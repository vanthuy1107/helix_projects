# Dataset — AcmeFoods Logistics (Sample, Q1 2026)

Bộ dữ liệu mẫu mô phỏng hoạt động vận chuyển hàng tiêu dùng nhanh (FMCG) của **AcmeFoods Vietnam** — một công ty bánh kẹo / thực phẩm hư cấu — trong **3 tháng đầu năm 2026 (01/02/2026 → 30/04/2026)**.

> **Lưu ý**: Đây là dataset hư cấu dùng cho mục đích phỏng vấn. Tên công ty, nhà vận tải, thương hiệu, kho, khu vực giao đều là tên giả. Số liệu (ngày, khối lượng, tỉ lệ) được giữ phân phối thực tế để bài phân tích có ý nghĩa.

---

## Bối cảnh kinh doanh

AcmeFoods sản xuất bánh kẹo & đồ ăn nhẹ, phân phối qua nhiều kênh (siêu thị, cửa hàng tạp hoá, e-commerce, horeca). Công ty có **mạng lưới kho** trên cả nước, và **thuê ngoài 100% vận chuyển** từ ~30-50 nhà vận tải.

Mỗi đơn hàng (Sales Order, gọi tắt **SO**) đi qua các mốc thời gian:
1. **GI date** — ngày xuất kho (Goods Issue).
2. **ETD planned** — thời điểm dự kiến xe rời kho.
3. **ETA planned** — thời điểm dự kiến giao đến khách.
4. **ATD actual** — thời điểm xe thực tế rời kho.
5. **ATA actual** — thời điểm thực tế giao tới khách.

Đội logistics cần các báo cáo định kỳ phục vụ **Supply Chain Manager (SC Manager)**. Cái gì là báo cáo phù hợp — đó là phần bạn tự khám phá.

---

## Cấu trúc dataset

5 file CSV ở cùng folder này, encoding UTF-8 với BOM (Excel mở thẳng được):

| File | Loại | Mô tả | Granularity | Row count |
|---|---|---|---|---|
| `shipments.csv` | Fact | 1 dòng / SO (đơn hàng giao) | Order | ~31k |
| `trips.csv` | Fact | 1 dòng / chuyến xe vận hành | Trip | ~6.6k |
| `carriers.csv` | Dim | Danh sách nhà vận tải | Carrier | 11 |
| `locations.csv` | Dim | Kho + khu vực giao + điểm nhận | Location | 19 |
| `products.csv` | Dim | Thương hiệu + nhóm hàng + kênh bán | Product | 40 |

Không có quan hệ FK cứng — bạn cần **join theo code** (xem § Relationships).

---

## Schema chi tiết

### `shipments.csv`

| Column | Type | Mô tả |
|---|---|---|
| `shipment_id` | string | Mã đơn hàng duy nhất, format `SH-2026-XXXXXX` |
| `warehouse_code` | string | Mã kho xuất hàng, FK → `locations.location_code` (location_type='WAREHOUSE') |
| `delivery_area` | string | Khu vực giao (tên VN public, vd "Ha Noi", "Mekong 1") — có thể trống |
| `cargo_group` | string | Nhóm hàng (FRESH / DRY / MOONCAKE / POSM/OFFBOM / PM / TEST / EQUIPMENT) |
| `carrier_code` | string | Mã nhà vận tải, FK → `carriers.carrier_code` — có thể trống |
| `sales_channel` | string | Kênh bán hàng (MT/GT/KA/DRP/B2B/EXPORT/OTHER) |
| `vehicle_type` | string | Loại xe vận hành (vd "5T", "11T", "1.4T") — có thể trống |
| `gi_date` | date | Ngày xuất kho (Goods Issue) — có thể trống |
| `etd_planned` | datetime | Thời điểm planned xe rời kho |
| `eta_planned` | datetime | Thời điểm planned giao tới khách |
| `atd_actual` | datetime | Thời điểm actual xe rời kho |
| `ata_actual` | datetime | Thời điểm actual giao tới khách |
| `planned_qty_cse` | number | Số lượng case (CSE) planned |
| `planned_weight_kg` | number | Khối lượng planned (kg) |
| `planned_volume_cbm` | number | Thể tích planned (m³) |
| `planned_pallets` | number | Số pallet planned |
| `delivered_qty_cse` | number | Số lượng case (CSE) thực tế giao |

### `trips.csv`

| Column | Type | Mô tả |
|---|---|---|
| `trip_id` | string | Mã chuyến xe, format `TR-2026-XXXXXX` |
| `tender_date` | date | Ngày phát hành tender (gọi xe) |
| `eta_operation` | datetime | ETA vận hành |
| `ata_operation` | datetime | ATA vận hành |
| `pickup_location` | string | Mã điểm nhận hàng, FK → `locations.location_code` (location_type='PICKUP_LOCATION') |
| `delivery_area` | string | Khu vực giao (cùng vocab với shipments) |
| `carrier_code` | string | FK → `carriers.carrier_code` |
| `vehicle_type` | string | Loại xe (vd "1.4T", "2T", "5T", "11T", "11T_16PL") |
| `cargo_group` | string | Nhóm hàng (có thể chứa nhiều group nếu trip ghép) |
| `vfr_pct` | number | Tỉ lệ tận dụng xe (%), 0-100 |
| `vfr_by_ton` | number | Tỉ lệ tận dụng theo trọng tải (%) |
| `vfr_by_volume` | number | Tỉ lệ tận dụng theo thể tích (%) |
| `planned_ton` | number | Tải trọng kế hoạch (tấn) |
| `planned_cbm` | number | Thể tích kế hoạch (m³) |

### `carriers.csv`

| Column | Type | Mô tả |
|---|---|---|
| `carrier_code` | string | PK, format `CARxxx` |
| `carrier_name` | string | Tên nhà vận tải |

### `locations.csv`

| Column | Type | Mô tả |
|---|---|---|
| `location_type` | string | `WAREHOUSE` / `DELIVERY_AREA` / `PICKUP_LOCATION` |
| `location_code` | string | PK trong từng location_type |
| `location_name` | string | Tên hiển thị |
| `location_group` | string | Group cha (chỉ với WAREHOUSE, có thể trống) |

Lưu ý: `WAREHOUSE` và `PICKUP_LOCATION` là 2 khái niệm khác nhau (kho xuất hàng vs hub trung chuyển). `shipments.warehouse_code` join với `WAREHOUSE`, `trips.pickup_location` join với `PICKUP_LOCATION`.

### `products.csv`

| Column | Type | Mô tả |
|---|---|---|
| `dim_type` | string | `BRAND_CARGO` hoặc `SALES_CHANNEL` |
| `code` | string | PK trong từng dim_type (vd brand code, channel code) |
| `name` | string | Tên hiển thị |
| `parent_group` | string | Với `BRAND_CARGO`: cargo group cha. Với `SALES_CHANNEL`: rỗng. |

---

## Relationships

```
                    +-----------------+
                    |  carriers.csv   |
                    +--------+--------+
                             |
              carrier_code   |
                             |
+-----------------+   +------v-----------+   +------------------+
|  locations.csv  +---+  shipments.csv   +---+  products.csv    |
+-----------------+   +------------------+   +------------------+
        ^                       
        |                      
        |                      
+-------+----------+   
|  trips.csv       |
+------------------+
```

- `shipments` join `carriers` qua `carrier_code`.
- `shipments` join `locations` qua `warehouse_code` (filter `location_type='WAREHOUSE'`) hoặc `delivery_area` (filter `location_type='DELIVERY_AREA'`).
- `shipments` join `products` qua `sales_channel` (filter `dim_type='SALES_CHANNEL'`).
- `trips` join `locations` qua `pickup_location` (filter `location_type='PICKUP_LOCATION'`).
- `trips` không link 1-1 với `shipments` — 1 trip có thể chở nhiều shipments hoặc 1 shipment ride nhiều trips. **Bạn tự suy luận khi cần.**

---

## Một vài quirk bạn nên biết khi profile

1. **Empty cells = NULL**: nhiều cột có giá trị trống thay vì NULL marker. Khi đọc bằng pandas → `NaN`. Trong Excel hiển thị như cell trống.
2. **Date semantic**: `gi_date` là ngày xuất kho, `eta_planned` là ngày dự kiến giao. **Một SO có thể có `eta_planned` trong window nhưng `gi_date` ngoài window** (vd ETA cuối tháng 4, GI đầu tháng 5).
3. **Brand không link xuống shipment**: brand chỉ tồn tại trong `products.csv` như dim độc lập, không có FK xuống `shipments`. Nếu muốn phân tích theo brand, bạn cần quyết định cách tiếp cận.
4. **Over-delivery**: vài đơn có `delivered_qty_cse > planned_qty_cse`. Có thể là data error hoặc giao thêm theo yêu cầu khách — bạn quyết định cách xử lý.
5. **Multi-cargo trip**: cột `trips.cargo_group` có thể chứa nhiều group cách nhau bằng dấu phẩy (vd "DRY, FRESH") khi 1 chuyến chở nhiều nhóm hàng.
6. **Vehicle type mix**: nhiều loại xe (1.4T → 11T), capacity khác nhau — so sánh metric cross-type cần cẩn thận.
7. **Encoding**: file lưu UTF-8 với BOM, Excel/pandas mở thẳng được.

---

## Sample query gợi ý (chỉ để bạn ấm máy, không bắt buộc theo hướng này)

```sql
-- Số lượng shipment theo tháng × kênh bán
SELECT
    DATE_TRUNC('month', gi_date)  AS month,
    sales_channel,
    COUNT(*)                       AS total_so,
    SUM(planned_qty_cse)           AS total_cse_planned,
    SUM(delivered_qty_cse)         AS total_cse_delivered
FROM shipments
WHERE gi_date IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2;
```

```python
# pandas equivalent
import pandas as pd
df = pd.read_csv('shipments.csv', parse_dates=['gi_date','eta_planned','ata_actual'])
df['month'] = df['gi_date'].dt.to_period('M')
agg = df.groupby(['month','sales_channel']).agg(
    total_so=('shipment_id','count'),
    total_cse_planned=('planned_qty_cse','sum'),
    total_cse_delivered=('delivered_qty_cse','sum'),
)
```

---

Good luck — be curious.
