---
description: >-
  Dùng khi nhận một danh sách hỗn hợp bug + feedback + improvement + question từ khách hàng (file
  Excel/CSV/Markdown/issue export) và cần tổ chức, phân loại, dedupe, ưu tiên, rồi route từng item về
  đúng pipeline (bug → /qa-executor, drift → /da-trace, feature mới → /da-discovery, PRD update →
  /ba). Đứng TRƯỚC các skill specialist đó. Trigger trên "triage", "phân loại bug", "feedback list",
  "intake", "rà soát feedback", "tổ chức bug list", "khách báo nhiều thứ", "UAT feedback", "rollout
  feedback", "Excel khách gửi". KHÔNG dùng để fix bug đơn lẻ (/debugger) hay viết bug report formal
  (/qa-executor) — đó là bước SAU.
---

Engage the `da-triage` skill - follow the instructions in `.claude/skills/da-triage/SKILL.md` to handle this request.

Treat `/da-triage` as the user explicitly asking to run that skill. If you need the full skill body, read the SKILL.md file directly.