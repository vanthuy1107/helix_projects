# UX-067: Bảng %OTIF chiều vận hành

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `OTIF (204)` row 19
- **Reporter**: MDLZ team
- **Tenant**: MDLZ
- **Area**: OrderMonitoring (OTIF widget)
- **Tech layer**: `frontend-config` — ViewConfig/columns trong `OtifDetailPanel`
- **Owner team**: `dev-fe`
- **Type**: UX
- **Triage confidence**: Med (lúc triage gốc 2026-05-09) → High (sau Phase 3 Cockpit dev hoàn tất)
- **View**: OTIF

## Raw quote
> **Bảng %OTIF chiều vận hành**

(File MDLZ Excel sheet `OTIF (204)` row 19 — không có thêm "Hiện tại/Mong muốn/Note".)

## Initial interpretation

Khách MDLZ muốn 1 bảng pivot %OTIF cắt theo **các chiều vận hành** — NVC × Kênh × Nhóm hàng × Khu vực — để Ops Manager đọc số liệu rõ ai/cái gì rớt.

## DEV note

✅ **Đã ship — đóng status DONE ngày 2026-05-16 bởi PM Mondelez confirm.**

### Bằng chứng implementation

Tab `%OTIF Chiều vận hành` đã có trong `OtifDetailPanel` (mở qua tab "Chi tiết" của widget):

| File | Vị trí | Nội dung |
|---|---|---|
| [widget-otif.tsx](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx) | OtifDetailPanel inner tab "%OTIF Chiều vận hành" | Bảng pivot với dimension toggles (NVC \| Kênh \| Nhóm hàng \| Khu vực) — render `WidgetGrid<SummaryReportRow>` |
| [otif/prd.md §6](../../../01-sections/otif/prd.md) | `operationSummary` query → cols `transporter, group_name, group_of_cargo, area, total_so, otif_so, ontime_so, infull_so` | Spec đã cover dimension toggle |
| [otif/spec.md §1](../../../01-sections/otif/spec.md) | Component tree: `Tab "detail" → OtifDetailPanel → Tab "%OTIF Chiều vận hành"` | Source-of-truth UI confirmed |
| [otif/prd.md AC-05](../../../01-sections/otif/prd.md) | "Operation Summary pivot theo chiều" | Acceptance criteria PASS |

### Interpretation cuối cùng

Item này là **PRD-cover-already** (không phải drift) — PRD §6 đã spec `operationSummary` với 4 dimension. Phase 3 Cockpit redesign (v1.2.5/v1.2.6 — PM Approved 2026-05-15) ship code tab này. UX request từ MDLZ đã được hấp thụ vào Phase 3 — KHÔNG cần action riêng.

### Caveat (theo dõi tiếp)

- Trong Phase 5 review reversal (v1.2.6) PM Mondelez chốt Tier 3 drill-down expanded default → 5 chart drill-down chiều vận hành render sẵn KHÔNG cần click. Tab `%OTIF Chiều vận hành` trong OtifDetailPanel vẫn giữ — bổ sung deep-dive cho user muốn pivot custom.

## Status

`[D] Done` — closed 2026-05-16 (PM Mondelez confirmation: UI redesign Phase 3 đã cover).

## History

| Date | Event | Actor | Ref |
|---|---|---|---|
| 2026-05-09 | Triage gốc — flagged Med priority, ?gap-or-drift | /da-triage | [backlog.md row 279](../../backlog.md) |
| 2026-05-10 | Pending summary — flagged "chưa có stub" | /da-triage | [widget-otif-pending-summary.md §1](../../widget-otif-pending-summary.md) |
| 2026-05-12 | PRD v1.2.5 PM Approved (Phase 3 unlock) | PM | [otif/prd.md changelog v1.2.5](../../../01-sections/otif/prd.md) |
| 2026-05-15 | PRD v1.2.6 Phase 5 review reversal | PM | otif/prd.md changelog v1.2.6 |
| 2026-05-16 | PM Mondelez confirm UI redesign ship — close UX-067 | PM | conversation 2026-05-16 |

## Next

KHÔNG cần action. Liên quan: nếu Phase 4 / Phase 5 ship khác spec → trigger PRD revision trước Go-Live signoff. Cross-ref [`go-live-tracker.md`](../../../go-live-tracker.md) cho overall Control Tower status.
