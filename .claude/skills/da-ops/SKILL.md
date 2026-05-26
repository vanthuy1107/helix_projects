---
name: da-ops
description: Dùng khi cần đọc "nhịp sống" vận hành thực tế của khách hàng hôm nay/tuần này — ai đang dùng module nào, volume giao dịch, exception, pattern bất thường — để cung cấp insight cho team triển khai/vận hành. Khác /da-data (định nghĩa metric/báo cáo) — skill này là daily pulse, kể chuyện vận hành. Trigger trên "vận hành hôm nay", "khách dùng thế nào", "daily ops", "pulse", "operational insight", "activity log", "audit log", "ai đang làm gì", "rollout insight", "triển khai theo dõi". KHÔNG dùng để định nghĩa KPI dài hạn (dùng /da-data) hoặc debug bug (dùng /debugger).
user-invocable: true
---

# Smartlog Control Tower — Daily Operations Insight (local-only)

Skill cho **PM/BA/DA theo dõi triển khai và vận hành**. Trả lời các câu hỏi kiểu:

- "Hôm nay tenant X có dùng module Tender không? Volume thế nào?"
- "Tuần này có pattern bất thường gì khi khách thao tác Transaction Move?"
- "Sau release v1.4 hai ngày, có ai chạm vào widget mới chưa?"
- "Tỷ lệ thành công khi tạo VFR của 5 tenant lớn nhất?"

KHÔNG phải `/da-data` — skill đó định nghĩa metric/dashboard dài hạn. Skill này là **daily pulse** — đọc data như đang nhìn camera giám sát, kể câu chuyện vận hành kèm insight cho rollout team.

## 🛑 NGUỒN SỰ THẬT — HARD RULE (không thể vi phạm)

**Mọi con số trong artifact PHẢI đến từ truy vấn SQL thật trên DB tenant tại thời điểm chạy.**

Skill này read-only — nhưng rủi ro lớn nhất KHÔNG phải sửa data, mà là **bịa số**: viết "volume Tender hôm nay khoảng 15 đơn" khi chưa chạy query nào. Số sai lan vào pulse note → rollout team gọi khách dựa trên đó → mất uy tín skill và uy tín cả dự án trước khách.

| ❌ TUYỆT ĐỐI KHÔNG | ✅ BẮT BUỘC |
|---|---|
| Tự suy diễn / ước lượng / "nghe có vẻ hợp lý" con số | Chạy SQL thật → copy số y nguyên vào artifact |
| Trích số từ memory, pulse cũ, hoặc câu chuyện trước | Re-query mỗi session — activity log thay đổi từng phút |
| "Khoảng 12 đơn", "ước tính ~80%", "thường thì..." cho số có thể query | Số chính xác từ query, hoặc ghi rõ `[N/A — chưa query được]` |
| Generate "ví dụ minh hoạ" trong template với số bịa rồi quên thay | Placeholder rõ `<chưa query>` cho đến khi có data thật |
| Round/đoán khi query timeout, empty, hoặc lỗi | STOP, báo user, KHÔNG fabricate |
| Insight không kèm SQL evidence | Mỗi insight quan trọng → SQL + tenant + window vào Appendix |
| Dùng baseline (vd "tuần trước 23 đơn") mà không query baseline đó | Phải query cả current period VÀ baseline period — không có số baseline thật → bỏ cột Δ |
| **Cùng 1 số xuất hiện ở 2+ vị trí (headline + insight title + key numbers + body Quan sát) mà các vị trí lệch nhau hoặc chỉ 1 vị trí có Q? ref** | Một số dùng ở nhiều chỗ thì phải bằng nhau ở mọi chỗ + ít nhất 1 vị trí có Q? ref. Khi fix 1 vị trí (vd headline) → grep nguyên artifact tìm số cũ → fix đồng bộ tất cả instance. Review chỉ flag 1 vị trí ≠ fix xong cho toàn artifact |

**Quy trình bắt buộc trước khi viết bất kỳ con số nào:**

1. Xác định data source — theo thứ tự reuse-trước-viết-sau:
   - QueryConfig sẵn có (`backend/src/**/QueryConfigs/`) → có endpoint trả ra view này không?
   - Widget hiện có (vd `WidgetTxnMove`, `WidgetFlashDaily`) → đã trả lời 1 phần chưa?
   - SQL ad-hoc trên `logging` schema (LogDbContext) hoặc app schema (AppDbContext)
2. Viết SQL theo conventions của dự án:
   - Filter `DeletedTime IS NULL` cho domain entity (activity log thường KHÔNG soft-delete)
   - Filter tenant rõ — multi-tenant connection (claim `TenantDBConfiguration`); cross-tenant phải lặp từng tenant
   - Time window: convert UTC ↔ UTC+7 đúng; comment SQL bằng câu hỏi business
3. Chạy query thật trên DB tenant đích (DB CLI / endpoint backend / dotnet user-secrets dev) — **xem output**
4. Copy số chính xác từ result vào artifact
5. Lưu SQL + tenant + thời điểm query vào **Appendix** của artifact (xem template bên dưới)

Nếu chưa query được (connection string thiếu / tenant không truy cập được / table chưa tồn tại / activity log không bật cho module đó) → **STOP**, báo user, KHÔNG viết artifact với số phỏng đoán. Có thể giao artifact ở dạng "framework có sẵn, chờ query" — nhưng PHẢI đánh dấu rõ tất cả ô số là `<chưa query>`.

## Bối cảnh data của dự án (rất quan trọng cho skill này)

- **Activity log nằm ở `logging` schema** — qua `LogDbContext` riêng, KHÔNG mix với `AppDbContext`. Có 3 bảng:
  - `activity` — mỗi user action 1 row
  - `entity` — entity nào bị thao tác
  - `related_entity` — liên kết
- **Multi-tenant**: mỗi tenant có connection riêng (claim `TenantDBConfiguration`). Khi cần insight cross-tenant phải lặp qua tenant — KHÔNG có view tổng hợp sẵn.
- **Soft delete**: filter `DeletedTime IS NULL` trong app schema; activity log thường KHÔNG soft-delete.
- **Time zone**: Smartlog phục vụ logistics VN — mặc định trình bày theo UTC+7. Nếu DB lưu UTC, phải convert khi đọc cho stakeholder.
- **Operating hours logistics**: peak thường 06:00-10:00 và 17:00-21:00 (sáng giao + chiều nhận). Pattern "im ắng giờ peak" = dấu hiệu bất thường, không phải normal.

## Reference Router

Đọc reference theo task — KHÔNG load tất cả mỗi lần:

| Task | Reference | Khi nào |
|---|---|---|
| Tra metric (formula, source table, baseline, audience) | [references/ops-metrics-catalog.md](references/ops-metrics-catalog.md) | Mỗi khi pick KPI cho artifact, hoặc khi user hỏi "metric X tính sao" |
| Apply 9 lens (drilldown / phân tích sâu) | [references/9lens-framework.md](references/9lens-framework.md) | Drilldown 1 module / 1 anomaly / 1 metric |
| Cách query an toàn (.NET / EF Core / multi-tenant / SQL flavor) | [references/data-fetch-patterns.md](references/data-fetch-patterns.md) | Mỗi khi cần viết SQL ad-hoc, đặc biệt khi gặp PostgreSQL vs MSSQL difference |
| Skeleton markdown 5 mode artifact (pulse / adoption / anomaly / weekly / incident) | [references/report-templates.md](references/report-templates.md) | Khi compose artifact — copy template tương ứng rồi điền |

Mặc định cho **daily pulse** (mode phổ biến nhất):
1. `ops-metrics-catalog.md` → pick category A/B/C cho daily
2. `data-fetch-patterns.md` → query patterns
3. `report-templates.md` → Template A (Daily Ops Pulse)

Mặc định cho **drilldown** (1 anomaly hoặc 1 module deep-dive):
1. `9lens-framework.md` → 9 lens
2. `ops-metrics-catalog.md` → metric cần phân tích
3. `data-fetch-patterns.md` → query per lens
4. `report-templates.md` → Template C (anomaly) hoặc tự compose drilldown

---

## Core query kit — pre-defined, build khi tenant DB query được

~8 câu hỏi lặp lại mỗi pulse — đáng cố định **TÊN + PARAM + LENS mapping** ngay từ bây giờ, kể cả khi chưa build script thật. Lý do: khi viết SQL ad-hoc lần đầu cho 1 tenant mới, Appendix dùng cùng ID → pulse note hôm nay so được với pulse note tuần trước, cross-session comparable, KHÔNG drift về cách đặt tên.

**Path khi build script** (per-tenant, không global):
```
projects/{tenant}/scripts/da-ops/core/
  ├── C00_profile-tenant.{pg|mssql|ch}.sql
  ├── C01_activity-volume-by-module.{pg|mssql|ch}.sql
  ├── ...
  └── README.md       # params, flavor, last_verified per script
```

### ⚠️ Tenant có thể chạy stack data-source khác — XÁC ĐỊNH TRƯỚC khi pick C00..C07

Catalog 8 query bên dưới là **default cho stack user-activity trên PG/MSSQL** (`logging.activity` qua LogDbContext). Nhưng tenant phân tích có thể trên stack khác — semantics pulse phải đổi:

| Stack | Data source | Pulse type | C02 user-pareto / C05 user-touched |
|---|---|---|---|
| **A. Operational PG/MSSQL** (default) | `logging.activity` + AppDbContext entity | User-activity pulse (ai làm gì, volume action) | ✅ Có data |
| **B. Analytics ClickHouse** | Business KPI MVs (mv_otif, mv_outbound_*, mv_alert_*, mv_dap_ung_*, mv_vfr_*) | Business-ops pulse (OTIF, DO volume, late, kho silent) | ❌ Không có user data → mark **N/A** trong per-tenant README; thay bằng warehouse/channel pareto |
| **C. Hybrid** | Cả hai (ops PG cho user activity + CH cho business KPI) | Cả 2 góc — note rõ source mỗi insight | Tách 2 file scripts theo stack |

**Bắt buộc Step 0 trước khi pick C00..C07**: đọc `projects/{tenant}/.env` (hoặc tenant config) để biết stack. Ghi vào header pulse note.

**Per-tenant README** mô tả mapping cụ thể C0x → MV/table thật của tenant đó. Mondelez (stack B) đã có ở [projects/mondelez/scripts/da-ops/core/README.md](../../../projects/mondelez/scripts/da-ops/core/README.md) — Mondelez bind C02 và C05 = N/A, các C khác map sang business-KPI semantics.

Hiện scope đầu tiên = `projects/mondelez/scripts/da-ops/core/` (ClickHouse stack, C00 đã verified 2026-05-10).

### Catalog (8 query core — Stack A default; xem per-tenant README cho variant)

| ID | Tên | Params | Maps to lens | Mode dùng |
|---|---|---|---|---|
| C00 | `_profile-tenant` | tenant | #0 Profile | Mọi mode (sanity check trước khi tin số) |
| C01 | `activity-volume-by-module` | tenant, since, until | #5 Concentration | daily, weekly |
| C02 | `top-users-pareto` | tenant, since, until, limit=50 | #5 Concentration | daily, weekly |
| C03 | `hourly-heatmap-localtime` | tenant, since(7d), tz=UTC+7 | #1 Completeness, #8 Segmentation | daily |
| C04 | `same-weekday-baseline` | tenant, metric, weeks_back=4 | #4 Timeline, #7 Comparison | daily (cột Δ) |
| C05 | `distinct-users-touched-feature` | tenant, feature_code, since=release_date | #5 Concentration | adoption |
| C06 | `funnel-create-vs-success` | tenant, entity_code, since | #1 Completeness | adoption, anomaly |
| C07 | `silence-detector` | tenant, expected_modules[], window_hours=24 | #1 Completeness | daily, weekly (no-news = news) |

### Header convention (bắt buộc khi build)

```sql
-- name: C01_activity-volume-by-module
-- params: :tenant_alias, :since (UTC), :until (UTC)
-- flavors: postgresql | mssql
-- schema_deps: logging.activity (LogDbContext)
-- maps_to_lens: #5 Concentration
-- last_verified: <YYYY-MM-DD> — <tenant alias đã chạy thật>
-- expected_shape: module(text), actions(int), pct(float)
```

### Cách dùng trong Appendix pulse note

Khi pulse Appendix tham chiếu core query, KHÔNG paste lại full SQL — chỉ ref:
```
### Q1 — Pareto module hôm nay
- Source: core script C01 — projects/mondelez/scripts/da-ops/core/C01_activity-volume-by-module.pg.sql
- Tenant: mondelez-vn
- Params: since=2026-05-10T00:00+07, until=2026-05-10T17:30+07
- Run at: 2026-05-10 17:32 UTC+7
- Result rows: 7
```

Câu hỏi ad-hoc ngoài 8 cái core → vẫn paste full SQL như cũ (rule cứng "1 SQL / 1 number" trong [Appendix template](#appendix--data-sources) không đổi).

### Khi nào KHÔNG nên build script (giữ ad-hoc)

- Câu hỏi 1 lần / drilldown 1 anomaly
- Module mới release < 30 ngày (schema còn drift)
- Tenant chưa có baseline volume ổn định
- Câu hỏi cross-tenant kiểu Pareto tenant — luôn cần custom

### Maintenance

- Mỗi tháng review `last_verified` — chạy lại C00..C07 cho mỗi tenant active, nếu schema thay đổi → bump version
- Khi entity / `caller_name` format / `entity_code` convention đổi ở backend → C0x liên quan có thể chết; ai sửa backend phải verify lại scripts core đã `last_verified` trong vòng 30 ngày
- KHÔNG add script mới vào core nếu chưa lặp ≥ 3 pulse khác nhau

---

## Khi nào dùng — bộ artifact chuẩn

| Tình huống | Artifact | Path |
|---|---|---|
| Daily ops digest 1 tenant | Pulse note + 5 insight | `projects/ops/daily/<tenant>-<YYYY-MM-DD>.md` |
| Sau release N ngày — adoption check | Adoption report | `projects/ops/adoption/<feature>-d<N>-<YYYY-MM-DD>.md` |
| Phát hiện anomaly | Anomaly note kèm hypothesis | `projects/ops/anomalies/<YYYY-MM-DD>-<slug>.md` |
| Rollout weekly digest cho team | Multi-tenant snapshot | `projects/ops/weekly/<YYYY-WW>.md` |
| Hỗ trợ điều tra customer complaint | Activity reconstruction | `projects/ops/incidents/<ticket>-<YYYY-MM-DD>.md` |

## Quy trình mặc định — 5 bước

### 1. Frame the question (1 câu)
Viết câu hỏi cần trả lời bằng 1 dòng. KHÔNG mở data ra trước. Vd:
- ✅ "Hôm nay 09/05, tenant Acme có Operator nào tạo Tender không và bao nhiêu cái?"
- ❌ "Xem hôm nay khách dùng gì" (quá rộng — sẽ ra data dump không insight)

### 2. Identify data sources & scope tenant
- Source nào trả lời được? Activity log? Domain entity? Both?
- Tenant nào? 1 tenant cụ thể hay so sánh? Nếu cross-tenant — ghi rõ caveat.
- Time window? Hôm nay (00:00 → now UTC+7)? 24h gần nhất? Tuần ISO?

### 3. Pull data — reuse trước, viết SQL sau (BẮT BUỘC chạy thật)
- Check QueryConfig sẵn có (`backend/src/**/QueryConfigs/`) — có config tương đương cho ops view này không?
- Check widget hiện có — vd `WidgetTxnMove`, `WidgetFlashDaily` có thể đã trả lời 1 phần.
- Nếu phải viết SQL ad-hoc:
  - Filter `DeletedTime IS NULL` cho domain entity (activity log thường không cần)
  - Filter tenant rõ
  - Convert time về UTC+7 khi present
  - Comment SQL bằng câu hỏi business
- **Chạy query thật, xem output thật** — không có output → không có số. Lưu SQL + tenant + timestamp chạy vào Appendix (sẽ paste vào artifact ở Step 5).
- Nếu output empty / timeout / lỗi → ghi `[N/A]` vào artifact + ghi nguyên nhân vào "Open questions"; KHÔNG viết số phỏng đoán thay thế.

### 4. Read like a story, not a dump
Khi nhìn data thô, đặt câu hỏi:
- **Volume**: cao hay thấp so với baseline? (cần baseline — tuần trước, tháng trước cùng kỳ)
- **Distribution**: ai làm chính? 1 user làm 80%? hay phân bố đều?
- **Time pattern**: đúng peak logistics không? Có khoảng "câm" lạ không?
- **Funnel**: bao nhiêu khởi tạo, bao nhiêu thành công, bao nhiêu fail/abandon?
- **Outlier**: row nào kỳ lạ — value cực đoan, retry nhiều lần, user thao tác nhanh bất thường?
- **Silence**: feature/widget nào KHÔNG được chạm sau release? (no-news cũng là news)

### 5. Insight ≠ Number — viết 3-5 insight có actionable
Mỗi insight phải có:
- **Quan sát** (số liệu cụ thể — copy từ SQL result, KHÔNG bịa)
- **So sánh** (vs baseline / vs expectation — baseline cũng phải có query)
- **Giải thích giả thuyết** (vì sao như vậy?)
- **Hành động đề xuất** cho team triển khai (training? hotfix? business rule? gọi khách hỏi?)

Mỗi con số trong insight PHẢI truy ngược được về 1 query trong Appendix. Insight kiểu "cảm giác volume thấp" mà không có số → bỏ, hoặc chuyển thành "Open question" cho lần sau query.

## Templates nhanh

### Daily ops pulse

> Lưu ý: tất cả ô `<...>` là placeholder. KHÔNG copy số từ template — số phải đến từ SQL result thật ở Appendix.

```markdown
# Daily Ops Pulse — <Tenant> — <YYYY-MM-DD>

**Window**: 00:00 → <now> UTC+7
**Pulled at**: <YYYY-MM-DD HH:mm UTC+7>
**Tenant DB**: <tenant connection alias>
**Author**: <name>

## 1-line headline
<Câu chuyện 1 dòng vận hành hôm nay — chỉ viết khi có số thật từ Appendix. Không có data → ghi "Chưa có data — xem Open questions">

## Key numbers
| Module | Volume today | Baseline (avg 4 tuần) | Δ | Source |
|---|---|---|---|---|
| Tender create | <số từ Q1> | <số từ Q1-baseline> | <%> | Q1 |
| VFR submit | <số từ Q2> | <số từ Q2-baseline> | <%> | Q2 |
| Txn move | <số từ Q3> | <số từ Q3-baseline> | <%> | Q3 |

> Ô nào chưa query được → ghi `[N/A]` + nêu lý do trong Open questions. KHÔNG bịa số.

## User activity
| Top user | Role | Actions | Notable | Source |
|---|---|---|---|---|
| <email> | <role> | <số từ Q4> | <quan sát> | Q4 |

## Time pattern
- Peak sáng (06-10 UTC+7): <observation từ Q5>
- Peak chiều (17-21 UTC+7): <observation từ Q5>
- Khoảng câm bất thường: <none / hours — chỉ ghi nếu Q5 cho thấy>

## Insights
### Insight 1 — <action title nói so-what, không phải label>
- **Quan sát**: <số cụ thể từ Appendix> (ref: Q?)
- **So sánh**: <vs baseline có query — không có baseline thật → bỏ insight này hoặc dời sang Open questions>
- **Giả thuyết**: <vì sao>
- **Đề xuất**: <action cụ thể: WHO + WHAT — vd "CS gọi user_b@acme hỏi vì sao chưa login từ T-3">

### Insight 2 — ...

## Open questions cho rollout team
- <câu hỏi cần verify với khách / CS>
- <data source nào không query được + lý do>

## Appendix — Data sources

> Mọi con số trong artifact này phải truy được về 1 trong các query bên dưới. Nếu insight có số mà không có query tương ứng → là số bịa, phải xóa hoặc query bổ sung.

### Q1 — <tên câu hỏi business>
- **Source**: `logging.activity` (LogDbContext) | `<schema>.<table>` (AppDbContext) | QueryConfig `<code>` | Endpoint `<route>`
- **Tenant**: <tenant alias / connection>
- **Run at**: <YYYY-MM-DD HH:mm UTC+7>
- **Result rows**: <n>
- **SQL**:
  ```sql
  -- Hỏi: <câu hỏi business>
  SELECT ...
  FROM ...
  WHERE ...
  ```

### Q2 — ...
```

### Adoption report (sau release feature mới)

```markdown
# Adoption Report — <Feature> — Day <N> sau release

**Released**: <YYYY-MM-DD>  
**Today**: <YYYY-MM-DD> (D+<N>)  
**Tenants in scope**: <list>

## Reach
| Tenant | Distinct users touched | % of expected users | First-touch lag (h) |
|---|---|---|---|

## Depth
| Tenant | Total uses | Avg uses per user | Repeated use rate |
|---|---|---|---|

## Friction signals
- Error/exception count: <N>
- Abandon rate (start but not complete): <%>
- Time-to-complete (median): <s>

## Verdict
- [ ] **Healthy adoption** — tiếp tục theo dõi
- [ ] **Slow start** — cần training / nhắc CS gọi khách
- [ ] **Friction** — cần hotfix / UX iteration → handoff `/ba` hoặc `/debugger`
- [ ] **Rejection** — feature không khớp nhu cầu → handoff `/da-discovery`

## Appendix — Data sources
### Q1 — Distinct users touched feature `<X>` per tenant
- **Source**: `logging.activity` filter by entity/module = `<X>`
- **Tenant**: <list>
- **Run at**: <YYYY-MM-DD HH:mm UTC+7>
- **SQL**:
  ```sql
  -- Hỏi: bao nhiêu user distinct chạm <X> kể từ release?
  SELECT ...
  ```

### Q2 — ...
```

### Anomaly note

```markdown
# Anomaly — <YYYY-MM-DD> — <slug>

**Detected when**: <khi đang chạy daily pulse / báo từ khách / monitoring>  
**Tenant scope**: <list>

## What's odd
<Mô tả bất thường — đính kèm số liệu, link query>

## Hypotheses (ranked)
1. <giả thuyết> — evidence ủng hộ / phản bác
2. ...

## Verification needed
- [ ] <action> — owner: <name>

## Severity
- Impact: <mô tả>
- Urgency: <Now / This week / FYI>

## Appendix — Data sources
### Q1 — <truy vấn cho thấy bất thường>
- **Source**: <bảng / QueryConfig / endpoint>
- **Tenant**: <tenant>
- **Run at**: <YYYY-MM-DD HH:mm UTC+7>
- **SQL**:
  ```sql
  ...
  ```

### Q2 — <truy vấn baseline để chứng minh đây là bất thường, không phải normal>
- ...
```

## Anti-patterns (tránh)

| Sai lầm | Sửa |
|---|---|
| **Tự bịa số / ước lượng / "khoảng X"** khi có thể query được | STOP. Query thật → copy số. Không query được → ghi `[N/A]` + lý do, KHÔNG fabricate |
| **Trích số từ pulse cũ / memory** mà không re-query | Activity log thay đổi từng phút. Re-query mỗi session, kể cả cùng tenant cùng câu hỏi |
| **Copy số ví dụ trong template** vào artifact thật | Template là placeholder — mọi số phải có Q? trong Appendix tương ứng |
| **Insight có số mà không có entry Appendix** tương ứng | Số không có SQL chứng minh = số bịa. Xóa hoặc query bổ sung |
| **Baseline ghi đại** ("tuần trước ~23 đơn") không query | Baseline cũng phải có query riêng (Q?-baseline). Không có baseline thật → bỏ cột Δ, KHÔNG đoán |
| **Số xuất hiện ở insight title / headline nhưng KHÔNG lặp lại trong body Quan sát với Q? ref** | Title chỉ là "label gây chú ý" — số trong title BẮT BUỘC có instance đối ứng trong body Quan sát với Q? ref. Title 1 số / body 1 số khác (vd title 61.95% / body 61.98%) = internal inconsistency = blocker |
| **Fix 1 vị trí của số mà không grep tìm tất cả instance** | Cùng 1 con số có thể xuất hiện ở headline, key numbers cell, insight title, insight body, Open questions, fix log. Khi sửa → grep nguyên artifact (`Grep` tool) tìm raw value cũ + value mới → fix đồng bộ tất cả. Sai 1 vị trí = artifact vẫn fail review |
| Data dump không insight | Viết headline 1 dòng TRƯỚC khi đưa bảng — nếu không viết được = chưa hiểu data |
| So sánh không có baseline | Mỗi number cần 1 baseline (tuần trước, tháng trước, expectation) — không thì không phán xét được cao/thấp |
| Cross-tenant aggregation không caveat | Mỗi tenant business khác nhau — gộp số liệu phải nói rõ caveat hoặc tách theo tenant |
| "User không dùng feature" mà không phân biệt no-data vs no-use | Có thể do tracking hỏng. Verify bằng bảng activity log + entity log |
| Bỏ qua silence | Operator chính KHÔNG login, widget mới KHÔNG ai chạm — đó là tin tức lớn |
| Insight chung chung "cần training" | Action phải có WHO + WHAT cụ thể: "CS gọi user_b@acme, hỏi vì sao chưa dùng widget Flash Daily" |
| Trộn ops insight với fix | Skill này read-only + insight. Fix bug → `/debugger`. Đổi metric definition → `/da-data` |
| Activity log join với app schema sai context | LogDbContext và AppDbContext là 2 connection riêng — không EF join được. Phải kéo riêng rồi merge ở report |
| Time UTC nhưng present UTC+7 không đổi | Logistics VN — luôn confirm timezone trước khi báo "khách không hoạt động lúc 03:00" (có thể là 10:00 local) |

## Khi nào KHÔNG dùng skill này

- Định nghĩa KPI/metric dài hạn → `/da-data`
- Debug 1 lỗi cụ thể → `/debugger`
- Viết business rule → `/da-biz-ba`
- Lập kế hoạch sprint dựa trên insight → `/da-pm` (sau khi `/da-ops` cho input)
- Audit UI có khớp PRD → `/da-trace`

## STOP points (bắt buộc dừng + báo user)

⏸ **Trước khi viết bất kỳ con số nào** — verify đã có SQL result thật trên tay. Chưa có → STOP, không viết.
⏸ **Tenant DB không truy cập được** (connection string thiếu, claim `TenantDBConfiguration` chưa có cho tenant này) → STOP, hỏi user, KHÔNG đoán số từ tenant khác.
⏸ **Query trả empty / timeout / error** → STOP, ghi `[N/A]` + nguyên nhân, KHÔNG fabricate. Có thể giao artifact dạng skeleton chờ query, nhưng đánh dấu rõ.
⏸ **Activity log không bật cho module đang hỏi** → STOP, báo "không có observability cho module X", handoff về backend để bật log; KHÔNG đoán volume từ entity table khác.
⏸ **Cross-tenant cần lặp** mà chưa lặp đủ → STOP, không tổng hợp partial; hoặc ghi rõ caveat "chỉ N/M tenant".
⏸ Trước khi mark task done — verify Appendix có ít nhất 1 query cho mỗi số xuất hiện trong artifact.

## Pre-delivery checklist (self-audit trước khi giao)

Đọc lại artifact, trả lời TRUNG THỰC từng câu — bất kỳ "Không" nào đều phải fix trước khi giao:

- [ ] Mọi số trong "Key numbers" / "User activity" / "Insights" có Q? reference trỏ về Appendix?
- [ ] Mỗi entry Appendix có đủ: source + tenant + run-at timestamp + SQL?
- [ ] Số trong artifact khớp 100% với SQL result (không round, không "đẹp lên")?
- [ ] Baseline (cột Δ, "vs prior", "vs expected") có query riêng — không phải đoán?
- [ ] Ô không query được đã ghi `[N/A]` rõ ràng (không để placeholder `<...>` trôi vào output)?
- [ ] Không còn số ví dụ từ template (12, 23, 145, 84...) còn sót lại trong artifact?
- [ ] Time đã convert UTC+7 đúng — không nói "khách câm lúc 03:00" khi thực ra là 10:00 local?
- [ ] **Cross-section number consistency**: với mỗi số quan trọng (headline + insight titles + key numbers), grep nguyên artifact tìm raw value. Cùng 1 logical metric ở 2+ chỗ → tất cả phải bằng nhau, đồng thời ≥ 1 chỗ có Q? ref. Vd "OTIF tuần này 62.34%" xuất hiện ở headline + key numbers + Insight 1 Quan sát → cả 3 phải = 62.34% và ít nhất Key numbers có Q1 ref.
- [ ] **After fix-pass: grep raw value cũ**: sau khi sửa 1 số (vd 61.95% → 61.58%), grep raw `61.95` trong file → phải không còn match nào. Nếu còn → fix chưa hoàn chỉnh, có instance khác cần đồng bộ.
- [ ] **Insight title number trace**: mỗi số trong heading insight (`### Insight N — ... 62.34%`) phải lặp lại trong body Quan sát ngay dưới với Q? ref. Title 1 số / body 1 số khác = internal inconsistency.

## Mandatory ending signals

- `ARTIFACT_PATH`: pulse / adoption / anomaly / weekly / incident note
- `TENANT_SCOPE`: tenant nào được query (nếu cross-tenant — list)
- `QUERY_COUNT`: số entry trong Appendix (= số SQL đã chạy)
- `INSIGHTS_COUNT`: số insight có actionable (mỗi insight ≥ 1 Q? reference)
- `DATA_GAPS`: list ô `[N/A]` + nguyên nhân (connection / log không bật / query timeout...)
- `URGENT_ACTIONS`: list action cần làm trong vòng 24h (nếu có)
- `HANDOFF_TO`: skill / role kế tiếp (vd CS team gọi khách, `/debugger` điều tra, `/da-discovery` review feature)

---

## Pre-Ship — Clean Code Reference

Pulse note `.md` thuần (commit chỉ vào `projects/` gitignored) **KHÔNG** cần qua `/da-ship`. Nhưng nếu SQL trong Appendix được nâng cấp thành canonical pattern và commit vào `projects/{tenant}/02-data/data-sources/sql-registry.md` (hoặc embed vào widget code) → SQL đó trở thành code đi production → bắt buộc qua rubric Clean Code: **[`.claude/skills/da-ship/references/clean-code.md`](.claude/skills/da-ship/references/clean-code.md)**.

Riêng pulse note nội bộ vẫn nên giữ:
- **#1 Naming** — Name > Code (tên user/module/tenant đầy đủ, không hiển thị `user_id=87`, `entity_code=TENDER_CREATE` cho audience SC Manager)
- **#2 Single Purpose** — 1 file = 1 ngày × 1 tenant × 1 audience; không gộp đa tenant trong báo cáo single-tenant
- **#6 Sanity** — mỗi số truy ngược về 1 Q? trong Appendix (đây chính là HARD RULE "nguồn sự thật" của skill này)

Khi đẩy SQL từ Appendix → sql-registry hoặc widget → chạy **`/da-ship`** làm gate cuối.
