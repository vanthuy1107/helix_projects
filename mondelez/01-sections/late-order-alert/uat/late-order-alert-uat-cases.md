# UAT Test Cases — Late Order Alert (Mondelez)

| Trường | Giá trị |
|---|---|
| **Plan reference** | [late-order-alert-uat-plan.md](late-order-alert-uat-plan.md) |
| **Tổng số case** | 28 (22 happy + 6 edge) |
| **Ngày tạo** | 2026-05-27 |
| **Tác giả** | PM/DA via `/da-uat` |

---

## Cách đọc

- **Layer storytelling**: L1 KPI cards → L2 Donut → L3 Transporter bar → L4 Detail table
- **Lớp test**: A=Data reconciliation · B=Business logic · C=UX storytelling · D=Filter/Performance
- **Severity** nếu Fail: Critical · Major · Minor · Cosmetic
- **P/F + Note** cột để khách hoặc PM fill trong session (Mode C)

---

## A. Lớp Data Reconciliation (8 TC)

> Đối chiếu 3 nguồn: Dashboard CT — SQL raw `mv_alert_late_do` — Golden file MDLZ Excel daily tracker. Tolerance per plan §4.

### TC-A01 — Tổng chuyến (L1 KPI lớn) khớp 3 nguồn

| Field | Giá trị |
|---|---|
| **Lớp** | A |
| **Layer** | L1 KPI lớn `Tổng chuyến` (w-44 large variant) |
| **Tiền điều kiện** | Filter: all=ALL, dateType=`'ETA gửi thầu (đơn)'`, dateRange=hôm nay |
| **Steps** | 1. Mở Late Order Alert widget<br>2. Đọc giá trị thẻ `Tổng chuyến` (lớn nhất bên trái)<br>3. Cross-check SQL raw scorecard từ Excel sheet 01<br>4. Cross-check golden file MDLZ — đếm distinct `Số chuyến` |
| **Expected** | Dashboard = SQL raw = Golden file (tolerance ±1 chuyến hoặc ±1%) |
| **Severity nếu Fail** | Critical (root metric tổng) |
| **P/F** | _____ |
| **Note** | _____ |

### TC-A02 — 7 KPI count phân loại khớp scorecard query

| Field | Giá trị |
|---|---|
| **Lớp** | A |
| **Layer** | L1 7 thẻ status (Normal/At risk/Late departure open/Late departure/Ontime departure/Ontime delivery/Late delivery) |
| **Tiền điều kiện** | Cùng filter TC-A01 |
| **Steps** | 1. Đọc 7 thẻ count<br>2. Cross-check với SQL `scorecard` output (Excel sheet 01)<br>3. Sum 7 status = giá trị `Tổng chuyến` TC-A01 |
| **Expected** | Mỗi count khớp SQL raw (tolerance ±1 chuyến). Sum 7 = Tổng (KHÔNG được lệch). |
| **Severity nếu Fail** | Critical |
| **P/F** | _____ |
| **Note** | _____ |

### TC-A03 — dateType `'ETA gửi thầu (đơn)'` không silent 0 (regression A1)

| Field | Giá trị |
|---|---|
| **Lớp** | A |
| **Layer** | Filter dateType → L1 KPI cards |
| **Tiền điều kiện** | Filter dateType chọn `'ETA gửi thầu (đơn)'` (suffix `(đơn)`) |
| **Steps** | 1. Đổi filter `dateType` từ `'Ngày gửi thầu'` sang `'ETA gửi thầu (đơn)'`<br>2. Đọc `Tổng chuyến`<br>3. Cross-check SQL raw với cùng `date_type` value |
| **Expected** | `Tổng chuyến` > 0 (không silent về 0). Số khớp SQL raw branch `eta_giao_hang_cho_npp`. |
| **Severity nếu Fail** | Critical — A1 regression |
| **P/F** | _____ |
| **Note** | Verify 4-way coherent: MV ↔ runtime widget.config ↔ registry ↔ FE `DATE_TYPE_FALLBACK[1]` |

### TC-A04 — Donut chart 7 segment count khớp scorecard

| Field | Giá trị |
|---|---|
| **Lớp** | A |
| **Layer** | L2 Donut chart |
| **Tiền điều kiện** | Cùng filter TC-A01 |
| **Steps** | 1. Hover từng segment donut → đọc count<br>2. Cross-check với KPI cards L1 (cùng số)<br>3. Legend bên phải hiển thị đủ 7 entries |
| **Expected** | Donut segment count = KPI card count (lossless). 7 segment theo `BREAKDOWN_STATUS_ORDER` (Normal → At risk → Late departure open → Late departure → Ontime departure → Ontime delivery → Late delivery) |
| **Severity nếu Fail** | Major |
| **P/F** | _____ |
| **Note** | _____ |

### TC-A05 — Donut share % khớp tỷ lệ tự tính

| Field | Giá trị |
|---|---|
| **Lớp** | A |
| **Layer** | L2 Donut chart |
| **Tiền điều kiện** | Cùng filter TC-A01 |
| **Steps** | 1. Đọc % share segment Late departure open<br>2. Tự tính: `count_late_dep_open / tat_ca × 100`<br>3. So sánh tolerance ≤0.5pp |
| **Expected** | Share % hiển thị khớp tính tay (±0.5pp do rounding) |
| **Severity nếu Fail** | Minor |
| **P/F** | _____ |
| **Note** | _____ |

### TC-A06 — Transporter bar chart total khớp detail

| Field | Giá trị |
|---|---|
| **Lớp** | A |
| **Layer** | L3 Stacked Bar chart theo NVT |
| **Tiền điều kiện** | Cùng filter TC-A01 |
| **Steps** | 1. Đọc top 5 NVT trên Bar chart<br>2. Cross-check với SQL `groupedTable` query (Excel sheet 02)<br>3. Sum stack của 1 bar = total trip cho NVT đó |
| **Expected** | 5/5 NVT match (thứ tự có thể lệch 1 bậc do tie). Sum stack mỗi bar = total trip NVT đó (lossless). |
| **Severity nếu Fail** | Major |
| **P/F** | _____ |
| **Note** | _____ |

### TC-A07 — Detail table trip count = scorecard `tat_ca` (sau aggregate)

| Field | Giá trị |
|---|---|
| **Lớp** | A |
| **Layer** | L4 Detail table |
| **Tiền điều kiện** | Cùng filter TC-A01 |
| **Steps** | 1. Mở tab `Chi tiết bảng`<br>2. Đọc footer count grid (T trips)<br>3. Cross-check T = `tat_ca` scorecard TC-A01 |
| **Expected** | T trip rows trong detail = `tat_ca` (lossless). Nếu T < tat_ca → trip-level aggregation drop rows (bug). Nếu T > tat_ca → DO-level chưa aggregate (bug). |
| **Severity nếu Fail** | Critical |
| **P/F** | _____ |
| **Note** | Trip count grid là source-of-truth — nếu lệch là dấu hiệu §5.3 PRD aggregation rule sai |

### TC-A08 — Top 5 chuyến trễ trên detail table khớp golden file

| Field | Giá trị |
|---|---|
| **Lớp** | A |
| **Layer** | L4 Detail table |
| **Tiền điều kiện** | Sort theo alert priority asc (mặc định) |
| **Steps** | 1. Đọc top 5 trip đầu (Late departure open priority 0)<br>2. Cross-check 5 `so_chuyen` với golden file MDLZ cột `Số chuyến` lọc theo trạng thái khách phân loại tương đương<br>3. So sánh kho + NVT + ETA |
| **Expected** | ≥ 4/5 trip match. Kho + NVT + ETA = golden file cho mỗi trip match. |
| **Severity nếu Fail** | Major |
| **P/F** | _____ |
| **Note** | Nếu khách phân loại "Late departure" khác → file defect Lớp B chứ không phải A |

---

## B. Lớp Business Logic (7 TC)

> Verify 7 status formula + trip aggregation rules đúng nghiệp vụ Ops MDLZ. Test trên CASE SPECIFIC trip rows (chuẩn bị từ SQL raw trong dry-run).

### TC-B01 — Status `Normal` formula đúng

| Field | Giá trị |
|---|---|
| **Lớp** | B |
| **Layer** | L1 KPI thẻ Normal |
| **Tiền điều kiện** | Chuẩn bị 3 sample trip từ SQL raw: `Giờ ra cổng IS NULL` AND `now() < TG_bat_buoc - 45m` |
| **Steps** | 1. Tìm 1 sample trip trong detail table<br>2. Verify nó hiển thị alert chip `Normal` màu emerald `#22c55e`<br>3. Hover tooltip — read i18n hint `hintNormal` |
| **Expected** | Status = Normal cho trip thoả công thức. Tooltip mô tả "chưa ra cổng + còn xa deadline" |
| **Severity nếu Fail** | Major |
| **P/F** | _____ |
| **Note** | _____ |

### TC-B02 — Status `At risk` 45-min window đúng (OQ-01)

| Field | Giá trị |
|---|---|
| **Lớp** | B |
| **Layer** | L1 KPI thẻ At risk + L4 badge `Mới nguy cơ trễ` |
| **Tiền điều kiện** | Sample trip với `Giờ ra cổng IS NULL` AND `now() - TG_bat_buoc IN (-45m, 0m)` |
| **Steps** | 1. Tìm sample trip<br>2. Verify alert chip = At risk màu amber `#f59e0b`<br>3. Verify badge `Mới nguy cơ trễ` xuất hiện cạnh trip code<br>4. Hỏi Ops Mondelez: 45 phút có đúng standard không (OQ-01) |
| **Expected** | Status hiển thị At risk. Khách confirm cửa sổ 45 phút phù hợp. Nếu khác → file defect A3 Severity Major (cần config-driven hoặc đổi threshold). |
| **Severity nếu Fail** | Major (threshold) hoặc Critical (logic sai 1-sided) |
| **P/F** | _____ |
| **Note** | _____ |

### TC-B03 — Status `Late departure open` (đã trễ chưa rời kho) đúng

| Field | Giá trị |
|---|---|
| **Lớp** | B |
| **Layer** | L1 KPI thẻ Late departure open priority 0 + L4 badge `Mới trễ` |
| **Tiền điều kiện** | Sample trip với `Giờ ra cổng IS NULL` AND `now() > TG_bat_buoc` |
| **Steps** | 1. Tìm sample trip<br>2. Verify alert chip = Late departure open màu red `#ef4444`<br>3. Verify trip xuất hiện đầu detail table (priority 0 = sort top)<br>4. Verify badge `Mới trễ` rose |
| **Expected** | Đúng status, badge, priority đẩy lên đầu sort |
| **Severity nếu Fail** | Critical (đây là alert quan trọng nhất Ops phải thấy ngay) |
| **P/F** | _____ |
| **Note** | _____ |

### TC-B04 — Status `Late departure` vs `Ontime departure` (đã rời kho, chưa hoàn tất giao)

| Field | Giá trị |
|---|---|
| **Lớp** | B |
| **Layer** | L1 KPI 2 thẻ trong nhóm "Chuyến trên đường giao" |
| **Tiền điều kiện** | 2 sample trip:<br>• Trip X: `Giờ ra cổng IS NOT NULL` AND `ATA rời IS NULL` AND `Giờ ra cổng < TG_bat_buoc` → Ontime departure<br>• Trip Y: cùng cond, AND `Giờ ra cổng >= TG_bat_buoc` → Late departure |
| **Steps** | 1. Tìm 2 sample trip<br>2. Verify trip X = Ontime departure (sky `#38bdf8`)<br>3. Verify trip Y = Late departure (pink `#fb7185`) |
| **Expected** | Cả 2 đúng status. Threshold đúng = `TG_bat_buoc` (không phải `TG_bat_buoc - 45m`) |
| **Severity nếu Fail** | Major |
| **P/F** | _____ |
| **Note** | _____ |

### TC-B05 — Status `Ontime delivery` vs `Late delivery` (đã hoàn tất giao)

| Field | Giá trị |
|---|---|
| **Lớp** | B |
| **Layer** | L1 KPI 2 thẻ trong nhóm "Chuyến đã giao" |
| **Tiền điều kiện** | 2 sample trip:<br>• Trip P: `ATA rời IS NOT NULL` AND `ATA rời <= ETA` → Ontime delivery<br>• Trip Q: `ATA rời IS NOT NULL` AND `ATA rời > ETA` → Late delivery |
| **Steps** | 1. Tìm 2 sample trip<br>2. Verify trip P = Ontime delivery (emerald-dark `#10b981`)<br>3. Verify trip Q = Late delivery (rose `#f43f5e`)<br>4. Confirm với khách: ETA dùng đây là ETA của DO sớm nhất trong trip (`earliestEtaRow`) |
| **Expected** | Cả 2 đúng. Khách confirm ETA used = earliestEta. |
| **Severity nếu Fail** | Critical (output metric cuối) |
| **P/F** | _____ |
| **Note** | Khả năng khách định nghĩa Late delivery khác (vd theo `phut_tre_giao_npp > X`) — nếu khác = file defect → `/ba` revise §3.2 |

### TC-B06 — Trip aggregation priority rule — multi-DO trip

| Field | Giá trị |
|---|---|
| **Lớp** | B |
| **Layer** | L4 Detail table — trip với ≥2 DO khác alert |
| **Tiền điều kiện** | Sample trip Z có 2 DO:<br>• DO-1: alert = Ontime delivery (priority 6)<br>• DO-2: alert = Late departure open (priority 0) |
| **Steps** | 1. Tìm trip Z trong detail<br>2. Verify trip row hiển thị alert = Late departure open (priority cao nhất = 0)<br>3. Verify `mandatoryDepartAt`, `warehouse`, `deliveryArea`, `transporter`, `atdActual` = của DO-2 (alertPriorityRow)<br>4. Verify `eta` = của DO-1 (earliestEtaRow — DO có ETA sớm nhất, có thể ≠ DO-2) |
| **Expected** | Trip row aggregate đúng §5.3 PRD: alert + 5 field từ alertPriorityRow; ETA + doCode từ earliestEtaRow; salesChannel từ nppPriorityRow |
| **Severity nếu Fail** | Major |
| **P/F** | _____ |
| **Note** | _____ |

### TC-B07 — Warehouse standardize đúng (BKD/NKD/VN821/VN831)

| Field | Giá trị |
|---|---|
| **Lớp** | B |
| **Layer** | L4 Detail cột `warehouse` + L3 Bar chart group key |
| **Tiền điều kiện** | Sample trip với raw `whseid` = "bkd-1", "BinhDuong1", "BKD 1", "NKD" |
| **Steps** | 1. Đếm trip theo `warehouse` trong detail table<br>2. Verify mọi variant của BKD1 → hiển thị "BKD1"<br>3. Cross-check tổng trip BKD1 trong dashboard = SQL raw `COUNT(DISTINCT so_chuyen) WHERE whseid LIKE 'BKD%1'` |
| **Expected** | 100% standardize đúng 6 codes (BKD1/2/3, NKD, VN821, VN831). Trip count theo kho khớp SQL raw. |
| **Severity nếu Fail** | Major |
| **P/F** | _____ |
| **Note** | Nếu MDLZ có kho mới (vd VN841) — note trong defect A4 follow-up |

---

## C. Lớp UX & Storytelling (6 TC)

> Ops Manager đọc dashboard từ L1 → L4 trong < 30s và ra quyết định "trip nào cần can thiệp ngay". Đo bằng câu hỏi mental model.

### TC-C01 — Mental model Q1 (< 5s) — "Hôm nay có bao nhiêu chuyến cảnh báo?"

| Field | Giá trị |
|---|---|
| **Lớp** | C |
| **Layer** | L1 KPI lớn `Tổng chuyến` |
| **Tiền điều kiện** | Filter default — first impression |
| **Steps** | 1. Hỏi Ops Manager: "Trong < 5s mở dashboard, anh thấy có bao nhiêu chuyến cảnh báo?"<br>2. Quan sát anh có nhìn thẳng vào KPI lớn không<br>3. Verify anh đọc đúng con số |
| **Expected** | Ops Manager đọc đúng `Tổng chuyến` trong < 5s. Nếu eye-track lệch sang chart trước → drift |
| **Severity nếu Fail** | Minor (UX, không phải bug) |
| **P/F** | _____ |
| **Note** | _____ |

### TC-C02 — Mental model Q2 (< 15s) — "Bao nhiêu chuyến đã trễ chưa rời kho, cần can thiệp ngay?"

| Field | Giá trị |
|---|---|
| **Lớp** | C |
| **Layer** | L1 nhóm "Chuyến trong kho" → thẻ "Late departure open" |
| **Tiền điều kiện** | Filter default |
| **Steps** | 1. Hỏi Ops Manager: "Bao nhiêu chuyến đang trễ chưa rời kho?"<br>2. Quan sát có nhìn vào 3 thẻ nhóm "Chuyến trong kho" không<br>3. Anh có đọc đúng count "Late departure open" không |
| **Expected** | Ops Manager đọc đúng count trong < 15s, mental model: "đỏ + chưa ra cổng = cần can thiệp" |
| **Severity nếu Fail** | Major (đây là use case chính của widget) |
| **P/F** | _____ |
| **Note** | Nếu khách confused giữa "Late departure" và "Late departure open" → label cần rephrase |

### TC-C03 — 3 nhóm display group có rõ ý nghĩa vận hành

| Field | Giá trị |
|---|---|
| **Lớp** | C |
| **Layer** | L1 — 3 nhóm i18n labels |
| **Tiền điều kiện** | Default view |
| **Steps** | 1. Hỏi Ops Manager: "3 nhóm `Chuyến trong kho` / `Chuyến trên đường giao` / `Chuyến đã giao` có rõ giai đoạn vận hành không?"<br>2. Verify khách hiểu đúng nhóm 1 = chưa có ATD; nhóm 2 = có ATD chưa có ATA rời; nhóm 3 = có ATA rời |
| **Expected** | Khách confirm 3 nhóm rõ ràng theo giai đoạn vận hành |
| **Severity nếu Fail** | Minor |
| **P/F** | _____ |
| **Note** | _____ |

### TC-C04 — Donut chart bổ trợ KPI cards, không trùng lặp gây nhiễu

| Field | Giá trị |
|---|---|
| **Lớp** | C |
| **Layer** | L1 KPI + L2 Donut |
| **Tiền điều kiện** | Default view |
| **Steps** | 1. Hỏi Ops Manager: "Donut chart 7 segment có thêm thông tin gì so với 7 KPI cards không?"<br>2. Verify khách thấy giá trị: trực quan share % thay vì count tuyệt đối |
| **Expected** | Khách thấy donut bổ trợ KPI (share %), không cảm thấy thừa hoặc lặp |
| **Severity nếu Fail** | Cosmetic |
| **P/F** | _____ |
| **Note** | Nếu khách thấy thừa — có thể đề xuất ẩn donut trong v1.1 |

### TC-C05 — Transporter bar chart actionable cho Coordinator

| Field | Giá trị |
|---|---|
| **Lớp** | C |
| **Layer** | L3 Stacked Bar chart |
| **Tiền điều kiện** | Default view |
| **Steps** | 1. Hỏi Transporter Coordinator (nếu có): "Bar chart này giúp anh hold-accountable NVT nào không?"<br>2. Quan sát anh có pick được top NVT có nhiều chuyến trễ (Late delivery + Late departure cao) không |
| **Expected** | Coordinator pick được top 1-3 NVT cần escalate trong < 10s |
| **Severity nếu Fail** | Major (mất giá trị widget cho persona Coordinator) |
| **P/F** | _____ |
| **Note** | _____ |

### TC-C06 — Detail table priority sort đẩy critical lên đầu

| Field | Giá trị |
|---|---|
| **Lớp** | C |
| **Layer** | L4 Detail table — mặc định sort |
| **Tiền điều kiện** | Click tab `Chi tiết bảng` lần đầu |
| **Steps** | 1. Hỏi Ops Manager: "5 trip đầu bảng là gì? Có phải critical nhất không?"<br>2. Verify 5 trip đầu = Late departure open (priority 0)<br>3. Verify khách reflexively pick những trip đầu để escalate |
| **Expected** | 5 trip đầu = priority 0 (Late departure open). Ops Manager confirm "đây là những trip tôi cần xử lý đầu tiên" |
| **Severity nếu Fail** | Major |
| **P/F** | _____ |
| **Note** | Nếu khách prefer sort khác (vd theo TG bắt buộc rời kho ASC) — note vào defect Lớp B revision spec |

---

## D. Lớp Filter / Performance (5 TC)

### TC-D01 — `dateType` filter switch hoạt động không silent 0

| Field | Giá trị |
|---|---|
| **Lớp** | D |
| **Layer** | Filter bar |
| **Tiền điều kiện** | Khởi đầu với `dateType = 'Ngày gửi thầu'` |
| **Steps** | 1. Đọc Tổng chuyến<br>2. Đổi sang `'ETA gửi thầu (đơn)'`<br>3. Đọc Tổng chuyến (có thể khác do CASE branch khác column)<br>4. Cả 2 phải > 0 (không silent về 0)<br>5. Cross-check với SQL raw cùng filter |
| **Expected** | 2 giá trị đều > 0, khớp SQL raw branch tương ứng. Regression check A1. |
| **Severity nếu Fail** | Critical (A1 regression) |
| **P/F** | _____ |
| **Note** | Per spec §2.1 PM canonical 2026-05-21 — phải có suffix `(đơn)` |

### TC-D02 — Multi-select filter `whseid` + `transporter` combo

| Field | Giá trị |
|---|---|
| **Lớp** | D |
| **Layer** | Filter bar |
| **Tiền điều kiện** | ALL filter |
| **Steps** | 1. Chọn `whseid = ['BKD1', 'NKD']` (2 kho)<br>2. Chọn thêm `transporter = ['ANH SON', 'HOA PHAT']` (2 NVT)<br>3. Verify Tổng chuyến giảm xuống<br>4. Cross-check với golden file MDLZ filter tương ứng |
| **Expected** | Filter combo apply đúng (AND giữa 2 filter). Số khớp SQL raw + golden file (tolerance ±1 chuyến). |
| **Severity nếu Fail** | Major |
| **P/F** | _____ |
| **Note** | _____ |

### TC-D03 — Date range 2-year guard

| Field | Giá trị |
|---|---|
| **Lớp** | D |
| **Layer** | Filter bar — `dateRange` |
| **Tiền điều kiện** | ALL filter |
| **Steps** | 1. Mở date range picker<br>2. Chọn from = 2024-01-01, to = 2026-05-27 (> 2 năm)<br>3. Apply |
| **Expected** | Toast error `dateRangeOver2Years` + KHÔNG apply filter mới (giữ state cũ). |
| **Severity nếu Fail** | Minor |
| **P/F** | _____ |
| **Note** | _____ |

### TC-D04 — localStorage persist sau reload

| Field | Giá trị |
|---|---|
| **Lớp** | D |
| **Layer** | Filter bar + localStorage |
| **Tiền điều kiện** | Đổi filter sang `whseid = 'BKD1'`, `dateType = 'ETA gửi thầu (đơn)'` |
| **Steps** | 1. Reload page (F5)<br>2. Đợi widget mount xong<br>3. Verify filter state restore đúng (BKD1 + ETA gửi thầu (đơn))<br>4. Verify Tổng chuyến khớp filter restored |
| **Expected** | Filter restore đúng. Trước khi restore xong widget KHÔNG gọi API (không flash số ALL rồi mới về BKD1) |
| **Severity nếu Fail** | Major |
| **P/F** | _____ |
| **Note** | localStorage key: `dashboard-widget-filter:{dashboardId}:{widgetId}` |

### TC-D05 — Performance: filter response + page load + detail tab open

| Field | Giá trị |
|---|---|
| **Lớp** | D |
| **Layer** | Toàn widget |
| **Tiền điều kiện** | Browser dev tools tắt; production-like env |
| **Steps** | 1. Đo page load time (F5 → widget render xong) — repeat 5 lần lấy p95<br>2. Đo filter change response (chọn `whseid='BKD1'` → render xong) — repeat 5 lần<br>3. Đo detail tab open (click `Chi tiết bảng` → grid render đủ rows) |
| **Expected** | Page load p95 < 5s; filter response p95 < 3s; detail tab open < 8s |
| **Severity nếu Fail** | Major (nếu > 2× threshold), Minor (nếu chỉ 1.5× threshold) |
| **P/F** | _____ |
| **Note** | Mondelez ~1.5K trip/ngày — under 5000 page size limit |

---

## E. Edge cases (6 TC)

### TC-E01 — Empty result (filter chặt — vd `whseid='VN831'` window cũ)

| Field | Giá trị |
|---|---|
| **Lớp** | A+C |
| **Layer** | L1 KPI cards + L4 Detail |
| **Tiền điều kiện** | Filter rất chặt để chắc không có data |
| **Steps** | 1. Đặt `whseid='VN831'`, `transporter='<NVT không tồn tại>'`<br>2. Verify 8 KPI cards = 0<br>3. Verify donut + bar chart render rỗng<br>4. Verify detail table empty |
| **Expected** | UI render 0 (không crash). Không có message "Không có dữ liệu" rõ (per A5 — anomaly LOCKED). |
| **Severity nếu Fail** | Minor |
| **P/F** | _____ |
| **Note** | Khách có thể request banner phân biệt "0 thật" vs "lỗi config" — note vào A5 backlog |

### TC-E02 — `unknownTransporter` fallback (NVT empty)

| Field | Giá trị |
|---|---|
| **Lớp** | A+B |
| **Layer** | L3 Bar chart |
| **Tiền điều kiện** | Có ≥1 trip với `ten_ngan_nvt IS NULL` hoặc empty trong window |
| **Steps** | 1. Verify bar chart có 1 bar `Không xác định`<br>2. Cross-check count = SQL raw `WHERE ten_ngan_nvt IS NULL OR ten_ngan_nvt = ''`<br>3. Hỏi Ops Manager: "Bar `Không xác định` có giúp anh phát hiện data quality issue không?" (OQ-05) |
| **Expected** | Bar `Không xác định` render đúng. Khách quyết: giữ làm signal hay ẩn |
| **Severity nếu Fail** | Minor |
| **P/F** | _____ |
| **Note** | OQ-05 — collect Ops feedback |

### TC-E03 — Trip multi-DO với cùng priority (tie-break test)

| Field | Giá trị |
|---|---|
| **Lớp** | B |
| **Layer** | L4 Detail table — trip aggregation tie-break |
| **Tiền điều kiện** | Sample trip với 2 DO cùng alert priority (vd cả 2 = Ontime delivery) |
| **Steps** | 1. Verify 2 DO này được aggregate về 1 row<br>2. Verify `eta` lấy DO có ETA sớm nhất (tie-break = doCode asc)<br>3. Verify `mandatoryDepartAt` lấy DO có mandatoryDepartAt sớm nhất |
| **Expected** | Aggregation tie-break đúng §5.3 PRD (eta asc → doCode asc; alert priority asc → mandatoryDepartAt asc → eta asc) |
| **Severity nếu Fail** | Minor |
| **P/F** | _____ |
| **Note** | _____ |

### TC-E04 — At-risk window biên (chuyến cách deadline đúng 45 phút)

| Field | Giá trị |
|---|---|
| **Lớp** | B |
| **Layer** | L1 KPI |
| **Tiền điều kiện** | Sample trip với `now() = TG_bat_buoc - 45m` chính xác |
| **Steps** | 1. Verify status = At risk (biên 45m thuộc At risk per §3.2 PRD)<br>2. Cross-check MV `alert_status` cùng row |
| **Expected** | Status = At risk (biên inclusive). Tolerance ±2 phút vì clock skew. |
| **Severity nếu Fail** | Minor |
| **P/F** | _____ |
| **Note** | Khả năng MV implementation dùng `>` vs `>=` — verify với DA |

### TC-E05 — Trip-less DO (DO không có `trip` value)

| Field | Giá trị |
|---|---|
| **Lớp** | B |
| **Layer** | L4 Detail table — `__tripless__{doCode}` synthetic key |
| **Tiền điều kiện** | Có DO với `so_chuyen IS NULL` trong window |
| **Steps** | 1. Verify DO này vẫn xuất hiện 1 row trong detail<br>2. Verify trip key = `__tripless__{doCode}` (hoặc rỗng display)<br>3. Cross-check count grid bao gồm cả trip-less DO |
| **Expected** | Trip-less DO render đúng 1 row, không bị drop |
| **Severity nếu Fail** | Minor |
| **P/F** | _____ |
| **Note** | Khả năng MDLZ không có case này — verify trên SQL raw trước |

### TC-E06 — Settings dialog admin paste SQL (chỉ admin role)

| Field | Giá trị |
|---|---|
| **Lớp** | D |
| **Layer** | Settings dialog |
| **Tiền điều kiện** | Login với role có `editMode` |
| **Steps** | 1. Click `Setting Chart` button<br>2. Verify dialog mở với 2 tab: `Scorecard` + `Detail`<br>3. Tab Scorecard — verify SQL canonical paste-able từ spec §22.1<br>4. Click `Test Query` — verify backend execute thành công<br>5. Verify `requiredColumns` validator (note A2 — chỉ check 5/8 cột) |
| **Expected** | Dialog hoạt động đúng. Test Query trả result. KHÔNG fail UAT dù A2 LOCKED. |
| **Severity nếu Fail** | Major nếu Test Query không chạy. Minor nếu chỉ validator gap. |
| **P/F** | _____ |
| **Note** | Anomaly A2 — note nhưng không count Fail |

---

## Summary table (cho session execution)

| TC ID | Lớp | Layer | Status | Severity nếu Fail |
|---|---|---|---|---|
| TC-A01 | A | L1 Tổng chuyến | _____ | Critical |
| TC-A02 | A | L1 7 status count | _____ | Critical |
| TC-A03 | A | dateType `(đơn)` regression | _____ | Critical |
| TC-A04 | A | L2 Donut segment count | _____ | Major |
| TC-A05 | A | L2 Donut share % | _____ | Minor |
| TC-A06 | A | L3 Bar transporter total | _____ | Major |
| TC-A07 | A | L4 Detail trip count vs scorecard | _____ | Critical |
| TC-A08 | A | L4 Detail top 5 trễ vs golden | _____ | Major |
| TC-B01 | B | L1 Normal formula | _____ | Major |
| TC-B02 | B | L1 At risk 45m (OQ-01) | _____ | Major |
| TC-B03 | B | L1 Late departure open | _____ | Critical |
| TC-B04 | B | L1 Late/Ontime departure | _____ | Major |
| TC-B05 | B | L1 Late/Ontime delivery | _____ | Critical |
| TC-B06 | B | L4 Trip aggregation priority | _____ | Major |
| TC-B07 | B | L4 Warehouse standardize | _____ | Major |
| TC-C01 | C | Mental Q1 Tổng < 5s | _____ | Minor |
| TC-C02 | C | Mental Q2 Late dep open < 15s | _____ | Major |
| TC-C03 | C | 3 display groups rõ ý | _____ | Minor |
| TC-C04 | C | Donut bổ trợ KPI | _____ | Cosmetic |
| TC-C05 | C | Bar chart actionable | _____ | Major |
| TC-C06 | C | Detail sort critical đầu | _____ | Major |
| TC-D01 | D | dateType filter switch | _____ | Critical |
| TC-D02 | D | Multi-select combo | _____ | Major |
| TC-D03 | D | 2-year guard | _____ | Minor |
| TC-D04 | D | localStorage persist | _____ | Major |
| TC-D05 | D | Performance perf p95 | _____ | Major/Minor |
| TC-E01 | A+C | Empty result | _____ | Minor |
| TC-E02 | A+B | unknownTransporter fallback (OQ-05) | _____ | Minor |
| TC-E03 | B | Aggregation tie-break | _____ | Minor |
| TC-E04 | B | 45m window biên | _____ | Minor |
| TC-E05 | B | Trip-less DO | _____ | Minor |
| TC-E06 | D | Settings dialog admin | _____ | Major/Minor |

**Total 28 happy + 6 edge case = 34 TC** (đã loại merge — Summary đếm 32 do gộp E vào A+B/A+C nhóm chính).

---

## Lịch sử thay đổi

| Version | Ngày | Tác giả | Thay đổi |
|---|---|---|---|
| 1.0.0 | 2026-05-27 | PM/DA via `/da-uat` | Bản đầu tiên — 28 TC happy + 6 edge bám L1 KPI → L2 Donut → L3 Bar → L4 Detail; cover 4 lớp A/B/C/D; verify regression A1 (dateType `(đơn)`); collect OQ-01 (45m) + OQ-05 (unknownTransporter); aggregate priority rule + warehouse standardize |
