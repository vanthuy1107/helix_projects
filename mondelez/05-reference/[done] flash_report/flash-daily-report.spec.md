# Spec – Flash Daily Report View

**UI:** `control-tower/ui/src/views/control-tower/flash-report/FlashDailyView.tsx`
**API:** `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs`
**Wireframe:** `docs/02-features/flash-daily-report/flash-daily-report.wireframe.md`

---

## 1. Overview

Màn hình theo dõi tiến độ xuất hàng trong ngày theo thời gian thực. Phân tích theo trạng thái đơn hàng, kho, kênh bán, khách hàng, khu vực giao hàng, và hàng hóa bị rớt (dropped delivery).

---

## 2. API Endpoints

| Function | Parameters | Return Type | Mô tả |
|---|---|---|---|
| `fetchFlashStatusSummary` | `FlashStatusFilter` | `FlashStatusRow[]` | Tổng hợp theo trạng thái + UOM |
| `fetchFlashStatusCards` | `FlashStatusFilter` | `FlashStatusCards` | KPI cards tổng hợp (totalDo, donXuat, donPending, donRot, pctXuat) |
| `fetchFlashE2EDistribution` | `FlashStatusFilter` | `FlashE2EStatusRow[]` | Phân bổ E2E status |
| `fetchFlashWarehouseProgress` | `FlashStatusFilter` | `FlashWarehouseProgressRow[]` | Tiến độ theo kho |
| `fetchFlashProgressByCustomer` | `FlashStatusFilter` | `FlashDimensionProgressRow[]` | Tiến độ theo khách hàng |
| `fetchFlashProgressByDeliveryArea` | `FlashStatusFilter` | `FlashDimensionProgressRow[]` | Tiến độ theo khu vực giao |
| `fetchFlashProgressBySalesChannel` | `FlashStatusFilter` | `FlashDimensionProgressRow[]` | Tiến độ theo kênh bán |
| `fetchFlashSummaryByWarehouse` | `FlashStatusFilter` | `FlashSummaryByDimensionRow[]` | Summary table theo kho |
| `fetchFlashSummaryByCustomer` | `FlashStatusFilter` | `FlashSummaryByDimensionRow[]` | Summary table theo khách hàng |
| `fetchFlashSummaryByDeliveryArea` | `FlashStatusFilter` | `FlashSummaryByDimensionRow[]` | Summary table theo khu vực |
| `fetchFlashSummaryBySalesChannel` | `FlashStatusFilter` | `FlashSummaryByDimensionRow[]` | Summary table theo kênh bán |
| `fetchFlashDroppedDeliveryReport` | `FlashStatusFilter` | `FlashDroppedDeliveryReportRow[]` | Danh sách đơn bị rớt |
| `fetchFlashDroppedReasonReport` | `FlashStatusFilter` | `FlashDroppedReasonReportRow[]` | Lý do rớt đơn |
| `fetchFlashDetailRows` | `FlashStatusFilter` | `FlashDetailRow[]` | Chi tiết từng đơn hàng (dùng cho export) |

**`FlashStatusFilter` fields:** `dateType`, `dateFrom`, `dateTo`, `groupName`, `whseid`, `brand`, `groupOfCargo`, `region`

---

## 3. State Management

| State | Type | Mô tả |
|---|---|---|
| `uom` | `'cse' \| 'ton' \| 'cbm' \| 'pallet' \| 'do'` | Đơn vị đo lường |
| `dateType` | `string` | Loại ngày lọc |
| `dateFrom / dateTo` | `string` (YYYY-MM-DD) | Khoảng ngày |
| `groupName` | `string` | Kênh/nhóm bán hàng |
| `whseid` | `string` | Kho |
| `brand` | `string` | Nhãn hàng |
| `groupOfCargo` | `string` | Loại hàng hóa |
| `region` | `string` | Khu vực giao hàng |
| `rows` | `FlashStatusRow[]` | Dữ liệu status summary |
| `e2eRows` | `FlashE2EStatusRow[]` | Dữ liệu E2E distribution |
| `warehouseRows` | `FlashWarehouseProgressRow[]` | Tiến độ theo kho |
| `customerRows` | `FlashDimensionProgressRow[]` | Tiến độ theo khách hàng |
| `deliveryAreaRows` | `FlashDimensionProgressRow[]` | Tiến độ theo khu vực |
| `salesChannelRows` | `FlashDimensionProgressRow[]` | Tiến độ theo kênh bán |
| `*SummaryRows` (×4) | `FlashSummaryByDimensionRow[]` | Summary data cho table tab |
| `droppedDeliveryRows` | `FlashDroppedDeliveryReportRow[]` | Đơn bị rớt |
| `droppedReasonRows` | `FlashDroppedReasonReportRow[]` | Lý do rớt |
| `isLoading` | `boolean` | Loading state |
| `loadError` | `string \| null` | Lỗi |
| `applied` | `FlashStatusFilter` | Bộ lọc đang được áp dụng |

---

## 4. Filters & Inputs

| Filter | Options | Ghi chú |
|---|---|---|
| UOM | `cse`, `ton`, `cbm`, `pallet`, `do` | Ảnh hưởng formatting và label |
| Date Type | `GI date`, `Actual Ship date`, `ETD gửi thầu`, `ATA đơn`, `ETA gửi thầu` | Xác định field ngày dùng để lọc |
| Date From / To | Date input | Default = today |
| Group / Channel | `ALL`, `MT`, `GT`, `KA`, `B2B`, `EXPORT`, `OTHER` | |
| Warehouse | `ALL`, `BKD1`, `BKD2`, `BKD3`, `BKD`, `NKD`, `VN821`, `VN831` | |
| Brand | `ALL`, `Solite`, `AFC`, `Lu`, `Cosy`, `Oreo`, `Tết`, `Trung Thu`, `Slide`, `KD`, `RITZ`, `Toblerone` | |
| Cargo Type | `ALL`, `FRESH`, `DRY`, `MOONCAKE`, `POSM/OFFBOM`, `TEST`, `PM`, `EQUIPMENT` | |
| Region | `ALL`, `South East`, `Ho Chi Minh`, `Mekong 1` | |

---

## 5. Derived / Computed Data

| useMemo | Mô tả |
|---|---|
| `statusValues` | Gom `rows` → tổng `valueUom` theo từng normalized status |
| `totalVolume` | Tổng tất cả statusValues |
| `e2eDoRows` | Map e2eRows → chart data với color code theo status |
| `totalDistinctSo` | Sum `distinctSo` qua e2e status rows |
| `warehouseProgressRows` | Group warehouse rows theo warehouse + status |
| `customerProgressRows / deliveryAreaProgressRows / salesChannelProgressRows` | Transform sang chart format qua `toDimensionChartRows()` |
| `*SummaryChartRows` (×4) | Transform sang chart format qua `toSummaryChartRows()`, tính `pctDone = doneVolume / totalVolume × 100` |

**Chart height formula:** `min(760, max(280, rowCount × 30))`

---

## 6. Business Logic Rules

### Status Normalization & Colors

| Status (raw) | Display | Màu |
|---|---|---|
| Chưa xuất kho | Not Shipped | `#858585` (Gray) |
| Đang xuất kho | Shipping | `#E18719` (Orange) |
| Đã xuất kho | Shipped | `#4F2170` (Purple) |
| Đang vận chuyển | In Transit | `#2D6EAA` (Blue) |
| Đã vận chuyển | Delivered | `#287819` (Green) |

### Value Formatting by UOM

| UOM | Format |
|---|---|
| `do` | Integer (rounded) |
| `ton`, `cbm`, `pallet` | 2 decimal places |
| `cse` | 0 decimal places |

---

## 7. User Interactions

| Tương tác | Hành động |
|---|---|
| Thay đổi filter | Cập nhật draft state (không auto-apply) |
| Click Apply | `handleApply()` → build `FlashStatusFilter` → `fetchData()` → cập nhật `applied` |
| Đổi UOM | Thay đổi `uom`, tính lại format toàn màn hình |
| Đổi Tab | Chart tab vs Table Detail tab qua `LeftStickySectionTabs` |
| Export | `ViewQueryExportActions` với chart names: Status Summary, Warehouse Progress, Customer Progress, Delivery Area, Sales Channel, E2E Distribution, Dropped Delivery, Dropped Reason |

---

## 8. Sub-components

| Component | Vai trò |
|---|---|
| `ViewQueryExportActions` | Export + Query action bar |
| `ControlTowerItemCard` | KPI card |
| `LeftStickySectionTabs` | Tab navigation (Chart / Table Detail) |
| `ScreenLoadingOverlay` | Loading overlay |
| Recharts: `BarChart`, `Bar`, `Cell` | Status stacked bar, warehouse/channel progress |

---

## 9. Loading & Error States

| Tình huống | Xử lý |
|---|---|
| `isLoading == true` | Hiển thị `ScreenLoadingOverlay` |
| `loadError != null` | Hiển thị error message |
| Empty rows | Charts hiển thị empty state, tables hiển thị "Không có dữ liệu" |

---

## 10. Workflow

### 10.1 Page Load Flow

```
Người dùng mở Flash Daily Report
  → Khởi tạo default filter:
      dateType = "GI date"
      dateFrom = dateTo = today (auto ETD-switch: nếu giờ hiện tại ≥ 15:00 → tomorrow)
      groupName = "ALL", whseid = "ALL", brand = "ALL"
      groupOfCargo = "ALL", region = "ALL"
      uom = "cbm"
  → handleApply() tự động trigger khi mount
  → fetchData() gọi song song 14 API endpoints
  → isLoading = true → hiển thị ScreenLoadingOverlay
  → Khi tất cả API trả về → isLoading = false
  → Render KPI cards, charts, tables
```

### 10.2 Filter & Apply Flow

```
Người dùng thay đổi filter (date, warehouse, brand, …)
  → Cập nhật draft state (chưa re-fetch)
  → Click nút "Apply"
      → handleApply() build FlashStatusFilter từ draft state
      → fetchData(filter) gọi lại toàn bộ API
      → applied = filter (lưu bộ lọc đang hiển thị)
      → UI cập nhật theo dữ liệu mới
```

### 10.3 UOM Switch Flow

```
Người dùng đổi UOM (cse / ton / cbm / pallet / do)
  → Không re-fetch API
  → useMemo tính lại statusValues, totalVolume, chart rows theo UOM mới
  → Toàn bộ chart + table re-render với format mới
```

### 10.4 Tab Switch Flow

```
Người dùng click tab (Chart / Table Detail)
  → LeftStickySectionTabs cập nhật active tab
  → Chart section ẩn / hiện tương ứng (không re-fetch)
  → Table Detail hiển thị FlashSummaryByDimensionRow theo dimension đang chọn
```

### 10.5 Export Flow

```
Người dùng click Export
  → ViewQueryExportActions gọi fetchFlashDetailRows(applied)
  → Trả về FlashDetailRow[] (toàn bộ đơn hàng chi tiết)
  → Xuất file (Excel/CSV) với các sheet:
      Status Summary | Warehouse Progress | Customer Progress
      Delivery Area  | Sales Channel      | E2E Distribution
      Dropped Delivery | Dropped Reason
```

### 10.6 ETD Auto-Switch Rule

```
Khi người dùng mở trang (hoặc refresh):
  IF giờ hiện tại ≥ 15:00
    → dateFrom = dateTo = ngày mai (tomorrow)
  ELSE
    → dateFrom = dateTo = hôm nay (today)
Người dùng vẫn có thể override bằng Date picker thủ công.
```

### 10.7 Error Handling Flow

```
fetchData() thất bại (network lỗi / API 5xx)
  → isLoading = false
  → loadError = message lỗi
  → Hiển thị error banner, giữ nguyên dữ liệu cũ (nếu có)
  → Người dùng có thể click Apply lại để retry
```
