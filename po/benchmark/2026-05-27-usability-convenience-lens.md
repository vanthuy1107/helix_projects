# Usability & Convenience Lens — Smartlog Control Tower (demand view)

**Mode**: C-supplement (Convenience lens) · **Scan baseline**: `41b3863` (2026-05-22) · **Branch**: `feat-vfr-late-alert`
**Author**: `/da-po` (squad1@gosmartlog.com) · **Date**: 2026-05-27
**Why this file exists**: the 2026-05-26 sweep ([capability matrix](2026-05-26-bi-capability-matrix.md), [gap analysis](2026-05-26-gap-analysis.md), [recommendations](../roadmap-input/2026-05-26-recommendations.md)) scored the platform on **Presence × Depth only** — the *supply view* ("what the platform HAS"). It had no axis for the *demand view* ("what the user EXPERIENCES"). This supplement adds that axis.
**Methodology**: per the patched [bi-capability-taxonomy.md](../../../.claude/skills/da-po/references/bi-capability-taxonomy.md) → 3-axis rubric (Presence × Depth × **Ease**) + Convenience personas (P1–P3) & journeys (J1–J6) + convenience-gap namespace `CONV-NNN`. On the next full `/da-po sweep`, this content folds into the standard Mode C structure.

---

## 1. Diagnosis — what the previous sweep missed, and why it's structural

The entire 2026-05-26 sweep scored every cell on two axes defined in the taxonomy rubric: **Presence** (does it exist?) and **Depth** (how complete vs "what good looks like"?). Both answer *"what does the platform HAVE."* Neither asks *"how easy/fast/pleasant is it for a real user to get value."*

This was not an accident — the skill's own anti-pattern table deliberately excluded UX ("So polish UI → so presence × depth"). But that rule **conflated two different things and discarded the wrong one**:

- *UI polish / aesthetics* ("đẹp hơn") — subjective → rightly excluded.
- *Usability / convenience* — **measurable** (time-to-task, click-depth, self-serve success, recovery) → wrongly excluded along with it.

**Three concrete proofs the blind spot is real:**

1. **The Metabase under-scoring.** In the capability matrix, Metabase reads "Medium" on almost everything — capability-light. Yet logistics ISVs choose Metabase *precisely because* of best-in-class no-code usability. The matrix buried this as prose ("Best-in-class Query Builder for SMB", `metabase.md §7`) instead of scoring it. A presence×depth matrix **systematically over-rewards capability-rich-but-clunky tools and under-rewards the usability champions** — and Smartlog will mis-position itself if it benchmarks only on that axis.

2. **All 26 capability gaps are feature-shaped.** Not one of `GAP-001..GAP-026` reads "time-to-insight is slow", "a non-technical user can't self-serve", or "onboarding a tenant takes N days". The whole gap inventory is supply-side.

3. **Smartlog's biggest *recent* investment is invisible to its own scoreboard.** The work on this branch — VFR storytelling v2 (`2dbefec`, `b642848`), Flash Daily 6-level layout, empty-state 3-case messages (`111effa`), the "Có rủi ro / Ổn định" plain-language rename ([[project_vfr_late_alert_taxonomy]]) — is *pure convenience / comprehension work for business users*. The capability matrix cannot see or credit any of it, because it only counts feature presence. **The team is doing demand-side work that its own product assessment is blind to.**

> Root insight: a Product Owner needs both the supply view (capabilities) and the demand view (convenience). Until now only the supply view existed.

---

## 2. The lens — personas & ease axis (summary)

Full definitions in the taxonomy. In short:

| Persona | Who (Smartlog) | Convenience = |
|---|---|---|
| **P1 — Business Consumer** | SC Manager, BOD | time-to-insight, comprehension, exception surfacing, **no training** |
| **P2 — Citizen Author / Analyst** | DA / BA / PM | self-build view / ad-hoc question / KPI without a frontend dev |
| **P3 — Tenant Admin / Embedder** | tenant IT, rollout | onboard a tenant, configure embed + permissions, clone from existing |

**Ease** (3rd axis, scored *per persona*): **Easy** (unaided, first try, no training) · **Moderate** (some learning / non-obvious steps) · **Hard** (needs expert/code/external tool) · **n/a**.

---

## 3. Ease re-read of the 14 capability areas (Smartlog, by target persona)

This re-scores the same areas the capability matrix covered, but on the demand axis. Competitor "ease champion" shown for contrast. Evidence traces to inventory `feature_id` / code / memory.

| # | Capability | Target persona | Smartlog Ease | Evidence (Smartlog) | Ease champion (contrast) |
|---|---|---|---|---|---|
| 1 | Connectors | P3 | Moderate | `data-sources` UI + schema introspection, but connection-string/tenant-claim technical | Metabase guided connect = Easy |
| 2 | Data Modeling | P2 | Moderate | `semantic-registry` (Beta) + `glossary` entity CRUD | Metabase Models = Easy; Looker LookML = Hard but powerful |
| 3 | Query Engine | P2 | Moderate→Hard | `monaco-sql-editor` requires SQL literacy; `golden-sql-library` (Beta) helps | Metabase Query Builder no-code = Easy |
| 4 | Visualization | P1 / P2 | **Easy (P1 read)** / Moderate (P2 author) | 8 domain widgets purpose-built to read; `chart-auto-detect` (Beta) for generic | PowerBI/Tableau = Moderate (interpret raw charts) |
| 5 | Dashboard/Canvas | P1 / P2 | **Easy (P1)** / Easy–Moderate (P2) | `react-grid-layout` drag-drop; storytelling layouts to consume | parity |
| 6 | Filtering | P1 | Easy–Moderate | `widget-filter-resolver` multi-select; `cross-filter-safe` same-dashboard only | parity |
| 7 | **Self-service Authoring** | P2 | **Hard (net-new widget)** / Easy (config CRUD) | net-new analytical widget needs FE code + canonical SQL pasted via Settings dialog ([[feedback_no_default_sql_in_widget_code]], [[feedback_registry_runtime_sync_gap]]); `form-configs` CRUD = Easy | **Metabase = Easy (citizen analyst)** |
| 8 | Embedding | P3 | Hard | `share-resource` iframe + URL only (= GAP-001/002/003) | Metabase signed embed / Sisense Compose SDK = Easy–Moderate |
| 9 | Collaboration | P1 / P2 | Moderate | `monitors`/`alerts` (LLM-attached) + `slack-integration`; discussion lives in Slack (context switch); no per-widget comment | PowerBI/Tableau in-context comments = Easy |
| 10 | Governance | P3 | Moderate | `users`/`roles`/`security-groups` standard admin CRUD | parity |
| 11 | Performance | — | n/a (invisible) | ClickHouse MV → fast queries; experienced as latency only | n/a |
| 12 | **AI / ML** | P1 / P2 | **Moderate (Beta-gated)** | `chat-conversations`/`chat-pipeline` (Beta) NL→SQL is the convenience lever; reliability gates consumer trust | Tableau Pulse / PowerBI Q&A 1-click (also imperfect) |
| 13 | Mobile | P1 (field) | Moderate | `responsive-web` only, not layout-optimized (IGNORE per GAP-026) | PowerBI/Tableau native app = Easy on phone |
| 14 | Pricing | — | n/a | internal product | n/a |

**The headline contradiction — area #7.** Capability matrix scored Self-service Authoring **`✓ / Deep`** (Smartlog *leads* — chat + notebook + KPI templates all exist). The demand axis scores it **`Ease: Hard (P2)`** for authoring a net-new analytical widget. **The "self-service moat" is far narrower than presence×depth implies** for the very persona it claims to serve. The capability is shipped; the *convenience path* is not.

---

## 4. Persona journeys (the convenience that lives *between* capabilities)

The heart of the demand view — end-to-end tasks no single capability owns.

| Journey | Persona | Smartlog Ease | What happens today | Champion |
|---|---|---|---|---|
| **J1 — Time-to-first-insight** | P1 | **Easy ✅ (strength)** | Storytelling layouts engineer comprehension: Flash Daily 6-level hero %, VFR hero + exception, plain-language "Có rủi ro/Ổn định" ([[project_mondelez_flash_daily_storytelling]], [[project_vfr_late_alert_taxonomy]]). "Is today OK?" answered in seconds, no training. | PowerBI/Tableau default = chart grid, user must interpret → Moderate. **Smartlog leads.** |
| **J2 — Self-serve a follow-up** | P1→P2 | Moderate (Beta-gated) | "Why did VFR drop in the North?" — filters + drill cover part; deep "why" needs NL chat (`chat-pipeline` Beta) or a DA. `cross-filter-safe` is same-dashboard only (= GAP-006). | Tableau Pulse / PowerBI Q&A 1-click (imperfect too). **Our top lever is half-shipped.** |
| **J3 — Author a new widget/metric** | P2 | **Hard ❌ (worst gap)** | Net-new analytical widget = FE code + canonical SQL pasted manually via Settings dialog; registry edits don't sync to runtime `widget.config` ([[feedback_registry_runtime_sync_gap]]); `{{date_type}}` label mismatch is a silent footgun ([[feedback_sql_date_type_label_exact_match]]). No GA visual query builder for a non-developer. | **Metabase no-code Query Builder = Easy** — its whole reason for winning deals. |
| **J4 — Onboard a new tenant** | P3 | **Hard ❌** | New tenant (e.g. Panasonic PSV — [[project_panasonic_psv_pipeline]]) = manual MV setup off-repo (`sql-registry.md`) + SQL registry paste; no "clone Mondelez VFR template" wizard. | SaaS BI = workspace templates / clone. **Live signal: scaling tenants IS the business model.** |
| **J5 — Recover from empty/error/stale** | all | Moderate (mixed) | GOOD: VFR empty-state 3-case messages (`111effa`). WEAK: as-of/freshness indicator deliberately dropped ([[project_mondelez_flash_daily_storytelling]] "KHÔNG as-of timestamp"); SQL silent-fail means a wrong number looks like a right one. User can't always tell stale/wrong from correct. | Most BI shows "last refreshed" by default = Easy trust. |
| **J6 — Embed into tenant portal** | P3 | Hard | iframe only — integration time high (already = capability GAP-001/002/003 CATCH-UP High). | Metabase signed embed / Sisense Compose SDK = Easy–Moderate. |

---

## 5. Convenience gaps — `CONV-NNN`

Separate namespace from capability `GAP-NNN` (avoids the dial-collision pattern in [[feedback_triage_namespace_FEAT_vs_DONE]]). Same verdict framework + `persona`/`journey` fields.

| conv_id | Persona | Journey | Gap summary (friction, not "missing feature") | Relevance | Verdict | Handoff |
|---|---|---|---|---|---|---|
| **CONV-001** | P2 | J3 | No GA no-code path to author a net-new analytical widget — needs FE code or manual SQL paste; the chat/auto-detect alternatives are Beta. `✓/Deep/Hard` contradiction on #7. | High | **CATCH-UP — High** | `/da-discovery` → `/frontend-ux` |
| **CONV-002** | P3 | J4 | New-tenant onboarding is manual (off-repo MV setup + SQL registry paste, no clone/template wizard) — throttles the multi-tenant business model. | High | **CATCH-UP — High** | `/da-discovery` |
| **CONV-003** | P1 | J2 | The highest-leverage self-serve lever (NL chat) is Beta → consumers can't trust it → fall back to DA. *Convenience prioritization* of GAP-004, not a new build. | High | **CATCH-UP — High** | `/da-discovery` |
| **CONV-004** | P1 | J1 | Storytelling-first comprehension (engineered narrative layouts + plain language + empty states) is a genuine convenience edge the supply matrix is blind to — but it's per-widget and uncodified, not a defended, reusable asset. | High | **LEAPFROG** | `/da-discovery` priority → `/da-storytelling-data` |
| **CONV-005** | P1/P2 | cross | No in-product onboarding / guided tour / contextual help; learning relies on specs + tribal knowledge. | Medium | **CATCH-UP — Medium** | `/da-discovery` → `/frontend-ux` |
| **CONV-006** | P1/P2 | J5 | Trust signals missing: no as-of/freshness indicator (deliberately dropped) + SQL silent-fail footguns → user can't distinguish stale/wrong from correct. Extends GAP-009 (lineage) with freshness. | Medium | **CATCH-UP — Medium** | `/da-discovery` |
| **CONV-007** | P1 | cross | Accessibility (WCAG, keyboard nav, screen reader) not assessed anywhere — convenience for a user class, currently a blind spot. | Low | **CATCH-UP — Low** (review 6mo) | `/da-discovery` → `/frontend-ux` |

**Verdict breakdown**: CATCH-UP = 6 (3 High + 2 Med + 1 Low) · LEAPFROG = 1 · KEEP = 0 · IGNORE = 0. **Handoff queue to `/da-discovery` = 7.**

### CONV-001 · No-code authoring path for the citizen author (the flagship gap)
- **Why it matters**: #7 is scored as Smartlog's *moat* (Deep). For P2 (the DA/BA/PM persona — the actual user of this skill), authoring a net-new analytical widget is **Hard**: it needs frontend code, and the SQL must be pasted by hand into the widget Settings dialog, where a registry edit doesn't propagate to runtime `widget.config` and a label typo silently selects the wrong column. Metabase wins citizen-analyst deals on exactly this journey being **Easy**.
- **Not a missing feature**: chat (`chat-pipeline`), `chart-auto-detect`, `saved-charts`→pin, and `kpi-templates` all exist — but the *stable, GA, no-code* path doesn't. This is convenience debt sitting on top of shipped capability.
- **Handoff framing for `/da-discovery`**: "What is the GA no-code authoring contract for a non-developer DA — promote chat→pin to GA, or ship a visual query builder, or harden the SQL-paste flow (registry→runtime sync + label validation)?"

### CONV-002 · Tenant onboarding convenience (business-model lever)
- **Why it matters**: Smartlog's model is multi-tenant per-contract. Each new tenant (Panasonic PSV is live) currently means manual MV authoring off-repo + SQL registry paste, no "clone Mondelez → Panasonic" template path. Onboarding friction scales linearly with the sales pipeline.
- **Handoff framing**: "What does a self-serve / templated tenant-onboarding flow look like — clone-from-tenant wizard + registry→runtime sync (overlaps CONV-001)?"

### CONV-004 · Codify storytelling as a defended convenience asset (LEAPFROG)
- **Why it matters**: J1 is where Smartlog genuinely *leads* — and it's the very thing the capability matrix can't see. Generic BI dumps a chart canvas and asks the user to interpret; Smartlog engineers the narrative (hero %, exception-first, plain-language status, funnel, drop-trend, empty-state messaging). **This is the demand-side moat.** Today it's hand-built per widget and uncodified.
- **Reconciles a supply/demand contradiction**: capability `GAP-024` marked Tableau "Story Points" as **IGNORE** ("we don't need that feature"). On the demand axis the *opposite* is true: our storytelling pattern is a **LEAPFROG** worth doubling down on. The point is not to copy Tableau's feature — it's to turn our existing pattern into a **reusable storytelling-layout framework + KPI-template trait**, and market "decisions in 30 seconds, no training."
- **Handoff framing for `/da-discovery` → `/da-storytelling-data`**: "How do we productize the storytelling layout pattern as a reusable, default-on framework instead of per-widget bespoke work?"

---

## 6. Strategic re-read (demand view vs the supply-view headline)

The 2026-05-26 headline: *"Smartlog leads #7 self-service + #12 AI; matches ~8 areas."* The demand axis sharpens it:

- **We lead where it's invisible.** Consumer comprehension (J1 storytelling) is a real, defensible edge that no presence×depth score captured. → name it, codify it, defend it (CONV-004 LEAPFROG).
- **The "self-service moat" is narrower than it looks.** #7 is Deep on capability but Hard on Ease for the citizen author (CONV-001). The moat is real for *consuming* and for *config CRUD*, but not for *net-new authoring by a non-developer* — which is exactly where Metabase wins. Closing CONV-001 is what *realizes* the moat the capability matrix already credits us for.
- **Onboarding friction throttles the business model.** CONV-002 has no capability-gap equivalent — it only surfaces on the demand axis — yet it directly limits how fast Smartlog can take on tenants. High strategic leverage, low visibility until now.
- **The biggest demand-side ROI is GA'ing chat.** Capability gap GAP-004 framed Beta→GA as a "quality/SLA gap." Through the convenience lens (CONV-003) it's the **single highest-leverage user-convenience investment**: it unlocks J2 self-serve for P1 and a no-code path for P2 at once.

**Cross-reference to existing `GAP-NNN`:**

| CONV | Relationship to capability gaps |
|---|---|
| CONV-001 | extends GAP-004 (Beta→GA) + GAP-016 (KPI templates) with the demand framing |
| CONV-002 | **no capability equivalent** — net-new, surfaced only by the lens |
| CONV-003 | demand-priority reframing of GAP-004 |
| CONV-004 | **inverts** GAP-024 (IGNORE on supply axis → LEAPFROG on demand axis) |
| CONV-006 | extends GAP-009 (lineage) with freshness/trust signals |
| CONV-007 | **no capability equivalent** — net-new |

---

## 7. Recommendations delta (feeds `roadmap-input`)

Add to the existing 16-item handoff queue, sorted by relevance (demand-axis items interleave with capability items):

1. **CONV-003** (multi-LLM/chat Beta→GA, demand-priority) — pairs with cluster B / GAP-004; sequence chat first for convenience ROI.
2. **CONV-001** (no-code authoring path for P2) — pairs with GAP-016; realizes the #7 moat.
3. **CONV-002** (tenant-onboarding convenience) — **new cluster E "Onboarding & scale"**; business-model lever.
4. **CONV-004** (codify storytelling) — **LEAPFROG**, new cluster; route to `/da-storytelling-data` after `/da-discovery`.
5. **CONV-005 / CONV-006** (in-product onboarding; freshness/trust signals) — cluster D tactical, after signal verification via `/da-ops`.
6. **CONV-007** (accessibility) — backlog / 6-month review.

> All 7 route through `/da-discovery` first (anti-pattern: never jump `/da-po` → `/ba`). Convenience items that resolve to UI/flow design then hand off to `/frontend-ux` or `/da-storytelling-data`.

---

## 8. Mandatory ending signals

- **MODE**: C-supplement (Convenience lens)
- **ARTIFACT_PATHS**:
  - `projects/po/benchmark/2026-05-27-usability-convenience-lens.md` (this file)
  - skill methodology patched: `.claude/skills/da-po/SKILL.md`, `references/bi-capability-taxonomy.md`, `references/competitor-baseline-template.md`
- **USABILITY_SUMMARY**: Ease re-read of 14 areas → Smartlog **leads** on consumer comprehension (J1, Easy), **lags** on author/admin ergonomics (J3/J4/J6, Hard). 1 flagship `✓/Deep/Hard` contradiction surfaced (#7 Self-service). Storytelling (J1) identified as an uncodified LEAPFROG asset invisible to the supply matrix.
- **GAP_VERDICT_BREAKDOWN (convenience `CONV-NNN`)**: catch_up = 6 (High 3, Med 2, Low 1) · leapfrog = 1 · keep = 0 · ignore = 0.
- **HANDOFF_QUEUE**: CONV-001, CONV-002, CONV-003, CONV-004 (priority), CONV-005, CONV-006, CONV-007 → `/da-discovery` (then `/frontend-ux` / `/da-storytelling-data`).
- **NEXT_REFRESH_DUE**: fold into the next full `/da-po sweep` (recommend `/da-po delta` 2026-06-02 while `feat-vfr-late-alert` is active); the patched skill now produces this lens automatically in Mode B/C.

---

## 9. Closing notes

- `projects/` is the `helix_projects` repo (gitignored from main) — commit this file via `/da-projects` ([[project_projects_repo_isolated]]). This run created the file but did **not** commit.
- The skill itself (`.claude/skills/da-po/`) lives in the **main** repo and was patched directly; sync to the team's `helix_projects` skill copy via `/da-sync` if desired.
- This supplement is **demand-view input**, not a roadmap — it feeds `/da-discovery`, which feeds `/ba`, which feeds `/planner`.
