# FEAT-057: bổ sung lý do rớt là gồm cả 2 ()

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `Sheet7` row 66
- **Requested by**: MDLZ team
- **Tenant**: MDLZ
- **Area**: Other
- **Priority**: **Major** — Lỗi chức năng lớn — không có cách khắc phục tạm thời
- **Triage confidence**: High
- **View**: OTIF
- **Tech layer**: `cross-stack` — Multiple layers (BE + FE, or data + BE + FE)
- **Owner team**: `mixed` — Multiple teams — needs coordination

## Raw quote
> **bổ sung lý do rớt là gồm cả 2 ()**
> Hiện tại: 
> Mong muốn: bổ sung lý do rớt là gồm cả 2 ()
> Note: 

## Initial problem hypothesis (BA paraphrase, KHÔNG phải solution)
Khách yêu cầu thêm capability "bổ sung lý do rớt là gồm cả 2 ()". Cần discovery để xác định:
- Vấn đề thật sự khách đang giải quyết là gì?
- Có alternative đơn giản hơn không?
- Có ảnh hưởng tới các tenant khác không (chỉ MDLZ-specific hay platform feature)?

## Note nội bộ
—

## DEV note

✅ **Đã verify dev bổ sung — đóng status DONE ngày 2026-05-12.**

### Bằng chứng implementation

Cột thứ 3 "**WH + Transport Infull failure**" (= rớt do **gồm cả 2** layer warehouse + transport) đã được thêm trong bảng Fail Report (tab "Chi tiết") của widget OTIF:

| File | Vị trí | Nội dung |
|---|---|---|
| [widget-otif.tsx](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L482) | line 482 | Field `warehouseTransportInfullFailure` trong type `FailSummaryReportRow` |
| [widget-otif.tsx](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L353-L357) | line 353-357 | `normalizeFailSummaryFromSql` mapping từ SQL column `warehouse_transport_infull_failure` |
| [widget-otif.columns.ts](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.columns.ts#L211-L218) | line 211-218 | Cột table render với label `t('orderMonitor.otif.warehouseTransportInfullFailure')` |
| [dashboard-order-monitor.json (vi)](../../../../frontend/src/i18n/locales/vi/dashboard-order-monitor.json#L278) | line 278 | i18n "WH + Transport Infull failure" |
| Commit gốc | `270667f` (2026-04-13) | "Add new filter options and tooltips to dashboard localization files for English and Vietnamese" |

### Interpretation cuối cùng

Từ 3 hypothesis ban đầu trong [widget-otif-pending-summary.md](../../widget-otif-pending-summary.md):
- ✅ **(a) gộp 2 reason fields hiện tại thành 1 cột** ← **đây là interpretation đúng** (cột `warehouseTransportInfullFailure` = số SO bị rớt **đồng thời** ở cả 2 layer WH infull + Transport infull, KHÔNG phải `lateArrivalByTransport + warehouseInfullFailure` cộng dồn).
- ❌ (b) hiển thị 2 chiều rớt (inbound + outbound) cùng lúc
- ❌ (c) chia "lý do rớt" thành 2 nhóm (planned vs unplanned)

### Caveat (theo dõi tiếp)

Implementation hiện chỉ ở **bảng Fail Report** (tab Chi tiết). 2 chart "Lý do fail" trên overview tab vẫn render riêng Ontime + Infull ([widget-otif.tsx:1637, 1706](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1637)). Nếu SC Manager MDLZ sau này nói "muốn thấy cột gộp cả ở CHART nữa, không chỉ table" → reopen NEW item FEAT-XXX (Minor priority), **KHÔNG** reopen FEAT-057.

## Status

`[D] Done` — verified 2026-05-12 bởi `/da-data`.

> ⚠️ **Lưu ý housekeeping**: file đã rename từ `[-]-FEAT-057-...` sang `[D]-FEAT-057-...`. Backlog/by-team có thể vẫn link bằng `%5B-%5D` — PM cần re-run `/da-triage` để refresh index, hoặc sửa tay link trong [`../../backlog.md`](../../backlog.md) + [`../../by-team.md`](../../by-team.md) + [`../../widget-otif-pending-summary.md`](../../widget-otif-pending-summary.md).

## Next

KHÔNG cần action — đã đóng. Liên quan: [FEAT-128 (DONE)](../frontend-widget/%5BD%5D-FEAT-128-otif-doi-thu-tu-charts-va-bo-sung-chart-loai-hang.md) (reorder charts + add chart by category) — đã DONE 2026-05-12.
