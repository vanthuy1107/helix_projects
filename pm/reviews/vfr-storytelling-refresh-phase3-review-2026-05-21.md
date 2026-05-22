# PM Review — VFR Storytelling Refresh Phase 3 (By Vendor + 4 Personas)

| Trường | Giá trị |
|---|---|
| **Date** | 2026-05-21 |
| **Reviewer** | thuy le — PM/DA (squad1@gosmartlog.com) |
| **Phase scope** | T3.1 → T3.6 — `byVendor` chart + 4 persona presets (BOD/Ops/Carrier/Planning) |
| **Branch** | `feat-vfr-late-alert` (ADR-N3 misnomer accepted; PM-driven, not dev squad) |
| **Status checked against** | [`tasks.md`](../../../docs/feature/vfr-storytelling-refresh/dev/tasks.md), git status, vitest/eslint/build output, file diffs |
| **Verdict** | **APPROVED for PM smoke-test** — 3 condition cần verify trước commit (xem §5) |

---

## 1. Cross-check evidence vs claim

| Claim trong tasks.md / summary | Evidence kiểm chứng | Verdict |
|---|---|---|
| 6 files modified (FE + i18n) | `git status` → 8 modified (6 Phase 3 + 2 pre-Phase 3 carryover: `widget-vfr.tsx` đã M từ Phase 2, `context.json`/`plan.md` carryover) | ✅ match |
| spec §22 appended | `vfr-spec.md` in `projects/` — gitignored, không hiện trong git status (đúng kỳ vọng) | ✅ verified bằng file content |
| ZERO new file Phase 3 (shared bar reuse) | `git status -u` → 0 new untracked file thuộc Phase 3 scope. Phase 2 untracked vẫn ở đó. | ✅ deviation đúng, hợp pattern |
| 0 commit | `git log --oneline -10` → commit mới nhất `2dbefec` thuộc late-alert, không có Phase 3 commit | ✅ PM giữ quyền commit |
| 104/105 vitest pass | Console output | ✅ pre-existing failure (`widget-vfr.columns.test.ts`) đã document Phase 2 T2.8.1 — không phải Phase 3 introduce |
| 0 eslint error | Console output: 14 warning (12 pre-existing + 1 `tenderByVendorApi` exhaustive-deps + 1 `preserve-manual-memoization`) | ✅ 0 error, 0 `eslint-disable` introduced (lesson 2026-05-05 compliant) |
| Build ✓ 18.07s | Console output | ✅ |

**Verdict**: Tất cả claim đối chứng được. Không phát hiện báo cáo lệch.

---

## 2. PM angle — 4 persona presets

### Preset-bod (BOD/Executive) ⚠️ CONDITIONAL

**Section set**: `[hero, chartLoadingType]` (h12). PM concern:
- **Loading-type trend chart vs sparkline 13w trong hero** — overlap conceptually. Hero đã có sparkline gọn, chartLoadingType là composed chart với grouped bars + 4 lines (Loose/FP/Other × time). Cho BOD lens, sparkline đủ — chartLoadingType có thể quá tải.
- **PM ask trước demo BOD**: Cân nhắc swap `chartLoadingType` → `timeAreaTable` (xu hướng khu vực theo tháng — đặc thù logistics hơn cho BOD). Hoặc giữ nguyên và thu thập feedback sau buổi 1.
- Effort = 0 nếu chỉ đổi `visibleSections` array — không động code.

### Preset-ops (Dispatch) ✅ APPROVE

**Section set**: `[hero, bucketChips, exceptionPanel, detail]` (h18). Match đúng pattern AS-IS dispatcher cần: bucket count → exception drill → detail grid. CTA drill (vfrMaxFilter='<50') từ exception panel đã wire từ Phase 1.

- **PM note**: Plan §3 ADR-N4 nói "Ops với VFR<70 pre-filter" cho detail. Hiện preset không inject pre-filter (chỉ set `visibleSections`). Chấp nhận v1.0 — user vẫn drill được qua exception CTA. Pre-filter là enhancement Phase 4 nếu cần.

### Preset-carrier ✅ APPROVE

**Section set**: `[hero, chartVendor, chartArea, timeAreaTable, detail]` (h22). Order chartVendor → chartArea: vendor ranking trước, area context sau — đúng audience priority.

- **PM ask**: Verify khi mode='operation' và admin chưa paste `byVendorOperation` SQL → chart slot `null` (đã wire `vendorBarRows.length > 0` check). Kỳ vọng UX: Carrier preset không nên hiển thị empty card lớn — ẩn slot là OK Phase 3.

### Preset-planning ✅ APPROVE (default fallback)

**Section set**: empty array → fallback all-visible (9 sections). Legacy `preset-om-vfr` cũng map về cùng behavior. Migration risk = 0.

---

## 3. AC checklist — Phase 3 deliverables

| AC | Auto-verified | Manual pending |
|---|---|---|
| AC-S5 (By Vendor chart + RAG sort) | Unit + lint + build ✅ | Paste §22.1 SQL → render check (PM smoke) |
| AC-S6 (4 persona presets distinct) | Static check: 4 preset IDs trong file ✅ | Instantiate qua template gallery → verify section subset (PM smoke) |

**AC-S7** (Bucket chips RAG) đã ship Phase 2 — không trong Phase 3 scope. AC-S1..S4 đã ship Phase 1+2.

---

## 4. Risk register — Phase 3 specific

### RISK-VFR-08: byVendor admin paste chưa drill, chart 4 sẽ empty silent
- **Discovered**: 2026-05-21 (Phase 3 review)
- **Likelihood**: High — Mondelez rollout day 1, chưa chắc admin biết §22.1 SQL ở đâu
- **Impact**: Medium — Carrier preset core value bị mất; BOD/Ops/Planning vẫn dùng được
- **Owner**: PM (thuy le) + Rollout team
- **Mitigation**:
  - (a) Trước demo Carrier preset, **paste §22.1 SQL trên 1 dashboard demo Mondelez tenant** để PM verify chart 4 render đẹp với data thật.
  - (b) Phase 4 polish: thêm placeholder "Admin chưa cấu hình SQL — vào Settings → tab By Vendor (Thầu)" thay vì ẩn slot. Effort 0.25d.
- **Status**: Open

### RISK-VFR-09: actionTitleVendorWorst template fix có thể break i18n display nếu cache cũ
- **Discovered**: 2026-05-21 (T3.5 changed param `{{tripCount}}` → `{{totalVendors}}` để match factory)
- **Likelihood**: Low — VI/EN cùng đổi đồng bộ
- **Impact**: Low — chỉ ảnh hưởng VFR widget title text (action title), không break logic
- **Owner**: PM verify khi smoke test
- **Mitigation**: Hard reload (Ctrl+Shift+R) khi smoke local. Production rollout cần invalidate i18n cache nếu có CDN edge cache.
- **Status**: Open

### RISK-VFR-10: 2 query mới (byVendor + byVendorOperation) đẩy Promise.all batch từ 12 → 14 SQL parallel
- **Discovered**: 2026-05-21
- **Likelihood**: Medium — Mondelez dataset chưa stress-tested với 14 SQL parallel
- **Impact**: Low — ClickHouse MV pre-aggregated, latency thường <500ms/query. P95 batch latency có thể tăng 100-200ms.
- **Owner**: PM monitor sau ship; escalate sang dev squad nếu P95 > 2s
- **Mitigation**: Phase 5 review (`/reviewer`) verify React Query `placeholderData: (prev) => prev` đã có (lesson 2026-05-04) — nếu có thì user perceive smooth refetch. Hiện tại đã có (line 715).
- **Status**: Open (acceptable)

---

## 5. Conditions trước PM commit Phase 3

1. **Smoke verify AC-S5 trên local dev** (5 phút) — paste §22.1 SQL vào Settings → "By Vendor (Thầu)" → Carrier preset → chart 4 render sorted RAG. Screenshot vào `projects/mondelez/01-sections/vfr/analysis/` nếu cần evidence.
2. **Smoke verify AC-S6 (4 preset)** (10 phút) — instantiate 4 preset từ template gallery, verify section subset match table §2 trên. Hard reload nếu i18n preset card không hiện.
3. **Decide preset-bod section set** (xem §2) — giữ `chartLoadingType` hay swap sang `timeAreaTable`. Quyết định 1-line trong tasks.md T3.4.1 trước commit. Nếu giữ → ghi rationale.

Sau 3 condition trên → PM commit theo memory `feedback_pm_driven_feature_attribution` (Executed by attribution đã có trong artifact triple). Commit pattern theo Phase 2: `feat(dashboard/vfr): T3.x ...` per sub-task hoặc 1 commit bundle "T3 by-vendor + persona presets" — PM tự quyết.

---

## 6. Defer / out-of-scope flag

| Item | Status | Lý do defer |
|---|---|---|
| `widget-vfr-vendor-bar.tsx` dedicated component | SKIP (deviation T3.3.1) | Phase 2 đã consolidate 3-file plan → 1 shared `WidgetVfrSortedBar`. Continuation hợp lý. |
| Empty state placeholder cho chart 4 | DEFER → Phase 4 | T3.3.3 minimal-null đủ Phase 3 AC. Phase 4 polish thêm "Admin chưa cấu hình" CTA. |
| `exceptionAggregate` dedicated SQL section | SKIP | Phase 1 đã reuse `detail`/`detailOperation` (T1.4.2). Không cần section riêng. |
| Persona pre-filter (vd Ops detail VFR<70) | DEFER | v1.0 rely on exception CTA drill. Pre-filter là Phase 4 enhancement nếu Mondelez feedback. |

---

## 7. Lessons surfaced Phase 3 (cho `docs/lessons/dev.md` post-ship)

1. **i18n placeholder param name phải match factory key exact** — phát hiện `actionTitleVendorWorst` template dùng `{{tripCount}}` nhưng factory pass `totalVendors`. Bug silent: i18next không error, chỉ leave `{{tripCount}}` literal trong UI. Lesson: khi add i18n key có placeholder, grep factory caller để verify param name match.
2. **`visibleSections` empty array vs missing → cùng fallback all-visible** — tránh tri-state confusion (undefined vs [] vs ['hero']). Single rule: "len 0 = full visibility" giữ migration đơn giản cho legacy preset.
3. **Settings dialog requiredColumns alias matrix phải cover canonical SQL output column** — nếu admin paste §22.1 (alias `vendor`/`planned`/`vfr`) thì pass; nếu paste hand-rolled với `nha_van_tai` raw thì alias matrix `['vendor', 'nha_van_tai']` cũng pass. Tốt cho admin flexibility.

---

`ARTIFACT_PATH`: `projects/pm/reviews/vfr-storytelling-refresh-phase3-review-2026-05-21.md`

`NEXT_ACTION`:
- **PM (thuy le)** — chạy 3 smoke verify §5 trên local dev (~15 phút) hôm nay 2026-05-21.
- Quyết định preset-bod section set (giữ chartLoadingType hay swap timeAreaTable).
- Nếu green → commit Phase 3 bundle với attribution per memory `feedback_pm_driven_feature_attribution`.
- Tiếp theo: chọn (a) Phase 4 polish (0.5-1d, error banner + mobile + a11y) hoặc (b) skip thẳng Phase 5 reviewer nếu polish acceptable v1.0.

`BLOCKERS`: Không có blocker. 3 condition §5 là verify steps, không phải blocker stakeholder.
