-- ============================================================================
-- C02 _psv-by-vendor — Phân tích theo nhà vận tải
-- ============================================================================
-- name: C02_psv-by-vendor
-- source: analytics_workspace.mv_psv_main
-- params: window = 6 tháng gần đây (chỉnh ở dòng WHERE nếu cần)
-- purpose: So sánh hiệu năng các nhà vận tải — số chuyến, ton/CBM share,
--          chi phí trung bình mỗi chuyến / mỗi km, % vi phạm ràng buộc.
-- expected_shape: 1 row / vendor, sort theo total_cost giảm dần
-- ============================================================================

WITH window_data AS
(
    SELECT *
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= now('Asia/Ho_Chi_Minh') - INTERVAL 6 MONTH
      AND vendor_name != ''
)
SELECT
    vendor_name,

    uniqExact(tracking_id)                                              AS trips,
    sum(total_order)                                                    AS orders,
    sum(total_delivery)                                                 AS deliveries,
    round(sum(total_ton), 1)                                            AS ton,
    round(sum(total_cbm), 1)                                            AS cbm,
    round(sum(total_cost), 0)                                           AS total_cost_vnd,
    round(sum(total_cost) / nullIf(uniqExact(tracking_id), 0), 0)       AS avg_cost_per_trip,

    -- % chuyến vi phạm ràng buộc
    round(100.0 * countIf(constraint_name != '') / count(), 2)          AS pct_constraint_violations,
    -- % chuyến điều chỉnh route (manual adjust)
    round(100.0 * uniqExactIf(tracking_id, status_name_detail = 'Chuyến điều chỉnh route')
                / nullIf(uniqExact(tracking_id), 0), 2)                 AS pct_adjusted,

    -- Đa dạng loại xe vendor dùng
    uniqExact(group_of_vehicle_code)                                    AS distinct_vehicle_types,
    uniqExact(vehicle_no)                                               AS distinct_vehicles

FROM window_data
GROUP BY vendor_name
HAVING trips >= 5  -- bỏ vendor quá nhỏ (noise)
ORDER BY total_cost_vnd DESC
LIMIT 50
FORMAT PrettyCompactMonoBlock;
