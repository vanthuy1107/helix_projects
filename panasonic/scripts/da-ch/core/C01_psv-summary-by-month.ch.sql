-- ============================================================================
-- C01 _psv-summary-by-month — Tổng quan PSV theo tháng
-- ============================================================================
-- name: C01_psv-summary-by-month
-- source: analytics_workspace.mv_psv_main (UI-facing, đã UTC+7, filter sạch)
-- purpose: Báo cáo tổng quan theo tháng — số chuyến, % chuyến điều chỉnh route,
--          tổng đơn / điểm giao, tổng tấn / CBM, tổng chi phí dự kiến.
-- expected_shape: 1 row / tháng, sort theo tháng giảm dần (mới nhất trên)
-- ============================================================================
-- Output cột:
--   month                       — YYYY-MM
--   total_trips                 — Số chuyến (unique tracking_id)
--   trips_created               — Chuyến tạo mới
--   trips_adjusted              — Chuyến điều chỉnh route
--   pct_adjusted                — % chuyến điều chỉnh
--   total_orders                — Tổng đơn (sum)
--   total_deliveries            — Tổng điểm giao
--   total_ton                   — Tấn
--   total_cbm                   — m³
--   total_cost_vnd              — VND tổng chi phí
--   avg_cost_per_trip           — VND / chuyến
--   distinct_vendors            — Số nhà vận tải
--   distinct_vehicles           — Số đầu xe
-- ============================================================================

SELECT
    formatDateTime(toStartOfMonth(created_date), '%Y-%m')              AS month,

    uniqExact(tracking_id)                                              AS total_trips,
    uniqExactIf(tracking_id, status_name_detail = 'Chuyến tạo mới')     AS trips_created,
    uniqExactIf(tracking_id, status_name_detail = 'Chuyến điều chỉnh route') AS trips_adjusted,

    round(100.0 * uniqExactIf(tracking_id, status_name_detail = 'Chuyến điều chỉnh route')
                / nullIf(uniqExact(tracking_id), 0), 2)                 AS pct_adjusted,

    sum(total_order)                                                    AS total_orders,
    sum(total_delivery)                                                 AS total_deliveries,
    round(sum(total_ton), 2)                                            AS total_ton,
    round(sum(total_cbm), 2)                                            AS total_cbm,
    round(sum(total_cost), 0)                                           AS total_cost_vnd,
    round(sum(total_cost) / nullIf(uniqExact(tracking_id), 0), 0)       AS avg_cost_per_trip,

    uniqExact(vendor_name)                                              AS distinct_vendors,
    uniqExact(vehicle_no)                                               AS distinct_vehicles

FROM analytics_workspace.mv_psv_main
WHERE created_date IS NOT NULL
GROUP BY month
ORDER BY month DESC
LIMIT 24
FORMAT PrettyCompactMonoBlock;
