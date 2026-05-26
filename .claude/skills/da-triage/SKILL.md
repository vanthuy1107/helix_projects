---
name: da-triage
description: Dùng khi nhận một danh sách hỗn hợp bug + feedback + improvement + question từ khách hàng (file Excel/CSV/Markdown/issue export) và cần tổ chức, phân loại, dedupe, ưu tiên, rồi route từng item về đúng pipeline (bug → /qa-executor, drift → /da-trace, feature mới → /da-discovery, PRD update → /ba). Đứng TRƯỚC các skill specialist đó. Trigger trên "triage", "phân loại bug", "feedback list", "intake", "rà soát feedback", "tổ chức bug list", "khách báo nhiều thứ", "UAT feedback", "rollout feedback", "Excel khách gửi". KHÔNG dùng để fix bug đơn lẻ (/debugger) hay viết bug report formal (/qa-executor) — đó là bước SAU.
user-invocable: true
---

# Smartlog Control Tower — Customer Feedback Triage (local-only)

Skill này biến **một file feedback hỗn loạn** từ khách hàng thành **backlog có cấu trúc + handoff stubs** sẵn sàng đẩy vào pipeline. Đứng ở vị trí **intake/triage** — trước `/qa-executor`, `/da-trace`, `/da-discovery`, `/ba`.

## Khi nào dùng

- Khách gửi 1 file Excel với 50 dòng "lỗi/góp ý/đề xuất" lẫn nhau (vd `Edit UX_UI_MDLZ.xlsx` cho tenant Mondelez).
- Sau buổi UAT có biên bản tay/Notion với bug + feature request trộn lẫn.
- Export từ Jira/Linear/GitHub Issues cần phân loại theo Smartlog area trước khi xử lý.
- Slack channel CS dồn lại 1 list cuối tuần cần tổ chức.

## Khi nào KHÔNG dùng

- Đã có 1 bug duy nhất rõ ràng → `/qa-executor` (bug report) hoặc `/debugger` (fix)
- Cần deep-dive 1 vấn đề chưa rõ → `/da-discovery`
- Chỉ kiểm tra UI có khớp PRD không (không có feedback từ khách) → `/da-trace`
- Audit code quality → `/reviewer`

## Output — tenant-aware routing

**Quy tắc xác định base path** (apply theo thứ tự):

1. Nếu source file nằm trong `projects/<tenant>/...` → `BASE = projects/<tenant>/triage/<source-slug>-<YYYY-MM-DD>/`
2. Nếu user nêu rõ tenant (vd "khách MDLZ", "Mondelez") nhưng file ở chỗ khác → `BASE = projects/<tenant-slug>/triage/<source-slug>-<YYYY-MM-DD>/` (tạo folder tenant nếu chưa có)
3. Nếu không xác định tenant → `BASE = projects/triage/<source-slug>-<YYYY-MM-DD>/` (fallback)

Luôn ghi rõ `BASE` đã chọn ở đầu báo cáo + lý do (rule 1/2/3).

| Artifact | Path |
|---|---|
| Triaged backlog (bảng tổng) | `<BASE>/backlog.md` |
| Bug report stubs | `<BASE>/bugs/<id>.md` |
| Discovery brief stubs | `<BASE>/discoveries/<id>.md` |
| PRD revision asks | `<BASE>/prd-asks/<id>.md` |
| Trace audit asks | `<BASE>/trace-asks/<id>.md` |

Tất cả trong `projects/` (gitignored).

**Ví dụ với MDLZ**:
- Source: `projects/mondelez/Edit UX_UI_MDLZ.xlsx`
- BASE: `projects/mondelez/triage/edit-ux-ui-mdlz-2026-05-09/`
- Backlog: `projects/mondelez/triage/edit-ux-ui-mdlz-2026-05-09/backlog.md`
- Bug stub: `projects/mondelez/triage/edit-ux-ui-mdlz-2026-05-09/bugs/BUG-001.md`

→ Tất cả artifacts của khách MDLZ gom dưới `projects/mondelez/` để dễ tổng quan theo tenant.

## Quy trình tổng — 4 giai đoạn (framing PM/BA)

Skill này phải luôn cover đủ 4 giai đoạn cổ điển của triage. Mỗi giai đoạn map sang 1+ bước chi tiết bên dưới:

| Giai đoạn | Mục tiêu | Map sang bước chi tiết |
|---|---|---|
| **1. Tiếp nhận (Intake)** | Tập hợp tất cả lỗi/feedback mới từ tester/user, normalize về 1 schema chung | Bước 1 (Parse) + Bước 3 (Dedupe) |
| **2. Đánh giá (Severity)** | Phân loại mức nghiêm trọng: block / nghiệp vụ / annoyance / cosmetic | Bước 2 (Classify — Sev1–4) |
| **3. Ưu tiên (Priority)** | Xếp thứ tự fix theo rủi ro & tác động kinh doanh | Bước 4 (RICE-lite) |
| **4. Phân công (Assignment)** | Giao mỗi item cho **người cụ thể** (dev / QA / BA / CS) **và** đúng pipeline | Bước 5 (Route + Assign owner) |

**Bắt buộc**: Output cuối (`backlog.md`) phải có cả 4 trường — Sev, Priority score, Pipeline, **Assignee** — trên cùng 1 row. Thiếu Assignee = triage chưa xong.

## Quy trình bắt buộc — 6 bước

### Bước 1: Parse input → normalized rows

Tuỳ format:

| Format | Cách parse |
|---|---|
| **Excel `.xlsx`** | Thử lần lượt: (a) `python -c` với `pandas`/`openpyxl`, (b) PowerShell `Import-Excel` module, (c) `npx xlsx-cli`. Nếu không có tool nào → **yêu cầu user export sang CSV** trước khi tiếp tục — không đoán nội dung. |
| **CSV** | PowerShell `Import-Csv` hoặc Bash với standard tools |
| **Markdown / text** | Đọc trực tiếp, parse heuristic (mỗi `-` / `1.` / dòng mới = 1 item) |
| **Jira/Linear/GitHub export (JSON/CSV)** | Map field: title/description/reporter/url → row chuẩn |

**Row chuẩn** (luôn map về schema này):

```
| id (raw từ source hoặc T-NNN) | raw_text | reporter | screen/feature | attachment | source_row_ref |
```

Ghi rõ tổng số row đọc được + số row skip + lý do skip ở đầu báo cáo.

### Bước 2: Classify từng row

Cho mỗi row, gán 4 nhãn:

#### Type (chọn 1)
- **Bug** — hệ thống làm sai vs spec/expectation
- **UX issue** — không sai chức năng nhưng khó dùng / xấu / chậm cảm nhận
- **Feature request** — yêu cầu thêm capability mới
- **Question** — khách hỏi cách dùng (không phải bug)
- **Duplicate** — đã có item khác tương đương
- **Out-of-scope** — nằm ngoài Smartlog Control Tower
- **Need-more-info** — không đủ data để phân loại

#### Area (Smartlog module)
Tender / VFR / Transaction Move / Flash Daily / Dashboard / Auth / Multi-tenant / Notification / Master data / FormConfig / Other (specify).

Nếu không chắc area → cờ `?` và liệt kê 2-3 area khả nghi.

#### Tenant scope
Tenant cụ thể (vd MDLZ = Mondelez) hoặc `All`.

#### Severity (chỉ cho Type=Bug)
- **Sev1** — block business operation, không workaround
- **Sev2** — ảnh hưởng nghiệp vụ chính, có workaround tệ
- **Sev3** — annoyance hoặc edge case
- **Sev4** — cosmetic

#### Confidence
- **High** — chắc chắn classification đúng
- **Med** — có thể đúng, cần xác nhận với reporter
- **Low** — đoán, cần BA verify

### Bước 3: Deduplicate

Heuristic dedupe:
- Cùng area + cùng screen + cùng symptom → suspect duplicate
- Cùng reporter + cùng ngày + text gần giống → duplicate
- Confirm trước khi merge — nếu không chắc → đánh dấu `Possible dup of #X` chứ KHÔNG xoá

Master row giữ tất cả reporter/timestamp gộp lại để không mất evidence.

### Bước 4: Prioritize (RICE-lite)

Mỗi item (sau dedupe, không phải Question/Out-of-scope/Duplicate) gán:

| Trục | Thang |
|---|---|
| **Reach** — bao nhiêu user/tenant chạm? | 1 (chỉ reporter) / 3 (≥1 team) / 5 (cross-team) / 9 (cross-tenant) |
| **Impact** — nặng tới mức nào nếu không fix? | 1 cosmetic / 3 annoy / 5 ảnh hưởng nghiệp vụ / 9 block |
| **Effort** — cảm tính (BA estimate, không phải dev) | 1 (XS) / 3 (S) / 5 (M) / 9 (L) |
| **Score** | (Reach × Impact) / Effort — sort giảm dần |

Đây là estimation thô của BA để **xếp thứ tự**, không phải estimation kỹ thuật. Ghi caveat trong report.

### Bước 5: Route → handoff path + Phân công owner

Có 2 việc trong bước này — **route** (đến đúng pipeline/skill) và **assign** (đến đúng người). Cả hai đều phải có cho mỗi item.

#### 5a. Route theo type

| Type | Handoff | Stub sinh ra |
|---|---|---|
| Bug Sev1-2 | `/qa-executor` (formal bug report) hoặc `/debugger` (nếu cần fix ngay) | `bugs/<id>.md` — title, repro steps, expected, actual, env, severity, attachment |
| Bug Sev3-4 | `/qa-executor` để gom vào batch tiếp theo | `bugs/<id>.md` ngắn |
| UX issue | Check là **drift** (UI khác PRD) hay **PRD chưa cover**? Drift → `/da-trace`; PRD chưa cover → `/ba` revision | `trace-asks/<id>.md` hoặc `prd-asks/<id>.md` |
| Feature request | `/da-discovery` (5 câu hỏi office-hours trước khi commit) | `discoveries/<id>.md` — quote raw + 1-line problem hypothesis |
| Question | CS team trả lời + đóng. KHÔNG sinh stub, ghi note "Closed: routed to CS" | — |
| Duplicate | Đóng, link master | — |
| Out-of-scope | Đóng, ghi lý do, đề xuất nơi khác (vd partner tool) | — |
| Need-more-info | Gán owner đi hỏi reporter, ETA | — |

#### 5b. Phân công owner (Assignee)

Mỗi item active (không phải Closed/Duplicate/Out-of-scope) **bắt buộc** có 1 Assignee — tên người hoặc team chịu trách nhiệm bước tiếp theo.

Gợi ý chọn assignee theo `tech_layer` (đã có trong row sau classify):

| tech_layer | Assignee gợi ý | Lý do |
|---|---|---|
| `etl-data` | Data engineer / DA | Pipeline ETL, transformation logic |
| `backend-config` | Backend dev (FormConfig/QueryConfig owner) | JSON config, không cần build code |
| `backend-api` | Backend dev (theo module: Tender/VFR/...) | Cần edit C# code, EF, controller |
| `frontend-config` | Frontend dev (theo feature folder) | ViewConfig, FormConfig FE |
| `frontend-widget` | Frontend dev (Dashboard/Widget owner) | Widget React + Recharts |
| `cross-stack` | Tech lead (cần phối hợp) | Đụng cả BE + FE |
| (UX issue → drift) | BA hoặc UX owner | Cần re-spec PRD trước |
| (Feature request) | BA / Product owner | Cần discovery trước, chưa giao dev |
| (Question) | CS team | Trả lời khách, không cần dev |

**Quy tắc**:
- Nếu chưa biết tên cụ thể → gán **team** (vd `Backend team`, `FE-Tender squad`) + flag `Owner: TBD` để PM resolve sau
- KHÔNG để trống Assignee. "TBD + team" vẫn tốt hơn là blank.
- Với Sev1 + Priority cao: assignee phải là **người cụ thể**, không được dừng ở team
- Ghi assignee vào cả backlog table + stub file (trường `Assignee`)

### Bước 6: Output backlog + handoff list

Backlog tổng (1 file):

```markdown
# Triage Backlog — <Source> — <YYYY-MM-DD>

**Source file**: <path or URL>  
**Tenant**: <MDLZ / All>  
**Total rows in source**: <N>  
**Triaged**: <N> | **Skipped**: <M> (lý do)  
**Triaged by**: <name>

## Distribution
| Type | Count | % |
|---|---|---|
| Bug | | |
| UX issue | | |
| Feature request | | |
| Question | | |
| Duplicate | | |
| Out-of-scope | | |
| Need-more-info | | |

## Top priorities (Score ≥ X, sort desc)
| # | Source ID | Type | Area | Tenant | Sev | R | I | E | Score | Title (1 dòng) | Pipeline | Assignee | Stub |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | MDLZ-12 | Bug | Tender | MDLZ | Sev1 | 9 | 9 | 3 | 27 | "Award button enable cho status đã đóng" | `/qa-executor` → `/debugger` | Backend team / TBD | bugs/T-001.md |

## Full backlog
<bảng đầy đủ tất cả items, kèm Confidence, dedupe note>

## Handoff summary
| Skill kế tiếp | Số stub | Path |
|---|---|---|
| `/qa-executor` | <N> | `bugs/` |
| `/da-trace` | <N> | `trace-asks/` |
| `/ba` | <N> | `prd-asks/` |
| `/da-discovery` | <N> | `discoveries/` |
| (Closed) CS | <N> | — |

## Open questions
- <items Need-more-info + owner + deadline>
```

Stub mẫu cho bug:

```markdown
# BUG-<id>: <title>

- **Source**: row <N> of <file>
- **Reporter**: <name + role + tenant>
- **Date reported**: <YYYY-MM-DD>
- **Area**: <module>
- **Severity**: Sev<N>
- **Priority score**: <R × I / E>
- **Assignee**: <tên người HOẶC team + "TBD"> — gợi ý theo `tech_layer`
- **Repro steps** (best-effort từ raw text):
  1.
  2.
- **Expected**:
- **Actual**:
- **Attachment**: <path nếu có>
- **Raw quote**:
  > <exact text từ source>
- **Triage confidence**: High / Med / Low
- **Next**: handoff `/qa-executor`
```

Stub mẫu cho discovery:

```markdown
# DISC-<id>: <feature ask 1 dòng>

- **Source**: row <N> of <file>
- **Requested by**: <name + role + tenant>
- **Raw quote**:
  > <exact text>
- **Initial problem hypothesis** (BA paraphrase, KHÔNG phải solution):
- **Triage confidence**: High / Med / Low
- **Next**: handoff `/da-discovery` để chạy 5 câu hỏi office-hours trước khi commit
```

## Anti-patterns (tránh)

| Sai lầm | Sửa |
|---|---|
| Đoán nội dung Excel khi không có tool đọc | Yêu cầu user export sang CSV trước — KHÔNG fabric data |
| Classify "Bug" mọi thứ vì khách dùng từ "lỗi" | Khách hay gọi feature request là "lỗi". Đọc kỹ — nếu không có expected vs actual rõ → có thể là Feature/UX |
| Dedupe bằng cách xoá row | Đánh dấu `Possible dup of #X`, giữ row gốc, master row gộp evidence |
| Severity inflation (toàn Sev1) | Sev1 = block không workaround. Nếu khách than phiền nhưng vẫn dùng được → max Sev2 |
| Effort estimation như dev | BA estimate thô để priortize, không phải sprint estimate. Ghi caveat. |
| Sinh stub mà thiếu raw quote | Mất evidence — luôn copy nguyên văn raw text vào stub để dev/QA hiểu context khách |
| Bỏ qua attachment | Screenshot/video thường là evidence quan trọng nhất — luôn link path attachment |
| Triage 1 lần xong là đóng | Triage là living document — khi nhận thêm feedback cùng source, append + re-triage. Có version + ngày. |
| Confuse drift với feature gap | UX issue = drift nếu PRD đã spec đúng nhưng UI sai. = PRD gap nếu PRD chưa spec. Phân biệt trước khi route |

## Process tip — Excel parsing trên Windows

Thử theo thứ tự ưu tiên:

```powershell
# Option 1: PowerShell ImportExcel module
if (Get-Module -ListAvailable -Name ImportExcel) {
  Import-Excel "<path>.xlsx" | ConvertTo-Csv -NoTypeInformation > out.csv
}

# Option 2: Python pandas
python -c "import pandas as pd; pd.read_excel(r'<path>.xlsx').to_csv('out.csv', index=False)"

# Option 3: bảo user File > Save As > CSV
```

Một khi có CSV → workflow trên chạy bình thường.

## Mandatory ending signals

- `ARTIFACT_PATH`: backlog file
- `TOTAL_ITEMS`: số item triaged
- `DISTRIBUTION`: bảng count theo type
- `STUBS_GENERATED`: số stub theo handoff (vd `5 bugs / 3 discoveries / 2 prd-asks / 1 trace-ask`)
- `ASSIGNMENTS`: số item đã gán owner cụ thể vs còn `TBD` (vd `8 assigned / 4 TBD`) — TBD ≠ blank, blank là lỗi
- `OPEN_QUESTIONS`: số item Need-more-info chưa resolve
- `RECOMMENDED_NEXT_SKILL`: skill ưu tiên gọi tiếp (thường là `/qa-executor` cho top Sev1-2 bugs, sau đó `/da-discovery` cho top feature requests)
