# Notebooks — Mondelez

Notebook tương tác để tra cứu dữ liệu (đọc `.env` cùng convention với `scripts/`).

| Notebook | Mục đích |
|---|---|
| `tms_report_25_explore.ipynb` | Tra cứu nhanh bảng CH `analytics_workspace.mdlz_tms_report_25_trip_order`: chi tiết 1 đơn (OrderCode), chi tiết 1 chuyến (MasterCode), summary 1 ngày, truy vấn tự do |

## Chạy

Mở bằng VSCode/Jupyter, chọn kernel Python có sẵn `clickhouse_connect` + `pandas`. Chạy cell **Setup** một lần, sửa cell **Tham số** rồi chạy cell tương ứng. Cần `CLICKHOUSE_*` trong `projects/mondelez/.env`.
