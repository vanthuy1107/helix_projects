# Spec — VFR (Vehicle Fill Rate) widget

**Tenant:** Mondelez
**Section slug:** `vfr`
**Last updated:** 2026-05-19 (refreshed against `feat-vfr-late-alert` branch, commit `d7f1435`)

---

## 1. File map

| File | Role | Line count |
|---|---|---|
| [widget-vfr.tsx](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx) | Main widget — filter, mode toggle, KPI cards, 3 charts, time×area table | 1661 |
| [widget-vfr.columns.ts](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.columns.ts) | Detail grid column specs (29 cols) | 255 |
| [widget-vfr-detail.tsx](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr-detail.tsx) | Detail tab — server-paginated grid via React Query | 134 |
| [widget-vfr-settings-dialog.tsx](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr-settings-dialog.tsx) | Admin SQL config dialog — 14 sections | 270 |
| [__tests__/widget-vfr.columns.test.ts](frontend/src/features/dashboard/components/widgets/order-monitor/__tests__/widget-vfr.columns.test.ts) | Unit test — column key/label stability | 24 |
| [DSHVFRDTG01.json](backend/src/FormConfigs/DSHVFRDTG01.json) | Backend FormConfig — grid column metadata | — |

Registration:
- [widget-renderer.tsx:12](frontend/src/features/dashboard/components/widgets/widget-renderer.tsx#L12) — imports `WidgetVfr`, dispatch on `widget.widgetType === 'vfr'`.
- [DashboardConsts.cs:50](backend/src/Smartlog.Domain.Shared/Constants/DashboardConsts.cs#L50) — `"vfr"` listed in `ValidWidgetTypes`.
- [preset-templates.ts:696](frontend/src/features/dashboard/data/preset-templates.ts#L696) — preset `preset-om-vfr`.

---

## 2. Component contract

```ts
WidgetVfr({
  config,        // SqlWidgetProps['config'] — parsed via parseSqlWidgetConfig<VfrSqlConfig>
  dashboardId,   // string
  widgetId,      // string
  editMode,      // boolean — controls visibility of toolbar Settings buttons
})
```

`VfrSqlConfig extends SqlWidgetConfigBase { orderMonitorApiUrl?, queries?: Partial<VfrSqlQueries> }` — see [widget-vfr-settings-dialog.tsx:19-41](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr-settings-dialog.tsx#L19-L41).

---

## 3. State management

### 3.1 Local UI state

| State | Type | Default | Reason |
|---|---|---|---|
| `mode` | `'tender' \| 'operation'` | `'tender'` | Mode toggle — drives which SQL set + KPI/charts to render |
| `tenderLoadingTypeGroupBy` | `'day' \| 'week' \| 'month'` | `'month'` | Group-by selector for loading-type chart |
| `applied` | `{ pickupWarehouse, deliveryArea, carrier, dateType, dateRange, vehicleTypeTender, vehicleTypeOps }` | `[ALL]/[ALL]/[ALL]/'ETA'/{startOfMonth..now}/[ALL]/[ALL]` | Committed filter state; drives queryKey of all SQL queries |
| `sqlFilterSettingsOpen` | `boolean` | `false` | Settings dialog open state |
| `filterInitialized` | `boolean` | `true` | Gates initial SQL execution |

Filter changes only commit on `handleFilterApply` (user clicks Apply in `SqlFilterPanel` — `autoApply` is on, so it fires on any field change).

### 3.2 Server state — React Query

| Query key (prefix) | Section keys | staleTime | Notes |
|---|---|---|---|
| `['vfr-sql', dashboardId, widgetId, hasSqlConfig, filterOverrides]` | 12 sections via `Promise.all` | 5 min | Single query batching all chart sections |
| `['vfr-detail-count', dashboardId, widgetId, sectionKey, filterOverrides]` | `detail` / `detailOperation` | 5 min | `countOnly: true` |
| `['vfr-detail-page', dashboardId, widgetId, sectionKey, filterOverrides, page, pageSize]` | `detail` / `detailOperation` | 2 min | `placeholderData: prev` for smooth pagination |

`enabled` for chart batch: `hasSqlConfig && dashboardId && widgetId && filterInitialized`.
`enabled` for detail: `Boolean(sql?.trim())`.

---

## 4. API surface

All SQL execution flows through:

```ts
dashboardV2Api.executeWidget(dashboardId, widgetId, {
  sectionKey: string,           // see §5
  filterOverrides: Record<string, string>,
  countOnly?: boolean,
  page?: number,
  pageSize?: number,
})
// → { rows: Record<string, unknown>[], error?: string }
```

There is **no dedicated VFR REST endpoint** — the entire widget is config-driven. The legacy spec in `05-reference/vfr.spec.md` lists `fetchVfrTenderKpi`, `fetchVfrTenderByArea`, … — those are **stale** and not present in current code.

Backend path: `dashboardV2Api.executeWidget` → backend dashboard widget executor → ClickHouse query against `analytics_workspace.mv_vfr_gui_thau` / `mv_vfr_van_hanh`.

---

## 5. Section key catalog

The Settings dialog binds 14 sections. Widget code reads each via `sqlQueries?.<key>`:

| Section key | Bound at | Returns shape (normalized) |
|---|---|---|
| `kpi` | KPI cards (tender) | `VfrKpiData { avgVfr, lowUnder50Count, medium50To70Count, high70To95Count, excellent95UpCount }` |
| `kpiOperation` | KPI cards (operation) | Same |
| `byArea` / `byAreaOperation` | Area chart | `{ area, planned, vfr }[]` |
| `byVehicle` / `byVehicleOperation` | Vehicle chart | `{ vehicle, registeredCbm, vfr }[]` |
| `byLoadingType` / `byLoadingTypeOperation` | Loading-type chart | `{ period, day?, week?, month?, loadingType, planned, vfr }[]` |
| `byTimeArea` / `byTimeAreaOperation` | Time × Area summary table | `{ period, area, vfr }[]` |
| `detail` / `detailOperation` | Detail grid | `VfrDetailRow[]` (29 fields — see [widget-vfr.tsx:64-97](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L64-L97)) |
| `vehicleTypeTenderOptions` | Filter option list | `{ value, label? }[]` → string[] |
| `vehicleTypeOpsOptions` | Filter option list | Same |

### 5.1 Required columns (validated by Settings dialog)

Pulled from [widget-vfr-settings-dialog.tsx:43-83](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr-settings-dialog.tsx#L43-L83):

```
KPI:           avg_vfr | low_under_50 | medium_50_70 | high_70_95 | excellent_95_up
By Area:       area | planned (or registered_cbm) | vfr
By Vehicle:    vehicle (or vehicle_type) | registered_cbm (or planned) | vfr
Loading Type:  period | loading_type | planned (or registered_cbm) | vfr
Time × Area:   period | area | vfr
Detail:        trip_id | pickup_warehouse | delivery_area | vendor | reg_cbm | act_cbm
```

Optional column aliases (matched case-insensitive in [widget-vfr.tsx:365-447](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L365-L447)):
- `avg_vfr` ← `avgVfr`, `vfr`
- `low_under_50` ← `cnt_vfr_50`, `lowUnder50Count`, `low`
- `vehicle` ← `vehicle_type`, `vehicleType`
- `planned` ← `registered_cbm`, `registeredCbm`
- `act_cbm` ← `actCbm`, `cbm_nhan`, `CBM nhận`
- `trip_id` ← `tripId`, `id_chuyen_gui_thau`, `ID chuyến gửi thầu`
- (29 Vietnamese aliases for detail fields — see `normalizeVfrDetailFromSql`)

---

## 6. Filter override mapping

`filterOverrides` is computed by [widget-vfr.tsx:848-870](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L848-L870):

```ts
{
  whseid:               applied.pickupWarehouse.includes('ALL') ? '' : csv,
  area:                 applied.deliveryArea.includes('ALL')   ? '' : csv,
  transporter:          applied.carrier.includes('ALL')        ? '' : csv,
  date_type:            applied.dateType,                  // 'ETA' | 'ATA'
  from_date:            toYmd(applied.dateRange.from),
  to_date:              toYmd(applied.dateRange.to),
  vehicle_type_tender:  applied.vehicleTypeTender.includes('ALL') ? '' : csv,
  vehicle_type_ops:     applied.vehicleTypeOps.includes('ALL')    ? '' : csv,
}
```

Substituted into SQL via the standard `{{placeholder}}` mechanism in the dashboard widget executor (`WidgetFilterResolver` — backend). Empty string = "do not filter this dimension".

**Canonical SQL pattern** (from `sql-registry.md`):
```sql
WITH params AS (SELECT
  'ALL' AS p_locationfrom,    -- replaced at runtime
  'ALL' AS p_area,
  ...
)
... WHERE
  (p_locationfrom = 'ALL' OR "ten_diem_nhan" = p_locationfrom)
  AND (p_area = 'ALL' OR "khu_vuc_doi_xe" = p_area)
  ...
```

Note: when override is empty string, the backend resolver typically substitutes `'ALL'` (or NULL → `coalesce('ALL')`). See memory `feedback_sql_review_widget_runtime` for the gotcha around CSV expansion.

---

## 7. Derived data (key `useMemo` blocks)

| useMemo | Input | Output | Where |
|---|---|---|---|
| `filterOverrides` | `applied` | filter map | L848 |
| `byAreaChartData` | API rows | rounded `{ area, planned, vfr }` | L1005 |
| `byVehicleChartData` | API rows | rounded `{ vehicle, registeredCbm, vfr }` | L1015 |
| `loadingTypeSeries` | API rows | unique loading-type list | L1025 |
| `byLoadingTypeTenderTrend` | API rows + group-by | `[{ period, <lt>__planned, <lt>__vfr, ... }]` weighted by `planned` | L1034 |
| `timeAreaSeries` / `operationTimeAreaSeries` | API rows | unique area list (fallback to `DELIVERY_AREAS`) | L1112 / L1167 |
| `byTimeAreaTenderTrend` / `byTimeAreaOperationTrend` | API rows | pivoted `[{ period, <area1>: vfr, <area2>: vfr, ... }]` | L1121 / L1176 |
| `timeAreaTableData` / `operationTimeAreaTableData` | pivoted rows | `{ rows, columnAverages, grandAverage }` | L1138 / L1188 |

`roundVfr`: 2 decimal places. `roundCbm`: integer.

---

## 8. Charts — rendering rules

### 8.1 By Area (ComposedChart)
- Bar: `planned` (CBM kế hoạch theo khu vực) on left Y axis, fill `#334155`.
- Line: `vfr` (%) on right Y axis, stroke `#8E59FF`.
- X axis: `area`.

### 8.2 By Vehicle (ComposedChart)
- Bar: `registeredCbm` on left Y axis, fill `#0EA5E9`, rounded corners.
- Line: `vfr` (%) on right Y axis, stroke `#8E59FF`.
- X axis: `vehicle`.

### 8.3 By Loading Type & Time (ComposedChart with multi-series)
- For each loading type:
  - Bar: `<lt>__planned` on left Y axis, color from `CHART_PALETTE[idx]`, rounded corners.
  - Line: `<lt>__vfr` on right Y axis, color from `VFR_LINE_PALETTE[idx]`, `connectNulls`.
- **Exception**: if `loadingType` (lowercased, trimmed) is `'other'` or `'full pallet'`, the planned bar is hidden (only line rendered) — see [widget-vfr.tsx:1587-1599](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L1587-L1599).
- Group-by toggle: day | week | month. Day uses raw `day` field; week derives ISO week from `day` if `week` field missing; month uses `month` or first 7 chars of `day`.

---

## 9. Detail grid

Implementation: `WidgetGrid` shared component, `gridKey = 'DSHVFRDTG01'`.

- 29 columns (see [widget-vfr.columns.ts](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.columns.ts)).
- Server-side pagination: `page` + `pageSize` (10 / 20 / 50) sent in `executeWidget` payload.
- Count query (`countOnly: true`) feeds the pager.
- Export-all: client iterates pages of 5000 up to 50 pages (250k row cap) — see `fetchAllRows` at [widget-vfr-detail.tsx:79-97](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr-detail.tsx#L79-L97).
- Switching mode changes both `sectionKey` and `sql`, triggering query refetch.

---

## 10. Filter panel integration

Uses shared `SqlFilterPanel` with field definitions from `BASE_VFR_FILTER_DEFINITIONS` ([widget-vfr.tsx:149-189](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L149-L189)) + 2 conditional vehicle-type fields ([widget-vfr.tsx:948-983](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L948-L983)).

| Field | `defaultDataType` | `disabled` rule | Fallback options source |
|---|---|---|---|
| `pickup_warehouse` | (warehouse) | — | `PICKUP_WAREHOUSES` const |
| `delivery_area` | (area) | — | `DELIVERY_AREAS` const |
| `vendor` | (vendor) | — | `VENDORS` const |
| `date_type` | `single_select` | — | `['ETA', 'ATA']` |
| `vfrDateRange` | (date range) | — | `MIN(planned_date) / MAX(planned_date)` from object |
| `vehicle_type_tender` | `multi_select` | `mode === 'operation'` | from `vehicleTypeTenderOptions` query |
| `vehicle_type_ops` | `multi_select` | `mode === 'tender'` | from `vehicleTypeOpsOptions` query |

Filter config is persisted to backend via `useFilterConfigSave({ dashboardId, widgetId, parsedConfig })`.

---

## 11. Toolbar actions (edit mode only)

Set via `useWidgetToolbarActions().setActions(...)` at [widget-vfr.tsx:1217-1240](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L1217-L1240):

1. **Setting Chart** button → opens `WidgetVfrSettingsDialog` (14 SQL sections).
2. **Setting Filter** button → opens `SqlFilterPanel` settings mode (amber-colored).

---

## 12. i18n keys (namespace `dashboard`)

All UI text reads from `orderMonitor.vfr.*` and `orderMonitor.common.*`. Key inventory:

```
orderMonitor.vfr.modeTender       → "VFR theo Chuyến thầu"
orderMonitor.vfr.modeOperation    → "VFR theo Chuyến vận hành"
orderMonitor.vfr.avgVfr / .low / .medium / .high / .excellent (+ *Desc)
orderMonitor.vfr.registeredCbm    → "Registered CBM"
orderMonitor.vfr.vfrPct           → "VFR %"
orderMonitor.vfr.detailTable      → "Chi tiết bảng"
orderMonitor.vfr.tenderLens / .operationLens
orderMonitor.vfr.colTrip / .colTripOps / .colOrderCode / ... (29 column labels)
orderMonitor.common.chart / .detail
```

Locale files:
- [frontend/src/i18n/locales/vi/dashboard-order-monitor.json](frontend/src/i18n/locales/vi/dashboard-order-monitor.json)
- [frontend/src/i18n/locales/en/dashboard-order-monitor.json](frontend/src/i18n/locales/en/dashboard-order-monitor.json)
- [frontend/src/i18n/locales/vi/dashboard-templates.json](frontend/src/i18n/locales/vi/dashboard-templates.json) — preset card title/description

---

## 13. Tooltips / explainers

Tooltip text constants at [widget-vfr.tsx:191-307](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L191-L307):

- `VFR_FORMULA` — Loose+FP weighted formula (see PRD §3.4).
- `VFR_NOTE` — explains 8 sub-metrics: Loose_khối_fill, Loose_khối_mix, Loose_tấn_fill, Loose_tấn_mix, FP_khối_fill, FP_khối_mix, FP_tấn_fill, FP_tấn_mix.
- `VFR_TENDER_HINTS` — 7 keys: avgVfr, low, medium, high, excellent, byArea, byVehicle, byLoadingType, byTimeArea.
- `VFR_OPERATION_HINTS` — same shape, "vận hành" wording.

> Drift detected: `VFR_OPERATION_HINTS.low/medium/high/excellent` still reference "chuyến gửi thầu (Max)" inside the formula text (copy-paste from tender hints) — see trace report §D-i18n-1.

---

## 14. Workflow flows

### 14.1 Page load
1. Read `parsedConfig` from `config` prop → `dataSourceId`, `queries`, filter SQL configs.
2. Initialize `applied` state to `[ALL]/[ALL]/[ALL]/ETA/{startOfMonth..today}/[ALL]/[ALL]`.
3. `filterInitialized = true` → triggers main `useQuery` to fire 12 parallel `executeWidget` calls (10 chart sections + 2 vehicle-type option queries).
4. Detail query is gated on `Boolean(sql?.trim())` and runs only when user opens Detail tab.
5. While loading: show 1 large skeleton header + 5 KPI skeletons + body skeleton.

### 14.2 Filter apply
1. User edits any field in `SqlFilterPanel` → with `autoApply` on, `handleFilterApply(values)` fires.
2. `applied` state mutates → `filterOverrides` memo recomputes → all queries refetch (new queryKey).
3. UI re-renders KPI cards, charts, tables; pagination resets to page 1 (handled by `useState` in detail panel keyed by `filterOverrides`).

### 14.3 Mode toggle (tender ↔ operation)
1. User clicks Mode toggle → `setMode('tender' | 'operation')`.
2. `tenderKpiApi`, `byAreaApi`, etc. branch on `mode` → render switches to operation series.
3. Tooltip text source switches to `VFR_OPERATION_HINTS` / `VFR_TENDER_HINTS`.
4. Detail tab `sql` and `sectionKey` switch → detail query refetches.

### 14.4 Settings change (admin)
1. Admin clicks "Setting Chart" → `WidgetVfrSettingsDialog` opens.
2. Edits SQL for any of 14 sections; validation runs `requiredColumns` check inline.
3. Save → `useUpdateV2Widget(dashboardId, widgetId).mutate({ config: JSON.stringify(next) })`.
4. On success, parent re-renders with new `config` → `parsedConfig` memo invalidates → main `useQuery` queryKey changes (`hasSqlConfig` may flip) → re-fetch.

### 14.5 Error handling
- `executeWidget` returns `{ error, rows: [] }` on failure → `exec()` helper returns `[]` so downstream normalizer sees empty array → chart renders empty state.
- No toast / banner currently — silent degradation. Open question for UX team.

---

## 15. Performance characteristics

- 12 SQL queries fired in parallel on each filter change. ClickHouse MVs are pre-aggregated, so per-query latency is typically <500ms.
- React Query `staleTime: 5min` for chart batch and count; `2min` for detail page. Mode toggle doesn't re-fetch chart batch (data is already there for both modes; only render differs).
- Export-all worst case: 50 × 5000 row pages × ~3KB/row ≈ 750MB JSON → use sparingly.

---

## 16. Known gaps / TODOs

| # | Gap | Note |
|---|---|---|
| 1 | Date range >12 months not validated | PRD §13.10 — see PRD drift D5 |
| 2 | `VFR > 100%` not clamped | PRD §13.3 — see PRD drift D4 |
| 3 | `loadingType=''` rows are dropped | PRD §13.9 wants "Không xác định" bucket — see PRD drift D7 |
| 4 | Late-alert correlation missing | Branch name `feat-vfr-late-alert` implies a cross-widget signal not yet implemented — see PRD §13 |
| 5 | `VFR_OPERATION_HINTS` text references "gửi thầu" in low/medium/high/excellent formulas | Copy-paste artifact — see trace report |
| 6 | No error banner when `executeWidget` fails | Silent empty-state only |
| 7 | No retry button for failed queries | User must change filter to re-trigger |

---

## 17. Test coverage

Only one test file: [__tests__/widget-vfr.columns.test.ts](frontend/src/features/dashboard/components/widgets/order-monitor/__tests__/widget-vfr.columns.test.ts) — 24 lines, checks column key stability.

**No tests** for:
- `normalizeVfrDetailFromSql` field mapping (29 fields × multiple aliases)
- `byLoadingTypeTenderTrend` weighted aggregation
- `timeAreaTableData` averaging
- Filter override CSV expansion
- Mode toggle state transitions

Recommend `/tester` add fixture-based tests for the normalizers (high churn area, alias matrix is brittle).

---

## 22. Canonical SQL — admin paste source (Phase 3 By Vendor)

> **Audience:** Mondelez tenant admin. Paste the SQL below into Settings → "By Vendor (Thầu)" / "By Vendor (Vận hành)" via the widget Settings dialog.
>
> **Pattern alignment:** ClickHouse `analytics_workspace` MV with params CTE, `mv_filter_*` membership probe for multi-select, `coalesce({{from_date}}, …)` outside CTE (avoids the WidgetFilterResolver CSV-expansion anti-pattern documented in memory `feedback_sql_review_widget_runtime`). Mirrors `byArea` shape (sql-registry.md §vfr tender / vfr operation) — only the grouping column changes from `khu_vuc_doi_xe` → `nha_van_tai`.
>
> **FE column contract:** widget code reads `vendor` / `planned` / `vfr` (via `normalizeVfrByVendorFromSql`). The canonical SQL aliases output columns to match. If admin uses a hand-rolled query, the same aliases must be preserved.

### 22.1 `byVendor` — VFR by Vendor (tender mode)

```sql
WITH base AS (
    SELECT
        t.nha_van_tai AS nha_van_tai,
        SUM(t.cbm_ke_hoach) AS total_cbm_ke_hoach,
        SUM(t.cbm_nhan)      AS total_cbm_nhan,

        /* Loose */
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse'), t.cbm_nhan, 0)) AS loose_cbm_nhan,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Khối', t.cbm_nhan, 0)) AS loose_khoi_cbm_nhan,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Khối', toFloat64OrZero(t.cbm_dang_ky), 0)) AS loose_khoi_cbm_dk,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn',  t.tan_nhan, 0)) AS loose_tan_nhan,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn',  toFloat64OrZero(t.tan_dang_ky), 0)) AS loose_tan_dk,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn',  t.cbm_nhan, 0)) AS loose_tan_cbm_nhan,

        /* Full Pallet */
        SUM(IF(t.loai_boc_xep = 'Full Pallet', t.cbm_nhan, 0)) AS fp_cbm_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Khối', t.cbm_nhan, 0)) AS fp_khoi_cbm_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Khối', toFloat64OrZero(t.cbm_dang_ky), 0)) AS fp_khoi_cbm_dk,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn',  t.tan_nhan, 0)) AS fp_tan_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn',  toFloat64OrZero(t.tan_dang_ky), 0)) AS fp_tan_dk,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn',  t.cbm_nhan, 0)) AS fp_tan_cbm_nhan
    FROM analytics_workspace.mv_vfr_gui_thau t
    WHERE 1 = 1

    -- Warehouse
    AND (coalesce({{whseid}}, 'ALL') = 'ALL' OR t.ma_diem_nhan IN ({{whseid}}))

    -- Area
    AND (coalesce({{area}}, 'ALL') = 'ALL' OR t.khu_vuc_doi_xe IN ({{area}}))

    -- Transporter
    AND (coalesce({{transporter}}, 'ALL') = 'ALL' OR t.nha_van_tai IN ({{transporter}}))

    -- Vehicle_type_tender
    AND (coalesce({{vehicle_type_tender}}, 'ALL') = 'ALL' OR t.ma_loai_xe_gui_thau IN ({{vehicle_type_tender}}))

    -- Date filter
    AND (
        toDate(
            CASE
                WHEN {{date_type}} = 'ETA' THEN t.eta_vh
                WHEN {{date_type}} = 'ATA' THEN t.ata_vh
                WHEN {{date_type}} = 'Ngày gửi thầu' THEN t.tender_date
            END
        ) BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
              AND toDate(coalesce({{to_date}},   '2999-12-31'))
    )
    GROUP BY t.nha_van_tai
),
calc AS (
    SELECT
        nha_van_tai,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        if(total_cbm_nhan = 0, 0, loose_cbm_nhan / total_cbm_nhan) AS loose_weight,
        if(total_cbm_nhan = 0, 0, fp_cbm_nhan    / total_cbm_nhan) AS fp_weight,
        if(loose_khoi_cbm_dk = 0, 0, loose_khoi_cbm_nhan / loose_khoi_cbm_dk) AS loose_khoi_fill_rate,
        if(loose_cbm_nhan    = 0, 0, loose_khoi_cbm_nhan / loose_cbm_nhan)    AS loose_khoi_mix_rate,
        if(loose_tan_dk      = 0, 0, loose_tan_nhan      / loose_tan_dk)      AS loose_tan_fill_rate,
        if(loose_cbm_nhan    = 0, 0, loose_tan_cbm_nhan  / loose_cbm_nhan)    AS loose_tan_mix_rate,
        if(fp_khoi_cbm_dk = 0, 0, fp_khoi_cbm_nhan / fp_khoi_cbm_dk) AS fp_khoi_fill_rate,
        if(fp_cbm_nhan    = 0, 0, fp_khoi_cbm_nhan / fp_cbm_nhan)    AS fp_khoi_mix_rate,
        if(fp_tan_dk      = 0, 0, fp_tan_nhan      / fp_tan_dk)      AS fp_tan_fill_rate,
        if(fp_cbm_nhan    = 0, 0, fp_tan_cbm_nhan  / fp_cbm_nhan)    AS fp_tan_mix_rate
    FROM base
)
SELECT
    nha_van_tai          AS vendor,
    total_cbm_ke_hoach   AS planned,
    round(
        least(
            1.0,
            (
                (loose_khoi_fill_rate * loose_khoi_mix_rate + loose_tan_fill_rate * loose_tan_mix_rate) * loose_weight
                +
                (fp_khoi_fill_rate    * fp_khoi_mix_rate    + fp_tan_fill_rate    * fp_tan_mix_rate)    * fp_weight
            )
        ) * 100,
        2
    ) AS vfr
FROM calc
WHERE nha_van_tai != ''
ORDER BY vfr ASC;
```

**Notes:**
- `ORDER BY vfr ASC` puts under-target carriers first — chart 4 is "carriers below target". FE also sorts client-side, but DB-side ordering keeps the export consistent.
- `WHERE nha_van_tai != ''` drops blank-vendor rows. Empty string carriers are masterdata gaps, not legitimate buckets.
- `{{transporter}}` membership probe via `mv_filter_vendor` follows sql-registry.md §vfr tender canonical pattern. Hand-rolled `(coalesce({{transporter}}, 'ALL') = 'ALL' OR …)` is the documented anti-pattern (CSV expansion through `WidgetFilterResolver` produces `'A,B,C'` not array literals).

### 22.2 `byVendorOperation` — VFR by Vendor (operation mode)

Identical to `byVendor` with two changes:

1. `FROM analytics_workspace.mv_vfr_gui_thau t` → `FROM analytics_workspace.mv_vfr_van_hanh t`
2. Vehicle-type filter switches from `vehicle_type_tender` → `vehicle_type_ops`:

```sql
-- Vehicle_type_ops (replaces the Vehicle_type_tender block)
AND (coalesce({{vehicle_type_ops}}, 'ALL') = 'ALL' OR t.ma_loai_xe_van_hanh IN ({{vehicle_type_ops}}))
```

All other CTE structure, filter blocks, and SELECT shape stay the same.

### 22.3 Output schema

| Column | Type | Source | FE alias matrix |
|---|---|---|---|
| `vendor` | String | `nha_van_tai` | `['vendor', 'nha_van_tai']` |
| `planned` | Float64 | `total_cbm_ke_hoach` | `['planned', 'registered_cbm', 'registeredCbm']` |
| `vfr` | Float64 (0–100) | computed VFR ratio | `['vfr']` |

If admin paste deviates, the widget's `normalizeVfrByVendorFromSql` falls back through the alias matrix — column name `nha_van_tai` will also resolve, but using the canonical `AS vendor` keeps the SQL self-documenting.

