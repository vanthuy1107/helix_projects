-- ============================================================================
-- C03 _psv-by-vehicle-type — Sử dụng theo loại xe / khung xe
-- ============================================================================
-- name: C03_psv-by-vehicle-type
-- source: analytics_workspace.mv_psv_main
-- params: window = 6 tháng gần đây
-- purpose: Đo mức độ sử dụng + utilization (% capacity) theo loại xe.
--          Phát hiện loại xe đang dùng dư hoặc thiếu (avg_load_ratio).
-- expected_shape: 1 row / (group_of_vehicle_code, group_of_vehicle_size)
-- ============================================================================
-- Output cột:
--   vehicle_code / vehicle_name / size
--   trips                — số chuyến dùng loại xe này
--   total_ton, total_cbm
--   avg_ton_per_trip, avg_cbm_per_trip
--   max_weight (capacity), max_capacity (CBM)
--   load_ratio_weight    — % avg ton / max_weight  ← <60% là under-utilized
--   load_ratio_volume    — % avg cbm / max_capacity
--   avg_cost_per_trip
--   distinct_vendors_using
-- ============================================================================

WITH window_data AS
(
    SELECT *
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= now('Asia/Ho_Chi_Minh') - INTERVAL 6 MONTH
      AND group_of_vehicle_code != ''
)
SELECT
    group_of_vehicle_code                                   AS vehicle_code,
    any(group_of_vehicle_name)                              AS vehicle_name,
    group_of_vehicle_size                                   AS size,

    uniqExact(tracking_id)                                  AS trips,
    round(sum(total_ton), 1)                                AS total_ton_t,
    round(sum(total_cbm), 1)                                AS total_cbm_m3,

    round(sum(total_ton) / nullIf(uniqExact(tracking_id), 0), 2)  AS avg_ton_per_trip,
    round(sum(total_cbm) / nullIf(uniqExact(tracking_id), 0), 2)  AS avg_cbm_per_trip,

    round(any(max_weight), 1)                               AS max_weight_ton,
    round(any(max_capacity), 1)                             AS max_capacity_cbm,

    round(100.0 * sum(total_ton) / nullIf(uniqExact(tracking_id) * any(max_weight), 0), 1)
                                                            AS load_ratio_weight_pct,
    round(100.0 * sum(total_cbm) / nullIf(uniqExact(tracking_id) * any(max_capacity), 0), 1)
                                                            AS load_ratio_volume_pct,

    round(sum(total_cost) / nullIf(uniqExact(tracking_id), 0), 0)  AS avg_cost_per_trip,
    uniqExact(vendor_name)                                  AS distinct_vendors_using

FROM window_data
GROUP BY group_of_vehicle_code, group_of_vehicle_size
ORDER BY trips DESC
LIMIT 50
FORMAT PrettyCompactMonoBlock;
