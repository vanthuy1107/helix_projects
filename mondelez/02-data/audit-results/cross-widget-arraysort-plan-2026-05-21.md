# Cross-widget arraySort Empty-Filter — Audit Sprint Plan

**Date:** 2026-05-21
**Author:** /da-ch (Discovery + planning only — NO fix applied)
**Parent bug:** [BUG-002 — Cross-widget arraySort empty-filter exposure](../../../../docs/feature/vfr-storytelling-refresh/qa/bugs/BUG-002-cross-widget-arraysort-exposure.md)
**Scope:** Plan how to close ~413 remaining `arraySort([{{x}}])` empty-filter occurrences in [`sql-registry.md`](../data-sources/sql-registry.md) outside the VFR sections that /debugger already fixed.
**Out of scope:** Apply fix (handoff to `/debugger`), individual per-widget audits (one `/da-ch` per widget if Path B chosen).

---

## 1. Survey — Per-section occurrence count

Grep command run:
```
awk 'NR>={start} && NR<={end} && /arraySort\(\[\{\{/' sql-registry.md | wc -l
```

| # | Section | Line range | arraySort occurrences | Status | Frontend widget consumer | Widget folder |
|---|---------|------------|----------------------:|--------|--------------------------|---------------|
| 1 | Utilization | 31–1641 | **23** | Open | `widget-wh-util*.tsx` | [wh-predict/](../../../../frontend/src/features/dashboard/components/widgets/wh-predict/) |
| 2 | Loose picking | 1642–2391 | **0** | ✅ Clean (no bracket pattern) | `widget-loose-picking*.tsx` | wh-predict/ |
| 3 | copack — ngừng develop | 2392–2521 | 0 | Deprecated — SKIP | — | — |
| 4 | trung chuyển — ngừng develop | 2522–2759 | 0 | Deprecated — SKIP | — | — |
| 5 | nhập từ xưởng — ngừng develop | 2760–2958 | 0 | Deprecated — SKIP | — | — |
| 6 | Stock type | 2959–3736 | **27** | Open | `widget-stock-type*.tsx` | wh-predict/ |
| 7 | vfr tender | 3737–5215 | **0** | ✅ Fixed by /debugger (VFR scope) | `widget-vfr*.tsx`, `widget-tender-response*.tsx` | [order-monitor/](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/) |
| 8 | vfr operation | 5216–6688 | **0** | ✅ Fixed by /debugger (VFR scope) | same as above | order-monitor/ |
| 9 | Fulfillment Ratio | 6689–7505 | **24** | Open | `widget-tender-response*.tsx` (config-driven) | order-monitor/ |
| 10 | Compliance Ratio | 7506–7934 | **18** | Open | `widget-tender-response*.tsx` (config-driven) | order-monitor/ |
| 11 | Transaction move | 7935–8941 | **24** | Open | `widget-txn-move*.tsx` | wh-predict/ |
| 12 | Flash Report | 8942–14077 | **105** | Open — **heaviest** | `widget-flash-daily*.tsx` | [flash-report/](../../../../frontend/src/features/dashboard/components/widgets/flash-report/) |
| 13 | Tiến độ xuất hàng | 14078–19351 | **88** | Open | `widget-shipping-progress*.tsx` | order-monitor/ |
| 14 | OTIF | 19352–22786 | **64** | Open | `widget-otif*.tsx` | order-monitor/ |
| 15 | Cảnh báo đơn trễ | 22787–24385 | **40** | Open — **current feature branch** | `widget-late-order-alert*.tsx` | order-monitor/ |
| | **TOTAL OPEN** | | **413** | 8 sections × ~50 avg | | |

Math reconciliation vs BUG-002:
- BUG-002 ticket said 408 remain (493 − 80 VFR − 5 spec).
- Current grep counts 413 remaining in registry.
- Δ = +5 (likely an off-by-five in the ticket's manual subtraction or a few VFR fixes that landed elsewhere; not material for planning).

Loose picking already has 0 occurrences — likely uses the older CTE-with-params pattern (`coalesce({{x}}, 'ALL')`) rather than `arraySort` bracket. Same is true of the 3 deprecated sections. Net affected: **8 active sections, ~413 occurrences**.

---

## 2. Production telemetry — BLOCKED

**Status:** Could not pull `system.query_log` telemetry. No ClickHouse credentials present in repo `.env`, `.env.local`, or any tracked config. User would need to supply `CLICKHOUSE_HOST` / `CLICKHOUSE_USER` / `CLICKHOUSE_PASSWORD` for `helix` user on Mondelez cluster, then I can run:

```sql
SELECT
    extract(query, 'mv_filter_(\\w+)')                         AS filter_mv,
    countIf(query LIKE '%arraySort(\[%')                       AS bracket_pattern_hits,
    count()                                                    AS total_hits,
    uniqExact(initial_query_id)                                AS distinct_sessions
FROM clusterAllReplicas('default', system.query_log)
WHERE event_time > now() - INTERVAL 30 DAY
  AND query LIKE '%mv_filter_%'
  AND type = 'QueryFinish'
  AND user = 'helix'
GROUP BY filter_mv
ORDER BY total_hits DESC
FORMAT PrettyNoEscapes
```

**Proxy ranking (used in lieu of telemetry):** occurrence count × known business criticality. Confidence: Medium (works for picking top-3 but not for fine-grained ordering).

| Rank | Section | Occ. | Business signal | Composite priority |
|------|---------|-----:|-----------------|--------------------|
| 1 | **Flash Report** | 105 | Mondelez daily SC pulse — exec-visible (memory: `project_mondelez_flash_daily_target` 95% target) | **CRITICAL** |
| 2 | **Tiến độ xuất hàng** | 88 | Shipping progress = OTIF parent flow, multi-warehouse | **HIGH** |
| 3 | **OTIF** | 64 | KPI cockpit (memory: `project_mondelez_otif_target` 90% RAG) | **HIGH** |
| 4 | Cảnh báo đơn trễ | 40 | Current feature branch (`feat-vfr-late-alert`) — under dev attention | HIGH (dev convenience) |
| 5 | Stock type | 27 | Inventory monitoring | MEDIUM |
| 6 | Fulfillment Ratio | 24 | Tender response metric | MEDIUM |
| 7 | Transaction move | 24 | Cross-warehouse moves | MEDIUM |
| 8 | Utilization | 23 | Warehouse capacity | MEDIUM |
| 9 | Compliance Ratio | 18 | Tender response sub-metric | LOW |

---

## 3. Path A vs Path B — 4-axis cost-benefit

### 3.1 Path A feasibility — re-evaluated after reading resolver code

Resolver source: [`WidgetFilterResolver.cs:134-149`](../../../../backend/src/Smartlog.Infrastructure/Services/Dashboard/WidgetFilterResolver.cs#L134-L149).

```csharp
private static string EscapeAsSqlLiteral(string? value)
{
    if (string.IsNullOrEmpty(value)) return "NULL";
    if (value.Contains(',')) { /* csv → 'a', 'b', 'c' */ }
    return $"'{value.Replace("'", "''")}'";
}
```

The substitution is pure regex replace via `InlinePlaceholderRegex` (line 89–94) — **zero awareness of bracket context**. Three implementation strategies for Path A:

| Strategy | Description | Verdict |
|----------|-------------|---------|
| A1 — change default empty literal | Make `EscapeAsSqlLiteral("")` emit something other than `"NULL"` (e.g. empty string) | ❌ **Regression hazard**. Single-select non-bracket usages relying on `IN (NULL)` short-circuit would break. |
| A2 — context-aware bracket detection | Detect `\[\s*\{\{x\}\}\s*\]` pattern in SQL template; for empty values, rewrite the entire `arraySort([{{x}}]) = (...)` probe to `1=1` (or equivalent) | ⚠️ **Feasible but brittle**. Requires regex/string surgery on SQL template before substitution. Whitespace, comments, line breaks, multi-line bracketing all need handling. Pattern drift = silent passthrough. |
| A3 — new placeholder syntax | Introduce `{{x:set}}` syntax with saturated-set semantics → all 413 SQLs must adopt new syntax | ❌ **Identical effort to Path B + extra backend work**. Defeats the purpose. |

**Only A2 is viable.** Saturated-set form for the probe-RHS (e.g. `arraySort(groupArray(DISTINCT col)) FROM mv_filter_*`) cannot be synthesized by the resolver because the resolver doesn't know the target MV name — that information lives in each individual SQL. So A2 must rewrite the probe to `1=1` directly.

### 3.2 Cost-benefit matrix

| Axis | Path A (A2 — context-aware resolver) | Path B (per-widget SQL rewrite) |
|------|--------------------------------------|---------------------------------|
| **Engineer-days** | 4–7 days = ~1 sprint slot<br>• Resolver regex + tests: 3–5 days<br>• Per-tenant regression: 1–2 days | ~8 sprint slots<br>• 8 sections × ~1 slot each (VFR took 1 slot for 80 occurrences; new sections range 18–105 each) |
| **Blast radius** | Backend: 1 file (`WidgetFilterResolver.cs`).<br>Runtime: **every widget query** is downstream — any bracket pattern variation breaking regex → silent passthrough → empty data on first paint, identical to current bug. | Per-PR: 1 section's worth of SQL strings in registry + spec.<br>Each PR independently safe. |
| **Tenant operational cost** | **ZERO**. No SQL re-paste. Fix invisible to admins. | **HIGH**. Each tenant admin must re-paste N widgets × M SQLs through Settings dialog after every PR. With 2–3 tenants and 8 sections = 16–24 admin operations.<br>(Memory: `feedback_registry_runtime_sync_gap` confirms this drift is operationally painful.) |
| **Regression risk** | **Medium-High**. Backend regex must match canonical pattern exactly across all 413 occurrences (and any future ones). One whitespace/comment variation = silent failure. Mitigated by: extending [`WidgetFilterResolverTests.cs`](../../../../backend/tests/Smartlog.Application.Tests/Services/Dashboard/WidgetFilterResolverTests.cs) with all pattern variants before merge. | **Low** per-PR (incremental, isolated). But cumulative risk = 8 chances for human error. /debugger's existing Option B template + apply tooling lowers risk further. |

### 3.3 Hidden cost — registry vs runtime drift

Per memory `feedback_registry_runtime_sync_gap`: registry is doc only. Runtime SQL lives in widget config DB and must be hand-pasted by admin. Path B inherits this gap (every fix needs re-paste); Path A removes the gap entirely for bracket-pattern bugs.

For Mondelez specifically, the team also operates Panasonic (PSV) and other tenants — Path B's re-paste cost multiplies linearly with active tenants. Path A is constant.

---

## 4. Recommendation

### 4.1 Recommended path: **Path A (A2 — context-aware resolver patch)**

Rationale:
1. **8× effort reduction**: 1 sprint slot vs 8 slots.
2. **Zero tenant admin re-paste**: critical given known registry↔runtime sync gap.
3. **Single PR, single test surface**: easier to validate exhaustively than 8 PRs.
4. **Manageable regression risk**: VFR Option B already removed ~80 bracket occurrences from highest-traffic section → smaller target surface for A2 to handle. Extending unit tests to cover whitespace/comment/multi-line variants before merge is cheap.
5. **Future-proof**: any new widget author writing the bracket pattern is automatically safe; no need to remember the convention.

### 4.2 Sprint allocation — Path A

| Sprint slot | Owner | Work |
|-------------|-------|------|
| **Slot 1** (single sprint) | `/backend` | • Implement A2 regex/pattern-surgery in [`WidgetFilterResolver.cs`](../../../../backend/src/Smartlog.Infrastructure/Services/Dashboard/WidgetFilterResolver.cs)<br>• Extend [`WidgetFilterResolverTests.cs`](../../../../backend/tests/Smartlog.Application.Tests/Services/Dashboard/WidgetFilterResolverTests.cs): empty/single/multi/CSV × canonical-bracket / whitespace-variants / multi-line / comment-adjacent<br>• Integration test: pick 1 representative SQL from each of the 8 affected sections, run through resolver, assert `1=1` rewrite when filter empty AND correct `IN (...)` when filter populated<br>• `/da-ch` live verification on Mondelez CH cluster (re-run BUG-002 evidence query post-fix to confirm zero-row condition gone) |
| **Slot 2** (follow-up, optional) | `/da-ch` + `/debugger` | **Pattern unification cleanup** — opportunistic migration of the 413 bracket-pattern SQLs to the canonical `(coalesce({{x}}, 'ALL') = 'ALL' OR t.col IN ({{x}}))` form used by VFR Option B fix, **so the registry no longer carries two parallel patterns**. This is hygienic, not bug-fixing — Path A removes the bug at runtime; this just removes the doc inconsistency. Can be deferred indefinitely. |

### 4.3 Fallback — if Path A2 is judged too risky after /backend impact analysis

Sequence Path B by composite priority (occurrence × business signal). Each is one `/da-ch` audit + one `/debugger` fix PR:

| Sprint | Section | Why this order |
|--------|---------|----------------|
| B1 | Flash Report (105) | Daily SC pulse, exec-visible — biggest blast radius |
| B2 | Tiến độ xuất hàng (88) | Shipping progress feeds OTIF parent flow |
| B3 | OTIF (64) | KPI cockpit, 90% RAG target |
| B4 | Cảnh báo đơn trễ (40) | Current feature branch — dev attention already there, easy to bundle with `feat-vfr-late-alert` work |
| B5 | Stock type (27) | Inventory dashboard |
| B6 | Fulfillment Ratio (24) | Tender response |
| B7 | Transaction move (24) | Cross-warehouse moves |
| B8 | Utilization (23) | Warehouse capacity |
| B9 | Compliance Ratio (18) | Tender response sub-metric |

(9 slots because Cảnh báo đơn trễ bundled with current sprint is +1 ad-hoc but technically still a slot.)

---

## 5. Risk callouts — Path A

### R1 — Pattern-drift silent failure (HIGH)
A2 detection regex must match canonical pattern exactly. Any author writing `arraySort([ {{x}} ])` with extra space, or wrapping in subquery, or comment between bracket and placeholder → regex misses → resolver emits `[NULL]` → bug re-appears silently. **Mitigation:** lint rule in CI to flag any new `arraySort([` pattern in registry that doesn't match the detected canonical form. Also: unit-test the regex against every known variant in current registry before merging.

### R2 — Hidden bracket usage outside registry (MEDIUM)
Per-tenant widget config DB may contain customized SQL with bracket pattern that drifted from registry. Path A fixes them transparently — **but only for Mondelez backend**. If another tenant has bespoke pattern that A2's regex doesn't match, that tenant stays buggy. **Mitigation:** before merge, query widget config tables across active tenants (`projects/mondelez/scripts/...`, `projects/panasonic/scripts/...`) to enumerate distinct bracket-pattern shapes; ensure regex covers all of them.

### R3 — Comprehensive test matrix is non-trivial (MEDIUM)
Path A's correctness depends on test coverage of all (placeholder-context × value-shape) combinations:
- Contexts: bare `{{x}}`, bracket `[{{x}}]`, in-CSV `{{x}}, {{y}}`, in-comment `-- {{x}}`, multi-line
- Values: empty, single, CSV, value-with-quote, value-with-comma-inside

Failure mode for any uncovered combo = production bug. **Mitigation:** use combinatorial test generation (xUnit `[Theory]` + `[InlineData]`), aim for ≥30 test cases. Existing `WidgetFilterResolverTests.cs` has the harness.

### R4 — Resolver regex maintenance burden (LOW-MEDIUM)
Future SQL conventions may introduce patterns A2 doesn't anticipate (e.g. `arraySortDescending([{{x}}])`, `arrayDifference([{{x}}, ...])`). Without periodic re-audit, the regex slowly diverges from registry reality. **Mitigation:** add to `docs/playbooks/dev/` or `docs/lessons/dev.md` the rule "new bracket pattern → update WidgetFilterResolver detection AND its test fixtures."

### R5 — Backend gates and CR review (LOW)
Backend touches a hot path (every widget query). Existing CR process will require thorough review. **Mitigation:** /backend agent should produce impact analysis via gitnexus `gitnexus_impact({target: "EscapeAsSqlLiteral", direction: "upstream"})` before any code change.

---

## 6. Open questions for product/eng leadership

1. **Are there active tenants beyond Mondelez/Panasonic using widget config DB with bracket-arraySort patterns we haven't surveyed?** (R2 mitigation depends on this.)
2. **Does /backend have bandwidth this sprint?** Path A2 needs 1 contiguous backend slot; if /backend is already committed, Path B starting with Flash Report is the parallel-friendly alternative.
3. **Is Slot 2 (registry pattern unification) ever going to be funded?** If no, Path A leaves registry in an inconsistent state (two parallel patterns: bracket-with-resolver-magic vs CTE-coalesce). Acceptable doc debt, but worth a deliberate decision.

---

## 7. Top 3 widgets to fix urgently (traffic-weighted, telemetry-blocked proxy)

If Path A approved → these are the regression-verification targets (run resolver-substituted SQL on CH post-fix, confirm zero-row state cleared):

| Rank | Widget | Section | Occ. | Verification SQL location |
|------|--------|---------|-----:|---------------------------|
| 1 | **`widget-flash-daily*`** | §Flash Report | 105 | sql-registry.md L8942–14077 |
| 2 | **`widget-shipping-progress*`** | §Tiến độ xuất hàng | 88 | sql-registry.md L14078–19351 |
| 3 | **`widget-otif*`** | §OTIF | 64 | sql-registry.md L19352–22786 |

If Path B approved → these are sprints B1, B2, B3 respectively.

---

## ARTIFACT_PATH: projects/mondelez/02-data/audit-results/cross-widget-arraysort-plan-2026-05-21.md
## DATA_CONFIDENCE: Medium
- Occurrence counts: High confidence (deterministic grep against pinned registry).
- Widget-consumer mapping: High confidence (verified via file listing).
- Path A2 effort estimate: Medium confidence (no precedent for context-aware resolver refactor in this codebase; range 4–7 days).
- Path B effort estimate: Medium-High (VFR's 1-slot/80-occurrence precedent extrapolated).
- Production telemetry: Low — could not pull `system.query_log`; ranking is proxy-based.
## MV_FRESHNESS: N/A — planning artifact, no live query executed.
## NEXT_ACTION:
1. Human approve recommended Path A.
2. `/backend` impact analysis on `EscapeAsSqlLiteral` + `WidgetFilterResolver.ResolveFilters` (gitnexus_impact upstream).
3. If Path A approved → `/debugger` (or `/backend`) implements A2 + comprehensive test matrix per §5.R3.
4. If Path A rejected → start `/da-ch` audit on §Flash Report (highest priority Path B sprint).
5. After fix lands → re-verify with BUG-002 evidence query against live CH on each affected section; close BUG-002 if all clear.
