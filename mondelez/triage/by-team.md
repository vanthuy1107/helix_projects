# Triage Backlog — by Owner Team

Index alternative cho [`backlog.md`](backlog.md) — group theo team chịu trách nhiệm thay vì sort theo priority. Cùng dữ liệu, view khác.

**Use this when**: PM cần biết "team X có bao nhiêu items, items nào phải xử lý". Để xem priority overall, dùng `backlog.md`.

**Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — 2026-05-09

## Team breakdown

| Team | Count | Description |
|---|---|---|
| `da` | 4 | Data Analyst (SQL views, ETL) |
| `dev-be` | 9 | Backend Developer (.NET, EF Core, Dynamic Query) |
| `dev-fe` | 63 | Frontend Developer (React 19, Shadcn, Recharts) |
| `mixed` | 45 | Multiple teams — needs coordination |
| `cs` | 1 | Customer Success — answer & close |
| `closed` | 18 | Closed (Duplicate / Out-of-scope) |

## Items by team

### `da` — Data Analyst (SQL views, ETL) (4 items)

| Status | Triage ID | Source | Type | Tech layer | Priority | Sev | Score | Title | Stub |
|---|---|---|---|---|---|---|---|---|---|
| `[-]` | BUG-038 | Sheet7# | Bug | `etl-data` | Major | Sev2 | 5.0 | Số total position NKD là 3559, số hiển thị chưa kh | [bugs/etl-data/[-]-BUG-038-other-so-total-position-nkd-la-3559-so-hien-th.md](bugs/etl-data/%5B-%5D-BUG-038-other-so-total-position-nkd-la-3559-so-hien-th.md) |
| `[-]` | BUG-041 | Sheet7#47 | Bug | `etl-data` | Major | Sev2 | 3.0 | Số liệu chưa realtime và chưa đúng với 3PL record  | [bugs/etl-data/[-]-BUG-041-inventory-so-lieu-chua-realtime-va-chua-dung-voi-3.md](bugs/etl-data/%5B-%5D-BUG-041-inventory-so-lieu-chua-realtime-va-chua-dung-voi-3.md) |
| `[-]` | FEAT-054 | Sheet7# | Feature | `etl-data` | Major |  | 3.0 | combine data  xuất từ kho này qua kho kia , kho tr | [discoveries/etl-data/[-]-FEAT-054-transactionmove-combine-data-xuat-tu-kho-nay-qua-kho-kia.md](discoveries/etl-data/%5B-%5D-FEAT-054-transactionmove-combine-data-xuat-tu-kho-nay-qua-kho-kia.md) |
| `[W]` | UX-140 | Sheet7#22 | UX | `etl-data` | — |  | 1.0 | Update lại TOBE visualization, công thức tính toán | — (no stub) |

### `dev-be` — Backend Developer (.NET, EF Core, Dynamic Query) (9 items)

| Status | Triage ID | Source | Type | Tech layer | Priority | Sev | Score | Title | Stub |
|---|---|---|---|---|---|---|---|---|---|
| `[W]` | BUG-007 | VFR#2 | Bug | `backend-config` | Major | Sev2 | 9.0 | Bộ lọc "Kho lấy hàng" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[W]` | BUG-008 | VFR#4 | Bug | `backend-config` | Major | Sev2 | 9.0 | Bộ lọc "Khu vực giao hàng" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[W]` | BUG-009 | VFR#5 | Bug | `backend-config` | Major | Sev2 | 9.0 | Bộ lọc "Nhà vận tải" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[W]` | BUG-010 | VFR#6 | Bug | `backend-config` | Major | Sev2 | 9.0 | Bộ lọc "Loại xe gửi thầu" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[W]` | BUG-011 | Tỷ lệ đáp ứng và tuân thủ#2 | Bug | `backend-config` | Major | Sev2 | 9.0 | Bộ lọc "Kho lấy hàng" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[W]` | BUG-012 | Tỷ lệ đáp ứng và tuân thủ#4 | Bug | `backend-config` | Major | Sev2 | 9.0 | Bộ lọc "Khu vực giao hàng" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[W]` | BUG-013 | Tỷ lệ đáp ứng và tuân thủ#5 | Bug | `backend-config` | Major | Sev2 | 9.0 | Bộ lọc "Nhà vận tải" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[-]` | UX-026 | Cảnh báo đơn trễ (204)#21 | UX | `backend-config` | — |  | 9.0 | Bảng dữ liệu chi tiết | [prd-asks/backend-config/[-]-UX-026-ordermonitoring-bang-du-lieu-chi-tiet.md](prd-asks/backend-config/%5B-%5D-UX-026-ordermonitoring-bang-du-lieu-chi-tiet.md) |
| `[-]` | BUG-037 | Tỷ lệ Đáp ứng & Tuân thủ (234)#7 | Bug | `backend-config` | Major | Sev2 | 5.0 | Param {{pickup_warehouse}} | [bugs/backend-config/[-]-BUG-037-vfr-param-pickup-warehouse.md](bugs/backend-config/%5B-%5D-BUG-037-vfr-param-pickup-warehouse.md) |

### `dev-fe` — Frontend Developer (React 19, Shadcn, Recharts) (63 items)

| Status | Triage ID | Source | Type | Tech layer | Priority | Sev | Score | Title | Stub |
|---|---|---|---|---|---|---|---|---|---|
| `[-]` | UX-002 | Cảnh báo đơn trễ (204)#15 | UX | `frontend-widget` | — |  | 15.0 | Show số liệu lên chart | [_platform/prd-asks/[-]-PLATFORM-SHOW-VALUE-ON-CHART.md](_platform/prd-asks/%5B-%5D-PLATFORM-SHOW-VALUE-ON-CHART.md) |
| `[-]` | UX-003 | %Stock Type (214)#3 | UX | `frontend-widget` | — |  | 15.0 | Bộ lọc | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[-]` | UX-004 | %Stock Type (214)#15 | UX | `frontend-widget` | — |  | 15.0 | Show số liệu lên chart | [_platform/prd-asks/[-]-PLATFORM-SHOW-VALUE-ON-CHART.md](_platform/prd-asks/%5B-%5D-PLATFORM-SHOW-VALUE-ON-CHART.md) |
| `[-]` | UX-005 | %Loose picking (234)#3 | UX | `frontend-widget` | — |  | 15.0 | Bộ lọc | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[-]` | UX-006 | %Loose picking (234)#15 | UX | `frontend-widget` | — |  | 15.0 | Show số liệu lên chart | [_platform/prd-asks/[-]-PLATFORM-SHOW-VALUE-ON-CHART.md](_platform/prd-asks/%5B-%5D-PLATFORM-SHOW-VALUE-ON-CHART.md) |
| `[-]` | FEAT-014 | VFR#14 | Feature | `frontend-widget` | Minor |  | 9.0 | Tính năng xuất excel của từng chart | [_platform/discoveries/[-]-PLATFORM-DOWNLOAD-IMG-EXCEL.md](_platform/discoveries/%5B-%5D-PLATFORM-DOWNLOAD-IMG-EXCEL.md) |
| `[-]` | FEAT-015 | Tỷ lệ đáp ứng và tuân thủ#13 | Feature | `frontend-widget` | Minor |  | 9.0 | Tính năng xuất excel của từng chart | [_platform/discoveries/[-]-PLATFORM-DOWNLOAD-IMG-EXCEL.md](_platform/discoveries/%5B-%5D-PLATFORM-DOWNLOAD-IMG-EXCEL.md) |
| `[W]` | FEAT-016 | Tiến độ xuất hàng (204)#16 | Feature | `frontend-widget` | Minor |  | 9.0 | Sort + Search ở report | [_platform/discoveries/[W]-PLATFORM-SORT-SEARCH-REPORT.md](_platform/discoveries/%5BW%5D-PLATFORM-SORT-SEARCH-REPORT.md) |
| `[-]` | FEAT-017 | %Stock Type (214)#11 | Feature | `frontend-widget` | Minor |  | 9.0 | Tính năng download hình ảnh, excel | [_platform/discoveries/[-]-PLATFORM-DOWNLOAD-IMG-EXCEL.md](_platform/discoveries/%5B-%5D-PLATFORM-DOWNLOAD-IMG-EXCEL.md) |
| `[-]` | FEAT-018 | %Stock Type (214)#16 | Feature | `frontend-widget` | Minor |  | 9.0 | Sort + Search ở report | [_platform/discoveries/[W]-PLATFORM-SORT-SEARCH-REPORT.md](_platform/discoveries/%5BW%5D-PLATFORM-SORT-SEARCH-REPORT.md) |
| `[W]` | FEAT-019 | Movement transaction (214)#16 | Feature | `frontend-widget` | Minor |  | 9.0 | Sort + Search ở report | [_platform/discoveries/[W]-PLATFORM-SORT-SEARCH-REPORT.md](_platform/discoveries/%5BW%5D-PLATFORM-SORT-SEARCH-REPORT.md) |
| `[W]` | FEAT-020 | %Utilization (224)#16 | Feature | `frontend-widget` | Minor |  | 9.0 | Sort + Search ở report | [_platform/discoveries/[W]-PLATFORM-SORT-SEARCH-REPORT.md](_platform/discoveries/%5BW%5D-PLATFORM-SORT-SEARCH-REPORT.md) |
| `[W]` | FEAT-021 | VFR (224)#7 | Feature | `frontend-widget` | Minor |  | 9.0 | Tính năng download hình ảnh, excel | [_platform/discoveries/[-]-PLATFORM-DOWNLOAD-IMG-EXCEL.md](_platform/discoveries/%5B-%5D-PLATFORM-DOWNLOAD-IMG-EXCEL.md) |
| `[-]` | FEAT-022 | %Loose picking (234)#11 | Feature | `frontend-widget` | Minor |  | 9.0 | Tính năng download hình ảnh, excel | [_platform/discoveries/[-]-PLATFORM-DOWNLOAD-IMG-EXCEL.md](_platform/discoveries/%5B-%5D-PLATFORM-DOWNLOAD-IMG-EXCEL.md) |
| `[-]` | FEAT-023 | %Loose picking (234)#16 | Feature | `frontend-widget` | Minor |  | 9.0 | Sort + Search ở report | [_platform/discoveries/[W]-PLATFORM-SORT-SEARCH-REPORT.md](_platform/discoveries/%5BW%5D-PLATFORM-SORT-SEARCH-REPORT.md) |
| `[-]` | UX-028 | %Stock Type (214)#19 | UX | `frontend-config` | — |  | 9.0 | Đổi tên scorecard | [_platform/prd-asks/[-]-PLATFORM-RENAME-SCORECARD.md](_platform/prd-asks/%5B-%5D-PLATFORM-RENAME-SCORECARD.md) |
| `[-]` | UX-029 | Tỷ lệ Đáp ứng & Tuân thủ (234)#9 | UX | `frontend-config` | — |  | 9.0 | Bộ lọc "Khoảng thời gian" | [prd-asks/frontend-config/[-]-UX-029-vfr-bo-loc-khoang-thoi-gian.md](prd-asks/frontend-config/%5B-%5D-UX-029-vfr-bo-loc-khoang-thoi-gian.md) |
| `[W]` | UX-030 | Sheet7#23 | UX | `frontend-widget` | — |  | 9.0 | Thêm dấu phẩy phân cách hàng nghìn đối với các car | [_platform/prd-asks/[W]-PLATFORM-VALUE-THOUSAND-SEP.md](_platform/prd-asks/%5BW%5D-PLATFORM-VALUE-THOUSAND-SEP.md) |
| `[W]` | UX-031 | Sheet7#25 | UX | `frontend-widget` | — |  | 9.0 | Chỉnh lại màu của Partial bins, đang bị trùng với  | [prd-asks/frontend-widget/[W]-UX-031-other-chinh-lai-mau-cua-partial-bins-dang-bi-t.md](prd-asks/frontend-widget/%5BW%5D-UX-031-other-chinh-lai-mau-cua-partial-bins-dang-bi-t.md) |
| `[-]` | UX-032 | Sheet7#54 | UX | `frontend-config` | — |  | 9.0 | Đổi tên scorecard  - Tổng Pallet Nhập => Tổng Volu | [_platform/prd-asks/[-]-PLATFORM-RENAME-SCORECARD.md](_platform/prd-asks/%5B-%5D-PLATFORM-RENAME-SCORECARD.md) |
| `[-]` | BUG-036 | Tỷ lệ Đáp ứng & Tuân thủ (234)#4 | Bug | `frontend-config` | Major | Sev2 | 5.0 | Dòng chú thích của card view " Tỷ lệ đáp ứng chuyế | [bugs/frontend-config/[-]-BUG-036-vfr-dong-chu-thich-cua-card-view-ty-le-dap-u.md](bugs/frontend-config/%5B-%5D-BUG-036-vfr-dong-chu-thich-cua-card-view-ty-le-dap-u.md) |
| `[-]` | BUG-039 | Tỷ lệ Đáp ứng & Tuân thủ (234)#14 | Bug | `frontend-config` | Major | Sev2 | 3.0 | Layout view "Tỷ lệ tuân thủ vận hành" | [bugs/frontend-config/[-]-BUG-039-vfr-layout-view-ty-le-tuan-thu-van-hanh.md](bugs/frontend-config/%5B-%5D-BUG-039-vfr-layout-view-ty-le-tuan-thu-van-hanh.md) |
| `[-]` | BUG-040 | Sheet7# | Bug | `frontend-widget` | Minor | Sev3 | 3.0 | Bộ lọc Kho: giá trị BKD, NKD chưa work đúng  - BKD | [bugs/frontend-widget/[-]-BUG-040-flashdaily-bo-loc-kho-gia-tri-bkd-nkd-chua-work-dun.md](bugs/frontend-widget/%5B-%5D-BUG-040-flashdaily-bo-loc-kho-gia-tri-bkd-nkd-chua-work-dun.md) |
| `[W]` | FEAT-043 | Tỷ lệ đáp ứng và tuân thủ#21 | Feature | `frontend-config` | Minor |  | 3.0 | Card "Tổng số điểm vận hành" | [discoveries/frontend-config/[W]-FEAT-043-vfr-card-tong-so-diem-van-hanh.md](discoveries/frontend-config/%5BW%5D-FEAT-043-vfr-card-tong-so-diem-van-hanh.md) |
| `[-]` | FEAT-044 | %Stock Type (214)#10 | Feature | `frontend-widget` | Minor |  | 3.0 | Nút Apply filters, Reset filter | [_platform/prd-asks/[-]-PLATFORM-APPLY-RESET-BUTTON.md](_platform/prd-asks/%5B-%5D-PLATFORM-APPLY-RESET-BUTTON.md) |
| `[-]` | FEAT-045 | Tỷ lệ Đáp ứng & Tuân thủ (234)#3 | Feature | `frontend-widget` | Minor |  | 3.0 | Bộ lọc | [discoveries/frontend-widget/[-]-FEAT-045-vfr-bo-loc.md](discoveries/frontend-widget/%5B-%5D-FEAT-045-vfr-bo-loc.md) |
| `[-]` | FEAT-046 | Tỷ lệ Đáp ứng & Tuân thủ (234)#5 | Feature | `frontend-config` | Minor |  | 3.0 | Chart "Tỷ lệ đáp ứng theo thời gian" | [discoveries/frontend-config/[-]-FEAT-046-vfr-chart-ty-le-dap-ung-theo-thoi-gian.md](discoveries/frontend-config/%5B-%5D-FEAT-046-vfr-chart-ty-le-dap-ung-theo-thoi-gian.md) |
| `[-]` | FEAT-047 | Tỷ lệ Đáp ứng & Tuân thủ (234)#11 | Feature | `frontend-config` | Minor |  | 3.0 | Card "Tỷ lệ tuân thủ" | [discoveries/frontend-config/[-]-FEAT-047-vfr-card-ty-le-tuan-thu.md](discoveries/frontend-config/%5B-%5D-FEAT-047-vfr-card-ty-le-tuan-thu.md) |
| `[-]` | FEAT-048 | %Loose picking (234)#10 | Feature | `frontend-widget` | Minor |  | 3.0 | Nút Apply filters, Reset filter | [_platform/prd-asks/[-]-PLATFORM-APPLY-RESET-BUTTON.md](_platform/prd-asks/%5B-%5D-PLATFORM-APPLY-RESET-BUTTON.md) |
| `[W]` | FEAT-049 | Sheet7#1 | Feature | `frontend-widget` | Low/Cosmetic |  | 3.0 | Thêm icon ? giải thích source, logic tính toán | [discoveries/frontend-widget/[W]-FEAT-049-flashdaily-them-icon-giai-thich-source-logic-tinh-t.md](discoveries/frontend-widget/%5BW%5D-FEAT-049-flashdaily-them-icon-giai-thich-source-logic-tinh-t.md) |
| `[W]` | FEAT-058 | Sheet7#74 | Feature | `frontend-config` | Minor |  | 3.0 | Scorecard: bổ sung % góc phải | [discoveries/frontend-config/[W]-FEAT-058-ordermonitoring-scorecard-bo-sung-goc-phai.md](discoveries/frontend-config/%5BW%5D-FEAT-058-ordermonitoring-scorecard-bo-sung-goc-phai.md) |
| `[W]` | FEAT-059 | Sheet7#75 | Feature | `frontend-widget` | Minor |  | 3.0 | Switch filter: day/week/month | — (no stub) |
| `[-]` | UX-064 | Tỷ lệ đáp ứng và tuân thủ#20 | UX | `frontend-config` | — |  | 3.0 | Card "Tổng số chuyến vận hành" | — (no stub) |
| `[-]` | UX-065 | Tỷ lệ đáp ứng và tuân thủ#22 | UX | `frontend-config` | — |  | 3.0 | Card "Tỷ lệ tuân thủ | — (no stub) |
| `[-]` | UX-066 | Tỷ lệ đáp ứng và tuân thủ#23 | UX | `frontend-config` | — |  | 3.0 | Chart "Tỷ lệ tuân thủ theo nhà vận tải" | — (no stub) |
| `[-]` | UX-067 | OTIF (204)#19 | UX | `frontend-config` | — |  | 3.0 | Bảng %OTIF chiều vận hành | — (no stub) |
| `[-]` | UX-068 | %Stock Type (214)#2 | UX | `frontend-widget` | — |  | 3.0 | Bộ lọc | [_platform/prd-asks/[-]-PLATFORM-FILTER-FIXED-SCORECARD.md](_platform/prd-asks/%5B-%5D-PLATFORM-FILTER-FIXED-SCORECARD.md) |
| `[-]` | UX-069 | %Stock Type (214)#4 | UX | `frontend-widget` | — |  | 3.0 | Bộ lọc | — (no stub) |
| `[-]` | UX-070 | %Stock Type (214)#9 | UX | `frontend-widget` | — |  | 3.0 | Bộ lọc "Khoảng thời gian" | — (no stub) |
| `[-]` | UX-071 | %Stock Type (214)#12 | UX | `frontend-config` | — |  | 3.0 | Vị trí thanh Biểu đồ, Chi tiết bảng | — (no stub) |
| `[-]` | UX-073 | Tỷ lệ Đáp ứng & Tuân thủ (234)#8 | UX | `frontend-widget` | — |  | 3.0 | Các bộ lọc còn lại trừ bộ lọc "Khoảng thời gian" | — (no stub) |
| `[-]` | UX-074 | Tỷ lệ Đáp ứng & Tuân thủ (234)#10 | UX | `frontend-config` | — |  | 3.0 | Card view "Tỷ lệ tuân thủ vận hành" | — (no stub) |
| `[-]` | UX-075 | Tỷ lệ Đáp ứng & Tuân thủ (234)#12 | UX | `frontend-config` | — |  | 3.0 | Chart "Tỷ lệ tuân thủ theo ngày" | — (no stub) |
| `[-]` | UX-076 | %Loose picking (234)#2 | UX | `frontend-widget` | — |  | 3.0 | Bộ lọc | [_platform/prd-asks/[-]-PLATFORM-FILTER-FIXED-SCORECARD.md](_platform/prd-asks/%5B-%5D-PLATFORM-FILTER-FIXED-SCORECARD.md) |
| `[-]` | UX-077 | %Loose picking (234)#4 | UX | `frontend-widget` | — |  | 3.0 | Bộ lọc | — (no stub) |
| `[-]` | UX-078 | %Loose picking (234)#9 | UX | `frontend-widget` | — |  | 3.0 | Bộ lọc "Khoảng thời gian" | — (no stub) |
| `[-]` | UX-079 | %Loose picking (234)#12 | UX | `frontend-config` | — |  | 3.0 | Vị trí thanh Biểu đồ, Chi tiết bảng | — (no stub) |
| `[W]` | UX-080 | Sheet7#2 | UX | `frontend-config` | — |  | 3.0 | Scorecard "Tổng volume" thành "Tổng volume kế hoạc | — (no stub) |
| `[-]` | UX-088 | Sheet7#53 | UX | `frontend-config` | — |  | 3.0 | Bỏ scorecard Movement Rows | — (no stub) |
| `[W]` | UX-090 | Sheet7#72 | UX | `frontend-config` | — |  | 3.0 | Scorecard chia 3 block: rời kho, trên đường giao,  | — (no stub) |
| `[W]` | UX-091 | Sheet7# | UX | `frontend-config` | — |  | 3.0 | Report: sort ưu tiên chuyến trễ và nguy cơ trễ   + | — (no stub) |
| `[-]` | UX-093 | Sheet7# | UX | `frontend-config` | — |  | 3.0 | chart: phân ra nguyên nhân fail ontime: phóng to t | — (no stub) |
| `[-]` | UX-109 | Tiến độ xuất hàng (204)#18 | UX | `frontend-config` | — |  | 1.8 | Relayout scorecard | — (no stub) |
| `[-]` | UX-110 | %Stock Type (214)#5 | UX | `frontend-widget` | — |  | 1.8 | Bộ lọc "Kho" | — (no stub) |
| `[-]` | UX-111 | %Stock Type (214)#6 | UX | `frontend-widget` | — |  | 1.8 | Bộ lọc "Khu vực giao hàng" | — (no stub) |
| `[-]` | UX-112 | %Stock Type (214)#7 | UX | `frontend-widget` | — |  | 1.8 | Bộ lọc "Kênh bán hàng" | — (no stub) |
| `[-]` | UX-113 | %Stock Type (214)#8 | UX | `frontend-widget` | — |  | 1.8 | Bộ lọc "Nhà vận tải" | — (no stub) |
| `[-]` | UX-115 | %Stock Type (214)#18 | UX | `frontend-config` | — |  | 1.8 | Relayout scorecard | — (no stub) |
| `[-]` | UX-117 | Tỷ lệ Đáp ứng & Tuân thủ (234)#2 | UX | `frontend-config` | — |  | 1.8 | Bố cục của view | — (no stub) |
| `[-]` | UX-120 | %Loose picking (234)#5 | UX | `frontend-widget` | — |  | 1.8 | Bộ lọc "Kho" | — (no stub) |
| `[-]` | UX-121 | %Loose picking (234)#6 | UX | `frontend-widget` | — |  | 1.8 | Bộ lọc "Khu vực giao hàng" | — (no stub) |
| `[-]` | UX-122 | %Loose picking (234)#7 | UX | `frontend-widget` | — |  | 1.8 | Bộ lọc "Kênh bán hàng" | — (no stub) |
| `[-]` | UX-123 | %Loose picking (234)#8 | UX | `frontend-widget` | — |  | 1.8 | Bộ lọc "Nhà vận tải" | — (no stub) |

### `mixed` — Multiple teams — needs coordination (45 items)

| Status | Triage ID | Source | Type | Tech layer | Priority | Sev | Score | Title | Stub |
|---|---|---|---|---|---|---|---|---|---|
| `[W]` | BUG-001 | VFR#11 | Bug | `cross-stack` | Major | Sev2 | 15.0 | Bảng dữ liệu detail | [bugs/cross-stack/[W]-BUG-001-vfr-bang-du-lieu-detail.md](bugs/cross-stack/%5BW%5D-BUG-001-vfr-bang-du-lieu-detail.md) |
| `[-]` | FEAT-024 | Sheet7# | Feature | `cross-stack` | Low/Cosmetic |  | 9.0 | tính năng config thay đổi tên field report | [discoveries/cross-stack/[-]-FEAT-024-other-tinh-nang-config-thay-doi-ten-field-repo.md](discoveries/cross-stack/%5B-%5D-FEAT-024-other-tinh-nang-config-thay-doi-ten-field-repo.md) |
| `[W]` | UX-025 | Tỷ lệ đáp ứng và tuân thủ#10 | UX | `cross-stack` | — |  | 9.0 | Bảng dữ liệu detail | [prd-asks/cross-stack/[W]-UX-025-vfr-bang-du-lieu-detail.md](prd-asks/cross-stack/%5BW%5D-UX-025-vfr-bang-du-lieu-detail.md) |
| `[-]` | UX-027 | Cảnh báo đơn trễ (204)#22 | UX | `cross-stack` | — |  | 9.0 | Bảng dữ liệu chi tiết | [prd-asks/cross-stack/[-]-UX-027-ordermonitoring-bang-du-lieu-chi-tiet.md](prd-asks/cross-stack/%5B-%5D-UX-027-ordermonitoring-bang-du-lieu-chi-tiet.md) |
| `[-]` | BUG-033 | VFR (224)#3 | Bug | `cross-stack` | Minor | Sev3 | 5.4 | Nội dung Bảng dữ liệu chi tiết | [bugs/cross-stack/[-]-BUG-033-vfr-noi-dung-bang-du-lieu-chi-tiet.md](bugs/cross-stack/%5B-%5D-BUG-033-vfr-noi-dung-bang-du-lieu-chi-tiet.md) |
| `[-]` | FEAT-034 | Cảnh báo đơn trễ (204)#20 | Feature | `cross-stack` | Major |  | 5.4 | Nội dung Bảng dữ liệu chi tiết | [discoveries/cross-stack/[-]-FEAT-034-ordermonitoring-noi-dung-bang-du-lieu-chi-tiet.md](discoveries/cross-stack/%5B-%5D-FEAT-034-ordermonitoring-noi-dung-bang-du-lieu-chi-tiet.md) |
| `[-]` | UX-035 | %Stock Type (214)#20 | UX | `cross-stack` | — |  | 5.4 | Nội dung Bảng dữ liệu chi tiết | [prd-asks/cross-stack/[-]-UX-035-inventory-noi-dung-bang-du-lieu-chi-tiet.md](prd-asks/cross-stack/%5B-%5D-UX-035-inventory-noi-dung-bang-du-lieu-chi-tiet.md) |
| `[-]` | FEAT-050 | Sheet7#27 | Feature | `cross-stack` | Minor |  | 3.0 | thêm fillter: trung chuyển trong, trung chuyển ngo | [discoveries/cross-stack/[-]-FEAT-050-other-them-fillter-trung-chuyen-trong-trung-ch.md](discoveries/cross-stack/%5B-%5D-FEAT-050-other-them-fillter-trung-chuyen-trong-trung-ch.md) |
| `[-]` | FEAT-051 | Sheet7# | Feature | `unknown` | Minor |  | 3.0 | thêm customer, region. Filter xổ chọn | [discoveries/unknown/[-]-FEAT-051-other-them-customer-region-filter-xo-chon.md](discoveries/unknown/%5B-%5D-FEAT-051-other-them-customer-region-filter-xo-chon.md) |
| `[-]` | FEAT-052 | Sheet7#48 | Feature | `cross-stack` | Major |  | 3.0 | bổ sung thêm stock type theo shelflife | [discoveries/cross-stack/[-]-FEAT-052-inventory-bo-sung-them-stock-type-theo-shelflife.md](discoveries/cross-stack/%5B-%5D-FEAT-052-inventory-bo-sung-them-stock-type-theo-shelflife.md) |
| `[-]` | FEAT-053 | Sheet7# | Feature | `cross-stack` | Major |  | 3.0 | thêm chart liên quan tới transaction | [discoveries/cross-stack/[-]-FEAT-053-transactionmove-them-chart-lien-quan-toi-transaction.md](discoveries/cross-stack/%5B-%5D-FEAT-053-transactionmove-them-chart-lien-quan-toi-transaction.md) |
| `[-]` | FEAT-055 | Sheet7# | Feature | `cross-stack` | Minor |  | 3.0 | thêm intotal xuất bán , ... | [discoveries/cross-stack/[-]-FEAT-055-transactionmove-them-intotal-xuat-ban.md](discoveries/cross-stack/%5B-%5D-FEAT-055-transactionmove-them-intotal-xuat-ban.md) |
| `[-]` | FEAT-056 | Sheet7#62 | Feature | `cross-stack` | Minor |  | 3.0 | Thêm filter thời gian | [discoveries/cross-stack/[-]-FEAT-056-other-them-filter-thoi-gian.md](discoveries/cross-stack/%5B-%5D-FEAT-056-other-them-filter-thoi-gian.md) |
| `[-]` | FEAT-057 | Sheet7#66 | Feature | `cross-stack` | Major |  | 3.0 | bổ sung lý do rớt là gồm cả 2 () | [discoveries/cross-stack/[-]-FEAT-057-other-bo-sung-ly-do-rot-la-gom-ca-2.md](discoveries/cross-stack/%5B-%5D-FEAT-057-other-bo-sung-ly-do-rot-la-gom-ca-2.md) |
| `[W]` | FEAT-060 | Sheet7# | Feature | `cross-stack` | Major |  | 3.0 | Phân quyền data: theo kho (ưu tiên sau) | — (no stub) |
| `[-]` | FEAT-061 | Sheet7# | Feature | `cross-stack` | Major |  | 3.0 | phân quyền nhập số | — (no stub) |
| `[-]` | FEAT-062 | Sheet7# | Feature | `cross-stack` | Major |  | 3.0 | thêm nhập số thay vì set cứng thì cho nhập số sett | — (no stub) |
| `[W]` | UX-063 | VFR#10 | UX | `unknown` | — |  | 3.0 | VFR gửi thầu theo thời gian và khu vực | — (no stub) |
| `[-]` | UX-072 | %Stock Type (214)#21 | UX | `cross-stack` | — |  | 3.0 | Nội dung Bảng dữ liệu pivot | — (no stub) |
| `[-]` | UX-081 | Sheet7# | UX | `unknown` | — |  | 3.0 | filter multiple choice -> bkd -> bkd 1,2,3  nkd -> | — (no stub) |
| `[-]` | UX-082 | Sheet7# | UX | `unknown` | — |  | 3.0 | bị vấn đề cái flow logic bị thiếu, ko chặt chẽ với | — (no stub) |
| `[W]` | UX-083 | Sheet7#26 | UX | `unknown` | — |  | 3.0 | Chỉnh sửa option filter warehouse: BKD, external B | — (no stub) |
| `[-]` | UX-084 | Sheet7#28 | UX | `unknown` | — |  | 3.0 | chuyển copack, trung chuyển , nhập từ xưởng vô tra | — (no stub) |
| `[-]` | UX-085 | Sheet7#29 | UX | `unknown` | — |  | 3.0 | 2 p: historical, daily | — (no stub) |
| `[-]` | UX-086 | Sheet7# | UX | `unknown` | — |  | 3.0 | cho tính theo palet | — (no stub) |
| `[-]` | UX-087 | Sheet7# | UX | `cross-stack` | — |  | 3.0 | stock category để identify | — (no stub) |
| `[-]` | UX-089 | Sheet7#67 | UX | `unknown` | — |  | 3.0 | Chỉnh sửa filter Kho lấy hàng: BKD, NKD, Kho ngoài | — (no stub) |
| `[-]` | UX-092 | Sheet7# | UX | `cross-stack` | — |  | 3.0 | thêm nhập số thay vì 45p thì cho nhập số setting t | — (no stub) |
| `[-]` | UX-094 | Sheet7# | UX | `unknown` | — |  | 3.0 | đưa các chuyến có nguy cơ trễ lên trước | — (no stub) |
| `[-]` | UX-095 | Sheet7# | UX | `unknown` | — |  | 3.0 | kích tổng số chuyển ra khỏi ngoài, cho tiêu đề inp | — (no stub) |
| `[-]` | UX-096 | Sheet7# | UX | `unknown` | — |  | 3.0 | sửa lại lý do trễ tiếng việt -> tiếng anh | — (no stub) |
| `[-]` | UX-097 | Sheet7# | UX | `cross-stack` | — |  | 3.0 | Logic: cảnh báo theo từng điểm giao | — (no stub) |
| `[W]` | UX-098 | Sheet7#95 | UX | `unknown` | — |  | 3.0 | Visualization:  - Thêm ô điền TG manual input  - T | — (no stub) |
| `[-]` | FEAT-104 | Cảnh báo đơn trễ (204)#13 | Feature | `cross-stack` | Minor |  | 1.8 | Chart time series | — (no stub) |
| `[-]` | FEAT-105 | %Stock Type (214)#13 | Feature | `cross-stack` | Minor |  | 1.8 | Chart time series | — (no stub) |
| `[-]` | FEAT-106 | %Utilization (224)#13 | Feature | `cross-stack` | Minor |  | 1.8 | Chart time series | — (no stub) |
| `[-]` | FEAT-107 | %Loose picking (234)#13 | Feature | `cross-stack` | Minor |  | 1.8 | Chart time series | — (no stub) |
| `[-]` | UX-114 | %Stock Type (214)#14 | UX | `cross-stack` | — |  | 1.8 | Chart time series | — (no stub) |
| `[-]` | UX-116 | %Utilization (224)#14 | UX | `cross-stack` | — |  | 1.8 | Chart time series | — (no stub) |
| `[-]` | UX-118 | Tỷ lệ Đáp ứng & Tuân thủ (234)#6 | UX | `unknown` | — |  | 1.8 | Report "Dữ liệu chi tiết tỷ lệ đáp ứng gửi thầu" | — (no stub) |
| `[-]` | UX-119 | Tỷ lệ Đáp ứng & Tuân thủ (234)#13 | UX | `unknown` | — |  | 1.8 | Report "Dữ liệu chi tiết tỷ lệ tuân thủ vận hành" | — (no stub) |
| `[-]` | UX-124 | %Loose picking (234)#14 | UX | `cross-stack` | — |  | 1.8 | Chart time series | — (no stub) |
| `[W]` | FEAT-125 | Sheet7#3 | Feature | `cross-stack` | Major |  | 1.7 | Bổ sung report tỷ lệ hoàn thành | — (no stub) |
| `[-]` | FEAT-126 | Sheet7# | Feature | `cross-stack` | Major |  | 1.7 | Bổ sung report Movement Transaction | — (no stub) |
| `[W]` | FEAT-127 | Sheet7#94 | Feature | `cross-stack` | Major |  | 1.7 | Thêm 1 view insight về vận chuyển & tính tuân thủ  | — (no stub) |

### `cs` — Customer Success — answer & close (1 items)

| Status | Triage ID | Source | Type | Tech layer | Priority | Sev | Score | Title | Stub |
|---|---|---|---|---|---|---|---|---|---|
| `[Q]` | Q-139 | Sheet7# | Question | `cross-stack` | — |  | 1.0 | ở report hàng rớt: thêm fillter by , lăng kinh khá | — (no stub) |

### `closed` — Closed (Duplicate / Out-of-scope) (18 items)

| Status | Triage ID | Source | Type | Tech layer | Priority | Sev | Score | Title | Stub |
|---|---|---|---|---|---|---|---|---|---|
| `[X]` | DUP-042 | VFR#22 | Duplicate | `frontend-config` | — |  | 3.0 | VFR gửi thầu theo Khu vực VFR gửi thầu theo loại x | — (no stub) |
| `[X]` | DUP-099 | VFR#16 | Duplicate | `backend-config` | — |  | 1.8 | Bộ lọc "Kho lấy hàng" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[X]` | DUP-100 | VFR#17 | Duplicate | `backend-config` | — |  | 1.8 | Bộ lọc "Điểm giao hàng" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[X]` | DUP-101 | VFR#18 | Duplicate | `backend-config` | — |  | 1.8 | Bộ lọc "Khu vực giao hàng" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[X]` | DUP-102 | VFR#19 | Duplicate | `backend-config` | — |  | 1.8 | Bộ lọc "Nhà vận tải" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[X]` | DUP-103 | VFR#20 | Duplicate | `backend-config` | — |  | 1.8 | Bộ lọc "Loại xe gửi thầu" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[X]` | OOS-108 | VFR#3 | Out-of-scope | `backend-config` | — |  | 1.8 | Bộ lọc "Điểm giao hàng" | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| `[X]` | DUP-128 | VFR#13 | Duplicate | `frontend-widget` | — |  | 1.0 | Bộ lọc | — (no stub) |
| `[X]` | DUP-129 | VFR#21 | Duplicate | `frontend-widget` | — |  | 1.0 | Bộ lọc "Loại ngày" | — (no stub) |
| `[X]` | DUP-130 | VFR#23 | Duplicate | `unknown` | — |  | 1.0 | VFR gửi thầu theo loại bốc xếp | — (no stub) |
| `[X]` | DUP-131 | VFR#24 | Duplicate | `unknown` | — |  | 1.0 | VFR gửi thầu theo thời gian và khu vực | — (no stub) |
| `[X]` | DUP-132 | Tỷ lệ đáp ứng và tuân thủ#12 | Duplicate | `frontend-widget` | — |  | 1.0 | Bộ lọc | — (no stub) |
| `[X]` | DUP-133 | Tỷ lệ đáp ứng và tuân thủ#15 | Duplicate | `frontend-config` | — |  | 1.0 | Bộ lọc "Mã điểm" | — (no stub) |
| `[X]` | DUP-134 | Tỷ lệ đáp ứng và tuân thủ#16 | Duplicate | `frontend-widget` | — |  | 1.0 | Bộ lọc "Loại điểm" | — (no stub) |
| `[X]` | DUP-135 | Tỷ lệ đáp ứng và tuân thủ#17 | Duplicate | `frontend-widget` | — |  | 1.0 | Bộ lọc "Nhà vận tải" | — (no stub) |
| `[X]` | DUP-136 | Tỷ lệ đáp ứng và tuân thủ#18 | Duplicate | `frontend-widget` | — |  | 1.0 | Bộ lọc "Loại ngày" | — (no stub) |
| `[X]` | DUP-137 | Tỷ lệ đáp ứng và tuân thủ#19 | Duplicate | `frontend-widget` | — |  | 1.0 | Bộ lọc "Khoảng thời gian" | — (no stub) |
| `[X]` | OOS-138 | Tỷ lệ đáp ứng và tuân thủ#3 | Out-of-scope | `frontend-widget` | — |  | 1.0 | Bộ lọc "Điểm giao hàng" | — (no stub) |


## Notes
- Mỗi item chỉ xuất hiện 1 lần (ở team chính). Nếu cần coordinate nhiều team → owner_team = `mixed`, xem stub để biết detail.
- Items với owner = `mixed` thường thuộc tech_layer = `cross-stack` hoặc `unknown` — cần PM kick-off meeting để chia việc.
- Items với owner = `closed` (Duplicate / Out-of-scope) không cần fix — list ở đây để traceability.
