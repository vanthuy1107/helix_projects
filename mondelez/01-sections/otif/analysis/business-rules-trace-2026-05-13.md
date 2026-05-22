# OTIF / OT / IF — Rule Trace (Mondelez)

| Trường | Giá trị |
|---|---|
| **Ngày** | 2026-05-13 |
| **Tác giả** | PM/DA (via `/da-biz-ba`) |
| **Audience** | PM, BA, Ops Manager Mondelez, dev squad refactor |
| **Câu hỏi gốc** | "Các rule xác định OTIF / OT / IF đang dựa vào rule nào?" |
| **Scope** | Tenant **Mondelez** — widget `WidgetOtif` + section `01-sections/otif` |
| **Tenant scope khác** | Rule này **chỉ áp Mondelez** — các tenant khác chưa có mv_otif tương đương |

---

## TL;DR

**Rule xác định OT / IF / OTIF KHÔNG được tính trong runtime của repo này.** Nó được tính **upstream trong ClickHouse MV `analytics_workspace.mv_otif`** (Mondelez data warehouse, Stack B), và widget chỉ **đọc 3 cột pre-computed**: `ontime_status`, `infull_status`, `otif_status`.

**Source of truth duy nhất** = [`projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql` line 3803-3805](../../../02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql#L3803-L3805) (DDL snapshot của MV).

Mọi tài liệu khác (PRD §3, glossary `02-kpis.md`, sql-registry widget queries) chỉ là **mô tả / consumer** — không phải nơi tính rule. Có **3 điểm lệch** giữa documentation và DDL cần làm rõ — xem §4.

---

## 1. Chuỗi nguồn (where the rule actually lives)

```
[Source data: STM + SWM operational systems]
       ↓
[mv_otif_swm_data]  + [mv_otif_stm_data]   (raw join sources, refresh 1h)
       ↓
[mv_otif_swm_stm_data]                     (joined SWM × STM, refresh 1h)
       ↓
[mv_otif]   ◄─── RULE TÍNH OT/IF/OTIF Ở ĐÂY (DDL line 3803-3805)
       ↓ pre-computed columns
[Widget SQL queries — sql-registry.md §OTIF]
   `countIf(ontime_status = 'Ontime')`
   `countIf(infull_status = 'Infull')`
   `countIf(otif_status   = 'OTIF')`
       ↓
[Frontend `widget-otif.tsx`]
   chỉ render `pct_ontime` / `pct_infull` / `pct_otif` từ API
   → KHÔNG re-compute rule
```

**Hệ quả:** Nếu business muốn thay đổi định nghĩa OT/IF/OTIF → phải **redeploy ClickHouse MV `mv_otif`**, không sửa code FE/BE được.

---

## 2. Rule chính xác (trích DDL — Observed)

> Nguồn: [`analytics-workspace_mvs.sql:3803-3805`](../../../02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql#L3803-L3805)

### 2.1 `ontime_status`

```sql
multiIf(
  p.`ETA (Giao hàng cho NPP)` <  p.`ATA đến`, 'Failed Ontime',
  p.`ETA (Giao hàng cho NPP)` >= p.`ATA đến`, 'Ontime',
  coalesce(s.has_stm_order, 0) = 0,          'Không có dữ liệu STM',
  /* else */                                  'Ontime'
) AS ontime_status
```

Bằng ngôn ngữ business:

> **BR-OTIF-001 — Ontime**
> Một đơn được xem là **Ontime** khi `ATA đến ≤ ETA giao hàng cho NPP`. Khi ATA > ETA → `Failed Ontime`. Khi đơn không có dữ liệu STM (chưa khớp với hệ thống STM) → đánh dấu sentinel `Không có dữ liệu STM`. Khi cả ETA và ATA cùng null → fallback **Ontime** (default tích cực — xem §4 Flag-1).

### 2.2 `infull_status`

```sql
multiIf(
  (s.sum_original_cse > s.sum_shipped_cse)
  OR (s.sum_shipped_cse > s.sum_giao_cse),                    'Failed Infull',
  (s.sum_original_cse  = s.sum_shipped_cse)
  AND (s.sum_shipped_cse = s.sum_giao_cse),                    'Infull',
  coalesce(s.has_stm_order, 0) = 0,                            'Không có dữ liệu STM',
  /* else */                                                    'Infull'
) AS infull_status
```

> **BR-OTIF-002 — Infull**
> Một đơn được xem là **Infull** khi `sum_original_cse = sum_shipped_cse = sum_giao_cse` (kế hoạch = xuất kho = giao thực tế, đơn vị **case**). Khi bất kỳ chuỗi giảm dần này bị phá (kế hoạch > xuất kho HOẶC xuất kho > giao) → `Failed Infull`. Không có STM → sentinel. Fallback **Infull** (default tích cực — xem §4 Flag-1).

### 2.3 `otif_status`

```sql
multiIf(
  (ontime_logic = 1) AND (infull_logic = 1),  'OTIF',
  coalesce(s.has_stm_order, 0) = 0,            'Không có dữ liệu STM',
  /* else */                                   'Failed OTIF'
) AS otif_status
```

(Trong DDL `ontime_logic`/`infull_logic` được inline lặp lại — không tham chiếu lại `ontime_status` column. Logic giống §2.1 / §2.2 nhưng dùng tristate 0/1/NULL thay vì string.)

> **BR-OTIF-003 — OTIF**
> Một đơn được xem là **OTIF** khi vừa **Ontime** (BR-001) **vừa Infull** (BR-002). Mọi trường hợp khác (kể cả khi 1 trong 2 metric bị Failed) → `Failed OTIF`. Không có STM → sentinel `Không có dữ liệu STM`.

---

## 3. Phân loại nguyên nhân fail (cũng nằm trong DDL, không phải FE)

> Nguồn: [`analytics-workspace_mvs.sql:3808-3815`](../../../02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql#L3808-L3815)

### 3.1 `not_infull_reason` (3 bucket)

| Bucket | Điều kiện |
|---|---|
| Warehouse Infull Failure | `sum_original_cse > sum_shipped_cse` (lỗi xuất kho thiếu so với kế hoạch) |
| Transport Infull Failure | `sum_shipped_cse > sum_giao_cse` (lỗi vận tải rớt hàng giữa kho và điểm giao) |
| Warehouse + Transport Infull Failure | Cả 2 điều kiện trên cùng đúng |

### 3.2 `not_ontime_reason` (5 bucket, dạng concatenated string)

Logic timestamp-based (DDL line 3809 — concatenated regex), trích các nguyên nhân:

| Bucket | Phát sinh khi |
|---|---|
| Late arrival by Transport | `Giờ gọi xe < ETD < Giờ vào cổng`, hoặc `ETD < Giờ đăng tài` |
| Late warehouse call by Warehouse | `Giờ đăng tài < ETD AND Giờ gọi xe > ETD` |
| Late pickup by Warehouse | `ETD > Giờ vào cổng AND Actual Ship Date > TG bắt buộc rời kho − 10 min` |
| Late departure by Transport | `Late pickup KHÔNG xảy ra` nhưng `TG bắt buộc rời kho < Giờ ra cổng` |
| Late delivery by Transport | Tất cả timestamps OK NHƯNG `ETA < ATA đến` |

**Chỉ tính khi đơn đã Failed Ontime** (`if(p.ETA < p.ATA, ..., NULL)`). Đơn Ontime → `not_ontime_reason = NULL`.

> **BR-OTIF-004 — Nguyên nhân Failed Ontime**
> Khi một đơn Failed Ontime, hệ thống tự gán 1 hoặc nhiều bucket trong 5 loại trên dựa vào sequence timestamps thực tế của chuyến. Nhiều bucket có thể cùng phát sinh trên 1 đơn (concatenated bằng `\r\n\r\n`).

---

## 4. Mâu thuẫn / điểm chưa rõ giữa docs và DDL

| # | Vấn đề | Hiện trạng docs | DDL thực tế | Risk | Owner xử lý |
|---|---|---|---|---|---|
| **Flag-1** | NULL fallback của Ontime/Infull = **success** | PRD §3, glossary `02-kpis.md` mô tả Ontime ⇔ ATA ≤ ETA, không nhắc fallback | DDL fallback cuối cùng = `'Ontime'` / `'Infull'` khi all branch fail (vd ETA hoặc ATA NULL) — **gán nhãn thành công cho dữ liệu thiếu** | **High** — inflate Ontime/Infull% giả tạo khi STM/SWM data có gap | Data team Mondelez confirm: đây là intent hay bug? Có nên đổi thành 'Không xác định'? |
| **Flag-2** | Đặt tên cột CSE khác nhau giữa docs và DDL | Glossary + PRD: `planned_cse / shipped_cse / delivered_cse` | DDL: `sum_original_cse / sum_shipped_cse / sum_giao_cse` | Low (semantic giống) | Doc team — update glossary để dùng tên thật của MV, hoặc thêm aliasing note |
| **Flag-3** | Rounding khi so sánh CSE | Glossary `02-kpis.md:22` ghi `"sau khi round(toFloat64(x), 4) để tránh false-positive precision"` | DDL **không có** round — so sánh trực tiếp `>` `=` trên kiểu gốc | Medium — nếu CSE là Decimal/Float thì có thể có precision drift; nếu là Int thì glossary thừa | Data team confirm: kiểu data thực tế của `sum_original_cse` là gì, có cần round? |
| **Flag-4** | PRD §3 ghi rule "extracted from widget code (`widget-otif.tsx`, `classifyReason()`, `classifyInfullBucket()`)" | PRD nói FE có `classifyReason()` và `classifyInfullBucket()` | Grep FE: **không có 2 hàm này** — FE chỉ đọc `notOntimeReason` / `notInfullReason` strings từ MV (line 465-466 widget-otif.tsx) | Low — chỉ là docs lag | BA — update PRD §3 để chỉ DDL là nguồn, FE chỉ là consumer |
| **Flag-5** | Loại trừ sentinel | Plan `widget-otif-chart-reorder-and-category/dev/plan.md` ghi: "Business rule: exclude `otif_status = 'Không có dữ liệu STM'`" | DDL có tạo sentinel nhưng **widget SQL trong sql-registry KHÔNG filter sentinel** (vd line 18068 `countIf(otif_status = 'OTIF')` — sentinel rơi vào mẫu số `count(so)`) | **High** — `% OTIF` bị **kéo xuống** bởi đơn không có STM data → metric sai tỷ lệ thực | DA/Dev team — confirm: có nên thêm `WHERE otif_status <> 'Không có dữ liệu STM'` vào CTE `filtered_data`? |
| **Flag-6** | Asymmetry sentinel: OT/IF gán 'Ontime'/'Infull', còn OTIF gán 'Failed OTIF' | DDL fallback cuối của OT/IF = success, OTIF = fail | Inconsistent semantic | Medium — `% Ontime` và `% Infull` đếm đơn-không-STM là pass, `% OTIF` đếm đơn-không-STM là fail → 3 metric không nhất quán cùng denominator | Data team Mondelez — decide intended semantic |

---

## 5. Tổng kết: rule chain (1 câu mỗi tầng)

| Tầng | Vai trò | File |
|---|---|---|
| **L1 — Source ops data** | STM + SWM raw orders/shipments | (Mondelez warehouse, không có trong repo) |
| **L2 — `mv_otif_swm_stm_data`** | Join SWM × STM theo SO + line | `clickhouse-ddl/analytics-workspace_mvs.sql:3992+` |
| **L3 — `mv_otif`** | **TÍNH rule OT/IF/OTIF** + nguyên nhân fail (`multiIf`) | `clickhouse-ddl/analytics-workspace_mvs.sql:3628-3819` |
| **L4 — Widget SQL** | `countIf(... = 'Ontime')` / `'Infull'` / `'OTIF'` + filter + groupby | `02-data/data-sources/sql-registry.md §OTIF` |
| **L5 — `widget-otif.tsx`** | Render `pct_*` đã được L4 tính; **không re-compute rule** | `frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx` |
| **L6 — PRD §3 + glossary** | Tài liệu hoá định nghĩa cho business | `01-sections/otif/prd.md §3` + `glossary/02-kpis.md` |
| **L7 — Targets + RAG** | Target % và RAG band — **không** thay đổi rule định nghĩa, chỉ định nghĩa "đạt hay không đạt" | `01-sections/otif/prd.md §13.2` + `docs/shared/business-rules.md` |

---

## 6. Đề xuất hành động

### 6.1 Cần customer/Data team Mondelez confirm (blocker khi metric bị challenge)

1. **Flag-1 — NULL fallback semantic**: ETA hoặc ATA NULL hiện default = 'Ontime'. Đây là intent (business "innocent until proven guilty") hay là bug data? → Nếu là bug, propose value mới `'Không xác định'` và tách khỏi cả tử số lẫn mẫu số.
2. **Flag-5 — Sentinel exclusion**: SQL trong sql-registry **KHÔNG** filter `'Không có dữ liệu STM'` trước khi `countIf`. Plan feature-128 nói cần filter. Quyết định: filter ở MV (loại sentinel hẳn) hay filter ở widget SQL (giữ trong MV để debug)?
3. **Flag-6 — Sentinel asymmetry**: Có nên thay đổi DDL để OT/IF cũng đẩy sentinel ra ngoài giống OTIF (đối xứng denominators)?

### 6.2 Cần BA/Doc team cập nhật (low risk, do drift docs)

4. **Flag-2 + Flag-3 + Flag-4**: Update `glossary/02-kpis.md` và `01-sections/otif/prd.md §3`:
   - Đổi `planned_cse / shipped_cse / delivered_cse` → tên thật `sum_original_cse / sum_shipped_cse / sum_giao_cse` (hoặc thêm alias mapping table)
   - Xoá hoặc xác minh `round(toFloat64(x), 4)` — không có trong DDL hiện tại
   - Xoá tham chiếu `classifyReason()` / `classifyInfullBucket()` — 2 hàm này không tồn tại; rule sống trong DDL

### 6.3 Trace truy ngược

5. Tạo entry trong `glossary/99-discrepancies.md` cho 6 flag ở §4 để theo dõi cho tới khi closed.

---

## 7. Liên hệ artifact khác

- **PRD section OTIF**: [`prd.md`](../prd.md)
- **DDL nguồn**: [`clickhouse-ddl/analytics-workspace_mvs.sql:3628-3819`](../../../02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql#L3628-L3819)
- **SQL registry consumer**: [`sql-registry.md` §OTIF](../../../02-data/data-sources/sql-registry.md)
- **Glossary KPI**: [`glossary/02-kpis.md`](../../../glossary/02-kpis.md)
- **Glossary data layer**: [`glossary/06-data-layer.md`](../../../glossary/06-data-layer.md)
- **Business rule chung (target + RAG)**: [`docs/shared/business-rules.md`](../../../../../docs/shared/business-rules.md)
- **Audit feat-128**: [`02-data/audit-results/s2-feat128-otif-chart-by-category-20260512.md`](../../../02-data/audit-results/s2-feat128-otif-chart-by-category-20260512.md)

---

ARTIFACT_PATH: `projects/mondelez/01-sections/otif/analysis/business-rules-trace-2026-05-13.md`

EVIDENCE_GAPS:
- Flag-1: NULL ETA/ATA fallback = 'Ontime' / 'Infull' — chưa có business confirmation đây là intent hay bug. (Assumed: nhiều khả năng là bug; cần Data team Mondelez confirm.)
- Flag-3: `round(toFloat64(x), 4)` trong glossary `02-kpis.md` không có nguồn trong DDL — chưa rõ là legacy doc hay rule đã removed. (Assumed: legacy.)
- Flag-5: Sentinel `'Không có dữ liệu STM'` có rơi vào mẫu số `count(so)` của widget không — đã kiểm tra qua sql-registry nhưng chưa có production data sample để xác nhận tỷ lệ ảnh hưởng.
- Flag-6: Asymmetry semantic sentinel — chưa biết là intent hay miss trong DDL design.

HANDOFF_TO:
- `/da-ch` — confirm DDL behavior cho Flag-1, Flag-3, Flag-5 (chạy ad-hoc query trên ClickHouse production)
- `/ba` — sau khi Data team confirm các flag → update PRD §3 + glossary
- `/da-pm` — đưa Flag-1 + Flag-5 (High risk) vào sprint backlog nếu cần fix
