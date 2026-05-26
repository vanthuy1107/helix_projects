---
name: da-trace
description: Dùng để audit xem implementation (đặc biệt frontend) có thực sự khớp với business requirement không, và tài liệu giữa các tầng (PRD ↔ plan ↔ code ↔ README/CLAUDE.md ↔ i18n) có đồng nhất không. Sản xuất "drift report" — chỉ ra mâu thuẫn, miss, hoặc behavior trôi khỏi spec. Trigger trên "audit", "trace", "kiểm tra spec", "drift", "kiểm tra UI vs PRD", "tài liệu không đồng nhất", "spec vs implementation", "conformance", "có đúng yêu cầu không". KHÔNG dùng để review code quality (dùng /reviewer), không thay test (dùng /qa-executor).
user-invocable: true
---

# Smartlog Control Tower — Spec/Implementation Trace Audit (local-only)

Skill này trả lời 2 câu hỏi:

1. **Implementation có làm đúng business requirement không?** (frontend code vs PRD vs business rules)
2. **Tài liệu có đồng nhất không?** (PRD ↔ plan ↔ README ↔ CLAUDE.md ↔ i18n string ↔ comment)

KHÔNG phải code review (`/reviewer`) — không phán xét chất lượng code. KHÔNG phải QA execution (`/qa-executor`) — không chạy test case. Đây là **traceability audit** — read-only, ra drift report.

## Tại sao cần skill riêng

Trong dự án có nhiều nguồn "sự thật":
- `docs/product/prd/<feature>.md` — PRD do `/ba` viết
- `docs/feature/<slug>/dev/plan.md` — technical plan do `/planner` viết
- `frontend/src/features/<name>/` — implementation thực tế
- Form/View configs JSON, FormConfig codes (`{MODULE}{TABLE}{TYPE}{SEQ}`)
- i18n string ở `frontend/src/i18n/` hoặc tương đương
- Comments trong code, README, CLAUDE.md các tầng
- Business rules từ `/da-biz-ba` ở `projects/biz/rules/`

Theo thời gian các nguồn này drift. Skill này phát hiện drift trước khi nó thành bug production / hiểu lầm stakeholder.

## Khi nào dùng

| Tình huống | Output |
|---|---|
| Trước UAT — confirm UI đã build đúng PRD | Trace report cho 1 feature |
| Sau hotfix — kiểm tra hotfix có cập nhật đủ tài liệu không | Drift report ngắn |
| Định kỳ (cuối quý) — audit doc consistency toàn module | Module-wide trace report |
| Stakeholder báo "UI khác mô tả" — verify | Single-claim trace (1 trang) |
| Trước khi handoff sang khách / partner | Conformance summary |

## Output

| Artifact | Path |
|---|---|
| Feature trace report | `projects/trace/<feature-slug>-<YYYY-MM-DD>.md` |
| Module-wide audit | `projects/trace/module-<name>-<YYYY-MM-DD>.md` |
| Single-claim verification | `projects/trace/claim-<slug>-<YYYY-MM-DD>.md` |

Đều nằm trong `projects/` (gitignored).

## Quy trình bắt buộc — 3 phase

### Phase 1: Establish "sources of truth"

Trước khi audit, liệt kê **đầy đủ** các nguồn áp dụng cho scope:

| Source type | Where to look | Có/Không |
|---|---|---|
| PRD | `docs/product/prd/<feature>.md` | |
| Technical plan | `docs/feature/<slug>/dev/plan.md` | |
| Business rules (business-side) | `projects/biz/rules/` | |
| Frontend implementation | `frontend/src/features/<name>/` | |
| Backend endpoint contract | `backend/src/Smartlog.Application.Contracts/` | |
| FormConfig / QueryConfig | `backend/src/**/QueryConfigs/`, FormConfig DB seed | |
| i18n strings | `frontend/src/i18n/` (hoặc đường tương ứng) | |
| Route registration | `frontend/src/routeTree.gen.ts` (auto-gen, đọc thôi) | |
| README / CLAUDE.md các tầng | repo root, `backend/`, `frontend/`, feature folders | |

Nếu source nào KHÔNG có (vd PRD chưa viết) — đánh dấu **"missing source"** trong report. Đây tự nó đã là drift.

### Phase 2: Build claim matrix

Liệt kê từng **claim** (mệnh đề kiểm chứng được) từ source ưu tiên cao nhất (thường là PRD), sau đó chéo với implementation:

| # | Claim (từ PRD) | PRD ref | Expected behavior | Implementation evidence | Match? | Note |
|---|---|---|---|---|---|---|
| 1 | "Operator có thể filter tender theo Carrier" | PRD §3.2 | Có filter dropdown Carrier trong tender list | `frontend/src/features/tender/components/TenderFilter.tsx:42` — có | ✅ | |
| 2 | "Tender award button chỉ enable khi status = Open" | PRD §4.1 | Button disabled với status khác Open | `TenderActions.tsx:88` — chỉ check `!isLoading`, KHÔNG check status | ❌ | Missing business rule |

**Quy tắc claim**:
- 1 claim = 1 mệnh đề kiểm chứng được (testable). KHÔNG dùng claim mơ hồ kiểu "UX phải tốt".
- Implementation evidence PHẢI là path:line cụ thể, không phải lời kể.
- Nếu không tìm được evidence sau khi grep/read kỹ → đánh dấu `❌ Not implemented` (không phải "không tìm thấy" — đó là kết luận audit).

### Phase 3: Cross-doc consistency check

Riêng cho phần "tài liệu đồng nhất", chạy thêm các check sau:

| Check | Cách chạy | Drift điển hình |
|---|---|---|
| Term consistency | Grep từ khóa domain (Tender, VFR, Carrier...) trong PRD vs i18n vs comments — chuẩn hoá viết hoa, số ít/nhiều, dấu | "Tender" trong PRD vs "tenders" trong i18n vs "Bid" trong code |
| Status enum consistency | List status trong PRD vs enum frontend (Zod) vs enum backend (C#) vs DB seed | PRD nói 5 status, code có 6 |
| FormConfig code | PRD/spec ghi code nào → grep trong DB seed + frontend ViewConfig | PRD ghi `SLGTNDG01`, code dùng `SLGTNDR01` |
| API path & method | PRD/contract ghi endpoint nào → check Refit client + controller | PRD nói POST, code dùng PUT |
| i18n key coverage | Mọi visible string trong UI có key i18n không, hay hardcode? | Hardcoded VI/EN trong JSX |
| Default value | PRD specify default → check Zod schema default + form initial value | PRD nói default = "All", form khởi tạo = empty |
| Edge case behavior | Empty state, error state, loading state có theo PRD không | PRD spec empty state, UI render bảng trống không message |

## Drift Report Template

```markdown
# Trace Report — <Feature/Module>

**Date**: <YYYY-MM-DD>  
**Auditor**: <name>  
**Scope**: <feature slug + commit/branch reference>  
**PRD version audited against**: <version + date>

## Sources used
| Source | Path | Status |
|---|---|---|
| PRD | <path> | Present @ v<x> |
| Plan | <path> | Present / Missing |
| ... | | |

## Drift summary
- ✅ Conformant claims: <N>
- ⚠️ Minor drift (terminology / cosmetic): <N>
- ❌ Functional drift (behavior wrong/missing): <N>
- 🚫 Missing source (no PRD/plan to verify against): <N>

## Claim matrix
| # | Claim | Source ref | Implementation evidence | Status | Severity |
|---|---|---|---|---|---|
| 1 | ... | PRD §x.y | path:line | ✅ / ⚠️ / ❌ / 🚫 | High/Med/Low |

## Cross-doc consistency findings
| # | Drift type | Detail | Sources in conflict | Severity |
|---|---|---|---|---|
| 1 | Terminology | "Tender" vs "Bid" | PRD §1, i18n key auction.bid_now | Low |
| 2 | Enum | Status list mismatch | PRD §3 has 5 / Zod has 6 | High |

## Recommended actions
| # | Action | Owner | Type | Effort |
|---|---|---|---|---|
| 1 | Add status check on award button | <Frontend> | Code fix | S |
| 2 | Update PRD to reflect 6th status `Cancelled` | <BA> | Doc update | S |
| 3 | Decide which is canonical: 5 or 6 statuses | <PM/BA> | Decision | M |

## Open questions (block sign-off)
- Q: Status `Cancelled` có thực sự cần không? — owner: <BA> — by: <date>
```

## Anti-patterns (tránh)

| Sai lầm | Sửa |
|---|---|
| Claim mơ hồ ("UX phải tốt") | Claim phải kiểm chứng được — outcome cụ thể, có thể yes/no |
| "Implementation evidence: thấy có" | Phải là path:line, không phải lời kể |
| Đánh dấu drift mà không phân loại severity | High/Med/Low ép decision: fix ngay vs tolerate vs ignore |
| Phán quyết "code sai" mà không xét lại PRD có sai không | PRD có thể outdated — drift có khi do PRD chưa update, action là update PRD chứ không sửa code |
| Audit toàn dự án 1 lúc | Time-box theo feature/module — audit dài quá thì stakeholder không đọc |
| Không record commit/branch audited | Audit chụp 1 thời điểm — phải ghi commit hash để repro được |
| Trộn audit với fix | Skill này read-only. Fix là việc của `/frontend` / `/backend` / `/ba` (cập nhật PRD) sau khi xem report |

## Process tip — dùng GitNexus nếu sẵn

Project này có GitNexus indexed (xem CLAUDE.md). Khi audit 1 feature lớn:

```
gitnexus_query({query: "<feature concept>"})       # tìm execution flow liên quan
gitnexus_context({name: "<key component>"})        # 360° view 1 component
```

Giúp đảm bảo không miss code path khi tìm implementation evidence.

## Khi nào KHÔNG dùng skill này

- Đánh giá code quality / pattern → `/reviewer`
- Chạy test case kiểm tra functional → `/qa-executor`
- Viết test plan → `/qa-planner`
- Sửa drift sau khi phát hiện → `/frontend` / `/backend` / `/ba` (update PRD)
- Audit security / OWASP → `/security-review` (built-in)

## Mandatory ending signals

- `ARTIFACT_PATH`: trace report
- `DRIFT_COUNT`: tổng số drift theo severity (vd `2 High / 3 Med / 5 Low`)
- `BLOCKING_QUESTIONS`: số câu hỏi cần stakeholder quyết để chốt audit
- `RECOMMENDED_NEXT`: action đề xuất (fix code / update PRD / cần decision)

---

## Pre-Ship — Clean Code Drift

Trace report là markdown read-only, KHÔNG ship code. Nhưng khi audit phát hiện drift kiểu **vi phạm Clean Code** — ghi rõ severity và cite rule nào trong **[`.claude/skills/da-ship/references/clean-code.md`](.claude/skills/da-ship/references/clean-code.md)** bị phá:

| Loại drift | Clean Code rule bị phá | Severity gợi ý |
|---|---|---|
| Term lệch giữa PRD / i18n / code (vd `Tender` vs `Bid`) | #1 Meaningful Names | High |
| SQL widget có CTE `t1`, `tmp_a` không mang nghĩa | #1 Meaningful Names | Med |
| Logic OTIF lặp giữa 3 widget, không reference sql-registry | #3 DRY | High |
| Comment trong code paraphrase code thay vì giải thích WHY | #4 WHY > WHAT | Low |
| Edge case PRD spec (empty state) không handle trong UI | #5 Boundaries | High |
| File `-v2`, `-final`, `-copy` còn tồn tại trong codebase | #7 Boy Scout | Med |

Drift loại này có thể là **action item cho `/da-ship`**: khi user chuẩn bị ship change đụng tới symbol/file đó → /da-ship Gate 2 sẽ flag lại. Trace report nên đề xuất ai fix (frontend/backend/BA) và thuộc rule Clean Code nào.
