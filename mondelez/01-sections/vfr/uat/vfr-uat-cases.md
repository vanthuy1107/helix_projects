# UAT Test Cases — VFR — Mondelez

**Section:** `vfr` · **Layout:** Storytelling v2 (origin/dev 69caff3) · **Window:** 2026-05-18 → 2026-05-22 · **Filter:** ALL / ETA
**Executed by:** PM/DA team (squad1) · **Total TC:** 38 happy + 9 edge = 47

> Code-as-built reference: [widget-vfr.tsx](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx), [widget-vfr-hero.tsx](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr-hero.tsx), [widget-vfr-bucket-chips.tsx](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr-bucket-chips.tsx), [widget-vfr-exception-panel.tsx](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr-exception-panel.tsx), [preset-templates.ts:696-795](../../../../frontend/src/features/dashboard/data/preset-templates.ts#L696-L795).

Layout sections binding: **L1 Hero** · **L2 Buckets** · **L3 Exception** · **L4 Charts** (Area/Vehicle/Vendor/Loading Type) · **L5 Time×Area** · **L6 Detail grid**.

---

## Lớp A — Data Reconciliation (TC-A-01 → TC-A-18)

| TC ID | Layer | Pre-condition (filter) | Steps | Expected | Live snapshot (Mode A) | Severity if fail |
|---|---|---|---|---|---|---|
| TC-A-01 | L1 Hero GT | mode=GT, ALL, ETA, 18-22/05 | Mở widget → đọc Avg VFR ở hero | = SQL value (Excel sheet 01) + matches golden | **94.49%** 🟢 | Critical |
| TC-A-02 | L1 Hero VH | mode=VH, ALL, ETA, 18-22/05 | Toggle sang VH → đọc Avg VFR | = SQL value (Excel sheet 01) + matches golden | **78.10%** 🟡 | Critical |
| TC-A-03 | L1 Hero Δ | (any mode, hero luôn show cả 2) | Đọc Δ GT−VH ở hero | = +16.39pp, có dấu, RAG indicator | **+16.39pp** | Major |
| TC-A-04 | L1 Hero gap | mode=VH | Đọc gap-vs-target | = 78.10 − 85.00 = −6.90pt; RAG = 🟡 | -6.90pt 🟡 | Minor |
| TC-A-05 | L2 Bucket GT Low | mode=GT | Đếm chip Low <50% | = 4 | 4 | Major |
| TC-A-06 | L2 Bucket GT Med | mode=GT | Đếm chip Medium 50-70% | = 6 | 6 | Major |
| TC-A-07 | L2 Bucket GT High | mode=GT | Đếm chip High 70-95% | = 178 | 178 | Major |
| TC-A-08 | L2 Bucket GT Exc | mode=GT | Đếm chip Excellent ≥95% | = 358 (registry ≥95, nếu widget config còn >95 thì có thể off-by N với N=count trip vfr_max=95.0) | 358 | Major |
| TC-A-09 | L2 Bucket VH Low | mode=VH | Đếm chip Low | = **78** — flag điểm nóng | 78 | Major |
| TC-A-10 | L2 Bucket VH all | mode=VH | Sum 4 chip + Avg row → tổng chuyến VH | = 78+87+137+190 = 492 | 492 | Major |
| TC-A-11 | L3 Exception count | window 7d trước today, vfr_max<50 | Đếm trong exception panel | = SQL detail filter vfr_max<50 ∩ 7d | (refresh ở Mode B — UAT window 5d ≠ exception 7d) | Major |
| TC-A-12 | L4 By Area GT | mode=GT | So sánh VFR per khu vực với SQL weighted (sheet 02) | ≤ 0.5pp diff cho từng row; ranking top 3 worst khớp golden ≥ 4/5 | Khu vực worst-first; xem Excel sheet 02 | Major |
| TC-A-13 | L4 By Area VH | mode=VH | So sánh VFR per khu vực | ≤ 0.5pp diff; worst-first sort | Excel sheet 02 | Major |
| TC-A-14 | L4 By Vehicle GT | mode=GT | So sánh VFR per loại xe (12-34 type) | ≤ 0.5pp diff; tên loại xe match | Excel sheet 02 | Major |
| TC-A-15 | L4 By Vendor GT | mode=GT, admin **đã** paste By Vendor SQL | So sánh VFR per NVC | ≤ 0.5pp; ranking 4/5 worst match golden | Ad-hoc, Excel sheet 02 (xem AC-S5) | Major |
| TC-A-16 | L4 By Loading Type GT | mode=GT | So sánh VFR per Loose / Full Pallet | Loose vs FP rõ riêng; vfr_ratio match SQL | Excel sheet 02 (ad-hoc rollup) | Minor |
| TC-A-17 | L5 Time×Area | mode=GT | So sánh cell value VFR per period × area | ≤ 0.5pp/cell; avg row + col render đúng | Excel sheet 02 + spec §3.4 | Minor |
| TC-A-18 | L4 Trend daily | mode=GT, VH | So Avg VFR per ngày trong 5 ngày | ≤ 0.5pp/ngày | Sheet 03 | Major |

---

## Lớp B — Business Logic (TC-B-01 → TC-B-09)

| TC ID | What | Steps | Expected | Severity |
|---|---|---|---|---|
| TC-B-01 | Per-trip MAX(VFR tấn, khối) | Chọn 1 trip trong Detail grid với VFR tấn + VFR khối + VFR max hiển thị | `vfr_max = MAX(tấn, khối)` (lấy max, không min) | Critical |
| TC-B-02 | Target 85% — RAG band | Đọc tài liệu PRD §3.6 với khách | Xác nhận MDLZ chấp nhận 85% chung cho cả GT + VH; RAG 🟢≥85/🟡75–<85/🔴<75; có thể điều chỉnh sau v1.0 | Critical |
| TC-B-03 | Avg VFR formula | Đọc tooltip Avg VFR ở hero | Documented = simple avg(vfr_max), NOT weighted (V3 Bước 4-5 chưa apply — BUG-VFR-09 tracked riêng) | Major |
| TC-B-04 | Dimension VFR weighted | Mở tooltip chart By Area | Document Loose+FP × Khối/Tấn fill×mix weighted | Major |
| TC-B-05 | Bucket boundary ≥95 | So registry vs runtime widget config | Registry dùng `vfr_max >= 95` (BUG-VFR-08 fixed). Nếu widget config DB chưa re-paste → off-by-N (N=count trip vfr_max=95.0 exact) | Major |
| TC-B-06 | VFR > 100% behavior | Filter detail Mode=GT, V (vfr_max) >100 | Render raw (vd 142%) + AlertTriangle icon, vẫn đếm Excellent ≥95 | Minor |
| TC-B-07 | Zero-delivery (regTon>0, actTon=0, actCbm=0) | Filter detail với P=0, S=0, O>0 | Render 0 + AlertTriangle (BUG-VFR-02 fixed) | Minor |
| TC-B-08 | Loose vs Losse typo | Filter detail K (Loại bốc xếp) = 'Losse' | Có chuyến với 'Losse', nhưng chart aggregate gom Loose + Losse (registry IN ('Loose','Losse')) | Minor |
| TC-B-09 | Loading type empty → '(rỗng)' | Filter detail K = '(rỗng)' | Có rows; chart byLoadingType gom thành group 'Không xác định' (BUG-VFR-04 fixed) | Minor |

---

## Lớp C — UX & Storytelling (TC-C-01 → TC-C-11)

| TC ID | Section | Mental model question | Expected behavior |
|---|---|---|---|
| TC-C-01 | Hero | Q1 'VFR tổng có thấp?' ≤ 2s | Khách đọc Avg + RAG ngay, không cần scroll. **GT 🟢 OK, VH 🟡 cần chú ý** |
| TC-C-02 | Hero Δ | Q2 'Kế hoạch hay thực thi kém?' ≤ 10s | Khách đọc GT/VH/Δ; câu trả lời: "Kế hoạch tốt, thực thi kém hơn 16.39pp" |
| TC-C-03 | Dimension charts | Q3 'Chiều nào kéo VFR xuống?' ≤ 20s | Worst-first sort → khách chỉ đúng khu vực / NVC / loại xe non-tải nhất |
| TC-C-04 | Exception | Q4 'Bao nhiêu chuyến nguy hiểm <50%?' ≤ 20s | Count + top 3 dim chip per area/vendor/vehicle; CTA drill 1-click |
| TC-C-05 | Sparkline | Q5 'Xu hướng VFR đang lên hay xuống?' ≤ 30s | Sparkline 14d cho thấy hướng. ⚠ PRD §18 ghi 13w — drift, dùng 14d làm chuẩn |
| TC-C-06 | Action title | Mở chart By Area → đọc title | Title dynamic (vd "Mekong 1 kéo VFR xuống 58% — thấp nhất 6 khu vực, hụt target 27 điểm") thay vì label tĩnh |
| TC-C-07 | RAG color charts | 3 sorted bar (Area/Vehicle/Vendor) | Có dashed ReferenceLine tại 85; bar tô RAG theo band |
| TC-C-08 | Bucket chips RAG | 4 chip dưới hero | Low🔴 / Medium🟡 / High🟢 / Excellent🟢đậm — KHÔNG còn 5 màu rời, Avg gộp hero |
| TC-C-09 | Preset BOD | Chọn preset-om-vfr-bod | Chỉ render hero + sparkline trong chart Loading Type (visibleSections=['hero','chartLoadingType']) |
| TC-C-10 | Preset Ops | Chọn preset-om-vfr-ops | Render hero + buckets + exception + detail (4 section) |
| TC-C-11 | Preset Carrier | Chọn preset-om-vfr-carrier | Render hero + chartVendor + chartArea + timeAreaTable + detail (5 section). Carrier KHÔNG cần chartVehicle/Loading Type |

---

## Lớp D — Performance / Filter (TC-D-01 → TC-D-09)

| TC ID | What | Steps | Expected | Severity |
|---|---|---|---|---|
| TC-D-01 | 12 SQL parallel | Mở widget lần đầu, trace Network | 12 calls executeWidget < 5s tổng; mỗi call < 800ms | Major |
| TC-D-02 | Filter combo 5-dim < 3s | Chọn Khu vực + NVC + Loại xe + ngày → Apply | Re-fetch < 3s | Major |
| TC-D-03 | Mode toggle không refetch chart | Hero hiển thị Mode GT → click toggle VH | Chart batch KHÔNG có call mới (data prefetch cả 2); detail có refetch | Major |
| TC-D-04 | Date cap 12 tháng | Chọn from_date = today−400d → Apply | from_date clamp về today−365d + toast `dateRangeCapWarning` (BUG-VFR-05 fixed) | Major |
| TC-D-05 | Filter multi-select | Chọn Khu vực = 2 giá trị → Apply | SQL `IN (a, b)`; số dashboard = tổng theo 2 khu vực | Major |
| TC-D-06 | Filter reset | Apply filter custom → click Reset | Default state đầy đủ (5 dim ALL, ETA, startOfMonth→today) | Minor |
| TC-D-07 | Preset switch < 1s | Đổi preset → render | < 1s, không refetch SQL (section visibility chỉ ở FE) | Minor |
| TC-D-08 | Detail pagination | Mở Detail tab → chuyển page 1→2→3 | < 800ms/page; pageSize 10/20/50 work | Minor |
| TC-D-09 | Export all rows | Click "Export all rows" trong Detail | Trả CSV với toàn bộ trip window; tối đa 50 × 5000 = 250k rows | Minor |

---

## Edge cases (TC-E-01 → TC-E-09)

| TC ID | Edge | Expected |
|---|---|---|
| TC-E-01 | window 1 ngày | Avg VFR + bucket vẫn render; sparkline vẫn show (14d tự fill) |
| TC-E-02 | window > 12 tháng | Clamp + toast (TC-D-04 duplicate, đặt riêng cho hậu kiểm) |
| TC-E-03 | filter no-data combination (NVC X + Khu vực Y không có chuyến) | Hero "—" hoặc 0; bucket = 0; empty state chart |
| TC-E-04 | By Vendor admin chưa cấu hình SQL | Empty state placeholder "Admin chưa cấu hình SQL"; widget không crash (AC-S5) |
| TC-E-05 | Exception <50% = 0 trong 7d | Empty state badge xanh "Hệ thống ổn — không có chuyến <50%" |
| TC-E-06 | Trip vfr_max = 95.0 chính xác | Đếm vào Excellent (registry ≥95). Nếu widget runtime SQL chưa update → drop khỏi cả 2 bucket. Verify với DB |
| TC-E-07 | Mode toggle khi đang Settings dialog mở | Dialog state preserved; mode toggle vẫn work |
| TC-E-08 | Filter ATA + window có chuyến chưa ATA | Hero vẫn render; chuyến chưa ATA bị loại khỏi window (toDate(NULL) → drop) |
| TC-E-09 | 0 chuyến trong window | Hero hiện "—"; buckets 0; exception 0; charts empty state; KHÔNG crash |

---

## TC defer rule

Nếu session ngắn không chạy hết:
- **Bắt buộc chạy:** Lớp A (TC-A-*) + TC-B-01 + TC-B-02 + TC-B-05 + TC-C-01..C-05 + TC-D-04
- **Có thể defer:** Edge cases TC-E-* + TC-D-08/09 + TC-C-09..11 (preset)
- Ghi rõ lý do defer trong execution log.

## TC route handoff (defect lớp X → đi đâu)

Xem `vfr-uat-plan.md §11`.
