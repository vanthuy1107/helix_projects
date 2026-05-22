-- ============================================================================
-- C00 _profile-tenant — Mondelez ClickHouse analytics_workspace
-- ============================================================================
-- name: C00_profile-tenant
-- params: (none — DB hardcoded analytics_workspace, set in connection URL)
-- flavor: clickhouse
-- schema_deps: 16 leaf KPI MVs in analytics_workspace (see catalog below)
-- maps_to_lens: #0 Profile (sanity check before trusting any pulse number)
-- last_verified: 2026-05-10  (helix user, ClickHouse 25.12.1.1497)
-- expected_shape: 1 row per leaf MV with: mv, time_col, rows, min_d, max_d, lag_days, status
-- status values:
--   FRESH    — lag <= 1 day  (data through yesterday or today)
--   OK       — lag 2 days
--   LAGGING  — lag 3-7 days  (warn — pipeline may be slow)
--   STALE    — lag > 7 days  (BLOCK — do not trust pulse numbers from this MV)
--   EMPTY    — 0 rows with non-null time  (BLOCK — MV broken or unused)
-- ============================================================================
-- Usage (PowerShell, .env in projects/mondelez/.env):
--   $body = Get-Content -Raw projects/mondelez/scripts/da-ops/core/C00_profile-tenant.ch.sql
--   Invoke-RestMethod -Method Post -Body $body `
--     -Uri "https://$env:CLICKHOUSE_HOST:8443/?database=analytics_workspace&default_format=PrettyCompactMonoBlock" `
--     -Headers @{ Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$env:CLICKHOUSE_USER:$env:CLICKHOUSE_PASSWORD"))) " }
-- Or curl:
--   curl --user "$CH_USER:$CH_PASS" -H "Content-Type: text/plain" \
--     --data-binary @C00_profile-tenant.ch.sql \
--     "https://$CH_HOST:8443/?database=analytics_workspace&default_format=PrettyCompactMonoBlock"
-- ============================================================================
-- Canonical time column per leaf MV (chosen as the primary business event time):
--   mv_otif                          actual_ship_date     OTIF measured at ship
--   mv_outbound_transaction_raw      actual_ship_date     DO outbound (raw, Date type)
--   mv_outbound_transaction_base     transaction_date     DO outbound (aggregated)
--   mv_inbound_transaction_base      transaction_date     DO inbound
--   mv_movement_transaction          transaction_date     internal movement
--   mv_alert_late_do                 actual_ship_date     late DO alert
--   mv_alert_swm_data                actual_ship_date     SWM-side alerts
--   mv_dap_ung_van_hanh              etd_chuyen           response measured vs ETD
--   mv_dap_ung_gui_thau              tender_date          tendering response
--   mv_vfr_van_hanh                  etd_vh               vehicle fill rate (ops)
--   mv_vfr_gui_thau                  tender_date          vehicle fill rate (tender)
--   mv_flash_report                  actual_ship_date     daily flash
--   mv_dropped_report                actual_ship_date     dropped DO (planned ship)
--   mv_transfer_in_out               date_transfer        inter-warehouse transfer
--   mv_copack                        date_in_out          copacking in/out
--   mv_wh_utilization                lottable04           lot tracking date (best guess)
-- ============================================================================

SELECT
  mv,
  time_col,
  rows,
  min_d,
  max_d,
  lag_days,
  multiIf(
    rows = 0,         'EMPTY',
    lag_days > 7,     'STALE',
    lag_days > 2,     'LAGGING',
    lag_days <= 1,    'FRESH',
                      'OK'
  ) AS status
FROM
(
  SELECT 'mv_otif' AS mv, 'actual_ship_date' AS time_col, count() AS rows,
         toString(toDate(min(actual_ship_date))) AS min_d,
         toString(toDate(max(actual_ship_date))) AS max_d,
         dateDiff('day', toDate(max(actual_ship_date)), toDate(now('Asia/Ho_Chi_Minh'))) AS lag_days
  FROM mv_otif WHERE actual_ship_date IS NOT NULL

  UNION ALL
  SELECT 'mv_outbound_transaction_raw', 'actual_ship_date', count(),
         toString(min(actual_ship_date)),
         toString(max(actual_ship_date)),
         dateDiff('day', max(actual_ship_date), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_outbound_transaction_raw

  UNION ALL
  SELECT 'mv_outbound_transaction_base', 'transaction_date', count(),
         toString(toDate(min(transaction_date))),
         toString(toDate(max(transaction_date))),
         dateDiff('day', toDate(max(transaction_date)), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_outbound_transaction_base WHERE transaction_date IS NOT NULL

  UNION ALL
  SELECT 'mv_inbound_transaction_base', 'transaction_date', count(),
         toString(toDate(min(transaction_date))),
         toString(toDate(max(transaction_date))),
         dateDiff('day', toDate(max(transaction_date)), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_inbound_transaction_base WHERE transaction_date IS NOT NULL

  UNION ALL
  SELECT 'mv_movement_transaction', 'transaction_date', count(),
         toString(toDate(min(transaction_date))),
         toString(toDate(max(transaction_date))),
         dateDiff('day', toDate(max(transaction_date)), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_movement_transaction WHERE transaction_date IS NOT NULL

  UNION ALL
  SELECT 'mv_alert_late_do', 'actual_ship_date', count(),
         toString(toDate(min(actual_ship_date))),
         toString(toDate(max(actual_ship_date))),
         dateDiff('day', toDate(max(actual_ship_date)), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_alert_late_do WHERE actual_ship_date IS NOT NULL

  UNION ALL
  SELECT 'mv_alert_swm_data', 'actual_ship_date', count(),
         toString(toDate(min(actual_ship_date))),
         toString(toDate(max(actual_ship_date))),
         dateDiff('day', toDate(max(actual_ship_date)), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_alert_swm_data WHERE actual_ship_date IS NOT NULL

  UNION ALL
  SELECT 'mv_dap_ung_van_hanh', 'etd_chuyen', count(),
         toString(toDate(min(etd_chuyen))),
         toString(toDate(max(etd_chuyen))),
         dateDiff('day', toDate(max(etd_chuyen)), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_dap_ung_van_hanh WHERE etd_chuyen IS NOT NULL

  UNION ALL
  SELECT 'mv_dap_ung_gui_thau', 'tender_date', count(),
         toString(toDate(min(tender_date))),
         toString(toDate(max(tender_date))),
         dateDiff('day', toDate(max(tender_date)), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_dap_ung_gui_thau WHERE tender_date IS NOT NULL

  UNION ALL
  SELECT 'mv_vfr_van_hanh', 'etd_vh', count(),
         toString(toDate(min(etd_vh))),
         toString(toDate(max(etd_vh))),
         dateDiff('day', toDate(max(etd_vh)), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_vfr_van_hanh WHERE etd_vh IS NOT NULL

  UNION ALL
  SELECT 'mv_vfr_gui_thau', 'tender_date', count(),
         toString(toDate(min(tender_date))),
         toString(toDate(max(tender_date))),
         dateDiff('day', toDate(max(tender_date)), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_vfr_gui_thau WHERE tender_date IS NOT NULL

  UNION ALL
  SELECT 'mv_flash_report', 'actual_ship_date', count(),
         toString(toDate(min(actual_ship_date))),
         toString(toDate(max(actual_ship_date))),
         dateDiff('day', toDate(max(actual_ship_date)), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_flash_report WHERE actual_ship_date IS NOT NULL

  UNION ALL
  SELECT 'mv_dropped_report', 'actual_ship_date', count(),
         toString(toDate(min(actual_ship_date))),
         toString(toDate(max(actual_ship_date))),
         dateDiff('day', toDate(max(actual_ship_date)), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_dropped_report WHERE actual_ship_date IS NOT NULL

  UNION ALL
  SELECT 'mv_transfer_in_out', 'date_transfer', count(),
         toString(min(date_transfer)),
         toString(max(date_transfer)),
         dateDiff('day', max(date_transfer), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_transfer_in_out WHERE date_transfer IS NOT NULL

  UNION ALL
  SELECT 'mv_copack', 'date_in_out', count(),
         toString(min(date_in_out)),
         toString(max(date_in_out)),
         dateDiff('day', max(date_in_out), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_copack

  UNION ALL
  SELECT 'mv_wh_utilization', 'lottable04', count(),
         toString(toDate(min(lottable04))),
         toString(toDate(max(lottable04))),
         dateDiff('day', toDate(max(lottable04)), toDate(now('Asia/Ho_Chi_Minh')))
  FROM mv_wh_utilization WHERE lottable04 IS NOT NULL
)
ORDER BY
  multiIf(status = 'EMPTY', 0, status = 'STALE', 1, status = 'LAGGING', 2, status = 'OK', 3, 4),
  lag_days DESC,
  mv
;
