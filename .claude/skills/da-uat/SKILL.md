---
name: da-uat
description: Dùng khi cần thiết kế và chạy User Acceptance Test với khách hàng cho 1 view/section của Smartlog Control Tower (dashboard OTIF, Flash Daily, VFR, late-alert, ...). Đứng ở góc PM/BA business-side — KHÔNG phải IT QA. Cover toàn lifecycle UAT theo 5 modes: A. Design (plan + cases + reconciliation template + tolerance), B. Pre-UAT prep (summary sức khỏe dữ liệu + quét anomaly + đối chiếu chéo nguồn upstream WMS/TMS + golden file + dry-run reconciliation trước session), C. Execute (record session với khách + defect log), D. Retest (sau khi dev fix, chỉ retest affected + regression panel), E. Signoff (pass criteria + release pack ngôn ngữ nghiệp vụ cho stakeholder khách). Trigger trên "UAT", "kịch bản UAT", "test với khách", "đối chiếu số liệu UAT", "golden file", "reconciliation matrix", "retest", "UAT signoff", "ký nghiệm thu", "tolerance UAT", "summary dữ liệu", "data health", "check dữ liệu bất thường", "anomaly", "đối chiếu chéo", "đối chiếu WMS", "đối chiếu TMS", "cross-check nguồn". KHÔNG dùng để: viết test plan dev QA (dùng /qa-planner), execute test case kỹ thuật (dùng /qa-executor), fix bug đơn lẻ phát sinh từ UAT (dùng /debugger), phân loại defect list lớn sau UAT thành backlog (dùng /da-triage), convert UAT bug → formal QA bug report cho dev squad (dùng /qa-executor intake mode), audit drift PRD vs implementation (dùng /da-trace).
user-invocable: true
---

# Smartlog Control Tower — Customer UAT Lifecycle (business-side)

Skill cho **PM/BA tự drive UAT với khách hàng** một view/section dashboard. Trả lời các câu hỏi kiểu:

- "Thiết kế kịch bản UAT cho view OTIF của Mondelez thế nào?"
- "Số trên dashboard vs Excel khách export bị lệch — tolerance bao nhiêu thì OK?"
- "Sau session UAT có 7 defect, retest thế nào để không phải chạy lại 18 TC?"
- "Pack signoff cho SC Manager khách ký — format gì, ngôn ngữ ra sao?"

KHÔNG phải `/qa-planner` — skill đó là IT QA persona, viết test case từ PRD AC cho dev squad chạy.
KHÔNG phải `/qa-executor` — skill đó execute test kỹ thuật + convert UAT bug đã được log thành formal QA bug report.
Skill này đứng **trước** `/da-triage`, `/qa-executor`, `/debugger` — tạo ra defect log mà các skill kia consume.

## 🛑 NGUỒN SỰ THẬT — HARD RULE (không thể vi phạm)

**Mọi số trong UAT reconciliation matrix PHẢI đến từ 3 nguồn thật, query/export tại thời điểm dry-run hoặc session:**

| Nguồn | Là gì | Lấy ở đâu |
|---|---|---|
| **Dashboard CT** | Số hiển thị trên widget tại session UAT | Screenshot + console value của widget |
| **SQL raw** | Số chạy SQL trực tiếp trên DB tenant (ClickHouse `analytics_workspace` cho Mondelez/Panasonic, hoặc Postgres `LogDbContext`/`AppDbContext` cho stack A) | Run query + paste result vào Appendix |
| **Golden file khách** | Export từ hệ thống cũ/Excel mà khách dùng làm chuẩn nghiệp vụ trước khi có Control Tower | File khách gửi, normalize cùng filter + cùng time window |
| **Nguồn upstream (cross-check)** | Hệ thống nghiệp vụ gốc mà dashboard MV dẫn xuất ra — **WMS/SWM** (`dim_orders`/`fact_order_fulfillment`/`fact_outbound`, 6 kho), **TMS report #25** (`mdlz_tms_report_25_trip_order`), **OTIF MV** (`mv_otif`). Dùng để chứng minh dashboard KHÔNG drift khỏi hệ gốc | Confusion matrix + set diff + per-day parity (Mode B.5, xem `references/data-audit-and-crosscheck.md`) |

| ❌ TUYỆT ĐỐI KHÔNG | ✅ BẮT BUỘC |
|---|---|
| So sánh chỉ 2 nguồn (Dashboard vs SQL) rồi kết luận "khớp = pass" | 3 nguồn — thiếu Golden file = block Mode B, không vào session |
| Đoán/ước lượng số khi golden file chưa có | STOP, yêu cầu khách export trước; chấp nhận lùi lịch UAT |
| Chốt tolerance threshold SAU khi đã thấy số lệch | Tolerance phải chốt trong Mode A (plan), trước Mode B |
| "Lệch 3% nhưng chắc do timezone" — không root-cause | Mọi diff vượt tolerance phải có root cause trong cột riêng của matrix |
| Mark TC=Pass vì số "gần đúng" | Pass khi diff ≤ tolerance VÀ root cause được khách accept; bằng không = Fail |
| Sinh số minh hoạ trong template rồi để rớt vào artifact | Placeholder `<chưa query>` / `<golden file pending>` rõ ràng |
| Reuse số từ session UAT trước cho session retest | Re-query mọi nguồn — data đã thay đổi sau khi dev fix |
| **Tự sinh câu SQL trong script UAT** dù registry đã có | **Load canonical từ `projects/{tenant}/02-data/data-sources/sql-registry.md`** — script dynamic-load section CH SQL block + substitute placeholder. Khi registry update, re-run script tự pick up. SQL ad-hoc CHỈ chấp nhận khi registry không có (note rõ "ad-hoc" trong SQL appendix) |
| Nhồi insight (red flag, master data quality, KPI extension đề xuất) **vào Excel UAT** | UAT Excel chỉ chứa **reconciliation data** (KPI, dim, trend, detail). Insight pack md là **file riêng** trong cùng folder, KHÔNG embed vào Excel — UAT pack giữ focus trên đối chiếu số |

**Tolerance threshold chuẩn** (chốt trong Mode A, override được nếu khách yêu cầu khắt khe hơn):

| Loại metric | Tolerance default |
|---|---|
| Số đếm tuyệt đối (đơn, volume) | ≤ 1% |
| % metric (OTIF%, OnTime%, InFull%) | ≤ 0.5 percentage point |
| Ranking top N (top 5 kho late) | ≥ 4/5 tên match, thứ tự có thể lệch |
| Tổng amount/cost | ≤ 0.5% |

Vượt tolerance VÀ chưa có root cause → defect Severity tối thiểu Major.

## Khi nào dùng

- Trước rollout 1 module/section cho 1 tenant (vd OTIF cho Mondelez, VFR late-alert cho Panasonic)
- Khách yêu cầu nghiệm thu chính thức trước khi sign HĐ rollout
- Sau release lớn (vd v1.5 đổi storytelling layout) cần xác nhận số liệu không drift
- Pre-rollout với key user trước khi mở cho toàn bộ tenant

## Khi nào KHÔNG dùng

- Dev QA muốn viết test plan từ PRD AC → `/qa-planner`
- Cần execute test case kỹ thuật trên môi trường dev → `/qa-executor`
- 1 bug duy nhất phát sinh, đã có repro → `/debugger`
- Khách gửi 1 Excel 50 dòng feedback hỗn loạn cần phân loại → `/da-triage`
- Convert UAT bug đã log → formal QA bug report cho dev squad → `/qa-executor` intake mode
- Audit drift PRD vs implementation (không có session khách) → `/da-trace`
- Retro sau khi UAT đã xong → `/da-retro`

## Output — tenant + section aware

**Base path** (đã chốt trong memory user):

```
projects/{tenant}/{section}/uat/
```

Ví dụ:
- `projects/mondelez/otif/uat/`
- `projects/mondelez/flash-daily/uat/`
- `projects/panasonic/vfr-late-alert/uat/`

Section root cùng cấp đã có `{section}-prd.md` / `{section}-spec.md` (per memory [[feedback_data_artifact_path]]). UAT là subfolder.

Artifacts theo 5 modes:

| Mode | Artifact | Path |
|---|---|---|
| A. Design | UAT plan | `{section}-uat-plan.md` |
| A. Design | Test cases | `{section}-uat-cases.md` |
| A. Design | Reconciliation template (empty) | `{section}-uat-reconciliation-template.md` |
| A. Design | **Excel pack với số SQL thật** (PM/khách dùng để đối chiếu — 7 sheet: README, KPI Hero, Health Matrix, Fail Reason, Trend, Detail Orders, Formula Guide, SQL Appendix) | `{section}-uat-numbers-{YYYY-MM-DD}_to_{YYYY-MM-DD}.xlsx` |
| A. Design | **Script Python re-runable** (đổi window → re-run) | `projects/{tenant}/scripts/uat_{section}_export.py` |
| A. Design (optional) | **Ops insight pack** (red flags, master data quality, KPI extension đề xuất, open questions cho session) — **file riêng KHÔNG nhồi vào Excel** | `{section}-uat-ops-insight-{YYYY-MM-DD}_to_{YYYY-MM-DD}.md` |
| B. Pre-UAT | **Data audit report** (summary health + 5 nhóm anomaly) | `{section}-uat-dataaudit-{YYYY-MM-DD}.md` |
| B. Pre-UAT | **Cross-system reconciliation** (dashboard MV ↔ WMS/TMS upstream) | `projects/{tenant}/02-data/audit-results/{a}-vs-{b}-{YYYY-MM-DD}.md` |
| B. Pre-UAT | Dry-run report (filled matrix với golden file thật) | `{section}-uat-dryrun-{YYYY-MM-DD}.md` |
| C. Execute | Execution log session với khách | `{section}-uat-execution-{YYYY-MM-DD}.md` |
| C. Execute | Defect stubs (1 file/defect) | `defects/UAT-{NNN}-{slug}.md` |
| D. Retest | Retest log (round N) | `{section}-uat-retest-{N}-{YYYY-MM-DD}.md` |
| E. Signoff | Signoff pack (audience khách) | `{section}-uat-signoff-{YYYY-MM-DD}.md` |

Tất cả trong `projects/` (gitignored). Commit qua `/da-projects`.

## Mode router — auto-detect

Skill này có 5 modes. Chọn mode theo trigger phrase + state file:

| User nói | State trong folder | → Mode |
|---|---|---|
| "thiết kế UAT", "kịch bản UAT cho X", "viết test case UAT" | Chưa có `{section}-uat-plan.md` | **A. Design** |
| "chuẩn bị UAT", "dry-run trước session", "đối chiếu golden file", "summary dữ liệu", "check dữ liệu bất thường", "quét anomaly", "đối chiếu chéo WMS/TMS", "cross-check nguồn" | Có plan, chưa có dry-run file | **B. Pre-UAT** |
| "ghi session UAT", "record kết quả UAT hôm nay", "log defect" | Có dry-run, ngày hôm nay = session | **C. Execute** |
| "retest UAT", "dev fix xong, kiểm tra lại", "round 2 UAT" | Có execution log + defect đã closed | **D. Retest** |
| "pack signoff", "ký nghiệm thu", "release UAT cho khách" | Pass rate đạt criteria | **E. Signoff** |

Nếu không rõ → hỏi user, KHÔNG đoán.

## Mode A — Design (trước UAT 1-2 tuần)

**Mục đích**: Thiết kế 4-lớp test, viết case bám storytelling layout của section, chốt tolerance + pass criteria + golden file requirement, route handoff trước.

### Bước A.1 — Đọc input

1. Đọc `{section}-prd.md` để hiểu acceptance criteria nghiệp vụ
2. Đọc `{section}-spec.md` để biết storytelling layout (L1 hero → L6 detail) và filter contract
3. Check memory tenant có target/RAG band gì chưa (vd Mondelez OTIF target 90%, Flash Daily target 95%)
4. Đọc registry/QueryConfig của section để biết data source (CH MV nào, app schema nào)

Nếu thiếu 1 trong 4 → STOP, hỏi user.

### Bước A.2 — Phân 4 lớp test

| Lớp | Mục đích | Tỷ lệ case |
|---|---|---|
| **A. Data Reconciliation** | Số dashboard có khớp golden file khách + SQL raw không | 30-40% |
| **B. Business Logic** | Định nghĩa metric, công thức, edge case có đúng nghiệp vụ tenant không | 30-35% |
| **C. UX & Storytelling** | Khách đọc được story L1→L6 không, ra quyết định gì | 20-25% |
| **D. Performance / Filter** | Filter combo, drill-down, response time | 10-15% |

Tách 4 lớp để khi fail biết fix ở đâu — KHÔNG trộn "số sai" với "UI khó dùng" trong cùng 1 ticket.

### Bước A.3 — Viết test case bám storytelling

Mỗi level/layer của storytelling layout = 2-4 test case (1 happy + 1-2 edge):

Ví dụ cho view OTIF (Mondelez):
- **L1 Hero** (1-2 TC, lớp A+B): % OTIF hôm nay vs target 90%, RAG color band đúng
- **L2 Exception banner** (1-2 TC, lớp B+C): khi <85% banner Red phải xuất hiện
- **L3 Funnel** (2-3 TC, lớp A+B): OTIF count dùng `otif_status = 'OTIF'` (cột pre-computed trong MV), KHÔNG dùng intersection `ontime_status = 'Ontime' AND infull_status = 'Infull'` — hai logic khác nhau do rounding (infull_status dùng `round(...,4)`, otif_status dùng raw decimal). Cross-check: tổng các bucket funnel = tổng đơn, không lệch >0.5%
- **L4 Trend 14d** (2 TC, lớp A+B): filter-independent, target line đúng 90%
- **L5 Dimension panels** (3-4 TC, lớp A+C): kho/khu vực/customer/channel drill-down
- **L6 Detail tables** (2-3 TC, lớp A+D): top N late/short, click qua Order Monitor

Tổng: 12-18 happy + 4-6 edge (timezone UTC cutoff, đơn không POD, filter ALL vs riêng).

Format mỗi case (1 row trong `{section}-uat-cases.md`):

```
TC-ID | Layer | Lớp (A/B/C/D) | Tiền điều kiện (filter) | Steps | Expected | Actual | P/F | Severity | Note
```

### Bước A.4 — Reconciliation matrix template

Sinh `{section}-uat-reconciliation-template.md` với:
- Hàng = mỗi metric cần đối chiếu (tổng đơn, %, top N kho, top N customer ...)
- Cột = `Filter` | `Dashboard` | `SQL raw (source DB)` | `Golden file khách` | `Diff Dashboard-Golden` | `Tolerance OK?` | `Root cause nếu lệch`

Chỉ định **rõ filter + time window** cho mỗi metric — đây là điểm dễ lệch nhất giữa 3 nguồn.

### Bước A.5 — Chốt pass criteria

Trong `{section}-uat-plan.md` ghi rõ:

| Tiêu chí | Default | Override? |
|---|---|---|
| Pass rate happy path | ≥ 95% | Khách có thể siết lên 100% |
| Pass rate edge case | ≥ 80% | |
| Defect Critical open | 0 | Block signoff tuyệt đối |
| Defect Major open | ≤ 2 với mitigation plan | Khách có thể yêu cầu = 0 |
| Reconciliation row pass | 100% trong tolerance | |
| Performance | Filter response < 3s, page load < 5s | |

### Bước A.6 — Route handoff trước

Trong plan, ghi rõ "khi UAT có defect tại lớp X thì route về ai":

| Defect lớp | Handoff |
|---|---|
| Lớp A (số lệch + root cause là SQL/MV) | `/da-ch` audit + dev squad CH owner |
| Lớp A (số lệch + root cause là filter/widget logic) | `/da-triage` → `/qa-executor` → dev FE |
| Lớp B (logic sai vs nghiệp vụ) | `/ba` revision PRD trước, sau đó dev fix |
| Lớp C (UX khó dùng nhưng đúng spec) | `/da-trace` xác nhận drift PRD vs implementation |
| Lớp D (perf chậm) | Dev squad theo module |

→ User dùng skill này không cần nhớ route — đã có sẵn trong plan.

### Bước A.7 — Sinh Excel pack với số SQL thật (PM/khách đối chiếu)

Sau khi plan + cases + reconciliation template xong, sinh artifact mới: **Excel pack chứa số chạy SQL thật từ DB tenant**. PM mang đi gặp khách để cùng review trước session UAT chính thức.

**Cấu trúc Excel pack chuẩn** (8 sheet):

| # | Sheet | Nội dung |
|---|---|---|
| 00 | README | Window, filter mặc định, source MV, tolerance, RAG band, hướng dẫn customer, sheet map |
| 01 | KPI Hero | KPI cards — cột **SQL value (frozen)** + cột **Công thức Excel (live)** + cột Dashboard/Golden để khách điền + Diff/Tolerance/Status |
| 02 | Health Matrix (5 dim) | NVC / **Kho code** (`whseid`) / Loại hàng / Kênh / Khu vực — worst-first %OTIF, color RAG, mỗi cell là COUNTIFS live formula reference sheet 05. **Chú ý**: dùng cột Kho code (B) trong Detail Orders, KHÔNG dùng Kho group (C) — COUNTIF phải match đúng cột chứa giá trị dimension label |
| 03 | Fail Reason | Bucket theo `not_ontime_reason` / `not_infull_reason` raw column từ MV. SQL value + Excel formula live (**COUNTIFS** trên Detail — bắt buộc 2 điều kiện: (1) reason column match bucket label VÀ (2) status column match trạng thái failed tương ứng, vd `ontime_status = 'Failed Ontime'` cho Fail Ontime breakdown, `infull_status = 'Failed Infull'` cho Fail Infull breakdown. KHÔNG dùng COUNTIF 1 điều kiện — sẽ đếm thừa row có reason text nhưng status không phải failed) |
| 04 | Trend daily | 1 row/ngày × tổng đơn + 3 % metric. COUNTIFS theo prefix ngày trên col J Detail |
| 05 | Detail Orders | Raw — 1 row = 1 SO + 21 cột (filter dim + status + reason + 2 cột khách verify: "Khớp golden? Y/N" + "Khách ghi chú"). Autofilter + freeze pane. **Là nguồn cho mọi formula sheet 01-04** |
| 06 | Formula Guide | Mapping cột Detail (A=SO, B=Kho code, ...) + 16 pattern công thức copy paste + 4 warning (range fragility, STM exclusion, sheet rename, recalc F9) |
| 07 | **UX & Filter checklist** | **30-40 mục checklist cho khách verify visual/filter/interaction/storytelling/master data — KHÔNG compute từ data, khách fill trong session.** 5 category: UX Visual, Filter, Interaction, Storytelling (mental model Q1→Q5), Master Data display. Mỗi mục có: Quan sát thế nào + Expected + Verdict cell (khách fill) + Severity nếu Fail + Reference PRD/AC + Ghi chú. |
| 08 | SQL Appendix | Mỗi query: ID + label + **source/provenance (registry line ref OR "ad-hoc")** + SQL đã substitute placeholder. Sources highlight **xanh = registry**, **vàng = ad-hoc** |

**Pattern dual SQL+formula** (KHÔNG bỏ 1 trong 2):
- **SQL value (frozen)**: Python ghi tại run-time, là số dashboard sẽ show
- **Excel formula (live)**: tính từ sheet 05 khi mở Excel
- Hai phải khớp. Diff → có gap filter ở 1 trong 2 → finding.

**Convention format chuẩn — consistent across mọi sheet** (bắt buộc):

| Loại value | Storage type | Number format | Display ví dụ |
|---|---|---|---|
| Datetime (ETA, ATA, ngày, ...) | Python `datetime` (**UTC, không convert timezone** — giữ nguyên giá trị UTC từ ClickHouse `DateTime64(3, 'UTC')` để khớp dashboard) | `yyyy-mm-dd hh:mm:ss` | `2026-05-18 12:30:00` |
| % metric (OTIF, Ontime, Infull, share, ...) | float / Decimal scale=2 | `0.00"%"` hoặc `0.00%` | `93.30%`, `82.94%` |
| Count (Tổng đơn, Ontime count, fail count, ...) | int | `#,##0` | `2,984` |
| Số lượng có decimal (CSE, volume, tiền, ...) | Decimal scale=2 (hoặc float) | `#,##0.00` | `110.00`, `1,326.50` |
| Date-only (Ngày trên Trend) | Python `date` | `yyyy-mm-dd` | `2026-05-18` |

**Quy tắc consistent rounding**:
- Cùng 1 logical metric type → cùng số decimal places. KHÔNG mix 1 cell hiện 93.3% và cell khác 92.43%.
- Apply qua **number_format** ở Excel cell — luôn `0.00"%"` cho %, luôn `#,##0.00` cho số có thập phân, luôn `#,##0` cho count.
- Note Excel float quirk: `round(93.30, 2)` trong Python = `93.3` (lost trailing zero). Raw value lưu trong file là 93.3, NHƯNG **display via number_format = "93.30%"** vẫn consistent. Không bug.
- Helper: `_pct2(v)` normalize → `Decimal('XX.XX')`, `_num2(v)` cho CSE. Mặc dù openpyxl convert lại float khi write, semantic là 2-decimal.

**Quy tắc datetime**:
- KHÔNG dùng `toString(toDateTime(...))` trong CH SQL → Python nhận text → Excel cell = text → không sort/filter range được.
- KHÔNG convert timezone `toDateTime(col, 'Asia/Ho_Chi_Minh')` → sẽ lệch ngày so với dashboard (dashboard dùng UTC raw). MV lưu `DateTime64(3, 'UTC')` — giữ nguyên UTC.
- Đúng: `SELECT col` (raw UTC) → Python nhận `datetime` → openpyxl ghi datetime serial → Excel cell = datetime. Không cần strip tzinfo vì ClickHouse driver trả naive datetime khi không convert timezone.
- Trend / time-bucket formulas: dùng `COUNTIFS(range, ">="&DATE(y,m,d), range, "<"&DATE(y,m,d)+1)` thay vì prefix text match `"yyyy-mm-dd*"`. Robust với datetime cell.
- **Lưu ý**: dashboard `CAST(selected_date, 'Date')` cắt ngày theo UTC. Excel Trend phải group theo UTC date tương ứng để reconciliation khớp.

### Bước A.8 — UX & Filter checklist sheet (cross-cutting cho lớp C + D)

Sheet `07 — UX & Filter checklist` trong Excel pack — **30-40 mục** chia 5 category, khách fill trong session UAT:

| Category | Số mục đề xuất | Focus |
|---|---|---|
| **UX Visual** | ~8 | RAG color visible trên HiDPI, KPI 4 phần tử đủ, Health Matrix per-metric band, Trend target band, action title nói insight, Tier 1 1-fold check, Tier 3 expanded-default, KPI sticky |
| **Filter** | ~10 | Dropdown đầy đủ option (Kho/NVC/Loại hàng/Loại ngày), validation (date range > 2 năm reject), default state, persistence (localStorage), multi-select AND, combo 5-dim perf, Reset button |
| **Interaction** | ~7 | Click Health Matrix → smooth-scroll + auto-expand, drill DO Order Monitor, Export PNG/CSV, Trend bucket toggle no-API, hover tooltip, Operation Summary pivot, Detail sort |
| **Storytelling** | ~6 | Mental model Q1→Q5 timing (≤2s / ≤10s / ≤20s / ≤30s), Exception Spotlight đúng "chiều kéo OTIF xuống" |
| **Master Data** | ~5 | NVC tên VN có dấu, Customer name không truncate, NVC empty hiển thị '(rỗng)', number/percent format VN/EN |

**Schema mỗi row**:
```
# | Category | Mục cần kiểm tra | Expected behavior | Verdict (khách fill) | Severity nếu Fail | Reference PRD/AC | Customer ghi chú
```

**Bắt buộc**:
- Category cell có background color phân biệt (xanh dương / vàng / indigo / hồng / xanh lá).
- Verdict cell + Customer ghi chú cell — yellow fill (signal "khách fill").
- Severity cell — color theo Critical (đỏ) / Major (vàng) / Minor (xanh) / Cosmetic (xám).
- Reference cell trỏ về PRD AC hoặc `§13.x` để khách trace ngược.
- Freeze pane top-left.

**Lưu ý**: Sheet này tập trung **lớp C (UX & Storytelling) + lớp D (Filter behavior + Perf)** — bổ sung cho sheet 01-05 chỉ kiểm **lớp A (Data) + B (Logic)**. UAT session sẽ chạy data reconciliation trước (sheet 01-05), sau đó cho khách fill checklist sheet 07.

### Bước A.9 — SQL provenance — load từ registry, KHÔNG tự sinh

**HARD RULE** (per skill `🛑 NGUỒN SỰ THẬT`):
- Mọi SQL trong Excel pack mà có canonical trong `projects/{tenant}/02-data/data-sources/sql-registry.md` → **dynamic-load tại runtime** (script đọc registry md, tìm section `### <tên>`, extract block ` ```sql ... ``` ` dưới `**ClickHouse SQL:**`).
- Substitute placeholders:
  - `{{whseid}}`, `{{group_of_cargo}}`, `{{transporter}}`, `{{area}}` → query `mv_filter_*` MV → format thành quoted CSV list (bypass-detect IF check trong registry SQL tự kích hoạt → 1=1 khi ALL filter)
  - `{{date_type}}` → `'ETA gửi thầu (đơn)'` (hoặc value user chọn — chú ý label exact phải match CASE branch trong SQL)
  - `{{from_date}}` / `{{to_date}}` → date literals. **Cả hai đều INCLUSIVE** vì registry SQL dùng `toDate(...) BETWEEN toDate(from) AND toDate(to)`. `to_date` là ngày cuối cùng CÓ trong kết quả, KHÔNG phải ngày đầu tiên bị loại. Ví dụ: window 18→22 May thì `from_date='2026-05-18'`, `to_date='2026-05-22'`. KHÔNG dùng convention exclusive-end của Python `range()` / `timedelta` (sẽ ra `to_date='2026-05-23'` → lấy thừa 1 ngày).
  - `[[ ... ]]` brackets → strip (keep clause content)
- Khi registry update, re-run script tự pick up — KHÔNG cần sửa code.
- Section không có trong registry (vd `chartByCategory`/Loại hàng, `detailTable`, FE-side classifier) → ad-hoc nhưng **note rõ "ad-hoc"** trong SQL appendix sheet 07.

**KHÔNG tự sinh SQL** khi registry đã có. Anti-pattern khi script tự sinh:
- Hand-rolled `count()` thay vì registry `uniqExact(so)` → đếm row vs đếm unique order → lệch 0.1-1%
- Filter `BETWEEN datetime UTC` thay vì registry `toDate(...) BETWEEN toDate(...) AND toDate(...)` → khác behavior với row biên
- Bỏ filter exclusion `ontime_status != 'Không có dữ liệu STM'` → tính số sai vs dashboard
- Hand-rolled bucket logic cho fail reason thay vì registry `GROUP BY not_ontime_reason` → bucket khác

### Bước A.10 — Sinh Ops Insight Pack md (file riêng, KHÔNG nhồi Excel)

(Optional — chỉ làm khi PM/BA muốn cung cấp góc nhìn vận hành ngoài reconciliation thuần.)

File: `{section}-uat-ops-insight-{YYYY-MM-DD}_to_{YYYY-MM-DD}.md` trong cùng folder UAT.

Mục đích: **giả định reconciliation pass 100%**, câu chuyện vận hành đứng sau số nói gì? Cung cấp:
1. 1-line headline + verdict
2. Master Data Quality scorecard (8 trục: whseid coverage, ETA/ATA completeness, STM coverage, cargo type, channel, NVC name fill rate, customer encoding, ...)
3. 6 Operational Red Flags với schema: Title + Severity + Layer + Quan sát + So sánh + Giả thuyết + Đề xuất + Route handoff + Source Q
4. 9 KPI extension đề xuất cho roadmap (per-cargo target, lateness histogram, NVC concentration, daily variance, ...)
5. 7 Open Questions mang vào session với customer
6. Appendix với Q-INS-* SQL evidence (ad-hoc query, NOT registry)

**Quy tắc**:
- Insight KHÔNG được nhồi vào Excel — file riêng. Excel = reconciliation pure. Md = insight commentary.
- Lý do: UAT pack tập trung "số đối chiếu" — overload insight vào Excel làm khách bị quá tải thông tin và confuse "đây là test data hay analysis?". Md riêng = audience PM/BA, share Slack/email kèm Excel.
- Insight md có thể dùng ad-hoc Q-INS-* SQL (không phải registry) vì đây là phân tích bổ sung, không phải dashboard verification.

### Bước A.11 — Chốt scope data-audit + cross-system check

Section nào cũng phải chốt **trước** (trong plan) 3 thứ, để Mode B chạy có chủ đích chứ không quét mò:

1. **Anomaly group nào áp dụng** (5 nhóm — xem `references/data-audit-and-crosscheck.md` §3): NULL/empty critical, volume integrity, business-rule cross-field, key uniqueness + cross-MV parity, timestamp ordering. Liệt kê field/cột cụ thể của section sẽ check + ngưỡng coi là defect (vd "volume âm = 0 dòng; NULL whseid ≤ 0.1%").
2. **Cross-source pair nào** cần đối chiếu chéo upstream + theo cấp grain nào:
   - OTIF / shipping → dashboard MV (`mv_otif`) ↔ **TMS report #25** (on-time thực tế giao) — cấp đơn `OrderCode`/`so`.
   - In-full / fulfillment / picking → dashboard ↔ **WMS/SWM** (`fact_order_fulfillment`) — cấp đơn/dòng.
   - Flash Daily → `mv_flash_and_drop_report` ↔ parity với `mv_flash_report` + `mv_dropped_report`.
3. **Quy ước timezone cho từng đối chiếu** (dashboard reconciliation = UTC theo MV; cross-check upstream nghiệp vụ = ngày VN) — ghi rõ pair nào dùng quy ước nào để Mode B không tự suy diễn.

Ghi vào `{section}-uat-plan.md` mục "Data audit scope". Tooling canonical = 2 notebook (`flash_daily_mtd_audit.ipynb`, `tms_report_25_explore.ipynb`) — KHÔNG tự viết lại SQL, clone cell + đổi `PARAMS`.

## Mode B — Pre-UAT prep (sát ngày, T-2 → T-1)

**Mục đích**: Chạy reconciliation matrix với golden file thật **trước khi gặp khách**. Nếu phát hiện lệch ngoài tolerance ở giai đoạn này — fix hoặc lùi lịch UAT, KHÔNG vào session với số sai.

**Thứ tự bắt buộc**: B.0 (summary sức khỏe dữ liệu) → B.0b (quét anomaly) → B.5 (đối chiếu chéo upstream WMS/TMS) → B.1-B.4 (reconciliation 3 nguồn). Không reconcile Dashboard vs Golden khi data nền chưa sạch hoặc đã lệch lớn với hệ gốc — sẽ đối chiếu trên rác. Chi tiết SQL/method: `references/data-audit-and-crosscheck.md`.

### Bước B.0 — Summary sức khỏe dữ liệu

Chạy snapshot "data có đủ + tươi + phân bố hợp lý + tổng volume đúng độ lớn?" trên nguồn của section (clone cell summary của notebook canonical, đổi `PARAMS` window/filter):

- **Scale**: row count, distinct order/key, dòng chưa gắn chuyến (`MasterCode=''`).
- **Window + Freshness**: min/max ngày có data; `dateDiff('minute', max(ts), now())` — lag vượt kỳ vọng refresh (vd `mv_otif` 5′) → STOP, đợi/force refresh, KHÔNG reconcile trên data cũ.
- **Distribution**: phân bố theo `e2e_label`/status/whseid/kênh/khu vực + %; bucket `(NULL)`/`(rỗng)` cao bất thường = red flag master data.
- **Volume totals**: tổng Plan/Shipped/Delivered (CSE/Ton/CBM) — lệch một bậc độ lớn so kỳ vọng khách = sai filter/window, không phải logic.
- **Column coverage**: % non-null các cột thời gian/số → biết cột nào đủ tin để dùng trong reconciliation.

Output → header của `{section}-uat-dataaudit-{date}.md`.

### Bước B.0b — Quét dữ liệu bất thường (5 nhóm anomaly)

Chạy 5 nhóm (xem `references/data-audit-and-crosscheck.md` §3), chỉ trên field đã chốt ở A.11:

1. NULL/empty critical · 2. Volume integrity (âm, over-ship, over-deliver, monotonicity Plan≥Shipped≥Delivered) · 3. Business-rule cross-field (status↔label↔fact mâu thuẫn, date phi lý) · 4. Key uniqueness + cross-MV parity (`rows_combined == rows_flash + rows_dropped`) · 5. Timestamp ordering (7 ràng buộc thời gian tăng dần).

Với mỗi nhóm có vi phạm > ngưỡng: drill listout (LIMIT 100, sort theo độ nặng) → **defect stub** (format Mode C.3) hoặc dòng "Accepted + root cause". KHÔNG để rớt im lặng. Route: integrity/parity sai → `/da-ch`; định nghĩa nghiệp vụ lệch → `/ba`.

### Bước B.1 — Yêu cầu golden file

Gửi khách spec golden file:
- Format: CSV/Excel, có header rõ
- Filter: cùng filter sẽ dùng trong UAT (NPP, kho, time window, cargo)
- Time window: chính xác giờ **UTC** (để khớp dashboard — MV lưu `DateTime64(3, 'UTC')`, dashboard cắt ngày theo UTC). Nếu khách cung cấp golden file theo UTC+7, phải note rõ và align khi so sánh
- Định nghĩa metric: yêu cầu khách document công thức (vd "OTIF của khách = ?")

Nếu khách chưa có cách export sạch → **block UAT**. Trong khi chờ: chuyển UAT lớp B (Business Logic) lên trước, dùng SQL raw làm chuẩn tạm.

### Bước B.2 — Run reconciliation matrix

Với mỗi row trong template:
1. Chạy SQL raw trên DB tenant → copy số vào cột SQL raw
2. Chụp screenshot dashboard với filter tương ứng → copy số vào cột Dashboard
3. Đọc giá trị từ golden file khách → copy vào cột Golden
4. Tính diff, check tolerance, identify root cause nếu lệch

### Bước B.3 — Diff resolution trước session

Mọi row out-of-tolerance phải có 1 trong 3 trạng thái trước session:

| Trạng thái | Action |
|---|---|
| **Resolved** | Đã fix, re-run matrix khớp |
| **Accepted** | Khách đã accept diff (vd timezone, cutoff) — ghi rõ accept trong note |
| **Deferred** | Convert thành defect stub, mở trước session, báo khách "row này sẽ check riêng" |

**KHÔNG được**: vào session với row chưa resolved/accepted/deferred.

### Bước B.4 — Output `{section}-uat-dryrun-{date}.md`

Format: copy reconciliation template + fill số thật + summary header "X/Y row pass, Z deferred, ready/not-ready for session".

### Bước B.5 — Đối chiếu chéo với nguồn upstream (WMS / TMS)

Cho cặp đã chốt ở A.11, chứng minh dashboard MV **không drift khỏi hệ nghiệp vụ gốc**. Dùng section L6 của `tms_report_25_explore.ipynb` làm khuôn (xem `references/data-audit-and-crosscheck.md` §4) — 4 kỹ thuật theo thứ tự:

1. **Count + set membership theo ngày** (FULL OUTER JOIN trên `code, ngay`): `trung` / `chi_A` / `chi_B`. `chi_*` lớn = lệch **tập đơn**, xử lý trước khi so trạng thái.
2. **Confusion matrix trạng thái** (INNER JOIN giao nhau, pivot `label_A × label_B`): đường chéo = đồng thuận; off-diagonal → list top 30 đơn lệch sort theo độ nặng (`abs(tre_phut)` / `abs(kh-giao)`).
3. **Set diff hai chiều + bucket nguyên nhân**: đơn chỉ-A / chỉ-B `GROUP BY status` → phân loại lý do (chưa lên chuyến / `status='Chờ'` / lệch tz-window / service khác). Biến "lệch" thành "lệch vì lý do đã hiểu".
4. **Grain alignment BẮT BUỘC**: rollup cùng cấp đơn (TMS `GROUP BY OrderCode`, `kh=max(QuantityOrder)` chống double-count, `gn=sum(QuantityBBGN)`; MV `GROUP BY so`; Failed nếu **bất kỳ** dòng con Failed); timezone (quy cả 2 về ngày VN cho cross-check upstream); service scope (`mv_otif` chỉ `'Xuất bán'`); on-time grace 30′ (`[D]-RULE-OTIF-001`).

**Gotcha**: chuỗi tiếng Việt phải bind `{svc:String}` — KHÔNG inline (clickhouse-connect corrupt UTF-8 → 0 row sai).

Output → `projects/{tenant}/02-data/audit-results/{a}-vs-{b}-{date}.md`. Diff cross-system vượt tolerance VÀ không giải thích được bằng bucket nguyên nhân → defect (Severity ≥ Major) hoặc block reconciliation 3 nguồn cho đến khi root-cause.

## Mode C — Execute (trong session với khách)

**Mục đích**: Drive session, record actual cho mỗi TC, log defect tại chỗ với evidence đủ để dev reproduce.

### Bước C.1 — Pre-session checklist (5 phút trước)

- [ ] Dry-run report status = ready
- [ ] All filters reset về default
- [ ] Browser dev tools tắt (đừng để khách thấy console)
- [ ] Screenshot tool sẵn sàng
- [ ] Execution log file đã mở
- [ ] Defect stub template sẵn

### Bước C.2 — Run TC theo thứ tự lớp

Thứ tự: **A → B → C → D**. Lý do: nếu lớp A (data) đã fail, lớp B (logic) không có ý nghĩa thảo luận. Stop và regroup.

Với mỗi TC:
1. Đọc Steps cho khách hiểu
2. Khách (hoặc PM/BA) thao tác
3. Đọc Expected
4. Quan sát Actual
5. Khách + PM/BA cùng kết luận P/F
6. Nếu Fail → tạo defect stub ngay, không để cuối session

### Bước C.3 — Defect stub format

1 file/defect tại `defects/UAT-{NNN}-{slug}.md`:

```
UAT-001 — OTIF % hôm nay lệch 1.2pp giữa dashboard và golden file

Severity: Major | tech_layer: cross-stack | Priority: P1
Reporter: <tên SC Manager khách>
Discovered in: Mode C session 2026-05-26 14:30

## Repro
1. Filter NPP=ALL, kho=ALL, date=2026-05-26
2. Vào view OTIF
3. Đọc % hero L1

## Expected (golden file khách)
87.0%

## Actual (dashboard)
88.2%

## Diff
+1.2pp (golden 87.0 vs dashboard 88.2)
Tolerance: ±0.5pp → OUT-OF-TOLERANCE

## Evidence
- Screenshot: defects/img/UAT-001-screenshot.png
- SQL: <Appendix SQL Q?-001>
- Golden file row: order count 12,450 / on-time 11,000 / in-full 10,830

## Hypothesis
Khác cutoff timezone — golden file khách tính theo UTC+7, dashboard cắt ngày theo UTC (MV lưu `DateTime64(3, 'UTC')`). Đơn 17:00-23:59 UTC rơi sang ngày khác khi nhìn từ UTC+7.

## Route
→ /da-ch audit timezone trong MV; → /qa-executor formal bug report cho dev FE
```

**Bắt buộc** mỗi defect phải có: severity + tech_layer + priority + evidence (screenshot OR sql ref) + hypothesis (không bỏ trống). tech_layer dùng convention từ memory [[feedback_triage_2dim_layer]].

### Bước C.4 — Defer rule

Nếu session ngắn không chạy hết — defer TC chưa chạy sang round retest, KHÔNG mark Skipped. Ghi rõ lý do defer (hết giờ / blocker từ TC trước).

### Bước C.5 — Closing session

Cuối session, đọc lại với khách:
- Tổng TC chạy / pass / fail / defer
- Defect open theo severity
- Next step: dev fix → retest round 1 vào ngày Y
- KHÔNG ký gì ở session này — signoff chỉ ở Mode E.

## Mode D — Retest (sau khi dev fix)

**Mục đích**: Chỉ retest TC bị ảnh hưởng + regression panel nhỏ. KHÔNG full re-run.

### Bước D.1 — Xác định scope retest

| Item | Retest? |
|---|---|
| TC đã Fail trong round trước, defect đã closed | **Bắt buộc** |
| TC ở cùng layer/section với defect đã fix | **Bắt buộc** (regression panel) |
| TC ở section khác, không liên quan defect | KHÔNG retest |
| Reconciliation matrix | Re-run **toàn bộ** matrix — số có thể dịch sau fix |

Scope retest điển hình: 30-50% tổng TC ban đầu + full reconciliation matrix.

### Bước D.2 — Pre-retest dry-run

Lặp lại Mode B logic với golden file ngày retest (khách có thể update golden file). Block retest nếu dry-run fail.

### Bước D.3 — Run TC retest

Giống Mode C nhưng:
- Mở lại file defect cũ, đổi status: Open → Verified-fixed / Reopened (nếu vẫn Fail)
- Defect mới phát sinh từ regression → UAT-{NNN+} với note "regression from UAT-{NNN-cũ} fix"

### Bước D.4 — Output `{section}-uat-retest-{N}-{date}.md`

Format: list TC retested + status (Pass / Fail / Pass after fix / New regression) + reconciliation matrix mới + defect changelog (closed/reopened/new).

### Bước D.5 — Loop control

Sau retest:
- Đạt pass criteria → **Mode E**
- Còn Major/Critical → schedule retest round (N+1)
- Quá 3 round mà còn Critical → escalate (block release, gọi `/da-pm` reassess timeline)

## Mode E — Signoff (đóng UAT chính thức)

**Mục đích**: Pack release artifact ngôn ngữ nghiệp vụ cho khách ký. KHÔNG dùng thuật ngữ kỹ thuật.

### Bước E.1 — Check pass criteria

Đối chiếu với pass criteria đã chốt trong Mode A:
- Pass rate happy ≥ 95%? ✓/✗
- Defect Critical open = 0? ✓/✗
- Defect Major open ≤ 2 với mitigation? ✓/✗
- Reconciliation matrix 100% trong tolerance? ✓/✗
- Performance đạt? ✓/✗

Nếu chưa đạt → KHÔNG sinh signoff. Quay lại Mode D.

### Bước E.2 — Viết signoff pack

Format `{section}-uat-signoff-{date}.md` (audience: SC Manager khách):

```
# Biên bản nghiệm thu UAT — {Section} — {Tenant}
Ngày: {date}
Phiên bản: {version} của Smartlog Control Tower

## 1. Phạm vi nghiệm thu
- View / chức năng: ...
- Thời gian UAT: {start} → {end} ({N} session)
- Người tham gia phía khách: ...
- Người tham gia phía Smartlog: ...

## 2. Kết quả tổng quan
- Tổng test case: {N}
- Pass rate: {%}
- Defect Critical: 0 (open) / {N} (đã đóng)
- Defect Major: {open}/{closed}
- Đối chiếu số liệu: {M/N} chỉ tiêu trong dung sai cho phép

## 3. Số liệu nghiệm thu chính
(Bảng metric của section — dashboard vs golden file khách, đã accept)

## 4. Vấn đề tồn đọng (nếu có)
(Major defect chưa fix + mitigation plan + cam kết fix date)

## 5. Kết luận
☐ Chấp thuận nghiệm thu, đưa vào sử dụng chính thức
☐ Chấp thuận có điều kiện (xem mục 4)
☐ Chưa chấp thuận

## 6. Chữ ký
Đại diện khách (SC Manager): _______________
Đại diện Smartlog (PM): _______________
```

### Bước E.3 — Bóc thuật ngữ kỹ thuật

Trước khi giao signoff doc cho khách, bóc các thuật ngữ sau (per memory [[feedback_i18n_no_internal_refs]] + da-ops-release convention):

| ❌ Thuật ngữ kỹ thuật | ✅ Thay bằng |
|---|---|
| ClickHouse, MV, materialized view, MergeTree | "kho dữ liệu phân tích" |
| QueryConfig, FormConfig, FE ViewConfig | "cấu hình màn hình" |
| `logging.activity`, LogDbContext, AppDbContext | "nhật ký hệ thống" |
| `mv_psv_main`, `mv_filter_*` | "nguồn dữ liệu" |
| SQL Appendix, JOIN, CTE | bỏ hẳn — đính kèm trong phụ lục kỹ thuật riêng nếu cần |
| Severity Sev1-4, tech_layer | "mức độ nghiêm trọng cao/trung bình/thấp" |
| Filter, drill-down, hero card | "bộ lọc", "xem chi tiết", "thẻ tổng quan" |

### Bước E.4 — (Optional) PDF render

Nếu khách yêu cầu PDF có brand → hand off `/da-ops-release` (đã có flow Edge headless render với brand Smartlog Control Tower lightmode).

## Common Mistakes

| Mistake | Fix |
|---|---|
| Bắt đầu UAT mà chưa chốt tolerance | Tolerance là pre-condition của Mode B, không phải kết quả |
| Reconcile Dashboard vs Golden khi chưa quét summary + anomaly | Data nền có thể bẩn (volume âm, status mâu thuẫn, key trùng) — đối chiếu trên rác. B.0/B.0b chạy TRƯỚC reconciliation 3 nguồn |
| Bỏ qua đối chiếu chéo upstream, chỉ tin dashboard MV | Dashboard MV là dẫn xuất — phải khớp hệ gốc (WMS/SWM cho in-full, TMS report cho on-time). B.5 confusion matrix + set diff = bắt buộc cho section có nguồn upstream |
| Cross-check 2 nguồn khác grain mà không rollup | TMS grain `Order×Trip`, MV grain `so×whseid` — phải `GROUP BY` về cùng cấp đơn (kh=`max`, gn=`sum`) trước khi so, nếu không double-count |
| Cross-check TMS↔MV mà không align timezone | TMS `TenderedDate` giờ VN, `mv_otif` UTC — quy cả 2 về ngày VN, nếu không lệch đơn giáp ranh ngày |
| Inline chuỗi tiếng Việt vào SQL cross-check | clickhouse-connect corrupt UTF-8 trong scalar subquery khi inline → 0 row sai. Bind `{svc:String}` |
| Tự viết lại SQL audit/anomaly thay vì clone notebook | `flash_daily_mtd_audit.ipynb` + `tms_report_25_explore.ipynb` đã xử lý tz/grain/binding. Clone cell + đổi `PARAMS`, KHÔNG viết lại |
| So sánh chỉ Dashboard vs SQL, bỏ golden file | 3 nguồn = bắt buộc; thiếu 1 = không reconcile được |
| Defect log không có hypothesis root cause | Hypothesis bắt buộc — kể cả là "chưa rõ, cần `/da-ch` audit" |
| Full re-run sau dev fix | Retest scope = affected + regression panel; tiết kiệm thời gian khách |
| Signoff doc dùng thuật ngữ kỹ thuật | Audience là SC Manager — bóc hết technical jargon |
| Mark Pass khi số "gần đúng" | Pass = trong tolerance + accept; bằng không = Fail |
| Defer TC vô tội vạ khi hết giờ | Defer phải có lý do rõ; quá nhiều defer = session chưa chuẩn bị kỹ |
| Co-Authored-By trailer trong commit artifact UAT | KHÔNG — per memory [[feedback_no_coauthor_trailer]] |
| File suffix -v2, -v3 cho retest round | KHÔNG — dùng `-retest-1`, `-retest-2` ngữ nghĩa rõ |
| Tự sinh câu SQL trong script Excel UAT thay vì load từ registry | Registry là canonical (dashboard chạy đúng pattern này). Tự sinh dễ lệch — `count()` vs `uniqExact(so)`, BETWEEN UTC vs toDate, sai exclusion clause. Always dynamic-load section CH SQL block từ `projects/{tenant}/02-data/data-sources/sql-registry.md` |
| Nhồi insight (red flag, master data quality, KPI extension) vào Excel UAT | Insight = file md riêng cùng folder UAT. Excel = reconciliation pure. Audience khác nhau → file khác nhau. Khách mở Excel bị overload sẽ confuse "đây là số đối chiếu hay phân tích?" |
| Excel chỉ có SQL value (frozen) hoặc chỉ formula (live), không cả 2 | Cần dual SQL+formula để audit hai chiều: SQL = số dashboard sẽ show; Formula = tính lại từ Detail; diff = finding |
| Sheet Detail Orders KHÔNG có autofilter + freeze pane | Khách verify line-by-line cần filter theo NVC/Kho/Status. Autofilter + freeze header = bắt buộc |
| SQL appendix sheet không phân biệt registry vs ad-hoc | Source provenance phải hiển thị rõ ("sql-registry.md:line_no" với highlight xanh; "ad-hoc" với highlight vàng). Khách review biết ngay query nào canonical, query nào tạm |
| Datetime ETA/ATA store dạng text (`toString(toDateTime(...))`) | Text cells không sort/filter range được; Trend formula bị stuck với prefix-text match fragile. Đúng: CH `SELECT col` (raw UTC, KHÔNG convert `toDateTime(col, 'Asia/Ho_Chi_Minh')` — sẽ lệch ngày vs dashboard) → Python `datetime` → openpyxl ghi serial → format `yyyy-mm-dd hh:mm:ss`. Trend formula dùng `COUNTIFS(J, ">="&DATE(...), J, "<"&DATE(...)+1)` |
| % values cùng metric type nhưng khác số decimal hiển thị (vd 93.3% bên cạnh 92.43%) | Áp `number_format = "0.00\"%\""` cho TẤT CẢ % cells → display luôn 2 decimals. Excel float storage có thể drop trailing zero (raw=93.3 không phải 93.30) nhưng DISPLAY via format = "93.30%" — consistent visible. Document trong README rằng đây là Excel quirk, không bug. |
| Mix format `#,##0` và `#,##0.00` cho count/CSE cùng sheet | Count integer → `#,##0`. Số có thập phân → `#,##0.00`. KHÔNG mix trong cùng cột — chốt 1 format theo data type của metric đó. |
| `to_date` dùng exclusive-end convention (Python `range()` / `timedelta`) thay vì inclusive | Registry SQL dùng `BETWEEN toDate(from) AND toDate(to)` — inclusive cả hai đầu. `to_date` là ngày cuối cùng CÓ trong kết quả. Ví dụ: 18→22 May thì `to_date='2026-05-22'`, KHÔNG phải `'2026-05-23'`. Sai → lấy thừa 1 ngày data |
| Tính OTIF bằng intersection `ontime_status='Ontime' AND infull_status='Infull'` thay vì dùng cột `otif_status` | MV có 3 cột status độc lập. `otif_status` dùng raw decimal comparison cho infull check, còn `infull_status` dùng `round(...,4)`. Intersection sẽ lệch so với dashboard. Luôn dùng `otif_status = 'OTIF'` để đếm OTIF |
| Health Matrix dùng cột Kho group thay vì Kho code (`whseid`) | COUNTIF/COUNTIFS trong Health Matrix phải trỏ về cột chứa đúng dimension value. Kho code (B) ≠ Kho group (C) — BKD1 vs BKD. Match sẽ fail hoặc trùng tình cờ (NKD = NKD) |
| Fail Reason sheet dùng COUNTIF 1 điều kiện (chỉ reason text) | Phải dùng COUNTIFS 2 điều kiện: (1) reason match VÀ (2) status = failed tương ứng (`ontime_status='Failed Ontime'` hoặc `infull_status='Failed Infull'`). COUNTIF 1 điều kiện đếm thừa row có reason text nhưng status không phải failed |

## Rationalization Table

| Thought | Reality |
|---|---|
| "Khách bận, gộp dry-run + session làm 1 cho nhanh" | Dry-run phát hiện số lệch → mất uy tín tại session với khách. Tách = bắt buộc |
| "Golden file phức tạp quá, dùng SQL raw làm chuẩn cũng được" | SQL raw chỉ chứng minh "code chạy đúng SQL ta viết" — không chứng minh "đúng nghiệp vụ khách". Phải có golden |
| "Defect Sev3 cosmetic, không cần repro chi tiết" | Mọi defect đều cần evidence — Sev3 hôm nay có thể là Sev1 ngày mai khi khách triển sang vận hành thật |
| "Pass rate 80% là OK cho UAT lần 1" | Mode A đã chốt ≥95% — đổi criteria sau khi thấy fail = mất chuẩn. Retest cho đến khi đạt |
| "Khách OK với % lệch 2pp, không cần root cause" | Khách OK bây giờ ≠ khách OK sau 3 tháng vận hành; root cause vẫn phải có, dù chỉ là note nội bộ |
| "Mình tự viết SQL nhanh hơn parse registry, vẫn ra số đúng mà" | Đến lúc dashboard updated registry (vd đổi `count()` → `uniqExact(so)`) thì script tự viết drift → giải thích với khách "vì sao Excel khác dashboard?" tốn thời gian gấp nhiều lần. Dynamic-load đảm bảo always-in-sync. |
| "Insight pack nhồi vào Excel cho khách thấy 1 file thôi tiện hơn" | Excel UAT có 6-8 sheet đã đủ; nhồi thêm 4 sheet insight → khách scan flat 12 sheet bị lạc, không biết focus đâu. Md riêng cho phép khách open Excel để reconcile, mở md để hiểu story. Audience khác, tool khác. |
| "SQL ad-hoc trong sheet appendix không cần label provenance" | Khi 2 tháng sau khách thấy số dashboard khác script → mở SQL appendix sheet không biết query nào canonical query nào tạm → mất uy tín. Provenance label = audit trail. |

## Output Artifacts (tóm tắt)

| Artifact | Mode | Path |
|---|---|---|
| UAT plan | A | `projects/{tenant}/{section}/uat/{section}-uat-plan.md` |
| Test cases | A | `projects/{tenant}/{section}/uat/{section}-uat-cases.md` |
| Reconciliation template | A | `projects/{tenant}/{section}/uat/{section}-uat-reconciliation-template.md` |
| **Excel pack (7 sheet, registry SQL + Excel formula live)** | A | `projects/{tenant}/{section}/uat/{section}-uat-numbers-{from-date}_to_{to-date}.xlsx` |
| **Script Python re-runable (đổi window → re-run)** | A | `projects/{tenant}/scripts/uat_{section}_export.py` |
| **Ops insight pack (optional, file riêng KHÔNG nhồi Excel)** | A | `projects/{tenant}/{section}/uat/{section}-uat-ops-insight-{from-date}_to_{to-date}.md` |
| **Data audit report (summary + 5 nhóm anomaly)** | B | `projects/{tenant}/{section}/uat/{section}-uat-dataaudit-{date}.md` |
| **Cross-system reconciliation (WMS/TMS upstream)** | B | `projects/{tenant}/02-data/audit-results/{a}-vs-{b}-{date}.md` |
| Dry-run report | B | `projects/{tenant}/{section}/uat/{section}-uat-dryrun-{date}.md` |
| Execution log | C | `projects/{tenant}/{section}/uat/{section}-uat-execution-{date}.md` |
| Defect stubs | C | `projects/{tenant}/{section}/uat/defects/UAT-{NNN}-{slug}.md` |
| Retest log (round N) | D | `projects/{tenant}/{section}/uat/{section}-uat-retest-{N}-{date}.md` |
| Signoff pack | E | `projects/{tenant}/{section}/uat/{section}-uat-signoff-{date}.md` |

## Read References By Topic

| Topic | Read file |
|---|---|
| Plan structure | `templates/uat-plan.md` |
| Test case format | `templates/uat-cases.md` |
| Reconciliation matrix structure | `templates/uat-reconciliation.md` |
| Execution log format (Mode C+D) | `templates/uat-execution-log.md` |
| Signoff pack format (audience khách) | `templates/uat-signoff.md` |
| 3-source reconciliation method depth | `references/reconciliation-method.md` |
| Summary health + 5 nhóm anomaly + cross-check WMS/TMS (Mode B.0/B.0b/B.5) | `references/data-audit-and-crosscheck.md` |
| Tooling canonical (SQL đã xử lý tz/grain/binding) | `projects/{tenant}/notebooks/flash_daily_mtd_audit.ipynb`, `projects/{tenant}/notebooks/tms_report_25_explore.ipynb` |

## Mandatory Ending Signals

Mỗi invocation MUST end với:

- `UAT_MODE`: A | B | C | D | E
- `UAT_BASE_PATH`: `projects/{tenant}/{section}/uat/`
- `ARTIFACTS_WRITTEN`: list path các file sinh ra/update
- `BLOCKERS`: list rào cản (vd "golden file chưa có", "tolerance chưa chốt", "MV chưa refresh"); empty nếu không có
- (Nếu Mode B) `DATA_AUDIT`: summary verdict (vd "scale/freshness OK; 5 nhóm anomaly: 4 sạch, 1 có vi phạm → UAT-007") hoặc `skipped`
- (Nếu Mode B) `CROSS_CHECK`: kết quả đối chiếu upstream (vd "MV↔TMS#25 cấp đơn: 19,965 trùng, on-time đồng thuận 97.8%, 2 nhóm off-diagonal → drill") hoặc `n/a (section không có nguồn upstream)`
- `NEXT_MODE_SUGGESTED`: A | B | C | D | E | done
- (Nếu Mode C/D) `DEFECTS_OPEN`: {Critical: N, Major: N, Minor: N, Cosmetic: N}
- (Nếu Mode E) `SIGNOFF_STATUS`: approved | conditional | not-approved

## Handoff (skill nào sau da-uat)

- Defect Critical/Major cần fix gấp → `/debugger`
- Nhiều defect cần phân loại + route → `/da-triage`
- Defect cần formal bug report cho dev squad QA → `/qa-executor` intake mode
- Defect Lớp C (UX drift PRD) → `/da-trace`
- Số lệch root cause SQL/MV → `/da-ch`
- Cần update PRD vì lộ business rule mới → `/ba`
- Signoff approved, commit artifacts → `/da-projects`
- Khách yêu cầu PDF signoff có brand → `/da-ops-release`
- Sau release retro → `/da-retro`
