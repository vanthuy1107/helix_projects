# PRD — Shipping Progress (Tiến độ xuất hàng)

> **Status:** 🟡 Draft v1 (cần stakeholder confirm các điểm `[TBD]`)
> **Owner:** [TBD]
> **Last updated:** 2026-05-07
> **Reference docs:**
> - Spec: `docs/02-features/tien_do_xuat_hang/shipping-progress.spec.md` *(⚠️ spec hiện tại lệch nặng so với implementation — cần rewrite)*
> - Wireframe: `docs/02-features/tien_do_xuat_hang/shipping-progress.wireframe.md` *(✅ aligned với SQL/MV)*
> - Audit results: `docs/audit-results/s2-shipping-progress-20260507.md`
> - GLOSSARY: `docs/GLOSSARY.md`

---

## 1. Overview

**Tiến độ xuất hàng** là dashboard giám sát realtime tiến độ thực thi kế hoạch xuất hàng của Mondelez Vietnam, đo bằng 4 đơn vị (UOM) song song:

- **CBM** (Cubic Meter — đơn vị gốc volume)
- **Tấn** (kg ÷ 1000)
- **Đơn** (DO — Delivery Order count)
- **Chuyến** (Trip — Số chuyến vận chuyển)

Mỗi UOM có 4 metric: **Kế hoạch** (planned, theo gửi thầu) / **Đã nhận** (received, hàng đã ShipCompleted) / **Pending** (chênh lệch) / **% Pending** (tỷ lệ chưa xuất / kế hoạch).

Feature thuộc module **Control Tower → Order Monitor**, sử dụng dữ liệu pre-computed từ ClickHouse: `analytics_workspace.mv_flash_report` UNION `mv_dropped_report` (refresh 5–30 phút).

---

## 2. Problem Statement

### 2.1 Pain points

1. **Thiếu visibility realtime** về việc kế hoạch gửi thầu (ETD) đã được thực thi đến đâu — đơn nào đã xuất, đơn nào còn pending.
2. Khi pending cao, **không biết tập trung ở kho nào, khu vực nào, nhà vận tải nào** → khó escalate cho team đúng.
3. Báo cáo tổng hợp 4 UOM (CBM/Tấn/Đơn/Chuyến) đang được làm thủ công trên Excel — tốn 1–2h/ngày cho ops team.
4. **Không có pivot view** để so sánh tiến độ giữa các dimension (kho, khu vực, nhóm hàng, loại xe vận hành) cho việc benchmark.

### 2.2 Why now

- Mondelez tăng số chuyến/ngày sau Q1/2026 → nhu cầu giám sát realtime cao hơn.
- DA team đã chuẩn hoá `mv_flash_report` (6.22M rows, range 2024-05 → 2026-05) → đủ điều kiện build dashboard tại chỗ.

---

## 3. Target Users

| Persona | Vai trò | Tần suất | Use case chính |
|---|---|---|---|
| **Logistics Manager** | Quản lý vận tải | Daily, intraday | Track % completion theo giờ; identify pending tập trung ở đâu |
| **Warehouse Supervisor** | Giám sát kho (BKD/NKD/VN821/…) | Daily | Theo dõi % xuất theo kho mình quản lý |
| **Operations Coordinator** | Điều phối chuyến | Intraday | Drill-down chuyến chưa hoàn thành để escalate transporter |

> **Personas khác** (chưa confirm scope): Sales Ops cần xem theo NPP/Customer — `[TBD]`.

---

## 4. Goals & Success Metrics

> ⚠️ Stakeholder cần confirm. Đề xuất default:

### 4.1 Business goals

| Goal | Metric | Target đề xuất |
|---|---|---|
| Tăng visibility tiến độ xuất hàng intraday | DAU view sử dụng | ≥ 3 lần/ngày/user |
| Rút ngắn time-to-detect pending bất thường | Thời gian từ delay xảy ra → ops nhận biết | < 30 phút |
| Giảm thời gian báo cáo daily | Giờ/ngày | < 15 phút (thay vì 1–2h Excel) |

### 4.2 Product KPIs sau launch

- DAU/WAU của Shipping Progress View
- Số lần Apply filter / Export per session
- Latency p95 của API (target < 2s)
- Refresh delay MV (target ≤ 5 phút như `mv_flash_report`)

---

## 5. Functional Requirements

### 5.1 Filter bar (Must-have)

| FR | Mô tả |
|---|---|
| FR-F1 | 7 filter: **Loại Ngày**, **Date Range**, **Warehouse**, **Area**, **Channel** (group_name), **Brand**, **Vendor** (transporter) |
| FR-F2 | Single-select dropdown, default `'ALL'` (trừ Date Range mặc định = today / current 7 days) |
| FR-F3 | **Loại Ngày** enum: `'Ngày gửi thầu'` (default, dùng `thoi_gian_gui_thau`) / `'ETD gửi thầu'` (dùng `etd_chuyen_gui_thau`) |
| FR-F4 | Pattern Draft → Apply: thay đổi filter chỉ update draft state; click "Apply Filters" mới fetch API |
| FR-F5 | NULL `group_name`/`brand`/`khu_vuc_doi_xe`/`ten_ngan_nha_van_tai` mapped thành `'Unclassified'` (SQL fallback) |

### 5.2 Tab "Chart" (Must-have)

| FR | Mô tả |
|---|---|
| FR-C1 | **4 KPI summary cards** (1 per UOM: CBM / Tấn / Đơn / Chuyến). Mỗi card hiển thị 4 numbers: Kế hoạch / Đã nhận / Pending / % Pending |
| FR-C2 | Color coding cho % Pending: 🟢 < 10% / 🟡 10–25% / 🔴 > 25% (xem §5.7) |
| FR-C3 | Chart "Progress by Warehouse" — stacked bar (Đã nhận / Pending) per warehouse |
| FR-C4 | Chart "Progress by Area" — stacked bar per khu vực giao hàng |
| FR-C5 | Chart "Progress by Operation Vehicle" — horizontal progress bar per loại xe vận hành |
| FR-C6 | Chart "Progress by Cargo Group" — horizontal progress bar per nhóm hàng |

### 5.3 Tab "Detail Table" (Must-have)

| FR | Mô tả |
|---|---|
| FR-T1 | Bảng tổng hợp với cột: Warehouse, Area, Channel, Vendor, Kế hoạch, Đã nhận (cho mỗi UOM) |
| FR-T2 | Per-column search input |
| FR-T3 | Sort 3-state per column |
| FR-T4 | Button "Xuất" export CSV/XLSX |
| FR-T5 | Button "Cấu hình bảng" mở dialog ẩn/hiện cột |
| FR-T6 | Pagination 10–50 rows/page |

### 5.4 Data layer (Must-have)

| FR | Mô tả |
|---|---|
| FR-D1 | Source: `analytics_workspace.mv_flash_report` UNION `analytics_workspace.mv_dropped_report` |
| FR-D2 | Refresh cadence chấp nhận: 5–30 phút (theo MV definition) |
| FR-D3 | KPI tính trong SQL/MV (single source of truth), UI **không tính lại** |
| FR-D4 | Divide-by-zero protection: SQL dùng `nullIf(ke_hoach, 0)`; UI fallback NULL → 0% |

### 5.5 API Endpoints

6 endpoints (theo spec hiện tại):

| Function | SQL Registry section | Mô tả |
|---|---|---|
| `fetchShippingProgressSummary` | "CBM/Tấn/Đơn/Chuyến kế hoạch + đã nhận + pending + %pending" (§10429–14869, 16 query) | KPI tổng — gộp 4 UOM × 4 metrics |
| `fetchShippingProgressSummaryTable` | "Bảng tổng hợp" (§15165) | Bảng chi tiết theo Warehouse × Area × Channel × Vendor |
| `fetchShippingProgressPivotByOperationVehicle` | "Bảng pivot theo loại xe vận hành" (§15378) | Pivot |
| `fetchShippingProgressPivotByCargoGroup` | "Bảng pivot theo nhóm hàng" (§15637) | Pivot |
| `fetchShippingProgressPivotByWarehouse` | "Bảng pivot theo kho" (§15899) | Pivot |
| `fetchShippingProgressPivotByArea` | "Bảng pivot theo khu vực đội xe" (§16161) | Pivot |

### 5.6 Business Logic Specification

> **Source of truth**: `analytics_workspace.mv_flash_report` UNION `analytics_workspace.mv_dropped_report`. Logic verified với 6.26M rows (range 2024-05 → 2026-05) tại 2026-05-07.

#### 5.6.1 Đầu vào & Granularity

| Item | Định nghĩa |
|---|---|
| **Granularity** | 1 row = 1 SO line × status snapshot. Một SO có thể có nhiều rows (mỗi orderline). KPI dùng `countDistinct(ma_don_hang)` để dedup tới SO level. |
| **Volume metrics** | `original_cbm`, `original_kg`, `shipped_cbm`, `shipped_kg` (đơn vị gốc CSE/PCE/PALLET đã được convert sẵn trong upstream) |
| **Status marker** | `status = 'ShipCompleted'` = "Đã nhận" (hàng đã xuất xong). Các status khác (`New`, `Picked`, `Allocated`, `PartPick`) = pending (chưa hoàn tất). |
| **Time markers** | `thoi_gian_gui_thau` (default filter), `etd_chuyen_gui_thau` (alternative filter) |

#### 5.6.2 Công thức KPI

```sql
-- Per UOM (CBM | Tấn | Đơn | Chuyến):
ke_hoach = SUM(coalesce(<original_metric>, 0))           -- hoặc countDistinct(<id>)
da_nhan  = SUM(if(status='ShipCompleted',
                  coalesce(<shipped_metric>, 0), 0))     -- hoặc countDistinct(if(status='ShipCompleted', <id>, NULL))
pending  = ke_hoach - da_nhan
pct_pending = pending / nullIf(ke_hoach, 0)
```

Cụ thể 4 UOM:

| UOM | Kế hoạch | Đã nhận |
|---|---|---|
| CBM | `SUM(coalesce(original_cbm, 0))` | `SUM(if(status='ShipCompleted', coalesce(shipped_cbm, 0), 0))` |
| Tấn | `SUM(coalesce(original_kg, 0)) / 1000.0` | `SUM(if(status='ShipCompleted', coalesce(shipped_kg, 0), 0)) / 1000.0` |
| Đơn | `countDistinct(ma_don_hang)` | `countDistinct(if(status='ShipCompleted', ma_don_hang, NULL))` |
| Chuyến | `countDistinct(so_chuyen)` | `countDistinct(if(status='ShipCompleted', so_chuyen, NULL))` |

#### 5.6.3 Status Logic

| status | Ý nghĩa | Tính vào "Đã nhận"? |
|---|---|---|
| `ShipCompleted` | Hàng đã xuất xong | ✅ |
| `New` | Đơn mới, chưa xử lý | ❌ (pending) |
| `Allocated` | Đã phân bổ pick | ❌ (pending) |
| `Picked` | Đã pick xong, chưa load | ❌ (pending) |
| `PartPick` | Pick một phần | ❌ (pending) |

> **Verified distribution (toàn MV 2024–2026):** ShipCompleted 99.88% (6.21M rows). Pending status chỉ ~0.12% — phản ánh data lag ngắn của MV.

#### 5.6.4 Filter Behavior

| Filter | SQL clause | Fallback rule |
|---|---|---|
| `whseid` | exact match | `'ALL'` → no filter |
| `groupName` | `coalesce(group_name, 'Unclassified') = p_group_name` | NULL → `'Unclassified'` |
| `brand` | `coalesce(brand, 'Unclassified') = p_brand` | NULL → `'Unclassified'` |
| `khu_vuc_doi_xe` | `coalesce(khu_vuc_doi_xe, 'Unclassified') = p_khu_vuc_doi_xe` | NULL → `'Unclassified'` |
| `ten_ngan_nha_van_tai` | `coalesce(ten_ngan_nha_van_tai, 'Unclassified') = p_ten_ngan_nha_van_tai` | NULL → `'Unclassified'` |
| `dateType + fromDate, toDate` | `toDate(<col>) BETWEEN p_from AND p_to` | dateType chọn cột áp dụng |

#### 5.6.5 Edge Cases

| # | Tình huống | Xử lý |
|---|---|---|
| BL-1 | Tổng kế hoạch = 0 (filter quá hẹp / không có data) | `pct_pending = NULL` (do `nullIf`); UI fallback `?? 0%` |
| BL-2 | `shipped > original` (giao thừa kế hoạch) | `pending = ke_hoach - da_nhan < 0` (negative) — hiện SQL không clamp → có thể hiển thị `% pending` âm. **`[TBD]` cần BA quyết định clamp 0 hay show negative** |
| BL-3 | `original_cbm/kg = NULL` | `coalesce(..., 0)` → tính như 0, không crash |
| BL-4 | NULL `group_name`/`brand`/`area`/`transporter` | SQL `coalesce → 'Unclassified'`; UI dropdown chỉ hiển thị giá trị non-empty |
| BL-5 | UNION ALL `mv_flash_report` ∪ `mv_dropped_report` schema mismatch | Hiện chưa verify column compatibility — cần DA confirm |
| BL-6 | Date filter chọn ngày tương lai | Trả empty (no data); UI hiển thị 0/0/0 |
| BL-7 | Status mới xuất hiện ngoài 5 giá trị verified | Sẽ rơi vào "pending" mặc định (vì `if(status='ShipCompleted', ..., 0)`) — an toàn |

#### 5.6.6 Threshold (đề xuất, cần stakeholder confirm)

| KPI | 🟢 Green | 🟡 Amber | 🔴 Red |
|---|---|---|---|
| % Pending (mọi UOM) | < 10% | 10–25% | > 25% |
| % Pending (cuối ngày, sau cut-off) | 0% | 0–5% | > 5% |

Áp dụng cho: KPI cards, pivot charts. `[TBD]` Phase 2 có thể cần threshold khác cho intraday vs end-of-day.

#### 5.6.7 CLAUDE.md Data Exclusion Rules — Audit

| # | Rule | Trạng thái mv_flash_report |
|---|---|---|
| 1 | `is_deleted = 0` | ⚠️ Chưa verify upstream — DA cần check |
| 2 | Cancelled orders excluded | ⚠️ Chưa thấy status `'Cancelled'` — có thể đã loại sẵn upstream |
| 3 | Virtual/Test orders excluded | ⚠️ Chưa verify — brand/group có thể có 'TEST' tag |
| 4 | Internal transfers excluded | ⚠️ Chưa verify — BA cần confirm scope |
| 5 | NULL warehouse/shift/ETD excluded | ❌ MV không filter; dùng coalesce → 'Unclassified' |
| 6 | Divide by zero → 0 | ✅ SQL `nullIf` + UI fallback (cần verify UI) |

> **Action:** DA team verify Q1, Q2, Q3, Q4 trước Phase 1 launch.

### 5.6.8 Verified Data Patterns (live ClickHouse audit 2026-05-07)

> Tất cả số liệu dưới đây được verify trực tiếp trên `analytics_workspace.mv_flash_report` ngày 2026-05-07.

#### A. UNION schema compatibility (BUG-2 đã đóng)

| MV | Số cột | Schema |
|---|---:|---|
| `mv_flash_report` | 63 | identical |
| `mv_dropped_report` | 63 | identical |

✅ **UNION ALL safe** — 2 MV có cùng 63 cột, cùng tên, cùng order. BUG-2 trong S2 audit có thể đóng.

#### B. `is_deleted` column (CLAUDE.md Rule 1)

❌ **`is_deleted` column KHÔNG tồn tại trong `mv_flash_report`** (verified via `system.columns`).

→ Filter `is_deleted = 0` được áp dụng (nếu có) ở upstream của MV (likely `mv_otif_swm_data`, STM/SWM raw sources). DA cần verify lineage.

#### C. Pending negative case (BUG-3 đã đóng)

Trên toàn 6.22M rows:

| Check | Count | % |
|---|---:|---:|
| `shipped_cbm > original_cbm` | **0** | 0% |
| `shipped_kg > original_kg` | **0** | 0% |
| `ShipCompleted AND shipped > original` | **0** | 0% |

✅ **Pending không bao giờ âm trong production data** (verified). BL-2 (negative pending) là edge case lý thuyết — Q1 PRD có thể đóng với answer: "không cần clamp; pipeline đảm bảo `shipped ≤ original`".

#### D. NULL distribution per dimension (Apr 2026)

Trên 98,746 rows tháng Apr 2026:

| Cột | NULL count | NULL % | Impact |
|---|---:|---:|---|
| `whseid` | 0 | 0% | ✅ Always present |
| `group_name` (Channel) | 0 | 0% | ✅ Always present |
| `brand` | 5 | 0.005% | 🟢 Negligible |
| `khu_vuc_doi_xe` (Area) | **16,115** | **16.3%** | 🟡 Significant — UI mapping `coalesce → 'Unclassified'` |
| `ten_ngan_nha_van_tai` (Vendor) | **6,772** | **6.9%** | 🟡 Significant — `coalesce → 'Unclassified'` |

> **Implication:** Filter "Area" hoặc "Vendor" theo giá trị cụ thể sẽ miss 6–16% rows. Filter `'ALL'` không bị ảnh hưởng.

#### E. NULL date columns (toàn MV)

| Cột | NULL count | NULL % |
|---|---:|---:|
| `thoi_gian_gui_thau` | 3,341,992 | **53.7%** |
| `etd_chuyen_gui_thau` | 3,455,511 | **55.6%** |
| Chỉ `thoi_gian_gui_thau` NULL (nhưng `etd` không) | 57,127 | 0.9% |
| Chỉ `etd_chuyen_gui_thau` NULL (nhưng `thoi_gian_gui_thau` không) | 170,646 | 2.7% |

> **Implication quan trọng:** Date filter của UI tự động loại 53–56% rows tùy `dateType` chọn. Đây là **expected behavior** vì rows NULL date là pre-tender hoặc orphan data.

#### F. Test / Cancelled / Virtual orders detection

Quét `group_name` và `brand` với pattern `LIKE '%TEST%' / '%CANCEL%' / '%VIRTUAL%'`:

✅ **0 matches** — Mondelez đã clean upstream. Q3 (test orders), Q4 partial (cancelled) PRD §8 có thể đóng với answer: "verified clean".

#### G. Status freshness by month

Distribution `status = 'ShipCompleted'` theo tháng (2026):

| Tháng | Total | ShipCompleted | % | Pending count |
|---|---:|---:|---:|---:|
| 2026-05 (current) | 20,635 | 20,389 | 98.81% | 246 |
| 2026-04 | 98,746 | 98,746 | **100.00%** | 0 |
| 2026-03 | 95,933 | 95,924 | 99.99% | 9 |
| 2026-02 | 70,663 | 70,603 | 99.92% | 60 |
| 2026-01 | 109,956 | 109,955 | 100.00% | 1 |

> **Implication:**
> - Closed months (≥1 tuần past): completion ≥ 99.9% → KPI luôn xanh
> - Current month intraday: 98–99% (pending = data lag ~5 phút)
> - Threshold 🟢<10% / 🟡10–25% / 🔴>25% chỉ trigger Amber/Red trong scenarios bất thường (system outage, mass cancellation, data pipeline lag)
> - **Reality check:** Threshold cần align với business expectations — có thể quá lỏng. **Q2 PRD: stakeholder confirm threshold mới khắt khe hơn (vd: 🟢<2% / 🟡 2–5% / 🔴>5%)?**

#### H. Verified dimension cardinality (cho UI dropdown)

| Filter | Distinct values | Sample list |
|---|---:|---|
| `group_name` (Channel) | 5 | `''`, `MT`, `GT`, `KA`, `B2B` |
| `group_of_cago` (Cargo Group) | 4 | `DRY`, `POSM/OFFBOM`, `MOONCAKE`, `FRESH` |
| `brand` | 11 | `Trung Thu`, `Tết`, `KD`, `AFC`, `Solite`, `Lu`, `Other`, `Slide`, `Cosy`, `Oreo`, `RITZ` |
| `loai_xe_van_hanh` (Operation Vehicle) | 14 | `''`, `8T`, `2T`, `8T_14PL`, `5T`, `7,3T`, `5,7T`, `11T`, `11T_16PL`, `3.5T`, `1.4T`, `Cont 20ft`, `Cont 40ft`, `2.5T` |

> **Phát hiện:** `group_name` và `loai_xe_van_hanh` có giá trị empty string `''` (1 mỗi cột). SQL `coalesce(col, 'Unclassified')` **chỉ thay NULL, không thay empty string** → empty `''` sẽ hiện trong dropdown như option trống. **Action:** UI nên filter empty hoặc SQL nên dùng `nullIf(col, '') → coalesce → 'Unclassified'`.

---

### 5.7 Color coding

Áp dụng cho % Pending:

| % Pending | Màu | Áp dụng |
|---|---|---|
| < 10% | 🟢 Green | KPI cards, pivot charts |
| 10–25% | 🟡 Amber | KPI cards, pivot charts |
| > 25% | 🔴 Red | KPI cards, pivot charts |

> **Lưu ý:** Spec.md hiện tại có nhắc đến status colors (On Track / At Risk / Delayed / Critical / Loading / Waiting / Completed) — **những status này KHÔNG tồn tại** trong MV. Spec đang mô tả feature khác (loading tracker với timeline/map/ETA) — cần rewrite spec.

---

## 6. Out of Scope

| # | Hạng mục | Lý do |
|---|---|---|
| OOS-1 | Real-time loading progress timeline (xe đang load %) | Không có data trong `mv_flash_report` — cần WMS source khác |
| OOS-2 | Map view / GPS tracking xe | Không có data — out of scope MVP |
| OOS-3 | ETA estimation (predict completion time) | Cần ML model — Phase 2+ |
| OOS-4 | Delay analysis (root cause) | Thuộc feature OTIF (`mv_otif`), không phải Shipping Progress |
| OOS-5 | Auto-refresh interval | MVP: manual refresh (click Apply); Phase 2 cân nhắc auto-refresh |
| OOS-6 | Mobile responsive UI | MVP chỉ desktop |
| OOS-7 | Drill-down KPI → trip detail | Phase 2 nếu user feedback yêu cầu |
| OOS-8 | Forecast pending end-of-day | Phase 2+ |

---

## 7. Decisions Log

| ID | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Source data | ✅ `mv_flash_report` UNION `mv_dropped_report` | Match với SQL Registry "Tiến độ xuất hàng - verified" |
| D2 | "Đã nhận" definition | ✅ `status = 'ShipCompleted'` | Match với SQL; 99.88% rows |
| D3 | Pending formula | ✅ `pending = ke_hoach - da_nhan` per UOM | Simple arithmetic, không clamp |
| D4 | Default Date Type | ✅ `'Ngày gửi thầu'` | Match với SQL default |
| D5 | NULL fallback | ✅ `'Unclassified'` cho group/brand/area/vendor | Match với SQL `coalesce` |

### Decisions đã đóng sau live data audit (2026-05-07)

| ID | Decision | Resolution |
|---|---|---|
| ~~Q1~~ | Pending có thể âm khi `shipped > original` | ✅ **CLOSED** — verified 0/6.22M rows (data pipeline đảm bảo `shipped ≤ original`); không cần clamp |
| ~~Q3 (data audit)~~ | Test/Virtual orders | ✅ **CLOSED** — verified 0 matches trên `group_name`/`brand` |

### Decisions còn `[TBD]`

| ID | Decision | Khi nào cần |
|---|---|---|
| Q2 | Threshold % Pending — verified data cho thấy completion 99.9%+ cho closed months → threshold 🟢<10%/🟡<25% có thể quá lỏng. Có cần đổi thành 🟢<2%/🟡<5%/🔴>5% (intraday) hoặc 🟢=0%/🔴>0% (end-of-day)? | Trước Phase 1 — Logistics manager confirm |
| Q4 | Status khác 'ShipCompleted' (`New`, `Allocated`, `Picked`, `PartPick`) có cần show separately? Distribution: ~0.12% toàn MV | Phase 2 — drill-down nếu user request |
| Q5 | Internal transfer orders (kho → kho) có nằm trong scope không? | Phase 1 — BA quyết định |
| Q6 (mới) | Empty string `''` trong `group_name`, `loai_xe_van_hanh` — UI có nên filter ra hay map thành 'Unclassified'? | Trước Phase 1 — UI/BA align |
| Q7 (mới) | Cancelled orders status có pattern khác (status code, type field)? Cần DA check thêm — pattern `LIKE '%CANCEL%'` không match | DA verify upstream |

---

## 8. Data Quality Risks (post live audit 2026-05-07)

| # | Risk | Severity | Status sau live audit | Action |
|---|---|---|---|---|
| ~~Q1~~ | `is_deleted=0` chưa verify | 🟡 Medium | ❌ **`is_deleted` column KHÔNG tồn tại trong `mv_flash_report`** | DA verify lineage upstream (mv_otif_swm_data, raw STM/SWM) |
| ~~Q2~~ | UNION ALL schema compatibility | 🟡 Medium | ✅ **CLOSED** — 2 MV cùng 63 cột identical | None |
| ~~Q3~~ | Test/Virtual orders | 🟡 Medium | ✅ **CLOSED** — 0 matches trong `group_name`/`brand` | None |
| Q3' | Cancelled orders | 🟡 Medium | ⚠️ Pattern `LIKE '%CANCEL%'` không match — có thể status code khác | DA verify (Q7 mới ở §7) |
| Q4 | Internal transfer orders | 🟡 Medium | Chưa verify | BA confirm scope |
| ~~Q5~~ | Pending âm | 🟢 Low | ✅ **CLOSED** — verified 0/6.22M rows | None |
| Q6 | Hardcoded date trong sql-registry.md:10620 | 🟢 Low | Chưa fix | DA cleanup |
| Q7 (mới) | NULL date columns 53–56% MV | 🟢 Low (expected) | Verified — UI date filter là implicit exclusion | Document trong spec |
| Q8 (mới) | NULL `khu_vuc_doi_xe` 16.3% Apr 2026 + NULL `ten_ngan_nha_van_tai` 6.9% | 🟡 Medium | Verified | UI fallback `'Unclassified'` cần verify hoạt động đúng |
| Q9 (mới) | Empty string `''` trong `group_name`, `loai_xe_van_hanh` không được coalesce | 🟢 Low | Verified | UI/SQL fix `nullIf('', col)` trước coalesce |

---

## 9. Release Plan

### Phase 1 — MVP

- ✅ 6 endpoints đã có (theo spec §2)
- 🔲 **Spec rewrite** — `shipping-progress.spec.md` đang lệch nặng (mô tả timeline/map/ETA không tồn tại). Phải rewrite trước khi dev sửa thêm.
- 🔲 BA confirm Q1 (pending negative policy), Q2 (threshold), Q5 (internal transfer scope)
- 🔲 DA verify Q1 (is_deleted), Q2 (UNION schema), Q3 (data exclusion)
- 🔲 DA cleanup BUG-1 (hardcoded date sql-registry.md:10620)

### Phase 2 — Post-MVP

- Auto-refresh interval
- Drill-down KPI → trip detail
- Status breakdown (New/Allocated/Picked/PartPick separate columns)
- Forecast end-of-day pending

### Phase 3 — Future

- ETA estimation (ML)
- Map view / GPS tracking
- Real-time loading timeline

---

## 10. Open Questions

1. **Pending negative policy** (BL-2): Nếu shipped CBM > original CBM (giao thừa), tính pending âm hay clamp 0?
2. **Threshold % Pending**: Logistics manager dùng ngưỡng nào để escalate? Khác nhau theo intraday vs end-of-day?
3. **Internal transfer orders**: Có thuộc scope OTIF/Shipping Progress không (CLAUDE.md Rule 4 yêu cầu loại — cần BA confirm áp dụng cho feature này)?
4. **Pivot dimension list**: Wireframe có 4 pivot (warehouse/area/operation_vehicle/cargo_group); có cần thêm theo Brand / Channel không?
5. **Status drill-down**: Phase 2 có cần show riêng count cho `New / Allocated / Picked / PartPick` để user biết stuck ở stage nào?

---

## 11. Cross-references

- Spec: `docs/02-features/tien_do_xuat_hang/shipping-progress.spec.md` *(⚠️ outdated — cần rewrite)*
- Wireframe: `docs/02-features/tien_do_xuat_hang/shipping-progress.wireframe.md` *(✅ aligned)*
- Audit: `docs/audit-results/s2-shipping-progress-20260507.md`
- SQL Registry: `docs/03-engineering/sql-registry.md` § "Tiến độ xuất hàng - verified" (10427–16320)
- DDL: `docs/03-engineering/data-sources/clickhouse-ddl/analytics-workspace_mvs.md`
  - `mv_flash_report` (line 2527)
  - `mv_dropped_report` (line 1461)
- Code:
  - UI: `control-tower/ui/src/views/control-tower/order-monitor/ShippingProgressView.tsx`
  - API: `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs`
- GLOSSARY: `docs/GLOSSARY.md`
