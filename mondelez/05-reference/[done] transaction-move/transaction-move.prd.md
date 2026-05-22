# PRD — Transaction Move

> **Status:** 🟡 Draft v1 (cần stakeholder confirm các điểm `[TBD]`)
> **Owner:** [TBD]
> **Last updated:** 2026-05-07
> **Reference docs:**
> - Spec: `docs/02-features/transaction-move/transaction-move.spec.md` *(⚠️ spec hiện tại lệch nặng — cần rewrite)*
> - Wireframe: `docs/02-features/transaction-move/transaction-move.wireframe.md` *(✅ aligned với SQL/MV)*
> - Audit results: `docs/audit-results/s2-transaction-move-20260507.md`

---

## 1. Overview

**Transaction Move** là dashboard giám sát giao dịch nhập/xuất kho theo đơn vị (UOM) song song, thuộc module **Control Tower → Efficiency (In-Inv-Out)**.

Feature trả lời 3 câu hỏi chính:
1. **Tổng volume nhập/xuất là bao nhiêu** (theo UOM được chọn) trong khoảng thời gian?
2. **Phân bổ theo activity** (Print DO, Xuất bán, Nhập xưởng, …) như thế nào?
3. **So sánh giữa các kho** (BKD1, BKD2, BKD3, NKD, VN821, VN831) ra sao?

Source: `analytics_workspace.mv_movement_transaction` — UNION ALL của `mv_inbound_transaction_base` + `mv_outbound_transaction_base`. Refresh **EVERY 1 HOUR**.

---

## 2. Problem Statement

### 2.1 Pain points

1. **Thiếu visibility tổng hợp** về giao dịch nhập/xuất theo các UOM khác nhau (CSE/PCE/CBM/TON/PALLET) — trước đây ops phải query SAP/WMS thủ công.
2. **Không có view so sánh kho** — manager khó đánh giá hiệu suất giữa BKD1 vs BKD2 vs NKD.
3. **Activity breakdown chưa thống nhất** — 17 loại activities (Nhập xưởng, Xuất bán, Print DO, Xuất hủy, …) cần grouping chuẩn để báo cáo định kỳ.
4. **Print DO orders** (1.42M đơn) là KPI riêng cho team customer service — cần track tổng đơn DO đã in.

### 2.2 Why now

- DA team đã chuẩn hoá pipeline `mv_movement_transaction` (60K rows, 4+ năm history) → đủ điều kiện build dashboard.
- Mondelez có nhu cầu báo cáo tuần/tháng cho 4 kho chính → tự động hoá thay Excel.

---

## 3. Target Users

| Persona | Vai trò | Tần suất | Use case |
|---|---|---|---|
| **Warehouse Manager** | Quản lý kho (BKD/NKD) | Daily / Weekly | So sánh hiệu suất kho, theo dõi total volume nhập/xuất |
| **Operations Coordinator** | Điều phối luồng hàng | Daily | Track Print DO orders, activity breakdown |
| **Logistics Analyst** | Phân tích xu hướng | Weekly / Monthly | Trend CBM/Pallet theo ngày, so sánh tháng |

---

## 4. Goals & Success Metrics

### 4.1 Business goals (đề xuất)

| Goal | Metric | Target |
|---|---|---|
| Tăng visibility tổng quan movement | DAU view | ≥ 2 lần/ngày/user |
| Rút ngắn báo cáo tuần WH | Giờ/tuần | < 30 phút (từ 2h Excel) |
| Cross-warehouse benchmark | Số WH manager dùng tab So sánh kho | 4/4 (100% kho chính) |

### 4.2 Product KPIs sau launch

- DAU/WAU
- Latency p95 các API (target < 2s)
- Refresh delay MV (target ≤ 1 giờ — `mv_movement_transaction` định nghĩa)

---

## 5. Functional Requirements

### 5.1 Filter bar (Must-have)

| FR | Mô tả |
|---|---|
| FR-F1 | 4 filter: **UOM toggle** (CSE/PCE/CBM/TON/PALLET), **Activity** (single-select), **Warehouse** (single-select), **Date Range** (from–to) |
| FR-F2 | UOM toggle radio button, default `CSE` |
| FR-F3 | Activity: `'ALL'` + 17 activities thực tế (xem §5.6.4) |
| FR-F4 | Warehouse: `'ALL'` + 6 kho thực tế (BKD1/BKD2/BKD3/NKD/VN821/VN831) |
| FR-F5 | Date Range mandatory; default = last 7 days |
| FR-F6 | Direction filter **fixed** = `IN ('INBOUND', 'OUTBOUND')` (chỉ 2 direction tồn tại) |

### 5.2 Tab "Chart" (Must-have)

| FR | Mô tả |
|---|---|
| FR-C1 | **3 KPI cards** (theo wireframe): Total Pallet Inbound / Total CBM Outbound / Print DO (Orders) |
| FR-C2 | Mỗi card có info icon `[?]` hiển thị tooltip công thức |
| FR-C3 | Chart "Trend CBM & Pallet by Day" — dual-axis line chart, theo warehouse + direction |
| FR-C4 | Chart "Inbound vs Outbound CBM by Day" — grouped bar |
| FR-C5 | Chart "Volume by Warehouse" — grouped bar (Inbound vs Outbound) |
| FR-C6 | Tất cả chart respect UOM toggle |

### 5.3 Tab "Movement Detail" (Must-have)

| FR | Mô tả |
|---|---|
| FR-T1 | Bảng raw transactions — cột: Tx Date, Whse, Activity, UOM, Volume |
| FR-T2 | Filter row table phụ: Date, Warehouse, Activity (override filter chính nếu cần) |
| FR-T3 | Sort 3-state per column |
| FR-T4 | Pagination 10–50 rows/page |
| FR-T5 | Export CSV/XLSX |

### 5.4 Data layer (Must-have)

| FR | Mô tả |
|---|---|
| FR-D1 | Source: `analytics_workspace.mv_movement_transaction` |
| FR-D2 | Refresh cadence: **1 giờ** (chậm hơn flash/otif 12x). UI **nên hiển thị "Cập nhật lúc HH:mm"** để user biết data lag |
| FR-D3 | KPI tính trong SQL/MV (single source of truth) |
| FR-D4 | Direction filter cố định `IN ('INBOUND', 'OUTBOUND')` |

### 5.5 API Endpoints

5 endpoints (theo spec hiện tại):

| Function | SQL Registry section | Mô tả |
|---|---|---|
| `fetchTransactionMoveKpiSummary` | "Tổng Volume Inbound/Outbound" + "Print DO" (§2795, 2854, 2913) | KPI tổng (4 numbers) |
| `fetchTransactionMoveTrendCbmPallet` | "Xu hướng CBM & Pallet theo ngày" (§2935) | Trend by day |
| `fetchTransactionMoveInboundOutboundCbm` | "Inbound vs Outbound" (§3031) | Compare in/out by day |
| `fetchTransactionMoveMovementReport` | "Movement Report Transaction" (§3090) | Detail table |
| `fetchTransactionMoveWarehouseComparison` | "So sánh khối lượng theo kho" (§2983) | Cross-warehouse |

### 5.6 Business Logic Specification

> **Source of truth**: `analytics_workspace.mv_movement_transaction`. Logic verified với 60,217 rows (range 2021-08-01 → 2026-05-07) tại 2026-05-07.

#### 5.6.1 Đầu vào & Granularity

| Item | Định nghĩa |
|---|---|
| **Granularity** | 1 row = 1 (transaction_date × warehouse × activity × category × uom × direction) aggregate. Đã được pre-aggregate ở upstream (`mv_inbound_transaction_base` / `mv_outbound_transaction_base`) |
| **Volume metrics** | 5 cột song song: `PCE`, `CBM`, `Ton`, `CSE`, `Pallet` — pre-converted từ canonical UOM. Mỗi row có giá trị ở **TẤT CẢ 5 cột** (đã quy đổi sẵn) |
| **`uom` column** | Canonical unit của activity (CASE/CBM/DO/PALLET/TONS) — tham chiếu, KHÔNG dùng để filter |
| **`direction`** | Chỉ 2 giá trị: `INBOUND` / `OUTBOUND`. **KHÔNG có "Internal"** (internal transfer được track như INBOUND + OUTBOUND của 2 kho khác nhau) |

#### 5.6.2 Công thức KPI

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
            ELSE 0
        END
    ELSE 0
END)

-- Tổng Volume Outbound — same logic, direction='OUTBOUND'

-- Print DO orders
total_print_do_orders = SUM(orders) WHERE activity = 'Print DO'

-- Total movement rows
total_movement_rows = COUNT(*) AFTER FILTER
```

#### 5.6.3 KPI cards (verified) — toàn MV

| KPI | Công thức | Giá trị verified |
|---|---|---:|
| `totalPalletInbound` | `SUM(if(direction='INBOUND', coalesce(Pallet, 0), 0))` | **5,853,978** |
| `totalCbmOutbound` | `SUM(if(direction='OUTBOUND', coalesce(CBM, 0), 0))` | **11,164,031** |
| `totalPrintDoOrders` | `SUM(orders) WHERE activity='Print DO'` | **1,421,023** |
| `totalMovementRows` | `count()` (sau filter) | **60,217** |

#### 5.6.4 Activity catalog (17 verified activities)

**INBOUND activities (8):**
| Activity | Rows | Σ Orders |
|---|---:|---:|
| Nhập xưởng / Inbound From Prod | 6,214 | 180,733 |
| Phí quấn màng co / Pallet shrink wrap | 6,018 | 183,807 |
| Nhập chuyển kho In-In / Warehouse transfer | 3,457 | 34,580 |
| Nhập copack | 3,056 | 34,565 |
| Nhập cont BKD / Nhập khẩu / Inbound loose | 2,815 | 6,981 |
| Nhập chuyển kho In-Ex / Warehouse transfer | 2,632 | 16,610 |
| Nhập trả về từ NPP | 1,431 | 2,630 |
| Nhập POSM / Inbound POSM | 1,169 | 2,454 |

**OUTBOUND activities (9):**
| Activity | Rows | Σ Orders |
|---|---:|---:|
| Print DO | 9,496 | 1,421,023 |
| Xuất bán / Loading loose | 5,664 | 1,262,258 |
| Xuất chuyển kho / WH Transfer In-In | 4,481 | 31,854 |
| Xuất TDX / Outbound copack | 3,720 | 14,606 |
| Xuất chuyển kho / WH Transfer In-Ex | 3,535 | 35,033 |
| Xuất khẩu / Outbound loose from Prod | 3,405 | 11,876 |
| Xuất POSM / Outbound POSM | 2,264 | 43,133 |
| Xuất chuyển kho trực tiếp từ xưởng | 668 | 1,525 |
| Xuất hủy | 192 | 300 |

> **Q5 PRD `[TBD]`:** `Xuất hủy` (192 rows) có nên gộp vào KPI không? BA cần confirm.

#### 5.6.5 UOM filter (5 options)

| Filter value | Mapping → metric column | Use case |
|---|---|---|
| `CSE` | `CSE` | Default, đơn vị thùng (cases) |
| `PCE` | `PCE` | Đơn vị PCE/EA/masterunit |
| `CBM` | `CBM` | Đơn vị thể tích |
| `TON` | `Ton` | Đơn vị khối lượng |
| `PALLET` | `Pallet` | Đơn vị pallet |

> ⚠️ **Naming inconsistency** (BUG-2 từ S2 audit):
> - SQL filter: `'CSE'`, `'TON'`
> - Column row value (`uom`): `'CASE'`, `'TONS'`
> - **Q6 PRD `[TBD]`:** UI dropdown hiển thị giá trị nào? Đề xuất giữ filter param `CSE/TON` (đơn vị Mondelez chuẩn) — không expose `CASE/TONS` ra UI.

#### 5.6.6 Filter Behavior (SQL)

```sql
WHERE 1=1
  AND (p_warehouse = 'ALL' OR warehouse = p_warehouse)
  AND toDate(transaction_date) BETWEEN p_from AND p_to
  AND (p_activity = 'ALL' OR activity = p_activity)
  AND direction IN ('INBOUND', 'OUTBOUND')      -- LUÔN cố định
GROUP BY <dimension>
```

#### 5.6.7 Edge Cases

| # | Tình huống | Xử lý |
|---|---|---|
| BL-1 | NULL `category_converted` (184 rows / 0.3%) | SQL không filter; UI chấp nhận hiển thị "Unclassified" |
| BL-2 | Date range không có data | Trả empty; UI hiển thị 0/0/0 |
| BL-3 | UOM toggle = `'PCE'` nhưng row PCE column NULL | `coalesce(PCE, 0)` → 0; KPI vẫn aggregate |
| BL-4 | Activity 'Print DO' có UOM = 'DO' (không phải CSE/CBM/TON/PALLET/PCE) | Print DO orders dùng `SUM(orders)` riêng, không qua UOM toggle |
| BL-5 | Refresh delay MV (1 giờ) | UI hiển thị timestamp "Cập nhật lúc HH:mm" |
| BL-6 | MV chỉ có `INBOUND` + `OUTBOUND` (no Internal) | Direction filter hardcoded; UI **không show** "Internal" option |
| BL-7 | `Xuất hủy` activity (192 rows) | Q5 PRD `[TBD]` — tạm tính như Outbound |
| BL-8 | Empty warehouse list | Filter trả empty; UI hiển thị "No data" |

#### 5.6.8 CLAUDE.md Data Exclusion Audit

| # | Rule | Trạng thái |
|---|---|---|
| 1 | `is_deleted = 0` | ⚠️ MV không có column; cần verify upstream `mv_inbound_transaction_base`, `mv_outbound_transaction_base` |
| 2 | Cancelled orders | ⚠️ Activity `Xuất hủy` chưa rõ là cancelled hay legitimate disposal — Q5 BA confirm |
| 3 | Virtual/Test orders | ✅ 17 activities production, không thấy "TEST" |
| 4 | Internal transfers | ⚠️ 4 activities "WH Transfer" (In-In, In-Ex) — Q4 BA xác định scope |
| 5 | NULL date/warehouse/activity | ✅ 0 NULL (verified) |
| 6 | Divide by zero → 0 | ✅ `coalesce(metric, 0)` SQL |

### 5.6.9 Verified Data Patterns (live ClickHouse audit 2026-05-07)

> Số liệu dưới đây verified trực tiếp trên `analytics_workspace.mv_movement_transaction` (60,217 rows).

#### A. MV existence — BUG-3 RESOLVED ✅

Query `system.tables WHERE name LIKE '%movement%'`:

| Table | Engine |
|---|---|
| `mv_filter_date_type_movement_transaction` | View (UI helper) |
| `mv_filter_type_movement_transaction` | View (UI helper) |
| `mv_movement_transaction` | MaterializedView (data) |

✅ **`mv_test_movement_transaction` KHÔNG tồn tại trong ClickHouse**. Tên `_test` chỉ xuất hiện trong Redshift schema (`reporting_schema.mv_test_movement_transaction`) — đó là legacy. Backend C# dùng ClickHouse → reference đúng `mv_movement_transaction`. **BUG-3 đã đóng.**

#### B. Pre-conversion of 5 metric columns

Trên 60,217 rows:

| Cột | Có giá trị (NOT NULL) | % |
|---|---:|---:|
| `PCE` | 60,217 | **100.00%** |
| `CSE` | 60,214 | 99.99% |
| `Ton` | 60,129 | 99.85% |
| `CBM` | 60,087 | 99.78% |
| `Pallet` | 59,793 | 99.30% |
| **Tất cả 5 cột có giá trị** | 59,660 | **99.07%** |
| Tất cả 5 NULL | 0 | 0% |

✅ **Pre-conversion gần đầy đủ** — 99% rows có giá trị ở tất cả 5 metric columns. Pipeline đã quy đổi sẵn.
✅ **Không có row "all NULL"** — mỗi row luôn có ít nhất 1 metric.
ℹ️ **0.93% rows có metric NULL** (chủ yếu Pallet) — `coalesce(metric, 0)` của SQL handle đúng.

#### C. UOM ↔ Activity mapping (1:1 verified)

Mỗi activity có **đúng 1 canonical UOM** (verified bằng `GROUP BY activity, uom`):

| `uom` value | Activities (số lượng) | Activity examples |
|---|---|---|
| `PALLET` (10) | Inbound xưởng/copack/transfer, Outbound copack/transfer/POSM/hủy/transfer trực tiếp, Phí quấn màng co | "Nhập xưởng", "Xuất TDX", "WH Transfer", "Xuất hủy" |
| `CBM` (3) | Nhập cont BKD, Nhập trả về NPP, Xuất bán | "Xuất bán / Loading loose" |
| `TONS` (2) | Nhập POSM, Xuất POSM | POSM operations |
| `CASE` (1) | Xuất khẩu / Outbound loose from Prod | Export ops |
| `DO` (1) | Print DO | Print DO orders |

> **Implication:**
> - UI có thể hiển thị "1 activity = 1 canonical UOM" như metadata
> - Filter UOM toggle chỉ ảnh hưởng **cách hiển thị aggregation**, không filter rows
> - Activity 'Print DO' với uom='DO' là **đặc biệt**: KPI dùng `SUM(orders)` thay vì SUM volume

#### D. Negative values check

Trên toàn 60,217 rows:

| Cột | Negative count |
|---|---:|
| `CSE` | **0** |
| `CBM` | **0** |
| `Pallet` | **0** |
| `orders` | **0** |

✅ **Không có giá trị âm** — pipeline đảm bảo data clean. Không cần clamp ở UI.

#### E. Internal Transfer Pairing 🔑 (business insight)

Verified pairing giữa OUTBOUND vs INBOUND của activity transfer:

| Type | OUT rows | IN rows | OUT Pallet | IN Pallet | OUT CSE | IN CSE | Δ Pallet |
|---|---:|---:|---:|---:|---:|---:|---:|
| **In-In** (Internal → Internal) | 4,481 | 3,457 | 868,199 | 908,778 | 38,488,288 | 38,586,920 | -40K (-4.7%) |
| **In-Ex** (Internal → External) | 3,535 | 2,632 | 676,157 | 244,613 | 16,728,742 | 9,887,801 | +431K (+64%) |

**Business insight quan trọng (chưa được document trước đây):**

- **In-In** (kho Mondelez ↔ kho Mondelez): rows + volume **gần balance** (~5% chênh lệch — có thể do timing/data lag), confirm cả 2 leg được track ⚠️ **Risk double-counting nếu KPI gộp toàn bộ INBOUND + OUTBOUND**
- **In-Ex** (kho Mondelez → external e.g. NPP/customer warehouse): chỉ tracked OUTBOUND leg đủ; INBOUND chỉ track khi receiving warehouse là Mondelez (giải thích Δ +64%) → **không có double-counting risk**

> **Q3 PRD `[TBD]` ANSWER:** Internal warehouse transfer In-In **gây double-counting** nếu cộng INBOUND + OUTBOUND mà không loại. Recommendation:
> - Customer-facing KPI: **loại** activities `WH Transfer In-In` cả 2 phía
> - Internal ops KPI: giữ nguyên (intentional)
> - Phase 1: Add filter "exclude internal transfer" cho customer-facing report

#### F. Date Freshness ✅

| Metric | Value |
|---|---|
| Latest transaction_date | **2026-05-07** (today) |
| Days lag | **0** |
| Rows today | 22 |
| Activities today | 8 |

Distribution recent days:

| Day | Rows | Activities |
|---|---:|---:|
| 2026-05-07 | 22 | 8 |
| 2026-05-06 | 45 | 14 |
| 2026-05-05 | 31 | 14 |
| 2026-05-04 | 35 | 14 |
| 2026-05-03 | 22 | 8 |
| 2026-05-02 | 11 | 8 |
| 2026-05-01 | 4 | 2 |

> **Data realtime ≤ 1h** — MV refresh hoạt động đúng. UI có thể hiển thị timestamp "Cập nhật lúc HH:mm".
> **Pattern weekend dip** (May 2-3 chỉ 11/22 rows) — phù hợp business reality (giảm hoạt động cuối tuần).

#### G. NULL distribution per dimension

| Cột | NULL count | NULL % |
|---|---:|---:|
| `transaction_date` | 0 | 0% |
| `warehouse` | 0 | 0% |
| `activity` | 0 | 0% |
| `uom` | 0 | 0% |
| `direction` | 0 | 0% |
| `orders` | 0 | 0% |
| `category_converted` | 184 | 0.30% |

✅ Data quality cao — chỉ `category_converted` có 184 rows NULL (negligible).

#### H. UI ↔ MV activity name mismatch (BUG xác nhận live)

UI hardcode `ACTIVITY_FILTER_OPTIONS` (TransactionMoveView.tsx lines 62–80) lệch với MV ở **2 activities**:

| UI value | MV value (verified live) | Hậu quả |
|---|---|---|
| `Xuất TĐX / Outbound copack` (có `Đ`) | `Xuất TDX / Outbound copack` (có `D`, **3,720 rows**) | UI filter "Xuất TĐX" → 0 results |
| `Pallet shrink wrap` (rút gọn) | `Phí quấn màng co / Pallet shrink wrap` (**6,018 rows**) | UI filter "Pallet shrink wrap" → 0 results |

**15/17 activities khác match đúng.** 2 activities bị bug có tổng 9,738 rows (~16% MV) → impact đáng kể nếu user filter cụ thể.

**Action:**
- **Option A (recommended):** Đổi UI hardcode để match MV exact value
- **Option B:** Map ở backend (API normalize input)

#### I. UI Warehouse list lệch MV (3PL warehouses thiếu)

UI hardcode 4 wh (TransactionMoveView.tsx line 52): `BKD1, BKD2, BKD3, NKD`.

MV có thêm 2 wh (verified):

| Warehouse | Rows | Direction observed | Date range | Đặc trưng |
|---|---:|---|---|---|
| **VN821** | 260 | OUTBOUND only | 2025-07-22 → 2026-05-06 | 3PL — chỉ outbound |
| **VN831** | 294 | OUTBOUND only | 2025-06-04 → 2026-05-06 | 3PL — chỉ outbound |

> **Insight quan trọng:** Cả 2 wh VN821 và VN831 chỉ có direction `OUTBOUND` — không có inbound. Có thể là **3PL warehouses** (kho thuê ngoài) chỉ nhận lệnh xuất từ Mondelez chính, không xử lý inbound từ xưởng. Tổng 554 rows (~0.9% MV).

**Verified Direction × Warehouse matrix:**

| Warehouse | INBOUND | OUTBOUND |
|---|:---:|:---:|
| BKD1 | ✅ | ✅ |
| BKD2 | ✅ | ✅ |
| BKD3 | ✅ | ✅ |
| NKD | ✅ | ✅ |
| VN821 | ❌ | ✅ |
| VN831 | ❌ | ✅ |

**Action:**
- **Option A:** Thêm VN821, VN831 vào UI hardcode → user filter được
- **Option B (best practice):** Convert UI dropdown thành dynamic từ API
- **Option C:** Giữ ẩn (nếu business confirm 3PL không cần expose)

#### J. Activity catalog summary (post bug fix)

Sau khi fix 2 UI bugs ở §H, danh sách 17 activities filter sẽ hoạt động đầy đủ:

**OUTBOUND (9 activities, 33,425 rows):**
1. Print DO (9,496) — đặc biệt, dùng SUM(orders)
2. Xuất bán / Loading loose (5,664)
3. Xuất chuyển kho / WH Transfer In-In (4,481) — internal pairing risk
4. **Xuất TDX / Outbound copack** (3,720) — fix UI value
5. Xuất chuyển kho / WH Transfer In-Ex (3,535)
6. Xuất khẩu / Outbound loose from Prod (3,405)
7. Xuất POSM / Outbound POSM (2,264)
8. Xuất chuyển kho trực tiếp từ xưởng (668)
9. Xuất hủy (192)

**INBOUND (8 activities, 26,792 rows):**
1. Nhập xưởng / Inbound From Prod (6,214)
2. **Phí quấn màng co / Pallet shrink wrap** (6,018) — fix UI value
3. Nhập chuyển kho In-In / Warehouse transfer (3,457) — pairing với In-In OUT
4. Nhập copack (3,056)
5. Nhập cont BKD / Nhập khẩu / Inbound loose (2,815)
6. Nhập chuyển kho In-Ex / Warehouse transfer (2,632)
7. Nhập trả về từ NPP (1,431)
8. Nhập POSM / Inbound POSM (1,169)

---

### 5.7 Color coding

| Trạng thái | Màu | Áp dụng |
|---|---|---|
| Inbound | 🟢 Green | Bar/legend chart Inbound vs Outbound |
| Outbound | 🟠 Orange | Bar/legend chart Inbound vs Outbound |

> **Bỏ** các status fictional trong spec cũ (High/Normal/Low Activity, Internal Purple) — không có data nguồn.

---

## 6. Out of Scope

| # | Hạng mục | Lý do |
|---|---|---|
| OOS-1 | Worker efficiency metrics (moves/hour per worker) | MV không track worker info |
| OOS-2 | Accuracy rate (% correct moves) | Không có "correct/incorrect" flag |
| OOS-3 | Peak hour detection (volume > avg + 2σ) | Out of scope MVP; có thể là Phase 2 |
| OOS-4 | Internal direction (chuyển vị trí trong kho) | Direction chỉ INBOUND/OUTBOUND; internal transfer được track ở activity level |
| OOS-5 | Realtime hourly heatmap | MV refresh 1h → không đủ realtime |
| OOS-6 | Drill-down activity → SO/orderline detail | Phase 2 nếu user request |
| OOS-7 | Forecast volume | Out of scope |
| OOS-8 | Mobile responsive | MVP chỉ desktop |

---

## 7. Decisions Log

| ID | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Source data | ✅ `mv_movement_transaction` | Match SQL Registry "transaction move" |
| D2 | UOM filter values | ✅ `CSE / PCE / CBM / TON / PALLET` (canonical Mondelez) | Match SQL filter; không expose `CASE/TONS` |
| D3 | Direction enum | ✅ Chỉ `INBOUND` / `OUTBOUND` | Verified MV không có Internal |
| D4 | Refresh cadence | ✅ 1 giờ (theo MV definition) | Acceptable cho dashboard daily review |
| D5 | KPI cards | ✅ 4 numbers theo spec (Pallet IN / CBM OUT / Print DO / Total rows) | Match wireframe |
| D6 | Activity catalog | ✅ 17 activities thực tế | Verified live data |

### Decisions đã đóng sau live data audit (2026-05-07)

| ID | Decision | Resolution |
|---|---|---|
| ~~Q3 (BUG-3)~~ | Backend dùng MV nào? | ✅ **CLOSED** — `mv_test_movement_transaction` không tồn tại trong ClickHouse; backend dùng `mv_movement_transaction` |
| ~~negative values~~ | Cần clamp 0 không? | ✅ **CLOSED** — verified 0/60,217 rows có giá trị âm |
| ~~pre-conversion~~ | Có phải mọi row đều có 5 metric? | ✅ **CLOSED** — 99.07% có cả 5; 0% all-null; UI `coalesce(metric, 0)` đủ |
| **Q3 (Internal transfer)** | In-In transfer có double-counting không? | ⚠️ **VERIFIED YES** — In-In gây double-count (4,481 OUT + 3,457 IN = ~8K rows track 1 sự kiện); In-Ex chỉ 1 leg → safe. **Action:** customer-facing KPI cần loại `WH Transfer In-In` cả 2 phía |

### Decisions còn `[TBD]` (sau live audit)

| ID | Decision | Khi nào cần |
|---|---|---|
| Q1 | Goals & Success Metrics target số cụ thể | Stakeholder trước Phase 2 |
| Q2 | UI hiển thị warning "Cập nhật cách đây N phút" cho refresh 1h? Verified data có thể realtime trong ngày | Trước Phase 1 |
| Q4 | `Xuất hủy` (192 rows, uom=PALLET) — disposal hợp pháp hay cancelled? Có gộp Outbound KPI không? | BA confirm |
| Q5 | In-Ex transfer có loại khỏi KPI customer-facing không? (verified imbalanced — chỉ track 1 leg) | BA confirm |
| Q6 | UOM dropdown UI — `CSE/TON` (filter param) hay `CASE/TONS` (column value)? | UI/BA align |
| Q7 | Category filter (3 categories) — cần expose Phase 1 không? | BA confirm |
| Q8 (mới) | "WH Transfer In-In" exclude default cho customer-facing tab — UI có toggle "Include internal transfer" không? | BA + UI design |
| **Q9 (mới)** | UI activity name mismatch (§5.6.9 H): fix UI hardcode hay backend normalize? | Trước Phase 1 — Engineering |
| **Q10 (mới)** | UI warehouse hardcode 4 wh (BKD1/2/3/NKD) — có expose VN821, VN831 (3PL outbound-only)? | Trước Phase 1 — BA + UI |

---

## 8. Data Quality Risks (post live audit 2026-05-07 v2)

| # | Risk | Severity | Status sau live audit | Action |
|---|---|---|---|---|
| ~~Q5 BUG-3~~ | Backend dùng MV nào? | 🔴 High | ✅ **CLOSED** — `mv_test_movement_transaction` không tồn tại trong ClickHouse. Backend dùng `mv_movement_transaction` | None |
| ~~Q2 UNION schema~~ | UNION ALL inbound + outbound base | 🟢 Low | ✅ **CLOSED** — verified 12 cột identical, no schema mismatch | None |
| ~~Negative values~~ | Có giá trị âm không? | 🟢 Low | ✅ **CLOSED** — 0/60K rows | None |
| ~~Pre-conversion~~ | Có phải mọi row đều có 5 metric? | 🟢 Low | ✅ **CLOSED** — 99.07% all-5, 0% all-null | None |
| **Q3 In-In double-count** | Internal transfer In-In double-counted nếu KPI gộp tất cả INBOUND + OUTBOUND | 🔴 **High (BUG-5 mới)** | ⚠️ **VERIFIED YES** | Filter exclude `WH Transfer In-In` cho customer-facing KPI |
| **Q5 In-Ex semantics** | In-Ex chỉ track 1 leg (Mondelez side) — có phải bug không? | 🟡 Medium | ✅ **VERIFIED** — by design, không phải bug | Document trong spec |
| Q1 | Upstream `is_deleted=0` chưa verify | 🟡 Medium | Pending | DA verify `mv_inbound_transaction_base`, `mv_outbound_transaction_base` |
| Q4 | UOM naming inconsistency (`CSE` filter ↔ `CASE` column value) | 🟡 Medium | Verified inconsistency | UI/BA Q6 align |
| Q6 | Refresh delay 1h | 🟢 Low | Acceptable, data freshness verified ≤1h | UI nên hiển thị timestamp |
| Q7 | NULL `category_converted` (184/60K = 0.3%) | 🟢 Low | Verified | Document only |
| Q8 (mới) | `Xuất hủy` activity semantics — disposal hợp pháp hay cancelled order? | 🟡 Medium | uom=PALLET, 192 rows, cần BA xác định scope | Q4 BA |
| Q9 (mới) | Pre-conversion 0.93% rows có 1 metric NULL (chủ yếu Pallet) | 🟢 Low | Verified — `coalesce(0)` handle đúng | Document only |
| **Q10 (mới)** | UI activity name mismatch (2/17): `Xuất TĐX` vs MV `Xuất TDX` (3,720 rows); `Pallet shrink wrap` vs MV `Phí quấn màng co / Pallet shrink wrap` (6,018 rows) | 🟡 **Medium** | ⚠️ **VERIFIED BUG** — UI filter 2 activities → 0 results (tổng 9,738 rows / 16% MV) | Engineering: fix UI hardcode hoặc map ở backend |
| **Q11 (mới)** | UI warehouse list (4) thiếu vs MV (6) — VN821/VN831 (3PL outbound-only, 554 rows) | 🟢 Low | ⚠️ **VERIFIED** — UI miss ~0.9% data; user filter `'ALL'` vẫn lấy hết | UI: thêm vào hardcode hoặc dynamic |

---

## 9. Release Plan

### Phase 1 — MVP

- ✅ 5 endpoints đã có
- 🔲 **Spec rewrite** — `transaction-move.spec.md` mô tả feature lý thuyết khác (worker efficiency, accuracy rate, peak hour). Cần rewrite theo wireframe + reality
- 🔲 BA confirm Q3 (internal transfer scope), Q4 (cancelled), Q5 (Xuất hủy)
- 🔲 UI confirm Q2 (refresh warning) + Q6 (UOM naming)
- 🔲 DA verify Q1 (is_deleted upstream) + Q5 (Redshift mv_test)

### Phase 2 — Post-MVP

- Drill-down activity → SO detail
- Category filter (Dry/POSM/Pallet rỗng)
- Peak hour detection
- Worker efficiency (cần thêm data source)

### Phase 3 — Future

- Realtime (cần MV refresh nhanh hơn)
- Forecast volume
- Mobile responsive

---

## 10. Open Questions

1. **Q5 BA**: `Xuất hủy` (192 rows) — là disposal hợp pháp hay cancelled order? Có gộp vào KPI Outbound CBM không?
2. **Q3 BA**: Internal warehouse transfers (BKD→BKD2 etc.) — có nằm trong customer-facing volume không? Verified gây double-count In-In (xem §5.6.9 E).
3. ~~**Q5 DA + Backend**: Code C# đang dùng `mv_test_movement_transaction` (Redshift) hay `mv_movement_transaction` (ClickHouse)?~~ ✅ **CLOSED** — verified `mv_test_movement_transaction` không tồn tại trong ClickHouse, backend dùng đúng `mv_movement_transaction`.
4. **Q10 Engineering (mới)**: UI activity hardcode lệch MV ở 2 activities (xem §5.6.9 H). Fix UI hay backend normalize?
5. **Q11 BA + UI (mới)**: 2 wh 3PL VN821/VN831 (outbound-only) — có expose ra UI dropdown không?
4. **Q6 UI**: Dropdown UOM hiển thị "CSE/TON" hay "CASE/TONS"? Cần align với SQL filter param.
5. **Activity grouping**: 17 activities có cần group thành super-categories (e.g. "Inbound from Production" / "Inter-warehouse transfer" / "POSM ops") cho UI gọn không?

---

## 11. Cross-references

- Spec: `docs/02-features/transaction-move/transaction-move.spec.md` *(⚠️ outdated — cần rewrite)*
- Wireframe: `docs/02-features/transaction-move/transaction-move.wireframe.md` *(✅ aligned)*
- Audit: `docs/audit-results/s2-transaction-move-20260507.md`
- SQL Registry: `docs/03-engineering/sql-registry.md` § "sql query - transaction move - discuss" (2793–3116)
- DDL: `docs/03-engineering/data-sources/clickhouse-ddl/analytics-workspace_mvs.md`
  - `mv_movement_transaction` (line 5378) — UNION view
  - `mv_inbound_transaction_base` — upstream
  - `mv_outbound_transaction_base` — upstream
- Code:
  - UI: `control-tower/ui/src/views/control-tower/efficiency/TransactionMoveView.tsx`
  - API: `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs`
- GLOSSARY: `docs/GLOSSARY.md`
