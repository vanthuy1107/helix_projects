# UAT Plan — OTIF (Mondelez)

> Mode A output. PRD ref: [`../prd.md`](../prd.md) v1.2.6 (PM Approved 2026-05-15). Spec ref: [`../spec.md`](../spec.md).

---

## 0. Metadata

| Field | Value |
|---|---|
| Section / View | OTIF (`WidgetOtif` trên Smartlog Control Tower) |
| Tenant | Mondelez |
| Version Smartlog CT | v1.5.x (branch `feat-otif-storytelling-refresh` — Phase 1+3+4 đã ship) |
| PRD ref | [`projects/mondelez/01-sections/otif/prd.md`](../prd.md) v1.2.6 |
| Spec ref | [`projects/mondelez/01-sections/otif/spec.md`](../spec.md) |
| Wireframe | [`projects/mondelez/01-sections/otif/wireframe.md`](../wireframe.md) |
| Plan author | PM/BA — thuy le |
| Plan date | 2026-05-26 |
| UAT scheduled window | 2026-06-01 → 2026-06-12 |
| UAT session(s) planned | 1 session chính + 1-2 retest round, mỗi session ~2.5 giờ |

---

## 1. Mục tiêu UAT

Xác nhận view OTIF cho Mondelez:
1. Số liệu khớp golden file của khách (Ops Manager + Logistics Analyst export từ pipeline báo cáo nội bộ MDLZ) trong tolerance đã chốt.
2. Định nghĩa nghiệp vụ Ontime / Infull / OTIF, classifier `classifyReason()` + `classifyInfullBucket()` đúng với mental model Ops Manager Mondelez.
3. Storytelling Tier 1 → Tier 2 → Tier 3 + detail panel hỗ trợ trả lời mental model Q1→Q5 (§13.9 PRD) trong ≤ 30 giây cho Q1+Q2 không cần scroll.
4. Target % OTIF 90% + RAG bands (Green ≥90 / Yellow 85–<90 / Red <85) áp dụng nhất quán xuyên KPI cards, Health Matrix, chart titles, exception spotlight.
5. PM tentative target Ontime 95% / Infull 97% được customer validate hoặc override config.

---

## 2. Phạm vi UAT

### 2.1. Trong scope

- **Component**: `WidgetOtif` (KPI + 8 charts + `OtifDetailPanel` 3 tab) sau Phase 1+3+4 — bao gồm 4 KPI cockpit, Health Matrix (5 dim), Mini trend sparkline, Trend full + target band, 2 Fail Reason chart, 5 Tier 3 drill-down (NVC / Kho / Loại hàng / Kênh / Khu vực) expanded mặc định, Exception Spotlight, Detail panel (Operation Summary / Fail Report / Detail Table).
- **Storytelling**: Tier 1 (KPI + Health Matrix + sparkline) → Tier 2 (Fail Reason + Trend) → Tier 3 (5 drill-down) → Detail panel — bám PRD §13.4 và mental model §13.9.
- **Filter combination**:
  - Default: Loại ngày = ETA gửi thầu, Khoảng ngày = hôm nay, các filter còn lại = ALL.
  - 1 combo single-dim: NVC = TLL only (test drill).
  - 1 combo cross-dim: Kho = BKD + Khu vực = South East + Loại hàng = DRY.
  - 1 combo time window dài: Khoảng ngày = 30 ngày gần nhất.
  - 1 combo ATA: Loại ngày = ATA chi tiết chuyến.
- **Time window**: 1 ngày (today), 7 ngày, 30 ngày.
- **Tenant DB**: Mondelez ClickHouse cluster (`analytics_workspace.mv_otif`).
- **Browser**: Chrome ≥ 124 hoặc Edge ≥ 124 trên viewport 1366×768 (AC-14 fold check) + 1920×1080.

### 2.2. Out of scope

- Module Monitors (alert/notification) — không thuộc OTIF section.
- Dashboard builder layout — không UAT.
- Performance load test cường độ cao (>20 user đồng thời) — chỉ smoke test single user.
- Multi-tenant switch — chỉ UAT trên tenant Mondelez.
- OQ-05 mở rộng 7 date_type → chỉ UAT 2 value FE hiện có (`ETA gửi thầu`, `ATA chi tiết chuyến`); FU-1 backlog riêng.
- KPI card "Tổng đơn" delta vs prior period (OQ-11 PM tentative) — UAT light, không block signoff nếu customer phản hồi khác.

---

## 3. Phân lớp test — 4 lớp

| Lớp | Mục đích | Số TC dự kiến |
|---|---|---|
| **A. Data Reconciliation** | Số dashboard có khớp golden file + SQL raw không (số tuyệt đối + % metric + ranking + funnel bucket) | 9 |
| **B. Business Logic** | Định nghĩa Ontime/Infull/OTIF, classifier fail reason, RAG bands per metric, target band trend, timezone cutoff | 6 |
| **C. UX & Storytelling** | Khách đọc story Q1→Q5 trong ≤ 30s, Exception Spotlight chỉ đúng "chiều kéo OTIF xuống", action title insight | 4 |
| **D. Performance / Filter** | Filter combo 5-dim < 3s, page load < 5s, drill-down Order Monitor < 2s | 3 |
| **Tổng** | | 18 happy + 4 edge = **22 TC** |

---

## 4. Test environment

| Item | Value |
|---|---|
| Environment | UAT — Mondelez tenant |
| URL | `<https://uat.smartlog.app/dashboard/...>` (PM/dev xác nhận trước session) |
| Tenant DB | ClickHouse cluster Mondelez, schema `analytics_workspace`, source MV `mv_otif` |
| Test user account | UAT key user MDLZ (Ops Manager role) + 1 backup account |
| Data freshness | MV `mv_otif` refresh hourly; xác nhận lần refresh gần nhất < 2h trước session |
| Browser yêu cầu | Chrome ≥ 124, Edge ≥ 124 |
| Viewport check | 1366×768 (AC-14 fold) + 1920×1080 |

---

## 5. Stakeholder & roles

| Role | Name | Trách nhiệm |
|---|---|---|
| Customer Ops Manager (MDLZ) | `<điền trước session>` | Final signoff Mode E, validate mental model |
| Customer Logistics Analyst | `<điền>` | Thao tác chính, xác nhận golden file |
| Customer IT representative | `<điền>` | Hỗ trợ confirm MV refresh, technical clarification |
| Smartlog PM | thuy le | Drive session, quyết định defer/escalate |
| Smartlog BA | thuy le | Clarify business rule, write defect log realtime |
| Smartlog dev FE on-call | `<điền>` | Standby cho Critical defect cần hotfix (storytelling/component bug) |
| Smartlog dev CH on-call | `<điền>` | Standby cho Critical defect cần SQL/MV audit |

---

## 6. Schedule

| Phase | Date | Activity |
|---|---|---|
| Mode A — Design | 2026-05-26 | Plan + cases + reconciliation template (file này) |
| Pre-UAT — Golden file ask | 2026-05-26 | Gửi spec golden file cho customer Logistics Analyst |
| Pre-UAT — Golden file received | target 2026-05-29 | Khách export + gửi file |
| Mode B — Dry-run | 2026-06-01 | Run reconciliation matrix 3 nguồn, fix lệch trước session |
| Mode C — Session 1 | 2026-06-03 (sáng) | Execute với khách (≤ 2.5h) |
| Mode D — Retest round 1 | 2026-06-08 | Sau dev fix, retest affected + regression panel |
| Mode D — Retest round 2 (nếu cần) | 2026-06-10 | Cho defect còn lại |
| Mode E — Signoff | 2026-06-12 | Sign biên bản nghiệm thu |

---

## 7. Tolerance threshold (chốt — KHÔNG đổi sau khi thấy số lệch)

| Loại metric | Tolerance | Áp dụng cho |
|---|---|---|
| Số đếm tuyệt đối | ≤ 1% | `total_so`, `ontime_so`, `infull_so`, `otif_so`, `fail_so` các bucket |
| % metric | ≤ 0.5 pp | `pct_ontime`, `pct_infull`, `pct_otif` ở cả KPI cards, Health Matrix cell, chart |
| Ranking top N | ≥ 4/5 tên match (top 5) hoặc ≥ 3/3 (Tier 3 dim ≤ 3 giá trị) | Top NVC / Kho / Loại hàng kéo OTIF xuống |
| Tổng đơn theo dimension | ≤ 1% | Tổng `total_so` theo NVC / Kho / Khu vực / Kênh / Loại hàng |

Override: customer chưa yêu cầu khắt khe hơn tại thời điểm Mode A. Nếu customer Logistics Analyst yêu cầu siết % metric xuống ≤ 0.2pp → cần PM approve trước Mode B, KHÔNG đổi giữa session.

---

## 8. Pass criteria

| Tiêu chí | Threshold | Notes |
|---|---|---|
| Pass rate happy path | ≥ 95% (17/18) | |
| Pass rate edge case | ≥ 75% (3/4) | |
| Defect Critical open | 0 | Block tuyệt đối signoff |
| Defect Major open | ≤ 2 + mitigation plan | Customer Ops Manager phải accept mitigation |
| Reconciliation matrix | 100% PASS/ACCEPTED/DEFERRED, 0 FAIL | Per Mode B rule |
| Performance: filter response | < 3s | Đo trên 1 combo 5-filter |
| Performance: page load | < 5s | Lần đầu vào view OTIF (cold cache) |
| AC-14 1-fold check | Tier 1 fit 1366×768 không scroll | Hiển thị KPI + Health Matrix + sparkline |
| Mental model Q1+Q2 thời gian trả lời | ≤ 10 giây (subjective, customer xác nhận) | Tier 1 storytelling |

---

## 9. Defect routing (chốt trước — session không bàn route)

| Defect lớp | Tech_layer hypothesis | Route to |
|---|---|---|
| A — Số lệch nguồn data (MV/CTE/CASE date_type) | etl-data / sql-query | `/da-ch` audit `mv_otif` / 12 SQL → dev squad CH owner |
| A — Số lệch do filter mapping (vd Kho BKD→whseid) | frontend-widget | `/da-triage` → `/qa-executor` → dev FE |
| A — Số lệch do timezone cutoff | cross-stack (CH session timezone + FE date string) | `/da-ch` confirm timezone trước, sau đó `/da-triage` → dev FE/CH |
| B — Định nghĩa Ontime/Infull/OTIF khác MDLZ standard | cross-stack (PRD trước, code sau) | `/ba` revision §3 PRD → `/da-trace` xác nhận, sau đó dev |
| B — RAG band per-metric sai (OTIF 90 / Ontime 95 / Infull 97) | frontend-config (band config) | `/da-trace` confirm PRD §13.2, dev FE update config |
| C — Storytelling Q1→Q5 user không hiểu (UX khó) | frontend-config (drift PRD §13.9) | `/da-trace` → `/ba` revision §13.9 hoặc `/da-storytelling-data` |
| C — UX bug rõ (chữ tràn KPI card, RAG color không visible HiDPI) | frontend-widget | `/da-triage` → dev FE |
| D — Perf chậm (filter combo, page load) | backend-api / sql-query (`mv_otif` perf) | `/da-ch` + dev squad CH owner |

---

## 10. Risks & mitigation

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Golden file Mondelez chỉ có % OTIF, không có breakdown % Ontime / % Infull riêng | High | Med | Lớp B no-target validation cho Ontime/Infull = compare với SQL raw, accept với điều kiện golden cung cấp tổng OTIF khớp |
| Customer chưa confirm OQ-07 (target Ontime 95 / Infull 97) trước session | Med | Med (RAG color có thể sai) | Lớp C question session cuối "OK với 95/97 không?"; nếu KHÔNG → defer RAG band 2 metric đó, không block signoff |
| MV `mv_otif` refresh không kịp (cutoff vẫn ở dữ liệu hôm trước) | Med | High | Dev CH on-call confirm refresh trước 1h, có fallback re-run refresh nếu trễ |
| Customer bận, session 2.5h cắt còn 1.5h | High | Med | Defer rule rõ; ưu tiên lớp A (TC-001 → TC-009) trước, lớp C UX cuối cùng |
| Phase 3 cockpit code mới merge, có thể có regression với Phase 1 (KPI cards) | Med | High | Dev FE on-call hotfix; Mode B dry-run check Tier 1 + Tier 2 + Tier 3 trước Mode C |
| Customer yêu cầu test thêm filter combo không trong scope | High | Low | Note in execution log, schedule round 2 retest hoặc round signoff |
| Mock data fallback bật do widget chưa cấu hình SQL UAT | Low | High | Pre-UAT confirm `hasSqlConfig = true` trên môi trường UAT |

---

## 11. Communication plan

- **Trong session**: PM/BA drive, BA log defect realtime vào `defects/UAT-{NNN}-{slug}.md`, dev FE + dev CH on-call qua Slack channel `#smartlog-mdlz-uat`.
- **Sau session ≤ 4h**: gửi `otif-uat-execution-2026-06-03.md` + defect list cho customer Ops Manager + IT rep.
- **Trước retest**: confirm với khách "defect X đã fix, schedule retest 2026-06-08 9:00".
- **Signoff**: gặp mặt + sign tay biên bản nghiệm thu; nếu remote → DocuSign + voice confirm.
- **Escalation path**: PM → Smartlog Delivery Lead nếu pass rate < 80% sau round retest 2 (gọi `/da-pm` reassess timeline).

---

## 12. Approval

| Role | Name | Signed | Date |
|---|---|---|---|
| Smartlog PM | thuy le | | 2026-05-26 |
| Smartlog BA | thuy le | | 2026-05-26 |
| Customer Ops Manager (approval to start UAT) | `<điền>` | | |
