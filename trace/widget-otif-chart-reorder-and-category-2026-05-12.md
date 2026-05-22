# Trace Report — FEAT-128 widget-otif-chart-reorder-and-category

**Date**: 2026-05-12
**Auditor**: thuy le (PM/DA, squad1@gosmartlog.com) via `/da-trace`
**Scope**: feature folder [`docs/feature/widget-otif-chart-reorder-and-category/`](../../docs/feature/widget-otif-chart-reorder-and-category/) vs WidgetOTIF source code vs Mondelez section docs at [`projects/mondelez/01-sections/otif/`](../mondelez/01-sections/otif/)
**Branch / commit audited**: `fix-frontend-otif` @ HEAD (last impl commit: `80194e9 feat(dashboard): reorder OTIF charts and add chart by product type`)
**Plan version audited against**: `plan.md` revision r6 (2026-05-12)

---

## Sources used

| Source | Path | Status |
|---|---|---|
| Plan | [`docs/feature/widget-otif-chart-reorder-and-category/dev/plan.md`](../../docs/feature/widget-otif-chart-reorder-and-category/dev/plan.md) | Present (r6) |
| Tasks | [`.../dev/tasks.md`](../../docs/feature/widget-otif-chart-reorder-and-category/dev/tasks.md) | Present |
| Context | [`.../dev/context.json`](../../docs/feature/widget-otif-chart-reorder-and-category/dev/context.json) | Present (v2) |
| PRD (formal) | `docs/product/prd/...` | **Missing — informal single-stakeholder request from MDLZ SC Manager** (per context.json `pipeline.ba`) |
| Mondelez section PRD | [`projects/mondelez/01-sections/otif/prd.md`](../mondelez/01-sections/otif/prd.md) | Present @ v1.0.0 — **stale relative to FEAT-128 + prior chartByWarehouse work** |
| Mondelez section spec | [`projects/mondelez/01-sections/otif/spec.md`](../mondelez/01-sections/otif/spec.md) | Present — **stale** |
| Mondelez section wireframe | [`projects/mondelez/01-sections/otif/wireframe.md`](../mondelez/01-sections/otif/wireframe.md) | Present — **stale** |
| Frontend implementation | [`frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx`](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx) | Present (≈1900 lines) |
| Settings dialog | [`.../widget-otif-settings-dialog.tsx`](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif-settings-dialog.tsx) | Present |
| i18n EN | [`frontend/src/i18n/locales/en/dashboard-order-monitor.json`](../../frontend/src/i18n/locales/en/dashboard-order-monitor.json) | Present |
| i18n VI | [`frontend/src/i18n/locales/vi/dashboard-order-monitor.json`](../../frontend/src/i18n/locales/vi/dashboard-order-monitor.json) | Present |

---

## Drift summary

- ✅ Conformant claims (plan → code): **16**
- ⚠️ Minor drift: **2** (date-type FE/SQL mismatch surfaced as FU-1 in context.json; "value axis = OTIF%" wording in plan §2.2 vs actual implementation = 3 bars)
- ❌ Functional drift: **0** (implementation matches all 8 acceptance criteria — see plan §9)
- 🚫 Missing/stale source: **3 stale section docs** (`prd.md`, `spec.md`, `wireframe.md` in `projects/mondelez/01-sections/otif/`) + **1 missing formal PRD** (Mondelez section PRD does not cover `chartByWarehouse` either — pre-existing drift from `53dd564 feat(warehouse): ...`)

---

## Claim matrix (plan claims vs implementation)

| # | Claim | Source ref | Implementation evidence | Status |
|---|---|---|---|---|
| 1 | 9-section order (Filter → 4 KPI → FailOntime+FailInfull → Trend → Transporter → Category → SalesChannel → Warehouse → Area) | plan §9.1 | [widget-otif.tsx:1155](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1155) (SqlFilterPanel), [:1191-1234](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1191) (4 KpiCards), [:1240/1309](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1240) (FailOntime+FailInfull `xl:grid-cols-2`), [:1379](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1379) (Time), [:1497](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1497) (Transporter), [:1580](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1580) (Category), [:1671](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1671) (SalesChannel), [:1754](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1754) (Warehouse), [:1837](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1837) (Area) | ✅ |
| 2 | `chartByCategory` registered in data fetch via `execSection` | plan §9.2 | [widget-otif.tsx:860](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L860) | ✅ |
| 3 | Settings-dialog hint: "OTIF theo loại hàng (FRESH/DRY/MOONCAKE/...)" | plan §9.2 | [widget-otif-settings-dialog.tsx:126](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif-settings-dialog.tsx#L126) | ✅ |
| 4 | i18n vi `chartByCategory` = "OTIF / Ontime / Infull theo loại hàng" | plan §9.2 | [vi/dashboard-order-monitor.json:154](../../frontend/src/i18n/locales/vi/dashboard-order-monitor.json#L154) | ✅ |
| 5 | i18n en `chartByCategory` = "OTIF / Ontime / Infull by product type" | plan §9.2 | [en/dashboard-order-monitor.json:171](../../frontend/src/i18n/locales/en/dashboard-order-monitor.json#L171) | ✅ |
| 6 | Empty state branch when `sqlQueries.chartByCategory` blank | plan §9.2 | [widget-otif.tsx:1588](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1588) (`categoryNoConfig` key) + i18n entries [en:172](../../frontend/src/i18n/locales/en/dashboard-order-monitor.json#L172) / [vi:155](../../frontend/src/i18n/locales/vi/dashboard-order-monitor.json#L155) | ✅ |
| 7 | `OTIF_CATEGORY_ORDER` extended to 7 entries (FRESH, DRY, MOONCAKE, POSM/OFFBOM, TEST, EQUIPMENT, PM) | plan §9.2, §5.1 | [widget-otif.tsx:522-530](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L522-L530) | ✅ |
| 8 | Sort segments client-side by `OTIF_CATEGORY_ORDER` priority + fallback 99 | plan §9.2 | [widget-otif.tsx:938-955](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L938-L955) | ✅ |
| 9 | No new `CATEGORY_COLORS` constant — reuse Recharts default (Ontime/Infull/OTIF tri-bar pattern from chartByArea) | plan §5 row 3, §9.2 | [widget-otif.tsx:1625-1663](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1625-L1663) — same `#22D3EE`/`#10B981`/`#8E59FF` palette as other 3-bar charts | ✅ |
| 10 | Settings dialog adds `chartByCategory` section with required-columns metadata | plan §3 | [widget-otif-settings-dialog.tsx:121-140](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif-settings-dialog.tsx#L121-L140) — accepts `group_of_cago`/`group_of_cargo`/etc. aliases | ✅ |
| 11 | `OtifSqlQueries` interface includes `chartByCategory` (+ existing `chartByWarehouse`) → 12 total keys | plan §5.2 column req | [widget-otif-settings-dialog.tsx:20-33](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif-settings-dialog.tsx#L20-L33) | ✅ |
| 12 | `normalizeCategoryProgressFromSql` accepts `category` alias | plan §5.3 | [widget-otif.tsx:208-227](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L208-L227) — alias list `[group_of_cago, group_of_cargo, groupofcargo, groupOfCargo, category]` | ✅ |
| 13 | FailOntime + FailInfull side-by-side at `xl:grid-cols-2` (position #3) | plan §2.1, §9.1 | [widget-otif.tsx:1238](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1238) | ✅ |
| 14 | `categoryFilter` in filter bar (predates FEAT-128, still works post-reorder) | plan §3 AC, §5.2 | [widget-otif.tsx:552+](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L552) `OTIF_FILTER_DEFINITIONS` | ✅ |
| 15 | ChartExportMenu (CSV) on new chart via `exportData={byCategory}` + `exportFilename='otif-by-category'` | plan §3 AC | [widget-otif.tsx:1583-1584](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1583-L1584) | ✅ |
| 16 | Status: code-done, branch `fix-frontend-otif` pushed | context.json `branch`, `status` | `git status` reports branch up-to-date with `origin/fix-frontend-otif`; commit `80194e9` merged into branch tip | ✅ |
| 17 | Plan §2.2 says new chart "value axis = OTIF%" only | plan §2.2 | Implementation renders **3 bars** (Ontime + Infull + OTIF) — pattern reuse from chartByArea | ⚠️ Minor — plan wording lags actual implementation (chose richer 3-bar pattern, consistent with sibling charts) |
| 18 | FE `OTIF_DATE_TYPE_OPTIONS` has 2 values; SQL CASE in r6 template has 7 | plan §5.4 note #3, context.json `openFollowUps[FU-1]` | [widget-otif.tsx:507-510](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L507-L510) (2 options) vs r6 SQL template (7 CASE branches) | ⚠️ Minor — already tracked as FU-1, non-blocker for FEAT-128 ship |

---

## Cross-doc consistency findings

| # | Drift type | Detail | Sources in conflict | Severity |
|---|---|---|---|---|
| D1 | **Section count + order** | `prd.md §5.2` and `spec.md §1` describe **6 charts** in the old order (byArea, bySalesChannel, byTransporter, Trend, FailOntime, FailInfull). Code now has **8 charts** in insight-first order: FailOntime + FailInfull → Trend → Transporter → **Category (NEW)** → SalesChannel → **Warehouse (PRE-EXISTING, never documented)** → Area | `prd.md`, `spec.md`, `wireframe.md` vs code | **High** |
| D2 | **SQL query catalog mismatch** | `prd.md §6` Table 6 lists **10 SQL queries** (no `chartByWarehouse`, no `chartByCategory`). `spec.md §11 OtifSqlQueries` lists **10 keys**. `spec.md §13` says "10-tab SQL editor". Code interface has **12 keys** — [widget-otif-settings-dialog.tsx:20-33](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif-settings-dialog.tsx#L20-L33) | `prd.md`, `spec.md` vs code | **High** |
| D3 | **Missing normalizer in spec** | `spec.md §4` lists 9 normalizers; code has 11 (`normalizeWarehouseProgressFromSql`, `normalizeCategoryProgressFromSql` missing) | `spec.md` vs [widget-otif.tsx:194-227](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L194-L227) | Medium |
| D4 | **Main query parallelism** | `spec.md §3.1` says "7 sections song song" — code now fires **9** parallel `execSection` calls | `spec.md` vs [widget-otif.tsx:855-863](../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L855-L863) | Medium |
| D5 | **Wireframe layout** | `wireframe.md` "Tổng quan layout" ASCII shows old order (byArea first, fail charts last). Real UI now puts fail charts at the **top** right after KPI cards. Two new charts (Warehouse, Category) absent. | `wireframe.md` vs code | **High** (the only visual doc; misleading for stakeholders) |
| D6 | **Date Type filter values** | All 3 docs say only **2 values** (ETA gửi thầu, ATA chi tiết chuyến). Plan §5.4 note #3 surfaces that r6 SQL template assumes **7 values** — this is a tracked follow-up (FU-1) but should be noted in the section docs as an open caveat | `prd.md §3.1`, `spec.md §2.1`, plan §5.4 note #3 | Low |
| D7 | **No FEAT-128 trail in section docs** | The Mondelez section folder has `_releases/`, `analysis/` but neither folder nor `prd.md` references `FEAT-128` or links back to the feature plan | `projects/mondelez/01-sections/otif/` | Low |
| D8 | **chartByWarehouse pre-existing drift** | `chartByWarehouse` was introduced in commit `53dd564 feat(warehouse): add OTIF charts and tooltips for warehouse performance` (before FEAT-128) but section docs were never updated for it — FEAT-128 audit surfaces this pre-existing gap | git history vs `prd.md` / `spec.md` / `wireframe.md` | Medium (pre-existing) |

---

## Recommended actions

| # | Action | Owner | Type | Effort |
|---|---|---|---|---|
| A1 | Update `projects/mondelez/01-sections/otif/prd.md` §5.2 (Charts table) + §6 (SQL Queries table) to cover 8 charts + 12 SQL keys in new insight-first order | PM/DA (this trace run) | Doc update | S |
| A2 | Update `projects/mondelez/01-sections/otif/spec.md` §1 Component Tree, §3.1 parallel count, §4 normalizers, §11 interface, §13 tab count | PM/DA (this trace run) | Doc update | S |
| A3 | Update `projects/mondelez/01-sections/otif/wireframe.md` "Tổng quan layout" ASCII to reflect insight-first order + 2 new chart blocks | PM/DA (this trace run) | Doc update | S |
| A4 | Decide FU-1: extend FE `OTIF_DATE_TYPE_OPTIONS` to 7 values **or** trim SQL CASE to 2 — tasks T6.1/T6.2 in `tasks.md` | dev-fe **or** da-ch | Code fix (out of FEAT-128 scope) | S |
| A5 | Commit + ship FEAT-128 working tree (4 modified FE files already merged in `80194e9`; verify branch pushed and open PR) — tasks.md T4.1-T4.4 | PM/DA | Process | S |
| A6 | Append FEAT-128 row to `projects/mondelez/triage/backlog.md` + `by-team.md` (or re-run `/da-triage`) — tasks.md T5.1-T5.4 | PM/DA | Process | S |

A1-A3 are executed in this same conversation per user request — see commit log after this report.

---

## Open questions (block sign-off)

None blocking. FU-1 (date-type FE/SQL mismatch) is documented as non-blocker in `context.json` and can be picked up as a separate triage item.

---

## Process notes

- Plan §9 (Done verification) is **fully load-bearing** — every acceptance criterion was traced to a specific path:line in this audit. The plan's self-assessment of `[D] Done` is independently verified.
- `chartByWarehouse` is **not** new to FEAT-128 — it was introduced earlier (commit `53dd564`) but never reflected in the section docs. This audit captures both layers of drift at once (D8 + D1/D2).
- No formal PRD exists at `docs/product/prd/...` for the OTIF widget itself; the Mondelez section docs in `projects/mondelez/01-sections/otif/` are the de-facto product spec for tenant work.

---

**ARTIFACT_PATH**: `projects/trace/widget-otif-chart-reorder-and-category-2026-05-12.md`
**DRIFT_COUNT**: `3 High / 3 Medium / 2 Low` (plus 2 Minor inside claim matrix already-tracked)
**BLOCKING_QUESTIONS**: `0`
**RECOMMENDED_NEXT**: update `prd.md`, `spec.md`, `wireframe.md` in `projects/mondelez/01-sections/otif/` (A1-A3 — done in same session); ship FEAT-128 (A5) and route FU-1 (A4) via `/da-triage`.
