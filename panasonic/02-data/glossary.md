# Panasonic PSV — Glossary

Bảng từ vựng cho dự án **Panasonic PSV** (Phương án Sắp Vận tải). Tra cứu nhanh khi đọc SQL, MV, hoặc report.

---

## Term ↔ Kỹ thuật

| Tên nghiệp vụ (VN) | Cột / Object kỹ thuật | Ghi chú |
|---|---|---|
| PSV — Phương án Sắp Vận tải | (project name) | Module trên TMS Panasonic, sinh từ OPS Optimizer |
| Kết quả OPS_Optimizer | `psv_target.ops_optimize_id` (Int32) | 1 lần chạy thuật toán tối ưu = 1 ops_optimize_id |
| Tên kết quả | `optimizer_name` | Tên do user đặt khi save phương án |
| Người tạo / Thời gian tạo | `created_by` / `created_date` | Thông tin OPS_Optimizer cha |
| Thời gian điều chỉnh cha | `parent_modified_date` / `parent_modified_by` | Modify ở level OPS_Optimizer (không phải route) |
| Thời gian điều chỉnh route | `report_modified_date` / `report_modified_by` | Modify ở level route con (trong JSON DataReport) |
| Khoảng kế hoạch | `date_from` / `date_to` | Window thời gian chạy tối ưu |
| Lưu kết quả | `is_save` (Bool) | True = user đã save (commit), false = draft |
| Cho phép ghép container | `is_container` (Bool) | Setting tối ưu |
| Cân bằng customer | `is_balance_customer` (Bool) | Setting tối ưu |
| Cân bằng KM/score | `is_balance_km_score` (Bool) | Setting tối ưu |
| Loại OPS Optimizer | `type_id` (Int32) | Phân loại loại bài toán (ý nghĩa cụ thể hỏi PM) |
| Ghi chú | `note`, `note_1`, `note_2` | Free-text user nhập |
| Chuyến | `tracking_id` | 1 chuyến = 1 tracking_id (route do thuật toán/user tạo). 1 ops_optimize_id sinh ra nhiều chuyến. |
| Báo cáo điều chỉnh | `report_id` | 1 report = 1 lần điều chỉnh trên 1 chuyến. Tùy data, có thể nhiều report/chuyến. |
| Chuyến có chỉnh sửa | `is_trip_edit_manual` (Bool) | User chạm tay vào chuyến (kéo thả, đổi xe, ...) |
| **Loại điều chỉnh (derived)** | `status_name_detail` | 2 giá trị: `Chuyến điều chỉnh route` / `Chuyến tạo mới` |
| Loại điều chỉnh (raw) | `status_name_detail_original` | Raw từ JSON; debug-only |
| Lý do điều chỉnh | `reason_change` | User nhập khi adjust |
| Mã đơn hàng (concatenated) | `order_code` | Chuỗi mã đơn — có thể là CSV hoặc 1 đơn |
| IDs đơn hàng | `order_ids` (JSON array) | `[123,456]` — mảng số nguyên |
| IDs group đơn | `group_ids` (JSON array) | Mảng group ID, dùng khi group orders trước khi assign chuyến |
| Tổng số đơn | `total_order` (Int64) | Số đơn trong chuyến |
| Tổng điểm giao | `total_delivery` (Int64) | Số điểm giao (location) trong chuyến |
| Tổng khối lượng | `total_ton` (Float64) | Đơn vị: tấn |
| Tổng thể tích | `total_cbm` (Float64) | Đơn vị: m³ |
| Tổng giá trị hàng | `total_cod_unit_price` (Float64) | COD = Cash on Delivery (hoặc giá trị hàng) |
| Loại xe (code) | `group_of_vehicle_code` | Vd: "T15" |
| Loại xe (tên) | `group_of_vehicle_name` | Vd: "Xe tải 15 tấn" |
| Khung xe | `group_of_vehicle_size` | Phân loại theo size (S/M/L/XL hoặc text) |
| Số xe | `vehicle_no` | Biển số cụ thể |
| Thể tích xe | `max_capacity` (Float64) | m³ — capacity của loại xe |
| Trọng tải xe | `max_weight` (Float64) | tấn — capacity của loại xe |
| Nhà vận tải | `vendor_name` | Tên vendor (cty vận tải) |
| Phí chính | `main_cost` (Float64) | VND — chi phí chính của chuyến |
| Phụ phí | `additional_cost` (Float64) | VND — phụ phí (xe nâng, lao công, ...) |
| Tổng chi phí dự kiến | `total_cost` (Float64) | `main_cost + additional_cost` |
| Tổng quãng đường | `total_distance` (Float64) | km |
| ETD chuyến | `master_etd` | Estimated Time of Departure |
| ETA chuyến | `master_eta` | Estimated Time of Arrival |
| Thời gian đến điểm nhận | `date_come_stock` | Khi nào xe đến kho nhận hàng |
| Thời gian xe về kho | `vehicle_end_time` | Khi nào xe về kho cuối |
| Nhóm hàng | `group_of_product_code` / `group_of_product_name` | |
| Hàng hóa | `product_code` / `product_name` | |
| Điểm nhận | `location_from_code` / `location_from_name` | Origin |
| Điểm giao | `location_to_code` / `location_to_name` | Destination |
| Vi phạm ràng buộc | `constraint_name` | Vd: "Vượt tải", "Vượt thể tích" |
| Ghi chú ràng buộc | `constraint_note` | Detail của vi phạm |
| Có data report | `data_report` (Bool) | True = JSON `DataRun.DataReport` không rỗng → có chuyến |
| Đã xóa | `is_deleted` (UInt8) | 1 = soft-deleted (PeerDB CDC), 0 = active |

---

## Status Name Detail — Quy tắc nghiệp vụ

| `is_trip_edit_manual` | JSON `StatusNameDetail` | → `status_name_detail` (derived) |
|---|---|---|
| `true` | NULL hoặc empty string | **Chuyến điều chỉnh route** |
| `true` | Có giá trị | **Chuyến tạo mới** |
| `false` | bất kỳ | **Chuyến tạo mới** |

Nói cách khác: chỉ khi user chỉnh sửa MANUALLY (`is_trip_edit_manual=true`) mà KHÔNG có `StatusNameDetail` đi kèm thì mới gọi là "Chuyến điều chỉnh route". Mọi trường hợp còn lại là "Chuyến tạo mới".

Trường `status_name_detail_original` giữ raw value để debug:
- `'Không có cột'` → JSON không có key `StatusNameDetail` (record cũ, schema chưa update)
- `' '` (1 space) → JSON có key nhưng value NULL/empty
- Giá trị khác → JSON có StatusNameDetail thực

---

## Đơn vị & Chuẩn

| Loại | Đơn vị | Lưu trữ |
|---|---|---|
| Khối lượng | tấn (ton) | `Float64` |
| Thể tích | m³ (CBM) | `Float64` |
| Chi phí | VND | `Float64` |
| Quãng đường | km | `Float64` |
| Thời gian (lưu trong `psv_target`) | UTC | `DateTime64(6, 'Asia/Ho_Chi_Minh')` (timezone metadata) |
| Thời gian (lưu trong `mv_psv_main`) | **UTC+7** (đã shift) | `DateTime` không có tz |

> ⚠️ **Bẫy timezone:** `psv_target` declare cột `master_etd` là `DateTime64(6, 'Asia/Ho_Chi_Minh')` nhưng giá trị thực sự stored là UTC. Khi `mv_psv_main` refresh, nó `+ toIntervalHour(7)` để shift sang UTC+7. Khi query trực tiếp `psv_target` cho dashboard, cần `+ INTERVAL 7 HOUR` thủ công.

---

## Liên kết
- DDL: [`clickhouse-ddl/analytics-workspace_psv.md`](data-sources/clickhouse-ddl/analytics-workspace_psv.md)
- Pipeline lineage: [`data-sources/pipeline.md`](data-sources/pipeline.md)
