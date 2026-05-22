# PLATFORM-VALUE-THOUSAND-SEP: Thousand separator (dấu phẩy) cho card KPI

- **Triage scope**: PLATFORM-LEVEL — affects 1 items across 1 views
- **Type**: UX
- **Area**: Platform
- **Tenant**: MDLZ (Mondelez), but pattern likely applicable cross-tenant
- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — multiple rows
- **Affected views**: Sheet7
- **Tech layer (rolled up)**: `frontend-widget` (1)
- **Owner team (rolled up)**: `dev-fe` (1)
- **Status (rolled up)**: majority `[W]` — breakdown: [W]=1
- **Priority**: _N/A (UX-only platform stub)_
- **Triage confidence**: High

## Problem
Card KPI số lớn chưa có dấu phẩy phân cách hàng nghìn — khách MDLZ đã request và team SLG đã nhận yêu cầu.

## Evidence (raw quotes from source)
- **Sheet7** (row 23): Thêm dấu phẩy phân cách hàng nghìn đối với các card KPI số lượng — current: __ → desired: _Thêm dấu phẩy phân cách hàng nghìn đối với các card KPI số lượng_


## Why platform-level (not per-view)
This is a single capability or convention that should be implemented once at the dashboard/widget framework level rather than per-view. Implementing per-view would create N copies of the same logic and regression risk.

## Next
Handoff `/ba` — revise PRD để spec capability platform-wide
