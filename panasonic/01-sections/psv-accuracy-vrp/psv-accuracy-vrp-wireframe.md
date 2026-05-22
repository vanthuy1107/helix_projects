# Wireframe — psv-accuracy-vrp

> **Section:** `psv-accuracy-vrp`
> **Tenant:** Panasonic
> **Data source:** `mv_psv_main` (ClickHouse cluster `analytics_workspace`)
> **Audit source:** `psv_target FINAL`
> **Author:** /da-storytelling-data → packaged for /ba → /planner
> **Date:** 2026-05-21 (revised — tab layout + raw data tables)
> **Status:** DRAFT — 5 tabs theo audience, 19 charts + 5 raw data tables exportable
> **Related:** [prd](psv-accuracy-vrp-prd.md) · [spec](psv-accuracy-vrp-spec.md) · [storytelling notes](analysis/storytelling-notes.md)

---

## 1. Layout Overview — Audience-Aligned Tabs

Wireframe v1 cũ (long-scroll 9 levels, ~3,200px) đã được refactor thành **5 tabs theo audience**:

| Tab | Audience chính | Business question | Charts | Raw table |
|---|---|---|---|---|
| **1. Overview** | BOD + Planning Lead landing | "VRP đang ổn không? Có exception gì cần biết?" | A1, B1, A2, B2, A3, B4 (condensed) + A4 footer | — |
| **2. Reliability** | Planning Lead | "VRP fail ở zone/constraint nào? Trend ra sao?" | A2, B2, B3, B4 (full detail) | T-CONSTRAINT |
| **3. Vendor & Carrier** | Procurement Lead | "Planner swap vendor nào? Δ chi phí bao nhiêu?" | C1, C2, C3, C4, C5 | T-VENDOR |
| **4. Cost Variance** | Finance + Planning Lead | "Zone/vendor nào tiết kiệm/lỗ? Bubble nào cần renegotiate?" | D2, D3, D4, D5 (Zone + Vendor) | T-ZONE-COST |
| **5. Data Explorer** | All audiences (bulk export) | "Tải toàn bộ raw data để forward / phân tích offline" | D1, D6 | T-MASTER, T-PLANNER |

**Section shell (chung mọi tab):**

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ PSV Accuracy — Độ tin cậy thuật toán VRP                                     │
│ Last refresh: 14:32 UTC+7 (1 hour ago)                                       │
├──────────────────────────────────────────────────────────────────────────────┤
│ [📅 Date: 01/05 - 21/05/2026 ▾]  [👤 Planner: All (5) ▾]                     │
│ [🌏 Zone: All ▾]  [☐ Include test accounts]  [⟳ Refresh]                     │
├──────────────────────────────────────────────────────────────────────────────┤
│ [📊 Overview] [🎯 Reliability] [🚚 Vendor] [💰 Cost] [📋 Data Explorer]      │
├──────────────────────────────────────────────────────────────────────────────┤
│ <tab content render here>                                                    │
└──────────────────────────────────────────────────────────────────────────────┘
```

- Filter bar + tab nav **sticky** top (giữ visible khi scroll trong tab).
- Filter state **shared across tabs** — không reset khi đổi tab.
- Tab default = **Overview** (BOD landing).
- URL deep-link: `?tab=reliability&zone=Z03&planner=P02` để bookmark / share.

---

## 2. Tab 1 — Overview (BOD landing)

**Mục đích:** snapshot ≤ 5 KPI + exception visibility trong 1 viewport (không cần scroll cho BOD).
**Height estimate:** ~1,100px (1 scroll page).

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ L1 — HERO KPIs (120px)                                                       │
│ ┌────────────────────────────┬──────────────────────────────┐                │
│ │ A1 % Accuracy: 68%         │ B1 % Violation Rate: 27%     │                │
│ │ ▲ +3% vs prior 14d         │ ▼ −2% vs prior 14d           │                │
│ │ ▁▂▄▆▇▅▃▂ (spark 14d)       │ ▇▆▅▄▃▂▁▁ (spark 14d)         │                │
│ │ 🟡 Target ≥80% (Q5)        │ 🟡 Target <10% (Q5)          │                │
│ └────────────────────────────┴──────────────────────────────┘                │
├──────────────────────────────────────────────────────────────────────────────┤
│ L2 — DIAGNOSTIC SNAPSHOT (400px)                                             │
│ ┌────────────────────────────┬──────────────────────────────┐                │
│ │ A2 Accuracy by Zone (top 5)│ B2 Violation Rate (top 5)    │                │
│ │ Horizontal bar, RAG color  │ Horizontal bar, gradient     │                │
│ │ "See all zones in Reliab." │ "See all zones in Reliab."   │                │
│ └────────────────────────────┴──────────────────────────────┘                │
├──────────────────────────────────────────────────────────────────────────────┤
│ L3 — TREND SNAPSHOT (280px)                                                  │
│ ┌────────────────────────────┬──────────────────────────────┐                │
│ │ A3 Cost/CBM Drift Trend    │ B4 Daily Violation Trend     │                │
│ │ Line, ±5% band             │ Line, section avg ref        │                │
│ └────────────────────────────┴──────────────────────────────┘                │
├──────────────────────────────────────────────────────────────────────────────┤
│ L4 — PROCESS EFFICIENCY FOOTER (160px)                                       │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ A4 AVG Adj Duration: 14 min/trip · 5 planner active      │                 │
│ │ "View per-planner breakdown in Data Explorer →"          │                 │
│ │ Note: AVG Prep + Final Leadtime → adoption section (v2)  │                 │
│ └──────────────────────────────────────────────────────────┘                 │
└──────────────────────────────────────────────────────────────────────────────┘
```

| Chart | Type | Notes |
|---|---|---|
| A1 % Accuracy | KPI card + sparkline 14d + delta | Action title: "Accuracy [X]% — [trend], [above/below] target [Y]%" |
| B1 % Violation | KPI card + sparkline + delta | Action title: "[X]% chuyến còn vi phạm sau adjust" |
| A2 Accuracy by Zone (top 5) | Horizontal bar, RAG, condensed | Click "See all zones" → switch sang Tab 2 |
| B2 Violation Rate by Zone (top 5) | Horizontal bar gradient | Cùng |
| A3 Cost/CBM Drift Trend | Line + ±5% band | Identical to Tab 2 + 4 trends, light version |
| B4 Daily Violation Trend | Line | Identical |
| A4 Process Efficiency | KPI card duration + planner count | Detail bar per planner → Tab 5 T-PLANNER |

**Exception highlight panel** (nếu có items off-track):
```
┌──────────────────────────────────────────────────────────┐
│ ⚠️  3 exception đáng chú ý                               │
│  • Zone Z03 — Accuracy 45%, low: −23pp vs section avg    │
│  • Constraint "Fishbone" — 89 vi phạm trong 7 ngày qua   │
│  • Vendor V07 — cost spike +18% so với Auto baseline     │
│  [→ View in Reliability tab]  [→ View in Vendor tab]     │
└──────────────────────────────────────────────────────────┘
```

---

## 3. Tab 2 — Reliability (Planning Lead deep-dive A + B)

**Mục đích:** Planning Lead diagnose WHY VRP fail — zone + constraint detail.
**Height estimate:** ~1,800px (long scroll OK cho deep-dive workflow).

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ L1 — ZONE PERFORMANCE (400px)                                                │
│ ┌────────────────────────────┬──────────────────────────────┐                │
│ │ A2 Accuracy by Zone (all)  │ B2 Violation Rate by Zone    │                │
│ │ Horizontal bar, RAG, click │ Horizontal bar gradient red  │                │
│ │ → cascade filter           │ → cascade filter             │                │
│ └────────────────────────────┴──────────────────────────────┘                │
├──────────────────────────────────────────────────────────────────────────────┤
│ L2 — CONSTRAINT PARETO (360px)                                               │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ B3 Violation Count by Category (Pareto top 20 + Others)  │                 │
│ │ Click bar → drill drawer with trip list                  │                 │
│ └──────────────────────────────────────────────────────────┘                 │
├──────────────────────────────────────────────────────────────────────────────┤
│ L3 — DAILY TREND (280px)                                                     │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ B4 Daily Violation Trend (line + section avg ref)        │                 │
│ └──────────────────────────────────────────────────────────┘                 │
├──────────────────────────────────────────────────────────────────────────────┤
│ L4 — RAW TABLE: T-CONSTRAINT (700px, paginated 50 rows)                      │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ [🔍 Search] [⚙ Columns ▾]      Total: 1,247 trips [⤓ CSV/XLSX]│             │
│ │ Tracking ID │ Planner │ Zone │ To Location │ Vendor │ Constraint │ Reason │ Date│
│ │ TRK0001     │ P01     │ Z03  │ Bien Hoa    │ V03    │ Fishbone   │ ...   │ 2026-05│
│ │ ...         │ ...     │ ...  │ ...         │ ...    │ ...        │ ...   │ ...  │
│ │ [< Prev] Page 1/25 [Next >]                                                │
│ └──────────────────────────────────────────────────────────┘                 │
└──────────────────────────────────────────────────────────────────────────────┘
```

| Chart | Type | Position | Notes |
|---|---|---|---|
| A2 Accuracy by Zone | Horizontal bar sorted desc, RAG, target line at 80% | 6/12 cols | Click → cascade filter zone xuống L2, L3, L4 |
| B2 Violation Rate by Zone | Horizontal bar gradient red, ref = section avg | 6/12 cols | Click → cascade filter |
| B3 Violation Count by Category | Pareto vertical bar, top 20 + Others | 12/12 cols | Click bar → drawer trip list |
| B4 Daily Violation Trend | Line + reference, auto-resample weekly nếu range > 90d | 12/12 cols | — |

**Raw table T-CONSTRAINT** (xem §8 Raw Data Tables pattern):
- Columns: `tracking_id`, `planner_name`, `zone`, `location_to_name`, `vendor_name`, `carrier_name`, `constraint_name`, `reason_change`, `total_cost_adjusted`, `created_date`
- Default sort: `created_date DESC`
- Filter: respects section filter (date / planner / zone) + local search box
- Export: CSV + XLSX, button apply current filter state

---

## 4. Tab 3 — Vendor & Carrier (Procurement Lead C series)

**Mục đích:** Procurement Lead xem vendor allocation, swap pattern, cost impact.
**Height estimate:** ~2,000px.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ L1 — VENDOR-LEVEL IMPACT (600px)                                             │
│ ┌────────────────────────────┬──────────────────────────────┐                │
│ │ C2 Vendor Allocation       │ C4 Cost Impact by Vendor     │                │
│ │ Dumbbell (Auto vs Adj)     │ Split: %drift bar + ΔVND bar │                │
│ │ Sort by abs(delta)         │ Sort by abs desc             │                │
│ └────────────────────────────┴──────────────────────────────┘                │
├──────────────────────────────────────────────────────────────────────────────┤
│ L2 — SWAP MATRIX (440px)                                                     │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ C1 Trip Change Matrix (Sankey default · toggle: heatmap) │                 │
│ │ Diagonal (no-change) hidden. Click flow → drawer.        │                 │
│ └──────────────────────────────────────────────────────────┘                 │
├──────────────────────────────────────────────────────────────────────────────┤
│ L3 — ZONE-LEVEL VENDOR DETAIL (440px)                                        │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ C3 Vendor Allocation by Zone (small multiples 4×3 grid)  │                 │
│ └──────────────────────────────────────────────────────────┘                 │
├──────────────────────────────────────────────────────────────────────────────┤
│ L4 — PIVOT HEATMAP (320px)                                                   │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ C5 % Change Vendor × Zone (divergent red-white-green)    │                 │
│ │ Cells n < 5 grey out                                     │                 │
│ └──────────────────────────────────────────────────────────┘                 │
├──────────────────────────────────────────────────────────────────────────────┤
│ L5 — RAW TABLE: T-VENDOR (700px, paginated 50 rows)                          │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ Trip-level vendor swap detail with cost impact           │                 │
│ │ Tracking ID│Zone│Vendor Auto│Vendor Adj│Carrier Auto│Carrier Adj│Cost Auto│Cost Adj│Δ VND│%Drift│Reason│
│ │ [⤓ CSV/XLSX export with current filter]                  │                 │
│ └──────────────────────────────────────────────────────────┘                 │
└──────────────────────────────────────────────────────────────────────────────┘
```

| Chart | Type | Position | Notes |
|---|---|---|---|
| C2 Vendor Allocation | Dumbbell, sort abs(delta) | 6/12 cols | Replace PDF grouped-bar (anti-pattern) |
| C4 Cost Impact by Vendor | 2 split bars: %drift + ΔVND | 6/12 cols | Replace dual-axis |
| C1 Trip Change Matrix | Sankey default / heatmap toggle | 12/12 cols | Click flow → drawer trip list |
| C3 Vendor Alloc by Zone | Small multiples 4×3 grid, 1 mini bar per vendor | 12/12 cols | Replace 17×2 grouped stacked |
| C5 % Change Vendor × Zone | Pivot heatmap, divergent | 12/12 cols | n<5 grey out |

**Raw table T-VENDOR:**
- Columns: `tracking_id`, `zone`, `vendor_auto`, `vendor_adj`, `carrier_auto`, `carrier_adj`, `cost_auto`, `cost_adj`, `cost_delta_vnd`, `pct_drift`, `cbm`, `reason_change`, `created_date`
- Default sort: `cost_delta_vnd DESC` (top overspend first)
- Filter: section filter + vendor multi-select inline
- Export: CSV + XLSX

---

## 5. Tab 4 — Cost Variance (Finance + Planning D series)

**Mục đích:** Finance đo saving/loss + Planning strategic decision (renegotiate / scale).
**Height estimate:** ~1,800px.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ L1 — ZONE COST VARIANCE (400px)                                              │
│ ┌────────────────────────────┬──────────────────────────────┐                │
│ │ D2 Trip Variation/Zone     │ D3 Total Saving/Loss (VND)   │                │
│ │ Diverging bar % (signed)   │ Diverging bar VND            │                │
│ │ Outlier cap ±50% + link    │ Unit: theo Q6                │                │
│ └────────────────────────────┴──────────────────────────────┘                │
├──────────────────────────────────────────────────────────────────────────────┤
│ L2 — COST % DIFF BY ZONE (320px)                                             │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ D4 Cost % Diff by Zone (diverging bar, hide n<10)        │                 │
│ └──────────────────────────────────────────────────────────┘                 │
├──────────────────────────────────────────────────────────────────────────────┤
│ L3 — STRATEGIC 2×2 BUBBLES (400px)                                           │
│ ┌────────────────────────────┬──────────────────────────────┐                │
│ │ D5-Zone Bubble             │ D5-Vendor Bubble             │                │
│ │ X=CBM, Y=CPC, size=trips   │ X=CBM, Y=CPC, size=trips     │                │
│ │ Quadrants: negotiate/scale │ Same                         │                │
│ └────────────────────────────┴──────────────────────────────┘                │
├──────────────────────────────────────────────────────────────────────────────┤
│ L4 — RAW TABLE: T-ZONE-COST (700px, paginated 50 rows)                       │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ Zone │Trips Auto│Trips Adj│Cost Auto│Cost Adj│Δ VND│Δ %│CBM Auto│CBM Adj│CPC Auto│CPC Adj│
│ │ [⤓ CSV/XLSX]                                              │                 │
│ └──────────────────────────────────────────────────────────┘                 │
└──────────────────────────────────────────────────────────────────────────────┘
```

| Chart | Type | Position | Notes |
|---|---|---|---|
| D2 Trip Variation/Zone | Diverging % bar, sorted | 6/12 cols | Outlier cap ±50% + "see details" link → T-ZONE-COST |
| D3 Total Saving/Loss | Diverging VND bar | 6/12 cols | Unit Q6 (VND / k VND / M VND) |
| D4 Cost % Diff by Zone | Diverging % bar | 12/12 cols | Hide cell n<10 |
| D5-Zone Bubble | Scatter X=CBM, Y=CPC, size=trips, median quadrants | 6/12 cols | Label top-left "negotiate", bottom-right "scale" |
| D5-Vendor Bubble | Same | 6/12 cols | — |

**Raw table T-ZONE-COST:**
- Columns: `zone`, `trip_count_auto`, `trip_count_adj`, `total_cost_auto`, `total_cost_adj`, `cost_delta_vnd`, `pct_diff`, `total_cbm_auto`, `total_cbm_adj`, `cpc_auto`, `cpc_adj`, `cpc_drift_pct`
- Default sort: `cost_delta_vnd DESC`
- Export: CSV + XLSX

---

## 6. Tab 5 — Data Explorer (bulk export, all audiences)

**Mục đích:** trip-level master + planner activity bulk download. Phục vụ:
- Procurement forward Excel cho carrier nego
- Finance ghép vào báo cáo monthly
- Planning Lead offline analysis
- Auditor verify số liệu

**Height estimate:** ~2,200px.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ L1 — SUMMARY COMPARISON (180px)                                              │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ D1 Summary: Auto vs Adjusted (2 rows × [trips/CBM/cost/CPC + Δ + Δ%])│      │
│ └──────────────────────────────────────────────────────────┘                 │
├──────────────────────────────────────────────────────────────────────────────┤
│ L2 — METRICS BY PROVINCE/ZONE (500px, sortable, exportable)                  │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ D6 Heatmap table, conditional intensity per column       │                 │
│ │ Auto cols + Adj cols grouped, [⤓ Export]                 │                 │
│ └──────────────────────────────────────────────────────────┘                 │
├──────────────────────────────────────────────────────────────────────────────┤
│ L3 — RAW TABLE: T-MASTER (800px, paginated 50 rows)                          │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ Trip master — ALL dimensions + measures                  │                 │
│ │ [🔍 Search] [⚙ Columns: 18/24 visible ▾] Total: 1,247    │                 │
│ │ Tracking│Date│Planner│Zone│Region│To Loc│Vendor Auto│Vendor Adj│...│       │
│ │ [⤓ Export CSV]  [⤓ Export XLSX]  [⤓ Export filtered only]│                 │
│ └──────────────────────────────────────────────────────────┘                 │
├──────────────────────────────────────────────────────────────────────────────┤
│ L4 — RAW TABLE: T-PLANNER (480px)                                            │
│ ┌──────────────────────────────────────────────────────────┐                 │
│ │ Planner │ Active │ Edits │ AVG Adj (min) │ No Change │ Change │ % Change │ │
│ │ P01     │ ✓      │ 89    │ 12.3          │ 245       │ 89     │ 26.6%    │ │
│ │ ...     │ ...    │ ...   │ ...           │ ...       │ ...    │ ...      │ │
│ │ [⤓ CSV]                                                   │                 │
│ └──────────────────────────────────────────────────────────┘                 │
└──────────────────────────────────────────────────────────────────────────────┘
```

| Asset | Type | Notes |
|---|---|---|
| D1 Summary Comparison | Compact table 2 rows × 6 cols | Replace PDF 4-col + Δ + %diff |
| D6 Summary Metrics by Prov | Heatmap table, conditional intensity per column | Pagination >20 zones; Auto cols + Adj cols grouped |
| **T-MASTER** | Trip-level master table | 24 columns (default 18 visible); search; column toggle; export |
| **T-PLANNER** | Per-planner activity | Drill A4 of Tab 1 |

**T-MASTER columns (24 total):**

| Group | Columns |
|---|---|
| Identity | `tracking_id`, `created_date`, `planner_name`, `status_name_detail` |
| Location | `zone`, `region`, `location_from_name`, `location_to_name` |
| Vendor / Carrier | `vendor_auto`, `vendor_adj`, `carrier_auto`, `carrier_adj` |
| Trip count | `trip_count_auto`, `trip_count_adj` |
| Cost | `total_cost_auto`, `total_cost_adj`, `cost_delta_vnd`, `pct_drift` |
| CBM | `total_cbm`, `cpc_auto`, `cpc_adj` |
| Violation | `constraint_violations_count`, `constraint_names_list` |
| Reason | `reason_change` |

Default visible cols (18): drop `location_from_name`, `carrier_auto/adj`, `constraint_names_list`, `cpc_auto/adj` — user toggle bật khi cần.

**T-PLANNER columns:**

| Columns |
|---|
| `planner_name`, `is_active`, `edits_count`, `avg_adj_duration_min`, `no_change_count`, `change_count`, `pct_change`, `first_seen`, `last_seen` |

---

## 7. Raw Data Tables — UX Pattern (chung cho T-CONSTRAINT, T-VENDOR, T-ZONE-COST, T-MASTER, T-PLANNER)

Mọi raw table phải hỗ trợ:

| Feature | Detail |
|---|---|
| **Sticky header** | Khi scroll trong table, header luôn visible |
| **Sortable** | Click column header → toggle asc/desc, multi-column shift+click |
| **Pagination** | 50 rows/page default; user toggle 25/50/100/200 |
| **Search inline** | Free-text search across all visible text columns |
| **Column toggle** | Dropdown "Columns" show/hide individual columns; preference persist localStorage |
| **Column resize** | Drag column edge to resize |
| **Density toggle** | Compact / Comfortable (row height) |
| **Filter respect** | Section filter (date/planner/zone) **always apply** to table query |
| **Export CSV** | Download current view (all matching rows, not just current page) |
| **Export XLSX** | Same; preserve number/date formatting + column headers in Vietnamese |
| **Export filtered only** | Toggle: export entire table data vs only filter-matched rows |
| **Total row count** | Visible at top: "Total: 1,247 trips · 285 matching filter" |
| **Empty state** | "No trips match current filter. Try widening date range or clear zone filter." |
| **Loading skeleton** | Shimmer rows trong 200ms; spinner sau 200ms |
| **n-low warning** | Inline icon ⚠️ trên row có sample n<10 nếu là aggregated table (T-ZONE-COST) |

**Performance:** server-side pagination cho T-MASTER (toàn bộ trips trong period có thể > 10k rows); client-side OK cho T-CONSTRAINT, T-VENDOR, T-ZONE-COST, T-PLANNER (expected < 2k rows).

**Export size limit:** XLSX cap 50k rows; CSV cap 200k rows. Beyond → caption "Result exceeds export limit, please narrow date filter or contact support."

---

## 8. Interactions

### 8.1 Filter cascade rules

| Source | Target | Behavior |
|---|---|---|
| Section filter bar (Date / Planner / Zone) | Mọi chart **và mọi raw table** trong mọi tab | Update toàn bộ; filter persist khi chuyển tab |
| Click bar A2/B2 (Tab 2) — zone | Cascade local trong Tab 2 (B3, B4, T-CONSTRAINT) | Pill "Filter by zone X" above sub-section, click pill clear |
| Click bar C2 (Tab 3) — vendor | Cascade local trong Tab 3 (C1, C3, C5, T-VENDOR) | Pill "Filter by vendor X" |
| Click bubble D5-zone (Tab 4) | Highlight zone trong D2/D3/D4 + scroll T-ZONE-COST tới zone row | — |
| Cross-tab cascade | KHÔNG cascade auto across tabs | Vì user có thể đang debug 1 dimension cụ thể, không muốn lan |
| Filter persist | localStorage key `panasonic.psv-accuracy-vrp.filter` | Persist date + planner + zone selection + active tab |

### 8.2 Drill-down rules

| Source | Action | Target |
|---|---|---|
| Click B3 bar (Tab 2 constraint) | Right drawer | Pre-filter T-CONSTRAINT theo constraint đó → highlight rows |
| Click C1 Sankey flow (Tab 3) | Right drawer | Pre-filter T-VENDOR theo `vendor_auto = old` AND `vendor_adj = new` |
| Click D6 zone row (Tab 5) | Right drawer | Filter T-MASTER theo zone đó |
| Click A1/B1 hero (Tab 1) | Switch tab + scroll | Switch sang Tab 2, scroll tới A2/B2 |
| Click exception alert (Tab 1) | Switch tab | Switch sang Tab 2/3/4 phù hợp + apply pre-filter |
| Click A4 footer "View per-planner" (Tab 1) | Switch tab | Tab 5, scroll T-PLANNER |

### 8.3 Tooltip patterns

Mọi chart cần tooltip với 4 thành phần (giữ từ v1):
1. **Dimension label** (zone / vendor / category).
2. **Primary measure** với unit explicit ("CBM: 5,712 m³", "Cost/CBM: 90,336 VND/m³", "Trip count: 223").
3. **Comparison context** (vs target / vs prior period / vs Auto baseline).
4. **Sample size warning** nếu n < 10 ("⚠️ Low sample, n=7").

Tooltip cho raw table cell: hover dài hàng (text wrap) → tooltip hiển thị full text + row link để open trip detail (sau v1).

### 8.4 Action title rule (giữ từ v1)

KHÔNG dùng tiêu đề chỉ là tên KPI. Mỗi chart phải có action title nói **insight**:

| Chart | Static label (❌) | Action title template (✅) |
|---|---|---|
| A1 | "% Accuracy" | "Accuracy [X]% — [trend], target [Y]%" |
| A2 | "Accuracy by Zone" | "[Zone-low] kéo Accuracy xuống thấp nhất [X]%" |
| A3 | "Cost per CBM Trend" | "Adjust làm Cost/CBM tăng trung bình [X]% trong [period]" |
| B1 | "Violation Rate" | "[X]% chuyến vẫn vi phạm — Top 3: [A, B, C]" |
| B2 | "Violation by Zone" | "[Zone] vi phạm cao nhất [Y]% — do [top constraint]" |
| B3 | "Violation by Category" | "Top 3 constraint: [A] [B] [C] chiếm [X]%" |
| C4 | "Cost Impact by Vendor" | "[Vendor X] đắt hơn baseline [Y]%" |
| D3 | "Total Saving/Loss" | "Zone [X] tiết kiệm [Y] VND; Zone [Z] lỗ [W] VND" |

### 8.5 Tab navigation behavior

| Behavior | Detail |
|---|---|
| Default tab | Overview |
| Tab persistence | localStorage `panasonic.psv-accuracy-vrp.activeTab` |
| Keyboard shortcut | `1`-`5` digit keys (focus trong section) → switch tab |
| URL deep-link | `?tab=reliability&zone=Z03&planner=P02&from=2026-05-01&to=2026-05-21` |
| Browser back/forward | Tab switch update URL history (push state) |
| Loading state per tab | Mỗi tab load riêng — switch tab không reload toàn bộ section |

---

## 9. Empty States

| Asset | Condition | Display | Color |
|---|---|---|---|
| A1, B1 | `total_trips = 0` | Big `—` + caption "No Autoplan runs in selected period." | Grey |
| A1 | `total_trips > 0` AND `pct = 100%` | "100%" + caption "All trips kept untouched — verify edge case" | Green w/ warning |
| A2, B2 | All zones `n < 10` | Empty chart + "Low sample. Widen filter." | Grey |
| A3 | All days `cpc_auto = 0` | "No Auto baseline — see Open Q1." | Yellow info |
| A3 | < 5 days with values | Show available + "Sparse data" caption | Yellow |
| A4 | `edited_trips = 0` per planner | Bar height = 0 + "No edits in period" | Grey |
| B3 | `constraint_name = ''` for all | "🎉 No constraint violations." | Green |
| B4 | All days `violation = 0` | Flat line at 0 + "🎉 No violations" | Green |
| C1-C5, D1-D6 | Auto baseline not available | Banner "Pending data — see Open Q1" + chart greyed | Grey |
| D5-zone | Zone master not available | Banner "Pending zone master — see Open Q2" | Grey |
| D5-vendor | `total_cbm = 0` all vendors | "No CBM data" | Grey |
| **Raw table any** | 0 rows match filter | "No records match current filter. [Clear filter]" | Grey |
| **Raw table any** | Query timeout (>30s) | "Query took too long — narrow filter or contact support" | Red |
| **T-MASTER export** | Result > 200k rows | Block export + "Result exceeds 200k rows — narrow filter" | Red |
| Tab 1 exception panel | 0 exceptions trigger | Replace với "✅ All clear — no exception" | Green |

---

## 10. Responsive & Accessibility

| Requirement | Detail |
|---|---|
| Min viewport | 1024px — KHÔNG support tablet/mobile portrait (NFR-7) |
| Breakpoint 1024–1440 | Tab nav vẫn horizontal; chart grid stack vertical (1 chart per row trong tab) |
| Breakpoint > 1440 | Multi-col grid như §2-§6 |
| Tab nav < 1024 | Fallback: dropdown selector (giữ NFR-7 desktop-only) |
| Color contrast | RAG WCAG AA (4.5:1) |
| Color-blind | RAG state có icon supplement (✓ / ⚠ / ✗) — không chỉ màu |
| Loading state | Skeleton placeholder 200ms; spinner sau 200ms |
| Error state | Inline banner per widget, KHÔNG full-page error |
| Raw table keyboard nav | Arrow keys move cell focus; Enter open drill drawer; Esc close drawer |

---

## 11. RTL / i18n

Section default tiếng Việt (Panasonic VN team chính). Tab labels:

| i18n key | VI | EN |
|---|---|---|
| `psv-accuracy-vrp.tab.overview` | "Tổng quan" | "Overview" |
| `psv-accuracy-vrp.tab.reliability` | "Độ tin cậy" | "Reliability" |
| `psv-accuracy-vrp.tab.vendor` | "Nhà thầu / Vendor" | "Vendor & Carrier" |
| `psv-accuracy-vrp.tab.cost` | "Chênh lệch chi phí" | "Cost Variance" |
| `psv-accuracy-vrp.tab.data` | "Dữ liệu chi tiết" | "Data Explorer" |
| `psv-accuracy-vrp.section.title` | "PSV Accuracy — Độ tin cậy thuật toán VRP" | "PSV Accuracy — VRP Auto-Planning Reliability" |
| `psv-accuracy-vrp.table.export_csv` | "Tải CSV" | "Export CSV" |
| `psv-accuracy-vrp.table.export_xlsx` | "Tải Excel" | "Export XLSX" |
| `psv-accuracy-vrp.table.search` | "Tìm kiếm…" | "Search…" |
| `psv-accuracy-vrp.table.columns` | "Cột" | "Columns" |
| `psv-accuracy-vrp.table.total_rows` | "Tổng: {n} chuyến" | "Total: {n} trips" |

LTR layout (Vietnamese đọc trái-phải). KHÔNG apply RTL pattern Shadcn.

---

## 12. UX Decisions (resolved 2026-05-21)

8 open UX decisions ở draft 2026-05-19 đã được BA chốt với reasonable default. Mỗi quyết định kèm rationale + condition để re-open sau monthly review nếu Panasonic stakeholder push back.

| # | Decision | Default v1 | Rationale | Re-open trigger |
|---|---|---|---|---|
| D1 | Default tab khi vào section | **Overview** cho mọi user | Audience landing common — BOD + Planning Lead đều cần snapshot trước khi deep-dive. Role-based smart-default cần RBAC role mapping chính thức → defer v2. | Sau khi RBAC role table có entry cho Panasonic → v2 cân nhắc smart-default. |
| D2 | C1 Trip Change Matrix — default view | **Sankey** default + toggle "View as heatmap" top-right | Audience C1 = Procurement Lead → câu hỏi "Planner swap who→whom" là flow narrative → Sankey. Khi cần exact count cho audit, switch sang heatmap. | Procurement Lead báo Sankey rối với > 8 vendor → switch default sang heatmap. |
| D3 | D6 Summary by Prov — sort default | `cost_delta_vnd DESC` (primary), `zone ASC` (secondary) | Finance + Procurement audit focus: lỗ lớn nhất lên đầu để action trước. | Nếu Planning Lead muốn diagnose zone-by-zone alphabetical → cho phép user override (sortable column). |
| D4 | T-MASTER default columns (18/24 visible) | **Hidden by default**: `location_from_name`, `carrier_auto`, `carrier_adj`, `constraint_names_list`, `cpc_auto`, `cpc_adj` | `location_from` = always nhà máy Panasonic (low variance); `carrier_*` derived từ `vendor_*`; `constraint_names_list` text dài làm row cao; `cpc_*` derivable từ cost + cbm. User toggle bật khi cần. | Procurement báo cần `carrier_*` visible default → unhide. |
| D5 | Inline help (ⓘ) per chart | **Yes** v1, content từ `glossary.md` | Panasonic Q7 đã flag "% Accuracy counter-intuitive" → cần educate. Inline help giảm support load. Disable per chart **chỉ khi** chart self-explanatory (KHÔNG được disable cho A1, B1 — 2 hero KPI counter-intuitive nhất). | Sau 2 tháng go-live, telemetry tooltip-open-rate < 5% chart nào → drop tooltip chart đó. |
| D6 | Exception panel logic Tab 1 | Trigger nếu BẤT KỲ điều kiện sau true: <br>• Top 3 zone với `pct_accuracy < 60%` (Red ở A2, skip zone n<10) <br>• Top 3 constraint từ B3 Pareto (`record_count DESC`) <br>• Top 3 vendor có `pct_drift > 15%` (Adj cost > Auto cost) <br>Hiển thị max 9 items; collapse "Show all 12 exceptions →" nếu > 9. | Threshold 60% / 15% bám Q5 default RAG; có thể tune sau khi Panasonic confirm Q5. | Sau 4 tuần go-live: nếu exception panel trống ≥ 50% session → relax threshold; nếu > 9 items thường xuyên → tighten. |
| D7 | Tab 1 vs Tab 2 cutoff (A2/B2 condensed) | **Top 5 zone** Tab 1, **all zones** Tab 2 | Top 5 phù hợp 1-viewport snapshot cho BOD (Industry standard "top N" pattern). Mọi exception cần action → đã có ở exception panel D6. | Nếu Panasonic > 30 zones (hiện ~17), nâng lên top 7 hoặc top 10. |
| D8 | Export filename pattern | `psv-accuracy-vrp__{tab}__{date_from}_{date_to}__{zone}.csv` <br>Examples: <br>• `psv-accuracy-vrp__reliability__2026-05-01_2026-05-21__ALL.csv` <br>• `psv-accuracy-vrp__cost__2026-04-01_2026-04-30__Z03.xlsx` | Self-describing: tenant + section + tab + period + zone. Compatible với Windows / macOS filesystem (double underscore separator, no special chars). Date ISO 8601 cho sort. | Procurement báo filename quá dài (> 100 chars) → shorten tab name (`reliab` thay `reliability`). |

**Classification** (per /ba evidence workflow):

- **Decision** (8/8): D1, D2, D3, D4, D5, D6, D7, D8 — all closed for v1 launch.
- **Open Question** (0): không còn block ship gate UX.
- **Assumption to verify** (0): các Re-open trigger là post-launch monitoring, KHÔNG block go-live.

---

## 13. References

- **PRD:** [psv-accuracy-vrp-prd.md](psv-accuracy-vrp-prd.md) — scope, audience, acceptance criteria, open questions.
- **Spec:** [psv-accuracy-vrp-spec.md](psv-accuracy-vrp-spec.md) — data contract, SQL canonical patterns, GAP fallback map.
- **Storytelling analysis:** [analysis/storytelling-notes.md](analysis/storytelling-notes.md) — full critique per chart từ demo PDF.
- **Source artifact:** [PSV-auto-demo.pdf](../../05-reference/PSV-auto-demo.pdf) — bộ chart mẫu đã thống nhất với Panasonic.

---

## 14. Changelog

| Date | Change |
|---|---|
| 2026-05-19 | DRAFT v1 — 19 charts, 9 levels long scroll (~3,200px) |
| 2026-05-21 | **REVISED** — refactor sang 5 tabs theo audience (Overview / Reliability / Vendor / Cost / Data Explorer); thêm 5 raw data tables exportable (T-CONSTRAINT, T-VENDOR, T-ZONE-COST, T-MASTER, T-PLANNER); thêm Tab 1 exception panel; thêm filter cascade local-per-tab; thêm URL deep-link; thêm i18n keys tab + table |
| 2026-05-21 | **UX DECISIONS RESOLVED** — chốt 8 open UX decisions §12 (default tab Overview, C1 Sankey, D6 sort cost_delta_vnd, T-MASTER 18 default cols, inline help Yes, exception threshold 60%/15%, Tab 1 top 5 zone, export filename pattern); 0 còn lại block ship gate UX |
