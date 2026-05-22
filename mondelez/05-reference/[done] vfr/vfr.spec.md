# Spec – VFR View (Vehicle Fill Rate)

**UI:** `control-tower/ui/src/views/control-tower/order-monitor/VFRView.tsx`
**API:** `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs`
**Wireframe:** `docs/02-features/vfr/vfr.wireframe.md`

---

## 1. Overview

Màn hình theo dõi tỷ lệ lấp đầy phương tiện (Vehicle Fill Rate - VFR). Phân tích utilization của trucks/containers theo route, product type, và thời gian. Hiển thị KPIs về space utilization và optimization opportunities.

---

## 2. API Endpoints

**`VfrFilter`:** `{ mode?, locationFrom?, area?, vendor?, tenderVehicleType?, dateType?, fromDate?, toDate? }`

| Function | Parameters | Return Type | Mô tả |
|---|---|---|---|
| `fetchVfrTenderKpi` | `VfrFilter?` | `VfrTenderKpi` | KPI tổng VFR: avgVfr, lowUnder50Count, medium50To70Count, high70To95Count, excellent95UpCount |
| `fetchVfrTenderByArea` | `VfrFilter?` | `VfrTenderAreaChartRow[]` | VFR theo khu vực giao hàng (area, planned, vfr) |
| `fetchVfrTenderByVehicle` | `VfrFilter?` | `VfrTenderVehicleChartRow[]` | VFR theo loại xe (vehicle, registeredCbm, vfr) |
| `fetchVfrTenderLoadingTypeTrend` | `VfrFilter?` | `VfrTenderLoadingTypeTrendRow[]` | Trend VFR theo loại loading theo thời gian |
| `fetchVfrTenderTimeAreaTrend` | `VfrFilter?` | `VfrTenderTimeAreaTrendRow[]` | Trend VFR theo thời gian × khu vực |

> `mode: 'tender' | 'operation'` — mặc định là `'tender'`. Tender mode: phân tích các chuyến gửi đấu thầu; Operation mode: phân tích các chuyến vận hành.

---

## 3. State Management

| State | Type | Default | Mô tả |
|---|---|---|---|
| `dateRange` | `{ from: string, to: string }` | last 7 days | Khoảng thời gian |
| `routeFilter` | `string` | `'ALL'` | Lọc theo route |
| `vehicleTypeFilter` | `string` | `'ALL'` | Lọc theo loại phương tiện |
| `productTypeFilter` | `string` | `'ALL'` | Lọc theo loại sản phẩm |
| `period` | `'daily' \| 'weekly' \| 'monthly'` | `'daily'` | Period aggregation |
| `viewMode` | `'fill-rate' \| 'utilization' \| 'optimization'` | `'fill-rate'` | Chế độ xem |
| `vfrData` | `VFRRecord[]` | `[]` | Dữ liệu VFR từ API |
| `summaryData` | `VFRSummary[]` | `[]` | Dữ liệu summary |
| `kpis` | `VFRKPIs` | `{}` | KPIs tổng hợp |
| `loading` | `boolean` | `true` | Loading state |
| `error` | `string \| null` | `null` | Lỗi |
| `lastUpdated` | `string` | `''` | Thời gian cập nhật cuối |

---

## 4. Filters & Inputs

| Filter | Options | Áp dụng cho |
|---|---|---|
| Date Range | Date picker | Tất cả tabs |
| Route | `ALL` + danh sách routes | Fill-rate & Utilization tabs |
| Vehicle Type | `ALL` + danh sách vehicle types | Tất cả tabs |
| Product Type | `ALL` + danh sách product types | Fill-rate tab |
| Period | `daily`, `weekly`, `monthly` | Summary views |
| View Mode | `fill-rate`, `utilization`, `optimization` | Chuyển đổi tab |

---

## 5. Derived / Computed Data

| useMemo | Mô tả |
|---|---|
| `filteredData` | Áp dụng filters cho vfrData |
| `fillRatePercentage` | Tính % fill rate (loaded / capacity) |
| `utilizationMetrics` | Weight, volume, pallet utilization |
| `routePerformance` | Hiệu suất theo route |
| `optimizationSuggestions` | Gợi ý tối ưu loading |
| `vehicleTypeComparison` | So sánh giữa các loại vehicle |

---

## 6. Business Logic Rules

| Rule | Điều kiện / Công thức |
|---|---|
| **Fill Rate %** | (Loaded Volume / Vehicle Capacity) × 100% |
| **Weight Utilization** | (Loaded Weight / Max Weight) × 100% |
| **Volume Utilization** | (Loaded Volume / Max Volume) × 100% |
| **Pallet Utilization** | (Loaded Pallets / Max Pallets) × 100% |
| **Overall Utilization** | Average of weight/volume/pallet utilizations |
| **Status: Excellent** | Fill Rate > 90% |
| **Status: Good** | Fill Rate 80-90% |
| **Status: Needs Improvement** | Fill Rate 70-80% |
| **Status: Critical** | Fill Rate < 70% |

---

## 7. Color / Status Coding

| Trạng thái | Màu | Điều kiện |
|---|---|---|
| Excellent | Green | Fill Rate > 90% |
| Good | Blue | Fill Rate 80-90% |
| Needs Improvement | Amber | Fill Rate 70-80% |
| Critical | Red | Fill Rate < 70% |
| Underutilized | Orange | Fill Rate < 50% |
| Overloaded | Red | Weight/Volume > 100% |

---

## 8. Workflow

### 8.1 Page Load Flow

```
Người dùng mở VFR (Vehicle Fill Rate) View
  → Khởi tạo default filter:
      date range = current month, route = "ALL", vehicle type = "ALL"
  → fetchVFR() gọi API
  → isLoading = true → hiển thị loading state
  → Render KPI cards (avg fill rate, % Excellent/Good/Critical), charts, route detail table
```

### 8.2 Filter & Apply Flow

```
Người dùng thay đổi filter (date range, route, vehicle type, carrier)
  → Cập nhật draft state
  → Click Apply → fetchData(filter) re-fetch
  → UI cập nhật charts + table theo filter mới
```

### 8.3 Fill Rate Analysis Flow

```
Hệ thống tính VFR theo 3 chiều song song:
  → Weight Fill Rate = Tổng trọng lượng hàng / Tải trọng xe × 100
  → Volume Fill Rate = Tổng CBM hàng / Thể tích thùng xe × 100
  → Pallet Fill Rate = Số pallet / Sức chứa pallet tối đa × 100
  → VFR tổng hợp = min(Weight FR, Volume FR, Pallet FR)  ← ràng buộc vật lý
  → Status badge tự động:
      Excellent (>90%) | Good (80-90%) | Needs Improvement (70-80%) | Critical (<70%)
  → Underutilized (Orange): Fill Rate < 50% → lãng phí năng lực xe
  → Overloaded (Red): Weight/Volume > 100% → vi phạm quy định tải trọng
  → Route ranking: sắp xếp theo VFR tăng dần (critical routes lên đầu)
```

### 8.4 Optimization Recommendation Flow

```
Khi VFR của route/vehicle < 70% (Critical):
  → Highlight row màu đỏ trong table
  → Gợi ý: gom chuyến (consolidation) để tăng fill rate
Khi Weight > 100% hoặc Volume > 100% (Overloaded):
  → Cảnh báo vi phạm tải trọng / thể tích
  → Cần điều chỉnh kế hoạch bốc xếp trước khi xe xuất phát
```

### 8.5 Error Handling Flow

```
fetchVFR() thất bại
  → isLoading = false
  → Hiển thị error message
  → Charts/table hiển thị empty state
  → Retry bằng click Apply lại
```