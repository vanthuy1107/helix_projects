---
name: da-retro
description: Dùng sau khi sprint/release/initiative kết thúc — chạy retrospective có cấu trúc, ép rút bài học và biến thành action item cụ thể. Cảm hứng từ /retro của gstack. Trigger trên "retro", "retrospective", "post-mortem", "rút kinh nghiệm", "lessons learned", "review sprint", "after-action". KHÔNG dùng để debug bug đơn lẻ (dùng /debugger) — retro là về quy trình, không về 1 lỗi cụ thể.
user-invocable: true
---

# Smartlog Control Tower — Retrospective Skill (local-only)

Cảm hứng từ `/retro` trong [gstack](https://github.com/garrytan/gstack). Mục tiêu: biến trải nghiệm sprint/release thành **action item** mà sprint sau thực thi được, không để retro biến thành than phiền.

## Triết lý

- Một retro tốt sản xuất ≤5 action item, mỗi cái có owner + deadline.
- Nếu retro 3 sprint liên tiếp ra cùng 1 vấn đề mà không action → vấn đề không phải ở retro, ở việc thực thi action item.
- Retro là cho **team learning**, không phải cho stakeholder report (cái đó là `/da-pm`).

## Khi nào dùng

| Trigger | Scope |
|---|---|
| Cuối sprint | Sprint retro — gọn, 30 phút |
| Sau release lớn | Release retro — sâu hơn, gồm cả production behavior |
| Sau incident production | Post-mortem — blameless, focus root cause |
| Cuối quý | Quarter retro — pattern across nhiều sprint |

## Output

| Artifact | Path |
|---|---|
| Sprint retro | `projects/retro/sprint-<YYYY-WW>.md` |
| Release retro | `projects/retro/release-<version>.md` |
| Post-mortem | `projects/retro/postmortem-<YYYY-MM-DD>-<incident>.md` |
| Quarter retro | `projects/retro/quarter-<YYYY-Q#>.md` |

Lessons học được từ retro mà có giá trị lâu dài → cập nhật vào `docs/lessons/<team>.md` (CLAUDE.md root đã chỉ định convention này).

## Quy trình mặc định

### 1. Gather data — facts trước cảm xúc
- Liệt kê: tickets done, PR merged, bug found, incident, deadline miss/hit.
- Số liệu: velocity vs commit, lead time, escape defect, deploy count.
- Đối chiếu với plan ban đầu (sprint plan từ `/da-pm`): cái gì commit nhưng không xong? Tại sao?

### 2. Generate insights — 4 cột (mặc định)
Dùng format **What worked / What didn't / What surprised / What confused** thay vì "Stop/Start/Continue" mơ hồ.

| Cột | Câu hỏi gợi ý |
|---|---|
| **What worked** | Practice nào nên giữ? Quyết định nào sáng suốt? |
| **What didn't** | Cái gì cản trở? Cái gì tốn thời gian không cần thiết? |
| **What surprised** | Phát hiện ngoài dự đoán (tốt hoặc xấu)? |
| **What confused** | Quy trình nào không rõ? Vai trò chồng chéo ở đâu? |

### 3. Decide actions — strict format
Mỗi action item phải có 4 trường, không thiếu trường nào:
- **Action**: imperative, cụ thể ("Tạo template PR cho widget" — không phải "cải thiện code review")
- **Owner**: 1 người (nếu nhiều người = không có ai)
- **Deadline**: ngày tuyệt đối
- **Definition of Done**: làm sao biết action xong

Nếu không viết được 4 trường này = chưa actionable, để dạng "topic to discuss" thay vì giả vờ action.

### 4. Carry-over check
Trước khi đóng retro, đọc lại retro sprint TRƯỚC. Action item nào chưa done? Tại sao? Có cần tái-commit hay drop?

## Templates

### Sprint retro

```markdown
# Sprint <YYYY-WW> Retro

**Date**: <YYYY-MM-DD>  
**Participants**: <names>  
**Sprint outcome**: Hit goal | Partial | Miss

## Facts
- Committed: <N> items / Done: <M> items
- Velocity: <points> (vs avg <X>)
- Bugs escaped: <N>
- Notable events: <incident, hotfix, scope change>

## Carry-over from last retro
| Last action | Status | Note |
|---|---|---|

## Insights
### What worked
- <observation> — vì sao quan trọng

### What didn't
- <observation> — vì sao quan trọng

### What surprised
- <observation>

### What confused
- <observation>

## Actions for next sprint
| # | Action | Owner | Deadline | DoD |
|---|---|---|---|---|

## Topics to revisit (not actionable yet)
- <topic + lý do chưa thành action>
```

### Post-mortem (incident)

```markdown
# Post-mortem: <incident name>

**Date of incident**: <YYYY-MM-DD HH:mm>  
**Detected**: <how + when>  
**Resolved**: <YYYY-MM-DD HH:mm>  
**Severity**: Sev1 | Sev2 | Sev3  
**Tenants impacted**: <list>  
**Author**: <name>

## Timeline (UTC+7)
| Time | Event | Source |
|---|---|---|
| HH:mm | <event> | <log/alert/user report> |

## Impact
- Users affected: <số lượng + role>
- Business impact: <transactions blocked, data loss, ...>
- Duration: <N phút/giờ>

## Root cause
<1-3 đoạn — root cause kỹ thuật + điều kiện kích hoạt>

## What went well
- <detection, response, communication>

## What went wrong
- <detection delay, false alarm, unclear runbook, ...>

## Actions (blameless)
| # | Action | Owner | Deadline | DoD | Type (prevent/detect/mitigate) |
|---|---|---|---|---|---|

## Lessons for `docs/lessons/`
- <bài học có giá trị lâu dài cần lưu>
```

## Anti-patterns (tránh)

| Sai lầm | Sửa |
|---|---|
| Retro thành phiên than phiền | Format 4 cột + bắt buộc 4 trường action ép focus vào quyết định |
| Action không có owner ("team sẽ cải thiện") | 1 owner cụ thể; nếu không gán được → xoá action |
| Action không có DoD | Không đo được = không làm được; thêm DoD hoặc loại bỏ |
| Lặp lại action 3 sprint không done | Stop adding it. Hỏi vì sao không done — đó mới là action thực |
| Post-mortem đổ lỗi cá nhân | Blameless: tập trung vào hệ thống/quy trình cho phép sai sót xảy ra |
| Không carry-over check | Mỗi retro phải mở retro trước, review action item cũ trước khi sinh action mới |
| Lessons học được không lưu | Lesson có giá trị lâu dài → cập nhật `docs/lessons/<team>.md` (đã định nghĩa trong CLAUDE.md) |

## Khi nào KHÔNG dùng skill này

- Debug 1 bug cụ thể → `/debugger` (retro về 1 incident chỉ phù hợp khi nó là post-mortem có scope)
- Stakeholder update → `/da-pm`
- Team performance review cá nhân → KHÔNG dùng AI cho việc này, là việc của manager 1-1

## Mandatory ending signals

- `ARTIFACT_PATH`: file retro
- `ACTION_COUNT`: số action item
- `LESSONS_PROMOTED`: list lesson đã copy sang `docs/lessons/...` (nếu có)
- `CARRYOVER_OPEN`: số action carry-over còn open sau retro này
