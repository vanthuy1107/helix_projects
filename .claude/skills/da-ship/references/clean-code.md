# Clean Code — Phiên Bản DA/BA/PM

Tài liệu này dịch 7 nguyên tắc Clean Code của **Robert C. Martin (Uncle Bob)** sang ngữ cảnh PM/BA/DA: bạn không ship class C#/component React, bạn ship **SQL widget, QueryConfig JSON, FormConfig seed, markdown artifact, pulse note, sql-registry entry**. Mọi nguyên tắc bên dưới đều dịch sang artifact loại đó.

Đây là rubric tham chiếu cho `/da-ship` (Gate 2) và 5 skill consumer (`da-ch`, `da-data`, `da-ops`, `da-ops-review`, `da-trace`). Một nguồn duy nhất — DRY (chính là nguyên tắc 3 ở dưới).

---

## Triết lý nền

> *"Clean code reads like well-written prose."* — Uncle Bob

3 thước đo cứng:

1. **Người khác đọc cold (không hỏi bạn) vẫn hiểu** — Dev squad reviewer là người đầu tiên thử nghiệm điều này. Nếu họ phải ping bạn hỏi *"câu CTE này tính gì?"* → fail.
2. **Sửa nó 6 tháng sau không sợ vỡ thứ khác** — bạn (hoặc PM kế nhiệm) mở SQL cũ 6 tháng sau có dám sửa không? Nếu phải copy ra file mới `-v2` vì sợ → fail.
3. **Một concept = một nơi định nghĩa** — OTIF tính ở 1 chỗ, mọi widget dùng chung. Đổi định nghĩa = đổi 1 chỗ.

Bất kỳ rule cụ thể nào dưới đây chỉ là cách đảm bảo 3 thước đo trên.

---

## 7 Nguyên Tắc — Áp dụng vào artifact của bạn

### 1. Meaningful Names — Tên có ý nghĩa nghiệp vụ

| Artifact | Tốt | Tệ | Lý do |
|---|---|---|---|
| SQL CTE | `orders_delivered_ontime` | `t1`, `cte_a`, `tmp_data` | Tên CTE = tên section trong câu chuyện SQL — Dev đọc xuống biết section đó tính gì |
| SQL alias bảng | `o` cho `orders` OK nếu file ngắn; `monthly_otif` rõ hơn cho subquery | `a`, `b`, `x` | Single-letter chỉ chấp nhận ở scope rất ngắn; subquery ≥ 5 dòng phải tên thật |
| Column output | `otif_pct`, `on_time_count` | `pct`, `cnt`, `val` | Output column là API — downstream widget/Excel bám vào tên này |
| JSON config key | `tenderListWithCarrierFilter` | `config1`, `q2`, `tmp` | Code khác ăn key này — đặt tên kém = grep cả repo không thấy |
| FormConfig code | `SLGTNDG01` (theo format `{MODULE}{TABLE}{TYPE}{SEQ}`) | `FORM1`, `TEST_CONFIG` | Convention đã chốt — phá convention = phá tooling |
| Markdown filename | `OTIF-ontime-target-debate.md` | `notes.md`, `final-v2.md` | Filename phải scan được không cần mở file ([[feedback_artifact_filenames]]) |
| Branch name | `fix/otif-target-90pct`, `feat/vfr-vehicle-filter` | `mybranch`, `temp`, `wip` | Branch là PR — Dev squad nhìn 30 branch phải biết cái nào ưu tiên |

**Quy tắc cứng:**
- Mọi domain term phải khớp glossary / sql-registry / business-rules. Đừng invent (`completion_pct` khi đã có `otif_pct` ở registry).
- Số ít / số nhiều / viết hoa phải nhất quán nội bộ artifact (vd: trong cùng SQL không vừa `Tender` vừa `tenders` vừa `BID`).
- Mã trần (`user_id=87`, `entity_code=TENDER_CREATE`) → không bao giờ xuất hiện trong artifact gửi audience (Name > Code, đã rule cứng của `/da-ops`).

### 2. Single Purpose — Một thứ làm một việc

| Artifact | Tốt | Tệ |
|---|---|---|
| SQL CTE | 1 CTE = 1 bước biến đổi (filter, join, aggregate, window) | 1 CTE 80 dòng làm: filter + 3 join + 2 window + group + having + sort |
| SQL file | 1 file = 1 widget / 1 metric | 1 file gộp 5 metric chỉ vì "tiện copy" |
| QueryConfig JSON | 1 config = 1 endpoint / 1 list view | 1 config 500 dòng cố gắng phục vụ 3 màn hình |
| Markdown PRD | 1 file = 1 feature scope | 1 file gộp 3 feature vì "có liên quan" |
| Pulse note | 1 file = 1 ngày × 1 tenant × 1 audience | 1 file gộp 3 tenant trong báo cáo single-tenant |
| Commit | 1 commit = 1 ý nghĩa nghiệp vụ ("fix OTIF target từ 95% → 90%") | 1 commit gộp 3 thay đổi không liên quan |

**Quy tắc cứng:**
- Nếu mô tả một thứ phải dùng từ "và" / "đồng thời" / "cùng lúc" → có thể đã vi phạm nguyên tắc này.
- CTE/function/file dài quá 50 dòng → kiểm tra xem có đang làm 2 việc không.

### 3. DRY — Don't Repeat Yourself

Nguyên tắc Uncle Bob viết: *"Every piece of knowledge must have a single, unambiguous, authoritative representation."*

| Tình huống | Sai | Đúng |
|---|---|---|
| Logic tính OTIF dùng ở 3 widget khác nhau | Copy SQL 3 lần, mỗi nơi 1 phiên bản lệch nhẹ | Định nghĩa canonical pattern trong `projects/{tenant}/02-data/data-sources/sql-registry.md`, mọi widget reference cùng pattern (xem [[feedback_sql_review_must_check_registry]]) |
| Filter resolver logic cho multi-select | Copy `coalesce({{multi_select}}, 'ALL')` vào CTE từng widget | Trace qua `WidgetFilterResolver` ([[feedback_sql_review_widget_runtime]]) — đừng copy logic resolver vào SQL |
| Định nghĩa "tenant Mondelez" | Hard-code tenant ID trong 5 file | 1 nơi duy nhất (config, hoặc connection alias) |
| Date range "last 4 weeks rolling baseline" | Lặp 4 lần expression `date_sub(now(), interval 28 day)` | CTE `baseline_window` reuse |
| OTIF target band 90/85 | Hard-code `90` rải rác | Reference từ 1 nơi (config / param), comment link sang ADR [[project_mondelez_otif_target]] |

**Quy tắc cứng:**
- Trước khi copy-paste SQL block sang file mới → STOP, hỏi: "Có nên extract ra registry/template không?"
- 3 lần lặp = bắt buộc DRY. 2 lần OK nhưng nên cảnh giác.

### 4. Comments giải thích WHY, không WHAT

Uncle Bob: *"Don't comment bad code — rewrite it."* Code đặt tên tốt là tự document. Comment chỉ ra đời khi WHY non-obvious.

| Tốt | Tệ |
|---|---|
| `-- Mondelez chốt target OTIF 90% (không phải 95% industry std); xem ADR [[project_mondelez_otif_target]] và OQ-07 cho lý do` | `-- select orders where status = delivered` |
| `-- Activity log lưu UTC, audience SC Manager VN dùng UTC+7 → phải convert` | `-- convert timezone` |
| `-- DeletedTime IS NULL: BaseSoftDeletedEntity không xóa thật, mọi entity domain phải filter` | `-- filter deleted rows` |
| `// Workaround: WidgetFilterResolver expand CSV cho multi-select; xem [[feedback_sql_review_widget_runtime]]` | `// handle multi select` |

**Quy tắc cứng:**
- Nếu xóa comment đi mà reader vẫn hiểu code → comment đó thừa, xóa.
- Comment dạng "này dùng cho X flow" / "Y team yêu cầu" → nên đẩy vào commit message hoặc PR description, không nhúng vào code (rot theo thời gian).
- TODO không có owner + deadline → cấm. `// TODO @claude` → cấm tuyệt đối trong code production.

### 5. Boundaries / Error Handling — Tin source thật, validate ở biên

Uncle Bob: *"Error handling is important, but if it obscures logic, it's wrong."* Quy tắc: validate ở biên hệ thống (input từ user, response từ API ngoài), bên trong tin code của chính mình.

| Loại biên | Phải handle |
|---|---|
| Multi-select filter | NULL (chưa chọn), empty array, 'ALL' sentinel, single value, multi value — tất cả 4 case có path rõ trong SQL/code |
| Timezone | DB lưu UTC (mặc định) → audience VN dùng UTC+7. Mọi date filter phải convert đúng phía nào. |
| Soft-delete | Entity domain inherit `BaseSoftDeletedEntity` → `WHERE DeletedTime IS NULL` mặc định. Activity log thường KHÔNG soft-delete — tuỳ schema. |
| Cross-tenant | Single-tenant report không leak data tenant khác. Cross-tenant report phải lặp từng tenant + ghi caveat. |
| Empty result | SQL ra 0 row → handle thay vì render bảng trống không message. Pulse note phải surface "silence" như tin tức. |
| NULL trong column | OTIF còn pending = NULL? Định nghĩa rõ ràng có tính vào denominator không. |

**Quy tắc cứng:**
- Edge case không phải "có thì handle" — phải liệt kê **trước** khi viết SQL/code, không catch sau khi prod báo lỗi.

### 6. Tests / Sanity Check — Reproducible

Uncle Bob F.I.R.S.T: Fast, Independent, Repeatable, Self-validating, Timely.

Phiên bản DA: bạn không viết unit test, bạn viết **sanity check** — proof artifact reproduce được.

| Artifact | Sanity check tối thiểu |
|---|---|
| SQL widget | SQL chạy được trên DB/CH đích → ra số khớp số trong artifact. Paste evidence vào Appendix (Source + Tenant + Run at + SQL block). |
| Pulse note | Mỗi số trong body truy ngược về 1 entry Q? trong Appendix. (`/da-ops-review` đã enforce — đây là "unit test" của bạn.) |
| QueryConfig | Backend boot không lỗi config parse. Endpoint trả ra structure khớp expected. |
| FormConfig seed | Chạy migration/seed local. Đăng nhập, FormConfig code mới hiện đúng trong UI. |
| sql-registry entry | SQL trong registry chạy lại trên CH ra số đúng (timestamp khi verify cuối). |
| Frontend small | Dev server start. Golden path render đúng. 1 edge case (empty/error state) render đúng. |

**Quy tắc cứng:**
- Không có sanity check = chưa "test" = chưa qua Gate 3 của `/da-ship`.
- "Trông đúng cú pháp" ≠ "chạy đúng" — luôn phải chạy thật.

### 7. Boy Scout Rule — Để lại sạch hơn lúc tới

Uncle Bob: *"Always leave the campground cleaner than you found it."*

Cảnh báo nhỏ thì không phải refactor lớn — chỉ là rule "khi đi qua thấy rác thì nhặt".

| Khi sửa X, kiểm tra | Vì |
|---|---|
| Sửa SQL widget → check sql-registry.md | Có cần update canonical pattern không, hay đang nhân bản divergence? |
| Sửa metric → check glossary/business-rules | Định nghĩa đã đổi → tài liệu khác phải đổi theo |
| Sửa filename → check tất cả reference | Filename rename trong markdown / sql-registry / pulse note cũ |
| Sửa SQL appendix trong 1 pulse → check headline + insight + key numbers cùng artifact | Một số dùng nhiều chỗ — `/da-ops` hard rule đồng bộ tất cả instance |
| Sửa OTIF target → check ADR | ADR / decision doc phải reflect |

**Quy tắc cứng:**
- KHÔNG tạo file `-v2`, `-v3`, `-new`, `-final`, `-copy` ([[feedback_no_v2_v3_filenames]]). Refactor in-place. Cần component khác = đặt tên nghiệp vụ (vd `-cockpit`, `-with-targets`).
- KHÔNG để TODO treo. Hoặc fix luôn, hoặc ghi rõ owner + deadline + issue link.
- KHÔNG để placeholder rớt: `<chưa query>`, `TODO @claude`, `console.log(...)`, `print(...)` trong diff ship → reject.

---

## Checklist Áp Dụng — 7 Câu Hỏi

Khi `/da-ship` chạy Gate 2, mỗi nguyên tắc map sang 1 câu hỏi cụ thể:

| # | Câu hỏi | Pass khi |
|---|---|---|
| 1 | Mọi tên (CTE, alias, column, file, branch) đọc tách rời (không context xung quanh) có hiểu nghĩa nghiệp vụ không? | Yes cho mọi tên |
| 2 | Có CTE / file / commit nào đang làm > 1 việc không thể tách bằng từ "và"? | None |
| 3 | Có block SQL / logic nào lặp ≥ 3 lần mà chưa extract ra registry/template? | None |
| 4 | Mọi comment đang giải thích WHY (lý do nghiệp vụ, ràng buộc ẩn) — không paraphrase code? | Yes |
| 5 | Edge case ở biên (NULL, empty filter, timezone, soft-delete, cross-tenant, empty result) đã liệt kê và handle? | Yes |
| 6 | Có evidence chạy thật (SQL output, Appendix, dev server screenshot, boot log) cho mỗi assertion trong diff? | Yes |
| 7 | Trước khi commit có scan TODO treo / `-v2` filename / `<chưa query>` / `console.log` / debug print không? | Đã scan, sạch |

**Verdict map:**
- 7/7 ✅ → Gate 2 PASS
- ≥ 1 nguyên tắc ⚠️ (PARTIAL — có vi phạm nhẹ với justification) → Gate 2 PARTIAL
- ≥ 1 nguyên tắc ❌ (FAIL — vi phạm rõ, không justify được) → Gate 2 FAIL

---

## Nguồn

- Robert C. Martin, *Clean Code: A Handbook of Agile Software Craftsmanship* (2008). 17 chương; rubric này chắt từ 7 trục lớn nhất áp dụng cho artifact DA.
- gstack philosophy ([github.com/garrytan/gstack](https://github.com/garrytan/gstack)): "Process replaces guesswork" — Clean Code là 1 phần của process gate, không phải tùy chọn.
- Memory liên quan: [[feedback_artifact_filenames]], [[feedback_no_v2_v3_filenames]], [[feedback_no_coauthor_trailer]], [[feedback_sql_review_must_check_registry]], [[feedback_sql_review_widget_runtime]], [[project_mondelez_otif_target]].
