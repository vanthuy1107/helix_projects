# Analysis: Đánh giá tổng quan view OTIF hiện tại

**Date**: 2026-05-10
**Requested by**: PM/BA/DA squad1
**Tenant scope**: Mondelez (MDLZ) — code path single-tenant nhưng ship qua framework dashboard chung
**Section docs (folder cha)**: [prd.md](../prd.md), [spec.md](../spec.md), [wireframe.md](../wireframe.md)
**Analysis cùng folder**: [feat-057-analysis.md](feat-057-analysis.md), [pulse-W19-2026-05-04_2026-05-09.md](pulse-W19-2026-05-04_2026-05-09.md)

---

## Question

OTIF view hiện đang ở trạng thái nào (architecture, data, UX, debt)? Có gì đáng tin, có gì cần fix trước khi tiếp tục đầu tư?

## Method

Đọc song song:
- 2 nguồn implementation: legacy `OTIFView.tsx` (Mondelez backend) + current `WidgetOtif` (control-tower SQL widget framework)
- 3 FormConfig grid stubs (`DSHOTIFDTG01`, `DSHOTIFFLG01`, `DSHOTIFOPG01` — xem [../../../../../backend/src/FormConfigs/](../../../../../backend/src/FormConfigs/))
- PRD/spec/wireframe gốc tại [../../../05-reference/[done] otif/](../../../05-reference/)
- Triage backlog tồn đọng [../../../triage/widget-otif-pending-summary.md](../../../triage/widget-otif-pending-summary.md)
- Plan refactor: [../../../../../docs/superpowers/plans/2026-05-04-otif-widget-grid-refactor.md](../../../../../docs/superpowers/plans/2026-05-04-otif-widget-grid-refactor.md), [../../../../../docs/feature/widgets-otif-pattern-rollout/dev/plan.md](../../../../../docs/feature/widgets-otif-pattern-rollout/dev/plan.md)

KHÔNG truy vấn DB ad-hoc — đánh giá dựa trên code + doc + verified data snapshot trong PRD §5.7.8 (Apr–May 2026, 1.28M rows).

---

## Architecture state

### Có 2 phiên bản đang tồn tại song song

| Khía cạnh | Legacy `OTIFView.tsx` (Mondelez) | Current `WidgetOtif` (this repo) |
|---|---|---|
| Hình thức | Page độc lập, route riêng | Widget render trên dashboard canvas |
| Data layer | 5 REST endpoints `/api/ctower/otif/*` (cần thêm 6 nữa per Figma) | 11 SQL queries cấu hình per-instance qua `dashboardV2Api.executeWidget` |
| Backend | `WPred.Api/CTowerController.cs` đập thẳng ClickHouse `mv_otif` | Generic SQL widget runtime (secure-widget-sql-runtime) — không bound vào MV cụ thể |
| Filter | Hardcoded 6 filter | `SqlFilterPanel` configurable per-widget |
| Grid persistence | Column ẩn/hiện local | `gridKey` → `UserFormSetting` aliases (cross-session) |
| Status | Production live cho MDLZ | Live in control-tower repo, đã rollout pattern sang 6 widget khác |

→ **Code path tại repo này là `WidgetOtif`**. Ba file `widget-otif.tsx` (~1500 lines, "God Component"), `widget-otif-detail.tsx`, `widget-otif-settings-dialog.tsx` + columns + 3 FormConfigs.

### Data semantics (verified snapshot 2026-05-07, MV `analytics_workspace.mv_otif`)

- 1.28M rows, 1 row/SO sau header-pick theo `group_priority`. 60.7% rows là `'Không có dữ liệu STM'` — bị date filter loại implicitly.
- 3 status: `ontime_status`, `infull_status`, `otif_status` tính trong SQL, **UI chỉ display** (single source of truth — đúng nguyên tắc).
- 9 fail reasons (6 ontime + 3 infull) — đã verified empirical: 0/61,970 rows có compound concat reason → trong production luôn single-valued.
- KPI threshold chốt: OTIF 90/80, Ontime+Infull 95/85.
- Refresh 5 phút (SharedMergeTree REFRESH EVERY 5 MINUTE).

---

## Findings

| # | Type | Statement | Evidence |
|---|---|---|---|
| F1 | **Insight** | OTIF thực tế cách target rất xa: tất cả 11 area đều <90% (max 71.3% South Central Coast, min 62.2% North Central Coast). Empty area paradox đạt 86.9% — cao bất thường. | [../../../05-reference/[done] otif/otif.prd.md](../../../05-reference/) §5.7.8 snapshot Apr 1 – May 7 2026 |
| F2 | **Insight** | 93% fail Infull thuộc Transport (xe chở thiếu so với bốc xếp), chỉ 5% Warehouse, 1% Combined → vấn đề chủ yếu ở giao, không phải kho. | PRD §5.6.4, distribution Apr 2026: Transport 74,744 / Warehouse 4,678 / Combined 1,080 |
| F3 | **Bug — silent** | `REASON_COLORS` mapping tại `widget-otif.tsx` line ~576-582 dùng key tiếng Việt ("Lỗi transport giao trễ", "Lỗi rớt do warehouse"...) nhưng MV trả `not_ontime_reason` tiếng Anh ("Late delivery by Transport", v.v.). 100% rows rơi vào `FALLBACK_REASON_COLORS` cycle → màu chart không stable theo reason. | Compare [../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx) vs PRD §5.6.4 + spec §6.3 |
| F4 | **Fact** | Hardcoded fallback URL `https://warehouse-prediction-mondelez-be-stage.smartlogvn.com` tại [../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/order-monitor-api.ts](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/order-monitor-api.ts) line 8-9 — vi phạm pattern multi-tenant của Smartlog Base (connection từ JWT claim `TenantDBConfiguration`). Áp dụng cho cả 4 modules (Late Order Alert, OTIF, Shipping Progress, Tender Response, VFR). | Direct read source |
| F5 | **Hypothesis** | Empty area 86.9% OTIF cao bất thường — nghi là internal transfers không qua carrier (less fail). PRD §11 Q3 + CLAUDE.md Data Exclusion Rule #4 yêu cầu loại internal transfer khỏi OTIF, **chưa verify** áp dụng. | PRD §9 Q3 status `Cần verify`; §5.6.9 row 4 `⚠️` |
| F6 | **Fact — open bug** | Pipeline có 5 inconsistency **chưa fix** (PRD §5.7.6): typo Redshift, filter coalesce inconsistency giữa 4 KPI summary và % chiều vận hành, KPI dùng `count(so)` vs `countDistinct(so)` (lệch ~0.1% với SO duplicate khác whseid), `assumeNotNull` masterdata throw runtime, **timezone mix DateTime64('UTC') vs DateTime no-tz có risk ±7h drift**. | PRD §5.7.6 BUG-1..5 |
| F7 | **Hypothesis** | Backlog Mondelez có 3 item triage tồn đọng (`UX-067`, `FEAT-056`, **`FEAT-057 Major`**). FEAT-057 quote mơ hồ ("bổ sung lý do rớt là gồm cả 2") — chưa clarify với user, blocking discovery. | [../../../triage/widget-otif-pending-summary.md](../../../triage/widget-otif-pending-summary.md) |
| F8 | **Insight** | 11 SQL queries (cards, 4 chart-by-dim, 2 fail-reason, trend, opSummary, failSummary, detailTable) cấu hình per-instance qua dialog → khá flexible nhưng đẩy responsibility "viết SQL đúng schema" cho người setup widget. Mỗi instance có thể divergent. | [../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif-settings-dialog.tsx](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif-settings-dialog.tsx) line 49-197 |
| F9 | **Fact** | Logic core verified và rất chặt: `round(toFloat64(x), 4)` cho infull match (tránh false positive precision), divide-by-zero protection 2 layer (`if(total=0,0,…)` SQL + `r.totalSo > 0 ? … : 0` UI), `coalesce(NULL, 'Unclassified')` cho dim filters. | PRD §5.6.2, §5.6.3, §5.6.5 |
| F10 | **Insight** | KPI threshold (90% OTIF green) không thể actionable trong realm hiện tại vì 0/11 area đạt được. Threshold cần re-calibrate theo baseline thực tế hoặc đổi sang relative metric (MoM trend). | F1 cross-reference với PRD §4.3 |

---

## Recommendation

| Priority | Owner | What | Why | Success measure |
|---|---|---|---|---|
| **P0 — Blocker** | DA | Verify Q5 timezone drift: chạy SQL check `ATA - ETA` distribution xem có cluster gần ±7h boundary không | Nếu drift thật → mọi `Failed Ontime`/`Ontime` classification đang sai cho subset đơn → KPI có thể wrong by hundreds-of-orders | 1 spike report, < 1 ngày |
| **P0 — Bug fix** | FE dev | Sửa `REASON_COLORS` mapping VN → EN tại `widget-otif.tsx` line ~576 khớp với MV labels (`Late delivery by Transport`, `Late arrival by Transport`, `Late warehouse call by Warehouse`, `Late pickup by Warehouse`, `Late departure by Transport`, `Thiếu dữ liệu đăng ký dock`, `Warehouse Infull Failure`, `Transport Infull Failure`, `Warehouse + Transport Infull Failure`) | Hiện 100% reason hiển thị fallback color → user không phân biệt được pattern qua color | Visual diff: từng reason có màu cố định |
| **P1 — Discovery** | BA + MDLZ | Resolve **FEAT-057** "bổ sung lý do rớt là gồm cả 2" — call ngắn với MDLZ, lấy screenshot/raw context từ Excel gốc | Quote 1 dòng mơ hồ, có 3 interpretation khả dĩ; bất kỳ dev nào pickup mà không discovery sẽ làm sai | 1 PRD revision hoặc bug-report rõ scope |
| **P1 — Tech debt** | FE dev | Loại bỏ hardcoded stage URL fallback `https://warehouse-prediction-mondelez-be-stage.smartlogvn.com` — bắt buộc widget config phải có `dataSourceId` rõ ràng, fail loud nếu thiếu | Vi phạm multi-tenant; leak tenant Mondelez stage info; nếu Mondelez xoá stage server thì 4 widgets crash silent | Grep repo `mondelez-be-stage` = 0 hits |
| **P2 — Data trust** | DA + BE | Verify Q1 (upstream `mv_otif_swm_data`/`mv_otif_stm_data` áp `is_deleted=0`) và Q2 (cancelled/test orders bị loại — đặc biệt cargo group `'TEST'` priority 5 có thể đang lọt vào MV) | Nếu test orders vào MV → mọi % KPI hiện tại có "rác" — không đo được mức độ | DDL audit + 2 query verification + update MV nếu cần |
| **P2 — UX clarity** | BA + FE | Empty area paradox: tách nhãn 'Chưa phân loại' thành 'Internal transfer / không qua carrier' (nếu confirmed F5) thay vì gộp với rows lỗi data | Hiện ~4,500 SO/tháng + paradox 86.9% confuse user khi đọc chart | User feedback test 1 round |
| **P3 — Threshold** | BA | Re-calibrate threshold OTIF: thay vì 90/80 absolute (không actionable), đổi sang relative (vs baseline tháng trước) hoặc tier theo area maturity | 0/11 area đạt 90% → threshold mất tín hiệu | Threshold mới chia rõ green/amber/red trong 4 tier |
| **P3 — Refactor** | FE dev | Tiếp tục plan widget-grid-column-aliases rollout: extract reason color map ra config, extract VN/EN translation map cho fail reasons (PRD OOS-8 — Phase 2 placeholder) | Giúp reuse cho tenant khác (KA/Vinamilk/...) | Hardcoded constant `AREAS`/`TRANSPORTER_OPTIONS`/`GROUP_OF_CARGO_OPTIONS` chuyển sang config |

---

## Caveats

- **Không tự chạy SQL ad-hoc**: đánh giá dựa trên PRD verified snapshot (Apr 1–May 7 2026) + code state. Nếu MV/code đã thay đổi sau 2026-05-07 thì 1 số finding có thể stale — đặc biệt số liệu F1, F2.
- **Không kiểm tra runtime**: F3 (REASON_COLORS mismatch) là static analysis — chưa verify visually trong browser. Nếu có code path normalize reason VN→EN ở giữa pipeline mà tôi miss thì bug F3 không tồn tại; cần FE confirm bằng test.
- **Skill này KHÔNG audit conformance UI vs PRD** (việc của `/da-trace`). Đánh giá tập trung vào data + architecture + 1 số bug rõ ràng.
- **Cross-tenant**: Code đang single-tenant Mondelez (constants, fallback URL). Đánh giá generic "view OTIF hiện tại" — nếu user muốn đánh giá riêng cho tenant khác thì phải re-scope.

---

## Cross-references

- Code: [../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx), [widget-otif-detail.tsx](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif-detail.tsx), [widget-otif.columns.ts](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.columns.ts), [widget-otif-settings-dialog.tsx](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif-settings-dialog.tsx), [order-monitor-api.ts](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/order-monitor-api.ts)
- FormConfigs: [DSHOTIFDTG01](../../../../../backend/src/FormConfigs/DSHOTIFDTG01.json) (67 cột), [DSHOTIFFLG01](../../../../../backend/src/FormConfigs/DSHOTIFFLG01.json) (15 cột), [DSHOTIFOPG01](../../../../../backend/src/FormConfigs/DSHOTIFOPG01.json) (8 cột)
- Section docs (folder cha): [prd.md](../prd.md), [spec.md](../spec.md), [wireframe.md](../wireframe.md)
- Reference docs (legacy Mondelez OTIFView): [../../../05-reference/](../../../05-reference/) — `[done] otif/otif.prd.md`, `otif.spec.md`, `otif.wireframe.md`
- Triage backlog: [../../../triage/widget-otif-pending-summary.md](../../../triage/widget-otif-pending-summary.md)
- Plans: [../../../../../docs/superpowers/plans/2026-05-04-otif-widget-grid-refactor.md](../../../../../docs/superpowers/plans/2026-05-04-otif-widget-grid-refactor.md), [../../../../../docs/feature/widgets-otif-pattern-rollout/dev/plan.md](../../../../../docs/feature/widgets-otif-pattern-rollout/dev/plan.md)
