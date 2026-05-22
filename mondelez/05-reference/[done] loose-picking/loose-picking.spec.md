# Spec – Loose Picking View

**UI:** `control-tower/ui/src/views/control-tower/efficiency/LoosePickingView.tsx`
**API:** `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs`
**Wireframe:** `docs/02-features/loose-picking/loose-picking.wireframe.md`
**PRD:** `docs/02-features/loose-picking/loose-picking.prd.md`
**MV chính:** `analytics_workspace.mv_loose_picking_clickhouse` (refresh 1 HOUR)

---

## 1. Overview

Màn hình theo dõi tỷ lệ pick hàng lẻ (loose picking) vs full pallet trong vận hành kho. Mục tiêu giám sát: pick lẻ càng nhiều → fast outbound càng kém (impact cost per case, productivity, fill rate). Phạm vi: **post-shipment analysis** — chỉ trip đã `status_code='95'` (ShipCompleted).

---

## 2. API Endpoints

**Filter signature:** `LoosePickingFilter = { whseid?: string, fromDate: string, toDate: string }`

| Function | Parameters | Return Type | Mô tả |
|---|---|---|---|
| `fetchLoosePicking` | `LoosePickingFilter` | `LoosePickingRow[]` | Dữ liệu raw per (SO+SKU+batch) — group by SO ở client nếu cần |
| `fetchLoosePickingByWh` | `LoosePickingFilter` | `LoosePickingByWhRow[]` | Aggregate theo kho |
| `fetchLoosePickingBySku` | `LoosePickingFilter & { topN: number }` | `LoosePickingBySkuRow[]` | Top N SKU theo cse_loose (BE truyền `LIMIT topN` xuống SQL) |

**3 endpoints riêng biệt nhưng cùng query MV `mv_loose_picking_clickhouse`.**

---

## 3. State Management

| State | Type | Default | Mô tả |
|---|---|---|---|
| `dateRange` | `{ from: string, to: string }` | last 7 days | Khoảng thời gian (`actual_ship_date`) |
| `warehouseFilter` | `string` | `'ALL'` | Lọc theo kho |
| `pickingData` | `LoosePickingRow[]` | `[]` | Raw rows từ API |
| `summaryData` | `LoosePickingByWhRow[]` | `[]` | Per-warehouse summary |
| `topSkuData` | `LoosePickingBySkuRow[]` | `[]` | Top N SKU |
| `kpis` | `PickingKPIs` | `{}` | KPIs tổng hợp (Total Cases, Total Loose, Full Pallets, %Loose) |
| `loading` | `boolean` | `true` | Loading state |
| `error` | `string \| null` | `null` | Lỗi |
| `lastUpdated` | `string` | `''` | Thời gian cập nhật cuối |

---

## 4. Filters & Inputs

| Filter | Options | Áp dụng cho |
|---|---|---|
| Date Range | Date picker | Tất cả views |
| Warehouse | `ALL` + `BKD1, BKD2, BKD3, NKD, VN821, VN831` (UI dropdown). VN821/VN831 hiện 0 rows trong MV (BUG-2) — UI show empty state. | Tất cả views |
| Cargo Group | `ALL` + `FRESH, DRY, MOONCAKE, POSM/OFFBOM` (theo data thực) | Tất cả views (mới — chờ BE implement) |

**Period aggregation (daily/weekly/monthly):** UI tự gộp client-side, không có server query riêng.

---

## 5. Derived / Computed Data

| useMemo | Mô tả |
|---|---|
| `filteredData` | Áp dụng filters cho pickingData |
| `loosePercentage` | `SUM(cse_loose) / SUM(cse_full + cse_loose) × 100` (warehouse-aggregated, KHÔNG dùng row-level pct_loose_picking) |
| `topSkuByLoose` | Sắp xếp SKU theo `SUM(cse_loose)` DESC |

---

## 6. Business Logic Rules

### 6.1 Core formula (CSE-based)

Dựa trên cột pre-computed của MV `mv_loose_picking_clickhouse`:

```
cse_per_pallet = masterunit_per_pallet / masterunit_per_cse
number_of_full_pallets = FLOOR(SUM(SHIPPED CSE) / cse_per_pallet)
cse_full   = number_of_full_pallets × cse_per_pallet
cse_loose  = SUM(SHIPPED CSE) - cse_full

Total Cases = SUM(cse_full + cse_loose)
% Loose    = SUM(cse_loose) / SUM(cse_full + cse_loose) × 100
Full Pallets = SUM(number_of_full_pallets)
```

> **Đơn vị: CSE (case/thùng)**, KHÔNG phải Lines.
> **Note assumption:** MV dùng `MAX(cse_per_pallet)` per group — giả định 1 pack/SKU. Mondelez convention là 1 pack/SKU, anomaly nếu có >1.

### 6.2 Divide by zero

| Source | Behavior khi denominator = 0 |
|---|---|
| MV column `pct_loose_picking` | `nullIf(SHIPPED CSE, 0)` → trả NULL |
| SQL Registry queries | `CASE WHEN cse_full + cse_loose = 0 THEN 0 ELSE …` → trả 0 |

→ Inconsistency — UI nên dùng SQL aggregation (trả 0), không dùng MV column raw.

### 6.3 Hardcoded business filters (upstream MV)

| # | Rule | Source |
|---|---|---|
| 1 | `is_deleted = 0` | tất cả `dim_*` upstream |
| 2 | `orderdetail.storer_key = 'MDLZ'` | dim_orderdetail |
| 3 | `orders.status_code = '95'` (chỉ ShipCompleted) | dim_orders |
| 4 | `orderdetail.whseid IN ('BKD1','BKD2','BKD3','NKD','VN821','VN831')` | dim_orderdetail |
| 5 | Order types theo whseid: BKD1/2/3 IN ('01','240'); NKD IN ('01','07','08','09','240','XB2BMC','XTNPP') | dim_orders.type |
| 6 | `extern_order_key IS NOT NULL` | dim_orders |
| 7 | `pickdetail.is_deleted = 0` | dim_pickdetail |

> XB2BMC, XTNPP đều là đơn xuất bán (per Operations 2026-05-06).

### 6.4 Status badge cho %Loose KPI card (no SLA threshold)

| Range | Màu |
|---|---|
| < 30% | 🟢 Green |
| 30–40% | 🟡 Amber |
| > 40% | 🔴 Red |

> Thresholds **visual-only**, không dựa trên SLA cụ thể (Mondelez chưa định ngưỡng). Áp dụng cho warehouse-aggregated %Loose, KHÔNG cho row-level.

### 6.5 Color coding

| Trạng thái | Màu code |
|---|---|
| Full Case | 🟢 Green (UI spec) — đổi từ slate gray hiện tại |
| Loose Picking | 🟠 Amber `#F59E0B` |

---

## 7. Workflow

### 7.1 Page Load Flow

```
Người dùng mở Loose Picking View
  → Khởi tạo default filter: date = last 7 days, warehouse = "ALL"
  → fetchLoosePicking() + fetchLoosePickingByWh() + fetchLoosePickingBySku({topN:10}) gọi 3 endpoint song song
  → isLoading = true → hiển thị loading state
  → Render KPI cards (Total Cases / Total Loose / Full Pallets / % Loose), 
     stacked bar by warehouse, pie/donut, top 10 SKU, detail table 14 cột
```

### 7.2 Filter & Apply Flow

```
Người dùng thay đổi filter (date, warehouse, cargo group)
  → Cập nhật draft state
  → Click Apply → fetch 3 endpoints lại
  → UI cập nhật charts + table
  → Note: MV refresh 1 HOUR → data có thể trễ 1h
```

### 7.3 Loose Picking Analysis Flow

```
Hệ thống aggregate cse_full vs cse_loose:
  → %Loose = SUM(cse_loose) / SUM(cse_full + cse_loose) × 100 (theo warehouse)
  → Total Cases = SUM(cse_full + cse_loose)
  → Full Pallets = SUM(number_of_full_pallets)
  → Top SKU theo SUM(cse_loose) DESC
KPI badge color theo §6.4 thresholds.
```

### 7.4 Error Handling Flow

```
Bất kỳ fetch* nào thất bại
  → isLoading = false
  → Hiển thị error message
  → Charts/table hiển thị empty state
  → User chọn VN821 hoặc VN831 → empty state (vì MV chưa có data — BUG-2)
  → Retry bằng click Apply lại
```

---

## 8. Data Quality Notes

| Issue | Impact |
|---|---|
| **25% rows region empty** | 1.92M rows / 2,836 customer (chủ yếu WinMart/WinCommerce KA chain) không có region trong masterdata. Pivot by region sẽ thấy bucket "" lớn. |
| **86.7% rows có cse_full=0** | Grain per (SO+SKU+batch) thường nhỏ hơn 1 pallet → đa số rows là pure loose. **Không dùng row-level pct_loose_picking** — luôn aggregate. |
| **5,475 NULL cse_full/cse_loose** | SKU không có pack info (`masterunit_per_cse=0` hoặc `masterunit_per_pallet=NULL`) → division NULL propagate. Dùng `coalesce(... , 0)`. |
| **VN821/VN831 = 0 rows** | MV BUG-2 — DA pending fix. UI show empty state. |
| **Timezone UTC default** | `toDate()` không respect VN UTC+7. Đơn ship sau 17:00 UTC (00:00 VN ngày sau) bị tag ngày trước. Edge case nhỏ. |
| **MV refresh 1 HOUR** | Data có thể trễ 1h. Chấp nhận được vì feature là post-shipment analysis. |
| **3 MV duplicate variants** | `mv_loose_picking_clickhouse_phong_test` và `mv_test_loose_picking` chưa cleanup — DA pending xóa. |

---

## 9. Out of Scope (đã verify)

- **Picker filter / Picker performance** — MV không có cột picker, không track per-worker. (Pending B2 BA decision — defaulted bỏ.)
- **Picking Efficiency (Lines/hour) / Picking Accuracy** — không có time tracking và correctness data trong upstream.
- **Recommendation engine** ("đề xuất chuyển sang full case") — không build, UI read-only. (Pending B3 BA decision.)
- **Live in-progress monitoring** — feature chỉ post-shipment analysis (status_code='95').
- **Brand filter / Search SKU** — wireframe có nhưng không build (per BA decision B6).
- **Status thresholds Optimal/Balanced/Needs Optimization** — bỏ, chỉ dùng %Loose color badge §6.4.
- **ViewMode 3 (efficiency/comparison/optimization)** — bỏ, chỉ 1 view.

---

## 10. Audit Reference

- **S2 Data Pipeline Audit:** `docs/audit-results/s2-loose-picking-20260506.md` (5 BUGs + 19 missing/change points)
- **S1 BA Logic Check:** `docs/audit-results/s1-loose-picking-20260506.md` (8 internal contradictions + 14 edge cases)
