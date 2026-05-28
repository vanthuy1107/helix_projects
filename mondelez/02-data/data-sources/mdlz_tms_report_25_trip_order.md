# ClickHouse table ? `analytics_workspace.mdlz_tms_report_25_trip_order`

> B?ng staging ch?a d? li?u **TMS report #25** (B?o c?o theo ??n h?ng v? chuy?n) c?a **Mondelez** ?? ??i chi?u trong ClickHouse.
> Sinh/n?p b?ng `mondelez/scripts/load_tms_report_to_ch.py`. Schema canonical: `knowledge-base/tms/reports/25-trip-and-order/25-tms-trip-and-order.columns.json`.

## T?ng quan

| H?ng m?c | Gi? tr? |
|---|---|
| Database.Table | `analytics_workspace.mdlz_tms_report_25_trip_order` |
| Engine | `MergeTree` ORDER BY (`MasterCode`, `OrderCode`) |
| S? c?t | 144 c?t d? li?u (String) + 2 c?t meta |
| Ki?u c?t | T?t c? `String` (staging trung th?c; c? th? layer view typed sau) |
| Ngu?n | `REPDIOPSPlan_SettingDownload` (functionid=78, TypeExport=25) ? xem [knowledge-base #25](../../../../knowledge-base/tms/reports/25-trip-and-order/25-tms-trip-and-order.md) |
| Refresh | **TRUNCATE + reload** to?n b? m?i l?n ch?y (ghi ??) |
| Chunk ngu?n | C?a s? **?5 ng?y**/l?n g?i (ngh? 3s gi?a c?c l?n) ?? nh? cho h? ngu?n |
| C?t meta | `_src_window` (c?a s? ng?y ngu?n), `_loaded_at` (th?i ?i?m n?p) |

## C?ch ch?y

```bash
python projects/mondelez/scripts/load_tms_report_to_ch.py --from 2026-05-01 --to 2026-05-26
python projects/mondelez/scripts/load_tms_report_to_ch.py --recreate   # DROP + t?o l?i khi ??i schema/comment
```

## L?u ?

- C?t l? `String` trung th?c theo file export (ng?y `dd/MM/yyyy HH:mm`, s? d?ng `.`); c?n cast khi so s?nh v?i MV typed.
- C?c c?a s? ng?y **r?i nhau** (disjoint) n?n kh?ng tr?ng d?ng gi?a c?c l?n g?i (l?c theo `TypeOfDate`).
- `COMMENT` t?ng c?t = t?n hi?n th? ti?ng Vi?t; xem ng? ngh?a/rule ??y ?? ? [columns.md](../../../../knowledge-base/tms/reports/25-trip-and-order/25-tms-trip-and-order.columns.md).
- ??i c?u tr?c c?t: c?p nh?t `columns.json` r?i ch?y l?i v?i `--recreate`, v? regen file n?y.

## DDL

```sql
CREATE TABLE IF NOT EXISTS `analytics_workspace`.`mdlz_tms_report_25_trip_order` (
  `STT` String COMMENT 'STT',
  `MasterCode` String COMMENT 'Mã chuyến',
  `MasterCodeRoute1` String COMMENT 'Mã chuyến chặng 1',
  `MasterStatus` String COMMENT 'Trạng thái chuyến',
  `MasterNote` String COMMENT 'Ghi chú chuyến',
  `MasterNote1` String COMMENT 'Ghi chú chuyến 1',
  `MasterNote2` String COMMENT 'Ghi chú chuyến 2',
  `MasterNote3` String COMMENT 'Ghi chú chuyến 3',
  `MasterNote4` String COMMENT 'Ghi chú chuyến 4',
  `MasterNote5` String COMMENT 'Ghi chú chuyến 5',
  `MasterETD` String COMMENT 'ETD chuyến',
  `MasterETA` String COMMENT 'ETA chuyến',
  `MasterATD` String COMMENT 'ATD chuyến',
  `MasterATA` String COMMENT 'ATA chuyến',
  `KM` String COMMENT 'KM',
  `KMGPS` String COMMENT 'KMGPS',
  `KMGPSMobile` String COMMENT 'KMGPSMobile',
  `VehicleRegNoStage1` String COMMENT 'Số xe',
  `GroupOfVehicleCode` String COMMENT 'Mã loại xe',
  `GroupOfVehicleName` String COMMENT 'Tên loại xe',
  `VehicleMaxWeightStage1` String COMMENT 'Trọng tải',
  `VehicleNote` String COMMENT 'Ghi chú xe',
  `DriverNameStage1` String COMMENT 'Tên tài xế',
  `DriverTelStage1` String COMMENT 'SĐT tài xế',
  `DriverName2` String COMMENT 'Tên phụ lái',
  `DriverName3` String COMMENT 'Tên bốc xếp',
  `VendorCode` String COMMENT 'Mã nhà xe',
  `VendorName` String COMMENT 'Tên nhà xe',
  `VendorShortName` String COMMENT 'Tên ngắn nhà xe',
  `TenderedDate` String COMMENT 'Thời gian gửi thầu',
  `DeliveryStatus` String COMMENT 'Trạng thái giao hàng',
  `QuantityOrder` String COMMENT 'Số lượng kế hoạch',
  `QuantityTransfer` String COMMENT 'Số lượng lấy',
  `QuantityBBGN` String COMMENT 'Số lượng giao',
  `TonOrder` String COMMENT 'Tấn kế hoạch',
  `TonTransfer` String COMMENT 'Tấn lấy',
  `TonBBGN` String COMMENT 'Tấn giao',
  `CBMOrder` String COMMENT 'Khối kế hoạch',
  `CBMTransfer` String COMMENT 'Khối lấy',
  `CBMBBGN` String COMMENT 'Khối giao',
  `ReasonDeliveryName` String COMMENT 'Nguyên nhân chênh lệch SL giao',
  `ORDLocationFromCode` String COMMENT 'Mã điểm lấy của đơn',
  `ORDLocationFromName` String COMMENT 'Tên điểm lấy của đơn',
  `ORDLocationToCode` String COMMENT 'Mã điểm giao của đơn',
  `ORDLocationToName` String COMMENT 'Tên điểm giao của đơn',
  `StockCode` String COMMENT 'Mã điểm lấy',
  `StockName` String COMMENT 'Tên điểm lấy',
  `StockAddress` String COMMENT 'Địa chỉ điểm lấy',
  `OPSLocationToCode` String COMMENT 'Mã điểm giao',
  `OPSLocationToName` String COMMENT 'Tên điểm giao',
  `OPSLocationToAddress` String COMMENT 'Địa chỉ điểm giao',
  `OPSLocationToProvince` String COMMENT 'Tỉnh điểm giao',
  `OPSLocationToDistrict` String COMMENT 'Quận điểm giao',
  `OPSLocationToNote` String COMMENT 'Ghi chú điểm giao',
  `OPSLocationToCellphone` String COMMENT 'SĐT điểm giao',
  `GroupOfLocationToCode` String COMMENT 'Mã loại điểm giao',
  `GroupOfLocationToName` String COMMENT 'Tên loại điểm giao',
  `PartnerToCode` String COMMENT 'Mã hệ thống của nhà phân phối',
  `GroupOfPartnerName` String COMMENT 'Nhóm nhà phân phối',
  `DistributorTypeModelName` String COMMENT 'Mô hình nhà phân phối',
  `LocationToUnloadingTypeName` String COMMENT 'Loại bốc xếp',
  `RoutingAreaToCode` String COMMENT 'Khu vực giao',
  `DateFromCome` String COMMENT 'Ngày đến điểm lấy',
  `DateFromLoadStart` String COMMENT 'Ngày bắt đầu load hàng điểm lấy',
  `DateFromLoadEnd` String COMMENT 'Ngày hoàn tất load hàng điểm lấy',
  `DateFromLeave` String COMMENT 'Ngày đi (rời) điểm lấy',
  `DateToCome` String COMMENT 'Ngày đến điểm giao',
  `DateToLoadStart` String COMMENT 'Ngày bắt đầu load hàng điểm giao',
  `DateToLoadEnd` String COMMENT 'Ngày hoàn tất load hàng điểm giao',
  `DateToLeave` String COMMENT 'Ngày đi (rời) điểm giao',
  `DateComeEstimateFrom` String COMMENT 'Ngày đến điểm lấy dự kiến',
  `DateLeaveEstimateFrom` String COMMENT 'Ngày đi (rời) điểm lấy dự kiến',
  `DateComeEstimateTo` String COMMENT 'Ngày đến điểm giao dự kiến',
  `DateLeaveEstimateTo` String COMMENT 'Ngày đi (rời) điểm giao dự kiến',
  `TripTempRoom1` String COMMENT 'Nhiệt độ ngăn 1',
  `TripTempRoom2` String COMMENT 'Nhiệt độ ngăn 2',
  `OPSGroupNote` String COMMENT 'Ghi chú chi tiết chuyến',
  `OPSGroupNote1` String COMMENT 'Ghi chú chi tiết chuyến 1',
  `OPSGroupNote2` String COMMENT 'Ghi chú chi tiết chuyến 2',
  `PODStatus` String COMMENT 'Trạng thái chứng từ',
  `InvoiceDate` String COMMENT 'Ngày nhận chứng từ',
  `InvoiceBy` String COMMENT 'Người nhận chứng từ',
  `HasUpload` String COMMENT 'Đã up hình chứng từ',
  `InvoiceNote` String COMMENT 'Ghi chú chứng từ',
  `InvoiceMissingNote` String COMMENT 'Ghi chú thiếu chứng từ',
  `OrderCode` String COMMENT 'Mã đơn hàng',
  `VesselNo` String COMMENT 'Mã tàu',
  `VesselName` String COMMENT 'Tên tàu',
  `ServiceOfOrderCode` String COMMENT 'Mã dịch vụ',
  `ServiceOfOrderName` String COMMENT 'Tên dịch vụ',
  `TransportModeCode` String COMMENT 'Mã loại hình vận chuyển',
  `TransportModeName` String COMMENT 'Tên loại hình vận chuyển',
  `OrderCreatedBy` String COMMENT 'Người tạo đơn',
  `OrderCreatedDate` String COMMENT 'Ngày tạo đơn',
  `OrderType` String COMMENT 'Loại đơn hàng',
  `OrderStatus` String COMMENT 'Trạng thái đơn',
  `ReasonCancel` String COMMENT 'Lý do huỷ đơn',
  `ReasonCancelNote` String COMMENT 'Ghi chú lý do huỷ đơn',
  `OrderNote` String COMMENT 'Ghi chú đơn hàng',
  `RequestDate` String COMMENT 'Ngày yêu cầu vận chuyển',
  `ETD` String COMMENT 'ETD đơn',
  `ETA` String COMMENT 'ETA đơn',
  `OrderContract` String COMMENT 'Hợp đồng đơn hàng',
  `PaymentMethod` String COMMENT 'Phương thức thanh toán',
  `SORefCode` String COMMENT 'Số SO',
  `CustomerCode` String COMMENT 'Mã khách hàng',
  `CustomerName` String COMMENT 'Tên khách hàng',
  `CustomerShortName` String COMMENT 'Tên ngắn khách hàng',
  `TextLocationFromCode` String COMMENT 'Text mã điểm nhận',
  `TextLocationFromName` String COMMENT 'Text tên điểm nhận',
  `TextLocationFromAddress` String COMMENT 'Text địa chỉ điểm nhận',
  `TextLocationFromProvinceCode` String COMMENT 'Text mã tỉnh thành điểm nhận',
  `TextLocationFromProvinceName` String COMMENT 'Text tên tỉnh thành điểm nhận',
  `TextLocationFromDistrictCode` String COMMENT 'Text mã quận huyện điểm nhận',
  `TextLocationFromDistrictName` String COMMENT 'Text tên quận huyện điểm nhận',
  `TextLocationFromWardCode` String COMMENT 'Text mã xã phường điểm nhận',
  `TextLocationFromWardName` String COMMENT 'Text tên xã phường điểm nhận',
  `TextLocationToCode` String COMMENT 'Text mã điểm giao',
  `TextLocationToName` String COMMENT 'Text tên điểm giao',
  `TextLocationToAddress` String COMMENT 'Text địa chỉ điểm giao',
  `TextLocationToProvinceCode` String COMMENT 'Text mã tỉnh thành điểm giao',
  `TextLocationToProvinceName` String COMMENT 'Text tên tỉnh thành điểm giao',
  `TextLocationToDistrictCode` String COMMENT 'Text mã quận huyện điểm giao',
  `TextLocationToDistrictName` String COMMENT 'Text tên quận huyện điểm giao',
  `TextLocationToWardCode` String COMMENT 'Text mã xã phường điểm giao',
  `TextLocationToWardName` String COMMENT 'Text tên xã phường điểm giao',
  `ORDTextLocationFromCode` String COMMENT 'Text mã điểm nhận chi tiết đơn',
  `ORDTextLocationFromName` String COMMENT 'Text tên điểm nhận chi tiết đơn',
  `ORDTextLocationFromAddress` String COMMENT 'Text địa chỉ điểm nhận chi tiết đơn',
  `ORDTextLocationFromProvinceCode` String COMMENT 'Text mã tỉnh thành điểm nhận chi tiết đơn',
  `ORDTextLocationFromProvinceName` String COMMENT 'Text tên tỉnh thành điểm nhận chi tiết đơn',
  `ORDTextLocationFromDistrictCode` String COMMENT 'Text mã quận huyện điểm nhận chi tiết đơn',
  `ORDTextLocationFromDistrictName` String COMMENT 'Text tên quận huyện điểm nhận chi tiết đơn',
  `ORDTextLocationFromWardCode` String COMMENT 'Text mã xã phường điểm nhận chi tiết đơn',
  `ORDTextLocationFromWardName` String COMMENT 'Text tên xã phường điểm nhận chi tiết đơn',
  `ORDTextLocationToCode` String COMMENT 'Text mã điểm giao chi tiết đơn',
  `ORDTextLocationToName` String COMMENT 'Text tên điểm giao chi tiết đơn',
  `ORDTextLocationToAddress` String COMMENT 'Text địa chỉ điểm giao chi tiết đơn',
  `ORDTextLocationToProvinceCode` String COMMENT 'Text mã tỉnh thành điểm giao chi tiết đơn',
  `ORDTextLocationToProvinceName` String COMMENT 'Text tên tỉnh thành điểm giao chi tiết đơn',
  `ORDTextLocationToDistrictCode` String COMMENT 'Text mã quận huyện điểm giao chi tiết đơn',
  `ORDTextLocationToDistrictName` String COMMENT 'Text tên quận huyện điểm giao chi tiết đơn',
  `ORDTextLocationToWardCode` String COMMENT 'Text mã xã phường điểm giao chi tiết đơn',
  `ORDTextLocationToWardName` String COMMENT 'Text tên xã phường điểm giao chi tiết đơn',
  `_src_window` String COMMENT 'Cửa sổ ngày nguồn (yyyy-mm-dd..yyyy-mm-dd)',
  `_loaded_at` DateTime DEFAULT now() COMMENT 'Thời điểm nạp dữ liệu'
)
ENGINE = MergeTree
ORDER BY (`MasterCode`, `OrderCode`)
COMMENT 'MDLZ TMS report #25 (Bao cao theo don hang va chuyen) - staging dump String trung thuc. Refresh: TRUNCATE+reload theo cua so <=5 ngay. Nguon: REPDIOPSPlan_SettingDownload functionid=78 TypeExport=25. Doc: mondelez/02-data/data-sources/mdlz_tms_report_25_trip_order.md'
```

## C?t (T?n hi?n th? ? CH column)

| # | CH column | COMMENT (t?n hi?n th?) |
|---|---|---|
| 1 | `STT` | STT |
| 2 | `MasterCode` | Mã chuyến |
| 3 | `MasterCodeRoute1` | Mã chuyến chặng 1 |
| 4 | `MasterStatus` | Trạng thái chuyến |
| 5 | `MasterNote` | Ghi chú chuyến |
| 6 | `MasterNote1` | Ghi chú chuyến 1 |
| 7 | `MasterNote2` | Ghi chú chuyến 2 |
| 8 | `MasterNote3` | Ghi chú chuyến 3 |
| 9 | `MasterNote4` | Ghi chú chuyến 4 |
| 10 | `MasterNote5` | Ghi chú chuyến 5 |
| 11 | `MasterETD` | ETD chuyến |
| 12 | `MasterETA` | ETA chuyến |
| 13 | `MasterATD` | ATD chuyến |
| 14 | `MasterATA` | ATA chuyến |
| 15 | `KM` | KM |
| 16 | `KMGPS` | KMGPS |
| 17 | `KMGPSMobile` | KMGPSMobile |
| 18 | `VehicleRegNoStage1` | Số xe |
| 19 | `GroupOfVehicleCode` | Mã loại xe |
| 20 | `GroupOfVehicleName` | Tên loại xe |
| 21 | `VehicleMaxWeightStage1` | Trọng tải |
| 22 | `VehicleNote` | Ghi chú xe |
| 23 | `DriverNameStage1` | Tên tài xế |
| 24 | `DriverTelStage1` | SĐT tài xế |
| 25 | `DriverName2` | Tên phụ lái |
| 26 | `DriverName3` | Tên bốc xếp |
| 27 | `VendorCode` | Mã nhà xe |
| 28 | `VendorName` | Tên nhà xe |
| 29 | `VendorShortName` | Tên ngắn nhà xe |
| 30 | `TenderedDate` | Thời gian gửi thầu |
| 31 | `DeliveryStatus` | Trạng thái giao hàng |
| 32 | `QuantityOrder` | Số lượng kế hoạch |
| 33 | `QuantityTransfer` | Số lượng lấy |
| 34 | `QuantityBBGN` | Số lượng giao |
| 35 | `TonOrder` | Tấn kế hoạch |
| 36 | `TonTransfer` | Tấn lấy |
| 37 | `TonBBGN` | Tấn giao |
| 38 | `CBMOrder` | Khối kế hoạch |
| 39 | `CBMTransfer` | Khối lấy |
| 40 | `CBMBBGN` | Khối giao |
| 41 | `ReasonDeliveryName` | Nguyên nhân chênh lệch SL giao |
| 42 | `ORDLocationFromCode` | Mã điểm lấy của đơn |
| 43 | `ORDLocationFromName` | Tên điểm lấy của đơn |
| 44 | `ORDLocationToCode` | Mã điểm giao của đơn |
| 45 | `ORDLocationToName` | Tên điểm giao của đơn |
| 46 | `StockCode` | Mã điểm lấy |
| 47 | `StockName` | Tên điểm lấy |
| 48 | `StockAddress` | Địa chỉ điểm lấy |
| 49 | `OPSLocationToCode` | Mã điểm giao |
| 50 | `OPSLocationToName` | Tên điểm giao |
| 51 | `OPSLocationToAddress` | Địa chỉ điểm giao |
| 52 | `OPSLocationToProvince` | Tỉnh điểm giao |
| 53 | `OPSLocationToDistrict` | Quận điểm giao |
| 54 | `OPSLocationToNote` | Ghi chú điểm giao |
| 55 | `OPSLocationToCellphone` | SĐT điểm giao |
| 56 | `GroupOfLocationToCode` | Mã loại điểm giao |
| 57 | `GroupOfLocationToName` | Tên loại điểm giao |
| 58 | `PartnerToCode` | Mã hệ thống của nhà phân phối |
| 59 | `GroupOfPartnerName` | Nhóm nhà phân phối |
| 60 | `DistributorTypeModelName` | Mô hình nhà phân phối |
| 61 | `LocationToUnloadingTypeName` | Loại bốc xếp |
| 62 | `RoutingAreaToCode` | Khu vực giao |
| 63 | `DateFromCome` | Ngày đến điểm lấy |
| 64 | `DateFromLoadStart` | Ngày bắt đầu load hàng điểm lấy |
| 65 | `DateFromLoadEnd` | Ngày hoàn tất load hàng điểm lấy |
| 66 | `DateFromLeave` | Ngày đi (rời) điểm lấy |
| 67 | `DateToCome` | Ngày đến điểm giao |
| 68 | `DateToLoadStart` | Ngày bắt đầu load hàng điểm giao |
| 69 | `DateToLoadEnd` | Ngày hoàn tất load hàng điểm giao |
| 70 | `DateToLeave` | Ngày đi (rời) điểm giao |
| 71 | `DateComeEstimateFrom` | Ngày đến điểm lấy dự kiến |
| 72 | `DateLeaveEstimateFrom` | Ngày đi (rời) điểm lấy dự kiến |
| 73 | `DateComeEstimateTo` | Ngày đến điểm giao dự kiến |
| 74 | `DateLeaveEstimateTo` | Ngày đi (rời) điểm giao dự kiến |
| 75 | `TripTempRoom1` | Nhiệt độ ngăn 1 |
| 76 | `TripTempRoom2` | Nhiệt độ ngăn 2 |
| 77 | `OPSGroupNote` | Ghi chú chi tiết chuyến |
| 78 | `OPSGroupNote1` | Ghi chú chi tiết chuyến 1 |
| 79 | `OPSGroupNote2` | Ghi chú chi tiết chuyến 2 |
| 80 | `PODStatus` | Trạng thái chứng từ |
| 81 | `InvoiceDate` | Ngày nhận chứng từ |
| 82 | `InvoiceBy` | Người nhận chứng từ |
| 83 | `HasUpload` | Đã up hình chứng từ |
| 84 | `InvoiceNote` | Ghi chú chứng từ |
| 85 | `InvoiceMissingNote` | Ghi chú thiếu chứng từ |
| 86 | `OrderCode` | Mã đơn hàng |
| 87 | `VesselNo` | Mã tàu |
| 88 | `VesselName` | Tên tàu |
| 89 | `ServiceOfOrderCode` | Mã dịch vụ |
| 90 | `ServiceOfOrderName` | Tên dịch vụ |
| 91 | `TransportModeCode` | Mã loại hình vận chuyển |
| 92 | `TransportModeName` | Tên loại hình vận chuyển |
| 93 | `OrderCreatedBy` | Người tạo đơn |
| 94 | `OrderCreatedDate` | Ngày tạo đơn |
| 95 | `OrderType` | Loại đơn hàng |
| 96 | `OrderStatus` | Trạng thái đơn |
| 97 | `ReasonCancel` | Lý do huỷ đơn |
| 98 | `ReasonCancelNote` | Ghi chú lý do huỷ đơn |
| 99 | `OrderNote` | Ghi chú đơn hàng |
| 100 | `RequestDate` | Ngày yêu cầu vận chuyển |
| 101 | `ETD` | ETD đơn |
| 102 | `ETA` | ETA đơn |
| 103 | `OrderContract` | Hợp đồng đơn hàng |
| 104 | `PaymentMethod` | Phương thức thanh toán |
| 105 | `SORefCode` | Số SO |
| 106 | `CustomerCode` | Mã khách hàng |
| 107 | `CustomerName` | Tên khách hàng |
| 108 | `CustomerShortName` | Tên ngắn khách hàng |
| 109 | `TextLocationFromCode` | Text mã điểm nhận |
| 110 | `TextLocationFromName` | Text tên điểm nhận |
| 111 | `TextLocationFromAddress` | Text địa chỉ điểm nhận |
| 112 | `TextLocationFromProvinceCode` | Text mã tỉnh thành điểm nhận |
| 113 | `TextLocationFromProvinceName` | Text tên tỉnh thành điểm nhận |
| 114 | `TextLocationFromDistrictCode` | Text mã quận huyện điểm nhận |
| 115 | `TextLocationFromDistrictName` | Text tên quận huyện điểm nhận |
| 116 | `TextLocationFromWardCode` | Text mã xã phường điểm nhận |
| 117 | `TextLocationFromWardName` | Text tên xã phường điểm nhận |
| 118 | `TextLocationToCode` | Text mã điểm giao |
| 119 | `TextLocationToName` | Text tên điểm giao |
| 120 | `TextLocationToAddress` | Text địa chỉ điểm giao |
| 121 | `TextLocationToProvinceCode` | Text mã tỉnh thành điểm giao |
| 122 | `TextLocationToProvinceName` | Text tên tỉnh thành điểm giao |
| 123 | `TextLocationToDistrictCode` | Text mã quận huyện điểm giao |
| 124 | `TextLocationToDistrictName` | Text tên quận huyện điểm giao |
| 125 | `TextLocationToWardCode` | Text mã xã phường điểm giao |
| 126 | `TextLocationToWardName` | Text tên xã phường điểm giao |
| 127 | `ORDTextLocationFromCode` | Text mã điểm nhận chi tiết đơn |
| 128 | `ORDTextLocationFromName` | Text tên điểm nhận chi tiết đơn |
| 129 | `ORDTextLocationFromAddress` | Text địa chỉ điểm nhận chi tiết đơn |
| 130 | `ORDTextLocationFromProvinceCode` | Text mã tỉnh thành điểm nhận chi tiết đơn |
| 131 | `ORDTextLocationFromProvinceName` | Text tên tỉnh thành điểm nhận chi tiết đơn |
| 132 | `ORDTextLocationFromDistrictCode` | Text mã quận huyện điểm nhận chi tiết đơn |
| 133 | `ORDTextLocationFromDistrictName` | Text tên quận huyện điểm nhận chi tiết đơn |
| 134 | `ORDTextLocationFromWardCode` | Text mã xã phường điểm nhận chi tiết đơn |
| 135 | `ORDTextLocationFromWardName` | Text tên xã phường điểm nhận chi tiết đơn |
| 136 | `ORDTextLocationToCode` | Text mã điểm giao chi tiết đơn |
| 137 | `ORDTextLocationToName` | Text tên điểm giao chi tiết đơn |
| 138 | `ORDTextLocationToAddress` | Text địa chỉ điểm giao chi tiết đơn |
| 139 | `ORDTextLocationToProvinceCode` | Text mã tỉnh thành điểm giao chi tiết đơn |
| 140 | `ORDTextLocationToProvinceName` | Text tên tỉnh thành điểm giao chi tiết đơn |
| 141 | `ORDTextLocationToDistrictCode` | Text mã quận huyện điểm giao chi tiết đơn |
| 142 | `ORDTextLocationToDistrictName` | Text tên quận huyện điểm giao chi tiết đơn |
| 143 | `ORDTextLocationToWardCode` | Text mã xã phường điểm giao chi tiết đơn |
| 144 | `ORDTextLocationToWardName` | Text tên xã phường điểm giao chi tiết đơn |
| 145 | `_src_window` | C?a s? ng?y ngu?n |
| 146 | `_loaded_at` | Th?i ?i?m n?p d? li?u |
