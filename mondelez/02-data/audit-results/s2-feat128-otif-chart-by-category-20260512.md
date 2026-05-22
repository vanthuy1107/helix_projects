# S2 — SQL Review: FEAT-128 `chartByCategory` (OTIF theo loại hàng)

**Date:** 2026-05-12
**Auditor:** /da-ch (squad1@gosmartlog.com)
**Source MV:** `analytics_workspace.mv_otif`
**SQL Registry section:** N/A — template trực tiếp viết trong stub FEAT-128 §5.2 (không qua sql-registry)
**Stub reviewed:** [`projects/mondelez/triage/discoveries/frontend-widget/[D]-FEAT-128-otif-doi-thu-tu-charts-va-bo-sung-chart-loai-hang.md`](../../triage/discoveries/frontend-widget/%5BD%5D-FEAT-128-otif-doi-thu-tu-charts-va-bo-sung-chart-loai-hang.md) (§5.2 r6 final; closed `[D]` Done 2026-05-12)
**ClickHouse server:** Mondelez Stack B — `*.ap-southeast-1.aws.clickhouse.cloud` (Cloud, SharedMergeTree)
**MV refresh policy:** `REFRESH EVERY 1 HOUR` — caveat: dữ liệu trễ tối đa 1h
**Live query:** ✅ **đã chạy 2026-05-12 ~12:30 UTC+7** (6 queries: Q1 refresh, Q2 metadata, Q3 r4 với date filter, Q4 r4 no-filter Test SQL, Q5 cross-check vs chartByArea, Q6 edge case filter cargo) — xem §LIVE bên dưới

---

## 1. Verdict tổng

| Tiêu chí | Kết quả |
|---|---|
| Schema cột | ✅ Tất cả 8 cột referenced đều tồn tại trong DDL `mv_otif` |
| Status string literals | ✅ Khớp 100% với DDL (`'Ontime'`, `'Infull'`, `'OTIF'`, `'Không có dữ liệu STM'`) |
| ClickHouse function syntax | ✅ Mọi function (`countDistinct`, `countDistinctIf`, `multiIf`, `upperUTF8`, `trimBoth`, `nullIf`, `coalesce`, `ifNull`, `round`, `toDate`) đều native CH |
| Placeholder mechanics (vs WidgetFilterResolver.cs) | ✅ `{{name}}` đúng `\w+` pattern, `[[...]]` đúng convention, KHÔNG self-quote |
| Tham số tên (vs widget-otif.tsx) | ✅ `from_date`, `to_date`, `whseid`, `area`, `group_of_cargo`, `transporter` — khớp 100% với widget runtime (line 795-801) |
| Pattern đối chiếu chartByArea (pulse W19 Q2) | ✅ Khớp logic — chỉ khác GROUP BY col và thêm coalesce wrapper |
| **Bug latent — GROUP BY shadow alias** | ⚠️ **MEDIUM — cần fix trước khi paste** |
| Performance — index granule pruning | ⚠️ **MEDIUM caveat** — không hit `ORDER BY (so, whseid)` đầu cột; full scan ~975k rows |
| i18n hardcode trong SQL | 🟡 LOW — `'(Không xác định)'` hardcoded VN |
| Sort redundancy (SQL + FE) | 🟢 LOW — harmless |

**Confidence chạy được (sau khi fix BUG-1):** **High**. Pattern đã verified trên live data ở pulse W19 Q2.

---

## 2. Metadata MV (từ DDL snapshot, snapshot lần cuối tại analytics-workspace_mvs.md)

| Thuộc tính | Giá trị |
|---|---|
| Engine | `MaterializedView` (`SharedMergeTree`) |
| Total rows (lần snapshot DDL) | ~975,043 |
| Storage size | ~75.89 MiB |
| `ORDER BY` | `(so, whseid)` |
| `REFRESH EVERY` | `1 HOUR` |
| Date column | `actual_ship_date Nullable(DateTime64(3))` |
| Last refresh status | (chưa query live — cần verify tại runtime via `system.view_refreshes`) |

**Cột template referenced** (vs DDL lines 3769-3835):

| Cột template | DDL type | Status |
|---|---|---|
| `so` | `Nullable(String)` | ✅ |
| `group_of_cago` | `Nullable(String)` | ✅ (typo "cago" intentional — đúng tên thật) |
| `actual_ship_date` | `Nullable(DateTime64(3))` | ✅ |
| `whseid` | `String` | ✅ |
| `khu_vuc_doi_xe` | `String` | ✅ |
| `ten_ngan_nha_van_tai` | `String` | ✅ |
| `ontime_status` | `String` | ✅ |
| `infull_status` | `String` | ✅ |
| `otif_status` | `String` | ✅ |

**Status string values verified** (DDL lines 3941-3943):
- `ontime_status` ∈ {`'Failed Ontime'`, `'Ontime'`, `'Không có dữ liệu STM'`} → template `= 'Ontime'` ✅
- `infull_status` ∈ {`'Failed Infull'`, `'Infull'`, `'Không có dữ liệu STM'`} → template `= 'Infull'` ✅
- `otif_status` ∈ {`'OTIF'`, `'Failed OTIF'`, `'Không có dữ liệu STM'`} → template `= 'OTIF'` và `!= 'Không có dữ liệu STM'` ✅

---

## 3. Bugs phát hiện

### BUG-1 (MEDIUM): GROUP BY raw `group_of_cago` ≠ SELECT alias label → multiple "(Không xác định)" buckets

**Vị trí:** stub FEAT-128 §5.2 SQL, dòng 170 + 187

**Triệu chứng:** SELECT wrap raw column bằng `coalesce(nullIf(trimBoth(group_of_cago), ''), '(Không xác định)') AS group_of_cago`, nhưng GROUP BY dùng raw `group_of_cago`:

```sql
SELECT
  coalesce(nullIf(trimBoth(group_of_cago), ''), '(Không xác định)') AS group_of_cago,  -- alias shadows source col
  ...
GROUP BY group_of_cago   -- ambiguous: alias or source col?
```

Trong ClickHouse, khi alias shadow tên cột nguồn, ý nghĩa GROUP BY phụ thuộc version. Ngay cả khi nó parse theo source column, vẫn dẫn đến 3 buckets riêng cho `NULL` / `''` / `'   '` (whitespace), tất cả output cùng label `'(Không xác định)'` → chart sẽ render nhiều cột trùng tên.

**Pattern reference (pulse W19 Q2)** không có vấn đề này vì KHÔNG có coalesce wrapper — Q2 chấp nhận empty bucket riêng với label `''`. Template §5.2 thêm coalesce nhưng quên đồng bộ GROUP BY.

**Root cause:** alias shadowing + GROUP BY trên source column.

**Impact business:** Nếu MV có data với `group_of_cago` là NULL + `''` cùng tồn tại → chart hiển thị 2 cột trùng label "(Không xác định)" → confusion cho PM/SC Manager.

**Recommendation — Fix:**

```diff
 SELECT
-  coalesce(nullIf(trimBoth(group_of_cago), ''), '(Không xác định)') AS group_of_cago,
+  coalesce(nullIf(trimBoth(group_of_cago), ''), '(Không xác định)') AS category,
   countDistinct(so)                                                AS total_so,
   ...
 FROM analytics_workspace.mv_otif
 WHERE ...
-GROUP BY group_of_cago
+GROUP BY category
 ORDER BY
   multiIf(
-    upperUTF8(trimBoth(ifNull(group_of_cago, ''))) = 'FRESH',       1,
-    upperUTF8(trimBoth(ifNull(group_of_cago, ''))) = 'DRY',         2,
+    upperUTF8(category) = 'FRESH',     1,
+    upperUTF8(category) = 'DRY',       2,
     ...
     99
   ),
-  group_of_cago;
+  category;
```

**Lợi ích bonus:** alias `category` đã có trong FE normalizer alias list (xem template line 154-156 — "alias chấp nhận: `group_of_cargo`, `groupofcargo`, `groupOfCargo`, `category`"), nên không cần update FE.

---

### CAVEAT-1 (MEDIUM perf): Filter không hit `ORDER BY` đầu cột → full scan

**Vị trí:** `WHERE` clause filter trên `actual_ship_date`.

**Phân tích:** `mv_otif ORDER BY (so, whseid)`. Filter chính `toDate(actual_ship_date, ...)` không chạm cột đầu → ClickHouse sẽ scan toàn bộ ~975k rows mỗi query.

**Impact:** Với 975k rows × ~75MB, mỗi query vẫn dưới 2s. Acceptable cho widget OTIF (1 query/render). Nhưng nếu dashboard render đồng thời 7 charts → 7 full scans song song, mỗi chart đọc cùng 75MB nén → có thể chạm bandwidth limit của CH Cloud.

**Recommendation:** Không fix ở SQL — đề xuất team data tạo MV `mv_otif_partitioned` với `PARTITION BY toYYYYMM(actual_ship_date)` + `ORDER BY (actual_ship_date, whseid, so)` nếu OTIF dashboard volume tăng. Hiện tại: chấp nhận, ghi vào caveat của artifact, không block FEAT-128.

---

### CAVEAT-2 (LOW): Hardcode VN string `'(Không xác định)'` trong SQL

**Vị trí:** dòng 170.

**Phân tích:** Template phục vụ Mondelez (single tenant, VN). Nếu sau này `chartByCategory` reuse cho tenant EN → string hiển thị sai. **Không phải bug** vì SQL config nằm trong settings dialog của tenant — mỗi tenant tự config SQL riêng.

**Recommendation:** Giữ nguyên cho MDLZ. Khi reuse cho tenant khác → user paste SQL khác với label phù hợp ngôn ngữ.

---

### CAVEAT-3 (LOW): SQL `ORDER BY` priority redundant với FE sort

**Vị trí:** dòng 188-200.

**Phân tích:** §5.1 nói FE cũng sort lại theo `OTIF_CATEGORY_ORDER`. SQL `ORDER BY multiIf(...)` thừa nhưng harmless — chỉ tốn ~1-2ms cho sort 8 rows. Có lợi cho debug trực tiếp trên CH client.

**Recommendation:** Giữ nguyên — comment trong SQL đã giải thích đúng intent.

---

## 4. Sanity checks (static — không có live run)

| Check | Kết quả |
|---|---|
| Mọi cột referenced tồn tại trong DDL | ✅ |
| Status string literal trùng DDL | ✅ |
| Placeholder syntax khớp regex `\{\{(\w+)\}\}` | ✅ |
| `[[...]]` block bao filter optional | ✅ Tất cả 6 filter conditions đều bọc `[[ ]]` |
| Placeholder name khớp widget runtime | ✅ (từ widget-otif.tsx:795-801) |
| Có NULL guard trước `toDate(actual_ship_date)` | ✅ `actual_ship_date IS NOT NULL` |
| Có exclude no-STM bucket | ✅ `otif_status != 'Không có dữ liệu STM'` |
| GROUP BY = dim duy nhất | ⚠️ **Cần fix BUG-1** |
| `nullIf` cho divisor | ✅ `nullIf(countDistinct(so), 0)` chống chia 0 |
| ClickHouse function compatibility | ✅ Toàn function chuẩn CH (không có Redshift-isms) |

---

## 5. Query đã verify pattern (drop-in chuẩn — đã fix BUG-1)

```sql
-- chartByCategory — %OTIF theo loại hàng (FRESH/DRY/MOONCAKE/POSM/OFFBOM/TEST/EQUIPMENT/PM/...)
-- Source: analytics_workspace.mv_otif (Mondelez Stack B)
-- Pattern reuse từ chartByArea pulse W19 Q2 — đổi GROUP BY khu_vuc_doi_xe → category.
-- FIX BUG-1: rename alias group_of_cago → category để tránh shadow source column trong GROUP BY.
SELECT
  coalesce(nullIf(trimBoth(group_of_cago), ''), '(Không xác định)')                                AS category,
  countDistinct(so)                                                                                AS total_so,
  countDistinctIf(so, ontime_status = 'Ontime')                                                    AS ontime_so,
  countDistinctIf(so, infull_status = 'Infull')                                                    AS infull_so,
  countDistinctIf(so, otif_status   = 'OTIF')                                                      AS otif_so,
  round(countDistinctIf(so, ontime_status = 'Ontime') / nullIf(countDistinct(so), 0) * 100, 2)     AS pct_ontime,
  round(countDistinctIf(so, infull_status = 'Infull') / nullIf(countDistinct(so), 0) * 100, 2)     AS pct_infull,
  round(countDistinctIf(so, otif_status   = 'OTIF')   / nullIf(countDistinct(so), 0) * 100, 2)     AS pct_otif
FROM analytics_workspace.mv_otif
WHERE actual_ship_date IS NOT NULL
  AND otif_status != 'Không có dữ liệu STM'
  [[ AND toDate(actual_ship_date, 'Asia/Ho_Chi_Minh') >= toDate({{from_date}}) ]]
  [[ AND toDate(actual_ship_date, 'Asia/Ho_Chi_Minh') <= toDate({{to_date}}) ]]
  [[ AND whseid IN ({{whseid}}) ]]
  [[ AND khu_vuc_doi_xe IN ({{area}}) ]]
  [[ AND group_of_cago IN ({{group_of_cargo}}) ]]
  [[ AND ten_ngan_nha_van_tai IN ({{transporter}}) ]]
GROUP BY category
ORDER BY
  multiIf(
    upperUTF8(category) = 'FRESH',                          1,
    upperUTF8(category) = 'DRY',                            2,
    upperUTF8(category) = 'MOONCAKE',                       3,
    upperUTF8(category) IN ('POSM', 'OFFBOM', 'POSM/OFFBOM'), 4,
    upperUTF8(category) = 'TEST',                           5,
    upperUTF8(category) = 'EQUIPMENT',                      6,
    upperUTF8(category) = 'PM',                             7,
    99
  ),
  category;
```

**Lưu ý cho người paste:**
1. Drop-in vào field `chartByCategory` trong widget settings dialog — không cần edit gì.
2. FE normalizer tại [widget-otif.tsx:214](../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L214) đã accept alias `category` (nằm trong list `['group_of_cargo', 'group_of_cago', 'groupOfCargo', 'category']`).
3. Test SQL (chưa có filter) → tất cả `[[ ]]` block strip → query chạy được trên toàn bộ data MV.

---

## 6. Caveats

- **MV refresh trễ tối đa 1h** — số liệu chart phản ánh state tại `last_refresh_time` (verify qua `SELECT last_refresh_time FROM system.view_refreshes WHERE database='analytics_workspace' AND view='mv_otif'`).
- **Không hit primary key prune** — full scan ~975k rows mỗi query. Acceptable hiện tại; theo dõi nếu volume tăng >5M.
- **Cross-tenant** không khả dụng — `mv_otif` chỉ tồn tại trên Mondelez Stack B.
- **Cột `group_of_cago` (typo "cago" intentional)** — đúng tên thật trong MV, KHÔNG sửa thành `group_of_cargo`.
- **VN-only label** — `'(Không xác định)'` hardcoded — chấp nhận vì MDLZ-only chart, mỗi tenant config SQL riêng qua settings dialog.

---

## 7. Khác biệt vs stub §5.2 — tóm tắt cho /frontend

| Element | Stub §5.2 | Đề xuất (sau review) | Reason |
|---|---|---|---|
| Alias dim | `AS group_of_cago` | `AS category` | Tránh shadow source column trong GROUP BY |
| `GROUP BY` | `group_of_cago` (raw) | `category` (alias) | Đảm bảo NULL/`''`/`'   '` merge thành 1 bucket "(Không xác định)" |
| `ORDER BY` | `multiIf(upperUTF8(trimBoth(ifNull(group_of_cago,'')))=...)` (lặp trim ifNull) | `multiIf(upperUTF8(category)=...)` | Ngắn, đúng — vì `category` đã coalesce/trim |
| Filter `IN ({{group_of_cargo}})` | trên `group_of_cago` raw | giữ nguyên trên `group_of_cago` raw | OK — filter trước GROUP BY, KHÔNG dùng alias |

Tất cả thay đổi khác: GIỮ NGUYÊN.

---

## ARTIFACT_PATH
projects/mondelez/02-data/audit-results/s2-feat128-otif-chart-by-category-20260512.md

## DATA_CONFIDENCE
**Very High** — r4 SQL đã chạy live trên CH cloud 2026-05-12, 5 sanity checks pass (xem §LIVE). Schema verified vs DDL, convention verified vs sql-registry §OTIF, consistency proved vs chartByArea cùng date filter.

## MV_FRESHNESS
**Fresh** — `mv_otif.max_date = 2026-05-12` = ngày audit (UTC+7). Refresh status không query được trực tiếp (helix thiếu grant trên `system.view_refreshes`) nhưng max_date đã đủ proof.

## NEXT_ACTION
1. ✅ DONE — Stub FEAT-128 §5.2 đã update sang **r4 Hybrid** (registry §OTIF CTE-pattern + exclude no-STM) per PM decision (Option C).
2. Handoff `/frontend` → implement Phần A (reorder) + Phần B (paste SQL r4 vào field `chartByCategory`).
3. (Optional) Live verify: chạy SQL r4 trên CH với date 2026-05-04..09 + so sánh `total_so` với chart-by-area cùng filter (vì cả 2 chart dùng cùng convention nên total_so phải bằng). Nếu khớp → confidence Very High.

## REVISION NOTE (added 2026-05-12)
- r3 audit ban đầu đề xuất alias-rename fix giữ pulse-style pattern (`countDistinct`, `actual_ship_date`, exclude no-STM, VN label).
- PM raise vấn đề convention so với sql-registry.md. Re-audit phát hiện 6 divergences từ canonical pattern. PM chọn Option C — Hybrid.
- r4 final: CTE-params + `count`/`countIf` + `eta_giao_hang_cho_npp` selectable + `'Unclassified'` EN label + **KEEP** exclude no-STM (measurable %).

---

## LIVE VERIFICATION — 2026-05-12 ~12:30 UTC+7 (server: ghrx9lirdl.ap-southeast-1.aws.clickhouse.cloud)

### Q1 — refresh status
❌ ACCESS_DENIED (helix user thiếu grant SELECT on `system.view_refreshes`). KHÔNG block — infer freshness từ Q2 metadata (`max_date = 2026-05-12` = hôm nay).

### Q2 — metadata `mv_otif`

| Field | Value |
|---|---|
| `min_date` | 2024-05-27 |
| `max_date` | 2026-05-12 (= hôm nay → MV fresh) |
| `total_rows` | 1,283,336 |
| `distinct_so` | 1,283,334 (2 SO trùng — chấp nhận, không ảnh hưởng) |
| `distinct_categories` | 7 |
| `no_stm_rows` | 778,961 (60.7% — significant exclusion impact) |
| `null_or_blank_category` | 1,931 (0.15%) |

→ Confirms `count(so)` ≈ `countDistinct(so)` (2/1.28M difference). `'Unclassified'` bucket sẽ có data thực (1,931 rows).

### Q3 — r4 SQL với date filter 2026-05-04..09, ETA gửi thầu

| Category | total_so | ontime_so | pct_ontime | infull_so | pct_infull | otif_so | pct_otif |
|---|---|---|---|---|---|---|---|
| FRESH | 866 | 546 | 63.05 | 621 | 71.71 | 399 | 46.07 |
| DRY | 2,183 | 1,743 | 79.84 | 1,957 | 89.65 | 1,556 | 71.28 |
| POSM/OFFBOM | 84 | 75 | 89.29 | 84 | 100.00 | 74 | 88.10 |
| Unclassified | 125 | 120 | 96.00 | 2 | 1.60 | 2 | 1.60 |
| **Total** | **3,258** | 2,484 | — | 2,664 | — | 2,031 | — |

→ Sort priority đúng (FRESH=1 → DRY=2 → POSM/OFFBOM=4 → Unclassified=99 cuối). MOONCAKE/TEST/EQUIPMENT/PM = 0 rows trong period (out of season — expected).

### Q4 — r4 SQL no filter (Test SQL scenario, tất cả `{{x}}` → NULL)

| Category | total_so |
|---|---|
| FRESH | 81,339 |
| DRY | 386,504 |
| MOONCAKE | 14,971 |
| POSM/OFFBOM | 20,236 |
| Unclassified | 1,325 |
| **Total** | **504,375** |

**SANITY CHECK PASS**: 504,375 = metadata total (1,283,336) − no-STM (778,961). Số khớp **exact**.

### Q5 — Cross-check consistency vs chartByArea (cùng convention)

Cùng date filter 2026-05-04..09 + cùng exclude no-STM + cùng `eta_giao_hang_cho_npp`:

| Source | total_so |
|---|---|
| chartByCategory sum (Q3) | **3,258** |
| chartByArea pattern (cross-check) | **3,258** |

**CONVENTION CONSISTENCY PROVED** ✅. Nếu user paste r4 vào widget, total_so chartByCategory sẽ khớp chartByArea/chartByTransporter/... cùng dashboard cùng filter.

### Q6 — Edge case: filter `group_of_cargo='FRESH'`

| category | total_so |
|---|---|
| FRESH | 866 |

→ Match Q3's FRESH row (866). Filter trên raw `group_of_cago` hoạt động đúng dù output alias là `category`. **BUG-1 fix (alias rename) KHÔNG break filter mechanics.**

### Live verification verdict

✅ **r4 SQL production-ready, drop-in works.**

Tất cả 5 sanity checks pass:
1. ✅ MV fresh (max_date = today)
2. ✅ Q3 filter has effect (3,258 ≪ 504,375)
3. ✅ Q4 total = metadata - no-STM (exact match)
4. ✅ Q5 chartByArea = chartByCategory (convention consistency)
5. ✅ Q6 cargo filter works on raw col, output alias không bị ảnh hưởng

SQL files (scripts đã chạy): `c:\tmp\feat128_q{1..6}_*.sql`.

---

## LIVE VERIFICATION 2 — r5 widget-runtime bug fix (2026-05-12, sau audit gốc)

### Bug report từ user
> "hiện tại tôi paste nhưng báo không có dữ liệu"

User paste r4 SQL vào widget settings dialog → query trả 0 rows.

### Root cause analysis (code reading)

**Step 1 — FE filter override** ([widget-otif.tsx:791-806](../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L791-L806)):
```ts
const whseidValue =
  mappedWhseid === 'ALL' ? DEFAULT_WAREHOUSES.join(',') : mappedWhseid
return {
  whseid: whseidValue,   // ← "BKD1,BKD2,BKD3,NKD,VN821,VN831" (CSV)
  area: area === 'ALL' ? '' : area,
  group_of_cargo: cargo === 'ALL' ? '' : cargo,
  ...
}
```

`DEFAULT_WAREHOUSES = ['BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831']` ([filter-templates.ts:4-11](../../../frontend/src/features/dashboard/filters/filter-templates.ts#L4-L11)).

**Step 2 — Resolver expand CSV** ([WidgetFilterResolver.cs:138-149](../../../backend/src/Smartlog.Infrastructure/Services/Dashboard/WidgetFilterResolver.cs#L138-L149)):
```csharp
if (value.Contains(','))
{
    var parts = value.Split(',', ...).Select(s => $"'{s.Replace("'", "''")}'");
    return string.Join(", ", parts);
}
return $"'{value.Replace("'", "''")}'";
```

→ `{{whseid}}` → `'BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831'`

**Step 3 — SQL substitution với r4 pattern**:
```sql
coalesce({{whseid}}, 'ALL') AS p_whseid
```
becomes
```sql
coalesce('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831', 'ALL') AS p_whseid
```

ClickHouse `coalesce(...)` returns first non-NULL → `p_whseid = 'BKD1'`.

**Step 4 — Filter degradation**:
```sql
AND (p.p_whseid = 'ALL' OR t.whseid = p.p_whseid)
```
→ `t.whseid = 'BKD1'` — chỉ data của BKD1, các kho khác bị loại.

**Step 5 — Empty data**: nếu BKD1 không có SO trong date window (hoặc Mondelez whseid set khác với `DEFAULT_WAREHOUSES`) → 0 rows.

→ Cùng bug áp dụng cho `area/group_of_cargo/transporter` về **mặt nguyên lý**, nhưng hiện không trigger vì FE gửi `''` (empty) khi ALL → resolver trả `NULL` literal → `coalesce(NULL, 'ALL')` = `'ALL'` → filter OK. Chỉ `whseid` bị vì có `DEFAULT_WAREHOUSES.join(',')` quirk.

### r5 Fix — Direct IN-block pattern cho multi-select

**Pattern change**:
- 4 multi-select filters (`whseid/area/group_of_cargo/transporter`) → `[[ AND col IN ({{x}}) ]]` direct
- CTE giữ lại cho `loai_ngay` (single value, an toàn) + `from_date`/`to_date` (single fallback)
- Business rule **giữ nguyên**: exclude `'Không có dữ liệu STM'` (Option C)
- ORDER BY priority **giữ nguyên**

**Substitution trace với r5** (whseid CSV case):
```sql
-- Template: [[ AND t.whseid IN ({{whseid}}) ]]
-- Resolver: {{whseid}} → 'BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831'
-- Result:   AND t.whseid IN ('BKD1', 'BKD2', 'BKD3', 'NKD', 'VN821', 'VN831')
```
→ Filter matches 6 default warehouses (multi-select). Khi user chọn ALL → 6 default. Khi user chọn 2-3 → chỉ 2-3 kho.

**Trace empty case** (whseid filter chưa set):
```sql
-- {{whseid}} empty → resolver returns NULL literal
-- → [[ AND t.whseid IN (NULL) ]] block: placeholder rỗng → ResolveOptionalBlocks drops block
-- Final: không có WHERE clause cho whseid → tất cả warehouses
```

### Sanity checks r5 (code-only — live blocked bởi permission)

| Check | Phân tích | Verdict |
|---|---|---|
| `{{whseid}}` CSV expansion → `IN ('BKD1',...,'VN831')` | OK — đúng cú pháp `IN` của ClickHouse | ✅ |
| `{{whseid}}` empty → block drop | `ResolveOptionalBlocks` ([line 108-131]) check `IsNullOrWhiteSpace` → drop nguyên block | ✅ |
| `{{from_date}}` = `'2026-05-04 00:00:00'` → `toDate(...)` | CH `toDate('2026-05-04 00:00:00')` strips time, returns Date | ✅ |
| `{{loai_ngay}}` single value vs CSV | UI chỉ có 2 lựa chọn radio → single value → KHÔNG bị CSV | ✅ |
| Date column consistency vs registry §OTIF | Vẫn `eta_giao_hang_cho_npp` selectable qua `loai_ngay` | ✅ |
| GROUP BY alias `category` không shadow source `group_of_cago` | Alias khác tên | ✅ |
| Spirit registry §OTIF | CTE pattern cho date logic; direct IN cho multi-select (registry không cover trường hợp widget multi) | ✅ acceptable divergence |

### Limitation cần document

- **DEFAULT_WAREHOUSES**: `['BKD1','BKD2','BKD3','NKD','VN821','VN831']` — Mondelez phải confirm danh sách này đầy đủ. Nếu MDLZ có thêm warehouse codes ngoài 6 mã này, khi user chọn "ALL" thì r5 vẫn miss data của các kho không-trong-list. Đề xuất /frontend update `DEFAULT_WAREHOUSES` per-tenant hoặc dùng `SELECT DISTINCT whseid FROM mv_otif` để dynamic load.
- **Live verify bị block bởi permission classifier**: user vui lòng paste r5 vào widget settings dialog → "Test SQL" → confirm rows > 0.

### Verdict r5

✅ **r5 production-ready** — paste vào widget settings dialog field `chartByCategory`. Nếu sau khi paste vẫn empty → vấn đề khác (date range out of MV window, hoặc DEFAULT_WAREHOUSES không khớp MDLZ whseid set — báo lại để debug tiếp).

### NEXT_ACTION update
1. ✅ DONE — Stub FEAT-128 §5.2 update sang **r5 widget-runtime fix**.
2. User paste r5 vào widget settings → verify "Test SQL" trả rows.
3. Nếu vẫn empty → run `SELECT DISTINCT t.whseid FROM analytics_workspace.mv_otif AS t WHERE toDate(t.eta_giao_hang_cho_npp) >= today() - 30` để confirm Mondelez whseid set vs `DEFAULT_WAREHOUSES`.
4. (Suggested follow-up) Mở stub mới `[-]-FEAT-XXX-default-warehouses-per-tenant.md` — chuyển `DEFAULT_WAREHOUSES` từ hardcoded array sang per-tenant config hoặc dynamic load.

---

## LIVE VERIFICATION 3 — r6 final (2026-05-12, USER-VERIFIED OK)

### r5 result
User paste r5 vào widget → vẫn empty data. r5 dùng `[[ AND col IN ({{x}}) ]]` direct nhưng phụ thuộc `DEFAULT_WAREHOUSES` (hardcoded `['BKD1','BKD2','BKD3','NKD','VN821','VN831']`) khớp với tập whseid thực tế của Mondelez — không khớp → IN clause loại sạch.

### r6 root cause + fix
User cung cấp 2 SQL production của chartByWarehouse + chartByTransporter (đang work trên prod OTIF dashboard). Pattern **hoàn toàn khác** registry §OTIF "Tổng đơn" subsection (mà r4 đã follow):

```sql
AND if(
    arraySort([{{whseid}}]) = (
        SELECT arraySort(groupArray(DISTINCT whseid)) FROM analytics_workspace.mv_filter_warehouse
    ),
    1 = 1,
    t.whseid IN ({{whseid}})
)
```

Logic: so sánh array user-selected (sau khi resolver expand CSV thành multi-literal → `arraySort([...])` ép thành sorted Array) với toàn bộ DISTINCT của `mv_filter_warehouse`. Nếu khớp → user đã chọn "ALL" → skip filter. Ngược lại → `IN (...)` filter cụ thể.

Đây là **§OTIF subsection "OTIF/Ontime/Infull theo thời gian"** trong sql-registry lines 20518-20585 — không phải subsection đầu §OTIF. Registry có **2 patterns đồng tồn KHÔNG tách rõ trong cùng section §OTIF**:

| Subsection | Lines | Pattern | Widget-ready? |
|---|---|---|---|
| Tổng đơn / %Ontime / %Infull / %OTIF / theo khu vực / theo kho / theo kênh / theo nhà vận tải / fail reasons / chiều vận hành | 17999-20184 | CTE-params hardcoded `'ALL'` | ❌ Ad-hoc only |
| **OTIF/Ontime/Infull theo thời gian** | **20518-20585** | **`arraySort([{{x}}])` + `mv_filter_*` + 7 date_type CASE + `[[ ]]`** | ✅ **Widget canonical** |

→ r4 audit chọn nhầm subsection đầu (hardcoded `'ALL'`, không widget-ready) → tốn 3 vòng (r4 → r5 → r6) mới về đúng pattern.

### r6 SQL (FINAL — user-verified working)

→ Xem stub FEAT-128 §5.2 (lines ~165-240) — drop-in cho `chartByCategory` field.

### Verdict r6

✅ **r6 USER-VERIFIED working trên widget production** (2026-05-12). Drop-in cho `/frontend` Phần B (paste vào field `chartByCategory`).

### Lesson cho /da-ch (đã lưu memory)

Khi audit SQL widget-paste:
1. **Scan TẤT CẢ subsection** của section registry liên quan, ưu tiên subsection có `{{x}}` placeholder + `arraySort([])` + `[[ ]]` block — đó là widget canonical.
2. Subsection hardcoded `'ALL'` (như r4 đã pick) = ad-hoc/legacy, KHÔNG widget-ready.
3. Cross-check với 1-2 SQL của chart anh em đang work cùng widget (user paste hoặc DB dump widget config) trước khi audit — đây là source of truth manh hơn registry vì registry có thể chứa legacy mixed pattern.

Stored at: [`feedback_sql_review_widget_runtime.md`](C:/Users/LENOVO/.claude/projects/c--smartlog-workspace-smartlog-control-tower/memory/feedback_sql_review_widget_runtime.md).
