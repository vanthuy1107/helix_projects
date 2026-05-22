# PRD — Section Flash Daily: Báo cáo tiến độ E2E hằng ngày

| Trường | Giá trị |
|--------|---------|
| **Version** | 1.1.0 |
| **Ngày** | 2026-05-16 |
| **Trạng thái** | Storytelling refresh — scope locked, ready for dev |
| **Tác giả** | PM/DA via `/da-trace` (v1.0.0 baseline) + `/da-biz-ba` (v1.1.0 storytelling refresh after 3 rounds PM duyệt + 3 audit) |
| **Phạm vi** | `01-sections/flash-daily` — widget `WidgetFlashDaily` trên dashboard Smartlog Control Tower |
| **Branch** | `feat-flash-daily-refresh` (cut từ `main` 2026-05-16) |
| **Source code** | [`frontend/src/features/dashboard/components/widgets/flash-report/`](../../../../frontend/src/features/dashboard/components/widgets/flash-report/) |
| **Source of truth (decisions)** | [`analysis/flash-daily-oq-resolution.md`](analysis/flash-daily-oq-resolution.md) — §0-LOCKED layout, §0a Decisions Log (25 quyết định), §0c Audit findings (A1/A2/A3) |

---

## 1. Mục đích

Section Flash Daily cung cấp bảng điều khiển giám sát **tiến độ giao hàng end-to-end (E2E) trong ngày/kỳ ngắn** cho đội vận hành Mondelez. Người dùng theo dõi từng đơn DO chạy qua 5 trạng thái E2E (Chưa xuất kho → Đang xuất kho → Đã xuất kho → Đang vận chuyển → Đã vận chuyển), so sánh kế hoạch vs thực xuất theo nhiều chiều phân tích, và xác định khối lượng đang rớt / nguyên nhân rớt.

Khác `OTIF` (đo *kết quả* — ontime/infull sau khi giao xong) — **Flash Daily đo *quá trình* trong ngày**: kế hoạch SAP đẩy về bao nhiêu, kho/vận tải đang xử lý tới đâu, dự kiến hoàn thành bao nhiêu.

---

## 2. Người dùng mục tiêu

| Vai trò | Nhu cầu chính |
|---------|--------------|
| Quản lý vận hành (Ops Manager) | Xem tiến độ E2E tổng, biết kho/khu vực nào đang "đỏ" cần can thiệp trong ngày |
| Trưởng kho (WH Manager) | Đối chiếu kho mình quản lý — xuất kho được bao nhiêu so với kế hoạch SAP đẩy về |
| Chuyên viên kế hoạch (Supply Chain Planner) | Theo dõi tỷ lệ hoàn thành theo NPP/khách hàng, kênh bán hàng, khu vực giao |
| QA/CS (Customer Service) | Tra cứu chi tiết đơn DO đang ở trạng thái nào, lý do nếu bị rớt |

---

## 3. Định nghĩa nghiệp vụ

> **[Observed]** — Định nghĩa dưới đây trích từ `widget-flash-daily.tsx` (constants `STATUS_ORDER`, `FLASH_DAILY_HINTS`) và `dashboard-flash-report.json`.

### 3.1 Trạng thái E2E của đơn DO

5 trạng thái chuẩn (constant `STATUS_ORDER`):

| # | Trạng thái | Định nghĩa nghiệp vụ (theo `FLASH_DAILY_HINTS`) | Pre-compute logic ở CH MV (`e2e_label`) | Volume formula | Màu sắc |
|---|------------|------------------------------------------------|------------------------------------------|----------------|---------|
| 1 | **Chưa xuất kho** | Đơn mới tạo trên WMS, kho chưa xử lý (SWM = New) | Bucket `Chưa xuất kho` | `SUM(QTY OPEN)` theo UOM | `#858585` (grey) |
| 2 | **Đang xuất kho** | Đơn đã vào vận hành kho: allocate / pick / part-shipped, chưa hoàn tất xuất toàn bộ | Bucket `Đang xuất kho` | `SUM(QTY PICKDETAILED)` theo UOM | `#E18719` (amber) |
| 3 | **Đã xuất kho** | Kho hoàn tất bước xuất, NHƯNG xe **chưa rời kho** (chưa có tín hiệu ATD từ STM) | `actual_ship_date NOT NULL AND thoi_gian_di IS NULL` | `SUM(QTY SHIPPEDDETAIL)` theo UOM | `#4F2170` (violet) |
| 4 | **Đang vận chuyển** | Kho xuất xong + xe đã rời kho, NHƯNG chưa có tín hiệu xe giao tới khách từ STM | `thoi_gian_di NOT NULL AND ata_den IS NULL` | `SUM(QTY SHIPPEDDETAIL)` theo UOM | `#2D6EAA` (blue) |
| 5 | **Đã vận chuyển** | Có tín hiệu hoàn tất giao từ STM: trạng thái giao/chứng từ hoặc có ATA đến | `ata_den NOT NULL` | `SUM(Sản lượng giao)` theo UOM | `#287819` (green) |

> Tham chiếu `FLASH_DAILY_HINTS.{notStarted,loading,shippedAtWh,inTransit,delivered}` trong [widget-flash-daily.tsx:182-217](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L182-L217).

> **⚠ Đính chính v1.1.0** (audit A3 finding 1): "Đã xuất kho" và "Đang vận chuyển" cùng có volume formula `SUM(QTY SHIPPEDDETAIL)` nhưng **KHÔNG có rủi ro double-count**. ClickHouse MV `analytics_workspace.mv_flash_and_drop_report` pre-computes 2 status mutually exclusive ở field `e2e_label` qua check `thoi_gian_di IS NULL` — 1 đơn DO chỉ thuộc đúng 1 bucket tại 1 thời điểm. STM lag chỉ ảnh hưởng **operational** (đơn xe đã rời kho >12h nhưng `thoi_gian_di` vẫn NULL → đơn bị giữ ở bucket "Đã xuất kho" lâu hơn thực tế), KHÔNG inflate count tổng. Storytelling action: thêm caveat tooltip "Chưa nhận tín hiệu ATD từ STM" ở 2 KPI status này; tham chiếu §0c A3 finding 1 của oq-resolution.md.

### 3.2 Khái niệm dẫn xuất

| Thuật ngữ | Định nghĩa | Công thức |
|-----------|-----------|----------|
| **Kế hoạch xuất (Plan Export)** | Tổng volume kế hoạch trong kỳ từ SAP đổ về | `SUM(ORIGINAL)` theo UOM |
| **Thực xuất (Actual Export)** | Volume đã rời kho hoặc đã giao | `Σ(Đã xuất kho + Đang vận chuyển + Đã vận chuyển)` |
| **Hoàn thành (Done)** | Volume đã giao tới NPP | Khi trạng thái = "Đã vận chuyển" → `SUM(Sản lượng giao)` |
| **Còn lại (Remaining)** | Volume chưa hoàn thành | `Mục tiêu − Hoàn thành` |
| **% Hoàn thành** | Tỷ lệ hoàn thành | `Done / Plan × 100` |

> **[Observed]** — `getPlanAndActualExport()` ở [widget-flash-daily.tsx:354-364](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L354-L364); hint `completionReport` ở [widget-flash-daily.tsx:238-244](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L238-L244).

### 3.3 Đơn vị đo (UOM)

Người dùng có thể đổi UOM trên toàn widget. Các giá trị hỗ trợ:

| UOM | Mô tả | Format hiển thị |
|-----|------|----------------|
| `cse` (mặc định) | Case (thùng) | Số nguyên với phân tách hàng nghìn |
| `ton` | Tấn | 0–2 chữ số sau dấu phẩy |
| `cbm` | Mét khối | 0–2 chữ số sau dấu phẩy |
| `pallet` | Pallet | 0–2 chữ số sau dấu phẩy |
| `do` | DO-line (đếm dòng đơn) | Số nguyên, label cột = `DO-line` |

> **[Observed]** — `FlashStatusFilter['uom']` ở [flash-report-api.ts:7](../../../../frontend/src/features/dashboard/components/widgets/flash-report/flash-report-api.ts#L7); `formatValue()` ở [widget-flash-daily.tsx:280-292](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L280-L292).

### 3.4 Phân loại lý do rớt (Dropped Bucket)

> **[Observed]** — `droppedDeliveryMetricRows` ở [widget-flash-daily.tsx:1921-2049](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1921-L2049).

| Bucket | Pattern match nội dung field `delivery_to_customer` |
|--------|-----------------------------------------------------|
| **Tổng kế hoạch (Total Plan)** | "tổng kế hoạch" / "tong ke hoach" / "total plan" |
| **Xử lý thành công (Success)** | "xử lý thành công" / "xu ly thanh cong" / "success" |
| **Xử lý không thành công (Failed)** | "xử lý ko thành công" / "khong thanh cong" / "failed" |
| **Đang xử lý (In-progress)** | `Total − Success − Failed` (tính lại) |

Phân loại theo đơn vị hàng hoá: **DRY/FRESH (CSE)** và **POSM (PC)**. Lý do rớt cụ thể (column `remark_2`) được group ở bảng `dropReasonReport`.

---

## 4. Bộ lọc (Filters)

> **[Observed]** — `FLASH_FILTER_DEFINITIONS` ở [widget-flash-daily.tsx:366-442](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L366-L442).

| Filter | Key | Loại | Giá trị mặc định | Ghi chú |
|--------|-----|------|-----------------|---------|
| Kho | `whseid` | Multi-select | ALL | Options fallback: BKD1, BKD2, BKD3, NKD, VN821, VN831 (đã loại BKD pseudo + ALL) |
| Sales Channel | `group_name` | Multi-select | ALL | Options fallback: MT, GT, KA, B2B, EXPORT, OTHER |
| Cargo Group | `group_of_cargo` | Multi-select | ALL | Options fallback: FRESH, DRY, MOONCAKE, POSM/OFFBOM, TEST, PM, EQUIPMENT. Filter cha của Brand. |
| Brand | `brand` | Multi-select | ALL | Options fallback: Solite, AFC, Lu, Cosy, Oreo, Tết, Trung Thu, Slide, KD, RITZ, Toblerone. Phụ thuộc filter `group_of_cargo`. |
| Region | `region` | Multi-select | ALL | 10 options: South East, South East - Lam Dong, Ha Noi, Central highland, Mekong 1, Ho Chi Minh, North East - North West, North Central Coast, South Central Coast, Mekong 2 |
| UOM | `uom` | Single-select | `cse` | 5 options: cse, ton, cbm, pallet, do |
| Date Type | `dateType` | Single-select | `GI date` | 5 options: GI date, Actual Ship date, ETD gửi thầu, ATA đơn, ETA gửi thầu |
| Date Range | `dateRange` | Date range | Tháng hiện tại tới hôm nay (`thisMonthToTodayRange`) | — |

**Auto-apply**: `SqlFilterPanel` chạy chế độ `autoApply` — thay đổi filter → áp dụng ngay, KHÔNG cần nhấn Apply.

**Filter restore**: Trạng thái filter được persist vào localStorage với key `dashboard-widget-filter:{dashboardId}:{widgetId}`. Trước khi restore xong (`filterInitialized = false`) — widget KHÔNG gọi API.

---

## 5. Cấu trúc màn hình

> **[Observed]** — `WidgetFlashDaily` component ở [widget-flash-daily.tsx:979-2893](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L979-L2893); `FlashDailyDetailPanel` ở [widget-flash-daily-detail.tsx:36-172](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily-detail.tsx#L36-L172).

Section Flash Daily gồm **2 vùng chính**: Sticky filter bar (trên) + 2 tab nội dung (Chart / Chi tiết bảng).

> **v1.1.0 storytelling refresh**: §5.1-§5.3 ghi lại baseline v1.0.0 (6 KPI cards + 5 chart + 9 bảng). Layout mới v1.1.0 (6 levels L1-L6) thay thế 6 KPI cards bằng L1 hero + L3 funnel strip và thêm 2 sections mới (L2 Exception, L4 Drop Trend). Xem §5.4 bên dưới.

### 5.1 KPI Cards (đầu tab Chart)

6 thẻ hiển thị grid responsive (1 / 2 / 3 cột theo breakpoint `sm` / `xl`):

| # | Card | i18n key | Icon | Màu | Volume formula |
|---|------|---------|------|-----|----------------|
| 1 | **Tổng Volume Kế hoạch** | `totalVolume` | `Box` | `#10B981` (emerald) | `findPlannedTotalVolume(sqlCardsRows)` hoặc tổng 5 status |
| 2 | **Chưa xuất kho** | `statusNotShipped` | `Layers` | `#858585` | `statusValues['Chưa xuất kho']` |
| 3 | **Đang xuất kho** | `statusShipping` | `TrendingUp` | `#E18719` | `statusValues['Đang xuất kho']` |
| 4 | **Đã xuất kho** | `statusShipped` | `Truck` | `#4F2170` | `statusValues['Đã xuất kho']` |
| 5 | **Đang vận chuyển** | `statusInTransit` | `Truck` | `#2D6EAA` | `statusValues['Đang vận chuyển']` |
| 6 | **Đã vận chuyển** | `statusDelivered` | `Truck` | `#287819` | `statusValues['Đã vận chuyển']` |

Mỗi card có: top border gradient (0.5px) màu accent, icon background `color × 26 hex` (~15% opacity), hint tooltip ngầm dùng `FLASH_DAILY_HINTS`, giá trị format theo UOM hiện hành.

### 5.2 Charts (trong tab Chart, sau KPI cards)

Thứ tự render trên màn hình:

| # | Chart | i18n title | Loại | Kích thước | Chiều dữ liệu | Render order JSX line |
|---|-------|-----------|------|-----------|---------------|----------------------|
| 1 | **Theo khu vực giao hàng** | `chartByDeliveryArea` | Horizontal stacked bar | h = `clamp(480, n × 200, 1400)`px | Region (Y) | [2203](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L2203) |
| 2 | **Phân bổ E2E** | `chartE2eValueTitle` | Vertical bar (7 cột) | 288px | 7 cột = Kế hoạch + Thực xuất + 5 status | [2344](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L2344) (xl:grid-cols-2 với Wh) |
| 3 | **Tiến độ theo kho hệ thống** | `chartByWh` | Vertical stacked bar | 384px (h-96) | Warehouse (X) | [2429](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L2429) |
| 4 | **Theo NPP/Customer** | `chartByCustomer` | Horizontal stacked bar | h = `clamp(480, n × 200, 1400)`px | Customer/NPP (Y) — top 10 by total | [2562](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L2562) |
| 5 | **Theo kênh bán hàng** | `chartBySalesChannel` | Horizontal stacked bar | h = `clamp(480, n × 200, 1400)`px | Channel (Y) | [2729](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L2729) |

**Chart by Customer** có dropdown filter riêng (`customerDimensionFilter`): `Tất cả` / `NPP` / `Customer`. Heuristic `inferCustomerDimensionType()` dùng substring match `npp` / `distributor` để phân loại.

**Layout**: Chart E2E + Chart by Wh hiển thị grid 2 cột trên `xl+`, stack vertical dưới `xl`. Các chart khác full-width.

**Bar series mỗi chart**: 7 series cùng pattern — `Kế hoạch xuất` (#0EA5E9 sky) + `Thực xuất` (#16A34A green) + 5 status (theo `STATUS_COLORS`). Mỗi bar có LabelList số 1-decimal-place ở vị trí top/right tuỳ layout.

**Legend**: Custom legend in 7 entries cố định kể cả khi chart không có data tương ứng.

**Empty state**: Khi data array rỗng → chart render container rỗng (responsive container vẫn vẽ axis, không có bar). KHÔNG có message rõ ràng "Chưa có data".

**Export**: Mỗi `SectionPanel` có `ChartExportMenu` — export ảnh PNG (DOM-to-image) + CSV. Filename pattern: `flash-daily-{slug}`.

### 5.3 Tab Chi tiết bảng (Tab "Table")

`FlashDailyDetailPanel` render **9 bảng** liên tiếp (vertical stack), mỗi bảng dùng `WidgetGrid` với `gridKey` riêng:

| # | gridKey | Caption (i18n) | Page size | Cột chính |
|---|---------|----------------|-----------|----------|
| 1 | `DSHFLADTG01` | `completionReportTitle` — Report tỷ lệ hoàn thành | 20 | Kho × Kênh × Khu vực × Mục tiêu/Hoàn thành/Còn lại/% Hoàn thành |
| 2 | `DSHFLADTG02` | `detailReportTitle` — Báo cáo chi tiết E2E | 10 | Trạng thái × Volume × UOM |
| 3 | `DSHFLADTG03` | `summaryByWh` — Tổng hợp theo kho hệ thống | 10 | Tên × Total × Done × Pending × % Done |
| 4 | `DSHFLADTG04` | `summaryByCustomer` — Tổng hợp theo NPP/Customer | 10 | (Cùng schema #3) |
| 5 | `DSHFLADTG05` | `summaryByArea` — Tổng hợp theo khu vực giao hàng | 10 | (Cùng schema #3) |
| 6 | `DSHFLADTG06` | `summaryBySalesChannel` — Tổng hợp theo kênh bán hàng | 10 | (Cùng schema #3) |
| 7 | `DSHFLADTG07` | `dropReportTitle` — Report hàng rớt | 20 | Bucket × DRY&FRESH (CSE) × POSM (PC) × % DRY&FRESH × % POSM |
| 8 | `DSHFLADTG08` | `dropReasonTitle` — Report lý do rớt đơn | 10 | Remark × FRESH/DRY × POSM |
| 9 | `DSHFLADTG09` | `flashDetailTitle` — Chi tiết Flash | 20 | 32 cột chi tiết DO (xem §8 trong spec.md) |

Mỗi bảng có export CSV qua `onExportAllRows`. Filter cột bằng multiselect/text tuỳ field. Bảng `flashDetailTitle` (#9) dùng UOM-aware cell rendering — cột `ORIGINAL`/`SHIPPED`/`Sản lượng giao` đổi field theo UOM hiện hành (cse/ton+kg/cbm/pallet).

### 5.4 Layout v1.1.0 — Storytelling 6 levels (LOCKED 2026-05-16)

> Locked 2026-05-16 sau 3 rounds duyệt với PM Smartlog (25 quyết định A1-E5 + F1-F2 + G1-G7) + 3 audit agent (A1/A2/A3). Source of truth: [`analysis/flash-daily-oq-resolution.md`](analysis/flash-daily-oq-resolution.md) §0-LOCKED.

```
┌─────────────────────────────────────────────────────────────────────┐
│ FILTER BAR (sticky, autoApply) — giữ nguyên v1.0.0                  │
├─────────────────────────────────────────────────────────────────────┤
│ L1 HERO — % HOÀN THÀNH HÔM NAY (full-width)                         │
│   • Snapshot value + target 95% reference + RAG color               │
│   • Sub-numbers: Plan / Đã giao / Còn lại                           │
│   • KHÔNG có delta, KHÔNG có as-of timestamp                        │
├─────────────────────────────────────────────────────────────────────┤
│ L2 EXCEPTION SPOTLIGHT — 3 ô (hôm nay)                              │
│   • Top N kho off-target (< 85%)                                    │
│   • Đơn rớt chưa xử lý                                              │
│   • Khu vực dưới target                                             │
├─────────────────────────────────────────────────────────────────────┤
│ L3 FUNNEL 5 TRẠNG THÁI — strip compact 1 dòng                       │
│   • Chưa xuất → Đang xuất → Đã xuất → Đang vận → Đã vận             │
│   • Mỗi entry: volume + % share                                     │
│   • THAY THẾ 6 KPI cards baseline (§5.1)                            │
├─────────────────────────────────────────────────────────────────────┤
│ L4 TREND TỶ LỆ RỚT 14 NGÀY — chart MỚI (line) — xem §6.6            │
│   • Drop_rate = # đơn FAIL / Tổng kế hoạch (per day)                │
│   • 14 ngày fixed (không dropdown), áp cùng filter bar              │
│   • Reference: target ≤5% (solid red) + rolling 30d avg (dashed)    │
├─────────────────────────────────────────────────────────────────────┤
│ L5 DIMENSION DRILLDOWN — tabbed chart (hôm nay)                     │
│   • Tabs: Kho / Khu vực / Khách / Kênh                              │
│   • Horizontal bar % completion, sort worst-first, target line 95%  │
├─────────────────────────────────────────────────────────────────────┤
│ L6 DETAIL TABLES (tab riêng) — GIỮ NGUYÊN 9 bảng (D2 defer)         │
│   • T1 Completion — BỎ synthetic fallback (drift #7 fix)            │
│   • T2-T6 Summary, T7-T9 detail (giữ — cleanup ở phase sau)         │
└─────────────────────────────────────────────────────────────────────┘
```

**Storytelling principles**:
- Action title trên mỗi section (vd: "Hôm nay 73% kế hoạch đã hoàn thành — DƯỚI target 95%")
- RAG color theo target 95% — xem AC-12 ở §9
- Alert banner full-width khi overall < 80%
- BỎ dropdown `customerDimensionFilter` ở chart Customer ([[project-mondelez-npp-eq-customer]])
- BỎ subtitle "Plan CBM forced display" trên các chart
- Sửa `STATUS_ORDER` đúng thứ tự luồng E2E (xem spec §20 Drift #11)

**Out of scope v1.1.0** (xuất hiện trong oq-resolution.md §0-LOCKED):
- Delta vs hôm qua / vs same time yesterday (F2 reframe)
- Snapshot infrastructure per timepoint (F2 reframe)
- As-of timestamp UI (G7)
- Target override per channel/cargo/warehouse (F1 + B2 + B3)
- Per-channel RAG bands (F1)
- Customer search box + N selector (OQ-06 → v1.2.0)
- Consolidate 17 → 5 query (OQ-09 → v1.3.0)
- Master data `customer_type` field (OQ-07 — N/A cho Mondelez vì NPP = Customer)
- File refactor 2,893 dòng (drift #2 → v1.2.0)
- Cut T2-T6 tables (D2 — defer hoàn toàn, user xử lý cleanup riêng phase sau)

---

## 6. Nguồn dữ liệu và SQL Queries

> **[Observed]** — `FlashDailySqlQueries` interface ở [widget-flash-daily-settings-dialog.tsx:11-30](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily-settings-dialog.tsx#L11-L30); section definitions `FLASH_DAILY_SECTIONS` ở [widget-flash-daily-settings-dialog.tsx:50-238](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily-settings-dialog.tsx#L50-L238).

Widget cấu hình bằng **17 SQL query** chia 2 nhóm:

### 6.1 Section keys hiện hành (15 keys — chart + table riêng biệt)

| Section key | Phục vụ | Cột bắt buộc (alias trong dấu ngoặc) |
|-------------|---------|--------------------------------------|
| `cardKpiStatus` | 6 KPI cards | `trang_thai_don_do (trangthaidondo, status)`, `value_uom (valueuom, volume, qty, quantity)` |
| `chartE2e` | Chart Phân bổ E2E (chia sẻ với T2) | Cùng `cardKpiStatus` |
| `chartWarehouse` | Chart Tiến độ theo kho (chia sẻ với T3) | + `whseid (warehouse)` |
| `chartDeliveryArea` | Chart Theo khu vực (chia sẻ với T5) | + `region (delivery_area)` |
| `chartCustomer` | Chart Theo NPP/Customer (chia sẻ với T4) | + `customer (customer_name, customer_code, dimension_value)` |
| `chartSalesChannel` | Chart Theo kênh bán (chia sẻ với T6) | + `group_name (sales_channel)` |
| `tblCompletion` | T1 Bảng Completion | `wh_name (wh, warehouse_name)`, `channel (sales_channel, group_name)`, `area (region, delivery_area)`, `target (muc_tieu, plan, total)`, `done (hoan_thanh, actual)` |
| `tblE2eDetail` | T2 Bảng E2E Chi tiết (riêng) | `cardKpiStatus cols` + `distinct_so (distinctso, distinct_so_count)` |
| `tblSummaryWh` | T3 Bảng TK Kho (riêng) | `whseid` + status/value |
| `tblSummaryCustomer` | T4 Bảng TK KH/NPP (riêng) | `customer_name (customer, customer_code)` + status/value |
| `tblSummaryArea` | T5 Bảng TK Vùng (riêng) | `region (delivery_area, khu_vuc_doi_xe)` + status/value |
| `tblSummaryChannel` | T6 Bảng TK Kênh (riêng) | `group_name (sales_channel)` + status/value |
| `tblDropped` | T7 Bảng Dropped Delivery (riêng) | `delivery_to_customer` |
| `tblDroppedReason` | T8 Bảng Dropped Reason (riêng) | `remark_2 (remark2, reason)` |
| `tableDetail` | T9 Bảng Flash Detail (riêng) | `so (order_id)` + status/value |

### 6.2 Legacy keys (3 keys — fallback chia sẻ — `@deprecated`)

| Key | Phục vụ | Vai trò |
|-----|---------|--------|
| `cards` | Cards KPI | Fallback nếu `cardKpiStatus` rỗng |
| `charts` | 5 chart | Fallback chia sẻ cho mọi chart key nếu chart-specific rỗng |
| `table` | 9 bảng | Fallback chia sẻ cho `tableDetail`, `tblDropped`, `tblDroppedReason` |

**Logic resolve**: Hàm `resolveSectionKey(...candidates)` ở [widget-flash-daily.tsx:1143-1150](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1143-L1150) chọn query key đầu tiên có nội dung non-empty. Khi `config.sql` (single SQL legacy) tồn tại → fan-out vào TẤT CẢ 10 key chính qua `resolveFlashQueries()` ở [widget-flash-daily.tsx:804-824](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L804-L824).

### 6.3 SQL Placeholders

> **[Observed]** — `buildFilterOverrides()` ở [widget-flash-daily.tsx:1118-1141](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1118-L1141).

Filter values được truyền lên backend dưới dạng `filterOverrides: Record<string, string>` — backend (`dashboardV2Api.executeWidget`) chịu trách nhiệm bind vào SQL template. Frontend gửi 11 cặp key-value:

| Placeholder key | Source filter | Giá trị empty string khi |
|-----------------|---------------|--------------------------|
| `uom` | `applied.uom` | (không bao giờ rỗng — default `cse`) |
| `date_type` / `dateType` | `applied.dateType` | dateType = "ALL" hoặc rỗng |
| `from_date` | `applied.fromDate + " 00:00:00"` | — |
| `to_date` | `applied.toDate + " 23:59:59"` | — |
| `group_name` | `applied.groupName` | groupName = "ALL" |
| `whseid` | `applied.whseid` | whseid = "ALL" |
| `brand` | `applied.brand` | brand = "ALL" |
| `group_of_cargo` / `groupOfCargo` | `applied.groupOfCargo` | groupOfCargo = "ALL" |
| `region` | `applied.region` | region = "ALL" |

Multi-select values là CSV (vd `"BKD1,BKD2,NKD"`), KHÔNG có quote — backend chịu trách nhiệm escape/quote khi bind vào SQL.

### 6.4 Cards CBM phụ trợ

Một query bổ sung `sql-cards-cbm` chạy CÙNG `cardKpiStatus` SQL nhưng force `uom = 'cbm'` để hiển thị "Số kế hoạch (CBM)" làm subtitle ở các chart — bất kể UOM người dùng đang chọn. **[Observed]** — [widget-flash-daily.tsx:1203-1219](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1203-L1219).

### 6.5 Fallback (không có mock data)

Khi widget chưa cấu hình `dataSourceId` HOẶC không có query nào non-empty → `hasSqlConfig = false`. **KHÔNG render mock data** như OTIF — chỉ render placeholder rỗng / loading skeleton. Bảng "T1 Completion" có cơ chế tự tổng hợp synthetic từ 3 summary queries (warehouse/channel/area) nếu `tblCompletion` rỗng — xem `completionRows` ở [widget-flash-daily.tsx:1809-1919](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1809-L1919).

> **v1.1.0**: T1 synthetic fallback **PHẢI removed** trước khi rollout — replace bằng `return [] as CompletionRateRow[]` + EmptyState ở consumer line 2878 + xoá constants `COMPLETION_WH_NAMES`/`COMPLETION_CHANNELS`/`COMPLETION_AREAS` ([widget-flash-daily.tsx:166-175](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L166-L175)). Tham chiếu spec §20 Drift #7 + audit A2 finding (oq-resolution.md §0c).

### 6.6 Section mới v1.1.0 — L4 Drop Trend chart (`chartDropTrend`)

> Section CHƯA TỒN TẠI trong code hiện hành — cần build mới. SQL draft đầy đủ ở spec §6.x. Audit A3 (oq-resolution.md §0c finding 2) đã xác nhận BUILDABLE NOW.

**Business definition**:

| Khái niệm | Định nghĩa |
|-----------|-----------|
| `drop_rate` | `# đơn FAIL / Tổng kế hoạch` (per day) — definition hẹp, KHÔNG bao gồm in-progress |
| `# đơn FAIL` | Count đơn có `status = 'Cancel'` trên `analytics_workspace.mv_dropped_report` (H1 chốt) |
| `Tổng kế hoạch` | Sum volume từ `mv_flash_report` (active) + `mv_dropped_report` (failed) — canonical per `sql-registry.md` "Flash Report" |
| Window | **14 ngày fixed** (G1 — KHÔNG dropdown chọn N) |
| Reference lines | Target ≤5% (solid red) + rolling 30-day avg (dashed) — G4 chốt cả 2 |

**FAIL classification (H1 chốt)**: chỉ `status = 'Cancel'` — KHÔNG bao gồm `Close` (tooltip T7 "Xử lý ko thành công" có thể bao gồm Close nhưng L4 chart **không**). Canonical theo `projects/mondelez/02-data/data-sources/sql-registry.md` "Flash Report" section.

**Date type guard (H2 chốt)**: `mv_dropped_report` chỉ expose 3/5 date_type options — frontend **phải disable** ETD gửi thầu + ETA gửi thầu trên UX của L4 chart. Chỉ allow: `GI date`, `Actual Ship Date`, `ATA đơn`. Nếu user chọn ETD/ETA ở filter bar overall → L4 chart hiển thị empty state hoặc fallback về GI.

**Section key & integration**:
- Frontend: thêm key `chartDropTrend` vào interface `FlashDailySqlQueries` ở [widget-flash-daily-settings-dialog.tsx:11-37](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily-settings-dialog.tsx#L11-L37) + section definition vào `FLASH_DAILY_SECTIONS`
- Backend: SQL config-driven (qua dynamic query), KHÔNG hardcode
- Filter parity: dùng cùng filter bar với L1-L3 (G5 chốt) → 11 placeholder hiện hành áp dụng trực tiếp

**SQL CTE backfill**: query template phải backfill **44 ngày** trong CTE (`flash_base` + `drop_base`) để 14 visible rows có đủ 30 priors cho rolling 30d avg. Xem spec §6.x cho draft SQL đầy đủ.

---

## 7. Luồng dữ liệu

> **[Observed]** — 17 `useQuery` ở [widget-flash-daily.tsx:1185-1470](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1185-L1470).

```
User thay đổi filter (autoApply)
  → handleSqlFilterApply tính applied: FlashStatusFilter
  → buildFilterOverrides → filterOverrides object
  → 17 useQuery invalidate (mỗi query có key riêng + applied)
  → Gọi song song:
      • sql-cards (cardKpiStatus, UOM hiện hành)
      • sql-cards-cbm (cardKpiStatus, force uom='cbm')
      • sql-charts (legacy fallback)
      • 5 chart queries: chartE2e, chartWarehouse, chartDeliveryArea, chartCustomer, chartSalesChannel
      • 2 table fallback queries: sql-table, sql-table-detail
      • 8 detail-tab queries: tblCompletion, tblE2eDetail, tblSummaryWh, tblSummaryCustomer,
                              tblSummaryArea, tblSummaryChannel, tblDropped, tblDroppedReason
  → Normalize từng response qua build*RowsFromSql() functions
  → useMemo derive: statusValues, e2eDoRows, warehouseProgressRows, customer/area/channel rows, completion, dropped
  → Render KPI cards + 5 chart + 9 bảng (theo tab active)
```

**Tổng số request song song khi widget load**: tối đa 17 (nhiều hơn OTIF 9).

**Cache**: `staleTime = 5 phút`, `placeholderData = prev` (giữ data cũ khi refetch).

**Page size**: 5000 dòng per request (lớn hơn OTIF 500/2000) — vì Flash Daily cần raw rows để client-side aggregate khi query chia sẻ.

**Pre-aggregation detection**: `buildE2ERowsFromSql` và `buildSummaryRowsFromSql` tự detect mode dựa trên column shape:
- E2E: có `distinct_so` → trust as-is; không có → group raw rows.
- Summary: có `total_volume`/`done_volume` → trust as-is; không có → group + compute từ status.

---

## 8. Cấu hình Widget (Settings Dialog)

> **[Observed]** — `WidgetFlashDailySettingsDialog` ở [widget-flash-daily-settings-dialog.tsx:250-291](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily-settings-dialog.tsx#L250-L291).

User có quyền `editMode` thấy 2 nút toolbar:

1. **Setting Chart** (variant outline) — mở `SqlSettingsDialog` với 15 section tabs (theo `FLASH_DAILY_SECTIONS`):
   - 1 Cards: `cardKpiStatus`
   - 5 Charts: `chartE2e`, `chartWarehouse`, `chartDeliveryArea`, `chartCustomer`, `chartSalesChannel`
   - 9 Tables: `tblCompletion`, `tblE2eDetail`, `tblSummaryWh`, `tblSummaryCustomer`, `tblSummaryArea`, `tblSummaryChannel`, `tblDropped`, `tblDroppedReason`, `tableDetail`

   Mỗi tab có Monaco editor + nút Test Query + `requiredColumns` validator.

2. **Setting Filter** (variant ghost amber) — mở `SqlFilterPanel` settings để override filter SQL.

Config lưu dưới dạng JSON string trong `widget.config` qua `useUpdateV2Widget`.

---

## 9. Acceptance Criteria

> **Lưu ý**: AC dưới đây là **Observed-only** — mô tả hành vi hiện hành. Khi storytelling refresh chốt scope → bổ sung AC mới ở phiên bản tiếp theo.

### AC-01: 6 KPI cards hiển thị đúng

**Given** widget cấu hình `cardKpiStatus` (hoặc legacy `cards`)  
**When** user load page hoặc đổi filter  
**Then** 6 thẻ KPI hiển thị: Tổng Volume Kế hoạch + 5 trạng thái — mỗi thẻ có giá trị format đúng UOM, icon, top-border accent, và tooltip hint từ `FLASH_DAILY_HINTS`

### AC-02: Đổi UOM cập nhật toàn widget

**Given** user thay đổi filter `UOM` (cse → ton → cbm → pallet → do)  
**When** filter apply (autoApply)  
**Then**:
- 6 KPI cards refetch với UOM mới
- 5 chart refetch và bar values đổi
- 8 bảng summary/detail render lại với format UOM phù hợp (`do` → integer, các UOM khác → 0–2 decimals)
- Subtitle "Số kế hoạch (CBM)" của chart vẫn dùng CBM bất kể UOM người dùng chọn

### AC-03: 5 chart render đúng chiều

**Given** widget có đầy đủ 5 chart query  
**When** page load xong  
**Then**:
- Chart "Theo khu vực giao hàng" — horizontal stacked bar, Y-axis là Region
- Chart "Phân bổ E2E" — vertical bar 7 cột (Plan + Actual + 5 status)
- Chart "Tiến độ theo kho hệ thống" — vertical stacked bar, X-axis là WHSEID
- Chart "Theo NPP/Customer" — horizontal stacked bar, Y-axis là Customer/NPP, top 10 by total volume
- Chart "Theo kênh bán hàng" — horizontal stacked bar, Y-axis là Sales Channel

Mỗi chart có 7 series: Kế hoạch xuất (sky) + Thực xuất (green) + 5 status (theo `STATUS_COLORS`)

### AC-04: Customer chart filter NPP/Customer

**Given** chart "Theo NPP/Customer" đang hiển thị  
**When** user đổi dropdown `customerDimensionFilter` (Tất cả / NPP / Customer)  
**Then** rows được filter theo `inferCustomerDimensionType()` — substring match `npp` / `nha phan phoi` / `distributor` để gắn tag `npp`, còn lại là `customer`. Sau filter giữ top 10 by total volume.

### AC-05: Tab Chi tiết bảng render 9 bảng

**Given** user click tab "Chi tiết bảng"  
**When** dữ liệu các table query đã fetch  
**Then** 9 `WidgetGrid` render liên tiếp với `gridKey` từ `DSHFLADTG01` đến `DSHFLADTG09`, mỗi bảng có columns đúng spec (xem §5.3) + page size 10/20.

### AC-06: Bảng Completion fallback synthetic

**Given** widget cấu hình KHÔNG có `tblCompletion`  
**When** user mở tab Chi tiết bảng  
**Then** bảng T1 hiển thị `COMPLETION_WH_NAMES × COMPLETION_CHANNELS × COMPLETION_AREAS = 6×3×3 = 54 dòng` synthetic — total/done/pct được derive từ 3 summary queries (`tblSummaryWh` / `tblSummaryChannel` / `tblSummaryArea`).

### AC-07: Filter date range mặc định = tháng tới hôm nay

**Given** widget load lần đầu, chưa có localStorage filter  
**When** widget khởi tạo state `applied`  
**Then** `fromDate` = ngày 1 của tháng hiện tại, `toDate` = hôm nay (theo `thisMonthToTodayRange()`)

### AC-08: Filter persist localStorage

**Given** user đổi filter và reload page  
**When** widget mount  
**Then** `SqlFilterPanel` restore filter từ key `dashboard-widget-filter:{dashboardId}:{widgetId}`. Trước khi restore xong → KHÔNG gọi API (guard `filterInitialized`).

### AC-09: Edit mode toolbar 2 nút

**Given** user có quyền edit dashboard  
**When** widget render với `editMode = true` và có `dashboardId` + `widgetId`  
**Then** Toolbar Dashboard hiển thị 2 nút:
- "Setting Chart" — mở SqlSettingsDialog 15 tab
- "Setting Filter" — mở SqlFilterPanel settings (chip amber)

### AC-10: Export chart/table

**Given** user xem chart hoặc bảng bất kỳ  
**When** user nhấn export menu  
**Then**:
- Chart: PNG (DOM-to-image) hoặc CSV với filename `flash-daily-{slug}`
- Bảng: CSV qua `onExportAllRows` với filename theo bảng

### AC-11: Brand filter phụ thuộc Cargo Group

**Given** user mở Brand filter dropdown  
**When** user đã chọn `group_of_cargo` ≠ ALL  
**Then** Brand dropdown chỉ hiện brands match cargo group đã chọn (`parentKey: 'group_of_cargo'` trong `brandFilter`).

---

## 10. Hành vi không thuộc phạm vi (Out of Scope)

- Tạo/chỉnh sửa datasource (thuộc module Data Sources)
- Gửi cảnh báo khi % hoàn thành dưới ngưỡng (thuộc module Monitors)
- Cấu hình dashboard layout (thuộc dashboard builder)
- Quản lý 9 file FormConfig `DSHFLADTG01..09.json` (file-based, deployed qua `Smartlog.Api.csproj` — không phải backend DB seed). Verify runtime smoke `GET /api/forms/{code}` × 9 ở rollout.

### Out of scope v1.1.0 (chuyển phase sau)

| Hạng mục | Chuyển sang | Lý do |
|----------|-------------|-------|
| Delta vs hôm qua / vs same time yesterday | KHÔNG làm | F2 reframe — quá nặng, không match Ops mental model |
| Snapshot infrastructure per timepoint | KHÔNG làm | F2 reframe — không cần delta thì không cần snapshot |
| As-of timestamp UI | KHÔNG làm | G7 — giữ dashboard clean |
| Per-channel RAG bands (KA / MT khác nhau) | v1.2.0 (nếu UAT feedback) | F1 — giữ 95% chung cho v1.1.0 |
| Target override per cargo/warehouse | KHÔNG làm | B2 + B3 — giữ 95% chung |
| Customer search box + N selector | v1.2.0 | OQ-06 — implementation decision |
| Master data `customer_type` field | KHÔNG làm cho Mondelez | OQ-07 — NPP = Customer, không cần distinction |
| Consolidate 17 → 5 query | v1.3.0 | OQ-09 — performance phase |
| Cut T2-T6 tables | Phase sau (user tự xử lý) | D2 — audit telemetry void, giữ nguyên 9 bảng cho v1.1.0 |
| File refactor `widget-flash-daily.tsx` (2,893 dòng) | v1.2.0 | Spec §20 Drift #2 — không phải user-facing |

---

## 11. Open Questions

> v1.1.0 status updates dưới đây dựa trên 25 quyết định PM (oq-resolution.md §0a Decisions Log) + 3 audit (A1/A2/A3) + 2 ambiguity được Ops confirm (H1/H2). Source of truth: [`analysis/flash-daily-oq-resolution.md`](analysis/flash-daily-oq-resolution.md).

| # | Câu hỏi | v1.1.0 Status | Quyết định / Hành động |
|---|---------|---------------|------------------------|
| OQ-01 | Mục đích chính của nhánh `feat-flash-daily-refresh` | ✅ **Resolved** | 3-phase: **Storytelling (v1.1.0) → UI reorg (v1.2.0) → Performance (v1.3.0)**. v1.1.0 scope = layout 6 levels L1-L6 (§5.4). |
| OQ-02 | Target % Hoàn thành Mondelez & cargo override | ✅ **Resolved** | **95% overall**, KHÔNG override theo cargo/kho. RAG: G≥95, Y 85-<95, R<85; Alert banner <80% ([[project-mondelez-flash-daily-target]]). |
| OQ-03 | UOM mặc định `cse` | ✅ **Resolved** | GIỮ `cse` default (D1 chốt). |
| OQ-04 | KPI cards "% target" + "delta vs hôm qua" | 🔄 **Reframed → Resolved** | **BỎ delta** (F2 reframe). v1.1.0 chỉ giữ value + %target. Thay delta bằng L4 Drop Trend 14 ngày. |
| OQ-05 | Cắt T2-T6 tables theo audit usage 9 bảng | 🟡 **Deferred** | Audit telemetry void cho Mondelez (A1 reversal — không có user-activity MV trên CH). User chọn **GIỮ NGUYÊN 9 bảng** cho v1.1.0, cleanup chuyển phase sau. |
| OQ-06 | Customer chart top 10 + search box | 🟡 **Deferred → v1.2.0** | Implementation decision, không block v1.1.0. |
| OQ-07 | NPP/Customer distinction qua master data | ❌ **Dropped / N/A** | Mondelez KHÔNG phân biệt NPP vs Customer ([[project-mondelez-npp-eq-customer]]) — bỏ luôn dropdown `customerDimensionFilter` ở chart Customer. Master data fix không cần cho tenant này. |
| OQ-08 | STM lag → 2 status đếm trùng? | ✅ **Resolved (PRD §3.1 sai)** | Audit A3: CH MV pre-computes 2 status mutually exclusive qua `e2e_label` check `thoi_gian_di IS NULL`. **Zero double-count risk** — chỉ operational lag. Action: thêm caveat tooltip "Chưa nhận tín hiệu ATD từ STM" ở 2 KPI status; KHÔNG block release. PRD §3.1 đã sửa ở v1.1.0. |
| OQ-09 | Consolidate 17 → 5 queries | 🟡 **Deferred → v1.3.0** | Performance phase sau khi UI reorg cắt query không cần. |
| OQ-10 | FormConfig DSHFLADTG01..09 đã seeded? | ✅ **Resolved (reversal)** | Audit A2: FormConfig là **file-based** (`FileBasedFormConfigProvider.cs` + `IMemoryCache` TTL 2h), **KHÔNG DB-seeded**. 9 JSON files đều có và valid ở `backend/src/FormConfigs/DSHFLADTG01..09.json`. Audit thực sự = runtime smoke `GET /api/forms/{code}` × 9. KHÔNG cần backend seed migration. |

### Quyết định mới phát sinh v1.1.0 (đã chốt)

| # | Câu hỏi | Status | Quyết định |
|---|---------|--------|-----------|
| H1 | FAIL classification cho L4 Drop Trend — Cancel only hay cả Close? | ✅ **Resolved** | **`status = 'Cancel'` only** — canonical per `sql-registry.md` "Flash Report" section. KHÔNG bao gồm Close (dù tooltip T7 "Xử lý ko thành công" có thể bao gồm). |
| H2 | Date type ETD/ETA gửi thầu trên L4 — fallback NULL hay disable? | ✅ **Resolved** | **Disable ETD gửi thầu + ETA gửi thầu trên L4 chart UX** (`mv_dropped_report` chỉ expose 3/5 date_type options). Chỉ allow GI/Actual Ship/ATA. |
| F1 | Target SLA per channel (KA=95%, MT=90-93%) vào dashboard? | ✅ **Resolved** | **KHÔNG** — dùng 95% chung cho v1.1.0. SLA per-channel là contractual cho BOD/Finance. Override per channel chuyển sang v1.2.0 nếu Ops feedback "MT bị đỏ oan" trong UAT. |
| G7 | As-of timestamp UI ("Dữ liệu cập nhật lần cuối: HH:mm")? | ✅ **Resolved** | **KHÔNG cần** — giữ dashboard sạch, chấp nhận data delay risk theo E5. |
| D2 | Cut T2-T6 tables hay defer? | ✅ **Resolved → Defer** | GIỮ NGUYÊN 9 bảng cho v1.1.0 (user 2026-05-16 chốt cleanup chuyển phase sau). |

---

## 12. Ghi chú kỹ thuật cho Planner

> Phần này chỉ nêu các **ràng buộc quan sát được** — quyết định implementation thuộc phạm vi `/planner`.

- Widget dùng `dashboardV2Api.executeWidget()` với `sectionKey` để backend chọn SQL phù hợp.
- Normalization xử lý 100% phía frontend qua các hàm `build*RowsFromSql()` — backend trả raw rows theo SQL.
- Có hai chế độ pre-aggregation cho E2E và Summary queries — frontend tự detect qua column shape (xem §7).
- Filter state persist localStorage với key `dashboard-widget-filter:{dashboardId}:{widgetId}`.
- `customerDimensionFilter` (NPP/Customer toggle) — state cục bộ trong component, KHÔNG persist.
- Khi `customerDimensionFilter` đổi → KHÔNG gọi lại API, chỉ filter client-side trên `customerProgressBaseRows`.
- Chart `customerProgress` luôn slice top 10 by total — nếu cần thay đổi limit, đổi tham số `topNByTotal(rows, 10)`.
- Subtitle "Số kế hoạch (CBM)" cần 1 query bổ sung `sql-cards-cbm` force `uom='cbm'` — nếu refresh cắt subtitle này thì gỡ luôn query bổ sung.

---

## 13. Lịch sử thay đổi

| Version | Ngày | Tác giả | Thay đổi |
|---------|------|---------|---------|
| 1.0.0 | 2026-05-16 | PM/DA via `/da-trace` | Bản đầu tiên — Observed baseline từ source code, KHÔNG có storytelling layer. Document tất cả 6 KPI / 5 chart / 9 bảng / 15 SQL section keys / 8 filter / 17 useQuery hiện hành. Mở 10 OQ chờ workshop refresh. |
| 1.1.0 | 2026-05-16 | PM/DA via `/da-biz-ba` | **Storytelling refresh — scope locked.** Chốt sau 3 rounds duyệt PM Smartlog (25 quyết định A1-E5 + F1-F2 + G1-G7) + 3 audit agent (A1 telemetry, A2 FormConfig, A3 CH SQL). (1) Thêm §5.4 Layout v2 6 levels (L1 Hero / L2 Exception / L3 Funnel / L4 Drop Trend / L5 Dimension / L6 Tables). (2) Thêm §6.6 spec L4 Drop Trend chart mới (section key `chartDropTrend`, FAIL = `status='Cancel'` only, 14 ngày fixed, target ≤5% + rolling 30d). (3) Sửa §3.1 double-count misconception — CH MV pre-computes `e2e_label` mutually exclusive qua `thoi_gian_di IS NULL`. (4) Update §10 Out of Scope với 10 hạng mục chuyển phase sau. (5) Update §11 OQ: OQ-01/02/03/04/08/10 resolved; OQ-05/06/09 deferred; OQ-07 dropped (N/A cho Mondelez); thêm H1/H2/F1/G7/D2 quyết định mới. (6) Sửa OQ-10 reversal — FormConfig là file-based không DB-seeded. Out-of-scope: delta, snapshot per timepoint, as-of timestamp, per-channel RAG, customer search/N selector, query consolidation, T2-T6 cut, file refactor. |
