# UX-029: Bộ lọc "Khoảng thời gian"

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `Tỷ lệ Đáp ứng & Tuân thủ (234)` row 9
- **Reporter**: Thanh
- **Tenant**: MDLZ
- **Area**: VFR
- **Triage confidence**: High
- **View**: Tỷ lệ Đáp ứng & Tuân thủ (234)
- **Tech layer**: `frontend-config` — FormConfig / ViewConfig / dashboard layout (label, layout, scorecard rename)
- **Owner team**: `dev-fe` — Frontend Developer (React 19, Shadcn, Recharts)

## What's the gap?
- **Current**: Tên "DATE RANGE"
- **Desired**: Đổi tên thành "Khoảng thời gian"

## Drift vs PRD-gap?
**To be determined** — kiểm tra PRD `docs/feature/<slug>/ba/prd.md` cho area `VFR`:
- Nếu PRD đã spec hành vi mong muốn → đây là **drift** (UI không khớp PRD) → handoff `/da-trace`
- Nếu PRD chưa spec → đây là **PRD gap** → handoff `/ba` để revise PRD

## Note nội bộ
—

## DEV note
—

## Status
`New`

## Raw quote
> **Bộ lọc "Khoảng thời gian"**
> Hiện tại: Tên "DATE RANGE"
> Mong muốn: Đổi tên thành "Khoảng thời gian"

## Next
Default handoff: `/ba` (treat as PRD gap unless `/da-trace` confirms drift first).
