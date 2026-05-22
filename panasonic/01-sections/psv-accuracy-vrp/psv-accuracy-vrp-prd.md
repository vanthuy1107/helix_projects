# PRD — psv-accuracy-vrp

> **Section:** `psv-accuracy-vrp`
> **Tenant:** Panasonic
> **Data source:** `mv_psv_main` (ClickHouse cluster `analytics_workspace`)
> **Audit source:** `psv_target FINAL` (`is_deleted=0 AND data_report=true`)
> **Author:** /da-storytelling-data → packaged for /ba → /planner
> **Date:** 2026-05-21 (revised — added 5 raw data tables in scope; 8 UX decisions resolved in wireframe §12)
> **Status:** DRAFT — pending data answers tại §8 Open Questions (Q1-Q4); UX decisions §wireframe.12 resolved
> **Related:** [spec](psv-accuracy-vrp-spec.md) · [wireframe](psv-accuracy-vrp-wireframe.md) · [storytelling notes](analysis/storytelling-notes.md)

---

## 1. Context

Panasonic Vietnam vận hành module **PSV — Phương án Sắp Vận tải** trên Panasonic TMS, sinh kết quả từ thuật toán **OPS_Optimizer (VRP — auto-routing/planning)**. Sau khi VRP đề xuất phương án, planner có thể **chỉnh sửa thủ công** (đổi xe, đổi vendor, sắp xếp lại route) trước khi gửi vendor.

Section `psv-accuracy-vrp` đo **độ tin cậy của VRP**: bao nhiêu phương án được giữ nguyên, bao nhiêu bị chỉnh, chỉnh xong còn vi phạm gì, và lệch chi phí bao nhiêu so với baseline thuật toán. Câu hỏi tối thượng:

> **"VRP có đáng tin để giữ nguyên không? Nếu phải chỉnh thì chỉnh ở đâu, vì sao, tốn thêm bao nhiêu?"**

Bộ chart mẫu đã thống nhất với khách hàng tại [PSV-auto-demo.pdf](../../05-reference/PSV-auto-demo.pdf) — section này lấy 4/5 dashboard của demo (drop Section 5 Autolog → tách riêng `psv-adoption-vrp`).

---

## 2. Audience

| Tier | Audience | Câu hỏi cốt lõi |
|---|---|---|
| Strategic | BOD + Operations Director | "VRP có ROI đủ tốt để mở rộng module/site không?" |
| Tactical | Planning Lead | "VRP làm tốt ở zone nào, kém ở zone nào? Constraint nào cần fix?" |
| Operational | Procurement Lead | "Planner đang swap vendor nào, ảnh hưởng chi phí gì?" |
| Operational | Planner (self-monitor) | "Phương án mình adjust có còn vi phạm gì không?" |

---

## 3. Business Intent / Goals

1. **Trust signal cho VRP**: định lượng "Auto kept rate" để Panasonic quyết định mở rộng auto-planning sang module/site khác.
2. **Root cause của manual adjustment**: phân tách lý do chỉnh (vendor mismatch, constraint vi phạm, vehicle shortage) để feedback cho thuật toán.
3. **Cost variance**: đo Δ chi phí Auto vs Adjusted để Finance kiểm soát overspend khi planner override.
4. **Constraint visibility**: surface các ràng buộc vận hành (Fishbone, 3D_loading, Break_time, PO_expired) còn vi phạm sau adjust → mục tiêu cải tiến.

---

## 4. User Stories

| ID | As a... | I want to... | So that... |
|---|---|---|---|
| US-A1 | BOD member | Xem 1 con số "% Accuracy" hàng tháng + trend | Quyết định có scale VRP sang site khác không |
| US-A2 | Planning Lead | Filter Accuracy theo zone | Biết zone nào VRP đang fail và cần tinh chỉnh |
| US-A3 | Planning Lead | Xem trend cost drift % theo ngày | Phát hiện spike bất thường để root-cause sớm |
| US-A4 | Planning Lead | Xem AVG Adj Duration trung bình | Hiểu workload planner đang bỏ ra để adjust |
| US-B1 | Planning Lead | Xem % chuyến còn vi phạm sau adjust | Biết chất lượng output cuối cùng đang ở đâu |
| US-B2 | Planning Lead | Pareto top constraint hay bị vi phạm | Đầu tư fix constraint nào trước (ROI) |
| US-B3 | Planning Lead | Daily violation trend | Phát hiện ngày có spike → điều tra root cause |
| US-C1 | Procurement Lead | Trip change matrix (carrier old → new) | Biết planner hay thay carrier nào bằng carrier nào |
| US-C2 | Procurement Lead | Vendor allocation Auto vs Adjusted | Đo ai bị cắt giảm, ai được tăng so với đề xuất |
| US-C3 | Finance | Cost Impact by Vendor (Δ VND + %Drift) | Quantify overspend khi planner override |
| US-D1 | Planning Lead | Summary table Auto vs Adjusted (4 metric) | Snapshot tổng cho monthly review |
| US-D2 | Finance | Total saving/loss VND by zone | Báo cáo zone nào tiết kiệm/tốn thêm nhất |
| US-D3 | Procurement Lead | Bubble chart CBM × CostPerCBM × Trip | Spot vendor/zone cần renegotiate giá |

---

## 5. Success Metrics (cho chính section này, không phải KPI của Panasonic)

| # | Metric | Target |
|---|---|---|
| SM-1 | Số report Monthly Review của Planning Lead **dùng dashboard này** thay file Excel rời | ≥ 80% sau 2 tháng go-live |
| SM-2 | Tỷ lệ planner mở dashboard ≥ 1 lần/tuần (DAU/WAU adoption) | ≥ 60% sau tháng đầu |
| SM-3 | Số lần BOD reference "% Accuracy from dashboard" trong steering committee | ≥ 1 lần/tháng |
| SM-4 | Số question từ Panasonic về "số liệu lệch" sau khi dashboard sống | ≤ 2 issue/tháng (≈ 0 silent bug) |

---

## 6. Acceptance Criteria (ship gate per chart)

Mỗi chart phải pass cả 4 điều kiện trước khi GO LIVE:

| Gate | Điều kiện |
|---|---|
| **G-Spec** | Có entry trong [spec](psv-accuracy-vrp-spec.md) §3/§4 với column mapping + SQL canonical pattern |
| **G-Audit** | Số liệu khớp audit query trên `psv_target FINAL` (sai số ≤ 1% — accept refresh lag 1h của mv_psv_main) |
| **G-Storytelling** | Action title viết theo §3 storytelling-notes (nói insight, không chỉ label KPI) |
| **G-EdgeCase** | Empty state + 0-vs-null + n-low warning xử lý đúng theo wireframe §Interactions |

Charts có GAP §8 → cannot ship gate G-Spec trước khi GAP resolve. Track riêng trong [tasks](dev/tasks.md) khi /planner tạo.

---

## 7. Scope

### 7.1 IN v1 (ship được sau khi answer §8 Open Questions)

| Chart ID | Tên | Phụ thuộc GAP | Khả năng ship v1 |
|---|---|---|---|
| A1 | % Accuracy KPI | none | 🟢 Ship full ngay |
| A2 | Accuracy Rate by Zone | Q2 (zone master) | 🟡 Ship sau khi có file zone |
| A3 | Cost per CBM Trend | Q1 (Auto baseline) | 🟡 Ship sau khi extend pipeline OR Option A version pivot |
| A4 | Process Efficiency — AVG Adj Duration only | none (fallback formula) | 🟢 Ship v1 với fallback từ `created_date` + `report_modified_date` |
| B1 | Constraint Violation Rate KPI | none | 🟢 Ship full ngay |
| B2 | Violation Rate by Zone | Q2 | 🟡 Cùng Q2 |
| B3 | Violation Count by Category | none | 🟢 Ship full ngay (`arrayJoin` constraint_name) |
| B4 | Daily Violation Trend | none | 🟢 Ship full ngay |
| C1 | Trip Change Matrix | Q1 | 🟡 Cùng Q1 |
| C2 | Vendor Allocation Ratio | Q1 | 🟡 Cùng Q1 |
| C3 | Vendor Allocation by Zone | Q1 + Q2 | 🟡 Double dep |
| C4 | Cost Impact by Vendor | Q1 | 🟡 Cùng Q1 |
| C5 | % Change Vendor by Zone | Q1 + Q2 | 🟡 Double dep |
| D1 | Summary Comparison table | Q1 | 🟡 Cùng Q1 |
| D2 | Trip Variation by Zone | Q1 + Q2 | 🟡 Double dep |
| D3 | Total Saving/Loss by Zone | Q1 + Q2 | 🟡 Double dep |
| D4 | Cost % Diff by Zone | Q1 + Q2 | 🟡 Double dep |
| D5 | Cost Efficiency Bubble (Zone + Vendor) | Q2 (zone bubble) | 🟢 Vendor bubble ship full; Zone bubble pending Q2 |
| D6 | Summary Metrics by Prov table | Q1 + Q2 | 🟡 Double dep |
| **T-CONSTRAINT** | Constraint violation trip log (Tab 2 raw) | Q2 (zone col 'Unknown' fallback) | 🟢 Ship full với zone='Unknown' nếu thiếu master |
| **T-VENDOR** | Vendor swap detail (Tab 3 raw) | Q1 + Q2 | 🟡 Double dep |
| **T-ZONE-COST** | Zone-level cost variance (Tab 4 raw) | Q1 + Q2 | 🟡 Double dep |
| **T-MASTER** | Trip master 24-col (Tab 5 raw) | Q1 (Auto cols NULL fallback) + Q2 (zone='Unknown') | 🟢 Ship với degraded cols |
| **T-PLANNER** | Per-planner activity (Tab 5 raw) | Q3 (avg_adj_duration fallback) | 🟢 Ship full với fallback formula |

**Phân loại theo readiness sau Open Questions (19 charts + 5 raw tables):**
- 🟢 **Ship-now** (8 assets): A1, A4 (partial), B1, B3, B4, T-CONSTRAINT, T-MASTER (degraded), T-PLANNER — không phụ thuộc Q1/Q2/Q3 hoặc có fallback acceptable.
- 🟡 **Q1-blocked baseline** (10 assets): A3, C1, C2, C4, D1, T-VENDOR; + 4 charts blocked cả Q1+Q2.
- 🟡 **Q2-blocked zone** (5 assets standalone): A2, B2, D5-zone, T-ZONE-COST; + 4 charts blocked cả Q1+Q2.

### 7.2 OUT v1 (deferred)

| Item | Rationale | Đẩy đi đâu |
|---|---|---|
| **Autolog** — DAU, Daily Auto Runs, Hourly Distribution, Run Success Rate | Là metric ADOPTION + run reliability, không phải VRP accuracy. Audience khác (IT Adoption + Ops Manager), narrative khác | Section riêng `psv-adoption-vrp` |
| **AVG Preparation (Min)** | PM/DA đã skip metric này khi generate fake data (xác nhận §0.5 storytelling-notes) | Drop hoàn toàn — không revive trừ khi Panasonic yêu cầu |
| **AVG Final Leadtime (Min)** | Cần event log "Send Tender" (Q3) — không có ở `mv_psv_main` | `psv-adoption-vrp` cùng Autolog |
| **Constraint master catalog** (chuẩn hoá tên violation) | Hiện dùng raw string OK v1; chuẩn hoá là enhancement | v2 — sau khi có catalog từ Panasonic |

---

## 8. Open Questions

Tất cả phải có câu trả lời trước khi /planner viết technical plan.

| ID | Question | Owner | Block | Decision tree |
|---|---|---|---|---|
| **Q1** | JSON `DataRun.DataReport` của `dbo.OPS_Optimizer` có lưu Auto-baseline values (fee/CBM/vendor/trip_count) trước khi planner adjust, hay chỉ overwrite với Adjusted final? | BA → Panasonic TMS team | 11 charts (A3, C1-C5, D1-D4, D6) | **Yes** → extend `mv_psv_trigger` materialize `*_auto` columns (Option B). **No** → fallback Option A (psv_target version pivot, MIN(version) = Auto). **Both no** → ship Option C (drop Auto-vs-Adjusted pillar, redesign Sections C+D as Adjusted-only) |
| **Q2** | File mapping `location_code → zone / zone_pair / route_type` mà PM dùng để populate cột Zone trong fake data — xin chia sẻ | BA → PM/DA | 9 charts | **Có file** → materialize `analytics_workspace.panasonic_zone_master` (dictionary hoặc bảng). **Không có** → request Panasonic Logistics team cung cấp |
| **Q3** | Table nào trong Panasonic TMS SQL Server log event `Run Auto` / `Final Save` / `Send Tender` với timestamp? Hoặc fallback: Smartlog activity log có capture được không? | BA → Panasonic TMS + Smartlog backend | A4 partial, toàn bộ `psv-adoption-vrp` | **Có TMS audit table** → extend PeerDB CDC, tạo `mv_psv_events`. **Smartlog log only** → ship adoption section qua `logging.activity`. **Không có** → drop adoption section v1, chỉ giữ A4 với fallback formula |
| **Q4** | Field `Run Status` (Success/Failure/Timeout) per Run Auto event đến từ đâu? `dbo.OPS_Optimizer.DataRun` JSON có field `Status` không, hay sister table? | BA → Panasonic TMS team | Run Success Rate (defer adoption) | **Trong JSON** → extend trigger MV extract. **Sister table** → JOIN trong refresh query. **Không có** → fallback `data_report=true` as success proxy |
| Q5 | RAG threshold chính thức của Panasonic cho `% Accuracy` và `Violation Rate`? (mặc định đề xuất: Accuracy Green ≥ 80% / Yellow 60-80% / Red < 60%; Violation Green < 10% / Yellow 10-25% / Red ≥ 25%) | BA → Planning Lead Panasonic | Color coding mọi chart | Confirm threshold hoặc nhận default |
| Q6 | Đơn vị "Total Saving/Loss" trong PDF demo (`4,428` → `-46,856`) — VND, nghìn VND, hay triệu VND? | BA → PM | D3 axis label | Confirm đơn vị + format `formatReadableQuantity` |
| Q7 | "% Accuracy" định nghĩa counter-intuitive (No Change + Change with violation) — có giữ đúng theo PDF không, hay đổi sang định nghĩa "% Kept Untouched" (chỉ No Change) cho dễ hiểu? | BA → Planning Lead Panasonic + Operations Director | A1 definition + tooltip | Confirm hold or change |
| Q8 | Có cần kèm `vendor_name` swap rule "đổi vendor do thiếu xe được count là No Change" trong A1 không? (PDF mention nhưng `status_name_detail` derive logic chưa cover) | BA → Planning Lead | A1 numerator | Confirm rule + add filter logic |

---

## 9. Non-functional Requirements

| # | Requirement |
|---|---|
| NFR-1 | Refresh cadence ≤ 1h (theo `mv_psv_main` refresh policy). Tooltip chú thích "Data refreshed every 1h" |
| NFR-2 | Filter date range default = current month (calendar). User chọn được preset 7d/30d/MTD/QTD/custom |
| NFR-3 | Filter persist khi navigate giữa các section khác (memory: localStorage section-level filter) |
| NFR-4 | Mọi chart support empty state — KHÔNG hiển thị 0% khi không có data (gây nhầm = VRP fail) |
| NFR-5 | Mọi chart support n-low warning (n < 10 trips) — grey-out hoặc tooltip "low sample" |
| NFR-6 | Mọi chart export CSV (PNG export là nice-to-have v2) |
| NFR-7 | Mobile: read-only access ở viewport ≥ 1024px; KHÔNG support < 1024px (audience là desktop) |
| NFR-8 | i18n: section + chart label hỗ trợ tiếng Việt là first-class; English fallback (Panasonic VN team chính, regional reporting English) |
| NFR-9 | Section render 5 tabs theo audience; section filter (date/planner/zone) persist khi switch tab; URL deep-link `?tab=...&zone=...` để bookmark/share (wireframe §1-§8) |
| NFR-10 | 5 raw data tables (T-CONSTRAINT, T-VENDOR, T-ZONE-COST, T-MASTER, T-PLANNER) export CSV + XLSX. T-MASTER server-side pagination cap 200k rows CSV / 50k rows XLSX (wireframe §7) |
| NFR-11 | Tab 1 Overview hiển thị exception panel auto-trigger với top 3 zone red + top 3 constraint Pareto + top 3 vendor `pct_drift > 15%`; max 9 items (wireframe §12 D6) |
| NFR-12 | Inline help (ⓘ) tooltip per chart bật default v1, content từ glossary; KHÔNG được disable cho A1, B1 (counter-intuitive KPI, Q7) (wireframe §12 D5) |

---

## 10. Dependencies

| Dep | Owner | Impact nếu thiếu |
|---|---|---|
| Panasonic TMS team — confirm Q1, Q3, Q4 | BA escalate | 11/19 charts không ship được v1 |
| Panasonic Logistics team — zone mapping file (Q2) | BA escalate | 9/19 charts không ship được v1 |
| Smartlog backend — `mv_psv_main` đã refreshable & stable (đã có) | DE | ✅ Done |
| Smartlog backend — extend `mv_psv_trigger` với `*_auto` columns (nếu Q1=Yes) | DE | 11 charts blocked |
| Smartlog backend — materialize `panasonic_zone_master` (nếu Q2 có file) | DE | 9 charts blocked |
| Smartlog frontend — Settings Dialog cho widget SQL paste (memory: SQL ở spec, paste runtime) | FE | SQL canonical patterns không attach được vào widget |

---

## 11. References

- **Source artifact:** [PSV-auto-demo.pdf](../../05-reference/PSV-auto-demo.pdf)
- **Storytelling analysis:** [analysis/storytelling-notes.md](analysis/storytelling-notes.md)
- **Data spec:** [psv-accuracy-vrp-spec.md](psv-accuracy-vrp-spec.md)
- **Wireframe:** [psv-accuracy-vrp-wireframe.md](psv-accuracy-vrp-wireframe.md)
- **DDL `mv_psv_main`:** [analytics-workspace_psv.md](../../02-data/data-sources/clickhouse-ddl/analytics-workspace_psv.md)
- **Glossary:** [glossary.md](../../02-data/glossary.md)
- **Pipeline lineage:** [pipeline.md](../../02-data/data-sources/pipeline.md)

---

## 12. Handoff

- **Next step** = /ba resolve §8 Open Questions với Panasonic (priority Q1, Q2, Q3).
- **Then** /planner tạo `dev/plan.md` + `dev/tasks.md` + `dev/context.json` (theo CLAUDE.md workflow §Task Management) dựa trên scope §7 + answer Q-set.
- **Implementation team** = Squad DEV (FE: widget render trên `react-grid-layout`; BE: extend `mv_psv_trigger` nếu Option B; DE: zone master ETL).
