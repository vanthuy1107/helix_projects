# 06 — Data Layer (ClickHouse MVs + source tables)

Tham chiếu nhanh tất cả Materialized Views và source tables. DEV (BE & DA) dùng làm map khi viết query, BA tra để biết widget nào kéo từ MV nào.

> Source DDL: [`02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql`](../02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql)

---

## Materialized Views — `analytics_workspace.*`

### Order Monitoring & Alerts

| MV name | Refresh | Phục vụ widget | Mô tả |
|---------|---------|---------------|------|
| `mv_otif` | ~5 phút | OTIF | KPI tổng hợp OTIF |
| `mv_otif_stm_data` | — | OTIF | Phần STM (transport) raw |
| `mv_otif_swm_data` | — | OTIF | Phần SWM (warehouse) raw |
| `mv_alert_late_do` | ~5 phút | Late Order Alert | KPI cảnh báo đơn trễ |
| `mv_alert_late_do_base` | — | Late Order Alert | Base data |
| `mv_alert_late_do_concat` | — | Late Order Alert | Concat info |
| `mv_alert_stm_data` | — | Alert Summary | STM-side alerts |
| `mv_alert_swm_data` | — | Alert Summary | SWM-side alerts |

### Distribution / Fulfillment

| MV name | Refresh | Phục vụ widget | Mô tả |
|---------|---------|---------------|------|
| `mv_dap_ung_gui_thau` | — | Tender Response | Tỷ lệ đáp ứng gửi thầu |
| `mv_flrp_stm_data` | ~5–30 phút | Flash Daily | Phần STM của Flash Report |
| `mv_flrp_swm_data` | ~5–30 phút | Flash Daily | Phần SWM của Flash Report |
| `mv_dropped_report` | — | Flash Daily | Đơn dropped tổng hợp |
| `mv_dropped_stm` | — | Flash Daily | Dropped phía STM |
| `mv_dropped_swm` | — | Flash Daily | Dropped phía SWM |

⚠️ Tài liệu PRD cũ (`05-reference/[done] flash_report/`) ghi `mv_flash_report` / `mv_flash_and_drop_report` — **đã refactor split STM/SWM**. Xem `99-discrepancies.md`.

### Inventory & Warehouse

| MV name | Refresh | Phục vụ widget | Mô tả |
|---------|---------|---------------|------|
| `mv_stocktype` | ~1 giờ | Stock Type | Tồn kho theo brand/group |
| `mv_loose_picking` | ~1 giờ | Loose Picking | % Loose vs Full pallet |
| `mv_copack` | — | Copack | Copack in/out |
| `mv_factory_inbound` | — | Factory Inbound | Hàng nhập từ nhà máy |
| `mv_transfer_in_out` | — | Transfer | Chuyển kho nội bộ |
| `mv_wh_utilization` | — | WH Utilization | Công suất kho |
| `mv_vfr_gui_thau` | — | VFR (tender lens) | Group by `TenderMasterID` |
| `mv_vfr_van_hanh` | — | VFR (operational lens) | Group by `MasterCode` |

### Transaction Movement

| MV name | Phục vụ widget | Mô tả |
|---------|---------------|------|
| `mv_movement_transaction` | Txn Move | Tổng movement nhập/xuất |
| `mv_inbound_transaction_base` | Txn Move | Inbound base |
| `mv_outbound_transaction_base` | Txn Move | Outbound base |

### Master Data MVs

| MV name | Mô tả |
|---------|------|
| `mv_masterdata_location` | Master kho/vị trí |
| `mv_masterdata_sku` | Master SKU |
| `mv_masterdata_vehicle` | Master loại xe (capacity Tấn/Khối) |
| `mv_masterdata_vendor` | Master NVC |
| `mv_masterdata_ordertype` | Master loại đơn |

---

## Source tables — STM (Smart Transport Management)

Schema: `stm` (PostgreSQL/MSSQL). Tham chiếu chi tiết: [`02-data/data-sources/stm-datawarehouse.md`](../02-data/data-sources/stm-datawarehouse.md).

| Table | Mô tả |
|-------|------|
| `stm.CAT_Product` | Danh mục sản phẩm STM |
| `stm.CAT_GroupOfProduct` | Nhóm sản phẩm |
| `stm.CAT_Parking` | Quy cách đóng gói |
| Tender-related | `trip`, `tender_trip`, `tender_trip_detail`, `tender_trip_response` |
| Order | `order`, `order_line`, `DO`, `DO_detail` |
| Vendor / vehicle | `vendor`, `vehicle`, `route` |
| Timestamps cột | `thoi_gian_gui_thau`, `etd_chuyen_gui_thau`, `ata_roi`, `eta`, `gio_ra_cong` |

---

## Source tables — SWM (Smart Warehouse Management)

Schema: `swm`. Tham chiếu chi tiết: [`02-data/data-sources/swm-datawarehouse.md`](../02-data/data-sources/swm-datawarehouse.md).

| Table | Mô tả |
|-------|------|
| `swm.sku` | Master SKU |
| `swm.loc` | Master location/bin |
| `dim_lotxlocxid` | Tồn kho chi tiết theo lot × location |
| Inbound | `receipt`, `receipt_line`, `pallet_inbound` |
| Outbound | `shipment`, `shipment_detail`, `pallet_outbound` |
| Inventory | `location`, `stock`, `stock_movement` |
| Cột warehouse | `WHSEID`, `SLOC` |

---

## Refresh strategy

- **5 phút:** OTIF, Late Order Alert (real-time-ish KPI cần live data)
- **5–30 phút:** Flash Daily (xuất kho progress)
- **1 giờ:** Stock Type, Loose Picking (snapshot, không cần real-time)

DEV cần verify khi setup MV mới → cập nhật vào file này.

---

## Lưu ý vận hành

- **MV không có time dimension** (Stock Type) → snapshot only, không trace history qua MV; nếu cần history phải log riêng.
- **Multi-leg trip:** ~80% SO Mondelez có multi-leg; 1 số MV chỉ giữ 1 leg → status có thể "lệch" thực tế. Acceptable cho Flash snapshot, KHÔNG dùng cho audit/compliance.
- **TZ:** ClickHouse mặc định UTC; UI render `Asia/Ho_Chi_Minh`. Khi viết query phải convert TZ rõ ràng.
