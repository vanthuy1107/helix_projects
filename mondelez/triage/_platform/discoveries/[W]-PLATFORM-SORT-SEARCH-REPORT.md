# PLATFORM-SORT-SEARCH-REPORT: Sort + Search bar ở report (mọi view có report)

- **Triage scope**: PLATFORM-LEVEL — affects 5 items across 5 views
- **Type**: Feature
- **Area**: Platform
- **Tenant**: MDLZ (Mondelez), but pattern likely applicable cross-tenant
- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — multiple rows
- **Affected views**: Tiến độ xuất hàng (204), %Stock Type (214), Movement transaction (214), %Utilization (224), %Loose picking (234)
- **Tech layer (rolled up)**: `frontend-widget` (5)
- **Owner team (rolled up)**: `dev-fe` (5)
- **Status (rolled up)**: majority `[W]` — breakdown: [W]=3, [-]=2
- **Priority (rolled up, max of 5 Bug/Feature items)**: **Minor** — breakdown: Minor=5
- **Triage confidence**: High

## Problem
Mọi report hiện chưa có sort + search. Khách yêu cầu thêm thanh search + sort, field ít giá trị → select option. Lặp 5 view.

## Evidence (raw quotes from source)
- **Tiến độ xuất hàng (204)** (row 16): Sort + Search ở report — current: _Chưa có search/sort ở report_ → desired: _(Bỏ qua nếu đã có)
Thêm thanh search bar + sort ở report. Nguyên tắc:
- Các field có ít giá trị thì dùng select option, _
- **%Stock Type (214)** (row 16): Sort + Search ở report — current: _Chưa có search/sort ở report_ → desired: _(Bỏ qua nếu đã có)
Thêm thanh search bar + sort ở report. Nguyên tắc:
- Các field có ít giá trị thì dùng select option, _
- **Movement transaction (214)** (row 16): Sort + Search ở report — current: _Chưa có search/sort ở report_ → desired: _(Bỏ qua nếu đã có)
Thêm thanh search bar + sort ở report. Nguyên tắc:
- Các field có ít giá trị thì dùng select option, _
- **%Utilization (224)** (row 16): Sort + Search ở report — current: _Chưa có search/sort ở report_ → desired: _(Bỏ qua nếu đã có)
Thêm thanh search bar + sort ở report. Nguyên tắc:
- Các field có ít giá trị thì dùng select option, _
- **%Loose picking (234)** (row 16): Sort + Search ở report — current: _Chưa có search/sort ở report_ → desired: _(Bỏ qua nếu đã có)
Thêm thanh search bar + sort ở report. Nguyên tắc:
- Các field có ít giá trị thì dùng select option, _


## Why platform-level (not per-view)
This is a single capability or convention that should be implemented once at the dashboard/widget framework level rather than per-view. Implementing per-view would create N copies of the same logic and regression risk.

## Next
Handoff `/da-discovery` — chạy 5 câu hỏi office-hours trước khi commit
