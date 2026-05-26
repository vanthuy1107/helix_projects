---
description: >-
  Dùng khi cần thao tác trên repo `projects/` — repo độc lập nằm bên trong cây thư mục
  `smartlog-control-tower/` nhưng có `.git` riêng và remote riêng (`helix_projects` trên GitHub).
  Skill này ép mọi git operation (status, add, commit, push, pull, branch, log, diff, stash) chạy với
  working tree là `projects/`, KHÔNG đụng vào repo chính. File operation (Read/Write/Edit/Glob/ Grep)
  chỉ được phép nhắm vào path nằm dưới `projects/`. Trigger trên "projects repo", "helix_projects",
  "commit projects", "push projects", "pull projects", "tạo branch trong projects", "diff projects",
  "trạng thái projects", "đẩy mondelez/panasonic/pm/trace/assessments lên git", "sync tenant docs".
  KHÔNG dùng để sửa code backend/frontend (đó là repo chính — dùng /backend hoặc /frontend) hoặc audit
  code trước push (dùng /da-ship).
---

Engage the `da-projects` skill - follow the instructions in `.claude/skills/da-projects/SKILL.md` to handle this request.

Treat `/da-projects` as the user explicitly asking to run that skill. If you need the full skill body, read the SKILL.md file directly.