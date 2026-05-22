# Spec – Shipping Progress (Tiến độ xuất hàng)

**UI:** `control-tower/ui/src/views/control-tower/order-monitor/ShippingProgressView.tsx`
**API:** `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs` (lines 1731–1972)
**Wireframe:** `docs/02-features/tien_do_xuat_hang/shipping-progress.wireframe.md`
**Data source:** `analytics_workspace.mv_flash_report` UNION ALL `analytics_workspace.mv_dropped_report` (ClickHouse, refresh 5–30 phút)

---

## 1. Overview

Màn hình giám sát realtime tiến độ thực thi kế hoạch xuất hàng theo 4 đơn vị (UOM) song song:

- **CBM** (Cubic Meter — đơn vị gốc volume)
- **Tấn** (kg ÷ 1000)
- **Đơn** (Delivery Order — DO count)
- **Chuyến** (Trip count)

Mỗi UOM hiển thị 4 metric: **Kế hoạch** (planned theo gửi thầu) / **Đã nhận** (received, `status = 'ShipCompleted'`) / **Pending** (chênh lệch) / **% Pending** (tỷ lệ chưa xuất / kế hoạch).

Định nghĩa KPI chuẩn: xem `docs/02-features/tien_do_xuat_hang/shipping-progress.prd.md` § 5.6 "Business Logic Specification".

---

## 2. API Endpoints

**`ShippingProgressSummaryFilter`:** `{ dateType?, fromDate?, toDate?, groupName?, whseid?, brand?, area?, transporter? }`

- `dateType` enum: `'Ngày gửi thầu'` (default) | `'ETD gửi thầu'`
- Tất cả filter mặc định `'ALL'` nếu không truyền (trừ `fromDate, toDate` mandatory).

### 2.1 Endpoints (6)

| Function | API Path | Return Type | Mô tả |
|---|---|---|---|
| `fetchShippingProgressSummary` | `GET /api/ctower/shipping-progress/summary` | `ShippingProgressSummary` | KPI tổng (4 UOM × 4 metrics = 16 numbers) |
| `fetchShippingProgressSummaryTable` | `GET /api/ctower/shipping-progress/summary-table` | `ShippingProgressSummaryTableRow[]` | Bảng tổng hợp theo Warehouse × Khu vực × Transporter |
| `fetchShippingProgressPivotByOperationVehicle` | `GET /api/ctower/shipping-progress/pivot-by-operation-vehicle` | `ShippingProgressPivotByOperationVehicleRow[]` | Pivot theo `loai_xe_van_hanh` |
| `fetchShippingProgressPivotByWarehouse` | `GET /api/ctower/shipping-progress/pivot-by-warehouse` | `ShippingProgressPivotByWarehouseRow[]` | Pivot theo `whseid` |
| `fetchShippingProgressPivotByArea` | `GET /api/ctower/shipping-progress/pivot-by-area` | `ShippingProgressPivotByAreaRow[]` | Pivot theo `khu_vuc_doi_xe` |
| `fetchShippingProgressPivotByCargoGroup` | `GET /api/ctower/shipping-progress/pivot-by-cargo-group` | `ShippingProgressPivotByCargoGroupRow[]` | Pivot theo `group_of_cago` |

**Export:** `POST /api/ctower/shipping-progress/export` — body `ExportRowsRequest`.

### 2.2 DTO shapes

```ts
ShippingProgressSummary = {
  cbmKeHoach, cbmDaNhan, cbmPending, pctCbmPending,
  tanKeHoach, tanDaNhan, tanPending, pctTanPending,
  donKeHoach, donDaNhan, donPending, pctDonPending,
  chuyenKeHoach, chuyenDaNhan, chuyenPending, pctChuyenPending
}

ShippingProgressSummaryTableRow = {
  whseid, khuVucDoiXe, tenNganNhaVanTai,                  // 3 dimensions
  doKeHoach, doDaXuat, doPending,                         // Đơn (note: doDaXuat, không phải doDaNhan)
  cbmKeHoach, cbmDaNhan, cbmPending,
  tanKeHoach, tanDaXuat, tanPending                       // Tấn (note: tanDaXuat)
}

ShippingProgressPivotByXxxRow = {
  <dimensionField>,                                       // loaiXeVanHanh / whseid / khuVucDoiXe / groupOfCago
  soChuyenKeHoach, soChuyenDaNhan, soChuyenPending,       // Chuyến
  tanKeHoach, tanDaNhan, tanPending,                      // Tấn
  khoiKeHoach, khoiDaNhan, khoiPending,                   // CBM (named "khoi")
  donKeHoach, donDaNhan, donPending                       // Đơn
}
```

> **Naming inconsistency**: `SummaryTableRow` dùng `doDaXuat / tanDaXuat`; pivot rows dùng `donDaNhan / tanDaNhan / khoiDaNhan`. Cần align ở Phase 2 hoặc map ở UI.

---

## 3. State Management

| State | Type | Default | Mô tả |
|---|---|---|---|
| `draftFilter` | `ReportFilter` | `buildDefaultFilter()` | Filter người dùng đang chọn (chưa Apply) |
| `appliedFilter` | `ReportFilter` | `buildDefaultFilter()` | Filter đã Apply (trigger fetch) |
| `summary` | `ShippingProgressSummary` | `ZERO_SUMMARY` (16 zeros) | KPI tổng |
| `summaryTableRows` | `ShippingProgressSummaryTableRow[]` | `[]` | Bảng tổng hợp |
| `pivotWarehouseRows` | `ShippingProgressPivotByWarehouseRow[]` | `[]` | Pivot kho |
| `pivotAreaRows` | `ShippingProgressPivotByAreaRow[]` | `[]` | Pivot khu vực |
| `pivotOperationVehicleRows` | `ShippingProgressPivotByOperationVehicleRow[]` | `[]` | Pivot loại xe vận hành |
| `pivotCargoGroupRows` | `ShippingProgressPivotByCargoGroupRow[]` | `[]` | Pivot nhóm hàng |
| `summaryTableSort` / `pivotXxxSort` | `SortState<…SortKey>` | `{ key: null, direction: 'none' }` | Sort 3-state per table |
| `summaryTableSearch` / `pivotXxxSearch` | `Record<…SortKey, string>` | empty strings | Per-column search input |
| `isLoading` | `boolean` | `false` | Loading state |
| `apiError` | `string \| null` | `null` | Lỗi API |
| `exportModal` | `{ … } \| null` | `null` | State modal export |

> **Pattern:** Draft → Apply (giống OTIF View). Fetch chỉ trigger khi `appliedFilter` đổi.

---

## 4. Filters & Inputs

| Filter | Loại UI | Options | Cột MV / Param |
|---|---|---|---|
| Loại Ngày | Single-select dropdown | `'Ngày gửi thầu'` (default) / `'ETD gửi thầu'` | `dateType` → chọn `thoi_gian_gui_thau` hoặc `etd_chuyen_gui_thau` |
| Date Range | Date picker (from–to) | mandatory | `fromDate`, `toDate` |
| Warehouse | Single-select | `'ALL'` + danh sách `whseid` | `whseid` |
| Area | Single-select | `'ALL'` + danh sách `khu_vuc_doi_xe` | `area` → `khu_vuc_doi_xe` |
| Channel | Single-select | `'ALL'` + danh sách `group_name` | `groupName` → `group_name` |
| Brand | Single-select | `'ALL'` + danh sách `brand` | `brand` |
| Vendor (Nhà vận tải) | Single-select | `'ALL'` + danh sách `ten_ngan_nha_van_tai` | `transporter` → `ten_ngan_nha_van_tai` |

**Fallback rules (SQL):**
- `'ALL'` → bỏ qua filter
- NULL value → `coalesce(<col>, 'Unclassified')` (riêng `whseid` exact match, không coalesce)

---

## 5. Derived / Computed Data

| Item | Mô tả |
|---|---|
| `kpiCards` | Map `summary` → 4 cards (CBM/Tấn/Đơn/Chuyến) với 4 numbers mỗi card; color theo `pct*Pending` threshold |
| `byWarehouseChart` | Map `pivotWarehouseRows` → stacked bar (Đã nhận / Pending) per warehouse |
| `byAreaChart` | Map `pivotAreaRows` → stacked bar per area |
| `byVehicleChart` | Map `pivotOperationVehicleRows` → horizontal progress bar per loại xe vận hành |
| `byCargoChart` | Map `pivotCargoGroupRows` → horizontal progress bar per nhóm hàng |
| `summaryTableFiltered` | Apply per-column search trên `summaryTableRows` |
| `summaryTableSorted` | Apply `summaryTableSort` lên rows đã filter |

Mỗi pivot table có cùng pattern filter+sort.

---

## 6. Business Logic Rules

> **Source of truth**: `analytics_workspace.mv_flash_report` UNION ALL `mv_dropped_report`. Logic chi tiết tại PRD § 5.6 "Business Logic Specification".

### 6.1 Status classification

| status | Tính vào "Đã nhận"? | Distribution (toàn MV) |
|---|---|---|
| `ShipCompleted` | ✅ | 6,213,060 (99.88%) |
| `New` | ❌ (pending) | 4,986 (0.08%) |
| `Picked` | ❌ (pending) | 2,124 |
| `Allocated` | ❌ (pending) | 140 |
| `PartPick` | ❌ (pending) | 91 |

### 6.2 Công thức KPI per UOM

```sql
-- Kế hoạch (planned, từ original_*)
ke_hoach   = SUM(coalesce(original_<unit>, 0))           -- CBM, Tấn (kg/1000)
ke_hoach   = countDistinct(<id>)                          -- Đơn, Chuyến

-- Đã nhận (received, status='ShipCompleted')
da_nhan    = SUM(if(status='ShipCompleted', coalesce(shipped_<unit>, 0), 0))
da_nhan    = countDistinct(if(status='ShipCompleted', <id>, NULL))

-- Pending (chênh lệch)
pending    = ke_hoach - da_nhan
pct_pending = pending / nullIf(ke_hoach, 0)              -- NULL nếu mẫu = 0
```

### 6.3 Per-UOM mapping

| UOM | Ke_hoach SQL | Da_nhan SQL |
|---|---|---|
| **CBM** | `SUM(coalesce(original_cbm, 0))` | `SUM(if(status='ShipCompleted', coalesce(shipped_cbm, 0), 0))` |
| **Tấn** | `SUM(coalesce(original_kg, 0)) / 1000.0` | `SUM(if(status='ShipCompleted', coalesce(shipped_kg, 0), 0)) / 1000.0` |
| **Đơn** | `countDistinct(ma_don_hang)` | `countDistinct(if(status='ShipCompleted', ma_don_hang, NULL))` |
| **Chuyến** | `countDistinct(so_chuyen)` | `countDistinct(if(status='ShipCompleted', so_chuyen, NULL))` |

### 6.4 Filter Behavior (SQL)

```sql
-- Date filter (CASE chọn cột theo dateType)
toDate(
  CASE WHEN p_loai_ngay = 'Ngày gửi thầu' THEN thoi_gian_gui_thau
       WHEN p_loai_ngay = 'ETD gửi thầu'  THEN etd_chuyen_gui_thau
       ELSE thoi_gian_gui_thau END
) BETWEEN p_from AND p_to

-- Dimension filters (mỗi filter pattern)
AND (p_<filter> = 'ALL' OR coalesce(<col>, 'Unclassified') = p_<filter>)
-- Riêng whseid: AND (p_whseid = 'ALL' OR whseid = p_whseid)
```

---

## 7. Color / Status Coding

| KPI | 🟢 Green | 🟡 Amber | 🔴 Red |
|---|---|---|---|
| % Pending (mọi UOM) | < 10% | 10–25% | > 25% |

Áp dụng cho:
- 4 KPI summary cards (badge % Pending)
- Pivot charts (cell highlight nếu vượt threshold)

> Threshold đang là default; PRD Q2 cần stakeholder confirm có cần threshold khác cho intraday vs end-of-day.

---

## 8. User Interactions

| Tương tác | Hành động |
|---|---|
| Đổi filter dropdown | Cập nhật `draftFilter` |
| Click **Apply Filters** | `setAppliedFilter(draftFilter)` → trigger Promise.all 6 fetches song song |
| Đổi Tab (Chart / Detail Table) | Toggle giữa 2 view |
| Hover chart | Tooltip Recharts hiển thị chi tiết |
| Sort table column | `nextSortState` toggle desc → asc → none |
| Search column | Per-column input filter (client-side) |
| Click **Export** | Mở modal export, gọi `POST /shipping-progress/export` |
| Click **Cấu hình bảng** | (TBD) mở dialog ẩn/hiện cột |

---

## 9. Sub-components

| Component | Vai trò |
|---|---|
| `ViewQueryExportActions` | Export + Query action bar |
| `ControlTowerItemCard` | KPI card per UOM (4 cards: CBM / Tấn / Đơn / Chuyến) |
| `LeftStickySectionTabs` | Tab navigation (Chart / Detail Table) |
| `SortableHeader` | Header với 3-state sort |
| `ChartHint` | Tooltip giải thích công thức KPI |
| Recharts: `BarChart`, `Bar` (stacked) | Charts theo Warehouse, Area |
| Recharts: horizontal bar | Charts theo Operation Vehicle, Cargo Group |

---

## 9.1 Layout (theo wireframe)

### Tab "Chart"

```
┌─ Filter bar: Loại Ngày | Date Range | Warehouse | Area | Channel | Brand | Vendor | [Apply] ──────┐
├─ Tab toggle: Chart | Detail Table
│
├─ 4 KPI summary cards (1 row, 1 per UOM):
│   ┌── CBM Summary ──┐ ┌── Tấn Summary ──┐ ┌── Đơn Summary ──┐ ┌── Chuyến Summary ──┐
│   │ Kế hoạch / Đã nhận / Pending / % Pending (tone color theo % Pending)              │
│   └─────────────────┘ └─────────────────┘ └─────────────────┘ └────────────────────┘
│
├─ Chart 1: "Progress by Warehouse" — stacked bar (Đã nhận / Pending) per whseid
├─ Chart 2: "Progress by Area" — stacked bar per khu_vuc_doi_xe
├─ Chart 3: "Progress by Operation Vehicle" — horizontal progress bar
└─ Chart 4: "Progress by Cargo Group" — horizontal progress bar per group_of_cago
```

### Tab "Detail Table"

```
├─ Filter bar (giống Tab Chart)
└─ Bảng "Summary Table"
      Cột: Warehouse | Area | Vendor | (per-column search) | DO Kế hoạch | DO Đã xuất | DO Pending |
            CBM Kế hoạch | CBM Đã nhận | CBM Pending | Tấn Kế hoạch | Tấn Đã xuất | Tấn Pending
      Sort 3-state per column, per-column search input, Export button, pagination
```

---

## 10. Loading & Error States

| Tình huống | Xử lý |
|---|---|
| Đang fetch API | `isLoading = true` → hiển thị skeleton/spinner |
| API error | `apiError != null` → hiển thị error banner; tables/charts hiển thị empty |
| `summary == ZERO_SUMMARY` | KPI cards hiển thị 0/0/0/0% (default state) |
| Empty pivot rows (filter quá hẹp) | Chart hiển thị empty state |
| Tổng kế hoạch = 0 | `pct_pending = NULL` (do `nullIf`); UI fallback `?? 0%` |

---

## 11. Edge Cases

| # | Tình huống | Xử lý production |
|---|---|---|
| E1 | Tổng `ke_hoach = 0` (filter quá hẹp) | SQL: `pct_pending = NULL`; UI fallback hiển thị `0%` |
| E2 | `shipped > original` (giao thừa kế hoạch) | `pending < 0` (negative); SQL không clamp — **`[TBD]` BA confirm** (PRD Q1) |
| E3 | `original_cbm/kg = NULL` | SQL `coalesce(..., 0)` → tính như 0, không crash |
| E4 | NULL `group_name` / `brand` / `khu_vuc_doi_xe` / `transporter` | SQL `coalesce → 'Unclassified'`; UI dropdown chỉ hiển thị giá trị non-empty |
| E5 | NULL `whseid` | SQL không coalesce — rows này có thể bị miss khi filter cụ thể; cần verify upstream không có NULL whseid |
| E6 | Date range chọn ngày tương lai | Trả empty data; UI hiển thị 0s |
| E7 | UNION schema mismatch (`mv_flash_report` ≠ `mv_dropped_report`) | **Risk** — chưa verify column compat; **DA action** (PRD Q2 data quality) |
| E8 | Status mới ngoài 5 giá trị verified | Mặc định rơi vào "pending" (do `if(status='ShipCompleted', …, 0)`) — an toàn |
| E9 | API timeout / 5xx | UI hiển thị error banner; click Apply để retry |
| E10 | Refresh delay MV (5–30 phút) | Không có cảnh báo "data cũ" trong UI |

---

## 12. Workflow

### 12.1 Page Load Flow

```
Người dùng mở Shipping Progress View
  → Khởi tạo default filter: dateType='Ngày gửi thầu', date=current week,
    warehouse/area/channel/brand/vendor='ALL'
  → Promise.all([
      fetchShippingProgressSummary,
      fetchShippingProgressSummaryTable,
      fetchShippingProgressPivotByWarehouse,
      fetchShippingProgressPivotByArea,
      fetchShippingProgressPivotByOperationVehicle,
      fetchShippingProgressPivotByCargoGroup
    ])
  → isLoading=true → render skeleton
  → API trả KPI từ SQL UNION ALL flash + dropped report
  → Render 4 KPI cards + 4 charts + summary table
```

### 12.2 Filter & Apply Flow

```
Người dùng thay đổi filter (loại ngày, date range, warehouse, area, channel, brand, vendor)
  → Cập nhật draftFilter
  → Click Apply Filters → setAppliedFilter(draftFilter)
  → useEffect detect appliedFilter đổi → Promise.all 6 API re-fetch song song
  → KPI tính lại trong SQL (không tính ở UI)
  → UI cập nhật cards + charts + table
```

### 12.3 KPI Calculation (in SQL — UI chỉ display)

```
Per UOM (CBM | Tấn | Đơn | Chuyến):
  → ke_hoach: SUM/COUNT trên toàn rows trong filter scope
  → da_nhan: SUM/COUNT chỉ rows status='ShipCompleted'
  → pending = ke_hoach - da_nhan
  → pct_pending = pending / nullIf(ke_hoach, 0)

Per Pivot dimension (warehouse | area | operation_vehicle | cargo_group):
  → GROUP BY <dimension>
  → Tính cùng formula trên mỗi group
```

### 12.4 Error Handling Flow

```
Bất kỳ fetch nào failed
  → catch → setApiError(message)
  → Reset summary = ZERO_SUMMARY, pivots = []
  → Hiển thị error banner với nút Retry (= click Apply lại)
```

---

## 13. Data Quality Notes (cần DA verify)

| # | Vấn đề | Mức độ |
|---|---|---|
| Q1 | `is_deleted=0` chưa verify ở upstream của `mv_flash_report`, `mv_dropped_report` | 🟡 Medium |
| Q2 | UNION ALL 2 MV — schema compatibility (cùng số cột, cùng order) | 🟡 Medium — **DA cần DESCRIBE 2 MV và compare** |
| Q3 | Cancelled / Virtual / Test orders có lọt vào KPI không | 🟡 Medium |
| Q4 | Internal transfer orders có nằm trong scope không (CLAUDE.md Rule 4) | 🟡 Medium |
| Q5 | Hardcoded date `'2026-03-19 00:00:00'` trong sql-registry.md:10620 | 🟢 Low (artifact, không ảnh hưởng prod) |
| Q6 | Pending có thể âm nếu `shipped > original` (BL-2) | 🟢 Low (Apr 2026 verified không xảy ra) |

---

## 14. Cross-references

- **PRD:** `docs/02-features/tien_do_xuat_hang/shipping-progress.prd.md` (full Business Logic Spec § 5.6)
- **Wireframe:** `docs/02-features/tien_do_xuat_hang/shipping-progress.wireframe.md`
- **GLOSSARY:** `docs/GLOSSARY.md`
- **SQL Registry:** `docs/03-engineering/sql-registry.md` § "Tiến độ xuất hàng - verified" (lines 10427–16320)
- **DDL:** `docs/03-engineering/data-sources/clickhouse-ddl/analytics-workspace_mvs.md`
  - `mv_flash_report` (line 2527, 6.22M rows)
  - `mv_dropped_report` (line 1461, 42K rows)
- **Audit results:**
  - S2 Pipeline: `docs/audit-results/s2-shipping-progress-20260507.md`
- **Code:**
  - UI: `control-tower/ui/src/views/control-tower/order-monitor/ShippingProgressView.tsx`
  - API: `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs:1731–1972`
  - Client: `control-tower/ui/src/api/shippingProgressApi.ts`
