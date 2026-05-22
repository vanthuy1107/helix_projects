# Spec – Stock Type (Inventory by Product Group)

**UI:** `control-tower/ui/src/views/control-tower/efficiency/StockTypeView.tsx`
**API:** `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs` (lines 184–216)
**Wireframe:** `docs/02-features/stock-type/stock-type.wireframe.md`
**Data source:** `analytics_workspace.mv_stocktype` (ClickHouse, refresh **EVERY 1 HOUR**, snapshot pattern — không có time dimension)

---

## 1. Overview

Màn hình giám sát **tồn kho hiện tại** của Mondelez Vietnam, breakdown theo:
- **Warehouse** (BKD1/BKD2/BKD3/NKD/VN821/VN831)
- **Cargo group** (DRY / FRESH / EQUIPMENT / POSM/OFFBOM / PM / TEST / NULL)
- **Brand** (Oreo, Cosy, Solite, AFC, Slide, KD, RITZ, Lu, Tết, Other)

Mỗi cell hiển thị tồn theo 5 đơn vị (PCE/CBM/Ton/CSE/Pallet) + 2 metrics phụ (Allocated, Picked).

Định nghĩa KPI chuẩn: xem `stock-type.prd.md` § 5.6 "Business Logic Specification".

---

## 2. API Endpoints

### 2.1 Single endpoint

| Function | API Path | Return Type | Mô tả |
|---|---|---|---|
| `fetchStockType` | `GET /api/ctower/stock-type?whseid=&cargo=&brand=&storer=` | `StockTypeRow[]` | Toàn bộ rows sau filter; UI tự aggregate KPI + charts |

**Params:** `{ whseid?, cargo?, brand?, storer? }`
- Default tất cả = `'ALL'`
- KHÔNG có date filter (MV là snapshot)
- `storer` redundant (DDL hardcoded `MDLZ`) — UI có thể bỏ

**Export:** `POST /api/ctower/stock-type/export` — body `ExportRowsRequest`.

### 2.2 DTO shape (per row)

```ts
StockTypeRow = {
  // Dimensions (4):
  WHSEID: string,
  group_of_cargo: string,
  brand: string,
  storer_key: string,

  // Total inventory (5 metrics):
  qty: number,           // master units (PCE/EA)
  qty_cbm: number,
  qty_ton: number,
  qty_cse: number,       // Case (thùng)
  qty_pl: number,        // Pallet

  // Allocated (5 metrics — đã phân bổ cho đơn):
  qty_allocated, qty_allocated_cbm, qty_allocated_ton,
  qty_allocated_cse, qty_allocated_pl,

  // Picked (5 metrics — đã pick chờ ship):
  qty_picked, qty_picked_cbm, qty_picked_ton,
  qty_picked_cse, qty_picked_pl,
}
```

> API chỉ trả ~82 rows max → fetch all an toàn, UI aggregate client-side cho KPI cards + pie/bar charts.

---

## 3. State Management

| State | Type | Default | Mô tả |
|---|---|---|---|
| `rows` | `StockRow[]` | `[]` | Toàn bộ data từ API (~82 rows) |
| `isLoading` | `boolean` | `true` | Loading state |
| `loadError` | `string \| null` | `null` | Lỗi fetch API |
| `warehouse` | `string` | `''` | Filter chính (empty = no filter) |
| `groupFilter` | `string` | `''` | Filter cargo group |
| `brandFilter` | `string` | `''` | Filter brand |
| `unit` | `'qty_cse' \| 'qty_pl'` | `'qty_cse'` | UOM toggle (chỉ 2 options) |
| `detailGroupFilter` | `string` | `''` | Filter cargo cho detail tab |
| `detailBrandFilter` | `string` | `''` | Filter brand cho detail tab |
| `detailWarehouseFilter` | `string` | `''` | Filter warehouse cho detail tab |
| `detailSearch` | per-column object | empty strings | Search per column |
| `detailSort` | `SortState<keyof StockRow>` | `{ key: null, direction: 'none' }` | Sort 3-state |
| `exportModal` | `{ … } \| null` | `null` | Export dialog state |

> **Pattern khác Transaction Move/OTIF:** Stock Type **không có Draft → Apply pattern**. Filter thay đổi → re-render UI ngay (client-side filter). Chỉ fetch 1 lần khi mount.

---

## 4. Filters & Inputs

### 4.1 Filter chính (Tab Chart)

| Filter | Loại UI | Options | Cột MV / Param |
|---|---|---|---|
| **Warehouse** | Single-select dropdown | `'ALL'` + 6 wh hardcoded (BKD1/BKD2/BKD3/NKD/VN821/VN831) | `whseid` |
| **Cargo group** | Single-select dropdown | `'ALL'` + dynamic từ data | `cargo` → `group_of_cargo` |
| **Brand** | Single-select dropdown | `'ALL'` + dynamic từ data | `brand` |
| **UOM toggle** | Radio button | `[● CSE]` / `[○ Pallet]` (chỉ 2 options) | `unit` (state UI) → SUM(qty_cse) hoặc SUM(qty_pl) |

> UOM toggle chỉ ảnh hưởng **cách hiển thị aggregation**, không filter rows.

### 4.2 Filter table (Tab Detail)

3 filter override + per-column search:
- `detailWarehouseFilter`, `detailGroupFilter`, `detailBrandFilter`
- `detailSearch` per cột

> Detail filter là **client-side override** — không refetch API.

---

## 5. Derived / Computed Data

| Item | Mô tả |
|---|---|
| `kpiCards` | Aggregate `rows` → 5 numbers: `SUM(qty_cse) / SUM(qty_pl) / SUM(qty) / SUM(qty_cbm) / SUM(qty_ton)` |
| `pieByCargoGroup` | `GROUP BY group_of_cargo SUM(qty_cse hoặc qty_pl)` (theo `unit`) |
| `stackedByWarehouse` | `GROUP BY whseid, group_of_cargo SUM(qty_cse hoặc qty_pl)` |
| `topProductGroups` | `GROUP BY group_of_cargo ORDER BY SUM(qty_cse|qty_pl) DESC LIMIT N` |
| `detailFiltered` | Apply 3 detail filters + per-column search trên `rows` |
| `detailSorted` | Apply `detailSort` lên rows đã filter |

> Tất cả aggregation **client-side** trên 82 rows.

---

## 6. Business Logic Rules

> **Source of truth**: `analytics_workspace.mv_stocktype`. Logic chi tiết tại PRD § 5.6 "Business Logic Specification". Verified với 82 rows tại 2026-05-07.

### 6.1 Built-in filters tại MV (DDL hardcoded)

| Filter | Giá trị | Lý do |
|---|---|---|
| `storer_key` | `'MDLZ'` only | MV chỉ track inventory MDLZ |
| `whseid` | `IN ('BKD1','BKD2','BKD3','NKD','VN821','VN831')` | 6 kho production |
| `qty > 0` | bắt buộc | Loại tồn = 0 |
| `is_deleted = 0` | ✅ CLAUDE Rule 1 | Verified |
| Exclude `(NKD, sku IN ('LOSCAM','BACHTHUAN'))` | hardcoded | Pallet rỗng không thuộc MDLZ |

### 6.2 Công thức KPI

```sql
-- 5 KPI cards (toàn rows sau filter UI)
total_inv_cse  = SUM(qty_cse)
total_inv_pl   = SUM(qty_pl)
master_units   = SUM(qty)
total_qty_cbm  = SUM(qty_cbm)
total_qty_ton  = SUM(qty_ton)

-- Per-row CSE/PL conversion (đã tính ở MV upstream)
qty_cse = CEIL(SUM(QTY / NULLIF(masterunit_per_cse, 0)))   -- per SKU × BATCH × KHO, rồi SUM
qty_pl  = CEIL(SUM(QTY / NULLIF(masterunit_per_pallet, 0)))
qty_cbm = SUM(QTY * cbm_per_masterunit)
qty_ton = SUM(QTY * kg_per_masterunit / 1000)

-- Pie by cargo group
pct_cargo = SUM(qty_<unit>) / SUM_TOTAL(qty_<unit>) × 100

-- Stacked bar by warehouse
SELECT whseid, group_of_cargo, SUM(qty_<unit>) GROUP BY 1, 2

-- Top product groups
SELECT group_of_cargo, SUM(qty_<unit>) GROUP BY 1 ORDER BY 2 DESC LIMIT N

-- (Phase 2) Commitment metrics
allocated = SUM(qty_allocated_<unit>)
picked    = SUM(qty_picked_<unit>)
available = SUM(qty_<unit> - coalesce(qty_allocated_<unit>, 0) - coalesce(qty_picked_<unit>, 0))
pct_committed = (allocated + picked) / nullIf(total, 0)
```

> **Lưu ý ceil per-batch**: `qty_cse` ở mỗi row là tổng `CEIL` per SKU×BATCH×KHO, **không** phải `CEIL` của tổng `SUM(QTY)`. Có thể lệch nhẹ (1–2 CSE) so với phép quy đổi 1 lần. Đây là behavior pre-aggregate ở upstream.

### 6.3 UOM mapping

| UI toggle | UI state | Aggregation column |
|---|---|---|
| `CSE` | `unit = 'qty_cse'` | `SUM(qty_cse)` |
| `Pallet` | `unit = 'qty_pl'` | `SUM(qty_pl)` |

> **Khác Transaction Move:** Stock Type chỉ có 2 UOM (CSE + Pallet) — không có TON/CBM/PCE toggle. Volume CBM/TON hiển thị **riêng** trong KPI cards (không qua toggle).

### 6.4 Filter Behavior (SQL backend)

```sql
WHERE 1=1
  AND (p_whse  = 'ALL' OR whseid = p_whse)
  AND (p_cargo = 'ALL' OR coalesce(group_of_cargo, 'Unclassified') = p_cargo)
  AND (p_brand = 'ALL' OR brand = p_brand)
  AND (p_storer = 'ALL' OR storer_key = p_storer)   -- redundant (MV chỉ MDLZ)
```

UI gửi `''` (empty) → backend interpret thành `'ALL'` (no filter).

---

## 7. Color / Status Coding

| Element | Màu | Áp dụng |
|---|---|---|
| Cargo group segments | `COLORS = ['#a78bfa', '#60a5fa', '#34d399', '#fbbf24', '#f472b6', '#fb7185']` (6 colors palette) | Pie chart |
| Warehouse stacks | Color cycle | Stacked bar |
| Top brand bars | Color cycle | Top product groups |

> **Bỏ** các status fictional trong spec cũ (Optimal/Good/Needs Adjustment/Critical, CSE Blue / PL Orange / Mixed Purple) — không có data nguồn cho "space efficiency", "optimal mix".

---

## 8. User Interactions

| Tương tác | Hành động |
|---|---|
| Mount component | `fetchStockType()` 1 lần (no draft pattern) |
| Đổi Warehouse / Cargo / Brand | Update state → re-render aggregate (client-side, no refetch) |
| Đổi UOM toggle | Update `unit` state → re-aggregate (client-side) |
| Đổi Tab (Chart / Detail) | Toggle giữa 2 view |
| Hover chart | Tooltip Recharts |
| Click info icon `[?]` | Hiển thị `ExplainHint` tooltip công thức |
| Sort table column | `nextSortState` toggle desc → asc → none |
| Search column | Per-column input filter |
| Filter detail table | 3 dropdown override + per-column search (client-side) |
| Click **Export** | Mở `exportModal`, gọi `POST /stock-type/export` |

---

## 9. Sub-components

| Component | Vai trò |
|---|---|
| `ViewQueryExportActions` | Export + Query action bar |
| `ControlTowerItemCard` | KPI card per metric |
| `ExplainHint` (UiTooltip + FiHelpCircle) | Tooltip giải thích công thức |
| `LeftStickySectionTabs` | Tab navigation (Chart / Detail) |
| `SortableHeader` | Header với 3-state sort |
| Recharts: `PieChart`, `Pie`, `Cell` | Pie chart by cargo group |
| Recharts: `BarChart`, `Bar` (stacked) | Stacked bar by warehouse |
| Recharts: horizontal bar | Top product groups ranking |

---

## 9.1 Layout (theo wireframe)

### Tab "Chart"

```
┌─ Filter bar: Warehouse [All ▼] | Brand [All ▼] | UOM [● CSE / ○ Pallet] ──────┐
├─ Tab toggle: Chart | Detail
│
├─ 5 KPI cards (1 row hoặc 2 rows):
│   ┌── Total Inv CSE ──┐ ┌── Total Inv PLT ──┐ ┌── Master Units ──┐
│   │  2,166,568 [?]    │ │  1,209,093 [?]    │  │ 44,309,378 [?]    │
│   └───────────────────┘ └───────────────────┘ └───────────────────┘
│   ┌── Volume CBM ─────┐ ┌── Volume TON ─────┐
│   │  27,212 CBM [?]   │ │  3,485 TON [?]    │
│   └───────────────────┘ └───────────────────┘
│
├─ Chart 1: "Inventory by Product Group" — pie chart % theo cargo (6 cargos)
├─ Chart 2: "Inventory by Warehouse (Stacked)" — stacked bar mỗi wh stack theo cargo
└─ Chart 3: "Top Product Groups" — horizontal bar top N theo `unit`
```

### Tab "Detail"

```
├─ Filter bar (giống Tab Chart) — applied filters
├─ Detail table override filters:
│     Warehouse ▼ | Cargo ▼ | Brand ▼ | (per-column search trong header)
│
└─ Bảng "Inventory Detail"
      Cột: Warehouse | Cargo | Brand | Storer | qty | qty_cbm | qty_ton |
            qty_cse | qty_pl | qty_allocated | qty_picked
      Sort 3-state, per-column search, Export button
      (~82 rows max — 1 page là đủ)
```

---

## 10. Loading & Error States

| Tình huống | Xử lý |
|---|---|
| Đang fetch API | `isLoading = true` → hiển thị skeleton |
| API error | `loadError != null` → banner error + empty UI |
| `rows = []` (filter quá hẹp) | KPI cards 0/0/0; pie/bar empty |
| Refresh delay 1h | UI nên show "Cập nhật lúc HH:mm" để user biết freshness |

---

## 11. Edge Cases

| # | Tình huống | Xử lý production |
|---|---|---|
| E1 | NULL `group_of_cargo` (14/82 rows = 17%) | UI hiển thị "Unclassified" hoặc segment riêng |
| E2 | NULL `brand` (4/82 rows) | UI hiển thị "Unclassified" |
| E3 | Tổng = 0 sau filter | KPI cards hiển thị 0; pie/bar empty |
| E4 | UOM toggle = `'qty_cse'` nhưng row có `qty_cse = 0` | SUM tính như 0; row không hiển thị trong top |
| E5 | EQUIPMENT cargo (45% CSE, qty_cbm≈0) | ⚠️ KPI gồm cả equipment → potentially misleading; **Q1 PRD `[TBD]`** |
| E6 | TEST cargo (66K CSE, qty_cbm=0) | ⚠️ Vi phạm CLAUDE Rule 3 → cần exclude (Q2 PRD) |
| E7 | "Other" brand (55% CSE) — catch-all bucket | ⚠️ SKU master mapping kém; Q3 PRD |
| E8 | Refresh delay 1h | Acceptable — daily ops, không cần realtime |
| E9 | UI hardcode 6 wh đầy đủ (khác Transaction Move chỉ 4) | ✅ Match MV — không có drift |
| E10 | Storer chỉ 1 value `MDLZ` | API filter redundant — UI nên bỏ |
| E11 | Decimal vs Float64 schema giữa `mv_stocktype` và `mv_test_stocktype` | UNION fail — backend phải dùng đúng `mv_stocktype` |
| E12 | Snapshot mismatch giữa 2 lần query liền kề (lệch refresh window) | Acceptable — user click Apply để refresh |

---

## 12. Workflow

### 12.1 Page Load Flow

```
Người dùng mở Stock Type View
  → fetchStockType({ whseid:'ALL', cargo:'ALL', brand:'ALL', storer:'ALL' })
  → isLoading=true → render skeleton
  → API trả ~82 rows (full MV sau MV-level filters)
  → setRows(data)
  → UI aggregate client-side: 5 KPI cards + 3 charts + detail table
```

### 12.2 Filter & Re-aggregate Flow (client-side, no refetch)

```
Người dùng đổi Warehouse / Cargo / Brand / UOM toggle
  → Update state ngay
  → useMemo re-compute aggregations
  → KPI cards + charts re-render
  → Detail table re-filter
  → KHÔNG fetch API lại
```

### 12.3 Detail Table Filter Flow

```
Trong tab Detail:
  → 3 detail filters (warehouse/cargo/brand) + 11 per-column search
  → Client-side filter trên rows
  → Sort + display
```

### 12.4 KPI Calculation (UI client-side)

```
Per UOM (CSE | Pallet):
  → total = rows.reduce((sum, r) => sum + r[unit], 0)

Pie by cargo:
  → groupBy(rows, 'group_of_cargo'), sum each group
  → pct = group_sum / total × 100

Stacked bar by warehouse:
  → groupBy(rows, ['whseid', 'group_of_cargo']), sum each cell

Top groups:
  → groupBy(rows, 'group_of_cargo'), sum, sort desc, take N
```

### 12.5 Error Handling Flow

```
fetchStockType() fail
  → setLoadError(message), setIsLoading(false)
  → UI hiển thị error banner
  → Charts/table empty state
  → User refresh page hoặc retry button
```

---

## 13. Data Quality Notes (cần DA / BA confirm)

| # | Vấn đề | Mức độ |
|---|---|---|
| Q1 | **EQUIPMENT cargo dominant 45% CSE** (qty_cbm ≈ 0) — likely empty pallets/forklifts | 🔴 High — KPI bị skew nếu gồm |
| Q2 | **TEST cargo 66K CSE** (BKD3 65K) — vi phạm CLAUDE Rule 3 | 🟡 Medium — cần exclude |
| Q3 | **"Other" brand 55%** — catch-all quá lớn | 🟡 Medium — Master data review |
| Q4 | NULL `group_of_cargo` 17% rows | 🟢 Low — UI fallback OK |
| Q5 | `mv_stocktype` vs `mv_test_stocktype` schema mismatch | 🟡 Medium — Backend verify |
| Q6 | Param `storer` redundant | 🟢 Low — UI bỏ filter này |
| Q7 | `is_deleted = 0` | ✅ Verified ở DDL |

---

## 14. Cross-references

- **PRD:** `docs/02-features/stock-type/stock-type.prd.md` (full Business Logic Spec § 5.6)
- **Wireframe:** `docs/02-features/stock-type/stock-type.wireframe.md`
- **GLOSSARY:** `docs/GLOSSARY.md`
- **SQL Registry:** `docs/03-engineering/sql-registry.md` § "stock type - verified" (lines 3120–3942)
- **DDL:** `docs/03-engineering/data-sources/clickhouse-ddl/analytics-workspace_mvs.md`
  - `mv_stocktype` (line 8416) — production
  - `mv_test_stocktype` (line 8905) — test (different schema, KHÔNG dùng)
- **Audit results:**
  - S2 Pipeline: `docs/audit-results/s2-stock-type-20260507.md`
- **Code:**
  - UI: `control-tower/ui/src/views/control-tower/efficiency/StockTypeView.tsx`
  - API: `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs:184–216`
  - Client: `control-tower/ui/src/api/stockTypeApi.ts`
