---
name: da-po
description: Dùng khi cần map toàn bộ tính năng hiện tại của Smartlog Control Tower (bóc từ source code BE+FE) và benchmark với các sản phẩm BI lớn (PowerBI, Tableau, Looker, Superset, Metabase, Sisense, Qlik) để định hướng roadmap sản phẩm. Hỗ trợ chạy định kỳ (manual `/da-po delta` hoặc cron) để detect feature mới trong code + re-benchmark đối thủ đã có release notes mới. 4 modes A/B/C/D. Trigger trên "PO sweep", "benchmark BI", "rà soát tính năng", "so với PowerBI/Tableau", "product landscape", "feature inventory", "gap với đối thủ", "ta đang ở đâu trên bản đồ BI". KHÔNG dùng để đánh giá lib/framework đơn lẻ (dùng /research-ideation), không thay /da-discovery khi đã biết vấn đề cụ thể, không thay /da-pm khi cần plan sprint.
user-invocable: true
---

# Smartlog Control Tower — Product Owner sweep (business-side)

Cảm hứng từ workflow gstack — *boil the lake before you code*, verdict-driven, atomic handoff. Skill này tồn tại để trả lời 2 câu hỏi cốt lõi của một Product Owner business-side:

1. **Ta đang có gì?** — bóc tính năng từ source code, không dựa vào trí nhớ stakeholder.
2. **Ta ở đâu trên bản đồ?** — so capability với 7 sản phẩm BI lớn để định hướng roadmap.

## Triết lý

- Inventory **phải bám source code**, không lấy từ slide marketing — code là source of truth.
- Benchmark so **capability presence × depth**, không so polish UI (subjective).
- Mỗi gap phải kết thúc bằng 1 verdict: `KEEP | CATCH-UP | LEAPFROG | IGNORE`. Không "TBD".
- Skill này **filter** trước `/da-discovery` và `/ba`, không thay thế chúng.
- Chạy định kỳ → chỉ re-quét phần *đã đổi*, không re-do toàn bộ.

## Khi nào dùng

- Quarterly product review — cần ảnh chụp landscape.
- Sales/partner hỏi "so với PowerBI thì sao" — cần fact sheet.
- Trước khi mở initiative lớn — cần biết đối thủ đã có gì.
- Định kỳ (weekly/monthly) — cần detect feature mới trong code + release notes đối thủ.

## 4 Modes

| Mode | Trigger phrase | Output | Thời lượng |
|---|---|---|---|
| **A. Inventory** | "liệt kê tính năng", "ta đang có gì", `/da-po inventory` | Feature catalog theo BI taxonomy | 30–60 phút |
| **B. Benchmark** | "so với PowerBI/Tableau", "benchmark BI", `/da-po benchmark` | Capability matrix 8 cột | 60–90 phút |
| **C. Full sweep** | "PO sweep", "rà soát PO", `/da-po sweep` | A + B + Gap analysis + Recommendations | 2–3 giờ |
| **D. Periodic delta** | `/da-po delta`, hoặc cron weekly | Diff vs snapshot trước → re-benchmark phần đổi | 15–30 phút |

## Mode A — Inventory (bóc từ source code)

Feature **KHÔNG list theo từng controller / từng route**. Gom theo **BI capability bucket** (xem `references/bi-capability-taxonomy.md` — 14 area).

**Nguồn quét bắt buộc:**

| Path | Capability bucket |
|---|---|
| `backend/src/Smartlog.Api/Controllers/*.cs` | Data Access Layer |
| `backend/src/QueryConfigs/*.json` + `Smartlog.DynamicQuery/` | Query / Semantic Layer |
| `backend/src/FormConfigs/*.json` | Self-service Authoring |
| `backend/src/Smartlog.Infrastructure/` (EF, Refit, Caching) | Connectors + Performance |
| `frontend/src/features/*/` + `frontend/src/routes/` | End-user Modules |
| `frontend/src/components/widgets/*` | Visualization Library |
| `frontend/src/components/ui/` (RTL-patched Shadcn) | UX foundations |
| `frontend/package.json` (Recharts, Monaco, react-grid-layout, ...) | Tech capability flags |
| Migration history (`backend/src/Smartlog.Infrastructure/Migrations/`) | Data Model coverage |
| `projects/{tenant}/` (gitignored) — KHÔNG quét, đó là tenant config | (skip) |

**Catalog row shape:**

```
feature_id      : kebab-case slug, stable
name            : human-readable Vietnamese name
bi_capability   : 1 trong 14 area (taxonomy)
maturity        : POC | Beta | GA
source_paths    : array of glob paths (truy ngược về code)
last_modified   : git short SHA + ISO date
owner_team      : DEV | DA | BA | Rollout (đoán từ recent committers nếu không rõ)
demo_route      : URL frontend nếu có
notes           : 1 dòng — gì đặc biệt
```

**Output:**
- `projects/po/inventory/{YYYY-MM-DD}-feature-catalog.md` — bảng human-readable + grouping theo capability
- `projects/po/inventory/_latest.json` — machine-readable snapshot (dùng cho Mode D)

`_latest.json` cũng ghi `last_scan_commit` (SHA của HEAD lúc scan) để Mode D diff được.

## Mode B — Benchmark vs 7 đối thủ

**Capability matrix 8 cột × 14 row:**

| Cột | Vendor |
|---|---|
| 1 | **Smartlog Control Tower** (ta) |
| 2 | Microsoft Power BI (primary competitor) |
| 3 | Tableau |
| 4 | Google Looker |
| 5 | Apache Superset |
| 6 | Metabase |
| 7 | Sisense |
| 8 | Qlik (Sense) |

**Mỗi ô:**
```
Presence : ✓ (full) | ◐ (partial) | ✗ (none)
Depth    : Deep | Medium | Shallow | n/a
Note     : 1 câu chứng minh, kèm path code (ta) hoặc URL doc (đối thủ)
Source   : commit SHA + date (ta) / vendor docs URL + access date (đối thủ)
```

**Cache đối thủ:** `projects/po/_competitors/{vendor}.md` — refresh khi >30 ngày hoặc khi vendor có release notes mới. Template ở `references/competitor-baseline-template.md`.

**Quy tắc fact-check (rút từ memory feedback):**
- Trước khi viết "Smartlog có X" → grep / read code chứng minh, ghi path vào cột Source.
- Trước khi viết "PowerBI không có Y" → fetch official docs, KHÔNG dựa marketing slide.
- Nếu không verify được trong 5 phút → ghi `Source: unverified`, đánh dấu phải resolve trước handoff.

**Output:** `projects/po/benchmark/{YYYY-MM-DD}-bi-capability-matrix.md`

## Mode C — Full sweep (A + B + Gap + Recommendation)

Chạy nối tiếp A → B → gap analysis → recommendations.

**Gap analysis:** Với mỗi ô đối thủ có mà ta không (hoặc Depth thấp hơn rõ rệt) → 1 row gap với 4 trường:

| Field | Nội dung |
|---|---|
| `gap_id` | `GAP-{NNN}` |
| `capability` | 1 trong 14 area |
| `gap_summary` | 1 câu mô tả ta thiếu gì |
| `evidence` | path/URL chứng minh đối thủ có |
| `relevance_to_logistics` | High / Medium / Low — dựa lens "tenant logistics của ta có cần không" |
| `verdict` | `KEEP` / `CATCH-UP` / `LEAPFROG` / `IGNORE` |
| `verdict_rationale` | 1 câu giải thích |
| `handoff_to` | `/da-discovery` (CATCH-UP, LEAPFROG) / null (KEEP, IGNORE) |

**Output:**
- `projects/po/benchmark/{YYYY-MM-DD}-gap-analysis.md`
- `projects/po/roadmap-input/{YYYY-MM-DD}-recommendations.md` — chỉ items CATCH-UP / LEAPFROG, sort theo `relevance_to_logistics` rồi gap_id

## Mode D — Periodic delta (đáp đúng yêu cầu chạy định kỳ)

Đọc procedure chi tiết ở `references/delta-detection-runbook.md`. Tóm tắt:

1. Đọc `projects/po/inventory/_latest.json` → lấy `last_scan_commit`.
2. `git diff --name-only <last_scan_commit>..HEAD` → file đổi.
3. Map file → capability bucket (bảng mapping ở runbook).
4. Re-quét **chỉ** capability bucket đụng tới → ra delta `NEW / CHANGED / REMOVED`.
5. Refresh `_competitors/{vendor}.md` cho vendor có release notes mới trong window (TTL 30 ngày mặc định, override qua flag).
6. Re-render *chỉ* các ô matrix đụng tới (ta hoặc đối thủ).
7. Update `_latest.json` (mới SHA + timestamp) + ghi `projects/po/changelog/{YYYY-MM-DD}-delta.md`.

**Trigger options:**

- **Manual (default):** user gõ `/da-po delta` weekly/monthly.
- **Cron:** dùng `CronCreate` để fire `/da-po delta` thứ Hai 9h:
  ```
  CronCreate: schedule="0 9 * * MON", prompt="/da-po delta", reason="weekly PO delta"
  ```
  Document option này trong SKILL nhưng KHÔNG tự setup cron mặc định — user quyết định.

**Changelog entry shape:**

```markdown
# PO Delta — YYYY-MM-DD

**Scan window**: <prev_commit> → <new_commit>  (X commits)
**Files changed**: N  →  buckets touched: [Visualization, Filtering & Parameters, ...]

## Inventory delta
- NEW: feature_id, capability, source_paths
- CHANGED: feature_id, what changed
- REMOVED: feature_id, reason

## Competitor delta (release notes window: YYYY-MM-DD .. YYYY-MM-DD)
- PowerBI: <X.Y release> — new capability Z (note refreshed)
- Tableau: no change
- ...

## Matrix cells re-rendered
- [Capability × Vendor] : Presence/Depth before → after

## New gaps surfaced
- GAP-NNN: ... → verdict ... → handoff ...

## Verdict summary
- Inventory: +N new, -M removed, ~K changed
- Gaps: +X new CATCH-UP, +Y new LEAPFROG, +Z new IGNORE
- Handoff items: <count to /da-discovery>
```

## Artifacts & paths

Toàn bộ output dưới `projects/po/` (vì `projects/` đã là repo riêng helix_projects, gitignored khỏi main repo). Thao tác file/git phải đi qua `/da-projects` khi muốn commit/push.

```
projects/po/
├── inventory/
│   ├── {YYYY-MM-DD}-feature-catalog.md
│   └── _latest.json
├── benchmark/
│   ├── {YYYY-MM-DD}-bi-capability-matrix.md
│   └── {YYYY-MM-DD}-gap-analysis.md
├── _competitors/
│   ├── powerbi.md
│   ├── tableau.md
│   ├── looker.md
│   ├── superset.md
│   ├── metabase.md
│   ├── sisense.md
│   └── qlik.md
├── changelog/
│   └── {YYYY-MM-DD}-delta.md
└── roadmap-input/
    └── {YYYY-MM-DD}-recommendations.md
```

Filename luôn có date prefix + slug self-describing (tuân thủ feedback "artifact filenames must be self-describing").

## Verdict framework (gstack-style)

Mỗi gap PHẢI kết thúc bằng 1 trong 4 verdict — không có "TBD", không có "cần thảo luận":

| Verdict | Nghĩa | Handoff |
|---|---|---|
| **KEEP** | Ta đã ngang / hơn — không hành động | none |
| **CATCH-UP** | Đối thủ có, ta thiếu, *cần* có vì user logistics có nhu cầu | `/da-discovery` để frame vấn đề |
| **LEAPFROG** | Khoảng trống không ai phục vụ tốt — cơ hội khác biệt hoá | `/da-discovery` priority cao |
| **IGNORE** | Đối thủ có nhưng *không* hợp lens logistics của Smartlog | Ghi lý do, review lại sau 6 tháng |

Nếu không quyết được verdict → ghi blocker cụ thể (câu hỏi + ai trả lời + deadline), không escape thành "TBD".

## Anti-patterns

| Sai lầm | Sửa |
|---|---|
| List từng controller / route như 1 feature | Gom theo 14 BI capability bucket |
| So polish UI ("PowerBI đẹp hơn") | So presence × depth capability, ghi rõ evidence path |
| Cố match mọi feature của PowerBI | Filter qua lens "tenant logistics của ta có cần không" |
| Verdict "ta cũng có" mà không chứng minh path | Phải có cột Source = code path hoặc PR link |
| Recommendation chung chung "nên thêm AI" | Link tới use case cụ thể của 1 tenant (Mondelez/Panasonic) |
| Tự chạy `/ba` ngay sau khi tìm gap | BẮT BUỘC qua `/da-discovery` trước để filter |
| Re-quét full source mỗi lần định kỳ | Mode D dùng git diff, chỉ re-quét bucket bị đụng |
| Lấy fact đối thủ từ blog post / Reddit | Phải từ official docs vendor, ghi URL + access date |
| Để cache `_competitors/*.md` quá 30 ngày mà không refresh | TTL cứng 30 ngày, Mode D check trước khi dùng |
| Bypass `/da-projects` để commit dưới `projects/po/` | Mọi commit `projects/` phải đi qua `/da-projects` |

## Khi nào KHÔNG dùng `/da-po`

- Đã biết tính năng cụ thể muốn thêm → `/da-discovery` rồi `/ba`
- Đánh giá *công nghệ* (library, framework, DB engine) → `/research-ideation`
- Phân tích nghiệp vụ vận hành nội bộ → `/da-biz-ba`
- Plan sprint, timeline, risk → `/da-pm`
- Daily ops pulse khách hàng → `/da-ops`
- Review code chất lượng → `/reviewer` hoặc `/da-ship`

## Handoff matrix

| Từ verdict | Skill kế tiếp | Input handoff |
|---|---|---|
| KEEP | (none) | — |
| CATCH-UP | `/da-discovery` | gap_id, capability, evidence, relevance |
| LEAPFROG | `/da-discovery` priority cao | gap_id + thị trường gap rationale |
| IGNORE | (review log) | record lý do để check lại 6 tháng sau |

`/da-discovery` sẽ tiếp tục bằng 5 câu hỏi reframe (xem SKILL.md của discovery). KHÔNG nhảy thẳng từ `/da-po` sang `/ba`.

## Mandatory ending signals

Kết thúc mọi lần chạy phải in ra:

- `MODE`: A | B | C | D
- `ARTIFACT_PATHS`: list file đã tạo/cập nhật
- `INVENTORY_SUMMARY`: X features total, Y new, Z removed, K changed (Mode A/C/D)
- `BENCHMARK_SUMMARY`: X capability area, Y ta dẫn đầu, Z ta tụt (Mode B/C)
- `GAP_VERDICT_BREAKDOWN`: catch_up=N, leapfrog=M, ignore=K (Mode C/D)
- `HANDOFF_QUEUE`: list gap_id sẽ handoff sang `/da-discovery`
- `NEXT_REFRESH_DUE`: ngày khuyến nghị chạy `/da-po delta` lần kế

## Templates & taxonomy

Chi tiết tham chiếu:

- `references/bi-capability-taxonomy.md` — định nghĩa 14 BI capability area + "what good looks like" cho từng area + path source code Smartlog liên quan
- `references/competitor-baseline-template.md` — template cho `projects/po/_competitors/{vendor}.md` (profile, capability scores, pricing, source URLs)
- `references/delta-detection-runbook.md` — step-by-step Mode D, bảng mapping file→bucket, decision tree
