-- ============================================================================
-- C05 _psv-adjustments-and-constraints — Phân tích điều chỉnh + vi phạm ràng buộc
-- ============================================================================
-- name: C05_psv-adjustments-and-constraints
-- source: analytics_workspace.mv_psv_main
-- params: window = 6 tháng gần đây
-- purpose: Trả lời 2 câu hỏi (gộp UNION ALL vì HTTP API không cho multi-statement):
--          1. User hay điều chỉnh chuyến vì lý do gì?  (group=reason_change)
--          2. Thuật toán hay vi phạm ràng buộc nào nhất?  (group=constraint_name)
-- expected_shape: top 20 mỗi group, sort theo group rồi trips_affected DESC
-- ============================================================================

WITH window_data AS
(
    SELECT
        tracking_id,
        reason_change,
        constraint_name,
        total_order,
        total_ton,
        is_trip_edit_manual
    FROM analytics_workspace.mv_psv_main
    WHERE created_date >= now('Asia/Ho_Chi_Minh') - INTERVAL 6 MONTH
)
SELECT * FROM
(
    SELECT
        'reason_change'                                                   AS metric,
        multiIf(empty(reason_change), '(empty)', reason_change)           AS value,
        countDistinct(tracking_id)                                        AS trips_affected,
        sum(total_order)                                                  AS orders,
        round(sum(total_ton), 1)                                          AS ton
    FROM window_data
    WHERE is_trip_edit_manual = true
    GROUP BY value

    UNION ALL

    SELECT
        'constraint_name'                                                 AS metric,
        multiIf(empty(constraint_name), '(none)', constraint_name)        AS value,
        countDistinct(tracking_id)                                        AS trips_affected,
        sum(total_order)                                                  AS orders,
        round(sum(total_ton), 1)                                          AS ton
    FROM window_data
    GROUP BY value
)
ORDER BY metric ASC, trips_affected DESC
LIMIT 40
FORMAT PrettyCompactMonoBlock;
