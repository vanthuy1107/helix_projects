# Spec – Late Order Alert View

**UI:** `control-tower/ui/src/views/control-tower/order-monitor/LateOrderAlertView.tsx`
**API:** `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs`
**Wireframe:** `docs/02-features/late-order-alert/late-order-alert.wireframe.md`

---

## 1. Overview

Màn hình theo dõi trạng thái trễ hạn của đơn hàng. Phân loại đơn thành các trạng thái: Normal, At Risk, Late Departure (Open/Closed), Ontime Departure, Ontime Delivery, Late Delivery. Hiển thị dạng scorecard, pie chart, bar chart và bảng tóm tắt.

---

## 2. API Endpoints

**`LateOrderAlertFilter`:** `{ dateType?, fromDate?, toDate?, groupName?, whseid?, region?, transporter? }`

| Function | Parameters | Return Type | Mô tả |
|---|---|---|---|
| `fetchLateOrderAlertScorecard` | `LateOrderAlertFilter?` | `LateOrderAlertScorecard` | Số lượng đơn theo từng trạng thái |
| `fetchLateOrderAlertDetail` | `LateOrderAlertFilter?` | `LateOrderAlertDetailRow[]` | Chi tiết từng trip/DO với các trường: trip, doCode, tripStatus, mandatoryDepartAt, alert, cargoGroup, alertSince, warehouse, deliveryArea, transporter, atdActual, eta, salesChannel |

**Cấu trúc `LateOrderAlertScorecard`:**

| Field | Type | Mô tả |
|---|---|---|
| `tatCa` | `number` | Tổng tất cả đơn |
| `normalCnt` | `number` | Đơn Normal |
| `atRiskCnt` | `number` | Đơn At Risk |
| `lateDepartureOpenCnt` | `number` | Đơn Late Departure (đang mở) |
| `lateDepartureCnt` | `number` | Đơn Late Departure (tổng) |
| `ontimeDepartureCnt` | `number` | Đơn Ontime Departure |
| `ontimeDeliveryCnt` | `number` | Đơn Ontime Delivery |
| `lateDeliveryCnt` | `number` | Đơn Late Delivery |

---

## 3. State Management

| State | Type | Default | Mô tả |
|---|---|---|---|
| `warehouse` | `string` | `'ALL'` | Filter đã áp dụng |
| `deliveryArea` | `string` | `'ALL'` | Filter khu vực giao hàng |
| `salesChannel` | `string` | `'ALL'` | Filter kênh bán |
| `transporter` | `string` | `'ALL'` | Filter nhà vận tải |
| `dateType` | `'Ngày gửi thầu' \| 'ETD gửi thầu' \| 'ETA gửi thầu'` | `'Ngày gửi thầu'` | Loại ngày lọc |
| `fromDate` | `string` | today | Ngày bắt đầu (YYYY-MM-DD) |
| `toDate` | `string` | today | Ngày kết thúc (YYYY-MM-DD) |
| `warehouse/deliveryArea/salesChannel/transporter/dateType/fromDate/toDateDraft` | `string` | same | Phần bản draft chưa áp dụng |
| `detailRowsSource` | `LateOrderAlertDetailRow[]` | mock rows | Dữ liệu bảng chi tiết |
| `scorecard` | `LateOrderAlertScorecard` | zeros | Dữ liệu scorecard từ API |
| `apiError` | `string \| null` | `null` | Lỗi API |

---

## 4. Filters & Inputs

| Filter | Options | Ghi chú |
|---|---|---|
| Warehouse | `ALL` + các mã kho | Dropdown select |
| Delivery Area | `ALL` + areas | Dropdown |
| Sales Channel | `ALL` + channels | Dropdown |
| Transporter | `ALL` + transporters | Dropdown |
| Date Type | `Ngày gửi thầu`, `ETD gửi thầu`, `ETA gửi thầu` | Radio / Select |
| From Date / To Date | YYYY-MM-DD | Date picker |

> Filters được áp dụng theo mạng draft (warehouseDraft, ...) — chỉ cập nhật applied state khi user nhấn Apply.

---

## 5. Derived / Computed Data

| useMemo | Mô tả |
|---|---|
| `statusBreakdown` | Mảng `{ name, count, color }` cho từng trạng thái từ scorecard |
| `scorecardBars` | Gom thành bars cho chart: Normal, At Risk, Late Departure Open, Ontime Departure, Ontime Delivery, Late Delivery |
| `tableRows` | Rows cho summary table: metric name + value per status |

---

## 6. Business Logic Rules (Status Definitions)

| Trạng thái | Màu | Mô tả |
|---|---|---|
| Normal | Green | Đơn chưa có dấu hiệu trễ |
| At Risk | Amber | Đơn có nguy cơ trễ |
| Late Departure Open | Red | Đơn trễ xuất kho, chưa đóng |
| Late Departure | Red variant | Đơn trễ xuất kho (tổng, bao gồm đã đóng) |
| Ontime Departure | Green | Đơn xuất kho đúng giờ |
| Ontime Delivery | Teal/Green | Đơn giao đúng giờ |
| Late Delivery | Red | Đơn giao trễ |

---

## 7. Color / Status Coding

| Trạng thái | Màu |
|---|---|
| Normal | `#10B981` (Green) |
| At Risk | `#F59E0B` (Amber) |
| Late Departure Open | `#EF4444` (Red) |
| Late Departure | `#DC2626` (Dark Red) |
| Ontime Departure | `#22C55E` (Light Green) |
| Ontime Delivery | `#14B8A6` (Teal) |
| Late Delivery | `#F87171` (Light Red) |

---

## 8. User Interactions

| Tương tác | Hành động |
|---|---|
| Apply Filters | Cập nhật applied filters từ draft state, gọi lại cả `fetchLateOrderAlertScorecard` và `fetchLateOrderAlertDetail` |
| Đổi Tab | Chart vs Detail Table qua `LeftStickySectionTabs` |
| Hover chart | Tooltip hiển thị số lượng + % |
| Export | `ViewQueryExportActions` |

---

## 9. Sub-components

| Component | Vai trò |
|---|---|
| `ControlTowerItemCard` | 6 KPI scorecard cards |
| `LeftStickySectionTabs` | Tab Chart / Detail |
| Recharts: `PieChart`, `BarChart` | Pie distribution + bar chart |

---

## 10. Loading & Error States

| Tình huống | Xử lý |
|---|---|
| API loading | Spinner trong body |
| `apiError != null` | Error message hiển thị, charts/table rỗng |

---

## 11. Workflow

### 11.1 Page Load Flow

```
Người dùng mở Late Order Alert View
  → Khởi tạo default filter:
      date range = today, warehouse = "ALL", delivery area = "ALL", transporter = "ALL"
  → fetchLateOrderAlert() gọi API
  → Loading spinner hiển thị trong body
  → Hệ thống phân loại đơn theo status:
      Normal | At Risk | Late Departure Open | Late Departure Closed
      Ontime Departure | Ontime Delivery | Late Delivery
  → Render scorecard, pie charts, bar charts, summary table
```

### 11.2 Filter & Apply Flow

```
Người dùng thay đổi filter (date range, warehouse, delivery area, transporter)
  → Cập nhật draft state
  → Click Apply → fetchData(filter) re-fetch
  → UI cập nhật scorecard + charts + table
```

### 11.3 Alert Classification Flow

```
Với mỗi đơn hàng, hệ thống xác định status:
  → Late Departure Open: đơn quá giờ xuất phát, chưa kết thúc
  → Late Departure Closed: đơn xuất phát trễ, đã đóng
  → At Risk: đơn có ngưy cơ trễ (theo logic nhận dạng sớm)
  → Late Delivery: đã giao nhưng trễ
  → Ontime Departure / Ontime Delivery: đúng hạn
  → Normal: không có vấn đề
  → Scorecard hiển thị đếm theo từng status + % tổng
  → Pie chart phân bổ theo status
  → Bar chart phân tích theo kho / delivery area / transporter
```

### 11.4 Export Flow

```
Người dùng click Export
  → Tải file Excel/CSV chứa toàn bộ đơn hàng theo filter hiện tại
  → Bao gồm cột: mã đơn, status, kho, delivery area, transporter, giờ xuất phát, giờ giao
```

### 11.5 Error Handling Flow

```
fetchLateOrderAlert() thất bại
  → Spinner dừng
  → apiError = error message → hiển thị trong body
  → Charts/table hiển thị rỗng
  → Retry bằng click Apply lại
```
