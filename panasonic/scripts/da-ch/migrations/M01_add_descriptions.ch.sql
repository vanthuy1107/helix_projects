-- ============================================================================
-- M01 _add_descriptions — Bổ sung Description cho psv_target + 3 MVs Panasonic
-- ============================================================================
-- name: M01_add_descriptions
-- target_db: analytics_workspace
-- objects: psv_target, mv_psv, mv_psv_main, mv_psv_trigger
-- source_of_truth: projects/panasonic/05-reference/SOURCE TABLE & FILES_STM.xlsx
--                  sheet "Source & File_Auto Planning " — column G (Mean_HeliX)
-- generated: 2026-05-19
-- ============================================================================
-- TÁC ĐỘNG:
--   - 4 ALTER TABLE ... MODIFY COMMENT (table-level) — APPLIED THÀNH CÔNG
--   - ~180 ALTER TABLE ... COMMENT COLUMN (column-level)
--   - KHÔNG đổi schema (column type, default value, ...)
--   - Metadata-only, không touch data
--
-- CÁCH CHẠY:
--   PowerShell: .\run.ps1 -File .\migrations\M01_add_descriptions.ch.sql -Format TabSeparated
--   Bash:       ./run.sh migrations/M01_add_descriptions.ch.sql
--
-- LƯU Ý:
--   1. HTTP API CH không cho multi-statement → dùng wrapper `run_migration.py`.
--   2. **CH 25.x LIMITATION**: ALTER COMMENT COLUMN trên REFRESHABLE MV
--      (mv_psv, mv_psv_main) trả về 200 OK nhưng KHÔNG persist — schema của
--      refreshable MV được control bởi SELECT clause của nó.
--      - Sections D + E (mv_psv_main, mv_psv) sẽ chạy nhưng không có hiệu lực
--        ở cột-level. Table-level COMMENT (Section A) vẫn áp dụng OK.
--      - Để comment thật cột của 2 MV này → phải DROP + CREATE với inline
--        COMMENT trong column definition. Xem M02_recreate_mv_with_comments.sql
--        (tạo sau, cần thêm authorization).
--   3. Incremental MV (mv_psv_trigger) + canonical table (psv_target) áp dụng
--      column-level COMMENT bình thường (Sections B + C).
-- ============================================================================
-- KẾT QUẢ RUN 2026-05-19 12:55 UTC: 184/184 OK; verify:
--   psv_target:     61/61 columns commented (100%)
--   mv_psv_trigger: 61/61 columns commented (100%)
--   mv_psv_main:    0/39  columns commented (REFRESHABLE MV LIMITATION)
--   mv_psv:         0/57  columns commented (REFRESHABLE MV LIMITATION)
--   All 4 objects:  table-level COMMENT applied ✓
-- ============================================================================


-- ──────────────────────────────────────────────────────────────────────────
-- SECTION A: Table-level COMMENT (4 statements)
-- ──────────────────────────────────────────────────────────────────────────

ALTER TABLE analytics_workspace.psv_target
  MODIFY COMMENT 'Canonical store cho PSV (Phương án Sắp Vận tải) - kết quả OPS_Optimizer của TMS Panasonic. Mỗi row = 1 chuyến (tracking_id) thuộc 1 lần chạy thuật toán tối ưu (ops_optimize_id). Fed by mv_psv_trigger từ tms_panasonic_prod.dbo_OPS_Optimizer. SharedReplacingMergeTree dedupe theo version - query FINAL khi cần latest. Filter mặc định: is_deleted=0 AND data_report=true.';

ALTER TABLE analytics_workspace.mv_psv_trigger
  MODIFY COMMENT 'Incremental MV ghi vào psv_target. Mỗi INSERT vào tms_panasonic_prod.dbo_OPS_Optimizer trigger MV này: ARRAY JOIN JSON DataRun.DataReport, parse từng route, derive status_name_detail (Chuyến điều chỉnh route / Chuyến tạo mới). Realtime - không có refresh policy.';

ALTER TABLE analytics_workspace.mv_psv_main
  MODIFY COMMENT 'UI-facing PSV MV (REFRESH EVERY 1 HOUR). SELECT FROM psv_target FINAL WHERE is_deleted=0 AND data_report=true, đồng thời shift mọi DateTime sang UTC+7 (cộng 7h). Dùng cho widget/dashboard Smartlog Control Tower - không phải audit (audit nên dùng psv_target FINAL).';

ALTER TABLE analytics_workspace.mv_psv
  MODIFY COMMENT 'Refreshable MV (EVERY 30 MIN) song song với mv_psv_trigger - đọc thẳng tms_panasonic_prod.dbo_OPS_Optimizer (không qua psv_target). LEGACY: không có cột status_name_detail/reason_change, schema lệch ~10 rows với psv_target do timing. Deprecate candidate - dùng mv_psv_main thay thế.';


-- ──────────────────────────────────────────────────────────────────────────
-- SECTION B: psv_target — fill gaps (columns chưa có COMMENT)
-- Nguồn: pipeline knowledge + DataRun JSON schema
-- ──────────────────────────────────────────────────────────────────────────

ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN ops_optimize_id 'ID kết quả OPS_Optimizer (từ OPS_Optimizer.ID) - 1 lần chạy thuật toán tối ưu';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN version 'Version từ PeerDB CDC (_peerdb_version) - dùng cho ReplacingMergeTree dedupe';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN sys_customer_id 'ID khách hàng hệ thống (Panasonic = 1 tenant cố định)';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN parent_modified_date 'Thời gian chỉnh sửa OPS_Optimizer cha (không phải route con)';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN parent_modified_by 'Người chỉnh sửa OPS_Optimizer cha';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN date_from 'Đầu khoảng kế hoạch chạy tối ưu';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN date_to 'Cuối khoảng kế hoạch chạy tối ưu';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN is_save 'User đã save kết quả tối ưu (true) hay còn draft (false)';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN is_container 'Setting tối ưu: cho phép ghép container';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN is_balance_customer 'Setting tối ưu: cân bằng theo customer';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN is_balance_km_score 'Setting tối ưu: cân bằng theo KM/score';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN type_id 'Loại OPS Optimizer (TypeID)';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN note 'Ghi chú chính của OPS_Optimizer';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN note_1 'Ghi chú phụ 1';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN note_2 'Ghi chú phụ 2';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN report_id 'ID báo cáo điều chỉnh trên 1 chuyến (DataReport[i].ID)';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN total_distance 'Tổng quãng đường chuyến (km)';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN location_from_name 'Tên điểm nhận';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN location_to_name 'Tên điểm giao';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN group_ids 'JSON mảng ID nhóm đơn (vd: [123,456])';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN order_ids 'JSON mảng ID đơn hàng (vd: [789,101])';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN data_report 'TRUE nếu JSON DataRun.DataReport không rỗng - tức là có chuyến để báo cáo';
ALTER TABLE analytics_workspace.psv_target COMMENT COLUMN is_deleted 'Soft-delete flag từ PeerDB CDC (1 = đã xóa ở source)';


-- ──────────────────────────────────────────────────────────────────────────
-- SECTION C: mv_psv_trigger — column COMMENT (57 columns, theo Mean_HeliX)
-- ──────────────────────────────────────────────────────────────────────────

ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN ops_optimize_id 'ID kết quả OPS_Optimizer (từ OPS_Optimizer.ID)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN version 'Version từ PeerDB CDC (_peerdb_version)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN sys_customer_id 'ID khách hàng hệ thống';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN optimizer_name 'Tên kết quả OPS_Optimizer';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN created_date 'Thời gian tạo kết quả';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN created_by 'Người tạo kết quả';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN parent_modified_date 'Thời gian chỉnh sửa OPS_Optimizer cha';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN parent_modified_by 'Người chỉnh sửa OPS_Optimizer cha';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN date_from 'Đầu khoảng kế hoạch tối ưu';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN date_to 'Cuối khoảng kế hoạch tối ưu';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN is_save 'User đã save kết quả (true) hay draft (false)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN is_container 'Setting tối ưu: ghép container';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN is_balance_customer 'Setting tối ưu: cân bằng customer';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN is_balance_km_score 'Setting tối ưu: cân bằng KM/score';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN type_id 'Loại OPS Optimizer';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN note 'Ghi chú chính';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN note_1 'Ghi chú phụ 1';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN note_2 'Ghi chú phụ 2';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN tracking_id 'Mã chuyến (TrackingID) - mỗi chuyến thuộc 1 OPS_Optimizer';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN report_id 'ID báo cáo điều chỉnh trên chuyến';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN is_trip_edit_manual 'Chuyến có chỉnh sửa thủ công';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN reason_change 'Lý do điều chỉnh';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN status_name_detail_original 'Raw StatusNameDetail từ JSON (debug only): Không có cột / 1 space / value)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN status_name_detail 'Loại điều chỉnh - Rule: Chuyến điều chỉnh route khi IsTripEditManual=true AND StatusNameDetail rỗng/null. Ngược lại: Chuyến tạo mới';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN order_code 'Mã đơn hàng (concat nếu nhiều đơn)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN total_order 'Tổng số đơn';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN total_delivery 'Tổng điểm giao';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN total_ton 'Tổng số tấn';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN total_cbm 'Tổng số CBM (m3)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN total_cod_unit_price 'Tổng giá trị hàng hóa (VND)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN group_of_vehicle_code 'Mã loại xe';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN group_of_vehicle_name 'Tên loại xe';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN group_of_vehicle_size 'Khung xe';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN vehicle_no 'Số xe (biển số)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN max_capacity 'Thể tích xe (CBM/m3)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN max_weight 'Trọng tải xe (tấn)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN vendor_name 'Nhà vận tải';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN main_cost 'Phí chính (VND)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN additional_cost 'Phụ phí (VND)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN total_cost 'Tổng chi phí dự kiến (VND) = main_cost + additional_cost';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN total_distance 'Tổng quãng đường (km)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN master_etd 'ETD chuyến (Estimated Time of Departure)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN master_eta 'ETA chuyến (Estimated Time of Arrival)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN date_come_stock 'Thời gian xe đến điểm nhận hàng';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN vehicle_end_time 'Thời gian xe về kho cuối';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN report_modified_date 'Thời gian chỉnh sửa report (route level)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN report_modified_by 'Người chỉnh sửa report (route level)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN group_of_product_code 'Mã nhóm hàng';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN group_of_product_name 'Tên nhóm hàng';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN product_code 'Mã hàng hóa';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN product_name 'Tên hàng hóa';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN location_from_code 'Mã điểm nhận';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN location_from_name 'Tên điểm nhận';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN location_to_code 'Mã điểm giao';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN location_to_name 'Tên điểm giao';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN group_ids 'JSON mảng ID nhóm đơn';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN order_ids 'JSON mảng ID đơn hàng';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN constraint_name 'Vi phạm ràng buộc (vd: Vi phạm ràng buộc MOQ)';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN constraint_note 'Ghi chú ràng buộc';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN data_report 'TRUE nếu JSON DataRun.DataReport không rỗng';
ALTER TABLE analytics_workspace.mv_psv_trigger COMMENT COLUMN is_deleted 'Soft-delete flag từ PeerDB CDC';


-- ──────────────────────────────────────────────────────────────────────────
-- SECTION D: mv_psv_main — column COMMENT (39 columns, UI-facing)
-- ──────────────────────────────────────────────────────────────────────────

ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN tracking_id 'Mã chuyến (TrackingID)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN optimizer_name 'Tên kết quả OPS_Optimizer';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN created_by 'Người tạo kết quả';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN created_date 'Thời gian tạo kết quả (UTC+7)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN is_trip_edit_manual 'Chuyến có chỉnh sửa thủ công';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN status_name_detail 'Loại điều chỉnh: Chuyến điều chỉnh route / Chuyến tạo mới (rule trong DDL của mv_psv_trigger)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN order_code 'Mã đơn hàng';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN total_order 'Tổng số đơn';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN total_delivery 'Tổng điểm giao';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN total_ton 'Tổng số tấn';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN total_cbm 'Tổng số CBM (m3)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN total_cod_unit_price 'Tổng giá trị hàng hóa (VND)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN group_of_vehicle_code 'Mã loại xe';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN group_of_vehicle_name 'Tên loại xe';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN group_of_vehicle_size 'Khung xe';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN vehicle_no 'Số xe (biển số)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN max_capacity 'Thể tích xe (CBM/m3)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN max_weight 'Trọng tải xe (tấn)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN vendor_name 'Nhà vận tải';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN main_cost 'Phí chính (VND)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN additional_cost 'Phụ phí (VND)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN total_cost 'Tổng chi phí dự kiến (VND)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN report_modified_by 'Người điều chỉnh report (route level)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN report_modified_date 'Thời gian điều chỉnh report (UTC+7, NULL nếu chưa chỉnh)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN reason_change 'Lý do điều chỉnh';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN constraint_name 'Vi phạm ràng buộc';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN constraint_note 'Ghi chú ràng buộc';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN group_of_product_code 'Mã nhóm hàng';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN group_of_product_name 'Tên nhóm hàng';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN product_code 'Mã hàng hóa';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN product_name 'Tên hàng hóa';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN location_from_code 'Mã điểm nhận';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN location_to_code 'Mã điểm giao';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN master_etd 'ETD chuyến (UTC+7)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN master_eta 'ETA chuyến (UTC+7)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN date_come_stock 'Thời gian xe đến điểm nhận (UTC+7)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN vehicle_end_time 'Thời gian xe về kho cuối (UTC+7)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN is_deleted 'Soft-delete flag (luôn = 0 vì WHERE đã filter)';
ALTER TABLE analytics_workspace.mv_psv_main COMMENT COLUMN data_report 'TRUE - luôn true vì WHERE đã filter';


-- ──────────────────────────────────────────────────────────────────────────
-- SECTION E: mv_psv — column COMMENT (57 columns, LEGACY pipeline)
-- ──────────────────────────────────────────────────────────────────────────

ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN ops_optimize_id 'ID kết quả OPS_Optimizer';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN version 'Version từ PeerDB CDC';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN sys_customer_id 'ID khách hàng hệ thống';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN optimizer_name 'Tên kết quả OPS_Optimizer';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN created_date 'Thời gian tạo kết quả';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN created_by 'Người tạo kết quả';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN parent_modified_date 'Thời gian chỉnh sửa OPS_Optimizer cha';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN parent_modified_by 'Người chỉnh sửa OPS_Optimizer cha';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN date_from 'Đầu khoảng kế hoạch';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN date_to 'Cuối khoảng kế hoạch';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN is_save 'User đã save (true) hay draft (false)';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN is_container 'Setting: ghép container';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN is_balance_customer 'Setting: cân bằng customer';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN is_balance_km_score 'Setting: cân bằng KM/score';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN type_id 'Loại OPS Optimizer';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN note 'Ghi chú chính';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN note_1 'Ghi chú phụ 1';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN note_2 'Ghi chú phụ 2';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN tracking_id 'Mã chuyến (TrackingID - kiểu String ở MV này, khác Int64 ở mv_psv_trigger)';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN report_id 'ID báo cáo điều chỉnh trên chuyến';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN is_trip_edit_manual 'Chuyến có chỉnh sửa thủ công';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN order_code 'Mã đơn hàng';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN total_order 'Tổng số đơn';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN total_delivery 'Tổng điểm giao';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN total_ton 'Tổng số tấn';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN total_cbm 'Tổng số CBM (m3)';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN total_cod_unit_price 'Tổng giá trị hàng hóa (VND)';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN group_of_vehicle_code 'Mã loại xe';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN group_of_vehicle_name 'Tên loại xe';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN group_of_vehicle_size 'Khung xe';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN vehicle_no 'Số xe (biển số)';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN max_capacity 'Thể tích xe (CBM/m3)';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN max_weight 'Trọng tải xe (tấn)';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN vendor_name 'Nhà vận tải';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN main_cost 'Phí chính (VND)';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN additional_cost 'Phụ phí (VND)';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN total_cost 'Tổng chi phí dự kiến (VND)';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN total_distance 'Tổng quãng đường (km)';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN master_etd 'ETD chuyến';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN master_eta 'ETA chuyến';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN date_come_stock 'Thời gian xe đến điểm nhận';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN vehicle_end_time 'Thời gian xe về kho';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN report_modified_date 'Thời gian điều chỉnh report';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN group_product_code 'Mã nhóm hàng (tên cột khác mv_psv_main: thiếu chữ _of_)';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN group_product_name 'Tên nhóm hàng (tên cột khác mv_psv_main: thiếu chữ _of_)';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN product_code 'Mã hàng hóa';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN product_name 'Tên hàng hóa';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN location_from_code 'Mã điểm nhận';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN location_from_name 'Tên điểm nhận';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN location_to_code 'Mã điểm giao';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN location_to_name 'Tên điểm giao';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN group_ids 'JSON mảng ID nhóm đơn';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN order_ids 'JSON mảng ID đơn hàng';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN constraint_name 'Vi phạm ràng buộc';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN constraint_note 'Ghi chú ràng buộc';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN data_report 'TRUE nếu JSON DataRun.DataReport không rỗng';
ALTER TABLE analytics_workspace.mv_psv COMMENT COLUMN is_deleted 'Soft-delete flag từ PeerDB CDC';
