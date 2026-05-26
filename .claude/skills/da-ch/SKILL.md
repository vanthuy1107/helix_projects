---
name: da-ch
description: Dùng khi cần làm việc trực tiếp với ClickHouse (chạy SQL ad-hoc qua HTTP API, audit pipeline MV, debug số liệu lệch, tối ưu query, đọc/đối chiếu DDL, fix Redshift SQL → ClickHouse SQL, hoặc thiết kế MergeTree / Materialized View). Trigger trên "clickhouse", "ch", "MV", "materialized view", "MergeTree", "analytics_workspace", "sql-registry", "audit pipeline", "kiểm tra số liệu MDLZ", "Redshift sang ClickHouse", "OLAP", "columnar". KHÔNG dùng để định nghĩa metric business-level (dùng /da-data) hay để code widget React (dùng /frontend).
user-invocable: true
---

# ClickHouse DA Skill — `da-ch`

Skill cho **Data Analyst / Data Engineer** làm việc trực tiếp với ClickHouse trên dự án **MDLZ Control Tower**. Mục tiêu: chạy SQL đúng dialect, audit pipeline MV, debug số liệu lệch, và xuất kết quả có thể truy vết — với **chuẩn 5 năm kinh nghiệm ClickHouse**: tư duy cột, hiểu MergeTree, biết khi nào MV tự bù trừ vs khi nào cần redesign.

> Skill này KHÔNG thay `/da-data`. `/da-data` định nghĩa metric ở tầng business; `/da-ch` thực thi SQL ở tầng engine.

---

## 1. Bối cảnh ClickHouse trong dự án

| Thuộc tính | Giá trị |
|---|---|
| Mode kết nối | HTTPS (cổng 8443) — không có MCP server, dùng `curl` |
| Cluster | ClickHouse Cloud — `*.ap-southeast-1.aws.clickhouse.cloud` |
| Schema chính | `analytics_workspace` (41 MV — xem [`projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.md`](projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.md)) |
| Schema test | `mondelez_stm_test`, `mondelez_swm_test` (được phép ghi) |
| Schema CDC | `default`, `swm-test` (read-only — KHÔNG ghi) |
| User mặc định | `helix` |
| SQL nguồn chân lý | [`projects/mondelez/02-data/data-sources/sql-registry.md`](projects/mondelez/02-data/data-sources/sql-registry.md) (158 charts, có cả Redshift SQL và ClickHouse SQL — luôn dùng ClickHouse SQL) |

Credentials lấy từ `.env` ở repo root hoặc user cung cấp trực tiếp trong conversation. **Không bao giờ commit credentials**, không log password ra audit file.

---

## 2. Tư duy 5 năm — Hiểu engine trước khi viết SQL

### 2.1 Columnar Thinking (bắt buộc nội hoá)

ClickHouse lưu theo cột. Mỗi cột là 1 file (hoặc 1 stream nén). Hệ quả thực dụng:

- **Cấm `SELECT *`** trong bất kỳ query nào ngoài `LIMIT 1` để xem schema. Mỗi cột thừa = thêm I/O = chậm.
- **Tránh `Nullable`** ở các cột tính toán nóng — `Nullable(T)` thực chất là 2 cột (mask + value), tốn dung lượng và slow down vector ops. Dùng default sentinel (`0`, `''`, `1970-01-01`) khi bài toán cho phép.
- **Đọc từ MV chuyên dụng**, đừng `JOIN` lại bảng raw. Kiến trúc dự án này đã denormalize sẵn vào MV → tận dụng.

### 2.2 MergeTree — Primary Key KHÔNG phải Unique Key

Đây là sai lầm phổ biến nhất khi DA chuyển từ Postgres/MSSQL sang. Trong MergeTree:

- `ORDER BY (a, b, c)` quyết định **layout vật lý** trên đĩa và là **sparse index** (mặc định mỗi 8192 rows mới có 1 entry).
- `PRIMARY KEY` (nếu khác `ORDER BY`) chỉ là phần prefix của `ORDER BY` được giữ trong RAM — vẫn không đảm bảo unique.
- Filter trên cột **đầu tiên** của `ORDER BY` → ClickHouse skip cả granule. Filter trên cột **thứ ba** → ít hiệu quả hơn, nhưng vẫn dùng được nếu cardinality thấp.

**Quy tắc khi đọc DDL của MV** ([`analytics-workspace_mvs.md`](projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.md)):

1. Tìm `ORDER BY (...)` của MV → đó là cột nên đặt vào `WHERE` đầu tiên.
2. Nếu `WHERE` của bạn không chạm cột đó → đang full scan, dù query trông "bình thường".
3. `PARTITION BY toYYYYMM(date)` là chuẩn → filter theo tháng/ngày sẽ prune partition.

### 2.3 JOIN — vũ khí yếu, dùng có chiến lược

ClickHouse JOIN thực hiện theo kiểu **build hash table cho bảng phải, scan bảng trái** (mặc định Hash Join). Hệ quả:

| Pattern | Đúng/Sai | Lý do |
|---|---|---|
| Bảng nhỏ bên phải | ✅ | RAM giữ hash table, nhỏ → nhanh |
| Bảng lớn bên phải | ❌ | OOM hoặc spill disk → chậm gấp 10× |
| `LEFT JOIN` lấy đầy đủ rows | OK nếu cần | |
| `ANY LEFT JOIN` lấy 1 match | ✅ ưu tiên | Tiết kiệm RAM khi quan hệ 1:N nhưng chỉ cần 1 |
| `JOIN` 3+ bảng raw | ⚠️ | Nên xem có MV denormalized không, ưu tiên đọc MV |
| Subquery thay JOIN cho lookup nhỏ | ✅ | `WHERE x IN (SELECT ... FROM small_table)` thường tốt hơn JOIN |

### 2.4 Aggregation — hàm đặc thù mạnh hơn pattern truyền thống

Sau 5 năm, DA giỏi không viết `COUNT(CASE WHEN cond THEN col END)` nữa:

| Cũ (Redshift / Postgres) | ClickHouse (ưu tiên) | Khi nào dùng |
|---|---|---|
| `COUNT(CASE WHEN c THEN 1 END)` | `countIf(c)` | Đếm có điều kiện |
| `SUM(CASE WHEN c THEN x END)` | `sumIf(x, c)` | Tổng có điều kiện |
| `COUNT(DISTINCT col)` | `uniqExact(col)` (chính xác) hoặc `uniqCombined(col)` (xấp xỉ, ~1% sai số, **rất nhanh**) | Báo cáo lớn ưu tiên `uniqCombined`, đối soát ưu tiên `uniqExact` |
| `COUNT(DISTINCT CASE WHEN c THEN col END)` | `uniqExactIf(col, c)` | |
| `GROUP BY` rồi join lại | `arrayJoin` + `groupArray` | Dữ liệu dạng array cùng row |
| `LAG / LEAD` | `lagInFrame / leadInFrame` (window) hoặc `neighbor` (toàn cột) | Window có sẵn từ v21.3+ |
| `STRING_AGG / LISTAGG` | `groupArray(col)` rồi `arrayStringConcat(..., ',')` | |

### 2.5 Materialized View — vũ khí tối thượng, nhưng có 2 loại

Đừng nhầm 2 loại MV:

- **Incremental MV** (`CREATE MATERIALIZED VIEW ... TO target`): mỗi `INSERT` vào source bảng → trigger query MV → ghi delta vào target. Phù hợp pre-aggregation real-time.
- **Refreshable MV** (`CREATE MATERIALIZED VIEW ... REFRESH EVERY X`): query lại toàn bộ định kỳ. Đa số MV của dự án này là **Refreshable** (xem `REFRESH EVERY 1 HOUR` trong DDL). Hệ quả thực dụng: **dữ liệu trong MV trễ tối đa 1 giờ** so với raw — phải nói rõ caveat này khi báo cáo.

Khi audit số liệu lệch giữa raw và MV:
- Hỏi `last_refresh_time` từ `system.view_refreshes` — không bao giờ assume MV "đã có data hôm nay".
- Nếu refresh fail (`exception_text`) → đó là root cause, không phải SQL của bạn sai.

### 2.6 Insert — không bao giờ chèn từng dòng

Nếu được yêu cầu seed data vào `mondelez_stm_test`/`mondelez_swm_test`:
- Batch ≥ 1.000 rows mỗi `INSERT`. Tốt nhất 10k–100k.
- Dùng `INSERT INTO ... FORMAT JSONEachRow` rồi pipe data, hoặc `INSERT INTO ... SELECT FROM s3('...')`.
- Đừng vòng lặp `INSERT INTO ... VALUES (...)` từng dòng — sẽ tạo ra hàng nghìn parts, dẫn đến `Too many parts` error và background merge nuốt CPU.

---

## 3. Kết nối — chuẩn HTTP API qua curl

### 3.1 Lệnh nền

```bash
curl --silent --show-error --fail-with-body \
  --user "$CLICKHOUSE_USER:$CLICKHOUSE_PASSWORD" \
  "https://$CLICKHOUSE_HOST:$CLICKHOUSE_PORT/" \
  --data-binary @- <<'SQL'
SELECT ...
FORMAT JSON
SQL
```

**Tại sao heredoc `<<'SQL'`**: Tránh shell expand `$`, backticks, dấu nháy đơn lồng nhau. PowerShell trên Windows: dùng here-string `@'...'@` (single-quoted, literal) hoặc lưu SQL ra `.sql` rồi `--data-binary @file.sql`.

### 3.2 Biến môi trường

| Biến | Giá trị |
|---|---|
| `CLICKHOUSE_HOST` | `<host>.ap-southeast-1.aws.clickhouse.cloud` |
| `CLICKHOUSE_PORT` | `8443` |
| `CLICKHOUSE_USER` | `helix` |
| `CLICKHOUSE_PASSWORD` | (lấy từ `.env` hoặc user cung cấp — KHÔNG hardcode, KHÔNG ghi vào audit file) |
| `CLICKHOUSE_SECURE` | `true` |

### 3.3 Output formats — chọn đúng cho mục đích

| Format | Dùng khi | Ghi chú |
|---|---|---|
| `JSON` | Cần parse, kiểm tra type, đếm rows trong meta | Có `data`, `meta`, `rows`, `statistics` |
| `JSONEachRow` | 1 row = 1 JSON line, dễ stream/append | Nhẹ hơn `JSON`, không kèm meta |
| `JSONCompactEachRow` | Khi schema đã biết, muốn payload nhỏ | Mỗi row là array, không có key |
| `PrettyNoEscapes` | Hiển thị trong terminal/audit file | Không escape ANSI — đọc người được |
| `Pretty` | Như trên nhưng có ANSI color | Tránh khi xuất ra `.md` |
| `TSV` / `TSVWithNames` | Pipe sang công cụ khác | Nhanh nhất |
| `CSVWithNames` | Đưa cho stakeholder Excel | Cẩn thận với cell có comma |

### 3.4 Tham số HTTP hữu ích (truyền qua query string)

| Param | Mục đích |
|---|---|
| `?max_execution_time=30` | Timeout query (giây) — luôn set khi explore |
| `?max_result_rows=10000` | Cản trở query trả mil rows về local |
| `?readonly=1` | Ép read-only — bảo hiểm khi chạy SQL từ nguồn không tin cậy |
| `?database=analytics_workspace` | Set default DB, đỡ phải prefix |
| `?send_progress_in_http_headers=1` | Theo dõi tiến độ query dài |

---

## 4. Quy trình chuẩn — Audit pipeline 1 feature

### Bước 1 — Định nghĩa câu hỏi

Viết 1 dòng: "Tôi đang xác minh metric X trên feature Y, kỳ Z, cho whseid `…`?". Nếu không viết được → user chưa rõ → hỏi lại trước khi tiêu CPU ClickHouse.

### Bước 2 — Tra `sql-registry.md`

```
Grep("tên feature", path="projects/mondelez/02-data/data-sources/sql-registry.md")
```

Đọc phần **ClickHouse SQL** (KHÔNG dùng Redshift SQL). Lưu ý:
- Prefix schema đúng: `analytics_workspace.<table>`.
- Token `{{whseid}}`, `{{date_from}}`, ... là Fluid template — phải replace thủ công khi chạy.

### Bước 3 — Verify schema với DDL

Khi không chắc cột:

```bash
curl ... --data-binary 'DESCRIBE analytics_workspace.<table> FORMAT PrettyNoEscapes'
```

Hoặc đọc snapshot offline (rất hữu ích vì có comment Vietnamese cho từng cột):
[`projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.md`](projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.md)

### Bước 4 — Metadata trước query chính

Bắt buộc chạy metadata trước. Nếu `max_date < ngày user hỏi` thì query chính sẽ ra 0 rows → biết trước để khỏi tốn thời gian.

```sql
SELECT
    min(toDate(<date_col>))         AS min_date,
    max(toDate(<date_col>))         AS max_date,
    count()                         AS total_rows,
    uniqExact(<key_col>)            AS distinct_keys
FROM analytics_workspace.<mv>
FORMAT JSONEachRow
```

Đồng thời check refresh status (chỉ cho refreshable MV):

```sql
SELECT database, view, status, last_refresh_time, last_refresh_error
FROM system.view_refreshes
WHERE database = 'analytics_workspace' AND view = '<mv>'
FORMAT JSONEachRow
```

### Bước 5 — Chạy queries chính song song

Khi có nhiều query độc lập, dùng `&` + `wait` (bash) hoặc `Start-Job` (PowerShell). Tận dụng concurrency của ClickHouse (mặc định ~100 query slot).

```bash
curl ... --data-binary 'SELECT ... -- query 1' > /tmp/q1.json &
curl ... --data-binary 'SELECT ... -- query 2' > /tmp/q2.json &
curl ... --data-binary 'SELECT ... -- query 3' > /tmp/q3.json &
wait
```

### Bước 6 — Sanity check trước khi xuất

| Check | Cách làm |
|---|---|
| Tổng có khớp không | `sum` của các bucket = `sum` không group |
| Outlier hợp lý | `quantiles(0.5, 0.95, 0.99)(metric)` — nếu p99 cách p95 vài bậc → check |
| NULL/empty rate | `countIf(col IS NULL OR col = '') / count()` |
| Cardinality của dimension | `uniqExact(dim)` — nếu =1 hoặc gần 1 thì group có ý nghĩa không? |
| MV vs raw | Spot-check 5 keys đối chiếu raw source và MV — nếu lệch >0.5% → cờ đỏ |

### Bước 7 — Xuất kết quả

Bắt buộc lưu vào:

```
projects/mondelez/02-data/audit-results/s2-{feature-slug}-{YYYYMMDD}.md
```

Theo template ở mục 6.

---

## 4.bis. Review SQL — quy trình bắt buộc khi user yêu cầu review câu SQL

Khi user nói "review câu SQL trong [stub / file / registry / ticket]", **KHÔNG chỉ check syntax + schema cột**. Phải so chiếu với **canonical convention của `sql-registry.md`** trước khi kết luận. Đây là lesson từ FEAT-128 audit (2026-05-12) — r3 audit verify schema/syntax OK nhưng bỏ qua registry convention → r4 phải rewrite toàn bộ.

### Bước 1 — Xác định scope

| SQL nằm ở đâu | Convention nguồn |
|---|---|
| Stub / triage / PRD draft | `sql-registry.md` + DDL `analytics_workspace_mvs.md` |
| Audit script (`projects/{tenant}/scripts/...`) | Tự do — không cần consistent với widget |
| Settings dialog của widget (user-paste) | **`sql-registry.md` (canonical) — bắt buộc** |
| Pulse note (`pulse-W*.md`) | Pulse có pattern phân tích riêng — **KHÔNG phải UI canonical** |

→ Nếu SQL sẽ chạy trên widget (paste vào settings dialog), **phải** check registry. Nếu chỉ ad-hoc analysis, skip Bước 2-3.

### Bước 2 — Lookup canonical pattern trong sql-registry

```
Grep "tên feature / chart / section" trong projects/{tenant}/02-data/data-sources/sql-registry.md
→ Đọc cả Redshift SQL VÀ ClickHouse SQL của section đó
→ Ghi structural pattern: CTE style, count function, date column, label convention, filter mechanism
```

**Registry có 2 patterns đồng tồn** — phải nhận diện đúng pattern của section gốc:

- **OLD pattern: CTE-with-params** — `WITH params AS (SELECT 'ALL' AS p_xxx) CROSS JOIN params`, filter `(p_xxx = 'ALL' OR t.xxx = p_xxx)`. Single-select only. Dùng trong §OTIF.
- **NEW pattern: arraySort placeholder** — `if(arraySort([{{x}}]) = (SELECT arraySort(groupArray(DISTINCT col)) FROM mv_filter_*), 1=1, col IN ({{x}}))`. Multi-select. Dùng trong §Stocktype, §Inventory.

→ Dùng đúng pattern theo section gốc. **Đừng "phát minh" pattern mới** hoặc trộn pattern audit (pulse) vào UI chart.

### Bước 3 — So sánh SQL candidate vs canonical theo 7 axes

| Axis | Phải check | Mức nghiêm trọng nếu mismatch |
|---|---|---|
| Parameter pattern | CTE-params hoặc `arraySort([{{x}}])` (theo section gốc) | MEDIUM — tự fixable |
| Aggregation function | `count(so)` vs `countDistinct(so)` (registry default = `count`) | LOW — equivalent nếu MV đã dedup |
| Conditional count | `countIf(...)` (CH) vs `COUNT(CASE WHEN...)` (RS) | LOW — chỉ là dialect |
| **Date filter column** | Cùng cột với các chart khác trong dashboard | ⚠️ **HIGH** — khác cột → chart hiển thị khác total → confusion cross-chart |
| NULL/blank dim label | Convention của registry (`'Unclassified'` / VN) | LOW — cosmetic |
| **Filter rule include/exclude** | Default theo registry — đổi phải có business justification | ⚠️ **HIGH** — đổi business meaning của metric |
| Multi-select support | Theo pattern section gốc (CTE = single, arraySort = multi) | MEDIUM — limitation cần document |

### Bước 4 — Distinguish "audit pattern" vs "UI chart pattern"

**KHÔNG được nhầm** 2 loại pattern này:

| Property | Pulse/audit pattern | UI canonical (registry) |
|---|---|---|
| Mục đích | Phân tích 1 thời điểm, có context cụ thể | Render real-time trên dashboard, cross-chart consistency |
| Aggregation | `countDistinct` (paranoid về dedup) | `count` (MV đã dedup, không cần) |
| Date column | Có thể chọn theo bài toán (`actual_ship_date`) | Đồng nhất với toàn dashboard (`eta_giao_hang_cho_npp` cho OTIF) |
| Filter format | Hardcoded values cho 1 lần chạy | `'ALL'` sentinel hoặc `{{placeholder}}` |
| Exclude no-STM (OTIF) | YES (measurable focus cho audit) | NO mặc định (registry); YES chỉ nếu PM/SC Manager explicit yêu cầu |

→ Khi reuse pulse SQL cho UI chart, **phải convert** sang canonical UI pattern. Verify với pulse là KHÔNG đủ — phải verify với registry.

### Bước 5 — Output review

Audit artifact (`s2-{feature}-{YYYYMMDD}.md`) phải bao gồm:
1. **Convention source declaration**: "So chiếu với `sql-registry.md §X` (lines Y-Z)" — explicit nguồn convention, KHÔNG chỉ "verified vs pulse".
2. **Convention match table**: 7 axes (Bước 3) + verdict mỗi axis (Match / Mismatch + severity).
3. **Bugs syntax** (như audit thường — schema cột, status literal, function compat).
4. **Bugs semantic** (xảy ra khi convention divergence mà người viết không biết — ví dụ date column khác → chart không match dashboard).
5. **Recommendation**: nếu có HIGH-severity divergence → đề xuất 3 options (A: theo canonical / B: giữ candidate / C: hybrid + business clarification). **KHÔNG tự quyết** — ask PM/BA qua `AskUserQuestion`.

### Bước 6 — Nếu user chọn rewrite theo canonical

Khi user accept rewrite, áp dụng convention nguyên vẹn từ registry. **Đặc biệt chú ý**:

- **Wireable cho widget runtime**: registry CTE pattern hardcode `'ALL'` literal trong `SELECT` — KHÔNG tự wire vào widget filter. Phải bọc bằng `coalesce({{name}}, 'ALL')`:
  ```sql
  WITH params AS (
      SELECT
          coalesce({{whseid}}, 'ALL')                              AS p_whseid,
          coalesce(toDate({{from_date}}), toDate('1900-01-01'))    AS p_tu_ngay,
          ...
  )
  ```
- **Multi-select limitation**: nếu section gốc dùng CTE pattern → toàn dashboard không multi-select. Nếu cần multi → phải refactor toàn bộ section sang `arraySort` pattern, KHÔNG refactor 1 chart đơn lẻ (sẽ inconsistent).

### Anti-patterns review SQL (tổng hợp)

| Sai | Hậu quả | Sửa |
|---|---|---|
| Chỉ check syntax + schema cột, bỏ qua convention | Chart hiển thị KHÁC 6 chart anh em cùng dashboard → confusion | Bước 2-3 bắt buộc |
| Verify với pulse SQL rồi tuyên bố "pattern khớp registry" | Pulse ≠ registry. Phải đối chiếu **trực tiếp** registry. | Bước 4 |
| Tuyên bố "High confidence" mà không declare nguồn convention | Mislead user, phải redo audit | Audit phải explicit "so chiếu với `sql-registry.md §X lines Y-Z`" |
| Auto-pick option khi có business divergence (exclude no-STM, ETA vs ATA) | Quyết định business mà không hỏi → có thể sai intent | Bước 5 — ask via `AskUserQuestion`, không assume |
| Đề xuất rewrite mà không bọc `coalesce({{x}}, 'ALL')` cho CTE constants | Widget filter KHÔNG wire vào → SQL chạy nhưng filter bị ignore | Bước 6 mandatory wireable wrapper |

---

## 5. Redshift → ClickHouse SQL — bảng dịch nhanh

Đây là nguồn lỗi #1 khi đọc `sql-registry.md` (registry có cả 2 dialect). Dịch theo bảng này:

| Redshift / Postgres | ClickHouse | Ghi chú |
|---|---|---|
| `'abc'::VARCHAR` | `'abc'` hoặc `CAST('abc' AS String)` | CH không có `::` syntax (có nhưng hạn chế) |
| `TIMESTAMP '2026-01-01 00:00:00'` | `toDateTime('2026-01-01 00:00:00')` | |
| `CAST(col AS DATE)` | `toDate(col)` | `CAST` với `Nullable` thường lỗi → ưu tiên `toDate` |
| `DATE_TRUNC('month', d)` | `toStartOfMonth(d)` | |
| `DATE_TRUNC('week', d)` | `toStartOfWeek(d, 1)` | Mode 1 = Monday-start, ISO |
| `DATE_TRUNC('day', d)` | `toStartOfDay(d)` hoặc `toDate(d)` | |
| `DATEDIFF('day', a, b)` | `dateDiff('day', a, b)` hoặc `b - a` | |
| `EXTRACT(YEAR FROM d)` | `toYear(d)` | |
| `NULLIF(a, 0)` | `nullIf(a, 0)` | |
| `COALESCE(a, b)` | `coalesce(a, b)` | OK cả 2 dialect |
| `COUNT(CASE WHEN c THEN x END)` | `countIf(c)` (đếm rows) hoặc `count(if(c, x, NULL))` | |
| `COUNT(DISTINCT CASE WHEN c THEN x END)` | `uniqExactIf(x, c)` (chính xác) hoặc `uniqCombinedIf(x, c)` (xấp xỉ) | |
| `CASE WHEN c1 THEN v1 WHEN c2 THEN v2 ELSE d END` | `multiIf(c1, v1, c2, v2, d)` | Ngắn hơn nhiều |
| `LISTAGG(col, ',')` | `arrayStringConcat(groupArray(col), ',')` | |
| `||` (concat) | `concat(a, b)` hoặc `a || b` (CH cũng hỗ trợ) | |
| `LIKE '%abc%'` | Như cũ, nhưng `position(col, 'abc') > 0` nhanh hơn | |
| `ILIKE` | `lower(col) LIKE lower('%abc%')` hoặc `positionCaseInsensitive` | CH không có `ILIKE` native |
| `regexp_substr(col, pat)` | `extract(col, pat)` | |
| `JSON_EXTRACT_PATH_TEXT(j, 'k')` | `JSONExtractString(j, 'k')` | |
| Window: `ROW_NUMBER() OVER (...)` | `rowNumberInAllBlocks()` (đơn giản) hoặc `row_number() OVER (...)` (đầy đủ) | |
| `LIMIT 10` | `LIMIT 10` (giống) — nhưng CH có `LIMIT 10 BY <key>` (top-N per group) | `LIMIT BY` cực mạnh, ít người biết |
| `WITH RECURSIVE` | Không hỗ trợ | Refactor sang `arrayMap`/loop ngoài SQL |

**Edge case hay đụng:**
- `CASE` của Redshift có thể trả mixed type — CH strict hơn, mọi nhánh phải cùng type → thêm `toFloat64()` nếu cần.
- `NULL = NULL` trong CH = `NULL` (giống chuẩn SQL) — dùng `isNull(x)` hoặc `x IS NULL`.

---

## 6. Template file kết quả audit (`s2-{feature}-{YYYYMMDD}.md`)

```markdown
# S2 — Pipeline Audit: {Tên feature}

**Date:** YYYY-MM-DD
**Auditor:** {tên / agent}
**Source MV:** `analytics_workspace.{mv_name}`
**SQL Registry section:** [`sql-registry.md` § {tên section}](../data-sources/sql-registry.md#...)
**ClickHouse server:** {host} (Cloud, ap-southeast-1)
**MV refresh policy:** {REFRESH EVERY X từ DDL} — caveat: dữ liệu trễ tối đa X

---

## 1. Metadata MV

| Thuộc tính | Giá trị |
|---|---|
| Total rows | {N} |
| Date range | YYYY-MM-DD → YYYY-MM-DD |
| Distinct {key} | {N} |
| Last refresh | YYYY-MM-DD HH:MM:SS UTC |
| Last refresh status | OK / Failed (chi tiết) |
| Storage size | {MB / GB} |

---

## 2. Kết quả truy vấn

### 2.1 {Query 1 title} — {bộ lọc / kỳ}
{bảng kết quả PrettyNoEscapes hoặc table markdown}

### 2.2 {Query 2 title}
{bảng kết quả}

---

## 3. Sanity checks

| Check | Kết quả | Pass/Fail |
|---|---|---|
| Sum group = Sum total | … | ✅ / ❌ |
| Outlier (p99 vs p95) | … | … |
| NULL rate cột chính | … | … |
| Cardinality dim chính | … | … |

---

## 4. Bug / Discrepancy phát hiện

### BUG-1 ({CRITICAL/HIGH/MEDIUM/LOW}): {tiêu đề}
- **Vị trí:** sql-registry.md § "…" / DDL của MV `…`
- **Triệu chứng:** {số liệu cụ thể, repro bằng query nào}
- **Root cause (giả thuyết):** …
- **Impact business:** {ai bị ảnh hưởng, số liệu nào sai}
- **Recommendation:** …

---

## 5. Query đã verify (ClickHouse SQL chuẩn)

```sql
-- {comment business}
SELECT ...
```

---

## 6. Caveats

- {MV refresh trễ X giờ → số liệu này là snapshot lúc Y}
- {Cross-tenant không khả dụng vì …}
- {Cột Z hiện đang Nullable → đếm có thể lệch nếu data có NULL}

---

## ARTIFACT_PATH: projects/mondelez/02-data/audit-results/s2-{feature}-{YYYYMMDD}.md
## DATA_CONFIDENCE: High | Medium | Low (lý do)
## NEXT_ACTION: {/da-data để định nghĩa metric chính thức / báo team pipeline / fix registry / …}
```

---

## 7. Lỗi thường gặp & cách fix

| Lỗi | Nguyên nhân | Fix |
|---|---|---|
| `UNKNOWN_IDENTIFIER: t.channel` | Tên cột registry dùng schema Redshift, không match MV ClickHouse | Mở DDL snapshot, dùng đúng tên cột MV |
| `CANNOT_INSERT_NULL_IN_ORDINARY_COLUMN` | `CAST(Nullable AS DATE)` ép NULL vào cột non-null | Thay bằng `toDate(col)` (an toàn với NULL) hoặc `toDateOrNull(col)` |
| `ILLEGAL_AGGREGATION` | Alias trùng tên cột gốc trong cùng SELECT | Prefix table `t.col` rõ ràng, hoặc đổi alias |
| `Syntax error: Single quoted string is not closed` | Shell escape lỗi (đặc biệt PowerShell) | Dùng heredoc `<<'SQL'` hoặc lưu SQL ra file rồi `--data-binary @file.sql` |
| Query trả 0 rows | Date range ngoài data MV | Luôn chạy metadata trước (Bước 4) |
| `MEMORY_LIMIT_EXCEEDED` | JOIN bảng lớn bên phải, hoặc `GROUP BY` cardinality cực cao | Đặt bảng nhỏ bên phải, hoặc dùng `uniqCombined` thay `uniqExact`, hoặc thêm `WHERE` filter trước JOIN |
| `Too many parts (N). Merges are processing significantly slower than inserts` | Insert từng dòng | Batch insert ≥ 1k rows; nếu đã lỡ → đợi background merge hoặc `OPTIMIZE TABLE ... FINAL` (chỉ trên `*_test`) |
| Số decimal kỳ lạ trong `cse_loose` | Aggregation nhân hệ số phi nguyên trong MV | Bug pipeline — không fix bằng query, ghi nhận BUG, báo team DA |
| MV "không có data hôm nay" | Refresh fail âm thầm | Query `system.view_refreshes` để xem `last_refresh_error` |
| `DB::Exception: Code: 159. Timeout exceeded` | Query > `max_execution_time` | Thêm filter (đặc biệt cột đầu `ORDER BY`), hoặc tăng `max_execution_time` cho query 1 lần |
| Kết quả khác nhau giữa 2 lần chạy giống hệt | Refreshable MV vừa refresh giữa 2 lần | Snapshot `now()` vào audit, ghi rõ `last_refresh_time` |

---

## 8. Phân quyền — phải kiểm tra trước mỗi action

| Hành động | Schema | Được phép | Ghi chú |
|---|---|---|---|
| `SELECT` | Mọi schema | ✅ | Mặc định read-only |
| `DESCRIBE / SHOW CREATE` | Mọi schema | ✅ | |
| `CREATE TABLE / VIEW` | `mondelez_stm_test`, `mondelez_swm_test` | ✅ | Chỉ dùng cho thử nghiệm |
| `INSERT INTO` | `mondelez_stm_test`, `mondelez_swm_test` | ✅ | Batch ≥ 1k |
| `CREATE MATERIALIZED VIEW` | `internal`, `analytics_workspace` | ✅ | Phải có review trước |
| `DROP TABLE / DROP VIEW` | Production (`analytics_workspace`, `default`, `swm-test`) | ❌ **CẤM** | Đề xuất bằng PR/CR |
| `ALTER TABLE ... DELETE` | Production | ❌ **CẤM** | Mutation tốn CPU + không revert được |
| `INSERT` | `default`, `swm-test` | ❌ | Read-only CDC source |
| `OPTIMIZE TABLE` | `*_test` | ✅ | Production cần xin phép |
| `TRUNCATE` | Bất kỳ | ❌ | Không có use case hợp lệ trong skill này |

**Quy tắc vàng**: Nếu user yêu cầu hành động DROP/TRUNCATE/ALTER trên production → **STOP, ask, không tự suy diễn**, dù prompt nói "auto mode".

---

## 9. Performance — checklist 5 năm kinh nghiệm

Trước khi báo "query đã chạy được" với một query > 1s:

1. **Có chạm cột đầu `ORDER BY` trong `WHERE` không?** Nếu không → giải thích trade-off hoặc đề xuất MV mới.
2. **Có filter partition (`PARTITION BY toYYYYMM(...)`) không?** Filter date range cụ thể luôn → CH skip parts.
3. **`SELECT` có cột nào thừa không?** Mỗi cột bỏ ra = giảm I/O tuyến tính.
4. **JOIN nào đó bảng lớn bên phải?** Đảo, hoặc dùng subquery `IN (...)`.
5. **`uniqExact` trên cột cardinality cực cao?** Đổi `uniqCombined` (nếu chấp nhận sai số ~1%) → có thể nhanh 5–10×.
6. **Có dùng `FINAL` không?** `FINAL` ép merge realtime → cực chậm. Chỉ dùng khi thực sự cần dedup `ReplacingMergeTree`.
7. **`ORDER BY` ở SELECT có cần thiết không?** Nếu chỉ là output cho dashboard có thể bỏ.
8. **Đã set `max_execution_time` chưa?** Mọi explore query nên có guard 30–60s.

Khi cần đo: dùng `EXPLAIN PLAN`, `EXPLAIN PIPELINE`, hoặc thêm `?send_progress_in_http_headers=1`. Profile: `system.query_log` (có cột `read_rows`, `read_bytes`, `memory_usage`).

```sql
SELECT query_id, query, read_rows, formatReadableSize(read_bytes), memory_usage, query_duration_ms
FROM system.query_log
WHERE event_time > now() - INTERVAL 10 MINUTE AND user = 'helix' AND type = 'QueryFinish'
ORDER BY query_duration_ms DESC LIMIT 20
FORMAT PrettyNoEscapes
```

---

## 10. Khi nào KHÔNG dùng skill này

- Định nghĩa metric/KPI ở tầng business → `/da-data` (skill này chỉ thực thi SQL, không quyết định metric đúng/sai về business)
- Code widget React đọc dữ liệu CH → `/frontend`
- Tạo entity domain / migration backend → `/backend`
- Viết PRD cho feature data mới → `/ba` (sau khi `/da-ch` xong audit)
- Triage bug list từ khách hàng → `/da-triage` rồi route sang `/da-ch` cho bug ETL/data
- Audit trace UI vs PRD vs i18n → `/da-trace`

---

## 11. Anti-patterns (5 năm — đã thấy nhiều)

| Sai | Tại sao | Sửa |
|---|---|---|
| `SELECT *` rồi filter ở client | Tốn I/O và bandwidth, có thể hit memory limit | Project chỉ cột cần |
| Copy Redshift SQL từ registry, dán nguyên vào CH | `CAST(... AS DATE)`, `DATE_TRUNC`, `LISTAGG` đều không tương thích | Dịch theo bảng mục 5 trước khi chạy |
| Dùng `Nullable` trong DDL test | Cột Nullable chậm + tốn dung lượng | Default sentinel, hoặc nếu cần Nullable thì có lý do rõ |
| Insert vòng lặp từng row vào `*_test` | Tạo nhiều parts → "Too many parts" | Batch ≥ 1k, hoặc `INSERT ... SELECT` |
| `OPTIMIZE TABLE ... FINAL` trên production | Block merge, ngốn IO | KHÔNG. Chỉ trên `*_test` khi thực cần |
| JOIN 4 bảng raw để build metric | Trùng với MV có sẵn 90% trường hợp | Mở DDL, tìm MV phù hợp trước |
| Không ghi `last_refresh_time` vào audit | Số liệu lúc audit ≠ lúc người đọc kiểm chứng | Snapshot timestamp + refresh status |
| Dùng `uniqExact` trên 100M rows cho dashboard | Chính xác nhưng chậm — UX dashboard chấp nhận xấp xỉ | `uniqCombined` hoặc `uniqHLL12` |
| Báo cáo "fixed" mà không re-run query verify | Có thể fix sai chỗ | Sau fix → chạy lại query và đính kết quả vào audit file |
| Lưu password ClickHouse vào audit `.md` | Leak credential | Reference `.env`, không bao giờ in raw password |

---

## 12. Nguồn chân lý — đọc trước khi debug

| Nguồn | File | Dùng khi |
|---|---|---|
| **SQL Registry** | [`projects/mondelez/02-data/data-sources/sql-registry.md`](projects/mondelez/02-data/data-sources/sql-registry.md) | Tra SQL gốc theo Chart/Feature |
| **DDL Snapshot (md)** | [`projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.md`](projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.md) | Đọc schema, comment cột, audit MV |
| **DDL Snapshot (sql)** | [`projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql`](projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql) | Copy DDL để tạo lại / migrate |
| **STM datawarehouse** | [`projects/mondelez/02-data/data-sources/stm-datawarehouse.md`](projects/mondelez/02-data/data-sources/stm-datawarehouse.md) | Hiểu schema STM gốc trước MV |
| **SWM datawarehouse** | [`projects/mondelez/02-data/data-sources/swm-datawarehouse.md`](projects/mondelez/02-data/data-sources/swm-datawarehouse.md) | Hiểu schema SWM gốc trước MV |
| **Glossary** | [`projects/mondelez/02-data/glossary.md`](projects/mondelez/02-data/glossary.md) | Tra term Vietnamese ↔ kỹ thuật |

Cập nhật snapshot:

```bash
# Refresh SQL Registry từ Google Sheet
python projects/mondelez/scripts/fetch_sql_registry.py

# Refresh DDL từ ClickHouse server
python projects/mondelez/scripts/export_clickhouse_ddl.py
```

---

## 13. Mandatory ending signals

Mỗi lần kết thúc một audit/analysis bằng `/da-ch`, output phải có:

- `ARTIFACT_PATH`: file audit đã tạo/cập nhật (đường dẫn tuyệt đối từ repo root)
- `DATA_CONFIDENCE`: High | Medium | Low (kèm lý do nếu không High — vd "MV refresh fail 2h trước", "cross-tenant data lệch 0.3%")
- `MV_FRESHNESS`: timestamp `last_refresh_time` của MV chính (hoặc "N/A — bảng raw")
- `NEXT_ACTION`: handoff cụ thể — `/da-data` để định nghĩa metric, `/ba` để mở PRD bug, `team pipeline` để fix MV refresh, hoặc `done` nếu không cần thêm

---

## Pre-Ship — Clean Code Reference

SQL viết bằng `/da-ch` thường đi tiếp vào widget code hoặc commit vào `projects/{tenant}/02-data/data-sources/sql-registry.md`. Lúc đó SQL = code đi production → bắt buộc qua rubric Clean Code: **[`.claude/skills/da-ship/references/clean-code.md`](.claude/skills/da-ship/references/clean-code.md)**.

Trục bắt buộc kiểm cho SQL ClickHouse:
- **#1 Naming** — mọi CTE phải đặt tên nghiệp vụ (`orders_delivered_ontime`, không `t1`); column output phải khớp glossary/registry
- **#2 Single Purpose** — 1 CTE = 1 phép biến đổi; tránh CTE 80 dòng nhồi filter + join + window
- **#3 DRY** — đối chiếu canonical pattern trong `sql-registry.md` trước khi viết mới (xem `feedback_sql_review_must_check_registry` memory)
- **#5 Boundaries** — multi-select expansion qua `WidgetFilterResolver`, timezone UTC↔UTC+7, NULL handling

Final gate trước commit: chạy **`/da-ship`** — đó là chốt chặn cuối, kiểm cả 4 gate (Scope / Clean Code / Verification / Traceability) trước khi đẩy sang Dev review.
