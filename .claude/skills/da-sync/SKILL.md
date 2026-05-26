---
name: da-sync
description: >-
  Dùng để đồng bộ các skill `da-*` (và phần `da-*.md` trong `.claude/commands/`
  nếu còn dùng) giữa workspace local và repo `helix_projects`. Skill luôn chạy
  `projects/scripts/sync-da-skills.ps1 -Mode check` trước để show drift, rồi hỏi
  user hướng push (workspace → projects) hay pull (projects → workspace) hay
  cancel, sau đó chạy `-Mode <chosen> -Force`. Trigger trên "sync skill",
  "sync da", "push skill cho team", "pull skill từ team", "đồng bộ skill",
  "team có skill mới", "tôi sửa skill xong", "da-sync". KHÔNG dùng để tự sửa
  nội dung skill (user edit trực tiếp `.claude/skills/da-*/SKILL.md`).
user-invocable: true
---

# /da-sync — Đồng bộ da-* skills giữa workspace ↔ helix_projects

Mọi skill `da-*` tồn tại 2 nơi trên máy mỗi developer:

| Nơi | Vai trò |
|---|---|
| `<repo>/.claude/skills/da-*/` | Claude Code load chỗ này lúc start. Gitignored khỏi main repo. |
| `<repo>/projects/.claude/skills/da-*/` | Commit vào `helix_projects` (repo riêng), share với team. |

Script `projects/scripts/sync-da-skills.ps1` strict-mirror giữa 2 phía với 3 mode (`check` / `push` / `pull`). Skill này wrap script: luôn check trước, show drift, hỏi hướng.

---

## Workflow

### S1. Resolve script path

Path tuyệt đối: `c:\smartlog_workspace\smartlog-control-tower\projects\scripts\sync-da-skills.ps1`.

Nếu file không tồn tại → STOP, báo user: `helix_projects` chưa được clone vào `projects/`. Đề xuất:
```
git clone https://github.com/vanthuy1107/helix_projects.git c:\smartlog_workspace\smartlog-control-tower\projects
```

### S2. Run drift check

```powershell
& "c:\smartlog_workspace\smartlog-control-tower\projects\scripts\sync-da-skills.ps1" -Mode check
```

Đọc output:

| Output | Hành động |
|---|---|
| "No drift. Both sides are identical" + exit 0 | Report success 1 dòng, STOP. |
| "Drift detected - N file(s)" + danh sách | Tiếp S3. |
| Exit code khác 0/1 | Surface raw output, hỏi user (có thể script lỗi). |

### S3. Show drift + hỏi hướng

Show user full danh sách drift verbatim (giữ format `+ workspace`, `+ projects`, `~ differs`). Sau đó hỏi:

```
Drift detected. Pick direction:
  - push   = workspace → projects (vừa sửa skill local, muốn share team)
  - pull   = projects → workspace (teammate vừa push update)
  - cancel = không sync
```

Diễn dịch drift để gợi ý hướng (KHÔNG tự quyết):
- Chỉ có `+ workspace ...` → user vừa sửa local → khả năng cao là **push**.
- Chỉ có `+ projects ...` → teammate đã push trước → khả năng cao là **pull**.
- `~ differs ...` → 2 bên đụng cùng file → CẢNH BÁO user rằng chọn 1 hướng sẽ overwrite phía kia, hỏi rõ ai là canonical.

### S4. Run chosen direction

Chỉ khi user explicit chọn `push` hoặc `pull`:

```powershell
& "c:\smartlog_workspace\smartlog-control-tower\projects\scripts\sync-da-skills.ps1" -Mode <push|pull> -Force
```

`-Force` để skip interactive prompt vì user đã confirm.

User nói `cancel` hoặc mơ hồ → STOP, không chạy.

### S5. Post-action

| Sau khi | Nhắc user |
|---|---|
| **push** | Tiếp theo cần commit + push `projects/` (gọi `/da-projects` Task A + B). Show command gợi ý: `git -C "<projects>" status` rồi `add .claude/` rồi `commit` rồi `push origin main`. KHÔNG tự chạy commit/push. |
| **pull** | **Restart Claude Code** để load skill mới (Claude Code chỉ scan `.claude/skills/` lúc start). |

---

## Quy tắc

- **Luôn check trước.** Không bao giờ push/pull blind.
- **Strict mirror**: cả push và pull XOÁ file thừa ở phía destination. Show drift trước khi hỏi hướng để user thấy chính xác cái gì sắp move.
- **Không chạy cả push lẫn pull cùng 1 lần invoke.**
- **Script chỉ chạm `.claude/skills/da-*/`** (và `.claude/commands/da-*.md` nếu pair commands còn được sync). Non-da assets script ignore — đừng cố mở rộng scope.
- **Không tự commit + push** sau khi push sync — luôn để user qua `/da-projects` flow.

---

## Anti-patterns

| ❌ Không làm | ✅ Thay bằng |
|---|---|
| Tự đoán hướng (push/pull) mà không hỏi user | Show drift, hỏi explicit, chờ trả lời |
| Chạy `-Force` ngay khi user mới gọi `/da-sync` | `-Force` chỉ dùng SAU khi user đã chọn hướng |
| Sửa nội dung skill trong khi sync | Sync = transport-only; user tự edit `.claude/skills/da-*/SKILL.md` rồi mới sync |
| Tự commit + push helix_projects sau khi push | Show command gợi ý, chờ user xác nhận (theo `/da-projects` rule) |
| Approve sync khi `~ differs` nhiều file mà không cảnh báo overwrite | Cảnh báo: "Hướng X sẽ overwrite N file ở phía Y — chắc chắn?" |

---

## STOP Points

⏸ Script không tồn tại → STOP, hướng dẫn clone helix_projects.
⏸ User chọn `cancel` → STOP, không chạy gì.
⏸ Drift có nhiều `~ differs` → cảnh báo overwrite, xin xác nhận thêm.
⏸ Script exit code khác 0/1 → surface error, không tự retry.

---

## Mandatory Ending Signal

```
DA-SYNC ACTION
─────────────────────────────────
Drift before   : N file(s)
Direction      : push / pull / cancel
Files moved    : M
Drift after    : 0 (verified) | unknown
Next step      : commit-push-projects / restart-claude-code / none
─────────────────────────────────
```
