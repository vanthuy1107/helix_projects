# PLATFORM-DOWNLOAD-IMG-EXCEL: Download hình ảnh / Excel cho từng chart & report

- **Triage scope**: PLATFORM-LEVEL — affects 5 items across 5 views
- **Type**: Feature
- **Area**: Platform
- **Tenant**: MDLZ (Mondelez), but pattern likely applicable cross-tenant
- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — multiple rows
- **Affected views**: VFR, Tỷ lệ đáp ứng và tuân thủ, %Stock Type (214), VFR (224), %Loose picking (234)
- **Tech layer (rolled up)**: `frontend-widget` (5)
- **Owner team (rolled up)**: `dev-fe` (5)
- **Status (rolled up)**: majority `[-]` — breakdown: [-]=4, [W]=1
- **Priority (rolled up, max of 5 Bug/Feature items)**: **Minor** — breakdown: Minor=5
- **Triage confidence**: High

## Problem
Chưa có capability download chart sang ảnh/excel. Khách muốn bổ sung trên 5 view (đã được đánh dấu "làm sau khi hoàn thiện tất cả view").

## Evidence (raw quotes from source)
- **VFR** (row 14): Tính năng xuất excel của từng chart — current: _Chưa có_ → desired: _Bổ sung_
- **Tỷ lệ đáp ứng và tuân thủ** (row 13): Tính năng xuất excel của từng chart — current: _Chưa có_ → desired: _Bổ sung_
- **%Stock Type (214)** (row 11): Tính năng download hình ảnh, excel — current: _Chưa có download report, download chart_ → desired: _(Bỏ qua nếu đã có)
Làm giống site cũ, đồng bộ tất cả các view còn lại_
- **VFR (224)** (row 7): Tính năng download hình ảnh, excel — current: _Chưa có_ → desired: _Bổ sung các các chart và table(PNG ,PDF, EXCEL,CSV), report  excel, csv_
- **%Loose picking (234)** (row 11): Tính năng download hình ảnh, excel — current: _Chưa có download report, download chart_ → desired: _(Bỏ qua nếu đã có)
Làm giống site cũ, đồng bộ tất cả các view còn lại_


## Why platform-level (not per-view)
This is a single capability or convention that should be implemented once at the dashboard/widget framework level rather than per-view. Implementing per-view would create N copies of the same logic and regression risk.

## Next
Handoff `/da-discovery` — chạy 5 câu hỏi office-hours trước khi commit
