# UAT Plan — VFR (Vehicle Fill Rate) — Mondelez

**Tenant:** Mondelez
**Section:** `vfr` (01-sections)
**Layout under test:** Storytelling v2 (§18) as built on `origin/dev` (commit `69caff3`, pulled 2026-05-27)
**Window:** 2026-05-18 → 2026-05-22 (5 ngày) — cùng window UAT OTIF để khách reconcile chéo
**Loại ngày:** ETA (mặc định production) → cột `eta_vh`
**Filter còn lại:** ALL trên 5 chiều (Kho / Khu vực / NVC / Loại xe GT / Loại xe VH)
**Executed by:** PM/DA team (squad1@gosmartlog.com) — drive trực tiếp, không qua dev squad
**Mode router:** A. Design

---

## 1. Mục tiêu UAT

VFR widget đã ship v1.0 và đang hoàn thiện storytelling v2 trên branch `feat-vfr-late-alert` (đã merge vào dev). UAT nghiệm thu **layout v2 trên dev**, không phải v1 baseline. 4 persona phải đọc được:

- **BOD** — VFR tổng, xu hướng 14d → quyết định chiến lược.
- **Ops** — chuyến nguy hiểm <50%, kho/khu vực non-tải → can thiệp ngày.
- **Carrier** — VFR theo NVC + khu vực → đàm phán SLA.
- **Planning** — GT vs VH delta + by Loading Type → tinh chỉnh ghép hàng.

Storytelling refresh xoay quanh 7 acceptance criteria AC-S1..S7 (PRD §18.2).

---

## 2. Phạm vi (in scope)

| Section | Tested | Lý do |
|---|---|---|
| Hero card (Avg VFR + Δ GT−VH + sparkline + gap-vs-85) | ✅ | AC-S2 — change cốt lõi v2 |
| 4 bucket chips (Low/Med/High/Excellent) — RAG color | ✅ | AC-S7 — đổi từ 5 standalone cards |
| Exception panel <50% (7d, top-3 area/vendor/vehicle, CTA drill) | ✅ | AC-S3 — section mới hoàn toàn |
| Chart By Area (sorted bar + RefLine 85 + RAG) | ✅ | AC-S1 + AC-S4 |
| Chart By Vehicle (sorted bar + RefLine 85 + RAG) | ✅ | AC-S1 + AC-S4 |
| Chart By Vendor (sorted bar + RefLine 85 + RAG, gated on data) | ✅ | AC-S5 — chart mới |
| Chart By Loading Type × Time (multi-series, day/week/month toggle) | ✅ | Existing — verify còn đúng |
| Time × Area table (RAG cells + average row/col) | ✅ | AC-S4 — RAG mới |
| 4 persona presets (BOD / Ops / Carrier / Planning) | ✅ | AC-S6 — visibleSections control |
| Mode toggle GT ↔ VH | ✅ | Existing — verify hero delta vẫn visible cả 2 mode |
| Filter 7-field + 12-month cap clamp | ✅ | PRD §4.5 + §5.3 |
| Detail grid 30 cột + pre-filter từ exception CTA | ✅ | Spec §9 (cập nhật 30 cột, không 29) |

## 3. Ngoài phạm vi (out of scope)

- Late-alert correlation vào VFR widget — đã close §13 + OQ-05 (sống ở widget khác).
- Aggregate VFR formula correctness theo V3 Bước 4-5 — **BUG-VFR-09 Major separate ticket** (data team rewrite); FE chỉ render whatever SQL returns. UAT KHÔNG assert weighted formula correctness, chỉ kiểm "số FE = số SQL".
- Backend code change — widget zero-touch (admin-paste SQL pattern).
- Cross-tenant rollout — Mondelez-only v1.0.
- Migration target sang tenant config — hardcode 85 const.

---

## 4. As-built drifts vs PRD §18 — phải đối chiếu trong UAT

| ID | PRD §18 nói | Code thực tế (dev branch) | Action UAT |
|---|---|---|---|
| **D-S2-14d** | AC-S2 "sparkline 13w" | `VFR_SPARKLINE_DAYS = 14` ([widget-vfr.tsx:174](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L174)). Commit 41b3863 đổi tên `sparkline13w → sparkline14d`. | Test case lấy **14d** làm chuẩn. PRD cần update sau UAT (hoặc revert code). |
| **D-Detail-30** | Spec §9 + PRD §6 "29 cột" | `widget-vfr.columns.tsx` đếm được 30 cột. | Test case lấy **30 cột** làm chuẩn. Spec/PRD update. |
| **D-Vendor-gated** | AC-S5 "Chart By Vendor render khi admin pasted SQL" | Render `showSection('chartVendor') && vendorBarRows.length > 0` ([widget-vfr.tsx:1527](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L1527)) — gated trên cả `showSection` lẫn `vendorBarRows.length>0`. Empty state nếu rỗng. | Test cả 2 path: configured (có data) + unconfigured (empty state). |
| **D-OpReport-aliases** | Registry mong đợi 28 alias đúng nghiệp vụ | Operation `report vận hành` block giữ 3 alias tender "VFR gửi thầu theo tấn/khối/(max)" — copy-paste artifact. Cosmetic, không ảnh hưởng data. | Insight pack flag; không block UAT. |

> Drift D-S2-14d và D-Detail-30 mở 2 sub-decision cho stakeholder: (1) update doc theo code, hoặc (2) revert code về PRD. Câu trả lời chốt sau khi customer review.

---

## 5. Mô hình 4 lớp test

| Lớp | Mục đích | Tỷ lệ TC | Reconcile cần golden file? |
|---|---|---|---|
| **A. Data Reconciliation** | Dashboard vs SQL raw vs golden file MDLZ — Avg VFR, 4 bucket count, dimension VFR weighted, trend daily, top N | ~40% | ✅ Có |
| **B. Business Logic** | Định nghĩa MAX(VFR tấn, khối), weighted Loose/FP formula, bucket boundary ≥95 vs >95, RAG thresholds 85/75, target = 85% | ~25% | ⚠ MDLZ giải thích, không cần file |
| **C. UX & Storytelling** | 4 persona đọc được Q1→Q5; hero Δ GT−VH; exception CTA drill; action title chart; By Vendor empty state; preset section visibility | ~25% | — Quan sát |
| **D. Performance / Filter** | 12 SQL parallel < 3s; mode toggle KHÔNG refetch; date cap 12 tháng clamp + toast; multi-select IN; preset switch | ~10% | — Trace Network |

Thứ tự chạy trong session: **A → B → C → D**. Nếu A fail nặng (số lệch >tolerance) → STOP, regroup, không bàn UX với số sai.

---

## 6. Tolerance threshold (chốt trước Mode B)

| Metric | Tolerance default | Override khách |
|---|---|---|
| Avg VFR % (GT, VH) | ≤ 0.5pp | Mondelez có thể siết 0.3pp |
| Δ GT − VH | ≤ 0.5pp | — |
| Bucket count tuyệt đối (Low/Med/High/Excellent) | ≤ 1% | Lưu ý ≥95 vs >95 — verify boundary trước |
| Dimension VFR weighted (Area / Vehicle / Vendor / Loading Type) | ≤ 0.5pp | Vì weighted, lệch nhỏ do floating round chấp nhận |
| Top-N ranking khu vực / NVC kéo VFR | ≥ 4/5 tên match, thứ tự có thể lệch | — |
| Tổng chuyến (count distinct trip) | ≤ 1% | — |
| Tổng CBM kế hoạch (planned per dim) | ≤ 0.5% | — |
| Exception count <50% (7d) | ≤ 1% chuyến | — |
| Trend daily Avg VFR | ≤ 0.5pp/ngày | — |
| Filter response time | < 3s (filter combo), < 5s (page load) | — |

Vượt tolerance VÀ chưa có root cause → defect **Major minimum**.

---

## 7. Golden file requirement

| Trường | Spec gửi khách |
|---|---|
| Format | Excel/CSV với header rõ |
| Window | 2026-05-18 00:00 → 2026-05-22 23:59 (UTC+7) — confirm timezone với khách |
| Filter | ALL trên 5 chiều (matching UAT setup) |
| Loại ngày | ETA chuyến vận hành = `eta_vh` |
| Granularity tối thiểu | Avg VFR GT + VH per ngày · 4 bucket count per mode · Top 5 NVC / Khu vực kéo VFR · Tổng chuyến |
| Định nghĩa VFR MDLZ | Document công thức MAX(tấn, khối) hay khác? Weighted Loose/FP có dùng không? |

**Nếu khách chưa export sạch trước session UAT** → block Mode B → block session → chấp nhận lùi 1 tuần. KHÔNG vào session với SQL raw làm chuẩn (không đủ chứng minh "đúng nghiệp vụ").

---

## 8. Pass criteria

| Tiêu chí | Mục tiêu |
|---|---|
| Pass rate happy path | ≥ 95% |
| Pass rate edge case | ≥ 80% |
| Defect Critical open | 0 |
| Defect Major open | ≤ 2 với mitigation plan |
| Reconciliation matrix row in tolerance | 100% |
| Performance | < 3s filter, < 5s page load |
| Drift findings (D-S2-14d, D-Detail-30) | Có decision rõ — update doc hay revert code |
| BUG-VFR-09 (weighted formula V3) | KHÔNG block UAT v2; track riêng |

---

## 9. Live number context (snapshot Mode A, sẽ refresh ở Mode B)

Window 2026-05-18..22, filter ALL, date_type ETA:

| Metric | GT (Tender) | VH (Operation) | Δ |
|---|---|---|---|
| **Avg VFR** | 94.49% 🟢 | 78.10% 🟡 | **+16.39pp** |
| Total trips | 546 | 492 | — |
| Low <50% | 4 | **78** | +74 |
| Medium 50-70% | 6 | 87 | +81 |
| High 70-95% | 178 | 137 | -41 |
| Excellent ≥95% | 358 | 190 | -168 |

**Câu chuyện**: Kế hoạch (GT) rất tốt — 94.49% > target 85%. Thực thi (VH) lệch xa — 78.10% dưới target, với 78 chuyến <50% (~16% operations) cần can thiệp. Δ 16.39pp = signal lớn về gap planning vs execution. Đây CHÍNH LÀ giá trị storytelling v2 mang lại — không có hero Δ GT−VH v1.0 thì khách phải toggle qua lại 2 mode mới phát hiện.

---

## 10. Reconciliation matrix scope

Xem `vfr-uat-reconciliation-template.md` cho ma trận đầy đủ. Tóm tắt:

| Block | Row count | Mode | Source comparison |
|---|---|---|---|
| Hero KPI (Avg + 4 bucket + total) | 6 rows × 2 modes | GT + VH | Dashboard / SQL / Golden |
| Δ GT − VH | 1 row | — | All 3 sources |
| By Area | ~12 area × 2 modes | GT + VH | All 3 |
| By Vehicle | ~34 vehicle type × 2 modes | GT + VH | All 3 |
| By Vendor | ~11 NVC × 2 modes | GT + VH | Dashboard (if configured) / SQL / Golden |
| By Loading Type | 2-3 LT × 2 modes (Loose / Full Pallet / Loose-Losse) | GT + VH | All 3 |
| Trend daily | 5 ngày × 2 modes | GT + VH | All 3 |
| Exception <50% summary | 1 count + top dim chips | — | Dashboard vs SQL detail |

Tổng ~150 reconciliation rows. Khả thi chạy trong 1 session 2-3h.

---

## 11. Route handoff (defect lớp X → đi đâu)

| Defect lớp | Route | Lý do |
|---|---|---|
| **Lớp A — số lệch + root cause SQL/MV** | `/da-ch` audit pipeline + dev squad CH owner | Sửa registry SQL hoặc MV refresh |
| **Lớp A — số lệch + root cause filter/widget logic FE** | `/da-triage` → `/qa-executor` → dev FE | Sửa FE normalization hoặc filter substitution |
| **Lớp B — logic sai vs nghiệp vụ MDLZ** | `/ba` revision PRD trước, sau đó dev fix | Định nghĩa metric sai cần align nghiệp vụ |
| **Lớp B — bucket boundary >95 vs ≥95** (BUG-VFR-08 rollout) | Admin re-paste SQL widget config | Registry đã đúng, runtime config chưa sync |
| **Lớp C — UX khó dùng nhưng đúng spec** | `/da-trace` xác nhận drift PRD vs implementation | Mở conversation về drift |
| **Lớp C — drift D-S2-14d / D-Detail-30** | `/ba` decide update doc hay revert code | Stakeholder chốt |
| **Lớp D — perf chậm > 3s** | Dev squad theo module (FE caching / CH query plan) | Trace Network + EXPLAIN |

PM/BA dùng skill này KHÔNG cần nhớ route — đã có sẵn trong file này.

---

## 12. Pre-UAT prep checklist (Mode B trigger)

Trước session với khách 1-2 ngày:

- [ ] Golden file MDLZ đã nhận và normalize cùng window/filter
- [ ] Dry-run reconciliation matrix với golden file → status `ready` (xem `vfr-uat-dryrun-{date}.md` Mode B sẽ sinh)
- [ ] Re-run `python scripts/uat_vfr_export.py` với window UAT chính thức (nếu khách dời ngày)
- [ ] Browser test login + access dashboard tenant Mondelez
- [ ] Admin xác nhận By Vendor SQL đã paste qua Settings dialog (nếu chưa → test case AC-S5 sẽ verify empty state)
- [ ] Decision pending về D-S2-14d / D-Detail-30 — có cần báo khách hay giữ làm finding?

---

## 13. Session logistics

| Item | Spec |
|---|---|
| Participants khách | SC Manager + Carrier Mgmt lead + Planning lead (3 personas khác BOD) |
| Participants Smartlog | PM (squad1) + BA + DA + Frontend lead on-call |
| Duration | 2-3h (1h KPI + dim, 30min UX/preset, 30min exception drill, buffer 30min) |
| Tool | Browser + Excel side-by-side + execution log file mở sẵn |
| Recording | Screen record OK, chia sẻ link với khách sau session |

---

## 14. Skill references

- Skill `/da-uat` (Mode A→E lifecycle) — file này tuân `templates/uat-plan.md`
- Memory `project_vfr_late_alert_taxonomy`, `feedback_data_artifact_path`, `feedback_pm_driven_feature_attribution`, `feedback_no_v2_v3_filenames`, `feedback_no_coauthor_trailer`, `feedback_sql_review_must_check_registry`, `feedback_check_registry_before_handrolling_sql`
- PRD: [vfr-prd.md](../vfr-prd.md)
- Spec: [vfr-spec.md](../vfr-spec.md)
- Storytelling v2 plan: [docs/feature/vfr-storytelling-refresh/dev/plan.md](../../../../../docs/feature/vfr-storytelling-refresh/dev/plan.md)
