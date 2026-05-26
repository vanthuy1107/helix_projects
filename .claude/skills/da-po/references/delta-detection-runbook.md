# Mode D — Delta detection runbook

Step-by-step procedure cho `/da-po delta`. Mục đích: tránh re-scan toàn bộ source code mỗi lần định kỳ — chỉ quét phần *đã đổi*.

## Pre-check

1. `projects/po/inventory/_latest.json` tồn tại?
   - Có → đọc `last_scan_commit`, tiếp tục.
   - Không → CHƯA chạy Mode A bao giờ → abort Mode D, yêu cầu user chạy `/da-po inventory` hoặc `/da-po sweep` trước.
2. `last_scan_commit` còn trong git history?
   - Có → tiếp tục.
   - Không (rebase / force-push xoá rồi) → fallback: dùng commit cha của file `_latest.json` từ git log, hoặc abort yêu cầu re-baseline.
3. Branch hiện tại = branch của lần scan trước?
   - Có → đi tiếp.
   - Không → warn user, hỏi có muốn cross-branch diff hay không. Cross-branch diff vẫn được nhưng ghi rõ vào changelog.

## Step 1 — Git diff

```powershell
git diff --name-only <last_scan_commit>..HEAD
```

Lọc bỏ:
- `frontend/src/routeTree.gen.ts` (auto-generated)
- `projects/**` (gitignored, không phải repo chính)
- `**/migrations/snapshot*` (EF auto)
- `**/*.lock` `**/*.min.*`
- `docs/lessons/**` (process docs, không phải feature)

## Step 2 — File → Capability bucket mapping

Bảng deterministic. File khớp glob nào ở cột phải → bucket cột giữa.

| Bucket (capability area) | Glob patterns |
|---|---|
| 1. Data Connectors | `backend/src/Smartlog.Infrastructure/Persistence/**`, `backend/src/Smartlog.Infrastructure/**/Refit*`, `backend/src/Smartlog.Infrastructure/IDbContextResolver.cs` |
| 2. Data Modeling | `backend/src/Smartlog.Domain/Entities/**`, `backend/src/Smartlog.Infrastructure/Migrations/**`, `backend/src/QueryConfigs/**` (metadata fields) |
| 3. Query Engine | `backend/src/Smartlog.DynamicQuery/**`, `backend/src/QueryConfigs/**` (query templates) |
| 4. Visualization | `frontend/src/components/widgets/**`, `frontend/package.json` (recharts/monaco/d3 lines) |
| 5. Dashboard / Canvas | `frontend/src/features/dashboard/**`, `frontend/package.json` (react-grid-layout) |
| 6. Filtering & Parameters | `frontend/src/features/dashboard/filters/**`, `frontend/src/features/dashboard/hooks/WidgetFilterResolver*` |
| 7. Self-service Authoring | `backend/src/FormConfigs/**`, `frontend/src/features/**/createEntityPage*`, FE Settings dialog modules |
| 8. Embedding & Sharing | `backend/src/Smartlog.Api/Controllers/Export*.cs`, `backend/src/Smartlog.Infrastructure/Reporting/**`, FE `share/` `export/` |
| 9. Collaboration | `backend/src/Smartlog.Application/**/Notifications/**`, `backend/src/Smartlog.Infrastructure/EventBus/**`, FE `notifications/` `alerts/` |
| 10. Governance & RBAC | `backend/src/Smartlog.Application/Authorization/**`, `backend/src/Smartlog.Infrastructure/IDbContextResolver.cs`, JWT/identity files |
| 11. Performance & Scale | `backend/src/Smartlog.Infrastructure/Caching/**`, ClickHouse MV scripts (nếu commit vào repo chính), query plan code |
| 12. AI / ML | `**/AI/**`, `**/Anthropic*`, `**/OpenAI*`, package deps `anthropic` / `openai` |
| 13. Mobile / Responsive | `frontend/tailwind.config.*`, `frontend/src/components/ui/**` (breakpoint logic) |
| 14. Pricing & Deployment | `infra/**`, `docker-compose*.yml`, `deploy/**`, `CONTRIBUTING.md` (license note) |

Nếu file không match bucket nào → log vào "Unclassified changes" của changelog, KHÔNG đoán capability.

## Step 3 — Re-scan chỉ buckets bị đụng

Với mỗi bucket trong tập đụng:
1. Đọc lại danh sách feature thuộc bucket đó trong `_latest.json`.
2. Re-quét theo evidence paths của bucket (xem `bi-capability-taxonomy.md`).
3. Tạo delta entry:

```json
{
  "feature_id": "...",
  "change": "NEW | CHANGED | REMOVED",
  "previous": { ... snapshot từ _latest.json hoặc null nếu NEW },
  "current": { ... snapshot mới hoặc null nếu REMOVED },
  "diff_fields": ["maturity", "source_paths", "demo_route"],
  "commits_in_window": ["<short SHA>", ...]
}
```

CHANGED chỉ ghi field nào thực sự khác (so sánh shallow trên các field của feature row).

## Step 4 — Competitor TTL check

Cho mỗi vendor trong `projects/po/_competitors/*.md`:

```
days_since_refresh = today - last_refresh_date
```

- `days_since_refresh < 30` AND không có release notes mới trong window → skip refresh.
- `days_since_refresh >= 30` OR vendor có release notes mới (check vendor release notes URL) → re-fetch, refresh:
  - Capability matrix scores (xem có capability nào đổi presence/depth không)
  - Pricing (giá thay đổi)
  - Recent releases table (thêm version mới)
  - Update `last_refresh_date`
- Refresh log entry mới vào file vendor.

Cấu hình TTL override qua flag: `/da-po delta --competitor-ttl 14` (rút TTL xuống 14 ngày khi cần).

## Step 5 — Re-render matrix cells bị đụng

Cell `(area, vendor)` cần re-render nếu **MỘT TRONG** điều kiện sau:
- Area thuộc tập bucket bị đụng → re-render cột Smartlog cho area đó.
- Vendor được refresh ở step 4 → re-render toàn bộ 14 ô của vendor đó (vì refresh có thể thay đổi score nhiều area).

Cell không thuộc 2 nhóm trên → giữ nguyên từ matrix lần trước, KHÔNG re-validate.

## Step 6 — Gap delta

Với cell vừa re-render:
- Nếu gap mới phát sinh (đối thủ ✓, ta ✗) → tạo `GAP-NNN` mới, run verdict logic.
- Nếu gap cũ đóng lại (ta đã ✓) → mark gap as `CLOSED` trong gap-analysis file.

Verdict logic (cho gap mới):
1. Capability area có thuộc top-3 relevance lens không? (xem competitor-baseline-template.md → Relevance lens)
   - Có → propose CATCH-UP
   - Không → propose IGNORE
2. Đối thủ nào có → có ≥4/7 đối thủ có? → propose CATCH-UP (industry standard)
3. Chỉ 0–1 đối thủ có + relevance High → propose LEAPFROG (cơ hội khác biệt)
4. User confirm verdict cuối; skill chỉ propose.

## Step 7 — Update artifacts

| File | Action |
|---|---|
| `projects/po/inventory/_latest.json` | Overwrite với snapshot mới, `last_scan_commit` = HEAD SHA |
| `projects/po/inventory/{TODAY}-feature-catalog.md` | KHÔNG re-render full — chỉ append delta section ở cuối nếu cần human view |
| `projects/po/benchmark/{TODAY}-bi-capability-matrix.md` | Render lại CHỈ các row có cell đụng, các row khác `(unchanged since YYYY-MM-DD)` |
| `projects/po/benchmark/{TODAY}-gap-analysis.md` | Append gap delta + close gap đã resolved |
| `projects/po/changelog/{TODAY}-delta.md` | Tạo mới, format ở SKILL.md |
| `projects/po/roadmap-input/{TODAY}-recommendations.md` | Tạo mới chỉ nếu có gap CATCH-UP / LEAPFROG mới |

## Step 8 — Mandatory ending output

```
MODE: D
ARTIFACT_PATHS:
  - projects/po/changelog/2026-05-26-delta.md
  - projects/po/inventory/_latest.json
  - projects/po/benchmark/2026-05-26-gap-analysis.md  (appended)
  - projects/po/roadmap-input/2026-05-26-recommendations.md  (if any)
INVENTORY_SUMMARY: 142 total, +3 new, -1 removed, ~5 changed
BENCHMARK_SUMMARY: 14 areas, 2 areas re-scored, 3 vendors refreshed
GAP_VERDICT_BREAKDOWN: catch_up=+2, leapfrog=+0, ignore=+1, closed=1
HANDOFF_QUEUE: [GAP-024, GAP-025]
NEXT_REFRESH_DUE: 2026-06-02  (1 week)
```

## Cron setup (optional, user-driven)

KHÔNG tự setup cron. Nếu user yêu cầu, đề xuất:

```
CronCreate({
  schedule: "0 9 * * MON",
  prompt: "/da-po delta",
  reason: "weekly PO landscape refresh"
})
```

Trước khi tạo, hỏi user 2 câu:
1. Tần suất phù hợp? (weekly Mon 9h là default — có thể monthly với landscape ít đổi)
2. Có muốn auto-handoff CATCH-UP/LEAPFROG sang `/da-discovery` không, hay chỉ ghi vào queue?

Khuyến nghị: KHÔNG auto-handoff, để PO duyệt verdict trước khi mở discovery (tránh queue ngập).

## Edge cases

| Tình huống | Xử lý |
|---|---|
| `last_scan_commit` không còn trong git history (rebase) | Abort Mode D, đề xuất re-baseline qua Mode A |
| Branch hiện tại = branch khi scan trước, nhưng commit window có merge của branch khác | OK — diff bao trùm merge, vẫn map file đổi bình thường |
| Bucket bị đụng nhưng nội dung file đổi không ảnh hưởng feature (whitespace, comment) | Re-scan vẫn chạy nhưng diff_fields rỗng → entry `CHANGED` nhưng trống → drop khỏi delta |
| Vendor docs URL 404 / paywall mới | Ghi `Source: stale, 404`, không lấy data cũ làm fact mới |
| Cùng 1 file map nhiều bucket | Quét cả 2 bucket (vd. `QueryConfigs/*.json` thuộc cả Modeling và Query Engine) |
| User chạy `delta` 2 lần trong cùng ngày | OK — overwrite file `{TODAY}-*.md` (idempotent với cùng SHA) |

## What Mode D KHÔNG làm

- KHÔNG re-render từng cell unchanged của matrix → tốn token vô ích.
- KHÔNG tự handoff sang `/da-discovery` → output là queue, PO duyệt.
- KHÔNG commit `projects/po/*` lên helix_projects → đó là việc của `/da-projects`.
- KHÔNG tự xoá file delta cũ → giữ history để retro.
- KHÔNG re-baseline khi chỉ 1 commit lẻ trong window — vẫn dùng diff.
