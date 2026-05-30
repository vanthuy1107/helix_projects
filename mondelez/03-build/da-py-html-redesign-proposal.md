# Đề xuất — DA Python: xuất HTML + khai tử notebook (.py-first hoàn toàn)

> **Trạng thái:** PROPOSAL — chờ review, **chưa code**.
> **Ngày:** 2026-05-29 · **Người soạn:** DA (`/da-py`)
> **Tiếp nối:** [da-python-platform-plan.md](da-python-platform-plan.md) (Phase 0–5 ✅ DONE). Doc này = **Phase 8–9** của lộ trình đó.
> **Quyết định user đã chốt (2026-05-29):** (1) HTML qua `save_html()` song sinh `save_md` · (2) giữ **cả** `.md` + `.html` · (3) **xóa hết** `.ipynb`, thay bằng `explore.py` (`# %%` cells) · (4) mỗi report 1 `main()` + 1 `run_all.py` sinh `index.html`.

---

## 0. Chốt phạm vi — KHÔNG đập lõi `da/`

Khảo sát thực tế: lõi `da/` (config·ch·macros·reconcile·report·cli) **đã sạch và đã chạy thật** — chính là bản đã dọn copy-paste. Các script audit/reconcile đã `import da` → xuất `.md` vào `mondelez/reports/`. "Cồng kềnh" còn lại = **3 file `.ipynb`** (JSON bloat, macro dễ divergence, xem code lẫn kết quả bất tiện).

→ "Đập đi xây lại lõi" là **anti-pattern** (`/da-py §8`): viết lại = tái sinh bug timezone/UTF-8/grain đã fix. Doc này chỉ làm **2 việc thực sự mới**:

| Việc mới | Vì sao | Đụng vào |
|---|---|---|
| **A. Tầng HTML** | `.md` đẹp để diff git nhưng gửi stakeholder cần trình bày | `da/report.py` (+1 hàm) + 1 dòng/script |
| **B. Khai tử notebook** | `.ipynb` cồng kềnh, diff bẩn, dễ divergence | `explore.py` mới + xóa 3 `.ipynb` |

Lõi `da/` **giữ nguyên**. Mọi script `.py` hiện có **giữ nguyên logic**, chỉ thêm 1 dòng `save_html`.

---

## 1. Tầng HTML — `save_html()` song sinh `save_md()`

### 1.1 Hợp đồng API (cùng `blocks` list — script chỉ thêm 1 dòng)

`save_md` hiện nhận `blocks: list[str | DataFrame]`. `save_html` nhận **đúng list đó** → script không phải dựng lại gì:

```python
# da/report.py — THÊM, không sửa save_md
def save_html(blocks, path, *, title=None, subtitle=None) -> Path:
    """Cùng `blocks` như save_md → 1 file .html self-contained (CSS inline).
       str       -> _md_to_html() (subset markdown: heading/bold/italic/code/list/pipe-table)
       DataFrame -> df.to_html(classes='da', index=False) + tô cờ RAG (🟢🟡🔴)
    Bọc trong <style> bộ nhận diện Smartlog lightmode. Mở browser / gửi đi được ngay."""
```

Script đổi đúng 1 chỗ cuối `main()`:
```python
out_md = cfg.root / "reports" / f"otif-mtd-audit-{dto.replace('-','')}.md"
da.save_md(blocks, out_md, title=...)
da.save_html(blocks, out_md.with_suffix(".html"), title=...)   # ← chỉ thêm dòng này
```

### 1.2 `_md_to_html()` — converter subset (zero dependency)

Các `str` block trong report chỉ dùng một **tập con markdown cố định** (heading `#/##/###`, `**bold**`, `_italic_`, `` `code` ``, `- list`, và bảng pipe do `kpi_table_md` sinh). Viết 1 converter ~40 dòng phủ đúng tập đó — **không kéo lib `markdown`** (giữ lời hứa zero-new-dep). Đây là converter **có chủ đích giới hạn**, không phải markdown engine tổng quát; gặp cú pháp ngoài tập con → render nguyên văn (an toàn, không vỡ).

> Vì sao không dùng lib `markdown`: thêm dependency cho 5 cú pháp là thừa; và ta cần tự kiểm soát class CSS của `<table>` để tô RAG. Đánh đổi: nếu sau này report dùng markdown phức tạp hơn (ảnh, blockquote lồng) → cân nhắc nâng lên lib. Ghi rõ giới hạn trong docstring.

### 1.3 CSS — bộ nhận diện Smartlog lightmode (1 hằng số)

Tái dùng đúng palette `/da-ops-release` (đã chuẩn hóa cho stakeholder tenant), gom thành `_HTML_CSS` trong `report.py`, dùng lại `PALETTE` sẵn có:

- navy `#1E3A5F` · dark `#14283F` · accent `#2563EB` · pale `#EFF4FB`
- **KHÔNG** dark mode · **KHÔNG** gradient · **KHÔNG** drop-shadow · `font-weight ≤ 500`
- bảng: header navy nền pale, zebra nhạt, số canh phải; cờ RAG giữ emoji (🟢🟡🔴 render tốt trong HTML), tùy chọn map sang badge màu.

### 1.4 PDF (tùy chọn, không bắt buộc Phase này)

`save_pdf(html_path)` qua **Edge headless** (zero-dep trên Windows, đã dùng ở `/da-ops-release`):
```
msedge --headless --disable-gpu --print-to-pdf="<out.pdf>" "<file:///out.html>"
```
Để **sau** — chỉ thêm khi cần phát hành PDF chính thức. Phase này dừng ở `.html`.

---

## 2. Runner — mỗi report 1 `main()` + `run_all.py` → `index.html`

### 2.1 Giữ nguyên: mỗi script là 1 entry độc lập
Mỗi `scripts/*_audit.py` / `reconcile_*.py` vẫn có `main()` riêng, chạy lẻ được (`python mondelez/scripts/otif_mtd_audit.py --from ... --to ...`) → tự xuất `.md` + `.html`. **Không gộp** — chạy lẻ 1 report khi cần là quan trọng.

### 2.2 Mới: `scripts/run_all.py` — chạy tất cả + trang chủ

```python
# scripts/run_all.py — orchestrator mỏng
REPORTS = [                                   # khai báo, không hardcode rải rác
    ("OTIF MTD",        "otif_mtd_audit",     "mv_otif"),
    ("Flash Daily MTD", "flash_daily_audit",  "mv_flash"),
    ("TMS Report #25",  "tms_report_25_audit","tms_report_25"),
    ("TMS ↔ OTIF",      "reconcile_tms_otif", None),
]
# for each: import module, gọi build_blocks()+save_md/html, thu (title, html_path,
#           headline_metric, freshness, status RAG)
# → da.save_html(index_blocks, reports/index.html, title="DA Reports — <tenant> — <date>")
```

`index.html` = bảng liên kết: `Report | Window | Freshness MV | Headline | Trạng thái | Mở`. Một cú click mở từng `.html`.

> **Refactor kèm theo (nhỏ, có chủ đích):** tách phần dựng `blocks` của mỗi script ra hàm `build_blocks(client, cfg, window) -> list` để `run_all.py` gọi lại được mà không chạy `main()` (tránh double-parse argv). `main()` chỉ còn = parse args → `build_blocks` → `save_md/html`. Đây là Single-Purpose (`/da-ship` #2), không đổi hành vi.

---

## 3. Khai tử notebook → `explore.py` (`# %%` cells)

### 3.1 Vì sao `.py` với `# %%` thay vì `.ipynb`
VSCode "Jupyter Interactive" chạy **từng cell `# %%`** trong file `.py` thuần (Shift+Enter) — y hệt trải nghiệm notebook, nhưng: diff git sạch (không JSON), `import da` như script, không lưu output rác, không divergence macro (mọi thứ từ `da`).

### 3.2 Map nội dung 3 notebook → cells trong `explore.py`
3 `.ipynb` hiện chứa **explore tương tác** (phần audit lặp-lại đã thành script `.py` rồi). Phần còn cần giữ = tra cứu tương tác:

| Từ notebook | → Cell trong `mondelez/explore.py` |
|---|---|
| `tms_report_25_explore`: chi tiết 1 OrderCode / 1 MasterCode / 1 ngày / free query | `# %% TMS — tra cứu 1 đơn / 1 chuyến / 1 ngày` |
| `otif_mtd_audit`: tra cứu 1 SO | `# %% OTIF — tra cứu 1 SO` |
| `flash_daily_mtd_audit`: slot ad-hoc | `# %% Flash — ad-hoc` |

```python
# mondelez/notebooks/explore.py   (thay 3 .ipynb cùng thư mục)
# %% Setup (chạy 1 lần)
import da
cfg = da.load_tenant("mondelez"); client = da.ch_client(cfg)
da.setup_display()

# %% OTIF — tra cứu 1 SO   (sửa mã rồi Shift+Enter)
da.run_df(client, f"SELECT * FROM {cfg.table('mv_otif')} WHERE so = {{s:String}}",
          {"s": "8482509466"})
```

### 3.3 An toàn xóa (gate parity)
**KHÔNG xóa** 3 `.ipynb` cho tới khi `explore.py` cover đủ + user xác nhận. Trình tự: (1) tạo `explore.py` đủ cells → (2) user dùng thử 1 buổi → (3) xóa 3 `.ipynb` + `__pycache__` + cập nhật `notebooks/README.md` (hoặc bỏ thư mục `notebooks/`).

---

## 4. Cấu trúc sau khi xong

```
helix-projects/
├── da/da/report.py          # +save_html, +_md_to_html, +_HTML_CSS   (lõi: chỉ THÊM)
├── mondelez/
│   ├── scripts/             # ★ phân 4 nhóm MECE (xem scripts/README.md)
│   │   ├── etl/             #   download_tms_report.py · load_tms_report_to_ch.py
│   │   ├── analysis/        #   otif/flash/tms _audit.py · reconcile_tms_otif.py · run_all.py
│   │   ├── export/          #   uat_*_export.py (4)
│   │   └── meta/            #   export_clickhouse_ddl.py · fetch_sql_registry.py
│   ├── reports/             # *.md + *.html + index.html  (do analysis/ sinh)
│   └── notebooks/
│       ├── explore.py       # ★ MỚI — thay 3 .ipynb (# %% cells)
│       └── (3 .ipynb)       # ✗ XÓA sau gate parity 9.2
```

> **Định vị tenant relocation-proof:** sau khi phân nhóm, mọi script tự đi lên tìm thư mục chứa `da.toml` (tenant root) thay vì đếm `.parent.parent` (giòn theo độ sâu) → di chuyển/đổi cấu trúc thư mục không vỡ path.

---

## 5. Lộ trình (phân pha, có gate — nối tiếp plan cũ)

| Pha | Nội dung | Gate xác nhận |
|---|---|---|
| **8.0** ✅ | Chốt proposal này | User APPROVE doc (2026-05-29) |
| **8.1** ✅ **DONE** | `da/report.py`: `save_html` + `_md_to_html` (+ link) + `_HTML_CSS`. Không đụng `save_md`. | ✅ `import da` OK; test 12/12 pass (heading/code/bold/italic-edge `_rows_minus_so_`/blockquote/pipe-table/dataframe/RAG emoji); `save_md` giữ nguyên |
| **8.2** ✅ **DONE** | Tách `build()` + thêm `save_html` cho 4 script | ✅ 4 script exit 0 (OTIF 91.75% · Flash 105K row · TMS 27 ngày · reconcile 29 ngày); `.md` parity byte-identical (chỉ khác data-drift sống: lag phút + 1 ngày MV cập nhật) |
| **8.3** ✅ **DONE** | `scripts/run_all.py` → `reports/index.html` | ✅ `run_all.py` exit 0; index link đủ 4 report + freshness + cờ RAG; link `[xem](*.html)` render OK |
| **9.1** ✅ **DONE** | `mondelez/notebooks/explore.py` (cover 3 notebook: 1 đơn/1 chuyến/1 ngày/1 SO/Flash ad-hoc + free query) | ✅ 8 cell `# %%` chạy end-to-end không lỗi; bind tiếng Việt chuẩn |
| **9.2** ⏳ **CHỜ USER** | User dùng thử `notebooks/explore.py` → **xóa** 3 `.ipynb` (giữ explore.py + README) | ⏳ Chờ user xác nhận explore.py đủ dùng |
| **(sau)** | `save_pdf()` Edge-headless; nhân cho Panasonic (Phase 6 plan cũ) | theo nhu cầu |

**Nguyên tắc an toàn:** không xóa `.ipynb` trước 9.2; mỗi pha = 1 PR nhỏ qua `/da-ship`; `save_md` bất biến để `.md` cũ diff sạch.

---

## 6. Quyết định còn mở (cần user xác nhận khi triển khai)

1. **`index.html` đặt ở đâu** — `reports/index.html` (đề xuất) hay `reports/index-<date>.md`+html? Đề xuất ghi đè `index.html` mỗi lần (luôn trỏ bản mới nhất), report con vẫn có hậu tố ngày.
2. **RAG trong HTML** — giữ emoji 🟢🟡🔴 (đề xuất, đơn giản) hay badge màu CSS?
3. **Bỏ hẳn thư mục `notebooks/`** hay giữ thư mục rỗng + README trỏ sang `explore.py`? Đề xuất bỏ hẳn, ghi chú trong `explore.py`.
4. **`explore.py` 1 file đa-module** (đề xuất) hay tách `explore_otif.py`/`explore_tms.py`? 1 file + section `# %%` gọn cho tra cứu nhanh.

---

## 7. Không nằm trong phạm vi

- Viết lại lõi `da/` (anti-pattern — đã loại ở §0).
- Sửa SQL/MV engine → `/da-ch`. Định nghĩa lại metric → `/da-data`.
- PDF chính thức / phát hành stakeholder → `/da-ops-release` (đã có pipeline).
- Final gate trước commit → `/da-ship`.

---

## Tín hiệu kết thúc

- **ARTIFACT_PATH:** `mondelez/03-build/da-py-html-redesign-proposal.md` (proposal — chưa code)
- **DATA_CONFIDENCE:** N/A (đây là đề xuất kiến trúc, không phải phân tích số liệu)
- **MV_FRESHNESS:** N/A
- **GRAIN/TIMEZONE:** N/A ở tầng proposal (giữ nguyên grain/TZ của từng script hiện có)
- **NEXT_ACTION:** user review §5 + §6 → APPROVE → triển khai Phase 8.1 qua `/da-py`; chốt từng PR qua `/da-ship`
