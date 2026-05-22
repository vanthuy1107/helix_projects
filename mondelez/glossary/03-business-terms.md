# 03 — Business Terms (thuật ngữ nghiệp vụ)

Từ điển thuật ngữ logistics dùng chung trong dự án Mondelez. Sắp xếp theo nhóm.

---

## Đơn hàng / Orders

| Viết tắt | Tên tiếng Anh | Tên tiếng Việt | Mô tả | Ngữ cảnh |
|---------|---------------|---------------|------|---------|
| **DO** | Delivery Order | Đơn giao hàng | Đơn hàng cấp giao — 1 SO có thể tách thành nhiều DO | TMS, OTIF, Shipping Progress |
| **SO** | Sales Order | Đơn bán hàng | Đơn từ kênh bán; cấp cao nhất | TMS, WMS |
| **CSE** | Case | Thùng | Đơn vị quy đổi chính cho Infull, picking | WMS, OTIF |
| **PCE** | Piece | Cái / lẻ | Đơn vị nhỏ nhất (Master Unit) | WMS |
| **PL / PLT** | Pallet | Pallet | Đơn vị lớn nhất; dùng trong Stock Type, Transaction Move | WMS |
| **MOQ** | Minimum Order Quantity | Số lượng đặt tối thiểu | Ngưỡng đơn hàng tối thiểu chấp nhận | Sales planning |
| **PGI** | Post Goods Issue | Xuất kho hệ thống | Hành động xác nhận xuất kho trong SAP/ERP | `WidgetPgiReport` |

---

## Vận chuyển / Transport (TMS = STM)

| Viết tắt | Tên tiếng Anh | Tên tiếng Việt | Mô tả |
|---------|---------------|---------------|------|
| **STM** | Smart Transport Management | Hệ thống vận tải | Hệ thống TMS của Smartlog |
| **NVC** | Carrier / Transporter | Nhà vận tải | Bên thứ 3 chở hàng |
| **Tender** | Tender | Gửi thầu | Quá trình gửi yêu cầu chuyến đến NVC để lấy báo giá/cam kết |
| **TenderMasterID** | — | Mã chuyến gửi thầu | ID kế hoạch gửi thầu (cấp tender) |
| **MasterCode** | — | Mã chuyến vận hành | ID chuyến vận hành thực tế (cấp operational); 1 tender → 1 master code (hoặc N nếu split) |
| **Trip / Chuyến** | Trip | Chuyến | 1 lần vận chuyển hàng hóa từ kho đến điểm giao |
| **so_chuyen** | — | Số chuyến | Mã trip dùng trong SQL của MV late-order |
| **FTL** | Full Truck Load | Xe đầy tải | 1 chuyến cho 1 khách |
| **LTL** | Less Than Truckload | Xe ghép | 1 chuyến nhiều khách |
| **Multi-leg trip** | — | Chuyến nhiều chặng | 1 trip có nhiều leg (kho → DC → khách); ~80% SO Mondelez là multi-leg |

### Timestamps

| Viết tắt | Tên tiếng Anh | Mô tả | Cột SQL liên quan |
|---------|---------------|------|------------------|
| **ETD** | Estimated Time of Departure | Giờ rời kho dự kiến | `etd_chuyen_gui_thau`, `etd_chuyen` |
| **ATD** | Actual Time of Departure | Giờ rời kho thực tế | `gio_ra_cong` (canonical, dock register) — **KHÔNG phải** `atd_chuyen` |
| **ETA** | Expected Time of Arrival | Giờ đến dự kiến | `eta` |
| **ATA** | Actual Time of Arrival | Giờ đến thực tế | `ata_roi`, `stm_ata_den` |
| **Deadline rời kho** | — | Giờ bắt buộc xe phải rời cổng | `tg_bat_buoc_roi_kho` |

---

## Kho & vận hành kho (WMS = SWM)

| Viết tắt | Tên tiếng Anh | Tên tiếng Việt | Mô tả |
|---------|---------------|---------------|------|
| **SWM** | Smart Warehouse Management | Hệ thống kho | Hệ thống WMS của Smartlog |
| **Whseid** | Warehouse ID | Mã kho | ID định danh 1 kho (vd `BKD1`, `NKD`) |
| **SLOC** | Storage Location | Mã vị trí kho | Bin code chi tiết bên trong kho |
| **DC** | Distribution Center | Trung tâm phân phối | Tương đương khái niệm warehouse cấp vùng |
| **Allocated** | Allocated | Đã phân bổ | CSE đã gán cho đơn nhưng chưa pick |
| **Picked** | Picked | Đã pick | CSE đã lấy khỏi vị trí, chờ pack/ship |
| **Loose Picking** | Loose Picking | Lấy hàng lẻ | Pick từng CSE/PCE thay vì cả pallet — chậm hơn nhiều |
| **Full Pallet** | Full Pallet | Pallet đầy đủ | Pallet đủ quy cách, không cần xé lẻ |
| **Stock Type** | Stock Type | Loại tồn kho | Phân loại tồn theo nhóm hàng/brand |
| **Copack** | Co-pack | Đóng gói lại | Tái đóng gói/repack sản phẩm theo yêu cầu |
| **Factory Inbound** | Factory Inbound | Hàng nhập từ nhà máy | Pallet nhập kho từ nhà máy Mondelez |
| **Transfer** | Transfer | Chuyển kho nội bộ | Di chuyển hàng giữa các kho/DC nội bộ |
| **Transaction Move / Txn Move** | Movement Transaction | Giao dịch nhập/xuất | Tổng các movement nhập/xuất kho |

---

## Khách hàng / Sales channel

| Viết tắt | Tên tiếng Anh | Tên tiếng Việt | Mô tả |
|---------|---------------|---------------|------|
| **NPP** | Distributor | Nhà phân phối | Cấp phân phối lớn của Mondelez |
| **KA** | Key Account | Khách hàng chiến lược | (vd siêu thị lớn, chuỗi) |
| **MT** | Modern Trade | Kênh hiện đại | Siêu thị, cửa hàng tiện lợi |
| **GT** | General Trade | Kênh truyền thống | Chợ, tiệm tạp hóa |

Cột phân loại trong DB: `kenh_ban_hang`, `group_name`.

---

## Sản phẩm / Master data

| Field | Mô tả |
|-------|------|
| `item_code` | Mã SKU |
| `product_name` | Tên SKU |
| `brand` | Thương hiệu (xem `05-master-data.md` để biết list 10 brands) |
| `group_of_cargo` / `cargo_group` | Nhóm hàng (FRESH / DRY / MOONCAKE / POSM / PM / TEST / EQUIPMENT) |
| `customer_code`, `customer_name` | Mã + tên khách |

---

## Tham chiếu nhanh

- **STM** = Smart **Transport** Management = TMS
- **SWM** = Smart **Warehouse** Management = WMS
- Khi BA viết PRD: viết `DO` (không viết `Delivery Order` lặp đi lặp lại) sau khi giải thích ở đầu.
- Khi DEV trong code: dùng `delivery_order_*` snake_case ở DB, `deliveryOrder*` camelCase ở FE.
