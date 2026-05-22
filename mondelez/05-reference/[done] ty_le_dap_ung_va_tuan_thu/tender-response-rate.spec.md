# Spec – Tender Response Rate View

**UI:** `control-tower/ui/src/views/control-tower/order-monitor/TenderResponseRateView.tsx`
**API:** `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs`
**Wireframe:** `docs/02-features/tender-response-rate/tender-response-rate.wireframe.md`

---

## 1. Overview

Màn hình theo dõi tỷ lệ đáp ứng và tuân thủ tender (đấu thầu vận tải). Phân tích response time, acceptance rates, compliance với terms, và performance theo carrier, route, và thời gian.

---

## 2. API Endpoints

**`TenderFilter`:** `{ locationTo?, locationFrom?, area?, granularity?, dateType?, fromDate?, toDate? }`

| Function | Parameters | Return Type | Mô tả |
|---|---|---|---|
| `fetchTenderResponseRate` | `TenderFilter?` | `TenderResponseRate` | KPI tổng: tyLeDapUngPct, soIdChuyenGuiThauDapUng, soIdChuyenGuiThauKhongDapUng, soIdChuyenGuiThau, soIdChuyenVanHanh |
| `fetchTenderResponseByVendor` | `TenderFilter?` | `TenderResponseByVendorRow[]` | Tỷ lệ đáp ứng theo nhà vận tải (vendorName, rate, ok, nok) |
| `fetchTenderResponseByTime` | `TenderFilter?` | `TenderResponseByTimeRow[]` | Trend tỷ lệ đáp ứng theo thời gian (period, rate, ok, nok) |

---

## 3. State Management

| State | Type | Default | Mô tả |
|---|---|---|---|
| `dateRange` | `{ from: string, to: string }` | last 30 days | Khoảng thời gian |
| `carrierFilter` | `string` | `'ALL'` | Lọc theo carrier |
| `routeFilter` | `string` | `'ALL'` | Lọc theo route |
| `tenderTypeFilter` | `string` | `'ALL'` | Lọc theo loại tender |
| `period` | `'daily' \| 'weekly' \| 'monthly'` | `'weekly'` | Period aggregation |
| `viewMode` | `'response' \| 'compliance' \| 'performance'` | `'response'` | Chế độ xem |
| `responseData` | `TenderResponseRecord[]` | `[]` | Dữ liệu response từ API |
| `summaryData` | `ResponseSummary[]` | `[]` | Dữ liệu summary |
| `kpis` | `ComplianceKPIs` | `{}` | KPIs tổng hợp |
| `loading` | `boolean` | `true` | Loading state |
| `error` | `string \| null` | `null` | Lỗi |
| `lastUpdated` | `string` | `''` | Thời gian cập nhật cuối |

---

## 4. Filters & Inputs

| Filter | Options | Áp dụng cho |
|---|---|---|
| Date Range | Date picker | Tất cả tabs |
| Carrier | `ALL` + danh sách carriers | Tất cả tabs |
| Route | `ALL` + danh sách routes | Response & Performance tabs |
| Tender Type | `ALL` + danh sách tender types | Compliance tab |
| Period | `daily`, `weekly`, `monthly` | Summary views |
| View Mode | `response`, `compliance`, `performance` | Chuyển đổi tab |

---

## 5. Derived / Computed Data

| useMemo | Mô tả |
|---|---|
| `filteredData` | Áp dụng filters cho responseData |
| `responseRate` | Tính % response rate (responses / tenders sent) |
| `acceptanceRate` | Tính % acceptance rate (accepted / responded) |
| `averageResponseTime` | Thời gian trung bình response |
| `complianceMetrics` | Tuân thủ terms và conditions |
| `carrierPerformance` | Hiệu suất theo carrier |

---

## 6. Business Logic Rules

| Rule | Điều kiện / Công thức |
|---|---|
| **Response Rate %** | (Responses Received / Tenders Sent) × 100% |
| **Acceptance Rate %** | (Accepted Tenders / Responses Received) × 100% |
| **Average Response Time** | Tổng response time / số responses |
| **Compliance Score** | Based on adherence to terms (0-100) |
| **Status: Excellent** | Response Rate > 95% & Response Time < 2h |
| **Status: Good** | Response Rate 90-95% & Response Time < 4h |
| **Status: Needs Improvement** | Response Rate 80-90% |
| **Status: Critical** | Response Rate < 80% |
| **Compliance: High** | Score > 90 |
| **Compliance: Medium** | Score 70-90 |
| **Compliance: Low** | Score < 70 |

---

## 7. Color / Status Coding

| Trạng thái | Màu | Điều kiện |
|---|---|---|
| Excellent | Green | Response Rate > 95% & Response Time < 2h |
| Good | Blue | Response Rate 90-95% & Response Time < 4h |
| Needs Improvement | Amber | Response Rate 80-90% |
| Critical | Red | Response Rate < 80% |
| Responded | Green | Tender responded |
| Accepted | Blue | Tender accepted |
| Rejected | Red | Tender rejected |
| Pending | Gray | Awaiting response |

---

## 8. Workflow

### 8.1 Page Load Flow

```
Người dùng mở Tender Response Rate View
  → Khởi tạo default filter:
      period = current month, carrier = "ALL", route = "ALL", tender type = "ALL"
  → fetchTenderResponseRate() gọi API
  → isLoading = true → hiển thị loading state
  → Render KPI cards (response rate %, acceptance rate %, avg response time), charts, carrier table
```

### 8.2 Filter & Apply Flow

```
Người dùng thay đổi filter (period, carrier, route, tender type)
  → Cập nhật draft state
  → Click Apply → fetchData(filter) re-fetch
  → UI cập nhật charts + table
```

### 8.3 Carrier Compliance Monitoring Flow

```
Hệ thống theo dõi từng carrier theo vòng đời tender:
  → Pending (Gray): tender đã gửi, chưa có phản hồi
  → Responded (Green): carrier đã phản hồi trong thời hạn
  → Accepted (Blue): carrier chấp nhận tender
  → Rejected (Red): carrier từ chối tender
  → Response Rate = Số tender đã phản hồi / Tổng tender gửi × 100
  → Avg Response Time = Trung bình giờ từ khi gửi → khi nhận phản hồi
  → Compliance badge:
      Excellent (>95%, <2h) | Good (90-95%, <4h) | Needs Improvement (80-90%) | Critical (<80%)
  → Carrier nào Critical → highlight đỏ trong bảng → cần escalation
```

### 8.4 Error Handling Flow

```
fetchTenderResponseRate() thất bại
  → isLoading = false
  → Hiển thị error message
  → Charts/table hiển thị empty state
  → Retry bằng click Apply lại
```