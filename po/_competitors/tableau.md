---
vendor: Tableau
slug: tableau
category: Enterprise BI
last_refresh_date: 2026-05-26
last_refresh_commit_smartlog: 41b3863
sources_consulted:
  - https://help.tableau.com/
  - https://help.tableau.com/current/online/en-us/pulse_intro.htm
  - https://www.tableau.com/pricing
  - https://www.tableau.com/developer/learning/embed-analytics-application
---

# Tableau — Capability baseline

## Profile

- **Vendor / Parent company**: Salesforce (acquired 2019, $15.7B)
- **Founded / acquired**: 2003, IPO 2013, acq 2019
- **License**: Proprietary
- **Deployment**: Tableau Cloud (SaaS) + Tableau Server (self-host) + Tableau Public (free, public-only) + Embedded
- **Primary user persona**: Power analyst, viz-first workflows; "Show Me" visual exploration
- **Logistics-vertical presence**: Generic; supply chain accelerators via Tableau Exchange

## Capability scores (14 areas)

### 1. Data Connectors
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.tableau.com/current/pro/desktop/en-us/exampleconnections_overview.htm
- **Notable**: 100+ native connectors + Web Data Connector SDK + Tableau Connector SDK (TDC). Native to Salesforce stack.
- **Smartlog comparable**: 3 features. Smartlog far narrower.

### 2. Data Modeling
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.tableau.com/current/pro/desktop/en-us/datasource_datamodel.htm
- **Notable**: Logical/physical layer separation; relationships (no FK required); calculated fields (Tableau's own dialect); Hyper data engine.
- **Smartlog comparable**: `semantic-registry` Beta — similar concept, smaller surface.

### 3. Query Engine / Semantic Layer
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.tableau.com/current/api/vizql-data-service/en-us/index.html
- **Notable**: Hyper in-memory + Tableau VizQL Data Service (REST endpoint for headless query); live + extract modes.
- **Smartlog comparable**: `dynamic-query-engine` (SqlKata + Fluid). Different paradigm — JSON config-driven vs Hyper engine.

### 4. Visualization Library
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.tableau.com/current/pro/desktop/en-us/dataview_examples.htm
- **Notable**: "Show Me" visual chooser + 24 built-in chart types + viz-of-the-day community + extensions API. Industry-standard for viz polish.
- **Smartlog comparable**: 8 widgets (logistics-specific) + chart-auto-detect Beta. **Smartlog chart-auto-detect is closer to Show Me than Metabase/Superset patterns.**

### 5. Dashboard / Canvas
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.tableau.com/current/pro/desktop/en-us/dashboards.htm
- **Notable**: Floating + tiled layouts, device-specific dashboards, actions (filter/highlight/URL/parameter), story points.
- **Smartlog comparable**: react-grid-layout drag-drop. Tiled only; no story points.

### 6. Filtering & Parameters
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.tableau.com/current/pro/desktop/en-us/filtering.htm
- **Notable**: Quick filters, context filters, data source filters, parameter actions, set actions. Cross-filter inherent.
- **Smartlog comparable**: Similar concept, far less depth.

### 7. Self-service Authoring
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.tableau.com/current/pro/desktop/en-us/buildexamples_overview.htm
- **Notable**: Drag-drop pill-based authoring (signature UX). Ask Data deprecated 2024; replaced by Pulse Q&A. No notebook concept.
- **Smartlog comparable**: 6 features including notebooks + chat. **Notebooks = differentiator vs Tableau.**

### 8. Embedding & Sharing
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.tableau.com/current/api/embedding_api/en-us/index.html
- **Notable**: Embedding API v3 (web component) + Connected Apps for SSO + RLS pass-through + Tabcmd export PDF/PNG/CSV.
- **Smartlog comparable**: 4 features. Client-side export only.

### 9. Collaboration
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://help.tableau.com/current/pro/desktop/en-us/comment.htm
- **Notable**: Comments per view + subscriptions + data-driven alerts (threshold).
- **Smartlog comparable**: 5 features including LLM-attached alerts — Smartlog richer in alert intelligence.

### 10. Governance & RBAC
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.tableau.com/current/server/en-us/permissions.htm
- **Notable**: Projects → Workbooks → Views permission model; row-level security via user filters or RLS data policies; SAML/OIDC SSO.
- **Smartlog comparable**: 7 features. Comparable model.

### 11. Performance & Scale
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.tableau.com/current/online/en-us/extracts_intro.htm
- **Notable**: Hyper extract engine + incremental refresh + Bridge for on-prem-to-cloud + materialized views (Cloud).
- **Smartlog comparable**: ClickHouse MV per-tenant (functionally similar end goal).

### 12. AI / ML
- **Presence**: ✓
- **Depth**: Medium → trending Deep
- **Evidence**: https://help.tableau.com/current/online/en-us/pulse_intro.htm (verified 2026-05-26)
- **Notable**: **Tableau Pulse** — metric subscriptions, anomaly detection, NL Q&A (Ask Q&A + Enhanced Q&A AI-powered, latter needs Tableau+ tier), Slack/email digests. **Tableau Cloud only — not Server**. Einstein Discovery (Salesforce ML) for predictive.
- **Smartlog comparable**: 11 AI/ML features. **Smartlog architecturally broader** (eval harness, error graph, user-memory, multi-LLM); Tableau Pulse more polished UX.

### 13. Mobile / Responsive
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://www.tableau.com/products/mobile
- **Notable**: Native iOS/Android, device-specific dashboard layouts, offline favorites.
- **Smartlog comparable**: Web responsive only. Gap.

### 14. Pricing & Deployment
- **Model**: Per-user role-based (Creator $75/user/mo, Explorer $42, Viewer $15). Tableau+ premium tier for Enhanced Q&A and forecasting.
- **Entry tier**: Viewer $15/user/mo.
- **Embedded license**: Yes — Tableau Embedded Analytics; separate license model (priced by usage and capacity).
- **Evidence**: https://www.tableau.com/pricing/teams-orgs (access date 2026-05-26)

## Strengths (top 3)
1. **Visualization polish** — gold standard for chart aesthetics and exploratory UX.
2. **Pulse** — metric-following + anomaly + Q&A digest is well-thought-out 2025 product direction.
3. **Salesforce ecosystem** — Einstein, MuleSoft, Data Cloud integration.

## Weaknesses (top 3)
1. **Pulse Tableau Cloud only** — Server customers cut off from latest AI; embedded customers stuck on older paradigm.
2. **Per-user pricing high** — $75 Creator price is hard sell for embedded ISV use case.
3. **No notebook / NL→SQL via chat** — Pulse is metric-following + Q&A, not free-form NL→SQL artifact authoring.

## Recent releases (window: last 90 days)
| Version | Date | Notable changes affecting capability matrix |
|---|---|---|
| Pulse Enhanced Q&A | 2025–2026 ramp | AI-powered NL Q&A behind Tableau+ tier (verified) |
| Other 2026 Q1/Q2 | 2026-Q1..Q2 | Unverified — Tableau release notes not refreshed in this baseline |

## Relevance lens — logistics SaaS

| Area | Vì sao quan trọng cho Smartlog |
|---|---|
| 7. Self-service | Tableau strong in drag-drop authoring; Smartlog's chat + notebook combo addresses *different* persona (chat-first business user) |
| 8. Embedding | Tableau Embedded works but pricing tough; Smartlog's per-tenant native embedding is unit-economics advantage |
| 12. AI | Pulse + Enhanced Q&A is direction of travel — Smartlog multi-LLM + golden SQL + eval harness is architecturally further but UX gap |

## Open questions / unverified
- Q: Current exact Tableau+ tier pricing delta vs Creator base? (need vendor quote)
- Q: Tableau Cloud Pulse vs Tableau Server gap — when (if ever) will Pulse arrive on Server? (Salesforce direction: Cloud-first)
- Q: Any 2026 Q1/Q2 Pulse capability expansions beyond what verified doc covered?

## Refresh log
| Date | Refreshed by | What changed |
|---|---|---|
| 2026-05-26 | da-po Mode B | Initial baseline; Pulse intro verified via WebFetch |
