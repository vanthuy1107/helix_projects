# PLATFORM-FILTER-FIXED-SCORECARD: Filter pane fixed độc lập với scorecard (scorecard scroll)

- **Triage scope**: PLATFORM-LEVEL — affects 2 items across 2 views
- **Type**: UX
- **Area**: Platform
- **Tenant**: MDLZ (Mondelez), but pattern likely applicable cross-tenant
- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — multiple rows
- **Affected views**: %Stock Type (214), %Loose picking (234)
- **Tech layer (rolled up)**: `frontend-widget` (2)
- **Owner team (rolled up)**: `dev-fe` (2)
- **Status (rolled up)**: majority `[-]` — breakdown: [-]=2
- **Priority**: _N/A (UX-only platform stub)_
- **Triage confidence**: High

## Problem
Filter pane hiện đang fixed cùng scorecard. Khách yêu cầu chỉ filter pane fixed, scorecard scroll như chart bên dưới.

## Evidence (raw quotes from source)
- **%Stock Type (214)** (row 2): Bộ lọc — current: _Filter pane đang fixed cùng với scorecard_ → desired: _(Bỏ qua nếu đã có)
Fixed only filter pane. Scorecard vẫn scroll như các chart bên dưới_
- **%Loose picking (234)** (row 2): Bộ lọc — current: _Filter pane đang fixed cùng với scorecard_ → desired: _(Bỏ qua nếu đã có)
Fixed only filter pane. Scorecard vẫn scroll như các chart bên dưới_


## Why platform-level (not per-view)
This is a single capability or convention that should be implemented once at the dashboard/widget framework level rather than per-view. Implementing per-view would create N copies of the same logic and regression risk.

## Next
Handoff `/ba` — revise PRD để spec capability platform-wide
