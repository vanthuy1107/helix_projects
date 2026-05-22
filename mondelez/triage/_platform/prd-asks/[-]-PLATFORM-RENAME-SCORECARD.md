# PLATFORM-RENAME-SCORECARD: Đổi tên scorecard chuẩn hoá theo terminology mới

- **Triage scope**: PLATFORM-LEVEL — affects 2 items across 2 views
- **Type**: UX
- **Area**: Platform
- **Tenant**: MDLZ (Mondelez), but pattern likely applicable cross-tenant
- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — multiple rows
- **Affected views**: %Stock Type (214), Sheet7
- **Tech layer (rolled up)**: `frontend-config` (2)
- **Owner team (rolled up)**: `dev-fe` (2)
- **Status (rolled up)**: majority `[-]` — breakdown: [-]=2
- **Priority**: _N/A (UX-only platform stub)_
- **Triage confidence**: High

## Problem
Một số scorecard cần đổi tên (vd "Tổng Pallet Nhập" → "Tổng Volume Inbound", "Tổng volume" → "Tổng volume kế hoạch", "Movement Rows" bỏ).

## Evidence (raw quotes from source)
- **%Stock Type (214)** (row 19): Đổi tên scorecard — current: __ → desired: __
- **Sheet7** (row 54): Đổi tên scorecard
 - Tổng Pallet Nhập => Tổng Volume Inbound
 - Tổng CBM Xuất => — current: __ → desired: _Đổi tên scorecard
 - Tổng Pallet Nhập => Tổng Volume Inbound
 - Tổng CBM Xuất => Tổng Volume Outbound
 - Đơn in DO => Pr_


## Why platform-level (not per-view)
This is a single capability or convention that should be implemented once at the dashboard/widget framework level rather than per-view. Implementing per-view would create N copies of the same logic and regression risk.

## Next
Handoff `/ba` — revise PRD để spec capability platform-wide
