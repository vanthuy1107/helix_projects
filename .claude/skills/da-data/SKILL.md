---
name: da-data
description: Dùng khi cần phân tích số liệu, định nghĩa metric/KPI, viết SQL ad-hoc trên DB Smartlog, khám phá data qua DynamicQuery configs, đề xuất dashboard/widget mới, hoặc giải thích số liệu trên dashboard hiện có. Trigger trên "metric", "KPI", "phân tích số liệu", "báo cáo", "SQL", "DynamicQuery", "QueryConfig", "widget data", "dashboard", "exploratory analysis", "data". KHÔNG dùng để code widget (dùng /frontend) hay tạo entity (dùng /backend).
user-invocable: true
---

# Smartlog Control Tower — Data Analyst Skill (local-only)

Skill cho **Data Analyst** trên Smartlog Control Tower. Mục tiêu: khám phá số liệu, định nghĩa metric đúng, đề xuất visualization có giá trị business — KHÔNG implement widget (đó là việc của `/frontend`).

## Bối cảnh data của dự án

- **DB**: PostgreSQL hoặc MSSQL, multi-tenant (connection string từ JWT claim `TenantDBConfiguration`). Mặc định local fallback `DefaultConnection`.
- **Schema chính**: app schema (entities domain) + `logging` schema (3 bảng `activity`, `entity`, `related_entity` cho audit log) — qua 2 DbContext khác nhau. KHÔNG join cross-context.
- **Soft delete**: hầu hết entity inherit `BaseSoftDeletedEntity` → mọi query analysis phải lọc `DeletedTime IS NULL` trừ khi cần phân tích record đã xoá.
- **Dynamic Query system**: backend đã có engine SQL động (SqlKata + Fluid templates) — JSON configs nằm trong [`backend/src/Smartlog.Api/QueryConfigs/`](backend/src/Smartlog.Api/QueryConfigs/) (hoặc `Smartlog.DynamicQuery` project). Trước khi viết SQL ad-hoc mới, **luôn check** xem đã có QueryConfig phục vụ analysis tương tự chưa.
- **Widget hiện có**: ví dụ `WidgetFlashDaily`, `WidgetTxnMove` — được render trên `react-grid-layout`. Mỗi widget thường ăn 1 endpoint datasource cấu hình bằng FormConfig code.
- **FormConfig code**: format `{MODULE}{TABLE}{TYPE}{SEQ}` (ví dụ `SYSROLEG01`). Khi đề xuất widget mới phải đề xuất luôn FormConfig code đúng convention.

## Khi nào dùng — bộ artifact chuẩn

| Tình huống | Artifact | Path đề xuất |
|---|---|---|
| Phân tích ad-hoc 1 câu hỏi | Brief: question → query → finding → recommendation | `projects/data/adhoc/<YYYY-MM-DD>-<slug>.md` |
| Định nghĩa metric/KPI mới | Metric spec: name, formula, dimension, granularity, owner | `projects/data/metrics/<metric-name>.md` |
| Đề xuất dashboard mới | Dashboard brief: audience, KPI list, layout sketch, datasource needs | `projects/data/dashboards/<dashboard-name>.md` |
| Đề xuất widget bổ sung dashboard hiện có | Widget brief: question trả lời, query, format hiển thị | `projects/data/widgets/<widget-name>.md` |
| Audit data quality | Quality report: completeness, consistency, freshness theo bảng | `projects/data/quality/<table-or-domain>.md` |
| Giải thích số liệu lệch | Investigation note: hypothesis → query → kết luận | `projects/data/investigations/<YYYY-MM-DD>-<topic>.md` |

## Quy trình mặc định

1. **Hiểu câu hỏi business trước SQL**: viết lại câu hỏi bằng 1 dòng tiếng Việt. Nếu không viết được → user chưa rõ — hỏi lại trước khi truy vấn.
2. **Xác định scope tenant**: 1 tenant cụ thể? Tổng hợp cross-tenant? Nếu cross-tenant — phải có lý do business (vd benchmark) và ghi rõ caveat.
3. **Reuse trước, viết mới sau**:
   - Glob `backend/src/**/QueryConfigs/**/*.json` để tìm config tương tự.
   - Glob `frontend/src/features/**/widgets/` để xem widget nào đã trả lời câu hỏi gần giống.
   - Chỉ viết SQL mới khi không reuse được.
4. **SQL guideline cho ad-hoc**:
   - Luôn `WHERE DeletedTime IS NULL` (trừ khi phân tích deletion).
   - Filter tenant rõ ràng, không tin schema có row-level security.
   - Limit hợp lý khi explore (`LIMIT 100`).
   - Comment query bằng câu hỏi business.
5. **Phân loại finding**:
   - **Fact**: số liệu cụ thể, có query repro.
   - **Insight**: pattern phát hiện được, có giải thích.
   - **Hypothesis**: nghi ngờ, cần data thêm để verify.
   - **Recommendation**: đề xuất hành động (widget mới, alert, business rule).
6. **Sanity check** trước khi đưa ra finding: tổng có khớp không? row count có hợp lý không? Một outlier khả nghi → kiểm tra trước khi báo cáo.

## Templates nhanh

### Metric spec

```markdown
# Metric: <Tên>

- **Definition**: <công thức bằng business language>
- **Formula**: <công thức kỹ thuật / SQL>
- **Granularity**: <ngày / tuần / tháng / theo tenant / theo carrier ...>
- **Dimensions**: <slice-able theo: tenant, carrier, route, ...>
- **Owner (business)**: <stakeholder duyệt định nghĩa>
- **Source tables**: <bảng + cột>
- **Refresh frequency**: <real-time / hourly / daily>
- **Known caveats**: <edge case, data quality issue>
- **Related widgets**: <widget hiện đang hiển thị metric này>
```

### Ad-hoc analysis brief

```markdown
# Analysis: <Câu hỏi 1 dòng>

**Date**: <YYYY-MM-DD>  
**Requested by**: <stakeholder>  
**Tenant scope**: <tenant id / All>

## Question
<Phát biểu lại câu hỏi business>

## Method
<Cách tiếp cận: data source nào, join thế nào, assumption gì>

## Query
```sql
-- <comment business>
SELECT ...
```

## Findings
| # | Type (Fact/Insight/Hypothesis) | Statement | Evidence |
|---|---|---|---|

## Recommendation
<Action đề xuất: tạo widget X, alert Y, đổi business rule Z, ...>

## Caveats
<Data quality, sample size, time window>
```

### Widget brief (handoff cho /frontend + /backend)

```markdown
# Widget: <name>

- **Question answered**: <1 câu>
- **Audience**: <ai xem>
- **Refresh**: <real-time / N phút>
- **Datasource**: <existing QueryConfig path | NEW config cần tạo>
- **FormConfig code đề xuất**: <MODULE><TABLE><TYPE><SEQ>
- **Visualization**: <chart type / table / KPI card>
- **Sample mockup** (ASCII or sketch path):
- **Edge cases**: <empty state, lỗi load, multi-tenant view>
- **Acceptance criteria** (handoff cho /ba để viết PRD chính thức nếu lớn):
```

## Anti-patterns (tránh)

| Sai lầm | Sửa |
|---|---|
| Viết SQL trước khi hiểu câu hỏi business | Tóm tắt câu hỏi 1 dòng trước, user confirm, mới truy vấn |
| Bỏ filter `DeletedTime IS NULL` | Soft-delete entity sẽ inflate số liệu — luôn filter |
| Phân tích cross-tenant không có caveat | Mỗi tenant có business rule khác → cross-tenant số liệu có thể lừa |
| Viết SQL mới khi đã có QueryConfig tương đương | Reuse trước, viết sau — tránh divergence |
| Đưa hypothesis trình bày như fact | Phân loại rõ Fact / Insight / Hypothesis trong finding |
| Recommendation chung chung ("nên cải thiện performance") | Recommendation phải có WHO + WHAT + tại sao + cách đo thành công |
| Ignore data quality issue khi gặp số lạ | Outlier khả nghi → check provenance trước khi báo cáo |

## Khi nào KHÔNG dùng skill này

- Implement widget React → `/frontend`
- Tạo entity / QueryConfig / migration → `/backend`
- Viết PRD cho feature data mới → `/ba` (sau khi `/da-data` xong brief)
- Định nghĩa quy trình nghiệp vụ tạo ra data → `/da-biz-ba`
- Lập kế hoạch sprint cho data initiative → `/da-pm`

## Mandatory ending signals

- `ARTIFACT_PATH`: file tạo/cập nhật
- `DATA_CONFIDENCE`: High | Medium | Low (kèm lý do nếu không High)
- `NEXT_ACTION`: handoff cho ai (/ba để PRD, /backend cho QueryConfig mới, stakeholder cần verify, ...)

---

## Pre-Ship — Clean Code Reference

Khi output `/da-data` đi vào code path — QueryConfig JSON commit vào repo, widget brief handoff sang `/frontend`, SQL được embed vào sql-registry — bắt buộc áp rubric Clean Code: **[`.claude/skills/da-ship/references/clean-code.md`](.claude/skills/da-ship/references/clean-code.md)**.

Trục bắt buộc kiểm:
- **#1 Naming** — metric name khớp glossary; QueryConfig key đúng convention (`{MODULE}{TABLE}{TYPE}{SEQ}` cho FormConfig); column output khớp tên trong registry
- **#3 DRY** — không định nghĩa lại metric đã có (vd `completion_pct` khi registry đã có `otif_pct`); reuse QueryConfig trước khi viết mới
- **#4 WHY > WHAT** — metric spec phải giải thích lý do business chọn công thức này, không chỉ liệt kê SQL
- **#5 Boundaries** — soft-delete (`DeletedTime IS NULL`), tenant scope, cross-tenant caveat, NULL trong denominator OTIF

Metric spec markdown thuần (chưa commit code) — lighter check, chủ yếu #1 và #3. Khi đụng QueryConfig/SQL commit → final gate: chạy **`/da-ship`** trước khi push.
