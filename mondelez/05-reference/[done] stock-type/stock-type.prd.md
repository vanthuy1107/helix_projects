# PRD — Stock Type (Inventory by Product Group)

> **Status:** 🟡 Draft v1 (cần stakeholder confirm các điểm `[TBD]`)
> **Owner:** [TBD]
> **Last updated:** 2026-05-07
> **Reference docs:**
> - Spec: `docs/02-features/stock-type/stock-type.spec.md` *(✅ rewritten v2 — aligned với code+MV reality)*
> - Wireframe: `docs/02-features/stock-type/stock-type.wireframe.md` *(✅ aligned)*
> - Audit results: `docs/audit-results/s2-stock-type-20260507.md`, `docs/audit-results/s1-stock-type-final-20260507.md`

---

## 1. Overview

**Stock Type** (tên trong UI: **Inventory by Product Group**) là dashboard giám sát tồn kho hiện tại của Mondelez Vietnam, breakdown theo:

- **Warehouse** (6 kho: BKD1, BKD2, BKD3, NKD, VN821, VN831 — verified live)
- **Cargo group** (6 + NULL: DRY, FRESH, EQUIPMENT, POSM/OFFBOM, PM, TEST + NULL → `coalesce → 'Unclassified'`)
- **Brand** (10 + NULL: Oreo, Cosy, Solite, AFC, Slide, KD, RITZ, Lu, Tết, Other + NULL)

Mỗi row hiển thị tồn kho theo 5 đơn vị song song (PCE/CBM/Ton/CSE/Pallet), kèm 2 commitment metrics: **Allocated** (CSE đã phân bổ cho đơn nhưng chưa pick) và **Picked** (CSE đã pick chờ ship). **Available** = `qty − allocated − picked` (computed UI).

Source: `analytics_workspace.mv_stocktype` (refresh **EVERY 1 HOUR**, snapshot pattern — không có time dimension).

---

## 2. Problem Statement

### 2.1 Pain points

1. **Thiếu visibility realtime** về tồn kho theo brand/cargo group — trước đây WH manager phải query SAP thủ công.
2. **Không có view so sánh kho** — manager khó đánh giá phân bổ tồn giữa BKD1/2/3 vs NKD vs VN.
3. **Allocated vs Available chưa rõ** — team customer service không biết bao nhiêu inventory thực sự "available" để bán (sau khi trừ allocated/picked).
4. **Brand mix Excel manual** — báo cáo top product groups theo Brand cho marketing tốn 1–2h/tuần.

### 2.2 Why now

- DA team đã chuẩn hoá `mv_stocktype` từ raw `dim_lotxlocxid` (refresh 1h) → đủ điều kiện build dashboard.
- Mondelez muốn dashboard quick view tồn kho cho daily ops review.

---

## 3. Target Users

| Persona | Vai trò | Tần suất | Use case |
|---|---|---|---|
| **Warehouse Manager** | Quản lý 1 hoặc nhiều kho | Daily | Track tổng tồn theo kho, identify bottleneck cargo group |
| **Customer Service / Sales Ops** | Nhận đơn, check availability | Intraday | Available CSE per brand → tránh promise quá tồn |
| **Brand Manager (Marketing)** | Theo dõi tồn brand | Weekly | Top product groups, share of total inventory |
| **Demand Planning** | Forecast vs actual | Weekly | Compare tồn kho vs IBP target |

---

## 4. Goals & Success Metrics

> ⚠️ Stakeholder cần confirm. Đề xuất default:

### 4.1 Business goals

| Goal | Metric | Target đề xuất |
|---|---|---|
| Tăng visibility tồn realtime | DAU view | ≥ 2 lần/ngày/user |
| Giảm thời gian báo cáo brand mix | Giờ/tuần | < 15 phút (từ 1–2h Excel) |
| Cross-warehouse benchmark | WH manager dùng tab So sánh kho | 4/6 kho (66%+) |

### 4.2 Product KPIs sau launch

- DAU/WAU
- Latency p95 API (target < 1s — MV nhỏ, query nhanh)
- Refresh cadence: 1 giờ (theo MV)

---

## 5. Functional Requirements

### 5.1 Filter bar (Must-have)

| FR | Mô tả |
|---|---|
| FR-F1 | 3 filter chính: **Warehouse**, **Cargo Group** (= Product Category), **Brand** |
| FR-F2 | Single-select dropdown, default `'ALL'` |
| FR-F3 | UI **không cần date filter** — MV là snapshot |
| FR-F4 | UI **không expose Storer** — MV pre-filter `storer_key='MDLZ'` (chỉ 1 value) |
| FR-F5 | Optional UOM toggle: `[CSE] [Pallet]` (theo wireframe) — chỉ thay đổi metric column SUM, không filter rows |
| FR-F6 | Apply button trigger refetch (Draft → Apply pattern) |

### 5.2 Tab "Chart" (Must-have)

| FR | Mô tả |
|---|---|
| FR-C1 | **5 KPI cards** (theo wireframe): Total Inv CSE / Total Inv PLT / Master Units / Volume CBM / Volume TON |
| FR-C2 | (Phase 2) **Allocated / Picked / Available** breakdown card với % Committed |
| FR-C3 | Chart "Inventory by Product Group" — pie chart % theo `group_of_cargo` |
| FR-C4 | Chart "Inventory by Warehouse (Stacked)" — stacked bar, mỗi wh stack theo cargo |
| FR-C5 | Chart "Top Product Groups Ranking" — horizontal bar top N (default 5–10) theo brand hoặc cargo |
| FR-C6 | Mỗi chart có info icon `[?]` tooltip công thức |

### 5.3 Tab "Detail" (Must-have)

| FR | Mô tả |
|---|---|
| FR-T1 | Bảng chi tiết — cột: Warehouse, Cargo, Brand, Storer, qty, qty_cbm, qty_ton, qty_cse, qty_pl, qty_allocated, qty_picked |
| FR-T2 | Per-column search input |
| FR-T3 | Sort 3-state per column |
| FR-T4 | Export CSV/XLSX |
| FR-T5 | Pagination 10–50 rows/page (MV chỉ ~82 rows nên 1 page là đủ) |

### 5.4 Data layer (Must-have)

| FR | Mô tả |
|---|---|
| FR-D1 | Source: `analytics_workspace.mv_stocktype` (KHÔNG dùng `mv_test_stocktype`) |
| FR-D2 | Refresh cadence: **1 giờ** (snapshot) |
| FR-D3 | KPI tính trong SQL/MV (single source of truth) |
| FR-D4 | UI hiển thị "Cập nhật lúc HH:mm" để user biết freshness |

### 5.5 API Endpoints (đề xuất 5 hoặc 1)

8 SQL queries trong registry có thể gộp thành:

**Option A — 5 endpoints (per concern):**

| Function | SQL Registry section | Mô tả |
|---|---|---|
| `fetchStockTypeKpiSummary` | "Total Inv CSE/Pallet" + "Master units" + "Volume CBM/Ton" (3120–3409) | 5 KPI numbers |
| `fetchStockTypeByCargo` | "% by Converted Product Group" (3411) | Pie chart data |
| `fetchStockTypeByWarehouse` | "% by warehouse · stacked" (3527) | Stacked bar |
| `fetchStockTypeTopProductGroups` | "Top product groups" (3662) | Top N ranking |
| `fetchStockTypeDetail` | "Detail data" (3789) | Raw table |

**Option B — 1 endpoint:**

```ts
fetchStockType(filter) → StockTypeRow[]   // raw 82 rows; UI tự aggregate
```

> **Recommendation:** Option B đơn giản hơn (MV chỉ 82 rows, fetch all an toàn). Aggregation client-side. Phase 2 cân nhắc Option A nếu data lớn lên.

### 5.6 Business Logic Specification

> **Source of truth**: `analytics_workspace.mv_stocktype`. Logic verified với 82 rows tại 2026-05-07.

#### 5.6.1 Đầu vào & Granularity

| Item | Định nghĩa |
|---|---|
| **Granularity** | 1 row = 1 (storer_key × whseid × group_of_cargo × brand) aggregate. Pre-aggregated từ raw `dim_lotxlocxid`. |
| **Volume metrics** | 5 cột song song: `qty` (PCE/masterunit), `qty_cbm`, `qty_ton`, `qty_cse`, `qty_pl` |
| **Commitment metrics** | 2 sets × 5 metrics: `qty_allocated_*` (đã phân bổ đơn), `qty_picked_*` (đã pick) |
| **Available** = `qty - allocated - picked` (computed UI hoặc thêm cột) |
| **Date dimension** | KHÔNG có — snapshot pattern; refresh 1 giờ |

#### 5.6.2 Built-in filters (DDL hardcoded)

| Filter | Giá trị | Lý do |
|---|---|---|
| `storer_key` | `'MDLZ'` only | MV chỉ track inventory MDLZ (không phải 3PL khác) |
| `whseid` | `IN ('BKD1','BKD2','BKD3','NKD','VN821','VN831')` | 6 kho production |
| `qty > 0` | bắt buộc | Loại tồn = 0 |
| `is_deleted = 0` | ✅ CLAUDE Rule 1 | Verified ở `dim_lotxlocxid` + `dim_lotattribute` |
| Exclude `(NKD, sku IN ('LOSCAM','BACHTHUAN'))` | hardcoded | Pallet rỗng từ supplier ngoài MDLZ |

> **Implication:** API filter `storer` redundant (chỉ có 1 value). Filter `whseid` chỉ chấp nhận 6 wh hardcoded.

#### 5.6.3 Công thức KPI

```sql
-- 5 KPI cards (toàn MV, sau filter)
total_inv_cse  = SUM(qty_cse)
total_inv_pl   = SUM(qty_pl)
master_units   = SUM(qty)
total_qty_cbm  = SUM(qty_cbm)
total_qty_ton  = SUM(qty_ton)

-- 3 commitment metrics (Phase 2 candidate)
allocated_cse  = SUM(qty_allocated_cse)
picked_cse     = SUM(qty_picked_cse)
available_cse  = SUM(qty_cse - coalesce(qty_allocated_cse, 0) - coalesce(qty_picked_cse, 0))
pct_committed  = (allocated_cse + picked_cse) / nullIf(total_inv_cse, 0)

-- Pie by cargo group (sum_total = SUM(qty_cse) toàn dataset sau filter)
WITH agg AS (
  SELECT coalesce(group_of_cargo, 'Unclassified') AS cargo,
         SUM(qty_cse) AS qty_cse
  FROM mv_stocktype <where_filter>
  GROUP BY cargo
),
total AS (SELECT SUM(qty_cse) AS sum_total FROM agg)
SELECT cargo, qty_cse,
       qty_cse * 100.0 / nullIf((SELECT sum_total FROM total), 0) AS pct
FROM agg

-- Stacked bar by warehouse
SELECT whseid, coalesce(group_of_cargo, 'Unclassified') AS cargo,
       SUM(qty_cse) AS qty_cse
GROUP BY whseid, cargo

-- Top product groups
SELECT coalesce(group_of_cargo, 'Unclassified') AS cargo,
       SUM(qty_cse) AS qty_cse
GROUP BY cargo
ORDER BY qty_cse DESC
LIMIT N
```

#### 5.6.4 Filter Behavior (SQL)

```sql
WHERE 1=1
  AND (p_whse  = 'ALL' OR whseid = p_whse)
  AND (p_cargo = 'ALL' OR coalesce(group_of_cargo, 'Unclassified') = p_cargo)
  AND (p_brand = 'ALL' OR brand = p_brand)
  AND (p_storer = 'ALL' OR storer_key = p_storer)   -- redundant (MV chỉ MDLZ)
```

#### 5.6.5 KPI Snapshot (verified live 2026-05-07)

| KPI | Giá trị toàn MV | Note |
|---|---:|---|
| Total Inventory CSE | **2,166,568** | ⚠️ Bao gồm 45% EQUIPMENT (BUG-1) |
| Total Inventory Pallet | **1,209,093** | |
| Master Units | **44,309,378** | |
| Total CBM | **27,212.62** | |
| Total Ton | **3,485.43** | |
| Allocated CSE | 27,221 (1.26%) | Đã dành cho đơn |
| Picked CSE | 14,237 (0.66%) | Đã pick chờ ship |
| **Available CSE** | **2,125,110 (98.08%)** | qty - allocated - picked |
| **% Committed** | **1.91%** | (allocated + picked) / total |

#### 5.6.6 Cargo Group Distribution (verified)

| Cargo | Rows | Σ CSE | % CSE | Σ CBM | Note |
|---|---:|---:|---:|---:|---|
| **EQUIPMENT** | 3 | 975,805 | **45.0%** | 299 | ⚠️ BUG-1 — empty pallets/forklifts; BA confirm có gồm KPI không |
| DRY | 54 | 916,129 | 42.3% | 23,918 | Hàng khô (chính) |
| NULL | 14 | 196,523 | 9.1% | 2,267 | UI fallback `'Unclassified'` |
| **TEST** | 2 | 66,149 | 3.1% | 0 | ⚠️ BUG-2 — vi phạm CLAUDE Rule 3, cần exclude |
| POSM/OFFBOM | 5 | 5,649 | 0.3% | 419 | Marketing material |
| FRESH | 2 | 5,544 | 0.3% | 310 | Hàng tươi |
| PM | 2 | 769 | <0.1% | 0 | Promotion material |

#### 5.6.7 Brand Distribution (verified)

11 brands (10 + NULL):

| Brand | Σ CSE | % |
|---|---:|---:|
| Other | 1,198,603 | 55.3% ⚠️ catch-all bucket lớn |
| Oreo | 443,316 | 20.5% |
| Cosy | 222,856 | 10.3% |
| Solite | 150,002 | 6.9% |
| AFC | 49,850 | 2.3% |
| Slide | 40,971 | 1.9% |
| KD | 27,972 | 1.3% |
| RITZ | 13,006 | 0.6% |
| Lu | 10,439 | 0.5% |
| NULL | 9,098 | 0.4% |
| Tết | 455 | <0.1% |

> **Q4 BA `[TBD]`:** "Other" brand chiếm 55% — quá lớn. SKU master mapping cần review.

#### 5.6.8 Edge Cases

| # | Tình huống | Xử lý |
|---|---|---|
| BL-1 | NULL `group_of_cargo` (14 rows / 17%) | SQL `coalesce → 'Unclassified'`; UI hiển thị segment "Unclassified" |
| BL-2 | NULL `brand` (4 rows / 5%) | SQL `coalesce → 'Unclassified'` |
| BL-3 | Filter cargo='Unclassified' khớp với rows có group NULL | ✅ Match expected |
| BL-4 | Tổng = 0 sau filter (filter quá hẹp) | KPI cards hiển thị 0; pie/bar empty |
| BL-5 | TEST cargo (66K CSE) | ⚠️ Hiện đang lọt vào KPI — Q1 BA quyết định loại |
| BL-6 | EQUIPMENT cargo (45% CSE) | ⚠️ qty_cbm gần 0 → empty pallets; Q2 BA quyết định scope |
| BL-7 | `qty_allocated_cse` NULL → Available calculation | `coalesce(qty_allocated_cse, 0)` |
| BL-8 | Refresh delay 1h | UI hiển thị timestamp |
| BL-9 | Snapshot mismatch — query 2 lần liền nhau giữa lần refresh có thể trả khác (nếu lệch refresh window) | Acceptable; user click Apply lại để refresh |
| BL-10 | Concurrent MV refresh — query trùng thời điểm `REFRESH EVERY 1 HOUR` đang chạy | ClickHouse SharedMergeTree đảm bảo atomic — không trả partial data; có thể delay vài giây |
| BL-11 | Filter combination empty (vd: warehouse=`VN821` AND cargo=`FRESH` → 0 rows; FRESH chỉ có ở BKD1, NKD) | KPI cards = 0; pie/bar chart empty state; cần UI message "No data for current filter" |
| BL-12 | Decimal precision rounding — `qty_cse` Decimal(38,4); MV dùng `CEIL` per SKU×BATCH→ tổng có thể lệch ±1–2 CSE so với `CEIL(SUM(qty))` | Document only; không fix — trade-off chấp nhận của upstream MV logic |
| BL-13 | Theoretical: `qty_allocated > qty` (allocated nhiều hơn tồn) | Verified 0 occurrences live; nếu xảy ra → Available âm. UI nên `Math.max(available, 0)` để guard |
| BL-14 | LOSCAM/BACHTHUAN exclusion ở NKD — verify hoạt động đúng | Filter ở DDL `NOT (whseid='NKD' AND sku IN ('LOSCAM','BACHTHUAN'))`; chưa verify đếm rows bị exclude — DA confirm |

#### 5.6.9 CLAUDE.md Data Exclusion Audit

| # | Rule | Trạng thái | Note |
|---|---|---|---|
| 1 | `is_deleted = 0` | ✅ **Verified ở DDL** | `l.is_deleted=0 AND lot.is_deleted=0` |
| 2 | Cancelled orders | N/A | MV về tồn kho, không có orders |
| 3 | Virtual/Test orders | ❌ **VIOLATION** | TEST cargo 66K CSE — BUG-2 cần fix |
| 4 | Internal transfers | N/A | Snapshot |
| 5 | NULL warehouse | ✅ **Verified** | DDL `whseid IN (...)` filter |
| 6 | Divide by zero → 0 | ✅ **Verified** | `nullIf(masterunit_per_cse, 0)` ở MV |

#### 5.6.10 Verified Data Patterns (live audit 2026-05-07)

**A. Anomaly: EQUIPMENT cargo dominant (45% CSE)**
- 3 rows, 975K CSE, qty_cbm = 299 m³ (effectively 0)
- qty_cse ≈ qty_pl (ratio 1:1) gợi ý empty pallets / non-product equipment
- Concentration: BKD1 (966K CSE), BKD3 (1.3K), VN821 (8.4K)
- **Action:** BA confirm có loại khỏi customer-facing KPI không

**B. TEST cargo violation (66K CSE)**
- 2 rows: BKD1 (704 CSE) + BKD3 (65,445 CSE)
- qty_cbm = 0 → giá trị thực tế = 0 nhưng count vào CSE
- **Action:** DA add `WHERE category != 'TEST'` ở MV

**C. NULL distribution**

| Column | NULL count | NULL % |
|---|---:|---:|
| `group_of_cargo` | 14 | 17.1% |
| `brand` | 4 | 4.9% |
| `qty`, `qty_cse`, `qty_pl`, `qty_cbm`, `qty_ton` | 0 | 0% |

**D. Storer = 1 only**
- `storer_key = 'MDLZ'` 100% (DDL hardcoded)
- API filter `storer` không có giá trị → bỏ khỏi UI

**E. mv_stocktype vs mv_test_stocktype**

| MV | Rows | Total CSE | Schema |
|---|---:|---:|---|
| `mv_stocktype` (prod) | 82 | 2,166,568 | Decimal(38,4)/(38,6) |
| `mv_test_stocktype` | 83 | 2,181,314 | Float64 (mostly) |

→ Schema mismatch (verified `UNION ALL` raise NO_COMMON_TYPE). Backend phải dùng đúng `mv_stocktype` (prod). Same pattern as Transaction Move BUG.

**F. Refresh cadence verified**
- DDL: `REFRESH EVERY 1 HOUR`
- Acceptable cho daily ops review (không cần realtime).

**G. Cargo classification by CSE/PL ratio + CBM (verified live)**

Phân loại 7 cargo groups bằng cách phân tích **`cse_per_pl` ratio** và **`cbm_per_pl`**:

| Cargo | Σ CSE | Σ PL | Σ CBM | CSE/PL ratio | CBM/PL ratio | **Classification** |
|---|---:|---:|---:|---:|---:|---|
| **DRY** | 916,129 | 18,861 | 23,917.77 | **48.57** | 1.27 | 🟢 **PRODUCT** (real cases on pallets) |
| **FRESH** | 5,544 | 221 | 310.23 | **25.09** | 1.40 | 🟢 **PRODUCT** (chilled product) |
| POSM/OFFBOM | 5,649 | 1,632 | 418.62 | 3.46 | 0.26 | 🟡 **MIXED** (small marketing items) |
| **EQUIPMENT** | 975,805 | 974,549 | 299.28 | **1.00** | **0.0003** | 🔴 **EMPTY/EQUIPMENT** (1:1 ratio = empty pallets) |
| **TEST** | 66,149 | 65,452 | 0.00 | **1.01** | **0.00** | 🔴 **EMPTY/EQUIPMENT** (test pallets, zero CBM) |
| **PM** | 769 | 732 | 0.03 | **1.05** | **0.00** | 🔴 **EMPTY/EQUIPMENT** (promotion pallets, zero CBM) |
| NULL | 196,523 | 147,646 | 2,266.68 | 1.33 | 0.015 | 🟡 **MIXED** (mostly equipment-like) |

> **Quy tắc phân loại verified:**
> - `cse_per_pl ≈ 1` AND `cbm_per_pl ≈ 0` → **EMPTY/EQUIPMENT** (qty_cse = qty_pl tức 1 case = 1 pallet, không có volume)
> - `cse_per_pl > 20` AND `cbm_per_pl > 1` → **PRODUCT** (real products with pallet ratio match SKU master)
> - Còn lại → **MIXED** (small items, POSM, NULL etc.)

**H. KPI scenario comparison (CRITICAL INSIGHT)**

Verified live so sánh KPI giữa các filter scenarios:

| Scope | Σ CSE | Σ Pallet | Σ CBM | Note |
|---|---:|---:|---:|---|
| **All 82 rows (current default)** | 2,166,568 | **1,209,093** | 27,212.62 | KPI hiện tại UI hiển thị |
| Real product (DRY + FRESH only) | 921,673 (43%) | 19,082 **(1.6%)** | 24,228 (89%) | Conservative |
| Minus EQUIPMENT/TEST/PM | 1,123,845 (52%) | 168,360 (14%) | 26,913 (99%) | Recommended default |
| EQUIPMENT/TEST/PM only | **1,042,723 (48%)** | **1,040,733 (86%)** | 299 (1%) | Empty pallets contribution |

> 🚨 **CRITICAL FINDING — "Total Inv Pallet" KPI bị skew nghiêm trọng:**
> - Total Pallet hiện tại = **1,209,093**
> - Nhưng **86% trong số đó (1,040,733) là EMPTY/EQUIPMENT pallets** (không có hàng)
> - Real product pallets chỉ **168,360 (14%)** hoặc **19,082 (1.6%)** nếu chỉ tính DRY+FRESH
>
> 🟡 **Total Inv CSE bị skew vừa**:
> - 48% CSE thuộc EQUIPMENT/TEST/PM (không phải hàng hóa thật)
> - Real product CSE: **1,123,845 (52%)**
>
> 🟢 **Total Volume CBM gần như chính xác** (99% là real product)
>
> **Implication:**
> - Nếu user query "Tôi có bao nhiêu pallet hàng?" → KPI "Total Inv Pallet" trả 1.2M (sai). Đáp án đúng là ~168K.
> - Q1 + Q2 PRD critical decisions cần resolve trước Phase 1 launch.

**I. Per-warehouse commitment metrics (verified live)**

| Warehouse | Σ CSE | Allocated CSE | Picked CSE | Available CSE | % Committed |
|---|---:|---:|---:|---:|---:|
| BKD1 | 1,128,206 | 1,582 | 1,415 | 1,125,209 | **0.27%** |
| BKD3 | 330,869 | 4,022 | 1,800 | 325,047 | 1.76% |
| BKD2 | 312,204 | 6,199 | **0** | 306,005 | 1.99% |
| VN831 | 197,427 | 13,854 | **0** | 183,573 | **7.02%** |
| NKD | 158,016 | 1,074 | 11,022 | 145,920 | **7.65%** |
| VN821 | 39,846 | 490 | **0** | 39,356 | 1.23% |
| **Total** | **2,166,568** | **27,221** | **14,237** | **2,125,110** | **1.91%** |

> **Insights:**
> - **BKD1 chỉ 0.27% committed** — phù hợp logic vì 85% inventory là EQUIPMENT (966K/1.13M) → equipment không cần allocate cho đơn
> - **NKD và VN831 có % Committed cao nhất (7%)** — kho busy, đang được dùng nhiều cho fulfillment
> - **3 warehouses (BKD2, VN831, VN821) có 0 picked** — hoặc chưa có lệnh pick today, hoặc workflow khác
> - **Q4 PRD `[TBD]`** confirmed: cần expose Allocated/Picked/Available cards Phase 1 cho user thấy real availability

**J. Top brand × warehouse concentrations (DRY + FRESH only)**

| # | Warehouse | Brand | Σ CSE |
|---:|---|---|---:|
| 1 | **BKD3** | **Oreo** | **194,588** ⭐ biggest single position |
| 2 | BKD1 | Oreo | 62,507 |
| 3 | VN831 | Cosy | 60,564 |
| 4 | NKD | Oreo | 60,215 |
| 5 | BKD2 | Cosy | 58,222 |
| 6 | VN831 | Oreo | 54,940 |
| 7 | BKD2 | Solite | 42,357 |
| 8 | NKD | Cosy | 41,992 |
| 9 | VN831 | Solite | 39,385 |
| 10 | BKD1 | Cosy | 32,447 |

> **Insights:**
> - **Oreo + Cosy + Solite** = top 3 brands, hiện diện ở **6/6 warehouses** (well-distributed)
> - **BKD3 Oreo concentration** = 194K CSE (4× lớn hơn next biggest single position) — single point of failure risk?
> - **VN831 (3PL) đang nắm hàng đáng kể**: Cosy 60K + Oreo 55K + Solite 39K = 155K real product CSE — cần xác định 3PL contract scope
> - "Other" brand không xuất hiện top 20 (vì query lọc DRY+FRESH only, "Other" có thể là EQUIPMENT/non-categorized)

**K. Edge cases verified (no anomalies)**

| Check | Count |
|---|---:|
| Negative `qty_cse` | 0 |
| Negative `qty_pl` | 0 |
| Negative `qty_cbm` | 0 |
| Negative `qty_allocated_cse` | 0 |
| Negative `qty_picked_cse` | 0 |
| Negative computed `available_cse` | **0** |
| `qty = 0` | **0** (DDL filter `qty > 0` hoạt động đúng) |
| Total rows | 82 |

✅ **Data quality khá tốt** — không có giá trị âm hoặc qty=0 (DDL filter `qty > 0` enforce). Available CSE = qty - allocated - picked không bao giờ âm trên data hiện tại.

### 5.7 Color coding

| Trạng thái | Màu | Áp dụng |
|---|---|---|
| Cargo group segments | Default Recharts palette | Pie chart |
| Warehouse stacks | Default per-cargo color | Stacked bar |
| Top brand bars | Default | Top product groups |

> **Bỏ** các status fictional trong spec cũ (Optimal/Good/Needs Adjustment/Critical, CSE Blue / PL Orange / Mixed Purple) — không có data nguồn cho "space efficiency", "optimal mix".

---

## 6. Out of Scope

| # | Hạng mục | Lý do |
|---|---|---|
| OOS-1 | Space utilization (% used / total) | MV không track total location capacity |
| OOS-2 | Inventory value (VND) | MV không có price data |
| OOS-3 | Optimal mix recommendation (CSE vs Pallet ideal ratio) | Out of scope MVP — có thể là Phase 2 |
| OOS-4 | Date filter (snapshot history) | MV refresh ghi đè, không có time series |
| OOS-5 | Stock movement / transactions | Thuộc feature Transaction Move |
| OOS-6 | Aging analysis (FIFO/FEFO) | Cần data `lottable04` (batch date) — không expose qua MV này |
| OOS-7 | Forecast tồn cuối tháng | Thuộc OTC View / DOW-weighted forecast |
| OOS-8 | Mobile responsive | MVP chỉ desktop |

---

## 7. Decisions Log

| ID | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Source data | ✅ `mv_stocktype` (KHÔNG dùng `mv_test_stocktype`) | Verified prod MV |
| D2 | API design | ✅ Option B (1 endpoint, raw rows + UI aggregate) | MV chỉ 82 rows |
| D3 | Filter date | ❌ **Bỏ** — MV là snapshot không có time | Match reality |
| D4 | Filter Storer | ❌ **Bỏ khỏi UI** — chỉ 1 value `MDLZ` | Match reality |
| D5 | Refresh cadence | ✅ 1 giờ | Per MV definition |
| D6 | Empty group fallback | ✅ `'Unclassified'` | SQL `coalesce` |
| D7 | KPI card list | ✅ 5 cards (CSE/PL/MasterUnits/CBM/TON) theo wireframe | Match SQL queries |

### Decisions đã đóng sau live data audit (2026-05-07)

| ID | Decision | Resolution |
|---|---|---|
| ~~Negative values check~~ | Có giá trị âm không? | ✅ **CLOSED** — verified 0 negative trên 82 rows |
| ~~Zero qty check~~ | DDL filter `qty > 0` hoạt động? | ✅ **CLOSED** — 0 rows có qty=0 |
| **Q4 (UI Allocated/Picked)** | Phase 1 có expose không? | ⚠️ **STRONGLY RECOMMENDED** — verified per-warehouse data có ý nghĩa: NKD 7.65%, VN831 7.02%, BKD1 chỉ 0.27% (do equipment dominate). User cần thấy "Available" để biết hàng thực sự sell-able |
| **Q1 (EQUIPMENT)** | Loại khỏi KPI? | ⚠️ **VERIFIED CRITICAL** — 86% Total Pallet thực ra là empty pallets! Total CSE bị skew 48%. Total CBM OK (99% real). Pattern verified bằng `cse_per_pl ≈ 1` AND `cbm_per_pl ≈ 0` |

### Decisions còn `[TBD]` (sau live audit)

| ID | Decision | Khi nào cần | Verified data |
|---|---|---|---|
| **Q1 critical** | KPI default có loại EQUIPMENT/TEST/PM không? Đề xuất: 🟢 **Có**, dùng `WHERE coalesce(group_of_cargo, '') NOT IN ('EQUIPMENT', 'TEST', 'PM')` làm default; user toggle "Include all" cho audit/full view | Trước Phase 1 — BA + WH manager | Real product CSE = 1,123,845 (52% của 2.17M) |
| **Q2 critical** | TEST cargo (66K CSE, 65K PL, 0 CBM) — DA exclude ở MV hay UI default? Đề xuất: **MV exclude** (cleanest) | Trước Phase 1 — DA | Verified 0 CBM → 100% test/junk |
| **Q3** | "Other" brand chiếm 55% (1.2M CSE) — phần lớn là EQUIPMENT có thể? Cần check `brand × cargo` cross-tab | Phase 2 — Master data team | "Other" KHÔNG xuất hiện top 20 DRY+FRESH brands → chủ yếu thuộc EQUIPMENT/non-product |
| **Q5** | Backend dùng `mv_stocktype` hay `mv_test_stocktype`? | Pending DA + Backend | Verified schema mismatch (Decimal vs Float64) |
| **Q6** | Goals & Success Metrics target số cụ thể | Stakeholder | — |
| **Q7** | UI warning "Cập nhật lúc HH:mm" cho refresh 1h không? | UX | Refresh verified hoạt động đúng |
| **Q8 (mới)** | BKD3 Oreo concentration 194K CSE (4× next biggest) — single point of failure risk hay business pattern bình thường? | Phase 2 — Risk team | Verified concentration |
| **Q9 (mới)** | 3 warehouses (BKD2, VN831, VN821) có 0 picked CSE — workflow normal hay bug? | Trước Phase 1 — Ops verify | Verified 0 picked at 3 wh |
| **Q10 (mới)** | VN831 (3PL) nắm 155K real product CSE — 3PL contract scope cần audit không? | Phase 2 — Logistics + Legal | Verified |

---

## 8. Data Quality Risks (post live audit 2026-05-07 v2)

| # | Risk | Severity | Status sau live audit | Action |
|---|---|---|---|---|
| **Q1 KPI skew CSE** | EQUIPMENT (45%) + TEST (3%) + PM (<1%) = 48% Total CSE không phải hàng hóa thật | 🔴 **High** | ⚠️ Verified critical — pattern `cse_per_pl≈1, cbm_per_pl≈0` | Q1 default exclude trong KPI |
| **Q1 KPI skew Pallet** | **86% Total Pallet = empty pallets** (1,040K/1,209K) — KPI hiện tại misleading nghiêm trọng | 🔴 **CRITICAL** | ⚠️ Verified critical | Cần fix Phase 1 |
| **Q2 TEST cargo violation** | TEST 66K CSE / 65K PL, CBM=0 → vi phạm CLAUDE Rule 3 | 🟡 Medium | ⚠️ Verified | DA exclude ở MV (cleanest) |
| ~~Negative values~~ | Có giá trị âm không? | 🟢 Low | ✅ **CLOSED** — 0 negative trên 82 rows | None |
| ~~Zero qty~~ | DDL filter qty>0? | 🟢 Low | ✅ **CLOSED** — 0 rows | None |
| Q3 | NULL `group_of_cargo` 17% rows | 🟢 Low | Verified | UI fallback OK; DA cải thiện SKU map |
| Q4 | "Other" brand 55% — phần lớn thuộc EQUIPMENT (verified KHÔNG xuất hiện top 20 DRY+FRESH brands) | 🟡 Medium | ⚠️ Verified — "Other" likely = equipment items | Master data team review |
| Q5 | `mv_stocktype` vs `mv_test_stocktype` schema mismatch | 🟡 Medium | Verified | Backend dùng đúng `mv_stocktype` |
| Q6 | Param `storer` redundant | 🟢 Low | Verified — DDL hardcoded MDLZ | Bỏ khỏi UI |
| Q7 | `is_deleted = 0` | 🟢 Low | ✅ **Verified ở DDL** | None |
| **Q8 (mới)** | BKD3 single position Oreo 194K CSE (4× next biggest) | 🟡 Medium | ⚠️ Verified concentration | Risk team review |
| **Q9 (mới)** | 3 wh (BKD2, VN831, VN821) có 0 picked CSE | 🟡 Medium | ⚠️ Verified | Ops workflow check |
| **Q10 (mới)** | VN831 (3PL) nắm 155K real product CSE | 🟢 Low | Verified | 3PL contract audit Phase 2 |

---

## 9. Release Plan

### Phase 1 — MVP

- ✅ MV `mv_stocktype` đã có
- ✅ Spec rewrite hoàn thành (v2 — aligned với code+MV)
- ✅ Folder rename `%_stock-type → stock-type` (git tracking restore)
- 🔲 **BA confirm Q1** (EQUIPMENT/TEST/PM scope) — **launch blocker**
- 🔲 **DA fix Q2** (exclude TEST cargo ở MV)
- 🔲 **DA + Backend verify Q5** (mv_stocktype vs mv_test_stocktype)
- 🔲 **Ops verify Q9** (3 wh có 0 picked CSE — workflow normal hay bug?)
- 🔲 UI bỏ filter Storer (D4)
- 🔲 UI hiển thị "Cập nhật lúc HH:mm" (Q7)
- 🔲 Stakeholder confirm Q6 (success metrics target)

### Phase 2 — Post-MVP

- Allocated/Picked/Available card (Q4)
- Top brand drill-down per warehouse
- Snapshot history (cần build time-series MV mới)
- Aging analysis (FIFO/FEFO)

### Phase 3 — Future

- Inventory value (VND, cần price master)
- Optimal mix recommendation
- Forecast tồn cuối tháng (kết hợp OTC View)

---

## 10. Open Questions

> **Note ID convention:** Q1–Q10 IDs đồng nhất giữa §7 (Decisions Log), §8 (Risks), và §10 (Open Questions). Same ID = same topic, viewed from 3 angles. Storer filter đã được quyết định trong D4 (§7 Decisions Log) — không phải Open Question.

### Phase 1 launch blockers (cần resolve trước launch)

1. **Q1 BA (CRITICAL)**: EQUIPMENT (45% CSE) + TEST (3%) + PM (<1%) = 48% Total CSE và **86% Total Pallet** không phải hàng hóa thật. Có loại khỏi default KPI không? Đề xuất: default exclude, thêm toggle "Include all".
2. **Q2 DA (CRITICAL)**: TEST cargo (66K CSE ở BKD3) — exclude ở MV (`WHERE category != 'TEST'`) hay UI default filter?
3. **Q5 DA + Backend**: Code C# dùng `mv_stocktype` hay `mv_test_stocktype`? Schema mismatch verified (Decimal vs Float64). Same pattern as Transaction Move BUG-3.
4. **Q9 Ops** (mới): 3 warehouses (BKD2, VN831, VN821) có **0 picked CSE** — workflow normal hay bug pipeline?
5. **Q6 Stakeholder**: Goals & Success Metrics target số cụ thể (DAU, latency, time-saved) chưa confirm.
6. **Q7 UX**: UI có cần hiển thị "Cập nhật lúc HH:mm" cho refresh delay 1h không?

### Phase 2 candidates

7. **Q3 Master Data**: "Other" brand chiếm 55% (1.2M CSE) — phần lớn là EQUIPMENT (verified KHÔNG xuất hiện top 20 DRY+FRESH brands). SKU master mapping cần cải thiện như thế nào?
8. **Q4 UI**: Allocated/Picked/Available cards (3 thêm Phase 1) hay Phase 2? *(Live audit recommend Phase 1 — verified per-warehouse data có ý nghĩa)*
9. **Q8 Risk Team**: BKD3 Oreo concentration 194K CSE (4× next biggest single position) — single point of failure risk hay business pattern bình thường?
10. **Q10 Logistics + Legal**: VN831 (3PL) nắm 155K real product CSE — 3PL contract scope cần audit không?

---

## 11. Cross-references

- Spec: `docs/02-features/stock-type/stock-type.spec.md` *(✅ rewritten v2)*
- Wireframe: `docs/02-features/stock-type/stock-type.wireframe.md` *(✅ aligned)*
- Audit results:
  - S2 Pipeline: `docs/audit-results/s2-stock-type-20260507.md`
  - S1 Final review: `docs/audit-results/s1-stock-type-final-20260507.md`
- SQL Registry: `docs/03-engineering/sql-registry.md` § "stock type - verified" (3120–3942)
- DDL: `docs/03-engineering/data-sources/clickhouse-ddl/analytics-workspace_mvs.md`
  - `mv_stocktype` (line 8416) — prod
  - `mv_test_stocktype` (line 8905) — test (different schema)
- Code:
  - UI: `control-tower/ui/src/views/control-tower/efficiency/StockTypeView.tsx`
  - API: `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs`
- GLOSSARY: `docs/GLOSSARY.md`
