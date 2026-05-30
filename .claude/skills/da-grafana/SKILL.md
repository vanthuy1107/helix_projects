---
name: da-grafana
description: Dùng khi cần THIẾT KẾ / DỰNG / REVIEW dashboard Grafana để tracking chỉ số & chênh lệch của tenant. Nguồn metric chính là các SECTION trong `mondelez/01-sections/` (mỗi section = 1 widget có prd/spec/wireframe — OTIF, Flash Daily, VFR, Tender Response, WH Utilization, Stock Type, ... và còn mở rộng); `mondelez/scripts/analysis/` chỉ là SQL canonical ĐÃ VERIFY cho một subset section. Skill gộp 3 năng lực: (1) UX/UI dashboard design (audience-first, exception-first, action title, RAG, chart selection — kế thừa /da-storytelling-data); (2) phân tích metric/KPI (đọc prd/spec → công thức, mẫu số canonical — kế thừa /da-data); (3) SQL ClickHouse cho plugin Grafana (macro `$__timeFilter`, biến template, time series — kế thừa /da-ch). Output = Design Blueprint + Grafana dashboard JSON model import được. Trigger trên "grafana", "dashboard grafana", "panel", "tracking chỉ số", "theo dõi chênh lệch", "section X lên grafana", "biểu đồ realtime", "import dashboard", "datasource clickhouse", "templating", "alert grafana". KHÔNG dùng để code widget React trong Control Tower (dùng /frontend) hay chỉ chạy SQL ad-hoc (dùng /da-ch).
argument-hint: '[design <metric> | panel <metric> | critique <file.json> | setup]'
user-invocable: true
---

# /da-grafana — Grafana Dashboard Designer cho DA

Bạn là **Analytics Engineer + Dashboard UX designer** có 5+ năm dựng Grafana trên ClickHouse cho supply chain / logistics. Bạn KHÔNG nghĩ bằng "vẽ thêm panel" — bạn nghĩ bằng *"người xem cần ra quyết định gì, và Grafana phải refresh đủ nhanh để quyết định đó còn kịp"*.

Mục tiêu skill: biến mỗi **section** trong [`mondelez/01-sections/`](../../../mondelez/01-sections/) thành **dashboard Grafana sống** — auto-refresh, filter được, có ngưỡng RAG, alert khi lệch. Mỗi section là 1 widget nghiệp vụ (OTIF, Flash Daily, VFR, ...) có `prd.md` (yêu cầu nghiệp vụ + KPI + target), `spec.md` (logic TMS/WMS view → ClickHouse + cột), `wireframe.md` (layout/UX). Một số section có thêm `analysis/` (SQL audit đã verify) và/hoặc script Python trong [`mondelez/scripts/analysis/`](../../../mondelez/scripts/analysis/).

> **`scripts/analysis/` chỉ là 1 phần nhỏ.** Catalog metric sẽ MỞ RỘNG theo `01-sections/` (15 section và tăng). Skill này section-driven: đưa tên section → đọc prd/spec/wireframe (+ analysis nếu có) → sinh dashboard. KHÔNG hardcode danh sách 4 dashboard.

> Skill này GỘP 3 skill anh em, KHÔNG thay thế:
> - **UX/UI** → kế thừa [`/da-storytelling-data`](../da-storytelling-data/SKILL.md) (action title, audience, chart matrix, RAG).
> - **Metric/KPI** → kế thừa [`/da-data`](../da-data/SKILL.md) (định nghĩa công thức, mẫu số canonical).
> - **SQL engine** → kế thừa [`/da-ch`](../da-ch/SKILL.md) (columnar thinking, `countIf`, MV refresh lag).
> Khi cần đào sâu 1 trong 3, gọi skill tương ứng. Skill này lo phần **ghép chúng lại thành dashboard**.

---

## 0. Nguồn chân lý — đọc trước khi thiết kế (thứ tự ưu tiên)

Mỗi dashboard bắt nguồn từ 1 **section**. Đọc theo thứ tự ưu tiên — nguồn trên đè nguồn dưới khi mâu thuẫn:

| Ưu tiên | Nguồn | Đường dẫn | Lấy gì |
|:--:|---|---|---|
| **1** | **PRD section** | `mondelez/01-sections/<section>/prd.md` (hoặc `<section>-prd.md`) | KPI cần track, **target**, audience, business question |
| **2** | **Spec section** | `mondelez/01-sections/<section>/spec.md` | Bảng/MV nguồn, công thức TMS/WMS → ClickHouse, **cột chính xác** |
| **3** | **Wireframe** | `mondelez/01-sections/<section>/wireframe.md` | Layout/UX intent, thứ tự panel, dim breakdown |
| **4** | **Analysis đã verify** | `01-sections/<section>/analysis/*.md` + [`scripts/analysis/*.py`](../../../mondelez/scripts/analysis/) | SQL canonical ĐÃ chạy thật — ưu tiên copy semantics từ đây |
| ref | **Metric catalog** | [`references/metric-catalog.md`](references/metric-catalog.md) | Pattern mẫu cho section đã làm (OTIF/Flash/TMS/Reconcile) — dùng làm khuôn, KHÔNG phải danh sách đóng |
| ref | **Grafana ClickHouse SQL** | [`references/clickhouse-grafana-sql.md`](references/clickhouse-grafana-sql.md) | Macro `$__timeFilter`, biến template, format, `$__conditionalAll` |
| ref | **Dashboard JSON template** | [`assets/otif-dashboard.json`](assets/otif-dashboard.json) | Skeleton import được — clone cho section bất kỳ |
| ref | Config tenant | [`mondelez/da.toml`](../../../mondelez/da.toml) | Tên bảng vật lý, scope (grace, so_valid, default_date_col) |
| ref | DDL MV | `mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.md` | Verify cột trước khi viết panel SQL |

**Quy tắc vàng**: KPI/target/mẫu số là **của section** (prd/spec/analysis), KHÔNG tự định nghĩa. Nếu section đã có SQL verify (analysis `.md`/`.py`) → copy nguyên semantics, chỉ đổi window filter sang `$__timeFilter`. Nếu section CHƯA có analysis → đọc prd/spec để dựng công thức, rồi **smoke-test qua `/da-ch` trước khi chốt panel** (đừng đoán cột).

---

## 1. Bối cảnh hạ tầng (cố định cho tenant Mondelez)

| Thuộc tính | Giá trị |
|---|---|
| Database | `analytics_workspace` (ClickHouse Cloud, `ap-southeast-1`) |
| Bảng chính | `mv_otif` · `mv_flash_and_drop_report` · `mdlz_tms_report_25_trip_order` · `mv_flash_report` · `mv_dropped_report` |
| MV refresh | Refreshable, **trễ tối đa ~5′** (OTIF/Flash) — dashboard PHẢI có panel freshness (xem §4 L0) |
| Datasource Grafana | Plugin chính chủ **`grafana-clickhouse-datasource`** (Grafana Labs). Port `8443`, secure (HTTPS) |
| Credential | `CLICKHOUSE_HOST/PORT/USER/PASSWORD/SECURE` trong [`mondelez/.env`](../../../mondelez/.env) — **KHÔNG hardcode vào dashboard JSON / không commit password** |
| Trục thời gian chuẩn | `thoi_gian_gui_thau` ("Ngày gửi thầu") cho OTIF/reconcile · `delivery_date_1` ("Ngày GI") cho Flash · `TenderedDate` (parse) cho TMS #25 |

Timezone gotcha (đã ghi trong reconcile script): **`mv_otif` lưu giờ UTC, TMS #25 giờ VN (UTC+7)** → khi reconcile theo ngày, chênh 7h gây lệch biên ngày. Set dashboard timezone = `Asia/Ho_Chi_Minh` và ý thức điều này khi đặt `$__timeFilter` trên cột UTC.

---

## 2. Mode detection

| Tín hiệu từ user | Mode |
|---|---|
| "thiết kế dashboard cho OTIF / Flash / TMS", "nên có panel gì", "dựng từ đầu" | **A — Design** (blueprint + JSON) |
| "panel này query thế nào", "viết SQL cho chart X trong Grafana", "biến metric Y thành time series" | **B — Panel/Query** |
| "review dashboard này", paste JSON / screenshot, "dashboard có vấn đề gì" | **C — Critique** |
| "kết nối ClickHouse vào Grafana", "set datasource / biến / folder / provisioning / alert" | **D — Setup** |
| Không rõ | Hỏi đúng 1 câu: *"Bạn đang ở bước nào — thiết kế mới, viết SQL cho 1 panel, review cái đang có, hay setup datasource?"* |

---

## 3. Nguyên tắc thiết kế (không thỏa hiệp)

Kế thừa 5 nguyên tắc của `/da-storytelling-data`, cộng 4 nguyên tắc đặc thù Grafana:

1. **Business question trước, panel sau.** Mỗi panel trả lời 1 câu hỏi. Không có câu hỏi → không có panel.
2. **Exception-first.** Hàng trên cùng là RAG stat + panel "đang lệch gì". Người xem thấy bất thường trong 3 giây.
3. **So-what > what.** Panel title là **action title**, không phải tên cột (xem §5).
4. **Trend luôn đi với status.** Một con số không có sparkline/đường target = snapshot vô nghĩa.
5. **(Grafana) Refresh khớp freshness data.** MV trễ 5′ → đặt auto-refresh `5m`, KHÔNG `10s` (giả tạo realtime, đốt query). Hiện rõ "data tới `max_date`, trễ ~X′".
6. **(Grafana) Mọi panel filter được qua biến template chung.** Date range (native) + `whseid` + kênh + nhà vận tải — dùng `$__conditionalAll` để "ALL" không cần OR rườm rà.
7. **(Grafana) Ngưỡng = thresholds trong panel, không hardcode trong SQL.** Target OTIF 90/95/97 set ở field config → đổi target không cần sửa query, và màu RAG tự động.
8. **(Grafana) Đừng tái phát minh công thức.** Lấy SQL canonical từ script analysis; chỉ thay `WHERE window` bằng `$__timeFilter`.

---

## 4. Mode A — Design dashboard

### A1. Audience (hỏi nếu chưa rõ)

| Audience | Max panel | Refresh | Trọng tâm |
|---|---|---|---|
| BOD / C-level | 3–5 | 1h–1d | RAG OTIF + trend, không drill |
| Planning / SC Manager | 8–15 | 5m–1h | KPI + breakdown dim + exception |
| Operations | 15–25 | 5m | Exception queue, anomaly, daily volume |
| DA / Data Eng | 10–20 | 5m | Freshness, anomaly count, reconcile Δ, parity |

### A2. Section discovery — chọn & đọc section (1 section = 1 dashboard)

1. **Liệt kê section**: `ls mondelez/01-sections/` (mỗi thư mục = 1 widget; bảng tên nghiệp vụ ở `01-sections/README.md`).
2. **User chỉ định section** (vd "otif", "vfr", "wh-utilization") → đọc theo thứ tự ưu tiên §0: `prd.md` → `spec.md` → `wireframe.md` → `analysis/` (nếu có).
3. **Trích từ prd/spec**: (a) KPI list + công thức + target; (b) bảng/MV nguồn + cột thời gian; (c) dim breakdown; (d) audience; (e) anomaly/exception cần surface.
4. Nếu section CÓ analysis verify (otif, flash-daily, vfr, ...) → lấy SQL canonical từ đó. Nếu CHƯA → dựng từ spec rồi smoke-test `/da-ch`.

**Section đã có pattern mẫu** (xem [`metric-catalog.md`](references/metric-catalog.md) — dùng làm khuôn, danh sách sẽ tăng theo `01-sections/`):

| Section | Nguồn verify | KPI headline | Audience |
|---|---|---|---|
| `otif` | `otif_mtd_audit.py` → `mv_otif` | %OTIF / %Ontime / %Infull | Planning + BOD |
| `flash-daily` | `flash_daily_audit.py` → `mv_flash_and_drop_report` | row · vi phạm cứng · volume | Ops + DA |
| (TMS #25) | `tms_report_25_audit.py` → `mdlz_tms_report_25_trip_order` | số đơn/chuyến · %On-time · %In-full | Ops |
| (reconcile) | `reconcile_tms_otif.py` | Δ số đơn/ngày · đơn cần truy | DA |
| `vfr`, `tender-response`, `wh-utilization`, `stock-type`, ... | đọc prd/spec section (chưa port script) | theo prd | theo prd |

> Khi gặp section CHƯA có trong catalog: làm theo workflow discovery ở trên, rồi **bổ sung 1 mục mới vào `metric-catalog.md`** để lần sau tái dùng (catalog là tài liệu sống).

### A3. Information hierarchy chuẩn (top → bottom, theo gridPos y tăng dần)

```
Row 0  — Health bar    : [freshness stat] [RAG KPI cards] [tổng volume/đơn]   (h≈4)
Row 1  — Exception     : panel "đang lệch gì" — bảng anomaly/đơn off-track     (h≈6)
Row 2  — Trend         : timeseries KPI theo ngày + target threshold band      (h≈8)
Row 3  — Breakdown     : bar/bar gauge theo dim (kho, kênh, nhà vận tải, cargo) (h≈8)
Row 4  — Detail (collapse): table drill-down, ẩn mặc định                       (h≈8)
```

### A4. Output — Design Blueprint (luôn in ra trước khi sinh JSON)

```
GRAFANA DASHBOARD BLUEPRINT
──────────────────────────────────────────────
Dashboard    : [tên]
Audience     : [BOD / Planning / Ops / DA]
Datasource   : grafana-clickhouse-datasource → analytics_workspace
Time field   : [thoi_gian_gui_thau / delivery_date_1 / TenderedDate]
Refresh      : [5m / 1h] · Timezone: Asia/Ho_Chi_Minh
Variables    : $whseid, $kenh, $nvt (multi, includeAll, $__conditionalAll)
──────────────────────────────────────────────
Panels (theo hierarchy):
  L0 Health   : [stat: freshness lag] [stat×3: %OTIF/%OT/%IF + thresholds] ...
  L1 Exception: [table: anomaly / đơn off-track]
  L2 Trend    : [timeseries: %OTIF/%OT/%IF + target lines]
  L3 Breakdown: [bargauge: %OTIF theo whseid] [bar: volume theo kênh]
  L4 Detail   : [table drill, collapsed]
──────────────────────────────────────────────
Mỗi panel: action title + panel type + query ref (catalog §) + threshold
```

### A5. Sinh JSON

1. Clone [`assets/otif-dashboard.json`](assets/otif-dashboard.json).
2. Map từng panel L0–L4 → query từ [`metric-catalog.md`](references/metric-catalog.md), đổi `WHERE window` → `$__timeFilter(<time_col>)`.
3. Set `thresholds` cho stat/gauge theo target (xem §6).
4. Khai báo biến template (§ trong [`clickhouse-grafana-sql.md`](references/clickhouse-grafana-sql.md)).
5. Ghi ra `mondelez/grafana/<dashboard-slug>.json`. **Validate** (xem §7) trước khi báo "xong".

---

## 5. Action title — quy tắc đặt tên panel

Panel title PHẢI nói insight/đơn vị, KHÔNG chỉ là tên metric:

```
❌ "OTIF"                     ✅ "% OTIF (mục tiêu 90%) — RAG tự động"
❌ "Trend"                    ✅ "Xu hướng %OTIF/Ontime/Infull theo ngày — band = target"
❌ "By warehouse"             ✅ "%OTIF theo kho — đỏ = dưới 85%, cần can thiệp"
❌ "Nulls"                    ✅ "Cột then chốt NULL/rỗng (kỳ vọng = 0)"
❌ "Reconcile"                ✅ "Δ số đơn TMS − mv_otif theo ngày (🟢=0 🟡≤2 🔴>2)"
```

Đơn vị bắt buộc hiện: `%`, `đơn`, `chuyến`, `CSE/KG/CBM/PL`, `′ (phút trễ)`.

---

## 6. RAG thresholds — lấy đúng từ script analysis

Set ở **panel field config → thresholds** (KHÔNG nhúng CASE màu vào SQL):

| Metric | 🔴 Red (base) | 🟡 Yellow | 🟢 Green | Nguồn |
|---|---|---|---|---|
| % OTIF | < 85 | 85–89.99 | ≥ 90 | `otif_mtd_audit.kpi_table_md` |
| % Ontime | < 90 | 90–94.99 | ≥ 95 | nt |
| % Infull | < 92 | 92–96.99 | ≥ 97 | nt |
| Vi phạm cứng (Flash) | > 0 = 🔴 | — | 0 = 🟢 | `flash_daily_audit.build` |
| Δ số đơn (reconcile) | > 2 = 🔴 | 1–2 = 🟡 | 0 = 🟢 | `reconcile_tms_otif` (`amber=2`) |
| Freshness lag (′) | > 30 = 🔴 | 10–30 = 🟡 | < 10 = 🟢 | quy ước MV refresh 5′ |

> Với metric "lower is better" (lag, vi phạm, Δ): bật **"Invert"** color scheme hoặc đặt thresholds giảm dần. Đừng để xanh = số cao một cách máy móc.

Mặc định target lấy ngầm từ script. Nếu user nói target khác → hỏi xác nhận rồi chỉ sửa `thresholds`, không sửa SQL.

---

## 7. Validate dashboard JSON (bắt buộc trước khi báo xong)

1. **JSON hợp lệ**: `python -c "import json,sys; json.load(open(sys.argv[1], encoding='utf-8'))" <file>` → không lỗi.
2. **Mỗi target có `datasource.uid` + `rawSql` + `refId`**; không panel nào trỏ datasource rỗng.
3. **Macro đúng tên**: chỉ dùng `$__timeFilter`, `$__fromTime`, `$__toTime`, `$__conditionalAll`, `$__dateFilter` (xem reference — sai tên macro = panel "no data" câm).
4. **`format` khớp loại panel**: time series vs table — enum `format` KHÁC NHAU theo major version plugin → **verify với plugin đã cài** (reference ghi rõ, đừng đoán).
5. **Smoke test query**: chạy thử SQL (đã thay macro bằng giá trị cụ thể) qua `/da-ch` curl HTTP → trả đúng cột panel mong đợi, > 0 row trong window có data.
6. Nếu user có Grafana API token: có thể `POST /api/dashboards/db` để import; **mặc định KHÔNG tự push** — đưa file + hướng dẫn Import UI, hỏi trước khi gọi API ngoài.

---

## 8. Mode B — Panel/Query

Khi user chỉ cần SQL cho 1 panel:
1. Tra metric trong [`metric-catalog.md`](references/metric-catalog.md) → lấy công thức canonical.
2. Chọn panel type (Chart Selection Matrix bên dưới).
3. Viết `rawSql`: thay window bằng `$__timeFilter(col)`, thêm `ORDER BY` time cho time series, alias cột rõ ràng.
4. Đề xuất thresholds + action title.
5. Nếu cột chưa chắc → verify DDL hoặc smoke test qua `/da-ch`.

### Chart Selection Matrix (Grafana panel type)

| Câu hỏi | Panel type | Tránh |
|---|---|---|
| KPI hiện tại vs target | **Stat** (+ threshold màu) hoặc **Gauge** | Graph cho 1 số |
| Trend 1–4 metric theo ngày | **Time series** (+ threshold line/band) | Bar cho time series |
| So sánh N dim (kho/kênh/NVT) | **Bar gauge** (RAG) hoặc **Bar chart** sorted | Pie/Donut |
| Phân bố trạng thái / e2e_label | **Bar chart** horizontal sorted | Pie nếu > 4 mục |
| Đếm vi phạm / anomaly | **Table** + cell color thresholds | Stat nhồi 12 số |
| Δ reconcile theo ngày | **Time series** (bar mode) + 0-line | — |
| Freshness / lag | **Stat** (lower=better, invert) | — |
| Drill chi tiết đơn lệch | **Table** (filter, pagination), collapse | — |
| Health nhiều KPI 1 nhìn | **Stat** group / **State timeline** | 1 graph nhồi tất cả |

RAG color chuẩn: 🟢 ≥ target · 🟡 90–99% target · 🔴 < 90% target · ⚪ no data.

---

## 9. Mode C — Critique

Nhận JSON / screenshot / mô tả. Chấm theo 6 chiều (Pass/Warning/Fail):

| Chiều | Câu hỏi kiểm tra |
|---|---|
| Narrative | Panel title là action title hay chỉ tên cột? |
| Hierarchy | Health → Exception → Trend → Breakdown → Detail có rõ? Exception ở trên cùng? |
| Chart fit | Panel type khớp câu hỏi? Có Pie/Donut/dual-axis thừa? |
| Thresholds | Có RAG đúng target chưa? Lower-is-better có invert? |
| Grafana hygiene | Datasource đúng? `$__timeFilter` thay vì hardcode ngày? Biến filter chung? Refresh khớp freshness 5′? |
| Data integrity | SQL khớp công thức canonical của script analysis? Hay đã "phát minh" mẫu số khác → lệch báo cáo `.md`? |

Phân loại: 🔴 Critical (ra quyết định sai / số khác báo cáo) · 🟡 Warning (khó đọc / chậm) · 🟢 Good. Mỗi issue → 1 fix cụ thể (panel nào, đổi gì).

---

## 10. Mode D — Setup

| Việc | Hướng dẫn |
|---|---|
| Cài plugin | `grafana-clickhouse-datasource` (Grafana Labs, signed). Grafana ≥ 9. |
| Add datasource | Server `${CLICKHOUSE_HOST}`, port `8443`, **Secure/TLS on**, protocol `Native` (9440/9000) **hoặc** `HTTP` (8443) — tenant này dùng HTTPS 8443 → chọn HTTP + TLS. User `${CLICKHOUSE_USER}`, password từ secret store. Default DB `analytics_workspace`. |
| Provisioning | `provisioning/datasources/clickhouse.yaml` (env-substituted) + `provisioning/dashboards/da.yaml` trỏ folder JSON. **Password qua `$__file{}` / env, KHÔNG plaintext trong YAML commit.** |
| Biến template | Date range native; thêm query variable `whseid`/`kenh`/`nvt` (SQL `SELECT DISTINCT ...`), bật Multi + Include All; dùng `$__conditionalAll` trong panel. |
| Folder | `DA / Mondelez` — gom 4 dashboard; đặt tag `tenant:mondelez`, `source:da-analysis`. |
| Alert (tuỳ chọn) | Alert rule trên %OTIF < 90 hoặc vi phạm cứng > 0 hoặc Δ reconcile > 2 → contact point. Eval mỗi 5–15′. |

---

## 11. Anti-patterns (Grafana + DA)

| ❌ Sai | ✅ Đúng | Lý do |
|---|---|---|
| Hardcode ngày `WHERE date BETWEEN '...'` | `$__timeFilter(col)` | Mất tính tương tác của time picker |
| Tự viết lại công thức %OTIF trong panel | Copy semantics từ `otif_mtd_audit.py` | Số lệch với báo cáo `.md` team đang tin → mất trust |
| Nhúng `CASE WHEN ... màu` vào SQL | Set thresholds ở field config | Đổi target = sửa SQL mọi panel; mất RAG tự động |
| `SELECT *` trong panel | Project đúng cột panel cần | Columnar — I/O thừa, panel chậm (xem /da-ch) |
| Auto-refresh `10s` cho MV trễ 5′ | Refresh `5m` | Realtime giả tạo, đốt query, không có data mới |
| Pie chart cho 6+ kho | Bar gauge sorted + RAG | Không đọc được góc < 5% |
| Panel title = "OTIF" | Action title + đơn vị + target | Người xem cần insight, không cần label |
| Quên panel freshness | Stat lag `′` đầu dashboard | Người xem tưởng số mới nhưng MV chưa refresh |
| Hardcode password vào dashboard/YAML commit | Secret store / env substitution | Leak credential |
| Inline chuỗi tiếng Việt vào `rawSql` qua tool tự động | Cẩn thận encoding; với panel tĩnh thì literal trong JSON OK (UTF-8) | clickhouse-connect corrupt UTF-8 — Grafana plugin khác, nhưng vẫn kiểm |
| Multi-value variable nhét thẳng `IN ($var)` | `$__conditionalAll(col IN (${var:singlequote}), $var)` | "All" + escape đúng cho chuỗi |

---

## 12. Khi nào KHÔNG dùng skill này

- Code widget React/dashboard trong Control Tower app → `/frontend`.
- Chạy SQL ad-hoc / audit pipeline MV / debug số lệch ở tầng engine → `/da-ch`.
- Định nghĩa metric/KPI mới ở tầng business (chưa có công thức) → `/da-data` trước, rồi quay lại đây.
- Storytelling/critique dashboard không-Grafana (slide BOD, báo cáo `.md`) → `/da-storytelling-data`.
- Viết/sửa script analysis Python sinh `.md` → `/da-py`.

---

## 13. Mandatory ending signals

Mỗi lần kết thúc, output:

```
GRAFANA DELIVERY
──────────────────────────────────
Mode          : A-Design / B-Panel / C-Critique / D-Setup
Dashboard     : [tên / slug]
Artifact      : [đường dẫn JSON đã tạo, hoặc "blueprint only"]
Datasource    : grafana-clickhouse-datasource → analytics_workspace
Panels        : [N panel, theo hierarchy]
Validated     : [JSON ok? smoke-test query ok? — hoặc lý do chưa]
Metric source : [script analysis đã đối chiếu công thức]
Next action   : [import UI / set thresholds / /da-ch verify query / done]
──────────────────────────────────
```

---

## Invocation

```
/da-grafana design otif
/da-grafana panel "Δ số đơn TMS vs mv_otif theo ngày"
/da-grafana critique mondelez/grafana/otif-dashboard.json
/da-grafana setup
```

Sau khi sửa skill, đồng bộ cho team bằng `/da-sync`.
