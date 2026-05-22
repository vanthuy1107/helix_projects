# PRD — Loose Picking

> **Status:** ✅ Active
> **Owner:** Control Tower Team
> **Last updated:** 2026-05-06
> **Source MV:** `analytics_workspace.mv_loose_picking_clickhouse` (refresh 1 HOUR)

---

## 1. Overview

Loose Picking là màn hình giám sát **tỷ lệ pick hàng lẻ vs pick hàng full pallet** trong vận hành kho thành phẩm (Dry & Fresh), thuộc module **Control Tower > Efficiency**. Pick lẻ càng nhiều → fast outbound càng kém, ảnh hưởng trực tiếp tới **cost per case, productivity, fill rate**.

**Phạm vi:** post-shipment analysis — chỉ trip đã hoàn tất (`orders.status_code = '95'` ShipCompleted). KHÔNG track in-progress orders.

Tài liệu liên quan:
- Spec kỹ thuật: [`loose-picking.spec.md`](loose-picking.spec.md)
- Wireframe: [`loose-picking.wireframe.md`](loose-picking.wireframe.md)
- GLOSSARY: [`docs/GLOSSARY.md`](../../GLOSSARY.md) → "Loose Picking"
- Audit S2 (data pipeline): [`docs/audit-results/s2-loose-picking-20260506.md`](../../audit-results/s2-loose-picking-20260506.md)
- Audit S1 (BA logic): [`docs/audit-results/s1-loose-picking-20260506.md`](../../audit-results/s1-loose-picking-20260506.md)

---

## 2. Problem Statement

Đội vận hành kho không có công cụ tập trung để theo dõi và phân tích tỷ trọng pick hàng lẻ. Hiện việc đánh giá pick lẻ phải thủ công qua WMS, dẫn đến:

- Không biết SKU nào gây tải pick lẻ cao nhất → khó tối ưu pack/pallet config.
- Không so sánh được mức loose picking giữa các kho (BKD vs NKD).
- Khó liên kết loose picking với cost per case và productivity metrics.
- Không phát hiện sớm xu hướng tăng loose picking theo ngày để có biện pháp điều chỉnh.

---

## 3. Target Users

| Người dùng | Vai trò | Tần suất sử dụng |
|---|---|---|
| Warehouse Manager | Theo dõi % loose của kho, ưu tiên SKU giảm pick lẻ | Daily |
| Logistics Supervisor | Phối hợp với picking team để xử lý SKU cao loose | Daily |
| Control Tower Analyst | Phân tích trend loose theo ngày, top SKU, pivot customer/region | Daily |
| Senior Management | Xem KPI tổng hợp (% loose toàn hệ thống) | 1 lần/ngày |

---

## 4. Goals & Success Metrics

### Mục tiêu

- Cung cấp visibility về tỷ lệ pick lẻ theo kho, SKU, customer, region.
- Liên kết với cost per case, productivity, fill rate (KPI Mondelez).
- Hỗ trợ identify SKU cần optimize pack config để giảm pick lẻ.
- Hỗ trợ export raw data để báo cáo EOD.

### Định nghĩa thành công

| Metric | Target |
|---|---|
| Thời gian tải màn hình | < 3 giây với dữ liệu 7 ngày |
| Độ chính xác KPI | 100% khớp với SQL Registry §"loose picking - verified" |
| Tỷ lệ sử dụng hàng ngày | ≥ 80% ngày làm việc có ít nhất 1 user active |
| % Loose monitoring | UI hiển thị KPI per-warehouse + trend daily |

---

## 5. Functional Requirements

### 5.1 Must-Have

#### FR-01: KPI Cards (4 thẻ)

| KPI | Định nghĩa | Source |
|---|---|---|
| **Total Cases** | `SUM(cse_full + cse_loose)` warehouse-aggregated | `mv_loose_picking_clickhouse` |
| **Total Loose Cases** | `SUM(cse_loose)` | — |
| **Total Full Pallets** | `SUM(number_of_full_pallets)` — pallet quy đổi từ thùng (KHÔNG phải pallet vật lý) | — |
| **% Loose** | `SUM(cse_loose) / SUM(cse_full + cse_loose) × 100` | derived |

**Color badge cho %Loose KPI** (visual-only, không dựa SLA):
- 🟢 **Green** `< 30%`
- 🟡 **Amber** `30–40%`
- 🔴 **Red** `> 40%`

> **Invariant:** `Total Cases = Total Loose Cases + (Total Full Pallets × cse_per_pallet)`

#### FR-02: Stacked Bar Chart — Cases (Full vs Loose) by Warehouse
Bar chart ngang/dọc theo whseid, stack 2 màu:
- 🟢 Full Cases (Green)
- 🟠 Loose Cases (Amber `#F59E0B`)

Tooltip per kho: Full Cases, Loose Cases, % Loose, Total Cases.

#### FR-03: Pie/Donut Chart — Full vs Loose Distribution Tổng
2 segment: Full vs Loose. Hiển thị %.

#### FR-04: Top SKU by Loose Cases
Bảng top N SKU (default N=10) sắp xếp theo `SUM(cse_loose)` DESC. Cột: SKU, Product Name, Loose Cases, Total Cases, % Loose.

API: `fetchLoosePickingBySku({ ..., topN })` — BE truyền `LIMIT topN` xuống SQL.

#### FR-05: SKU Breakdown Table (Detail tab)
Bảng raw 14 cột (toàn bộ MV):

| Group | Cột |
|---|---|
| Identity | `whseid`, `SO`, `order_key`, `actual_ship_date` |
| SKU | `item_code`, `product_name`, `batch` |
| Volume | `number_of_full_pallets`, `cse_full`, `cse_loose`, `pct_loose_picking` |
| Customer | `customer_code`, `customer_name`, `region` |

Filter Warehouse áp dụng cho bảng. Search SKU và Brand filter **không build** (không expose trong UI).

#### FR-06: Bộ lọc

| Filter | Giá trị | Cột MV |
|---|---|---|
| **Date Range** | From / To (default last 7 days) | `actual_ship_date` |
| **Warehouse** | ALL, BKD1, BKD2, BKD3, NKD, VN821, VN831 | `whseid` |
| **Cargo Group** | ALL, FRESH, DRY, MOONCAKE, POSM/OFFBOM | `item_code` lookup → `masterdata_sku.group_of_cargo` (cần BE implement) |

> **Period filter** (daily/weekly/monthly) — UI tự gộp client-side, không có server query riêng.
> **VN821/VN831** hiện 0 rows trong MV (BUG-2 §11) — UI show empty state khi user chọn.

#### FR-07: Export
Export bảng FR-05 (raw 14 cột) sang Excel/CSV theo filter hiện tại.

### 5.2 Nice-to-Have

| ID | Mô tả |
|---|---|
| NFR-01 | Trend chart "% Loose by ship_date" — hiển thị xu hướng theo ngày |
| NFR-02 | Pivot customer × region — drill cross-dimension |
| NFR-03 | Highlight row có %Loose >40% trong Detail table |

---

## 6. Data & Business Rules

### 6.1 Core formula (CSE-based)

MV pre-compute per (whseid, SO, order_key, ship_date, item_code, product_name, batch):

```
cse_per_pallet = masterunit_per_pallet / masterunit_per_cse
number_of_full_pallets = FLOOR(SUM(SHIPPED CSE) / cse_per_pallet)
cse_full   = number_of_full_pallets × cse_per_pallet
cse_loose  = SUM(SHIPPED CSE) - cse_full
pct_loose_picking (row-level) = cse_loose / NULLIF(SUM(SHIPPED CSE), 0)
```

> **Đơn vị: CSE** (case/thùng).
> **Quan trọng:** KHÔNG dùng `pct_loose_picking` row-level (86.7% rows = 100% loose vì grain rất nhỏ). Luôn **warehouse-aggregated**:
> ```
> %Loose (warehouse) = SUM(cse_loose) / SUM(cse_full + cse_loose) × 100
> ```

### 6.2 Hardcoded business filters (upstream MV)

| # | Filter | Implement |
|---|---|---|
| 1 | `is_deleted = 0` | tất cả `dim_*` upstream |
| 2 | `orderdetail.storer_key = 'MDLZ'` | `dim_orderdetail` |
| 3 | `orders.status_code = '95'` (chỉ ShipCompleted) | `dim_orders` |
| 4 | `orderdetail.whseid IN ('BKD1','BKD2','BKD3','NKD','VN821','VN831')` | `dim_orderdetail` |
| 5 | Order types theo whseid: BKD `IN ('01','240')`; NKD `IN ('01','07','08','09','240','XB2BMC','XTNPP')` (XB2BMC + XTNPP đều là đơn xuất bán) | `dim_orders.type` |
| 6 | `extern_order_key IS NOT NULL` | `dim_orders` |
| 7 | `pickdetail.is_deleted = 0` | `dim_pickdetail` |
| 8 | `cse_per_pallet = MAX(cse_per_pallet)` per group — assumption 1 pack/SKU | `dim_pack` JOIN |

### 6.3 Volume convention

- `original_qty` và `shipped_qty` luôn ở **masterunit (PCE/EA)** trong toàn data.
- Hệ số quy đổi từ `dim_sku` (`std_cube`, `std_grossweight`) + `dim_pack` (`inner_pack`, `pallet`).
- `cse_per_pallet` lấy `MAX` per group — chấp nhận assumption 1 pack/SKU. Anomaly nếu có >1 pack code cho cùng SKU.

### 6.4 Warehouse hierarchy

| whseid | Rows trong MV | Status |
|---|---:|---|
| BKD1 | 4,094,220 | Active (33% loose) |
| NKD | 3,534,880 | Active (29% loose) |
| BKD3 | 37,569 | Active (25% loose) |
| BKD2 | 266 | Near-dead (chỉ 32 SO) |
| VN821 | **0** | ❌ BUG-2 — pending DA fix |
| VN831 | **0** | ❌ BUG-2 — pending DA fix |

> Operations team đã confirm rollup VN821→BKD và VN831→NKD (per Late Order Alert PRD §6.6). Khi DA fix BUG-2, VN821/VN831 sẽ có data và rollup theo intent.

### 6.5 Filter ↔ Cột MV (cheatsheet)

| UI Filter | Cột MV | NULL handling |
|---|---|---|
| Date Range | `actual_ship_date` | NULL date → loại khỏi range |
| Warehouse | `whseid` | exact match |
| Cargo Group | `item_code` lookup → `group_of_cargo` | NULL → bucket `'Unclassified'` |

### 6.6 Data quality notes

| Issue | Số liệu | Action |
|---|---|---|
| **Region empty** | 25% rows / 2,836 customer (chủ yếu WinMart/WinCommerce KA chain) | Document. Chuỗi MT KA không có `group_area_name` trong masterdata location. Pivot by region sẽ có bucket "" lớn. |
| **NULL cse_full/cse_loose** | 5,475 rows (0.07%) — concentrate ở NKD (4,126), BKD1 (1,346) | SKU không có pack info. Aggregation dùng `coalesce(... ,0)`. Giữ nguyên (không investigate root cause per BA decision). |
| **86.7% rows pure loose** | row-level pct_loose = 100% | Grain MV per (SO+SKU+batch) thường nhỏ hơn 1 pallet → đa số rows là pure loose. **Luôn dùng warehouse-aggregated, không dùng row-level**. |
| **Test orders** | 783 rows (0.01%) — `cargo_group='TEST'` vẫn vào MV | Scale rất nhỏ, accept. |
| **Timezone UTC** | `toDate()` dùng UTC default | Đơn ship 00:30 VN ngày 7 = 17:30 UTC ngày 6 → bị tag date ngày 6 (sai 1 ngày). Edge case nhỏ. |
| **3 MV duplicate variants** | `mv_loose_picking_clickhouse_phong_test`, `mv_test_loose_picking` | DA pending xóa (BUG-5). |

### 6.7 Refresh cadence

- `mv_loose_picking_clickhouse`: **REFRESH EVERY 1 HOUR**

→ Chậm hơn các MV khác (Flash Daily 5'/15', Late Order 5'). **Acceptable** vì feature là post-shipment analysis (đơn đã ship, không cần realtime).

→ UI nên hiển thị "Last MV refreshed at HH:MM" để user biết. Nhấn Apply không trigger MV refresh (chỉ query MV current state).

### 6.8 Divide-by-zero behavior

| Source | Behavior |
|---|---|
| MV column `pct_loose_picking` raw | `nullIf` → trả NULL |
| SQL Registry queries | `CASE WHEN denom=0 THEN 0 ELSE ...` → trả 0 |

→ UI dùng SQL aggregation (trả 0), KHÔNG dùng MV column raw để hiển thị.

---

## 7. Out of Scope

- Picker filter / Picker Performance — MV không có cột picker, không track per-worker. (Pending Q1 §10.)
- Picking Efficiency (Lines/hour) / Picking Accuracy — không có time tracking và correctness data.
- Recommendation engine ("đề xuất chuyển sang full case") — UI read-only, không tự đề xuất. (Pending Q2 §10.)
- Live in-progress monitoring — chỉ post-shipment (status_code='95').
- Brand filter / Search SKU — không build (per BA decision).
- Status thresholds Optimal/Balanced/Needs Optimization (theo old spec) — bỏ. Chỉ dùng %Loose color badge §FR-01.
- Period server query (weekly/monthly) — UI tự gộp client-side.
- Status badge dựa SLA — Mondelez chưa định ngưỡng SLA.
- Real-time websocket — không.

---

## 8. Dependencies

| Dependency | Mô tả | Refresh |
|---|---|---|
| SWM ClickHouse (`swm_dwh_mondelez.*`) | dim_orderdetail, dim_orders, dim_pickdetail, dim_receiptdetail, dim_sku, dim_pack | CDC realtime |
| STM ClickHouse (`stm_dwh_mondelez.*`) | subdim_cus_product (item_code lookup) | CDC realtime |
| `analytics_workspace.mv_loose_picking_clickhouse` | Master MV cho FR-01 → FR-07 | **1 HOUR** |
| `analytics_workspace.mv_masterdata_location` | Customer location → region (`group_area_name`) | CDC |
| `internal.convert_cargo` | SKU → cargo group classification | static |
| `CTowerController.cs` | API: 3 endpoint (`fetchLoosePicking`, `fetchLoosePickingByWh`, `fetchLoosePickingBySku`) — đều query cùng MV | — |
| `LoosePickingView.tsx` | UI component chính | — |
| `GLOSSARY.md` → Loose Picking, CSE, Pallet | Định nghĩa thuật ngữ chuẩn | — |

---

## 9. Business Workflow

### 9.1 Luồng sử dụng trong ngày

```
Daily morning:
  Warehouse Manager / Logistics Supervisor mở Loose Picking View
  → Default filter: last 7 days, Warehouse = ALL
  → Xem KPI cards: % Loose toàn hệ thống → màu (🟢/🟡/🔴)
  → So sánh stacked bar by warehouse → kho nào có %loose cao nhất
  → Drill Top SKU by Loose Cases → SKU nào gây tải pick lẻ
  → Phối hợp với picking team / SKU planning để tối ưu pack config

Throughout day:
  Control Tower Analyst phân tích trend
  → User nhấn Apply để query lại MV (UI không auto-refresh, MV refresh 1h)
  → Nice-to-have: trend chart "% Loose by ship_date" 7 ngày qua
  → Nice-to-have: pivot customer × region để identify chuỗi MT có pattern loose cao

End of day:
  Analyst export bảng raw 14 cột (FR-05) sang Excel/CSV
  → Báo cáo Management về SKU có %loose cao nhất tuần
  → Đề xuất action plan optimize pack/pallet
```

### 9.2 Luồng theo vai trò

| Vai trò | Bước 1 | Bước 2 | Bước 3 | Output |
|---|---|---|---|---|
| **Warehouse Manager** | Filter theo kho | KPI cards + stacked bar | Top SKU loose | Tối ưu pick strategy |
| **Logistics Supervisor** | Daily check 4 thẻ KPI | Pie chart distribution | Phối hợp picking team | Giảm pick lẻ |
| **Control Tower Analyst** | Trend chart by date | Pivot customer/region | Export EOD | Báo cáo Mgmt |
| **Senior Management** | KPI tổng %loose | Snapshot weekly | — | Decision pack config |

### 9.3 Điều kiện đặc biệt

| Tình huống | Hành vi hệ thống | Người dùng cần làm gì |
|---|---|---|
| %Loose < 30% (toàn kho) | KPI badge xanh | Hoạt động tốt — không cần action |
| %Loose 30-40% | KPI badge vàng | Theo dõi xu hướng, drill top SKU |
| %Loose > 40% | KPI badge đỏ | Action plan — review SKU mix, pack config |
| User chọn VN821/VN831 | Empty state (no data) | Đợi DA fix BUG-2 |
| SKU không có pack info | NULL cse_full/cse_loose, không xuất hiện trong KPI cards | DA verify SKU master |
| Customer chuỗi MT (WinMart…) | Region = empty → bucket "Unclassified" | Bình thường — masterdata location chưa cover |
| Dữ liệu chưa cập nhật | MV refresh 1h → có thể trễ tối đa 1h | Nhấn Apply để query lại MV state |

---

## 10. Open Questions

| # | Câu hỏi | Người cần trả lời | Trạng thái |
|---|---|---|---|
| Q1 | Picker filter / Picker Performance — confirm bỏ hay roadmap thêm sau? Cần DA build pipeline mới nếu thêm. | BA + Operations | ⏳ Chờ (default = bỏ) |
| Q2 | Recommendation engine ("đề xuất chuyển sang full case") — confirm bỏ hay phase 2 build sau? | BA + Product Owner | ⏳ Chờ (default = bỏ) |
| Q3 | Pivot customer/region (NFR-02) có ai stakeholder không? Roadmap implement? | BA | ⏳ Chờ |
| Q4 | DA fix BUG-1 (Top SKU SQL paste nhầm) khi nào? | DA | 🔴 Pending |
| Q5 | DA fix BUG-2 (VN821/VN831 implicit drop) khi nào? | DA | 🔴 Pending |
| Q6 | DA fix BUG-3 (Redshift `::DECIMAL` cast) khi nào? | DA | 🟡 Pending |
| Q7 | DA cleanup duplicate MV (BUG-5) khi nào? | DA | 🟢 Pending |
| Q8 | UI fix color Full Case (slate gray → green) — ai own? | FE | ⏳ Chờ |

**Đã resolved (per BA + Operations + DA 2026-05-06):**
- ✅ Status thresholds Optimal/Balanced/Needs — bỏ, chỉ %Loose color badge (B1 + O2)
- ✅ Period filter — UI gộp client-side (B4)
- ✅ ViewMode — bỏ, chỉ 1 view (B5)
- ✅ Brand filter + Search SKU — bỏ (B6)
- ✅ Cargo Group filter — thêm (B7)
- ✅ Refresh 1 HOUR acceptable — feature post-shipment (B8 + O3)
- ✅ Feature scope = post-shipment (B9, status_code='95')
- ✅ Detail table 14 cột tất cả (B10)
- ✅ Color Full Case → Green (B11)
- ✅ Color thresholds %Loose: <30% green, 30-40% amber, >40% red (B12)
- ✅ Target users = 4 đối tượng (B13)
- ✅ Mục tiêu = giám sát fast outbound, liên kết cost/productivity/fill rate (O1, O5)
- ✅ Frequency = daily (O3)
- ✅ Order types XB2BMC + XTNPP đều là xuất bán — không phải internal transfer (D10)
- ✅ 1 pack/SKU là nguyên tắc Mondelez (D11)
- ✅ 3 endpoint riêng cùng query 1 MV (E1, E2)
- ✅ TopN BE LIMIT (E3)
- ✅ VN821/VN831 dropdown → empty state (E4)

---

## 11. Known Issues (BUGs cần fix)

| ID | Mức độ | Mô tả | Vị trí | Impact |
|---|---|---|---|---|
| **BUG-1** | 🔴 HIGH | "Top SKU theo tổng thùng lẻ" ClickHouse SQL bị paste nhầm — group by `whseid + ship_date` thay vì `item_code` | `sql-registry.md` line 2596–2625 | Top SKU chart hiển thị sai (daily trend thay vì SKU ranking) |
| **BUG-2** | 🔴 HIGH | VN821/VN831 implicit drop — order type filter chỉ cover BKD/NKD, không có nhánh cho VN821/VN831 → ~91K orderdetail rows mất khỏi MV | DDL `mv_loose_picking_clickhouse` line 4938 | Reporting EOD thiếu data 2 kho. Same pattern Flash Report BUG-6 + Late Order. |
| **BUG-3** | 🟡 MEDIUM | "Report raw data" + "pivot customer/region" có Redshift cast `::DECIMAL(18,6)` trong nhánh ClickHouse | `sql-registry.md` line 2680, 2713 | Query fail trên ClickHouse engine |
| **BUG-4** | 🟡 MEDIUM | MV refresh 1 HOUR — chậm 12x so với Flash/Late Order. **Accepted** per BA (B8) vì post-shipment analysis. | DDL line 4828 | Acceptable — không phải bug nữa, chỉ document |
| **BUG-5** | 🟢 LOW | 3 MV duplicate variants chưa cleanup: `mv_loose_picking_clickhouse_phong_test`, `mv_test_loose_picking` | DDL list | Tốn 600 MB+ disk |
| **BUG-6** | 🟢 LOW | UI color Full Case = `#334155` (slate gray) — bạn quyết định đổi sang Green (per B11) | `LoosePickingView.tsx` line 32 | UX consistency |
| **BUG-7** | 🟢 LOW | Timezone `toDate()` UTC default — đơn ship 00:30 VN ngày sau bị tag date ngày trước | DDL | Edge case nhỏ |

> Audit chi tiết:
> - S2 (Data Pipeline): `docs/audit-results/s2-loose-picking-20260506.md`
> - S1 (BA Logic Check): `docs/audit-results/s1-loose-picking-20260506.md`
