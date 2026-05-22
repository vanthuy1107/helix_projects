# SPEC — Late Order Alert: SQL contract & widget runtime behavior

| Trường | Giá trị |
|--------|---------|
| **Version** | 1.0.0 |
| **Ngày** | 2026-05-19 |
| **Trạng thái** | Observed baseline — trích từ implementation hiện hành |
| **Tác giả** | PM/DA via `/da-trace` |
| **Phạm vi** | Hợp đồng SQL + runtime behavior của `WidgetLateOrderAlert` |
| **PRD reference** | [late-order-alert-prd.md](late-order-alert-prd.md) |
| **Source code** | [`frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx`](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx) |

---

## 1. Section keys & SQL contract

> **[Observed]** — `LATE_ORDER_ALERT_SECTIONS` ở [widget-late-order-alert-settings-dialog.tsx:27-83](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert-settings-dialog.tsx#L27-L83). Interface `LateOrderAlertSqlQueries` ở [widget-late-order-alert-settings-dialog.tsx:13-23](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert-settings-dialog.tsx#L13-L23).

Widget cần 2 SQL query, lưu dưới `config.queries`:

```ts
interface LateOrderAlertSqlQueries {
  scorecard: string  // SQL trả về 1 row với 8 count
  detail: string     // SQL trả về N rows DO-level
}
```

### 1.1 Section `scorecard`

**Mục đích**: Cấp data cho 8 KPI card (Tổng chuyến + 7 alert status).

**Required columns** (validator dùng `anyOf` — chỉ cần 1 alias match):

| Logical name | anyOf aliases | Mục đích |
|--------------|---------------|----------|
| `tat_ca` | `tat_ca`, `tatca`, `tatCa`, `total_count` | Tổng số chuyến |
| `normal_cnt` | `normal_cnt`, `normalcnt`, `normalCnt` | Count status = Normal |
| `at_risk_cnt` | `at_risk_cnt`, `atriskcnt`, `atRiskCnt` | Count status = At risk |
| `late_departure_open_cnt` | `late_departure_open_cnt`, `latedepartureopencnt`, `lateDepartureOpenCnt` | Count status = Late departure open |
| `late_departure_cnt` | `late_departure_cnt`, `latedeparturecnt`, `lateDepartureCnt` | Count status = Late departure |
| `ontime_departure_cnt` | `ontime_departure_cnt`, `ontimeDepartureCnt`, `ontimedepcnt` | Count status = Ontime departure |
| `ontime_delivery_cnt` | `ontime_delivery_cnt`, `ontimeDeliveryCnt`, `ontimedelcnt` | Count status = Ontime delivery |
| `late_delivery_cnt` | `late_delivery_cnt`, `lateDeliveryCnt`, `latedelcnt` | Count status = Late delivery |

**Shape**: 1 row, 8 cột. Nếu trả >1 row → frontend pick `rows[0]` (`normalizeScorecardFromSql` line 256-291). Nếu trả 0 row → fallback `ZERO_SCORECARD` (tất cả = 0).

**Status classification — canonical source**:

Cột `alert_status` **được precompute trong materialized view** `analytics_workspace.mv_alert_late_do` (ClickHouse — Mondelez stack) / `reporting_schema.mv_alert_late_do` (Redshift). Widget SQL **KHÔNG tính alert inline** — chỉ `SELECT COUNT(DISTINCT so_chuyen) … WHERE alert_status = '<status>'`.

Canonical scorecard SQL:

- **Production-ready template để paste vào Settings dialog** → §22.1 (đã test trên `analytics_workspace` 2026-05-22, dùng `[[…]]` optional block để xử lý "ALL" filter đúng).
- Registry reference: [`02-data/data-sources/sql-registry.md`](../../02-data/data-sources/sql-registry.md) → section `## Cảnh báo đơn trễ` → `### Scorecard Tất cả` (line 22787+). Phiên bản registry dùng pattern `if(arraySort([{{whseid}}]) = (SELECT arraySort(...) FROM mv_filter_warehouse), 1=1, t.whseid IN ({{whseid}}))` — pattern này CHỈ work khi FE gửi CSV của tất cả warehouse codes lúc "ALL". FE hiện tại gửi `''` khi ALL ⇒ backend escape → `NULL` ⇒ `arraySort([NULL]) ≠ MV list` ⇒ rớt vào `t.whseid IN (NULL)` ⇒ **0 rows**. Vì vậy §22.1 dùng `[[...]]` block thay vì `if(arraySort)`.

CH canonical (paraphrased — KHÔNG paste version này; xem §22.1):

```sql
WITH base AS (
  SELECT t.*
  FROM analytics_workspace.mv_alert_late_do t
  WHERE 1=1
    AND if(arraySort([{{whseid}}]) = (SELECT arraySort(...) FROM mv_filter_warehouse), 1=1, t.whseid IN ({{whseid}}))
    AND if(arraySort([{{region}}]) = (SELECT arraySort(...) FROM mv_filter_region),   1=1, t.khu_vuc_doi_xe IN ({{region}}))
    AND if(arraySort([{{sales_channel}}]) = (SELECT arraySort(...) FROM mv_filter_channel), 1=1, t.group IN ({{sales_channel}}))
    AND if(arraySort([{{transporter}}]) = (SELECT arraySort(...) FROM mv_filter_vendor),    1=1, t.ten_ngan_nvt IN ({{transporter}}))
    AND toDate(CASE WHEN {{date_type}}='ETA gửi thầu (đơn)' THEN t.eta_giao_hang_cho_npp
                    WHEN {{date_type}}='Ngày gửi thầu'      THEN t.thoi_gian_gui_thau
                    WHEN {{date_type}}='ETD chuyến - …'     THEN t.etd_chuyen
                    WHEN {{date_type}}='ETA chuyến - …'     THEN t.eta_chuyen
                    WHEN {{date_type}}='Ngày gửi yêu cầu đơn hàng' THEN t.request_date
                    WHEN {{date_type}}='ATD chuyến - …'     THEN t.atd_chuyen
                    WHEN {{date_type}}='ATA chuyến - …'     THEN t.ata_chuyen
                    WHEN {{date_type}}='Ngày duyệt chuyến'  THEN t.approved_date END)
        BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
            AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
SELECT
  COUNT(DISTINCT so_chuyen) AS tat_ca,
  COUNT(DISTINCT CASE WHEN alert_status='Normal'              THEN so_chuyen END) AS normal_cnt,
  COUNT(DISTINCT CASE WHEN alert_status='At risk'             THEN so_chuyen END) AS at_risk_cnt,
  COUNT(DISTINCT CASE WHEN alert_status='Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
  COUNT(DISTINCT CASE WHEN alert_status='Late departure'      THEN so_chuyen END) AS late_departure_cnt,
  COUNT(DISTINCT CASE WHEN alert_status='Ontime departure'    THEN so_chuyen END) AS ontime_departure_cnt,
  COUNT(DISTINCT CASE WHEN alert_status='Ontime delivery'     THEN so_chuyen END) AS ontime_delivery_cnt,
  COUNT(DISTINCT CASE WHEN alert_status='Late delivery'       THEN so_chuyen END) AS late_delivery_cnt
FROM base
```

> **Quan trọng**: Logic phân loại 7 status (kể cả ngưỡng 45 phút At-risk) **sống bên trong MV `mv_alert_late_do`**, không phải trong widget SQL. Muốn audit / chỉnh threshold phải sửa MV definition, không sửa được qua Settings dialog. Xem §7 (Known Anomalies — A3).

> Nếu user chọn `date_type = 'ETA gửi thầu'` (không có suffix `(đơn)`) → CH CASE expression không match nhánh nào → `toDate(NULL)` → row bị loại bởi BETWEEN → scorecard về 0. Xem §7 (Known Anomalies — A1).

### 1.2 Section `detail`

**Mục đích**: Cấp data cho bảng chi tiết + 2 chart client-side derived (transporter breakdown + trip-level aggregation).

**Required columns** (visible-by-default — fail nếu thiếu): `trip`, `do_code`, `trip_status`, `mandatory_depart_at`, `alert`, `warehouse`, `delivery_area`, `transporter`, `atd_actual`, `eta`, `sales_channel`.

**Cột optional** (default-hidden — chỉ cần trả nếu user opt-in qua column toggle):

| Nhóm | Cột |
|------|-----|
| Identity / status | `trang_thai_chuyen_stm`, `customer_code`, `customer_name`, `ma_doi_tac_nhan`, `ten_doi_tac_nhan` |
| Time fields | `thoi_gian_gui_thau`, `ngay_tao_chuyen`, `etd_chuyen_gui_thau`, `gio_dang_tai`, `gio_goi_xe`, `gio_vao_cong`, `gio_vao_dock`, `actual_ship_date`, `gio_ra_dock`, `tg_bat_buoc_roi_kho`, `ata_den`, `ata_roi` |
| Vehicle | `so_xe`, `tai_xe`, `ma_nha_xe` |
| Quantities — original | `sum_original`, `sum_original_cbm`, `sum_original_ton`, `sum_original_cse`, `sum_original_pl` |
| Quantities — shipped | `sum_shipped`, `sum_shipped_cbm`, `sum_shipped_ton`, `sum_shipped_cse`, `sum_shipped_pl` |
| Quantities — delivered | `sum_san_luong_giao`, `sum_san_luong_giao_cbm`, `sum_san_luong_giao_ton`, `sum_san_luong_giao_cse`, `sum_san_luong_giao_pl` |
| Diff | `diff_sl_giao_cho`, `diff_sl_giao_cho_cbm`, `diff_sl_giao_cho_ton`, `diff_sl_giao_cho_cse`, `diff_sl_giao_cho_pl` |
| Durations | `total_time_in_warehouse_minute`, `total_time_loading_minute`, `diff_delivery_time_hour`, `phut_tre_roi_kho`, `phut_tre_giao_npp` |
| Status / metadata | `ly_do_tre_hoan_thanh` |
| Other times | `etd_chuyen`, `eta_chuyen`, `ata_chuyen`, `atd_chuyen`, `request_date`, `approved_date` |
| Distance | `so_km`, `van_toc` |

**Shape**: N rows DO-level (1 DO = 1 row). Frontend tự aggregate về trip-level theo §5.3 PRD.

**Canonical SQL**:

- **Production-ready template để paste vào Settings dialog** → §22.2 (đã test trên `analytics_workspace` 2026-05-22).
- Registry reference: [`02-data/data-sources/sql-registry.md`](../../02-data/data-sources/sql-registry.md) → `## Cảnh báo đơn trễ` → `### Report raw` (line 23957+). Registry variant alias mọi cột sang display name tiếng Việt (`so_chuyen AS "Số chuyến"` …) — **KHÔNG paste version này** vì `normalizeDetailRowFromSql` ([widget-late-order-alert.tsx:267-566](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L267-L566)) chỉ recognize aliases tiếng Anh / snake_case (`trip`, `so_chuyen`, `alert_status`, `whseid`, `ten_ngan_nvt` …). Paste registry variant → mọi field về empty string. §22.2 dùng English aliases cho 11 cột required + raw snake_case cho ~50 cột optional.

**Page size**: 5000 (truyền từ frontend qua API call).

---

## 2. Filter override binding

> **[Observed]** — `filterOverrides` memo ở [widget-late-order-alert.tsx:910-944](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L910-L944).

Frontend gửi 9 cặp key-value sang backend qua `executeWidget` (cùng key-value cho cả `scorecard` và `detail`):

```ts
filterOverrides: Record<string, string> = {
  whseid: <CSV warehouse codes hoặc "">,
  region: <CSV regions hoặc "">,
  group_name: <CSV sales channels hoặc "">,
  sales_channel: <CSV sales channels hoặc "">,  // alias
  transporter: <CSV transporters hoặc "">,
  date_type: <single value hoặc "">,
  dateType: <single value hoặc "">,             // alias
  loai_ngay: <single value hoặc "">,            // alias
  from_date: "YYYY-MM-DD 00:00:00",
  to_date:   "YYYY-MM-DD 23:59:59"
}
```

**Rules**:
- Multi-select: CSV không quote (vd `BKD1,BKD2,NKD`). Backend phải split + quote khi bind vào SQL `IN (...)`.
- Khi user chọn "ALL" hoặc empty → giá trị truyền là `""` (empty string). Backend phải skip điều kiện đó (no-op).
- `date_type`, `dateType`, `loai_ngay` chứa CÙNG 1 value (3 alias để backward-compat với SQL legacy).
- `group_name` và `sales_channel` cũng là 2 alias của cùng filter.

### 2.1 Date type semantics

**FE filter `dateType`** từ 2026-05-21 (T3.4 scope expansion): SQL-driven qua Filter Settings, không còn hardcoded array. Admin paste SQL trả về `code` + `date_type_name` qua Setting Filter dialog; widget consume `analytics_workspace.mv_filter_date_type_alert` MV làm default source.

Default fallback options (khi chưa configure SQL): `['Ngày gửi thầu', 'ETA gửi thầu (đơn)']` — match MV live state.

**Canonical date_type values (PM decision 2026-05-21 — vẫn giữ `(đơn)` suffix)**:

| Canonical value | Cột map (CASE branch) | Default Mondelez option? |
|-----------------|------------------------|--------------------------|
| `Ngày gửi thầu` | `thoi_gian_gui_thau` | ✅ Default (#1, safest) |
| `ETA gửi thầu (đơn)` | `eta_giao_hang_cho_npp` | ✅ Default (#2, KEEP suffix per PM) |
| `ETD chuyến - ngày dự kiến lấy hàng` | `etd_chuyen` | ❌ Available qua MV — paste để expose |
| `ETA chuyến - ngày dự kiến giao hàng` | `eta_chuyen` | ❌ Available qua MV |
| `Ngày gửi yêu cầu đơn hàng` | `request_date` | ❌ Available qua MV |
| `ATD chuyến - ngày thực tế lấy hàng` | `atd_chuyen` | ❌ Available qua MV |
| `ATA chuyến - ngày thực tế giao hàng` | `ata_chuyen` | ❌ Available qua MV |
| `Ngày duyệt chuyến` | `approved_date` | ❌ Available qua MV |

**PM decision 2026-05-21** (override fix 2026-05-19): registry SQL CASE branch CH phải match `'ETA gửi thầu (đơn)'` (giữ suffix `(đơn)` từ MDLZ legacy), KHÔNG drop suffix.

→ **Action items consequence**:
- ✅ MV `mv_filter_date_type_alert` giữ nguyên (KHÔNG fix DDL, KHÔNG drop suffix) — Step 0 cancelled.
- ⏳ Registry SQL `sql-registry.md` cần **REVERT** fix 2026-05-19: re-add `(đơn)` suffix vào 38 spot CASE branch (CH variants chỉ). Phải làm trước khi paste runtime mới.
- ✅ Runtime `widget.config.queries` của Mondelez tenant giữ nguyên (pre-A1 state) — match được MV + registry sau revert.
- ⚠ RS tenant (nếu có): RS variants registry không có suffix; cần decision riêng nếu deploy LOA cho RS-backed tenant.
- ⚠ FE callsites khác đang dùng `'ETA gửi thầu'` (no suffix) — cần align cùng decision: [widget-otif.tsx:531,778,1409](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L531), [widget-flash-daily.tsx:114](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L114), [order-monitor-api.ts:353](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/order-monitor-api.ts#L353).

⚠ **Memory rule `feedback_sql_date_type_label_exact_match`**: value PHẢI khớp **EXACT** với CASE branch label — sai 1 ký tự (case/dấu cách/suffix) → CASE rớt ELSE → query luôn lấy column mặc định, silently sai data. **PM canonical 2026-05-21: `'ETA gửi thầu (đơn)'` với suffix.**

### 2.2 Filter Date Type — Canonical SQL template (registry-aligned)

> **Pattern chuẩn project**: dùng dedicated MV `analytics_workspace.mv_filter_date_type_alert` thay vì hardcoded UNION SELECT. Đây là cách registry binds các filter source khác (`mv_filter_warehouse`, `mv_filter_region`, `mv_filter_channel`, `mv_filter_vendor`, `mv_filter_cargo_brand`) — single source of truth, sửa MV definition là sửa được tất cả widget consume.

#### 2.2.1 Canonical SQL (project-standard, matches widget defaultSql)

```sql
SELECT code, date_type_name
FROM analytics_workspace.mv_filter_date_type_alert
```

**MV schema** (per [`analytics-workspace_mvs.md` line 1920-1961](../../02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.md)):
```
CREATE VIEW analytics_workspace.mv_filter_date_type_alert (
  `code` String,
  `date_type_name` String
)
```

**Verified live output trên CH `analytics_workspace`** 2026-05-21 — trả về 8 row, `code` = `date_type_name`:
```
   ┌─code────────────────────────────────┬─date_type_name──────────────────────┐
1. │ ETA gửi thầu (đơn)                  │ ETA gửi thầu (đơn)                  │
2. │ Ngày gửi thầu                       │ Ngày gửi thầu                       │
3. │ ETD chuyến - ngày dự kiến lấy hàng  │ ETD chuyến - ngày dự kiến lấy hàng  │
4. │ ETA chuyến - ngày dự kiến giao hàng │ ETA chuyến - ngày dự kiến giao hàng │
5. │ Ngày gửi yêu cầu đơn hàng           │ Ngày gửi yêu cầu đơn hàng           │
6. │ ATD chuyến - ngày thực tế lấy hàng  │ ATD chuyến - ngày thực tế lấy hàng  │
7. │ ATA chuyến - ngày thực tế giao hàng │ ATA chuyến - ngày thực tế giao hàng │
8. │ Ngày duyệt chuyến                   │ Ngày duyệt chuyến                   │
   └─────────────────────────────────────┴─────────────────────────────────────┘
```

Khớp với `defaultSql` factory ở [widget-late-order-alert.tsx LOA_FILTER_DEFINITIONS dateType field](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx) — `valueFieldCandidates: ['code', 'date_type_name', 'value']` + `labelFieldCandidates: ['date_type_name', 'label', 'code']`.

#### 2.2.2 PM decision 2026-05-21 — KEEP `(đơn)` suffix; verify đã coherent

> Per PM (squad1@gosmartlog.com): canonical value cho ETA gửi thầu = `'ETA gửi thầu (đơn)'` (MDLZ legacy data convention). Override decision A1.

**Current 4-way state — verified live 2026-05-21**:

| Layer | Value | Match PM canonical `(đơn)`? |
|-------|-------|------------------------------|
| MV `mv_filter_date_type_alert.date_type_name` | `'ETA gửi thầu (đơn)'` | ✅ correct |
| Runtime `widget.config.queries.{scorecard,detail}` (Mondelez tenant DB) | `WHEN ... = 'ETA gửi thầu (đơn)'` | ✅ correct |
| Registry SQL `sql-registry.md` Cảnh báo đơn trễ — **55/55 CH WHEN branches** | `WHEN {{date_type}} = 'ETA gửi thầu (đơn)'` | ✅ correct (verified via grep) |
| Registry SQL `sql-registry.md` Cảnh báo đơn trễ — RS WHEN branches | `WHEN p.p_loai_ngay = 'ETA gửi thầu'` | ✅ correct (RS không có suffix originally) |
| FE widget `DATE_TYPE_FALLBACK[1]` | `'ETA gửi thầu (đơn)'` | ✅ correct (updated 2026-05-21) |

→ **NO ACTION ITEMS** — tất cả 4 layer đã align trên `(đơn)` canonical cho CH stack. BUG-043 effectively resolved bởi PM decision + FE update đơn lẻ.

**Important correction**: BUG-043 §"Fix applied 2026-05-19 Step 1" claim (replace_all 38 spots) thực tế **KHÔNG match state file hiện tại**:
- Grep current: `WHEN {{date_type}} = 'ETA gửi thầu (đơn)'` → 55 matches CH variants
- Grep current: `WHEN {{date_type}} = 'ETA gửi thầu'` (no suffix) → 0 matches CH variants

→ Step 1 doc-side fix hoặc chưa từng được apply lên disk, hoặc đã bị revert ở session sau. Registry CH variants **đã luôn luôn** giữ `(đơn)` suffix — consistent với MV + runtime + (now) FE.

**Cross-widget callsites** đang dùng `'ETA gửi thầu'` (no suffix) — cần align cùng PM decision nếu apply globally:

| Widget | File | Status |
|--------|------|--------|
| OTIF | [widget-otif.tsx:531,778,1409](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L531) | ⏳ Pending PM decision extend |
| Flash Daily | [widget-flash-daily.tsx:114](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L114) | ⏳ Pending PM decision extend |
| order-monitor-api default | [order-monitor-api.ts:353](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/order-monitor-api.ts#L353) | ⏳ Pending PM decision extend |

Tracked at [BUG-043 §Status updated 2026-05-21](../../triage/bugs/cross-stack/%5BW%5D-BUG-043-late-order-alert-date-type-eta-gui-thau-mismatch.md).

#### 2.2.3 Test command — verify MV vẫn trả đúng `(đơn)` suffix

```bash
# Load CH credentials
export $(grep -v '^#' projects/mondelez/.env | xargs -d '\n')

# Query MV directly — expect row #1 = 'ETA gửi thầu (đơn)'
echo "SELECT code, date_type_name FROM analytics_workspace.mv_filter_date_type_alert FORMAT PrettyCompactMonoBlock" \
  | curl -s \
  --user "$CLICKHOUSE_USER:$CLICKHOUSE_PASSWORD" \
  -H "Content-Type: text/plain" \
  --data-binary @- \
  "https://$CLICKHOUSE_HOST:8443/?database=analytics_workspace"
```

Expected: 8 rows trả về, row #1 = `'ETA gửi thầu (đơn)'` (verified live 2026-05-21).

Hoặc PM dùng nút **Test Query** trong Filter Settings dialog của widget — runs SQL qua `dashboardV2Api.executeFilterSql` endpoint.

**LOA filter dateType status — đã coherent 2026-05-21**:
1. ✅ Registry SQL `sql-registry.md` CH variants — 55/55 spots đã có `(đơn)` suffix (verified live grep)
2. ✅ MV `mv_filter_date_type_alert` keep as-is — đã có suffix
3. ✅ Runtime `widget.config.queries` Mondelez keep as-is — pre-A1 state đã canonical
4. ✅ FE `DATE_TYPE_FALLBACK[1]` updated to `'ETA gửi thầu (đơn)'` 2026-05-21

→ **No further action required cho LOA filter dateType ship**.

**Cross-widget impact (separate scope)**: OTIF + Flash Daily + order-monitor-api.ts cũng dùng `'ETA gửi thầu'` (no suffix) — cần align nếu PM extend decision cho các widget này. Tracked at [BUG-043 cross-widget table](../../triage/bugs/cross-stack/%5BW%5D-BUG-043-late-order-alert-date-type-eta-gui-thau-mismatch.md).

---

## 3. Runtime behavior

### 3.1 Loading & error states

> [widget-late-order-alert.tsx:1163-1192](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L1163-L1192)

| State | Trigger | UI |
|-------|---------|-----|
| Initial loading | `isLoading && !hasLoadedData` | Skeleton: filter strip + 8 KPI cards + 1 chart placeholder |
| Refetching (autoApply) | `isFetching` (sau initial load) | Filter bar có loading indicator; data cũ giữ qua `placeholderData = prev` |
| Error | `scorecardError && !hasLoadedData` | Inline error box với `AlertTriangle` icon + error message |
| Empty | data rỗng | Cards = 0; chart render rỗng (KHÔNG có message "Không có dữ liệu") |
| No config | `hasSqlConfig = false` | `useQuery` disabled — widget show empty cards + empty charts |

### 3.2 Query lifecycle

| Property | Giá trị |
|----------|---------|
| `staleTime` | 5 phút (300_000 ms) |
| `placeholderData` | `(prev) => prev` — giữ data cũ khi refetch để filter panel không unmount |
| `enabled` | `hasSqlConfig && dashboardId && widgetId && filterInitialized` |

**Query key**:
```ts
['order-monitor', 'late-order-alert-{scorecard|detail}', dashboardId, widgetId, filterOverrides, hasSqlConfig, sqlQueries]
```

**Filter init guard**: Trước khi localStorage restore xong (`filterInitialized = false`), `enabled = false` → KHÔNG gọi API. Nếu không có `filterStorageKey` (dashboardId/widgetId thiếu) → `filterInitialized = true` ngay (xem [widget-late-order-alert.tsx:812-816](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L812-L816)).

### 3.3 Client-side derive logic

> Tất cả memos ở [widget-late-order-alert.tsx:1018-1135](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L1018-L1135).

**statusBreakdown** (donut chart data):
```
Input: scorecard (8 numbers)
Output: 7 entries { status, count, color } theo BREAKDOWN_STATUS_ORDER
        [Normal, At risk, Late departure open, Late departure, Ontime departure, Ontime delivery, Late delivery]
```

**transporterBreakdown** (bar chart data):
```
Input: detailRowsSource (N DO-level rows)
Output: M entries { transporter, total, Normal?, At risk?, ... }
Logic:  group by transporter; với mỗi group, count rows theo alert status;
        nếu transporter empty → fallback "Không xác định" (unknownTransporter);
        sort by total desc
```

**detailTripRows** (table data, pre-sort):
```
Input: detailRowsSource (N DO-level rows)
Output: T trip-level rows (T <= N)
Logic:  group by trip (or "__tripless__{doCode}" nếu trip empty);
        với mỗi group, chọn 3 priority rows:
          - earliestEtaRow: sort by eta asc, tie-break doCode asc → base
          - alertPriorityRow: sort by getAlertPriority asc, tie-break mandatoryDepartAt asc, eta asc
          - nppPriorityRow: trong byEta (ETA asc), first row có salesChannel non-empty; nếu không có → fallback earliestEtaRow
        override fields:
          - alert, tripStatus, mandatoryDepartAt, alertSince, warehouse,
            deliveryArea, transporter, atdActual ← alertPriorityRow
          - salesChannel ← nppPriorityRow
          - eta, doCode, cargoGroup ← earliestEtaRow (base)
        warehouse → standardizeWarehouseName() (BKD1-3, NKD, VN821, VN831)
```

**sortedDetailRows** (table data, final):
```
Input: detailTripRows
Output: same rows, sort by getAlertPriority asc, tie-break trip alphabetical
```

### 3.4 Alert priority bảng

| Status | `getAlertPriority` value | Ý nghĩa |
|--------|--------------------------|---------|
| `Late departure open` | 0 | Critical — chưa rời kho và đã trễ |
| `Late departure` | 1 | High — đã rời kho trễ |
| `Late delivery` | 2 | High — đã giao trễ |
| `At risk` | 3 | Medium — sắp tới deadline |
| `Normal` | 4 | OK |
| `Ontime departure` | 5 | OK |
| `Ontime delivery` | 6 | OK |
| (unknown) | 7 | Fallback |

Priority được dùng cả ở **trip aggregation** (chọn DO đại diện) và **table default sort** (đẩy critical lên đầu).

---

## 4. Warehouse standardization

> [widget-late-order-alert.tsx:163-177](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L163-L177)

Function `standardizeWarehouseName()` được apply ở `detailTripRows` để chuẩn hoá tên kho. Logic:

```
Input → uppercase → remove all whitespace
  "BKD1", "BKD-1", "BINHDUONG1" → "BKD1"
  "BKD2", "BKD-2", "BINHDUONG2" → "BKD2"
  "BKD3", "BKD-3", "BINHDUONG3" → "BKD3"
  "NKD" → "NKD"
  "VN821" → "VN821"
  "VN831" → "VN831"
  others → raw value (unchanged trim only)
```

> ⚠ Hardcoded warehouse codes của Mondelez. Khi mở rộng sang tenant khác → cần config-driven (qua filter Settings hoặc SQL-side standardization).

---

## 5. Cấu trúc cột bảng chi tiết

> [widget-late-order-alert.columns.tsx](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.columns.tsx)

`gridKey = 'DSHLOAMNG01'` — `WidgetGrid` page size 20.

### 5.1 Cột visible-by-default (11 cột)

| Order | Column key | Label (i18n) | Type | Sortable | Filter | Đặc biệt |
|-------|------------|--------------|------|----------|--------|----------|
| 1 | `trip` | colTrip | string | yes | text | Render kèm badge `Mới nguy cơ trễ` (At risk) / `Mới trễ` (Late departure open) |
| 2 | `doCode` | colDoCode | string | yes | text | Mono font 11px |
| 3 | `tripStatus` | colTripStatus | string | — | multiselect | — |
| 4 | `mandatoryDepartAt` | colMandatoryDepart | datetime | yes | text | — |
| 5 | `alert` | colAlert | string | — | multiselect | Pill chip với màu theo status |
| 6 | `warehouse` | colWarehouse | string | — | multiselect | Centered, standardize |
| 7 | `deliveryArea` | colDeliveryArea | string | — | multiselect | — |
| 8 | `transporter` | colTransporter | string | — | multiselect | — |
| 9 | `atdActual` | colAtdActual | datetime | yes | text | — |
| 10 | `eta` | colEta | datetime | yes | text | — |
| 11 | `salesChannel` | colSalesChannel | string | — | multiselect | — |

### 5.2 Cột default-hidden (~50 cột)

Khi user toggle hiển thị, các cột này render kèm format vi-VN:
- `datetime` → mặc định format của `WidgetGrid`
- `number` (volume) → `value.toLocaleString('vi-VN')` (vd `1,234.56`)
- `string` (mono) → font-mono cho codes (`customerCode`, `maDoiTacNhan`, `soXe`, `maNhaXe`)

Xem [widget-late-order-alert.columns.tsx:154-686](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.columns.tsx#L154-L686) cho danh sách đầy đủ.

---

## 6. Settings Dialog contract

> [widget-late-order-alert-settings-dialog.tsx](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert-settings-dialog.tsx)

### 6.1 Config schema

```ts
interface LateOrderAlertSqlConfig extends SqlWidgetConfigBase {
  orderMonitorApiUrl?: string                    // deprecated, dùng dashboardV2Api
  queries?: Partial<LateOrderAlertSqlQueries>    // { scorecard, detail }
}
```

Config được serialize JSON và lưu vào `widget.config` qua `useUpdateV2Widget`.

### 6.2 Sections trong dialog

| Key | Label | Icon | Accent | Hint |
|-----|-------|------|--------|------|
| `scorecard` | Scorecard | LayoutGrid | emerald | "KPI tổng hợp các trạng thái cảnh báo" |
| `detail` | Detail | Table2 | amber | "Bảng chi tiết chuyến" |

Mỗi tab có Monaco SQL editor + nút "Test Query" + danh sách `requiredColumns` validator (xem §1.1 và §1.2).

### 6.3 Title/description dialog

- Title: `Late Order Alert Widget Settings`
- Description: `Configure SQL queries for the alert scorecard and trip detail table.`

---

## 7. Known anomalies & issues (locked for fix)

> Mỗi anomaly = bug/tech-debt phát hiện qua audit code+registry. Doc đã observe đúng hành vi hiện hành; entry dưới đây là **để track work cần làm**, KHÔNG phải gap trong doc. Status `LOCKED` = đã ghi nhận, chờ owner schedule fix.

### Severity scale

- **Critical** — sai số liệu, mất chức năng end-user
- **High** — tenant-coupling / khả năng mở rộng bị chặn
- **Medium** — validator/safety gap, dễ tạo bug downstream
- **Low** — UX / operational rough edge

### Anomaly registry

| ID | Title | Severity | Status | Owner | Evidence | Decision needed |
|----|-------|----------|--------|-------|----------|-----------------|
| **A1** | FE gửi `date_type='ETA gửi thầu'` (no suffix) nhưng registry CH SQL + MV + Mondelez runtime widget.config đều match `'ETA gửi thầu (đơn)'` (suffix `(đơn)`). Pattern lặp lại trên LOA + OTIF + Flash Daily. | **Critical** | ✅ **RESOLVED for LOA 2026-05-21**, ⏸ **LOCKED for OTIF/Flash Daily/api** | PM/DA | [widget-late-order-alert.tsx](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx) `DATE_TYPE_FALLBACK[1]` vs MV `mv_filter_date_type_alert.date_type_name` | PM decision 2026-05-21 "Vẫn giữ `(đơn)`" — LOA FE updated 1 dòng, 4-way coherent. Original Option B fix doc-claim (2026-05-19, drop 38 spots) thực tế không apply lên file — registry CH luôn giữ suffix. OTIF + Flash Daily + order-monitor-api.ts pending PM cleanup (separate effort). Tracked at [BUG-043 LOCKED](../../triage/bugs/cross-stack/%5BW%5D-BUG-043-late-order-alert-date-type-eta-gui-thau-mismatch.md). |
| **A2** | `requiredColumns` validator chỉ liệt kê 5/8 cột scorecard (thiếu `ontime_departure_cnt`, `ontime_delivery_cnt`, `late_delivery_cnt`) và 5/11 cột detail (thiếu `warehouse`, `delivery_area`, `transporter`, `atd_actual`, `eta`, `sales_channel`) | Medium | LOCKED | FE | [widget-late-order-alert-settings-dialog.tsx:36-81](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert-settings-dialog.tsx#L36-L81) | Backfill `anyOf` aliases cho 9 cột còn thiếu để bắt SQL config sai sớm |
| **A3** | Ngưỡng 45-min At-risk hardcode bên trong MV `mv_alert_late_do.alert_status` — không expose qua Settings | High | LOCKED | DA + BE | sql-registry §`Cảnh báo đơn trễ` — `alert_status` đến từ MV, widget SQL không tính lại | Mondelez: confirm 45 phút có phải standard không. Tenant khác: cần config |
| **A4** | `standardizeWarehouseName()` hardcode warehouse codes Mondelez (BKD1-3, NKD, VN821, VN831) trong FE code chung | High | LOCKED | FE | [widget-late-order-alert.tsx:163-177](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L163-L177) | Move sang SQL-side hoặc Settings filter override để widget không coupling tenant |
| **A5** | `ZERO_SCORECARD` fallback khi scorecard query trả 0 row — UI hiển thị 0 cho tất cả, không phân biệt "0 chuyến thật" vs "SQL config lỗi/empty" | Low | LOCKED | FE | [widget-late-order-alert.tsx:110-119](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L110-L119) | Thêm empty-state banner phân biệt 2 case |
| **A6** | FE `DATE_TYPE_OPTIONS` chỉ expose 2/8 nhánh registry CH hỗ trợ (ETD/ETA chuyến, ATD/ATA chuyến, request_date, approved_date không có ở UI) | Medium | LOCKED | FE + PM | [widget-late-order-alert.tsx:76-79](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L76-L79) vs sql-registry CH 8 branches | PM quyết: expose tất cả 8 option hay giữ chỉ 2 (theo nhu cầu Ops Mondelez) |
| **A7** | Filter `dateType` default = `Ngày gửi thầu` hardcode ở `DATE_TYPE_OPTIONS[0]` — không tenant-aware | Low | LOCKED | FE | [widget-late-order-alert.tsx:76-79](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L76-L79) | Khi cần multi-tenant, move default vào Settings |
| **A8** | i18n key `dateRangeOver2Years` ở namespace `orderMonitor.common` — có thể chỉ Late Order Alert dùng | Low | LOCKED | FE | [dashboard-order-monitor.json](../../../../frontend/src/i18n/locales/vi/dashboard-order-monitor.json) | Nếu chỉ widget này dùng → move vào `lateOrderAlert` namespace |
| **A9** | Button text `Setting Chart` / `Setting Filter` hardcoded ở [widget-late-order-alert.tsx:1112,1154](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L1112) — không qua i18n | Low | LOCKED (pattern-wide) | FE | line 1112 + 1154 | Pattern toàn module order-monitor — fix toàn cụm khi i18n-ize edit toolbar |

> **Critical priority**: A1 đứng đầu — silently trả về 0 khi user chọn "ETA gửi thầu" trên Mondelez CH stack. Cần fix trước v1.0 ship hoặc add migration note nếu đã ship.

---

## 8. Performance & limits

| Metric | Giá trị | Ghi chú |
|--------|---------|---------|
| Page size per request | 5000 | Hardcoded — đủ cho Mondelez ~1.5K trip/ngày |
| Stale time | 5 phút | Cache theo filter key |
| Số request song song | 2 | Scorecard + Detail |
| Số chart render | 2 (donut + bar) | Recharts |
| Number of rows in table | Max 5000 (DO-level) → aggregate về T trips | T phụ thuộc DO/trip ratio |
| Date range max | 2 năm (`MAX_DATE_RANGE_MS`) | Vượt → toast error, không apply |

---

## 9. Lịch sử thay đổi

| Version | Ngày | Tác giả | Thay đổi |
|---------|------|---------|---------|
| 1.0.0 | 2026-05-19 | PM/DA via `/da-trace` | Bản đầu tiên — Observed baseline. Document 2 SQL sections (scorecard 8 required cols + detail 11 visible + ~50 hidden), filter override binding (9 placeholders + 3 alias groups), runtime lifecycle (staleTime 5min, page 5000, autoApply), 7 alert status canonical SQL pattern (CASE expression), trip aggregation 3-priority rules, warehouse standardize hardcode list. Phát hiện 6 cross-doc consistency findings, finding #4 (requiredColumns thiếu 3/8 + 6/11 cột) cần backfill. |
| 1.0.1 | 2026-05-19 | PM/DA via `/ba-review` | Reconcile với codebase + `sql-registry.md`. §1.1 / §1.2: SQL canonical KHÔNG inline CASE — `alert_status` precompute trong MV `mv_alert_late_do`; widget chỉ COUNT theo column này. §2.1: liệt kê 8 nhánh date_type trong registry CH, đánh dấu drift FE↔registry. §7 restructure thành Known Anomalies & Issues — 9 anomaly có ID/severity/owner/evidence, LOCKED status. Phát hiện **A1 critical** (FE `'ETA gửi thầu'` ≠ registry CH `'ETA gửi thầu (đơn)'` → user chọn option này silently về 0). §3.3 NppPriorityRow định nghĩa chính xác theo `byEta`. |
| 1.0.2 | 2026-05-21 | PM/DA via `/reviewer + /tester + scope expansion T3.4` | (1) §2.1 rewrite — FE filter `dateType` chuyển từ hardcoded `DATE_TYPE_OPTIONS` array sang SQL-driven qua Filter Settings (resolves A6); bảng 8 BE-supported value đánh dấu rõ "Default" vs "Available — paste để expose". (2) §2.2 NEW — Canonical SQL template 3 variant (default 2-option, full 8-option, sorted với subquery wrap) + live-verified output trên CH `analytics_workspace` 2026-05-21 + curl test command cho admin verify trước paste. (3) Memory rule `feedback_sql_date_type_label_exact_match` reinforced trong header §2.1. |
| 1.0.3 | 2026-05-21 | PM/DA via PM correction | §2.2 REWRITE per PM feedback "đọc hiểu phong cách từ registry thay vì tự nghĩ ra" — hardcoded UNION SELECT replaced bằng canonical project pattern `SELECT FROM mv_filter_date_type_alert` (matches `mv_filter_warehouse` / `mv_filter_region` / `mv_filter_channel` / `mv_filter_vendor` / `mv_filter_cargo_brand` style). Widget `defaultSql` factory cũng đổi sang query MV. Phát hiện thêm BLOCKER §2.2.2: MV DDL chưa fix theo post-A1 (vẫn còn `'ETA gửi thầu (đơn)'` suffix) → BUG-043 cần thêm step 0 (MV DDL update) trước khi step 2 (admin paste post-A1 widget.config) safe để rollout. |
| 1.0.4 | 2026-05-21 | PM/DA via PM decision "Vẫn giữ ETA gửi thầu (đơn)" | §2.1 + §2.2.2 REWRITE — PM canonical = `'ETA gửi thầu (đơn)'` (MDLZ legacy). Verify live grep: registry CH variants đã có suffix 55/55 spots, MV đã có suffix, Mondelez runtime widget.config đã có suffix → 4-way coherent sau khi update 1-line FE (`DATE_TYPE_FALLBACK[1]`). Critical correction: BUG-043 Step 1 doc-claim "38 spots fixed" KHÔNG match file state thực tế — hoặc chưa từng apply hoặc đã bị revert; lesson learnt logged. NO ACTION required ngoài 1-line FE update (đã done). Cross-widget impact (OTIF + Flash Daily + order-monitor-api) vẫn pending PM extend decision. |
| 1.0.5 | 2026-05-22 | PM/DA | §22 NEW — Canonical SQL templates `scorecard` + `detail` + `groupedTable` để paste qua Settings dialog. SQL đã test live trên `analytics_workspace` (ngày test 2026-05-22). Pattern dùng `[[…]]` optional block của `WidgetFilterResolver` ([backend/Infrastructure/Services/Dashboard/WidgetFilterResolver.cs:108-131](../../../../backend/src/Smartlog.Infrastructure/Services/Dashboard/WidgetFilterResolver.cs#L108-L131)) thay vì `if(arraySort([{{whseid}}])=…)` registry pattern — registry pattern chỉ work khi FE gửi CSV full warehouse codes, hiện tại FE gửi `''` khi "ALL" → backend escape → `NULL` → registry pattern rớt zero rows. §1.1 + §1.2 cập nhật pointer sang §22, note caveat về VN aliases (registry detail SQL alias `so_chuyen AS "Số chuyến"` không match FE normalizer). §22.3 NEW: optional section `groupedTable` cho pre-aggregated rows (4 cột: warehouse, transporter, alert, count) — widget consume qua `computeLateAlertGroupedRowsFromPreAgg` nếu SQL set, fallback `computeLateAlertGroupedRows(detailRows)` nếu empty. Verified sum 195 trips (109 risk + 86 stable) khớp scorecard cùng window. |
| 1.0.6 | 2026-05-22 | PM/DA | §22.3 BEHAVIOR CHANGE — bỏ fallback "auto-derive từ Detail" khi groupedTable SQL trống. UI Settings là source of truth duy nhất cho bảng nhóm: paste SQL → có data, trống → table rỗng. Lý do: explicit > implicit, admin debug được logic group qua Test Query, scorecard/detail/groupedTable trở thành 3 SQL hoàn toàn độc lập. Widget memo bỏ branch `hasGroupedTableSql ? preAgg : legacy` → luôn `computeLateAlertGroupedRowsFromPreAgg(rows)`. Hàm `computeLateAlertGroupedRows` (legacy detail-rows variant) giữ trong utility cho test reference, KHÔNG còn consumer production. |

---

## 22. Canonical SQL templates (paste vào Settings dialog)

> **Mục đích**: 2 SQL dưới đây là **production-ready template** để tenant admin Mondelez paste vào Settings dialog (Setting Chart → chọn section → dán SQL → Save). Đã verify trên `analytics_workspace` (ClickHouse Cloud, 2026-05-22). Tenant khác phải adapt theo schema riêng (đặc biệt nếu chạy Redshift `reporting_schema.mv_alert_late_do` — alert_status mapping giống, nhưng placeholder substitution có thể khác).
>
> **Placeholder semantics** (xem `WidgetFilterResolver` source):
> - `{{name}}` (literal escape): empty → `NULL`; CSV `BKD1,BKD2` → `'BKD1', 'BKD2'`; single → `'value'`.
> - `[[ ... {{name}} ... ]]` (optional block): nếu BẤT KỲ placeholder trong block có giá trị empty/whitespace → cả block bị strip trước khi substitute. Đây là cách handle filter "ALL" đúng cho registry-style IN (...) pattern.
>
> **KHÔNG paste registry CH variant nguyên bản**:
> - Scorecard: registry dùng `if(arraySort([{{whseid}}]) = (SELECT arraySort(...) FROM mv_filter_warehouse), 1=1, t.whseid IN ({{whseid}}))` — verified 2026-05-22 trả về 0 rows khi `{{whseid}}=NULL` (FE gửi `''` cho ALL).
> - Detail: registry alias mọi cột sang VN display name (`so_chuyen AS "Số chuyến"`) → `normalizeDetailRowFromSql` không recognize → mọi field về empty.

### 22.1 Section `scorecard`

**Required output columns** (8, validator ở [widget-late-order-alert-settings-dialog.tsx:36-75](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert-settings-dialog.tsx#L36-L75)):
`tat_ca`, `normal_cnt`, `at_risk_cnt`, `late_departure_open_cnt`, `late_departure_cnt`, `ontime_departure_cnt`, `ontime_delivery_cnt`, `late_delivery_cnt`.

**Filter override placeholders consumed**: `{{whseid}}`, `{{region}}`, `{{sales_channel}}`, `{{transporter}}`, `{{date_type}}`, `{{from_date}}`, `{{to_date}}` (xem §2 cho mapping 9 alias từ FE).

```sql
WITH base AS (
  SELECT t.*
  FROM analytics_workspace.mv_alert_late_do t
  WHERE 1 = 1
    [[ AND t.whseid         IN ({{whseid}}) ]]
    [[ AND t.khu_vuc_doi_xe IN ({{region}}) ]]
    [[ AND t.group          IN ({{sales_channel}}) ]]
    [[ AND t.ten_ngan_nvt   IN ({{transporter}}) ]]
    AND toDate(CASE
          WHEN {{date_type}} = 'ETA gửi thầu (đơn)'              THEN t.eta_giao_hang_cho_npp
          WHEN {{date_type}} = 'Ngày gửi thầu'                    THEN t.thoi_gian_gui_thau
          WHEN {{date_type}} = 'ETD chuyến - ngày dự kiến lấy hàng' THEN t.etd_chuyen
          WHEN {{date_type}} = 'ETA chuyến - ngày dự kiến giao hàng' THEN t.eta_chuyen
          WHEN {{date_type}} = 'Ngày gửi yêu cầu đơn hàng'        THEN t.request_date
          WHEN {{date_type}} = 'ATD chuyến - ngày thực tế lấy hàng' THEN t.atd_chuyen
          WHEN {{date_type}} = 'ATA chuyến - ngày thực tế giao hàng' THEN t.ata_chuyen
          WHEN {{date_type}} = 'Ngày duyệt chuyến'                THEN t.approved_date
          ELSE t.eta_giao_hang_cho_npp
        END)
        BETWEEN toDate(coalesce({{from_date}}, '1970-01-01'))
            AND toDate(coalesce({{to_date}},   '2106-02-07'))
)
SELECT
  COUNT(DISTINCT so_chuyen) AS tat_ca,
  COUNT(DISTINCT CASE WHEN alert_status = 'Normal'              THEN so_chuyen END) AS normal_cnt,
  COUNT(DISTINCT CASE WHEN alert_status = 'At risk'             THEN so_chuyen END) AS at_risk_cnt,
  COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
  COUNT(DISTINCT CASE WHEN alert_status = 'Late departure'      THEN so_chuyen END) AS late_departure_cnt,
  COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure'    THEN so_chuyen END) AS ontime_departure_cnt,
  COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery'     THEN so_chuyen END) AS ontime_delivery_cnt,
  COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery'       THEN so_chuyen END) AS late_delivery_cnt
FROM base
```

**Verified output** (CH `analytics_workspace`, 2026-05-22, filter range 2026-05-15 → 2026-05-22, ALL warehouses):

```
tat_ca  normal_cnt  at_risk_cnt  late_departure_open_cnt  late_departure_cnt  ontime_departure_cnt  ontime_delivery_cnt  late_delivery_cnt
685     0           0            4                        1                   12                    244                  424
```

**Verified single-filter** (whseid='BKD1', cùng date range): `tat_ca=394, late_delivery_cnt=219`.

**Verified multi-CSV** (whseid='BKD1,NKD,VN821'): `tat_ca=638` (VN821 no data trong window).

**Date range limits**: `toDate('1970-01-01')` → `1970-01-01`; `toDate('2106-02-07')` → `2106-02-07` (CH `Date` type bounds). Empty placeholder `{{from_date}}` → backend → `NULL` → `coalesce(NULL, '1970-01-01')` → `'1970-01-01'`. KHÔNG dùng `'1900-01-01'`/`'2999-12-31'` như registry — CH clamp về 1970/2149 silently.

### 22.2 Section `detail`

**Required output columns** (11, validator ở [widget-late-order-alert-settings-dialog.tsx:84-117](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert-settings-dialog.tsx#L84-L117)):
`trip`, `do_code`, `trip_status`, `mandatory_depart_at`, `alert`, `warehouse`, `delivery_area`, `transporter`, `atd_actual`, `eta`, `sales_channel`.

**Optional output columns** (default-hidden — admin enable qua column toggle): cargo_group + ~50 cột detail (Identity / status, Time fields, Vehicle, Quantities original/shipped/delivered, Diff, Durations, Other times, Distance). Xem §5 cho danh sách đầy đủ.

**Aliasing required**: 5 cột MV phải alias sang English name để validator + `normalizeDetailRowFromSql` recognize:
- `so_chuyen AS trip`
- `ds_ma_don_trong_chuyen AS do_code`
- `trang_thai_chuyen AS trip_status` (FE candidates đã include raw alias nhưng validator chỉ check `trip_status*`)
- `tg_bat_buoc_roi_kho AS mandatory_depart_at`
- `alert_status AS alert`
- `whseid AS warehouse`
- `khu_vuc_doi_xe AS delivery_area`
- `ten_ngan_nvt AS transporter`
- `gio_ra_cong AS atd_actual`
- `eta_giao_hang_cho_npp AS eta`
- `group AS sales_channel`
- `group_of_cago AS cargo_group` (optional — FE field; lưu ý MV typo `cago`)

```sql
SELECT
  so_chuyen                AS trip,
  ds_ma_don_trong_chuyen   AS do_code,
  trang_thai_chuyen        AS trip_status,
  tg_bat_buoc_roi_kho      AS mandatory_depart_at,
  alert_status             AS alert,
  group_of_cago            AS cargo_group,
  whseid                   AS warehouse,
  khu_vuc_doi_xe           AS delivery_area,
  ten_ngan_nvt             AS transporter,
  gio_ra_cong              AS atd_actual,
  eta_giao_hang_cho_npp    AS eta,
  group                    AS sales_channel,
  trang_thai_chuyen_stm,
  customer_code,
  customer_name,
  ma_doi_tac_nhan,
  ten_doi_tac_nhan,
  thoi_gian_gui_thau,
  ngay_tao_chuyen,
  etd_chuyen_gui_thau,
  gio_dang_tai,
  gio_goi_xe,
  gio_vao_cong,
  gio_vao_dock,
  actual_ship_date,
  gio_ra_dock,
  ata_den,
  ata_roi,
  so_xe,
  tai_xe,
  ma_nha_xe,
  sum_original,
  sum_original_cbm,
  sum_original_kg,
  sum_original_cse,
  sum_original_pl,
  sum_shipped,
  sum_shipped_cbm,
  sum_shipped_kg,
  sum_shipped_cse,
  sum_shipped_pl,
  sum_san_luong_giao,
  sum_san_luong_giao_cbm,
  sum_san_luong_giao_kg,
  sum_san_luong_giao_cse,
  sum_san_luong_giao_pl,
  diff_sl_giao_cho,
  diff_sl_giao_cho_cbm,
  diff_sl_giao_cho_kg,
  diff_sl_giao_cho_cse,
  diff_sl_giao_cho_pl,
  total_time_in_warehouse_minute,
  total_time_loading_minute,
  diff_delivery_time_hour,
  phut_tre_roi_kho,
  phut_tre_giao_npp,
  ly_do_tre_hoan_thanh,
  etd_chuyen,
  eta_chuyen,
  ata_chuyen,
  atd_chuyen,
  request_date,
  approved_date,
  so_km,
  van_toc
FROM analytics_workspace.mv_alert_late_do t
WHERE 1 = 1
  [[ AND t.whseid         IN ({{whseid}}) ]]
  [[ AND t.khu_vuc_doi_xe IN ({{region}}) ]]
  [[ AND t.group          IN ({{sales_channel}}) ]]
  [[ AND t.ten_ngan_nvt   IN ({{transporter}}) ]]
  AND toDate(CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'              THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'Ngày gửi thầu'                    THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'ETD chuyến - ngày dự kiến lấy hàng' THEN t.etd_chuyen
        WHEN {{date_type}} = 'ETA chuyến - ngày dự kiến giao hàng' THEN t.eta_chuyen
        WHEN {{date_type}} = 'Ngày gửi yêu cầu đơn hàng'        THEN t.request_date
        WHEN {{date_type}} = 'ATD chuyến - ngày thực tế lấy hàng' THEN t.atd_chuyen
        WHEN {{date_type}} = 'ATA chuyến - ngày thực tế giao hàng' THEN t.ata_chuyen
        WHEN {{date_type}} = 'Ngày duyệt chuyến'                THEN t.approved_date
        ELSE t.eta_giao_hang_cho_npp
      END)
      BETWEEN toDate(coalesce({{from_date}}, '1970-01-01'))
          AND toDate(coalesce({{to_date}},   '2106-02-07'))
ORDER BY eta_giao_hang_cho_npp DESC, so_chuyen
```

**Verified output** (CH `analytics_workspace`, 2026-05-22, whseid='BKD1', range 2026-05-21 → 2026-05-22, LIMIT 3): trả về full 65 cột (12 alias + 53 raw snake_case) — sample first row `trip=DI0206607, alert='Ontime delivery', warehouse=BKD1, transporter='ANH SON', cargo_group=FRESH, sum_original=33015, …`. `normalizeDetailRowFromSql` map đúng vào `LateOrderAlertDetailRow`.

**Pagination**: Backend gắn `LIMIT 5000` từ `pageSize` argument ([widget-late-order-alert.tsx:943-947](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L943-L947)); ORDER BY trong SQL đảm bảo deterministic page khi data overflow. KHÔNG embed `LIMIT` trong SQL — sẽ bị backend strip qua `sanitizeSqlForTest`.

### 22.3 Section `groupedTable` (SQL-only source — không fallback)

**Mục đích**: Pre-aggregated rows cho bảng nhóm 3 cấp Kho → NVT → Trạng thái. **Section này là source of truth duy nhất**: để trống ⇒ bảng nhóm rỗng (KHÔNG tự derive từ `detail` nữa). Paste SQL ⇒ widget consume rows.

Trade-off: bảng nhóm trở thành **explicit** — admin phải paste SQL khi rollout widget. Đổi lại được:
- Giảm payload (vài chục row thay vì 5000+)
- Debug logic group qua nút **Test Query** trong Settings dialog (admin có thể inspect rows trước khi save)
- Tách concern hoàn toàn: scorecard (KPI) / detail (table chi tiết) / groupedTable (bảng nhóm) — 3 SQL độc lập, sửa MV hoặc filter không ảnh hưởng nhau

**Required output columns** (4, validator ở [widget-late-order-alert-settings-dialog.tsx:121-133](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert-settings-dialog.tsx#L121-L133)):

| Logical name | anyOf aliases | Mục đích |
|--------------|---------------|----------|
| `warehouse` | `warehouse`, `whseid` | Khóa group L0 (qua `standardizeWarehouseName()`) |
| `transporter` | `transporter`, `ten_ngan_nvt`, `tenngannvt`, `tenNganNvt` | Khóa group L1 |
| `alert` | `alert`, `alert_status`, `alertstatus`, `alertStatus` | Khóa group L2 (filter qua 7-leaf taxonomy) |
| `count` | `count`, `cnt`, `total_count`, `totalCount` | Số chuyến cho tuple (warehouse, transporter, alert) |

**Shape**: N rows (mỗi tuple 1 row). Mondelez 1-day window điển hình ≈20 rows. Empty result → bảng nhóm rỗng.

**Filter override placeholders consumed**: giống §22.1 — same 7 placeholders (`{{whseid}}`, `{{region}}`, `{{sales_channel}}`, `{{transporter}}`, `{{date_type}}`, `{{from_date}}`, `{{to_date}}`).

```sql
SELECT
  whseid                    AS warehouse,
  ten_ngan_nvt              AS transporter,
  alert_status              AS alert,
  COUNT(DISTINCT so_chuyen) AS count
FROM analytics_workspace.mv_alert_late_do t
WHERE 1 = 1
  [[ AND t.whseid         IN ({{whseid}}) ]]
  [[ AND t.khu_vuc_doi_xe IN ({{region}}) ]]
  [[ AND t.group          IN ({{sales_channel}}) ]]
  [[ AND t.ten_ngan_nvt   IN ({{transporter}}) ]]
  AND toDate(CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'              THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'Ngày gửi thầu'                    THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'ETD chuyến - ngày dự kiến lấy hàng' THEN t.etd_chuyen
        WHEN {{date_type}} = 'ETA chuyến - ngày dự kiến giao hàng' THEN t.eta_chuyen
        WHEN {{date_type}} = 'Ngày gửi yêu cầu đơn hàng'        THEN t.request_date
        WHEN {{date_type}} = 'ATD chuyến - ngày thực tế lấy hàng' THEN t.atd_chuyen
        WHEN {{date_type}} = 'ATA chuyến - ngày thực tế giao hàng' THEN t.ata_chuyen
        WHEN {{date_type}} = 'Ngày duyệt chuyến'                THEN t.approved_date
        ELSE t.eta_giao_hang_cho_npp
      END)
      BETWEEN toDate(coalesce({{from_date}}, '1970-01-01'))
          AND toDate(coalesce({{to_date}},   '2106-02-07'))
GROUP BY whseid, ten_ngan_nvt, alert_status
ORDER BY whseid, ten_ngan_nvt, alert_status
```

**Verified output** (CH `analytics_workspace`, 2026-05-22, ALL filters, range 2026-05-21 → 2026-05-22):

```
warehouse  transporter  alert                count
BKD1       ANH SON      Late delivery        35
BKD1       ANH SON      Ontime delivery      38
BKD1       ANH SON      Ontime departure     7
BKD1       HOA PHAT     Ontime delivery      3
BKD1       HVP          Late delivery        1
...
```

**Verified totals** (cross-check với §22.1 scorecard cùng window):

| Metric | Value |
|--------|-------|
| `SUM(count)` total | 195 |
| `SUM(count) WHERE alert IN ('Late departure open','Late delivery','At risk','Late departure')` | 109 risk |
| `SUM(count) WHERE alert IN ('Ontime departure','Ontime delivery','Normal')` | 86 stable |

**Widget consumption**: widget LUÔN chạy `computeLateAlertGroupedRowsFromPreAgg(rows, …)` ([utils/compute-late-alert-grouped-rows.ts](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/utils/compute-late-alert-grouped-rows.ts)). Khi SQL trống → `rows = []` → table rỗng (empty state "Không có chuyến nào khớp với bộ lọc hiện tại"). Function `computeLateAlertGroupedRows` (legacy nhận `LateOrderAlertDetailRow[]`) vẫn còn trong utility nhưng KHÔNG còn consumer trong widget — giữ để các unit test hiện tại pass + làm reference cho client-derive pattern.

### 22.4 Test command (admin verify trước paste)

```bash
# Scorecard
curl -s --user "$CLICKHOUSE_USER:$CLICKHOUSE_PASSWORD" \
  -H "Content-Type: text/plain" \
  --data-binary @<(sed 's/\[\[.*\]\]//g; s/{{date_type}}/'\''ETA gửi thầu (đơn)'\''/g; s/{{from_date}}/'\''2026-05-15 00:00:00'\''/g; s/{{to_date}}/'\''2026-05-22 23:59:59'\''/g' projects/mondelez/01-sections/late-order-alert/scorecard.sql) \
  "https://$CLICKHOUSE_HOST:8443/?database=analytics_workspace&default_format=PrettyCompactMonoBlock"
```

Admin chú ý: lệnh sed phía trên strip `[[...]]` (simulate empty filters) và substitute date placeholders. Khi paste vào Settings dialog production, backend handle `[[...]]` + `{{...}}` tự động.

Trong UI Settings dialog: nút **Test Query** sau khi paste SQL sẽ chạy substituted-form + render kết quả ngay tab dialog — cách debug khuyến nghị cho admin.

### 22.5 Out-of-scope cho §22

- **Redshift variant**: §22 chỉ document CH (Mondelez stack). Redshift tenant (nếu có) cần adapt: thay `{{...}}` bằng SqlKata named param `@p_xxx`, `coalesce` thay bằng RS-compatible `COALESCE`, `toDate` thay `CAST(... AS DATE)`. Xem registry RS variant làm baseline rồi adapt theo backend resolver behavior tenant đó.
- **Threshold At-risk 45 phút**: hardcode trong MV `mv_alert_late_do.alert_status` (xem §7 A3). Chỉnh threshold = chỉnh MV DDL, KHÔNG paste qua Settings.
