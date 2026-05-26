---
name: da-pm
description: Dùng khi cần lập kế hoạch sprint, roadmap, theo dõi tiến độ, quản lý rủi ro, viết stakeholder update / release note, hoặc bất kỳ tác vụ Project/Product Management nào trên Smartlog Control Tower. Trigger trên "sprint", "roadmap", "kế hoạch", "rủi ro", "stakeholder", "release note", "milestone", "tiến độ", "PM". KHÔNG dùng cho phân tích nghiệp vụ chi tiết (dùng /da-biz-ba) hay phân tích số liệu (dùng /da-data).
user-invocable: true
---

# Smartlog Control Tower — PM Skill (local-only)

Skill này dành riêng cho vai trò **PM/Product Manager** trên dự án Smartlog Control Tower. Mục tiêu: giảm overhead khi lập kế hoạch, theo dõi sprint, và communicate với stakeholder — KHÔNG nhằm thay thế các skill dev-side (`/team`, `/planner`, ...).

## Bối cảnh dự án (luôn áp dụng)

- **Sản phẩm**: Dashboard / monitoring workspace cho logistics, build trên Smartlog Base. Frontend render widget cấu hình được (`WidgetFlashDaily`, `WidgetTxnMove`, ...) trên `react-grid-layout`.
- **Domain logistics**: tender, VFR (Vehicle Fill Rate), transaction move, flash daily, dispatch, ...
- **Stack**: .NET 10 + React 19, multi-tenant theo JWT claim `TenantDBConfiguration`.
- **Đội**: nhiều squad (squad1@gosmartlog.com là user). Có pipeline DEV (`/team`) và DELIVERY (`/delivery-team`) đã định nghĩa.

## Khi nào dùng

| Tình huống | Output mong đợi |
|---|---|
| Lập sprint plan mới | `projects/pm/sprint-<YYYY-WW>/plan.md` với mục tiêu, scope, capacity, risk |
| Update tiến độ giữa sprint | `projects/pm/sprint-<YYYY-WW>/standup-<date>.md` hoặc append vào `progress.md` |
| Viết stakeholder update (weekly/biweekly) | `projects/pm/updates/<YYYY-MM-DD>.md` — định dạng: Done / In Progress / Risks / Asks |
| Risk register | `projects/pm/risks.md` — bảng: Risk / Likelihood / Impact / Owner / Mitigation |
| Release note nội bộ | `projects/pm/releases/<version>.md` |
| Roadmap quý | `projects/pm/roadmap-<YYYY-Q#>.md` |

Tất cả output ở `projects/` đã gitignored (`.gitignore` dòng 52) — an toàn khỏi commit nhầm.

## Quy trình mặc định

1. **Xác định mode**: tạo mới hay cập nhật artifact đang có. Đọc artifact cũ trước khi viết đè.
2. **Convert ngày tương đối → tuyệt đối** ngay khi user nói ("thứ 5 tới" → ghi rõ `2026-05-14`). Không bao giờ để ngày tương đối trong artifact.
3. **Phân loại mệnh đề** trong mọi cập nhật:
   - **Đã xong** — có evidence (commit hash, PR link, screenshot)
   - **Đang làm** — owner + ETA cụ thể
   - **Risk** — likelihood × impact + mitigation đề xuất
   - **Cần stakeholder quyết** — phải ghi rõ ai quyết, deadline quyết
4. **Đối chiếu thực tế** trước khi tuyên bố "Done": chạy `git log --since=...` hoặc `gh pr list` để kiểm chứng, không tin lời kể của ai (kể cả user).
5. **Output ngắn gọn**: stakeholder update không quá 1 trang. Bullet, không paragraph.

## Templates nhanh (copy & fill)

### Stakeholder weekly update

```markdown
# Smartlog Control Tower — Weekly Update <YYYY-MM-DD>

## Done this week
- <feature/PR + link>

## In progress (with ETA)
- <feature> — owner: <name>, ETA: <YYYY-MM-DD>

## Risks
- <risk> — mitigation: <action>

## Asks
- <decision needed> — from: <stakeholder>, by: <date>
```

### Sprint plan

```markdown
# Sprint <YYYY-WW> Plan

**Goal**: <1 câu — outcome, không phải output>
**Capacity**: <man-days available>
**Dates**: <start> → <end>

## Committed scope
| Item | Owner | Estimate | Definition of Done |
|---|---|---|---|

## Stretch
| Item | Owner | Why stretch |
|---|---|---|

## Risks at start
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
```

### Risk register entry

```
## RISK-<NNN>: <tên ngắn>
- **Discovered**: <date>
- **Likelihood**: Low | Medium | High
- **Impact**: Low | Medium | High
- **Owner**: <name>
- **Mitigation**: <action>
- **Status**: Open | Mitigated | Accepted | Closed
```

## Anti-patterns (tránh)

| Sai lầm | Sửa |
|---|---|
| Status update kiểu "đang làm việc" | Phải có % cụ thể hoặc ETA tuyệt đối |
| Risk không có mitigation | Risk không có mitigation = than phiền, không phải PM artifact |
| Sprint goal là output ("xong 5 widget") | Goal phải là outcome ("user xem được tender exception trong 1 dashboard view") |
| Tin tự báo cáo, không verify | Cross-check `git log` / `gh pr list` / screenshot |
| Mix dev planning vào PM artifact | Technical breakdown thuộc `/planner`, PM chỉ track WHAT + WHEN + WHO |

## Khi nào KHÔNG dùng skill này

- **Phân tích nghiệp vụ chi tiết** (process, business rules, stakeholder analysis) → `/da-biz-ba`
- **Phân tích số liệu / metric** (truy vấn DB, định nghĩa KPI) → `/da-data`
- **Viết PRD cho dev** (problem space, AC) → `/ba` (IT BA hiện có)
- **Lập technical implementation plan** → `/planner`
- **Discovery / reframe vấn đề trước khi spec** → `/da-discovery`

## Mandatory ending signals

Mọi invocation kết thúc bằng:

- `ARTIFACT_PATH`: đường dẫn file đã tạo/cập nhật
- `NEXT_ACTION`: hành động tiếp theo (ai, làm gì, khi nào)
- `BLOCKERS`: blocker đang cần stakeholder giải quyết (nếu có)
