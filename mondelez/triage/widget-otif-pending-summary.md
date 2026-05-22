# WidgetOTIF — Pending Backlog Summary

- **View / Widget**: `WidgetOTIF` ([frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx](../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx))
- **Liên quan**: `widget-otif-detail.tsx`, `widget-otif-settings-dialog.tsx`, `widget-otif.columns.ts`
- **Tenant**: Mondelez (MDLZ)
- **Triage source**: [`backlog.md`](backlog.md) — Edit UX_UI_MDLZ.xlsx (2026-05-09)
- **PRD reference**: [`01-sections/otif/prd.md`](../01-sections/otif/prd.md)
- **Generated**: 2026-05-10 (`/da-triage`)
- **Refreshed**: 2026-05-16 (`/da-triage` — sau Phase 3 redesign ship + 2 fixes)
- **Go-Live tracker**: [`../go-live-tracker.md`](../go-live-tracker.md)

---

## Tổng quan trạng thái (2026-05-16 update)

| Trạng thái | Count | Ghi chú |
|---|---|---|
| ✅ Done (`Đã fixed`) | **23** | 20 từ done-summary + FEAT-057 + 3 mới đóng 2026-05-16 (BUG-042, UX-067, FEAT-056) |
| ⏳ Pending — chờ customer call | **1** | DISC-OTIF-RAW-VIEW (raw view walk-through với MDLZ) |
| 🔧 Work In Progress (`[W]`) | 0 | — |
| 🚫 Closed (Dup/OOS) | 0 | — |

→ **Phần lớn UX/feature/bug của OTIF đã ship**. Còn **1 task duy nhất** — discussion với khách về raw view.

---

## Snapshot — gì đã thay đổi từ snapshot 2026-05-10 → 2026-05-16

| # | ID | Trạng thái cũ | Trạng thái mới | Lý do đóng |
|---|---|---|---|---|
| 1 | **BUG-042** (Critical, etl-data) | `[-]` Draft | ✅ **[D] Done** | Lỗi sync `LineNo` STM↔SWM đã fix ở MV `mv_otif_stm_data`. % Infull khôi phục đúng. |
| 2 | **UX-067** (Med, frontend-config) | `[-]` Draft (no stub) | ✅ **[D] Done** + stub mới | Tab `%OTIF Chiều vận hành` đã có trong Phase 3 Cockpit redesign (PRD §6 + AC-05 PASS). |
| 3 | **FEAT-056** (Minor, cross-stack) | `[-]` Draft | ✅ **[D] Done** | Filter thời gian (Từ ngày / Đến ngày / Loại ngày / Day-Week-Month bucket) đã có đầy đủ trong `SqlFilterPanel`. |
| 4 | **RULE-OTIF-001** (Major, etl-data) | — (NEW) | ✅ **[D] Done** | Business rule mới: Ontime = `ATA ≤ ETA + 30 phút`. DDL MV `mv_otif` updated. |

→ Đợt fix gộp 2026-05-16 = **Phase 3 UI redesign + BUG-042 + RULE-OTIF-001**. Tất cả ship cùng đợt.

---

## Bảng tồn đọng (1 item)

| # | ID | Type | Priority | Owner | Title | Stub |
|---|---|---|---|---|---|---|
| 1 | **DISC-OTIF-RAW-VIEW** | Discovery | **Major** | PM (need customer call) | Thảo luận lần nữa với MDLZ về "view các raw" | [discoveries/unknown/[W]-DISC-OTIF-RAW-VIEW](discoveries/unknown/%5BW%5D-DISC-OTIF-RAW-VIEW-customer-discussion.md) |

### Chi tiết DISC-OTIF-RAW-VIEW

- **Vì sao Major**: Là task duy nhất chặn Go-Live của OTIF section. Mọi item khác đã ship.
- **Hypothesis về scope** (BA paraphrase, chưa confirm với khách):
  - **A** — Walk-through 3 tab Operation Summary / Fail Report / Detail (re-validate cột sau Phase 3 redesign)
  - **B** — Re-validate "failure reason" buckets sau khi data mới có (BUG-042 + RULE-30min đổi tỉ lệ)
  - **C** — Customer muốn 1 view raw mới (chưa rõ)
  - **D** — Permissions raw view (overlap FEAT-060 đang in-dev)
- **PM action**: schedule short call/workshop 15-30 phút với Mondelez Ops Manager tuần này
- **Output kỳ vọng**: Sau call → split thành sub-items cụ thể HOẶC đóng nếu không có gap

---

## Đề xuất route + assignee

| ID | Skill kế tiếp | Assignee | Lý do |
|---|---|---|---|
| DISC-OTIF-RAW-VIEW | Customer call (PM-led) → sau đó `/da-discovery` HOẶC `/ba` HOẶC `/da-trace` tuỳ output | PM Mondelez | Cần customer-call clarify scope trước khi route dev |

**ASSIGNMENTS**: 1 assigned (PM) / 0 TBD.

---

## Open questions cho PM/BA

1. Customer call cho raw-view scheduled chưa? (Khuyến nghị: trong tuần này 2026-05-16..23)
2. Có Mondelez stakeholder cụ thể tham gia call không (Ops Manager? IT? Data team)?
3. Sau call → có cần update PRD changelog v1.2.7 với feedback raw-view không?
4. Go-Live OTIF chỉ chặn bởi raw-view discussion, hay còn pending non-blocker khác mà PM chưa surface (vd backfill historical sau RULE-30min change)?

---

## Tham chiếu nhanh

- Go-Live tracker overall: [`../go-live-tracker.md`](../go-live-tracker.md)
- Backlog tổng: [`backlog.md`](backlog.md)
- Done summary: [`done-summary.md:132-156`](done-summary.md#L132) (20 items đã đóng đợt trước)
- By-team view: [`by-team.md`](by-team.md)
- PRD OTIF: [`../01-sections/otif/prd.md`](../01-sections/otif/prd.md)
- Spec OTIF: [`../01-sections/otif/spec.md`](../01-sections/otif/spec.md)
- Code: [`frontend/src/features/dashboard/components/widgets/order-monitor/`](../../../frontend/src/features/dashboard/components/widgets/order-monitor/)
- Stubs đóng đợt này:
  - [BUG-042](bugs/etl-data/%5BD%5D-BUG-042-otif-stm-lineno-strip-mismatch.md)
  - [UX-067](prd-asks/frontend-config/%5BD%5D-UX-067-otif-bang-chieu-van-hanh.md)
  - [FEAT-056](discoveries/cross-stack/%5BD%5D-FEAT-056-other-them-filter-thoi-gian.md)
  - [RULE-OTIF-001](bugs/etl-data/%5BD%5D-RULE-OTIF-001-ontime-tolerance-30min.md)
  - [FEAT-057 (đã đóng 2026-05-12)](discoveries/cross-stack/%5BD%5D-FEAT-057-other-bo-sung-ly-do-rot-la-gom-ca-2.md)
