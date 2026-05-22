# BUG-040: Bộ lọc Kho: giá trị BKD, NKD chưa work đúng
 - BKD: internal + external , bộ lọc

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `Sheet7` row 
- **Reporter**: MDLZ team (xem note nội bộ)
- **Tenant**: MDLZ
- **Area**: FlashDaily
- **Severity**: Sev3
- **Priority**: **Minor** — Lỗi chức năng nhỏ — có thể khắc phục tạm thời
- **Triage confidence**: High
- **View**: Flash report
- **Tech layer**: `frontend-widget` — React component / Recharts / Shadcn UI (multi-select, chart, download)
- **Owner team**: `dev-fe` — Frontend Developer (React 19, Shadcn, Recharts)

## Repro steps (best-effort từ raw text)
1. Mở dashboard view: Flash report
2. Quan sát Bộ lọc Kho: giá trị BKD, NKD chưa work đúng
 - BKD: internal + external , bộ lọc
3. So sánh hành vi hiện tại vs mong muốn

## Expected
Bộ lọc Kho: giá trị BKD, NKD chưa work đúng
 - BKD: internal + external , bộ lọc nhóm hàng chưa work

## Actual (current)
(see raw quote)

## Note nội bộ
—

## DEV note
—

## Status trong source
`New`

## Raw quote
> **Bộ lọc Kho: giá trị BKD, NKD chưa work đúng
 - BKD: internal + external , bộ lọc**
> Hiện tại: 
> Mong muốn: Bộ lọc Kho: giá trị BKD, NKD chưa work đúng
 - BKD: internal + external , bộ lọc nhóm hàng chưa work
> Note: 

## Next
Handoff `/qa-executor` — formal bug report + repro env capture (browser, account, tenant connection).
