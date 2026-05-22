# FEAT-034: Nội dung Bảng dữ liệu chi tiết

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `Cảnh báo đơn trễ (204)` row 20
- **Requested by**: Như
- **Tenant**: MDLZ
- **Area**: OrderMonitoring
- **Priority**: **Major** — Lỗi chức năng lớn — không có cách khắc phục tạm thời
- **Triage confidence**: High
- **View**: Cảnh báo đơn trễ (204)
- **Tech layer**: `cross-stack` — Multiple layers (BE + FE, or data + BE + FE)
- **Owner team**: `mixed` — Multiple teams — needs coordination

## Raw quote
> **Nội dung Bảng dữ liệu chi tiết**
> Hiện tại: Bổ sung field cho report
> Mong muốn: đầy đủ theo field trong link này OTIF report.xlsx

Ưu tiên sort lên đầu các chuyến có status: At risk > Late departure open. Các status còn lại sort theo TG bắt buộc rời kho giảm dần
> Note: Câu SQL trong gg sheet
Feedback

## Initial problem hypothesis (BA paraphrase, KHÔNG phải solution)
Khách yêu cầu thêm capability "Nội dung Bảng dữ liệu chi tiết". Cần discovery để xác định:
- Vấn đề thật sự khách đang giải quyết là gì?
- Có alternative đơn giản hơn không?
- Có ảnh hưởng tới các tenant khác không (chỉ MDLZ-specific hay platform feature)?

## Note nội bộ
Câu SQL trong gg sheet
Feedback

## DEV note
—

## Status
`New`

## Next
Handoff `/da-discovery` — chạy 5 câu hỏi office-hours trước khi commit (user, value, alternative, success metric, blast radius).
