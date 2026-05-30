# 01-sections — Widgets / Sections Dashboard

Mỗi widget = 1 thư mục, bên trong có đủ 3 file:
- `prd.md` — yêu cầu nghiệp vụ
- `spec.md` — logic TMS/WMS view → Clickhouse
- `wireframe.md` — ASCII layout

## Danh sách Widgets

| Folder | Tên nghiệp vụ | Frontend source | Trạng thái |
|--------|--------------|-----------------|------------|
| `late-order-alert/` | Cảnh báo đơn trễ | `order-monitor/widget-late-order-alert` | ✅ Docs v1.0.0 (2026-05-19) — prd/spec/wireframe prefixed convention |
| `otif/` | OTIF | `order-monitor/widget-otif` | — |
| `shipping-progress/` | Tiến độ giao hàng | `order-monitor/widget-shipping-progress` | — |
| `tender-response/` | Tender Response | `order-monitor/widget-tender-response` | ✅ Docs v1.0.0 (2026-05-30) — canonical từ glossary+MV (FE chưa trace) · prefixed convention |
| `vfr/` | VFR (Vehicle Fill Rate) | `order-monitor/widget-vfr` | — |
| `copack/` | Copack In/Out | `wh-predict/widget-copack` | — |
| `factory-inbound/` | Factory Inbound | `wh-predict/widget-factory-inbound` | — |
| `loose-picking/` | Loose Picking | `wh-predict/widget-loose-picking` | — |
| `stock-type/` | Stock Type | `wh-predict/widget-stock-type` | — |
| `transfer/` | Transfer | `wh-predict/widget-transfer` | — |
| `txn-move/` | Transaction Move | `wh-predict/widget-txn-move` | — |
| `wh-utilization/` | Công suất kho | `wh-predict/widget-wh-util` | — |
| `flash-daily/` | Flash Daily Report | `flash-report/widget-flash-daily` | — |
| `daily-ops/` | Daily Ops | `daily-ops/widget-daily-ops` | — |
| `alert-summary/` | Alert Summary | `alert-summary/` | — |
