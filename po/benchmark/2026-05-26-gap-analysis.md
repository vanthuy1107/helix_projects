# Gap Analysis — Smartlog Control Tower vs 7 BI Vendors

**Mode**: C (Full sweep — Gap Analysis section) · **Scan baseline**: `41b3863` (2026-05-22)
**Author**: `/da-po sweep` (squad1@gosmartlog.com)
**Branch**: `feat-vfr-late-alert`
**Inventory source**: [`projects/po/inventory/2026-05-26-feature-catalog.md`](../inventory/2026-05-26-feature-catalog.md)
**Benchmark source**: [`projects/po/benchmark/2026-05-26-bi-capability-matrix.md`](2026-05-26-bi-capability-matrix.md)
**Competitor baselines**: [`projects/po/_competitors/`](../_competitors/)

---

## How to read this file

Each gap is one row in the table below (and one detail block in section 3). Schema:

| Field | Definition |
|---|---|
| `gap_id` | `GAP-NNN` stable identifier across runs |
| `capability` | one of 14 areas (taxonomy) |
| `gap_summary` | one sentence: what we lack OR what's our unique edge |
| `evidence` | URL / code path proving the comparison |
| `relevance_to_logistics` | High / Medium / Low — lens: "does Smartlog tenant logistics workflow need this?" |
| `verdict` | KEEP \| CATCH-UP \| LEAPFROG \| IGNORE |
| `verdict_rationale` | one sentence |
| `handoff_to` | `/da-discovery` for CATCH-UP / LEAPFROG; null for KEEP / IGNORE |

**Verdict framework** (no "TBD"):

| Verdict | Means |
|---|---|
| **KEEP** | We match or lead — no action |
| **CATCH-UP** | Competitor has, we lack, our users need it |
| **LEAPFROG** | We have something competitors mostly don't — double down |
| **IGNORE** | Competitor has, but doesn't fit our positioning — review 6 months |

---

## 1. TL;DR — verdict breakdown

**26 gaps surfaced** across 13 capability areas (area #14 Pricing is N/A — Smartlog is internal product):

| Verdict | Count | gap_ids |
|---|---:|---|
| **CATCH-UP — High priority** | 4 | GAP-001, GAP-002, GAP-003, GAP-004 |
| **CATCH-UP — Medium priority** | 5 | GAP-005, GAP-006, GAP-007, GAP-008, GAP-009 |
| **CATCH-UP — Low priority** | 1 | GAP-010 |
| **LEAPFROG** | 6 | GAP-011, GAP-012, GAP-013, GAP-014, GAP-015, GAP-016 |
| **KEEP** | 4 | GAP-017, GAP-018, GAP-019, GAP-020 |
| **IGNORE** | 6 | GAP-021, GAP-022, GAP-023, GAP-024, GAP-025, GAP-026 |

**Handoff queue to `/da-discovery`** — 16 items (10 CATCH-UP + 6 LEAPFROG). Sorted-and-batched recommendations are in [`roadmap-input/2026-05-26-recommendations.md`](../roadmap-input/2026-05-26-recommendations.md).

**Strategic posture**:
- Smartlog's positioning is **vertical logistics + AI-native embedded BI**. The 4 HIGH-priority CATCH-UP items + 6 LEAPFROG items all reinforce that posture; the 6 IGNORE items would dilute it (chase generic-BI breadth instead of vertical depth).
- The most urgent CATCH-UP cluster is **embedding maturity (GAP-001/002/003)** — Smartlog is positioned as embedded ISV but the SDK depth doesn't match Sisense Compose SDK / Looker signed-URL today.
- The deepest LEAPFROG opportunity is **AI/ML transparency + customer-extensible AI corpus (GAP-012/014/015)** — Smartlog already has the entities (`EvaluationRun`, `GoldenSql`, `ErrorNode`), they just aren't yet customer-facing surfaces.

---

## 2. Gap summary table

| gap_id | Capability | Gap summary | Relevance | Verdict | Handoff |
|---|---|---|---|---|---|
| **GAP-001** | #8 Embedding | No component-level embed SDK (React/Angular/Vue components) — competitors have Compose SDK / Embedding API v3 | High | **CATCH-UP — High** | `/da-discovery` |
| **GAP-002** | #8 Embedding | No signed-URL embedding with user-attribute pass-through — Looker pattern, mature ISV embedding | High | **CATCH-UP — High** | `/da-discovery` |
| **GAP-003** | #8 Embedding | Iframe embed lacks policy-driven RLS pass-through — tenant DB isolation exists but iframe→tenant claim flow is implicit, not declarative | High | **CATCH-UP — High** | `/da-discovery` |
| **GAP-004** | #12 AI/ML | 9 of 11 AI/ML features still Beta — chat pipeline, notebooks, eval harness, error-graph, user-memory not yet GA | High | **CATCH-UP — High** | `/da-discovery` |
| **GAP-005** | #8 Embedding | Export PDF is client-side (jspdf + html2canvas) — no server-side pixel-perfect render for enterprise reporting | Medium | **CATCH-UP — Medium** | `/da-discovery` |
| **GAP-006** | #5 Dashboard | Drill-through richer at competitors (Power BI cross-page drill, Tableau actions) — `cross-filter-safe` covers same-dashboard but not cross-dashboard | Medium | **CATCH-UP — Medium** | `/da-discovery` |
| **GAP-007** | #9 Collaboration | No commenting per chart/widget + @-mention — competitors all have it, control-tower SC-Manager workflow could benefit | Medium | **CATCH-UP — Medium** | `/da-discovery` |
| **GAP-008** | #12 AI/ML | Customer-facing anomaly detection + forecasting maturity — competitors expose as 1-click; ours requires `AnalysisRun` config | Medium | **CATCH-UP — Medium** | `/da-discovery` |
| **GAP-009** | #10 Governance | No field-level data lineage UI — semantic-registry has relationships but lineage view isn't exposed | Medium | **CATCH-UP — Medium** | `/da-discovery` |
| **GAP-010** | #13 Mobile | Mobile-optimized dashboard layout designer absent — only responsive Tailwind breakpoints | Low | **CATCH-UP — Low** | `/da-discovery` |
| **GAP-011** | #7 Authoring | Notebook + tool-trace-replay combo is uncommon — Hex/Deepnote/Mode are separate tools, vendor BIs lack it | High | **LEAPFROG** | `/da-discovery` priority |
| **GAP-012** | #12 AI/ML | Eval harness is internal — exposing customer-facing eval scores (model trust + transparency) is unique opportunity | High | **LEAPFROG** | `/da-discovery` priority |
| **GAP-013** | #12 AI/ML | Multi-LLM abstraction (LlmProvider + Budget + RateLimit) — vendor copilots are single-LLM (PowerBI=AzureOpenAI, Looker=Gemini, Tableau=Einstein); ISV cost-control + privacy positioning | High | **LEAPFROG** | `/da-discovery` priority |
| **GAP-014** | #3 Query Engine | Golden SQL library is customer-extensible — most vendor "verified answers" are vendor-curated; let tenants own their training corpus | Medium | **LEAPFROG** | `/da-discovery` priority |
| **GAP-015** | #12 AI/ML | Error-graph (ErrorNode/Relation/FixPattern/Column-Table links) — no equivalent at any benchmarked vendor; root-cause AI moat | Medium | **LEAPFROG** | `/da-discovery` priority |
| **GAP-016** | #7 Authoring | KPI Templates with `KpiIndustryBenchmark` + required-column gating + drilldown dim — uncommon depth, marketplace-able | Medium | **LEAPFROG** | `/da-discovery` priority |
| **GAP-017** | #2 Data Modeling | Code-defined semantic layer (LookML reference) — semantic-registry has versioning + test cases, sufficient for current use case | Low | **KEEP** | — |
| **GAP-018** | #6 Filtering | Field parameters / synced slicers (Power BI) — `widget-parameters` covers core use case | Low | **KEEP** | — |
| **GAP-019** | #10 Governance | Sensitivity labels / column-level masking (Power BI MIP) — per-tenant DB resolution covers harder isolation requirement | Low | **KEEP** | — |
| **GAP-020** | #11 Performance | In-memory engine (VertiPaq / Hyper / ElastiCube) — ClickHouse MV per-tenant is functional equivalent for analytical workloads | Low | **KEEP** | — |
| **GAP-021** | #1 Connectors | Connector breadth (3 providers vs 60-200) — vertical logistics doesn't need 200 connectors; positioning is "deep on 3" | Low | **IGNORE** | review 6 months |
| **GAP-022** | #4 Visualization | Custom viz SDK / marketplace (PowerBI AppSource, Tableau Extensions) — domain widgets are the moat, not chart library | Low | **IGNORE** | review 6 months |
| **GAP-023** | #4 Visualization | Generic chart-type breadth (8 widgets + chart-auto-detect vs 25-40 at competitors) — chart-auto-detect Beta gives some generic muscle | Low | **IGNORE** | review 6 months |
| **GAP-024** | #5 Dashboard | Story points / device-specific layouts (Tableau) — control-tower is desktop-first | Low | **IGNORE** | review 6 months |
| **GAP-025** | #11 Performance | Aggregation table fallback / dual storage mode — ClickHouse MV covers analytical layer | Low | **IGNORE** | review 6 months |
| **GAP-026** | #13 Mobile | Native iOS/Android app — control-tower usage is desktop/large-screen for SC Manager / BOD | Low | **IGNORE** | review 6 months — surface if customer signal |

---

## 3. Gap detail — per-row evidence and rationale

### GAP-001 · Component-level embed SDK
- **Capability**: #8 Embedding
- **Gap summary**: Sisense (Compose SDK for React/Angular/Vue), Tableau (Embedding API v3 web components), Looker (Embed SDK + Components) all ship component-level SDKs. Smartlog has `dashboard-shares` URL + iframe pattern only.
- **Evidence**:
  - Sisense: `_competitors/sisense.md` §8 — `https://sisense.dev/`
  - Tableau Embedding API v3: `_competitors/tableau.md` §8
  - Smartlog current state: `backend/src/Smartlog.Api/Controllers/SharesController.cs`, `frontend/src/features/dashboard/hooks/use-dashboard-shares.ts` (URL + iframe only)
- **Relevance**: **High** — Smartlog's whole positioning is embedded ISV; this is the *defining* capability of the category.
- **Verdict**: **CATCH-UP — High priority**
- **Rationale**: Direct identity gap — if Smartlog positions as embedded BI but lacks the SDK depth Sisense ships, RFP wins suffer. Component SDK also unlocks deeper customer customization without copying our widget code.
- **Handoff**: `/da-discovery` — frame as "embedded ISV SDK strategy" question (component SDK vs iframe + signed URL vs hybrid).

---

### GAP-002 · Signed-URL embedding with user-attribute pass-through
- **Capability**: #8 Embedding
- **Gap summary**: Looker's signed embed URL pattern passes user attributes (org, role, tenant) into the embedded session, driving RLS without separate JWT exchange. Smartlog `DashboardShare` + JWT tenant claim handles tenant routing but doesn't standardize attribute pass-through for embedded session.
- **Evidence**:
  - Looker: `_competitors/looker.md` §8 — `https://cloud.google.com/looker/docs/embedding-looker`
  - Smartlog: `backend/src/Smartlog.Api/Controllers/SharesController.cs`, `DashboardShare.cs`; multi-tenant via `IDbContextResolver.cs` JWT `TenantDBConfiguration` claim
- **Relevance**: **High** — multi-tenant embedded BI requires this pattern for ISV customers to embed Smartlog inside *their* user portal.
- **Verdict**: **CATCH-UP — High priority**
- **Rationale**: Without signed-URL with attribute pass-through, ISV customers either build custom JWT bridge or accept generic iframe — both raise integration cost. Looker pattern is industry reference.
- **Handoff**: `/da-discovery` — frame as "signed embed URL contract" question (which user attributes are mandatory vs optional; how do they map to RLS predicates).

---

### GAP-003 · Iframe with policy-driven RLS pass-through
- **Capability**: #8 Embedding
- **Gap summary**: Current iframe embed inherits JWT tenant claim implicitly; no declarative policy that says "for this dashboard, RLS predicate = `user.tenant_id`". Looker, Sisense, Metabase all ship this as a configurable policy.
- **Evidence**:
  - Metabase: `_competitors/metabase.md` §8 — `https://www.metabase.com/docs/latest/embedding/signed-embedding`
  - Sisense JAQL filter API: `_competitors/sisense.md` §10
  - Smartlog: implicit via `IDbContextResolver.cs` — no declarative policy file
- **Relevance**: **High** — auditability for ISV customers; without declarative policy, security review is harder.
- **Verdict**: **CATCH-UP — High priority**
- **Rationale**: Audit-friendly policy file (e.g., per-dashboard `embed-policy.json`) raises the bar for security review during procurement. Closely coupled to GAP-001/GAP-002 — likely one initiative.
- **Handoff**: `/da-discovery` — bundle with GAP-001/002 as "embedded BI hardening" initiative.

---

### GAP-004 · AI/ML maturity push (Beta → GA)
- **Capability**: #12 AI/ML
- **Gap summary**: Smartlog has architectural breadth (11 features) but 9 are Beta: chat-pipeline, knowledge-rag, embedding-management, analysis-runs, evaluation-harness, user-memory, error-graph, chat-suggestions, message-feedback. Inventory of features is strong; quality bar to take Beta → GA is the lift.
- **Evidence**: [`inventory/2026-05-26-feature-catalog.md`](../inventory/2026-05-26-feature-catalog.md) §12 — maturity column
- **Relevance**: **High** — competitors' AI features are GA-marketed; Smartlog "Beta" labels block enterprise procurement.
- **Verdict**: **CATCH-UP — High priority**
- **Rationale**: This is not a feature gap, it's a quality/SLA gap. Going GA requires: SLA on chat latency, eval harness running on production traffic, error budget defined, customer-facing changelog, deprecation policy.
- **Handoff**: `/da-discovery` — frame as "AI Beta → GA readiness criteria" question (which features go first; what SLA/quality bar; rollout sequencing across Mondelez vs Panasonic).

---

### GAP-005 · Server-side pixel-perfect PDF export
- **Capability**: #8 Embedding
- **Gap summary**: Smartlog `export-pdf-excel` is client-side (jspdf + html2canvas) — works for ad-hoc but pixel jitter in charts; no server-side rendering pipeline (Power BI Subscriptions, Tableau tabcmd, Looker Scheduled Plans).
- **Evidence**:
  - Power BI: `_competitors/powerbi.md` §8 (Subscriptions + paginated reports)
  - Tableau: `_competitors/tableau.md` §8 (`tabcmd export`)
  - Smartlog: FE deps `jspdf ^4.2.1`, `html-to-image ^1.11.13`, `html2canvas ^1.4.1`; `frontend/src/core/utils/excel-export.ts`
- **Relevance**: **Medium** — enterprise reporting use cases need pixel-perfect; SC Manager / BOD audience expects clean PDF.
- **Verdict**: **CATCH-UP — Medium priority**
- **Rationale**: Many tenant customers will accept current client-side export for daily ops; gap matters for monthly/quarterly executive reports. Lower urgency than embedding SDK.
- **Handoff**: `/da-discovery` — frame after embedding SDK initiative; can leverage Playwright/Chromium headless server-side render.

---

### GAP-006 · Drill-through richer cross-widget / cross-dashboard
- **Capability**: #5 Dashboard / Canvas
- **Gap summary**: Smartlog `cross-filter-safe` handles same-dashboard cross-filter; competitors offer cross-page drill (Power BI), action-driven navigation (Tableau Actions), drill-through with parameter pass (Looker UDD).
- **Evidence**:
  - Power BI: `_competitors/powerbi.md` §5 (cross-page drill + bookmarks)
  - Tableau: `_competitors/tableau.md` §5 (Actions framework)
  - Smartlog: `frontend/src/features/dashboard/hooks/use-cross-filter-safe.ts` — same-dashboard only
- **Relevance**: **Medium** — VFR late-alert / OTIF storytelling workflows benefit from drill from KPI hero → grouped table → row detail. Some of this exists today (Order Monitor → row detail) but not formalized.
- **Verdict**: **CATCH-UP — Medium priority**
- **Rationale**: Existing widgets implement informal drill (VFR storytelling v2 grouped table); formalize as `actions` framework to make it config-driven, not widget-baked.
- **Handoff**: `/da-discovery` — frame as "action/drill framework design" tied to widget-shared-base.

---

### GAP-007 · Comments per chart/widget + @-mention
- **Capability**: #9 Collaboration
- **Gap summary**: Power BI, Tableau, Looker, Sisense all have commenting per object + @-mention + notification. Smartlog has `MessageFeedback` (chat thumbs) and notification channels but no chart-level commenting.
- **Evidence**:
  - Power BI: `_competitors/powerbi.md` §9
  - Tableau: `_competitors/tableau.md` §9
  - Smartlog: `MessageFeedback.cs`, `NotificationLog.cs` — no per-widget comment entity
- **Relevance**: **Medium** — SC Manager / Rollout teams could use comments on widgets ("why is this number red today?"). But control-tower audience is typically smaller team using Slack already.
- **Verdict**: **CATCH-UP — Medium priority**
- **Rationale**: Slack integration partially covers async discussion; comments-on-widget closes the loop without context switch. Could be a thin layer on top of `MessageFeedback` entity.
- **Handoff**: `/da-discovery` — verify customer signal (Mondelez/Panasonic users) before committing to schema.

---

### GAP-008 · Customer-facing anomaly detection + forecasting
- **Capability**: #12 AI/ML
- **Gap summary**: Tableau Pulse (anomaly), Sisense Fusion AI (forecast), Qlik Insight Advisor (anomaly) all expose 1-click anomaly/forecast. Smartlog `AnalysisRun` entity is foundation but not yet customer-facing pattern (e.g., "auto-forecast this metric for next 14d").
- **Evidence**:
  - Tableau Pulse: `_competitors/tableau.md` §12 — `https://help.tableau.com/current/online/en-us/pulse_intro.htm`
  - Sisense Fusion AI: `_competitors/sisense.md` §12
  - Smartlog: `AnalysisRunsController.cs`, `AnalysisRun.cs`, `AnalysisArtifact.cs` — engine exists, UX missing
- **Relevance**: **Medium** — Mondelez Flash Daily target tracking and VFR rolling 14d already implement de-facto trend lines; anomaly/forecast as 1-click would compound.
- **Verdict**: **CATCH-UP — Medium priority**
- **Rationale**: Foundation exists; UX layer is the gap. Likely a "smart insight" panel on existing widgets.
- **Handoff**: `/da-discovery` — frame after AI Beta→GA initiative.

---

### GAP-009 · Field-level data lineage UI
- **Capability**: #10 Governance & RBAC
- **Gap summary**: Power BI (Fabric), Tableau (Catalog), Looker (Explore + Field details) all surface field-level lineage in UI. Smartlog `semantic-registry` has relationships entity but no lineage view.
- **Evidence**:
  - Tableau Catalog: `_competitors/tableau.md` §10
  - Smartlog: `SemanticRelationship.cs`, `SemanticDimension.cs` — data exists, UI missing
- **Relevance**: **Medium** — when investigating a number on a widget, lineage view ("which CTE → which MV → which raw table") is useful for DA/PM debugging. Currently captured in `sql-registry.md` per-tenant doc (off-repo).
- **Verdict**: **CATCH-UP — Medium priority**
- **Rationale**: Lineage formalization unlocks self-service auditability; tightly coupled to semantic-registry growth.
- **Handoff**: `/da-discovery` — frame as part of semantic-registry roadmap.

---

### GAP-010 · Mobile-optimized layout designer
- **Capability**: #13 Mobile / Responsive
- **Gap summary**: Power BI / Tableau have explicit mobile-layout authoring (drag-drop separately for mobile); Smartlog only has Tailwind responsive breakpoints.
- **Evidence**:
  - Power BI: `_competitors/powerbi.md` §13
  - Smartlog: `frontend/tailwind.config.*`, `use-mobile.tsx`
- **Relevance**: **Low** — control-tower is desktop-first; SC Manager / BOD typically use 24" displays. Field rollout users may need mobile but use Slack-pushed report screenshots today.
- **Verdict**: **CATCH-UP — Low priority** (only if customer signal)
- **Rationale**: Bigger than IGNORE because RTL Shadcn components already work on mobile; gap is layout designer, not basic responsiveness. Defer pending Mondelez/Panasonic mobile usage data.
- **Handoff**: `/da-discovery` — bundle with `/da-ops` pulse review of mobile traffic.

---

### GAP-011 · Notebook + tool-trace-replay combo (LEAPFROG)
- **Capability**: #7 Self-service Authoring
- **Gap summary**: Smartlog `notebooks` (cell + revision + run + artifact entities) + `tool-trace-replay` (chat agent step replay) is uncommon — competitors don't bundle notebook with conversational AI replay. Closest analog (Hex, Deepnote, Mode) are *separate* tools.
- **Evidence**:
  - Power BI / Tableau / Looker / Sisense / Qlik: no notebook concept (see `_competitors/*.md` §7)
  - Smartlog: `NotebooksController.cs`, `Notebook.cs`, `NotebookCellRevision.cs`, `ToolExecutionTrace.cs`, `frontend/src/features/notebook/`, `frontend/src/features/chat/api/tool-trace.api.ts`
- **Relevance**: **High** — DA / data scientist persona at Mondelez / Panasonic uses ad-hoc analytical workflow today via Excel + SQL editor; notebook is the productized version. Tool-trace-replay enables AI auditability.
- **Verdict**: **LEAPFROG**
- **Rationale**: Combination is unique; polish to GA + market as flagship "BI + analytical notebook + AI explainability" triad. Closest competitors require 3 separate tools.
- **Handoff**: `/da-discovery` priority — frame as "notebook polish + go-to-market positioning" question.

---

### GAP-012 · Customer-facing eval harness (LEAPFROG)
- **Capability**: #12 AI/ML
- **Gap summary**: `EvaluationRun` + `EvaluationResult` + QueryConfig is internal today; exposing customer-facing eval scores (per-model accuracy, hallucination rate, golden-SQL pass rate) builds model-trust narrative. Vendor copilots hide eval behind internal CI.
- **Evidence**:
  - PowerBI Copilot / Looker Gemini / Tableau Pulse: no public eval score (see `_competitors/*.md` §12)
  - Smartlog: `EvaluationRunsController.cs`, `EvaluationRun.cs`, `EvaluationResult.cs`, `QueryConfigs/EvaluationRuns.json`
- **Relevance**: **High** — enterprise procurement increasingly asks for model trust evidence; this is differentiated answer.
- **Verdict**: **LEAPFROG**
- **Rationale**: Foundation exists; productization = customer-facing dashboard showing eval scores + drill into failed cases. Marketable as "the only BI where you can verify the AI."
- **Handoff**: `/da-discovery` priority — frame as "model trust productization" question.

---

### GAP-013 · Multi-LLM as ISV value prop (LEAPFROG)
- **Capability**: #12 AI/ML
- **Gap summary**: `LlmProviderConfig` + `LlmBudgetConfig` + `LlmModelPricing` + `LlmUsageLog` = multi-vendor LLM abstraction. Vendor copilots are single-LLM (PowerBI=AzureOpenAI / Looker=Gemini / Tableau=Einstein). Smartlog ISV tenant can choose LLM + cap budget.
- **Evidence**:
  - PowerBI Copilot AzureOpenAI lock-in: `_competitors/powerbi.md` §12 — `https://learn.microsoft.com/en-us/power-bi/create-reports/copilot-introduction`
  - Looker Gemini lock-in: `_competitors/looker.md` §12
  - Smartlog: `LlmProvidersController.cs`, `LlmProviderConfig.cs`, `LlmProviderType.cs` (enum), `LlmBudgetConfig.cs`, `LlmUsageLog.cs`, `RateLimitsController.cs`
- **Relevance**: **High** — Mondelez / Panasonic enterprise procurement has data-residency + cost-cap requirements that single-LLM-lock-in vendors can't meet.
- **Verdict**: **LEAPFROG**
- **Rationale**: Architectural moat already shipped; needs go-to-market story. ISV tenants who hate Azure OpenAI lock-in are direct addressable market.
- **Handoff**: `/da-discovery` priority — frame as "multi-LLM positioning + tenant LLM contract" question.

---

### GAP-014 · Customer-extensible Golden SQL library (LEAPFROG)
- **Capability**: #3 Query Engine / Semantic Layer
- **Gap summary**: `GoldenSql` (NL↔SQL pairs with difficulty rating) is uncommon; positioned as **customer-extensible training corpus** (each tenant grows their own library) would be unique. Vendor "verified answers" (Tableau Pulse) are vendor-curated.
- **Evidence**:
  - Tableau Pulse Enhanced Q&A: `_competitors/tableau.md` §12 — verified answers are vendor-curated
  - Smartlog: `GoldenSqlsController.cs`, `GoldenSql.cs`, `GoldenSqlDifficulty.cs` (enum)
- **Relevance**: **Medium** — Mondelez has 24-month historical SQL library accumulated; Panasonic PSV new tenant could clone subset. Customer ownership of training corpus is differentiated.
- **Verdict**: **LEAPFROG**
- **Rationale**: Foundation shipped; productization = tenant-owned library + cross-tenant sharing controls + golden-SQL → eval-harness loop.
- **Handoff**: `/da-discovery` priority — frame after GAP-012 (eval harness customer-facing).

---

### GAP-015 · Error-graph as root-cause AI (LEAPFROG)
- **Capability**: #12 AI/ML
- **Gap summary**: `ErrorNode` + `ErrorRelation` + `ErrorFixPattern` + `ErrorColumnLink` + `ErrorTableLink` = graph-based root-cause analysis. No equivalent at any benchmarked vendor.
- **Evidence**:
  - PowerBI Decomposition Tree, Tableau Explain Data, Sisense narrative: capability-shallow vs Smartlog's graph schema (see `_competitors/*.md` §12)
  - Smartlog: `ErrorNodesController.cs`, `ErrorNode.cs`, `ErrorRelation.cs`, `ErrorFixPattern.cs`, `ErrorColumnLink.cs`, `ErrorTableLink.cs`, `QueryConfigs/ErrorNodes.json`, `frontend/src/features/error-graph/`
- **Relevance**: **Medium** — VFR late-alert / Flash Daily exception triage already use de-facto root-cause workflow; error-graph could productize "when this metric drops, here are the 3 likely upstream causes."
- **Verdict**: **LEAPFROG**
- **Rationale**: Unique IP. Polish + customer-facing UX = defensible moat. Pair with `analysis-runs` for "AI says X caused Y" narrative.
- **Handoff**: `/da-discovery` priority — frame as "root-cause AI productization" question.

---

### GAP-016 · KPI Templates as marketplace (LEAPFROG)
- **Capability**: #7 Self-service Authoring
- **Gap summary**: `KpiTemplate` + `KpiIndustryBenchmark` + `KpiRequiredColumn` + `KpiRequiredTable` + `KpiDrilldownDimension` + `KpiGoalConfig` is unusual depth. Competitors have "metric definition" but not "industry benchmark + required-column gating + drilldown dim + goal config" bundle.
- **Evidence**:
  - Power BI metrics: `_competitors/powerbi.md` §2 — metric def only, no industry benchmark
  - Smartlog: `KpiTemplatesController.cs`, 11 entities under KpiTemplate (`KpiTemplate.cs`, `KpiChartConfig.cs`, `KpiDrilldownDimension.cs`, `KpiGoalConfig.cs`, `KpiIndustryBenchmark.cs`, `KpiMetricType.cs`, `KpiRequiredColumn.cs`, `KpiRequiredTable.cs`, `KpiRuntimeParameter.cs`, `KpiTemplateConsts.cs`, `KpiTemplateMapping.cs`)
- **Relevance**: **Medium** — logistics-specific KPI library (OTIF, VFR, PGI, Flash Daily) is the vertical moat; productize as marketplace of templates with industry benchmark, tenants subscribe.
- **Verdict**: **LEAPFROG**
- **Rationale**: Schema is unusually rich; only need marketplace UX + benchmark sourcing strategy (NSO data, Mondelez/Panasonic baselines as benchmark).
- **Handoff**: `/da-discovery` priority — frame as "KPI template marketplace" + "industry benchmark sourcing" two-part question.

---

### GAP-017 · Code-defined modeling (LookML reference)
- **Capability**: #2 Data Modeling
- **Gap summary**: Looker LookML is reference: code-defined semantic layer, Git-versioned, IDE in browser. Smartlog `SemanticModelVersion` + `SemanticTestCase` covers core versioning use case; LookML-style full DSL not present.
- **Evidence**:
  - Looker LookML: `_competitors/looker.md` §2
  - Smartlog: `SemanticModelVersion.cs`, `SemanticTestCase.cs`, `SemanticDimension.cs`, `SemanticMetric.cs`, `SemanticRelationship.cs`
- **Relevance**: **Low** — vertical logistics tenants don't have analytics engineering teams that need LookML depth; semantic-registry covers tenant use case.
- **Verdict**: **KEEP**
- **Rationale**: Sufficient depth for vertical positioning; not worth chasing LookML.

---

### GAP-018 · Field parameters / synced slicers
- **Capability**: #6 Filtering & Parameters
- **Gap summary**: Power BI field parameters (single slicer drives field choice across visuals) and synced slicers (same selection across pages). Smartlog `widget-parameters` + `cross-filter-safe` covers same-dashboard use case.
- **Evidence**:
  - Power BI: `_competitors/powerbi.md` §6
  - Smartlog: `WidgetParameter.cs`, `frontend/src/features/dashboard/hooks/use-cross-filter-safe.ts`
- **Relevance**: **Low** — current pattern works for VFR / Flash Daily / Order Monitor.
- **Verdict**: **KEEP**
- **Rationale**: No customer signal of friction.

---

### GAP-019 · Sensitivity labels / column-level masking
- **Capability**: #10 Governance & RBAC
- **Gap summary**: Power BI MIP sensitivity labels + column-level masking. Smartlog tenant DB isolation via JWT claim covers harder-to-fake isolation requirement.
- **Evidence**:
  - Power BI MIP: `_competitors/powerbi.md` §10
  - Smartlog: `IDbContextResolver.cs`, multi-tenant per-contract
- **Relevance**: **Low** — per-tenant DB is structurally stronger than column-masking in shared DB.
- **Verdict**: **KEEP**
- **Rationale**: Different architectural choice already addresses underlying need.

---

### GAP-020 · Incremental refresh / aggregation fallback
- **Capability**: #11 Performance & Scale
- **Gap summary**: Power BI VertiPaq aggregations + incremental refresh; ClickHouse MV per-tenant is functional equivalent for analytical layer (materialized at ingest, refresh by partition).
- **Evidence**:
  - Power BI aggregations: `_competitors/powerbi.md` §11
  - Smartlog: per-tenant `mv_*` (e.g., Mondelez `analytics_workspace`, Panasonic PSV pipeline — memory `project_mondelez_da_ops_stack`, `project_panasonic_psv_pipeline`)
- **Relevance**: **Low** — different stack achieving same end goal.
- **Verdict**: **KEEP**
- **Rationale**: ClickHouse MV is appropriate choice; no architectural debt.

---

### GAP-021 · Connector breadth (3 vs 60-200)
- **Capability**: #1 Data Connectors
- **Gap summary**: Power BI 200+, Tableau 100+, Looker 60+, Superset 40+, Sisense 50+, Qlik 100+. Smartlog 3 (PG/MSSQL/CH via EF Core).
- **Evidence**:
  - All vendors: `_competitors/*.md` §1
  - Smartlog: `DataSourcesController.cs`, `DatabaseProviderType.cs` (enum)
- **Relevance**: **Low** — vertical logistics tenant data lives in TMS/WMS/ERP/CH warehouse; 3 providers cover 90% of analytical surface.
- **Verdict**: **IGNORE**
- **Rationale**: Not a moat to chase. Smartlog ETL ingest from logistics systems is the real connector story (off this product's scope).
- **Review**: 6 months — if customer signal for direct Snowflake/BigQuery, revisit.

---

### GAP-022 · Custom viz SDK / marketplace
- **Capability**: #4 Visualization Library
- **Gap summary**: PowerBI AppSource ~700 visuals, Tableau Extensions Gallery, Superset chart plugin SDK. Smartlog has 8 logistics-specific widgets + `widget-shared-base` primitives.
- **Evidence**:
  - PowerBI AppSource: `_competitors/powerbi.md` §4
  - Smartlog: `frontend/src/features/dashboard/components/widgets/` (8 widget folders + shared)
- **Relevance**: **Low** — domain widgets are the moat; chart-library breadth dilutes positioning.
- **Verdict**: **IGNORE**
- **Rationale**: Chase only if logistics-specific tenant signal asks for custom chart.
- **Review**: 6 months.

---

### GAP-023 · Generic chart-type breadth
- **Capability**: #4 Visualization Library
- **Gap summary**: Power BI 30+ built-in, Superset 40+, Sisense 30+. Smartlog 8 widgets + `chart-auto-detect` Beta (Recharts + d3-array).
- **Evidence**:
  - Vendors: `_competitors/*.md` §4
  - Smartlog: `frontend/src/features/charts/lib/chart-auto-detect.ts`, `smart-encoding-suggester.ts`
- **Relevance**: **Low** — chart-auto-detect Beta gives some generic-chart muscle; logistics-specific widgets are differentiated.
- **Verdict**: **IGNORE**
- **Rationale**: Polishing chart-auto-detect Beta → GA may incidentally close this gap without strategic intent.
- **Review**: 6 months.

---

### GAP-024 · Story points / device-specific layouts
- **Capability**: #5 Dashboard / Canvas
- **Gap summary**: Tableau Story Points (sequence-driven narrative), device-specific layouts. Smartlog flat react-grid-layout.
- **Evidence**:
  - Tableau: `_competitors/tableau.md` §5
  - Smartlog: `frontend/src/features/dashboard/api/`, react-grid-layout ^2.2.2
- **Relevance**: **Low** — Smartlog storytelling is per-widget (Flash Daily 6 levels, VFR storytelling v2) — already implements narrative without sequence framework.
- **Verdict**: **IGNORE**
- **Rationale**: Storytelling pattern already implemented at widget level — different paradigm, same end goal.
- **Review**: 6 months.

---

### GAP-025 · Aggregation table fallback / dual storage mode
- **Capability**: #11 Performance & Scale
- **Gap summary**: Power BI aggregation tables (in-memory rollup + DirectQuery fallback). Smartlog ClickHouse MV pre-aggregates at ingest.
- **Evidence**:
  - Power BI: `_competitors/powerbi.md` §11
  - Smartlog: tenant `mv_*` MV pattern
- **Relevance**: **Low** — same end goal, different architecture.
- **Verdict**: **IGNORE**
- **Rationale**: ClickHouse MV adequate; no migration value.
- **Review**: 6 months.

---

### GAP-026 · Native iOS/Android app
- **Capability**: #13 Mobile / Responsive
- **Gap summary**: Power BI / Tableau / Sisense / Qlik all ship native mobile apps. Smartlog web responsive only.
- **Evidence**:
  - Vendors: `_competitors/*.md` §13
  - Smartlog: `frontend/tailwind.config.*`, `use-mobile.tsx`, RTL Shadcn — no native iOS/Android project
- **Relevance**: **Low** — control-tower audience is desktop-first; Slack-pushed screenshots cover field-mobile use case today.
- **Verdict**: **IGNORE**
- **Rationale**: Native app investment is large; control-tower usage doesn't justify. Revisit if customer signal changes.
- **Review**: 6 months — pair with `/da-ops` pulse on mobile traffic.

---

## 4. Open questions / blockers

No `unverified` gaps requiring resolution before handoff. All 26 gaps have either code path (Smartlog side) or competitor doc URL (`_competitors/*.md` per-area Evidence field).

Note from Mode B verification:
- **Looker Studio Pro** — embedded specifics partial-unverified (doc 404). Affects GAP-002 scoping precision but not the verdict (CATCH-UP HIGH stands regardless).
- **Metabase / Superset / Qlik / Looker** — written from training cutoff + vendor doc URL roots. 2026 Q1/Q2 release scope flagged in each baseline. Specific recent-release diffs would be Mode D scope.

---

## 5. Closing notes

- File generated by `/da-po sweep` (Mode C — Gap Analysis section).
- Sibling file [`roadmap-input/2026-05-26-recommendations.md`](../roadmap-input/2026-05-26-recommendations.md) sequences CATCH-UP + LEAPFROG items by relevance + dependency.
- `projects/` is the `helix_projects` repo (gitignored from main) — commit via `/da-projects` (memory: `project_projects_repo_isolated`).
- Mode D delta will diff against this when re-run; recommend rerun cadence weekly while `feat-vfr-late-alert` branch active.

---

## Mandatory ending signals — see top-level run summary in conversation output
