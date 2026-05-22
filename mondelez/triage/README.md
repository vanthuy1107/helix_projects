# Triage workspace — Mondelez (MDLZ)

Folder triage cho mọi feedback của khách Mondelez. **Living document** — re-triage append vào folder này thay vì tạo folder mới mỗi đợt.

> **Convention chỉ áp dụng nội bộ — chưa thống nhất với khách MDLZ.** Nếu rollout production, đồng bộ convention prefix `[D]/[W]/[-]` với cột "Trạng thái" của khách.

## 3 quy ước bắt buộc khi sinh artifacts

### 1. Status prefix trong filename

Mỗi stub file PHẢI có prefix `[X]-` ở đầu filename:

| Prefix | Meaning | Map từ status raw trong file Excel MDLZ |
|---|---|---|
| `[D]` | **Done** — đã hoàn thành | `Đã fixed`, `Đã sửa = True` |
| `[W]` | **Work In Progress** — đang làm | `Đang fixing`, `Fix lại`, `In-dev`, `In-doing`, `In Progress`, `Pending`, `SLG đã nhận yêu cầu` |
| `[-]` | **Draft** — chưa pickup | `New`, hoặc blank |
| `[Q]` | **Question** — cần CS trả lời | type=Question |
| `[X]` | **Closed** — Dup/OOS/cancelled | `BỎ`, `trùng hả c`, type=Duplicate/Out-of-scope |
| `[U]` | **Unmappable** — cần BA review | Status text lạ, không khớp pattern (`?` không dùng được trên Windows filename → đổi thành `U`) |

**Why**: PM scan folder + biết status ngay không cần mở file. Khi khách gửi update, chỉ đổi prefix là biết item nào đã đóng — KHÔNG xoá file (giữ history).

**Format**: `[X]-{ID}-{area}-{slug-from-title}.md`
- VD: `[W]-BUG-001-vfr-bang-du-lieu-detail.md`
- VD: `[-]-FEAT-024-other-tinh-nang-config-thay-doi-ten-field.md`
- Platform stubs: `[X]-PLATFORM-{PATTERN}.md` — prefix = majority status của các item con

**Markdown links**: `[`/`]` là reserved char trong markdown, link target PHẢI URL-encode brackets:
- File path: `bugs/cross-stack/[W]-BUG-001-foo.md`
- Markdown link: `[bugs/cross-stack/[W]-BUG-001-foo.md](bugs/cross-stack/%5BW%5D-BUG-001-foo.md)`
- `%5B` = `[`, `%5D` = `]`

### 2. Folder nesting theo `tech_layer`

Per-item stubs nest 1 lớp con theo tech_layer (nơi fix sống):

```
bugs/                        # → /qa-executor
├── etl-data/                # SQL view / mv_test_* (DA team)
├── backend-config/          # JSON QueryConfig (DEV-BE quick edit)
├── backend-api/             # Controller / handler (DEV-BE code)
├── frontend-config/         # FormConfig / layout (DEV-FE quick)
├── frontend-widget/         # React component (DEV-FE code)
├── cross-stack/             # Multi-layer (multi-team)
└── unknown/                 # Cần BA/PM review
```

Tương tự cho `discoveries/` (→ /da-discovery) và `prd-asks/` (→ /ba).

**Platform stubs** (cross-cutting, áp dụng nhiều view) tách riêng:
```
_platform/
├── prd-asks/                # PLATFORM-* → /ba
└── discoveries/             # PLATFORM-* → /da-discovery
```

Underscore prefix (`_platform`) để folder lên đầu khi sort.

### 3. Priority field (Bug + Feature only)

Mỗi stub thuộc type **Bug** hoặc **Feature** PHẢI có dòng `**Priority**:` trong frontmatter — KHÔNG rename file, chỉ ghi vào nội dung.

| Priority | Definition |
|---|---|
| **Critical/Blocker** | Lỗi nghiêm trọng — ứng dụng không thể sử dụng (treo/sập/mất dữ liệu) |
| **Major** | Lỗi chức năng lớn — không có cách khắc phục tạm thời |
| **Minor** | Lỗi chức năng nhỏ — có thể khắc phục tạm thời |
| **Low/Cosmetic** | Lỗi giao diện / chính tả — ảnh hưởng nhỏ đến trải nghiệm |

**Heuristic auto-assign**:
- Bug Sev1 → Critical/Blocker
- Bug Sev2 (default cho filter sai value, data mismatch, layout sai) → Major
- Bug Sev3 (label/màu) → Minor or Low/Cosmetic
- Feature `cross-stack` (phân quyền, combine data, realtime, logic, bổ sung report) → Major
- Feature `frontend-widget`/`frontend-config` (sort, search, download, multi-select UI) → Minor
- Feature rename/icon/color → Low/Cosmetic

**Platform stubs** chứa Bug/Feature: dùng `Priority (rolled up, max of N items)` = priority cao nhất trong group. UX-only platform stubs ghi `N/A`.

**UX/Question/Duplicate/OOS**: KHÔNG có Priority field (theo yêu cầu — chỉ Bug + Feature).

**Override**: Nếu auto-assign sai context, BA edit thẳng vào file. Re-run skill sẽ overwrite — nên ghi note nếu muốn lock priority manual.

### 4. Multi-index navigation

PM có 4 cách navigate cùng dữ liệu:

| File | Use khi |
|---|---|
| [`backlog.md`](backlog.md) | Active items sort theo priority (RICE-lite) — biết "làm gì trước" |
| [`by-team.md`](by-team.md) | Backlog group theo `owner_team` — route việc cho team |
| [`_index/status-distribution.md`](_index/status-distribution.md) | Overview tất cả 250 items by status / tech_layer / folder |
| [`_index/done-index.md`](_index/done-index.md) / [`wip-index.md`](_index/wip-index.md) / [`unmapped-index.md`](_index/unmapped-index.md) | Per-status lookup — list 170 Done / 29 WIP / 13 Unmapped, link tới stub |
| Browse folder | Status prefix + slug → scan nhanh không mở file |

Backlog, by-team, indexes đều link tới full nested path với URL-encoded brackets.

## Files trong folder này

| File / folder | Purpose |
|---|---|
| `README.md` | This file — quy ước & navigation guide |
| [`backlog.md`](backlog.md) | Master backlog của 38 active items (Draft + WIP human-curated), priority-sorted |
| [`by-team.md`](by-team.md) | Backlog group theo owner_team |
| `_index/` | **Auto-gen** indexes (4 files) cho 212 items extracted từ `done-summary.md` — re-run `scripts/regen-indexes.py` khi đổi stub |
| `_archive/` | Snapshot file gốc của các đợt triage trước (vd `done-summary-2026-05-09.md`) |
| `_platform/` | Cross-cutting platform stubs |
| `bugs/{tech_layer}/` | Bug stubs → /qa-executor |
| `discoveries/{tech_layer}/` | Feature discovery stubs → /da-discovery |
| `prd-asks/{tech_layer}/` | UX/PRD revision stubs → /ba |
| `scripts/extract-done-summary.py` | **One-shot** — bóc `done-summary.md` thành 212 per-item stubs (đã chạy ngày 2026-05-09) |
| `scripts/regen-indexes.py` | **Idempotent** — scan stub filenames `[D|W|U]-DONE-*.md` rồi sinh lại `_index/*.md`. Chạy mỗi lần đổi prefix file hoặc move stub giữa folder. |

Total stubs: ~250 (38 human-curated + 212 extracted từ done-summary).

## Per-item stub schema (extracted from done-summary)

Mỗi stub `[D|W|U]-DONE-NNN-*.md` có:
- **Title**: 1 dòng item từ Excel row
- **Status / type / tech_layer**: prefix + heuristic
- **Module / Sheet + row ref**: trace ngược về source Excel
- **History table** (4 cột Date / Event / Actor / Ref): row #1 = MDLZ marked done; rows tiếp theo = PR / QA verify / UAT confirm — điền khi có thông tin
- **Logic section**: files changed / config code / behavior before-after — **TBD cho hầu hết Done items** (chỉ điền khi động đến code)
- **Raw quote**: nguyên văn từ Excel row
- **Re-verify checklist**: 4 mục — smoke test / regression / FormConfig verify / UAT confirm
- **Next action**: tùy status (D = re-verify; W = chase DEV team; U = BA clarify)

## Workflow: item `[W]` → `[D]`

1. Rename file: `[W]-DONE-NNN-*.md` → `[D]-DONE-NNN-*.md`
2. Append history row: `| YYYY-MM-DD | PR merged | <author> | <PR link> |`
3. Fill `Logic` section (files changed, config code, behavior delta)
4. Re-run `python scripts/regen-indexes.py` để cập nhật indexes
5. KHÔNG xóa file — keep history

## Re-triage policy

Folder này là **living document** — KHÔNG tạo sub-folder mới mỗi đợt feedback:

1. Khách MDLZ gửi update bổ sung → re-run skill `/da-triage` với cùng `BASE` path. Generator overwrite stubs + cập nhật prefix theo status mới.
2. Item từ `[W]` → `[D]`: chỉ đổi prefix filename + append history row, content giữ. Re-run `regen-indexes.py`.
3. Item mới: append vào backlog với ID kế tiếp.
4. Convention prefix: nếu khách MDLZ apply `[D]/[W]/[-]` directly trong cột "Trạng thái" của Excel sau này → giảm `[U]` (unmapped) về 0 → triage chính xác hơn.

## Extraction history

- **2026-05-09**: bóc tách 170 Done + 29 WIP + 13 Unmapped khỏi `done-summary.md` → 212 per-item stubs. Source file archived tại `_archive/done-summary-2026-05-09.md`. Script: `scripts/extract-done-summary.py`. Lý do: cần track logic + audit trail per-item (PR link, QA verify, UAT confirm) thay vì gom 1 file flat table.

## Source data

- File khách: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` (14 sheets, ~310 rows)
- Tenant: Mondelez (MDLZ)
- Last triage: 2026-05-09
- Triaged by: `/da-triage` skill
