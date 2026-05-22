# ClickHouse DDL Snapshot — Panasonic PSV pipeline

> **Generated:** 2026-05-19 12:37 UTC
> **Cluster:** `ghrx9lirdl.ap-southeast-1.aws.clickhouse.cloud` (ClickHouse Cloud, ap-southeast-1)
> **Database:** `analytics_workspace`
> **Scope:** 4 objects (`psv_target`, `mv_psv`, `mv_psv_main`, `mv_psv_trigger`)
> **CDC source:** `tms_panasonic_prod.dbo_OPS_Optimizer` (replicated via PeerDB from Panasonic TMS SQL Server)

---

## Danh sách Objects

| # | Name | Engine | Rows | Size | Role |
|---|------|--------|------|------|------|
| 1 | `psv_target` | `SharedReplacingMergeTree` | 39,144 | 3.46 MiB | Canonical store — đích của trigger MV, dedupe theo `version` |
| 2 | `mv_psv_trigger` | `MaterializedView` (incremental, `TO psv_target`) | — | — | Trigger: parse JSON `DataRun.DataReport` từ CDC → ghi vào `psv_target` |
| 3 | `mv_psv_main` | `MaterializedView` (refreshable, `REFRESH EVERY 1 HOUR`) | 34,643 | 2.42 MiB | UI-facing: đọc `psv_target FINAL`, filter `is_deleted=0 AND data_report=true`, convert UTC → UTC+7 |
| 4 | `mv_psv` | `MaterializedView` (refreshable, `REFRESH EVERY 30 MINUTE`) | 39,134 | 3.54 MiB | Standalone refreshable MV đọc trực tiếp `tms_panasonic_prod.dbo_OPS_Optimizer` — pipeline song song với `mv_psv_trigger` |

**Metadata (queried 2026-05-19 12:37 UTC):**

| MV | Min created_date | Max created_date | Distinct ops_optimize_id | Distinct tracking_id |
|---|---|---|---|---|
| `psv_target` (FINAL) | 2024-09-15 23:04 | 2026-05-19 17:38 | 7,686 | 1,705 |
| `mv_psv_main` | 2025-09-04 10:08 | 2026-05-19 17:38 | — | 1,704 |
| `mv_psv` | 2024-09-15 23:04 | 2026-05-19 17:24 | 7,685 | 1,705 |

> **Note**: `mv_psv_main` chỉ chứa records có `data_report=true` (JSON `DataRun.DataReport` không rỗng) — nên min_date bắt đầu từ 2025-09 (records cũ hơn không có `DataReport` payload).

---

## Quan hệ giữa 4 objects

```
[Panasonic TMS SQL Server: dbo.OPS_Optimizer]
            │ (PeerDB CDC)
            ▼
   tms_panasonic_prod.dbo_OPS_Optimizer   ← raw CDC (7,686 source rows, 16.34 MiB)
            │
            ├──► mv_psv_trigger  (Incremental MV, TO target)
            │       │ — parse JSON DataRun.DataReport
            │       │ — ARRAY JOIN từng route trong report
            │       │ — derive `status_name_detail` (Chuyến điều chỉnh route / Chuyến tạo mới)
            │       ▼
            │    psv_target  (SharedReplacingMergeTree, dedupe by version)
            │       │
            │       └──► mv_psv_main  (Refreshable 1h)
            │             — SELECT FROM psv_target FINAL WHERE is_deleted=0 AND data_report=true
            │             — UTC → UTC+7 cho mọi DateTime
            │             — UI-facing, drop schema columns không cần
            │
            └──► mv_psv  (Refreshable 30min, standalone)
                  — đọc thẳng raw CDC, JSON parse như trigger
                  — KHÔNG ghi vào psv_target
                  — schema khác chút (tracking_id là String vs Int64)
```

### Chọn MV nào để query

| Use case | Dùng | Lý do |
|---|---|---|
| UI dashboard / widget Panasonic PSV | `mv_psv_main` | Đã filter sạch, datetime đã ở UTC+7, tên cột clean |
| Audit / debug pipeline | `psv_target FINAL` | Có đủ cột raw (note, group_ids, order_ids), bao gồm cả `is_deleted=1` |
| So sánh 2 pipeline (debug discrepancy) | `mv_psv` vs `psv_target` | `mv_psv` ↔ pipeline parallel; `psv_target` ↔ trigger-based |
| Trace 1 OPS_Optimizer cụ thể | `tms_panasonic_prod.dbo_OPS_Optimizer` | Raw CDC, có cả `DataRun` JSON gốc |

---

## DDL Chi tiết

### `psv_target`

> Canonical store cho Panasonic PSV (Phương án Sắp Vận tải — kết quả OPS_Optimizer). `SharedReplacingMergeTree` dedupe theo `version`. Mọi DateTime ở đây vẫn ở UTC (chưa convert sang VN).

**Engine:** `SharedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}', version)`
**ORDER BY:** `(ops_optimize_id, tracking_id, report_id)`
**Settings:** `allow_nullable_key = 1, index_granularity = 8192, async_insert = 1`

```sql
CREATE TABLE analytics_workspace.psv_target
(
    `ops_optimize_id` Int32,
    `version` UInt64,
    `sys_customer_id` Nullable(Int32),
    `optimizer_name` Nullable(String) COMMENT 'Tên kết quả OPS_Optimizer',
    `created_date` Nullable(DateTime64(6)) COMMENT 'Thời gian tạo kết quả',
    `created_by` LowCardinality(Nullable(String)) COMMENT 'Người tạo kết quả',
    `parent_modified_date` Nullable(DateTime64(6)),
    `parent_modified_by` LowCardinality(Nullable(String)),
    `date_from` Nullable(DateTime64(6)),
    `date_to` Nullable(DateTime64(6)),
    `is_save` Nullable(Bool),
    `is_container` Nullable(Bool),
    `is_balance_customer` Nullable(Bool),
    `is_balance_km_score` Nullable(Bool),
    `type_id` Nullable(Int32),
    `note` Nullable(String),
    `note_1` Nullable(String),
    `note_2` Nullable(String),
    `tracking_id` Nullable(Int64) COMMENT 'Mã kết quả DataRun (Tracking ID của chuyến)',
    `report_id` Nullable(Int64),
    `is_trip_edit_manual` Nullable(Bool) COMMENT 'Chuyến có chỉnh sửa',
    `reason_change` Nullable(String) COMMENT 'Lý do điều chỉnh',
    `status_name_detail_original` LowCardinality(Nullable(String)) COMMENT 'Loại điều chỉnh (raw từ JSON)',
    `status_name_detail` LowCardinality(Nullable(String)) COMMENT 'Loại điều chỉnh — derived: "Chuyến điều chỉnh route" khi IsTripEditManual=true và StatusNameDetail rỗng, ngược lại "Chuyến tạo mới"',
    `order_code` Nullable(String) COMMENT 'Mã đơn hàng',
    `total_order` Nullable(Int64) COMMENT 'Tổng số đơn',
    `total_delivery` Nullable(Int64) COMMENT 'Tổng điểm giao',
    `total_ton` Nullable(Float64) COMMENT 'Tổng số tấn',
    `total_cbm` Nullable(Float64) COMMENT 'Tổng số CBM',
    `total_cod_unit_price` Nullable(Float64) COMMENT 'Tổng giá trị hàng hóa',
    `group_of_vehicle_code` LowCardinality(Nullable(String)) COMMENT 'Mã loại xe',
    `group_of_vehicle_name` LowCardinality(Nullable(String)) COMMENT 'Tên loại xe',
    `group_of_vehicle_size` LowCardinality(Nullable(String)) COMMENT 'Khung xe',
    `vehicle_no` LowCardinality(Nullable(String)) COMMENT 'Số xe',
    `max_capacity` Nullable(Float64) COMMENT 'Thể tích xe (CBM)',
    `max_weight` Nullable(Float64) COMMENT 'Trọng tải xe (tấn)',
    `vendor_name` LowCardinality(Nullable(String)) COMMENT 'Nhà vận tải',
    `main_cost` Nullable(Float64) COMMENT 'Phí chính',
    `additional_cost` Nullable(Float64) COMMENT 'Phụ phí',
    `total_cost` Nullable(Float64) COMMENT 'Tổng chi phí dự kiến',
    `total_distance` Nullable(Float64),
    `master_etd` Nullable(DateTime64(6, 'Asia/Ho_Chi_Minh')) COMMENT 'ETD chuyến',
    `master_eta` Nullable(DateTime64(6, 'Asia/Ho_Chi_Minh')) COMMENT 'ETA chuyến',
    `date_come_stock` Nullable(DateTime64(6, 'Asia/Ho_Chi_Minh')) COMMENT 'Thời gian đến điểm nhận',
    `vehicle_end_time` Nullable(DateTime64(6, 'Asia/Ho_Chi_Minh')) COMMENT 'Thời gian xe về kho',
    `report_modified_date` Nullable(DateTime64(6, 'Asia/Ho_Chi_Minh')) COMMENT 'Thời gian điều chỉnh',
    `report_modified_by` LowCardinality(Nullable(String)) COMMENT 'Người điều chỉnh',
    `group_of_product_code` Nullable(String) COMMENT 'Mã nhóm hàng',
    `group_of_product_name` Nullable(String) COMMENT 'Tên nhóm hàng',
    `product_code` Nullable(String) COMMENT 'Mã hàng hóa',
    `product_name` Nullable(String) COMMENT 'Tên hàng hóa',
    `location_from_code` LowCardinality(Nullable(String)) COMMENT 'Mã điểm nhận',
    `location_from_name` LowCardinality(Nullable(String)),
    `location_to_code` Nullable(String) COMMENT 'Mã điểm giao',
    `location_to_name` Nullable(String),
    `group_ids` Nullable(String),
    `order_ids` Nullable(String),
    `constraint_name` Nullable(String) COMMENT 'Vi phạm ràng buộc',
    `constraint_note` Nullable(String) COMMENT 'Ghi chú ràng buộc',
    `data_report` Bool,
    `is_deleted` Nullable(UInt8)
)
ENGINE = SharedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}', version)
ORDER BY (ops_optimize_id, tracking_id, report_id)
SETTINGS allow_nullable_key = 1, index_granularity = 8192, async_insert = 1;
```

> **Performance note:**
> - Filter trên `ops_optimize_id` đầu tiên → CH skip granule tốt.
> - Nếu chỉ filter theo `created_date` → full scan (cột này không nằm trong `ORDER BY`).
> - Khi query cần latest version per key: `SELECT ... FROM psv_target FINAL` (tốn thời gian merge realtime, nên ưu tiên `mv_psv_main` cho dashboard).

---

### `mv_psv_trigger`

> Incremental MV: chạy trên mỗi `INSERT` vào `tms_panasonic_prod.dbo_OPS_Optimizer`. Parse JSON `DataRun.DataReport`, ARRAY JOIN từng route trong report, derive nghiệp vụ rồi ghi vào `psv_target`.
> **Quan trọng**: `tracking_id` ở đây là `Int64` (từ `JSONExtractInt`), trong khi ở `mv_psv` lại là `String` — cẩn thận khi JOIN giữa các MV.

**Engine:** `MaterializedView TO analytics_workspace.psv_target`

```sql
CREATE MATERIALIZED VIEW analytics_workspace.mv_psv_trigger TO analytics_workspace.psv_target
AS SELECT
    ID AS ops_optimize_id,
    _peerdb_version AS version,
    coalesce(SYSCustomerID, -1) AS sys_customer_id,
    coalesce(OptimizerName, '') AS optimizer_name,
    coalesce(CreatedDate, toDateTime64('1970-01-01 00:00:00', 6)) AS created_date,
    CAST(coalesce(CreatedBy, ''), 'LowCardinality(String)') AS created_by,
    coalesce(ModifiedDate, toDateTime64('1970-01-01 00:00:00', 6)) AS parent_modified_date,
    CAST(coalesce(ModifiedBy, ''), 'LowCardinality(String)') AS parent_modified_by,
    coalesce(DateFrom, toDateTime64('1970-01-01 00:00:00', 6)) AS date_from,
    coalesce(DateTo, toDateTime64('1970-01-01 00:00:00', 6)) AS date_to,
    coalesce(IsSave, false) AS is_save,
    coalesce(IsContainer, false) AS is_container,
    coalesce(IsBalanceCustomer, false) AS is_balance_customer,
    coalesce(IsBalanceKMScore, false) AS is_balance_km_score,
    coalesce(TypeID, -1) AS type_id,
    coalesce(Note, '') AS note,
    coalesce(Note1, '') AS note_1,
    coalesce(Note2, '') AS note_2,
    coalesce(JSONExtractInt(v, 'TrackingID'), -1) AS tracking_id,
    coalesce(JSONExtractInt(v, 'ID'), -1) AS report_id,
    toBool(coalesce(JSONExtractBool(v, 'IsTripEditManual'), false)) AS is_trip_edit_manual,
    coalesce(JSONExtractString(v, 'ReasonChange'), '') AS reason_change,
    CAST(multiIf(
        NOT JSONHas(v, 'StatusNameDetail'), 'Không có cột',
        isNull(JSONExtractString(v, 'StatusNameDetail')) OR (JSONExtractString(v, 'StatusNameDetail') = ''), ' ',
        JSONExtractString(v, 'StatusNameDetail')
    ), 'LowCardinality(String)') AS status_name_detail_original,
    CAST(multiIf(
        (is_trip_edit_manual = true)
            AND (isNull(JSONExtractString(v, 'StatusNameDetail')) OR (JSONExtractString(v, 'StatusNameDetail') = '')),
        'Chuyến điều chỉnh route',
        'Chuyến tạo mới'
    ), 'LowCardinality(String)') AS status_name_detail,
    coalesce(JSONExtractString(v, 'OrderCode'), '') AS order_code,
    coalesce(JSONExtractInt(v, 'TotalOrder'), 0) AS total_order,
    coalesce(JSONExtractInt(v, 'TotalDelivery'), 0) AS total_delivery,
    coalesce(JSONExtractFloat(v, 'TotalTon'), 0) AS total_ton,
    coalesce(JSONExtractFloat(v, 'TotalCBM'), 0) AS total_cbm,
    coalesce(JSONExtractFloat(v, 'TotalCODUnitPrice'), 0) AS total_cod_unit_price,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleCode'), ''), 'LowCardinality(String)') AS group_of_vehicle_code,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleName'), ''), 'LowCardinality(String)') AS group_of_vehicle_name,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleSize'), ''), 'LowCardinality(String)') AS group_of_vehicle_size,
    CAST(coalesce(JSONExtractString(v, 'VehicleNo'), ''), 'LowCardinality(String)') AS vehicle_no,
    coalesce(JSONExtractFloat(v, 'MaxCapacity'), 0) AS max_capacity,
    coalesce(JSONExtractFloat(v, 'MaxWeight'), 0) AS max_weight,
    CAST(coalesce(JSONExtractString(v, 'VendorName'), ''), 'LowCardinality(String)') AS vendor_name,
    coalesce(JSONExtractFloat(v, 'MainCost'), 0) AS main_cost,
    coalesce(JSONExtractFloat(v, 'AdditionalCost'), 0) AS additional_cost,
    coalesce(JSONExtractFloat(v, 'TotalCost'), 0) AS total_cost,
    coalesce(JSONExtractFloat(v, 'TotalDistance'), 0) AS total_distance,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'MasterETD')), toDateTime('1970-01-01 00:00:00')) AS master_etd,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'MasterETA')), toDateTime('1970-01-01 00:00:00')) AS master_eta,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'DateComeStock')), toDateTime('1970-01-01 00:00:00')) AS date_come_stock,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'VehicleEndTime')), toDateTime('1970-01-01 00:00:00')) AS vehicle_end_time,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'ModifiedDate')), toDateTime('1970-01-01 00:00:00')) AS report_modified_date,
    CAST(coalesce(JSONExtractString(v, 'ModifiedBy'), ''), 'LowCardinality(String)') AS report_modified_by,
    coalesce(JSONExtractString(v, 'GroupOfProductCode'), '') AS group_of_product_code,
    coalesce(JSONExtractString(v, 'GroupOfProductName'), '') AS group_of_product_name,
    coalesce(JSONExtractString(v, 'ProductCode'), '') AS product_code,
    coalesce(JSONExtractString(v, 'ProductName'), '') AS product_name,
    CAST(coalesce(JSONExtractString(v, 'LocationFromCode'), ''), 'LowCardinality(String)') AS location_from_code,
    CAST(coalesce(JSONExtractString(v, 'LocationFromName'), ''), 'LowCardinality(String)') AS location_from_name,
    coalesce(JSONExtractString(v, 'LocationToCode'), '') AS location_to_code,
    coalesce(JSONExtractString(v, 'LocationToName'), '') AS location_to_name,
    coalesce(JSONExtractRaw(v, 'GroupIds'), '[]') AS group_ids,
    coalesce(JSONExtractRaw(v, 'OrderIds'), '[]') AS order_ids,
    coalesce(JSONExtractString(v, 'ConstraintName'), '') AS constraint_name,
    coalesce(JSONExtractString(v, 'ConstraintNote'), '') AS constraint_note,
    if(empty(JSONExtractString(DataRun, 'DataReport')) OR (JSONExtractString(DataRun, 'DataReport') = '[]'), false, true) AS data_report,
    coalesce(_peerdb_is_deleted, 0) AS is_deleted
FROM tms_panasonic_prod.dbo_OPS_Optimizer
LEFT ARRAY JOIN JSONExtractArrayRaw(coalesce(JSONExtractString(DataRun, 'DataReport'), '[]')) AS v;
```

> **Business rule quan trọng (status_name_detail):**
> - `Chuyến điều chỉnh route` ⇔ `IsTripEditManual = true` AND `StatusNameDetail` (trong JSON) là NULL/empty
> - `Chuyến tạo mới` ⇔ tất cả trường hợp còn lại
>
> Trường raw `status_name_detail_original` được giữ riêng để debug — nếu = `' '` (1 space) nghĩa là JSON có key nhưng giá trị empty; nếu = `'Không có cột'` nghĩa là JSON không có key.

---

### `mv_psv_main`

> UI-facing refreshable MV. Lấy snapshot từ `psv_target FINAL` mỗi 1 giờ. Convert mọi `DateTime` từ UTC sang UTC+7 bằng `+ toIntervalHour(7)`. Filter sạch: chỉ giữ records active (`is_deleted=0`) có dữ liệu report (`data_report=true`).

**Engine:** `SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')`
**ORDER BY:** `(tracking_id, order_code)`
**Refresh:** `EVERY 1 HOUR`
**Settings:** `allow_nullable_key = 1, index_granularity = 8192`

```sql
CREATE MATERIALIZED VIEW analytics_workspace.mv_psv_main
REFRESH EVERY 1 HOUR
(
    `tracking_id` String,
    `optimizer_name` String,
    `created_by` LowCardinality(String),
    `created_date` DateTime64(6),
    `is_trip_edit_manual` Bool,
    `status_name_detail` String,
    `order_code` String,
    `total_order` Int64,
    `total_delivery` Int64,
    `total_ton` Float64,
    `total_cbm` Float64,
    `total_cod_unit_price` Float64,
    `group_of_vehicle_code` LowCardinality(String),
    `group_of_vehicle_name` LowCardinality(String),
    `group_of_vehicle_size` LowCardinality(String),
    `vehicle_no` LowCardinality(String),
    `max_capacity` Float64,
    `max_weight` Float64,
    `vendor_name` LowCardinality(String),
    `main_cost` Float64,
    `additional_cost` Float64,
    `total_cost` Float64,
    `report_modified_by` LowCardinality(String),
    `report_modified_date` Nullable(DateTime),
    `reason_change` String,
    `constraint_name` String,
    `constraint_note` String,
    `group_of_product_code` String,
    `group_of_product_name` String,
    `product_code` String,
    `product_name` String,
    `location_from_code` LowCardinality(String),
    `location_to_code` String,
    `master_etd` Nullable(DateTime),
    `master_eta` Nullable(DateTime),
    `date_come_stock` Nullable(DateTime),
    `vehicle_end_time` Nullable(DateTime),
    `is_deleted` Nullable(Int8),
    `data_report` Bool
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (tracking_id, order_code)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
AS SELECT
    tracking_id,
    optimizer_name,
    created_by,
    created_date,
    is_trip_edit_manual,
    status_name_detail,
    order_code,
    total_order,
    total_delivery,
    total_ton,
    total_cbm,
    total_cod_unit_price,
    group_of_vehicle_code,
    group_of_vehicle_name,
    group_of_vehicle_size,
    vehicle_no,
    max_capacity,
    max_weight,
    vendor_name,
    main_cost,
    additional_cost,
    total_cost,
    report_modified_by,
    nullIf(report_modified_date + toIntervalHour(7), toDateTime('1970-01-01 07:00:00')) AS report_modified_date,
    reason_change,
    constraint_name,
    constraint_note,
    group_of_product_code,
    group_of_product_name,
    product_code,
    product_name,
    location_from_code,
    location_to_code,
    nullIf(master_etd + toIntervalHour(7), toDateTime('1970-01-01 07:00:00')) AS master_etd,
    nullIf(master_eta + toIntervalHour(7), toDateTime('1970-01-01 07:00:00')) AS master_eta,
    nullIf(date_come_stock + toIntervalHour(7), toDateTime('1970-01-01 07:00:00')) AS date_come_stock,
    nullIf(vehicle_end_time + toIntervalHour(7), toDateTime('1970-01-01 07:00:00')) AS vehicle_end_time,
    is_deleted,
    data_report
FROM analytics_workspace.psv_target
FINAL
WHERE (is_deleted = 0) AND (data_report = true);
```

> **Caveats khi dùng `mv_psv_main`:**
> 1. **Refresh trễ tối đa 1h** — dữ liệu mới insert vào `psv_target` sẽ chưa có ở `mv_psv_main` cho đến cycle refresh tiếp theo.
> 2. **Datetime đã UTC+7** — KHÔNG cộng thêm `toIntervalHour(7)` lần nữa khi viết SQL audit.
> 3. **`tracking_id` là `String`** ở MV này (vẫn từ Int64 dưới `psv_target` nhưng implicit cast trong refresh query). Khi JOIN với MV khác phải cast cùng kiểu.
> 4. **Sentinel `1970-01-01 07:00:00`** = UTC `1970-01-01 00:00:00` đã +7 → đã `nullIf` về NULL. Không cần check sentinel khác.

---

### `mv_psv`

> Pipeline song song với `mv_psv_trigger`: cũng đọc từ `tms_panasonic_prod.dbo_OPS_Optimizer` nhưng là **refreshable MV** (chạy mỗi 30 phút), KHÔNG ghi vào `psv_target`. Schema gần giống `psv_target` nhưng:
> - `tracking_id` là `String` (vs `Int64` ở trigger)
> - Giữ cột `note`, `group_ids`, `order_ids`, `total_distance`, `location_from_name`, `location_to_name` (giống `psv_target`, bị bỏ ở `mv_psv_main`)
> - KHÔNG có `reason_change`, `status_name_detail`, `status_name_detail_original`, `report_modified_by` (3 cột business derive thêm ở `mv_psv_trigger`)

**Engine:** `SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')`
**ORDER BY:** `(ops_optimize_id, tracking_id, report_id, version)`
**Refresh:** `EVERY 30 MINUTE`

```sql
CREATE MATERIALIZED VIEW analytics_workspace.mv_psv
REFRESH EVERY 30 MINUTE
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (ops_optimize_id, tracking_id, report_id, version)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
AS SELECT
    ID AS ops_optimize_id,
    _peerdb_version AS version,
    coalesce(SYSCustomerID, -1) AS sys_customer_id,
    coalesce(OptimizerName, '') AS optimizer_name,
    coalesce(CreatedDate, toDateTime64('1970-01-01 00:00:00', 6)) AS created_date,
    CAST(coalesce(CreatedBy, ''), 'LowCardinality(String)') AS created_by,
    coalesce(ModifiedDate, toDateTime64('1970-01-01 00:00:00', 6)) AS parent_modified_date,
    CAST(coalesce(ModifiedBy, ''), 'LowCardinality(String)') AS parent_modified_by,
    coalesce(DateFrom, toDateTime64('1970-01-01 00:00:00', 6)) AS date_from,
    coalesce(DateTo, toDateTime64('1970-01-01 00:00:00', 6)) AS date_to,
    coalesce(IsSave, false) AS is_save,
    coalesce(IsContainer, false) AS is_container,
    coalesce(IsBalanceCustomer, false) AS is_balance_customer,
    coalesce(IsBalanceKMScore, false) AS is_balance_km_score,
    coalesce(TypeID, -1) AS type_id,
    coalesce(Note, '') AS note,
    coalesce(Note1, '') AS note_1,
    coalesce(Note2, '') AS note_2,
    coalesce(JSONExtractString(v, 'TrackingID'), '') AS tracking_id,
    coalesce(JSONExtractInt(v, 'ID'), -1) AS report_id,
    toBool(coalesce(JSONExtractBool(v, 'IsTripEditManual'), false)) AS is_trip_edit_manual,
    coalesce(JSONExtractString(v, 'OrderCode'), '') AS order_code,
    coalesce(JSONExtractInt(v, 'TotalOrder'), 0) AS total_order,
    coalesce(JSONExtractInt(v, 'TotalDelivery'), 0) AS total_delivery,
    coalesce(JSONExtractFloat(v, 'TotalTon'), 0) AS total_ton,
    coalesce(JSONExtractFloat(v, 'TotalCBM'), 0) AS total_cbm,
    coalesce(JSONExtractFloat(v, 'TotalCODUnitPrice'), 0) AS total_cod_unit_price,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleCode'), ''), 'LowCardinality(String)') AS group_of_vehicle_code,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleName'), ''), 'LowCardinality(String)') AS group_of_vehicle_name,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleSize'), ''), 'LowCardinality(String)') AS group_of_vehicle_size,
    CAST(coalesce(JSONExtractString(v, 'VehicleNo'), ''), 'LowCardinality(String)') AS vehicle_no,
    coalesce(JSONExtractFloat(v, 'MaxCapacity'), 0) AS max_capacity,
    coalesce(JSONExtractFloat(v, 'MaxWeight'), 0) AS max_weight,
    CAST(coalesce(JSONExtractString(v, 'VendorName'), ''), 'LowCardinality(String)') AS vendor_name,
    coalesce(JSONExtractFloat(v, 'MainCost'), 0) AS main_cost,
    coalesce(JSONExtractFloat(v, 'AdditionalCost'), 0) AS additional_cost,
    coalesce(JSONExtractFloat(v, 'TotalCost'), 0) AS total_cost,
    coalesce(JSONExtractFloat(v, 'TotalDistance'), 0) AS total_distance,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'MasterETD')), toDateTime('1970-01-01 00:00:00')) AS master_etd,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'MasterETA')), toDateTime('1970-01-01 00:00:00')) AS master_eta,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'DateComeStock')), toDateTime('1970-01-01 00:00:00')) AS date_come_stock,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'VehicleEndTime')), toDateTime('1970-01-01 00:00:00')) AS vehicle_end_time,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'ModifiedDate')), toDateTime('1970-01-01 00:00:00')) AS report_modified_date,
    coalesce(JSONExtractString(v, 'GroupOfProductCode'), '') AS group_product_code,
    coalesce(JSONExtractString(v, 'GroupOfProductName'), '') AS group_product_name,
    coalesce(JSONExtractString(v, 'ProductCode'), '') AS product_code,
    coalesce(JSONExtractString(v, 'ProductName'), '') AS product_name,
    CAST(coalesce(JSONExtractString(v, 'LocationFromCode'), ''), 'LowCardinality(String)') AS location_from_code,
    CAST(coalesce(JSONExtractString(v, 'LocationFromName'), ''), 'LowCardinality(String)') AS location_from_name,
    coalesce(JSONExtractString(v, 'LocationToCode'), '') AS location_to_code,
    coalesce(JSONExtractString(v, 'LocationToName'), '') AS location_to_name,
    coalesce(JSONExtractRaw(v, 'GroupIds'), '[]') AS group_ids,
    coalesce(JSONExtractRaw(v, 'OrderIds'), '[]') AS order_ids,
    coalesce(JSONExtractString(v, 'ConstraintName'), '') AS constraint_name,
    coalesce(JSONExtractString(v, 'ConstraintNote'), '') AS constraint_note,
    if(empty(JSONExtractString(DataRun, 'DataReport')) OR (JSONExtractString(DataRun, 'DataReport') = '[]'), false, true) AS data_report,
    coalesce(_peerdb_is_deleted, 0) AS is_deleted
FROM tms_panasonic_prod.dbo_OPS_Optimizer
LEFT ARRAY JOIN JSONExtractArrayRaw(coalesce(JSONExtractString(DataRun, 'DataReport'), '[]')) AS v;
```

> **Khi nào dùng `mv_psv` thay vì `mv_psv_main`:**
> - Cần các cột `note`, `group_ids`, `order_ids`, `total_distance` mà `mv_psv_main` không có.
> - Chấp nhận datetime ở UTC (chưa +7).
> - Cần dữ liệu fresh hơn (30min vs 1h).
>
> **Cảnh báo:** `mv_psv` và `psv_target` cùng đọc 1 nguồn nhưng có thể lệch nhau ~10 rows do timing/dedup khác nhau. Không reconcile được realtime — chấp nhận drift 1-2%.

---

## Hành động khuyến nghị (Recommendations)

1. **Sử dụng cho widget/dashboard**: `mv_psv_main` (đã clean, UTC+7, refresh 1h).
2. **Sử dụng cho audit/debug**: `psv_target FINAL` (canonical, có đủ cột raw).
3. **TRÁNH** dùng `mv_psv` cho dashboard mới — đây là pipeline cũ, sẽ deprecate khi `mv_psv_main` ổn định.
4. **Đề xuất pipeline team**: hợp nhất `mv_psv` + `mv_psv_trigger` về 1 nguồn duy nhất để tránh drift; hoặc remove `mv_psv` nếu không còn use case.

---

## ARTIFACT_PATH

`projects/panasonic/02-data/data-sources/clickhouse-ddl/analytics-workspace_psv.md`
