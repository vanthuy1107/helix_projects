# PLATFORM-APPLY-RESET-BUTTON: Bổ sung nút Apply / Reset filter (không auto-filter)

- **Triage scope**: PLATFORM-LEVEL — affects 2 items across 2 views
- **Type**: UX
- **Area**: Platform
- **Tenant**: MDLZ (Mondelez), but pattern likely applicable cross-tenant
- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — multiple rows
- **Affected views**: %Stock Type (214), %Loose picking (234)
- **Tech layer (rolled up)**: `frontend-widget` (2)
- **Owner team (rolled up)**: `dev-fe` (2)
- **Status (rolled up)**: majority `[-]` — breakdown: [-]=2
- **Priority (rolled up, max of 2 Bug/Feature items)**: **Minor** — breakdown: Minor=2
- **Triage confidence**: High

## Problem
Filter hiện auto-apply khi đổi giá trị. Khách yêu cầu thêm nút Apply Filters / Reset Filter, không lọc tự động.

## Evidence (raw quotes from source)
- **%Stock Type (214)** (row 10): Nút Apply filters, Reset filter — current: _Chưa có nút apply, reset_ → desired: _(Bỏ qua nếu đã có)
Làm giống site cũ, đồng bộ tất cả các view còn lại_
- **%Loose picking (234)** (row 10): Nút Apply filters, Reset filter — current: _Chưa có nút apply, reset_ → desired: _(Bỏ qua nếu đã có)
Làm giống site cũ, đồng bộ tất cả các view còn lại_


## Why platform-level (not per-view)
This is a single capability or convention that should be implemented once at the dashboard/widget framework level rather than per-view. Implementing per-view would create N copies of the same logic and regression risk.

## Next
Handoff `/ba` — revise PRD để spec capability platform-wide
