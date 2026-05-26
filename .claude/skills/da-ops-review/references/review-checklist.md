# Da-Ops-Review Checklist

> Checklist chi tiết cho `/da-ops-review`. Đi qua từng mục với artifact trên tay.
> Source of truth: `.claude/skills/da-ops/SKILL.md` (HARD RULES + anti-patterns + STOP points + pre-delivery checklist) + `.claude/skills/da-ops/references/data-fetch-patterns.md` + `.claude/skills/da-ops/references/report-templates.md`.

---

## Trục 1 — Data Accuracy (số liệu trung thực)

### 1.1 Frontmatter & metadata
- [ ] Tiêu đề khớp kind: `# Daily Ops Pulse — <Tenant> — <YYYY-MM-DD>` / `# Adoption Report — <Feature> — Day <N>` / `# Anomaly — <YYYY-MM-DD> — <slug>` / `# <YYYY-WW>` weekly / `# Incident — <ticket>`
- [ ] `Window` định dạng `00:00 → <now>` UTC+7 hoặc `<from> → <to>` UTC+7, khớp với data trong body
- [ ] `Pulled at` ISO + UTC+7, không cũ quá so với context (>24h cho daily pulse = warning về freshness)
- [ ] `Tenant DB` ghi alias hoặc tên tenant — KHÔNG ghi connection string thô, KHÔNG ghi password/credential
- [ ] `Author` có ghi rõ
- [ ] Period/window khớp giữa frontmatter và Appendix SQL filter (vd Appendix WHERE date >= '2026-05-08' khớp Window 08/05)

### 1.2 Mọi con số phải truy ngược về SQL
- [ ] Mọi số trong "1-line headline" có SQL tương ứng trong Appendix
- [ ] Mọi số trong bảng "Key numbers" / "Reach" / "Depth" / "Friction" có Q? ref trỏ về Appendix
- [ ] Mọi số trong "User activity" có SQL (thường gộp chung Q?)
- [ ] Mọi số trong "Insights" có Q? ref
- [ ] Tỷ lệ % có ghi rõ tử/mẫu hoặc derive được từ 2 con số có Q?
- [ ] Số làm tròn theo quy ước (1 thập phân cho %, integer cho count, 2 thập phân cho thời gian giây/phút)
- [ ] Không có số "ước tính ~X" / "khoảng Y" cho thứ có thể query được

**Severity guide cho 1.2:**
- Số không có Q? ref nào trong Appendix → 🔴 BLOCKER
- "khoảng X" / "ước tính ~Y" cho số có thể query → 🔴 BLOCKER
- Số ví dụ từ template (12, 23, 145 — đặc biệt nếu trùng số trong template `report-templates.md`) còn rớt → 🔴 BLOCKER
- Round lệch chút → 🟢 NIT

### 1.3 SQL Appendix quality
- [ ] Mỗi entry Appendix có đủ: `Source` + `Tenant` + `Run at` + `SQL` block
- [ ] Mỗi query có comment hoặc heading ("-- Hỏi: <câu hỏi business>") nói rõ con số nó produce
- [ ] Filter time window trong WHERE khớp với `Window` của frontmatter
- [ ] JOIN với entity table khi cần resolve tên user/module (Name > Code rule)
- [ ] Có `LIMIT` (đặc biệt cho query có thể trả nhiều rows; query aggregation thì không cần)
- [ ] Aggregation đúng (COUNT distinct user vs COUNT actions vs SUM volume)
- [ ] Schema/table có thật trong codebase — verify với `backend/src/Smartlog.Infrastructure/**/*DbContext*.cs` hoặc `pipeline/sql/`
- [ ] Nếu là domain entity (không phải activity log) → có `DeletedTime IS NULL` filter

### 1.4 Cross-check 3 số quan trọng nhất
Chọn 3 số có impact lớn nhất (thường: số trong headline + 2 row top của Key numbers / Reach / Depth). Với từng số:
- [ ] Tìm Q? ref → đối chiếu logic SQL
- [ ] Nếu logic SQL có nghi vấn (filter sai period, JOIN miss, aggregation sai) → flag 🔴 BLOCKER
- [ ] Nếu logic OK nhưng số trông bất thường (vd volume = 0 cho ngày làm việc bình thường, hoặc % > 100) → flag `[NEEDS RE-QUERY]`

### 1.5 Baseline cho cột Δ (HARD RULE của /da-ops)
> `/da-ops` HARD RULE: cột Δ phải có baseline thật (query riêng), không đoán.

- [ ] Mỗi cột "Δ" / "vs prior" / "vs baseline" có Q?-baseline tương ứng trong Appendix
- [ ] Q?-baseline filter đúng period baseline (vd "trung bình 4 tuần trước" = WHERE date BETWEEN 4 weeks ago AND last week)
- [ ] Aggregation của Q?-baseline cùng metric với Q? current (vd cùng COUNT distinct user — không trộn COUNT distinct với COUNT actions)
- [ ] Số baseline trong body khớp 100% với SQL result Q?-baseline

**Severity guide cho 1.5:**
- Cột Δ không có Q?-baseline → 🔴 BLOCKER
- Baseline period khác current period đáng kể (vd current = today, baseline = 6 tháng trước, không có biện minh) → 🔴 BLOCKER
- Baseline aggregation khác current → 🔴 BLOCKER
- Baseline có nhưng Q?-baseline timestamp cũ >7 ngày so với current → 🟡 WARNING

### 1.6 Data quality flags / N/A handling
- [ ] Nếu activity log không bật cho 1 module → có ghi `[N/A]` + nguyên nhân, không bịa số
- [ ] Nếu connection thiếu cho 1 tenant → có ghi `[N/A]` + nguyên nhân
- [ ] Nếu query timeout / empty → có ghi `[N/A]` + nguyên nhân, KHÔNG fabricate
- [ ] Placeholder `<chưa query>` / `<...>` từ template KHÔNG còn rớt vào output (đã chuyển thành `[N/A]` đúng cách hoặc đã thay bằng số thật)

**Severity guide cho 1.6:**
- Placeholder `<...>` rớt vào output → 🔴 BLOCKER
- Số mà không có `[N/A]` annotation khi query thật sự không chạy được → 🔴 BLOCKER (số bịa)
- `[N/A]` không có lý do (vd "[N/A]" trống) → 🟡 WARNING

---

## Trục 2 — Data Source Correctness

### 2.1 Source layer chọn đúng
Theo `data-fetch-patterns.md`:
- [ ] Activity log query → dùng `LogDbContext` / `logging.activity` (KHÔNG dùng AppDbContext)
- [ ] Domain entity count → dùng `AppDbContext` + entity table tương ứng (vd `Tenders`, `VfrDocuments`)
- [ ] Aggregation đã có dashboard → ưu tiên dùng QueryConfig endpoint sẵn có thay vì viết SQL ad-hoc
- [ ] Cross-tenant aggregation → có lặp từng tenant, KHÔNG join cross-tenant qua DbContext (do multi-tenant connection riêng)

### 2.2 Schema/table có thật
- [ ] Schema name (`logging`, `dbo`, `wms`, ...) có trong codebase
- [ ] Table name có trong DbContext entity definition hoặc migration file
- [ ] Cột query có trong entity property hoặc EF configuration
- [ ] QueryConfig code (nếu dùng) có trong `backend/src/**/QueryConfigs/*.json`

**Severity guide cho 2.2:**
- Schema/table không tồn tại → 🔴 BLOCKER (artifact dựa trên fiction)
- Cột không tồn tại → 🔴 BLOCKER
- QueryConfig code không có trong codebase → 🟡 WARNING (có thể đã đổi tên — verify với backend team)

### 2.3 Tenant scope
- [ ] Mỗi query có ghi rõ tenant (alias hoặc name) trong Appendix
- [ ] Single-tenant artifact (daily / adoption / anomaly / incident) → KHÔNG có data tenant khác lẫn vào body
- [ ] Multi-tenant artifact (weekly) → có caveat tenant nào lặp được, tenant nào skip + lý do
- [ ] Email user trong artifact thuộc đúng tenant scope

**Severity guide cho 2.3:**
- Báo cáo cho Mondelez có nhắc số/email Acme (cross-tenant leak) trong single-tenant artifact → 🔴 BLOCKER
- Multi-tenant artifact không có caveat partial → 🟡 WARNING
- Tenant DB alias technical (`mondelez_prod_replica`) lộ trong body — chỉ giữ trong Appendix là OK → 🟢 NIT

### 2.4 Time zone & window
- [ ] Window declared UTC+7 trong frontmatter
- [ ] Time trong body present UTC+7 (không lẫn UTC raw)
- [ ] Nếu DB lưu UTC → SQL có convert hoặc artifact có note "DB lưu UTC, đã convert UTC+7 khi present"
- [ ] Insight về "khoảng câm lúc X giờ" có giờ đúng UTC+7 (không nhầm với UTC raw)

**Severity guide cho 2.4:**
- Insight "operator câm lúc 03:00" mà thực ra là 10:00 local (UTC chưa convert) → 🔴 BLOCKER (kết luận sai về logistics VN peak)
- Time trong body lẫn UTC raw, không có suffix UTC+7 → 🟡 WARNING
- Window có UTC+7 nhưng 1-2 chỗ trong body lẫn không suffix → 🟢 NIT

### 2.5 Soft-delete & filter convention
- [ ] Nếu query domain entity (AppDbContext) → có filter `DeletedTime IS NULL`
- [ ] Activity log (LogDbContext) thường KHÔNG soft-delete → KHÔNG có filter `DeletedTime IS NULL` thừa
- [ ] Filter tenant rõ trong WHERE (qua connection scope hoặc explicit `tenant_id`)

**Severity guide cho 2.5:**
- Domain entity query thiếu `DeletedTime IS NULL` → số có thể bao gồm record đã xoá → 🔴 BLOCKER
- Activity log có `DeletedTime IS NULL` thừa (nếu schema không có cột đó) → 🟢 NIT (query có thể chạy lỗi nhẹ)

---

## Trục 3 — Language & Audience

### 3.1 Ngôn ngữ
- [ ] Toàn bộ artifact bằng tiếng Việt (trừ tên cột SQL, code identifier, tên module/widget business)
- [ ] Không lẫn lộn Anh-Việt giữa các đoạn (consistency)
- [ ] Thuật ngữ logistics/SC đúng tiếng Việt khi có (vd "tồn kho", "đơn hàng", "tuyến vận chuyển")
- [ ] Tên tenant viết đầy đủ lần đầu mention ("Mondelez Việt Nam"), sau đó tên ngắn ("Mondelez") OK

### 3.2 Name > Code rule
- [ ] Không có mã trần (`user_id=87`, `entity_code=TENDER_CREATE`, `module=TXN_MOVE`) trong body artifact
- [ ] Mọi mention user có tên đọc được — email business hoặc tên hiển thị (vd `ops_lead@mondelez.com`)
- [ ] Mọi mention entity có tên action đời thường ("Tạo Tender", "Gửi VFR") thay vì code
- [ ] Lần đầu mention thực thể quan trọng có thể kèm cả tên + ref technical: `"thao tác Tạo Tender (entity_code TENDER_CREATE)"` — chỉ trong Appendix; body chính chỉ có tên
- [ ] Bảng User activity / Key numbers — column đầu là tên đọc được, mã (nếu có) ở cột phụ

**Exception (cho phép giữ mã):**
- Tenant code chính thức (Mondelez, Acme, TTCS) — quen thuộc với team
- Module/widget name nội bộ (Tender, VFR, Transaction Move, Flash Daily) — đã quen với tenant
- Connection alias internal CHỈ trong Appendix, KHÔNG trong body

**Severity guide cho 3.2:**
- Mã trần (user_id, entity_code) trong báo cáo audience SC Manager / BOD → 🔴 BLOCKER
- Mã trần trong báo cáo audience Internal PM / Engineering → 🟡 WARNING
- Mã trần CHỈ trong Appendix (không trong body) → OK, không flag

### 3.3 Audience-fit
Verify audience đích trong frontmatter và check depth:

| Audience | Đặc điểm phải có | Đặc điểm KHÔNG được có |
|---|---|---|
| **SC Manager (tenant)** | Operational depth, exception list, breakdown user/module | Tên schema/table, alias DB, code identifier kỹ thuật |
| **BOD/C-Level (tenant)** | 1-2 page, top-line numbers, action title súc tích | Detail user-level, jargon ops, bảng dày >10 dòng |
| **Rollout/CS Smartlog** | Danh sách user cần CS gọi, exception queue, daily refresh | Cross-tenant raw data nhạy cảm (trừ khi có purpose) |
| **Engineering / Tech lead** | Friction signals (error count, abandon rate, time-to-complete), regression flag | Pure narrative không metric (quá business cho engineering) |
| **Internal PM (default cho /da-ops)** | Multi-section, có Open questions cho rollout team, link Q? rõ ràng | (đây là audience nội bộ — gần như mọi thứ OK) |

- [ ] Depth khớp với audience đích
- [ ] Nếu artifact cho BOD nhưng có 30 dòng exception list → flag mismatch

### 3.4 Insight / Action title (so-what)
Mọi heading insight quan trọng + 1-line headline:
- [ ] Action title nói **so-what**, không phải label
- [ ] Có số / có direction / có driver

**Examples:**
```
❌ "Phân tích Volume Tender" (label)
✅ "Volume Tender hôm nay giảm 38% — phần lớn Operator chưa login"

❌ "Adoption widget Flash Daily"
✅ "Widget Flash Daily đạt 60% reach sau 5 ngày — Mondelez nhanh hơn Acme 2 ngày"
```

### 3.5 Tone & jargon
- [ ] Không jargon ops nặng cho audience SC Manager / BOD (vd "MV", "BFF query", "DbContext")
- [ ] Acronym lần đầu có expand (KPI, SKU, OTIF...) trong body audience tenant
- [ ] Không ngôn ngữ phán xét chủ quan ("rất tệ", "thảm họa") — dùng số

**Severity guide cho 3.4 + 3.5:**
- Action title chỉ là label (nhiều heading) → 🟡 WARNING
- Headline 1 dòng không có so-what → 🟡 WARNING
- Audience mismatch (BOD report dày 30 dòng) → 🟡 WARNING
- Lẫn Anh-Việt nặng → 🟡 WARNING
- Typo / format → 🟢 NIT

---

## Trục 4 — Insight Integrity

### 4.1 1-line headline
- [ ] Headline có thật (không phải "Chưa có data" trừ khi cả pulse là skeleton)
- [ ] Headline súc tích 1 câu, có số + so sánh
- [ ] Headline khớp với top-finding trong Insights (không lệch giữa headline và body)

### 4.2 Insight 4-component rule (HARD RULE của /da-ops)
Với mỗi insight quan trọng:
- [ ] Có **QUAN SÁT** (số cụ thể, copy chính xác từ SQL — có Q? ref)
- [ ] Có **SO SÁNH** (vs baseline / vs expectation — baseline có Q?-baseline)
- [ ] Có **GIẢ THUYẾT** (vì sao lại như vậy?)
- [ ] Có **ĐỀ XUẤT** (action cụ thể: WHO + WHAT)

**Examples:**
```
❌ Insight thiếu thành phần:
"Volume Tender giảm." (chỉ có quan sát, không số, không so sánh, không giả thuyết, không action)

❌ Insight có số mơ hồ:
"Volume Tender khoảng 145 đơn, có vẻ thấp." (không Q? ref, không Q?-baseline)

✅ Insight đủ 4 thành phần:
"- Quan sát: Volume tạo Tender 145 đơn (Q1)
 - So sánh: giảm 38% so với trung bình 4 tuần trước (235 đơn — Q1-baseline)
 - Giả thuyết: chỉ 2/8 Operator login trước 10:00, có thể do shift change
 - Đề xuất: CS Smartlog gọi ops_lead@mondelez.com hỏi kế hoạch ca chiều, trước 14:00"
```

**Severity guide cho 4.2:**
- Insight thiếu cả 4 thành phần → 🔴 BLOCKER (không phải insight, chỉ là note)
- Insight thiếu Đề xuất (chỉ Quan sát + So sánh + Giả thuyết) → 🟡 WARNING
- Insight có Đề xuất "tiếp tục theo dõi" (không action) → 🟡 WARNING (đây không phải action)
- Đề xuất không có WHO + WHEN cụ thể → 🟡 WARNING

### 4.3 Exception-first / Silence surface
- [ ] Artifact có surface exception (volume bất thường, user vắng mặt, module silence)
- [ ] Mỗi exception có owner đề xuất + severity
- [ ] Silence (operator chính không login, widget mới không ai chạm) được surface — không bị bỏ qua

**Severity guide cho 4.3:**
- Exception bị chôn ở cuối artifact (không trong headline / điểm nhấn) → 🟡 WARNING
- Silence quan trọng không được surface → 🟡 WARNING

### 4.4 Internal consistency
- [ ] Số trong Headline khớp với số trong Insights tương ứng (không lệch)
- [ ] Số trong Key numbers khớp với số trong Insights tương ứng
- [ ] Conclusion trong Insights phù hợp với data trong bảng (không có claim không support)
- [ ] Window/Period trong frontmatter khớp Window trong tất cả các section
- [ ] Tenant trong frontmatter khớp tenant trong tất cả các Q? Appendix

### 4.5 Recommendations / Open questions quality
- [ ] Mỗi Đề xuất có owner đề xuất + timeline (giờ / ngày / tuần)
- [ ] Đề xuất cụ thể (không phải "cải thiện process" / "tiếp tục theo dõi")
- [ ] Có priority/impact note nếu có thể (vd "Trước 14:00 hôm nay" mức Now)
- [ ] Open questions cho rollout team rõ ràng — mỗi câu hỏi có owner verify

### 4.6 Pre-delivery checklist của /da-ops
Verify rằng artifact đã pass pre-delivery checklist của `/da-ops` (xem `da-ops/SKILL.md`):
- [ ] Mọi số trong "Key numbers" / "User activity" / "Insights" có Q? ref trỏ về Appendix
- [ ] Mỗi entry Appendix có đủ: source + tenant + run-at timestamp + SQL
- [ ] Số trong artifact khớp 100% với SQL result (không round, không "đẹp lên")
- [ ] Baseline có query riêng (không phải đoán)
- [ ] Ô không query được đã ghi `[N/A]` rõ ràng
- [ ] Không còn số ví dụ từ template
- [ ] Time đã convert UTC+7 đúng

**Severity guide cho 4.6:** mỗi mục fail từ checklist này → blocker hoặc warning tương ứng (đa số là blocker vì /da-ops liệt là HARD RULE).

---

## Verdict Decision Matrix

| Tổng số blocker | Tổng số warning | Verdict |
|---:|---:|---|
| 0 | 0–2 | 🟢 APPROVED |
| 0 | 3+ cùng 1 trục | 🟡 CONDITIONAL |
| 0 | ≥1 về số liệu (Trục 1) | 🟡 CONDITIONAL |
| 0 | ≥1 về tenant scope (Trục 2.3) | 🟡 CONDITIONAL |
| ≥1 | * | 🔴 NEEDS REWORK |

**Edge case:**
- Artifact không có Appendix SQL → blocker tự động "no SQL audit trail" → NEEDS REWORK
- Artifact có cross-tenant leak (single-tenant kind nhưng nhắc tenant khác) → blocker tự động → NEEDS REWORK
- Artifact có placeholder `<chưa query>` rớt → blocker tự động → NEEDS REWORK
- Artifact có cột Δ mà không có Q?-baseline → blocker tự động → NEEDS REWORK

---

## Quick-fire Self-Check (cho reviewer trước khi gửi verdict)

- [ ] Tôi đã đọc HẾT artifact (không skim)?
- [ ] Tôi đã cross-check ít nhất 3 số quan trọng nhất với SQL Appendix?
- [ ] Tôi đã verify schema/table có thật trong codebase (cho ít nhất 1 SQL trong Appendix)?
- [ ] Tôi đã check baseline (Q?-baseline) cho mọi cột Δ?
- [ ] Tôi đã quét cross-tenant leak cho artifact single-tenant?
- [ ] Tôi đã check placeholder `<chưa query>` / `<...>` không rớt vào body?
- [ ] Tôi đã check insight 4-component cho mỗi insight quan trọng?
- [ ] Tôi đã check time UTC+7 conversion (đặc biệt insight về peak / silence giờ)?
- [ ] Mỗi finding của tôi có cite location cụ thể (section / dòng)?
- [ ] Mỗi finding có fix cụ thể (không chỉ phán xét)?
- [ ] Tôi KHÔNG rewrite artifact?
- [ ] Verdict của tôi phù hợp với Decision Matrix?
