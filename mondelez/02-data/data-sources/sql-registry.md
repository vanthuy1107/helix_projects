# SQL Registry — MDLZ Control Tower

> **Auto-generated** — Không chỉnh sửa tay. Chạy lại script để cập nhật.
>
> Source: [1o768AUAuHj9HFasdkk8B7UFpYX6G49qyKFoaywte48M](https://docs.google.com/spreadsheets/d/1o768AUAuHj9HFasdkk8B7UFpYX6G49qyKFoaywte48M) / sheet `Summary_Report`  
> Last updated: **2026-05-21 11:10**  
> Total charts với SQL: **165**

---

## Mục lục

1. [Utilization](#utilization)
2. [Loose picking](#loose-picking)
3. [copack - ngừng develop](#copack-ng-ng-develop)
4. [trung chuyển - ngừng develop](#trung-chuy-n-ng-ng-develop)
5. [nhập từ xưởng - ngừng develop](#nh-p-t-x-ng-ng-ng-develop)
6. [Stock type](#stock-type)
7. [vfr tender](#vfr-tender)
8. [vfr operation](#vfr-operation)
9. [Fulfillment Ratio (tỷ lệ đáp ứng)](#fulfillment-ratio-t-l-p-ng)
10. [Compliance Ratio (tỷ lệ tuân thủ)](#compliance-ratio-t-l-tu-n-th)
11. [Transaction move](#transaction-move)
12. [Flash Report](#flash-report)
13. [Tiến độ xuất hàng](#ti-n-xu-t-h-ng)
14. [OTIF](#otif)
15. [Cảnh báo đơn trễ](#c-nh-b-o-n-tr)

---

## Utilization

### Utilization

**Redshift SQL:**

```sql
WITH loc_summary AS (
    SELECT
        wh.whseid                                                       AS whseid,
        wh.loc                                                          AS loc,
        wh.level_type                                                   AS level_type,
        MAX(toInt32(wh.stacklimit))                                     AS max_stacklimit,
        countDistinct(
            CASE
                WHEN wh.palletid IS NOT NULL
                 AND trim(toString(wh.palletid)) <> ''
                 AND upper(trim(toString(wh.palletid))) <> 'NULL'
                THEN wh.palletid
            END
        )                                                               AS pallet_cnt
    FROM analytics_workspace.mv_wh_utilization AS wh
    WHERE 1 = 1

        -- Warehouse filter
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
        )
    GROUP BY wh.whseid, wh.loc, wh.level_type
),

loc_classified AS (
    SELECT
        whseid,
        loc,
        level_type,
        max_stacklimit,
        pallet_cnt,
        CASE
            WHEN level_type = 'Tầng cao' AND pallet_cnt >= max_stacklimit                   THEN 'Full'
            WHEN level_type = 'Tầng cao' AND pallet_cnt > 0 AND pallet_cnt < max_stacklimit THEN 'Partial'
            WHEN level_type = 'Tầng cao' AND pallet_cnt = 0                                 THEN 'Empty'
            ELSE NULL
        END                                                             AS bin_status
    FROM loc_summary
),

wh_summary AS (
    SELECT
        whseid,

        CASE whseid
            WHEN 'BKD1' THEN 4844
            WHEN 'BKD2' THEN 5221
            WHEN 'BKD3' THEN 5014
            WHEN 'NKD'  THEN 3935
            ELSE 0
        END                                                             AS total_position,

        round(
            CASE whseid
                WHEN 'BKD1' THEN 4844
                WHEN 'BKD2' THEN 5221
                WHEN 'BKD3' THEN 5014
                WHEN 'NKD'  THEN 3935
                ELSE 0
            END * 0.85
        , 0)                                                            AS position_85,

        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Full',    pallet_cnt,     0)) AS full_bins,
        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Partial', pallet_cnt,     0)) AS partial_bins,
        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Empty',   max_stacklimit, 0)) AS empty_bins,
        SUM(if(level_type = 'Pickface',                            pallet_cnt,     0)) AS pickface,

          SUM(if(level_type = 'Tầng cao' AND bin_status = 'Full',    pallet_cnt, 0))
        + SUM(if(level_type = 'Tầng cao' AND bin_status = 'Partial', pallet_cnt, 0))
        + SUM(if(level_type = 'Pickface',                            pallet_cnt, 0))
                                                                        AS utilized

    FROM loc_classified
    GROUP BY whseid
)

SELECT
    whseid,
    total_position,
    position_85,
    full_bins,
    partial_bins,
    empty_bins,
    pickface,
    utilized,
    round(
        toFloat64(utilized) / nullIf(position_85, 0)
    , 4)                                                                AS utilization_pct
FROM wh_summary
ORDER BY whseid;
```

**ClickHouse SQL:**

```sql
WITH
    loc_summary AS
    (
        SELECT
            wh.whseid,
            wh.loc,
            any(wh.level_type) AS level_type,
            max(toInt32(wh.stacklimit)) AS max_stacklimit,
            uniqExactIf(
                wh.palletid,
                wh.palletid IS NOT NULL
                AND trim(BOTH ' ' FROM toString(wh.palletid)) != ''
                AND upper(trim(BOTH ' ' FROM toString(wh.palletid))) != 'NULL'
            ) AS pallet_cnt
        FROM analytics_workspace.mv_wh_utilization AS wh
        WHERE 1 = 1
                -- Warehouse
                AND if(
                    arraySort([{{whseid}}]) = (
                        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
                    ),
                    1 = 1,
                    wh.whseid IN ({{whseid}})
                )
        GROUP BY
            wh.whseid,
            wh.loc
    ),

    loc_classified AS
    (
        SELECT
            whseid,
            loc,
            level_type,
            max_stacklimit,
            pallet_cnt,
            multiIf(
                level_type = 'Tầng cao' AND pallet_cnt >= max_stacklimit, 'Full',
                level_type = 'Tầng cao' AND pallet_cnt > 0 AND pallet_cnt < max_stacklimit, 'Partial',
                level_type = 'Tầng cao' AND pallet_cnt = 0, 'Empty',
                NULL
            ) AS bin_status
        FROM loc_summary
    ),

    wh_summary AS
    (
        SELECT
            whseid,

            multiIf(
                whseid = 'BKD1', 4844,
                whseid = 'BKD2', 5221,
                whseid = 'BKD3', 5014,
                whseid = 'NKD', 3935,
                0
            ) AS total_position,

            round(
                multiIf(
                    whseid = 'BKD1', 4844,
                    whseid = 'BKD2', 5221,
                    whseid = 'BKD3', 5014,
                    whseid = 'NKD', 3935,
                    0
                ) * 0.85,
                0
            ) AS position_85,

            sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Full') AS full_bins,
            sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Partial') AS partial_bins,
            sumIf(max_stacklimit, level_type = 'Tầng cao' AND bin_status = 'Empty') AS empty_bins,
            sumIf(pallet_cnt, level_type = 'Pickface') AS pickface,

            (
                sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Full')
                + sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Partial')
                + sumIf(pallet_cnt, level_type = 'Pickface')
            ) AS utilized

        FROM loc_classified
        GROUP BY whseid
    )

SELECT
    whseid,
    total_position,
    position_85,
    full_bins,
    partial_bins,
    empty_bins,
    pickface,
    utilized,
    round(utilized / nullIf(position_85, 0), 4) AS utilization_pct
FROM wh_summary
ORDER BY whseid;
```

### Full bins

**Redshift SQL:**

```sql
WITH loc_summary AS (
    SELECT
        wh.whseid                                                       AS whseid,
        wh.loc                                                          AS loc,
        wh.level_type                                                   AS level_type,
        MAX(toInt32(wh.stacklimit))                                     AS max_stacklimit,
        countDistinct(
            CASE
                WHEN wh.palletid IS NOT NULL
                 AND trim(toString(wh.palletid)) <> ''
                 AND upper(trim(toString(wh.palletid))) <> 'NULL'
                THEN wh.palletid
            END
        )                                                               AS pallet_cnt
    FROM analytics_workspace.mv_wh_utilization AS wh
    WHERE 1 = 1

        -- Warehouse filter
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
        )
    GROUP BY wh.whseid, wh.loc, wh.level_type
),

loc_classified AS (
    SELECT
        whseid,
        loc,
        level_type,
        max_stacklimit,
        pallet_cnt,
        CASE
            WHEN level_type = 'Tầng cao' AND pallet_cnt >= max_stacklimit                   THEN 'Full'
            WHEN level_type = 'Tầng cao' AND pallet_cnt > 0 AND pallet_cnt < max_stacklimit THEN 'Partial'
            WHEN level_type = 'Tầng cao' AND pallet_cnt = 0                                 THEN 'Empty'
            ELSE NULL
        END                                                             AS bin_status
    FROM loc_summary
),

wh_summary AS (
    SELECT
        whseid,

        CASE whseid
            WHEN 'BKD1' THEN 4844
            WHEN 'BKD2' THEN 5221
            WHEN 'BKD3' THEN 5014
            WHEN 'NKD'  THEN 3935
            ELSE 0
        END                                                             AS total_position,

        round(
            CASE whseid
                WHEN 'BKD1' THEN 4844
                WHEN 'BKD2' THEN 5221
                WHEN 'BKD3' THEN 5014
                WHEN 'NKD'  THEN 3935
                ELSE 0
            END * 0.85
        , 0)                                                            AS position_85,

        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Full',    pallet_cnt,     0)) AS full_bins,
        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Partial', pallet_cnt,     0)) AS partial_bins,
        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Empty',   max_stacklimit, 0)) AS empty_bins,
        SUM(if(level_type = 'Pickface',                            pallet_cnt,     0)) AS pickface,

          SUM(if(level_type = 'Tầng cao' AND bin_status = 'Full',    pallet_cnt, 0))
        + SUM(if(level_type = 'Tầng cao' AND bin_status = 'Partial', pallet_cnt, 0))
        + SUM(if(level_type = 'Pickface',                            pallet_cnt, 0))
                                                                        AS utilized

    FROM loc_classified
    GROUP BY whseid
)

SELECT
    whseid,
    total_position,
    position_85,
    full_bins,
    partial_bins,
    empty_bins,
    pickface,
    utilized,
    round(
        toFloat64(utilized) / nullIf(position_85, 0)
    , 4)                                                                AS utilization_pct
FROM wh_summary
ORDER BY whseid;
```

**ClickHouse SQL:**

```sql
WITH
    loc_summary AS
    (
        SELECT
            wh.whseid,
            wh.loc,
            any(wh.level_type) AS level_type,
            max(toInt32(wh.stacklimit)) AS max_stacklimit,
            uniqExactIf(
                wh.palletid,
                wh.palletid IS NOT NULL
                AND trim(BOTH ' ' FROM toString(wh.palletid)) != ''
                AND upper(trim(BOTH ' ' FROM toString(wh.palletid))) != 'NULL'
            ) AS pallet_cnt
        FROM analytics_workspace.mv_wh_utilization AS wh
        WHERE 1 = 1
                -- Warehouse
                AND if(
                    arraySort([{{whseid}}]) = (
                        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
                    ),
                    1 = 1,
                    wh.whseid IN ({{whseid}})
                )
        GROUP BY
            wh.whseid,
            wh.loc
    ),

    loc_classified AS
    (
        SELECT
            whseid,
            loc,
            level_type,
            max_stacklimit,
            pallet_cnt,
            multiIf(
                level_type = 'Tầng cao' AND pallet_cnt >= max_stacklimit, 'Full',
                level_type = 'Tầng cao' AND pallet_cnt > 0 AND pallet_cnt < max_stacklimit, 'Partial',
                level_type = 'Tầng cao' AND pallet_cnt = 0, 'Empty',
                NULL
            ) AS bin_status
        FROM loc_summary
    ),

    wh_summary AS
    (
        SELECT
            whseid,

            multiIf(
                whseid = 'BKD1', 4844,
                whseid = 'BKD2', 5221,
                whseid = 'BKD3', 5014,
                whseid = 'NKD', 3935,
                0
            ) AS total_position,

            round(
                multiIf(
                    whseid = 'BKD1', 4844,
                    whseid = 'BKD2', 5221,
                    whseid = 'BKD3', 5014,
                    whseid = 'NKD', 3935,
                    0
                ) * 0.85,
                0
            ) AS position_85,

            sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Full') AS full_bins,
            sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Partial') AS partial_bins,
            sumIf(max_stacklimit, level_type = 'Tầng cao' AND bin_status = 'Empty') AS empty_bins,
            sumIf(pallet_cnt, level_type = 'Pickface') AS pickface,

            (
                sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Full')
                + sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Partial')
                + sumIf(pallet_cnt, level_type = 'Pickface')
            ) AS utilized

        FROM loc_classified
        GROUP BY whseid
    )

SELECT
    whseid,
    total_position,
    position_85,
    full_bins,
    partial_bins,
    empty_bins,
    pickface,
    utilized,
    round(utilized / nullIf(position_85, 0), 4) AS utilization_pct
FROM wh_summary
ORDER BY whseid;
```

### Partial bins

**Redshift SQL:**

```sql
WITH loc_summary AS (
    SELECT
        wh.whseid                                                       AS whseid,
        wh.loc                                                          AS loc,
        wh.level_type                                                   AS level_type,
        MAX(toInt32(wh.stacklimit))                                     AS max_stacklimit,
        countDistinct(
            CASE
                WHEN wh.palletid IS NOT NULL
                 AND trim(toString(wh.palletid)) <> ''
                 AND upper(trim(toString(wh.palletid))) <> 'NULL'
                THEN wh.palletid
            END
        )                                                               AS pallet_cnt
    FROM analytics_workspace.mv_wh_utilization AS wh
    WHERE 1 = 1

        -- Warehouse filter
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
        )
    GROUP BY wh.whseid, wh.loc, wh.level_type
),

loc_classified AS (
    SELECT
        whseid,
        loc,
        level_type,
        max_stacklimit,
        pallet_cnt,
        CASE
            WHEN level_type = 'Tầng cao' AND pallet_cnt >= max_stacklimit                   THEN 'Full'
            WHEN level_type = 'Tầng cao' AND pallet_cnt > 0 AND pallet_cnt < max_stacklimit THEN 'Partial'
            WHEN level_type = 'Tầng cao' AND pallet_cnt = 0                                 THEN 'Empty'
            ELSE NULL
        END                                                             AS bin_status
    FROM loc_summary
),

wh_summary AS (
    SELECT
        whseid,

        CASE whseid
            WHEN 'BKD1' THEN 4844
            WHEN 'BKD2' THEN 5221
            WHEN 'BKD3' THEN 5014
            WHEN 'NKD'  THEN 3935
            ELSE 0
        END                                                             AS total_position,

        round(
            CASE whseid
                WHEN 'BKD1' THEN 4844
                WHEN 'BKD2' THEN 5221
                WHEN 'BKD3' THEN 5014
                WHEN 'NKD'  THEN 3935
                ELSE 0
            END * 0.85
        , 0)                                                            AS position_85,

        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Full',    pallet_cnt,     0)) AS full_bins,
        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Partial', pallet_cnt,     0)) AS partial_bins,
        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Empty',   max_stacklimit, 0)) AS empty_bins,
        SUM(if(level_type = 'Pickface',                            pallet_cnt,     0)) AS pickface,

          SUM(if(level_type = 'Tầng cao' AND bin_status = 'Full',    pallet_cnt, 0))
        + SUM(if(level_type = 'Tầng cao' AND bin_status = 'Partial', pallet_cnt, 0))
        + SUM(if(level_type = 'Pickface',                            pallet_cnt, 0))
                                                                        AS utilized

    FROM loc_classified
    GROUP BY whseid
)

SELECT
    whseid,
    total_position,
    position_85,
    full_bins,
    partial_bins,
    empty_bins,
    pickface,
    utilized,
    round(
        toFloat64(utilized) / nullIf(position_85, 0)
    , 4)                                                                AS utilization_pct
FROM wh_summary
ORDER BY whseid;
```

**ClickHouse SQL:**

```sql
WITH
    loc_summary AS
    (
        SELECT
            wh.whseid,
            wh.loc,
            any(wh.level_type) AS level_type,
            max(toInt32(wh.stacklimit)) AS max_stacklimit,
            uniqExactIf(
                wh.palletid,
                wh.palletid IS NOT NULL
                AND trim(BOTH ' ' FROM toString(wh.palletid)) != ''
                AND upper(trim(BOTH ' ' FROM toString(wh.palletid))) != 'NULL'
            ) AS pallet_cnt
        FROM analytics_workspace.mv_wh_utilization AS wh
        WHERE 1 = 1
                -- Warehouse
                AND if(
                    arraySort([{{whseid}}]) = (
                        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
                    ),
                    1 = 1,
                    wh.whseid IN ({{whseid}})
                )
        GROUP BY
            wh.whseid,
            wh.loc
    ),

    loc_classified AS
    (
        SELECT
            whseid,
            loc,
            level_type,
            max_stacklimit,
            pallet_cnt,
            multiIf(
                level_type = 'Tầng cao' AND pallet_cnt >= max_stacklimit, 'Full',
                level_type = 'Tầng cao' AND pallet_cnt > 0 AND pallet_cnt < max_stacklimit, 'Partial',
                level_type = 'Tầng cao' AND pallet_cnt = 0, 'Empty',
                NULL
            ) AS bin_status
        FROM loc_summary
    ),

    wh_summary AS
    (
        SELECT
            whseid,

            multiIf(
                whseid = 'BKD1', 4844,
                whseid = 'BKD2', 5221,
                whseid = 'BKD3', 5014,
                whseid = 'NKD', 3935,
                0
            ) AS total_position,

            round(
                multiIf(
                    whseid = 'BKD1', 4844,
                    whseid = 'BKD2', 5221,
                    whseid = 'BKD3', 5014,
                    whseid = 'NKD', 3935,
                    0
                ) * 0.85,
                0
            ) AS position_85,

            sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Full') AS full_bins,
            sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Partial') AS partial_bins,
            sumIf(max_stacklimit, level_type = 'Tầng cao' AND bin_status = 'Empty') AS empty_bins,
            sumIf(pallet_cnt, level_type = 'Pickface') AS pickface,

            (
                sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Full')
                + sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Partial')
                + sumIf(pallet_cnt, level_type = 'Pickface')
            ) AS utilized

        FROM loc_classified
        GROUP BY whseid
    )

SELECT
    whseid,
    total_position,
    position_85,
    full_bins,
    partial_bins,
    empty_bins,
    pickface,
    utilized,
    round(utilized / nullIf(position_85, 0), 4) AS utilization_pct
FROM wh_summary
ORDER BY whseid;
```

### Empty bins

**Redshift SQL:**

```sql
WITH loc_summary AS (
    SELECT
        wh.whseid                                                       AS whseid,
        wh.loc                                                          AS loc,
        wh.level_type                                                   AS level_type,
        MAX(toInt32(wh.stacklimit))                                     AS max_stacklimit,
        countDistinct(
            CASE
                WHEN wh.palletid IS NOT NULL
                 AND trim(toString(wh.palletid)) <> ''
                 AND upper(trim(toString(wh.palletid))) <> 'NULL'
                THEN wh.palletid
            END
        )                                                               AS pallet_cnt
    FROM analytics_workspace.mv_wh_utilization AS wh
    WHERE 1 = 1

        -- Warehouse filter
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
        )
    GROUP BY wh.whseid, wh.loc, wh.level_type
),

loc_classified AS (
    SELECT
        whseid,
        loc,
        level_type,
        max_stacklimit,
        pallet_cnt,
        CASE
            WHEN level_type = 'Tầng cao' AND pallet_cnt >= max_stacklimit                   THEN 'Full'
            WHEN level_type = 'Tầng cao' AND pallet_cnt > 0 AND pallet_cnt < max_stacklimit THEN 'Partial'
            WHEN level_type = 'Tầng cao' AND pallet_cnt = 0                                 THEN 'Empty'
            ELSE NULL
        END                                                             AS bin_status
    FROM loc_summary
),

wh_summary AS (
    SELECT
        whseid,

        CASE whseid
            WHEN 'BKD1' THEN 4844
            WHEN 'BKD2' THEN 5221
            WHEN 'BKD3' THEN 5014
            WHEN 'NKD'  THEN 3935
            ELSE 0
        END                                                             AS total_position,

        round(
            CASE whseid
                WHEN 'BKD1' THEN 4844
                WHEN 'BKD2' THEN 5221
                WHEN 'BKD3' THEN 5014
                WHEN 'NKD'  THEN 3935
                ELSE 0
            END * 0.85
        , 0)                                                            AS position_85,

        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Full',    pallet_cnt,     0)) AS full_bins,
        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Partial', pallet_cnt,     0)) AS partial_bins,
        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Empty',   max_stacklimit, 0)) AS empty_bins,
        SUM(if(level_type = 'Pickface',                            pallet_cnt,     0)) AS pickface,

          SUM(if(level_type = 'Tầng cao' AND bin_status = 'Full',    pallet_cnt, 0))
        + SUM(if(level_type = 'Tầng cao' AND bin_status = 'Partial', pallet_cnt, 0))
        + SUM(if(level_type = 'Pickface',                            pallet_cnt, 0))
                                                                        AS utilized

    FROM loc_classified
    GROUP BY whseid
)

SELECT
    whseid,
    total_position,
    position_85,
    full_bins,
    partial_bins,
    empty_bins,
    pickface,
    utilized,
    round(
        toFloat64(utilized) / nullIf(position_85, 0)
    , 4)                                                                AS utilization_pct
FROM wh_summary
ORDER BY whseid;
```

**ClickHouse SQL:**

```sql
WITH
    loc_summary AS
    (
        SELECT
            wh.whseid,
            wh.loc,
            any(wh.level_type) AS level_type,
            max(toInt32(wh.stacklimit)) AS max_stacklimit,
            uniqExactIf(
                wh.palletid,
                wh.palletid IS NOT NULL
                AND trim(BOTH ' ' FROM toString(wh.palletid)) != ''
                AND upper(trim(BOTH ' ' FROM toString(wh.palletid))) != 'NULL'
            ) AS pallet_cnt
        FROM analytics_workspace.mv_wh_utilization AS wh
        WHERE 1 = 1
                -- Warehouse
                AND if(
                    arraySort([{{whseid}}]) = (
                        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
                    ),
                    1 = 1,
                    wh.whseid IN ({{whseid}})
                )
        GROUP BY
            wh.whseid,
            wh.loc
    ),

    loc_classified AS
    (
        SELECT
            whseid,
            loc,
            level_type,
            max_stacklimit,
            pallet_cnt,
            multiIf(
                level_type = 'Tầng cao' AND pallet_cnt >= max_stacklimit, 'Full',
                level_type = 'Tầng cao' AND pallet_cnt > 0 AND pallet_cnt < max_stacklimit, 'Partial',
                level_type = 'Tầng cao' AND pallet_cnt = 0, 'Empty',
                NULL
            ) AS bin_status
        FROM loc_summary
    ),

    wh_summary AS
    (
        SELECT
            whseid,

            multiIf(
                whseid = 'BKD1', 4844,
                whseid = 'BKD2', 5221,
                whseid = 'BKD3', 5014,
                whseid = 'NKD', 3935,
                0
            ) AS total_position,

            round(
                multiIf(
                    whseid = 'BKD1', 4844,
                    whseid = 'BKD2', 5221,
                    whseid = 'BKD3', 5014,
                    whseid = 'NKD', 3935,
                    0
                ) * 0.85,
                0
            ) AS position_85,

            sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Full') AS full_bins,
            sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Partial') AS partial_bins,
            sumIf(max_stacklimit, level_type = 'Tầng cao' AND bin_status = 'Empty') AS empty_bins,
            sumIf(pallet_cnt, level_type = 'Pickface') AS pickface,

            (
                sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Full')
                + sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Partial')
                + sumIf(pallet_cnt, level_type = 'Pickface')
            ) AS utilized

        FROM loc_classified
        GROUP BY whseid
    )

SELECT
    whseid,
    total_position,
    position_85,
    full_bins,
    partial_bins,
    empty_bins,
    pickface,
    utilized,
    round(utilized / nullIf(position_85, 0), 4) AS utilization_pct
FROM wh_summary
ORDER BY whseid;
```

### Pickface

**Redshift SQL:**

```sql
WITH loc_summary AS (
    SELECT
        wh.whseid                                                       AS whseid,
        wh.loc                                                          AS loc,
        wh.level_type                                                   AS level_type,
        MAX(toInt32(wh.stacklimit))                                     AS max_stacklimit,
        countDistinct(
            CASE
                WHEN wh.palletid IS NOT NULL
                 AND trim(toString(wh.palletid)) <> ''
                 AND upper(trim(toString(wh.palletid))) <> 'NULL'
                THEN wh.palletid
            END
        )                                                               AS pallet_cnt
    FROM analytics_workspace.mv_wh_utilization AS wh
    WHERE 1 = 1

        -- Warehouse filter
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
        )
    GROUP BY wh.whseid, wh.loc, wh.level_type
),

loc_classified AS (
    SELECT
        whseid,
        loc,
        level_type,
        max_stacklimit,
        pallet_cnt,
        CASE
            WHEN level_type = 'Tầng cao' AND pallet_cnt >= max_stacklimit                   THEN 'Full'
            WHEN level_type = 'Tầng cao' AND pallet_cnt > 0 AND pallet_cnt < max_stacklimit THEN 'Partial'
            WHEN level_type = 'Tầng cao' AND pallet_cnt = 0                                 THEN 'Empty'
            ELSE NULL
        END                                                             AS bin_status
    FROM loc_summary
),

wh_summary AS (
    SELECT
        whseid,

        CASE whseid
            WHEN 'BKD1' THEN 4844
            WHEN 'BKD2' THEN 5221
            WHEN 'BKD3' THEN 5014
            WHEN 'NKD'  THEN 3935
            ELSE 0
        END                                                             AS total_position,

        round(
            CASE whseid
                WHEN 'BKD1' THEN 4844
                WHEN 'BKD2' THEN 5221
                WHEN 'BKD3' THEN 5014
                WHEN 'NKD'  THEN 3935
                ELSE 0
            END * 0.85
        , 0)                                                            AS position_85,

        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Full',    pallet_cnt,     0)) AS full_bins,
        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Partial', pallet_cnt,     0)) AS partial_bins,
        SUM(if(level_type = 'Tầng cao' AND bin_status = 'Empty',   max_stacklimit, 0)) AS empty_bins,
        SUM(if(level_type = 'Pickface',                            pallet_cnt,     0)) AS pickface,

          SUM(if(level_type = 'Tầng cao' AND bin_status = 'Full',    pallet_cnt, 0))
        + SUM(if(level_type = 'Tầng cao' AND bin_status = 'Partial', pallet_cnt, 0))
        + SUM(if(level_type = 'Pickface',                            pallet_cnt, 0))
                                                                        AS utilized

    FROM loc_classified
    GROUP BY whseid
)

SELECT
    whseid,
    total_position,
    position_85,
    full_bins,
    partial_bins,
    empty_bins,
    pickface,
    utilized,
    round(
        toFloat64(utilized) / nullIf(position_85, 0)
    , 4)                                                                AS utilization_pct
FROM wh_summary
ORDER BY whseid;
```

**ClickHouse SQL:**

```sql
WITH
    loc_summary AS
    (
        SELECT
            wh.whseid,
            wh.loc,
            any(wh.level_type) AS level_type,
            max(toInt32(wh.stacklimit)) AS max_stacklimit,
            uniqExactIf(
                wh.palletid,
                wh.palletid IS NOT NULL
                AND trim(BOTH ' ' FROM toString(wh.palletid)) != ''
                AND upper(trim(BOTH ' ' FROM toString(wh.palletid))) != 'NULL'
            ) AS pallet_cnt
        FROM analytics_workspace.mv_wh_utilization AS wh
        WHERE 1 = 1
                -- Warehouse
                AND if(
                    arraySort([{{whseid}}]) = (
                        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
                    ),
                    1 = 1,
                    wh.whseid IN ({{whseid}})
                )
        GROUP BY
            wh.whseid,
            wh.loc
    ),

    loc_classified AS
    (
        SELECT
            whseid,
            loc,
            level_type,
            max_stacklimit,
            pallet_cnt,
            multiIf(
                level_type = 'Tầng cao' AND pallet_cnt >= max_stacklimit, 'Full',
                level_type = 'Tầng cao' AND pallet_cnt > 0 AND pallet_cnt < max_stacklimit, 'Partial',
                level_type = 'Tầng cao' AND pallet_cnt = 0, 'Empty',
                NULL
            ) AS bin_status
        FROM loc_summary
    ),

    wh_summary AS
    (
        SELECT
            whseid,

            multiIf(
                whseid = 'BKD1', 4844,
                whseid = 'BKD2', 5221,
                whseid = 'BKD3', 5014,
                whseid = 'NKD', 3935,
                0
            ) AS total_position,

            round(
                multiIf(
                    whseid = 'BKD1', 4844,
                    whseid = 'BKD2', 5221,
                    whseid = 'BKD3', 5014,
                    whseid = 'NKD', 3935,
                    0
                ) * 0.85,
                0
            ) AS position_85,

            sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Full') AS full_bins,
            sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Partial') AS partial_bins,
            sumIf(max_stacklimit, level_type = 'Tầng cao' AND bin_status = 'Empty') AS empty_bins,
            sumIf(pallet_cnt, level_type = 'Pickface') AS pickface,

            (
                sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Full')
                + sumIf(pallet_cnt, level_type = 'Tầng cao' AND bin_status = 'Partial')
                + sumIf(pallet_cnt, level_type = 'Pickface')
            ) AS utilized

        FROM loc_classified
        GROUP BY whseid
    )

SELECT
    whseid,
    total_position,
    position_85,
    full_bins,
    partial_bins,
    empty_bins,
    pickface,
    utilized,
    round(utilized / nullIf(position_85, 0), 4) AS utilization_pct
FROM wh_summary
ORDER BY whseid;
```

### Utilization by warehouse and level type `Đã sửa`

**Redshift SQL:**

```sql
WITH loc_summary AS (
    SELECT
        wh.whseid,
        wh.level_type,
        wh.loc,
        CAST(wh.stacklimit AS INTEGER) AS stacklimit_max,
        COUNT(DISTINCT wh.palletid)         AS pallet_cnt
    FROM analytics_workspace.mv_wh_utilization AS wh
    WHERE 1=1
        -- Warehouse filter
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
        )
    GROUP by 1,2,3,4
)
SELECT
    whseid,
    level_type,
    SUM(pallet_cnt)                                                          AS total_pallet,
    SUM(stacklimit_max)                                                      AS total_stacklimit,
    ROUND(
        CAST(SUM(pallet_cnt) AS DECIMAL(18,4)) / NULLIF(SUM(stacklimit_max), 0),
        4
    )                                                                        AS utilization_pct
FROM loc_summary
GROUP BY
    whseid,
    level_type
ORDER BY
    whseid,
    level_type;
```

**ClickHouse SQL:**

```sql
WITH
loc_summary AS (
    SELECT
        wh.whseid,
        wh.level_type,
        wh.loc,
        COUNT(DISTINCT wh.palletid) AS pallet_cnt,
        MAX(CAST(wh.stacklimit AS INTEGER)) AS stacklimit_max
    FROM analytics_workspace.mv_wh_utilization AS wh
    WHERE 1= 1
    -- Warehouse
                AND if(
                    arraySort([{{whseid}}]) = (
                        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
                    ),
                    1 = 1,
                    wh.whseid IN ({{whseid}})
                )
    GROUP BY
        wh.whseid,
        wh.level_type,
        wh.loc
)
SELECT
    whseid,
    level_type,
    SUM(pallet_cnt) AS total_pallet,
    SUM(stacklimit_max) AS total_stacklimit,
    ROUND(
        SUM(pallet_cnt)::decimal(18,4) / NULLIF(SUM(stacklimit_max), 0),
        4
    ) AS utilization_pct
FROM loc_summary
GROUP BY
    whseid,
    level_type
ORDER BY
    whseid,
    level_type;
```

### Bin status by warehouse `Đã sửa`

**Redshift SQL:**

```sql
WITH loc_summary AS (
    /* B1: group theo whseid, loc, level_type */
    SELECT
        wh.whseid                       AS whseid,
        wh.loc                          AS loc,
        wh.level_type                   AS level_type,
        toInt32(wh.stacklimit)          AS max_stacklimit,
        countDistinct(wh.palletid)      AS pallet_cnt
    FROM analytics_workspace.mv_wh_utilization AS wh
    WHERE 1 = 1

        -- Warehouse filter
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
        )
    GROUP BY
        wh.whseid,
        wh.loc,
        wh.level_type,
        toInt32(wh.stacklimit)
),

classified AS (
    /* B2: phân loại cho level_type = 'Tầng cao' */
    SELECT
        whseid,
        loc,
        level_type,
        pallet_cnt,
        max_stacklimit,
        CASE
            WHEN level_type = 'Tầng cao' AND pallet_cnt >= max_stacklimit                   THEN 'Full'
            WHEN level_type = 'Tầng cao' AND pallet_cnt > 0 AND pallet_cnt < max_stacklimit THEN 'Partial'
            WHEN level_type = 'Tầng cao' AND pallet_cnt = 0                                 THEN 'Empty'
            ELSE NULL
        END                              AS bin_group
    FROM loc_summary
),

wh_total AS (
    /* Tổng số location tầng cao theo kho */
    SELECT
        whseid,
        COUNT(*)                         AS total_loc_tang_cao
    FROM classified
    WHERE level_type = 'Tầng cao'
    GROUP BY whseid
)

/* B3: tính tỷ trọng theo số location của 3 group */
SELECT
    c.whseid                                                            AS whseid,
    c.bin_group                                                         AS bin_group,
    COUNT(*)                                                            AS location_cnt,
    any(t.total_loc_tang_cao)                                           AS total_loc_tang_cao,
    round(
        toFloat64(COUNT(*)) / nullIf(any(t.total_loc_tang_cao), 0),
        4
    )                                                                   AS location_ratio
FROM classified AS c
LEFT JOIN wh_total AS t
    ON c.whseid = t.whseid
WHERE
    c.level_type = 'Tầng cao'
    AND c.bin_group IS NOT NULL
GROUP BY
    c.whseid,
    c.bin_group
ORDER BY
    c.whseid,
    c.bin_group;
```

**ClickHouse SQL:**

```sql
WITH

    loc_summary AS
    (
        /* B1: group theo whseid, loc */
        SELECT
            wh.whseid,
            wh.loc,
            any(wh.level_type) AS level_type,
            uniqExact(wh.palletid) AS pallet_cnt,
            max(toInt32(wh.stacklimit)) AS max_stacklimit
        FROM analytics_workspace.mv_wh_utilization AS wh
        WHERE 1 = 1
        -- Warehouse
                AND if(
                    arraySort([{{whseid}}]) = (
                        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
                    ),
                    1 = 1,
                    wh.whseid IN ({{whseid}})
                )
        GROUP BY
            wh.whseid,
            wh.loc
    ),

    classified AS
    (
        /* B2: phân loại cho level_type = 'Tầng cao' */
        SELECT
            whseid,
            loc,
            level_type,
            pallet_cnt,
            max_stacklimit,
            multiIf(
                level_type = 'Tầng cao' AND pallet_cnt >= max_stacklimit, 'Full',
                level_type = 'Tầng cao' AND pallet_cnt > 0 AND pallet_cnt < max_stacklimit, 'Partial',
                level_type = 'Tầng cao' AND pallet_cnt = 0, 'Empty',
                NULL
            ) AS bin_group
        FROM loc_summary
    ),

    wh_total AS
    (
        /* Tổng số location tầng cao theo kho */
        SELECT
            whseid,
            count() AS total_loc_tang_cao
        FROM classified
        WHERE level_type = 'Tầng cao'
        GROUP BY whseid
    )

/* B3: tính tỷ trọng theo số location của 3 group */
SELECT
    c.whseid,
    c.bin_group,
    count() AS location_cnt,
    t.total_loc_tang_cao,
    round(count() / nullIf(t.total_loc_tang_cao, 0), 4) AS location_ratio
FROM classified AS c
LEFT JOIN wh_total AS t
    ON c.whseid = t.whseid
WHERE
    c.level_type = 'Tầng cao'
    AND c.bin_group IS NOT NULL
GROUP BY
    c.whseid,
    c.bin_group,
    t.total_loc_tang_cao
ORDER BY
    c.whseid,
    c.bin_group;
```

### Cargo mix (FG/SLOB/POSM) `Đã sửa`

**Redshift SQL:**

```sql
WITH base AS (
        SELECT
            wh.whseid,
            wh.palletid,
            UPPER(COALESCE(wh.group_of_cargo, ''))  AS group_of_cargo_u,
            COALESCE(wh.status, '')                  AS status_raw,
            CASE
                WHEN UPPER(COALESCE(wh.group_of_cargo, '')) <> 'POSM/OFFBOM'
                 AND (
                        LOWER(COALESCE(wh.status, '')) LIKE '%damage%'
                     OR LOWER(COALESCE(wh.status, '')) LIKE '%damaged%'
                     OR LOWER(COALESCE(wh.status, '')) LIKE '%hold%'
                     OR LOWER(COALESCE(wh.status, '')) LIKE '%qi%'
                     OR LOWER(COALESCE(wh.status, '')) LIKE '%blocked%'
                     OR LOWER(COALESCE(wh.status, '')) LIKE '%expired%'
                 )
                THEN 1 ELSE 0
            END AS is_slob,
            
            CASE
                WHEN UPPER(COALESCE(wh.group_of_cargo, '')) = 'POSM/OFFBOM' THEN 1 ELSE 0
            END AS is_posm
            
        FROM analytics_workspace.mv_wh_utilization AS wh
        WHERE 1=1
        -- Warehouse filter
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
        )
          AND COALESCE(wh.palletid, '') <> ''
    ),
    pallet_flag AS (
        SELECT
            whseid,
            palletid,
            MAX(is_slob) AS is_slob,
            MAX(is_posm) AS is_posm
        FROM base
        GROUP BY
            whseid,
            palletid
    )
SELECT
    whseid,
    COUNT(*)                                        AS utilized_pallet,
    COUNT(case when is_slob = 1 then palletid end)    AS slob_pallet,
    COUNT(case when is_posm = 1 then palletid end)    AS posm_pallet,
    COUNT(*) - COUNT(case when is_slob = 1 then palletid end) - COUNT(case when is_posm = 1 then palletid end)         AS fg_pallet
FROM pallet_flag
GROUP BY whseid
ORDER BY whseid;
```

**ClickHouse SQL:**

```sql
WITH
    base AS (
        SELECT
            wh.whseid,
            wh.palletid,
            UPPER(COALESCE(wh.group_of_cargo, ''))  AS group_of_cargo_u,
            COALESCE(wh.status, '')                  AS status_raw,
            CASE
                WHEN UPPER(COALESCE(wh.group_of_cargo, '')) <> 'POSM/OFFBOM'
                 AND (
                        LOWER(COALESCE(wh.status, '')) LIKE '%damage%'
                     OR LOWER(COALESCE(wh.status, '')) LIKE '%damaged%'
                     OR LOWER(COALESCE(wh.status, '')) LIKE '%hold%'
                     OR LOWER(COALESCE(wh.status, '')) LIKE '%qi%'
                     OR LOWER(COALESCE(wh.status, '')) LIKE '%blocked%'
                     OR LOWER(COALESCE(wh.status, '')) LIKE '%expired%'
                 )
                THEN 1 ELSE 0
            END AS is_slob,
            
            CASE
                WHEN UPPER(COALESCE(wh.group_of_cargo, '')) = 'POSM/OFFBOM' THEN 1 ELSE 0
            END AS is_posm
            
        FROM analytics_workspace.mv_wh_utilization AS wh

        WHERE 1 =1 
        -- Warehouse
                AND if(
                    arraySort([{{whseid}}]) = (
                        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
                    ),
                    1 = 1,
                    wh.whseid IN ({{whseid}})
                )
          AND COALESCE(wh.palletid, '') <> ''
    ),
    pallet_flag AS (
        SELECT
            whseid,
            palletid,
            MAX(is_slob) AS is_slob,
            MAX(is_posm) AS is_posm
        FROM base
        GROUP BY
            whseid,
            palletid
    )
SELECT
    whseid,
    COUNT(*)                                        AS utilized_pallet,
    COUNT(case when is_slob = 1 then palletid end)    AS slob_pallet,
    COUNT(case when is_posm = 1 then palletid end)    AS posm_pallet,
    COUNT(*) - COUNT(case when is_slob = 1 then palletid end) - COUNT(case when is_posm = 1 then palletid end)         AS fg_pallet
FROM pallet_flag
GROUP BY whseid
ORDER BY whseid;
```

### Top 10 SKU by pallet count `Đã sửa`

**Redshift SQL:**

```sql
SELECT
    u.item_code,
    COUNT(CASE WHEN COALESCE(TRIM(CAST(u.palletid AS VARCHAR)), '') <> '' THEN 1 END) AS pallet_count
FROM analytics_workspace.mv_wh_utilization u
WHERE 1=1
                -- Warehouse filter
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
        )
GROUP BY u.item_code
ORDER BY pallet_count DESC;
```

**ClickHouse SQL:**

```sql
SELECT
    u.item_code,
    countIf(notEmpty(toString(u.palletid))) AS pallet_count
FROM analytics_workspace.mv_wh_utilization u
where 1 = 1
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    u.whseid IN ({{whseid}})
)
GROUP BY u.item_code
ORDER BY pallet_count DESC
```

### Warehouse Summary (table) `Đã sửa`

**Redshift SQL:**

```sql
SELECT
    u.item_code,
    COUNT(CASE WHEN COALESCE(TRIM(CAST(u.palletid AS VARCHAR)), '') <> '' THEN 1 END) AS pallet_count
FROM analytics_workspace.mv_wh_utilization u
WHERE 1=1
                -- Warehouse filter
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
        )
GROUP BY u.item_code
ORDER BY pallet_count DESC;
```

**ClickHouse SQL:**

```sql
WITH

location_stats AS (
    SELECT
        whseid,
        loc,
        any(stacklimit)                     AS stacklimit,
        anyIf(level_type, level_type != '') AS level_type,
        -- đếm pallet thực tế (bỏ qua NULL lpnid)
        uniqExactIf(lpnid, lpnid != '')     AS pallet_count
    FROM analytics_workspace.mv_wh_utilization
    WHERE whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    u.whseid IN ({{whseid}})
)
    GROUP BY whseid, loc
),

warehouse_location_agg AS (
    SELECT
        whseid,
        CASE whseid
            WHEN 'BKD1' THEN 4844
            WHEN 'BKD2' THEN 5221
            WHEN 'BKD3' THEN 5014
            WHEN 'NKD'  THEN 4559
        END                                                              AS total_position,
        CASE whseid
            WHEN 'BKD1' THEN 4117
            WHEN 'BKD2' THEN 4438
            WHEN 'BKD3' THEN 4262
            WHEN 'NKD'  THEN 3875
        END                                                              AS total_utilized_85,
        countIf(level_type = 'Tầng cao' AND pallet_count >= stacklimit AND pallet_count > 0)  AS full_location,
        countIf(level_type = 'Tầng cao' AND pallet_count > 0 AND pallet_count < stacklimit)   AS partial_location,
        -- empty: pallet_count = 0, không bắt buộc level_type vì loc trống có thể không có level_type
        countIf(level_type = 'Tầng cao' AND pallet_count = 0)                                 AS empty_location,
        countIf(level_type = 'Pickface')                                                      AS pick_face
    FROM location_stats
    GROUP BY whseid
),

warehouse_pallet_agg AS (
    SELECT
        whseid,
        uniqExactIf(lpnid, lpnid != '')                                 AS utilized_total,
        uniqExactIf(lpnid, lpnid != '' AND group_of_cargo = 'POSM/OFFBOM')  AS posm,
        uniqExactIf(lpnid,
            lpnid != ''
            AND group_of_cargo != 'POSM/OFFBOM'
            AND (
                status LIKE '%Damaged%'
                OR status LIKE '%Hold%'
                OR status LIKE '%QI%'
                OR status LIKE '%Blocked%'
                OR status LIKE '%Expired%'
            )
        )                                                               AS slob
    FROM analytics_workspace.mv_wh_utilization
    WHERE whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    u.whseid IN ({{whseid}})
)
    GROUP BY whseid
)

SELECT
    l.whseid                                                            AS Kho,
    l.total_position                                                    AS `Total Position`,
    l.total_utilized_85                                                 AS `Total Utilized Position (85% Capacity)`,
    l.full_location                                                     AS `Full Location`,
    l.partial_location                                                  AS `Partial Location`,
    l.empty_location                                                    AS `Empty Location`,
    l.pick_face                                                         AS `Pick Face`,
    p.utilized_total                                                    AS `Utilized (Total Pallet Internal)`,
    if(l.total_utilized_85 > 0,
        ROUND(p.utilized_total / l.total_utilized_85 * 100, 2), 0)     AS `%WH Utilization`,
    (p.utilized_total - p.slob - p.posm)                               AS FG,
    p.slob                                                              AS SLOB,
    p.posm                                                              AS POSM,
    if(l.total_utilized_85 > 0,
        ROUND((p.utilized_total - p.slob - p.posm) / l.total_utilized_85 * 100, 2), 0)  AS `%FG`,
    if(l.total_utilized_85 > 0,
        ROUND(p.slob / l.total_utilized_85 * 100, 2), 0)               AS `%SLOB`,
    if(l.total_utilized_85 > 0,
        ROUND(p.posm / l.total_utilized_85 * 100, 2), 0)               AS `%POSM`

FROM warehouse_location_agg l
LEFT JOIN warehouse_pallet_agg p ON l.whseid = p.whseid
ORDER BY l.whseid
```

### Detail by Location (table) `Đã sửa`

**Redshift SQL:**

```sql
SELECT
    u.item_code,
    COUNT(CASE WHEN COALESCE(TRIM(CAST(u.palletid AS VARCHAR)), '') <> '' THEN 1 END) AS pallet_count
FROM analytics_workspace.mv_wh_utilization u
WHERE 1=1
                -- Warehouse filter
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
        )
GROUP BY u.item_code
ORDER BY pallet_count DESC;
```

**ClickHouse SQL:**

```sql
SELECT
    whseid        AS Warehouse
    , loc         AS Location
    , stacklimit  AS "Stack Limit"
    , uniqExactIf(lpnid, lpnid != '') AS Pallets
    , status      AS Status
FROM analytics_workspace.mv_wh_utilization
WHERE whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    u.whseid IN ({{whseid}})
)
GROUP BY
    whseid
    , loc
    , stacklimit
    , status
ORDER BY
    whseid ASC
    , loc  ASC
```

---

## Loose picking

### TỔNG THÙNG XUẤT `Đã sửa`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                         -- đổi thành 'BKD1' để lọc 1 kho
        TIMESTAMP '2026-02-01 00:00:00' AS p_from_date,    -- ngày bắt đầu
        TIMESTAMP '2026-02-28 23:59:59' AS p_to_date       -- ngày kết thúc
),
summary AS (
    SELECT
        wh.whseid,
        wh."SO",
        SUM(wh.cse_full) AS cse_full,
        SUM(wh.cse_loose) AS cse_loose,
        SUM(wh.number_of_full_pallets) AS number_of_full_pallets
    FROM analytics_workspace.reporting_schema.mv_test_loose_picking AS wh
    CROSS JOIN params AS p
    WHERE 1 = 1
        AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
        AND (p.p_from_date IS NULL OR wh.actual_ship_date >= p.p_from_date)
        AND (p.p_to_date IS NULL OR wh.actual_ship_date <= p.p_to_date)
    GROUP BY
        wh.whseid,
        wh."SO"
)
SELECT
    *,
    cse_full + cse_loose AS total_case,
    CASE
        WHEN cse_full + cse_loose = 0 THEN 0
        ELSE cse_loose * 100.0 / (cse_full + cse_loose)
    END AS pct_loose_picking
FROM summary
ORDER BY "SO";
```

**ClickHouse SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'                             AS p_whseid,
        toDateTime('2026-02-01 00:00:00') AS p_from_date,
        toDateTime('2026-02-28 23:59:59') AS p_to_date
)
SELECT
    whseid,
    cse_full,
    cse_loose,
    number_of_full_pallets,
    cse_full + cse_loose AS total_case,
    CASE
        WHEN cse_full + cse_loose = 0 THEN 0.0
        ELSE cse_loose * 100.0 / (cse_full + cse_loose)
    END AS pct_loose_picking
FROM (
    SELECT
        wh.whseid,
        SUM(ifNull(wh.cse_full, 0))               AS cse_full,
        SUM(ifNull(wh.cse_loose, 0))              AS cse_loose,
        SUM(ifNull(wh.number_of_full_pallets, 0)) AS number_of_full_pallets
    FROM analytics_workspace.mv_loose_picking_clickhouse AS wh
    CROSS JOIN params AS p
    WHERE 1= 1 
      AND (p_whseid = 'ALL' or wh.whseid = p_whseid)
      AND wh.actual_ship_date >= p.p_from_date
      AND wh.actual_ship_date <= p.p_to_date
    GROUP BY wh.whseid
) t
ORDER BY whseid;
```

### TỔNG THÙNG LẺ `Đã sửa`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                         -- đổi thành 'BKD1' để lọc 1 kho
        TIMESTAMP '2026-02-01 00:00:00' AS p_from_date,    -- ngày bắt đầu
        TIMESTAMP '2026-02-28 23:59:59' AS p_to_date       -- ngày kết thúc
),
summary AS (
    SELECT
        wh.whseid,
        wh."SO",
        SUM(wh.cse_full) AS cse_full,
        SUM(wh.cse_loose) AS cse_loose,
        SUM(wh.number_of_full_pallets) AS number_of_full_pallets
    FROM analytics_workspace.reporting_schema.mv_test_loose_picking AS wh
    CROSS JOIN params AS p
    WHERE 1 = 1
        AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
        AND (p.p_from_date IS NULL OR wh.actual_ship_date >= p.p_from_date)
        AND (p.p_to_date IS NULL OR wh.actual_ship_date <= p.p_to_date)
    GROUP BY
        wh.whseid,
        wh."SO"
)
SELECT
    *,
    cse_full + cse_loose AS total_case,
    CASE
        WHEN cse_full + cse_loose = 0 THEN 0
        ELSE cse_loose * 100.0 / (cse_full + cse_loose)
    END AS pct_loose_picking
FROM summary
ORDER BY "SO";
```

**ClickHouse SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'                             AS p_whseid,
        toDateTime('2026-02-01 00:00:00') AS p_from_date,
        toDateTime('2026-02-28 23:59:59') AS p_to_date
)
SELECT
    whseid,
    cse_full,
    cse_loose,
    number_of_full_pallets,
    cse_full + cse_loose AS total_case,
    CASE
        WHEN cse_full + cse_loose = 0 THEN 0.0
        ELSE cse_loose * 100.0 / (cse_full + cse_loose)
    END AS pct_loose_picking
FROM (
    SELECT
        wh.whseid,
        SUM(ifNull(wh.cse_full, 0))               AS cse_full,
        SUM(ifNull(wh.cse_loose, 0))              AS cse_loose,
        SUM(ifNull(wh.number_of_full_pallets, 0)) AS number_of_full_pallets
    FROM analytics_workspace.mv_loose_picking_clickhouse AS wh
    CROSS JOIN params AS p
    WHERE 1= 1 
      AND (p_whseid = 'ALL' or wh.whseid = p_whseid)
      AND wh.actual_ship_date >= p.p_from_date
      AND wh.actual_ship_date <= p.p_to_date
    GROUP BY wh.whseid
) t
ORDER BY whseid;
```

### TỔNG PALLET NGUYÊN `Đã sửa`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                         -- đổi thành 'BKD1' để lọc 1 kho
        TIMESTAMP '2026-02-01 00:00:00' AS p_from_date,    -- ngày bắt đầu
        TIMESTAMP '2026-02-28 23:59:59' AS p_to_date       -- ngày kết thúc
),
summary AS (
    SELECT
        wh.whseid,
        wh."SO",
        SUM(wh.cse_full) AS cse_full,
        SUM(wh.cse_loose) AS cse_loose,
        SUM(wh.number_of_full_pallets) AS number_of_full_pallets
    FROM analytics_workspace.reporting_schema.mv_test_loose_picking AS wh
    CROSS JOIN params AS p
    WHERE 1 = 1
        AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
        AND (p.p_from_date IS NULL OR wh.actual_ship_date >= p.p_from_date)
        AND (p.p_to_date IS NULL OR wh.actual_ship_date <= p.p_to_date)
    GROUP BY
        wh.whseid,
        wh."SO"
)
SELECT
    *,
    cse_full + cse_loose AS total_case,
    CASE
        WHEN cse_full + cse_loose = 0 THEN 0
        ELSE cse_loose * 100.0 / (cse_full + cse_loose)
    END AS pct_loose_picking
FROM summary
ORDER BY "SO";
```

**ClickHouse SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'                             AS p_whseid,
        toDateTime('2026-02-01 00:00:00') AS p_from_date,
        toDateTime('2026-02-28 23:59:59') AS p_to_date
)
SELECT
    whseid,
    cse_full,
    cse_loose,
    number_of_full_pallets,
    cse_full + cse_loose AS total_case,
    CASE
        WHEN cse_full + cse_loose = 0 THEN 0.0
        ELSE cse_loose * 100.0 / (cse_full + cse_loose)
    END AS pct_loose_picking
FROM (
    SELECT
        wh.whseid,
        SUM(ifNull(wh.cse_full, 0))               AS cse_full,
        SUM(ifNull(wh.cse_loose, 0))              AS cse_loose,
        SUM(ifNull(wh.number_of_full_pallets, 0)) AS number_of_full_pallets
    FROM analytics_workspace.mv_loose_picking_clickhouse AS wh
    CROSS JOIN params AS p
    WHERE 1= 1 
      AND (p_whseid = 'ALL' or wh.whseid = p_whseid)
      AND wh.actual_ship_date >= p.p_from_date
      AND wh.actual_ship_date <= p.p_to_date
    GROUP BY wh.whseid
) t
ORDER BY whseid;
```

### %LOOSE (WEIGHTED) = tổng cse loose/(tổng cse loose + tổng cse full) `Đã sửa`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                         -- đổi thành 'BKD1' để lọc 1 kho
        TIMESTAMP '2026-02-01 00:00:00' AS p_from_date,    -- ngày bắt đầu
        TIMESTAMP '2026-02-28 23:59:59' AS p_to_date       -- ngày kết thúc
),
summary AS (
    SELECT
        wh.whseid,
        wh."SO",
        SUM(wh.cse_full) AS cse_full,
        SUM(wh.cse_loose) AS cse_loose,
        SUM(wh.number_of_full_pallets) AS number_of_full_pallets
    FROM analytics_workspace.reporting_schema.mv_test_loose_picking AS wh
    CROSS JOIN params AS p
    WHERE 1 = 1
        AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
        AND (p.p_from_date IS NULL OR wh.actual_ship_date >= p.p_from_date)
        AND (p.p_to_date IS NULL OR wh.actual_ship_date <= p.p_to_date)
    GROUP BY
        wh.whseid,
        wh."SO"
)
SELECT
    *,
    cse_full + cse_loose AS total_case,
    CASE
        WHEN cse_full + cse_loose = 0 THEN 0
        ELSE cse_loose * 100.0 / (cse_full + cse_loose)
    END AS pct_loose_picking
FROM summary
ORDER BY "SO";
```

**ClickHouse SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'                             AS p_whseid,
        toDateTime('2026-02-01 00:00:00') AS p_from_date,
        toDateTime('2026-02-28 23:59:59') AS p_to_date
)
SELECT
    whseid,
    cse_full,
    cse_loose,
    number_of_full_pallets,
    cse_full + cse_loose AS total_case,
    CASE
        WHEN cse_full + cse_loose = 0 THEN 0.0
        ELSE cse_loose * 100.0 / (cse_full + cse_loose)
    END AS pct_loose_picking
FROM (
    SELECT
        wh.whseid,
        SUM(ifNull(wh.cse_full, 0))               AS cse_full,
        SUM(ifNull(wh.cse_loose, 0))              AS cse_loose,
        SUM(ifNull(wh.number_of_full_pallets, 0)) AS number_of_full_pallets
    FROM analytics_workspace.mv_loose_picking_clickhouse AS wh
    CROSS JOIN params AS p
    WHERE 1= 1 
      AND (p_whseid = 'ALL' or wh.whseid = p_whseid)
      AND wh.actual_ship_date >= p.p_from_date
      AND wh.actual_ship_date <= p.p_to_date
    GROUP BY wh.whseid
) t
ORDER BY whseid;
```

### % Loose theo Warehouse
Thay đổi từ chart %Loose theo Item code `Đã sửa`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                         -- đổi thành 'BKD1' để lọc 1 kho
        TIMESTAMP '2026-02-01 00:00:00' AS p_from_date,    -- ngày bắt đầu
        TIMESTAMP '2026-02-28 23:59:59' AS p_to_date       -- ngày kết thúc
),
summary AS (
    SELECT
        wh.whseid,
        SUM(wh.cse_full) AS cse_full,
        SUM(wh.cse_loose) AS cse_loose,
        SUM(wh.number_of_full_pallets) AS number_of_full_pallets
    FROM analytics_workspace.reporting_schema.mv_test_loose_picking AS wh
    CROSS JOIN params p
    WHERE 1 = 1
        AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
        AND (p.p_from_date IS NULL OR wh.actual_ship_date >= p.p_from_date)
        AND (p.p_to_date IS NULL OR wh.actual_ship_date <= p.p_to_date)
    GROUP BY
        wh.whseid
)
SELECT
    whseid,
    cse_full,
    cse_loose,
    number_of_full_pallets,
    cse_full + cse_loose AS total_case,
    CASE
        WHEN cse_full + cse_loose = 0 THEN 0
        ELSE cse_loose * 100.0 / (cse_full + cse_loose)
    END AS pct_loose_picking
FROM summary
ORDER BY whseid;
```

**ClickHouse SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'                             AS p_whseid,
        toDateTime('2026-02-01 00:00:00') AS p_from_date,
        toDateTime('2026-02-28 23:59:59') AS p_to_date
)
SELECT
    whseid,
    cse_full,
    cse_loose,
    number_of_full_pallets,
    cse_full + cse_loose AS total_case,
    CASE
        WHEN cse_full + cse_loose = 0 THEN 0.0
        ELSE cse_loose * 100.0 / (cse_full + cse_loose)
    END AS pct_loose_picking
FROM (
    SELECT
        wh.whseid,
        SUM(ifNull(wh.cse_full, 0))               AS cse_full,
        SUM(ifNull(wh.cse_loose, 0))              AS cse_loose,
        SUM(ifNull(wh.number_of_full_pallets, 0)) AS number_of_full_pallets
    FROM analytics_workspace.mv_loose_picking_clickhouse AS wh
    CROSS JOIN params AS p
    WHERE 1= 1 
      AND (p_whseid = 'ALL' or wh.whseid = p_whseid)
      AND wh.actual_ship_date >= p.p_from_date
      AND wh.actual_ship_date <= p.p_to_date
    GROUP BY wh.whseid
) t
ORDER BY whseid;
```

### Full vs Loose (CSE) `Đã sửa`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                         -- đổi thành 'BKD1' để lọc 1 kho
        TIMESTAMP '2026-02-01 00:00:00' AS p_from_date,    -- ngày bắt đầu
        TIMESTAMP '2026-02-28 23:59:59' AS p_to_date       -- ngày kết thúc
),
summary AS (
    SELECT
        wh.whseid,
        SUM(wh.cse_full) AS cse_full,
        SUM(wh.cse_loose) AS cse_loose,
        SUM(wh.number_of_full_pallets) AS number_of_full_pallets
    FROM analytics_workspace.reporting_schema.mv_test_loose_picking AS wh
    CROSS JOIN params p
    WHERE 1 = 1
        AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
        AND (p.p_from_date IS NULL OR wh.actual_ship_date >= p.p_from_date)
        AND (p.p_to_date IS NULL OR wh.actual_ship_date <= p.p_to_date)
    GROUP BY
        wh.whseid
)
SELECT
    whseid,
    cse_full,
    cse_loose,
    number_of_full_pallets,
    cse_full + cse_loose AS total_case,
    CASE
        WHEN cse_full + cse_loose = 0 THEN 0
        ELSE cse_loose * 100.0 / (cse_full + cse_loose)
    END AS pct_loose_picking
FROM summary
ORDER BY whseid;
```

**ClickHouse SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'                             AS p_whseid,
        toDateTime('2026-02-01 00:00:00') AS p_from_date,
        toDateTime('2026-02-28 23:59:59') AS p_to_date
)
SELECT
    whseid,
    cse_full,
    cse_loose,
    number_of_full_pallets,
    cse_full + cse_loose AS total_case,
    CASE
        WHEN cse_full + cse_loose = 0 THEN 0.0
        ELSE cse_loose * 100.0 / (cse_full + cse_loose)
    END AS pct_loose_picking
FROM (
    SELECT
        wh.whseid,
        SUM(ifNull(wh.cse_full, 0))               AS cse_full,
        SUM(ifNull(wh.cse_loose, 0))              AS cse_loose,
        SUM(ifNull(wh.number_of_full_pallets, 0)) AS number_of_full_pallets
    FROM analytics_workspace.mv_loose_picking_clickhouse AS wh
    CROSS JOIN params AS p
    WHERE 1= 1 
      AND (p_whseid = 'ALL' or wh.whseid = p_whseid)
      AND wh.actual_ship_date >= p.p_from_date
      AND wh.actual_ship_date <= p.p_to_date
    GROUP BY wh.whseid
) t
ORDER BY whseid;
```

### Xu hướng % Loose theo ngày giao `Đã sửa`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                         -- đổi thành 'BKD1' để lọc 1 kho
        TIMESTAMP '2026-02-01 00:00:00' AS p_from_date,    -- ngày bắt đầu
        TIMESTAMP '2026-03-01 00:00:00' AS p_to_date       -- ngày kết thúc (exclusive)
)
SELECT
    wh.whseid,
    CAST(wh.actual_ship_date AS DATE) AS ship_date,
    SUM(wh.cse_full) AS cse_full,
    SUM(wh.cse_loose) AS cse_loose,
    SUM(wh.number_of_full_pallets) AS number_of_full_pallets,
    SUM(wh.cse_full) + SUM(wh.cse_loose) AS total_case,
    CASE
        WHEN SUM(wh.cse_full) + SUM(wh.cse_loose) = 0 THEN 0
        ELSE SUM(wh.cse_loose) * 100.0 / (SUM(wh.cse_full) + SUM(wh.cse_loose))
    END AS pct_loose_picking
FROM analytics_workspace.reporting_schema.mv_test_loose_picking AS wh
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
    AND wh.actual_ship_date >= p.p_from_date
    AND wh.actual_ship_date < p.p_to_date
GROUP BY
    wh.whseid,
    CAST(wh.actual_ship_date AS DATE)
ORDER BY
    wh.whseid,
    ship_date;
```

**ClickHouse SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                         -- đổi thành 'BKD1' để lọc 1 kho
        TIMESTAMP '2026-02-01 00:00:00' AS p_from_date,    -- ngày bắt đầu
        TIMESTAMP '2026-03-01 00:00:00' AS p_to_date       -- ngày kết thúc (exclusive)
)
SELECT
    wh.whseid,
    CAST(wh.actual_ship_date AS DATE) AS ship_date,
    SUM(wh.cse_full) AS cse_full,
    SUM(wh.cse_loose) AS cse_loose,
    SUM(wh.number_of_full_pallets) AS number_of_full_pallets,
    SUM(wh.cse_full) + SUM(wh.cse_loose) AS total_case,
    CASE
        WHEN SUM(wh.cse_full) + SUM(wh.cse_loose) = 0 THEN 0
        ELSE SUM(wh.cse_loose) * 100.0 / (SUM(wh.cse_full) + SUM(wh.cse_loose))
    END AS pct_loose_picking
FROM analytics_workspace.mv_loose_picking_clickhouse AS wh
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
    AND wh.actual_ship_date >= p.p_from_date
    AND wh.actual_ship_date < p.p_to_date
GROUP BY
    wh.whseid,
    CAST(wh.actual_ship_date AS DATE)
ORDER BY
    wh.whseid,
    ship_date;
```

### Top SKU theo tổng thùng lẻ `Đã sửa`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                         -- đổi thành 'BKD1' để lọc 1 kho
        TIMESTAMP '2026-02-01 00:00:00' AS p_from_date,    -- ngày bắt đầu
        TIMESTAMP '2026-03-01 00:00:00' AS p_to_date       -- ngày kết thúc (exclusive)
)
SELECT
    wh.item_code,
    SUM(wh.cse_loose) AS cse_loose
FROM analytics_workspace.reporting_schema.mv_test_loose_picking AS wh
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
    AND wh.actual_ship_date >= p.p_from_date
    AND wh.actual_ship_date < p.p_to_date
GROUP BY
    wh.item_code
ORDER BY
    cse_loose DESC;
```

**ClickHouse SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                         -- đổi thành 'BKD1' để lọc 1 kho
        TIMESTAMP '2026-02-01 00:00:00' AS p_from_date,    -- ngày bắt đầu
        TIMESTAMP '2026-03-01 00:00:00' AS p_to_date       -- ngày kết thúc (exclusive)
)
SELECT
    wh.whseid,
    CAST(wh.actual_ship_date AS DATE) AS ship_date,
    SUM(wh.cse_full) AS cse_full,
    SUM(wh.cse_loose) AS cse_loose,
    SUM(wh.number_of_full_pallets) AS number_of_full_pallets,
    SUM(wh.cse_full) + SUM(wh.cse_loose) AS total_case,
    CASE
        WHEN SUM(wh.cse_full) + SUM(wh.cse_loose) = 0 THEN 0
        ELSE SUM(wh.cse_loose) * 100.0 / (SUM(wh.cse_full) + SUM(wh.cse_loose))
    END AS pct_loose_picking
FROM analytics_workspace.mv_loose_picking_clickhouse AS wh
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
    AND wh.actual_ship_date >= p.p_from_date
    AND wh.actual_ship_date < p.p_to_date
GROUP BY
    wh.whseid,
    CAST(wh.actual_ship_date AS DATE)
ORDER BY
    wh.whseid,
    ship_date;
```

### pivot customer/region `Đã sửa`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                        
        TIMESTAMP '2026-04-14 00:00:00' AS p_from_date,   
        TIMESTAMP '2026-04-14 23:59:59' AS p_to_date      
)
SELECT
    wh."customer_code",
    wh."customer_name",
    wh."region",
    wh.actual_ship_date,
    SUM(wh.cse_full)  AS cse_full,
    SUM(wh.cse_loose) AS cse_loose,
    CASE
        WHEN SUM(wh.cse_loose) + SUM(wh.cse_full) = 0 THEN 0
        ELSE SUM(wh.cse_loose)::DECIMAL(18,6)
             / (SUM(wh.cse_loose) + SUM(wh.cse_full))
    END AS pct_loose_picking
FROM analytics_workspace.reporting_schema.mv_test_loose_picking AS wh
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
    AND wh.actual_ship_date >= p.p_from_date
    AND wh.actual_ship_date <= p.p_to_date
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4;
```

**ClickHouse SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                        
        TIMESTAMP '2026-04-14 00:00:00' AS p_from_date,   
        TIMESTAMP '2026-04-14 23:59:59' AS p_to_date      
)
SELECT
        wh."whseid",
    wh."customer_code",
    wh."customer_name",
    wh."region",
    wh.actual_ship_date,
    SUM(wh.cse_full)  AS cse_full,
    SUM(wh.cse_loose) AS cse_loose,
    CASE
        WHEN SUM(wh.cse_loose) + SUM(wh.cse_full) = 0 THEN 0
        ELSE SUM(wh.cse_loose)::DECIMAL(18,6)
             / (SUM(wh.cse_loose) + SUM(wh.cse_full))
    END AS pct_loose_picking
FROM analytics_workspace.mv_loose_picking_clickhouse AS wh
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
    AND wh.actual_ship_date >= p.p_from_date
    AND wh.actual_ship_date <= p.p_to_date
GROUP BY 1,2,3,4,5
ORDER BY 1,2,3,4,5
```

### Report raw data `Đã sửa`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                        
        TIMESTAMP '2026-04-14 00:00:00' AS p_from_date,   
        TIMESTAMP '2026-04-14 23:59:59' AS p_to_date      
)
SELECT
    wh."customer_code",
    wh."customer_name",
    wh."region",
    wh.actual_ship_date,
    SUM(wh.cse_full)  AS cse_full,
    SUM(wh.cse_loose) AS cse_loose,
    CASE
        WHEN SUM(wh.cse_loose) + SUM(wh.cse_full) = 0 THEN 0
        ELSE SUM(wh.cse_loose)::DECIMAL(18,6)
             / (SUM(wh.cse_loose) + SUM(wh.cse_full))
    END AS pct_loose_picking
FROM analytics_workspace.reporting_schema.mv_test_loose_picking AS wh
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
    AND wh.actual_ship_date >= p.p_from_date
    AND wh.actual_ship_date <= p.p_to_date
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4;
```

**ClickHouse SQL:**

```sql
WITH params AS (
    SELECT
        'ALL' AS p_whseid,
        toDateTime('2026-04-14 00:00:00') AS p_from_date,
        toDateTime('2026-04-14 23:59:59') AS p_to_date
),
base AS (
    SELECT
        wh.whseid,
        wh.customer_code,
        wh.customer_name,
        wh.region,
        wh.actual_ship_date,
        SUM(wh.cse_full)  AS cse_full,
        SUM(wh.cse_loose) AS cse_loose,
        if(
            SUM(wh.cse_loose) + SUM(wh.cse_full) = 0,
            0,
            toFloat64(SUM(wh.cse_loose)) / (SUM(wh.cse_loose) + SUM(wh.cse_full))
        ) AS pct_loose_picking
    FROM mv_loose_picking_clickhouse AS wh
    CROSS JOIN params AS p
    WHERE 1 = 1
        AND (p.p_whseid = 'ALL' OR wh.whseid = p.p_whseid)
        AND wh.actual_ship_date >= p.p_from_date
        AND wh.actual_ship_date <= p.p_to_date
    GROUP BY 1, 2, 3, 4, 5
    ORDER BY 1, 2, 3, 4, 5
),
pivot_data AS (
    SELECT
        customer_code,
        customer_name,
        region,
        SUM(cse_full)   AS total_cse_full,
        SUM(cse_loose)  AS total_cse_loose,
        SUM(cse_full) + SUM(cse_loose) AS total_case,
        if(
            SUM(cse_full) + SUM(cse_loose) = 0,
            0,
            toFloat64(SUM(cse_loose)) / (SUM(cse_full) + SUM(cse_loose))
        ) AS pct_loose_picking
    FROM base
    GROUP BY
        customer_code,
        customer_name,
        region
)
SELECT
    customer_code       AS "Customer Code",
    customer_name       AS "Customer Name",
    region              AS "Region",
    total_cse_full      AS "Total CSE Full",
    total_cse_loose     AS "Total CSE Loose",
    total_case          AS "Total Case",
    round(pct_loose_picking * 100, 2) AS "% Loose Picking"
FROM pivot_data
ORDER BY
    region,
    customer_name;
```

---

## copack - ngừng develop

### Total pallet in `Đã sửa`

**Redshift SQL:**

```sql
WITH
    'ALL' AS p_whseid,   -- đổi thành 'BKD1' nếu muốn lọc 1 kho
    toDateTime('2026-01-01 00:00:00') AS p_from,
    toDateTime('2026-01-31 23:59:59') AS p_to
SELECT
    whseid,
    sum(ifNull(`Pallet In`, 0)) AS total_pallet_in,
    sum(ifNull(`Pallet Out`, 0)) AS total_pallet_out,
    sum(ifNull(`Pallet In`, 0)) - sum(ifNull(`Pallet Out`, 0)) AS net_pallet
FROM mondelez_swm_test.mv_copack
WHERE (p_whseid = 'ALL' OR whseid = p_whseid)
  AND date_in_out >= p_from
  AND date_in_out <= p_to
GROUP BY whseid
ORDER BY whseid;
```

### Total pallet out `Đã sửa`

**Redshift SQL:**

```sql
WITH
    'ALL' AS p_whseid,   -- đổi thành 'BKD1' nếu muốn lọc 1 kho
    toDateTime('2026-01-01 00:00:00') AS p_from,
    toDateTime('2026-01-31 23:59:59') AS p_to
SELECT
    whseid,
    sum(ifNull(`Pallet In`, 0)) AS total_pallet_in,
    sum(ifNull(`Pallet Out`, 0)) AS total_pallet_out,
    sum(ifNull(`Pallet In`, 0)) - sum(ifNull(`Pallet Out`, 0)) AS net_pallet
FROM mondelez_swm_test.mv_copack
WHERE (p_whseid = 'ALL' OR whseid = p_whseid)
  AND date_in_out >= p_from
  AND date_in_out <= p_to
GROUP BY whseid
ORDER BY whseid;
```

### Net Pallets (In − Out) `Đã sửa`

**Redshift SQL:**

```sql
WITH
    'ALL' AS p_whseid,   -- đổi thành 'BKD1' nếu muốn lọc 1 kho
    toDateTime('2026-01-01 00:00:00') AS p_from,
    toDateTime('2026-01-31 23:59:59') AS p_to
SELECT
    whseid,
    sum(ifNull(`Pallet In`, 0)) AS total_pallet_in,
    sum(ifNull(`Pallet Out`, 0)) AS total_pallet_out,
    sum(ifNull(`Pallet In`, 0)) - sum(ifNull(`Pallet Out`, 0)) AS net_pallet
FROM mondelez_swm_test.mv_copack
WHERE (p_whseid = 'ALL' OR whseid = p_whseid)
  AND date_in_out >= p_from
  AND date_in_out <= p_to
GROUP BY whseid
ORDER BY whseid;
```

### Pallet In vs Out theo ngày `Đã sửa`

**Redshift SQL:**

```sql
WITH
    'ALL' AS p_whseid,   -- đổi thành 'BKD1' nếu muốn lọc 1 kho
    toDateTime('2026-01-01 00:00:00') AS p_from,
    toDateTime('2026-01-31 23:59:59') AS p_to
SELECT *
FROM mondelez_swm_test.mv_copack
WHERE (p_whseid = 'ALL' OR whseid = p_whseid)
  AND date_in_out >= p_from
  AND date_in_out <= p_to
ORDER BY whseid, date_in_out;
```

### Pallet In vs Out theo warehouse `Đã sửa`

**Redshift SQL:**

```sql
WITH
    'ALL' AS p_whseid,   -- đổi thành 'BKD1' nếu muốn lọc 1 kho
    toDateTime('2026-01-01 00:00:00') AS p_from,
    toDateTime('2026-01-31 23:59:59') AS p_to
SELECT
    whseid,
    sum(ifNull(`Pallet In`, 0)) AS total_pallet_in,
    sum(ifNull(`Pallet Out`, 0)) AS total_pallet_out
FROM mondelez_swm_test.mv_copack
WHERE (p_whseid = 'ALL' OR whseid = p_whseid)
  AND date_in_out >= p_from
  AND date_in_out <= p_to
GROUP BY whseid
ORDER BY whseid;
```

### Net pallet theo warehouse `Đã sửa`

**Redshift SQL:**

```sql
WITH
    'ALL' AS p_whseid,   -- đổi thành 'BKD1' nếu muốn lọc 1 kho
    toDateTime('2026-01-01 00:00:00') AS p_from,
    toDateTime('2026-01-31 23:59:59') AS p_to
SELECT
    whseid,
    sum(ifNull(`Pallet In`, 0)) AS total_pallet_in,
    sum(ifNull(`Pallet Out`, 0)) AS total_pallet_out,
    sum(ifNull(`Pallet In`, 0)) - sum(ifNull(`Pallet Out`, 0)) AS net_pallet
FROM your_table_name
WHERE (p_whseid = 'ALL' OR whseid = p_whseid)
  AND date_in_out >= p_from
  AND date_in_out <= p_to
GROUP BY whseid
ORDER BY whseid;
```

---

## trung chuyển - ngừng develop

### INBOUND PALLET

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::varchar AS p_whseid,  -- đổi thành 'BKD1' nếu muốn lọc 1 kho
        TIMESTAMP '2021-12-24 00:00:00' AS p_from,
        TIMESTAMP '2021-12-28 23:59:59' AS p_to
)
SELECT
    t.whseid,
    SUM(COALESCE(t.pallet_in, 0)) AS total_pallet_in,
    SUM(COALESCE(t.pallet_out, 0)) AS total_pallet_out,
    SUM(COALESCE(t.pallet_in, 0)) - SUM(COALESCE(t.pallet_out, 0)) AS net_pallet,
    ROUND(
        (SUM(COALESCE(t.pallet_in, 0)) - SUM(COALESCE(t.pallet_out, 0))) / 16.0,
        2
    ) AS net_truck
FROM reporting_schema.mv_test_transfer_in_out t
CROSS JOIN params p
WHERE (p.p_whseid = 'ALL' OR t.whseid = p.p_whseid)
  AND t.date_transfer >= p.p_from
  AND t.date_transfer <= p.p_to
GROUP BY t.whseid
ORDER BY t.whseid;
```

### OUTBOUND PALLET

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::varchar AS p_whseid,  -- đổi thành 'BKD1' nếu muốn lọc 1 kho
        TIMESTAMP '2021-12-24 00:00:00' AS p_from,
        TIMESTAMP '2021-12-28 23:59:59' AS p_to
)
SELECT
    t.whseid,
    SUM(COALESCE(t.pallet_in, 0)) AS total_pallet_in,
    SUM(COALESCE(t.pallet_out, 0)) AS total_pallet_out,
    SUM(COALESCE(t.pallet_in, 0)) - SUM(COALESCE(t.pallet_out, 0)) AS net_pallet,
    ROUND(
        (SUM(COALESCE(t.pallet_in, 0)) - SUM(COALESCE(t.pallet_out, 0))) / 16.0,
        2
    ) AS net_truck
FROM reporting_schema.mv_test_transfer_in_out t
CROSS JOIN params p
WHERE (p.p_whseid = 'ALL' OR t.whseid = p.p_whseid)
  AND t.date_transfer >= p.p_from
  AND t.date_transfer <= p.p_to
GROUP BY t.whseid
ORDER BY t.whseid;
```

### NET PALLETS

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::varchar AS p_whseid,  -- đổi thành 'BKD1' nếu muốn lọc 1 kho
        TIMESTAMP '2021-12-24 00:00:00' AS p_from,
        TIMESTAMP '2021-12-28 23:59:59' AS p_to
)
SELECT
    t.whseid,
    SUM(COALESCE(t.pallet_in, 0)) AS total_pallet_in,
    SUM(COALESCE(t.pallet_out, 0)) AS total_pallet_out,
    SUM(COALESCE(t.pallet_in, 0)) - SUM(COALESCE(t.pallet_out, 0)) AS net_pallet,
    ROUND(
        (SUM(COALESCE(t.pallet_in, 0)) - SUM(COALESCE(t.pallet_out, 0))) / 16.0,
        2
    ) AS net_truck
FROM reporting_schema.mv_test_transfer_in_out t
CROSS JOIN params p
WHERE (p.p_whseid = 'ALL' OR t.whseid = p.p_whseid)
  AND t.date_transfer >= p.p_from
  AND t.date_transfer <= p.p_to
GROUP BY t.whseid
ORDER BY t.whseid;
```

### NET TRUCK LOADS

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::varchar AS p_whseid,  -- đổi thành 'BKD1' nếu muốn lọc 1 kho
        TIMESTAMP '2021-12-24 00:00:00' AS p_from,
        TIMESTAMP '2021-12-28 23:59:59' AS p_to
)
SELECT
    t.whseid,
    SUM(COALESCE(t.pallet_in, 0)) AS total_pallet_in,
    SUM(COALESCE(t.pallet_out, 0)) AS total_pallet_out,
    SUM(COALESCE(t.pallet_in, 0)) - SUM(COALESCE(t.pallet_out, 0)) AS net_pallet,
    ROUND(
        (SUM(COALESCE(t.pallet_in, 0)) - SUM(COALESCE(t.pallet_out, 0))) / 16.0,
        2
    ) AS net_truck
FROM reporting_schema.mv_test_transfer_in_out t
CROSS JOIN params p
WHERE (p.p_whseid = 'ALL' OR t.whseid = p.p_whseid)
  AND t.date_transfer >= p.p_from
  AND t.date_transfer <= p.p_to
GROUP BY t.whseid
ORDER BY t.whseid;
```

### IN vs OUT by day

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        CAST('ALL' AS VARCHAR(20)) AS p_whseid,   -- đổi thành 'BKD1' nếu muốn lọc 1 kho
        CAST('2021-12-24 00:00:00' AS TIMESTAMP) AS p_from,
        CAST('2021-12-28 23:59:59' AS TIMESTAMP) AS p_to
)
SELECT
    t.*,
    COALESCE(t.pallet_in, 0) - COALESCE(t.pallet_out, 0) AS net_pallet
FROM reporting_schema.mv_test_transfer_in_out AS t
CROSS JOIN params AS p
WHERE (p.p_whseid = 'ALL' OR t.whseid = p.p_whseid)
  AND t.date_transfer >= p.p_from
  AND t.date_transfer <= p.p_to
ORDER BY t.whseid, t.date_transfer;
```

### Net pallets by day

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        CAST('ALL' AS VARCHAR(20)) AS p_whseid,   -- đổi thành 'BKD1' nếu muốn lọc 1 kho
        CAST('2021-12-24 00:00:00' AS TIMESTAMP) AS p_from,
        CAST('2021-12-28 23:59:59' AS TIMESTAMP) AS p_to
)
SELECT
    t.*,
    COALESCE(t.pallet_in, 0) - COALESCE(t.pallet_out, 0) AS net_pallet
FROM reporting_schema.mv_test_transfer_in_out AS t
CROSS JOIN params AS p
WHERE (p.p_whseid = 'ALL' OR t.whseid = p.p_whseid)
  AND t.date_transfer >= p.p_from
  AND t.date_transfer <= p.p_to
ORDER BY t.whseid, t.date_transfer;
```

### By warehouse (tổng in/tổng out)

**Redshift SQL:**

```sql
WITH params AS (

    SELECT

        CAST('ALL' AS VARCHAR(20)) AS p_whseid,   -- đổi thành 'BKD1' nếu muốn lọc 1 kho

        CAST('2021-12-06 00:00:00' AS TIMESTAMP) AS p_from,

        CAST('2021-12-10 23:59:59' AS TIMESTAMP) AS p_to

)

SELECT

    t.whseid,

    SUM(COALESCE(t.pallet_in, 0)) AS total_pallet_in,

    SUM(COALESCE(t.pallet_out, 0)) AS total_pallet_out

FROM reporting_schema.mv_test_transfer_in_out AS t

CROSS JOIN params AS p

WHERE (p.p_whseid = 'ALL' OR t.whseid = p.p_whseid)

  AND t.date_transfer >= p.p_from

  AND t.date_transfer <= p.p_to

GROUP BY t.whseid

ORDER BY t.whseid;
```

### Status mix

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        CAST('ALL' AS VARCHAR(20)) AS p_whseid,   -- đổi thành 'BKD1' nếu muốn lọc 1 kho
        CAST('2021-12-06 00:00:00' AS TIMESTAMP) AS p_from,
        CAST('2021-12-10 23:59:59' AS TIMESTAMP) AS p_to
),
base AS (
    SELECT
        t.status,
        COUNT(DISTINCT CAST(t.date_transfer AS DATE)) AS day_count
    FROM reporting_schema.mv_test_transfer_in_out AS t
    CROSS JOIN params AS p
    WHERE (p.p_whseid = 'ALL' OR t.whseid = p.p_whseid)
      AND t.date_transfer >= p.p_from
      AND t.date_transfer <= p.p_to
    GROUP BY t.status
)
SELECT
    status,
    day_count,
    ROUND(
        100.0 * day_count
        / NULLIF(SUM(day_count) OVER (), 0),
        2
    ) AS ratio_pct
FROM base
ORDER BY day_count DESC, status;
```

---

## nhập từ xưởng - ngừng develop

### TODAY (PALLETS)

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::varchar AS p_whseid   -- đổi thành 'NKD' để lọc 1 kho
)
SELECT
    t.whseid,
    SUM(t.pallet) AS total_pallet_today
FROM analytics_workspace.reporting_schema.mv_test_goods_receipt t
CROSS JOIN params p
WHERE (p.p_whseid = 'ALL' OR t.whseid = p.p_whseid)
  AND CAST(t.date_received AS DATE) = CURRENT_DATE
GROUP BY t.whseid
ORDER BY t.whseid;
```

### MTD TOTAL

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::varchar AS p_whseid   -- đổi thành 'NKD' để lọc 1 kho
)
SELECT
    g.whseid,
    SUM(g.pallet) AS total_pallet_mtd
FROM analytics_workspace.reporting_schema.mv_test_goods_receipt g
CROSS JOIN params p
WHERE
    (p.p_whseid = 'ALL' OR g.whseid = p.p_whseid)
    AND CAST(g.date_received AS DATE) >= DATE_TRUNC('month', CURRENT_DATE)::date
    AND CAST(g.date_received AS DATE) <= CURRENT_DATE
GROUP BY g.whseid
ORDER BY g.whseid;
```

### AVG LAST 7 DAYS

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::varchar AS p_whseid   -- đổi thành 'NKD' để lọc 1 kho
)
SELECT
    g.whseid,
    ROUND(SUM(g.pallet) / 7.0, 2) AS avg_pallet_last_7_days
FROM analytics_workspace.reporting_schema.mv_test_goods_receipt g
CROSS JOIN params p
WHERE
    (p.p_whseid = 'ALL' OR g.whseid = p.p_whseid)
    AND CAST(g.date_received AS DATE) BETWEEN CURRENT_DATE - 6 AND CURRENT_DATE
GROUP BY g.whseid
ORDER BY g.whseid;
```

### MAX DAY

**Redshift SQL:**

```sql
BỎ CHART NÀY
```

### Daily inbound pallets

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::varchar AS p_whseid,
        DATE '2025-05-01' AS p_from_date,
        DATE '2025-05-31' AS p_to_date
)
SELECT
    received_date,
    whseid,
    SUM(pallet) AS total_pallet
FROM (
    SELECT
        CAST(g.date_received AS DATE) AS received_date,
        g.whseid,
        g.pallet
    FROM analytics_workspace.reporting_schema.mv_test_goods_receipt g
    CROSS JOIN params p
    WHERE
        (p.p_whseid = 'ALL' OR g.whseid = p.p_whseid)
        AND CAST(g.date_received AS DATE) BETWEEN p.p_from_date AND p.p_to_date
) s
GROUP BY
    received_date,
    whseid
ORDER BY
    received_date,
    whseid;
```

### MTD cummulative inbound

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::varchar AS p_whseid,
        DATE '2025-05-01' AS p_from_date,
        DATE '2025-05-31' AS p_to_date
),
daily_data AS (
    SELECT
        CAST(g.date_received AS DATE) AS received_date,
        g.whseid,
        SUM(CAST(g.pallet AS INTEGER)) AS total_pallet
    FROM analytics_workspace.reporting_schema.mv_test_goods_receipt g
    CROSS JOIN params p
    WHERE
        (p.p_whseid = 'ALL' OR g.whseid = p.p_whseid)
        AND CAST(g.date_received AS DATE) BETWEEN p.p_from_date AND p.p_to_date
    GROUP BY
        CAST(g.date_received AS DATE),
        g.whseid
)
SELECT
    received_date,
    whseid,
    total_pallet,
    SUM(total_pallet) OVER (
        PARTITION BY whseid
        ORDER BY received_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_pallet
FROM daily_data
ORDER BY
    whseid,
    received_date;
```

### Inbound Intensity

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,
        DATE '2025-05-01' AS p_from_date,
        DATE '2025-05-31' AS p_to_date
)
SELECT
    CAST(g.date_received AS DATE) AS received_date,
    SUM(CAST(g.pallet AS INTEGER)) AS total_pallet
FROM analytics_workspace.reporting_schema.mv_test_goods_receipt g
CROSS JOIN params p
WHERE
    (p.p_whseid = 'ALL' OR g.whseid = p.p_whseid)
    AND CAST(g.date_received AS DATE) BETWEEN p.p_from_date AND p.p_to_date
GROUP BY
    CAST(g.date_received AS DATE)
ORDER BY
    received_date;
```

### Report raw

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,
        DATE '2025-05-01' AS p_from_date,
        DATE '2025-05-31' AS p_to_date
)
SELECT
    CAST(g.date_received AS DATE) AS date_received,
    g.whseid,
    CAST(g.pallet AS INTEGER) AS pallet
FROM analytics_workspace.reporting_schema.mv_test_goods_receipt g
CROSS JOIN params p
WHERE
    (p.p_whseid = 'ALL' OR g.whseid = p.p_whseid)
    AND CAST(g.date_received AS DATE) BETWEEN p.p_from_date AND p.p_to_date
ORDER BY
    date_received,
    g.whseid;
```

---

## Stock type

### Total Inventory (CSE) `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT 
        'ALL'::VARCHAR AS p_whse,
        'ALL'::VARCHAR AS p_cargo,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_storer
)
SELECT 
    SUM(qty_cse) AS total_inventory_cse
FROM analytics_workspace.reporting_schema.mv_test_stocktype
CROSS JOIN constants
WHERE 
    -- Filter Warehouse
    (p_whse = 'ALL' OR whseid = p_whse)
    
    -- Filter Cargo Group (Sử dụng COALESCE thay cho ifNull)
    AND (p_cargo = 'ALL' OR COALESCE(group_of_cargo, 'Unclassified') = p_cargo)
    
    -- Filter Brand
    AND (p_brand = 'ALL' OR brand = p_brand)
    
    -- Filter Storer
    AND (p_storer = 'ALL' OR storer_key = p_storer)
```

**ClickHouse SQL:**

```sql
SELECT 
        SUM(qty_cse) AS total_inventory_cse,
    SUM(qty_pl ) AS total_inventory_pl,
    SUM(qty) AS total_inventory_masterunits,
    SUM(qty_cbm) AS total_qty_cbm,
    SUM(qty_ton) AS total_qty_ton
FROM analytics_workspace.mv_stocktype 
WHERE 
    1 =1 
    -- Warehouse
        AND if(
            arraySort([{{whseid}}]) = (
                SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
            ),
            1 = 1,
            whseid IN ({{whseid}})
        )
    
    -- Filter Cargo Group
    AND if(
            arraySort([{{cargo}}]) = (
                SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            group_of_cargo IN ({{cargo}})
    
    -- Filter Brand
    AND if(
            arraySort([{{brand}}]) = (
                SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            brand IN ({{brand}})
```

### Total Inventory (Pallet) `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    -- Khởi tạo tham số dưới dạng một bảng tạm (CTE)
    SELECT 
        'ALL'::VARCHAR AS p_whse,
        'ALL'::VARCHAR AS p_cargo,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_storer
)
SELECT 
    SUM(qty_pl) AS total_inventory_pl
FROM analytics_workspace.reporting_schema.mv_test_stocktype
CROSS JOIN constants
WHERE 
    -- Filter Kho
    (p_whse = 'ALL' OR whseid = p_whse)
    
    -- Filter Nhóm hàng (Sử dụng COALESCE thay cho ifNull của ClickHouse)
    AND (p_cargo = 'ALL' OR COALESCE(group_of_cargo, 'Unclassified') = p_cargo)
    
    -- Filter Thương hiệu
    AND (p_brand = 'ALL' OR brand = p_brand)
    
    -- Filter Khách hàng (Storer)
    AND (p_storer = 'ALL' OR storer_key = p_storer)
```

**ClickHouse SQL:**

```sql
SELECT 
        SUM(qty_cse) AS total_inventory_cse,
    SUM(qty_pl ) AS total_inventory_pl,
    SUM(qty) AS total_inventory_masterunits,
    SUM(qty_cbm) AS total_qty_cbm,
    SUM(qty_ton) AS total_qty_ton
FROM analytics_workspace.mv_stocktype 
WHERE 
    1 =1 
    -- Warehouse
        AND if(
            arraySort([{{whseid}}]) = (
                SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
            ),
            1 = 1,
            whseid IN ({{whseid}})
        )
    
    -- Filter Cargo Group
    AND if(
            arraySort([{{cargo}}]) = (
                SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            group_of_cargo IN ({{cargo}})
    
    -- Filter Brand
    AND if(
            arraySort([{{brand}}]) = (
                SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            brand IN ({{brand}})
```

### Master units `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    -- Khởi tạo các tham số lọc tương tự như cách khai báo trong ClickHouse
    SELECT 
        'ALL'::VARCHAR AS p_whse,
        'ALL'::VARCHAR AS p_cargo,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_storer
)
SELECT 
    SUM(qty) AS master_units
FROM analytics_workspace.reporting_schema.mv_test_stocktype
CROSS JOIN constants
WHERE 
    -- Filter theo Kho
    (p_whse = 'ALL' OR whseid = p_whse)
    
    -- Filter theo Nhóm hàng (Sử dụng COALESCE thay cho ifNull)
    AND (p_cargo = 'ALL' OR COALESCE(group_of_cargo, 'Unclassified') = p_cargo)
    
    -- Filter theo Thương hiệu
    AND (p_brand = 'ALL' OR brand = p_brand)
    
    -- Filter theo Khách hàng (Storer)
    AND (p_storer = 'ALL' OR storer_key = p_storer)
```

**ClickHouse SQL:**

```sql
SELECT 
        SUM(qty_cse) AS total_inventory_cse,
    SUM(qty_pl ) AS total_inventory_pl,
    SUM(qty) AS total_inventory_masterunits,
    SUM(qty_cbm) AS total_qty_cbm,
    SUM(qty_ton) AS total_qty_ton
FROM analytics_workspace.mv_stocktype 
WHERE 
    1 =1 
    -- Warehouse
        AND if(
            arraySort([{{whseid}}]) = (
                SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
            ),
            1 = 1,
            whseid IN ({{whseid}})
        )
    
    -- Filter Cargo Group
    AND if(
            arraySort([{{cargo}}]) = (
                SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            group_of_cargo IN ({{cargo}})
    
    -- Filter Brand
    AND if(
            arraySort([{{brand}}]) = (
                SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            brand IN ({{brand}})
```

### Volume · CBM `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT 
        'ALL'::VARCHAR AS p_whse,
        'ALL'::VARCHAR AS p_cargo,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_storer
)
SELECT 
    SUM(qty_cbm) AS total_qty_cbm,
    SUM(qty_ton) AS total_qty_ton
FROM analytics_workspace.reporting_schema.mv_test_stocktype
CROSS JOIN constants
WHERE 
    -- Lọc theo Kho
    (p_whse = 'ALL' OR whseid = p_whse)
    
    -- Lọc theo Nhóm hàng (Sử dụng COALESCE thay cho ifNull)
    AND (p_cargo = 'ALL' OR COALESCE(group_of_cargo, 'Unclassified') = p_cargo)
    
    -- Lọc theo Thương hiệu
    AND (p_brand = 'ALL' OR brand = p_brand)
    
    -- Lọc theo Khách hàng (Storer)
    AND (p_storer = 'ALL' OR storer_key = p_storer)
```

**ClickHouse SQL:**

```sql
SELECT 
        SUM(qty_cse) AS total_inventory_cse,
    SUM(qty_pl ) AS total_inventory_pl,
    SUM(qty) AS total_inventory_masterunits,
    SUM(qty_cbm) AS total_qty_cbm,
    SUM(qty_ton) AS total_qty_ton
FROM analytics_workspace.mv_stocktype 
WHERE 
    1 =1 
    -- Warehouse
        AND if(
            arraySort([{{whseid}}]) = (
                SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
            ),
            1 = 1,
            whseid IN ({{whseid}})
        )
    
    -- Filter Cargo Group
    AND if(
            arraySort([{{cargo}}]) = (
                SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            group_of_cargo IN ({{cargo}})
    
    -- Filter Brand
    AND if(
            arraySort([{{brand}}]) = (
                SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            brand IN ({{brand}})
```

### Volume ·  Ton `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT 
        'ALL'::VARCHAR AS p_whse,
        'ALL'::VARCHAR AS p_cargo,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_storer
)
SELECT 
    SUM(qty_cbm) AS total_qty_cbm,
    SUM(qty_ton) AS total_qty_ton
FROM analytics_workspace.reporting_schema.mv_test_stocktype
CROSS JOIN constants
WHERE 
    -- Lọc theo Kho
    (p_whse = 'ALL' OR whseid = p_whse)
    
    -- Lọc theo Nhóm hàng (Sử dụng COALESCE thay cho ifNull)
    AND (p_cargo = 'ALL' OR COALESCE(group_of_cargo, 'Unclassified') = p_cargo)
    
    -- Lọc theo Thương hiệu
    AND (p_brand = 'ALL' OR brand = p_brand)
    
    -- Lọc theo Khách hàng (Storer)
    AND (p_storer = 'ALL' OR storer_key = p_storer)
```

**ClickHouse SQL:**

```sql
SELECT 
        SUM(qty_cse) AS total_inventory_cse,
    SUM(qty_pl ) AS total_inventory_pl,
    SUM(qty) AS total_inventory_masterunits,
    SUM(qty_cbm) AS total_qty_cbm,
    SUM(qty_ton) AS total_qty_ton
FROM analytics_workspace.mv_stocktype 
WHERE 
    1 =1 
    -- Warehouse
        AND if(
            arraySort([{{whseid}}]) = (
                SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
            ),
            1 = 1,
            whseid IN ({{whseid}})
        )
    
    -- Filter Cargo Group
    AND if(
            arraySort([{{cargo}}]) = (
                SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            group_of_cargo IN ({{cargo}})
    
    -- Filter Brand
    AND if(
            arraySort([{{brand}}]) = (
                SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            brand IN ({{brand}})
```

### % by Converted Product Group `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT 
        'ALL'::VARCHAR AS p_whse,
        'ALL'::VARCHAR AS p_cargo,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_storer,
        'CSE'::VARCHAR AS p_measure --cse, pallet, cbm, ton
)
SELECT
    group_name AS group_of_cargo,
    measure_value,
    -- Tính % tỷ trọng: Nhân với 100.0 để đảm bảo kết quả là số thập phân
    measure_value * 100.0 / NULLIF(SUM(measure_value) OVER (), 0) AS pct_of_total
FROM
(
    SELECT
        COALESCE(group_of_cargo, 'Unclassified') AS group_name,
        -- Thay thế logic if() động bằng CASE WHEN
        SUM(
            CASE 
                WHEN p_measure = 'CSE' THEN qty_cse
                WHEN p_measure = 'PALLET' THEN qty_pl
                WHEN p_measure = 'TON' THEN qty_ton
                WHEN p_measure = 'CBM' THEN qty_cbm
                ELSE qty_cse 
            END
        ) AS measure_value
    FROM analytics_workspace.reporting_schema.mv_test_stocktype
    CROSS JOIN constants
    WHERE
        (p_whse = 'ALL' OR whseid = p_whse)
        AND (p_cargo = 'ALL' OR COALESCE(group_of_cargo, 'Unclassified') = p_cargo)
        AND (p_brand = 'ALL' OR brand = p_brand)
        AND (p_storer = 'ALL' OR storer_key = p_storer)
    GROUP BY 1 -- Group by group_name
) x
ORDER BY measure_value DESC
```

**ClickHouse SQL:**

```sql
SELECT
    group_name AS group_of_cargo,
    measure_value,
    -- Tính % tỷ trọng
    measure_value * 100.0 / nullIf(SUM(measure_value) OVER (), 0) AS pct_of_total
FROM
(
    SELECT
        coalesce(group_of_cargo, 'Unclassified') AS group_name,
        SUM(
            CASE 
                WHEN {{uom}} = 'CSE'    THEN qty_cse
                WHEN {{uom}} = 'PALLET' THEN qty_pl
                WHEN {{uom}} = 'TON'    THEN qty_ton
                WHEN {{uom}} = 'CBM'    THEN qty_cbm
                ELSE qty_cse 
            END
        ) AS measure_value
    FROM analytics_workspace.mv_stocktype
    WHERE 
    1 =1 
    -- Warehouse
        AND if(
            arraySort([{{whseid}}]) = (
                SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
            ),
            1 = 1,
            whseid IN ({{whseid}})
        )
    
    -- Filter Cargo Group
    AND if(
            arraySort([{{cargo}}]) = (
                SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            group_of_cargo IN ({{cargo}})
    
    -- Filter Brand
    AND if(
            arraySort([{{brand}}]) = (
                SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            brand IN ({{brand}})
    GROUP BY group_name
) x

ORDER BY measure_value DESC
```

### % by warehouse · stacked `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT 
        'ALL'::VARCHAR AS p_whse,
        'ALL'::VARCHAR AS p_cargo,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_storer,
        'CSE'::VARCHAR AS p_measure
)
SELECT
    whseid,
    group_name AS group_of_cargo,
    measure_value,
    -- Tính % tỷ trọng theo từng kho (Partition by WHSEID)
    -- Nhân với 100.0 để tránh lỗi chia số nguyên (Integer Division)
    measure_value * 100.0 / NULLIF(SUM(measure_value) OVER (PARTITION BY whseid), 0) AS pct_of_warehouse
FROM
(
    SELECT
        whseid,
        COALESCE(group_of_cargo, 'Unclassified') AS group_name,
        -- Logic chọn cột động theo p_measure
        SUM(
            CASE 
                WHEN p_measure = 'CSE' THEN qty_cse
                WHEN p_measure = 'PALLET' THEN qty_pl
                WHEN p_measure = 'TON' THEN qty_ton
                WHEN p_measure = 'CBM' THEN qty_cbm
                ELSE qty_cse 
            END
        ) AS measure_value
    FROM analytics_workspace.reporting_schema.mv_test_stocktype
    CROSS JOIN constants
    WHERE
        (p_whse = 'ALL' OR whseid = p_whse)
        AND (p_cargo = 'ALL' OR COALESCE(group_of_cargo, 'Unclassified') = p_cargo)
        AND (p_brand = 'ALL' OR brand = p_brand)
        AND (p_storer = 'ALL' OR storer_key = p_storer)
    GROUP BY 
        whseid, 
        group_name
) x
ORDER BY 
    whseid, 
    measure_value DESC
```

**ClickHouse SQL:**

```sql
SELECT
    whseid,
    group_name AS group_of_cargo,
    measure_value,
    -- Tính % tỷ trọng theo từng kho
    measure_value * 100.0 / nullIf(SUM(measure_value) OVER (PARTITION BY whseid), 0) AS pct_of_warehouse
FROM
(
    SELECT
        whseid,
        coalesce(group_of_cargo, 'Unclassified') AS group_name,
        SUM(
            CASE 
                WHEN {{uom}} = 'CSE'    THEN qty_cse
                WHEN {{uom}} = 'PALLET' THEN qty_pl
                WHEN {{uom}} = 'TON'    THEN qty_ton
                WHEN {{uom}} = 'CBM'    THEN qty_cbm
                ELSE qty_cse 
            END
        ) AS measure_value
    FROM analytics_workspace.mv_stocktype
    WHERE
    1 =1 
    -- Warehouse
        AND if(
            arraySort([{{whseid}}]) = (
                SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
            ),
            1 = 1,
            whseid IN ({{whseid}})
        )
    
    -- Filter Cargo Group
    AND if(
            arraySort([{{cargo}}]) = (
                SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            group_of_cargo IN ({{cargo}})
    
    -- Filter Brand
    AND if(
            arraySort([{{brand}}]) = (
                SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            brand IN ({{brand}})
    GROUP BY 
        whseid, 
        group_name
) x
ORDER BY 
    whseid, 
    measure_value DESC
```

### Top product groups `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT 
        'ALL'::VARCHAR AS p_whse,
        'ALL'::VARCHAR AS p_cargo,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_storer,
        'CSE'::VARCHAR AS p_measure
)
SELECT
    group_name AS group_of_cargo,
    measure_value
FROM
(
    SELECT
        COALESCE(group_of_cargo, 'Unclassified') AS group_name,
        -- Chuyển hàm if() của ClickHouse sang CASE WHEN chuẩn SQL
        SUM(
            CASE 
                WHEN p_measure = 'CSE' THEN qty_cse
                WHEN p_measure = 'PALLET' THEN qty_pl
                WHEN p_measure = 'TON' THEN qty_ton
                WHEN p_measure = 'CBM' THEN qty_cbm
                ELSE qty_cse 
            END
        ) AS measure_value
    FROM analytics_workspace.reporting_schema.mv_test_stocktype
    CROSS JOIN constants
    WHERE
        (p_whse = 'ALL' OR whseid = p_whse)
        AND (p_cargo = 'ALL' OR COALESCE(group_of_cargo, 'Unclassified') = p_cargo)
        AND (p_brand = 'ALL' OR brand = p_brand)
        AND (p_storer = 'ALL' OR storer_key = p_storer)
    GROUP BY 1
) x
ORDER BY measure_value DESC
LIMIT 10
```

**ClickHouse SQL:**

```sql
SELECT
    whseid,
    group_name AS group_of_cargo,
    measure_value,
    -- Tính % tỷ trọng theo từng kho
    measure_value * 100.0 / nullIf(SUM(measure_value) OVER (PARTITION BY whseid), 0) AS pct_of_warehouse
FROM
(
    SELECT
        whseid,
        coalesce(group_of_cargo, 'Unclassified') AS group_name,
        SUM(
            CASE 
                WHEN {{uom}} = 'CSE'    THEN qty_cse
                WHEN {{uom}} = 'PALLET' THEN qty_pl
                WHEN {{uom}} = 'TON'    THEN qty_ton
                WHEN {{uom}} = 'CBM'    THEN qty_cbm
                ELSE qty_cse 
            END
        ) AS measure_value
    FROM analytics_workspace.mv_stocktype
    WHERE 
    1 =1 
    -- Warehouse
        AND if(
            arraySort([{{whseid}}]) = (
                SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
            ),
            1 = 1,
            whseid IN ({{whseid}})
        )
    
    -- Filter Cargo Group
    AND if(
            arraySort([{{cargo}}]) = (
                SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            group_of_cargo IN ({{cargo}})
    
    -- Filter Brand
    AND if(
            arraySort([{{brand}}]) = (
                SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            brand IN ({{brand}})
    GROUP BY 
        whseid, 
        group_name
) x
ORDER BY 
    whseid, 
    measure_value DESC
```

### Detail data `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT 
        'ALL'::VARCHAR AS p_whse,
        'ALL'::VARCHAR AS p_cargo,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_storer
)
SELECT
    COALESCE(group_of_cargo, 'Unclassified') AS group_of_cargo,
    brand,
    storer_key,
    whseid,
    -- Nhóm chỉ số tồn kho thực tế (Stock)
    SUM(qty) AS qty,
    SUM(qty_cbm) AS qty_cbm,
    SUM(qty_ton) AS qty_ton,
    SUM(qty_cse) AS qty_cse,
    SUM(qty_pl) AS qty_pl,
    
    -- Nhóm chỉ số đã giữ hàng (Allocated)
    SUM(qty_allocated) AS qty_allocated,
    SUM(qty_allocated_cbm) AS qty_allocated_cbm,
    SUM(qty_allocated_ton) AS qty_allocated_ton,
    SUM(qty_allocated_cse) AS qty_allocated_cse,
    SUM(qty_allocated_pl) AS qty_allocated_pl,
    
    -- Nhóm chỉ số đã nhặt hàng (Picked)
    SUM(qty_picked) AS qty_picked,
    SUM(qty_picked_cbm) AS qty_picked_cbm,
    SUM(qty_picked_ton) AS qty_picked_ton,
    SUM(qty_picked_cse) AS qty_picked_cse,
    SUM(qty_picked_pl) AS qty_picked_pl
FROM analytics_workspace.reporting_schema.mv_test_stocktype
CROSS JOIN constants
WHERE
    (p_whse = 'ALL' OR whseid = p_whse)
    AND (p_cargo = 'ALL' OR COALESCE(group_of_cargo, 'Unclassified') = p_cargo)
    AND (p_brand = 'ALL' OR brand = p_brand)
    AND (p_storer = 'ALL' OR storer_key = p_storer)
GROUP BY
    1, -- Tương ứng group_of_cargo (đã xử lý COALESCE)
    2,3,4
ORDER BY
    1,
    2,3,4
```

**ClickHouse SQL:**

```sql
SELECT
    coalesce(group_of_cargo, 'Unclassified') AS group_of_cargo,
    brand,
    storer_key,
    whseid,
    -- Nhóm chỉ số tồn kho thực tế (Stock)
    SUM(qty)     AS qty,
    SUM(qty_cbm) AS qty_cbm,
    SUM(qty_ton) AS qty_ton,
    SUM(qty_cse) AS qty_cse,
    SUM(qty_pl)  AS qty_pl,
    
    -- Nhóm chỉ số đã giữ hàng (Allocated)
    SUM(qty_allocated)     AS qty_allocated,
    SUM(qty_allocated_cbm) AS qty_allocated_cbm,
    SUM(qty_allocated_ton) AS qty_allocated_ton,
    SUM(qty_allocated_cse) AS qty_allocated_cse,
    SUM(qty_allocated_pl)  AS qty_allocated_pl,
    
    -- Nhóm chỉ số đã nhặt hàng (Picked)
    SUM(qty_picked)     AS qty_picked,
    SUM(qty_picked_cbm) AS qty_picked_cbm,
    SUM(qty_picked_ton) AS qty_picked_ton,
    SUM(qty_picked_cse) AS qty_picked_cse,
    SUM(qty_picked_pl)  AS qty_picked_pl

FROM analytics_workspace.mv_stocktype
WHERE 
    1 =1 
    -- Warehouse
        AND if(
            arraySort([{{whseid}}]) = (
                SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
            ),
            1 = 1,
            whseid IN ({{whseid}})
        )
    
    -- Filter Cargo Group
    AND if(
            arraySort([{{cargo}}]) = (
                SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            group_of_cargo IN ({{cargo}})
    
    -- Filter Brand
    AND if(
            arraySort([{{brand}}]) = (
                SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
            ),
            1 = 1,
            brand IN ({{brand}})
GROUP BY
    group_of_cargo,
    brand,
    storer_key,
    whseid
ORDER BY
    group_of_cargo,
    brand,
    storer_key,
    whseid
```

---

## vfr tender

### Avg VFR (VFR by Tender Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT
    AVG("%VFR_theo_ID_chuyen_gui_thau(Max)") AS avg_vfr
FROM reporting_schema.mv_test_vfr_theo_loai_xe_gui_thau
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "ten_diem_nhan"  = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (p.p_vendor = 'ALL' OR "ten_ngan_nha_thau" = p.p_vendor)
    AND (p.p_tender_vehicle_type = 'ALL' OR "loai_xe_gui_thau" = p.p_tender_vehicle_type)
    AND (
        (p.p_date_type = 'tg_gt' AND "thoi_gian_gui_thau" >= p.p_from_date AND "thoi_gian_gui_thau" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND "ETA_chuyen_van_hanh" >= p.p_from_date AND "ETA_chuyen_van_hanh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ATA_chuyen_van_hanh" >= p.p_from_date AND "ATA_chuyen_van_hanh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
-- VFR KPI Summary
SELECT
    round(avg(vfr_max), 2)                          AS avg_vfr,
    countIf(vfr_max < 50)                           AS cnt_vfr_50,
    countIf(vfr_max >= 50 AND vfr_max < 70)         AS cnt_vfr_50_70,
    countIf(vfr_max >= 70 AND vfr_max < 95)         AS cnt_vfr_70_95,
    countIf(vfr_max >= 95)                          AS cnt_vfr_95
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

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Low <50% (VFR by Tender Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT 
    COUNT(*) AS cnt_vfr_50
FROM reporting_schema.mv_test_vfr_theo_loai_xe_gui_thau
CROSS JOIN params p
WHERE 1 = 1
    AND "%VFR_theo_ID_chuyen_gui_thau(Max)" < 50
    AND (p.p_locationfrom = 'ALL' OR "ten_diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (p.p_vendor = 'ALL' OR "ten_ngan_nha_thau" = p.p_vendor)
    AND (p.p_tender_vehicle_type = 'ALL' OR "loai_xe_gui_thau" = p.p_tender_vehicle_type)
    AND (
        (p.p_date_type = 'tg_gt' AND "thoi_gian_gui_thau" >= p.p_from_date AND "thoi_gian_gui_thau" < p.p_to_date)
        OR        
        (p.p_date_type = 'eta_vh' AND "ETA_chuyen_van_hanh" >= p.p_from_date AND "ETA_chuyen_van_hanh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ATA_chuyen_van_hanh" >= p.p_from_date AND "ATA_chuyen_van_hanh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
-- VFR KPI Summary
SELECT
    round(avg(vfr_max), 2)                          AS avg_vfr,
    countIf(vfr_max < 50)                           AS cnt_vfr_50,
    countIf(vfr_max >= 50 AND vfr_max < 70)         AS cnt_vfr_50_70,
    countIf(vfr_max >= 70 AND vfr_max < 95)         AS cnt_vfr_70_95,
    countIf(vfr_max >= 95)                          AS cnt_vfr_95
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

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Medium 50-70% (VFR by Tender Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT 
    COUNT(*) AS cnt_vfr_50_70
FROM reporting_schema.mv_test_vfr_theo_loai_xe_gui_thau
CROSS JOIN params p
WHERE 1 = 1
    AND "%VFR_theo_ID_chuyen_gui_thau(Max)" >= 50
    AND "%VFR_theo_ID_chuyen_gui_thau(Max)" < 70
    AND (p.p_locationfrom = 'ALL' OR "ten_diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (p.p_vendor = 'ALL' OR "ten_ngan_nha_thau" = p.p_vendor)
    AND (p.p_tender_vehicle_type = 'ALL' OR "loai_xe_gui_thau" = p.p_tender_vehicle_type)
    AND (
        (p.p_date_type = 'tg_gt' AND "thoi_gian_gui_thau" >= p.p_from_date AND "thoi_gian_gui_thau" < p.p_to_date)
        OR        
        (p.p_date_type = 'eta_vh' AND "ETA_chuyen_van_hanh" >= p.p_from_date AND "ETA_chuyen_van_hanh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ATA_chuyen_van_hanh" >= p.p_from_date AND "ATA_chuyen_van_hanh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
-- VFR KPI Summary
SELECT
    round(avg(vfr_max), 2)                          AS avg_vfr,
    countIf(vfr_max < 50)                           AS cnt_vfr_50,
    countIf(vfr_max >= 50 AND vfr_max < 70)         AS cnt_vfr_50_70,
    countIf(vfr_max >= 70 AND vfr_max < 95)         AS cnt_vfr_70_95,
    countIf(vfr_max >= 95)                          AS cnt_vfr_95
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

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### High 70-95% (VFR by Tender Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT 
    COUNT(*) AS cnt_vfr_70_95
FROM reporting_schema.mv_test_vfr_theo_loai_xe_gui_thau
CROSS JOIN params p
WHERE 1 = 1
    AND "%VFR_theo_ID_chuyen_gui_thau(Max)" >= 70
    AND "%VFR_theo_ID_chuyen_gui_thau(Max)" < 95
    AND (p.p_locationfrom = 'ALL' OR "ten_diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (p.p_vendor = 'ALL' OR "ten_ngan_nha_thau" = p.p_vendor)
    AND (p.p_tender_vehicle_type = 'ALL' OR "loai_xe_gui_thau" = p.p_tender_vehicle_type)
    AND (
        (p.p_date_type = 'tg_gt' AND "thoi_gian_gui_thau" >= p.p_from_date AND "thoi_gian_gui_thau" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND "ETA_chuyen_van_hanh" >= p.p_from_date AND "ETA_chuyen_van_hanh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ATA_chuyen_van_hanh" >= p.p_from_date AND "ATA_chuyen_van_hanh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
-- VFR KPI Summary
SELECT
    round(avg(vfr_max), 2)                          AS avg_vfr,
    countIf(vfr_max < 50)                           AS cnt_vfr_50,
    countIf(vfr_max >= 50 AND vfr_max < 70)         AS cnt_vfr_50_70,
    countIf(vfr_max >= 70 AND vfr_max < 95)         AS cnt_vfr_70_95,
    countIf(vfr_max >= 95)                          AS cnt_vfr_95
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

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Excellent ≥95% (VFR by Tender Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT 
    COUNT(*) AS cnt_vfr_95
FROM reporting_schema.mv_test_vfr_theo_loai_xe_gui_thau
CROSS JOIN params p
WHERE 1 = 1
    AND "%VFR_theo_ID_chuyen_gui_thau(Max)" >= 95
    AND (p.p_locationfrom = 'ALL' OR "ten_diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (p.p_vendor = 'ALL' OR "ten_ngan_nha_thau" = p.p_vendor)
    AND (p.p_tender_vehicle_type = 'ALL' OR "loai_xe_gui_thau" = p.p_tender_vehicle_type)
    AND (
        (p.p_date_type = 'tg_gt' AND "thoi_gian_gui_thau" >= p.p_from_date AND "thoi_gian_gui_thau" < p.p_to_date)
        OR
        (p.p_date_type = 'tg_gt' AND "thoi_gian_gui_thau" >= p.p_from_date AND "thoi_gian_gui_thau" < p.p_to_date)
        OR        
        (p.p_date_type = 'eta_vh' AND "ETA_chuyen_van_hanh" >= p.p_from_date AND "ETA_chuyen_van_hanh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ATA_chuyen_van_hanh" >= p.p_from_date AND "ATA_chuyen_van_hanh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
-- VFR KPI Summary
SELECT
    round(avg(vfr_max), 2)                          AS avg_vfr,
    countIf(vfr_max < 50)                           AS cnt_vfr_50,
    countIf(vfr_max >= 50 AND vfr_max < 70)         AS cnt_vfr_50_70,
    countIf(vfr_max >= 70 AND vfr_max < 95)         AS cnt_vfr_70_95,
    countIf(vfr_max >= 95)                          AS cnt_vfr_95
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

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### VFR gửi thầu theo khu vực (VFR by Tender Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
),
base AS (
    SELECT
        t."khu_vuc_doi_xe" AS khu_vuc_doi_xe,
        SUM(CAST(t."so_khoi_ke_hoach" AS DOUBLE PRECISION)) AS total_cbm_ke_hoach,
        SUM(CAST(t."so_khoi_nhan" AS DOUBLE PRECISION))      AS total_cbm_nhan,
        /* Loose */
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_VFR" = 'Khối'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_khoi_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_VFR" = 'Khối'
                THEN CAST(t."CBM" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_khoi_cbm_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."tan_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_tan_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."trong_tai_tan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_tan_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_tan_cbm_nhan,
        /* Full Pallet */
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_VFR" = 'Khối'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_khoi_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_VFR" = 'Khối'
                THEN CAST(t."CBM" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_khoi_cbm_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."tan_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_tan_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."trong_tai_tan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_tan_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_tan_cbm_nhan
    FROM reporting_schema.mv_test_vfr_theo_loai_xe_gui_thau t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (p.p_locationfrom = 'ALL' OR "ten_diem_nhan" = p.p_locationfrom)
        AND (p.p_area = 'ALL' OR t."khu_vuc_doi_xe" = p.p_area)
        AND (p.p_vendor = 'ALL' OR t."ten_ngan_nha_thau" = p.p_vendor)
        AND (p.p_tender_vehicle_type = 'ALL' OR t."loai_xe_gui_thau" = p.p_tender_vehicle_type)
        AND (
        (p.p_date_type = 'tg_gt' AND "thoi_gian_gui_thau" >= p.p_from_date AND "thoi_gian_gui_thau" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND t."ETA_chuyen_van_hanh" >= p.p_from_date AND t."ETA_chuyen_van_hanh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND t."ATA_chuyen_van_hanh" >= p.p_from_date AND t."ATA_chuyen_van_hanh" < p.p_to_date)
        )
    GROUP BY t."khu_vuc_doi_xe"
),
calc AS (
    SELECT
        khu_vuc_doi_xe,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        COALESCE(loose_cbm_nhan / NULLIF(total_cbm_nhan, 0.0), 0.0) AS loose_weight,
        COALESCE(fp_cbm_nhan    / NULLIF(total_cbm_nhan, 0.0), 0.0) AS fp_weight,
        COALESCE(loose_khoi_cbm_nhan / NULLIF(loose_khoi_cbm_dk, 0.0), 0.0) AS loose_khoi_fill_rate,
        COALESCE(loose_khoi_cbm_nhan / NULLIF(loose_cbm_nhan, 0.0), 0.0)    AS loose_khoi_mix_rate,
        COALESCE(loose_tan_nhan      / NULLIF(loose_tan_dk, 0.0), 0.0)      AS loose_tan_fill_rate,
        COALESCE(loose_tan_cbm_nhan  / NULLIF(loose_cbm_nhan, 0.0), 0.0)    AS loose_tan_mix_rate,
        COALESCE(fp_khoi_cbm_nhan / NULLIF(fp_khoi_cbm_dk, 0.0), 0.0)       AS fp_khoi_fill_rate,
        COALESCE(fp_khoi_cbm_nhan / NULLIF(fp_cbm_nhan, 0.0), 0.0)          AS fp_khoi_mix_rate,
        COALESCE(fp_tan_nhan      / NULLIF(fp_tan_dk, 0.0), 0.0)            AS fp_tan_fill_rate,
        COALESCE(fp_tan_cbm_nhan  / NULLIF(fp_cbm_nhan, 0.0), 0.0)          AS fp_tan_mix_rate
    FROM base
)
SELECT
    khu_vuc_doi_xe,
    total_cbm_ke_hoach,
    ROUND(
        LEAST(
            1.0,
            (
                (
                    loose_khoi_fill_rate * loose_khoi_mix_rate
                    + loose_tan_fill_rate * loose_tan_mix_rate
                ) * loose_weight
                +
                (
                    fp_khoi_fill_rate * fp_khoi_mix_rate
                    + fp_tan_fill_rate * fp_tan_mix_rate
                ) * fp_weight
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY khu_vuc_doi_xe;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.khu_vuc_doi_xe AS khu_vuc_doi_xe,
        SUM(t.cbm_ke_hoach) AS total_cbm_ke_hoach, -- Cột này là Float64 sẵn, ko cần cast
        SUM(t.cbm_nhan)      AS total_cbm_nhan,   -- Cột này là Float64 sẵn
        
        /* Loose - Lưu ý sửa 'Losse' thành 'Loose' nếu DB viết đúng */
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse'), t.cbm_nhan, 0)) AS loose_cbm_nhan,
        
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Khối', t.cbm_nhan, 0)) AS loose_khoi_cbm_nhan,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Khối', toFloat64OrZero(t.cbm_dang_ky), 0)) AS loose_khoi_cbm_dk,
        
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn', t.tan_nhan, 0)) AS loose_tan_nhan,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn', toFloat64OrZero(t.tan_dang_ky), 0)) AS loose_tan_dk,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn', t.cbm_nhan, 0)) AS loose_tan_cbm_nhan,
        
        /* Full Pallet */
        SUM(IF(t.loai_boc_xep = 'Full Pallet', t.cbm_nhan, 0)) AS fp_cbm_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Khối', t.cbm_nhan, 0)) AS fp_khoi_cbm_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Khối', toFloat64OrZero(t.cbm_dang_ky), 0)) AS fp_khoi_cbm_dk,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn', t.tan_nhan, 0)) AS fp_tan_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn', toFloat64OrZero(t.tan_dang_ky), 0)) AS fp_tan_dk,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn', t.cbm_nhan, 0)) AS fp_tan_cbm_nhan
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

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

    GROUP BY t.khu_vuc_doi_xe
),
calc AS (
    SELECT
        khu_vuc_doi_xe,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        if(total_cbm_nhan = 0, 0, loose_cbm_nhan / total_cbm_nhan) AS loose_weight,
        if(total_cbm_nhan = 0, 0, fp_cbm_nhan / total_cbm_nhan)    AS fp_weight,
        if(loose_khoi_cbm_dk = 0, 0, loose_khoi_cbm_nhan / loose_khoi_cbm_dk) AS loose_khoi_fill_rate,
        if(loose_cbm_nhan = 0, 0, loose_khoi_cbm_nhan / loose_cbm_nhan)       AS loose_khoi_mix_rate,
        if(loose_tan_dk = 0, 0, loose_tan_nhan / loose_tan_dk)               AS loose_tan_fill_rate,
        if(loose_cbm_nhan = 0, 0, loose_tan_cbm_nhan / loose_cbm_nhan)       AS loose_tan_mix_rate,
        if(fp_khoi_cbm_dk = 0, 0, fp_khoi_cbm_nhan / fp_khoi_cbm_dk)         AS fp_khoi_fill_rate,
        if(fp_cbm_nhan = 0, 0, fp_khoi_cbm_nhan / fp_cbm_nhan)               AS fp_khoi_mix_rate,
        if(fp_tan_dk = 0, 0, fp_tan_nhan / fp_tan_dk)                       AS fp_tan_fill_rate,
        if(fp_cbm_nhan = 0, 0, fp_tan_cbm_nhan / fp_cbm_nhan)               AS fp_tan_mix_rate
    FROM base
)
SELECT
    khu_vuc_doi_xe,
    total_cbm_ke_hoach,
    round(
        least(
            1.0,
            (
                (
                    loose_khoi_fill_rate * loose_khoi_mix_rate
                    + loose_tan_fill_rate * loose_tan_mix_rate
                ) * loose_weight
                +
                (
                    fp_khoi_fill_rate * fp_khoi_mix_rate
                    + fp_tan_fill_rate * fp_tan_mix_rate
                ) * fp_weight
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY khu_vuc_doi_xe;
```

### VFR gửi thầu theo loại xe (VFR by Tender Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
),
base AS (
    SELECT
        t."loai_xe_gui_thau" AS loai_xe_gui_thau,
        SUM(CAST(t."so_khoi_ke_hoach" AS DOUBLE PRECISION)) AS total_cbm_ke_hoach,
        SUM(CAST(t."so_khoi_nhan" AS DOUBLE PRECISION))      AS total_cbm_nhan,
        /* Loose */
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_VFR" = 'Khối'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_khoi_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_VFR" = 'Khối'
                THEN CAST(t."CBM" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_khoi_cbm_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."tan_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_tan_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."trong_tai_tan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_tan_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_tan_cbm_nhan,
        /* Full Pallet */
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_VFR" = 'Khối'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_khoi_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_VFR" = 'Khối'
                THEN CAST(t."CBM" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_khoi_cbm_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."tan_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_tan_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."trong_tai_tan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_tan_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_tan_cbm_nhan
    FROM reporting_schema.mv_test_vfr_theo_loai_xe_gui_thau t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (p.p_locationfrom = 'ALL' OR "ten_diem_nhan" = p.p_locationfrom)
        AND (p.p_area = 'ALL' OR t."khu_vuc_doi_xe" = p.p_area)
        AND (p.p_vendor = 'ALL' OR t."ten_ngan_nha_thau" = p.p_vendor)
        AND (p.p_tender_vehicle_type = 'ALL' OR t."loai_xe_gui_thau" = p.p_tender_vehicle_type)
        AND (
        (p.p_date_type = 'tg_gt' AND "thoi_gian_gui_thau" >= p.p_from_date AND "thoi_gian_gui_thau" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND t."ETA_chuyen_van_hanh" >= p.p_from_date AND t."ETA_chuyen_van_hanh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND t."ATA_chuyen_van_hanh" >= p.p_from_date AND t."ATA_chuyen_van_hanh" < p.p_to_date)
        )
    GROUP BY t."loai_xe_gui_thau"
),
calc AS (
    SELECT
        loai_xe_gui_thau,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        COALESCE(loose_cbm_nhan / NULLIF(total_cbm_nhan, 0.0), 0.0) AS loose_weight,
        COALESCE(fp_cbm_nhan    / NULLIF(total_cbm_nhan, 0.0), 0.0) AS fp_weight,
        COALESCE(loose_khoi_cbm_nhan / NULLIF(loose_khoi_cbm_dk, 0.0), 0.0) AS loose_khoi_fill_rate,
        COALESCE(loose_khoi_cbm_nhan / NULLIF(loose_cbm_nhan, 0.0), 0.0)    AS loose_khoi_mix_rate,
        COALESCE(loose_tan_nhan      / NULLIF(loose_tan_dk, 0.0), 0.0)      AS loose_tan_fill_rate,
        COALESCE(loose_tan_cbm_nhan  / NULLIF(loose_cbm_nhan, 0.0), 0.0)    AS loose_tan_mix_rate,
        COALESCE(fp_khoi_cbm_nhan / NULLIF(fp_khoi_cbm_dk, 0.0), 0.0)       AS fp_khoi_fill_rate,
        COALESCE(fp_khoi_cbm_nhan / NULLIF(fp_cbm_nhan, 0.0), 0.0)          AS fp_khoi_mix_rate,
        COALESCE(fp_tan_nhan      / NULLIF(fp_tan_dk, 0.0), 0.0)            AS fp_tan_fill_rate,
        COALESCE(fp_tan_cbm_nhan  / NULLIF(fp_cbm_nhan, 0.0), 0.0)          AS fp_tan_mix_rate
    FROM base
)
SELECT
    loai_xe_gui_thau,
    total_cbm_ke_hoach,
    ROUND(
        LEAST(
            1.0,
            (
                (
                    loose_khoi_fill_rate * loose_khoi_mix_rate
                    + loose_tan_fill_rate * loose_tan_mix_rate
                ) * loose_weight
                +
                (
                    fp_khoi_fill_rate * fp_khoi_mix_rate
                    + fp_tan_fill_rate * fp_tan_mix_rate
                ) * fp_weight
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY loai_xe_gui_thau;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.loai_xe_gui_thau AS loai_xe_gui_thau,
        SUM(t.cbm_ke_hoach) AS total_cbm_ke_hoach, -- Cột này là Float64 sẵn, ko cần cast
        SUM(t.cbm_nhan)      AS total_cbm_nhan,   -- Cột này là Float64 sẵn
        
        /* Loose - Lưu ý sửa 'Losse' thành 'Loose' nếu DB viết đúng */
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse'), t.cbm_nhan, 0)) AS loose_cbm_nhan,
        
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Khối', t.cbm_nhan, 0)) AS loose_khoi_cbm_nhan,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Khối', toFloat64OrZero(t.cbm_dang_ky), 0)) AS loose_khoi_cbm_dk,
        
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn', t.tan_nhan, 0)) AS loose_tan_nhan,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn', toFloat64OrZero(t.tan_dang_ky), 0)) AS loose_tan_dk,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn', t.cbm_nhan, 0)) AS loose_tan_cbm_nhan,
        
        /* Full Pallet */
        SUM(IF(t.loai_boc_xep = 'Full Pallet', t.cbm_nhan, 0)) AS fp_cbm_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Khối', t.cbm_nhan, 0)) AS fp_khoi_cbm_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Khối', toFloat64OrZero(t.cbm_dang_ky), 0)) AS fp_khoi_cbm_dk,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn', t.tan_nhan, 0)) AS fp_tan_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn', toFloat64OrZero(t.tan_dang_ky), 0)) AS fp_tan_dk,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn', t.cbm_nhan, 0)) AS fp_tan_cbm_nhan
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

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

    GROUP BY t.loai_xe_gui_thau
),
calc AS (
    SELECT
        loai_xe_gui_thau,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        if(total_cbm_nhan = 0, 0, loose_cbm_nhan / total_cbm_nhan) AS loose_weight,
        if(total_cbm_nhan = 0, 0, fp_cbm_nhan / total_cbm_nhan)    AS fp_weight,
        if(loose_khoi_cbm_dk = 0, 0, loose_khoi_cbm_nhan / loose_khoi_cbm_dk) AS loose_khoi_fill_rate,
        if(loose_cbm_nhan = 0, 0, loose_khoi_cbm_nhan / loose_cbm_nhan)       AS loose_khoi_mix_rate,
        if(loose_tan_dk = 0, 0, loose_tan_nhan / loose_tan_dk)               AS loose_tan_fill_rate,
        if(loose_cbm_nhan = 0, 0, loose_tan_cbm_nhan / loose_cbm_nhan)       AS loose_tan_mix_rate,
        if(fp_khoi_cbm_dk = 0, 0, fp_khoi_cbm_nhan / fp_khoi_cbm_dk)         AS fp_khoi_fill_rate,
        if(fp_cbm_nhan = 0, 0, fp_khoi_cbm_nhan / fp_cbm_nhan)               AS fp_khoi_mix_rate,
        if(fp_tan_dk = 0, 0, fp_tan_nhan / fp_tan_dk)                       AS fp_tan_fill_rate,
        if(fp_cbm_nhan = 0, 0, fp_tan_cbm_nhan / fp_cbm_nhan)               AS fp_tan_mix_rate
    FROM base
)
SELECT
    loai_xe_gui_thau,
    total_cbm_ke_hoach,
    round(
        least(
            1.0,
            (
                (
                    loose_khoi_fill_rate * loose_khoi_mix_rate
                    + loose_tan_fill_rate * loose_tan_mix_rate
                ) * loose_weight
                +
                (
                    fp_khoi_fill_rate * fp_khoi_mix_rate
                    + fp_tan_fill_rate * fp_tan_mix_rate
                ) * fp_weight
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY loai_xe_gui_thau;
```

### VFR gửi thầu theo loại bốc xếp (sẽ có 2 kiểu group: Group theo tháng - SQL cột E, Group theo tuần - SQL cột F)
(VFR by Tender Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-03-01 00:00:00' AS TIMESTAMP) AS p_to_date
),
base AS (
    SELECT
        DATE_TRUNC(
            'month',
            CASE
                WHEN p.p_date_type = 'eta_vh' THEN t."ETA_chuyen_van_hanh"
                WHEN p.p_date_type = 'ata_vh' THEN t."ATA_chuyen_van_hanh"
            END
        ) AS thang,
        t."loai_boc_xep" AS loai_boc_xep,
        SUM(CAST(t."so_khoi_ke_hoach" AS DOUBLE PRECISION)) AS total_cbm_ke_hoach,
        SUM(CAST(t."so_khoi_nhan" AS DOUBLE PRECISION))      AS total_cbm_nhan,
        SUM(
            CASE
                WHEN t."phan_loai_VFR" = 'Khối'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS khoi_cbm_nhan,
        SUM(
            CASE
                WHEN t."phan_loai_VFR" = 'Khối'
                THEN CAST(t."CBM" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS khoi_cbm_dk,
        SUM(
            CASE
                WHEN t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."tan_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS tan_nhan,
        SUM(
            CASE
                WHEN t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."trong_tai_tan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS tan_dk,
        SUM(
            CASE
                WHEN t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS tan_cbm_nhan
    FROM reporting_schema.mv_test_vfr_theo_loai_xe_gui_thau t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (p.p_locationfrom = 'ALL' OR "ten_diem_nhan" = p.p_locationfrom)
        AND (p.p_area = 'ALL' OR t."khu_vuc_doi_xe" = p.p_area)
        AND (p.p_vendor = 'ALL' OR t."ten_ngan_nha_thau" = p.p_vendor)
        AND (p.p_tender_vehicle_type = 'ALL' OR t."loai_xe_gui_thau" = p.p_tender_vehicle_type)
        AND (
        (p.p_date_type = 'tg_gt' AND "thoi_gian_gui_thau" >= p.p_from_date AND "thoi_gian_gui_thau" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND t."ETA_chuyen_van_hanh" >= p.p_from_date AND t."ETA_chuyen_van_hanh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND t."ATA_chuyen_van_hanh" >= p.p_from_date AND t."ATA_chuyen_van_hanh" < p.p_to_date)
        )
    GROUP BY
        DATE_TRUNC(
            'month',
            CASE
                WHEN p.p_date_type = 'eta_vh' THEN t."ETA_chuyen_van_hanh"
                WHEN p.p_date_type = 'ata_vh' THEN t."ATA_chuyen_van_hanh"
            END
        ),
        t."loai_boc_xep"
),
calc AS (
    SELECT
        thang,
        loai_boc_xep,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        COALESCE(khoi_cbm_nhan / NULLIF(khoi_cbm_dk, 0.0), 0.0)    AS khoi_fill_rate,
        COALESCE(khoi_cbm_nhan / NULLIF(total_cbm_nhan, 0.0), 0.0) AS khoi_mix_rate,
        COALESCE(tan_nhan / NULLIF(tan_dk, 0.0), 0.0)              AS tan_fill_rate,
        COALESCE(tan_cbm_nhan / NULLIF(total_cbm_nhan, 0.0), 0.0)  AS tan_mix_rate
    FROM base
)
SELECT
    TO_CHAR(thang, 'MM-YYYY') AS thang,
    loai_boc_xep,
    total_cbm_ke_hoach,
    ROUND(
        LEAST(
            1.0,
            (
                khoi_fill_rate * khoi_mix_rate
                + tan_fill_rate * tan_mix_rate
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY
    calc.thang,
    loai_boc_xep;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
          toDate(CASE
                WHEN {{date_type}} = 'ETA'                                 THEN t.eta_vh
                WHEN {{date_type}} = 'ATA'                                 THEN t.ata_vh
                WHEN {{date_type}} = 'Ngày gửi thầu'         THEN t.tender_date
            END) AS thoi_gian,
        t.loai_boc_xep,
        SUM(toFloat64(t.cbm_ke_hoach)) AS total_cbm_ke_hoach,
        SUM(toFloat64(t.cbm_nhan))     AS total_cbm_nhan,
        SUM(if(t.phan_loai_vfr = 'Khối',
               toFloat64(t.cbm_nhan), 0))    AS khoi_cbm_nhan,
        SUM(if(t.phan_loai_vfr = 'Khối',
               toFloat64(t.cbm_dang_ky), 0)) AS khoi_cbm_dk,
        SUM(if(t.phan_loai_vfr = 'Tấn',
               toFloat64(t.tan_nhan), 0))    AS tan_nhan,
        SUM(if(t.phan_loai_vfr = 'Tấn',
               toFloat64(t.tan_dang_ky), 0)) AS tan_dk,
        SUM(if(t.phan_loai_vfr = 'Tấn',
               toFloat64(t.cbm_nhan), 0))    AS tan_cbm_nhan
    FROM analytics_workspace.mv_vfr_gui_thau AS t
    WHERE 1 = 1
    
-- Warehouse
AND (coalesce({{whseid}}, 'ALL') = 'ALL' OR t.ma_diem_nhan IN ({{whseid}}))

-- Area
AND (coalesce({{area}}, 'ALL') = 'ALL' OR t.khu_vuc_doi_xe IN ({{area}}))

-- Transporter
AND (coalesce({{transporter}}, 'ALL') = 'ALL' OR t.nha_van_tai IN ({{transporter}}))

-- Vehicle_type_tender
AND (coalesce({{vehicle_type_tender}}, 'ALL') = 'ALL' OR t.ma_loai_xe_gui_thau IN ({{vehicle_type_tender}}))

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

    GROUP BY
                toDate(CASE
                WHEN {{date_type}} = 'ETA'                                 THEN t.eta_vh
                WHEN {{date_type}} = 'ATA'                                 THEN t.ata_vh
                WHEN {{date_type}} = 'Ngày gửi thầu'         THEN t.tender_date
            END)
        ,
        t.loai_boc_xep
),
calc AS (
    SELECT
        thoi_gian,
        loai_boc_xep,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        coalesce(khoi_cbm_nhan / nullIf(khoi_cbm_dk, 0.0),    0.0) AS khoi_fill_rate,
        coalesce(khoi_cbm_nhan / nullIf(total_cbm_nhan, 0.0), 0.0) AS khoi_mix_rate,
        coalesce(tan_nhan      / nullIf(tan_dk, 0.0),         0.0) AS tan_fill_rate,
        coalesce(tan_cbm_nhan  / nullIf(total_cbm_nhan, 0.0), 0.0) AS tan_mix_rate
    FROM base
)
SELECT
    thoi_gian,
    loai_boc_xep,
    total_cbm_ke_hoach,
    round(
        least(
            1.0,
            (
                khoi_fill_rate * khoi_mix_rate
                + tan_fill_rate * tan_mix_rate
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY
    thoi_gian,
    loai_boc_xep;
```

### VFR gửi thầu theo thời gian và khu vực
(VFR by Tender Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-03-01 00:00:00' AS TIMESTAMP) AS p_to_date
),
base AS (
    SELECT
        DATE_TRUNC(
            'month',
            CASE
                WHEN p.p_date_type = 'eta_vh' THEN t."ETA_chuyen_van_hanh"
                WHEN p.p_date_type = 'ata_vh' THEN t."ATA_chuyen_van_hanh"
            END
        ) AS thang,
        t."khu_vuc_doi_xe" AS khu_vuc_doi_xe,
        SUM(CAST(t."so_khoi_ke_hoach" AS DOUBLE PRECISION)) AS total_cbm_ke_hoach,
        SUM(CAST(t."so_khoi_nhan" AS DOUBLE PRECISION))      AS total_cbm_nhan,
        SUM(
            CASE
                WHEN t."phan_loai_VFR" = 'Khối'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS khoi_cbm_nhan,
        SUM(
            CASE
                WHEN t."phan_loai_VFR" = 'Khối'
                THEN CAST(t."CBM" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS khoi_cbm_dk,
        SUM(
            CASE
                WHEN t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."tan_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS tan_nhan,
        SUM(
            CASE
                WHEN t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."trong_tai_tan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS tan_dk,
        SUM(
            CASE
                WHEN t."phan_loai_VFR" = 'Tấn'
                THEN CAST(t."so_khoi_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS tan_cbm_nhan
    FROM reporting_schema.mv_test_vfr_theo_loai_xe_gui_thau t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (p.p_locationfrom = 'ALL' OR "ten_diem_nhan" = p.p_locationfrom)
        AND (p.p_area = 'ALL' OR t."khu_vuc_doi_xe" = p.p_area)
        AND (p.p_vendor = 'ALL' OR t."ten_ngan_nha_thau" = p.p_vendor)
        AND (p.p_tender_vehicle_type = 'ALL' OR t."loai_xe_gui_thau" = p.p_tender_vehicle_type)
        AND (
        (p.p_date_type = 'tg_gt' AND "thoi_gian_gui_thau" >= p.p_from_date AND "thoi_gian_gui_thau" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND t."ETA_chuyen_van_hanh" >= p.p_from_date AND t."ETA_chuyen_van_hanh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND t."ATA_chuyen_van_hanh" >= p.p_from_date AND t."ATA_chuyen_van_hanh" < p.p_to_date)
        )
    GROUP BY
        DATE_TRUNC(
            'month',
            CASE
                WHEN p.p_date_type = 'eta_vh' THEN t."ETA_chuyen_van_hanh"
                WHEN p.p_date_type = 'ata_vh' THEN t."ATA_chuyen_van_hanh"
            END
        ),
        t."khu_vuc_doi_xe"
),
calc AS (
    SELECT
        thang,
        khu_vuc_doi_xe,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        COALESCE(khoi_cbm_nhan / NULLIF(khoi_cbm_dk, 0.0), 0.0)    AS khoi_fill_rate,
        COALESCE(khoi_cbm_nhan / NULLIF(total_cbm_nhan, 0.0), 0.0) AS khoi_mix_rate,
        COALESCE(tan_nhan / NULLIF(tan_dk, 0.0), 0.0)              AS tan_fill_rate,
        COALESCE(tan_cbm_nhan / NULLIF(total_cbm_nhan, 0.0), 0.0)  AS tan_mix_rate
    FROM base
)
SELECT
    TO_CHAR(thang, 'MM-YYYY') AS thang,
    khu_vuc_doi_xe,
    total_cbm_ke_hoach,
    ROUND(
        LEAST(
            1.0,
            (
                khoi_fill_rate * khoi_mix_rate
                + tan_fill_rate * tan_mix_rate
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY
    calc.thang,
    khu_vuc_doi_xe;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        toStartOfMonth(
            CASE
                WHEN {{date_type}} = 'ETA'                                 THEN t.eta_vh
                WHEN {{date_type}} = 'ATA'                                 THEN t.ata_vh
                WHEN {{date_type}} = 'Ngày gửi thầu'         THEN t.tender_date
            END
        ) AS thang,
        t.khu_vuc_doi_xe,
        SUM(toFloat64(t.cbm_ke_hoach)) AS total_cbm_ke_hoach,
        SUM(toFloat64(t.cbm_nhan))     AS total_cbm_nhan,
        SUM(if(t.phan_loai_vfr = 'Khối',
               toFloat64(t.cbm_nhan), 0))    AS khoi_cbm_nhan,
        SUM(if(t.phan_loai_vfr = 'Khối',
               toFloat64(t.cbm_dang_ky), 0)) AS khoi_cbm_dk,
        SUM(if(t.phan_loai_vfr = 'Tấn',
               toFloat64(t.tan_nhan), 0))    AS tan_nhan,
        SUM(if(t.phan_loai_vfr = 'Tấn',
               toFloat64(t.tan_dang_ky), 0)) AS tan_dk,
        SUM(if(t.phan_loai_vfr = 'Tấn',
               toFloat64(t.cbm_nhan), 0))    AS tan_cbm_nhan
    FROM analytics_workspace.mv_vfr_gui_thau AS t
    WHERE 1 = 1
   
   -- Warehouse
AND (coalesce({{whseid}}, 'ALL') = 'ALL' OR t.ma_diem_nhan IN ({{whseid}}))

-- Area
AND (coalesce({{area}}, 'ALL') = 'ALL' OR t.khu_vuc_doi_xe IN ({{area}}))

-- Transporter
AND (coalesce({{transporter}}, 'ALL') = 'ALL' OR t.nha_van_tai IN ({{transporter}}))

-- Vehicle_type_tender
AND (coalesce({{vehicle_type_tender}}, 'ALL') = 'ALL' OR t.ma_loai_xe_gui_thau IN ({{vehicle_type_tender}}))

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA' THEN t.eta_vh
        WHEN {{date_type}} = 'ATA' THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu' THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
    
    GROUP BY
        toStartOfMonth(
            CASE
                WHEN {{date_type}} = 'ETA' THEN t.eta_vh
                WHEN {{date_type}} = 'ATA' THEN t.ata_vh
                WHEN {{date_type}} = 'Ngày gửi thầu' THEN t.tender_date
            END
        ),
        t.khu_vuc_doi_xe
),
calc AS (
    SELECT
        thang,
        khu_vuc_doi_xe,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        coalesce(khoi_cbm_nhan / nullIf(khoi_cbm_dk, 0.0),    0.0) AS khoi_fill_rate,
        coalesce(khoi_cbm_nhan / nullIf(total_cbm_nhan, 0.0), 0.0) AS khoi_mix_rate,
        coalesce(tan_nhan      / nullIf(tan_dk, 0.0),         0.0) AS tan_fill_rate,
        coalesce(tan_cbm_nhan  / nullIf(total_cbm_nhan, 0.0), 0.0) AS tan_mix_rate
    FROM base
)
SELECT
    formatDateTime(thang, '%m-%Y') AS thang,
    khu_vuc_doi_xe,
    total_cbm_ke_hoach,
    round(
        least(
            1.0,
            (
                khoi_fill_rate * khoi_mix_rate
                + tan_fill_rate * tan_mix_rate
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY
    thang,
    khu_vuc_doi_xe;
```

### report gửi thầu
(VFR by Tender Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-04-16 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-04-16 23:59:59' AS TIMESTAMP) AS p_to_date
)
    select 
    t."ID_chuyen_gui_thau" as "ID chuyến gửi thầu",
    t.ma_chuyen_van_hanh as "Mã chuyến vận hành",
    t.ma_don_hang as "Mã đơn hàng",
    t.dich_vu_van_chuyen as "Dịch vụ vận chuyển",
    t.trang_thai_chuyen as "Trạng thái chuyến",
    t.thoi_gian_gui_thau as "Thời gian gửi thầu",
    t."ETA_chuyen_van_hanh" as "ETA chuyến vận hành",
    t."ATA_chuyen_van_hanh" as "ATA chuyến vận hành",
    t.so_xe as "Số xe",
    t.ten_tai_xe as "Tên tài xế",
    t.ten_ngan_nha_thau as "Tên ngắn nhà thầu",
    t.ten_nhom_hang as "Tên nhóm hàng",
    t.ma_diem_nhan as "Mã điểm nhận",
    t.ten_diem_nhan as "Tên điểm nhận",
    t.ma_diem_giao as "Mã điểm giao",
    t.ten_diem_giao as "Tên điểm giao",
    t.khu_vuc_doi_xe as "Khu vực đội xe",
    t.loai_boc_xep as "Loại bốc xếp",
    t.loai_xe_van_hanh as "Loại xe vận hành",
    t.loai_xe_gui_thau as "Loại xe gửi thầu",
    t.trong_tai_tan as "Tấn đăng ký",
    t."CBM" as "CBM đăng ký",
    t.tan_ke_hoach as "Tấn kế hoạch",
    t.tan_nhan as "Tấn nhận",
    t.tan_giao as "Tấn giao", 
    t.so_khoi_ke_hoach as "CBM kế hoạch",
    t.so_khoi_nhan as "CBM nhận",
    t.so_khoi_giao as "CBM giao",
    t."%VFR_theo_id_chuyen_gui_thau(tan)" as "VFR gửi thầu theo tấn",
    t."%VFR_theo_id_chuyen_gui_thau(khoi)" as "VFR gửi thầu theo CBM",
    t."%VFR_theo_ID_chuyen_gui_thau(Max)" as "VFR gửi thầu (max)"
    FROM reporting_schema.mv_test_vfr_theo_loai_xe_gui_thau t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (p.p_locationfrom = 'ALL' OR "ten_diem_nhan" = p.p_locationfrom)
        AND (p.p_area = 'ALL' OR t."khu_vuc_doi_xe" = p.p_area)
        AND (p.p_vendor = 'ALL' OR t."ten_ngan_nha_thau" = p.p_vendor)
        AND (p.p_tender_vehicle_type = 'ALL' OR t."loai_xe_gui_thau" = p.p_tender_vehicle_type)
        AND (
        (p.p_date_type = 'tg_gt' AND "thoi_gian_gui_thau" >= p.p_from_date AND "thoi_gian_gui_thau" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND t."ETA_chuyen_van_hanh" >= p.p_from_date AND t."ETA_chuyen_van_hanh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND t."ATA_chuyen_van_hanh" >= p.p_from_date AND t."ATA_chuyen_van_hanh" < p.p_to_date)
        )
```

**ClickHouse SQL:**

```sql
SELECT
    t.id_chuyen_gui_thau                    AS "ID chuyến gửi thầu",
    t.ma_chuyen_van_hanh                    AS "Mã chuyến vận hành",
    t.ma_don_hang                           AS "Mã đơn hàng",
    t.dich_vu_van_chuyen                    AS "Dịch vụ vận chuyển",
    t.trang_thai_chuyen                     AS "Trạng thái chuyến",
    t.tender_date                    AS "Thời gian gửi thầu",
    t.eta_vh                   AS "ETA chuyến vận hành",
    t.ata_vh                   AS "ATA chuyến vận hành",
    t.so_xe                                 AS "Số xe",
    t.tai_xe                            AS "Tên tài xế",
    t.nha_van_tai                     AS "Tên ngắn nhà thầu",
    t.nhom_hang_hoa                         AS "Tên nhóm hàng",
    t.ma_diem_nhan                          AS "Mã điểm nhận",
    t.diem_nhan                         AS "Tên điểm nhận",
    t.ma_diem_giao                          AS "Mã điểm giao",
    t.diem_giao                         AS "Tên điểm giao",
    t.khu_vuc_doi_xe                        AS "Khu vực đội xe",
    t.loai_boc_xep                          AS "Loại bốc xếp",
    t.loai_xe_van_hanh                      AS "Loại xe vận hành",
    t.loai_xe_gui_thau                      AS "Loại xe gửi thầu",
    t.tan_dang_ky                         AS "Tấn đăng ký",
    t.cbm_dang_ky                                   AS "CBM đăng ký",
    t.tan_ke_hoach                          AS "Tấn kế hoạch",
    t.tan_nhan                              AS "Tấn nhận",
    t.tan_giao                              AS "Tấn giao",
    t.cbm_ke_hoach                      AS "CBM kế hoạch",
    t.cbm_nhan                          AS "CBM nhận",
    t.cbm_giao                          AS "CBM giao",
    t.vfr_theo_tan   AS "VFR gửi thầu theo tấn",
    t.vfr_theo_khoi  AS "VFR gửi thầu theo CBM",
    t.vfr_max   AS "VFR gửi thầu (max)"
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

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA' THEN t.eta_vh
        WHEN {{date_type}} = 'ATA' THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu' THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

---

## vfr operation

### Avg VFR (VFR by Operation Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT
    AVG("vfr_max") AS avg_vfr
FROM reporting_schema.mv_test_vfr_van_hanh
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (p.p_vendor = 'ALL' OR "nha_van_tai" = p.p_vendor)
    AND (p.p_tender_vehicle_type = 'ALL' OR "loai_xe_van_hanh" = p.p_tender_vehicle_type)
    AND (
        (p.p_date_type = 'tg_gt' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND "eta_vh" >= p.p_from_date AND "eta_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ata_vh" >= p.p_from_date AND "ata_vh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
-- VFR KPI Summary
SELECT
    round(avg(vfr_max), 2)                          AS avg_vfr,
    countIf(vfr_max < 50)                           AS cnt_vfr_50,
    countIf(vfr_max >= 50 AND vfr_max < 70)         AS cnt_vfr_50_70,
    countIf(vfr_max >= 70 AND vfr_max < 95)         AS cnt_vfr_70_95,
    countIf(vfr_max >= 95)                          AS cnt_vfr_95
FROM analytics_workspace.mv_vfr_van_hanh t
WHERE 1 = 1

-- Warehouse
AND (coalesce({{whseid}}, 'ALL') = 'ALL' OR t.ma_diem_nhan IN ({{whseid}}))

-- Area
AND (coalesce({{area}}, 'ALL') = 'ALL' OR t.khu_vuc_doi_xe IN ({{area}}))

-- Transporter
AND (coalesce({{transporter}}, 'ALL') = 'ALL' OR t.nha_van_tai IN ({{transporter}}))

-- Vehicle_type_tender
AND (coalesce({{vehicle_type_ops}}, 'ALL') = 'ALL' OR t.ma_loai_xe_van_hanh IN ({{vehicle_type_ops}}))

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Low <50% (VFR by Operation Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT 
    COUNT(*) AS cnt_vfr_50
FROM reporting_schema.mv_test_vfr_van_hanh
CROSS JOIN params p
WHERE 1 = 1
    AND "vfr_max" < 50
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (p.p_vendor = 'ALL' OR "nha_van_tai" = p.p_vendor)
    AND (p.p_tender_vehicle_type = 'ALL' OR "loai_xe_van_hanh" = p.p_tender_vehicle_type)
    AND (
        (p.p_date_type = 'tg_gt' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND "eta_vh" >= p.p_from_date AND "eta_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ata_vh" >= p.p_from_date AND "ata_vh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
-- VFR KPI Summary
SELECT
    round(avg(vfr_max), 2)                          AS avg_vfr,
    countIf(vfr_max < 50)                           AS cnt_vfr_50,
    countIf(vfr_max >= 50 AND vfr_max < 70)         AS cnt_vfr_50_70,
    countIf(vfr_max >= 70 AND vfr_max < 95)         AS cnt_vfr_70_95,
    countIf(vfr_max >= 95)                          AS cnt_vfr_95
FROM analytics_workspace.mv_vfr_van_hanh t
WHERE 1 = 1

-- Warehouse
AND (coalesce({{whseid}}, 'ALL') = 'ALL' OR t.ma_diem_nhan IN ({{whseid}}))

-- Area
AND (coalesce({{area}}, 'ALL') = 'ALL' OR t.khu_vuc_doi_xe IN ({{area}}))

-- Transporter
AND (coalesce({{transporter}}, 'ALL') = 'ALL' OR t.nha_van_tai IN ({{transporter}}))

-- Vehicle_type_tender
AND (coalesce({{vehicle_type_ops}}, 'ALL') = 'ALL' OR t.ma_loai_xe_van_hanh IN ({{vehicle_type_ops}}))

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Medium 50-70% (VFR by Operation Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT 
    COUNT(*) AS cnt_vfr_50_70
FROM reporting_schema.mv_test_vfr_van_hanh
CROSS JOIN params p
WHERE 1 = 1
    AND "vfr_max" >= 50
    AND "vfr_max" < 70
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (p.p_vendor = 'ALL' OR "nha_van_tai" = p.p_vendor)
    AND (p.p_tender_vehicle_type = 'ALL' OR "loai_xe_van_hanh" = p.p_tender_vehicle_type)
    AND (
        (p.p_date_type = 'tg_gt' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND "eta_vh" >= p.p_from_date AND "eta_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ata_vh" >= p.p_from_date AND "ata_vh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
-- VFR KPI Summary
SELECT
    round(avg(vfr_max), 2)                          AS avg_vfr,
    countIf(vfr_max < 50)                           AS cnt_vfr_50,
    countIf(vfr_max >= 50 AND vfr_max < 70)         AS cnt_vfr_50_70,
    countIf(vfr_max >= 70 AND vfr_max < 95)         AS cnt_vfr_70_95,
    countIf(vfr_max >= 95)                          AS cnt_vfr_95
FROM analytics_workspace.mv_vfr_van_hanh t
WHERE 1 = 1

-- Warehouse
AND (coalesce({{whseid}}, 'ALL') = 'ALL' OR t.ma_diem_nhan IN ({{whseid}}))

-- Area
AND (coalesce({{area}}, 'ALL') = 'ALL' OR t.khu_vuc_doi_xe IN ({{area}}))

-- Transporter
AND (coalesce({{transporter}}, 'ALL') = 'ALL' OR t.nha_van_tai IN ({{transporter}}))

-- Vehicle_type_tender
AND (coalesce({{vehicle_type_ops}}, 'ALL') = 'ALL' OR t.ma_loai_xe_van_hanh IN ({{vehicle_type_ops}}))

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### High 70-95% (VFR by Operation Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT 
    COUNT(*) AS cnt_vfr_70_95
FROM reporting_schema.mv_test_vfr_van_hanh
CROSS JOIN params p
WHERE 1 = 1
    AND "vfr_max" >= 70
    AND "vfr_max" < 95
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (p.p_vendor = 'ALL' OR "nha_van_tai" = p.p_vendor)
    AND (p.p_tender_vehicle_type = 'ALL' OR "loai_xe_van_hanh" = p.p_tender_vehicle_type)
    AND (
        (p.p_date_type = 'eta_vh' AND "eta_vh" >= p.p_from_date AND "eta_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ata_vh" >= p.p_from_date AND "ata_vh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
-- VFR KPI Summary
SELECT
    round(avg(vfr_max), 2)                          AS avg_vfr,
    countIf(vfr_max < 50)                           AS cnt_vfr_50,
    countIf(vfr_max >= 50 AND vfr_max < 70)         AS cnt_vfr_50_70,
    countIf(vfr_max >= 70 AND vfr_max < 95)         AS cnt_vfr_70_95,
    countIf(vfr_max >= 95)                          AS cnt_vfr_95
FROM analytics_workspace.mv_vfr_van_hanh t
WHERE 1 = 1

-- Warehouse
AND (coalesce({{whseid}}, 'ALL') = 'ALL' OR t.ma_diem_nhan IN ({{whseid}}))

-- Area
AND (coalesce({{area}}, 'ALL') = 'ALL' OR t.khu_vuc_doi_xe IN ({{area}}))

-- Transporter
AND (coalesce({{transporter}}, 'ALL') = 'ALL' OR t.nha_van_tai IN ({{transporter}}))

-- Vehicle_type_tender
AND (coalesce({{vehicle_type_ops}}, 'ALL') = 'ALL' OR t.ma_loai_xe_van_hanh IN ({{vehicle_type_ops}}))

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Excellent ≥95% (VFR by Operation Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT 
    COUNT(*) AS cnt_vfr_95
FROM reporting_schema.mv_test_vfr_van_hanh
CROSS JOIN params p
WHERE 1 = 1
    AND "vfr_max" >= 95
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (p.p_vendor = 'ALL' OR "nha_van_tai" = p.p_vendor)
    AND (p.p_tender_vehicle_type = 'ALL' OR "loai_xe_van_hanh" = p.p_tender_vehicle_type)
    AND (
        (p.p_date_type = 'tg_gt' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND "eta_vh" >= p.p_from_date AND "eta_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ata_vh" >= p.p_from_date AND "ata_vh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
-- VFR KPI Summary
SELECT
    round(avg(vfr_max), 2)                          AS avg_vfr,
    countIf(vfr_max < 50)                           AS cnt_vfr_50,
    countIf(vfr_max >= 50 AND vfr_max < 70)         AS cnt_vfr_50_70,
    countIf(vfr_max >= 70 AND vfr_max < 95)         AS cnt_vfr_70_95,
    countIf(vfr_max >= 95)                          AS cnt_vfr_95
FROM analytics_workspace.mv_vfr_van_hanh t
WHERE 1 = 1

-- Warehouse
AND (coalesce({{whseid}}, 'ALL') = 'ALL' OR t.ma_diem_nhan IN ({{whseid}}))

-- Area
AND (coalesce({{area}}, 'ALL') = 'ALL' OR t.khu_vuc_doi_xe IN ({{area}}))

-- Transporter
AND (coalesce({{transporter}}, 'ALL') = 'ALL' OR t.nha_van_tai IN ({{transporter}}))

-- Vehicle_type_tender
AND (coalesce({{vehicle_type_ops}}, 'ALL') = 'ALL' OR t.ma_loai_xe_van_hanh IN ({{vehicle_type_ops}}))

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### VFR vận hành theo khu vực (VFR by Operation Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
),
base AS (
    SELECT
        t."khu_vuc_doi_xe" AS khu_vuc_doi_xe,
        SUM(CAST(t."cbm_ke_hoach" AS DOUBLE PRECISION)) AS total_cbm_ke_hoach,
        SUM(CAST(t."cbm_nhan" AS DOUBLE PRECISION))      AS total_cbm_nhan,
        /* Loose */
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_vfr" = 'Khối'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_khoi_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_vfr" = 'Khối'
                THEN CAST(t."cbm_dang_ky" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_khoi_cbm_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."tan_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_tan_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."tan_dang_ky" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_tan_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_tan_cbm_nhan,
        /* Full Pallet */
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_vfr" = 'Khối'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_khoi_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_vfr" = 'Khối'
                THEN CAST(t."cbm_dang_ky" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_khoi_cbm_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."tan_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_tan_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."tan_dang_ky" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_tan_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_tan_cbm_nhan
    FROM reporting_schema.mv_test_vfr_van_hanh t
    CROSS JOIN params p
    WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
        AND (p.p_area = 'ALL' OR t."khu_vuc_doi_xe" = p.p_area)
        AND (p.p_vendor = 'ALL' OR t."nha_van_tai" = p.p_vendor)
        AND (p.p_tender_vehicle_type = 'ALL' OR t."loai_xe_van_hanh" = p.p_tender_vehicle_type)
        AND (
        (p.p_date_type = 'tg_gt' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND t."eta_vh" >= p.p_from_date AND t."ata_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND t."eta_vh" >= p.p_from_date AND t."ata_vh" < p.p_to_date)
        )
    GROUP BY t."khu_vuc_doi_xe"
),
calc AS (
    SELECT
        khu_vuc_doi_xe,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        COALESCE(loose_cbm_nhan / NULLIF(total_cbm_nhan, 0.0), 0.0) AS loose_weight,
        COALESCE(fp_cbm_nhan    / NULLIF(total_cbm_nhan, 0.0), 0.0) AS fp_weight,
        COALESCE(loose_khoi_cbm_nhan / NULLIF(loose_khoi_cbm_dk, 0.0), 0.0) AS loose_khoi_fill_rate,
        COALESCE(loose_khoi_cbm_nhan / NULLIF(loose_cbm_nhan, 0.0), 0.0)    AS loose_khoi_mix_rate,
        COALESCE(loose_tan_nhan      / NULLIF(loose_tan_dk, 0.0), 0.0)      AS loose_tan_fill_rate,
        COALESCE(loose_tan_cbm_nhan  / NULLIF(loose_cbm_nhan, 0.0), 0.0)    AS loose_tan_mix_rate,
        COALESCE(fp_khoi_cbm_nhan / NULLIF(fp_khoi_cbm_dk, 0.0), 0.0)       AS fp_khoi_fill_rate,
        COALESCE(fp_khoi_cbm_nhan / NULLIF(fp_cbm_nhan, 0.0), 0.0)          AS fp_khoi_mix_rate,
        COALESCE(fp_tan_nhan      / NULLIF(fp_tan_dk, 0.0), 0.0)            AS fp_tan_fill_rate,
        COALESCE(fp_tan_cbm_nhan  / NULLIF(fp_cbm_nhan, 0.0), 0.0)          AS fp_tan_mix_rate
    FROM base
)
SELECT
    khu_vuc_doi_xe,
    total_cbm_ke_hoach,
    ROUND(
        LEAST(
            1.0,
            (
                (
                    loose_khoi_fill_rate * loose_khoi_mix_rate
                    + loose_tan_fill_rate * loose_tan_mix_rate
                ) * loose_weight
                +
                (
                    fp_khoi_fill_rate * fp_khoi_mix_rate
                    + fp_tan_fill_rate * fp_tan_mix_rate
                ) * fp_weight
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY khu_vuc_doi_xe;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.khu_vuc_doi_xe AS khu_vuc_doi_xe,
        SUM(t.cbm_ke_hoach) AS total_cbm_ke_hoach, -- Cột này là Float64 sẵn, ko cần cast
        SUM(t.cbm_nhan)      AS total_cbm_nhan,   -- Cột này là Float64 sẵn
        
        /* Loose - Lưu ý sửa 'Losse' thành 'Loose' nếu DB viết đúng */
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse'), t.cbm_nhan, 0)) AS loose_cbm_nhan,
        
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Khối', t.cbm_nhan, 0)) AS loose_khoi_cbm_nhan,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Khối', toFloat64OrZero(t.cbm_dang_ky), 0)) AS loose_khoi_cbm_dk,
        
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn', t.tan_nhan, 0)) AS loose_tan_nhan,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn', toFloat64OrZero(t.tan_dang_ky), 0)) AS loose_tan_dk,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn', t.cbm_nhan, 0)) AS loose_tan_cbm_nhan,
        
        /* Full Pallet */
        SUM(IF(t.loai_boc_xep = 'Full Pallet', t.cbm_nhan, 0)) AS fp_cbm_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Khối', t.cbm_nhan, 0)) AS fp_khoi_cbm_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Khối', toFloat64OrZero(t.cbm_dang_ky), 0)) AS fp_khoi_cbm_dk,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn', t.tan_nhan, 0)) AS fp_tan_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn', toFloat64OrZero(t.tan_dang_ky), 0)) AS fp_tan_dk,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn', t.cbm_nhan, 0)) AS fp_tan_cbm_nhan
    FROM analytics_workspace.mv_vfr_van_hanh t
    WHERE 1 = 1

-- Warehouse
AND (coalesce({{whseid}}, 'ALL') = 'ALL' OR t.ma_diem_nhan IN ({{whseid}}))

-- Area
AND (coalesce({{area}}, 'ALL') = 'ALL' OR t.khu_vuc_doi_xe IN ({{area}}))

-- Transporter
AND (coalesce({{transporter}}, 'ALL') = 'ALL' OR t.nha_van_tai IN ({{transporter}}))

-- Vehicle_type_tender
AND (coalesce({{vehicle_type_ops}}, 'ALL') = 'ALL' OR t.ma_loai_xe_van_hanh IN ({{vehicle_type_ops}}))

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

    GROUP BY t.khu_vuc_doi_xe
),
calc AS (
    SELECT
        khu_vuc_doi_xe,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        if(total_cbm_nhan = 0, 0, loose_cbm_nhan / total_cbm_nhan) AS loose_weight,
        if(total_cbm_nhan = 0, 0, fp_cbm_nhan / total_cbm_nhan)    AS fp_weight,
        if(loose_khoi_cbm_dk = 0, 0, loose_khoi_cbm_nhan / loose_khoi_cbm_dk) AS loose_khoi_fill_rate,
        if(loose_cbm_nhan = 0, 0, loose_khoi_cbm_nhan / loose_cbm_nhan)       AS loose_khoi_mix_rate,
        if(loose_tan_dk = 0, 0, loose_tan_nhan / loose_tan_dk)               AS loose_tan_fill_rate,
        if(loose_cbm_nhan = 0, 0, loose_tan_cbm_nhan / loose_cbm_nhan)       AS loose_tan_mix_rate,
        if(fp_khoi_cbm_dk = 0, 0, fp_khoi_cbm_nhan / fp_khoi_cbm_dk)         AS fp_khoi_fill_rate,
        if(fp_cbm_nhan = 0, 0, fp_khoi_cbm_nhan / fp_cbm_nhan)               AS fp_khoi_mix_rate,
        if(fp_tan_dk = 0, 0, fp_tan_nhan / fp_tan_dk)                       AS fp_tan_fill_rate,
        if(fp_cbm_nhan = 0, 0, fp_tan_cbm_nhan / fp_cbm_nhan)               AS fp_tan_mix_rate
    FROM base
)
SELECT
    khu_vuc_doi_xe,
    total_cbm_ke_hoach,
    round(
        least(
            1.0,
            (
                (
                    loose_khoi_fill_rate * loose_khoi_mix_rate
                    + loose_tan_fill_rate * loose_tan_mix_rate
                ) * loose_weight
                +
                (
                    fp_khoi_fill_rate * fp_khoi_mix_rate
                    + fp_tan_fill_rate * fp_tan_mix_rate
                ) * fp_weight
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY khu_vuc_doi_xe;
```

### VFR vận hành theo loại xe (VFR by Operation Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
),
base AS (
    SELECT
        t."loai_xe_van_hanh" AS loai_xe_van_hanh,
        SUM(CAST(t."cbm_ke_hoach" AS DOUBLE PRECISION)) AS total_cbm_ke_hoach,
        SUM(CAST(t."cbm_nhan" AS DOUBLE PRECISION))      AS total_cbm_nhan,
        /* Loose */
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_vfr" = 'Khối'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_khoi_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_vfr" = 'Khối'
                THEN CAST(t."cbm_dang_ky" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_khoi_cbm_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."tan_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_tan_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."tan_dang_ky" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_tan_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Other'
                 AND t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS loose_tan_cbm_nhan,
        /* Full Pallet */
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_vfr" = 'Khối'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_khoi_cbm_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_vfr" = 'Khối'
                THEN CAST(t."cbm_dang_ky" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_khoi_cbm_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."tan_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_tan_nhan,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."tan_dang_ky" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_tan_dk,
        SUM(
            CASE
                WHEN t."loai_boc_xep" = 'Full Pallet'
                 AND t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS fp_tan_cbm_nhan
    FROM reporting_schema.mv_test_vfr_van_hanh t
    CROSS JOIN params p
    WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
        AND (p.p_area = 'ALL' OR t."khu_vuc_doi_xe" = p.p_area)
        AND (p.p_vendor = 'ALL' OR t."nha_van_tai" = p.p_vendor)
        AND (p.p_tender_vehicle_type = 'ALL' OR t."loai_xe_van_hanh" = p.p_tender_vehicle_type)
        AND (
        (p.p_date_type = 'tg_gt' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND t."eta_vh" >= p.p_from_date AND t."ata_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND t."eta_vh" >= p.p_from_date AND t."ata_vh" < p.p_to_date)
        )
    GROUP BY t."loai_xe_van_hanh"
),
calc AS (
    SELECT
        loai_xe_van_hanh,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        COALESCE(loose_cbm_nhan / NULLIF(total_cbm_nhan, 0.0), 0.0) AS loose_weight,
        COALESCE(fp_cbm_nhan    / NULLIF(total_cbm_nhan, 0.0), 0.0) AS fp_weight,
        COALESCE(loose_khoi_cbm_nhan / NULLIF(loose_khoi_cbm_dk, 0.0), 0.0) AS loose_khoi_fill_rate,
        COALESCE(loose_khoi_cbm_nhan / NULLIF(loose_cbm_nhan, 0.0), 0.0)    AS loose_khoi_mix_rate,
        COALESCE(loose_tan_nhan      / NULLIF(loose_tan_dk, 0.0), 0.0)      AS loose_tan_fill_rate,
        COALESCE(loose_tan_cbm_nhan  / NULLIF(loose_cbm_nhan, 0.0), 0.0)    AS loose_tan_mix_rate,
        COALESCE(fp_khoi_cbm_nhan / NULLIF(fp_khoi_cbm_dk, 0.0), 0.0)       AS fp_khoi_fill_rate,
        COALESCE(fp_khoi_cbm_nhan / NULLIF(fp_cbm_nhan, 0.0), 0.0)          AS fp_khoi_mix_rate,
        COALESCE(fp_tan_nhan      / NULLIF(fp_tan_dk, 0.0), 0.0)            AS fp_tan_fill_rate,
        COALESCE(fp_tan_cbm_nhan  / NULLIF(fp_cbm_nhan, 0.0), 0.0)          AS fp_tan_mix_rate
    FROM base
)
SELECT
    loai_xe_van_hanh,
    total_cbm_ke_hoach,
    ROUND(
        LEAST(
            1.0,
            (
                (
                    loose_khoi_fill_rate * loose_khoi_mix_rate
                    + loose_tan_fill_rate * loose_tan_mix_rate
                ) * loose_weight
                +
                (
                    fp_khoi_fill_rate * fp_khoi_mix_rate
                    + fp_tan_fill_rate * fp_tan_mix_rate
                ) * fp_weight
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY loai_xe_van_hanh;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.loai_xe_van_hanh AS loai_xe_van_hanh,
        SUM(t.cbm_ke_hoach) AS total_cbm_ke_hoach, -- Cột này là Float64 sẵn, ko cần cast
        SUM(t.cbm_nhan)      AS total_cbm_nhan,   -- Cột này là Float64 sẵn
        
        /* Loose - Lưu ý sửa 'Losse' thành 'Loose' nếu DB viết đúng */
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse'), t.cbm_nhan, 0)) AS loose_cbm_nhan,
        
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Khối', t.cbm_nhan, 0)) AS loose_khoi_cbm_nhan,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Khối', toFloat64OrZero(t.cbm_dang_ky), 0)) AS loose_khoi_cbm_dk,
        
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn', t.tan_nhan, 0)) AS loose_tan_nhan,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn', toFloat64OrZero(t.tan_dang_ky), 0)) AS loose_tan_dk,
        SUM(IF(trim(t.loai_boc_xep) IN ('Loose', 'Losse') AND t.phan_loai_vfr = 'Tấn', t.cbm_nhan, 0)) AS loose_tan_cbm_nhan,
        
        /* Full Pallet */
        SUM(IF(t.loai_boc_xep = 'Full Pallet', t.cbm_nhan, 0)) AS fp_cbm_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Khối', t.cbm_nhan, 0)) AS fp_khoi_cbm_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Khối', toFloat64OrZero(t.cbm_dang_ky), 0)) AS fp_khoi_cbm_dk,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn', t.tan_nhan, 0)) AS fp_tan_nhan,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn', toFloat64OrZero(t.tan_dang_ky), 0)) AS fp_tan_dk,
        SUM(IF(t.loai_boc_xep = 'Full Pallet' AND t.phan_loai_vfr = 'Tấn', t.cbm_nhan, 0)) AS fp_tan_cbm_nhan
    FROM analytics_workspace.mv_vfr_van_hanh t
    WHERE 1 = 1

-- Warehouse
AND (coalesce({{whseid}}, 'ALL') = 'ALL' OR t.ma_diem_nhan IN ({{whseid}}))

-- Area
AND (coalesce({{area}}, 'ALL') = 'ALL' OR t.khu_vuc_doi_xe IN ({{area}}))

-- Transporter
AND (coalesce({{transporter}}, 'ALL') = 'ALL' OR t.nha_van_tai IN ({{transporter}}))

-- Vehicle_type_tender
AND (coalesce({{vehicle_type_ops}}, 'ALL') = 'ALL' OR t.ma_loai_xe_van_hanh IN ({{vehicle_type_ops}}))

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

    GROUP BY t.loai_xe_van_hanh
),
calc AS (
    SELECT
        loai_xe_van_hanh,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        if(total_cbm_nhan = 0, 0, loose_cbm_nhan / total_cbm_nhan) AS loose_weight,
        if(total_cbm_nhan = 0, 0, fp_cbm_nhan / total_cbm_nhan)    AS fp_weight,
        if(loose_khoi_cbm_dk = 0, 0, loose_khoi_cbm_nhan / loose_khoi_cbm_dk) AS loose_khoi_fill_rate,
        if(loose_cbm_nhan = 0, 0, loose_khoi_cbm_nhan / loose_cbm_nhan)       AS loose_khoi_mix_rate,
        if(loose_tan_dk = 0, 0, loose_tan_nhan / loose_tan_dk)               AS loose_tan_fill_rate,
        if(loose_cbm_nhan = 0, 0, loose_tan_cbm_nhan / loose_cbm_nhan)       AS loose_tan_mix_rate,
        if(fp_khoi_cbm_dk = 0, 0, fp_khoi_cbm_nhan / fp_khoi_cbm_dk)         AS fp_khoi_fill_rate,
        if(fp_cbm_nhan = 0, 0, fp_khoi_cbm_nhan / fp_cbm_nhan)               AS fp_khoi_mix_rate,
        if(fp_tan_dk = 0, 0, fp_tan_nhan / fp_tan_dk)                       AS fp_tan_fill_rate,
        if(fp_cbm_nhan = 0, 0, fp_tan_cbm_nhan / fp_cbm_nhan)               AS fp_tan_mix_rate
    FROM base
)
SELECT
    loai_xe_van_hanh,
    total_cbm_ke_hoach,
    round(
        least(
            1.0,
            (
                (
                    loose_khoi_fill_rate * loose_khoi_mix_rate
                    + loose_tan_fill_rate * loose_tan_mix_rate
                ) * loose_weight
                +
                (
                    fp_khoi_fill_rate * fp_khoi_mix_rate
                    + fp_tan_fill_rate * fp_tan_mix_rate
                ) * fp_weight
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY loai_xe_van_hanh;
```

### VFR vận hành theo loại bốc xếp (sẽ có 2 kiểu group: Group theo tháng - SQL cột B, Group theo tuần - SQL cột D)
(VFR by Operation Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-03-01 00:00:00' AS TIMESTAMP) AS p_to_date
),
base AS (
    SELECT
        DATE_TRUNC(
            'month',
            CASE
                WHEN p.p_date_type = 'eta_vh' THEN t."eta_vh"
                WHEN p.p_date_type = 'ata_vh' THEN t."ata_vh"
            END
        ) AS thang,
        t."loai_boc_xep" AS loai_boc_xep,
        SUM(CAST(t."cbm_ke_hoach" AS DOUBLE PRECISION)) AS total_cbm_ke_hoach,
        SUM(CAST(t."cbm_nhan" AS DOUBLE PRECISION))      AS total_cbm_nhan,
        SUM(
            CASE
                WHEN t."phan_loai_vfr" = 'Khối'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS khoi_cbm_nhan,
        SUM(
            CASE
                WHEN t."phan_loai_vfr" = 'Khối'
                THEN CAST(t."cbm_dang_ky" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS khoi_cbm_dk,
        SUM(
            CASE
                WHEN t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."tan_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS tan_nhan,
        SUM(
            CASE
                WHEN t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."tan_dang_ky" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS tan_dk,
        SUM(
            CASE
                WHEN t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS tan_cbm_nhan
    FROM reporting_schema.mv_test_vfr_van_hanh t
    CROSS JOIN params p
    WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
        AND (p.p_area = 'ALL' OR t."khu_vuc_doi_xe" = p.p_area)
        AND (p.p_vendor = 'ALL' OR t."nha_van_tai" = p.p_vendor)
        AND (p.p_tender_vehicle_type = 'ALL' OR t."loai_xe_van_hanh" = p.p_tender_vehicle_type)
        AND (
        (p.p_date_type = 'tg_gt' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND t."eta_vh" >= p.p_from_date AND t."ata_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND t."eta_vh" >= p.p_from_date AND t."ata_vh" < p.p_to_date)
        )
    GROUP BY
        DATE_TRUNC(
            'month',
            CASE
                WHEN p.p_date_type = 'eta_vh' THEN t."eta_vh"
                WHEN p.p_date_type = 'ata_vh' THEN t."ata_vh"
            END
        ),
        t."loai_boc_xep"
),
calc AS (
    SELECT
        thang,
        loai_boc_xep,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        COALESCE(khoi_cbm_nhan / NULLIF(khoi_cbm_dk, 0.0), 0.0)    AS khoi_fill_rate,
        COALESCE(khoi_cbm_nhan / NULLIF(total_cbm_nhan, 0.0), 0.0) AS khoi_mix_rate,
        COALESCE(tan_nhan / NULLIF(tan_dk, 0.0), 0.0)              AS tan_fill_rate,
        COALESCE(tan_cbm_nhan / NULLIF(total_cbm_nhan, 0.0), 0.0)  AS tan_mix_rate
    FROM base
)
SELECT
    TO_CHAR(thang, 'MM-YYYY') AS thang,
    loai_boc_xep,
    total_cbm_ke_hoach,
    ROUND(
        LEAST(
            1.0,
            (
                khoi_fill_rate * khoi_mix_rate
                + tan_fill_rate * tan_mix_rate
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY
    calc.thang,
    loai_boc_xep;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
          toDate(CASE
                WHEN {{date_type}} = 'ETA'                                 THEN t.eta_vh
                WHEN {{date_type}} = 'ATA'                                 THEN t.ata_vh
                WHEN {{date_type}} = 'Ngày gửi thầu'         THEN t.tender_date
            END) AS thoi_gian,
        t.loai_boc_xep,
        SUM(toFloat64(t.cbm_ke_hoach)) AS total_cbm_ke_hoach,
        SUM(toFloat64(t.cbm_nhan))     AS total_cbm_nhan,
        SUM(if(t.phan_loai_vfr = 'Khối',
               toFloat64(t.cbm_nhan), 0))    AS khoi_cbm_nhan,
        SUM(if(t.phan_loai_vfr = 'Khối',
               toFloat64(t.cbm_dang_ky), 0)) AS khoi_cbm_dk,
        SUM(if(t.phan_loai_vfr = 'Tấn',
               toFloat64(t.tan_nhan), 0))    AS tan_nhan,
        SUM(if(t.phan_loai_vfr = 'Tấn',
               toFloat64(t.tan_dang_ky), 0)) AS tan_dk,
        SUM(if(t.phan_loai_vfr = 'Tấn',
               toFloat64(t.cbm_nhan), 0))    AS tan_cbm_nhan
    FROM analytics_workspace.mv_vfr_van_hanh AS t
    WHERE 1 = 1
    
-- Warehouse
AND (coalesce({{whseid}}, 'ALL') = 'ALL' OR t.ma_diem_nhan IN ({{whseid}}))

-- Area
AND (coalesce({{area}}, 'ALL') = 'ALL' OR t.khu_vuc_doi_xe IN ({{area}}))

-- Transporter
AND (coalesce({{transporter}}, 'ALL') = 'ALL' OR t.nha_van_tai IN ({{transporter}}))

-- Vehicle_type_tender
AND (coalesce({{vehicle_type_ops}}, 'ALL') = 'ALL' OR t.ma_loai_xe_van_hanh IN ({{vehicle_type_ops}}))

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

    GROUP BY
                toDate(CASE
                WHEN {{date_type}} = 'ETA'                                 THEN t.eta_vh
                WHEN {{date_type}} = 'ATA'                                 THEN t.ata_vh
                WHEN {{date_type}} = 'Ngày gửi thầu'         THEN t.tender_date
            END)
        ,
        t.loai_boc_xep
),
calc AS (
    SELECT
        thoi_gian,
        loai_boc_xep,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        coalesce(khoi_cbm_nhan / nullIf(khoi_cbm_dk, 0.0),    0.0) AS khoi_fill_rate,
        coalesce(khoi_cbm_nhan / nullIf(total_cbm_nhan, 0.0), 0.0) AS khoi_mix_rate,
        coalesce(tan_nhan      / nullIf(tan_dk, 0.0),         0.0) AS tan_fill_rate,
        coalesce(tan_cbm_nhan  / nullIf(total_cbm_nhan, 0.0), 0.0) AS tan_mix_rate
    FROM base
)
SELECT
    thoi_gian,
    loai_boc_xep,
    total_cbm_ke_hoach,
    round(
        least(
            1.0,
            (
                khoi_fill_rate * khoi_mix_rate
                + tan_fill_rate * tan_mix_rate
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY
    thoi_gian,
    loai_boc_xep;
```

### VFR vận hành theo thời gian và khu vực (VFR by Operation Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-03-01 00:00:00' AS TIMESTAMP) AS p_to_date
),
base AS (
    SELECT
        DATE_TRUNC(
            'month',
            CASE
                WHEN p.p_date_type = 'eta_vh' THEN t."eta_vh"
                WHEN p.p_date_type = 'ata_vh' THEN t."ata_vh"
            END
        ) AS thang,
        t."khu_vuc_doi_xe" AS khu_vuc_doi_xe,
        SUM(CAST(t."cbm_ke_hoach" AS DOUBLE PRECISION)) AS total_cbm_ke_hoach,
        SUM(CAST(t."cbm_nhan" AS DOUBLE PRECISION))      AS total_cbm_nhan,
        SUM(
            CASE
                WHEN t."phan_loai_vfr" = 'Khối'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS khoi_cbm_nhan,
        SUM(
            CASE
                WHEN t."phan_loai_vfr" = 'Khối'
                THEN CAST(t."cbm_dang_ky" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS khoi_cbm_dk,
        SUM(
            CASE
                WHEN t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."tan_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS tan_nhan,
        SUM(
            CASE
                WHEN t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."tan_dang_ky" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS tan_dk,
        SUM(
            CASE
                WHEN t."phan_loai_vfr" = 'Tấn'
                THEN CAST(t."cbm_nhan" AS DOUBLE PRECISION)
                ELSE 0
            END
        ) AS tan_cbm_nhan
    FROM reporting_schema.mv_test_vfr_van_hanh t
    CROSS JOIN params p
    WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
        AND (p.p_area = 'ALL' OR t."khu_vuc_doi_xe" = p.p_area)
        AND (p.p_vendor = 'ALL' OR t."nha_van_tai" = p.p_vendor)
        AND (p.p_tender_vehicle_type = 'ALL' OR t."loai_xe_van_hanh" = p.p_tender_vehicle_type)
        AND (
        (p.p_date_type = 'tg_gt' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND t."eta_vh" >= p.p_from_date AND t."ata_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND t."eta_vh" >= p.p_from_date AND t."ata_vh" < p.p_to_date)
        )
    GROUP BY
        DATE_TRUNC(
            'month',
            CASE
                WHEN p.p_date_type = 'eta_vh' THEN t."eta_vh"
                WHEN p.p_date_type = 'ata_vh' THEN t."ata_vh"
            END
        ),
        t."khu_vuc_doi_xe"
),
calc AS (
    SELECT
        thang,
        khu_vuc_doi_xe,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        COALESCE(khoi_cbm_nhan / NULLIF(khoi_cbm_dk, 0.0), 0.0)    AS khoi_fill_rate,
        COALESCE(khoi_cbm_nhan / NULLIF(total_cbm_nhan, 0.0), 0.0) AS khoi_mix_rate,
        COALESCE(tan_nhan / NULLIF(tan_dk, 0.0), 0.0)              AS tan_fill_rate,
        COALESCE(tan_cbm_nhan / NULLIF(total_cbm_nhan, 0.0), 0.0)  AS tan_mix_rate
    FROM base
)
SELECT
    TO_CHAR(thang, 'MM-YYYY') AS thang,
    khu_vuc_doi_xe,
    total_cbm_ke_hoach,
    ROUND(
        LEAST(
            1.0,
            (
                khoi_fill_rate * khoi_mix_rate
                + tan_fill_rate * tan_mix_rate
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY
    calc.thang,
    khu_vuc_doi_xe;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        toStartOfMonth(
            CASE
                WHEN {{date_type}} = 'ETA'                                 THEN t.eta_vh
                WHEN {{date_type}} = 'ATA'                                 THEN t.ata_vh
                WHEN {{date_type}} = 'Ngày gửi thầu'         THEN t.tender_date
            END
        ) AS thang,
        t.khu_vuc_doi_xe,
        SUM(toFloat64(t.cbm_ke_hoach)) AS total_cbm_ke_hoach,
        SUM(toFloat64(t.cbm_nhan))     AS total_cbm_nhan,
        SUM(if(t.phan_loai_vfr = 'Khối',
               toFloat64(t.cbm_nhan), 0))    AS khoi_cbm_nhan,
        SUM(if(t.phan_loai_vfr = 'Khối',
               toFloat64(t.cbm_dang_ky), 0)) AS khoi_cbm_dk,
        SUM(if(t.phan_loai_vfr = 'Tấn',
               toFloat64(t.tan_nhan), 0))    AS tan_nhan,
        SUM(if(t.phan_loai_vfr = 'Tấn',
               toFloat64(t.tan_dang_ky), 0)) AS tan_dk,
        SUM(if(t.phan_loai_vfr = 'Tấn',
               toFloat64(t.cbm_nhan), 0))    AS tan_cbm_nhan
    FROM analytics_workspace.mv_vfr_van_hanh AS t
    WHERE 1 = 1
   
   -- Warehouse
AND (coalesce({{whseid}}, 'ALL') = 'ALL' OR t.ma_diem_nhan IN ({{whseid}}))

-- Area
AND (coalesce({{area}}, 'ALL') = 'ALL' OR t.khu_vuc_doi_xe IN ({{area}}))

-- Transporter
AND (coalesce({{transporter}}, 'ALL') = 'ALL' OR t.nha_van_tai IN ({{transporter}}))

-- Vehicle_type_tender
AND (coalesce({{vehicle_type_ops}}, 'ALL') = 'ALL' OR t.ma_loai_xe_van_hanh IN ({{vehicle_type_ops}}))

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA' THEN t.eta_vh
        WHEN {{date_type}} = 'ATA' THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu' THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
    
    GROUP BY
        toStartOfMonth(
            CASE
                WHEN {{date_type}} = 'ETA' THEN t.eta_vh
                WHEN {{date_type}} = 'ATA' THEN t.ata_vh
                WHEN {{date_type}} = 'Ngày gửi thầu' THEN t.tender_date
            END
        ),
        t.khu_vuc_doi_xe
),
calc AS (
    SELECT
        thang,
        khu_vuc_doi_xe,
        total_cbm_ke_hoach,
        total_cbm_nhan,
        coalesce(khoi_cbm_nhan / nullIf(khoi_cbm_dk, 0.0),    0.0) AS khoi_fill_rate,
        coalesce(khoi_cbm_nhan / nullIf(total_cbm_nhan, 0.0), 0.0) AS khoi_mix_rate,
        coalesce(tan_nhan      / nullIf(tan_dk, 0.0),         0.0) AS tan_fill_rate,
        coalesce(tan_cbm_nhan  / nullIf(total_cbm_nhan, 0.0), 0.0) AS tan_mix_rate
    FROM base
)
SELECT
    formatDateTime(thang, '%m-%Y') AS thang,
    khu_vuc_doi_xe,
    total_cbm_ke_hoach,
    round(
        least(
            1.0,
            (
                khoi_fill_rate * khoi_mix_rate
                + tan_fill_rate * tan_mix_rate
            )
        ) * 100,
        2
    ) AS vfr_ratio
FROM calc
ORDER BY
    thang,
    khu_vuc_doi_xe;
```

### report vận hành (VFR by Operation Trip) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'ALL'::VARCHAR AS p_tender_vehicle_type,
        'eta_vh'::VARCHAR AS p_date_type,
        CAST('2026-04-16 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-04-16 23:59:59' AS TIMESTAMP) AS p_to_date
)
    SELECT
    t."id_chuyen_gui_thau" as "ID chuyến gửi thầu",
    t.ma_chuyen_van_hanh as "Mã chuyến vận hành",
    t.ma_don_hang as "Mã đơn hàng",
    t.dich_vu_van_chuyen as "Dịch vụ vận chuyển",
    t.trang_thai_chuyen as "Trạng thái chuyến",
    t.tender_date as "Thời gian gửi thầu",
    t.eta_vh as "ETA chuyến vận hành",
    t.ata_vh as "ATA chuyến vận hành",
    t.so_xe as "Số xe",
    t.tai_xe as "Tên tài xế",
    t.nha_van_tai as "Tên ngắn nhà thầu",
    t.nhom_hang_hoa as "Tên nhóm hàng",
    t.ma_diem_nhan as "Mã điểm nhận",
    t.diem_nhan as "Tên điểm nhận",
    t.ma_diem_giao as "Mã điểm giao",
    t.diem_giao as "Tên điểm giao",
    t.khu_vuc_doi_xe as "Khu vực đội xe",
    t.loai_boc_xep as "Loại bốc xếp",
    t.loai_xe_van_hanh as "Loại xe vận hành",
    t.loai_xe_gui_thau as "Loại xe gửi thầu",
    t.tan_dang_ky as "Tấn đăng ký",
    t.cbm_dang_ky as "CBM đăng ký",
    t.tan_ke_hoach as "Tấn kế hoạch",
    t.tan_nhan as "Tấn nhận",
    t.tan_giao as "Tấn giao", 
    t.cbm_ke_hoach as "CBM kế hoạch",
    t.cbm_nhan as "CBM nhận",
    t.cbm_giao as "CBM giao",
    t.vfr_theo_tan as "VFR vận hành theo tấn",
    t.vfr_theo_khoi as "VFR vận hành theo CBM",
    t.vfr_max  as "VFR vận hành (max)"
    FROM reporting_schema.mv_test_vfr_van_hanh t
    CROSS JOIN params p
    WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
        AND (p.p_area = 'ALL' OR t."khu_vuc_doi_xe" = p.p_area)
        AND (p.p_vendor = 'ALL' OR t."nha_van_tai" = p.p_vendor)
        AND (p.p_tender_vehicle_type = 'ALL' OR t."loai_xe_van_hanh" = p.p_tender_vehicle_type)
        AND (
        (p.p_date_type = 'tg_gt' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND t."eta_vh" >= p.p_from_date AND t."ata_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND t."eta_vh" >= p.p_from_date AND t."ata_vh" < p.p_to_date)
        )
```

**ClickHouse SQL:**

```sql
SELECT
    t.id_chuyen_gui_thau                    AS "ID chuyến gửi thầu",
    t.ma_chuyen_van_hanh                    AS "Mã chuyến vận hành",
    t.ma_don_hang                           AS "Mã đơn hàng",
    t.dich_vu_van_chuyen                    AS "Dịch vụ vận chuyển",
    t.trang_thai_chuyen                     AS "Trạng thái chuyến",
    t.tender_date                    AS "Thời gian gửi thầu",
    t.eta_vh                   AS "ETA chuyến vận hành",
    t.ata_vh                   AS "ATA chuyến vận hành",
    t.so_xe                                 AS "Số xe",
    t.tai_xe                            AS "Tên tài xế",
    t.nha_van_tai                     AS "Tên ngắn nhà thầu",
    t.nhom_hang_hoa                         AS "Tên nhóm hàng",
    t.ma_diem_nhan                          AS "Mã điểm nhận",
    t.diem_nhan                         AS "Tên điểm nhận",
    t.ma_diem_giao                          AS "Mã điểm giao",
    t.diem_giao                         AS "Tên điểm giao",
    t.khu_vuc_doi_xe                        AS "Khu vực đội xe",
    t.loai_boc_xep                          AS "Loại bốc xếp",
    t.loai_xe_van_hanh                      AS "Loại xe vận hành",
    t.loai_xe_gui_thau                      AS "Loại xe gửi thầu",
    t.tan_dang_ky                         AS "Tấn đăng ký",
    t.cbm_dang_ky                                   AS "CBM đăng ký",
    t.tan_ke_hoach                          AS "Tấn kế hoạch",
    t.tan_nhan                              AS "Tấn nhận",
    t.tan_giao                              AS "Tấn giao",
    t.cbm_ke_hoach                      AS "CBM kế hoạch",
    t.cbm_nhan                          AS "CBM nhận",
    t.cbm_giao                          AS "CBM giao",
    t.vfr_theo_tan   AS "VFR gửi thầu theo tấn",
    t.vfr_theo_khoi  AS "VFR gửi thầu theo CBM",
    t.vfr_max   AS "VFR gửi thầu (max)"
FROM analytics_workspace.mv_vfr_van_hanh t
WHERE 1 = 1

-- Warehouse
AND (coalesce({{whseid}}, 'ALL') = 'ALL' OR t.ma_diem_nhan IN ({{whseid}}))

-- Area
AND (coalesce({{area}}, 'ALL') = 'ALL' OR t.khu_vuc_doi_xe IN ({{area}}))

-- Transporter
AND (coalesce({{transporter}}, 'ALL') = 'ALL' OR t.nha_van_tai IN ({{transporter}}))

-- Vehicle_type_tender
AND (coalesce({{vehicle_type_ops}}, 'ALL') = 'ALL' OR t.ma_loai_xe_van_hanh IN ({{vehicle_type_ops}}))

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA' THEN t.eta_vh
        WHEN {{date_type}} = 'ATA' THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu' THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

---

## Fulfillment Ratio (tỷ lệ đáp ứng)

### Tỷ lệ đáp ứng `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'tender_date'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT
    ROUND(
        COUNT(DISTINCT CASE WHEN dap_ung_gui_thau = true THEN id_chuyen_gui_thau END) * 100.0
        / NULLIF(COUNT(DISTINCT id_chuyen_gui_thau), 0),
        2
    ) AS ty_le_dap_ung_pct
FROM reporting_schema.mv_test_dap_ung_gui_thau
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (p.p_area = 'ALL' OR "nha_van_tai" = p.p_vendor)
    AND (
       (p.p_date_type = 'tender_date' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND "eta_vh" >= p.p_from_date AND "eta_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ata_vh" >= p.p_from_date AND "ata_vh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
SELECT
    countDistinct(id_chuyen_gui_thau) AS so_id_chuyen_gui_thau,
    countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_dap_ung,
    countDistinct(if(dap_ung_gui_thau = false, id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_khong_dap_ung,
    countDistinct(id_chuyen_van_hanh) AS so_id_chuyen_van_hanh,
    round(
        countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL)) * 100.0
        / nullIf(countDistinct(id_chuyen_gui_thau), 0),
        2
    ) AS ty_le_dap_ung_pct
FROM analytics_workspace.mv_dap_ung_gui_thau
WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupUniqArray(ma_su_dung)) FROM analytics_workspace.mv_masterdata_kho_stm
    ),
    1 = 1,
    t.ma_diem_nhan IN ({{whseid}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Đáp ứng `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'tender_date'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT
    COUNT(DISTINCT CASE WHEN dap_ung_gui_thau = true THEN id_chuyen_gui_thau END) AS so_id_chuyen_gui_thau_dap_ung
FROM reporting_schema.mv_test_dap_ung_gui_thau
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (p.p_area = 'ALL' OR "nha_van_tai" = p.p_vendor)
    AND (
        (p.p_date_type = 'tender_date' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND "eta_vh" >= p.p_from_date AND "eta_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ata_vh" >= p.p_from_date AND "ata_vh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
SELECT
    countDistinct(id_chuyen_gui_thau) AS so_id_chuyen_gui_thau,
    countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_dap_ung,
    countDistinct(if(dap_ung_gui_thau = false, id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_khong_dap_ung,
    countDistinct(id_chuyen_van_hanh) AS so_id_chuyen_van_hanh,
    round(
        countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL)) * 100.0
        / nullIf(countDistinct(id_chuyen_gui_thau), 0),
        2
    ) AS ty_le_dap_ung_pct
FROM analytics_workspace.mv_dap_ung_gui_thau
WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupUniqArray(ma_su_dung)) FROM analytics_workspace.mv_masterdata_kho_stm
    ),
    1 = 1,
    t.ma_diem_nhan IN ({{whseid}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Không đáp ứng `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'tender_date'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT
    COUNT(DISTINCT CASE WHEN dap_ung_gui_thau = false THEN id_chuyen_gui_thau END) AS so_id_chuyen_gui_thau_khong_dap_ung
FROM reporting_schema.mv_test_dap_ung_gui_thau
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (p.p_area = 'ALL' OR "nha_van_tai" = p.p_vendor)
    AND (
        (p.p_date_type = 'tender_date' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND "eta_vh" >= p.p_from_date AND "eta_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ata_vh" >= p.p_from_date AND "ata_vh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
SELECT
    countDistinct(id_chuyen_gui_thau) AS so_id_chuyen_gui_thau,
    countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_dap_ung,
    countDistinct(if(dap_ung_gui_thau = false, id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_khong_dap_ung,
    countDistinct(id_chuyen_van_hanh) AS so_id_chuyen_van_hanh,
    round(
        countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL)) * 100.0
        / nullIf(countDistinct(id_chuyen_gui_thau), 0),
        2
    ) AS ty_le_dap_ung_pct
FROM analytics_workspace.mv_dap_ung_gui_thau
WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupUniqArray(ma_su_dung)) FROM analytics_workspace.mv_masterdata_kho_stm
    ),
    1 = 1,
    t.ma_diem_nhan IN ({{whseid}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Tổng chuyến gửi thầu `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'tender_date'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT
    COUNT(DISTINCT id_chuyen_gui_thau) AS so_id_chuyen_gui_thau
FROM reporting_schema.mv_test_dap_ung_gui_thau
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (
        (p.p_date_type = 'tender_date' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND "eta_vh" >= p.p_from_date AND "eta_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ata_vh" >= p.p_from_date AND "ata_vh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
SELECT
    countDistinct(id_chuyen_gui_thau) AS so_id_chuyen_gui_thau,
    countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_dap_ung,
    countDistinct(if(dap_ung_gui_thau = false, id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_khong_dap_ung,
    countDistinct(id_chuyen_van_hanh) AS so_id_chuyen_van_hanh,
    round(
        countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL)) * 100.0
        / nullIf(countDistinct(id_chuyen_gui_thau), 0),
        2
    ) AS ty_le_dap_ung_pct
FROM analytics_workspace.mv_dap_ung_gui_thau
WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupUniqArray(ma_su_dung)) FROM analytics_workspace.mv_masterdata_kho_stm
    ),
    1 = 1,
    t.ma_diem_nhan IN ({{whseid}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Tổng chuyến vận hành `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'tender_date'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT
    COUNT(DISTINCT id_chuyen_van_hanh) AS so_id_chuyen_van_hanh
FROM reporting_schema.mv_test_dap_ung_gui_thau
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (
        (p.p_date_type = 'tender_date' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND "eta_vh" >= p.p_from_date AND "eta_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ata_vh" >= p.p_from_date AND "ata_vh" < p.p_to_date)
    );
```

**ClickHouse SQL:**

```sql
SELECT
    countDistinct(id_chuyen_gui_thau) AS so_id_chuyen_gui_thau,
    countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_dap_ung,
    countDistinct(if(dap_ung_gui_thau = false, id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_khong_dap_ung,
    countDistinct(id_chuyen_van_hanh) AS so_id_chuyen_van_hanh,
    round(
        countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL)) * 100.0
        / nullIf(countDistinct(id_chuyen_gui_thau), 0),
        2
    ) AS ty_le_dap_ung_pct
FROM analytics_workspace.mv_dap_ung_gui_thau
WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupUniqArray(ma_su_dung)) FROM analytics_workspace.mv_masterdata_kho_stm
    ),
    1 = 1,
    t.ma_diem_nhan IN ({{whseid}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Tỷ lệ đáp ứng theo nhà vận tải `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'tender_date'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
SELECT
    nha_van_tai,
    ROUND(
        COUNT(DISTINCT CASE WHEN dap_ung_gui_thau = true THEN id_chuyen_gui_thau END) * 100.0
        / NULLIF(COUNT(DISTINCT id_chuyen_gui_thau), 0),
        2
    ) AS ty_le_dap_ung_pct,
    COUNT(DISTINCT CASE WHEN dap_ung_gui_thau = true THEN id_chuyen_gui_thau END) AS so_id_chuyen_gui_thau_du,
    COUNT(DISTINCT CASE WHEN dap_ung_gui_thau = false THEN id_chuyen_gui_thau END) AS so_id_chuyen_gui_thau_kdu
FROM reporting_schema.mv_test_dap_ung_gui_thau
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (
        (p.p_date_type = 'tender_date' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR
        (p.p_date_type = 'eta_vh' AND "eta_vh" >= p.p_from_date AND "eta_vh" < p.p_to_date)
        OR
        (p.p_date_type = 'ata_vh' AND "ata_vh" >= p.p_from_date AND "ata_vh" < p.p_to_date)
    )
GROUP BY nha_van_tai
ORDER BY nha_van_tai;
```

**ClickHouse SQL:**

```sql
SELECT
    nha_van_tai,
    round(
        countDistinct(if(dap_ung_gui_thau = true,  id_chuyen_gui_thau, NULL)) * 100.0
        / nullIf(countDistinct(id_chuyen_gui_thau), 0),
        2
    ) AS ty_le_dap_ung_pct,
    countDistinct(if(dap_ung_gui_thau = true,  id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_du,
    countDistinct(if(dap_ung_gui_thau = false, id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_kdu
FROM analytics_workspace.mv_dap_ung_gui_thau
WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupUniqArray(ma_su_dung)) FROM analytics_workspace.mv_masterdata_kho_stm
    ),
    1 = 1,
    t.ma_diem_nhan IN ({{whseid}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

GROUP BY nha_van_tai
ORDER BY nha_van_tai
```

### Tỷ lệ đáp ứng theo thời gian (Group theo Tháng hoặc Tuần) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'tender_date'::VARCHAR AS p_date_type,
        'day'::VARCHAR AS p_granularity,   -- day / week / month
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-03-08 00:00:00' AS TIMESTAMP) AS p_to_date
),
base AS (
    SELECT
        id_chuyen_gui_thau,
        dap_ung_gui_thau,
        CASE
                WHEN p.p_date_type ='tender_date' THEN "tender_date"
            WHEN p.p_date_type = 'eta_vh'     THEN "eta_vh"
            WHEN p.p_date_type = 'ata_vh'     THEN "ata_vh"
        END AS ngay_goc,
        p.p_granularity
    FROM reporting_schema.mv_test_dap_ung_gui_thau
    CROSS JOIN params p
    WHERE 1 = 1
        AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
        AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
        AND (
            (p.p_date_type = 'tender_date' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
            OR
            (p.p_date_type = 'eta_vh' AND "eta_vh" >= p.p_from_date AND "eta_vh" < p.p_to_date)
            OR
            (p.p_date_type = 'ata_vh' AND "ata_vh" >= p.p_from_date AND "ata_vh" < p.p_to_date)
        )
)
SELECT
    CASE
        WHEN p_granularity = 'day' THEN TO_CHAR(DATE_TRUNC('day', ngay_goc), 'DD-MM-YYYY')
        WHEN p_granularity = 'week' THEN TO_CHAR(DATE_TRUNC('week', ngay_goc), 'IYYY-"W"IW')
        WHEN p_granularity = 'month' THEN TO_CHAR(DATE_TRUNC('month', ngay_goc), 'MM-YYYY')
    END AS thoi_gian,
    ROUND(
        COUNT(DISTINCT CASE WHEN dap_ung_gui_thau = true THEN id_chuyen_gui_thau END) * 100.0
        / NULLIF(COUNT(DISTINCT id_chuyen_gui_thau), 0),
        2
    ) AS ty_le_dap_ung_pct,
    COUNT(DISTINCT CASE WHEN dap_ung_gui_thau = true THEN id_chuyen_gui_thau END) AS so_id_chuyen_gui_thau_du,
    COUNT(DISTINCT CASE WHEN dap_ung_gui_thau = false THEN id_chuyen_gui_thau END) AS so_id_chuyen_gui_thau_kdu
FROM base
GROUP BY 1
ORDER BY 1;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        id_chuyen_gui_thau,
        dap_ung_gui_thau,
        CASE
            WHEN {{date_type}} = 'Ngày gửi thầu'         THEN tender_date
            WHEN {{date_type}} = 'ETA'                      THEN eta_vh
            WHEN {{date_type}} = 'ATA'                      THEN ata_vh
        END AS ngay_goc
    FROM analytics_workspace.mv_dap_ung_gui_thau
    WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupUniqArray(ma_su_dung)) FROM analytics_workspace.mv_masterdata_kho_stm
    ),
    1 = 1,
    t.ma_diem_nhan IN ({{whseid}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

)
SELECT
    ngay_goc AS thoi_gian,
    round(
        countDistinct(if(dap_ung_gui_thau = true,  id_chuyen_gui_thau, NULL)) * 100.0
        / nullIf(countDistinct(id_chuyen_gui_thau), 0),
        2
    ) AS ty_le_dap_ung_pct,
    countDistinct(if(dap_ung_gui_thau = true,  id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_du,
    countDistinct(if(dap_ung_gui_thau = false, id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_kdu
FROM base
GROUP BY 1
ORDER BY 1
```

### Report Tỷ lệ đáp ứng `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_locationfrom,
        'ALL'::VARCHAR AS p_area,
        'ALL'::VARCHAR AS p_vendor,
        'tender_date'::VARCHAR AS p_date_type,
        CAST('2026-02-01 00:00:00' AS TIMESTAMP) AS p_from_date,
        CAST('2026-02-08 00:00:00' AS TIMESTAMP) AS p_to_date
)
select
    t.dap_ung_gui_thau as "Đáp ứng gửi thầu",
    t."id_chuyen_gui_thau" as "ID chuyến gửi thầu",
    t.ma_chuyen_van_hanh as "Mã chuyến vận hành",
    t.ma_don_hang as "Mã đơn hàng",
    t.dich_vu_van_chuyen as "Dịch vụ vận chuyển",
    t.trang_thai_chuyen as "Trạng thái chuyến",
    t.tender_date as "Thời gian gửi thầu",
    t.eta_vh as "ETA chuyến vận hành",
    t.ata_vh as "ATA chuyến vận hành",
    t.so_xe as "Số xe",
    t.tai_xe as "Tên tài xế",
    t.nha_van_tai as "Tên ngắn nhà thầu",
    t.nhom_hang_hoa as "Tên nhóm hàng",
    t.ma_diem_nhan as "Mã điểm nhận",
    t.diem_nhan as "Tên điểm nhận",
    t.ma_diem_giao as "Mã điểm giao",
    t.diem_giao as "Tên điểm giao",
    t.khu_vuc_doi_xe as "Khu vực đội xe",
    t.loai_boc_xep as "Loại bốc xếp",
    t.loai_xe_van_hanh as "Loại xe vận hành",
    t.loai_xe_gui_thau as "Loại xe gửi thầu",
    t.tan_ke_hoach as "Tấn kế hoạch",
    t.tan_nhan as "Tấn nhận",
    t.tan_giao as "Tấn giao", 
    t.cbm_ke_hoach as "CBM kế hoạch",
    t.cbm_nhan as "CBM nhận",
    t.cbm_giao as "CBM giao"
FROM reporting_schema.mv_test_dap_ung_gui_thau t
CROSS JOIN params p
WHERE 1 = 1
    AND (p.p_locationfrom = 'ALL' OR "diem_nhan" = p.p_locationfrom)
    AND (p.p_area = 'ALL' OR "khu_vuc_doi_xe" = p.p_area)
    AND (
        (p.p_date_type = 'tender_date' AND "tender_date" >= p.p_from_date AND "tender_date" < p.p_to_date)
        OR 
        (p.p_date_type = 'eta_vh' AND "eta_vh" >= p.p_from_date AND "eta_vh" < p.p_to_date)
        OR 
        (p.p_date_type = 'ata_vh' AND "ata_vh" >= p.p_from_date AND "ata_vh" < p.p_to_date) 
);
```

**ClickHouse SQL:**

```sql
SELECT
    t.dap_ung_gui_thau as "Đáp ứng gửi thầu",
    t."id_chuyen_gui_thau" as "ID chuyến gửi thầu",
    t.ma_chuyen_van_hanh as "Mã chuyến vận hành",
    t.ma_don_hang as "Mã đơn hàng",
    t.dich_vu_van_chuyen as "Dịch vụ vận chuyển",
    t.trang_thai_chuyen as "Trạng thái chuyến",
    t.tender_date as "Thời gian gửi thầu",
    t.eta_vh as "ETA chuyến vận hành",
    t.ata_vh as "ATA chuyến vận hành",
    t.so_xe as "Số xe",
    t.tai_xe as "Tên tài xế",
    t.nha_van_tai as "Tên ngắn nhà thầu",
    t.nhom_hang_hoa as "Tên nhóm hàng",
    t.ma_diem_nhan as "Mã điểm nhận",
    t.diem_nhan as "Tên điểm nhận",
    t.ma_diem_giao as "Mã điểm giao",
    t.diem_giao as "Tên điểm giao",
    t.khu_vuc_doi_xe as "Khu vực đội xe",
    t.loai_boc_xep as "Loại bốc xếp",
    t.loai_xe_van_hanh as "Loại xe vận hành",
    t.loai_xe_gui_thau as "Loại xe gửi thầu",
    t.tan_ke_hoach as "Tấn kế hoạch",
    t.tan_nhan as "Tấn nhận",
    t.tan_giao as "Tấn giao", 
    t.cbm_ke_hoach as "CBM kế hoạch",
    t.cbm_nhan as "CBM nhận",
    t.cbm_giao as "CBM giao"
FROM analytics_workspace.mv_dap_ung_gui_thau t
WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupUniqArray(ma_su_dung)) FROM analytics_workspace.mv_masterdata_kho_stm
    ),
    1 = 1,
    t.ma_diem_nhan IN ({{whseid}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.tender_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

---

## Compliance Ratio (tỷ lệ tuân thủ)

### Tổng số chuyến vận hành `New`

**ClickHouse SQL:**

```sql
SELECT
    countDistinct(ma_chuyen_van_hanh)                           AS so_chuyen_distinct,
    count(ma_diem)                                              AS diem_van_hanh,
    countIf(tuan_thu_van_hanh = 'Tuân thủ')                    AS so_diem_tuan_thu,
    countIf(tuan_thu_van_hanh = 'Vi phạm')                     AS so_diem_khong_tuan_thu,
    round(
        100.0 * countIf(tuan_thu_van_hanh = 'Tuân thủ')
        / nullIf(count(ma_diem), 0),
        2
    )                                                           AS ty_le_tuan_thu
FROM analytics_workspace.mv_dap_ung_van_hanh
WHERE 1 = 1

-- Mã điểm
AND if(
    arraySort([{{location}}]) = (
        SELECT arraySort(groupUniqArray(location_code)) FROM analytics_workspace.mv_filter_location_tuan_thu
    ),
    1 = 1,
    t.ma_diem IN ({{location}})
)

-- Loại điểm
AND if(
    arraySort([{{location_type}}]) = (
        SELECT arraySort(groupUniqArray(code)) FROM analytics_workspace.mv_filter_location_type_tuan_thu
    ),
    1 = 1,
    t.loai_diem IN ({{location_type}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Tổng số điểm vận hành `New`

**ClickHouse SQL:**

```sql
SELECT
    countDistinct(ma_chuyen_van_hanh)                           AS so_chuyen_distinct,
    count(ma_diem)                                              AS diem_van_hanh,
    countIf(tuan_thu_van_hanh = 'Tuân thủ')                    AS so_diem_tuan_thu,
    countIf(tuan_thu_van_hanh = 'Vi phạm')                     AS so_diem_khong_tuan_thu,
    round(
        100.0 * countIf(tuan_thu_van_hanh = 'Tuân thủ')
        / nullIf(count(ma_diem), 0),
        2
    )                                                           AS ty_le_tuan_thu
FROM analytics_workspace.mv_dap_ung_van_hanh
WHERE 1 = 1

-- Mã điểm
AND if(
    arraySort([{{location}}]) = (
        SELECT arraySort(groupUniqArray(location_code)) FROM analytics_workspace.mv_filter_location_tuan_thu
    ),
    1 = 1,
    t.ma_diem IN ({{location}})
)

-- Loại điểm
AND if(
    arraySort([{{location_type}}]) = (
        SELECT arraySort(groupUniqArray(code)) FROM analytics_workspace.mv_filter_location_type_tuan_thu
    ),
    1 = 1,
    t.loai_diem IN ({{location_type}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Tỷ lệ tuân thủ `New`

**ClickHouse SQL:**

```sql
SELECT
    countDistinct(ma_chuyen_van_hanh)                           AS so_chuyen_distinct,
    count(ma_diem)                                              AS diem_van_hanh,
    countIf(tuan_thu_van_hanh = 'Tuân thủ')                    AS so_diem_tuan_thu,
    countIf(tuan_thu_van_hanh = 'Vi phạm')                     AS so_diem_khong_tuan_thu,
    round(
        100.0 * countIf(tuan_thu_van_hanh = 'Tuân thủ')
        / nullIf(count(ma_diem), 0),
        2
    )                                                           AS ty_le_tuan_thu
FROM analytics_workspace.mv_dap_ung_van_hanh
WHERE 1 = 1

-- Mã điểm
AND if(
    arraySort([{{location}}]) = (
        SELECT arraySort(groupUniqArray(location_code)) FROM analytics_workspace.mv_filter_location_tuan_thu
    ),
    1 = 1,
    t.ma_diem IN ({{location}})
)

-- Loại điểm
AND if(
    arraySort([{{location_type}}]) = (
        SELECT arraySort(groupUniqArray(code)) FROM analytics_workspace.mv_filter_location_type_tuan_thu
    ),
    1 = 1,
    t.loai_diem IN ({{location_type}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_vh
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_vh
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### Tỷ lệ tuân thủ theo nhà vận tải `New`

**ClickHouse SQL:**

```sql
WITH filtered AS (
    SELECT
        ma_diem,
        nha_van_tai,
        tuan_thu_van_hanh
    FROM analytics_workspace.mv_dap_ung_van_hanh
    WHERE 1 = 1

-- Mã điểm
AND if(
    arraySort([{{location}}]) = (
        SELECT arraySort(groupUniqArray(location_code)) FROM analytics_workspace.mv_filter_location_tuan_thu
    ),
    1 = 1,
    t.ma_diem IN ({{location}})
)

-- Loại điểm
AND if(
    arraySort([{{location_type}}]) = (
        SELECT arraySort(groupUniqArray(code)) FROM analytics_workspace.mv_filter_location_type_tuan_thu
    ),
    1 = 1,
    t.loai_diem IN ({{location_type}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_chuyen
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_chuyen
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
 
)
SELECT
    nha_van_tai,

    SUM(
        CASE 
            WHEN tuan_thu_van_hanh = 'Tuân thủ' THEN 1 
            ELSE 0 
        END
    ) AS so_diem_tuan_thu,

    SUM(
        CASE 
            WHEN tuan_thu_van_hanh = 'Vi phạm' THEN 1 
            ELSE 0 
        END
    ) AS so_diem_khong_tuan_thu,

    ROUND(
        100.0 * SUM(
            CASE 
                WHEN tuan_thu_van_hanh = 'Tuân thủ' THEN 1 
                ELSE 0 
            END
        ) / NULLIF(COUNT(ma_diem), 0),
        2
    ) AS ty_le_tuan_thu

FROM filtered
GROUP BY nha_van_tai
ORDER BY ty_le_tuan_thu DESC;
```

### Tỷ lệ tuân thủ theo thời gian `New`

**ClickHouse SQL:**

```sql
WITH filtered AS (
    SELECT
        ma_diem,
        nha_van_tai,
        tuan_thu_van_hanh,
        toDate(
        CASE
            WHEN {{date_type}} = 'ETA' THEN eta_chuyen
            WHEN {{date_type}} = 'ATA' THEN ata_chuyen
        END) AS ngay_goc
    FROM analytics_workspace.mv_dap_ung_van_hanh
    WHERE 1 = 1

-- Mã điểm
AND if(
    arraySort([{{location}}]) = (
        SELECT arraySort(groupUniqArray(location_code)) FROM analytics_workspace.mv_filter_location_tuan_thu
    ),
    1 = 1,
    t.ma_diem IN ({{location}})
)

-- Loại điểm
AND if(
    arraySort([{{location_type}}]) = (
        SELECT arraySort(groupUniqArray(code)) FROM analytics_workspace.mv_filter_location_type_tuan_thu
    ),
    1 = 1,
    t.loai_diem IN ({{location_type}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_chuyen
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_chuyen
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
 
),
grouped AS (
    SELECT
        ngay_goc AS thoi_gian,
        ma_diem,
        nha_van_tai,
        tuan_thu_van_hanh
    FROM filtered
)
SELECT
    thoi_gian,
    count(ma_diem)                          AS diem_van_hanh,
    countIf(tuan_thu_van_hanh = 'Tuân thủ') AS so_diem_tuan_thu,
    countIf(tuan_thu_van_hanh = 'Vi phạm')  AS so_diem_khong_tuan_thu,
    round(
        100.0 * countIf(tuan_thu_van_hanh = 'Tuân thủ')
        / nullIf(count(ma_diem), 0),
        2
    )                                       AS ty_le_tuan_thu
FROM grouped
GROUP BY thoi_gian
ORDER BY thoi_gian
```

### Report Tỷ lệ tuân thủ] `New`

**ClickHouse SQL:**

```sql
SELECT
    t.ma_chuyen_van_hanh as "Mã chuyến vận hành",
    t.ma_nha_van_tai as "Mã nhà vận tải",
    t.nha_van_tai as "Nhà vận tải",
    t.tai_xe as "Tài xế",
    t.ma_don_hang as "Mã đơn hàng",
    t.etd_chuyen as "ETD chuyến vận hành",
    t.atd_chuyen as "ATD chuyến vận hành",
    t.eta_chuyen as "ETA chuyến vận hành",
    t.ata_chuyen as "ATA chuyến vận hành",
    t.ma_diem as "Mã điểm",
    t.ten_diem as "Tên điểm",
    t.loai_diem as "Loại điểm",
    t.thoi_gian_vao_diem as "Thời gian vào điểm",
    t.user_thao_tac_vao_diem as "User thao tác vào điểm",
    t.phuong_thuc_vao_diem as "Phương thức vào điểm",
    t.thoi_gian_ra_diem as "Thời gian ra điểm",
    t.user_thao_tac_ra_diem as "User thao tác ra điểm",
    t.phuong_thuc_ra_diem as "Phương thức ra điểm",
    t.so_luong_giao as "Số lượng giao",
    t.thoi_gian_load_hang_quy_dinh_gio as "Thời gian load hàng qui định (giờ)",
    t.thoi_gian_load_hang_thuc_te_gio as "Thời gian laod hàng thực tế (giờ)",
    t.thao_tac_ra_vao_diem as "Thao tác vào/ra điểm", 
    t.thoi_gian_load_hang as "Thời gian load hàng",
    t.tuan_thu_van_hanh as "Tuân thủ vận hành"
FROM analytics_workspace.mv_dap_ung_van_hanh t
WHERE 1 = 1

-- Mã điểm
AND if(
    arraySort([{{location}}]) = (
        SELECT arraySort(groupUniqArray(location_code)) FROM analytics_workspace.mv_filter_location_tuan_thu
    ),
    1 = 1,
    t.ma_diem IN ({{location}})
)

-- Loại điểm
AND if(
    arraySort([{{location_type}}]) = (
        SELECT arraySort(groupUniqArray(code)) FROM analytics_workspace.mv_filter_location_type_tuan_thu
    ),
    1 = 1,
    t.loai_diem IN ({{location_type}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.nha_van_tai IN ({{transporter}})
)

-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA'
            THEN t.eta_chuyen
        WHEN {{date_type}} = 'ATA'
            THEN t.ata_chuyen
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

ORDER BY
    CASE 
        WHEN {{location_type}} = 'ETA' THEN eta_chuyen
        WHEN {{location_type}} = 'ATA' THEN ata_chuyen
    END;
```

---

## Transaction move

### Tổng Volume Inbound `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT
        'ALL'::VARCHAR AS p_warehouse,
        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,
        'CSE'::VARCHAR AS p_uom,
        'ALL'::VARCHAR AS p_activity
)
SELECT
    UPPER(p_uom) AS uom,

    SUM(
        CASE
            WHEN direction = 'INBOUND' THEN
                CASE
                    WHEN UPPER(p_uom) = 'CSE' THEN COALESCE("CSE", 0)
                    WHEN UPPER(p_uom) = 'PCE' THEN COALESCE("PCE", 0)
                    WHEN UPPER(p_uom) = 'CBM' THEN COALESCE("CBM", 0)
                    WHEN UPPER(p_uom) = 'TON' THEN COALESCE("Ton", 0)
                    WHEN UPPER(p_uom) = 'PALLET' THEN COALESCE("Pallet", 0)
                    ELSE 0
                END
            ELSE 0
        END
    ) AS total_volume_inbound,

    SUM(
        CASE
            WHEN direction = 'OUTBOUND' THEN
                CASE
                    WHEN UPPER(p_uom) = 'CSE' THEN COALESCE("CSE", 0)
                    WHEN UPPER(p_uom) = 'PCE' THEN COALESCE("PCE", 0)
                    WHEN UPPER(p_uom) = 'CBM' THEN COALESCE("CBM", 0)
                    WHEN UPPER(p_uom) = 'TON' THEN COALESCE("Ton", 0)
                    WHEN UPPER(p_uom) = 'PALLET' THEN COALESCE("Pallet", 0)
                    ELSE 0
                END
            ELSE 0
        END
    ) AS total_volume_outbound,

    COUNT(DISTINCT orders) AS so_don_do

FROM reporting_schema.mv_test_movement_transaction
CROSS JOIN constants
WHERE
    (p_warehouse = 'ALL' OR warehouse = p_warehouse)
    AND transaction_date::DATE >= p_from::DATE
    AND transaction_date::DATE <= p_to::DATE
    AND (p_activity = 'ALL' OR activity = p_activity)
    AND direction IN ('INBOUND', 'OUTBOUND')
GROUP BY UPPER(p_uom);
```

**ClickHouse SQL:**

```sql
SELECT
    SUM(
        CASE
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CSE'                 THEN CSE
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'TON'                 THEN TON
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CBM'                 THEN CBM
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'PALLET'         THEN PALLET
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'DO'                 THEN orders
            ELSE 0
        END
    ) AS total_inbound,

    SUM(
        CASE
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CSE'                 THEN CSE
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'TON'                 THEN TON
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CBM'                 THEN CBM
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'PALLET'         THEN PALLET
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'DO'                 THEN orders
            ELSE 0
        END
    ) AS total_outbound,
    
     SUM(
        CASE
            WHEN direction = 'OUTBOUND' AND activity = 'Print DO' THEN orders
            ELSE 0
        END
    ) AS total_print_do_orders
FROM analytics_workspace.mv_movement_transaction AS t
WHERE 1=1


-- Warehouse
AND if(
    arraySort([{{warehouse}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.warehouse IN ({{warehouse}})
)


-- Activity
AND if(
    arraySort([{{activity}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_activity
    ),
    1 = 1,
    t.activity IN ({{activity}})
)

/*
-- TYPE
AND if(
    arraySort([{{type}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_type_movement_transaction
    ),
    1 = 1,
    t.category_converted IN ({{type}})
)
*/


    -- Date filter (fix robust)
AND (
    toDateTime(
    CASE
        WHEN {{date_type}} = 'DATERECEIVED'
            THEN t.transaction_date
        WHEN {{date_type}} = 'ACTUALSHIPDATE'
            THEN t.transaction_date
/*
        WHEN {{date_type}} = 'Ngày tạo lệnh pick hàng'
            THEN t.pick_date
*/
    END)
    BETWEEN toDateTime(coalesce({{from_date}}, '1900-01-01'))
        AND toDateTime(coalesce({{to_date}}, '2999-12-31'))
)


    AND direction IN ('INBOUND', 'OUTBOUND')
```

### Tổng Volume Outbound `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT
        'ALL'::VARCHAR AS p_warehouse,
        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,
        'CSE'::VARCHAR AS p_uom,
        'ALL'::VARCHAR AS p_activity
)
SELECT
    UPPER(p_uom) AS uom,

    SUM(
        CASE
            WHEN direction = 'INBOUND' THEN
                CASE
                    WHEN UPPER(p_uom) = 'CSE' THEN COALESCE("CSE", 0)
                    WHEN UPPER(p_uom) = 'PCE' THEN COALESCE("PCE", 0)
                    WHEN UPPER(p_uom) = 'CBM' THEN COALESCE("CBM", 0)
                    WHEN UPPER(p_uom) = 'TON' THEN COALESCE("Ton", 0)
                    WHEN UPPER(p_uom) = 'PALLET' THEN COALESCE("Pallet", 0)
                    ELSE 0
                END
            ELSE 0
        END
    ) AS total_volume_inbound,

    SUM(
        CASE
            WHEN direction = 'OUTBOUND' THEN
                CASE
                    WHEN UPPER(p_uom) = 'CSE' THEN COALESCE("CSE", 0)
                    WHEN UPPER(p_uom) = 'PCE' THEN COALESCE("PCE", 0)
                    WHEN UPPER(p_uom) = 'CBM' THEN COALESCE("CBM", 0)
                    WHEN UPPER(p_uom) = 'TON' THEN COALESCE("Ton", 0)
                    WHEN UPPER(p_uom) = 'PALLET' THEN COALESCE("Pallet", 0)
                    ELSE 0
                END
            ELSE 0
        END
    ) AS total_volume_outbound,

    COUNT(DISTINCT orders) AS so_don_do

FROM reporting_schema.mv_test_movement_transaction
CROSS JOIN constants
WHERE
    (p_warehouse = 'ALL' OR warehouse = p_warehouse)
    AND transaction_date::DATE >= p_from::DATE
    AND transaction_date::DATE <= p_to::DATE
    AND (p_activity = 'ALL' OR activity = p_activity)
    AND direction IN ('INBOUND', 'OUTBOUND')
GROUP BY UPPER(p_uom);
```

**ClickHouse SQL:**

```sql
SELECT
    SUM(
        CASE
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CSE'                 THEN CSE
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'TON'                 THEN TON
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CBM'                 THEN CBM
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'PALLET'         THEN PALLET
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'DO'                 THEN orders
            ELSE 0
        END
    ) AS total_inbound,

    SUM(
        CASE
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CSE'                 THEN CSE
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'TON'                 THEN TON
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CBM'                 THEN CBM
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'PALLET'         THEN PALLET
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'DO'                 THEN orders
            ELSE 0
        END
    ) AS total_outbound,
    
     SUM(
        CASE
            WHEN direction = 'OUTBOUND' AND activity = 'Print DO' THEN orders
            ELSE 0
        END
    ) AS total_print_do_orders
FROM analytics_workspace.mv_movement_transaction AS t
WHERE 1=1


-- Warehouse
AND if(
    arraySort([{{warehouse}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.warehouse IN ({{warehouse}})
)


-- Activity
AND if(
    arraySort([{{activity}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_activity
    ),
    1 = 1,
    t.activity IN ({{activity}})
)

/*
-- TYPE
AND if(
    arraySort([{{type}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_type_movement_transaction
    ),
    1 = 1,
    t.category_converted IN ({{type}})
)
*/


    -- Date filter (fix robust)
AND (
    toDateTime(
    CASE
        WHEN {{date_type}} = 'DATERECEIVED'
            THEN t.transaction_date
        WHEN {{date_type}} = 'ACTUALSHIPDATE'
            THEN t.transaction_date
/*
        WHEN {{date_type}} = 'Ngày tạo lệnh pick hàng'
            THEN t.pick_date
*/
    END)
    BETWEEN toDateTime(coalesce({{from_date}}, '1900-01-01'))
        AND toDateTime(coalesce({{to_date}}, '2999-12-31'))
)


    AND direction IN ('INBOUND', 'OUTBOUND')
```

### Print DO — Tổng đơn `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT
        'ALL'::VARCHAR AS p_warehouse,
        '2026-01-01 00:00:00'::TIMESTAMP AS p_from,
        '2026-01-31 23:59:59'::TIMESTAMP AS p_to
)
select SUM(orders) AS so_don_do

FROM reporting_schema.mv_test_movement_transaction
CROSS JOIN constants
WHERE
    (p_warehouse = 'ALL' OR warehouse = p_warehouse)
    AND transaction_date::DATE >= p_from::DATE
    AND transaction_date::DATE <= p_to::DATE
    AND activity = 'Print DO';
```

**ClickHouse SQL:**

```sql
SELECT
    SUM(
        CASE
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CSE'                 THEN CSE
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'TON'                 THEN TON
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CBM'                 THEN CBM
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'PALLET'         THEN PALLET
            WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'DO'                 THEN orders
            ELSE 0
        END
    ) AS total_inbound,

    SUM(
        CASE
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CSE'                 THEN CSE
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'TON'                 THEN TON
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CBM'                 THEN CBM
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'PALLET'         THEN PALLET
            WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'DO'                 THEN orders
            ELSE 0
        END
    ) AS total_outbound,
    
     SUM(
        CASE
            WHEN direction = 'OUTBOUND' AND activity = 'Print DO' THEN orders
            ELSE 0
        END
    ) AS total_print_do_orders
FROM analytics_workspace.mv_movement_transaction AS t
WHERE 1=1


-- Warehouse
AND if(
    arraySort([{{warehouse}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.warehouse IN ({{warehouse}})
)


-- Activity
AND if(
    arraySort([{{activity}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_activity
    ),
    1 = 1,
    t.activity IN ({{activity}})
)

/*
-- TYPE
AND if(
    arraySort([{{type}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_type_movement_transaction
    ),
    1 = 1,
    t.category_converted IN ({{type}})
)
*/


    -- Date filter (fix robust)
AND (
    toDateTime(
    CASE
        WHEN {{date_type}} = 'DATERECEIVED'
            THEN t.transaction_date
        WHEN {{date_type}} = 'ACTUALSHIPDATE'
            THEN t.transaction_date
/*
        WHEN {{date_type}} = 'Ngày tạo lệnh pick hàng'
            THEN t.pick_date
*/
    END)
    BETWEEN toDateTime(coalesce({{from_date}}, '1900-01-01'))
        AND toDateTime(coalesce({{to_date}}, '2999-12-31'))
)


    AND direction IN ('INBOUND', 'OUTBOUND')
```

### Xu hướng CBM & Pallet theo ngày `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT 
        'ALL'::VARCHAR AS p_warehouse,
        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,
        'CSE'::VARCHAR AS p_uom,
        'ALL'::VARCHAR AS p_activity
)
SELECT
    transaction_date,
    UPPER(p_uom) AS uom,
    SUM(
        CASE
            WHEN UPPER(p_uom) = 'CSE' THEN COALESCE("CSE", 0)
            WHEN UPPER(p_uom) = 'PCE' THEN COALESCE("PCE", 0)
            WHEN UPPER(p_uom) = 'CBM' THEN COALESCE("CBM", 0)
            WHEN UPPER(p_uom) = 'TON' THEN COALESCE("Ton", 0)
            WHEN UPPER(p_uom) = 'PALLET' THEN COALESCE("Pallet", 0)
            ELSE 0
        END
    ) AS total_volume
FROM reporting_schema.mv_test_movement_transaction
CROSS JOIN constants
WHERE 
    -- Filter Warehouse
    (p_warehouse = 'ALL' OR warehouse = p_warehouse)
    
    -- Filter Date Range
    AND transaction_date::DATE >= p_from::DATE 
    AND transaction_date::DATE <= p_to::DATE

    -- Filter Activity
    AND (p_activity = 'ALL' OR activity = p_activity)

    -- Chỉ lấy nhập/xuất
    AND direction IN ('INBOUND', 'OUTBOUND')
GROUP BY 
    transaction_date,
    UPPER(p_uom)
ORDER BY 
    transaction_date ASC;
```

**ClickHouse SQL:**

```sql
SELECT
  toDate(transaction_date) AS transaction_date,
      SUM(CASE
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CSE'    THEN coalesce(`CSE`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'PCE'    THEN coalesce(`PCE`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CBM'    THEN coalesce(`CBM`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'TON'    THEN coalesce(`Ton`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'PALLET' THEN coalesce(`Pallet`, 0)
          ELSE 0 
          END) AS total_inbound_volume --inbound

    , SUM(CASE
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CSE'    THEN coalesce(`CSE`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'PCE'    THEN coalesce(`PCE`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CBM'    THEN coalesce(`CBM`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'TON'    THEN coalesce(`Ton`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'PALLET' THEN coalesce(`Pallet`, 0)
          ELSE 0
          END) AS total_outbound_volume --outbound

FROM analytics_workspace.mv_movement_transaction AS t
WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{warehouse}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.warehouse IN ({{warehouse}})
)


-- Activity
AND if(
    arraySort([{{activity}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_activity
    ),
    1 = 1,
    t.activity IN ({{activity}})
)

/*
-- TYPE
AND if(
    arraySort([{{type}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_type_movement_transaction
    ),
    1 = 1,
    t.category_converted IN ({{type}})
)
*/


    -- Date filter (fix robust)
AND (
    toDateTime(
    CASE
        WHEN {{date_type}} = 'DATERECEIVED'
            THEN t.transaction_date
        WHEN {{date_type}} = 'ACTUALSHIPDATE'
            THEN t.transaction_date
/*
        WHEN {{date_type}} = 'Ngày tạo lệnh pick hàng'
            THEN t.pick_date
*/
    END)
    BETWEEN toDateTime(coalesce({{from_date}}, '1900-01-01'))
        AND toDateTime(coalesce({{to_date}}, '2999-12-31'))
)

GROUP BY transaction_date
ORDER BY transaction_date
```

### Inbound vs Outbound `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT 
        'ALL'::VARCHAR AS p_warehouse,
        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,
        'CSE'::VARCHAR AS p_uom,
        'ALL'::VARCHAR AS p_activity
)
SELECT
    transaction_date,
    UPPER(p_uom) AS uom,
    SUM(
        CASE 
            WHEN direction = 'INBOUND' THEN
                CASE
                    WHEN UPPER(p_uom) = 'CSE' THEN COALESCE("CSE", 0)
                    WHEN UPPER(p_uom) = 'PCE' THEN COALESCE("PCE", 0)
                    WHEN UPPER(p_uom) = 'CBM' THEN COALESCE("CBM", 0)
                    WHEN UPPER(p_uom) = 'TON' THEN COALESCE("Ton", 0)
                    WHEN UPPER(p_uom) = 'PALLET' THEN COALESCE("Pallet", 0)
                    ELSE 0
                END
            ELSE 0
        END
    ) AS inbound_volume,
    SUM(
        CASE 
            WHEN direction = 'OUTBOUND' THEN
                CASE
                    WHEN UPPER(p_uom) = 'CSE' THEN COALESCE("CSE", 0)
                    WHEN UPPER(p_uom) = 'PCE' THEN COALESCE("PCE", 0)
                    WHEN UPPER(p_uom) = 'CBM' THEN COALESCE("CBM", 0)
                    WHEN UPPER(p_uom) = 'TON' THEN COALESCE("Ton", 0)
                    WHEN UPPER(p_uom) = 'PALLET' THEN COALESCE("Pallet", 0)
                    ELSE 0
                END
            ELSE 0
        END
    ) AS outbound_volume
FROM reporting_schema.mv_test_movement_transaction
CROSS JOIN constants
WHERE 
    (p_warehouse = 'ALL' OR warehouse = p_warehouse)
    AND transaction_date::DATE >= p_from::DATE
    AND transaction_date::DATE <= p_to::DATE
    AND (p_activity = 'ALL' OR activity = p_activity)
    AND direction IN ('INBOUND', 'OUTBOUND')
GROUP BY 
    transaction_date,
    UPPER(p_uom)
ORDER BY 
    transaction_date;
```

**ClickHouse SQL:**

```sql
SELECT
  toDate(transaction_date) AS transaction_date,
      SUM(CASE
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CSE'    THEN coalesce(`CSE`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'PCE'    THEN coalesce(`PCE`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CBM'    THEN coalesce(`CBM`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'TON'    THEN coalesce(`Ton`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'PALLET' THEN coalesce(`Pallet`, 0)
          ELSE 0 
          END) AS total_inbound_volume --inbound

    , SUM(CASE
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CSE'    THEN coalesce(`CSE`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'PCE'    THEN coalesce(`PCE`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CBM'    THEN coalesce(`CBM`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'TON'    THEN coalesce(`Ton`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'PALLET' THEN coalesce(`Pallet`, 0)
          ELSE 0
          END) AS total_outbound_volume --outbound

FROM analytics_workspace.mv_movement_transaction AS t
WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{warehouse}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.warehouse IN ({{warehouse}})
)


-- Activity
AND if(
    arraySort([{{activity}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_activity
    ),
    1 = 1,
    t.activity IN ({{activity}})
)

/*
-- TYPE
AND if(
    arraySort([{{type}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_type_movement_transaction
    ),
    1 = 1,
    t.category_converted IN ({{type}})
)
*/


    -- Date filter (fix robust)
AND (
    toDateTime(
    CASE
        WHEN {{date_type}} = 'DATERECEIVED'
            THEN t.transaction_date
        WHEN {{date_type}} = 'ACTUALSHIPDATE'
            THEN t.transaction_date
/*
        WHEN {{date_type}} = 'Ngày tạo lệnh pick hàng'
            THEN t.pick_date
*/
    END)
    BETWEEN toDateTime(coalesce({{from_date}}, '1900-01-01'))
        AND toDateTime(coalesce({{to_date}}, '2999-12-31'))
)

GROUP BY transaction_date
ORDER BY transaction_date
```

### So sánh khối lượng theo kho

dòng 20 trong file EDIT UX/UI `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT 
        'ALL'::VARCHAR AS p_warehouse,
        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,
        'CSE'::VARCHAR AS p_uom,
        'ALL'::VARCHAR AS p_activity
)
SELECT 
    warehouse,
    UPPER(p_uom) AS uom,
    SUM(
        CASE
            WHEN UPPER(p_uom) = 'CSE' THEN COALESCE("CSE", 0)
            WHEN UPPER(p_uom) = 'PCE' THEN COALESCE("PCE", 0)
            WHEN UPPER(p_uom) = 'CBM' THEN COALESCE("CBM", 0)
            WHEN UPPER(p_uom) = 'TON' THEN COALESCE("Ton", 0)
            WHEN UPPER(p_uom) = 'PALLET' THEN COALESCE("Pallet", 0)
            ELSE 0
        END
    ) AS total_volume
FROM reporting_schema.mv_test_movement_transaction
CROSS JOIN constants
WHERE 
    -- Filter warehouse
    (p_warehouse = 'ALL' OR warehouse = p_warehouse)
    
    -- Filter date range
    AND transaction_date::DATE >= p_from::DATE
    AND transaction_date::DATE <= p_to::DATE

    -- Filter activity
    AND (p_activity = 'ALL' OR activity = p_activity)

    -- Chỉ lấy nhập/xuất
    AND direction IN ('INBOUND', 'OUTBOUND')
GROUP BY 
    warehouse,
    UPPER(p_uom)
ORDER BY 
    total_volume DESC;
```

**ClickHouse SQL:**

```sql
SELECT
  warehouse,
      SUM(CASE
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CSE'    THEN coalesce(`CSE`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'PCE'    THEN coalesce(`PCE`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CBM'    THEN coalesce(`CBM`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'TON'    THEN coalesce(`Ton`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'PALLET' THEN coalesce(`Pallet`, 0)
                    ELSE 0
                END
    ) AS total_inbound_volume --inbound


       , SUM(CASE
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CSE'    THEN coalesce(`CSE`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'PCE'    THEN coalesce(`PCE`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CBM'    THEN coalesce(`CBM`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'TON'    THEN coalesce(`Ton`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'PALLET' THEN coalesce(`Pallet`, 0)
                    ELSE 0
                END
    ) AS total_outbound_volume --outbound

FROM analytics_workspace.mv_movement_transaction AS t
WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{warehouse}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.warehouse IN ({{warehouse}})
)


-- Activity
AND if(
    arraySort([{{activity}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_activity
    ),
    1 = 1,
    t.activity IN ({{activity}})
)

/*
-- TYPE
AND if(
    arraySort([{{type}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_type_movement_transaction
    ),
    1 = 1,
    t.category_converted IN ({{type}})
)
*/


    -- Date filter (fix robust)
AND (
    toDateTime(
    CASE
        WHEN {{date_type}} = 'DATERECEIVED'
            THEN t.transaction_date
        WHEN {{date_type}} = 'ACTUALSHIPDATE'
            THEN t.transaction_date
/*
        WHEN {{date_type}} = 'Ngày tạo lệnh pick hàng'
            THEN t.pick_date
*/
    END)
    BETWEEN toDateTime(coalesce({{from_date}}, '1900-01-01'))
        AND toDateTime(coalesce({{to_date}}, '2999-12-31'))
)

GROUP BY warehouse
ORDER BY warehouse
```

### Movement Report Transaction (Table body — reportBody)

dòng 21 trong file EDIT UX/UI `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT 
        'ALL'::VARCHAR AS p_warehouse,
        'ALL'::VARCHAR AS p_date_type,
        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,
        'CSE'::VARCHAR AS p_uom,
        'ALL'::VARCHAR AS p_activity
)
SELECT *
FROM analytics_workspace.reporting_schema.mv_test_movement_transaction
CROSS JOIN constants
WHERE 
    (p_warehouse = 'ALL' OR warehouse = p_warehouse)
    AND transaction_date >= p_from::DATE 
    AND transaction_date <= p_to::DATE
    AND (p_activity = 'ALL' OR activity = p_activity)
    AND direction IN ('INBOUND', 'OUTBOUND')
ORDER BY 
    transaction_date DESC, 
    activity
```

**ClickHouse SQL:**

```sql
SELECT 
        transaction_date AS "Transaction date"
        , warehouse AS "Kho"
        , activity AS "Activity"
        , category_converted AS "Type"
        , uom AS "UOM"
        , PCE AS "PCE"
        , CBM AS "CBM"
        , Ton AS "Ton"
        , CSE AS "CSE"
        , Pallet AS "Pallet"
        , orders AS "Số lượng đơn DO"
FROM analytics_workspace.mv_movement_transaction AS t
WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{warehouse}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.warehouse IN ({{warehouse}})
)


-- Activity
AND if(
    arraySort([{{activity}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_activity
    ),
    1 = 1,
    t.activity IN ({{activity}})
)

/*
-- TYPE
AND if(
    arraySort([{{type}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_type_movement_transaction
    ),
    1 = 1,
    t.category_converted IN ({{type}})
)
*/


    -- Date filter (fix robust)
AND (
    toDateTime(
    CASE
        WHEN {{date_type}} = 'DATERECEIVED'
            THEN t.transaction_date
        WHEN {{date_type}} = 'ACTUALSHIPDATE'
            THEN t.transaction_date
/*
        WHEN {{date_type}} = 'Ngày tạo lệnh pick hàng'
            THEN t.pick_date
*/
    END)
    BETWEEN toDateTime(coalesce({{from_date}}, '1900-01-01'))
        AND toDateTime(coalesce({{to_date}}, '2999-12-31'))
)

ORDER BY transaction_date DESC
```

### Khối lượng theo activities

dòng 19 trong file EDIT UX/UI `Đã sửa`

**Redshift SQL:**

```sql
WITH constants AS (
    SELECT 
        'ALL'::VARCHAR AS p_warehouse,
        'ALL'::VARCHAR AS p_date_type,
        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,
        'CSE'::VARCHAR AS p_uom,
        'ALL'::VARCHAR AS p_activity
)
SELECT *
FROM analytics_workspace.reporting_schema.mv_test_movement_transaction
CROSS JOIN constants
WHERE 
    (p_warehouse = 'ALL' OR warehouse = p_warehouse)
    AND transaction_date >= p_from::DATE 
    AND transaction_date <= p_to::DATE
    AND (p_activity = 'ALL' OR activity = p_activity)
    AND direction IN ('INBOUND', 'OUTBOUND')
ORDER BY 
    transaction_date DESC, 
    activity
```

**ClickHouse SQL:**

```sql
SELECT
  warehouse,
      SUM(CASE
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CSE'    THEN coalesce(`CSE`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'PCE'    THEN coalesce(`PCE`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'CBM'    THEN coalesce(`CBM`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'TON'    THEN coalesce(`Ton`, 0)
WHEN direction = 'INBOUND' AND activity <> 'Phí quấn màng co / Pallet shrink wrap' AND upper({{uom}}) = 'PALLET' THEN coalesce(`Pallet`, 0)
                    ELSE 0
                END
    ) AS total_inbound_volume --inbound


       , SUM(CASE
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CSE'    THEN coalesce(`CSE`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'PCE'    THEN coalesce(`PCE`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'CBM'    THEN coalesce(`CBM`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'TON'    THEN coalesce(`Ton`, 0)
WHEN direction = 'OUTBOUND' AND activity <> 'Print DO' AND upper({{uom}}) = 'PALLET' THEN coalesce(`Pallet`, 0)
                    ELSE 0
                END
    ) AS total_outbound_volume --outbound

FROM analytics_workspace.mv_movement_transaction AS t
WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{warehouse}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.warehouse IN ({{warehouse}})
)


-- Activity
AND if(
    arraySort([{{activity}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_activity
    ),
    1 = 1,
    t.activity IN ({{activity}})
)

/*
-- TYPE
AND if(
    arraySort([{{type}}]) = (
        SELECT arraySort(groupArray(DISTINCT code)) FROM analytics_workspace.mv_filter_type_movement_transaction
    ),
    1 = 1,
    t.category_converted IN ({{type}})
)
*/


    -- Date filter (fix robust)
AND (
    toDateTime(
    CASE
        WHEN {{date_type}} = 'DATERECEIVED'
            THEN t.transaction_date
        WHEN {{date_type}} = 'ACTUALSHIPDATE'
            THEN t.transaction_date
/*
        WHEN {{date_type}} = 'Ngày tạo lệnh pick hàng'
            THEN t.pick_date
*/
    END)
    BETWEEN toDateTime(coalesce({{from_date}}, '1900-01-01'))
        AND toDateTime(coalesce({{to_date}}, '2999-12-31'))
)

GROUP BY activity 
ORDER BY activity
```

---

## Flash Report

### L2 Điểm nóng — Kho

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT t.*
    FROM analytics_workspace.mv_flash_and_drop_report t
    WHERE 1 = 1

    -- Date filter
    AND (
        toDate(t.ngay_gi)
        BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
            AND toDate(coalesce({{to_date}},   '2999-12-31'))
    )
)

SELECT 
whseid AS name, 

--    SUM(CASE WHEN trang_thai_don_do = 'Kế hoạch xuất' THEN value_uom ELSE 0 END) AS total_volume,
--    SUM(CASE WHEN trang_thai_don_do = 'Đã vận chuyển' THEN value_uom ELSE 0 END) AS done_volume,
--    SUM(CASE WHEN trang_thai_don_do NOT IN ('Kế hoạch xuất', 'Đã vận chuyển') THEN value_uom ELSE 0 END) AS pending_volume,
    -- bonus: % done
    round(
        SUM(CASE WHEN trang_thai_don_do = 'Đã vận chuyển' THEN value_uom ELSE 0 END)
        / nullIf(SUM(CASE WHEN trang_thai_don_do = 'Kế hoạch xuất' THEN value_uom ELSE 0 END), 0) * 100,
        2
    ) AS pct_done

FROM (

    -- 1. Kế hoạch xuất: original từ TẤT CẢ (flash + dropped/hủy)
    SELECT 1 AS sort_order,
        whseid,
        'Kế hoạch xuất' AS trang_thai_don_do,
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END AS value_uom
    FROM base
    GROUP BY whseid

    UNION ALL

    -- 2. Chưa xuất kho: original
    SELECT 2, whseid, 'Chưa xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Chưa xuất kho'
    GROUP BY whseid

    UNION ALL

    -- 3. Đang xuất kho: shipped
    SELECT 3, whseid, 'Đang xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang xuất kho'
    GROUP BY whseid

    UNION ALL

    -- 4. Đã xuất kho: shipped
    SELECT 4, whseid, 'Đã xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã xuất kho'
    GROUP BY whseid

    UNION ALL

    -- 5. Đang vận chuyển: shipped
    SELECT 5, whseid, 'Đang vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang vận chuyển'
    GROUP BY whseid

    UNION ALL

    -- 6. Đã vận chuyển: san_luong_giao (BBGN/STM)
    SELECT 6, whseid, 'Đã vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(san_luong_giao_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(san_luong_giao_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(san_luong_giao_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã vận chuyển'
    GROUP BY whseid

)
GROUP BY whseid
HAVING pct_done < 85
ORDER BY whseid;
```

### L2 Điểm nóng — Drop + Lý do

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT t.*
    FROM analytics_workspace.mv_dropped_report t
    WHERE 1 = 1

    -- Date filter
    AND (
        toDate(t.ngay_gi)
        BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
            AND toDate(coalesce({{to_date}},   '2999-12-31'))
    )
)

SELECT
    sort_order,
    ly_do_rot_don,
    pallet,
    ton,
    cbm,
    cse
FROM (
    -- 1. Tổng ĐƠN RỚT (số lớn phía trên card)
    SELECT
        0                                                       AS sort_order,
        'TỔNG ĐƠN RỚT'                                          AS ly_do_rot_don,
        toFloat64(SUM(coalesce(original_pl,  0)))               AS pallet,
        toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0      AS ton,
        toFloat64(SUM(coalesce(original_cbm, 0)))               AS cbm,
        toFloat64(SUM(coalesce(original_cse, 0)))               AS cse
    FROM base

    UNION ALL

    -- 2. Break-down theo lý do rớt đơn (remark_2) - số nhỏ phía dưới
    SELECT
        1                                                       AS sort_order,
        coalesce(nullIf(trimBoth(remark_2), ''), 'Không điền lý do rớt') AS ly_do_rot_don,
        toFloat64(SUM(coalesce(original_pl,  0)))               AS pallet,
        toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0      AS ton,
        toFloat64(SUM(coalesce(original_cbm, 0)))               AS cbm,
        toFloat64(SUM(coalesce(original_cse, 0)))               AS cse
    FROM base
    GROUP BY coalesce(nullIf(trimBoth(remark_2), ''), 'Không điền lý do rớt')
)
ORDER BY sort_order, cse DESC, ly_do_rot_don
```

### L2 Điểm nóng — Khu vực

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT t.*
    FROM analytics_workspace.mv_flash_and_drop_report t
    WHERE 1 = 1

    -- Date filter
    AND (
        toDate(t.ngay_gi)
        BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
            AND toDate(coalesce({{to_date}},   '2999-12-31'))
    )
)


SELECT 
delivery_area AS name,
--    SUM(CASE WHEN trang_thai_don_do = 'Kế hoạch xuất' THEN value_uom ELSE 0 END) AS total_volume,
--    SUM(CASE WHEN trang_thai_don_do = 'Đã vận chuyển' THEN value_uom ELSE 0 END) AS done_volume,
--    SUM(CASE WHEN trang_thai_don_do NOT IN ('Kế hoạch xuất', 'Đã vận chuyển') THEN value_uom ELSE 0 END) AS pending_volume,
    -- bonus: % done
    round(
        SUM(CASE WHEN trang_thai_don_do = 'Đã vận chuyển' THEN value_uom ELSE 0 END)
        / nullIf(SUM(CASE WHEN trang_thai_don_do = 'Kế hoạch xuất' THEN value_uom ELSE 0 END), 0) * 100,
        2
    ) AS pct_done

FROM (

    -- 1. Kế hoạch xuất: original từ TẤT CẢ (flash + dropped/hủy)
    SELECT 1 AS sort_order,
        coalesce(khu_vuc_doi_xe, 'Unclassified') AS delivery_area,
        'Kế hoạch xuất' AS trang_thai_don_do,
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END AS value_uom
    FROM base
    GROUP BY delivery_area

    UNION ALL

    -- 2. Chưa xuất kho: original
    SELECT 2,
        coalesce(khu_vuc_doi_xe, 'Unclassified'),
        'Chưa xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Chưa xuất kho'
    GROUP BY coalesce(khu_vuc_doi_xe, 'Unclassified')

    UNION ALL

    -- 3. Đang xuất kho: shipped
    SELECT 3,
        coalesce(khu_vuc_doi_xe, 'Unclassified'),
        'Đang xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang xuất kho'
    GROUP BY coalesce(khu_vuc_doi_xe, 'Unclassified')

    UNION ALL

    -- 4. Đã xuất kho: shipped
    SELECT 4,
        coalesce(khu_vuc_doi_xe, 'Unclassified'),
        'Đã xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã xuất kho'
    GROUP BY coalesce(khu_vuc_doi_xe, 'Unclassified')

    UNION ALL

    -- 5. Đang vận chuyển: shipped
    SELECT 5,
        coalesce(khu_vuc_doi_xe, 'Unclassified'),
        'Đang vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang vận chuyển'
    GROUP BY coalesce(khu_vuc_doi_xe, 'Unclassified')

    UNION ALL

    -- 6. Đã vận chuyển: san_luong_giao (BBGN/STM)
    SELECT 6,
        coalesce(khu_vuc_doi_xe, 'Unclassified'),
        'Đã vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(san_luong_giao_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(san_luong_giao_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(san_luong_giao_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã vận chuyển'
    GROUP BY coalesce(khu_vuc_doi_xe, 'Unclassified')

)
GROUP BY delivery_area
HAVING pct_done < 95
ORDER BY pct_done;
```

### L4 Trend tỷ lệ rớt 14 ngày

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*,
        toDate(
            CASE
                WHEN 'Ngày GI' = 'Ngày GI'             THEN t.ngay_gi
            END
        ) AS filter_date
    FROM analytics_workspace.mv_flash_and_drop_report t
    WHERE 1 = 1
      -- Date filter (group date sẽ dùng cùng cột đã chọn)
      AND toDate(t.ngay_gi) BETWEEN (today() - 13) AND today()

      -- Sales Channel
      AND if(
          arraySort([{{group_name}}]) = (
              SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
          ),
          1 = 1,
          t.group_name IN ({{group_name}})
      )

      -- Warehouse
      AND if(
          arraySort([{{whseid}}]) = (
              SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
          ),
          1 = 1,
          t.whseid IN ({{whseid}})
      )

      -- Brand
      AND if(
          arraySort([{{brand}}]) = (
              SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
          ),
          1 = 1,
          coalesce(t.brand, 'Unclassified') IN ({{brand}})
      )

      -- Cargo Group
      AND if(
          arraySort([{{group_of_cargo}}]) = (
              SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
          ),
          1 = 1,
          coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
      )

      -- Area
      AND if(
          arraySort([{{region}}]) = (
              SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
          ),
          1 = 1,
          t.khu_vuc_doi_xe IN ({{region}})
      )
),

daily AS (
    SELECT
        b.filter_date                                                              AS date,
        SUM(coalesce(b.original_cse, 0))                                           AS total_plan,
        SUM(if(b.e2e_label = 'Kế hoạch hủy', coalesce(b.original_cse, 0), 0))      AS total_failed
    FROM base b
    WHERE b.filter_date IS NOT NULL
    GROUP BY b.filter_date
),

-- Benchmark scalar: window CỐ ĐỊNH today()-29 .. today(), không phụ thuộc {{from_date}}/{{to_date}}.
-- Vẫn dùng cùng {{date_type}} & dim filters để so sánh apples-to-apples với line chart.

avg30 AS (
    SELECT
        if(SUM(coalesce(t.original_cse, 0)) = 0, 0,
           100.0
             * SUMIf(coalesce(t.original_cse, 0), t.e2e_label = 'Kế hoạch hủy')
             / SUM(coalesce(t.original_cse, 0))
        ) AS drop_rate_30d_avg
    FROM analytics_workspace.mv_flash_and_drop_report t
    WHERE 1 = 1
      AND toDate(
              CASE
                  WHEN {{date_type}} = 'Ngày GI'             THEN t.ngay_gi
              END
          ) BETWEEN (today() - 29) AND today()

      -- Sales Channel
      AND if(
          arraySort([{{group_name}}]) = (
              SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
          ),
          1 = 1,
          t.group_name IN ({{group_name}})
      )

      -- Warehouse
      AND if(
          arraySort([{{whseid}}]) = (
              SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
          ),
          1 = 1,
          t.whseid IN ({{whseid}})
      )

      -- Brand
      AND if(
          arraySort([{{brand}}]) = (
              SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
          ),
          1 = 1,
          coalesce(t.brand, 'Unclassified') IN ({{brand}})
      )

      -- Cargo Group
      AND if(
          arraySort([{{group_of_cargo}}]) = (
              SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
          ),
          1 = 1,
          coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
      )

      -- Area
      AND if(
          arraySort([{{region}}]) = (
              SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
          ),
          1 = 1,
          t.khu_vuc_doi_xe IN ({{region}})
      )
)

--Required: date, total_plan, total_failed, drop_rate, drop_rate_30d_avg
SELECT
    d.date                                                                     AS date,
    round(d.total_plan,   2)                                                   AS total_plan,
    round(d.total_failed, 2)                                                   AS total_failed,
    round(if(d.total_plan = 0, 0, 100.0 * d.total_failed / d.total_plan), 2)   AS drop_rate,
    round(a.drop_rate_30d_avg, 2)                                              AS drop_rate_30d_avg
FROM daily d
CROSS JOIN avg30 a
ORDER BY d.date;
```

### Tổng Volume `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter Date Type + Date Range
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )

        -- Filter Sales Channel
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Brand
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Delivery Area
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)

SELECT
    COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,
    CASE
        WHEN p.p_uom = 'cse' THEN SUM(COALESCE(b.original_cse, 0))
        WHEN p.p_uom = 'ton' THEN SUM(COALESCE(b.original_kg, 0)) / 1000.0
        WHEN p.p_uom = 'cbm' THEN SUM(COALESCE(b.original_cbm, 0))
        WHEN p.p_uom = 'pallet' THEN SUM(COALESCE(b.original_pl, 0))
        WHEN p.p_uom = 'DO' THEN COUNT(DISTINCT b.so)
        ELSE SUM(COALESCE(b.original_cse, 0))
    END AS value_uom
FROM base b
CROSS JOIN params p
GROUP BY
    COALESCE(b.trang_thai_don_do, 'Unclassified'),
    p.p_uom
ORDER BY
    COALESCE(b.trang_thai_don_do, 'Unclassified');
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT t.*
    FROM analytics_workspace.mv_flash_and_drop_report t
    WHERE 1 = 1

    -- Date filter
    AND (
        toDate(
            CASE
                WHEN {{date_type}} = 'Ngày GI'             THEN t.delivery_date_1
                WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN t.etd_chuyen_gui_thau
                WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN t.eta_giao_hang_cho_npp
                WHEN {{date_type}} = 'Actual Ship Date'    THEN t.actual_ship_date
                WHEN {{date_type}} = 'ATA đơn'             THEN t.ata_den
            END
        )
        BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
            AND toDate(coalesce({{to_date}},   '2999-12-31'))
    )

    -- Sales Channel
    AND if(
        arraySort([{{group_name}}]) = (
            SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
        ),
        1 = 1,
        t.group_name IN ({{group_name}})
    )

    -- Warehouse
    AND if(
        arraySort([{{whseid}}]) = (
            SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
        ),
        1 = 1,
        t.whseid IN ({{whseid}})
    )

    -- Brand
    AND if(
        arraySort([{{brand}}]) = (
            SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
        ),
        1 = 1,
        coalesce(t.brand, 'Unclassified') IN ({{brand}})
    )

    -- Cargo Group
    AND if(
        arraySort([{{group_of_cargo}}]) = (
            SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
        ),
        1 = 1,
        coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
    )

    -- Area
    AND if(
        arraySort([{{region}}]) = (
            SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
        ),
        1 = 1,
        t.khu_vuc_doi_xe IN ({{region}})
    )
)

SELECT trang_thai_don_do, value_uom
FROM (

    -- 1. Kế hoạch xuất: original từ TẤT CẢ (flash + dropped/hủy)
    SELECT 1 AS sort_order, 'Kế hoạch xuất' AS trang_thai_don_do,
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END AS value_uom
    FROM base

    UNION ALL

    -- 2. Chưa xuất kho: original, status = New
    SELECT 2, 'Chưa xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Chưa xuất kho'

    UNION ALL

    -- 3. Đang xuất kho: shipped, status Allocated/PartAllocate/PartPick/Picked/PartShipped
    SELECT 3, 'Đang xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang xuất kho'

    UNION ALL

    -- 4. Đã xuất kho: shipped, ShipCompleted chưa lên xe (thoi_gian_di IS NULL)
    SELECT 4, 'Đã xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã xuất kho'

    UNION ALL

    -- 5. Đang vận chuyển: shipped, ShipCompleted + ATD (thoi_gian_di IS NOT NULL)
    SELECT 5, 'Đang vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang vận chuyển'

    UNION ALL

    -- 6. Đã vận chuyển: san_luong_giao (BBGN/STM), ShipCompleted + ATA IS NOT NULL
    SELECT 6, 'Đã vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(san_luong_giao_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(san_luong_giao_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(san_luong_giao_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã vận chuyển'

)
ORDER BY sort_order
```

### Chưa xuất kho `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter Date Type + Date Range
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )

        -- Filter Sales Channel
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Brand
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Delivery Area
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)

SELECT
    COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,
    CASE
        WHEN p.p_uom = 'cse' THEN SUM(COALESCE(b.original_cse, 0))
        WHEN p.p_uom = 'ton' THEN SUM(COALESCE(b.original_kg, 0)) / 1000.0
        WHEN p.p_uom = 'cbm' THEN SUM(COALESCE(b.original_cbm, 0))
        WHEN p.p_uom = 'pallet' THEN SUM(COALESCE(b.original_pl, 0))
        WHEN p.p_uom = 'DO' THEN COUNT(DISTINCT b.so)
        ELSE SUM(COALESCE(b.original_cse, 0))
    END AS value_uom
FROM base b
CROSS JOIN params p
GROUP BY
    COALESCE(b.trang_thai_don_do, 'Unclassified'),
    p.p_uom
ORDER BY
    COALESCE(b.trang_thai_don_do, 'Unclassified');
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT t.*
    FROM analytics_workspace.mv_flash_and_drop_report t
    WHERE 1 = 1

    -- Date filter
    AND (
        toDate(
            CASE
                WHEN {{date_type}} = 'Ngày GI'             THEN t.delivery_date_1
                WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN t.etd_chuyen_gui_thau
                WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN t.eta_giao_hang_cho_npp
                WHEN {{date_type}} = 'Actual Ship Date'    THEN t.actual_ship_date
                WHEN {{date_type}} = 'ATA đơn'             THEN t.ata_den
            END
        )
        BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
            AND toDate(coalesce({{to_date}},   '2999-12-31'))
    )

    -- Sales Channel
    AND if(
        arraySort([{{group_name}}]) = (
            SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
        ),
        1 = 1,
        t.group_name IN ({{group_name}})
    )

    -- Warehouse
    AND if(
        arraySort([{{whseid}}]) = (
            SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
        ),
        1 = 1,
        t.whseid IN ({{whseid}})
    )

    -- Brand
    AND if(
        arraySort([{{brand}}]) = (
            SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
        ),
        1 = 1,
        coalesce(t.brand, 'Unclassified') IN ({{brand}})
    )

    -- Cargo Group
    AND if(
        arraySort([{{group_of_cargo}}]) = (
            SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
        ),
        1 = 1,
        coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
    )

    -- Area
    AND if(
        arraySort([{{region}}]) = (
            SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
        ),
        1 = 1,
        t.khu_vuc_doi_xe IN ({{region}})
    )
)

SELECT trang_thai_don_do, value_uom
FROM (

    -- 1. Kế hoạch xuất: original từ TẤT CẢ (flash + dropped/hủy)
    SELECT 1 AS sort_order, 'Kế hoạch xuất' AS trang_thai_don_do,
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END AS value_uom
    FROM base

    UNION ALL

    -- 2. Chưa xuất kho: original, status = New
    SELECT 2, 'Chưa xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Chưa xuất kho'

    UNION ALL

    -- 3. Đang xuất kho: shipped, status Allocated/PartAllocate/PartPick/Picked/PartShipped
    SELECT 3, 'Đang xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang xuất kho'

    UNION ALL

    -- 4. Đã xuất kho: shipped, ShipCompleted chưa lên xe (thoi_gian_di IS NULL)
    SELECT 4, 'Đã xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã xuất kho'

    UNION ALL

    -- 5. Đang vận chuyển: shipped, ShipCompleted + ATD (thoi_gian_di IS NOT NULL)
    SELECT 5, 'Đang vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang vận chuyển'

    UNION ALL

    -- 6. Đã vận chuyển: san_luong_giao (BBGN/STM), ShipCompleted + ATA IS NOT NULL
    SELECT 6, 'Đã vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(san_luong_giao_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(san_luong_giao_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(san_luong_giao_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã vận chuyển'

)
ORDER BY sort_order
```

### Đang xuất kho `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter Date Type + Date Range
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )

        -- Filter Sales Channel
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Brand
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Delivery Area
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)

SELECT
    COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,
    CASE
        WHEN p.p_uom = 'cse' THEN SUM(COALESCE(b.original_cse, 0))
        WHEN p.p_uom = 'ton' THEN SUM(COALESCE(b.original_kg, 0)) / 1000.0
        WHEN p.p_uom = 'cbm' THEN SUM(COALESCE(b.original_cbm, 0))
        WHEN p.p_uom = 'pallet' THEN SUM(COALESCE(b.original_pl, 0))
        WHEN p.p_uom = 'DO' THEN COUNT(DISTINCT b.so)
        ELSE SUM(COALESCE(b.original_cse, 0))
    END AS value_uom
FROM base b
CROSS JOIN params p
GROUP BY
    COALESCE(b.trang_thai_don_do, 'Unclassified'),
    p.p_uom
ORDER BY
    COALESCE(b.trang_thai_don_do, 'Unclassified');
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT t.*
    FROM analytics_workspace.mv_flash_and_drop_report t
    WHERE 1 = 1

    -- Date filter
    AND (
        toDate(
            CASE
                WHEN {{date_type}} = 'Ngày GI'             THEN t.delivery_date_1
                WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN t.etd_chuyen_gui_thau
                WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN t.eta_giao_hang_cho_npp
                WHEN {{date_type}} = 'Actual Ship Date'    THEN t.actual_ship_date
                WHEN {{date_type}} = 'ATA đơn'             THEN t.ata_den
            END
        )
        BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
            AND toDate(coalesce({{to_date}},   '2999-12-31'))
    )

    -- Sales Channel
    AND if(
        arraySort([{{group_name}}]) = (
            SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
        ),
        1 = 1,
        t.group_name IN ({{group_name}})
    )

    -- Warehouse
    AND if(
        arraySort([{{whseid}}]) = (
            SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
        ),
        1 = 1,
        t.whseid IN ({{whseid}})
    )

    -- Brand
    AND if(
        arraySort([{{brand}}]) = (
            SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
        ),
        1 = 1,
        coalesce(t.brand, 'Unclassified') IN ({{brand}})
    )

    -- Cargo Group
    AND if(
        arraySort([{{group_of_cargo}}]) = (
            SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
        ),
        1 = 1,
        coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
    )

    -- Area
    AND if(
        arraySort([{{region}}]) = (
            SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
        ),
        1 = 1,
        t.khu_vuc_doi_xe IN ({{region}})
    )
)

SELECT trang_thai_don_do, value_uom
FROM (

    -- 1. Kế hoạch xuất: original từ TẤT CẢ (flash + dropped/hủy)
    SELECT 1 AS sort_order, 'Kế hoạch xuất' AS trang_thai_don_do,
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END AS value_uom
    FROM base

    UNION ALL

    -- 2. Chưa xuất kho: original, status = New
    SELECT 2, 'Chưa xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Chưa xuất kho'

    UNION ALL

    -- 3. Đang xuất kho: shipped, status Allocated/PartAllocate/PartPick/Picked/PartShipped
    SELECT 3, 'Đang xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang xuất kho'

    UNION ALL

    -- 4. Đã xuất kho: shipped, ShipCompleted chưa lên xe (thoi_gian_di IS NULL)
    SELECT 4, 'Đã xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã xuất kho'

    UNION ALL

    -- 5. Đang vận chuyển: shipped, ShipCompleted + ATD (thoi_gian_di IS NOT NULL)
    SELECT 5, 'Đang vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang vận chuyển'

    UNION ALL

    -- 6. Đã vận chuyển: san_luong_giao (BBGN/STM), ShipCompleted + ATA IS NOT NULL
    SELECT 6, 'Đã vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(san_luong_giao_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(san_luong_giao_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(san_luong_giao_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã vận chuyển'

)
ORDER BY sort_order
```

### Đã xuất kho `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter Date Type + Date Range
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )

        -- Filter Sales Channel
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Brand
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Delivery Area
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)

SELECT
    COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,
    CASE
        WHEN p.p_uom = 'cse' THEN SUM(COALESCE(b.original_cse, 0))
        WHEN p.p_uom = 'ton' THEN SUM(COALESCE(b.original_kg, 0)) / 1000.0
        WHEN p.p_uom = 'cbm' THEN SUM(COALESCE(b.original_cbm, 0))
        WHEN p.p_uom = 'pallet' THEN SUM(COALESCE(b.original_pl, 0))
        WHEN p.p_uom = 'DO' THEN COUNT(DISTINCT b.so)
        ELSE SUM(COALESCE(b.original_cse, 0))
    END AS value_uom
FROM base b
CROSS JOIN params p
GROUP BY
    COALESCE(b.trang_thai_don_do, 'Unclassified'),
    p.p_uom
ORDER BY
    COALESCE(b.trang_thai_don_do, 'Unclassified');
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT t.*
    FROM analytics_workspace.mv_flash_and_drop_report t
    WHERE 1 = 1

    -- Date filter
    AND (
        toDate(
            CASE
                WHEN {{date_type}} = 'Ngày GI'             THEN t.delivery_date_1
                WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN t.etd_chuyen_gui_thau
                WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN t.eta_giao_hang_cho_npp
                WHEN {{date_type}} = 'Actual Ship Date'    THEN t.actual_ship_date
                WHEN {{date_type}} = 'ATA đơn'             THEN t.ata_den
            END
        )
        BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
            AND toDate(coalesce({{to_date}},   '2999-12-31'))
    )

    -- Sales Channel
    AND if(
        arraySort([{{group_name}}]) = (
            SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
        ),
        1 = 1,
        t.group_name IN ({{group_name}})
    )

    -- Warehouse
    AND if(
        arraySort([{{whseid}}]) = (
            SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
        ),
        1 = 1,
        t.whseid IN ({{whseid}})
    )

    -- Brand
    AND if(
        arraySort([{{brand}}]) = (
            SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
        ),
        1 = 1,
        coalesce(t.brand, 'Unclassified') IN ({{brand}})
    )

    -- Cargo Group
    AND if(
        arraySort([{{group_of_cargo}}]) = (
            SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
        ),
        1 = 1,
        coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
    )

    -- Area
    AND if(
        arraySort([{{region}}]) = (
            SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
        ),
        1 = 1,
        t.khu_vuc_doi_xe IN ({{region}})
    )
)

SELECT trang_thai_don_do, value_uom
FROM (

    -- 1. Kế hoạch xuất: original từ TẤT CẢ (flash + dropped/hủy)
    SELECT 1 AS sort_order, 'Kế hoạch xuất' AS trang_thai_don_do,
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END AS value_uom
    FROM base

    UNION ALL

    -- 2. Chưa xuất kho: original, status = New
    SELECT 2, 'Chưa xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Chưa xuất kho'

    UNION ALL

    -- 3. Đang xuất kho: shipped, status Allocated/PartAllocate/PartPick/Picked/PartShipped
    SELECT 3, 'Đang xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang xuất kho'

    UNION ALL

    -- 4. Đã xuất kho: shipped, ShipCompleted chưa lên xe (thoi_gian_di IS NULL)
    SELECT 4, 'Đã xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã xuất kho'

    UNION ALL

    -- 5. Đang vận chuyển: shipped, ShipCompleted + ATD (thoi_gian_di IS NOT NULL)
    SELECT 5, 'Đang vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang vận chuyển'

    UNION ALL

    -- 6. Đã vận chuyển: san_luong_giao (BBGN/STM), ShipCompleted + ATA IS NOT NULL
    SELECT 6, 'Đã vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(san_luong_giao_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(san_luong_giao_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(san_luong_giao_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã vận chuyển'

)
ORDER BY sort_order
```

### Đang vận chuyển `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter Date Type + Date Range
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )

        -- Filter Sales Channel
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Brand
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Delivery Area
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)

SELECT
    COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,
    CASE
        WHEN p.p_uom = 'cse' THEN SUM(COALESCE(b.original_cse, 0))
        WHEN p.p_uom = 'ton' THEN SUM(COALESCE(b.original_kg, 0)) / 1000.0
        WHEN p.p_uom = 'cbm' THEN SUM(COALESCE(b.original_cbm, 0))
        WHEN p.p_uom = 'pallet' THEN SUM(COALESCE(b.original_pl, 0))
        WHEN p.p_uom = 'DO' THEN COUNT(DISTINCT b.so)
        ELSE SUM(COALESCE(b.original_cse, 0))
    END AS value_uom
FROM base b
CROSS JOIN params p
GROUP BY
    COALESCE(b.trang_thai_don_do, 'Unclassified'),
    p.p_uom
ORDER BY
    COALESCE(b.trang_thai_don_do, 'Unclassified');
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT t.*
    FROM analytics_workspace.mv_flash_and_drop_report t
    WHERE 1 = 1

    -- Date filter
    AND (
        toDate(
            CASE
                WHEN {{date_type}} = 'Ngày GI'             THEN t.delivery_date_1
                WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN t.etd_chuyen_gui_thau
                WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN t.eta_giao_hang_cho_npp
                WHEN {{date_type}} = 'Actual Ship Date'    THEN t.actual_ship_date
                WHEN {{date_type}} = 'ATA đơn'             THEN t.ata_den
            END
        )
        BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
            AND toDate(coalesce({{to_date}},   '2999-12-31'))
    )

    -- Sales Channel
    AND if(
        arraySort([{{group_name}}]) = (
            SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
        ),
        1 = 1,
        t.group_name IN ({{group_name}})
    )

    -- Warehouse
    AND if(
        arraySort([{{whseid}}]) = (
            SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
        ),
        1 = 1,
        t.whseid IN ({{whseid}})
    )

    -- Brand
    AND if(
        arraySort([{{brand}}]) = (
            SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
        ),
        1 = 1,
        coalesce(t.brand, 'Unclassified') IN ({{brand}})
    )

    -- Cargo Group
    AND if(
        arraySort([{{group_of_cargo}}]) = (
            SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
        ),
        1 = 1,
        coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
    )

    -- Area
    AND if(
        arraySort([{{region}}]) = (
            SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
        ),
        1 = 1,
        t.khu_vuc_doi_xe IN ({{region}})
    )
)

SELECT trang_thai_don_do, value_uom
FROM (

    -- 1. Kế hoạch xuất: original từ TẤT CẢ (flash + dropped/hủy)
    SELECT 1 AS sort_order, 'Kế hoạch xuất' AS trang_thai_don_do,
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END AS value_uom
    FROM base

    UNION ALL

    -- 2. Chưa xuất kho: original, status = New
    SELECT 2, 'Chưa xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Chưa xuất kho'

    UNION ALL

    -- 3. Đang xuất kho: shipped, status Allocated/PartAllocate/PartPick/Picked/PartShipped
    SELECT 3, 'Đang xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang xuất kho'

    UNION ALL

    -- 4. Đã xuất kho: shipped, ShipCompleted chưa lên xe (thoi_gian_di IS NULL)
    SELECT 4, 'Đã xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã xuất kho'

    UNION ALL

    -- 5. Đang vận chuyển: shipped, ShipCompleted + ATD (thoi_gian_di IS NOT NULL)
    SELECT 5, 'Đang vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang vận chuyển'

    UNION ALL

    -- 6. Đã vận chuyển: san_luong_giao (BBGN/STM), ShipCompleted + ATA IS NOT NULL
    SELECT 6, 'Đã vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(san_luong_giao_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(san_luong_giao_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(san_luong_giao_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã vận chuyển'

)
ORDER BY sort_order
```

### Đã vận chuyển `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter Date Type + Date Range
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )

        -- Filter Sales Channel
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Brand
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Delivery Area
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)

SELECT
    COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,
    CASE
        WHEN p.p_uom = 'cse' THEN SUM(COALESCE(b.original_cse, 0))
        WHEN p.p_uom = 'ton' THEN SUM(COALESCE(b.original_kg, 0)) / 1000.0
        WHEN p.p_uom = 'cbm' THEN SUM(COALESCE(b.original_cbm, 0))
        WHEN p.p_uom = 'pallet' THEN SUM(COALESCE(b.original_pl, 0))
        WHEN p.p_uom = 'DO' THEN COUNT(DISTINCT b.so)
        ELSE SUM(COALESCE(b.original_cse, 0))
    END AS value_uom
FROM base b
CROSS JOIN params p
GROUP BY
    COALESCE(b.trang_thai_don_do, 'Unclassified'),
    p.p_uom
ORDER BY
    COALESCE(b.trang_thai_don_do, 'Unclassified');
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT t.*
    FROM analytics_workspace.mv_flash_and_drop_report t
    WHERE 1 = 1

    -- Date filter
    AND (
        toDate(
            CASE
                WHEN {{date_type}} = 'Ngày GI'             THEN t.delivery_date_1
                WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN t.etd_chuyen_gui_thau
                WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN t.eta_giao_hang_cho_npp
                WHEN {{date_type}} = 'Actual Ship Date'    THEN t.actual_ship_date
                WHEN {{date_type}} = 'ATA đơn'             THEN t.ata_den
            END
        )
        BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
            AND toDate(coalesce({{to_date}},   '2999-12-31'))
    )

    -- Sales Channel
    AND if(
        arraySort([{{group_name}}]) = (
            SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
        ),
        1 = 1,
        t.group_name IN ({{group_name}})
    )

    -- Warehouse
    AND if(
        arraySort([{{whseid}}]) = (
            SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
        ),
        1 = 1,
        t.whseid IN ({{whseid}})
    )

    -- Brand
    AND if(
        arraySort([{{brand}}]) = (
            SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
        ),
        1 = 1,
        coalesce(t.brand, 'Unclassified') IN ({{brand}})
    )

    -- Cargo Group
    AND if(
        arraySort([{{group_of_cargo}}]) = (
            SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
        ),
        1 = 1,
        coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
    )

    -- Area
    AND if(
        arraySort([{{region}}]) = (
            SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
        ),
        1 = 1,
        t.khu_vuc_doi_xe IN ({{region}})
    )
)

SELECT trang_thai_don_do, value_uom
FROM (

    -- 1. Kế hoạch xuất: original từ TẤT CẢ (flash + dropped/hủy)
    SELECT 1 AS sort_order, 'Kế hoạch xuất' AS trang_thai_don_do,
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END AS value_uom
    FROM base

    UNION ALL

    -- 2. Chưa xuất kho: original, status = New
    SELECT 2, 'Chưa xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(original_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(original_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(original_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(original_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(original_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Chưa xuất kho'

    UNION ALL

    -- 3. Đang xuất kho: shipped, status Allocated/PartAllocate/PartPick/Picked/PartShipped
    SELECT 3, 'Đang xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang xuất kho'

    UNION ALL

    -- 4. Đã xuất kho: shipped, ShipCompleted chưa lên xe (thoi_gian_di IS NULL)
    SELECT 4, 'Đã xuất kho',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã xuất kho'

    UNION ALL

    -- 5. Đang vận chuyển: shipped, ShipCompleted + ATD (thoi_gian_di IS NOT NULL)
    SELECT 5, 'Đang vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(shipped_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(shipped_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(shipped_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(shipped_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(shipped_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đang vận chuyển'

    UNION ALL

    -- 6. Đã vận chuyển: san_luong_giao (BBGN/STM), ShipCompleted + ATA IS NOT NULL
    SELECT 6, 'Đã vận chuyển',
        CASE upper({{uom}})
            WHEN 'CSE'    THEN toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
            WHEN 'TON'    THEN toFloat64(SUM(coalesce(san_luong_giao_kg,  0))) / 1000.0
            WHEN 'CBM'    THEN toFloat64(SUM(coalesce(san_luong_giao_cbm, 0)))
            WHEN 'PALLET' THEN toFloat64(SUM(coalesce(san_luong_giao_pl,  0)))
            WHEN 'DO'     THEN toFloat64(uniqExact(so))
            ELSE               toFloat64(SUM(coalesce(san_luong_giao_cse, 0)))
        END
    FROM base WHERE e2e_label = 'Đã vận chuyển'

)
ORDER BY sort_order
```

### Phân bổ E2E (DO count) `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)

SELECT
    COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,

    CASE
        WHEN p.p_uom = 'cse' THEN SUM(COALESCE(b.original_cse, 0))
        WHEN p.p_uom = 'ton' THEN SUM(COALESCE(b.original_kg, 0)) / 1000.0
        WHEN p.p_uom = 'cbm' THEN SUM(COALESCE(b.original_cbm, 0))
        WHEN p.p_uom = 'pallet' THEN SUM(COALESCE(b.original_pl, 0))
        WHEN p.p_uom = 'DO' THEN COUNT(DISTINCT b.so)
        ELSE SUM(COALESCE(b.original_cse, 0))
    END AS value_uom,

    COUNT(DISTINCT b.so) AS distinct_so

FROM base b
CROSS JOIN params p
GROUP BY
    COALESCE(b.trang_thai_don_do, 'Unclassified'),
    p.p_uom
ORDER BY
    COALESCE(b.trang_thai_don_do, 'Unclassified');
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*,
        CASE
WHEN {{date_type}} = 'Ngày GI' THEN CAST(t.delivery_date_1 AS DATE)
WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN CAST(t.etd_chuyen_gui_thau AS DATE)
WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
WHEN {{date_type}} = 'Actual Ship Date' THEN CAST(t.actual_ship_date AS DATE)
WHEN {{date_type}} = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
        END AS filter_date
    FROM analytics_workspace.mv_flash_report t
    WHERE 1 = 1
-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.delivery_date_1
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'Actual Ship Date'
            THEN t.actual_ship_date
        WHEN {{date_type}} = 'ATA đơn'
            THEN t.ata_den
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales Channel
    [[ AND t.group_name IN ({{group_name}}) ]]
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

    -- Brand
AND if(
    arraySort([{{brand}}]) = (
        SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.brand, 'Unclassified') IN ({{brand}})
)

-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)

-- Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

)

SELECT
    b.trang_thai_don_do AS trang_thai_don_do,

CASE
    WHEN {{uom}} = 'CSE'    THEN toFloat64(SUM(coalesce(b.original_cse, 0)))
    WHEN {{uom}} = 'TON'    THEN toFloat64(SUM(coalesce(b.original_kg, 0))) / 1000.0
    WHEN {{uom}} = 'CBM'    THEN toFloat64(SUM(coalesce(b.original_cbm, 0)))
    WHEN {{uom}} = 'PALLET' THEN toFloat64(SUM(coalesce(b.original_pl, 0)))
    WHEN {{uom}} = 'DO'     THEN toFloat64(uniqExact(b.so))
    ELSE                         toFloat64(SUM(coalesce(b.original_cse, 0)))
END AS value_uom,

    COUNT(DISTINCT b.so) AS distinct_so

FROM base b
GROUP BY
    b.trang_thai_don_do
ORDER BY
    b.trang_thai_don_do;
```

### Tiến độ theo kho hệ thống `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)

SELECT
    COALESCE(b.whseid, 'Unclassified') AS whseid,
    COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,

    CASE
        WHEN p.p_uom = 'cse' THEN SUM(COALESCE(b.original_cse, 0))
        WHEN p.p_uom = 'ton' THEN SUM(COALESCE(b.original_kg, 0)) / 1000.0
        WHEN p.p_uom = 'cbm' THEN SUM(COALESCE(b.original_cbm, 0))
        WHEN p.p_uom = 'pallet' THEN SUM(COALESCE(b.original_pl, 0))
        WHEN p.p_uom = 'DO' THEN COUNT(DISTINCT b.so)
        ELSE SUM(COALESCE(b.original_cse, 0))
    END AS value_uom,

    COUNT(DISTINCT b.so) AS distinct_so

FROM base b
CROSS JOIN params p
GROUP BY
    COALESCE(b.whseid, 'Unclassified'),
    COALESCE(b.trang_thai_don_do, 'Unclassified'),
    p.p_uom
ORDER BY
    COALESCE(b.whseid, 'Unclassified'),
    COALESCE(b.trang_thai_don_do, 'Unclassified');
```

**ClickHouse SQL:**

```sql
WITH base AS (

    SELECT

        t.*,

        CASE

            WHEN {{date_type}} = 'Ngày GI' THEN CAST(t.delivery_date_1 AS DATE)

            WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN CAST(t.etd_chuyen_gui_thau AS DATE)

            WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)

            WHEN {{date_type}} = 'Actual Ship Date' THEN CAST(t.actual_ship_date AS DATE)

            WHEN {{date_type}} = 'ATA đơn' THEN CAST(t.ata_den AS DATE)

            ELSE CAST(t.delivery_date_1 AS DATE)

        END AS filter_date

    FROM analytics_workspace.mv_flash_report t

    WHERE 1 = 1



-- Date filter (fix robust)

AND (

    toDate(

    CASE

        WHEN {{date_type}} = 'Ngày GI'

            THEN t.delivery_date_1

        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'

            THEN t.etd_chuyen_gui_thau

        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'

            THEN t.eta_giao_hang_cho_npp

        WHEN {{date_type}} = 'Actual Ship Date'

            THEN t.actual_ship_date

        WHEN {{date_type}} = 'ATA đơn'

            THEN t.ata_den

    END)

    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))

        AND toDate(coalesce({{to_date}},   '2999-12-31'))

)



-- Sales Channel

    [[ AND t.group_name IN ({{group_name}}) ]]

AND if(

    arraySort([{{group_name}}]) = (

        SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel

    ),

    1 = 1,

    t.group_name IN ({{group_name}})

)



-- Warehouse

AND if(

    arraySort([{{whseid}}]) = (

        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse

    ),

    1 = 1,

    t.whseid IN ({{whseid}})

)



    -- Brand

AND if(

    arraySort([{{brand}}]) = (

        SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand

    ),

    1 = 1,

    coalesce(t.brand, 'Unclassified') IN ({{brand}})

)



-- Cargo Group

AND if(

    arraySort([{{group_of_cargo}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand

    ),

    1 = 1,

    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})

)



-- Area

AND if(

    arraySort([{{region}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region

    ),

    1 = 1,

    t.khu_vuc_doi_xe IN ({{region}})

)



)



SELECT

    b.whseid AS whseid,

    b.trang_thai_don_do AS trang_thai_don_do,



    CASE

    WHEN {{uom}} = 'CSE'    THEN toFloat64(SUM(coalesce(b.original_cse, 0)))

    WHEN {{uom}} = 'TON'    THEN toFloat64(SUM(coalesce(b.original_kg, 0))) / 1000.0

    WHEN {{uom}} = 'CBM'    THEN toFloat64(SUM(coalesce(b.original_cbm, 0)))

    WHEN {{uom}} = 'PALLET' THEN toFloat64(SUM(coalesce(b.original_pl, 0)))

    WHEN {{uom}} = 'DO'     THEN toFloat64(uniqExact(b.so))

    ELSE                         toFloat64(SUM(coalesce(b.original_cse, 0)))

END AS value_uom,



    COUNT(DISTINCT b.so) AS distinct_so



FROM base b

GROUP BY

    b.whseid,

    b.trang_thai_don_do

ORDER BY

    b.whseid,

    b.trang_thai_don_do;
```

### Theo NPP/Customer `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)

SELECT
    COALESCE(b.customer_name, 'Unclassified') AS customer_name,
    COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,

    CASE
        WHEN p.p_uom = 'cse' THEN SUM(COALESCE(b.original_cse, 0))
        WHEN p.p_uom = 'ton' THEN SUM(COALESCE(b.original_kg, 0)) / 1000.0
        WHEN p.p_uom = 'cbm' THEN SUM(COALESCE(b.original_cbm, 0))
        WHEN p.p_uom = 'pallet' THEN SUM(COALESCE(b.original_pl, 0))
        WHEN p.p_uom = 'DO' THEN COUNT(DISTINCT b.so)
        ELSE SUM(COALESCE(b.original_cse, 0))
    END AS value_uom,

    COUNT(DISTINCT b.so) AS distinct_so

FROM base b
CROSS JOIN params p
GROUP BY
    COALESCE(b.customer_name, 'Unclassified'),
    COALESCE(b.trang_thai_don_do, 'Unclassified'),
    p.p_uom
ORDER BY
    COALESCE(b.customer_name, 'Unclassified'),
    COALESCE(b.trang_thai_don_do, 'Unclassified');
```

**ClickHouse SQL:**

```sql
WITH base AS (

    SELECT

        t.*,

        CASE

            WHEN {{date_type}} = 'Ngày GI' THEN CAST(t.delivery_date_1 AS DATE)

            WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN CAST(t.etd_chuyen_gui_thau AS DATE)

            WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)

            WHEN {{date_type}} = 'Actual Ship Date' THEN CAST(t.actual_ship_date AS DATE)

            WHEN {{date_type}} = 'ATA đơn' THEN CAST(t.ata_den AS DATE)

            ELSE CAST(t.delivery_date_1 AS DATE)

        END AS filter_date

    FROM analytics_workspace.mv_flash_report t

    WHERE 1 = 1

-- Date filter (fix robust)

AND (

    toDate(

    CASE

        WHEN {{date_type}} = 'Ngày GI'

            THEN t.delivery_date_1

        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'

            THEN t.etd_chuyen_gui_thau

        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'

            THEN t.eta_giao_hang_cho_npp

        WHEN {{date_type}} = 'Actual Ship Date'

            THEN t.actual_ship_date

        WHEN {{date_type}} = 'ATA đơn'

            THEN t.ata_den

    END)

    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))

        AND toDate(coalesce({{to_date}},   '2999-12-31'))

)



-- Sales Channel

    [[ AND t.group_name IN ({{group_name}}) ]]

AND if(

    arraySort([{{group_name}}]) = (

        SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel

    ),

    1 = 1,

    t.group_name IN ({{group_name}})

)



-- Warehouse

AND if(

    arraySort([{{whseid}}]) = (

        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse

    ),

    1 = 1,

    t.whseid IN ({{whseid}})

)



    -- Brand

AND if(

    arraySort([{{brand}}]) = (

        SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand

    ),

    1 = 1,

    coalesce(t.brand, 'Unclassified') IN ({{brand}})

)



-- Cargo Group

AND if(

    arraySort([{{group_of_cargo}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand

    ),

    1 = 1,

    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})

)



-- Area

AND if(

    arraySort([{{region}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region

    ),

    1 = 1,

    t.khu_vuc_doi_xe IN ({{region}})

)



)



SELECT

    b.customer_name AS customer_name,

    b.trang_thai_don_do AS trang_thai_don_do,



CASE

    WHEN {{uom}} = 'CSE'    THEN toFloat64(SUM(coalesce(b.original_cse, 0)))

    WHEN {{uom}} = 'TON'    THEN toFloat64(SUM(coalesce(b.original_kg, 0))) / 1000.0

    WHEN {{uom}} = 'CBM'    THEN toFloat64(SUM(coalesce(b.original_cbm, 0)))

    WHEN {{uom}} = 'PALLET' THEN toFloat64(SUM(coalesce(b.original_pl, 0)))

    WHEN {{uom}} = 'DO'     THEN toFloat64(uniqExact(b.so))

    ELSE                         toFloat64(SUM(coalesce(b.original_cse, 0)))

END AS value_uom,



    COUNT(DISTINCT b.so) AS distinct_so



FROM base b

GROUP BY

    b.customer_name,

    b.trang_thai_don_do

ORDER BY

    b.customer_name,

    b.trang_thai_don_do;
```

### Theo khu vực giao hàng `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)

SELECT
    COALESCE(b.khu_vuc_doi_xe, 'Unclassified') AS khu_vuc_doi_xe,
    COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,

    CASE
        WHEN p.p_uom = 'cse' THEN SUM(COALESCE(b.original_cse, 0))
        WHEN p.p_uom = 'ton' THEN SUM(COALESCE(b.original_kg, 0)) / 1000.0
        WHEN p.p_uom = 'cbm' THEN SUM(COALESCE(b.original_cbm, 0))
        WHEN p.p_uom = 'pallet' THEN SUM(COALESCE(b.original_pl, 0))
        WHEN p.p_uom = 'DO' THEN COUNT(DISTINCT b.so)
        ELSE SUM(COALESCE(b.original_cse, 0))
    END AS value_uom,

    COUNT(DISTINCT b.so) AS distinct_so

FROM base b
CROSS JOIN params p
GROUP BY
    COALESCE(b.khu_vuc_doi_xe, 'Unclassified'),
    COALESCE(b.trang_thai_don_do, 'Unclassified'),
    p.p_uom
ORDER BY
    COALESCE(b.khu_vuc_doi_xe, 'Unclassified'),
    COALESCE(b.trang_thai_don_do, 'Unclassified');
```

**ClickHouse SQL:**

```sql
WITH base AS (

    SELECT

        t.*,

        CASE

            WHEN {{date_type}} = 'Ngày GI' THEN CAST(t.delivery_date_1 AS DATE)

            WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN CAST(t.etd_chuyen_gui_thau AS DATE)

            WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)

            WHEN {{date_type}} = 'Actual Ship Date' THEN CAST(t.actual_ship_date AS DATE)

            WHEN {{date_type}} = 'ATA đơn' THEN CAST(t.ata_den AS DATE)

            ELSE CAST(t.delivery_date_1 AS DATE)

        END AS filter_date

    FROM analytics_workspace.mv_flash_report t

    WHERE 1 = 1

-- Date filter (fix robust)

AND (

    toDate(

    CASE

        WHEN {{date_type}} = 'Ngày GI'

            THEN t.delivery_date_1

        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'

            THEN t.etd_chuyen_gui_thau

        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'

            THEN t.eta_giao_hang_cho_npp

        WHEN {{date_type}} = 'Actual Ship Date'

            THEN t.actual_ship_date

        WHEN {{date_type}} = 'ATA đơn'

            THEN t.ata_den

    END)

    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))

        AND toDate(coalesce({{to_date}},   '2999-12-31'))

)



-- Sales Channel

    [[ AND t.group_name IN ({{group_name}}) ]]

AND if(

    arraySort([{{group_name}}]) = (

        SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel

    ),

    1 = 1,

    t.group_name IN ({{group_name}})

)



-- Warehouse

AND if(

    arraySort([{{whseid}}]) = (

        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse

    ),

    1 = 1,

    t.whseid IN ({{whseid}})

)



    -- Brand

AND if(

    arraySort([{{brand}}]) = (

        SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand

    ),

    1 = 1,

    coalesce(t.brand, 'Unclassified') IN ({{brand}})

)



-- Cargo Group

AND if(

    arraySort([{{group_of_cargo}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand

    ),

    1 = 1,

    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})

)



-- Area

AND if(

    arraySort([{{region}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region

    ),

    1 = 1,

    t.khu_vuc_doi_xe IN ({{region}})

)



)



SELECT

    b.khu_vuc_doi_xe AS delivery_area,

    b.trang_thai_don_do AS trang_thai_don_do,



CASE

    WHEN {{uom}} = 'CSE'    THEN toFloat64(SUM(coalesce(b.original_cse, 0)))

    WHEN {{uom}} = 'TON'    THEN toFloat64(SUM(coalesce(b.original_kg, 0))) / 1000.0

    WHEN {{uom}} = 'CBM'    THEN toFloat64(SUM(coalesce(b.original_cbm, 0)))

    WHEN {{uom}} = 'PALLET' THEN toFloat64(SUM(coalesce(b.original_pl, 0)))

    WHEN {{uom}} = 'DO'     THEN toFloat64(uniqExact(b.so))

    ELSE                         toFloat64(SUM(coalesce(b.original_cse, 0)))

END AS value_uom,



    COUNT(DISTINCT b.so) AS distinct_so



FROM base b

GROUP BY

    b.khu_vuc_doi_xe,

    b.trang_thai_don_do

ORDER BY

    b.khu_vuc_doi_xe,

    b.trang_thai_don_do;
```

### Theo kênh bán hàng `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)

SELECT
    COALESCE(b.group_name, 'Unclassified') AS group_name,
    COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,

    CASE
        WHEN p.p_uom = 'cse' THEN SUM(COALESCE(b.original_cse, 0))
        WHEN p.p_uom = 'ton' THEN SUM(COALESCE(b.original_kg, 0)) / 1000.0
        WHEN p.p_uom = 'cbm' THEN SUM(COALESCE(b.original_cbm, 0))
        WHEN p.p_uom = 'pallet' THEN SUM(COALESCE(b.original_pl, 0))
        WHEN p.p_uom = 'DO' THEN COUNT(DISTINCT b.so)
        ELSE SUM(COALESCE(b.original_cse, 0))
    END AS value_uom,

    COUNT(DISTINCT b.so) AS distinct_so

FROM base b
CROSS JOIN params p
GROUP BY
    COALESCE(b.group_name, 'Unclassified'),
    COALESCE(b.trang_thai_don_do, 'Unclassified'),
    p.p_uom
ORDER BY
    COALESCE(b.group_name, 'Unclassified'),
    COALESCE(b.trang_thai_don_do, 'Unclassified');
```

**ClickHouse SQL:**

```sql
WITH base AS (

    SELECT

        t.*,

        CASE

            WHEN {{date_type}} = 'Ngày GI' THEN CAST(t.delivery_date_1 AS DATE)

            WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN CAST(t.etd_chuyen_gui_thau AS DATE)

            WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)

            WHEN {{date_type}} = 'Actual Ship Date' THEN CAST(t.actual_ship_date AS DATE)

            WHEN {{date_type}} = 'ATA đơn' THEN CAST(t.ata_den AS DATE)

            ELSE CAST(t.delivery_date_1 AS DATE)

        END AS filter_date

    FROM analytics_workspace.mv_flash_report t

    WHERE 1 = 1

-- Date filter (fix robust)

AND (

    toDate(

    CASE

        WHEN {{date_type}} = 'Ngày GI'

            THEN t.delivery_date_1

        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'

            THEN t.etd_chuyen_gui_thau

        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'

            THEN t.eta_giao_hang_cho_npp

        WHEN {{date_type}} = 'Actual Ship Date'

            THEN t.actual_ship_date

        WHEN {{date_type}} = 'ATA đơn'

            THEN t.ata_den

    END)

    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))

        AND toDate(coalesce({{to_date}},   '2999-12-31'))

)



-- Sales Channel

    [[ AND t.group_name IN ({{group_name}}) ]]

AND if(

    arraySort([{{group_name}}]) = (

        SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel

    ),

    1 = 1,

    t.group_name IN ({{group_name}})

)



-- Warehouse

AND if(

    arraySort([{{whseid}}]) = (

        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse

    ),

    1 = 1,

    t.whseid IN ({{whseid}})

)



    -- Brand

AND if(

    arraySort([{{brand}}]) = (

        SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand

    ),

    1 = 1,

    coalesce(t.brand, 'Unclassified') IN ({{brand}})

)



-- Cargo Group

AND if(

    arraySort([{{group_of_cargo}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand

    ),

    1 = 1,

    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})

)



-- Area

AND if(

    arraySort([{{region}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region

    ),

    1 = 1,

    t.khu_vuc_doi_xe IN ({{region}})

)



)



SELECT

    b.group_name AS group_name,

    b.trang_thai_don_do AS trang_thai_don_do,



CASE

    WHEN {{uom}} = 'CSE'    THEN toFloat64(SUM(coalesce(b.original_cse, 0)))

    WHEN {{uom}} = 'TON'    THEN toFloat64(SUM(coalesce(b.original_kg, 0))) / 1000.0

    WHEN {{uom}} = 'CBM'    THEN toFloat64(SUM(coalesce(b.original_cbm, 0)))

    WHEN {{uom}} = 'PALLET' THEN toFloat64(SUM(coalesce(b.original_pl, 0)))

    WHEN {{uom}} = 'DO'     THEN toFloat64(uniqExact(b.so))

    ELSE                         toFloat64(SUM(coalesce(b.original_cse, 0)))

END AS value_uom,



    COUNT(DISTINCT b.so) AS distinct_so



FROM base b

GROUP BY

    b.group_name,

    b.trang_thai_don_do

ORDER BY

    b.group_name,

    b.trang_thai_don_do;
```

### Báo cáo tổng hợp theo kho hệ thống `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
data_with_volume AS (
    SELECT
        COALESCE(b.whseid, 'Unclassified') AS whseid,
        COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,
        b.so,
        CASE
            WHEN p.p_uom = 'cse' THEN COALESCE(b.original_cse, 0)
            WHEN p.p_uom = 'ton' THEN COALESCE(b.original_kg, 0) / 1000.0
            WHEN p.p_uom = 'cbm' THEN COALESCE(b.original_cbm, 0)
            WHEN p.p_uom = 'pallet' THEN COALESCE(b.original_pl, 0)
            WHEN p.p_uom = 'DO' THEN 1
            ELSE COALESCE(b.original_cse, 0)
        END AS volume_value
    FROM base b
    CROSS JOIN params p
)

SELECT
    whseid,

    SUM(volume_value) AS total_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
            ELSE 0
        END
    ) AS done_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do <> 'Đã vận chuyển' OR trang_thai_don_do IS NULL THEN volume_value
            ELSE 0
        END
    ) AS pending_volume,

    CASE
        WHEN SUM(volume_value) = 0 THEN 0
        ELSE
            SUM(
                CASE
                    WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
                    ELSE 0
                END
            ) / SUM(volume_value)::FLOAT
    END AS pct_done

FROM data_with_volume
GROUP BY whseid
ORDER BY whseid;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*,
        CASE
            WHEN {{date_type}} = 'Ngày GI' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN CAST(t.etd_chuyen_gui_thau AS DATE)
            WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            WHEN {{date_type}} = 'Actual Ship Date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN {{date_type}} = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM analytics_workspace.mv_flash_report t
    WHERE 1 = 1
-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.delivery_date_1
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'Actual Ship Date'
            THEN t.actual_ship_date
        WHEN {{date_type}} = 'ATA đơn'
            THEN t.ata_den
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales Channel
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

    -- Brand
AND if(
    arraySort([{{brand}}]) = (
        SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.brand, 'Unclassified') IN ({{brand}})
)

-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)

-- Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

)
, data_with_volume AS (
    SELECT
        b.whseid AS whseid,
        b.trang_thai_don_do AS trang_thai_don_do,
        b.so,
        CASE
            WHEN {{uom}} = 'CSE'    THEN toFloat64(coalesce(b.original_cse, 0))
            WHEN {{uom}} = 'TON'    THEN toFloat64(coalesce(b.original_kg,  0)) / 1000.0
            WHEN {{uom}} = 'CBM'    THEN toFloat64(coalesce(b.original_cbm, 0))
            WHEN {{uom}} = 'PALLET' THEN toFloat64(coalesce(b.original_pl,  0))
            WHEN {{uom}} = 'DO'     THEN 1.0   -- đếm 1 dòng = 1 DO; xem ghi chú bên dưới
            ELSE                         toFloat64(coalesce(b.original_cse, 0))
        END AS volume_value
    FROM base b
)

SELECT
    whseid,

    SUM(volume_value) AS total_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
            ELSE 0
        END
    ) AS done_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do <> 'Đã vận chuyển' OR trang_thai_don_do IS NULL THEN volume_value
            ELSE 0
        END
    ) AS pending_volume,

    CASE
        WHEN SUM(volume_value) = 0 THEN 0
        ELSE
            SUM(
                CASE
                    WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
                    ELSE 0
                END
            ) / SUM(volume_value)::FLOAT
    END AS pct_done

FROM data_with_volume
GROUP BY whseid
ORDER BY whseid;
```

### Báo cáo tổng hợp theo NPP `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
data_with_volume AS (
    SELECT
        COALESCE(b.customer_name, 'Unclassified') AS customer_name,
        COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,
        b.so,
        CASE
            WHEN p.p_uom = 'cse' THEN COALESCE(b.original_cse, 0)
            WHEN p.p_uom = 'ton' THEN COALESCE(b.original_kg, 0) / 1000.0
            WHEN p.p_uom = 'cbm' THEN COALESCE(b.original_cbm, 0)
            WHEN p.p_uom = 'pallet' THEN COALESCE(b.original_pl, 0)
            WHEN p.p_uom = 'DO' THEN 1
            ELSE COALESCE(b.original_cse, 0)
        END AS volume_value
    FROM base b
    CROSS JOIN params p
)

SELECT
    customer_name,

    SUM(volume_value) AS total_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
            ELSE 0
        END
    ) AS done_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do <> 'Đã vận chuyển' OR trang_thai_don_do IS NULL THEN volume_value
            ELSE 0
        END
    ) AS pending_volume,

    CASE
        WHEN SUM(volume_value) = 0 THEN 0
        ELSE
            SUM(
                CASE
                    WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
                    ELSE 0
                END
            ) / SUM(volume_value)::FLOAT
    END AS pct_done

FROM data_with_volume
GROUP BY customer_name
ORDER BY customer_name;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*,
        CASE
            WHEN {{date_type}} = 'Ngày GI' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN CAST(t.etd_chuyen_gui_thau AS DATE)
            WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            WHEN {{date_type}} = 'Actual Ship Date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN {{date_type}} = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM analytics_workspace.mv_flash_report t
    WHERE 1 = 1
-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.delivery_date_1
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'Actual Ship Date'
            THEN t.actual_ship_date
        WHEN {{date_type}} = 'ATA đơn'
            THEN t.ata_den
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales Channel
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

    -- Brand
AND if(
    arraySort([{{brand}}]) = (
        SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.brand, 'Unclassified') IN ({{brand}})
)

-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)

-- Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

),
data_with_volume AS (
    SELECT
        b.customer_name AS customer_name,
        b.trang_thai_don_do AS trang_thai_don_do,
        b.so,
        CASE
            WHEN {{uom}} = 'CSE'    THEN toFloat64(coalesce(b.original_cse, 0))
            WHEN {{uom}} = 'TON'    THEN toFloat64(coalesce(b.original_kg,  0)) / 1000.0
            WHEN {{uom}} = 'CBM'    THEN toFloat64(coalesce(b.original_cbm, 0))
            WHEN {{uom}} = 'PALLET' THEN toFloat64(coalesce(b.original_pl,  0))
            WHEN {{uom}} = 'DO'     THEN 1.0   -- đếm 1 dòng = 1 DO; xem ghi chú bên dưới
            ELSE                         toFloat64(coalesce(b.original_cse, 0))
        END AS volume_value
    FROM base b
)

SELECT
    customer_name,

    SUM(volume_value) AS total_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
            ELSE 0
        END
    ) AS done_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do <> 'Đã vận chuyển' OR trang_thai_don_do IS NULL THEN volume_value
            ELSE 0
        END
    ) AS pending_volume,

    CASE
        WHEN SUM(volume_value) = 0 THEN 0
        ELSE
            SUM(
                CASE
                    WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
                    ELSE 0
                END
            ) / SUM(volume_value)::FLOAT
    END AS pct_done

FROM data_with_volume
GROUP BY customer_name
ORDER BY customer_name;
```

### Báo cáo tổng hợp theo khu vực `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
data_with_volume AS (
    SELECT
        COALESCE(b.khu_vuc_doi_xe, 'Unclassified') AS khu_vuc_doi_xe,
        COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,
        b.so,
        CASE
            WHEN p.p_uom = 'cse' THEN COALESCE(b.original_cse, 0)
            WHEN p.p_uom = 'ton' THEN COALESCE(b.original_kg, 0) / 1000.0
            WHEN p.p_uom = 'cbm' THEN COALESCE(b.original_cbm, 0)
            WHEN p.p_uom = 'pallet' THEN COALESCE(b.original_pl, 0)
            WHEN p.p_uom = 'DO' THEN 1
            ELSE COALESCE(b.original_cse, 0)
        END AS volume_value
    FROM base b
    CROSS JOIN params p
)

SELECT
    khu_vuc_doi_xe,

    SUM(volume_value) AS total_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
            ELSE 0
        END
    ) AS done_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do <> 'Đã vận chuyển' OR trang_thai_don_do IS NULL THEN volume_value
            ELSE 0
        END
    ) AS pending_volume,

    CASE
        WHEN SUM(volume_value) = 0 THEN 0
        ELSE
            SUM(
                CASE
                    WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
                    ELSE 0
                END
            ) / SUM(volume_value)::FLOAT
    END AS pct_done

FROM data_with_volume
GROUP BY khu_vuc_doi_xe
ORDER BY khu_vuc_doi_xe;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*,
        CASE
            WHEN {{date_type}} = 'Ngày GI' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN CAST(t.etd_chuyen_gui_thau AS DATE)
            WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            WHEN {{date_type}} = 'Actual Ship Date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN {{date_type}} = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM analytics_workspace.mv_flash_report t
    WHERE 1 = 1
-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.delivery_date_1
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'Actual Ship Date'
            THEN t.actual_ship_date
        WHEN {{date_type}} = 'ATA đơn'
            THEN t.ata_den
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales Channel
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

    -- Brand
AND if(
    arraySort([{{brand}}]) = (
        SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.brand, 'Unclassified') IN ({{brand}})
)

-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)

-- Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

),
data_with_volume AS (
    SELECT
        b.khu_vuc_doi_xe AS khu_vuc_doi_xe,
        b.trang_thai_don_do AS trang_thai_don_do,
        b.so,
        CASE
            WHEN {{uom}} = 'CSE'    THEN toFloat64(coalesce(b.original_cse, 0))
            WHEN {{uom}} = 'TON'    THEN toFloat64(coalesce(b.original_kg,  0)) / 1000.0
            WHEN {{uom}} = 'CBM'    THEN toFloat64(coalesce(b.original_cbm, 0))
            WHEN {{uom}} = 'PALLET' THEN toFloat64(coalesce(b.original_pl,  0))
            WHEN {{uom}} = 'DO'     THEN 1.0   -- đếm 1 dòng = 1 DO; xem ghi chú bên dưới
            ELSE                         toFloat64(coalesce(b.original_cse, 0))
        END AS volume_value
    FROM base b
)

SELECT
    khu_vuc_doi_xe,

    SUM(volume_value) AS total_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
            ELSE 0
        END
    ) AS done_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do <> 'Đã vận chuyển' OR trang_thai_don_do IS NULL THEN volume_value
            ELSE 0
        END
    ) AS pending_volume,

    CASE
        WHEN SUM(volume_value) = 0 THEN 0
        ELSE
            SUM(
                CASE
                    WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
                    ELSE 0
                END
            ) / SUM(volume_value)::FLOAT
    END AS pct_done

FROM data_with_volume
GROUP BY khu_vuc_doi_xe
ORDER BY khu_vuc_doi_xe;
```

### Báo cáo tổng hợp theo kênh bán hàng `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- cse / ton / cbm / pallet / DO
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
data_with_volume AS (
    SELECT
        COALESCE(b.group_name, 'Unclassified') AS group_name,
        COALESCE(b.trang_thai_don_do, 'Unclassified') AS trang_thai_don_do,
        b.so,
        CASE
            WHEN p.p_uom = 'cse' THEN COALESCE(b.original_cse, 0)
            WHEN p.p_uom = 'ton' THEN COALESCE(b.original_kg, 0) / 1000.0
            WHEN p.p_uom = 'cbm' THEN COALESCE(b.original_cbm, 0)
            WHEN p.p_uom = 'pallet' THEN COALESCE(b.original_pl, 0)
            WHEN p.p_uom = 'DO' THEN 1
            ELSE COALESCE(b.original_cse, 0)
        END AS volume_value
    FROM base b
    CROSS JOIN params p
)

SELECT
    group_name,

    SUM(volume_value) AS total_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
            ELSE 0
        END
    ) AS done_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do <> 'Đã vận chuyển' OR trang_thai_don_do IS NULL THEN volume_value
            ELSE 0
        END
    ) AS pending_volume,

    CASE
        WHEN SUM(volume_value) = 0 THEN 0
        ELSE
            SUM(
                CASE
                    WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
                    ELSE 0
                END
            ) / SUM(volume_value)::FLOAT
    END AS pct_done

FROM data_with_volume
GROUP BY group_name
ORDER BY group_name;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*,
        CASE
            WHEN {{date_type}} = 'Ngày GI' THEN CAST(t.delivery_date_1 AS DATE)
            WHEN {{date_type}} = 'ETD gửi thầu (đơn)' THEN CAST(t.etd_chuyen_gui_thau AS DATE)
            WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            WHEN {{date_type}} = 'Actual Ship Date' THEN CAST(t.actual_ship_date AS DATE)
            WHEN {{date_type}} = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
            ELSE CAST(t.delivery_date_1 AS DATE)
        END AS filter_date
    FROM analytics_workspace.mv_flash_report t
    WHERE 1 = 1
-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.delivery_date_1
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'Actual Ship Date'
            THEN t.actual_ship_date
        WHEN {{date_type}} = 'ATA đơn'
            THEN t.ata_den
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales Channel
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

    -- Brand
AND if(
    arraySort([{{brand}}]) = (
        SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.brand, 'Unclassified') IN ({{brand}})
)

-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)

-- Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

),
data_with_volume AS (
    SELECT
        b.group_name AS group_name,
        b.trang_thai_don_do AS trang_thai_don_do,
        b.so,
        CASE
            WHEN {{uom}} = 'CSE'    THEN toFloat64(coalesce(b.original_cse, 0))
            WHEN {{uom}} = 'TON'    THEN toFloat64(coalesce(b.original_kg,  0)) / 1000.0
            WHEN {{uom}} = 'CBM'    THEN toFloat64(coalesce(b.original_cbm, 0))
            WHEN {{uom}} = 'PALLET' THEN toFloat64(coalesce(b.original_pl,  0))
            WHEN {{uom}} = 'DO'     THEN 1.0   -- đếm 1 dòng = 1 DO; xem ghi chú bên dưới
            ELSE                         toFloat64(coalesce(b.original_cse, 0))
        END AS volume_value
    FROM base b
)

SELECT
    group_name,

    SUM(volume_value) AS total_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
            ELSE 0
        END
    ) AS done_volume,

    SUM(
        CASE
            WHEN trang_thai_don_do <> 'Đã vận chuyển' OR trang_thai_don_do IS NULL THEN volume_value
            ELSE 0
        END
    ) AS pending_volume,

    CASE
        WHEN SUM(volume_value) = 0 THEN 0
        ELSE
            SUM(
                CASE
                    WHEN trang_thai_don_do = 'Đã vận chuyển' THEN volume_value
                    ELSE 0
                END
            ) / SUM(volume_value)::FLOAT
    END AS pct_done

FROM data_with_volume
GROUP BY group_name
ORDER BY group_name;
```

### Bổ sung report hàng rớt `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu
        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày
        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),

flash_base AS (
    SELECT
        t.*
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),

dropped_base AS (
    SELECT
        t.*
    FROM reporting_schema.mv_dropped_report t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
),

flash_agg AS (
    SELECT
        SUM(
            CASE
                WHEN group_of_cago IN ('FRESH', 'DRY')
                     AND status = 'ShipCompleted'
                THEN COALESCE(shipped_cse, 0)
                ELSE 0
            END
        ) AS success_fresh_dry_cse,

        SUM(
            CASE
                WHEN group_of_cago = 'POSM/OFFBOM'
                     AND status = 'ShipCompleted'
                THEN COALESCE(shipped_qty, 0)
                ELSE 0
            END
        ) AS success_posm_pc,

        SUM(
            CASE
                WHEN group_of_cago IN ('FRESH', 'DRY')
                     AND status <> 'ShipCompleted'
                THEN COALESCE(original_cse, 0)
                ELSE 0
            END
        ) AS processing_fresh_dry_cse,

        SUM(
            CASE
                WHEN group_of_cago = 'POSM/OFFBOM'
                     AND status <> 'ShipCompleted'
                THEN COALESCE(original_qty, 0)
                ELSE 0
            END
        ) AS processing_posm_pc,

        SUM(
            CASE
                WHEN group_of_cago IN ('FRESH', 'DRY')
                THEN COALESCE(original_cse, 0)
                ELSE 0
            END
        ) AS total_flash_fresh_dry_cse,

        SUM(
            CASE
                WHEN group_of_cago = 'POSM/OFFBOM'
                THEN COALESCE(original_qty, 0)
                ELSE 0
            END
        ) AS total_flash_posm_pc
    FROM flash_base
),

dropped_agg AS (
    SELECT
        SUM(
            CASE
                WHEN group_of_cago IN ('FRESH', 'DRY')
                     AND status = 'Cancel'
                THEN COALESCE(original_cse, 0)
                ELSE 0
            END
        ) AS failed_fresh_dry_cse,

        SUM(
            CASE
                WHEN group_of_cago = 'POSM/OFFBOM'
                     AND status = 'Cancel'
                THEN COALESCE(original_qty, 0)
                ELSE 0
            END
        ) AS failed_posm_pc
    FROM dropped_base
),

plan_agg AS (
    SELECT
        f.total_flash_fresh_dry_cse + d.failed_fresh_dry_cse AS total_plan_fresh_dry_cse,
        f.total_flash_posm_pc + d.failed_posm_pc AS total_plan_posm_pc
    FROM flash_agg f
    CROSS JOIN dropped_agg d
),

report_rows AS (
    SELECT
        1 AS sort_order,
        'Tổng kế hoạch CS book' AS "Delivery to Customer",
        p.total_plan_fresh_dry_cse AS "DRY & FRESH (CSE)",
        p.total_plan_posm_pc AS "POSM (PC)"
    FROM plan_agg p

    UNION ALL

    SELECT
        2 AS sort_order,
        'Xử lý thành công' AS "Delivery to Customer",
        f.success_fresh_dry_cse AS "DRY & FRESH (CSE)",
        f.success_posm_pc AS "POSM (PC)"
    FROM flash_agg f

    UNION ALL

    SELECT
        3 AS sort_order,
        'Đang xử lý' AS "Delivery to Customer",
        f.processing_fresh_dry_cse AS "DRY & FRESH (CSE)",
        f.processing_posm_pc AS "POSM (PC)"
    FROM flash_agg f

    UNION ALL

    SELECT
        4 AS sort_order,
        'Xử lý không thành công' AS "Delivery to Customer",
        d.failed_fresh_dry_cse AS "DRY & FRESH (CSE)",
        d.failed_posm_pc AS "POSM (PC)"
    FROM dropped_agg d
)

SELECT
    r."Delivery to Customer",
    r."DRY & FRESH (CSE)",
    r."POSM (PC)",
    ROUND(
        CASE
            WHEN p.total_plan_fresh_dry_cse = 0 THEN 0
            ELSE 100.0 * r."DRY & FRESH (CSE)" / p.total_plan_fresh_dry_cse
        END
    , 2) AS "%DRY & FRESH (CSE)",
    ROUND(
        CASE
            WHEN p.total_plan_posm_pc = 0 THEN 0
            ELSE 100.0 * r."POSM (PC)" / p.total_plan_posm_pc
        END
    , 2) AS "%POSM (PC)"
FROM report_rows r
CROSS JOIN plan_agg p
ORDER BY r.sort_order;
```

**ClickHouse SQL:**

```sql
WITH flash_base AS (
    SELECT t.*
    FROM analytics_workspace.mv_flash_report t
    WHERE 1 = 1
-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.delivery_date_1
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'Actual Ship Date'
            THEN t.actual_ship_date
        WHEN {{date_type}} = 'ATA đơn'
            THEN t.ata_den
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales Channel
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

    -- Brand
AND if(
    arraySort([{{brand}}]) = (
        SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.brand, 'Unclassified') IN ({{brand}})
)

-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)

-- Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)
),

dropped_base AS (
    SELECT t.*
    FROM analytics_workspace.mv_dropped_report t
    WHERE 1 = 1
-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.delivery_date_1
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'Actual Ship Date'
            THEN t.actual_ship_date
        WHEN {{date_type}} = 'ATA đơn'
            THEN t.ata_den
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales Channel
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

    -- Brand
AND if(
    arraySort([{{brand}}]) = (
        SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.brand, 'Unclassified') IN ({{brand}})
)

-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)

-- Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)
),

flash_agg AS (
    SELECT
        -- ⚠️ toFloat64() trên TẤT CẢ giá trị numeric để tránh Float64 vs Decimal
        SUM(if(group_of_cago IN ('FRESH', 'DRY')   AND status = 'ShipCompleted', toFloat64(coalesce(shipped_cse, 0)),  toFloat64(0))) AS success_fresh_dry_cse,
        SUM(if(group_of_cago = 'POSM/OFFBOM'       AND status = 'ShipCompleted', toFloat64(coalesce(shipped_qty, 0)),  toFloat64(0))) AS success_posm_pc,
        SUM(if(group_of_cago IN ('FRESH', 'DRY')   AND status != 'ShipCompleted', toFloat64(coalesce(original_cse, 0)), toFloat64(0))) AS processing_fresh_dry_cse,
        SUM(if(group_of_cago = 'POSM/OFFBOM'       AND status != 'ShipCompleted', toFloat64(coalesce(original_qty, 0)), toFloat64(0))) AS processing_posm_pc,
        SUM(if(group_of_cago IN ('FRESH', 'DRY'),   toFloat64(coalesce(original_cse, 0)), toFloat64(0)))                              AS total_flash_fresh_dry_cse,
        SUM(if(group_of_cago = 'POSM/OFFBOM',       toFloat64(coalesce(original_qty, 0)), toFloat64(0)))                              AS total_flash_posm_pc
    FROM flash_base
),

dropped_agg AS (
    SELECT
        SUM(if(group_of_cago IN ('FRESH', 'DRY') AND status = 'Cancel', toFloat64(coalesce(original_cse, 0)), toFloat64(0))) AS failed_fresh_dry_cse,
        SUM(if(group_of_cago = 'POSM/OFFBOM'     AND status = 'Cancel', toFloat64(coalesce(original_qty, 0)), toFloat64(0))) AS failed_posm_pc
    FROM dropped_base
),

plan_agg AS (
    SELECT
        f.total_flash_fresh_dry_cse + d.failed_fresh_dry_cse AS total_plan_fresh_dry_cse,
        f.total_flash_posm_pc       + d.failed_posm_pc       AS total_plan_posm_pc
    FROM flash_agg f
    CROSS JOIN dropped_agg d
),

report_rows AS (
    SELECT 1 AS sort_order, 'Tổng kế hoạch CS book' AS delivery_label,
           p.total_plan_fresh_dry_cse AS fresh_dry_cse,
           p.total_plan_posm_pc       AS posm_pc
    FROM plan_agg p

    UNION ALL
    SELECT 2, 'Xử lý thành công',
           f.success_fresh_dry_cse, f.success_posm_pc
    FROM flash_agg f

    UNION ALL
    SELECT 3, 'Đang xử lý',
           f.processing_fresh_dry_cse, f.processing_posm_pc
    FROM flash_agg f

    UNION ALL
    SELECT 4, 'Xử lý không thành công',
           d.failed_fresh_dry_cse, d.failed_posm_pc
    FROM dropped_agg d
)

SELECT
    r.delivery_label                                                           AS "Delivery to Customer",
    r.fresh_dry_cse                                                            AS "DRY & FRESH (CSE)",
    r.posm_pc                                                                  AS "POSM (PC)",
    round(if(p.total_plan_fresh_dry_cse = 0, 0, 100.0 * r.fresh_dry_cse / p.total_plan_fresh_dry_cse), 2) AS "%DRY & FRESH (CSE)",
    round(if(p.total_plan_posm_pc = 0,       0, 100.0 * r.posm_pc       / p.total_plan_posm_pc),       2) AS "%POSM (PC)"
FROM report_rows r
CROSS JOIN plan_agg p
ORDER BY r.sort_order;
```

### Bổ sung report lý do rớt đơn `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- giữ lại theo mẫu, hiện chưa dùng trong logic tính
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
),
base AS (
    SELECT
        t.*
    FROM reporting_schema.mv_dropped_report t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)

SELECT
    COALESCE(remark_2, 'Unclassified') AS remark_2,

    SUM(
        CASE
            WHEN COALESCE(group_of_cago, '') IN ('FRESH', 'DRY')
                THEN COALESCE(original_cbm, 0)
            ELSE 0
        END
    ) AS "FRESH/DRY (CSE)",

    SUM(
        CASE
            WHEN COALESCE(group_of_cago, '') = 'POSM'
                THEN COALESCE(original_qty, 0)
            ELSE 0
        END
    ) AS "POSM (PC)"

FROM base
GROUP BY COALESCE(remark_2, 'Unclassified')
ORDER BY COALESCE(remark_2, 'Unclassified');
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*
    FROM analytics_workspace.mv_dropped_report t
    WHERE 1 = 1
-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.delivery_date_1
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'Actual Ship Date'
            THEN t.actual_ship_date
        WHEN {{date_type}} = 'ATA đơn'
            THEN t.ata_den
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales Channel
    [[ AND t.group_name IN ({{group_name}}) ]]
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

    -- Brand
AND if(
    arraySort([{{brand}}]) = (
        SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.brand, 'Unclassified') IN ({{brand}})
)

-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)

-- Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)
)

SELECT
    remark_2 AS ly_do_rot_don,

    SUM(original_cbm) AS "FRESH/DRY (CSE)",

    SUM(original_qty) AS "POSM (PC)"

FROM base
GROUP BY remark_2
ORDER BY remark_2;
```

### Report raw `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'cse'::VARCHAR AS p_uom,                            -- giữ lại theo mẫu, hiện chưa dùng trong logic tính
        'GI date'::VARCHAR AS p_loai_ngay,                 -- GI date / Actual Ship date / ETD gửi thầu / ATA đơn / ETA gửi thầu

        NULL::DATE AS p_tu_ngay,                           -- từ ngày
        NULL::DATE AS p_den_ngay,                          -- đến ngày

        'ALL'::VARCHAR AS p_group_name,                    -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                        -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                         -- brand
        'ALL'::VARCHAR AS p_group_of_cago,                 -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe                 -- khu vực giao
)
    SELECT
        t.*
    FROM reporting_schema.mv_flash_report t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'GI date' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'Actual Ship date' THEN CAST(t.actual_ship_date AS DATE)
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN CAST(t.delivery_date_1 AS DATE)
                WHEN p.p_loai_ngay = 'ATA đơn' THEN CAST(t.ata_den AS DATE)
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                ELSE CAST(t.delivery_date_1 AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
```

**ClickHouse SQL:**

```sql
SELECT
        t.*
    FROM analytics_workspace.mv_flash_report t
    WHERE 1 = 1
-- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.delivery_date_1
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'Actual Ship Date'
            THEN t.actual_ship_date
        WHEN {{date_type}} = 'ATA đơn'
            THEN t.ata_den
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales Channel
    [[ AND t.group_name IN ({{group_name}}) ]]
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code)) FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

    -- Brand
AND if(
    arraySort([{{brand}}]) = (
        SELECT arraySort(groupArray(DISTINCT brand_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.brand, 'Unclassified') IN ({{brand}})
)

-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)

-- Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)
```

---

## Tiến độ xuất hàng

### CBM kế hoạch `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### CBM đã nhận `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### CBM pending `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### %CBM pending/ KH `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### Tấn kế hoạch `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### Tấn đã nhận `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### Tấn pending `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### %Tấn pending/ KH `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### Đơn kế hoạch `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### Đơn đã nhận `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### Đơn pending `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### %Đơn pending/ KH `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### Chuyến kế hoạch `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### Chuyến đã nhận `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### Chuyến pending `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### %Chuyến pending/ KH `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_brand,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM (
             select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
     ) AS t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
),
agg AS (
    SELECT
        /* CBM */
        SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
                ELSE 0
            END) AS cbm_da_nhan,

        /* Tấn */
        SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
        SUM(CASE
                WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
                ELSE 0
            END) / 1000.0 AS tan_da_nhan,

        /* Đơn */
        COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN ma_don_hang
            END) AS don_da_nhan,

        /* Chuyến */
        COUNT(DISTINCT so_chuyen) AS chuyen_ke_hoach,
        COUNT(DISTINCT CASE
                WHEN status = 'ShipCompleted' THEN so_chuyen
            END) AS chuyen_da_nhan
    FROM base
)
SELECT
    /* CBM */
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / NULLIF(cbm_ke_hoach, 0) AS pct_cbm_pending,

    /* Tấn */
    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / NULLIF(tan_ke_hoach, 0) AS pct_tan_pending,

    /* Đơn */
    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    (don_ke_hoach - don_da_nhan)::DECIMAL(18,6) / NULLIF(don_ke_hoach, 0) AS pct_don_pending,

    /* Chuyến */
    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    (chuyen_ke_hoach - chuyen_da_nhan)::DECIMAL(18,6) / NULLIF(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

**ClickHouse SQL:**

```sql
WITH base AS
(
    SELECT
        t.*
    FROM
    (SELECT 
            delivery_date_1,
                    thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        SELECT 
                delivery_date_1,
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, ma_don_hang, so_chuyen,
            toFloat64(original_cbm) AS original_cbm, 
            toFloat64(shipped_cbm) AS shipped_cbm,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg
        FROM analytics_workspace.mv_dropped_report
    ) t
 WHERE 1=1

    -- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
   
),

agg AS
(
    SELECT
        SUM(original_cbm) AS cbm_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_cbm, 0)) AS cbm_da_nhan,
        SUM(original_kg) / 1000 AS tan_ke_hoach,
        SUM(if(status='ShipCompleted', shipped_kg, 0)) / 1000 AS tan_da_nhan,
        countDistinct(ma_don_hang) AS don_ke_hoach,
        countDistinct(if(status='ShipCompleted', ma_don_hang, NULL)) AS don_da_nhan,
        countDistinct(so_chuyen) AS chuyen_ke_hoach,
        countDistinct(if(status='ShipCompleted', so_chuyen, NULL)) AS chuyen_da_nhan
    FROM base
)

SELECT
    cbm_ke_hoach,
    cbm_da_nhan,
    cbm_ke_hoach - cbm_da_nhan AS cbm_pending,
    (cbm_ke_hoach - cbm_da_nhan) / nullIf(cbm_ke_hoach, 0) AS pct_cbm_pending,

    tan_ke_hoach,
    tan_da_nhan,
    tan_ke_hoach - tan_da_nhan AS tan_pending,
    (tan_ke_hoach - tan_da_nhan) / nullIf(tan_ke_hoach, 0) AS pct_tan_pending,

    don_ke_hoach,
    don_da_nhan,
    don_ke_hoach - don_da_nhan AS don_pending,
    toFloat64(don_ke_hoach - don_da_nhan) / nullIf(don_ke_hoach, 0) AS pct_don_pending,

    chuyen_ke_hoach,
    chuyen_da_nhan,
    chuyen_ke_hoach - chuyen_da_nhan AS chuyen_pending,
    toFloat64(chuyen_ke_hoach - chuyen_da_nhan) / nullIf(chuyen_ke_hoach, 0) AS pct_chuyen_pending
FROM agg;
```

### Bảng tổng hợp `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2999-12-31 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,             -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                 -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                  -- brand
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,         -- khu vực giao
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai    -- nhà vận tải
),
base AS (
    SELECT
        t.*
    FROM (
            select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
    ) as t
    CROSS JOIN params p
    WHERE 1 = 1
                
        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)
SELECT
    whseid,
    khu_vuc_doi_xe,
    ten_ngan_nha_van_tai,

    /* DO */
    COUNT(DISTINCT so) AS do_ke_hoach,
    COUNT(DISTINCT CASE
        WHEN status = 'ShipCompleted' THEN so
    END) AS do_da_xuat,
    COUNT(DISTINCT so)
        - COUNT(DISTINCT CASE
            WHEN status = 'ShipCompleted' THEN so
        END) AS do_pending,

    /* CBM */
    SUM(COALESCE(original_cbm, 0)) AS cbm_ke_hoach,
    SUM(CASE
        WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
        ELSE 0
    END) AS cbm_da_nhan,
    SUM(COALESCE(original_cbm, 0))
        - SUM(CASE
            WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
            ELSE 0
        END) AS cbm_pending,

    /* Tấn */
    SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
    SUM(CASE
        WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
        ELSE 0
    END) / 1000.0 AS tan_da_xuat,
    SUM(COALESCE(original_kg, 0)) / 1000.0
        - SUM(CASE
            WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
            ELSE 0
        END) / 1000.0 AS tan_pending,

    /* Chuyến */
    COUNT(DISTINCT so_chuyen) AS do_ke_hoach,
    COUNT(DISTINCT CASE
        WHEN status = 'ShipCompleted' THEN so_chuyen
    END) AS do_da_xuat,
    COUNT(DISTINCT so_chuyen)
        - COUNT(DISTINCT CASE
            WHEN status = 'ShipCompleted' THEN so_chuyen
        END) AS do_pending

FROM base
GROUP BY
    whseid,
    khu_vuc_doi_xe,
    ten_ngan_nha_van_tai
ORDER BY
    whseid,
    khu_vuc_doi_xe,
    ten_ngan_nha_van_tai;
```

**ClickHouse SQL:**

```sql
-- Shipping Progress Summary Table
SELECT
    t.whseid AS whseid,
    t.khu_vuc_doi_xe AS khu_vuc_doi_xe,
    t.ten_ngan_nha_van_tai AS ten_ngan_nha_van_tai,

    COUNT(*) AS do_ke_hoach,
    COUNT(CASE WHEN t.status = 'ShipCompleted' THEN 1 END) AS do_da_xuat,
    COUNT(*) - COUNT(CASE WHEN t.status = 'ShipCompleted' THEN 1 END) AS do_pending,

    SUM(toFloat64(t.original_cbm)) AS cbm_ke_hoach,
    SUM(CASE WHEN t.status = 'ShipCompleted' THEN toFloat64(t.shipped_cbm) ELSE 0 END) AS cbm_da_nhan,
    SUM(toFloat64(t.original_cbm))
        - SUM(CASE WHEN t.status = 'ShipCompleted' THEN toFloat64(t.shipped_cbm) ELSE 0 END) AS cbm_pending,

    SUM(toFloat64(t.original_kg)) / 1000 AS tan_ke_hoach,
    SUM(CASE WHEN t.status = 'ShipCompleted' THEN toFloat64(t.shipped_kg) ELSE 0 END) / 1000 AS tan_da_xuat,
    (SUM(toFloat64(t.original_kg))
        - SUM(CASE WHEN t.status = 'ShipCompleted' THEN toFloat64(t.shipped_kg) ELSE 0 END)) / 1000 AS tan_pending

FROM analytics_workspace.mv_flash_report AS t
WHERE 1 = 1
-- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
GROUP BY t.whseid, t.khu_vuc_doi_xe, t.ten_ngan_nha_van_tai
ORDER BY t.whseid, t.khu_vuc_doi_xe;
```

### Bảng pivot theo loại xe vận hành `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,             -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                 -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                  -- brand
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,         -- khu vực giao
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai    -- nhà vận tải
),
base AS (
    SELECT
        t.*
    FROM (
            select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
    ) as t
    CROSS JOIN params p
    WHERE 1 = 1            
        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)
SELECT
    COALESCE(loai_xe_van_hanh, 'Unclassified') AS loai_xe_van_hanh,

    /* Số chuyến */
    COUNT(DISTINCT so_chuyen) AS so_chuyen_ke_hoach,
    COUNT(DISTINCT CASE
        WHEN status = 'ShipCompleted' THEN so_chuyen
    END) AS so_chuyen_da_nhan,
    COUNT(DISTINCT so_chuyen)
        - COUNT(DISTINCT CASE
            WHEN status = 'ShipCompleted' THEN so_chuyen
        END) AS so_chuyen_pending,

    /* Tấn */
    SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
    SUM(CASE
        WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
        ELSE 0
    END) / 1000.0 AS tan_da_nhan,
    SUM(COALESCE(original_kg, 0)) / 1000.0
        - SUM(CASE
            WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
            ELSE 0
        END) / 1000.0 AS tan_pending,

    /* Khối */
    SUM(COALESCE(original_cbm, 0)) AS khoi_ke_hoach,
    SUM(CASE
        WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
        ELSE 0
    END) AS khoi_da_nhan,
    SUM(COALESCE(original_cbm, 0))
        - SUM(CASE
            WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
            ELSE 0
        END) AS khoi_pending,

    /* Đơn */
    COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
    COUNT(DISTINCT CASE
        WHEN status = 'ShipCompleted' THEN ma_don_hang
    END) AS don_da_nhan,
    COUNT(DISTINCT ma_don_hang)
        - COUNT(DISTINCT CASE
            WHEN status = 'ShipCompleted' THEN ma_don_hang
        END) AS don_pending

FROM base
GROUP BY 1
ORDER BY 1;
```

**ClickHouse SQL:**

```sql
-- Pivot by loại xe
SELECT
t.loai_xe_van_hanh AS loai_xe_van_hanh,

    COUNT(DISTINCT t.so_chuyen) AS so_chuyen_ke_hoach,
    countDistinctIf(t.so_chuyen, t.status = 'ShipCompleted') AS so_chuyen_da_nhan,
      COUNT(DISTINCT t.so_chuyen)
    - countDistinctIf(t.so_chuyen, t.status = 'ShipCompleted') AS so_chuyen_pending,

    SUM(toFloat64(t.original_kg)) / 1000 AS tan_ke_hoach,
    sumIf(toFloat64(t.shipped_kg), t.status = 'ShipCompleted') / 1000 AS tan_da_nhan,
    ( SUM(toFloat64(t.original_kg))
    - sumIf(toFloat64(t.shipped_kg), t.status = 'ShipCompleted') ) / 1000 AS tan_pending,

    SUM(toFloat64(t.original_cbm)) AS khoi_ke_hoach,
    sumIf(toFloat64(t.shipped_cbm), t.status = 'ShipCompleted') AS khoi_da_nhan,
      SUM(toFloat64(t.original_cbm))
    - sumIf(toFloat64(t.shipped_cbm), t.status = 'ShipCompleted') AS khoi_pending,

    COUNT(DISTINCT t.ma_don_hang) AS don_ke_hoach,
    countDistinctIf(t.ma_don_hang, t.status = 'ShipCompleted') AS don_da_nhan,
      COUNT(DISTINCT t.ma_don_hang)
    - countDistinctIf(t.ma_don_hang, t.status = 'ShipCompleted') AS don_pending

FROM analytics_workspace.mv_flash_report AS t
WHERE 1 = 1
-- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
GROUP BY t.loai_xe_van_hanh
ORDER BY t.loai_xe_van_hanh;
```

### Bảng pivot theo nhóm hàng `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,             -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                 -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                  -- brand
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,         -- khu vực giao
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai    -- nhà vận tải
),
base AS (
    SELECT
        t.*
    FROM (
            select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
    ) as t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)
SELECT
    COALESCE(group_of_cago, 'Unclassified') AS group_of_cago,

    /* Số chuyến */
    COUNT(DISTINCT so_chuyen) AS so_chuyen_ke_hoach,
    COUNT(DISTINCT CASE
        WHEN status = 'ShipCompleted' THEN so_chuyen
    END) AS so_chuyen_da_nhan,
    COUNT(DISTINCT so_chuyen)
        - COUNT(DISTINCT CASE
            WHEN status = 'ShipCompleted' THEN so_chuyen
        END) AS so_chuyen_pending,

    /* Tấn */
    SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
    SUM(CASE
        WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
        ELSE 0
    END) / 1000.0 AS tan_da_nhan,
    SUM(COALESCE(original_kg, 0)) / 1000.0
        - SUM(CASE
            WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
            ELSE 0
        END) / 1000.0 AS tan_pending,

    /* Khối */
    SUM(COALESCE(original_cbm, 0)) AS khoi_ke_hoach,
    SUM(CASE
        WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
        ELSE 0
    END) AS khoi_da_nhan,
    SUM(COALESCE(original_cbm, 0))
        - SUM(CASE
            WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
            ELSE 0
        END) AS khoi_pending,

    /* Đơn */
    COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
    COUNT(DISTINCT CASE
        WHEN status = 'ShipCompleted' THEN ma_don_hang
    END) AS don_da_nhan,
    COUNT(DISTINCT ma_don_hang)
        - COUNT(DISTINCT CASE
            WHEN status = 'ShipCompleted' THEN ma_don_hang
        END) AS don_pending

FROM base
GROUP BY 1
ORDER BY 1;
```

**ClickHouse SQL:**

```sql
-- Pivot by nhóm hàng
SELECT
    t.group_of_cago                               AS group_of_cago,

    COUNT(DISTINCT t.so_chuyen)                                             AS so_chuyen_ke_hoach,
    countDistinctIf(t.so_chuyen, t.status = 'ShipCompleted')                AS so_chuyen_da_nhan,
      COUNT(DISTINCT t.so_chuyen)
    - countDistinctIf(t.so_chuyen, t.status = 'ShipCompleted')              AS so_chuyen_pending,

    SUM(toFloat64(t.original_kg)) / 1000                                    AS tan_ke_hoach,
    sumIf(toFloat64(t.shipped_kg), t.status = 'ShipCompleted') / 1000       AS tan_da_nhan,
    ( SUM(toFloat64(t.original_kg))
    - sumIf(toFloat64(t.shipped_kg), t.status = 'ShipCompleted') ) / 1000   AS tan_pending,

    SUM(toFloat64(t.original_cbm))                                          AS khoi_ke_hoach,
    sumIf(toFloat64(t.shipped_cbm), t.status = 'ShipCompleted')             AS khoi_da_nhan,
      SUM(toFloat64(t.original_cbm))
    - sumIf(toFloat64(t.shipped_cbm), t.status = 'ShipCompleted')           AS khoi_pending,

    COUNT(DISTINCT t.ma_don_hang)                                           AS don_ke_hoach,
    countDistinctIf(t.ma_don_hang, t.status = 'ShipCompleted')              AS don_da_nhan,
      COUNT(DISTINCT t.ma_don_hang)
    - countDistinctIf(t.ma_don_hang, t.status = 'ShipCompleted')            AS don_pending

FROM analytics_workspace.mv_flash_report AS t
WHERE 1 = 1
-- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
GROUP BY t.group_of_cago
ORDER BY t.group_of_cago
```

### Bảng pivot theo kho `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,             -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                 -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                  -- brand
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,         -- khu vực giao
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai    -- nhà vận tải
),
base AS (
    SELECT
        t.*
    FROM (
            select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
    ) as t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)
SELECT
    COALESCE(whseid_stm, 'Unclassified') AS whseid_stm,

    /* Số chuyến */
    COUNT(DISTINCT so_chuyen) AS so_chuyen_ke_hoach,
    COUNT(DISTINCT CASE
        WHEN status = 'ShipCompleted' THEN so_chuyen
    END) AS so_chuyen_da_nhan,
    COUNT(DISTINCT so_chuyen)
        - COUNT(DISTINCT CASE
            WHEN status = 'ShipCompleted' THEN so_chuyen
        END) AS so_chuyen_pending,

    /* Tấn */
    SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
    SUM(CASE
        WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
        ELSE 0
    END) / 1000.0 AS tan_da_nhan,
    SUM(COALESCE(original_kg, 0)) / 1000.0
        - SUM(CASE
            WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
            ELSE 0
        END) / 1000.0 AS tan_pending,

    /* Khối */
    SUM(COALESCE(original_cbm, 0)) AS khoi_ke_hoach,
    SUM(CASE
        WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
        ELSE 0
    END) AS khoi_da_nhan,
    SUM(COALESCE(original_cbm, 0))
        - SUM(CASE
            WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
            ELSE 0
        END) AS khoi_pending,

    /* Đơn */
    COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
    COUNT(DISTINCT CASE
        WHEN status = 'ShipCompleted' THEN ma_don_hang
    END) AS don_da_nhan,
    COUNT(DISTINCT ma_don_hang)
        - COUNT(DISTINCT CASE
            WHEN status = 'ShipCompleted' THEN ma_don_hang
        END) AS don_pending

FROM base
GROUP BY 1
ORDER BY 1;
```

**ClickHouse SQL:**

```sql
-- Pivot by kho
SELECT
    t.whseid                                                            AS whseid,

    COUNT(DISTINCT t.so_chuyen)                                         AS so_chuyen_ke_hoach,
    countIf(t.status = 'ShipCompleted')                                 AS so_chuyen_da_nhan,
    COUNT(DISTINCT t.so_chuyen) - countIf(t.status = 'ShipCompleted')   AS so_chuyen_pending,

    SUM(t.original_kg)/1000                                             AS tan_ke_hoach,
    sumIf(t.shipped_kg, t.status = 'ShipCompleted')/1000                AS tan_da_nhan,
    SUM(t.original_kg)/1000
        - sumIf(t.shipped_kg, t.status = 'ShipCompleted')/1000          AS tan_pending,

    SUM(t.original_cbm)                                             AS khoi_ke_hoach,
    sumIf(t.shipped_cbm, t.status = 'ShipCompleted')                AS khoi_da_nhan,
    SUM(t.original_cbm)
        - sumIf(t.shipped_cbm, t.status = 'ShipCompleted')          AS khoi_pending,

    COUNT(*)                                                            AS don_ke_hoach,
    countIf(t.status = 'ShipCompleted')                                 AS don_da_nhan,
    COUNT(*) - countIf(t.status = 'ShipCompleted')                      AS don_pending

FROM analytics_workspace.mv_flash_report AS t
WHERE 1 = 1
-- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
GROUP BY whseid
ORDER BY whseid
```

### Bảng pivot theo khu vực đội xe `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,             -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                 -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                  -- brand
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,         -- khu vực giao
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai    -- nhà vận tải
),
base AS (
    SELECT
        t.*
    FROM (
            select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
    ) as t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)
SELECT
    COALESCE(khu_vuc_doi_xe, 'Unclassified') AS khu_vuc_doi_xe,

    /* Số chuyến */
    COUNT(DISTINCT so_chuyen) AS so_chuyen_ke_hoach,
    COUNT(DISTINCT CASE
        WHEN status = 'ShipCompleted' THEN so_chuyen
    END) AS so_chuyen_da_nhan,
    COUNT(DISTINCT so_chuyen)
        - COUNT(DISTINCT CASE
            WHEN status = 'ShipCompleted' THEN so_chuyen
        END) AS so_chuyen_pending,

    /* Tấn */
    SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
    SUM(CASE
        WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
        ELSE 0
    END) / 1000.0 AS tan_da_nhan,
    SUM(COALESCE(original_kg, 0)) / 1000.0
        - SUM(CASE
            WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
            ELSE 0
        END) / 1000.0 AS tan_pending,

    /* Khối */
    SUM(COALESCE(original_cbm, 0)) AS khoi_ke_hoach,
    SUM(CASE
        WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
        ELSE 0
    END) AS khoi_da_nhan,
    SUM(COALESCE(original_cbm, 0))
        - SUM(CASE
            WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
            ELSE 0
        END) AS khoi_pending,

    /* Đơn */
    COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
    COUNT(DISTINCT CASE
        WHEN status = 'ShipCompleted' THEN ma_don_hang
    END) AS don_da_nhan,
    COUNT(DISTINCT ma_don_hang)
        - COUNT(DISTINCT CASE
            WHEN status = 'ShipCompleted' THEN ma_don_hang
        END) AS don_pending

FROM base
GROUP BY 1
ORDER BY 1;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*
    FROM (
        /* Nhánh 1: Ép kiểu toFloat64 để đồng nhất dữ liệu */
        SELECT 
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, whseid_stm,
            so_chuyen, ma_don_hang,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg,
            toFloat64(original_cbm) AS original_cbm,
            toFloat64(shipped_cbm) AS shipped_cbm
        FROM analytics_workspace.mv_flash_report

        UNION ALL

        /* Nhánh 2: Phải khớp hoàn toàn thứ tự và kiểu dữ liệu với Nhánh 1 */
        SELECT 
            thoi_gian_gui_thau, etd_chuyen_gui_thau, group_name, whseid, brand, 
            ten_ngan_nha_van_tai, khu_vuc_doi_xe, status, whseid_stm,
            so_chuyen, ma_don_hang,
            toFloat64(original_kg) AS original_kg,
            toFloat64(shipped_kg) AS shipped_kg,
            toFloat64(original_cbm) AS original_cbm,
            toFloat64(shipped_cbm) AS shipped_cbm
        FROM analytics_workspace.mv_dropped_report
    ) AS t
    WHERE 1 = 1
-- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
)
SELECT
    khu_vuc_doi_xe                                       AS khu_vuc_doi_xe,                                             
                                                                                                             
    /* Số chuyến */                                                                                          
    countDistinct(so_chuyen)                                                    AS so_chuyen_ke_hoach,       
    countDistinct(if(status = 'ShipCompleted', so_chuyen, NULL))                AS so_chuyen_da_nhan,        
      countDistinct(so_chuyen)                                                                               
    - countDistinct(if(status = 'ShipCompleted', so_chuyen, NULL))              AS so_chuyen_pending,        
                                                                                                             
    /* Tấn */                                                                                                
    SUM(original_kg) / 1000.0                                                   AS tan_ke_hoach,             
    SUM(if(status = 'ShipCompleted', shipped_kg, 0)) / 1000.0                   AS tan_da_nhan,              
    ( SUM(original_kg)                                                                                       
    - SUM(if(status = 'ShipCompleted', shipped_kg, 0)) ) / 1000.0               AS tan_pending,              
                                                                                                             
    /* Khối */                                                                                               
    SUM(original_cbm)                                                           AS khoi_ke_hoach,            
    SUM(if(status = 'ShipCompleted', shipped_cbm, 0))                           AS khoi_da_nhan,             
      SUM(original_cbm)                                                                                      
    - SUM(if(status = 'ShipCompleted', shipped_cbm, 0))                         AS khoi_pending,             
                                                                                                             
    /* Đơn */                                                                                                
    countDistinct(ma_don_hang)                                                  AS don_ke_hoach,             
    countDistinct(if(status = 'ShipCompleted', ma_don_hang, NULL))              AS don_da_nhan,              
      countDistinct(ma_don_hang)                                                                             
    - countDistinct(if(status = 'ShipCompleted', ma_don_hang, NULL))            AS don_pending               
FROM base
GROUP BY 1
ORDER BY 1;
```

### Report raw data `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'Ngày gửi thầu'::VARCHAR AS p_loai_ngay,

        '2026-03-19 00:00:00'::TIMESTAMP AS p_from,
        '2026-03-28 23:59:59'::TIMESTAMP AS p_to,

        'ALL'::VARCHAR AS p_group_name,             -- kênh bán hàng
        'ALL'::VARCHAR AS p_whseid,                 -- kho lấy hàng
        'ALL'::VARCHAR AS p_brand,                  -- brand
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,         -- khu vực giao
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai    -- nhà vận tải
),
base AS (
    SELECT
        t.*
    FROM (
            select *
                from reporting_schema.mv_flash_report

                union all

                select *
                from reporting_schema.mv_dropped_report
    ) as t
    CROSS JOIN params p
    WHERE 1 = 1

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE >= p.p_from::DATE

        AND (
            CASE
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN t."thoi_gian_gui_thau"
                WHEN p.p_loai_ngay = 'ETD gửi thầu' THEN t."etd_chuyen_gui_thau"
                ELSE t.thoi_gian_gui_thau
            END
        )::DATE <= p.p_to::DATE

        AND (
            p.p_group_name = 'ALL'
            OR COALESCE(t.group_name, 'Unclassified') = p.p_group_name
        )

        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        AND (
            p.p_brand = 'ALL'
            OR COALESCE(t.brand, 'Unclassified') = p.p_brand
        )

        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )

        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
)
SELECT
    COALESCE(khu_vuc_doi_xe, 'Unclassified') AS khu_vuc_doi_xe,

    /* Số chuyến */
    COUNT(DISTINCT so_chuyen) AS so_chuyen_ke_hoach,
    COUNT(DISTINCT CASE
        WHEN status = 'ShipCompleted' THEN so_chuyen
    END) AS so_chuyen_da_nhan,
    COUNT(DISTINCT so_chuyen)
        - COUNT(DISTINCT CASE
            WHEN status = 'ShipCompleted' THEN so_chuyen
        END) AS so_chuyen_pending,

    /* Tấn */
    SUM(COALESCE(original_kg, 0)) / 1000.0 AS tan_ke_hoach,
    SUM(CASE
        WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
        ELSE 0
    END) / 1000.0 AS tan_da_nhan,
    SUM(COALESCE(original_kg, 0)) / 1000.0
        - SUM(CASE
            WHEN status = 'ShipCompleted' THEN COALESCE(shipped_kg, 0)
            ELSE 0
        END) / 1000.0 AS tan_pending,

    /* Khối */
    SUM(COALESCE(original_cbm, 0)) AS khoi_ke_hoach,
    SUM(CASE
        WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
        ELSE 0
    END) AS khoi_da_nhan,
    SUM(COALESCE(original_cbm, 0))
        - SUM(CASE
            WHEN status = 'ShipCompleted' THEN COALESCE(shipped_cbm, 0)
            ELSE 0
        END) AS khoi_pending,

    /* Đơn */
    COUNT(DISTINCT ma_don_hang) AS don_ke_hoach,
    COUNT(DISTINCT CASE
        WHEN status = 'ShipCompleted' THEN ma_don_hang
    END) AS don_da_nhan,
    COUNT(DISTINCT ma_don_hang)
        - COUNT(DISTINCT CASE
            WHEN status = 'ShipCompleted' THEN ma_don_hang
        END) AS don_pending

FROM base
GROUP BY 1
ORDER BY 1;
```

**ClickHouse SQL:**

```sql
SELECT
  t.*
FROM analytics_workspace.mv_flash_report AS t
WHERE 1 = 1
-- Date filter
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETD gửi thầu (đơn)'
            THEN t.etd_chuyen_gui_thau
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

-- Sales channel/Group name
AND if(
    arraySort([{{group_name}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group_name IN ({{group_name}})
)

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)

-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)
```

---

## OTIF

### Tổng đơn `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                  -- kho lấy hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,          -- khu vực đội xe
        'ALL'::VARCHAR AS p_group_of_cago,          -- nhóm hàng
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,   -- nhà vận tải
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,  -- eta_giao_hang_cho_npp / ata_den / ALL
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,                    -- từ ngày
        '2999-12-31 23:59:59'::DATE AS p_den_ngay                    -- đến ngày
),
filtered_data AS (
    SELECT t.*
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Transporter
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR t.ten_ngan_nha_van_tai = p.p_ten_ngan_nha_van_tai
        )

        -- Filter Area
        AND (
            p.p_khu_vuc_doi_xe= 'ALL'
            OR t.khu_vuc_doi_xe= p.p_khu_vuc_doi_xe
        )

        -- Filter Date Type + Date Range
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
)

select
    COUNT("so") AS total_so,

    COUNT(CASE WHEN ontime_status = 'Ontime' THEN "so" END) AS ontime_so,
    ROUND(
        100.0 * COUNT(CASE WHEN ontime_status = 'Ontime' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_ontime,

    COUNT(CASE WHEN infull_status = 'Infull' THEN "so" END) AS infull_so,
    ROUND(
        100.0 * COUNT(CASE WHEN infull_status = 'Infull' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_infull,

    COUNT(CASE WHEN otif_status = 'OTIF' THEN "so" END) AS otif_so,
    ROUND(
        100.0 * COUNT(CASE WHEN otif_status = 'OTIF' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_otif
FROM filtered_data;
```

**ClickHouse SQL:**

```sql
WITH filtered_data AS (
    SELECT t.*
    FROM analytics_workspace.mv_otif AS t
    WHERE 1 = 1

-- Khi tính pctOntime / pctInfull / pctOtif:
AND ontime_status != 'Không có dữ liệu STM'


-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)


-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)


-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)


-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)


    -- Date filter (fix robust)
    [[ AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
) ]]
)

SELECT
    uniqExact(so)                                AS total_so,

    countIf(ontime_status = 'Ontime')        AS ontime_so,
    round(
        100.0 * countIf(ontime_status = 'Ontime')
        / nullIf(count(so), 0),
        2
    )                                        AS pct_ontime,

    countIf(infull_status = 'Infull')        AS infull_so,
    round(
        100.0 * countIf(infull_status = 'Infull')
        / nullIf(count(so), 0),
        2
    )                                        AS pct_infull,

    countIf(otif_status = 'OTIF')            AS otif_so,
    round(
        100.0 * countIf(otif_status = 'OTIF')
        / nullIf(count(so), 0),
        2
    )                                        AS pct_otif
FROM filtered_data
```

### % Ontime `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                  -- kho lấy hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,          -- khu vực đội xe
        'ALL'::VARCHAR AS p_group_of_cago,          -- nhóm hàng
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,   -- nhà vận tải
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,  -- eta_giao_hang_cho_npp / ata_den / ALL
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,                    -- từ ngày
        '2999-12-31 23:59:59'::DATE AS p_den_ngay                    -- đến ngày
),
filtered_data AS (
    SELECT t.*
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Transporter
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR t.ten_ngan_nha_van_tai = p.p_ten_ngan_nha_van_tai
        )

        -- Filter Area
        AND (
            p.p_khu_vuc_doi_xe= 'ALL'
            OR t.khu_vuc_doi_xe= p.p_khu_vuc_doi_xe
        )

        -- Filter Date Type + Date Range
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
)

select
    COUNT("so") AS total_so,

    COUNT(CASE WHEN ontime_status = 'Ontime' THEN "so" END) AS ontime_so,
    ROUND(
        100.0 * COUNT(CASE WHEN ontime_status = 'Ontime' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_ontime,

    COUNT(CASE WHEN infull_status = 'Infull' THEN "so" END) AS infull_so,
    ROUND(
        100.0 * COUNT(CASE WHEN infull_status = 'Infull' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_infull,

    COUNT(CASE WHEN otif_status = 'OTIF' THEN "so" END) AS otif_so,
    ROUND(
        100.0 * COUNT(CASE WHEN otif_status = 'OTIF' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_otif
FROM filtered_data;
```

**ClickHouse SQL:**

```sql
WITH filtered_data AS (
    SELECT t.*
    FROM analytics_workspace.mv_otif AS t
    WHERE 1 = 1

-- Khi tính pctOntime / pctInfull / pctOtif:
AND ontime_status != 'Không có dữ liệu STM'


-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)


-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)


-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)


-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)


    -- Date filter (fix robust)
    [[ AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
) ]]
)

SELECT
    uniqExact(so)                                AS total_so,

    countIf(ontime_status = 'Ontime')        AS ontime_so,
    round(
        100.0 * countIf(ontime_status = 'Ontime')
        / nullIf(count(so), 0),
        2
    )                                        AS pct_ontime,

    countIf(infull_status = 'Infull')        AS infull_so,
    round(
        100.0 * countIf(infull_status = 'Infull')
        / nullIf(count(so), 0),
        2
    )                                        AS pct_infull,

    countIf(otif_status = 'OTIF')            AS otif_so,
    round(
        100.0 * countIf(otif_status = 'OTIF')
        / nullIf(count(so), 0),
        2
    )                                        AS pct_otif
FROM filtered_data
```

### % Infull `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                  -- kho lấy hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,          -- khu vực đội xe
        'ALL'::VARCHAR AS p_group_of_cago,          -- nhóm hàng
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,   -- nhà vận tải
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,  -- eta_giao_hang_cho_npp / ata_den / ALL
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,                    -- từ ngày
        '2999-12-31 23:59:59'::DATE AS p_den_ngay                    -- đến ngày
),
filtered_data AS (
    SELECT t.*
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Transporter
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR t.ten_ngan_nha_van_tai = p.p_ten_ngan_nha_van_tai
        )

        -- Filter Area
        AND (
            p.p_khu_vuc_doi_xe= 'ALL'
            OR t.khu_vuc_doi_xe= p.p_khu_vuc_doi_xe
        )

        -- Filter Date Type + Date Range
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
)

select
    COUNT("so") AS total_so,

    COUNT(CASE WHEN ontime_status = 'Ontime' THEN "so" END) AS ontime_so,
    ROUND(
        100.0 * COUNT(CASE WHEN ontime_status = 'Ontime' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_ontime,

    COUNT(CASE WHEN infull_status = 'Infull' THEN "so" END) AS infull_so,
    ROUND(
        100.0 * COUNT(CASE WHEN infull_status = 'Infull' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_infull,

    COUNT(CASE WHEN otif_status = 'OTIF' THEN "so" END) AS otif_so,
    ROUND(
        100.0 * COUNT(CASE WHEN otif_status = 'OTIF' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_otif
FROM filtered_data;
```

**ClickHouse SQL:**

```sql
WITH filtered_data AS (
    SELECT t.*
    FROM analytics_workspace.mv_otif AS t
    WHERE 1 = 1

-- Khi tính pctOntime / pctInfull / pctOtif:
AND ontime_status != 'Không có dữ liệu STM'


-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)


-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)


-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)


-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)


    -- Date filter (fix robust)
    [[ AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
) ]]
)

SELECT
    uniqExact(so)                                AS total_so,

    countIf(ontime_status = 'Ontime')        AS ontime_so,
    round(
        100.0 * countIf(ontime_status = 'Ontime')
        / nullIf(count(so), 0),
        2
    )                                        AS pct_ontime,

    countIf(infull_status = 'Infull')        AS infull_so,
    round(
        100.0 * countIf(infull_status = 'Infull')
        / nullIf(count(so), 0),
        2
    )                                        AS pct_infull,

    countIf(otif_status = 'OTIF')            AS otif_so,
    round(
        100.0 * countIf(otif_status = 'OTIF')
        / nullIf(count(so), 0),
        2
    )                                        AS pct_otif
FROM filtered_data
```

### % OTIF `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                  -- kho lấy hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,          -- khu vực đội xe
        'ALL'::VARCHAR AS p_group_of_cago,          -- nhóm hàng
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,   -- nhà vận tải
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,  -- eta_giao_hang_cho_npp / ata_den / ALL
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,                    -- từ ngày
        '2999-12-31 23:59:59'::DATE AS p_den_ngay                    -- đến ngày
),
filtered_data AS (
    SELECT t.*
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Transporter
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR t.ten_ngan_nha_van_tai = p.p_ten_ngan_nha_van_tai
        )

        -- Filter Area
        AND (
            p.p_khu_vuc_doi_xe= 'ALL'
            OR t.khu_vuc_doi_xe= p.p_khu_vuc_doi_xe
        )

        -- Filter Date Type + Date Range
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
)

select
    COUNT("so") AS total_so,

    COUNT(CASE WHEN ontime_status = 'Ontime' THEN "so" END) AS ontime_so,
    ROUND(
        100.0 * COUNT(CASE WHEN ontime_status = 'Ontime' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_ontime,

    COUNT(CASE WHEN infull_status = 'Infull' THEN "so" END) AS infull_so,
    ROUND(
        100.0 * COUNT(CASE WHEN infull_status = 'Infull' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_infull,

    COUNT(CASE WHEN otif_status = 'OTIF' THEN "so" END) AS otif_so,
    ROUND(
        100.0 * COUNT(CASE WHEN otif_status = 'OTIF' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_otif
FROM filtered_data;
```

**ClickHouse SQL:**

```sql
WITH filtered_data AS (
    SELECT t.*
    FROM analytics_workspace.mv_otif AS t
    WHERE 1 = 1

-- Khi tính pctOntime / pctInfull / pctOtif:
AND ontime_status != 'Không có dữ liệu STM'


-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)


-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)


-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)


-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)


    -- Date filter (fix robust)
    [[ AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
) ]]
)

SELECT
    uniqExact(so)                                AS total_so,

    countIf(ontime_status = 'Ontime')        AS ontime_so,
    round(
        100.0 * countIf(ontime_status = 'Ontime')
        / nullIf(count(so), 0),
        2
    )                                        AS pct_ontime,

    countIf(infull_status = 'Infull')        AS infull_so,
    round(
        100.0 * countIf(infull_status = 'Infull')
        / nullIf(count(so), 0),
        2
    )                                        AS pct_infull,

    countIf(otif_status = 'OTIF')            AS otif_so,
    round(
        100.0 * countIf(otif_status = 'OTIF')
        / nullIf(count(so), 0),
        2
    )                                        AS pct_otif
FROM filtered_data
```

### OTIF/ Ontime/ Infull theo khu vực `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                  -- kho lấy hàng
        'ALL'::VARCHAR AS p_group_of_cago,          -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,          -- khu vực đội xe
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,   -- nhà vận tải
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,  -- eta_giao_hang_cho_npp / ata_den / ALL
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,                    -- từ ngày
        '2999-12-31 23:59:59'::DATE AS p_den_ngay                    -- đến ngày
),
filtered_data AS (
    SELECT t.*
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Transporter
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR t.ten_ngan_nha_van_tai = p.p_ten_ngan_nha_van_tai
        )

        -- Filter Area
        AND (
            p.p_khu_vuc_doi_xe= 'ALL'
            OR t.khu_vuc_doi_xe= p.p_khu_vuc_doi_xe
        )

        -- Filter Date Type + Date Range
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
)

SELECT
    COALESCE(khu_vuc_doi_xe, NULL) AS khu_vuc_doi_xe,
    COUNT("so") AS total_so,

    COUNT(CASE WHEN ontime_status = 'Ontime' THEN "so" END) AS ontime_so,
    ROUND(
        100.0 * COUNT(CASE WHEN ontime_status = 'Ontime' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_ontime,

    COUNT(CASE WHEN infull_status = 'Infull' THEN "so" END) AS infull_so,
    ROUND(
        100.0 * COUNT(CASE WHEN infull_status = 'Infull' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_infull,

    COUNT(CASE WHEN otif_status = 'OTIF' THEN "so" END) AS otif_so,
    ROUND(
        100.0 * COUNT(CASE WHEN otif_status = 'OTIF' THEN "so" END)
        / NULLIF(COUNT("so"), 0),
        2
    ) AS pct_otif
FROM filtered_data
GROUP BY 1
ORDER BY 1;
```

**ClickHouse SQL:**

```sql
WITH filtered_data AS (
    SELECT t.*
    FROM analytics_workspace.mv_otif AS t
WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)


-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)


-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)


-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)


    -- Date filter (fix robust)
    [[ AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
) ]]

)
SELECT
    khu_vuc_doi_xe,
    COUNT(so)                                              AS total_so,
    countIf(ontime_status = 'Ontime')                     AS ontime_so,
    round(
        100.0 * countIf(ontime_status = 'Ontime')
        / nullIf(COUNT(so), 0),
        2
    )                                                      AS pct_ontime,
    countIf(infull_status = 'Infull')                     AS infull_so,
    round(
        100.0 * countIf(infull_status = 'Infull')
        / nullIf(COUNT(so), 0),
        2
    )                                                      AS pct_infull,
    countIf(otif_status = 'OTIF')                         AS otif_so,
    round(
        100.0 * countIf(otif_status = 'OTIF')
        / nullIf(COUNT(so), 0),
        2
    )                                                      AS pct_otif
FROM filtered_data
-- Khi tính pctOntime / pctInfull / pctOtif:
WHERE ontime_status != 'Không có dữ liệu STM'
GROUP BY 1
ORDER BY 1
```

### Phân rã nguyên nhân fail ontime `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                  -- kho lấy hàng
        'ALL'::VARCHAR AS p_group_of_cago,          -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,          -- khu vực đội xe
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,   -- nhà vận tải
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,  -- eta_giao_hang_cho_npp / ata_den / ALL
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,                    -- từ ngày
        '2999-12-31 23:59:59'::DATE AS p_den_ngay                    -- đến ngày
),

filtered_data AS (
    SELECT t.*
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Transporter
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR t.ten_ngan_nha_van_tai = p.p_ten_ngan_nha_van_tai
        )

        -- Filter Area
        AND (
            p.p_khu_vuc_doi_xe= 'ALL'
            OR t.khu_vuc_doi_xe= p.p_khu_vuc_doi_xe
        )

        -- Filter Date Type + Date Range
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
),

fail_ontime AS (
    SELECT
        t."so",
        COALESCE(t.not_ontime_reason, '') AS not_ontime_reason
    FROM filtered_data t
    WHERE t.ontime_status = 'Failed Ontime'
)

SELECT
    not_ontime_reason,
    COUNT(DISTINCT "so") AS fail_ontime_so
FROM fail_ontime
GROUP BY 1
ORDER BY 2 DESC, 1;
```

**ClickHouse SQL:**

```sql
SELECT

    coalesce(t.not_ontime_reason, '') AS reason,

    uniqExact(t.so)                   AS fail_so

FROM analytics_workspace.mv_otif t

WHERE 1 = 1

-- Warehouse

AND if(

    arraySort([{{whseid}}]) = (

        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse

    ),

    1 = 1,

    t.whseid IN ({{whseid}})

)





-- Cargo Group

AND if(

    arraySort([{{group_of_cargo}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand

    ),

    1 = 1,

    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})

)





-- Transporter

AND if(

    arraySort([{{transporter}}]) = (

        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor

    ),

    1 = 1,

    t.ten_ngan_nha_van_tai IN ({{transporter}})

)





-- Area

AND if(

    arraySort([{{area}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region

    ),

    1 = 1,

    t.khu_vuc_doi_xe IN ({{area}})

)





    -- Date filter (fix robust)

    [[ AND (

    toDate(

    CASE

        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'

            THEN t.eta_giao_hang_cho_npp

        WHEN {{date_type}} = 'ATA chi tiết chuyến'

            THEN t.ata_den

        WHEN {{date_type}} = 'Ngày gửi thầu'

            THEN t.thoi_gian_gui_thau

        WHEN {{date_type}} = 'Ngày vào kho'

            THEN t.gio_dang_tai

        WHEN {{date_type}} = 'Ngày duyệt chuyến'

            THEN t.ngay_duyet_chuyen

        WHEN {{date_type}} = 'Ngày GI'

            THEN t.ngay_gi

        WHEN {{date_type}} = 'Ngày tạo đơn hàng'

            THEN t.ngay_tao_don

    END)

    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))

        AND toDate(coalesce({{to_date}},   '2999-12-31'))

) ]]

AND t.ontime_status = 'Failed Ontime'

-- Khi tính pctOntime / pctInfull / pctOtif:

AND ontime_status != 'Không có dữ liệu STM'

GROUP BY 1

ORDER BY 2 DESC, 1;
```

### Phân rã nguyên nhân fail infull `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                  -- kho lấy hàng
        'ALL'::VARCHAR AS p_group_of_cago,          -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,          -- khu vực đội xe
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,   -- nhà vận tải
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,  -- eta_giao_hang_cho_npp / ata_den / ALL
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,                    -- từ ngày
        '2999-12-31 23:59:59'::DATE AS p_den_ngay                    -- đến ngày
),

filtered_data AS (
    SELECT t.*
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Transporter
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR t.ten_ngan_nha_van_tai = p.p_ten_ngan_nha_van_tai
        )

        -- Filter Area
        AND (
            p.p_khu_vuc_doi_xe= 'ALL'
            OR t.khu_vuc_doi_xe= p.p_khu_vuc_doi_xe
        )

        -- Filter Date Type + Date Range
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
),

fail_infull AS (
    SELECT
        t."so",
        COALESCE(t.not_infull_reason, '') AS not_infull_reason
    FROM filtered_data t
    WHERE t.infull_status = 'Failed Infull'
)

SELECT
    not_infull_reason,
    COUNT(DISTINCT "so") AS fail_infull_so
FROM fail_infull
GROUP BY 1
ORDER BY 2 DESC, 1;
```

**ClickHouse SQL:**

```sql
SELECT

    coalesce(t.not_infull_reason, '') AS reason,

    uniqExact(t.so)                   AS fail_so



FROM analytics_workspace.mv_otif t

WHERE 1 = 1

-- Warehouse

AND if(

    arraySort([{{whseid}}]) = (

        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse

    ),

    1 = 1,

    t.whseid IN ({{whseid}})

)





-- Cargo Group

AND if(

    arraySort([{{group_of_cargo}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand

    ),

    1 = 1,

    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})

)





-- Transporter

AND if(

    arraySort([{{transporter}}]) = (

        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor

    ),

    1 = 1,

    t.ten_ngan_nha_van_tai IN ({{transporter}})

)





-- Area

AND if(

    arraySort([{{area}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region

    ),

    1 = 1,

    t.khu_vuc_doi_xe IN ({{area}})

)





    -- Date filter (fix robust)

    [[ AND (

    toDate(

    CASE

        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'

            THEN t.eta_giao_hang_cho_npp

        WHEN {{date_type}} = 'ATA chi tiết chuyến'

            THEN t.ata_den

        WHEN {{date_type}} = 'Ngày gửi thầu'

            THEN t.thoi_gian_gui_thau

        WHEN {{date_type}} = 'Ngày vào kho'

            THEN t.gio_dang_tai

        WHEN {{date_type}} = 'Ngày duyệt chuyến'

            THEN t.ngay_duyet_chuyen

        WHEN {{date_type}} = 'Ngày GI'

            THEN t.ngay_gi

        WHEN {{date_type}} = 'Ngày tạo đơn hàng'

            THEN t.ngay_tao_don

    END)

    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))

        AND toDate(coalesce({{to_date}},   '2999-12-31'))

) ]]

AND t.infull_status = 'Failed Infull'

-- Khi tính pctOntime / pctInfull / pctOtif:

AND ontime_status != 'Không có dữ liệu STM'

GROUP BY 1

ORDER BY 2 DESC, 1
```

### Report raw data `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                    -- kho lấy hàng
        'ALL'::VARCHAR AS p_group_of_cago,            -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,          -- khu vực đội xe
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,     -- nhà vận tải
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,  -- eta_giao_hang_cho_npp / ata_den / ALL
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,                      -- từ ngày
        '2999-12-31 23:59:59'::DATE AS p_den_ngay                      -- đến ngày
),

filtered_data AS (
    SELECT
        t.*
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1

        -- Filter warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter cargo group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter transporter
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR t.ten_ngan_nha_van_tai = p.p_ten_ngan_nha_van_tai
        )

        -- Filter Area
        AND (
            p.p_khu_vuc_doi_xe= 'ALL'
            OR t.khu_vuc_doi_xe= p.p_khu_vuc_doi_xe
        )

        -- Filter date type + date range
        AND (
            p.p_loai_ngay = 'ALL'
            OR (
                CASE
                    WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                    WHEN p.p_loai_ngay = 'ATA chi tiết chuyên' THEN CAST(t.ata_den AS DATE)
                    ELSE NULL
                END
            ) BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                  AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
)

SELECT
    t.*
FROM filtered_data t
ORDER BY
    t.so,
    t.ngay_tao_chuyen,
    t.eta_giao_hang_cho_npp;
```

**ClickHouse SQL:**

```sql
SELECT *

FROM analytics_workspace.mv_otif t
WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)


-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)


-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)


-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)


    -- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

### %OTIF và khối lượng đơn theo thời gian `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,                   -- kho lấy hàng
        'ALL'::VARCHAR AS p_group_of_cago,           -- nhóm hàng
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,          -- khu vực đội xe
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,    -- nhà vận tải
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,  -- eta_giao_hang_cho_npp / ata_den
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,                     -- từ ngày
        '2999-12-31 23:59:59'::DATE AS p_den_ngay                     -- đến ngày
),

filtered_data AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
            ELSE NULL
        END AS selected_date
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1
        -- Filter Warehouse
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )

        -- Filter Cargo Group
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )

        -- Filter Transporter
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR t.ten_ngan_nha_van_tai = p.p_ten_ngan_nha_van_tai
        )

        -- Filter Area
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR t.khu_vuc_doi_xe = p.p_khu_vuc_doi_xe
        )

        -- Filter Date Range theo loại ngày được chọn
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
),

agg_otif AS (
    SELECT
        selected_date AS day,
        DATE_TRUNC('week', selected_date)::DATE AS week,
        DATE_TRUNC('month', selected_date)::DATE AS month,
        COUNT(DISTINCT so) AS tong_so_don,
        COUNT(DISTINCT CASE WHEN otif_status = 'OTIF' THEN so END) AS so_don_dat_otif
    FROM filtered_data
    WHERE selected_date IS NOT NULL
    GROUP BY 1, 2, 3
)

SELECT
    day,
    week,
    month,
    tong_so_don,
    so_don_dat_otif,
    CASE
        WHEN tong_so_don = 0 THEN 0
        ELSE so_don_dat_otif::DECIMAL(18,4) / tong_so_don
    END AS pct_otif
FROM agg_otif
ORDER BY day;
```

**ClickHouse SQL:**

```sql
SELECT
    CAST(selected_date, 'Date')                    AS day,
    CAST(toStartOfWeek(selected_date, 1), 'Date')  AS week,
    CAST(toStartOfMonth(selected_date), 'Date')    AS month,
    uniqExact(so)                                                    AS total_so,
    uniqExactIf(so, otif_status = 'OTIF')                           AS otif_so,
    if(
        uniqExact(so) = 0,
        0,
        toFloat64(uniqExactIf(so, otif_status = 'OTIF')) * 100
        / uniqExact(so)
    )                                                                AS pct_otif
FROM (
    SELECT
        t.*,
       CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
        END AS selected_date
    FROM analytics_workspace.mv_otif t
    WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)


-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)


-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)


-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)


    -- Date filter (fix robust)
    [[ AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
) ]]
) t
WHERE selected_date IS NOT NULL
-- Khi tính pctOntime / pctInfull / pctOtif:
AND ontime_status != 'Không có dữ liệu STM'
GROUP BY
    day,
    week,
    month
ORDER BY day;
```

### %OTIF chiều vận hành `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_group_of_cago,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,   -- eta_giao_hang_cho_npp / ata_den
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,
        '2999-12-31 23:59:59'::DATE AS p_den_ngay
),

filtered_data AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
            ELSE NULL
        END AS selected_date
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, 'Unclassified') = p.p_group_of_cago
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
),

agg_report AS (
    SELECT
        COALESCE(ten_ngan_nha_van_tai, '') AS nha_van_tai,
        COALESCE(group_name, '') AS kenh_ban_hang,
        COALESCE(group_of_cago, '') AS nhom_hang,
        COALESCE(khu_vuc_doi_xe, '') AS khu_vuc_doi_xe,

        COUNT(DISTINCT so) AS tong_so_don,

        COUNT(DISTINCT CASE WHEN otif_status = 'OTIF' THEN so END) AS so_don_otif,
        COUNT(DISTINCT CASE WHEN ontime_status = 'Ontime' THEN so END) AS so_don_ontime,
        COUNT(DISTINCT CASE WHEN infull_status = 'Infull' THEN so END) AS so_don_infull
    FROM filtered_data
    WHERE selected_date IS NOT NULL
    GROUP BY 1, 2, 3, 4
)

SELECT
    nha_van_tai AS "Nhà vận tải",
    kenh_ban_hang AS "Kênh bán hàng",
    nhom_hang AS "Nhóm hàng",
    khu_vuc_doi_xe AS "Khu vực đội xe",
    tong_so_don AS "Tổng số đơn",

    so_don_otif AS "Số đơn OTIF",
    ROUND(
        CASE
            WHEN tong_so_don = 0 THEN 0
            ELSE so_don_otif::DECIMAL(18,4) / tong_so_don
        END
    , 4) AS "%OTIF",

    so_don_ontime AS "Số đơn Ontime",
    ROUND(
        CASE
            WHEN tong_so_don = 0 THEN 0
            ELSE so_don_ontime::DECIMAL(18,4) / tong_so_don
        END
    , 4) AS "%Ontime",

    so_don_infull AS "Số đơn Infull",
    ROUND(
        CASE
            WHEN tong_so_don = 0 THEN 0
            ELSE so_don_infull::DECIMAL(18,4) / tong_so_don
        END
    , 4) AS "%Infull"

FROM agg_report
ORDER BY 1, 2, 3, 4;
```

**ClickHouse SQL:**

```sql
SELECT

    COALESCE(t.ten_ngan_nha_van_tai, '') AS transporter,

    COALESCE(t.group_name, '')           AS group_name,

    COALESCE(t.group_of_cago, '')        AS group_of_cargo,

    COALESCE(t.khu_vuc_doi_xe, '')       AS area,



    COUNT(DISTINCT t.so) AS total_so,



    COUNT(DISTINCT CASE WHEN t.otif_status = 'OTIF' THEN t.so END) AS otif_so,

    ROUND(

        CASE WHEN COUNT(DISTINCT t.so) = 0 THEN 0

            ELSE CAST(COUNT(DISTINCT CASE WHEN t.otif_status = 'OTIF' THEN t.so END) AS FLOAT)*100

                / COUNT(DISTINCT t.so)

        END,

        2

    ) AS pct_otif,



    COUNT(DISTINCT CASE WHEN t.ontime_status = 'Ontime' THEN t.so END) AS ontime_so,

    ROUND(

        CASE WHEN COUNT(DISTINCT t.so) = 0 THEN 0

            ELSE CAST(COUNT(DISTINCT CASE WHEN t.ontime_status = 'Ontime' THEN t.so END) AS FLOAT)*100

                / COUNT(DISTINCT t.so)

        END,

        2

    ) AS pct_ontime,



    COUNT(DISTINCT CASE WHEN t.infull_status = 'Infull' THEN t.so END) AS infull_so,

    ROUND(

        CASE WHEN COUNT(DISTINCT t.so) = 0 THEN 0

            ELSE CAST(COUNT(DISTINCT CASE WHEN t.infull_status = 'Infull' THEN t.so END) AS FLOAT)*100

                / COUNT(DISTINCT t.so)

        END,

        2

    ) AS pct_infull



FROM analytics_workspace.mv_otif t

WHERE 1 = 1



-- Warehouse

AND if(

    arraySort([{{whseid}}]) = (

        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse

    ),

    1 = 1,

    t.whseid IN ({{whseid}})

)





-- Cargo Group

AND if(

    arraySort([{{group_of_cargo}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand

    ),

    1 = 1,

    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})

)





-- Transporter

AND if(

    arraySort([{{transporter}}]) = (

        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor

    ),

    1 = 1,

    t.ten_ngan_nha_van_tai IN ({{transporter}})

)





-- Area

AND if(

    arraySort([{{area}}]) = (

        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region

    ),

    1 = 1,

    t.khu_vuc_doi_xe IN ({{area}})

)





    -- Date filter (fix robust)

    [[ AND (

    toDate(

    CASE

        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'

            THEN t.eta_giao_hang_cho_npp

        WHEN {{date_type}} = 'ATA chi tiết chuyến'

            THEN t.ata_den

        WHEN {{date_type}} = 'Ngày gửi thầu'

            THEN t.thoi_gian_gui_thau

        WHEN {{date_type}} = 'Ngày vào kho'

            THEN t.gio_dang_tai

        WHEN {{date_type}} = 'Ngày duyệt chuyến'

            THEN t.ngay_duyet_chuyen

        WHEN {{date_type}} = 'Ngày GI'

            THEN t.ngay_gi

        WHEN {{date_type}} = 'Ngày tạo đơn hàng'

            THEN t.ngay_tao_don

    END)

    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))

        AND toDate(coalesce({{to_date}},   '2999-12-31'))

) ]]

-- Khi tính pctOntime / pctInfull / pctOtif:

AND ontime_status != 'Không có dữ liệu STM'

GROUP BY

    1,2,3,4



ORDER BY

    1,2,3,4
```

### Report fail ontime, fail infull `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_group_of_cago,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,   -- eta_giao_hang_cho_npp / ata_den
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,
        '2999-12-31 23:59:59'::DATE AS p_den_ngay
),

filtered_data AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
            ELSE NULL
        END AS selected_date
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, '') = p.p_group_of_cago
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, '') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, '') = p.p_khu_vuc_doi_xe
        )
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
),

agg_report AS (
    SELECT
        COALESCE(ten_ngan_nha_van_tai, '') AS nha_van_tai,
        COALESCE(group_name, '') AS kenh_ban_hang,
        COALESCE(group_of_cago, '') AS nhom_hang,
        COALESCE(khu_vuc_doi_xe, '') AS khu_vuc_doi_xe,

        COUNT(DISTINCT so) AS tong_so_don,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime' THEN so
        END) AS so_don_fail_ontime,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late arrival by Transport'
            THEN so
        END) AS fail_ontime_late_arrival_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late warehouse call by Warehouse'
            THEN so
        END) AS fail_ontime_late_warehouse_call_by_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late pickup by Warehouse'
            THEN so
        END) AS fail_ontime_late_pickup_by_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late departure by Transport'
            THEN so
        END) AS fail_ontime_late_departure_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late delivery by Transport'
            THEN so
        END) AS fail_ontime_late_delivery_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull' THEN so
        END) AS so_don_fail_infull,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Warehouse Infull Failure'
            THEN so
        END) AS fail_infull_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Transport Infull Failure'
            THEN so
        END) AS fail_infull_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Warehouse + Transport Infull Failure'
            THEN so
        END) AS fail_infull_warehouse_transport

    FROM filtered_data
    WHERE selected_date IS NOT NULL
    GROUP BY 1, 2, 3, 4
)

SELECT
    nha_van_tai AS "Nhà vận tải",
    kenh_ban_hang AS "Kênh bán hàng",
    nhom_hang AS "Nhóm hàng",
    khu_vuc_doi_xe AS "Khu vực đội xe",
    tong_so_don AS "Tổng số đơn",

    so_don_fail_ontime AS "Số đơn fail ontime",
    fail_ontime_late_arrival_by_transport AS "Late arrival by Transport",
    fail_ontime_late_warehouse_call_by_warehouse AS "Late warehouse call by Warehouse",
    fail_ontime_late_pickup_by_warehouse AS "Late pickup by Warehouse",
    fail_ontime_late_departure_by_transport AS "Late departure by Transport",
    fail_ontime_late_delivery_by_transport AS "Late delivery by Transport",

    so_don_fail_infull AS "Số đơn fail infull",
    fail_infull_warehouse AS "Warehouse Infull Failure",
    fail_infull_transport AS "Transport Infull Failure",
    fail_infull_warehouse_transport AS "Warehouse + Transport Infull Failure"

FROM agg_report
ORDER BY 1, 2, 3, 4;
```

**ClickHouse SQL:**

```sql
SELECT 
    t.ten_ngan_nha_van_tai                                                            AS transporter,
    t.group_name                                                                      AS group_name,
    t.group_of_cago                                                                   AS group_of_cargo,
    t.khu_vuc_doi_xe                                                                  AS area,
    count(t.so)                                                                       AS total_so,
    countIf(t.so, coalesce(t.ontime_status, '') <> 'Ontime')                         AS fail_ontime_so,
    countIf(t.so, coalesce(t.ontime_status, '') <> 'Ontime'
                  AND t.not_ontime_reason = 'Late arrival by Transport')              AS late_arrival_by_transport,
    countIf(t.so, coalesce(t.ontime_status, '') <> 'Ontime'
                  AND t.not_ontime_reason = 'Late warehouse call by Warehouse')       AS late_wh_call_by_warehouse,
    countIf(t.so, coalesce(t.ontime_status, '') <> 'Ontime'
                  AND t.not_ontime_reason = 'Late pickup by Warehouse')               AS late_pickup_by_warehouse,
    countIf(t.so, coalesce(t.ontime_status, '') <> 'Ontime'
                  AND t.not_ontime_reason = 'Late departure by Transport')            AS late_departure_by_transport,
    countIf(t.so, coalesce(t.ontime_status, '') <> 'Ontime'
                  AND t.not_ontime_reason = 'Late delivery by Transport')             AS late_delivery_by_transport,
    countIf(t.so, coalesce(t.infull_status, '') <> 'Infull')                         AS fail_infull_so,
    countIf(t.so, coalesce(t.infull_status, '') <> 'Infull'
                  AND t.not_infull_reason = 'Warehouse Infull Failure')               AS warehouse_infull_failure,
    countIf(t.so, coalesce(t.infull_status, '') <> 'Infull'
                  AND t.not_infull_reason = 'Transport Infull Failure')               AS transport_infull_failure,
    countIf(t.so, coalesce(t.infull_status, '') <> 'Infull'
                  AND t.not_infull_reason = 'Warehouse + Transport Infull Failure')   AS warehouse_transport_infull_failure
FROM analytics_workspace.mv_otif t
WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)


-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)


-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)


-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)


    -- Date filter (fix robust)
    [[ AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
) ]]
-- Khi tính pctOntime / pctInfull / pctOtif:
AND ontime_status != 'Không có dữ liệu STM'
GROUP BY 
    t.ten_ngan_nha_van_tai,
    t.group_name,
    t.group_of_cago,
    t.khu_vuc_doi_xe
ORDER BY 
    t.ten_ngan_nha_van_tai,
    t.group_name,
    t.group_of_cago,
    t.khu_vuc_doi_xe;
```

### OTIF/ Ontime/ Infull theo kho `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_group_of_cago,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,   -- eta_giao_hang_cho_npp / ata_den
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,
        '2999-12-31 23:59:59'::DATE AS p_den_ngay
),

filtered_data AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
            ELSE NULL
        END AS selected_date
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, '') = p.p_group_of_cago
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, '') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, '') = p.p_khu_vuc_doi_xe
        )
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
),

agg_report AS (
    SELECT
        COALESCE(ten_ngan_nha_van_tai, '') AS nha_van_tai,
        COALESCE(group_name, '') AS kenh_ban_hang,
        COALESCE(group_of_cago, '') AS nhom_hang,
        COALESCE(khu_vuc_doi_xe, '') AS khu_vuc_doi_xe,

        COUNT(DISTINCT so) AS tong_so_don,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime' THEN so
        END) AS so_don_fail_ontime,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late arrival by Transport'
            THEN so
        END) AS fail_ontime_late_arrival_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late warehouse call by Warehouse'
            THEN so
        END) AS fail_ontime_late_warehouse_call_by_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late pickup by Warehouse'
            THEN so
        END) AS fail_ontime_late_pickup_by_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late departure by Transport'
            THEN so
        END) AS fail_ontime_late_departure_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late delivery by Transport'
            THEN so
        END) AS fail_ontime_late_delivery_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull' THEN so
        END) AS so_don_fail_infull,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Warehouse Infull Failure'
            THEN so
        END) AS fail_infull_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Transport Infull Failure'
            THEN so
        END) AS fail_infull_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Warehouse + Transport Infull Failure'
            THEN so
        END) AS fail_infull_warehouse_transport

    FROM filtered_data
    WHERE selected_date IS NOT NULL
    GROUP BY 1, 2, 3, 4
)

SELECT
    nha_van_tai AS "Nhà vận tải",
    kenh_ban_hang AS "Kênh bán hàng",
    nhom_hang AS "Nhóm hàng",
    khu_vuc_doi_xe AS "Khu vực đội xe",
    tong_so_don AS "Tổng số đơn",

    so_don_fail_ontime AS "Số đơn fail ontime",
    fail_ontime_late_arrival_by_transport AS "Late arrival by Transport",
    fail_ontime_late_warehouse_call_by_warehouse AS "Late warehouse call by Warehouse",
    fail_ontime_late_pickup_by_warehouse AS "Late pickup by Warehouse",
    fail_ontime_late_departure_by_transport AS "Late departure by Transport",
    fail_ontime_late_delivery_by_transport AS "Late delivery by Transport",

    so_don_fail_infull AS "Số đơn fail infull",
    fail_infull_warehouse AS "Warehouse Infull Failure",
    fail_infull_transport AS "Transport Infull Failure",
    fail_infull_warehouse_transport AS "Warehouse + Transport Infull Failure"

FROM agg_report
ORDER BY 1, 2, 3, 4;
```

**ClickHouse SQL:**

```sql
WITH filtered_data AS (
    SELECT t.*
    FROM analytics_workspace.mv_otif AS t
    WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)


-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)


-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)


-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)


    -- Date filter (fix robust)
    [[ AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
) ]]
)
SELECT
    whseid                                                  AS kho,
    COUNT(so)                                               AS total_so,
    countIf(ontime_status = 'Ontime')                      AS ontime_so,
    round(100.0 * countIf(ontime_status = 'Ontime') / nullIf(COUNT(so), 0), 2) AS pct_ontime,
    countIf(infull_status = 'Infull')                      AS infull_so,
    round(100.0 * countIf(infull_status = 'Infull') / nullIf(COUNT(so), 0), 2) AS pct_infull,
    countIf(otif_status = 'OTIF')                          AS otif_so,
    round(100.0 * countIf(otif_status = 'OTIF')    / nullIf(COUNT(so), 0), 2) AS pct_otif
FROM filtered_data
GROUP BY whseid
ORDER BY whseid;
```

### OTIF/ Ontime/ Infull theo kênh bán hàng `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_group_of_cago,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,   -- eta_giao_hang_cho_npp / ata_den
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,
        '2999-12-31 23:59:59'::DATE AS p_den_ngay
),

filtered_data AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
            ELSE NULL
        END AS selected_date
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, '') = p.p_group_of_cago
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, '') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, '') = p.p_khu_vuc_doi_xe
        )
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
),

agg_report AS (
    SELECT
        COALESCE(ten_ngan_nha_van_tai, '') AS nha_van_tai,
        COALESCE(group_name, '') AS kenh_ban_hang,
        COALESCE(group_of_cago, '') AS nhom_hang,
        COALESCE(khu_vuc_doi_xe, '') AS khu_vuc_doi_xe,

        COUNT(DISTINCT so) AS tong_so_don,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime' THEN so
        END) AS so_don_fail_ontime,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late arrival by Transport'
            THEN so
        END) AS fail_ontime_late_arrival_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late warehouse call by Warehouse'
            THEN so
        END) AS fail_ontime_late_warehouse_call_by_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late pickup by Warehouse'
            THEN so
        END) AS fail_ontime_late_pickup_by_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late departure by Transport'
            THEN so
        END) AS fail_ontime_late_departure_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late delivery by Transport'
            THEN so
        END) AS fail_ontime_late_delivery_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull' THEN so
        END) AS so_don_fail_infull,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Warehouse Infull Failure'
            THEN so
        END) AS fail_infull_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Transport Infull Failure'
            THEN so
        END) AS fail_infull_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Warehouse + Transport Infull Failure'
            THEN so
        END) AS fail_infull_warehouse_transport

    FROM filtered_data
    WHERE selected_date IS NOT NULL
    GROUP BY 1, 2, 3, 4
)

SELECT
    nha_van_tai AS "Nhà vận tải",
    kenh_ban_hang AS "Kênh bán hàng",
    nhom_hang AS "Nhóm hàng",
    khu_vuc_doi_xe AS "Khu vực đội xe",
    tong_so_don AS "Tổng số đơn",

    so_don_fail_ontime AS "Số đơn fail ontime",
    fail_ontime_late_arrival_by_transport AS "Late arrival by Transport",
    fail_ontime_late_warehouse_call_by_warehouse AS "Late warehouse call by Warehouse",
    fail_ontime_late_pickup_by_warehouse AS "Late pickup by Warehouse",
    fail_ontime_late_departure_by_transport AS "Late departure by Transport",
    fail_ontime_late_delivery_by_transport AS "Late delivery by Transport",

    so_don_fail_infull AS "Số đơn fail infull",
    fail_infull_warehouse AS "Warehouse Infull Failure",
    fail_infull_transport AS "Transport Infull Failure",
    fail_infull_warehouse_transport AS "Warehouse + Transport Infull Failure"

FROM agg_report
ORDER BY 1, 2, 3, 4;
```

**ClickHouse SQL:**

```sql
WITH filtered_data AS (
    SELECT t.*
    FROM analytics_workspace.mv_otif AS t
    WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)


-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)


-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)


-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)


    -- Date filter (fix robust)
    [[ AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
) ]]
)
SELECT
    coalesce(group_name, 'Unclassified')                AS kenh_ban_hang,
    COUNT(so)                                               AS total_so,
    countIf(ontime_status = 'Ontime')                      AS ontime_so,
    round(100.0 * countIf(ontime_status = 'Ontime') / nullIf(COUNT(so), 0), 2) AS pct_ontime,
    countIf(infull_status = 'Infull')                      AS infull_so,
    round(100.0 * countIf(infull_status = 'Infull') / nullIf(COUNT(so), 0), 2) AS pct_infull,
    countIf(otif_status = 'OTIF')                          AS otif_so,
    round(100.0 * countIf(otif_status = 'OTIF')    / nullIf(COUNT(so), 0), 2) AS pct_otif
FROM filtered_data
GROUP BY group_name
ORDER BY group_name;
```

### OTIF/ Ontime/ Infull theo nhà vận tải `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_group_of_cago,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,   -- eta_giao_hang_cho_npp / ata_den
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,
        '2999-12-31 23:59:59'::DATE AS p_den_ngay
),

filtered_data AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
            ELSE NULL
        END AS selected_date
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, '') = p.p_group_of_cago
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, '') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, '') = p.p_khu_vuc_doi_xe
        )
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
),

agg_report AS (
    SELECT
        COALESCE(ten_ngan_nha_van_tai, '') AS nha_van_tai,
        COALESCE(group_name, '') AS kenh_ban_hang,
        COALESCE(group_of_cago, '') AS nhom_hang,
        COALESCE(khu_vuc_doi_xe, '') AS khu_vuc_doi_xe,

        COUNT(DISTINCT so) AS tong_so_don,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime' THEN so
        END) AS so_don_fail_ontime,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late arrival by Transport'
            THEN so
        END) AS fail_ontime_late_arrival_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late warehouse call by Warehouse'
            THEN so
        END) AS fail_ontime_late_warehouse_call_by_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late pickup by Warehouse'
            THEN so
        END) AS fail_ontime_late_pickup_by_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late departure by Transport'
            THEN so
        END) AS fail_ontime_late_departure_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late delivery by Transport'
            THEN so
        END) AS fail_ontime_late_delivery_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull' THEN so
        END) AS so_don_fail_infull,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Warehouse Infull Failure'
            THEN so
        END) AS fail_infull_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Transport Infull Failure'
            THEN so
        END) AS fail_infull_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Warehouse + Transport Infull Failure'
            THEN so
        END) AS fail_infull_warehouse_transport

    FROM filtered_data
    WHERE selected_date IS NOT NULL
    GROUP BY 1, 2, 3, 4
)

SELECT
    nha_van_tai AS "Nhà vận tải",
    kenh_ban_hang AS "Kênh bán hàng",
    nhom_hang AS "Nhóm hàng",
    khu_vuc_doi_xe AS "Khu vực đội xe",
    tong_so_don AS "Tổng số đơn",

    so_don_fail_ontime AS "Số đơn fail ontime",
    fail_ontime_late_arrival_by_transport AS "Late arrival by Transport",
    fail_ontime_late_warehouse_call_by_warehouse AS "Late warehouse call by Warehouse",
    fail_ontime_late_pickup_by_warehouse AS "Late pickup by Warehouse",
    fail_ontime_late_departure_by_transport AS "Late departure by Transport",
    fail_ontime_late_delivery_by_transport AS "Late delivery by Transport",

    so_don_fail_infull AS "Số đơn fail infull",
    fail_infull_warehouse AS "Warehouse Infull Failure",
    fail_infull_transport AS "Transport Infull Failure",
    fail_infull_warehouse_transport AS "Warehouse + Transport Infull Failure"

FROM agg_report
ORDER BY 1, 2, 3, 4;
```

**ClickHouse SQL:**

```sql
WITH filtered_data AS (
    SELECT t.*
    FROM analytics_workspace.mv_otif AS t
    WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)


-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)


-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)


-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)


    -- Date filter (fix robust)
    [[ AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
) ]]
)
SELECT
    ten_ngan_nha_van_tai                                    AS nha_van_tai,
    COUNT(so)                                               AS total_so,
    countIf(ontime_status = 'Ontime')                      AS ontime_so,
    round(100.0 * countIf(ontime_status = 'Ontime') / nullIf(COUNT(so), 0), 2) AS pct_ontime,
    countIf(infull_status = 'Infull')                      AS infull_so,
    round(100.0 * countIf(infull_status = 'Infull') / nullIf(COUNT(so), 0), 2) AS pct_infull,
    countIf(otif_status = 'OTIF')                          AS otif_so,
    round(100.0 * countIf(otif_status = 'OTIF')    / nullIf(COUNT(so), 0), 2) AS pct_otif
FROM filtered_data
GROUP BY ten_ngan_nha_van_tai
ORDER BY ten_ngan_nha_van_tai;
```

### OTIF/ Ontime/ Infull theo thời gian `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_group_of_cago,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,   -- eta_giao_hang_cho_npp / ata_den
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,
        '2999-12-31 23:59:59'::DATE AS p_den_ngay
),

filtered_data AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
            ELSE NULL
        END AS selected_date
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, '') = p.p_group_of_cago
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, '') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, '') = p.p_khu_vuc_doi_xe
        )
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
),

agg_report AS (
    SELECT
        COALESCE(ten_ngan_nha_van_tai, '') AS nha_van_tai,
        COALESCE(group_name, '') AS kenh_ban_hang,
        COALESCE(group_of_cago, '') AS nhom_hang,
        COALESCE(khu_vuc_doi_xe, '') AS khu_vuc_doi_xe,

        COUNT(DISTINCT so) AS tong_so_don,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime' THEN so
        END) AS so_don_fail_ontime,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late arrival by Transport'
            THEN so
        END) AS fail_ontime_late_arrival_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late warehouse call by Warehouse'
            THEN so
        END) AS fail_ontime_late_warehouse_call_by_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late pickup by Warehouse'
            THEN so
        END) AS fail_ontime_late_pickup_by_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late departure by Transport'
            THEN so
        END) AS fail_ontime_late_departure_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late delivery by Transport'
            THEN so
        END) AS fail_ontime_late_delivery_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull' THEN so
        END) AS so_don_fail_infull,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Warehouse Infull Failure'
            THEN so
        END) AS fail_infull_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Transport Infull Failure'
            THEN so
        END) AS fail_infull_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Warehouse + Transport Infull Failure'
            THEN so
        END) AS fail_infull_warehouse_transport

    FROM filtered_data
    WHERE selected_date IS NOT NULL
    GROUP BY 1, 2, 3, 4
)

SELECT
    nha_van_tai AS "Nhà vận tải",
    kenh_ban_hang AS "Kênh bán hàng",
    nhom_hang AS "Nhóm hàng",
    khu_vuc_doi_xe AS "Khu vực đội xe",
    tong_so_don AS "Tổng số đơn",

    so_don_fail_ontime AS "Số đơn fail ontime",
    fail_ontime_late_arrival_by_transport AS "Late arrival by Transport",
    fail_ontime_late_warehouse_call_by_warehouse AS "Late warehouse call by Warehouse",
    fail_ontime_late_pickup_by_warehouse AS "Late pickup by Warehouse",
    fail_ontime_late_departure_by_transport AS "Late departure by Transport",
    fail_ontime_late_delivery_by_transport AS "Late delivery by Transport",

    so_don_fail_infull AS "Số đơn fail infull",
    fail_infull_warehouse AS "Warehouse Infull Failure",
    fail_infull_transport AS "Transport Infull Failure",
    fail_infull_warehouse_transport AS "Warehouse + Transport Infull Failure"

FROM agg_report
ORDER BY 1, 2, 3, 4;
```

**ClickHouse SQL:**

```sql
WITH filtered_data AS (
    SELECT t.*
    FROM analytics_workspace.mv_otif AS t
    WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)


-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)


-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)


-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)


    -- Date filter (fix robust)
    [[ AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
) ]]
)
SELECT
    toDate(CASE
        WHEN {{date_type}} = 'ETA gửi thầu'         THEN eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'  THEN ata_den
    END)                                                    AS thoi_gian,
    COUNT(so)                                               AS total_so,
    countIf(ontime_status = 'Ontime')                      AS ontime_so,
    round(100.0 * countIf(ontime_status = 'Ontime') / nullIf(COUNT(so), 0), 2) AS pct_ontime,
    countIf(infull_status = 'Infull')                      AS infull_so,
    round(100.0 * countIf(infull_status = 'Infull') / nullIf(COUNT(so), 0), 2) AS pct_infull,
    countIf(otif_status = 'OTIF')                          AS otif_so,
    round(100.0 * countIf(otif_status = 'OTIF')    / nullIf(COUNT(so), 0), 2) AS pct_otif
FROM filtered_data
GROUP BY {{date_type}}
ORDER BY {{date_type}};
```

### Report detail `New`

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_group_of_cago,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai,
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,   -- eta_giao_hang_cho_npp / ata_den
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,
        '2999-12-31 23:59:59'::DATE AS p_den_ngay
),

filtered_data AS (
    SELECT
        t.*,
        CASE
            WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
            WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
            ELSE NULL
        END AS selected_date
    FROM reporting_schema.mv_otif t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_group_of_cago = 'ALL'
            OR COALESCE(t.group_of_cago, '') = p.p_group_of_cago
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nha_van_tai, '') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, '') = p.p_khu_vuc_doi_xe
        )
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN CAST(t.ata_den AS DATE)
                ELSE NULL
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31')
        )
),

agg_report AS (
    SELECT
        COALESCE(ten_ngan_nha_van_tai, '') AS nha_van_tai,
        COALESCE(group_name, '') AS kenh_ban_hang,
        COALESCE(group_of_cago, '') AS nhom_hang,
        COALESCE(khu_vuc_doi_xe, '') AS khu_vuc_doi_xe,

        COUNT(DISTINCT so) AS tong_so_don,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime' THEN so
        END) AS so_don_fail_ontime,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late arrival by Transport'
            THEN so
        END) AS fail_ontime_late_arrival_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late warehouse call by Warehouse'
            THEN so
        END) AS fail_ontime_late_warehouse_call_by_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late pickup by Warehouse'
            THEN so
        END) AS fail_ontime_late_pickup_by_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late departure by Transport'
            THEN so
        END) AS fail_ontime_late_departure_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(ontime_status, '') <> 'Ontime'
             AND not_ontime_reason = 'Late delivery by Transport'
            THEN so
        END) AS fail_ontime_late_delivery_by_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull' THEN so
        END) AS so_don_fail_infull,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Warehouse Infull Failure'
            THEN so
        END) AS fail_infull_warehouse,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Transport Infull Failure'
            THEN so
        END) AS fail_infull_transport,

        COUNT(DISTINCT CASE
            WHEN COALESCE(infull_status, '') <> 'Infull'
             AND not_infull_reason = 'Warehouse + Transport Infull Failure'
            THEN so
        END) AS fail_infull_warehouse_transport

    FROM filtered_data
    WHERE selected_date IS NOT NULL
    GROUP BY 1, 2, 3, 4
)

SELECT
    nha_van_tai AS "Nhà vận tải",
    kenh_ban_hang AS "Kênh bán hàng",
    nhom_hang AS "Nhóm hàng",
    khu_vuc_doi_xe AS "Khu vực đội xe",
    tong_so_don AS "Tổng số đơn",

    so_don_fail_ontime AS "Số đơn fail ontime",
    fail_ontime_late_arrival_by_transport AS "Late arrival by Transport",
    fail_ontime_late_warehouse_call_by_warehouse AS "Late warehouse call by Warehouse",
    fail_ontime_late_pickup_by_warehouse AS "Late pickup by Warehouse",
    fail_ontime_late_departure_by_transport AS "Late departure by Transport",
    fail_ontime_late_delivery_by_transport AS "Late delivery by Transport",

    so_don_fail_infull AS "Số đơn fail infull",
    fail_infull_warehouse AS "Warehouse Infull Failure",
    fail_infull_transport AS "Transport Infull Failure",
    fail_infull_warehouse_transport AS "Warehouse + Transport Infull Failure"

FROM agg_report
ORDER BY 1, 2, 3, 4;
```

**ClickHouse SQL:**

```sql
SELECT
  *
FROM analytics_workspace.mv_otif t
WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)


-- Cargo Group
AND if(
    arraySort([{{group_of_cargo}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_of_cargo_code)) FROM analytics_workspace.mv_filter_cargo_brand
    ),
    1 = 1,
    coalesce(t.group_of_cago, 'Unclassified') IN ({{group_of_cargo}})
)


-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nha_van_tai IN ({{transporter}})
)


-- Area
AND if(
    arraySort([{{area}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{area}})
)


    -- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp
        WHEN {{date_type}} = 'ATA chi tiết chuyến'
            THEN t.ata_den
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau
        WHEN {{date_type}} = 'Ngày vào kho'
            THEN t.gio_dang_tai
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.ngay_duyet_chuyen
        WHEN {{date_type}} = 'Ngày GI'
            THEN t.ngay_gi
        WHEN {{date_type}} = 'Ngày tạo đơn hàng'
            THEN t.ngay_tao_don
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
```

---

## Cảnh báo đơn trễ

### Scorecard Tất cả

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,
        '2026-04-16 00:00:00'::DATE AS p_tu_ngay,
        '2026-04-16 23:59:59'::DATE AS p_den_ngay,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_kenh_ban_hang,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM reporting_schema.mv_alert_late_do t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN CAST(t.thoi_gian_gui_thau AS DATE)
                ELSE CAST(t.eta_giao_hang_cho_npp AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '2026-01-01 00:00:00')
                AND COALESCE(p.p_den_ngay, DATE '2026-01-31 23:59:59')
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nvt, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
        AND (
            p.p_kenh_ban_hang= 'ALL'
            OR COALESCE(t.group, 'Unclassified') = p.p_kenh_ban_hang
        )
)
SELECT
    COUNT(DISTINCT so_chuyen) AS tat_ca,
    COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt
FROM base;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*
    FROM analytics_workspace.mv_alert_late_do t
    WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Region / Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code))
        FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

-- Sales channel
AND if(
    arraySort([{{sales_channel}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group IN ({{sales_channel}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code))
        FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nvt IN ({{transporter}})
)

    -- Date filter (fix robust)
  AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp 
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
        WHEN {{date_type}} = 'ETD chuyến - ngày dự kiến lấy hàng'
            THEN t.etd_chuyen
        WHEN {{date_type}} = 'ETA chuyến - ngày dự kiến giao hàng'
            THEN t.eta_chuyen
        WHEN {{date_type}} = 'Ngày gửi yêu cầu đơn hàng'
            THEN t.request_date
        WHEN {{date_type}} = 'ATD chuyến - ngày thực tế lấy hàng'
            THEN t.atd_chuyen
        WHEN {{date_type}} = 'ATA chuyến - ngày thực tế giao hàng'
            THEN t.ata_chuyen
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.approved_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
)

SELECT
COUNT(DISTINCT so_chuyen) AS tat_ca,
COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt

FROM base
```

### Scorecard Normal

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,
        '2026-04-16 00:00:00'::DATE AS p_tu_ngay,
        '2026-04-16 23:59:59'::DATE AS p_den_ngay,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_kenh_ban_hang,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM reporting_schema.mv_alert_late_do t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN CAST(t.thoi_gian_gui_thau AS DATE)
                ELSE CAST(t.eta_giao_hang_cho_npp AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '2026-01-01 00:00:00')
                AND COALESCE(p.p_den_ngay, DATE '2026-01-31 23:59:59')
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nvt, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
        AND (
            p.p_kenh_ban_hang= 'ALL'
            OR COALESCE(t.group, 'Unclassified') = p.p_kenh_ban_hang
        )
)
SELECT
    COUNT(DISTINCT so_chuyen) AS tat_ca,
    COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt
FROM base;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*
    FROM analytics_workspace.mv_alert_late_do t
    WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Region / Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code))
        FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

-- Sales channel
AND if(
    arraySort([{{sales_channel}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group IN ({{sales_channel}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code))
        FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nvt IN ({{transporter}})
)

    -- Date filter (fix robust)
  AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp 
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
        WHEN {{date_type}} = 'ETD chuyến - ngày dự kiến lấy hàng'
            THEN t.etd_chuyen
        WHEN {{date_type}} = 'ETA chuyến - ngày dự kiến giao hàng'
            THEN t.eta_chuyen
        WHEN {{date_type}} = 'Ngày gửi yêu cầu đơn hàng'
            THEN t.request_date
        WHEN {{date_type}} = 'ATD chuyến - ngày thực tế lấy hàng'
            THEN t.atd_chuyen
        WHEN {{date_type}} = 'ATA chuyến - ngày thực tế giao hàng'
            THEN t.ata_chuyen
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.approved_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
)

SELECT
COUNT(DISTINCT so_chuyen) AS tat_ca,
COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt

FROM base
```

### Scorecard Late departure open

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,
        '2026-04-16 00:00:00'::DATE AS p_tu_ngay,
        '2026-04-16 23:59:59'::DATE AS p_den_ngay,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_kenh_ban_hang,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM reporting_schema.mv_alert_late_do t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN CAST(t.thoi_gian_gui_thau AS DATE)
                ELSE CAST(t.eta_giao_hang_cho_npp AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '2026-01-01 00:00:00')
                AND COALESCE(p.p_den_ngay, DATE '2026-01-31 23:59:59')
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nvt, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
        AND (
            p.p_kenh_ban_hang= 'ALL'
            OR COALESCE(t.group, 'Unclassified') = p.p_kenh_ban_hang
        )
)
SELECT
    COUNT(DISTINCT so_chuyen) AS tat_ca,
    COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt
FROM base;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*
    FROM analytics_workspace.mv_alert_late_do t
    WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Region / Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code))
        FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

-- Sales channel
AND if(
    arraySort([{{sales_channel}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group IN ({{sales_channel}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code))
        FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nvt IN ({{transporter}})
)

    -- Date filter (fix robust)
  AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp 
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
        WHEN {{date_type}} = 'ETD chuyến - ngày dự kiến lấy hàng'
            THEN t.etd_chuyen
        WHEN {{date_type}} = 'ETA chuyến - ngày dự kiến giao hàng'
            THEN t.eta_chuyen
        WHEN {{date_type}} = 'Ngày gửi yêu cầu đơn hàng'
            THEN t.request_date
        WHEN {{date_type}} = 'ATD chuyến - ngày thực tế lấy hàng'
            THEN t.atd_chuyen
        WHEN {{date_type}} = 'ATA chuyến - ngày thực tế giao hàng'
            THEN t.ata_chuyen
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.approved_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
)

SELECT
COUNT(DISTINCT so_chuyen) AS tat_ca,
COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt

FROM base
```

### Scorecard Late departure

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,
        '2026-04-16 00:00:00'::DATE AS p_tu_ngay,
        '2026-04-16 23:59:59'::DATE AS p_den_ngay,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_kenh_ban_hang,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM reporting_schema.mv_alert_late_do t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN CAST(t.thoi_gian_gui_thau AS DATE)
                ELSE CAST(t.eta_giao_hang_cho_npp AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '2026-01-01 00:00:00')
                AND COALESCE(p.p_den_ngay, DATE '2026-01-31 23:59:59')
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nvt, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
        AND (
            p.p_kenh_ban_hang= 'ALL'
            OR COALESCE(t.group, 'Unclassified') = p.p_kenh_ban_hang
        )
)
SELECT
    COUNT(DISTINCT so_chuyen) AS tat_ca,
    COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt
FROM base;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*
    FROM analytics_workspace.mv_alert_late_do t
    WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Region / Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code))
        FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

-- Sales channel
AND if(
    arraySort([{{sales_channel}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group IN ({{sales_channel}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code))
        FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nvt IN ({{transporter}})
)

    -- Date filter (fix robust)
  AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp 
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
        WHEN {{date_type}} = 'ETD chuyến - ngày dự kiến lấy hàng'
            THEN t.etd_chuyen
        WHEN {{date_type}} = 'ETA chuyến - ngày dự kiến giao hàng'
            THEN t.eta_chuyen
        WHEN {{date_type}} = 'Ngày gửi yêu cầu đơn hàng'
            THEN t.request_date
        WHEN {{date_type}} = 'ATD chuyến - ngày thực tế lấy hàng'
            THEN t.atd_chuyen
        WHEN {{date_type}} = 'ATA chuyến - ngày thực tế giao hàng'
            THEN t.ata_chuyen
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.approved_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
)

SELECT
COUNT(DISTINCT so_chuyen) AS tat_ca,
COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt

FROM base
```

### Scorecard Ontime departure

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,
        '2026-04-16 00:00:00'::DATE AS p_tu_ngay,
        '2026-04-16 23:59:59'::DATE AS p_den_ngay,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_kenh_ban_hang,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM reporting_schema.mv_alert_late_do t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN CAST(t.thoi_gian_gui_thau AS DATE)
                ELSE CAST(t.eta_giao_hang_cho_npp AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '2026-01-01 00:00:00')
                AND COALESCE(p.p_den_ngay, DATE '2026-01-31 23:59:59')
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nvt, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
        AND (
            p.p_kenh_ban_hang= 'ALL'
            OR COALESCE(t.group, 'Unclassified') = p.p_kenh_ban_hang
        )
)
SELECT
    COUNT(DISTINCT so_chuyen) AS tat_ca,
    COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt
FROM base;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*
    FROM analytics_workspace.mv_alert_late_do t
    WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Region / Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code))
        FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

-- Sales channel
AND if(
    arraySort([{{sales_channel}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group IN ({{sales_channel}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code))
        FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nvt IN ({{transporter}})
)

    -- Date filter (fix robust)
  AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp 
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
        WHEN {{date_type}} = 'ETD chuyến - ngày dự kiến lấy hàng'
            THEN t.etd_chuyen
        WHEN {{date_type}} = 'ETA chuyến - ngày dự kiến giao hàng'
            THEN t.eta_chuyen
        WHEN {{date_type}} = 'Ngày gửi yêu cầu đơn hàng'
            THEN t.request_date
        WHEN {{date_type}} = 'ATD chuyến - ngày thực tế lấy hàng'
            THEN t.atd_chuyen
        WHEN {{date_type}} = 'ATA chuyến - ngày thực tế giao hàng'
            THEN t.ata_chuyen
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.approved_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
)

SELECT
COUNT(DISTINCT so_chuyen) AS tat_ca,
COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt

FROM base
```

### Scorecard Ontime delivery

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,
        '2026-04-16 00:00:00'::DATE AS p_tu_ngay,
        '2026-04-16 23:59:59'::DATE AS p_den_ngay,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_kenh_ban_hang,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM reporting_schema.mv_alert_late_do t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN CAST(t.thoi_gian_gui_thau AS DATE)
                ELSE CAST(t.eta_giao_hang_cho_npp AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '2026-01-01 00:00:00')
                AND COALESCE(p.p_den_ngay, DATE '2026-01-31 23:59:59')
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nvt, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
        AND (
            p.p_kenh_ban_hang= 'ALL'
            OR COALESCE(t.group, 'Unclassified') = p.p_kenh_ban_hang
        )
)
SELECT
    COUNT(DISTINCT so_chuyen) AS tat_ca,
    COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt
FROM base;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*
    FROM analytics_workspace.mv_alert_late_do t
    WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Region / Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code))
        FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

-- Sales channel
AND if(
    arraySort([{{sales_channel}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group IN ({{sales_channel}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code))
        FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nvt IN ({{transporter}})
)

    -- Date filter (fix robust)
  AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp 
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
        WHEN {{date_type}} = 'ETD chuyến - ngày dự kiến lấy hàng'
            THEN t.etd_chuyen
        WHEN {{date_type}} = 'ETA chuyến - ngày dự kiến giao hàng'
            THEN t.eta_chuyen
        WHEN {{date_type}} = 'Ngày gửi yêu cầu đơn hàng'
            THEN t.request_date
        WHEN {{date_type}} = 'ATD chuyến - ngày thực tế lấy hàng'
            THEN t.atd_chuyen
        WHEN {{date_type}} = 'ATA chuyến - ngày thực tế giao hàng'
            THEN t.ata_chuyen
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.approved_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
)

SELECT
COUNT(DISTINCT so_chuyen) AS tat_ca,
COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt

FROM base
```

### Scorecard Late delivery

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,
        '2026-04-16 00:00:00'::DATE AS p_tu_ngay,
        '2026-04-16 23:59:59'::DATE AS p_den_ngay,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_kenh_ban_hang,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM reporting_schema.mv_alert_late_do t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN CAST(t.thoi_gian_gui_thau AS DATE)
                ELSE CAST(t.eta_giao_hang_cho_npp AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '2026-01-01 00:00:00')
                AND COALESCE(p.p_den_ngay, DATE '2026-01-31 23:59:59')
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nvt, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
        AND (
            p.p_kenh_ban_hang= 'ALL'
            OR COALESCE(t.group, 'Unclassified') = p.p_kenh_ban_hang
        )
)
SELECT
    COUNT(DISTINCT so_chuyen) AS tat_ca,
    COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt
FROM base;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*
    FROM analytics_workspace.mv_alert_late_do t
    WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Region / Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code))
        FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

-- Sales channel
AND if(
    arraySort([{{sales_channel}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group IN ({{sales_channel}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code))
        FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nvt IN ({{transporter}})
)

    -- Date filter (fix robust)
  AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp 
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
        WHEN {{date_type}} = 'ETD chuyến - ngày dự kiến lấy hàng'
            THEN t.etd_chuyen
        WHEN {{date_type}} = 'ETA chuyến - ngày dự kiến giao hàng'
            THEN t.eta_chuyen
        WHEN {{date_type}} = 'Ngày gửi yêu cầu đơn hàng'
            THEN t.request_date
        WHEN {{date_type}} = 'ATD chuyến - ngày thực tế lấy hàng'
            THEN t.atd_chuyen
        WHEN {{date_type}} = 'ATA chuyến - ngày thực tế giao hàng'
            THEN t.ata_chuyen
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.approved_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
)

SELECT
COUNT(DISTINCT so_chuyen) AS tat_ca,
COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt

FROM base
```

### Donut chart

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,
        '2026-04-16 00:00:00'::DATE AS p_tu_ngay,
        '2026-04-16 23:59:59'::DATE AS p_den_ngay,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_kenh_ban_hang,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM reporting_schema.mv_alert_late_do t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN CAST(t.thoi_gian_gui_thau AS DATE)
                ELSE CAST(t.eta_giao_hang_cho_npp AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '2026-01-01 00:00:00')
                AND COALESCE(p.p_den_ngay, DATE '2026-01-31 23:59:59')
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nvt, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
        AND (
            p.p_kenh_ban_hang= 'ALL'
            OR COALESCE(t.group, 'Unclassified') = p.p_kenh_ban_hang
        )
)
SELECT
    COUNT(DISTINCT so_chuyen) AS tat_ca,
    COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
    COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt
FROM base;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*
    FROM analytics_workspace.mv_alert_late_do t
    WHERE 1 = 1

-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Region / Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code))
        FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

-- Sales channel
AND if(
    arraySort([{{sales_channel}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group IN ({{sales_channel}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code))
        FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nvt IN ({{transporter}})
)

    -- Date filter (fix robust)
  AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp 
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
        WHEN {{date_type}} = 'ETD chuyến - ngày dự kiến lấy hàng'
            THEN t.etd_chuyen
        WHEN {{date_type}} = 'ETA chuyến - ngày dự kiến giao hàng'
            THEN t.eta_chuyen
        WHEN {{date_type}} = 'Ngày gửi yêu cầu đơn hàng'
            THEN t.request_date
        WHEN {{date_type}} = 'ATD chuyến - ngày thực tế lấy hàng'
            THEN t.atd_chuyen
        WHEN {{date_type}} = 'ATA chuyến - ngày thực tế giao hàng'
            THEN t.ata_chuyen
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.approved_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
)

SELECT
COUNT(DISTINCT so_chuyen) AS tat_ca,
COUNT(DISTINCT CASE WHEN alert_status = 'Normal' THEN so_chuyen END) AS normal_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'At risk' THEN so_chuyen END) AS at_risk_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure open' THEN so_chuyen END) AS late_departure_open_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late departure' THEN so_chuyen END) AS late_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime departure' THEN so_chuyen END) AS ontime_departure_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Ontime delivery' THEN so_chuyen END) AS ontime_delivery_cnt,
COUNT(DISTINCT CASE WHEN alert_status = 'Late delivery' THEN so_chuyen END) AS late_delivery_cnt

FROM base
```

### Report raw

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,
        '2999-12-31 23:59:59'::DATE AS p_den_ngay,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_kenh_ban_hang,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM reporting_schema.mv_alert_late_do t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN CAST(t.thoi_gian_gui_thau AS DATE)
                ELSE CAST(t.eta_giao_hang_cho_npp AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01 00:00:00')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31 23:59:59')
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nvt, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
        AND (
            p.p_kenh_ban_hang = 'ALL'
            OR COALESCE(t."group", 'Unclassified') = p.p_kenh_ban_hang
        )
)

SELECT DISTINCT
    so_chuyen,
    ds_ma_don_trong_chuyen,
    trang_thai_chuyen,                 -- thay bằng đúng tên cột trạng thái chuyến nếu khác
    tg_bat_buoc_roi_kho,
    group_of_cago, --nhóm hàng
    alert_status,
    ten_doi_tac_nhan,
    khu_vuc_doi_xe,
    ten_ngan_nvt,
    gio_ra_cong,
    eta_giao_hang_cho_npp,
    "group" AS kenh_ban_hang
FROM base
ORDER BY
    eta_giao_hang_cho_npp DESC,
    so_chuyen;
```

**ClickHouse SQL:**

```sql
SELECT

    so_chuyen                           AS "Số chuyến",

    whseid                              AS "Mã kho",

    trang_thai_chuyen                   AS "Trạng thái chuyến",

    trang_thai_chuyen_stm               AS "Trạng thái chuyến STM",

    group_of_cago                       AS "Nhóm hàng",

    group                               AS "Group",

    customer_code                       AS "Mã đối tác giao",

    customer_name                       AS "Tên đối tác giao",

    khu_vuc_doi_xe                      AS "Khu vực đội xe",

    ten_ngan_nvt                        AS "Tên ngắn NVT",

    ma_doi_tac_nhan                     AS "Mã đối tác nhận",

    ten_doi_tac_nhan                    AS "Tên đối tác nhận",

    thoi_gian_gui_thau                  AS "Thời gian gửi thầu",

    ngay_tao_chuyen                     AS "Ngày tạo chuyến",

    etd_chuyen_gui_thau                 AS "ETD chuyến gửi thầu",

    gio_dang_tai                        AS "Giờ đăng tài",

    gio_goi_xe                          AS "Giờ gọi xe",

    gio_vao_cong                        AS "Giờ vào cổng",

    gio_vao_dock                        AS "Giờ vào dock",

    actual_ship_date                    AS "Actual Ship Date",

    gio_ra_dock                         AS "Giờ ra dock",

    gio_ra_cong                         AS "Giờ ra cổng",

    tg_bat_buoc_roi_kho                 AS "TG bắt buộc rời kho",

    eta_giao_hang_cho_npp               AS "ETA giao hàng cho NPP",

    ata_den                             AS "ATA đến",

    ata_roi                             AS "ATA rời",

    so_xe                               AS "Số xe",

    tai_xe                              AS "Tài xế",

    ma_nha_xe                           AS "Mã nhà xe",

    sum_original                        AS "Original",

    sum_original_cbm                    AS "Original CBM",

    sum_original_kg/1000.0              AS "Original Ton",

    sum_original_cse                    AS "Original CSE",

    sum_original_pl                     AS "Original PL",

    sum_shipped                         AS "Shipped",

    sum_shipped_cbm                     AS "Shipped CBM",

    sum_shipped_kg/1000.0               AS "Shipped Ton",

    sum_shipped_cse                     AS "Shipped CSE",

    sum_shipped_pl                      AS "Shipped PL",

    sum_san_luong_giao                  AS "Sản lượng giao",

    sum_san_luong_giao_cbm              AS "Sản lượng giao CBM",

    sum_san_luong_giao_kg/1000.0        AS "Sản lượng giao Ton",

    sum_san_luong_giao_cse              AS "Sản lượng giao CSE",

    sum_san_luong_giao_pl               AS "Sản lượng giao PL",

    diff_sl_giao_cho                    AS "Chênh lệch SL giao & chở",

    diff_sl_giao_cho_cbm                AS "Chênh lệch SL giao & chở CBM",

    diff_sl_giao_cho_kg/1000.0          AS "Chênh lệch SL giao & chở Ton",

    diff_sl_giao_cho_cse                AS "Chênh lệch SL giao & chở CSE",

    diff_sl_giao_cho_pl                 AS "Chênh lệch SL giao & chở PL",

    total_time_in_warehouse_minute      AS "Tổng TG trong kho (phút)",

    total_time_loading_minute           AS "TG load hàng (phút)",

    diff_delivery_time_hour             AS "Chênh lệch TG thực tế/dự kiến (giờ)",

    phut_tre_roi_kho                    AS "Phút trễ rời kho",

    phut_tre_giao_npp                   AS "Phút trễ giao NPP",

    ds_ma_don_trong_chuyen              AS "DS mã đơn trong chuyến",

    alert_status                        AS "Trạng thái cảnh báo",

    ly_do_tre_hoan_thanh                AS "Lý do trễ hoàn thành",

    etd_chuyen                          AS "ETD chuyến",

    eta_chuyen                          AS "ETA chuyến",

    ata_chuyen                          AS "ATA chuyến",

    atd_chuyen                          AS "ATD chuyến",

    request_date                        AS "Ngày yêu cầu",

    approved_date                       AS "Ngày duyệt",

    so_km                               AS "Số KM",

    van_toc                             AS "Vận tốc"

    

    FROM analytics_workspace.mv_alert_late_do t
    WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Region / Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code))
        FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

-- Sales channel
AND if(
    arraySort([{{sales_channel}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group IN ({{sales_channel}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code))
        FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nvt IN ({{transporter}})
)

    -- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp 
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
        WHEN {{date_type}} = 'ETD chuyến - ngày dự kiến lấy hàng'
            THEN t.etd_chuyen
        WHEN {{date_type}} = 'ETA chuyến - ngày dự kiến giao hàng'
            THEN t.eta_chuyen
        WHEN {{date_type}} = 'Ngày gửi yêu cầu đơn hàng'
            THEN t.request_date
        WHEN {{date_type}} = 'ATD chuyến - ngày thực tế lấy hàng'
            THEN t.atd_chuyen
        WHEN {{date_type}} = 'ATA chuyến - ngày thực tế giao hàng'
            THEN t.ata_chuyen
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.approved_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)

ORDER BY
    eta_giao_hang_cho_npp DESC,
    so_chuyen
```

### Chart Cảnh báo tình trạng đơn hàng theo nhà vận tải

**Redshift SQL:**

```sql
WITH params AS (
    SELECT
        'ETA gửi thầu'::VARCHAR AS p_loai_ngay,
        '1900-01-01 00:00:00'::DATE AS p_tu_ngay,
        '2999-12-31 23:59:59'::DATE AS p_den_ngay,
        'ALL'::VARCHAR AS p_whseid,
        'ALL'::VARCHAR AS p_khu_vuc_doi_xe,
        'ALL'::VARCHAR AS p_kenh_ban_hang,
        'ALL'::VARCHAR AS p_ten_ngan_nha_van_tai
),
base AS (
    SELECT
        t.*
    FROM reporting_schema.mv_alert_late_do t
    CROSS JOIN params p
    WHERE 1 = 1
        AND (
            CASE
                WHEN p.p_loai_ngay = 'ETA gửi thầu' THEN CAST(t.eta_giao_hang_cho_npp AS DATE)
                WHEN p.p_loai_ngay = 'Ngày gửi thầu' THEN CAST(t.thoi_gian_gui_thau AS DATE)
                ELSE CAST(t.eta_giao_hang_cho_npp AS DATE)
            END
            BETWEEN COALESCE(p.p_tu_ngay, DATE '1900-01-01 00:00:00')
                AND COALESCE(p.p_den_ngay, DATE '2999-12-31 23:59:59')
        )
        AND (
            p.p_whseid = 'ALL'
            OR t.whseid = p.p_whseid
        )
        AND (
            p.p_ten_ngan_nha_van_tai = 'ALL'
            OR COALESCE(t.ten_ngan_nvt, 'Unclassified') = p.p_ten_ngan_nha_van_tai
        )
        AND (
            p.p_khu_vuc_doi_xe = 'ALL'
            OR COALESCE(t.khu_vuc_doi_xe, 'Unclassified') = p.p_khu_vuc_doi_xe
        )
        AND (
            p.p_kenh_ban_hang = 'ALL'
            OR COALESCE(t."group", 'Unclassified') = p.p_kenh_ban_hang
        )
)

SELECT DISTINCT
    so_chuyen,
    ds_ma_don_trong_chuyen,
    trang_thai_chuyen,                 -- thay bằng đúng tên cột trạng thái chuyến nếu khác
    tg_bat_buoc_roi_kho,
    group_of_cago, --nhóm hàng
    alert_status,
    ten_doi_tac_nhan,
    khu_vuc_doi_xe,
    ten_ngan_nvt,
    gio_ra_cong,
    eta_giao_hang_cho_npp,
    "group" AS kenh_ban_hang
FROM base
ORDER BY
    eta_giao_hang_cho_npp DESC,
    so_chuyen;
```

**ClickHouse SQL:**

```sql
WITH base AS (
    SELECT
        t.*
    FROM analytics_workspace.mv_alert_late_do t
    WHERE 1 = 1
-- Warehouse
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)

-- Region / Area
AND if(
    arraySort([{{region}}]) = (
        SELECT arraySort(groupArray(DISTINCT group_area_code))
        FROM analytics_workspace.mv_filter_region
    ),
    1 = 1,
    t.khu_vuc_doi_xe IN ({{region}})
)

-- Sales channel
AND if(
    arraySort([{{sales_channel}}]) = (
        SELECT arraySort(groupArray(DISTINCT channel_code))
        FROM analytics_workspace.mv_filter_channel
    ),
    1 = 1,
    t.group IN ({{sales_channel}})
)

-- Transporter
AND if(
    arraySort([{{transporter}}]) = (
        SELECT arraySort(groupArray(DISTINCT vendor_code))
        FROM analytics_workspace.mv_filter_vendor
    ),
    1 = 1,
    t.ten_ngan_nvt IN ({{transporter}})
)

    -- Date filter (fix robust)
AND (
    toDate(
    CASE
        WHEN {{date_type}} = 'ETA gửi thầu (đơn)'
            THEN t.eta_giao_hang_cho_npp 
        WHEN {{date_type}} = 'Ngày gửi thầu'
            THEN t.thoi_gian_gui_thau 
        WHEN {{date_type}} = 'ETD chuyến - ngày dự kiến lấy hàng'
            THEN t.etd_chuyen
        WHEN {{date_type}} = 'ETA chuyến - ngày dự kiến giao hàng'
            THEN t.eta_chuyen
        WHEN {{date_type}} = 'Ngày gửi yêu cầu đơn hàng'
            THEN t.request_date
        WHEN {{date_type}} = 'ATD chuyến - ngày thực tế lấy hàng'
            THEN t.atd_chuyen
        WHEN {{date_type}} = 'ATA chuyến - ngày thực tế giao hàng'
            THEN t.ata_chuyen
        WHEN {{date_type}} = 'Ngày duyệt chuyến'
            THEN t.approved_date
    END)
    BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
        AND toDate(coalesce({{to_date}},   '2999-12-31'))
)
)
SELECT
    ten_ngan_nvt,
    countDistinctIf(so_chuyen, alert_status = 'Normal')               AS normal_cnt,
    countDistinctIf(so_chuyen, alert_status = 'At risk')              AS at_risk_cnt,
    countDistinctIf(so_chuyen, alert_status = 'Late departure open')  AS late_departure_open_cnt,
    countDistinctIf(so_chuyen, alert_status = 'Late departure')       AS late_departure_cnt,
    countDistinctIf(so_chuyen, alert_status = 'Ontime departure')     AS ontime_departure_cnt,
    countDistinctIf(so_chuyen, alert_status = 'Ontime delivery')      AS ontime_delivery_cnt,
    countDistinctIf(so_chuyen, alert_status = 'Late delivery')        AS late_delivery_cnt
FROM base
GROUP BY ten_ngan_nvt
ORDER BY ten_ngan_nvt;
```

---
