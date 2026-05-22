# PRD — Flash Daily Report

> **Status:** ✅ Active
> **Owner:** Control Tower Team
> **Last updated:** 2026-05-06
> **Source MV:** `analytics_workspace.mv_flash_report` (refresh 5'), `analytics_workspace.mv_flash_and_drop_report` (refresh 15'), `analytics_workspace.mv_dropped_report`

---

## 1. Overview

Flash Daily Report là màn hình theo dõi tiến độ xuất hàng trong ngày theo thời gian thực, thuộc module **Control Tower** của hệ thống W-PRED. Màn hình cung cấp snapshot nhanh (flash) về tình trạng toàn bộ Delivery Orders (DO) trong kỳ đã chọn — từ chưa xuất, đang xuất, đến đã vận chuyển — phân tích theo nhiều chiều: kho, kênh bán, khách hàng, khu vực giao hàng, và theo dõi đơn hàng bị rớt (dropped delivery).

Tài liệu liên quan:
- Spec kỹ thuật: [`flash-daily-report.spec.md`](flash-daily-report.spec.md)
- Wireframe: [`flash-daily-report.wireframe.md`](flash-daily-report.wireframe.md)
- Định nghĩa thuật ngữ: [`docs/GLOSSARY.md`](../../GLOSSARY.md)

---

## 2. Problem Statement

Trước khi có màn hình này, đội vận hành và quản lý kho phải tổng hợp thủ công từ nhiều báo cáo rời rạc (TMS, WMS) để trả lời câu hỏi cơ bản: **"Hôm nay đã xuất được bao nhiêu phần trăm?"** Quá trình này mất thời gian, dễ sai số, và không cho phép drilldown nhanh theo kho hay kênh bán khi có sự cố.

**Hệ quả cụ thể:**
- Không phát hiện kịp thời các đơn bị rớt hoặc bị chậm trễ.
- Quản lý không có cái nhìn tổng thể về hiệu suất xuất hàng theo thời gian thực.
- Khó so sánh tiến độ giữa các kho (BKD, NKD) và kênh bán (MT, GT, KA…) trong cùng một màn hình.

---

## 3. Target Users

| Người dùng | Vai trò | Tần suất sử dụng |
|---|---|---|
| Warehouse Manager | Theo dõi tiến độ xuất hàng toàn kho | Nhiều lần/ngày |
| Logistics Supervisor | Giám sát theo kênh, khu vực, khách hàng | 2–3 lần/ngày |
| Control Tower Analyst | Phân tích đơn rớt, báo cáo EOD | Cuối ngày |
| Senior Management | Xem KPI tổng hợp (snapshot nhanh) | 1 lần/ngày |

---

## 4. Goals & Success Metrics

### Mục tiêu

- Cung cấp **real-time visibility** về tiến độ xuất hàng trong ngày.
- Cho phép drilldown nhanh theo kho, kênh bán, khách hàng, khu vực.
- Phát hiện sớm đơn hàng bị rớt và nguyên nhân.
- Hỗ trợ export để chia sẻ báo cáo EOD.

### Định nghĩa thành công

| Metric | Target |
|---|---|
| Thời gian tải màn hình | < 3 giây với dữ liệu 1 ngày |
| Độ chính xác số liệu | 100% khớp với nguồn STM/SWM (sau khi áp exclusion rules) |
| Tỷ lệ sử dụng hàng ngày | ≥ 80% ngày làm việc có ít nhất 1 user active |
| Đơn rớt được phát hiện | 100% đơn có flag dropped hiển thị trong Dropped Delivery Report |

---

## 5. Functional Requirements

### 5.1 Must-Have

#### FR-01: KPI Summary Cards
Hiển thị 5 KPI cards tổng hợp trên đầu màn hình. Source: `mv_flash_and_drop_report` (đếm distinct `so`).

| KPI | Định nghĩa chính xác | Source |
|---|---|---|
| **Total DO** | `COUNT(DISTINCT so)` thuộc cả flash và dropped trong kỳ lọc | `mv_flash_and_drop_report` |
| **Đơn xuất** | `COUNT(DISTINCT so)` với `e2e_label IN ('Đã xuất kho', 'Đang vận chuyển', 'Đã vận chuyển')` | `mv_flash_and_drop_report` |
| **Đơn pending** | `COUNT(DISTINCT so)` với `e2e_label IN ('Chưa xuất kho', 'Đang xuất kho')` | `mv_flash_and_drop_report` |
| **Đơn rớt** | `COUNT(DISTINCT so)` với `e2e_label = 'Kế hoạch hủy'` | `mv_flash_and_drop_report` |
| **% Xuất** | `(Đơn xuất / Total DO) × 100`, chia 0 → trả 0 | derived |

> **Lưu ý invariant**: `Total DO = Đơn xuất + Đơn pending + Đơn rớt` (không trùng nhau, không thiếu). Backend phải đảm bảo công thức KPI card và "Done" của Summary Table (FR-06) dùng **cùng định nghĩa "đơn xuất" = 3 status** để tránh số liệu mâu thuẫn.

#### FR-02: Status Summary — Stacked Bar Chart
Biểu đồ cột thể hiện volume (theo UOM đã chọn) phân theo status chuẩn hóa. Source: `mv_flash_report.trang_thai_don_do`.

**Business intent (priority cao nhất):** Nếu xe đã đến NPP (`stm_ata_den IS NOT NULL`) → coi như **đã giao xong**, bất kể status SWM. Ngược lại fallback theo SWM status_code.

| Status hiển thị | Tiếng Anh | Màu | Điều kiện (multiIf, theo thứ tự) |
|---|---|---|---|
| Đã vận chuyển | Delivered | `#287819` (Green) | **Branch 1**: `(SWM='ShipCompleted' AND STM_status IN ('Đã giao hàng','Nhận 1 phần chứng từ','Đã nhận chứng từ'))` OR `stm_ata_den IS NOT NULL` |
| Chưa xuất kho | Not Shipped | `#858585` (Gray) | **Branch 2**: SWM `status = 'New'` |
| Đang xuất kho | Shipping | `#E18719` (Orange) | **Branch 3**: SWM `status IN ('PartAllocate','Allocated','PartPick','Picked','PartShipped')` |
| Đang vận chuyển | In Transit | `#2D6EAA` (Blue) | **Branch 4**: SWM `status = 'ShipCompleted'` AND `stm_thoi_gian_di IS NOT NULL` |
| Đã xuất kho | Shipped | `#4F2170` (Purple) | **Branch 5 (default)**: SWM `status = 'ShipCompleted'` |

**⚠️ Edge case (verify 2026-05-06):** 464 SO có `SWM='New'` + `stm_ata_den IS NOT NULL` → branch 1 chiếm trước → hiển thị **`'Đã vận chuyển'`** mặc dù SWM chưa pick.
- **Root cause:** kết hợp 3 yếu tố:
  1. `mv_flrp_stm_data` filter `sort_order IN (1, -1)` — **80% SO có multi-leg trip**
  2. `mv_flash_report` dùng `ANY LEFT JOIN` với mv_flrp_stm_data — chọn ngẫu nhiên 1 leg
  3. `ata_den` của leg trung gian (sort_order=1) đã có data trong khi SWM chưa ship từ kho
- **Theo intent (D1):** đây là behavior CỐ Ý — đã có dấu hiệu xe đến (bất kể stop trung gian hay cuối) thì coi như đã giao.
- **Implication cho user:** số SO "Đã vận chuyển" có thể bao gồm 1 phần đơn mới đến trạm trung chuyển, chưa đến NPP cuối. Acceptable cho Flash Report (snapshot nhanh), nhưng KHÔNG dùng cho OTIF accuracy.

**PartShipped business rule (theo BA 2026-05-06):**
- Nghiệp vụ: xe chỉ rời kho khi load xong (status='ShipCompleted'), không bao giờ rời kho lúc PartShipped.
- → Branch 4 (`Đang vận chuyển`) gần như không bao giờ áp dụng cho status = PartShipped → mapping `PartShipped → Đang xuất kho` (branch 3) là đúng nghiệp vụ.

#### FR-03: E2E Status Distribution
Biểu đồ phân bổ E2E status (6 nhãn), kèm tổng số SO distinct. Source: `mv_flash_and_drop_report.e2e_label`.

| E2E label | Hiển thị | Màu | Nguồn |
|---|---|---|---|
| Chưa xuất kho | Not Shipped | `#858585` | `mv_flash_report` |
| Đang xuất kho | Shipping | `#E18719` | `mv_flash_report` |
| Đã xuất kho | Shipped | `#4F2170` | `mv_flash_report` |
| Đang vận chuyển | In Transit | `#2D6EAA` | `mv_flash_report` |
| Đã vận chuyển | Delivered | `#287819` | `mv_flash_report` |
| **Kế hoạch hủy** | **Cancelled** | `#C53030` (Red) — đề xuất | `mv_dropped_report` (UNION) |

> **Lưu ý:** FR-02 chỉ có 5 status (không có "Kế hoạch hủy"), FR-03 có 6 label. Đây là khác biệt **cố ý** giữa "operational status" (đơn còn xử lý) và "end-to-end view" (bao gồm cả đơn hủy kế hoạch).

#### FR-04: Warehouse Progress
Bar chart ngang hiển thị tiến độ xuất hàng theo từng kho, kèm số DO đã xong / tổng DO và %.

#### FR-05: Dimension Breakdown
Cho phép drilldown theo 3 chiều (mỗi chiều là một tab/chart riêng):
- Theo **khách hàng** (Customer)
- Theo **khu vực giao hàng** (Delivery Area)
- Theo **kênh bán** (Sales Channel: MT, GT, KA, B2B, Export…)

#### FR-06: Summary Table (Table Detail tab)
Bảng chi tiết tổng hợp theo từng chiều (kho / khách hàng / khu vực / kênh bán) với cột: Plan (DO), Done (DO), Progress %.

#### FR-07: Dropped Delivery Report
- Danh sách DO bị rớt kèm kho và lý do rớt. Source: `mv_dropped_report` (filter `status = 'Cancel'`).
- Bảng thống kê lý do rớt (Dropped Reason Report) — group by `remark_2` (= `oh.notes2` của order header SWM).
- Bảng phụ "Bổ sung report hàng rớt" gồm 4 dòng:
  1. **Tổng kế hoạch CS book** = tổng flash + tổng dropped
  2. **Xử lý thành công** = SUM volume WHERE flash AND `status = 'ShipCompleted'`
  3. **Đang xử lý** = SUM volume WHERE flash AND `status <> 'ShipCompleted'`
  4. **Xử lý không thành công** = SUM volume WHERE dropped AND `status = 'Cancel'`
- Cột tách FRESH/DRY (CSE) vs POSM/OFFBOM (PC). Volume FRESH/DRY = `original_cse`, POSM/OFFBOM = `original_qty`.

#### FR-08: Bộ lọc đa chiều
Cho phép lọc theo (label phải đồng bộ với MV `mv_filter_date_type_flashreport`):

| Filter | Giá trị (UI label = SQL param) | Cột MV |
|---|---|---|
| **Date Type** | `Ngày GI`, `Actual Ship Date`, `ETD gửi thầu (đơn)`, `ATA đơn`, `ETA gửi thầu (đơn)` | xem mapping §6.2 |
| **Date Range** | từ ngày → đến ngày (default = hôm nay) | derived theo Date Type |
| **Group/Channel** | `ALL` + danh sách `mloc.channel` distinct (MT, GT, KA, B2B, Export, Other) | `t.group_name` |
| **Warehouse** | `ALL`, BKD1, BKD2, BKD3, BKD (rollup), NKD, VN821, VN831 | `t.whseid` (vật lý) hoặc `t.whseid_stm` (rollup) |
| **Brand** | `ALL` + danh sách `sku.brand` distinct (đề xuất verify) | `t.brand` |
| **Cargo Type** | `ALL`, FRESH, DRY, MOONCAKE, TET, POSM/OFFBOM, PM (giá trị thực từ `sku.group_of_cargo`) | `t.group_of_cago` |
| **Region** | `ALL` + danh sách `group_area.area_name` distinct (South East, Ho Chi Minh, Mekong 1, …) | `t.khu_vuc_doi_xe` |

**Lưu ý dữ liệu thực tế (2026-05-06):**
- `whseid` thực tế chỉ có data ở BKD1, BKD2 (gần như rỗng — 31 SO), BKD3, NKD. **VN821 / VN831** đã có trong filter MV nhưng **chưa có data thực** — UI cần handle "no data" gracefully.
- Brand list "Tết / Trung Thu" trong PRD cũ là **lỗi** — đây là `group_of_cargo` (TET, MOONCAKE), không phải brand. Brand list cần được rebuild bằng `SELECT DISTINCT brand FROM mv_flash_report` khi triển khai.
- Cargo Type "TEST", "EQUIPMENT" không xuất hiện trong data — chỉ giữ trong filter nếu upstream thực sự sinh ra.

Lọc chỉ áp dụng sau khi nhấn **Apply** (không auto-refresh).

#### FR-09: UOM Toggle
Cho phép đổi đơn vị đo giữa: `DO`, `CSE`, `TON`, `CBM`, `Pallet`. Tất cả KPI dùng cột `original_*` (planned từ SWM) — KHÔNG dùng `shipped_*` hay `san_luong_giao_*`.

| UOM | Công thức aggregate | Cột MV |
|---|---|---|
| `DO` | `COUNT(DISTINCT so)` | `t.so` |
| `CSE` | `SUM(original_cse)` | `t.original_cse` |
| `TON` | `SUM(original_kg) / 1000.0` | `t.original_kg` |
| `CBM` | `SUM(original_cbm)` | `t.original_cbm` |
| `Pallet` | `SUM(original_pl)` | `t.original_pl` |

- Tất cả chart và table cập nhật đồng thời theo UOM đã chọn.
- Format số:
  - `DO`, `CSE`: integer
  - `TON`, `CBM`, `Pallet`: 2 chữ số thập phân
- **DDL typo cần fix:** `mv_filter_uom` đang có `'TON' AS activity_name, 'TOB' AS code` — code phải là `'TON'`. Backend phải normalize trước khi compare.

#### FR-10: Export
Cho phép export các dataset sau sang Excel/CSV:
- Status Summary, Warehouse Progress, Customer Progress, Delivery Area, Sales Channel, E2E Distribution, Dropped Delivery, Dropped Reason.

### 5.2 Nice-to-Have

| ID | Mô tả |
|---|---|
| NFR-01 | Map tab: heatmap khu vực giao hàng trên bản đồ Việt Nam |
| NFR-02 | Auto-refresh theo interval (5–15 phút) |
| NFR-03 | Bộ lọc "Quick Date": Hôm nay / Hôm qua / Tuần này |

---

## 6. Data & Business Rules

### 6.1 Data Exclusion (BẮT BUỘC)

Mọi query đều phải áp dụng (đã enforce ở MV upstream):

| # | Rule | Implement |
|---|---|---|
| 1 | `is_deleted = 0` | `mv_flrp_swm_data`, `mv_flrp_stm_data`, `dim_*` upstream |
| 2 | Loại trừ cancelled orders (status_code IN ('1','2')) khỏi flash volume | `mv_flrp_swm_data WHERE oh.status_code NOT IN ('1','2')` — note: status_code='2' (Close) hiện **không xuất hiện** trong upstream data nên filter này thực tế chỉ loại Cancel ('1') |
| 3 | Đơn cancel hiển thị riêng dưới label "Kế hoạch hủy" | `mv_dropped_report` UNION trong `mv_flash_and_drop_report` |
| 4 | Chỉ orderdetail có `extern_order_key IS NOT NULL` | `mv_flrp_swm_data WHERE oh.extern_order_key IS NOT NULL` |
| 5 | Chỉ orders có `sync_status = 'SUCCESS'` hoặc rỗng | `mv_flrp_swm_data` |
| 6 | Bỏ qua trip có `status_id != 13` (vận hành) hoặc `= 13` (gửi thầu) tùy nhánh | `mv_flrp_stm_data` (2 alias trip + tender) |
| 7 | Date NULL hoặc `= '1970-01-01'` → trả NULL (không tính vào filter date) | `if((col IS NULL) OR (toDate(col) = '1970-01-01'), NULL, col)` |
| 8 | Chia cho 0 → trả `0` (không lỗi) | tất cả KPI |
| 9 | Split shipment (1 SO có lines vừa ship vừa cancel) — VALID, không dedupe | xem §6.10 |

### 6.10 Split shipment pattern (đơn hủy 1 phần SAP)

**Business pattern (theo BA 2026-05-06):** SAP có thể hủy 1 phần đơn (partial cancellation):
- **Hủy cả đơn:** SO `848xxxxxxx` → toàn bộ vào `mv_dropped_report` với `status='Cancel'`.
- **Hủy 1 phần:** SO gốc `848xxxxxxx` còn ship done (vào flash với `ShipCompleted`) + SO con `848xxxxxxx-SP001(-SP001…)` cho phần hủy (vào dropped với `Cancel`).
  - SO ID có thể giống nhau ở 2 MV (cùng `extern_order_key`) nếu mapping SP001 không tách prefix.

**Verify (2026-05-06):** 7 SO thực tế trùng giữa flash + dropped — toàn bộ là pattern này (`8481008170-SP001-SP001-...`, `BÙ TÚI 211122-...`).

**Hệ quả:**
- **KPI card** dùng `COUNT(DISTINCT so)` → đếm 1 lần / SO ✓ OK.
- **SUM volume** ở KPI card / chart có thể double-count cho 7 SO này (overlap nhẹ — ~0.0006% volume). **Không cần dedupe** — đây là pattern hợp lệ.
- **PRD chính sách:** giữ nguyên `UNION ALL`, accept overlap nhỏ. Nếu DA muốn fix thì add `WHERE so NOT IN dropped` ở flash branch — nhưng không recommended vì sẽ làm mất phần đã ship của SO partial-cancel.

### 6.2 Date Type → Cột MV (mapping)

| UI label (DDL `mv_filter_date_type_flashreport`) | SQL param `p_loai_ngay` | Cột MV được filter |
|---|---|---|
| `Ngày GI` | `'GI date'` | `delivery_date_1` |
| `Actual Ship Date` | `'Actual Ship date'` | `actual_ship_date` |
| `ETD gửi thầu (đơn)` | `'ETD gửi thầu'` | `etd_chuyen_gui_thau` ⚠ (SQL hiện đang trỏ nhầm vào `delivery_date_1` — xem BUG-2 §11) |
| `ATA đơn` | `'ATA đơn'` | `ata_den` |
| `ETA gửi thầu (đơn)` | `'ETA gửi thầu'` | `eta_giao_hang_cho_npp` |

> **Convention bắt buộc:** Backend phải duy trì 1 bảng dịch UI label ↔ SQL param. Tránh hard-code chuỗi tiếng Việt phía FE.

### 6.3 KPI công thức

| KPI | Công thức | Note |
|---|---|---|
| `Total DO` | `COUNT(DISTINCT so)` từ `mv_flash_and_drop_report` | scope = flash + dropped |
| `Đơn xuất` | `COUNT(DISTINCT so) WHERE e2e_label IN ('Đã xuất kho','Đang vận chuyển','Đã vận chuyển')` | 3 status |
| `Đơn pending` | `COUNT(DISTINCT so) WHERE e2e_label IN ('Chưa xuất kho','Đang xuất kho')` | 2 status |
| `Đơn rớt` | `COUNT(DISTINCT so) WHERE e2e_label = 'Kế hoạch hủy'` | 1 label |
| `% Xuất` | `Đơn xuất / Total DO × 100` | chia 0 → 0 |
| `Done volume` (Summary Table FR-06) | `SUM(volume_value WHERE e2e_label IN ('Đã xuất kho','Đang vận chuyển','Đã vận chuyển'))` | **PHẢI cùng định nghĩa với "Đơn xuất"** |
| `Pending volume` (Summary Table) | `SUM(volume_value)` − `Done volume` | derived |
| `% Progress` (Dimension) | `Done volume / Total volume × 100` | chia 0 → 0 |

> ⚠️ **SQL hiện tại có BUG** ở Summary Table — đang chỉ count `'Đã vận chuyển'` (1 status). Xem BUG-1 §11.

### 6.4 Hardcoded business filters (ở MV upstream)

DA/QA cần biết các filter này khi đối soát số liệu:

**SWM (`mv_flrp_swm_data`):**
- `od.storer_key = 'MDLZ'` AND `od.is_deleted = 0`
- `od.whseid IN ('BKD1','BKD2','BKD3','NKD','VN821','VN831')`
- Order types theo whseid:
  - NKD: `('01','07','08','09','240','XB2BMC','XTNPP')`
  - BKD: `('01','240')`
- `oh.status_code NOT IN ('1','2')` (loại Cancel + Close)
- `oh.extern_order_key IS NOT NULL`
- `od.order_key IS NOT NULL`
- `oh.sync_status = 'SUCCESS'` hoặc rỗng

**STM (`mv_flrp_stm_data`):**
- `ord.is_deleted = 0`
- `ord.service_name = 'Xuất bán'`
- `ord.customer_id = '9'` (Mondelez)
- `opg.code_sync IS NOT NULL` AND `trim(opg.code_sync) <> ''`
- `dtd.is_deleted = 0` AND `dtd.sort_order IN (1, -1)` (chỉ leg đầu hoặc cuối multi-leg)
- `trip.status_id != 13` (alias `trip` = vận hành) ; `tender.status_id = 13` (alias `tender` = gửi thầu)
- `dim_ops_dock_register`: lấy `argMax(loading_end, register_date)` → `gio_ra_dock`

**JOIN khóa flash:**
- `swm.so = stm.ma_don_hang` AND `swm.orderlinenumber = stm.line_no`
- `line_no` STM = `LEFT(opg.code_sync, length(code_sync) - 1)` (bỏ ký tự cuối)
- JOIN type = **`ANY LEFT JOIN`** — nếu 1 line SWM khớp với nhiều STM trip leg, ClickHouse chọn **ngẫu nhiên 1 leg** giữ lại. Không deterministic.

**Multi-leg trip note (verify 2026-05-06):**
- Distribution `sort_order` trong `dim_ops_trip_detail`: `-1` (2.34M rows), `0` (992K), `1` (990K), `2` (995K).
- `mv_flrp_stm_data` filter `sort_order IN (1, -1)` → **giữ leg đầu (sort=1) và leg cuối/single (sort=-1)**, loại leg trung gian (sort=0,2).
- **80% SO có multi-leg trip** (990K / 1.25M distinct SO).
- → 1 SO multi-leg có thể có 2 STM record (sort=1 và sort=-1) → `ANY LEFT JOIN` ở mv_flash_report chọn 1 trong 2 → giá trị `ata_den`, `eta_giao_hang_cho_npp`, `etd_chuyen_gui_thau` không deterministic giữa các lần MV refresh.
- **Implication:** Date filter ATA/ETA/ETD có thể inconsistent giữa các phiên xem; status mapping "Đã vận chuyển" có thể fire dựa trên ATA của trạm trung gian thay vì NPP cuối.

### 6.5 Volume — 3 layer khác nhau (BẮT BUỘC phân biệt)

| Layer | Cột MV | Nguồn | Khi nào dùng |
|---|---|---|---|
| **Planned** | `original_qty`, `original_cse`, `original_cbm`, `original_kg`, `original_pl` | SWM `dim_orderdetail.original_qty` × hệ số quy đổi | KPI Flash Report (FR-01 → FR-06), Summary Table |
| **Actual SWM** | `shipped_qty`, `shipped_cse`, `shipped_cbm`, `shipped_kg`, `shipped_pl` | SWM `dim_pickdetail.qty` × hệ số quy đổi | "Bổ sung report hàng rớt" — dòng "Xử lý thành công" |
| **Actual STM (BBGN)** | `san_luong_giao_*` (các biến CSE / PALLET / PCE và đã quy đổi) | STM `dim_ops_trip_detail.quantity_bbgn` (Biên bản giao nhận) | Hiện chưa dùng trong Flash Report — exposed cho future use |

> **UOM convention (xác nhận với DA team 2026-05-06):** `od.original_qty` và `gp.shipped_qty` LUÔN ở **masterunit (PCE/EA)** trong toàn bộ data. Công thức quy đổi giả định convention này:
> - `original_cse = original_qty / masterunit_per_cse`
> - `original_pl = original_qty / masterunit_per_pallet`
> - `original_cbm = original_qty * cbm_per_masterunit`
> - `original_kg = original_qty * kg_per_masterunit`
>
> Hệ số quy đổi: `cbm_per_masterunit`, `kg_per_masterunit`, `masterunit_per_cse`, `masterunit_per_pallet` từ `mv_masterdata_sku`.

### 6.6 Warehouse hierarchy

**Business intent (theo Operations team — verify 2026-05-06):**
| Kho vật lý | Rollup vào |
|---|---|
| BKD1, BKD2, BKD3, **VN821** (Kho BEE_BKD) | **BKD** |
| NKD, **VN831** (Kho ngoài-NKD) | **NKD** |

→ Báo cáo EOD đang gộp VN821 vào BKD và VN831 vào NKD.

**Implementation thực tế (current SQL):**
| Cột MV | Giá trị thực |
|---|---|
| `t.whseid` | BKD1, BKD2, BKD3, NKD (4 — VN821/VN831 KHÔNG có data trong MV mặc dù upstream có) |
| `t.whseid_stm` | BKD (= BKD1/BKD2/BKD3), NKD (= NKD) — chỉ rollup được 4 kho |

> ⚠️ **Có gap giữa intent và implementation** — xem **BUG-6 §11**:
> - SQL `mv_flrp_swm_data` line 2910 có WHERE clause cho VN821/VN831 (`whseid IN (..., 'VN821', 'VN831')`) nhưng **order type filter chỉ cover NKD và BKD1/2/3**, không có nhánh cho VN821/VN831 → các SO này bị **implicit drop** khỏi flash MV.
> - Upstream `swm_dwh_mondelez.dim_orderdetail` có 6,740 distinct order ở VN821 và 8,720 ở VN831 (verify 2026-05-06) — đang bị mất khỏi Flash Report.
> - Rollup `whseid_stm` cũng chưa cover VN821→BKD và VN831→NKD trong SQL.

### 6.7 Filter ↔ Cột MV (cheatsheet)

| UI Filter | Cột MV | Source upstream | NULL handling |
|---|---|---|---|
| Date Type + Date Range | xem §6.2 | — | NULL date → loại khỏi date range (không hiện ở mọi chart) |
| Group/Channel | `t.group_name` | `mloc.channel` từ `mv_masterdata_location` (consignee) | NULL → bucket `'Unclassified'` |
| Warehouse | `t.whseid` | `dim_orderdetail.whseid` | exact match (không Unclassified) |
| Brand | `t.brand` | `mv_masterdata_sku.brand` | NULL → bucket `'Unclassified'` |
| Cargo Type | `t.group_of_cago` | `mv_masterdata_sku.group_of_cargo` | NULL → bucket `'Unclassified'` |
| Region | `t.khu_vuc_doi_xe` | `group_area.area_name` (theo customer_code) | NULL → bucket `'Unclassified'` |

**NULL filter behavior (theo BA 2026-05-06):**
- SQL hiện tại: `COALESCE(t.<col>, 'Unclassified') = p.p_<col>` — khi user filter cụ thể (vd Brand=`Solite`), SO có `brand=NULL` (tức bucket `'Unclassified'`) **bị ẩn hoàn toàn** khỏi kết quả.
- → Trong UI dropdown filter, **không** expose option `'Unclassified'` cho user chọn riêng (per BA decision).
- Khi filter = `'ALL'`, tất cả SO (kể cả NULL) đều xuất hiện, chia bucket `'Unclassified'` trong chart.

### 6.8 ETD Auto-Switch (cần verify implementation)
- **Spec:** Sau 15:00 hệ thống tự động chuyển sang dữ liệu của ngày hôm sau (áp dụng khi Date Type = `ETD gửi thầu (đơn)`).
- **Implementation:** không có trong SQL Registry — phải nằm ở `CTowerController.cs` (BE) hoặc `FlashDailyView.tsx` (FE).
- **Open Question Q3:** verify chỉ áp dụng cho ETD hay tất cả Date Type. Xem §10.

### 6.9 Refresh cadence
- `mv_flash_report`: **REFRESH EVERY 5 MINUTE**
- `mv_flash_and_drop_report`: **REFRESH EVERY 15 MINUTE**
- `mv_flrp_swm_data`, `mv_flrp_stm_data`: 5 phút
- → Số liệu E2E (FR-03, FR-07) trễ tối đa **15 phút** so với source. UI nên hiển thị "Last updated" timestamp.

---

## 7. Out of Scope

- Chỉnh sửa hay cập nhật trạng thái đơn hàng (read-only).
- Tích hợp real-time websocket (dùng manual refresh hoặc auto-poll).
- Lịch sử thay đổi trạng thái đơn (chỉ xem trạng thái hiện tại).
- Phân tích OTIF, VFR — thuộc các màn hình riêng trong Order Monitor.
- Forecast hay dự báo — thuộc module Warehouse Prediction.

---

## 8. Dependencies

| Dependency | Mô tả | Refresh |
|---|---|---|
| STM ClickHouse (`stm_dwh_mondelez.*`) | Order, trip, tender, dock register | CDC realtime |
| SWM ClickHouse (`swm_dwh_mondelez.*`) | Order header/detail, pickdetail | CDC realtime |
| `analytics_workspace.mv_flrp_swm_data` | SWM transformation layer | 5 min |
| `analytics_workspace.mv_flrp_stm_data` | STM transformation layer | 5 min |
| `analytics_workspace.mv_flash_report` | Master MV cho FR-02, FR-04, FR-05, FR-06 | 5 min |
| `analytics_workspace.mv_dropped_report` | Đơn cancelled (label `'Kế hoạch hủy'`) | 5 min |
| `analytics_workspace.mv_flash_and_drop_report` | UNION flash + dropped, expose `e2e_label` cho FR-01, FR-03, FR-07 | 15 min |
| `analytics_workspace.mv_filter_*` | Dropdown sources: date_type, warehouse, region, uom, vendor | static/CDC |
| `analytics_workspace.mv_masterdata_sku` | Brand, group_of_cargo, hệ số quy đổi UOM | CDC |
| `analytics_workspace.mv_masterdata_location` | Customer info, channel, region | CDC |
| `CTowerController.cs` | API backend cho tất cả endpoints Flash Report | — |
| `FlashDailyView.tsx` | UI component chính | — |
| `GLOSSARY.md` → Flash Report, DO, UOM, BBGN | Định nghĩa thuật ngữ chuẩn | — |

---

## 9. Business Workflow

### 9.1 Luồng sử dụng trong ngày (Daily Operations Cycle)

```
06:00 — Đầu ca sáng (K1)
  Warehouse Manager mở Flash Daily Report
  → Chọn Date = hôm nay, Date Type = GI date
  → Xem KPI cards: Total DO / % Xuất / Đơn pending / Đơn rớt
  → Mục tiêu: nắm tổng thể kế hoạch xuất hàng trong ngày

Trong ca (cứ 2–3 tiếng/lần)
  Logistics Supervisor theo dõi tiến độ
  → Filter theo Warehouse (BKD / NKD) hoặc Channel (MT / GT / KA)
  → Xem Warehouse Progress chart → kho nào đang chậm?
  → Xem Customer Progress → khách hàng nào chưa được xuất?
  → Nếu phát hiện % Xuất thấp bất thường → xem Dropped Delivery Report

Khi có đơn bị rớt
  Control Tower Analyst mở tab Dropped Delivery
  → Xem danh sách DO bị rớt theo kho
  → Xem Dropped Reason Report → nhóm lý do phổ biến
  → Phối hợp với kho để xử lý hoặc reschedule

18:00 — Cuối ngày (EOD)
  Control Tower Analyst xuất báo cáo
  → Click Export → tải file Excel với đầy đủ 8 sheet
  → Gửi báo cáo EOD cho Management
  → Senior Management xem KPI cards (% Xuất, Đơn rớt) → đánh giá ngày
```

### 9.2 Luồng theo vai trò (Role-based Flow)

| Vai trò | Bước 1 | Bước 2 | Bước 3 | Output |
|---|---|---|---|---|
| **Warehouse Manager** | Mở màn hình đầu ca | Xem KPI cards tổng thể | Filter theo kho cụ thể | Nắm tiến độ, điều phối nhân lực |
| **Logistics Supervisor** | Filter theo kênh / khu vực | Xem Dimension Breakdown | Phát hiện bottleneck | Hành động điều chỉnh kế hoạch |
| **Control Tower Analyst** | Theo dõi Dropped Delivery | Phân tích Dropped Reason | Export báo cáo EOD | File báo cáo gửi lên Management |
| **Senior Management** | Mở màn hình 1 lần/ngày | Xem KPI summary (% Xuất) | Không cần drilldown | Snapshot nhanh để ra quyết định |

### 9.3 Luồng xử lý đơn rớt (Dropped Delivery Handling)

```
Hệ thống phát hiện DO có flag dropped
  → Hiển thị trong KPI card "Đơn rớt" (số lượng tăng)
  → DO xuất hiện trong bảng Dropped Delivery Report (kho + lý do)
  → Thống kê tổng hợp trong Dropped Reason Report

Control Tower Analyst nhìn thấy:
  → Lý do phổ biến nhất (ví dụ: xe không đến, hàng thiếu, địa chỉ sai)
  → Kho nào có tỷ lệ rớt cao nhất
  → Export danh sách → gửi cho team logistics xử lý

Lưu ý: Hệ thống chỉ READ-ONLY.
  Việc cập nhật trạng thái đơn thực hiện trực tiếp trên TMS/WMS.
  Flash Report sẽ phản ánh thay đổi sau lần refresh tiếp theo.
```

### 9.4 Điều kiện đặc biệt

| Tình huống | Hành vi hệ thống | Người dùng cần làm gì |
|---|---|---|
| Sau 15:00, Date Type = ETD | Auto-switch sang ngày mai (verify §6.8 / Q3) | Kiểm tra lại date range nếu cần xem hôm nay |
| Dữ liệu chưa cập nhật | Số liệu có thể chưa phản ánh thực tế (MV flash 5', flash+drop 15') | Chờ pipeline chạy hoặc nhấn Apply để refresh (UI hiện không auto-refresh — phụ thuộc vào MV refresh) |
| Kho không có đơn (vd VN821/VN831) | Chart hiển thị trống. **Cảnh báo:** VN821/VN831 có data ở upstream nhưng đang bị MV drop (xem BUG-6) | DA verify lại sau khi fix |
| Đơn cancelled (`status_code = '1'`) | KHÔNG vào `mv_flash_report`. Vào `mv_dropped_report` với label `'Kế hoạch hủy'` → tính vào **Total DO** và KPI **Đơn rớt** | Không cần action |
| Đơn `Close` (status_code='2') | Theoretically loại khỏi cả flash và dropped, nhưng **không xuất hiện trong upstream data thực** (verify 2026-05-06) | Không impact thực |
| Split shipment (đơn hủy 1 phần SAP) | SO có cả lines ShipCompleted (flash) AND Cancel (dropped). 7 SO thực tế. UNION ALL không dedupe (xem §6.10). | Không cần action — pattern hợp lệ |
| `delivery_date_1 = '1970-01-01'` hoặc NULL | Không filter được theo Date Type GI date — bị loại khỏi date range. **Tỷ lệ NULL rất cao**: 27% SO toàn MV (44% với status `'Đã xuất kho'`, 32% NKD, 20% BKD1) | Khi filter bằng GI date, hiểu rằng mất khoảng 1/4 SO. Đề xuất dùng `Actual Ship Date` cho data lịch sử nếu cần đầy đủ. UI nên hiển thị badge "X SO loại do thiếu date". |
| 1 SO span nhiều warehouse | Có 32 SO thực tế. Filter Warehouse cụ thể chỉ lấy 1 phần lines. Sum KPI per-warehouse > Total DO. | Accept partial count — note trong báo cáo EOD nếu liên quan |

---

## 10. Open Questions

| # | Câu hỏi | Người cần trả lời | Trạng thái |
|---|---|---|---|
| Q1 | Map tab (heatmap) có nằm trong scope hiện tại không? | Product Owner | ⏳ Chờ |
| Q2 | Auto-refresh interval — UI hiện không auto-refresh, phụ thuộc MV refresh (5'/15'). Có cần thêm UI auto-poll không? | Dev Lead | ⏳ Chờ |
| Q3 | ETD auto-switch sau 15:00: (a) chỉ apply khi date range = "Hôm nay" default, (b) override user-selected date, (c) popup confirm, (d) đổi label hiển thị. Implement ở BE hay FE? | BA + Dev Lead | 🟡 ĐANG CHỜ BA — xem §6.8 |
| Q4 | "Done" của Summary Table (FR-06) phải align với "Đơn xuất" của KPI card (3 status) hay chỉ 1 status `'Đã vận chuyển'`? | BA + Product Owner | 🔴 BUG-1 — cần chốt gấp |
| Q5 | Brand filter list chính thức là gì? (loại "Tết / Trung Thu" khỏi PRD cũ vì là cargo type) | Product Owner | ⏳ Chờ — DA chạy `SELECT DISTINCT brand` |
| Q6 | VN821, VN831 — Operations confirm cần rollup vào BKD/NKD và đã có data ở upstream (6.7K + 8.7K orders). DA fix BUG-6 khi nào? | DA + Operations | 🔴 BUG-6 — cần fix |
| Q7 | Có cần expose `san_luong_giao_*` (BBGN) lên UI Flash Report không, hay chỉ giữ ở Tiến độ xuất hàng? | Product Owner | ⏳ Chờ |
| Q8 | "Bổ sung report hàng rớt" có cần thêm cột "Other (CSE)" cho cargo MOONCAKE/TET/PM không, hay chỉ FRESH/DRY + POSM/OFFBOM là đủ? | BA + Product Owner | 🟡 ĐANG CHỜ BA |
| Q9 | Định nghĩa **Đơn rớt** chính thức = chỉ Cancel? Hay còn case khác (đơn không xuất kịp cut-off, hủy chuyến cuối, đổi NPP)? | BA — đã trả lời = chỉ Cancel ✓ | ✅ Resolved 2026-05-06 |
| Q10 | KPI card (15min refresh) vs charts (5min refresh) có thể desync. Endpoint nào dùng MV nào? Cần align cùng MV không? | Dev Lead + BA | ⏳ Chờ — verify code |
| Q11 | UI hiển thị badge "X SO bị loại do thiếu date" khi filter GI date có data NULL — có cần implement không? | BA + FE | ⏳ Chờ |

---

## 11. Known Issues (BUGs cần fix)

| ID | Mức độ | Mô tả | Vị trí | Impact |
|---|---|---|---|---|
| **BUG-1** | 🔴 HIGH | Summary Table `done_volume = SUM WHERE trang_thai_don_do = 'Đã vận chuyển'` (1 status) — KHÁC định nghĩa "Đơn xuất" KPI card (3 status) | `sql-registry.md` § "Báo cáo tổng hợp theo kho/NPP/khu vực/kênh" | KPI card vs bảng cho 2 con số khác nhau cùng filter |
| **BUG-2** | 🔴 HIGH | Date Type "ETD gửi thầu" filter trỏ nhầm `delivery_date_1` thay vì `etd_chuyen_gui_thau` | All Flash Report queries trong `sql-registry.md` | Filter "ETD gửi thầu" cho ra cùng kết quả với "GI date" |
| **BUG-6** | 🔴 HIGH | `mv_flrp_swm_data` order type filter chỉ cover NKD và BKD1/2/3, **không cover VN821/VN831** → 6,740 + 8,720 distinct order ở upstream bị implicit drop. Operations đã confirm cần rollup VN821→BKD, VN831→NKD. | `analytics-workspace_mvs.md` § `mv_flrp_swm_data` line ~2910 | Báo cáo EOD thiếu data 2 kho — số liệu không khớp với báo cáo Operations |
| **BUG-3** | 🟡 MEDIUM | "Bổ sung report lý do rớt" dùng `original_cbm` cho cột `"FRESH/DRY (CSE)"` → sai unit | `sql-registry.md` line ~10349 | Số liệu Dropped Reason FRESH/DRY sai 1-2x |
| **BUG-7** | 🟡 MEDIUM (data integrity) | `ANY LEFT JOIN` ở `mv_flash_report` với `mv_flrp_stm_data` → 1 line SWM khớp nhiều STM trip leg (sort_order=1 và -1) sẽ chọn ngẫu nhiên 1 leg. Status mapping `'Đã vận chuyển'` (branch 1 OR `ata_den IS NOT NULL`) có thể fire dựa trên ATA của trạm trung gian. | DDL `mv_flash_report` line ~2637 | 80% SO multi-leg, ~464 SO bị status='New' nhưng map 'Đã vận chuyển'. Theo intent (D1) là CỐ Ý nhưng kết quả không deterministic giữa MV refreshes. |
| **BUG-4** | 🟢 LOW | DDL `mv_filter_uom` có `'TON' AS activity_name, 'TOB' AS code` — typo | `analytics-workspace_mvs.md` § `mv_filter_uom` | UI gửi UOM theo code không match dropdown |
| **BUG-5** | 🟢 LOW | Date Type label inconsistency: UI dùng `'Ngày GI', 'ETD gửi thầu (đơn)', 'ETA gửi thầu (đơn)'` — SQL CASE so với `'GI date', 'ETD gửi thầu', 'ETA gửi thầu'`. Backend đã có mapping trong câu query chart. | DDL `mv_filter_date_type_flashreport` ↔ SQL params | Mapping hoạt động (E2 confirmed), nhưng documentation gap |

**Đã resolved trong PRD:**
- ✅ "Đơn rớt = chỉ Cancel" (theo BA — Q9)
- ✅ "PartShipped → Đang xuất kho" là đúng nghiệp vụ (theo BA — B1: xe chỉ rời kho khi load xong)
- ✅ Volume = `original_qty` luôn ở masterunit (theo DA — D4)
- ✅ NULL filter ẩn hoàn toàn khi user chọn cụ thể (theo BA — B5)
- ✅ Default Date Type = GI date (theo BA — B6) + warning trong UI về NULL
- ✅ Split shipment pattern (đơn hủy 1 phần SAP, hậu tố `-SP001-...`) là VALID, không dedupe — theo BA (B2) + verify (D2)

> Audit chi tiết:
> - S2 (Data Pipeline): `docs/audit-results/s2-flash-daily-report-20260506.md`
> - S1 (BA Logic Check): `docs/audit-results/s1-flash-daily-report-20260506.md`

