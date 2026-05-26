# 9 Lens Framework — Smartlog Control Tower

> Reference cho `/da-ops`. 9 kỹ thuật phân tích kinh điển (Tukey 1977 EDA, Pareto 1896, Pearson, Box-Jenkins, RFM) — đã đóng gói vào ngữ cảnh **monitoring rollout SaaS multi-tenant** của Smartlog Control Tower.
>
> Khác 9-lens generic: ví dụ + bẫy + chart spec ở đây dùng **entity + table + caller_name pattern thật** của project. Không có metric SC/AOP — Smartlog Control Tower là analytics platform đang rollout, baseline = chính tenant đó vs. rolling 4w.

---

## Phase Map

```
BƯỚC 0 — PROFILE DATA SOURCE (table, columns, period, quality, tenant scope)
   ↓
PHASE 1 — HIỂU DATA    → Lens #1 Completeness, #2 Distribution, #3 Outliers
   ↓
PHASE 2 — NHÌN XA      → Lens #4 Timeline, #5 Concentration
   ↓
PHASE 3 — HIỂU SÂU     → Lens #6 Correlation, #7 Comparison, #8 Segmentation
   ↓
PHASE 4 — ĐO RISK      → Lens #9 Volatility
   ↓
BƯỚC 5 — TỔNG HỢP → BÁO CÁO
```

---

## Bước 0 — Profile Data Source

Không cần auto-detect type — schema đã có trong entity classes. Chỉ cần verify:

```
1. Xác định context: LogDbContext (logging schema) hay AppDbContext (domain)?
2. Đọc entity class → lấy column list + types + nullable
3. Xác định tenant scope: connection đang trỏ tenant nào?
4. Query profile shape:
   - row count
   - period covered: min/max(time) hoặc min/max(created_time)
   - distinct user_id, distinct caller_name (cho activity log)
   - distinct data_source_id (cho domain artifact)
5. Ghi audit: tenant alias, run-at timestamp, query SQL → vào Appendix
```

**Lag alert:** nếu activity log `max(time) < now() − 1h` trong giờ làm việc → cảnh báo ingestion stale (LogDbContext write-path failing?).

---

## Phase 1 — Hiểu Data

### 🔭 Lens #1 — COMPLETENESS (LUÔN áp dụng)

> Data có ở đó không? Thiếu ở đâu, theo PATTERN gì?

**Quy trình:**
```
1. % null/empty mỗi cột (cho domain entity — log activity ít NULL):
   SELECT
     COUNT(*) FILTER (WHERE user_id IS NULL) * 100.0 / COUNT(*) AS user_null_pct,
     COUNT(*) FILTER (WHERE caller_name = '') * 100.0 / COUNT(*) AS caller_empty_pct,
     ...
   FROM logging.activity
   WHERE time >= now() - INTERVAL '7 days'

2. Missing theo time partition (giờ × ngày):
   SELECT date_trunc('hour', time) AS h, COUNT(*) AS rows
   FROM logging.activity
   WHERE time >= now() - INTERVAL '7 days'
   GROUP BY h ORDER BY h
   → phát hiện giờ "câm" — partition lag hoặc downtime

3. Phân loại pattern:
   - MCAR: thiếu random
   - MAR: thiếu liên quan cột khác (ví dụ: tracking handler X không có activity log → dev quên gọi CommitAsync)
   - MNAR: thiếu CHÍNH VÌ giá trị (ví dụ: read-only Q không log vì IActivityLogContext.CommitAsync skip khi changedEntities=0)
```

**Ví dụ Smartlog cụ thể:**
- `logging.activity` thiếu hoàn toàn module X trong 7 ngày → handler X không gọi `IActivityLogContext.CommitAsync` (dev miss) hoặc module này chỉ có read query (Q-only, không có Command). Verify bằng grep `Features.X` trong `backend/`.
- `Conversations.is_archived` distribution lệch về `false` 100% → archive workflow chưa được rollout với user, không phải data error.
- `MonitorRuns` có giờ "câm" 3h hôm qua → scheduler down, không phải sampling bug.

**Bẫy:**
- ❌ Coi "no activity log cho module X" = "module X không được dùng" — có thể tracking miss, verify code trước khi conclude.
- ❌ Fill default cho `user_id` NULL → spoof identity, KHÔNG bao giờ làm.
- ❌ Bỏ qua survivorship bias — chỉ thấy Conversation đã save, không thấy ai mở lên rồi đóng (front-end-only event không vào activity log).

**Chart spec (markdown-native):**
- Bảng "% null/empty per column" sorted descending
- Heatmap text (hour × day) cho row count theo giờ — phát hiện partition câm

---

### 🔭 Lens #2 — DISTRIBUTION

> Data trông như thế nào? Shape quyết định metric bạn dùng.

**Khi nào:** ≥ 1 cột NUMERIC continuous (vd `MonitorRun.execution_time_ms`, `LlmUsageLog.total_tokens`, `LlmUsageLog.estimated_cost_usd`, `NotebookCellRun.duration_ms`).

**Quy trình:**
```
1. Với mỗi cột numeric quan trọng:
   SELECT
     AVG(execution_time_ms)                                                  AS mean,
     PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY execution_time_ms)          AS p50,
     PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_time_ms)         AS p95,
     PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY execution_time_ms)         AS p99,
     STDDEV_POP(execution_time_ms)                                           AS std
   FROM "MonitorRuns"
   WHERE execution_time_ms > 0 AND created_time >= now() - INTERVAL '14 days'

2. So mean vs p50:
   - Chênh > 30% → right-skewed (bình thường cho latency/cost) → **dùng p50/p95, KHÔNG dùng mean**
   - Chênh < 10% → roughly normal → mean OK

3. Histogram qua quantile buckets cho visualization
```

**Ví dụ Smartlog:**
- `LlmUsageLog.total_tokens` per request thường **right-skewed** (đa số short prompt, 1 vài long-context huge) → mean cao do outlier; **dùng p50** khi nói "typical request".
- `MonitorRun.execution_time_ms` thường **bimodal**: cluster dưới 500ms (cached / simple monitor) + cluster trên 5000ms (heavy SQL) → segment theo monitor_id trước khi nhận xét.
- `LlmUsageLog.estimated_cost_usd` per user/day — heavy-tailed → median tells you typical user, mean kéo lệch bởi 1 power user.

**Bẫy:**
- ❌ Báo "average response time 2.3s" khi p50 = 800ms, p99 = 30s — BOD/PM hiểu sai performance thật.
- ❌ Không kiểm tra bimodal trong `MonitorRun` → đề xuất "tối ưu chung" trong khi cluster slow là 1 nhóm monitor riêng.
- ❌ Tính average cost/user khi cost concentrate ở top 5% — segment trước.

**Chart spec:**
- Text histogram (quantile buckets) cho numeric columns quan trọng
- Boxplot ASCII nếu so sánh distribution giữa segment (model_id × duration, monitor × execution_time)

---

### 🔭 Lens #3 — OUTLIERS

> Có gì bất thường không? TẠI SAO bất thường?

**Khi nào:** Có cột NUMERIC continuous.

**Quy trình:**
```
1. Phát hiện:
   - IQR rule: < Q1 − 1.5·IQR hoặc > Q3 + 1.5·IQR
   - Domain-specific: total_tokens < 0? duration_ms = 0 khi status=success? created_time tương lai?

2. Phân loại 3 LOẠI — KHÔNG BAO GIỜ XÓA TỰ ĐỘNG:
   🔴 DATA ERROR: total_tokens âm, fired_at > now(), monitor_id không tồn tại → fix nguồn / loại có ghi chú
   🟡 VALID EXTREME: 1 conversation 50k tokens (hợp lệ với long-context analysis, hiếm) → giữ, segment riêng
   🟢 SIGNAL: cost spike 1 user × 10 trong 1 ngày → điều tra (run-away script? bulk operation? legitimate?)
```

**Ví dụ Smartlog:**
- `LlmUsageLog`: 1 user dùng 200k tokens trong 5 phút → 🟢 SIGNAL — verify pipeline_stage ('Chat' = manual có thể; 'Monitor' batch = automation có thể có vấn đề loop).
- `MonitorRun.execution_time_ms`: 1 monitor 60000ms (60s) trong khi median 200ms → 🟢 SIGNAL — query regression hoặc data growth?
- `Conversations.created_time` future > now() → 🔴 ERROR (clock skew), hoặc dữ liệu test seed.
- `logging.activity`: 1 user_id 5000 actions trong 10 phút → 🟢/🟡 — bot/integration hay UI bug spam-click? Check `caller_name` pattern.

**Bẫy:**
- ❌ Auto-xóa cost outlier → mất signal về user lạm dụng / abuse / runaway.
- ❌ Dùng mean khi outlier chưa xử lý → mean cost/user lệch.
- ❌ Coi "1 user 5000 actions" là spam mà không check pattern (regular cron job vẫn có thể tạo nhịp đều đặn).

**Chart spec:**
- Bảng top 10 outliers với cột "loại" (error / valid / signal) + "hành động" + Q? reference
- Annotated timeline text nếu outlier có timing cluster (vd cost spike toàn vào 1 giờ → có thể cron)

---

## Phase 2 — Nhìn Xa

### 🔭 Lens #4 — TIMELINE

> Xu hướng đi về đâu? Trend, weekly seasonal, hay đột biến?

**Khi nào:** Có cột thời gian (`time`, `created_time`, `fired_at`, ...).

**Quy trình:**
```
1. Aggregate theo period phù hợp:
   - Daily pulse → giờ-trong-ngày, hoặc 6 ngày gần nhất daily
   - Weekly digest → 8 tuần daily hoặc rolling 7d
   - Adoption D+N → daily từ release date

2. Nhận diện 3 thành phần:
   - TREND: rolling 7-day mean
   - SEASONALITY: week-over-week-same-weekday (vd Monday vs Monday)
   - RESIDUAL: deviation từ expected → anomaly

3. Same-weekday > MoM khi có weekly seasonality (Smartlog có pattern weekday-office-hours rất mạnh):
   SELECT
     date_trunc('day', time) AS d,
     EXTRACT(dow FROM time)  AS weekday,
     COUNT(*)                AS actions
   FROM logging.activity
   WHERE time >= now() - INTERVAL '8 weeks'
   GROUP BY d, weekday
```

**Ví dụ Smartlog:**
- Activity drop hôm nay 40% → so với cùng-thứ tuần trước, không so MoM (Monday vs Sunday vô nghĩa).
- Monitor run count drop từ tuần trước → check weekend (cron pause weekend?) vs scheduler issue thực sự.
- Conversation start tăng spike sau release notification email → expected, KHÔNG phải anomaly.
- LLM cost rolling 7d trend lên đều → adoption healthy hay run-away cron? Cần Lens #5 + #8 confirm.

**Bẫy:**
- ❌ So sánh today (Tue) với yesterday (Mon) cho activity volume — Mon thường cao nhất tuần.
- ❌ So Feb với Jan cho cost mà không normalize số ngày làm việc.
- ❌ Kết luận "user dùng nhiều hơn" mà chưa check số expected user thay đổi (rollout thêm tenant mới).

**Chart spec:**
- ASCII sparkline 7–14-day rolling: `▁▂▄▅▇█▇▆▄▃▂▁▁`
- Annotated text timeline cho release events / known incidents

---

### 🔭 Lens #5 — CONCENTRATION

> 80% kết quả từ 20% nào?

**Khi nào:** Có chiều group (tenant / user / module / monitor / model_id) + 1 metric.

**Quy trình:**
```
1. Pareto query:
   SELECT
     user_id,
     COUNT(*)                                                                 AS actions,
     COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()                                AS pct,
     SUM(COUNT(*)) OVER (ORDER BY COUNT(*) DESC) * 100.0 / SUM(COUNT(*)) OVER () AS cum_pct
   FROM logging.activity
   WHERE time >= now() - INTERVAL '7 days'
   GROUP BY user_id
   ORDER BY actions DESC
   LIMIT 50

2. Tìm: top X% entities tạo 80% metric
3. Đánh giá concentration RISK / OPPORTUNITY
```

**Ví dụ Smartlog:**
- **User concentration:** 5/120 user tạo 70% activity → adoption rủi ro nếu 5 user power-user nghỉ. Đề xuất: rollout team training thêm "next tier" 10–20 user.
- **Module concentration:** 80% activity từ Chat module, Dashboard module < 5% → Dashboard adoption lag, cần CS gọi user hỏi tại sao chưa dùng.
- **Tenant concentration:** 1 tenant tạo 60% LLM cost → exposure cao, verify sử dụng có đúng SLA tier; nếu tenant này churn → mất 60% revenue line.
- **Monitor concentration:** top 3 monitor đóng góp 80% alert volume → tuning 3 monitor đó = giảm alert noise nhiều nhất.

**Bẫy:**
- ❌ Treat tất cả tenant như nhau khi report — concentration risk biến mất.
- ❌ Báo "user trung bình làm 25 actions/ngày" khi distribution heavily skewed.

**Chart spec:**
- Pareto table: entity | name | actions | % | cumulative % (mark 80% line)
- Pattern chuẩn: xem `report-templates.md` §Pattern 1 (Pareto)

---

## Phase 3 — Hiểu Sâu

### 🔭 Lens #6 — CORRELATION

> Thứ gì liên quan thứ gì? Correlation ≠ Causation.

**Khi nào:** ≥ 2 cột numeric (hoặc 2 KPI có thể derive theo cùng period).

**Quy trình:**
```
1. Pearson correlation (numeric continuous), aggregate cùng grain:
   WITH daily AS (
     SELECT
       date_trunc('day', created_time)             AS d,
       SUM(total_tokens)                            AS tokens,
       SUM(estimated_cost_usd)                      AS cost,
       COUNT(*) FILTER (WHERE status='Failed')      AS fails
     FROM "LlmUsageLog"
     WHERE created_time >= now() - INTERVAL '60 days'
     GROUP BY d
   )
   SELECT corr(tokens, fails) AS r_tokens_fails,
          corr(cost, tokens)  AS r_cost_tokens
   FROM daily

2. Highlight |r| > 0.5 = strong, |r| > 0.3 = moderate

3. LUÔN hỏi confounding:
   - A correlate B → có thể cả 2 do C gây ra
   - VD: Chat conversation count correlate Notebook run count → có thể cả 2 do "ngày làm việc bận" gây ra (confounding = workload)

4. Correlation → HYPOTHESIS, cần A/B test hoặc investigation để prove causation
```

**Ví dụ Smartlog:**
- Notebook cell fail rate correlate với LLM provider response latency (r=0.6) → hypothesis: provider issue cascade → LLM call timeout → cell fail. Action: check provider status page khi fail rate spike.
- Monitor execution_time spike correlate với active user count tại tenant đó (r=0.5) → DB contention. Action: schedule heavy monitor vào off-peak.
- LLM cost correlate với conversation count chỉ r=0.3 → cost growth KHÔNG tuyến tính với usage; có thể model-mix shift là driver chính (xem Lens #5 model concentration).

**Bẫy:**
- ❌ Kết luận nhân quả từ correlation (sai lầm cơ bản).
- ❌ Bỏ qua confounding (vd 2 metric đều spike vào sáng thứ 2 vì office-hours bias).
- ❌ Tin r cao từ sample size < 14 ngày — quá ít data points cho correlation tin cậy.

**Chart spec:**
- Correlation heatmap text giữa pairs of metric
- Scatter plot spec cho top pairs (feed dashboard nếu cần handoff sang `/da-data`)

---

### 🔭 Lens #7 — COMPARISON (LUÔN áp dụng)

> Tốt hay xấu SO VỚI GÌ?

**5 Level baseline cho Smartlog Control Tower:**

```
Level 1 — vs EXPECTATION (rollout-team agreed)
  Distinct active users D+7 = 35 vs expected 50 → −30%

Level 2 — vs PRIOR PERIOD (rolling)
  Today actions = 1240 vs avg 4 same-weekdays = 1800 → −31%

Level 3 — vs SAME-WEEKDAY HISTORY (loại weekday seasonality)
  Mon actions = 1240 vs avg 4 prior Mon = 1320 → −6%

Level 4 — vs PEER TENANT (cùng tier, cùng module)
  Tenant A adoption Notebook = 12% vs Tenant B (cùng tier) = 38% → gap 26pp

Level 5 — vs RELEASE DATE BASELINE (pre-release vs post-release)
  Conversation/day pre-release = 80, post-release D+14 = 180 → +125%
```

**Ví dụ Smartlog cụ thể:**
- Mỗi metric trong artifact phải có ≥ 2 baseline (current + 1 reference). Tốt nhất là same-weekday + rolling 7d.
- KHÔNG có "AOP target" — Smartlog Control Tower đang rollout, expectation đến từ rollout team agreement (đọc memory project hoặc hỏi PM nếu chưa rõ).

**Khi không có baseline:**
- Nếu chưa có rolling baseline (tenant mới rollout < 4 tuần) → ghi `[chưa đủ history]` thay vì phỏng đoán, đề xuất follow-up sau D+28.
- Nếu chưa có peer benchmark → chỉ dùng Level 2/3/5, ghi rõ.

**Chart spec:**
- Bullet chart spec vs expectation (feed dashboard)
- Pattern chuẩn: xem `report-templates.md` §Pattern 2 (RAG Comparison Bar)

---

### 🔭 Lens #8 — SEGMENTATION

> Average che giấu điều gì?

**Khi nào:** ≥ 1 chiều để nhóm.

**Quy trình:**
```
1. Segment 1 chiều:
   SELECT module, AVG(daily_actions) FROM ... GROUP BY module
   SELECT tenant, AVG(daily_actions) FROM ... GROUP BY tenant

2. Segment đa chiều:
   SELECT tenant, module, AVG(daily_actions) FROM ... GROUP BY tenant, module

3. Check Simpson's Paradox:
   - Metric tổng hợp NGƯỢC CHIỀU với từng segment?
   - VD: Adoption tổng = 45%, nhưng mỗi tenant đều < 45% → weighted average dominated bởi 1 tenant lớn
```

**Ví dụ Smartlog:**
- **RFM-style cho user:**
  - Recency (last action days) × Frequency (actions/week) × Monetary (LLM cost contribution)
  - → Champions / At-risk (Recency drift) / Inactive — action khác nhau (CS gọi at-risk, gift Champions)
- **Tenant segmentation:**
  - Activity volume × Module breadth → "Heavy + Broad" (mature) vs "Heavy + Narrow" (single-feature lock) vs "Light + Broad" (exploratory) vs "Light + Narrow" (pre-churn)
- **Module × Role heatmap:**
  - Vd Analyst role vs Operator role × module → Notebook chỉ có Analyst dùng (expected), Dashboard ai cũng dùng (expected); Monitor chỉ Ops dùng → nếu Operator role có activity Monitor → mở rộng adoption hoặc role-misuse

**Bẫy:**
- ❌ Segment chỉ bằng "actions count" — thiếu recency / breadth.
- ❌ Kết luận từ aggregate cross-tenant mà không tách tenant — Simpson's paradox lớn vì tenant size khác xa nhau.
- ❌ "Adoption company-level 50%" che fact rằng 1 tenant 90% kéo trung bình lên.

**Chart spec:**
- Heatmap 2D text (tenant × module, hoặc module × role, màu RAG)
- Pattern chuẩn: xem `report-templates.md` §Pattern 3 (Heatmap RAG)

---

## Phase 4 — Đo Risk

### 🔭 Lens #9 — VOLATILITY

> Ổn định hay lung tung? CV cao = khó forecast = risk.

**Khi nào:** Time-series hoặc repeated measures.

**Quy trình:**
```
1. CV = stddev / mean × 100%
   WITH daily AS (
     SELECT tenant, date_trunc('day', time) AS d, COUNT(*) AS actions
     FROM logging.activity
     WHERE time >= now() - INTERVAL '14 days'
     GROUP BY tenant, d
   )
   SELECT
     tenant,
     AVG(actions)                            AS m,
     STDDEV_POP(actions)                     AS s,
     STDDEV_POP(actions) / AVG(actions) * 100 AS cv_pct
   FROM daily
   GROUP BY tenant
   HAVING AVG(actions) > 0
   ORDER BY cv_pct DESC

2. Interpret:
   CV < 20%  → Ổn định, baseline tin được, anomaly detection dễ
   CV 20-50% → Moderate, wider tolerance
   CV > 50%  → Volatile, baseline không tin cậy — dùng band scenarios thay vì điểm

3. Rolling CV — có đang tăng không?

4. Risk Matrix:
   X: CV (volatility)
   Y: % activity / cost (impact)
   Ô "High Impact + High Volatility" = ưu tiên monitoring chặt
```

**Ví dụ Smartlog:**
- **Tenant volume CV:** Tenant A CV=15% (predictable), Tenant B CV=80% (sporadic — chỉ dùng vài ngày trong tháng) → 2 strategy rollout khác nhau (A có thể alert anomaly nhạy; B alert sẽ false positive nhiều).
- **LLM cost CV theo user:** user CV>60% = "spike user" có lúc bùng nổ token usage → có thể automation script không control good; check pipeline_stage distribution.
- **Monitor execution_time CV:** monitor CV>30% = unstable performance → query có thể không có index ổn định, hoặc data growth không kiểm soát.

**Bẫy:**
- ❌ Set 1 alert threshold cho mọi tenant CV khác nhau → spam ở high-CV tenant, miss ở low-CV tenant.
- ❌ Forecast cho tenant CV > 50% (vô nghĩa).
- ❌ Bỏ qua rolling CV (trung bình 14d ổn nhưng 3 ngày gần đây spike).

**Chart spec:**
- CV comparison bar (entities sorted by CV)
- Risk matrix scatter: impact vs volatility
- Pattern chuẩn: xem `report-templates.md` §Pattern 4 (CV Bar)

---

## 10 Mental Models — LUÔN GHI NHỚ

```
1.  Context is king. "200 actions hôm nay" không nghĩa gì nếu không có baseline.
2.  All models are wrong, some are useful. (George Box)
3.  Correlation ≠ Causation — mãi mãi.
4.  Averages lie — luôn hỏi distribution (đặc biệt cost / latency / token usage).
5.  Sample size matters — tenant rollout < 4 tuần không đủ data cho baseline.
6.  Survivorship Bias — chỉ thấy Conversation đã save, không thấy ai vào rồi đóng.
7.  Garbage in, garbage out — activity log không bật cho module → data thiếu, không phải user không dùng.
8.  80% data cleaning, 20% analysis — verify schema + tenant scope + soft-delete filter trước.
9.  Apples to apples — cùng definition (active user = ai? click hay write?), cùng period, cùng tenant scope.
10. The goal is decision, not insight — analysis chỉ có giá trị khi rollout/CS team hành động.
```

---

## Project-specific constraints

- Industry locked: **multi-tenant SaaS analytics platform** — không phân tích data ngoài phạm vi (nếu user đưa data khác → handoff `/da-data`).
- **Multi-tenant**: cross-tenant aggregation phải tách hoặc ghi caveat. KHÔNG có "global view" tự nhiên — mỗi connection = 1 tenant.
- **Activity log + domain context không EF-join được** — kéo riêng (mỗi context 1 query), merge ở report layer.
- Soft delete: `DeletedTime IS NULL` cho `BaseSoftDeletedEntity` (Conversation, Notebook, Dashboard, ...). Activity log không soft-delete.
- Time UTC trong DB → trình bày UTC+7. Không tự skip step convert.
- Reuse-trước-ad-hoc: kiểm `backend/src/QueryConfigs/*.json` xem có endpoint sẵn không trước khi viết SQL ad-hoc.
- KHÔNG render PNG — Chart Block 3-layer (xem `report-templates.md`).
- KHÔNG tự xóa outlier — 3-loại classification bắt buộc.
- KHÔNG tự generate expectation/baseline — đọc agreement với rollout team hoặc dùng rolling 4w.

---

*Gốc framework: "9 Lens Bất Biến" — adapt vào ngữ cảnh Smartlog Control Tower (multi-tenant analytics SaaS, rollout phase). Cập nhật khi entity mới được thêm hoặc pattern mới phát hiện.*
