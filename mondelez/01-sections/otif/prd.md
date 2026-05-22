# PRD — Section OTIF: Giám sát On-Time In-Full

| Trường | Giá trị |
|--------|---------|
| **Version** | 1.2.6 |
| **Ngày** | 2026-05-15 |
| **Trạng thái** | **PM Approved 2026-05-15 (v1.2.6 Phase 5 review reversal)** — Phase 1+3+4 ship-ready code. v1.2.6 chỉ đảo AC-15 + §13.4 Tier 3 default state (collapsed → expanded). 4 OQ PM tentative (OQ-07/09/10/11) chờ customer validate async, KHÔNG blocker. |
| **Tác giả** | BA Agent (v1.0.0); PM/DA (v1.1.0 via `/da-trace`); PM/DA (v1.2.0–v1.2.5 via `/da-storytelling-data` + `/da-biz-ba` + `/ba` + `/ba-review`) |
| **Phạm vi** | `01-sections/otif` — widget `WidgetOtif` trên dashboard Smartlog Control Tower |
| **Branch** | `feat-otif-storytelling-refresh` (tạo từ `fix-frontend-otif` 2026-05-12) |
| **Changelog v1.1.0** | Đồng bộ với FEAT-128 (reorder + chart by product type) + chartByWarehouse pre-existing. Cập nhật §5.2, §6, §7. Trace report: [`projects/trace/widget-otif-chart-reorder-and-category-2026-05-12.md`](../../../trace/widget-otif-chart-reorder-and-category-2026-05-12.md). |
| **Changelog v1.2.0** | Bổ sung quy tắc trình bày — Tier-based hierarchy, KPI target/RAG, action titles, target band, exception spotlight, typography scale. Bắt nguồn từ **2 phản biện**: [`analysis/wireframe-ux-review-2026-05-12.md`](analysis/wireframe-ux-review-2026-05-12.md) (`/da-biz-ba`, density + hierarchy) và critique storytelling/sizing 2026-05-12 (`/da-storytelling-data`, narrative + visual hierarchy). Thêm §13 mới + AC-10..AC-15. Mở 6 Open Questions (OQ-06..OQ-11) cần Ops Manager Mondelez confirm. |
| **Changelog v1.2.1** | **OQ-06 resolved**: Target % OTIF = **90%** (PM confirm 2026-05-12). Cập nhật §13.2 từ `[Assumption]` 95% → `[Decision]` 90%. Cập nhật RAG bands theo target mới: Green ≥ 90% / Yellow 85–<90% / Red < 85%. AC-10, AC-11, AC-13, AC-14 hết tham chiếu target giả định. OQ-07 thu hẹp scope (target % Ontime, % Infull vẫn open). |
| **Changelog v1.2.2** | Apply 3 blocker fixes từ `/ba-review` 2026-05-12: (B1) §13.2 + AC-10: % Ontime / % Infull chuyển sang **no-target mode** thay vì fallback 90% — tránh false-positive Green RAG khi metric thực tế cần ≥95/97% theo chuẩn FMCG. (B2) AC-14, AC-15: gỡ conditional suffix khỏi tiêu đề (move vào Given clause); AC-15 Then clause thay pixel/fold/`h-72` bằng outcome user-visible "≤ 2 lần scroll". (B3) Mở **OQ-12** (workshop 30' mental model Ops Manager — blocker cho Phase 2). Non-blocker: NB-1 restructure §13.10 always-apply vs conditional; NB-4 thay "Top offender" → "Giá trị xấu nhất trong dimension" trong AC-12. RAG band convention promoted sang `docs/shared/business-rules.md` (NB-2). |
| **Changelog v1.2.3** | Apply 4 cleanup fixes từ `/ba-review` round 2 (re-review v1.2.2): (B4) §13.10 phase numbering collision — đổi từ dual "Phase 2" thành 4-phase linear: Phase 1 Always-apply → Phase 2 Decision Workshop → Phase 3 Cockpit core (chỉ khi C) → Phase 4 Polish (chỉ khi C). (NB-5) §13 header + OQ-12 description: update stale OQ list (OQ-06 đã closed, thêm OQ-09/10/11/12; OQ-12 "Phase 0" → "Phase 2 Decision Workshop"). (NB-6) AC-13 Given: drop OQ-07 dependency vì Exception Spotlight chỉ dùng % OTIF target, không phụ thuộc target Ontime/Infull. (NB-7) §13.7 Reference line: clarify chỉ áp dụng cho metric có target được cấu hình (hiện tại: chỉ % OTIF; Ontime/Infull pending OQ-07). |
| **Changelog v1.2.4** | 4/6 OQ resolved (PM tentative): **OQ-07** target % Ontime = 95%, % Infull = 97% (PM giả định theo chuẩn FMCG — pending customer confirm sau). **OQ-09** thứ tự 5 dimensions Health Matrix: NVC → Kho → Loại hàng → Kênh → Khu vực. **OQ-10** = No (không cross-filter, chỉ smooth scroll + auto-expand Tier 3). **OQ-11** delta vs prior period = tuần trước + tháng trước (hiển thị 2 delta). Affects: §13.2 (RAG bands per metric), AC-10 (3 metric full RAG; Ontime/Infull marked PM tentative), §13.3 (delta dual baseline), §13.5 (row order + click behavior), §13.7 (reference line all 3 metrics), §13.10 Phase 2 workshop scope (chỉ còn OQ-08 + OQ-12), Phase 4 effort (giảm vì không cross-filter). |
| **Changelog v1.2.5** | **2/2 OQ blockers resolved by PM**: **OQ-08** = **Phương án C** (Cockpit Tier-based) — §13.4 Tier hierarchy + §13.5 Health Matrix + AC-14/15 IN SCOPE; Phase 3 + Phase 4 dev unlocked. **OQ-12** = Q1→Q5 mental model **confirmed** — §13.9 [Assumption] → [Decision]. Status: **PM Approved, sẵn sàng `/planner`**. Affects: §13.4/§13.5/§13.9 từ `[pending]` → `[Decision]`; AC-14/15 Given clauses simplified (drop OQ-08/OQ-12 preconditions, giữ "Tier 1/2 đã triển khai"); §13.10 Phase 2 từ "Decision Workshop blocker" → "Customer Validation (async, non-blocker)"; §13 header Trạng thái → "PM Approved 2026-05-12". |
| **Changelog v1.2.6** | **AC-15 / §13.4 Tier 3 reversal — Phase 5 review 2026-05-15**: PM Mondelez đảo Tier 3 default state từ **collapsed → expanded**. Lý do: storytelling intent ưu tiên "zero click drill-down" + "mọi dim chart hiện sẵn trên 1 narrative liên tục" hơn là "fewer-scroll/short tab". Affects: AC-15 title + Then + Outcome (drop ≤2 scroll requirement); §13.4 Tier 3 description (header toggle = click-to-collapse thay vì click-to-expand); §13.1 G4 (chiều dài tab Chart không còn ràng buộc ~1,200px, baseline ~2,800px chấp nhận); §13.10 không đổi (4 phases linear giữ nguyên). KHÔNG ảnh hưởng AC-10..AC-14; KHÔNG ảnh hưởng Phase 1+3+4 code đã ship (`widget-otif-cockpit.tsx:39` `defaultOpen ?? true` đã đúng intent v1.2.6). |

---

## 1. Mục đích

Section OTIF cung cấp bảng điều khiển giám sát tỷ lệ giao hàng **đúng hạn và đủ số lượng** (On-Time In-Full) cho đội vận hành Mondelez. Người dùng có thể theo dõi KPI tổng hợp, phân tích nguyên nhân thất bại và tra cứu chi tiết từng đơn hàng.

---

## 2. Người dùng mục tiêu

| Vai trò | Nhu cầu chính |
|---------|--------------|
| Quản lý vận hành (Ops Manager) | Xem tỷ lệ OTIF tổng thể, so sánh theo khu vực / NVC / kênh |
| Chuyên viên vận tải (Logistics Analyst) | Phân tích nguyên nhân fail, xác định NVC / khu vực yếu |
| Nhân viên kho (Warehouse Staff) | Tra cứu chi tiết đơn hàng cụ thể |

---

## 3. Định nghĩa nghiệp vụ

> **[Observed]** — Tất cả định nghĩa dưới đây được trích xuất trực tiếp từ source code widget (`widget-otif.tsx`, `widget-otif-settings-dialog.tsx`) và chuỗi i18n (`dashboard-order-monitor.json`).

| Thuật ngữ | Định nghĩa | Công thức / Điều kiện |
|-----------|-----------|----------------------|
| **Ontime** | Đơn giao đúng hạn | `ATA ≤ ETA` |
| **Infull** | Đơn giao đủ số lượng | `Kế hoạch (planned_cse) = Xuất kho (shipped_cse) = Giao (delivered_cse)` |
| **OTIF** | Đơn vừa đúng hạn vừa đủ số lượng | `Ontime AND Infull` |
| **% Ontime** | Tỷ lệ đơn Ontime | `COUNT(Ontime DO) / COUNT(DO) × 100` |
| **% Infull** | Tỷ lệ đơn Infull | `COUNT(Infull DO) / COUNT(DO) × 100` |
| **% OTIF** | Tỷ lệ đơn OTIF | `COUNT(OTIF DO) / COUNT(DO) × 100` |
| **DO** | Delivery Order — đơn giao hàng | Đơn vị đếm cơ bản |
| **SO** | Sales Order — đơn bán hàng | Gắn với nhiều DO |
| **CSE** | Case — đơn vị số lượng hàng | Đơn vị tính Infull |
| **ETA** | Expected Time of Arrival | Thời điểm dự kiến giao hàng (ETA gửi thầu) |
| **ATA** | Actual Time of Arrival | Thời điểm giao hàng thực tế |

### Loại ngày lọc (Date Type)
> **[Observed]** — `widget-otif.tsx` line ~287, `OTIF_DATE_TYPE_OPTIONS`

| Giá trị | Mô tả |
|---------|-------|
| `ETA gửi thầu` | Lọc theo ETA trên đơn gửi thầu (mặc định) |
| `ATA chi tiết chuyến` | Lọc theo ATA thực tế trên chuyến |

### Phân loại nguyên nhân fail Ontime
> **[Observed]** — `classifyReason()` trong `widget-otif.tsx`

| Nguyên nhân | Điều kiện |
|-------------|-----------|
| Lỗi transport giao trễ | Ontime fail, planned_cse = shipped_cse |
| Lỗi warehouse gọi vào kho trễ | Ontime fail, shipped_cse < planned_cse |
| Lỗi transport vào kho trễ | Ontime fail, shipped_cse > 0, delivered_cse < shipped_cse |
| Lỗi rớt do warehouse | Infull fail, shipped_cse < planned_cse |
| Lỗi rớt do transport | Còn lại |

### Phân loại nguyên nhân fail Infull
> **[Observed]** — `classifyInfullBucket()` trong `widget-otif.tsx`

| Nguyên nhân | Điều kiện |
|-------------|-----------|
| Warehouse Infull failure | shipped_cse < planned_cse (lỗi kho) |
| Transport Infull failure | delivered_cse < shipped_cse (lỗi vận tải) |
| WH + Transport Infull failure | Cả hai đều lỗi |

---

## 4. Bộ lọc (Filters)

> **[Observed]** — `OTIF_FILTER_DEFINITIONS` trong `widget-otif.tsx`

| Filter | Key | Loại | Giá trị mặc định | Ghi chú |
|--------|-----|------|-----------------|---------|
| Kho | `whseid` | Multi-select | ALL | BKD, NKD, Kho ngoài BKD, Kho ngoài NKD |
| Khu vực giao hàng | `area` | Multi-select | ALL | South East, Ho Chi Minh, Mekong 1, Mekong 2 |
| Nhóm hàng | `group_of_cargo` | Multi-select | ALL | PM, TEST, EQUIPMENT, MOONCAKE, POSM/OFFBOM, FRESH, DRY |
| Nhà vận tải | `transporter` | Multi-select | ALL | HVP, TLL, NJV-Nhất Tín, ... |
| Loại ngày | `dateType` | Single-select | ETA gửi thầu | ETA gửi thầu / ATA chi tiết chuyến |
| Khoảng ngày | `otifDateRange` | Date range | Today | Giới hạn tối đa 2 năm |

**Ràng buộc khoảng ngày:** Hệ thống từ chối khi `to_date - from_date > 2 năm` và hiển thị lỗi toast. **[Observed]** — `isDateStringRangeOver2Years()`, `MAX_DATE_RANGE_MS = 2 * 365.25 * 24 * 60 * 60 * 1000`

### Ánh xạ Kho → whseid
> **[Observed]** — `mapWarehouseToWhseid()` trong `widget-otif.tsx`

| Filter value | whseid truyền vào SQL |
|-------------|----------------------|
| BKD | BKD1, BKD2, BKD3 |
| NKD | NKD |
| Kho ngoài BKD | VN821 |
| Kho ngoài NKD | VN831 |
| ALL | Tất cả kho mặc định |

---

## 5. Cấu trúc màn hình

> **[Observed]** — `WidgetOtif` component trong `widget-otif.tsx` (~950 dòng); `OtifDetailPanel` trong `widget-otif-detail.tsx`

Section OTIF gồm **2 vùng chính**: Panel KPI + Charts (trên), và Panel Chi tiết (tab dưới).

### 5.1 KPI Cards (hàng đầu)

4 thẻ hiển thị song song:

| Card | Metric | Mô tả |
|------|--------|-------|
| Tổng đơn | `totalSo` | Tổng số DO trong phạm vi lọc. `COUNT(DISTINCT DO)` |
| % Ontime | `pctOntime` | Tỷ lệ đơn giao đúng hạn. `COUNT(Ontime DO) / COUNT(DO) × 100` |
| % Infull | `pctInfull` | Tỷ lệ đơn giao đủ số lượng. `COUNT(Infull DO) / COUNT(DO) × 100` |
| % OTIF | `pctOtif` | Tỷ lệ đơn đạt cả Ontime và Infull. `COUNT(OTIF DO) / COUNT(DO) × 100` |

Mỗi card hiển thị: giá trị %, số đơn tuyệt đối (phụ), mô tả ngắn, icon màu, và tooltip giải thích công thức.

### 5.2 Charts

> **[Observed — v1.1.0]** Thứ tự render trong code (FEAT-128, commit `80194e9`) — insight-first: lý do fail (root cause) → trend → các chiều drill-down. Xem [widget-otif.tsx:1240..1837](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1240).

| # | Chart | Tiêu đề (i18n vi) | Loại | Trục / Chiều | JSX line |
|---|---|---|---|---|---|
| 1 | Fail Ontime Reason | Lý do fail ontime | Bar chart horizontal (h=256px) | X: fail_so, Y: lý do | [1240](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1240) |
| 2 | Fail Infull Reason | Lý do fail infull | Bar chart horizontal (h=256px) | X: fail_so, Y: lý do | [1309](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1309) |
| 3 | Trend by Time | %OTIF và số lượng đơn theo thời gian | Composed chart (Line + Bar, h=288px) | X: ngày/tuần/tháng, Y trái: %, Y phải: số đơn | [1379](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1379) |
| 4 | By Transporter | OTIF / Ontime / Infull theo nhà vận tải | Bar chart grouped (h=288px) | X: NVC, Y: % | [1497](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1497) |
| 5 | **By Category** (NEW — FEAT-128) | OTIF / Ontime / Infull theo loại hàng | Bar chart grouped (h=288px) | X: loại hàng (FRESH/DRY/...), Y: % | [1580](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1580) |
| 6 | By Sales Channel | OTIF / Ontime / Infull theo kênh bán hàng | Bar chart grouped (h=288px) | X: kênh, Y: % | [1671](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1671) |
| 7 | **By Warehouse** (pre-existing, chưa có ở v1.0.0) | OTIF / Ontime / Infull theo kho | Bar chart grouped (h=288px) | X: kho (whseid), Y: % | [1754](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1754) |
| 8 | By Area | OTIF / Ontime / Infull theo khu vực | Bar chart grouped (h=288px) | X: khu vực, Y: % | [1837](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1837) |

**Layout responsive**: Fail Ontime + Fail Infull render side-by-side ở `xl` (`xl:grid-cols-2`). Trên `<xl` stack vertical. Các chart còn lại full-width một cột.

**Trend chart** có toggle chọn Time Bucket: Day / Week / Month. **[Observed]** — `TIME_BUCKET_OPTIONS`, `TimeBucket` type.

**Chart by Category — ordering**: Segments được sort client-side theo `OTIF_CATEGORY_ORDER = ['FRESH','DRY','MOONCAKE','POSM/OFFBOM','TEST','EQUIPMENT','PM']` (priority 1–7). Loại hàng không match list → fallback priority 99 + sort alpha. **[Observed]** — [widget-otif.tsx:522-530](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L522-L530), sort logic [:938-955](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L938-L955).

**Empty state — Chart by Category**: Khi `sqlQueries.chartByCategory` chưa được cấu hình → hiển thị message i18n `categoryNoConfig`. Các chart khác KHÔNG bị block. **[Observed]** — [widget-otif.tsx:1586-1591](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1586-L1591).

Mỗi chart có nút export (ảnh / CSV). **[Observed]** — `ChartExportMenu` component.

### 5.3 Panel Chi tiết (tabs)

Nằm trong `OtifDetailPanel`, hiển thị 3 tab:

| Tab | Tiêu đề | Nội dung |
|-----|---------|---------|
| %OTIF Chiều vận hành | Operation Summary | Bảng pivot: NVC × Kênh × Nhóm hàng × Khu vực với % OTIF, % Ontime, % Infull, tổng đơn |
| Fail Report | Report fail ontime / infull | Bảng tổng hợp số đơn fail ontime + phân loại nguyên nhân theo từng NVC/kênh/khu vực |
| Chi tiết đơn hàng | Detail Table | Bảng full chi tiết từng DO — tất cả cột trường của `OtifRow` |

**Dimension grouping** cho Operation Summary và Fail Report: Người dùng chọn tối đa 4 chiều `transporter`, `groupName`, `groupOfCargo`, `area` để pivot bảng. **[Observed]** — `summaryDims: SummaryDimensionKey[]`, `DIMENSION_OPTIONS`.

---

## 6. Nguồn dữ liệu và SQL Queries

> **[Observed]** — `OtifSqlQueries` interface trong `widget-otif-settings-dialog.tsx`; `QUERY_META`, `SQL_FIELD_HINTS`, `SQL_REQUIRED_COLUMNS`

Widget được cấu hình bởi **12 SQL query riêng biệt** (v1.1.0 — thêm `chartByWarehouse`, `chartByCategory`), mỗi query phục vụ một phần tử hiển thị:

| Query Key | Phục vụ | Cột bắt buộc (alias chấp nhận trong dấu ngoặc) |
|-----------|---------|-------------|
| `cards` | KPI Cards | `total_so, ontime_so, pct_ontime, infull_so, pct_infull, otif_so, pct_otif` |
| `chartByArea` | Chart By Area | `area (khu_vuc_doi_xe), pct_otif, pct_ontime, pct_infull` |
| `chartBySalesChannel` | Chart By Sales Channel | `kenh_ban_hang (group_name), total_so, ontime_so, pct_ontime, infull_so, pct_infull, otif_so, pct_otif` |
| `chartByTransporter` | Chart By Transporter | `nha_van_tai (transporter, ten_ngan_nha_van_tai), total_so, ontime_so, pct_ontime, infull_so, pct_infull, otif_so, pct_otif` |
| `chartByWarehouse` ★ | Chart By Warehouse | `kho (whseid, warehouse), total_so, pct_otif, pct_ontime, pct_infull` |
| `chartByCategory` ★ | Chart By Category (FEAT-128) | `group_of_cago (group_of_cargo, category), total_so, pct_otif, pct_ontime, pct_infull` |
| `chartFailOntime` | Chart Fail Ontime | `reason, fail_so` |
| `chartFailInfull` | Chart Fail Infull | `reason, fail_so` |
| `chartTrend` | Trend Chart | `period (day/week/month), total_so, otif_so` |
| `operationSummary` | %OTIF Chiều vận hành | `transporter, group_name, group_of_cargo, area, total_so, otif_so, ontime_so, infull_so` |
| `failSummary` | Fail Report | `total_so, fail_ontime_so, late_arrival_by_transport, late_wh_call_by_warehouse, late_pickup_by_warehouse, late_departure_by_transport, late_delivery_by_transport, fail_infull_so, warehouse_infull_failure, transport_infull_failure, warehouse_transport_infull_failure` |
| `detailTable` | Chi tiết đơn hàng | `do_code, warehouse, eta, ata, planned_cse, shipped_cse` |

★ = **Mới so với v1.0.0**. `chartByCategory` được thêm bởi FEAT-128 (2026-05-12). `chartByWarehouse` đã có từ trước (commit `53dd564`) nhưng v1.0.0 chưa ghi nhận.

> **SQL template Mondelez** cho `chartByCategory` (r6 — production-verified, ClickHouse pattern `arraySort([{{x}}]) + mv_filter_*` + 7 date_type CASE): xem [`docs/feature/widget-otif-chart-reorder-and-category/dev/plan.md` §5.2](../../../../docs/feature/widget-otif-chart-reorder-and-category/dev/plan.md). Source table: `analytics_workspace.mv_otif`. Business rule: exclude `otif_status = 'Không có dữ liệu STM'`.

### SQL Placeholders

> **[Observed]** — `bindOtifPlaceholders()` trong `widget-otif.tsx`

Các placeholder được thay thế động theo giá trị filter hiện tại:

| Placeholder | Mô tả |
|-------------|-------|
| `{{whseid}}` | Danh sách kho dạng SQL literals, ví dụ `'BKD1','BKD2'` |
| `{{area}}` | Danh sách khu vực |
| `{{group_of_cargo}}` / `{{group_of_cago}}` | Danh sách nhóm hàng (hai alias) |
| `{{transporter}}` | Danh sách NVC |
| `{{from_date}}` | Datetime bắt đầu dạng `'YYYY-MM-DD 00:00:00'` |
| `{{to_date}}` | Datetime kết thúc dạng `'YYYY-MM-DD 23:59:59'` |
| `{{date_type}}` / `{{dateType}}` / `{{loai_ngay}}` | Loại ngày lọc (ba alias) |
| `[[ AND ... ]]` | Optional clause — bị loại bỏ khi giá trị là null |

### Fallback (mock data)
Khi widget chưa được cấu hình dataSource (`hasSqlConfig = false`), widget hiển thị **mock data tĩnh** gồm 120 dòng để người dùng xem trước layout. **[Observed]** — `buildMock()`, `hasSqlConfig` check.

---

## 7. Luồng dữ liệu

> **[Observed]** — `useQuery` trong `WidgetOtif`, `dashboardV2Api.executeWidget()`

```
User thay đổi filter
  → filterOverrides object được tính lại (useMemo)
  → useQuery invalidate (queryKey chứa filterOverrides)
  → Gọi song song 9 API (cards, byArea, bySalesChannel, byTransporter,
                        byWarehouse, byCategory, failOntime, failInfull, trend)
  → Normalize từng response → state hiển thị
  → Hai tab (operationSummary, failSummary) được tải lazy khi user mở OtifDetailPanel
  → detailTable tải khi user mở tab Chi tiết
```

> **[Observed — v1.1.0]** — [widget-otif.tsx:855-863](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L855-L863). v1.0.0 ghi 7 API; FEAT-128 + chartByWarehouse pre-existing nâng lên 9.

**Cache**: `staleTime = 5 phút`. **[Observed]** — `useQuery` config.

---

## 8. Cấu hình Widget (Settings Dialog)

> **[Observed]** — `WidgetOtifSettingsDialog` trong `widget-otif-settings-dialog.tsx`

Người dùng có quyền `editMode` có thể mở dialog cấu hình widget với:
- **Data Source**: chọn datasource (table/view)
- **10 tab SQL**: mỗi tab tương ứng một query key, có editor Monaco với syntax highlighting
- **Test Query**: kiểm tra SQL trực tiếp và validate cột bắt buộc
- **Filter Settings**: cấu hình bộ lọc động (`SqlFilterPanel`)

Widget config được lưu dưới dạng JSON string trong `widget.config`. **[Observed]** — `parseSqlWidgetConfig<WidgetOtifConfig>()`.

---

## 9. Acceptance Criteria

### AC-01: KPI Cards hiển thị đúng

**Given** widget được cấu hình với datasource và query `cards`  
**When** user load trang hoặc thay đổi filter  
**Then** 4 thẻ KPI hiển thị: Tổng đơn, % Ontime, % Infull, % OTIF — mỗi thẻ có giá trị % và số đơn tuyệt đối

### AC-02: Filter khoảng ngày bị giới hạn

**Given** user đang cấu hình filter Date Range  
**When** user chọn khoảng > 2 năm và nhấn Apply  
**Then** hệ thống không gọi API và hiển thị thông báo lỗi; filter không được áp dụng

### AC-03: Charts hiển thị đúng chiều

**Given** widget có đầy đủ 5 query charts  
**When** page load xong  
**Then**:
- Bar chart By Area hiển thị % Ontime / Infull / OTIF theo từng khu vực
- Bar chart By Sales Channel hiển thị % Ontime / Infull / OTIF theo kênh
- Bar chart By Transporter hiển thị % Ontime / Infull / OTIF theo NVC
- Fail Ontime chart hiển thị số đơn fail theo từng lý do
- Fail Infull chart hiển thị số đơn fail theo từng lý do (Warehouse / Transport / Cả hai)

### AC-04: Trend chart đổi time bucket

**Given** trend chart đang hiển thị  
**When** user nhấn nút "Day" / "Week" / "Month"  
**Then** trục X và dữ liệu grouping thay đổi tương ứng; không gọi lại API (tính toán từ dữ liệu đã fetch)

### AC-05: Operation Summary pivot theo chiều

**Given** user mở tab "%OTIF Chiều vận hành"  
**When** user chọn/bỏ chọn các chiều (NVC, Kênh, Nhóm hàng, Khu vực)  
**Then** bảng pivot nhóm lại theo đúng các chiều đã chọn, % OTIF được tính lại

### AC-06: Detail table hiển thị đầy đủ cột

**Given** user mở tab "Chi tiết đơn hàng"  
**When** dữ liệu được tải từ `detailTable` query  
**Then** bảng hiển thị tất cả cột của `OtifRow` bao gồm: DO, SO, Kho, Khu vực, Nhóm hàng, Kênh, NVC, ETA, ATA, Planned/Shipped/Delivered CSE, trạng thái Ontime/Infull/OTIF

### AC-07: Mock data khi chưa cấu hình

**Given** widget chưa được gắn datasource  
**When** user xem dashboard  
**Then** widget hiển thị mock data 120 dòng để preview layout; không gọi API

### AC-08: Export chart

**Given** user đang xem một chart bất kỳ  
**When** user nhấn nút export trên chart  
**Then** chart được xuất dưới dạng ảnh PNG hoặc dữ liệu CSV

### AC-09: Ánh xạ kho đúng

**Given** user chọn filter Kho = "BKD"  
**When** filter được áp dụng  
**Then** SQL nhận `whseid IN ('BKD1','BKD2','BKD3')`; chọn "Kho ngoài BKD" → `whseid IN ('VN821')`

---

### AC-10: KPI card hiển thị gap-to-target và trạng thái RAG  *(v1.2.0 / v1.2.1 / v1.2.2 / v1.2.4)*

**Given** target được cấu hình theo §13.2 (% OTIF = 90%, % Ontime = 95%, % Infull = 97% — 2 target sau PM tentative)  
**When** user load dashboard hoặc đổi filter  
**Then**:
- **3 KPI card có target** (% Ontime / % Infull / % OTIF) hiển thị đủ 4 phần tử (§13.3):
  - Giá trị hiện tại
  - Gap-to-target có dấu (ví dụ `−1.8pt` / `+1.5pt`)
  - Chỉ thị RAG theo bands per-metric §13.2 (OTIF: Green ≥90/Yellow 85–<90/Red <85; Ontime: Green ≥95/Yellow 90–<95/Red <90; Infull: Green ≥97/Yellow 92–<97/Red <92)
  - Delta vs prior period — hiển thị **2 delta**: vs tuần trước + vs tháng trước (§13.3, OQ-11 resolved v1.2.4)
- KPI card **"Tổng đơn"** KHÔNG có target — chỉ hiển thị giá trị và 2 delta (vs tuần trước + vs tháng trước)
- Khi target Ontime/Infull được customer confirm thay đổi (post-OQ-07 final) → chỉ update config, KHÔNG cần code change (theo §13.2 lưu ý cho /planner)

### AC-11: Trend chart có vùng target band  *(v1.2.0 / v1.2.1)*

**Given** user đang xem trend chart `% OTIF theo thời gian` với target = 90% (§13.2)  
**When** chart render  
**Then**:
- Vùng từ 90% đến 100% được tô màu nền xanh nhạt (visual reference band cho "đạt target")
- Đường % OTIF nằm trong band → eye nhận diện ngay là đang đạt mục tiêu
- Đường % OTIF dưới band → eye nhận diện ngay là dưới target
- Người dùng KHÔNG cần đối chiếu thủ công với số target

### AC-12: Mỗi chart có action title nói insight  *(v1.2.0)*

**Given** một chart bất kỳ trong tab Chart (trừ KPI cards)  
**When** data load xong  
**Then** tiêu đề chart **không** chỉ là tên dimension (ví dụ "OTIF theo NVC") mà nói rõ:
- Giá trị xấu nhất trong dimension (ví dụ: NVC/Kho/Loại hàng có % OTIF thấp nhất)
- Magnitude (giá trị %)
- Gap tới target khi áp dụng

Ví dụ outcome:
- "3/8 NVC dưới target — TLL kéo OTIF chung xuống 4pt"
- "Lỗi transport giao trễ chiếm 61% root cause (85/139 đơn fail ontime)"
- "OTIF giảm 3pt liên tiếp 5 ngày — chú ý spike đơn ngày 05-04"

Khi không có data (empty state) hoặc data không có exception → fallback về tiêu đề mô tả (giữ behavior v1.1.0).

### AC-13: Exception spotlight liệt kê top items off-target  *(v1.2.0 / v1.2.3)*

**Given** target % OTIF đã chốt (OQ-06 — 90%) và RAG bands theo §13.2  
**When** user xem tab Chart  
**Then** có một vùng "Exception Spotlight" liệt kê **top 3–5 items** (xuyên các dimension NVC / Kho / Loại hàng / Kênh / Khu vực) có % OTIF dưới target, sắp xếp theo magnitude (% gap × volume). Mỗi item hiển thị:
- Tên dimension + giá trị
- % OTIF hiện tại
- Gap tới target (signed)
- Số đơn fail tuyệt đối

Mỗi item là **link drill-down** mở chart chi tiết hoặc filter tương ứng.

### AC-14: Tier 1 snapshot vừa trên 1 fold *(v1.2.0 / v1.2.2 / v1.2.5)*

**Given** Tier 1 (§13.4) đã triển khai (sau Phase 3 Cockpit core), user mở dashboard trên viewport laptop chuẩn (1366×768) hoặc desktop chuẩn (1920×1080)  
**When** page load xong, chưa scroll  
**Then** user nhìn thấy đủ Tier 1 mà không cần scroll:
- 4 KPI cards (Tổng đơn / Ontime / Infull / OTIF) — % OTIF có target gap + RAG (AC-10), % Ontime/% Infull no-target mode tới khi OQ-07 chốt
- Health Matrix cross-dimension (5 chiều: NVC / Kho / Loại hàng / Kênh / Khu vực) — RAG color-coded
- Mini trend sparkline (giá trị %OTIF khung thời gian gần)

Người dùng trả lời được 3 câu hỏi đầu trong mental model Ops (`Q1: tổng OTIF có đỏ không / Q2: vấn đề ở chiều nào / Q3: trend ngắn hạn`) **mà không cần scroll xuống fold 2**.

### AC-15: Tier 3 drill-down expanded mặc định *(v1.2.0 / v1.2.2 / v1.2.5 / v1.2.6)*

> **Reversal v1.2.6 (Phase 5 review 2026-05-15)**: PM Mondelez chốt đảo từ collapsed → expanded mặc định. Lý do: storytelling intent là "mọi chart drill-down hiện sẵn trên 1 dòng narrative liên tục KPI → Matrix → Trend → 5 dim", user KHÔNG phải click để biết NVC/Kho/Loại hàng/Kênh/Khu vực có gì. Trade-off: tab Chart dài hơn (chấp nhận thêm scroll) đổi lấy "zero hidden affordance" + "thấy ngay" — đúng goal Q4/Q5 trong §13.9 mental model.

**Given** Tier 1 + Tier 2 (§13.4) đã triển khai (sau Phase 3 Cockpit core), user đang ở tab Chart  
**When** page load xong  
**Then** 5 chart drill-down (theo NVC / Kho / Loại hàng / Kênh / Khu vực) **expanded mặc định**, mỗi chart render đầy đủ với hành vi v1.1.0 (grouped-bar 3 metric Ontime/Infull/OTIF). Header `▼ Xem chi tiết theo [dimension]` + count badge vẫn click được để **manually collapse** (toggle behavior — user nào muốn tab gọn lại vẫn tự quyết).

**Outcome đo lường (v1.2.6)**:
- **Tier 1** (KPI cards + Health Matrix) vẫn fit 1 fold trên viewport 1366×768 (AC-14 không đổi) — đảm bảo Q1 + Q2 mental model trả lời ngay không cần scroll.
- **Tab Chart total height** chấp nhận tăng từ ~1,200px (collapsed-default plan v1.2.5) lên ~2,400-2,800px (expanded-default v1.2.6) — gần baseline v1.1.0 (~2,810px) nhưng được tổ chức theo Tier hierarchy với narrative liên tục.
- Zero click required cho drill-down — chart NVC/Kho/Loại hàng/Kênh/Khu vực render sẵn theo thứ tự `OQ-09` (NVC → Kho → Loại hàng → Kênh → Khu vực).
- Drill-down từ Health Matrix click row vẫn smooth-scroll + ensure-open (không cần expand vì đã open) — xem [`analysis/wireframe-ux-review-2026-05-12.md` §2.1](analysis/wireframe-ux-review-2026-05-12.md).

---

## 10. Hành vi không thuộc phạm vi (Out of Scope)

- Tạo / chỉnh sửa datasource (thuộc module Data Sources riêng biệt)
- Gửi cảnh báo / notification khi OTIF dưới ngưỡng (thuộc module Monitors)
- Cấu hình dashboard layout (thuộc dashboard builder)

---

## 11. Open Questions

| # | Câu hỏi | Mức độ | Người giải quyết |
|---|---------|--------|-----------------|
| OQ-01 | Ngưỡng % OTIF "tốt" / "cần cải thiện" của Mondelez là bao nhiêu? (Để thêm màu sắc cảnh báo vào KPI cards) | Medium | PO / Business Owner |
| OQ-02 | Tên chính xác của view/table ClickHouse tại môi trường Mondelez là gì? (Để viết SQL mẫu chính xác) | High | IT Mondelez |
| OQ-03 | Danh sách đầy đủ NVC (transporter) và khu vực (area) thực tế tại Mondelez? (Hiện hardcode trong fallback options) | Medium | Business Owner |
| OQ-04 | Đơn vị "CSE" (Case) có đúng với thuật ngữ Mondelez không? Hay cần dùng tên khác? | Low | Business Owner |
| OQ-05 | FE `OTIF_DATE_TYPE_OPTIONS` hiện chỉ có **2 value** (`'ETA gửi thầu'`, `'ATA chi tiết chuyến'`). SQL template r6 cho `chartByCategory` dùng **7 branch** `{{date_type}}` (`'ETA gửi thầu (đơn)'`, `'ATA chi tiết chuyến'`, `'Ngày gửi thầu'`, `'Ngày vào kho'`, `'Ngày duyệt chuyến'`, `'Ngày GI'`, `'Ngày tạo đơn hàng'`). Value `'ETA gửi thầu'` của FE KHÔNG match `'ETA gửi thầu (đơn)'` của SQL CASE. Quyết định: mở rộng FE → 7 option hay thu hẹp SQL → 2 option? | Medium | dev-fe / da-ch (tracked: FU-1 trong [plan.md §5.4 note #3](../../../../docs/feature/widget-otif-chart-reorder-and-category/dev/plan.md)) |
| ~~OQ-06~~ | ~~Giá trị target % OTIF chính thức~~ → **Resolved 2026-05-12 (v1.2.1)**: Target % OTIF = **90%** (PM confirm). Xem §13.2. | ~~High~~ Closed | ~~Ops Manager Mondelez~~ |
| ~~OQ-07~~ | ~~Target riêng cho % Ontime và % Infull~~ → **PM tentative 2026-05-12 (v1.2.4)**: Target % Ontime = **95%**, Target % Infull = **97%** (PM giả định theo chuẩn FMCG — sẽ trao đổi lại customer Mondelez để confirm chính thức). Xem §13.2. | ~~High~~ PM Tentative | ~~Ops Manager Mondelez~~ → Customer confirm sau |
| ~~OQ-08~~ | ~~Phạm vi v1.2.0 refresh~~ → **Resolved by PM 2026-05-12 (v1.2.5)**: **Phương án C** (Cockpit Tier-based) — §13.4 Tier hierarchy + §13.5 Health Matrix + AC-14/15 IN SCOPE; Phase 3 + 4 dev unlocked. | ~~High~~ Closed | ~~PM / Ops Manager Mondelez~~ |
| ~~OQ-09~~ | ~~Thứ tự ưu tiên 5 dimensions trên Tier 1 Health Matrix~~ → **PM tentative 2026-05-12 (v1.2.4)**: giữ thứ tự đề xuất — **NVC → Kho → Loại hàng → Kênh → Khu vực**. Xem §13.5 (rationale per row). | ~~Medium~~ PM Tentative | ~~Ops Manager Mondelez~~ → Customer validate sau |
| ~~OQ-10~~ | ~~Cross-filter giữa các chart~~ → **PM tentative 2026-05-12 (v1.2.4)**: **No** — click row Health Matrix chỉ smooth scroll + auto-expand chart Tier 3 tương ứng, KHÔNG filter các chart Tier 2 (Fail reason, Trend) để giữ context tổng. Phase 4 effort giảm. Xem §13.5 Click row + §13.10 Phase 4. | ~~Medium~~ PM Tentative | ~~PM / Ops Manager~~ → Customer validate sau |
| ~~OQ-11~~ | ~~Period baseline cho "vs prior period" delta~~ → **PM tentative 2026-05-12 (v1.2.4)**: hiển thị **2 delta** stacked — vs tuần trước + vs tháng trước. KHÔNG cho user chọn (giữ KPI card đơn giản, fixed baseline). Xem §13.3 + AC-10. | ~~Low-Medium~~ PM Tentative | ~~Ops Manager Mondelez~~ → Customer validate sau |
| ~~OQ-12~~ | ~~Mental model Ops Manager Mondelez~~ → **Resolved by PM 2026-05-12 (v1.2.5)**: Q1→Q5 trong §13.9 confirmed khớp mental model. §13.4 Tier hierarchy + §13.5 Health Matrix row order ready cho Phase 3. Customer Mondelez validate async qua Phase 2 (không blocker). | ~~High~~ Closed | ~~Ops Manager Mondelez~~ → Customer async |

---

## 12. Ghi chú kỹ thuật cho Planner

> Phần này chỉ nêu các **ràng buộc quan sát được** — quyết định implementation thuộc phạm vi `/planner`.

- Widget sử dụng `dashboardV2Api.executeWidget()` với `sectionKey` để backend biết query nào cần chạy.
- Tất cả normalization (camelCase / snake_case) xử lý tại frontend trong các hàm `normalize*FromSql()`.
- `operationSummary` và `failSummary` có thể compute từ `detailTable` data (mock path) hoặc từ SQL riêng (production path) — widget tự detect qua `hasOperationSummarySql`.
- Filter state được persist vào localStorage với key `dashboard-widget-filter:{dashboardId}:{widgetId}`.

---

## 13. Quy tắc trình bày — Storytelling Refresh v1.2.0

> **Trạng thái**: **PM Approved 2026-05-12** — sẵn sàng `/planner`. OQ-06 closed v1.2.1; OQ-08 = Phương án C + OQ-12 mental model confirmed v1.2.5; OQ-07/09/10/11 PM tentative chờ customer validate async (không blocker).
> **Nguồn gốc**: 2 phản biện ngày 2026-05-12:
> - `/da-biz-ba` review: [`analysis/wireframe-ux-review-2026-05-12.md`](analysis/wireframe-ux-review-2026-05-12.md) — density + hierarchy (Phương án C recommended)
> - `/da-storytelling-data` critique 2026-05-12 — narrative + visual hierarchy + sizing
>
> Section này mô tả **hành vi quan sát được** (PRD layer) — quyết định implementation (component naming, library choice, CSS class) thuộc `/planner` + `/frontend`.

### 13.1 Mục tiêu của v1.2.0

| # | Mục tiêu | Lý do |
|---|----------|-------|
| G1 | Trên 1 fold đầu, user trả lời được "OTIF tổng có đỏ không?" và "vấn đề ở chiều nào?" | Hiện tại fold 1 chỉ thấy KPI tổng — chưa biết root cause ở chiều nào |
| G2 | Mọi chart phải nói **insight**, không chỉ liệt kê data | Audience Ops Manager cần *so what*, không cần *what* |
| G3 | KPI cards phải có context "đạt hay không đạt" mà không cần user nhớ target ngoài đầu | Hiện tại 91.8% là số trần — không biết good/bad |
| G4 | Tier 1 (~650px) fit 1 fold trên 1366×768 → user trả lời Q1+Q2 không scroll. Tier 2+3 (expanded default v1.2.6) total chiều dài tương đương baseline ~2,800px nhưng tổ chức theo Tier hierarchy + narrative liên tục | v1.2.5 plan từng nhắm ~1,200px (collapsed default), nhưng v1.2.6 PM đảo → "zero click drill-down" quan trọng hơn fewer-scroll |
| G5 | Typography và visual hierarchy ưu tiên metric headline | Hiện tại KPI value 20px = body-large, không phải display weight |

### 13.2 Quy tắc business — Target & RAG bands

> **[Decision]** — Target % OTIF = **90%** (PM Mondelez confirm 2026-05-12, OQ-06 resolved).
> **[Assumption — PM tentative v1.2.4]** — Target % Ontime = **95%**, Target % Infull = **97%** (PM giả định theo chuẩn FMCG, OQ-07 partial — sẽ trao đổi lại với customer Mondelez để confirm chính thức).

**Targets per metric**:

| Metric | Target | Trạng thái |
|--------|--------|-----------|
| **% OTIF** | **90%** | `[Decision]` — PM confirm 2026-05-12, OQ-06 resolved |
| **% Ontime** | **95%** | `[Assumption — pending customer confirm]` — PM tentative v1.2.4 theo chuẩn FMCG; compound math: để OTIF ≥ 90% với 2 metric tương đối độc lập thì mỗi metric phải ≥ ~95% |
| **% Infull** | **97%** | `[Assumption — pending customer confirm]` — PM tentative v1.2.4 theo chuẩn FMCG (Infull thường nghiêm hơn Ontime vì rớt số lượng khó remediate hơn rớt thời gian) |

**RAG bands per metric** (áp dụng convention `target − 5pt buffer` từ [`docs/shared/business-rules.md`](../../../../docs/shared/business-rules.md)):

| Metric | Green (≥ target) | Yellow (target−5pt ≤ value < target) | Red (< target−5pt) |
|--------|------------------|--------------------------------------|--------------------|
| **% OTIF** | ≥ 90% | 85% – <90% | < 85% |
| **% Ontime** | ≥ 95% | 90% – <95% | < 90% |
| **% Infull** | ≥ 97% | 92% – <97% | < 92% |
| **Grey** (any metric) | — | — | Không đủ data (vd: dimension có < 5 đơn) |

**Áp dụng**: RAG bands trên dùng nhất quán xuyên suốt KPI cards, Health Matrix, chart titles, exception spotlight.

**Lưu ý cho /planner**:
- 3 target value (90/95/97%) nên được **lưu cấu hình** (config tại widget settings hoặc tenant config), KHÔNG hardcode — phòng khi Mondelez điều chỉnh target trong tương lai hoặc tenant khác có target khác.
- 2 target Ontime/Infull (95/97%) là PM tentative — nếu customer Mondelez confirm khác → chỉ cần update config, KHÔNG cần code change.
- Yellow buffer mặc định 5pt — nếu tenant override thì derive lại Yellow/Red boundaries.

### 13.3 KPI Cards — Quy tắc hiển thị mới

> Thay thế quy tắc §5.1 v1.1.0 cho 3 KPI có target (% Ontime, % Infull, % OTIF). KPI "Tổng đơn" giữ nguyên nhưng thêm delta vs prior period.

Mỗi KPI card (3 metric có target) phải hiển thị 4 phần tử thông tin:

1. **Tên metric** (label trên) — đủ readable (xem §13.6 typography)
2. **Giá trị hiện tại** (headline) — display weight, tabular-nums
3. **Gap-to-target** — số có dấu (ví dụ `−3.2pt` hoặc `+1.5pt`) — đặt cạnh hoặc dưới giá trị chính
4. **Trạng thái RAG** — chỉ thị màu (border, dot, hoặc background) áp dụng theo §13.2

Bổ sung (OQ-11 resolved v1.2.4):
- **Delta vs prior period** — hiển thị **2 delta** stacked: `▼ 1.4pt vs tuần trước` + `▲ 0.8pt vs tháng trước`
- **Subtitle context** — nhắc lại filter context (vd: `Theo ETA gửi thầu · 01–31/05/2026`)

KPI "Tổng đơn" (không có target):
- Headline value
- 2 delta (vs tuần trước + vs tháng trước)
- Subtitle context

### 13.4 Tier-based hierarchy (Phương án C — OQ-08 confirmed v1.2.5)

> **[Decision]** — OQ-08 PM chốt Phương án C 2026-05-12. OQ-12 mental model Q1→Q5 confirmed. Cấu trúc 3 tier khớp mental model Ops Manager: tổng → vấn đề ở đâu → lý do → trend → action.

**Tier 1 — Above the fold (snapshot, ≈ 1 fold laptop chuẩn)**
- Hàng 1: 4 KPI cards (theo §13.3)
- Hàng 2: Health Matrix (xem §13.5) + Mini trend sparkline
- Người xem trả lời được 3 câu hỏi đầu mà không cần scroll

**Tier 2 — Scroll 1 lần (root cause + trend đầy đủ)**
- 2 chart Fail Reason (Ontime + Infull) — bổ sung % share alongside count
- Trend chart đầy đủ với target band (xem §13.7)

**Tier 3 — Expanded mặc định, click-to-collapse (drill-down chi tiết)** *(v1.2.6 reversal)*
- 5 grouped-bar chart cũ (NVC / Kho / Loại hàng / Kênh / Khu vực) — **expanded mặc định**, render đầy đủ chart h-72 như v1.1.0 với header `▼ Xem chi tiết theo [dimension]` + count badge
- User click header → **manually collapse** từng dimension (toggle, không phải read-only header)
- Backward compatible: không xóa chart cũ, chỉ thay style header thành Collapsible

### 13.5 Health Matrix (Tier 1 — Phương án C)

> **[Decision]** — OQ-08 = C + OQ-12 mental model confirmed v1.2.5. OQ-09 row order + OQ-10 click behavior PM tentative v1.2.4 (chờ customer validate async).

Health Matrix là một bảng cross-dimension thay thế việc liệt kê 5 chart grouped-bar full-width. Hành vi quan sát được:

- **Rows**: 5 dimensions theo thứ tự ưu tiên Ops Manager (PM confirm v1.2.4, OQ-09 resolved):
  1. **NVC** (Nhà vận tải) — câu hỏi đầu Ops Manager khi OTIF tụt: "NVC nào kéo xuống?"
  2. **Kho** — kho fail hay vận tải fail là root cause phổ biến thứ 2
  3. **Loại hàng** — FRESH/DRY/MOONCAKE/... có pattern thời vụ khác nhau
  4. **Kênh** — bán hàng GT/MT có service level cam kết khác nhau
  5. **Khu vực** — geographic dispersion, ít actionable hơn 4 chiều trên
- **Sub-rows**: Mỗi dimension có 3–5 giá trị thực tế (ví dụ NVC có HVP, TLL, SVL, NJV, ...)
- **Columns**: % Ontime, % Infull, % OTIF, Tổng đơn
- **Cell coloring**: RAG per-metric theo §13.2 (3 target khác nhau → bands khác nhau)
- **Sort**: Mặc định worst-first trong mỗi dimension (% OTIF tăng dần)
- **Click row**: drill-down — **smooth scroll** xuống chart Tier 3 tương ứng + **auto-expand** chart đó. **KHÔNG** cross-filter các chart Tier 2 khác (Fail reason, Trend) — giữ context tổng (OQ-10 resolved v1.2.4 = No, PM tentative)
- **Empty state**: Khi một dimension không có data → row đó hiển thị "Không có data" + grey badge

### 13.6 Visual hierarchy & typography

> **[Decision]** — Áp dụng tất cả các phương án (A/B/C/D).

| Element | Quy tắc |
|---------|---------|
| KPI headline value | Display weight (lớn hơn đáng kể so với body) — không dùng body-large làm headline |
| KPI label, subtitle | Đủ readable (tối thiểu 12px hoặc text-xs theo design system) — không dùng 10px |
| KPI RAG indicator | Phải visible trên mọi resolution (kể cả retina/HiDPI) — không dùng border 0.5px |
| Vertical rhythm | Phân biệt rõ "section break" vs "item break" qua gap khác nhau |
| Section max-width | Có max-width container để chart không kéo dài quá rộng trên ultra-wide monitor (so sánh adjacent dimension khó khi bars cách xa) |
| Sticky KPI bar | KPI cards dính top khi user scroll (sau filter bar) — giữ context "đang so với target nào" trong suốt tab Chart |

### 13.7 Chart narrative rules

| Quy tắc | Mô tả |
|---------|-------|
| **Action title** | Mọi chart phải có title nói insight (xem AC-12) — không chỉ là tên dimension |
| **Trend target band** | Trend chart có vùng nền xanh nhạt từ target tới 100% (xem AC-11) — thay thế cách user phải đọc số target từ filter |
| **Fail reason % share** | Mỗi bar trong Fail Reason hiển thị thêm % share trên tổng fail (vd: `85 (61%)`) — magnitude lẫn tỉ trọng |
| **Reference line** | Chart % render horizontal dashed line tại target value cho từng metric. Hiện tại (post OQ-07 PM tentative v1.2.4): % OTIF tại 90%, % Ontime tại 95%, % Infull tại 97%. Khi customer confirm thay đổi → chỉ update config. |
| **Filter context echo** | Subtitle dưới mỗi chart nhắc lại filter context khi user share screenshot (loại ngày + khoảng ngày) |

### 13.8 Exception Spotlight (Decision)

Vùng "Exception Spotlight" nằm trong Tier 1 (nếu Phương án C) hoặc ngay sau KPI cards (nếu Phương án A). Hành vi:

- Liệt kê **top 3–5 items** xuyên 5 dimensions có % OTIF dưới target
- Sắp xếp theo magnitude impact = `(target − current) × volume`
- Mỗi item: tên dimension/giá trị + % OTIF + gap (signed) + số đơn fail + link drill-down

Empty state: Khi toàn bộ items đạt target → hiển thị message `"Tất cả chiều đều đạt target OTIF ≥ {target}%"` với badge xanh.

### 13.9 Mental model & audience priority

> **[Decision]** — OQ-12 confirmed by PM 2026-05-12 (v1.2.5). Pattern Q1→Q5 dưới đây được PM xác nhận khớp mental model Ops Manager Mondelez. Customer Mondelez có thể validate async qua Phase 2 — nếu phản hồi khác → trigger PRD revision trước Phase 3 kick-off.

Khi Ops Manager Mondelez mở dashboard buổi sáng, họ scan theo thứ tự:

```
Q1. %OTIF hôm nay có "đỏ" không?          ← KPI tổng (≤ 2 giây)
Q2. Nếu đỏ — vấn đề ở chiều nào?           ← Health Matrix (≤ 10 giây)
Q3. Lý do fail là gì?                      ← Fail reason (≤ 20 giây)
Q4. Xu hướng có xấu đi không?              ← Trend (≤ 30 giây)
Q5. Cần action gì? Ai chịu trách nhiệm?    ← Drill-down chi tiết
```

Layout v1.2.0 phải khớp thứ tự này — đó là tiêu chí test cho mọi quyết định trình bày.

### 13.10 Dependencies & phased rollout

> **[Restructured v1.2.2; phase numbering fixed v1.2.3]** — 4 phase tuyến tính, không trùng tên. Phase 1 always-apply chạy độc lập, Phase 2 = workshop quyết định A vs C, Phase 3-4 chỉ chạy khi OQ-08 = Phương án C. `/planner` có thể start Phase 1 ngay khi PRD approved, parallel với Phase 2 workshop.

**Phase 1 — Always-apply** (bất kể OQ-08; có thể start ngay khi PRD approved):

Scope:
- §13.3 KPI gap+RAG — % OTIF có đủ 4 phần tử; % Ontime/% Infull no-target mode tới khi OQ-07 chốt (xem B1 fix)
- §13.6 Visual hierarchy & typography
- §13.7 Chart narrative rules (action titles, target band, reference line cho metric có target, fail reason % share, filter context echo)
- §13.8 Exception Spotlight — placement linh hoạt: dưới KPI cards nếu Phương án A, trong Tier 1 nếu Phương án C

Acceptance Criteria valid Phase 1: AC-10, AC-11, AC-12, AC-13.

Effort ước lượng: ~1-1.5 ngày dev.

---

**Phase 2 — Customer Validation** (Async, KHÔNG blocker — chạy parallel với Phase 1 + 3 + 4):

OQ-08 và OQ-12 đã chốt PM v1.2.5 → Phase 2 chuyển từ "blocker workshop" sang "customer async validation". `/planner` có thể start Phase 3 ngay sau Phase 1, KHÔNG phải đợi Phase 2.

4 PM tentative items cần customer Mondelez validate (qua email / Q&A async, không có deadline cứng):
- OQ-07: confirm target % Ontime = 95% và % Infull = 97% (PM giả định FMCG standard)
- OQ-09: confirm thứ tự 5 dimensions NVC → Kho → Loại hàng → Kênh → Khu vực
- OQ-10: confirm No cross-filter
- OQ-11: confirm delta vs tuần trước + tháng trước

Nếu customer phản hồi khác PM tentative → PRD revision + config update (không phải code change theo §13.2 lưu ý cho /planner). Nếu mental model OQ-12 thực tế khác → trigger Phase 3 re-design trước rollout.

---

**Phase 3 — Cockpit core** (chỉ khi OQ-08 = Phương án C):
- §13.4 Tier-based hierarchy
- §13.5 Health Matrix component
- AC-14, AC-15 áp dụng

Effort ước lượng: ~3-5 ngày dev.

---

**Phase 4 — Polish** (chỉ khi OQ-08 = Phương án C):
- Click row Health Matrix → smooth scroll + auto-expand Tier 3 (OQ-10 = No, không cross-filter)
- Mobile layout (Health Matrix → scrollable horizontal)
- A11y: keyboard navigation cho matrix

Effort ước lượng: ~0.5-1 ngày dev (giảm so với v1.2.3 vì không cross-filter).

---

Tổng effort (cập nhật v1.2.4 sau OQ-10 = No):
- Phương án A: ~1-1.5 ngày dev (Phase 1 only) + ~30-60 phút Phase 2 workshop
- Phương án C: ~4.5-7.5 ngày dev (Phase 1 + 3 + 4) + ~30-60 phút Phase 2 workshop + 2 ngày BA/UX review

Tham chiếu effort estimate: [`analysis/wireframe-ux-review-2026-05-12.md` §7](analysis/wireframe-ux-review-2026-05-12.md).

