---
vendor: Sisense
slug: sisense
category: Embedded BI
last_refresh_date: 2026-05-26
last_refresh_commit_smartlog: 41b3863
sources_consulted:
  - https://docs.sisense.com/
  - https://www.sisense.com/pricing/
  - https://www.sisense.com/platform/embedded-analytics/
  - https://sisense.dev/
---

# Sisense — Capability baseline

## Profile

- **Vendor / Parent company**: Sisense Inc (private, Insight Partners-backed)
- **License**: Proprietary, quote-based
- **Deployment**: Cloud (Linux) + On-prem (Linux) + Embedded SDK (Compose SDK, Fusion Embed)
- **Primary user persona**: **ISV embedding analytics into product** — most similar to Smartlog model
- **Logistics-vertical presence**: Supply chain accelerator templates exist (Sisense Marketplace)

## Capability scores (14 areas)

### 1. Data Connectors
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://docs.sisense.com/main/SisenseLinux/data-connectors.htm
- **Notable**: 50+ native connectors + ElastiCube ETL engine for in-memory column store.
- **Smartlog comparable**: 3 features. Sisense broader.

### 2. Data Modeling
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://docs.sisense.com/main/SisenseLinux/elasticube-modeling.htm
- **Notable**: ElastiCube (proprietary columnar in-memory engine) + Live model (DirectQuery) + relationships + custom tables. Drag-drop modeler.
- **Smartlog comparable**: `semantic-registry` Beta.

### 3. Query Engine / Semantic Layer
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://docs.sisense.com/main/SisenseLinux/elasticube-overview.htm
- **Notable**: ElastiCube in-memory + Live (passthrough) modes. Formula language (Sisense's own).
- **Smartlog comparable**: SqlKata + Fluid + ClickHouse MV (different stack, similar end goal).

### 4. Visualization Library
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://docs.sisense.com/main/SisenseLinux/widgets.htm
- **Notable**: 30+ widget types + Custom Widget Plugin SDK + Compose SDK for React/Angular/Vue components.
- **Smartlog comparable**: 8 widgets.

### 5. Dashboard / Canvas
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://docs.sisense.com/main/SisenseLinux/dashboards.htm
- **Notable**: Drag-drop dashboard editor + tabs + filters + drill-down + JS scripting hooks.
- **Smartlog comparable**: Comparable concept.

### 6. Filtering & Parameters
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://docs.sisense.com/main/SisenseLinux/filters.htm
- **Notable**: Dashboard filters + widget filters + cross-filter + JAQL filter API.
- **Smartlog comparable**: Comparable.

### 7. Self-service Authoring
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://docs.sisense.com/main/SisenseLinux/creating-charts.htm
- **Notable**: Drag-drop chart creation + NL "Ask" assistant in Fusion. No notebook concept.
- **Smartlog comparable**: 6 features. Smartlog notebooks + tool-trace-replay differentiated.

### 8. Embedding & Sharing
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://www.sisense.com/platform/embedded-analytics/ (verified 2026-05-26), https://sisense.dev/
- **Notable**: **Compose SDK** (React/Angular/Vue components, pixel-perfect UX control) + **Fusion Embed** (iframe + JS SDK) + RLS via JWT + white-label. **This is Sisense's core differentiator.**
- **Smartlog comparable**: 4 features. **Sisense is the embedded BI reference Smartlog competes against most directly.**

### 9. Collaboration
- **Presence**: ◐
- **Depth**: Medium
- **Evidence**: https://docs.sisense.com/main/SisenseLinux/alerts.htm
- **Notable**: Alerts + Pulse (anomaly notifications) + scheduled reports. No commenting native.
- **Smartlog comparable**: 5 features. Smartlog LLM-attached alert richer.

### 10. Governance & RBAC
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://docs.sisense.com/main/SisenseLinux/data-security.htm
- **Notable**: Role-based + Data Security Rules (RLS) via JAQL filters + JWT SSO + multi-tenant architecture. Strong ISV story.
- **Smartlog comparable**: 7 features. Comparable; Sisense more battle-tested for multi-tenant ISV.

### 11. Performance & Scale
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://docs.sisense.com/main/SisenseLinux/elasticube-overview.htm
- **Notable**: ElastiCube columnar in-memory + build schedule + incremental builds. Different from VertiPaq but similar tier.
- **Smartlog comparable**: ClickHouse MV per-tenant — different stack.

### 12. AI / ML
- **Presence**: ✓
- **Depth**: Medium → trending Deep
- **Evidence**: https://docs.sisense.com/main/SisenseLinux/ai-features.htm (URL pattern; specific page unverified)
- **Notable**: Sisense Fusion AI: NL→chart assistant, anomaly detection, forecasting. Compose SDK + AI APIs for embedded LLM. Multi-LLM uncertain.
- **Smartlog comparable**: 11 features incl multi-LLM + golden SQL + eval harness. **Smartlog architecturally broader.**

### 13. Mobile / Responsive
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://docs.sisense.com/main/SisenseLinux/mobile.htm
- **Notable**: Sisense Mobile iOS/Android app + responsive web.
- **Smartlog comparable**: Web only. Gap.

### 14. Pricing & Deployment
- **Model**: Quote-based; estimated $25K–$100K+/year entry for Sisense + Fusion Embed; per-viewer pricing typical.
- **Entry tier**: Not public.
- **Embedded license**: Yes — Fusion Embed + Compose SDK are core products.
- **Evidence**: https://www.sisense.com/pricing/ (access date 2026-05-26; price not publicly listed)

## Strengths (top 3)
1. **Embedded SDK depth** — Compose SDK (component-level React/Angular) is industry-leading for ISV white-label.
2. **ElastiCube in-memory** — performance story for analytical workloads in embedded contexts.
3. **Multi-tenant battle-tested** — many SaaS products embed Sisense at scale.

## Weaknesses (top 3)
1. **Opaque pricing** — quote-based barrier for cost-sensitive SMB; tough comparison vs Metabase.
2. **AI features behind official docs gating** — public marketing strong but specific AI capability depth not transparent.
3. **Smaller ecosystem** — vs PowerBI/Tableau, fewer partners and integrations.

## Recent releases (window: last 90 days)
| Version | Date | Notable changes affecting capability matrix |
|---|---|---|
| Sisense Fusion 2025+ | Ongoing | Compose SDK improvements; AI capabilities ramp. Specific 2026 Q1/Q2 unverified. |

## Relevance lens — logistics SaaS

| Area | Vì sao quan trọng cho Smartlog |
|---|---|
| 8. Embedding | **Sisense is the closest competitor model to Smartlog** — same ISV embedded play; Compose SDK is benchmark for Smartlog's embedded story |
| 10. Multi-tenant | Sisense JWT-based tenant isolation = same playbook as Smartlog `TenantDBConfiguration` claim |
| 14. Pricing | Sisense quote-based at $25K+ creates pricing umbrella above Metabase — Smartlog can position between |

## Open questions / unverified
- Q: Specific Sisense Fusion AI capability depth (verified docs gated behind login)?
- Q: Current Compose SDK supported framework versions (React 19? Vue 3?)?
- Q: Sisense AI multi-LLM support — Azure OpenAI only or Anthropic/etc.?

## Refresh log
| Date | Refreshed by | What changed |
|---|---|---|
| 2026-05-26 | da-po Mode B | Initial baseline; embedded analytics platform page verified |
