# Kế hoạch — DA Python Platform (đa tenant)

> **Trạng thái:** PROPOSAL — chờ review, **chưa code**.
> **Ngày:** 2026-05-29 · **Người soạn:** DA (`/da-py`)
> **Quyết định user đã chốt:** đa tenant + thư viện DA dùng chung + báo cáo/reconcile tự động + framework reconcile chuẩn hoá. Bước đầu = **chốt kế hoạch chi tiết trước**, chưa thực thi.

---

## ⚑ Reframe (2026-05-29, theo phản hồi user)

**Artifact phân tích CHÍNH = script `.py` → kết quả `.md`** (không phải notebook). Notebook chỉ giữ cho explore tương tác — "phần nhỏ". Mọi phân tích lặp lại / cần đọc-gửi → viết `.py` dùng `da.cli` + `da.run_df` + `da.reconcile` + `da.save_md`, xuất `.md` vào `<tenant>/reports/`.

→ Mẫu chuẩn đã chạy thật: [`mondelez/scripts/reconcile_tms_otif.py`](../scripts/reconcile_tms_otif.py) → [`mondelez/reports/tms-vs-otif-20260528.md`](../reports/tms-vs-otif-20260528.md).

## 0. Vấn đề (đo được, không cảm tính)

Khảo sát `mondelez/notebooks/` (3 notebook) + `mondelez/scripts/` (8 script):

| Boilerplate bị lặp | Lặp ở đâu |
|---|---|
| `_find_tenant()` (định vị `.env`) | 3/3 notebook **+** 8/8 script |
| `clickhouse_connect.get_client(...)` | 3/3 notebook **+** 5/8 script |
| `q()` / render-helper | 3/3 notebook (3 bản **khác nhau** nhẹ) |
| `DT()`/`NUM()`/`ONTIME(grace)`, `ANALYSIS_FILTER`, `SO_VALID`, `GRACE` | tms notebook; GRACE tái suy ra ở otif → **divergence** |
| `pd.set_option` + bảng màu | 3/3 notebook |
| `validate_env()` | 3/8 script (5 script bỏ qua → **không nhất quán**) |

Việc làm **nhiều nhất** — reconcile **TMS report #25 ↔ `mv_otif`** theo ngày — đang nằm rời rạc ở §L6 notebook tms, **không phải hàm tái dùng** → mỗi lần đối chiếu gõ lại.

Hiện trạng: **không** có `analysis/` package, **không** `requirements.txt`/`pyproject.toml`, **không** tách code/kết quả. Đúng như memory note: macro copy giữa notebook → divergence âm thầm; xem code+kết quả lẫn lộn trong Jupyter bất tiện.

**Hệ quả nếu không xử lý:** sang tenant Panasonic sẽ copy nguyên bộ boilerplate lần thứ tư → bug timezone/UTF-8 cũ tái sinh; mỗi report tự động phải viết lại connection + reconcile từ đầu.

---

## 1. Kiến trúc đề xuất — 3 tầng

`da/` (shared, tenant-agnostic) ← tầng lõi. Tenant dir (`mondelez/`, `panasonic/`) chỉ giữ **config + recipe + output**. Notebook/script là tầng mỏng nhất, chỉ `import da`.

```
helix-projects/
├── da/                              # ★ THƯ VIỆN DÙNG CHUNG (cài editable: pip install -e da)
│   ├── pyproject.toml               #   → ở đâu cũng `import da`, KHÔNG sys.path hack
│   ├── README.md
│   └── da/
│       ├── __init__.py
│       ├── config.py                # TenantConfig: load .env + <tenant>/da.toml
│       ├── ch.py                    # ch_client(cfg) · run_df(client, sql, **params) · meta()
│       ├── macros.py                # DT · NUM · ontime(come,eta,grace) — fragment generic
│       ├── reconcile.py             # ★ FRAMEWORK: align_grain · full_outer_by · delta_flags · classify
│       ├── report.py                # save_md · palette · setup_display · excel_pack
│       └── cli.py                   # build_parser(--tenant/--from/--to) · resolve()
├── mondelez/
│   ├── .env                         # secret (gitignored — KHÔNG commit)
│   ├── da.toml                      # ★ CONFIG TENANT: bảng, service scope, grace, date col
│   ├── analysis/                    # recipe đặc thù tenant (mỏng, tuỳ chọn)
│   │   ├── __init__.py
│   │   └── sources.py               #   tms_report_25() · mv_otif() — định nghĩa nguồn riêng tenant
│   ├── notebooks/                   # Setup cell rút từ ~50 dòng → ~5 dòng
│   ├── scripts/                     # CLI dùng chung da.cli + da.ch
│   └── reports/                     # ★ output sinh tự động (.md/.xlsx)
└── panasonic/
    ├── .env · da.toml · analysis/ · ...   # nhân bản cấu trúc → đa tenant chứng minh ở Phase 6
```

**Vì sao `da/` ở top-level, không nằm trong `mondelez/`:** cả `mondelez/` và `panasonic/` đã tồn tại ở root. Lõi phải là **sibling** để cả hai cùng import. Nếu nhét vào `mondelez/` thì Panasonic không reuse được → phá mục tiêu đa tenant.

**Tách config khỏi code:** mọi thứ *khác nhau giữa tenant* (tên bảng vật lý, service scope `'Xuất bán'`, grace 30′, cột ngày mặc định, filter `SO_VALID`) nằm trong `da.toml` — **không hardcode trong lõi**. Lõi chỉ chứa logic *giống nhau* mọi tenant.

---

## 2. Thiết kế API từng module (hợp đồng giao diện)

### 2.1 `da/config.py` — nạp cấu hình tenant
```python
@dataclass(frozen=True)
class ChCreds:        # đọc từ .env
    host: str; port: int; user: str; password: str; secure: bool

@dataclass(frozen=True)
class TenantConfig:
    name: str                 # "mondelez"
    root: Path                # .../mondelez
    database: str             # "analytics_workspace"
    ch: ChCreds
    tables: dict[str, str]    # logical -> physical, vd "mv_otif" -> "mv_otif"
    scope: dict               # grace, so_valid, otif_service, default_date_col...

def load_tenant(name_or_path: str | None = None) -> TenantConfig: ...
    # 1) tìm tenant dir (kế thừa _find_tenant cũ)  2) load .env  3) load da.toml
    # 4) validate_env fail-fast nếu thiếu CLICKHOUSE_*  5) trả TenantConfig
```
`mondelez/da.toml` (rút từ hằng số đang hardcode trong notebook):
```toml
database = "analytics_workspace"
[tables]
tms_report_25 = "mdlz_tms_report_25_trip_order"
mv_otif       = "mv_otif"
mv_flash      = "mv_flash_and_drop_report"
mv_flash_only = "mv_flash_report"
mv_drop       = "mv_dropped_report"
[scope]
ontime_grace_min = 30
so_valid         = "position(OrderCode, '-') = 0"   # loại mã đơn "XXXXXXXX-N"
otif_service     = "Xuất bán"
default_date_col = "thoi_gian_gui_thau"             # "Ngày gửi thầu" (trục reconcile chung)
```

### 2.2 `da/ch.py` — kết nối + truy vấn (1 nơi duy nhất)
```python
def ch_client(cfg: TenantConfig): ...
    # factory get_client DUY NHẤT — thay 13 bản copy. connect_timeout=30, send_receive_timeout=120
def run_df(client, sql: str, **params) -> pd.DataFrame: ...
    # bind tham số an toàn. Chuỗi tiếng Việt -> {x:String}, KHÔNG inline (chống corrupt UTF-8)
def meta(client, table: str) -> dict: ...
    # min/max date, row count, last_refresh_time (freshness MV) — chạy TRƯỚC query chính (Bước 4 §3)
```

### 2.3 `da/macros.py` — SQL fragment generic (hết divergence)
```python
def DT(col: str)  -> str: ...    # parseDateTimeBestEffortOrNull(nullIf(col,''))
def NUM(col: str) -> str: ...    # toFloat64OrZero(col)
def ontime(come: str, eta: str, grace_min: int) -> str: ...   # tham số hoá, KHÔNG global GRACE
# Chỉ fragment GIỐNG mọi tenant. Scope đặc thù (service, so_valid) lấy từ cfg.scope, không nhúng ở đây.
```

### 2.4 `da/reconcile.py` — ★ FRAMEWORK reconcile chuẩn hoá
Cô đọng 4 bước reconcile (`/da-py §6.1`) thành hàm tái dùng cho **mọi** cặp nguồn:
```python
def align_grain(df, key: list[str], agg: dict) -> pd.DataFrame: ...
    # rollup về cùng grain. vd TMS: GROUP BY OrderCode, kh=max(QtyOrder) chống double-count đa-chuyến
def full_outer_by(a, b, on: list[str], suffixes=("_a","_b")) -> pd.DataFrame: ...
    # merge how="outer", indicator=True (_merge: left_only/right_only/both)
def delta_flags(m, col_a, col_b, green=0, amber=2) -> pd.DataFrame: ...
    # thêm cột delta + cờ 🟢(=0) 🟡(<=amber) 🔴(>amber)
def reconcile_by_day(a, b, on=("code","ngay"), metric="don", tol=(0,2)) -> pd.DataFrame: ...
    # bọc 3 hàm trên → bảng ngay|don_a|don_b|Δ|flag. CHỈ tin cột số đơn (% khác mẫu số → tham khảo)
def classify_causes(m) -> pd.DataFrame: ...
    # gán nhãn nguyên nhân lệch: left/right_only (lệch tập đơn) · status='Chờ' · tz giáp ranh · service khác
```
> Lần đầu dùng để **port §L6 tms notebook** (TMS↔mv_otif) thành `reconcile_by_day` — biến code rời thành API.

### 2.5 `da/report.py` — tách code khỏi kết quả
```python
PALETTE = {"navy":"#1E3A5F", "accent":"#2563EB", ...}   # gom bảng màu rải rác
def setup_display() -> None: ...        # pd.set_option block dùng chung
def save_md(blocks, path: Path, title=None) -> Path: ...  # xuất bảng/finding ra .md (không bắt cuộn code)
def excel_pack(sheets: dict[str, pd.DataFrame], path: Path) -> Path: ...  # gom uat_*_export pattern
```

### 2.6 `da/cli.py` — scaffold script CLI nhất quán
```python
def build_parser(desc: str) -> argparse.ArgumentParser: ...   # --tenant --from --to chuẩn
def resolve(args) -> tuple[TenantConfig, tuple[str,str]]: ...  # load_tenant + window
```

**Notebook Setup cell sau khi migrate** (~50 dòng → ~6 dòng):
```python
from da.config import load_tenant
from da.ch import ch_client, run_df
from da.macros import DT, NUM, ontime
from da.reconcile import reconcile_by_day
cfg = load_tenant("mondelez"); client = ch_client(cfg)
```

---

## 3. Lộ trình migrate (phân pha, an toàn, có cổng parity)

| Pha | Nội dung | Cổng xác nhận (gate) |
|---|---|---|
| **0** ✅ | Chốt kế hoạch này: kiến trúc + vị trí `da/` + schema `da.toml` + cách cài (editable) | User APPROVE doc này |
| **1** ✅ **DONE 2026-05-29** | Scaffold `da/` (config·ch·macros·reconcile·report·cli) + `mondelez/da.toml` + `pyproject.toml` + `requirements.txt`. **Không đổi hành vi.** | ✅ `pip install -e ./da` OK; `import da` OK; parity Vietnamese bound==inline=555,558; `meta()` freshness OK; notebook/script cũ không đụng |
| **2** ✅ **DONE 2026-05-29** | Migrate `otif_mtd_audit.ipynb` → `import da` (proof) | ✅ nbconvert --execute: **0 lỗi**; setup cell `da`-backed; KPI OTIF 91.75%/Ontime 92.68%/Infull 98.95% (total SO 22,183) — khớp data; chỉ đổi plumbing, `q()`/`T`/cells giữ nguyên |
| **3** ✅ **DONE 2026-05-29 (theo reframe: .py-first)** | Thay vì migrate notebook → **build script `.py` → `.md`** cho cả 3 audit (otif/flash/tms), giữ notebook cho explore | ✅ 3 script chạy exit 0: `otif_mtd_audit.py` (%OTIF 91.75%, 22,182 SO) · `flash_daily_audit.py` (100,765 row, parity=0) · `tms_report_25_audit.py` (27 ngày, 24,337 đơn) — đều bind tiếng Việt chuẩn, .md vào reports/ |
| **4** | Migrate 8 script → `da.ch_client` + `da.cli` (1 `validate_env`, nhất quán) | Mỗi script chạy `--help` + 1 lần thật, exit 0 |
| **5** ✅ **DONE 2026-05-29 (kéo lên sớm)** | Build `reconcile.py`; port §L6 → `scripts/reconcile_tms_otif.py` → `mondelez/reports/tms-vs-otif-{YYYYMMDD}.md` | ✅ Script chạy: 28 ngày, 8 ngày lệch số đơn, bind tiếng Việt chuẩn, .md sinh ra OK |
| **6** | Nhân `da.toml` cho **Panasonic** + 1 notebook/script mẫu | Đa tenant chứng minh: cùng lõi, khác config |
| **7** (sau) | Báo cáo tự động định kỳ (cron/scheduled) gọi `scripts/reconcile_*.py` | Lịch chạy, output vào `reports/`, có log |

**Nguyên tắc an toàn:** không xoá boilerplate cũ cho tới khi pha tương ứng pass cổng parity. Mỗi pha là 1 PR nhỏ qua `/da-ship`.

---

## 3b. Caveat đã phát hiện khi build Phase 1

**Namespace shadowing:** thư mục `da/` ở root khiến `import da` bị che nếu CWD = root repo (Python coi `da/` là namespace package rỗng → `AttributeError`). **Không ảnh hưởng thực tế:**
- Notebook chạy với CWD = thư mục notebook (mondelez/notebooks) → OK.
- Script chạy `python mondelez/scripts/x.py` → `sys.path[0]` = thư mục script, CWD root KHÔNG trên path → OK.
- Chỉ lỗi khi gõ `python -c "import da"` đứng ngay tại root repo → workaround: `cd` ra chỗ khác, hoặc dùng notebook/script như thường.

## 4. Quyết định cần user chốt (open decisions)

1. **Vị trí lõi & git boundary** — `da/` ở root `helix-projects/`, hay nằm trong repo `projects/` (helix_projects, có `.git` riêng — xem `/da-projects`)? Đề xuất: theo nơi tenant dir đang được version-control để cùng remote.
2. **Cách cài lõi** — `pip install -e da` (editable, **đề xuất**, hết `sys.path` hack) vs giữ `sys.path.insert`. Editable cần user đồng ý chạy 1 lệnh cài 1 lần.
3. **Tên package** — `da` (ngắn) vs `helix_da` / `slda` (tránh đụng tên chung). Đề xuất `da`.
4. **Config format** — `da.toml` (cần `tomllib`, Python 3.11+; user đang 3.12 ✅) vs `.yaml`/`.json`. Đề xuất `.toml`.
5. **Tách code/kết quả notebook** — chỉ `save_md` (đề xuất, đủ dùng) hay thêm **Jupytext pairing** (`.py` ↔ `.ipynb`) / hide-input cho diff git sạch?

---

## 5. Phạm vi KHÔNG nằm trong kế hoạch này

- Viết/sửa SQL engine ClickHouse, tối ưu MV → `/da-ch`
- Định nghĩa lại metric OTIF/OT%/IF% đúng/sai business → `/da-data`
- Final gate trước commit code/module → `/da-ship`
- Không tạo `da/` package thật ở pha này — **chỉ kế hoạch**.

---

## Tín hiệu kết thúc

- **ARTIFACT_PATH:** `mondelez/03-build/da-python-platform-plan.md` (kế hoạch — chưa code)
- **DATA_CONFIDENCE:** N/A (đây là plan, không phải phân tích số liệu)
- **MV_FRESHNESS:** N/A
- **GRAIN/TIMEZONE:** sẽ chốt ở từng reconcile khi triển khai (mặc định grain đơn theo "Ngày gửi thầu", `toDate` raw)
- **NEXT_ACTION:** user review §4 (5 quyết định) → APPROVE → triển khai Phase 1 qua `/da-py`, chốt commit qua `/da-ship`
