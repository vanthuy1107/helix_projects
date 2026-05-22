# Spec — Section Flash Daily

> **Phạm vi:** Tài liệu kỹ thuật chi tiết cho widget `WidgetFlashDaily`.
> **Nguồn:** 100% trích xuất từ source code — `widget-flash-daily.tsx` (2,893 dòng), `widget-flash-daily-detail.tsx` (172 dòng), `widget-flash-daily.columns.tsx` (436 dòng), `widget-flash-daily-settings-dialog.tsx` (291 dòng), `flash-report-api.ts` (65 dòng), `dashboard-flash-report.json` (104 dòng).
>
> **Version**: 1.1.0 — Storytelling refresh 2026-05-16. Đi cùng [`flash-daily-prd.md`](flash-daily-prd.md) v1.1.0. Source of truth cho decisions: [`analysis/flash-daily-oq-resolution.md`](analysis/flash-daily-oq-resolution.md) §0-LOCKED + §0a Decisions Log + §0c Audit findings.

---

## 1. Component Tree

```
WidgetFlashDaily
├── SqlFilterPanel (sticky, autoApply)               ← khi filterStorageKey tồn tại
│   └── FLASH_FILTER_DEFINITIONS (8 filter fields)
├── Loading skeleton (h-20 + 6×h-20 grid + h-64)     ← isInitialLoading
├── Error banner                                      ← sqlError exists
└── Tabs
    ├── Tab "chart"                                   ← default
    │   ├── StatusCard grid (1/2/3 cols)
    │   │   ├── StatusCard: Tổng Volume Kế hoạch   (color: #10B981, icon: Box)
    │   │   ├── StatusCard: Chưa xuất kho           (color: #858585, icon: Layers)
    │   │   ├── StatusCard: Đang xuất kho           (color: #E18719, icon: TrendingUp)
    │   │   ├── StatusCard: Đã xuất kho             (color: #4F2170, icon: Truck)
    │   │   ├── StatusCard: Đang vận chuyển         (color: #2D6EAA, icon: Truck)
    │   │   └── StatusCard: Đã vận chuyển           (color: #287819, icon: Truck)
    │   ├── SectionPanel: Theo khu vực giao hàng    (horizontal stacked bar, dynamic height)
    │   ├── Grid 2 cols (xl)
    │   │   ├── SectionPanel: Phân bổ E2E           (vertical 7-bar, h=288px)
    │   │   └── SectionPanel: Tiến độ theo kho      (vertical stacked, h=384px)
    │   ├── SectionPanel: Theo NPP/Customer         (horizontal stacked, dynamic, top 10)
    │   │   └── Dropdown: customerDimensionFilter (Tất cả / NPP / Customer)
    │   └── SectionPanel: Theo kênh bán hàng        (horizontal stacked, dynamic)
    └── Tab "table"
        └── FlashDailyDetailPanel
            ├── WidgetGrid DSHFLADTG01: Report tỷ lệ hoàn thành        (page 20)
            ├── WidgetGrid DSHFLADTG02: Báo cáo chi tiết E2E           (page 10)
            ├── WidgetGrid DSHFLADTG03: Tổng hợp theo kho              (page 10)
            ├── WidgetGrid DSHFLADTG04: Tổng hợp theo NPP/Customer     (page 10)
            ├── WidgetGrid DSHFLADTG05: Tổng hợp theo khu vực          (page 10)
            ├── WidgetGrid DSHFLADTG06: Tổng hợp theo kênh bán hàng    (page 10)
            ├── WidgetGrid DSHFLADTG07: Report hàng rớt                (page 20)
            ├── WidgetGrid DSHFLADTG08: Report lý do rớt đơn           (page 10)
            └── WidgetGrid DSHFLADTG09: Chi tiết Flash (32 cột)        (page 20)
```

---

## 2. State Management

### 2.1 Filter state — applied

> **[Observed]** — [widget-flash-daily.tsx:1026-1039](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1026-L1039).

Widget chỉ giữ 1 set state `applied: FlashStatusFilter` (KHÔNG có draft/applied tách rời như OTIF — vì `SqlFilterPanel` chạy `autoApply`):

| Field | Type | Mặc định |
|-------|------|---------|
| `uom` | `'cse' \| 'ton' \| 'cbm' \| 'pallet' \| 'do'` | `'cse'` |
| `dateType` | `string` | `'GI date'` |
| `fromDate` | `string` (YYYY-MM-DD) | `toYmd(thisMonthToTodayRange().from)` |
| `toDate` | `string` (YYYY-MM-DD) | `toYmd(thisMonthToTodayRange().to)` |
| `groupName` | `string` | `'ALL'` |
| `whseid` | `string` (CSV nếu multi) | `'ALL'` |
| `brand` | `string` (CSV nếu multi) | `'ALL'` |
| `groupOfCargo` | `string` (CSV nếu multi) | `'ALL'` |
| `region` | `string` (CSV nếu multi) | `'ALL'` |

### 2.2 Derived filterOverrides

```ts
buildFilterOverrides(filter) = {
  uom:            filter.uom ?? '',
  date_type:      filter.dateType !== 'ALL' ? filter.dateType : '',
  dateType:       (alias above)
  from_date:      `${filter.fromDate} 00:00:00`,
  to_date:        `${filter.toDate} 23:59:59`,
  group_name:     filter.groupName !== 'ALL' ? filter.groupName : '',
  whseid:         filter.whseid !== 'ALL' ? filter.whseid : '',
  brand:          filter.brand !== 'ALL' ? filter.brand : '',
  group_of_cargo: filter.groupOfCargo !== 'ALL' ? filter.groupOfCargo : '',
  groupOfCargo:   (alias above)
  region:         filter.region !== 'ALL' ? filter.region : '',
}
```

### 2.3 Các state cục bộ khác

| State | Type | Mặc định | Mô tả |
|-------|------|---------|-------|
| `filterInitialized` | `boolean` | `!filterStorageKey` | Guard tránh fetch khi filter chưa restore. `false` khi widget có storage key, `true` khi không. |
| `customerDimensionFilter` | `'all' \| 'npp' \| 'customer'` | `'all'` | Filter cục bộ cho chart "Theo NPP/Customer" — KHÔNG persist, KHÔNG trigger refetch (chỉ filter client-side). |
| `sqlFilterSettingsOpen` | `boolean` | `false` | Mở/đóng dialog filter settings (chỉ edit mode). |

### 2.4 Query keys

Mỗi useQuery có pattern key:
```ts
['flash-daily', '<query-name>', dashboardId, widgetId, sectionKey, applied]
```

Cache: `staleTime = 5 * 60 * 1000` (5 phút), `placeholderData = prev` (giữ data cũ).

---

## 3. Data Fetching

### 3.1 17 useQuery song song

> **[Observed]** — [widget-flash-daily.tsx:1185-1470](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1185-L1470).

Tất cả query enable khi `widgetReady = hasSqlConfig && dashboardId && widgetId && filterInitialized`.

| # | Query name | Section key resolve | pageSize | Mục đích |
|---|------------|--------------------|---------|---------| 
| 1 | sql-cards | `cardKpiStatus → cards` | 5000 | 6 KPI cards (UOM hiện hành) |
| 2 | sql-cards-cbm | `cardKpiStatus → cards`, force `uom='cbm'` | 5000 | Subtitle "Số kế hoạch (CBM)" |
| 3 | sql-charts | `charts → cards` | 5000 | Legacy fallback chia sẻ |
| 4 | sql-chart-e2e | `chartE2e → charts → cards` | 5000 | Chart Phân bổ E2E |
| 5 | sql-chart-warehouse | `chartWarehouse → charts` | 5000 | Chart Tiến độ theo kho |
| 6 | sql-chart-delivery-area | `chartDeliveryArea → charts` | 5000 | Chart Theo khu vực |
| 7 | sql-chart-customer | `chartCustomer → charts` | 5000 | Chart Theo NPP/Customer |
| 8 | sql-chart-sales-channel | `chartSalesChannel → charts` | 5000 | Chart Theo kênh bán |
| 9 | sql-table | `table` | 5000 | Legacy fallback chia sẻ |
| 10 | sql-table-detail | `tableDetail → table` | 5000 | T9 Chi tiết Flash |
| 11 | tbl-completion | `tblCompletion` | 5000 | T1 Report tỷ lệ hoàn thành |
| 12 | tbl-e2e-detail | `tblE2eDetail` | 5000 | T2 Báo cáo chi tiết E2E |
| 13 | tbl-summary-wh | `tblSummaryWh` | 5000 | T3 Tổng hợp theo kho |
| 14 | tbl-summary-customer | `tblSummaryCustomer` | 5000 | T4 Tổng hợp theo NPP/Customer |
| 15 | tbl-summary-area | `tblSummaryArea` | 5000 | T5 Tổng hợp theo khu vực |
| 16 | tbl-summary-channel | `tblSummaryChannel` | 5000 | T6 Tổng hợp theo kênh bán |
| 17 | tbl-dropped | `tblDropped` | 5000 | T7 Report hàng rớt |
|  | tbl-dropped-reason | `tblDroppedReason` | 5000 | T8 Report lý do rớt |

Mỗi query gọi `dashboardV2Api.executeWidget(dashboardId, widgetId, { sectionKey, filterOverrides, pageSize: 5000 })`. Nếu `result.error` → throw, useQuery sẽ surface error qua hook return.

### 3.2 Error aggregation

```ts
sqlError = sqlCardsError ?? sqlCardsCbmError ?? sqlChartsError ?? ... ?? sqlTableDetailError
```

Chỉ banner error chung — KHÔNG hiển thị section/query nào lỗi. Mọi banner đều dùng cùng style `border-destructive/30 bg-destructive/10`.

### 3.3 Loading aggregation

```ts
isLoading = loadingSqlCardsRows || loadingSqlCardsRowsCbm || ... || loadingTblDroppedReason
isInitialLoading = isLoading && statusRows.length === 0
```

`isInitialLoading` chỉ true khi LẦN ĐẦU và chưa có data — sau đó refetch dùng `placeholderData: prev` (data cũ vẫn hiển thị).

### 3.4 Pre-aggregation auto-detect

> **[Observed]** — `buildE2ERowsFromSql` ở [widget-flash-daily.tsx:538-586](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L538-L586); `buildSummaryRowsFromSql` ở [:651-696](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L651-L696).

| Function | Pre-aggregated trigger | Fallback aggregate behavior |
|----------|-------------------------|----------------------------|
| `buildE2ERowsFromSql` | First row có key `distinct_so` hoặc `distinctso` | Group raw rows theo `trang_thai_don_do`, sum value, count distinct `so` |
| `buildSummaryRowsFromSql` | First row có key `total_volume` hoặc `done_volume` | Group raw rows theo dimension, sum total, sum done (chỉ khi status = "Đã vận chuyển"), compute pendingVolume + pctDone |

Pre-aggregated mode trust columns: `total_volume`, `done_volume`, `pending_volume`, `pct_done` (chia 100 nếu > 1). Fallback mode hardcode "Đã vận chuyển" làm done state.

---

## 4. Normalization Functions

> **[Observed]** — [widget-flash-daily.tsx:444-802](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L444-L802).

| Hàm | Input | Output | Mục đích |
|-----|-------|--------|---------|
| `sqlGetText(row, keys[])` | raw row + alias list | string (trim) | Lấy text field theo alias (case-insensitive) |
| `sqlGetNumber(row, keys[])` | raw row + alias list | number | Lấy number field, fallback 0 |
| `sqlGetVolume(row)` | raw row | number | Lấy volume từ aliases `value_uom \| valueuom \| value_vol \| valuevol \| volume \| qty \| quantity \| value` |
| `findPlannedTotalVolume(rows)` | raw rows | number \| null | Tìm dòng có status match "kế hoạch xuất"/"plan export"/"total volume" — trả về volume tổng |
| `normalizeStatus(raw)` | string | `StatusName \| null` | Map text → 1 trong 5 status (case + accent insensitive) |
| `normalizeSqlRowsToDetail(rows)` | raw rows | `FlashDetailRow[]` | Convert mọi cell sang string |
| `buildStatusRowsFromSql(rows)` | raw rows | `FlashStatusRow[]` | Group theo `trang_thai_don_do`, sum value |
| `buildE2ERowsFromSql(rows)` | raw rows | `FlashE2EStatusRow[]` | Pre-agg detection (xem §3.4) |
| `buildWarehouseRowsFromSql(rows)` | raw rows | `FlashWarehouseProgressRow[]` | Group theo `whseid × trang_thai_don_do`, sum + distinct SO |
| `buildDimensionRowsFromSql(rows, dimKeys[])` | raw rows + dim alias list | `FlashDimensionProgressRow[]` | Generic — dùng cho customer / area / channel |
| `buildSummaryRowsFromSql(rows, dimKeys[])` | raw rows + dim alias list | `FlashSummaryByDimensionRow[]` | Pre-agg detection cho 4 summary tables |
| `buildDroppedDeliveryRowsFromSql(rows)` | raw rows | `FlashDroppedDeliveryReportRow[]` | Group theo `delivery_to_customer`, compute pct shares |
| `buildDroppedReasonRowsFromSql(rows)` | raw rows | `FlashDroppedReasonReportRow[]` | Group theo `remark_2`, sum dryFresh+POSM |
| `buildCompletionRowsFromSql(rows)` | raw rows | `CompletionRateRow[]` | Direct map từ `tblCompletion` SQL |
| `toDimensionChartRows(rows)` | `FlashDimensionProgressRow[]` | `{name, ...5 status counts}[]` | Pivot rows thành chart-ready format |
| `toSummaryChartRows(rows)` | `FlashSummaryByDimensionRow[]` | `{name, totalVolume, doneVolume, pendingVolume, pctDone (×100)}[]` | Sort alpha + scale pct |
| `topNByTotal(rows, n)` | chart rows + n | top n rows | Sort by total volume DESC, slice top N |
| `inferCustomerDimensionType(name)` | string | `'npp' \| 'customer'` | Substring match `npp/distributor/nhà phân phối` |
| `getPlanAndActualExport(statusMap)` | status counts | `{planExport, actualExport}` | planExport = tổng 5 status; actualExport = sum 3 latest (Đã xuất + Đang vận + Đã vận) |
| `toFlashUom(value)` | string | `FlashStatusFilter['uom']` | Normalize UOM, default `cse` |
| `resolveFlashQueries(config)` | config | `Partial<FlashDailySqlQueries>` | Fan-out legacy `config.sql` → 10 keys nếu cần |
| `hasAnyFlashQuery(queries)` | queries | boolean | True khi >= 1 key có nội dung non-empty |

Tất cả text getters dùng `toLowerCase()` match — case insensitive.

---

## 5. SQL Section Resolve Logic

> **[Observed]** — `resolveSectionKey()` ở [widget-flash-daily.tsx:1143-1150](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1143-L1150); usage ở [:1167-1175](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1167-L1175).

```ts
resolveSectionKey(...candidates: (keyof FlashDailySqlQueries)[]): keyof FlashDailySqlQueries | null
```

Logic: trả về key đầu tiên trong list có `sqlQueries[key]?.trim()` non-empty.

Cấu hình resolve cho 9 query types:

| Query type | Resolve order |
|-----------|---------------|
| Cards | `cardKpiStatus` → `cards` |
| Charts shared | `charts` → `cards` |
| Chart E2E | `chartE2e` → `charts` → `cards` |
| Chart Warehouse | `chartWarehouse` → `charts` |
| Chart Delivery Area | `chartDeliveryArea` → `charts` |
| Chart Customer | `chartCustomer` → `charts` |
| Chart Sales Channel | `chartSalesChannel` → `charts` |
| Table shared | `table` |
| Table Detail | `tableDetail` → `table` |

Detail-tab queries (8 keys): KHÔNG có fallback — chỉ enable khi key cụ thể có nội dung. Nếu rỗng → bảng trống.

---

## 6. Chart Specifications

### 6.1 Pattern chung — 7-series stacked bar

5 chart cùng pattern (`SectionPanel` wrapper + `ResponsiveContainer` + `BarChart`):

| Property | Value |
|----------|-------|
| Component | `BarChart` (Recharts) |
| Cartesian grid | `strokeDasharray='3 3', strokeOpacity=0.2` |
| Tooltip | `RoundedChartTooltip` (custom) với `valueFormatter = Number.toLocaleString('vi-VN')` |
| Cursor | `ROUNDED_CHART_TOOLTIP_CURSOR` (custom) |
| Legend | Custom render — `dimensionLegendItems` 7 entries cố định (Kế hoạch xuất + Thực xuất + 5 status) |
| Label format | 1 decimal place (`minimumFractionDigits: 1`), font size 9px, color `#9CA3AF`. Bỏ qua label khi value = 0. |
| Bar radius | `[0, 4, 4, 0]` (horizontal) / `[4, 4, 0, 0]` (vertical) |
| Series | 7 bars per group: `planExport` (`#0EA5E9`), `actualExport` (`#16A34A`), 5 status (theo `STATUS_COLORS`) |
| maxBarSize | 28-32px |
| barCategoryGap | `'10%'` (horizontal) hoặc `'25%'` (vertical Wh) |
| barGap | 2px |

### 6.2 Chart by Delivery Area (Region) — đặc thù

| Property | Value |
|----------|-------|
| Layout | `vertical` (horizontal bars — Region trên Y-axis) |
| Height | `Math.min(1400, Math.max(480, rows.length * 200))`px — dynamic theo số dimension |
| YAxis width | 180px |
| Margin | `{ top: 4, right: 60, left: 0, bottom: 0 }` |
| Sort | Alpha asc by name (qua `toDimensionChartRows`) |
| Export filename | `flash-daily-by-delivery-area` |
| i18n keys | `chartByDeliveryArea`, `chartByDeliveryAreaValueSubtitle`, `progressByArea` (hint) |

### 6.3 Chart by Warehouse — đặc thù

| Property | Value |
|----------|-------|
| Layout | Vertical (bars vertical — WHSEID trên X-axis) |
| Height | 384px (h-96 — cố định, KHÔNG dynamic) |
| barCategoryGap | `'25%'` (rộng hơn các chart khác) |
| maxBarSize | 28px |
| Sort | Alpha asc by whseid |
| Export filename | `flash-daily-by-warehouse` |
| i18n keys | `chartByWh`, `chartByWhValueSubtitle`, `progressByWh` (hint) |

### 6.4 Chart E2E Distribution — đặc thù

| Property | Value |
|----------|-------|
| Layout | Vertical (X-axis = 7 status entries) |
| Height | 288px (h-72) |
| Bars | 1 bar per X entry — KHÔNG stacked (mỗi entry có color riêng từ `e2eDoRows[i].color`) |
| Bar radius | `[6, 6, 0, 0]` |
| Legend | Custom render 7 entries từ `e2eDoRows` (text size 15px — khác các chart khác) |
| Margin | `{ top: 20, right: 12, left: 0, bottom: 0 }` |
| Export filename | `flash-daily-e2e-value` |

### 6.5 Chart by Customer — đặc thù

| Property | Value |
|----------|-------|
| Layout | `vertical` (horizontal bars) |
| Height | `Math.min(1400, Math.max(480, rows.length * 200))`px |
| Customer dropdown | `customerDimensionFilter` — Tất cả (mặc định) / NPP / Customer. Filter client-side qua `inferCustomerDimensionType`. |
| Top N limit | `topNByTotal(filteredRows, 10)` — chỉ giữ top 10 theo tổng volume |
| Sort within top 10 | Theo total volume DESC qua `topNByTotal`; sau đó `toDimensionChartRows` sort alpha asc bằng `localeCompare` → tự override topN order? — **xem note** |
| Export filename | `flash-daily-by-customer` |
| i18n keys | `chartByCustomer`, `chartByCustomerValueSubtitle`, `progressByCustomer` (hint) |

> **Note**: `toDimensionChartRows` sort alpha asc xảy ra TRƯỚC `topNByTotal` — vì pipeline là `customerRows → toDimensionChartRows (alpha sort) → topNByTotal (sort by total, slice 10)`. Kết quả top 10 sẽ ordered by total volume DESC (vì sort cuối).

### 6.6 Chart by Sales Channel — đặc thù

Cùng pattern chart by Delivery Area. Export filename: `flash-daily-by-sales-channel`. i18n keys: `chartBySalesChannel`, `chartBySalesChannelValueSubtitle`, `progressByChannel` (hint).

### 6.7 Chart Drop Trend 14 ngày (`chartDropTrend`) — section MỚI v1.1.0

> Section CHƯA TỒN TẠI trong code v1.0.0 — cần build mới. Audit A3 (oq-resolution.md §0c finding 2) đã confirm BUILDABLE NOW.

**Frontend interface change**:
```ts
interface FlashDailySqlQueries {
  // ... existing 15 keys
  chartDropTrend: string  // ⭐ NEW — required for L4
}
```

Thêm vào `FLASH_DAILY_SECTIONS` ở [widget-flash-daily-settings-dialog.tsx:50-238](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily-settings-dialog.tsx#L50-L238) với label "L4 Trend tỷ lệ rớt 14 ngày" và requiredColumns: `date`, `total_plan`, `total_failed`, `drop_rate`.

| Property | Value |
|----------|-------|
| Component | `LineChart` (Recharts) — 1 line series cho `drop_rate`, 2 reference lines (target + rolling 30d) |
| X-axis | `date` (14 ngày, ordered ASC) — format `dd/MM` |
| Y-axis | `drop_rate` (%) — `[0, max(15, ceil(maxDrop))]` domain |
| Reference line 1 | `y=5` solid red, label "Target ≤5%" |
| Reference line 2 | `drop_rate_30d_avg` dashed grey, dynamic per-day value |
| Tooltip | `RoundedChartTooltip` — show `total_plan` + `total_failed` + `drop_rate` + `drop_rate_30d_avg` |
| Height | 320px (fixed) |
| Date type guard | UI **disable** `ETD gửi thầu` + `ETA gửi thầu` options khi user xem L4 (H2 chốt) — fallback về `GI date` nếu user đang chọn ETD/ETA |
| Filter parity | Áp cùng filter bar với L1-L3 (G5 chốt) — dùng cùng 11 placeholder ở §6.3 PRD |
| Export filename | `flash-daily-drop-trend-14d` |
| i18n title | `chartDropTrend14d` (new key) |

**SQL draft** (cho `/da-ch` finalize, parity với existing T7 — KHÔNG có brand filter; canonical theo `projects/mondelez/02-data/data-sources/sql-registry.md` "Flash Report" section):

```sql
-- L4 Drop Trend 14 ngày — section key chartDropTrend
-- Backfill 44 ngày trong CTE để 14 visible rows có đủ 30 priors cho rolling 30d avg
-- FAIL = status='Cancel' (H1 chốt, canonical sql-registry.md)
-- Date type allowed: 'Ngày GI' / 'Actual Ship Date' / 'ATA đơn' (H2 — ETD/ETA disabled trên UX)

WITH flash_base AS (
  SELECT
    toDate(CASE
      WHEN {{date_type}} = 'Ngày GI'          THEN delivery_date_1
      WHEN {{date_type}} = 'Actual Ship Date' THEN actual_ship_date
      WHEN {{date_type}} = 'ATA đơn'           THEN ata_den
      ELSE delivery_date_1
    END) AS d,
    toFloat64(coalesce(original_cse, 0))
      + toFloat64(coalesce(original_qty, 0)) AS plan_v
  FROM analytics_workspace.mv_flash_report
  WHERE toDate(CASE
          WHEN {{date_type}} = 'Ngày GI'          THEN delivery_date_1
          WHEN {{date_type}} = 'Actual Ship Date' THEN actual_ship_date
          WHEN {{date_type}} = 'ATA đơn'           THEN ata_den
          ELSE delivery_date_1
        END) BETWEEN toDate({{to_date}}) - 43 AND toDate({{to_date}})
    AND ({{whseid}}         = '' OR whseid          IN splitByChar(',', {{whseid}}))
    AND ({{group_name}}     = '' OR group_name      IN splitByChar(',', {{group_name}}))
    AND ({{group_of_cargo}} = '' OR coalesce(group_of_cago, 'Unclassified') IN splitByChar(',', {{group_of_cargo}}))
    AND ({{region}}         = '' OR khu_vuc_doi_xe  IN splitByChar(',', {{region}}))
),
drop_base AS (
  SELECT
    toDate(CASE
      WHEN {{date_type}} = 'Ngày GI'          THEN delivery_date_1
      WHEN {{date_type}} = 'Actual Ship Date' THEN actual_ship_date
      WHEN {{date_type}} = 'ATA đơn'           THEN ata_den
      ELSE delivery_date_1
    END) AS d,
    toFloat64(coalesce(original_cse, 0))
      + toFloat64(coalesce(original_qty, 0)) AS plan_v,
    if(status = 'Cancel',
       toFloat64(coalesce(original_cse, 0)) + toFloat64(coalesce(original_qty, 0)),
       0) AS fail_v
  FROM analytics_workspace.mv_dropped_report
  WHERE toDate(CASE
          WHEN {{date_type}} = 'Ngày GI'          THEN delivery_date_1
          WHEN {{date_type}} = 'Actual Ship Date' THEN actual_ship_date
          WHEN {{date_type}} = 'ATA đơn'           THEN ata_den
          ELSE delivery_date_1
        END) BETWEEN toDate({{to_date}}) - 43 AND toDate({{to_date}})
    AND ({{whseid}}         = '' OR whseid          IN splitByChar(',', {{whseid}}))
    AND ({{group_name}}     = '' OR group_name      IN splitByChar(',', {{group_name}}))
    AND ({{group_of_cargo}} = '' OR coalesce(group_of_cago, 'Unclassified') IN splitByChar(',', {{group_of_cargo}}))
    AND ({{region}}         = '' OR khu_vuc_doi_xe  IN splitByChar(',', {{region}}))
),
per_day AS (
  SELECT d, SUM(plan_v) AS total_plan, 0          AS total_failed FROM flash_base GROUP BY d
  UNION ALL
  SELECT d, SUM(plan_v) AS total_plan, SUM(fail_v) AS total_failed FROM drop_base  GROUP BY d
),
daily AS (
  SELECT
    d AS date,
    SUM(total_plan)   AS day_plan,
    SUM(total_failed) AS day_failed,
    if(SUM(total_plan) = 0, 0,
       round(100.0 * SUM(total_failed) / SUM(total_plan), 2)) AS drop_rate
  FROM per_day
  GROUP BY d
)
SELECT
  date,
  day_plan   AS total_plan,
  day_failed AS total_failed,
  drop_rate,
  avg(drop_rate) OVER (
    ORDER BY date
    ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
  ) AS drop_rate_30d_avg
FROM daily
ORDER BY date DESC
LIMIT 14;
```

**Lưu ý**:
- CTE backfill 44 ngày (`to_date - 43`) — không phải 14 — để rolling 30d có đủ 30 priors cho 14 visible rows.
- Filter parity với existing T7 (`tblDropped` SQL) — KHÔNG có brand filter trong CTE này (T7 cũng không có).
- `splitByChar(',', ...)` cho multi-select CSV values từ `buildFilterOverrides()` (xem §2.2).
- `result` trả về 14 rows DESC; frontend sort ASC trước render để X-axis trái → phải = cũ → mới.

### 6.8 Chart L5 — Hoàn thành theo dimension (4 chart) — section keys MỚI v1.1.0

> Section keys `chartWarehouse` / `chartDeliveryArea` / `chartCustomer` / `chartSalesChannel` được **REPURPOSE** v1.1.0: từ "stacked-status chart cũ" (đã xoá Step 8) → "L5 summary panel pct_done per dim". Mỗi chart 1 SQL riêng — KHÔNG share với `tblSummaryWh/Customer/Area/Channel` (T3-T6 tables dùng key riêng theo convention 1-chart-per-SQL).

**Frontend interface (giữ nguyên 4 keys, đổi semantic)**:
```ts
interface FlashDailySqlQueries {
  // ... existing keys
  chartWarehouse:      string  // ⭐ REPURPOSED v1.1.0 — L5 panel Kho (summary shape)
  chartDeliveryArea:   string  // ⭐ REPURPOSED v1.1.0 — L5 panel Khu vực
  chartCustomer:       string  // ⭐ REPURPOSED v1.1.0 — L5 panel Customer (NPP=Customer per Mondelez D3)
  chartSalesChannel:   string  // ⭐ REPURPOSED v1.1.0 — L5 panel Kênh bán
}
```

| Property | Value |
|----------|-------|
| Component | `WidgetFlashDailyDimensionPanels` ([widget-flash-daily-dimension-panels.tsx](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily-dimension-panels.tsx)) |
| Layout | `grid grid-cols-1 lg:grid-cols-2` — 4 panels visible đồng thời (không phải Tabs) |
| Chart per panel | Horizontal bar `pct_done` per dim, RAG color (computeRagBand), sort ASC (worst-first) |
| Reference line | `x=95` (target) — solid grey với label "Target 95%" |
| Bar label phải | 2 dòng: `{pct_done}%` (top, bold) + `{done_volume} / {total_volume} {uom}` (dưới, muted) |
| Highlight | Row được wire từ L2 click → outline + full opacity |
| Height | `clamp(240, rows*36+64, 520)` per panel |
| Filter parity | L5 áp cùng filter bar như L1-L3 (G5 chốt) — khác L4 (filter-independent per Step 9 override) |
| Required output cols | `{dim_column}`, `total_volume`, `done_volume` · Optional: `pending_volume`, `pct_done` |
| Builder | `buildSummaryRowsFromSql` auto-detect pre-aggregated rows khi `total_volume` hoặc `done_volume` present (xem §3.4) |

**SQL drafts** (cho `/da-ch` finalize — canonical pattern theo `projects/mondelez/02-data/data-sources/sql-registry.md` "Báo cáo tổng hợp theo X" Flash Report section; 4 SQL khác nhau chỉ ở **dim_column** trong base CTE + final GROUP BY):

#### 6.8.1 `chartWarehouse` — L5 Hoàn thành theo Kho

```sql
-- L5 Hoàn thành theo Kho — section key chartWarehouse
-- Output: { whseid, total_volume, done_volume, pending_volume, pct_done } per kho
-- "Done" = trang_thai_don_do = 'Đã vận chuyển' (final E2E status)
-- Filter parity: cùng filter bar với L1-L3 (G5 chốt)
-- ⚠ MUST filter status IN 5 canonical để PARITY denominator với cardKpiStatus L1 Hero
--   (xem [[feedback-l5-sql-canonical-status-filter]] — bug 2026-05-18: bỏ filter này
--    → SUM(total_volume) L5 lệch L1 plan, vd L1 18.350 PALLET vs L5 sum 33.721 PALLET)

WITH base AS (
  SELECT
    t.whseid AS dim_value,
    t.trang_thai_don_do,
    CASE
      WHEN {{uom}} = 'cse'    THEN toFloat64(coalesce(t.original_cse, 0))
      WHEN {{uom}} = 'ton'    THEN toFloat64(coalesce(t.original_kg,  0)) / 1000.0
      WHEN {{uom}} = 'cbm'    THEN toFloat64(coalesce(t.original_cbm, 0))
      WHEN {{uom}} = 'pallet' THEN toFloat64(coalesce(t.original_pl,  0))
      WHEN {{uom}} = 'do'     THEN 1.0
      ELSE                         toFloat64(coalesce(t.original_cse, 0))
    END AS volume_value
  FROM analytics_workspace.mv_flash_report t
  WHERE toDate(CASE
          WHEN {{date_type}} = 'GI date'          THEN t.delivery_date_1
          WHEN {{date_type}} = 'Actual Ship date' THEN t.actual_ship_date
          WHEN {{date_type}} = 'ETD gửi thầu'      THEN t.etd_chuyen_gui_thau
          WHEN {{date_type}} = 'ATA đơn'           THEN t.ata_den
          WHEN {{date_type}} = 'ETA gửi thầu'      THEN t.eta_giao_hang_cho_npp
          ELSE t.delivery_date_1
        END) BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
                 AND toDate(coalesce({{to_date}},   '2999-12-31'))
    -- Canonical 5 status filter — PARITY với cardKpiStatus L1 Hero (bắt buộc)
    AND t.trang_thai_don_do IN (
      'Chưa xuất kho', 'Đang xuất kho', 'Đã xuất kho',
      'Đang vận chuyển', 'Đã vận chuyển'
    )
    AND ({{whseid}}         = '' OR t.whseid          IN splitByChar(',', {{whseid}}))
    AND ({{group_name}}     = '' OR t.group_name      IN splitByChar(',', {{group_name}}))
    AND ({{brand}}          = '' OR coalesce(t.brand, 'Unclassified') IN splitByChar(',', {{brand}}))
    AND ({{group_of_cargo}} = '' OR coalesce(t.group_of_cago, 'Unclassified') IN splitByChar(',', {{group_of_cargo}}))
    AND ({{region}}         = '' OR t.khu_vuc_doi_xe  IN splitByChar(',', {{region}}))
)
SELECT
  coalesce(dim_value, 'Unclassified') AS whseid,
  SUM(volume_value) AS total_volume,
  SUM(if(trang_thai_don_do = 'Đã vận chuyển', volume_value, 0)) AS done_volume,
  SUM(if(trang_thai_don_do <> 'Đã vận chuyển' OR trang_thai_don_do IS NULL,
         volume_value, 0)) AS pending_volume,
  if(SUM(volume_value) = 0, 0,
     SUM(if(trang_thai_don_do = 'Đã vận chuyển', volume_value, 0))
       / SUM(volume_value)) AS pct_done
FROM base
GROUP BY dim_value
ORDER BY total_volume DESC;
```

#### 6.8.2 `chartDeliveryArea` — L5 Hoàn thành theo Khu vực

> Delta so với §6.8.1: thay `t.whseid AS dim_value` → `t.khu_vuc_doi_xe AS dim_value`, final SELECT alias đổi từ `whseid` → `khu_vuc_doi_xe`. Mọi else giữ nguyên (CTE, status filter, formula pct_done, ORDER BY total_volume DESC).

#### 6.8.3 `chartCustomer` — L5 Hoàn thành theo Khách hàng

> Delta: thay `t.whseid AS dim_value` → `t.customer_name AS dim_value`, final alias đổi sang `customer_name`. Mondelez NPP=Customer (D3) — KHÔNG cần dropdown filter NPP vs Customer. FE tự cap top 10 by volume DESC (xem `WidgetFlashDailyDimensionPanels.CUSTOMER_TOP_N`).

#### 6.8.4 `chartSalesChannel` — L5 Hoàn thành theo Kênh bán

> Delta: thay `t.whseid AS dim_value` → `t.group_name AS dim_value`, final alias đổi sang `group_name`.

**Lưu ý chung 4 SQL**:
- ⚠ **BẮT BUỘC** filter `trang_thai_don_do IN (5 canonical statuses)` để PARITY denominator với cardKpiStatus. Bỏ filter này → đếm cả Cancel/dropped/non-canonical-status vào total → SUM(total_volume) của L5 sẽ lệch L1 plan (bug 2026-05-18 thực tế gặp). Xem memory [[feedback-l5-sql-canonical-status-filter]].
- Same filter set như L1-L3 baseline — `{{date_type}}`, `{{from_date}}`, `{{to_date}}`, `{{whseid}}`, `{{group_name}}`, `{{brand}}`, `{{group_of_cargo}}`, `{{region}}`, `{{uom}}`.
- `splitByChar(',', {{var}})` pattern cho CSV multi-select; placeholder rỗng `''` = không lọc (per `buildFilterOverrides` ở §2.2).
- `Đã vận chuyển` literal — đúng STATUS_ORDER mới sau Step 6 (đã fix drift #11).
- Default `ORDER BY total_volume DESC` để FE preview khớp với rendering (L5 panel sort biggest-first per PM directive 2026-05-18).
- T3-T6 tables dùng `tblSummaryWh`/`tblSummaryCustomer`/`tblSummaryArea`/`tblSummaryChannel` riêng (cùng shape — admin có thể copy SQL từ §6.8.x sang nếu muốn). Convention 1-chart-1-SQL.

---

## 7. KPI Card (StatusCard) Specifications

> **[Observed]** — `StatusCard` component ở [widget-flash-daily.tsx:860-911](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L860-L911).

| Card | Icon (lucide) | Color | Label hex (border + icon) | Value format | Description i18n |
|------|--------------|-------|--------------------------|-------------|------------------|
| Tổng Volume Kế hoạch | `Box` | `#10B981` (emerald) | accent border 0.5px | `formatValue(totalVolume, uom)` | `totalVolumeDesc` |
| Chưa xuất kho | `Layers` | `#858585` (grey) | accent border | `formatValue(statusValues['Chưa xuất kho'], uom)` | `groupNotShipped` |
| Đang xuất kho | `TrendingUp` | `#E18719` (amber) | accent border | `formatValue(statusValues['Đang xuất kho'], uom)` | `groupProcessing` |
| Đã xuất kho | `Truck` | `#4F2170` (violet) | accent border | `formatValue(statusValues['Đã xuất kho'], uom)` | `groupDone` |
| Đang vận chuyển | `Truck` | `#2D6EAA` (blue) | accent border | `formatValue(statusValues['Đang vận chuyển'], uom)` | `groupInTransit` |
| Đã vận chuyển | `Truck` | `#287819` (green) | accent border | `formatValue(statusValues['Đã vận chuyển'], uom)` | `groupDelivered` |

**Styling chung**:
- Container: `relative overflow-hidden rounded-xl border p-3 shadow-lg backdrop-blur-md`
- Background: linear-gradient 135deg `{color}26 → {color}0D` (15% → 5% opacity)
- Top border: 0.5px stripe màu accent
- Icon container: 32×32px (h-8 w-8) bg `{color}26`, icon 16×16px (h-4 w-4) color accent
- Label: `text-[10px] font-semibold` muted-foreground
- Value: `text-lg font-bold tabular-nums` color accent
- Description: `text-[10px]` muted-foreground
- Hint tooltip: ExplainHint button (h-5 w-5 với icon `Info` 12×12px) ở `absolute top-2 right-2` — nội dung từ `FLASH_DAILY_HINTS`

**Grid layout**: `grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-3` — 1 cột mobile, 2 cột sm, 3 cột xl.

---

## 8. Bảng cột — Chi tiết Flash (T9 / DSHFLADTG09)

> **[Observed]** — `FLASH_DETAIL_COLUMNS` ở [widget-flash-daily.columns.tsx:138-175](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.columns.tsx#L138-L175); UOM-aware rendering ở `getUomMappedDetailCellValue()` [:104-134](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.columns.tsx#L104-L134).

32 cột render theo thứ tự cố định, mọi cột đều `dataType: 'string'`, sortable, filter text, `whitespace-nowrap`:

| # | Label | Source keys (alias chấp nhận) | UOM-aware |
|---|-------|------------------------------|-----------|
| 1 | SO | `so` | No |
| 2 | Order type | `order_type` | No |
| 3 | STATUS | `status` | No |
| 4 | Trạng thái đơn hàng | `trang_thai_don_hang` | No |
| 5 | Trạng thái đơn DO | `trang_thai_don_do` | No |
| 6 | Item Code | `item_code` | No |
| 7 | Tên hàng | `ten_hang, sku_name, item_name` | No |
| 8 | Group of Cago | `group_of_cago` | No |
| 9 | Group | `group_name` | No |
| 10 | Customer Code | `customer_code` | No |
| 11 | Customer Name | `customer_name` | No |
| 12 | Khu vực đội xe | `khu_vuc_doi_xe` | No |
| 13 | Tên ngắn nhà vận tải | `ten_ngan_nha_van_tai` | No |
| 14 | Loại xe vận hành | `loai_xe_van_hanh` | No |
| 15 | Mã điểm nhận | `ma_doi_tac_nhan, ma_diem_nhan` | No |
| 16 | Tên điểm nhận | `ten_doi_tac_nhan, ten_diem_nhan` | No |
| 17 | **ORIGINAL** | `original, original_cse` (fallback) | **Yes** |
| 18 | **SHIPPED** | `shipped, shipped_cse` (fallback) | **Yes** |
| 19 | **Sản lượng giao** | `san_luong_giao, sum_san_luong_giao_cse` (fallback) | **Yes** |
| 20 | Thời gian gửi thầu | `thoi_gian_gui_thau` | No |
| 21 | Delievery Date 1 | `delivery_date_1` | No |
| 22 | ETD chuyến gửi thầu | `etd_chuyen_gui_thau` | No |
| 23 | ATD đến | `atd_den, ata_den` | No |
| 24 | ATD rời | `atd_roi, ata_roi` | No |
| 25 | Actual Ship Date | `actual_ship_date` | No |
| 26 | TG bắt buộc rời kho | `tg_bat_buoc_roi_kho` | No |
| 27 | Thời gian đi | `thoi_gian_di` | No |
| 28 | ETA (Giao hàng cho NPP) | `eta_giao_hang_cho_npp, eta` | No |
| 29 | ATA đến | `ata_den` | No |
| 30 | ATA rời | `ata_roi` | No |
| 31 | Số chuyến | `so_chuyen` | No |
| 32 | Số xe | `so_xe` | No |
| 33 | Mã nhà xe | `ma_nha_xe` | No |

**Lưu ý**: Header table không có "Delievery Date 1" typo fix (Sic — `Delievery` thay vì `Delivery` ở label trong code).

### 8.1 UOM-aware rendering cho ORIGINAL / SHIPPED / Sản lượng giao

| UOM | Field used (prefix → field) | Format |
|-----|-----------------------------|--------|
| `cse` | `{prefix}_cse` | Raw value (string) |
| `ton` | `{prefix}_kg` → `formatTonWithKg(kg)` | `"{kg/1000} Tấn ({kg} Kg)"` |
| `cbm` | `{prefix}_cbm` | Raw value |
| `pallet` | `{prefix}_pl` | Raw value |
| `do` | — | Trả `"-"` (DO không có volume khái niệm) |

Prefix: `original` / `shipped` / `san_luong_giao`. Hidden cells trả `'-'`.

---

## 9. Bảng cột — Completion (T1 / DSHFLADTG01)

> **[Observed]** — `createCompletionColumns()` ở [widget-flash-daily.columns.tsx:179-248](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.columns.tsx#L179-L248).

| Key | Label i18n | Type | Filter | Style |
|-----|-----------|------|--------|-------|
| `whName` | `colWhName` | string | multiselect | `font-semibold` |
| `channel` | `colChannel` | string | multiselect | — |
| `area` | `colArea` | string | multiselect | — |
| `mucTieu` | `colTarget` | number | — | `tabular-nums text-right` |
| `hoanThanh` | `colDone` | number | — | `text-emerald-500` |
| `conLai` | `colRemaining` | number | — | `text-amber-500` |
| `pctHoanThanh` | `colPctDone` | percent | — | `text-indigo-400`, format `X.XX%` |

Synthetic fallback (xem §10): `COMPLETION_WH_NAMES × COMPLETION_CHANNELS × COMPLETION_AREAS = 6 × 3 × 3 = 54 dòng` được sinh khi `tblCompletion` rỗng.

---

## 10. Bảng cột — E2E Status Detail (T2 / DSHFLADTG02)

> **[Observed]** — `createE2eStatusDetailColumns()` ở [widget-flash-daily.columns.tsx:250-278](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.columns.tsx#L250-L278).

| Key | Label i18n | Type | Render |
|-----|-----------|------|--------|
| `status` | `colStatus` | string | `<span style="color: row.color">{status}</span>` |
| `valueUom` | `colVolume` | number | `formatValue(value, uom)` |
| `uomLabel` | `colUom` | string | `formatUomLabel(uom)` — `'DO-line'` nếu `do`, else `uom.toUpperCase()` |

Total rows = 7 (Kế hoạch + Thực xuất + 5 status), data từ `e2eStatusDetailRows` (xem [widget-flash-daily.tsx:2051-2061](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L2051-L2061)).

---

## 11. Bảng cột — Summary (T3/T4/T5/T6 — chung schema)

> **[Observed]** — `createFlashSummaryColumns()` ở [widget-flash-daily.columns.tsx:280-326](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.columns.tsx#L280-L326).

| Key | Label i18n | Type | Filter | Style |
|-----|-----------|------|--------|-------|
| `name` | `colDimension` | string | text | `font-semibold` |
| `totalVolume` | `colTotal` | number | — | `tabular-nums text-right` |
| `doneVolume` | `colDone` | number | — | `text-emerald-500` |
| `pendingVolume` | `colPending` | number | — | `text-amber-500` |
| `pctDone` | `colPctDone` | percent | — | `text-indigo-400`, format `X.XX%` |

Used by `whSummaryRows`, `customerSummaryRows`, `deliveryAreaSummaryRows`, `salesChannelSummaryRows`.

---

## 12. Bảng cột — Dropped Delivery (T7 / DSHFLADTG07)

> **[Observed]** — `createDroppedDeliveryColumns()` ở [widget-flash-daily.columns.tsx:328-384](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.columns.tsx#L328-L384).

| Key | Label i18n | Type | Render |
|-----|-----------|------|--------|
| `rowLabel` | `deliveryToCustomer` | string | `font-semibold`, multiselect filter |
| `dryFreshCse` | `dryFresh` (DRY & FRESH CSE) | number | Format `vi-VN` 2 decimals, `'-'` nếu 0 |
| `posmPc` | `posm` (POSM PC) | number | Format `vi-VN` 2 decimals, `'-'` nếu 0 |
| `pctDryFreshCse` | `pctDryFresh` | percent | `X%` (0 decimals) |
| `pctPosmPc` | `pctPosm` | percent | `X%` (0 decimals) |

Total rows luôn = 4 (Tổng kế hoạch, Xử lý thành công, Đang xử lý, Xử lý không thành công) — `droppedDeliveryMetricRows` ở [widget-flash-daily.tsx:1921-2049](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1921-L2049).

---

## 13. Bảng cột — Dropped Reason (T8 / DSHFLADTG08)

> **[Observed]** — `createDroppedReasonColumns()` ở [widget-flash-daily.columns.tsx:386-420](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.columns.tsx#L386-L420).

| Key | Label i18n | Type | Render |
|-----|-----------|------|--------|
| `remark2` | `colRemark` | string | `font-semibold`, multiselect filter |
| `freshDryCse` | `colFreshDry` (FRESH/DRY CSE) | number | Format `vi-VN` 2 decimals |
| `posmPc` | `colPosm` (POSM PC) | number | Format `vi-VN` 2 decimals |

Group theo `remark_2`/`remark2`/`reason` field, sum `dry_fresh_cse + posm_pc`.

---

## 14. Synthetic Completion Fallback (T1)

> **[Observed]** — `completionRows` memo ở [widget-flash-daily.tsx:1809-1919](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1809-L1919).

Khi `tblCompletion` SQL rỗng → frontend tự sinh 54 dòng synthetic:

```
COMPLETION_WH_NAMES (6):
  Kho ngoài - NKD, Kho BEE_BKD, Kho trong - NKD, Kho trong - BKD,
  Kho ngoài 2 - NKD, KHO ICD_12

COMPLETION_CHANNELS (3): GT, MT, KA
COMPLETION_AREAS (3): Mekong1, Mekong2, South East

→ 6 × 3 × 3 = 54 rows
```

Cách tính cho mỗi dòng (wh × channel × area):

1. Normalize tên dimension (NFD + remove accents + lowercase)
2. Đọc share của dimension trong 3 summary maps (`whSummaryRows`, `salesChannelSummaryRows`, `deliveryAreaSummaryRows`)
3. Compute synthetic target: `totalVolume × whShare × channelShare × areaShare`
4. Compute synthetic %: trung bình 3 pct theo dimension, clamp [0, 1]
5. `done = target × pct`, `remaining = max(0, target - done)`
6. `pctHoanThanh = (done / target) × 100`

> **Warning**: Đây là **synthetic data** — không phản ánh data thực tế. Khi rollout production cho Mondelez, **PHẢI** cấu hình `tblCompletion` SQL — nếu không số liệu sẽ misleading.

---

## 15. Widget Config Schema

```ts
interface FlashDailySqlConfig extends SqlWidgetConfigBase {
  dataSourceId?:      string
  sourceObjectType?:  'table' | 'view'
  sourceObjectName?:  string
  sql?:               string                    // legacy single SQL — fan out tới 10 keys
  queries?:           Partial<FlashDailySqlQueries>
  filterConfig?:      SqlViewFilterConfig
  flashApiUrl?:       string                    // legacy REST endpoint (no longer used)
}

interface FlashDailySqlQueries {
  cards:               string  // @deprecated legacy fallback
  charts:              string  // @deprecated legacy fallback
  cardKpiStatus:       string
  chartE2e:            string
  chartWarehouse:      string
  chartDeliveryArea:   string
  chartCustomer:       string
  chartSalesChannel:   string
  chartDropTrend:      string
  exceptionWarehouse:  string  // v1.3.0 — L2 hotspot panel Warehouse
  exceptionDrop:       string  // v1.3.0 — L2 hotspot panel Drop + Reason
  exceptionRegion:     string  // v1.3.0 — L2 hotspot panel Region
  table:               string  // @deprecated legacy fallback
  tblCompletion:       string
  tblE2eDetail:        string
  tblSummaryWh:        string
  tblSummaryCustomer:  string
  tblSummaryArea:      string
  tblSummaryChannel:   string
  tblDropped:          string
  tblDroppedReason:    string
  tableDetail:         string
}
```

**[Observed]** — [widget-flash-daily-settings-dialog.tsx:11-37](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily-settings-dialog.tsx#L11-L37). Total 18 keys (3 deprecated + 15 hiện hành).

Config được serialized thành JSON string và lưu vào `widget.config` column qua `useUpdateV2Widget`.

---

## 16. Loading & Error States

| State | UI |
|-------|----|
| `isInitialLoading` (true khi `isLoading && statusRows.length === 0`) | Skeleton: 1 × h-20 (filter bar) + 6 × h-20 grid (cards) + 1 × h-64 (chart placeholder) |
| `sqlError && !apiData` | Error banner `border-destructive/30 bg-destructive/10` với icon AlertTriangle + message |
| `isFetching && apiData` | `placeholderData: prev` — hiển thị data cũ, SqlFilterPanel có loading indicator |
| `!hasSqlConfig` | KHÔNG mock data. Widget render placeholder rỗng + skeleton mãi mãi (nếu widgetReady false). |

**Khác biệt với OTIF**: Flash Daily **KHÔNG fallback mock 120 dòng** khi chưa có config — chỉ trống. Đây là drift cần lưu ý.

---

## 17. Edit Mode — Toolbar Actions

> **[Observed]** — useEffect setToolbarActions ở [widget-flash-daily.tsx:2066-2088](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L2066-L2088).

Khi `editMode = true` và có `dashboardId` + `widgetId`, toolbar Dashboard hiển thị 2 nút:

1. **Setting Chart** — variant outline, icon `Settings`, label `"Setting Chart"`. Click mở `WidgetFlashDailySettingsDialog` với 15 section tabs (Cards 1 + Charts 5 + Tables 9). Mỗi tab có Monaco editor + Test Query + required column validation.

2. **Setting Filter** — variant ghost với amber chip styling (`bg-amber-500/10 text-amber-600 ring-amber-500/30`), icon `SlidersHorizontal`, label `"Setting Filter"`. Click set `sqlFilterSettingsOpen = true` → `SqlFilterPanel` render dialog config.

Cleanup: khi unmount → `setToolbarActions(null)` qua return của useEffect.

---

## 18. FormConfig Codes (File-Based Build/Deploy)

9 grid trong `FlashDailyDetailPanel` dùng `gridKey` namespace `DSHFLA`:

| Code | Grid | Page size | Caption i18n |
|------|------|-----------|--------------|
| `DSHFLADTG01` | Completion | 20 | `completionReportTitle` |
| `DSHFLADTG02` | E2E Status Detail | 10 | `detailReportTitle` |
| `DSHFLADTG03` | Summary by Warehouse | 10 | `summaryByWh` |
| `DSHFLADTG04` | Summary by Customer | 10 | `summaryByCustomer` |
| `DSHFLADTG05` | Summary by Area | 10 | `summaryByArea` |
| `DSHFLADTG06` | Summary by Sales Channel | 10 | `summaryBySalesChannel` |
| `DSHFLADTG07` | Dropped Delivery | 20 | `dropReportTitle` |
| `DSHFLADTG08` | Dropped Reason | 10 | `dropReasonTitle` |
| `DSHFLADTG09` | Flash Detail | 20 | `flashDetailTitle` |

Naming pattern: `DSH` (Dashboard) + `FLA` (Flash) + `DTG` (Detail Grid) + `01..09` (sequence).

**System type**: **File-based**, KHÔNG DB-seeded. Loaded bởi `FileBasedFormConfigProvider.cs` từ `backend/src/FormConfigs/{code}.json`, cache qua `IMemoryCache` TTL 2h. Deployed via `Smartlog.Api.csproj <Content Include="..\FormConfigs\**\*.json">` lines 29-32. **Global scope** — 1 file phục vụ mọi tenant (không per-tenant).

**Build/Deploy verification**: 9 JSON files PHẢI có trong Api image; verify bằng **runtime smoke** `GET /api/forms/{code}` cho cả 9 codes với Mondelez tenant context. **KHÔNG có DB query để audit** — không có table `form_config`.

**Audit findings 2026-05-16** (oq-resolution.md §0c A2):
- ✅ All 9 JSON files present at `backend/src/FormConfigs/DSHFLADTG01..09.json`
- ✅ All parse, `category="GRID"`, code matches filename
- ✅ Column counts: 01=7, 02=3, 03=5, 04=5, 05=5, 06=5, 07=5, 08=3, 09=33
- ⚠ Pending: runtime smoke `GET /api/forms/{code}` × 9 với Mondelez tenant (verify Api image deploy đủ)

**Block v1.1.0 rollout if**: runtime smoke fails for any of 9 codes → CI/CD packaging bug.

---

## 19. Performance & Concurrency Notes

| Concern | Observation |
|---------|-------------|
| Total parallel requests | 17 useQuery enabled simultaneously khi widget mount với đầy đủ config |
| pageSize per request | 5000 dòng (~10× OTIF 500) — vì FE cần raw rows để aggregate |
| Total potential rows fetched | 17 × 5000 = 85,000 rows max (chưa nén) |
| Client-side aggregation cost | Build* functions chạy O(n) over rows; useMemo guard re-aggregate khi data change |
| customerDimensionFilter re-render | KHÔNG refetch — chỉ filter client `customerProgressBaseRows` → cheap |
| UOM change cost | TRIGGER refetch toàn bộ 17 queries — vì filterOverrides có `uom` |
| Cache hit pattern | Same `applied` filter → useQuery cache hit (5 min staleTime) |
| Memory usage estimate | ~85k rows × ~30 fields × ~50 bytes = ~130 MB raw (in-memory) |

**Tham chiếu OQ-09 trong PRD**: Có cần consolidate 17 queries thành 5-7 queries không? — pending decision.

---

## 20. Drift / Inconsistencies (cần fix khi refresh)

| # | Drift | Severity | Note |
|---|-------|----------|------|
| 1 | Label cột 21 trong `FLASH_DETAIL_COLUMNS` ghi `"Delievery Date 1"` — typo (đúng là "Delivery") | Low | Cosmetic — không ảnh hưởng filter/sort |
| 2 | Component `WidgetFlashDaily` 2,893 dòng trong 1 file — vi phạm Clean Code rule SRP, khó test/maintain | Med | Deferred → v1.2.0. Cân nhắc split thành `widget-flash-daily-chart.tsx` + `-cards.tsx` |
| 3 | `inferCustomerDimensionType` dùng substring match thay vì field — fragile khi customer name tiếng Anh | ~~Med~~ → **N/A** | OQ-07: Mondelez không phân biệt NPP/Customer ([[project-mondelez-npp-eq-customer]]) → BỎ luôn dropdown + helper trong v1.1.0 |
| 4 | KHÔNG mock data fallback khi `!hasSqlConfig` — UX không trùng pattern OTIF | Low | Decision: giữ nguyên — Mondelez có config thật, không cần mock |
| 5 | `findPlannedTotalVolume` dựa pattern match string Tiếng Việt "kế hoạch xuất" — fragile khi i18n sang EN | Med | Cần field cố định từ SQL — defer v1.2.0 |
| 6 | 6 status colors hardcode hex — duplicate giữa `STATUS_COLORS` constant và chart rendering | Low | Defer v1.2.0 |
| 7 | Bảng T1 Completion có synthetic fallback "sinh số liệu giả" — nguy hiểm cho production decision | **High** | **v1.1.0 fix pattern** (audit A2): (a) Replace [widget-flash-daily.tsx:1813-1910](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1813-L1910) bằng `return [] as CompletionRateRow[]`; (b) Render EmptyState ("Chưa cấu hình tblCompletion SQL") ở consumer line 2878 khi `completionRows.length === 0`; (c) Xoá constants `COMPLETION_WH_NAMES`/`COMPLETION_CHANNELS`/`COMPLETION_AREAS` ở [lines 166-175](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L166-L175). |
| 8 | 3 legacy keys (`cards`, `charts`, `table`) còn trong type — chưa cleanup | Low | Boy Scout: gỡ sau khi confirm không tenant nào còn dùng. Defer v1.2.0. |
| 9 | 17 useQuery có thể overload | Med | OQ-09 deferred → v1.3.0 (consolidate 17 → 5 query). |
| 10 | Status "Đã xuất kho" + "Đang vận chuyển" cùng dùng `SUM(QTY SHIPPEDDETAIL)` — nghi double-count nếu STM signal lag | ~~High~~ → **Low** | **Audit A3 reversal**: CH MV pre-computes `e2e_label` mutually exclusive qua check `thoi_gian_di IS NULL`. **Zero double-count risk** — chỉ là operational caveat (signal lag). Action v1.1.0: thêm tooltip "Chưa nhận tín hiệu ATD từ STM" ở 2 KPI status — KHÔNG block release. |
| 11 | **`STATUS_ORDER` constant sai thứ tự nghiệp vụ E2E** ở [widget-flash-daily.tsx:91-97](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L91-L97). Order hiện hành không phản ánh đúng luồng "Chưa xuất → Đang xuất → Đã xuất → Đang vận → Đã vận". | Med | **v1.1.0 fix**: Sửa constant thành `['Chưa xuất kho', 'Đang xuất kho', 'Đã xuất kho', 'Đang vận chuyển', 'Đã vận chuyển']` — ảnh hưởng L3 Funnel strip render order + chart legend order. |

---

## 21. Change history

| Version | Ngày | Tác giả | Thay đổi |
|---------|------|---------|---------|
| 1.0.0 | 2026-05-16 | PM/DA via `/da-trace` | Observed baseline từ source code — 17 useQuery / 5 chart / 9 grid spec + 10 drift items. |
| 1.1.0 | 2026-05-16 | PM/DA via `/da-biz-ba` | Storytelling refresh. (1) Add §6.7 spec L4 Drop Trend chart mới (`chartDropTrend` section key, full SQL CTE backfill 44 ngày, target ≤5% + rolling 30d, FAIL = `status='Cancel'` only, date type chỉ allow GI/Actual Ship/ATA). (2) Sửa §18 FormConfig wording — file-based (`FileBasedFormConfigProvider` + IMemoryCache TTL 2h, deployed via `Smartlog.Api.csproj`, global scope), KHÔNG DB-seeded. Verify bằng runtime smoke `GET /api/forms/{code}` × 9. (3) §20 drift list: #7 (T1 synthetic) thêm fix pattern 3-step; #10 (STM double-count) downgrade severity Low theo audit A3 reversal; #3 (NPP/Customer) downgrade N/A theo D3 chốt; #11 mới (STATUS_ORDER sai thứ tự E2E). |
| 1.2.0 | 2026-05-19 | PM/DA | Move default SQL ra khỏi code FE (`widget-flash-daily-settings-dialog.tsx` không còn embed `defaultSql` cho `chartWarehouse` / `chartDeliveryArea` / `chartCustomer` / `chartSalesChannel` / `chartDropTrend`). Tenant admin paste SQL trực tiếp trong Settings dialog. Canonical SQL templates lưu ở §22 dưới đây để copy-paste. |
| 1.3.0 | 2026-05-20 | PM/DA (Executed by Claude Opus 4.7) | (1) Tách L2 Điểm nóng cần xử lý hôm nay khỏi reuse data L5 → 3 section keys mới `exceptionWarehouse` / `exceptionDrop` / `exceptionRegion`. FE render empty-state nhắc paste SQL khi chưa cấu hình (KHÔNG fallback derive từ L5+T7/T8 như v1.2.x). (2) L4 `chartDropTrend` từ filter-independent (`filterOverrides: {}`) → nhận full filter binds giống L1/L3/L5 (queryKey include `applied`). (3) Add §22.3/22.4/22.5 spec sections (required cols + rules + SQL skeleton để PM/DA paste). (4) Update §22.2 note về filter mapping change. |

---

## 22. Canonical SQL templates (paste vào Settings dialog)

> **Note**: Từ v1.2.0, FE KHÔNG còn `defaultSql` embedded — các template dưới đây là canonical reference để tenant admin paste vào Settings dialog (UI: Setting Chart → chọn section key → dán SQL). Stack giả định ClickHouse `analytics_workspace` (Mondelez). Tenant khác phải adapt schema.
>
> Placeholders runtime substituted bởi `WidgetFilterResolver`: `{{date_type}}`, `{{from_date}}`, `{{to_date}}`, `{{uom}}`, `{{whseid}}`, `{{group_name}}`, `{{brand}}`, `{{group_of_cargo}}`, `{{region}}`. Multi-select truyền dạng CSV → `splitByChar(',', {{key}})`. Filter chưa chọn → empty string.

### 22.1 L5 Dimension panels — `chartWarehouse` / `chartDeliveryArea` / `chartCustomer` / `chartSalesChannel`

4 section keys dùng cùng shape SQL — chỉ khác `${dimColumn}`:
- `chartWarehouse` → `whseid`
- `chartDeliveryArea` → `khu_vuc_doi_xe`
- `chartCustomer` → `customer_name`
- `chartSalesChannel` → `group_name`

**Required output columns**: `${dimColumn}`, `total_volume`, `done_volume`, `pending_volume`, `pct_done`.

**Done definition**: `trang_thai_don_do = 'Đã vận chuyển'` (final E2E status).

⚠ **PARITY guard**: Phải filter `trang_thai_don_do IN` 5 canonical status (xem inline) để khớp denominator với L1 Hero (`cardKpiStatus`). Bỏ filter này → SUM(total_volume) sẽ to hơn L1 plan vì bao gồm cả Cancel + non-canonical (lệch ratio ~1.84× đã từng gặp).

```sql
WITH base AS (
  SELECT
    t.${dimColumn} AS dim_value,
    t.trang_thai_don_do,
    CASE
      WHEN {{uom}} = 'cse'    THEN toFloat64(coalesce(t.original_cse, 0))
      WHEN {{uom}} = 'ton'    THEN toFloat64(coalesce(t.original_kg,  0)) / 1000.0
      WHEN {{uom}} = 'cbm'    THEN toFloat64(coalesce(t.original_cbm, 0))
      WHEN {{uom}} = 'pallet' THEN toFloat64(coalesce(t.original_pl,  0))
      WHEN {{uom}} = 'do'     THEN 1.0
      ELSE                         toFloat64(coalesce(t.original_cse, 0))
    END AS volume_value
  FROM analytics_workspace.mv_flash_report t
  WHERE toDate(CASE
          WHEN {{date_type}} = 'GI date'          THEN t.delivery_date_1
          WHEN {{date_type}} = 'Actual Ship date' THEN t.actual_ship_date
          WHEN {{date_type}} = 'ETD gửi thầu'      THEN t.etd_chuyen_gui_thau
          WHEN {{date_type}} = 'ATA đơn'           THEN t.ata_den
          WHEN {{date_type}} = 'ETA gửi thầu'      THEN t.eta_giao_hang_cho_npp
          ELSE t.delivery_date_1
        END) BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
                 AND toDate(coalesce({{to_date}},   '2999-12-31'))
    AND t.trang_thai_don_do IN (
      'Chưa xuất kho', 'Đang xuất kho', 'Đã xuất kho',
      'Đang vận chuyển', 'Đã vận chuyển'
    )
    AND ({{whseid}}         = '' OR t.whseid          IN splitByChar(',', {{whseid}}))
    AND ({{group_name}}     = '' OR t.group_name      IN splitByChar(',', {{group_name}}))
    AND ({{brand}}          = '' OR coalesce(t.brand, 'Unclassified') IN splitByChar(',', {{brand}}))
    AND ({{group_of_cargo}} = '' OR coalesce(t.group_of_cago, 'Unclassified') IN splitByChar(',', {{group_of_cargo}}))
    AND ({{region}}         = '' OR t.khu_vuc_doi_xe  IN splitByChar(',', {{region}}))
)
SELECT
  coalesce(dim_value, 'Unclassified') AS ${dimColumn},
  SUM(volume_value) AS total_volume,
  SUM(if(trang_thai_don_do = 'Đã vận chuyển', volume_value, 0)) AS done_volume,
  SUM(if(trang_thai_don_do <> 'Đã vận chuyển' OR trang_thai_don_do IS NULL,
         volume_value, 0)) AS pending_volume,
  if(SUM(volume_value) = 0, 0,
     SUM(if(trang_thai_don_do = 'Đã vận chuyển', volume_value, 0))
       / SUM(volume_value)) AS pct_done
FROM base
GROUP BY dim_value
ORDER BY total_volume DESC;
```

### 22.2 L4 Drop Trend 14 ngày — `chartDropTrend`

**Required output columns**: `date`, `total_plan`, `total_failed`, `drop_rate`, `drop_rate_30d_avg`.

**Rules**:
- FAIL = `status = 'Cancel'` only (canonical theo sql-registry.md "Flash Report").
- Date type allowed: `'GI date'` / `'Actual Ship date'` / `'ATA đơn'`. ETD/ETA disabled trên UX (L4 component fallback EmptyState).
- Backfill **44 ngày** trong CTE để 14 visible rows có đủ 30 priors cho `avg(...) OVER (ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)`.
- **Từ v1.3.0**: L4 nhận **full filter binds** giống L1/L3/L5 (`uom`, `dateType`, `whseid`, `group_name`, `brand`, `group_of_cargo`, `region`, `from_date`, `to_date`). SQL author quyết định:
  - Anchor 14d window vào `{{to_date}}` (template hiện tại) — chart luôn render 14 ngày gần nhất so với to_date.
  - Hoặc dùng nguyên `BETWEEN from_date AND to_date` — chart chạy theo đúng range user chọn (lưu ý: nếu range < 14 ngày thì rolling 30d avg mất nghĩa).

```sql
WITH flash_base AS (
  SELECT
    toDate(CASE
      WHEN {{date_type}} = 'GI date'          THEN delivery_date_1
      WHEN {{date_type}} = 'Actual Ship date' THEN actual_ship_date
      WHEN {{date_type}} = 'ATA đơn'           THEN ata_den
      ELSE delivery_date_1
    END) AS d,
    toFloat64(coalesce(original_cse, 0))
      + toFloat64(coalesce(original_qty, 0)) AS plan_v
  FROM analytics_workspace.mv_flash_report
  WHERE toDate(CASE
          WHEN {{date_type}} = 'GI date'          THEN delivery_date_1
          WHEN {{date_type}} = 'Actual Ship date' THEN actual_ship_date
          WHEN {{date_type}} = 'ATA đơn'           THEN ata_den
          ELSE delivery_date_1
        END) BETWEEN toDate({{to_date}}) - 43 AND toDate({{to_date}})
    AND ({{whseid}}         = '' OR whseid          IN splitByChar(',', {{whseid}}))
    AND ({{group_name}}     = '' OR group_name      IN splitByChar(',', {{group_name}}))
    AND ({{group_of_cargo}} = '' OR coalesce(group_of_cago, 'Unclassified') IN splitByChar(',', {{group_of_cargo}}))
    AND ({{region}}         = '' OR khu_vuc_doi_xe  IN splitByChar(',', {{region}}))
),
drop_base AS (
  SELECT
    toDate(CASE
      WHEN {{date_type}} = 'GI date'          THEN delivery_date_1
      WHEN {{date_type}} = 'Actual Ship date' THEN actual_ship_date
      WHEN {{date_type}} = 'ATA đơn'           THEN ata_den
      ELSE delivery_date_1
    END) AS d,
    toFloat64(coalesce(original_cse, 0))
      + toFloat64(coalesce(original_qty, 0)) AS plan_v,
    if(status = 'Cancel',
       toFloat64(coalesce(original_cse, 0)) + toFloat64(coalesce(original_qty, 0)),
       0) AS fail_v
  FROM analytics_workspace.mv_dropped_report
  WHERE toDate(CASE
          WHEN {{date_type}} = 'GI date'          THEN delivery_date_1
          WHEN {{date_type}} = 'Actual Ship date' THEN actual_ship_date
          WHEN {{date_type}} = 'ATA đơn'           THEN ata_den
          ELSE delivery_date_1
        END) BETWEEN toDate({{to_date}}) - 43 AND toDate({{to_date}})
    AND ({{whseid}}         = '' OR whseid          IN splitByChar(',', {{whseid}}))
    AND ({{group_name}}     = '' OR group_name      IN splitByChar(',', {{group_name}}))
    AND ({{group_of_cargo}} = '' OR coalesce(group_of_cago, 'Unclassified') IN splitByChar(',', {{group_of_cargo}}))
    AND ({{region}}         = '' OR khu_vuc_doi_xe  IN splitByChar(',', {{region}}))
),
per_day AS (
  SELECT d, SUM(plan_v) AS total_plan, 0          AS total_failed FROM flash_base GROUP BY d
  UNION ALL
  SELECT d, SUM(plan_v) AS total_plan, SUM(fail_v) AS total_failed FROM drop_base  GROUP BY d
),
daily AS (
  SELECT
    d AS date,
    SUM(total_plan)   AS day_plan,
    SUM(total_failed) AS day_failed,
    if(SUM(total_plan) = 0, 0,
       round(100.0 * SUM(total_failed) / SUM(total_plan), 2)) AS drop_rate
  FROM per_day
  GROUP BY d
)
SELECT
  date,
  day_plan   AS total_plan,
  day_failed AS total_failed,
  drop_rate,
  avg(drop_rate) OVER (
    ORDER BY date
    ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
  ) AS drop_rate_30d_avg
FROM daily
ORDER BY date DESC
LIMIT 14;
```

### 22.3 L2 Điểm nóng — Kho (`exceptionWarehouse`)

**Required output columns**: `name` (hoặc alias `whseid_name` / `warehouse_name` / `whseid`), `pct_done` (số 0..100 hoặc 0..1 — FE auto-detect).

**Rules**:
- SQL phải tự `WHERE pct_done < 0.85` (hoặc 85 nếu xài %) — FE KHÔNG filter ngưỡng lần nữa.
- SQL phải tự `ORDER BY pct_done ASC LIMIT 3` (hoặc top N theo PM quyết định).
- Phải filter `trang_thai_don_do IN` 5 canonical status (PARITY guard với L1 Hero / L5 panels).
- Filter binds dùng được: `{{uom}}`, `{{date_type}}`, `{{from_date}}`, `{{to_date}}`, `{{whseid}}`, `{{group_name}}`, `{{brand}}`, `{{group_of_cargo}}`, `{{region}}`.

```sql
-- L2 Điểm nóng — Kho (section key exceptionWarehouse)
-- Output: kho có pct_done < 85%, worst-first, top 3
-- PARITY guard: cùng denominator với L1 Hero và L5 chartWarehouse
-- FE reads: name alias 'name'|'whseid_name'|'warehouse_name'|'whseid'; pct_done 0..1

WITH base AS (
  SELECT
    t.whseid AS dim_value,
    t.trang_thai_don_do,
    CASE
      WHEN {{uom}} = 'cse'    THEN toFloat64(coalesce(t.original_cse, 0))
      WHEN {{uom}} = 'ton'    THEN toFloat64(coalesce(t.original_kg,  0)) / 1000.0
      WHEN {{uom}} = 'cbm'    THEN toFloat64(coalesce(t.original_cbm, 0))
      WHEN {{uom}} = 'pallet' THEN toFloat64(coalesce(t.original_pl,  0))
      WHEN {{uom}} = 'do'     THEN 1.0
      ELSE                         toFloat64(coalesce(t.original_cse, 0))
    END AS volume_value
  FROM analytics_workspace.mv_flash_report t
  WHERE toDate(CASE
          WHEN {{date_type}} = 'GI date'          THEN t.delivery_date_1
          WHEN {{date_type}} = 'Actual Ship date' THEN t.actual_ship_date
          WHEN {{date_type}} = 'ETD gửi thầu'      THEN t.etd_chuyen_gui_thau
          WHEN {{date_type}} = 'ATA đơn'           THEN t.ata_den
          WHEN {{date_type}} = 'ETA gửi thầu'      THEN t.eta_giao_hang_cho_npp
          ELSE t.delivery_date_1
        END) BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
                 AND toDate(coalesce({{to_date}},   '2999-12-31'))
    -- Canonical 5 status filter — PARITY với L1 Hero (bắt buộc)
    AND t.trang_thai_don_do IN (
      'Chưa xuất kho', 'Đang xuất kho', 'Đã xuất kho',
      'Đang vận chuyển', 'Đã vận chuyển'
    )
    AND ({{whseid}}         = '' OR t.whseid          IN splitByChar(',', {{whseid}}))
    AND ({{group_name}}     = '' OR t.group_name      IN splitByChar(',', {{group_name}}))
    AND ({{brand}}          = '' OR coalesce(t.brand, 'Unclassified') IN splitByChar(',', {{brand}}))
    AND ({{group_of_cargo}} = '' OR coalesce(t.group_of_cago, 'Unclassified') IN splitByChar(',', {{group_of_cargo}}))
    AND ({{region}}         = '' OR t.khu_vuc_doi_xe  IN splitByChar(',', {{region}}))
),
agg AS (
  SELECT
    coalesce(dim_value, 'Unclassified') AS name,
    SUM(volume_value) AS total_volume,
    SUM(if(trang_thai_don_do = 'Đã vận chuyển', volume_value, 0)) AS done_volume,
    if(SUM(volume_value) = 0, 0,
       SUM(if(trang_thai_don_do = 'Đã vận chuyển', volume_value, 0))
         / SUM(volume_value)) AS pct_done
  FROM base
  GROUP BY dim_value
)
SELECT name, pct_done
FROM agg
WHERE pct_done < 0.85
ORDER BY pct_done ASC
LIMIT 3;
```

### 22.4 L2 Điểm nóng — Drop + Lý do (`exceptionDrop`)

**Required output columns**: `row_type` (`'total'` | `'reason'`), `reason` (text — null/empty cho total row), `fresh_dry_cse`, `posm_pc`.

**Rules**:
- Output 1 row tổng + N rows lý do trong cùng query (UNION ALL).
  - Row tổng: `row_type='total'`, `reason=NULL`, `fresh_dry_cse` + `posm_pc` = tổng failed của period.
  - Rows lý do: `row_type='reason'`, `reason=<remark_2>`, ranked DESC theo (fresh_dry_cse + posm_pc), LIMIT 4.
- FAIL = `status = 'Cancel'` only (canonical theo sql-registry "Flash Report").
- Unit convention: FRESH/DRY → CSE; POSM → PC (PCE). KHÔNG sum CSE + PC (mỗi unit render độc lập).
- Filter binds dùng được: giống §22.3.

```sql
-- L2 Điểm nóng — Drop + Lý do (section key exceptionDrop)
-- Output: 1 total row + top 4 reason rows (UNION ALL)
-- FAIL = status = 'Cancel' only (canonical)
-- FE reads: row_type 'total'|'reason'; reason; fresh_dry_cse; posm_pc

WITH drop_base AS (
  SELECT
    remark_2,
    if(coalesce(group_of_cago, '') IN ('FRESH', 'DRY'),
       toFloat64(coalesce(original_cse, 0)), 0) AS fresh_dry_v,
    if(coalesce(group_of_cago, '') = 'POSM',
       toFloat64(coalesce(original_qty, 0)), 0) AS posm_v
  FROM analytics_workspace.mv_dropped_report
  WHERE status = 'Cancel'
    AND toDate(CASE
          WHEN {{date_type}} = 'GI date'          THEN delivery_date_1
          WHEN {{date_type}} = 'Actual Ship date' THEN actual_ship_date
          WHEN {{date_type}} = 'ATA đơn'           THEN ata_den
          ELSE delivery_date_1
        END) BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
                 AND toDate(coalesce({{to_date}},   '2999-12-31'))
    AND ({{whseid}}         = '' OR whseid          IN splitByChar(',', {{whseid}}))
    AND ({{group_name}}     = '' OR group_name      IN splitByChar(',', {{group_name}}))
    AND ({{group_of_cargo}} = '' OR coalesce(group_of_cago, 'Unclassified') IN splitByChar(',', {{group_of_cargo}}))
    AND ({{region}}         = '' OR khu_vuc_doi_xe  IN splitByChar(',', {{region}}))
)
-- Row tổng (total)
SELECT
  'total'           AS row_type,
  NULL              AS reason,
  SUM(fresh_dry_v)  AS fresh_dry_cse,
  SUM(posm_v)       AS posm_pc
FROM drop_base

UNION ALL

-- Rows lý do (reason), top 4 worst by volume
SELECT
  'reason'         AS row_type,
  coalesce(remark_2, 'Không rõ') AS reason,
  SUM(fresh_dry_v) AS fresh_dry_cse,
  SUM(posm_v)      AS posm_pc
FROM drop_base
WHERE remark_2 IS NOT NULL AND remark_2 <> ''
GROUP BY remark_2
ORDER BY (fresh_dry_cse + posm_pc) DESC
LIMIT 4;
```

### 22.5 L2 Điểm nóng — Khu vực (`exceptionRegion`)

**Required output columns**: `name` (hoặc alias `region` / `delivery_area` / `khu_vuc_doi_xe`), `pct_done`.

**Rules**: giống §22.3 — chỉ thay `whseid` dimension bằng `khu_vuc_doi_xe`.

```sql
-- L2 Điểm nóng — Khu vực (section key exceptionRegion)
-- Output: khu vực có pct_done < 85%, worst-first, top 3
-- PARITY guard: cùng denominator với L1 Hero và L5 chartDeliveryArea
-- FE reads: name alias 'name'|'region'|'delivery_area'|'khu_vuc_doi_xe'; pct_done 0..1

WITH base AS (
  SELECT
    t.khu_vuc_doi_xe AS dim_value,
    t.trang_thai_don_do,
    CASE
      WHEN {{uom}} = 'cse'    THEN toFloat64(coalesce(t.original_cse, 0))
      WHEN {{uom}} = 'ton'    THEN toFloat64(coalesce(t.original_kg,  0)) / 1000.0
      WHEN {{uom}} = 'cbm'    THEN toFloat64(coalesce(t.original_cbm, 0))
      WHEN {{uom}} = 'pallet' THEN toFloat64(coalesce(t.original_pl,  0))
      WHEN {{uom}} = 'do'     THEN 1.0
      ELSE                         toFloat64(coalesce(t.original_cse, 0))
    END AS volume_value
  FROM analytics_workspace.mv_flash_report t
  WHERE toDate(CASE
          WHEN {{date_type}} = 'GI date'          THEN t.delivery_date_1
          WHEN {{date_type}} = 'Actual Ship date' THEN t.actual_ship_date
          WHEN {{date_type}} = 'ETD gửi thầu'      THEN t.etd_chuyen_gui_thau
          WHEN {{date_type}} = 'ATA đơn'           THEN t.ata_den
          WHEN {{date_type}} = 'ETA gửi thầu'      THEN t.eta_giao_hang_cho_npp
          ELSE t.delivery_date_1
        END) BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
                 AND toDate(coalesce({{to_date}},   '2999-12-31'))
    -- Canonical 5 status filter — PARITY với L1 Hero (bắt buộc)
    AND t.trang_thai_don_do IN (
      'Chưa xuất kho', 'Đang xuất kho', 'Đã xuất kho',
      'Đang vận chuyển', 'Đã vận chuyển'
    )
    AND ({{whseid}}         = '' OR t.whseid          IN splitByChar(',', {{whseid}}))
    AND ({{group_name}}     = '' OR t.group_name      IN splitByChar(',', {{group_name}}))
    AND ({{brand}}          = '' OR coalesce(t.brand, 'Unclassified') IN splitByChar(',', {{brand}}))
    AND ({{group_of_cargo}} = '' OR coalesce(t.group_of_cago, 'Unclassified') IN splitByChar(',', {{group_of_cargo}}))
    AND ({{region}}         = '' OR t.khu_vuc_doi_xe  IN splitByChar(',', {{region}}))
),
agg AS (
  SELECT
    coalesce(dim_value, 'Unclassified') AS name,
    SUM(volume_value) AS total_volume,
    SUM(if(trang_thai_don_do = 'Đã vận chuyển', volume_value, 0)) AS done_volume,
    if(SUM(volume_value) = 0, 0,
       SUM(if(trang_thai_don_do = 'Đã vận chuyển', volume_value, 0))
         / SUM(volume_value)) AS pct_done
  FROM base
  GROUP BY dim_value
)
SELECT name, pct_done
FROM agg
WHERE pct_done < 0.85
ORDER BY pct_done ASC
LIMIT 3;
```
