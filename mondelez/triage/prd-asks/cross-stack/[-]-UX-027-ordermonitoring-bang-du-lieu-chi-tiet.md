# UX-027: Bảng dữ liệu chi tiết

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `Cảnh báo đơn trễ (204)` row 22
- **Reporter**: Như
- **Tenant**: MDLZ
- **Area**: OrderMonitoring
- **Triage confidence**: Med
- **View**: Cảnh báo đơn trễ (204)
- **Tech layer**: `cross-stack` — Multiple layers (BE + FE, or data + BE + FE)
- **Owner team**: `mixed` — Multiple teams — needs coordination

## What's the gap?
- **Current**: Highlight nhấp nháy cảnh bảo các chuyến sắp trễ hoặc đã trễ rời kho
- **Desired**: Rule: dùng status của field Cảnh báo
At risk: gán label "Mới" và nhấp nháy 15p kể từ thời điểm chuyến đó có trạng thái "At risk". Sau 15p, nếu chuyến vẫn có trạng thái này thì highlight vàng (không nhấp nháy nữa)
Late departure open: gán label "Mới" và nhấp nháy 15p kể từ thời điểm chuyến đó có trạng thái "Late departure open". Sau 15p, nếu chuyến vẫn có trạng thái này thì highlight đỏ (không nhấp nháy nữa)

## Drift vs PRD-gap?
**To be determined** — kiểm tra PRD `docs/feature/<slug>/ba/prd.md` cho area `OrderMonitoring`:
- Nếu PRD đã spec hành vi mong muốn → đây là **drift** (UI không khớp PRD) → handoff `/da-trace`
- Nếu PRD chưa spec → đây là **PRD gap** → handoff `/ba` để revise PRD

## Note nội bộ
—

## DEV note
—

## Status
`New`

## Raw quote
> **Bảng dữ liệu chi tiết**
> Hiện tại: Highlight nhấp nháy cảnh bảo các chuyến sắp trễ hoặc đã trễ rời kho
> Mong muốn: Rule: dùng status của field Cảnh báo
At risk: gán label "Mới" và nhấp nháy 15p kể từ thời điểm chuyến đó có trạng thái "At risk". Sau 15p, nếu chuyến vẫn có trạng thái này thì highlight vàng (không nhấp nháy nữa)
Late departure open: gán label "Mới" và nhấp nháy 15p kể từ thời điểm chuyến đó có trạng thái "Late departure open". Sau 15p, nếu chuyến vẫn có trạng thái này thì highlight đỏ (không nhấp nháy nữa)

## Next
Default handoff: `/ba` (treat as PRD gap unless `/da-trace` confirms drift first).
