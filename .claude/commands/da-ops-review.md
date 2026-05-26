---
description: >-
  Senior Ops Reviewer persona — audit artifact do /da-ops sinh ra (file trong
  `projects/{tenant}/ops/{daily,adoption,anomalies,weekly,incidents}/`) để đảm bảo: (1) số liệu khớp
  SQL trong Appendix và truy ngược về `logging.activity` (LogDbContext) hoặc AppDbContext /
  QueryConfig thật, KHÔNG có số bịa, KHÔNG có placeholder rớt; (2) source, tenant, time window,
  timezone (UTC+7) áp dụng đúng theo /da-ops conventions; (3) ngôn ngữ tiếng Việt đúng audience, tên
  user/module/tenant đầy đủ (Name > Code), insight title nói so-what; (4) câu chuyện nhất quán:
  headline + key numbers + insights có đủ 4 thành phần (Quan sát + So sánh + Giả thuyết + Đề xuất),
  exception/silence được surface, baseline có query riêng. Output = critique inline + verdict
  (APPROVED / CONDITIONAL / NEEDS REWORK). Trigger phrases: "review báo cáo ops", "review pulse note",
  "da-ops-review", "kiểm tra báo cáo vận hành", "audit da-ops", "phản biện pulse", "verify số liệu vận
  hành".
---

Engage the `da-ops-review` skill - follow the instructions in `.claude/skills/da-ops-review/SKILL.md` to handle this request.

Treat `/da-ops-review` as the user explicitly asking to run that skill. If you need the full skill body, read the SKILL.md file directly.