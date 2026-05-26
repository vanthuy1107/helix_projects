# Ops Metrics Catalog — Smartlog Control Tower

> Reference cho `/da-ops`. Mỗi metric: data source thật + công thức + baseline + drill dimensions + audience.
>
> **Source of truth cho schema:** entity classes trong `backend/src/Smartlog.Domain/Entities/` và DbContext mapping. Khi conflict với file này → schema thắng, update file này theo.
>
> **Source of truth cho expectation/baseline:** không có "AOP target" như SC analytics — Smartlog Control Tower là SaaS đang rollout. Baseline = **rolling 4-week của chính tenant đó** (hoặc D-7 same-weekday). Không tự đặt target nếu chưa được agreement với rollout team.

---

## Cách dùng

Khi `/da-ops` cần metric info:
- **Daily pulse**: pick các metric `Priority = P0` (volume + adoption + anomaly), 1 tenant cụ thể
- **Adoption report**: pick category A (Adoption) — sau release feature mới
- **Anomaly note**: pick category H (Anomaly Signals) làm starting point
- **Weekly digest cross-tenant**: pick category A + B + G, mỗi tenant 1 row

---

## Bối cảnh data layer (đọc trước khi query)

| Tầng | Context | Schema | Chứa gì |
|---|---|---|---|
| **Activity log** | `LogDbContext` | `logging` | `LogActivity` (mỗi user action), `LogEntity` (CRUD diff), `LogRelatedEntity` (liên kết) |
| **Domain artifacts** | `AppDbContext` | default + per-module | `Conversation`, `Notebook`, `Dashboard`, `Monitor`, `MonitorRun`, `Alert`, `LlmUsageLog`, ... |
| **Multi-tenant** | resolver `IDbContextResolver` | per-tenant DB | Connection string từ JWT claim `TenantDBConfiguration`; fallback `DefaultConnection` |

Ghi chú quan trọng:
- LogDbContext và AppDbContext **không EF-join được** — kéo riêng rồi merge ở report layer (Python pandas, dotnet-script, hoặc viết tay trong artifact).
- `LogActivity` **không có cột tenant** — tenant inferred từ connection string của LogDbContext. Cross-tenant phải lặp tenant.
- Hầu hết domain entity inherit `BaseSoftDeletedEntity` → filter `DeletedTime IS NULL` cho artifact "đang active". Activity log KHÔNG soft-delete.

---

## A. Adoption (post-release)

Mục đích: feature mới release rồi, ai đã chạm? Trong bao lâu? Lặp lại không?

| Metric | Formula | Unit | Expectation | Source | Audience |
|---|---|---|---|---|---|
| **Distinct users touched** | `count(distinct user_id)` filter `caller_name LIKE '%<Feature>Handler'` trong window | users | ≥ 30% expected user base sau D+7 | `logging.activity` | Rollout, CS |
| **Time-to-first-touch** | `min(time) per user_id` − release_at | hours | median < 48h cho power users | `logging.activity` | Rollout |
| **Repeat use rate** | `count(distinct user_id with ≥ 2 actions in 7d) / count(distinct users touched)` | % | > 60% nếu feature là daily-use | `logging.activity` | Rollout, BA |
| **Feature dwell** (artifact created) | `count distinct artifact_id` (Conversation / Notebook / Dashboard) | count | tùy feature — báo trend, không tự đặt target | `Conversations`, `Notebooks`, `Dashboards` | Rollout, PM |
| **Drop-off after first try** | `users with exactly 1 action in 7d / users touched` | % | < 30% (drop-off cao = friction signal) | `logging.activity` | Rollout, BA |

**Drill dimensions:** `tenant`, `user_id`, `caller_name` (handler ≈ feature), `time` (theo ngày D+N).

**Insight hints:**
- "30 user touched" mà không kèm "out of expected N" = vô nghĩa — luôn có denominator.
- Adoption curve thường có shape **S-curve** trong 14 ngày đầu — flat → spike khi CS gọi → plateau. Plateau dưới 50% expected = friction, gọi user hỏi.
- `caller_name` dạng `Smartlog.Application.Features.<Module>.<Handler>` — parse phần `<Module>` để group adoption theo module.

---

## B. Activity Volume (daily pulse)

Mục đích: hôm nay tenant này nhịp đập thế nào so với chính nó tuần trước?

| Metric | Formula | Unit | Expectation | Source | Audience |
|---|---|---|---|---|---|
| **Total actions today** | `count(*) from logging.activity where time::date = today` | events | so với rolling 4-week same-weekday avg | `logging.activity` | PM, Rollout |
| **Actions per module** | `count(*) group by extract_module(caller_name)` | events | break down theo handler namespace | `logging.activity` | PM, BA |
| **Distinct active users** | `count(distinct user_id) where time::date = today` | users | ≥ same-weekday baseline | `logging.activity` | Rollout, CS |
| **Conversation starts** | `count(*) from Conversations where created_time::date = today` | count | so với rolling 4w | `Conversations` | PM |
| **Notebook runs** | `count(*) from NotebookCellRuns where created_time::date = today` | count | so với rolling 4w | `NotebookCellRuns` | PM |
| **Dashboard views** | `count(*) from logging.activity where caller_name LIKE '%DashboardViewHandler%'` | events | tracking-dependent — verify caller_name pattern thực tế | `logging.activity` | PM |
| **Monitor runs** | `count(*) from MonitorRuns where created_time::date = today` | count | xấp xỉ count(active monitor) × runs/day theo cron | `MonitorRuns` | Ops |

**Drill dimensions:** `module` (extract from `caller_name`), `user_id`, `hour-of-day`.

**Insight hints:**
- "Volume hôm nay" KHÔNG meaningful nếu chưa qua hết ngày — luôn nói "tính đến HH:mm UTC+7" và nội suy thận trọng (tốt hơn là so cùng giờ tuần trước, không proportional-extrapolate).
- Drop volume bất thường + `user_id` chính KHÔNG xuất hiện = silence signal (xem Lens #1 + Anti-pattern "no-data vs no-use").

---

## C. User Behavior (top users + role/time pattern)

Mục đích: ai đang dùng nhiều, ai im lặng, có pattern theo giờ không?

| Metric | Formula | Unit | Source | Audience |
|---|---|---|---|---|
| **Top N users by actions** | `count(*) group by user_id order by ... limit N` | events/user | `logging.activity` | Rollout |
| **Heavy-user concentration (Pareto)** | top 20% users đóng góp X% actions | % | `logging.activity` | PM, BA |
| **Action time distribution** | histogram theo hour-of-day (UTC+7) | events/hour | `logging.activity` | PM |
| **Inactive expected users** | expected_users − active_users (cần list expected từ rollout team) | users | `logging.activity` JOIN external list | Rollout, CS |
| **Role × Module heatmap** | `count(*) group by Role, module` (cần JOIN `UserGroup` / `Role`) | events | `logging.activity` + `Roles` (AppDbContext) | BA |

**Drill dimensions:** `user_id`, `role`, `hour-of-day`, `weekday`.

**Insight hints:**
- "Top user làm 80%" có thể là **bot/integration**, không phải human — verify qua `ip_address` + `user_email` + `caller_name` pattern.
- Smartlog Control Tower phục vụ user phân tích/monitor → KHÔNG có "logistics peak 06-10/17-21" như TMS gốc. Pattern thường là **office hours 09-18 UTC+7, weekday**, ít activity weekend (trừ scheduled monitor runs).

---

## D. Funnel & Success Rate

Mục đích: user khởi tạo Conversation → có ra artifact không? Notebook chạy có thành công không?

| Metric | Formula | Unit | Expectation | Source | Audience |
|---|---|---|---|---|---|
| **Conversation → Notebook** | `count(distinct conversation_id) where source_analysis_run_id IS NOT NULL / count(distinct conversation_id)` | % | tùy use case — report trend | `Conversations`, `Notebooks` | PM, BA |
| **Notebook cell success rate** | `count(NotebookCellRun where status=success) / count(*)` | % | > 90% (lỗi cao = friction hoặc data issue) | `NotebookCellRuns` (status enum) | PM, Eng |
| **Analysis run completion** | `count(AnalysisRun where status=completed) / count(*)` | % | > 85% | `AnalysisRuns`, `AnalysisRunStatus` enum | PM, Eng |
| **Monitor run pass rate** | `count(MonitorRun where status=success) / count(*)` | % | > 95% (under that → monitor flaky hoặc system issue) | `MonitorRuns`, `MonitorRunStatus` | Ops |
| **Conversation abandon** | `count(Conversation with 1 message and idle > 24h) / count(*)` | % | < 30% | `Conversations`, `Messages` | BA, Rollout |

**Drill dimensions:** `tenant`, `user_id`, `data_source_id`, `model_id` (cho analysis), thời điểm.

**Insight hints:**
- Funnel mỗi tenant rất khác nhau — KHÔNG aggregate cross-tenant cho funnel rate (Simpson's paradox).
- Notebook cell fail có thể do user error (SQL sai) hoặc system error (LLM timeout) — phân biệt qua `error_message` / `caller_name` pattern.

---

## E. Performance & Latency

Mục đích: hệ thống có chậm không? Slow ops dồn vào module/tenant nào?

| Metric | Formula | Unit | Threshold | Source | Audience |
|---|---|---|---|---|---|
| **Slow CQRS commands** | count where `PerformanceLoggingBehavior` warning fired (>1000ms) | events | spike = bottleneck | application logs (Serilog) — KHÔNG có table riêng, đọc log file | Eng, Ops |
| **Notebook cell run duration p50/p95** | `percentile_cont(0.5/0.95) within group (order by duration_ms)` | ms | depends on cell type — track trend | `NotebookCellRuns.duration_ms` (verify cột tồn tại) | PM, Eng |
| **Monitor run execution time** | avg/p95 of `MonitorRun.execution_time_ms` per monitor | ms | so với chính monitor đó tuần trước; spike = data growth hoặc query regression | `MonitorRuns` | Ops |
| **LLM response latency** | derived from `LlmUsageLog.metadata` nếu có timing field | ms | per-model baseline | `LlmUsageLog` | Eng, BA |

**Drill dimensions:** `caller_name`, `monitor_id`, `model_id`, `tenant`.

**Insight hints:**
- **Performance log đi vào Serilog file/sink, không vào DB** — `/da-ops` chủ yếu đọc `MonitorRun.execution_time_ms` (cột thực tồn tại). Slow CQRS warning cần đọc log file → chỉ ghi nếu user đã có log access.
- Latency spike thường correlate với LLM provider issue (xem Lens #6 với `LlmUsageLog`).

---

## F. LLM Cost & Usage

Mục đích: tenant đang tiêu bao nhiêu token? Model mix có hợp lý? Budget có nguy cơ vượt?

| Metric | Formula | Unit | Source | Audience |
|---|---|---|---|---|
| **Total tokens today** | `sum(total_tokens) where created_time::date = today` | tokens | `LlmUsageLog` | PM, Finance |
| **Estimated cost today** | `sum(estimated_cost_usd) where created_time::date = today` | USD | `LlmUsageLog` | PM, Finance |
| **Tokens per user** | `sum(total_tokens) group by user_id` | tokens/user | `LlmUsageLog` | Rollout, BA |
| **Model mix** | `sum(total_tokens) group by provider, model_id` distribution | % | `LlmUsageLog` | PM, Eng |
| **Pipeline stage distribution** | `count + tokens group by pipeline_stage` (Chat/Analytics/Monitor) | events + tokens | `LlmUsageLog.pipeline_stage` | PM, BA |
| **Budget consumption** | actual vs budget per period (cần `LlmBudgetConfig`) | % | `LlmBudgetConfig` + `LlmUsageLog` | Finance, PM |

**Drill dimensions:** `user_id`, `provider`, `model_id`, `pipeline_stage`, time.

**Insight hints:**
- Cost spike đột ngột không kèm volume spike → **model mix shift** sang model đắt hơn (vd Sonnet → Opus). Check distribution `model_id` MoM.
- 1 user dominate token usage = power user thật hay run-away script? Check `pipeline_stage` distribution + retry pattern.

---

## G. Monitor Health

Mục đích: hệ thống monitoring đang ổn định không? Alert có spam không?

| Metric | Formula | Unit | Expectation | Source | Audience |
|---|---|---|---|---|---|
| **Active monitors count** | `count(*) where is_active = true` | count | snapshot — nói về adoption monitoring | `Monitors` | Ops, PM |
| **Monitor run success rate** | `count(MonitorRun success) / count(*)` per period | % | > 95% (xem D — Funnel) | `MonitorRuns` | Ops |
| **Alert firing rate** | `count(Alert where state='Firing' and fired_at::date = today)` | alerts/day | spike = real incident hoặc alert spam (tuning issue) | `Alerts` | Ops |
| **Alert MTTR** | `avg(resolved_at − fired_at)` | minutes | mỗi tenant tự định, track trend | `Alerts` | Ops |
| **Alert silence ratio** | `count(AlertSilence active) / count(active monitor)` | % | > 30% = potentially over-alerting | `AlertSilences` | Ops, BA |
| **Monitors not run in 24h** | active monitors WHERE `last_run_at < now() - 24h` | count | 0 ideal — > 0 = scheduler issue | `Monitors` | Ops |

**Drill dimensions:** `monitor_id`, `severity`, `tenant`.

**Insight hints:**
- High firing rate + high silence ratio = alert tuning broken → handoff `/ba` để revisit thresholds.
- Monitor `last_run_at` lag bất thường (vd cron 5min nhưng `last_run_at` 2h ago) = scheduler/job runner issue, urgent ops handoff.

---

## H. Anomaly Signals

Mục đích: pattern bất thường cần điều tra ngay.

| Signal | Detection | Severity | Source |
|---|---|---|---|
| **Volume drop > 50% same-weekday** | today vs avg(4 same weekdays) | 🟡 hoặc 🔴 nếu kéo dài 2 ngày | `logging.activity` |
| **Power user silence** | user thường top-10 trong 4 tuần KHÔNG login hôm nay | 🟡 (gọi CS verify) | `logging.activity` |
| **Error/exception spike** | `count(activity where label LIKE 'Error%' or parameters LIKE '%exception%')` > p95 baseline | 🔴 | `logging.activity` |
| **Rate limit hits** | count of 429 in `caller_name` traces | 🟡 | log files / rate limit telemetry (chưa có table dedicated — verify) |
| **Failed monitor cluster** | ≥ 3 monitors fail trong 1h cùng tenant | 🔴 | `MonitorRuns` |
| **LLM cost runaway** | tenant cost today > 3× rolling 7d avg | 🔴 | `LlmUsageLog` |
| **Module first-time silence** | module có activity 30 ngày qua nhưng 0 hôm nay | 🟡 | `logging.activity` |

Mỗi anomaly khi phát hiện → tạo `projects/ops/anomalies/<YYYY-MM-DD>-<slug>.md` (xem template trong `report-templates.md`).

---

## Audience × Metric Depth Matrix

`/da-ops` phục vụ rollout/PM/BA — KHÔNG phải BOD strategic view. Map:

| Audience | Metric Count | Focus | Sample |
|---|---|---|---|
| **Rollout/CS team** | 5–8 daily | Adoption, silence signal, user-level action list | Distinct active users, top users, inactive expected users, anomaly volume drop |
| **PM** | 8–12 weekly | Activity volume trend, funnel, adoption | Volume per module, conversation→notebook rate, top tenants by activity |
| **BA** | nhiều khi drilldown | User behavior + funnel + role pattern | Role×Module heatmap, abandon rate, friction signals |
| **Ops/Eng** | per incident | Monitor health, performance | Monitor run pass rate, latency p95, alert MTTR |
| **Finance** | weekly cost | LLM cost + budget | Tokens/cost per tenant, model mix, budget consumption |

KHÔNG có "BOD audience" trong skill này — strategic view chuyển sang `/da-pm` hoặc `/da-data`.

---

## RAG Color Convention

Vì Smartlog Control Tower đang rollout (chưa có hard target từ contract), RAG dùng so với baseline rolling, không hardcoded:

| Color | Rule cơ bản |
|---|---|
| 🟢 Green | Trong band ±15% so với rolling 4w baseline (hoặc ≥ baseline cho lower-is-better) |
| 🟡 Yellow | Lệch 15–35% so với baseline, kéo dài 1–2 ngày |
| 🔴 Red | Lệch > 35% hoặc kéo dài ≥ 3 ngày, hoặc `[N/A]` đáng lo (silence không expected) |
| ⚪ Grey | No data / activity log không bật cho module / tenant DB không truy cập |

**Lower-is-better** (ngược chiều): Conversation abandon rate, Drop-off after first try, Alert firing rate (nếu vô lý), Latency p95, LLM cost runaway.

---

## Quy ước extract module từ caller_name

`caller_name` lưu full type name của handler, vd:
```
Smartlog.Application.Features.Chat.CreateConversationHandler
Smartlog.Application.Features.Dashboard.UpdateDashboardHandler
Smartlog.Application.Features.Monitor.RunMonitorHandler
```

Pattern tách module:
```sql
-- PostgreSQL
split_part(caller_name, '.', 4) AS module    -- 'Chat' | 'Dashboard' | 'Monitor' | ...

-- MSSQL
PARSENAME(REPLACE(caller_name, '.', '#'), 3)  -- careful với số dot, test trên data thật
```

Khi `caller_name` không match pattern (vd background job, system action) → bucket `_other`.

---

## Cross-references

- Entity DDL: `backend/src/Smartlog.Domain/Entities/<area>/<Name>.cs`
- EF mapping: `backend/src/Smartlog.Infrastructure/EntityFramework/Configurations/`
- LogDbContext: `backend/src/Smartlog.Infrastructure/ActivityLogs/`
- QueryConfigs: `backend/src/QueryConfigs/*.json`
- Tenant resolver: `backend/src/Smartlog.Infrastructure/EntityFramework/IDbContextResolver.cs`
- Multi-tenant claim: `AppClaimTypes.TenantDBConfiguration`
- Glossary của handler/module → `docs/shared/glossary/*` (nếu chưa có, đề xuất tạo khi `/da-ops` gặp tên handler khó hiểu)

---

*Update file này khi: (1) entity mới được thêm vào `Smartlog.Domain`, (2) baseline expectation thay đổi sau khi rollout team agreement, (3) phát hiện caller_name pattern mới chưa cover.*
