# PRD — Late Order Alert

> **Status:** ✅ Active
> **Owner:** Control Tower Team
> **Last updated:** 2026-05-06
> **Source MV:** `analytics_workspace.mv_alert_late_do` (refresh 5'), `mv_alert_late_do_so_pick`, `mv_alert_late_do_concat`, `mv_alert_late_do_base`

---

## 1. Overview

Late Order Alert là màn hình giám sát trạng thái trễ hạn của đơn hàng theo thời gian thực, thuộc module **Control Tower > Order Monitor**. Hệ thống phân loại từng **chuyến (trip)** thành **7 trạng thái cảnh báo** chia 2 nhóm:
- **Real-time alerts** (3 status: `Normal`, `At Risk`, `Late Departure Open`) — cảnh báo cho trip đang còn trong kho, dựa trên `now64()` so với `tg_bat_buoc_roi_kho`.
- **Historical** (4 status: `Late Departure`, `Ontime Departure`, `Ontime Delivery`, `Late Delivery`) — đánh giá trip đã rời cổng hoặc đã hoàn tất.

Hiển thị dạng scorecard KPI, pie chart phân bổ, bar chart drilldown, và bảng chi tiết Trip.

Tài liệu liên quan:
- Spec kỹ thuật: [`late-order-alert.spec.md`](late-order-alert.spec.md)
- Wireframe: [`late-order-alert.wireframe.md`](late-order-alert.wireframe.md)
- Định nghĩa thuật ngữ: [`docs/GLOSSARY.md`](../../GLOSSARY.md)
- Audit S2 (data pipeline): [`docs/audit-results/s2-late-order-alert-20260506.md`](../../audit-results/s2-late-order-alert-20260506.md)
- Audit S1 (BA logic): [`docs/audit-results/s1-late-order-alert-20260506.md`](../../audit-results/s1-late-order-alert-20260506.md)

---

## 2. Problem Statement

Đội vận hành và logistics hiện không có công cụ tập trung để theo dõi đơn hàng nào đang có nguy cơ trễ hay đã trễ xuất kho/giao hàng. Việc phát hiện trễ đang được thực hiện thủ công qua TMS, dẫn đến:

- Phản ứng chậm khi đơn bắt đầu có dấu hiệu trễ (At Risk).
- Không có phân loại rõ ràng giữa trễ xuất kho (Late Departure) và trễ giao hàng (Late Delivery).
- Khó biết tổng thể tỷ lệ đơn đúng hạn vs trễ trong ngày để báo cáo management.
- Không drilldown được theo kho, khu vực, kênh bán, hoặc nhà vận tải để tìm nguyên nhân.

---

## 3. Target Users

| Người dùng | Vai trò | Tần suất sử dụng |
|---|---|---|
| Logistics Supervisor | Theo dõi trip trễ, điều phối xử lý kịp thời | Nhiều lần/ngày |
| Control Tower Analyst | Phân tích nguyên nhân trễ theo kho/kênh/transporter | 2–3 lần/ngày |
| Warehouse Manager | Nắm tổng thể tỷ lệ đơn Late Departure từ kho của mình | 1–2 lần/ngày |
| Senior Management | Xem KPI tổng hợp (% đúng hạn, số đơn trễ) | 1 lần/ngày |

---

## 4. Goals & Success Metrics

### Mục tiêu

- Cung cấp visibility real-time về trạng thái trễ hạn của từng chuyến.
- Phân loại rõ ràng 7 trạng thái để đội vận hành ưu tiên xử lý đúng chỗ.
- Cho phép drilldown theo kho, khu vực giao hàng, kênh bán, nhà vận tải.
- Hỗ trợ export để báo cáo EOD và theo dõi lịch sử.

### Định nghĩa thành công

| Metric | Target |
|---|---|
| Thời gian tải màn hình | < 3 giây với dữ liệu 1 ngày |
| Độ chính xác phân loại trạng thái | 100% khớp với logic TMS/STM |
| Tỷ lệ sử dụng hàng ngày | ≥ 80% ngày làm việc có ít nhất 1 user active |
| Phát hiện At Risk | Alert real-time được tính dựa trên dữ liệu MV (refresh 5'). Trip phải có `tg_bat_buoc_roi_kho` để fire — xem §6.10. |

---

## 5. Functional Requirements

### 5.1 Must-Have

#### FR-01: KPI Scorecard Cards (8 cards = 1 total + 7 status)

| KPI | Định nghĩa | Source |
|---|---|---|
| **Tất cả** | `COUNT(DISTINCT so_chuyen)` toàn bộ trip trong kỳ lọc | `mv_alert_late_do` |
| **Normal** | `COUNT(DISTINCT so_chuyen) WHERE alert_status = 'Normal'` | — |
| **At Risk** | `COUNT(DISTINCT so_chuyen) WHERE alert_status = 'At risk'` | — |
| **Late Departure Open** | `COUNT(DISTINCT so_chuyen) WHERE alert_status = 'Late departure open'` | — |
| **Late Departure** | `COUNT(DISTINCT so_chuyen) WHERE alert_status = 'Late departure'` | — |
| **Ontime Departure** | `COUNT(DISTINCT so_chuyen) WHERE alert_status = 'Ontime departure'` | — |
| **Ontime Delivery** | `COUNT(DISTINCT so_chuyen) WHERE alert_status = 'Ontime delivery'` | — |
| **Late Delivery** | `COUNT(DISTINCT so_chuyen) WHERE alert_status = 'Late delivery'` | — |

> **Invariant:** `Tất cả ≈ Σ (7 status counts)` — 7 status là **mutually exclusive** (không trùng nhau). Có thể có chênh lệch nhỏ do `alert_status = NULL` hoặc `'N/A'` (trường hợp thiếu dữ liệu). Verify thực tế: 0 NULL row, 4 row N/A.

#### FR-02: Pie Chart — Phân bổ trạng thái
Biểu đồ tròn 7 trạng thái với công thức:
```
% = COUNT(DISTINCT so_chuyen WHERE alert_status = X) / COUNT(DISTINCT so_chuyen) × 100
```
- Mẫu số = `Tất cả` (KPI card đầu tiên).
- Tổng % = 100% (vì 7 status mutually exclusive — trừ phần N/A nếu có).

#### FR-03: Bar Chart — Drilldown 4 chiều
Bar chart với **dropdown chọn dimension** (1 chart, 4 lựa chọn):
- **Warehouse** (`whseid`)
- **Khu vực giao hàng** (`khu_vuc_doi_xe`) — đồng nghĩa với "khu vực đội xe" trong DDL
- **Sales Channel** (`group` / `channel`)
- **Transporter** (`ten_ngan_nvt`)

Mỗi bar chia stack theo 7 alert_status.

#### FR-04: Bảng chi tiết Trip
Grain: **1 row = 1 trip** (`so_chuyen`). Nhiều DO trong 1 trip được concat thành chuỗi `ds_ma_don_trong_chuyen` (giới hạn 120 SO/trip — quá thì truncate).

**Hiển thị TẤT CẢ 47 cột** của `mv_alert_late_do`. Phân group:

| Group | Cột |
|---|---|
| Identity | `so_chuyen`, `whseid`, `ds_ma_don_trong_chuyen` |
| Trip status | `trang_thai_chuyen` (10 nhãn — xem §6.2), `trang_thai_chuyen_stm`, `alert_status` (7 nhãn) |
| Dimensions | `group_of_cago`, `group` (channel), `customer_code`, `customer_name`, `khu_vuc_doi_xe`, `ten_ngan_nvt`, `ma_doi_tac_nhan`, `ten_doi_tac_nhan`, `ma_nha_xe` |
| Vehicle | `so_xe`, `tai_xe` |
| Timeline (planning) | `request_date`, `approved_date`, `thoi_gian_gui_thau`, `ngay_tao_chuyen`, `etd_chuyen_gui_thau`, `etd_chuyen`, `eta_chuyen`, `eta_giao_hang_cho_npp`, `tg_bat_buoc_roi_kho` |
| Timeline (operation) | `gio_dang_tai`, `gio_goi_xe`, `gio_vao_cong`, `gio_vao_dock`, `gio_ra_dock`, `gio_ra_cong` (= ATD Actual), `actual_ship_date` |
| Timeline (delivery) | `atd_chuyen`, `ata_den`, `ata_roi`, `ata_chuyen` |
| Volume — Plan | `sum_original`, `sum_original_cbm`, `sum_original_kg`, `sum_original_cse`, `sum_original_pl` |
| Volume — Pick (SWM) | `sum_shipped`, `sum_shipped_cbm`, `sum_shipped_kg`, `sum_shipped_cse`, `sum_shipped_pl` |
| Volume — Giao BBGN (STM) | `sum_san_luong_giao`, `sum_san_luong_giao_cbm`, `sum_san_luong_giao_kg`, `sum_san_luong_giao_cse`, `sum_san_luong_giao_pl` |
| Volume — Diff | `diff_sl_giao_cho`, `diff_sl_giao_cho_cbm`, `diff_sl_giao_cho_kg`, `diff_sl_giao_cho_cse`, `diff_sl_giao_cho_pl` |
| Time metrics | `total_time_in_warehouse_minute`, `total_time_loading_minute`, `diff_delivery_time_hour` |
| Late reasons | `phut_tre_roi_kho` (concat phút trễ rời kho per DO), `phut_tre_giao_npp` (concat phút trễ giao per DO), `ly_do_tre_hoan_thanh` (chỉ cho `Late delivery` + `Đã giao/đã hoàn thành`) |
| Distance | `so_km`, `van_toc` |

> **"ATD Actual" = `gio_ra_cong`** (xe thực sự rời cổng — từ dock register). KHÔNG dùng `atd_chuyen` (ATD trip header — BA duyệt).

#### FR-05: Bộ lọc đa chiều

| Filter | Giá trị (UI label) | Cột MV |
|---|---|---|
| **Date Type** | `Ngày gửi thầu`, `ETD gửi thầu`, `ETA gửi thầu` | xem §6.2 |
| **Date Range** | From / To (default = hôm nay) | derived theo Date Type |
| **Warehouse** | ALL, **BKD1, NKD, VN821, VN831** (4 kho thực có data) | `t.whseid` |
| **Khu vực giao hàng** | ALL + danh sách `group_area.area_name` distinct | `t.khu_vuc_doi_xe` |
| **Sales Channel** | ALL + danh sách `channel` distinct | `t.group` (alias từ `t.channel`) |
| **Transporter** | ALL + danh sách `short_name` distinct | `t.ten_ngan_nvt` |

**Lưu ý filter:**
- "Khu vực giao hàng" và "Khu vực đội xe" là 1 khái niệm — chỉ khác tên gọi UI.
- KHÔNG có filter Cargo Group, Customer (per BA decision 2026-05-06).
- Lọc chỉ áp dụng sau khi nhấn **Apply**.

#### FR-06: Tab Chart / Detail
- **Tab Chart:** scorecard + pie + bar chart drilldown
- **Tab Detail:** bảng chi tiết 47 cột

#### FR-07: Export
Cho phép export bảng Detail hiện tại sang Excel/CSV (theo filter đã apply).

### 5.2 Nice-to-Have

| ID | Mô tả |
|---|---|
| NFR-01 | Highlight row "Late Departure Open" và "At Risk" trong bảng để dễ nhận diện |
| NFR-02 | UI cho phép thiết lập **At Risk window** (mặc định 45 phút, configurable) — truyền giá trị xuống SQL khi chạy lại. (Per Operations roadmap 2026-05-06.) |

> NFR cũ "Auto-refresh interval" và "Push notification khi At Risk tăng đột biến" đã được loại bỏ — UI không có chế độ auto-refresh, phụ thuộc MV refresh 5'. User check liên tục thay vì chờ push.

---

## 6. Data & Business Rules

### 6.1 Định nghĩa 7 alert_status (mutually exclusive)

multiIf logic trong `mv_alert_late_do` (tính tại MV refresh dùng `now64()`):

| # | Status | Màu | Điều kiện | Nhóm |
|---|---|---|---|---|
| 1 | **Late delivery** | `#F87171` (Light Red) | `max_ata_roi_trip NOT NULL` AND `cnt_line_trip > 0` AND `cnt_line_late_vs_eta > 0` | Historical |
| 2 | **Ontime delivery** | `#14B8A6` (Teal) | `max_ata_roi_trip NOT NULL` AND `cnt_line_trip > 0` AND `cnt_line_late_vs_eta = 0` AND **mỗi line có ETA NOT NULL** | Historical |
| 3 | **Late departure** | `#DC2626` (Dark Red) | `gio_ra_cong NOT NULL` AND `max_ata_roi_trip IS NULL` AND `tg_bat_buoc_roi_kho NOT NULL` AND `gio_ra_cong >= tg_bat_buoc_roi_kho` | Historical |
| 4 | **Ontime departure** | `#22C55E` (Light Green) | `gio_ra_cong NOT NULL` AND `max_ata_roi_trip IS NULL` AND `tg_bat_buoc_roi_kho NOT NULL` AND `gio_ra_cong < tg_bat_buoc_roi_kho` | Historical |
| 5 | **Normal** | `#10B981` (Green) | `gio_ra_cong IS NULL` AND `tg_bat_buoc_roi_kho NOT NULL` AND `now64() < tg_bat_buoc_roi_kho - 45 min` | Real-time |
| 6 | **At risk** | `#F59E0B` (Amber) | `gio_ra_cong IS NULL` AND `tg_bat_buoc_roi_kho NOT NULL` AND `tg_bat_buoc_roi_kho - 45 min ≤ now64() ≤ tg_bat_buoc_roi_kho` | Real-time |
| 7 | **Late departure open** | `#EF4444` (Red) | `gio_ra_cong IS NULL` AND `tg_bat_buoc_roi_kho NOT NULL` AND `now64() > tg_bat_buoc_roi_kho` | Real-time |
| (fallback) | **N/A** | — | (default) — gồm trip thiếu thông tin (`tg_bat_buoc_roi_kho IS NULL` AND chưa có alert hiển nhiên) | — |

**Lưu ý quan trọng:**
- `Late departure` (no "Open") và `Late departure open` là **2 nhãn ĐỘC LẬP, mutually exclusive** (không phải superset). Phân biệt:
  - `Late departure open`: chưa ra cổng + đã quá deadline → đang còn trong kho
  - `Late departure`: đã ra cổng + lúc ra cổng đã quá deadline → đã rời kho nhưng trễ
- 3 status real-time (Normal/At risk/Late departure open) **phụ thuộc `now64()`** — giá trị thay đổi giữa các MV refresh.
- "Ontime delivery" YÊU CẦU **tất cả lines có ETA NOT NULL**. Nếu trip có lines NULL ETA → fall vào nhánh khác hoặc bị tag sai (xem BUG-6 §11).

#### Distribution thực tế (verify 2026-05-06)

| alert_status | % | Note |
|---|---:|---|
| Late delivery | 64.6% | Dominant |
| Ontime delivery | 35.3% | Dominant |
| Ontime departure | 0.04% | Very rare |
| N/A | 0.006% | thiếu data |
| Normal / Late departure / Late departure open | <0.01% mỗi cái | Rất hiếm — vì 97.5% trip không có `tg_bat_buoc_roi_kho` |

→ Real-time alerts gần như chỉ fire trên trip mới (sau khi rule `tg_bat_buoc_roi_kho` được áp dụng — xem §6.10).

### 6.2 Date Type → Cột MV (mapping)

| UI label | SQL param `p_loai_ngay` | Cột MV được filter |
|---|---|---|
| `Ngày gửi thầu` | `'Ngày gửi thầu'` | `thoi_gian_gui_thau` |
| `ETD gửi thầu` | `'ETD gửi thầu'` | `etd_chuyen_gui_thau` ⚠ SQL hiện không có CASE branch — fallback ETA. Xem **BUG-1 §11**. |
| `ETA gửi thầu` (default) | `'ETA gửi thầu'` | `eta_giao_hang_cho_npp` |

### 6.3 KPI công thức + Pie chart base

| KPI | Công thức |
|---|---|
| `Tất cả` | `COUNT(DISTINCT so_chuyen)` toàn MV trong kỳ lọc |
| 7 status counts | `COUNT(DISTINCT so_chuyen) WHERE alert_status = '<X>'` |
| Pie chart % | `count_status / Tất cả × 100`, mẫu số = `Tất cả` |
| Chia 0 | trả `0` |

### 6.4 Hardcoded business filters (upstream MV)

DA/QA cần biết khi đối soát:

**STM (`mv_alert_stm_data`):**
- `ordm.is_deleted = 0`
- `ordm.service_name = 'Xuất bán'` — chỉ đơn xuất bán
- `ordm.customer_id = '9'` — Mondelez
- `trip.status_id IN (98, 99, 100, 101)` — chỉ tender approved trips
- `dtd.sort_order IN ('1', '-1')` OR `(sort_order='2' AND service_name='Xuất bán')`
- `dtd.is_deleted = 0`, `trip.is_deleted = 0`
- `opg.code_sync IS NOT NULL` AND `code_sync != ''`

**SWM (`mv_alert_swm_data`):** TBD — DA verify (xem §11 task list).

**JOIN khóa:**
- `swm.so = stm.ma_don_hang` AND `swm.order_line_number = stm.line_no`
- `line_no` STM = `LEFT(opg.code_sync, length(code_sync) - 1)` (bỏ ký tự cuối)

### 6.5 Volume — 3 layer (BẮT BUỘC phân biệt)

15 cột volume per trip:

| Layer | Cột (5 UOM mỗi layer) | Nguồn |
|---|---|---|
| **Plan** | `sum_original` (masterunit), `sum_original_cbm`, `sum_original_kg`, `sum_original_cse`, `sum_original_pl` | SWM `original_qty` × hệ số |
| **Pick (SWM Actual)** | `sum_shipped*` | SWM `shipped_qty` × hệ số |
| **Giao BBGN (STM Actual)** | `sum_san_luong_giao*` | STM `quantity_bbgn` × hệ số |
| **Diff** | `diff_sl_giao_cho*` = `sum_shipped - sum_san_luong_giao` | derived |

> UOM convention: `original_qty` luôn ở masterunit (PCE/EA). Hệ số quy đổi từ `mv_masterdata_sku`.

### 6.6 Warehouse hierarchy

**Business intent:** VN821 → BKD; VN831 → NKD (Operations team đã confirm 2026-05-06 — báo cáo EOD đã gộp).

**Implementation thực tế (Late Order Alert):**
| whseid | Rows | % |
|---|---:|---:|
| BKD1 | 36,608 | 56% |
| NKD | 24,020 | 37% |
| VN831 | 3,129 | 4.7% |
| VN821 | 1,951 | 3% |

→ MV này **CÓ data** ở VN821/VN831 (khác Flash Report). Không cần fix rollup ở MV layer cho feature này — backend/UI tự rollup nếu cần hierarchy.

### 6.7 Filter ↔ Cột MV (cheatsheet)

| UI Filter | Cột MV | Source upstream | NULL handling |
|---|---|---|---|
| Date Type + Date Range | xem §6.2 | — | NULL date → loại khỏi date range |
| Warehouse | `t.whseid` | SWM `dim_orderdetail.whseid` | exact match |
| Khu vực giao hàng | `t.khu_vuc_doi_xe` | `group_area.area_name` (theo customer_code) | NULL → bucket `'Unclassified'` |
| Sales Channel | `t.group` (alias từ `t.channel`) | `mv_masterdata_location.channel` | NULL → `'Unclassified'` |
| Transporter | `t.ten_ngan_nvt` | STM `subdim_cus_customer.short_name` (vendor) | NULL → `'Unclassified'` |

> **NULL filter behavior:** Khi user chọn filter cụ thể (vd `Channel='MT'`), trip có cột NULL bị **ẩn hoàn toàn**. UI không expose option `'Unclassified'` trong dropdown. (Per BA decision.)

### 6.8 Multi-leg trip + Single-warehouse rule

**Multi-leg:** `mv_alert_stm_data` filter `sort_order IN ('1','-1') OR (sort_order='2' AND service_name='Xuất bán')`.
- `max_ata_roi_trip = maxIf(ata_roi, ata_roi IS NOT NULL)` → MAX qua tất cả lines → đại diện thời điểm rời điểm giao cuối.
- `cnt_line_late_vs_eta = countIf(ata_roi NOT NULL AND eta NOT NULL AND ata_roi > eta)` → 1 line trễ → trip = Late delivery.

**Single-warehouse rule (Operations confirm 2026-05-06):** 1 chuyến chỉ pick từ 1 kho. Multi-warehouse trip không xảy ra trong nghiệp vụ → mỗi trip có duy nhất 1 `whseid`.

**Trip "Giao một phần"** (cnt_line_co_ata_roi > 0 AND cnt_line_chua_ata_roi > 0):
- `trang_thai_chuyen = 'Giao một phần'` — đây là **state intermediate** trong nghiệp vụ.
- `alert_status` map vào Late/Ontime delivery (vì max_ata_roi_trip NOT NULL).
- → Có gap: nghiệp vụ coi là intermediate, alert coi là terminal. Acceptable cho high-level monitoring.

### 6.9 Refresh cadence
- `mv_alert_stm_data`: **REFRESH EVERY 5 MINUTE**
- `mv_alert_swm_data`: 5'
- `mv_alert_stm_swm_data`: 5'
- `mv_alert_late_do_base`: 5'
- `mv_alert_late_do_so_pick`: 5'
- `mv_alert_late_do_concat`: 5'
- **`mv_alert_late_do`: REFRESH EVERY 5 MINUTE**

→ Toàn pipeline 5 phút uniform. UI **không có auto-refresh** — user phải nhấn Apply để query lại MV.

→ **`alert_status` real-time:** Nhãn Normal/At risk/Late departure open được tính lúc MV refresh dùng `now64()` AT REFRESH TIME. Nếu user query 4 phút sau MV refresh, status có thể "stale" theo logic real-time (vd đáng lẽ At risk → vẫn hiển thị Normal cho tới refresh tiếp theo).

### 6.10 Data quality notes

| Cột | NULL rate | Nguyên nhân | Impact |
|---|---:|---|---|
| `eta_giao_hang_cho_npp` | 0.001% | trip không phải Xuất bán (rất hiếm) | Trip này bị tag Ontime delivery sai (false positive — xem **BUG-6 §11**) |
| `etd_chuyen_gui_thau` | 0.3% | Trip cũ không có ETD tender | Filter Date Type ETD bỏ qua trip này |
| `thoi_gian_gui_thau` | 2.1% | minor | Filter "Ngày gửi thầu" bỏ qua |
| `tg_bat_buoc_roi_kho` | **97.5%** | Rule tính `RequiredDepartureTime` mới được áp dụng gần đây — phần lớn trip cũ chưa có | Real-time alert (Normal/At risk/Late departure open) chỉ fire cho trip mới (sau khi rule active). Trip cũ rơi vào N/A hoặc Historical alerts. **Đây là hành vi đúng**, không phải bug. |

### 6.11 Distance & speed (so_km, van_toc)

Công thức ước lượng quãng đường dựa trên gap thời gian giữa `tg_bat_buoc_roi_kho` và `eta_giao_hang_cho_npp`:

```
so_km = (intDiv(diff_min, 255) * 240 + LEAST(modulo(diff_min, 255), 240)) / 60 × van_toc
diff_min = dateDiff('minute', tg_bat_buoc_roi_kho, eta_giao_hang_cho_npp)

van_toc:
  BKD1, BKD2, BKD, VN821 → 40 km/h
  NKD, VN831            → 50 km/h
```

> Magic numbers (45-min At Risk window, 40/50 km/h speed) là **cố định theo SLA Mondelez**. Future enhancement: configurable trên UI (NFR-02).

---

## 7. Out of Scope

- Chỉnh sửa hay cập nhật trạng thái đơn hàng (read-only).
- Phân tích OTIF, VFR — thuộc các màn hình riêng trong Order Monitor.
- Lịch sử thay đổi trạng thái theo thời gian (chỉ xem trạng thái hiện tại).
- Tích hợp real-time websocket — UI dùng MV refresh 5' + manual Apply.
- Auto-refresh polling từ FE — không implement, dựa hoàn toàn vào MV.
- Push notification — bỏ NFR cũ. User check liên tục trong workflow.
- Root cause analysis tự động — chỉ hiển thị `ly_do_tre_hoan_thanh` per trip Late delivery hoàn tất.

---

## 8. Dependencies

| Dependency | Mô tả | Refresh |
|---|---|---|
| STM ClickHouse (`stm_dwh_mondelez.*`) | Trip, order, dock register, vehicle | CDC realtime |
| SWM ClickHouse (`swm_dwh_mondelez.*`) | Order header/detail (qua `mv_alert_swm_data`) | CDC realtime |
| `analytics_workspace.mv_alert_stm_data` | STM transformation layer | 5 min |
| `analytics_workspace.mv_alert_swm_data` | SWM transformation layer | 5 min |
| `analytics_workspace.mv_alert_stm_swm_data` | JOIN layer | 5 min |
| `analytics_workspace.mv_alert_late_do_base` | Per-line raw | 5 min |
| `analytics_workspace.mv_alert_late_do_so_pick` | Per-trip aggregation | 5 min |
| `analytics_workspace.mv_alert_late_do_concat` | String concat per trip | 5 min |
| `analytics_workspace.mv_alert_late_do` | Master MV cho FR-01 → FR-07 | 5 min |
| `mv_masterdata_sku`, `mv_masterdata_location`, `mv_masterdata_vehicle` | Reference data | CDC |
| `CTowerController.cs` | API: 1 endpoint trả 8 count + 1 endpoint trả Detail | — |
| `LateOrderAlertView.tsx` | UI component chính | — |
| `GLOSSARY.md` → Late Departure, At Risk, Ontime Delivery | Định nghĩa thuật ngữ chuẩn | — |

---

## 9. Business Workflow

### 9.1 Luồng sử dụng trong ngày

```
Đầu ca (06:00 / 12:00 / 18:00):
  Logistics Supervisor mở Late Order Alert
  → Xem scorecard 7 status: hôm nay có bao nhiêu trip At Risk / Late Departure Open?
  → Nếu At Risk hoặc Late Departure Open có trip:
      → Filter theo Warehouse hoặc Transporter để tìm điểm nóng
      → Chuyển sang Tab Detail → xem từng trip cụ thể (ds_ma_don_trong_chuyen, lý do)
      → Phối hợp với kho / nhà xe để xử lý ngay

Trong ca:
  Control Tower Analyst theo dõi diễn biến
  → User nhấn Apply để query lại (UI không auto-refresh, phụ thuộc MV 5')
  → Chú ý số Late Departure Open giảm dần (đơn đã ra cổng)
  → Nếu số đơn At Risk tăng → cảnh báo sớm cho Supervisor
  → Có chuyến "Giao một phần" → state intermediate, theo dõi tiếp

Cuối ngày:
  Analyst export bảng chi tiết (47 cột)
  → Báo cáo số liệu Late Delivery, tỷ lệ Ontime Departure/Delivery
  → Gửi lên Management
```

### 9.2 Luồng theo vai trò

| Vai trò | Bước 1 | Bước 2 | Bước 3 | Output |
|---|---|---|---|---|
| **Logistics Supervisor** | Xem scorecard 7 status | Filter theo transporter Late nhiều | Gọi điện xử lý ngay | Giảm Late Departure Open / At risk |
| **Control Tower Analyst** | Phân tích bar chart drilldown 4 dimension | Drilldown Detail table 47 cột | Export báo cáo EOD | File báo cáo gửi Management |
| **Warehouse Manager** | Filter theo kho của mình | Xem Late Departure Open + Late Departure | Điều phối nhân lực ưu tiên xuất hàng | Giảm trip tồn đọng |
| **Senior Management** | Xem scorecard tổng hợp | Không cần drilldown | — | Snapshot tỷ lệ đúng hạn |

### 9.3 Điều kiện đặc biệt

| Tình huống | Hành vi hệ thống | Người dùng cần làm gì |
|---|---|---|
| Tất cả trip = Normal | Scorecard hiển thị 0 cho At risk/Late departure open | Hoạt động tốt — không cần action |
| Late Departure Open tăng | Số đỏ nổi bật trong scorecard | Xem Detail table → phối hợp xử lý |
| Trip "Giao một phần" (intermediate state) | `trang_thai_chuyen='Giao một phần'`, alert_status = Late/Ontime delivery | Theo dõi line chưa giao xong |
| Dữ liệu chưa cập nhật | Số liệu lag tối đa 5' so với MV | Nhấn Apply để refresh (UI không auto-refresh) |
| Filter quá hẹp | Charts/table hiển thị trống | Mở rộng filter |
| Trip không có `tg_bat_buoc_roi_kho` | KHÔNG vào Real-time alerts (Normal/At risk/Late departure open) — chỉ vào Historical | Bình thường (97.5% trip cũ rơi vào case này) |
| Trip không có ETA | Bị tag `Ontime delivery` sai (BUG-6) — chỉ xảy ra với trip không phải Xuất bán (rất hiếm) | DA verify nếu thấy nhiều |
| Chuyến chở > 120 DO | `ds_ma_don_trong_chuyen` bị truncate ở 120 đơn đầu | Detail row sẽ thiếu DO — cảnh báo trong UI nếu cần |

---

## 10. Open Questions

| # | Câu hỏi | Người cần trả lời | Trạng thái |
|---|---|---|---|
| Q1 | DA verify hardcoded business filters từ `mv_alert_swm_data` upstream — có filter virtual/test/internal transfer không? | DA | ⏳ Chờ |
| Q2 | DA fix BUG-1 (ETD gửi thầu) khi nào? | DA | 🔴 Pending fix |
| Q3 | DA fix BUG-4 (Sales Channel Redshift `t.group` vs ClickHouse `t.channel`) khi nào? | DA | 🔴 Pending fix |
| Q4 | DA fix BUG-5 (label whitespace `Đã ra cổng,\r\n...`) khi nào? | DA | 🟡 Pending fix |
| Q5 | DA fix BUG-6 (NULL ETA → 'N/A' thay vì 'Ontime delivery') — yêu cầu sửa multiIf | DA | 🔴 Pending fix |
| Q6 | NFR-02 — UI configurable At Risk window: roadmap implement khi nào? | Product Owner + Dev Lead | ⏳ Chờ |

**Đã resolved (per BA + Operations + DA 2026-05-06):**
- ✅ Late Departure status — 7 status mutually exclusive, có KPI card riêng (B1)
- ✅ At Risk logic — vẫn dựa trên `tg_bat_buoc_roi_kho` (B3 — alert chuyến sắp rời kho trễ)
- ✅ NULL ETA → tag 'N/A' (B4 — chờ DA fix)
- ✅ "Khu vực giao hàng" = "Khu vực đội xe" — chỉ khác tên gọi (B5, O1)
- ✅ 7 KPI cards (B6)
- ✅ Pie chart % chia trên `Tất cả` (B7)
- ✅ Volume 15 cột exposed UI (B8)
- ✅ Bỏ filter Cargo Group + Customer (B9)
- ✅ Detail table = TẤT CẢ 47 cột (B10)
- ✅ Bar chart 1 chart + dropdown chọn dimension (B11)
- ✅ "Giao một phần" → mapped Late/Ontime delivery (B12 + D10 + O5 — accept gap)
- ✅ "ATD Actual" = `gio_ra_cong` (B13, O2)
- ✅ Bỏ cột "Alert Since" (B14, O3)
- ✅ UI refresh = phụ thuộc MV refresh 5' (B15, E2)
- ✅ Bỏ NFR-03 push notification (B16, O7 — user check liên tục)
- ✅ `tg_bat_buoc_roi_kho` NULL 97.5% là **đúng** (D1 — rule mới áp dụng gần đây)
- ✅ Duplicate so_chuyen 1 row là bình thường (D5 — minor, không impact)
- ✅ Magic numbers (45 phút, 40/50 km/h) là cố định, future configurable (D9, O4 → NFR-02)
- ✅ Single-warehouse rule (O6 — 1 trip = 1 kho)
- ✅ Trip phải có ETA, NULL ETA = bất thường (O8)
- ✅ 1 endpoint trả 8 count (E1)

---

## 11. Known Issues (BUGs cần fix)

| ID | Mức độ | Mô tả | Vị trí | Impact |
|---|---|---|---|---|
| **BUG-1** | 🔴 HIGH | Date Type "ETD gửi thầu" không có CASE branch trong SQL — fallback default sang ETA | All scorecard queries trong `sql-registry.md` (line 18411–19378) | Filter "ETD gửi thầu" cho ra cùng kết quả với "ETA gửi thầu" → user không lọc đúng theo ETD |
| **BUG-4** | 🔴 HIGH | Sales Channel cột — Redshift dùng `t.group`, ClickHouse dùng `t.channel`. DDL alias là `t.group` (line 277). | sql-registry.md scorecard queries | Engine không nhất quán → query fail trên 1 trong 2 platform |
| **BUG-6** | 🔴 HIGH | NULL ETA → trip bị tag `'Ontime delivery'` (false positive). Branch 1 multiIf không guard `cnt_line_no_eta`. | DDL `mv_alert_late_do_so_pick` line 646 + `mv_alert_late_do` line 268 | Trip không phải Xuất bán (rất hiếm) bị tag Ontime sai |
| **BUG-5** | 🟢 LOW | Label `'Đã ra cổng,\r\n\r\n\r\n\r\n đang trên đường giao'` có 4 set `\r\n` | DDL `mv_alert_late_do` line 215 | UI render lạ, copy-paste filter không match |

**Resolved & no fix needed (đã được clarify):**
- BUG-2 cũ (Late Departure superset paradox) → resolved bằng BA decision B1 = mutually exclusive
- BUG-3 cũ ("Delivery Area" vs `khu_vuc_doi_xe`) → resolved: 2 tên cùng 1 khái niệm (B5 + O1)

**Data quality notes (không phải bug):**
- 97.5% trip có `tg_bat_buoc_roi_kho IS NULL` — đúng, do rule mới áp dụng gần đây (D1)
- 1 row duplicate so_chuyen — bình thường, không impact (D5)

> Audit chi tiết:
> - S2 (Data Pipeline): `docs/audit-results/s2-late-order-alert-20260506.md`
> - S1 (BA Logic Check): `docs/audit-results/s1-late-order-alert-20260506.md`
