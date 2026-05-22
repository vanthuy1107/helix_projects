# BUG-001: Bảng dữ liệu detail

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `VFR` row 11
- **Reporter**: MDLZ team (xem note nội bộ)
- **Tenant**: MDLZ
- **Area**: VFR
- **Severity**: Sev2
- **Priority**: **Major** — Lỗi chức năng lớn — không có cách khắc phục tạm thời
- **Triage confidence**: High
- **View**: 
- **Tech layer**: `cross-stack` — Multiple layers (BE + FE, or data + BE + FE)
- **Owner team**: `mixed` — Multiple teams — needs coordination

## Repro steps (best-effort từ raw text)
1. Mở dashboard view: 
2. Quan sát Bảng dữ liệu detail
3. So sánh hành vi hiện tại vs mong muốn

## Expected
- tạo thêm 1 bảng
- Tên của 2 bảng lần lượt là "Bảng dữ liệu chi tiết của VFR theo loại xe gửi thầu", "Bảng dữ liệu chi tiết của VFR theo loại xe vận hành"
- Nằm chung với nhóm chart của từng view, ở cuối cùng

## Actual (current)
- chỉ có 1 bảng 
- Tên bảng chưa đúng
- không nằm chung với nhóm chart

## Note nội bộ
lấy tất cả các cột của mv_test_vfr_theo_loai_xe_gui_thau, mv_test_vfr_van_hanh để hiển thị lên 2 bảng dữ liệu chi tiết

## DEV note
—

## Status trong source
`Đang fixing`

## Raw quote
> **Bảng dữ liệu detail**
> Hiện tại: - chỉ có 1 bảng 
- Tên bảng chưa đúng
- không nằm chung với nhóm chart
> Mong muốn: - tạo thêm 1 bảng
- Tên của 2 bảng lần lượt là "Bảng dữ liệu chi tiết của VFR theo loại xe gửi thầu", "Bảng dữ liệu chi tiết của VFR theo loại xe vận hành"
- Nằm chung với nhóm chart của từng view, ở cuối cùng
> Note: lấy tất cả các cột của mv_test_vfr_theo_loai_xe_gui_thau, mv_test_vfr_van_hanh để hiển thị lên 2 bảng dữ liệu chi tiết

## Next
Handoff `/qa-executor` — formal bug report + repro env capture (browser, account, tenant connection).
