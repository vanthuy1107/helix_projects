# PRD — VFR (Vehicle Fill Rate)

**Tenant:** Mondelez
**Section slug:** `vfr` (Mondelez 01-sections)
**Frontend source:** `frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx`
**Backend FormConfig:** `DSHVFRDTG01.json`
**ClickHouse source:** `analytics_workspace.mv_vfr_gui_thau` (tender), `analytics_workspace.mv_vfr_van_hanh` (operation)
**SQL registry sections:** `sql-registry.md §7 vfr tender`, `§8 vfr operation`
**Status:** In production (implementation done); PRD consolidated from `05-reference/[done] vfr/vfr.prd.md` and refreshed against current widget on 2026-05-19.
**Owner:** Thanh (original BA), updated by squad1
**Last updated:** 2026-05-19

---

## 1. Overview

VFR — Vehicle Fill Rate — đo mức độ tận dụng xe cho hai luồng độc lập:

- **Chuyến gửi thầu (GT)** — group theo `TenderMasterID`, dùng materialized view `mv_vfr_gui_thau`.
- **Chuyến vận hành (VH)** — group theo `MasterCode`, dùng materialized view `mv_vfr_van_hanh`.

Trên widget, người dùng chuyển giữa GT và VH qua **Mode toggle** (mỗi lần chỉ xem 1 mode). Đây là khác biệt với PRD gốc — PRD gốc đề xuất 10 scorecard hiển thị song song GT+VH, code chốt phương án toggle để giảm tải UI (xem §17 Drift log).

VFR dùng để: phát hiện xe non tải, so sánh GT vs VH, đánh giá hiệu suất nhà vận tải, tối ưu kế hoạch ghép hàng theo khu vực / loại xe / loại bốc xếp.

---

## 2. Target users

| Nhóm | Nhu cầu chính |
|---|---|
| Logistics / Transport Ops Manager | Theo dõi VFR tổng thể; phát hiện non tải; so sánh GT vs VH theo khu vực, loại xe, loại bốc xếp |
| Carrier Management | So sánh VFR theo nhà vận tải; làm cơ sở đánh giá Carrier Performance, đàm phán SLA |
| Team Lập kế hoạch vận tải | Đánh giá chất lượng kế hoạch GT; điều chỉnh ghép hàng; chọn loại xe phù hợp |
| Lãnh đạo Chuỗi cung ứng | Theo dõi KPI tổng, xu hướng theo thời gian, định hướng tối ưu chi phí logistics |

---

## 3. KPI definitions

### 3.1 Công thức cốt lõi — VFR theo chuyến

```
VFR Tấn  = Tấn chở / Tấn đăng ký
VFR Khối = Khối chở / Khối đăng ký
VFR Max  = MAX(VFR Tấn, VFR Khối)
```

Lấy **MAX** chứ không phải MIN — phản ánh yếu tố giới hạn chính của chuyến (chiều nào "đầy trước" thì chiều đó quyết định).

Implementation tại [widget-vfr.tsx:454-462](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L454-L462):
- Nếu SQL trả về `vfr_max` ≠ 0 → dùng giá trị server.
- Fallback client-side: `Math.max(actTon/regTon, actCbm/regCbm) × 100`.

### 3.2 Phân loại VFR

Yêu cầu phân loại theo "VFR Tấn" / "VFR Khối" đã được **đóng won't-fix (OQ-02, 2026-05-19)** — widget không render column này và không có UI consumer cho classification value. PRD chỉ giữ formula MAX cho per-trip VFR (§3.1), không phân biệt nguồn.

### 3.3 5 nhóm scorecard theo ngưỡng (server-side bucketing)

5 bucket count đến từ SQL section `kpi` / `kpiOperation`, tính trên cột `vfr_max` đã pre-compute trong CH MV. Boundary thực tế trên branch `feat-vfr-late-alert` (per [sql-registry.md §7-8](../../02-data/data-sources/sql-registry.md)):

| Nhóm | Field | Điều kiện CH (as-built) | Điều kiện canonical (PRD gốc) | Màu accent |
|---|---|---|---|---|
| Avg VFR | `avg_vfr` | `AVG(vfr_max)` | — | tím |
| Low <50% | `cnt_vfr_50` | `vfr_max < 50` | `< 50` ✓ | đỏ |
| Medium 50–70% | `cnt_vfr_50_70` | `vfr_max >= 50 AND vfr_max < 70` | `>= 50, < 70` ✓ | vàng |
| High 70–95% | `cnt_vfr_70_95` | `vfr_max >= 70 AND vfr_max < 95` | `>= 70, < 95` ✓ | xanh dương |
| Excellent ≥95% | `cnt_vfr_95` | `vfr_max > 95` ⚠️ | `>= 95` | xanh lá |

⚠️ **Bug ranh giới**: CH SQL ở `cnt_vfr_95` dùng strict `> 95` thay vì `>= 95` (cả tender + operation). Rows với `vfr_max = 95.0` exactly bị drop khỏi cả 2 bucket → không được đếm. Xem [BUG-VFR-08](analysis/bugs-2026-05-19.md).

**Clamp >100%**: KHÔNG có clamp ở client. Trip có `vfr_max = 142` được render raw 142% trong Detail grid và được đếm vào nhóm `cnt_vfr_95`. Đây là behavior hiện tại; PRD gốc đề xuất clamp 100% nhưng chưa implement — xem [BUG-VFR-01](analysis/bugs-2026-05-19.md).

### 3.4 VFR theo loại bốc xếp (TOBE V3 spec)

Authoritative spec: [`05-reference/[Version 3.0] TOBE - GIẢI PHÁP CONTROL TOWER.pdf`](../../05-reference/[Version 3.0]%20TOBE%20-%20GI%E1%BA%A2I%20PH%C3%81P%20CONTROL%20TOWER.pdf) slide 49-50.

**Per-trip `vfr_max`** (Bước 1-2): `MAX(VFR Tấn, VFR Khối)` simple per row trong MV — **khớp** code thực tế.

**Aggregate VFR** (Bước 3-5) theo công thức Loose+FP weighted:

```
Bước 3 (per loại bốc xếp LT):
  VFR Tấn (c)  = Σ Tấn chở (trip phân loại Tấn của LT) / Σ Tấn đăng ký (idem)
  VFR Khối (d) = Σ Khối chở (trip phân loại Khối của LT) / Σ Khối đăng ký (idem)

Bước 4 (VFR loại bốc xếp = aggregate weighted):
  VFR (LT) = (c) × (Σ Khối chở Tấn / Σ Khối đk Tấn)
           + (d) × (Σ Khối chở Khối / Σ Khối đk Khối)

Bước 5 (VFR Tổng):
  VFR Tổng = Σ [VFR (LT_n) × (Σ Khối chở LT_n / Σ Khối đk LT_n)]
```

Widget tooltip `VFR_FORMULA` tại [widget-vfr.tsx:201](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L201) là expansion của Bước 4-5 cho Mondelez với 2 loại bốc xếp (Loose + Full Pallet).

> **⚠️ DRIFT confirmed (BUG-VFR-09)**: SQL hiện tại trong [sql-registry.md §3590](../../02-data/data-sources/sql-registry.md#L3590) chỉ làm `AVG(vfr_max)` simple — KHÔNG implement V3 Bước 4-5 weighted. Aggregate KPI/chart bị sai số theo spec Mondelez TOBE 3.0. Cần data team rewrite SQL — xem [analysis/bugs-2026-05-19.md BUG-VFR-09](analysis/bugs-2026-05-19.md). V3 line 995 reference file mẫu data Mondelez làm authoritative source.

### 3.5 Formula source-of-truth — mapping per UI element

| UI element | Field | Nguồn formula | Tính ở đâu |
|---|---|---|---|
| KPI card `Avg VFR` | `avg_vfr` | §3.4 Loose+FP weighted | CH MV (`vfr_max` per row) → `AVG(vfr_max)` trong SQL `kpi` section |
| KPI card `Low / Medium / High / Excellent` count | `cnt_vfr_*` | §3.3 bucket theo `vfr_max` | SQL `kpi` section trên `mv_vfr_gui_thau`/`mv_vfr_van_hanh` |
| Chart `VFR theo Khu vực` | `vfr` (per area row) | Aggregate `vfr_max` theo `khu_vuc_doi_xe` | SQL `byArea` / `byAreaOperation` |
| Chart `VFR theo Loại xe` | `vfr` (per vehicle row) | Aggregate `vfr_max` theo loại xe | SQL `byVehicle` / `byVehicleOperation` |
| Chart `VFR theo Loại bốc xếp` | `<lt>__vfr` (per period × LT) | Weighted by `planned` trong [widget-vfr.tsx:1034](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L1034) `byLoadingTypeTenderTrend` useMemo | SQL `byLoadingType*` cung cấp raw rows; widget weighted-aggregate |
| Time × Area table | `vfr` (per period × area) | Aggregate `vfr_max` theo period + area | SQL `byTimeArea` / `byTimeAreaOperation` |
| Detail grid `vfr` column | per-trip `vfr` | `vfrMax > 0 ? vfrMax : Math.max(actTon/regTon, actCbm/regCbm) × 100` | [widget-vfr.tsx:454-462](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L454-L462) — server-first, client fallback khi MV thiếu `vfr_max` |

Per-trip `MAX(VFR Tấn, VFR Khối)` công thức ở §3.1 CHỈ áp dụng cho client fallback ở Detail grid. KPI/chart/table đều dùng pre-computed `vfr_max` từ MV.

### 3.6 Target VFR — Mondelez

Chốt 2026-05-20 với PM (squad1@gosmartlog.com — PM/DA team):

| Field | Giá trị | Rationale |
|---|---|---|
| Target overall | **85%** | Áp dụng cho cả 2 mode GT + VH; có thể điều chỉnh sau khi thu thập feedback rollout v1.0 |
| RAG bands | 🟢 ≥ 85% / 🟡 75 – <85% / 🔴 < 75% | Buffer 10pt vì VFR variance theo lane/loại xe/mùa vụ cao hơn metric kết quả |
| Source-of-truth (code) | Constant `DEFAULT_VFR_TARGETS.overall = 85` tại top of [widget-vfr.tsx](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx) | Single literal; future v1.x có thể migrate sang tenant config khi backend admin UI ready |
| Per-loading-type target (Loose vs FP) | Defer v1.x | Single 85% chung cho v1.0 storytelling refresh |

Parallel tenant precedents: OTIF Mondelez = 90% (memory `project_mondelez_otif_target`), Flash Daily = 95% (memory `project_mondelez_flash_daily_target`). VFR target thấp hơn 2 metric kia vì đo "non tải" (process metric, không phải outcome metric).

---

## 4. Functional requirements (as built)

### 4.1 KPI cards (5 thẻ)

Mỗi mode (GT hoặc VH) hiển thị 5 KPI cards: **Avg VFR / Low / Medium / High / Excellent**. Mỗi card có tooltip công thức (hover icon `?`).

### 4.2 Charts (3 charts/mode, tab `Chart`)

| # | Chart | Loại | Bind SQL section |
|---|---|---|---|
| 1 | VFR theo Khu vực | ComposedChart (Bar `planned` + Line `vfr`) | `byArea` / `byAreaOperation` |
| 2 | VFR theo Loại xe | ComposedChart | `byVehicle` / `byVehicleOperation` |
| 3 | VFR theo Loại bốc xếp & Thời gian | ComposedChart, multi-series, group-by `day/week/month` toggle | `byLoadingType` / `byLoadingTypeOperation` |

Drift vs PRD gốc: PRD §9.3 đề xuất 8 charts (4 cho GT, 4 cho VH song song). Code chốt 3 charts × 2 modes = 6 series qua toggle (xem §17 Drift D1).

### 4.3 Time × Area summary table (tab `Detail`)

Table dạng matrix: hàng = period (tự suy ra từ data), cột = khu vực giao, value = VFR %. Có hàng/cột trung bình. Bind:

| Mode | Section |
|---|---|
| Tender | `byTimeArea` |
| Operation | `byTimeAreaOperation` |

### 4.4 Detail grid (tab `Detail`)

Dùng `WidgetGrid` (gridKey `DSHVFRDTG01`) với 30 cột. Xem §6 cho danh sách cột đầy đủ.

Pagination: server-side qua `dashboardV2Api.executeWidget({ countOnly, page, pageSize })`. Page sizes: 10 / 20 / 50.

Export: nút "Export all rows" gọi `fetchAllRows()` — page qua tối đa 50 page × 5000 rows.

### 4.5 Filters

Filter panel (`SqlFilterPanel`) cho 5 fields + 2 fields phụ thuộc mode:

| Key | Label | Loại | Mặc định |
|---|---|---|---|
| `pickup_warehouse` | Pickup Warehouse | multi-select | ALL |
| `delivery_area` | Khu vực giao hàng | multi-select | ALL |
| `vendor` | Vendor / Carrier | multi-select | ALL |
| `date_type` | Date Type | single-select (ETA / ATA) | ETA |
| `vfrDateRange` | Khoảng thời gian | date range | đầu tháng → hôm nay |
| `vehicle_type_tender` | Loại xe gửi thầu | multi-select; **disabled khi mode = operation** | ALL |
| `vehicle_type_ops` | Loại xe vận hành | multi-select; **disabled khi mode = tender** | ALL |

CSV expansion: `applied.<field>.includes('ALL')` → gửi chuỗi rỗng cho filter override (=> SQL không filter trường này). Ngược lại gửi CSV `value1,value2,...`.

### 4.6 Settings dialogs

| Dialog | File | Mục đích |
|---|---|---|
| **Setting Chart** (`WidgetVfrSettingsDialog`) | [widget-vfr-settings-dialog.tsx](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr-settings-dialog.tsx) | Admin paste SQL cho 14 sections (4 tender + 4 operation + 2 detail + 2 time-area + 2 vehicle-type-options) |
| **Setting Filter** | `SqlFilterPanel` settings mode | Admin override SQL cho từng filter (vẫn dùng fallback options nếu SQL chưa set) |

---

## 5. Filters (chi tiết)

### 5.1 Mặc định client-side fallback (khi SQL options không có)

```
PICKUP_WAREHOUSES = ['Kho trong - NKD', 'Kho trong - BKD', 'Kho ngoài - NKD', 'Kho ngoài - BKD', 'KHO THĂNG LONG']
DELIVERY_AREAS    = ['South East', 'South East - Lam Dong', 'Ha Noi', 'Central highland', 'Mekong 1', 'Ho Chi Minh', 'North East - North West', 'North Central Coast', 'South Central Coast', 'Mekong 2']
VENDORS           = ['NGUYEN PHAT', 'HDA', 'NINJAVAN', 'NGUYEN PHAT, ANH SON', 'ANH SON', 'THANH AN', 'GHN', 'TLL']
```

### 5.2 Date type

Combo box: `ETA` (default) / `ATA`. Khi đổi → cả widget re-fetch với filter override `date_type`.

### 5.3 Date range

Date range picker. TOBE V3 slide 51 line 1029 specify **"Chọn tối đa 12 tháng"** — user chỉ filter dữ liệu quá khứ tối đa 12 tháng tính từ today (`from_date ≥ today - 365d`).

Trạng thái:
- Default = startOfMonth(today) → today
- Cap = 12 tháng historical (theo V3)
- **Hiện tại code KHÔNG enforce** — xem [BUG-VFR-05](analysis/bugs-2026-05-19.md) (reopened 2026-05-20)

---

## 6. Data requirements — detail grid

Cột render trong detail grid (key trong `VfrDetailRow`, label qua i18n):

| Key | Label (vi) | Source field (CH) | Type |
|---|---|---|---|
| `tripId` | Trip | `trip_id` / `ID chuyến gửi thầu` | string |
| `maChuyenVanHanh` | Mã chuyến vận hành | `ma_chuyen_van_hanh` | string |
| `maDonHang` | Mã đơn hàng | `ma_don_hang` | string |
| `dichVuVanChuyen` | Dịch vụ vận chuyển | `dich_vu_van_chuyen` | string |
| `trangThaiChuyen` | Trạng thái chuyến | `trang_thai_chuyen` | string |
| `tenderDate` | Thời gian gửi thầu | `tender_date` | string |
| `plannedDate` | ETA vận hành | `eta_vh` | string |
| `actualDate` | ATA vận hành | `ata_vh` | string |
| `soXe` | Số xe | `so_xe` | string |
| `taiXe` | Tài xế | `tai_xe` | string |
| `vendor` | Vendor | `nha_van_tai` | string |
| `nhomHangHoa` | Nhóm hàng | `nhom_hang_hoa` | string |
| `pickupWarehouse` | Mã điểm nhận | `pickup_warehouse` / `ma_diem_nhan` | string |
| `maDiemNhan` | Tên điểm nhận | `diem_nhan` | string |
| `maDiemGiao` | Mã điểm giao | `ma_diem_giao` | string |
| `deliveryPoint` | Tên điểm giao | `delivery_point` / `diem_giao` | string |
| `deliveryArea` | Khu vực | `delivery_area` / `khu_vuc_doi_xe` | string |
| `loadingTypeTender` | Loại bốc xếp | `loading_type_tender` / `loai_boc_xep` | string |
| `vehicleTypeTender` | Loại thầu | `vehicle_type_tender` / `loai_xe_gui_thau` | string |
| `vehicleTypeOps` | Loại vận hành | `vehicle_type_ops` / `loai_xe_van_hanh` | string |
| `regTon` | Tấn đăng ký | `reg_ton` | number |
| `regCbm` | CBM đăng ký | `reg_cbm` | number (rounded int) |
| `tanKeHoach` | Tấn kế hoạch | `tan_ke_hoach` | number |
| `actTon` | Tấn thực tế | `act_ton` | number |
| `tanGiao` | Tấn giao | `tan_giao` | number |
| `cbmKeHoach` | CBM kế hoạch | `cbm_ke_hoach` | number (rounded int) |
| `actCbm` | CBM thực tế | `act_cbm` | number |
| `cbmGiao` | CBM giao | `cbm_giao` | number |
| `vfr` | VFR% | computed | percent |

Tổng 29 cột hiển thị. Mọi cột đều `sortable: true`, các cột business có `filterType: 'text' | 'multiselect'`.

---

## 7. Business rules / edge cases (as-built)

Cột "Behavior" = hành vi thực tế của code hiện tại (branch `feat-vfr-late-alert`). Mọi gap so với PRD gốc đã được lock vào bug log — xem cột "Abnormality?".

| # | Tình huống | Behavior (as-built) | Abnormality? |
|---|---|---|---|
| 1 | `Tấn đăng ký = 0/null` | Per-trip client fallback: nếu `regTon ≤ 0` → `vfrWeight = 0`; nếu `regCbm ≤ 0` → `vfrVolume = 0`. Lọc record là trách nhiệm SQL upstream ([widget-vfr.tsx:459-460](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L459-L460)) | — (theo design) |
| 2 | `regTon > 0` nhưng `actTon = 0` AND `actCbm = 0` (zero-delivery anomaly) | Render giá trị 0 + AlertTriangle icon + Tooltip cảnh báo trong column `actTon` | ✅ Fixed (BUG-VFR-02, 2026-05-19) |
| 3 | VFR > 100% | Render giá trị raw (vd 142%) + AlertTriangle icon + Tooltip trong column `vfr`; đếm vào `cnt_vfr_95` theo giá trị raw | ✅ Fixed (BUG-VFR-01, 2026-05-19) |
| 4 | VFR Tấn = VFR Khối | Không tiebreak — `Math.max` không xác định nguồn. KHÔNG có UI consumer → close-by-design | ✅ Closed won't-fix (OQ-02, BUG-VFR-03) |
| 5 | Thiếu `TenderGroupOfVehicleName` (GT) | Loại khỏi VFR GT (SQL filter upstream) | — |
| 6 | Thiếu `GroupOfVehicleName` (VH) | Loại khỏi VFR VH (SQL filter upstream) | — |
| 7 | `LocationFromCode ≠ TextFromCode` (GT) | Loại khỏi VFR GT (SQL filter upstream) | — |
| 8 | `ServiceOfOrderName ≠ "Xuất bán"` | Loại khỏi dashboard (SQL filter upstream) | — |
| 9 | `UnloadingTypeID = null` / `loading_type` rỗng | Gom thành group `'Không xác định'` trong chart `byLoadingType` ([widget-vfr.tsx:1071-1072](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx#L1071-L1072)) | ✅ Fixed (BUG-VFR-04, 2026-05-19) |
| 10 | Date range > 12 tháng historical | `from_date` bị clamp về `today - 365d` + toast warning khi user pick sớm hơn (V3 spec) | ✅ Fixed (BUG-VFR-05, 2026-05-20) |
| 11 | `vfr_max = 95.0` exactly | Đếm vào `cnt_vfr_95` đúng — `cnt_vfr_95` dùng `>= 95` sau fix BUG-VFR-08 | ✅ Fixed (BUG-VFR-08, registry; rollout pending) |
| 12 | `executeWidget` trả `error` | Banner đỏ trên đầu widget + retry button gọi `refetch()` | ✅ Fixed (BUG-VFR-07, 2026-05-19) |
| 13 | i18n `VFR_OPERATION_HINTS.{low,medium,high,excellent}` | Đã đổi "gửi thầu" → "vận hành"; label `high` đổi `Medium 70-95%` → `High 70-95%`; tender + operation boundary `>= 95%` | ✅ Fixed (BUG-VFR-06, 2026-05-19) |

---

## 8. SQL contract — section keys

Widget gọi `dashboardV2Api.executeWidget(dashboardId, widgetId, { sectionKey, filterOverrides })` cho mỗi section. Admin phải paste 14 SQL queries:

| Section key | Mục đích | Cột bắt buộc |
|---|---|---|
| `kpi` | KPI tender | `avg_vfr`, `low_under_50`, `medium_50_70`, `high_70_95`, `excellent_95_up` |
| `byArea` | Chart area tender | `area`, `planned` (or `registered_cbm`), `vfr` |
| `byVehicle` | Chart vehicle tender | `vehicle`, `registered_cbm` (or `planned`), `vfr` |
| `byLoadingType` | Chart loading-type tender | `period`, `loading_type`, `planned`, `vfr` |
| `kpiOperation` | KPI operation | (như `kpi`) |
| `byAreaOperation` | Chart area operation | (như `byArea`) |
| `byVehicleOperation` | Chart vehicle operation | (như `byVehicle`) |
| `byLoadingTypeOperation` | Chart loading-type operation | (như `byLoadingType`) |
| `detail` | Detail grid tender | `trip_id`, `pickup_warehouse`, `delivery_area`, `vendor`, `reg_cbm`, `act_cbm`, `reg_ton`, `act_ton` (+ optional fields) |
| `detailOperation` | Detail grid operation | (như `detail`) |
| `byTimeArea` | Time × Area table tender | `period`, `area`, `vfr` |
| `byTimeAreaOperation` | Time × Area table operation | (như `byTimeArea`) |
| `vehicleTypeTenderOptions` | Option list filter loại xe thầu | `value` (và optional `label`) |
| `vehicleTypeOpsOptions` | Option list filter loại xe VH | `value` (và optional `label`) |

**Filter substitution**: tất cả 14 SQL nhận `filterOverrides` map qua `{{placeholder}}` syntax. Phổ biến: `{{whseid}}`, `{{area}}`, `{{transporter}}`, `{{date_type}}`, `{{from_date}}`, `{{to_date}}`, `{{vehicle_type_tender}}`, `{{vehicle_type_ops}}`.

Khi user chọn "All": override = chuỗi rỗng → SQL phải dùng pattern `coalesce({{x}}, 'ALL')` HOẶC CTE param với fallback. Tham khảo `sql-registry.md §7-8` cho canonical pattern.

> Anti-pattern: hardcode `'ALL'` vào CTE param mà không trace qua WidgetFilterResolver — sẽ làm filter mất hiệu lực. Xem memory `feedback_sql_review_widget_runtime`.

---

## 9. ClickHouse source views

| MV | Refresh | Rows (snapshot) | Mục đích |
|---|---|---|---|
| `analytics_workspace.mv_vfr_gui_thau` | 5 min | ~590k historical / ~72k window | Tender — group theo `TenderMasterID` |
| `analytics_workspace.mv_vfr_van_hanh` | 1 hour | ~72k total | Operation — group theo `MasterCode` |

---

## 10. Access & permissions

Hiện tại không có row-level security trong widget. Toàn bộ user có quyền vào dashboard này đều xem toàn bộ data.

---

## 11. In scope (đã build)

- ✅ Tính VFR GT/VH theo trọng tải + thể tích, lấy MAX.
- ✅ Phân nhóm 5 ngưỡng <50 / 50-70 / 70-95 / ≥95 + Avg.
- ✅ Phân tích theo khu vực, loại xe, loại bốc xếp.
- ✅ Phân tích theo thời gian × khu vực (table matrix).
- ✅ Detail grid 29 cột với pagination + export.
- ✅ Filter 7 dimensions với conditional disable theo mode.
- ✅ Mode toggle GT ↔ VH.

## 12. Out of scope (NOT in this widget)

- ❌ Tỷ lệ tuân thủ quy trình (separate widget).
- ❌ Tỷ lệ đáp ứng chuyến gửi thầu (separate widget = `tender-response`).
- ❌ Phân tích chi phí vận chuyển per-vehicle.
- ❌ Tracking nhiên liệu / bảo trì / hiệu suất kỹ thuật xe.
- ❌ Auto-recommendation ghép hàng / đổi loại xe.
- ❌ Penalty / bonus auto-calc cho nhà vận tải.
- ❌ Forecasting demand vận tải.

## 13. Late alert (branch context — `feat-vfr-late-alert`)

**Decision (PM, 2026-05-19, OQ-05 closed):** Late-alert đã có ở widget độc lập [widget-late-order-alert.tsx](frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx) (1487 dòng). KHÔNG cần thêm late-alert correlation vào widget VFR. Branch `feat-vfr-late-alert` chỉ là umbrella chia sẻ filter context giữa 2 widget khi cùng dashboard — accept naming misnomer.

VFR widget không có business requirement về late-alert. Refresh PRD/storytelling v2 cho VFR tiếp tục độc lập với late-order-alert track.

---

## 14. MVP recommendation (đã đạt)

20-component MVP từ PRD gốc đã thu gọn còn 10-component cho 1 mode tại 1 thời điểm + toggle. Đánh đổi: giảm clutter UI, mất khả năng so sánh GT/VH song song trên cùng màn hình.

---

## 15. Open questions

Mọi gap về hành vi code đã được lock thành bug ở [analysis/bugs-2026-05-19.md](analysis/bugs-2026-05-19.md). Các câu hỏi dưới đây là *decision* cần stakeholder chốt (không phải bug).

| ID | Question | Owner | Block? | Liên kết |
|---|---|---|---|---|
| OQ-01 | ✅ **Closed 2026-05-19** — Decision (PM): render raw + warning icon khi VFR > 100%. BUG-VFR-01 → **Fixed**. | BA + Data | — | BUG-VFR-01 |
| OQ-02 | ✅ **Closed 2026-05-19** — Decision (BA): bỏ yêu cầu tiebreak Khối (không có UI consumer). BUG-VFR-03 → **won't-fix**. | BA | — | BUG-VFR-03 |
| OQ-03 | ✅ **Resolved 2026-05-20** — V3 specify cap 12m historical; user clarify; **Fixed FE** clamp `from_date ≥ today-365d`. BUG-VFR-05 closed. | BA + UX | — | BUG-VFR-05 |
| OQ-04 | ✅ **Partially resolved 2026-05-20** — TOBE V3 slide 49-50 + line 995 file mẫu confirm formula. Per-trip = MAX simple (Bước 1-2). Aggregate = Loose+FP weighted (Bước 4-5). Mondelez-specific scope. New drift discovered → [BUG-VFR-09](analysis/bugs-2026-05-19.md) Major. | Data | High | §3.4, BUG-VFR-09 |
| OQ-05 | ✅ **Closed 2026-05-19** — Decision (PM): late-alert đã có ở widget khác, không cần thêm vào VFR. Branch misnomer accepted. | PM | — | §13 |
| OQ-06 | ✅ **Closed 2026-05-20** — Decision (PM): Target VFR Mondelez = **85% overall**, RAG bands 75/85 (10pt buffer). Có thể điều chỉnh sau rollout v1.0. Unblock storytelling v2 Phase 1. | PM/SC Manager | — | §3.6, §18 |

---

## 16. References

- PRD gốc (immutable): [05-reference/[done] vfr/vfr.prd.md](../../05-reference/%5Bdone%5D%20vfr/vfr.prd.md)
- Spec gốc (outdated paths, kept for history): [05-reference/[done] vfr/vfr.spec.md](../../05-reference/%5Bdone%5D%20vfr/vfr.spec.md)
- SQL registry: [02-data/data-sources/sql-registry.md §7-8](../../02-data/data-sources/sql-registry.md)
- Trace report (drift log): [projects/trace/vfr-2026-05-19.md](../../../trace/vfr-2026-05-19.md)

---

## 17. Drift log — PRD GỐC (`05-reference/[done] vfr/vfr.prd.md`) vs as-built

**Posture (2026-05-19 trở đi)**: PRD này (§1-§16) đã được align về code thực tế. Drift log dưới đây chỉ giữ lại lịch sử so sánh **PRD-gốc** vs **code hiện tại** để khi BA/PM tham chiếu lại documentation cũ vẫn hiểu vì sao chốt thế. Hành vi as-built đã được mô tả tại §3, §4, §7; các bug đã được lock tại [analysis/bugs-2026-05-19.md](analysis/bugs-2026-05-19.md).

Severity: 🟢 cosmetic / 🟡 documentation / 🔴 functional.

| # | Area | PRD gốc nói | Code as-built làm | Severity | Trạng thái |
|---|---|---|---|---|---|
| D1 | Layout | 10 scorecards + 8 charts hiển thị song song GT+VH (gốc §9.2-9.3) | 5 scorecards + 3 charts per mode, switched via toggle | 🟡 | ✓ Aligned trong §1, §4.1. Confirm PM toggle pattern là final |
| D2 | Tiebreak | VFR Tấn = VFR Khối → ưu tiên Khối (gốc §5.5, §13.4) | `Math.max` không tiebreak | 🟢 | ✅ Closed 2026-05-19 (OQ-02): won't-fix, không UI consumer; BUG-VFR-03 closed |
| D3 | Formula aggregate VFR | TOBE V3 Bước 4-5: Loose+FP weighted; PRD gốc §5.10 same | SQL `AVG(vfr_max)` simple, không weighted | 🔴 | ✅ V3 confirmed spec 2026-05-20; locked: **BUG-VFR-09 Major** — data team rewrite SQL pending |
| D4 | Clamp >100% | Render 100%, gom ≥95% (gốc §13.3) | Render raw + warning icon (hybrid) | 🟡 | ✅ Fixed 2026-05-19 (BUG-VFR-01) |
| D5 | 12-month historical cap | TOBE V3 slide 51 + gốc §13.10: cap 12 tháng từ today | `from_date` clamp + toast warning | 🔴 | ✅ Fixed 2026-05-20 (BUG-VFR-05) |
| D6 | Late alert | — | Branch tên có "late-alert" nhưng widget không có path này | 🔴 | ✅ Closed 2026-05-19 (OQ-05) |
| D7 | "Không xác định loại bốc xếp" | Vẫn tính VFR, gom nhóm này (gốc §13.9) | Gom thành group `'Không xác định'` | 🟡 | ✅ Fixed 2026-05-19 (BUG-VFR-04) |
| D8 | i18n vận hành text | Hint cho mode operation nói đúng "vận hành" | Đã align operation hints; label `high` đã sửa; boundary `>= 95%` | 🟢 | ✅ Fixed 2026-05-19 (BUG-VFR-06) |
| D9 | Bucket boundary 95% | "Excellent ≥95%" (gốc §13) | CH SQL `cnt_vfr_95` đã đổi sang `>= 95` | 🔴 | ✅ Fixed 2026-05-19 (BUG-VFR-08, registry); ⏳ tenant config rollout pending |
| D10 | Error state | Banner + retry button khi fetch fail (gốc UX) | Banner đỏ + retry button | 🟡 | ✅ Fixed 2026-05-19 (BUG-VFR-07) |

---

## 18. Storytelling refresh v2 — Requirements

> **Scope**: UX uplift cho widget VFR đã ship v1.0. Triggered by [`/da-storytelling-data` critique 2026-05-19](analysis/storytelling-review-2026-05-19.md) — 4 critical + 6 warning issues. Implementation track: [`docs/feature/vfr-storytelling-refresh/dev/plan.md`](../../../../docs/feature/vfr-storytelling-refresh/dev/plan.md).

### 18.1 Goal

Apply storytelling discipline cho VFR widget để 4 persona (BOD / Logistics Ops / Carrier Management / Planning) đọc được insight trong 1 glance thay vì serial scan + tự đối chiếu thủ công. Cùng pattern OTIF v1.1 đã ship (feature `otif-storytelling-refresh`, 2026-05-15).

**Audience problem hiện tại**: 4 persona xem cùng 1 screen với 5 KPI cards equal-weight + 3 charts no-target + Detail grid 29 cột. BOD không cần grid; Carrier cần "By Vendor" ở primary view; Planning cần GT vs VH delta luôn visible nhưng đang bị ẩn sau toggle mode.

### 18.2 Acceptance criteria

| ID | Title | Given / When / Then |
|---|---|---|
| **AC-S1** | Dynamic action titles (Fix 1) | **Given** widget render xong với data; **When** 3 charts (By Area / By Vehicle / By Loading Type×Time) + Time×Area table mount; **Then** mỗi chart/table show action title chứa worst dimension / trend direction / threshold cross (vd "Mekong 1 kéo VFR xuống 58% — thấp nhất 6 khu vực, hụt target 27 điểm"), KHÔNG phải static label "VFR theo Khu vực". Empty data → static fallback `actionTitleStatic`. |
| **AC-S2** | Hero card + GT vs VH delta luôn visible (Fix 2) | **Given** user mở widget; **When** chuyển mode tender ↔ operation; **Then** hero card show: (a) Avg VFR mode đang xem + RAG dot + Gap pt vs target 85% + sparkline 13w; (b) GT (thầu) % + VH (vận hành) % + Δ GT−VH **luôn hiển thị bất kể mode toggle**; (c) insight text 1 dòng theo `(tenderBand, operationBand)` band pair (5 templates: PlanGoodExecBad / PlanBadExecGood / BothGood / BothBad / DeltaSpread). |
| **AC-S3** | Exception panel drill-1-click (Fix 3) | **Given** có ≥ 1 chuyến với `vfr_max < 50%` trong 7 ngày gần nhất theo filter date_type hiện tại; **When** widget render; **Then** exception panel show: (a) count chuyến + window N ngày; (b) top 3 dim chips per area/vendor/vehicle (sort by count DESC); (c) CTA "Xem N chuyến →" — click switch sang Detail tab + apply pre-filter `vfr_max < 50` + `date_range = last_7d` trong 1 click. Empty state: badge xanh "Không có chuyến nào dưới 50% trong 7 ngày — hệ thống ổn". |
| **AC-S4** | RAG color theo target 85% (Fix 4 + Fix 5) | **Given** target VFR = 85% (per §3.6); **When** render Time×Area cells / By Area bars / By Vehicle bars / By Vendor bars; **Then** mỗi cell/bar tô RAG band: 🔴 < 75 / 🟡 75 – <85 / 🟢 ≥ 85. ReferenceLine ngang ở target 85% trên 3 bar charts (dashed). Average row + column của Time×Area giữ text-sky-400 (existing behavior). |
| **AC-S5** | Chart By Vendor mới (Fix 6) | **Given** admin đã paste canonical SQL cho section `byVendor` + `byVendorOperation` (per `vfr-spec.md §22`); **When** widget render mode tender hoặc operation; **Then** chart 4 "VFR theo Nhà vận tải" render sorted bar ascending + RAG color + tooltip secondary `planned_cbm`. Empty state khi SQL chưa configured: placeholder "Admin chưa cấu hình SQL — vào Settings → tab By Vendor". |
| **AC-S6** | 4 persona presets (Fix 7) | **Given** user chọn 1 trong 4 preset (BOD / Ops / Carrier / Planning); **When** widget render; **Then** chỉ render các section per ma trận §18.3. Default preset = Planning (full view). Legacy preset `preset-om-vfr` alias đến `preset-om-vfr-planning` để không break existing dashboards. |
| **AC-S7** | Bucket scheme RAG color collapse | **Given** 4 bucket chips (Low / Medium / High / Excellent) render dưới hero; **When** widget mount; **Then** 4 chips dùng RAG scheme: Low → 🔴, Medium → 🟡, High → 🟢, Excellent → 🟢 deep (`#059669`) — KHÔNG còn 5 màu rời (tím/đỏ/vàng/xanh dương/xanh lá). Avg merge vào hero number, không còn standalone card. |

### 18.3 Per-persona view matrix

| Section | BOD | Ops | Carrier | Planning (default) |
|---|---|---|---|---|
| Hero card (Avg VFR + GT/VH delta + sparkline) | ✅ | ✅ compact | ✅ | ✅ |
| Bucket chips (Low/Medium/High/Excellent) | — | ✅ | — | ✅ |
| Exception panel | — | ✅ | — | ✅ |
| Chart 1: By Area | — | — | ✅ | ✅ |
| Chart 2: By Vehicle | — | — | — | ✅ |
| Chart 3: By Loading Type × Time | sparkline 13w only (in hero) | — | — | ✅ |
| Chart 4: By Vendor (NEW) | — | — | ✅ | ✅ |
| Time × Area table | — | — | ✅ | ✅ |
| Detail grid 29 cột | — | ✅ pre-filtered `vfr_max < 70` | ✅ | ✅ |

Implementation: section visibility do `parsedConfig.visibleSections: string[]` điều khiển — preset templates declare array, widget render slot có điều kiện. Default fallback (no preset) = all sections (Planning behavior).

### 18.4 Business rules — Exception alert

| Rule | Giá trị | Rationale |
|---|---|---|
| Threshold trigger | `vfr_max < 50%` | Match Low bucket boundary §3.3; chuyến red severity |
| Window | 7 ngày từ `today` (tính theo filter `date_type` — ETA default) | Daily ops cadence cho Logistics Ops persona |
| Magnitude (sort ranking) | `(target − vfr) × planned_cbm` per chuyến, sum per dimension group | Volume-weighted — chuyến lớn không tải xuất hiện trước chuyến nhỏ không tải |
| Top-N per dimension | 3 chips per area / vendor / vehicle | Tóm gọn cho L2 panel; full list mở qua CTA drill-down |
| Empty state | Badge xanh "Hệ thống ổn — không có chuyến <50%" | Avoid silent empty (anti-pattern theo skill convention) |

### 18.5 Out of scope (storytelling v2)

- Migration target VFR sang tenant config — hardcode constant v1.0 per §3.6
- Per-loading-type target (Loose 75% / FP 85% riêng) — defer v1.x
- Late-alert correlation vào VFR widget — closed §13 + OQ-05 (late-alert sống ở widget riêng)
- Aggregate VFR formula correctness (Loose+FP weighted per TOBE V3 Bước 4-5) — separate ticket **BUG-VFR-09 Major** (data team rewrite SQL). Storytelling v2 render whatever `avg_vfr` SQL returns; FE không assert formula correctness.
- Cross-tenant rollout — Mondelez-only v1.0; lift sang shared widget v2.0 sau khi pattern validate
- Detail grid 29 cột restructure — keep current; chỉ wire pre-filter từ Exception panel CTA
- Settings dialog UI tab structure refactor — chỉ extend `SQL_SECTION_DEFINITIONS` để accept 2 new sections (`byVendor` + `byVendorOperation`)
- Backend code change — zero touch (admin-paste SQL pattern)
