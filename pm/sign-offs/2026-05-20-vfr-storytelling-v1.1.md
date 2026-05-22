# PM Sign-off — VFR Storytelling Refresh v1.1

**Date**: 2026-05-20
**Signed by**: thuy le — PM/DA team (squad1@gosmartlog.com), self-driven per memory `feedback_pm_driven_feature_attribution`
**Feature**: [`docs/feature/vfr-storytelling-refresh`](../../../docs/feature/vfr-storytelling-refresh/)
**Plan**: [`plan.md v1.1`](../../../docs/feature/vfr-storytelling-refresh/dev/plan.md) — frozen immutable từ thời điểm này
**PRD anchor**: [`projects/mondelez/01-sections/vfr/vfr-prd.md`](../../mondelez/01-sections/vfr/vfr-prd.md) §3.6 + §15 OQ-06 + §18

---

## Approval scope

5 sign-off Q0-Q4 approved 2026-05-20. 3 ADR + 1 OQ closed inline pre-sign-off via PRD anchoring.

| # | Item | Decision | Anchor |
|---|---|---|---|
| Q0 | plan.md v1.1 | ✅ Approved — flip `[P]` → `[A]` immutable | plan.md header |
| Q1 | ADR-G2 — Hero GT vs VH delta luôn visible | ✅ Approved | plan.md §3 ADR-G2 + PRD §18.2 AC-S2 |
| Q2 | ADR-G3 — 5-bucket → RAG 3-tier color collapse | ✅ Approved — closes OQ-07 | plan.md §3 ADR-G3 + PRD §18.2 AC-S7 |
| Q3 | ADR-G4 — Admin-paste SQL `byVendor` (canonical ở `vfr-spec.md §22`) | ✅ Approved | plan.md §3 ADR-G4 |
| Q4 | ADR-N4 — 4 persona presets BOD / Ops / Carrier / Planning | ✅ Approved | plan.md §3 ADR-N4 + PRD §18.3 matrix |

### Pre-closed (no separate sign-off needed)

| ADR | Decision | Why pre-closed |
|---|---|---|
| ADR-G1 — VFR target 85% + RAG 75/85 | ✅ Anchored vào PRD §3.6 (PM/SC Manager confirm 2026-05-20) | Target = product decision, lives in PRD not in plan |
| ADR-N1 — Hardcode `DEFAULT_VFR_TARGETS = { overall: 85 }` | ✅ Follows OTIF v1.1 precedent | Single-line constant, conventional |
| ADR-N2 — Exception magnitude `(target − vfr) × planned_cbm`, threshold 50%, window 7d | ✅ Anchored vào PRD §18.4 | Business rule lives in PRD |
| ADR-N3 — Branch `feat-vfr-late-alert` misnomer accepted | ✅ Anchored vào PRD §13 + §15 OQ-05 | Late-alert ở widget riêng, no cross-ref needed |

---

## Rationale per decision

**Q1 — ADR-G2 (GT vs VH delta)**: Storytelling principle headline + diagnostic. GT vs VH gap là insight #1 của VFR; ẩn sau toggle (PRD §17 D1) gây serial scan, đặc biệt tệ cho Planning persona. 2 KPI queries always-on overhead acceptable (ClickHouse MV pre-aggregated P95 <500ms per Spec §15).

**Q2 — ADR-G3 (RAG color collapse)**: 5 màu rời (tím/đỏ/vàng/xanh dương/xanh lá) violate RAG convention shared. User không có muscle memory cho purple = Avg. Rollout risk = 7-day banner notice (per plan §8.2). Acceptable.

**Q3 — ADR-G4 (admin-paste SQL)**: Match OTIF storytelling refresh pattern + memory `feedback_no_default_sql_in_widget_code`. Backend zero touch. Phase 3 prerequisite = write `vfr-spec.md §22` canonical SQL trước khi admin paste.

**Q4 — ADR-N4 (4 persona presets)**: Per-persona view requirement đã anchor vào PRD §18.3. Implementation pattern = `visibleSections: string[]` array, simpler hơn per-preset config object. Legacy `preset-om-vfr` alias đến `-planning` để không break existing dashboards.

---

## Phase ordering — unblocked

| Phase | Status | Gate |
|---|---|---|
| Phase 0 (Plan & approval) | ✅ Done 2026-05-20 | — |
| Phase 1 (Quick wins — action titles + exception panel + RAG cells) | 🚀 Unblocked, ready to start | All Q0-Q4 approved |
| Phase 2 (Hero + chart restructure) | ⏳ Blocked by Phase 1 ship | — |
| Phase 3 (By Vendor + persona presets) | ⏳ Blocked by Phase 2 ship + `vfr-spec.md §22` written | Q3 + Q4 approved |
| Phase 4 (Polish) | ⏳ Blocked by Phase 3 ship | — |
| Phase 5-7 (Review/Test/Ship) | ⏳ Sequential | — |

**Effort total v1.1**: ~5-7 ngày dev + 1.5 ngày review/test/ship = **~6.5-8.5 ngày calendar**.

---

## Risks tracked

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| RISK-VFR-01: Bucket 95% boundary (BUG-VFR-08) chưa rollout sang tenant config khi v2 ship | Medium | Medium | Coordinate với Rollout team; bucket count nhỏ lệch trên `vfr_max = 95.0` exact, không ảnh hưởng UX | Open |
| RISK-VFR-02: User mental model "tím = Avg" sau switch RAG | Medium | Low | Dashboard banner 7 ngày + i18n tooltip rõ ràng | Mitigated |
| RISK-VFR-03: Exception panel chỉ aggregate page-1 (5000 rows) của detail SQL | Low | Low | Mondelez detail rows ~<5000/7d; Phase 5 follow-up nếu cần dedicated `exceptionAggregate` SQL | Accepted |
| RISK-VFR-04: BUG-VFR-09 (Loose+FP weighted formula) chưa fix data team | Medium | Medium | Out-of-scope feature này; storytelling v2 render whatever SQL returns; separate ticket data team | Accepted (out of scope) |
| RISK-VFR-05: Target 85% sau rollout có thể tight/loose vs Mondelez ops reality | Low | Low | Constant pattern → 1-line code change để điều chỉnh; v1.1 follow-up sau khi thu thập feedback | Accepted |

---

## Asks (cần stakeholder follow up)

- **Data team**: rewrite SQL `kpi`/`kpiOperation` theo TOBE V3 Bước 4-5 Loose+FP weighted (BUG-VFR-09) — separate ticket, không gate v1.1 ship.
- **Rollout team**: prepare banner "VFR widget refresh — 5 bucket cũ giờ dùng RAG color" cho first 7 days post-ship — coordinate khi Phase 7 chuẩn bị ship.
- **Tenant admin (Mondelez)**: paste canonical SQL `byVendor` + `byVendorOperation` từ `vfr-spec.md §22` qua Settings dialog khi Phase 3 ship — Phase 3 prerequisite.

---

## ARTIFACT_PATH

- [`projects/pm/sign-offs/2026-05-20-vfr-storytelling-v1.1.md`](.) (this file)
- [`docs/feature/vfr-storytelling-refresh/dev/plan.md`](../../../docs/feature/vfr-storytelling-refresh/dev/plan.md) — status `[A]` immutable
- [`docs/feature/vfr-storytelling-refresh/dev/tasks.md`](../../../docs/feature/vfr-storytelling-refresh/dev/tasks.md) — Phase 0 complete
- [`docs/feature/vfr-storytelling-refresh/dev/context.json`](../../../docs/feature/vfr-storytelling-refresh/dev/context.json) — 4 ADR approved=true

## NEXT_ACTION

- **Owner**: thuy le (PM/DA, self-driven FE implementation)
- **Action**: Start Phase 1 — invoke `/frontend` skill với task T1.1 RAG band utility (`utils/compute-vfr-bands.ts`)
- **ETA**: T1.1 + T1.2 + T1.3 ~ 1-1.5 ngày từ 2026-05-21

## BLOCKERS

- Không còn blocker nào cho Phase 1.
- Pre-Phase-3 prerequisite (chưa block hôm nay): viết canonical SQL `byVendor` + `byVendorOperation` vào `vfr-spec.md §22` — sẽ làm trong T3.1.1 trước khi paste qua Settings dialog.
