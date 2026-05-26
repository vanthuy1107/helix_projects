---
description: >-
  Dùng để audit xem implementation (đặc biệt frontend) có thực sự khớp với business requirement không,
  và tài liệu giữa các tầng (PRD ↔ plan ↔ code ↔ README/CLAUDE.md ↔ i18n) có đồng nhất không. Sản xuất
  "drift report" — chỉ ra mâu thuẫn, miss, hoặc behavior trôi khỏi spec. Trigger trên "audit",
  "trace", "kiểm tra spec", "drift", "kiểm tra UI vs PRD", "tài liệu không đồng nhất", "spec vs
  implementation", "conformance", "có đúng yêu cầu không". KHÔNG dùng để review code quality (dùng
  /reviewer), không thay test (dùng /qa-executor).
---

Engage the `da-trace` skill - follow the instructions in `.claude/skills/da-trace/SKILL.md` to handle this request.

Treat `/da-trace` as the user explicitly asking to run that skill. If you need the full skill body, read the SKILL.md file directly.