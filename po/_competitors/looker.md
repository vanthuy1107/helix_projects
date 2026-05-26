---
vendor: Google Looker (and Looker Studio)
slug: looker
category: Cloud BI
last_refresh_date: 2026-05-26
last_refresh_commit_smartlog: 41b3863
sources_consulted:
  - https://cloud.google.com/looker/docs
  - https://cloud.google.com/looker/pricing
  - https://support.google.com/looker-studio
  - https://cloud.google.com/looker/docs/embedded-analytics
notes_on_two_products:
  - "Looker (LookML-based enterprise) and Looker Studio (free, formerly Data Studio + Pro paid tier) are distinct products. This baseline scores Looker (LookML enterprise) primarily; Looker Studio Pro listed in pricing section."
---

# Google Looker — Capability baseline

## Profile

- **Vendor / Parent company**: Google Cloud (acquired 2019 for $2.6B)
- **Founded / acquired**: Looker founded 2012, acq 2019
- **License**: Proprietary (Looker enterprise) + freemium (Looker Studio)
- **Deployment**: Looker SaaS only (managed by Google Cloud) + embedded; Looker Studio is freemium SaaS with Pro tier
- **Primary user persona**: Data engineer + analyst — LookML modeling-first workflow
- **Logistics-vertical presence**: Generic; supply chain via partner blocks

## Capability scores (14 areas)

### 1. Data Connectors
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://cloud.google.com/looker/docs/db-config-overview
- **Notable**: ~60+ database dialects (Looker is SQL-first; queries warehouse direct, no ingestion). BigQuery / Snowflake / Redshift first-class.
- **Smartlog comparable**: 3 features. Looker broader DB dialects but no file/REST connectors.

### 2. Data Modeling
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://cloud.google.com/looker/docs/what-is-lookml
- **Notable**: **LookML** — code-defined semantic layer (views, explores, dimensions, measures). Git-versioned by design. Industry reference for "semantic layer".
- **Smartlog comparable**: `semantic-registry` (Beta) — Smartlog conceptually similar but UI-driven; Looker is code-and-Git. Looker is the deeper reference here.

### 3. Query Engine / Semantic Layer
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://cloud.google.com/looker/docs/sql-runner-and-the-sql-runner-page
- **Notable**: LookML → SQL transpiler; pushdown to warehouse; SQL Runner for raw queries; Looker Modeler standalone semantic-layer-as-a-service.
- **Smartlog comparable**: SqlKata + Fluid + Golden SQL library. Different abstraction level.

### 4. Visualization Library
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://cloud.google.com/looker/docs/visualization-attributes
- **Notable**: ~25 built-in viz + custom viz API. Less polished than Tableau, more polished than Superset.
- **Smartlog comparable**: 8 widgets + chart-auto-detect Beta.

### 5. Dashboard / Canvas
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://cloud.google.com/looker/docs/dashboard-design-considerations
- **Notable**: User-defined dashboards (UDD) + LookML dashboards (code-defined). Drill-through to underlying Look.
- **Smartlog comparable**: Comparable concept.

### 6. Filtering & Parameters
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://cloud.google.com/looker/docs/filters-and-parameters
- **Notable**: Dashboard filters + LookML parameters + templated filters (control SQL `WHERE` directly).
- **Smartlog comparable**: 3 features. Comparable.

### 7. Self-service Authoring
- **Presence**: ◐
- **Depth**: Medium
- **Evidence**: https://cloud.google.com/looker/docs/looks-folders
- **Notable**: "Explore" UX for ad-hoc analysis but requires LookML model pre-built by data engineer. Not truly self-service for business users.
- **Smartlog comparable**: 6 features. **Smartlog chat + notebook authoring is more business-user-friendly** than LookML; Looker is engineer-first.

### 8. Embedding & Sharing
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://cloud.google.com/looker/docs/embedded-analytics
- **Notable**: Signed embed URLs + iframe + JS Embed SDK + RLS pass-through via user attributes + scheduled delivery. Strong ISV story.
- **Smartlog comparable**: Looker stronger here (signed URL with parameter pass-through is mature).

### 9. Collaboration
- **Presence**: ◐
- **Depth**: Medium
- **Evidence**: https://cloud.google.com/looker/docs/scheduling-and-sending-dashboards
- **Notable**: Scheduled delivery + alerts + Slack integration. No first-class commenting.
- **Smartlog comparable**: 5 features including LLM-attached alerts — Smartlog richer.

### 10. Governance & RBAC
- **Presence**: ✓
- **Depth**: Deep
- **Evidence**: https://cloud.google.com/looker/docs/admin-panel-users-roles
- **Notable**: Roles + permission sets + model sets + RLS via user attributes + Git workflow for LookML changes. LookML versioning = built-in lineage.
- **Smartlog comparable**: 7 features. Comparable, less code-versioning model.

### 11. Performance & Scale
- **Presence**: ✓
- **Depth**: Medium
- **Evidence**: https://cloud.google.com/looker/docs/caching-and-datagroups
- **Notable**: Persistent Derived Tables (PDT) + datagroups (cache invalidation) + warehouse pushdown.
- **Smartlog comparable**: ClickHouse MV per-tenant (similar concept).

### 12. AI / ML
- **Presence**: ✓
- **Depth**: Medium → trending Deep
- **Evidence**: https://cloud.google.com/looker/docs/studio/gemini-in-looker-studio (unverified URL — Gemini in Looker Studio docs)
- **Notable**: Gemini in Looker (formerly Duet AI) — formula assist, LookML assist, conversational analytics, slide generation. **Tied to Gemini (Google) only** — no multi-LLM choice.
- **Smartlog comparable**: 11 features, multi-LLM. Architecturally broader.

### 13. Mobile / Responsive
- **Presence**: ◐
- **Depth**: Medium
- **Evidence**: https://cloud.google.com/looker/docs/looker-mobile
- **Notable**: Looker mobile app exists; less polished than Tableau/PowerBI.
- **Smartlog comparable**: Web only. Comparable gap.

### 14. Pricing & Deployment
- **Model**: Quote-based (no public list). Looker enterprise platform fee + per-user. Estimated ~$50K+/year entry. Looker Studio free; Looker Studio Pro $9/user/mo.
- **Entry tier**: Looker Studio free (Pro $9/mo). Looker enterprise quote-based.
- **Embedded license**: Yes — embedded usage license tier exists; Powered by Looker for ISVs.
- **Evidence**: https://cloud.google.com/looker/pricing (access date 2026-05-26)

## Strengths (top 3)
1. **LookML semantic layer** — code-versioned modeling is the gold standard; data engineer love.
2. **Embedded ISV story** — signed URL + user attributes + RLS is mature.
3. **Google Cloud integration** — BigQuery deep, Gemini AI integration, Vertex AI ML hooks.

## Weaknesses (top 3)
1. **Business-user self-service weak** — requires LookML pre-build; not truly self-service for non-engineer.
2. **Single-LLM (Gemini)** — same lock-in problem as PowerBI Copilot.
3. **Opaque pricing** — quote-based blocks SMB; unfriendly for ISV cost modeling.

## Recent releases (window: last 90 days)
| Version | Date | Notable changes affecting capability matrix |
|---|---|---|
| Looker Modeler | 2024–2025 | Standalone semantic-layer-as-a-service GA (verified concept, exact dates unverified) |
| Gemini in Looker | 2024–2026 ramp | Continuing capability expansion; specific 2026 Q1/Q2 unverified |

## Relevance lens — logistics SaaS

| Area | Vì sao quan trọng cho Smartlog |
|---|---|
| 2. Modeling | LookML is the reference Smartlog `semantic-registry` should benchmark against |
| 8. Embedding | Looker signed URL pattern is what Smartlog's `share-resource` could mature toward |
| 14. Pricing | Looker quote-based is barrier for ISV; Smartlog's per-tenant SaaS pricing is more friendly |

## Open questions / unverified
- Q: Current Looker enterprise platform fee benchmark for ISV tier? (need vendor quote)
- Q: Gemini in Looker 2026 Q1/Q2 release scope (was the conversational analytics GA pushed?)
- Q: Looker Studio Pro embedding capabilities — pixel-perfect or iframe only?

## Refresh log
| Date | Refreshed by | What changed |
|---|---|---|
| 2026-05-26 | da-po Mode B | Initial baseline; Looker Studio Pro doc URL 404 — used Google Cloud / Looker docs roots |
