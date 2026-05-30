# scripts/ — phân nhóm theo dòng chảy dữ liệu (MECE)

4 nhóm, không chồng lấn, phủ hết. Đọc theo pipeline: **etl → analysis → export**, cộng **meta** (nguồn chân lý).

| Nhóm | Làm gì | File |
|---|---|---|
| **`etl/`** | Đưa dữ liệu VÀO ClickHouse | `download_tms_report.py` (tải TMS report) · `load_tms_report_to_ch.py` (nạp vào CH) |
| **`analysis/`** | Phân tích → `.md` + `.html` | `otif_mtd_audit.py` · `flash_daily_audit.py` · `tms_report_25_audit.py` · `reconcile_tms_otif.py` · `run_all.py` (chạy hết → `reports/index.html`) |
| **`export/`** | Xuất Excel pack cho stakeholder/UAT | `uat_otif_export.py` · `uat_vfr_export.py` · `uat_flash_daily_export.py` · `uat_quick_check_export.py` |
| **`meta/`** | Refresh nguồn chân lý | `export_clickhouse_ddl.py` (DDL) · `fetch_sql_registry.py` (sql-registry) |

## Quy ước chung

- **Chạy từ gốc repo:** `python mondelez/scripts/<nhóm>/<file>.py [--from … --to …]`. Chạy hết audit/reconcile: `python mondelez/scripts/analysis/run_all.py`.
- **Định vị tenant relocation-proof:** mỗi script tự đi lên tìm thư mục chứa `da.toml` (= tenant root) — không phụ thuộc độ sâu thư mục, di chuyển file không vỡ path.
- **Output:** `analysis/` → `mondelez/reports/*.{md,html}` + `index.html` · `export/` → `mondelez/01-sections/*/uat/*.xlsx` · `meta/` → `mondelez/02-data/…`.
- **Explore tương tác** (tra 1 đơn/SO/ngày) KHÔNG ở đây → `mondelez/notebooks/explore.py` (cell `# %%`).

## Thêm script mới

Đặt vào đúng 1 nhóm theo câu hỏi "script này LÀM GÌ với dữ liệu": đưa vào (etl) / phân tích ra report (analysis) / xuất pack (export) / refresh metadata (meta). Nếu một script làm >1 việc → tách, đừng để mơ hồ nhóm.
