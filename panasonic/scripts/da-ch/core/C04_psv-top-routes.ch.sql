-- ============================================================================
-- C04 _psv-top-routes — Top tuyến đường vận tải (location_from → location_to)
-- ============================================================================
-- name: C04_psv-top-routes
-- source: analytics_workspace.mv_psv_main
-- params: window = 6 tháng gần đây
-- purpose: Liệt kê các cặp điểm nhận → điểm giao có khối lượng lớn nhất.
--          Trả lời: tuyến nào đang chiếm % tải chính? Có route nào chi phí/tấn cao bất thường?
-- expected_shape: 1 row / cặp (from_code, to_code), sort theo total_ton giảm dần
-- ============================================================================
-- Cảnh báo: 1 chuyến có thể có nhiều order_code → tuyến này dựa trên (from→to) ở row-level,
-- thường là từng leg của chuyến, không phải tổng hành trình chuyến.

WITH window_data AS
(
    SELECT *
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= now('Asia/Ho_Chi_Minh') - INTERVAL 6 MONTH
      AND location_from_code != ''
      AND location_to_code != ''
)
SELECT
    location_from_code                                              AS from_code,
    location_to_code                                                AS to_code,

    count()                                                         AS legs,           -- rows
    uniqExact(tracking_id)                                          AS trips,
    sum(total_order)                                                AS orders,
    round(sum(total_ton), 1)                                        AS ton,
    round(sum(total_cbm), 1)                                        AS cbm,
    round(sum(total_cost), 0)                                       AS total_cost_vnd,
    round(sum(total_cost) / nullIf(sum(total_ton), 0), 0)           AS cost_per_ton,
    uniqExact(vendor_name)                                          AS vendors_running,
    uniqExact(group_of_vehicle_code)                                AS vehicle_types_used

FROM window_data
GROUP BY from_code, to_code
HAVING ton >= 5  -- bỏ tuyến quá lẻ
ORDER BY ton DESC
LIMIT 50
FORMAT PrettyCompactMonoBlock;
