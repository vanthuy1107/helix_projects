---
vendor: Microsoft Power BI
slug: powerbi
category: Enterprise BI
last_refresh_date: 2026-05-26
last_refresh_commit_smartlog: 41b3863
sources_consulted:
  - https://learn.microsoft.com/en-us/power-bi/
  - https://learn.microsoft.com/en-us/power-bi/create-reports/copilot-introduction
  - https://azure.microsoft.com/pricing/details/microsoft-fabric/
  - https://learn.microsoft.com/en-us/power-bi/enterprise/service-premium-what-is
  - https://learn.microsoft.com/en-us/power-bi/developer/embedded/
---

# Microsoft Power BI — Capability baseline

## Profile

- **Vendor / Parent company**: Microsoft
- **Founded / acquired**: Power BI launched 2014; absorbed into Microsoft Fabric platform (2023+)
- **License**: Proprietary
- **Deployment**: Power BI Service (SaaS) + Desktop (free authoring) + Power BI Embedded (Azure capacity) + Power BI Report Server (on-prem)
- **Primary user persona**: Enterprise analyst, IT-led BI, Microsoft 365 / Azure shops
- **Logistics-vertical presence**: Generic — no native logistics templates; community/partner templates exist

## Capability scores (14 areas)

### 1. Data Connectors
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://learn.microsoft.com/en-us/power-query/connectors/
- **Notable**: 200+ Power Query connectors (SQL Server, Snowflake, SAP, Salesforce, REST, OData, file, streaming). Connector SDK + certification path.
- **Smartlog comparable**: Smartlog has 3 features (data-sources, multi-tenant-resolver, refit clients). Far smaller breadth — ~3 RDBMS providers via EF Core + Refit clients for Smartlog ecosystem.

### 2. Data Modeling
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://learn.microsoft.com/en-us/dax/, https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-modeling-view
- **Notable**: DAX measures + calculated columns + visual modeling view (star/snowflake); semantic model versioning via Fabric workspace.
- **Smartlog comparable**: `semantic-registry` (Beta) — equivalent in concept (Dimensions/Metrics/Relationships/TestCase) but lighter. DAX is much deeper than Smartlog's metric language.

### 3. Query Engine / Semantic Layer
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://learn.microsoft.com/en-us/analysis-services/tabular-models/tabular-model-solution-deployment-ssas-tabular
- **Notable**: VertiPaq columnar engine in-memory + DirectQuery passthrough + composite models. DAX is *the* semantic language of Microsoft BI ecosystem.
- **Smartlog comparable**: `dynamic-query-engine` (SqlKata + Fluid) — pushdown SQL, but no in-memory engine; relies on ClickHouse MV for performance.

### 4. Visualization Library
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://learn.microsoft.com/en-us/power-bi/visuals/, https://appsource.microsoft.com/marketplace/apps?product=power-bi-visuals
- **Notable**: 30+ built-in visuals + AppSource marketplace (~700 custom visuals) + Smart Narrative + R/Python viz.
- **Smartlog comparable**: 8 logistics-specific widgets + chart-auto-detect Beta. Much narrower chart library but deeper domain semantics.

### 5. Dashboard / Canvas
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://learn.microsoft.com/en-us/power-bi/create-reports/service-dashboards
- **Notable**: Reports (multi-page) + Dashboards (pinned) + Apps (curated bundles) + Drill-through + Bookmarks + Sync slicers.
- **Smartlog comparable**: `dashboard-core` (react-grid-layout) + folders + permissions + AI assist. Single-page primarily.

### 6. Filtering & Parameters
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://learn.microsoft.com/en-us/power-bi/create-reports/power-bi-report-filter, https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-dynamic-format-strings
- **Notable**: Slicers, page/report/visual-level filters, field parameters, what-if parameters, URL filter state. Cross-filter implicit between visuals.
- **Smartlog comparable**: `widget-filter-resolver` + `cross-filter-safe` + `widget-parameters`. Similar concept, less polished interaction model.

### 7. Self-service Authoring
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-quick-measure, https://learn.microsoft.com/en-us/power-bi/create-reports/copilot-introduction
- **Notable**: Power BI Desktop (free) + Q&A natural language visual + Quick measures + Smart Narrative + Copilot (NL→DAX, summarize, narrative). No notebook concept.
- **Smartlog comparable**: 6 features — chat-conversations, notebooks (Beta, Jupyter-style), form-configs, monaco-sql-editor, kpi-templates, tool-trace-replay. **Smartlog notebooks + tool-trace-replay = unusual**; PowerBI has no equivalent.

### 8. Embedding & Sharing
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://learn.microsoft.com/en-us/power-bi/developer/embedded/embedded-analytics-power-bi, https://learn.microsoft.com/en-us/power-bi/collaborate-share/service-create-the-new-workspaces
- **Notable**: Power BI Embedded SKU (A/EM capacity) + iframe + JS SDK + RLS pass-through + scheduled subscriptions + export to PDF/PPT/Excel. Pricing-gated (Embedded capacity).
- **Smartlog comparable**: `share-resource` + `scheduled-reports` + `slack-integration` + `export-pdf-excel`. Client-side export only — no pixel-perfect server render.

### 9. Collaboration
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://learn.microsoft.com/en-us/power-bi/collaborate-share/service-create-distribute-apps, https://learn.microsoft.com/en-us/power-bi/create-reports/service-subscribe
- **Notable**: Comments per visual + @-mention + Teams integration + subscriptions. Data Alerts (numeric threshold) limited to dashboard tile.
- **Smartlog comparable**: `monitors` + `alerts` + `notifications` + `message-feedback` + `actions`. Smartlog has **LLM-attached alerts** (LlmAnalysisResult) — PowerBI does not.

### 10. Governance & RBAC
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://learn.microsoft.com/en-us/power-bi/enterprise/service-admin-rls, https://learn.microsoft.com/en-us/power-bi/enterprise/service-security-microsoft-information-protection-overview, https://learn.microsoft.com/en-us/fabric/admin/service-admin-portal
- **Notable**: Workspace + dataset + report + RLS + OLS (object-level security) + Sensitivity labels (MIP) + Audit log (M365). Multi-tenant via Azure AD.
- **Smartlog comparable**: 7 features (users, roles, security-groups, tenant-branding, rate-limits, activity-log, admin-features). Tenant isolation via JWT claim. Less mature than MIP.

### 11. Performance & Scale
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://learn.microsoft.com/en-us/power-bi/guidance/aggregations, https://learn.microsoft.com/en-us/power-bi/connect-data/incremental-refresh-overview
- **Notable**: VertiPaq + aggregations + incremental refresh + composite models. Premium has dedicated capacity.
- **Smartlog comparable**: `embedding-cache` + `background-jobs` + `file-storage` + `clickhouse-mv-tenant`. Different stack (CH MV instead of in-memory column store).

### 12. AI / ML
- **Presence**: ✓
- **Depth**: Deep (Copilot) but **single-vendor (Azure OpenAI)**
- **Evidence**: https://learn.microsoft.com/en-us/power-bi/create-reports/copilot-introduction (verified 2026-03-23: requires Fabric F2+ or Premium P1+, Pro insufficient)
- **Notable**: Copilot for Power BI: standalone full-screen, in-report pane, in-app, DAX generation, narrative visual, semantic model description, summarize report. AI insights: Key Influencers, Decomposition Tree, AutoML in Fabric. **Hard tied to Azure OpenAI / Fabric capacity** (no multi-LLM choice).
- **Smartlog comparable**: 11 features in AI/ML bucket. **Multi-LLM provider** (`llm-providers`) + `golden-sql-library` + `error-graph` + `evaluation-harness` + `user-memory` + `knowledge-rag`. Less polished UX than Copilot today but architecturally vendor-neutral. LEAPFROG opportunities.

### 13. Mobile / Responsive
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://learn.microsoft.com/en-us/power-bi/consumer/mobile/
- **Notable**: Native iOS + Android + Windows apps. Mobile-optimized report layout designer.
- **Smartlog comparable**: `responsive-web` only. No native app. **Gap vs PowerBI.**

### 14. Pricing & Deployment
- **Model**: Per-user (Pro $14/user/mo, PPU $24/user/mo) + per-capacity (Fabric F2 ~$262/mo, Premium P1) + Embedded SKUs (A1/A2/...). Free desktop authoring.
- **Entry tier**: Pro $14/user/mo for cloud sharing. **Copilot requires Fabric F2+ or Premium P1+ (capacity-based, not Pro).**
- **Embedded license**: Yes — Power BI Embedded via Azure capacity (A SKU, pay-per-hour) or Premium capacity. App-owns-data model for ISVs.
- **Evidence**: https://www.microsoft.com/en-us/power-platform/products/power-bi/pricing (access date 2026-05-26)

## Strengths (top 3)
1. **Ecosystem lock-in** — first-class integration with M365, Azure, Excel, Teams; massive partner network.
2. **DAX + VertiPaq depth** — semantic layer + in-memory engine is industry-leading for relational analytics.
3. **Copilot with paying-customer scale** — verified 2026-03 release notes show standalone Copilot GA in many regions.

## Weaknesses (top 3)
1. **AI/Copilot gated behind capacity SKU** — requires Fabric F2+ or Premium P1+; cost barrier for ISVs and SMB.
2. **Single-LLM vendor (Azure OpenAI)** — no multi-provider abstraction; cannot route Copilot to Anthropic/Voyage. Multi-tenant ISVs cannot hand customers their own model.
3. **Embedded license cost** — per-capacity model expensive for per-tenant ISV like Smartlog (Sisense / Looker Studio Pro more flexible at small scale).

## Recent releases (window: last 90 days)
| Version | Date | Notable changes affecting capability matrix |
|---|---|---|
| Power BI March 2026 | 2026-03 | Copilot standalone GA expansion; 10k char prompt limit; app-scoped Copilot in apps (preview) |
| Power BI April–May 2026 | 2026-04..05 | Unverified — release notes not fetched in this baseline |

## Relevance lens — logistics SaaS

| Area | Vì sao quan trọng cho Smartlog |
|---|---|
| 8. Embedding | PowerBI Embedded SKU exists but expensive at per-tenant unit economics |
| 10. Multi-tenant | RLS + workspace isolation strong but ties to Azure AD; Smartlog's JWT-claim tenant routing is independent |
| 12. AI vendor lock-in | PowerBI Copilot = Azure OpenAI only → Smartlog's `llm-providers` multi-vendor is a real differentiator for tenants with vendor-neutrality requirements |
| 14. Pricing | Per-capacity model is the natural blocker for cost-sensitive logistics ISV use case |

## Open questions / unverified
- Q: Did April–May 2026 Power BI release notes change anything material in this matrix? (release notes not fetched in initial baseline)
- Q: Current Fabric F2 capacity SAR/USD pricing precise figure (estimate ~$262/mo; verify before quoting).
- Q: Does Copilot now support non-English prompts in GA? (March 2026 doc says "occasionally returns relevant responses" — not officially supported)

## Refresh log
| Date | Refreshed by | What changed |
|---|---|---|
| 2026-05-26 | da-po Mode B | Initial baseline; Copilot intro page verified via WebFetch |
