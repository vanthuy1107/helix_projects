---
vendor: Qlik Sense
slug: qlik
category: Enterprise BI
last_refresh_date: 2026-05-26
last_refresh_commit_smartlog: 41b3863
sources_consulted:
  - https://help.qlik.com/
  - https://www.qlik.com/us/pricing
  - https://www.qlik.com/us/products/qlik-cloud-analytics
---

# Qlik Sense — Capability baseline

## Profile

- **Vendor / Parent company**: Qlik Inc (Thoma Bravo owned since 2016)
- **License**: Proprietary
- **Deployment**: Qlik Cloud (SaaS) + Client-Managed (on-prem, formerly Qlik Sense Enterprise on Windows/Linux) + Embedded
- **Primary user persona**: Enterprise analyst; "associative engine" workflows for guided exploration
- **Logistics-vertical presence**: Supply chain Qlik Accelerator templates exist

## Capability scores (14 areas)

### 1. Data Connectors
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.qlik.com/en-US/connectors/Content/Connectors_QlikConnectors/Introduction/Introduction.htm
- **Notable**: 100+ connectors + Qlik Data Gateway + Qlik Data Integration (formerly Attunity, full CDC/replication).
- **Smartlog comparable**: 3 features. Qlik broader.

### 2. Data Modeling
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.qlik.com/en-US/sense/Subsystems/Hub/Content/Sense_Hub/LoadData/data-modeling.htm
- **Notable**: **Associative model** — Qlik's signature: all tables linked by field name; users explore via selections, not pre-built joins. Distinct paradigm.
- **Smartlog comparable**: `semantic-registry` Beta — relational model, not associative.

### 3. Query Engine / Semantic Layer
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.qlik.com/en-US/sense/Subsystems/Hub/Content/Sense_Hub/Scripting/scripting.htm
- **Notable**: Qlik Associative Engine (in-memory, indexed all-vs-all) + Qlik Script load language.
- **Smartlog comparable**: SqlKata + Fluid. Different paradigm (relational pushdown vs associative in-memory).

### 4. Visualization Library
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.qlik.com/en-US/sense/Subsystems/Hub/Content/Sense_Hub/Visualizations/visualizations.htm
- **Notable**: 25+ built-in + custom extensions + Vizlib (third-party premium viz set).
- **Smartlog comparable**: 8 widgets.

### 5. Dashboard / Canvas
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.qlik.com/en-US/sense/Subsystems/Hub/Content/Sense_Hub/Apps/build-app.htm
- **Notable**: "Sheets" (dashboards) within apps; Stories for guided narrative; Bookmarks for state.
- **Smartlog comparable**: Comparable concept.

### 6. Filtering & Parameters
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.qlik.com/en-US/sense/Subsystems/Hub/Content/Sense_Hub/Visualizations/FilterPane/filterpane.htm
- **Notable**: **Selection-based filtering** is signature — click anything, everything filters. Filter pane + bookmarks + alternate states.
- **Smartlog comparable**: cross-filter-safe + widget-filter-resolver. Smartlog widget-level cross-filter, Qlik global associative.

### 7. Self-service Authoring
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.qlik.com/en-US/sense/Subsystems/Hub/Content/Sense_Hub/CreateApp/Create-app-overview.htm
- **Notable**: Drag-drop sheet builder + Insight Advisor (NL → chart suggestion). No notebook concept.
- **Smartlog comparable**: 6 features incl notebook + chat — Smartlog broader self-service surface.

### 8. Embedding & Sharing
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://qlik.dev/embed/
- **Notable**: nebula.js component library + iframe + Capability APIs + JWT-based SSO + RLS via Section Access.
- **Smartlog comparable**: 4 features. Qlik strong here, comparable to Sisense Compose SDK.

### 9. Collaboration
- **Presence**: ◐
- **Depth**: Medium
- **Evidence**: https://help.qlik.com/en-US/cloud-services/Subsystems/Hub/Content/Sense_Hub/Collaborate/collaborate.htm
- **Notable**: Notes + subscriptions + Qlik Alerting (threshold-based). No deep @-mention thread.
- **Smartlog comparable**: 5 features. Comparable.

### 10. Governance & RBAC
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.qlik.com/en-US/sense-admin/Subsystems/DeployAdministerQSE/Content/Sense_DeployAdminister/QSEoW/Administer_QSEoW/Managing_QSEoW/security-rules.htm
- **Notable**: Spaces (workspaces) + role + security rules + Section Access (RLS) + audit log. Mature enterprise governance.
- **Smartlog comparable**: 7 features. Comparable.

### 11. Performance & Scale
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.qlik.com/en-US/sense/Subsystems/Hub/Content/Sense_Hub/LoadData/get-started-loading-data.htm
- **Notable**: Associative engine in-memory + Direct Query mode + incremental load (Script-driven).
- **Smartlog comparable**: ClickHouse MV — different stack.

### 12. AI / ML
- **Presence**: ✓
- **Depth**: Medium → trending Deep
- **Evidence**: https://help.qlik.com/en-US/cloud-services/Subsystems/Hub/Content/Sense_Hub/Insights/insight-advisor.htm
- **Notable**: **Insight Advisor** (NL Q&A + auto-chart) + **Qlik Answers** (GenAI conversational analytics, 2024+) + Qlik AutoML (predictive). Multi-LLM unverified.
- **Smartlog comparable**: 11 features. Smartlog architecturally broader.

### 13. Mobile / Responsive
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://help.qlik.com/en-US/sense/Subsystems/Mobile/Content/Sense_Mobile/Introduction-to-Qlik-Sense-Mobile.htm
- **Notable**: Qlik Sense Mobile iOS/Android with offline mode.
- **Smartlog comparable**: Web only. Gap.

### 14. Pricing & Deployment
- **Model**: Qlik Sense Business $30/user/mo (Cloud) + Enterprise quote-based (capacity + users). Embedded license separate.
- **Entry tier**: $30/user/mo Business (Cloud).
- **Embedded license**: Yes — Qlik OEM/Embedded program.
- **Evidence**: https://www.qlik.com/us/pricing (access date 2026-05-26)

## Strengths (top 3)
1. **Associative engine** — selection-based exploration UX is unique; users discover patterns competitors miss.
2. **Insight Advisor + Qlik Answers** — NL/AI direction strong.
3. **Data Integration (Attunity heritage)** — CDC + replication capability bundled.

## Weaknesses (top 3)
1. **Learning curve** — associative model + Qlik Script is unfamiliar to SQL-first analysts.
2. **Enterprise sales motion** — less SMB-friendly than Metabase/Superset.
3. **Vertical-specific positioning weaker than supply chain ISVs** like Smartlog can deliver.

## Recent releases (window: last 90 days)
| Version | Date | Notable changes affecting capability matrix |
|---|---|---|
| Qlik Cloud Analytics ongoing | 2025-2026 | Qlik Answers GenAI capability expansion. Specific 2026 Q1/Q2 unverified. |

## Relevance lens — logistics SaaS

| Area | Vì sao quan trọng cho Smartlog |
|---|---|
| 2. Data Modeling | Associative paradigm is *different* from Smartlog's relational/QueryConfig — unlikely Smartlog re-architects |
| 6. Filtering | Qlik's "select everything filters everything" is a UX moat — Smartlog's cross-filter is correctness-safe but less magical |
| 12. AI | Qlik Answers + Insight Advisor is direction-of-travel competitor; Smartlog multi-LLM is architectural defense |

## Open questions / unverified
- Q: Qlik Answers multi-LLM support — single vendor or pluggable?
- Q: Qlik AutoML positioning vs DataRobot/Vertex AI in 2026?
- Q: Qlik Cloud Analytics specific 2026 Q1/Q2 release scope?

## Refresh log
| Date | Refreshed by | What changed |
|---|---|---|
| 2026-05-26 | da-po Mode B | Initial baseline |
