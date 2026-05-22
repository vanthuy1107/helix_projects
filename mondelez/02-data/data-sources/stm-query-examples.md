# HƯỚNG DẪN SỬ DỤNG VÀ QUERY MẪU - DATAWAREHOUSE STM

## PHẦN I: GIỚI THIỆU CHUNG

### 1. Cấu trúc Dữ liệu

Datawarehouse STM sử dụng **mô hình sao (Star Schema)** bao gồm:
- **3 Fact Tables** (Bảng sự kiện): fact_order, fact_trip, fact_dock
- **10 Dimension Tables** (Bảng chiều): dim_ord_order, dim_ops_trip, v.v.
- **12 Sub-Dimension Tables** (Danh mục): subdim_cus_product, subdim_cat_vehicle, v.v.

### 2. Cách dữ liệu được tổ chức

```
Orders (ORD)
  ├─ dim_ord_order (Đơn hàng chính)
  │  └─ dim_ord_product_group (Chi tiết đơn - nhóm hàng)
  │     └─ dim_ord_product (Hàng hóa - bridge)
  │        ├─ subdim_cus_product (Danh mục sản phẩm)
  │        ├─ subdim_cus_group_of_product (Nhóm sản phẩm)
  │        └─ subdim_cat_parking (Quy cách đóng gói)
  └─ fact_order (Sự kiện đơn hàng)

Trips (OPS)
  ├─ dim_ops_trip (Chuyến vận hành)
  │  ├─ subdim_cat_vehicle (Xe)
  │  ├─ subdim_cat_group_of_vehicle (Loại xe)
  │  └─ subdim_cus_customer (Khách hàng/Vendor)
  ├─ dim_ops_trip_detail (Chi tiết chuyến điểm)
  │  └─ dim_ops_trip_product (Sản phẩm trong chuyến)
  │     └─ dim_ord_product (Link tới đơn hàng)
  ├─ dim_ops_dock_register (Đăng ký bốc xếp)
  │  └─ dim_cus_dock (Bãy hàng)
  └─ fact_trip (Sự kiện chuyến)

Locations (CUS/CAT)
  ├─ dim_cus_location (Địa điểm khách hàng)
  │  ├─ subdim_cat_location (Danh mục địa điểm)
  │  ├─ subdim_cat_area (Danh mục khu vực)
  │  ├─ subdim_cus_customer (Khách hàng)
  │  └─ subdim_cus_partner (Nhà phân phối)
  ├─ dim_cus_dock (Bãy hàng/Dock)
  ├─ dim_cat_stand (Vị trí đứng hàng)
  └─ fact_dock (Sự kiện bốc xếp)
```

### 3. 🔴 Nguyên tắc sử dụng Datawarehouse (MUST FOLLOW)

#### 3.1. Nguyên tắc FDN (Fact → Dimension → SubDimension)

**Luật vàng - CÓ TÍNH BẮT BUỘC:**
```
Mô hình JOIN duy nhất được phép:
Fact → Dimension → Sub-Dimension
```

**Các JOIN không được phép:**
- ❌ Fact → Sub-Dimension (trực tiếp)
- ❌ Dimension → Dimension (không qua Fact)
- ❌ Sub-Dimension → Sub-Dimension

**Ví dụ:**
```sql
-- ✅ ĐÚNG
FROM fact_trip f
INNER JOIN dim_ops_trip t ON f.ops_trip_sk = t.trip_sk
INNER JOIN subdim_cat_vehicle v ON t.vehicle_id = v.id

-- ❌ SAI (trực tiếp Fact → SubDim)
FROM fact_trip f
INNER JOIN subdim_cat_vehicle v ON ...
```

**Lý do:** 
- Query rõ ràng, dễ maintain
- Tránh data lineage confusion
- Performance tối ưu trên ClickHouse

---

#### 3.2. Luôn lọc is_deleted = 0

Tất cả query **PHẢI** có điều kiện này:

```sql
WHERE f.is_deleted = 0  -- Bắt buộc
```

**Lý do:** Track soft deletes từ source system

---

#### 3.3. Luôn filter theo ngày (date range)

```sql
WHERE f.is_deleted = 0
    AND toDate(f.created_date) >= today() - interval '30 day'
```

**Lý do:**
- ClickHouse dùng partition theo date
- Giảm data scan từ terabytes xuống megabytes
- Query nhanh 10-100x lần

**Quy tắc:**
- Last 7 days: `interval '7 day'`
- Last 30 days: `interval '30 day'`
- Last 90 days: `interval '90 day'`
- Specific date: `= today()` hoặc `= toDate('2026-03-30')`

---

#### 3.4. Chọn Fact Table đúng theo usecase

| Usecase | Fact Table | Dimension | Mục đích |
|:---|:---|:---|:---|
| Phân tích đơn hàng | fact_order | dim_ord_order | Doanh số, khách hàng, sản phẩm |
| Phân tích chuyến | fact_trip | dim_ops_trip | Hiệu suất vận chuyển, tài xế |
| Phân tích bốc xếp | fact_dock | dim_cus_dock | Tải dock, thời gian xếp |

**Cảnh báo:** Không JOIN nhiều Fact table cùng lúc (dễ data explosion)

---

#### 3.5. Sử dụng DISTINCT cho COUNT duy nhất

```sql
-- ❌ SAI: count tất cả rows (có trùng lặp)
COUNT(*) AS orders

-- ✅ ĐÚNG: count bản ghi duy nhất
COUNT(DISTINCT f.ord_order_sk) AS unique_orders
```

**Khi nào dùng DISTINCT:**
- `COUNT(DISTINCT f.ord_order_sk)` - Unique orders
- `COUNT(DISTINCT f.key_sk)` - Unique items/products
- `COUNT(DISTINCT c.customer_name)` - Unique customers

---

#### 3.6. Xử lý NULL values đúng cách

**Vấn đề:** SUM/AVG trên NULL → kết quả NULL

```sql
-- ❌ SAI
SELECT SUM(quantity_bbgn) FROM fact_trip;

-- ✅ TỐT: dùng ifNull
SELECT SUM(ifNull(quantity_bbgn, 0)) FROM fact_trip;

-- ✅ TỐT: dùng CASE (explicit)
SELECT SUM(CASE
    WHEN quantity_bbgn IS NOT NULL THEN quantity_bbgn
    ELSE 0
END) FROM fact_trip;
```

---

#### 3.7. DateTime operations

```sql
-- Convert
toDate(created_date)      -- DateTime → Date
toTime(created_date)      -- DateTime → Time

-- Extract
toYear(), toMonth(), toDayOfMonth()
toHour(), toMinute(), toSecond()

-- Calculate delta
dateDiff('day', etd, ata)       -- Số ngày
dateDiff('hour', gate_in, gate_out)  -- Số giờ
dateDiff('minute', start, end)  -- Số phút
```

---

#### 3.8. Lựa chọn INNER vs LEFT JOIN

```sql
-- ✅ INNER: bắt buộc có data ở cả 2 bảng
FROM fact_order f
INNER JOIN dim_ord_order do ON f.ord_order_sk = do.key_sk

-- ✅ LEFT: data 1 bảng có thể không match
FROM fact_order f
LEFT JOIN fact_trip ft ON f.key_sk = ft.ord_product_sk  -- Chuyến chưa tạo
```

---

#### 3.9. Cảnh báo: FINAL chỉ dùng khi cần thiết

```sql
-- FINAL loại bỏ duplicate (chậm!)
SELECT * FROM fact_order FINAL WHERE is_deleted = 0

-- Thông thường: không cần FINAL
SELECT * FROM fact_order WHERE is_deleted = 0
```

**Lưu ý:** FINAL slow × 10-100; chỉ dùng khi **GỌC THIẾT** dữ liệu mới nhất.

---

#### 3.10. Debug query trước khi production

```sql
-- Step 1: Xem sample
SELECT * FROM fact_order WHERE is_deleted = 0 LIMIT 10;

-- Step 2: Xem date range
SELECT MIN(created_date), MAX(created_date), COUNT(*)
FROM fact_order WHERE is_deleted = 0;

-- Step 3: Xem NULL distribution
SELECT SUM(CASE WHEN qty IS NULL THEN 1 ELSE 0 END) AS null_count
FROM fact_trip WHERE is_deleted = 0;

-- Step 4: Explode result sau JOIN
SELECT f.*, d.*, td.*
FROM fact_trip f
INNER JOIN dim_ops_trip d ON ...
INNER JOIN dim_ops_trip_detail td ON ...
LIMIT 1;  -- Kiểm tra 1 row sau JOIN
```

---

## PHẦN II: HƯỚNG DẪN SỬ DỤNG CHO CÁC BỘ PHẬN

### 1. Phòng Bán hàng & Dự báo (Sales & Forecast)

**Bảng chính sử dụng:**
- fact_order, dim_ord_order, dim_ord_product_group
- subdim_cus_product, subdim_cus_group_of_product
- dim_cus_location, subdim_cus_customer

**Phân tích tiêu điểm:**
- Xu hướng đơn hàng theo thời gian
- Sản phẩm hot nhất (top products)
- Khách hàng có giá trị cao nhất
- Doanh số theo khu vực giao hàng

---

### 2. Phòng Vận chuyển (Operations)

**Bảng chính sử dụng:**
- fact_trip, dim_ops_trip, dim_ops_trip_detail
- dim_ops_trip_product, dim_ops_dock_register
- subdim_cat_vehicle, subdim_cat_group_of_vehicle
- dim_cus_location, dim_cus_dock

**Phân tích tiêu điểm:**
- Hiệu suất chuyến và thời gian giao hàng
- Tĩnh trạng bốc xếp và chi phí xử lý
- Tận dụng xe (vehicle utilization)
- Idling time & efficiency metrics

---

### 3. Phòng Kế toán (Finance)

**Bảng chính sử dụng:**
- fact_order, fact_trip, fact_dock
- dim_ord_product, dim_ops_trip, dim_cus_location
- subdim_cat_partner

**Phân tích tiêu điểm:**
- Doanh thu/chi phí theo khách hàng
- Lợi nhuận theo chuyến/đơn hàng
- Chi phí vận chuyển và bốc xếp
- Công nợ và hóa đơn

---

### 4. Team BI / Data Analyst

**Phạm vi:**
Toàn bộ dữ liệu để xây dựng các báo cáo, dashboard, mô hình dự báo

**Ưu tiên:**
- fact_order, fact_trip: Dữ liệu giao dịch chính
- dim_ops_trip, dim_cus_location: Chiều phân tích
- Các subdimensions: Để filter/drill-down chi tiết

---

## PHẦN IV: BEST PRACTICES & PERFORMANCE TIPS

### 🔴 NGUYÊN TẮC FDN (Fact-Dimension-SubDimension) - CÓ TÍNH BẮT BUỘC

**Mô hình JOIN duy nhất được phép:**
```
Fact → Dimension → Sub-Dimension
```

Không được phép:
- ❌ Fact → Sub-Dimension (trực tiếp)
- ❌ Dimension → Dimension (không qua Fact)
- ❌ Sub-Dimension → Sub-Dimension

---

### 1. Luôn thêm WHERE điều kiện cho is_deleted

```sql
-- ❌ KHÔNG TỐT
SELECT * FROM fact_order;

-- ✅ TỐT
SELECT * FROM fact_order WHERE is_deleted = 0;
```

### 2. Filter by ngày để tối ưu performance

ClickHouse sử dụng partition theo dữ liệu, vì vậy luôn filter theo ngày:

```sql
WHERE f.is_deleted = 0
    AND toDate(f.created_date) >= today() - interval '30 day'
```

### 3. Sử dụng Fact Tables khi cần dữ liệu sự kiện

- **fact_order**: Dùng khi cần dữ liệu đơn hàng
- **fact_trip**: Dùng khi cần dữ liệu chuyến vận hành
- **fact_dock**: Dùng khi cần dữ liệu bốc xếp

Tránh JOIN quá nhiều bảng; hãy dùng Fact table như trực tuyến để nhận ID/FK.

### 4. Nguyên tắc JOIN: Fact → Dimension → Sub-Dimension ONLY

**Luật vàng:** Không bao giờ JOIN trực tiếp từ Fact sang Sub-Dimension. Phải đi qua Dimension trung gian.

```sql
-- ✅ ĐÚNG: Fact → Dim → SubDim
FROM fact_trip f
INNER JOIN dim_ops_trip t ON f.ops_trip_sk = t.trip_sk
INNER JOIN subdim_cat_vehicle v ON t.vehicle_id = v.id

-- ❌ SAI: JOIN trực tiếp Fact → SubDim (KHÔNG ĐƯỢC PHÉP)
FROM fact_trip f
INNER JOIN subdim_cat_vehicle v ON ...  -- ⛔ Vi phạm nguyên tắc FDN

-- ❌ SAI: Dim → Dim (không nên kết nối độc lập)
FROM dim_ops_trip t
INNER JOIN dim_ops_trip_detail td ON ...  -- Dùng Fact làm "hub"
```

**Lý do:** Nguyên tắc FDN (Fact-Dimension-SubDimension) giúp:
- Query rõ ràng, dễ maintain
- Tránh nhầm lẫn dữ liệu từ bảng nào
- Performance tối ưu trên ClickHouse

### 5. Dùng DISTINCT khi cần count bản ghi duy nhất

```sql
-- Count đơn hàng duy nhất
COUNT(DISTINCT f.ord_order_sk)

-- Count sản phẩm/item duy nhất
COUNT(DISTINCT f.key_sk)
```

### 6. Hiểu cơ chế last_modified_date và composite_last_modified_date

**last_modified_date:** Mốc thời gian thay đổi của bản ghi gốc
```sql
greatest(CreatedDate, ModifiedDate)
```

**composite_last_modified_date:** Mốc thời gian thay đổi của bản ghi + tất cả dimension liên quan
```sql
MAX(last_modified_date từ fact + tất cả dimensions)
```

**Khi nào dùng cái nào:**
- Incremental load: Dùng `last_modified_date` để track delta
- SLA tracking: Dùng `created_date` (thời gian khởi tạo)
- Data freshness check: Dùng `dbt_updated_at` (thời điểm load vào DW)

```sql
-- ✅ Incremental delta (tìm bản ghi thay đổi trong 1 ngày)
WHERE last_modified_date >= now64(3) - interval '1 day'

-- ✅ Thời gian khai báo
WHERE toDate(created_date) >= today() - interval '30 day'

-- ✅ Tính uptime của DW
WHERE dbt_updated_at >= now64(3) - interval '1 hour'
```

### 7. Xử lý NULL/dữ liệu thiếu đúng cách

**Vấn đề:** Nhiều cột (nhất là quantity, weight) có thể NULL

**Giải pháp:**
```sql
-- ❌ SAI: NULL làm sum bị NULL
SELECT SUM(quantity_bbgn) FROM fact_trip;  -- Kết quả có thể NULL

-- ✅ TỐT: Dùng ifNull
SELECT SUM(ifNull(quantity_bbgn, 0)) FROM fact_trip;

-- ✅ TỐT: Dùng CASE (explicit hơn)
SELECT SUM(CASE
    WHEN quantity_bbgn IS NOT NULL THEN quantity_bbgn
    ELSE 0
END) AS total_qty FROM fact_trip;

-- ✅ TỐT: Filter ra NULL nếu cần
SELECT SUM(quantity_bbgn) FROM fact_trip 
WHERE quantity_bbgn IS NOT NULL;
```

### 8. DateTime/Date conversion best practices

```sql
-- Chuyển DateTime sang Date (chặt time thành 00:00:00)
toDate(created_date)  -- DateTime → Date

-- Chuyển DateTime sang Time (bỏ date, lấy time)
toTime(created_date)  -- DateTime → Time

-- Lấy components từ DateTime
toYear(created_date), toMonth(created_date), toDayOfMonth(created_date)
toHour(created_date), toMinute(created_date)

-- Tính khoảng cách thời gian (trả về số ngày/giờ/phút/giây)
dateDiff('day', etd, ata)      -- Số ngày
dateDiff('hour', gate_in, gate_out)  -- Số giờ
dateDiff('minute', loading_start, loading_end)  -- Số phút

-- So sánh date/time
WHERE toDate(created_date) = today()     -- Hôm nay
WHERE toDate(created_date) = yesterday()  -- Hôm qua
WHERE toDate(created_date) >= today() - interval '30 day'  -- 30 ngày gần nhất
```

### 9. Phân biệt các loại surrogate key (key_sk)

| Cột | Ý Nghĩa | Cách thành lập |
|:---|:---|:---|
| **key_sk** | Surrogate Key từ ID gốc | Từ source system ID |
| **ops_trip_sk / ord_order_sk** | Alias của key_sk (ForeignKey) | Trỏ tới key_sk của dimension |
| **id** | ID gốc từ source | Từ ORD_Order.ID, CAT_Product.ID, etc. |

**Cách sử dụng:**
```sql
-- ✅ Join dùng SK
FROM fact_order f
INNER JOIN dim_ord_order do ON f.ord_order_sk = do.key_sk  -- key_sk ở Dim

-- ❌ Tránh join qua ID
FROM fact_order f
INNER JOIN dim_ord_order do ON f.id = do.id  -- Sai cách
```

### 10. Tối ưu với FINAL (nếu cần dữ liệu mới nhất)

ClickHouse ReplacingMergeTree có thể giữ nhiều bản ghi cho cùng key. Dùng FINAL để lấy version mới nhất:

```sql
-- ✅ Lấy data mới nhất, loại bỏ duplicate
SELECT * FROM fact_order
FINAL
WHERE is_deleted = 0
LIMIT 10;

-- ❌ Không dùng FINAL: có thể có duplicate
SELECT * FROM fact_order
WHERE is_deleted = 0
LIMIT 10;
```

**Lưu ý:** FINAL chậm hơn; chỉ dùng khi **GỌC THIẾT** những dữ liệu mới nhất.

### 11. Các QoS (Quality of Service) của Datawarehouse

| Khía cạnh | Tiêu chuẩn |
|:---|:---|
| **Data Freshness** | Cập nhật hàng ngày (Daily) |
| **Retention** | 2+ năm dữ liệu lịch sử |
| **Accuracy** | 100% từ source sau ETL |
| **Consistency** | ReplacingMergeTree quản lý versioning |
| **Completeness** | is_deleted flag để track soft deletes |

### 12. Lựa chọn INNER vs LEFT JOIN đúng cách

```sql
-- ✅ INNER JOIN: Khi PHẢI có data ở cả 2 bảng
FROM fact_order f
INNER JOIN dim_ord_order do ON f.ord_order_sk = do.key_sk
-- Nếu fact_order có ord_order_sk orphan (không có match), row đó sẽ bị loại

-- ✅ LEFT JOIN: Khi data ở Fact có thể chưa được assign vào Trip
FROM fact_order f
LEFT JOIN fact_trip ft ON f.key_sk = ft.ord_product_sk
-- Row fact_order sẽ giữ ngay cả khi chưa có trip

-- ⚠️ Khi nào dùng LEFT JOIN?
WHERE f.is_deleted = 0
    AND toDate(f.created_date) >= today() - interval '1 day'  -- Đơn hàng hôm nay
LEFT JOIN fact_trip ft ON ...  -- Chuyến có thể chưa tạo
-- → Dùng LEFT để xem đơn hàng nào chưa được assign vào chuyến
```

### 13. Filtering logic cho các trạng thái (status)

```sql
-- ✅ Khi cần SLA analysis: lấy tất cả trạng thái
WHERE f.is_deleted = 0

-- ✅ Khi cần thực tế giao hàng: filter cho trạng thái completed
WHERE f.is_deleted = 0
    AND d.status_name IN ('Delivered', 'Completed')
    AND t.ata IS NOT NULL  -- Phải có mốc thời gian thực tế

-- ⚠️ Cẩn thận với NULL status
WHERE f.is_deleted = 0
    AND d.status_id IS NOT NULL  -- Tránh bản ghi status chưa assign
```

### 14. Aggregation patterns thường dùng

```sql
-- Pattern 1: Count + Distinct (đơn vị vs bản ghi)
COUNT(*) AS total_items,
COUNT(DISTINCT f.ord_order_sk) AS unique_orders

-- Pattern 2: Sum weighted (lượng x hệ số)
SUM(CAST(quantity_bbgn AS Float64) * vcf_bbgn) AS cbm_delivered

-- Pattern 3: Min/Max time delta (SLA tracking)
MIN(dateDiff('hour', f.created_date, t.ata)) AS min_delivery_hours,
MAX(dateDiff('hour', f.created_date, t.ata)) AS max_delivery_hours,
AVG(dateDiff('hour', f.created_date, t.ata)) AS avg_delivery_hours

-- Pattern 4: Percentage (thành công / tổng)
ROUND(100.0 * SUM(CASE WHEN status='OK' THEN 1 ELSE 0 END) / COUNT(*), 2) AS success_rate_pct
```

### 15. Debug query - kiểm tra dữ liệu trước khi aggregate

```sql
-- Step 1: Xem sample dữ liệu (limit rows)
SELECT * FROM fact_order
WHERE is_deleted = 0
LIMIT 100;

-- Step 2: Xem distribution
SELECT status_name, COUNT(*) 
FROM dim_ord_order
WHERE is_deleted = 0
GROUP BY status_name;

-- Step 3: Xem date range
SELECT MIN(created_date), MAX(created_date), COUNT(*)
FROM fact_order
WHERE is_deleted = 0;

-- Step 4: Xem NULL distribution
SELECT
    SUM(CASE WHEN quantity_bbgn IS NULL THEN 1 ELSE 0 END) AS null_qty,
    COUNT(*) AS total_rows
FROM fact_trip WHERE is_deleted = 0;

-- Step 5: Explode detail (FROM fact → JOIN to see all columns)
SELECT f.*, d.*, td.*
FROM fact_trip f
INNER JOIN dim_ops_trip d ON f.ops_trip_sk = d.trip_sk
INNER JOIN dim_ops_trip_detail td ON f.ops_trip_detail_sk = td.key_sk
WHERE f.is_deleted = 0
LIMIT 1;  -- Xem 1 row đầu sau JOIN
```

### 6. Xử lý NULL/dữ liệu thiếu

```sql
-- Chuẩn đo cho dữ liệu qty bị thiếu
SUM(CASE
    WHEN ftd.quantity_bbgn IS NOT NULL THEN ftd.quantity_bbgn
    ELSE 0
END)

-- Hoặc dùng ifNull
SUM(ifNull(ftd.quantity_bbgn, 0))
```

### 7. Sử dụng DateTime64(3) cho precision cao

```sql
-- ClickHouse dùng DateTime64(3) tương ứng milliseconds
-- Khi cần convert sang date, dùng toDate()
toDate(f.created_date)

-- Khi cần time, dùng toTime()
toTime(f.created_date)
```

### 8. Tối ưu với FINAL (nếu cần dữ liệu mới nhất)

ClickHouse ReplacingMergeTree có thể giữ nhiều bản ghi cho cùng key. Dùng FINAL để lấy version mới nhất:

```sql
SELECT * FROM fact_order
FINAL
WHERE is_deleted = 0
LIMIT 10;
```

**Lưu ý:** FINAL chậm hơn; chỉ dùng khi GỌC THIẾT những dữ liệu mới nhất.

---

## PHẦN V: CẮT NÉT TẠNG CHUYÊN MỤC

### Phân tích Đơn hàng (Order Analytics)

**Primary fact table:** fact_order  
**Key dimensions:** dim_ord_order, dim_ord_product, dim_cus_location

```sql
-- Template: Doanh số theo khách hàng/sản phẩm/ngày
SELECT
    -- Dimensions
    c.customer_name,
    sp.product_name,
    toDate(fo.created_date) AS order_date,
    -- Measures
    COUNT(DISTINCT fo.key_sk) AS items,
    COUNT(DISTINCT fo.ord_order_sk) AS orders
FROM fact_order fo
INNER JOIN dim_ord_order do ON fo.ord_order_sk = do.key_sk
INNER JOIN dim_cus_location l ON fo.location_from_sk = l.key_sk
INNER JOIN subdim_cus_customer c ON l.cus_customer_sk = c.key_sk
INNER JOIN dim_ord_product p ON fo.ord_product_sk = p.key_sk
INNER JOIN subdim_cus_product sp ON p.subcus_product_sk = sp.key_sk
WHERE fo.is_deleted = 0
GROUP BY c.customer_name, sp.product_name, toDate(fo.created_date);
```

### Phân tích Chuyến vận hành (Trip Analytics)

**Primary fact table:** fact_trip  
**Key dimensions:** dim_ops_trip, dim_ops_trip_detail

```sql
-- Template: Hiệu suất chuyến theo xe/tài xế
SELECT
    v.reg_no,
    v.driver_name,
    COUNT(DISTINCT ft.ops_trip_sk) AS trips,
    AVG(dateDiff('day', t.etd, t.ata)) AS avg_days,
    SUM(CAST(td.quantity_bbgn AS Float64)) AS qty
FROM fact_trip ft
INNER JOIN dim_ops_trip t ON ft.ops_trip_sk = t.trip_sk
INNER JOIN dim_ops_trip_detail td ON ft.ops_trip_detail_sk = td.key_sk
INNER JOIN subdim_cat_vehicle v ON t.vehicle_id = v.id
WHERE ft.is_deleted = 0
GROUP BY v.reg_no, v.driver_name;
```

### Phân tích Bốc xếp (Dock Analytics)

**Primary fact table:** fact_dock  
**Key dimensions:** dim_ops_dock_register, dim_cus_dock

```sql
-- Template: Tải bốc xếp theo ngày/bãy
SELECT
    toDate(dr.register_date) AS dock_date,
    d.dock_name,
    COUNT(*) AS registrations,
    AVG(dateDiff('minute', dr.loading_start, dr.loading_end)) AS avg_loading_min
FROM fact_dock fd
INNER JOIN dim_ops_dock_register dr ON fd.ops_dock_register_sk = dr.key_sk
INNER JOIN dim_cus_dock d ON fd.cus_dock_sk = d.key_sk
WHERE fd.is_deleted = 0
GROUP BY toDate(dr.register_date), d.dock_name;
```

---

## PHẦN VI: TROUBLESHOOTING

| Vấn đề | Nguyên nhân | Giải pháp |
|:---|:---|:---|
| Kết quả query quá chậm | Không filter theo ngày | Thêm `WHERE toDate(created_date) >= today() - interval '30 day'` |
| Số liệu bị trùng lặp | WHERE không có `is_deleted = 0` | Thêm filter `WHERE is_deleted = 0` |
| Không tìm thấy dữ liệu | Dữ liệu chưa được load hoặc sai FK | Kiểm tra data loading log hoặc dùng FINAL |
| JOIN result bị tăng | JOIN trên nhiều Fact cùng lúc | Dùng subquery để joining smart hơn |
| NULL values quá nhiều | Để nguyên NULL | Dùng `ifNull()` hoặc `CASE WHEN IS NOT NULL` |

---

**Tài liệu cập nhật:** 30/03/2026  
**Phiên bản:** 1.2 - STM Datawarehouse Query Examples & Usage Principles     
