# BI Capability Matrix — Smartlog Control Tower vs 7 BI Vendors

**Mode**: B (Benchmark) · **Scan baseline**: `41b3863` (2026-05-22)
**Author**: `/da-po benchmark` (squad1@gosmartlog.com)
**Inventory source**: [`projects/po/inventory/2026-05-26-feature-catalog.md`](../inventory/2026-05-26-feature-catalog.md) (47 features, 13 buckets)
**Competitor baselines**: [`projects/po/_competitors/`](../_competitors/) (7 files, all refreshed 2026-05-26)

---

## TL;DR — where we stand

Quick read across the 14 capability areas, scoring Presence (✓ / ◐ / ✗) and Depth (Deep / Medium / Shallow):

- **Smartlog leads** in: **#12 AI/ML (architecturally — multi-LLM + golden SQL + eval harness + error graph + user memory), #7 self-service (chat + notebook combo), #2 data modeling (semantic-registry + glossary + column-value-index = anti-hallucination grounding).**
- **Smartlog matches** in: #5 dashboard/canvas, #6 filtering, #10 governance, #11 performance (different stack — ClickHouse MV vs in-memory engine), #9 collaboration.
- **Smartlog behind** in: **#1 connectors (3 vs 60–200), #4 visualization breadth (8 widgets vs 25–40 chart types), #13 mobile (web only, no native app), #8 embedding polish (Sisense Compose SDK / Looker signed URL / Metabase interactive embedding are more mature).**
- **N/A** for Smartlog: **#14 pricing/deployment** (internal product, multi-tenant per-contract — no public list).

The headline strategic read: **Smartlog is wide on AI/ML and self-service, narrow on connectors and chart library**. The AI/ML depth is unusual for the price point and the multi-LLM architecture is a real differentiator vs PowerBI Copilot (Azure OpenAI lock-in), Looker (Gemini lock-in), and Tableau Pulse (Salesforce-Einstein-tied). The connector and chart-library breadth gap is consistent with "vertical logistics analytics ISV" positioning — and shouldn't be the next focus.

---

## How to read the matrix

**Cell format**: `Presence|Depth` followed by 1-line evidence note. Presence per [taxonomy](../../../.claude/skills/da-po/references/bi-capability-taxonomy.md):

| Presence | Meaning |
|---|---|
| ✓ | Full-featured per "what good looks like" rubric |
| ◐ | Has the capability but missing key components |
| ✗ | None / roadmap only |

**Depth**: Deep ≥80% rubric match · Medium 40–80% · Shallow <40% · n/a not applicable.

**Source**: Each Smartlog cell references the inventory file by `feature_id`. Each competitor cell references the competitor baseline file (`_competitors/{vendor}.md`).

---

## Capability matrix (14 × 8)

| # | Capability | Smartlog | Power BI | Tableau | Looker | Superset | Metabase | Sisense | Qlik |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **Data Connectors** | ◐ Medium · 3 features: data-sources (EF Core providers PG/MSSQL/CH), multi-tenant-resolver (JWT claim), Refit clients | ✓ Deep · 200+ Power Query connectors; SDK + certified marketplace | ✓ Deep · 100+ native + WDC SDK | ✓ Medium · 60+ DB dialects; SQL-first (no file/REST) | ✓ Medium · 40+ SQLAlchemy dialects | ✓ Medium · 20+ official + community | ✓ Deep · 50+ + ElastiCube ETL | ✓ Deep · 100+ + Qlik Data Integration (CDC) |
| 2 | **Data Modeling** | ✓ Medium · 4 features: semantic-registry (Dim/Metric/Rel/TestCase), glossary, column-value-index (NL grounding), dynamic-query-configs | ✓ Deep · DAX + visual modeling view + Fabric versioning | ✓ Deep · logical/physical layers + Tableau dialect | ✓ Deep · **LookML — code-defined, Git-versioned (reference)** | ◐ Medium · datasets + computed columns, no semantic layer | ◐ Medium · Models + metrics (lightweight) | ✓ Deep · ElastiCube + Live model + drag-drop modeler | ✓ Deep · **Associative model (unique paradigm)** |
| 3 | **Query Engine / Semantic Layer** | ✓ Medium · 4 features: dynamic-query-engine (SqlKata + Fluid), golden-sql-library (NL↔SQL pairs — uncommon), query-history, ClickHouse MV per-tenant | ✓ Deep · VertiPaq in-memory + DAX + DirectQuery + composite | ✓ Deep · Hyper in-memory + VizQL Data Service | ✓ Deep · LookML → SQL transpiler + Modeler standalone | ◐ Medium · Jinja+SQLAlchemy pushdown | ◐ Medium · Query Builder + warehouse pushdown | ✓ Deep · ElastiCube in-memory + Live mode | ✓ Deep · Associative in-memory engine |
| 4 | **Visualization Library** | ◐ Medium · 10 features: 8 logistics-specific widgets (alert-summary, daily-ops, flash-report, matrix-table, order-monitor, pgi-report, wh-predict, shared) + chart-auto-detect Beta + saved-charts | ✓ Deep · 30+ built-in + AppSource (~700) + R/Python viz | ✓ Deep · 24+ built-in + Show Me + extensions API | ✓ Medium · ~25 built-in + custom viz API | ✓ Deep · 40+ echarts-based + plugin SDK | ✓ Medium · 18 chart types (no SDK) | ✓ Deep · 30+ widgets + Custom Widget SDK + Compose SDK | ✓ Deep · 25+ + extensions + Vizlib |
| 5 | **Dashboard / Canvas** | ✓ Medium · 5 features: dashboard-core (react-grid-layout), permissions, shares, AI assist Beta, landing-canvas | ✓ Deep · Reports + Dashboards + Apps + drill-through + bookmarks | ✓ Deep · Floating + tiled + device layouts + actions + story points | ✓ Medium · UDD + LookML dashboards + drill-through | ✓ Medium · Drag-drop + tabs + filters | ✓ Medium · Drag-drop + tabs + parameters | ✓ Deep · Drag-drop + tabs + JS hooks | ✓ Deep · Sheets + Stories + Bookmarks |
| 6 | **Filtering & Parameters** | ✓ Medium · 3 features: widget-filter-resolver (multi-select+CSV), cross-filter-safe, widget-parameters | ✓ Deep · Slicers + page/visual filters + field params + sync slicers | ✓ Deep · Quick + context + data source filters + parameter actions | ✓ Deep · Dashboard filters + LookML params + templated WHERE | ✓ Medium · Native filter system + cross-filter | ✓ Medium · Filters + linked + click behavior | ✓ Deep · JAQL filter API + cross-filter | ✓ Deep · **Associative selection (signature UX)** |
| 7 | **Self-service Authoring** | ✓ Deep · **6 features: chat-conversations (NL→SQL), notebooks (Beta, cell+revision+run+artifact), form-configs (38), monaco-sql-editor, kpi-templates (industry benchmark + drilldown + goal), tool-trace-replay** | ✓ Deep · Desktop + Q&A NL visual + Quick measures + Smart Narrative + Copilot | ✓ Deep · Drag-drop pill-based authoring (signature) | ◐ Medium · Explore UX requires LookML pre-build (engineer-first) | ✓ Medium · Explore + SQL Lab (no chat/NL) | ✓ Deep · **Best-in-class Query Builder for SMB** + X-rays | ✓ Medium · Drag-drop + NL "Ask" in Fusion | ✓ Deep · Drag-drop + Insight Advisor NL |
| 8 | **Embedding & Sharing** | ✓ Medium · 4 features: share-resource, scheduled-reports, slack-integration, export-pdf-excel (client-side only) | ✓ Deep · Power BI Embedded + iframe + JS SDK + RLS pass-through + subscriptions | ✓ Deep · Embedding API v3 + Connected Apps + RLS + tabcmd | ✓ Deep · **Signed embed URLs + JS Embed SDK + RLS via user attributes (mature ISV)** | ◐ Medium · Embedded SDK (community) + iframe + Alerts & Reports | ✓ Deep · **Static + Interactive embedding + JWT signed (ISV-friendly)** | ✓ Deep · **Compose SDK (React/Angular/Vue components) + Fusion Embed + JWT RLS (industry-leading)** | ✓ Deep · nebula.js + iframe + Capability APIs + Section Access RLS |
| 9 | **Collaboration** | ✓ Medium · 5 features: monitors, alerts (**LLM analysis attached — unusual**), notifications, message-feedback (chat thumbs), actions | ✓ Medium · Comments + @-mention + Teams + subscriptions + Data Alerts | ✓ Medium · Comments + subscriptions + data-driven alerts | ◐ Medium · Scheduled delivery + alerts + Slack (no commenting) | ◐ Shallow · Alerts & Reports only | ◐ Medium · Alerts + dashboard subs + pinning | ◐ Medium · Alerts + Pulse anomaly + scheduled | ◐ Medium · Notes + subs + Qlik Alerting |
| 10 | **Governance & RBAC** | ✓ Medium · 7 features: users + roles + security-groups + tenant-branding + rate-limits + activity-log + admin-features. Tenant isolation via JWT claim | ✓ Deep · Workspace + RLS + OLS + MIP sensitivity labels + audit (M365) | ✓ Deep · Project/Workbook/View permissions + RLS + SAML/OIDC | ✓ Deep · Roles + permission sets + model sets + RLS + Git workflow | ✓ Medium · Flask-AppBuilder roles + dataset + RLS Jinja + LDAP/OAuth | ✓ Medium · Group permissions + sandboxing (Pro+) + audit (Ent only) | ✓ Deep · Roles + Data Security Rules + JWT SSO + multi-tenant arch | ✓ Deep · Spaces + roles + security rules + Section Access RLS |
| 11 | **Performance & Scale** | ✓ Medium · 4 features: embedding-cache (vector), background-jobs, file-storage, ClickHouse MV per-tenant | ✓ Deep · VertiPaq + aggregations + incremental refresh + Premium capacity | ✓ Deep · Hyper extract + incremental + Bridge | ✓ Medium · PDT + datagroups + warehouse pushdown | ◐ Medium · Redis cache + Celery async + warehouse pushdown | ◐ Medium · Caching + query timeout (no in-memory) | ✓ Deep · ElastiCube + incremental builds | ✓ Deep · Associative engine + Direct Query + incremental |
| 12 | **AI / ML** | ✓ Deep · **11 features: chat-pipeline (multi-step agent), knowledge-rag (chunk retrieval), embedding-management (multi-provider), llm-providers (multi-vendor + budget + usage), org-ai-settings, analysis-runs, evaluation-harness (uncommon), skills-registry, user-memory (long-term), error-graph (root cause), chat-suggestions. Multi-LLM = architectural moat.** | ✓ Deep · Copilot (standalone + pane + apps + DAX + narrative) + Key Influencers + Decomposition Tree + Fabric AutoML. **Azure OpenAI single-vendor lock-in.** Requires Fabric F2+/Premium P1+. | ✓ Medium · **Tableau Pulse (anomaly + Enhanced Q&A Tableau+ tier) — Tableau Cloud only**. Einstein Discovery. | ✓ Medium · Gemini in Looker (formula assist + LookML assist + conversational + slide gen). **Gemini single-vendor.** | ✗ Shallow · No native AI upstream; Preset cloud experimental | ◐ Shallow → Medium · Metabot (NL→query); X-rays rule-based | ✓ Medium · Fusion AI (NL→chart + anomaly + forecast). Multi-LLM unverified. | ✓ Medium · Insight Advisor + **Qlik Answers (GenAI)** + AutoML |
| 13 | **Mobile / Responsive** | ◐ Medium · responsive-web (Tailwind v4 + RTL Shadcn). **No native iOS/Android app.** | ✓ Deep · Native iOS+Android+Windows + mobile-optimized layout designer | ✓ Deep · Native iOS+Android + device-specific layouts + offline favorites | ◐ Medium · Looker Mobile app (less polished) | ◐ Shallow · Responsive only, no native | ◐ Shallow · Web responsive, no native | ✓ Medium · Sisense Mobile iOS+Android | ✓ Deep · Qlik Sense Mobile + offline mode |
| 14 | **Pricing & Deployment** | n/a · **Internal product** — B2B SaaS embedded multi-tenant per-contract; JWT claim tenant routing. Self-hosted .NET 10 + React 19. No public pricing. | ✓ Deep · Pro $14 + PPU $24 + Fabric F2 ~$262/mo + Premium P1 + Embedded SKU. **Copilot requires F2+/P1+ capacity.** | ✓ Deep · Viewer $15 + Explorer $42 + Creator $75 + Tableau+ premium. Embedded license separate. | ◐ Medium · **Quote-based enterprise** + Looker Studio free / Pro $9. Embedded license tier exists. | ✓ Deep · **FREE Apache 2.0 OSS** + Preset Cloud $0–$20/user/mo | ✓ Deep · OSS free + Cloud Starter $85/mo (5 users) + Pro $500/mo + Enterprise quote | ◐ Medium · **Quote-based** $25K–$100K+/yr; Fusion Embed core product | ✓ Medium · Business $30/user/mo + Enterprise quote + OEM/Embedded |

---

## Per-area highlights (where each cell has a real story)

### Areas Smartlog leads or matches

**#12 AI/ML — strongest moat.** Smartlog has 11 features in this bucket vs 1–5 typical. The architectural choices are differentiated:

- `llm-providers` (entity + controller + budget config) = **multi-LLM abstraction** vs PowerBI Copilot (Azure OpenAI only) / Looker (Gemini only) / Tableau Pulse (Salesforce Einstein only).
- `golden-sql-library` (NL↔SQL training pairs with difficulty rating) = uncommon at BI vendors; closest analog is Tableau Pulse "verified answers" but at SQL grain not chart grain.
- `evaluation-harness` (EvaluationRun + EvaluationResult + QueryConfig) = ability to score model versions in-product. PowerBI/Tableau/Looker do not expose this; it sits behind their internal CI.
- `error-graph` (ErrorNode + Relation + FixPattern + Column/Table links) = graph-based root cause. No direct equivalent at any benchmarked vendor.
- `user-memory` persistent (scope + type) = cross-conversation memory. Vendor copilots are mostly single-session.
- `column-value-index` (anti-hallucination grounding for NL→SQL) — supports area 12 by lifting modeling foundation.

**#7 Self-service Authoring — wide moat.** chat + notebook + KPI templates trio:

- `notebooks` (Jupyter-style with cell + revision + run + artifact entities) = no equivalent at PowerBI/Tableau/Looker/Sisense/Qlik. Closest analog is Hex/Deepnote/Mode, which are *separate* tools, not BI-integrated.
- `kpi-templates` with `KpiIndustryBenchmark` + `KpiRequiredColumn` + `KpiRequiredTable` + `KpiGoalConfig` = uncommon depth. Most vendors have "metric definition"; few have "industry benchmark + required-column gating".
- `tool-trace-replay` (chat agent replay) = enables debugging/explainability for AI authoring. No vendor exposes this at this depth.

**#2 Data Modeling — surprisingly competitive.** Smartlog's `semantic-registry` (versioned, with TestCase entity) + `glossary` (BusinessRule) + `column-value-index` (grounding) is actually a tighter modeling triangle than Superset/Metabase. Below Looker (LookML reference) and below DAX semantically, but above OSS BI tools.

### Areas Smartlog is behind

**#1 Data Connectors — narrowest gap.** 3 features vs 60–200. Smartlog goes through .NET EF providers (PG/MSSQL/CH) and Refit clients to Smartlog ecosystem APIs. **Not a moat to chase** — fits vertical logistics positioning. Logistics customers don't need 200 connectors; they need 3 done well + ETL pipelines done well.

**#4 Visualization Library — domain-shaped gap.** 8 widgets (logistics-specific: alert-summary, daily-ops, flash-report, matrix-table, order-monitor, pgi-report, wh-predict, shared) + chart-auto-detect + saved-charts vs 25–40 chart types at competitors. **Strategic call**: Smartlog widgets are *domain* widgets, not chart-library widgets. Chart-auto-detect Beta gives some generic-chart muscle. Probably IGNORE most "chart breadth" gaps; only catch up on a couple of high-leverage chart types.

**#8 Embedding Polish — visible gap.** Smartlog has dashboard-shares + scheduled-reports + slack-integration + client-side export, but no:
- Component-level embed SDK (Sisense Compose SDK pattern, React-native components)
- Signed URL with user-attribute pass-through (Looker pattern, more rigorous than current share-resource)
- Server-side pixel-perfect PDF (current is client html2canvas/jsPDF)
- Iframe with policy-driven RLS pass-through

This is the **most defensible CATCH-UP candidate** because Smartlog's whole positioning is embedded ISV.

**#13 Mobile — open gap.** Web responsive only; no native iOS/Android. PowerBI, Tableau, Sisense, Qlik all have apps. **Probably IGNORE** unless customer signal — control tower use cases mostly desktop/large screen.

### N/A

**#14 Pricing & Deployment** — Smartlog is internal product, not a public-priced BI tool. Listed n/a. Note vendor pricing is in [`_competitors/`](../_competitors/) baselines for sales/RFP support.

---

## Capability summary by vendor (1 row each)

| Vendor | Areas Deep | Areas Medium | Areas Shallow/None | Strongest moat | Most relevant lens for Smartlog |
|---|---|---:|---:|---|---|
| **Smartlog** | **#7, #12** | #1, #2, #3, #4, #5, #6, #8, #9, #10, #11 | #13 (no native app), #14 (n/a) | Multi-LLM AI/ML + chat+notebook self-service + KPI templates with industry benchmarks | Self-positioned as vertical logistics + AI-native embedded BI |
| Power BI | #1, #2, #3, #4, #5, #6, #7, #8, #10, #11, #12, #13, #14 | #9 | — | DAX + VertiPaq + Copilot scale | Capacity-priced Copilot raises ISV cost barrier — Smartlog multi-LLM defends |
| Tableau | #1, #2, #3, #4, #5, #6, #7, #8, #13, #14 | #9, #10, #11, #12 | — | Viz polish + Pulse direction | Pulse Cloud-only leaves Server customers exposed — entry for vertical-specific challenger |
| Looker | #1*, #2, #3, #6, #8, #10 | #4, #5, #11, #12, #13, #14 | #7 (engineer-first), #9 | LookML semantic layer + signed-URL embedding | LookML is reference for Smartlog's semantic-registry growth path |
| Superset | #4 | #1, #2, #3, #5, #6, #7, #10, #14 | #8 (community SDK), #9, #11, #12 (no AI), #13 | OSS economics + chart library + SQL Lab | OSS price floor — Smartlog's AI/ML + vertical depth must justify premium |
| Metabase | #7, #8, #14 | #1, #2, #3, #4, #5, #6, #10, #11 | #9, #12, #13 | Citizen-analyst no-code + ISV embedding economics | Direct embedded-BI competitor at $85–$500/mo price point |
| Sisense | #1, #2, #3, #4, #5, #6, #7, #8, #10, #11 | #9, #12, #13, #14 | — | Compose SDK + ElastiCube + multi-tenant | **Closest model to Smartlog** — same ISV embedded play; Compose SDK is the embedding benchmark |
| Qlik | #1, #2, #3, #4, #5, #6, #7, #8, #10, #11, #13 | #9, #12, #14 | — | Associative engine UX | Qlik Answers GenAI is direction-of-travel competitor; associative paradigm doesn't threaten Smartlog architecture |

*Looker #1 is Medium (60+ DB but no file/REST first-class).

---

## Pre-gap surfacing (for full Mode C run later)

If/when `/da-po sweep` is run, the following gap candidates from this matrix will surface — sketched here for orientation, not yet formal GAP-NNN entries:

| Area | Direction | Sketch |
|---|---|---|
| #8 Embedding | **CATCH-UP — high priority** | Component-level SDK pattern (Sisense Compose SDK + Looker signed URL hybrid). Smartlog is positioned as embedded but doesn't yet have ISV-grade SDK. |
| #1 Connectors (REST/file) | IGNORE | Vertical logistics doesn't need 200 connectors. Keep current 3. |
| #4 Generic chart breadth | IGNORE | Domain widgets are the moat. Don't chase chart library count. |
| #13 Native mobile app | IGNORE (review 6 months) | Control tower is desktop-first. Revisit if customer signal changes. |
| #11 In-memory engine | IGNORE | ClickHouse MV is functional equivalent for vertical use case. |
| #12 AI/ML maturity (move features from Beta → GA) | **CATCH-UP** | Smartlog has architectural breadth in AI/ML; many features still Beta. Maturity push, not new features. |
| #7 Notebook polish | **LEAPFROG candidate** | Notebooks + tool-trace-replay is unusual; double down before competitors catch up. |
| #12 Eval harness as customer-facing surface | **LEAPFROG candidate** | Expose evaluation results to customers (model trust + transparency). Unique vs vendor copilots. |
| #2 LookML-style code modeling | KEEP / partial CATCH-UP | semantic-registry already covers core; only add Git-versioning if signal. |
| #8 Pixel-perfect server-side export | CATCH-UP (low priority) | Current client-side export works but limits enterprise PDF use cases. |

Formal gap analysis with verdict + handoff to be produced in `/da-po sweep` Mode C.

---

## Verification notes

Per `_competitors/*.md` baselines:

- **Power BI Copilot** — verified via WebFetch of `learn.microsoft.com/en-us/power-bi/create-reports/copilot-introduction` on 2026-05-26 (article updated 2026-03-23, GitNexus commit `6e35105`). Capacity requirement F2+/P1+ confirmed.
- **Tableau Pulse** — verified via WebFetch of `help.tableau.com/current/online/en-us/pulse_intro.htm` on 2026-05-26. Tableau Cloud only confirmed; Enhanced Q&A is Tableau+ tier.
- **Sisense embedded** — verified via WebFetch of `sisense.com/platform/embedded-analytics/` on 2026-05-26.
- **Looker Studio Pro** — doc URL 404 (`cloud.google.com/looker/docs/studio/looker-studio-pro` and redirect target). Baseline written from training-cutoff knowledge with vendor docs URL roots. **Mark as partially unverified** for Pro-specific embedding details.
- **Metabase / Superset / Qlik** — baselines written from training-cutoff knowledge with vendor docs URL roots. Specific 2026 Q1/Q2 release scope flagged as unverified in each baseline file.

Each cell's source path is in the corresponding `_competitors/{vendor}.md` capability section. Smartlog cells trace to `inventory/_latest.json` feature entries by `feature_id`.

---

## Closing notes

- Matrix is **static snapshot** at commit `41b3863` (2026-05-22). Mode D (delta) will diff against this when re-run.
- Verdict assignment (KEEP / CATCH-UP / LEAPFROG / IGNORE) is **NOT in this file**. That belongs in Mode C `gap-analysis.md`.
- For sales/RFP support, each competitor's pricing + strengths/weaknesses sections in `_competitors/*.md` are the source-of-truth — use those, not this matrix's brief notes.
- Off-repo tenant MV (`projects/{tenant}/`) was not scanned this run; capability area #11 ClickHouse MV captured as feature only.

---

## Mandatory ending signals

- **MODE**: B (Benchmark)
- **ARTIFACT_PATHS**:
  - `projects/po/benchmark/2026-05-26-bi-capability-matrix.md` (this file)
  - `projects/po/_competitors/powerbi.md` (new)
  - `projects/po/_competitors/tableau.md` (new)
  - `projects/po/_competitors/looker.md` (new)
  - `projects/po/_competitors/superset.md` (new)
  - `projects/po/_competitors/metabase.md` (new)
  - `projects/po/_competitors/sisense.md` (new)
  - `projects/po/_competitors/qlik.md` (new)
- **BENCHMARK_SUMMARY**: 14 capability areas across 8 vendors. Smartlog leads in 2 areas (#7 self-service authoring, #12 AI/ML). Smartlog matches in ~8 areas. Smartlog behind in 3 areas (#1 connectors, #4 viz breadth, #13 mobile, #8 embedding polish). #14 pricing N/A. **2 verified via WebFetch** (Power BI Copilot, Tableau Pulse, Sisense embed page). **5 from training-cutoff knowledge + vendor docs URL roots** (Looker, Superset, Metabase, Qlik partial; doc 404 on Looker Studio Pro). All claims have evidence URL or `unverified` flag in baseline file.
- **GAP_VERDICT_BREAKDOWN**: Not produced in Mode B. Sketched in "Pre-gap surfacing" section; formal verdict assignment is Mode C output.
- **HANDOFF_QUEUE**: None yet. Mode C (`/da-po sweep`) will produce formal `GAP-NNN` IDs with handoff to `/da-discovery`.
- **NEXT_REFRESH_DUE**: 2026-06-25 (30-day TTL on `_competitors/*.md`); recommend running `/da-po delta` on **2026-06-02** to align with weekly cadence and catch any code changes on `feat-vfr-late-alert` branch.
