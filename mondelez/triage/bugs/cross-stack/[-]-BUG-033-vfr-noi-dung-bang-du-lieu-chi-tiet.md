# BUG-033: Nội dung Bảng dữ liệu chi tiết

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `VFR (224)` row 3
- **Reporter**: Thanh
- **Tenant**: MDLZ
- **Area**: VFR
- **Severity**: Sev3
- **Priority**: **Minor** — Lỗi chức năng nhỏ — có thể khắc phục tạm thời
- **Triage confidence**: Med
- **View**: VFR (224)
- **Tech layer**: `cross-stack` — Multiple layers (BE + FE, or data + BE + FE)
- **Owner team**: `mixed` — Multiple teams — needs coordination

## Repro steps (best-effort từ raw text)
1. Mở dashboard view: VFR (224)
2. Quan sát Nội dung Bảng dữ liệu chi tiết
3. So sánh hành vi hiện tại vs mong muốn

## Expected
Lấy các cột của bảng raw và hiển thị trên site

## Actual (current)
Chưa có dữ liệu

## Note nội bộ
Câu SQL của report đã được update ở gg sheet SQL

## DEV note
—

## Status trong source
`New`

## Raw quote
> **Nội dung Bảng dữ liệu chi tiết**
> Hiện tại: Chưa có dữ liệu
> Mong muốn: Lấy các cột của bảng raw và hiển thị trên site
> Note: Câu SQL của report đã được update ở gg sheet SQL

## Next
Handoff `/qa-executor` — formal bug report + repro env capture (browser, account, tenant connection).
