-- ============================================================================
-- C00 _profile-psv — Panasonic PSV pipeline sanity check
-- ============================================================================
-- name: C00_profile-psv
-- params: none
-- flavor: clickhouse
-- schema_deps: analytics_workspace.{psv_target, mv_psv_main, mv_psv, dbo_OPS_Optimizer}
--              tms_panasonic_prod.dbo_OPS_Optimizer
-- purpose: Health check 5 nodes của pipeline PSV — row counts, distinct keys,
--          min/max date (HCM wall-clock display). Chạy đầu mỗi session phân tích.
-- ============================================================================
-- Cách đọc kết quả:
--   - 5 nodes liệt kê theo thứ tự pipeline (source → CDC → trigger MV → target → 2 MV).
--   - Cột max_date_hcm là wall-clock HCM (UTC+7) — value gốc stored bởi SQL Server,
--     KHÔNG apply toTimeZone (vì source data đã là wall-clock HCM, naive).
--   - So sánh max_date_hcm với now_hcm để estimate lag thực của pipeline.
--   - psv_target stale: max_date_hcm cách "now HCM" >1h → trigger MV có thể bị nghẽn.
--   - mv_psv_main stale: max_date_hcm cách "now HCM" >2h → refresh policy 1h fail/lag.
--   - dbo_OPS_Optimizer (analytics_workspace) stale >1 ngày là OK vì đây là bảng aggregate
--     dùng riêng cho các MV khác (không phải nguồn của psv_*).
-- ============================================================================
-- Usage:
--   PowerShell:  .\run.ps1 -File .\core\C00_profile-psv.ch.sql
--   Bash:        ./run.sh core/C00_profile-psv.ch.sql
-- ============================================================================

WITH ref AS
(
    SELECT toString(now('Asia/Ho_Chi_Minh')) AS now_hcm
)
SELECT
    n.node,
    n.rows,
    n.distinct_keys,
    n.min_date_hcm,
    n.max_date_hcm,
    r.now_hcm,
    n.note
FROM
(
    SELECT
        'tms_panasonic_prod.dbo_OPS_Optimizer'                                AS node,
        count()                                                                AS rows,
        uniqExact(ID)                                                          AS distinct_keys,
        toString(toDateTime(min(CreatedDate))) AS min_date_hcm,
        toString(toDateTime(max(CreatedDate))) AS max_date_hcm,
        'CDC source (raw OPS_Optimizer rows)'                                  AS note,
        1                                                                      AS ord
    FROM tms_panasonic_prod.dbo_OPS_Optimizer

    UNION ALL
    SELECT
        'analytics_workspace.psv_target (FINAL, is_deleted=0)',
        count(),
        uniqExact(ops_optimize_id),
        toString(toDateTime(min(created_date))),
        toString(toDateTime(max(created_date))),
        'Canonical store — fed by mv_psv_trigger (realtime)',
        2
    FROM analytics_workspace.psv_target FINAL
    WHERE is_deleted = 0

    UNION ALL
    SELECT
        'analytics_workspace.mv_psv_main',
        count(),
        uniqExact(tracking_id),
        -- mv_psv_main đã shift +7h sẵn, treat as wall-clock HCM
        toString(toDateTime(min(created_date))),
        toString(toDateTime(max(created_date))),
        'UI MV (refresh EVERY 1 HOUR, datetime UTC+7)',
        3
    FROM analytics_workspace.mv_psv_main

    UNION ALL
    SELECT
        'analytics_workspace.mv_psv',
        count(),
        uniqExact(ops_optimize_id),
        toString(toDateTime(min(created_date))),
        toString(toDateTime(max(created_date))),
        'Parallel MV (refresh EVERY 30 MIN) — deprecate candidate',
        4
    FROM analytics_workspace.mv_psv

    UNION ALL
    SELECT
        'analytics_workspace.dbo_OPS_Optimizer',
        count(),
        uniqExact(ID),
        toString(toDateTime(min(CreatedDate))),
        toString(toDateTime(max(CreatedDate))),
        'Aggregate table (cross-tenant) — KHÔNG phải source của psv_*',
        5
    FROM analytics_workspace.dbo_OPS_Optimizer
) AS n
CROSS JOIN ref AS r
ORDER BY n.ord
FORMAT PrettyCompactMonoBlock;
