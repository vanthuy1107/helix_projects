-- =============================================================================
-- DA Assessment — Sample Data Extract
-- Source: ClickHouse Mondelez tenant, database `analytics_workspace`
-- Time window: 2026-02-01 → 2026-04-30 (3 months by eta_giao_hang_cho_npp)
-- Output: 5 raw CSV files in dataset/_internal/raw/
--
-- Verified against DDL: projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.md
-- Verified row counts (2026-05-16):
--   mv_otif total 1.28M, in-window 31,207
--   mv_vfr_van_hanh total 72k, in-window 6,631
--   distinct carriers (otif) = 10, warehouses = 6, areas = 12
-- =============================================================================
--
-- Run via curl (Bash):
--   set -a; source projects/mondelez/.env; set +a
--   curl --silent --show-error --fail-with-body \
--     --user "$CLICKHOUSE_USER:$CLICKHOUSE_PASSWORD" \
--     "https://$CLICKHOUSE_HOST:$CLICKHOUSE_PORT/?max_execution_time=120" \
--     --data-binary @01_shipments.sql > raw/shipments_raw.csv
--
-- Each block below is a standalone SELECT. Run separately to get 5 CSVs.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. shipments_raw.csv — Fact OTIF (1 dòng / SO)
-- -----------------------------------------------------------------------------
-- Source: mv_otif (REFRESH EVERY 5 MINUTE)
-- Expected: ~31,207 rows for window
-- Status values from MV:
--   ontime_status:  'Ontime' | 'Failed Ontime' | 'Không có dữ liệu STM' | NULL
--   infull_status:  'Infull' | 'Failed Infull' | 'Không có dữ liệu STM' | NULL
--   otif_status:    'OTIF'   | 'Failed OTIF'   | 'Không có dữ liệu STM'         (NOT Nullable)
-- We KEEP these original VN labels in raw — anonymize.py will map to EN.

SELECT
    ifNull(so, '')                                              AS shipment_id_raw,
    whseid                                                      AS warehouse_code_raw,
    khu_vuc_doi_xe                                              AS delivery_area_raw,
    ifNull(group_of_cago, 'Unclassified')                       AS cargo_group_raw,
    ten_ngan_nha_van_tai                                        AS carrier_code_raw,
    group_name                                                  AS sales_channel_raw,
    ifNull(loai_xe_van_hanh, '')                                AS vehicle_type_raw,
    toDate(ngay_gi)                                             AS gi_date,
    toString(etd_chuyen_gui_thau)                               AS etd_planned,
    toString(eta_giao_hang_cho_npp)                             AS eta_planned,
    toString(actual_ship_date)                                  AS atd_actual,
    toString(ata_den)                                           AS ata_actual,
    ifNull(ontime_status, '')                                   AS ontime_status_raw,
    ifNull(infull_status, '')                                   AS infull_status_raw,
    otif_status                                                 AS otif_status_raw,
    toFloat64(ifNull(sum_original_cse, 0))                      AS planned_qty_cse,
    toFloat64(ifNull(sum_original_kg, 0))                       AS planned_weight_kg,
    toFloat64(ifNull(sum_original_cbm, 0))                      AS planned_volume_cbm,
    toFloat64(ifNull(sum_original_pl, 0))                       AS planned_pallets,
    toFloat64(ifNull(sum_san_luong_giao_cse, 0))                AS delivered_qty_cse
FROM analytics_workspace.mv_otif
WHERE toDate(eta_giao_hang_cho_npp) BETWEEN toDate('2026-02-01') AND toDate('2026-04-30')
ORDER BY eta_giao_hang_cho_npp, so
FORMAT CSVWithNames;


-- -----------------------------------------------------------------------------
-- 2. trips_raw.csv — Fact VFR (1 dòng / chuyến vận hành)
-- -----------------------------------------------------------------------------
-- Source: mv_vfr_van_hanh (REFRESH EVERY 1 HOUR)
-- Expected: ~6,631 rows for window

SELECT
    ma_chuyen_van_hanh                                          AS trip_id_raw,
    toDate(tender_date)                                         AS tender_date,
    toString(eta_vh)                                            AS eta_operation,
    toString(ata_vh)                                            AS ata_operation,
    ifNull(diem_nhan, '')                                       AS pickup_location_raw,
    ifNull(khu_vuc_doi_xe, '')                                  AS delivery_area_raw,
    ifNull(nha_van_tai, '')                                     AS carrier_code_raw,
    loai_xe_van_hanh                                            AS vehicle_type_raw,
    nhom_hang_hoa                                               AS cargo_group_raw,
    toFloat64(vfr_max)                                          AS vfr_pct,
    toFloat64(vfr_theo_tan)                                     AS vfr_by_ton,
    toFloat64(vfr_theo_khoi)                                    AS vfr_by_volume,
    toFloat64(ifNull(tan_ke_hoach, 0))                          AS planned_ton,
    toFloat64(ifNull(cbm_ke_hoach, 0))                          AS planned_cbm
FROM analytics_workspace.mv_vfr_van_hanh
WHERE toDate(eta_vh) BETWEEN toDate('2026-02-01') AND toDate('2026-04-30')
ORDER BY eta_vh, ma_chuyen_van_hanh
FORMAT CSVWithNames;


-- -----------------------------------------------------------------------------
-- 3. carriers_raw.csv — Dim carrier
-- -----------------------------------------------------------------------------
-- Source: mv_filter_vendor (vendor_code, short_name)
-- Expected: ~10 carriers (small dim)

SELECT DISTINCT
    vendor_code                                                 AS carrier_code_raw,
    short_name                                                  AS carrier_short_name_raw
FROM analytics_workspace.mv_filter_vendor
ORDER BY vendor_code
FORMAT CSVWithNames;


-- -----------------------------------------------------------------------------
-- 4. locations_raw.csv — Dim warehouse + delivery area
-- -----------------------------------------------------------------------------
-- Source A: mv_filter_warehouse (whseid, whseid_name, group_whseid_name)
-- Source B: mv_filter_region (group_area_code, group_area_name)

SELECT
    'WAREHOUSE'                                                 AS location_type,
    whseid                                                      AS location_code_raw,
    whseid_name                                                 AS location_name_raw,
    group_whseid_name                                           AS location_group_raw
FROM analytics_workspace.mv_filter_warehouse
UNION ALL
SELECT
    'DELIVERY_AREA'                                             AS location_type,
    group_area_code                                             AS location_code_raw,
    group_area_name                                             AS location_name_raw,
    ''                                                          AS location_group_raw
FROM analytics_workspace.mv_filter_region
ORDER BY location_type, location_code_raw
FORMAT CSVWithNames;


-- -----------------------------------------------------------------------------
-- 5. products_raw.csv — Dim brand + cargo group + sales channel
-- -----------------------------------------------------------------------------
-- Source A: mv_filter_cargo_brand (group_of_cargo_code, group_of_cargo_name, brand_code, brand_name)
-- Source B: mv_filter_channel (channel_code, channel_name)
-- NOTE: brand không denormalize xuống shipments — chỉ tồn tại như independent dim.
-- Đây là realistic gap (FK gap) — candidate sẽ gặp và phải tự xử lý.

SELECT DISTINCT
    'BRAND_CARGO'                                               AS dim_type,
    ifNull(brand_code, 'Other')                                 AS code_raw,
    ifNull(brand_name, 'Other')                                 AS name_raw,
    ifNull(group_of_cargo_code, 'Unclassified')                 AS parent_group_raw
FROM analytics_workspace.mv_filter_cargo_brand
WHERE brand_code IS NOT NULL OR group_of_cargo_code IS NOT NULL

UNION ALL

SELECT DISTINCT
    'SALES_CHANNEL'                                             AS dim_type,
    channel_code                                                AS code_raw,
    channel_name                                                AS name_raw,
    ''                                                          AS parent_group_raw
FROM analytics_workspace.mv_filter_channel
ORDER BY dim_type, code_raw
FORMAT CSVWithNames;


-- =============================================================================
-- Caveats
-- =============================================================================
-- 1. Brand KHÔNG join trực tiếp với shipments — chỉ tồn tại như dim độc lập.
--    Đây là realistic data gap, candidate phải tự nhận ra và quyết định cách xử lý.
-- 2. Trips KHÔNG link 1-1 với shipments — candidate tự suy luận khi cần.
-- 3. Status values lưu nguyên VN từ MV (vd 'Không có dữ liệu STM') — anonymize.py
--    sẽ map sang EN labels ('Unknown') để dataset có audience English-friendly.
-- 4. Cột `delivered_qty_cse` (sum_san_luong_giao_cse) — số lượng thực tế giao.
--    Hữu ích để candidate tự verify infull_status logic nếu muốn.
