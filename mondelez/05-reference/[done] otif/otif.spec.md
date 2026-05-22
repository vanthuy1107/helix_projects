# Spec – OTIF View (On-Time In-Full Performance)

**UI:** `control-tower/ui/src/views/control-tower/order-monitor/OTIFView.tsx`
**API:** `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs` (lines 1465–1660)
**Wireframe:** `docs/02-features/otif/otif.wireframe.md`
**Data source:** `analytics_workspace.mv_otif` (ClickHouse, refresh 5 phút)

---

## 1. Overview

Màn hình theo dõi hiệu suất giao hàng đúng hạn và đầy đủ (OTIF – On-Time In-Full). Phân tích theo khu vực giao hàng, lý do giao trễ, lý do thiếu hàng, trend theo thời gian, và chi tiết từng đơn hàng.

Định nghĩa KPI chuẩn: xem `docs/GLOSSARY.md` § "On-Time In-Full".

---

## 2. API Endpoints

**`OtifSummaryFilter`:** `{ whseid?, area?, groupOfCargo?, transporter?, dateType?, fromDate?, toDate? }`
- `dateType` enum: `'ETA gửi thầu'` (default) | `'ATA chi tiết chuyến'` | `'ALL'` (chỉ Report raw chấp nhận `'ALL'`)
- Tất cả filter mặc định `'ALL'` nếu không truyền.

### 2.1 Endpoints hiện tại (5)

| Function | API Path | Return Type | Mô tả |
|---|---|---|---|
| `fetchOtifSummary` | `GET /api/ctower/otif/summary` | `OtifSummary` | KPI tổng: totalSo, ontimeSo, pctOntime, infullSo, pctInfull, otifSo, pctOtif |
| `fetchOtifProgressByArea` | `GET /api/ctower/otif/progress-by-area` | `OtifAreaProgressRow[]` | % OTIF/Ontime/Infull theo khu vực giao hàng |
| `fetchOtifFailOntimeReasons` | `GET /api/ctower/otif/fail-ontime-reasons` | `OtifFailReasonRow[]` | Phân bổ đơn Failed Ontime theo `not_ontime_reason` |
| `fetchOtifFailInfullReasons` | `GET /api/ctower/otif/fail-infull-reasons` | `OtifFailReasonRow[]` | Phân bổ đơn Failed Infull theo `not_infull_reason` |
| `fetchOtifTrendByTime` | `GET /api/ctower/otif/trend-by-time` | `OtifTrendByTimeRow[]` | Trend OTIF theo day/week/month: totalSo, otifSo, pctOtif |

### 2.2 Endpoints cần bổ sung (Figma-confirmed)

Dựa trên Figma 2026-05-07, UI yêu cầu thêm các endpoint sau:

| Function (đề xuất) | SQL Registry / Note | Chart/Table dùng |
|---|---|---|
| `fetchOtifProgressByChannel` | Mở rộng từ "OTIF chiều vận hành" — group by `group_name` | Chart "OTIF/Ontime/Infull theo kênh bán hàng" |
| `fetchOtifProgressByCarrier` | Group by `ten_ngan_nha_van_tai` | Chart "OTIF/Ontime/Infull theo nhà vận tải" |
| `fetchOtifProgressByWarehouse` | Group by `whseid` | Chart "OTIF/Ontime/Infull theo kho" |
| `fetchOtifByOperationDimension` | `sql-registry.md` § "%OTIF chiều vận hành" (17910) | Table "%OTIF chiều vận hành" (4-dim grouping: NVT × Kênh × Nhóm × Khu vực) |
| `fetchOtifFailOntimeBreakdown` | Mở rộng từ "Report fail ontime" — pivot theo reason | Table "Số đơn fail Ontime" (cột pivot: Late arrival/wh call/pickup/departure/delivery) |
| `fetchOtifFailReport` | § "Report fail ontime, fail infull" (18164) | (alternative) Long-form report |
| `fetchOtifReportRaw` | § "Report raw data" (17551) | Table "Bảng chi tiết đơn hàng" — replace `buildMock()` |

> 4 chart theo dimension (area/channel/carrier/warehouse) có thể consolidate thành **1 endpoint** `fetchOtifProgressByDimension(?dimension=area|channel|carrier|warehouse)` để tiết kiệm code/cache.

### 2.3 DTO shapes

```ts
OtifSummary           = { totalSo, ontimeSo, pctOntime, infullSo, pctInfull, otifSo, pctOtif }
OtifAreaProgressRow   = { khuVucDoiXe, totalSo, ontimeSo, pctOntime, infullSo, pctInfull, otifSo, pctOtif }
OtifFailReasonRow     = { reason, failSo }
OtifTrendByTimeRow    = { day, week, month, totalSo, otifSo, pctOtif }
```

---

## 3. State Management

| State | Type | Default | Mô tả |
|---|---|---|---|
| `apiSummary` | `OtifSummary \| null` | `null` | KPI tổng từ API |
| `apiByArea` | `OtifAreaProgressRow[]` | `[]` | Dữ liệu theo khu vực |
| `apiFailOntimeReasons` | `OtifFailReasonRow[]` | `[]` | Lý do giao trễ |
| `apiFailInfullReasons` | `OtifFailReasonRow[]` | `[]` | Lý do thiếu hàng |
| `apiTrendByTime` | `OtifTrendByTimeRow[]` | `[]` | Trend OTIF theo thời gian |
| `apiSummaryError` | `string \| null` | `null` | Lỗi API |
| `warehouseFilter` | `string` | `'ALL'` | Filter kho (applied) |
| `deliveryAreaFilter` | `string` | `'ALL'` | Filter khu vực giao hàng (single-select) |
| `groupOfCargoFilter` | `string` | `'ALL'` | Filter nhóm hàng |
| `transporterFilter` | `string` | `'ALL'` | Filter nhà vận tải |
| `dateTypeFilter` | `OtifDateTypeValue` | `'ETA gửi thầu'` | Loại ngày lọc |
| `fromDateFilter` / `toDateFilter` | `string` | today | Khoảng thời gian lọc |
| `*Draft` states | (tương ứng) | — | Draft chưa Apply |

---

## 4. Filters & Inputs

| Filter | Loại UI | Options | Ghi chú |
|---|---|---|---|
| Warehouse | Single-select dropdown | `'ALL'` + danh sách kho | — |
| Delivery Area | **Single-select dropdown** | `'ALL'` + 11 khu vực | Xem §4.1 |
| Group of Cargo | Single-select dropdown | `'ALL'` + DRY/FRESH/MOONCAKE/POSM/TEST/EQUIPMENT/PM/Unclassified | NULL → `'Unclassified'` (SQL Registry) |
| Transporter | Single-select dropdown | `'ALL'` + danh sách nhà vận tải | NULL → `'Unclassified'` |
| Date Type | Single-select | `'ETA gửi thầu'` (default) \| `'ATA chi tiết chuyến'` | `'ALL'` chỉ áp dụng cho Report raw |
| Date Range | Date picker (from–to) | — | Default = today; Apply mới fetch |

### 4.1 Danh sách Khu vực đội xe

11 areas thực tế trong `mv_otif`:
- North East - North West, Ha Noi, Ho Chi Minh, South East, North Central Coast, Central, Mekong 1, Mekong 2, South Central Coast, Central highland, South East - Lam Dong

UI hardcode 4 areas trong constant `AREAS`: `South East`, `Ho Chi Minh`, `Mekong 1`, `Mekong 2`. `areaOptions` = union(`AREAS`, areas dynamic từ API), sort theo locale 'vi'.

**Empty area policy:** UI fallback `'Chưa phân loại'` (OTIFView.tsx:980); spec đề xuất chuẩn hóa thành `'Không xác định'` (xem PRD D6).

---

## 5. Derived / Computed Data

| useMemo | Mô tả |
|---|---|
| `areaOptions` | Hợp nhất constant `AREAS` + areas từ API data, sort 'vi' |
| `filtered` | Mock rows sau khi lọc theo `deliveryAreaFilter` (chỉ dùng cho buildMock fallback) |
| `kpiMetrics` | Extract `{ totalOrders, pctOntime, pctInfull, pctOtif }` từ `apiSummary` (hoặc 0 nếu null) |
| `byArea` | Map `apiByArea` → chart format `{ area, ontime, infull, otif, totalSo }`; empty area → `'Chưa phân loại'` |
| `reasonMix` | Map `apiFailOntimeReasons` → pie chart `{ name, value, color }`; color predefined per reason key, fallback cycle |
| `infullReasonMix` | Map `apiFailInfullReasons` → pie chart cùng structure |
| `detailRows` | Trả về `filtered` nếu không có error, ngược lại `[]` (sẽ replace bằng API thật khi tích hợp `fetchOtifReportRaw`) |

---

## 6. Business Logic Rules (Production reality)

> Logic chính thức được implement tại `analytics_workspace.mv_otif` (xem DDL `clickhouse-ddl/analytics-workspace_mvs.md` § `mv_otif` lines 5442–5660). UI chỉ display, **không tính lại KPI** khi đã tích hợp API.

### 6.1 Status classification

| Field | Rule |
|---|---|
| `ontime_status` | `'Ontime'` nếu `ETA >= ATA`; `'Failed Ontime'` nếu `ETA < ATA`; `'Không có dữ liệu STM'` nếu `has_stm_order = 0`; `NULL` nếu ETA hoặc ATA NULL |
| `infull_status` | `'Infull'` nếu `round(sum_original_cse, 4) = round(sum_shipped_cse, 4) AND round(sum_shipped_cse, 4) = round(sum_giao_cse, 4)`; `'Failed Infull'` nếu `original > shipped` hoặc `shipped > giao`; `'Không có dữ liệu STM'` nếu `has_stm_order = 0` |
| `otif_status` | `'OTIF'` nếu `ontime AND infull` (cả 2 = `'Ontime'/'Infull'`); `'Failed OTIF'` nếu fail ít nhất 1 và có STM data; `'Không có dữ liệu STM'` nếu `has_stm_order = 0` |

> **Lưu ý**: Trạng thái `'Không có dữ liệu STM'` chỉ xuất hiện khi `eta_giao_hang_cho_npp IS NULL`. Khi UI lọc theo date range (mặc định), các rows này tự động bị loại — nên KPI production hiển thị đúng.

### 6.2 % KPI aggregation (per query)

```sql
% Ontime = countDistinct(if(ontime_status = 'Ontime', so, NULL)) / countDistinct(so) * 100
% Infull = countDistinct(if(infull_status = 'Infull', so, NULL)) / countDistinct(so) * 100
% OTIF   = countDistinct(if(otif_status   = 'OTIF',   so, NULL)) / countDistinct(so) * 100
```
- Mẫu số = tổng SO trong filter scope (sau khi date filter loại NULL ETA/ATA).
- Divide-by-zero protection: `if(tong_so_don = 0, 0, ...)` trong SQL; `r.totalSo > 0 ? ... : 0` trong UI.

### 6.3 `not_ontime_reason` (timestamp-based logic, English labels)

Nguồn: `mv_otif` line 5645 — concat các pattern matched:

| Reason | Điều kiện trigger |
|---|---|
| `Late arrival by Transport` | `Giờ gọi xe < ETD chuyến gửi thầu < Giờ vào cổng` (xe đến trễ so với ETD) |
| `Late warehouse call by Warehouse` | `ETD chuyến gửi thầu < Giờ đăng tài AND Giờ gọi xe > ETD` (kho gọi xe trễ so với ETD) |
| `Late pickup by Warehouse` | `ETD > Giờ vào cổng AND Actual Ship Date > (TG bắt buộc rời kho - 10p)` (kho xuất hàng trễ) |
| `Late departure by Transport` | `ETD > Giờ vào cổng AND Actual Ship < (TG bắt buộc - 10p) AND TG bắt buộc < Giờ ra cổng` (xe ra cổng trễ) |
| `Late delivery by Transport` | `ETD > Giờ vào cổng AND Actual Ship < (TG bắt buộc - 10p) AND TG bắt buộc > Giờ ra cổng AND ETA < ATA` (xe trên đường lâu) |
| `Thiếu dữ liệu đăng ký dock` | Catch-all khi không match pattern nào (thiếu timestamp dock) |

> **Multi-reason concat**: Field này có thể chứa multiple reasons separated bởi `,\r\n\r\n…`. Tuy nhiên data reality (verified 2026-05-07): **0/61,970 rows** có compound string — luôn single-valued trong production. UI tooltip hiện ghi "có thể nhiều reason" — phù hợp lý thuyết nhưng không xảy ra thực tế.

### 6.4 `not_infull_reason` (CSE-based logic)

Nguồn: `mv_otif` line 5644:

| Reason | Điều kiện |
|---|---|
| `Warehouse + Transport Infull Failure` | `original > shipped > giao` (cả 2 cùng rớt) |
| `Warehouse Infull Failure` | `original > shipped AND shipped = giao` (chỉ kho rớt) HOẶC `original > shipped` mà không thuộc nhóm trên |
| `Transport Infull Failure` | `original = shipped AND shipped > giao` (chỉ vận tải rớt) |

Distribution thực tế (Apr 2026): Transport 74,744 / Warehouse 4,678 / Combined 1,080.

### 6.5 Reason Colors (Figma 2026-05-07)

Theo Figma: 2 chart fail reason là **horizontal bar** (không phải pie), dùng đơn sắc:

| Chart | Màu | Reasons hiển thị |
|---|---|---|
| Lý do fail ontime | 🟧 Orange (`#F59E0B` / Amber) | Late delivery / arrival / wh call / pickup / departure by …, Thiếu dữ liệu đăng ký dock |
| Lý do fail infull | 🟥 Red (`#EF4444`) | Transport Infull / Warehouse Infull / Warehouse + Transport Infull Failure |

> Code legacy có thể còn pie chart logic + per-reason colors — cần align với Figma (horizontal bar, đơn sắc theo nhóm).

---

## 7. Color / Status Coding

| KPI | Threshold | Áp dụng |
|---|---|---|
| % On-Time | 🟢 ≥ 95% / 🟡 85–94% / 🔴 < 85% | KPI card, Area chart |
| % In-Full | 🟢 ≥ 95% / 🟡 85–94% / 🔴 < 85% | KPI card, Area chart |
| % OTIF | 🟢 ≥ 90% / 🟡 80–89% / 🔴 < 80% | KPI card, Area chart, Trend threshold line |
| Row table | 🟢 `Đạt OTIF` / 🟡 `Failed Ontime` only / 🔴 `Failed Infull` (any) | Detail table |

---

## 8. User Interactions

| Tương tác | Hành động |
|---|---|
| Đổi filter dropdown | Cập nhật draft state |
| Click **Apply filter** | Gọi tất cả fetch API song song với filter mới |
| Click **Reset filter** | Reset draft về default (`'ALL'`, current date range) |
| Đổi Tab (Biểu đồ / Chi tiết bảng) | `LeftStickySectionTabs` |
| Hover chart | Tooltip Recharts hiển thị chi tiết |
| Toggle Day/Week/Month (chart trend) | Đổi grain time, refetch trend data |
| Toggle "Nhóm theo" checkboxes (table tab) | Re-aggregate table client-side hoặc refetch tuỳ design |
| Sort table column | `nextSortState` toggle desc → asc → none |
| Search column (per-column input) | Filter rows client-side |
| Click **Cấu hình bảng** | Mở dialog ẩn/hiện cột |
| Click **Xuất** | Export table CSV/XLSX |
| Click số orange "Số đơn fail Ontime" (Section 2 table tab) | (suggested) drill xuống detail rows fail ontime |
| Drill-down KPI card → detail table | ❌ **Không có** (PRD D8 = N) |

---

## 9. Sub-components

| Component | Vai trò |
|---|---|
| `ViewQueryExportActions` | Export + Query action bar |
| `ControlTowerItemCard` | KPI card (Total Orders, % Ontime, % Infull, % OTIF) |
| `LeftStickySectionTabs` | Tab navigation (Biểu đồ / Chi tiết bảng) |
| `SortableHeader` | Header với 3-state sort (asc/desc/none) |
| `ChartHint` | Tooltip giải thích công thức KPI |
| Recharts: `BarChart`, `Bar`, `XAxis`, `Tooltip`, `Legend`, `Line`, `ComposedChart` | Grouped bar OTIF by dimension, fail reason horizontal bars, trend bar+line combo |

---

## 9.1 Layout (Figma 2026-05-07)

### Tab "Biểu đồ"

```
┌─ Filter bar: KHO | KHU VỰC GIAO HÀNG | NHÓM HÀNG | NHÀ VẬN TẢI | LOẠI NGÀY | DATE RANGE | Reset | Apply ┐
├─ Tab toggle: Biểu đồ | Chi tiết bảng
│
├─ 4 KPI cards (1 row, equal width):
│   ┌─ Tổng đơn ──────────┐ ┌─ % Ontime ──────────┐ ┌─ % Infull ──────────┐ ┌─ % OTIF ───────────┐
│   │ 3,118               │ │ 81.8% (2552 đơn)    │ │ 93.9% (2929 đơn)    │ │ 76.3% (2380 đơn)   │
│   │ Số đơn theo filter  │ │ Tỷ lệ đơn giao đúng │ │ Tỷ lệ đơn giao đủ   │ │ Tỷ lệ đơn đạt đủ   │
│   │ OTIF                │ │ hạn                 │ │ số lượng            │ │ và đúng hạn        │
│   └─────────────────────┘ └─────────────────────┘ └─────────────────────┘ └────────────────────┘
│
├─ Chart 1: "OTIF / Ontime / Infull theo khu vực"  ← Grouped bar (Cyan/Green/Purple) per area
├─ Chart 2: "OTIF / Ontime / Infull theo kênh bán hàng"  ← Grouped bar per channel (KA/MT/GT/…)
├─ Chart 3: "OTIF / Ontime / Infull theo nhà vận tải"  ← Grouped bar per carrier
├─ Chart 4: "OTIF / Ontime / Infull theo kho"  ← Grouped bar per warehouse (BKD1/NKD/VN831/…)
├─ Chart 5: "%OTIF và số lượng đơn theo thời gian"  ← Combo bar (Số đơn/day) + line (%OTIF)
│           ▸ Toggle Day | Week | Month (top-right)
│           ▸ Footer: "Số đơn/{grain} · N {grain}" + total DO
└─ 2 charts side-by-side:
    ┌─ "Lý do fail ontime" (horizontal bar, ORANGE) ─┐ ┌─ "Lý do fail infull" (horizontal bar, RED) ─┐
    │ Late delivery by Transport         ▮▮▮▮▮ 272  │ │ Transport Infull Failure       ▮▮▮▮▮ 112    │
    │ Late arrival by Transport          ▮▮▮ 180    │ │ Warehouse + Transport          ▮ 16         │
    │ Late warehouse call by Warehouse   ▮ 78       │ │ Warehouse Infull Failure       ▮ 14         │
    │ Thiếu dữ liệu đăng ký dock         ▮ 36       │ │                                              │
    │                          Footer: 566 DO       │ │                          Footer: 142 DO     │
    └────────────────────────────────────────────────┘ └──────────────────────────────────────────────┘
```

### Tab "Chi tiết bảng"

```
├─ Filter bar (giống Tab Biểu đồ)
├─ "Nhóm theo:" multi-select checkboxes:
│     ☑ Nhà vận tải   ☑ Kênh bán hàng   ☑ Nhóm hàng   ☑ Khu vực đội xe
│
├─ Section 1: "%OTIF chiều vận hành"  [Xuất] [Cấu hình bảng]
│     Cột: <dim cols> | Tổng số đơn | %OTIF (% và số đơn) | %Ontime (% và số đơn) | %Infull (% và số đơn)
│     Per-column search inputs (header row)
│
├─ Section 2: (cùng grouping) — fail-reason pivot
│     Cột: <dim cols> | Tổng số đơn | Số đơn fail Ontime [orange] |
│            Late arrival by Transport | Late wh call by Warehouse |
│            Late pickup by Warehouse | Late departure by Transport | Late delivery by Transport
│
└─ Section 3: "Bảng chi tiết đơn hàng"  [Xuất] [Cấu hình bảng]
      Cột: Mã đơn hàng | Mã kho | Khu vực đội xe | Nhóm hàng | Group |
            Tên ngắn nhà vận tải | Mã đối tác giao | Tên đối tác giao |
            Loại xe vận hành | Loại xe gửi thầu | ETA | ATA | Mã nhà xe |
            Original | Original CBM | (… cấu hình bảng cho phép thêm)
      Pagination: 10 rows/page, 318 pages → ~3,180 DO total (matches Tổng đơn KPI)
```

### KPI Card content (chốt theo Figma)

| Card | Big number | Sub | Description |
|---|---|---|---|
| Tổng đơn | `totalSo` | — | "Số đơn theo filter OTIF" |
| % Ontime | `pctOntime%` | `{ontimeSo} đơn` | "Tỷ lệ đơn giao đúng hạn" |
| % Infull | `pctInfull%` | `{infullSo} đơn` | "Tỷ lệ đơn giao đủ số lượng" |
| % OTIF | `pctOtif%` | `{otifSo} đơn` | "Tỷ lệ đơn đạt đủ và đúng hạn" |

### Loại ngày dropdown (Figma chốt)

Format hiển thị: `'ETA gửi thầu (đơn)'`, `'ATA chi tiết chuyến'` — suffix `(đơn)` để phân biệt nguồn ngày từ DO vs trip.

---

## 10. Loading & Error States

| Tình huống | Xử lý |
|---|---|
| Đang fetch API | `isLoading = true` → hiển thị skeleton/spinner |
| API error | `apiSummaryError != null` → `detailRows = []`, KPI cards hiển thị 0, banner error |
| `apiSummary == null` | `kpiMetrics` trả về 0 cho tất cả metrics |
| Empty `apiByArea` | `byArea` chart trả về `[]`, chart hiển thị empty state |
| Tổng SO = 0 (filter quá hẹp) | KPI hiển thị 0% (divide-by-zero protected) |

---

## 11. Edge Cases

| # | Tình huống | Xử lý production |
|---|---|---|
| E1 | `eta_giao_hang_cho_npp IS NULL` | Status = `'Không có dữ liệu STM'` (vì luôn đi kèm `has_stm_order=0`); date filter tự động loại |
| E2 | `ata_den IS NULL` (đơn chưa đến) | `ontime_status = NULL` (không phân loại); KPI bỏ qua trong `countIf` |
| E3 | `has_stm_order = 0` | All status = `'Không có dữ liệu STM'`; chiếm 60.7% MV nhưng 0% sau date filter |
| E4 | `sum_original_cse = 0` | `pct_otif = NULL`; không ảnh hưởng status |
| E5 | `khu_vuc_doi_xe = ''` (empty) | UI render `'Chưa phân loại'`; ~4,500 SO/tháng (cần PRD D6 chuẩn hóa) |
| E6 | `group_of_cago = NULL` | Filter SQL fallback `'Unclassified'`; UI dropdown chỉ hiển thị giá trị thực |
| E7 | Date type = `'ALL'` | Chỉ Report raw query support; các query KPI khác sẽ trả empty |
| E8 | Tổng DO = 0 (filter trả empty) | KPI = 0% (`if(tong_so_don=0, 0, ...)` trong SQL + `r.totalSo > 0 ? ... : 0` trong UI) |
| E9 | Multi-reason `not_ontime_reason` (concat) | Theory: SQL group ra row riêng; reality: 0 occurrences trong production |
| E10 | API timeout / 5xx | UI hiển thị error banner; charts/table empty; user click Apply lại để retry |
| E11 | Duplicate SO across `whseid` | MV ORDER BY (so, whseid) → có thể có 2 row/SO khác whseid; KPI dùng `countDistinct(so)` nên không double-count |
| E12 | Timezone mismatch (DateTime64 UTC vs DateTime local) | MV mix cả 2 — risk: ATA/ETA có thể lệch ±7h khi compare. Cần verify với DA team |
| E13 | MV refresh delay (5 phút) | Không có cảnh báo "data cũ" trong UI; chấp nhận trễ 5p (PRD D7) |
| E14 | Filter area = single string (UI dropdown) | API accept 1 area value → consistent. **Không phải multi-select** như spec cũ ghi nhầm |

---

## 12. Workflow

### 12.1 Page Load Flow

```
Người dùng mở OTIF View
  → Khởi tạo default filter: dateType='ETA gửi thầu', date=today,
    area/wh/cargo/transporter='ALL'
  → Promise.all([fetchOtifSummary, fetchOtifProgressByArea,
                 fetchOtifFailOntimeReasons, fetchOtifFailInfullReasons,
                 fetchOtifTrendByTime])
  → isLoading=true → hiển thị loading state
  → MV mv_otif đã pre-compute KPI (refresh 5 phút)
  → API trả KPI từ countIf trên filtered data
  → Render KPI cards, fail-reason pie charts, area bar chart, trend chart, detail table
```

### 12.2 Filter & Apply Flow

```
Người dùng thay đổi filter (dateType, dateRange, area, warehouse, group, transporter)
  → Cập nhật draft state
  → Click Apply → setXxxFilter(xxxDraft) trigger useEffect
  → Promise.all 5 API re-fetch song song
  → KPI tính lại trong SQL (không tính ở UI)
  → UI cập nhật cards + charts + table
```

### 12.3 OTIF Calculation (in SQL/MV — UI chỉ display)

```
Per SO trong mv_otif:
  → On-Time check: ATA <= ETA → 'Ontime'; ATA > ETA → 'Failed Ontime'; NULL → 'Không có dữ liệu STM'/NULL
  → In-Full check: round(original,4) = round(shipped,4) = round(giao,4) → 'Infull';
                   else → 'Failed Infull'
  → OTIF = 'Ontime' AND 'Infull' → 'OTIF'; else → 'Failed OTIF' (hoặc 'Không có dữ liệu STM')

KPI aggregation per filter scope:
  → % OTIF = countDistinct(SO if otif_status='OTIF') / countDistinct(SO)
  → Compare threshold: ≥90% green, 80-89% amber, <80% red

Fail-reason breakdown (chỉ trên rows Failed):
  → not_ontime_reason: 6 categories (timestamp-based)
  → not_infull_reason: 3 categories (cse-based)
  → Pie chart phân bổ theo reason
```

### 12.4 Trend Analysis Flow

```
fetchOtifTrendByTime trả về day/week/month rows:
  → Chart hiển thị OTIF % theo grain time đã chọn
  → So sánh với threshold line (90%)
  → Điểm dưới threshold hiển thị màu đỏ → cần điều tra
```

### 12.5 Error Handling Flow

```
Bất kỳ fetch nào failed
  → catch → setApiSummaryError(message)
  → Reset apiByArea/apiFail*/apiTrend = []
  → Detail table = []
  → Banner error với nút Retry (= Apply lại)
```

---

## 13. Data Quality Notes (cần DA verify)

| # | Vấn đề | Mức độ |
|---|---|---|
| Q1 | Upstream `mv_otif_swm_data`, `mv_otif_stm_data` có áp `is_deleted=0` không? CLAUDE.md yêu cầu BẮT BUỘC | 🟡 Cần verify |
| Q2 | Cancelled / Virtual / Test orders có được loại khỏi MV không? | 🟡 Cần verify |
| Q3 | Internal transfer orders có nằm trong scope OTIF không? | 🟡 PRD cần xác định |
| Q4 | Typo `'ATA chi tiết chuyên'` ở Redshift Report raw (sql-registry.md §17604) | 🟢 Low — Redshift sắp deprecate |
| Q5 | Timezone mix DateTime64('UTC') và DateTime (no tz) — risk lệch ±7h | 🟡 Cần verify |

---

## 14. Cross-references

- **PRD:** `docs/02-features/otif/prd.md`
- **GLOSSARY:** `docs/GLOSSARY.md` § "On-Time In-Full"
- **Wireframe:** `docs/02-features/otif/otif.wireframe.md`
- **SQL Registry:** `docs/03-engineering/sql-registry.md` § "OTIF - verified" (lines 16425–18406)
- **DDL:** `docs/03-engineering/data-sources/clickhouse-ddl/analytics-workspace_mvs.md` § `mv_otif` (5442–5660)
- **Audit results:**
  - S2 Pipeline: `docs/audit-results/s2-otif-20260507.md`
  - S1 BA Logic: `docs/audit-results/s1-otif-20260507.md`
