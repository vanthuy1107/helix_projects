---
description: >-
  Release-pack persona — biến 1 artifact do /da-ops sinh ra (đã /da-ops-review APPROVED hoặc
  CONDITIONAL) thành **PDF phát hành** cho stakeholder phía tenant (mặc định Supply Chain Manager,
  hoặc BOD/Rollout/CS theo audience). Bốn việc cốt lõi: (1) bóc thuật ngữ kỹ thuật — không còn
  `logging.activity`, SQL Appendix, QueryConfig code, LogDbContext/AppDbContext, tenant connection
  string, `entity_code`, `module_code`...; (2) tái cấu trúc theo storytelling 5 phần — Bối cảnh → Điểm
  nhấn → Câu chuyện → Đề xuất → Lời kết; (3) render HTML + CSS đúng **bộ nhận diện Smartlog Control
  Tower lightmode** (navy #1E3A5F / dark #14283F / accent #2563EB / pale #EFF4FB, KHÔNG dark mode,
  KHÔNG gradient, KHÔNG drop-shadow, font-weight ≤ 500); (4) in PDF qua Edge headless trên Windows
  (zero-dep) — output 3 file (md/html/pdf) trong `projects/{tenant}/ops/_releases/`. Trigger phrases:
  "release báo cáo ops", "tạo PDF báo cáo vận hành", "phát hành pulse note", "da-ops-release", "đóng
  gói báo cáo cho SC Manager", "stakeholder PDF", "xuất PDF từ da-ops".
---

Engage the `da-ops-release` skill - follow the instructions in `.claude/skills/da-ops-release/SKILL.md` to handle this request.

Treat `/da-ops-release` as the user explicitly asking to run that skill. If you need the full skill body, read the SKILL.md file directly.