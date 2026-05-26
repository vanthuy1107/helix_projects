# Roadmap Recommendations — Smartlog Control Tower PO Sweep

**Mode**: C (Full sweep — Recommendations section) · **Scan baseline**: `41b3863` (2026-05-22)
**Author**: `/da-po sweep` (squad1@gosmartlog.com)
**Branch**: `feat-vfr-late-alert`
**Source**: [`benchmark/2026-05-26-gap-analysis.md`](../benchmark/2026-05-26-gap-analysis.md) — 26 gaps total, 16 actionable (10 CATCH-UP + 6 LEAPFROG)
**Scope**: Only CATCH-UP and LEAPFROG verdicts. KEEP and IGNORE are documented in gap analysis, not repeated here.

---

## How to read this file

Each item below is a candidate roadmap initiative. The next step is **NOT** to spawn `/ba` directly — every item handoff routes through `/da-discovery` (memory: anti-pattern of jumping `/da-po` → `/ba`). `/da-discovery` then frames the problem (5 reframe questions) before PRD work begins.

**Sort order**: `relevance_to_logistics` (High first), then verdict (LEAPFROG before CATCH-UP since LEAPFROG defends moat), then `gap_id`.

**Effort tag** (rough order-of-magnitude only — formal estimation belongs to `/planner` after PRD):
- **S** = single sprint (1-2 weeks dev)
- **M** = multi-sprint (3-6 weeks)
- **L** = quarter-sized (8-12 weeks)
- **XL** = multi-quarter

---

## 1. Executive summary

**16 items routed for `/da-discovery`** across 4 strategic clusters:

| Cluster | Items | Strategic intent |
|---|---|---|
| **A. Embedded ISV hardening** | GAP-001, GAP-002, GAP-003, GAP-005 | Match the embedded BI category bar (Sisense Compose SDK + Looker signed-URL + RLS policy + server-side PDF) — Smartlog *positions* as embedded but SDK depth lags |
| **B. AI moat polish + monetization** | GAP-004, GAP-011, GAP-012, GAP-013, GAP-015 | Take 9 Beta AI features to GA, productize the eval harness + multi-LLM + error-graph as customer-facing surfaces, market as "the BI you can verify" |
| **C. Vertical IP marketplace** | GAP-014, GAP-016 | Golden SQL + KPI templates with industry benchmark = logistics-specific marketable artifacts; turn into per-tenant marketplace |
| **D. Collaboration + analytical depth** | GAP-006, GAP-007, GAP-008, GAP-009, GAP-010 | Tactical CATCH-UP for drill-through, comments, anomaly, lineage, mobile layout — low-strategic-risk but improves day-to-day UX |

The 4 clusters are **independently routeable** — clusters A and B are highest-leverage (positioning) and should be sequenced first; cluster C is medium-leverage but uses existing entities (low-cost productization); cluster D is opportunistic.

---

## 2. Recommendations table (sorted by relevance + verdict)

| Rank | gap_id | Cluster | Capability | Summary | Verdict | Effort | Dependency |
|---:|---|---|---|---|---|---|---|
| **1** | GAP-013 | B | #12 AI/ML | **Multi-LLM tenant cost-control** — productize as ISV value prop vs single-LLM-lock-in vendors | LEAPFROG | M | Existing `LlmProvidersController` + `LlmBudgetConfig`; needs GTM story |
| **2** | GAP-012 | B | #12 AI/ML | **Customer-facing eval harness** — expose model trust scores per tenant ("the only BI you can verify") | LEAPFROG | M | Existing `EvaluationRun` entities; needs UX layer |
| **3** | GAP-011 | B | #7 Authoring | **Notebook + tool-trace-replay polish** — push Beta → GA; market as integrated BI + analyst notebook + AI explainability triad | LEAPFROG | L | Notebook entities exist; needs polish + GA SLA |
| **4** | GAP-001 | A | #8 Embedding | **Component-level embed SDK** — match Sisense Compose SDK / Tableau Embedding API v3 (React/Vue/Angular components) | CATCH-UP H | L | Greenfield; depends on share-resource model evolution |
| **5** | GAP-002 | A | #8 Embedding | **Signed-URL embedding with user-attribute pass-through** — Looker pattern, mature ISV embedding | CATCH-UP H | M | `DashboardShare` + JWT claim foundation exists |
| **6** | GAP-003 | A | #8 Embedding | **Declarative RLS policy file** for iframe embed — auditable security for ISV procurement review | CATCH-UP H | M | Closely coupled to GAP-001/002; likely one initiative |
| **7** | GAP-004 | B | #12 AI/ML | **AI Beta → GA push** for 9 features (chat, notebooks, eval, error-graph, user-memory, etc.) — SLA + quality bar + customer-facing changelog | CATCH-UP H | XL | Cross-feature; needs SLA + ops investment |
| **8** | GAP-015 | B | #12 AI/ML | **Error-graph as root-cause AI** — productize ErrorNode/Relation/FixPattern graph as "when X drops, here are 3 likely causes" | LEAPFROG | M | Schema exists; needs UX + integration with `analysis-runs` |
| **9** | GAP-014 | C | #3 Query | **Customer-extensible Golden SQL library** — per-tenant NL↔SQL training corpus; loop into eval harness | LEAPFROG | M | Schema exists; sequence after GAP-012 |
| **10** | GAP-016 | C | #7 Authoring | **KPI Templates marketplace** — productize industry benchmark + required-column + drilldown bundle; tenants subscribe to logistics-specific templates | LEAPFROG | L | 11 entities already shipped; needs marketplace UX + benchmark sourcing strategy |
| **11** | GAP-005 | A | #8 Embedding | **Server-side pixel-perfect PDF export** — for monthly/quarterly executive reports (SC Manager / BOD audience) | CATCH-UP M | M | Playwright/Chromium headless renderer; sequence after cluster A core |
| **12** | GAP-006 | D | #5 Dashboard | **Drill-through framework formalization** — cross-widget / cross-dashboard navigation with parameter pass | CATCH-UP M | M | Existing widget-level drills (Order Monitor row drill); formalize as config-driven |
| **13** | GAP-007 | D | #9 Collaboration | **Comments per widget + @-mention** — thin layer on `MessageFeedback` entity; integrates with existing Slack channel | CATCH-UP M | S | Verify customer signal before scoping |
| **14** | GAP-008 | D | #12 AI/ML | **Customer-facing anomaly + forecast** — 1-click on existing widget metrics (Flash Daily, VFR rolling 14d already trend-imply) | CATCH-UP M | M | Existing `AnalysisRun` foundation; needs UX layer + integration with widget settings |
| **15** | GAP-009 | D | #10 Governance | **Field-level data lineage UI** — semantic-registry has relationships, surface as lineage graph | CATCH-UP M | M | Semantic-registry growth-track; closely tied to `sql-registry.md` per-tenant docs |
| **16** | GAP-010 | D | #13 Mobile | **Mobile-optimized dashboard layout designer** — explicit mobile layout authoring beyond Tailwind breakpoints | CATCH-UP L | M | Defer pending Mondelez / Panasonic mobile usage signal (pair with `/da-ops` pulse review) |

---

## 3. Sequencing proposal (informal — `/planner` will refine)

```
Q3 2026 (Jul-Sep)            Q4 2026 (Oct-Dec)               Q1 2027 (Jan-Mar)
──────────────────────────  ──────────────────────────────  ──────────────────────────
Cluster A — Embedded ISV    Cluster A continues             Cluster C — Vertical IP
  ├ GAP-001 SDK design        ├ GAP-005 server PDF            ├ GAP-014 Golden SQL prod
  ├ GAP-002 signed URL        └ Cluster D — Tactical          └ GAP-016 KPI marketplace
  └ GAP-003 RLS policy          ├ GAP-006 drill-through
                                ├ GAP-007 comments          Cluster B finishes
Cluster B — AI moat start     └ GAP-008 anomaly/forecast      ├ GAP-004 GA SLA finalize
  ├ GAP-013 multi-LLM GTM                                     └ GAP-015 error-graph prod
  ├ GAP-012 eval harness    Cluster B continues
  └ GAP-011 notebook GA       ├ GAP-004 GA push start       Cluster D wrap
                              └ GAP-015 error-graph UX        ├ GAP-009 lineage
                                                              └ GAP-010 mobile (signal-gated)
```

This sequence is a **suggestion** — `/planner` will validate against actual capacity, dev squad availability, and tenant commitment (Mondelez / Panasonic / pipeline).

---

## 4. Per-cluster handoff briefs

### Cluster A — Embedded ISV hardening (GAP-001, GAP-002, GAP-003, GAP-005)

**Strategic framing for `/da-discovery`**: Smartlog positions as embedded ISV BI but SDK depth lags Sisense Compose SDK + Looker signed-URL. This is identity-defining — if our positioning is "embedded" but our embedding contract is iframe-only, we lose RFPs against vendors whose entire product is embedding.

**Questions to filter (`/da-discovery` 5-question reframe)**:
1. Which ISV customer signal triggered this? (Internal observation, or specific Mondelez / Panasonic / pipeline tenant ask?)
2. What is the contract surface? (Component SDK vs signed URL vs hybrid)
3. Who is the buyer? (Tenant IT, tenant procurement, Smartlog sales?)
4. What is the success metric? (RFP win rate, tenant integration time, ISV embedding cost)
5. What does "good enough" look like? (Match Sisense Compose, or innovate beyond?)

**Suggested handoff sequence**: GAP-001 + GAP-002 + GAP-003 as **one initiative** ("embedded BI hardening"); GAP-005 separately after cluster A core.

---

### Cluster B — AI moat polish + monetization (GAP-004, GAP-011, GAP-012, GAP-013, GAP-015)

**Strategic framing for `/da-discovery`**: Smartlog has architectural AI/ML breadth (11 features in #12) that vendor copilots (PowerBI / Tableau Pulse / Looker Gemini) don't have, but the surfaces are Beta and not customer-facing. Polish + productization could establish "the BI you can verify" positioning.

**Questions to filter**:
1. Which AI features go GA first? (Chat pipeline + notebook + eval harness are top-3 candidates)
2. What SLA + quality bar defines "GA" for AI? (Latency p95, hallucination rate, eval pass rate)
3. How does multi-LLM positioning play with enterprise procurement? (Azure OpenAI lock-in vs Anthropic vs Voyage vs on-prem)
4. Does customer-facing eval harness create trust or noise? (Test with Mondelez Flash Daily / VFR cases)
5. Which features stay Beta vs deprecate? (`/da-discovery` should pressure-test scope)

**Suggested handoff sequence**: GAP-013 (multi-LLM GTM) → GAP-012 (eval harness) → GAP-011 (notebook GA) → GAP-004 (full AI GA push) → GAP-015 (error-graph prod).

---

### Cluster C — Vertical IP marketplace (GAP-014, GAP-016)

**Strategic framing for `/da-discovery`**: Golden SQL + KPI Templates with industry benchmark are vertical-logistics IP that competitors don't have. Productizing as marketplace (per-tenant subscribable templates + golden-SQL corpus) compounds vertical moat.

**Questions to filter**:
1. Is the marketplace per-tenant private (Mondelez owns Mondelez SQL) or cross-tenant shared (curated by Smartlog)?
2. How is industry benchmark sourced? (Mondelez baseline, public NSO data, vendor benchmark licensing?)
3. What's the monetization model? (Bundled with tenant contract vs add-on?)
4. Who curates? (Smartlog DA team, tenant DA, third-party logistics analyst?)
5. Does the marketplace surface accelerate new-tenant onboarding? (Panasonic PSV → "clone Mondelez VFR template" workflow)

**Suggested handoff sequence**: GAP-014 (Golden SQL prod after GAP-012 eval harness) → GAP-016 (KPI marketplace).

---

### Cluster D — Tactical CATCH-UP (GAP-006, GAP-007, GAP-008, GAP-009, GAP-010)

**Strategic framing for `/da-discovery`**: These are day-to-day UX gaps where competitors have polished features. None is identity-defining; all are opportunistic.

**Per-item questions**:
- **GAP-006 drill-through**: which exact tenant scenario benefits? (Mondelez VFR row → trip detail, Flash Daily exception → SKU detail?)
- **GAP-007 comments**: do tenant users want widget-comment or do they already use Slack threads? Verify via `/da-ops` pulse.
- **GAP-008 anomaly/forecast**: which metric is highest-leverage? (Flash Daily target, VFR rolling 14d, OTIF monthly?)
- **GAP-009 lineage**: who is the audience? (DA debugging, PM reading widget, BA verifying spec?)
- **GAP-010 mobile**: real customer signal yet? Pair with `/da-ops` pulse on mobile traffic.

**Suggested handoff sequence**: Pre-filter each item via `/da-discovery` to verify customer signal before committing PRD effort.

---

## 5. Items NOT recommended (IGNORE — for transparency)

These are documented in [gap analysis](../benchmark/2026-05-26-gap-analysis.md) §3 but explicitly NOT routed for `/da-discovery`:

| gap_id | What | Why we skip |
|---|---|---|
| GAP-021 | Connector breadth (3 vs 200) | Logistics tenant needs deep on 3 providers, not 200 |
| GAP-022 | Custom viz SDK / marketplace | Domain widgets are moat; chart-library breadth dilutes |
| GAP-023 | Generic chart-type breadth | `chart-auto-detect` Beta gives generic-chart muscle incidentally |
| GAP-024 | Story points / device layouts | Widget-level storytelling (Flash Daily 6 levels, VFR v2) already achieves narrative |
| GAP-025 | Aggregation table fallback | ClickHouse MV is functional equivalent |
| GAP-026 | Native iOS/Android app | Control-tower is desktop-first; Slack-pushed screenshots cover field-mobile |

Schedule **6-month review** for all 6 IGNORE items: 2026-11-26 (`/da-po sweep` re-run). Surface if customer signal changes.

---

## 6. Closing notes

- This file is the **roadmap-input artifact** — NOT a final roadmap. It feeds `/da-discovery`, which feeds `/ba` (PRD), which feeds `/planner` (tech plan).
- `projects/` is repo `helix_projects` (gitignored from main) — commit via `/da-projects` (memory `project_projects_repo_isolated`).
- `/da-po` does not assign owners or dates — that is `/da-pm` scope.
- Anti-pattern check: do NOT jump from this file directly to `/ba`. Always route through `/da-discovery` first (memory: skill anti-pattern table).

---

## 7. Suggested next actions

1. **Tenant signal verification** — run `/da-ops` pulse on each CATCH-UP cluster D item (GAP-006, GAP-007, GAP-008, GAP-009, GAP-010) before committing PRD effort.
2. **Cluster A handoff** — open `/da-discovery` session for GAP-001/002/003 as one initiative ("Embedded BI hardening"). High leverage, identity-defining.
3. **Cluster B sequencing** — open `/da-discovery` session for GAP-013 (multi-LLM GTM) first — GTM positioning question, not engineering question.
4. **Cluster C exploration** — `/da-discovery` for GAP-014 + GAP-016 after Cluster B core. Likely needs partner conversation (industry benchmark sourcing).
5. **Mode D scheduling** — recommend `/da-po delta` weekly on Mondays (cron candidate); next manual run **2026-06-02**.
