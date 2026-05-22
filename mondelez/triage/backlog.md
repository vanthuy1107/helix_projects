# Triage Backlog — Edit UX_UI MDLZ — 2026-05-09

- **Source file**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx`
- **Tenant**: Mondelez (MDLZ)
- **Total rows in source**: 140 actionable rows extracted from 14 sheets (raw file has ~330 rows incl. header/empty/closed)
- **Normalized & triaged**: 140
- **Skipped sheets**: `Overview` (meta dashboard for tracking — `% Tiến độ UI`, owners, deadlines — not feedback rows)
- **Closed-pre-triage** (status `Đã fixed` in source): ~120 rows excluded before triage (already done by team SLG)
- **BASE path**: `projects/mondelez/triage/edit-ux-ui-mdlz-2026-05-09/` — tenant-aware (rule 1: source under `projects/mondelez/`)
- **Triaged by**: da-triage skill
- **Triage date**: 2026-05-09

## Story Prefix convention (filename + status)

Mỗi stub file có prefix `[D]/[W]/[-]/[?]/[X]` ở đầu filename để PM scan folder + biết status ngay. Convention map từ status raw trong file Excel của khách MDLZ:

| Prefix | Meaning | Status raw |
|---|---|---|
| `[D]` | Done | `Đã fixed`, `Đã sửa=True` (KHÔNG có trong stub vì đã filter) |
| `[W]` | Work In Progress | `Đang fixing`, `Fix lại`, `In-dev`, `In-doing`, `In Progress`, `Pending`, `SLG đã nhận yêu cầu` |
| `[-]` | Draft (chưa pickup) | `New` hoặc blank |
| `[Q]` | Question (CS) | type=Question |
| `[X]` | Closed (Dup/OOS/cancelled) | `BỎ`, `trùng hả c`, type=Duplicate/Out-of-scope |
| `[?]` | Unmappable status | text raw không khớp pattern, cần BA review |

Chi tiết Done items (170 items đã đóng KHÔNG có stub): xem [`done-summary.md`](done-summary.md).

## Status distribution (only triaged 140 items, KHÔNG bao gồm 170 Done items)

| Prefix | Count | % |
|---|---|---|
| `[-]` | 92 | 65.7% |
| `[W]` | 29 | 20.7% |
| `[X]` | 18 | 12.9% |
| `[Q]` | 1 | 0.7% |
| `[?]` | 0 | 0.0% |

## Distribution by Type

| Type | Count | % |
|---|---|---|
| Bug | 15 | 10.7% |
| UX | 67 | 47.9% |
| Feature | 39 | 27.9% |
| Question | 1 | 0.7% |
| Duplicate | 16 | 11.4% |
| Out-of-scope | 2 | 1.4% |
| Need-more-info | 0 | 0.0% |


> **Note on classification**: Khách MDLZ dùng từ "lỗi cần fix" cho mọi item. Triage không treat tất cả thành "Bug" — chỉ items có "expected vs actual" rõ và behavior sai vs spec → Bug. Còn lại là UX/Feature.

## Severity (bugs only)

| Sev | Count |
|---|---|
| Sev1 (block, no workaround) | 0 |
| Sev2 (ảnh hưởng nghiệp vụ, có workaround) | 13 |
| Sev3 (annoyance/edge) | 2 |
| Sev4 (cosmetic) | 0 |

## Priority (Bug + Feature only — UX/Question/Duplicate/OOS không có)

| Priority | Count | Description |
|---|---|---|
| **Critical/Blocker** | 0 | Lỗi nghiêm trọng — ứng dụng không thể sử dụng (treo/sập/mất dữ liệu) |
| **Major** | 24 | Lỗi chức năng lớn — không có cách khắc phục tạm thời |
| **Minor** | 28 | Lỗi chức năng nhỏ — có thể khắc phục tạm thời |
| **Low/Cosmetic** | 2 | Lỗi giao diện / chính tả — ảnh hưởng nhỏ |

> Priority được auto-assign theo heuristic dựa trên text + severity. UX items KHÔNG có Priority (theo yêu cầu — chỉ Bug + Feature). Override thủ công trong stub file nếu cần.

## Area distribution

| Area | Count |
|---|---|
| VFR | 52 |
| Inventory | 22 |
| OrderMonitoring | 21 |
| Warehouse | 18 |
| Other | 11 |
| TransactionMove | 8 |
| FlashDaily | 8 |

## Tech layer distribution (where the fix lives)

| Tech layer | Count | What it means |
|---|---|---|
| `frontend-widget` | 46 | React component / Recharts / Shadcn UI (multi-select, chart, download) |
| `cross-stack` | 31 | Multiple layers (BE + FE, or data + BE + FE) |
| `frontend-config` | 27 | FormConfig / ViewConfig / dashboard layout (label, layout, scorecard rename) |
| `unknown` | 17 | NEED-INVESTIGATION — ambiguous one-liner, BA/PM manual review |
| `backend-config` | 15 | JSON QueryConfig / Dynamic Query param template (no code change) |
| `etl-data` | 4 | SQL view / materialized view / ETL pipeline |

## Owner team distribution (who fixes)

| Owner team | Count | Description |
|---|---|---|
| `dev-fe` | 63 | Frontend Developer (React 19, Shadcn, Recharts) |
| `mixed` | 45 | Multiple teams — needs coordination |
| `closed` | 18 | Closed (Duplicate / Out-of-scope) |
| `dev-be` | 9 | Backend Developer (.NET, EF Core, Dynamic Query) |
| `da` | 4 | Data Analyst (SQL views, ETL) |
| `cs` | 1 | Customer Success — answer & close |

## Tech layer × Type cross-tab

```
type             Bug  Duplicate  Feature  Out-of-scope  Question  UX
tech_layer                                                          
backend-config     8          5        0             1         0   1
cross-stack        2          0       18             0         1  10
etl-data           2          0        1             0         0   1
frontend-config    2          2        4             0         0  19
frontend-widget    1          7       15             1         0  22
unknown            0          2        1             0         0  14
```

> **Reading**: `etl-data` Bug = data sai từ pipeline (DA fix); `backend-config` Bug = QueryConfig JSON sai (DEV-BE quick edit, no migration); `frontend-widget` UX = capability missing on UI (DEV-FE code change); `cross-stack` = cần >1 team coordinate; `unknown` = ambiguous one-liner cần PM/BA review thủ công.

## Recurring patterns (PLATFORM-LEVEL items — implement once, applies to all views)

These patterns lặp lại trên nhiều view. Mỗi pattern đã được merge thành **1 platform stub** thay vì N stubs lẻ. Implement 1 lần ở widget framework / dashboard layer, không phải per-view.

| Status | ID | Pattern | # items | Affected views | Route | Path |
|---|---|---|---|---|---|---|
| `[W]` | PLATFORM-MULTI-SELECT-FILTER | multi-select-filter | 15 | %Stock Type (214), %Loose picking (234), VFR, Tỷ lệ đáp ứng  | /ba | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[W]` | PLATFORM-SORT-SEARCH-REPORT | sort-search-report | 5 | Tiến độ xuất hàng (204), %Stock Type (214), Movement transac | /da-discovery | [_platform/discoveries/[W]-PLATFORM-SORT-SEARCH-REPORT.md](_platform/discoveries/%5BW%5D-PLATFORM-SORT-SEARCH-REPORT.md) |
| `[-]` | PLATFORM-DOWNLOAD-IMG-EXCEL | download-img-excel | 5 | VFR, Tỷ lệ đáp ứng và tuân thủ, %Stock Type (214), VFR (224) | /da-discovery | [_platform/discoveries/[-]-PLATFORM-DOWNLOAD-IMG-EXCEL.md](_platform/discoveries/%5B-%5D-PLATFORM-DOWNLOAD-IMG-EXCEL.md) |
| `[-]` | PLATFORM-SHOW-VALUE-ON-CHART | show-value-on-chart | 3 | Cảnh báo đơn trễ (204), %Stock Type (214), %Loose picking (2 | /ba | [_platform/prd-asks/[-]-PLATFORM-SHOW-VALUE-ON-CHART.md](_platform/prd-asks/%5B-%5D-PLATFORM-SHOW-VALUE-ON-CHART.md) |
| `[-]` | PLATFORM-FILTER-FIXED-SCORECARD | filter-fixed-scorecard | 2 | %Stock Type (214), %Loose picking (234) | /ba | [_platform/prd-asks/[-]-PLATFORM-FILTER-FIXED-SCORECARD.md](_platform/prd-asks/%5B-%5D-PLATFORM-FILTER-FIXED-SCORECARD.md) |
| `[-]` | PLATFORM-APPLY-RESET-BUTTON | apply-reset-button | 2 | %Stock Type (214), %Loose picking (234) | /ba | [_platform/prd-asks/[-]-PLATFORM-APPLY-RESET-BUTTON.md](_platform/prd-asks/%5B-%5D-PLATFORM-APPLY-RESET-BUTTON.md) |
| `[-]` | PLATFORM-RENAME-SCORECARD | rename-scorecard | 2 | %Stock Type (214), Sheet7 | /ba | [_platform/prd-asks/[-]-PLATFORM-RENAME-SCORECARD.md](_platform/prd-asks/%5B-%5D-PLATFORM-RENAME-SCORECARD.md) |
| `[W]` | PLATFORM-VALUE-THOUSAND-SEP | value-thousand-sep | 1 | Sheet7 | /ba | [_platform/prd-asks/[W]-PLATFORM-VALUE-THOUSAND-SEP.md](_platform/prd-asks/%5BW%5D-PLATFORM-VALUE-THOUSAND-SEP.md) |


## Top priorities (Score-sorted, excluding Duplicate/OOS) — top 40

| # | Status | Triage ID | Source | Type | Area | Tech layer | Owner | Priority | Sev | Score | Title | Stub |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `[W]` | BUG-001 | VFR#11 | Bug | VFR | `cross-stack` | `mixed` | Major | Sev2 | 15.0 | Bảng dữ liệu detail | [bugs/cross-stack/[W]-BUG-001-vfr-bang-du-lieu-detail.md](bugs/cross-stack/%5BW%5D-BUG-001-vfr-bang-du-lieu-detail.md) |
| 2 | `[-]` | UX-002 | Cảnh báo đơn trễ (204)#15 | UX | OrderMonitoring | `frontend-widget` | `dev-fe` | — |  | 15.0 | Show số liệu lên chart | [_platform/prd-asks/[-]-PLATFORM-SHOW-VALUE-ON-CHART.md](_platform/prd-asks/%5B-%5D-PLATFORM-SHOW-VALUE-ON-CHART.md) |
| 3 | `[-]` | UX-003 | %Stock Type (214)#3 | UX | Inventory | `frontend-widget` | `dev-fe` | — |  | 15.0 | Bộ lọc | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| 4 | `[-]` | UX-004 | %Stock Type (214)#15 | UX | Inventory | `frontend-widget` | `dev-fe` | — |  | 15.0 | Show số liệu lên chart | [_platform/prd-asks/[-]-PLATFORM-SHOW-VALUE-ON-CHART.md](_platform/prd-asks/%5B-%5D-PLATFORM-SHOW-VALUE-ON-CHART.md) |
| 5 | `[-]` | UX-005 | %Loose picking (234)#3 | UX | Warehouse | `frontend-widget` | `dev-fe` | — |  | 15.0 | Bộ lọc | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| 6 | `[-]` | UX-006 | %Loose picking (234)#15 | UX | Warehouse | `frontend-widget` | `dev-fe` | — |  | 15.0 | Show số liệu lên chart | [_platform/prd-asks/[-]-PLATFORM-SHOW-VALUE-ON-CHART.md](_platform/prd-asks/%5B-%5D-PLATFORM-SHOW-VALUE-ON-CHART.md) |
| 7 | `[W]` | BUG-007 | VFR#2 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Bộ lọc "Kho lấy hàng" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| 8 | `[W]` | BUG-008 | VFR#4 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Bộ lọc "Khu vực giao hàng" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| 9 | `[W]` | BUG-009 | VFR#5 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Bộ lọc "Nhà vận tải" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| 10 | `[W]` | BUG-010 | VFR#6 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Bộ lọc "Loại xe gửi thầu" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| 11 | `[W]` | BUG-011 | Tỷ lệ đáp ứng và tuân thủ#2 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Bộ lọc "Kho lấy hàng" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| 12 | `[W]` | BUG-012 | Tỷ lệ đáp ứng và tuân thủ#4 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Bộ lọc "Khu vực giao hàng" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| 13 | `[W]` | BUG-013 | Tỷ lệ đáp ứng và tuân thủ#5 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Bộ lọc "Nhà vận tải" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| 14 | `[-]` | FEAT-014 | VFR#14 | Feature | VFR | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Tính năng xuất excel của từng chart | [_platform/discoveries/[-]-PLATFORM-DOWNLOAD-IMG-EXCEL.md](_platform/discoveries/%5B-%5D-PLATFORM-DOWNLOAD-IMG-EXCEL.md) |
| 15 | `[-]` | FEAT-015 | Tỷ lệ đáp ứng và tuân thủ#13 | Feature | VFR | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Tính năng xuất excel của từng chart | [_platform/discoveries/[-]-PLATFORM-DOWNLOAD-IMG-EXCEL.md](_platform/discoveries/%5B-%5D-PLATFORM-DOWNLOAD-IMG-EXCEL.md) |
| 16 | `[W]` | FEAT-016 | Tiến độ xuất hàng (204)#16 | Feature | OrderMonitoring | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Sort + Search ở report | [_platform/discoveries/[W]-PLATFORM-SORT-SEARCH-REPORT.md](_platform/discoveries/%5BW%5D-PLATFORM-SORT-SEARCH-REPORT.md) |
| 17 | `[-]` | FEAT-017 | %Stock Type (214)#11 | Feature | Inventory | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Tính năng download hình ảnh, excel | [_platform/discoveries/[-]-PLATFORM-DOWNLOAD-IMG-EXCEL.md](_platform/discoveries/%5B-%5D-PLATFORM-DOWNLOAD-IMG-EXCEL.md) |
| 18 | `[-]` | FEAT-018 | %Stock Type (214)#16 | Feature | Inventory | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Sort + Search ở report | [_platform/discoveries/[W]-PLATFORM-SORT-SEARCH-REPORT.md](_platform/discoveries/%5BW%5D-PLATFORM-SORT-SEARCH-REPORT.md) |
| 19 | `[W]` | FEAT-019 | Movement transaction (214)#16 | Feature | TransactionMove | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Sort + Search ở report | [_platform/discoveries/[W]-PLATFORM-SORT-SEARCH-REPORT.md](_platform/discoveries/%5BW%5D-PLATFORM-SORT-SEARCH-REPORT.md) |
| 20 | `[W]` | FEAT-020 | %Utilization (224)#16 | Feature | Warehouse | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Sort + Search ở report | [_platform/discoveries/[W]-PLATFORM-SORT-SEARCH-REPORT.md](_platform/discoveries/%5BW%5D-PLATFORM-SORT-SEARCH-REPORT.md) |
| 21 | `[W]` | FEAT-021 | VFR (224)#7 | Feature | VFR | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Tính năng download hình ảnh, excel | [_platform/discoveries/[-]-PLATFORM-DOWNLOAD-IMG-EXCEL.md](_platform/discoveries/%5B-%5D-PLATFORM-DOWNLOAD-IMG-EXCEL.md) |
| 22 | `[-]` | FEAT-022 | %Loose picking (234)#11 | Feature | Warehouse | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Tính năng download hình ảnh, excel | [_platform/discoveries/[-]-PLATFORM-DOWNLOAD-IMG-EXCEL.md](_platform/discoveries/%5B-%5D-PLATFORM-DOWNLOAD-IMG-EXCEL.md) |
| 23 | `[-]` | FEAT-023 | %Loose picking (234)#16 | Feature | Warehouse | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Sort + Search ở report | [_platform/discoveries/[W]-PLATFORM-SORT-SEARCH-REPORT.md](_platform/discoveries/%5BW%5D-PLATFORM-SORT-SEARCH-REPORT.md) |
| 24 | `[-]` | FEAT-024 | Sheet7# | Feature | Other | `cross-stack` | `mixed` | Low/Cosmetic |  | 9.0 | tính năng config thay đổi tên field report | [discoveries/cross-stack/[-]-FEAT-024-other-tinh-nang-config-thay-doi-ten-field-repo.md](discoveries/cross-stack/%5B-%5D-FEAT-024-other-tinh-nang-config-thay-doi-ten-field-repo.md) |
| 25 | `[W]` | UX-025 | Tỷ lệ đáp ứng và tuân thủ#10 | UX | VFR | `cross-stack` | `mixed` | — |  | 9.0 | Bảng dữ liệu detail | [prd-asks/cross-stack/[W]-UX-025-vfr-bang-du-lieu-detail.md](prd-asks/cross-stack/%5BW%5D-UX-025-vfr-bang-du-lieu-detail.md) |
| 26 | `[-]` | UX-026 | Cảnh báo đơn trễ (204)#21 | UX | OrderMonitoring | `backend-config` | `dev-be` | — |  | 9.0 | Bảng dữ liệu chi tiết | [prd-asks/backend-config/[-]-UX-026-ordermonitoring-bang-du-lieu-chi-tiet.md](prd-asks/backend-config/%5B-%5D-UX-026-ordermonitoring-bang-du-lieu-chi-tiet.md) |
| 27 | `[-]` | UX-027 | Cảnh báo đơn trễ (204)#22 | UX | OrderMonitoring | `cross-stack` | `mixed` | — |  | 9.0 | Bảng dữ liệu chi tiết | [prd-asks/cross-stack/[-]-UX-027-ordermonitoring-bang-du-lieu-chi-tiet.md](prd-asks/cross-stack/%5B-%5D-UX-027-ordermonitoring-bang-du-lieu-chi-tiet.md) |
| 28 | `[-]` | UX-028 | %Stock Type (214)#19 | UX | Inventory | `frontend-config` | `dev-fe` | — |  | 9.0 | Đổi tên scorecard | [_platform/prd-asks/[-]-PLATFORM-RENAME-SCORECARD.md](_platform/prd-asks/%5B-%5D-PLATFORM-RENAME-SCORECARD.md) |
| 29 | `[-]` | UX-029 | Tỷ lệ Đáp ứng & Tuân thủ (234)#9 | UX | VFR | `frontend-config` | `dev-fe` | — |  | 9.0 | Bộ lọc "Khoảng thời gian" | [prd-asks/frontend-config/[-]-UX-029-vfr-bo-loc-khoang-thoi-gian.md](prd-asks/frontend-config/%5B-%5D-UX-029-vfr-bo-loc-khoang-thoi-gian.md) |
| 30 | `[W]` | UX-030 | Sheet7#23 | UX | Other | `frontend-widget` | `dev-fe` | — |  | 9.0 | Thêm dấu phẩy phân cách hàng nghìn đối với cá | [_platform/prd-asks/[W]-PLATFORM-VALUE-THOUSAND-SEP.md](_platform/prd-asks/%5BW%5D-PLATFORM-VALUE-THOUSAND-SEP.md) |
| 31 | `[W]` | UX-031 | Sheet7#25 | UX | Other | `frontend-widget` | `dev-fe` | — |  | 9.0 | Chỉnh lại màu của Partial bins, đang bị trùng | [prd-asks/frontend-widget/[W]-UX-031-other-chinh-lai-mau-cua-partial-bins-dang-bi-t.md](prd-asks/frontend-widget/%5BW%5D-UX-031-other-chinh-lai-mau-cua-partial-bins-dang-bi-t.md) |
| 32 | `[-]` | UX-032 | Sheet7#54 | UX | TransactionMove | `frontend-config` | `dev-fe` | — |  | 9.0 | Đổi tên scorecard  - Tổng Pallet Nhập => Tổng | [_platform/prd-asks/[-]-PLATFORM-RENAME-SCORECARD.md](_platform/prd-asks/%5B-%5D-PLATFORM-RENAME-SCORECARD.md) |
| 33 | `[-]` | BUG-033 | VFR (224)#3 | Bug | VFR | `cross-stack` | `mixed` | Minor | Sev3 | 5.4 | Nội dung Bảng dữ liệu chi tiết | [bugs/cross-stack/[-]-BUG-033-vfr-noi-dung-bang-du-lieu-chi-tiet.md](bugs/cross-stack/%5B-%5D-BUG-033-vfr-noi-dung-bang-du-lieu-chi-tiet.md) |
| 34 | `[-]` | FEAT-034 | Cảnh báo đơn trễ (204)#20 | Feature | OrderMonitoring | `cross-stack` | `mixed` | Major |  | 5.4 | Nội dung Bảng dữ liệu chi tiết | [discoveries/cross-stack/[-]-FEAT-034-ordermonitoring-noi-dung-bang-du-lieu-chi-tiet.md](discoveries/cross-stack/%5B-%5D-FEAT-034-ordermonitoring-noi-dung-bang-du-lieu-chi-tiet.md) |
| 35 | `[-]` | UX-035 | %Stock Type (214)#20 | UX | Inventory | `cross-stack` | `mixed` | — |  | 5.4 | Nội dung Bảng dữ liệu chi tiết | [prd-asks/cross-stack/[-]-UX-035-inventory-noi-dung-bang-du-lieu-chi-tiet.md](prd-asks/cross-stack/%5B-%5D-UX-035-inventory-noi-dung-bang-du-lieu-chi-tiet.md) |
| 36 | `[-]` | BUG-036 | Tỷ lệ Đáp ứng & Tuân thủ (234)#4 | Bug | VFR | `frontend-config` | `dev-fe` | Major | Sev2 | 5.0 | Dòng chú thích của card view " Tỷ lệ đáp ứng  | [bugs/frontend-config/[-]-BUG-036-vfr-dong-chu-thich-cua-card-view-ty-le-dap-u.md](bugs/frontend-config/%5B-%5D-BUG-036-vfr-dong-chu-thich-cua-card-view-ty-le-dap-u.md) |
| 37 | `[-]` | BUG-037 | Tỷ lệ Đáp ứng & Tuân thủ (234)#7 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 5.0 | Param {{pickup_warehouse}} | [bugs/backend-config/[-]-BUG-037-vfr-param-pickup-warehouse.md](bugs/backend-config/%5B-%5D-BUG-037-vfr-param-pickup-warehouse.md) |
| 38 | `[-]` | BUG-038 | Sheet7# | Bug | Other | `etl-data` | `da` | Major | Sev2 | 5.0 | Số total position NKD là 3559, số hiển thị ch | [bugs/etl-data/[-]-BUG-038-other-so-total-position-nkd-la-3559-so-hien-th.md](bugs/etl-data/%5B-%5D-BUG-038-other-so-total-position-nkd-la-3559-so-hien-th.md) |
| 39 | `[-]` | BUG-039 | Tỷ lệ Đáp ứng & Tuân thủ (234)#14 | Bug | VFR | `frontend-config` | `dev-fe` | Major | Sev2 | 3.0 | Layout view "Tỷ lệ tuân thủ vận hành" | [bugs/frontend-config/[-]-BUG-039-vfr-layout-view-ty-le-tuan-thu-van-hanh.md](bugs/frontend-config/%5B-%5D-BUG-039-vfr-layout-view-ty-le-tuan-thu-van-hanh.md) |
| 40 | `[-]` | BUG-040 | Sheet7# | Bug | FlashDaily | `frontend-widget` | `dev-fe` | Minor | Sev3 | 3.0 | Bộ lọc Kho: giá trị BKD, NKD chưa work đúng   | [bugs/frontend-widget/[-]-BUG-040-flashdaily-bo-loc-kho-gia-tri-bkd-nkd-chua-work-dun.md](bugs/frontend-widget/%5B-%5D-BUG-040-flashdaily-bo-loc-kho-gia-tri-bkd-nkd-chua-work-dun.md) |


## Handoff summary

| Skill kế tiếp | Số stub | Path |
|---|---|---|
| `/qa-executor` (bugs) | 8 per-item + 0 platform | bugs/ |
| `/da-discovery` (features) | 16 per-item + 2 platform | discoveries/ |
| `/ba` (PRD revisions) | 6 per-item + 6 platform | prd-asks/ |
| `/da-trace` (drift checks) | 0 (deferred until `/ba` triages each UX) | trace-asks/ |
| (Closed) Duplicate / Out-of-scope / Question | 19 | — |


> **Lưu ý routing**:
> - `/qa-executor` cho bugs (Sev2 chiếm đa số): cần tạo formal bug report với repro env (browser, tenant connection, account)
> - `/da-discovery` cho features: chạy 5-question office-hours TRƯỚC KHI commit. Nhiều "Feature" thực ra là enhancement nhỏ — discovery sẽ filter
> - `/ba` cho UX issues: BA cần quyết định mỗi item là **PRD gap** (chưa spec) hay **drift** (đã spec nhưng UI sai). Nếu drift → forward sang `/da-trace`
> - **Đa số items đã closed bằng status "Đã fixed" trong source file** — chỉ triage những item active

## Open questions / Need-more-info

- **Q-139** (Sheet7#): ở report hàng rớt: thêm fillter by , lăng kinh khác (đợi mdl sẽ feedback lại)


## Full backlog (all 140 items)

<details>
<summary>Click to expand full table</summary>

| Prefix | Triage ID | Source | Type | Area | Tech layer | Owner | Priority | Sev | Score | Status raw | Conf | Title | Pattern |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `[W]` | BUG-001 | VFR#11 | Bug | VFR | `cross-stack` | `mixed` | Major | Sev2 | 15.0 | Đang fixing | High | Bảng dữ liệu detail | detail-table |
| `[-]` | UX-002 | Cảnh báo đơn trễ (204)#15 | UX | OrderMonitoring | `frontend-widget` | `dev-fe` | — |  | 15.0 | New | High | Show số liệu lên chart | show-value-on-chart |
| `[-]` | UX-003 | %Stock Type (214)#3 | UX | Inventory | `frontend-widget` | `dev-fe` | — |  | 15.0 | New | High | Bộ lọc | multi-select-filter |
| `[-]` | UX-004 | %Stock Type (214)#15 | UX | Inventory | `frontend-widget` | `dev-fe` | — |  | 15.0 | New | High | Show số liệu lên chart | show-value-on-chart |
| `[-]` | UX-005 | %Loose picking (234)#3 | UX | Warehouse | `frontend-widget` | `dev-fe` | — |  | 15.0 | New | High | Bộ lọc | multi-select-filter |
| `[-]` | UX-006 | %Loose picking (234)#15 | UX | Warehouse | `frontend-widget` | `dev-fe` | — |  | 15.0 | New | High | Show số liệu lên chart | show-value-on-chart |
| `[W]` | BUG-007 | VFR#2 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Fix lại | High | Bộ lọc "Kho lấy hàng" | multi-select-filter |
| `[W]` | BUG-008 | VFR#4 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Fix lại | High | Bộ lọc "Khu vực giao hàng" | multi-select-filter |
| `[W]` | BUG-009 | VFR#5 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Fix lại | High | Bộ lọc "Nhà vận tải" | multi-select-filter |
| `[W]` | BUG-010 | VFR#6 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Fix lại | High | Bộ lọc "Loại xe gửi thầu" | multi-select-filter |
| `[W]` | BUG-011 | Tỷ lệ đáp ứng và tuân thủ#2 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Fix lại | High | Bộ lọc "Kho lấy hàng" | multi-select-filter |
| `[W]` | BUG-012 | Tỷ lệ đáp ứng và tuân thủ#4 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Fix lại | High | Bộ lọc "Khu vực giao hàng" | multi-select-filter |
| `[W]` | BUG-013 | Tỷ lệ đáp ứng và tuân thủ#5 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 9.0 | Fix lại | High | Bộ lọc "Nhà vận tải" | multi-select-filter |
| `[-]` | FEAT-014 | VFR#14 | Feature | VFR | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | New | High | Tính năng xuất excel của từng chart | download-img-excel |
| `[-]` | FEAT-015 | Tỷ lệ đáp ứng và tuân thủ#13 | Feature | VFR | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | New | High | Tính năng xuất excel của từng chart | download-img-excel |
| `[W]` | FEAT-016 | Tiến độ xuất hàng (204)#16 | Feature | OrderMonitoring | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Pending | Med | Sort + Search ở report | sort-search-report |
| `[-]` | FEAT-017 | %Stock Type (214)#11 | Feature | Inventory | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | New | High | Tính năng download hình ảnh, excel | download-img-excel |
| `[-]` | FEAT-018 | %Stock Type (214)#16 | Feature | Inventory | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | New | Med | Sort + Search ở report | sort-search-report |
| `[W]` | FEAT-019 | Movement transaction (214)#16 | Feature | TransactionMove | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Pending | Med | Sort + Search ở report | sort-search-report |
| `[W]` | FEAT-020 | %Utilization (224)#16 | Feature | Warehouse | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Pending | Med | Sort + Search ở report | sort-search-report |
| `[W]` | FEAT-021 | VFR (224)#7 | Feature | VFR | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | Đang fixing | High | Tính năng download hình ảnh, excel | download-img-excel |
| `[-]` | FEAT-022 | %Loose picking (234)#11 | Feature | Warehouse | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | New | High | Tính năng download hình ảnh, excel | download-img-excel |
| `[-]` | FEAT-023 | %Loose picking (234)#16 | Feature | Warehouse | `frontend-widget` | `dev-fe` | Minor |  | 9.0 | New | Med | Sort + Search ở report | sort-search-report |
| `[-]` | FEAT-024 | Sheet7# | Feature | Other | `cross-stack` | `mixed` | Low/Cosmetic |  | 9.0 | New | High | tính năng config thay đổi tên field report |  |
| `[W]` | UX-025 | Tỷ lệ đáp ứng và tuân thủ#10 | UX | VFR | `cross-stack` | `mixed` | — |  | 9.0 | Đang fixing | Med | Bảng dữ liệu detail | detail-table |
| `[-]` | UX-026 | Cảnh báo đơn trễ (204)#21 | UX | OrderMonitoring | `backend-config` | `dev-be` | — |  | 9.0 | New | Med | Bảng dữ liệu chi tiết | detail-table |
| `[-]` | UX-027 | Cảnh báo đơn trễ (204)#22 | UX | OrderMonitoring | `cross-stack` | `mixed` | — |  | 9.0 | New | Med | Bảng dữ liệu chi tiết | detail-table |
| `[-]` | UX-028 | %Stock Type (214)#19 | UX | Inventory | `frontend-config` | `dev-fe` | — |  | 9.0 | New | High | Đổi tên scorecard | rename-scorecard |
| `[-]` | UX-029 | Tỷ lệ Đáp ứng & Tuân thủ (234)#9 | UX | VFR | `frontend-config` | `dev-fe` | — |  | 9.0 | New | High | Bộ lọc "Khoảng thời gian" |  |
| `[W]` | UX-030 | Sheet7#23 | UX | Other | `frontend-widget` | `dev-fe` | — |  | 9.0 | SLG đã nhận yêu cầu | High | Thêm dấu phẩy phân cách hàng nghìn đối với các car | value-thousand-sep |
| `[W]` | UX-031 | Sheet7#25 | UX | Other | `frontend-widget` | `dev-fe` | — |  | 9.0 | SLG đã nhận yêu cầu | High | Chỉnh lại màu của Partial bins, đang bị trùng với  |  |
| `[-]` | UX-032 | Sheet7#54 | UX | TransactionMove | `frontend-config` | `dev-fe` | — |  | 9.0 | New | High | Đổi tên scorecard  - Tổng Pallet Nhập => Tổng Volu | rename-scorecard |
| `[-]` | BUG-033 | VFR (224)#3 | Bug | VFR | `cross-stack` | `mixed` | Minor | Sev3 | 5.4 | New | Med | Nội dung Bảng dữ liệu chi tiết | detail-table |
| `[-]` | FEAT-034 | Cảnh báo đơn trễ (204)#20 | Feature | OrderMonitoring | `cross-stack` | `mixed` | Major |  | 5.4 | New | High | Nội dung Bảng dữ liệu chi tiết | detail-table |
| `[-]` | UX-035 | %Stock Type (214)#20 | UX | Inventory | `cross-stack` | `mixed` | — |  | 5.4 | New | Med | Nội dung Bảng dữ liệu chi tiết | detail-table |
| `[-]` | BUG-036 | Tỷ lệ Đáp ứng & Tuân thủ (234)#4 | Bug | VFR | `frontend-config` | `dev-fe` | Major | Sev2 | 5.0 | New | High | Dòng chú thích của card view " Tỷ lệ đáp ứng chuyế |  |
| `[-]` | BUG-037 | Tỷ lệ Đáp ứng & Tuân thủ (234)#7 | Bug | VFR | `backend-config` | `dev-be` | Major | Sev2 | 5.0 | New | High | Param {{pickup_warehouse}} |  |
| `[-]` | BUG-038 | Sheet7# | Bug | Other | `etl-data` | `da` | Major | Sev2 | 5.0 | New | High | Số total position NKD là 3559, số hiển thị chưa kh |  |
| `[-]` | BUG-039 | Tỷ lệ Đáp ứng & Tuân thủ (234)#14 | Bug | VFR | `frontend-config` | `dev-fe` | Major | Sev2 | 3.0 | New | High | Layout view "Tỷ lệ tuân thủ vận hành" |  |
| `[-]` | BUG-040 | Sheet7# | Bug | FlashDaily | `frontend-widget` | `dev-fe` | Minor | Sev3 | 3.0 | New | High | Bộ lọc Kho: giá trị BKD, NKD chưa work đúng  - BKD |  |
| `[-]` | BUG-041 | Sheet7#47 | Bug | Inventory | `etl-data` | `da` | Major | Sev2 | 3.0 | New | High | Số liệu chưa realtime và chưa đúng với 3PL record  |  |
| `[X]` | DUP-042 | VFR#22 | Duplicate | VFR | `frontend-config` | `closed` | — |  | 3.0 | trùng hả c | High | VFR gửi thầu theo Khu vực VFR gửi thầu theo loại x |  |
| `[W]` | FEAT-043 | Tỷ lệ đáp ứng và tuân thủ#21 | Feature | VFR | `frontend-config` | `dev-fe` | Minor |  | 3.0 | Fix lại | Med | Card "Tổng số điểm vận hành" |  |
| `[-]` | FEAT-044 | %Stock Type (214)#10 | Feature | Inventory | `frontend-widget` | `dev-fe` | Minor |  | 3.0 | New | Med | Nút Apply filters, Reset filter | apply-reset-button |
| `[-]` | FEAT-045 | Tỷ lệ Đáp ứng & Tuân thủ (234)#3 | Feature | VFR | `frontend-widget` | `dev-fe` | Minor |  | 3.0 | New | High | Bộ lọc |  |
| `[-]` | FEAT-046 | Tỷ lệ Đáp ứng & Tuân thủ (234)#5 | Feature | VFR | `frontend-config` | `dev-fe` | Minor |  | 3.0 | New | High | Chart "Tỷ lệ đáp ứng theo thời gian" |  |
| `[-]` | FEAT-047 | Tỷ lệ Đáp ứng & Tuân thủ (234)#11 | Feature | VFR | `frontend-config` | `dev-fe` | Minor |  | 3.0 | New | High | Card "Tỷ lệ tuân thủ" |  |
| `[-]` | FEAT-048 | %Loose picking (234)#10 | Feature | Warehouse | `frontend-widget` | `dev-fe` | Minor |  | 3.0 | New | Med | Nút Apply filters, Reset filter | apply-reset-button |
| `[W]` | FEAT-049 | Sheet7#1 | Feature | FlashDaily | `frontend-widget` | `dev-fe` | Low/Cosmetic |  | 3.0 | In-dev | High | Thêm icon ? giải thích source, logic tính toán |  |
| `[-]` | FEAT-050 | Sheet7#27 | Feature | Other | `cross-stack` | `mixed` | Minor |  | 3.0 | New | High | thêm fillter: trung chuyển trong, trung chuyển ngo |  |
| `[-]` | FEAT-051 | Sheet7# | Feature | Other | `unknown` | `mixed` | Minor |  | 3.0 | New | High | thêm customer, region. Filter xổ chọn |  |
| `[-]` | FEAT-052 | Sheet7#48 | Feature | Inventory | `cross-stack` | `mixed` | Major |  | 3.0 | New | High | bổ sung thêm stock type theo shelflife |  |
| `[-]` | FEAT-053 | Sheet7# | Feature | TransactionMove | `cross-stack` | `mixed` | Major |  | 3.0 | New | High | thêm chart liên quan tới transaction |  |
| `[-]` | FEAT-054 | Sheet7# | Feature | TransactionMove | `etl-data` | `da` | Major |  | 3.0 | New | High | combine data  xuất từ kho này qua kho kia , kho tr |  |
| `[-]` | FEAT-055 | Sheet7# | Feature | TransactionMove | `cross-stack` | `mixed` | Minor |  | 3.0 | New | High | thêm intotal xuất bán , ... |  |
| `[-]` | FEAT-056 | Sheet7#62 | Feature | Other | `cross-stack` | `mixed` | Minor |  | 3.0 | New | High | Thêm filter thời gian |  |
| `[-]` | FEAT-057 | Sheet7#66 | Feature | Other | `cross-stack` | `mixed` | Major |  | 3.0 | New | High | bổ sung lý do rớt là gồm cả 2 () |  |
| `[W]` | FEAT-058 | Sheet7#74 | Feature | OrderMonitoring | `frontend-config` | `dev-fe` | Minor |  | 3.0 | In-dev | High | Scorecard: bổ sung % góc phải |  |
| `[W]` | FEAT-059 | Sheet7#75 | Feature | OrderMonitoring | `frontend-widget` | `dev-fe` | Minor |  | 3.0 | In-dev | High | Switch filter: day/week/month |  |
| `[W]` | FEAT-060 | Sheet7# | Feature | OrderMonitoring | `cross-stack` | `mixed` | Major |  | 3.0 | In-dev | High | Phân quyền data: theo kho (ưu tiên sau) |  |
| `[-]` | FEAT-061 | Sheet7# | Feature | OrderMonitoring | `cross-stack` | `mixed` | Major |  | 3.0 | New | High | phân quyền nhập số |  |
| `[-]` | FEAT-062 | Sheet7# | Feature | OrderMonitoring | `cross-stack` | `mixed` | Major |  | 3.0 | New | High | thêm nhập số thay vì set cứng thì cho nhập số sett |  |
| `[W]` | UX-063 | VFR#10 | UX | VFR | `unknown` | `mixed` | — |  | 3.0 | Fix lại | High | VFR gửi thầu theo thời gian và khu vực |  |
| `[-]` | UX-064 | Tỷ lệ đáp ứng và tuân thủ#20 | UX | VFR | `frontend-config` | `dev-fe` | — |  | 3.0 |  | Med | Card "Tổng số chuyến vận hành" |  |
| `[-]` | UX-065 | Tỷ lệ đáp ứng và tuân thủ#22 | UX | VFR | `frontend-config` | `dev-fe` | — |  | 3.0 |  | Med | Card "Tỷ lệ tuân thủ |  |
| `[-]` | UX-066 | Tỷ lệ đáp ứng và tuân thủ#23 | UX | VFR | `frontend-config` | `dev-fe` | — |  | 3.0 |  | Med | Chart "Tỷ lệ tuân thủ theo nhà vận tải" |  |
| `[-]` | UX-067 | OTIF (204)#19 | UX | OrderMonitoring | `frontend-config` | `dev-fe` | — |  | 3.0 | New | Med | Bảng %OTIF chiều vận hành |  |
| `[-]` | UX-068 | %Stock Type (214)#2 | UX | Inventory | `frontend-widget` | `dev-fe` | — |  | 3.0 | New | Med | Bộ lọc | filter-fixed-scorecard |
| `[-]` | UX-069 | %Stock Type (214)#4 | UX | Inventory | `frontend-widget` | `dev-fe` | — |  | 3.0 | New | Med | Bộ lọc |  |
| `[-]` | UX-070 | %Stock Type (214)#9 | UX | Inventory | `frontend-widget` | `dev-fe` | — |  | 3.0 | New | Med | Bộ lọc "Khoảng thời gian" |  |
| `[-]` | UX-071 | %Stock Type (214)#12 | UX | Inventory | `frontend-config` | `dev-fe` | — |  | 3.0 | New | High | Vị trí thanh Biểu đồ, Chi tiết bảng |  |
| `[-]` | UX-072 | %Stock Type (214)#21 | UX | Inventory | `cross-stack` | `mixed` | — |  | 3.0 | New | Med | Nội dung Bảng dữ liệu pivot |  |
| `[-]` | UX-073 | Tỷ lệ Đáp ứng & Tuân thủ (234)#8 | UX | VFR | `frontend-widget` | `dev-fe` | — |  | 3.0 | New | Med | Các bộ lọc còn lại trừ bộ lọc "Khoảng thời gian" |  |
| `[-]` | UX-074 | Tỷ lệ Đáp ứng & Tuân thủ (234)#10 | UX | VFR | `frontend-config` | `dev-fe` | — |  | 3.0 | New | Med | Card view "Tỷ lệ tuân thủ vận hành" |  |
| `[-]` | UX-075 | Tỷ lệ Đáp ứng & Tuân thủ (234)#12 | UX | VFR | `frontend-config` | `dev-fe` | — |  | 3.0 | New | Med | Chart "Tỷ lệ tuân thủ theo ngày" |  |
| `[-]` | UX-076 | %Loose picking (234)#2 | UX | Warehouse | `frontend-widget` | `dev-fe` | — |  | 3.0 | New | Med | Bộ lọc | filter-fixed-scorecard |
| `[-]` | UX-077 | %Loose picking (234)#4 | UX | Warehouse | `frontend-widget` | `dev-fe` | — |  | 3.0 | New | Med | Bộ lọc |  |
| `[-]` | UX-078 | %Loose picking (234)#9 | UX | Warehouse | `frontend-widget` | `dev-fe` | — |  | 3.0 | New | Med | Bộ lọc "Khoảng thời gian" |  |
| `[-]` | UX-079 | %Loose picking (234)#12 | UX | Warehouse | `frontend-config` | `dev-fe` | — |  | 3.0 | New | High | Vị trí thanh Biểu đồ, Chi tiết bảng |  |
| `[W]` | UX-080 | Sheet7#2 | UX | FlashDaily | `frontend-config` | `dev-fe` | — |  | 3.0 | In-dev | Med | Scorecard "Tổng volume" thành "Tổng volume kế hoạc |  |
| `[-]` | UX-081 | Sheet7# | UX | FlashDaily | `unknown` | `mixed` | — |  | 3.0 | New | Med | filter multiple choice -> bkd -> bkd 1,2,3  nkd -> |  |
| `[-]` | UX-082 | Sheet7# | UX | FlashDaily | `unknown` | `mixed` | — |  | 3.0 | New | Med | bị vấn đề cái flow logic bị thiếu, ko chặt chẽ với |  |
| `[W]` | UX-083 | Sheet7#26 | UX | Other | `unknown` | `mixed` | — |  | 3.0 | SLG đã nhận yêu cầu | Med | Chỉnh sửa option filter warehouse: BKD, external B |  |
| `[-]` | UX-084 | Sheet7#28 | UX | TransactionMove | `unknown` | `mixed` | — |  | 3.0 | New | Med | chuyển copack, trung chuyển , nhập từ xưởng vô tra |  |
| `[-]` | UX-085 | Sheet7#29 | UX | Other | `unknown` | `mixed` | — |  | 3.0 | New | Med | 2 p: historical, daily |  |
| `[-]` | UX-086 | Sheet7# | UX | Other | `unknown` | `mixed` | — |  | 3.0 | New | Med | cho tính theo palet |  |
| `[-]` | UX-087 | Sheet7# | UX | Inventory | `cross-stack` | `mixed` | — |  | 3.0 | New | Med | stock category để identify |  |
| `[-]` | UX-088 | Sheet7#53 | UX | TransactionMove | `frontend-config` | `dev-fe` | — |  | 3.0 | New | Med | Bỏ scorecard Movement Rows |  |
| `[-]` | UX-089 | Sheet7#67 | UX | VFR | `unknown` | `mixed` | — |  | 3.0 | New | Med | Chỉnh sửa filter Kho lấy hàng: BKD, NKD, Kho ngoài |  |
| `[W]` | UX-090 | Sheet7#72 | UX | OrderMonitoring | `frontend-config` | `dev-fe` | — |  | 3.0 | In-dev | Med | Scorecard chia 3 block: rời kho, trên đường giao,  |  |
| `[W]` | UX-091 | Sheet7# | UX | OrderMonitoring | `frontend-config` | `dev-fe` | — |  | 3.0 | In-dev | High | Report: sort ưu tiên chuyến trễ và nguy cơ trễ   + |  |
| `[-]` | UX-092 | Sheet7# | UX | OrderMonitoring | `cross-stack` | `mixed` | — |  | 3.0 | New | Med | thêm nhập số thay vì 45p thì cho nhập số setting t |  |
| `[-]` | UX-093 | Sheet7# | UX | OrderMonitoring | `frontend-config` | `dev-fe` | — |  | 3.0 | New | Med | chart: phân ra nguyên nhân fail ontime: phóng to t |  |
| `[-]` | UX-094 | Sheet7# | UX | OrderMonitoring | `unknown` | `mixed` | — |  | 3.0 | New | Med | đưa các chuyến có nguy cơ trễ lên trước |  |
| `[-]` | UX-095 | Sheet7# | UX | OrderMonitoring | `unknown` | `mixed` | — |  | 3.0 | New | Med | kích tổng số chuyển ra khỏi ngoài, cho tiêu đề inp |  |
| `[-]` | UX-096 | Sheet7# | UX | OrderMonitoring | `unknown` | `mixed` | — |  | 3.0 | New | Med | sửa lại lý do trễ tiếng việt -> tiếng anh |  |
| `[-]` | UX-097 | Sheet7# | UX | OrderMonitoring | `cross-stack` | `mixed` | — |  | 3.0 | New | Med | Logic: cảnh báo theo từng điểm giao |  |
| `[W]` | UX-098 | Sheet7#95 | UX | VFR | `unknown` | `mixed` | — |  | 3.0 | In-dev | Med | Visualization:  - Thêm ô điền TG manual input  - T |  |
| `[X]` | DUP-099 | VFR#16 | Duplicate | VFR | `backend-config` | `closed` | — |  | 1.8 | sao lại dùng bộ lọc riêng ?? | High | Bộ lọc "Kho lấy hàng" | multi-select-filter |
| `[X]` | DUP-100 | VFR#17 | Duplicate | VFR | `backend-config` | `closed` | — |  | 1.8 | sao lại dùng bộ lọc riêng ?? | High | Bộ lọc "Điểm giao hàng" | multi-select-filter |
| `[X]` | DUP-101 | VFR#18 | Duplicate | VFR | `backend-config` | `closed` | — |  | 1.8 | sao lại dùng bộ lọc riêng ?? | High | Bộ lọc "Khu vực giao hàng" | multi-select-filter |
| `[X]` | DUP-102 | VFR#19 | Duplicate | VFR | `backend-config` | `closed` | — |  | 1.8 | sao lại dùng bộ lọc riêng ?? | High | Bộ lọc "Nhà vận tải" | multi-select-filter |
| `[X]` | DUP-103 | VFR#20 | Duplicate | VFR | `backend-config` | `closed` | — |  | 1.8 | sao lại dùng bộ lọc riêng ?? | High | Bộ lọc "Loại xe gửi thầu" | multi-select-filter |
| `[-]` | FEAT-104 | Cảnh báo đơn trễ (204)#13 | Feature | OrderMonitoring | `cross-stack` | `mixed` | Minor |  | 1.8 | New | Med | Chart time series |  |
| `[-]` | FEAT-105 | %Stock Type (214)#13 | Feature | Inventory | `cross-stack` | `mixed` | Minor |  | 1.8 | New | Med | Chart time series |  |
| `[-]` | FEAT-106 | %Utilization (224)#13 | Feature | Warehouse | `cross-stack` | `mixed` | Minor |  | 1.8 | New | Med | Chart time series |  |
| `[-]` | FEAT-107 | %Loose picking (234)#13 | Feature | Warehouse | `cross-stack` | `mixed` | Minor |  | 1.8 | New | Med | Chart time series |  |
| `[X]` | OOS-108 | VFR#3 | Out-of-scope | VFR | `backend-config` | `closed` | — |  | 1.8 | BỎ | High | Bộ lọc "Điểm giao hàng" | multi-select-filter |
| `[-]` | UX-109 | Tiến độ xuất hàng (204)#18 | UX | OrderMonitoring | `frontend-config` | `dev-fe` | — |  | 1.8 | New | High | Relayout scorecard |  |
| `[-]` | UX-110 | %Stock Type (214)#5 | UX | Inventory | `frontend-widget` | `dev-fe` | — |  | 1.8 | New | Med | Bộ lọc "Kho" |  |
| `[-]` | UX-111 | %Stock Type (214)#6 | UX | Inventory | `frontend-widget` | `dev-fe` | — |  | 1.8 | New | Med | Bộ lọc "Khu vực giao hàng" |  |
| `[-]` | UX-112 | %Stock Type (214)#7 | UX | Inventory | `frontend-widget` | `dev-fe` | — |  | 1.8 | New | Med | Bộ lọc "Kênh bán hàng" |  |
| `[-]` | UX-113 | %Stock Type (214)#8 | UX | Inventory | `frontend-widget` | `dev-fe` | — |  | 1.8 | New | Med | Bộ lọc "Nhà vận tải" |  |
| `[-]` | UX-114 | %Stock Type (214)#14 | UX | Inventory | `cross-stack` | `mixed` | — |  | 1.8 | New | Med | Chart time series |  |
| `[-]` | UX-115 | %Stock Type (214)#18 | UX | Inventory | `frontend-config` | `dev-fe` | — |  | 1.8 | New | High | Relayout scorecard |  |
| `[-]` | UX-116 | %Utilization (224)#14 | UX | Warehouse | `cross-stack` | `mixed` | — |  | 1.8 | New | Med | Chart time series |  |
| `[-]` | UX-117 | Tỷ lệ Đáp ứng & Tuân thủ (234)#2 | UX | VFR | `frontend-config` | `dev-fe` | — |  | 1.8 | New | High | Bố cục của view |  |
| `[-]` | UX-118 | Tỷ lệ Đáp ứng & Tuân thủ (234)#6 | UX | VFR | `unknown` | `mixed` | — |  | 1.8 | New | Med | Report "Dữ liệu chi tiết tỷ lệ đáp ứng gửi thầu" |  |
| `[-]` | UX-119 | Tỷ lệ Đáp ứng & Tuân thủ (234)#13 | UX | VFR | `unknown` | `mixed` | — |  | 1.8 | New | Med | Report "Dữ liệu chi tiết tỷ lệ tuân thủ vận hành" |  |
| `[-]` | UX-120 | %Loose picking (234)#5 | UX | Warehouse | `frontend-widget` | `dev-fe` | — |  | 1.8 | New | Med | Bộ lọc "Kho" |  |
| `[-]` | UX-121 | %Loose picking (234)#6 | UX | Warehouse | `frontend-widget` | `dev-fe` | — |  | 1.8 | New | Med | Bộ lọc "Khu vực giao hàng" |  |
| `[-]` | UX-122 | %Loose picking (234)#7 | UX | Warehouse | `frontend-widget` | `dev-fe` | — |  | 1.8 | New | Med | Bộ lọc "Kênh bán hàng" |  |
| `[-]` | UX-123 | %Loose picking (234)#8 | UX | Warehouse | `frontend-widget` | `dev-fe` | — |  | 1.8 | New | Med | Bộ lọc "Nhà vận tải" |  |
| `[-]` | UX-124 | %Loose picking (234)#14 | UX | Warehouse | `cross-stack` | `mixed` | — |  | 1.8 | New | Med | Chart time series |  |
| `[W]` | FEAT-125 | Sheet7#3 | Feature | FlashDaily | `cross-stack` | `mixed` | Major |  | 1.7 | In-dev | High | Bổ sung report tỷ lệ hoàn thành |  |
| `[-]` | FEAT-126 | Sheet7# | Feature | TransactionMove | `cross-stack` | `mixed` | Major |  | 1.7 | New | High | Bổ sung report Movement Transaction |  |
| `[W]` | FEAT-127 | Sheet7#94 | Feature | VFR | `cross-stack` | `mixed` | Major |  | 1.7 | In-dev | High | Thêm 1 view insight về vận chuyển & tính tuân thủ  |  |
| `[X]` | DUP-128 | VFR#13 | Duplicate | VFR | `frontend-widget` | `closed` | — |  | 1.0 | sao lại dùng bộ lọc riêng ?? | High | Bộ lọc |  |
| `[X]` | DUP-129 | VFR#21 | Duplicate | VFR | `frontend-widget` | `closed` | — |  | 1.0 | sao lại dùng bộ lọc riêng ?? | High | Bộ lọc "Loại ngày" | filter-values-from-sql |
| `[X]` | DUP-130 | VFR#23 | Duplicate | VFR | `unknown` | `closed` | — |  | 1.0 | trùng hả c | High | VFR gửi thầu theo loại bốc xếp |  |
| `[X]` | DUP-131 | VFR#24 | Duplicate | VFR | `unknown` | `closed` | — |  | 1.0 | trùng hả c | High | VFR gửi thầu theo thời gian và khu vực |  |
| `[X]` | DUP-132 | Tỷ lệ đáp ứng và tuân thủ#12 | Duplicate | VFR | `frontend-widget` | `closed` | — |  | 1.0 | sao lại dùng bộ lọc riêng ?? | High | Bộ lọc |  |
| `[X]` | DUP-133 | Tỷ lệ đáp ứng và tuân thủ#15 | Duplicate | VFR | `frontend-config` | `closed` | — |  | 1.0 | sao lại dùng bộ lọc riêng ?? | High | Bộ lọc "Mã điểm" |  |
| `[X]` | DUP-134 | Tỷ lệ đáp ứng và tuân thủ#16 | Duplicate | VFR | `frontend-widget` | `closed` | — |  | 1.0 | sao lại dùng bộ lọc riêng ?? | High | Bộ lọc "Loại điểm" |  |
| `[X]` | DUP-135 | Tỷ lệ đáp ứng và tuân thủ#17 | Duplicate | VFR | `frontend-widget` | `closed` | — |  | 1.0 | sao lại dùng bộ lọc riêng ?? | High | Bộ lọc "Nhà vận tải" |  |
| `[X]` | DUP-136 | Tỷ lệ đáp ứng và tuân thủ#18 | Duplicate | VFR | `frontend-widget` | `closed` | — |  | 1.0 | sao lại dùng bộ lọc riêng ?? | High | Bộ lọc "Loại ngày" |  |
| `[X]` | DUP-137 | Tỷ lệ đáp ứng và tuân thủ#19 | Duplicate | VFR | `frontend-widget` | `closed` | — |  | 1.0 | sao lại dùng bộ lọc riêng ?? | High | Bộ lọc "Khoảng thời gian" |  |
| `[X]` | OOS-138 | Tỷ lệ đáp ứng và tuân thủ#3 | Out-of-scope | VFR | `frontend-widget` | `closed` | — |  | 1.0 | BỎ | High | Bộ lọc "Điểm giao hàng" |  |
| `[Q]` | Q-139 | Sheet7# | Question | FlashDaily | `cross-stack` | `cs` | — |  | 1.0 | New | Med | ở report hàng rớt: thêm fillter by , lăng kinh khá |  |
| `[W]` | UX-140 | Sheet7#22 | UX | FlashDaily | `etl-data` | `da` | — |  | 1.0 | In-doing | Med | Update lại TOBE visualization, công thức tính toán |  |


</details>

## Anti-patterns avoided trong triage này

1. **Severity inflation**: KHÔNG markup tất cả thành Sev1 dù khách dùng từ "cần fix gấp". Sev1 yêu cầu block không workaround. Đa số items là Sev2 (filter sai value, layout sai) — có workaround tệ.
2. **Bug vs Feature confusion**: "Chưa có tính năng download excel" KHÔNG phải bug — là Feature request (capability missing). "Filter chỉ cho phép chọn 1 giá trị" được khách spec là single-option ban đầu nhưng giờ muốn multi → UX issue (PRD gap), không phải bug.
3. **Per-view stub explosion**: 15 occurrences của "multi-select filter" gộp thành 1 platform stub — dev implement 1 lần, không phải 15 lần.
4. **Discussion noise**: Status `sao lại dùng bộ lọc riêng ??` là conversation thread giữa team & khách — đã được khách trả lời "đổi sang dùng chung nha" → marked Duplicate (resolved), không generate stub.
5. **Effort estimation caveat**: Effort score (1/3/5/9) là BA-rough cho prioritization, KHÔNG phải dev sprint estimate. Dev cần re-estimate khi pickup.

## Re-triage policy

Triage này là **living document**. Khi:
- Khách MDLZ gửi feedback bổ sung trên cùng file → re-run với cùng `BASE` (append, không tạo folder mới)
- Có item resolved trong session sau → mark `Resolved-{date}` ở backlog table
- Discovery/PRD revision đổi classification → update stub + ghi history
