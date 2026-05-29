# Cấu trúc file Python cho DA — depth

> Reference của `da-py`. Đọc khi cần thiết kế/refactor cấu trúc file Python (script, notebook, module). Nguồn: bóc từ tooling canonical Mondelez (`load_tms_report_to_ch.py`, `uat_*_export.py`) + nguyên tắc clean code.

---

## 1. Cây thư mục chuẩn của một tenant

```
mondelez/
  .env                         # secret (CLICKHOUSE_*, TMS_*) — KHÔNG commit
  scripts/                     # script CLI: ETL, export, fetch (chạy lặp, có argparse)
  notebooks/                   # audit/explore tương tác (.ipynb) + README.md
  analysis/                    # ĐỀ XUẤT: module dùng chung (ch.py, macros.py, reconcile.py)
  02-data/
    audit-results/             # OUTPUT .md của phân tích/reconcile
    data-sources/              # nguồn chân lý: sql-registry.md, clickhouse-ddl/, glossary.md
    sql/                       # .sql tái sử dụng
  triage/scripts/              # script phụ trợ theo nhu cầu
```

**Nguyên tắc đặt file**:
- Chạy lặp + tham số → `scripts/`
- Tương tác, một-lần → `notebooks/`
- Dùng ở ≥2 nơi → `analysis/` (import, không copy)
- Kết quả người đọc → `02-data/audit-results/*.md` (KHÔNG để trong notebook)

---

## 2. Giải phẫu script CLI — 9 lớp theo thứ tự

| # | Lớp | Nội dung | Lý do |
|---|---|---|---|
| 1 | **Docstring module** | Mục đích · Chiến lược · Cách chạy (kèm ví dụ CLI) · Env cần | `python file.py --help` chưa đủ; người mở file hiểu ngay trong 5s |
| 2 | **Imports** | stdlib → third-party → (local `analysis/`); nhóm bằng dòng trống | Đọc nhanh dependency |
| 3 | **Path resolution** | `Path(__file__).resolve().parent` → tìm `.env`, thư mục data | Chạy từ bất kỳ CWD |
| 4 | **Load `.env`** | `load_dotenv(_ENV if _ENV.exists() else None)` | Secret ngoài code |
| 5 | **Hằng module** | `UPPER_CASE`: `CH_DATABASE`, `CHUNK_DAYS`, `DEFAULT_FROM`, comment bảng | Đổi 1 chỗ, không magic number |
| 6 | **`validate_env()`** | Liệt kê env thiếu, `sys.exit(1)` với message | Fail-fast, không chết giữa chừng |
| 7 | **Helper thuần** | Hàm nhỏ có type hint: `fetch_*`, `build_*`, `to_df` | 1 hàm = 1 nhiệm vụ, test được |
| 8 | **`main()`** | argparse + orchestration + log tiến độ | Điểm vào duy nhất |
| 9 | **`if __name__ == "__main__"`** | gọi `main()` | Import lại hàm mà không chạy |

### Mẫu argparse chuẩn (theo `load_tms_report_to_ch.py`)
```python
p = argparse.ArgumentParser(description="<mô tả ngắn>")
p.add_argument("--from", dest="dfrom", default=DEFAULT_FROM, help="Ngày bắt đầu YYYY-MM-DD")
p.add_argument("--to", dest="dto", default=DEFAULT_TO, help="Ngày kết thúc YYYY-MM-DD")
p.add_argument("--recreate", action="store_true", help="DROP + tạo lại bảng")
p.add_argument("--sleep", type=float, default=3.0, help="Giây nghỉ giữa các lần gọi nguồn")
args = p.parse_args()
```
Lưu ý: `--from` là keyword Python → phải `dest="dfrom"`.

### Log convention
```python
print(f"[INFO] Khoảng: {args.dfrom} → {args.dto} | {n} cột | {len(windows)} cửa sổ")
print(f"        ↳ {len(rows):,} dòng")          # indent cho sub-step
print(f"[OK] Nạp xong: {total:,} dòng")
print(f"[ERROR] Thiếu env: {missing}"); sys.exit(1)
```
`{n:,}` để format số có dấu phẩy. Prefix `[INFO]/[OK]/[ERROR]` đồng nhất toàn bộ scripts.

---

## 3. Idempotency — rerun không làm bẩn data

Mọi script ghi data phải **chạy lại nhiều lần ra cùng kết quả**. Ba pattern:

| Pattern | Khi nào | Cách |
|---|---|---|
| **TRUNCATE + reload** | Bảng staging, full refresh | `TRUNCATE TABLE` rồi insert lại toàn bộ |
| **DROP + recreate** | Đổi schema/comment | flag `--recreate` → `DROP TABLE IF EXISTS` rồi tạo |
| **Upsert / ReplacingMergeTree** | Incremental, giữ lịch sử | insert version mới, engine dedupe |

**Phản ví dụ**: `INSERT` append không guard → chạy 2 lần = data nhân đôi. Luôn hỏi "rerun thì sao?" trước khi viết bước ghi.

---

## 4. Tách module `analysis/` — khi nào & cách

### Tiêu chí tách (đủ MỘT là tách)
- Logic dùng ở ≥2 file (notebook + notebook, hoặc notebook + script)
- Chứa bug-prone logic: timezone convert, UTF-8 parameter bind, grain rollup, on-time grace 30′
- Định nghĩa metric/macro mà nhiều nơi phải đồng bộ

### Cấu trúc đề xuất
```python
# analysis/ch.py — kết nối + chạy query trả DataFrame
import os, clickhouse_connect, pandas as pd

def ch_client():
    return clickhouse_connect.get_client(host=os.getenv("CLICKHOUSE_HOST",""), ...)

def run_df(client, sql: str, params: dict | None = None) -> pd.DataFrame:
    """Chạy SQL, trả DataFrame. params bind an toàn UTF-8 (vd {'svc':'Xuất bán'})."""
    return client.query_df(sql, parameters=params or {})
```
```python
# analysis/macros.py — SQL fragment dùng chung (1 nguồn chân lý)
DT   = lambda c: f"parseDateTimeBestEffortOrNull(nullIf({c}, ''))"
NUM  = lambda c: f"toFloat64OrZero({c})"
ONTIME_GRACE_MIN = 30   # [D]-RULE-OTIF-001
ANALYSIS_FILTER = "position(OrderCode,'-') = 0"   # loại dòng chuyến con
```
```python
# analysis/reconcile.py — hàm đối chiếu pandas (xem reconcile-recipes.md)
def reconcile_by_day(a, b, on, qty_col): ...
```

### Import từ notebook
```python
import sys; sys.path.insert(0, "..")    # notebooks/ → thấy analysis/
from analysis.ch import ch_client, run_df
from analysis.macros import DT, NUM, ANALYSIS_FILTER, ONTIME_GRACE_MIN
```
Tạo `analysis/__init__.py` rỗng để Python nhận package.

### Cảnh báo
- Tách module = refactor có chủ đích → nói rõ với user, đừng âm thầm dựng package.
- **Đừng over-engineer**: macro dùng đúng 1 nơi → để tại chỗ. Trừu tượng hoá sớm tệ hơn copy-paste 1 lần.

---

## 5. Checklist clean code cho file Python DA

Trước khi báo "script xong":
- [ ] Docstring có **Cách chạy** với ví dụ CLI thật
- [ ] Mọi hàm public có type hint
- [ ] Không magic number — đã rút lên hằng `UPPER_CASE`
- [ ] `validate_env()` chặn thiếu env trước khi chạy logic
- [ ] Không hardcode secret — đọc `.env`
- [ ] Tham số tiếng Việt bind, không inline SQL
- [ ] Rerun idempotent (TRUNCATE/DROP/upsert, không append mù)
- [ ] Có `if __name__ == "__main__"`
- [ ] Log `[INFO]/[OK]/[ERROR]` ở các mốc
- [ ] Tên hàm/biến nghiệp vụ (`giao_cse`, `reconcile_by_day`), không `f1`/`tmp`/`df2`
- [ ] Logic dùng ≥2 nơi đã cân nhắc tách `analysis/`

Đạt hết → handoff `/da-ship` cho final gate trước commit.
