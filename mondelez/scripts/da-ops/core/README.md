# /da-ops core kit — Mondelez (ClickHouse `analytics_workspace`)

Per-tenant variant của core query kit định nghĩa trong [.claude/skills/da-ops/SKILL.md](../../../../../.claude/skills/da-ops/SKILL.md) §"Core query kit". Mondelez stack = ClickHouse Cloud (không phải PG/MSSQL với `logging.activity` như default skill assumption).

Mỗi script trong folder này tương ứng với 1 ID trong skill catalog (C00..C07). Header convention bắt buộc: `name`, `params`, `flavor`, `schema_deps`, `maps_to_lens`, `last_verified`, `expected_shape`.

## Catalog

| ID | Status | File | Maps to lens | Notes |
|---|---|---|---|---|
| C00 | ✅ verified 2026-05-10 | `C00_profile-tenant.ch.sql` | #0 Profile | Sanity check 16 leaf KPI MVs trước khi tin số |
| C01 | ⏳ TODO | `C01_do-volume-by-channel.ch.sql` | #5 Concentration | Pareto DO outbound theo channel/category — thay `activity-volume-by-module` (no user activity in CH) |
| C02 | ⏳ TODO | `C02_top-warehouses-pareto.ch.sql` | #5 Concentration | Pareto theo `whseid` — thay `top-users-pareto` (no user data) |
| C03 | ⏳ TODO | `C03_do-volume-by-hour.ch.sql` | #1, #8 | Heatmap giờ ship — peak load hour |
| C04 | ⏳ TODO | `C04_otif-same-weekday-baseline.ch.sql` | #4, #7 | OTIF rate today vs avg(4 same-weekday gần nhất) |
| C05 | N/A | — | — | `distinct-users-touched-feature` — không có user activity data trên CH |
| C06 | ⏳ TODO | `C06_otif-funnel.ch.sql` | #1 | created → on-time → in-full → otif pass funnel |
| C07 | ⏳ TODO | `C07_wh-silence-detector.ch.sql` | #1 | Kho nào không có DO ship trong N giờ peak |

C02 user-activity và C05 đều phụ thuộc activity log (không có ở Mondelez stack) → mark N/A. Khi có tenant khác chạy PG/MSSQL với LogDbContext, viết riêng dưới `projects/<other-tenant>/scripts/da-ops/core/`.

## Setup credentials

Đã có sẵn ở [projects/mondelez/.env](../../../.env). Load env trước khi chạy:

**PowerShell:**
```powershell
Get-Content projects/mondelez/.env | Where-Object { $_ -match '^[A-Z]' } | ForEach-Object {
  $k,$v = $_ -split '=',2
  Set-Item -Path "env:$k" -Value $v
}
```

**Bash (Git Bash):**
```bash
export $(grep -v '^#' projects/mondelez/.env | xargs)
```

## Run a script

**curl:**
```bash
curl -s --user "$CLICKHOUSE_USER:$CLICKHOUSE_PASSWORD" \
  -H "Content-Type: text/plain" \
  --data-binary @projects/mondelez/scripts/da-ops/core/C00_profile-tenant.ch.sql \
  "https://$CLICKHOUSE_HOST:8443/?database=analytics_workspace&default_format=PrettyCompactMonoBlock"
```

**PowerShell (Invoke-RestMethod):**
```powershell
$body = Get-Content -Raw projects/mondelez/scripts/da-ops/core/C00_profile-tenant.ch.sql
$auth = "Basic " + [Convert]::ToBase64String(
  [Text.Encoding]::ASCII.GetBytes("$env:CLICKHOUSE_USER:$env:CLICKHOUSE_PASSWORD"))
Invoke-RestMethod -Method Post -Body $body `
  -Uri "https://$env:CLICKHOUSE_HOST:8443/?database=analytics_workspace&default_format=PrettyCompactMonoBlock" `
  -Headers @{ Authorization = $auth }
```

Output formats khác:
- `default_format=TabSeparatedWithNames` — máy đọc
- `default_format=JSONEachRow` — pipe vào jq / pandas
- `default_format=Pretty` — terminal eyeball

## Output convention C00

C00 trả 1 hàng / leaf KPI MV với:

| Cột | Ý nghĩa |
|---|---|
| `mv` | Tên MV |
| `time_col` | Cột time canonical đã chọn (xem header SQL) |
| `rows` | Số rows có time không null |
| `min_d` / `max_d` | Range time trong MV |
| `lag_days` | Số ngày từ `max_d` đến hôm nay (UTC+7) |
| `status` | `FRESH` (≤1d), `OK` (=2d), `LAGGING` (3-7d), `STALE` (>7d), `EMPTY` (rows=0) |

**Decision rule cho pulse author:**
- Trước khi viết bất kỳ pulse note nào: chạy C00. Nếu MV cần dùng có `status != FRESH/OK` → STOP, ghi `[N/A]` cho metric đó, không fabricate.
- Nếu nhiều MV cùng `STALE` cùng lúc → có thể pipeline upstream (Redshift → CH ingestion) gặp vấn đề — handoff về data team trước khi viết pulse.

## Maintenance

- `last_verified` trong SQL header = ngày cuối cùng query chạy thành công với schema hiện tại
- Khi backend đổi MV definition (xem [projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql](../../../02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql)) → re-run C00 để verify; nếu lỗi schema → bump `last_verified` sau khi fix
- Re-run mỗi đầu pulse session — không trust `last_verified` cũ hơn 7 ngày
- KHÔNG promote C01..C07 vào folder này nếu chưa lặp ≥ 3 pulse khác nhau (rule trong SKILL.md)

## Liên quan

- Skill chính: [.claude/skills/da-ops/SKILL.md](../../../../../.claude/skills/da-ops/SKILL.md)
- ClickHouse skill (technical SQL layer): [.claude/skills/da-ch/](../../../../../.claude/skills/da-ch/)
- DDL snapshot: [projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql](../../../02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql)
- Connection: [projects/mondelez/.env](../../../.env)
