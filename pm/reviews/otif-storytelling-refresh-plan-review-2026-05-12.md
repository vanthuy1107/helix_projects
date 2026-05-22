# PM Review — OTIF Storytelling Refresh Plan v1.0

| Trường | Giá trị |
|---|---|
| **Date** | 2026-05-12 |
| **Reviewer** | thuy le — PM/DA (squad1@gosmartlog.com) |
| **Artifact reviewed** | [`docs/feature/otif-storytelling-refresh/dev/plan.md`](../../../docs/feature/otif-storytelling-refresh/dev/plan.md) |
| **PRD reference** | `projects/mondelez/01-sections/otif/prd.md` v1.2.5 (PM Approved 2026-05-12) |
| **Total effort** | 5.5–9 ngày dev + 1.5 ngày review/test/ship + 1–2 tuần Phase 2 async customer validation |
| **Verdict** | **APPROVED with 4 conditions** (xem §4) — không có blocker, có 4 cải thiện cần PM xử trước/trong Phase 1 |

---

## 1. Scope & sprint capacity check

| Aspect | Status | PM concern |
|---|---|---|
| Effort estimate Phase 1 | 1–1.5 ngày | ✅ Fit nửa sprint |
| Effort estimate Phase 3 | 3–5 ngày spread 67% | ⚠️ Spread quá rộng cho sprint commit — request /planner break theo task group (T3.1..T3.8) |
| Effort estimate Phase 4 | 0.5–1 ngày | ✅ |
| Sprint allocation | 1 FE dev (thuy le PM-driven) | ⚠️ Capacity check: nếu 1 dev solo, 5.5–9 ngày = 1.5–2 tuần lịch (factor in review + UAT) |
| Parallel work | Phase 2 customer async + dev sequential | ✅ Decoupled |

**PM decision**: Commit **Phase 1 + Phase 3 cùng 1 sprint** (2 tuần), Phase 4 đầu sprint kế. Phase 4 nhỏ (0.5–1d) không nên ép cuối sprint dễ kéo dài.

---

## 2. 4 ADRs — PM angle review

### ADR-G1 — Calendar delta semantic ✅ APPROVE
- **Quyết định OK**: Mondelez ops báo cáo theo calendar week (Mon-Sun) + tháng dương lịch — match.
- **Lỗ hổng nhỏ**: "Cross-month range (15/05–15/06) → prior month = 15/04–15/05" — offset shift logic chưa được test với 2–3 real Mondelez weekly reports.
- **PM ask**: Trước khi merge Phase 1, attach screenshot 1 báo cáo weekly Mondelez đang dùng → xác nhận semantic match. Nếu lệch → adjust trước UAT, không phải sau ship.
- **Edge case còn thiếu**: User chọn range > 1 tháng (vd: 01/04–31/05). "Prior month" còn make sense không? Plan §8.2 đã flag nhưng chưa có behavior — recommend hide delta trong case này (fallback empty), không cố tính.

### ADR-G2 — Reuse 5 existing SQL ✅ APPROVE
- **Quyết định OK**: 5 SQL đã fetch parallel via `Promise.all`. Aggregate client-side cost = 0.
- **PM ask**: Sau Phase 3 ship, monitor **P95 latency 5 SQL aggregate** cho Mondelez dataset 1 năm (~50k đơn). Threshold trigger Option B migration: **P95 > 2s sustained 1 tuần** → mở separate ticket `feat-otif-matrix-dedicated-sql` (effort +2d BE per plan ADR-G2).
- **Risk**: Mondelez có thể có dataset > 50k đơn / range 1 năm. Chưa biết. **Action**: trước Phase 3, ping da-ch lấy số đơn 12 tháng gần nhất từ `analytics_workspace.mv_otif` để estimate.

### ADR-G3 — Top 3 worst per dim + "Xem tất cả" ✅ APPROVE (với clarification UX)
- **Quyết định OK**: Top 3 cover 80% case, Tier 1 ≤ 650px.
- **PM ask**: "Xem tất cả {dim}" UX cần specify trong tasks.md T3.3.3 — **Popover hay Dialog**? Recommend **Popover** (inline, ít disruptive hơn Dialog modal) — match Tier 3 Collapsible pattern.
- **Post-ship metric**: Track click-rate trên "Xem tất cả" qua telemetry/activity log. Nếu > 30% Ops Manager session click "Xem tất cả NVC" → Top 3 cap sai cho NVC dim → tăng lên Top 5 hoặc per-dim cap khác nhau.

### ADR-N3 — Feature flag rollback ✅ APPROVE (với governance ask)
- **Quyết định OK**: `otif.storytelling.cockpit` boolean tenant config, default false.
- **PM ask CRITICAL**: Ai có quyền **flip flag**? Plan chưa nói rõ:
  - Option A: Backend admin UI cho PM/Rollout flip (non-dev) — preferred
  - Option B: Hardcode per environment — kém linh hoạt
  - Option C: SQL update tenant config direct — risky
- **Action trước Phase 3 T3.1**: PM xác nhận với tech lead **tenant config admin UI hiện có** hay cần build mới. Nếu cần build → +1d backend hoặc defer flip-by-PM (PM phải nhờ dev mỗi lần flip).
- **Rollback drill**: Trước ship, **practice flip flag** trên dev environment 2 lần (true → false → true) để confirm zero-downtime + no cache issue.

---

## 3. Risk register additions (promote từ plan §8.2 → `projects/pm/risks.md`)

Top 3 risk cần PM track formally (theo template risk register):

### RISK-001: Customer reject Cockpit layout sau ship Phase 3
- **Likelihood**: Medium (layout shift lớn từ liệt kê → matrix)
- **Impact**: High (rollback toàn bộ Phase 3 + lost effort 4–6 ngày dev nếu không có flag)
- **Mitigation**: ADR-N3 feature flag default false. Ship Phase 1+3 với flag = false → demo cho Ops Manager Mondelez UAT trước khi flip true. Rollback = flip flag (zero code change).
- **Owner**: PM (thuy le) + Rollout team for Mondelez interface
- **Status**: Open — mitigated by design

### RISK-002: 5 SQL aggregate client-side perf regression
- **Likelihood**: Low (Promise.all đã parallel; aggregation cheap)
- **Impact**: Medium (Phase 3 ship + perf complaint từ Mondelez → Option B migration +2d BE)
- **Mitigation**: Estimate dataset size trước Phase 3 (PM ask cho da-ch). Add P95 monitoring post-ship. Threshold = 2s.
- **Owner**: PM + dev-fe (thuy le)
- **Status**: Open — accepted risk

### RISK-003: Customer Validation Phase 2 chậm > 2 tuần → blocks OQ-07 confirm
- **Likelihood**: Medium (customer Mondelez đang busy season, không cam kết SLA reply)
- **Impact**: Low–Medium (Ontime/Infull KPI render với target 95/97% PM tentative. Nếu customer say 93/96 → config update post-ship; widget show wrong RAG ~1–2 tuần)
- **Mitigation**: PM gửi email customer ngay sau plan approve (không đợi ship). Set deadline reply = 2 tuần. Nếu silence > 2 tuần → escalate Account Manager.
- **Owner**: PM (thuy le) interface với customer
- **Status**: Open — needs PM action this week

---

## 4. APPROVAL conditions

Plan **APPROVED** với 4 conditions PM phải xử trước hoặc trong Phase 1:

| # | Condition | Owner | Deadline |
|---|---|---|---|
| **C1** | ADR-G1: Attach 2–3 screenshot Mondelez weekly report → xác nhận calendar semantic. Update plan §3 ADR-G1 với evidence. | PM | Trước merge Phase 1 (≤ 2026-05-19) |
| **C2** | ADR-G2: Ping da-ch lấy dataset size estimate Mondelez 12 tháng → confirm Option A đủ perf. | PM + da-ch | Trước Phase 3 T3.2 kick-off |
| **C3** | ADR-G3 clarification: "Xem tất cả" UX = **Popover** (inline). Update tasks.md T3.3.3 spec. | PM | Trước Phase 3 T3.3 |
| **C4** | ADR-N3 governance: Confirm tenant config admin UI có/không, ai flip flag. Document trong plan §3 ADR-N3. | PM + tech lead | Trước Phase 3 T3.1 |

C1 + C4 là blocker phase-level. C2 + C3 có thể defer 2–3 ngày vào Phase 3 kick-off.

---

## 5. Communication plan (PM hành động ngay sau approve)

| Audience | Message | Channel | When |
|---|---|---|---|
| Customer Mondelez (Ops Manager + Account Manager) | "Plan refresh OTIF dashboard duyệt. 4 PM tentative items xin confirm trong 2 tuần." (link OQ-07/09/10/11 + screenshot wireframe Cockpit) | Email | 2026-05-13 |
| Tech lead | "Plan approved. Cần confirm tenant config admin UI cho flag flip. PM-driven implementation (PM tự code FE)." | Slack/Email | 2026-05-13 |
| da-ch | "Cần dataset size Mondelez 12 tháng — estimate Health Matrix perf." | Slack | 2026-05-13 |
| Rollout team | "Mondelez sẽ có feature flag mới `otif.storytelling.cockpit`. Coordinate flip post-UAT (timing TBD)." | Email | 2026-05-19 (sau Phase 1 ship) |

---

## 6. Definition of Done (cho stakeholder)

Feature **SHIPPED** khi:
- [x] Phase 1 + 3 + 4 code merged to main
- [x] Feature flag default false trên prod
- [x] UAT Ops Manager Mondelez pass (flag flip true on dev/staging environment, demo session ≥ 30 phút)
- [x] Mondelez tenant flag flip true (post UAT pass)
- [x] 4 Phase 2 customer validation OQ resolved (customer email confirm)
- [x] Telemetry baseline collected (5 SQL P95, "Xem tất cả" click rate)
- [x] PRD §13.10 changelog updated với link merged PR + ship date (T7.6)

---

## Mandatory ending signals

**ARTIFACT_PATH**: `projects/pm/reviews/otif-storytelling-refresh-plan-review-2026-05-12.md`

**NEXT_ACTION**:
- **PM (thuy le)**: gửi 4 email/Slack trong §5 vào **2026-05-13** (mai).
- **PM**: batch-approve plan.md T0.3 + T0.4 + T0.5 + T0.6 + T0.7 trong 1 session (giảm gate delay). Update plan §10 checkbox.
- **PM**: bắt đầu Phase 1 T1.1 sau khi tech lead confirm tenant config infra (C4).

**BLOCKERS**:
- **C1** (Mondelez report screenshot) — PM tự lấy, deadline 2026-05-19.
- **C4** (tenant config admin UI governance) — chờ tech lead reply, deadline 2026-05-14 để không block Phase 3 kick-off.
