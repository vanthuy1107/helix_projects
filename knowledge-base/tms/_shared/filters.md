# TMS — Từ điển bộ lọc (ListFilterAvailable)

Mỗi report khai báo `item.ListFilterAvailable` — danh sách code filter UI cho phép. Dưới đây là 40 code xuất hiện ở báo cáo #25 (gloss tiếng Việt best-effort; nhãn chuẩn theo UI TMS).

| Code | Ý nghĩa |
|---|---|
| `Vehicle` | Xe (biển số) |
| `Customer` | Khách hàng |
| `CustomerExclude` | Loại trừ khách hàng |
| `Vendor` | Nhà vận tải |
| `OfficeRouting` | Văn phòng / routing |
| `GroupProduct` | Nhóm hàng |
| `Stock` | Kho / điểm lấy |
| `AreaTo` | Khu vực giao |
| `LocationTo` | Điểm giao |
| `LocationHub` | Điểm hub |
| `Partner` | Đối tác (NPP) |
| `Province` | Tỉnh / thành |
| `District` | Quận / huyện |
| `ServiceOfOrder` | Dịch vụ của đơn |
| `OrderRouting` | Routing đơn |
| `OPSRouting` | Routing vận hành |
| `VendorLoadUnload` | Nhà thầu bốc xếp |
| `TypeOfOrder` | Loại đơn hàng |
| `TransportModeOrder` | Phương thức vận chuyển (đơn) |
| `SYSCustomer` | Khách hàng hệ thống |
| `OrderOfficeOwner` | Văn phòng sở hữu đơn |
| `MasterOfficeRental` | Văn phòng thuê (chuyến) |
| `MasterOfficeOwner` | Văn phòng sở hữu (chuyến) |
| `TransportModeCost` | Phương thức vận chuyển (chi phí) |
| `GroupOfPartner` | Nhóm đối tác / loại NPP |
| `GroupOfLocation` | Nhóm điểm |
| `BiddingStatus` | Trạng thái đấu thầu |
| `TripStatus` | Trạng thái chuyến |
| `DetailStatus` | Trạng thái chi tiết chuyến |
| `TransportModeContractMaster` | Phương thức VC (hợp đồng master) |
| `BranchPL` | Chi nhánh P&L |
| `TransportType` | Loại hình vận tải |
| `TypeGroup` | Nhóm loại |
| `ProductStatus` | Trạng thái hàng hóa |
| `RouteSplit` | Tách tuyến |
| `TenderOrder` | Đơn gửi thầu |
| `KindProduct` | Loại sản phẩm |
| `DockRegisterStatus` | Trạng thái đăng ký dock |
| `CUSPayer` | Bên thanh toán (khách) |
| `MasterGroupOfVehicle` | Nhóm xe (master) |

> Trong payload, mỗi filter ứng với một mảng `List<Tên>` (vd `ListCustomer`, `ListVendor`). Để trống `[]` = không lọc theo chiều đó.
