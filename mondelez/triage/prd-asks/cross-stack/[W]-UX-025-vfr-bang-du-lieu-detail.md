# UX-025: Bảng dữ liệu detail

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `Tỷ lệ đáp ứng và tuân thủ` row 10
- **Reporter**: MDLZ team
- **Tenant**: MDLZ
- **Area**: VFR
- **Triage confidence**: Med
- **View**: Tỷ lệ đáp ứng
- **Tech layer**: `cross-stack` — Multiple layers (BE + FE, or data + BE + FE)
- **Owner team**: `mixed` — Multiple teams — needs coordination

## What's the gap?
- **Current**: - không nằm chung với nhóm chart
- **Desired**: - Nằm chung với nhóm chart của từng view, ở cuối cùng

## Drift vs PRD-gap?
**To be determined** — kiểm tra PRD `docs/feature/<slug>/ba/prd.md` cho area `VFR`:
- Nếu PRD đã spec hành vi mong muốn → đây là **drift** (UI không khớp PRD) → handoff `/da-trace`
- Nếu PRD chưa spec → đây là **PRD gap** → handoff `/ba` để revise PRD

## Note nội bộ
lấy tất cả các cột của reporting_schema.mv_test_dap_ung_gui_thau,  thị lên bảng dữ liệu chi tiết

## DEV note
—

## Status
`Đang fixing`

## Raw quote
> **Bảng dữ liệu detail**
> Hiện tại: - không nằm chung với nhóm chart
> Mong muốn: - Nằm chung với nhóm chart của từng view, ở cuối cùng

## Next
Default handoff: `/ba` (treat as PRD gap unless `/da-trace` confirms drift first).
