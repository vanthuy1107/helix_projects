# FEAT-056: Thêm filter thời gian

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `Sheet7` row 62
- **Requested by**: MDLZ team
- **Tenant**: MDLZ
- **Area**: Other
- **Priority**: **Minor** — Lỗi chức năng nhỏ — có thể khắc phục tạm thời
- **Triage confidence**: High
- **View**: OTIF
- **Tech layer**: `cross-stack` — Multiple layers (BE + FE, or data + BE + FE)
- **Owner team**: `mixed` — Multiple teams — needs coordination

## Raw quote
> **Thêm filter thời gian**
> Hiện tại: 
> Mong muốn: Thêm filter thời gian
> Note: 

## Initial problem hypothesis (BA paraphrase, KHÔNG phải solution)
Khách yêu cầu thêm capability "Thêm filter thời gian". Cần discovery để xác định:
- Vấn đề thật sự khách đang giải quyết là gì?
- Có alternative đơn giản hơn không?
- Có ảnh hưởng tới các tenant khác không (chỉ MDLZ-specific hay platform feature)?

## Note nội bộ
—

## DEV note

✅ **Đã ship — đóng status DONE ngày 2026-05-16 bởi PM Mondelez confirm (superseded by Phase 3 redesign).**

### Bằng chứng implementation

Filter thời gian đầy đủ đã có trong `WidgetOtif` (`SqlFilterPanel` + 7-field fallback bar) — bao gồm:

| Filter | Loại | Source |
|---|---|---|
| **Từ ngày** (`fromDate`) | Date picker, default = hôm nay | [widget-otif.tsx — state `fromDate/fromDateDraft`](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx) |
| **Đến ngày** (`toDate`) | Date picker, default = hôm nay | same |
| **Loại ngày** (`dateType`) | Single-select: `ETA gửi thầu` \| `ATA chi tiết chuyến` (FE), SQL CASE branch 7 value | [otif/prd.md §96 OQ-05](../../../01-sections/otif/prd.md), [otif/spec.md §2.1](../../../01-sections/otif/spec.md) |
| **Time bucket** (chart-only) | `Day/Week/Month` toggle trong Trend chart | otif/spec.md (ChartCard "Trend by Time") |

PRD §4 đã spec đủ filter thời gian + AC-04 (Time bucket toggle) đã PASS.

### Interpretation cuối cùng

Raw quote ngắn ("Thêm filter thời gian") không nói rõ thiếu cái gì. Sau Phase 3 redesign yêu cầu đã được hấp thụ hoàn toàn:
- ✅ Time range filter (từ ngày / đến ngày)
- ✅ Loại ngày (`dateType`) — 2 value FE / 7 branch SQL
- ✅ Time bucket toggle trong trend chart

→ KHÔNG còn gap.

### Caveat (theo dõi tiếp)

- Discrepancy OQ-05 (FE 2 value vs SQL 7 branch) vẫn open — tracked in [`docs/feature/widget-otif-chart-reorder-and-category/dev/plan.md`](../../../../docs/feature/widget-otif-chart-reorder-and-category/dev/plan.md) FU-1. KHÔNG block FEAT-056 closure.
- Nếu MDLZ sau này nói "filter này khác cái họ muốn" → reopen NEW item, KHÔNG reopen FEAT-056.

## Status

`[D] Done` — closed 2026-05-16 (PM Mondelez confirmation: SqlFilterPanel + dateType + time bucket đã cover).

## History

| Date | Event | Actor | Ref |
|---|---|---|---|
| 2026-05-09 | Triage gốc — Minor priority, ambiguous quote | /da-triage | [backlog.md row 268](../../backlog.md) |
| 2026-05-10 | Pending summary — flagged "dedupe với platform filter asks trước khi discovery" | /da-triage | [widget-otif-pending-summary.md §2](../../widget-otif-pending-summary.md) |
| 2026-05-16 | PM Mondelez confirm UI redesign ship → close as superseded | PM | conversation 2026-05-16 |

## Next

KHÔNG cần action. Nếu khách muốn enhancement cụ thể (granularity custom, comparison period) → mở NEW item.
