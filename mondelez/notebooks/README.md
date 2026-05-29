# Notebooks — Mondelez

Notebook tương tác để tra cứu dữ liệu (đọc `.env` cùng convention với `scripts/`).

| Notebook | Mục đích |
|---|---|
| `tms_report_25_explore.ipynb` | Tra cứu nhanh bảng CH `analytics_workspace.mdlz_tms_report_25_trip_order`: chi tiết 1 đơn (OrderCode), chi tiết 1 chuyến (MasterCode), summary 1 ngày, truy vấn tự do |
| `flash_daily_mtd_audit.ipynb` | Audit + debug số liệu Flash Daily (view `mv_flash_and_drop_report`) theo phạm vi MTD: row count / distinct / freshness, phân bố `e2e_label` + dim, tổng volume Plan/Shipped/Delivered, và 5 nhóm bất thường (NULL, volume integrity, business rule, key/cross-MV parity, timestamp ordering) + slot ad-hoc. |

## Chạy

Mở bằng VSCode/Jupyter, chọn kernel Python có sẵn `clickhouse_connect` + `pandas`. Chạy cell **Setup** một lần, sửa cell **Tham số** rồi chạy cell tương ứng. Cần `CLICKHOUSE_*` trong `projects/mondelez/.env`.
