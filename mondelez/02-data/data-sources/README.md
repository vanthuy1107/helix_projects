# Data Sources — External Data Warehouses

Tài liệu về các hệ thống dữ liệu nguồn (upstream) mà MDLZ Control Tower đọc vào.

---

## Hệ thống nguồn

| Hệ thống | DB Engine | Phạm vi | Tài liệu |
|---|---|---|---|
| **STM** (Smart Transport Management) | ClickHouse | Đơn hàng, chuyến vận chuyển, bốc xếp | [stm-datawarehouse.md](stm-datawarehouse.md) |
| **SWM** (Smart Warehouse Management) | ClickHouse | Nhập kho, tồn kho, xuất kho, mua hàng | [swm-datawarehouse.md](swm-datawarehouse.md) |
| **analytics_workspace** | ClickHouse | Materialized Views tổng hợp (KPI layer) | [clickhouse-ddl/](clickhouse-ddl/) |

---

## ClickHouse DDL Snapshot — `analytics_workspace`

DDL của tất cả Materialized Views trong `analytics_workspace` được lưu tại:

| File | Mục đích |
|---|---|
| [clickhouse-ddl/analytics-workspace_mvs.md](clickhouse-ddl/analytics-workspace_mvs.md) | Markdown đầy đủ: schema + DDL + metadata (dùng để đọc, debug, audit) |
| [clickhouse-ddl/analytics-workspace_mvs.sql](clickhouse-ddl/analytics-workspace_mvs.sql) | Raw SQL DDL (dùng để copy-paste vào migration, recreation) |

**Cập nhật DDL mới nhất** (chạy bất cứ khi nào MV thay đổi trên server):

```bash
python data-pipeline/control-tower/scripts/export_clickhouse_ddl.py
# Options:
#   --database analytics_workspace   (default)
#   --table mv_alert_late_do         # chỉ export 1 MV
#   --include-inner                  # bao gồm backing tables .inner_id.*
```

**Danh sách 41 MVs hiện có:** `mv_alert_late_do`, `mv_alert_late_do_base`, `mv_alert_late_do_concat`,
`mv_alert_late_do_so_pick`, `mv_alert_stm_data`, `mv_alert_stm_swm_data`, `mv_alert_swm_data`,
`mv_copack`, `mv_dap_ung_gui_thau`, `mv_dropped_report`, `mv_dropped_stm`, `mv_dropped_swm`,
`mv_filter_cargo_brand`, `mv_filter_channel`, `mv_filter_region`, `mv_filter_vendor`, `mv_filter_warehouse`,
`mv_flrp_stm_data`, `mv_flrp_swm_data`, `mv_inbound_transaction_base`, `mv_loose_picking`,
`mv_loose_picking_clickhouse`, `mv_masterdata_location`, `mv_masterdata_ordertype`, `mv_masterdata_sku`,
`mv_masterdata_vehicle`, `mv_masterdata_vendor`, `mv_movement_transaction`, `mv_otif`,
`mv_otif_stm_data`, `mv_otif_swm_data`, `mv_otif_swm_stm_data`, `mv_outbound_transaction_base`,
`mv_stocktype`, `mv_test_copack_clickhouse`, `mv_test_goods_receipt`, `mv_test_loose_picking`,
`mv_transfer_in_out`, `mv_vfr_gui_thau`, `mv_vfr_van_hanh`, `mv_wh_utilization`

---

## STM — Smart Transport Management

**Mô hình:** Star Schema (FDN — Fact → Dimension → SubDimension)

| File | Nội dung |
|---|---|
| [stm-datawarehouse.md](stm-datawarehouse.md) | Schema đầy đủ: fact/dim/subdim tables, cột, kiểu dữ liệu |
| [stm-query-examples.md](stm-query-examples.md) | Query mẫu theo từng use case (Sales, Ops, Finance, BI) |

**Nguyên tắc query STM:**
- JOIN theo chiều: `Fact → Dimension → SubDimension` (không được nhảy cấp)
- Luôn filter: `is_deleted = 0`
- Luôn filter ngày để tối ưu partition scan

---

## SWM — Smart Warehouse Management

**Mô hình:** Denormalized Star Schema (OLAP — FACT + DIM ONLY)

| File | Nội dung |
|---|---|
| [swm-datawarehouse.md](swm-datawarehouse.md) | Schema đầy đủ: 5 fact tables + 12 dim tables + 2 subdim |
| [swm-query-examples.md](swm-query-examples.md) | Query mẫu theo từng bộ phận (Inbound, Inventory, Outbound, Finance, BI) |

**Nguyên tắc query SWM:**
- Query **FACT tables trực tiếp** (đã denormalized)
- Chỉ LEFT JOIN thêm DIM nếu cần extra detail (tối đa 1–2 bảng)
- **Không dùng** subdim tables trực tiếp
- Phạm vi kho: `BKD1, BKD2, BKD3, NKD, VN821, VN831` | Chủ hàng: `MDLZ`
