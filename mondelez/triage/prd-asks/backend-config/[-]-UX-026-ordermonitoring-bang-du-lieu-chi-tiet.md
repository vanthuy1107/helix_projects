# UX-026: Bảng dữ liệu chi tiết

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `Cảnh báo đơn trễ (204)` row 21
- **Reporter**: Như
- **Tenant**: MDLZ
- **Area**: OrderMonitoring
- **Triage confidence**: Med
- **View**: Cảnh báo đơn trễ (204)
- **Tech layer**: `backend-config` — JSON QueryConfig / Dynamic Query param template (no code change)
- **Owner team**: `dev-be` — Backend Developer (.NET, EF Core, Dynamic Query)

## What's the gap?
- **Current**: Thêm ô điền số phút để truyền vào query => ảnh hưởng logic phân loại status của chuyến
- **Desired**: user điền số phút => truyền parameter xuống câu query để phân loại status

## Drift vs PRD-gap?
**To be determined** — kiểm tra PRD `docs/feature/<slug>/ba/prd.md` cho area `OrderMonitoring`:
- Nếu PRD đã spec hành vi mong muốn → đây là **drift** (UI không khớp PRD) → handoff `/da-trace`
- Nếu PRD chưa spec → đây là **PRD gap** → handoff `/ba` để revise PRD

## Note nội bộ
Liên hệ Như nếu khó hiểu
Point này có thể hẹn khách được

## DEV note
—

## Status
`New`

## Raw quote
> **Bảng dữ liệu chi tiết**
> Hiện tại: Thêm ô điền số phút để truyền vào query => ảnh hưởng logic phân loại status của chuyến
> Mong muốn: user điền số phút => truyền parameter xuống câu query để phân loại status

## Next
Default handoff: `/ba` (treat as PRD gap unless `/da-trace` confirms drift first).
