# Spec — psv-accuracy-vrp

> **Section:** `psv-accuracy-vrp`
> **Tenant:** Panasonic
> **Data source:** `analytics_workspace.mv_psv_main` (ClickHouse cluster, refresh 1h, UTC+7)
> **Audit source:** `analytics_workspace.psv_target FINAL` (`is_deleted=0 AND data_report=true`)
> **Author:** /da-storytelling-data → packaged for /ba → /planner
> **Date:** 2026-05-21 (revised — added 5 raw data table contracts for tab layout)
> **Status:** DRAFT — SQL pattern hoàn chỉnh cho 5 ship-now charts + 5 raw data tables (T-CONSTRAINT ship-ready, T-PLANNER ship-ready với fallback A4, còn lại pending PRD §8 Q1/Q2)
> **Related:** [prd](psv-accuracy-vrp-prd.md) · [wireframe](psv-accuracy-vrp-wireframe.md) · [storytelling notes](analysis/storytelling-notes.md)
> **SQL deployment:** SQL canonical sống trong file này (§4) → admin paste runtime qua widget Settings dialog. **KHÔNG** embed default SQL vào widget FE code (memory rule).

---

## 1. Data Source Overview

### 1.1 Primary binding — `mv_psv_main`

| Property | Value |
|---|---|
| Cluster | `ghrx9lirdl.ap-southeast-1.aws.clickhouse.cloud` (ClickHouse Cloud, ap-southeast-1) |
| Database | `analytics_workspace` |
| Table | `mv_psv_main` (refreshable MaterializedView) |
| Engine | `SharedMergeTree` |
| Refresh cadence | `REFRESH EVERY 1 HOUR` |
| Source | `psv_target FINAL` where `is_deleted = 0 AND data_report = true` |
| Timezone | UTC+7 (Asia/Ho_Chi_Minh) — đã shift, KHÔNG cộng thêm `+ toIntervalHour(7)` |
| Sentinel | `1970-01-01 07:00:00` đã nullified → tất cả `NULL` thực sự là NULL |
| Grain | 1 row = 1 (`tracking_id`, `order_code`). 1 trip có thể có nhiều order rows |
| Min `created_date` | 2025-09-04 10:08 (UTC+7) |
| ORDER BY | `(tracking_id, order_code)` |

### 1.2 Audit source — `psv_target FINAL`

Dùng để **verify số liệu lệch ≤ 1%** giữa widget render và canonical store. Pattern audit:

```sql
SELECT count(), uniqExact(tracking_id), sum(total_cost)
FROM analytics_workspace.psv_target FINAL
WHERE is_deleted = 0
  AND data_report = true
  AND created_date BETWEEN {{date_from}} - INTERVAL 7 HOUR AND {{date_to}} - INTERVAL 7 HOUR;
```

**Lưu ý timezone:** `psv_target` stored UTC; query so sánh với UI date (UTC+7) phải shift `- 7 hour` ở filter.

### 1.3 KHÔNG dùng `mv_psv` legacy

`analytics_workspace.mv_psv` là pipeline song song refresh 30min với schema khác (tracking_id String, thiếu các derived columns). **Toàn bộ section `psv-accuracy-vrp` BIND `mv_psv_main` ONLY** (memory: project_panasonic_psv_pipeline).

---

## 2. Filter Context (section-level)

Filter applied chung cho mọi chart trong section trừ khi note khác:

| Filter | Column / value | Default | Notes |
|---|---|---|---|
| `date_from`, `date_to` | `created_date BETWEEN ...` | Current calendar month | Range picker với preset 7d/30d/MTD/QTD/custom |
| `planner` | `created_by IN (...)` | All | Multi-select; default exclude test accounts `@gosmartlog.com` |
| `zone` | derived → `panasonic_zone_master.zone` | All | **Pending Q2** — disable filter cho đến khi có master |
| Include test accounts | toggle | Off | Khi On → bao gồm `*@gosmartlog.com` |

**Built-in filter của `mv_psv_main`** (KHÔNG cần lặp trong WHERE):
- `is_deleted = 0`
- `data_report = true`

---

## 3. Per-Chart Data Contract

Mỗi entry sau gồm: dimension columns, measure formula, grain, status (ship-ready / GAP).

### Group A — Overall Accuracy

#### A1. % Accuracy KPI

| Field | Spec |
|---|---|
| Grain | per `tracking_id` (uniqExact) |
| Dimensions | none — single KPI |
| Numerator | trips with `is_trip_edit_manual = 0` **OR** (`is_trip_edit_manual = 1 AND constraint_name != ''`) |
| Denominator | `uniqExact(tracking_id)` total |
| Status | 🟢 Ship-ready |
| Caveat | Q7 — "Change with violation also counted as accurate" là counter-intuitive; cần Panasonic confirm |
| Caveat | Q8 — chuyến chỉ đổi vendor do thiếu xe nên count thế nào (chưa derive được từ `mv_psv_main`) |

#### A2. Accuracy Rate by Zone

| Field | Spec |
|---|---|
| Grain | per (`zone`, `tracking_id`) |
| Dimensions | `zone` (derived qua JOIN `panasonic_zone_master` — Q2) |
| Measure | same A1 formula, GROUP BY zone |
| Status | 🟡 Pending Q2 |
| Edge | Hide zones với `n < 10` trips; bucket "Unknown" cho `location_to_code` không match master |

#### A3. Cost per CBM Trend (daily)

| Field | Spec |
|---|---|
| Grain | per day |
| Dimensions | `toDate(created_date)` |
| Measure | `(cpc_adjusted − cpc_auto) / cpc_auto` per day, where `cpc = SUM(total_cost) / SUM(total_cbm)` |
| Status | 🔴 GAP — pending Q1 (need `total_cost_auto`, `total_cbm_auto` columns) |
| Fallback | If Q1=No → Option A version pivot (`psv_target` MIN/MAX version per `tracking_id`) → join into per-day aggregate |

#### A4. Process Efficiency — AVG Adj Duration only (v1)

| Field | Spec |
|---|---|
| Grain | per (`created_by`, `tracking_id`) |
| Dimensions | `created_by` (planner) |
| Measure (Adj Duration min) | `AVG(dateDiff('minute', created_date, report_modified_date))` for `is_trip_edit_manual = 1 AND report_modified_date IS NOT NULL` |
| Status | 🟢 Ship-ready (fallback formula vs PM ideal event-log formula) |
| Defer | AVG Preparation (drop), AVG Final Leadtime (defer to `psv-adoption-vrp` pending Q3) |

### Group B — Post-Adjustment Violation

#### B1. Constraint Violation Rate KPI

| Field | Spec |
|---|---|
| Grain | per `tracking_id` |
| Dimensions | none |
| Numerator | trips with `max(constraint_name != '')` per `tracking_id` |
| Denominator | `uniqExact(tracking_id)` |
| Status | 🟢 Ship-ready |
| Edge | `constraint_name` CSV ("Fishbone, M…") tính là 1 trip violated (KHÔNG splitByChar trong B1) |

#### B2. Violation Rate by Zone

| Field | Spec |
|---|---|
| Grain | per (`zone`, `tracking_id`) |
| Dimensions | `zone` (Q2) |
| Measure | same B1 GROUP BY zone |
| Status | 🟡 Pending Q2 |

#### B3. Violation Count by Category

| Field | Spec |
|---|---|
| Grain | per (`violation_type`, row) — splitByChar applied |
| Dimensions | `arrayJoin(splitByChar(',', constraint_name))` trimmed |
| Measure | `count()` per category |
| Status | 🟢 Ship-ready |
| Caveat | 1 trip với "Fishbone, 3D_loading" → +1 cho "Fishbone" AND +1 cho "3D_loading" (count per violation, không per trip) |
| Output limit | Top 20 + bucket "Others" |

#### B4. Daily Violation Trend

| Field | Spec |
|---|---|
| Grain | per day, per `tracking_id` (dedupe) |
| Dimensions | `toDate(created_date)` |
| Measure | `countIf(any constraint_name != '')` per trip per day |
| Status | 🟢 Ship-ready |
| Edge | Show 0 (KHÔNG gap) cho ngày không có violation |
| Resample | Auto switch sang weekly nếu range > 90 ngày |

### Group C — Vendor & Operation Impact

⚠️ **Toàn bộ Group C pending Q1** (Auto baseline). Status = 🔴 GAP cho tất cả charts.

#### C1. Trip Change Matrix (carrier_old × carrier_new)

| Field | Spec |
|---|---|
| Grain | per `tracking_id` |
| Dimensions | (`vendor_name_auto`, `vendor_name_adjusted`) — pivot matrix |
| Measure | `count(tracking_id)` per cell |
| Status | 🔴 GAP Q1 |
| Filter | only trips with `vendor_name_auto != vendor_name_adjusted` (loại diagonal) |

#### C2. Vendor Allocation Ratio (Auto vs Adjusted)

| Field | Spec |
|---|---|
| Grain | per vendor, per data_source (Auto/Adjusted) |
| Dimensions | `vendor_name`, `data_source` |
| Measure | `uniqExact(tracking_id) / total_trips * 100` per (vendor, source) |
| Status | 🔴 GAP Q1 |

#### C3. Vendor Allocation by Zone

| Field | Spec |
|---|---|
| Grain | per (zone, vendor, source) |
| Status | 🔴 GAP Q1 + Q2 (double dep) |

#### C4. Cost Impact by Vendor

| Field | Spec |
|---|---|
| Grain | per vendor |
| Measure 1 (Original Fee VND) | `SUM(total_cost_auto)` per vendor |
| Measure 2 (Actual Fee VND) | `SUM(total_cost)` per vendor |
| Measure 3 (Cost Variation) | `Actual - Original` |
| Measure 4 (%Drift Cost/CBM) | `(cpc_adj - cpc_auto) / cpc_auto` per vendor |
| Status | 🔴 GAP Q1 |
| Vendor selection rule | GROUP BY `vendor_name` ADJUSTED (vendor cuối chịu chi phí thực tế) |

#### C5. % Change Vendor by Zone (pivot)

| Field | Spec |
|---|---|
| Grain | per (vendor, zone) |
| Dimensions | `vendor_name`, `zone` |
| Measure | `(trip_adj - trip_auto) / trip_auto * 100` per cell |
| Status | 🔴 GAP Q1 + Q2 |
| Outlier rule | n < 5 trips Auto → grey out cell |

### Group D — Adjusted vs Auto by Zone

⚠️ Cả Group D pending Q1 (Auto baseline). 4/6 charts cũng pending Q2 (zone master).

#### D1. Summary Comparison Table (2 rows × 4 cols)

| Field | Spec |
|---|---|
| Grain | total across window |
| Dimensions | `data_source ∈ {Auto, Adjusted}` |
| Measures | `total_cbm`, `uniqExact(tracking_id)`, `total_fee`, `cost_per_cbm` |
| Status | 🔴 GAP Q1 |
| UI enhancement | Thêm 2 cột Δ và % diff (PRD §6.G-Storytelling) |

#### D2. Trip Variation by Zone (diverging bar %)

| Field | Spec |
|---|---|
| Grain | per zone |
| Measure | `(trip_adj_zone - trip_auto_zone) / trip_auto_zone * 100` |
| Status | 🔴 GAP Q1 + Q2 |

#### D3. Total Saving/Loss by Zone (diverging bar VND)

| Field | Spec |
|---|---|
| Grain | per zone |
| Measure | `SUM(total_cost_auto_zone) - SUM(total_cost_zone)` |
| Status | 🔴 GAP Q1 + Q2 |
| Unit | Pending Q6 — VND / thousand VND / million VND |

#### D4. Cost % Diff by Zone (diverging bar)

| Field | Spec |
|---|---|
| Grain | per zone |
| Measure | `(cpc_adj_zone - cpc_auto_zone) / cpc_auto_zone * 100` |
| Status | 🔴 GAP Q1 + Q2 |

#### D5. Cost Efficiency Bubble (Zone + Vendor)

| Field | Spec |
|---|---|
| Grain (Zone bubble) | per zone |
| Grain (Vendor bubble) | per vendor |
| X | `SUM(total_cbm)` |
| Y | `SUM(total_cost) / SUM(total_cbm)` = cost per CBM |
| Bubble size | `uniqExact(tracking_id)` — Adjusted (KHÔNG Auto như PDF — Adjusted ship-ready, Auto pending Q1) |
| Status (Vendor) | 🟢 Ship-ready (vendor không cần zone master) |
| Status (Zone) | 🟡 Pending Q2 |

#### D6. Summary Metrics by Prov (heatmap table)

| Field | Spec |
|---|---|
| Grain | per zone |
| Dimensions | `zone`, `data_source` |
| Measures | 4 columns × 2 source (cbm, trip, fee, cpc) |
| Status | 🔴 GAP Q1 + Q2 |

### Group E — Raw Data Tables (added 2026-05-21 for tab layout)

5 raw tables ship với 5-tab wireframe. Mỗi table = exportable CSV/XLSX, sortable, search, pagination. Filter section-level (date/planner/zone) **luôn apply**; filter local-per-table cho phép user narrow thêm.

#### E1. T-CONSTRAINT — Constraint Violation Trip Log (Tab 2)

| Field | Spec |
|---|---|
| Tab | Reliability (Tab 2) |
| Grain | 1 row = 1 trip có ít nhất 1 constraint violation |
| Dimensions | `tracking_id`, `created_date`, `planner_name`, `zone`, `location_to_name`, `vendor_name`, `carrier_name` |
| Measures | `constraint_violations` (CSV preserved), `reason_change`, `total_cost_adjusted` |
| Status | 🟢 Ship-ready (zone column dùng Q2 fallback 'Unknown') |
| Default sort | `created_date DESC` |
| Pagination | Server-side, 50 rows/page default |
| Filter | section filter + local search across `tracking_id` + `constraint_name` |
| Edge | Drop trips với `constraint_name = ''` (chỉ list trips có violation) |

#### E2. T-VENDOR — Vendor Swap Detail (Tab 3)

| Field | Spec |
|---|---|
| Tab | Vendor & Carrier (Tab 3) |
| Grain | 1 row = 1 trip (với cả Auto + Adj measure) |
| Dimensions | `tracking_id`, `zone`, `vendor_auto`, `vendor_adjusted`, `carrier_auto`, `carrier_adjusted` |
| Measures | `cost_auto`, `cost_adjusted`, `cost_delta_vnd`, `pct_drift`, `total_cbm`, `reason_change`, `created_date` |
| Status | 🔴 GAP Q1 (Auto baseline) + Q2 (zone bucket 'Unknown' if no master) |
| Default sort | `cost_delta_vnd DESC` (top overspend first) |
| Pagination | Server-side, 50 rows/page default |
| Filter | section filter + local vendor multi-select inline |
| Edge | Bao gồm cả trips no-change (vendor_auto == vendor_adj) để user có full data export |

#### E3. T-ZONE-COST — Zone-Level Cost Variance (Tab 4)

| Field | Spec |
|---|---|
| Tab | Cost Variance (Tab 4) |
| Grain | 1 row = 1 zone (aggregated) |
| Dimensions | `zone` |
| Measures | `trip_count_auto`, `trip_count_adj`, `total_cost_auto`, `total_cost_adj`, `cost_delta_vnd`, `pct_diff`, `total_cbm_auto`, `total_cbm_adj`, `cpc_auto`, `cpc_adj`, `cpc_drift_pct` |
| Status | 🔴 GAP Q1 + Q2 |
| Default sort | `cost_delta_vnd DESC` |
| Pagination | Client-side (zones ≤ 20 expected) |
| Edge | Filter `HAVING trip_count_adj >= 10` (n-low rule); zone 'Unknown' bucket cho location_to không match master |

#### E4. T-MASTER — Trip Master (Tab 5)

| Field | Spec |
|---|---|
| Tab | Data Explorer (Tab 5) |
| Grain | 1 row = 1 trip (`tracking_id`) |
| Dimensions (10) | `tracking_id`, `created_date`, `planner_name`, `zone`, `region`, `location_from_name`, `location_to_name`, `vendor_auto`, `vendor_adj`, `carrier_auto`, `carrier_adj`, `status_name_detail`, `reason_change` |
| Measures (11) | `total_cost_auto`, `total_cost_adj`, `cost_delta_vnd`, `pct_drift`, `total_cbm_auto`, `total_cbm_adj`, `cpc_auto`, `cpc_adj`, `constraint_violations_count`, `constraint_names_list` |
| Status | 🟡 Partial — Adjusted measures ship-ready; Auto measures GAP Q1 (show empty col + tooltip "Pending Q1" nếu Option B chưa deploy) |
| Default sort | `created_date DESC` |
| Pagination | **Server-side mandatory** (potentially > 10k rows) |
| Default visible cols | 18/24 — hide `location_from_name`, `carrier_auto`, `carrier_adj`, `constraint_names_list`, `cpc_auto`, `cpc_adj` (wireframe §6 D4) |
| Export limit | XLSX 50k rows / CSV 200k rows. Beyond → block + caption "narrow filter" |

#### E5. T-PLANNER — Per-Planner Activity (Tab 5)

| Field | Spec |
|---|---|
| Tab | Data Explorer (Tab 5) |
| Grain | 1 row = 1 planner |
| Dimensions | `planner_name`, `is_active_last_7d` |
| Measures | `total_trips`, `no_change_trips`, `edited_trips`, `pct_change`, `avg_adj_duration_min`, `first_seen`, `last_seen` |
| Status | 🟢 Ship-ready (extends A4 fallback formula) |
| Default sort | `total_trips DESC` |
| Pagination | Client-side (planners ≤ 50 expected) |
| Edge | `avg_adj_duration_min` = NULL khi planner không có edited trips (display `—`) |

---

## 4. SQL Canonical Patterns

> **Convention**: mỗi pattern này là **source-of-truth SQL** cho 1 chart. Khi widget go-live, admin paste vào widget Settings dialog. Đăng ký pattern vào `docs/shared/sql-registry.md` (memory rule) — section `panasonic/psv-accuracy-vrp`.
> Placeholders `{{date_from}}`, `{{date_to}}`, `{{planner_list}}` được resolve bởi WidgetFilterResolver tại runtime.

### 4.1 A1 — % Accuracy KPI

```sql
WITH trip_level AS (
    SELECT
        tracking_id,
        any(is_trip_edit_manual)            AS edited,
        max(constraint_name != '')          AS has_violation
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= {{date_from}}
      AND created_date <  {{date_to}}
      AND created_by IN ({{planner_list}})
    GROUP BY tracking_id
)
SELECT
    countIf(edited = 0)                                       AS no_change_trips,
    countIf(edited = 1 AND has_violation = 1)                 AS change_with_violation_trips,
    count()                                                   AS total_trips,
    round(
        (countIf(edited = 0) + countIf(edited = 1 AND has_violation = 1)) * 100.0
        / nullIf(count(), 0)
    , 1)                                                      AS pct_accuracy
FROM trip_level;
```

### 4.2 A2 — Accuracy Rate by Zone

```sql
WITH trip_level AS (
    SELECT
        tracking_id,
        any(location_to_code)               AS location_to_code,
        any(is_trip_edit_manual)            AS edited,
        max(constraint_name != '')          AS has_violation
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= {{date_from}}
      AND created_date <  {{date_to}}
      AND created_by IN ({{planner_list}})
    GROUP BY tracking_id
)
SELECT
    coalesce(z.zone, 'Unknown')                               AS zone,
    count()                                                   AS total_trips,
    countIf(t.edited = 0) + countIf(t.edited = 1 AND t.has_violation = 1)
                                                              AS accurate_trips,
    round(accurate_trips * 100.0 / nullIf(total_trips, 0), 1) AS pct_accuracy
FROM trip_level AS t
LEFT JOIN analytics_workspace.panasonic_zone_master AS z
    ON z.location_to_code = t.location_to_code
GROUP BY zone
HAVING total_trips >= 10
ORDER BY pct_accuracy DESC;
```

### 4.3 A3 — Cost per CBM Trend

```sql
SELECT
    toDate(created_date)                                      AS day,
    SUM(total_cost)        / nullIf(SUM(total_cbm), 0)        AS cpc_adjusted,
    SUM(total_cost_auto)   / nullIf(SUM(total_cbm_auto), 0)   AS cpc_auto,
    round(
        (cpc_adjusted - cpc_auto) * 100.0 / nullIf(cpc_auto, 0)
    , 2)                                                      AS pct_diff_cpc
FROM analytics_workspace.mv_psv_main
WHERE created_date >= {{date_from}}
  AND created_date <  {{date_to}}
  AND created_by IN ({{planner_list}})
GROUP BY day
ORDER BY day;
```

> Requires `total_cost_auto`, `total_cbm_auto` columns added by Option B (pending Q1). Option A alternative pattern: see §4.A.alt.

### 4.4 A4 — AVG Adj Duration (v1 fallback)

```sql
WITH trip_level AS (
    SELECT
        tracking_id,
        any(created_by)                     AS created_by,
        any(created_date)                   AS run_start,
        any(report_modified_date)           AS final_save,
        max(is_trip_edit_manual)            AS edited
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= {{date_from}}
      AND created_date <  {{date_to}}
      AND created_by IN ({{planner_list}})
    GROUP BY tracking_id
)
SELECT
    created_by,
    count()                                                   AS total_trips,
    countIf(edited = 1)                                       AS edited_trips,
    avgIf(
        dateDiff('minute', run_start, final_save),
        edited = 1 AND final_save IS NOT NULL
    )                                                         AS avg_adj_duration_min
FROM trip_level
GROUP BY created_by
ORDER BY total_trips DESC;
```

### 4.5 B1 — Constraint Violation Rate KPI

```sql
WITH trip_level AS (
    SELECT
        tracking_id,
        max(constraint_name != '')          AS has_violation
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= {{date_from}}
      AND created_date <  {{date_to}}
      AND created_by IN ({{planner_list}})
    GROUP BY tracking_id
)
SELECT
    count()                                                   AS total_trips,
    countIf(has_violation = 1)                                AS violated_trips,
    round(countIf(has_violation = 1) * 100.0 / nullIf(count(), 0), 1)
                                                              AS pct_violation
FROM trip_level;
```

### 4.6 B2 — Violation Rate by Zone

```sql
WITH trip_level AS (
    SELECT
        tracking_id,
        any(location_to_code)               AS location_to_code,
        max(constraint_name != '')          AS has_violation
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= {{date_from}}
      AND created_date <  {{date_to}}
      AND created_by IN ({{planner_list}})
    GROUP BY tracking_id
)
SELECT
    coalesce(z.zone, 'Unknown')                               AS zone,
    count()                                                   AS total_trips,
    countIf(t.has_violation = 1)                              AS violated_trips,
    round(violated_trips * 100.0 / nullIf(total_trips, 0), 1) AS pct_violation
FROM trip_level AS t
LEFT JOIN analytics_workspace.panasonic_zone_master AS z
    ON z.location_to_code = t.location_to_code
GROUP BY zone
HAVING total_trips >= 10
ORDER BY pct_violation DESC;
```

### 4.7 B3 — Violation Count by Category

```sql
SELECT
    trim(violation_type)                                      AS constraint_violation,
    count()                                                   AS record_count
FROM analytics_workspace.mv_psv_main
ARRAY JOIN splitByChar(',', constraint_name) AS violation_type
WHERE created_date >= {{date_from}}
  AND created_date <  {{date_to}}
  AND created_by IN ({{planner_list}})
  AND constraint_name != ''
GROUP BY constraint_violation
HAVING constraint_violation != ''
ORDER BY record_count DESC
LIMIT 20;
```

### 4.8 B4 — Daily Violation Trend

```sql
WITH trip_level AS (
    SELECT
        tracking_id,
        toDate(any(created_date))           AS day,
        max(constraint_name != '')          AS has_violation
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= {{date_from}}
      AND created_date <  {{date_to}}
      AND created_by IN ({{planner_list}})
    GROUP BY tracking_id
)
SELECT
    day,
    count()                                                   AS total_trips,
    countIf(has_violation = 1)                                AS violated_trips
FROM trip_level
GROUP BY day
ORDER BY day;
```

### 4.9 D5 (Vendor bubble) — Cost Efficiency by Vendor

```sql
SELECT
    vendor_name,
    SUM(total_cbm)                                            AS total_cbm,
    SUM(total_cost)        / nullIf(SUM(total_cbm), 0)        AS cost_per_cbm,
    uniqExact(tracking_id)                                    AS trip_count
FROM analytics_workspace.mv_psv_main
WHERE created_date >= {{date_from}}
  AND created_date <  {{date_to}}
  AND created_by IN ({{planner_list}})
  AND vendor_name != ''
GROUP BY vendor_name
HAVING total_cbm > 0
ORDER BY total_cbm DESC;
```

### 4.A.alt — Option A fallback pattern (psv_target version pivot)

Khi Q1 = No (JSON không lưu Auto baseline) thì fallback dùng `psv_target` raw (chưa FINAL) để pivot theo `version`:

```sql
WITH versioned AS (
    SELECT
        ops_optimize_id,
        tracking_id,
        report_id,
        version,
        vendor_name,
        total_cost,
        total_cbm,
        row_number() OVER (PARTITION BY ops_optimize_id, tracking_id, report_id ORDER BY version ASC)  AS rn_first,
        row_number() OVER (PARTITION BY ops_optimize_id, tracking_id, report_id ORDER BY version DESC) AS rn_last
    FROM analytics_workspace.psv_target
    WHERE is_deleted = 0
      AND data_report = true
      AND created_date >= {{date_from}} - INTERVAL 7 HOUR
      AND created_date <  {{date_to}} - INTERVAL 7 HOUR
)
SELECT
    tracking_id,
    anyIf(vendor_name, rn_first = 1)        AS vendor_auto,
    anyIf(vendor_name, rn_last  = 1)        AS vendor_adjusted,
    anyIf(total_cost,  rn_first = 1)        AS cost_auto,
    anyIf(total_cost,  rn_last  = 1)        AS cost_adjusted,
    anyIf(total_cbm,   rn_first = 1)        AS cbm_auto,
    anyIf(total_cbm,   rn_last  = 1)        AS cbm_adjusted
FROM versioned
GROUP BY tracking_id;
```

⚠️ Pattern Option A có **caveat**: nếu planner adjust trước khi save lần đầu (Panasonic TMS workflow chưa verify), MIN(version) = Adjusted, KHÔNG phải Auto → fallback fails silently. Phải verify trước go-live.

### 4.B.alt — Option B trigger MV extension

Nếu Q1 = Yes, extend `mv_psv_trigger` để extract Auto baseline từ JSON. Pseudo-code (BE owns):

```sql
-- Pseudo: actual extraction depends on JSON path Panasonic confirms
coalesce(JSONExtractFloat(v, 'OriginalTotalCost'), 0)  AS total_cost_auto,
coalesce(JSONExtractFloat(v, 'OriginalTotalCBM'),  0)  AS total_cbm_auto,
coalesce(JSONExtractString(v, 'OriginalVendorName'), '') AS vendor_name_auto,
```

→ Materialize vào `psv_target` + propagate qua `mv_psv_main`. Cần migration: ADD COLUMN + REFRESH MV.

### 4.10 T-CONSTRAINT — Violation Trip Log (data + count, server-side pagination)

**Data query:**

```sql
WITH trips AS (
    SELECT
        tracking_id,
        any(created_date)                                     AS created_date,
        any(created_by)                                       AS planner_name,
        any(location_to_code)                                 AS location_to_code,
        any(location_to_name)                                 AS location_to_name,
        any(vendor_name)                                      AS vendor_name,
        any(carrier_name)                                     AS carrier_name,
        any(constraint_name)                                  AS constraint_violations,
        any(reason_change)                                    AS reason_change,
        SUM(total_cost)                                       AS total_cost_adjusted
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= {{date_from}}
      AND created_date <  {{date_to}}
      AND created_by IN ({{planner_list}})
      AND constraint_name != ''
    GROUP BY tracking_id
)
SELECT
    t.tracking_id,
    t.created_date,
    t.planner_name,
    coalesce(z.zone, 'Unknown')                               AS zone,
    t.location_to_name,
    t.vendor_name,
    t.carrier_name,
    t.constraint_violations,
    t.reason_change,
    t.total_cost_adjusted
FROM trips AS t
LEFT JOIN analytics_workspace.panasonic_zone_master AS z
    ON z.location_to_code = t.location_to_code
WHERE ({{zone}} = 'ALL' OR coalesce(z.zone, 'Unknown') = {{zone}})
  AND ({{search}} = '' 
       OR positionCaseInsensitive(toString(t.tracking_id), {{search}}) > 0
       OR positionCaseInsensitive(t.constraint_violations, {{search}}) > 0
       OR positionCaseInsensitive(t.vendor_name, {{search}}) > 0)
ORDER BY {{sort_field:created_date}} {{sort_order:DESC}}
LIMIT {{page_size:50}} OFFSET {{page_offset:0}};
```

**Count query (for pagination total):**

```sql
SELECT count()
FROM (
    SELECT tracking_id, any(location_to_code) AS location_to_code, any(constraint_name) AS constraint_name, any(vendor_name) AS vendor_name
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= {{date_from}}
      AND created_date <  {{date_to}}
      AND created_by IN ({{planner_list}})
      AND constraint_name != ''
    GROUP BY tracking_id
) AS t
LEFT JOIN analytics_workspace.panasonic_zone_master AS z
    ON z.location_to_code = t.location_to_code
WHERE ({{zone}} = 'ALL' OR coalesce(z.zone, 'Unknown') = {{zone}})
  AND ({{search}} = '' 
       OR positionCaseInsensitive(toString(t.tracking_id), {{search}}) > 0
       OR positionCaseInsensitive(t.constraint_name, {{search}}) > 0
       OR positionCaseInsensitive(t.vendor_name, {{search}}) > 0);
```

### 4.11 T-VENDOR — Vendor Swap Detail (Option B — requires Auto baseline columns)

```sql
WITH trips AS (
    SELECT
        tracking_id,
        any(created_date)                                     AS created_date,
        any(location_to_code)                                 AS location_to_code,
        any(vendor_name_auto)                                 AS vendor_auto,
        any(vendor_name)                                      AS vendor_adjusted,
        any(carrier_name_auto)                                AS carrier_auto,
        any(carrier_name)                                     AS carrier_adjusted,
        SUM(total_cost_auto)                                  AS cost_auto,
        SUM(total_cost)                                       AS cost_adjusted,
        SUM(total_cbm)                                        AS total_cbm,
        any(reason_change)                                    AS reason_change
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= {{date_from}}
      AND created_date <  {{date_to}}
      AND created_by IN ({{planner_list}})
    GROUP BY tracking_id
)
SELECT
    t.tracking_id,
    t.created_date,
    coalesce(z.zone, 'Unknown')                               AS zone,
    t.vendor_auto,
    t.vendor_adjusted,
    t.carrier_auto,
    t.carrier_adjusted,
    t.cost_auto,
    t.cost_adjusted,
    t.cost_adjusted - t.cost_auto                             AS cost_delta_vnd,
    round((t.cost_adjusted - t.cost_auto) * 100.0 / nullIf(t.cost_auto, 0), 2)  AS pct_drift,
    t.total_cbm,
    t.reason_change
FROM trips AS t
LEFT JOIN analytics_workspace.panasonic_zone_master AS z
    ON z.location_to_code = t.location_to_code
WHERE (t.cost_auto > 0 OR t.cost_adjusted > 0)
  AND ({{zone}} = 'ALL' OR coalesce(z.zone, 'Unknown') = {{zone}})
  AND ({{vendor}} = 'ALL' OR t.vendor_auto = {{vendor}} OR t.vendor_adjusted = {{vendor}})
ORDER BY {{sort_field:cost_delta_vnd}} {{sort_order:DESC}}
LIMIT {{page_size:50}} OFFSET {{page_offset:0}};
```

> **Option A fallback** (nếu Q1 = No): derive `vendor_auto`, `cost_auto` từ pattern §4.A.alt, then JOIN với current `mv_psv_main` aggregated by `tracking_id`. Status: 🟡 caveat MIN(version) accuracy.

### 4.12 T-ZONE-COST — Zone-Level Cost Variance (Option B)

```sql
WITH per_zone AS (
    SELECT
        coalesce(z.zone, 'Unknown')                           AS zone,
        uniqExact(m.tracking_id)                              AS trip_count_adj,
        uniqExactIf(m.tracking_id, m.total_cost_auto > 0)     AS trip_count_auto,
        SUM(m.total_cost_auto)                                AS total_cost_auto,
        SUM(m.total_cost)                                     AS total_cost_adj,
        SUM(m.total_cbm_auto)                                 AS total_cbm_auto,
        SUM(m.total_cbm)                                      AS total_cbm_adj
    FROM analytics_workspace.mv_psv_main AS m
    LEFT JOIN analytics_workspace.panasonic_zone_master AS z
        ON z.location_to_code = m.location_to_code
    WHERE m.created_date >= {{date_from}}
      AND m.created_date <  {{date_to}}
      AND m.created_by IN ({{planner_list}})
    GROUP BY z.zone
    HAVING trip_count_adj >= 10
)
SELECT
    zone,
    trip_count_auto,
    trip_count_adj,
    total_cost_auto,
    total_cost_adj,
    total_cost_adj - total_cost_auto                          AS cost_delta_vnd,
    round((total_cost_adj - total_cost_auto) * 100.0 / nullIf(total_cost_auto, 0), 2)
                                                              AS pct_diff,
    total_cbm_auto,
    total_cbm_adj,
    total_cost_auto / nullIf(total_cbm_auto, 0)               AS cpc_auto,
    total_cost_adj  / nullIf(total_cbm_adj, 0)                AS cpc_adj,
    round(
        ((total_cost_adj / nullIf(total_cbm_adj, 0))
         - (total_cost_auto / nullIf(total_cbm_auto, 0)))
        * 100.0
        / nullIf(total_cost_auto / nullIf(total_cbm_auto, 0), 0)
    , 2)                                                      AS cpc_drift_pct
FROM per_zone
ORDER BY cost_delta_vnd DESC;
```

> Client-side pagination — zones ≤ 20 expected, full result returned.

### 4.13 T-MASTER — Trip Master Table (Tab 5, server-side pagination)

**Data query:**

```sql
SELECT
    m.tracking_id,
    any(m.created_date)                                       AS created_date,
    any(m.created_by)                                         AS planner_name,
    coalesce(z.zone, 'Unknown')                               AS zone,
    any(z.region)                                             AS region,
    any(m.location_from_name)                                 AS location_from_name,
    any(m.location_to_name)                                   AS location_to_name,
    any(m.vendor_name_auto)                                   AS vendor_auto,
    any(m.vendor_name)                                        AS vendor_adj,
    any(m.carrier_name_auto)                                  AS carrier_auto,
    any(m.carrier_name)                                       AS carrier_adj,
    any(m.status_name_detail)                                 AS status_name_detail,
    any(m.reason_change)                                      AS reason_change,
    SUM(m.total_cost_auto)                                    AS total_cost_auto,
    SUM(m.total_cost)                                         AS total_cost_adj,
    SUM(m.total_cost) - SUM(m.total_cost_auto)                AS cost_delta_vnd,
    round((SUM(m.total_cost) - SUM(m.total_cost_auto)) * 100.0 / nullIf(SUM(m.total_cost_auto), 0), 2)
                                                              AS pct_drift,
    SUM(m.total_cbm_auto)                                     AS total_cbm_auto,
    SUM(m.total_cbm)                                          AS total_cbm_adj,
    SUM(m.total_cost_auto) / nullIf(SUM(m.total_cbm_auto), 0) AS cpc_auto,
    SUM(m.total_cost)      / nullIf(SUM(m.total_cbm), 0)      AS cpc_adj,
    countIf(m.constraint_name != '')                          AS constraint_violations_count,
    any(m.constraint_name)                                    AS constraint_names_list
FROM analytics_workspace.mv_psv_main AS m
LEFT JOIN analytics_workspace.panasonic_zone_master AS z
    ON z.location_to_code = m.location_to_code
WHERE m.created_date >= {{date_from}}
  AND m.created_date <  {{date_to}}
  AND m.created_by IN ({{planner_list}})
  AND ({{zone}} = 'ALL' OR coalesce(z.zone, 'Unknown') = {{zone}})
GROUP BY m.tracking_id, z.zone, z.region
ORDER BY {{sort_field:created_date}} {{sort_order:DESC}}
LIMIT {{page_size:50}} OFFSET {{page_offset:0}};
```

**Count query:**

```sql
SELECT count()
FROM (
    SELECT m.tracking_id, any(m.location_to_code) AS location_to_code
    FROM analytics_workspace.mv_psv_main AS m
    WHERE m.created_date >= {{date_from}}
      AND m.created_date <  {{date_to}}
      AND m.created_by IN ({{planner_list}})
    GROUP BY m.tracking_id
) AS t
LEFT JOIN analytics_workspace.panasonic_zone_master AS z
    ON z.location_to_code = t.location_to_code
WHERE ({{zone}} = 'ALL' OR coalesce(z.zone, 'Unknown') = {{zone}});
```

> **Auto columns degradation**: nếu Option B chưa deploy → `vendor_name_auto`, `carrier_name_auto`, `total_cost_auto`, `total_cbm_auto` returns NULL. Widget runtime tooltip column header với "Pending Q1 — see spec §7 GAP" thay vì hide column.

### 4.14 T-PLANNER — Per-Planner Activity (Tab 5)

```sql
WITH trip_level AS (
    SELECT
        tracking_id,
        any(created_by)                                       AS planner_name,
        any(created_date)                                     AS run_start,
        any(report_modified_date)                             AS final_save,
        max(is_trip_edit_manual)                              AS edited
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= {{date_from}}
      AND created_date <  {{date_to}}
      AND created_by IN ({{planner_list}})
    GROUP BY tracking_id
),
planner_active AS (
    SELECT DISTINCT created_by AS planner_name
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= now() - INTERVAL 7 DAY
)
SELECT
    t.planner_name,
    pa.planner_name IS NOT NULL                               AS is_active_last_7d,
    count()                                                   AS total_trips,
    countIf(t.edited = 0)                                     AS no_change_trips,
    countIf(t.edited = 1)                                     AS edited_trips,
    round(countIf(t.edited = 1) * 100.0 / nullIf(count(), 0), 1)
                                                              AS pct_change,
    avgIf(
        dateDiff('minute', t.run_start, t.final_save),
        t.edited = 1 AND t.final_save IS NOT NULL
    )                                                         AS avg_adj_duration_min,
    min(t.run_start)                                          AS first_seen,
    max(t.run_start)                                          AS last_seen
FROM trip_level AS t
LEFT JOIN planner_active AS pa ON pa.planner_name = t.planner_name
GROUP BY t.planner_name
ORDER BY total_trips DESC;
```

---

## 5. Edge Cases & Null Handling

| Trường hợp | Rule | Apply tới |
|---|---|---|
| No data trong window | Return NULL → UI display `—` + caption "No Autoplan run" | A1, B1 |
| `total_trips = 0` | NULL (divide-by-zero) — KHÔNG fallback 0% | A1, B1 |
| Zone không match master | Bucket `'Unknown'` cuối list + telemetry warning | A2, B2, C3, C5, D2-D6 |
| Zone với `n < 10` trips | Filter HAVING; nếu cần show grey-out + tooltip "low sample (n=N)" | A2, B2, D2-D6 |
| `constraint_name` CSV | Split by `,` (B3 only); B1/B2/B4 count per trip không split | All B charts |
| Trip không edited | `is_trip_edit_manual = 0` → loại khỏi AVG Adj Duration (A4) | A4 |
| `report_modified_date < created_date` (corrupt) | Loại + DQ alert log | A4 |
| Vendor mới xuất hiện ở Adjusted (auto = null) | Label `(New)`; vendor biến mất (adj = null) → `(Removed)` | C1, C2 |
| Outlier cell n < 5 trips Auto | Grey out hoặc hide cell | C5 |
| `cpc_auto = 0` | `pct_diff` = NULL → display `—` | A3, D4 |
| Weekend / holiday với 0 user | Show day = 0 (KHÔNG gap) | B4 |
| Range > 90 ngày | Auto resample sang weekly | A3, B4 |
| Date column timezone | `mv_psv_main` đã UTC+7; KHÔNG `+ INTERVAL 7 HOUR` lại | All |
| Raw table 0 rows match filter | Return empty result + UI display "No records match current filter. [Clear filter]" | E1-E5 |
| Raw table query timeout (>30s) | UI display "Query took too long — narrow filter or contact support" | E1-E5 |
| T-MASTER result > 200k rows | Block export + UI caption "Result exceeds 200k rows — narrow date filter" | E4 |
| T-MASTER Auto columns degraded | Cell return NULL; column header tooltip "Pending Q1 — see spec §7 GAP" (KHÔNG hide column) | E4 |
| T-CONSTRAINT search trùng nhiều | Server-side `positionCaseInsensitive` apply trên tracking_id + constraint_name + vendor_name (3-field OR) | E1 |
| Raw table `is_active_last_7d` (T-PLANNER) | Planner không activity 7d gần nhất → `false` + UI badge "Inactive" grey | E5 |
| Pagination offset > total | Return empty + UI auto-redirect về page 1 | E1, E4 |

---

## 6. Audit Queries (verification)

Run mỗi lần dashboard live + monthly khi BA reconcile số liệu.

### 6.1 Sanity check row count

```sql
SELECT
    'mv_psv_main'        AS source,
    count()              AS rows,
    uniqExact(tracking_id) AS distinct_trips,
    min(created_date)    AS min_date,
    max(created_date)    AS max_date
FROM analytics_workspace.mv_psv_main
WHERE created_date >= {{date_from}}
  AND created_date <  {{date_to}}

UNION ALL

SELECT
    'psv_target FINAL'   AS source,
    count(),
    uniqExact(tracking_id),
    min(created_date + INTERVAL 7 HOUR),
    max(created_date + INTERVAL 7 HOUR)
FROM analytics_workspace.psv_target FINAL
WHERE is_deleted = 0
  AND data_report = true
  AND created_date >= {{date_from}} - INTERVAL 7 HOUR
  AND created_date <  {{date_to}} - INTERVAL 7 HOUR;
```

Tolerance: row count drift ≤ 1% (do refresh lag 1h của mv_psv_main).

### 6.2 Sanity check A1 (% Accuracy) on audit source

```sql
WITH trip_level AS (
    SELECT
        tracking_id,
        any(is_trip_edit_manual)            AS edited,
        max(constraint_name != '')          AS has_violation
    FROM analytics_workspace.psv_target FINAL
    WHERE is_deleted = 0
      AND data_report = true
      AND created_date >= {{date_from}} - INTERVAL 7 HOUR
      AND created_date <  {{date_to}} - INTERVAL 7 HOUR
    GROUP BY tracking_id
)
SELECT
    countIf(edited = 0 OR (edited = 1 AND has_violation = 1)) * 100.0
    / nullIf(count(), 0) AS pct_accuracy_audit
FROM trip_level;
```

So sánh với widget value của A1 — tolerance ≤ 1%.

---

## 7. GAPs & Fallback Map

| GAP | Charts / Tables affected | Resolution path | Fallback (nếu không resolve) |
|---|---|---|---|
| Q1 Auto baseline | A3, C1-C5, D1-D4, D6 (11 charts) + **T-VENDOR (E2)**, **T-ZONE-COST (E3)**, **T-MASTER Auto cols (E4)** | Option B (extend `mv_psv_trigger`) hoặc Option A (psv_target version pivot, §4.A.alt) | Option C — drop Auto-vs-Adjusted; T-MASTER hiển thị Auto cols = NULL + tooltip explain; T-VENDOR / T-ZONE-COST → hide tab cho đến khi resolve |
| Q2 Zone master | A2, B2, C3, C5, D2-D6 (9 charts) + **T-CONSTRAINT zone col (E1)**, **T-VENDOR zone col (E2)**, **T-ZONE-COST entire (E3)**, **T-MASTER zone+region cols (E4)** | Materialize `analytics_workspace.panasonic_zone_master` từ file PM/Panasonic Logistics | Disable filter zone; T-CONSTRAINT/T-VENDOR/T-MASTER hiển thị `zone = 'Unknown'` cho mọi rows; T-ZONE-COST tab disabled |
| Q3 Event log | A4 (ideal formula), full `psv-adoption-vrp`, **T-PLANNER avg_adj_duration (E5)** | Capture từ Panasonic TMS audit table hoặc Smartlog activity log | A4 + T-PLANNER fallback từ `created_date` + `report_modified_date` (đã ship v1); adoption section defer |
| Q4 Run Status | `psv-adoption-vrp` 5.4 | Extract từ JSON / sister table | `data_report = true` as success proxy |

---

## 8. Performance Notes

- `mv_psv_main` ORDER BY `(tracking_id, order_code)` → filter theo `created_date` SẼ FULL SCAN. Acceptable do MV chỉ 34k rows. Nếu mở rộng > 1M rows, cân nhắc thêm `(toYYYYMM(created_date), tracking_id)` index hoặc skip index trên `created_date`.
- ARRAY JOIN trong B3 với `splitByChar` — chi phí proportional với avg violation count per trip. Hiện max ~5 violations/trip, OK.
- WINDOW FUNCTION trong §4.A.alt — chỉ chạy khi Option A active; OK với 39k rows nhưng monitor nếu mở rộng.
- Section dashboard render ~10-15 widgets cùng lúc → tổng query ~15 calls. Bật query result cache (60s) ở widget runtime để tránh duplicate.

---

## 9. References

- **PRD:** [psv-accuracy-vrp-prd.md](psv-accuracy-vrp-prd.md)
- **Wireframe:** [psv-accuracy-vrp-wireframe.md](psv-accuracy-vrp-wireframe.md)
- **Storytelling notes:** [analysis/storytelling-notes.md](analysis/storytelling-notes.md)
- **DDL canonical:** [analytics-workspace_psv.md](../../02-data/data-sources/clickhouse-ddl/analytics-workspace_psv.md)
- **Glossary:** [glossary.md](../../02-data/glossary.md)
- **SQL registry convention:** `docs/shared/sql-registry.md` (project-level)
