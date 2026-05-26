---
vendor: Metabase
slug: metabase
category: Freemium BI (OSS + Cloud)
last_refresh_date: 2026-05-26
last_refresh_commit_smartlog: 41b3863
sources_consulted:
  - https://www.metabase.com/docs/
  - https://www.metabase.com/pricing/
  - https://www.metabase.com/learn/metabase-basics/embedding
---

# Metabase — Capability baseline

## Profile

- **Vendor / Parent company**: Metabase Inc (formerly stewarded by Expa, now independent)
- **License**: Dual — OSS (AGPL v3) + Cloud + Pro/Enterprise (commercial)
- **Deployment**: Self-host (Docker/jar) free + Cloud Starter $85/mo + Pro + Enterprise
- **Primary user persona**: Citizen analyst, lightweight BI; startup-friendly
- **Logistics-vertical presence**: None — generic BI for SMB and embedded ISV

## Capability scores (14 areas)

### 1. Data Connectors
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://www.metabase.com/docs/latest/databases/connecting
- **Notable**: 20+ official drivers (Postgres, MySQL, BigQuery, Snowflake, Redshift, Mongo, Druid). Community drivers for more. SQL-warehouse first.
- **Smartlog comparable**: 3 features. Comparable in breadth.

### 2. Data Modeling
- **Presence**: ◐
- **Depth**: Medium
- **Evidence**: https://www.metabase.com/docs/latest/data-modeling/models
- **Notable**: "Models" (saved questions promoted to reusable dataset) + metric definitions + segment definitions. Lightweight semantic layer.
- **Smartlog comparable**: `semantic-registry` Beta — comparable lightweight semantic concept.

### 3. Query Engine / Semantic Layer
- **Presence**: ◐
- **Depth**: Medium
- **Evidence**: https://www.metabase.com/docs/latest/questions/query-builder/introduction
- **Notable**: Query Builder (no-code) + SQL editor; warehouse pushdown. No in-memory engine.
- **Smartlog comparable**: SqlKata + Fluid.

### 4. Visualization Library
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://www.metabase.com/docs/latest/questions/visualizations/visualizing-results
- **Notable**: 18 chart types (line, bar, area, scatter, map, funnel, pivot, smartscalar). No custom viz SDK.
- **Smartlog comparable**: 8 widgets. Smartlog more domain-tailored; Metabase more generic-chart-library.

### 5. Dashboard / Canvas
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://www.metabase.com/docs/latest/dashboards/start
- **Notable**: Drag-drop grid, tabs, filters, parameter mappings. Less polished than Tableau/PowerBI.
- **Smartlog comparable**: Comparable.

### 6. Filtering & Parameters
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://www.metabase.com/docs/latest/dashboards/filters
- **Notable**: Dashboard filters + linked filters + cross-filter via click behavior.
- **Smartlog comparable**: Comparable.

### 7. Self-service Authoring
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://www.metabase.com/docs/latest/questions/query-builder/introduction
- **Notable**: **Best-in-class no-code Query Builder for SMB**. Citizen analyst sweet spot. X-rays auto-explore feature.
- **Smartlog comparable**: 6 features. Metabase X-rays vs Smartlog chart-auto-detect — different approach.

### 8. Embedding & Sharing
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://www.metabase.com/docs/latest/embedding/start
- **Notable**: **Static embedding** (free), **interactive embedding** (Pro/Enterprise), JWT-signed embed tokens, dashboard subscriptions, public links. Strong ISV story at price point.
- **Smartlog comparable**: 4 features. Metabase embedding is more polished for ISV use case at this price.

### 9. Collaboration
- **Presence**: ◐
- **Depth**: Medium
- **Evidence**: https://www.metabase.com/docs/latest/questions/sharing/alerts
- **Notable**: Alerts (threshold) + dashboard subscriptions (email/Slack) + question pinning. No commenting.
- **Smartlog comparable**: 5 features. Smartlog richer in alert intelligence (LLM analysis).

### 10. Governance & RBAC
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://www.metabase.com/docs/latest/permissions/start
- **Notable**: Group-based data permissions + sandboxing (row-level via attribute mapping, Pro/Enterprise only). Audit log Enterprise-only.
- **Smartlog comparable**: 7 features. Comparable.

### 11. Performance & Scale
- **Presence**: ◐
- **Depth**: Medium
- **Evidence**: https://www.metabase.com/docs/latest/configuring-metabase/caching
- **Notable**: Caching (Redis or DB-backed) + query timeout config. No in-memory engine. Materialized view delegation to warehouse.
- **Smartlog comparable**: ClickHouse MV per-tenant.

### 12. AI / ML
- **Presence**: ◐
- **Depth**: Shallow → Medium (2025+)
- **Evidence**: https://www.metabase.com/blog/metabot-faq (Metabase has "Metabot" AI feature)
- **Notable**: Metabot (NL → query for SQL questions); X-rays auto-explore is rule-based (not ML). 2024+ direction adds AI in Cloud Pro.
- **Smartlog comparable**: 11 features. Smartlog much broader architecturally.

### 13. Mobile / Responsive
- **Presence**: ◐
- **Depth**: Shallow
- **Evidence**: https://www.metabase.com/docs/latest/dashboards/introduction
- **Notable**: Web responsive; no native app. Mobile-friendly dashboard layout option.
- **Smartlog comparable**: Comparable.

### 14. Pricing & Deployment
- **Model**: Self-host OSS free → Cloud Starter $85/mo (5 users) → Pro $500/mo → Enterprise quote.
- **Entry tier**: $0 (self-host OSS) or $85/mo Cloud Starter.
- **Embedded license**: Yes — Pro/Enterprise interactive embedding; static embedding included free.
- **Evidence**: https://www.metabase.com/pricing/ (access date 2026-05-26)

## Strengths (top 3)
1. **Citizen analyst UX** — best-in-class no-code Query Builder for SMB and non-technical user.
2. **Embedding economics** — JWT signed embed for ISVs at $500/mo Pro is unbeatable mid-market.
3. **OSS option** — full AGPL source available for self-host customers.

## Weaknesses (top 3)
1. **No semantic layer beyond Models** — cross-source unified metric weaker than Looker/PowerBI.
2. **Limited governance in OSS tier** — sandboxing, audit log are paid-tier gated.
3. **AI/ML still shallow vs PowerBI/Tableau** — Metabot is in development.

## Recent releases (window: last 90 days)
| Version | Date | Notable changes affecting capability matrix |
|---|---|---|
| Metabase 0.50+ ongoing | 2024-2026 | Metabot iterations, embedding improvements. Specific 2026 Q1/Q2 unverified. |

## Relevance lens — logistics SaaS

| Area | Vì sao quan trọng cho Smartlog |
|---|---|
| 8. Embedding | **Metabase is the embedded BI price benchmark Smartlog competes against** — many logistics ISVs use Metabase as cheap embedded option |
| 14. Pricing | $85/mo Starter sets SMB floor — Smartlog's per-tenant value must clear this bar |

## Open questions / unverified
- Q: Metabase 0.5x exact current version + Metabot GA status?
- Q: Interactive embedding 2026 Q1/Q2 capability additions?

## Refresh log
| Date | Refreshed by | What changed |
|---|---|---|
| 2026-05-26 | da-po Mode B | Initial baseline |
