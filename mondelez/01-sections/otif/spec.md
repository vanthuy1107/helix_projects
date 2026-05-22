# Spec — Section OTIF

> **Phạm vi:** Tài liệu kỹ thuật chi tiết cho widget `WidgetOtif`.
> **Nguồn:** 100% trích xuất từ source code — `widget-otif.tsx`, `widget-otif-detail.tsx`, `widget-otif.columns.ts`, `widget-otif-settings-dialog.tsx`, `dashboard-order-monitor.json`.
>
> **Refresh 2026-05-12 (v1.1.0)** — đồng bộ với FEAT-128 (reorder + Chart by Category) và chartByWarehouse pre-existing. Trace report: [`projects/trace/widget-otif-chart-reorder-and-category-2026-05-12.md`](../../../trace/widget-otif-chart-reorder-and-category-2026-05-12.md).

---

## 1. Component Tree

```
WidgetOtif
├── SqlFilterPanel (sticky, autoApply)           ← khi filterStorageKey tồn tại
│   └── OTIF_FILTER_DEFINITIONS (6 filter fields)
├── Fallback filter bar (7 select/date inputs)   ← khi không có filterStorageKey
│   └── Nút Apply / Reset
└── Tabs
    ├── Tab "chart"  (thứ tự insight-first sau FEAT-128 — root cause trước, segment sau)
    │   ├── KPI Cards Row (grid 2→4 cols)
    │   │   ├── KpiCard: Tổng đơn      (icon: Target,       color: #60A5FA)
    │   │   ├── KpiCard: % Ontime      (icon: Clock,        color: #22D3EE)
    │   │   ├── KpiCard: % Infull      (icon: CheckCircle,  color: #10B981)
    │   │   └── KpiCard: % OTIF        (icon: AlertTriangle,color: #8E59FF)
    │   ├── Grid 2 cols (xl) — Lý do fail (root cause)
    │   │   ├── ChartCard: Fail Ontime Reason  (BarChart horiz, h=256px)
    │   │   └── ChartCard: Fail Infull Reason  (BarChart horiz, h=256px)
    │   ├── ChartCard: Trend by Time   (ComposedChart,     h=288px)
    │   │   └── TimeBucket toggle: Day | Week | Month
    │   ├── ChartCard: By Transporter  (BarChart grouped,  h=288px)
    │   ├── ChartCard: By Category ★   (BarChart grouped,  h=288px)  ← FEAT-128 (NEW)
    │   ├── ChartCard: By Sales Channel(BarChart grouped,  h=288px)
    │   ├── ChartCard: By Warehouse ★  (BarChart grouped,  h=288px)
    │   └── ChartCard: By Area         (BarChart grouped,  h=288px)
    └── Tab "detail"
        └── OtifDetailPanel
            ├── Tabs (inner)
            │   ├── Tab: %OTIF Chiều vận hành
            │   │   ├── Dimension toggles (NVC | Kênh | Nhóm hàng | Khu vực)
            │   │   └── WidgetGrid<SummaryReportRow>
            │   ├── Tab: Fail Report
            │   │   ├── Dimension toggles
            │   │   └── WidgetGrid<FailSummaryReportRow>
            │   └── Tab: Chi tiết đơn hàng
            │       └── WidgetGrid<OtifRow>
            └── useQuery (detailTable, operationSummary, failSummary)
```

---

## 2. State Management

### 2.1 Filter state (applied vs. draft)

Widget duy trì hai tập state song song — draft (hiển thị trong UI) và applied (dùng để query):

| State | Draft | Applied | Mô tả |
|-------|-------|---------|-------|
| Kho | `whDraft` | `wh` | WarehouseFilterValue |
| Khu vực | `areaDraft` | `area` | string, mặc định `'ALL'` |
| Nhóm hàng | `cargoDraft` | `cargo` | string, mặc định `'ALL'` |
| NVC | `transporterDraft` | `transporter` | string, mặc định `'ALL'` |
| Loại ngày | `dateTypeDraft` | `dateType` | `'ETA gửi thầu'` mặc định |
| Từ ngày | `fromDateDraft` | `fromDate` | ISO date string, mặc định hôm nay |
| Đến ngày | `toDateDraft` | `toDate` | ISO date string, mặc định hôm nay |

Draft chỉ được chuyển thành applied khi user nhấn Apply (hoặc `autoApply` trong `SqlFilterPanel`).

### 2.2 Derived state từ filter

```ts
filterOverrides = {
  whseid:          wh === 'ALL' ? DEFAULT_WAREHOUSES.join(',') : mappedWhseid,
  area:            area === 'ALL' ? '' : area,
  group_of_cargo:  cargo === 'ALL' ? '' : cargo,
  group_of_cago:   cargo === 'ALL' ? '' : cargo,   // alias
  transporter:     transporter === 'ALL' ? '' : transporter,
  from_date:       `${fromDate} 00:00:00`,
  to_date:         `${toDate} 23:59:59`,
  date_type:       dateType,
  dateType:        dateType,
  loai_ngay:       dateType,
}
```

### 2.3 Query keys & cache

```ts
queryKey: ['order-monitor', 'otif', dashboardId, widgetId, filterOverrides, hasSqlConfig]
staleTime: 5 * 60 * 1000  // 5 phút
placeholderData: prev       // giữ data cũ trong lúc refetch
```

### 2.4 Các state khác

| State | Type | Mặc định | Mô tả |
|-------|------|---------|-------|
| `timeBucket` | `'day'\|'week'\|'month'` | `'day'` | Granularity của Trend chart |
| `summaryDims` | `SummaryDimensionKey[]` | `['transporter','groupName','groupOfCargo','area']` | Chiều pivot cho Operation/Fail Summary |
| `filterInitialized` | `boolean` | `false` khi có filterStorageKey | Guard tránh query trước khi filter restore |

---

## 3. Data Fetching

### 3.1 Main query (9 sections song song)

Thực hiện trong `useQuery`, enabled khi `hasSqlConfig && dashboardId && widgetId && filterInitialized`:

```
Promise.all([
  execSection('cards',              sqlQueries.cards),
  execSection('chartByArea',        sqlQueries.chartByArea),
  execSection('chartBySalesChannel',sqlQueries.chartBySalesChannel),
  execSection('chartByTransporter', sqlQueries.chartByTransporter),
  execSection('chartByWarehouse',   sqlQueries.chartByWarehouse),   // ★
  execSection('chartByCategory',    sqlQueries.chartByCategory),    // ★ FEAT-128
  execSection('chartFailOntime',    sqlQueries.chartFailOntime),
  execSection('chartFailInfull',    sqlQueries.chartFailInfull),
  execSection('chartTrend',         sqlQueries.chartTrend),
])
```

> **[Observed]** — [widget-otif.tsx:855-863](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L855-L863). v1.0.0 ghi 7 sections; v1.1.0 = 9 (+`chartByWarehouse`, +`chartByCategory`).

Mỗi `execSection` gọi `dashboardV2Api.executeWidget(dashboardId, widgetId, { sectionKey, filterOverrides, pageSize: 500 })`.

### 3.2 Detail queries (lazy — chỉ khi tab 'detail' active)

| Query key | SQL nguồn | pageSize |
|-----------|-----------|----------|
| `operationSummary` | `sqlQueries.operationSummary` | 500 |
| `failSummary` | `sqlQueries.failSummary` | 500 |
| `detailTable` | `sqlQueries.detailTable \|\| parsedConfig.sql` | 2000 |

### 3.3 Fallback mock

Khi `!hasSqlConfig`, `buildMock()` tạo 120 dòng `OtifRow` synthetic với:
- 4 khu vực × 3 kho × 11 NVC × 7 nhóm hàng
- `eta`, `ata`, `plannedCse`, `shippedCse`, `deliveredCse` được tính theo pattern deterministic (không random)

---

## 4. Normalization Functions

| Hàm | Input | Output | Ghi chú |
|-----|-------|--------|--------|
| `normalizeSummaryFromSql(rows)` | `Record[]` | `OtifSummary` | Lấy row[0], map 7 fields |
| `normalizeAreaProgressFromSql(rows)` | `Record[]` | `OtifAreaProgressRow[]` | key `khuVucDoiXe` dùng alias `area\|khu_vuc_doi_xe` |
| `normalizeSalesChannelProgressFromSql(rows)` | `Record[]` | `OtifAreaProgressRow[]` | key `khuVucDoiXe` dùng alias `kenh_ban_hang\|group_name\|sales_channel` |
| `normalizeTransporterProgressFromSql(rows)` | `Record[]` | `OtifAreaProgressRow[]` | key `khuVucDoiXe` dùng alias `nha_van_tai\|ten_ngan_nha_van_tai\|transporter` |
| `normalizeWarehouseProgressFromSql(rows)` ★ | `Record[]` | `OtifAreaProgressRow[]` | key `khuVucDoiXe` dùng alias `kho\|whseid\|warehouse` — [widget-otif.tsx:194-207](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L194-L207) |
| `normalizeCategoryProgressFromSql(rows)` ★ | `Record[]` | `OtifAreaProgressRow[]` | key `khuVucDoiXe` dùng alias `group_of_cago\|group_of_cargo\|groupofcargo\|groupOfCargo\|category` — [widget-otif.tsx:208-227](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L208-L227) (FEAT-128) |
| `normalizeFailReasonFromSql(rows)` | `Record[]` | `OtifFailReasonRow[]` | fields: `reason`, `fail_so` |
| `normalizeTrendFromSql(rows)` | `Record[]` | `OtifTrendByTimeRow[]` | fields: `period/day/week/month`, `total_so`, `otif_so` |
| `normalizeOperationSummaryFromSql(rows)` | `Record[]` | `SummaryReportRow[]` | pct_otif tự tính nếu = 0 |
| `normalizeFailSummaryFromSql(rows)` | `Record[]` | `FailSummaryReportRow[]` | 11 fail-reason fields |
| `normalizeDetailTableFromSql(rows)` | `Record[]` | `OtifRow[]` | 50+ fields, trong `widget-otif-detail.tsx` |

Cả `sqlGS()` và `sqlGN()` dùng `.toLowerCase()` để match case-insensitive.

---

## 5. SQL Placeholder Binding

Hàm `bindOtifPlaceholders(sql: string): string` xử lý:

1. **Optional clause** `[[ AND ... {{placeholder}} ... ]]` — bị xóa hoàn toàn khi value là `null`
2. **Inline placeholder** `{{placeholder}}` — thay bằng giá trị hoặc empty string

| Placeholder | SQL literal output | Null khi |
|------------|-------------------|----------|
| `{{whseid}}` | `'BKD1','BKD2','BKD3'` | — (luôn có giá trị) |
| `{{area}}` | `'South East'` | area === 'ALL' |
| `{{group_of_cargo}}` / `{{group_of_cago}}` | `'PM','DRY'` | cargo === 'ALL' |
| `{{transporter}}` | `'HVP','TLL'` | transporter === 'ALL' |
| `{{from_date}}` | `'2026-01-01 00:00:00'` | — |
| `{{to_date}}` | `'2026-01-31 23:59:59'` | — |
| `{{date_type}}` / `{{dateType}}` / `{{loai_ngay}}` | `'ETA gửi thầu'` | — |

Single-quote escaping: `value.replace(/'/g, "''")`

---

## 6. Chart Specifications

### 6.1 Bar Chart By Area / By Sales Channel / By Transporter / By Warehouse / By Category

5 chart cùng pattern grouped bar (Recharts). Sau FEAT-128 + chartByWarehouse pre-existing, có **5 chart sử dụng pattern này** (v1.0.0 chỉ ghi 3).

| Property | Value |
|----------|-------|
| Component | `BarChart` (Recharts) |
| Layout | Vertical bars, grouped |
| Height | 288px (h-72) |
| X-Axis | Tên khu vực / kênh / NVC / kho (whseid) / loại hàng (FRESH/DRY/...) |
| Y-Axis | 0–100 (%) |
| Bars | 3 bars mỗi nhóm: Ontime (#22D3EE) / Infull (#10B981) / OTIF (#8E59FF) |
| LabelList | Trên đỉnh mỗi bar, format `X.X%` |
| Legend | Vertical, align right |
| Tooltip | Format `X.XX%` |
| Export | Ảnh PNG + CSV (`ChartExportMenu`) |

**Chart by Category — đặc thù** (FEAT-128):

| Property | Value |
|----------|-------|
| Sort order | Client-side theo `OTIF_CATEGORY_ORDER = ['FRESH','DRY','MOONCAKE','POSM/OFFBOM','TEST','EQUIPMENT','PM']` (priority 1-7). Loại không match → priority 99 + sort alpha. |
| Empty state | Khi `sqlQueries.chartByCategory` blank → render message i18n `categoryNoConfig` thay vì bar chart. Các chart khác KHÔNG bị block. — [widget-otif.tsx:1586-1591](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1586-L1591) |
| Accent gradient | `from-lime-500/80 to-lime-400/30` (khác chart khác để dễ phân biệt visually) |
| Export filename | `otif-by-category` |
| i18n keys | `orderMonitor.otif.chartByCategory`, `orderMonitor.otif.tooltipByCategory`, `orderMonitor.otif.categoryNoConfig` |

**Chart by Warehouse — đặc thù**:

| Property | Value |
|----------|-------|
| Dimension column | `kho` (alias `whseid`/`warehouse`) — output từ SQL theo whseid trực tiếp, không qua `mapWarehouseToWhseid` |
| Export filename | `otif-by-warehouse` |
| i18n keys | `orderMonitor.otif.chartByWarehouse`, `orderMonitor.otif.tooltipByWarehouse` |

### 6.2 Trend Chart (%OTIF theo thời gian)

| Property | Value |
|----------|-------|
| Component | `ComposedChart` |
| Height | 288px |
| Bar | `totalSo` (số đơn) — Y trục phải, màu #60A5FA |
| Line | `pctOtif` (%) — Y trục trái (0–100), màu #F59E0B, strokeWidth=2.5 |
| X-Axis | `period` — format: `YYYY-MM-DD` / `YYYY-WXX` / `YYYY-MM` |
| Time bucket | Toggle Day/Week/Month — tính toán client-side từ data đã fetch |
| Footer | Tổng số DO trong period |

### 6.3 Fail Ontime / Fail Infull Reason Charts

| Property | Value |
|----------|-------|
| Component | `BarChart layout='vertical'` |
| Height | 256px (h-64) |
| Hiển thị tối đa | 10 lý do đầu tiên (`slice(0, 10)`) |
| X-Axis | Số đơn (`fail_so`) |
| Y-Axis | Tên lý do, width=160px (Ontime) / 180px (Infull) |
| Bar Fail Ontime | Màu #F59E0B (amber) |
| Bar Fail Infull | Màu #EF4444 (red) |
| Footer | Tổng số DO fail |

---

## 7. KPI Card Specifications

| Card | Icon (lucide) | Color | Accent Gradient | Value Format | Sub-value |
|------|--------------|-------|-----------------|-------------|----------|
| Tổng đơn | `Target` | #60A5FA (blue) | `from-blue-400/80 to-blue-400/30` | `N.toLocaleString()` | — |
| % Ontime | `Clock` | #22D3EE (cyan) | `from-cyan-400/80 to-cyan-400/30` | `X.X%` | `N đơn` |
| % Infull | `CheckCircle` | #10B981 (emerald) | `from-emerald-500/80 to-emerald-400/30` | `X.X%` | `N đơn` |
| % OTIF | `AlertTriangle` | #8E59FF (violet) | `from-violet-500/80 to-violet-400/30` | `X.X%` | `N đơn` |

Mỗi card có: top border gradient (0.5px), icon có background `color+'20'`, tooltip question-mark (OtifHint), hover effect `-translate-y-0.5`.

---

## 8. Bảng cột — Detail Table

### 8.1 Cột hiển thị mặc định (visible by default)

| Key | Label | Type | Filter |
|-----|-------|------|--------|
| `so` | SO | string | text |
| `doCode` | DO | string | text |
| `warehouse` | Kho | string | multiselect |
| `area` | Khu vực | string | multiselect |
| `groupOfCargo` | Nhóm hàng | string | text |
| `groupName` | Kênh bán hàng | string | text |
| `transporter` | Nhà vận tải | string | text |
| `customerCode` | Mã khách hàng | string | text |
| `customerName` | Tên khách hàng | string | text |
| `loaiXeVanHanh` | Loại xe vận hành | string | text |
| `loaiXeGuiThau` | Loại xe gửi thầu | string | text |
| `eta` | ETA | datetime | text, sortable |
| `ata` | ATA | datetime | text, sortable |
| `plannedCse` | Kế hoạch | number | text, sortable |
| `shippedCse` | Xuất kho | number | text, sortable |
| `deliveredCse` | Giao | number | text, sortable |
| `maNhaXe` | Mã nhà xe | string | text |
| `sumOriginalCse` | Original CSE | number | text, sortable |
| `sumShippedCse` | Shipped CSE | number | text, sortable |
| `sumSanLuongGiaoCse` | Sản lượng giao CSE | number | text, sortable |
| `etaGiaoHangChoNpp` | ETA giao hàng cho NPP | datetime | text, sortable |
| `ataDen` | ATA đến | datetime | text, sortable |
| `ontimeStatus` | Ontime | string | multiselect, sortable |
| `infullStatus` | Infull | string | multiselect, sortable |
| `otifStatus` | OTIF | string | multiselect, sortable |
| `pctOtif` | % OTIF | percent | text, sortable |

### 8.2 Cột ẩn mặc định (`defaultHidden: true`) — 30+ cột

Gồm các nhóm:
- **Volume extended**: `sumOriginal`, `sumOriginalCbm`, `sumOriginalTon`, `sumOriginalPl`, `sumShipped`, `sumShippedCbm`, `sumShippedKg`, `sumShippedPl`, `sumSanLuongGiao`, `sumSanLuongGiaoCbm`, `sumSanLuongGiaoTon`, `sumSanLuongGiaoPl`
- **Chênh lệch**: `chenhLechSlGiaoCho`, `chenhLechSlGiaoChoCbm`, `chenhLechSlGiaoChoKg`, `chenhLechSlGiaoChoCse`, `chenhLechSlGiaoChoPl`
- **Đối tác nhận**: `maDoiTacNhan`, `tenDoiTacNhan`
- **Timestamp chuỗi**: `ngayGi`, `ngayTaoDon`, `thoiGianGuiThau`, `ngayDuyetChuyen`, `ngayTaoChuyen`, `etdChuyenGuiThau`, `gioDangTai`, `gioGoiXe`, `gioVaoCong`, `gioVaoDock`, `actualShipDate`, `gioRaDock`, `tgBatBuocRoiKho`, `gioRaCong`
- **Thời gian thực**: `tongTgTrongKhoMin`, `ataRoi`, `tgLoadHangMin`, `chenhLechTgThucTeDuKienHour`
- **Phân tích lỗi**: `notInfullReason`, `notOntimeReason`, `cseOtif`, `delayWarehouse`, `delayTransport`
- **Chuyến xe**: `soChuyen`, `soXe`, `taiXe`, `idChuyenGuiThau`

---

## 9. Bảng cột — Operation Summary

| Key | Label | Type | Render |
|-----|-------|------|--------|
| `transporter` | Nhà vận tải | string | multiselect filter |
| `groupName` | Kênh bán hàng | string | multiselect filter |
| `groupOfCargo` | Nhóm hàng | string | multiselect filter |
| `area` | Khu vực đội xe | string | multiselect filter |
| `totalSo` | Tổng số đơn | number | sortable |
| `pctOtif` | %OTIF (% và số đơn) | percent | `X.X% (N)` via `formatPctAndCount()` |
| `pctOntime` | %Ontime (% và số đơn) | percent | `X.X% (N)` |
| `pctInfull` | %Infull (% và số đơn) | percent | `X.X% (N)` |

---

## 10. Bảng cột — Fail Summary

| Key | Label | Color |
|-----|-------|-------|
| `transporter` | Nhà vận tải | — |
| `groupName` | Kênh bán hàng | — |
| `groupOfCargo` | Nhóm hàng | — |
| `area` | Khu vực đội xe | — |
| `totalSo` | Tổng số đơn | — |
| `failOntimeSo` | Số đơn fail Ontime | amber-400 |
| `lateArrivalByTransport` | Late arrival by Transport | — |
| `lateWarehouseCallByWarehouse` | Late wh call by Warehouse | — |
| `latePickupByWarehouse` | Late pickup by Warehouse | — |
| `lateDepartureByTransport` | Late departure by Transport | — |
| `lateDeliveryByTransport` | Late delivery by Transport | — |
| `failInfullSo` | Số đơn fail Infull | rose-400 |
| `warehouseInfullFailure` | Warehouse Infull failure | — |
| `transportInfullFailure` | Transport Infull failure | — |
| `warehouseTransportInfullFailure` | WH + Transport Infull failure | — |

---

## 11. Widget Config Schema

```ts
interface WidgetOtifConfig {
  dataSourceId?:      string                   // ID datasource trong Smartlog
  sourceObjectType?:  'table' | 'view'         // loại đối tượng SQL
  sourceObjectName?:  string                   // tên table/view
  sql?:               string                   // legacy single SQL (fallback cho detailTable)
  queries?:           Partial<OtifSqlQueries>  // 10 SQL queries
  filterConfig?:      SqlViewFilterConfig      // cấu hình filter động
}

interface OtifSqlQueries {
  cards: string
  chartByArea: string
  chartBySalesChannel: string
  chartByTransporter: string
  chartByWarehouse: string       // ★ pre-existing (commit 53dd564)
  chartByCategory: string        // ★ FEAT-128 (commit 80194e9)
  chartFailOntime: string
  chartFailInfull: string
  chartTrend: string
  operationSummary: string
  failSummary: string
  detailTable: string
}
```

**[Observed]** — [widget-otif-settings-dialog.tsx:20-33](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif-settings-dialog.tsx#L20-L33). Interface có **12 keys** (v1.0.0 ghi 10).

Config được serialized thành JSON string và lưu vào `widget.config` column.

---

## 12. Loading & Error States

| State | UI |
|-------|----|  
| `isLoading && !apiData` | Skeleton: 1 tall + 4 card skeleton + 1 flex-1 skeleton |
| `error && !apiData` | Error banner với AlertTriangle icon + message |
| `isFetching && apiData` | `placeholderData: prev` — hiển thị data cũ, loading indicator trên filter panel |
| `!hasSqlConfig` | Hiển thị mock data, không có loading state |

---

## 13. Edit Mode — Toolbar Actions

Khi `editMode = true` và widget có `filterStorageKey`, toolbar hiển thị 2 nút:

1. **WidgetOtifSettingsDialog** — mở settings dialog **12-tab SQL editor** (Cards / By Area / By Sales Channel / By Transporter / **By Warehouse** / **By Category** / Fail Ontime / Fail Infull / Trend / OTIF Ops / Fail Report / Detail). **[Observed]** — [widget-otif-settings-dialog.tsx:50-200+](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif-settings-dialog.tsx#L50). v1.0.0 ghi 10 tab.
2. **Filter Settings** (`SlidersHorizontal` icon, màu amber) — mở `SqlFilterPanel` settings

Cả hai chỉ xuất hiện khi user có quyền edit dashboard.

