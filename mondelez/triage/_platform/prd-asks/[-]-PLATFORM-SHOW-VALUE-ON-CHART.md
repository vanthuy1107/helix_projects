# PLATFORM-SHOW-VALUE-ON-CHART: Hiển thị data label trên chart

- **Triage scope**: PLATFORM-LEVEL — affects 3 items across 3 views
- **Type**: UX
- **Area**: Platform
- **Tenant**: MDLZ (Mondelez), but pattern likely applicable cross-tenant
- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — multiple rows
- **Affected views**: Cảnh báo đơn trễ (204), %Stock Type (214), %Loose picking (234)
- **Tech layer (rolled up)**: `frontend-widget` (3)
- **Owner team (rolled up)**: `dev-fe` (3)
- **Status (rolled up)**: majority `[-]` — breakdown: [-]=3
- **Priority**: _N/A (UX-only platform stub)_
- **Triage confidence**: High

## Problem
Chart hiện chưa show số liệu lên. Lặp 3 view.

## Evidence (raw quotes from source)
- **Cảnh báo đơn trễ (204)** (row 15): Show số liệu lên chart — current: _Chưa show số liệu, phải hover mới hiện số liệu_ → desired: _(Bỏ qua nếu đã có)
Nguyên tắc:
- % thì làm tròn 2 chữ số (64.59% --> 64%)
- số thập phân thì lấy số nguyên kèm đơn vị tí_
- **%Stock Type (214)** (row 15): Show số liệu lên chart — current: _Chưa show số liệu, phải hover mới hiện số liệu_ → desired: _(Bỏ qua nếu đã có)
Nguyên tắc:
- % thì làm tròn 2 chữ số (64.59% --> 64%)
- số thập phân thì lấy số nguyên kèm đơn vị tí_
- **%Loose picking (234)** (row 15): Show số liệu lên chart — current: _Chưa show số liệu, phải hover mới hiện số liệu_ → desired: _(Bỏ qua nếu đã có)
Nguyên tắc:
- % thì làm tròn 2 chữ số (64.59% --> 64%)
- số thập phân thì lấy số nguyên kèm đơn vị tí_


## Why platform-level (not per-view)
This is a single capability or convention that should be implemented once at the dashboard/widget framework level rather than per-view. Implementing per-view would create N copies of the same logic and regression risk.

## Next
Handoff `/ba` — revise PRD để spec capability platform-wide
