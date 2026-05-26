# Data Fetch Patterns — da-ops

> Reference cho `/da-ops`. Cách query data an toàn trong stack .NET 10 + EF Core + multi-tenant + 2-context (LogDbContext / AppDbContext) + per-tenant connection.
>
> **Rule cứng:** Mọi con số trong artifact phải đến từ query thật (xem hard rule trong [SKILL.md](../SKILL.md)). File này lo cách CHẠY query — KHÔNG lo có nên fabricate số không (câu trả lời luôn là không).

---

## Bối cảnh stack

| Tầng | Tech | Note |
|---|---|---|
| Backend | .NET 10 Web API | CQRS pipeline có `LoggingBehavior`, `PerformanceLoggingBehavior`, `ValidationBehavior` |
| ORM | EF Core | 2 DbContext: `AppDbContext` (domain, schema default + per-module) + `LogDbContext` (`logging` schema, separate tables) |
| DB providers | PostgreSQL hoặc MSSQL | Detected từ connection string prefix (`Host=` → Npgsql, `Server=` → MSSQL); một số tenant chạy 1, một số 2 |
| Multi-tenant | `IDbContextResolver` → `TenantBasedDbContextResolver` | Connection lấy từ JWT claim `AppClaimTypes.TenantDBConfiguration`, fallback `DefaultConnection` (dev) |

**Implication cho `/da-ops`:**
- Mỗi tenant = 1 connection riêng. Cross-tenant phải lặp.
- LogDbContext và AppDbContext **không EF-join được** dù đôi khi cùng physical DB — kéo riêng, merge ở report.
- Query SQL flavor depends on tenant DB type — cần biết mỗi tenant chạy gì (PG hay MSSQL) trước khi viết SQL.

---

## 3 Cách Fetch Data (chọn theo tình huống)

### Option 1 — QueryConfig endpoint sẵn có (KHUYẾN NGHỊ trước tiên)

Nếu câu hỏi đã có endpoint trong `backend/src/QueryConfigs/*.json` → gọi qua API, không tự viết SQL.

Pros: RBAC enforced (JWT scope tenant tự động), logic đồng bộ với UI, không cần connection string trực tiếp.
Cons: Phải có dev user JWT; chỉ trả về theo schema config đã định.

```bash
# Dev: API ở https://localhost:5001 (hoặc http://localhost:5000)
# JWT từ login dev user
curl -k -H "Authorization: Bearer $JWT" \
  "https://localhost:5001/api/<resource>?<filters>" \
  | jq '.'
```

**Khi nào dùng:** Câu hỏi rơi vào view đã có (vd "list user role X", "active monitors") — bám list `backend/src/QueryConfigs/`.

### Option 2 — EF Core / dotnet-script ad-hoc trong dev

Khi cần aggregation phức tạp hoặc query LogDbContext (không expose qua endpoint trừ khi dev viết riêng).

```bash
# Verify connection cho tenant đang test (dev fallback DefaultConnection):
dotnet user-secrets list --project backend/src/Smartlog.Api

# Hoặc xem appsettings.Development.json (KHÔNG commit credentials)
```

Quick LINQ trong dev (ví dụ — không commit):
```csharp
// scripts/da-ops-query.csx (dotnet-script, không commit)
using Smartlog.Infrastructure;
// ... bootstrap minimal services with tenant connection ...

var logCtx = scope.ServiceProvider.GetRequiredService<LogDbContext>();
var since = DateTime.UtcNow.AddDays(-7);
var byUser = await logCtx.Activities
    .Where(a => a.Time >= since)
    .GroupBy(a => a.UserEmail)
    .Select(g => new { Email = g.Key, Count = g.Count() })
    .OrderByDescending(x => x.Count)
    .Take(20)
    .ToListAsync();
```

Pros: Strong typing với entity, dễ refactor; tự respect cấu hình DB provider.
Cons: Cần dev environment + bootstrap DI; bypass RBAC nếu skill dùng connection trực tiếp — chỉ dùng khi user có quyền analyst level.

**Khi nào dùng:** Cần kéo cross-table aggregation, hoặc tận dụng entity navigation properties.

### Option 3 — Direct SQL via DB CLI (psql / sqlcmd / SSMS)

Nhanh nhất cho profile / sanity check. Cần connection string của tenant đang query.

```bash
# PostgreSQL (Npgsql tenant)
psql "postgres://user:pass@host:5432/dbname" -c "SELECT COUNT(*) FROM logging.activity WHERE time >= now() - INTERVAL '24 hours';"

# MSSQL (cho tenant chạy SQL Server)
sqlcmd -S host -d dbname -U user -P pass -Q "SELECT COUNT(*) FROM logging.activity WHERE time >= DATEADD(hour, -24, SYSUTCDATETIME());"
```

Pros: Nhanh, không cần bootstrap.
Cons: Credentials trong shell history → cẩn thận với prod creds; phải tự handle SQL flavor difference.

**Khi nào dùng:** Profile shape, quick row count, single-table aggregation.

---

## Checklist Trước Khi Query

- [ ] **Tenant scope đã rõ** — connection đang trỏ tenant nào? Cross-tenant cần lặp tenant.
- [ ] **DB provider đã biết** (PostgreSQL hay MSSQL) — SQL syntax khác nhau (xem §SQL Flavor bên dưới).
- [ ] **Context đúng**: activity log → `LogDbContext` / `logging.*`; domain entity → `AppDbContext` / default schema.
- [ ] **Soft-delete filter** `DeletedTime IS NULL` cho `BaseSoftDeletedEntity` artifacts (Conversation, Notebook, Dashboard, ...). Activity log KHÔNG cần filter này.
- [ ] **Time conversion** UTC ↔ UTC+7 đã handle khi present (DB lưu UTC).
- [ ] **LIMIT** ≤ 10000 cho ad-hoc list query (tránh load quá nhiều); aggregate query thì không cần.
- [ ] **Parameterize input** (tenant code, date range, user_id) — không string-concat user input.
- [ ] **Append vào Appendix** SQL + tenant + run-at trước khi commit số vào artifact.

---

## SQL Flavor — PostgreSQL vs MSSQL

Smartlog tenant DB có thể là một trong hai. Một số function khác nhau — write portable nếu có thể, hoặc note rõ flavor.

| Operation | PostgreSQL | MSSQL |
|---|---|---|
| Now UTC | `now() AT TIME ZONE 'UTC'` hoặc `current_timestamp` | `SYSUTCDATETIME()` |
| Date arithmetic | `now() - INTERVAL '7 days'` | `DATEADD(day, -7, SYSUTCDATETIME())` |
| Truncate to day | `date_trunc('day', col)` | `CAST(col AS DATE)` |
| Truncate to hour | `date_trunc('hour', col)` | `DATETIMEFROMPARTS(YEAR(col), MONTH(col), DAY(col), DATEPART(hour, col), 0, 0, 0)` |
| Day-of-week | `EXTRACT(dow FROM col)` (0=Sun) | `DATEPART(weekday, col)` (1=Sun, depends on DATEFIRST) |
| Conditional count | `COUNT(*) FILTER (WHERE cond)` | `SUM(CASE WHEN cond THEN 1 ELSE 0 END)` |
| Percentile | `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY col)` | `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY col) OVER ()` (cần OVER) |
| Stddev pop | `STDDEV_POP(col)` | `STDEVP(col)` |
| Correlation | `corr(a, b)` | Không có built-in — viết thủ công với SUM/AVG, hoặc skip |
| String split | `split_part(s, '.', 4)` | `PARSENAME(REPLACE(s, '.', '#'), 3)` (cẩn thận với số dot khác 4) |
| UTC → UTC+7 | `col AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh'` | `col AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time'` |

Templates dưới đây mặc định **PostgreSQL** (tenant phổ biến hơn). MSSQL alt khi cần.

---

## Query Patterns — Per Lens

### Lens #0 — Profile

**Activity log shape (LogDbContext / `logging` schema):**

```sql
-- PostgreSQL
SELECT
  COUNT(*)                                   AS rows,
  MIN(time)                                  AS first_event,
  MAX(time)                                  AS last_event,
  COUNT(DISTINCT user_id)                    AS distinct_users,
  COUNT(DISTINCT caller_name)                AS distinct_handlers
FROM logging.activity
WHERE time >= now() - INTERVAL '7 days';
```

**Column-level sanity:**

```sql
SELECT
  COUNT(*) FILTER (WHERE user_id IS NULL)           * 100.0 / COUNT(*) AS user_null_pct,
  COUNT(*) FILTER (WHERE user_email IS NULL OR user_email = '') * 100.0 / COUNT(*) AS email_empty_pct,
  COUNT(*) FILTER (WHERE caller_name IS NULL OR caller_name = '') * 100.0 / COUNT(*) AS caller_empty_pct,
  COUNT(*) FILTER (WHERE label IS NULL OR label = '') * 100.0 / COUNT(*) AS label_empty_pct
FROM logging.activity
WHERE time >= now() - INTERVAL '7 days';
```

**Domain artifact (AppDbContext) profile (vd Conversation):**

```sql
SELECT
  COUNT(*)                                          AS rows,
  COUNT(*) FILTER (WHERE deleted_time IS NOT NULL)  AS soft_deleted,
  MIN(created_time)                                  AS first_created,
  MAX(created_time)                                  AS last_created,
  COUNT(DISTINCT user_id)                            AS distinct_owners,
  COUNT(DISTINCT data_source_id)                     AS distinct_data_sources
FROM "Conversations";
```

### Lens #1 — Completeness theo time partition

```sql
-- Activity volume per hour, last 7 days (PostgreSQL)
SELECT
  date_trunc('hour', time) AS bucket,
  COUNT(*)                  AS events,
  COUNT(DISTINCT user_id)   AS distinct_users
FROM logging.activity
WHERE time >= now() - INTERVAL '7 days'
GROUP BY bucket
ORDER BY bucket;
-- Detect: giờ "câm" trong office hours = ingestion lag hoặc downtime
```

### Lens #2 — Distribution

```sql
-- LLM token distribution (last 14 days)
SELECT
  AVG(total_tokens)                                                         AS mean,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY total_tokens)                AS p50,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_tokens)                AS p95,
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_tokens)                AS p99,
  STDDEV_POP(total_tokens)                                                  AS std,
  MIN(total_tokens) AS min_v,
  MAX(total_tokens) AS max_v
FROM "LlmUsageLog"
WHERE total_tokens > 0
  AND created_time >= now() - INTERVAL '14 days';
```

### Lens #3 — Outliers (IQR)

```sql
-- Outlier MonitorRun execution times (PostgreSQL)
WITH stats AS (
  SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY execution_time_ms) AS q1,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY execution_time_ms) AS q3
  FROM "MonitorRuns"
  WHERE execution_time_ms > 0
    AND created_time >= now() - INTERVAL '7 days'
)
SELECT mr.id, mr.monitor_id, mr.execution_time_ms, mr.created_time, mr.status, mr.summary
FROM "MonitorRuns" mr, stats s
WHERE mr.created_time >= now() - INTERVAL '7 days'
  AND (
    mr.execution_time_ms < s.q1 - 1.5 * (s.q3 - s.q1)
    OR mr.execution_time_ms > s.q3 + 1.5 * (s.q3 - s.q1)
  )
ORDER BY mr.execution_time_ms DESC
LIMIT 30;
```

### Lens #4 — Timeline (rolling daily / same-weekday)

```sql
-- Daily activity 8 weeks rolling
SELECT
  date_trunc('day', time)::date AS d,
  EXTRACT(dow FROM time)         AS weekday,  -- 0=Sun..6=Sat
  COUNT(*)                        AS actions,
  COUNT(DISTINCT user_id)         AS distinct_users
FROM logging.activity
WHERE time >= now() - INTERVAL '8 weeks'
GROUP BY d, weekday
ORDER BY d;
```

```sql
-- Same-weekday comparison: today vs avg(4 prior same-weekdays)
WITH today AS (
  SELECT COUNT(*) AS c
  FROM logging.activity
  WHERE time::date = current_date
),
prior_same_weekday AS (
  SELECT date_trunc('day', time)::date AS d, COUNT(*) AS c
  FROM logging.activity
  WHERE time::date < current_date
    AND time >= current_date - INTERVAL '5 weeks'
    AND EXTRACT(dow FROM time) = EXTRACT(dow FROM current_date)
  GROUP BY d
  ORDER BY d DESC
  LIMIT 4
)
SELECT
  (SELECT c FROM today)                                     AS today_actions,
  (SELECT AVG(c) FROM prior_same_weekday)                   AS baseline_avg,
  (SELECT c FROM today) - (SELECT AVG(c) FROM prior_same_weekday)  AS delta;
```

### Lens #5 — Concentration (Pareto)

```sql
-- Top users by activity, with cumulative %
SELECT
  user_email,
  COUNT(*)                                                                         AS actions,
  COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()                                         AS pct,
  SUM(COUNT(*)) OVER (ORDER BY COUNT(*) DESC) * 100.0 / SUM(COUNT(*)) OVER ()      AS cum_pct
FROM logging.activity
WHERE time >= now() - INTERVAL '7 days'
GROUP BY user_email
ORDER BY actions DESC
LIMIT 50;
```

```sql
-- Module Pareto (split caller_name)
SELECT
  split_part(caller_name, '.', 4) AS module,
  COUNT(*)                          AS actions,
  COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()  AS pct
FROM logging.activity
WHERE time >= now() - INTERVAL '7 days'
  AND caller_name IS NOT NULL AND caller_name <> ''
GROUP BY module
ORDER BY actions DESC;
```

### Lens #6 — Correlation

```sql
-- Tokens vs cost vs error rate per day
WITH daily AS (
  SELECT
    date_trunc('day', created_time)::date AS d,
    SUM(total_tokens)                      AS tokens,
    SUM(estimated_cost_usd)                AS cost,
    COUNT(*)                                AS calls
  FROM "LlmUsageLog"
  WHERE created_time >= now() - INTERVAL '60 days'
  GROUP BY d
)
SELECT
  corr(tokens, cost)  AS r_tokens_cost,
  corr(tokens, calls) AS r_tokens_calls,
  COUNT(*)            AS sample_days
FROM daily;
-- MSSQL không có corr() — skip hoặc compute manual qua SUM/AVG
```

### Lens #7 — Comparison (multi-baseline)

```sql
-- Today vs yesterday vs same-weekday vs week ago
WITH ranges AS (
  SELECT
    SUM(CASE WHEN time::date = current_date THEN 1 ELSE 0 END)                    AS today,
    SUM(CASE WHEN time::date = current_date - 1 THEN 1 ELSE 0 END)                AS yesterday,
    SUM(CASE WHEN time::date = current_date - 7 THEN 1 ELSE 0 END)                AS same_weekday_last_week,
    SUM(CASE WHEN time::date BETWEEN current_date - 7 AND current_date - 1 THEN 1 ELSE 0 END) AS prior_week_total
  FROM logging.activity
  WHERE time >= current_date - INTERVAL '14 days'
)
SELECT * FROM ranges;
```

### Lens #8 — Segmentation (2D)

```sql
-- Module × Hour-of-day heatmap (last 7 days, UTC+7)
SELECT
  split_part(caller_name, '.', 4) AS module,
  EXTRACT(hour FROM (time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh')) AS hour_local,
  COUNT(*) AS actions
FROM logging.activity
WHERE time >= now() - INTERVAL '7 days'
  AND caller_name IS NOT NULL AND caller_name <> ''
GROUP BY module, hour_local
ORDER BY module, hour_local;
```

### Lens #9 — Volatility (CV per user / module)

```sql
-- CV per module across 14 days
WITH daily AS (
  SELECT
    split_part(caller_name, '.', 4) AS module,
    date_trunc('day', time)::date    AS d,
    COUNT(*)                          AS actions
  FROM logging.activity
  WHERE time >= now() - INTERVAL '14 days'
    AND caller_name IS NOT NULL AND caller_name <> ''
  GROUP BY module, d
)
SELECT
  module,
  AVG(actions)                       AS mean_daily,
  STDDEV_POP(actions)                AS std_daily,
  STDDEV_POP(actions) / NULLIF(AVG(actions), 0) * 100 AS cv_pct,
  COUNT(*)                            AS sample_days
FROM daily
GROUP BY module
HAVING AVG(actions) > 0
ORDER BY cv_pct DESC;
```

---

## Multi-tenant Iteration Pattern

Smartlog không có "global view" — phải lặp tenant. Pseudocode pattern:

```python
# Pseudocode — adapt sang dotnet-script / psql wrapper / bash loop
for tenant in tenant_list:
    conn = resolve_connection(tenant.code)  # claim TenantDBConfiguration đã decode hoặc dev secret
    df_log = run_sql(conn, ACTIVITY_PROFILE_SQL)
    df_app = run_sql(conn, ARTIFACT_PROFILE_SQL)
    rows.append({
        "tenant": tenant.code,
        "tenant_name": tenant.display_name,    # đọc từ master/dim — KHÔNG hiển thị code trần
        "actions_today": df_log["today_actions"][0],
        "baseline":     df_log["baseline_avg"][0],
        # ...
    })

merged = pd.DataFrame(rows)
# Render Pareto / heatmap / RAG matrix theo tenant
```

Caveats khi tổng hợp cross-tenant:
- KHÔNG aggregate raw counts thẳng — tenant size khác xa nhau (Simpson's paradox).
- Mỗi metric có thể có RAG khác nhau theo tier tenant — note tier trong cột.
- Tên tenant phải đọc được, KHÔNG hiển thị `tenant_id = guid` trần (xem rule Name > Code).

---

## RBAC & Tenant Scoping

Khi user của `/da-ops` có role analyst toàn org:
- API endpoint (Option 1) tự inject scope theo JWT claim — an toàn default.
- Direct SQL (Option 2/3) bypass RBAC — chỉ dùng khi user thực sự có quyền cross-tenant analyst (xác nhận trước với rollout/PM).

Nếu skill chạy với role bị scope (vd 1 tenant) → KHÔNG lén query tenant khác để "complete picture". Báo limitation, đề xuất escalate.

---

## Secrets / Credentials

- Connection string lấy từ:
  - **Dev**: `appsettings.Development.json` `ConnectionStrings:DefaultConnection`, hoặc `dotnet user-secrets`
  - **Per-tenant**: claim `TenantDBConfiguration` (decode JWT)
  - **Pipeline/dotnet-script**: env var `ConnectionStrings__DefaultConnection`
- **KHÔNG** paste credentials vào artifact / Appendix
- **KHÔNG** commit script ad-hoc có credentials (đặt trong `scripts/local/` đã `.gitignore`, hoặc `c:/tmp/`)
- Nếu credentials missing → STOP, hướng dẫn user setup, KHÔNG hardcode fallback

---

## Error Handling

| Triệu chứng | Khả năng | Hành động |
|---|---|---|
| `relation "logging.activity" does not exist` (PG) / `Invalid object name` (MSSQL) | Schema chưa migrate hoặc tenant chưa enable activity log | Verify migrations applied; nếu tenant mới → ghi `[chưa có history]` không fabricate |
| `column "xxx" does not exist` | Schema lệch entity definition (entity changed, DB chưa migrate) | Đọc entity file → re-check; nếu cần, đề xuất migration |
| Empty result | Period lệch / tenant không hoạt động / activity log filter quá hẹp | Check `MAX(time)` với widening period; nếu vẫn empty → ghi `[N/A]` + lý do |
| Query timeout | Thiếu LIMIT / index / aggregation xấu | Reduce period; aggregate trước rồi join; LIMIT 10000 |
| 401/403 từ API endpoint | JWT expired / RBAC scope | Re-login dev user; nếu thiếu quyền → escalate |
| `Connection refused` | DB host không reachable / port wrong / wrong tenant | Verify connection alias + ping host; KHÔNG fallback sang tenant khác |
| `corr()` không tồn tại (MSSQL) | Function chỉ có trong PG | Compute manual qua SUM/AVG hoặc skip Lens #6 cho tenant này |

Mọi error → STOP, ghi `[N/A]` + nguyên nhân vào artifact, KHÔNG fabricate số.

---

## Liên quan

- Entity classes: `backend/src/Smartlog.Domain/Entities/`
- LogDbContext: `backend/src/Smartlog.Infrastructure/ActivityLogs/`
- AppDbContext: `backend/src/Smartlog.Infrastructure/EntityFramework/`
- Tenant resolver: `backend/src/Smartlog.Infrastructure/EntityFramework/IDbContextResolver.cs`
- QueryConfigs: `backend/src/QueryConfigs/*.json`
- Activity log commit logic: `backend/src/Smartlog.Application/Services/ActivityLogContext.cs`
- Multi-tenant claim type: `AppClaimTypes.TenantDBConfiguration`
- Performance log threshold: 1000ms (xem `PerformanceLoggingBehavior` decorator trong Application layer)
