---
name: da-py
description: Skill MASTER cho việc dùng Python để phân tích số liệu, đối chiếu/reconcile chéo nhiều nguồn, và THIẾT KẾ cấu trúc file Python (script CLI + notebook + module dùng chung). Trigger trên "python", "pandas", "notebook", "jupyter", "script", "đối chiếu", "reconcile", "cross-check", "so số liệu", "audit notebook", "ETL nhỏ", "phân tích bằng python", "tách code khỏi kết quả", "macro dùng chung", "cấu trúc file python". KHÔNG thay /da-ch (thực thi SQL ClickHouse) hay /da-data (định nghĩa metric business) — skill này là TẦNG ORCHESTRATION Python bao quanh chúng.
user-invocable: true
---

# Python Data Analysis & Reconciliation — Master Skill `da-py`

Skill **master** cho Data Analyst dùng Python trên các tenant của Smartlog Control Tower (mặc định **Mondelez**). Ba việc cốt lõi:

1. **Phân tích số liệu** — explore, summary sức khỏe, anomaly sweep bằng pandas + `clickhouse_connect`.
2. **Đối chiếu / reconcile chéo nhiều nguồn** — TMS report ↔ MV ↔ WMS ↔ Golden; full-outer-join theo ngày/đơn, cột Δ, cờ trạng thái.
3. **Thiết kế cấu trúc file Python** — script CLI, notebook audit, và **module dùng chung** để diệt copy-paste macro.

> Đây là tầng **orchestration**. SQL chạy ở đâu? → `/da-ch` (engine ClickHouse). Metric đúng/sai về business? → `/da-data`. Skill này quyết **cách tổ chức code Python, quy trình chạy, và cách trình bày kết quả truy vết được**.

---

## 0. Triết lý (rút từ gstack, áp vào DA Python)

Bộ skill `da-*` này lấy cảm hứng từ [gstack](https://github.com/garrytan/gstack) — "biến Claude Code thành một team kỹ thuật ảo". `da-py` nội hoá 6 nguyên tắc, dịch sang ngôn ngữ phân tích dữ liệu:

| Nguyên tắc gstack | Dịch sang `da-py` |
|---|---|
| **Process over tools** | Không quăng ra một đống script rời. Mọi phân tích đi theo **quy trình 7 bước** (§3), output có path cố định, truy vết được. |
| **Assumption verification first** (`/office-hours`) | TRƯỚC khi viết dòng pandas nào: viết **câu hỏi 1 dòng + giả định + grain + timezone + tolerance**. Không viết được → user chưa rõ, hỏi lại. Solving sai bài toán ở scale = đắt nhất. |
| **Real execution, not simulation** | **Chạy thật, đính số thật.** Tuyệt đối không bịa kết quả, không "ước chừng" output. Mỗi con số trong report phải có cell/script repro được. |
| **Specialized roles** | `da-py` không tự định nghĩa metric (→ `/da-data`) hay tự quyết SQL dialect (→ `/da-ch`). Nó điều phối, không lấn sân. |
| **Safety by default** | Đọc credential từ `.env`, **không bao giờ** hardcode/commit/in password. Script destructive (DROP/TRUNCATE) chỉ chạy trên schema `*_test`, hỏi trước khi đụng production. |
| **Persistent memory / compounding** | **Diệt copy-paste**: macro/hàm dùng ở ≥2 nơi → tách ra **module `.py` chung** (§5). Bug đã fix một lần không tái sinh ở notebook khác. |

**Một câu để nhớ**: *Reuse canonical trước, viết mới sau; chạy thật rồi mới báo; tách code khỏi kết quả.*

---

## 1. Reuse canonical — KHÔNG tự sinh lại

Dự án Mondelez đã có sẵn tooling Python canonical. Mọi bug timezone, parameter-binding UTF-8, grain rollup **đã được fix trong đó**. Tự viết lại = tái phát bug cũ.

| Asset | Dùng cho | Path |
|---|---|---|
| `tms_report_25_explore.ipynb` | Explore TMS report #25 đa cấp + **§L6 cross-check TMS ↔ `mv_otif`** | `mondelez/notebooks/` |
| `otif_mtd_audit.ipynb` | Audit `mv_otif` MTD: summary, KPI OTIF canonical, trend, 5 nhóm anomaly, tra cứu 1 SO | `mondelez/notebooks/` |
| `flash_daily_mtd_audit.ipynb` | Audit `mv_flash_and_drop_report`: summary + 5 nhóm anomaly + parity | `mondelez/notebooks/` |
| `load_tms_report_to_ch.py` | Mẫu **script ETL CLI** chuẩn (argparse + .env + clickhouse_connect + windowing) | `mondelez/scripts/` |
| `uat_*_export.py`, `uat_quick_check_export.py` | Mẫu **export Excel pack** reconciliation | `mondelez/scripts/` |
| `fetch_sql_registry.py`, `export_clickhouse_ddl.py` | Refresh nguồn chân lý (registry, DDL) | `mondelez/scripts/` |

**Quy tắc**: khi cần audit một section → **clone cell/script tương ứng, đổi `PARAMS`, re-run**. Chỉ viết mới khi không có canonical nào gần.

**Gotcha BẮT BUỘC nhớ** (đã debug): chuỗi tiếng Việt (`'Xuất bán'`, `'Hoàn tất'`, `'Đã vận chuyển'`) phải **bind qua tham số** (`{svc:String}`) — KHÔNG inline literal vào SQL. `clickhouse-connect` corrupt UTF-8 trong scalar subquery khi inline → trả 0 row sai. Bind = đúng.

Cross-check chuyên sâu ở tầng SQL (summary + 5 nhóm anomaly + 4 kỹ thuật cross-system) → đọc **[`.claude/skills/da-uat/references/data-audit-and-crosscheck.md`](.claude/skills/da-uat/references/data-audit-and-crosscheck.md)**. `da-py` lo phần **orchestration Python** bao quanh nó.

---

## 2. Hai loại artifact Python — chọn đúng ngay từ đầu

| | **Script CLI** (`.py`) | **Notebook** (`.ipynb`) |
|---|---|---|
| Khi nào | Chạy lặp lại, có tham số, đưa vào cron/pipeline, export pack | Explore 1 lần, audit tương tác, kể chuyện số liệu |
| Đặc trưng | `argparse`, `main()`, idempotent, in log `[INFO]/[OK]/[ERROR]` | Cell Setup → cell Params → cell phân tích, hiển thị DataFrame |
| Output | File (Excel/CSV/MD/bảng CH) + exit code | Bảng + chart trong notebook → export `.md`/HTML |
| Reproducible nhờ | Đối số CLI cố định | Cell Params ở đầu + "Restart & Run All" |
| Sống ở | `mondelez/scripts/` | `mondelez/notebooks/` |

**Nguyên tắc chọn**: nếu sẽ chạy lại với tham số khác / người khác chạy → **script**. Nếu là điều tra một-lần, cần nhìn từng bước → **notebook**. Logic dùng chung giữa cả hai → **module** (§5).

---

## 3. Quy trình chuẩn 7 bước (mọi phân tích)

### Bước 1 — Phát biểu câu hỏi + giả định (assumption-first)
Viết **1 dòng tiếng Việt**: *"Tôi đối chiếu metric X giữa nguồn A và B, kỳ Z, grain G, timezone TZ, tolerance ε?"*. Không viết được → STOP, hỏi user. Đây là `/office-hours` thu nhỏ — chặn việc giải sai bài toán.

Chốt 4 thứ trước khi code:
- **Grain**: đơn / chuyến / ngày / SO × whseid? Hai nguồn KHÁC grain → phải rollup về cùng cấp trước khi so.
- **Timezone**: cột ngày là UTC hay giờ VN? `mv_otif` lưu `DateTime64(3,'UTC')`; TMS report lưu string giờ VN. Quy về cùng một quy ước, ghi rõ.
- **Tolerance**: lệch bao nhiêu là 🟢/🟡/🔴? (mặc định reconcile order-count: 0 = 🟢, 1–2 đơn = 🟡, >2 = 🔴).
- **Trục tin cậy**: khi 2 nguồn khác mẫu số (vd OT%/IF% tính trên tập khác nhau) → **chỉ tin cột số đơn**, % chỉ tham khảo.

### Bước 2 — Reuse trước
Glob `mondelez/notebooks/` + `mondelez/scripts/` tìm asset gần nhất (§1). Có → clone + đổi params. Không → mới sang Bước 3.

### Bước 3 — Chọn loại artifact (§2) + scaffold cấu trúc (§4/§5)
Script hay notebook? Có logic dùng chung không → đặt vào module. **Đừng** mở file trắng gõ tự do — dùng skeleton ở §4.

### Bước 4 — Kết nối + metadata trước query chính
Đọc `.env`, tạo client (§4.2). **Luôn chạy metadata trước**: min/max date, row count, freshness (`last_refresh_time` của MV). Nếu `max_date < ngày user hỏi` → query chính sẽ 0 row, biết trước đỡ tốn thời gian. (Chi tiết engine → `/da-ch`.)

### Bước 5 — Phân tích / đối chiếu (§6 cho reconcile)
Chạy thật. Với reconcile: full-outer-join theo trục chung, tạo cột Δ và cờ trạng thái. Phân loại finding: **Fact / Insight / Hypothesis / Recommendation**.

### Bước 6 — Sanity check trước khi tin
| Check | Cách |
|---|---|
| Tổng group = tổng không group | `df.groupby(...).sum()` vs tổng toàn cục |
| Row count hợp lý | so với kỳ vọng độ lớn của khách |
| NULL/empty rate cột chính | `df[col].isna().mean()` |
| Outlier | `df[metric].describe()` / quantile p95–p99 |
| Join không nở/co bất ngờ | row count sau join vs trước (left/inner) |

### Bước 7 — Xuất kết quả truy vết được
- **Tách code khỏi kết quả** (yêu cầu cố định của user — xem [[mdlz-notebook-reconcile-pattern]]): export bảng/finding ra `.md`, không bắt người đọc cuộn qua code.
- Path chuẩn:
  - Reconcile/cross-system → `mondelez/02-data/audit-results/{a}-vs-{b}-{YYYYMMDD}.md`
  - Phân tích ad-hoc → `mondelez/02-data/audit-results/{slug}-{YYYYMMDD}.md`
- Kết thúc bằng **Mandatory ending signals** (§9).

---

## 4. Cấu trúc file Python — script CLI chuẩn

> Đây là phần "thiết kế cấu trúc file" — depth đầy đủ ở **[`references/python-file-structure.md`](references/python-file-structure.md)**. Dưới đây là skeleton bắt buộc.

### 4.1 Giải phẫu một script (thứ tự cố định)

```python
"""
<tên_file>.py
────────────
<Mục đích 1–2 câu.>

Chiến lược:
  - <bước chính 1>
  - <bước chính 2>

Cách chạy:
    python mondelez/scripts/<tên_file>.py
    python mondelez/scripts/<tên_file>.py --from 2026-05-01 --to 2026-05-26

Env (mondelez/.env): CLICKHOUSE_* (+ TMS_* nếu gọi nguồn TMS)
"""

import os, sys, argparse                 # 1. stdlib
from pathlib import Path
from datetime import datetime, timedelta

import pandas as pd                      # 2. third-party
from dotenv import load_dotenv
import clickhouse_connect

_TENANT_DIR = Path(__file__).resolve().parent.parent   # 3. resolve path → đọc .env cạnh tenant
_ENV = _TENANT_DIR / ".env"
load_dotenv(_ENV if _ENV.exists() else None)

CH_DATABASE = "analytics_workspace"     # 4. hằng UPPER_CASE, không magic number rải rác
DEFAULT_FROM = "2026-05-01"

def validate_env() -> None:             # 5. fail-fast nếu thiếu env
    missing = [k for k in ("CLICKHOUSE_HOST", "CLICKHOUSE_USER") if not os.getenv(k)]
    if missing:
        print(f"[ERROR] Thiếu env trong {_ENV}: {', '.join(missing)}"); sys.exit(1)

def ch_client():                        # 6. factory kết nối — 1 nơi duy nhất
    return clickhouse_connect.get_client(
        host=os.getenv("CLICKHOUSE_HOST", ""),
        port=int(os.getenv("CLICKHOUSE_PORT", "8443")),
        username=os.getenv("CLICKHOUSE_USER", ""),
        password=os.getenv("CLICKHOUSE_PASSWORD", ""),
        secure=os.getenv("CLICKHOUSE_SECURE", "true").lower() not in ("false", "0", "no"),
        connect_timeout=30,
    )

def fetch_xxx(client, params: dict) -> pd.DataFrame:   # 7. hàm thuần, type hint, 1 nhiệm vụ
    ...

def main() -> None:                     # 8. argparse + orchestration
    p = argparse.ArgumentParser(description="<mô tả>")
    p.add_argument("--from", dest="dfrom", default=DEFAULT_FROM)
    p.add_argument("--to", dest="dto", default=DEFAULT_FROM)
    args = p.parse_args()
    validate_env()
    client = ch_client()
    ...

if __name__ == "__main__":              # 9. guard — import được mà không chạy
    main()
```

### 4.2 Quy ước bắt buộc

| Quy ước | Lý do |
|---|---|
| Path qua `Path(__file__).resolve().parent` | Chạy được từ bất kỳ CWD nào, không vỡ khi đổi thư mục |
| `.env` qua `python-dotenv`, **không** hardcode secret | Safety by default — không leak credential |
| Hằng số `UPPER_CASE` ở đầu module | Đổi tham số một chỗ, không săn magic number |
| `validate_env()` fail-fast với message rõ | Lỗi env phát hiện ngay, không chết giữa chừng |
| Type hint cho mọi hàm public | Đọc nhanh, IDE bắt lỗi |
| Log `[INFO]/[OK]/[ERROR]` | Theo dõi tiến độ script dài, đồng nhất với canonical |
| `if __name__ == "__main__"` | Import lại hàm trong notebook/test mà không trigger run |
| Bind tham số tiếng Việt (`{x:String}`), không inline | Tránh corrupt UTF-8 của clickhouse-connect (§1) |
| Idempotent: rerun không nhân đôi data | DROP/TRUNCATE+reload, hoặc upsert — không append mù |

---

## 5. Module dùng chung — DIỆT copy-paste (compounding)

**Vấn đề đã ghi nhận** ([[mdlz-notebook-reconcile-pattern]]): macro `DT()`/`NUM()`/`ONTIME()` + `ANALYSIS_FILTER` đang bị **copy giữa các notebook** → khi sửa một nơi, nơi kia divergence âm thầm. Đây đúng là thứ gstack gọi *"compounding intelligence"* — kiến thức phải tích luỹ một chỗ.

**Giải pháp**: tách logic dùng ở ≥2 nơi ra một module chung, notebook/script chỉ `import`.

```
mondelez/
  analysis/                      # ← module dùng chung (ĐỀ XUẤT tạo)
    __init__.py
    ch.py                        # ch_client(), run_df(client, sql, params) -> DataFrame
    macros.py                    # DT/NUM/ONTIME (SQL fragment) + ANALYSIS_FILTER
    reconcile.py                 # reconcile_by_day(), confusion_matrix(), set_diff()
  notebooks/                     # import từ analysis/, KHÔNG định nghĩa lại macro
  scripts/                       # CLI, cũng import analysis/
```

Notebook chỉ còn:
```python
import sys; sys.path.insert(0, "..")          # cho phép import analysis/ từ notebooks/
from analysis.ch import ch_client, run_df
from analysis.macros import DT, NUM, ONTIME, ANALYSIS_FILTER
from analysis.reconcile import reconcile_by_day
```

**Tiêu chí tách module**: dùng ≥2 nơi, HOẶC chứa bug-prone logic (timezone, UTF-8 bind, grain rollup, on-time grace). Macro dùng đúng 1 nơi → để tại chỗ, đừng over-engineer.

> Đề xuất tạo `analysis/` là một **refactor có chủ đích** — phải nói rõ với user và (nếu lớn) handoff `/da-ship` trước khi commit. Đừng âm thầm dựng package mới.

---

## 6. Reconcile / đối chiếu chéo — playbook Python

Đây là nhu cầu lặp lại nhất của user. Recipe pandas chi tiết → **[`references/reconcile-recipes.md`](references/reconcile-recipes.md)**. Khung tư duy:

### 6.1 Bốn bước reconcile
1. **Align grain** (BẮT BUỘC trước mọi so sánh) — rollup cả hai nguồn về cùng cấp. TMS `GROUP BY OrderCode` (`kh=max(QtyOrder)` chống double-count khi đơn vào nhiều chuyến); MV `GROUP BY so`. Align timezone về cùng quy ước. Filter cùng service scope (`mv_otif` chỉ `'Xuất bán'`).
2. **Full-outer-join theo trục chung** (thường `(code, ngay)` hoặc `(so, ngay)`):
   ```python
   m = a.merge(b, on=["code", "ngay"], how="outer", suffixes=("_a", "_b"), indicator=True)
   ```
3. **Tạo cột Δ + cờ trạng thái**:
   ```python
   m["delta_don"] = m["don_a"].fillna(0) - m["don_b"].fillna(0)
   m["flag"] = m["delta_don"].map(lambda d: "🟢" if d == 0 else ("🟡" if abs(d) <= 2 else "🔴"))
   ```
   `_merge == "left_only"/"right_only"` → đơn chỉ có ở một nguồn (lệch **tập đơn**, KHÁC lệch số liệu — phân loại riêng).
4. **Phân loại nguyên nhân lệch** (đừng để "lệch" trần): chưa lên chuyến / status='Chờ' / timezone giáp ranh ngày / service khác / sai cột đơn vị. Biến "lệch" → "lệch vì lý do X đã hiểu".

### 6.2 Quy tắc tin cậy (từ [[mdlz-notebook-reconcile-pattern]])
- **Chỉ tin cột số đơn** khi 2 nguồn có định nghĩa % khác mẫu số. TMS tính % trên dòng `Hoàn tất`; `mv_otif` tính trên `count(so)` gồm cả `Không có dữ liệu STM` → **OT%/IF% Δpp chỉ tham khảo**, không kết luận pass/fail từ nó.
- Trục ngày chung mặc định = **"Ngày gửi thầu"** (`TenderedDate` ≈ `thoi_gian_gui_thau`), `toDate` raw không convert TZ trừ khi đã chốt align VN ở Bước 1.

### 6.3 Trình bày kết quả reconcile
Bảng đối chiếu theo ngày: `ngay | don_a | don_b | Δ | flag | OT%_a | OT%_b | Δpp(tham khảo)`. Dưới bảng: liệt kê top đơn lệch (sort theo độ nặng) + dòng phân loại nguyên nhân. Export ra `.md` (tách khỏi code).

---

## 7. Notebook — quy ước trình bày

| Quy ước | Chi tiết |
|---|---|
| **Cell Setup** (chạy 1 lần) | import + `ch_client()` + macro (lý tưởng: `from analysis...`) |
| **Cell Params** (sửa rồi chạy) | `WINDOW`, `DATE_COL`, `WHSEID`, filter — gom 1 chỗ, KHÔNG rải rác giữa code |
| **Reproducible** | Phải chạy được bằng "Restart & Run All" từ trên xuống. Không phụ thuộc thứ tự chạy lung tung |
| **Tách code/kết quả** | User thấy "coi cả code lẫn kết quả trong Jupyter bất tiện" → ưu tiên export `.md`/HTML, hoặc Jupytext pair `.py`, hoặc hide-input |
| **Không hardcode secret** | Đọc `.env` như script (cùng convention) |
| **Markdown cell tiêu đề** | Mỗi block phân tích có heading nói **so-what**, không chỉ "Query 3" |

---

## 8. Anti-patterns (tránh)

| Sai | Tại sao | Sửa |
|---|---|---|
| Viết pandas trước khi chốt grain/timezone/tolerance | So sai mẫu số → kết luận sai toàn bộ | Bước 1 — phát biểu 1 dòng + 4 chốt |
| Inline chuỗi tiếng Việt vào SQL | clickhouse-connect corrupt UTF-8 → 0 row sai | Bind `{x:String}` |
| Copy macro `DT/NUM/ONTIME` giữa các notebook | Divergence âm thầm khi sửa 1 nơi | Tách `analysis/` module (§5) |
| Kết luận pass/fail từ Δpp của OT%/IF% | Hai nguồn khác mẫu số | Chỉ tin cột số đơn; % tham khảo |
| So 2 nguồn khác grain mà không rollup | Double-count khi đơn vào nhiều chuyến | Align grain trước (§6.1) |
| Bịa/ước chừng output thay vì chạy thật | Vi phạm "real execution" | Chạy → đính số thật → repro được |
| Hardcode credential trong `.py`/notebook | Leak khi commit | `.env` + dotenv |
| Append data mà không idempotent | Rerun nhân đôi | DROP/TRUNCATE+reload hoặc upsert |
| `SELECT *` rồi lọc ở pandas | Tốn I/O, có thể OOM | Project cột cần ở SQL (→ `/da-ch`) |
| Notebook chạy phụ thuộc thứ tự lung tung | Người khác không repro được | Restart & Run All phải xanh |
| Để code lẫn kết quả khi giao stakeholder | User đã nói bất tiện | Export `.md`/HTML, tách rõ |
| `merge` xong không check row count nở/co | Join nhân bản âm thầm | Sanity check row count (Bước 6) |

---

## 9. Mandatory ending signals

Mỗi lần kết thúc một phân tích/đối chiếu bằng `/da-py`, output phải có:

- `ARTIFACT_PATH`: file `.md`/`.py`/`.ipynb` đã tạo/cập nhật (đường dẫn từ repo root)
- `DATA_CONFIDENCE`: High | Medium | Low (kèm lý do nếu không High — vd "MV refresh trễ 1h", "lệch tập đơn 12 đơn chưa phân loại")
- `MV_FRESHNESS`: `last_refresh_time` của MV chính (hoặc "N/A — bảng raw / file export")
- `GRAIN` + `TIMEZONE`: grain so sánh và quy ước timezone đã dùng (để người đọc verify đúng cơ sở)
- `NEXT_ACTION`: handoff cụ thể — `/da-ch` nếu lệch do MV/SQL, `/da-data` nếu cần định nghĩa lại metric, `/da-ship` nếu sắp commit script/module, `team pipeline` nếu MV refresh fail, hoặc `done`

---

## 10. Khi nào KHÔNG dùng skill này

- Chạy SQL ad-hoc / tối ưu query / debug MV ở tầng engine ClickHouse → **`/da-ch`**
- Định nghĩa metric/KPI đúng/sai về business → **`/da-data`**
- Audit UAT lifecycle business-side (reconcile 3 nguồn Dashboard/SQL/Golden có quy trình riêng) → **`/da-uat`**
- Code widget React đọc dữ liệu → `/frontend`
- Tạo entity / QueryConfig / migration backend → `/backend`
- Final gate trước khi commit script/module Python → **`/da-ship`** (4 gate: Scope / Clean Code / Verification / Traceability)

---

## 11. Pre-Ship — Clean Code Reference

Khi output `/da-py` đi vào code path (script commit vào `mondelez/scripts/`, module mới trong `analysis/`, notebook commit) → bắt buộc áp rubric **[`.claude/skills/da-ship/references/clean-code.md`](.claude/skills/da-ship/references/clean-code.md)**.

Trục bắt buộc kiểm:
- **#1 Naming** — hàm/biến đặt tên nghiệp vụ (`reconcile_by_day`, không `f1`/`df2`); cột output khớp glossary
- **#2 Single Purpose** — 1 hàm = 1 nhiệm vụ; tránh hàm 100 dòng fetch + transform + export
- **#3 DRY** — tách macro/logic dùng ≥2 nơi ra `analysis/` (§5); reuse canonical (§1) trước khi viết mới
- **#4 WHY > WHAT** — docstring/comment giải thích lý do (vì sao rollup theo OrderCode, vì sao bind tham số), không kể lại code
- **#5 Boundaries** — `.env` không hardcode; timezone UTC↔UTC+7; NULL trong mẫu số; idempotent rerun

Final gate trước push: chạy **`/da-ship`**.
