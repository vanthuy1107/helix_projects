# 01 — Widgets / Sections

Bảng tra cứu chính: 1 widget = 1 dòng = đầy đủ canonical names ở mọi tầng (PRD ↔ FE ↔ BE ↔ Data).

> Khi nói "widget X", BA và DEV phải xác định được: tên TV, slug folder, component React, MV ClickHouse và FormConfig.

---

## Order Monitor (giám sát đơn hàng)

| # | Tên TV | Tên EN | Slug folder PRD | React component | i18n key | ClickHouse MV | FormConfig |
|---|--------|--------|----------------|-----------------|----------|---------------|-----------|
| 1 | Tỷ lệ giao hàng OTIF | OTIF — Order Monitoring | `01-sections/otif/` | `WidgetOTIF` | `orderMonitor.otif.*` | `mv_otif`, `mv_otif_stm_data`, `mv_otif_swm_data` | `DSHOTIFDTG01`, `DSHOTIFFLG01`, `DSHOTIFOPG01` |
| 2 | Cảnh báo đơn trễ | Late Order Alert | `01-sections/late-order-alert/` | `WidgetLateOrderAlert` ⚠️ | `orderMonitor.lateOrderAlert.*` | `mv_alert_late_do`, `mv_alert_late_do_base`, `mv_alert_late_do_concat` | `DSHLOAMNG01` |
| 3 | Tiến độ xuất hàng | Shipping Progress | `01-sections/shipping-progress/` | `WidgetShippingProgress` | `orderMonitor.shippingProgress` | (chia sẻ với Flash Daily) | `DSHSHPDTG01`–`DSHSHPDTG05` |
| 4 | Tỷ lệ đáp ứng chuyến gửi thầu | Tender Response Rate | `01-sections/tender-response/` | `WidgetTenderResponse` | `orderMonitor.tenderResponse` | `mv_dap_ung_gui_thau` | `DSHTNDDTG01`, `DSHTNDDTG02` |
| 5 | Tỷ lệ sử dụng xe | VFR — Vehicle Fill Rate | `01-sections/vfr/` | `WidgetVFR` | `orderMonitor.vfr.*` | `mv_vfr_gui_thau` (tender), `mv_vfr_van_hanh` (operational) | `DSHVFRDTG01` |

⚠️ Component name trong code có thể là `WidgetLateLateOrderAlert` (typo) — xem `99-discrepancies.md`.

---

## WH Predict (dự báo & vận hành kho)

| # | Tên TV | Tên EN | Slug folder PRD | React component | i18n key | ClickHouse MV | FormConfig |
|---|--------|--------|----------------|-----------------|----------|---------------|-----------|
| 6 | Copack In/Out | Copack | `01-sections/copack/` | `WidgetCopack` | `whPredict.copack.*` | `mv_copack` | — |
| 7 | Hàng nhập từ nhà máy | Factory Inbound | `01-sections/factory-inbound/` | `WidgetFactoryInbound` | `whPredict.factoryInbound.*` | `mv_factory_inbound` | — |
| 8 | Lấy hàng lẻ | Loose Picking | `01-sections/loose-picking/` | `WidgetLoosePicking` | `whPredict.loosePicking.*` | `mv_loose_picking` ⚠️ | — |
| 9 | Tồn kho theo nhóm hàng | Stock Type | `01-sections/stock-type/` | `WidgetStockType` | `whPredict.stockType.*` | `mv_stocktype` | — |
| 10 | Chuyển kho nội bộ | Transfer | `01-sections/transfer/` | `WidgetTransfer` | `whPredict.transfer.*` | `mv_transfer_in_out` | — |
| 11 | Giao dịch nhập/xuất | Transaction Move | `01-sections/txn-move/` | `WidgetTxnMove` | `whPredict.txnMove.*` | `mv_movement_transaction`, `mv_inbound_transaction_base`, `mv_outbound_transaction_base` | — |
| 12 | Công suất kho | WH Utilization | `01-sections/wh-utilization/` | `WidgetWhUtil` | `whPredict.whUtil.*` | `mv_wh_utilization` | `DSHWHUDTG01`, `DSHWHUDTG02` |

⚠️ PRD ghi `mv_loose_picking_clickhouse`, code dùng `mv_loose_picking` — xem `99-discrepancies.md`.

---

## Flash Report

| # | Tên TV | Tên EN | Slug folder PRD | React component | i18n key | ClickHouse MV | FormConfig |
|---|--------|--------|----------------|-----------------|----------|---------------|-----------|
| 13 | Báo cáo Flash Daily | Flash Daily Report | `01-sections/flash-daily/` | `WidgetFlashDaily` | `flashReport.flashDaily.*` | `mv_flrp_stm_data`, `mv_flrp_swm_data`, `mv_dropped_report`, `mv_dropped_stm`, `mv_dropped_swm` ⚠️ | `DSHFLADTG01`–`DSHFLADTG09` |

⚠️ PRD ghi `mv_flash_report` / `mv_flash_and_drop_report` — code đã refactor split STM vs SWM. Xem `99-discrepancies.md`.

---

## Daily Ops & Alert Summary

| # | Tên TV | Tên EN | Slug folder PRD | React component | i18n key | ClickHouse MV | FormConfig |
|---|--------|--------|----------------|-----------------|----------|---------------|-----------|
| 14 | Daily Ops | Daily Ops | `01-sections/daily-ops/` | `WidgetDailyOps` | `dashboard.widgets.dailyOps` | (chưa rõ) | — |
| 15 | Tổng hợp cảnh báo | Alert Summary | `01-sections/alert-summary/` | `WidgetAlertSummary` | `dashboard.widgets.alertSummary` | `mv_alert_stm_data`, `mv_alert_swm_data` | — |

---

## Widgets có trong code nhưng CHƯA có PRD

| # | Tên TV (đề xuất) | Tên EN | React component | i18n key | Trạng thái |
|---|-----------------|--------|-----------------|----------|------------|
| 16 | Báo cáo PGI | PGI Report | `WidgetPgiReport` | `pgiReport.*` | ⚠️ Có code, chưa có folder `01-sections/pgi-report/` — cần BA viết PRD hoặc xác nhận deprecated |

---

## KPI / chart placeholder widgets (không thuộc dashboard Mondelez)

Các widget kiểu chart-generic dùng chung trong nền tảng — KHÔNG phải widget nghiệp vụ Mondelez:

| Component / i18n | Mô đề | Ghi chú |
|------------------|------|---------|
| `dashboard.widgets.chart` | Chart | Chart generic — render từ data source bất kỳ |
| `dashboard.widgets.kpi` | KPI | Card hiển thị 1 số (template trong feature `kpi-templates`) |
| `dashboard.widgets.metric` | Metric | Tương tự KPI |
| `dashboard.widgets.narrative` | Insight | Đoạn text mô tả |
| `dashboard.widgets.aiInsight` | AI Insight | Insight do LLM sinh ra |
| `dashboard.widgets.matrixTable` | Matrix Table | Pivot table generic |
| `dashboard.widgets.statList` | Stat List | List chỉ số |

---

## Reference cũ (đã có version mới ở `01-sections/`)

`05-reference/[done] *` chứa PRD/spec/wireframe phiên bản đầu tiên. Không phải canonical — chỉ dùng làm reference khi cần xem chi tiết historical hoặc khi `01-sections/` còn rỗng.

| Reference folder | Map sang `01-sections/` |
|------------------|------------------------|
| `[done] canh_bao_don_tre/` | `late-order-alert/` |
| `[done] flash_report/` | `flash-daily/` |
| `[done] loose-picking/` | `loose-picking/` |
| `[done] otif/` | `otif/` |
| `[done] stock-type/` | `stock-type/` |
| `[done] tien_do_xuat_hang/` | `shipping-progress/` |
| `[done] transaction-move/` | `txn-move/` |
| `[done] ty_le_dap_ung_va_tuan_thu/` | `tender-response/` |
| `[done] ty_le_lap_day_xe_van_hanh_gui_thau/` | (Commit Response Rate — chưa có folder mới) ⚠️ |
| `[done] vfr/` | `vfr/` |
