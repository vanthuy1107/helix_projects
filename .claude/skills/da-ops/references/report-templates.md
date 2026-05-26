# Report Templates — da-ops

> Skeleton markdown cho 5 mode output của `/da-ops`. Copy-paste-fill khi generate artifact. Mọi số trong artifact PHẢI có Q? reference trong Appendix (xem hard rule trong [SKILL.md](../SKILL.md)).
>
> Filename convention (đã định trong SKILL.md):
> - Daily pulse: `projects/ops/daily/<tenant>-<YYYY-MM-DD>.md`
> - Adoption: `projects/ops/adoption/<feature>-d<N>-<YYYY-MM-DD>.md`
> - Anomaly: `projects/ops/anomalies/<YYYY-MM-DD>-<slug>.md`
> - Weekly: `projects/ops/weekly/<YYYY-WW>.md`
> - Incident: `projects/ops/incidents/<ticket>-<YYYY-MM-DD>.md`

---

## Convention chung

**YAML frontmatter** (bắt buộc cho artifact non-trivial — giúp tools downstream `/da-ops-review`, `/da-ops-release` parse):

```yaml
---
report_type: pulse | adoption | anomaly | weekly | incident
generated_at: 2026-05-10T14:30:00+07:00
generated_by: /da-ops (Claude)
tenant_scope: <tenant alias | list | "all-rollout">
period_covered: 2026-05-10T00:00+07:00 → 2026-05-10T14:30+07:00
data_sources:
  - logging.activity (LogDbContext)
  - "Conversations" (AppDbContext)
  - "MonitorRuns" (AppDbContext)
queries_run: 6
data_gaps:
  - "Tenant X: connection unavailable, marked [N/A]"
lenses_applied: [1, 4, 5, 7]   # nếu drilldown
---
```

**RAG emoji chuẩn:** 🟢 🟡 🔴 ⚪ (grey = N/A / không query được)
**Trend arrow:** ↑ ↓ → (sau giá trị)
**Sparkline chars:** `▁▂▃▄▅▆▇█` (8 bars cho 7–14 điểm)
**Time:** luôn UTC+7, ghi rõ "ICT" hoặc "UTC+7" sau timestamp

---

## Template A — Daily Ops Pulse

```markdown
---
report_type: pulse
generated_at: <ISO8601 +07:00>
generated_by: /da-ops
tenant_scope: <tenant alias>
period_covered: <YYYY-MM-DD>T00:00+07:00 → <YYYY-MM-DD>THH:mm+07:00
data_sources:
  - logging.activity (LogDbContext)
  - "Conversations" (AppDbContext)
  - "MonitorRuns" (AppDbContext)
queries_run: <N>
data_gaps: []
---

# Daily Ops Pulse — <Tenant Name> — <YYYY-MM-DD>

**Window**: 00:00 → <HH:mm> UTC+7
**Pulled at**: <YYYY-MM-DD HH:mm UTC+7>
**Tenant**: <tenant display name> (<tenant code/alias>)
**Author**: /da-ops (Claude)

## 🎯 Headline (1 dòng)
<Câu chuyện 1 dòng vận hành hôm nay — chỉ viết khi có số thật từ Appendix. Không có data → "Chưa đủ data để conclude — xem Open questions">

**So-what:** <1 dòng action implication cho rollout/CS team>

---

## 📊 Key Numbers

| Metric | Today | Baseline (avg 4 same-weekday) | Δ | RAG | Source |
|---|---:|---:|---:|:---:|:---:|
| Total actions | <Q1.today> | <Q1.baseline> | <%> | <emoji> | Q1 |
| Distinct active users | <Q2.today> | <Q2.baseline> | <%> | <emoji> | Q2 |
| Conversations started | <Q3.today> | <Q3.baseline> | <%> | <emoji> | Q3 |
| Notebook runs | <Q4.today> | <Q4.baseline> | <%> | <emoji> | Q4 |
| Monitor runs | <Q5.today> | <Q5.baseline> | <%> | <emoji> | Q5 |
| LLM cost (USD) | <Q6.today> | <Q6.baseline> | <%> | <emoji> | Q6 |

> Ô không query được → ghi `[N/A]` + nêu lý do trong Open questions. KHÔNG bịa số.

---

## 👥 User Activity (Top N + silence)

### Top users hôm nay

| User | Role | Actions | Notable | Q? |
|---|---|---:|---|:---:|
| <name (email)> | <role> | <num> | <observation> | Q7 |

### Silence signals

| Expected user | Last seen | Note |
|---|---|---|
| <name> | <YYYY-MM-DD> (D-<N>) | <hypothesis — sick? feature unused?> |

> Liệt kê expected users từ rollout team list — KHÔNG đoán "user X ngừng dùng" nếu chưa có expected list.

---

## ⏰ Time Pattern

```
Activity per hour (UTC+7) — today vs same-weekday baseline

Hour  Today  Baseline
00    ▁  <n>      ▁  <n>
...
09    ▆  <n>      ▇  <n>
10    █  <n>      █  <n>
...
18    ▄  <n>      ▃  <n>
```

- Office-hour coverage (09–18 UTC+7): <%>
- Khoảng câm bất thường: <none / "13:00–15:00 — silent, prior baseline ~80 actions/hour">

---

## 💡 Insights (3–5 actionable)

### Insight 1 — <action title nói so-what, không phải label KPI>

- **Quan sát:** <số cụ thể từ Q?> (ref: Q?)
- **So sánh:** <vs baseline có query — không có baseline → bỏ insight này hoặc move to Open questions>
- **Giả thuyết:** <vì sao>
- **Đề xuất:** <action cụ thể: WHO + WHAT — vd "CS gọi Anh A (anh.a@tenant.vn) hỏi vì sao không login từ T-3">

### Insight 2 — ...

---

## 🚨 Anomalies (nếu có)

| Severity | Signal | Detail | Q? |
|:---:|---|---|:---:|
| 🔴 | Volume drop > 50% | <metric, value vs baseline> | Q? |
| 🟡 | Power user silence | <user, last seen> | Q? |

→ Anomaly nghiêm trọng tách thành file riêng `projects/ops/anomalies/...` (Template C).

---

## ❓ Open Questions

- <câu hỏi cần verify với rollout/CS — vd "User B có nghỉ phép tuần này không?">
- <data source nào không query được + lý do — vd "MonitorRun query timeout, thử window 6h thay 24h cho lần sau">

---

## 📎 Appendix — Data Sources

> Mọi số trên artifact phải truy được về 1 trong các query bên dưới.

### Q1 — Total actions today vs same-weekday baseline
- **Context**: LogDbContext
- **Source**: `logging.activity`
- **Tenant**: <alias> (connection: <db_alias>)
- **Run at**: <YYYY-MM-DD HH:mm UTC+7>
- **Result rows**: <n>
- **SQL** (PostgreSQL):
  ```sql
  -- Hỏi: today vs avg(4 prior same-weekdays)
  WITH today AS (
    SELECT COUNT(*) AS c FROM logging.activity
    WHERE time::date = current_date
  ),
  prior AS (
    SELECT date_trunc('day', time)::date AS d, COUNT(*) AS c
    FROM logging.activity
    WHERE time::date < current_date
      AND time >= current_date - INTERVAL '5 weeks'
      AND EXTRACT(dow FROM time) = EXTRACT(dow FROM current_date)
    GROUP BY d ORDER BY d DESC LIMIT 4
  )
  SELECT (SELECT c FROM today) AS today_actions,
         (SELECT AVG(c) FROM prior) AS baseline_avg;
  ```

### Q2, Q3, ... — <theo cùng pattern>

### Limitations & caveats
- <vd "Activity log không bật cho module Knowledge — adoption Knowledge KHÔNG tracking được trong artifact này">
- <vd "Notebook cell run latency: column duration_ms chưa verify tồn tại — skip metric performance">
```

---

## Template B — Adoption Report

Dùng sau release feature mới, theo dõi D+1, D+3, D+7, D+14, D+28.

```markdown
---
report_type: adoption
generated_at: <ISO8601 +07:00>
generated_by: /da-ops
feature: <feature slug>
released_at: <YYYY-MM-DD>
day_n: <N>
tenant_scope: <list>
data_sources:
  - logging.activity
  - "Conversations" / "Notebooks" / "Dashboards" (đúng artifact của feature)
queries_run: <N>
---

# Adoption Report — <Feature> — Day <N>

**Released**: <YYYY-MM-DD>
**Today**: <YYYY-MM-DD> (D+<N>)
**Tenants in scope**: <list>
**Pulled at**: <YYYY-MM-DD HH:mm UTC+7>

## 🎯 Headline

<1 dòng kết luận adoption — vd "D+7: 12/40 expected users đã chạm, 60% repeat use — adoption healthy nhưng dưới target 30 user">

**So-what:** <CS action / training? hotfix?>

---

## 📊 Reach (per tenant)

| Tenant | Distinct users touched | Expected users | % | First-touch median (h) | Q? |
|---|---:|---:|---:|---:|:---:|
| <name> | <Q1.value> | <expected> | <%> | <Q2.median> | Q1, Q2 |

> Expected users từ rollout team list, KHÔNG fabricate. Chưa có list → ghi `[chưa có expected]` và đề xuất rollout team supply.

---

## 📈 Depth (engagement)

| Tenant | Total uses | Avg uses per user | Repeat-use rate (≥2 in 7d) | Q? |
|---|---:|---:|---:|:---:|
| <name> | <num> | <num> | <%> | Q3 |

---

## 🚧 Friction signals

| Signal | Value | Threshold | RAG | Q? |
|---|---:|---:|:---:|:---:|
| Drop-off after 1 try | <%> | < 30% | <emoji> | Q4 |
| Action error rate | <%> | < 5% | <emoji> | Q5 |
| Time-to-complete (median) | <s> | per feature SLO | <emoji> | Q6 |

---

## 💡 Verdict

- [ ] **Healthy adoption** — tiếp tục theo dõi, next checkpoint D+<N+7>
- [ ] **Slow start** — cần training / nhắc CS gọi user inactive
- [ ] **Friction** — cần hotfix / UX iteration → handoff `/ba` hoặc `/debugger`
- [ ] **Rejection** — feature không khớp nhu cầu → handoff `/da-discovery`

**Reasoning:** <1–2 câu giải thích verdict dựa trên số ở Q?>

---

## 📎 Appendix — Data Sources

### Q1 — Distinct users touched feature `<X>` per tenant
- **Context**: LogDbContext
- **Source**: `logging.activity` filtered by `caller_name` pattern
- **Tenant**: <list, lặp tenant>
- **Run at**: <YYYY-MM-DD HH:mm UTC+7>
- **SQL** (PostgreSQL):
  ```sql
  -- Hỏi: bao nhiêu distinct user chạm <X> kể từ release_at?
  SELECT
    COUNT(DISTINCT user_id) AS distinct_users,
    MIN(time) AS first_touch
  FROM logging.activity
  WHERE caller_name LIKE 'Smartlog.Application.Features.<X>.%'
    AND time >= '<release_at>'::timestamptz;
  ```

### Q2, Q3, ... — <theo pattern>
```

---

## Template C — Anomaly Note

```markdown
---
report_type: anomaly
generated_at: <ISO8601 +07:00>
generated_by: /da-ops
tenant_scope: <tenant alias | list>
slug: <YYYY-MM-DD-short-slug>
severity: critical | warning | info
queries_run: <N>
---

# Anomaly — <YYYY-MM-DD> — <slug>

**Detected when**: <khi đang chạy daily pulse | báo từ rollout team | monitor fired>
**Tenant scope**: <list>
**Pulled at**: <YYYY-MM-DD HH:mm UTC+7>

## 🚨 What's odd

<Mô tả bất thường — kèm số cụ thể từ Appendix>

| Metric | Observed | Expected (baseline) | Deviation | Q? |
|---|---:|---:|---:|:---:|
| <metric> | <num> | <num> | <%> | Q1 |

---

## 🔍 Hypotheses (ranked by likelihood)

### H1 (most likely) — <hypothesis>
- **Evidence ủng hộ:** <số / pattern từ Q?>
- **Evidence phản bác:** <nếu có>
- **Verification needed:** <action cụ thể>

### H2 — ...

---

## ✅ Verification needed

- [ ] <action> — owner: <name/role> — ETA: <date>
- [ ] <action> — owner: <name/role> — ETA: <date>

---

## 🎯 Severity assessment

- **Impact:** <ai bị ảnh hưởng, scope>
- **Urgency:** Now / This week / FYI
- **Suggested handoff:** `/debugger` (system bug) | `/da-biz-ba` (process issue) | rollout team (training/comms)

---

## 📎 Appendix — Data Sources

### Q1 — <main detection query>
- **Context**: <LogDbContext / AppDbContext>
- **Source**: <table>
- **Tenant**: <alias>
- **Run at**: <YYYY-MM-DD HH:mm UTC+7>
- **SQL**:
  ```sql
  -- Detection query
  ...
  ```

### Q2 — <baseline query để chứng minh đây là bất thường>
### Q3 — <evidence cho H1>
```

---

## Template D — Weekly Digest (cross-tenant)

Multi-tenant snapshot cho rollout team team-meeting đầu tuần.

```markdown
---
report_type: weekly
generated_at: <ISO8601 +07:00>
generated_by: /da-ops
tenant_scope: all-rollout
period_covered: <YYYY-WW> (Mon → Sun)
queries_run: <N>
---

# Weekly Ops Digest — Week <YYYY-WW> (<Mon date> → <Sun date>)

**Tenants in scope**: <N>
**Pulled at**: <YYYY-MM-DD HH:mm UTC+7>

## 🎯 Week Headline

<1 dòng câu chuyện tuần — vd "8/10 tenant healthy growth, 1 tenant volume drop > 40% (cần CS), 1 tenant LLM cost spike 3x">

**So-what for next week:** <top 1 priority>

---

## 📊 Tenant Health Matrix

| Tenant | Active users | Δ vs prev week | Conversations | Notebook runs | LLM $ | Top module | Health | Q? |
|---|---:|---:|---:|---:|---:|---|:---:|:---:|
| <name> | <num> | <%> | <num> | <num> | <$> | <module> | <emoji> | Q1 |

> Tenant code → tên: dùng dim/master mapping, không hiển thị guid trần.

---

## 🚀 Adoption Highlights

- **Top 3 active tenants:** <list với ngắn gọn lý do>
- **At-risk tenants** (volume Δ < −20%): <list + hypothesis>

---

## 🚨 Notable anomalies tuần này

| Date | Tenant | Anomaly | Severity | Status | Linked artifact |
|---|---|---|:---:|---|---|
| <YYYY-MM-DD> | <name> | <short> | <emoji> | <open/resolved> | <link to anomaly note> |

---

## 💡 Top 3 insights cross-tenant

### 1. <action title>
<insight 3-component, có ref Q?>

### 2. ...

### 3. ...

---

## ✅ Recommended actions next week

| # | Action | Owner | ETA |
|---|---|---|---|
| 1 | <action> | <role> | <date> |

---

## 📎 Appendix — Data Sources

> Lặp tenant — mỗi tenant có entry Q? riêng để truy vết.

### Q1 — Tenant Health Matrix snapshot
- **Pattern**: lặp `for tenant in list, run X` — kết quả merged ở report layer
- **Run at**: <YYYY-MM-DD HH:mm UTC+7>
- **SQL** per tenant:
  ```sql
  -- Active users + key counts last 7 days
  ...
  ```

### Q2, Q3, ... — <support insights>
```

---

## Template E — Incident Reconstruction

Dùng khi rollout/CS hỏi "user A báo lỗi lúc X, hãy giúp dựng lại chuyện gì xảy ra".

```markdown
---
report_type: incident
generated_at: <ISO8601 +07:00>
generated_by: /da-ops
ticket: <ticket-id>
tenant: <alias>
user: <user_id / email>
incident_window: <ISO8601> → <ISO8601>
queries_run: <N>
---

# Incident Reconstruction — <ticket> — <user> @ <tenant>

**Ticket**: <link/id>
**User**: <email> (<user_id>)
**Reported window**: <ISO8601> → <ISO8601> UTC+7
**Pulled at**: <YYYY-MM-DD HH:mm UTC+7>

## 🎯 What happened (timeline)

| Time (UTC+7) | Action (caller_name) | Entity (kind, id) | Result | Q? |
|---|---|---|---|:---:|
| <HH:mm:ss> | <handler> | <Conversation, abc-123> | success | Q1 |
| <HH:mm:ss> | <handler> | — | error: <message> | Q1 |

---

## 🔍 What's likely the issue

<1–2 câu hypothesis dựa trên timeline + entity diff + error pattern>

---

## 📎 Linked entities

| Entity kind | Id | Last action | Diff (old → new) | Q? |
|---|---|---|---|:---:|
| <Conversation> | <id> | <handler @ time> | <field: A → B> | Q2 |

---

## ✅ Recommended next step

- [ ] <Reproduce / handoff `/debugger`>
- [ ] <Update CS comm template với explanation>

---

## 📎 Appendix — Data Sources

### Q1 — Activity timeline
- **Context**: LogDbContext
- **Source**: `logging.activity` filtered by user_id + window
- **Run at**: <ISO8601>
- **SQL**:
  ```sql
  SELECT time, caller_name, label, parameters, request_id
  FROM logging.activity
  WHERE user_id = '<user_guid>'
    AND time BETWEEN '<from>' AND '<to>'
  ORDER BY time;
  ```

### Q2 — Entity diffs
- **Source**: `logging.entity` joined to activity
- **SQL**:
  ```sql
  SELECT a.time, e.entity_name, e.action, e.old_value, e.new_value
  FROM logging.entity e
  JOIN logging.activity a ON e.activity_id = a.id
  WHERE a.user_id = '<user_guid>'
    AND a.time BETWEEN '<from>' AND '<to>'
  ORDER BY a.time;
  ```
```

---

## Tips viết artifact chất lượng

1. **Action title** — không chỉ là label, mà là kết luận:
   - ❌ "Activity volume hôm nay"
   - ✅ "Volume hôm nay −38% vs same-weekday baseline — 2 power user nghỉ"

2. **3-component insight rule** (theo SKILL.md):
   - Con số cụ thể (có Q?) + So sánh (có baseline query) + Action implication

3. **Bottom Line Up Front** — rollout team đọc 30s đầu là đủ nắm câu chuyện

4. **Không giữ section rỗng** — nếu Insight 5 không có data → cắt, ghi "chỉ 3 insight tuần này, nhiều tuần sau" trong Open questions

5. **Link tới source** — entity file path, QueryConfig, glossary → user verify độc lập

6. **Chart Block 3-layer (ASCII + Data + Spec)** — bắt buộc cho numeric breakdown ≥ 5 dòng / time series ≥ 7 điểm / comparison ≥ 2 baseline / 2D segmentation / volatility ≥ 3 segments. Pattern chi tiết: §Chart Patterns dưới đây.

7. **Tên đọc được** (Name > Code rule) — `tenant.display_name` không phải GUID; `user_email` không phải `user_id` raw. Code chỉ ở Appendix/tooltip.

---

## Chart Patterns Library

> 4 pattern chuẩn cho Chart Block 3-layer. Copy-paste rồi điền data thật từ Appendix queries. Mỗi pattern map 1-1 với 1 lens.

### Pattern 1 — Pareto (Lens #5 Concentration)

**Khi nào:** Numeric breakdown theo dimension (user, module, tenant, monitor), cần show concentration risk + cumulative %.

```markdown
#### Chart: <action title — "Top N <dim> = X% <metric>, <implication>">

**ASCII:**
```
                  0%      25%     50%     75%    100%   cum%
<item 1>  ████████████████████      <pct>%  ←─────────────────  <cum>%
<item 2>  █████████████          <pct>%  ←──────────         <cum>%   ← Top 2
<item 3>  █████                  <pct>%  ←────────           <cum>%   ← Top N marker
...
```

**Data:**
| rank | name | (id) | value | pct | cum_pct |
| 1 | <display name> | <id, fine print> | <num> | <num> | <num> |
...

**Spec:**
  type: pareto
  x: <name_col>
  y_left: <value_col> (bar)
  y_right: cum_pct (line)
  reference: top5_cum=<%>, top10_cum=<%>
  audience: <Rollout | PM | BA | Ops>
  action_title: "..."
```

**Lưu ý:**
- Bar length = `round(pct * 40 / 100)` ký tự `█` (40 = chiều rộng max)
- ASCII và Data PHẢI khớp số 100%
- "name" là column hiển thị; "id" (guid/code) chỉ ghi nếu thực sự cần truy vết, ưu tiên không hiển thị

---

### Pattern 2 — RAG Comparison Bar (Lens #7 Comparison)

**Khi nào:** So 1 metric vs ≥ 2 baseline (expectation / prior week / same-weekday / peer tenant).

```markdown
#### Chart: <action title — "<metric> <delta> vs <baseline chính>, gap chính là <baseline gap nhất>">

**ASCII:**
```
            0%      25%      50%      75%     100%  Δ
Baseline    ████████████████████████████░░░░░       (reference)
Current     ██████████████████████████░░░░░░  <Δ>  <rag>
Prior week  ███████████████████████████░░░░░  <Δ>  <rag>
Same-weekday avg  █████████████████████████░░░░░░░  <Δ>  <rag>
Peer tenant ██████████████████████████████░░  <Δ>  <rag>
            └── baseline ────┘
```

**Data:**
| baseline | value | delta | rag | Q? |
| expectation | <num> | <Δ> | <rag> | Q? |
| prior_week | <num> | <Δ> | <rag> | Q? |
| same_weekday_avg | <num> | <Δ> | <rag> | Q? |
| peer_tenant_<name> | <num> | <Δ> | <rag> | Q? |
| current | <num> | — | — | Q? |

**Spec:**
  type: rag-bar
  x: baseline
  y: <metric_col>
  reference: expectation=<num>, current=<num>
  audience: Rollout + PM
  action_title: "..."
```

**Lưu ý:**
- Delta column **bắt buộc có dấu** (`+12%` / `−38%`)
- "Peer" phải cùng tenant tier — KHÔNG so tenant 5 user với tenant 500 user
- Baseline phải có Q? riêng — KHÔNG ghi đại

---

### Pattern 3 — Heatmap RAG (Lens #8 Segmentation 2D)

**Khi nào:** Segmentation 2D (Tenant × Module, Module × Hour, Role × Module).

```markdown
#### Chart: <action title — "<cell xấu nhất> = <giá trị>, <implication>">

**ASCII:**
```
<metric> theo <Y> × <X>  (baseline <T>; 🔴 lệch>−35%, 🟡 −15..−35%, 🟢 ≥−15%)

              <X1>          <X2>          <X3>
<Y1>     <rag> <v> [<Δ>]   <rag> <v> [<Δ>]   <rag> <v> [<Δ>]
<Y2>     <rag> <v> [<Δ>]   <rag> <v> [<Δ>]   <rag> <v> [<Δ>]
<Y3>     <rag> <v> [<Δ>]   <rag> <v> [<Δ>]   <rag> <v> [<Δ>]
                                       ↑ <annotation cho cell xấu nhất>
```

**Data:**
| <y_col> | <x_col> | value | baseline | delta | rag |
| <Y1> | <X1> | <num> | <num> | <Δ> | <rag> |
...

**Spec:**
  type: heatmap
  x: <x_col>
  y: <y_col>
  z: value (cell)
  reference: baseline=<num>, thresholds=[−35,−15]
  audience: PM + Rollout
  action_title: "..."
```

**Lưu ý:**
- Cell format: `<emoji> <value> [<delta>]` — 3 thông tin compact
- **Simpson check** trong Insight nếu là cross-tenant aggregate (tránh paradox)
- Annotation arrow `↑` chỉ vào cell có insight chính

---

### Pattern 4 — CV Bar / Volatility (Lens #9)

**Khi nào:** Volatility (CV%) cho ≥ 3 segments (tenant, user, module).

```markdown
#### Chart: <action title — "<segment> CV <cv>% — <implication>">

**ASCII:**
```
CV% (Coefficient of Variation, 14d daily)  — band: 🟢 <20  🟡 20-50  🔴 >50

<seg 1>        ████████░░░░░░░░░░░░░░░░░░░░░░░░  <cv>%  🟢  Reliable
<seg 2>        ██████████████████████░░░░░░░░░░  <cv>%  🟡  Moderate
<seg 3>        ████████████████░░░░░░░░░░░░░░░░  <cv>%  🟡  Moderate
<seg 4>        ████████████████████████████████████████████████  <cv>%  🔴  Volatile
                              └─ band reliable ─┘└─ band moderate ─┘└─── volatile ───→
```

**Data:**
| segment | mean_daily | std | cv_pct | band |
| <s1> | <num> | <num> | <num> | reliable |
...

**Spec:**
  type: cv-bar
  x: segment
  y: cv_pct
  reference: band_reliable=20, band_moderate=50
  audience: PM + Rollout
  action_title: "..."
```

**Lưu ý:**
- Band defaults adapt sang Smartlog: reliable < 20%, moderate 20–50%, volatile > 50% (rộng hơn SC tradition vì SaaS rollout volatile hơn).
- Insight phải nói **implication**: tenant CV>50% thì baseline single-point không tin được → dùng band scenario hoặc widen alert threshold.

---

### Pattern 5 — Time Series Sparkline (Lens #4 Timeline)

> Pattern phụ — quick visual trong RAG matrix. Time series chính (≥ 7 điểm) dùng Pattern 1/2 với bar.

**Quick reference:**

```
Sparkline 7-day: ▆▇█▇▆▅▄ (Mon → Sun, height ∝ daily count)
```

Compact dùng trong cột "Trend" của bảng tổng hợp.

---

## Chart Block — Validation Checklist (self-review trước khi commit)

- [ ] Mỗi numeric breakdown ≥ 5 dòng có Chart Block (không phải chỉ bảng đơn)
- [ ] Mỗi Chart Block có đủ 3 layer: ASCII + Data + Spec
- [ ] ASCII và Data **khớp số 100%** (cùng làm tròn, cùng đơn vị)
- [ ] Spec có `audience` + `action_title` (không rỗng)
- [ ] `action_title` nói **so-what**, không phải label ("Volume theo module" ❌ vs "Module Notebook chỉ 3% — adoption miss target ✅")
- [ ] Chart Block heading khớp với `action_title` của Spec
- [ ] **Tên đọc được** trong Data (Name > Code) — id chỉ ở column phụ hoặc tooltip
- [ ] Có Q? reference chỉ tới Appendix
- [ ] Không còn placeholder `<...>` trôi vào output cuối
- [ ] Không còn số ví dụ template (mọi `<num>` đã được thay bằng số thật)
