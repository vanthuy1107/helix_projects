# Story Prefix Status — Edit UX_UI MDLZ — 2026-05-09

Mapping convention `[D]/[W]/[-]` → status thực tế trong file Excel của khách MDLZ.

**Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx`
**Total rows scanned**: 310 (12 sheet, skip `Overview`)

## Convention mapping

| Story Prefix | Meaning | Raw status trong file MDLZ |
|---|---|---|
| `[D]` | **Done** | `Đã fixed` (12 sheet feedback) hoặc `Đã sửa = True` (Sheet7 boolean column) |
| `[W]` | **Work In Progress** | `Đang fixing`, `Fix lại`, `In-dev`, `In-doing`, `In Progress`, `SLG đã nhận yêu cầu`, `Pending` |
| `[-]` | **Draft** | `New` hoặc `(blank)` |
| `X` | _Closed-cancelled_ (không trong convention) | `BỎ`, `trùng hả c` |
| `?` | _Unmappable_ — cần BA review | Status text không khớp pattern nào |

## Distribution

| Prefix | Count | % | Note |
|---|---|---|---|
| `[D]` Done | 170 | 54.8% | Đã hoàn thành — KHÔNG nằm trong triage backlog |
| `[-]` Draft | 93 | 30.0% | Items mới chưa fix — main triage backlog |
| `[W]` WIP | 29 | 9.4% | Đang làm — vẫn trong triage backlog để tracking |
| `?` unmapped | 13 | 4.2% | Cần BA review thủ công |
| `X` closed | 5 | 1.6% | Khách hủy / duplicate |
| **Total** | **310** | 100% | |

> **Validation**: 170 Done + 140 trong [`backlog.md`](backlog.md) actionable = 310 rows tổng. Backlog chỉ triage 140 items active (Draft + WIP + closed-mark).

## `[D]` Done items — by sheet


### `%Stock Type (214)` — 1 done items

| Row | Status raw | Item |
|---|---|---|
| 17 | `Đã fixed` | Đổi tên view |

### `%Utilization (224)` — 12 done items

| Row | Status raw | Item |
|---|---|---|
| 2 | `Đã fixed` | Bộ lọc |
| 3 | `Đã fixed` | Bộ lọc |
| 4 | `Đã fixed` | Bộ lọc |
| 5 | `Đã fixed` | Bộ lọc "Kho" |
| 6 | `Đã fixed` | Bộ lọc "Khu vực giao hàng" |
| 7 | `Đã fixed` | Bộ lọc "Kênh bán hàng" |
| 8 | `Đã fixed` | Bộ lọc "Nhà vận tải" |
| 9 | `Đã fixed` | Bộ lọc "Khoảng thời gian" |
| 10 | `Đã fixed` | Nút Apply filters, Reset filter |
| 11 | `Đã fixed` | Tính năng download hình ảnh, excel |
| 12 | `Đã fixed` | Vị trí thanh Biểu đồ, Chi tiết bảng |
| 15 | `Đã fixed` | Show số liệu lên chart |

### `Cảnh báo đơn trễ (204)` — 17 done items

| Row | Status raw | Item |
|---|---|---|
| 2 | `Đã fixed` | Bộ lọc |
| 3 | `Đã fixed` | Bộ lọc |
| 4 | `Đã fixed` | Bộ lọc |
| 5 | `Đã fixed` | Bộ lọc "Kho" |
| 6 | `Đã fixed` | Bộ lọc "Khu vực giao hàng" |
| 7 | `Đã fixed` | Bộ lọc "Kênh bán hàng" |
| 8 | `Đã fixed` | Bộ lọc "Nhà vận tải" |
| 9 | `Đã fixed` | Bộ lọc "Khoảng thời gian" |
| 10 | `Đã fixed` | Nút Apply filters, Reset filter |
| 11 | `Đã fixed` | Tính năng download hình ảnh, excel |
| 12 | `Đã fixed` | Vị trí thanh Biểu đồ, Chi tiết bảng |
| 14 | `Đã fixed` | Chart time series |
| 16 | `Đã fixed` | Sort + Search ở report |
| 17 | `Đã fixed` | Đổi tên view |
| 18 | `Đã fixed` | Đổi tên scorecard |
| 19 | `Đã fixed` | Relayout scorecard |
| 23 | `Đã fixed` | Bổ sung chart |

### `Flash report (214)` — 25 done items

| Row | Status raw | Item |
|---|---|---|
| 2 | `Đã fixed` | Bộ lọc |
| 3 | `Đã fixed` | Bộ lọc |
| 4 | `Đã fixed` | Bộ lọc |
| 5 | `Đã fixed` | Bộ lọc "Kho" |
| 6 | `Đã fixed` | Bộ lọc "Khu vực giao hàng" |
| 7 | `Đã fixed` | Bộ lọc "Kênh bán hàng" |
| 8 | `Đã fixed` | Bộ lọc "Nhà vận tải" |
| 9 | `Đã fixed` | Bộ lọc "Khoảng thời gian" |
| 10 | `Đã fixed` | Nút Apply filters, Reset filter |
| 11 | `Đã fixed` | Tính năng download hình ảnh, excel |
| 12 | `Đã fixed` | Vị trí thanh Biểu đồ, Chi tiết bảng |
| 13 | `Đã fixed` | Chart time series |
| 14 | `Đã fixed` | Chart time series |
| 15 | `Đã fixed` | Show số liệu lên chart |
| 16 | `Đã fixed` | Sort + Search ở report |
| 17 | `Đã fixed` | Filter Brand |
| 18 | `Đã fixed` | Thêm tính năng ẩn cột |
| 19 | `Đã fixed` | Report lý do rớt đơn |
| 20 | `Đã fixed` | Bar chart |
| 21 | `Đã fixed` | Relayout view |
| 22 | `Đã fixed` | Sai loại chart |
| 23 | `Đã fixed` | 9 report Flash report |
| 24 | `Đã fixed` | [BUG] |
| 25 | `Đã fixed` | [BUG] |
| 26 | `Đã fixed` | [UI] |

### `Movement transaction (214)` — 18 done items

| Row | Status raw | Item |
|---|---|---|
| 2 | `Đã fixed` | Bộ lọc |
| 3 | `Đã fixed` | Bộ lọc |
| 4 | `Đã fixed` | Bộ lọc |
| 5 | `Đã fixed` | Bộ lọc "Kho" |
| 6 | `Đã fixed` | Bộ lọc "Khu vực giao hàng" |
| 7 | `Đã fixed` | Bộ lọc "Kênh bán hàng" |
| 8 | `Đã fixed` | Bộ lọc "Nhà vận tải" |
| 9 | `Đã fixed` | Bộ lọc "Khoảng thời gian" |
| 10 | `Đã fixed` | Nút Apply filters, Reset filter |
| 11 | `Đã fixed` | Tính năng download hình ảnh, excel |
| 12 | `Đã fixed` | Vị trí thanh Biểu đồ, Chi tiết bảng |
| 13 | `Đã fixed` | Chart time series |
| 14 | `Đã fixed` | Chart time series |
| 15 | `Đã fixed` | Show số liệu lên chart |
| 18 | `Đã fixed` | Bộ lọc TYPE |
| 19 | `Đã fixed` | Bổ sung chart |
| 20 | `Đã fixed` | Bổ sung chart |
| 21 | `Đã fixed` | Bổ sung report raw |

### `OTIF (204)` — 20 done items

| Row | Status raw | Item |
|---|---|---|
| 2 | `Đã fixed` | Bộ lọc |
| 3 | `Đã fixed` | Bộ lọc |
| 4 | `Đã fixed` | Bộ lọc |
| 5 | `Đã fixed` | Bộ lọc "Kho" |
| 6 | `Đã fixed` | Bộ lọc "Khu vực giao hàng" |
| 7 | `Đã fixed` | Bộ lọc "Nhóm hàng" |
| 8 | `Đã fixed` | Bộ lọc "Nhà vận tải" |
| 9 | `Đã fixed` | Bộ lọc "Khoảng thời gian" |
| 10 | `Đã fixed` | Nút Apply filters, Reset filter |
| 11 | `Đã fixed` | Tính năng download hình ảnh, excel |
| 12 | `Đã fixed` | Vị trí thanh Biểu đồ, Chi tiết bảng |
| 13 | `Đã fixed` | Chart time series |
| 14 | `Đã fixed` | Chart time series |
| 15 | `Đã fixed` | Show số liệu lên chart |
| 16 | `Đã fixed` | Sort + Search ở report |
| 17 | `Đã fixed` | Show số total ở góc phải |
| 18 | `Đã fixed` | Đổi tên chart |
| 20 | `Đã fixed` | Bảng chi tiết OTIF |
| 21 | `Đã fixed` | Bổ sung chart |
| 22 | `Đã fixed` | Đổi chart |

### `Sheet7` — 41 done items

| Row | Status raw | Item |
|---|---|---|
| 5 | `Đã sửa=True` | Bộ lọc Loại ngày: GI date |
| 8 | `Đã sửa=True` | hide các cột không liên quan đến các chart, filter |
| 9 | `Đã sửa=True` | thêm cột total cho table report hàng rớt |
| 10 | `Đã sửa=True` | ở chart Phân bổ e2e: thêm kế hoạch xuất và tổng thực xuất |
| 12 | `Đã sửa=True` | sửa các con số nổi bật khi ở dạng dark |
| 13 | `Đã sửa=True` | sửa fixed các mục fillter scroll ko di chuyển |
| 14 | `Đã sửa=True` | bổ sung thêm thuôc tính số kế hoạch mỗi chart |
| 15 | `Đã sửa=True` | bổ sung layout ưu tiên 1 page (giá trị vh) tránh scroll |
| 17 | `Đã sửa=True` | ở chart e2e, thêm cục rớt, thêm cột total gì đó |
| 18 | `Đã sửa=True` | các thông tin cột ko link map với chart trên thì ẩn nó đi, tránh bị rối, thể hiện đúng các |
| 19 | `Đã sửa=True` | sửa layout |
| 20 | `Đã sửa=True` | Chart khu vực lên trước |
| 21 | `Đã sửa=True` | thiếu kế hoạch xuất: bổ sung 2 cột: kế hoạch xuất và tổng thực xuất cho tất cả chart và hà |
| 22 | `Đã sửa=True` | bổ xung filter npp/ vùng cho chart "theo npp/customer"-> fix cứng filter scroll |
| 31 | `Đã sửa=True` | bỏ đi số lẻ ở các card |
| 32 | `Đã sửa=True` | thêm biểu đồ line chart để hiện thị tháng nào cao nhất |
| 33 | `Đã sửa=True` | bỏ đi chart SKU top 15 |
| 35 | `Đã sửa=True` | master unit: bỏ đi |
| 37 | `Đã sửa=True` | Fixed filter scroll |
| 38 | `Đã sửa=True` | Bỏ số thập phân ở scorecard Total boxes, Loose boxes |
| 39 | `Đã sửa=True` | Bỏ chart Top SKU |
| 40 | `Đã sửa=True` | Bổ sung line chart (câu query dòng 8)  - Trục x: theo thời gian  - Trục y: %Loose picking  |
| 41 | `Đã sửa=True` | Report detail pivot theo customer & region (câu query dòng 9)  - Nút tick chọn pivot: cust |
| 42 | `Đã sửa=True` | Show số liệu lên chart Full / Loose structure by warehouse (không hover) |
| 43 | `Đã sửa=True` | Show số liệu lên scorecard Full vs Loose (total CSE) (không hover) |
| 44 | `Đã sửa=True` | Thu gọn scorecard, kéo dài chart Full/Loose structure by warehouse |
| 47 | `Đã sửa=True` | dư masterunit |
| 49 | `Đã sửa=True` | Fixed filter scroll |
| 50 | `Đã sửa=True` | Bỏ bộ lọc loại ngày. Thêm description "Với hoạt động xuất, lọc theo ngày Actual Ship Date. |
| 58 | `Đã sửa=True` | ĐỂ TÊN VIEW GIỐNG SITE CŨ |
| 59 | `Đã sửa=True` | sửa lại con số ấn tượng to lên ở mỗi chart |
| 60 | `Đã sửa=True` | thêm loading khi load dữ liệu ở site cũ |
| 63 | `Đã sửa=True` | ĐỂ TÊN VIEW GIỐNG SITE CŨ |
| 65 | `Đã sửa=True` | ĐỂ TÊN VIEW GIỐNG SITE CŨ |
| 73 | `Đã sửa=True` | hightlight trong kho/ vận chuyển |
| 77 | `Đã sửa=True` | sửa lại cái late order alert là ưu tiên trễ lên đầu, cho chớp chớp at rick,.. thể hiện cho |
| 82 | `Đã sửa=True` | sửa lại hiện thị các con số nổi bật |
| 83 | `Đã sửa=True` | ĐỂ TÊN VIEW GIỐNG SITE CŨ |
| 86 | `Đã sửa=True` | thêm theo ngày chart tỷ lệ tuân thủ theo thời gian |
| 87 | `Đã sửa=True` | chart tuân thủ chưa có |
| 88 | `Đã sửa=True` | ĐỂ TÊN VIEW GIỐNG SITE CŨ |

### `Tiến độ xuất hàng (204)` — 18 done items

| Row | Status raw | Item |
|---|---|---|
| 2 | `Đã fixed` | Bộ lọc |
| 3 | `Đã fixed` | Bộ lọc |
| 4 | `Đã fixed` | Bộ lọc |
| 5 | `Đã fixed` | Bộ lọc "Kho" |
| 6 | `Đã fixed` | Bộ lọc "Khu vực giao hàng" |
| 7 | `Đã fixed` | Bộ lọc "Kênh bán hàng" |
| 8 | `Đã fixed` | Bộ lọc "Nhà vận tải" |
| 9 | `Đã fixed` | Bộ lọc "Khoảng thời gian" |
| 10 | `Đã fixed` | Nút Apply filters, Reset filter |
| 11 | `Đã fixed` | Tính năng download hình ảnh, excel |
| 12 | `Đã fixed` | Vị trí thanh Biểu đồ, Chi tiết bảng |
| 13 | `Đã fixed` | Chart time series |
| 14 | `Đã fixed` | Chart time series |
| 15 | `Đã fixed` | Show số liệu lên chart |
| 17 | `Đã fixed` | Đổi tên view |
| 19 | `Đã fixed` | Đổi tên scorecard |
| 20 | `Đã fixed` | Nội dung Bảng dữ liệu chi tiết |
| 21 | `Đã fixed` | Nội dung Bảng dữ liệu pivot |

### `Tỷ lệ đáp ứng và tuân thủ` — 7 done items

| Row | Status raw | Item |
|---|---|---|
| 6 | `Đã fixed` | Bộ lọc "Loại ngày" |
| 7 | `Đã fixed` | Card |
| 8 | `Đã fixed` | Tỷ lệ đáp ứng theo nhà vận tải |
| 9 | `Đã fixed` | Tỷ lệ đáp ứng theo thời gian |
| 11 | `Đã fixed` | Tính năng bộ lọc |
| 14 | `Đã fixed` | Mô tả thông tin liên quan của từng chart |
| 24 | `Đã fixed` | Chart " Tỷ lệ tuân thủ theo thời gian" |

### `VFR` — 5 done items

| Row | Status raw | Item |
|---|---|---|
| 7 | `Đã fixed` | Bộ lọc "Loại ngày" |
| 8 | `Đã fixed` | VFR gửi thầu theo Khu vực VFR gửi thầu theo loại xe |
| 9 | `Đã fixed` | VFR gửi thầu theo loại bốc xếp |
| 12 | `Đã fixed` | Tính năng bộ lọc |
| 15 | `Đã fixed` | Mô tả thông tin liên quan của từng chart |

### `VFR (224)` — 6 done items

| Row | Status raw | Item |
|---|---|---|
| 2 | `Đã fixed` | Kích thước của chart và table |
| 4 | `Đã fixed` | Bộ lọc "Loại xe gửi thầu" |
| 5 | `Đã fixed` | Bộ lọc "Loại xe vận hành" |
| 6 | `Đã fixed` | Nút Apply filters, Reset filter |
| 8 | `Đã fixed` | Chọn value của bộ lọc |
| 9 | `Đã fixed` | Bộ lọc "Khoảng thời gian" |

## `[W]` Work In Progress items — 29

| Sheet | Row | Status raw | Item |
|---|---|---|---|
| %Utilization (224) | 16 | `Pending` | Sort + Search ở report |
| Movement transaction (214) | 16 | `Pending` | Sort + Search ở report |
| Sheet7 | 2 | `In-dev` | Thêm icon ? giải thích source, logic tính toán |
| Sheet7 | 3 | `In-dev` | Scorecard "Tổng volume" thành "Tổng volume kế hoạch"  Scorecard: note thêm descr |
| Sheet7 | 4 | `In-dev` | Bổ sung report tỷ lệ hoàn thành |
| Sheet7 | 23 | `In-doing` | Update lại TOBE visualization, công thức tính toán cho từng chart |
| Sheet7 | 24 | `SLG đã nhận yêu cầu` | Thêm dấu phẩy phân cách hàng nghìn đối với các card KPI số lượng |
| Sheet7 | 26 | `SLG đã nhận yêu cầu` | Chỉnh lại màu của Partial bins, đang bị trùng với màu nền |
| Sheet7 | 27 | `SLG đã nhận yêu cầu` | Chỉnh sửa option filter warehouse: BKD, external BKD, NKD, external NKD |
| Sheet7 | 64 | `In-dev` | Scorecard chia 3 block: rời kho, trên đường giao, đã giao |
| Sheet7 | 66 | `In-dev` | Scorecard: bổ sung % góc phải |
| Sheet7 | 67 | `In-dev` | Switch filter: day/week/month |
| Sheet7 | 68 | `In-dev` | Report: sort ưu tiên chuyến trễ và nguy cơ trễ   + Size chữ bự: chuyến, giờ bắt  |
| Sheet7 | 69 | `In-dev` | Phân quyền data: theo kho (ưu tiên sau) |
| Sheet7 | 84 | `In-dev` | Thêm 1 view insight về vận chuyển & tính tuân thủ của tài xế ra vào NPP  Logic:  |
| Sheet7 | 85 | `In-dev` | Visualization:  - Thêm ô điền TG manual input  - Tương tự phần dock (vào kho ra  |
| Tiến độ xuất hàng (204) | 16 | `Pending` | Sort + Search ở report |
| Tỷ lệ đáp ứng và tuân thủ | 2 | `Fix lại` | Bộ lọc "Kho lấy hàng" |
| Tỷ lệ đáp ứng và tuân thủ | 4 | `Fix lại` | Bộ lọc "Khu vực giao hàng" |
| Tỷ lệ đáp ứng và tuân thủ | 5 | `Fix lại` | Bộ lọc "Nhà vận tải" |
| Tỷ lệ đáp ứng và tuân thủ | 10 | `Đang fixing` | Bảng dữ liệu detail |
| Tỷ lệ đáp ứng và tuân thủ | 21 | `Fix lại` | Card "Tổng số điểm vận hành" |
| VFR | 2 | `Fix lại` | Bộ lọc "Kho lấy hàng" |
| VFR | 4 | `Fix lại` | Bộ lọc "Khu vực giao hàng" |
| VFR | 5 | `Fix lại` | Bộ lọc "Nhà vận tải" |
| VFR | 6 | `Fix lại` | Bộ lọc "Loại xe gửi thầu" |
| VFR | 10 | `Fix lại` | VFR gửi thầu theo thời gian và khu vực |
| VFR | 11 | `Đang fixing` | Bảng dữ liệu detail |
| VFR (224) | 7 | `Đang fixing` | Tính năng download hình ảnh, excel |

## `?` Unmappable status — 13

Items có status text lạ, không khớp convention. Cần BA review thủ công.

| Sheet | Row | Status raw | Item |
|---|---|---|---|
| Tỷ lệ đáp ứng và tuân thủ | 12 | `sao lại dùng bộ lọc riêng ??` | Bộ lọc |
| Tỷ lệ đáp ứng và tuân thủ | 15 | `sao lại dùng bộ lọc riêng ??` | Bộ lọc "Mã điểm" |
| Tỷ lệ đáp ứng và tuân thủ | 16 | `sao lại dùng bộ lọc riêng ??` | Bộ lọc "Loại điểm" |
| Tỷ lệ đáp ứng và tuân thủ | 17 | `sao lại dùng bộ lọc riêng ??` | Bộ lọc "Nhà vận tải" |
| Tỷ lệ đáp ứng và tuân thủ | 18 | `sao lại dùng bộ lọc riêng ??` | Bộ lọc "Loại ngày" |
| Tỷ lệ đáp ứng và tuân thủ | 19 | `sao lại dùng bộ lọc riêng ??` | Bộ lọc "Khoảng thời gian" |
| VFR | 13 | `sao lại dùng bộ lọc riêng ??` | Bộ lọc |
| VFR | 16 | `sao lại dùng bộ lọc riêng ??` | Bộ lọc "Kho lấy hàng" |
| VFR | 17 | `sao lại dùng bộ lọc riêng ??` | Bộ lọc "Điểm giao hàng" |
| VFR | 18 | `sao lại dùng bộ lọc riêng ??` | Bộ lọc "Khu vực giao hàng" |
| VFR | 19 | `sao lại dùng bộ lọc riêng ??` | Bộ lọc "Nhà vận tải" |
| VFR | 20 | `sao lại dùng bộ lọc riêng ??` | Bộ lọc "Loại xe gửi thầu" |
| VFR | 21 | `sao lại dùng bộ lọc riêng ??` | Bộ lọc "Loại ngày" |

## Note quy trình

1. **Convention `[D]/[W]/[-]` chưa được khách MDLZ áp dụng trực tiếp** — họ dùng từ Tiếng Việt (`Đã fixed`, `Đang fixing`, `New`, ...). File này map ngầm sang convention.
2. **Đề xuất**: nếu muốn convention thực sự enforce, thống nhất với khách dùng prefix `[D]/[W]/[-]` trong cột "Trạng thái" thay vì free-text. Sẽ giảm 13 row `?` unmapped.
3. **Items Done KHÔNG cần re-triage** — đã closed bởi team SLG. Triage backlog chỉ tập trung 140 items active.
4. **Items WIP có thể đã có dev đang làm** — kiểm tra với DEV team trước khi assign mới.
