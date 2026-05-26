---
name: da-projects
description: >-
  Dùng khi cần thao tác trên repo `projects/` — repo độc lập nằm bên trong cây
  thư mục `smartlog-control-tower/` nhưng có `.git` riêng và remote riêng
  (`helix_projects` trên GitHub). Skill này ép mọi git operation (status, add,
  commit, push, pull, branch, log, diff, stash) chạy với working tree là
  `projects/`, KHÔNG đụng vào repo chính. File operation (Read/Write/Edit/Glob/
  Grep) chỉ được phép nhắm vào path nằm dưới `projects/`. Trigger trên
  "projects repo", "helix_projects", "commit projects", "push projects", "pull
  projects", "tạo branch trong projects", "diff projects", "trạng thái
  projects", "đẩy mondelez/panasonic/pm/trace/assessments lên git", "sync
  tenant docs". KHÔNG dùng để sửa code backend/frontend (đó là repo chính —
  dùng /backend hoặc /frontend) hoặc audit code trước push (dùng /da-ship).
user-invocable: true
---

# /da-projects — Cô lập thao tác lên repo `projects/`

`projects/` là một **git repo độc lập** sống bên trong cây thư mục `smartlog-control-tower/`:

| Field | Value |
|---|---|
| Path tuyệt đối | `c:\smartlog_workspace\smartlog-control-tower\projects\` |
| Remote | `https://github.com/vanthuy1107/helix_projects.git` |
| Default branch | `main` |
| Quan hệ với repo chính | **Gitignored** ở dòng 52 (`projects/`) của main `.gitignore` |
| Mục đích | Per-tenant workspace: assessments, mondelez, panasonic, pm, trace |

Khi user gọi `/da-projects`, bạn hiểu rằng:

1. **Mọi git command phải chạy trên repo `projects/`** — không phải repo chính.
2. **Mọi file operation phải nằm trong `projects/`** — Read/Write/Edit/Glob/Grep ngoài path này là sai phạm.
3. **Không bao giờ chạy `git ...` ở repo chính trong session này** — kể cả `git status` để "xem tình hình tổng" cũng cấm; nếu cần, mở session khác.

Lý do tồn tại: rất dễ nhầm `git commit` ở root (sẽ thấy `projects/` là untracked — main repo gitignored nên không sao, nhưng mọi file khác trong main repo sẽ bị stage chung). Skill này đóng vai trò context guard.

---

## 🎯 Hard Rules

### R1. Mọi git command PHẢI có `-C "<projects-path>"`

```powershell
# ĐÚNG
git -C "c:\smartlog_workspace\smartlog-control-tower\projects" status
git -C "c:\smartlog_workspace\smartlog-control-tower\projects" add mondelez/
git -C "c:\smartlog_workspace\smartlog-control-tower\projects" commit -m "..."
git -C "c:\smartlog_workspace\smartlog-control-tower\projects" push origin main

# SAI (chạy trên repo chính)
git status
git -C "c:\smartlog_workspace\smartlog-control-tower" status
cd projects; git status  # cd làm thay đổi shell state liên session — fragile
```

**Ngoại lệ duy nhất:** nếu user explicit yêu cầu so sánh gitignore status / kiểm tra main repo có pick up untracked không (vd "kiểm main repo có thấy projects/ không") → cho phép `git check-ignore -v projects/...` ở root, nhưng KHÔNG modify gì.

### R2. Mọi file path phải resolve về dưới `projects/`

Trước khi gọi Read/Write/Edit/Glob/Grep, verify path bắt đầu bằng `c:\smartlog_workspace\smartlog-control-tower\projects\`. Nếu user yêu cầu "sửa file X" mà X ngoài `projects/` → STOP, hỏi lại: "X nằm ở `<actual-path>`, không thuộc repo `projects/`. Bạn muốn (a) chuyển sang skill khác để sửa file đó, hay (b) ý là 1 file tương tự trong `projects/`?"

### R3. KHÔNG `git add -A` / `git add .` ở root

Kể cả trong `projects/`, ưu tiên `git add <path-cụ-thể>`. `git add .` chỉ OK khi user explicit confirm và đã `git status` để verify staged list không chứa rác.

### R4. KHÔNG push lên `origin/main` không hỏi

User confirm trước mọi `git push`. Nếu là `push --force` lên `main` → từ chối thẳng, đề xuất `--force-with-lease` lên feature branch hoặc revert+commit mới.

### R5. KHÔNG commit secrets

Trước khi commit: scan diff cho `.env`, `password=`, `connection`, `api_key`, `Bearer `, `eyJ` (JWT prefix), connection string MSSQL/PG/CH. Phát hiện → STOP, báo user remove + xem có cần rotate không.

### R6. KHÔNG dùng `--no-verify` hoặc bỏ hook

Nếu commit fail vì hook, fix root cause. Không bypass.

### R7. Commit message convention (giống `/da-ship`)

- Format `<type>(<scope>): <subject>`, type ∈ {feat, fix, chore, refactor, docs, perf}.
- Scope thường là tenant (`mondelez`, `panasonic`, `pm`, `trace`, `assessments`) hoặc section (`mondelez/flash-daily`, `pm/reviews`).
- KHÔNG `Co-Authored-By: Claude` trailer. KHÔNG `🤖 Generated with Claude Code`. KHÔNG AI attribution.
- Subject hiện tại, không quá 70 ký tự. Body (nếu có) giải thích WHY.

---

## Pre-flight (chạy ngay khi `/da-projects` được gọi)

1. **Verify repo tồn tại + remote đúng:**
   ```powershell
   git -C "c:\smartlog_workspace\smartlog-control-tower\projects" rev-parse --is-inside-work-tree
   git -C "c:\smartlog_workspace\smartlog-control-tower\projects" remote -v
   ```
   Remote phải là `helix_projects.git`. Nếu khác → STOP, cảnh báo user.

2. **Show current state:**
   ```powershell
   git -C "<projects>" status --short
   git -C "<projects>" branch --show-current
   git -C "<projects>" log --oneline -3
   ```

3. **Hỏi rõ ý định nếu user gọi mơ hồ** (ví dụ chỉ "/da-projects"): "Bạn muốn (a) xem trạng thái, (b) commit thay đổi, (c) push, (d) pull, (e) tạo/đổi branch, hay (f) thao tác file?"

---

## Workflow theo loại task

### Task A — Commit thay đổi local

1. `git -C <projects> status --short` → review từng file.
2. Với mỗi modified/untracked: confirm thuộc scope user mô tả; nếu rác (`.tmp`, `~$...`, `Thumbs.db`, output Excel khách gửi đi) → đề xuất xoá hoặc add vào `projects/.gitignore` thay vì commit.
3. Stage cụ thể: `git -C <projects> add mondelez/flash-daily/...` — KHÔNG `add -A`.
4. Verify staged: `git -C <projects> diff --cached --stat`.
5. Compose commit message theo R7. Show cho user xác nhận.
6. Commit qua HEREDOC để giữ format:
   ```powershell
   git -C "<projects>" commit -m @'
   docs(mondelez): add flash-daily storytelling spec v1.1.0

   Why: anchor source-of-truth for L1-L6 layout so widget code
   pulls canonical SQL from §22 instead of embedding defaults.
   '@
   ```
   PowerShell here-string single-quoted (`@'...'@`) để literal — không expand `$`. Closing `'@` phải ở column 0.
7. Confirm: `git -C <projects> log -1 --stat`.

### Task B — Push

1. Verify branch hiện tại: `git -C <projects> branch --show-current`.
2. Verify ahead/behind: `git -C <projects> status -sb`.
3. Hỏi user: "Push `<branch>` lên `origin/<branch>`?" — chờ confirm.
4. `git -C <projects> push origin <branch>` (lần đầu thêm `-u`).
5. KHÔNG `--force` không hỏi. Nếu push reject (non-fast-forward) → pull/rebase trước, KHÔNG force giải quyết.

### Task C — Pull (sync from remote)

Mặc định **rebase** (giữ history phẳng, tránh merge commit rác cho repo docs):

```powershell
git -C "<projects>" fetch origin
git -C "<projects>" status -sb
# nếu có dirty:
git -C "<projects>" stash push -m "da-projects auto-stash"
git -C "<projects>" rebase origin/<branch>
git -C "<projects>" stash pop  # nếu có stash
```

Nếu conflict → STOP, show user và để user resolve. KHÔNG auto-resolve giùm.

### Task D — Tạo / đổi branch

```powershell
git -C "<projects>" switch -c feat/<scope>-<short-slug>     # tạo mới từ HEAD
git -C "<projects>" switch <existing-branch>                 # chuyển
```

Branch name: `feat/`, `fix/`, `docs/`, `chore/` + `<scope>` + slug ngắn. VD `docs/mondelez-flash-daily-spec-v1.1`.

### Task E — File operation (Read/Write/Edit/Glob/Grep)

- Mọi `file_path` truyền cho Edit/Read/Write phải bắt đầu bằng `c:\smartlog_workspace\smartlog-control-tower\projects\`.
- Glob/Grep cũng phải pass `path: "c:\\smartlog_workspace\\smartlog-control-tower\\projects"` (không default workspace root).
- Sau khi edit, chạy `git -C <projects> status --short` để confirm file lên đúng tracking.

### Task F — Diff / inspect

```powershell
git -C "<projects>" diff                            # unstaged
git -C "<projects>" diff --cached                   # staged
git -C "<projects>" diff <ref1>..<ref2> -- <path>   # giữa 2 ref
git -C "<projects>" log --oneline --graph -20
git -C "<projects>" show <sha> --stat
```

### Task G — Sync da-* skills giữa workspace ↔ projects

Skill `da-*` được mirror 2 nơi: workspace (`<repo>/.claude/skills/da-*/` — Claude Code load chỗ này) và projects (`projects/.claude/skills/da-*/` — commit để share với team). Script đồng bộ ở `projects/scripts/sync-da-skills.ps1` với 3 mode:

| Mode | Hành động | Khi nào dùng |
|---|---|---|
| `check` | so sánh hash, exit 1 nếu drift | Verify trước commit; CI / pre-push hook |
| `push` | workspace → projects (strict mirror) | Sau khi user sửa skill local, muốn share |
| `pull` | projects → workspace (strict mirror) | Sau khi teammate push update lên helix_projects |

**Workflow chuẩn khi user yêu cầu "sync skills" / "push skill mới" / "pull skill từ team":**

1. **Luôn `check` trước** để biết hướng nào có drift:
   ```powershell
   & "c:\smartlog_workspace\smartlog-control-tower\projects\scripts\sync-da-skills.ps1" -Mode check
   ```
2. Đọc output drift để xác định hướng:
   - `+ workspace  <path>` → file chỉ có ở workspace → nếu user là người vừa sửa → `push`.
   - `+ projects  <path>` → file chỉ có ở projects → có thể teammate đẩy lên trước → `pull`.
   - `~ differs  <path>` → 2 bên khác nhau → hỏi user version nào canonical.
3. **Hỏi user xác nhận hướng** trước khi push/pull (cả 2 là strict mirror — xoá extras phía destination).
4. Chạy với `-DryRun` trước để preview, rồi `-Force` để skip prompt khi đã confirm:
   ```powershell
   & "<projects>\scripts\sync-da-skills.ps1" -Mode push -DryRun
   & "<projects>\scripts\sync-da-skills.ps1" -Mode push -Force
   ```
5. Re-check sau khi sync → expect "No drift".
6. Nếu push: tiếp tục flow Task A (commit) + Task B (push) trong repo `projects/`.
7. Nếu pull: nhắc user **restart Claude Code** để load skill mới (Claude Code chỉ scan skills lúc start).

**Anti-patterns thêm cho Task G:**

- ❌ Chạy `push` rồi `pull` liên tiếp mà không check — overwrite ngầm.
- ❌ Edit thẳng vào `projects/.claude/skills/da-*/` rồi commit — đó là mirror, không phải source. Edit ở workspace, sync push.
- ❌ Skip `check` khi user nói "push đi" — luôn show drift trước để user thấy đúng cái họ muốn.
- ❌ Chạy `-Force` không hỏi user — `-Force` chỉ dùng sau khi user đã confirm hướng và scope.
- ❌ Add file ngoài `da-*` vào skills/ rồi expect script sync — script ignore non-da skills theo design.

---

## Convention nội bộ `projects/`

Đã ghi trong memory (xem `[[feedback_data_artifact_path]]`, `[[feedback_triage_base_path]]`):

- Section root: `projects/<tenant>/<section>/<section>-prd.md` (KHÔNG bare `prd.md`).
- Analysis/pulse: `projects/<tenant>/<section>/analysis/`.
- Triage: `projects/<tenant>/triage/` (flat, 1 living folder per tenant).
- Da-ops releases: `projects/<tenant>/ops/_releases/` (md + html + pdf).

Khi tạo file mới, gợi ý đúng location theo convention thay vì để user tự đoán.

---

## Anti-patterns

| ❌ Không làm | ✅ Thay bằng |
|---|---|
| `git status` ở root để "xem chung" | Chỉ `git -C <projects> status`. Trạng thái main repo không thuộc skill này. |
| `cd projects; git ...` | `git -C "<projects>" ...` — không phụ thuộc shell state. |
| `git add .` cho nhanh | `git add <path-cụ-thể>` sau khi review `git status`. |
| `git commit -am "..."` (skip `git add` review) | Tách 2 bước, review staged trước commit. |
| `git push --force origin main` | Reject. Đề xuất fix branch khác hoặc revert+commit. |
| Edit file `frontend/...` hay `backend/...` khi đang trong `/da-projects` | STOP, báo user đây là main repo, chuyển skill khác. |
| Add `Co-Authored-By: Claude` vào commit | Reject — rule cứng. |
| Tạo file `xxx-v2.md` / `xxx-new.md` để "khỏi đè bản cũ" | Sửa thẳng file cũ hoặc đặt tên theo nghiệp vụ; không dùng version suffix. |
| Push xong rồi mới nói user | Confirm trước mỗi push. |
| Stash mà không note message | Luôn `stash push -m "<reason>"` để truy ngược được. |

---

## STOP Points

⏸ Remote không khớp `helix_projects.git` → STOP, cảnh báo user (có thể đã clone nhầm).
⏸ User yêu cầu sửa file ngoài `projects/` → STOP, hỏi lại scope.
⏸ Phát hiện secret/credential trong diff → STOP, không commit.
⏸ `git push` reject vì non-fast-forward → STOP, không force; pull/rebase rồi thử lại.
⏸ Conflict khi rebase/pull → STOP, để user resolve.
⏸ User yêu cầu `git reset --hard` / `git clean -fd` → confirm 2 lần (destructive).
⏸ User yêu cầu thao tác trên `.git/` directly (vd sửa config, edit refs) → từ chối trừ khi explicit hiểu rõ hậu quả.

---

## Khi nào KHÔNG dùng `/da-projects`

| Tình huống | Skill đúng |
|---|---|
| Sửa code BE (`backend/...`) | `/backend` |
| Sửa code FE (`frontend/...`) | `/frontend` |
| Audit code trước push (any repo) | `/da-ship` |
| Viết PRD docs/spec mới (nội dung) | `/ba` rồi commit qua `/da-projects` |
| Phân tích số liệu | `/da-data` hoặc `/da-ch` |
| Đọc/phân tích activity log vận hành | `/da-ops` |

`/da-projects` chỉ lo **mechanics của git + file boundary**, không lo nội dung.

---

## Mandatory Ending Signal

Sau mỗi tác vụ, in:

```
DA-PROJECTS ACTION
─────────────────────────────────
Repo           : projects/ (helix_projects)
Branch         : <branch>
Action         : status / add / commit / push / pull / branch / file-edit
Files affected : N (<short list>)
Result         : OK / BLOCKED / NEEDS USER ACTION
Next step      : <1 câu>
─────────────────────────────────
```

---

## Tinh thần

> Repo `projects/` là sandbox riêng — KHÔNG ảnh hưởng codebase chính, KHÔNG được leak vào commit chính. `da-` prefix của skill này (và mọi sibling `da-*`) là lớp bảo vệ thứ 2 sau `.gitignore`. Mọi nhầm lẫn boundary ở đây sẽ tạo commit rác vĩnh viễn trong history team. Tốt nhất: chậm hơn 5 giây để verify path, còn hơn revert 1 commit đã push.
