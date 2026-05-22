# Panasonic — Smartlog Control Tower

Workspace của dự án **Panasonic** trên Control Tower. Hiện tại scope = **PSV** (Phương án Sắp Vận tải) — output từ module OPS Optimizer trên TMS của Panasonic.

> Cluster ClickHouse dùng chung với Mondelez (`ghrx9lirdl.ap-southeast-1.aws.clickhouse.cloud`), schema `analytics_workspace`. Phân biệt data theo prefix bảng (`psv_*`) hoặc theo nguồn CDC (`tms_panasonic_prod.*`).

---

## Cấu trúc thư mục

```
projects/panasonic/
├── README.md                       ← bạn đang đọc
├── .env.example                    ← template credential CH (copy thành .env)
│
├── 02-data/
│   ├── glossary.md                 ← thuật ngữ PSV (chuyến, status_name_detail, ...)
│   ├── audit-results/              ← output audit theo template /da-ch (s2-*.md)
│   └── data-sources/
│       ├── pipeline.md             ← luồng dữ liệu 4 node (SQL Server → CDC → MV → UI)
│       └── clickhouse-ddl/
│           ├── analytics-workspace_psv.md   ← DDL có comment, lineage, caveats
│           └── analytics-workspace_psv.sql  ← raw DDL (copy-paste ready)
│
└── scripts/da-ch/
    ├── run.ps1                     ← PowerShell wrapper chạy SQL trên CH
    ├── run.sh                      ← Bash wrapper (cùng chức năng)
    └── core/
        ├── C00_profile-psv.ch.sql                     ← health check pipeline
        ├── C01_psv-summary-by-month.ch.sql            ← tổng quan theo tháng
        ├── C02_psv-by-vendor.ch.sql                   ← phân tích nhà vận tải
        ├── C03_psv-by-vehicle-type.ch.sql             ← phân tích loại xe + utilization
        ├── C04_psv-top-routes.ch.sql                  ← top tuyến đường (from→to)
        └── C05_psv-adjustments-and-constraints.ch.sql ← lý do điều chỉnh + ràng buộc
```

---

## Quick start

### 1. Setup credential

```powershell
Copy-Item .env.example .env
# Mở .env, điền CLICKHOUSE_PASSWORD (xin trong vault team)
```

Hoặc bỏ qua bước này — runner tự fallback sang `projects/mondelez/.env` (cùng cluster).

### 2. Chạy thử health check

PowerShell (Windows):
```powershell
cd projects\panasonic\scripts\da-ch
.\run.ps1 -File .\core\C00_profile-psv.ch.sql
```

Bash (Git Bash / WSL / Linux):
```bash
cd projects/panasonic/scripts/da-ch
./run.sh core/C00_profile-psv.ch.sql
```

Output expected (snapshot 2026-05-19):
```
node                                            rows   distinct_keys  max_date_hcm         now_hcm
tms_panasonic_prod.dbo_OPS_Optimizer            7686   7686           2026-05-19 17:38:00  2026-05-19 19:50:16
analytics_workspace.psv_target (FINAL)          39133  7685           2026-05-19 17:38:00  ...
analytics_workspace.mv_psv_main                 34643  1704           2026-05-19 17:38:00  ...
```

### 3. Lưu output ra file

```powershell
.\run.ps1 -File .\core\C01_psv-summary-by-month.ch.sql -Format CSVWithNames -Out .\out\summary-by-month.csv
```

```bash
./run.sh core/C01_psv-summary-by-month.ch.sql --format CSVWithNames --out out/summary-by-month.csv
```

### 4. Chạy SQL ad-hoc

PowerShell:
```powershell
"SELECT vendor_name, count() FROM analytics_workspace.mv_psv_main GROUP BY vendor_name" | .\run.ps1 -Format PrettyCompactMonoBlock
```

Bash:
```bash
echo "SELECT vendor_name, count() FROM analytics_workspace.mv_psv_main GROUP BY vendor_name" | ./run.sh
```

---

## Pipeline trong 1 sơ đồ

```
Panasonic TMS (SQL Server)
   └─ dbo.OPS_Optimizer
        │ PeerDB CDC (realtime)
        ▼
   tms_panasonic_prod.dbo_OPS_Optimizer       (raw, JSON DataRun)
        │
        ├─► mv_psv_trigger  (incremental MV)
        │      │ ARRAY JOIN DataRun.DataReport + derive status_name_detail
        │      ▼
        │   psv_target  (canonical, ReplacingMergeTree)
        │      │
        │      └─► mv_psv_main  (refresh 1h)
        │            FINAL + filter + UTC→UTC+7
        │            ← dùng cho UI / dashboard
        │
        └─► mv_psv  (refresh 30min, parallel, legacy)
```

Chi tiết: [`02-data/data-sources/pipeline.md`](02-data/data-sources/pipeline.md).
DDL đầy đủ: [`02-data/data-sources/clickhouse-ddl/analytics-workspace_psv.md`](02-data/data-sources/clickhouse-ddl/analytics-workspace_psv.md).

---

## Catalog các query phân tích

| # | File | Trả lời câu hỏi | Source MV |
|---|------|-----------------|-----------|
| C00 | `C00_profile-psv.ch.sql` | Pipeline có healthy không? Data có fresh không? | All 5 nodes |
| C01 | `C01_psv-summary-by-month.ch.sql` | Mỗi tháng có bao nhiêu chuyến, % chuyến điều chỉnh, tổng ton/CBM/chi phí? | `mv_psv_main` |
| C02 | `C02_psv-by-vendor.ch.sql` | Nhà vận tải nào chiếm % chi phí lớn nhất? Vendor nào hay vi phạm ràng buộc? | `mv_psv_main` |
| C03 | `C03_psv-by-vehicle-type.ch.sql` | Loại xe nào đang dùng under-/over-utilized? (% capacity) | `mv_psv_main` |
| C04 | `C04_psv-top-routes.ch.sql` | Tuyến (from→to) nào nặng nhất? Chi phí/tấn của từng tuyến? | `mv_psv_main` |
| C05 | `C05_psv-adjustments-and-constraints.ch.sql` | User hay chỉnh chuyến vì lý do gì? Thuật toán hay vi phạm ràng buộc nào? | `mv_psv_main` |

Mọi query phân tích đều **default window = 6 tháng gần đây**. Chỉnh `INTERVAL 6 MONTH` trong file SQL nếu cần khoảng khác.

---

## Cảnh báo timezone (đọc trước khi tự viết SQL)

| Bảng / cột | Stored value | Cách query đúng |
|---|---|---|
| `tms_panasonic_prod.dbo_OPS_Optimizer.CreatedDate` | **Wall-clock HCM** (naïve, không tz) | Display trực tiếp, KHÔNG `toTimeZone` |
| `psv_target.created_date` | **Wall-clock HCM** (naïve) — kế thừa từ source | Display trực tiếp |
| `psv_target.master_etd` | Declare `Asia/Ho_Chi_Minh` tz nhưng VALUE thực vẫn là wall-clock HCM | Display trực tiếp, BỎ QUA tz metadata |
| `mv_psv_main.*` (mọi datetime) | Wall-clock HCM (đã +7h từ refresh logic) | Display trực tiếp |

**Quy tắc đơn giản**: với pipeline Panasonic này, mọi datetime hiển thị ra đều là wall-clock HCM. Không cộng/trừ thêm 7h khi format.

So sánh với `now()`:
- `now('Asia/Ho_Chi_Minh')` → returns HCM wall-clock — dùng cái này khi compare với cột PSV.

---

## Workflow phân tích đề xuất

1. **Sanity check trước**: `./run.sh core/C00_profile-psv.ch.sql` — confirm pipeline fresh.
2. **Trend dài hạn**: `C01` để xem volume trend theo tháng.
3. **Drill 1 chiều**:
   - Theo vendor → `C02`
   - Theo xe → `C03`
   - Theo tuyến → `C04`
   - Theo điều chỉnh/ràng buộc → `C05`
4. **Cross-check** với SQL ad-hoc khi cần (xem mục Quick start).
5. **Lưu audit** vào `02-data/audit-results/s2-<feature>-<YYYYMMDD>.md` theo template `/da-ch` mục 6.

---

## Liên kết
- Skill `/da-ch`: [`.claude/skills/da-ch/SKILL.md`](../../.claude/skills/da-ch/SKILL.md)
- Mondelez project (tham khảo): [`../mondelez/`](../mondelez/)
- Mondelez DDL snapshot (other MVs cùng cluster): [`../mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.md`](../mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.md)
