# DISC-OTIF-RAW-VIEW: Cần thảo luận thêm 1 lần với khách MDLZ về "view các raw"

- **Source**: PM internal — feedback follow-up sau Phase 3 redesign + BUG-042 fix
- **Reporter**: PM (sid.product@gosmartlog.com) — 2026-05-16
- **Tenant**: MDLZ
- **Area**: OrderMonitoring (OTIF widget — specifically detail/raw tab)
- **Priority**: **Major** — Blocker cuối cùng cho Go-Live OTIF (PM ghi nhận là task duy nhất còn pending)
- **Triage confidence**: Med — phạm vi "raw view" chưa rõ exact scope
- **View**: OTIF
- **Tech layer**: `unknown` — chưa định nghĩa tới khi customer-call clarify
- **Owner team**: PM + BA (cần customer-call MDLZ → sau đó route xuống dev nếu có change)

## Raw quote (PM internal note)
> "Hiện tại còn 1 task là cần thảo luận 1 lần nữa về view các raw với khách hàng."

## Initial problem hypothesis (BA paraphrase, chưa confirm với khách)

"View raw" trong context Mondelez OTIF có thể là:

| Hypothesis | Khả năng | Action |
|---|---|---|
| **A** — Tab `Chi tiết đơn hàng` (`detailTable` query) trong `OtifDetailPanel` — cột nào hiển thị, cột nào ẩn, default sort | Cao | Walk-through từng cột với customer |
| **B** — Tab `Fail Report` raw — định nghĩa "failure reason" buckets có khớp business intent không (sau khi rule Ontime+30min + BUG-042 fix → tỉ lệ buckets thay đổi) | Cao | Re-validate sau khi data mới có |
| **C** — Customer muốn 1 view raw mới (vd "raw STM/SWM join để debug khi metric lệch") — khác với 3 tab hiện tại | Trung | Cần discovery |
| **D** — Permissions: ai được xem raw, ai chỉ summary | Thấp | Liên quan FEAT-060 (phân quyền data theo kho) đang in-dev |

## Caveat

- Hypothesis A và B nhiều khả năng đúng nhất — vì Phase 3 redesign đã thay đổi structure detail panel + BUG-042 + RULE-30min fix sẽ làm các con số ở detail table khác trước. Customer cần re-walkthrough để confirm.
- Hypothesis C cần screenshot hoặc workshop ngắn — KHÔNG đoán từ phía dev.

## Status

`[W] WIP — chờ customer-call` (PM owns)

## History

| Date | Event | Actor | Ref |
|---|---|---|---|
| 2026-05-16 | PM open follow-up task sau Phase 3 redesign + 2 bug-fixes ship | PM | conversation 2026-05-16 |

## Next

1. **PM action** — schedule short call/workshop với Mondelez Ops Manager (15-30 phút) trong tuần này để walkthrough 3 tab raw (Operation Summary / Fail Report / Detail) — xác nhận hypothesis A & B
2. **BA action (sau call)** — nếu A hoặc B có gap → quyết định:
    - PRD gap → mở stub `prd-asks/` route `/ba` revision
    - Drift → mở stub `trace-asks/` route `/da-trace`
3. **Nếu C** — mở `/da-discovery` chính thức (5 câu hỏi office-hours) trước khi commit dev
4. **Update Go-Live tracker** sau call: chuyển task từ Pending → Done HOẶC split thành sub-items cụ thể

## Liên quan

- [OTIF PRD §6 detailTable + AC-06](../../../01-sections/otif/prd.md) — định nghĩa raw cột hiện tại
- [OTIF spec.md §1 Component Tree](../../../01-sections/otif/spec.md) — 3 inner tab của OtifDetailPanel
- [BUG-042 (Done)](../../bugs/etl-data/%5BD%5D-BUG-042-otif-stm-lineno-strip-mismatch.md) — fix gây thay đổi số raw
- [RULE-OTIF-001 (Done)](../../bugs/etl-data/%5BD%5D-RULE-OTIF-001-ontime-tolerance-30min.md) — fix gây thay đổi raw Ontime status
- [go-live-tracker.md](../../../go-live-tracker.md) — Go-Live tracker overall
