# TMS #25 — Báo cáo theo đơn hàng và chuyến

> **Trạng thái:** 🟢 đầy đủ. Hồ sơ kiến thức "trải phẳng" để hiểu trọn ngữ cảnh, định nghĩa trường, rule ghép/tổng hợp và cách phân tích — không cần mở link ngoài.

| Định danh | Giá trị |
|---|---|
| Số (TypeExport) | 25 |
| Code | REPDIOPSPlan |
| functionid | 78 |
| Tên | Báo cáo theo đơn hàng và chuyến |
| Slug | trip-and-order |
| File output | `REPDIOPSPlan_25_TripAndOrder.xlsx` (144 cột) |
| Đơn vị dữ liệu (grain) | **1 dòng = 1 cặp duy nhất `MasterCode × OrderCode`** (chuyến × đơn) |

**Liên quan:** [144 cột thực xuất](25-tms-trip-and-order.columns.md) · [API contract](25-tms-trip-and-order.api.md) · payload mẫu `samples/request.json`

---

## 1. Mục tiêu & phạm vi

Báo cáo 25 dùng để **đối soát vận hành**: theo dõi hành trình lấy–giao, trạng thái POD, đối chiếu DN/SO, nhà vận tải, sản lượng (số lượng / CBM / Tấn), cảnh báo trễ, và các thuộc tính khách – NPP – điểm.

- **Phân quyền dữ liệu:** theo Khách hàng, Kho nhận, Nhà xe (nếu có cấu hình phân quyền theo tổ chức/điểm).

## 2. Nguyên tắc dữ liệu & hiển thị

- **Không trùng dòng:** mỗi dòng là duy nhất theo cặp `MasterCode × OrderCode`.
- **Nối chuỗi (concat):** trường có nhiều giá trị trên cùng cặp (nhiều điểm lấy/giao, nhiều DN…) → nối bằng dấu `,`, **distinct**, ưu tiên thứ tự thời gian hoặc thứ tự tự nhiên theo chuyến.
- **Tổng hợp (sum):** các trường "Tổng …" cộng trên tất cả chi tiết thuộc cặp; trường chi tiết dùng nối chuỗi.
- **TypeOfDate:** chỉ ảnh hưởng *phạm vi dữ liệu* (lọc theo mốc ngày), **không** đổi logic tính trường.
- **PODStatus:** gom nhóm theo bộ trường `Invoice*` / `POD*` — xem §5.

## 3. Loại ngày & bộ lọc

### 3.1 TypeOfDate (loại ngày xuất báo cáo)

| Nhãn nghiệp vụ | Field áp dụng | Rule lọc |
|---|---|---|
| ETD đơn hàng | `[ETD]` | dòng có ETD đơn của OrderCode trong khoảng `from–to` |
| ETA đơn hàng | `[ETA]` | dòng có ETA đơn của OrderCode trong khoảng `from–to` |
| ATD chuyến | `[MasterATD]` | dòng có ATD chuyến của MasterCode trong khoảng `from–to` |
| ATA chuyến | `[MasterATA]` | dòng có ATA chuyến của MasterCode trong khoảng `from–to` |

> Bản đồ số↔nhãn xem [_shared/date-params.md](../../_shared/date-params.md). Payload mẫu #25 dùng `TypeOfDate=9`.

### 3.2 Bộ lọc thường dùng

Khách hàng · Nhà vận tải · Xe · Kho nhận/Kho đi · Loại NPP · NPP · Điểm giao · Trạng thái chuyến · Trạng thái chi tiết chuyến · Cảnh báo trễ ("Trễ lấy hàng", "Trễ giao hàng"). Danh mục code đầy đủ: [_shared/filters.md](../../_shared/filters.md).

- **Config "Lấy thêm dữ liệu chiều về":** khi bật, ngoài dữ liệu thỏa lọc, xuất thêm đơn/chuyến chiều về có Kho nhận / Loại NPP / NPP / Điểm giao **đối xứng** với chiều đi.

## 4. Danh mục trường dữ liệu

> Đây là *từ điển trường* (gồm cả trường tương thích với báo cáo lân cận 26/38). Tập cột **thực xuất** của file #25 (144 cột, theo thứ tự) nằm ở [columns.md](25-tms-trip-and-order.columns.md).

### 4.1 Nhận diện đơn & chuyến

| Code | Tên | Kiểu | Mô tả & rule |
|---|---|---|---|
| `[OrderCode]` | Mã đơn hàng | String | Định danh đơn; lấy theo đơn thuộc chi tiết chuyến trong cặp |
| `[MasterCode]` | Mã chuyến | String | Định danh chuyến; lấy từ chuyến chứa đơn |
| `[OrderStatus]` | Trạng thái đơn | String | Trạng thái tổng thể của đơn |
| `[MasterStatus]` | Trạng thái chuyến | String | Trạng thái chuyến tại thời điểm xuất |
| `[ExternalCode]` | Mã giao dịch | String | Mã ngoại hệ (SAP/ERP), ưu tiên theo đơn |
| `[ExternalDate]` | Ngày giao dịch | DateTime | Timestamp ghi nhận giao dịch |
| `[SOCode]` | Số SO | String | Sales Order; nối chuỗi distinct theo chi tiết đơn |
| `[DNCode]` | Số DN | String | Delivery Note; nối chuỗi distinct theo chi tiết đơn |

### 4.2 Thời gian kế hoạch/thực tế

| Code | Tên | Kiểu | Mô tả & rule |
|---|---|---|---|
| `[ETD]` | ETD đơn hàng | DateTime | Dự kiến lấy; nhiều chi tiết → sớm nhất |
| `[ETA]` | ETA đơn hàng | DateTime | Dự kiến giao; nhiều chi tiết → muộn nhất |
| `[DateFromCome]` / `[DateFromLeave]` | Đến / Rời điểm lấy (thực tế) | DateTime | Nối chuỗi theo thời gian tăng dần |
| `[DateToCome]` / `[DateToLeave]` | Đến / Rời điểm giao (thực tế) | DateTime | Nối chuỗi theo thời gian tăng dần |
| `[MasterETD]` / `[MasterETA]` | ETD / ETA chuyến | DateTime | Tổng của chuyến (cấp chuyến) |
| `[MasterATD]` / `[MasterATA]` | ATD / ATA chuyến | DateTime | Mốc rời / đến thực tế của chuyến |

### 4.3 Khách hàng, NPP, điểm & khu vực

| Code | Tên | Kiểu | Mô tả & rule |
|---|---|---|---|
| `[CustomerCode]` / `[CustomerName]` | Mã / Tên khách hàng | String | Theo masterdata khách của đơn |
| `[PartnerToCode]` / `[PartnerToName]` | Mã / Tên NPP giao | String | Nối chuỗi distinct theo chi tiết chuyến |
| `[GroupOfPartnerName]` | Loại NPP | String | Nối chuỗi distinct |
| `[StockCode]` / `[StockName]` | Mã / Tên điểm lấy | String | Nối chuỗi theo chi tiết đơn |
| `[ORDLocationFromCode/Name]` | Điểm lấy của đơn | String | Cấp chi tiết đơn; nối chuỗi |
| `[ORDLocationToCode/Name]` | Điểm giao của đơn | String | Cấp chi tiết đơn; nối chuỗi |
| `[LocationToAddress]` | Địa chỉ điểm giao | String | Nối chuỗi theo chi tiết chuyến |
| `[LocationToDistrict]` / `[LocationToProvince]` | Quận huyện / Tỉnh giao | String | Nối chuỗi distinct |
| `[LocationToArea]` | Zone | String | Map tỉnh/quận điểm giao vào polygon; nối chuỗi distinct |
| `[LocationToUnloadingTypeName]` | Loại bốc xếp | String | Nối chuỗi theo chi tiết chuyến |

### 4.4 Nhà vận tải, xe & tài xế

| Code | Tên | Kiểu | Mô tả & rule |
|---|---|---|---|
| `[VendorCode]` / `[VendorName]` / `[VendorShortName]` | Nhà vận tải | String | Lấy theo chuyến |
| `[GroupVehicleName]` | Loại xe | String | Theo phương tiện gán cho chuyến |
| `[VehicleRegNo]` | Số xe | String | Biển số, theo chuyến |
| `[VehicleMaxWeight]` | Trọng tải xe | Number | Theo masterdata xe |
| `[DriverName]` / `[DriverTel]` | Tài xế / SĐT | String | Theo chuyến |

### 4.5 Hàng hóa & nhóm hàng

| Code | Tên | Kiểu | Mô tả & rule |
|---|---|---|---|
| `[GroupOfProductCode/Name]` | Nhóm hàng | String | Nối chuỗi distinct theo chi tiết chuyến |
| `[ProductCode]` / `[ProductName]` / `[ProductDescription]` | Hàng hóa | String | Nối chuỗi theo chi tiết |

### 4.6 Sản lượng, quy đổi & COD

| Code | Tên | Kiểu | Mô tả & rule |
|---|---|---|---|
| `[QuantityOrder]` | Số lượng yêu cầu | Number | Sum cấp đơn (kế hoạch) |
| `[QuantityTransfer]` | Số lượng lấy | Number | Sum theo chi tiết chuyến |
| `[QuantityReturn]` | Số lượng trả về | Number | Sum theo chi tiết chuyến |
| `[QuantityBBGN]` | Số lượng giao | Number | Sum theo chi tiết chuyến (đã giao BBGN) |
| `[QuantityConfig]` / `[QuantityConfig1]` | Số lượng quy đổi 1 / 2 | Number | Sum theo rule quy đổi cấu hình (vd pallet) |
| `[CODUnitAmount]` | Giá trị hàng hóa giao | Number | Sum(UnitPrice × QuantityBBGN) theo chi tiết |
| `[ProductPrice]` | COD cần thu | Number | Sum theo chi tiết đơn; không áp dụng → 0 |
| `[ActualProductPrice]` | COD thực thu | Number | Sum theo xác nhận thu COD |

### 4.7 Chứng từ & trạng thái POD

| Code | Tên | Kiểu | Mô tả & rule |
|---|---|---|---|
| `[InvoiceNo]` | Số chứng từ | String | Nối chuỗi distinct theo chi tiết |
| `[InvoiceBy]` | Người nhận chứng từ | String | Nối chuỗi distinct |
| `[InvoiceDate]` | Ngày nhận chứng từ | DateTime | Sớm nhất trên các chứng từ |
| `[InvoiceReturnDate]` | Ngày nhận bản gốc trả về | DateTime | Sớm nhất |
| `[InvoiceNote]` / `[InvoiceReturnNote]` | Ghi chú chứng từ / bản gốc | String | Nối chuỗi |
| `[PODStatus]` | Tình trạng chứng từ | String | Tổng hợp — xem §5 |

### 4.8 Ghi chú & trường mở rộng

| Code | Tên | Mô tả & rule |
|---|---|---|
| `[OrderNote1..6]` | Ghi chú đơn 1..6 | Cấp đơn; nhiều chi tiết → nối chuỗi distinct |
| `[ORDNote1..5]` | Ghi chú chi tiết đơn 1..5 | Nối chuỗi theo chi tiết |
| `[UserDefine1]` | PO No. | Trường mở rộng đơn |
| `[UserDefine3]` | Sale Order Date | Ngày SO |
| `[UserDefine4]` | Request Date | Ngày yêu cầu |
| `[UserDefine5]` | Deadline Date | Hạn chót |

### 4.9 Mã vận hành & đồng bộ

| Code | Tên | Mô tả & rule |
|---|---|---|
| `[CodeSync]` | CodeSync | Mã đồng bộ chi tiết chuyến; nối chuỗi |
| `[MasterApiCode]` | Mã chuyến SAP | Mã tích hợp cấp chuyến |

### 4.10 Trường tương thích khác

`[TenderMasterID]`, `[TenderMasterIDGroupOfVehicle]`, `[MasterTimeSlotName]`, `[MasterTimeSlotTimeFrom]`, `[MasterTimeSlotTimeTo]`: nếu bật timeslot/gửi thầu → lấy theo chuyến; nhiều giá trị → nối chuỗi.

## 5. Quy tắc tính PODStatus

| Điều kiện | Kết quả |
|---|---|
| Không có bản ghi chứng từ POD nào | **Chưa có POD** |
| Có chứng từ điện tử (`InvoiceDate` có giá trị), chưa trả bản gốc | **Đã nhận POD điện tử** |
| Có bản gốc trả về (`InvoiceReturnDate` có giá trị) | **Đã nhận POD gốc** |
| Có chứng từ nhưng có ghi chú lỗi/thiếu bắt buộc | **POD lỗi/thiếu** |

> Nhiều dòng chứng từ cho cùng cặp → ưu tiên đánh giá theo thứ tự: **POD lỗi/thiếu → Đã nhận POD gốc → Đã nhận POD điện tử → Chưa có POD**.

## 6. Cảnh báo trễ

- **Trễ lấy hàng:** dòng có chi tiết chuyến gắn cờ trễ tại điểm lấy.
- **Trễ giao hàng:** dòng có chi tiết chuyến gắn cờ trễ tại điểm giao.
- Bật bộ lọc cảnh báo → chỉ xuất dòng có ít nhất một chi tiết mang cờ tương ứng.

## 7. Chuẩn hóa nối chuỗi & tổng hợp

- **Nối chuỗi:** dấu `,`, bỏ trùng, sắp xếp tăng dần theo thời gian / thứ tự điểm trong chuyến.
- **Tổng hợp:** `Quantity*`, `COD*`, CBM/Tấn cộng trên toàn bộ chi tiết thuộc cặp.
- **Định dạng ngày:** `dd/MM/yyyy HH:mm`. **Số:** thập phân `.`, không kèm đơn vị trong ô số.

## 8. Hướng dẫn phân tích

**Câu hỏi mẫu:**
- Đơn "Chưa có POD" quá X ngày kể từ ATA chuyến.
- "Trễ giao hàng" theo Vendor / Tỉnh-Zone / Nhóm hàng.
- Chênh lệch `QuantityOrder` vs `QuantityBBGN` theo khách/NPP.
- COD cần thu vs thực thu theo ngày/tuần/tháng.
- Top điểm giao nhiều DN/đơn nhất (mức phân mảnh giao hàng).

**Góc nhìn:** Vận hành (mốc lấy–giao, cảnh báo trễ, trạng thái chuyến) · Dịch vụ (tỷ lệ POD đúng hạn, chất lượng chứng từ) · Thương mại (sản lượng theo nhóm hàng/NPP/khu vực, lệch kế hoạch–thực tế) · Tài chính (đối soát DN/SO, COD thu–chi).

## 9. Ví dụ logic tổng hợp

- **Ghép nhiều điểm giao vào 1 dòng:** Đơn A trong chuyến M có 2 điểm giao G1, G2 → `DateToCome = "01/06/2026 09:10, 01/06/2026 10:35"`; `ORDLocationToCode = "G1, G2"`; `QuantityBBGN = Sum(G1 + G2)`.
- **COD:** `CODUnitAmount = Sum(UnitPrice × QuantityBBGN)` theo chi tiết; `ProductPrice` = COD cần thu theo đơn; `ActualProductPrice` = COD thực thu.

## 10. FAQ

- **Vì sao một dòng có nhiều DN?** Cặp `MasterCode × OrderCode` có nhiều chi tiết đơn/điểm giao → DN nối chuỗi distinct.
- **ETD/ETA đơn vs chuyến khác nhau?** Đúng — đơn ở cấp đơn hàng, chuyến ở cấp chuyến.
- **PODStatus "POD lỗi/thiếu" dù có `InvoiceReturnDate`?** Do tồn tại ghi chú lỗi/thiếu bắt buộc; rule ưu tiên gán "POD lỗi/thiếu".
