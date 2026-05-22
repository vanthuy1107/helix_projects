# TÀI LIỆU THIẾT KẾ DỮ LIỆU HỆ THỐNG SMART TRANSPORT MANAGEMENT (STM)

## PHẦN I: TỔNG QUAN HỆ THỐNG

Hệ thống dữ liệu **Smart Transport Management (STM)** là kho dữ liệu phục vụ phân tích vận chuyển hàng hóa. Dữ liệu được tổ chức theo mô hình sao (Star Schema) với 3 Fact Tables, 10 Dimension Tables, và 12 Sub-Dimension Tables (Danh mục tham chiếu), hỗ trợ các truy vấn OLAP nhanh chóng.

**Kho dữ liệu:** ClickHouse (ReplacingMergeTree)  
**Cơ chế loading:** Incremental (Daily)  
**Mốc thời gian:** last_modified_date = greatest(CreatedDate, ModifiedDate)

---

# PHẦN II: CHI TIẾT THIẾT KẾ DỮ LIỆU

## SECTION 0: SUB-DIMENSION TABLES (12 bảng - Danh mục tham chiếu)

### 1. Bảng subdim_cus_product (Danh mục Sản phẩm)

**Nguồn dữ liệu chính:** CAT_Product (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CAT_Product | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CAT_Product | id | UInt64 | ID hàng hóa |
| GroupOfProductID | CAT_Product | group_of_product_id | UInt64 | FK tới nhóm sản phẩm |
| ParkingID | CAT_Product | parking_id | UInt64 | FK tới quy cách đóng gói |
| Code | CAT_Product | code | String | Mã hàng hóa |
| ProductName | CAT_Product | product_name | String | Tên hàng hóa |
| QuantityConfig | CAT_Product | quantity_config | String | Quy cách số lượng |
| CBM | CAT_Product | cbm | Decimal(18,4) | Khối lượng m³ |
| Weight | CAT_Product | weight | Decimal(18,4) | Trọng lượng kg |
| CreatedDate | CAT_Product | created_date | DateTime | Ngày tạo |
| ModifiedDate | CAT_Product | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CAT_Product | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 2. Bảng subdim_cus_group_of_product (Danh mục Nhóm sản phẩm)

**Nguồn dữ liệu chính:** CAT_GroupOfProduct (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CAT_GroupOfProduct | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CAT_GroupOfProduct | id | UInt64 | ID nhóm sản phẩm |
| Code | CAT_GroupOfProduct | code | String | Mã nhóm sản phẩm |
| GroupName | CAT_GroupOfProduct | group_name | String | Tên nhóm sản phẩm |
| CreatedDate | CAT_GroupOfProduct | created_date | DateTime | Ngày tạo |
| ModifiedDate | CAT_GroupOfProduct | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CAT_GroupOfProduct | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 3. Bảng subdim_cat_parking (Danh mục Quy cách đóng gói)

**Nguồn dữ liệu chính:** CAT_Parking (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CAT_Parking | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CAT_Parking | id | UInt64 | ID loại đóng gói |
| Code | CAT_Parking | code | String | Mã loại đóng gói |
| PackingName | CAT_Parking | packing_name | String | Tên loại đóng gói (EA, CS, PL) |
| CreatedDate | CAT_Parking | created_date | DateTime | Ngày tạo |
| ModifiedDate | CAT_Parking | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CAT_Parking | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 4. Bảng subdim_cat_service_of_order (Danh mục Dịch vụ đơn hàng)

**Nguồn dữ liệu chính:** CAT_ServiceOfOrder (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CAT_ServiceOfOrder | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CAT_ServiceOfOrder | id | UInt64 | ID loại dịch vụ |
| Code | CAT_ServiceOfOrder | code | String | Mã dịch vụ |
| ServiceName | CAT_ServiceOfOrder | service_name | String | Tên loại dịch vụ |
| CreatedDate | CAT_ServiceOfOrder | created_date | DateTime | Ngày tạo |
| ModifiedDate | CAT_ServiceOfOrder | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CAT_ServiceOfOrder | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 5. Bảng subdim_cus_customer (Danh mục Khách hàng)

**Nguồn dữ liệu chính:** CUS_Customer (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CUS_Customer | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CUS_Customer | id | UInt64 | ID khách hàng |
| Code | CUS_Customer | code | String | Mã khách hàng |
| CustomerName | CUS_Customer | customer_name | String | Tên khách hàng |
| ShortName | CUS_Customer | short_name | String | Tên viết tắt |
| CreatedDate | CUS_Customer | created_date | DateTime | Ngày tạo |
| ModifiedDate | CUS_Customer | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CUS_Customer | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 6. Bảng subdim_cat_vehicle (Danh mục Xe vận tải)

**Nguồn dữ liệu chính:** CAT_Vehicle (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CAT_Vehicle | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CAT_Vehicle | id | UInt64 | ID xe |
| RegNo | CAT_Vehicle | reg_no | String | Biển số xe |
| DriverName | CAT_Vehicle | driver_name | String | Tên tài xế chính |
| GroupOfVehicleID | CAT_Vehicle | group_of_vehicle_id | UInt64 | FK tới loại xe |
| CreatedDate | CAT_Vehicle | created_date | DateTime | Ngày tạo |
| ModifiedDate | CAT_Vehicle | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CAT_Vehicle | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 7. Bảng subdim_cat_group_of_vehicle (Danh mục Loại xe)

**Nguồn dữ liệu chính:** CAT_GroupOfVehicle (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CAT_GroupOfVehicle | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CAT_GroupOfVehicle | id | UInt64 | ID loại xe |
| Code | CAT_GroupOfVehicle | code | String | Mã loại xe |
| GroupName | CAT_GroupOfVehicle | group_name | String | Tên loại xe |
| Ton | CAT_GroupOfVehicle | ton | Decimal(18,4) | Tấn đăng ký |
| CBM | CAT_GroupOfVehicle | cbm | Decimal(18,4) | Dung tích m³ |
| CreatedDate | CAT_GroupOfVehicle | created_date | DateTime | Ngày tạo |
| ModifiedDate | CAT_GroupOfVehicle | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CAT_GroupOfVehicle | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 8. Bảng subdim_cat_partner (Danh mục Nhà phân phối/Đối tác)

**Nguồn dữ liệu chính:** CAT_Partner (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CAT_Partner | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CAT_Partner | id | UInt64 | ID nhà phân phối |
| Code | CAT_Partner | code | String | Mã nhà phân phối |
| PartnerName | CAT_Partner | partner_name | String | Tên nhà phân phối |
| TypeOfPartnerID | CAT_Partner | type_of_partner_id | UInt64 | ID loại đối tác |
| GroupOfPartnerID | CAT_Partner | group_of_partner_id | UInt64 | ID nhóm đối tác |
| Email | CAT_Partner | email | String | Email liên hệ |
| Fax | CAT_Partner | fax | String | Số fax |
| TelNo | CAT_Partner | tel_no | String | Điện thoại |
| Address | CAT_Partner | address | String | Địa chỉ trụ sở |
| WardID | CAT_Partner | ward_id | UInt64 | ID phường/xã |
| ProvinceID | CAT_Partner | province_id | UInt64 | ID tỉnh/thành phố |
| CountryID | CAT_Partner | country_id | UInt64 | ID quốc gia |
| CreatedDate | CAT_Partner | created_date | DateTime | Ngày tạo |
| ModifiedDate | CAT_Partner | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CAT_Partner | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 9. Bảng subdim_cus_partner (Liên kết Nhà phân phối - Khách hàng)

**Nguồn dữ liệu chính:** CUS_Partner (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CUS_Partner | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CUS_Partner | id | UInt64 | ID liên kết |
| PartnerID | CUS_Partner | partner_id | UInt64 | FK tới nhà phân phối |
| CustomerID | CUS_Partner | customer_id | UInt64 | FK tới khách hàng |
| PartnerCode | CUS_Partner | partner_code | String | Mã nhà phân phối |
| TMSCusPartnerID | CUS_Partner | tms_cus_partner_id | UInt64 | ID mapping TMS |
| CreatedDate | CUS_Partner | created_date | DateTime | Ngày tạo |
| ModifiedDate | CUS_Partner | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CUS_Partner | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 10. Bảng subdim_cat_location (Danh mục Địa điểm)

**Nguồn dữ liệu chính:** CAT_Location (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CAT_Location | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CAT_Location | id | UInt64 | ID địa điểm |
| Code | CAT_Location | code | String | Mã địa điểm |
| LocationName | CAT_Location | location_name | String | Tên địa điểm |
| Address | CAT_Location | address | String | Địa chỉ |
| GroupOfLocationID | CAT_Location | group_of_location_id | UInt64 | FK tới loại địa điểm |
| UnloadingTypeID | CAT_Location | unloading_type_id | UInt64 | ID loại bốc xếp |
| AreaID | CAT_Location | area_id | UInt64 | FK tới khu vực |
| CreatedDate | CAT_Location | created_date | DateTime | Ngày tạo |
| ModifiedDate | CAT_Location | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CAT_Location | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 11. Bảng subdim_cat_group_of_location (Danh mục Loại địa điểm)

**Nguồn dữ liệu chính:** CAT_GroupOfLocation (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CAT_GroupOfLocation | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CAT_GroupOfLocation | id | UInt64 | ID loại địa điểm |
| Code | CAT_GroupOfLocation | code | String | Mã loại địa điểm |
| GroupName | CAT_GroupOfLocation | group_name | String | Tên loại địa điểm |
| CreatedDate | CAT_GroupOfLocation | created_date | DateTime | Ngày tạo |
| ModifiedDate | CAT_GroupOfLocation | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CAT_GroupOfLocation | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 12. Bảng subdim_cat_area (Danh mục Khu vực)

**Nguồn dữ liệu chính:** CAT_Area (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CAT_Area | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CAT_Area | id | UInt64 | ID khu vực |
| Code | CAT_Area | code | String | Mã khu vực |
| AreaName | CAT_Area | area_name | String | Tên khu vực |
| CreatedDate | CAT_Area | created_date | DateTime | Ngày tạo |
| ModifiedDate | CAT_Area | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CAT_Area | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

## SECTION 1: FACT TABLES (3 bảng)

### 1. Bảng fact_trip (Chuyến Vận hành)

**Nguồn dữ liệu chính:** dim_ops_trip_product, dim_ops_trip_detail  
**Engine:** ReplacingMergeTree(composite_last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| key_sk | dim_ops_trip_product | key_sk | UInt64 | Khóa chính - ID sản phẩm trong chuyến |
| key_sk | dim_ops_trip_product | ops_trip_product_sk | UInt64 | Surrogate Key (trùng key_sk) |
| key_sk | dim_ops_trip_detail | ops_trip_detail_sk | UInt64 | FK tới chi tiết chuyến |
| order_group_product_id | dim_ops_trip_detail | ord_group_product_sk | UInt64 | FK tới chi tiết đơn hàng |
| trip_header_id | dim_ops_trip_detail | ops_trip_sk | UInt64 | FK tới chuyến vận hành |
| order_product_id | dim_ops_trip_product | ord_product_sk | UInt64 | FK tới sản phẩm đơn hàng |
| created_date | dim_ops_trip_product | created_date | DateTime | Ngày tạo bản ghi |
| updated_date | dim_ops_trip_product | updated_date | DateTime | Ngày cập nhật gần nhất |
| last_modified_date | dim_ops_trip_product | last_modified_date | DateTime64(3) | Mốc thời gian tracking delta |
| - | derived | composite_last_modified_date | DateTime64(3) | MAX(trip_product, trip_detail) |
| - | derived | is_deleted | Boolean | Cờ đánh dấu xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 2. Bảng fact_order (Đơn Hàng)

**Nguồn dữ liệu chính:** dim_ord_product, dim_ord_product_group, dim_ord_order, dim_cus_location  
**Engine:** ReplacingMergeTree(composite_last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| key_sk | dim_ord_product | key_sk | UInt64 | Khóa chính - ID sản phẩm đơn hàng |
| location_to_id | dim_ord_product_group | location_to_sk | UInt64 | FK tới điểm giao hàng |
| location_from_id | dim_ord_product_group | location_from_sk | UInt64 | FK tới điểm nhận hàng |
| key_sk | dim_ord_product_group | ord_product_group_sk | UInt64 | FK tới chi tiết đơn |
| key_sk | dim_ord_order | ord_order_sk | UInt64 | FK tới đơn hàng |
| order_product_id | dim_ord_product | ord_product_sk | UInt64 | FK tới sản phẩm |
| created_date | dim_ord_product | created_date | DateTime | Ngày tạo |
| updated_date | dim_ord_product | updated_date | DateTime | Ngày cập nhật gần nhất |
| last_modified_date | dim_ord_product | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | composite_last_modified_date | DateTime64(3) | MAX(tất cả dimensions) |
| - | derived | is_deleted | Boolean | Cờ đánh dấu xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 3. Bảng fact_dock (Dock Register)

**Nguồn dữ liệu chính:** dim_ops_dock_register  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| key_sk | dim_ops_dock_register | key_sk | UInt64 | Khóa chính |
| key_sk | dim_ops_dock_register | ops_dock_register_sk | UInt64 | Surrogate Key (trùng key_sk) |
| dock_id | dim_ops_dock_register | cus_dock_sk | UInt64 | FK tới bãy hàng |
| dito_master_id | dim_ops_dock_register | ops_trip_sk | UInt64 | FK tới chuyến vận hành |
| created_date | dim_ops_dock_register | created_date | DateTime | Ngày tạo |
| updated_date | dim_ops_dock_register | updated_date | DateTime | Ngày cập nhật |
| last_modified_date | dim_ops_dock_register | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ đánh dấu xóa |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

## SECTION 2: DIMENSION TABLES (10 bảng)

### 1. Bảng dim_ord_order (Đơn Hàng)

**Nguồn dữ liệu chính:** ORD_Order (STM), SYS_Var, subdim_cat_service_of_order  
**Engine:** ReplacingMergeTree(composite_last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | ORD_Order | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | ORD_Order | id | UInt64 | ID đơn hàng |
| Code | ORD_Order | code | String | Mã đơn hàng |
| CustomerID | ORD_Order | customer_id | String | ID khách hàng |
| StatusOfOrderID | ORD_Order | status_of_order_id | UInt64 | ID trạng thái đơn |
| (ValueOfVar from SYS_Var) | SYS_Var | status_name | String | Tên trạng thái (mapped từ SYS_Var) |
| (TypeOfVar from SYS_Var) | SYS_Var | status_type | String | Phân loại trạng thái |
| ServiceOfOrderID | ORD_Order | subcat_sevice_of_order_sk | UInt64 | FK tới dịch vụ đơn hàng |
| (code from subdim) | subdim_cat_service_of_order | service_code | String | Mã loại dịch vụ |
| (name from subdim) | subdim_cat_service_of_order | service_name | String | Tên loại dịch vụ |
| ETD | ORD_Order | etd | DateTime | Dự kiến lấy hàng |
| ETA | ORD_Order | eta | DateTime | Dự kiến giao hàng |
| RequestDate | ORD_Order | request_date | DateTime | Ngày gửi đơn hàng |
| CreatedDate | ORD_Order | created_date | DateTime | Ngày tạo đơn |
| ModifiedDate | ORD_Order | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | ORD_Order | last_modified_date | DateTime64(3) | Mốc thời gian thay đổi gốc |
| - | derived | composite_last_modified_date | DateTime64(3) | MAX(order, status, service) |
| - | derived | is_deleted | Boolean | Cờ xóa (mặc định false) |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 2. Bảng dim_ord_product_group (Chi tiết Đơn Hàng)

**Nguồn dữ liệu chính:** ORD_GroupProduct (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | ORD_GroupProduct | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | ORD_GroupProduct | id | UInt64 | ID chi tiết đơn |
| OrderID | ORD_GroupProduct | order_id | UInt64 | FK tới dim_ord_order |
| CodeSync | ORD_GroupProduct | code_sync | String | Trạng thái đồng bộ SWM ↔ STM |
| LocationFromID | ORD_GroupProduct | location_from_id | UInt64 | ID điểm lấy hàng |
| LocationToID | ORD_GroupProduct | location_to_id | UInt64 | ID điểm giao hàng |
| IsReturn | ORD_GroupProduct | is_return | Boolean | Cờ đơn hàng trả về |
| CreatedDate | ORD_GroupProduct | created_date | DateTime | Ngày tạo |
| ModifiedDate | ORD_GroupProduct | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | ORD_GroupProduct | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa (mặc định false) |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 3. Bảng dim_ord_product (Sản Phẩm Đơn Hàng)

**Nguồn dữ liệu chính:** ORD_Product (STM), subdim_cus_product, subdim_cus_group_of_product, subdim_cat_parking  
**Engine:** ReplacingMergeTree(composite_last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | ORD_Product | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | ORD_Product | id | UInt64 | ID hàng hóa chi tiết |
| ProductID | subdim_cus_product | subcus_product_sk | UInt64 | FK tới sản phẩm danh mục |
| (group_of_product_id from subdim) | subdim_cus_product | subcus_group_of_product_sk | UInt64 | FK tới nhóm sản phẩm |
| (parking_id from subdim) | subdim_cus_product | subcat_parking_sk | UInt64 | FK tới quy cách đóng gói |
| GroupProductID | ORD_Product | group_product_id | UInt64 | FK tới dim_ord_product_group |
| CreatedDate | ORD_Product | created_date | DateTime | Ngày tạo |
| ModifiedDate | ORD_Product | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | ORD_Product | last_modified_date | DateTime64(3) | Tracking delta gốc |
| - | derived | composite_last_modified_date | DateTime64(3) | MAX(product, group, parking) |
| - | derived | is_deleted | Boolean | Cờ xóa (mặc định false) |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 4. Bảng dim_ops_trip (Chuyến Vận hành)

**Nguồn dữ liệu chính:** OPS_DITOMaster (STM), subdim_cat_vehicle, subdim_cat_group_of_vehicle, subdim_cus_customer  
**Engine:** ReplacingMergeTree(composite_last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | OPS_DITOMaster | trip_sk | UInt64 | Khóa chính (ID gốc) |
| ID | OPS_DITOMaster | id | UInt64 | ID chuyến |
| Code | OPS_DITOMaster | code | String | Mã chuyến vận hành |
| ETA | OPS_DITOMaster | eta | DateTime | Dự kiến giao hàng |
| ETD | OPS_DITOMaster | etd | DateTime | Dự kiến lấy hàng |
| ATA | OPS_DITOMaster | ata | DateTime | Thực tế giao hàng |
| ATD | OPS_DITOMaster | atd | DateTime | Thực tế lấy hàng |
| ApprovedDate | OPS_DITOMaster | approved_date | DateTime | Ngày phê duyệt |
| TenderedDate | OPS_DITOMaster | tendered_date | DateTime | Ngày gửi thầu |
| VehicleID | OPS_DITOMaster | vehicle_id | UInt64 | ID xe thực tế |
| (reg_no from subdim) | subdim_cat_vehicle | reg_no | String | Biển số xe |
| DriverID1 | OPS_DITOMaster | driver_id1 | UInt64 | ID tài xế chính |
| DriverName1 | OPS_DITOMaster | driver_name1 | String | Tên tài xế chính |
| VendorOfVehicleID | OPS_DITOMaster | vendor_id | UInt64 | FK tới nhà thầu (subdim_cus_customer) |
| StatusOfDITOMasterID | OPS_DITOMaster | status_id | UInt64 | ID trạng thái chuyến |
| (group_of_vehicle_id from subdim) | subdim_cat_vehicle | header_group_vehicle_sk | UInt64 | SK loại xe thực tế |
| GroupOfVehicleID | OPS_DITOMaster | tender_group_vehicle_sk | UInt64 | SK loại xe gửi thầu |
| (group_name from subdim) | subdim_cat_group_of_vehicle | header_vehicle_group_name | String | Tên loại xe thực tế |
| (group_name from subdim) | subdim_cat_group_of_vehicle | tender_vehicle_group_name | String | Tên loại xe gửi thầu |
| CreatedDate | OPS_DITOMaster | created_date | DateTime | Ngày tạo |
| ModifiedDate | OPS_DITOMaster | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | OPS_DITOMaster | last_modified_date | DateTime64(3) | Tracking delta gốc |
| - | derived | composite_last_modified_date | DateTime64(3) | MAX(trip, vehicle, group) |
| - | derived | is_deleted | Boolean | Cờ xóa (mặc định false) |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 5. Bảng dim_ops_trip_detail (Chi tiết Chuyến Vận hành)

**Nguồn dữ liệu chính:** OPS_DITOGroupProduct (STM), SYS_Var  
**Engine:** ReplacingMergeTree(composite_last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | OPS_DITOGroupProduct | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | OPS_DITOGroupProduct | id | UInt64 | ID chi tiết chuyến |
| DITOMasterID | OPS_DITOGroupProduct | trip_header_id | UInt64 | FK tới chuyến header |
| TenderMasterID | OPS_DITOGroupProduct | trip_tender_id | UInt64 | ID chuyến gửi thầu |
| OrderGroupProductID | OPS_DITOGroupProduct | order_group_product_id | UInt64 | FK tới chi tiết đơn |
| DITOGroupProductStatusID | OPS_DITOGroupProduct | status_id | UInt64 | ID trạng thái chi tiết |
| (ValueOfVar from SYS_Var) | SYS_Var | status_name | String | Tên trạng thái chi tiết |
| DITOGroupProductStatusPODID | OPS_DITOGroupProduct | status_pod_id | UInt64 | ID trạng thái POD |
| (ValueOfVar from SYS_Var) | SYS_Var | status_pod_name | String | Tên trạng thái POD |
| Quantity | OPS_DITOGroupProduct | quantity | Decimal(18,4) | Số lượng kế hoạch |
| QuantityTranfer | OPS_DITOGroupProduct | quantity_tranfer | Decimal(18,4) | Số lượng chở (thực tế) |
| QuantityBBGN | OPS_DITOGroupProduct | quantity_bbgn | Decimal(18,4) | Số lượng giao (BBGN) |
| Ton | OPS_DITOGroupProduct | ton | Decimal(18,4) | Tấn kế hoạch |
| TonTranfer | OPS_DITOGroupProduct | ton_tranfer | Decimal(18,4) | Tấn nhận (chuyển đi) |
| TonBBGN | OPS_DITOGroupProduct | ton_bbgn | Decimal(18,4) | Tấn giao (thực nhận) |
| CBM | OPS_DITOGroupProduct | cbm | Decimal(18,4) | Khối kế hoạch |
| CBMTranfer | OPS_DITOGroupProduct | cbm_tranfer | Decimal(18,4) | Khối nhận |
| CBMBBGN | OPS_DITOGroupProduct | cbm_bbgn | Decimal(18,4) | Khối giao |
| ETA | OPS_DITOGroupProduct | eta | DateTime | Dự kiến giao |
| DateFromLeave | OPS_DITOGroupProduct | date_from_leave | DateTime | Ngày rời điểm lấy |
| DateToLeave | OPS_DITOGroupProduct | date_to_leave | DateTime | Ngày rời điểm giao |
| DateToCome | OPS_DITOGroupProduct | date_to_come | DateTime | Ngày đến điểm giao |
| DateFromCome | OPS_DITOGroupProduct | date_from_come | DateTime | Ngày đến điểm lấy |
| TenderedDate | OPS_DITOGroupProduct | tender_date | DateTime | Ngày gửi thầu |
| DateToLoadStart | OPS_DITOGroupProduct | date_to_load_start | DateTime | Bắt đầu lên hàng |
| DateToLoadEnd | OPS_DITOGroupProduct | date_to_load_end | DateTime | Kết thúc lên hàng |
| RequiredDepartureTime | OPS_DITOGroupProduct | required_departure_time | DateTime | Thời gian bắt đầu khởi hành |
| LocationFromID | OPS_DITOGroupProduct | location_from_id | UInt64 | ID điểm lấy |
| LocationToID | OPS_DITOGroupProduct | location_to_id | UInt64 | ID điểm giao |
| SortOrder | OPS_DITOGroupProduct | sort_order | Int32 | Thứ tự trong chuyến |
| LockedBy | OPS_DITOGroupProduct | locked_by | String | Người khóa bản ghi |
| CreatedDate | OPS_DITOGroupProduct | created_date | DateTime | Ngày tạo |
| ModifiedDate | OPS_DITOGroupProduct | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | OPS_DITOGroupProduct | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | composite_last_modified_date | DateTime64(3) | MAX(detail, status, pod) |
| - | derived | is_deleted | Boolean | Cờ xóa (mặc định false) |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 6. Bảng dim_ops_trip_product (Sản phẩm Chuyến)

**Nguồn dữ liệu chính:** OPS_DITOProduct (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | OPS_DITOProduct | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | OPS_DITOProduct | id | UInt64 | ID hàng hóa chi tiết chuyến |
| DITOGroupProductID | OPS_DITOProduct | dito_group_product_id | UInt64 | FK tới chi tiết chuyến |
| OrderProductID | OPS_DITOProduct | order_product_id | UInt64 | FK tới sản phẩm đơn |
| Quantity | OPS_DITOProduct | quantity_plan | Decimal(18,4) | Số lượng kế hoạch |
| QuantityTranfer | OPS_DITOProduct | quantity_transfer | Decimal(18,4) | Số lượng thực chở |
| QuantityBBGN | OPS_DITOProduct | quantity_bbgn | Decimal(18,4) | Số lượng giao |
| QuantityReturn | OPS_DITOProduct | quantity_return | Decimal(18,4) | Số lượng trả về |
| Weight | OPS_DITOProduct | weight | Decimal(18,4) | Trọng lượng hàng |
| VCFTransfer | OPS_DITOProduct | vcf_transfer | Decimal(18,4) | Hệ số VCF lúc nhận |
| VCFBBGN | OPS_DITOProduct | vcf_bbgn | Decimal(18,4) | Hệ số VCF lúc giao |
| InventoryStatusID | OPS_DITOProduct | inventory_status_id | UInt64 | ID trạng thái kho |
| InventoryZone | OPS_DITOProduct | inventory_zone | String | Khu vực kho |
| ReferNumber | OPS_DITOProduct | refer_number | String | Số tham chiếu |
| ActiveDate | OPS_DITOProduct | active_date | DateTime | Ngày kích hoạt |
| QuantityConfirmStatusDate | OPS_DITOProduct | qty_confirm_date | DateTime | Ngày xác nhận SL |
| StockConfirmStatusDate | OPS_DITOProduct | stock_confirm_date | DateTime | Ngày xác nhận kho |
| QuantityConfirmStatusBBGNDate | OPS_DITOProduct | bbgn_confirm_date | DateTime | Ngày xác nhận BBGN |
| CreatedDate | OPS_DITOProduct | created_date | DateTime | Ngày tạo |
| ModifiedDate | OPS_DITOProduct | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | OPS_DITOProduct | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa (mặc định false) |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 7. Bảng dim_cus_location (Vị trí Khách hàng)

**Nguồn dữ liệu chính:** CUS_Location (STM), subdim_cat_location, subdim_cat_area, subdim_cus_partner, subdim_cat_partner, subdim_cus_customer  
**Engine:** ReplacingMergeTree(composite_last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CUS_Location | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CUS_Location | id | UInt64 | ID vị trí khách hàng |
| Code | CUS_Location | code | String | Mã vị trí khách hàng |
| LocationName | CUS_Location | location_name | String | Tên vị trí khách hàng |
| LocationID | subdim_cat_location | subcat_location_sk | UInt64 | FK tới danh mục địa điểm |
| (area_id from subdim) | subdim_cat_location | subcat_area_sk | UInt64 | FK tới khu vực |
| (group_of_location_id from subdim) | subdim_cat_location | subcat_group_sk | UInt64 | FK tới nhóm vị trí |
| CusPartID | CUS_Location | cus_partner_sk | UInt64 | FK tới nhà phân phối khách hàng |
| (partner_id from subdim) | subdim_cus_partner | cat_partner_sk | UInt64 | FK tới danh mục đối tác |
| CustomerID | CUS_Location | cus_customer_sk | UInt64 | FK tới khách hàng |
| CreatedDate | CUS_Location | created_date | DateTime | Ngày tạo |
| ModifiedDate | CUS_Location | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CUS_Location | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | composite_last_modified_date | DateTime64(3) | MAX(location, related dims) |
| - | derived | is_deleted | Boolean | Cờ xóa (mặc định false) |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 8. Bảng dim_cus_dock (Bãy hàng Khách hàng)

**Nguồn dữ liệu chính:** CUS_Dock (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CUS_Dock | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CUS_Dock | id | UInt64 | ID dock |
| Code | CUS_Dock | code | String | Mã bãy hàng |
| DockName | CUS_Dock | dock_name | String | Tên bãy hàng |
| LocationID | CUS_Dock | location_id | UInt64 | ID địa điểm |
| SortOrder | CUS_Dock | sort_order | Int32 | Thứ tự sắp xếp |
| VehicleLimit | CUS_Dock | vehicle_limit | Int32 | Giới hạn số xe |
| CreatedDate | CUS_Dock | created_date | DateTime | Ngày tạo |
| ModifiedDate | CUS_Dock | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CUS_Dock | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa (mặc định false) |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 9. Bảng dim_ops_dock_register (Đăng ký Dock)

**Nguồn dữ liệu chính:** OPS_DockRegister (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | OPS_DockRegister | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | OPS_DockRegister | id | UInt64 | ID đăng ký dock |
| DockID | OPS_DockRegister | dock_id | UInt64 | ID dock |
| DITOMasterID | OPS_DockRegister | dito_master_id | UInt64 | ID chuyến vận hành |
| RegisterDate | OPS_DockRegister | register_date | DateTime | Thời điểm đăng ký |
| CalledDate | OPS_DockRegister | called_date | DateTime | Thời điểm gọi xe |
| GateIn | OPS_DockRegister | gate_in | DateTime | Thời điểm vào cổng |
| LoadingStart | OPS_DockRegister | loading_start | DateTime | Thời điểm bắt đầu xếp |
| LoadingEnd | OPS_DockRegister | loading_end | DateTime | Thời điểm kết thúc xếp |
| GateOut | OPS_DockRegister | gate_out | DateTime | Thời điểm rời cổng |
| CreatedDate | OPS_DockRegister | created_date | DateTime | Ngày tạo |
| ModifiedDate | OPS_DockRegister | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | OPS_DockRegister | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa (mặc định false) |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

### 10. Bảng dim_cat_stand (Điểm Dừng)

**Nguồn dữ liệu chính:** CAT_Stand (STM)  
**Engine:** ReplacingMergeTree(last_modified_date)  
**Tần suất:** Hàng ngày

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu Dữ Liệu | Ý Nghĩa Nghiệp Vụ |
|:---|:---|:---|:---|:---|
| ID | CAT_Stand | key_sk | UInt64 | Khóa chính (ID gốc) |
| ID | CAT_Stand | id | UInt64 | ID điểm dừng |
| Code | CAT_Stand | code | String | Mã điểm dừng |
| LocationID | CAT_Stand | location_id | UInt64 | ID địa điểm |
| StandName | CAT_Stand | stand_name | String | Tên điểm dừng |
| CodeSync | CAT_Stand | code_sync | String | Mã đồng bộ |
| StandTypeID | CAT_Stand | stand_type_id | UInt64 | ID loại điểm dừng |
| CreatedDate | CAT_Stand | created_date | DateTime | Ngày tạo |
| ModifiedDate | CAT_Stand | updated_date | DateTime | Ngày cập nhật |
| greatest(ModifiedDate, CreatedDate) | CAT_Stand | last_modified_date | DateTime64(3) | Tracking delta |
| - | derived | is_deleted | Boolean | Cờ xóa (mặc định false) |
| - | derived | dbt_updated_at | DateTime64(3) | Thời điểm load vào DW |

---

**Tài liệu cập nhật lần cuối:** 30/03/2026  
**Phiên bản:** 2.0 (STM - ClickHouse - Chi tiết nguồn cột)  
**Trạng thái:** Hoàn chỉnh - 12 Sub-Dimension Tables + 3 Fact Tables + 10 Dimension Tables
