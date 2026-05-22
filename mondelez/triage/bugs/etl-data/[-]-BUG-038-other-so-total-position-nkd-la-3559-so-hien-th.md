# BUG-038: Số total position NKD là 3559, số hiển thị chưa khớp

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `Sheet7` row 
- **Reporter**: MDLZ team (xem note nội bộ)
- **Tenant**: MDLZ
- **Area**: Other
- **Severity**: Sev2
- **Priority**: **Major** — Lỗi chức năng lớn — không có cách khắc phục tạm thời
- **Triage confidence**: High
- **View**: %U
- **Tech layer**: `etl-data` — SQL view / materialized view / ETL pipeline
- **Owner team**: `da` — Data Analyst (SQL views, ETL)

## Repro steps (best-effort từ raw text)
1. Mở dashboard view: %U
2. Quan sát Số total position NKD là 3559, số hiển thị chưa khớp
3. So sánh hành vi hiện tại vs mong muốn

## Expected
Số total position NKD là 3559, số hiển thị chưa khớp

## Actual (current)
(see raw quote)

## Note nội bộ
—

## DEV note
—

## Status trong source
`New`

## Raw quote
> **Số total position NKD là 3559, số hiển thị chưa khớp**
> Hiện tại: 
> Mong muốn: Số total position NKD là 3559, số hiển thị chưa khớp
> Note: 

## Next
Handoff `/qa-executor` — formal bug report + repro env capture (browser, account, tenant connection).
