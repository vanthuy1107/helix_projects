-- ============================================================================
-- MV: analytics_workspace.mv_mdlz_tms_report_25_order
-- Grain: 1 row = 1 OrderCode  (rollup từ Order × Trip về cấp đơn)
-- Nguồn: analytics_workspace.mdlz_tms_report_25_trip_order
-- Refresh: 1 HOUR (source reload TRUNCATE+reload theo cửa sổ ≤ 5 ngày)
-- Mục đích: rollup cấp đơn — gom các chuyến của 1 OrderCode về 1 row, đồng
--           thời parse sẵn date/number (cột source toàn String) + tính sẵn
--           cờ Ontime/Infull/OTIF + dimension. Reusable cho dashboard &
--           notebook không phải viết lại logic. Khớp 100% với
--           tms_report_25_explore.ipynb (Setup + L6).
--
-- Quy ước (lấy từ notebook):
--   ONTIME  = DateToCome ≤ ETA + 30 phút (grace cứng 30')
--   INFULL  = sum(QuantityBBGN) ≥ max(QuantityOrder)
--   SCOPE   = DeliveryStatus = 'Hoàn tất' khi đánh giá OTIF
--   SO_VALID= OrderCode KHÔNG chứa dấu '-' (đơn mã tách dòng)
--
-- KHÔNG pre-filter MasterStatus — giữ cả đơn 'Chờ'/'Chưa giao' để dashboard
-- vẫn quan sát được pipeline tổng. Caller tự filter `master_status_has_active`
-- nếu chỉ muốn scope L1-L4 ('Đã hoàn thành', 'Đang vận chuyển').
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics_workspace.mv_mdlz_tms_report_25_order
REFRESH EVERY 1 HOUR
(
    -- ── Khoá & phân vùng ────────────────────────────────────────────────────
    `order_code`                   String,
    `tendered_date_vn`             Date    COMMENT 'toDate(TenderedDate) theo VN — dùng partition + filter chính',

    -- ── Cờ trạng thái OTIF (cấp đơn) ────────────────────────────────────────
    `ontime_status`                LowCardinality(String) COMMENT 'Ontime | Failed Ontime | Chưa giao | Thiếu thời gian',
    `infull_status`                LowCardinality(String) COMMENT 'Infull | Failed Infull | Chưa giao | KH = 0',
    `otif_status`                  LowCardinality(String) COMMENT 'OTIF Pass | Failed Ontime | Failed Infull | Failed Both | Not Evaluable',

    -- ── Bộ đếm dòng (giải thích cờ) ─────────────────────────────────────────
    `dong_tong`                    UInt32  COMMENT 'Tổng dòng Order × Trip của đơn',
    `dong_da_giao`                 UInt32  COMMENT 'countIf(DeliveryStatus = Hoàn tất)',
    `dong_eval_ot`                 UInt32  COMMENT 'Số dòng đã giao có đủ ETA + DateToCome để chấm Ontime',
    `dong_tre`                     UInt32  COMMENT 'Số dòng đã giao bị trễ (DateToCome > ETA + 30 phút)',

    -- ── Số lượng (kế hoạch vs giao) ─────────────────────────────────────────
    `kh_qty`                       Float64 COMMENT 'max(QuantityOrder) — KH cấp đơn, KHÔNG cộng dồn qua chuyến',
    `gn_qty`                       Float64 COMMENT 'sum(QuantityBBGN) — thực giao cộng dồn tất cả chuyến',
    `chenh_qty`                    Float64 COMMENT 'gn_qty − kh_qty',
    `kh_ton`                       Float64,
    `gn_ton`                       Float64,
    `kh_cbm`                       Float64,
    `gn_cbm`                       Float64,

    -- ── Latency ─────────────────────────────────────────────────────────────
    `late_phut_max`                Nullable(Int64) COMMENT 'max(dateDiff(minute, ETA, DateToCome)) — chuyến trễ nhất. NULL nếu không có chuyến nào đủ ETA + DateToCome',
    `late_phut_min`                Nullable(Int64) COMMENT 'min(dateDiff) — chuyến sớm nhất (âm = sớm hơn ETA)',

    -- ── Trip rollup ─────────────────────────────────────────────────────────
    `so_chuyen`                    UInt32  COMMENT 'uniqExactIf(MasterCode, MasterCode != "")',
    `master_codes`                 Array(String) COMMENT 'groupUniqArrayIf(MasterCode, MasterCode != "")',
    `master_statuses`              Array(String) COMMENT 'groupUniqArrayIf(MasterStatus, MasterStatus != "")',
    `master_status_has_active`     UInt8   COMMENT '1 nếu có chuyến MasterStatus IN (Đã hoàn thành, Đang vận chuyển) — scope notebook L1-L4',

    -- ── Thuộc tính đơn (any) ────────────────────────────────────────────────
    `service_of_order_name`        LowCardinality(String),
    `order_type`                   LowCardinality(String),
    `order_status`                 LowCardinality(String),
    `delivery_status_first`        LowCardinality(String) COMMENT 'DeliveryStatus của 1 dòng bất kỳ (any) — dùng cho lọc nhanh',

    -- ── Thời gian (parsed) ──────────────────────────────────────────────────
    `order_created_date`           Nullable(DateTime),
    `request_date`                 Nullable(DateTime),
    `tendered_date`                Nullable(DateTime),
    `eta`                          Nullable(DateTime) COMMENT 'ETA của đơn (any — đa số 1 đơn 1 ETA)',
    `etd`                          Nullable(DateTime),
    `date_to_come_max`             Nullable(DateTime) COMMENT 'max(DateToCome) — mốc giao cuối cùng của đơn',

    -- ── Customer / Nhà xe / Kho / Điểm giao ─────────────────────────────────
    `customer_code`                String,
    `customer_name`                String,
    `vendor_code`                  String,
    `vendor_name`                  String,
    `vendor_short_name`            String,
    `stock_code`                   String,
    `stock_name`                   String,
    `ops_location_to_code`         String,
    `ops_location_to_name`         String,
    `ops_location_to_province`     LowCardinality(String),
    `ops_location_to_district`     String,
    `group_of_vehicle_name`        LowCardinality(String),

    -- ── Metadata ────────────────────────────────────────────────────────────
    `src_loaded_at`                DateTime COMMENT 'max(_loaded_at) — thời điểm dòng cuối cùng của đơn được nạp vào staging',
    `_refreshed_at`                DateTime DEFAULT now() COMMENT 'Thời điểm MV refresh sinh ra row này'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toYYYYMM(tendered_date_vn)
ORDER BY (tendered_date_vn, order_code)
SETTINGS index_granularity = 8192
COMMENT 'MDLZ TMS Report #25 — rollup cấp đơn (1 row = 1 OrderCode). Nguồn: mdlz_tms_report_25_trip_order. Có sẵn: cờ Ontime/Infull/OTIF + parsed dates + parsed numbers + trip rollup + dimensions. Logic Ontime (≤ETA+30'')/Infull (sumBBGN≥maxOrder) lấy từ tms_report_25_explore.ipynb. Refresh 1h. Doc: mondelez/02-data/audit-results/tms-report-25-order-mv-20260528.md'
AS
WITH
    base AS (
        SELECT
            t.OrderCode                                                  AS order_code,
            t.MasterCode,
            t.MasterStatus,
            t.DeliveryStatus,
            t.OrderStatus,
            t.OrderType,
            t.ServiceOfOrderName,
            t.VendorCode, t.VendorName, t.VendorShortName,
            t.StockCode,  t.StockName,
            t.CustomerCode, t.CustomerName,
            t.OPSLocationToCode, t.OPSLocationToName,
            t.OPSLocationToProvince, t.OPSLocationToDistrict,
            t.GroupOfVehicleName,
            parseDateTimeBestEffortOrNull(nullIf(t.OrderCreatedDate, ''))    AS dt_order_created,
            parseDateTimeBestEffortOrNull(nullIf(t.RequestDate, ''))         AS dt_request,
            parseDateTimeBestEffortOrNull(nullIf(t.TenderedDate, ''))        AS dt_tendered,
            parseDateTimeBestEffortOrNull(nullIf(t.ETD, ''))                 AS dt_etd,
            parseDateTimeBestEffortOrNull(nullIf(t.ETA, ''))                 AS dt_eta,
            parseDateTimeBestEffortOrNull(nullIf(t.DateToCome, ''))          AS dt_to_come,
            toFloat64OrZero(t.QuantityOrder)                                 AS n_qty_order,
            toFloat64OrZero(t.QuantityBBGN)                                  AS n_qty_bbgn,
            toFloat64OrZero(t.TonOrder)                                      AS n_ton_order,
            toFloat64OrZero(t.TonBBGN)                                       AS n_ton_bbgn,
            toFloat64OrZero(t.CBMOrder)                                      AS n_cbm_order,
            toFloat64OrZero(t.CBMBBGN)                                       AS n_cbm_bbgn,
            t._loaded_at                                                     AS src_loaded_at
        FROM analytics_workspace.mdlz_tms_report_25_trip_order AS t
        WHERE position(t.OrderCode, '-') = 0    -- SO_VALID
          AND t.OrderCode != ''
    ),
    rolled AS (
        SELECT
            order_code,

            -- Counters
            count()                                                                                              AS dong_tong,
            countIf(DeliveryStatus = 'Hoàn tất')                                                                 AS dong_da_giao,
            countIf(DeliveryStatus = 'Hoàn tất' AND dt_to_come IS NOT NULL AND dt_eta IS NOT NULL)               AS dong_eval_ot,
            countIf(DeliveryStatus = 'Hoàn tất' AND dt_to_come IS NOT NULL AND dt_eta IS NOT NULL
                    AND dt_to_come > addMinutes(dt_eta, 30))                                                     AS dong_tre,

            -- Quantities (notebook convention: KH = max per order, GN = sum across trips)
            max(n_qty_order)                                                                                     AS kh_qty,
            sum(n_qty_bbgn)                                                                                      AS gn_qty,
            max(n_ton_order)                                                                                     AS kh_ton,
            sum(n_ton_bbgn)                                                                                      AS gn_ton,
            max(n_cbm_order)                                                                                     AS kh_cbm,
            sum(n_cbm_bbgn)                                                                                      AS gn_cbm,

            -- Latency
            maxOrNull(dateDiff('minute', dt_eta, dt_to_come))                                                    AS late_phut_max,
            minOrNull(dateDiff('minute', dt_eta, dt_to_come))                                                    AS late_phut_min,

            -- Trip rollup
            uniqExactIf(MasterCode, MasterCode != '')                                                            AS so_chuyen,
            groupUniqArrayIf(MasterCode, MasterCode != '')                                                       AS master_codes,
            groupUniqArrayIf(MasterStatus, MasterStatus != '')                                                   AS master_statuses,
            toUInt8(countIf(MasterStatus IN ('Đã hoàn thành', 'Đang vận chuyển')) > 0)                          AS master_status_has_active,

            -- Order attributes (any-style: lấy 1 giá trị non-empty bất kỳ)
            any(ServiceOfOrderName)         AS service_of_order_name,
            any(OrderType)                  AS order_type,
            any(OrderStatus)                AS order_status,
            any(DeliveryStatus)             AS delivery_status_first,

            -- Dates
            any(dt_order_created)           AS order_created_date,
            any(dt_request)                 AS request_date,
            any(dt_tendered)                AS tendered_date,
            any(dt_eta)                     AS eta,
            any(dt_etd)                     AS etd,
            maxOrNull(dt_to_come)           AS date_to_come_max,

            -- Dimensions
            any(CustomerCode)               AS customer_code,
            any(CustomerName)               AS customer_name,
            any(VendorCode)                 AS vendor_code,
            any(VendorName)                 AS vendor_name,
            any(VendorShortName)            AS vendor_short_name,
            any(StockCode)                  AS stock_code,
            any(StockName)                  AS stock_name,
            any(OPSLocationToCode)          AS ops_location_to_code,
            any(OPSLocationToName)          AS ops_location_to_name,
            any(OPSLocationToProvince)      AS ops_location_to_province,
            any(OPSLocationToDistrict)      AS ops_location_to_district,
            any(GroupOfVehicleName)         AS group_of_vehicle_name,

            max(src_loaded_at)              AS src_loaded_at
        FROM base
        GROUP BY order_code
    )
SELECT
    order_code,
    ifNull(toDate(tendered_date), toDate('1970-01-01'))                                                          AS tendered_date_vn,

    -- ── Status labels (khớp tuyệt đối logic L6 notebook) ────────────────────
    multiIf(
        dong_da_giao = 0,                'Chưa giao',
        dong_eval_ot = 0,                'Thiếu thời gian',
        dong_tre > 0,                    'Failed Ontime',
                                         'Ontime'
    )                                                                                                            AS ontime_status,

    multiIf(
        dong_da_giao = 0,                'Chưa giao',
        kh_qty = 0,                      'KH = 0',
        gn_qty >= kh_qty,                'Infull',
                                         'Failed Infull'
    )                                                                                                            AS infull_status,

    multiIf(
        dong_da_giao = 0,                'Not Evaluable',
        dong_eval_ot = 0 OR kh_qty = 0,  'Not Evaluable',
        dong_tre > 0 AND gn_qty < kh_qty,'Failed Both',
        dong_tre > 0,                    'Failed Ontime',
        gn_qty < kh_qty,                 'Failed Infull',
                                         'OTIF Pass'
    )                                                                                                            AS otif_status,

    dong_tong, dong_da_giao, dong_eval_ot, dong_tre,
    kh_qty, gn_qty, (gn_qty - kh_qty)                                                                            AS chenh_qty,
    kh_ton, gn_ton, kh_cbm, gn_cbm,
    late_phut_max, late_phut_min,

    so_chuyen, master_codes, master_statuses, master_status_has_active,

    service_of_order_name, order_type, order_status, delivery_status_first,

    order_created_date, request_date, tendered_date, eta, etd, date_to_come_max,

    customer_code, customer_name,
    vendor_code, vendor_name, vendor_short_name,
    stock_code, stock_name,
    ops_location_to_code, ops_location_to_name,
    ops_location_to_province, ops_location_to_district,
    group_of_vehicle_name,

    src_loaded_at
FROM rolled;
