# UAT Plan — Flash Daily (Mondelez)

> Mode A output. PRD ref: [`../flash-daily-prd.md`](../flash-daily-prd.md) v1.1.0 (Storytelling refresh scope locked 2026-05-16). Spec ref: [`../flash-daily-spec.md`](../flash-daily-spec.md). Wireframe: [`../flash-daily-wireframe.md`](../flash-daily-wireframe.md). Decisions of truth: [`../analysis/flash-daily-oq-resolution.md`](../analysis/flash-daily-oq-resolution.md) §0-LOCKED.

---

## 0. Metadata

| Field | Value |
|---|---|
| Section / View | Flash Daily (`WidgetFlashDaily` trên Smartlog Control Tower) |
| Tenant | Mondelez |
| Version Smartlog CT | v1.1.0 — branch `feat-flash-daily-refresh` (storytelling 6 levels L1-L6) |
| PRD ref | [`projects/mondelez/01-sections/flash-daily/flash-daily-prd.md`](../flash-daily-prd.md) v1.1.0 |
| Spec ref | [`projects/mondelez/01-sections/flash-daily/flash-daily-spec.md`](../flash-daily-spec.md) |
| Wireframe | [`projects/mondelez/01-sections/flash-daily/flash-daily-wireframe.md`](../flash-daily-wireframe.md) |
| Plan author | PM/BA — thuy le |
| Plan date | 2026-05-26 |
| UAT scheduled window | 2026-06-08 → 2026-06-19 |
| UAT session(s) planned | 1 session chính (~2.5h) + 1-2 retest round |
| Mode A artifacts | (1) Plan (file này) · (2) [Test cases](flash-daily-uat-cases.md) · (3) [Reconciliation template](flash-daily-uat-reconciliation-template.md) · (4) [Ops Insight Pack](flash-daily-uat-ops-insight-2026-06-08_to_2026-06-08.md) (file riêng, KHÔNG nhồi Excel) · (5) **Excel pack với số SQL thật** — proxy window 2026-05-22 đã build (`flash-daily-uat-numbers-2026-05-22_to_2026-05-22.xlsx`); khi sát ngày UAT thực, re-run script với window 2026-06-08 · (6) **Python re-runable script** (`projects/mondelez/scripts/uat_flash_daily_export.py`) — dynamic-load canonical SQL từ `sql-registry.md`, chạy `PYTHONIOENCODING=utf-8 python <script>` để rebuild Excel |

---

## 1. Mục tiêu UAT

Xác nhận view Flash Daily cho Mondelez:

1. **Số liệu khớp golden file** — Ops Manager + WH Manager MDLZ export từ pipeline báo cáo nội bộ (SAP plan + WMS shipped + STM giao) trong tolerance đã chốt.
2. **Định nghĩa 5 trạng thái E2E** (Chưa xuất / Đang xuất / Đã xuất / Đang vận chuyển / Đã vận chuyển) + bucket Dropped (Tổng kế hoạch / Success / Failed / In-progress) đúng mental model Ops Manager Mondelez. Đặc biệt chốt: STM lag không inflate count (Audit A3, PRD §3.1 v1.1.0).
3. **Target 95% % Hoàn thành** + RAG band (Green ≥95 / Yellow 85–<95 / Red <85) + Alert banner <80% áp dụng nhất quán L1 Hero, L2 Exception, L5 Dimension panels (per memory [[project_mondelez_flash_daily_target]]).
4. **Storytelling 6 levels L1 → L6** (PRD §5.4) hỗ trợ Ops Manager trả lời 5 câu mental model trong ≤30 giây: (Q1) Hôm nay đang đi tới đâu? (Q2) Có rủi ro gì không? (Q3) Đơn đang kẹt ở đâu trong luồng E2E? (Q4) Xu hướng rớt 14 ngày? (Q5) Chiều nào đang kéo % xuống?
5. **L4 Drop Trend chart MỚI** — `chartDropTrend`: FAIL = `status='Cancel'` only (H1), 14 ngày fixed, target ≤5% solid red + rolling 30d avg dashed, date type guard disable ETD/ETA gửi thầu (H2). Filter parity với L1-L3 (G5).
6. **NPP = Customer** — KHÔNG có dropdown `customerDimensionFilter`, sub-row sort worst-first cho L5 Customer panel (memory [[project_mondelez_npp_eq_customer]]).
7. **5 UOM** (cse default / ton / cbm / pallet / do) — đổi UOM cập nhật toàn widget (KPI L3 funnel, L5 panels, T1-T9 detail tables).

---

## 2. Phạm vi UAT

### 2.1. Trong scope

- **Component**: `WidgetFlashDaily` v1.1.0 storytelling layout 6 levels:
  - **L1 Hero** — % Hoàn thành hôm nay full-width + target 95% + RAG color + sub-numbers Plan/Đã giao/Còn lại (KHÔNG delta, KHÔNG as-of timestamp).
  - **L2 Exception Spotlight** — 3 ô: Top N kho off-target (<85%) / Đơn rớt chưa xử lý / Khu vực dưới target.
  - **L3 Funnel** — strip 5 status compact 1 dòng (Chưa xuất → Đang xuất → Đã xuất → Đang vận → Đã vận), thay thế 6 KPI cards baseline.
  - **L4 Drop Trend 14 ngày** — line chart MỚI `chartDropTrend`, filter-independent (override G5 per memory [[project_mondelez_flash_daily_l4_filter_independent]]).
  - **L5 Dimension panels** — 4 horizontal bar panels (Kho / Khu vực / Khách hàng = NPP / Kênh bán), sort worst-first, target line 95%, click row → L2 highlight.
  - **L6 Detail tables** — 9 WidgetGrid `DSHFLADTG01..09` (T1 Completion bỏ synthetic fallback per drift #7; T2-T6 summary tables giữ nguyên D2 defer; T7 Drop / T8 Drop Reason / T9 Flash Detail 32 cột).
- **Filter combination** (8 filter — autoApply, persist localStorage):
  - Default: Kho=ALL, Sales Channel=ALL, Cargo Group=ALL, Brand=ALL, Region=ALL, UOM=cse, Date Type=GI date, Date Range=tháng hiện tại tới hôm nay (`thisMonthToTodayRange`).
  - 1 combo single-dim: Kho=BKD1 only (test drill kho lớn).
  - 1 combo cross-dim: Kho=BKD1+BKD2 + Region=South East + Cargo Group=DRY+FRESH.
  - 1 combo Brand dependent: Cargo Group=DRY → Brand dropdown chỉ hiện brands DRY (AC-11).
  - 1 combo UOM switch: cse → ton → cbm → pallet → do.
  - 1 combo Date Type switch: GI date → Actual Ship date → ETD gửi thầu → ATA đơn → ETA gửi thầu (L4 disable ETD/ETA per H2).
- **Time window**: hôm nay (T0), tuần này (T-6 → T0), tháng này (default), 14 ngày fixed cho L4.
- **Tenant DB**: Mondelez ClickHouse cluster, schema `analytics_workspace`, source MV `mv_flash_and_drop_report` (L1-L3, L5) + `mv_dropped_report` (L4, T7, T8) + `mv_flash_report` (T1-T6, T9 backup). Filter MV `mv_filter_*` cho dropdown options.
- **Browser**: Chrome ≥ 124 hoặc Edge ≥ 124 trên viewport 1366×768 (1-fold check Tier 1) + 1920×1080.
- **15 SQL section keys** + 3 legacy fallback (`cards` / `charts` / `table`) — verify hasSqlConfig=true trên UAT env, KHÔNG render synthetic placeholder.

### 2.2. Out of scope

- Module Monitors (alert/notification dưới ngưỡng) — không thuộc Flash Daily section.
- Dashboard builder layout — không UAT.
- **Delta vs hôm qua / Same-time-yesterday** — F2 reframe, KHÔNG làm v1.1.0.
- **Snapshot infrastructure per timepoint** — F2 reframe, KHÔNG làm.
- **As-of timestamp UI** — G7 chốt KHÔNG cần.
- **Per-channel RAG bands** (KA=95% / MT=90-93%) — F1, chuyển v1.2.0 nếu UAT có feedback "MT bị đỏ oan".
- **Target override per cargo/warehouse** — B2+B3, dùng 95% chung.
- **Customer search box + N selector** — OQ-06, chuyển v1.2.0.
- **Customer dropdown NPP vs Customer toggle** — OQ-07 dropped (NPP=Customer per Mondelez).
- **Consolidate 17 → 5 query** — OQ-09 chuyển v1.3.0 (performance phase).
- **Cut T2-T6 tables** — D2 defer hoàn toàn, giữ nguyên 9 bảng cho v1.1.0.
- **File refactor `widget-flash-daily.tsx` 2,893 dòng** — drift #2 chuyển v1.2.0.
- Performance load test cường độ cao (>20 user đồng thời) — chỉ smoke single user.
- Multi-tenant switch — chỉ UAT trên tenant Mondelez.
- FormConfig `DSHFLADTG01..09.json` validation chi tiết — verify smoke `GET /api/forms/{code}` × 9 ở rollout, KHÔNG block UAT (Audit A2: file-based, không DB-seeded).

---

## 3. Phân lớp test — 4 lớp

| Lớp | Mục đích | Số TC dự kiến |
|---|---|---|
| **A. Data Reconciliation** | Số dashboard khớp golden file + SQL raw (% Hoàn thành, 5 status volume, 4 dim panel, drop bucket, 32-col flash detail) | 10 |
| **B. Business Logic** | Định nghĩa 5 trạng thái E2E (đặc biệt mutually exclusive `e2e_label`), STM lag không double-count, drop bucket pattern match, RAG band 95/85/80, FAIL='Cancel' only, target line 95 + 5% drop | 6 |
| **C. UX & Storytelling** | Mental model Q1-Q5 trong ≤30s, L2 Exception chỉ "kéo % xuống", L4 reference lines, action title insight, L5 click → L2 highlight, UOM switch consistency | 5 |
| **D. Performance / Filter** | Filter combo 5-dim < 3s, 17 useQuery song song < 5s page load, brand dependent filter, date type guard L4, localStorage persist | 4 |
| **Tổng** | | **20 happy + 5 edge = 25 TC** |

---

## 4. Test environment

| Item | Value |
|---|---|
| Environment | UAT — Mondelez tenant |
| URL | `<https://uat.smartlog.app/dashboard/...>` (PM/dev xác nhận trước session) |
| Tenant DB | ClickHouse cluster Mondelez, schema `analytics_workspace` |
| Source MV chính | `mv_flash_and_drop_report` (E2E + L1-L3 + L5 dim) + `mv_dropped_report` (L4 + T7 + T8) + `mv_flash_report` (T1-T6 summary backup, T9 raw 32-col detail) |
| Filter MV | `mv_filter_warehouse`, `mv_filter_region`, `mv_filter_channel`, `mv_filter_cargo_brand`, `mv_filter_date_type_*` (per memory [[feedback_check_registry_before_handrolling_sql]]) |
| Test user account | UAT key user MDLZ (Ops Manager role) + 1 backup (WH Manager BKD) |
| Data freshness | MV refresh hourly; xác nhận lần refresh gần nhất < 2h trước session |
| Browser yêu cầu | Chrome ≥ 124, Edge ≥ 124 |
| Viewport check | 1366×768 (Tier 1 fit 1-fold) + 1920×1080 |
| 15 SQL section keys | All non-empty (`cardKpiStatus`, `chartE2e`, `chartDropTrend`, `chartWarehouse`, `chartDeliveryArea`, `chartCustomer`, `chartSalesChannel`, `tblCompletion`, `tblE2eDetail`, `tblSummaryWh`, `tblSummaryCustomer`, `tblSummaryArea`, `tblSummaryChannel`, `tblDropped`, `tblDroppedReason`, `tableDetail`) |
| Synthetic fallback T1 | **MUST removed** trên UAT env (drift #7 fix) — verify `tblCompletion` non-empty, không render 54 synthetic rows. |

---

## 5. Stakeholder & roles

| Role | Name | Trách nhiệm |
|---|---|---|
| Customer Ops Manager (MDLZ) | `<điền trước session>` | Final signoff Mode E, validate mental model + RAG band 95/85/80 |
| Customer WH Manager (BKD reference) | `<điền>` | Verify giao diện L5 panel Kho, click → L2 highlight đúng kho mình |
| Customer Logistics Analyst | `<điền>` | Thao tác chính, xác nhận golden file 3 nguồn (SAP plan / WMS / STM) |
| Customer IT representative | `<điền>` | Hỗ trợ confirm MV refresh, STM signal lag, technical clarification |
| Smartlog PM | thuy le | Drive session, quyết định defer/escalate |
| Smartlog BA | thuy le | Clarify business rule, write defect log realtime |
| Smartlog dev FE on-call | `<điền>` | Standby cho Critical defect cần hotfix (storytelling layout / L4 chart / L5 panel) |
| Smartlog dev CH on-call | `<điền>` | Standby cho Critical defect cần SQL/MV audit (chartDropTrend backfill 44d, e2e_label mutual exclusion) |

---

## 6. Schedule

| Phase | Date | Activity |
|---|---|---|
| Mode A — Design | 2026-05-26 | Plan + cases + reconciliation template (file này) |
| Pre-UAT — Golden file ask | 2026-05-27 | Gửi spec golden file cho customer Logistics Analyst (3 nguồn — SAP plan + WMS shipped + STM giao) |
| Pre-UAT — Golden file received | target 2026-06-02 | Khách export + gửi 3 file (1 file/nguồn) |
| Mode B — Dry-run | 2026-06-05 | Run reconciliation matrix 3 nguồn, fix lệch trước session |
| Mode C — Session 1 | 2026-06-09 (sáng) | Execute với khách (~2.5h) |
| Mode D — Retest round 1 | 2026-06-15 | Sau dev fix, retest affected + regression panel |
| Mode D — Retest round 2 (nếu cần) | 2026-06-17 | Cho defect còn lại |
| Mode E — Signoff | 2026-06-19 | Sign biên bản nghiệm thu |

---

## 7. Tolerance threshold (chốt — KHÔNG đổi sau khi thấy số lệch)

| Loại metric | Tolerance | Áp dụng cho |
|---|---|---|
| Số đếm tuyệt đối | ≤ 1% | Tổng Plan / Đã giao / Còn lại (L1 Hero), volume 5 status (L3 funnel), volume per dim (L5 panels), drop bucket count (T7), reason count (T8) |
| % metric | ≤ 0.5 pp | `% Hoàn thành` (L1 + L5 panels), `drop_rate` (L4), `pct_done` per dim |
| Ranking top N | ≥ 4/5 tên match | Top N kho off-target L2 (top 5), top 10 customer L5, top 10 area L5 |
| Tổng volume per dim | ≤ 1% | `SUM(total_volume)` L5 panels phải PARITY với `cardKpiStatus` L1 Plan denominator (per memory [[feedback_l5_sql_canonical_status_filter]] — bug 2026-05-18) |
| Trend L4 14 ngày | ≤ 0.5 pp per day | `drop_rate` từng ngày + rolling 30d avg line |
| UOM consistency | 100% — đổi UOM → tất cả L1/L3/L5/T1-T9 đồng bộ refetch | KHÔNG có cell nào còn UOM cũ |

Override: customer chưa yêu cầu khắt khe hơn tại thời điểm Mode A. Nếu Logistics Analyst MDLZ yêu cầu siết % metric xuống ≤ 0.2pp → cần PM approve trước Mode B, KHÔNG đổi giữa session.

---

## 8. Pass criteria

| Tiêu chí | Threshold | Notes |
|---|---|---|
| Pass rate happy path | ≥ 95% (19/20) | |
| Pass rate edge case | ≥ 80% (4/5) | |
| Defect Critical open | 0 | Block tuyệt đối signoff |
| Defect Major open | ≤ 2 + mitigation plan | Customer Ops Manager phải accept mitigation |
| Reconciliation matrix | 100% PASS/ACCEPTED/DEFERRED, 0 FAIL | Per Mode B rule |
| Performance: filter response | < 3s | Đo trên combo 5-filter cross-dim |
| Performance: page load (17 useQuery song song) | < 5s | Lần đầu vào view Flash Daily (cold cache) |
| 1-fold check 1366×768 | L1 Hero + L2 Exception fit 1 fold không scroll | Tier 1 storytelling |
| Mental model Q1+Q2 thời gian trả lời | ≤ 10 giây (subjective, customer xác nhận) | L1 + L2 — "Hôm nay đang đi tới đâu" + "Có rủi ro gì không" |
| L4 Drop Trend filter-independent | Đổi filter L1-L3 → L4 không refetch | Per memory [[project_mondelez_flash_daily_l4_filter_independent]] |
| L5 panel SUM(total_volume) parity L1 Plan denominator | Equal (in tolerance ≤1%) | Bug 2026-05-18 đã fix; verify lại không regress |

---

## 9. Defect routing (chốt trước — session không bàn route)

| Defect lớp | Tech_layer hypothesis | Route to |
|---|---|---|
| A — Số lệch nguồn data (MV/CTE/CASE date_type/uom branching) | etl-data / sql-query | `/da-ch` audit `mv_flash_and_drop_report` / `mv_dropped_report` → dev squad CH owner |
| A — Số lệch L5 panel vs L1 (regression bug 2026-05-18) | sql-query (canonical status filter trong L5 CTE) | `/da-ch` confirm registry `Báo cáo tổng hợp theo X` Flash Report section, dev update SQL config |
| A — Số lệch do filter mapping (vd Kho BKD1→whseid CSV expansion) | frontend-widget (WidgetFilterResolver) | `/da-triage` → `/qa-executor` → dev FE |
| A — Số lệch do timezone cutoff | cross-stack (CH session timezone + FE date string `00:00:00` / `23:59:59`) | `/da-ch` confirm timezone trước, sau đó `/da-triage` → dev FE/CH |
| A — STM lag inflate 2 status count | etl-data (`e2e_label` pre-compute lỗi) | `/da-ch` audit `e2e_label` mutually exclusive qua `thoi_gian_di IS NULL` (PRD §3.1 v1.1.0) |
| B — Định nghĩa 5 trạng thái khác MDLZ standard | cross-stack (PRD trước, code sau) | `/ba` revision §3.1 PRD → `/da-trace` xác nhận, sau đó dev |
| B — RAG band sai (Green ≥95 / Yellow 85-<95 / Red <85 / Alert <80) | frontend-config (band config) | `/da-trace` confirm PRD §5.4 + memory [[project_mondelez_flash_daily_target]], dev FE update config |
| B — FAIL classification L4 sai (Cancel + Close vs Cancel only) | sql-query (chartDropTrend CTE) | `/da-ch` confirm registry "Flash Report" + H1, dev update SQL |
| C — Storytelling Q1→Q5 user không hiểu (UX khó) | frontend-config (drift PRD §5.4) | `/da-trace` → `/ba` revision storytelling principles hoặc `/da-storytelling-data` |
| C — UX bug rõ (RAG color không visible HiDPI, L2 click → L5 không highlight) | frontend-widget | `/da-triage` → dev FE |
| C — L4 reference lines sai (target ≤5% solid vs rolling 30d dashed nhầm vai) | frontend-widget | `/da-triage` → dev FE |
| D — Perf chậm (filter combo, 17 useQuery song song page load) | backend-api / sql-query (`mv_flash_and_drop_report` perf) | `/da-ch` + dev squad CH owner |
| D — Brand filter không depend Cargo Group (AC-11) | frontend-config (filter dependency) | `/da-triage` → dev FE |
| D — L4 date type guard không disable ETD/ETA (H2) | frontend-widget | `/da-triage` → dev FE |

---

## 10. Risks & mitigation

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Golden file Mondelez chỉ có % Hoàn thành tổng, không có breakdown per status / per dim | High | Med | Lớp B no-target validation = compare SQL raw cho breakdown; accept với điều kiện golden cung cấp tổng Plan + Đã giao khớp ±1% |
| STM lag → 2 status "Đã xuất kho" + "Đang vận chuyển" có operational confusion (đơn xe đã rời >12h vẫn ở "Đã xuất kho") | High | Low | Caveat tooltip "Chưa nhận tín hiệu ATD từ STM" đã add (PRD §3.1 v1.1.0). Mode B verify tooltip xuất hiện. Customer education trong session. |
| Customer chưa confirm target 95% — F1 có thể yêu cầu per-channel | Med | Med (RAG color có thể sai) | Lớp C question session cuối "OK với 95% chung không?"; nếu KHÔNG → log defect Major + chuyển v1.2.0 per-channel, không block signoff |
| MV `mv_flash_and_drop_report` + `mv_dropped_report` refresh không đồng bộ (`mv_dropped_report` chỉ expose 3/5 date_type — per H2) | Med | High | Dev CH on-call confirm refresh đồng bộ trước 1h; UI disable ETD/ETA trên L4 (H2 chốt); fallback NULL nếu user vẫn chọn ETD/ETA |
| Customer bận, session 2.5h cắt còn 1.5h | High | Med | Defer rule rõ; ưu tiên lớp A (TC-001 → TC-010) trước, lớp C UX cuối cùng |
| L4 Drop Trend chart MỚI — Backend SQL chưa stable (CTE backfill 44d perf risk) | Med | High | Dev CH on-call hotfix; Mode B dry-run check L4 trước Mode C ≥ 2 ngày |
| Bug 2026-05-18 L5 SUM(total_volume) parity L1 regression (canonical status filter) | Med | High | Mode B dry-run BẮT BUỘC compare L5 sum 4 panels vs L1 Plan denominator. Nếu lệch → block session, force dev fix trước. |
| Customer yêu cầu test thêm filter combo Brand×Cargo×Region không trong scope | High | Low | Note in execution log, schedule round 2 retest hoặc round signoff |
| Synthetic fallback T1 vẫn render trên UAT env (drift #7 chưa fix) | Low | High | Pre-UAT confirm `tblCompletion` non-empty (verify 54 synthetic rows KHÔNG xuất hiện). Block UAT nếu còn. |
| `customerDimensionFilter` dropdown vẫn xuất hiện (OQ-07 chưa remove) | Low | Med | Pre-UAT verify dropdown đã ẩn (per memory [[project_mondelez_npp_eq_customer]]) |
| Mock data fallback bật do widget chưa cấu hình SQL UAT | Low | High | Pre-UAT confirm `hasSqlConfig = true`, 15 section SQL non-empty |

---

## 11. Communication plan

- **Trong session**: PM/BA drive, BA log defect realtime vào `defects/UAT-{NNN}-{slug}.md`, dev FE + dev CH on-call qua Slack channel `#smartlog-mdlz-uat`.
- **Sau session ≤ 4h**: gửi `flash-daily-uat-execution-2026-06-09.md` + defect list cho customer Ops Manager + IT rep.
- **Trước retest**: confirm với khách "defect X đã fix, schedule retest 2026-06-15 9:00".
- **Signoff**: gặp mặt + sign tay biên bản nghiệm thu; nếu remote → DocuSign + voice confirm.
- **Escalation path**: PM → Smartlog Delivery Lead nếu pass rate < 80% sau round retest 2 (gọi `/da-pm` reassess timeline).

---

## 12. Approval

| Role | Name | Signed | Date |
|---|---|---|---|
| Smartlog PM | thuy le | | 2026-05-26 |
| Smartlog BA | thuy le | | 2026-05-26 |
| Customer Ops Manager (approval to start UAT) | `<điền>` | | |
