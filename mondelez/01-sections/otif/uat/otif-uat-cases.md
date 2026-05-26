# UAT Test Cases — OTIF (Mondelez)

> Mode A output. Bám storytelling Tier 1 → Tier 2 → Tier 3 + Detail panel của PRD §13.4 + AC-01..AC-15.
> Mapping storytelling level cho consistency với skill template:
> - **L1 Hero** = Tier 1 KPI cards (4 KPI cockpit)
> - **L2 Tier-1 cluster** = Health Matrix (5 dim) + Mini trend sparkline
> - **L3 Tier-2 Fail Reason** = 2 chart Fail Ontime + Fail Infull
> - **L4 Tier-2 Trend** = Trend full + target band 90%
> - **L5 Tier-3 drill-down** = 5 grouped-bar chart (NVC / Kho / Loại hàng / Kênh / Khu vực)
> - **L6 Detail panel** = OtifDetailPanel 3 tab (Operation Summary / Fail Report / Detail Table)
> - **Filter & Cross-layer edge** = riêng

---

## 0. Quy ước

- **TC-ID**: `UAT-OTIF-{NNN}` (001-022)
- **Layer**: L1 / L2 / L3 / L4 / L5 / L6 / FIL / EDGE
- **Lớp**: A (Data) / B (Logic) / C (UX) / D (Perf) — có thể kết hợp `A+B`
- **Tiền điều kiện** mặc định (trừ khi ghi khác): Loại ngày = ETA gửi thầu, Khoảng ngày = 2026-06-02 (D-1 session), NVC=ALL, Kho=ALL, Khu vực=ALL, Nhóm hàng=ALL; user = Ops Manager (MDLZ).
- **P/F**: Pass / Fail / Blocked / Defer / N/A
- **Severity nếu Fail**: Critical / Major / Minor / Cosmetic

---

## 1. Layer L1 — Hero KPI (Tier 1)

### UAT-OTIF-001 (lớp A+B, happy) — 4 KPI cards giá trị + RAG

| Field | Value |
|---|---|
| Mục đích | Verify 4 KPI cards (Tổng đơn / % Ontime / % Infull / % OTIF) hiển thị giá trị khớp golden file + 3 KPI có target hiển thị RAG đúng band per-metric §13.2 |
| Tiền điều kiện | Default filter |
| Steps | 1. Mở view OTIF<br>2. Đọc 4 KPI card<br>3. Note RAG color của % Ontime / % Infull / % OTIF<br>4. So với golden file row "KPI summary" |
| Expected | Tổng đơn khớp golden ±1%; 3 % metric khớp golden ±0.5pp; RAG đúng band (OTIF: Green≥90/Yellow85–<90/Red<85; Ontime: Green≥95/Yellow90–<95/Red<90; Infull: Green≥97/Yellow92–<97/Red<92) |
| Actual | |
| P/F | |
| Severity | Major (data) — nếu RAG sai band → Critical |
| Note | AC-01 + AC-10 |

### UAT-OTIF-002 (lớp B, edge) — RAG band ranh giới ngưỡng

| Field | Value |
|---|---|
| Mục đích | Verify RAG color đúng khi % OTIF chạm chính xác ranh giới band — % = 90.0%, 89.9%, 85.0%, 84.9% |
| Tiền điều kiện | PM/BA chọn 4 time window có % OTIF rơi vào 4 ngưỡng trên (chuẩn bị trước Mode B); nếu data thực không cover → dùng test data dev FE |
| Steps | Với mỗi ngưỡng: filter time window → note RAG |
| Expected | 90.0% → Green; 89.9% → Yellow; 85.0% → Yellow; 84.9% → Red |
| Actual | |
| P/F | |
| Severity | Major |
| Note | Edge band convention `target − 5pt buffer` (PRD §13.2) |

---

## 2. Layer L2 — Tier 1 cluster (Health Matrix + Sparkline)

### UAT-OTIF-003 (lớp A+B, happy) — Health Matrix giá trị + RAG cell

| Field | Value |
|---|---|
| Mục đích | Verify Health Matrix hiển thị 5 dim (NVC / Kho / Loại hàng / Kênh / Khu vực) đúng thứ tự §13.5 (OQ-09); mỗi cell % metric coloring RAG đúng band per-metric §13.2 |
| Tiền điều kiện | Default filter |
| Steps | 1. Quan sát thứ tự row dim<br>2. Đọc 3 sub-row đầu của NVC, so với golden top 3 NVC theo % OTIF tăng dần (worst-first)<br>3. Spot check 5 cell ngẫu nhiên cross dimension/metric, note RAG color |
| Expected | Row order = NVC → Kho → Loại hàng → Kênh → Khu vực; Sub-row sort worst-first (% OTIF ↑); ≥4/5 cell spot-check khớp golden ±0.5pp; cell coloring đúng band per-metric |
| Actual | |
| P/F | |
| Severity | Major |
| Note | §13.5 + AC-14 |

### UAT-OTIF-004 (lớp A, happy) — Mini trend sparkline khớp Trend full

| Field | Value |
|---|---|
| Mục đích | Verify mini sparkline (Tier 1) hiển thị giá trị % OTIF cho window gần khớp với Trend full (Tier 2) cùng window |
| Tiền điều kiện | Default filter |
| Steps | 1. Note giá trị endpoint sparkline (ngày D-1)<br>2. Cuộn xuống Trend Tier 2 → đọc value ngày D-1<br>3. So sánh 2 giá trị |
| Expected | 2 giá trị identical (cùng nguồn `chartTrend` query bucket=Day) |
| Actual | |
| P/F | |
| Severity | Minor |
| Note | Tier 1 vs Tier 2 consistency |

---

## 3. Layer L3 — Tier 2 Fail Reason (2 charts)

### UAT-OTIF-005 (lớp A+B, happy) — Fail Ontime classifier

| Field | Value |
|---|---|
| Mục đích | Verify Fail Ontime chart hiển thị 5 lý do (`classifyReason()` PRD §3) đúng số đơn + sort desc; tổng các bar = `fail_ontime_so` ở Detail Fail Report |
| Tiền điều kiện | Default filter |
| Steps | 1. Đọc value từng bar Fail Ontime<br>2. So với golden cột "Fail Ontime breakdown"<br>3. Cộng tay tổng → so với Fail Report `fail_ontime_so` |
| Expected | Mỗi bar khớp golden ±1%; tổng các bar = `fail_ontime_so` |
| Actual | |
| P/F | |
| Severity | Major |
| Note | AC-03 + classifier `classifyReason()` |

### UAT-OTIF-006 (lớp A+B, happy) — Fail Infull classifier

| Field | Value |
|---|---|
| Mục đích | Verify Fail Infull chart 3 bucket (`Warehouse Infull failure` / `Transport Infull failure` / `WH + Transport Infull failure`) khớp golden |
| Tiền điều kiện | Default filter |
| Steps | 1. Đọc 3 bar Fail Infull<br>2. So với golden<br>3. Cộng tay → so `fail_infull_so` |
| Expected | Mỗi bar khớp golden ±1%; tổng = `fail_infull_so` |
| Actual | |
| P/F | |
| Severity | Major |
| Note | `classifyInfullBucket()` PRD §3 |

---

## 4. Layer L4 — Tier 2 Trend (target band + time bucket)

### UAT-OTIF-007 (lớp A, happy) — Trend value theo Day bucket

| Field | Value |
|---|---|
| Mục đích | Verify mỗi điểm trên Trend (bucket=Day) khớp golden file daily % OTIF cho 7 ngày gần nhất |
| Tiền điều kiện | Khoảng ngày = 7 ngày gần nhất, bucket = Day |
| Steps | 1. Hover/click từng điểm 7 ngày → đọc tooltip<br>2. So với golden cột daily |
| Expected | 7/7 điểm khớp golden ±0.5pp |
| Actual | |
| P/F | |
| Severity | Major |
| Note | AC-04 |

### UAT-OTIF-008 (lớp B+C, happy) — Target band visual 90%

| Field | Value |
|---|---|
| Mục đích | Verify Trend chart có vùng nền xanh nhạt từ 90% → 100% (target band % OTIF) + reference dashed line tại 90%; user spot được "đang đạt/dưới target" không cần đọc số |
| Tiền điều kiện | Default filter, bucket = Day |
| Steps | 1. Quan sát vùng nền xanh<br>2. Hỏi customer: "Theo anh/chị, ngày nào tuần qua dưới target?" |
| Expected | Vùng nền xanh từ 90→100; dashed line tại 90; customer chỉ đúng ngày dưới band |
| Actual | |
| P/F | |
| Severity | Minor (storytelling) — Major nếu band sai số 90 |
| Note | AC-11 + §13.7 |

---

## 5. Layer L5 — Tier 3 drill-down (5 chart)

> 5 chart Tier 3 expanded mặc định v1.2.6 (AC-15 reversal). Mỗi TC dim verify cùng pattern: top N giá trị khớp golden ranking, % metric khớp ±0.5pp.

### UAT-OTIF-009 (lớp A+B, happy) — Chart by NVC

| Field | Value |
|---|---|
| Mục đích | Verify chart NVC hiển thị top NVC theo % OTIF, grouped-bar 3 metric (Ontime/Infull/OTIF); top 5 NVC khớp golden ranking + values |
| Tiền điều kiện | Default filter |
| Steps | 1. Đọc top 5 NVC theo % OTIF<br>2. So với golden top 5 NVC<br>3. Spot check 3 NVC: cả 3 % metric khớp ±0.5pp |
| Expected | ≥ 4/5 NVC tên match top 5; 3 NVC spot check % metric trong tolerance |
| Actual | |
| P/F | |
| Severity | Major |

### UAT-OTIF-010 (lớp A+B, happy) — Chart by Kho (whseid mapping)

| Field | Value |
|---|---|
| Mục đích | Verify chart Kho show 4 group (BKD / NKD / Kho ngoài BKD / Kho ngoài NKD) + ánh xạ whseid PRD §4 đúng; values khớp golden |
| Tiền điều kiện | Default filter |
| Steps | 1. Đếm số kho hiển thị<br>2. So % OTIF từng group với golden |
| Expected | 4 kho group; % khớp golden ±0.5pp; mapping BKD = BKD1+BKD2+BKD3 |
| Actual | |
| P/F | |
| Severity | Major |
| Note | AC-09 + ánh xạ Kho→whseid |

### UAT-OTIF-011 (lớp A+B, happy) — Chart by Loại hàng (sort order)

| Field | Value |
|---|---|
| Mục đích | Verify chart Loại hàng sort theo `OTIF_CATEGORY_ORDER` = FRESH→DRY→MOONCAKE→POSM/OFFBOM→TEST→EQUIPMENT→PM (priority 1–7) + values khớp golden |
| Tiền điều kiện | Default filter |
| Steps | 1. Note thứ tự segment trên trục X<br>2. So % OTIF từng loại hàng với golden |
| Expected | Thứ tự đúng `OTIF_CATEGORY_ORDER`; % khớp golden ±0.5pp |
| Actual | |
| P/F | |
| Severity | Major |
| Note | FEAT-128 §5.2 PRD |

### UAT-OTIF-012 (lớp A+B, happy) — Chart by Kênh

| Field | Value |
|---|---|
| Mục đích | Verify chart Kênh bán hàng hiển thị các kênh thực tế MDLZ (GT/MT/...) + values khớp golden |
| Tiền điều kiện | Default filter |
| Steps | 1. Đọc kênh + % OTIF<br>2. So golden |
| Expected | ≥ 4/5 kênh tên match; % khớp ±0.5pp |
| Actual | |
| P/F | |
| Severity | Major |

### UAT-OTIF-013 (lớp A+B, happy) — Chart by Khu vực

| Field | Value |
|---|---|
| Mục đích | Verify chart Khu vực hiển thị 4+ khu vực (South East, Ho Chi Minh, Mekong 1, Mekong 2) + values khớp golden |
| Tiền điều kiện | Default filter |
| Steps | 1. Đọc khu vực + % OTIF<br>2. So golden |
| Expected | ≥ 4/5 khu vực tên match; % khớp ±0.5pp |
| Actual | |
| P/F | |
| Severity | Major |

---

## 6. Layer L6 — Detail panel (3 tab)

### UAT-OTIF-014 (lớp A+B, happy) — Operation Summary pivot

| Field | Value |
|---|---|
| Mục đích | Verify tab %OTIF Chiều vận hành pivot 4 dimension (NVC × Kênh × Nhóm hàng × Khu vực) khớp golden; % OTIF row khớp tổng cấp trên |
| Tiền điều kiện | Default filter; user chọn full 4 dim |
| Steps | 1. Mở tab, chọn 4 dim<br>2. Spot check 5 row ngẫu nhiên với golden<br>3. Verify tổng row aggregation khớp KPI hero |
| Expected | 5/5 row spot check khớp golden ±0.5pp; tổng = KPI hero |
| Actual | |
| P/F | |
| Severity | Major |
| Note | AC-05 |

### UAT-OTIF-015 (lớp A+B, happy) — Fail Report breakdown đầy đủ

| Field | Value |
|---|---|
| Mục đích | Verify tab Fail Report có đủ 11 cột bắt buộc (PRD §6 `failSummary`) + tổng `fail_ontime_so` + `fail_infull_so` khớp `chartFailOntime` + `chartFailInfull` |
| Tiền điều kiện | Default filter |
| Steps | 1. Mở tab Fail Report<br>2. Đếm cột<br>3. Cộng `fail_ontime_so` của 4 sub-cause<br>4. So với tổng `chartFailOntime` ở Tier 2 |
| Expected | 11/11 cột present; tổng khớp ±1% |
| Actual | |
| P/F | |
| Severity | Major |

### UAT-OTIF-016 (lớp A, happy) — Detail Table cột đầy đủ

| Field | Value |
|---|---|
| Mục đích | Verify Detail Table hiển thị đủ cột PRD §5.3 + DO/SO/ETA/ATA/planned_cse/shipped_cse/delivered_cse + trạng thái Ontime/Infull/OTIF |
| Tiền điều kiện | Default filter |
| Steps | 1. Mở tab Chi tiết<br>2. Đếm cột so PRD<br>3. Export CSV, so với golden 10 row đầu |
| Expected | Tất cả cột present; 10/10 row khớp golden từng cột |
| Actual | |
| P/F | |
| Severity | Major |
| Note | AC-06 |

### UAT-OTIF-017 (lớp D, edge) — Drill xuống Order Monitor < 2s

| Field | Value |
|---|---|
| Mục đích | Click 1 DO row → mở Order Monitor với context đúng DO + load < 2s |
| Tiền điều kiện | Detail Table có ≥ 10 row |
| Steps | Click 1 row → đo wall-clock thời gian load Order Monitor → verify URL/state params chứa đúng DO code |
| Expected | Load < 2s; Order Monitor state đúng DO |
| Actual | |
| P/F | |
| Severity | Minor |

---

## 7. Filter behavior (FIL)

### UAT-OTIF-018 (lớp B, happy) — Ánh xạ Kho → whseid

| Field | Value |
|---|---|
| Mục đích | Verify filter Kho = "BKD" gửi SQL `whseid IN ('BKD1','BKD2','BKD3')`; "Kho ngoài BKD" = `'VN821'`; ALL không thêm clause |
| Tiền điều kiện | Default filter |
| Steps | 1. Filter Kho=BKD → check KPI tổng đơn vs SQL raw chạy với `whseid IN ('BKD1','BKD2','BKD3')`<br>2. Filter Kho="Kho ngoài BKD" → check vs `whseid='VN821'` |
| Expected | Số dashboard = SQL raw cho từng case |
| Actual | |
| P/F | |
| Severity | Critical (filter sai → toàn bộ dashboard sai) |
| Note | AC-09 + PRD §4 mapping |

### UAT-OTIF-019 (lớp B, edge) — Khoảng ngày > 2 năm bị reject

| Field | Value |
|---|---|
| Mục đích | Verify khoảng ngày > 2 năm → toast lỗi + KHÔNG gọi API |
| Tiền điều kiện | Default filter |
| Steps | 1. Filter Date Range = 2024-01-01 → 2026-06-02 (>2 năm)<br>2. Nhấn Apply<br>3. Quan sát toast + Network tab |
| Expected | Toast lỗi i18n hiển thị; KHÔNG có request executeWidget gửi đi; filter trước được giữ |
| Actual | |
| P/F | |
| Severity | Major |
| Note | AC-02 |

---

## 8. Cross-layer edge (EDGE)

### UAT-OTIF-020 (lớp B, edge) — Timezone cutoff UTC+7

| Field | Value |
|---|---|
| Mục đích | Verify đơn có ETA = 23:30 UTC+7 ngày D có nằm trong filter "Khoảng ngày = D" hay không; đơn 00:30 UTC+7 D+1 KHÔNG nằm trong D |
| Tiền điều kiện | PM/BA chuẩn bị 2 DO test code biết trước ETA: 1 đơn 23:30 D, 1 đơn 00:30 D+1 (có thể là DO thực hoặc test data dev CH) |
| Steps | 1. Filter Khoảng ngày = D<br>2. Mở Detail Table → tìm 2 DO test |
| Expected | DO 23:30 D có trong list; DO 00:30 D+1 KHÔNG có; placeholder `{{from_date}}` = `'D 00:00:00'`, `{{to_date}}` = `'D 23:59:59'` |
| Actual | |
| P/F | |
| Severity | Critical (timezone sai → toàn bộ daily report sai) |
| Note | PRD §6 placeholder + memory [[feedback_sql_date_type_label_exact_match]] tham chiếu |

### UAT-OTIF-021 (lớp C, edge) — Exception Spotlight đúng "chiều kéo OTIF"

| Field | Value |
|---|---|
| Mục đích | Verify Exception Spotlight liệt kê top 3-5 items off-target xuyên 5 dim, sort theo magnitude `(target − current) × volume`; khách spot được chiều cause |
| Tiền điều kiện | Default filter (có ≥ 3 items dưới target trong data) |
| Steps | 1. Đọc Exception Spotlight Tier 1<br>2. Hỏi customer "Theo anh/chị, đâu là chiều/item kéo OTIF xuống nhất?"<br>3. So câu trả lời customer vs item #1 trong Spotlight |
| Expected | Customer chỉ đúng item #1; nếu data toàn xanh → message "Tất cả chiều đều đạt target OTIF ≥ 90%" |
| Actual | (ghi câu trả lời customer) |
| P/F | (đạt yêu cầu storytelling không) |
| Severity | Major (storytelling miss = mental model sai) |
| Note | AC-13 + §13.8 |

### UAT-OTIF-022 (lớp D, edge) — Filter combo 5-dim < 3s

| Field | Value |
|---|---|
| Mục đích | Verify response time filter combo phức tạp (Kho=BKD + Khu vực=South East + Loại hàng=DRY + NVC=TLL + Khoảng ngày=30 ngày) |
| Tiền điều kiện | Cache cleared, viewport 1920×1080 |
| Steps | 1. Set 5 filter cùng lúc<br>2. Apply<br>3. Đo wall-clock time đến khi KPI cards render xong |
| Expected | < 3s |
| Actual | |
| P/F | |
| Severity | Minor (nếu 3-5s) / Major (nếu > 5s) |

---

## 9. Tóm tắt

| Metric | Value |
|---|---|
| Tổng TC | 22 |
| Happy path | 18 (TC-001, 003-016, 018) |
| Edge case | 4 (TC-002, 017, 019-022 — count = 5 nếu tính 017 perf-edge; recount: 002, 017, 019, 020, 021, 022 = 6) |
| Lớp A (Data) | 9 (TC-001, 003, 004, 005, 006, 007, 009-013, 014, 015, 016) — count cao do nhiều dim |
| Lớp B (Logic) | 6 (TC-002, 005, 006, 008, 018, 019, 020) |
| Lớp C (UX) | 4 (TC-008, 021 + observation từ 003, 014) |
| Lớp D (Perf) | 3 (TC-017, 022) — count lower |

> Note: 1 TC có thể thuộc 2 lớp (vd A+B); tổng theo lớp > tổng TC là bình thường.

### Severity expected distribution (nếu Fail)

| Severity | Count |
|---|---|
| Critical (block signoff) | 2 (TC-018 ánh xạ Kho, TC-020 timezone) |
| Major | 14 |
| Minor | 6 |
| Cosmetic | 0 |

---

## 10. Notes cho Mode B+C

- **TC-002 (RAG ranh giới)**: Yêu cầu PM/BA preset 4 time window có % OTIF chính xác ngưỡng — chuẩn bị trong Mode B dry-run, KHÔNG để session phụ thuộc data thực.
- **TC-020 (Timezone)**: Cần 2 DO test code chuẩn bị từ dev CH on-call trước Mode B (xác định trong dry-run).
- **TC-021 (Exception Spotlight)**: TC tự nhiên (organic) — KHÔNG cho customer xem Spotlight trước khi hỏi (storytelling validation).
- **Lớp C** không có "đúng/sai" tuyệt đối — Pass khi customer xác nhận "đọc được story Q1→Q5"; ghi rõ câu trả lời customer làm evidence trong execution log.
- **Defer rule**: Nếu hết giờ → ưu tiên defer TC lớp D (perf) và edge cases (002, 017, 021, 022); KHÔNG defer TC lớp A reconciliation chính.
