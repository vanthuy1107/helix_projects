# PLATFORM-MULTI-SELECT-FILTER: Multi-select cho filter pane (toàn bộ dashboard)

- **Triage scope**: PLATFORM-LEVEL — affects 15 items across 4 views
- **Type**: UX
- **Area**: Platform
- **Tenant**: MDLZ (Mondelez), but pattern likely applicable cross-tenant
- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — multiple rows
- **Affected views**: %Stock Type (214), %Loose picking (234), VFR, Tỷ lệ đáp ứng và tuân thủ
- **Tech layer (rolled up)**: `backend-config` (13), `frontend-widget` (2)
- **Owner team (rolled up)**: `dev-be` (7), `closed` (6), `dev-fe` (2)
- **Status (rolled up)**: majority `[W]` — breakdown: [W]=7, [X]=6, [-]=2
- **Priority (rolled up, max of 7 Bug/Feature items)**: **Major** — breakdown: Major=7
- **Triage confidence**: High

## Problem
Filter pane hiện chỉ cho phép chọn 1 giá trị (single option). Khách MDLZ yêu cầu đổi thành multi-select cho phần lớn filter (Kho, Khu vực, Nhà vận tải, Loại xe, Kênh bán hàng, ...). Lặp lại 15 lần trên 8+ view.

## Evidence (raw quotes from source)
- **%Stock Type (214)** (row 3): Bộ lọc — current: _Single option_ → desired: _(Bỏ qua nếu đã có)
Đổi thành multiple option_
- **%Loose picking (234)** (row 3): Bộ lọc — current: _Single option_ → desired: _(Bỏ qua nếu đã có)
Đổi thành multiple option_
- **VFR** (row 2): Bộ lọc "Kho lấy hàng" — current: _- Giá trị bộ lọc chưa đúng
- Chỉ cho phép chọn 1 giá trị_ → desired: _- Danh sách bộ lọc gồm: lấy từ câu SQL
- Cho phép chọn nhiều giá trị_
- **VFR** (row 4): Bộ lọc "Khu vực giao hàng" — current: _- Giá trị bộ lọc chưa đúng
- Chỉ cho phép chọn 1 giá trị_ → desired: _- Danh sách bộ lọc gồm: lấy từ câu SQL
- Cho phép chọn nhiều giá trị_
- **VFR** (row 5): Bộ lọc "Nhà vận tải" — current: _- Giá trị bộ lọc chưa đúng
- Chỉ cho phép chọn 1 giá trị_ → desired: _- Danh sách bộ lọc gồm: lấy từ câu SQL
- Cho phép chọn nhiều giá trị_
- **VFR** (row 6): Bộ lọc "Loại xe gửi thầu" — current: _- Giá trị bộ lọc chưa đúng
- Chỉ cho phép chọn 1 giá trị_ → desired: _- Danh sách bộ lọc gồm: lấy từ câu SQL
- Cho phép chọn nhiều giá trị_
- **Tỷ lệ đáp ứng và tuân thủ** (row 2): Bộ lọc "Kho lấy hàng" — current: _- Giá trị bộ lọc chưa đúng
- Chỉ cho phép chọn 1 giá trị_ → desired: _- Danh sách bộ lọc gồm: lấy từ câu SQL
- Cho phép chọn nhiều giá trị_
- **Tỷ lệ đáp ứng và tuân thủ** (row 4): Bộ lọc "Khu vực giao hàng" — current: _- Giá trị bộ lọc chưa đúng
- Chỉ cho phép chọn 1 giá trị_ → desired: _- Danh sách bộ lọc gồm: lấy từ câu SQL
- Cho phép chọn nhiều giá trị_
- **Tỷ lệ đáp ứng và tuân thủ** (row 5): Bộ lọc "Nhà vận tải" — current: _- Giá trị bộ lọc chưa đúng
- Chỉ cho phép chọn 1 giá trị_ → desired: _- Danh sách bộ lọc gồm: lấy từ câu SQL
- Cho phép chọn nhiều giá trị_
- **VFR** (row 16): Bộ lọc "Kho lấy hàng" — current: _- Giá trị bộ lọc chưa đúng
- Chỉ cho phép chọn 1 giá trị_ → desired: _- Danh sách bộ lọc gồm: lấy từ câu SQL
- Cho phép chọn nhiều giá trị_
- **VFR** (row 17): Bộ lọc "Điểm giao hàng" — current: _- Giá trị bộ lọc chưa đúng
- Chỉ cho phép chọn 1 giá trị_ → desired: _- Danh sách bộ lọc gồm: lấy từ câu SQL
- Cho phép chọn nhiều giá trị_
- **VFR** (row 18): Bộ lọc "Khu vực giao hàng" — current: _- Giá trị bộ lọc chưa đúng
- Chỉ cho phép chọn 1 giá trị_ → desired: _- Danh sách bộ lọc gồm: lấy từ câu SQL
- Cho phép chọn nhiều giá trị_
- **VFR** (row 19): Bộ lọc "Nhà vận tải" — current: _- Giá trị bộ lọc chưa đúng
- Chỉ cho phép chọn 1 giá trị_ → desired: _- Danh sách bộ lọc gồm: lấy từ câu SQL
- Cho phép chọn nhiều giá trị_
- **VFR** (row 20): Bộ lọc "Loại xe gửi thầu" — current: _- Giá trị bộ lọc chưa đúng
- Chỉ cho phép chọn 1 giá trị_ → desired: _- Danh sách bộ lọc gồm: lấy từ câu SQL
- Cho phép chọn nhiều giá trị_
- **VFR** (row 3): Bộ lọc "Điểm giao hàng" — current: _- Giá trị bộ lọc chưa đúng
- Chỉ cho phép chọn 1 giá trị_ → desired: _- Danh sách bộ lọc gồm: lấy từ câu SQL
- Cho phép chọn nhiều giá trị_


## Why platform-level (not per-view)
This is a single capability or convention that should be implemented once at the dashboard/widget framework level rather than per-view. Implementing per-view would create N copies of the same logic and regression risk.

## Next
Handoff `/ba` — revise PRD để spec capability platform-wide
