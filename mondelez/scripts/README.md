# Scripts — Mondelez

Python scripts tiện ích cho dự án (data check, migration, sync, ...).

## Danh sách

| File | Mục đích |
|------|---------|
| download_tms_report.py | Lấy token TMS + tải report (mặc định #25 Trip&Order) từ S3 → `.downloads/tms/` |
| load_tms_report_to_ch.py | Nạp report #25 vào ClickHouse `analytics_workspace.mdlz_tms_report_25_trip_order` (chunk ≤5 ngày, TRUNCATE+reload) |

## Cách chạy

```bash
cd projects/mondelez/scripts
python <script>.py
```
