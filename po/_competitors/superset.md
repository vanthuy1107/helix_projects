---
vendor: Apache Superset
slug: superset
category: OSS BI
last_refresh_date: 2026-05-26
last_refresh_commit_smartlog: 41b3863
sources_consulted:
  - https://superset.apache.org/docs/
  - https://github.com/apache/superset
  - https://preset.io/pricing/
---

# Apache Superset — Capability baseline

## Profile

- **Vendor / Parent company**: Apache Software Foundation (created at Airbnb 2015); Preset is commercial managed Superset
- **License**: Apache 2.0 (OSS) — full source available
- **Deployment**: Self-host only (Docker/K8s) + Preset managed cloud
- **Primary user persona**: OSS power user, data engineer; analytics teams allergic to per-user licensing
- **Logistics-vertical presence**: None — generic BI

## Capability scores (14 areas)

### 1. Data Connectors
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://superset.apache.org/docs/configuration/databases
- **Notable**: 40+ SQLAlchemy dialects (Postgres, MySQL, Snowflake, BigQuery, Trino, Druid, ClickHouse). SQLAlchemy-based — wide DB compat, no REST/file/streaming first-class.
- **Smartlog comparable**: 3 features. Comparable DB breadth via EF.

### 2. Data Modeling
- **Presence**: ◐
- **Depth**: Medium
- **Evidence**: https://superset.apache.org/docs/using-superset/exploring-data
- **Notable**: Datasets (virtual + physical) + computed columns + metrics defined per dataset. No semantic layer across datasets; no LookML equivalent.
- **Smartlog comparable**: `semantic-registry` Beta — Smartlog's semantic layer is actually more structured than Superset's flat dataset model.

### 3. Query Engine / Semantic Layer
- **Presence**: ◐
- **Depth**: Medium
- **Evidence**: https://superset.apache.org/docs/configuration/sql-templating
- **Notable**: Jinja templating in SQL + SQLAlchemy pushdown. No native semantic layer; Preset has feature called "Semantic Layer" (newer).
- **Smartlog comparable**: SqlKata + Fluid is conceptually similar to Jinja+SQLAlchemy.

### 4. Visualization Library
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://superset.apache.org/docs/using-superset/exploring-data#chart-types
- **Notable**: 40+ chart types (echarts-based) + plugin SDK for custom viz. Generally well-regarded for chart variety in OSS.
- **Smartlog comparable**: 8 logistics widgets — narrower but domain-specific.

### 5. Dashboard / Canvas
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://superset.apache.org/docs/using-superset/creating-your-first-dashboard
- **Notable**: Drag-drop dashboards + filters + tabs. Less polished than Tableau/PowerBI.
- **Smartlog comparable**: react-grid-layout comparable.

### 6. Filtering & Parameters
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://superset.apache.org/docs/using-superset/native-filters
- **Notable**: Native filter system (refactored 2021) + cross-filter + filter sets. Less mature than commercial vendors.
- **Smartlog comparable**: 3 features. Roughly similar level.

### 7. Self-service Authoring
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://superset.apache.org/docs/using-superset/exploring-data
- **Notable**: Explore page (drag-drop) + SQL Lab (in-app SQL editor with autocomplete, save query as virtual dataset). No chat/NL → SQL out-of-box.
- **Smartlog comparable**: Smartlog has chat + notebook + KPI templates — broader.

### 8. Embedding & Sharing
- **Presence**: ◐
- **Depth**: Medium
- **Evidence**: https://superset.apache.org/docs/configuration/setup-ssh-tunneling/, https://docs.preset.io/docs/embedding-an-superset-dashboard
- **Notable**: Embedded SDK exists (community-supported); iframe; export CSV/Excel; scheduled email reports via Alerts & Reports feature.
- **Smartlog comparable**: 4 features — Smartlog has Slack integration + scheduled reports; Superset comparable.

### 9. Collaboration
- **Presence**: ◐
- **Depth**: Shallow
- **Evidence**: https://superset.apache.org/docs/configuration/alerts-reports
- **Notable**: Alerts & Reports (threshold + scheduled). No commenting, no @-mention.
- **Smartlog comparable**: 5 features (monitors, alerts, notifications, message-feedback, actions). Smartlog richer.

### 10. Governance & RBAC
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://superset.apache.org/docs/security/security
- **Notable**: Flask-AppBuilder roles + dataset-level + row-level security (Jinja templated). SSO via LDAP/OAuth.
- **Smartlog comparable**: 7 features. Comparable.

### 11. Performance & Scale
- **Presence**: ◐
- **Depth**: Medium
- **Evidence**: https://superset.apache.org/docs/configuration/cache
- **Notable**: Cache layer (Redis) + warehouse pushdown. No in-memory column engine. Async query support (Celery).
- **Smartlog comparable**: ClickHouse MV — different stack but similar end.

### 12. AI / ML
- **Presence**: ✗
- **Depth**: Shallow (community plugins only)
- **Evidence**: https://github.com/apache/superset/issues (search "AI")
- **Notable**: No native AI/NL features in upstream Apache Superset as of 2025. Preset cloud has experimental "AI Assist" preview but unverified depth.
- **Smartlog comparable**: 11 features. **Massive Smartlog advantage in this area.**

### 13. Mobile / Responsive
- **Presence**: ◐
- **Depth**: Shallow
- **Evidence**: https://superset.apache.org/docs/faq#how-can-i-see-individual-records-on-the-explore-view
- **Notable**: Responsive but not optimized for mobile; no native app.
- **Smartlog comparable**: Comparable.

### 14. Pricing & Deployment
- **Model**: Apache Superset FREE (Apache 2.0). Preset cloud: Starter free → Pro $20/user/mo → Enterprise quote-based.
- **Entry tier**: $0 (self-host) or $0 Preset Starter.
- **Embedded license**: Yes — Preset Embedded; Apache OSS license permits embedding free.
- **Evidence**: https://preset.io/pricing/ (access date 2026-05-26)

## Strengths (top 3)
1. **OSS — no per-user fee** — economics unbeatable for cost-sensitive teams.
2. **Chart library breadth** — 40+ chart types via echarts is competitive with Tableau.
3. **SQL Lab** — strong in-app SQL editor with virtual dataset workflow.

## Weaknesses (top 3)
1. **No AI/NL features** — 2026 BI market expects copilot; Superset has none upstream.
2. **Self-host operational burden** — Celery, Redis, Postgres metadata DB, Gunicorn. Heavy.
3. **No semantic layer** — flat dataset model; cross-dashboard reuse weak.

## Recent releases (window: last 90 days)
| Version | Date | Notable changes affecting capability matrix |
|---|---|---|
| Superset 4.x ongoing | 2025-2026 | Chart engine improvements; AI features remain plugin-level. Specific 2026 Q1/Q2 unverified. |

## Relevance lens — logistics SaaS

| Area | Vì sao quan trọng cho Smartlog |
|---|---|
| 12. AI gap | Superset's biggest gap = Smartlog's biggest moat opportunity for cost-conscious ISV positioning |
| 14. Pricing | Superset OSS sets price floor — Smartlog must justify proprietary value above $0 |

## Open questions / unverified
- Q: Preset's "AI Assist" current depth and pricing tier inclusion?
- Q: Apache Superset upstream 2026 roadmap re: AI/NL?

## Refresh log
| Date | Refreshed by | What changed |
|---|---|---|
| 2026-05-26 | da-po Mode B | Initial baseline |
