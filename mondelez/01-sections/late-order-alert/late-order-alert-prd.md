# PRD — Section Late Order Alert: Cảnh báo đơn trễ theo thời gian thực

| Trường | Giá trị |
|--------|---------|
| **Version** | 1.0.0 |
| **Ngày** | 2026-05-19 |
| **Trạng thái** | Observed baseline — trích từ implementation hiện hành |
| **Tác giả** | PM/DA via `/da-trace` |
| **Phạm vi** | `01-sections/late-order-alert` — widget `WidgetLateOrderAlert` trên dashboard Smartlog Control Tower |
| **Branch** | `feat-vfr-late-alert` |
| **Source code** | [`frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx`](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx) |
| **Lần đầu introduce** | commit `f8a5c3b` (2026-04-10) — `feat: add DateRangePicker component and local storage management for template usage` |

---

## 1. Mục đích

Section Late Order Alert là **bảng cảnh báo trạng thái rời kho / giao hàng theo thời gian thực** cho đội vận hành Mondelez. Mỗi chuyến được phân loại vào 1 trong 7 trạng thái cảnh báo dựa trên 3 mốc thời gian — **TG bắt buộc rời kho**, **Giờ ra cổng (ATD)**, **ATA rời** — so với hệ trục thời gian hiện tại và ETA giao hàng cho NPP.

Khác `OTIF` (đo *kết quả* sau khi giao xong) — Late Order Alert là **dashboard hành động**: chỉ ra chuyến nào đang ở trạng thái "sắp trễ" / "đã trễ" cần can thiệp ngay. Khác `Shipping Progress` (đo tiến độ tổng) — widget này tập trung vào exception (trễ + rủi ro trễ).

---

## 2. Người dùng mục tiêu

| Vai trò | Nhu cầu chính |
|---------|--------------|
| Quản lý vận hành (Ops Manager) | Phát hiện sớm chuyến sắp/đã trễ rời kho để escalate với kho hoặc NVT |
| Trưởng kho (WH Manager) | Theo dõi cửa sổ 45 phút trước TG bắt buộc rời kho — biết chuyến nào cần ưu tiên xuất xe |
| Điều phối vận tải (Transporter Coordinator) | Xem breakdown theo nhà vận tải để hold-accountable NVT có nhiều chuyến trễ |
| QA/CS (Customer Service) | Tra chi tiết chuyến trễ giao NPP — đối chiếu DO, mã chuyến, lý do trễ |

---

## 3. Định nghĩa nghiệp vụ

> **[Observed]** — Định nghĩa dưới đây trích từ i18n hints (`orderMonitor.lateOrderAlert.hint*`) tại [dashboard-order-monitor.json:128-135](../../../../frontend/src/i18n/locales/vi/dashboard-order-monitor.json#L128-L135) và constant `AlertStatus` tại [widget-late-order-alert.tsx:81-108](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L81-L108).

### 3.1 Các mốc thời gian cốt lõi

| Thuật ngữ | Định nghĩa | Nguồn dữ liệu |
|-----------|-----------|---------------|
| **TG bắt buộc rời kho** | Mốc thời gian xe phải rời kho để kịp giao **2 đơn FRESH** theo ETA gửi thầu. Đây là deadline rời kho. | Field `mandatory_depart_at` / `tg_bat_buoc_roi_kho` |
| **Giờ ra cổng (ATD)** | Thời điểm xe rời cổng kho thực tế. | Field `atd_actual` / `gio_ra_cong` |
| **ATA rời** | Thời điểm xe hoàn tất giao hàng và rời điểm giao cuối (NPP). Tín hiệu này đến từ STM. | Field `ata_roi` |
| **ETA (Giao hàng cho NPP)** | Mốc giao hàng tới NPP theo cam kết. | Field `eta` / `eta_giao_hang_cho_npp` |
| **Cửa sổ At-risk** | 45 phút cuối trước TG bắt buộc rời kho. | Hardcoded: `45 minutes` (xem hint `atRisk`) |

### 3.2 Bảng 7 trạng thái cảnh báo

> Constant `AlertStatus` ở [widget-late-order-alert.tsx:81-89](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L81-L89). Ưu tiên hiển thị (`getAlertPriority`) ở [widget-late-order-alert.tsx:152-161](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L152-L161).

| # | Trạng thái | Định nghĩa nghiệp vụ | Công thức điều kiện | Màu sắc | Priority |
|---|------------|---------------------|---------------------|---------|----------|
| 1 | **Normal** (Bình thường) | Chuyến chưa ra cổng, còn xa deadline rời kho (>45 phút) | `Giờ ra cổng IS NULL` AND `CURRENT_TIMESTAMP < TG_bat_buoc - 45 minutes` | `#22c55e` emerald | 4 |
| 2 | **At risk** (Sắp trễ) | Chuyến chưa ra cổng, đang trong cửa sổ 45 phút cuối — cần theo dõi sát | `Giờ ra cổng IS NULL` AND `CURRENT_TIMESTAMP >= TG_bat_buoc - 45m` (upper bound do `Late departure open` chiếm trên cascade) | `#f59e0b` amber | 3 |
| 3 | **Late departure open** (Đã trễ, chưa rời kho) | Chuyến chưa ra cổng và đã quá deadline — rủi ro trễ giao 2 đơn FRESH | `Giờ ra cổng IS NULL` AND `CURRENT_TIMESTAMP > TG_bat_buoc` | `#ef4444` red | 0 |
| 4 | **Late departure** (Rời kho trễ, trên đường giao) | Chuyến đã rời cổng nhưng chưa hoàn tất giao, và rời kho sau deadline | `Giờ ra cổng IS NOT NULL` AND `ATA rời IS NULL` AND `Giờ ra cổng >= TG_bat_buoc` | `#fb7185` pink | 1 |
| 5 | **Ontime departure** (Rời kho đúng hạn, trên đường giao) | Chuyến đã rời cổng trước deadline, chưa hoàn tất giao | `Giờ ra cổng IS NOT NULL` AND `ATA rời IS NULL` AND `Giờ ra cổng < TG_bat_buoc` | `#38bdf8` sky | 5 |
| 6 | **Ontime delivery** (Giao đúng hạn) | Chuyến đã hoàn tất giao, ATA rời sớm hơn hoặc bằng ETA | `ATA rời IS NOT NULL` AND `ATA rời <= ETA` | `#10b981` emerald-dark | 6 |
| 7 | **Late delivery** (Giao trễ) | Chuyến đã hoàn tất giao nhưng ATA rời muộn hơn ETA | `ATA rời IS NOT NULL` AND `ATA rời > ETA` | `#f43f5e` rose | 2 |

> **Ghi chú**: Priority quyết định khi 1 chuyến (Trip) có nhiều DO có alert khác nhau → chọn alert mức nghiêm trọng nhất để hiển thị ở bảng chi tiết. Xem `detailTripRows` ở [widget-late-order-alert.tsx:1064-1122](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L1064-L1122).

### 3.3 Nhóm hiển thị (Display Groups)

Trên UI 7 status được gộp thành **3 nhóm trực quan** theo giai đoạn vận hành:

| Nhóm | i18n key | Statuses thành viên | Ý nghĩa |
|------|----------|---------------------|---------|
| **Chuyến trong kho, chưa rời kho** | `groupInWarehouse` | Normal · At risk · Late departure open | Chuyến chưa có Giờ ra cổng — kho đang xử lý |
| **Chuyến trên đường giao** | `groupInTransit` | Late departure · Ontime departure | Chuyến đã rời cổng, chưa có ATA rời |
| **Chuyến đã giao thành công ít nhất 1 đơn** | `groupDelivered` | Ontime delivery · Late delivery | Chuyến đã có ATA rời → đo kết quả giao |

### 3.4 Đơn vị đo

Widget đếm **số chuyến** (count of trips), KHÔNG đo volume/CSE/CBM/Ton. Bảng chi tiết có cột volume (`sumOriginal`, `sumShipped`, `sumSanLuongGiao` × 5 UOM) nhưng mặc định `defaultHidden: true`.

---

## 4. Bộ lọc (Filters)

> **[Observed]** — `LOA_FILTER_DEFINITIONS` ở [widget-late-order-alert.tsx:181-232](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L181-L232).

| Filter | Key | Loại | Giá trị mặc định | Ghi chú |
|--------|-----|------|-----------------|---------|
| Kho | `whseid` | Multi-select | ALL | Value candidates: `whseid`, `warehouse_id`, `whs_id`. Standardize tên ở client qua `standardizeWarehouseName()` (BKD1-3, NKD, VN821, VN831) |
| Khu vực giao hàng | `region` | Multi-select | ALL | Value candidates: `region`, `delivery_area`, `area` |
| Kênh bán hàng | `group_name` | Multi-select | ALL | Value candidates: `group_name`, `groupname`, `sales_channel`, `channel` |
| Nhà vận tải | `transporter` | Multi-select | ALL | Value candidates: `transporter`, `carrier`, `vendor` |
| Loại ngày | `dateType` | Single-select | `Ngày gửi thầu` | 2 options: `Ngày gửi thầu`, `ETA gửi thầu` |
| Date Range | `dateRange` | Date range | Hôm nay → hôm nay | Hard-limit 2 năm (`MAX_DATE_RANGE_MS`) — vượt → toast error |

**Auto-apply**: `SqlFilterPanel` chạy chế độ `autoApply` — thay đổi filter → áp dụng ngay, KHÔNG cần nhấn Apply.

**Filter restore**: Trạng thái filter được persist vào localStorage với key `dashboard-widget-filter:{dashboardId}:{widgetId}`. Trước khi restore xong (`filterInitialized = false`) — widget KHÔNG gọi API.

---

## 5. Cấu trúc màn hình

> **[Observed]** — `WidgetLateOrderAlert` ở [widget-late-order-alert.tsx:768-1487](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L768-L1487).

Section gồm **2 vùng chính**: Sticky filter bar (trên) + 2 tab (Chart / Chi tiết bảng).

### 5.1 Tab Chart — Layout

```
┌── KPI Cards Row ───────────────────────────────────────────┐
│ ┌──────────┐ ┌──────────────────────────────────────────┐ │
│ │  Tổng    │ │ Group 1: Chuyến trong kho               │ │
│ │  chuyến  │ │   Normal | At risk | Late dep open      │ │
│ │  (large) │ ├──────────────────────────────────────────┤ │
│ │          │ │ Group 2: Chuyến trên đường giao         │ │
│ │          │ │   Late departure | Ontime departure     │ │
│ │          │ ├──────────────────────────────────────────┤ │
│ │          │ │ Group 3: Chuyến đã giao                 │ │
│ │          │ │   Ontime delivery | Late delivery       │ │
│ └──────────┘ └──────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────┤
│ Chart 1: Breakdown trạng thái cảnh báo (Donut)            │
│   • Donut chart 7 status + legend list bên phải            │
├────────────────────────────────────────────────────────────┤
│ Chart 2: Cảnh báo theo nhà vận tải (Stacked Bar)          │
│   • X = transporter (sort theo total desc)                 │
│   • Stack 7 status (theo STATUS_COLORS)                    │
│   • LabelList số trên mỗi bar segment                      │
└────────────────────────────────────────────────────────────┘
```

**KPI Cards (8 thẻ)**: 1 thẻ lớn `Tổng chuyến` ở trái (w-44, `large` variant) + 7 thẻ nhỏ chia 3 nhóm bên phải. Mỗi thẻ có icon + label + value + desc + hint tooltip (từ i18n `hint*` keys).

**Donut chart**: `Pie` với `innerRadius=62`, `outerRadius=105`. 7 segment màu theo `STATUS_COLORS`. Bên phải có **legend strip** liệt kê 7 status + count.

**Transporter bar chart**: Height 320px. `BarChart` với `barCategoryGap='20%'`. 7 series (1 series per status), mỗi bar có `LabelList` ở `position='top'` hiển thị count. Tooltip custom (`TransporterBreakdownTooltip`) hiển thị full breakdown.

### 5.2 Tab Chi tiết bảng

1 bảng duy nhất `WidgetGrid` với `gridKey='DSHLOAMNG01'`:

| Property | Giá trị |
|----------|---------|
| Page size | 20 |
| Default visible | 11 cột (trip, doCode, tripStatus, mandatoryDepartAt, alert, warehouse, deliveryArea, transporter, atdActual, eta, salesChannel) |
| Default hidden | 54 cột (identity, time fields, vehicle, quantities × 5 UOM, durations, distance) — xem [widget-late-order-alert.columns.tsx](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.columns.tsx) |
| Sort mặc định | Theo alert priority asc, sau đó theo trip alphabetical (xem `sortedDetailRows`) |

**Alert chip render**: Cột `alert` render dạng pill với màu theo status (`alertChipClass()` ở columns file). Cột `trip` có badge `Mới nguy cơ trễ` / `Mới trễ` nếu status = At risk / Late departure open.

### 5.3 Trip aggregation

`detailTripRows` aggregate DO-level rows về trip-level: với mỗi trip key (`row.trip` hoặc `__tripless__{doCode}`), chọn:
- **EarliestEtaRow**: DO có ETA sớm nhất (tie-breaker = doCode asc) — làm base row
- **AlertPriorityRow**: DO có alert nghiêm trọng nhất (tie-breaker = mandatoryDepartAt asc, sau đó eta asc) — override `tripStatus`, `mandatoryDepartAt`, `alert`, `alertSince`, `warehouse`, `deliveryArea`, `transporter`, `atdActual`
- **NppPriorityRow**: trong danh sách `byEta` (đã sort ETA asc), DO đầu tiên có `salesChannel` non-empty — override `salesChannel`. Nếu không có DO nào có sales channel → fallback `earliestEtaRow`.

---

## 6. Nguồn dữ liệu và SQL Queries

> **[Observed]** — `LATE_ORDER_ALERT_SECTIONS` ở [widget-late-order-alert-settings-dialog.tsx:27-83](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert-settings-dialog.tsx#L27-L83).

Widget cấu hình bằng **2 SQL query**:

| Section key | Phục vụ | Cột bắt buộc (anyOf alias) |
|-------------|---------|-----------------------------|
| `scorecard` | 8 KPI cards (1 row trả về) | `tat_ca`, `normal_cnt`, `at_risk_cnt`, `late_departure_open_cnt`, `late_departure_cnt`, `ontime_departure_cnt`, `ontime_delivery_cnt`, `late_delivery_cnt` |
| `detail` | Bảng chi tiết + 2 chart derived | `trip`, `do_code`, `trip_status`, `mandatory_depart_at`, `alert`, `warehouse`, `delivery_area`, `transporter`, `atd_actual`, `eta`, `sales_channel` (+ ~50 cột optional) |

**Backend executor**: `dashboardV2Api.executeWidget(dashboardId, widgetId, { sectionKey, filterOverrides, pageSize: 5000 })`. Backend chịu trách nhiệm bind `filterOverrides` vào SQL template — frontend chỉ gửi values dạng string.

### 6.1 Filter overrides truyền backend

> **[Observed]** — `filterOverrides` memo ở [widget-late-order-alert.tsx:910-944](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L910-L944).

| Placeholder key | Source (FE var) | Giá trị empty string khi |
|-----------------|-----------------|--------------------------|
| `whseid` | `apiFilter.whseid` | whseid = "" hoặc "ALL" |
| `region` | `apiFilter.region` | region = "" hoặc "ALL" |
| `group_name` | `apiFilter.groupName` | groupName = "" hoặc "ALL" |
| `sales_channel` | `apiFilter.groupName` (alias) | groupName = "" hoặc "ALL" |
| `transporter` | `apiFilter.transporter` | transporter = "" hoặc "ALL" |
| `date_type` / `dateType` / `loai_ngay` | `apiFilter.dateType` (3 alias cùng value) | dateType = "" hoặc "ALL" |
| `from_date` | `apiFilter.fromDate + " 00:00:00"` | fromDate rỗng → `""` |
| `to_date` | `apiFilter.toDate + " 23:59:59"` | toDate rỗng → `""` |

Multi-select values là CSV (vd `"BKD1,BKD2,NKD"`), KHÔNG có quote — backend escape/quote khi bind.

### 6.2 Không có mock data fallback

Khi widget chưa cấu hình `dataSourceId` HOẶC SQL query rỗng → `hasSqlConfig = false` → widget KHÔNG gọi API (xem `enabled` của `useQuery`). KHÔNG có synthetic fallback (khác T1 của Flash Daily).

---

## 7. Luồng dữ liệu

> **[Observed]** — 2 `useQuery` ở [widget-late-order-alert.tsx:962-1011](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L962-L1011).

```
User thay đổi filter (autoApply)
  → handleFilterApply tính applied state
  → filterOverrides memo update
  → 2 useQuery invalidate:
      • late-order-alert-scorecard (SQL section "scorecard")
      • late-order-alert-detail (SQL section "detail")
  → Normalize:
      • normalizeScorecardFromSql() — pick first row, 8 numbers
      • normalizeDetailRowFromSql() — full DTO ~60 fields
  → Derive client-side:
      • statusBreakdown (donut chart) — từ scorecard
      • transporterBreakdown (bar chart) — group detail rows by transporter × alert status
      • detailTripRows — aggregate DO→Trip với priority rules (§5.3)
      • sortedDetailRows — sort by alert priority asc
  → Render KPI cards + donut + bar chart + detail table
```

**Tổng request song song khi load**: 2.

**Cache**: `staleTime = 5 phút`, `placeholderData = prev` (giữ data cũ khi refetch).

**Page size**: 5000 dòng per request (đủ cho 1 ngày Mondelez).

---

## 8. Cấu hình Widget (Settings Dialog)

> **[Observed]** — `WidgetLateOrderAlertSettingsDialog` ở [widget-late-order-alert-settings-dialog.tsx:95-136](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert-settings-dialog.tsx#L95-L136).

User có quyền `editMode` thấy 2 nút toolbar:

1. **Setting Chart** (variant outline) — mở `SqlSettingsDialog` với 2 section tab:
   - `Scorecard` (icon `LayoutGrid`, accent emerald) — Monaco editor + Test Query + `requiredColumns` validator
   - `Detail` (icon `Table2`, accent amber) — tương tự
2. **Setting Filter** (variant ghost amber) — mở `SqlFilterPanel` settings để override filter SQL (vd custom warehouse list).

Config lưu dưới dạng JSON string trong `widget.config` qua `useUpdateV2Widget`.

---

## 9. Acceptance Criteria

> AC dưới đây là **Observed-only** — mô tả hành vi hiện hành.

### AC-01: 8 KPI cards hiển thị đúng

**Given** widget cấu hình `scorecard` query trả 1 row có 8 cột count  
**When** user load page hoặc đổi filter  
**Then** 8 thẻ KPI hiển thị: `Tổng chuyến` (large, w-44) + 7 thẻ status chia 3 nhóm. Mỗi thẻ có icon + label + value + desc + tooltip hint từ i18n namespace `orderMonitor.lateOrderAlert.hint*` (lookup qua `tl('hintTotal')`, `tl('hintNormal')`, …).

### AC-02: Donut chart breakdown 7 segment

**Given** scorecard query trả về data  
**When** chart render  
**Then** Donut chart có 7 segment đúng thứ tự `BREAKDOWN_STATUS_ORDER`: Normal → At risk → Late departure open → Late departure → Ontime departure → Ontime delivery → Late delivery. Color theo `STATUS_COLORS`. Legend bên phải liệt kê đúng 7 entries dù value = 0.

### AC-03: Transporter bar chart sort & breakdown

**Given** detail query trả ≥ 1 row có `transporter` non-empty  
**When** chart render  
**Then** Stacked bar chart hiển thị tất cả transporter (1 bar per transporter), sort theo total desc. Mỗi bar stack 7 status (1 series per status). LabelList số nguyên trên mỗi segment. Row không có transporter → fallback label `Không xác định` (`unknownTransporter`).

### AC-04: Detail table aggregate DO → Trip

**Given** detail query trả nhiều DO của cùng 1 trip với alert khác nhau  
**When** bảng render  
**Then** 1 row per trip với rules:
- `eta` lấy DO có ETA sớm nhất
- `alert`, `tripStatus`, `mandatoryDepartAt` lấy DO có alert priority cao nhất (Late departure open = 0, ... Ontime delivery = 6)
- `salesChannel` lấy DO đầu tiên có sales channel non-empty
- `warehouse` được standardize qua `standardizeWarehouseName()` (BKD1-3, NKD, VN821, VN831)

### AC-05: Detail table sort default

**Given** bảng chi tiết đã load  
**When** user chưa nhấn sort  
**Then** Rows sort theo alert priority asc (Late departure open trước), trong cùng priority sort theo trip alphabetical.

### AC-06: Badge "Mới nguy cơ trễ" / "Mới trễ"

**Given** trip row có alert = `At risk` hoặc `Late departure open`  
**When** cột `trip` render  
**Then** Bên cạnh trip code có badge nhỏ:
- `At risk` → badge amber `Mới nguy cơ trễ` (`badgeNewAtRisk`)
- `Late departure open` → badge rose `Mới trễ` (`badgeNewLate`)

### AC-07: Date range guard 2 năm

**Given** user chọn date range  
**When** `nextDateRange.to - nextDateRange.from > 2 năm`  
**Then** Toast error `dateRangeOver2Years` + KHÔNG apply filter mới.

### AC-08: Filter persist localStorage

**Given** user đổi filter và reload page  
**When** widget mount  
**Then** `SqlFilterPanel` restore filter từ key `dashboard-widget-filter:{dashboardId}:{widgetId}`. Trước khi restore xong → KHÔNG gọi API.

### AC-09: Edit mode toolbar 2 nút

**Given** user có quyền edit dashboard  
**When** widget render với `editMode = true` và có `dashboardId` + `widgetId`  
**Then** Toolbar hiển thị 2 nút:
- "Setting Chart" (outline) — mở SqlSettingsDialog 2 tab (Scorecard / Detail)
- "Setting Filter" (ghost amber) — mở SqlFilterPanel settings

### AC-10: Export chart + table

**Given** user xem chart hoặc bảng  
**When** user mở export menu  
**Then**:
- Donut chart: PNG / CSV với filename `late-order-breakdown`
- Bar chart: PNG / CSV với filename `late-order-by-transporter`
- Bảng: CSV qua `WidgetGrid` export

---

## 10. Hành vi không thuộc phạm vi (Out of Scope)

- Gửi notification/email/SMS khi có chuyến trễ (thuộc module Monitors / Alerts)
- Cấu hình ngưỡng `45 phút` window At-risk (hiện hardcoded, chỉnh ở SQL của tenant)
- Cấu hình `TG bắt buộc rời kho` (thuộc upstream — STM hoặc planner xác định)
- Drilldown 1 chuyến → trang riêng (hiện chỉ có inline detail row)
- Lý do trễ (column `lyDoTreHoanThanh`) — không phân tích aggregate, chỉ hiển thị raw ở bảng chi tiết
- Phân tích root-cause `Late delivery` theo trip leg (multi-stop) — schema hiện không có cột `is_last_leg`

---

## 11. Open Questions

> Questions thuần business / product decisions. Items về technical bug / drift FE↔SQL được track ở [late-order-alert-spec.md §7 — Known anomalies](late-order-alert-spec.md#7-known-anomalies--issues-locked-for-fix).

| # | Câu hỏi | Status | Hành động |
|---|---------|--------|-----------|
| OQ-01 | Ngưỡng 45 phút cho At-risk có đúng cho Mondelez (và mọi tenant tương lai) không? | 🟡 **Open — needs Ops Mondelez confirm** | Threshold hardcode bên trong MV `mv_alert_late_do` (xem spec A3). Quyết định BUSINESS: 45 phút có phải standard Mondelez? → confirm hoặc đưa vào config (spec A3 đã track technical work). |
| OQ-02 | Trip multi-stop: alert priority dựa trên DO-level — có cover đủ case "DO leg sớm OK, leg cuối trễ" không? | 🟡 **Open — needs business sample audit** | Chạy SQL trên 1 sample tuần để verify pattern; chốt với Ops xem trip-level alert có cần xét leg-order không. |
| OQ-03 | Date range default = hôm nay → hôm nay phù hợp dashboard "realtime" không? | 🟡 **Open — needs UX decision** | Hiện default = `new Date()` cho cả from/to; user phải mở rộng để thấy chuyến chưa kết thúc. PM quyết: giữ "snapshot hôm nay" hay đổi thành "today ± 1 ngày" hoặc "rolling 24h". |
| OQ-04 | Filter `transporter` có skew khi 1 chuyến đổi NVT giữa chừng không? | 🟡 **Open — needs data quality audit** | Cần check schema MV có column `current_transporter` riêng không, và xem có chuyến nào thực tế đổi NVT giữa chừng. |
| OQ-05 | `unknownTransporter` fallback (`Không xác định`) — loại khỏi chart hay giữ làm data-quality signal? | 🟡 **Open — needs Ops feedback** | Hiện giữ. Hỏi Ops Manager: thông tin này có dùng được không, hay chỉ làm noise. |
| OQ-06 | Có cần "alert summary" cross-section (LOA + OTIF + Flash Daily) cho BOD view không? | 🟡 **Open — depends storytelling phase** | Out of scope v1.0. Đánh giá lại sau khi 3 widget đều ổn định. |
| ~~OQ-07~~ | Date type semantic giữa "ETA gửi thầu" vs "Ngày gửi thầu" ở SQL backend | ✅ **Closed (2026-05-19)** | Verified với sql-registry — registry CH hỗ trợ 8 nhánh `date_type`, FE chỉ expose 2; có mismatch `(đơn)` suffix → đã chuyển thành spec anomaly **A1** + **A6**. |
| OQ-08 | A2 (`requiredColumns` validator gap) là bug fix v1.1 hay accepted current state? | 🟡 **Open — needs PM call** | Validator hiện cho phép SQL config thiếu 3/8 + 6/11 cột pass mà không cảnh báo. PM quyết: log bug v1.1 hay deprioritize (vì admin Mondelez đã quen với config canonical). |

---

## 12. Ghi chú kỹ thuật cho Planner

- Widget dùng `dashboardV2Api.executeWidget()` với `sectionKey` để backend chọn SQL phù hợp. 2 section: `scorecard` + `detail`.
- Normalization xử lý 100% phía frontend qua `normalizeScorecardFromSql()` + `normalizeDetailRowFromSql()` — backend trả raw rows theo SQL.
- `transporterBreakdown` derived client-side từ `detailRowsSource` — KHÔNG gọi API riêng. Khi user filter sâu, có thể gây tải client nếu detail rows nhiều.
- Trip-level aggregation (`detailTripRows`) xử lý ở frontend với 3 priority rules song song (eta / alert / sales channel) — refactor về backend nếu performance issue.
- `STATUS_COLORS` hardcoded ở frontend; theme dark mode không override (xem `alertChipClass()` columns file đã có biến `dark:` để adapt nhẹ).
- Filter state persist localStorage với key `dashboard-widget-filter:{dashboardId}:{widgetId}` — giống các widget khác.
- Page size 5000 hardcoded; nếu tenant > 5K trip/ngày sẽ cần pagination hoặc raise limit.

---

## 13. Lịch sử thay đổi

| Version | Ngày | Tác giả | Thay đổi |
|---------|------|---------|---------|
| 1.0.0 | 2026-05-19 | PM/DA via `/da-trace` | Bản đầu tiên — Observed baseline từ source code branch `feat-vfr-late-alert`. Document 7 alert statuses (Normal/At risk/Late departure open/Late departure/Ontime departure/Ontime delivery/Late delivery) với formula trích từ i18n hints; 6 filters (whseid/region/group_name/transporter/dateType/dateRange); 2 SQL sections (scorecard 8 cột + detail ~60 cột); 2 charts (donut + transporter bar); 1 detail table grid `DSHLOAMNG01`. Mở 7 OQ chờ confirm với Ops Mondelez. |
| 1.0.1 | 2026-05-19 | PM/DA via `/ba-review` | Doc reconciliation pass — cross-check với codebase + `sql-registry.md`. Sửa drift: AC-01 i18n namespace (`FLASH_DAILY_HINTS` → `orderMonitor.lateOrderAlert.hint*`); At-risk window 1-sided; NppPriorityRow định nghĩa chính xác (theo `byEta`); default-hidden count 54 (không phải ~50); §6.1 source vars (`apiFilter.*` thay `applied.*`); AC-05 typo. Close OQ-07 → spec anomalies A1 + A6 (mismatch FE↔registry về `date_type` value). Mở OQ-08 cho validator gap. |
