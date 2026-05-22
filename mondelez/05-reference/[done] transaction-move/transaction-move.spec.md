# Spec – Transaction Move

**UI:** `control-tower/ui/src/views/control-tower/efficiency/TransactionMoveView.tsx`
**API:** `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs` (lines 219–410)
**Wireframe:** `docs/02-features/transaction-move/transaction-move.wireframe.md`
**Data source:** `analytics_workspace.mv_movement_transaction` (UNION ALL của `mv_inbound_transaction_base` + `mv_outbound_transaction_base`, ClickHouse, refresh **EVERY 1 HOUR**)

---

## 1. Overview

Màn hình giám sát giao dịch nhập/xuất kho theo đơn vị (UOM) song song. Thuộc module **Control Tower → Efficiency (In-Inv-Out)**.

Trả lời 3 câu hỏi:
1. Tổng volume nhập/xuất là bao nhiêu (theo UOM được chọn) trong khoảng thời gian?
2. Phân bổ theo activity (Print DO, Xuất bán, Nhập xưởng, …) như thế nào?
3. So sánh giữa các kho (BKD1, BKD2, BKD3, NKD) ra sao?

Định nghĩa KPI chuẩn: xem `transaction-move.prd.md` § 5.6 "Business Logic Specification".

---

## 2. API Endpoints

**Params chung:** `{ warehouse?, dateType?, fromDate?, toDate?, measure?, activity? }`
- `warehouse` enum: `'ALL'` (default) | `'BKD1'` | `'BKD2'` | `'BKD3'` | `'NKD'`
- `measure` enum (UOM toggle): `'cse'` (default) | `'ton'` | `'cbm'` | `'pallet'` | `'pce'`
- `activity` enum: `'ALL'` (default) | 17 activities thực tế (xem §6.4)
- `fromDate, toDate` mandatory; default = today

### 2.1 Endpoints (6)

| Function | API Path | Return Type | Mô tả |
|---|---|---|---|
| `fetchTransactionMoveTotalPalletInbound` | `GET /api/ctower/transaction-move/total-pallet-inbound` | `{ totalPalletInbound: number }` | KPI riêng cho card "Total Pallet Inbound" |
| `fetchTransactionMoveKpiSummary` | `GET /api/ctower/transaction-move/kpi-summary` | `TransactionMoveKpiSummary` | KPI tổng (4 numbers) |
| `fetchTransactionMoveMovementReport` | `GET /api/ctower/transaction-move/movement-report` | `TransactionMoveMovementReportRow[]` | Detail table (có `rowLimit`) |
| `fetchTransactionMoveTrendCbmPallet` | `GET /api/ctower/transaction-move/trend-cbm-pallet` | `TransactionMoveTrendRow[]` | Trend by day |
| `fetchTransactionMoveInboundOutboundCbm` | `GET /api/ctower/transaction-move/inbound-outbound-cbm` | `TransactionMoveInboundOutboundCbmRow[]` | So sánh in/out theo ngày |
| `fetchTransactionMoveWarehouseComparison` | `GET /api/ctower/transaction-move/warehouse-comparison` | `TransactionMoveWarehouseComparisonRow[]` | So sánh tổng volume theo kho |

**Export:** `POST /api/ctower/transaction-move/export` — body `ExportRowsRequest`.

### 2.2 DTO shapes

```ts
TransactionMoveKpiSummary = {
  totalPalletInbound: number,    // Σ Pallet WHERE direction='INBOUND'
  totalCbmOutbound: number,      // Σ CBM WHERE direction='OUTBOUND'
  totalPrintDoOrders: number,    // Σ orders WHERE activity='Print DO'
  totalMovementRows: number      // count() sau filter
}

TransactionMoveTrendRow = { transactionDate, uom, totalVolume }

TransactionMoveInboundOutboundCbmRow = {
  transactionDate, inboundCbm, outboundCbm
}

TransactionMoveMovementReportRow = {
  transactionDate, warehouse, activities, uom,
  pce, cbm, ton, cse, pallet, orders, direction,
  // Filter echo (debug/audit fields):
  pWarehouse, pDateType, pFrom, pTo, pUom, pActivity
}

TransactionMoveWarehouseComparisonRow = { warehouse, totalVolume }
```

> **Note:** `MovementReportRow` echo lại 6 filter params (`pWarehouse, pDateType, pFrom, pTo, pUom, pActivity`) trong mỗi row — phục vụ debug/audit, không hiển thị trong table view bình thường.

---

## 3. State Management

| State | Type | Default | Mô tả |
|---|---|---|---|
| `prototypeUom` / `prototypeUomDraft` | `UomFilterValue` (`'cse' \| 'ton' \| 'cbm' \| 'pallet' \| 'pce'`) | `'cse'` | UOM toggle (Apply pattern) |
| `prototypeActivity` / `prototypeActivityDraft` | `string` | `'ALL'` | Filter activity |
| `prototypeWarehouse` / `prototypeWarehouseDraft` | `string` | `'ALL'` | Filter kho |
| `prototypeFromDate` / `prototypeFromDateDraft` | `string` | `todayDate` | Filter date from |
| `prototypeToDate` / `prototypeToDateDraft` | `string` | `todayDate` | Filter date to |
| `kpiSummaryApi` | `TransactionMoveKpiSummary` | 4 zeros | KPI từ API |
| `trendApiRows` | `TransactionMoveTrendRow[]` | `[]` | Trend data |
| `inboundOutboundApiRows` | `TransactionMoveInboundOutboundCbmRow[]` | `[]` | In/Out by day |
| `movementReportApiRows` | `TransactionMoveMovementReportRow[]` | `[]` | Detail table data |
| `warehouseComparisonApiRows` | `TransactionMoveWarehouseComparisonRow[]` | `[]` | Warehouse comparison |
| `isInboundApiLoading` | `boolean` | `false` | Loading state |
| `isApiUnavailable` | `boolean` | `false` | API error fallback |
| `detailDateFilter` | `string` | `''` | Search input cột Date trong table |
| `detailWarehouseFilter` | `string` | `'ALL'` | Filter cột Warehouse trong table |
| `detailActivityFilter` | `string` | `'ALL'` | Filter cột Activity trong table |
| `detailUomFilter` | `MetricUom \| 'ALL'` | `'ALL'` | Filter cột UOM trong table |
| `detailDirectionFilter` | `string` | `'ALL'` | Filter cột Direction trong table |
| `detailSearch` | per-column search object | empty strings | Search per column |
| `detailSort` | `SortState<…>` | `{ key: null, direction: 'none' }` | Sort 3-state |
| `exportModal` | `{ … } \| null` | `null` | State modal export |

---

## 4. Filters & Inputs

### 4.1 Filter chính (Tab Chart)

| Filter | Loại UI | Options | Cột MV / Param |
|---|---|---|---|
| **UOM toggle** | Radio button (5 options) | `CSE` (default) / `TON` / `CBM` / `PALLET` / `PCE` | `measure` → chọn metric column để SUM |
| **Activity** | Single-select dropdown | `'ALL'` + 17 activities (xem §6.4) | `activity` |
| **Warehouse** | Single-select | `'ALL'`, `'BKD1'`, `'BKD2'`, `'BKD3'`, `'NKD'` | `warehouse` |
| **Date Range** | Date picker (from–to) | mandatory | `fromDate`, `toDate` (`dateType` not used — chỉ 1 date column `transaction_date`) |

> ⚠️ **Drift cảnh báo:** UI hardcode 4 warehouses (`BKD1/2/3/NKD`) nhưng MV có 6 (thêm `VN821`, `VN831`). UI miss 554 rows (~0.9%) data.

### 4.2 Filter table (Tab Movement Detail)

7 filter override cho detail table (client-side, không trigger refetch):
- `detailDateFilter` (text search)
- `detailWarehouseFilter` (`ALL` + 6 wh từ data)
- `detailActivityFilter` (`ALL` + 17 activities)
- `detailUomFilter` (`ALL` + 5 UOMs)
- `detailDirectionFilter` (`ALL` + `INBOUND` + `OUTBOUND`)
- `detailSearch` per column

---

## 5. Derived / Computed Data

| Item | Mô tả |
|---|---|
| `kpiCards` | Map `kpiSummaryApi` → 3 cards (Pallet Inbound / CBM Outbound / Print DO Orders) |
| `trendChart` | Map `trendApiRows` → dual-axis line chart by transactionDate × uom |
| `inboundOutboundChart` | Map `inboundOutboundApiRows` → grouped bar by transactionDate |
| `warehouseChart` | Map `warehouseComparisonApiRows` → grouped bar Inbound vs Outbound per warehouse |
| `detailFiltered` | Apply 7 detail filters trên `movementReportApiRows` (client-side) |
| `detailSorted` | Apply `detailSort` lên rows đã filter |

---

## 6. Business Logic Rules

> **Source of truth**: `analytics_workspace.mv_movement_transaction`. Logic chi tiết tại PRD § 5.6 "Business Logic Specification". Verified với 60,217 rows tại 2026-05-07.

### 6.1 Direction (chỉ 2 giá trị)

| direction | Ý nghĩa | Distribution |
|---|---|---:|
| `INBOUND` | Nhập kho (từ xưởng / chuyển kho từ kho khác / NPP trả về / nhập POSM) | 26,792 (44.5%) |
| `OUTBOUND` | Xuất kho (bán / chuyển kho / xuất khẩu / xuất hủy / Print DO) | 33,425 (55.5%) |

> **KHÔNG có "Internal" direction** — internal warehouse transfers được track như INBOUND + OUTBOUND ở 2 kho khác nhau.

### 6.2 Công thức KPI

```sql
-- Tổng Volume Inbound (theo UOM toggle)
total_volume_inbound = SUM(CASE
    WHEN direction='INBOUND' THEN
        CASE
            WHEN UPPER(p_uom) = 'CSE'    THEN COALESCE(CSE, 0)
            WHEN UPPER(p_uom) = 'PCE'    THEN COALESCE(PCE, 0)
            WHEN UPPER(p_uom) = 'CBM'    THEN COALESCE(CBM, 0)
            WHEN UPPER(p_uom) = 'TON'    THEN COALESCE(Ton, 0)
            WHEN UPPER(p_uom) = 'PALLET' THEN COALESCE(Pallet, 0)
        END
    ELSE 0
END)

-- KPI Summary (4 numbers)
totalPalletInbound  = SUM(if(direction='INBOUND',  coalesce(Pallet, 0), 0))
totalCbmOutbound    = SUM(if(direction='OUTBOUND', coalesce(CBM, 0), 0))
totalPrintDoOrders  = SUM(orders) WHERE activity = 'Print DO'
totalMovementRows   = COUNT(*) sau filter

-- Trend by day
trendRow = SELECT transaction_date, p_uom AS uom, SUM(<metric>) AS totalVolume
           GROUP BY transaction_date

-- Inbound vs Outbound by day (chỉ CBM)
inOutRow = SELECT transaction_date,
                  SUM(if(direction='INBOUND',  coalesce(CBM, 0), 0)) AS inboundCbm,
                  SUM(if(direction='OUTBOUND', coalesce(CBM, 0), 0)) AS outboundCbm
           GROUP BY transaction_date

-- Warehouse comparison
whRow = SELECT warehouse, SUM(<metric_by_uom>) AS totalVolume
        GROUP BY warehouse
```

### 6.3 UOM mapping (filter param ↔ metric column)

| Filter param | Metric column | Đơn vị |
|---|---|---|
| `cse` (default) | `CSE` | Case (thùng) |
| `pce` | `PCE` | Piece / EA / masterunit |
| `cbm` | `CBM` | Cubic meter |
| `ton` | `Ton` | Tấn |
| `pallet` | `Pallet` | Pallet |

> **Naming inconsistency** với column `uom` row value (`CASE`/`TONS`/`CBM`/`PALLET`/`DO`) — không expose ra UI.

### 6.4 Activity Catalog (17 activities verified)

UI hardcode danh sách 17 activities trong `ACTIVITY_FILTER_OPTIONS`:

**OUTBOUND (9):**
1. `Xuất bán / Loading loose` *(MV: 1,262,258 orders)*
2. `Xuất chuyển kho / WH Transfer In-Ex`
3. `Xuất chuyển kho / WH Transfer In-In`
4. `Xuất hủy`
5. `Xuất chuyển kho trực tiếp từ xưởng`
6. `Xuất khẩu / Outbound loose from Prod`
7. `Xuất TĐX / Outbound copack` ⚠️ **UI có `Đ`; MV có `Xuất TDX` (D)** → bug filter
8. `Xuất POSM / Outbound POSM`
9. `Print DO`

**INBOUND (8):**
1. `Nhập xưởng / Inbound From Prod`
2. `Nhập copack`
3. `Nhập cont BKD / Nhập khẩu / Inbound loose`
4. `Nhập chuyển kho In-Ex / Warehouse transfer`
5. `Nhập chuyển kho In-In / Warehouse transfer`
6. `Nhập trả về từ NPP`
7. `Nhập POSM / Inbound POSM`
8. `Pallet shrink wrap` ⚠️ **UI rút gọn; MV có `Phí quấn màng co / Pallet shrink wrap`** → bug filter

> **2 bugs filter:** "Xuất TĐX" ↔ "Xuất TDX" (1 ký tự khác); "Pallet shrink wrap" ↔ "Phí quấn màng co / Pallet shrink wrap" (UI rút gọn). UI gửi value sai → query trả empty cho 2 activities này. **Fix:** dùng đúng MV value hoặc map ở backend.

### 6.5 Filter Behavior (SQL)

```sql
WHERE 1=1
  AND (p_warehouse = 'ALL' OR warehouse = p_warehouse)
  AND toDate(transaction_date) BETWEEN p_from AND p_to
  AND (p_activity = 'ALL' OR activity = p_activity)
  AND direction IN ('INBOUND', 'OUTBOUND')   -- LUÔN cố định
```

> **Direction filter hardcoded** — không có cách nào tắt direction filter qua API.

---

## 7. Color / Status Coding

| Trạng thái | Màu | Áp dụng |
|---|---|---|
| Inbound | 🟢 Green | Bar/legend "Inbound vs Outbound" + "Volume by Warehouse" |
| Outbound | 🟠 Orange | Bar/legend "Inbound vs Outbound" + "Volume by Warehouse" |
| Total | (theo theme) | KPI cards (không có threshold green/amber/red — chỉ là số tổng) |

> **Bỏ** các status fictional trong spec cũ (High/Normal/Low Activity, Internal Purple) — không có data nguồn.

---

## 8. User Interactions

| Tương tác | Hành động |
|---|---|
| Đổi UOM toggle | Cập nhật `prototypeUomDraft` |
| Đổi Activity / Warehouse / Date | Cập nhật draft state |
| Click **Apply** | `setPrototype<X>(draft)` → trigger Promise.all 6 fetch song song |
| Đổi Tab (Chart / Movement Detail) | Toggle giữa 2 view |
| Hover chart | Tooltip Recharts hiển thị chi tiết |
| Click info icon `[?]` | Hiển thị `ExplainHint` tooltip công thức |
| Sort table column | `nextSortState` toggle desc → asc → none |
| Search column | Per-column input filter (client-side) |
| Filter detail table | 7 dropdown override (client-side, không refetch) |
| Click **Export** | Mở `exportModal`, gọi `POST /transaction-move/export` |

---

## 9. Sub-components

| Component | Vai trò |
|---|---|
| `ViewQueryExportActions` | Export + Query action bar |
| `ControlTowerItemCard` | KPI card per metric |
| `ExplainHint` | Tooltip giải thích công thức (UiTooltip + FiHelpCircle) |
| `LeftStickySectionTabs` | Tab navigation (Chart / Movement Detail) |
| `SortableHeader` | Header với 3-state sort |
| Recharts: `LineChart`, `BarChart`, `Bar`, `Line` | Trend dual-axis, Inbound/Outbound bar, Warehouse comparison |

---

## 9.1 Layout (theo wireframe)

### Tab "Chart"

```
┌─ Filter bar: UOM toggle [CSE/TON/CBM/PALLET/PCE] | Activity | Warehouse | From/To | [Apply] ──┐
├─ Tab toggle: Chart | Movement Detail
│
├─ 3 KPI cards (1 row):
│   ┌── Total Pallet Inbound ──┐ ┌── Total CBM Outbound ──┐ ┌── Print DO (Orders) ──┐
│   │  8,450 PLT [?]           │ │  12,300 CBM [?]        │ │  1,850 SO [?]         │
│   └──────────────────────────┘ └────────────────────────┘ └───────────────────────┘
│
├─ Chart 1: "CBM & Pallet Trend by Day" — dual-axis line (CBM trên + Pallet dưới),
│           series theo warehouse × direction (BKD1●○ BKD2▪□ BKD3×÷ NKD◆◇)
├─ Chart 2: "Inbound vs Outbound CBM & CSE" — grouped bar by day
└─ Chart 3: "Volume by Warehouse" — grouped bar Inbound vs Outbound per warehouse
```

### Tab "Movement Detail"

```
├─ Filter bar (giống Tab Chart) — applied filters
├─ Detail table override filters (row 2):
│     Date search | Warehouse ▼ | Activity ▼ | UOM ▼ | Direction ▼
│
└─ Bảng "Movement Transactions"
      Cột: Tx Date | Whse | Activity | UOM | PCE | CBM | TON | CSE | Pallet | Orders | Direction
      Per-column search input, sort 3-state, pagination
```

---

## 10. Loading & Error States

| Tình huống | Xử lý |
|---|---|
| Đang fetch API | `isInboundApiLoading = true` → hiển thị skeleton |
| API error / unavailable | `isApiUnavailable = true` → hiển thị fallback UI hoặc empty data |
| `kpiSummaryApi` chưa load | Cards hiển thị 0/0/0/0 (default state) |
| Empty rows (filter quá hẹp) | Charts/table empty state |
| Refresh delay 1h | (PRD Q2) UI nên show "Cập nhật lúc HH:mm" |

---

## 11. Edge Cases

| # | Tình huống | Xử lý production |
|---|---|---|
| E1 | UI Activity `'Xuất TĐX'` không match MV `'Xuất TDX'` | Filter trả empty cho activity này | ⚠️ **BUG** |
| E2 | UI Activity `'Pallet shrink wrap'` không match MV `'Phí quấn màng co / Pallet shrink wrap'` | Filter trả empty | ⚠️ **BUG** |
| E3 | UI hardcode 4 wh (BKD1/2/3/NKD); MV có 6 (thêm VN821, VN831) | Filter `'ALL'` vẫn lấy hết; filter cụ thể wh VN8xx **không có UI option** |
| E4 | UOM = `'PCE'` nhưng row PCE NULL | `coalesce(PCE, 0)` → 0 |
| E5 | NULL `category_converted` (184/60K = 0.3%) | Không filter; UI hiển thị blank |
| E6 | Activity 'Print DO' có UOM = 'DO' (không thuộc 5 UOM toggle) | Print DO orders dùng `SUM(orders)` riêng, không qua UOM toggle |
| E7 | Date range không có data | Trả empty; UI 0s |
| E8 | Date range vượt MV refresh window (1 giờ) | User thấy data lag tối đa 1h |
| E9 | Direction filter = 'Internal' (UI cũ) | KHÔNG có direction này; UI mới đã bỏ |
| E10 | Same activity tracked ở cả INBOUND + OUTBOUND (e.g. WH Transfer In-In) | Đó là 2 phía của 1 chuyển kho — đếm như 2 transactions riêng |
| E11 | API timeout / 5xx | `isApiUnavailable = true`; UI fallback empty + retry button |
| E12 | Refresh 1h delay | Có thể stale tới 1 giờ vs realtime SAP |
| E13 | UI `prototypeFromDate = prototypeToDate = today` (default) | Chỉ load data hôm nay (~170 rows); khuyến khích user mở rộng date range |
| E14 | Detail table có `pWarehouse, pDateType, pFrom, pTo, pUom, pActivity` columns | Filter echo từ API request — debug field, UI nên hide mặc định |

---

## 12. Workflow

### 12.1 Page Load Flow

```
Người dùng mở Transaction Move View
  → Khởi tạo default filter:
      uom='cse', activity='ALL', warehouse='ALL', from=today, to=today
  → Promise.all 6 fetch song song:
      - fetchTransactionMoveKpiSummary
      - fetchTransactionMoveTrendCbmPallet
      - fetchTransactionMoveInboundOutboundCbm
      - fetchTransactionMoveMovementReport (rowLimit)
      - fetchTransactionMoveWarehouseComparison
      (+ fetchTransactionMoveTotalPalletInbound nếu cần)
  → isInboundApiLoading=true → render skeleton
  → API trả KPI từ SQL aggregation trên mv_movement_transaction
  → Render 3 KPI cards + 3 charts + detail table
```

### 12.2 Filter & Apply Flow

```
Người dùng đổi UOM toggle / Activity / Warehouse / Date
  → Cập nhật prototype<X>Draft state
  → Click Apply Filters → setPrototype<X>(draft) trigger useEffect
  → Promise.all 6 API re-fetch
  → KPI tính lại trong SQL (không tính ở UI)
  → Charts + table cập nhật
```

### 12.3 Detail Table Filter Flow (client-side)

```
Người dùng đổi filter trong tab Movement Detail
  → 7 detail filters (date/wh/activity/uom/direction + search) update state
  → UI re-filter rows từ movementReportApiRows (client-side)
  → KHÔNG gọi API lại
  → Sort + pagination áp dụng trên rows đã filter
```

### 12.4 Error Handling Flow

```
Bất kỳ fetch nào failed
  → catch → setIsApiUnavailable(true)
  → Reset summary/trend/inOut/warehouse arrays = []
  → UI hiển thị fallback: empty cards + charts + "API unavailable" banner
  → User click Apply lại để retry
```

---

## 13. Data Quality Notes (cần DA verify)

| # | Vấn đề | Mức độ |
|---|---|---|
| Q1 | Upstream `is_deleted=0` chưa verify ở `mv_inbound_transaction_base`, `mv_outbound_transaction_base` | 🟡 Medium |
| Q2 | UI activity name mismatch (`Xuất TĐX` ↔ `Xuất TDX`, `Pallet shrink wrap` ↔ `Phí quấn màng co / Pallet shrink wrap`) | 🟡 Medium — 2 activities filter không hoạt động |
| Q3 | UI warehouse list (4) thiếu so với MV (6) — VN821, VN831 không có trong UI dropdown | 🟢 Low — chỉ 0.9% data; có thể do test data |
| Q4 | `Xuất hủy` activity (192 rows) — disposal hợp pháp hay cancelled? | 🟡 Medium — BA confirm scope |
| Q5 | SQL Registry references `mv_test_movement_transaction` (Redshift) thay vì `mv_movement_transaction` | 🔴 High — production code dùng MV nào? |
| Q6 | Refresh cadence 1 giờ — UI có warning data lag không? | 🟢 Low — UX |
| Q7 | NULL `category_converted` (0.3%) | 🟢 Low |

---

## 14. Cross-references

- **PRD:** `docs/02-features/transaction-move/transaction-move.prd.md` (Business Logic Spec § 5.6)
- **Wireframe:** `docs/02-features/transaction-move/transaction-move.wireframe.md`
- **GLOSSARY:** `docs/GLOSSARY.md`
- **SQL Registry:** `docs/03-engineering/sql-registry.md` § "sql query - transaction move - discuss" (lines 2793–3116)
- **DDL:** `docs/03-engineering/data-sources/clickhouse-ddl/analytics-workspace_mvs.md`
  - `mv_movement_transaction` (line 5378)
  - `mv_inbound_transaction_base`, `mv_outbound_transaction_base` (upstream)
- **Audit results:**
  - S2 Pipeline: `docs/audit-results/s2-transaction-move-20260507.md`
- **Code:**
  - UI: `control-tower/ui/src/views/control-tower/efficiency/TransactionMoveView.tsx`
  - API: `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs:219–410`
  - Client: `control-tower/ui/src/api/transactionMoveApi.ts`
