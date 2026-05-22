# BUG-036: Dòng chú thích của card view " Tỷ lệ đáp ứng chuyến gửi thầu"

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `Tỷ lệ Đáp ứng & Tuân thủ (234)` row 4
- **Reporter**: Thanh
- **Tenant**: MDLZ
- **Area**: VFR
- **Severity**: Sev2
- **Priority**: **Major** — Lỗi chức năng lớn — không có cách khắc phục tạm thời
- **Triage confidence**: High
- **View**: Tỷ lệ Đáp ứng & Tuân thủ (234)
- **Tech layer**: `frontend-config` — FormConfig / ViewConfig / dashboard layout (label, layout, scorecard rename)
- **Owner team**: `dev-fe` — Frontend Developer (React 19, Shadcn, Recharts)

## Repro steps (best-effort từ raw text)
1. Mở dashboard view: Tỷ lệ Đáp ứng & Tuân thủ (234)
2. Quan sát Dòng chú thích của card view " Tỷ lệ đáp ứng chuyến gửi thầu"
3. So sánh hành vi hiện tại vs mong muốn

## Expected
Mô tả lại, lần lượt là:
- Tỷ lệ chuyến gửi thầu được đáp ứng
- Số chuyến gửi thầu được đáp ứng
- Số chuyến gửi thầu không được đáp ứng
- Tổng số chuyến gửi thầu
- Tổng số chuyến vận hành

## Actual (current)
Các dòng phía dưới số mô tả chưa đúng

## Note nội bộ
—

## DEV note
—

## Status trong source
`New`

## Raw quote
> **Dòng chú thích của card view " Tỷ lệ đáp ứng chuyến gửi thầu"**
> Hiện tại: Các dòng phía dưới số mô tả chưa đúng
> Mong muốn: Mô tả lại, lần lượt là:
- Tỷ lệ chuyến gửi thầu được đáp ứng
- Số chuyến gửi thầu được đáp ứng
- Số chuyến gửi thầu không được đáp ứng
- Tổng số chuyến gửi thầu
- Tổng số chuyến vận hành
> Note: 

## Next
Handoff `/qa-executor` — formal bug report + repro env capture (browser, account, tenant connection).
