# UAT Test Cases — Flash Daily (Mondelez)

> Mode A output. Bám storytelling 6 levels L1-L6 của PRD §5.4 + AC-01..AC-11 + 25 quyết định oq-resolution.md §0a.
> Mapping storytelling level cho consistency với skill template:
> - **L1 Hero** = % Hoàn thành hôm nay full-width + target 95% + RAG
> - **L2 Exception Spotlight** = 3 ô (Top N kho off-target / Đơn rớt / Khu vực dưới target)
> - **L3 Funnel** = 5-status strip compact (Chưa xuất → Đang xuất → Đã xuất → Đang vận → Đã vận)
> - **L4 Drop Trend** = `chartDropTrend` line chart 14 ngày + target ≤5% + rolling 30d
> - **L5 Dimension panels** = 4 horizontal bar panels (Kho / Khu vực / Khách / Kênh)
> - **L6 Detail tables** = 9 WidgetGrid `DSHFLADTG01..09`
> - **FIL** = 8 filter combo + persist + brand dependent
> - **EDGE** = STM lag / synthetic fallback removed / UOM=do / Date type guard

---

## 0. Quy ước

- **TC-ID**: `UAT-FLASH-{NNN}` (001-025)
- **Layer**: L1 / L2 / L3 / L4 / L5 / L6 / FIL / EDGE
- **Lớp**: A (Data) / B (Logic) / C (UX) / D (Perf) — có thể kết hợp `A+B`
- **Tiền điều kiện** mặc định (trừ khi ghi khác): Date Type = GI date, Date Range = 2026-06-08 (D-1 session, 1 ngày), Kho/Channel/Cargo Group/Brand/Region = ALL, UOM = cse; user = Ops Manager (MDLZ).
- **P/F**: Pass / Fail / Blocked / Defer / N/A
- **Severity nếu Fail**: Critical / Major / Minor / Cosmetic

Tổng: 25 TC (20 happy + 5 edge). Chạy theo thứ tự lớp A → B → C → D.

---

## 1. Layer L1 — Hero % Hoàn thành (Tier 1)

### UAT-FLASH-001 (lớp A+B, happy) — L1 Hero giá trị + RAG band

| Field | Value |
|---|---|
| Mục đích | Verify L1 Hero hiển thị % Hoàn thành hôm nay full-width + target 95% reference + RAG color đúng band (Green ≥95 / Yellow 85-<95 / Red <85) + sub-numbers Plan/Đã giao/Còn lại đúng công thức (PRD §3.2) |
| Tiền điều kiện | Default filter |
| Steps | 1. Mở view Flash Daily<br>2. Đọc giá trị % Hoàn thành L1<br>3. Đọc 3 sub-numbers (Plan / Đã giao / Còn lại)<br>4. Note RAG color (Green/Yellow/Red)<br>5. So với golden file row "Daily summary" + tự verify Plan = Done + Còn lại |
| Expected | % Hoàn thành khớp golden ±0.5pp; Plan khớp golden ±1%; Đã giao khớp golden ±1%; Còn lại = Plan − Đã giao (chính xác); RAG đúng band per-target 95%; KHÔNG có delta, KHÔNG có as-of timestamp (per F2 + G7 chốt) |
| Actual | |
| P/F | |
| Severity | Major (data) — nếu RAG sai band → Critical |
| Note | AC-02 + PRD §5.4 + memory [[project_mondelez_flash_daily_target]] |

### UAT-FLASH-002 (lớp B, edge) — RAG band ranh giới ngưỡng

| Field | Value |
|---|---|
| Mục đích | Verify RAG color đúng khi % Hoàn thành chạm chính xác ranh giới: 95.0%, 94.9%, 85.0%, 84.9%, 80.0%, 79.9% (Alert banner ngưỡng) |
| Tiền điều kiện | PM/BA chọn 6 time window có % Hoàn thành rơi vào 6 ngưỡng trên (chuẩn bị trước Mode B); nếu data thực không cover → dùng test data dev FE |
| Steps | Với mỗi ngưỡng: filter time window → note RAG + Alert banner |
| Expected | 95.0% → Green; 94.9% → Yellow; 85.0% → Yellow; 84.9% → Red; 80.0% → Red KHÔNG banner; 79.9% → Red + Alert banner full-width xuất hiện |
| Actual | |
| P/F | |
| Severity | Major |
| Note | PRD §5.4 storytelling principles "Alert banner full-width khi overall < 80%" |

---

## 2. Layer L2 — Exception Spotlight (3 ô)

### UAT-FLASH-003 (lớp A+B, happy) — 3 ô Exception giá trị

| Field | Value |
|---|---|
| Mục đích | Verify L2 Exception Spotlight 3 ô: (a) Top N kho off-target (<85%) — list tên kho + % của mỗi kho; (b) Đơn rớt chưa xử lý — count đơn FAIL chưa close; (c) Khu vực dưới target — list region <95%. Mỗi ô có headline + list-3-max |
| Tiền điều kiện | Default filter |
| Steps | 1. Đọc ô (a): note 3 kho + %<br>2. Đọc ô (b): note count đơn rớt<br>3. Đọc ô (c): note 3 khu vực + %<br>4. So với golden file 3 nguồn (a/b/c) |
| Expected | (a) ≥4/5 tên kho match golden, % khớp ±0.5pp; (b) count khớp golden ±1%; (c) ≥4/5 tên khu vực match, % khớp ±0.5pp. Filter "<85%" cho ô (a) là worst-first per memory [[project_mondelez_flash_daily_storytelling]] |
| Actual | |
| P/F | |
| Severity | Major |
| Note | PRD §5.4 L2 — registry "L2 Điểm nóng — Kho", "L2 Điểm nóng — Drop + Lý do", "L2 Điểm nóng — Khu vực" |

### UAT-FLASH-004 (lớp C, happy) — L2 click → L5 highlight

| Field | Value |
|---|---|
| Mục đích | Verify click 1 kho trong L2 ô (a) → scroll xuống L5 panel Kho + highlight row đó (outline + full opacity) |
| Tiền điều kiện | Default filter, có ≥ 1 kho off-target trong L2 |
| Steps | 1. Click kho A trong L2 ô (a)<br>2. Quan sát viewport scroll<br>3. Note row được highlight trong L5 panel Kho |
| Expected | Smooth-scroll xuống L5 Kho panel; row của kho A có outline + bold; row khác giảm opacity (50%) |
| Actual | |
| P/F | |
| Severity | Minor (UX) |
| Note | PRD §5.4 storytelling principles + Spec §6.8 L5 panel |

---

## 3. Layer L3 — Funnel 5 status (compact strip)

### UAT-FLASH-005 (lớp A+B, happy) — L3 Funnel volume + % share

| Field | Value |
|---|---|
| Mục đích | Verify L3 funnel hiển thị strip 5 status với (a) volume per status khớp golden, (b) % share = volume_status / total_plan × 100, (c) thứ tự đúng STATUS_ORDER mới (Chưa xuất → Đang xuất → Đã xuất → Đang vận → Đã vận — per drift #11 fix) |
| Tiền điều kiện | Default filter, UOM=cse |
| Steps | 1. Đọc volume 5 status<br>2. Đọc % share<br>3. So volume với golden + SQL raw từng status<br>4. Verify Σ volume = Plan (L1) ± 1% |
| Expected | 5 volume khớp golden ±1%; % share khớp ±0.5pp; Σ volume = Plan L1; thứ tự đúng STATUS_ORDER (Chưa xuất → Đang xuất → Đã xuất → Đang vận → Đã vận); KHÔNG có status `Kế hoạch xuất` hay `Thực xuất` trong funnel (đó là KPI cards baseline §5.1 — đã thay bằng L3 funnel) |
| Actual | |
| P/F | |
| Severity | Major (data) — nếu sai thứ tự → Critical (drift #11 chưa fix) |
| Note | PRD §5.4 L3 + Spec §20 Drift #11 |

### UAT-FLASH-006 (lớp B, edge) — STM lag không double-count "Đã xuất kho" + "Đang vận chuyển"

| Field | Value |
|---|---|
| Mục đích | Verify CH MV `e2e_label` pre-computes 2 status mutually exclusive qua `thoi_gian_di IS NULL` check — 1 đơn DO chỉ thuộc 1 bucket tại 1 thời điểm. STM lag KHÔNG inflate count tổng (Audit A3 finding 1) |
| Tiền điều kiện | PM/BA chuẩn bị test data: 1 đơn có `actual_ship_date NOT NULL` + `thoi_gian_di IS NULL` (kho xuất xong, chưa nhận signal STM) — đơn này phải ở bucket "Đã xuất kho", KHÔNG ở "Đang vận chuyển" |
| Steps | 1. Filter time window có đơn test case<br>2. Đọc count "Đã xuất kho" và "Đang vận chuyển"<br>3. Run SQL raw count distinct so theo `e2e_label` (CH `mv_flash_and_drop_report`)<br>4. Verify dashboard count = SQL count, KHÔNG có overlap |
| Expected | Dashboard "Đã xuất kho" count = SQL `e2e_label='Đã xuất kho'` distinct so; tooltip 2 status có caveat "Chưa nhận tín hiệu ATD từ STM"; KHÔNG có đơn nào count 2 lần |
| Actual | |
| P/F | |
| Severity | Critical (nếu inflate count → toàn hệ thống số sai) |
| Note | PRD §3.1 v1.1.0 + Audit A3 finding 1 (oq-resolution.md §0c) |

---

## 4. Layer L4 — Drop Trend 14 ngày (chartDropTrend MỚI)

### UAT-FLASH-007 (lớp A+B, happy) — L4 drop_rate 14 ngày khớp SQL

| Field | Value |
|---|---|
| Mục đích | Verify L4 line chart hiển thị 14 ngày drop_rate (FAIL/Plan × 100, FAIL = `status='Cancel'` only per H1) + 2 reference lines (target ≤5% solid red + rolling 30d avg dashed grey). CTE backfill 44d để có 30 priors cho rolling avg |
| Tiền điều kiện | Default filter (L4 áp filter parity per Spec §6.7) **HOẶC** filter-independent (per memory [[project_mondelez_flash_daily_l4_filter_independent]] — chốt v1.1.0). PM/BA verify behavior thực tế trước session. |
| Steps | 1. Đọc 14 điểm trên line chart<br>2. Hover tooltip → note `total_plan`, `total_failed`, `drop_rate`, `drop_rate_30d_avg`<br>3. So với SQL raw chạy chart `chartDropTrend` (registry "L4 Trend tỷ lệ rớt 14 ngày")<br>4. Verify target line = y=5 (solid red); rolling line = `drop_rate_30d_avg` per day (dashed grey) |
| Expected | 14 điểm drop_rate khớp SQL ±0.5pp; rolling 30d avg per day khớp SQL ±0.5pp; reference lines render đúng (target solid red label "Target ≤5%"; rolling dashed grey, KHÔNG nhầm vai 2 lines); X-axis 14 ngày DESC sort lại ASC trong FE trước render |
| Actual | |
| P/F | |
| Severity | Major (chart MỚI — nếu fail → block storytelling Q4) |
| Note | PRD §6.6 + Spec §6.7 + H1 chốt FAIL=Cancel only |

### UAT-FLASH-008 (lớp B, edge) — L4 date type guard disable ETD/ETA

| Field | Value |
|---|---|
| Mục đích | Verify khi user chọn Date Type = `ETD gửi thầu` hoặc `ETA gửi thầu` trên filter bar overall → L4 chart **disable 2 option đó** trên UX hoặc fallback về GI date (H2 chốt — `mv_dropped_report` chỉ expose 3/5 date_type) |
| Tiền điều kiện | Filter bar set Date Type = `ETD gửi thầu` |
| Steps | 1. Đổi Date Type = ETD gửi thầu trên filter bar<br>2. Quan sát L4 chart<br>3. Đổi Date Type = ETA gửi thầu → quan sát L4<br>4. Hover tooltip → note giá trị |
| Expected | UX hành vi 1 trong 2: (a) L4 ẩn 2 option đó trong scope chart, fallback GI date; (b) L4 hiển thị empty state "Date type ETD/ETA chưa support cho Drop Trend". KHÔNG render line chart với data sai |
| Actual | |
| P/F | |
| Severity | Major |
| Note | H2 chốt (PRD §11) |

### UAT-FLASH-009 (lớp A+B, happy) — L4 FAIL = Cancel only, KHÔNG bao gồm Close

| Field | Value |
|---|---|
| Mục đích | Verify L4 chart đếm FAIL chỉ với `status = 'Cancel'` (H1) — KHÔNG bao gồm `status = 'Close'` (dù tooltip T7 "Xử lý ko thành công" có thể bao gồm Close) |
| Tiền điều kiện | PM/BA chuẩn bị test data ngày D-1: có đơn status=Cancel + đơn status=Close + đơn status active |
| Steps | 1. Run SQL raw count: (a) status=Cancel; (b) status=Close; (c) total_plan<br>2. Đọc L4 drop_rate ngày D-1<br>3. Verify drop_rate = (a) / (c) × 100, KHÔNG = ((a)+(b)) / (c) |
| Expected | drop_rate L4 = count(Cancel) / total_plan × 100; KHÔNG bao gồm Close trong tử số |
| Actual | |
| P/F | |
| Severity | Major (definition mismatch — nếu sai sẽ confuse với T7 tooltip) |
| Note | H1 + memory [[feedback_l5_sql_canonical_status_filter]] về canonical registry |

---

## 5. Layer L5 — Dimension panels (4 horizontal bar)

### UAT-FLASH-010 (lớp A+B, happy) — L5 panel Kho giá trị + RAG

| Field | Value |
|---|---|
| Mục đích | Verify L5 panel Kho hiển thị horizontal bar `pct_done` per kho + RAG color + sort worst-first + target line x=95 solid grey + bar label phải 2 dòng (`{pct_done}%` + `{done_volume} / {total_volume} {uom}`) |
| Tiền điều kiện | Default filter (UOM=cse) |
| Steps | 1. Đọc top 5 kho worst-first<br>2. Note % của 5 kho<br>3. Note bar label 2 dòng đầy đủ<br>4. So với golden file ranking kho theo % completion ASC |
| Expected | ≥4/5 tên kho match golden top 5 worst; % khớp ±0.5pp; RAG color đúng band per-target 95%; target line x=95 hiển thị label "Target 95%"; bar label 2 dòng visible (top bold % + dưới muted volume/total) |
| Actual | |
| P/F | |
| Severity | Major |
| Note | Spec §6.8.1 + memory [[feedback_l5_dimension_panels_over_tabs]] |

### UAT-FLASH-011 (lớp A+B, happy) — L5 4 panels SUM(total_volume) parity L1 Plan (regression bug 2026-05-18)

| Field | Value |
|---|---|
| Mục đích | Verify SUM(total_volume) của L5 panel Kho, Khu vực, Customer, Kênh — mỗi cái phải PARITY với L1 Plan denominator (≤ 1%). Bug 2026-05-18: thiếu `trang_thai_don_do IN (5 canonical status)` filter trong CTE → SUM(total_volume) đếm cả non-canonical status → L5 18.350 PALLET vs L1 33.721 PALLET (ratio 1.84×). Regression test. |
| Tiền điều kiện | Default filter, UOM=pallet |
| Steps | 1. Đọc L1 Hero "Plan" volume<br>2. Trong L5 Kho panel, sum `total_volume` của tất cả kho<br>3. Trong L5 Khu vực panel, sum `total_volume`<br>4. Trong L5 Customer panel, sum `total_volume`<br>5. Trong L5 Kênh panel, sum `total_volume`<br>6. So 4 sums với L1 Plan |
| Expected | 4 sums ≈ L1 Plan ±1% (Customer panel có top-10 cap → expect slightly nhỏ hơn, note rõ); KHÔNG có panel nào > 1.5× L1 Plan |
| Actual | |
| P/F | |
| Severity | Critical (regression — nếu fail → bug 2026-05-18 chưa fix hoặc đã regress) |
| Note | memory [[feedback_l5_sql_canonical_status_filter]] + Spec §6.8 lưu ý chung "MUST filter 5 canonical status" |

### UAT-FLASH-012 (lớp A, happy) — L5 panel Customer top-10 + KHÔNG dropdown NPP/Customer

| Field | Value |
|---|---|
| Mục đích | Verify L5 panel Customer hiển thị top 10 by volume DESC (sau khi cap) + **KHÔNG có dropdown** filter NPP vs Customer (per memory [[project_mondelez_npp_eq_customer]] — Mondelez NPP=Customer) |
| Tiền điều kiện | Default filter |
| Steps | 1. Quan sát panel Customer header → confirm KHÔNG có dropdown "Tất cả / NPP / Customer"<br>2. Đọc top 10 customer<br>3. So với golden file top 10 customer by total volume |
| Expected | KHÔNG có dropdown `customerDimensionFilter`; ≥8/10 tên customer match golden top 10; top 10 sort by total volume DESC (không phải alpha) |
| Actual | |
| P/F | |
| Severity | Major (UX drift nếu dropdown vẫn xuất hiện) |
| Note | OQ-07 dropped (PRD §11) |

---

## 6. Layer L6 — Detail tables (9 WidgetGrid)

### UAT-FLASH-013 (lớp A+B, happy) — T1 Completion KHÔNG synthetic fallback (drift #7 fix)

| Field | Value |
|---|---|
| Mục đích | Verify T1 `DSHFLADTG01` Completion table render từ `tblCompletion` SQL thật. KHÔNG render 54 dòng synthetic (6 kho × 3 channel × 3 area) khi `tblCompletion` rỗng — instead show EmptyState "Chưa có data" |
| Tiền điều kiện | Default filter; PM/BA confirm trước session env UAT có `tblCompletion` SQL non-empty |
| Steps | 1. Mở tab "Chi tiết bảng"<br>2. Đọc T1 Completion<br>3. Count rows<br>4. Verify column data: whName, channel, area, mucTieu, hoanThanh, conLai, pctHoanThanh<br>5. Spot check 3 rows với golden file |
| Expected | Row count match SQL output (KHÔNG = 54 fixed); ≥3 row khớp golden ±1%; pctHoanThanh = (hoanThanh / mucTieu) × 100 (verify công thức); KHÔNG có row tên kho không thật như "Kho ngoài - NKD" / "Kho BEE_BKD" / ... (6 hardcoded) |
| Actual | |
| P/F | |
| Severity | Critical (nếu synthetic fallback vẫn render → drift #7 chưa fix) |
| Note | Spec §10 + drift #7 + PRD §6.5 v1.1.0 + Audit A2 finding |

### UAT-FLASH-014 (lớp A, happy) — T9 Flash Detail 32 cột + UOM-aware

| Field | Value |
|---|---|
| Mục đích | Verify T9 `DSHFLADTG09` 32 cột render đúng schema + 3 cột UOM-aware (ORIGINAL / SHIPPED / Sản lượng giao) đổi field theo UOM hiện hành (cse/ton+kg/cbm/pallet/do) |
| Tiền điều kiện | Default filter (cse → ton → cbm → pallet → do) |
| Steps | 1. Mở tab "Chi tiết bảng" → T9<br>2. Spot check 5 row × 32 cột — verify schema khớp Spec §8<br>3. Đổi UOM = ton → quan sát cột ORIGINAL/SHIPPED/Sản lượng giao đổi sang `{kg/1000} Tấn ({kg} Kg)`<br>4. Đổi UOM = do → 3 cột đó hiển thị "-" |
| Expected | 32 cột match Spec §8 (kể cả typo "Delievery Date 1" giữ nguyên — KHÔNG fix typo trong v1.1.0); UOM=ton render `"{kg/1000} Tấn ({kg} Kg)"`; UOM=do render `"-"` cho 3 volume cột |
| Actual | |
| P/F | |
| Severity | Major |
| Note | Spec §8 + §8.1 |

### UAT-FLASH-015 (lớp A+B, happy) — T7 Drop bucket pattern match (CSE + PC riêng)

| Field | Value |
|---|---|
| Mục đích | Verify T7 `DSHFLADTG07` Dropped Delivery hiển thị 4 bucket (Tổng kế hoạch / Xử lý thành công / Xử lý không thành công / Đang xử lý = computed = Total − Success − Failed) — với 2 cột riêng DRY&FRESH (CSE) + POSM (PC) **KHÔNG sum** (per memory [[feedback_mondelez_dropreport_cse_pc_split]]) |
| Tiền điều kiện | Default filter |
| Steps | 1. Đọc 4 row T7 Drop report<br>2. Note giá trị 2 cột CSE và PC<br>3. Verify Đang xử lý = Tổng KH − (Success + Failed)<br>4. So với golden file bucket count |
| Expected | 4 row match đúng bucket (text pattern match `tổng kế hoạch` / `xử lý thành công` / `xử lý ko thành công` / Đang xử lý computed); 2 cột CSE và PC riêng biệt — KHÔNG render "{CSE+PC} đơn"; ranking sort không sum 2 unit |
| Actual | |
| P/F | |
| Severity | Major |
| Note | PRD §3.4 + memory [[feedback_mondelez_dropreport_cse_pc_split]] |

---

## 7. Filter & UX

### UAT-FLASH-016 (lớp C+D, happy) — Filter combo cross-dim < 3s

| Field | Value |
|---|---|
| Mục đích | Verify response time khi áp 5-filter cross-dim < 3s; sau khi response, 17 useQuery tất cả refetch đồng bộ với placeholder data fallback |
| Tiền điều kiện | Default filter, viewport 1366×768 |
| Steps | 1. Đo timer start<br>2. Áp filter Kho=BKD1+BKD2, Region=South East, Cargo Group=DRY+FRESH, UOM=cse, Date Type=GI date, Date Range=hôm nay<br>3. Đo timer end khi L1+L2+L3+L5 đều stable (KHÔNG còn skeleton)<br>4. Verify 17 queries refetch (DevTools Network tab show 17 API calls) |
| Expected | Response time < 3s; 17 useQuery refetch song song; placeholderData = prev (data cũ vẫn hiển thị trong khi refetch) |
| Actual | |
| P/F | |
| Severity | Major (D) |
| Note | PRD §4 + Spec §3.1 |

### UAT-FLASH-017 (lớp D, happy) — Brand filter dependent Cargo Group (AC-11)

| Field | Value |
|---|---|
| Mục đích | Verify Brand dropdown chỉ hiện brands match Cargo Group đã chọn (`parentKey: 'group_of_cargo'` trong `brandFilter`) |
| Tiền điều kiện | Default filter |
| Steps | 1. Mở Brand dropdown khi Cargo Group=ALL → note danh sách brand<br>2. Đổi Cargo Group=DRY → mở Brand dropdown lại → note danh sách<br>3. Đổi Cargo Group=POSM → mở Brand dropdown → note |
| Expected | Cargo=ALL: tất cả brand (Solite, AFC, Lu, Cosy, Oreo, Tết, Trung Thu, Slide, KD, RITZ, Toblerone); Cargo=DRY: chỉ brands DRY (Oreo, Cosy, Slide, KD, RITZ, AFC, Lu, Toblerone); Cargo=POSM: 0 hoặc 1 brand (POSM thường không có brand) |
| Actual | |
| P/F | |
| Severity | Major (filter dependency) |
| Note | AC-11 + PRD §4 |

### UAT-FLASH-018 (lớp D, happy) — Filter persist localStorage

| Field | Value |
|---|---|
| Mục đích | Verify filter state persist vào key `dashboard-widget-filter:{dashboardId}:{widgetId}` + reload page restore đúng + trước restore xong widget KHÔNG gọi API (guard `filterInitialized`) |
| Tiền điều kiện | Default filter, browser DevTools mở tab Application/LocalStorage |
| Steps | 1. Đổi filter Kho=BKD1, UOM=ton<br>2. F5 reload<br>3. Verify localStorage có key + value<br>4. Verify filter bar restore Kho=BKD1, UOM=ton<br>5. Network tab: verify KHÔNG có API call trước khi `filterInitialized=true` |
| Expected | localStorage key `dashboard-widget-filter:{dashboardId}:{widgetId}` non-empty; reload restore filter đúng; KHÔNG có API call trước restore (max 1-2 frame delay) |
| Actual | |
| P/F | |
| Severity | Minor (Persist UX) |
| Note | AC-08 + Spec §2.3 |

### UAT-FLASH-019 (lớp C, happy) — UOM switch consistency (5 UOM)

| Field | Value |
|---|---|
| Mục đích | Verify đổi UOM (cse → ton → cbm → pallet → do) — tất cả L1/L2/L3/L5/T1-T9 đồng bộ refetch + format đúng UOM mới + subtitle "Số kế hoạch (CBM)" vẫn dùng CBM bất kể user chọn UOM gì |
| Tiền điều kiện | Default filter |
| Steps | 1. UOM=cse → snapshot L1 Plan value<br>2. Đổi UOM=ton → wait stable → snapshot L1<br>3. UOM=cbm, pallet, do — tương tự<br>4. Verify subtitle "Số kế hoạch (CBM)" trên chart luôn dùng CBM |
| Expected | 5 UOM switch: cse integer phân tách hàng nghìn; ton/cbm/pallet 0-2 decimals; do integer + label đổi "DO-line"; subtitle CBM giữ nguyên không đổi theo UOM bar (per Spec §3.3 + AC-02); KHÔNG có cell nào còn UOM cũ sau khi switch |
| Actual | |
| P/F | |
| Severity | Major (UX consistency) |
| Note | AC-02 + Spec §3.3 + Spec §6.4 (Cards CBM phụ trợ) |

---

## 8. Storytelling mental model (Q1-Q5)

### UAT-FLASH-020 (lớp C, happy) — Mental model Q1+Q2 timing ≤ 10s

| Field | Value |
|---|---|
| Mục đích | Verify Ops Manager MDLZ trả lời được Q1 ("Hôm nay đang đi tới đâu?") + Q2 ("Có rủi ro gì không?") trong ≤ 10 giây từ lúc mở dashboard, KHÔNG cần scroll xuống L3-L6 |
| Tiền điều kiện | Default filter, viewport 1366×768 (1-fold check), customer Ops Manager là người trả lời |
| Steps | 1. PM/BA bấm giờ; mở dashboard<br>2. Hỏi Ops Manager: "Hôm nay % hoàn thành bao nhiêu, có dưới target không?"<br>3. Stop timer khi Ops trả lời<br>4. Hỏi tiếp: "Kho/khu vực nào đang rủi ro?" — stop timer khi trả lời<br>5. Verify Ops chỉ scroll L1 + L2 (không cần L3-L6) |
| Expected | Q1 trả lời ≤ 5s (đọc L1 Hero %); Q2 trả lời ≤ 10s (đọc L2 Exception 3 ô); Ops KHÔNG scroll xuống L3-L6 |
| Actual | |
| P/F | |
| Severity | Major (storytelling fail = block C) |
| Note | PRD §5.4 storytelling principles + memory [[project_mondelez_flash_daily_storytelling]] |

### UAT-FLASH-021 (lớp C, happy) — Q5 ("Chiều nào kéo % xuống") qua L5 grid 2×2

| Field | Value |
|---|---|
| Mục đích | Verify L5 dùng **grid 2×2 hiển thị đồng thời 4 panels** (KHÔNG dùng Tabs) — Ops Manager spot "chiều nào kéo % xuống" trong ≤ 20s qua so sánh 4 panel cùng frame (per memory [[feedback_l5_dimension_panels_over_tabs]]) |
| Tiền điều kiện | Default filter, viewport ≥ 1920×1080 |
| Steps | 1. Scroll xuống L5<br>2. Verify layout: 4 panels visible đồng thời, 2 cột × 2 dòng<br>3. Ops trả lời "Chiều nào kéo % xuống nhất?" |
| Expected | 4 panels visible 1 frame; KHÔNG dùng Tabs/dropdown chuyển panel; Ops trả lời ≤ 20s; có thể spot panel có % thấp nhất bằng RAG color visual |
| Actual | |
| P/F | |
| Severity | Major (UX storytelling decision) |
| Note | Memory [[feedback_l5_dimension_panels_over_tabs]] override Tabs |

---

## 9. Edge cases

### UAT-FLASH-022 (lớp B, edge) — Filter Date Range > 31 ngày — performance + accuracy

| Field | Value |
|---|---|
| Mục đích | Verify dashboard ổn định khi Date Range = 90 ngày (3 tháng) — KHÔNG crash, không degrade > 2× baseline perf, số khớp golden cho window dài |
| Tiền điều kiện | Filter Date Range = 2026-03-09 → 2026-06-08 (90 ngày) |
| Steps | 1. Áp filter 90 ngày<br>2. Đo response time<br>3. So L1 Plan với SQL raw cho 90 ngày<br>4. Verify L4 chart vẫn chỉ 14 ngày (filter-independent per memory)<br>5. Verify L6 detail tables paginate đúng (page size 20/10) |
| Expected | Response time < 6s (2× baseline 3s); L1 Plan khớp SQL ±1%; L4 chart KHÔNG bị ảnh hưởng (vẫn 14 ngày); detail tables paginate working |
| Actual | |
| P/F | |
| Severity | Major (D + A) |
| Note | Stress test, không nhất thiết hard pass |

### UAT-FLASH-023 (lớp B, edge) — Filter combo all=ALL + 0 row golden

| Field | Value |
|---|---|
| Mục đích | Verify khi filter combo trả về 0 row → dashboard hiển thị EmptyState clear, KHÔNG render synthetic fallback hoặc placeholder confusion |
| Tiền điều kiện | Filter Date Range = ngày tương lai (2026-12-31) → expect 0 row |
| Steps | 1. Áp filter ngày tương lai<br>2. Quan sát L1, L2, L3, L4, L5, L6<br>3. Verify mỗi section có EmptyState message rõ ràng |
| Expected | L1: % Hoàn thành = "N/A" hoặc "0%" + sub-numbers 0/0/0; L2: 3 ô show "Không có data"; L3: funnel 5 status đều 0 + 0%; L4: chart empty hoặc placeholder skeleton; L5: 4 panels show empty; T1-T9: WidgetGrid show empty state; KHÔNG render 54 synthetic rows T1 |
| Actual | |
| P/F | |
| Severity | Major |
| Note | PRD §6.5 v1.1.0 |

### UAT-FLASH-024 (lớp A+C, edge) — Action title hiển thị insight

| Field | Value |
|---|---|
| Mục đích | Verify action title trên mỗi section là **insight statement** không phải static label (vd "Hôm nay 73% kế hoạch đã hoàn thành — DƯỚI target 95%"), thay theo data |
| Tiền điều kiện | 2 filter window khác % Hoàn thành: 1 window % ≥ 95% (Green) + 1 window % < 85% (Red) |
| Steps | 1. Filter window Green → đọc action title L1<br>2. Filter window Red → đọc action title L1<br>3. So 2 title — phải khác nhau (1 nói "đạt", 1 nói "DƯỚI target") |
| Expected | Title đổi theo state — Green case: "Hôm nay X% — VƯỢT target 95%" hoặc tương tự; Red case: "Hôm nay Y% — DƯỚI target 95%" với màu cảnh báo |
| Actual | |
| P/F | |
| Severity | Minor (UX) — nếu static label thì là drift PRD §5.4 |
| Note | PRD §5.4 storytelling principles "Action title nói insight" |

### UAT-FLASH-025 (lớp D, edge) — 17 useQuery song song page load < 5s

| Field | Value |
|---|---|
| Mục đích | Verify page load lần đầu (cold cache, KHÔNG localStorage) — 17 useQuery refetch đồng bộ, page interactive trong < 5s. Critical vì OTIF chỉ 9 query, Flash Daily nặng hơn 2× |
| Tiền điều kiện | Clear localStorage + clear browser cache + close all tabs Flash Daily |
| Steps | 1. Mở DevTools Network tab + Performance tab<br>2. Navigate to view Flash Daily<br>3. Đo timer từ navigation start tới khi tất cả 17 useQuery resolve + L1+L2+L3 stable<br>4. Count API calls |
| Expected | Page load < 5s; ≥ 17 API calls (15 main + 2 fallback `cards-cbm` + `charts-shared`); KHÔNG có queue/throttle browser; KHÔNG có 5xx error |
| Actual | |
| P/F | |
| Severity | Major (perf — nếu fail block rollout) |
| Note | Spec §3.1 + PRD §6.5 (17 query consolidate v1.3.0 nếu fail) |

---

## 10. Summary

| Layer | TC count | Lớp distribution |
|---|---|---|
| L1 Hero | 2 (001-002) | A+B happy / B edge |
| L2 Exception | 2 (003-004) | A+B happy / C happy |
| L3 Funnel | 2 (005-006) | A+B happy / B edge |
| L4 Drop Trend | 3 (007-009) | A+B happy / B edge / A+B happy |
| L5 Dimension panels | 3 (010-012) | A+B happy / A+B happy / A happy |
| L6 Detail tables | 3 (013-015) | A+B happy / A happy / A+B happy |
| FIL Filter | 4 (016-019) | C+D / D / D / C |
| Storytelling | 2 (020-021) | C / C |
| Edge | 4 (022-025) | B / B / A+C / D |
| **Tổng** | **25 TC (20 happy + 5 edge)** | |

Execution order Mode C: theo thứ tự lớp **A → B → C → D**, trong mỗi lớp theo thứ tự TC-001 → TC-025. Defer rule rõ trong plan §10 nếu hết giờ.
