# Panasonic PSV — Data Pipeline

> Tài liệu mô tả luồng dữ liệu từ Panasonic TMS (SQL Server) → ClickHouse → UI/Report.
> Last verified: 2026-05-19 (helix user, CH 25.12.1.1497).

---

## Tổng quan

PSV (Phương án Sắp Vận tải) là kết quả của module **OPS Optimizer** trên TMS Panasonic. Mỗi lần chạy thuật toán tối ưu sinh ra 1 record `OPS_Optimizer` chứa JSON `DataRun.DataReport` — mảng các "chuyến" (trips) được đề xuất.

Luồng dữ liệu:

```
┌─────────────────────────────┐
│ Panasonic TMS (SQL Server)  │
│   dbo.OPS_Optimizer         │
└──────────┬──────────────────┘
           │ PeerDB CDC (realtime)
           ▼
┌─────────────────────────────────────────┐
│ ClickHouse: tms_panasonic_prod          │
│   dbo_OPS_Optimizer                     │
│   (SharedReplacingMergeTree, ~7,686 rows)│
└──────────┬─────────────────────┬────────┘
           │                     │
           │ mv_psv_trigger      │ mv_psv
           │ (incremental MV)    │ (refreshable, 30min)
           │                     │
           ▼                     ▼
   ┌──────────────────┐   ┌──────────────────┐
   │ psv_target       │   │ mv_psv           │
   │ (canonical)      │   │ (parallel, đọc thẳng raw)
   │ ReplacingMergeTree│  │ ~39,134 rows     │
   │ ~39,144 rows     │   └──────────────────┘
   └──────┬───────────┘
          │ FINAL + filter(is_deleted=0, data_report=true)
          │ + UTC → UTC+7
          ▼
   ┌──────────────────┐
   │ mv_psv_main      │
   │ (refreshable 1h) │
   │ ~34,643 rows     │
   │ UI-facing        │
   └──────┬───────────┘
          │
          ▼
   [Smartlog Control Tower widgets]
```

---

## Chi tiết mỗi node

### 1. Source — Panasonic TMS SQL Server
- **Table**: `dbo.OPS_Optimizer`
- **Loại**: SQL Server (OLTP)
- **Có gì**: 1 row = 1 lần chạy OPS Optimizer (bài toán tối ưu). Có cột `DataRun` (NVARCHAR(MAX)) chứa JSON mô tả kết quả tối ưu, bao gồm mảng `DataReport`.

### 2. CDC Mirror — `tms_panasonic_prod.dbo_OPS_Optimizer`
- **Engine**: `SharedReplacingMergeTree` (dedupe theo `_peerdb_version`)
- **Rows**: 7,686 (snapshot 2026-05-19)
- **Size**: 16.34 MiB
- **Replication**: PeerDB CDC — mỗi INSERT/UPDATE/DELETE ở SQL Server được mirror sang đây (~vài giây delay).
- **Cột đặc biệt**: `_peerdb_version` (UInt64), `_peerdb_is_deleted` (UInt8), `DataRun` (JSON String).
- **Không được INSERT trực tiếp** vào đây — read-only CDC schema.

### 3. Incremental MV — `mv_psv_trigger`
- **Engine**: `MaterializedView TO analytics_workspace.psv_target`
- **Trigger**: mỗi INSERT vào `tms_panasonic_prod.dbo_OPS_Optimizer` → MV chạy `SELECT` của nó trên delta → INSERT kết quả vào `psv_target`.
- **Logic**:
  1. ARRAY JOIN `JSONExtractArrayRaw(DataRun.DataReport)` để mỗi chuyến (`v`) thành 1 row.
  2. JSONExtract từng field (TrackingID, ID, OrderCode, ETD, ETA, ...).
  3. Derive `status_name_detail` theo rule nghiệp vụ (xem [glossary.md](../glossary.md)).
  4. Coalesce NULL về sentinel (`-1`, `''`, `1970-01-01 00:00:00`) — KHÔNG truyền NULL.
- **Tần suất**: realtime (theo INSERT của CDC).
- **Lưu ý**: không có dữ liệu lịch sử backfill — chỉ chứa data từ thời điểm MV được tạo trở đi.

### 4. Canonical Store — `psv_target`
- **Engine**: `SharedReplacingMergeTree(version)` — dedupe theo `version` (= `_peerdb_version`).
- **ORDER BY**: `(ops_optimize_id, tracking_id, report_id)`
- **Rows**: 39,144 (snapshot)
- **Size**: 3.46 MiB
- **Time range**: 2024-09-15 → 2026-05-19 (~20 tháng)
- **Distinct ops_optimize_id**: 7,686 (bằng row count của source — mỗi OPS_Optimizer sinh trung bình ~5.1 chuyến)
- **Distinct tracking_id**: 1,705
- **Filter** khi query: `is_deleted = 0` (soft-deleted vẫn ở đây), `data_report = true` (loại records có JSON DataReport rỗng).
- **Timezone**: cột DateTime declare là `Asia/Ho_Chi_Minh` nhưng VALUE thực vẫn ở UTC. Phải `+ INTERVAL 7 HOUR` khi hiển thị.

### 5. UI MV — `mv_psv_main`
- **Engine**: `MaterializedView REFRESH EVERY 1 HOUR`
- **Backing storage**: `SharedMergeTree` (internal, không truy cập trực tiếp)
- **Rows**: 34,643 (snapshot) — chênh ~4,500 vs `psv_target` vì filter `data_report=true` loại bỏ records có DataReport rỗng (chủ yếu data 2024-09 → 2025-08).
- **Time range**: 2025-09-04 → 2026-05-19
- **Logic**:
  1. `FROM psv_target FINAL` — dedupe canonical
  2. Filter `is_deleted = 0 AND data_report = true`
  3. `+ toIntervalHour(7)` cho mọi DateTime (UTC → UTC+7)
  4. `nullIf(x, '1970-01-01 07:00:00')` — convert sentinel epoch về NULL
- **Refresh**: mỗi 1h. Có thể trễ tối đa 1h so với raw.
- **UI-facing**: đây là MV nên consume ở widget/dashboard.

### 6. Parallel MV — `mv_psv` (legacy)
- **Engine**: `MaterializedView REFRESH EVERY 30 MINUTE`
- **Backing storage**: `SharedMergeTree`, ORDER BY `(ops_optimize_id, tracking_id, report_id, version)`
- **Rows**: 39,134 (snapshot) — gần bằng `psv_target` nhưng lệch ~10 rows.
- **Khác `psv_target`**:
  - `tracking_id` là `String` (JSONExtractString) thay vì Int64
  - KHÔNG có `reason_change`, `status_name_detail`, `status_name_detail_original`, `report_modified_by`
  - GIỮ `note`, `group_ids`, `order_ids`, `total_distance` (giống `psv_target`)
- **Tình trạng**: pipeline song song, có vẻ là phiên bản cũ trước khi `mv_psv_trigger` được tạo. KHUYẾN NGHỊ deprecate, dùng `psv_target FINAL` thay.

---

## Lineage chi tiết

| Cột business | Đường đi |
|---|---|
| `tracking_id` (chuyến) | SQL Server `OPS_Optimizer.DataRun` JSON → `DataReport[i].TrackingID` → `mv_psv_trigger.tracking_id` (Int64) → `psv_target.tracking_id` → `mv_psv_main.tracking_id` (cast String) |
| `status_name_detail` (loại chuyến) | Derived từ `IsTripEditManual` + `StatusNameDetail` trong JSON, qua rule `multiIf(...)` ở `mv_psv_trigger` → `psv_target.status_name_detail` → `mv_psv_main.status_name_detail` |
| `master_etd` (ETD) | `DataReport[i].MasterETD` (text) → `parseDateTimeBestEffortOrNull(...)` → `psv_target.master_etd` (UTC) → `mv_psv_main.master_etd` (UTC+7) |
| `total_cost` | `DataReport[i].TotalCost` (number) → `JSONExtractFloat(...)` → `psv_target.total_cost` → `mv_psv_main.total_cost` (không đổi) |
| `vendor_name` | `DataReport[i].VendorName` → cast `LowCardinality(String)` → `psv_target.vendor_name` → `mv_psv_main.vendor_name` |

---

## Sự cố thường gặp

| Triệu chứng | Root cause | Xử lý |
|---|---|---|
| Số chuyến tăng/giảm bất thường giữa 2 lần query trong vòng 1h | `mv_psv_main` refresh chu kỳ → snapshot có thể stale | Query `psv_target FINAL` (realtime) để cross-check |
| `psv_target` vs `mv_psv` lệch ~10 rows | 2 pipeline song song có thời điểm sample khác nhau | Trust `psv_target` (canonical), debug `mv_psv` riêng nếu cần |
| `created_date` ở `mv_psv_main` bắt đầu từ 2025-09 (mất data 2024) | Records cũ có JSON `DataReport` rỗng → `data_report=false` → bị filter | Query `psv_target` (không filter) nếu cần lịch sử đầy đủ |
| ETA/ETD lệch 7 giờ giữa 2 widget | 1 widget dùng `psv_target` (UTC), 1 widget dùng `mv_psv_main` (UTC+7) | Quy ước: dashboard luôn dùng `mv_psv_main`. Audit thì +7 thủ công khi query `psv_target`. |
| Cùng 1 chuyến có nhiều report_id | Mỗi lần edit chuyến → record mới vào JSON `DataReport` | `GROUP BY tracking_id` + `argMax(*, report_modified_date)` để lấy bản latest |

---

## Refresh status (queried 2026-05-19 12:37 UTC)

- `helix` user không có quyền đọc đầy đủ `system.view_refreshes` → không track được `last_refresh_time`/`exception`.
- Cách workaround: query `max(created_date)` của MV và so với `now()` để đo độ trễ thực.
- Script kiểm tra: [`scripts/da-ch/core/C00_profile-psv.ch.sql`](../../scripts/da-ch/core/C00_profile-psv.ch.sql)

---

## Description / COMMENT metadata (post M01 migration — 2026-05-19)

Sau khi chạy [`migrations/M01_add_descriptions.ch.sql`](../../scripts/da-ch/migrations/M01_add_descriptions.ch.sql):

| Object | Table-level COMMENT | Column-level COMMENT | Ghi chú |
|---|---|---|---|
| `psv_target` | ✓ | 61/61 (100%) | Canonical, dùng làm nguồn comment chính |
| `mv_psv_trigger` | ✓ | 61/61 (100%) | Incremental MV, ALTER COMMENT bình thường |
| `mv_psv_main` | ✓ | 0/39 (0%) | **Refreshable MV — CH 25.x limitation**: ALTER COMMENT COLUMN no-op, MODIFY COLUMN unsupported. Cross-reference comments của `psv_target` (cùng tên cột). |
| `mv_psv` | ✓ | 0/57 (0%) | Same limitation. Tham khảo `psv_target` cho column meaning. |

**Limitation chi tiết** (ClickHouse 25.12.1):
- `ALTER TABLE <refreshable_mv> COMMENT COLUMN col 'x'` trả về 200 OK nhưng comment KHÔNG persist trong `system.columns` (schema được control bởi SELECT clause của MV).
- `ALTER TABLE <refreshable_mv> MODIFY COLUMN col Type COMMENT 'x'` trả về `Code 48: NOT_IMPLEMENTED — Alter of type 'MODIFY_COLUMN' is not supported by storage MaterializedView`.
- Cách duy nhất để có column-level COMMENT trên refreshable MV = **DROP + CREATE** với inline `<col> Type COMMENT '...'` trong column definition. Đây là invasive change, cần auth riêng → để dành cho M02 nếu cần.
