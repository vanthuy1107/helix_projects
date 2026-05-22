# BUG-041: Số liệu chưa realtime và chưa đúng với 3PL record
 + Chart không có thể hiện đủ 

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `Sheet7` row 47
- **Reporter**: MDLZ team (xem note nội bộ)
- **Tenant**: MDLZ
- **Area**: Inventory
- **Severity**: Sev2
- **Priority**: **Major** — Lỗi chức năng lớn — không có cách khắc phục tạm thời
- **Triage confidence**: High
- **View**: %Stock Type
- **Tech layer**: `etl-data` — SQL view / materialized view / ETL pipeline
- **Owner team**: `da` — Data Analyst (SQL views, ETL)

## Repro steps (best-effort từ raw text)
1. Mở dashboard view: %Stock Type
2. Quan sát Số liệu chưa realtime và chưa đúng với 3PL record
 + Chart không có thể hiện đủ 
3. So sánh hành vi hiện tại vs mong muốn

## Expected
Số liệu chưa realtime và chưa đúng với 3PL record
 + Chart không có thể hiện đủ thông tin như vị trí trống; Slob
 + Chưa coi được overview tồn kho trên 1 chart + số liệu

## Actual (current)
(see raw quote)

## Note nội bộ
—

## DEV note
—

## Status trong source
`New`

## Raw quote
> **Số liệu chưa realtime và chưa đúng với 3PL record
 + Chart không có thể hiện đủ **
> Hiện tại: 
> Mong muốn: Số liệu chưa realtime và chưa đúng với 3PL record
 + Chart không có thể hiện đủ thông tin như vị trí trống; Slob
 + Chưa coi được overview tồn kho trên 1 chart + số liệu
> Note: 

## Next
Handoff `/qa-executor` — formal bug report + repro env capture (browser, account, tenant connection).
