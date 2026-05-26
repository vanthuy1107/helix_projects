-- ClickHouse DDL Snapshot: analytics_workspace
-- Generated: 2026-05-16 03:10 UTC
-- Total: 70 objects
-- ────────────────────────────────────────────────────────────

-- ════════════════════════════════════════════════════
-- Object: mv_alert_late_do  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_alert_late_do
REFRESH EVERY 5 MINUTE
(
    `so_chuyen` Nullable(String) COMMENT 'Mã chuyến vận hành',
    `whseid` Nullable(String) COMMENT 'Mã kho (SWM)',
    `trang_thai_chuyen` Nullable(String) COMMENT 'Trạng thái chuyến (tính động)',
    `trang_thai_chuyen_stm` Nullable(String) COMMENT 'Trạng thái chuyến gốc từ STM',
    `group_of_cago` Nullable(String) COMMENT 'Nhóm hàng đại diện',
    `group` Nullable(String) COMMENT 'Kênh (Group/channel)',
    `customer_code` Nullable(String) COMMENT 'Mã khách hàng',
    `customer_name` Nullable(String) COMMENT 'Tên khách hàng',
    `khu_vuc_doi_xe` Nullable(String) COMMENT 'Khu vực đội xe',
    `ten_ngan_nvt` Nullable(String) COMMENT 'Tên ngắn nhà vận tải',
    `ma_doi_tac_nhan` Nullable(String) COMMENT 'Mã đối tác nhận',
    `ten_doi_tac_nhan` Nullable(String) COMMENT 'Tên đối tác nhận',
    `thoi_gian_gui_thau` Nullable(DateTime64(3, 'UTC')) COMMENT 'Thời gian gửi thầu',
    `ngay_tao_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày tạo chuyến',
    `etd_chuyen_gui_thau` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETD chuyến gửi thầu',
    `gio_dang_tai` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ đăng tài',
    `gio_goi_xe` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ gọi xe',
    `gio_vao_cong` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ vào cổng',
    `gio_vao_dock` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ vào dock',
    `actual_ship_date` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày thực xuất kho',
    `gio_ra_dock` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ ra dock',
    `gio_ra_cong` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ ra cổng',
    `tg_bat_buoc_roi_kho` Nullable(DateTime64(3, 'UTC')) COMMENT 'TG bắt buộc rời kho',
    `eta_giao_hang_cho_npp` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETA giao hàng cho NPP',
    `ata_den` Nullable(DateTime64(3, 'UTC')) COMMENT 'ATA đến điểm giao',
    `ata_roi` Nullable(DateTime64(3, 'UTC')) COMMENT 'ATA rời điểm giao',
    `so_xe` Nullable(String) COMMENT 'Biển số xe',
    `tai_xe` Nullable(String) COMMENT 'Tài xế',
    `ma_nha_xe` Nullable(String) COMMENT 'Mã nhà xe',
    `sum_original` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL đặt (masterunit)',
    `sum_original_cbm` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL đặt CBM',
    `sum_original_kg` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL đặt KG',
    `sum_original_cse` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL đặt CSE',
    `sum_original_pl` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL đặt PL',
    `sum_shipped` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL pick (masterunit)',
    `sum_shipped_cbm` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL pick CBM',
    `sum_shipped_kg` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL pick KG',
    `sum_shipped_cse` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL pick CSE',
    `sum_shipped_pl` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL pick PL',
    `sum_san_luong_giao` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL giao BBGN (masterunit)',
    `sum_san_luong_giao_cbm` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL giao BBGN CBM',
    `sum_san_luong_giao_kg` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL giao BBGN KG',
    `sum_san_luong_giao_cse` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL giao BBGN CSE',
    `sum_san_luong_giao_pl` Nullable(Decimal(18, 4)) COMMENT 'Tổng SL giao BBGN PL',
    `diff_sl_giao_cho` Nullable(Decimal(18, 4)) COMMENT 'Chênh lệch (shipped - giao BBGN)',
    `diff_sl_giao_cho_cbm` Nullable(Decimal(18, 4)) COMMENT 'Chênh lệch CBM',
    `diff_sl_giao_cho_kg` Nullable(Decimal(18, 4)) COMMENT 'Chênh lệch KG',
    `diff_sl_giao_cho_cse` Nullable(Decimal(18, 4)) COMMENT 'Chênh lệch CSE',
    `diff_sl_giao_cho_pl` Nullable(Decimal(18, 4)) COMMENT 'Chênh lệch PL',
    `total_time_in_warehouse_minute` Nullable(Int64) COMMENT 'Thời gian trong kho (phút)',
    `total_time_loading_minute` Nullable(Int64) COMMENT 'Thời gian giao hàng (phút)',
    `diff_delivery_time_hour` Nullable(Int64) COMMENT 'Chênh lệch giao hàng (giờ)',
    `phut_tre_roi_kho` Nullable(String) COMMENT 'Concat phút trễ rời kho',
    `phut_tre_giao_npp` Nullable(String) COMMENT 'Concat phút trễ giao NPP',
    `ds_ma_don_trong_chuyen` Nullable(String) COMMENT 'Danh sách mã đơn trong chuyến',
    `alert_status` Nullable(String) COMMENT 'Trạng thái cảnh báo',
    `ly_do_tre_hoan_thanh` Nullable(String) COMMENT 'Lý do trễ khi Late delivery + Đã hoàn thành',
    `etd_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETD chuyến (dim_ops_trip.etd)',
    `eta_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETA chuyến (dim_ops_trip.eta)',
    `ata_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'ATA chuyến (dim_ops_trip.ata)',
    `atd_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'ATD chuyến (dim_ops_trip.atd)',
    `request_date` Nullable(DateTimsquad1@gosmartlog.come64(3, 'UTC')) COMMENT 'Ngày yêu cầu đơn hàng',
    `approved_date` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày duyệt chuyến',
    `so_km` Nullable(Int64) COMMENT 'Số km từ kho đến điểm giao đầu tiên',
    `van_toc` Nullable(Int64) COMMENT 'Vận tốc'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY so_chuyen
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH alert_status_calc AS
    (
        SELECT
            p.so_chuyen,
            p.whseid,
            multiIf((p.trang_thai_chuyen = 'Chưa vận chuyển') OR ((p.trang_thai_chuyen = 'Đang vận chuyển') AND (p.gio_dang_tai IS NULL)), 'Đang tới kho', (p.gio_dang_tai IS NOT NULL) AND (p.gio_vao_cong IS NULL), 'Đã đăng tài', (p.gio_vao_cong IS NOT NULL) AND (p.gio_vao_dock IS NULL), 'Đã vào cổng', (p.gio_vao_dock IS NOT NULL) AND (p.gio_ra_dock IS NULL) AND (p.tat_ca_don_shipped_trip = 1), 'Đã lên hàng', (p.gio_vao_dock IS NOT NULL) AND (p.gio_ra_dock IS NULL), 'Đã vào dock', (p.gio_ra_dock IS NOT NULL) AND (p.gio_ra_cong IS NULL), 'Đã ra dock', (p.gio_ra_cong IS NOT NULL) AND (p.max_ata_roi_trip IS NULL), 'Đã ra cổng,\r\n\r\n\r\n\r\n đang trên đường giao', (p.gio_ra_cong IS NOT NULL) AND (p.max_ata_roi_trip IS NOT NULL) AND (p.cnt_line_co_ata_roi > 0) AND (p.cnt_line_chua_ata_roi > 0), 'Giao một phần', (p.gio_ra_cong IS NOT NULL) AND (p.max_ata_roi_trip IS NOT NULL) AND (p.cnt_line_chua_ata_roi = 0) AND (p.cnt_line_trip > 0), 'Đã giao/đã hoàn thành', NULL) AS trang_thai_chuyen,
            p.trang_thai_chuyen AS trang_thai_chuyen_stm,
            p.group_of_cago,
            p.channel,
            p.customer_code,
            p.customer_name,
            p.khu_vuc_doi_xe,
            p.ten_ngan_nvt,
            p.ma_doi_tac_nhan,
            p.ten_doi_tac_nhan,
            p.thoi_gian_gui_thau,
            p.ngay_tao_chuyen,
            p.etd_chuyen_gui_thau,
            p.gio_dang_tai,
            p.gio_goi_xe,
            p.gio_vao_cong,
            p.gio_vao_dock,
            p.actual_ship_date,
            p.gio_ra_dock,
            p.gio_ra_cong,
            p.tg_bat_buoc_roi_kho,
            p.eta_giao_hang_cho_npp,
            p.ata_den,
            p.ata_roi,
            p.etd_chuyen,
            p.eta_chuyen,
            p.ata_chuyen,
            p.atd_chuyen,
            p.request_date,
            p.approved_date,
            p.so_xe,
            p.tai_xe,
            p.ma_nha_xe,
            p.sum_original,
            p.sum_original_cbm,
            p.sum_original_kg,
            p.sum_original_cse,
            p.sum_original_pl,
            p.sum_shipped,
            p.sum_shipped_cbm,
            p.sum_shipped_kg,
            p.sum_shipped_cse,
            p.sum_shipped_pl,
            p.sum_giao,
            p.sum_giao_cbm,
            p.sum_giao_kg,
            p.sum_giao_cse,
            p.sum_giao_pl,
            p.max_ata_roi_trip,
            p.cnt_line_trip,
            p.cnt_line_co_ata_roi,
            p.cnt_line_chua_ata_roi,
            p.cnt_line_late_vs_eta,
            multiIf((p.max_ata_roi_trip IS NOT NULL) AND (p.cnt_line_trip > 0), multiIf(p.cnt_line_late_vs_eta > 0, 'Late delivery', 'Ontime delivery'), (p.gio_ra_cong IS NOT NULL) AND (p.max_ata_roi_trip IS NULL), multiIf(p.tg_bat_buoc_roi_kho IS NULL, 'N/A', p.gio_ra_cong < p.tg_bat_buoc_roi_kho, 'Ontime departure', p.gio_ra_cong >= p.tg_bat_buoc_roi_kho, 'Late departure', 'N/A'), (p.gio_ra_cong IS NULL) AND (p.tg_bat_buoc_roi_kho IS NOT NULL) AND (now64(3) < (p.tg_bat_buoc_roi_kho - toIntervalMinute(45))), 'Normal', (p.gio_ra_cong IS NULL) AND (p.tg_bat_buoc_roi_kho IS NOT NULL) AND (now64(3) >= (p.tg_bat_buoc_roi_kho - toIntervalMinute(45))) AND (now64(3) <= p.tg_bat_buoc_roi_kho), 'At risk', (p.gio_ra_cong IS NULL) AND (p.tg_bat_buoc_roi_kho IS NOT NULL) AND (now64(3) > p.tg_bat_buoc_roi_kho), 'Late departure open', 'N/A') AS alert_status
        FROM analytics_workspace.mv_alert_late_do_so_pick AS p
    )
SELECT
    a.so_chuyen,
    a.whseid,
    a.trang_thai_chuyen,
    a.trang_thai_chuyen_stm,
    a.group_of_cago,
    a.channel AS group,
    a.customer_code,
    a.customer_name,
    a.khu_vuc_doi_xe,
    a.ten_ngan_nvt,
    a.ma_doi_tac_nhan,
    a.ten_doi_tac_nhan,
    a.thoi_gian_gui_thau AS thoi_gian_gui_thau,
    a.ngay_tao_chuyen AS ngay_tao_chuyen,
    a.etd_chuyen_gui_thau AS etd_chuyen_gui_thau,
    a.gio_dang_tai AS gio_dang_tai,
    a.gio_goi_xe AS gio_goi_xe,
    a.gio_vao_cong AS gio_vao_cong,
    a.gio_vao_dock AS gio_vao_dock,
    a.actual_ship_date,
    a.gio_ra_dock AS gio_ra_dock,
    a.gio_ra_cong AS gio_ra_cong,
    a.tg_bat_buoc_roi_kho AS tg_bat_buoc_roi_kho,
    a.eta_giao_hang_cho_npp AS eta_giao_hang_cho_npp,
    a.ata_den AS ata_den,
    a.ata_roi AS ata_roi,
    a.etd_chuyen,
    a.eta_chuyen,
    a.ata_chuyen,
    a.atd_chuyen,
    a.request_date,
    a.approved_date,
    a.so_xe,
    a.tai_xe,
    a.ma_nha_xe,
    a.sum_original,
    a.sum_original_cbm,
    a.sum_original_kg,
    a.sum_original_cse,
    a.sum_original_pl,
    a.sum_shipped,
    a.sum_shipped_cbm,
    a.sum_shipped_kg,
    a.sum_shipped_cse,
    a.sum_shipped_pl,
    a.sum_giao AS sum_san_luong_giao,
    a.sum_giao_cbm AS sum_san_luong_giao_cbm,
    a.sum_giao_kg AS sum_san_luong_giao_kg,
    a.sum_giao_cse AS sum_san_luong_giao_cse,
    a.sum_giao_pl AS sum_san_luong_giao_pl,
    a.sum_shipped - a.sum_giao AS diff_sl_giao_cho,
    a.sum_shipped_cbm - a.sum_giao_cbm AS diff_sl_giao_cho_cbm,
    a.sum_shipped_kg - a.sum_giao_kg AS diff_sl_giao_cho_kg,
    a.sum_shipped_cse - a.sum_giao_cse AS diff_sl_giao_cho_cse,
    a.sum_shipped_pl - a.sum_giao_pl AS diff_sl_giao_cho_pl,
    dateDiff('minute', a.gio_vao_cong, a.gio_ra_cong) AS total_time_in_warehouse_minute,
    dateDiff('minute', a.ata_den, a.ata_roi) AS total_time_loading_minute,
    dateDiff('hour', a.eta_giao_hang_cho_npp, a.ata_den) AS diff_delivery_time_hour,
    c.concat_do_phut_roi_kho AS phut_tre_roi_kho,
    c.concat_do_phut_giao_npp AS phut_tre_giao_npp,
    c.concat_ma_don_chuyen AS ds_ma_don_trong_chuyen,
    a.alert_status,
    multiIf((a.alert_status = 'Late delivery') AND (a.trang_thai_chuyen = 'Đã giao/đã hoàn thành'), c.concat_do_ly_do, NULL) AS ly_do_tre_hoan_thanh,
    multiIf((eta_giao_hang_cho_npp IS NULL) OR (tg_bat_buoc_roi_kho IS NULL), NULL, dateDiff('minute', tg_bat_buoc_roi_kho, eta_giao_hang_cho_npp) <= 0, NULL, (((intDiv(dateDiff('minute', tg_bat_buoc_roi_kho, eta_giao_hang_cho_npp), 255) * 240) + least(modulo(dateDiff('minute', tg_bat_buoc_roi_kho, eta_giao_hang_cho_npp), 255), 240)) / 60.) * multiIf((a.whseid IN ('BKD1', 'BKD2', 'BKD', 'VN821')), 40, (a.whseid IN ('NKD', 'VN831')), 50, NULL)) AS so_km,
    multiIf((a.whseid IN ('BKD1', 'BKD2', 'BKD', 'VN821')), 40, (a.whseid IN ('NKD', 'VN831')), 50, NULL) AS van_toc
FROM
alert_status_calc AS a
LEFT JOIN analytics_workspace.mv_alert_late_do_concat AS c ON a.so_chuyen = c.so_chuyen


-- ════════════════════════════════════════════════════
-- Object: mv_alert_late_do_base  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_alert_late_do_base
REFRESH EVERY 5 MINUTE
(
    `whseid` Nullable(String),
    `whseid_stm` Nullable(String),
    `so` Nullable(String),
    `order_line_number` String,
    `so_chuyen` Nullable(String),
    `trang_thai_chuyen` Nullable(String),
    `group_of_cago` Nullable(String),
    `channel` Nullable(String),
    `customer_code` Nullable(String),
    `customer_name` Nullable(String),
    `khu_vuc_doi_xe` Nullable(String),
    `ten_ngan_nvt` Nullable(String),
    `ma_nha_xe` Nullable(String),
    `ma_doi_tac_nhan` Nullable(String),
    `ten_doi_tac_nhan` Nullable(String),
    `status` Nullable(String),
    `uom` Nullable(String),
    `actual_ship_date` Nullable(DateTime64(3, 'UTC')),
    `thoi_gian_gui_thau` Nullable(DateTime64(3, 'UTC')),
    `ngay_tao_chuyen` Nullable(DateTime64(3, 'UTC')),
    `etd_chuyen_gui_thau` Nullable(DateTime64(3, 'UTC')),
    `gio_dang_tai` Nullable(DateTime64(3, 'UTC')),
    `gio_goi_xe` Nullable(DateTime64(3, 'UTC')),
    `gio_vao_cong` Nullable(DateTime64(3, 'UTC')),
    `gio_vao_dock` Nullable(DateTime64(3, 'UTC')),
    `tg_bat_buoc_roi_kho` Nullable(DateTime64(3, 'UTC')),
    `gio_ra_dock` Nullable(DateTime64(3, 'UTC')),
    `gio_ra_cong` Nullable(DateTime64(3, 'UTC')),
    `eta_giao_hang_cho_npp` Nullable(DateTime64(3, 'UTC')),
    `ata_den` Nullable(DateTime64(3, 'UTC')),
    `ata_roi` Nullable(DateTime64(3, 'UTC')),
    `so_xe` Nullable(String),
    `tai_xe` Nullable(String),
    `original` Nullable(Decimal(18, 4)),
    `original_cbm` Nullable(Decimal(18, 4)),
    `original_kg` Nullable(Decimal(18, 4)),
    `original_cse` Nullable(Decimal(18, 4)),
    `original_pl` Nullable(Decimal(18, 4)),
    `shipped` Nullable(Decimal(18, 4)),
    `shipped_cbm` Nullable(Decimal(18, 4)),
    `shipped_kg` Nullable(Decimal(18, 4)),
    `shipped_cse` Nullable(Decimal(18, 4)),
    `shipped_pl` Nullable(Decimal(18, 4)),
    `san_luong_giao` Nullable(Decimal(18, 4)),
    `san_luong_giao_cbm` Nullable(Decimal(18, 4)),
    `san_luong_giao_kg` Nullable(Decimal(18, 4)),
    `san_luong_giao_cse` Nullable(Decimal(18, 4)),
    `san_luong_giao_pl` Nullable(Decimal(18, 4)),
    `group_priority` Int32,
    `phut_roi_line` Nullable(Int64),
    `phut_giao_line` Nullable(Int64),
    `ly_do_line` Nullable(String),
    `etd_chuyen` Nullable(DateTime64(3, 'UTC')),
    `eta_chuyen` Nullable(DateTime64(3, 'UTC')),
    `ata_chuyen` Nullable(DateTime64(3, 'UTC')),
    `atd_chuyen` Nullable(DateTime64(3, 'UTC')),
    `request_date` Nullable(DateTime64(3, 'UTC')),
    `approved_date` Nullable(DateTime64(3, 'UTC'))
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (so_chuyen, so, order_line_number)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH base AS
    (
        SELECT
            t.*,
            multiIf(upperUTF8(trimBoth(t.group_of_cago)) = 'FRESH', 1, upperUTF8(trimBoth(t.group_of_cago)) = 'DRY', 2, upperUTF8(trimBoth(t.group_of_cago)) = 'MOONCAKE', 3, (upperUTF8(trimBoth(t.group_of_cago)) IN ('POSM', 'OFFBOM', 'POSM/OFFBOM')), 4, upperUTF8(trimBoth(t.group_of_cago)) = 'TEST', 5, upperUTF8(trimBoth(t.group_of_cago)) = 'EQUIPMENT', 6, upperUTF8(trimBoth(t.group_of_cago)) = 'PM', 7, 99) AS group_priority,
            multiIf((t.tg_bat_buoc_roi_kho = toDateTime64('1900-01-01 00:00:00', 3)) OR (t.tg_bat_buoc_roi_kho IS NULL), NULL, (t.gio_ra_cong = toDateTime64('1900-01-01 00:00:00', 3)) OR (t.gio_ra_cong IS NULL), NULL, dateDiff('minute', t.tg_bat_buoc_roi_kho, t.gio_ra_cong) <= 0, NULL, dateDiff('minute', t.tg_bat_buoc_roi_kho, t.gio_ra_cong)) AS phut_roi_line,
            multiIf((t.eta_giao_hang_cho_npp = toDateTime64('1900-01-01 00:00:00', 3)) OR (t.eta_giao_hang_cho_npp IS NULL), NULL, (t.ata_roi = toDateTime64('1900-01-01 00:00:00', 3)) OR (t.ata_roi IS NULL), NULL, dateDiff('minute', t.eta_giao_hang_cho_npp, t.ata_roi) <= 0, NULL, dateDiff('minute', t.eta_giao_hang_cho_npp, t.ata_roi)) AS phut_giao_line
        FROM analytics_workspace.mv_alert_stm_swm_data AS t
    )
SELECT
    whseid,
    whseid_stm,
    so,
    order_line_number,
    so_chuyen,
    trang_thai_chuyen,
    group_of_cago,
    channel,
    customer_code,
    customer_name,
    khu_vuc_doi_xe,
    ten_ngan_nvt,
    ma_nha_xe,
    ma_doi_tac_nhan,
    ten_doi_tac_nhan,
    status,
    uom,
    actual_ship_date,
    thoi_gian_gui_thau,
    ngay_tao_chuyen,
    etd_chuyen_gui_thau,
    gio_dang_tai,
    gio_goi_xe,
    gio_vao_cong,
    gio_vao_dock,
    tg_bat_buoc_roi_kho,
    gio_ra_dock,
    gio_ra_cong,
    eta_giao_hang_cho_npp,
    ata_den,
    ata_roi,
    so_xe,
    tai_xe,
    original,
    original_cbm,
    original_kg,
    original_cse,
    original_pl,
    shipped,
    shipped_cbm,
    shipped_kg,
    shipped_cse,
    shipped_pl,
    san_luong_giao,
    san_luong_giao_cbm,
    san_luong_giao_kg,
    san_luong_giao_cse,
    san_luong_giao_pl,
    group_priority,
    phut_roi_line,
    phut_giao_line,
    multiIf((phut_roi_line IS NOT NULL) AND (phut_giao_line IS NOT NULL) AND (phut_roi_line >= phut_giao_line), 'Rời kho trễ', (phut_roi_line IS NOT NULL) AND (phut_giao_line IS NOT NULL) AND (phut_roi_line < phut_giao_line), 'Rời kho trễ + Vận tải giao trễ', (phut_roi_line IS NULL) AND (phut_giao_line IS NOT NULL), 'Vận tải giao trễ', (phut_roi_line IS NOT NULL) AND (phut_giao_line IS NULL), 'Rời kho trễ', NULL) AS ly_do_line,
    etd_chuyen,
    eta_chuyen,
    ata_chuyen,
    atd_chuyen,
    request_date,
    approved_date
FROM
base


-- ════════════════════════════════════════════════════
-- Object: mv_alert_late_do_concat  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_alert_late_do_concat
REFRESH EVERY 5 MINUTE
(
    `so_chuyen` Nullable(String),
    `concat_do_ly_do` Nullable(String),
    `concat_do_phut_roi_kho` Nullable(String),
    `concat_do_phut_giao_npp` Nullable(String),
    `concat_ma_don_chuyen` Nullable(String)
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY so_chuyen
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    per_so_worst_line AS
    (
        SELECT *
        FROM
        (
            SELECT
                b.*,
                row_number() OVER (PARTITION BY b.so_chuyen, b.so ORDER BY multiIf(ifNull(b.ly_do_line, '') = 'Rời kho trễ + Vận tải giao trễ', 1, ifNull(b.ly_do_line, '') = 'Rời kho trễ', 2, ifNull(b.ly_do_line, '') = 'Vận tải giao trễ', 3, 9) ASC, ifNull(b.phut_giao_line, 0) DESC, b.order_line_number ASC) AS rn_so
            FROM analytics_workspace.mv_alert_late_do_base AS b
        ) AS z
        WHERE z.rn_so = 1
    ),
    per_so_concat_limited AS
    (
        SELECT
            w.*,
            row_number() OVER (PARTITION BY w.so_chuyen ORDER BY w.so ASC) AS rn_concat
        FROM
        per_so_worst_line AS w
    )
SELECT
    so_chuyen,
    arrayStringConcat(groupArray(120)(substring(concat(so, ': ', ifNull(ly_do_line, 'Đúng giờ')), 1, 256)), ' | ') AS concat_do_ly_do,
    arrayStringConcat(groupArray(120)(substring(concat(so, ': ', ifNull(toString(phut_roi_line), '-'), ' phút'), 1, 256)), ' | ') AS concat_do_phut_roi_kho,
    arrayStringConcat(groupArray(120)(substring(concat(so, ': ', ifNull(toString(phut_giao_line), '-'), ' phút'), 1, 256)), ' | ') AS concat_do_phut_giao_npp,
    arrayStringConcat(groupArray(120)(substring(trimBoth(so), 1, 256)), ',\r\n ') AS concat_ma_don_chuyen
FROM
per_so_concat_limited
WHERE rn_concat <= 120
GROUP BY so_chuyen


-- ════════════════════════════════════════════════════
-- Object: mv_alert_late_do_so_pick  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_alert_late_do_so_pick
REFRESH EVERY 5 MINUTE
(
    `so_chuyen` Nullable(String),
    `whseid` Nullable(String),
    `trang_thai_chuyen` Nullable(String),
    `group_of_cago` Nullable(String),
    `channel` Nullable(String),
    `customer_code` Nullable(String),
    `customer_name` Nullable(String),
    `khu_vuc_doi_xe` Nullable(String),
    `ten_ngan_nvt` Nullable(String),
    `ma_nha_xe` Nullable(String),
    `ma_doi_tac_nhan` Nullable(String),
    `ten_doi_tac_nhan` Nullable(String),
    `actual_ship_date` Nullable(DateTime64(3, 'UTC')),
    `thoi_gian_gui_thau` Nullable(DateTime64(3, 'UTC')),
    `ngay_tao_chuyen` Nullable(DateTime64(3, 'UTC')),
    `etd_chuyen_gui_thau` Nullable(DateTime64(3, 'UTC')),
    `gio_dang_tai` Nullable(DateTime64(3, 'UTC')),
    `gio_goi_xe` Nullable(DateTime64(3, 'UTC')),
    `gio_vao_cong` Nullable(DateTime64(3, 'UTC')),
    `gio_vao_dock` Nullable(DateTime64(3, 'UTC')),
    `tg_bat_buoc_roi_kho` Nullable(DateTime64(3, 'UTC')),
    `gio_ra_dock` Nullable(DateTime64(3, 'UTC')),
    `gio_ra_cong` Nullable(DateTime64(3, 'UTC')),
    `eta_giao_hang_cho_npp` Nullable(DateTime64(3, 'UTC')),
    `ata_den` Nullable(DateTime64(3, 'UTC')),
    `ata_roi` Nullable(DateTime64(3, 'UTC')),
    `so_xe` Nullable(String),
    `tai_xe` Nullable(String),
    `sum_original` Nullable(Decimal(18, 4)),
    `sum_original_cbm` Nullable(Decimal(18, 4)),
    `sum_original_kg` Nullable(Decimal(18, 4)),
    `sum_original_cse` Nullable(Decimal(18, 4)),
    `sum_original_pl` Nullable(Decimal(18, 4)),
    `sum_shipped` Nullable(Decimal(18, 4)),
    `sum_shipped_cbm` Nullable(Decimal(18, 4)),
    `sum_shipped_kg` Nullable(Decimal(18, 4)),
    `sum_shipped_cse` Nullable(Decimal(18, 4)),
    `sum_shipped_pl` Nullable(Decimal(18, 4)),
    `sum_giao` Nullable(Decimal(18, 4)),
    `sum_giao_cbm` Nullable(Decimal(18, 4)),
    `sum_giao_kg` Nullable(Decimal(18, 4)),
    `sum_giao_cse` Nullable(Decimal(18, 4)),
    `sum_giao_pl` Nullable(Decimal(18, 4)),
    `max_ata_roi_trip` Nullable(DateTime64(3, 'UTC')),
    `cnt_line_trip` UInt64,
    `cnt_line_co_ata_roi` UInt64,
    `cnt_line_chua_ata_roi` UInt64,
    `cnt_line_late_vs_eta` UInt64,
    `tat_ca_don_shipped_trip` UInt8,
    `etd_chuyen` Nullable(DateTime64(3, 'UTC')),
    `eta_chuyen` Nullable(DateTime64(3, 'UTC')),
    `ata_chuyen` Nullable(DateTime64(3, 'UTC')),
    `atd_chuyen` Nullable(DateTime64(3, 'UTC')),
    `request_date` Nullable(DateTime64(3, 'UTC')),
    `approved_date` Nullable(DateTime64(3, 'UTC'))
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY so_chuyen
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    so_pick AS
    (
        SELECT *
        FROM
        (
            SELECT
                b.*,
                row_number() OVER (PARTITION BY b.so_chuyen ORDER BY b.eta_giao_hang_cho_npp ASC, b.group_priority ASC, if(b.order_line_number = '', 1, 0) ASC, b.order_line_number ASC) AS rn
            FROM analytics_workspace.mv_alert_late_do_base AS b
        ) AS x
        WHERE x.rn = 1
    ),
    so_sum AS
    (
        SELECT
            b.so_chuyen,
            sum(ifNull(b.original, 0)) AS sum_original,
            sum(ifNull(b.original_cbm, 0)) AS sum_original_cbm,
            sum(ifNull(b.original_kg, 0)) AS sum_original_kg,
            sum(ifNull(b.original_cse, 0)) AS sum_original_cse,
            sum(ifNull(b.original_pl, 0)) AS sum_original_pl,
            sum(ifNull(b.shipped, 0)) AS sum_shipped,
            sum(ifNull(b.shipped_cbm, 0)) AS sum_shipped_cbm,
            sum(ifNull(b.shipped_kg, 0)) AS sum_shipped_kg,
            sum(ifNull(b.shipped_cse, 0)) AS sum_shipped_cse,
            sum(ifNull(b.shipped_pl, 0)) AS sum_shipped_pl,
            sum(ifNull(b.san_luong_giao, 0)) AS sum_giao,
            sum(ifNull(b.san_luong_giao_cbm, 0)) AS sum_giao_cbm,
            sum(ifNull(b.san_luong_giao_kg, 0)) AS sum_giao_kg,
            sum(ifNull(b.san_luong_giao_cse, 0)) AS sum_giao_cse,
            sum(ifNull(b.san_luong_giao_pl, 0)) AS sum_giao_pl,
            coalesce(maxIf(b.ata_roi, b.ata_roi IS NOT NULL), NULL) AS max_ata_roi_trip,
            count() AS cnt_line_trip,
            countIf(b.ata_roi IS NOT NULL) AS cnt_line_co_ata_roi,
            countIf(b.ata_roi IS NULL) AS cnt_line_chua_ata_roi,
            countIf((b.ata_roi IS NOT NULL) AND (b.eta_giao_hang_cho_npp IS NOT NULL) AND (b.ata_roi > b.eta_giao_hang_cho_npp)) AS cnt_line_late_vs_eta,
            if(countIf((upperUTF8(trimBoth(ifNull(b.status, ''))) NOT IN ('SHIPPED', 'SHIPCOMPLETED'))) = 0, 1, 0) AS tat_ca_don_shipped_trip
        FROM analytics_workspace.mv_alert_late_do_base AS b
        GROUP BY b.so_chuyen
    )
SELECT
    s.so_chuyen,
    p.whseid,
    p.trang_thai_chuyen,
    p.group_of_cago,
    p.channel,
    p.customer_code,
    p.customer_name,
    p.khu_vuc_doi_xe,
    p.ten_ngan_nvt,
    p.ma_nha_xe,
    p.ma_doi_tac_nhan,
    p.ten_doi_tac_nhan,
    p.actual_ship_date,
    p.thoi_gian_gui_thau,
    p.ngay_tao_chuyen,
    p.etd_chuyen_gui_thau,
    p.gio_dang_tai,
    p.gio_goi_xe,
    p.gio_vao_cong,
    p.gio_vao_dock,
    p.tg_bat_buoc_roi_kho,
    p.gio_ra_dock,
    p.gio_ra_cong,
    p.eta_giao_hang_cho_npp,
    p.ata_den,
    p.ata_roi,
    p.so_xe,
    p.tai_xe,
    s.sum_original,
    s.sum_original_cbm,
    s.sum_original_kg,
    s.sum_original_cse,
    s.sum_original_pl,
    s.sum_shipped,
    s.sum_shipped_cbm,
    s.sum_shipped_kg,
    s.sum_shipped_cse,
    s.sum_shipped_pl,
    s.sum_giao,
    s.sum_giao_cbm,
    s.sum_giao_kg,
    s.sum_giao_cse,
    s.sum_giao_pl,
    s.max_ata_roi_trip,
    s.cnt_line_trip,
    s.cnt_line_co_ata_roi,
    s.cnt_line_chua_ata_roi,
    s.cnt_line_late_vs_eta,
    s.tat_ca_don_shipped_trip,
    p.etd_chuyen,
    p.eta_chuyen,
    p.ata_chuyen,
    p.atd_chuyen,
    p.request_date,
    p.approved_date
FROM
so_sum AS s
LEFT JOIN
so_pick AS p ON s.so_chuyen = p.so_chuyen


-- ════════════════════════════════════════════════════
-- Object: mv_alert_stm_data  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_alert_stm_data
REFRESH EVERY 5 MINUTE
(
    `id_ord_group_product` UInt64 COMMENT 'ID chi tiết đơn hàng (ORD_GroupProduct.ID)',
    `ma_don_hang` Nullable(String) COMMENT 'Mã đơn hàng (ORD_Order.Code)',
    `line_no` Nullable(String) COMMENT 'Số dòng đơn (CodeSync bỏ ký tự cuối)',
    `trang_thai_chuyen` Nullable(String) COMMENT 'Trạng thái chuyến (status_id dạng text từ SYS_Var)',
    `trang_thai_don` Nullable(String) COMMENT 'Trạng thái đơn hàng (StatusOfOrderID dạng text từ SYS_Var)',
    `quantity_bbgn` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng giao thực tế (QuantityBBGN)',
    `thoi_gian_gui_thau` Nullable(DateTime64(3, 'UTC')) COMMENT 'Thời gian gửi thầu (TenderedDate)',
    `eta_giao_hang_cho_npp` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETA giao hàng cho NPP',
    `ata_den` Nullable(DateTime64(3, 'UTC')) COMMENT 'ATA đến điểm giao (DateToCome)',
    `ata_roi` Nullable(DateTime64(3, 'UTC')) COMMENT 'ATA rời điểm giao (DateToLeave)',
    `ten_ngan_nvt` Nullable(String) COMMENT 'Tên ngắn nhà vận tải',
    `ma_nha_xe` Nullable(String) COMMENT 'Mã nhà xe (vendor code)',
    `ngay_tao_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày tạo chuyến (CreatedDate)',
    `etd_chuyen_gui_thau` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETD chuyến gửi thầu',
    `gio_dang_tai` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ đăng tài (RegisterDate)',
    `gio_goi_xe` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ gọi xe (CalledDate)',
    `gio_vao_cong` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ vào cổng (GateIn)',
    `gio_vao_dock` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ vào dock (LoadingStart)',
    `tg_bat_buoc_roi_kho` Nullable(DateTime64(3, 'UTC')) COMMENT 'TG bắt buộc rời kho (RequiredDepartureTime)',
    `gio_ra_dock` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ ra dock (LoadingEnd)',
    `gio_ra_cong` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ ra cổng (GateOut)',
    `so_chuyen` Nullable(String) COMMENT 'Mã chuyến vận hành (OPS_DITOMaster.Code)',
    `so_xe` Nullable(String) COMMENT 'Biển số xe (reg_no)',
    `tai_xe` Nullable(String) COMMENT 'Tên tài xế (DriverName1)',
    `etd_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETD chuyến',
    `eta_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETA chuyến',
    `ata_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'ATA chuyến',
    `atd_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'ATD chuyến',
    `request_date` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày yêu cầu đơn hàng',
    `approved_date` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày duyệt chuyến'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY id_ord_group_product
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS SELECT
    opg.id AS id_ord_group_product,
    ordm.code AS ma_don_hang,
    if(length(opg.code_sync) > 0, left(opg.code_sync, length(opg.code_sync) - 1), '') AS line_no,
    status_dito_var.value_of_var AS trang_thai_chuyen,
    status_order_var.value_of_var AS trang_thai_don,
    dtd.quantity_bbgn AS quantity_bbgn,
    if((dtd.tender_date IS NULL) OR (toDate(toDateTime64(dtd.tender_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.tender_date, 3, 'UTC')) AS thoi_gian_gui_thau,
    if((dtd.eta IS NULL) OR (toDate(toDateTime64(dtd.eta, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.eta, 3, 'UTC')) AS eta_giao_hang_cho_npp,
    if((dtd.date_to_come IS NULL) OR (toDate(toDateTime64(dtd.date_to_come, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.date_to_come, 3, 'UTC')) AS ata_den,
    if((dtd.date_to_leave IS NULL) OR (toDate(toDateTime64(dtd.date_to_leave, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.date_to_leave, 3, 'UTC')) AS ata_roi,
    vendor.short_name AS ten_ngan_nvt,
    vendor.code AS ma_nha_xe,
    if((trip.created_date IS NULL) OR (toDate(toDateTime64(trip.created_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(trip.created_date, 3, 'UTC')) AS ngay_tao_chuyen,
    if((tender.etd IS NULL) OR (toDate(toDateTime64(tender.etd, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(tender.etd, 3, 'UTC')) AS etd_chuyen_gui_thau,
    if((dock.register_date IS NULL) OR (toDate(toDateTime64(dock.register_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dock.register_date, 3, 'UTC')) AS gio_dang_tai,
    if((dock.called_date IS NULL) OR (toDate(toDateTime64(dock.called_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dock.called_date, 3, 'UTC')) AS gio_goi_xe,
    if((dock.gate_in IS NULL) OR (toDate(toDateTime64(dock.gate_in, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dock.gate_in, 3, 'UTC')) AS gio_vao_cong,
    if((dock.loading_start IS NULL) OR (toDate(toDateTime64(dock.loading_start, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dock.loading_start, 3, 'UTC')) AS gio_vao_dock,
    if((dtd.required_departure_time IS NULL) OR (toDate(toDateTime64(dtd.required_departure_time, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.required_departure_time, 3, 'UTC')) AS tg_bat_buoc_roi_kho,
    if((dock.loading_end IS NULL) OR (toDate(toDateTime64(dock.loading_end, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dock.loading_end, 3, 'UTC')) AS gio_ra_dock,
    if((dock.gate_out IS NULL) OR (toDate(toDateTime64(dock.gate_out, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dock.gate_out, 3, 'UTC')) AS gio_ra_cong,
    trip.code AS so_chuyen,
    vehicle.reg_no AS so_xe,
    trip.driver_name1 AS tai_xe,
    if((trip.etd IS NULL) OR (toDate(toDateTime64(trip.etd, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(trip.etd, 3, 'UTC')) AS etd_chuyen,
    if((trip.eta IS NULL) OR (toDate(toDateTime64(trip.eta, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(trip.eta, 3, 'UTC')) AS eta_chuyen,
    if((trip.ata IS NULL) OR (toDate(toDateTime64(trip.ata, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(trip.ata, 3, 'UTC')) AS ata_chuyen,
    if((trip.atd IS NULL) OR (toDate(toDateTime64(trip.atd, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(trip.atd, 3, 'UTC')) AS atd_chuyen,
    if((ordm.request_date IS NULL) OR (toDate(toDateTime64(ordm.request_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(ordm.request_date, 3, 'UTC')) AS request_date,
    if((trip.approved_date IS NULL) OR (toDate(toDateTime64(trip.approved_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(trip.approved_date, 3, 'UTC')) AS approved_date
FROM stm_dwh_mondelez.dim_ops_trip_detail AS dtd
LEFT JOIN stm_dwh_mondelez.dim_ord_product_group AS opg ON dtd.order_group_product_id = opg.id
LEFT JOIN stm_dwh_mondelez.dim_ord_order AS ordm ON opg.order_id = ordm.id
LEFT JOIN stm_dwh_mondelez.dim_ops_trip AS trip ON dtd.trip_header_id = trip.id
LEFT JOIN stm_dwh_mondelez.dim_ops_trip AS tender ON dtd.trip_tender_id = tender.id
LEFT JOIN stm_dwh_mondelez.subdim_cus_customer AS vendor ON trip.vendor_id = vendor.id
LEFT JOIN
(
    SELECT
        dito_master_id,
        argMax(register_date, sort_key) AS register_date,
        argMax(called_date, sort_key) AS called_date,
        argMax(gate_in, sort_key) AS gate_in,
        argMax(loading_start, sort_key) AS loading_start,
        argMax(loading_end, sort_key) AS loading_end,
        argMax(gate_out, sort_key) AS gate_out
    FROM
    (
        SELECT
            *,
            toInt64(register_date) AS sort_key
        FROM stm_dwh_mondelez.dim_ops_dock_register
    )
    GROUP BY dito_master_id
) AS dock ON trip.id = dock.dito_master_id
LEFT JOIN analytics_workspace.mv_masterdata_vehicle AS vehicle ON toUInt64(trip.vehicle_id) = toUInt64(vehicle.id_vehicle)
LEFT JOIN stm_dwh_mondelez.dim_sys_var AS status_dito_var ON status_dito_var.id = trip.status_id
LEFT JOIN stm_dwh_mondelez.dim_sys_var AS status_order_var ON status_order_var.id = ordm.status_of_order_id
WHERE (ordm.service_name = 'Xuất bán') AND (ordm.customer_id = '9') AND (trip.status_id IN (98, 99, 100, 101)) AND ((dtd.sort_order IN ('1', '-1')) OR ((dtd.sort_order = '2') AND (ordm.service_name = 'Xuất bán'))) AND (opg.order_id > 0) AND (opg.code_sync != '') AND (opg.code_sync IS NOT NULL) AND (dtd.is_deleted = 0) AND (ordm.is_deleted = 0) AND (trip.is_deleted = 0)


-- ════════════════════════════════════════════════════
-- Object: mv_alert_stm_swm_data  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_alert_stm_swm_data
REFRESH EVERY 5 MINUTE
(
    `whseid` Nullable(String) COMMENT 'Mã kho (SWM)',
    `whseid_stm` Nullable(String) COMMENT 'Mã kho STM (BKD1/2/3→BKD)',
    `so` Nullable(String) COMMENT 'Số đơn SO',
    `order_line_number` String COMMENT 'Số dòng đơn',
    `type` Nullable(String) COMMENT 'Loại đơn hàng',
    `type_description` Nullable(String) COMMENT 'Mô tả loại đơn',
    `item_code` Nullable(String) COMMENT 'Mã SKU',
    `status` Nullable(String) COMMENT 'Trạng thái WMS (ShipCompleted/Picked/...)',
    `uom` Nullable(String) COMMENT 'Đơn vị tính',
    `group_of_cago` Nullable(String) COMMENT 'Nhóm hàng',
    `channel` Nullable(String) COMMENT 'Kênh (Group)',
    `customer_code` Nullable(String) COMMENT 'Mã khách hàng',
    `customer_name` Nullable(String) COMMENT 'Tên khách hàng',
    `actual_ship_date` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày thực xuất kho',
    `delivery_date` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày giao hàng',
    `original` Nullable(Decimal(18, 4)) COMMENT 'SL đặt (masterunit)',
    `original_cbm` Nullable(Decimal(18, 4)) COMMENT 'SL đặt CBM',
    `original_kg` Nullable(Decimal(18, 4)) COMMENT 'SL đặt KG',
    `original_cse` Nullable(Decimal(18, 4)) COMMENT 'SL đặt CSE',
    `original_pl` Nullable(Decimal(18, 4)) COMMENT 'SL đặt PL',
    `shipped` Nullable(Decimal(18, 4)) COMMENT 'SL pick (masterunit)',
    `shipped_cbm` Nullable(Decimal(18, 4)) COMMENT 'SL pick CBM',
    `shipped_kg` Nullable(Decimal(18, 4)) COMMENT 'SL pick KG',
    `shipped_cse` Nullable(Decimal(18, 4)) COMMENT 'SL pick CSE',
    `shipped_pl` Nullable(Decimal(18, 4)) COMMENT 'SL pick PL',
    `so_chuyen` Nullable(String) COMMENT 'Mã chuyến vận hành (STM)',
    `trang_thai_chuyen` Nullable(String) COMMENT 'Trạng thái chuyến',
    `trang_thai_don` Nullable(String) COMMENT 'Trạng thái đơn hàng',
    `ten_ngan_nvt` Nullable(String) COMMENT 'Tên ngắn nhà vận tải',
    `ma_nha_xe` Nullable(String) COMMENT 'Mã nhà xe',
    `ngay_tao_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày tạo chuyến',
    `etd_chuyen_gui_thau` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETD chuyến gửi thầu',
    `thoi_gian_gui_thau` Nullable(DateTime64(3, 'UTC')) COMMENT 'Thời gian gửi thầu',
    `gio_dang_tai` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ đăng tài',
    `gio_goi_xe` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ gọi xe',
    `gio_vao_cong` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ vào cổng',
    `gio_vao_dock` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ vào dock',
    `tg_bat_buoc_roi_kho` Nullable(DateTime64(3, 'UTC')) COMMENT 'TG bắt buộc rời kho',
    `gio_ra_dock` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ ra dock',
    `gio_ra_cong` Nullable(DateTime64(3, 'UTC')) COMMENT 'Giờ ra cổng',
    `eta_giao_hang_cho_npp` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETA giao hàng cho NPP',
    `ata_den` Nullable(DateTime64(3, 'UTC')) COMMENT 'ATA đến điểm giao',
    `ata_roi` Nullable(DateTime64(3, 'UTC')) COMMENT 'ATA rời điểm giao',
    `so_xe` Nullable(String) COMMENT 'Biển số xe',
    `tai_xe` Nullable(String) COMMENT 'Tài xế',
    `ma_doi_tac_nhan` Nullable(String) COMMENT 'Mã đối tác nhận (từ whseid_stm)',
    `ten_doi_tac_nhan` Nullable(String) COMMENT 'Tên đối tác nhận',
    `khu_vuc_doi_xe` Nullable(String) COMMENT 'Khu vực đội xe (từ customer_code)',
    `san_luong_giao` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng giao BBGN (masterunit)',
    `san_luong_giao_cse` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng giao BBGN CSE',
    `san_luong_giao_cbm` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng giao BBGN CBM',
    `san_luong_giao_kg` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng giao BBGN KG',
    `san_luong_giao_pl` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng giao BBGN PL',
    `etd_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETD chuyến',
    `eta_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETA chuyến',
    `ata_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'ATA chuyến',
    `atd_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'ATD chuyến',
    `request_date` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày yêu cầu đơn hàng',
    `approved_date` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày duyệt chuyến'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (whseid, so)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH enriched AS
    (
        SELECT
            swm.whseid,
            swm.whseid_stm,
            swm.so,
            swm.order_line_number,
            swm.type,
            swm.type_description,
            swm.item_code,
            swm.status,
            swm.uom,
            swm.group_of_cago,
            swm.channel AS channel,
            swm.customer_code,
            swm.customer_name,
            swm.actual_ship_date,
            swm.delivery_date,
            swm.original,
            swm.original_cbm,
            swm.original_kg,
            swm.original_cse,
            swm.original_pl,
            swm.shipped,
            swm.shipped_cbm,
            swm.shipped_kg,
            swm.shipped_cse,
            swm.shipped_pl,
            stm.so_chuyen,
            stm.trang_thai_chuyen,
            stm.trang_thai_don,
            stm.ten_ngan_nvt,
            stm.ma_nha_xe,
            stm.ngay_tao_chuyen,
            stm.etd_chuyen_gui_thau,
            stm.thoi_gian_gui_thau,
            stm.gio_dang_tai,
            stm.gio_goi_xe,
            stm.gio_vao_cong,
            stm.gio_vao_dock,
            stm.tg_bat_buoc_roi_kho,
            stm.gio_ra_dock,
            stm.gio_ra_cong,
            stm.eta_giao_hang_cho_npp,
            stm.ata_den,
            stm.ata_roi,
            stm.so_xe,
            stm.tai_xe,
            stm.etd_chuyen,
            stm.eta_chuyen,
            stm.ata_chuyen,
            stm.atd_chuyen,
            stm.request_date,
            stm.approved_date,
            stm.quantity_bbgn,
            loc_from.cus_location_code AS ma_doi_tac_nhan,
            loc_from.cus_location_name AS ten_doi_tac_nhan,
            loc_to.group_area_name AS khu_vuc_doi_xe,
            multiIf(upperUTF8(trimBoth(swm.uom)) = 'CSE', stm.quantity_bbgn, NULL) AS sl_giao_cse1,
            multiIf((upperUTF8(trimBoth(swm.uom)) IN ('PCE', 'PC', 'EA')), stm.quantity_bbgn, NULL) AS sl_giao1,
            multiIf(upperUTF8(trimBoth(swm.uom)) = 'PALLET', stm.quantity_bbgn, NULL) AS sl_giao_pl1
        FROM analytics_workspace.mv_alert_swm_data AS swm
        LEFT JOIN analytics_workspace.mv_alert_stm_data AS stm ON (swm.so = stm.ma_don_hang) AND (swm.order_line_number = stm.line_no)
        LEFT JOIN analytics_workspace.mv_masterdata_location AS loc_from ON swm.whseid_stm = loc_from.code
        LEFT JOIN analytics_workspace.mv_masterdata_location AS loc_to ON swm.customer_code = loc_to.code
    )
SELECT
    e.whseid,
    e.whseid_stm,
    e.so,
    e.order_line_number,
    e.type,
    e.type_description,
    e.item_code,
    e.status,
    e.uom,
    e.group_of_cago,
    e.channel,
    e.customer_code,
    e.customer_name,
    e.actual_ship_date,
    e.delivery_date,
    e.original,
    e.original_cbm,
    e.original_kg,
    e.original_cse,
    e.original_pl,
    e.shipped,
    e.shipped_cbm,
    e.shipped_kg,
    e.shipped_cse,
    e.shipped_pl,
    e.so_chuyen,
    e.trang_thai_chuyen,
    e.trang_thai_don,
    e.ten_ngan_nvt,
    e.ma_nha_xe,
    e.ngay_tao_chuyen,
    e.etd_chuyen_gui_thau,
    e.thoi_gian_gui_thau,
    e.gio_dang_tai,
    e.gio_goi_xe,
    e.gio_vao_cong,
    e.gio_vao_dock,
    e.tg_bat_buoc_roi_kho,
    e.gio_ra_dock,
    e.gio_ra_cong,
    e.eta_giao_hang_cho_npp,
    e.ata_den,
    e.ata_roi,
    e.so_xe,
    e.tai_xe,
    e.etd_chuyen,
    e.eta_chuyen,
    e.ata_chuyen,
    e.atd_chuyen,
    e.request_date,
    e.approved_date,
    e.ma_doi_tac_nhan,
    e.ten_doi_tac_nhan,
    e.khu_vuc_doi_xe,
    multiIf(e.sl_giao_cse1 IS NOT NULL, e.sl_giao_cse1 * toDecimal64(assumeNotNull(ms.masterunit_per_cse), 4), e.sl_giao1 IS NOT NULL, e.sl_giao1, e.sl_giao_pl1 IS NOT NULL, e.sl_giao_pl1 * toDecimal64(assumeNotNull(ms.masterunit_per_pallet), 4), toNullable(toDecimal64(0, 4))) AS san_luong_giao,
    multiIf(e.sl_giao_cse1 IS NOT NULL, e.sl_giao_cse1, e.sl_giao1 IS NOT NULL, e.sl_giao1 / nullIf(toDecimal64(assumeNotNull(ms.masterunit_per_cse), 4), toDecimal64(0, 4)), e.sl_giao_pl1 IS NOT NULL, (e.sl_giao_pl1 * toDecimal64(assumeNotNull(ms.masterunit_per_pallet), 4)) / nullIf(toDecimal64(assumeNotNull(ms.masterunit_per_cse), 4), toDecimal64(0, 4)), toNullable(toDecimal64(0, 4))) AS san_luong_giao_cse,
    multiIf(e.sl_giao_cse1 IS NOT NULL, (e.sl_giao_cse1 * toDecimal64(assumeNotNull(ms.masterunit_per_cse), 4)) * toDecimal64(assumeNotNull(ms.cbm_per_masterunit), 4), e.sl_giao1 IS NOT NULL, e.sl_giao1 * toDecimal64(assumeNotNull(ms.cbm_per_masterunit), 4), e.sl_giao_pl1 IS NOT NULL, (e.sl_giao_pl1 * toDecimal64(assumeNotNull(ms.masterunit_per_pallet), 4)) * toDecimal64(assumeNotNull(ms.cbm_per_masterunit), 4), toNullable(toDecimal64(0, 4))) AS san_luong_giao_cbm,
    multiIf(e.sl_giao_cse1 IS NOT NULL, (e.sl_giao_cse1 * toDecimal64(assumeNotNull(ms.masterunit_per_cse), 4)) * toDecimal64(assumeNotNull(ms.kg_per_masterunit), 4), e.sl_giao1 IS NOT NULL, e.sl_giao1 * toDecimal64(assumeNotNull(ms.kg_per_masterunit), 4), e.sl_giao_pl1 IS NOT NULL, (e.sl_giao_pl1 * toDecimal64(assumeNotNull(ms.masterunit_per_pallet), 4)) * toDecimal64(assumeNotNull(ms.kg_per_masterunit), 4), toNullable(toDecimal64(0, 4))) AS san_luong_giao_kg,
    multiIf(e.sl_giao_cse1 IS NOT NULL, (e.sl_giao_cse1 * toDecimal64(assumeNotNull(ms.masterunit_per_cse), 4)) / nullIf(toDecimal64(assumeNotNull(ms.masterunit_per_pallet), 4), toDecimal64(0, 4)), e.sl_giao1 IS NOT NULL, e.sl_giao1 / nullIf(toDecimal64(assumeNotNull(ms.masterunit_per_pallet), 4), toDecimal64(0, 4)), e.sl_giao_pl1 IS NOT NULL, e.sl_giao_pl1, toNullable(toDecimal64(0, 4))) AS san_luong_giao_pl
FROM
enriched AS e
LEFT JOIN analytics_workspace.mv_masterdata_sku AS ms ON (e.item_code = assumeNotNull(ms.item_code)) AND (e.whseid = ms.whseid)


-- ════════════════════════════════════════════════════
-- Object: mv_alert_swm_data  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_alert_swm_data
REFRESH EVERY 5 MINUTE
(
    `whseid` String COMMENT 'Mã kho (WHSEID)',
    `whseid_stm` String COMMENT 'Mã kho quy về STM (BKD1/2/3 → BKD)',
    `so` Nullable(String) COMMENT 'Số đơn SO (EXTERNORDERKEY)',
    `order_line_number` String COMMENT 'Số dòng đơn (ORDERLINENUMBER)',
    `type` Nullable(String) COMMENT 'Loại đơn hàng (TYPE)',
    `type_description` Nullable(String) COMMENT 'Mô tả loại đơn',
    `item_code` Nullable(String) COMMENT 'Mã SKU',
    `status` Nullable(String) COMMENT 'Trạng thái đơn hàng (New/Allocated/Picked/ShipCompleted/...)',
    `uom` Nullable(String) COMMENT 'Đơn vị tính (UOM)',
    `group_of_cago` Nullable(String) COMMENT 'Nhóm hàng (FRESH,\r\n\r\n\r\n\r\n\r\n\r\n DRY,\r\n\r\n\r\n\r\n\r\n\r\n ...)',
    `channel` Nullable(String) COMMENT 'Kênh khách hàng (channel)',
    `customer_code` Nullable(String) COMMENT 'Mã khách hàng (CONSIGNEEKEY)',
    `customer_name` Nullable(String) COMMENT 'Tên khách hàng',
    `original` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng đặt (masterunit)',
    `original_cbm` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng đặt CBM',
    `original_kg` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng đặt KG',
    `original_cse` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng đặt CSE',
    `original_pl` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng đặt PL',
    `delivery_date` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày giao hàng (DELIVERYDATE)',
    `actual_ship_date` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày thực tế xuất kho (ACTUALSHIPDATE)',
    `shipped` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng đã pick (masterunit)',
    `shipped_cbm` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng đã pick CBM',
    `shipped_kg` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng đã pick KG',
    `shipped_cse` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng đã pick CSE',
    `shipped_pl` Nullable(Decimal(18, 4)) COMMENT 'Sản lượng đã pick PL'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (whseid, order_line_number)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH group_pickdetail AS
    (
        SELECT
            storer_key,
            whseid,
            order_key,
            toString(order_line_number) AS order_line_number,
            sum(qty) AS shipped_qty
        FROM swm_dwh_mondelez.dim_pickdetail
        WHERE is_deleted = 0
        GROUP BY
            storer_key,
            whseid,
            order_key,
            order_line_number
    )
SELECT
    od.whseid AS whseid,
    if((od.whseid IN ('BKD1', 'BKD2', 'BKD3')), 'BKD', od.whseid) AS whseid_stm,
    o.extern_order_key AS so,
    toString(od.order_line_number) AS order_line_number,
    o.type AS type,
    mot.description AS type_description,
    od.sku AS item_code,
    multiIf(o.status_code = '04', 'New', o.status_code = '14', 'PartAllocate', o.status_code = '17', 'Allocated', o.status_code = '52', 'PartPick', o.status_code = '55', 'Picked', o.status_code = '92', 'PartShipped', o.status_code = '95', 'ShipCompleted', o.status_code = '72', 'InSorting', o.status_code = '75', 'Sorted', o.status_code = '82', 'InPacking', o.status_code = '85', 'Packed', o.status_code = '1', 'Cancel', o.status_code = '31', 'PartPreAllocated', o.status_code = '32', 'PreAllocated', o.status_code = '2', 'Close', NULL) AS status,
    od.uom AS uom,
    ms.group_of_cargo AS group_of_cago,
    loc.channel AS channel,
    o.consignee_key AS customer_code,
    loc.cus_location_name AS customer_name,
    od.original_qty AS original,
    od.original_qty * ms.cbm_per_masterunit AS original_cbm,
    od.original_qty * ms.kg_per_masterunit AS original_kg,
    od.original_qty / nullIf(ms.masterunit_per_cse, 0) AS original_cse,
    od.original_qty / nullIf(ms.masterunit_per_pallet, 0) AS original_pl,
    if(toDate(toDateTime64(o.delivery_date, 3, 'UTC')) = toDate(toDateTime64('1970-01-01 00:00:00', 3, 'UTC')), NULL, toDateTime64(o.delivery_date, 3, 'UTC')) AS delivery_date,
    if(toDate(toDateTime64(o.actual_ship_date, 3, 'UTC')) = toDate(toDateTime64('1970-01-01 00:00:00', 3, 'UTC')), NULL, toDateTime64(o.actual_ship_date, 3, 'UTC')) AS actual_ship_date,
    gpd.shipped_qty AS shipped,
    gpd.shipped_qty * ms.cbm_per_masterunit AS shipped_cbm,
    gpd.shipped_qty * ms.kg_per_masterunit AS shipped_kg,
    gpd.shipped_qty / nullIf(ms.masterunit_per_cse, 0) AS shipped_cse,
    gpd.shipped_qty / nullIf(ms.masterunit_per_pallet, 0) AS shipped_pl
FROM swm_dwh_mondelez.dim_orderdetail AS od
LEFT JOIN analytics_workspace.mv_masterdata_sku AS ms ON (od.sku = ms.item_code) AND (od.whseid = ms.whseid)
LEFT JOIN swm_dwh_mondelez.dim_orders AS o ON (od.storer_key = o.storer_key) AND (od.whseid = o.whseid) AND (od.order_key = o.order_key)
LEFT JOIN analytics_workspace.mv_masterdata_location AS loc ON o.consignee_key = loc.cus_location_code
LEFT JOIN
group_pickdetail AS gpd ON (od.storer_key = gpd.storer_key) AND (od.whseid = gpd.whseid) AND (od.order_key = gpd.order_key) AND (toString(od.order_line_number) = gpd.order_line_number)
LEFT JOIN analytics_workspace.mv_masterdata_ordertype AS mot ON (o.whseid = mot.whseid) AND (o.type = mot.code)
WHERE (od.storer_key = 'MDLZ') AND (((od.whseid = 'NKD') AND (o.type IN ('01', '07', '08', '09', '240', 'XB2BMC', 'XTNPP'))) OR ((od.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (o.type IN ('01', '240'))) OR ((od.whseid IN ('VN821', 'VN831')) AND (o.type IN ('01', '240')))) AND (od.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (o.extern_order_key IS NOT NULL) AND (od.order_key IS NOT NULL) AND (o.sync_date IS NOT NULL) AND (od.is_deleted = 0) AND (o.is_deleted = 0)


-- ════════════════════════════════════════════════════
-- Object: mv_copack  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_copack
REFRESH EVERY 1 HOUR
(
    `whseid` Nullable(String) COMMENT 'Mã kho',
    `date_in_out` Date COMMENT 'Ngày nhập/xuất copack',
    `pallet_in` UInt64 COMMENT 'Số pallet nhập (receipt line count theo palletid)',
    `pallet_out` Float64 COMMENT 'Số pallet xuất (làm tròn lên theo masterunit_per_pallet)'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY whseid
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    in_copack AS
    (
        SELECT
            toDate(r.date_received) AS ngay,
            r.whseid AS kho,
            count(r.palletid) AS pallet_in
        FROM mondelez_swm_test.dim_receiptdetail AS r
        FINAL
        LEFT JOIN mondelez_swm_test.dim_receipt AS rh
        FINAL ON (rh.storer_key = r.storer_key) AND (rh.whseid = r.whseid) AND (rh.receipt_key = r.receipt_key) AND (rh.is_deleted = 0)
        WHERE (((r.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (((rh.type = 'FGTN') AND ((r.lottable06 IN ('0072', '')) OR (r.lottable06 IS NULL))) OR (rh.type = '05'))) OR ((r.whseid = 'NKD') AND (((rh.type = 'FGTN') AND (r.lottable06 IN ('0032', '0021'))) OR (rh.type = '05')))) AND (r.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (rh.status_code IN ('9', '5')) AND (r.storer_key = 'MDLZ') AND (r.is_deleted = 0)
        GROUP BY
            ngay,
            kho
    ),
    group_out_copack AS
    (
        SELECT
            o_h.extern_order_key AS so,
            o.order_key AS order_key,
            o.sku AS sku,
            toDate(r.lottable04) AS batch,
            toDate(o.actual_ship_date) AS ngay,
            o.whseid AS kho,
            ceil(sum(p.qty / nullIf(s.masterunit_per_pallet, 0))) AS pallet_out
        FROM mondelez_swm_test.dim_orderdetail AS o
        FINAL
        LEFT JOIN mondelez_swm_test.dim_orders AS o_h
        FINAL ON (o_h.storer_key = o.storer_key) AND (o_h.whseid = o.whseid) AND (o_h.order_key = o.order_key) AND (o_h.is_deleted = 0)
        LEFT JOIN mondelez_swm_test.dim_pickdetail AS p
        FINAL ON (o.storer_key = p.storer_key) AND (o.whseid = p.whseid) AND (o.order_key = p.order_key) AND (o.order_line_number = p.order_line_number) AND (p.is_deleted = 0)
        LEFT JOIN mondelez_swm_test.dim_receiptdetail AS r
        FINAL ON (r.storer_key = p.storer_key) AND (r.whseid = p.whseid) AND (r.lpnid = p.lpnid) AND (r.is_deleted = 0)
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS s ON (s.whseid = o.whseid) AND (s.item_code = o.sku)
        WHERE (o.storer_key = 'MDLZ') AND (o.status_code IN ('95', '92')) AND (o.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (((o.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (o_h.type IN ('05', 'CPK'))) OR ((o.whseid = 'NKD') AND (o_h.type IN ('04', '05', 'CPK')))) AND (o.is_deleted = 0)
        GROUP BY
            o_h.extern_order_key,
            o.order_key,
            o.sku,
            batch,
            ngay,
            kho
    ),
    out_copack AS
    (
        SELECT
            ngay,
            kho,
            sum(pallet_out) AS pallet_out
        FROM
        group_out_copack
        GROUP BY
            ngay,
            kho
    )
SELECT
    coalesce(i.kho, o.kho) AS whseid,
    coalesce(i.ngay, o.ngay) AS date_in_out,
    i.pallet_in AS pallet_in,
    o.pallet_out AS pallet_out
FROM
in_copack AS i
FULL OUTER JOIN
out_copack AS o ON (i.ngay = o.ngay) AND (i.kho = o.kho)


-- ════════════════════════════════════════════════════
-- Object: mv_dap_ung_gui_thau  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_dap_ung_gui_thau
REFRESH EVERY 1 HOUR
(
    `id_chuyen_gui_thau` Nullable(Int32),
    `id_chuyen_van_hanh` Nullable(Int32),
    `ma_chuyen_van_hanh` String,
    `trang_thai_chuyen` String,
    `ma_don_hang` String,
    `dich_vu_van_chuyen` String,
    `tender_date` Nullable(DateTime('UTC')),
    `etd_gt` Nullable(DateTime('UTC')),
    `eta_gt` Nullable(DateTime('UTC')),
    `etd_vh` Nullable(DateTime('UTC')),
    `atd_vh` Nullable(DateTime('UTC')),
    `eta_vh` Nullable(DateTime('UTC')),
    `ata_vh` Nullable(DateTime('UTC')),
    `so_xe` Nullable(String),
    `tai_xe` Nullable(String),
    `ma_nha_van_tai` Nullable(String),
    `nha_van_tai` Nullable(String),
    `nhom_hang_hoa` String,
    `ma_diem_nhan` Nullable(String),
    `diem_nhan` Nullable(String),
    `ma_diem_giao` Nullable(String),
    `diem_giao` Nullable(String),
    `ma_khu_vuc_doi_xe` Nullable(String),
    `khu_vuc_doi_xe` Nullable(String),
    `loai_boc_xep` Nullable(String),
    `loai_dia_diem` Nullable(String),
    `ma_loai_xe_gui_thau` String,
    `loai_xe_gui_thau` String,
    `ma_loai_xe_van_hanh` String,
    `loai_xe_van_hanh` String,
    `tan_ke_hoach` Nullable(Float64),
    `tan_nhan` Nullable(Float64),
    `tan_giao` Nullable(Float64),
    `cbm_ke_hoach` Nullable(Float64),
    `cbm_nhan` Nullable(Float64),
    `cbm_giao` Nullable(Float64),
    `cnt_id_chuyen_van_hanh` UInt64,
    `cnt_id_chuyen_gui_thau` UInt64,
    `dap_ung_gui_thau` Bool
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (ma_chuyen_van_hanh, id_chuyen_gui_thau)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH base_dt AS
    (
        SELECT
            trip_tender_id,
            trip_header_id,
            status_name,
            tender_date,
            order_group_product_id,
            location_from_id,
            location_to_id,
            ton,
            ton_tranfer,
            ton_bbgn,
            cbm,
            cbm_tranfer,
            cbm_bbgn
        FROM stm_dwh_mondelez.dim_ops_trip_detail
        WHERE (trip_header_id != -1) AND (trip_tender_id != -1)
    )
SELECT
    x.*,
    if((x.cnt_id_chuyen_van_hanh >= 2) OR (x.cnt_id_chuyen_gui_thau >= 2), false, true) AS dap_ung_gui_thau
FROM
(
    SELECT
        bd.*,
        count() OVER (PARTITION BY bd.id_chuyen_van_hanh) AS cnt_id_chuyen_van_hanh,
        count() OVER (PARTITION BY bd.id_chuyen_gui_thau) AS cnt_id_chuyen_gui_thau
    FROM
    (
        SELECT
            dt.trip_tender_id AS id_chuyen_gui_thau,
            dt.trip_header_id AS id_chuyen_van_hanh,
            arrayStringConcat(groupUniqArray(t.code), ', ') AS ma_chuyen_van_hanh,
            arrayStringConcat(groupUniqArray(dt.status_name), ', ') AS trang_thai_chuyen,
            arrayStringConcat(groupUniqArray(o.code), ', ') AS ma_don_hang,
            arrayStringConcat(groupUniqArray(o.service_name), ', ') AS dich_vu_van_chuyen,
            max(dt.tender_date) AS tender_date,
            max(tt.etd) AS etd_gt,
            max(tt.eta) AS eta_gt,
            max(t.etd) AS etd_vh,
            max(t.atd) AS atd_vh,
            max(t.eta) AS eta_vh,
            max(t.ata) AS ata_vh,
            argMax(t.reg_no, dt.order_group_product_id) AS so_xe,
            argMax(t.driver_name1, dt.order_group_product_id) AS tai_xe,
            argMax(nvt.code, dt.order_group_product_id) AS ma_nha_van_tai,
            argMax(nvt.short_name, dt.order_group_product_id) AS nha_van_tai,
            arrayStringConcat(groupUniqArray(gsku.group_name), ', ') AS nhom_hang_hoa,
            argMax(order_catfrom.code, dt.order_group_product_id) AS ma_diem_nhan,
            argMax(order_catfrom.location, dt.order_group_product_id) AS diem_nhan,
            argMax(order_catto.code, dt.order_group_product_id) AS ma_diem_giao,
            argMax(order_catto.location, dt.order_group_product_id) AS diem_giao,
            ifNull(nullIf(argMax(kv.code, dt.order_group_product_id), ''), 'UNKNOWN') AS ma_khu_vuc_doi_xe,
            ifNull(nullIf(argMax(kv.area_name, dt.order_group_product_id), ''), 'UNKNOWN') AS khu_vuc_doi_xe,
            multiIf(argMax(order_catto.unloading_type_id, dt.order_group_product_id) = -1, 'Loose', argMax(order_catto.unloading_type_id, dt.order_group_product_id) = 1, 'Full Pallet', toString(argMax(order_catto.unloading_type_id, dt.order_group_product_id))) AS loai_boc_xep,
            argMax(ldd.group_name, dt.order_group_product_id) AS loai_dia_diem,
            arrayStringConcat(groupUniqArray(lxgt.code), ', ') AS ma_loai_xe_gui_thau,
            arrayStringConcat(groupUniqArray(tt.tender_vehicle_group_name), ', ') AS loai_xe_gui_thau,
            arrayStringConcat(groupUniqArray(lxvh.code), ', ') AS ma_loai_xe_van_hanh,
            arrayStringConcat(groupUniqArray(t.header_vehicle_group_name), ', ') AS loai_xe_van_hanh,
            sumIf(dt.ton, ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) AS tan_ke_hoach,
            sumIf(dt.ton_tranfer, ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) AS tan_nhan,
            sumIf(dt.ton_bbgn, ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) AS tan_giao,
            sumIf(dt.cbm, ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) AS cbm_ke_hoach,
            sumIf(dt.cbm_tranfer, ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) AS cbm_nhan,
            sumIf(dt.cbm_bbgn, ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) AS cbm_giao
        FROM
        base_dt AS dt
        INNER JOIN stm_dwh_mondelez.dim_ops_trip AS t ON (dt.trip_header_id = t.key_sk) AND (t.header_group_vehicle_sk != -1)
        LEFT JOIN stm_dwh_mondelez.subdim_cus_customer AS nvt ON t.vendor_id = nvt.key_sk
        INNER JOIN stm_dwh_mondelez.dim_ops_trip AS tt ON (dt.trip_tender_id = tt.key_sk) AND (tt.tender_group_vehicle_sk != -1)
        INNER JOIN stm_dwh_mondelez.dim_ord_product_group AS dpg ON dt.order_group_product_id = dpg.key_sk
        INNER JOIN stm_dwh_mondelez.dim_ord_order AS o ON (dpg.order_id = o.key_sk) AND (o.service_code = 'XB')
        LEFT JOIN stm_dwh_mondelez.dim_ord_product AS sku ON dpg.id = sku.key_sk
        LEFT JOIN stm_dwh_mondelez.subdim_cus_group_of_product AS gsku ON sku.subcus_group_of_product_sk = gsku.key_sk
        INNER JOIN stm_dwh_mondelez.dim_cus_location AS order_cusfrom ON dpg.location_from_id = order_cusfrom.key_sk
        INNER JOIN stm_dwh_mondelez.subdim_cat_location AS order_catfrom ON order_cusfrom.subcat_location_sk = order_catfrom.key_sk
        INNER JOIN stm_dwh_mondelez.dim_cus_location AS order_custo ON dpg.location_to_id = order_custo.key_sk
        INNER JOIN stm_dwh_mondelez.subdim_cat_location AS order_catto ON order_custo.subcat_location_sk = order_catto.key_sk
        LEFT JOIN stm_dwh_mondelez.subdim_cat_group_of_location AS ldd ON order_catto.group_of_location_id = ldd.key_sk
        LEFT JOIN stm_dwh_mondelez.subdim_cat_area AS kv ON order_catto.area_id = kv.key_sk
        LEFT JOIN stm_dwh_mondelez.subdim_cat_group_of_vehicle AS lxvh ON t.header_group_vehicle_sk = lxvh.key_sk
        LEFT JOIN stm_dwh_mondelez.subdim_cat_group_of_vehicle AS lxgt ON tt.tender_group_vehicle_sk = lxgt.key_sk
        WHERE t.status_id > 98
        GROUP BY
            dt.trip_header_id,
            dt.trip_tender_id
    ) AS bd
) AS x


-- ════════════════════════════════════════════════════
-- Object: mv_dap_ung_van_hanh  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_dap_ung_van_hanh
REFRESH EVERY 1 HOUR
(
    `ma_chuyen_van_hanh` String,
    `ma_nha_van_tai` Nullable(String),
    `nha_van_tai` Nullable(String),
    `tai_xe` Nullable(String),
    `ma_don_hang` String,
    `etd_chuyen` Nullable(DateTime('UTC')),
    `atd_chuyen` Nullable(DateTime('UTC')),
    `eta_chuyen` Nullable(DateTime('UTC')),
    `ata_chuyen` Nullable(DateTime('UTC')),
    `ma_diem` Nullable(String),
    `ten_diem` Nullable(String),
    `loai_diem` Nullable(String),
    `thoi_gian_vao_diem` Nullable(DateTime('UTC')),
    `user_thao_tac_vao_diem` Nullable(String),
    `phuong_thuc_vao_diem` Nullable(String),
    `thoi_gian_ra_diem` Nullable(DateTime('UTC')),
    `user_thao_tac_ra_diem` Nullable(String),
    `phuong_thuc_ra_diem` Nullable(String),
    `so_luong_giao` Nullable(Float64),
    `thoi_gian_load_hang_quy_dinh_gio` Nullable(Float64),
    `thoi_gian_load_hang_thuc_te_gio` Nullable(Float64),
    `thao_tac_ra_vao_diem` Nullable(String),
    `thoi_gian_load_hang` Nullable(String),
    `tuan_thu_van_hanh` Nullable(String)
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY ma_chuyen_van_hanh
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS SELECT
    final.*,
    multiIf((final.thao_tac_ra_vao_diem = 'Hợp lệ') AND (final.thoi_gian_load_hang = 'Đạt'), 'Tuân thủ', 'Vi phạm') AS tuan_thu_van_hanh
FROM
(
    SELECT
        f.*,
        multiIf((f.thoi_gian_load_hang_quy_dinh_gio <= f.thoi_gian_load_hang_thuc_te_gio) AND (f.thoi_gian_load_hang_thuc_te_gio < 8), 'Đạt', 'Không đạt') AS thoi_gian_load_hang
    FROM
    (
        WITH
            30 AS config_seconds_per_unit,
            sum(if((cat.key_sk = cat_from.key_sk) OR (cat.key_sk = cat_to.key_sk), tripd.quantity_bbgn, 0)) AS total_qty
        SELECT
            trip.code AS ma_chuyen_van_hanh,
            vendor.code AS ma_nha_van_tai,
            vendor.short_name AS nha_van_tai,
            trip.driver_name1 AS tai_xe,
            trip.etd AS etd_chuyen,
            trip.atd AS atd_chuyen,
            trip.eta AS eta_chuyen,
            trip.ata AS ata_chuyen,
            arrayStringConcat(arrayFilter(x -> (isNotNull(x) AND (x != '')), groupUniqArray(if((cat.key_sk = cat_from.key_sk) OR (cat.key_sk = cat_to.key_sk), ordm.code, NULL))), ', ') AS ma_don_hang,
            cat.code AS ma_diem,
            cat.location AS ten_diem,
            typecat.value_of_var AS loai_diem,
            main.date_come AS thoi_gian_vao_diem,
            main.action_come_by AS user_thao_tac_vao_diem,
            caseWithExpression(main.action_come_by_id, -1, '', 0, 'Mobile app tài xế', 1, 'Giám sát (Web/Mobile)', 2, 'Geofencing', 3, 'SpecialConfig', 4, 'AutoWithSignPOD', 5, 'ExpressShipment', CAST(main.action_come_by_id, 'VARCHAR(50)')) AS phuong_thuc_vao_diem,
            main.date_leave AS thoi_gian_ra_diem,
            main.action_leave_by AS user_thao_tac_ra_diem,
            caseWithExpression(main.action_leave_by_id, -1, '', 0, 'Mobile app tài xế', 1, 'Giám sát (Web/Mobile)', 2, 'Geofencing', 3, 'SpecialConfig', 4, 'AutoWithSignPOD', 5, 'ExpressShipment', CAST(main.action_leave_by_id, 'VARCHAR(50)')) AS phuong_thuc_ra_diem,
            total_qty AS so_luong_giao,
            round((total_qty * config_seconds_per_unit) / 3600, 2) AS thoi_gian_load_hang_quy_dinh_gio,
            round(dateDiff('second', main.date_come, main.date_leave) / 3600, 2) AS thoi_gian_load_hang_thuc_te_gio,
            multiIf((main.action_come_by_id = 0) AND (main.action_leave_by_id = 0), 'Hợp lệ', 'Không hợp lệ') AS thao_tac_ra_vao_diem
        FROM stm_dwh_mondelez.dim_ops_ditolocation AS main
        LEFT JOIN stm_dwh_mondelez.dim_ops_trip AS trip ON main.dito_master_id = trip.key_sk
        LEFT JOIN stm_dwh_mondelez.subdim_cus_customer AS vendor ON trip.vendor_id = vendor.key_sk
        LEFT JOIN stm_dwh_mondelez.subdim_cat_location AS cat ON main.location_id = cat.key_sk
        LEFT JOIN stm_dwh_mondelez.dim_sys_var AS typecat ON main.type_of_to_location_id = typecat.key_sk
        LEFT JOIN stm_dwh_mondelez.dim_ops_trip_detail AS tripd ON tripd.trip_header_id = trip.key_sk
        LEFT JOIN stm_dwh_mondelez.dim_ord_product_group AS ordd ON tripd.order_group_product_id = ordd.key_sk
        LEFT JOIN stm_dwh_mondelez.dim_ord_order AS ordm ON ordd.order_id = ordm.key_sk
        LEFT JOIN stm_dwh_mondelez.subdim_cat_location AS cat_from ON tripd.location_from_id = cat_from.key_sk
        LEFT JOIN stm_dwh_mondelez.subdim_cat_location AS cat_to ON tripd.location_to_id = cat_to.key_sk
        WHERE (ordm.service_code = 'XB') AND (trip.status_id > 98)
        GROUP BY
            ma_chuyen_van_hanh,
            ma_nha_van_tai,
            nha_van_tai,
            tai_xe,
            etd_chuyen,
            atd_chuyen,
            eta_chuyen,
            ata_chuyen,
            ma_diem,
            ten_diem,
            loai_diem,
            thoi_gian_vao_diem,
            user_thao_tac_vao_diem,
            phuong_thuc_vao_diem,
            thoi_gian_ra_diem,
            user_thao_tac_ra_diem,
            phuong_thuc_ra_diem,
            thao_tac_ra_vao_diem
    ) AS f
) AS final
WHERE notEmpty(ma_don_hang)


-- ════════════════════════════════════════════════════
-- Object: mv_dropped_report  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_dropped_report
REFRESH EVERY 15 MINUTE
(
    `biz_key` String,
    `whseid` String,
    `whseid_stm` String,
    `so` String,
    `orderlinenumber` String,
    `type` Nullable(String),
    `type_description` Nullable(String),
    `status` Nullable(String),
    `item_code` Nullable(String),
    `ten_hang` Nullable(String),
    `uom` Nullable(String),
    `group_of_cago` Nullable(String),
    `brand` Nullable(String),
    `group_name` Nullable(String),
    `customer_code` Nullable(String),
    `customer_name` Nullable(String),
    `original_qty` Nullable(Decimal(38, 8)),
    `original_cbm` Nullable(Decimal(38, 8)),
    `original_kg` Nullable(Decimal(38, 8)),
    `original_cse` Nullable(Decimal(38, 8)),
    `original_pl` Nullable(Decimal(38, 8)),
    `shipped_qty` Nullable(Decimal(38, 8)),
    `shipped_cbm` Nullable(Decimal(38, 8)),
    `shipped_kg` Nullable(Decimal(38, 8)),
    `shipped_cse` Nullable(Decimal(38, 8)),
    `shipped_pl` Nullable(Decimal(38, 8)),
    `delivery_date_1` Nullable(DateTime64(3, 'UTC')),
    `actual_ship_date` Nullable(DateTime64(3, 'UTC')),
    `remark_2` Nullable(String),
    `id_ord_groupproduct` Nullable(UInt64),
    `ma_don_hang` Nullable(String),
    `trang_thai_don_hang` Nullable(String),
    `line_no` Nullable(String),
    `quantity_bbgn` Nullable(Decimal(38, 8)),
    `thoi_gian_gui_thau` Nullable(DateTime64(3, 'UTC')),
    `eta_giao_hang_cho_npp` Nullable(DateTime64(3, 'UTC')),
    `ata_den` Nullable(DateTime64(3, 'UTC')),
    `ata_roi` Nullable(DateTime64(3, 'UTC')),
    `id_chuyen_gui_thau` Nullable(UInt64),
    `ten_ngan_nha_van_tai` Nullable(String),
    `ma_nha_xe` Nullable(String),
    `loai_xe_van_hanh` Nullable(String),
    `ngay_tao_chuyen` Nullable(DateTime64(3, 'UTC')),
    `etd_chuyen_gui_thau` Nullable(DateTime64(3, 'UTC')),
    `atd_den` Nullable(DateTime64(3, 'UTC')),
    `gio_ra_dock` Nullable(DateTime64(3, 'UTC')),
    `tg_bat_buoc_roi_kho` Nullable(DateTime64(3, 'UTC')),
    `thoi_gian_di` Nullable(DateTime64(3, 'UTC')),
    `so_chuyen` Nullable(String),
    `so_xe` Nullable(String),
    `tai_xe` Nullable(String),
    `ma_doi_tac_nhan` Nullable(String),
    `ten_doi_tac_nhan` Nullable(String),
    `khu_vuc_doi_xe` Nullable(String),
    `san_luong_giao_cse1` Nullable(Decimal(38, 8)),
    `san_luong_giao1` Nullable(Decimal(38, 8)),
    `san_luong_giao_pl1` Nullable(Decimal(38, 8)),
    `san_luong_giao` Nullable(Decimal(38, 8)),
    `san_luong_giao_cse` Nullable(Decimal(38, 8)),
    `san_luong_giao_cbm` Nullable(Decimal(38, 8)),
    `san_luong_giao_kg` Nullable(Decimal(38, 8)),
    `san_luong_giao_pl` Nullable(Decimal(38, 8)),
    `trang_thai_don_do` Nullable(String)
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (so, orderlinenumber)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    swm_stm_data AS
    (
        SELECT
            swm.*,
            stm.id_ord_groupproduct AS stm_id_ord_groupproduct,
            stm.ma_don_hang AS stm_ma_don_hang,
            stm.trang_thai_don_hang AS stm_trang_thai_don_hang,
            stm.line_no AS stm_line_no,
            stm.quantity_bbgn AS stm_quantity_bbgn,
            stm.thoi_gian_gui_thau AS stm_thoi_gian_gui_thau,
            stm.eta_giao_hang_cho_npp AS stm_eta_giao_hang_cho_npp,
            stm.ata_den AS stm_ata_den,
            stm.ata_roi AS stm_ata_roi,
            stm.id_chuyen_gui_thau AS stm_id_chuyen_gui_thau,
            stm.ten_ngan_nha_van_tai AS stm_ten_ngan_nha_van_tai,
            stm.ma_nha_xe AS stm_ma_nha_xe,
            stm.loai_xe_van_hanh AS stm_loai_xe_van_hanh,
            stm.ngay_tao_chuyen AS stm_ngay_tao_chuyen,
            stm.etd_chuyen_gui_thau AS stm_etd_chuyen_gui_thau,
            stm.atd_den AS stm_atd_den,
            stm.gio_ra_dock AS stm_gio_ra_dock,
            stm.tg_bat_buoc_roi_kho AS stm_tg_bat_buoc_roi_kho,
            stm.thoi_gian_di AS stm_thoi_gian_di,
            stm.so_chuyen AS stm_so_chuyen,
            stm.so_xe AS stm_so_xe,
            stm.tai_xe AS stm_tai_xe,
            mlf.cus_location_code AS ma_doi_tac_nhan,
            mlf.cus_location_name AS ten_doi_tac_nhan,
            mlt.group_area_name AS khu_vuc_doi_xe,
            multiIf(upperUTF8(trimBoth(ifNull(swm.uom, ''))) = 'CSE', stm.quantity_bbgn, NULL) AS san_luong_giao_cse1,
            multiIf((upperUTF8(trimBoth(ifNull(swm.uom, ''))) IN ('PCE', 'PC', 'EA')), stm.quantity_bbgn, NULL) AS san_luong_giao1,
            multiIf(upperUTF8(trimBoth(ifNull(swm.uom, ''))) = 'PALLET', stm.quantity_bbgn, NULL) AS san_luong_giao_pl1
        FROM analytics_workspace.mv_dropped_swm AS swm
        ANY LEFT JOIN analytics_workspace.mv_dropped_stm AS stm ON (swm.so = stm.ma_don_hang) AND (swm.orderlinenumber = stm.line_no)
        LEFT JOIN analytics_workspace.mv_masterdata_location AS mlf ON swm.whseid_stm = mlf.code
        LEFT JOIN analytics_workspace.mv_masterdata_location AS mlt ON swm.customer_code = mlt.code
    ),
    enriched AS
    (
        SELECT
            s.*,
            multiIf(s.san_luong_giao_cse1 IS NOT NULL, s.san_luong_giao_cse1 * toDecimal64(assumeNotNull(sku.masterunit_per_cse), 4), s.san_luong_giao1 IS NOT NULL, s.san_luong_giao1, s.san_luong_giao_pl1 IS NOT NULL, s.san_luong_giao_pl1 * toDecimal64(assumeNotNull(sku.masterunit_per_pallet), 4), toNullable(toDecimal64(0, 4))) AS san_luong_giao,
            multiIf(s.san_luong_giao_cse1 IS NOT NULL, s.san_luong_giao_cse1, s.san_luong_giao1 IS NOT NULL, s.san_luong_giao1 / nullIf(toDecimal64(assumeNotNull(sku.masterunit_per_cse), 4), toDecimal64(0, 4)), s.san_luong_giao_pl1 IS NOT NULL, (s.san_luong_giao_pl1 * toDecimal64(assumeNotNull(sku.masterunit_per_pallet), 4)) / nullIf(toDecimal64(assumeNotNull(sku.masterunit_per_cse), 4), toDecimal64(0, 4)), toNullable(toDecimal64(0, 4))) AS san_luong_giao_cse,
            multiIf(s.san_luong_giao_cse1 IS NOT NULL, (s.san_luong_giao_cse1 * toDecimal64(assumeNotNull(sku.masterunit_per_cse), 4)) * toDecimal64(assumeNotNull(sku.cbm_per_masterunit), 4), s.san_luong_giao1 IS NOT NULL, s.san_luong_giao1 * toDecimal64(assumeNotNull(sku.cbm_per_masterunit), 4), s.san_luong_giao_pl1 IS NOT NULL, (s.san_luong_giao_pl1 * toDecimal64(assumeNotNull(sku.masterunit_per_pallet), 4)) * toDecimal64(assumeNotNull(sku.cbm_per_masterunit), 4), toNullable(toDecimal64(0, 4))) AS san_luong_giao_cbm,
            multiIf(s.san_luong_giao_cse1 IS NOT NULL, (s.san_luong_giao_cse1 * toDecimal64(assumeNotNull(sku.masterunit_per_cse), 4)) * toDecimal64(assumeNotNull(sku.kg_per_masterunit), 4), s.san_luong_giao1 IS NOT NULL, s.san_luong_giao1 * toDecimal64(assumeNotNull(sku.kg_per_masterunit), 4), s.san_luong_giao_pl1 IS NOT NULL, (s.san_luong_giao_pl1 * toDecimal64(assumeNotNull(sku.masterunit_per_pallet), 4)) * toDecimal64(assumeNotNull(sku.kg_per_masterunit), 4), toNullable(toDecimal64(0, 4))) AS san_luong_giao_kg,
            multiIf(s.san_luong_giao_cse1 IS NOT NULL, (s.san_luong_giao_cse1 * toDecimal64(assumeNotNull(sku.masterunit_per_cse), 4)) / nullIf(toDecimal64(assumeNotNull(sku.masterunit_per_pallet), 4), toDecimal64(0, 4)), s.san_luong_giao1 IS NOT NULL, s.san_luong_giao1 / nullIf(toDecimal64(assumeNotNull(sku.masterunit_per_pallet), 4), toDecimal64(0, 4)), s.san_luong_giao_pl1 IS NOT NULL, s.san_luong_giao_pl1, toNullable(toDecimal64(0, 4))) AS san_luong_giao_pl
        FROM
        swm_stm_data AS s
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (assumeNotNull(s.item_code) = sku.item_code) AND (assumeNotNull(s.whseid) = sku.whseid)
    )
SELECT
    e.biz_key,
    e.whseid,
    e.whseid_stm,
    e.so,
    e.orderlinenumber,
    e.type,
    e.type_description,
    e.status,
    e.item_code,
    e.ten_hang,
    e.uom,
    e.group_of_cago,
    e.brand,
    e.group_name,
    e.customer_code,
    e.customer_name,
    e.original_qty,
    e.original_cbm,
    e.original_kg,
    e.original_cse,
    e.original_pl,
    e.shipped_qty,
    e.shipped_cbm,
    e.shipped_kg,
    e.shipped_cse,
    e.shipped_pl,
    e.delivery_date_1,
    e.actual_ship_date,
    e.remark_2,
    e.stm_id_ord_groupproduct AS id_ord_groupproduct,
    e.stm_ma_don_hang AS ma_don_hang,
    e.stm_trang_thai_don_hang AS trang_thai_don_hang,
    e.stm_line_no AS line_no,
    e.stm_quantity_bbgn AS quantity_bbgn,
    e.stm_thoi_gian_gui_thau AS thoi_gian_gui_thau,
    e.stm_eta_giao_hang_cho_npp AS eta_giao_hang_cho_npp,
    e.stm_ata_den AS ata_den,
    e.stm_ata_roi AS ata_roi,
    e.stm_id_chuyen_gui_thau AS id_chuyen_gui_thau,
    e.stm_ten_ngan_nha_van_tai AS ten_ngan_nha_van_tai,
    e.stm_ma_nha_xe AS ma_nha_xe,
    e.stm_loai_xe_van_hanh AS loai_xe_van_hanh,
    e.stm_ngay_tao_chuyen AS ngay_tao_chuyen,
    e.stm_etd_chuyen_gui_thau AS etd_chuyen_gui_thau,
    e.stm_atd_den AS atd_den,
    e.stm_gio_ra_dock AS gio_ra_dock,
    e.stm_tg_bat_buoc_roi_kho AS tg_bat_buoc_roi_kho,
    e.stm_thoi_gian_di AS thoi_gian_di,
    e.stm_so_chuyen AS so_chuyen,
    e.stm_so_xe AS so_xe,
    e.stm_tai_xe AS tai_xe,
    e.ma_doi_tac_nhan,
    e.ten_doi_tac_nhan,
    e.khu_vuc_doi_xe,
    e.san_luong_giao_cse1,
    e.san_luong_giao1,
    e.san_luong_giao_pl1,
    e.san_luong_giao,
    e.san_luong_giao_cse,
    e.san_luong_giao_cbm,
    e.san_luong_giao_kg,
    e.san_luong_giao_pl,
    multiIf(((e.status = 'ShipCompleted') AND (e.stm_trang_thai_don_hang IN ('Da giao hang', 'Nhan 1 phan chung tu', 'Da nhan chung tu'))) OR (e.stm_ata_den IS NOT NULL), 'Da van chuyen', e.status = 'New', 'Chua xuat kho', (e.status IN ('PartAllocate', 'Allocated', 'PartPick', 'Picked', 'PartShipped')), 'Dang xuat kho', (e.status = 'ShipCompleted') AND (e.stm_thoi_gian_di IS NOT NULL), 'Dang van chuyen', e.status = 'ShipCompleted', 'Da xuat kho', NULL) AS trang_thai_don_do
FROM
enriched AS e


-- ════════════════════════════════════════════════════
-- Object: mv_dropped_stm  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_dropped_stm
REFRESH EVERY 1 HOUR
(
    `id_ord_groupproduct` UInt64 COMMENT 'ID dim_ord_product_group',
    `ma_don_hang` String COMMENT 'Mã đơn STM (dim_ord_order.code)',
    `trang_thai_don_hang` Nullable(String) COMMENT 'Tên trạng thái đơn (dim_ord_order.status_name)',
    `line_no` String COMMENT 'LineNo từ code_sync (bỏ 1 ký tự cuối)',
    `quantity_bbgn` Nullable(Decimal(38, 8)) COMMENT 'Số lượng giao BBGN',
    `thoi_gian_gui_thau` Nullable(DateTime64(3, 'UTC')) COMMENT 'Tender date',
    `eta_giao_hang_cho_npp` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETA chi tiết chuyến',
    `ata_den` Nullable(DateTime64(3, 'UTC')) COMMENT 'date_to_come',
    `ata_roi` Nullable(DateTime64(3, 'UTC')) COMMENT 'date_to_leave',
    `id_chuyen_gui_thau` Nullable(UInt64) COMMENT 'trip_tender_id',
    `ten_ngan_nha_van_tai` Nullable(String) COMMENT 'Nhà vận tải (mv_masterdata_vendor)',
    `ma_nha_xe` Nullable(String) COMMENT 'Mã nhà xe',
    `loai_xe_van_hanh` Nullable(String) COMMENT 'Nhóm xe vận hành',
    `ngay_tao_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'dim_ops_trip.created_date',
    `etd_chuyen_gui_thau` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETD chuyến gửi thầu',
    `atd_den` Nullable(DateTime64(3, 'UTC')) COMMENT 'date_from_come',
    `gio_ra_dock` Nullable(DateTime64(3, 'UTC')) COMMENT 'loading_end (dock,\r\n\r\n argMax theo chuyến)',
    `tg_bat_buoc_roi_kho` Nullable(DateTime64(3, 'UTC')) COMMENT 'required_departure_time',
    `thoi_gian_di` Nullable(DateTime64(3, 'UTC')) COMMENT 'date_from_leave',
    `so_chuyen` Nullable(String) COMMENT 'Mã chuyến vận hành',
    `so_xe` Nullable(String) COMMENT 'Biển số',
    `tai_xe` Nullable(String) COMMENT 'Tài xế'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (ma_don_hang, line_no)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH dock_end AS
    (
        SELECT
            dito_master_id,
            argMax(loading_end, last_modified_date) AS loading_end
        FROM stm_dwh_mondelez.dim_ops_dock_register
        WHERE is_deleted = 0
        GROUP BY dito_master_id
    )
SELECT
    opg.id AS id_ord_groupproduct,
    ord.code AS ma_don_hang,
    ord.status_name AS trang_thai_don_hang,
    left(opg.code_sync, greatest(lengthUTF8(trimBoth(opg.code_sync)) - 1, 0)) AS line_no,
    ifNull(dtd.quantity_bbgn, toDecimal64(0, 8)) AS quantity_bbgn,
    if((dtd.tender_date IS NULL) OR (toDate(toDateTime64(dtd.tender_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.tender_date, 3, 'UTC')) AS thoi_gian_gui_thau,
    if((dtd.eta IS NULL) OR (toDate(toDateTime64(dtd.eta, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.eta, 3, 'UTC')) AS eta_giao_hang_cho_npp,
    if((dtd.date_to_come IS NULL) OR (toDate(toDateTime64(dtd.date_to_come, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.date_to_come, 3, 'UTC')) AS ata_den,
    if((dtd.date_to_leave IS NULL) OR (toDate(toDateTime64(dtd.date_to_leave, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.date_to_leave, 3, 'UTC')) AS ata_roi,
    dtd.trip_tender_id AS id_chuyen_gui_thau,
    if((trip.created_date IS NULL) OR (toDate(toDateTime64(trip.created_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(trip.created_date, 3, 'UTC')) AS ngay_tao_chuyen,
    if((tender.etd IS NULL) OR (toDate(toDateTime64(tender.etd, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(tender.etd, 3, 'UTC')) AS etd_chuyen_gui_thau,
    if((dtd.date_from_come IS NULL) OR (toDate(toDateTime64(dtd.date_from_come, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.date_from_come, 3, 'UTC')) AS atd_den,
    if((dr.loading_end IS NULL) OR (toDate(toDateTime64(dr.loading_end, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dr.loading_end, 3, 'UTC')) AS gio_ra_dock,
    if((dtd.required_departure_time IS NULL) OR (toDate(toDateTime64(dtd.required_departure_time, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.required_departure_time, 3, 'UTC')) AS tg_bat_buoc_roi_kho,
    if((dtd.date_from_leave IS NULL) OR (toDate(toDateTime64(dtd.date_from_leave, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.date_from_leave, 3, 'UTC')) AS thoi_gian_di,
    trip.code AS so_chuyen,
    trip.driver_name1 AS tai_xe
FROM stm_dwh_mondelez.dim_ord_order AS ord
LEFT JOIN stm_dwh_mondelez.dim_ord_product_group AS opg ON (opg.order_id = ord.id) AND (opg.is_deleted = 0)
ANY LEFT JOIN analytics_workspace.mv_masterdata_location AS mloc_stm ON opg.location_from_id = toInt64(mloc_stm.id_cus)
LEFT JOIN stm_dwh_mondelez.dim_ops_trip_detail AS dtd ON (dtd.order_group_product_id = opg.id) AND (dtd.is_deleted = 0)
LEFT JOIN stm_dwh_mondelez.dim_ops_trip AS trip ON (dtd.trip_header_id = trip.id) AND (trip.is_deleted = 0) AND (trip.status_id != 13)
LEFT JOIN stm_dwh_mondelez.dim_ops_trip AS tender ON (dtd.trip_tender_id = tender.id) AND (tender.is_deleted = 0) AND (tender.status_id = 13)
LEFT JOIN
dock_end AS dr ON dr.dito_master_id = trip.id
LEFT JOIN analytics_workspace.mv_masterdata_vendor AS mv ON trip.vendor_id = toInt64(mv.id)
LEFT JOIN analytics_workspace.mv_masterdata_vehicle AS mveh ON trip.vehicle_id = toInt64(mveh.id_vehicle)
WHERE (ord.is_deleted = 0) AND (ord.service_name = 'Xuất bán') AND (ord.customer_id = '9') AND (opg.order_id IS NOT NULL) AND (opg.code_sync IS NOT NULL) AND (trimBoth(opg.code_sync) != '') AND ((dtd.sort_order = 1) OR (dtd.sort_order IS NULL))


-- ════════════════════════════════════════════════════
-- Object: mv_dropped_swm  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_dropped_swm
REFRESH EVERY 1 HOUR
(
    `biz_key` String,
    `whseid` String,
    `whseid_stm` String,
    `so` String,
    `orderlinenumber` String,
    `type` Nullable(String),
    `type_description` Nullable(String),
    `status` Nullable(String),
    `item_code` Nullable(String),
    `ten_hang` Nullable(String),
    `uom` Nullable(String),
    `group_of_cago` Nullable(String),
    `brand` Nullable(String),
    `group_name` Nullable(String),
    `customer_code` Nullable(String),
    `customer_name` Nullable(String),
    `remark_2` Nullable(String),
    `original_qty` Nullable(Decimal(38, 8)),
    `original_cbm` Nullable(Decimal(38, 8)),
    `original_kg` Nullable(Decimal(38, 8)),
    `original_cse` Nullable(Decimal(38, 8)),
    `original_pl` Nullable(Decimal(38, 8)),
    `shipped_qty` Nullable(Decimal(38, 8)),
    `shipped_cbm` Nullable(Decimal(38, 8)),
    `shipped_kg` Nullable(Decimal(38, 8)),
    `shipped_cse` Nullable(Decimal(38, 8)),
    `shipped_pl` Nullable(Decimal(38, 8)),
    `delivery_date_1` Nullable(DateTime64(3, 'UTC')),
    `actual_ship_date` Nullable(DateTime64(3, 'UTC'))
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (so, orderlinenumber)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH group_pickdetail AS
    (
        SELECT
            storer_key,
            whseid,
            order_key,
            order_line_number,
            sum(qty) AS shipped_qty
        FROM swm_dwh_mondelez.dim_pickdetail
        FINAL
        PREWHERE (storer_key = 'MDLZ') AND (whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831'))
        WHERE is_deleted = 0
        GROUP BY
            storer_key,
            whseid,
            order_key,
            order_line_number
    )
SELECT
    concat(ifNull(oh.extern_order_key, ''), ifNull(od.order_line_number, '')) AS biz_key,
    od.whseid AS whseid,
    if((od.whseid IN ('BKD1', 'BKD2', 'BKD3')), 'BKD', od.whseid) AS whseid_stm,
    oh.extern_order_key AS so,
    od.order_line_number AS orderlinenumber,
    oh.type AS type,
    ot.description AS type_description,
    multiIf(oh.status_code = '04', 'New', oh.status_code = '14', 'PartAllocate', oh.status_code = '17', 'Allocated', oh.status_code = '52', 'PartPick', oh.status_code = '55', 'Picked', oh.status_code = '92', 'PartShipped', oh.status_code = '95', 'ShipCompleted', oh.status_code = '72', 'InSorting', oh.status_code = '75', 'Sorted', oh.status_code = '82', 'InPacking', oh.status_code = '85', 'Packed', oh.status_code = '1', 'Cancel', oh.status_code = '31', 'PartPreAllocated', oh.status_code = '32', 'PreAllocated', oh.status_code = '2', 'Close', NULL) AS status,
    od.sku AS item_code,
    sku.sku_name AS ten_hang,
    od.uom AS uom,
    sku.group_of_cargo AS group_of_cago,
    sku.brand AS brand,
    mloc.channel AS group_name,
    oh.consignee_key AS customer_code,
    mloc.cus_location_name AS customer_name,
    oh.notes2 AS remark_2,
    CAST(od.original_qty, 'Nullable(Decimal(38,\r\n 8))') AS original_qty,
    CAST(od.original_qty * sku.cbm_per_masterunit, 'Nullable(Decimal(38,\r\n 8))') AS original_cbm,
    CAST(od.original_qty * sku.kg_per_masterunit, 'Nullable(Decimal(38,\r\n 8))') AS original_kg,
    CAST(od.original_qty / nullIf(sku.masterunit_per_cse, 0), 'Nullable(Decimal(38,\r\n 8))') AS original_cse,
    CAST(od.original_qty / nullIf(sku.masterunit_per_pallet, 0), 'Nullable(Decimal(38,\r\n 8))') AS original_pl,
    CAST(gp.shipped_qty, 'Nullable(Decimal(38,\r\n 8))') AS shipped_qty,
    CAST(gp.shipped_qty * sku.cbm_per_masterunit, 'Nullable(Decimal(38,\r\n 8))') AS shipped_cbm,
    CAST(gp.shipped_qty * sku.kg_per_masterunit, 'Nullable(Decimal(38,\r\n 8))') AS shipped_kg,
    CAST(gp.shipped_qty / nullIf(sku.masterunit_per_cse, 0), 'Nullable(Decimal(38,\r\n 8))') AS shipped_cse,
    CAST(gp.shipped_qty / nullIf(sku.masterunit_per_pallet, 0), 'Nullable(Decimal(38,\r\n 8))') AS shipped_pl,
    if((oh.delivery_date IS NULL) OR (toDate(toDateTime64(oh.delivery_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(oh.delivery_date, 3, 'UTC')) AS delivery_date_1,
    if((oh.actual_ship_date IS NULL) OR (toDate(toDateTime64(oh.actual_ship_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(oh.actual_ship_date, 3, 'UTC')) AS actual_ship_date
FROM swm_dwh_mondelez.dim_orderdetail AS od
FINAL
LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (od.sku = sku.item_code) AND (od.whseid = sku.whseid)
LEFT JOIN swm_dwh_mondelez.dim_orders AS oh
FINAL ON (od.storer_key = oh.storer_key) AND (od.whseid = oh.whseid) AND (od.order_key = oh.order_key) AND (oh.is_deleted = 0)
LEFT JOIN analytics_workspace.mv_masterdata_location AS mloc ON oh.consignee_key = mloc.cus_location_code
LEFT JOIN
group_pickdetail AS gp ON (od.storer_key = gp.storer_key) AND (od.whseid = gp.whseid) AND (od.order_key = gp.order_key) AND (od.order_line_number = gp.order_line_number)
LEFT JOIN analytics_workspace.mv_masterdata_ordertype AS ot ON (oh.whseid = ot.whseid) AND (oh.type = ot.code)
WHERE (od.storer_key = 'MDLZ') AND (od.is_deleted = 0) AND (((od.whseid = 'NKD') AND (oh.type IN ('01', '07', '08', '09', '240', 'XB2BMC', 'XTNPP'))) OR ((od.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (oh.type IN ('01', '240')))) AND (oh.status_code IN ('1', '2')) AND (od.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (oh.extern_order_key IS NOT NULL) AND (od.order_key IS NOT NULL)


-- ════════════════════════════════════════════════════
-- Object: mv_filter_activity  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_activity
(
    `code` String,
    `activity_name` String
)
AS SELECT
    'Xuất bán / Loading loose' AS activity_name,
    'Xuất bán / Loading loose' AS code
UNION ALL
SELECT
    'Xuất chuyển kho / WH Transfer In-Ex' AS activity_name,
    'Xuất chuyển kho / WH Transfer In-Ex' AS code
UNION ALL
SELECT
    'Xuất chuyển kho / WH Transfer In-In' AS activity_name,
    'Xuất chuyển kho / WH Transfer In-In' AS code
UNION ALL
SELECT
    'Xuất hủy' AS activity_name,
    'Xuất hủy' AS code
UNION ALL
SELECT
    'Xuất chuyển kho trực tiếp từ xưởng' AS activity_name,
    'Xuất chuyển kho trực tiếp từ xưởng' AS code
UNION ALL
SELECT
    'Xuất khẩu / Outbound loose from Prod' AS activity_name,
    'Xuất khẩu / Outbound loose from Prod' AS code
UNION ALL
SELECT
    'Xuất TĐX / Outbound copack' AS activity_name,
    'Xuất TĐX / Outbound copack' AS code
UNION ALL
SELECT
    'Xuất POSM / Outbound POSM' AS activity_name,
    'Xuất POSM / Outbound POSM' AS code
UNION ALL
SELECT
    'Print DO' AS activity_name,
    'Print DO' AS code
UNION ALL
SELECT
    'Nhập xưởng / Inbound From Prod' AS activity_name,
    'Nhập xưởng / Inbound From Prod' AS code
UNION ALL
SELECT
    'Nhập copack' AS activity_name,
    'Nhập copack' AS code
UNION ALL
SELECT
    'Nhập cont BKD / Nhập khẩu / Inbound loose' AS activity_name,
    'Nhập cont BKD / Nhập khẩu / Inbound loose' AS code
UNION ALL
SELECT
    'Nhập chuyển kho In-Ex / Warehouse transfer' AS activity_name,
    'Nhập chuyển kho In-Ex / Warehouse transfer' AS code
UNION ALL
SELECT
    'Nhập chuyển kho In-In / Warehouse transfer' AS activity_name,
    'Nhập chuyển kho In-In / Warehouse transfer' AS code
UNION ALL
SELECT
    'Nhập trả về từ NPP' AS activity_name,
    'Nhập trả về từ NPP' AS code
UNION ALL
SELECT
    'Nhập POSM / Inbound POSM' AS activity_name,
    'Nhập POSM / Inbound POSM' AS code
UNION ALL
SELECT
    'Pallet shrink wrap' AS activity_name,
    'Pallet shrink wrap' AS code


-- ════════════════════════════════════════════════════
-- Object: mv_filter_cargo_brand  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_cargo_brand
(
    `group_of_cargo_code` Nullable(String),
    `group_of_cargo_name` Nullable(String),
    `brand_code` Nullable(String),
    `brand_name` Nullable(String)
)
AS SELECT DISTINCT
    multiIf((upper(trimBoth(sku.CATEGORY)) IN ('OTHER', 'ORTHER')) AND (substring(sku.SKU, 1, 1) = '2'), 'PM', (upper(trimBoth(sku.CATEGORY)) IN ('OTHER', 'ORTHER')) AND (sku.SKU LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.CATEGORY)) IN ('OTHER', 'ORTHER')) AND (substring(sku.SKU, 1, 1) != '2') AND (sku.SKU NOT LIKE '%SAMPLE%'), 'EQUIPMENT', (upper(trimBoth(sku.CATEGORY)) IN ('MOONCAKE')), 'MOONCAKE', (upper(trimBoth(sku.CATEGORY)) IN ('PALLET')), 'EQUIPMENT', (upper(trimBoth(sku.CATEGORY)) IN ('POSM', 'OFFBOM')), 'POSM/OFFBOM', (upper(trimBoth(sku.CATEGORY)) IN ('TEST')), 'TEST', (upper(trimBoth(sku.CATEGORY)) IN ('BUN', 'BUN1', 'BUN2')), 'FRESH', (upper(trimBoth(sku.CATEGORY)) IN ('FRESH')), 'FRESH', (upper(trimBoth(sku.CATEGORY)) IN ('DRY')), 'DRY', (upper(trimBoth(sku.CATEGORY)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (substring(sku.SKU, 1, 1) = '2'), 'PM', (upper(trimBoth(sku.CATEGORY)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (sku.SKU LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.CATEGORY)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (substring(sku.SKU, 1, 1) != '2') AND (sku.SKU NOT LIKE '%SAMPLE%'), convert_cargo.convert_skugroup, (sku.CATEGORY IS NULL) AND (substring(sku.SKU, 1, 2) = 'ZW'), 'POSM/OFFBOM', (sku.CATEGORY IS NULL) AND (substring(sku.SKU, 1, 1) = '2'), 'PM', (sku.CATEGORY IS NULL) AND (upper(sku.SKU) LIKE '%BAO BI%'), 'PM', (sku.CATEGORY IS NULL) AND (upper(sku.SKU) LIKE '%BAOBI%'), 'PM', (sku.CATEGORY IS NULL) AND (upper(sku.SKU) LIKE '%PL%'), 'EQUIPMENT', (sku.CATEGORY IS NULL) AND (upper(sku.SKU) LIKE '%PPE%'), 'EQUIPMENT', NULL) AS group_of_cargo_code,
    multiIf((upper(trimBoth(sku.CATEGORY)) IN ('OTHER', 'ORTHER')) AND (substring(sku.SKU, 1, 1) = '2'), 'PM', (upper(trimBoth(sku.CATEGORY)) IN ('OTHER', 'ORTHER')) AND (sku.SKU LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.CATEGORY)) IN ('OTHER', 'ORTHER')) AND (substring(sku.SKU, 1, 1) != '2') AND (sku.SKU NOT LIKE '%SAMPLE%'), 'EQUIPMENT', (upper(trimBoth(sku.CATEGORY)) IN ('MOONCAKE')), 'MOONCAKE', (upper(trimBoth(sku.CATEGORY)) IN ('PALLET')), 'EQUIPMENT', (upper(trimBoth(sku.CATEGORY)) IN ('POSM', 'OFFBOM')), 'POSM/OFFBOM', (upper(trimBoth(sku.CATEGORY)) IN ('TEST')), 'TEST', (upper(trimBoth(sku.CATEGORY)) IN ('BUN', 'BUN1', 'BUN2')), 'FRESH', (upper(trimBoth(sku.CATEGORY)) IN ('FRESH')), 'FRESH', (upper(trimBoth(sku.CATEGORY)) IN ('DRY')), 'DRY', (upper(trimBoth(sku.CATEGORY)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (substring(sku.SKU, 1, 1) = '2'), 'PM', (upper(trimBoth(sku.CATEGORY)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (sku.SKU LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.CATEGORY)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (substring(sku.SKU, 1, 1) != '2') AND (sku.SKU NOT LIKE '%SAMPLE%'), convert_cargo.convert_skugroup, (sku.CATEGORY IS NULL) AND (substring(sku.SKU, 1, 2) = 'ZW'), 'POSM/OFFBOM', (sku.CATEGORY IS NULL) AND (substring(sku.SKU, 1, 1) = '2'), 'PM', (sku.CATEGORY IS NULL) AND (upper(sku.SKU) LIKE '%BAO BI%'), 'PM', (sku.CATEGORY IS NULL) AND (upper(sku.SKU) LIKE '%BAOBI%'), 'PM', (sku.CATEGORY IS NULL) AND (upper(sku.SKU) LIKE '%PL%'), 'EQUIPMENT', (sku.CATEGORY IS NULL) AND (upper(sku.SKU) LIKE '%PPE%'), 'EQUIPMENT', NULL) AS group_of_cargo_name,
    multiIf(substring(sku.SKU, 1, 1) != '4', 'Other', match(upper(sku.DESCR), '(^| )SOLITE( |$)'), 'Solite', match(upper(sku.DESCR), '(^|[^A-Z0-9])AFC([^A-Z0-9]|$)'), 'AFC', match(upper(sku.DESCR), '(^|[^A-Z0-9])LU([^A-Z0-9]|$)'), 'Lu', match(upper(sku.DESCR), '(^|[^A-Z0-9])COSY([^A-Z0-9]|$)'), 'Cosy', match(upper(sku.DESCR), '(^|[^A-Z0-9])OREO([^A-Z0-9]|$)'), 'Oreo', match(upper(sku.DESCR), '(^|[^A-Z0-9])TET([^A-Z0-9]|$)'), 'Tết', match(upper(sku.DESCR), '(^|[^A-Z0-9])TRUNG THU([^A-Z0-9]|$)'), 'Trung Thu', match(upper(sku.DESCR), '(^|[^A-Z0-9])SLIDE([^A-Z0-9]|$)'), 'Slide', match(upper(sku.DESCR), '(^|[^A-Z0-9])(KD|KINH ĐÔ|KINH DO)([^A-Z0-9]|$)'), 'KD', match(upper(sku.DESCR), '(^|[^A-Z0-9])RITZ([^A-Z0-9]|$)'), 'RITZ', match(upper(sku.DESCR), '(^|[^A-Z0-9])TOBLERONE([^A-Z0-9]|$)'), 'Toblerone', NULL) AS brand_code,
    multiIf(substring(sku.SKU, 1, 1) != '4', 'Other', match(upper(sku.DESCR), '(^| )SOLITE( |$)'), 'Solite', match(upper(sku.DESCR), '(^|[^A-Z0-9])AFC([^A-Z0-9]|$)'), 'AFC', match(upper(sku.DESCR), '(^|[^A-Z0-9])LU([^A-Z0-9]|$)'), 'Lu', match(upper(sku.DESCR), '(^|[^A-Z0-9])COSY([^A-Z0-9]|$)'), 'Cosy', match(upper(sku.DESCR), '(^|[^A-Z0-9])OREO([^A-Z0-9]|$)'), 'Oreo', match(upper(sku.DESCR), '(^|[^A-Z0-9])TET([^A-Z0-9]|$)'), 'Tết', match(upper(sku.DESCR), '(^|[^A-Z0-9])TRUNG THU([^A-Z0-9]|$)'), 'Trung Thu', match(upper(sku.DESCR), '(^|[^A-Z0-9])SLIDE([^A-Z0-9]|$)'), 'Slide', match(upper(sku.DESCR), '(^|[^A-Z0-9])(KD|KINH ĐÔ|KINH DO)([^A-Z0-9]|$)'), 'KD', match(upper(sku.DESCR), '(^|[^A-Z0-9])RITZ([^A-Z0-9]|$)'), 'RITZ', match(upper(sku.DESCR), '(^|[^A-Z0-9])TOBLERONE([^A-Z0-9]|$)'), 'Toblerone', NULL) AS brand_name
FROM swm_prod.swm_sku AS sku
LEFT JOIN internal.convert_cargo AS convert_cargo ON (convert_cargo.whseid = 'BKD1') AND (sku.SKU = convert_cargo.sku)
WHERE sku.STORERKEY = 'MDLZ'


-- ════════════════════════════════════════════════════
-- Object: mv_filter_channel  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_channel
(
    `channel_code` String,
    `channel_name` String
)
AS SELECT DISTINCT
    multiIf((upper(trimBoth(GROUPCODE)) IN ('B2B', 'VN04')), 'B2B', (upper(trimBoth(GROUPCODE)) IN ('BKD', 'NKD')), 'DRP', (upper(trimBoth(GROUPCODE)) IN ('EXPORT', 'EXP', 'VN08')), 'EXPORT', (upper(trimBoth(GROUPCODE)) IN ('GT', 'VN01', 'VN09')), 'GT', (upper(trimBoth(GROUPCODE)) IN ('KA', 'VN03')), 'KA', (upper(trimBoth(GROUPCODE)) IN ('OTHER', 'VN07')), 'OTHER', 'MT') AS channel_code,
    multiIf((upper(trimBoth(GROUPCODE)) IN ('B2B', 'VN04')), 'B2B', (upper(trimBoth(GROUPCODE)) IN ('BKD', 'NKD')), 'DRP', (upper(trimBoth(GROUPCODE)) IN ('EXPORT', 'EXP', 'VN08')), 'EXPORT', (upper(trimBoth(GROUPCODE)) IN ('GT', 'VN01', 'VN09')), 'GT', (upper(trimBoth(GROUPCODE)) IN ('KA', 'VN03')), 'KA', (upper(trimBoth(GROUPCODE)) IN ('OTHER', 'VN07')), 'OTHER', 'MT') AS channel_name
FROM swm_prod.swm_storer
WHERE (WHSEID IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (TYPE = '2')


-- ════════════════════════════════════════════════════
-- Object: mv_filter_date_type_alert  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_date_type_alert
(
    `code` String,
    `date_type_name` String
)
AS SELECT
    'ETA gửi thầu (đơn)' AS date_type_name,
    'ETA gửi thầu (đơn)' AS code
UNION ALL
SELECT
    'Ngày gửi thầu' AS date_type_name,
    'Ngày gửi thầu' AS code
UNION ALL
SELECT
    'ETD chuyến - ngày dự kiến lấy hàng' AS date_type_name,
    'ETD chuyến - ngày dự kiến lấy hàng' AS code
UNION ALL
SELECT
    'ETA chuyến - ngày dự kiến giao hàng' AS date_type_name,
    'ETA chuyến - ngày dự kiến giao hàng' AS code
UNION ALL
SELECT
    'Ngày gửi yêu cầu đơn hàng' AS date_type_name,
    'Ngày gửi yêu cầu đơn hàng' AS code
UNION ALL
SELECT
    'ATD chuyến - ngày thực tế lấy hàng' AS date_type_name,
    'ATD chuyến - ngày thực tế lấy hàng' AS code
UNION ALL
SELECT
    'ATA chuyến - ngày thực tế giao hàng' AS date_type_name,
    'ATA chuyến - ngày thực tế giao hàng' AS code
UNION ALL
SELECT
    'Ngày duyệt chuyến' AS date_type_name,
    'Ngày duyệt chuyến' AS code


-- ════════════════════════════════════════════════════
-- Object: mv_filter_date_type_dap_ung  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_date_type_dap_ung
(
    `code` String,
    `date_type_name` String
)
AS SELECT
    'ETA' AS date_type_name,
    'ETA' AS code
UNION ALL
SELECT
    'Ngày gửi thầu' AS date_type_name,
    'Ngày gửi thầu' AS code
UNION ALL
SELECT
    'ATA' AS date_type_name,
    'ATA' AS code


-- ════════════════════════════════════════════════════
-- Object: mv_filter_date_type_flashreport  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_date_type_flashreport
(
    `code` String,
    `date_type_name` String
)
AS SELECT
    'Ngày GI' AS date_type_name,
    'Ngày GI' AS code
UNION ALL
SELECT
    'Actual Ship Date' AS date_type_name,
    'Actual Ship Date' AS code
UNION ALL
SELECT
    'ATA đơn' AS date_type_name,
    'ATA đơn' AS code
UNION ALL
SELECT
    'ETD gửi thầu (đơn)' AS date_type_name,
    'ETD gửi thầu (đơn)' AS code
UNION ALL
SELECT
    'ETA gửi thầu (đơn)' AS date_type_name,
    'ETA gửi thầu (đơn)' AS code


-- ════════════════════════════════════════════════════
-- Object: mv_filter_date_type_movement_transaction  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_date_type_movement_transaction
(
    `code` String,
    `date_type_name` String
)
AS SELECT
    'DATERECEIVED' AS date_type_name,
    'DATERECEIVED' AS code
UNION ALL
SELECT
    'ACTUALSHIPDATE' AS date_type_name,
    'ACTUALSHIPDATE' AS code


-- ════════════════════════════════════════════════════
-- Object: mv_filter_date_type_otif  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_date_type_otif
(
    `code` String,
    `date_type_name` String
)
AS SELECT
    'ETA gửi thầu (đơn)' AS date_type_name,
    'ETA gửi thầu (đơn)' AS code
UNION ALL
SELECT
    'ATA chi tiết chuyến' AS date_type_name,
    'ATA chi tiết chuyến' AS code
UNION ALL
SELECT
    'Ngày gửi thầu' AS date_type_name,
    'Ngày gửi thầu' AS code
UNION ALL
SELECT
    'Ngày duyệt chuyến' AS date_type_name,
    'Ngày duyệt chuyến' AS code
UNION ALL
SELECT
    'Ngày vào kho' AS date_type_name,
    'Ngày vào kho' AS code
UNION ALL
SELECT
    'Ngày GI' AS date_type_name,
    'Ngày GI' AS code
UNION ALL
SELECT
    'Ngày tạo đơn hàng' AS date_type_name,
    'Ngày tạo đơn hàng' AS code


-- ════════════════════════════════════════════════════
-- Object: mv_filter_date_type_tien_do_xuat_hang  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_date_type_tien_do_xuat_hang
(
    `code` String,
    `date_type_name` String
)
AS SELECT
    'ETD gửi thầu (đơn)' AS date_type_name,
    'ETD gửi thầu (đơn)' AS code
UNION ALL
SELECT
    'Ngày gửi thầu' AS date_type_name,
    'Ngày gửi thầu' AS code


-- ════════════════════════════════════════════════════
-- Object: mv_filter_date_type_vfr  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_date_type_vfr
(
    `code` String,
    `date_type_name` String
)
AS SELECT
    'ETA' AS date_type_name,
    'ETA' AS code
UNION ALL
SELECT
    'ATA' AS date_type_name,
    'ATA' AS code


-- ════════════════════════════════════════════════════
-- Object: mv_filter_location_tuan_thu  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_location_tuan_thu
(
    `location_code` String,
    `location_name` String
)
AS SELECT DISTINCT
    code AS location_code,
    code AS location_name
FROM analytics_workspace.mv_masterdata_location


-- ════════════════════════════════════════════════════
-- Object: mv_filter_location_type_tuan_thu  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_location_type_tuan_thu
(
    `code` String,
    `name` String
)
AS SELECT
    'Kho' AS code,
    'Kho' AS name
UNION ALL
SELECT
    'Giao hàng' AS code,
    'Giao hàng' AS name


-- ════════════════════════════════════════════════════
-- Object: mv_filter_region  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_filter_region
(
    `group_area_code` String,
    `group_area_name` String
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY tuple()
SETTINGS index_granularity = 8192
AS SELECT
    group_area.code AS group_area_code,
    group_area.area_name AS group_area_name
FROM stm_dwh_mondelez.subdim_cat_area AS group_area


-- ════════════════════════════════════════════════════
-- Object: mv_filter_type_movement_transaction  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_type_movement_transaction
(
    `code` String,
    `type_name` String
)
AS SELECT
    'Pallet rỗng' AS type_name,
    'Pallet rỗng' AS code
UNION ALL
SELECT
    'Dry & Fresh & MC & Tet' AS type_name,
    'Dry & Fresh & MC & Tet' AS code
UNION ALL
SELECT
    'POSM/OFFBOM & PM' AS type_name,
    'POSM/OFFBOM & PM' AS code


-- ════════════════════════════════════════════════════
-- Object: mv_filter_uom  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_uom
(
    `code` String,
    `activity_name` String
)
AS SELECT
    'PALLET' AS activity_name,
    'PALLET' AS code
UNION ALL
SELECT
    'CBM' AS activity_name,
    'CBM' AS code
UNION ALL
SELECT
    'TON' AS activity_name,
    'TOB' AS code
UNION ALL
SELECT
    'CSE' AS activity_name,
    'CSE' AS code


-- ════════════════════════════════════════════════════
-- Object: mv_filter_vehicle_type  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_vehicle_type
(
    `code` String,
    `activity_name` String
)
AS SELECT DISTINCT
    code AS activity_name,
    code AS code
FROM analytics_workspace.mv_masterdata_vehicle


-- ════════════════════════════════════════════════════
-- Object: mv_filter_vendor  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_vendor
(
    `vendor_code` String,
    `short_name` String
)
AS SELECT
    short_name AS vendor_code,
    short_name AS short_name
FROM stm_dwh_mondelez.subdim_cus_customer AS CUS_Customer
WHERE type_of_customer_id = 11


-- ════════════════════════════════════════════════════
-- Object: mv_filter_warehouse  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.mv_filter_warehouse
(
    `whseid` String,
    `whseid_name` String,
    `group_whseid_name` String
)
AS WITH whseid_swm AS
    (
        SELECT
            'BKD1' AS whseid,
            'BKD1' AS whseid_name,
            'BKD' AS group_whseid_name
        UNION ALL
        SELECT
            'BKD2' AS whseid,
            'BKD2' AS whseid_name,
            'BKD' AS group_whseid_name
        UNION ALL
        SELECT
            'BKD3' AS whseid,
            'BKD3' AS whseid_name,
            'BKD' AS group_whseid_name
        UNION ALL
        SELECT
            'NKD' AS whseid,
            'NKD' AS whseid_name,
            'NKD' AS group_whseid_name
    )
SELECT
    whseid,
    whseid_name,
    group_whseid_name
FROM
whseid_swm
UNION ALL
WITH whseid_swm AS
    (
        SELECT
            'BKD1' AS whseid,
            'BKD1' AS whseid_name,
            'BKD' AS group_whseid_name
        UNION ALL
        SELECT
            'BKD2' AS whseid,
            'BKD2' AS whseid_name,
            'BKD' AS group_whseid_name
        UNION ALL
        SELECT
            'BKD3' AS whseid,
            'BKD3' AS whseid_name,
            'BKD' AS group_whseid_name
        UNION ALL
        SELECT
            'NKD' AS whseid,
            'NKD' AS whseid_name,
            'NKD' AS group_whseid_name
    )
SELECT
    'VN821' AS whseid,
    'Kho BEE_BKD' AS whseid_name,
    'BKD' AS group_whseid_name
UNION ALL
WITH whseid_swm AS
    (
        SELECT
            'BKD1' AS whseid,
            'BKD1' AS whseid_name,
            'BKD' AS group_whseid_name
        UNION ALL
        SELECT
            'BKD2' AS whseid,
            'BKD2' AS whseid_name,
            'BKD' AS group_whseid_name
        UNION ALL
        SELECT
            'BKD3' AS whseid,
            'BKD3' AS whseid_name,
            'BKD' AS group_whseid_name
        UNION ALL
        SELECT
            'NKD' AS whseid,
            'NKD' AS whseid_name,
            'NKD' AS group_whseid_name
    )
SELECT
    'VN831' AS whseid,
    'Kho ngoài - NKD' AS whseid_name,
    'NKD' AS group_whseid_name


-- ════════════════════════════════════════════════════
-- Object: mv_flash_and_drop_report  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_flash_and_drop_report
REFRESH EVERY 15 MINUTE
(
    `biz_key` String,
    `whseid` String,
    `whseid_stm` String,
    `so` String,
    `orderlinenumber` String,
    `type` Nullable(String),
    `type_description` Nullable(String),
    `status` Nullable(String),
    `item_code` Nullable(String),
    `ten_hang` Nullable(String),
    `uom` Nullable(String),
    `group_of_cago` Nullable(String),
    `brand` Nullable(String),
    `group_name` Nullable(String),
    `customer_code` Nullable(String),
    `customer_name` Nullable(String),
    `original_qty` Nullable(Float64),
    `original_cbm` Nullable(Float64),
    `original_kg` Nullable(Float64),
    `original_cse` Nullable(Float64),
    `original_pl` Nullable(Float64),
    `shipped_qty` Nullable(Float64),
    `shipped_cbm` Nullable(Float64),
    `shipped_kg` Nullable(Float64),
    `shipped_cse` Nullable(Float64),
    `shipped_pl` Nullable(Float64),
    `delivery_date_1` Nullable(DateTime64(3, 'UTC')),
    `actual_ship_date` Nullable(DateTime64(3, 'UTC')),
    `remark_2` Nullable(String),
    `id_ord_groupproduct` Nullable(UInt64),
    `ma_don_hang` Nullable(String),
    `trang_thai_don_hang` Nullable(String),
    `line_no` Nullable(String),
    `quantity_bbgn` Nullable(Float64),
    `thoi_gian_gui_thau` Nullable(DateTime64(3, 'UTC')),
    `eta_giao_hang_cho_npp` Nullable(DateTime64(3, 'UTC')),
    `ata_den` Nullable(DateTime64(3, 'UTC')),
    `ata_roi` Nullable(DateTime64(3, 'UTC')),
    `id_chuyen_gui_thau` Nullable(UInt64),
    `ten_ngan_nha_van_tai` Nullable(String),
    `ma_nha_xe` Nullable(String),
    `loai_xe_van_hanh` Nullable(String),
    `ngay_tao_chuyen` Nullable(DateTime64(3, 'UTC')),
    `etd_chuyen_gui_thau` Nullable(DateTime64(3, 'UTC')),
    `atd_den` Nullable(DateTime64(3, 'UTC')),
    `gio_ra_dock` Nullable(DateTime64(3, 'UTC')),
    `tg_bat_buoc_roi_kho` Nullable(DateTime64(3, 'UTC')),
    `thoi_gian_di` Nullable(DateTime64(3, 'UTC')),
    `so_chuyen` Nullable(String),
    `so_xe` Nullable(String),
    `tai_xe` Nullable(String),
    `ma_doi_tac_nhan` Nullable(String),
    `ten_doi_tac_nhan` Nullable(String),
    `khu_vuc_doi_xe` Nullable(String),
    `san_luong_giao_cse1` Nullable(Float64),
    `san_luong_giao1` Nullable(Float64),
    `san_luong_giao_pl1` Nullable(Float64),
    `san_luong_giao` Nullable(Float64),
    `san_luong_giao_cse` Nullable(Float64),
    `san_luong_giao_cbm` Nullable(Float64),
    `san_luong_giao_kg` Nullable(Float64),
    `san_luong_giao_pl` Nullable(Float64),
    `e2e_label` Nullable(String)
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (so, orderlinenumber)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS SELECT
    biz_key,
    whseid,
    whseid_stm,
    so,
    orderlinenumber,
    type,
    type_description,
    status,
    item_code,
    ten_hang,
    uom,
    group_of_cago,
    brand,
    group_name,
    customer_code,
    customer_name,
    toFloat64(original_qty) AS original_qty,
    toFloat64(original_cbm) AS original_cbm,
    toFloat64(original_kg) AS original_kg,
    toFloat64(original_cse) AS original_cse,
    toFloat64(original_pl) AS original_pl,
    toFloat64(shipped_qty) AS shipped_qty,
    toFloat64(shipped_cbm) AS shipped_cbm,
    toFloat64(shipped_kg) AS shipped_kg,
    toFloat64(shipped_cse) AS shipped_cse,
    toFloat64(shipped_pl) AS shipped_pl,
    delivery_date_1,
    actual_ship_date,
    remark_2,
    id_ord_groupproduct,
    ma_don_hang,
    trang_thai_don_hang,
    line_no,
    toFloat64(quantity_bbgn) AS quantity_bbgn,
    thoi_gian_gui_thau,
    eta_giao_hang_cho_npp,
    ata_den,
    ata_roi,
    id_chuyen_gui_thau,
    ten_ngan_nha_van_tai,
    ma_nha_xe,
    loai_xe_van_hanh,
    ngay_tao_chuyen,
    etd_chuyen_gui_thau,
    atd_den,
    gio_ra_dock,
    tg_bat_buoc_roi_kho,
    thoi_gian_di,
    so_chuyen,
    so_xe,
    tai_xe,
    ma_doi_tac_nhan,
    ten_doi_tac_nhan,
    khu_vuc_doi_xe,
    toFloat64(san_luong_giao_cse1) AS san_luong_giao_cse1,
    toFloat64(san_luong_giao1) AS san_luong_giao1,
    toFloat64(san_luong_giao_pl1) AS san_luong_giao_pl1,
    toFloat64(san_luong_giao) AS san_luong_giao,
    toFloat64(san_luong_giao_cse) AS san_luong_giao_cse,
    toFloat64(san_luong_giao_cbm) AS san_luong_giao_cbm,
    toFloat64(san_luong_giao_kg) AS san_luong_giao_kg,
    toFloat64(san_luong_giao_pl) AS san_luong_giao_pl,
    trang_thai_don_do AS e2e_label
FROM analytics_workspace.mv_flash_report
UNION ALL
SELECT
    biz_key,
    whseid,
    whseid_stm,
    so,
    orderlinenumber,
    type,
    type_description,
    status,
    item_code,
    ten_hang,
    uom,
    group_of_cago,
    brand,
    group_name,
    customer_code,
    customer_name,
    toFloat64(original_qty) AS original_qty,
    toFloat64(original_cbm) AS original_cbm,
    toFloat64(original_kg) AS original_kg,
    toFloat64(original_cse) AS original_cse,
    toFloat64(original_pl) AS original_pl,
    toFloat64(shipped_qty) AS shipped_qty,
    toFloat64(shipped_cbm) AS shipped_cbm,
    toFloat64(shipped_kg) AS shipped_kg,
    toFloat64(shipped_cse) AS shipped_cse,
    toFloat64(shipped_pl) AS shipped_pl,
    delivery_date_1,
    actual_ship_date,
    remark_2,
    id_ord_groupproduct,
    ma_don_hang,
    trang_thai_don_hang,
    line_no,
    toFloat64(quantity_bbgn) AS quantity_bbgn,
    thoi_gian_gui_thau,
    eta_giao_hang_cho_npp,
    ata_den,
    ata_roi,
    id_chuyen_gui_thau,
    ten_ngan_nha_van_tai,
    ma_nha_xe,
    loai_xe_van_hanh,
    ngay_tao_chuyen,
    etd_chuyen_gui_thau,
    atd_den,
    gio_ra_dock,
    tg_bat_buoc_roi_kho,
    thoi_gian_di,
    so_chuyen,
    so_xe,
    tai_xe,
    ma_doi_tac_nhan,
    ten_doi_tac_nhan,
    khu_vuc_doi_xe,
    toFloat64(san_luong_giao_cse1) AS san_luong_giao_cse1,
    toFloat64(san_luong_giao1) AS san_luong_giao1,
    toFloat64(san_luong_giao_pl1) AS san_luong_giao_pl1,
    toFloat64(san_luong_giao) AS san_luong_giao,
    toFloat64(san_luong_giao_cse) AS san_luong_giao_cse,
    toFloat64(san_luong_giao_cbm) AS san_luong_giao_cbm,
    toFloat64(san_luong_giao_kg) AS san_luong_giao_kg,
    toFloat64(san_luong_giao_pl) AS san_luong_giao_pl,
    'Kế hoạch hủy' AS e2e_label
FROM analytics_workspace.mv_dropped_report


-- ════════════════════════════════════════════════════
-- Object: mv_flash_report  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_flash_report
REFRESH EVERY 5 MINUTE
(
    `biz_key` String,
    `whseid` String,
    `whseid_stm` String,
    `so` String,
    `orderlinenumber` String,
    `type` Nullable(String),
    `type_description` Nullable(String),
    `status` Nullable(String),
    `item_code` Nullable(String),
    `ten_hang` Nullable(String),
    `uom` Nullable(String),
    `group_of_cago` Nullable(String),
    `brand` Nullable(String),
    `group_name` Nullable(String),
    `customer_code` Nullable(String),
    `customer_name` Nullable(String),
    `original_qty` Nullable(Decimal(38, 8)),
    `original_cbm` Nullable(Decimal(38, 8)),
    `original_kg` Nullable(Decimal(38, 8)),
    `original_cse` Nullable(Decimal(38, 8)),
    `original_pl` Nullable(Decimal(38, 8)),
    `shipped_qty` Nullable(Decimal(38, 8)),
    `shipped_cbm` Nullable(Decimal(38, 8)),
    `shipped_kg` Nullable(Decimal(38, 8)),
    `shipped_cse` Nullable(Decimal(38, 8)),
    `shipped_pl` Nullable(Decimal(38, 8)),
    `delivery_date_1` Nullable(DateTime64(3, 'UTC')),
    `actual_ship_date` Nullable(DateTime64(3, 'UTC')),
    `remark_2` Nullable(String),
    `id_ord_groupproduct` Nullable(UInt64),
    `ma_don_hang` Nullable(String),
    `trang_thai_don_hang` Nullable(String),
    `line_no` Nullable(String),
    `quantity_bbgn` Nullable(Decimal(38, 8)),
    `thoi_gian_gui_thau` Nullable(DateTime64(3, 'UTC')),
    `eta_giao_hang_cho_npp` Nullable(DateTime64(3, 'UTC')),
    `ata_den` Nullable(DateTime64(3, 'UTC')),
    `ata_roi` Nullable(DateTime64(3, 'UTC')),
    `id_chuyen_gui_thau` Nullable(UInt64),
    `ten_ngan_nha_van_tai` Nullable(String),
    `ma_nha_xe` Nullable(String),
    `loai_xe_van_hanh` Nullable(String),
    `ngay_tao_chuyen` Nullable(DateTime64(3, 'UTC')),
    `etd_chuyen_gui_thau` Nullable(DateTime64(3, 'UTC')),
    `atd_den` Nullable(DateTime64(3, 'UTC')),
    `gio_ra_dock` Nullable(DateTime64(3, 'UTC')),
    `tg_bat_buoc_roi_kho` Nullable(DateTime64(3, 'UTC')),
    `thoi_gian_di` Nullable(DateTime64(3, 'UTC')),
    `so_chuyen` Nullable(String),
    `so_xe` Nullable(String),
    `tai_xe` Nullable(String),
    `ma_doi_tac_nhan` Nullable(String),
    `ten_doi_tac_nhan` Nullable(String),
    `khu_vuc_doi_xe` Nullable(String),
    `san_luong_giao_cse1` Nullable(Decimal(38, 8)),
    `san_luong_giao1` Nullable(Decimal(38, 8)),
    `san_luong_giao_pl1` Nullable(Decimal(38, 8)),
    `san_luong_giao` Nullable(Decimal(38, 8)),
    `san_luong_giao_cse` Nullable(Decimal(38, 8)),
    `san_luong_giao_cbm` Nullable(Decimal(38, 8)),
    `san_luong_giao_kg` Nullable(Decimal(38, 8)),
    `san_luong_giao_pl` Nullable(Decimal(38, 8)),
    `trang_thai_don_do` Nullable(String)
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (so, orderlinenumber)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    swm_stm_data AS
    (
        SELECT
            swm.*,
            stm.id_ord_groupproduct AS stm_id_ord_groupproduct,
            stm.ma_don_hang AS stm_ma_don_hang,
            stm.trang_thai_don_hang AS stm_trang_thai_don_hang,
            stm.line_no AS stm_line_no,
            stm.quantity_bbgn AS stm_quantity_bbgn,
            stm.thoi_gian_gui_thau AS stm_thoi_gian_gui_thau,
            stm.eta_giao_hang_cho_npp AS stm_eta_giao_hang_cho_npp,
            stm.ata_den AS stm_ata_den,
            stm.ata_roi AS stm_ata_roi,
            stm.id_chuyen_gui_thau AS stm_id_chuyen_gui_thau,
            stm.ten_ngan_nha_van_tai AS stm_ten_ngan_nha_van_tai,
            stm.ma_nha_xe AS stm_ma_nha_xe,
            stm.loai_xe_van_hanh AS stm_loai_xe_van_hanh,
            stm.ngay_tao_chuyen AS stm_ngay_tao_chuyen,
            stm.etd_chuyen_gui_thau AS stm_etd_chuyen_gui_thau,
            stm.atd_den AS stm_atd_den,
            stm.gio_ra_dock AS stm_gio_ra_dock,
            stm.tg_bat_buoc_roi_kho AS stm_tg_bat_buoc_roi_kho,
            stm.thoi_gian_di AS stm_thoi_gian_di,
            stm.so_chuyen AS stm_so_chuyen,
            stm.so_xe AS stm_so_xe,
            stm.tai_xe AS stm_tai_xe,
            mlf.cus_location_code AS ma_doi_tac_nhan,
            mlf.cus_location_name AS ten_doi_tac_nhan,
            mlt.group_area_name AS khu_vuc_doi_xe,
            multiIf(upperUTF8(trimBoth(ifNull(swm.uom, ''))) = 'CSE', stm.quantity_bbgn, NULL) AS san_luong_giao_cse1,
            multiIf((upperUTF8(trimBoth(ifNull(swm.uom, ''))) IN ('PCE', 'PC', 'EA')), stm.quantity_bbgn, NULL) AS san_luong_giao1,
            multiIf(upperUTF8(trimBoth(ifNull(swm.uom, ''))) = 'PALLET', stm.quantity_bbgn, NULL) AS san_luong_giao_pl1
        FROM analytics_workspace.mv_flrp_swm_data AS swm
        ANY LEFT JOIN analytics_workspace.mv_flrp_stm_data AS stm ON (swm.so = stm.ma_don_hang) AND (swm.orderlinenumber = stm.line_no)
        LEFT JOIN analytics_workspace.mv_masterdata_location AS mlf ON swm.whseid_stm = mlf.code
        LEFT JOIN analytics_workspace.mv_masterdata_location AS mlt ON swm.customer_code = mlt.code
    ),
    enriched AS
    (
        SELECT
            s.*,
            multiIf(s.san_luong_giao_cse1 IS NOT NULL, s.san_luong_giao_cse1 * toDecimal64(assumeNotNull(sku.masterunit_per_cse), 8), s.san_luong_giao1 IS NOT NULL, s.san_luong_giao1, s.san_luong_giao_pl1 IS NOT NULL, s.san_luong_giao_pl1 * toDecimal64(assumeNotNull(sku.masterunit_per_pallet), 8), toNullable(toDecimal64(0, 8))) AS san_luong_giao,
            multiIf(s.san_luong_giao_cse1 IS NOT NULL, s.san_luong_giao_cse1, s.san_luong_giao1 IS NOT NULL, s.san_luong_giao1 / nullIf(toDecimal64(assumeNotNull(sku.masterunit_per_cse), 8), toDecimal64(0, 8)), s.san_luong_giao_pl1 IS NOT NULL, (s.san_luong_giao_pl1 * toDecimal64(assumeNotNull(sku.masterunit_per_pallet), 8)) / nullIf(toDecimal64(assumeNotNull(sku.masterunit_per_cse), 8), toDecimal64(0, 8)), toNullable(toDecimal64(0, 8))) AS san_luong_giao_cse,
            multiIf(s.san_luong_giao_cse1 IS NOT NULL, (s.san_luong_giao_cse1 * toDecimal64(assumeNotNull(sku.masterunit_per_cse), 8)) * toDecimal64(assumeNotNull(sku.cbm_per_masterunit), 8), s.san_luong_giao1 IS NOT NULL, s.san_luong_giao1 * toDecimal64(assumeNotNull(sku.cbm_per_masterunit), 8), s.san_luong_giao_pl1 IS NOT NULL, (s.san_luong_giao_pl1 * toDecimal64(assumeNotNull(sku.masterunit_per_pallet), 8)) * toDecimal64(assumeNotNull(sku.cbm_per_masterunit), 8), toNullable(toDecimal64(0, 8))) AS san_luong_giao_cbm,
            multiIf(s.san_luong_giao_cse1 IS NOT NULL, (s.san_luong_giao_cse1 * toDecimal64(assumeNotNull(sku.masterunit_per_cse), 8)) * toDecimal64(assumeNotNull(sku.kg_per_masterunit), 8), s.san_luong_giao1 IS NOT NULL, s.san_luong_giao1 * toDecimal64(assumeNotNull(sku.kg_per_masterunit), 8), s.san_luong_giao_pl1 IS NOT NULL, (s.san_luong_giao_pl1 * toDecimal64(assumeNotNull(sku.masterunit_per_pallet), 8)) * toDecimal64(assumeNotNull(sku.kg_per_masterunit), 8), toNullable(toDecimal64(0, 8))) AS san_luong_giao_kg,
            multiIf(s.san_luong_giao_cse1 IS NOT NULL, (s.san_luong_giao_cse1 * toDecimal64(assumeNotNull(sku.masterunit_per_cse), 8)) / nullIf(toDecimal64(assumeNotNull(sku.masterunit_per_pallet), 8), toDecimal64(0, 8)), s.san_luong_giao1 IS NOT NULL, s.san_luong_giao1 / nullIf(toDecimal64(assumeNotNull(sku.masterunit_per_pallet), 8), toDecimal64(0, 8)), s.san_luong_giao_pl1 IS NOT NULL, s.san_luong_giao_pl1, toNullable(toDecimal64(0, 8))) AS san_luong_giao_pl
        FROM
        swm_stm_data AS s
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (assumeNotNull(s.item_code) = sku.item_code) AND (assumeNotNull(s.whseid) = sku.whseid)
    )
SELECT
    e.biz_key,
    e.whseid,
    e.whseid_stm,
    e.so,
    e.orderlinenumber,
    e.type,
    e.type_description,
    e.status,
    e.item_code,
    e.ten_hang,
    e.uom,
    e.group_of_cago,
    e.brand,
    e.group_name,
    e.customer_code,
    e.customer_name,
    e.original_qty,
    e.original_cbm,
    e.original_kg,
    e.original_cse,
    e.original_pl,
    e.shipped_qty,
    e.shipped_cbm,
    e.shipped_kg,
    e.shipped_cse,
    e.shipped_pl,
    e.delivery_date_1,
    e.actual_ship_date,
    e.remark_2,
    e.stm_id_ord_groupproduct AS id_ord_groupproduct,
    e.stm_ma_don_hang AS ma_don_hang,
    e.stm_trang_thai_don_hang AS trang_thai_don_hang,
    e.stm_line_no AS line_no,
    e.stm_quantity_bbgn AS quantity_bbgn,
    e.stm_thoi_gian_gui_thau AS thoi_gian_gui_thau,
    e.stm_eta_giao_hang_cho_npp AS eta_giao_hang_cho_npp,
    e.stm_ata_den AS ata_den,
    e.stm_ata_roi AS ata_roi,
    e.stm_id_chuyen_gui_thau AS id_chuyen_gui_thau,
    e.stm_ten_ngan_nha_van_tai AS ten_ngan_nha_van_tai,
    e.stm_ma_nha_xe AS ma_nha_xe,
    e.stm_loai_xe_van_hanh AS loai_xe_van_hanh,
    e.stm_ngay_tao_chuyen AS ngay_tao_chuyen,
    e.stm_etd_chuyen_gui_thau AS etd_chuyen_gui_thau,
    e.stm_atd_den AS atd_den,
    e.stm_gio_ra_dock AS gio_ra_dock,
    e.stm_tg_bat_buoc_roi_kho AS tg_bat_buoc_roi_kho,
    e.stm_thoi_gian_di AS thoi_gian_di,
    e.stm_so_chuyen AS so_chuyen,
    e.stm_so_xe AS so_xe,
    e.stm_tai_xe AS tai_xe,
    e.ma_doi_tac_nhan,
    e.ten_doi_tac_nhan,
    e.khu_vuc_doi_xe,
    e.san_luong_giao_cse1,
    e.san_luong_giao1,
    e.san_luong_giao_pl1,
    e.san_luong_giao,
    e.san_luong_giao_cse,
    e.san_luong_giao_cbm,
    e.san_luong_giao_kg,
    e.san_luong_giao_pl,
    multiIf(((e.status = 'ShipCompleted') AND (e.stm_trang_thai_don_hang IN ('Đã giao hàng', 'Nhận 1 phần chứng từ', 'Đã nhận chứng từ'))) OR (e.stm_ata_den IS NOT NULL), 'Đã vận chuyển', e.status = 'New', 'Chưa xuất kho', (e.status IN ('PartAllocate', 'Allocated', 'PartPick', 'Picked', 'PartShipped')), 'Đang xuất kho', (e.status = 'ShipCompleted') AND (e.stm_thoi_gian_di IS NOT NULL), 'Đang vận chuyển', e.status = 'ShipCompleted', 'Đã xuất kho', NULL) AS trang_thai_don_do
FROM
enriched AS e
SETTINGS join_algorithm = 'grace_hash', max_block_size = 1024, max_bytes_in_join = 209715200, max_bytes_before_external_group_by = 209715200, max_bytes_before_external_sort = 209715200, min_insert_block_size_bytes = 20971520, min_insert_block_size_rows = 50000, min_bytes_to_use_direct_io = 1


-- ════════════════════════════════════════════════════
-- Object: mv_flrp_stm_data  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_flrp_stm_data
REFRESH EVERY 5 MINUTE
(
    `id_ord_groupproduct` UInt64 COMMENT 'ID dim_ord_product_group',
    `ma_don_hang` String COMMENT 'Mã đơn STM (dim_ord_order.code)',
    `trang_thai_don_hang` Nullable(String) COMMENT 'Tên trạng thái đơn (dim_ord_order.status_name)',
    `line_no` String COMMENT 'LineNo từ code_sync (bỏ 1 ký tự cuối)',
    `quantity_bbgn` Nullable(Decimal(38, 8)) COMMENT 'Số lượng giao BBGN',
    `thoi_gian_gui_thau` Nullable(DateTime64(3, 'UTC')) COMMENT 'Tender date',
    `eta_giao_hang_cho_npp` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETA chi tiết chuyến',
    `ata_den` Nullable(DateTime64(3, 'UTC')) COMMENT 'date_to_come',
    `ata_roi` Nullable(DateTime64(3, 'UTC')) COMMENT 'date_to_leave',
    `id_chuyen_gui_thau` Nullable(UInt64) COMMENT 'trip_tender_id',
    `ten_ngan_nha_van_tai` Nullable(String) COMMENT 'Nhà vận tải',
    `ma_nha_xe` Nullable(String) COMMENT 'Mã nhà xe',
    `loai_xe_van_hanh` Nullable(String) COMMENT 'Nhóm xe vận hành',
    `ngay_tao_chuyen` Nullable(DateTime64(3, 'UTC')) COMMENT 'dim_ops_trip.created_date',
    `etd_chuyen_gui_thau` Nullable(DateTime64(3, 'UTC')) COMMENT 'ETD chuyến gửi thầu',
    `atd_den` Nullable(DateTime64(3, 'UTC')) COMMENT 'date_from_come',
    `gio_ra_dock` Nullable(DateTime64(3, 'UTC')) COMMENT 'loading_end (dock)',
    `tg_bat_buoc_roi_kho` Nullable(DateTime64(3, 'UTC')) COMMENT 'required_departure_time',
    `thoi_gian_di` Nullable(DateTime64(3, 'UTC')) COMMENT 'date_from_leave',
    `so_chuyen` Nullable(String) COMMENT 'Mã chuyến vận hành',
    `so_xe` Nullable(String) COMMENT 'Biển số',
    `tai_xe` Nullable(String) COMMENT 'Tài xế'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (ma_don_hang, line_no)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH dock_end AS
    (
        SELECT
            dito_master_id,
            argMax(loading_end, toInt64(register_date)) AS loading_end
        FROM stm_dwh_mondelez.dim_ops_dock_register
        WHERE is_deleted = 0
        GROUP BY dito_master_id
    )
SELECT
    opg.id AS id_ord_groupproduct,
    ord.code AS ma_don_hang,
    ord.status_name AS trang_thai_don_hang,
    left(opg.code_sync, greatest(lengthUTF8(trimBoth(opg.code_sync)) - 1, 0)) AS line_no,
    ifNull(dtd.quantity_bbgn, toDecimal64(0, 8)) AS quantity_bbgn,
    if((dtd.tender_date IS NULL) OR (toDate(toDateTime64(dtd.tender_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.tender_date, 3, 'UTC')) AS thoi_gian_gui_thau,
    if((dtd.eta IS NULL) OR (toDate(toDateTime64(dtd.eta, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.eta, 3, 'UTC')) AS eta_giao_hang_cho_npp,
    if((dtd.date_to_come IS NULL) OR (toDate(toDateTime64(dtd.date_to_come, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.date_to_come, 3, 'UTC')) AS ata_den,
    if((dtd.date_to_leave IS NULL) OR (toDate(toDateTime64(dtd.date_to_leave, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.date_to_leave, 3, 'UTC')) AS ata_roi,
    dtd.trip_tender_id AS id_chuyen_gui_thau,
    mv.short_name AS ten_ngan_nha_van_tai,
    mv.code AS ma_nha_xe,
    mveh.group_name AS loai_xe_van_hanh,
    if((trip.created_date IS NULL) OR (toDate(toDateTime64(trip.created_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(trip.created_date, 3, 'UTC')) AS ngay_tao_chuyen,
    if((tender.etd IS NULL) OR (toDate(toDateTime64(tender.etd, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(tender.etd, 3, 'UTC')) AS etd_chuyen_gui_thau,
    if((dtd.date_from_come IS NULL) OR (toDate(toDateTime64(dtd.date_from_come, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.date_from_come, 3, 'UTC')) AS atd_den,
    if((dr.loading_end IS NULL) OR (toDate(toDateTime64(dr.loading_end, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dr.loading_end, 3, 'UTC')) AS gio_ra_dock,
    if((dtd.required_departure_time IS NULL) OR (toDate(toDateTime64(dtd.required_departure_time, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.required_departure_time, 3, 'UTC')) AS tg_bat_buoc_roi_kho,
    if((dtd.date_from_leave IS NULL) OR (toDate(toDateTime64(dtd.date_from_leave, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.date_from_leave, 3, 'UTC')) AS thoi_gian_di,
    trip.code AS so_chuyen,
    mveh.reg_no AS so_xe,
    trip.driver_name1 AS tai_xe
FROM stm_dwh_mondelez.dim_ord_order AS ord
FINAL
LEFT JOIN stm_dwh_mondelez.dim_ord_product_group AS opg
FINAL ON (opg.order_id = ord.id) AND (opg.is_deleted = 0)
ANY LEFT JOIN analytics_workspace.mv_masterdata_location AS mloc_stm ON opg.location_from_id = toInt64(mloc_stm.id_cus)
LEFT JOIN stm_dwh_mondelez.dim_ops_trip_detail AS dtd
FINAL ON (dtd.order_group_product_id = opg.id) AND (dtd.is_deleted = 0)
LEFT JOIN stm_dwh_mondelez.dim_ops_trip AS trip
FINAL ON (dtd.trip_header_id = trip.id) AND (trip.is_deleted = 0) AND (trip.status_id != 13)
LEFT JOIN stm_dwh_mondelez.dim_ops_trip AS tender
FINAL ON (dtd.trip_tender_id = tender.id) AND (tender.is_deleted = 0) AND (tender.status_id = 13)
LEFT JOIN
dock_end AS dr ON dr.dito_master_id = trip.id
LEFT JOIN analytics_workspace.mv_masterdata_vendor AS mv ON trip.vendor_id = toInt64(mv.id)
LEFT JOIN analytics_workspace.mv_masterdata_vehicle AS mveh ON trip.vehicle_id = toInt64(mveh.id_vehicle)
WHERE (ord.is_deleted = 0) AND (ord.service_name = 'Xuất bán') AND (ord.customer_id = '9') AND (opg.order_id IS NOT NULL) AND (opg.code_sync IS NOT NULL) AND (trimBoth(opg.code_sync) != '') AND ((dtd.sort_order = 1) OR (dtd.sort_order = -1))
SETTINGS join_algorithm = 'grace_hash', max_block_size = 1024, max_bytes_in_join = 209715200, max_bytes_before_external_group_by = 209715200, max_bytes_before_external_sort = 209715200, min_insert_block_size_bytes = 20971520, min_insert_block_size_rows = 50000, min_bytes_to_use_direct_io = 1


-- ════════════════════════════════════════════════════
-- Object: mv_flrp_swm_data  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_flrp_swm_data
REFRESH EVERY 5 MINUTE
(
    `biz_key` String,
    `whseid` String,
    `whseid_stm` String,
    `so` String,
    `orderlinenumber` String,
    `type` Nullable(String),
    `type_description` Nullable(String),
    `status` Nullable(String),
    `item_code` Nullable(String),
    `ten_hang` Nullable(String),
    `uom` Nullable(String),
    `group_of_cago` Nullable(String),
    `brand` Nullable(String),
    `group_name` Nullable(String),
    `customer_code` Nullable(String),
    `customer_name` Nullable(String),
    `remark_2` Nullable(String),
    `original_qty` Nullable(Decimal(38, 8)),
    `original_cbm` Nullable(Decimal(38, 8)),
    `original_kg` Nullable(Decimal(38, 8)),
    `original_cse` Nullable(Decimal(38, 8)),
    `original_pl` Nullable(Decimal(38, 8)),
    `shipped_qty` Nullable(Decimal(38, 8)),
    `shipped_cbm` Nullable(Decimal(38, 8)),
    `shipped_kg` Nullable(Decimal(38, 8)),
    `shipped_cse` Nullable(Decimal(38, 8)),
    `shipped_pl` Nullable(Decimal(38, 8)),
    `delivery_date_1` Nullable(DateTime64(3, 'UTC')),
    `actual_ship_date` Nullable(DateTime64(3, 'UTC'))
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (so, orderlinenumber)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH group_pickdetail AS
    (
        SELECT
            storer_key,
            whseid,
            order_key,
            order_line_number,
            sum(qty) AS shipped_qty
        FROM swm_dwh_mondelez.dim_pickdetail
        FINAL
        PREWHERE (storer_key = 'MDLZ') AND (whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831'))
        WHERE is_deleted = 0
        GROUP BY
            storer_key,
            whseid,
            order_key,
            order_line_number
    )
SELECT
    concat(ifNull(oh.extern_order_key, ''), ifNull(od.order_line_number, '')) AS biz_key,
    od.whseid AS whseid,
    if((od.whseid IN ('BKD1', 'BKD2', 'BKD3')), 'BKD', od.whseid) AS whseid_stm,
    oh.extern_order_key AS so,
    od.order_line_number AS orderlinenumber,
    oh.type AS type,
    ot.description AS type_description,
    multiIf(oh.status_code = '04', 'New', oh.status_code = '14', 'PartAllocate', oh.status_code = '17', 'Allocated', oh.status_code = '52', 'PartPick', oh.status_code = '55', 'Picked', oh.status_code = '92', 'PartShipped', oh.status_code = '95', 'ShipCompleted', oh.status_code = '72', 'InSorting', oh.status_code = '75', 'Sorted', oh.status_code = '82', 'InPacking', oh.status_code = '85', 'Packed', oh.status_code = '1', 'Cancel', oh.status_code = '31', 'PartPreAllocated', oh.status_code = '32', 'PreAllocated', oh.status_code = '2', 'Close', NULL) AS status,
    od.sku AS item_code,
    sku.sku_name AS ten_hang,
    od.uom AS uom,
    sku.group_of_cargo AS group_of_cago,
    sku.brand AS brand,
    mloc.channel AS group_name,
    oh.consignee_key AS customer_code,
    mloc.cus_location_name AS customer_name,
    oh.notes2 AS remark_2,
    CAST(od.original_qty, 'Nullable(Decimal(38,\r\n 8))') AS original_qty,
    CAST(od.original_qty * sku.cbm_per_masterunit, 'Nullable(Decimal(38,\r\n 8))') AS original_cbm,
    CAST(od.original_qty * sku.kg_per_masterunit, 'Nullable(Decimal(38,\r\n 8))') AS original_kg,
    CAST(od.original_qty / nullIf(sku.masterunit_per_cse, 0), 'Nullable(Decimal(38,\r\n 8))') AS original_cse,
    CAST(od.original_qty / nullIf(sku.masterunit_per_pallet, 0), 'Nullable(Decimal(38,\r\n 8))') AS original_pl,
    CAST(gp.shipped_qty, 'Nullable(Decimal(38,\r\n 8))') AS shipped_qty,
    CAST(gp.shipped_qty * sku.cbm_per_masterunit, 'Nullable(Decimal(38,\r\n 8))') AS shipped_cbm,
    CAST(gp.shipped_qty * sku.kg_per_masterunit, 'Nullable(Decimal(38,\r\n 8))') AS shipped_kg,
    CAST(gp.shipped_qty / nullIf(sku.masterunit_per_cse, 0), 'Nullable(Decimal(38,\r\n 8))') AS shipped_cse,
    CAST(gp.shipped_qty / nullIf(sku.masterunit_per_pallet, 0), 'Nullable(Decimal(38,\r\n 8))') AS shipped_pl,
    if((oh.delivery_date IS NULL) OR (toDate(toDateTime64(oh.delivery_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(oh.delivery_date, 3, 'UTC')) AS delivery_date_1,
    if((oh.actual_ship_date IS NULL) OR (toDate(toDateTime64(oh.actual_ship_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(oh.actual_ship_date, 3, 'UTC')) AS actual_ship_date
FROM swm_dwh_mondelez.dim_orderdetail AS od
FINAL
LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (od.sku = sku.item_code) AND (od.whseid = sku.whseid)
LEFT JOIN swm_dwh_mondelez.dim_orders AS oh
FINAL ON (od.storer_key = oh.storer_key) AND (od.whseid = oh.whseid) AND (od.order_key = oh.order_key) AND (oh.is_deleted = 0)
LEFT JOIN analytics_workspace.mv_masterdata_location AS mloc ON oh.consignee_key = assumeNotNull(mloc.cus_location_code)
LEFT JOIN
group_pickdetail AS gp ON (od.storer_key = gp.storer_key) AND (od.whseid = gp.whseid) AND (od.order_key = gp.order_key) AND (od.order_line_number = gp.order_line_number)
LEFT JOIN analytics_workspace.mv_masterdata_ordertype AS ot ON (oh.whseid = ot.whseid) AND (oh.type = ot.code)
WHERE (od.storer_key = 'MDLZ') AND (od.is_deleted = 0) AND (((od.whseid = 'NKD') AND (oh.type IN ('01', '07', '08', '09', '240', 'XB2BMC', 'XTNPP'))) OR ((od.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (oh.type IN ('01', '240')))) AND (oh.status_code NOT IN ('1', '2')) AND (od.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (oh.extern_order_key IS NOT NULL) AND (od.order_key IS NOT NULL) AND ((upperUTF8(trimBoth(ifNull(oh.sync_status, ''))) = 'SUCCESS') OR (trimBoth(ifNull(oh.sync_status, '')) = ''))
SETTINGS join_algorithm = 'grace_hash', max_block_size = 1024, max_bytes_in_join = 209715200, max_bytes_before_external_group_by = 209715200, max_bytes_before_external_sort = 209715200, min_insert_block_size_bytes = 20971520, min_insert_block_size_rows = 50000, min_bytes_to_use_direct_io = 1


-- ════════════════════════════════════════════════════
-- Object: mv_inbound_transaction_base  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_inbound_transaction_base
REFRESH EVERY 30 MINUTE
(
    `transaction_date` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày transaction',
    `warehouse` String COMMENT 'Mã kho',
    `category_converted` Nullable(String) COMMENT 'Bộ lọc Category đã converted',
    `activity` Nullable(String) COMMENT 'Hoạt động nhập hoặc xuất',
    `uom` Nullable(String) COMMENT 'Đơn vị tính tiền cho activity',
    `PCE` Nullable(Float64) COMMENT 'Khối lượng xử lý,\r\n\r\n đơn vị masterunit/PCE/EA',
    `CBM` Nullable(Float64) COMMENT 'Khối lượng xử lý,\r\n\r\n đơn vị CBM',
    `Ton` Nullable(Float64) COMMENT 'Khối lượng xử lý,\r\n\r\n đơn vị TON',
    `CSE` Nullable(Float64) COMMENT 'Khối lượng xử lý,\r\n\r\n đơn vị CSE',
    `Pallet` Nullable(Float64) COMMENT 'Khối lượng xử lý,\r\n\r\n đơn vị PALLET',
    `orders` Nullable(UInt64) COMMENT 'Số đơn xử lý',
    `direction` Nullable(String) COMMENT 'Luồng nhập hoặc xuất'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (warehouse, transaction_date)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    inbound_summary AS
    (
        SELECT
            toDate(rd.date_received) AS date_received,
            rd.whseid AS warehouse,
            r.extern_receipt_key AS extern_receipt_key,
            r.type AS type,
            rd.lottable06 AS sloc,
            rd.palletid AS palletid,
            rd.sku AS sku,
            masterdata_sku.group_of_cargo AS group_of_cargo,
            rd.qty_received AS qty_received
        FROM swm_dwh_mondelez.dim_receiptdetail AS rd
        FINAL
        LEFT JOIN swm_dwh_mondelez.dim_receipt AS r
        FINAL ON (r.receipt_key = rd.receipt_key) AND (r.whseid = rd.whseid) AND (r.storer_key = rd.storer_key) AND (r.is_deleted = 0)
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS masterdata_sku ON (masterdata_sku.whseid = rd.whseid) AND (masterdata_sku.item_code = rd.sku)
        WHERE (rd.status_code = '9') AND (rd.storer_key = 'MDLZ') AND (rd.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (rd.is_deleted = 0)
    ),
    inbound_all AS
    (
        SELECT
            ib.date_received,
            ib.warehouse,
            ib.extern_receipt_key,
            ib.type,
            ib.sku,
            ib.sloc,
            ib.palletid,
            sku.group_of_cargo,
            multiIf((trimBoth(upper(ib.sku)) IN ('LOSCAM', 'BACHTHUAN')), 'Pallet rỗng', (sku.group_of_cargo IN ('DRY', 'FRESH', 'MOONCAKE', 'TET')), 'Dry & Fresh & MC & Tet', (sku.group_of_cargo IN ('POSM/OFFBOM', 'PM')), 'POSM/OFFBOM & PM', NULL) AS category_converted,
            ib.qty_received,
            ib.qty_received * sku.cbm_per_masterunit AS CBM_received,
            (ib.qty_received * sku.kg_per_masterunit) / 1000 AS TON_received,
            ib.qty_received / nullIf(sku.masterunit_per_cse, 0) AS CSE_received,
            ib.qty_received / nullIf(sku.masterunit_per_pallet, 0) AS PALLET_received
        FROM
        inbound_summary AS ib
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (ib.sku = sku.item_code) AND (ib.warehouse = sku.whseid)
    ),
    inbound_from_prod AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập xưởng / Inbound From Prod' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type = '04'))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK'))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_copack AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập copack' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND ((type = '05') OR ((type = 'FGTN') AND ((sloc = '0072') OR (sloc IS NULL) OR (sloc = ''))))) OR ((warehouse = 'NKD') AND ((type = '05') OR ((type = 'FGTN') AND (sloc IN ('0032', '0021')))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_loose AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập cont BKD / Nhập khẩu / Inbound loose' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('03', '09', '16', '220'))) OR ((warehouse = 'NKD') AND (type IN ('03', '07', '220', 'NK')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_ex AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-Ex / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type IN ('08', 'ICDMT', 'ICD')) AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type = '09') AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_in AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-In / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE (type = '02') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_return_npp AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập trả về từ NPP' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('06', '36E', '70E'))) OR ((warehouse = 'NKD') AND (type IN ('06', '08')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_posm AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập POSM / Inbound POSM' AS activity_inbound,
            'TONS' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type = '01') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type IN ('01', 'NPOSM')) AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_shrink_wrap AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Phí quấn màng co / Pallet shrink wrap' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type IN ('04', '03', '09', '16', '220')))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK', '03', '07', '220', 'NK'))))
        GROUP BY
            1,
            2,
            3
    )
SELECT
    date_received AS transaction_date,
    warehouse,
    category_converted,
    activity_inbound AS activity,
    uom,
    PCE,
    CBM,
    Ton,
    CSE,
    Pallet,
    don AS orders,
    'INBOUND' AS direction
FROM
inbound_from_prod
UNION ALL
WITH
    inbound_summary AS
    (
        SELECT
            toDate(rd.date_received) AS date_received,
            rd.whseid AS warehouse,
            r.extern_receipt_key AS extern_receipt_key,
            r.type AS type,
            rd.lottable06 AS sloc,
            rd.palletid AS palletid,
            rd.sku AS sku,
            masterdata_sku.group_of_cargo AS group_of_cargo,
            rd.qty_received AS qty_received
        FROM swm_dwh_mondelez.dim_receiptdetail AS rd
        FINAL
        LEFT JOIN swm_dwh_mondelez.dim_receipt AS r
        FINAL ON (r.receipt_key = rd.receipt_key) AND (r.whseid = rd.whseid) AND (r.storer_key = rd.storer_key) AND (r.is_deleted = 0)
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS masterdata_sku ON (masterdata_sku.whseid = rd.whseid) AND (masterdata_sku.item_code = rd.sku)
        WHERE (rd.status_code = '9') AND (rd.storer_key = 'MDLZ') AND (rd.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (rd.is_deleted = 0)
    ),
    inbound_all AS
    (
        SELECT
            ib.date_received,
            ib.warehouse,
            ib.extern_receipt_key,
            ib.type,
            ib.sku,
            ib.sloc,
            ib.palletid,
            sku.group_of_cargo,
            multiIf((trimBoth(upper(ib.sku)) IN ('LOSCAM', 'BACHTHUAN')), 'Pallet rỗng', (sku.group_of_cargo IN ('DRY', 'FRESH', 'MOONCAKE', 'TET')), 'Dry & Fresh & MC & Tet', (sku.group_of_cargo IN ('POSM/OFFBOM', 'PM')), 'POSM/OFFBOM & PM', NULL) AS category_converted,
            ib.qty_received,
            ib.qty_received * sku.cbm_per_masterunit AS CBM_received,
            (ib.qty_received * sku.kg_per_masterunit) / 1000 AS TON_received,
            ib.qty_received / nullIf(sku.masterunit_per_cse, 0) AS CSE_received,
            ib.qty_received / nullIf(sku.masterunit_per_pallet, 0) AS PALLET_received
        FROM
        inbound_summary AS ib
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (ib.sku = sku.item_code) AND (ib.warehouse = sku.whseid)
        WHERE sku.group_of_cargo NOT IN ('PM', 'TEST', 'EQUIPMENT')
    ),
    inbound_from_prod AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập xưởng / Inbound From Prod' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type = '04'))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK'))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_copack AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập copack' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND ((type = '05') OR ((type = 'FGTN') AND ((sloc = '0072') OR (sloc IS NULL) OR (sloc = ''))))) OR ((warehouse = 'NKD') AND ((type = '05') OR ((type = 'FGTN') AND (sloc IN ('0032', '0021')))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_loose AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập cont BKD / Nhập khẩu / Inbound loose' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('03', '09', '16', '220'))) OR ((warehouse = 'NKD') AND (type IN ('03', '07', '220', 'NK')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_ex AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-Ex / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type IN ('08', 'ICDMT', 'ICD')) AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type = '09') AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_in AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-In / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE (type = '02') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_return_npp AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập trả về từ NPP' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('06', '36E', '70E'))) OR ((warehouse = 'NKD') AND (type IN ('06', '08')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_posm AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập POSM / Inbound POSM' AS activity_inbound,
            'TONS' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type = '01') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type IN ('01', 'NPOSM')) AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_shrink_wrap AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Phí quấn màng co / Pallet shrink wrap' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type IN ('04', '03', '09', '16', '220')))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK', '03', '07', '220', 'NK'))))
        GROUP BY
            1,
            2,
            3
    )
SELECT
    date_received,
    warehouse,
    category_converted,
    activity_inbound,
    uom,
    PCE,
    CBM,
    Ton,
    CSE,
    Pallet,
    don,
    'INBOUND'
FROM
inbound_copack
UNION ALL
WITH
    inbound_summary AS
    (
        SELECT
            toDate(rd.date_received) AS date_received,
            rd.whseid AS warehouse,
            r.extern_receipt_key AS extern_receipt_key,
            r.type AS type,
            rd.lottable06 AS sloc,
            rd.palletid AS palletid,
            rd.sku AS sku,
            masterdata_sku.group_of_cargo AS group_of_cargo,
            rd.qty_received AS qty_received
        FROM swm_dwh_mondelez.dim_receiptdetail AS rd
        FINAL
        LEFT JOIN swm_dwh_mondelez.dim_receipt AS r
        FINAL ON (r.receipt_key = rd.receipt_key) AND (r.whseid = rd.whseid) AND (r.storer_key = rd.storer_key) AND (r.is_deleted = 0)
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS masterdata_sku ON (masterdata_sku.whseid = rd.whseid) AND (masterdata_sku.item_code = rd.sku)
        WHERE (rd.status_code = '9') AND (rd.storer_key = 'MDLZ') AND (rd.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (rd.is_deleted = 0)
    ),
    inbound_all AS
    (
        SELECT
            ib.date_received,
            ib.warehouse,
            ib.extern_receipt_key,
            ib.type,
            ib.sku,
            ib.sloc,
            ib.palletid,
            sku.group_of_cargo,
            multiIf((trimBoth(upper(ib.sku)) IN ('LOSCAM', 'BACHTHUAN')), 'Pallet rỗng', (sku.group_of_cargo IN ('DRY', 'FRESH', 'MOONCAKE', 'TET')), 'Dry & Fresh & MC & Tet', (sku.group_of_cargo IN ('POSM/OFFBOM', 'PM')), 'POSM/OFFBOM & PM', NULL) AS category_converted,
            ib.qty_received,
            ib.qty_received * sku.cbm_per_masterunit AS CBM_received,
            (ib.qty_received * sku.kg_per_masterunit) / 1000 AS TON_received,
            ib.qty_received / nullIf(sku.masterunit_per_cse, 0) AS CSE_received,
            ib.qty_received / nullIf(sku.masterunit_per_pallet, 0) AS PALLET_received
        FROM
        inbound_summary AS ib
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (ib.sku = sku.item_code) AND (ib.warehouse = sku.whseid)
        WHERE sku.group_of_cargo NOT IN ('PM', 'TEST', 'EQUIPMENT')
    ),
    inbound_from_prod AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập xưởng / Inbound From Prod' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type = '04'))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK'))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_copack AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập copack' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND ((type = '05') OR ((type = 'FGTN') AND ((sloc = '0072') OR (sloc IS NULL) OR (sloc = ''))))) OR ((warehouse = 'NKD') AND ((type = '05') OR ((type = 'FGTN') AND (sloc IN ('0032', '0021')))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_loose AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập cont BKD / Nhập khẩu / Inbound loose' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('03', '09', '16', '220'))) OR ((warehouse = 'NKD') AND (type IN ('03', '07', '220', 'NK')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_ex AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-Ex / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type IN ('08', 'ICDMT', 'ICD')) AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type = '09') AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_in AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-In / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE (type = '02') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_return_npp AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập trả về từ NPP' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('06', '36E', '70E'))) OR ((warehouse = 'NKD') AND (type IN ('06', '08')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_posm AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập POSM / Inbound POSM' AS activity_inbound,
            'TONS' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type = '01') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type IN ('01', 'NPOSM')) AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_shrink_wrap AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Phí quấn màng co / Pallet shrink wrap' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type IN ('04', '03', '09', '16', '220')))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK', '03', '07', '220', 'NK'))))
        GROUP BY
            1,
            2,
            3
    )
SELECT
    date_received,
    warehouse,
    category_converted,
    activity_inbound,
    uom,
    PCE,
    CBM,
    Ton,
    CSE,
    Pallet,
    don,
    'INBOUND'
FROM
inbound_loose
UNION ALL
WITH
    inbound_summary AS
    (
        SELECT
            toDate(rd.date_received) AS date_received,
            rd.whseid AS warehouse,
            r.extern_receipt_key AS extern_receipt_key,
            r.type AS type,
            rd.lottable06 AS sloc,
            rd.palletid AS palletid,
            rd.sku AS sku,
            masterdata_sku.group_of_cargo AS group_of_cargo,
            rd.qty_received AS qty_received
        FROM swm_dwh_mondelez.dim_receiptdetail AS rd
        FINAL
        LEFT JOIN swm_dwh_mondelez.dim_receipt AS r
        FINAL ON (r.receipt_key = rd.receipt_key) AND (r.whseid = rd.whseid) AND (r.storer_key = rd.storer_key) AND (r.is_deleted = 0)
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS masterdata_sku ON (masterdata_sku.whseid = rd.whseid) AND (masterdata_sku.item_code = rd.sku)
        WHERE (rd.status_code = '9') AND (rd.storer_key = 'MDLZ') AND (rd.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (rd.is_deleted = 0)
    ),
    inbound_all AS
    (
        SELECT
            ib.date_received,
            ib.warehouse,
            ib.extern_receipt_key,
            ib.type,
            ib.sku,
            ib.sloc,
            ib.palletid,
            sku.group_of_cargo,
            multiIf((trimBoth(upper(ib.sku)) IN ('LOSCAM', 'BACHTHUAN')), 'Pallet rỗng', (sku.group_of_cargo IN ('DRY', 'FRESH', 'MOONCAKE', 'TET')), 'Dry & Fresh & MC & Tet', (sku.group_of_cargo IN ('POSM/OFFBOM', 'PM')), 'POSM/OFFBOM & PM', NULL) AS category_converted,
            ib.qty_received,
            ib.qty_received * sku.cbm_per_masterunit AS CBM_received,
            (ib.qty_received * sku.kg_per_masterunit) / 1000 AS TON_received,
            ib.qty_received / nullIf(sku.masterunit_per_cse, 0) AS CSE_received,
            ib.qty_received / nullIf(sku.masterunit_per_pallet, 0) AS PALLET_received
        FROM
        inbound_summary AS ib
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (ib.sku = sku.item_code) AND (ib.warehouse = sku.whseid)
        WHERE sku.group_of_cargo NOT IN ('PM', 'TEST', 'EQUIPMENT')
    ),
    inbound_from_prod AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập xưởng / Inbound From Prod' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type = '04'))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK'))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_copack AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập copack' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND ((type = '05') OR ((type = 'FGTN') AND ((sloc = '0072') OR (sloc IS NULL) OR (sloc = ''))))) OR ((warehouse = 'NKD') AND ((type = '05') OR ((type = 'FGTN') AND (sloc IN ('0032', '0021')))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_loose AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập cont BKD / Nhập khẩu / Inbound loose' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('03', '09', '16', '220'))) OR ((warehouse = 'NKD') AND (type IN ('03', '07', '220', 'NK')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_ex AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-Ex / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type IN ('08', 'ICDMT', 'ICD')) AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type = '09') AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_in AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-In / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE (type = '02') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_return_npp AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập trả về từ NPP' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('06', '36E', '70E'))) OR ((warehouse = 'NKD') AND (type IN ('06', '08')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_posm AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập POSM / Inbound POSM' AS activity_inbound,
            'TONS' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type = '01') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type IN ('01', 'NPOSM')) AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_shrink_wrap AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Phí quấn màng co / Pallet shrink wrap' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type IN ('04', '03', '09', '16', '220')))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK', '03', '07', '220', 'NK'))))
        GROUP BY
            1,
            2,
            3
    )
SELECT
    date_received,
    warehouse,
    category_converted,
    activity_inbound,
    uom,
    PCE,
    CBM,
    Ton,
    CSE,
    Pallet,
    don,
    'INBOUND'
FROM
inbound_wh_transfer_in_ex
UNION ALL
WITH
    inbound_summary AS
    (
        SELECT
            toDate(rd.date_received) AS date_received,
            rd.whseid AS warehouse,
            r.extern_receipt_key AS extern_receipt_key,
            r.type AS type,
            rd.lottable06 AS sloc,
            rd.palletid AS palletid,
            rd.sku AS sku,
            masterdata_sku.group_of_cargo AS group_of_cargo,
            rd.qty_received AS qty_received
        FROM swm_dwh_mondelez.dim_receiptdetail AS rd
        FINAL
        LEFT JOIN swm_dwh_mondelez.dim_receipt AS r
        FINAL ON (r.receipt_key = rd.receipt_key) AND (r.whseid = rd.whseid) AND (r.storer_key = rd.storer_key) AND (r.is_deleted = 0)
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS masterdata_sku ON (masterdata_sku.whseid = rd.whseid) AND (masterdata_sku.item_code = rd.sku)
        WHERE (rd.status_code = '9') AND (rd.storer_key = 'MDLZ') AND (rd.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (rd.is_deleted = 0)
    ),
    inbound_all AS
    (
        SELECT
            ib.date_received,
            ib.warehouse,
            ib.extern_receipt_key,
            ib.type,
            ib.sku,
            ib.sloc,
            ib.palletid,
            sku.group_of_cargo,
            multiIf((trimBoth(upper(ib.sku)) IN ('LOSCAM', 'BACHTHUAN')), 'Pallet rỗng', (sku.group_of_cargo IN ('DRY', 'FRESH', 'MOONCAKE', 'TET')), 'Dry & Fresh & MC & Tet', (sku.group_of_cargo IN ('POSM/OFFBOM', 'PM')), 'POSM/OFFBOM & PM', NULL) AS category_converted,
            ib.qty_received,
            ib.qty_received * sku.cbm_per_masterunit AS CBM_received,
            (ib.qty_received * sku.kg_per_masterunit) / 1000 AS TON_received,
            ib.qty_received / nullIf(sku.masterunit_per_cse, 0) AS CSE_received,
            ib.qty_received / nullIf(sku.masterunit_per_pallet, 0) AS PALLET_received
        FROM
        inbound_summary AS ib
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (ib.sku = sku.item_code) AND (ib.warehouse = sku.whseid)
        WHERE sku.group_of_cargo NOT IN ('PM', 'TEST', 'EQUIPMENT')
    ),
    inbound_from_prod AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập xưởng / Inbound From Prod' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type = '04'))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK'))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_copack AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập copack' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND ((type = '05') OR ((type = 'FGTN') AND ((sloc = '0072') OR (sloc IS NULL) OR (sloc = ''))))) OR ((warehouse = 'NKD') AND ((type = '05') OR ((type = 'FGTN') AND (sloc IN ('0032', '0021')))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_loose AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập cont BKD / Nhập khẩu / Inbound loose' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('03', '09', '16', '220'))) OR ((warehouse = 'NKD') AND (type IN ('03', '07', '220', 'NK')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_ex AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-Ex / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type IN ('08', 'ICDMT', 'ICD')) AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type = '09') AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_in AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-In / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE (type = '02') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_return_npp AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập trả về từ NPP' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('06', '36E', '70E'))) OR ((warehouse = 'NKD') AND (type IN ('06', '08')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_posm AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập POSM / Inbound POSM' AS activity_inbound,
            'TONS' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type = '01') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type IN ('01', 'NPOSM')) AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_shrink_wrap AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Phí quấn màng co / Pallet shrink wrap' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type IN ('04', '03', '09', '16', '220')))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK', '03', '07', '220', 'NK'))))
        GROUP BY
            1,
            2,
            3
    )
SELECT
    date_received,
    warehouse,
    category_converted,
    activity_inbound,
    uom,
    PCE,
    CBM,
    Ton,
    CSE,
    Pallet,
    don,
    'INBOUND'
FROM
inbound_wh_transfer_in_in
UNION ALL
WITH
    inbound_summary AS
    (
        SELECT
            toDate(rd.date_received) AS date_received,
            rd.whseid AS warehouse,
            r.extern_receipt_key AS extern_receipt_key,
            r.type AS type,
            rd.lottable06 AS sloc,
            rd.palletid AS palletid,
            rd.sku AS sku,
            masterdata_sku.group_of_cargo AS group_of_cargo,
            rd.qty_received AS qty_received
        FROM swm_dwh_mondelez.dim_receiptdetail AS rd
        FINAL
        LEFT JOIN swm_dwh_mondelez.dim_receipt AS r
        FINAL ON (r.receipt_key = rd.receipt_key) AND (r.whseid = rd.whseid) AND (r.storer_key = rd.storer_key) AND (r.is_deleted = 0)
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS masterdata_sku ON (masterdata_sku.whseid = rd.whseid) AND (masterdata_sku.item_code = rd.sku)
        WHERE (rd.status_code = '9') AND (rd.storer_key = 'MDLZ') AND (rd.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (rd.is_deleted = 0)
    ),
    inbound_all AS
    (
        SELECT
            ib.date_received,
            ib.warehouse,
            ib.extern_receipt_key,
            ib.type,
            ib.sku,
            ib.sloc,
            ib.palletid,
            sku.group_of_cargo,
            multiIf((trimBoth(upper(ib.sku)) IN ('LOSCAM', 'BACHTHUAN')), 'Pallet rỗng', (sku.group_of_cargo IN ('DRY', 'FRESH', 'MOONCAKE', 'TET')), 'Dry & Fresh & MC & Tet', (sku.group_of_cargo IN ('POSM/OFFBOM', 'PM')), 'POSM/OFFBOM & PM', NULL) AS category_converted,
            ib.qty_received,
            ib.qty_received * sku.cbm_per_masterunit AS CBM_received,
            (ib.qty_received * sku.kg_per_masterunit) / 1000 AS TON_received,
            ib.qty_received / nullIf(sku.masterunit_per_cse, 0) AS CSE_received,
            ib.qty_received / nullIf(sku.masterunit_per_pallet, 0) AS PALLET_received
        FROM
        inbound_summary AS ib
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (ib.sku = sku.item_code) AND (ib.warehouse = sku.whseid)
        WHERE sku.group_of_cargo NOT IN ('PM', 'TEST', 'EQUIPMENT')
    ),
    inbound_from_prod AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập xưởng / Inbound From Prod' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type = '04'))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK'))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_copack AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập copack' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND ((type = '05') OR ((type = 'FGTN') AND ((sloc = '0072') OR (sloc IS NULL) OR (sloc = ''))))) OR ((warehouse = 'NKD') AND ((type = '05') OR ((type = 'FGTN') AND (sloc IN ('0032', '0021')))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_loose AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập cont BKD / Nhập khẩu / Inbound loose' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('03', '09', '16', '220'))) OR ((warehouse = 'NKD') AND (type IN ('03', '07', '220', 'NK')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_ex AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-Ex / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type IN ('08', 'ICDMT', 'ICD')) AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type = '09') AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_in AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-In / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE (type = '02') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_return_npp AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập trả về từ NPP' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('06', '36E', '70E'))) OR ((warehouse = 'NKD') AND (type IN ('06', '08')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_posm AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập POSM / Inbound POSM' AS activity_inbound,
            'TONS' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type = '01') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type IN ('01', 'NPOSM')) AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_shrink_wrap AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Phí quấn màng co / Pallet shrink wrap' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type IN ('04', '03', '09', '16', '220')))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK', '03', '07', '220', 'NK'))))
        GROUP BY
            1,
            2,
            3
    )
SELECT
    date_received,
    warehouse,
    category_converted,
    activity_inbound,
    uom,
    PCE,
    CBM,
    Ton,
    CSE,
    Pallet,
    don,
    'INBOUND'
FROM
inbound_return_npp
UNION ALL
WITH
    inbound_summary AS
    (
        SELECT
            toDate(rd.date_received) AS date_received,
            rd.whseid AS warehouse,
            r.extern_receipt_key AS extern_receipt_key,
            r.type AS type,
            rd.lottable06 AS sloc,
            rd.palletid AS palletid,
            rd.sku AS sku,
            masterdata_sku.group_of_cargo AS group_of_cargo,
            rd.qty_received AS qty_received
        FROM swm_dwh_mondelez.dim_receiptdetail AS rd
        FINAL
        LEFT JOIN swm_dwh_mondelez.dim_receipt AS r
        FINAL ON (r.receipt_key = rd.receipt_key) AND (r.whseid = rd.whseid) AND (r.storer_key = rd.storer_key) AND (r.is_deleted = 0)
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS masterdata_sku ON (masterdata_sku.whseid = rd.whseid) AND (masterdata_sku.item_code = rd.sku)
        WHERE (rd.status_code = '9') AND (rd.storer_key = 'MDLZ') AND (rd.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (rd.is_deleted = 0)
    ),
    inbound_all AS
    (
        SELECT
            ib.date_received,
            ib.warehouse,
            ib.extern_receipt_key,
            ib.type,
            ib.sku,
            ib.sloc,
            ib.palletid,
            sku.group_of_cargo,
            multiIf((trimBoth(upper(ib.sku)) IN ('LOSCAM', 'BACHTHUAN')), 'Pallet rỗng', (sku.group_of_cargo IN ('DRY', 'FRESH', 'MOONCAKE', 'TET')), 'Dry & Fresh & MC & Tet', (sku.group_of_cargo IN ('POSM/OFFBOM', 'PM')), 'POSM/OFFBOM & PM', NULL) AS category_converted,
            ib.qty_received,
            ib.qty_received * sku.cbm_per_masterunit AS CBM_received,
            (ib.qty_received * sku.kg_per_masterunit) / 1000 AS TON_received,
            ib.qty_received / nullIf(sku.masterunit_per_cse, 0) AS CSE_received,
            ib.qty_received / nullIf(sku.masterunit_per_pallet, 0) AS PALLET_received
        FROM
        inbound_summary AS ib
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (ib.sku = sku.item_code) AND (ib.warehouse = sku.whseid)
        WHERE sku.group_of_cargo NOT IN ('PM', 'TEST', 'EQUIPMENT')
    ),
    inbound_from_prod AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập xưởng / Inbound From Prod' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type = '04'))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK'))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_copack AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập copack' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND ((type = '05') OR ((type = 'FGTN') AND ((sloc = '0072') OR (sloc IS NULL) OR (sloc = ''))))) OR ((warehouse = 'NKD') AND ((type = '05') OR ((type = 'FGTN') AND (sloc IN ('0032', '0021')))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_loose AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập cont BKD / Nhập khẩu / Inbound loose' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('03', '09', '16', '220'))) OR ((warehouse = 'NKD') AND (type IN ('03', '07', '220', 'NK')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_ex AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-Ex / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type IN ('08', 'ICDMT', 'ICD')) AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type = '09') AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_in AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-In / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE (type = '02') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_return_npp AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập trả về từ NPP' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('06', '36E', '70E'))) OR ((warehouse = 'NKD') AND (type IN ('06', '08')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_posm AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập POSM / Inbound POSM' AS activity_inbound,
            'TONS' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type = '01') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type IN ('01', 'NPOSM')) AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_shrink_wrap AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Phí quấn màng co / Pallet shrink wrap' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type IN ('04', '03', '09', '16', '220')))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK', '03', '07', '220', 'NK'))))
        GROUP BY
            1,
            2,
            3
    )
SELECT
    date_received,
    warehouse,
    category_converted,
    activity_inbound,
    uom,
    PCE,
    CBM,
    Ton,
    CSE,
    Pallet,
    don,
    'INBOUND'
FROM
inbound_posm
UNION ALL
WITH
    inbound_summary AS
    (
        SELECT
            toDate(rd.date_received) AS date_received,
            rd.whseid AS warehouse,
            r.extern_receipt_key AS extern_receipt_key,
            r.type AS type,
            rd.lottable06 AS sloc,
            rd.palletid AS palletid,
            rd.sku AS sku,
            masterdata_sku.group_of_cargo AS group_of_cargo,
            rd.qty_received AS qty_received
        FROM swm_dwh_mondelez.dim_receiptdetail AS rd
        FINAL
        LEFT JOIN swm_dwh_mondelez.dim_receipt AS r
        FINAL ON (r.receipt_key = rd.receipt_key) AND (r.whseid = rd.whseid) AND (r.storer_key = rd.storer_key) AND (r.is_deleted = 0)
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS masterdata_sku ON (masterdata_sku.whseid = rd.whseid) AND (masterdata_sku.item_code = rd.sku)
        WHERE (rd.status_code = '9') AND (rd.storer_key = 'MDLZ') AND (rd.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (rd.is_deleted = 0)
    ),
    inbound_all AS
    (
        SELECT
            ib.date_received,
            ib.warehouse,
            ib.extern_receipt_key,
            ib.type,
            ib.sku,
            ib.sloc,
            ib.palletid,
            sku.group_of_cargo,
            multiIf((trimBoth(upper(ib.sku)) IN ('LOSCAM', 'BACHTHUAN')), 'Pallet rỗng', (sku.group_of_cargo IN ('DRY', 'FRESH', 'MOONCAKE', 'TET')), 'Dry & Fresh & MC & Tet', (sku.group_of_cargo IN ('POSM/OFFBOM', 'PM')), 'POSM/OFFBOM & PM', NULL) AS category_converted,
            ib.qty_received,
            ib.qty_received * sku.cbm_per_masterunit AS CBM_received,
            (ib.qty_received * sku.kg_per_masterunit) / 1000 AS TON_received,
            ib.qty_received / nullIf(sku.masterunit_per_cse, 0) AS CSE_received,
            ib.qty_received / nullIf(sku.masterunit_per_pallet, 0) AS PALLET_received
        FROM
        inbound_summary AS ib
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (ib.sku = sku.item_code) AND (ib.warehouse = sku.whseid)
        WHERE sku.group_of_cargo NOT IN ('PM', 'TEST', 'EQUIPMENT')
    ),
    inbound_from_prod AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập xưởng / Inbound From Prod' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type = '04'))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK'))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_copack AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập copack' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND ((type = '05') OR ((type = 'FGTN') AND ((sloc = '0072') OR (sloc IS NULL) OR (sloc = ''))))) OR ((warehouse = 'NKD') AND ((type = '05') OR ((type = 'FGTN') AND (sloc IN ('0032', '0021')))))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_loose AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập cont BKD / Nhập khẩu / Inbound loose' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('03', '09', '16', '220'))) OR ((warehouse = 'NKD') AND (type IN ('03', '07', '220', 'NK')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_ex AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-Ex / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type IN ('08', 'ICDMT', 'ICD')) AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type = '09') AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_wh_transfer_in_in AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập chuyển kho In-In / Warehouse transfer' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE (type = '02') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_return_npp AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập trả về từ NPP' AS activity_inbound,
            'CBM' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (type IN ('06', '36E', '70E'))) OR ((warehouse = 'NKD') AND (type IN ('06', '08')))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_posm AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Nhập POSM / Inbound POSM' AS activity_inbound,
            'TONS' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((type = '01') AND (warehouse IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type IN ('01', 'NPOSM')) AND (warehouse = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    inbound_shrink_wrap AS
    (
        SELECT
            date_received,
            warehouse,
            category_converted,
            'Phí quấn màng co / Pallet shrink wrap' AS activity_inbound,
            'PALLET' AS uom,
            sum(qty_received) AS PCE,
            sum(CBM_received) AS CBM,
            sum(TON_received) AS Ton,
            sum(CSE_received) AS CSE,
            count(palletid) AS Pallet,
            countDistinct(extern_receipt_key) AS don
        FROM
        inbound_all
        WHERE ((warehouse IN ('BKD1', 'BKD2', 'BKD3')) AND (((type = 'FGTN') AND (sloc IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (type IN ('04', '03', '09', '16', '220')))) OR ((warehouse = 'NKD') AND (((type = 'FGTN') AND (sloc IN ('0041', '0047', '0020', '0050', '0055'))) OR (type IN ('04', 'NB2BMC', 'NHXK', '03', '07', '220', 'NK'))))
        GROUP BY
            1,
            2,
            3
    )
SELECT
    date_received,
    warehouse,
    category_converted,
    activity_inbound,
    uom,
    PCE,
    CBM,
    Ton,
    CSE,
    Pallet,
    don,
    'INBOUND'
FROM
inbound_shrink_wrap


-- ════════════════════════════════════════════════════
-- Object: mv_loose_picking_clickhouse  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_loose_picking_clickhouse
REFRESH EVERY 1 HOUR
(
    `whseid` String,
    `SO` String,
    `order_key` String,
    `actual_ship_date` DateTime64(9),
    `item_code` String,
    `product_name` String,
    `batch` DateTime64(9),
    `number_of_full_pallets` Nullable(Float64),
    `cse_full` Nullable(Float64),
    `cse_loose` Nullable(Float64),
    `pct_loose_picking` Nullable(Float64),
    `customer_code` String,
    `customer_name` String,
    `region` String
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY tuple()
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    sku_stm AS
    (
        SELECT
            products.id AS id_cus,
            products.code AS item_code_raw,
            replaceRegexpAll(trimBoth(products.code), '[ /-].*$', '') AS item_code,
            row_number() OVER (PARTITION BY replaceRegexpAll(trimBoth(products.code), '[ /-].*$', '') ORDER BY products.id ASC) AS rn
        FROM stm_dwh_mondelez.subdim_cus_product AS products
        LEFT JOIN stm_dwh_mondelez.subdim_cus_group_of_product AS group_products ON (products.group_of_product_id = group_products.id) AND (group_products.is_deleted = 0)
        WHERE products.is_deleted = 0
    ),
    masterdata_sku AS
    (
        SELECT
            sku_stm.id_cus,
            sku.whseid AS whseid,
            sku.sku AS item_code,
            sku.descr AS sku_name,
            sku.category,
            multiIf((upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (left(sku.sku, 1) = '2'), 'PM', (upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (sku.sku LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (left(sku.sku, 1) != '2') AND (sku.sku NOT LIKE '%SAMPLE%'), 'EQUIPMENT', (upper(trimBoth(sku.category)) IN ('MOONCAKE')), 'MOONCAKE', (upper(trimBoth(sku.category)) IN ('PALLET')), 'EQUIPMENT', (upper(trimBoth(sku.category)) IN ('POSM', 'OFFBOM')), 'POSM/OFFBOM', (upper(trimBoth(sku.category)) IN ('TEST')), 'TEST', (upper(trimBoth(sku.category)) IN ('BUN', 'BUN1', 'BUN2')), 'FRESH', (upper(trimBoth(sku.category)) IN ('FRESH')), 'FRESH', (upper(trimBoth(sku.category)) IN ('DRY')), 'DRY', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (left(sku.sku, 1) = '2'), 'PM', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (sku.sku LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (left(sku.sku, 1) != '2') AND (sku.sku NOT LIKE '%SAMPLE%'), convert_cargo.convert_skugroup, (sku.category IS NULL) AND (left(sku.sku, 2) = 'ZW'), 'POSM/OFFBOM', (sku.category IS NULL) AND (left(sku.sku, 1) = '2'), 'PM', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%BAO BI%'), 'PM', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%BAOBI%'), 'PM', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%PL%'), 'EQUIPMENT', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%PPE%'), 'EQUIPMENT', NULL) AS group_of_cargo,
            multiIf(substring(sku.sku, 1, 1) != '4', 'Other', match(upper(sku.descr), '(^| )SOLITE( |$)'), 'Solite', match(upper(sku.descr), '(^|[^A-Z0-9])AFC([^A-Z0-9]|$)'), 'AFC', match(upper(sku.descr), '(^|[^A-Z0-9])LU([^A-Z0-9]|$)'), 'Lu', match(upper(sku.descr), '(^|[^A-Z0-9])COSY([^A-Z0-9]|$)'), 'Cosy', match(upper(sku.descr), '(^|[^A-Z0-9])OREO([^A-Z0-9]|$)'), 'Oreo', match(upper(sku.descr), '(^|[^A-Z0-9])TET([^A-Z0-9]|$)'), 'Tết', match(upper(sku.descr), '(^|[^A-Z0-9])TRUNG THU([^A-Z0-9]|$)'), 'Trung Thu', match(upper(sku.descr), '(^|[^A-Z0-9])SLIDE([^A-Z0-9]|$)'), 'Slide', match(upper(sku.descr), '(^|[^A-Z0-9])(KD|KINH ĐÔ|KINH DO)([^A-Z0-9]|$)'), 'KD', match(upper(sku.descr), '(^|[^A-Z0-9])RITZ([^A-Z0-9]|$)'), 'RITZ', match(upper(sku.descr), '(^|[^A-Z0-9])TOBLERONE([^A-Z0-9]|$)'), 'Toblerone', NULL) AS brand,
            sku.std_cube AS cbm_per_masterunit,
            sku.std_grossweight AS kg_per_masterunit,
            pack.inner_pack AS masterunit_per_cse,
            pack.pallet AS masterunit_per_pallet
        FROM
        sku_stm
        FULL OUTER JOIN swm_dwh_mondelez.dim_sku AS sku ON (sku.storer_key = 'MDLZ') AND (sku_stm.rn = 1) AND (sku_stm.item_code = sku.sku) AND (sku.is_deleted = 0)
        LEFT JOIN swm_dwh_mondelez.dim_pack AS pack ON (pack.whseid = sku.whseid) AND (pack.pack_key = sku.pack_key) AND (pack.is_deleted = 0)
        LEFT JOIN internal.convert_cargo AS convert_cargo ON (convert_cargo.whseid = 'BKD1') AND (sku.sku = convert_cargo.sku)
        WHERE (sku.storer_key = 'MDLZ') AND (sku.is_deleted = 0)
    ),
    group_pickdetail AS
    (
        SELECT
            pickdetail.storer_key,
            pickdetail.whseid,
            pickdetail.order_key,
            pickdetail.order_line_number,
            pickdetail.lpnid,
            sum(pickdetail.qty) AS SHIPPED
        FROM swm_dwh_mondelez.dim_pickdetail AS pickdetail
        WHERE pickdetail.is_deleted = 0
        GROUP BY
            1,
            2,
            3,
            4,
            5
    ),
    enriching_data AS
    (
        SELECT
            orders.whseid AS whseid,
            orders.extern_order_key AS SO,
            orders.order_key AS order_key,
            orders.actual_ship_date AS actual_ship_date,
            orderdetail.order_line_number,
            orders.consignee_key AS `Customer Code`,
            masterdata_location.cus_location_name AS `Customer Name`,
            masterdata_location.group_area_name AS `Khu vực đội xe`,
            orderdetail.sku AS item_code,
            masterdata_sku.sku_name AS product_name,
            masterdata_sku.group_of_cargo AS `Group of Cago`,
            rd.lottable04 AS batch,
            orderdetail.original_qty AS ORIGINAL,
            orderdetail.original_qty * cbm_per_masterunit AS `ORIGINAL CBM`,
            orderdetail.original_qty * kg_per_masterunit AS `ORIGINAL KG`,
            orderdetail.original_qty / nullIf(masterunit_per_cse, 0) AS `ORIGINAL CSE`,
            orderdetail.original_qty / nullIf(masterunit_per_pallet, 0) AS `ORIGINAL PL`,
            p.SHIPPED AS SHIPPED,
            p.SHIPPED * cbm_per_masterunit AS `SHIPPED CBM`,
            p.SHIPPED * kg_per_masterunit AS `SHIPPED KG`,
            p.SHIPPED / nullIf(masterunit_per_cse, 0) AS `SHIPPED CSE`,
            p.SHIPPED / nullIf(masterunit_per_pallet, 0) AS `SHIPPED PL`,
            cbm_per_masterunit,
            kg_per_masterunit,
            masterunit_per_cse,
            masterunit_per_pallet,
            masterunit_per_pallet / nullIf(masterunit_per_cse, 0) AS cse_per_pallet
        FROM swm_dwh_mondelez.dim_orderdetail AS orderdetail
        LEFT JOIN
        masterdata_sku ON (orderdetail.whseid = masterdata_sku.whseid) AND (orderdetail.sku = masterdata_sku.item_code)
        LEFT JOIN swm_dwh_mondelez.dim_orders AS orders ON (orderdetail.storer_key = orders.storer_key) AND (orderdetail.whseid = orders.whseid) AND (orderdetail.order_key = orders.order_key) AND (orders.is_deleted = 0)
        LEFT JOIN
        group_pickdetail AS p ON (orderdetail.storer_key = p.storer_key) AND (orderdetail.whseid = p.whseid) AND (orderdetail.order_key = p.order_key) AND (orderdetail.order_line_number = p.order_line_number)
        LEFT JOIN swm_dwh_mondelez.dim_receiptdetail AS rd ON (rd.storer_key = p.storer_key) AND (rd.whseid = p.whseid) AND (rd.lpnid = p.lpnid) AND (rd.is_deleted = 0)
        LEFT JOIN analytics_workspace.mv_masterdata_location AS masterdata_location ON orders.consignee_key = masterdata_location.cus_location_code
        WHERE (orderdetail.storer_key = 'MDLZ') AND (orders.status_code = '95') AND (orderdetail.is_deleted = 0) AND (orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (orders.extern_order_key IS NOT NULL) AND (orderdetail.order_key IS NOT NULL) AND (((orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (orders.type IN ('01', '240'))) OR ((orderdetail.whseid = 'NKD') AND (orders.type IN ('01', '07', '08', '09', '240', 'XB2BMC', 'XTNPP'))))
    ),
    summary AS
    (
        SELECT
            whseid,
            SO,
            order_key,
            actual_ship_date,
            item_code,
            product_name,
            batch,
            floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) AS number_of_full_pallets,
            floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) * max(cse_per_pallet) AS cse_full,
            sum(`SHIPPED CSE`) - (floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) * max(cse_per_pallet)) AS cse_loose,
            (sum(`SHIPPED CSE`) - (floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) * max(cse_per_pallet))) / nullIf(sum(`SHIPPED CSE`), 0) AS pct_loose_picking
        FROM
        enriching_data
        GROUP BY
            1,
            2,
            3,
            4,
            5,
            6,
            7
    )
SELECT
    summary.*,
    enriching_data.`Customer Code` AS customer_code,
    enriching_data.`Customer Name` AS customer_name,
    enriching_data.`Khu vực đội xe` AS region
FROM
summary
LEFT JOIN
enriching_data ON (summary.SO = enriching_data.SO) AND (summary.item_code = enriching_data.item_code) AND (summary.batch = enriching_data.batch)


-- ════════════════════════════════════════════════════
-- Object: mv_loose_picking_clickhouse_new  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_loose_picking_clickhouse_new
REFRESH EVERY 20 MINUTE
(
    `whseid` String,
    `SO` String,
    `order_key` String,
    `actual_ship_date` DateTime64(9),
    `item_code` String,
    `product_name` String,
    `batch` DateTime64(9),
    `number_of_full_pallets` Nullable(Float64),
    `cse_full` Nullable(Float64),
    `cse_loose` Nullable(Float64),
    `pct_loose_picking` Nullable(Float64),
    `customer_code` String,
    `customer_name` String,
    `region` String
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY tuple()
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = `sql-console:vy.tao@gosmartlog.com` SQL SECURITY DEFINER
AS WITH
    sku_stm AS
    (
        SELECT
            products.id AS id_cus,
            products.code AS item_code_raw,
            replaceRegexpAll(trimBoth(products.code), '[ /-].*$', '') AS item_code,
            row_number() OVER (PARTITION BY replaceRegexpAll(trimBoth(products.code), '[ /-].*$', '') ORDER BY products.id ASC) AS rn
        FROM stm_dwh_mondelez.subdim_cus_product AS products
        LEFT JOIN stm_dwh_mondelez.subdim_cus_group_of_product AS group_products ON (products.group_of_product_id = group_products.id) AND (group_products.is_deleted = 0)
        WHERE products.is_deleted = 0
    ),
    masterdata_sku AS
    (
        SELECT
            sku_stm.id_cus,
            sku.whseid AS whseid,
            sku.sku AS item_code,
            sku.descr AS sku_name,
            sku.category,
            multiIf((upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (left(sku.sku, 1) = '2'), 'PM', (upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (sku.sku LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (left(sku.sku, 1) != '2') AND (sku.sku NOT LIKE '%SAMPLE%'), 'EQUIPMENT', (upper(trimBoth(sku.category)) IN ('MOONCAKE')), 'MOONCAKE', (upper(trimBoth(sku.category)) IN ('PALLET')), 'EQUIPMENT', (upper(trimBoth(sku.category)) IN ('POSM', 'OFFBOM')), 'POSM/OFFBOM', (upper(trimBoth(sku.category)) IN ('TEST')), 'TEST', (upper(trimBoth(sku.category)) IN ('BUN', 'BUN1', 'BUN2')), 'FRESH', (upper(trimBoth(sku.category)) IN ('FRESH')), 'FRESH', (upper(trimBoth(sku.category)) IN ('DRY')), 'DRY', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (left(sku.sku, 1) = '2'), 'PM', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (sku.sku LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (left(sku.sku, 1) != '2') AND (sku.sku NOT LIKE '%SAMPLE%'), convert_cargo.convert_skugroup, (sku.category IS NULL) AND (left(sku.sku, 2) = 'ZW'), 'POSM/OFFBOM', (sku.category IS NULL) AND (left(sku.sku, 1) = '2'), 'PM', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%BAO BI%'), 'PM', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%BAOBI%'), 'PM', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%PL%'), 'EQUIPMENT', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%PPE%'), 'EQUIPMENT', NULL) AS group_of_cargo,
            multiIf(substring(sku.sku, 1, 1) != '4', 'Other', match(upper(sku.descr), '(^| )SOLITE( |$)'), 'Solite', match(upper(sku.descr), '(^|[^A-Z0-9])AFC([^A-Z0-9]|$)'), 'AFC', match(upper(sku.descr), '(^|[^A-Z0-9])LU([^A-Z0-9]|$)'), 'Lu', match(upper(sku.descr), '(^|[^A-Z0-9])COSY([^A-Z0-9]|$)'), 'Cosy', match(upper(sku.descr), '(^|[^A-Z0-9])OREO([^A-Z0-9]|$)'), 'Oreo', match(upper(sku.descr), '(^|[^A-Z0-9])TET([^A-Z0-9]|$)'), 'Tết', match(upper(sku.descr), '(^|[^A-Z0-9])TRUNG THU([^A-Z0-9]|$)'), 'Trung Thu', match(upper(sku.descr), '(^|[^A-Z0-9])SLIDE([^A-Z0-9]|$)'), 'Slide', match(upper(sku.descr), '(^|[^A-Z0-9])(KD|KINH ĐÔ|KINH DO)([^A-Z0-9]|$)'), 'KD', match(upper(sku.descr), '(^|[^A-Z0-9])RITZ([^A-Z0-9]|$)'), 'RITZ', match(upper(sku.descr), '(^|[^A-Z0-9])TOBLERONE([^A-Z0-9]|$)'), 'Toblerone', NULL) AS brand,
            sku.std_cube AS cbm_per_masterunit,
            sku.std_grossweight AS kg_per_masterunit,
            pack.inner_pack AS masterunit_per_cse,
            pack.pallet AS masterunit_per_pallet
        FROM
        sku_stm
        FULL OUTER JOIN swm_dwh_mondelez.dim_sku AS sku ON (sku.storer_key = 'MDLZ') AND (sku_stm.rn = 1) AND (sku_stm.item_code = sku.sku) AND (sku.is_deleted = 0)
        LEFT JOIN swm_dwh_mondelez.dim_pack AS pack ON (pack.whseid = sku.whseid) AND (pack.pack_key = sku.pack_key) AND (pack.is_deleted = 0)
        LEFT JOIN internal.convert_cargo AS convert_cargo ON (convert_cargo.whseid = 'BKD1') AND (sku.sku = convert_cargo.sku)
        WHERE (sku.storer_key = 'MDLZ') AND (sku.is_deleted = 0)
    ),
    group_pickdetail AS
    (
        SELECT
            pickdetail.storer_key,
            pickdetail.whseid,
            pickdetail.order_key,
            pickdetail.order_line_number,
            pickdetail.lpnid,
            sum(pickdetail.qty) AS SHIPPED
        FROM swm_dwh_mondelez.dim_pickdetail AS pickdetail
        WHERE pickdetail.is_deleted = 0
        GROUP BY
            1,
            2,
            3,
            4,
            5
    ),
    enriching_data AS
    (
        SELECT
            orders.whseid AS whseid,
            orders.extern_order_key AS SO,
            orders.order_key AS order_key,
            orders.actual_ship_date AS actual_ship_date,
            orderdetail.order_line_number,
            orders.consignee_key AS `Customer Code`,
            masterdata_location.cus_location_name AS `Customer Name`,
            masterdata_location.group_area_name AS `Khu vực đội xe`,
            orderdetail.sku AS item_code,
            masterdata_sku.sku_name AS product_name,
            masterdata_sku.group_of_cargo AS `Group of Cago`,
            rd.lottable04 AS batch,
            orderdetail.original_qty AS ORIGINAL,
            orderdetail.original_qty * cbm_per_masterunit AS `ORIGINAL CBM`,
            orderdetail.original_qty * kg_per_masterunit AS `ORIGINAL KG`,
            orderdetail.original_qty / nullIf(masterunit_per_cse, 0) AS `ORIGINAL CSE`,
            orderdetail.original_qty / nullIf(masterunit_per_pallet, 0) AS `ORIGINAL PL`,
            p.SHIPPED AS SHIPPED,
            p.SHIPPED * cbm_per_masterunit AS `SHIPPED CBM`,
            p.SHIPPED * kg_per_masterunit AS `SHIPPED KG`,
            p.SHIPPED / nullIf(masterunit_per_cse, 0) AS `SHIPPED CSE`,
            p.SHIPPED / nullIf(masterunit_per_pallet, 0) AS `SHIPPED PL`,
            cbm_per_masterunit,
            kg_per_masterunit,
            masterunit_per_cse,
            masterunit_per_pallet,
            masterunit_per_pallet / nullIf(masterunit_per_cse, 0) AS cse_per_pallet
        FROM swm_dwh_mondelez.dim_orderdetail AS orderdetail
        LEFT JOIN
        masterdata_sku ON (orderdetail.whseid = masterdata_sku.whseid) AND (orderdetail.sku = masterdata_sku.item_code)
        LEFT JOIN swm_dwh_mondelez.dim_orders AS orders ON (orderdetail.storer_key = orders.storer_key) AND (orderdetail.whseid = orders.whseid) AND (orderdetail.order_key = orders.order_key) AND (orders.is_deleted = 0)
        LEFT JOIN
        group_pickdetail AS p ON (orderdetail.storer_key = p.storer_key) AND (orderdetail.whseid = p.whseid) AND (orderdetail.order_key = p.order_key) AND (orderdetail.order_line_number = p.order_line_number)
        LEFT JOIN swm_dwh_mondelez.dim_receiptdetail AS rd ON (rd.storer_key = p.storer_key) AND (rd.whseid = p.whseid) AND (rd.lpnid = p.lpnid) AND (rd.is_deleted = 0)
        LEFT JOIN analytics_workspace.mv_masterdata_location AS masterdata_location ON orders.consignee_key = masterdata_location.cus_location_code
        WHERE (orderdetail.storer_key = 'MDLZ') AND (orders.status_code = '95') AND (orderdetail.is_deleted = 0) AND (orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (orders.extern_order_key IS NOT NULL) AND (orderdetail.order_key IS NOT NULL) AND (((orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (orders.type IN ('01', '240'))) OR ((orderdetail.whseid = 'NKD') AND (orders.type IN ('01', '07', '08', '09', '240', 'XB2BMC', 'XTNPP'))))
    ),
    summary AS
    (
        SELECT
            whseid,
            SO,
            order_key,
            actual_ship_date,
            item_code,
            product_name,
            batch,
            floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) AS number_of_full_pallets,
            floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) * max(cse_per_pallet) AS cse_full,
            sum(`SHIPPED CSE`) - (floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) * max(cse_per_pallet)) AS cse_loose,
            (sum(`SHIPPED CSE`) - (floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) * max(cse_per_pallet))) / nullIf(sum(`SHIPPED CSE`), 0) AS pct_loose_picking
        FROM
        enriching_data
        GROUP BY
            1,
            2,
            3,
            4,
            5,
            6,
            7
    )
SELECT
    summary.*,
    enriching_data.`Customer Code` AS customer_code,
    enriching_data.`Customer Name` AS customer_name,
    enriching_data.`Khu vực đội xe` AS region
FROM
summary
LEFT JOIN
enriching_data ON (summary.SO = enriching_data.SO) AND (summary.item_code = enriching_data.item_code) AND (summary.batch = enriching_data.batch)
SETTINGS join_algorithm = 'grace_hash', max_block_size = 1024, max_bytes_in_join = '200M', max_bytes_before_external_group_by = '200M', max_bytes_before_external_sort = '200M', min_insert_block_size_bytes = 20971520, min_insert_block_size_rows = 50000, min_bytes_to_use_direct_io = 1


-- ════════════════════════════════════════════════════
-- Object: mv_loose_picking_clickhouse_phong_test  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_loose_picking_clickhouse_phong_test
REFRESH EVERY 1 HOUR
(
    `whseid` String,
    `SO` String,
    `order_key` String,
    `actual_ship_date` DateTime64(9),
    `item_code` String,
    `product_name` String,
    `batch` DateTime64(9),
    `number_of_full_pallets` Nullable(Float64),
    `cse_full` Nullable(Float64),
    `cse_loose` Nullable(Float64),
    `pct_loose_picking` Nullable(Float64),
    `customer_code` String,
    `customer_name` String,
    `region` String
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY tuple()
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    sku_stm AS
    (
        SELECT
            products.id AS id_cus,
            products.code AS item_code_raw,
            replaceRegexpAll(trimBoth(products.code), '[ /-].*$', '') AS item_code,
            row_number() OVER (PARTITION BY replaceRegexpAll(trimBoth(products.code), '[ /-].*$', '') ORDER BY products.id ASC) AS rn
        FROM stm_dwh_mondelez.subdim_cus_product AS products
        LEFT JOIN stm_dwh_mondelez.subdim_cus_group_of_product AS group_products ON (products.group_of_product_id = group_products.id) AND (group_products.is_deleted = 0)
        WHERE products.is_deleted = 0
    ),
    masterdata_sku AS
    (
        SELECT
            sku_stm.id_cus,
            sku.whseid AS whseid,
            sku.sku AS item_code,
            sku.descr AS sku_name,
            sku.category,
            multiIf((upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (left(sku.sku, 1) = '2'), 'PM', (upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (sku.sku LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (left(sku.sku, 1) != '2') AND (sku.sku NOT LIKE '%SAMPLE%'), 'EQUIPMENT', (upper(trimBoth(sku.category)) IN ('MOONCAKE')), 'MOONCAKE', (upper(trimBoth(sku.category)) IN ('PALLET')), 'EQUIPMENT', (upper(trimBoth(sku.category)) IN ('POSM', 'OFFBOM')), 'POSM/OFFBOM', (upper(trimBoth(sku.category)) IN ('TEST')), 'TEST', (upper(trimBoth(sku.category)) IN ('BUN', 'BUN1', 'BUN2')), 'FRESH', (upper(trimBoth(sku.category)) IN ('FRESH')), 'FRESH', (upper(trimBoth(sku.category)) IN ('DRY')), 'DRY', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (left(sku.sku, 1) = '2'), 'PM', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (sku.sku LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (left(sku.sku, 1) != '2') AND (sku.sku NOT LIKE '%SAMPLE%'), convert_cargo.convert_skugroup, (sku.category IS NULL) AND (left(sku.sku, 2) = 'ZW'), 'POSM/OFFBOM', (sku.category IS NULL) AND (left(sku.sku, 1) = '2'), 'PM', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%BAO BI%'), 'PM', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%BAOBI%'), 'PM', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%PL%'), 'EQUIPMENT', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%PPE%'), 'EQUIPMENT', NULL) AS group_of_cargo,
            multiIf(substring(sku.sku, 1, 1) != '4', 'Other', match(upper(sku.descr), '(^| )SOLITE( |$)'), 'Solite', match(upper(sku.descr), '(^|[^A-Z0-9])AFC([^A-Z0-9]|$)'), 'AFC', match(upper(sku.descr), '(^|[^A-Z0-9])LU([^A-Z0-9]|$)'), 'Lu', match(upper(sku.descr), '(^|[^A-Z0-9])COSY([^A-Z0-9]|$)'), 'Cosy', match(upper(sku.descr), '(^|[^A-Z0-9])OREO([^A-Z0-9]|$)'), 'Oreo', match(upper(sku.descr), '(^|[^A-Z0-9])TET([^A-Z0-9]|$)'), 'Tết', match(upper(sku.descr), '(^|[^A-Z0-9])TRUNG THU([^A-Z0-9]|$)'), 'Trung Thu', match(upper(sku.descr), '(^|[^A-Z0-9])SLIDE([^A-Z0-9]|$)'), 'Slide', match(upper(sku.descr), '(^|[^A-Z0-9])(KD|KINH ĐÔ|KINH DO)([^A-Z0-9]|$)'), 'KD', match(upper(sku.descr), '(^|[^A-Z0-9])RITZ([^A-Z0-9]|$)'), 'RITZ', match(upper(sku.descr), '(^|[^A-Z0-9])TOBLERONE([^A-Z0-9]|$)'), 'Toblerone', NULL) AS brand,
            sku.std_cube AS cbm_per_masterunit,
            sku.std_grossweight AS kg_per_masterunit,
            pack.inner_pack AS masterunit_per_cse,
            pack.pallet AS masterunit_per_pallet
        FROM
        sku_stm
        FULL OUTER JOIN swm_dwh_mondelez.dim_sku AS sku ON (sku.storer_key = 'MDLZ') AND (sku_stm.rn = 1) AND (sku_stm.item_code = sku.sku) AND (sku.is_deleted = 0)
        LEFT JOIN swm_dwh_mondelez.dim_pack AS pack ON (pack.whseid = sku.whseid) AND (pack.pack_key = sku.pack_key) AND (pack.is_deleted = 0)
        LEFT JOIN internal.convert_cargo AS convert_cargo ON (convert_cargo.whseid = 'BKD1') AND (sku.sku = convert_cargo.sku)
        WHERE (sku.storer_key = 'MDLZ') AND (sku.is_deleted = 0)
    ),
    group_pickdetail AS
    (
        SELECT
            pickdetail.storer_key,
            pickdetail.whseid,
            pickdetail.order_key,
            pickdetail.order_line_number,
            pickdetail.lpnid,
            sum(pickdetail.qty) AS SHIPPED
        FROM swm_dwh_mondelez.dim_pickdetail AS pickdetail
        WHERE pickdetail.is_deleted = 0
        GROUP BY
            1,
            2,
            3,
            4,
            5
    ),
    enriching_data AS
    (
        SELECT
            orders.whseid AS whseid,
            orders.extern_order_key AS SO,
            orders.order_key AS order_key,
            orders.actual_ship_date - toIntervalHour(7) AS actual_ship_date,
            orderdetail.order_line_number,
            orders.consignee_key AS `Customer Code`,
            masterdata_location.cus_location_name AS `Customer Name`,
            masterdata_location.group_area_name AS `Khu vực đội xe`,
            orderdetail.sku AS item_code,
            masterdata_sku.sku_name AS product_name,
            masterdata_sku.group_of_cargo AS `Group of Cago`,
            rd.lottable04 - toIntervalHour(7) AS batch,
            orderdetail.original_qty AS ORIGINAL,
            orderdetail.original_qty * cbm_per_masterunit AS `ORIGINAL CBM`,
            orderdetail.original_qty * kg_per_masterunit AS `ORIGINAL KG`,
            orderdetail.original_qty / nullIf(masterunit_per_cse, 0) AS `ORIGINAL CSE`,
            orderdetail.original_qty / nullIf(masterunit_per_pallet, 0) AS `ORIGINAL PL`,
            p.SHIPPED AS SHIPPED,
            p.SHIPPED * cbm_per_masterunit AS `SHIPPED CBM`,
            p.SHIPPED * kg_per_masterunit AS `SHIPPED KG`,
            p.SHIPPED / nullIf(masterunit_per_cse, 0) AS `SHIPPED CSE`,
            p.SHIPPED / nullIf(masterunit_per_pallet, 0) AS `SHIPPED PL`,
            cbm_per_masterunit,
            kg_per_masterunit,
            masterunit_per_cse,
            masterunit_per_pallet,
            masterunit_per_pallet / nullIf(masterunit_per_cse, 0) AS cse_per_pallet
        FROM swm_dwh_mondelez.dim_orderdetail AS orderdetail
        LEFT JOIN
        masterdata_sku ON (orderdetail.whseid = masterdata_sku.whseid) AND (orderdetail.sku = masterdata_sku.item_code)
        LEFT JOIN swm_dwh_mondelez.dim_orders AS orders ON (orderdetail.storer_key = orders.storer_key) AND (orderdetail.whseid = orders.whseid) AND (orderdetail.order_key = orders.order_key) AND (orders.is_deleted = 0)
        LEFT JOIN
        group_pickdetail AS p ON (orderdetail.storer_key = p.storer_key) AND (orderdetail.whseid = p.whseid) AND (orderdetail.order_key = p.order_key) AND (orderdetail.order_line_number = p.order_line_number)
        LEFT JOIN swm_dwh_mondelez.dim_receiptdetail AS rd ON (rd.storer_key = p.storer_key) AND (rd.whseid = p.whseid) AND (rd.lpnid = p.lpnid) AND (rd.is_deleted = 0)
        LEFT JOIN analytics_workspace.mv_masterdata_location AS masterdata_location ON orders.consignee_key = masterdata_location.cus_location_code
        WHERE (orderdetail.storer_key = 'MDLZ') AND (orders.status_code = '95') AND (orderdetail.is_deleted = 0) AND (orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (orders.extern_order_key IS NOT NULL) AND (orderdetail.order_key IS NOT NULL) AND (((orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (orders.type IN ('01', '240'))) OR ((orderdetail.whseid = 'NKD') AND (orders.type IN ('01', '07', '08', '09', '240', 'XB2BMC', 'XTNPP'))))
    ),
    summary AS
    (
        SELECT
            whseid,
            SO,
            order_key,
            actual_ship_date,
            item_code,
            product_name,
            batch,
            floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) AS number_of_full_pallets,
            floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) * max(cse_per_pallet) AS cse_full,
            sum(`SHIPPED CSE`) - (floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) * max(cse_per_pallet)) AS cse_loose,
            (sum(`SHIPPED CSE`) - (floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) * max(cse_per_pallet))) / nullIf(sum(`SHIPPED CSE`), 0) AS pct_loose_picking
        FROM
        enriching_data
        GROUP BY
            1,
            2,
            3,
            4,
            5,
            6,
            7
    )
SELECT
    summary.*,
    enriching_data.`Customer Code` AS customer_code,
    enriching_data.`Customer Name` AS customer_name,
    enriching_data.`Khu vực đội xe` AS region
FROM
summary
LEFT JOIN
enriching_data ON (summary.SO = enriching_data.SO) AND (summary.item_code = enriching_data.item_code) AND (summary.batch = enriching_data.batch)


-- ════════════════════════════════════════════════════
-- Object: mv_masterdata_kho_stm  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_masterdata_kho_stm
REFRESH EVERY 3 MINUTE
(
    `id_kho` Int32,
    `ten_he_thong` Nullable(String),
    `ma_he_thong` Nullable(String),
    `ma_su_dung` String,
    `ten_su_dung` String,
    `id_khach_hang` Int32,
    `ten_khach_hang` Nullable(String)
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY id_kho
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS SELECT
    main.subcat_location_sk AS id_kho,
    cat.location AS ten_he_thong,
    cat.code AS ma_he_thong,
    main.code AS ma_su_dung,
    main.location_name AS ten_su_dung,
    main.cus_customer_sk AS id_khach_hang,
    csc.customer_name AS ten_khach_hang
FROM stm_dwh_mondelez.dim_cus_location AS main
LEFT JOIN stm_dwh_mondelez.subdim_cat_location AS cat ON main.subcat_location_sk = cat.key_sk
LEFT JOIN stm_dwh_mondelez.subdim_cus_customer AS csc ON main.cus_customer_sk = csc.key_sk
WHERE (main.cus_partner_sk = 0) AND (main.cus_customer_sk = 9)


-- ════════════════════════════════════════════════════
-- Object: mv_masterdata_location  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_masterdata_location
REFRESH EVERY 3 MINUTE
(
    `id_cus` Int32,
    `id_cat` Int32,
    `code` String,
    `name` String,
    `cus_location_code` String,
    `cus_location_name` String,
    `group_area_code` String,
    `group_area_name` String,
    `channel_raw` String,
    `channel` String,
    `STT` UInt64
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY tuple()
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = `sql-console:vy.tao@gosmartlog.com` SQL SECURITY DEFINER
AS WITH customer_swm AS
    (
        SELECT DISTINCT
            storer_key AS code,
            company AS name,
            address1 AS address,
            group_code AS group_raw
        FROM swm_dwh_mondelez.subdim_storer
        WHERE (whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (type = '2') AND (is_deleted = 0)
    )
SELECT *
FROM
(
    SELECT
        location_cus.key_sk AS id_cus,
        location_cat.key_sk AS id_cat,
        customer_swm.code AS code,
        customer_swm.name AS name,
        location_cus.code AS cus_location_code,
        location_cus.location_name AS cus_location_name,
        group_area.code AS group_area_code,
        group_area.area_name AS group_area_name,
        upper(trimBoth(customer_swm.group_raw)) AS channel_raw,
        multiIf((upper(trimBoth(customer_swm.group_raw)) IN ('B2B', 'VN04')), 'B2B', (upper(trimBoth(customer_swm.group_raw)) IN ('BKD', 'NKD')), 'DRP', (upper(trimBoth(customer_swm.group_raw)) IN ('EXPORT', 'EXP', 'VN08')), 'EXPORT', (upper(trimBoth(customer_swm.group_raw)) IN ('GT', 'VN01', 'VN09')), 'GT', (upper(trimBoth(customer_swm.group_raw)) IN ('KA', 'VN03')), 'KA', (upper(trimBoth(customer_swm.group_raw)) IN ('OTHER', 'VN07')), 'OTHER', 'MT') AS channel,
        row_number() OVER (PARTITION BY location_cus.code ORDER BY location_cus.key_sk ASC) AS STT
    FROM
    customer_swm
    LEFT JOIN stm_dwh_mondelez.dim_cus_location AS location_cus ON (location_cus.code = customer_swm.code) AND (location_cus.is_deleted = 0)
    LEFT JOIN stm_dwh_mondelez.subdim_cat_location AS location_cat ON (location_cus.subcat_location_sk = location_cat.key_sk) AND (location_cat.is_deleted = 0)
    LEFT JOIN stm_dwh_mondelez.subdim_cat_area AS group_area ON (location_cat.area_id = group_area.key_sk) AND (group_area.is_deleted = 0)
    LEFT JOIN stm_dwh_mondelez.subdim_cus_partner AS partner_cus ON (location_cus.cus_partner_sk = partner_cus.key_sk) AND (partner_cus.is_deleted = 0)
    LEFT JOIN stm_dwh_mondelez.subdim_cat_partner AS partner_cat ON (partner_cus.partner_id = partner_cat.id) AND (partner_cat.is_deleted = 0)
    WHERE (location_cus.cus_customer_sk = 9) AND (location_cus.is_deleted = 0)
) AS final_data
WHERE STT = 1


-- ════════════════════════════════════════════════════
-- Object: mv_masterdata_ordertype  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_masterdata_ordertype
REFRESH EVERY 6 MINUTE
(
    `whseid` String,
    `code` String,
    `description` String,
    `long_value` String
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY tuple()
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = `sql-console:vy.tao@gosmartlog.com` SQL SECURITY DEFINER
AS SELECT
    whseid,
    code,
    description,
    long_value
FROM swm_dwh_mondelez.dim_codelkup
WHERE (whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (list_name = 'ORDERTYPE') AND (is_deleted = 0)


-- ════════════════════════════════════════════════════
-- Object: mv_masterdata_sku  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_masterdata_sku
REFRESH EVERY 1 HOUR
(
    `id_cus` Int32,
    `whseid` String,
    `item_code` String,
    `sku_name` String,
    `category` String,
    `group_of_cargo` Nullable(String),
    `brand` Nullable(String),
    `cbm_per_masterunit` Float64,
    `kg_per_masterunit` Float64,
    `masterunit_per_cse` Float64,
    `masterunit_per_pallet` Float64
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY tuple()
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = `sql-console:vy.tao@gosmartlog.com` SQL SECURITY DEFINER
AS WITH sku_stm AS
    (
        SELECT
            products.id AS id_cus,
            products.code AS item_code_raw,
            replaceRegexpAll(trimBoth(products.code), '[ /-].*$', '') AS item_code,
            row_number() OVER (PARTITION BY replaceRegexpAll(trimBoth(products.code), '[ /-].*$', '') ORDER BY products.id ASC) AS rn
        FROM stm_dwh_mondelez.subdim_cus_product AS products
        LEFT JOIN stm_dwh_mondelez.subdim_cus_group_of_product AS group_products ON products.group_of_product_id = group_products.id
    )
SELECT
    sku_stm.id_cus,
    sku.whseid AS whseid,
    sku.sku AS item_code,
    sku.descr AS sku_name,
    sku.category AS category,
    multiIf((upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (left(sku.sku, 1) = '2'), 'PM', (upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (sku.sku LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (left(sku.sku, 1) != '2') AND (sku.sku NOT LIKE '%SAMPLE%'), 'EQUIPMENT', (upper(trimBoth(sku.category)) IN ('MOONCAKE')), 'MOONCAKE', (upper(trimBoth(sku.category)) IN ('PALLET')), 'EQUIPMENT', (upper(trimBoth(sku.category)) IN ('POSM', 'OFFBOM')), 'POSM/OFFBOM', (upper(trimBoth(sku.category)) IN ('TEST')), 'TEST', (upper(trimBoth(sku.category)) IN ('BUN', 'BUN1', 'BUN2')), 'FRESH', (upper(trimBoth(sku.category)) IN ('FRESH')), 'FRESH', (upper(trimBoth(sku.category)) IN ('DRY')), 'DRY', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (left(sku.sku, 1) = '2'), 'PM', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (sku.sku LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (left(sku.sku, 1) != '2') AND (sku.sku NOT LIKE '%SAMPLE%'), convert_cargo.convert_skugroup, (sku.category IS NULL) AND (left(sku.sku, 2) = 'ZW'), 'POSM/OFFBOM', (sku.category IS NULL) AND (left(sku.sku, 1) = '2'), 'PM', (sku.category IS NULL) AND match(upper(sku.sku), 'BAO BI|BAOBI'), 'PM', (sku.category IS NULL) AND (sku.sku LIKE '%PL%'), 'EQUIPMENT', (sku.category IS NULL) AND (sku.sku LIKE '%PPE%'), 'EQUIPMENT', NULL) AS group_of_cargo,
    multiIf(substring(sku.sku, 1, 1) != '4', 'Other', match(upper(sku.descr), '(^| )SOLITE( |$)'), 'Solite', match(upper(sku.descr), '(^|[^A-Z0-9])AFC([^A-Z0-9]|$)'), 'AFC', match(upper(sku.descr), '(^|[^A-Z0-9])LU([^A-Z0-9]|$)'), 'Lu', match(upper(sku.descr), '(^|[^A-Z0-9])COSY([^A-Z0-9]|$)'), 'Cosy', match(upper(sku.descr), '(^|[^A-Z0-9])OREO([^A-Z0-9]|$)'), 'Oreo', match(upper(sku.descr), '(^|[^A-Z0-9])TET([^A-Z0-9]|$)'), 'Tết', match(upper(sku.descr), '(^|[^A-Z0-9])TRUNG THU([^A-Z0-9]|$)'), 'Trung Thu', match(upper(sku.descr), '(^|[^A-Z0-9])SLIDE([^A-Z0-9]|$)'), 'Slide', match(upper(sku.descr), '(^|[^A-Z0-9])(KD|KINH ĐÔ|KINH DO)([^A-Z0-9]|$)'), 'KD', match(upper(sku.descr), '(^|[^A-Z0-9])RITZ([^A-Z0-9]|$)'), 'RITZ', match(upper(sku.descr), '(^|[^A-Z0-9])TOBLERONE([^A-Z0-9]|$)'), 'Toblerone', NULL) AS brand,
    sku.std_cube AS cbm_per_masterunit,
    sku.std_grossweight AS kg_per_masterunit,
    pack.inner_pack AS masterunit_per_cse,
    pack.pallet AS masterunit_per_pallet
FROM
sku_stm
FULL OUTER JOIN swm_dwh_mondelez.dim_sku AS sku ON (sku.storer_key = 'MDLZ') AND (sku_stm.rn = 1) AND (sku_stm.item_code = sku.sku)
LEFT JOIN swm_dwh_mondelez.dim_pack AS pack ON (pack.whseid = sku.whseid) AND (pack.pack_key = sku.pack_key)
LEFT JOIN internal.convert_cargo AS convert_cargo ON (convert_cargo.whseid = 'BKD1') AND (sku.sku = convert_cargo.sku)
WHERE sku.storer_key = 'MDLZ'


-- ════════════════════════════════════════════════════
-- Object: mv_masterdata_vehicle  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_masterdata_vehicle
REFRESH EVERY 5 MINUTE
(
    `id_vehicle` Int32,
    `id_group_vehicle` Int32,
    `group_name` String,
    `code` String,
    `ton` Float64,
    `reg_no` String
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY tuple()
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = `sql-console:vy.tao@gosmartlog.com` SQL SECURITY DEFINER
AS SELECT
    CAT_Vehicle.id AS id_vehicle,
    CAT_GroupOfVehicle.id AS id_group_vehicle,
    CAT_GroupOfVehicle.group_name AS group_name,
    CAT_GroupOfVehicle.code AS code,
    CAT_GroupOfVehicle.ton AS ton,
    CAT_Vehicle.reg_no AS reg_no
FROM stm_dwh_mondelez.subdim_cat_group_of_vehicle AS CAT_GroupOfVehicle
LEFT JOIN stm_dwh_mondelez.subdim_cat_vehicle AS CAT_Vehicle ON (CAT_Vehicle.group_of_vehicle_id = CAT_GroupOfVehicle.id) AND (CAT_Vehicle.is_deleted = 0)
WHERE CAT_GroupOfVehicle.is_deleted = 0


-- ════════════════════════════════════════════════════
-- Object: mv_masterdata_vendor  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_masterdata_vendor
REFRESH EVERY 3 MINUTE
(
    `id` Int32,
    `code` String,
    `customer_name` String,
    `short_name` String
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY tuple()
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = `sql-console:vy.tao@gosmartlog.com` SQL SECURITY DEFINER
AS SELECT
    c.id AS id,
    c.code AS code,
    c.customer_name AS customer_name,
    c.short_name AS short_name
FROM stm_dwh_mondelez.subdim_cus_customer AS c
WHERE (c.type_of_customer_id = 11) AND (c.is_deleted = 0)


-- ════════════════════════════════════════════════════
-- Object: mv_mdlz_data_cat_daily  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_mdlz_data_cat_daily
REFRESH EVERY 1 HOUR
(
    `orderdate` Nullable(Date),
    `etd` Nullable(Date),
    `category` String,
    `brand` String,
    `region` LowCardinality(String),
    `total_cbm` Nullable(Float64),
    `total_qty` Nullable(Float64),
    `week_label` String,
    `day_of_month` Nullable(UInt8)
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (orderdate, category, region, brand)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    holiday_set AS
    (
        SELECT groupArray(holiday_date) AS holidays
        FROM analytics_workspace.dim_business_holidays
    ),
    base AS
    (
        SELECT
            if(toHour(toTimezone(f.actual_ship_date, 'Asia/Ho_Chi_Minh')) >= 17, toDate(toTimezone(f.actual_ship_date, 'Asia/Ho_Chi_Minh')) + 1, toDate(toTimezone(f.actual_ship_date, 'Asia/Ho_Chi_Minh'))) AS orderdate,
            multiIf(upper(coalesce(f.group_of_cago, '')) = 'DRY', 'Dry', upper(coalesce(f.group_of_cago, '')) = 'FRESH', 'Fresh', coalesce(f.group_of_cago, '')) AS category,
            coalesce(f.brand, '') AS brand,
            coalesce(r.region, '') AS region,
            toFloat64OrZero(toString(f.shipped_cbm)) AS shipped_cbm,
            toFloat64OrZero(toString(f.shipped_qty)) AS shipped_qty
        FROM analytics_workspace.mv_flrp_swm_data AS f
        LEFT JOIN analytics_workspace.dim_warehouse_region_source AS r ON r.whseid = f.whseid
        WHERE (f.actual_ship_date IS NOT NULL) AND (f.type_description IN ('XUẤT NPP EDI', 'EDI Xuất bán (tích hợp)', 'Shipment for sale', 'Xuất bán')) AND (f.group_of_cago IS NOT NULL) AND (f.brand IS NOT NULL)
    )
SELECT
    base.orderdate AS orderdate,
    arrayFirst(d -> ((toDayOfWeek(d) != 7) AND (NOT has(holiday_set.holidays, d))), arrayMap(i -> (if(toDayOfWeek(base.orderdate) = 6, base.orderdate + 2, base.orderdate + 1) + i), range(0, 8))) AS etd,
    base.category AS category,
    base.brand AS brand,
    base.region AS region,
    sum(base.shipped_cbm) AS total_cbm,
    sum(base.shipped_qty) AS total_qty,
    multiIf(toDayOfWeek(base.orderdate) = 1, '1.Monday', toDayOfWeek(base.orderdate) = 2, '2.Tuesday', toDayOfWeek(base.orderdate) = 3, '3.Wednesday', toDayOfWeek(base.orderdate) = 4, '4.Thursday', toDayOfWeek(base.orderdate) = 5, '5.Friday', toDayOfWeek(base.orderdate) = 6, '6.Saturday', '7.Sunday') AS week_label,
    toUInt8(toDayOfMonth(base.orderdate)) AS day_of_month
FROM
base
CROSS JOIN
holiday_set
GROUP BY
    orderdate,
    category,
    brand,
    region,
    holiday_set.holidays


-- ════════════════════════════════════════════════════
-- Object: mv_mdlz_fact_daily_warehouse_actual_cbm  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_mdlz_fact_daily_warehouse_actual_cbm
REFRESH EVERY 1 HOUR
(
    `etd` Nullable(Date),
    `wh_name` String,
    `work_shift` String,
    `product_type` String,
    `customergroupcode` String,
    `region` LowCardinality(String),
    `wh_type` LowCardinality(String),
    `actual_volume_cbm` Nullable(Float64),
    `ship_completed` Nullable(Float64),
    `sku_count` UInt64,
    `updated_at` DateTime
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (etd, wh_name, work_shift, product_type, customergroupcode)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH shift_lookup AS
    (
        SELECT
            wh_name,
            anyHeavy(work_shift) AS work_shift
        FROM analytics_workspace.dim_work_shift_source
        GROUP BY wh_name
    )
SELECT
    toDate(toTimezone(f.delivery_date_1, 'Asia/Ho_Chi_Minh')) AS etd,
    f.whseid AS wh_name,
    coalesce(s.work_shift, 'UNKNOWN') AS work_shift,
    multiIf(upper(coalesce(f.group_of_cago, '')) = 'DRY', 'Dry', upper(coalesce(f.group_of_cago, '')) = 'FRESH', 'Fresh', coalesce(f.group_of_cago, '')) AS product_type,
    coalesce(f.group_name, '') AS customergroupcode,
    coalesce(r.region, '') AS region,
    coalesce(r.wh_type, 'external') AS wh_type,
    sum(if(toFloat64OrZero(toString(f.shipped_cbm)) > 0, toFloat64OrZero(toString(f.shipped_cbm)), toFloat64OrZero(toString(f.original_cbm)))) AS actual_volume_cbm,
    sum(toFloat64OrZero(toString(f.shipped_cbm))) AS ship_completed,
    uniqExact(f.item_code) AS sku_count,
    now() AS updated_at
FROM analytics_workspace.mv_flrp_swm_data AS f
LEFT JOIN analytics_workspace.dim_warehouse_region_source AS r ON r.whseid = f.whseid
LEFT JOIN
shift_lookup AS s ON s.wh_name = f.whseid
WHERE (f.delivery_date_1 IS NOT NULL) AND (f.type_description IN ('XUẤT NPP EDI', 'EDI Xuất bán (tích hợp)', 'Shipment for sale', 'Xuất bán')) AND (f.group_of_cago IS NOT NULL)
GROUP BY
    etd,
    wh_name,
    work_shift,
    product_type,
    customergroupcode,
    region,
    wh_type


-- ════════════════════════════════════════════════════
-- Object: mv_movement_transaction  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_movement_transaction
REFRESH EVERY 1 HOUR
(
    `transaction_date` Nullable(DateTime64(3, 'UTC')) COMMENT 'Ngày transaction',
    `warehouse` String COMMENT 'Mã kho',
    `activity` Nullable(String) COMMENT 'Hoạt động nhập hoặc xuất',
    `category_converted` Nullable(String) COMMENT 'Loại hàng (định nghĩa MDLZ)',
    `uom` Nullable(String) COMMENT 'Đơn vị tính tiền cho activity',
    `PCE` Nullable(Float64) COMMENT 'Khối lượng xử lý,\r\n đơn vị masterunit/PCE/EA',
    `CBM` Nullable(Float64) COMMENT 'Khối lượng xử lý,\r\n đơn vị CBM',
    `Ton` Nullable(Float64) COMMENT 'Khối lượng xử lý,\r\n đơn vị TON',
    `CSE` Nullable(Float64) COMMENT 'Khối lượng xử lý,\r\n đơn vị CSE',
    `Pallet` Nullable(Float64) COMMENT 'Khối lượng xử lý,\r\n đơn vị PALLET',
    `orders` Nullable(UInt64) COMMENT 'Số đơn xử lý',
    `direction` Nullable(String) COMMENT 'Luồng nhập hoặc xuất'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (direction, transaction_date, warehouse, activity)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS SELECT
    toDateTime(transaction_date) AS transaction_date,
    warehouse,
    activity,
    category_converted,
    uom,
    toFloat64(PCE) AS PCE,
    CBM,
    Ton,
    CSE,
    Pallet,
    orders,
    direction
FROM analytics_workspace.mv_outbound_transaction_base
UNION ALL
SELECT
    toDateTime(transaction_date) AS transaction_date,
    warehouse,
    activity,
    category_converted,
    uom,
    PCE,
    CBM,
    Ton,
    CSE,
    Pallet,
    orders,
    direction
FROM analytics_workspace.mv_inbound_transaction_base
ORDER BY
    direction ASC,
    transaction_date ASC,
    warehouse ASC,
    activity ASC,
    category_converted ASC


-- ════════════════════════════════════════════════════
-- Object: mv_otif  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_otif
REFRESH EVERY 5 MINUTE
(
    `so` Nullable(String),
    `whseid` String,
    `group_of_cago` Nullable(String),
    `group_name` String,
    `customer_code` Nullable(String),
    `customer_name` String,
    `khu_vuc_doi_xe` String,
    `ten_ngan_nha_van_tai` String,
    `loai_xe_van_hanh` Nullable(String),
    `loai_xe_gui_thau` Nullable(String),
    `ma_doi_tac_nhan` String,
    `ten_doi_tac_nhan` String,
    `thoi_gian_gui_thau` Nullable(DateTime64(3, 'UTC')),
    `ngay_tao_chuyen` Nullable(DateTime64(3, 'UTC')),
    `etd_chuyen_gui_thau` Nullable(DateTime64(3, 'UTC')),
    `gio_dang_tai` Nullable(DateTime64(3, 'UTC')),
    `gio_goi_xe` Nullable(DateTime64(3, 'UTC')),
    `gio_vao_cong` Nullable(DateTime64(3, 'UTC')),
    `gio_vao_dock` Nullable(DateTime64(3, 'UTC')),
    `actual_ship_date` Nullable(DateTime64(3, 'UTC')),
    `gio_ra_dock` Nullable(DateTime64(3, 'UTC')),
    `gio_ra_cong` Nullable(DateTime64(3, 'UTC')),
    `tg_bat_buoc_roi_kho` Nullable(DateTime64(3, 'UTC')),
    `eta_giao_hang_cho_npp` Nullable(DateTime64(3, 'UTC')),
    `ata_den` Nullable(DateTime64(3, 'UTC')),
    `ata_roi` Nullable(DateTime64(3, 'UTC')),
    `id_chuyen_gui_thau` Nullable(Int32),
    `so_chuyen` Nullable(String),
    `so_xe` Nullable(String),
    `tai_xe` Nullable(String),
    `ma_nha_xe` String,
    `sum_original` Nullable(Decimal(38, 8)),
    `sum_original_cbm` Nullable(Decimal(38, 12)),
    `sum_original_kg` Nullable(Decimal(38, 12)),
    `sum_original_cse` Nullable(Decimal(38, 8)),
    `sum_original_pl` Nullable(Decimal(38, 8)),
    `sum_shipped` Nullable(Decimal(38, 8)),
    `sum_shipped_cbm` Nullable(Decimal(38, 8)),
    `sum_shipped_kg` Nullable(Decimal(38, 12)),
    `sum_shipped_cse` Nullable(Decimal(38, 8)),
    `sum_shipped_pl` Nullable(Decimal(38, 8)),
    `sum_san_luong_giao` Nullable(Decimal(38, 8)),
    `sum_san_luong_giao_cbm` Nullable(Decimal(38, 12)),
    `sum_san_luong_giao_kg` Nullable(Decimal(38, 12)),
    `sum_san_luong_giao_cse` Nullable(Decimal(38, 8)),
    `sum_san_luong_giao_pl` Nullable(Decimal(38, 8)),
    `chenh_lech_sl_giao_cho` Nullable(Decimal(38, 8)),
    `chenh_lech_sl_giao_cho_cbm` Nullable(Decimal(38, 12)),
    `chenh_lech_sl_giao_cho_kg` Nullable(Decimal(38, 12)),
    `chenh_lech_sl_giao_cho_cse` Nullable(Decimal(38, 8)),
    `chenh_lech_sl_giao_cho_pl` Nullable(Decimal(38, 8)),
    `tong_tg_trong_kho_min` Nullable(Int64),
    `tg_load_hang_min` Nullable(Int64),
    `chenh_lech_tg_thuc_te_du_kien_hour` Nullable(Int64),
    `ontime_status` Nullable(String),
    `infull_status` Nullable(String),
    `otif_status` String,
    `cse_otif` Nullable(Float64),
    `pct_otif` Nullable(Float64),
    `not_infull_reason` Nullable(String),
    `not_ontime_reason` Nullable(String),
    `delay_xe_dang_tai` Nullable(Int64),
    `delay_goi_xe` Nullable(Int64),
    `delay_vao_cong` Nullable(Int64),
    `delay_xuat_kho_tre` Nullable(Int64),
    `delay_roi_kho_tre` Nullable(Int64),
    `delay_tren_duong` Nullable(Int64),
    `ngay_duyet_chuyen` Nullable(DateTime64(3, 'UTC')),
    `ngay_gi` Nullable(DateTime64(3, 'UTC')),
    `ngay_tao_don` Nullable(DateTime64(3, 'UTC'))
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (so, whseid)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    base AS
    (
        SELECT
            t.*,
            multiIf(upperUTF8(trimBoth(ifNull(t.`Group of Cago`, ''))) = 'FRESH', 1, upperUTF8(trimBoth(ifNull(t.`Group of Cago`, ''))) = 'DRY', 2, upperUTF8(trimBoth(ifNull(t.`Group of Cago`, ''))) = 'MOONCAKE', 3, (upperUTF8(trimBoth(ifNull(t.`Group of Cago`, ''))) IN ('POSM', 'OFFBOM', 'POSM/OFFBOM')), 4, upperUTF8(trimBoth(ifNull(t.`Group of Cago`, ''))) = 'TEST', 5, upperUTF8(trimBoth(ifNull(t.`Group of Cago`, ''))) = 'EQUIPMENT', 6, upperUTF8(trimBoth(ifNull(t.`Group of Cago`, ''))) = 'PM', 7, 99) AS group_priority
        FROM analytics_workspace.mv_otif_swm_stm_data AS t
    ),
    so_pick AS
    (
        SELECT *
        FROM
        (
            SELECT
                b.*,
                row_number() OVER (PARTITION BY b.SO ORDER BY b.group_priority ASC, b.ORDERLINENUMBER ASC NULLS LAST) AS rn
            FROM
            base AS b
        ) AS x
        WHERE x.rn = 1
    ),
    so_sum AS
    (
        SELECT
            b.SO,
            sum(coalesce(b.ORIGINAL, 0)) AS sum_original,
            sum(coalesce(b.`ORIGINAL CBM`, 0)) AS sum_original_cbm,
            sum(coalesce(b.`ORIGINAL KG`, 0)) AS sum_original_kg,
            sum(coalesce(b.`ORIGINAL CSE`, 0)) AS sum_original_cse,
            sum(coalesce(b.`ORIGINAL PL`, 0)) AS sum_original_pl,
            sum(coalesce(b.SHIPPED, 0)) AS sum_shipped,
            sum(coalesce(b.`SHIPPED CBM`, 0)) AS sum_shipped_cbm,
            sum(coalesce(b.`SHIPPED KG`, 0)) AS sum_shipped_kg,
            sum(coalesce(b.`SHIPPED CSE`, 0)) AS sum_shipped_cse,
            sum(coalesce(b.`SHIPPED PL`, 0)) AS sum_shipped_pl,
            sum(b.`Sản lượng giao`) AS sum_giao,
            sum(b.`Sản lượng giao CBM`) AS sum_giao_cbm,
            sum(b.`Sản lượng giao KG`) AS sum_giao_kg,
            sum(b.`Sản lượng giao CSE`) AS sum_giao_cse,
            sum(b.`Sản lượng giao PL`) AS sum_giao_pl,
            max(b.has_stm_line) AS has_stm_order,
            minIf(b.`ETA (Giao hàng cho NPP)`, b.has_stm_line = 1) AS `ETA (Giao hàng cho NPP)`,
            maxIf(b.`ATA rời`, b.has_stm_line = 1) AS `ATA rời`,
            maxIf(b.`ATA đến`, b.has_stm_line = 1) AS `ATA đến`,
            maxIf(b.`Thời gian gửi thầu`, b.has_stm_line = 1) AS `Thời gian gửi thầu`,
            maxIf(b.`Ngày tạo chuyến`, b.has_stm_line = 1) AS `Ngày tạo chuyến`,
            maxIf(b.`ETD chuyến gửi thầu`, b.has_stm_line = 1) AS `ETD chuyến gửi thầu`,
            maxIf(b.`Giờ đăng tài`, b.has_stm_line = 1) AS `Giờ đăng tài`,
            maxIf(b.`Giờ gọi xe`, b.has_stm_line = 1) AS `Giờ gọi xe`,
            maxIf(b.`Giờ vào cổng`, b.has_stm_line = 1) AS `Giờ vào cổng`,
            maxIf(b.`Giờ vào dock`, b.has_stm_line = 1) AS `Giờ vào dock`,
            maxIf(b.`Actual Ship Date`, b.has_stm_line = 1) AS `Actual Ship Date`,
            maxIf(b.`Giờ ra dock`, b.has_stm_line = 1) AS `Giờ ra dock`,
            maxIf(b.`Giờ ra cổng`, b.has_stm_line = 1) AS `Giờ ra cổng`,
            maxIf(b.`TG bắt buộc rời kho`, b.has_stm_line = 1) AS `TG bắt buộc rời kho`
        FROM
        base AS b
        GROUP BY b.SO
    )
SELECT
    s.SO AS so,
    p.whseid AS whseid,
    p.`Group of Cago` AS group_of_cago,
    p.Group AS group_name,
    p.`Customer Code` AS customer_code,
    p.`Customer Name` AS customer_name,
    p.`Khu vực đội xe` AS khu_vuc_doi_xe,
    p.`Tên ngắn nhà vận tải` AS ten_ngan_nha_van_tai,
    p.`Loại xe vận hành` AS loai_xe_van_hanh,
    p.`Loại xe gửi thầu` AS loai_xe_gui_thau,
    p.`Mã đối tác nhận` AS ma_doi_tac_nhan,
    p.`Tên đối tác nhận` AS ten_doi_tac_nhan,
    s.`Thời gian gửi thầu` AS thoi_gian_gui_thau,
    s.`Ngày tạo chuyến` AS ngay_tao_chuyen,
    s.`ETD chuyến gửi thầu` AS etd_chuyen_gui_thau,
    s.`Giờ đăng tài` AS gio_dang_tai,
    s.`Giờ gọi xe` AS gio_goi_xe,
    s.`Giờ vào cổng` AS gio_vao_cong,
    s.`Giờ vào dock` AS gio_vao_dock,
    s.`Actual Ship Date` AS actual_ship_date,
    s.`Giờ ra dock` AS gio_ra_dock,
    s.`Giờ ra cổng` AS gio_ra_cong,
    s.`TG bắt buộc rời kho` AS tg_bat_buoc_roi_kho,
    s.`ETA (Giao hàng cho NPP)` AS eta_giao_hang_cho_npp,
    s.`ATA đến` AS ata_den,
    s.`ATA rời` AS ata_roi,
    p.`ID chuyến gửi thầu` AS id_chuyen_gui_thau,
    p.`Số chuyến` AS so_chuyen,
    p.`Số xe` AS so_xe,
    p.`Tài xế` AS tai_xe,
    p.`Mã nhà xe` AS ma_nha_xe,
    s.sum_original AS sum_original,
    s.sum_original_cbm AS sum_original_cbm,
    s.sum_original_kg AS sum_original_kg,
    s.sum_original_cse AS sum_original_cse,
    s.sum_original_pl AS sum_original_pl,
    s.sum_shipped AS sum_shipped,
    s.sum_shipped_cbm AS sum_shipped_cbm,
    s.sum_shipped_kg AS sum_shipped_kg,
    s.sum_shipped_cse AS sum_shipped_cse,
    s.sum_shipped_pl AS sum_shipped_pl,
    s.sum_giao AS sum_san_luong_giao,
    s.sum_giao_cbm AS sum_san_luong_giao_cbm,
    s.sum_giao_kg AS sum_san_luong_giao_kg,
    s.sum_giao_cse AS sum_san_luong_giao_cse,
    s.sum_giao_pl AS sum_san_luong_giao_pl,
    s.sum_shipped - s.sum_giao AS chenh_lech_sl_giao_cho,
    s.sum_shipped_cbm - s.sum_giao_cbm AS chenh_lech_sl_giao_cho_cbm,
    s.sum_shipped_kg - s.sum_giao_kg AS chenh_lech_sl_giao_cho_kg,
    s.sum_shipped_cse - s.sum_giao_cse AS chenh_lech_sl_giao_cho_cse,
    s.sum_shipped_pl - s.sum_giao_pl AS chenh_lech_sl_giao_cho_pl,
    dateDiff('minute', p.`Giờ vào cổng`, p.`Giờ ra cổng`) AS tong_tg_trong_kho_min,
    dateDiff('minute', p.`ATA đến`, p.`ATA rời`) AS tg_load_hang_min,
    dateDiff('hour', p.`ETA (Giao hàng cho NPP)`, p.`ATA đến`) AS chenh_lech_tg_thuc_te_du_kien_hour,
    multiIf((p.`ETA (Giao hàng cho NPP)` IS NOT NULL) AND (p.`ATA đến` IS NOT NULL) AND (dateDiff('minute', p.`ETA (Giao hàng cho NPP)`, p.`ATA đến`) > 30), 'Failed Ontime', (p.`ETA (Giao hàng cho NPP)` IS NOT NULL) AND (p.`ATA đến` IS NOT NULL) AND (dateDiff('minute', p.`ETA (Giao hàng cho NPP)`, p.`ATA đến`) <= 30), 'Ontime', coalesce(s.has_stm_order, 0) = 0, 'Không có dữ liệu STM', NULL) AS ontime_status,
    multiIf(coalesce(s.has_stm_order, 0) = 0, 'Không có dữ liệu STM', (round(toFloat64(s.sum_original_cse), 4) > round(toFloat64(s.sum_shipped_cse), 4)) OR (round(toFloat64(s.sum_shipped_cse), 4) > round(toFloat64(s.sum_giao_cse), 4)), 'Failed Infull', (round(toFloat64(s.sum_original_cse), 4) = round(toFloat64(s.sum_shipped_cse), 4)) AND (round(toFloat64(s.sum_shipped_cse), 4) = round(toFloat64(s.sum_giao_cse), 4)), 'Infull', NULL) AS infull_status,
    multiIf((if(p.`ETA (Giao hàng cho NPP)` < p.`ATA đến`, 0, if(p.`ETA (Giao hàng cho NPP)` >= p.`ATA đến`, 1, NULL)) = 1) AND (if((s.sum_original_cse > s.sum_shipped_cse) OR (s.sum_shipped_cse > s.sum_giao_cse), 0, if((s.sum_original_cse = s.sum_shipped_cse) AND (s.sum_shipped_cse = s.sum_giao_cse), 1, NULL)) = 1), 'OTIF', coalesce(s.has_stm_order, 0) = 0, 'Không có dữ liệu STM', 'Failed OTIF') AS otif_status,
    multiIf((p.`ETA (Giao hàng cho NPP)` IS NULL) OR (p.`ATA đến` IS NULL), NULL, p.`ETA (Giao hàng cho NPP)` < p.`ATA đến`, toFloat64(0), toFloat64(s.sum_giao_cse)) AS cse_otif,
    if(coalesce(s.sum_original_cse, 0) = 0, NULL, multiIf((p.`ETA (Giao hàng cho NPP)` IS NULL) OR (p.`ATA đến` IS NULL), NULL, p.`ETA (Giao hàng cho NPP)` < p.`ATA đến`, toFloat64(0), toFloat64(s.sum_giao_cse)) / toFloat64(s.sum_original_cse)) AS pct_otif,
    multiIf(coalesce(s.has_stm_order, 0) = 0, 'Không có dữ liệu STM', (round(toFloat64(s.sum_original_cse), 4) > round(toFloat64(s.sum_shipped_cse), 4)) AND (round(toFloat64(s.sum_shipped_cse), 4) > round(toFloat64(s.sum_giao_cse), 4)), 'Warehouse + Transport Infull Failure', (round(toFloat64(s.sum_original_cse), 4) > round(toFloat64(s.sum_shipped_cse), 4)) AND (round(toFloat64(s.sum_shipped_cse), 4) = round(toFloat64(s.sum_giao_cse), 4)), 'Warehouse Infull Failure', (round(toFloat64(s.sum_original_cse), 4) = round(toFloat64(s.sum_shipped_cse), 4)) AND (round(toFloat64(s.sum_shipped_cse), 4) > round(toFloat64(s.sum_giao_cse), 4)), 'Transport Infull Failure', (round(toFloat64(s.sum_original_cse), 4) = round(toFloat64(s.sum_shipped_cse), 4)) AND (round(toFloat64(s.sum_shipped_cse), 4) = round(toFloat64(s.sum_giao_cse), 4)), NULL, round(toFloat64(s.sum_original_cse), 4) > round(toFloat64(s.sum_shipped_cse), 4), 'Warehouse Infull Failure', NULL) AS not_infull_reason,
    if(p.`ETA (Giao hàng cho NPP)` < p.`ATA đến`, coalesce(nullIf(replaceRegexpAll(concatWithSeparator('', if((toStartOfMinute(toDateTime64(p.`Giờ gọi xe`, 3)) < toStartOfMinute(toDateTime64(p.`ETD chuyến gửi thầu`, 3))) AND (toStartOfMinute(toDateTime64(p.`ETD chuyến gửi thầu`, 3)) < toStartOfMinute(toDateTime64(p.`Giờ vào cổng`, 3))), 'Late arrival by Transport', ''), if(toStartOfMinute(toDateTime64(p.`ETD chuyến gửi thầu`, 3)) < toStartOfMinute(toDateTime64(p.`Giờ đăng tài`, 3)), ',\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n Late arrival by Transport', ''), if((toStartOfMinute(toDateTime64(p.`Giờ đăng tài`, 3)) < toStartOfMinute(toDateTime64(p.`ETD chuyến gửi thầu`, 3))) AND (toStartOfMinute(toDateTime64(p.`Giờ gọi xe`, 3)) > toStartOfMinute(toDateTime64(p.`ETD chuyến gửi thầu`, 3))), ',\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n Late warehouse call by Warehouse', ''), if((toStartOfMinute(toDateTime64(p.`ETD chuyến gửi thầu`, 3)) > toStartOfMinute(toDateTime64(p.`Giờ vào cổng`, 3))) AND (toDateTime64(p.`Actual Ship Date`, 3) > subtractMinutes(toDateTime64(p.`TG bắt buộc rời kho`, 3), 10)), ',\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n Late pickup by Warehouse', ''), if((toStartOfMinute(toDateTime64(p.`ETD chuyến gửi thầu`, 3)) > toStartOfMinute(toDateTime64(p.`Giờ vào cổng`, 3))) AND (toDateTime64(p.`Actual Ship Date`, 3) < subtractMinutes(toDateTime64(p.`TG bắt buộc rời kho`, 3), 10)) AND (toDateTime64(p.`TG bắt buộc rời kho`, 3) < toStartOfMinute(toDateTime64(p.`Giờ ra cổng`, 3))), ',\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n Late departure by Transport', ''), if((toStartOfMinute(toDateTime64(p.`ETD chuyến gửi thầu`, 3)) > toStartOfMinute(toDateTime64(p.`Giờ vào cổng`, 3))) AND (toDateTime64(p.`Actual Ship Date`, 3) < subtractMinutes(toDateTime64(p.`TG bắt buộc rời kho`, 3), 10)) AND (toDateTime64(p.`TG bắt buộc rời kho`, 3) > toStartOfMinute(toDateTime64(p.`Giờ ra cổng`, 3))) AND (p.`ETA (Giao hàng cho NPP)` < p.`ATA đến`), ',\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n Late delivery by Transport', '')), '^[,\r\n\r\n\r\n\r\n\r\n\r\n ]+|[,\r\n\r\n\r\n\r\n\r\n\r\n ]+$', ''), ''), 'Thiếu dữ liệu đăng ký dock'), NULL) AS not_ontime_reason,
    if(p.`ETA (Giao hàng cho NPP)` < p.`ATA đến`, if(dateDiff('minute', p.`ETD chuyến gửi thầu`, p.`Giờ đăng tài`) > 0, dateDiff('minute', p.`ETD chuyến gửi thầu`, p.`Giờ đăng tài`), NULL), NULL) AS delay_xe_dang_tai,
    if(p.`ETA (Giao hàng cho NPP)` < p.`ATA đến`, if(dateDiff('minute', p.`ETD chuyến gửi thầu`, p.`Giờ gọi xe`) > 0, dateDiff('minute', p.`ETD chuyến gửi thầu`, p.`Giờ gọi xe`), NULL), NULL) AS delay_goi_xe,
    if(p.`ETA (Giao hàng cho NPP)` < p.`ATA đến`, if(dateDiff('minute', p.`ETD chuyến gửi thầu`, p.`Giờ vào cổng`) > 0, dateDiff('minute', p.`ETD chuyến gửi thầu`, p.`Giờ vào cổng`), NULL), NULL) AS delay_vao_cong,
    if(p.`ETA (Giao hàng cho NPP)` < p.`ATA đến`, if(dateDiff('minute', subtractMinutes(toDateTime64(p.`TG bắt buộc rời kho`, 3), 10), toDateTime64(p.`Actual Ship Date`, 3)) > 0, dateDiff('minute', subtractMinutes(toDateTime64(p.`TG bắt buộc rời kho`, 3), 10), toDateTime64(p.`Actual Ship Date`, 3)), NULL), NULL) AS delay_xuat_kho_tre,
    if(p.`ETA (Giao hàng cho NPP)` < p.`ATA đến`, if(dateDiff('minute', p.`TG bắt buộc rời kho`, p.`Giờ ra cổng`) > 0, dateDiff('minute', p.`TG bắt buộc rời kho`, p.`Giờ ra cổng`), NULL), NULL) AS delay_roi_kho_tre,
    if(p.`ETA (Giao hàng cho NPP)` < p.`ATA đến`, if(dateDiff('minute', p.`ETA (Giao hàng cho NPP)`, p.`ATA rời`) > 0, dateDiff('minute', p.`ETA (Giao hàng cho NPP)`, p.`ATA rời`), NULL), NULL) AS delay_tren_duong,
    p.`Ngày duyệt chuyến` AS ngay_duyet_chuyen,
    p.`Delivery Date 1` AS ngay_gi,
    coalesce(p.`Ngày tạo đơn`, ordm_direct.created_date) AS ngay_tao_don
FROM
so_sum AS s
LEFT JOIN
so_pick AS p ON s.SO = p.SO
LEFT JOIN stm_dwh_mondelez.dim_ord_order AS ordm_direct ON (s.SO = ordm_direct.code) AND (ifNull(toUInt8(ordm_direct.is_deleted), 0) = 0)


-- ════════════════════════════════════════════════════
-- Object: mv_otif_stm_data  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_otif_stm_data
REFRESH EVERY 5 MINUTE
(
    `ID_ORD_GroupProduct` Int32,
    `Mã đơn hàng` Nullable(String),
    `LineNo` String,
    `QuantityBBGN` Decimal(22, 8),
    `Thời gian gửi thầu` Nullable(DateTime64(3, 'UTC')),
    `ETA (Giao hàng cho NPP)` Nullable(DateTime64(3, 'UTC')),
    `ATA đến` Nullable(DateTime64(3, 'UTC')),
    `ATA rời` Nullable(DateTime64(3, 'UTC')),
    `ID chuyến gửi thầu` Nullable(Int32),
    `Tên ngắn nhà vận tải` String,
    `Mã nhà xe` String,
    `Loại xe vận hành` Nullable(String),
    `Loại xe gửi thầu` Nullable(String),
    `Ngày tạo chuyến` Nullable(DateTime64(3, 'UTC')),
    `ETD chuyến gửi thầu` Nullable(DateTime64(3, 'UTC')),
    `Giờ đăng tài` Nullable(DateTime64(3, 'UTC')),
    `Giờ gọi xe` Nullable(DateTime64(3, 'UTC')),
    `Giờ vào cổng` Nullable(DateTime64(3, 'UTC')),
    `Giờ vào dock` Nullable(DateTime64(3, 'UTC')),
    `TG bắt buộc rời kho` Nullable(DateTime64(3, 'UTC')),
    `Giờ ra dock` Nullable(DateTime64(3, 'UTC')),
    `Giờ ra cổng` Nullable(DateTime64(3, 'UTC')),
    `Số chuyến` Nullable(String),
    `Số xe` Nullable(String),
    `Tài xế` Nullable(String),
    `Ngày duyệt chuyến` Nullable(DateTime64(3, 'UTC')),
    `Ngày tạo đơn` Nullable(DateTime64(3, 'UTC')),
    `productCode` Nullable(String),
    `Note1` Nullable(String),
    `ExpiryDate` Nullable(DateTime64(3, 'UTC'))
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (`Mã đơn hàng`, LineNo)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS SELECT
    opg.id AS ID_ORD_GroupProduct,
    ordm.code AS `Mã đơn hàng`,
    leftUTF8(ifNull(opg.code_sync, ''), greatest(lengthUTF8(ifNull(opg.code_sync, '')) - 1, 0)) AS LineNo,
    dtd.quantity_bbgn AS QuantityBBGN,
    if((dtd.tender_date IS NULL) OR (toDate(toDateTime64(dtd.tender_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.tender_date, 3, 'UTC')) AS `Thời gian gửi thầu`,
    if((dtd.eta IS NULL) OR (toDate(toDateTime64(dtd.eta, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.eta, 3, 'UTC')) AS `ETA (Giao hàng cho NPP)`,
    if((dtd.date_to_come IS NULL) OR (toDate(toDateTime64(dtd.date_to_come, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.date_to_come, 3, 'UTC')) AS `ATA đến`,
    if((dtd.date_to_leave IS NULL) OR (toDate(toDateTime64(dtd.date_to_leave, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.date_to_leave, 3, 'UTC')) AS `ATA rời`,
    dtd.trip_tender_id AS `ID chuyến gửi thầu`,
    vendor.short_name AS `Tên ngắn nhà vận tải`,
    vendor.code AS `Mã nhà xe`,
    lxvh.group_name AS `Loại xe vận hành`,
    lxgt.group_name AS `Loại xe gửi thầu`,
    if((trip.created_date IS NULL) OR (toDate(toDateTime64(trip.created_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(trip.created_date, 3, 'UTC')) AS `Ngày tạo chuyến`,
    if((tender.etd IS NULL) OR (toDate(toDateTime64(tender.etd, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(tender.etd, 3, 'UTC')) AS `ETD chuyến gửi thầu`,
    if((dock.register_date IS NULL) OR (toDate(toDateTime64(dock.register_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dock.register_date, 3, 'UTC')) AS `Giờ đăng tài`,
    if((dock.called_date IS NULL) OR (toDate(toDateTime64(dock.called_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dock.called_date, 3, 'UTC')) AS `Giờ gọi xe`,
    if((dock.gate_in IS NULL) OR (toDate(toDateTime64(dock.gate_in, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dock.gate_in, 3, 'UTC')) AS `Giờ vào cổng`,
    if((dock.loading_start IS NULL) OR (toDate(toDateTime64(dock.loading_start, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dock.loading_start, 3, 'UTC')) AS `Giờ vào dock`,
    if((dtd.date_to_load_end IS NULL) OR (toDate(toDateTime64(dtd.date_to_load_end, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.date_to_load_end, 3, 'UTC')) AS `TG bắt buộc rời kho`,
    if((dock.loading_end IS NULL) OR (toDate(toDateTime64(dock.loading_end, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dock.loading_end, 3, 'UTC')) AS `Giờ ra dock`,
    if((dock.gate_out IS NULL) OR (toDate(toDateTime64(dock.gate_out, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dock.gate_out, 3, 'UTC')) AS `Giờ ra cổng`,
    trip.code AS `Số chuyến`,
    trip.reg_no AS `Số xe`,
    trip.driver_name1 AS `Tài xế`,
    if((trip.approved_date IS NULL) OR (toDate(toDateTime64(trip.approved_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(trip.approved_date, 3, 'UTC')) AS `Ngày duyệt chuyến`,
    if((ordm.created_date IS NULL) OR (toDate(toDateTime64(ordm.created_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(ordm.created_date, 3, 'UTC')) AS `Ngày tạo đơn`,
    sub_prod.code AS productCode,
    dtd.note1 AS Note1,
    if((dtd.expiry_date IS NULL) OR (toDate(toDateTime64(dtd.expiry_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(dtd.expiry_date, 3, 'UTC')) AS ExpiryDate
FROM stm_dwh_mondelez.dim_ord_order AS ordm
LEFT JOIN stm_dwh_mondelez.dim_ord_product_group AS opg ON opg.order_id = ordm.id
LEFT JOIN analytics_workspace.mv_masterdata_location AS masterdata_locationfrom ON opg.location_from_id = masterdata_locationfrom.id_cus
LEFT JOIN stm_dwh_mondelez.dim_ops_trip_detail AS dtd ON (dtd.order_group_product_id = opg.id) AND (ifNull(toUInt8(dtd.is_deleted), 0) = 0)
LEFT JOIN stm_dwh_mondelez.dim_ops_trip AS trip ON dtd.trip_header_id = trip.id
LEFT JOIN analytics_workspace.mv_masterdata_vendor AS vendor ON trip.vendor_id = vendor.id
LEFT JOIN stm_dwh_mondelez.subdim_cat_vehicle AS vh ON (trip.vehicle_id = vh.id) AND (ifNull(toUInt8(vh.is_deleted), 0) = 0)
LEFT JOIN stm_dwh_mondelez.subdim_cat_group_of_vehicle AS lxvh ON (vh.group_of_vehicle_id = lxvh.id) AND (ifNull(toUInt8(lxvh.is_deleted), 0) = 0)
LEFT JOIN
(
    SELECT
        dito_master_id,
        argMin(register_date, NULL) AS register_date,
        argMin(called_date, NULL) AS called_date,
        argMin(gate_in, NULL) AS gate_in,
        argMin(loading_start, NULL) AS loading_start,
        argMin(loading_end, NULL) AS loading_end,
        argMin(gate_out, NULL) AS gate_out
    FROM stm_dwh_mondelez.dim_ops_dock_register
    WHERE ifNull(toUInt8(is_deleted), 0) = 0
    GROUP BY dito_master_id
) AS dock ON dock.dito_master_id = trip.id
LEFT JOIN stm_dwh_mondelez.dim_ops_trip AS tender ON dtd.trip_tender_id = tender.id
LEFT JOIN stm_dwh_mondelez.subdim_cat_group_of_vehicle AS lxgt ON (tender.tender_group_vehicle_sk = lxgt.id) AND (ifNull(toUInt8(lxgt.is_deleted), 0) = 0)
LEFT JOIN stm_dwh_mondelez.dim_ord_product AS ord_prod ON (ord_prod.group_product_id = opg.id) AND (ifNull(toUInt8(ord_prod.is_deleted), 0) = 0)
LEFT JOIN stm_dwh_mondelez.subdim_cus_product AS sub_prod ON (sub_prod.key_sk = ord_prod.subcus_product_sk) AND (ifNull(toUInt8(sub_prod.is_deleted), 0) = 0)
WHERE (ordm.service_name = 'Xuất bán') AND (ordm.status_of_order_id IN (62, 63, 64)) AND (ordm.customer_id = 9) AND (ifNull(toUInt8(ordm.is_deleted), 0) = 0) AND (ifNull(toUInt8(opg.is_deleted), 0) = 0) AND (opg.order_id IS NOT NULL) AND (opg.code_sync IS NOT NULL) AND (opg.code_sync != '') AND (ifNull(toUInt8(dtd.is_deleted), 0) = 0) AND ((toString(dtd.sort_order) = '1') OR (dtd.sort_order = '-1')) AND (ifNull(toUInt8(trip.is_deleted), 0) = 0) AND (ifNull(toUInt8(tender.is_deleted), 0) = 0)


-- ════════════════════════════════════════════════════
-- Object: mv_otif_swm_data  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_otif_swm_data
REFRESH EVERY 5 MINUTE
(
    `whseid` String,
    `WHSEID_stm` String,
    `orderkey` String,
    `SO` Nullable(String),
    `ORDERLINENUMBER` Nullable(String),
    `TYPE` LowCardinality(Nullable(String)),
    `Type Description` String,
    `Item Code` Nullable(String),
    `UOM` Nullable(String),
    `Group of Cago` Nullable(String),
    `Group` String,
    `Customer Code` Nullable(String),
    `Customer Name` String,
    `ORIGINAL` Nullable(Decimal(22, 8)),
    `ORIGINAL CBM` Nullable(Decimal(38, 12)),
    `ORIGINAL KG` Nullable(Decimal(38, 12)),
    `ORIGINAL CSE` Nullable(Decimal(38, 8)),
    `ORIGINAL PL` Nullable(Decimal(38, 8)),
    `Delivery Date 1` Nullable(DateTime64(3, 'UTC')),
    `Actual Ship Date` Nullable(DateTime64(3, 'UTC')),
    `SHIPPED` Nullable(Decimal(38, 8)),
    `SHIPPED CBM` Nullable(Decimal(38, 12)),
    `SHIPPED KG` Nullable(Decimal(38, 12)),
    `SHIPPED CSE` Nullable(Decimal(38, 8)),
    `SHIPPED PL` Nullable(Decimal(38, 8)),
    `lottable01` Nullable(String),
    `lottable05` Nullable(DateTime64(3, 'UTC'))
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (whseid, orderkey, ORDERLINENUMBER)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH group_pickdetail AS
    (
        SELECT
            storer_key,
            whseid,
            order_key,
            order_line_number,
            lot,
            sku,
            sum(qty) AS shipped
        FROM swm_dwh_mondelez.dim_pickdetail
        WHERE (storer_key = 'MDLZ') AND (whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (is_deleted = 0)
        GROUP BY
            storer_key,
            whseid,
            order_key,
            order_line_number,
            lot,
            sku
    )
SELECT
    orderdetail.whseid AS whseid,
    if((orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3')), 'BKD', orderdetail.whseid) AS WHSEID_stm,
    orders.order_key AS orderkey,
    multiIf(orders.status_code = '95', orders.extern_order_key, orders.status_code = '1', replaceRegexpOne(orders.extern_order_key, '-SP[0-9]+$', ''), NULL) AS SO,
    multiIf(orders.status_code = '95', toString(orderdetail.order_line_number), orders.status_code = '1', concat(toString(orderdetail.order_line_number), '-', extract(orders.extern_order_key, 'SP[0-9]+$')), NULL) AS ORDERLINENUMBER,
    orders.type AS TYPE,
    masterdata_ordertype.description AS `Type Description`,
    orderdetail.sku AS `Item Code`,
    orderdetail.uom AS UOM,
    masterdata_sku.group_of_cargo AS `Group of Cago`,
    masterdata_location.channel AS Group,
    orders.consignee_key AS `Customer Code`,
    masterdata_location.cus_location_name AS `Customer Name`,
    orderdetail.original_qty AS ORIGINAL,
    orderdetail.original_qty * masterdata_sku.cbm_per_masterunit AS `ORIGINAL CBM`,
    orderdetail.original_qty * masterdata_sku.kg_per_masterunit AS `ORIGINAL KG`,
    orderdetail.original_qty / nullIf(masterdata_sku.masterunit_per_cse, 0) AS `ORIGINAL CSE`,
    orderdetail.original_qty / nullIf(masterdata_sku.masterunit_per_pallet, 0) AS `ORIGINAL PL`,
    if((orders.delivery_date IS NULL) OR (toDate(toDateTime64(orders.delivery_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(orders.delivery_date, 3, 'UTC')) AS `Delivery Date 1`,
    if((orders.actual_ship_date IS NULL) OR (toDate(toDateTime64(orders.actual_ship_date, 3, 'UTC')) = toDate('1970-01-01')), NULL, toDateTime64(orders.actual_ship_date, 3, 'UTC')) AS `Actual Ship Date`,
    group_pickdetail.shipped AS SHIPPED,
    group_pickdetail.shipped * masterdata_sku.cbm_per_masterunit AS `SHIPPED CBM`,
    group_pickdetail.shipped * masterdata_sku.kg_per_masterunit AS `SHIPPED KG`,
    group_pickdetail.shipped / nullIf(masterdata_sku.masterunit_per_cse, 0) AS `SHIPPED CSE`,
    group_pickdetail.shipped / nullIf(masterdata_sku.masterunit_per_pallet, 0) AS `SHIPPED PL`,
    lotattr.lottable01 AS lottable01,
    lotattr.lottable05 AS lottable05
FROM swm_dwh_mondelez.dim_orderdetail AS orderdetail
LEFT JOIN analytics_workspace.mv_masterdata_sku AS masterdata_sku ON (toString(orderdetail.sku) = toString(masterdata_sku.item_code)) AND (toString(orderdetail.whseid) = toString(masterdata_sku.whseid))
LEFT JOIN swm_dwh_mondelez.dim_orders AS orders ON (orderdetail.storer_key = orders.storer_key) AND (orderdetail.whseid = orders.whseid) AND (orderdetail.order_key = orders.order_key)
LEFT JOIN analytics_workspace.mv_masterdata_location AS masterdata_location ON toString(orders.consignee_key) = toString(masterdata_location.cus_location_code)
LEFT JOIN
group_pickdetail ON (orderdetail.storer_key = group_pickdetail.storer_key) AND (orderdetail.whseid = group_pickdetail.whseid) AND (orderdetail.order_key = group_pickdetail.order_key) AND (orderdetail.order_line_number = group_pickdetail.order_line_number)
LEFT JOIN swm_dwh_mondelez.dim_lotattribute AS lotattr ON (group_pickdetail.whseid = lotattr.whseid) AND (group_pickdetail.storer_key = lotattr.storer_key) AND (group_pickdetail.sku = lotattr.sku) AND (group_pickdetail.lot = lotattr.lot) AND (lotattr.is_deleted = 0)
LEFT JOIN analytics_workspace.mv_masterdata_ordertype AS masterdata_ordertype ON (toString(orders.whseid) = toString(masterdata_ordertype.whseid)) AND (toString(orders.type) = toString(masterdata_ordertype.code))
WHERE (orderdetail.storer_key = 'MDLZ') AND (orderdetail.order_key IS NOT NULL) AND (orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (orders.extern_order_key IS NOT NULL) AND (((orderdetail.whseid = 'NKD') AND (orders.type IN ('01', '07', '08', '09', '240', 'XB2BMC', 'XTNPP'))) OR ((orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (orders.type IN ('01', '240'))) OR ((orderdetail.whseid IN ('VN821', 'VN831')) AND (orders.type IN ('01', '240')))) AND (orders.status_code IN ('95', '1')) AND (orderdetail.is_deleted = 0) AND (orders.is_deleted = 0)


-- ════════════════════════════════════════════════════
-- Object: mv_otif_swm_stm_data  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_otif_swm_stm_data
REFRESH EVERY 5 MINUTE
(
    `whseid` String,
    `WHSEID_stm` String,
    `orderkey` String,
    `SO` Nullable(String),
    `ORDERLINENUMBER` String,
    `TYPE` LowCardinality(Nullable(String)),
    `Type Description` String,
    `Item Code` Nullable(String),
    `UOM` Nullable(String),
    `Group of Cago` Nullable(String),
    `Group` String,
    `Customer Code` Nullable(String),
    `Customer Name` String,
    `ORIGINAL` Nullable(Decimal(22, 8)),
    `ORIGINAL CBM` Nullable(Decimal(38, 12)),
    `ORIGINAL KG` Nullable(Decimal(38, 12)),
    `ORIGINAL CSE` Nullable(Decimal(38, 8)),
    `ORIGINAL PL` Nullable(Decimal(38, 8)),
    `Delivery Date 1` Nullable(DateTime64(3, 'UTC')),
    `Actual Ship Date` Nullable(DateTime64(3, 'UTC')),
    `SHIPPED` Nullable(Decimal(38, 8)),
    `SHIPPED CBM` Nullable(Decimal(38, 12)),
    `SHIPPED KG` Nullable(Decimal(38, 12)),
    `SHIPPED CSE` Nullable(Decimal(38, 8)),
    `SHIPPED PL` Nullable(Decimal(38, 8)),
    `ID_ORD_GroupProduct` Int32,
    `Mã đơn hàng` Nullable(String),
    `LineNo` String,
    `QuantityBBGN` Nullable(Float32),
    `Thời gian gửi thầu` Nullable(DateTime64(3, 'UTC')),
    `ETA (Giao hàng cho NPP)` Nullable(DateTime64(3, 'UTC')),
    `ATA đến` Nullable(DateTime64(3, 'UTC')),
    `ATA rời` Nullable(DateTime64(3, 'UTC')),
    `ID chuyến gửi thầu` Nullable(Int32),
    `Tên ngắn nhà vận tải` String,
    `Mã nhà xe` String,
    `Loại xe vận hành` Nullable(String),
    `Loại xe gửi thầu` Nullable(String),
    `Ngày tạo chuyến` Nullable(DateTime64(3, 'UTC')),
    `ETD chuyến gửi thầu` Nullable(DateTime64(3, 'UTC')),
    `Giờ đăng tài` Nullable(DateTime64(3, 'UTC')),
    `Giờ gọi xe` Nullable(DateTime64(3, 'UTC')),
    `Giờ vào cổng` Nullable(DateTime64(3, 'UTC')),
    `Giờ vào dock` Nullable(DateTime64(3, 'UTC')),
    `TG bắt buộc rời kho` Nullable(DateTime64(3, 'UTC')),
    `Giờ ra dock` Nullable(DateTime64(3, 'UTC')),
    `Giờ ra cổng` Nullable(DateTime64(3, 'UTC')),
    `Số chuyến` Nullable(String),
    `Số xe` Nullable(String),
    `Tài xế` Nullable(String),
    `Ngày duyệt chuyến` Nullable(DateTime64(3, 'UTC')),
    `Ngày tạo đơn` Nullable(DateTime64(3, 'UTC')),
    `Mã đối tác nhận` String,
    `Tên đối tác nhận` String,
    `Khu vực đội xe` String,
    `Sản lượng giao CSE1` Nullable(Decimal(18, 4)),
    `Sản lượng giao1` Nullable(Decimal(18, 4)),
    `Sản lượng giao PL1` Nullable(Decimal(18, 4)),
    `has_stm_line` Int8,
    `Sản lượng giao` Nullable(Decimal(38, 8)),
    `Sản lượng giao CSE` Nullable(Decimal(38, 8)),
    `Sản lượng giao CBM` Nullable(Decimal(38, 12)),
    `Sản lượng giao KG` Nullable(Decimal(38, 12)),
    `Sản lượng giao PL` Nullable(Decimal(38, 8)),
    `lottable01` Nullable(String),
    `lottable05` Nullable(DateTime64(3, 'UTC')),
    `productCode` Nullable(String),
    `Note1` Nullable(String),
    `ExpiryDate` Nullable(DateTime64(3, 'UTC'))
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (SO, ORDERLINENUMBER)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    stm_deduped AS
    (
        SELECT *
        FROM
        (
            SELECT
                *,
                row_number() OVER (PARTITION BY `Mã đơn hàng`, LineNo, productCode ORDER BY (Note1 IS NOT NULL) AND (Note1 != '') DESC, ExpiryDate IS NOT NULL DESC, QuantityBBGN DESC) AS _rn
            FROM analytics_workspace.mv_otif_stm_data
        )
        WHERE _rn = 1
    ),
    swm_stm_enrich AS
    (
        SELECT
            swm_data.*,
            stm_data.*,
            masterdata_locationfrom.cus_location_code AS `Mã đối tác nhận`,
            masterdata_locationfrom.cus_location_name AS `Tên đối tác nhận`,
            masterdata_locationto.group_area_name AS `Khu vực đội xe`,
            if(upperUTF8(trimBoth(ifNull(swm_data.UOM, ''))) = 'CSE', CAST(stm_data.QuantityBBGN, 'Nullable(Decimal(18,\r\n 4))'), NULL) AS `Sản lượng giao CSE1`,
            if((upperUTF8(trimBoth(ifNull(swm_data.UOM, ''))) IN ('PCE', 'PC', 'EA')), CAST(stm_data.QuantityBBGN, 'Nullable(Decimal(18,\r\n 4))'), NULL) AS `Sản lượng giao1`,
            if(upperUTF8(trimBoth(ifNull(swm_data.UOM, ''))) = 'PALLET', CAST(stm_data.QuantityBBGN, 'Nullable(Decimal(18,\r\n 4))'), NULL) AS `Sản lượng giao PL1`,
            if(stm_data.`Mã đơn hàng` IS NOT NULL, 1, 0) AS has_stm_line
        FROM analytics_workspace.mv_otif_swm_data AS swm_data
        LEFT JOIN
        stm_deduped AS stm_data ON (swm_data.SO = stm_data.`Mã đơn hàng`) AND (swm_data.`Item Code` = stm_data.productCode) AND (toString(swm_data.ORDERLINENUMBER) = toString(stm_data.LineNo)) AND ((stm_data.Note1 IS NULL) OR (stm_data.Note1 = '') OR (ifNull(swm_data.lottable01, '') = stm_data.Note1)) AND ((stm_data.ExpiryDate IS NULL) OR (toDate(swm_data.lottable05) = toDate(stm_data.ExpiryDate)))
        LEFT JOIN analytics_workspace.mv_masterdata_location AS masterdata_locationfrom ON toString(swm_data.WHSEID_stm) = toString(masterdata_locationfrom.code)
        LEFT JOIN analytics_workspace.mv_masterdata_location AS masterdata_locationto ON toString(swm_data.`Customer Code`) = toString(masterdata_locationto.code)
    ),
    mapped AS
    (
        SELECT
            swm_stm_enrich.*,
            multiIf(swm_stm_enrich.`Sản lượng giao CSE1` IS NOT NULL, swm_stm_enrich.`Sản lượng giao CSE1` * toDecimal64(assumeNotNull(masterdata_sku.masterunit_per_cse), 4), swm_stm_enrich.`Sản lượng giao1` IS NOT NULL, swm_stm_enrich.`Sản lượng giao1`, swm_stm_enrich.`Sản lượng giao PL1` IS NOT NULL, swm_stm_enrich.`Sản lượng giao PL1` * toDecimal64(assumeNotNull(masterdata_sku.masterunit_per_pallet), 4), NULL) AS `Sản lượng giao_mapped`,
            multiIf(swm_stm_enrich.`Sản lượng giao CSE1` IS NOT NULL, swm_stm_enrich.`Sản lượng giao CSE1`, swm_stm_enrich.`Sản lượng giao1` IS NOT NULL, swm_stm_enrich.`Sản lượng giao1` / nullIf(toDecimal64(assumeNotNull(masterdata_sku.masterunit_per_cse), 4), toDecimal64(0, 4)), swm_stm_enrich.`Sản lượng giao PL1` IS NOT NULL, (swm_stm_enrich.`Sản lượng giao PL1` * toDecimal64(assumeNotNull(masterdata_sku.masterunit_per_pallet), 4)) / nullIf(toDecimal64(assumeNotNull(masterdata_sku.masterunit_per_cse), 4), toDecimal64(0, 4)), NULL) AS `Sản lượng giao CSE_mapped`,
            multiIf(swm_stm_enrich.`Sản lượng giao CSE1` IS NOT NULL, (swm_stm_enrich.`Sản lượng giao CSE1` * toDecimal64(assumeNotNull(masterdata_sku.masterunit_per_cse), 4)) * toDecimal64(assumeNotNull(masterdata_sku.cbm_per_masterunit), 4), swm_stm_enrich.`Sản lượng giao1` IS NOT NULL, swm_stm_enrich.`Sản lượng giao1` * toDecimal64(assumeNotNull(masterdata_sku.cbm_per_masterunit), 4), swm_stm_enrich.`Sản lượng giao PL1` IS NOT NULL, (swm_stm_enrich.`Sản lượng giao PL1` * toDecimal64(assumeNotNull(masterdata_sku.masterunit_per_pallet), 4)) * toDecimal64(assumeNotNull(masterdata_sku.cbm_per_masterunit), 4), NULL) AS `Sản lượng giao CBM_mapped`,
            multiIf(swm_stm_enrich.`Sản lượng giao CSE1` IS NOT NULL, (swm_stm_enrich.`Sản lượng giao CSE1` * toDecimal64(assumeNotNull(masterdata_sku.masterunit_per_cse), 4)) * toDecimal64(assumeNotNull(masterdata_sku.kg_per_masterunit), 4), swm_stm_enrich.`Sản lượng giao1` IS NOT NULL, swm_stm_enrich.`Sản lượng giao1` * toDecimal64(assumeNotNull(masterdata_sku.kg_per_masterunit), 4), swm_stm_enrich.`Sản lượng giao PL1` IS NOT NULL, (swm_stm_enrich.`Sản lượng giao PL1` * toDecimal64(assumeNotNull(masterdata_sku.masterunit_per_pallet), 4)) * toDecimal64(assumeNotNull(masterdata_sku.kg_per_masterunit), 4), NULL) AS `Sản lượng giao KG_mapped`,
            multiIf(swm_stm_enrich.`Sản lượng giao CSE1` IS NOT NULL, (swm_stm_enrich.`Sản lượng giao CSE1` * toDecimal64(assumeNotNull(masterdata_sku.masterunit_per_cse), 4)) / nullIf(toDecimal64(assumeNotNull(masterdata_sku.masterunit_per_pallet), 4), toDecimal64(0, 4)), swm_stm_enrich.`Sản lượng giao1` IS NOT NULL, swm_stm_enrich.`Sản lượng giao1` / nullIf(toDecimal64(assumeNotNull(masterdata_sku.masterunit_per_pallet), 4), toDecimal64(0, 4)), swm_stm_enrich.`Sản lượng giao PL1` IS NOT NULL, swm_stm_enrich.`Sản lượng giao PL1`, NULL) AS `Sản lượng giao PL_mapped`
        FROM
        swm_stm_enrich
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS masterdata_sku ON (toString(swm_stm_enrich.`Item Code`) = toString(masterdata_sku.item_code)) AND (toString(swm_stm_enrich.whseid) = toString(masterdata_sku.whseid))
    )
SELECT
    any(whseid) AS whseid,
    any(WHSEID_stm) AS WHSEID_stm,
    any(orderkey) AS orderkey,
    SO,
    ORDERLINENUMBER,
    any(TYPE) AS TYPE,
    any(`Type Description`) AS `Type Description`,
    `Item Code`,
    any(UOM) AS UOM,
    any(`Group of Cago`) AS `Group of Cago`,
    any(Group) AS Group,
    any(`Customer Code`) AS `Customer Code`,
    any(`Customer Name`) AS `Customer Name`,
    any(ORIGINAL) AS ORIGINAL,
    any(`ORIGINAL CBM`) AS `ORIGINAL CBM`,
    any(`ORIGINAL KG`) AS `ORIGINAL KG`,
    any(`ORIGINAL CSE`) AS `ORIGINAL CSE`,
    any(`ORIGINAL PL`) AS `ORIGINAL PL`,
    any(`Delivery Date 1`) AS `Delivery Date 1`,
    any(`Actual Ship Date`) AS `Actual Ship Date`,
    sum(ifNull(SHIPPED, 0)) AS SHIPPED,
    sum(ifNull(`SHIPPED CBM`, 0)) AS `SHIPPED CBM`,
    sum(ifNull(`SHIPPED KG`, 0)) AS `SHIPPED KG`,
    sum(ifNull(`SHIPPED CSE`, 0)) AS `SHIPPED CSE`,
    sum(ifNull(`SHIPPED PL`, 0)) AS `SHIPPED PL`,
    any(ID_ORD_GroupProduct) AS ID_ORD_GroupProduct,
    any(`Mã đơn hàng`) AS `Mã đơn hàng`,
    any(LineNo) AS LineNo,
    any(QuantityBBGN) AS QuantityBBGN,
    any(`Thời gian gửi thầu`) AS `Thời gian gửi thầu`,
    any(`ETA (Giao hàng cho NPP)`) AS `ETA (Giao hàng cho NPP)`,
    any(`ATA đến`) AS `ATA đến`,
    any(`ATA rời`) AS `ATA rời`,
    any(`ID chuyến gửi thầu`) AS `ID chuyến gửi thầu`,
    any(`Tên ngắn nhà vận tải`) AS `Tên ngắn nhà vận tải`,
    any(`Mã nhà xe`) AS `Mã nhà xe`,
    any(`Loại xe vận hành`) AS `Loại xe vận hành`,
    any(`Loại xe gửi thầu`) AS `Loại xe gửi thầu`,
    any(`Ngày tạo chuyến`) AS `Ngày tạo chuyến`,
    any(`ETD chuyến gửi thầu`) AS `ETD chuyến gửi thầu`,
    any(`Giờ đăng tài`) AS `Giờ đăng tài`,
    any(`Giờ gọi xe`) AS `Giờ gọi xe`,
    any(`Giờ vào cổng`) AS `Giờ vào cổng`,
    any(`Giờ vào dock`) AS `Giờ vào dock`,
    any(`TG bắt buộc rời kho`) AS `TG bắt buộc rời kho`,
    any(`Giờ ra dock`) AS `Giờ ra dock`,
    any(`Giờ ra cổng`) AS `Giờ ra cổng`,
    any(`Số chuyến`) AS `Số chuyến`,
    any(`Số xe`) AS `Số xe`,
    any(`Tài xế`) AS `Tài xế`,
    any(`Ngày duyệt chuyến`) AS `Ngày duyệt chuyến`,
    any(`Ngày tạo đơn`) AS `Ngày tạo đơn`,
    any(`Mã đối tác nhận`) AS `Mã đối tác nhận`,
    any(`Tên đối tác nhận`) AS `Tên đối tác nhận`,
    any(`Khu vực đội xe`) AS `Khu vực đội xe`,
    any(`Sản lượng giao CSE1`) AS `Sản lượng giao CSE1`,
    any(`Sản lượng giao1`) AS `Sản lượng giao1`,
    any(`Sản lượng giao PL1`) AS `Sản lượng giao PL1`,
    max(has_stm_line) AS has_stm_line,
    any(`Sản lượng giao_mapped`) AS `Sản lượng giao`,
    any(`Sản lượng giao CSE_mapped`) AS `Sản lượng giao CSE`,
    any(`Sản lượng giao CBM_mapped`) AS `Sản lượng giao CBM`,
    any(`Sản lượng giao KG_mapped`) AS `Sản lượng giao KG`,
    any(`Sản lượng giao PL_mapped`) AS `Sản lượng giao PL`,
    any(lottable01) AS lottable01,
    any(lottable05) AS lottable05,
    any(productCode) AS productCode,
    any(Note1) AS Note1,
    any(ExpiryDate) AS ExpiryDate
FROM
mapped
GROUP BY
    SO,
    `Item Code`,
    ORDERLINENUMBER


-- ════════════════════════════════════════════════════
-- Object: mv_outbound_transaction_base  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_outbound_transaction_base
REFRESH EVERY 30 MINUTE
(
    `transaction_date` Nullable(DateTime64(3, 'UTC')),
    `warehouse` String,
    `category_converted` Nullable(String),
    `activity` String,
    `uom` String,
    `PCE` Decimal(38, 8),
    `CBM` Nullable(Float64),
    `Ton` Nullable(Float64),
    `CSE` Nullable(Float64),
    `Pallet` Nullable(Float64),
    `orders` UInt64,
    `direction` String
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (direction, transaction_date, warehouse, activity, category_converted)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    raw AS
    (
        SELECT *
        FROM analytics_workspace.mv_outbound_transaction_raw
    ),
    ob_sales_cbm AS
    (
        SELECT
            actual_ship_date,
            whseid AS warehouse,
            category_converted,
            'Xuất bán / Loading loose' AS activity_outbound,
            'CBM' AS uom,
            sum(shipped_qty) AS PCE,
            sum(CBM_shipped) AS CBM,
            sum(TON_shipped) AS Ton,
            sum(CSE_shipped) AS CSE,
            sum(PALLET_shipped) AS Pallet,
            countDistinct(so_no) AS don
        FROM
        raw
        WHERE ((type IN ('01', '240', 'XTNPP')) AND (whseid IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type IN ('01', '07', '08', '09', '240', 'XB2BMC', 'XMAU')) AND (whseid = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    ob_wh_transfer_in_ex AS
    (
        SELECT
            actual_ship_date,
            whseid AS warehouse,
            category_converted,
            'Xuất chuyển kho / WH Transfer In-Ex' AS activity_outbound,
            'PALLET' AS uom,
            sum(shipped_qty) AS PCE,
            sum(CBM_shipped) AS CBM,
            sum(TON_shipped) AS Ton,
            sum(CSE_shipped) AS CSE,
            sum(ceil(PALLET_shipped)) AS Pallet,
            countDistinct(so_no) AS don
        FROM
        raw
        WHERE ((type IN ('03', 'ICDK12', 'ICDMT', 'ICD', 'ICDMC', 'ICDSFG')) AND (whseid IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type IN ('03', 'GMDGT', 'TLLMC', 'CKN')) AND (whseid = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    ob_wh_transfer_in_in AS
    (
        SELECT
            actual_ship_date,
            whseid AS warehouse,
            category_converted,
            'Xuất chuyển kho / WH Transfer In-In' AS activity_outbound,
            'PALLET' AS uom,
            sum(shipped_qty) AS PCE,
            sum(CBM_shipped) AS CBM,
            sum(TON_shipped) AS Ton,
            sum(CSE_shipped) AS CSE,
            sum(ceil(PALLET_shipped)) AS Pallet,
            countDistinct(so_no) AS don
        FROM
        raw
        WHERE type IN ('02')
        GROUP BY
            1,
            2,
            3
    ),
    ob_destroy AS
    (
        SELECT
            actual_ship_date,
            whseid AS warehouse,
            category_converted,
            'Xuất hủy' AS activity_outbound,
            'PALLET' AS uom,
            sum(shipped_qty) AS PCE,
            sum(CBM_shipped) AS CBM,
            sum(TON_shipped) AS Ton,
            sum(CSE_shipped) AS CSE,
            sum(ceil(PALLET_shipped)) AS Pallet,
            countDistinct(so_no) AS don
        FROM
        raw
        WHERE (type IN ('XK', '14')) AND (actual_ship_date IS NOT NULL)
        GROUP BY
            1,
            2,
            3
    ),
    ob_direct_transfer AS
    (
        SELECT
            actual_ship_date,
            whseid AS warehouse,
            category_converted,
            'Xuất chuyển kho trực tiếp từ xưởng' AS activity_outbound,
            'PALLET' AS uom,
            sum(shipped_qty) AS PCE,
            sum(CBM_shipped) AS CBM,
            sum(TON_shipped) AS Ton,
            sum(CSE_shipped) AS CSE,
            sum(ceil(PALLET_shipped)) AS Pallet,
            countDistinct(so_no) AS don
        FROM
        raw
        WHERE ((type IN ('08', 'XTX')) AND (whseid IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type IN ('CKX0022')) AND (whseid = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    ob_export_case AS
    (
        SELECT
            actual_ship_date,
            whseid AS warehouse,
            category_converted,
            'Xuất khẩu / Outbound loose from Prod' AS activity_outbound,
            'CASE' AS uom,
            sum(shipped_qty) AS PCE,
            sum(CBM_shipped) AS CBM,
            sum(TON_shipped) AS Ton,
            sum(CSE_shipped) AS CSE,
            sum(PALLET_shipped) AS Pallet,
            countDistinct(so_no) AS don
        FROM
        raw
        WHERE ((type IN ('EXPORT', '241')) AND (whseid = 'NKD')) OR ((type IN ('04', '09', '241')) AND (whseid IN ('BKD1', 'BKD2', 'BKD3')))
        GROUP BY
            1,
            2,
            3
    ),
    ob_copack AS
    (
        SELECT
            actual_ship_date,
            whseid AS warehouse,
            category_converted,
            'Xuất TDX / Outbound copack' AS activity_outbound,
            'PALLET' AS uom,
            sum(shipped_qty) AS PCE,
            sum(CBM_shipped) AS CBM,
            sum(TON_shipped) AS Ton,
            sum(CSE_shipped) AS CSE,
            sum(ceil(PALLET_shipped)) AS Pallet,
            countDistinct(so_no) AS don
        FROM
        raw
        WHERE (((type IN ('CPK', '05')) AND (whseid IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type IN ('04', '05', 'CPK')) AND (whseid = 'NKD'))) AND (actual_ship_date IS NOT NULL)
        GROUP BY
            1,
            2,
            3
    ),
    ob_posm AS
    (
        SELECT
            actual_ship_date,
            whseid AS warehouse,
            category_converted,
            'Xuất POSM / Outbound POSM' AS activity_outbound,
            'TONS' AS uom,
            sum(shipped_qty) AS PCE,
            sum(CBM_shipped) AS CBM,
            sum(TON_shipped) AS Ton,
            sum(CSE_shipped) AS CSE,
            sum(PALLET_shipped) AS Pallet,
            countDistinct(so_no) AS don
        FROM
        raw
        WHERE ((type IN ('01', '240', 'XTNPP')) AND (group_of_cargo = 'POSM/OFFBOM') AND (whseid IN ('BKD1', 'BKD2', 'BKD3'))) OR ((type IN ('01', '07', '08', '09', '240', 'XB2BMC', 'XTNPP')) AND (group_of_cargo = 'POSM/OFFBOM') AND (whseid = 'NKD'))
        GROUP BY
            1,
            2,
            3
    ),
    ob_print_do AS
    (
        SELECT
            actual_ship_date,
            whseid AS warehouse,
            category_converted,
            'Print DO' AS activity_outbound,
            'DO' AS uom,
            sum(shipped_qty) AS PCE,
            sum(CBM_shipped) AS CBM,
            sum(TON_shipped) AS Ton,
            sum(CSE_shipped) AS CSE,
            sum(PALLET_shipped) AS Pallet,
            countDistinct(so_no) AS don
        FROM
        raw
        GROUP BY
            1,
            2,
            3
    ),
    unioned AS
    (
        SELECT *
        FROM
        ob_sales_cbm
        UNION ALL
        SELECT *
        FROM
        ob_wh_transfer_in_ex
        UNION ALL
        SELECT *
        FROM
        ob_wh_transfer_in_in
        UNION ALL
        SELECT *
        FROM
        ob_destroy
        UNION ALL
        SELECT *
        FROM
        ob_direct_transfer
        UNION ALL
        SELECT *
        FROM
        ob_export_case
        UNION ALL
        SELECT *
        FROM
        ob_copack
        UNION ALL
        SELECT *
        FROM
        ob_posm
        UNION ALL
        SELECT *
        FROM
        ob_print_do
    )
SELECT
    actual_ship_date AS transaction_date,
    warehouse,
    category_converted,
    activity_outbound AS activity,
    uom,
    PCE,
    CBM,
    Ton,
    CSE,
    Pallet,
    don AS orders,
    'OUTBOUND' AS direction
FROM
unioned


-- ════════════════════════════════════════════════════
-- Object: mv_outbound_transaction_raw  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_outbound_transaction_raw
REFRESH EVERY 30 MINUTE
(
    `so_no` String,
    `actual_ship_date` Date,
    `whseid` String,
    `type` String,
    `group_of_cargo` Nullable(String),
    `category_converted` Nullable(String),
    `shipped_qty` Nullable(Float64),
    `CBM_shipped` Nullable(Float64),
    `TON_shipped` Nullable(Float64),
    `CSE_shipped` Nullable(Float64),
    `PALLET_shipped` Nullable(Float64)
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (actual_ship_date, whseid, type)
SETTINGS index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    group_pickdetail AS
    (
        SELECT
            storer_key,
            whseid,
            order_key,
            order_line_number,
            sum(qty) AS shipped
        FROM swm_dwh_mondelez.dim_pickdetail
        WHERE (storer_key = 'MDLZ') AND (whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (is_deleted = 0)
        GROUP BY
            1,
            2,
            3,
            4
    ),
    outbound_summary AS
    (
        SELECT
            orders.extern_order_key AS so_no,
            toDate(orders.actual_ship_date) AS actual_ship_date,
            orderdetail.whseid AS whseid,
            orders.type AS type,
            orderdetail.sku AS sku,
            p.shipped AS shipped_qty
        FROM swm_dwh_mondelez.dim_orderdetail AS orderdetail
        INNER JOIN swm_dwh_mondelez.dim_orders AS orders ON (orderdetail.order_key = orders.order_key) AND (orderdetail.whseid = orders.whseid) AND (orderdetail.storer_key = orders.storer_key)
        LEFT JOIN
        group_pickdetail AS p ON (orderdetail.order_key = p.order_key) AND (orderdetail.order_line_number = p.order_line_number) AND (orderdetail.whseid = p.whseid) AND (orderdetail.storer_key = p.storer_key)
        WHERE (orders.status_code = '95') AND (orders.storer_key = 'MDLZ') AND (orders.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (orders.is_deleted = 0) AND (orderdetail.is_deleted = 0)
    )
SELECT
    ob.so_no,
    ob.actual_ship_date,
    ob.whseid,
    ob.type,
    sku.group_of_cargo,
    multiIf((trimBoth(upper(ob.sku)) IN ('LOSCAM', 'BACHTHUAN')), 'Pallet rong', (sku.group_of_cargo IN ('DRY', 'FRESH', 'MOONCAKE', 'TET')), 'Dry & Fresh & MC & Tet', (sku.group_of_cargo IN ('POSM/OFFBOM', 'PM')), 'POSM/OFFBOM & PM', NULL) AS category_converted,
    toFloat64(ob.shipped_qty) AS shipped_qty,
    ob.shipped_qty * nullIf(sku.cbm_per_masterunit, 0) AS CBM_shipped,
    (ob.shipped_qty * nullIf(sku.kg_per_masterunit, 0)) / 1000 AS TON_shipped,
    ob.shipped_qty / nullIf(sku.masterunit_per_cse, 0) AS CSE_shipped,
    ob.shipped_qty / nullIf(sku.masterunit_per_pallet, 0) AS PALLET_shipped
FROM
outbound_summary AS ob
LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (ob.sku = sku.item_code) AND (ob.whseid = sku.whseid)
WHERE sku.group_of_cargo NOT IN ('PM', 'TEST', 'EQUIPMENT')


-- ════════════════════════════════════════════════════
-- Object: mv_psv  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_psv
REFRESH EVERY 30 MINUTE
(
    `ops_optimize_id` Int32,
    `version` UInt64,
    `sys_customer_id` Int32,
    `optimizer_name` String,
    `created_date` DateTime64(6),
    `created_by` LowCardinality(String),
    `parent_modified_date` DateTime64(6),
    `parent_modified_by` LowCardinality(String),
    `date_from` DateTime64(6),
    `date_to` DateTime64(6),
    `is_save` Bool,
    `is_container` Bool,
    `is_balance_customer` Bool,
    `is_balance_km_score` Bool,
    `type_id` Int32,
    `note` String,
    `note_1` String,
    `note_2` String,
    `tracking_id` String,
    `report_id` Int64,
    `is_trip_edit_manual` Bool,
    `order_code` String,
    `total_order` Int64,
    `total_delivery` Int64,
    `total_ton` Float64,
    `total_cbm` Float64,
    `total_cod_unit_price` Float64,
    `group_of_vehicle_code` LowCardinality(String),
    `group_of_vehicle_name` LowCardinality(String),
    `group_of_vehicle_size` LowCardinality(String),
    `vehicle_no` LowCardinality(String),
    `max_capacity` Float64,
    `max_weight` Float64,
    `vendor_name` LowCardinality(String),
    `main_cost` Float64,
    `additional_cost` Float64,
    `total_cost` Float64,
    `total_distance` Float64,
    `master_etd` DateTime,
    `master_eta` DateTime,
    `date_come_stock` DateTime,
    `vehicle_end_time` DateTime,
    `report_modified_date` DateTime,
    `group_product_code` String,
    `group_product_name` String,
    `product_code` String,
    `product_name` String,
    `location_from_code` LowCardinality(String),
    `location_from_name` LowCardinality(String),
    `location_to_code` String,
    `location_to_name` String,
    `group_ids` String,
    `order_ids` String,
    `constraint_name` String,
    `constraint_note` String,
    `data_report` Bool,
    `is_deleted` UInt8
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (ops_optimize_id, tracking_id, report_id, version)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = `sql-console:vy.tao@gosmartlog.com` SQL SECURITY DEFINER
AS SELECT
    ID AS ops_optimize_id,
    _peerdb_version AS version,
    coalesce(SYSCustomerID, -1) AS sys_customer_id,
    coalesce(OptimizerName, '') AS optimizer_name,
    coalesce(CreatedDate, toDateTime64('1970-01-01 00:00:00', 6)) AS created_date,
    CAST(coalesce(CreatedBy, ''), 'LowCardinality(String)') AS created_by,
    coalesce(ModifiedDate, toDateTime64('1970-01-01 00:00:00', 6)) AS parent_modified_date,
    CAST(coalesce(ModifiedBy, ''), 'LowCardinality(String)') AS parent_modified_by,
    coalesce(DateFrom, toDateTime64('1970-01-01 00:00:00', 6)) AS date_from,
    coalesce(DateTo, toDateTime64('1970-01-01 00:00:00', 6)) AS date_to,
    coalesce(IsSave, false) AS is_save,
    coalesce(IsContainer, false) AS is_container,
    coalesce(IsBalanceCustomer, false) AS is_balance_customer,
    coalesce(IsBalanceKMScore, false) AS is_balance_km_score,
    coalesce(TypeID, -1) AS type_id,
    coalesce(Note, '') AS note,
    coalesce(Note1, '') AS note_1,
    coalesce(Note2, '') AS note_2,
    coalesce(JSONExtractString(v, 'TrackingID'), '') AS tracking_id,
    coalesce(JSONExtractInt(v, 'ID'), -1) AS report_id,
    toBool(coalesce(JSONExtractBool(v, 'IsTripEditManual'), false)) AS is_trip_edit_manual,
    coalesce(JSONExtractString(v, 'OrderCode'), '') AS order_code,
    coalesce(JSONExtractInt(v, 'TotalOrder'), 0) AS total_order,
    coalesce(JSONExtractInt(v, 'TotalDelivery'), 0) AS total_delivery,
    coalesce(JSONExtractFloat(v, 'TotalTon'), 0) AS total_ton,
    coalesce(JSONExtractFloat(v, 'TotalCBM'), 0) AS total_cbm,
    coalesce(JSONExtractFloat(v, 'TotalCODUnitPrice'), 0) AS total_cod_unit_price,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleCode'), ''), 'LowCardinality(String)') AS group_of_vehicle_code,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleName'), ''), 'LowCardinality(String)') AS group_of_vehicle_name,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleSize'), ''), 'LowCardinality(String)') AS group_of_vehicle_size,
    CAST(coalesce(JSONExtractString(v, 'VehicleNo'), ''), 'LowCardinality(String)') AS vehicle_no,
    coalesce(JSONExtractFloat(v, 'MaxCapacity'), 0) AS max_capacity,
    coalesce(JSONExtractFloat(v, 'MaxWeight'), 0) AS max_weight,
    CAST(coalesce(JSONExtractString(v, 'VendorName'), ''), 'LowCardinality(String)') AS vendor_name,
    coalesce(JSONExtractFloat(v, 'MainCost'), 0) AS main_cost,
    coalesce(JSONExtractFloat(v, 'AdditionalCost'), 0) AS additional_cost,
    coalesce(JSONExtractFloat(v, 'TotalCost'), 0) AS total_cost,
    coalesce(JSONExtractFloat(v, 'TotalDistance'), 0) AS total_distance,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'MasterETD')), toDateTime('1970-01-01 00:00:00')) AS master_etd,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'MasterETA')), toDateTime('1970-01-01 00:00:00')) AS master_eta,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'DateComeStock')), toDateTime('1970-01-01 00:00:00')) AS date_come_stock,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'VehicleEndTime')), toDateTime('1970-01-01 00:00:00')) AS vehicle_end_time,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'ModifiedDate')), toDateTime('1970-01-01 00:00:00')) AS report_modified_date,
    coalesce(JSONExtractString(v, 'GroupOfProductCode'), '') AS group_product_code,
    coalesce(JSONExtractString(v, 'GroupOfProductName'), '') AS group_product_name,
    coalesce(JSONExtractString(v, 'ProductCode'), '') AS product_code,
    coalesce(JSONExtractString(v, 'ProductName'), '') AS product_name,
    CAST(coalesce(JSONExtractString(v, 'LocationFromCode'), ''), 'LowCardinality(String)') AS location_from_code,
    CAST(coalesce(JSONExtractString(v, 'LocationFromName'), ''), 'LowCardinality(String)') AS location_from_name,
    coalesce(JSONExtractString(v, 'LocationToCode'), '') AS location_to_code,
    coalesce(JSONExtractString(v, 'LocationToName'), '') AS location_to_name,
    coalesce(JSONExtractRaw(v, 'GroupIds'), '[]') AS group_ids,
    coalesce(JSONExtractRaw(v, 'OrderIds'), '[]') AS order_ids,
    coalesce(JSONExtractString(v, 'ConstraintName'), '') AS constraint_name,
    coalesce(JSONExtractString(v, 'ConstraintNote'), '') AS constraint_note,
    if(empty(JSONExtractString(DataRun, 'DataReport')) OR (JSONExtractString(DataRun, 'DataReport') = '[]'), false, true) AS data_report,
    coalesce(_peerdb_is_deleted, 0) AS is_deleted
FROM tms_panasonic_prod.dbo_OPS_Optimizer
LEFT ARRAY JOIN JSONExtractArrayRaw(coalesce(JSONExtractString(DataRun, 'DataReport'), '[]')) AS v


-- ════════════════════════════════════════════════════
-- Object: mv_psv_main  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_psv_main
REFRESH EVERY 1 HOUR
(
    `tracking_id` String,
    `optimizer_name` String,
    `created_by` LowCardinality(String),
    `created_date` DateTime64(6),
    `is_trip_edit_manual` Bool,
    `status_name_detail` String,
    `order_code` String,
    `total_order` Int64,
    `total_delivery` Int64,
    `total_ton` Float64,
    `total_cbm` Float64,
    `total_cod_unit_price` Float64,
    `group_of_vehicle_code` LowCardinality(String),
    `group_of_vehicle_name` LowCardinality(String),
    `group_of_vehicle_size` LowCardinality(String),
    `vehicle_no` LowCardinality(String),
    `max_capacity` Float64,
    `max_weight` Float64,
    `vendor_name` LowCardinality(String),
    `main_cost` Float64,
    `additional_cost` Float64,
    `total_cost` Float64,
    `report_modified_by` LowCardinality(String),
    `report_modified_date` Nullable(DateTime),
    `reason_change` String,
    `constraint_name` String,
    `constraint_note` String,
    `group_of_product_code` String,
    `group_of_product_name` String,
    `product_code` String,
    `product_name` String,
    `location_from_code` LowCardinality(String),
    `location_to_code` String,
    `master_etd` Nullable(DateTime),
    `master_eta` Nullable(DateTime),
    `date_come_stock` Nullable(DateTime),
    `vehicle_end_time` Nullable(DateTime),
    `is_deleted` Nullable(Int8),
    `data_report` Bool
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (tracking_id, order_code)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS SELECT
    tracking_id,
    optimizer_name,
    created_by,
    created_date,
    is_trip_edit_manual,
    status_name_detail,
    order_code,
    total_order,
    total_delivery,
    total_ton,
    total_cbm,
    total_cod_unit_price,
    group_of_vehicle_code,
    group_of_vehicle_name,
    group_of_vehicle_size,
    vehicle_no,
    max_capacity,
    max_weight,
    vendor_name,
    main_cost,
    additional_cost,
    total_cost,
    report_modified_by,
    nullIf(report_modified_date + toIntervalHour(7), toDateTime('1970-01-01 07:00:00')) AS report_modified_date,
    reason_change,
    constraint_name,
    constraint_note,
    group_of_product_code,
    group_of_product_name,
    product_code,
    product_name,
    location_from_code,
    location_to_code,
    nullIf(master_etd + toIntervalHour(7), toDateTime('1970-01-01 07:00:00')) AS master_etd,
    nullIf(master_eta + toIntervalHour(7), toDateTime('1970-01-01 07:00:00')) AS master_eta,
    nullIf(date_come_stock + toIntervalHour(7), toDateTime('1970-01-01 07:00:00')) AS date_come_stock,
    nullIf(vehicle_end_time + toIntervalHour(7), toDateTime('1970-01-01 07:00:00')) AS vehicle_end_time,
    is_deleted,
    data_report
FROM analytics_workspace.psv_target
FINAL
WHERE (is_deleted = 0) AND (data_report = true)


-- ════════════════════════════════════════════════════
-- Object: mv_psv_trigger  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_psv_trigger TO analytics_workspace.psv_target
(
    `ops_optimize_id` Int32,
    `version` UInt64,
    `sys_customer_id` Int32,
    `optimizer_name` String,
    `created_date` DateTime64(6),
    `created_by` LowCardinality(String),
    `parent_modified_date` DateTime64(6),
    `parent_modified_by` LowCardinality(String),
    `date_from` DateTime64(6),
    `date_to` DateTime64(6),
    `is_save` Bool,
    `is_container` Bool,
    `is_balance_customer` Bool,
    `is_balance_km_score` Bool,
    `type_id` Int32,
    `note` String,
    `note_1` String,
    `note_2` String,
    `tracking_id` Int64,
    `report_id` Int64,
    `is_trip_edit_manual` Bool,
    `reason_change` String,
    `status_name_detail_original` LowCardinality(String),
    `status_name_detail` LowCardinality(String),
    `order_code` String,
    `total_order` Int64,
    `total_delivery` Int64,
    `total_ton` Float64,
    `total_cbm` Float64,
    `total_cod_unit_price` Float64,
    `group_of_vehicle_code` LowCardinality(String),
    `group_of_vehicle_name` LowCardinality(String),
    `group_of_vehicle_size` LowCardinality(String),
    `vehicle_no` LowCardinality(String),
    `max_capacity` Float64,
    `max_weight` Float64,
    `vendor_name` LowCardinality(String),
    `main_cost` Float64,
    `additional_cost` Float64,
    `total_cost` Float64,
    `total_distance` Float64,
    `master_etd` DateTime,
    `master_eta` DateTime,
    `date_come_stock` DateTime,
    `vehicle_end_time` DateTime,
    `report_modified_date` DateTime,
    `report_modified_by` LowCardinality(String),
    `group_of_product_code` String,
    `group_of_product_name` String,
    `product_code` String,
    `product_name` String,
    `location_from_code` LowCardinality(String),
    `location_from_name` LowCardinality(String),
    `location_to_code` String,
    `location_to_name` String,
    `group_ids` String,
    `order_ids` String,
    `constraint_name` String,
    `constraint_note` String,
    `data_report` Bool,
    `is_deleted` UInt8
)
AS SELECT
    ID AS ops_optimize_id,
    _peerdb_version AS version,
    coalesce(SYSCustomerID, -1) AS sys_customer_id,
    coalesce(OptimizerName, '') AS optimizer_name,
    coalesce(CreatedDate, toDateTime64('1970-01-01 00:00:00', 6)) AS created_date,
    CAST(coalesce(CreatedBy, ''), 'LowCardinality(String)') AS created_by,
    coalesce(ModifiedDate, toDateTime64('1970-01-01 00:00:00', 6)) AS parent_modified_date,
    CAST(coalesce(ModifiedBy, ''), 'LowCardinality(String)') AS parent_modified_by,
    coalesce(DateFrom, toDateTime64('1970-01-01 00:00:00', 6)) AS date_from,
    coalesce(DateTo, toDateTime64('1970-01-01 00:00:00', 6)) AS date_to,
    coalesce(IsSave, false) AS is_save,
    coalesce(IsContainer, false) AS is_container,
    coalesce(IsBalanceCustomer, false) AS is_balance_customer,
    coalesce(IsBalanceKMScore, false) AS is_balance_km_score,
    coalesce(TypeID, -1) AS type_id,
    coalesce(Note, '') AS note,
    coalesce(Note1, '') AS note_1,
    coalesce(Note2, '') AS note_2,
    coalesce(JSONExtractInt(v, 'TrackingID'), -1) AS tracking_id,
    coalesce(JSONExtractInt(v, 'ID'), -1) AS report_id,
    toBool(coalesce(JSONExtractBool(v, 'IsTripEditManual'), false)) AS is_trip_edit_manual,
    coalesce(JSONExtractString(v, 'ReasonChange'), '') AS reason_change,
    CAST(multiIf(NOT JSONHas(v, 'StatusNameDetail'), 'Không có cột', isNull(JSONExtractString(v, 'StatusNameDetail')) OR (JSONExtractString(v, 'StatusNameDetail') = ''), ' ', JSONExtractString(v, 'StatusNameDetail')), 'LowCardinality(String)') AS status_name_detail_original,
    CAST(multiIf((is_trip_edit_manual = true) AND (isNull(JSONExtractString(v, 'StatusNameDetail')) OR (JSONExtractString(v, 'StatusNameDetail') = '')), 'Chuyến điều chỉnh route', 'Chuyến tạo mới'), 'LowCardinality(String)') AS status_name_detail,
    coalesce(JSONExtractString(v, 'OrderCode'), '') AS order_code,
    coalesce(JSONExtractInt(v, 'TotalOrder'), 0) AS total_order,
    coalesce(JSONExtractInt(v, 'TotalDelivery'), 0) AS total_delivery,
    coalesce(JSONExtractFloat(v, 'TotalTon'), 0) AS total_ton,
    coalesce(JSONExtractFloat(v, 'TotalCBM'), 0) AS total_cbm,
    coalesce(JSONExtractFloat(v, 'TotalCODUnitPrice'), 0) AS total_cod_unit_price,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleCode'), ''), 'LowCardinality(String)') AS group_of_vehicle_code,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleName'), ''), 'LowCardinality(String)') AS group_of_vehicle_name,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleSize'), ''), 'LowCardinality(String)') AS group_of_vehicle_size,
    CAST(coalesce(JSONExtractString(v, 'VehicleNo'), ''), 'LowCardinality(String)') AS vehicle_no,
    coalesce(JSONExtractFloat(v, 'MaxCapacity'), 0) AS max_capacity,
    coalesce(JSONExtractFloat(v, 'MaxWeight'), 0) AS max_weight,
    CAST(coalesce(JSONExtractString(v, 'VendorName'), ''), 'LowCardinality(String)') AS vendor_name,
    coalesce(JSONExtractFloat(v, 'MainCost'), 0) AS main_cost,
    coalesce(JSONExtractFloat(v, 'AdditionalCost'), 0) AS additional_cost,
    coalesce(JSONExtractFloat(v, 'TotalCost'), 0) AS total_cost,
    coalesce(JSONExtractFloat(v, 'TotalDistance'), 0) AS total_distance,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'MasterETD')), toDateTime('1970-01-01 00:00:00')) AS master_etd,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'MasterETA')), toDateTime('1970-01-01 00:00:00')) AS master_eta,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'DateComeStock')), toDateTime('1970-01-01 00:00:00')) AS date_come_stock,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'VehicleEndTime')), toDateTime('1970-01-01 00:00:00')) AS vehicle_end_time,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'ModifiedDate')), toDateTime('1970-01-01 00:00:00')) AS report_modified_date,
    CAST(coalesce(JSONExtractString(v, 'ModifiedBy'), ''), 'LowCardinality(String)') AS report_modified_by,
    coalesce(JSONExtractString(v, 'GroupOfProductCode'), '') AS group_of_product_code,
    coalesce(JSONExtractString(v, 'GroupOfProductName'), '') AS group_of_product_name,
    coalesce(JSONExtractString(v, 'ProductCode'), '') AS product_code,
    coalesce(JSONExtractString(v, 'ProductName'), '') AS product_name,
    CAST(coalesce(JSONExtractString(v, 'LocationFromCode'), ''), 'LowCardinality(String)') AS location_from_code,
    CAST(coalesce(JSONExtractString(v, 'LocationFromName'), ''), 'LowCardinality(String)') AS location_from_name,
    coalesce(JSONExtractString(v, 'LocationToCode'), '') AS location_to_code,
    coalesce(JSONExtractString(v, 'LocationToName'), '') AS location_to_name,
    coalesce(JSONExtractRaw(v, 'GroupIds'), '[]') AS group_ids,
    coalesce(JSONExtractRaw(v, 'OrderIds'), '[]') AS order_ids,
    coalesce(JSONExtractString(v, 'ConstraintName'), '') AS constraint_name,
    coalesce(JSONExtractString(v, 'ConstraintNote'), '') AS constraint_note,
    if(empty(JSONExtractString(DataRun, 'DataReport')) OR (JSONExtractString(DataRun, 'DataReport') = '[]'), false, true) AS data_report,
    coalesce(_peerdb_is_deleted, 0) AS is_deleted
FROM tms_panasonic_prod.dbo_OPS_Optimizer
LEFT ARRAY JOIN JSONExtractArrayRaw(coalesce(JSONExtractString(DataRun, 'DataReport'), '[]')) AS v


-- ════════════════════════════════════════════════════
-- Object: mv_psv_trigger_test  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_psv_trigger_test TO analytics_workspace.psv_target_test
(
    `ops_optimize_id` Int32,
    `version` UInt64,
    `sys_customer_id` Int32,
    `optimizer_name` String,
    `created_date` DateTime64(6),
    `created_by` LowCardinality(String),
    `parent_modified_date` DateTime64(6),
    `parent_modified_by` LowCardinality(String),
    `date_from` DateTime64(6),
    `date_to` DateTime64(6),
    `is_save` Bool,
    `is_container` Bool,
    `is_balance_customer` Bool,
    `is_balance_km_score` Bool,
    `type_id` Int32,
    `note` String,
    `note_1` String,
    `note_2` String,
    `tracking_id` String,
    `report_id` Int64,
    `is_trip_edit_manual` Bool,
    `order_code` String,
    `total_order` Int64,
    `total_delivery` Int64,
    `total_ton` Float64,
    `total_cbm` Float64,
    `total_cod_unit_price` Float64,
    `group_of_vehicle_code` LowCardinality(String),
    `group_of_vehicle_name` LowCardinality(String),
    `group_of_vehicle_size` LowCardinality(String),
    `vehicle_no` LowCardinality(String),
    `max_capacity` Float64,
    `max_weight` Float64,
    `vendor_name` LowCardinality(String),
    `main_cost` Float64,
    `additional_cost` Float64,
    `total_cost` Float64,
    `total_distance` Float64,
    `master_etd` DateTime,
    `master_eta` DateTime,
    `date_come_stock` DateTime,
    `vehicle_end_time` DateTime,
    `report_modified_date` DateTime,
    `group_product_code` String,
    `group_product_name` String,
    `product_code` String,
    `product_name` String,
    `location_from_code` LowCardinality(String),
    `location_from_name` LowCardinality(String),
    `location_to_code` String,
    `location_to_name` String,
    `group_ids` String,
    `order_ids` String,
    `constraint_name` String,
    `constraint_note` String,
    `data_report` Bool,
    `is_deleted` UInt8
)
AS SELECT
    ID AS ops_optimize_id,
    _peerdb_version AS version,
    coalesce(SYSCustomerID, -1) AS sys_customer_id,
    coalesce(OptimizerName, '') AS optimizer_name,
    coalesce(CreatedDate, toDateTime64('1970-01-01 00:00:00', 6)) AS created_date,
    CAST(coalesce(CreatedBy, ''), 'LowCardinality(String)') AS created_by,
    coalesce(ModifiedDate, toDateTime64('1970-01-01 00:00:00', 6)) AS parent_modified_date,
    CAST(coalesce(ModifiedBy, ''), 'LowCardinality(String)') AS parent_modified_by,
    coalesce(DateFrom, toDateTime64('1970-01-01 00:00:00', 6)) AS date_from,
    coalesce(DateTo, toDateTime64('1970-01-01 00:00:00', 6)) AS date_to,
    coalesce(IsSave, false) AS is_save,
    coalesce(IsContainer, false) AS is_container,
    coalesce(IsBalanceCustomer, false) AS is_balance_customer,
    coalesce(IsBalanceKMScore, false) AS is_balance_km_score,
    coalesce(TypeID, -1) AS type_id,
    coalesce(Note, '') AS note,
    coalesce(Note1, '') AS note_1,
    coalesce(Note2, '') AS note_2,
    coalesce(JSONExtractString(v, 'TrackingID'), '') AS tracking_id,
    coalesce(JSONExtractInt(v, 'ID'), -1) AS report_id,
    toBool(coalesce(JSONExtractBool(v, 'IsTripEditManual'), false)) AS is_trip_edit_manual,
    coalesce(JSONExtractString(v, 'OrderCode'), '') AS order_code,
    coalesce(JSONExtractInt(v, 'TotalOrder'), 0) AS total_order,
    coalesce(JSONExtractInt(v, 'TotalDelivery'), 0) AS total_delivery,
    coalesce(JSONExtractFloat(v, 'TotalTon'), 0) AS total_ton,
    coalesce(JSONExtractFloat(v, 'TotalCBM'), 0) AS total_cbm,
    coalesce(JSONExtractFloat(v, 'TotalCODUnitPrice'), 0) AS total_cod_unit_price,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleCode'), ''), 'LowCardinality(String)') AS group_of_vehicle_code,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleName'), ''), 'LowCardinality(String)') AS group_of_vehicle_name,
    CAST(coalesce(JSONExtractString(v, 'GroupOfVehicleSize'), ''), 'LowCardinality(String)') AS group_of_vehicle_size,
    CAST(coalesce(JSONExtractString(v, 'VehicleNo'), ''), 'LowCardinality(String)') AS vehicle_no,
    coalesce(JSONExtractFloat(v, 'MaxCapacity'), 0) AS max_capacity,
    coalesce(JSONExtractFloat(v, 'MaxWeight'), 0) AS max_weight,
    CAST(coalesce(JSONExtractString(v, 'VendorName'), ''), 'LowCardinality(String)') AS vendor_name,
    coalesce(JSONExtractFloat(v, 'MainCost'), 0) AS main_cost,
    coalesce(JSONExtractFloat(v, 'AdditionalCost'), 0) AS additional_cost,
    coalesce(JSONExtractFloat(v, 'TotalCost'), 0) AS total_cost,
    coalesce(JSONExtractFloat(v, 'TotalDistance'), 0) AS total_distance,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'MasterETD')), toDateTime('1970-01-01 00:00:00')) AS master_etd,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'MasterETA')), toDateTime('1970-01-01 00:00:00')) AS master_eta,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'DateComeStock')), toDateTime('1970-01-01 00:00:00')) AS date_come_stock,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'VehicleEndTime')), toDateTime('1970-01-01 00:00:00')) AS vehicle_end_time,
    coalesce(parseDateTimeBestEffortOrNull(JSONExtractString(v, 'ModifiedDate')), toDateTime('1970-01-01 00:00:00')) AS report_modified_date,
    coalesce(JSONExtractString(v, 'GroupOfProductCode'), '') AS group_product_code,
    coalesce(JSONExtractString(v, 'GroupOfProductName'), '') AS group_product_name,
    coalesce(JSONExtractString(v, 'ProductCode'), '') AS product_code,
    coalesce(JSONExtractString(v, 'ProductName'), '') AS product_name,
    CAST(coalesce(JSONExtractString(v, 'LocationFromCode'), ''), 'LowCardinality(String)') AS location_from_code,
    CAST(coalesce(JSONExtractString(v, 'LocationFromName'), ''), 'LowCardinality(String)') AS location_from_name,
    coalesce(JSONExtractString(v, 'LocationToCode'), '') AS location_to_code,
    coalesce(JSONExtractString(v, 'LocationToName'), '') AS location_to_name,
    coalesce(JSONExtractRaw(v, 'GroupIds'), '[]') AS group_ids,
    coalesce(JSONExtractRaw(v, 'OrderIds'), '[]') AS order_ids,
    coalesce(JSONExtractString(v, 'ConstraintName'), '') AS constraint_name,
    coalesce(JSONExtractString(v, 'ConstraintNote'), '') AS constraint_note,
    if(empty(JSONExtractString(DataRun, 'DataReport')) OR (JSONExtractString(DataRun, 'DataReport') = '[]'), false, true) AS data_report,
    coalesce(_peerdb_is_deleted, 0) AS is_deleted
FROM analytics_workspace.dbo_OPS_Optimizer
LEFT ARRAY JOIN JSONExtractArrayRaw(coalesce(JSONExtractString(DataRun, 'DataReport'), '[]')) AS v


-- ════════════════════════════════════════════════════
-- Object: mv_stm_dropped  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_stm_dropped
REFRESH EVERY 8 MINUTE
(
    `ID_ORD_GroupProduct` Int32,
    `Mã đơn hàng` String,
    `Trạng thái đơn hàng` String,
    `LineNo` String,
    `QuantityBBGN` Float64,
    `Thời gian gửi thầu` DateTime64(9),
    `ETA (Giao hàng cho NPP)` DateTime64(9),
    `ATA đến` DateTime64(9),
    `ATA rời` DateTime64(9),
    `ID chuyến gửi thầu` Int32,
    `Tên ngắn nhà vận tải` String,
    `Mã nhà xe` String,
    `Loại xe vận hành` String,
    `Ngày tạo chuyến` DateTime64(9),
    `ETD chuyến gửi thầu` DateTime64(9),
    `ATD đến` DateTime64(9),
    `Giờ ra dock` DateTime64(9),
    `TG bắt buộc rời kho` DateTime64(9),
    `Thời gian đi` DateTime64(9),
    `Số chuyến` String,
    `Số xe` String,
    `Tài xế` String
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY tuple()
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = `sql-console:vy.tao@gosmartlog.com` SQL SECURITY DEFINER
AS SELECT
    ORD_GroupProduct.key_sk AS ID_ORD_GroupProduct,
    ORD_Order.code AS `Mã đơn hàng`,
    ORD_Order.status_name AS `Trạng thái đơn hàng`,
    substring(ORD_GroupProduct.code_sync, 1, if(length(ORD_GroupProduct.code_sync) > 0, length(ORD_GroupProduct.code_sync) - 1, 0)) AS LineNo,
    OPS_DITOGroupProduct.quantity_bbgn AS QuantityBBGN,
    OPS_DITOGroupProduct.tender_date AS `Thời gian gửi thầu`,
    OPS_DITOGroupProduct.eta AS `ETA (Giao hàng cho NPP)`,
    OPS_DITOGroupProduct.date_to_come AS `ATA đến`,
    OPS_DITOGroupProduct.date_to_leave AS `ATA rời`,
    OPS_DITOGroupProduct.trip_tender_id AS `ID chuyến gửi thầu`,
    masterdata_vendor.short_name AS `Tên ngắn nhà vận tải`,
    masterdata_vendor.code AS `Mã nhà xe`,
    OPS_DITOMaster.header_vehicle_group_name AS `Loại xe vận hành`,
    OPS_DITOMaster.created_date AS `Ngày tạo chuyến`,
    OPS_DITOMasterTender.etd AS `ETD chuyến gửi thầu`,
    OPS_DITOGroupProduct.date_from_come AS `ATD đến`,
    OPS_DockRegister.loading_end AS `Giờ ra dock`,
    OPS_DITOGroupProduct.required_departure_time AS `TG bắt buộc rời kho`,
    OPS_DITOGroupProduct.date_from_leave AS `Thời gian đi`,
    OPS_DITOMaster.code AS `Số chuyến`,
    OPS_DITOMaster.reg_no AS `Số xe`,
    OPS_DITOMaster.driver_name1 AS `Tài xế`
FROM stm_dwh_mondelez.dim_ord_order AS ORD_Order
LEFT JOIN stm_dwh_mondelez.dim_ord_product_group AS ORD_GroupProduct ON (ORD_GroupProduct.order_id = ORD_Order.key_sk) AND (ORD_GroupProduct.is_deleted = 0)
LEFT JOIN stm_dwh_mondelez.dim_ops_trip_detail AS OPS_DITOGroupProduct ON (ORD_GroupProduct.key_sk = OPS_DITOGroupProduct.order_group_product_id) AND (OPS_DITOGroupProduct.is_deleted = 0)
LEFT JOIN stm_dwh_mondelez.dim_ops_trip AS OPS_DITOMaster ON (OPS_DITOGroupProduct.trip_header_id = OPS_DITOMaster.key_sk) AND (OPS_DITOMaster.status_id != 13) AND (OPS_DITOMaster.is_deleted = 0)
LEFT JOIN analytics_workspace.mv_masterdata_vendor AS masterdata_vendor ON OPS_DITOMaster.vendor_id = masterdata_vendor.id
LEFT JOIN stm_dwh_mondelez.dim_ops_dock_register AS OPS_DockRegister ON (OPS_DITOMaster.key_sk = OPS_DockRegister.dito_master_id) AND (OPS_DockRegister.is_deleted = 0)
LEFT JOIN stm_dwh_mondelez.dim_ops_trip AS OPS_DITOMasterTender ON (OPS_DITOGroupProduct.trip_tender_id = OPS_DITOMasterTender.key_sk) AND (OPS_DITOMasterTender.status_id = 13) AND (OPS_DITOMasterTender.is_deleted = 0)
WHERE (ORD_Order.subcat_sevice_of_order_sk = 36) AND (ORD_Order.customer_id = '9') AND (ORD_Order.is_deleted = 0) AND (ORD_GroupProduct.code_sync IS NOT NULL) AND (ORD_GroupProduct.code_sync != '') AND ((OPS_DITOGroupProduct.sort_order = 1) OR (OPS_DITOGroupProduct.sort_order = -1))


-- ════════════════════════════════════════════════════
-- Object: mv_stocktype  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_stocktype
REFRESH EVERY 1 HOUR
(
    `group_of_cargo` Nullable(String) COMMENT 'Nhóm hàng',
    `brand` Nullable(String) COMMENT 'Brand',
    `storer_key` String COMMENT 'Mã chủ hàng',
    `whseid` String COMMENT 'Mã kho',
    `qty` Nullable(Decimal(38, 4)) COMMENT 'Sản lượng tồn,\r\n đơn vị masterunit/PCE/EA',
    `qty_cbm` Nullable(Decimal(38, 6)) COMMENT 'Sản lượng tồn,\r\n đơn vị CBM',
    `qty_ton` Nullable(Decimal(38, 6)) COMMENT 'Sản lượng tồn,\r\n đơn vị TON',
    `qty_cse` Nullable(Decimal(38, 4)) COMMENT 'Sản lượng tồn,\r\n đơn vị CSE',
    `qty_pl` Nullable(Decimal(38, 4)) COMMENT 'Sản lượng tồn,\r\n đơn vị PALLET',
    `qty_allocated` Nullable(Decimal(38, 4)) COMMENT 'Sản lượng tồn đã allocated,\r\n đơn vị masterunit/PCE/EA',
    `qty_allocated_cbm` Nullable(Decimal(38, 6)) COMMENT 'Sản lượng tồn đã allocated,\r\n đơn vị CBM',
    `qty_allocated_ton` Nullable(Decimal(38, 6)) COMMENT 'Sản lượng tồn đã allocated,\r\n đơn vị TON',
    `qty_allocated_cse` Nullable(Decimal(38, 4)) COMMENT 'Sản lượng tồn đã allocated,\r\n đơn vị CSE',
    `qty_allocated_pl` Nullable(Decimal(38, 4)) COMMENT 'Sản lượng tồn đã allocated,\r\n đơn vị PALLET',
    `qty_picked` Nullable(Decimal(38, 4)) COMMENT 'Sản lượng tồn đã picked,\r\n đơn vị masterunit/PCE/EA',
    `qty_picked_cbm` Nullable(Decimal(38, 6)) COMMENT 'Sản lượng tồn đã picked,\r\n đơn vị CBM',
    `qty_picked_ton` Nullable(Decimal(38, 6)) COMMENT 'Sản lượng tồn đã picked,\r\n đơn vị TON',
    `qty_picked_cse` Nullable(Decimal(38, 4)) COMMENT 'Sản lượng tồn đã picked,\r\n đơn vị CSE',
    `qty_picked_pl` Nullable(Decimal(38, 4)) COMMENT 'Sản lượng tồn đã picked,\r\n đơn vị PALLET'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (storer_key, whseid, group_of_cargo, brand)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    grouping_skubatch AS
    (
        SELECT
            l.storer_key AS storer_key,
            l.whseid AS whseid,
            l.sku AS sku,
            lot.lottable04 AS batch,
            sum(l.qty) AS qty,
            sum(l.qty * s.cbm_per_masterunit) AS qty_cbm,
            sum((l.qty * s.kg_per_masterunit) / 1000) AS qty_ton,
            ceil(sum(l.qty / nullIf(s.masterunit_per_cse, 0))) AS qty_cse,
            ceil(sum(l.qty / nullIf(s.masterunit_per_pallet, 0))) AS qty_pl,
            sum(l.qty_allocated) AS qty_allocated,
            sum(l.qty_allocated * s.cbm_per_masterunit) AS qty_allocated_cbm,
            sum((l.qty_allocated * s.kg_per_masterunit) / 1000) AS qty_allocated_ton,
            ceil(sum(l.qty_allocated / nullIf(s.masterunit_per_cse, 0))) AS qty_allocated_cse,
            ceil(sum(l.qty_allocated / nullIf(s.masterunit_per_pallet, 0))) AS qty_allocated_pl,
            sum(l.qty_picked) AS qty_picked,
            sum(l.qty_picked * s.cbm_per_masterunit) AS qty_picked_cbm,
            sum((l.qty_picked * s.kg_per_masterunit) / 1000) AS qty_picked_ton,
            ceil(sum(l.qty_picked / nullIf(s.masterunit_per_cse, 0))) AS qty_picked_cse,
            ceil(sum(l.qty_picked / nullIf(s.masterunit_per_pallet, 0))) AS qty_picked_pl
        FROM mondelez_swm_test.dim_lotxlocxid AS l
        FINAL
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS s ON (s.whseid = l.whseid) AND (s.item_code = l.sku)
        LEFT JOIN mondelez_swm_test.dim_lotattribute AS lot
        FINAL ON (lot.whseid = l.whseid) AND (lot.sku = l.sku) AND (lot.lot = l.lot) AND (lot.is_deleted = 0)
        WHERE (l.storer_key = 'MDLZ') AND (l.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (l.qty > 0) AND (l.is_deleted = 0) AND (NOT ((l.whseid = 'NKD') AND (upper(l.sku) IN ('LOSCAM', 'BACHTHUAN'))))
        GROUP BY
            l.storer_key,
            l.whseid,
            l.sku,
            lot.lottable04
    ),
    enriching_data AS
    (
        SELECT
            s.group_of_cargo,
            s.brand,
            sb.*
        FROM
        grouping_skubatch AS sb
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS s ON (s.whseid = sb.whseid) AND (s.item_code = sb.sku)
    )
SELECT
    group_of_cargo,
    brand,
    storer_key,
    whseid,
    sum(qty) AS qty,
    sum(qty_cbm) AS qty_cbm,
    sum(qty_ton) AS qty_ton,
    sum(qty_cse) AS qty_cse,
    sum(qty_pl) AS qty_pl,
    sum(qty_allocated) AS qty_allocated,
    sum(qty_allocated_cbm) AS qty_allocated_cbm,
    sum(qty_allocated_ton) AS qty_allocated_ton,
    sum(qty_allocated_cse) AS qty_allocated_cse,
    sum(qty_allocated_pl) AS qty_allocated_pl,
    sum(qty_picked) AS qty_picked,
    sum(qty_picked_cbm) AS qty_picked_cbm,
    sum(qty_picked_ton) AS qty_picked_ton,
    sum(qty_picked_cse) AS qty_picked_cse,
    sum(qty_picked_pl) AS qty_picked_pl
FROM
enriching_data
GROUP BY
    group_of_cargo,
    brand,
    storer_key,
    whseid


-- ════════════════════════════════════════════════════
-- Object: mv_swm_dropped  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_swm_dropped
REFRESH EVERY 8 MINUTE
(
    `biz_key` String,
    `WHSEID` String,
    `WHSEID_stm` String,
    `SO` String,
    `ORDERLINENUMBER` String,
    `TYPE` String,
    `Type Description` String,
    `STATUS` Nullable(String),
    `Item Code` String,
    `Tên hàng` String,
    `UOM` String,
    `Group of Cago` Nullable(String),
    `Brand` Nullable(String),
    `Group` String,
    `Customer Code` String,
    `Customer Name` String,
    `Remark 2` String,
    `ORIGINAL` Decimal(22, 8),
    `ORIGINAL CBM` Float64,
    `ORIGINAL KG` Float64,
    `ORIGINAL CSE` Nullable(Float64),
    `ORIGINAL PL` Nullable(Float64),
    `SHIPPED` Decimal(38, 8),
    `SHIPPED CBM` Float64,
    `SHIPPED KG` Float64,
    `SHIPPED CSE` Nullable(Float64),
    `SHIPPED PL` Nullable(Float64),
    `Delivery Date 1` DateTime64(9),
    `Actual Ship Date` DateTime64(9)
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY tuple()
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = `sql-console:vy.tao@gosmartlog.com` SQL SECURITY DEFINER
AS WITH group_pickdetail AS
    (
        SELECT
            storer_key,
            whseid,
            order_key,
            order_line_number,
            sum(qty) AS shipped
        FROM swm_dwh_mondelez.dim_pickdetail
        WHERE is_deleted = 0
        GROUP BY
            storer_key,
            whseid,
            order_key,
            order_line_number
    )
SELECT
    concat(orders.extern_order_key, orderdetail.order_line_number) AS biz_key,
    orderdetail.whseid AS WHSEID,
    if((orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3')), 'BKD', orderdetail.whseid) AS WHSEID_stm,
    orders.extern_order_key AS SO,
    orderdetail.order_line_number AS ORDERLINENUMBER,
    orders.type AS TYPE,
    masterdata_ordertype.description AS `Type Description`,
    multiIf(orders.status_code = '04', 'New', orders.status_code = '14', 'PartAllocate', orders.status_code = '17', 'Allocated', orders.status_code = '52', 'PartPick', orders.status_code = '55', 'Picked', orders.status_code = '92', 'PartShipped', orders.status_code = '95', 'ShipCompleted', orders.status_code = '72', 'InSorting', orders.status_code = '75', 'Sorted', orders.status_code = '82', 'InPacking', orders.status_code = '85', 'Packed', orders.status_code = '1', 'Cancel', orders.status_code = '31', 'PartPreAllocated', orders.status_code = '32', 'PreAllocated', orders.status_code = '2', 'Close', NULL) AS STATUS,
    orderdetail.sku AS `Item Code`,
    masterdata_sku.sku_name AS `Tên hàng`,
    orderdetail.uom AS UOM,
    masterdata_sku.group_of_cargo AS `Group of Cago`,
    masterdata_sku.brand AS Brand,
    masterdata_location.channel AS Group,
    orders.consignee_key AS `Customer Code`,
    masterdata_location.cus_location_name AS `Customer Name`,
    orders.notes2 AS `Remark 2`,
    orderdetail.original_qty AS ORIGINAL,
    orderdetail.original_qty * masterdata_sku.cbm_per_masterunit AS `ORIGINAL CBM`,
    orderdetail.original_qty * masterdata_sku.kg_per_masterunit AS `ORIGINAL KG`,
    orderdetail.original_qty / nullIf(masterdata_sku.masterunit_per_cse, 0) AS `ORIGINAL CSE`,
    orderdetail.original_qty / nullIf(masterdata_sku.masterunit_per_pallet, 0) AS `ORIGINAL PL`,
    group_pickdetail.shipped AS SHIPPED,
    group_pickdetail.shipped * masterdata_sku.cbm_per_masterunit AS `SHIPPED CBM`,
    group_pickdetail.shipped * masterdata_sku.kg_per_masterunit AS `SHIPPED KG`,
    group_pickdetail.shipped / nullIf(masterdata_sku.masterunit_per_cse, 0) AS `SHIPPED CSE`,
    group_pickdetail.shipped / nullIf(masterdata_sku.masterunit_per_pallet, 0) AS `SHIPPED PL`,
    orders.delivery_date AS `Delivery Date 1`,
    orders.actual_ship_date AS `Actual Ship Date`
FROM swm_dwh_mondelez.dim_orderdetail AS orderdetail
LEFT JOIN analytics_workspace.mv_masterdata_sku AS masterdata_sku ON (orderdetail.sku = masterdata_sku.item_code) AND (orderdetail.whseid = masterdata_sku.whseid)
LEFT JOIN swm_dwh_mondelez.dim_orders AS orders ON (orderdetail.storer_key = orders.storer_key) AND (orderdetail.whseid = orders.whseid) AND (orderdetail.order_key = orders.order_key)
LEFT JOIN analytics_workspace.mv_masterdata_location AS masterdata_location ON orders.consignee_key = masterdata_location.cus_location_code
LEFT JOIN
group_pickdetail ON (orderdetail.storer_key = group_pickdetail.storer_key) AND (orderdetail.whseid = group_pickdetail.whseid) AND (orderdetail.order_key = group_pickdetail.order_key) AND (orderdetail.order_line_number = group_pickdetail.order_line_number)
LEFT JOIN analytics_workspace.mv_masterdata_ordertype AS masterdata_ordertype ON (orders.whseid = masterdata_ordertype.whseid) AND (orders.type = masterdata_ordertype.code)
WHERE (orderdetail.storer_key = 'MDLZ') AND (orderdetail.is_deleted = 0) AND (((orderdetail.whseid = 'NKD') AND (orders.type IN ('01', '07', '08', '09', '240', 'XB2BMC', 'XTNPP'))) OR ((orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (orders.type IN ('01', '240')))) AND (orders.status_code IN ('1', '2')) AND (orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (orders.extern_order_key IS NOT NULL) AND (orderdetail.order_key IS NOT NULL)


-- ════════════════════════════════════════════════════
-- Object: mv_test_copack_clickhouse  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_test_copack_clickhouse
REFRESH EVERY 1 HOUR
(
    `whseid` String,
    `date_in_out` DateTime,
    `pallet_in` UInt64,
    `pallet_out` Nullable(Float64)
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (whseid, date_in_out)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = `sql-console:vy.tao@gosmartlog.com` SQL SECURITY DEFINER
AS WITH
    sku_stm AS
    (
        SELECT
            key_sk AS id_cus,
            code AS item_code_raw,
            replaceRegexpAll(trimBoth(code), '[ /-].*$', '') AS item_code,
            row_number() OVER (PARTITION BY replaceRegexpAll(trimBoth(code), '[ /-].*$', '') ORDER BY key_sk ASC) AS rn
        FROM stm_dwh_mondelez.subdim_cus_product
        WHERE is_deleted = 0
    ),
    masterdata_sku AS
    (
        SELECT
            sku.whseid AS whseid,
            sku.sku AS item_code,
            pack.pallet AS masterunit_per_pallet
        FROM
        sku_stm
        INNER JOIN swm_dwh_mondelez.dim_sku AS sku ON (sku.sku = sku_stm.item_code) AND (sku_stm.rn = 1)
        LEFT JOIN swm_dwh_mondelez.dim_pack AS pack ON (pack.whseid = sku.whseid) AND (pack.pack_key = sku.pack_key)
        WHERE (sku.storer_key = 'MDLZ') AND (sku.is_deleted = 0) AND (pack.is_deleted = 0)
    ),
    in_copack AS
    (
        SELECT
            toStartOfDay(r.date_received) AS ngay,
            r.whseid AS kho,
            count(r.palletid) AS pallet_in
        FROM swm_dwh_mondelez.dim_receiptdetail AS r
        LEFT JOIN swm_dwh_mondelez.dim_receipt AS rh ON (rh.receipt_key = r.receipt_key) AND (rh.whseid = r.whseid)
        WHERE (r.is_deleted = 0) AND (rh.is_deleted = 0) AND (((r.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (((rh.type = 'FGTN') AND (r.lottable06 IN ('0072', ''))) OR (rh.type = '05'))) OR ((r.whseid = 'NKD') AND (((rh.type = 'FGTN') AND (r.lottable06 IN ('0032', '0021'))) OR (rh.type = '05')))) AND (r.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (rh.status_code IN ('9', '5'))
        GROUP BY
            1,
            2
    ),
    group_out_copack AS
    (
        SELECT
            o.whseid AS kho,
            toStartOfDay(o.actual_ship_date) AS ngay,
            ceil(sum(p.qty / nullIf(s.masterunit_per_pallet, 0))) AS pallet_out
        FROM swm_dwh_mondelez.dim_orderdetail AS o
        LEFT JOIN swm_dwh_mondelez.dim_orders AS o_h ON (o.order_key = o_h.order_key) AND (o.whseid = o_h.whseid)
        LEFT JOIN swm_dwh_mondelez.dim_pickdetail AS p ON (o.order_key = p.order_key) AND (o.whseid = p.whseid) AND (o.order_line_number = p.order_line_number)
        LEFT JOIN swm_dwh_mondelez.dim_receiptdetail AS r ON (r.whseid = p.whseid) AND (r.lpnid = p.lpnid)
        LEFT JOIN
        masterdata_sku AS s ON (o.whseid = s.whseid) AND (o.sku = s.item_code)
        WHERE (o.storer_key = 'MDLZ') AND (o.is_deleted = 0) AND (o_h.is_deleted = 0) AND (p.is_deleted = 0) AND (r.is_deleted = 0) AND (o.status_code IN ('95', '92')) AND (((o.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (o_h.type IN ('05', 'CPK'))) OR ((o.whseid = 'NKD') AND (o_h.type IN ('04', '05', 'CPK'))))
        GROUP BY
            1,
            2
    ),
    out_copack AS
    (
        SELECT
            ngay,
            kho,
            sum(pallet_out) AS pallet_out
        FROM
        group_out_copack
        GROUP BY
            1,
            2
    )
SELECT
    coalesce(i.kho, o.kho) AS whseid,
    coalesce(i.ngay, o.ngay) AS date_in_out,
    i.pallet_in AS pallet_in,
    o.pallet_out AS pallet_out
FROM
in_copack AS i
FULL OUTER JOIN
out_copack AS o ON (i.ngay = o.ngay) AND (i.kho = o.kho)


-- ════════════════════════════════════════════════════
-- Object: mv_test_goods_receipt  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_test_goods_receipt
REFRESH EVERY 1 HOUR
(
    `date_received` Date COMMENT 'Ngày nhận hàng (theo date_received dòng receipt)',
    `whseid` String COMMENT 'Mã kho',
    `pallet` UInt64 COMMENT 'Số dòng đếm theo palletid'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (whseid, date_received)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS SELECT
    toDate(rd.date_received) AS date_received,
    rd.whseid AS whseid,
    count(rd.palletid) AS pallet
FROM mondelez_swm_test.dim_receiptdetail AS rd
FINAL
LEFT JOIN mondelez_swm_test.dim_receipt AS r
FINAL ON (r.storer_key = rd.storer_key) AND (r.whseid = rd.whseid) AND (r.receipt_key = rd.receipt_key) AND (r.is_deleted = 0)
WHERE (rd.storer_key = 'MDLZ') AND (rd.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (((rd.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (((r.type = 'FGTN') AND (rd.lottable06 IN ('0035', '0038', '0041', '0044', '0046', '0054'))) OR (r.type = '04'))) OR ((rd.whseid = 'NKD') AND (((r.type = 'FGTN') AND (rd.lottable06 IN ('0041', '0047', '0020', '0050', '0055'))) OR (r.type IN ('04', 'NB2BMC', 'NHXK'))))) AND (rd.status_code IN ('9')) AND (rd.is_deleted = 0)
GROUP BY
    toDate(rd.date_received),
    rd.whseid


-- ════════════════════════════════════════════════════
-- Object: mv_test_loose_picking  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_test_loose_picking
REFRESH EVERY 1 HOUR
(
    `whseid` String,
    `SO` String,
    `order_key` String,
    `actual_ship_date` DateTime64(9),
    `item_code` String,
    `product_name` String,
    `batch` DateTime64(9),
    `number_of_full_pallets` Nullable(Float64),
    `cse_full` Nullable(Float64),
    `cse_loose` Nullable(Float64),
    `pct_loose_picking` Nullable(Float64),
    `customer_code` String,
    `customer_name` String,
    `region` String
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY tuple()
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = `sql-console:vy.tao@gosmartlog.com` SQL SECURITY DEFINER
AS WITH
    sku_stm AS
    (
        SELECT
            products.id AS id_cus,
            products.code AS item_code_raw,
            replaceRegexpAll(trimBoth(products.code), '[ /-].*$', '') AS item_code,
            row_number() OVER (PARTITION BY replaceRegexpAll(trimBoth(products.code), '[ /-].*$', '') ORDER BY products.id ASC) AS rn
        FROM stm_dwh_mondelez.subdim_cus_product AS products
        LEFT JOIN stm_dwh_mondelez.subdim_cus_group_of_product AS group_products ON products.group_of_product_id = group_products.id
    ),
    masterdata_sku AS
    (
        SELECT
            sku_stm.id_cus,
            sku.whseid AS whseid,
            sku.sku AS item_code,
            sku.descr AS sku_name,
            sku.category,
            multiIf((upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (left(sku.sku, 1) = '2'), 'PM', (upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (sku.sku LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.category)) IN ('OTHER', 'ORTHER')) AND (left(sku.sku, 1) != '2') AND (sku.sku NOT LIKE '%SAMPLE%'), 'EQUIPMENT', (upper(trimBoth(sku.category)) IN ('MOONCAKE')), 'MOONCAKE', (upper(trimBoth(sku.category)) IN ('PALLET')), 'EQUIPMENT', (upper(trimBoth(sku.category)) IN ('POSM', 'OFFBOM')), 'POSM/OFFBOM', (upper(trimBoth(sku.category)) IN ('TEST')), 'TEST', (upper(trimBoth(sku.category)) IN ('BUN', 'BUN1', 'BUN2')), 'FRESH', (upper(trimBoth(sku.category)) IN ('FRESH')), 'FRESH', (upper(trimBoth(sku.category)) IN ('DRY')), 'DRY', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (left(sku.sku, 1) = '2'), 'PM', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (sku.sku LIKE '%SAMPLE%'), 'TEST', (upper(trimBoth(sku.category)) IN ('LOCAL', 'IMPORT', 'EXPORT', 'TET')) AND (left(sku.sku, 1) != '2') AND (sku.sku NOT LIKE '%SAMPLE%'), convert_cargo.convert_skugroup, (sku.category IS NULL) AND (left(sku.sku, 2) = 'ZW'), 'POSM/OFFBOM', (sku.category IS NULL) AND (left(sku.sku, 1) = '2'), 'PM', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%BAO BI%'), 'PM', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%BAOBI%'), 'PM', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%PL%'), 'EQUIPMENT', (sku.category IS NULL) AND (upper(sku.sku) LIKE '%PPE%'), 'EQUIPMENT', NULL) AS group_of_cargo,
            multiIf(substring(sku.sku, 1, 1) != '4', 'Other', match(upper(sku.descr), '(^| )SOLITE( |$)'), 'Solite', match(upper(sku.descr), '(^|[^A-Z0-9])AFC([^A-Z0-9]|$)'), 'AFC', match(upper(sku.descr), '(^|[^A-Z0-9])LU([^A-Z0-9]|$)'), 'Lu', match(upper(sku.descr), '(^|[^A-Z0-9])COSY([^A-Z0-9]|$)'), 'Cosy', match(upper(sku.descr), '(^|[^A-Z0-9])OREO([^A-Z0-9]|$)'), 'Oreo', match(upper(sku.descr), '(^|[^A-Z0-9])TET([^A-Z0-9]|$)'), 'Tết', match(upper(sku.descr), '(^|[^A-Z0-9])TRUNG THU([^A-Z0-9]|$)'), 'Trung Thu', match(upper(sku.descr), '(^|[^A-Z0-9])SLIDE([^A-Z0-9]|$)'), 'Slide', match(upper(sku.descr), '(^|[^A-Z0-9])(KD|KINH ĐÔ|KINH DO)([^A-Z0-9]|$)'), 'KD', match(upper(sku.descr), '(^|[^A-Z0-9])RITZ([^A-Z0-9]|$)'), 'RITZ', match(upper(sku.descr), '(^|[^A-Z0-9])TOBLERONE([^A-Z0-9]|$)'), 'Toblerone', NULL) AS brand,
            sku.std_cube AS cbm_per_masterunit,
            sku.std_grossweight AS kg_per_masterunit,
            pack.inner_pack AS masterunit_per_cse,
            pack.pallet AS masterunit_per_pallet
        FROM
        sku_stm
        FULL OUTER JOIN swm_dwh_mondelez.dim_sku AS sku ON (sku.storer_key = 'MDLZ') AND (sku_stm.rn = 1) AND (sku_stm.item_code = sku.sku)
        LEFT JOIN swm_dwh_mondelez.dim_pack AS pack ON (pack.whseid = sku.whseid) AND (pack.pack_key = sku.pack_key)
        LEFT JOIN internal.convert_cargo AS convert_cargo ON (convert_cargo.whseid = 'BKD1') AND (sku.sku = convert_cargo.sku)
        WHERE sku.storer_key = 'MDLZ'
    ),
    group_pickdetail AS
    (
        SELECT
            pickdetail.storer_key,
            pickdetail.whseid,
            pickdetail.order_key,
            pickdetail.order_line_number,
            pickdetail.lpnid,
            sum(pickdetail.qty) AS SHIPPED
        FROM swm_dwh_mondelez.dim_pickdetail AS pickdetail
        GROUP BY
            1,
            2,
            3,
            4,
            5
    ),
    enriching_data AS
    (
        SELECT
            orders.whseid AS whseid,
            orders.extern_order_key AS SO,
            orders.order_key AS order_key,
            orders.actual_ship_date AS actual_ship_date,
            orderdetail.order_line_number,
            orders.consignee_key AS `Customer Code`,
            masterdata_location.cus_location_name AS `Customer Name`,
            masterdata_location.group_area_name AS `Khu vực đội xe`,
            orderdetail.sku AS item_code,
            masterdata_sku.sku_name AS product_name,
            masterdata_sku.group_of_cargo AS `Group of Cago`,
            rd.lottable04 AS batch,
            orderdetail.original_qty AS ORIGINAL,
            orderdetail.original_qty * cbm_per_masterunit AS `ORIGINAL CBM`,
            orderdetail.original_qty * kg_per_masterunit AS `ORIGINAL KG`,
            orderdetail.original_qty / nullIf(masterunit_per_cse, 0) AS `ORIGINAL CSE`,
            orderdetail.original_qty / nullIf(masterunit_per_pallet, 0) AS `ORIGINAL PL`,
            p.SHIPPED AS SHIPPED,
            p.SHIPPED * cbm_per_masterunit AS `SHIPPED CBM`,
            p.SHIPPED * kg_per_masterunit AS `SHIPPED KG`,
            p.SHIPPED / nullIf(masterunit_per_cse, 0) AS `SHIPPED CSE`,
            p.SHIPPED / nullIf(masterunit_per_pallet, 0) AS `SHIPPED PL`,
            cbm_per_masterunit,
            kg_per_masterunit,
            masterunit_per_cse,
            masterunit_per_pallet,
            masterunit_per_pallet / nullIf(masterunit_per_cse, 0) AS cse_per_pallet
        FROM swm_dwh_mondelez.dim_orderdetail AS orderdetail
        LEFT JOIN
        masterdata_sku ON (orderdetail.whseid = masterdata_sku.whseid) AND (orderdetail.sku = masterdata_sku.item_code)
        LEFT JOIN swm_dwh_mondelez.dim_orders AS orders ON (orderdetail.storer_key = orders.storer_key) AND (orderdetail.whseid = orders.whseid) AND (orderdetail.order_key = orders.order_key)
        LEFT JOIN
        group_pickdetail AS p ON (orderdetail.storer_key = p.storer_key) AND (orderdetail.whseid = p.whseid) AND (orderdetail.order_key = p.order_key) AND (orderdetail.order_line_number = p.order_line_number)
        LEFT JOIN swm_dwh_mondelez.dim_receiptdetail AS rd ON (rd.storer_key = p.storer_key) AND (rd.whseid = p.whseid) AND (rd.lpnid = p.lpnid)
        LEFT JOIN analytics_workspace.mv_masterdata_location AS masterdata_location ON orders.consignee_key = masterdata_location.code
        WHERE (orderdetail.storer_key = 'MDLZ') AND (orders.status_code = '95') AND (orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (orders.extern_order_key IS NOT NULL) AND (orderdetail.order_key IS NOT NULL) AND (((orderdetail.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (orders.type IN ('01', '240'))) OR ((orderdetail.whseid = 'NKD') AND (orders.type IN ('01', '07', '08', '09', '240', 'XB2BMC', 'XTNPP'))))
    ),
    summary AS
    (
        SELECT
            whseid,
            SO,
            order_key,
            actual_ship_date,
            item_code,
            product_name,
            batch,
            floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) AS number_of_full_pallets,
            floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) * max(cse_per_pallet) AS cse_full,
            sum(`SHIPPED CSE`) - (floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) * max(cse_per_pallet)) AS cse_loose,
            (sum(`SHIPPED CSE`) - (floor(sum(`SHIPPED CSE`) / nullIf(max(cse_per_pallet), 0)) * max(cse_per_pallet))) / nullIf(sum(`SHIPPED CSE`), 0) AS pct_loose_picking
        FROM
        enriching_data
        GROUP BY
            1,
            2,
            3,
            4,
            5,
            6,
            7
    )
SELECT
    summary.*,
    enriching_data.`Customer Code` AS customer_code,
    enriching_data.`Customer Name` AS customer_name,
    enriching_data.`Khu vực đội xe` AS region
FROM
summary
LEFT JOIN
enriching_data ON (summary.SO = enriching_data.SO) AND (summary.item_code = enriching_data.item_code) AND (summary.batch = enriching_data.batch)


-- ════════════════════════════════════════════════════
-- Object: mv_test_stocktype  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_test_stocktype
REFRESH EVERY 20 MINUTE
(
    `group_of_cargo` Nullable(String),
    `brand` Nullable(String),
    `storer_key` String,
    `whseid` String,
    `qty` Decimal(38, 8),
    `qty_cbm` Float64,
    `qty_ton` Float64,
    `qty_cse` Nullable(Float64),
    `qty_pl` Nullable(Float64),
    `qty_allocated` Decimal(38, 8),
    `qty_allocated_cbm` Float64,
    `qty_allocated_ton` Float64,
    `qty_allocated_cse` Nullable(Float64),
    `qty_allocated_pl` Nullable(Float64),
    `qty_picked` Decimal(38, 8),
    `qty_picked_cbm` Float64,
    `qty_picked_ton` Float64,
    `qty_picked_cse` Nullable(Float64),
    `qty_picked_pl` Nullable(Float64)
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY tuple()
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = `sql-console:vy.tao@gosmartlog.com` SQL SECURITY DEFINER
AS WITH
    grouping_skubatch AS
    (
        SELECT
            l.storer_key AS storer_key,
            l.whseid AS whseid,
            l.sku AS sku,
            lot.lottable04 AS BATCH,
            sum(l.qty) AS qty,
            sum(l.qty * s.cbm_per_masterunit) AS qty_cbm,
            sum((l.qty * s.kg_per_masterunit) / 1000) AS qty_ton,
            ceil(sum(l.qty / nullIf(s.masterunit_per_cse, 0))) AS qty_cse,
            ceil(sum(l.qty / nullIf(s.masterunit_per_pallet, 0))) AS qty_pl,
            sum(l.qty_allocated) AS qty_allocated,
            sum(l.qty_allocated * s.cbm_per_masterunit) AS qty_allocated_cbm,
            sum((l.qty_allocated * s.kg_per_masterunit) / 1000) AS qty_allocated_ton,
            ceil(sum(l.qty_allocated / nullIf(s.masterunit_per_cse, 0))) AS qty_allocated_cse,
            ceil(sum(l.qty_allocated / nullIf(s.masterunit_per_pallet, 0))) AS qty_allocated_pl,
            sum(l.qty_picked) AS qty_picked,
            sum(l.qty_picked * s.cbm_per_masterunit) AS qty_picked_cbm,
            sum((l.qty_picked * s.kg_per_masterunit) / 1000) AS qty_picked_ton,
            ceil(sum(l.qty_picked / nullIf(s.masterunit_per_cse, 0))) AS qty_picked_cse,
            ceil(sum(l.qty_picked / nullIf(s.masterunit_per_pallet, 0))) AS qty_picked_pl
        FROM swm_dwh_mondelez.dim_lotxlocxid AS l
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS s ON (s.whseid = l.whseid) AND (s.item_code = l.sku)
        LEFT JOIN swm_dwh_mondelez.dim_lotattribute AS lot ON (lot.whseid = l.whseid) AND (lot.sku = l.sku) AND (lot.lot = l.lot) AND (lot.is_deleted = 0)
        WHERE (l.storer_key = 'MDLZ') AND (l.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (l.qty > 0) AND (l.is_deleted = 0) AND (NOT ((l.whseid = 'NKD') AND (upper(l.sku) IN ('LOSCAM', 'BACHTHUAN'))))
        GROUP BY
            storer_key,
            whseid,
            sku,
            BATCH
    ),
    enriching_data AS
    (
        SELECT
            s.group_of_cargo,
            s.brand,
            sb.*
        FROM
        grouping_skubatch AS sb
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS s ON (s.whseid = sb.whseid) AND (s.item_code = sb.sku)
    )
SELECT
    group_of_cargo,
    brand,
    storer_key,
    whseid,
    sum(qty) AS qty,
    sum(qty_cbm) AS qty_cbm,
    sum(qty_ton) AS qty_ton,
    sum(qty_cse) AS qty_cse,
    sum(qty_pl) AS qty_pl,
    sum(qty_allocated) AS qty_allocated,
    sum(qty_allocated_cbm) AS qty_allocated_cbm,
    sum(qty_allocated_ton) AS qty_allocated_ton,
    sum(qty_allocated_cse) AS qty_allocated_cse,
    sum(qty_allocated_pl) AS qty_allocated_pl,
    sum(qty_picked) AS qty_picked,
    sum(qty_picked_cbm) AS qty_picked_cbm,
    sum(qty_picked_ton) AS qty_picked_ton,
    sum(qty_picked_cse) AS qty_picked_cse,
    sum(qty_picked_pl) AS qty_picked_pl
FROM
enriching_data
GROUP BY
    group_of_cargo,
    brand,
    storer_key,
    whseid


-- ════════════════════════════════════════════════════
-- Object: mv_transfer_in_out  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_transfer_in_out
REFRESH EVERY 1 HOUR
(
    `whseid` String COMMENT 'Mã kho',
    `date_transfer` Nullable(Date) COMMENT 'Ngày trung chuyển',
    `pallet_in` Nullable(Float64) COMMENT 'Số pallet trung chuyển vào',
    `pallet_out` Nullable(Float64) COMMENT 'Số pallet trung chuyển ra',
    `status` Nullable(String) COMMENT 'Trạng thái trung chuyển: xuất siêu/nhập siêu'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (whseid, date_transfer)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    transfer_in AS
    (
        SELECT
            toDate(rd.date_received) AS ngay,
            rd.whseid,
            count(rd.palletid) AS pallet_transfer_in
        FROM mondelez_swm_test.dim_receiptdetail AS rd
        FINAL
        LEFT JOIN mondelez_swm_test.dim_receipt AS r
        FINAL ON (r.storer_key = rd.storer_key) AND (r.whseid = rd.whseid) AND (r.receipt_key = rd.receipt_key) AND (r.is_deleted = 0)
        WHERE (rd.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (((rd.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (r.type IN ('02', '08', 'ICDMT', 'ICD'))) OR ((rd.whseid = 'NKD') AND (r.type IN ('09')))) AND (rd.status_code IN ('9')) AND (rd.storer_key = 'MDLZ') AND (rd.is_deleted = 0)
        GROUP BY
            1,
            2
    ),
    shipped_line AS
    (
        SELECT
            toDate(oh.actual_ship_date) AS ngay,
            od.whseid AS whseid,
            oh.extern_order_key AS extern_order_key,
            od.order_key AS order_key,
            r.lottable04 AS batch,
            od.sku AS sku,
            ceil(sum(p.qty / nullIf(sku.masterunit_per_pallet, 0))) AS pallet_out
        FROM mondelez_swm_test.dim_orderdetail AS od
        FINAL
        LEFT JOIN mondelez_swm_test.dim_orders AS oh
        FINAL ON (oh.storer_key = od.storer_key) AND (oh.whseid = od.whseid) AND (oh.order_key = od.order_key) AND (oh.is_deleted = 0)
        LEFT JOIN mondelez_swm_test.dim_pickdetail AS p
        FINAL ON (od.storer_key = p.storer_key) AND (od.whseid = p.whseid) AND (od.order_key = p.order_key) AND (od.order_line_number = p.order_line_number) AND (p.is_deleted = 0)
        LEFT JOIN mondelez_swm_test.dim_receiptdetail AS r
        FINAL ON (r.storer_key = p.storer_key) AND (r.whseid = p.whseid) AND (r.lpnid = p.lpnid) AND (r.is_deleted = 0)
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (sku.whseid = od.whseid) AND (sku.item_code = od.sku)
        WHERE (od.storer_key = 'MDLZ') AND (od.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (((od.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (oh.type IN ('02', '03', 'ICD', 'ICDK12', 'ICDMT', 'ICDMC', 'ICDSFG'))) OR ((od.whseid = 'NKD') AND (oh.type IN ('03', 'GMDGT', 'TLLMC', 'CKN')))) AND (od.status_code IN ('95')) AND (od.is_deleted = 0)
        GROUP BY
            1,
            2,
            3,
            4,
            5,
            6
    ),
    transfer_out AS
    (
        SELECT
            s.ngay AS ngay,
            s.whseid AS whseid,
            sum(s.pallet_out) AS pallet_transfer_out
        FROM
        shipped_line AS s
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS sku ON (sku.whseid = s.whseid) AND (sku.item_code = s.sku)
        GROUP BY
            1,
            2
    ),
    final_table AS
    (
        SELECT
            coalesce(i.whseid, o.whseid) AS whseid,
            coalesce(i.ngay, o.ngay) AS date_transfer,
            coalesce(i.pallet_transfer_in, 0) AS pallet_in,
            coalesce(o.pallet_transfer_out, 0) AS pallet_out,
            multiIf(coalesce(i.pallet_transfer_in, 0) > coalesce(o.pallet_transfer_out, 0), 'Nhập Siêu', coalesce(i.pallet_transfer_in, 0) < coalesce(o.pallet_transfer_out, 0), 'Xuất Siêu', 'Cân Bằng') AS status
        FROM
        transfer_in AS i
        FULL OUTER JOIN
        transfer_out AS o ON (i.whseid = o.whseid) AND (i.ngay = o.ngay)
    )
SELECT *
FROM
final_table
ORDER BY
    whseid ASC,
    date_transfer ASC


-- ════════════════════════════════════════════════════
-- Object: mv_vfr_gui_thau  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_vfr_gui_thau
REFRESH EVERY 1 HOUR
(
    `id_chuyen_gui_thau` String,
    `id_chuyen_van_hanh` String,
    `ma_chuyen_van_hanh` String,
    `trang_thai_chuyen` String,
    `ma_don_hang` String,
    `dich_vu_van_chuyen` String,
    `tender_date` Nullable(DateTime('UTC')),
    `etd_gt` Nullable(DateTime('UTC')),
    `eta_gt` Nullable(DateTime('UTC')),
    `etd_vh` Nullable(DateTime('UTC')),
    `atd_vh` Nullable(DateTime('UTC')),
    `eta_vh` Nullable(DateTime('UTC')),
    `ata_vh` Nullable(DateTime('UTC')),
    `so_xe` Nullable(String),
    `tai_xe` Nullable(String),
    `ma_nha_van_tai` Nullable(String),
    `nha_van_tai` Nullable(String),
    `nhom_hang_hoa` String,
    `ma_diem_nhan` Nullable(String),
    `diem_nhan` Nullable(String),
    `ma_diem_giao` Nullable(String),
    `diem_giao` Nullable(String),
    `ma_khu_vuc_doi_xe` Nullable(String),
    `khu_vuc_doi_xe` Nullable(String),
    `loai_boc_xep` Nullable(String),
    `loai_dia_diem` Nullable(String),
    `ma_loai_xe_gui_thau` String,
    `loai_xe_gui_thau` String,
    `ma_loai_xe_van_hanh` String,
    `loai_xe_van_hanh` String,
    `tan_dang_ky` String,
    `cbm_dang_ky` String,
    `tan_ke_hoach` Nullable(Float64),
    `tan_nhan` Nullable(Float64),
    `tan_giao` Nullable(Float64),
    `cbm_ke_hoach` Nullable(Float64),
    `cbm_nhan` Nullable(Float64),
    `cbm_giao` Nullable(Float64),
    `vfr_theo_tan` Float64,
    `vfr_theo_khoi` Float64,
    `vfr_max` Float64,
    `phan_loai_vfr` String
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (id_chuyen_gui_thau, ma_chuyen_van_hanh)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH base_dt AS
    (
        SELECT
            key_sk,
            trip_tender_id,
            trip_header_id,
            status_name,
            tender_date,
            order_group_product_id,
            location_from_id,
            location_to_id,
            ton,
            ton_tranfer,
            ton_bbgn,
            cbm,
            cbm_tranfer,
            cbm_bbgn
        FROM stm_dwh_mondelez.dim_ops_trip_detail
        WHERE (trip_header_id != -1) AND (trip_tender_id != -1)
    )
SELECT
    bd.*,
    greatest(ifNull(bd.vfr_theo_tan, 0.), ifNull(bd.vfr_theo_khoi, 0.)) AS vfr_max,
    if(ifNull(bd.vfr_theo_tan, 0.) >= ifNull(bd.vfr_theo_khoi, 0.), 'Tấn', 'Khối') AS phan_loai_vfr
FROM
(
    SELECT
        dt.trip_tender_id AS id_chuyen_gui_thau,
        arrayStringConcat(groupUniqArray(toString(dt.trip_header_id)), ', ') AS id_chuyen_van_hanh,
        arrayStringConcat(groupUniqArray(t.code), ', ') AS ma_chuyen_van_hanh,
        arrayStringConcat(groupUniqArray(dt.status_name), ', ') AS trang_thai_chuyen,
        arrayStringConcat(groupUniqArray(o.code), ', ') AS ma_don_hang,
        arrayStringConcat(groupUniqArray(o.service_name), ', ') AS dich_vu_van_chuyen,
        max(dt.tender_date) AS tender_date,
        max(tt.etd) AS etd_gt,
        max(tt.eta) AS eta_gt,
        max(t.etd) AS etd_vh,
        max(t.atd) AS atd_vh,
        max(t.eta) AS eta_vh,
        max(t.ata) AS ata_vh,
        argMax(t.reg_no, dt.order_group_product_id) AS so_xe,
        argMax(t.driver_name1, dt.order_group_product_id) AS tai_xe,
        argMax(nvt.code, dt.order_group_product_id) AS ma_nha_van_tai,
        argMax(nvt.short_name, dt.order_group_product_id) AS nha_van_tai,
        arrayStringConcat(groupUniqArray(gsku.group_name), ', ') AS nhom_hang_hoa,
        argMax(order_catfrom.code, dt.order_group_product_id) AS ma_diem_nhan,
        argMax(order_catfrom.location, dt.order_group_product_id) AS diem_nhan,
        argMax(order_catto.code, dt.order_group_product_id) AS ma_diem_giao,
        argMax(order_catto.location, dt.order_group_product_id) AS diem_giao,
        argMax(kv.code, dt.order_group_product_id) AS ma_khu_vuc_doi_xe,
        argMax(kv.area_name, dt.order_group_product_id) AS khu_vuc_doi_xe,
        multiIf(argMax(order_catto.unloading_type_id, dt.order_group_product_id) = -1, 'Loose', argMax(order_catto.unloading_type_id, dt.order_group_product_id) = 1, 'Full Pallet', toString(argMax(order_catto.unloading_type_id, dt.order_group_product_id))) AS loai_boc_xep,
        argMax(ldd.group_name, dt.order_group_product_id) AS loai_dia_diem,
        arrayStringConcat(groupUniqArray(lxvh.code), ', ') AS ma_loai_xe_van_hanh,
        arrayStringConcat(groupUniqArray(t.header_vehicle_group_name), ', ') AS loai_xe_van_hanh,
        arrayStringConcat(groupUniqArray(lxgt.code), ', ') AS ma_loai_xe_gui_thau,
        arrayStringConcat(groupUniqArray(tt.tender_vehicle_group_name), ', ') AS loai_xe_gui_thau,
        arrayStringConcat(groupUniqArray(lxgt.ton), ', ') AS tan_dang_ky,
        arrayStringConcat(groupUniqArray(lxgt.cbm), ', ') AS cbm_dang_ky,
        sumIf(dt.ton, ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) AS tan_ke_hoach,
        sumIf(dt.ton_tranfer, ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) AS tan_nhan,
        sumIf(dt.ton_bbgn, ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) AS tan_giao,
        sumIf(dt.cbm, ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) AS cbm_ke_hoach,
        sumIf(dt.cbm_tranfer, ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) AS cbm_nhan,
        sumIf(dt.cbm_bbgn, ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) AS cbm_giao,
        ifNull(least((sumIf(ifNull(dt.ton_tranfer, 0), ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) * 100.) / nullIf(max(ifNull(lxgt.ton, 0)), 0), 100.), 0.) AS vfr_theo_tan,
        ifNull(least((sumIf(ifNull(dt.cbm_tranfer, 0), ifNull(dt.location_from_id = order_cusfrom.subcat_location_sk, 0)) * 100.) / nullIf(max(ifNull(lxgt.cbm, 0)), 0), 100.), 0.) AS vfr_theo_khoi
    FROM
    base_dt AS dt
    LEFT JOIN stm_dwh_mondelez.dim_ops_trip AS t ON dt.trip_header_id = t.key_sk
    LEFT JOIN stm_dwh_mondelez.subdim_cus_customer AS nvt ON t.vendor_id = nvt.key_sk
    INNER JOIN stm_dwh_mondelez.dim_ops_trip AS tt ON (dt.trip_tender_id = tt.key_sk) AND (tt.tender_group_vehicle_sk != -1)
    INNER JOIN stm_dwh_mondelez.dim_ord_product_group AS dpg ON dt.order_group_product_id = dpg.key_sk
    INNER JOIN stm_dwh_mondelez.dim_ord_order AS o ON (dpg.order_id = o.key_sk) AND (o.service_code = 'XB')
    LEFT JOIN stm_dwh_mondelez.dim_ord_product AS sku ON dpg.id = sku.key_sk
    LEFT JOIN stm_dwh_mondelez.subdim_cus_group_of_product AS gsku ON sku.subcus_group_of_product_sk = gsku.key_sk
    INNER JOIN stm_dwh_mondelez.dim_cus_location AS order_cusfrom ON dpg.location_from_id = order_cusfrom.key_sk
    INNER JOIN stm_dwh_mondelez.subdim_cat_location AS order_catfrom ON order_cusfrom.subcat_location_sk = order_catfrom.key_sk
    INNER JOIN stm_dwh_mondelez.dim_cus_location AS order_custo ON dpg.location_to_id = order_custo.key_sk
    INNER JOIN stm_dwh_mondelez.subdim_cat_location AS order_catto ON order_custo.subcat_location_sk = order_catto.key_sk
    LEFT JOIN stm_dwh_mondelez.subdim_cat_group_of_location AS ldd ON order_catto.group_of_location_id = ldd.key_sk
    LEFT JOIN stm_dwh_mondelez.subdim_cat_area AS kv ON order_catto.area_id = kv.key_sk
    LEFT JOIN stm_dwh_mondelez.subdim_cat_group_of_vehicle AS lxvh ON t.header_group_vehicle_sk = lxvh.key_sk
    LEFT JOIN stm_dwh_mondelez.subdim_cat_group_of_vehicle AS lxgt ON tt.tender_group_vehicle_sk = lxgt.key_sk
    WHERE t.status_id > 98
    GROUP BY dt.trip_tender_id
) AS bd


-- ════════════════════════════════════════════════════
-- Object: mv_vfr_van_hanh  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_vfr_van_hanh
REFRESH EVERY 1 HOUR
(
    `id_chuyen_gui_thau` String,
    `id_chuyen_van_hanh` Nullable(Int32),
    `ma_chuyen_van_hanh` String,
    `trang_thai_chuyen` String,
    `ma_don_hang` String,
    `dich_vu_van_chuyen` String,
    `tender_date` Nullable(DateTime('UTC')),
    `etd_gt` Nullable(DateTime('UTC')),
    `eta_gt` Nullable(DateTime('UTC')),
    `etd_vh` Nullable(DateTime('UTC')),
    `atd_vh` Nullable(DateTime('UTC')),
    `eta_vh` Nullable(DateTime('UTC')),
    `ata_vh` Nullable(DateTime('UTC')),
    `so_xe` Nullable(String),
    `tai_xe` Nullable(String),
    `ma_nha_van_tai` Nullable(String),
    `nha_van_tai` Nullable(String),
    `nhom_hang_hoa` String,
    `ma_diem_nhan` Nullable(String),
    `diem_nhan` Nullable(String),
    `ma_diem_giao` Nullable(String),
    `diem_giao` Nullable(String),
    `ma_khu_vuc_doi_xe` Nullable(String),
    `khu_vuc_doi_xe` Nullable(String),
    `loai_boc_xep` Nullable(String),
    `loai_dia_diem` Nullable(String),
    `ma_loai_xe_gui_thau` String,
    `loai_xe_gui_thau` String,
    `ma_loai_xe_van_hanh` String,
    `loai_xe_van_hanh` String,
    `tan_dang_ky` String,
    `cbm_dang_ky` String,
    `tan_ke_hoach` Nullable(Float64),
    `tan_nhan` Nullable(Float64),
    `tan_giao` Nullable(Float64),
    `cbm_ke_hoach` Nullable(Float64),
    `cbm_nhan` Nullable(Float64),
    `cbm_giao` Nullable(Float64),
    `vfr_theo_tan` Float64,
    `vfr_theo_khoi` Float64,
    `vfr_max` Float64,
    `phan_loai_vfr` String
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (ma_chuyen_van_hanh, id_chuyen_gui_thau)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH base_dt AS
    (
        SELECT
            key_sk,
            trip_tender_id,
            trip_header_id,
            status_name,
            tender_date,
            order_group_product_id,
            location_from_id,
            location_to_id,
            ton,
            ton_tranfer,
            ton_bbgn,
            cbm,
            cbm_tranfer,
            cbm_bbgn
        FROM stm_dwh_mondelez.dim_ops_trip_detail
        WHERE (trip_header_id != -1) AND (trip_tender_id != -1)
    )
SELECT
    bd.*,
    greatest(ifNull(bd.vfr_theo_tan, 0.), ifNull(bd.vfr_theo_khoi, 0.)) AS vfr_max,
    if(ifNull(bd.vfr_theo_tan, 0.) >= ifNull(bd.vfr_theo_khoi, 0.), 'Tấn', 'Khối') AS phan_loai_vfr
FROM
(
    SELECT
        arrayStringConcat(groupUniqArray(toString(dt.trip_tender_id)), ', ') AS id_chuyen_gui_thau,
        dt.trip_header_id AS id_chuyen_van_hanh,
        arrayStringConcat(groupUniqArray(t.code), ', ') AS ma_chuyen_van_hanh,
        arrayStringConcat(groupUniqArray(dt.status_name), ', ') AS trang_thai_chuyen,
        arrayStringConcat(groupUniqArray(o.code), ', ') AS ma_don_hang,
        arrayStringConcat(groupUniqArray(o.service_name), ', ') AS dich_vu_van_chuyen,
        max(dt.tender_date) AS tender_date,
        max(tt.etd) AS etd_gt,
        max(tt.eta) AS eta_gt,
        max(t.etd) AS etd_vh,
        max(t.atd) AS atd_vh,
        max(t.eta) AS eta_vh,
        max(t.ata) AS ata_vh,
        argMax(t.reg_no, dt.order_group_product_id) AS so_xe,
        argMax(t.driver_name1, dt.order_group_product_id) AS tai_xe,
        argMax(nvt.code, dt.order_group_product_id) AS ma_nha_van_tai,
        argMax(nvt.short_name, dt.order_group_product_id) AS nha_van_tai,
        arrayStringConcat(groupUniqArray(gsku.group_name), ', ') AS nhom_hang_hoa,
        argMax(order_catfrom.code, dt.order_group_product_id) AS ma_diem_nhan,
        argMax(order_catfrom.location, dt.order_group_product_id) AS diem_nhan,
        argMax(order_catto.code, dt.order_group_product_id) AS ma_diem_giao,
        argMax(order_catto.location, dt.order_group_product_id) AS diem_giao,
        argMax(kv.code, dt.order_group_product_id) AS ma_khu_vuc_doi_xe,
        argMax(kv.area_name, dt.order_group_product_id) AS khu_vuc_doi_xe,
        multiIf(argMax(order_catto.unloading_type_id, dt.order_group_product_id) = '-1', 'Loose', argMax(order_catto.unloading_type_id, dt.order_group_product_id) = 1, 'Full Pallet', toString(argMax(order_catto.unloading_type_id, dt.order_group_product_id))) AS loai_boc_xep,
        argMax(ldd.group_name, dt.order_group_product_id) AS loai_dia_diem,
        arrayStringConcat(groupUniqArray(lxgt.code), ', ') AS ma_loai_xe_gui_thau,
        arrayStringConcat(groupUniqArray(tt.tender_vehicle_group_name), ', ') AS loai_xe_gui_thau,
        arrayStringConcat(groupUniqArray(lxvh.code), ', ') AS ma_loai_xe_van_hanh,
        arrayStringConcat(groupUniqArray(t.header_vehicle_group_name), ', ') AS loai_xe_van_hanh,
        arrayStringConcat(groupUniqArray(lxvh.ton), ', ') AS tan_dang_ky,
        arrayStringConcat(groupUniqArray(lxvh.cbm), ', ') AS cbm_dang_ky,
        sum(dt.ton) AS tan_ke_hoach,
        sum(dt.ton_tranfer) AS tan_nhan,
        sum(dt.ton_bbgn) AS tan_giao,
        sum(dt.cbm) AS cbm_ke_hoach,
        sum(dt.cbm_tranfer) AS cbm_nhan,
        sum(dt.cbm_bbgn) AS cbm_giao,
        ifNull(least((sum(ifNull(dt.ton_tranfer, 0)) * 100.) / nullIf(max(ifNull(lxvh.ton, 0)), 0), 100.), 0.) AS vfr_theo_tan,
        ifNull(least((sum(ifNull(dt.cbm_tranfer, 0)) * 100.) / nullIf(max(ifNull(lxvh.cbm, 0)), 0), 100.), 0.) AS vfr_theo_khoi
    FROM
    base_dt AS dt
    INNER JOIN stm_dwh_mondelez.dim_ops_trip AS t ON (dt.trip_header_id = t.key_sk) AND (t.header_group_vehicle_sk != -1)
    LEFT JOIN stm_dwh_mondelez.subdim_cus_customer AS nvt ON t.vendor_id = nvt.key_sk
    INNER JOIN stm_dwh_mondelez.dim_ops_trip AS tt ON (dt.trip_tender_id = tt.key_sk) AND (tt.tender_group_vehicle_sk != -1)
    INNER JOIN stm_dwh_mondelez.dim_ord_product_group AS dpg ON dt.order_group_product_id = dpg.key_sk
    INNER JOIN stm_dwh_mondelez.dim_ord_order AS o ON (dpg.order_id = o.key_sk) AND (o.service_code = 'XB')
    LEFT JOIN stm_dwh_mondelez.dim_ord_product AS sku ON dpg.id = sku.key_sk
    LEFT JOIN stm_dwh_mondelez.subdim_cus_group_of_product AS gsku ON sku.subcus_group_of_product_sk = gsku.key_sk
    INNER JOIN stm_dwh_mondelez.dim_cus_location AS order_cusfrom ON dpg.location_from_id = order_cusfrom.key_sk
    INNER JOIN stm_dwh_mondelez.subdim_cat_location AS order_catfrom ON order_cusfrom.subcat_location_sk = order_catfrom.key_sk
    INNER JOIN stm_dwh_mondelez.dim_cus_location AS order_custo ON dpg.location_to_id = order_custo.key_sk
    INNER JOIN stm_dwh_mondelez.subdim_cat_location AS order_catto ON order_custo.subcat_location_sk = order_catto.key_sk
    LEFT JOIN stm_dwh_mondelez.subdim_cat_group_of_location AS ldd ON order_catto.group_of_location_id = ldd.key_sk
    LEFT JOIN stm_dwh_mondelez.subdim_cat_area AS kv ON order_catto.area_id = kv.key_sk
    LEFT JOIN stm_dwh_mondelez.subdim_cat_group_of_vehicle AS lxvh ON t.header_group_vehicle_sk = lxvh.key_sk
    LEFT JOIN stm_dwh_mondelez.subdim_cat_group_of_vehicle AS lxgt ON tt.tender_group_vehicle_sk = lxgt.key_sk
    WHERE t.status_id > 98
    GROUP BY dt.trip_header_id
) AS bd


-- ════════════════════════════════════════════════════
-- Object: mv_wh_utilization  (engine: MaterializedView)
-- ════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW analytics_workspace.mv_wh_utilization
REFRESH EVERY 1 HOUR
(
    `biz_key` Nullable(String) COMMENT 'Business key ghép theo kho-bin-LPN-pallet-SKU-batch',
    `loc` String COMMENT 'Mã bin - Mã location',
    `whseid` String COMMENT 'Mã kho',
    `level_type` Nullable(String) COMMENT 'Phân loại tầng Pickface/Tầng cao',
    `stacklimit` Nullable(Decimal(18, 4)) COMMENT 'Số pallet tối đa chứa tại bin',
    `group_of_cargo` Nullable(String) COMMENT 'Nhóm hàng',
    `item_code` Nullable(String) COMMENT 'Mã SKU',
    `sku_name` Nullable(String) COMMENT 'Tên SKU',
    `lpnid` Nullable(String) COMMENT 'Mã LPNID',
    `palletid` Nullable(String) COMMENT 'Mã palletID',
    `lottable04` Nullable(DateTime64(3)) COMMENT 'Batch/Ngày sản xuất',
    `status` Nullable(String) COMMENT 'Trạng thái hàng tồn'
)
ENGINE = SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (whseid, loc, biz_key)
SETTINGS allow_nullable_key = 1, index_granularity = 8192
DEFINER = helix SQL SECURITY DEFINER
AS WITH
    base_loc AS
    (
        SELECT
            l.loc,
            l.whseid,
            l.stack_limit,
            if(right(l.loc, 1) = '1', 'Pickface', 'Tầng cao') AS level_type
        FROM mondelez_swm_test.dim_loc AS l
        WHERE (l.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (l.is_deleted = 0) AND (l.loc NOT IN ('A0', 'STAGE', 'BUN', 'PICKTO', 'CHECK', 'CHAMHANG', 'Inventory', 'TRIBECO', 'CHUYEN KHO', 'BLOCK01', 'KHO INHOUSE')) AND (NOT ((l.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (left(trimBoth(l.loc), 1) = 'F'))) AND (NOT ((l.whseid = 'BKD2') AND (l.loc LIKE 'A%'))) AND (NOT ((l.whseid = 'BKD3') AND (l.loc IN ('16', '17', '18', '19', '20', '21', '22', 'A0', 'K', 'TO', 'E', 'CK', 'COPACK'))))
    ),
    cargo AS
    (
        SELECT
            concat(l.whseid, l.loc, ifNull(l.lpnid, ''), ifNull(l.palletid, ''), ifNull(s.item_code, ''), toString(r.lottable04)) AS biz_key,
            l.whseid AS whseid,
            s.group_of_cargo,
            l.loc,
            s.item_code,
            s.sku_name,
            l.lpnid AS lpnid,
            l.palletid AS palletid,
            r.lottable04,
            l.status
        FROM mondelez_swm_test.dim_lotxlocxid AS l
        LEFT JOIN analytics_workspace.mv_masterdata_sku AS s ON (s.whseid = l.whseid) AND (s.item_code = l.sku)
        LEFT JOIN mondelez_swm_test.dim_receiptdetail AS r ON (r.whseid = l.whseid) AND (r.storer_key = l.storer_key) AND (r.lpnid = l.lpnid) AND (r.is_deleted = 0)
        WHERE (l.storer_key = 'MDLZ') AND (l.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')) AND (l.is_deleted = 0) AND (l.qty != 0) AND (l.loc NOT IN ('A0', 'STAGE', 'BUN', 'PICKTO', 'CHECK', 'CHAMHANG', 'Inventory', 'TRIBECO', 'CHUYEN KHO', 'BLOCK01', 'KHO INHOUSE')) AND (NOT ((l.whseid = 'NKD') AND (s.item_code IN ('LOSCAM', 'BACHTHUAN')))) AND (NOT ((l.whseid IN ('BKD1', 'BKD2', 'BKD3')) AND (left(trimBoth(l.loc), 1) = 'F'))) AND (NOT ((l.whseid = 'BKD2') AND (l.loc LIKE 'A%'))) AND (NOT ((l.whseid = 'BKD3') AND (l.loc IN ('16', '17', '18', '19', '20', '21', '22', 'A0', 'K', 'TO', 'E', 'CK', 'COPACK'))))
    ),
    final_ds AS
    (
        SELECT
            c.biz_key,
            b.loc AS loc,
            b.whseid AS whseid,
            b.level_type,
            if(b.level_type = 'Tầng cao', b.stack_limit, least(b.stack_limit, toDecimal64(2, 4))) AS stacklimit,
            c.group_of_cargo,
            c.item_code,
            c.sku_name,
            c.lpnid AS lpnid,
            c.palletid AS palletid,
            c.lottable04 AS lottable04,
            c.status AS status
        FROM
        base_loc AS b
        LEFT JOIN
        cargo AS c ON (c.whseid = b.whseid) AND (c.loc = b.loc)
    )
SELECT *
FROM
final_ds


-- ════════════════════════════════════════════════════
-- Object: v_mdlz_masterdata_category_brand  (engine: View)
-- ════════════════════════════════════════════════════

CREATE VIEW analytics_workspace.v_mdlz_masterdata_category_brand
(
    `sku` String,
    `brand` Nullable(String),
    `category` String
)
AS SELECT DISTINCT
    item_code AS sku,
    brand,
    category
FROM analytics_workspace.mv_masterdata_sku
WHERE (brand IS NOT NULL) OR (category IS NOT NULL)

