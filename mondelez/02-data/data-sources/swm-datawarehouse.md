# TÀI LIỆU THIẾT KẾ DỮ LIỆU HỆ THỐNG SMART WAREHOUSE MANAGEMENT (SWM)

## PHẦN I: TỔNG QUAN HỆ THỐNG

Hệ thống dữ liệu **Smart Warehouse Management (SWM)** được thiết kế để quản lý toàn diện vòng đời hàng hóa. Dữ liệu được tổ chức thành **6 nhóm chính**, kết hợp giữa thông tin danh mục (Dimensions), dữ liệu giao dịch (Facts), và danh mục tham chiếu (Reference Data).

### 0. Nhóm Quản lý Đơn mua hàng (Purchasing)
Quản lý luồng đơn mua từ lập kế hoạch đến nhận hàng.
* **Thành phần:** `dim_po`, `dim_podetail`, `fact_purchase_fulfillment`.
* **Vai trò:** Lưu trữ thông tin đơn mua hàng, nhà cung cấp, số lượng dự kiến, phân tích tỷ lệ hoàn thành và chênh lệch giao hàng.

### 1. Nhóm Nghiệp vụ Nhập kho (Inbound)
Quản lý luồng hàng đi vào kho từ nhà cung cấp hoặc nhà máy.
* **Thành phần:** `dim_receipt`, `dim_receiptdetail`, `fact_inbound`.
* **Vai trò:** Lưu trữ thông tin chứng từ, số lô (lot), hạn sử dụng và ghi nhận sự kiện nhập hàng thực tế.

### 2. Nhóm Quản lý Tồn kho (Inventory)
Theo dõi "vật lý" hàng hóa đang nằm ở đâu và trạng thái khả dụng.
* **Thành phần:** `dim_lotxlocxid`, `dim_sku`, `dim_loc`, `dim_pack`, `fact_inventory`.
* **Vai trò:** Quản lý chi tiết đến từng mã kiện (LPN), vị trí ô kệ. Phản ánh bức tranh tồn kho hiện tại (hàng sẵn sàng, hàng bị khóa, hàng lỗi).

### 3. Nhóm Nghiệp vụ Xuất kho (Outbound)
Quản lý luồng hàng đi ra khỏi kho để giao cho khách hàng hoặc chuyển kho.
* **Thành phần:** `dim_orders`, `dim_orderdetail`, `dim_pickdetail`, `fact_outbound`, `fact_order_fulfillment`.
* **Vai trò:** Theo dõi từ lúc tiếp nhận đơn hàng, lịch sử nhân viên lấy hàng từ kệ (Picking) cho đến khi sản phẩm thực tế rời kho.

### 4. Danh mục Tham chiếu (Master Data Reference)
Quản lý các data tham chiếu được dùng chung trong toàn bộ hệ thống.
* **Thành phần:** `dim_codelkup`, `subdim_storer`, `subdim_customergroup`.
* **Vai trò:** Cung cấp danh mục hệ thống, danh sách khách hàng, nhóm khách hàng.

**Metadata quản lý:** Tất cả các bảng đều sử dụng các cột kỹ thuật như `is_deleted`, `dbt_updated_at`, `last_modified_date` để quản lý lịch sử thay đổi và dấu vết dữ liệu bị xóa từ nguồn.

**Kho dữ liệu:** ClickHouse (ReplacingMergeTree engine cho CDC)
**Phạm vi:** 6 kho: BKD1, BKD2, BKD3, NKD, VN821, VN831
**Chủ hàng:** MDLZ (Mondelez)

---

# PHẦN II: CHI TIẾT THIẾT KẾ DỮ LIỆU

## 1. NHÓM BẢNG DANH MỤC (DIMENSION TABLES)

### 1.1. Bảng dim_sku (Danh mục Sản phẩm)

**Mô tả:** Danh mục sản phẩm chính, chứa thông tin chi tiết về từng SKU bao gồm thông số vật lý, chiến lược cất hàng, lấy hàng.

**Nguồn dữ liệu:** `swm.sku` (bảng sku từ hệ thống WMS)

**Quy trình xử lý:**
- Lọc: `STORERKEY = 'MDLZ'` và `WHSEID IN ('BKD1','BKD2','BKD3','NKD','VN821','VN831')`
- Surrogate Key: `cityHash64(ifNull(sku,''), ifNull(whseid,''), ifNull(storer_key,''))`
- last_modified_date: `greatest(ADDDATE, EDITDATE)` với kiểu toDateTime64(3)
- Nạp tăng trưởng (Incremental) dựa trên so sánh `last_modified_date`

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, sku, storer_key)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.sku | sku_id | VARCHAR(129) | ID định danh duy nhất của sản phẩm trong hệ thống nguồn |
| SKU | swm.sku | sku | VARCHAR(180) | Mã sản phẩm (Stock Keeping Unit) - Duy nhất theo (whseid, storer_key) |
| WHSEID | swm.sku | whseid | VARCHAR(108) | Mã kho quản lý sản phẩm (BKD1, BKD2, BKD3, NKD, VN821, VN831) |
| STORERKEY | swm.sku | storer_key | VARCHAR(144) | Mã chủ hàng (MDLZ) - Luôn lọc theo giá trị này |
| SKUGROUP | swm.sku | sku_group | VARCHAR(234) | Nhóm sản phẩm (cấp 1) - Dùng phân tích danh mục |
| CATEGORY | swm.sku | category | VARCHAR(144) | Phân loại sản phẩm (cấp 2) theo hệ thống SWM |
| DESCR | swm.sku | descr | VARCHAR(900) | Mô tả chi tiết tên sản phẩm |
| PACKKEY | swm.sku | pack_key | VARCHAR(180) | Mã quy cách đóng gói liên kết với bảng dim_pack |
| STDGROSSWGT | swm.sku | std_grossweight | DECIMAL(18,4) | Trọng lượng thô tiêu chuẩn (Kg/Unit) |
| STDNETWGT | swm.sku | std_netweight | DECIMAL(18,4) | Trọng lượng tịnh tiêu chuẩn (không bao bì) |
| STDCUBE | swm.sku | std_cube | DECIMAL(18,4) | Thể tích tiêu chuẩn - Số khối (m³) |
| STDLENGTH | swm.sku | std_length | DECIMAL(18,4) | Chiều dài tiêu chuẩn của sản phẩm (Master Unit) |
| STDWIDTH | swm.sku | std_width | DECIMAL(18,4) | Chiều rộng tiêu chuẩn của sản phẩm (Master Unit) |
| STDHEIGTH | swm.sku | std_height | DECIMAL(18,4) | Chiều cao tiêu chuẩn của sản phẩm (Master Unit) |
| STRATEGYKEY | swm.sku | strategy_key | VARCHAR(180) | Chiến lược allocate hàng cho nhân viên picking (VD: FEFO, LIFO) |
| PUTAWAYZONE | swm.sku | putaway_zone | VARCHAR(180) | Đánh dấu cất hàng: Loose (lẻ) hay Full (kiện đủ) |
| PUTAWAYSTRATEGYKEY | swm.sku | putaway_strategy_key | VARCHAR(180) | Chiến lược cất hàng (VD: FIFO, Weight-based, Zone-based) |
| REPLENISHMENTSTRATEGYKEY | swm.sku | replenish_strategy_key | VARCHAR(180) | Chiến lược châm hàng từ khu lưu trữ chính |
| ADDDATE | swm.sku | created_date | TIMESTAMP | Ngày giờ tạo sản phẩm trên hệ thống |
| EDITDATE | swm.sku | updated_date | TIMESTAMP | Ngày giờ cập nhật sản phẩm gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.sku | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Dùng để tracking delta incremental |
| -/-  | -/- | key_sk | VARCHAR(32) | Khóa thay thế (Surrogate Key) - Hash 64-bit từ sku, whseid, storer_key |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái: false (hoạt động), true (đã bị xóa/hết hạn) |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm được load vào DW (batch timestamp) |

---

### 1.2. Bảng dim_loc (Danh mục Vị trí)

**Mô tả:** Danh mục vị trí bin trong kho, nơi lưu trữ và quản lý hàng hóa.

**Nguồn dữ liệu:** `swm.loc` (bảng vị trí bin từ hệ thống WMS)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, loc)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.loc | loc_id | VARCHAR(129) | ID gốc từ hệ thống WMS |
| LOC | swm.loc | loc | VARCHAR(144) | Mã vị trí (bin) |
| WHSEID | swm.loc | whseid | VARCHAR(108) | Mã kho |
| LOGICALLOCATION | swm.loc | logical_location | VARCHAR(180) | Vị trí bin vật lý trong kho |
| LINE | swm.loc | line | VARCHAR(180) | Vị trí dãy (aisle) |
| BIN | swm.loc | bin | VARCHAR(180) | Vị trí bin chi tiết |
| STATUS | swm.loc | status | VARCHAR(144) | Trạng thái của bin (Available, Blocked,...) |
| STACKLIMIT | swm.loc | stack_limit | DECIMAL(18,4) | Số pallet tối đa chứa tại bin |
| PUTAWAYZONE | swm.loc | putaway_zone | VARCHAR(180) | Khu vực cất hàng (Loose/Full) |
| ADDDATE | swm.loc | created_date | TIMESTAMP | Ngày giờ tạo vị trí |
| EDITDATE | swm.loc | updated_date | TIMESTAMP | Ngày giờ cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.loc | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Dùng tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế (Surrogate Key) - Hash từ loc, whseid |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm (false = hoạt động) |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm được load vào DW |

---

### 1.3. Bảng dim_pack (Danh mục Quy cách Đóng gói)

**Mô tả:** Danh mục quy cách đóng gói/đơn vị bao bì cho sản phẩm.

**Nguồn dữ liệu:** `swm.pack` (bảng pack từ hệ thống WMS)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, pack_key)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.pack | pack_id | VARCHAR(129) | ID gốc từ hệ thống |
| PACKKEY | swm.pack | pack_key | VARCHAR(180) | Mã quy cách đóng gói |
| WHSEID | swm.pack | whseid | VARCHAR(108) | Mã kho |
| QTY | swm.pack | qty | DECIMAL(18,4) | Số lượng unit trong quy cách |
| PALLET | swm.pack | pallet | DECIMAL(18,4) | Số lượng pallet |
| INNERPACK | swm.pack | inner_pack | DECIMAL(18,4) | Số lượng inner pack |
| ADDDATE | swm.pack | created_date | TIMESTAMP | Ngày giờ tạo |
| EDITDATE | swm.pack | updated_date | TIMESTAMP | Ngày giờ cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.pack | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế - Hash từ whseid, pack_key |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

---

### 1.4. Bảng dim_po (Đơn Mua Hàng - Header)

**Mô tả:** Thông tin đơn mua hàng từ nhà cung cấp hoặc chuyển kho nội bộ.

**Nguồn dữ liệu:** `swm.po` (bảng purchase order từ hệ thống)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, po_key)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.po | po_id | VARCHAR(129) | ID gốc từ hệ thống |
| WHSEID | swm.po | whseid | VARCHAR(108) | Mã kho nhận hàng |
| POKEY | swm.po | po_key | VARCHAR(180) | Mã chứng từ Purchase Order |
| STORERKEY | swm.po | storer_key | VARCHAR(144) | Mã chủ hàng (MDLZ) |
| POTYPE | swm.po | po_type | VARCHAR(180) | Loại đơn PO (Nhập mua, chuyển kho nội bộ,...) |
| SELLERNAME | swm.po | seller_name | VARCHAR(900) | Tên nhà cung cấp (Supplier/Vendor) |
| BUYERCITY | swm.po | buyer_city | VARCHAR(180) | Thành phố nhận hàng |
| BUYERSTATE | swm.po | buyer_state | VARCHAR(180) | Tỉnh/Bang nhận hàng |
| BUYERZIP | swm.po | buyer_zip | VARCHAR(180) | Mã bưu chính |
| BUYERPHONE | swm.po | buyer_phone | VARCHAR(180) | Số điện thoại liên hệ bên nhận |
| PODATE | swm.po | po_date | TIMESTAMP | Ngày lập chứng từ |
| EXPECTEDRECEIPTDATE | swm.po | expected_receipt_date | TIMESTAMP | Ngày dự kiến nhập hàng |
| ADDDATE | swm.po | created_date | TIMESTAMP | Ngày tạo bản ghi trong hệ thống |
| EDITDATE | swm.po | updated_date | TIMESTAMP | Ngày cập nhật lần cuối |
| MAX(ADDDATE, EDITDATE) | swm.po | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế - Hash từ whseid, po_key |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

---

### 1.5. Bảng dim_podetail (Đơn Mua Hàng - Chi tiết)

**Mô tả:** Chi tiết từng dòng hàng hóa trong đơn mua, bao gồm số lượng dự kiến, chốt, và thực nhập.

**Nguồn dữ liệu:** `swm.podetail` (bảng chi tiết PO)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, po_key, po_line_number)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.podetail | podetail_id | VARCHAR(129) | ID gốc từ hệ thống |
| WHSEID | swm.podetail | whseid | VARCHAR(108) | Mã kho |
| POKEY | swm.podetail | po_key | VARCHAR(180) | Mã chứng từ Purchase Order |
| POLINENUMBER | swm.podetail | po_line_number | VARCHAR(180) | Mã dòng trong PO |
| STORERKEY | swm.podetail | storer_key | VARCHAR(144) | Mã chủ hàng (MDLZ) |
| PACKKEY | swm.podetail | pack_key | VARCHAR(180) | Mã quy cách đóng gói |
| SKU | swm.podetail | sku | VARCHAR(180) | Mã sản phẩm |
| SKUDESCR | swm.podetail | sku_description | VARCHAR(900) | Mô tả sản phẩm |
| UOM | swm.podetail | uom | VARCHAR(108) | Đơn vị tính |
| QTYORIGINAL | swm.podetail | qty_original | DECIMAL(18,4) | Số lượng dự kiến ban đầu |
| QTYORDERED | swm.podetail | qty_ordered | DECIMAL(18,4) | Số lượng đã chốt đặt hàng |
| QTYRECEIVED | swm.podetail | qty_received | DECIMAL(18,4) | Số lượng thực tế đã nhập kho |
| UNITCOST | swm.podetail | unit_cost | DECIMAL(18,4) | Đơn giá mua |
| STATUS | swm.podetail | status_code | VARCHAR(144) | Mã trạng thái dòng PO |
| CONDITION | swm.podetail | condition_code | VARCHAR(144) | Mã tình trạng hàng |
| ADDDATE | swm.podetail | created_date | TIMESTAMP | Ngày tạo bản ghi |
| EDITDATE | swm.podetail | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.podetail | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế - Hash từ whseid, po_key, po_line_number |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

---

### 1.6. Bảng dim_receipt (Chứng từ Nhập kho - Header)

**Mô tả:** Thông tin chứng từ nhập kho (ASN - Advanced Shipping Notice).

**Nguồn dữ liệu:** `swm.receipt` (bảng receipt từ hệ thống)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, receipt_key)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.receipt | receipt_id | VARCHAR(129) | ID gốc từ hệ thống |
| WHSEID | swm.receipt | whseid | VARCHAR(108) | Mã kho nhập hàng |
| RECEIPTKEY | swm.receipt | receipt_key | VARCHAR(180) | Mã đơn nhập (ASN) |
| STORERKEY | swm.receipt | storer_key | VARCHAR(144) | Mã chủ hàng (MDLZ) |
| POKEY | swm.receipt | po_key | VARCHAR(180) | Mã đơn PO liên kết |
| EXTERNRECEIPTKEY | swm.receipt | extern_receipt_key | VARCHAR(180) | Mã đơn PO từ khách hàng |
| STATUS | swm.receipt | status_code | VARCHAR(144) | Mã trạng thái nhập hàng |
| STATUS | swm.receipt | status_name | VARCHAR(180) | Tên trạng thái nhập hàng (Received, Partial,...) |
| TYPE | swm.receipt | type | VARCHAR(180) | Loại đơn nhập |
| RECEIPTGROUP | swm.receipt | receipt_group | VARCHAR(180) | Nhóm công việc nhập |
| SUPPLIERCODE | swm.receipt | supplier_code | VARCHAR(180) | Mã nhà cung cấp |
| SUPPLIERNAME | swm.receipt | supplier_name | VARCHAR(900) | Tên nhà cung cấp |
| RECEIPTDATE | swm.receipt | receipt_date | TIMESTAMP | Ngày thực nhập của đơn ASN |
| EXPECTEDRECEIPTDATE | swm.receipt | expected_receipt_date | TIMESTAMP | Ngày dự kiến nhập |
| ADDDATE | swm.receipt | created_date | TIMESTAMP | Ngày tạo bản ghi |
| EDITDATE | swm.receipt | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.receipt | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế - Hash từ whseid, receipt_key |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

---

### 1.7. Bảng dim_receiptdetail (Chứng từ Nhập kho - Chi tiết)

**Mô tả:** Chi tiết từng dòng hàng hóa trong chứng từ nhập, bao gồm số lô, hạn sử dụng, số lượng.

**Nguồn dữ liệu:** `swm.receiptdetail` (bảng chi tiết receipt)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, receipt_key, receipt_line_number)
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.receiptdetail | receiptdetail_id | VARCHAR(129) | ID gốc từ hệ thống |
| WHSEID | swm.receiptdetail | whseid | VARCHAR(108) | Mã kho |
| RECEIPTKEY | swm.receiptdetail | receipt_key | VARCHAR(180) | Mã đơn nhập (ASN) |
| RECEIPTLINENUMBER | swm.receiptdetail | receipt_line_number | VARCHAR(180) | Mã dòng trong chứng từ nhập |
| STORERKEY | swm.receiptdetail | storer_key | VARCHAR(144) | Mã chủ hàng (MDLZ) |
| POKEY | swm.receiptdetail | po_key | VARCHAR(180) | Mã đơn PO liên kết |
| POLINENUMBER | swm.receiptdetail | po_line_number | VARCHAR(180) | Mã dòng trong PO |
| LPNID | swm.receiptdetail | lpnid | VARCHAR(180) | Mã LPNID (kiện hàng) |
| PALLETID | swm.receiptdetail | palletid | VARCHAR(180) | Mã Pallet |
| LOTTABLE01 | swm.receiptdetail | lottable01 | VARCHAR(180) | Số lô (Lot) |
| LOTTABLE04 | swm.receiptdetail | lottable04 | TIMESTAMP | Ngày sản xuất (NSX) |
| LOTTABLE05 | swm.receiptdetail | lottable05 | TIMESTAMP | Hạn sử dụng (HSD) |
| LOTTABLE06 | swm.receiptdetail | lottable06 | VARCHAR(180) | Thông tin lô mở rộng |
| DATERECEIVED | swm.receiptdetail | date_received | TIMESTAMP | Ngày thực nhập của từng dòng |
| CONDITIONCODE | swm.receiptdetail | condition_code | VARCHAR(144) | Tình trạng hàng nhập |
| SKU | swm.receiptdetail | sku | VARCHAR(180) | Mã sản phẩm |
| PACKKEY | swm.receiptdetail | pack_key | VARCHAR(180) | Mã quy cách sản phẩm |
| UOM | swm.receiptdetail | uom | VARCHAR(108) | Đơn vị tính |
| QTYRECEIVED | swm.receiptdetail | qty_received | DECIMAL(18,4) | Số lượng hàng thực nhập |
| STATUS | swm.receiptdetail | status_code | VARCHAR(144) | Mã tình trạng nhập của dòng |
| STATUS | swm.receiptdetail | status_name | VARCHAR(180) | Tên trạng thái nhập |
| TYPE | swm.receiptdetail | type | VARCHAR(180) | Loại đơn nhập |
| ADDDATE | swm.receiptdetail | created_date | TIMESTAMP | Ngày tạo bản ghi |
| EDITDATE | swm.receiptdetail | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.receiptdetail | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế - Hash từ whseid, receipt_key, receipt_line_number |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

---

### 1.8. Bảng dim_orders (Đơn Hàng Khách - Header)

**Mô tả:** Thông tin đơn hàng từ khách hàng để xuất kho.

**Nguồn dữ liệu:** `swm.orders` (bảng orders từ hệ thống)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, storer_key, order_key)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.orders | orders_id | VARCHAR(129) | ID gốc từ hệ thống |
| WHSEID | swm.orders | whseid | VARCHAR(108) | Mã kho xuất hàng |
| STORERKEY | swm.orders | storer_key | VARCHAR(144) | Mã chủ hàng (MDLZ) |
| ORDERKEY | swm.orders | order_key | VARCHAR(180) | Mã đơn xuất (SO - Sales Order) |
| EXTERNORDERKEY | swm.orders | extern_order_key | VARCHAR(180) | Mã đơn DO (Delivery Order) từ khách hàng |
| CONSIGNEEKEY | swm.orders | consignee_key | VARCHAR(180) | Mã khách hàng (giáo đến) |
| STATUS | swm.orders | status_code | VARCHAR(144) | Mã trạng thái xuất hàng |
| TYPE | swm.orders | type | VARCHAR(180) | Loại đơn xuất |
| SYNCSTATUS | swm.orders | sync_status | VARCHAR(180) | Trạng thái đồng bộ với STM |
| SYNCSDATE | swm.orders | sync_date | DATETIME | Ngày trạng thái đồng bộ với STM |
| ORDERDATE | swm.orders | order_date | TIMESTAMP | Ngày đặt hàng |
| NOTES2 | swm.orders | notes2 | STRING | remark lý do rớt đơn của kho |
| DELIVERYDATE | swm.orders | delivery_date | TIMESTAMP | GI date (Ngày dự kiến xe đến kho) |
| REQUESTEDSHIPDATE | swm.orders | requested_ship_date | TIMESTAMP | Ngày yêu cầu giao hàng |
| ACTUALSHIPDATE | swm.orders | actual_ship_date | TIMESTAMP | Ngày thực tế giao hàng |
| ADDDATE | swm.orders | created_date | TIMESTAMP | Ngày tạo bản ghi |
| EDITDATE | swm.orders | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.orders | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế - Hash từ whseid, order_key, storer_key |
| -/- | -/- | subdim_storer_sk | VARCHAR(32) | Khóa con của bảng subdim_storer cho khách hàng giao hàng |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

---

### 1.9. Bảng dim_orderdetail (Đơn Hàng Khách - Chi tiết)

**Mô tả:** Chi tiết từng dòng hàng hóa trong đơn hàng khách, bao gồm số lượng kế hoạch, picked, shipped.

**Nguồn dữ liệu:** `swm.orderdetail` (bảng chi tiết order)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, order_key, order_line_number)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.orderdetail | orderdetail_id | VARCHAR(129) | ID gốc từ hệ thống |
| WHSEID | swm.orderdetail | whseid | VARCHAR(108) | Mã kho |
| ORDERKEY | swm.orderdetail | order_key | VARCHAR(180) | Mã đơn xuất |
| ORDERLINENUMBER | swm.orderdetail | order_line_number | VARCHAR(180) | Mã dòng trong đơn hàng |
| STORERKEY | swm.orderdetail | storer_key | VARCHAR(144) | Mã chủ hàng (MDLZ) |
| EXTERNORDERKEY | swm.orderdetail | extern_order_key | VARCHAR(180) | Mã đơn DO |
| SKU | swm.orderdetail | sku | VARCHAR(180) | Mã sản phẩm |
| UOM | swm.orderdetail | uom | VARCHAR(108) | Đơn vị tính |
| PACKKEY | swm.orderdetail | pack_key | VARCHAR(180) | Mã quy cách sản phẩm |
| LOT | swm.orderdetail | lot | VARCHAR(180) | Số lot |
| LPNID | swm.orderdetail | lpnid | VARCHAR(180) | Mã LPNID |
| PALLETID | swm.orderdetail | palletid | VARCHAR(180) | Mã Pallet |
| LOC | swm.orderdetail | loc | VARCHAR(180) | Vị trí bin |
| ORIGINALQTY | swm.orderdetail | original_qty | DECIMAL(18,4) | Số lượng kế hoạch (Header) |
| SHIPPEDQTY | swm.orderdetail | shipped_qty | DECIMAL(18,4) | Số lượng thực xuất (Header) |
| QTYPICKED | swm.orderdetail | qty_picked | DECIMAL(18,4) | Số lượng đã pick hàng |
| STATUS | swm.orderdetail | status_code | VARCHAR(144) | Mã trạng thái chi tiết đơn |
| -/- | -/- | status_name | VARCHAR(180) | Tên trạng thái đơn hàng (được tính từ status_code) |
| CONDITIONCODE | swm.orderdetail | condition_code | VARCHAR(144) | Tình trạng hàng |
| ACTUALSHIPDATE | swm.orderdetail | actual_ship_date | TIMESTAMP | Ngày thực xuất |
| LOTTABLE04 | swm.orderdetail | lottable04 | TIMESTAMP | Ngày sản xuất lô hàng |
| ADDDATE | swm.orderdetail | created_date | TIMESTAMP | Ngày tạo bản ghi |
| EDITDATE | swm.orderdetail | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.orderdetail | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế - Hash từ whseid, order_key, order_line_number |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

---

### 1.10. Bảng dim_pickdetail (Chi tiết Picking/Xuất kho)

**Mô tả:** Chi tiết quá trình lấy hàng từ kệ, bao gồm vị trí bin, LPNID, số lượng thực tế.

**Nguồn dữ liệu:** `swm.pickdetail` (bảng chi tiết picking)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, pick_detail_key)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.pickdetail | pickdetail_id | VARCHAR(129) | ID gốc từ hệ thống |
| PICKDETAILKEY | swm.pickdetail | pick_detail_key | VARCHAR(180) | Mã chi tiết pick hàng |
| WHSEID | swm.pickdetail | whseid | VARCHAR(108) | Mã kho |
| STORERKEY | swm.pickdetail | storer_key | VARCHAR(144) | Mã chủ hàng (MDLZ) |
| ORDERKEY | swm.pickdetail | order_key | VARCHAR(180) | Mã đơn xuất |
| ORDERLINENUMBER | swm.pickdetail | order_line_number | VARCHAR(180) | Mã dòng hàng hóa |
| LOC | swm.pickdetail | loc | VARCHAR(180) | Vị trí bin lấy hàng |
| LPNID | swm.pickdetail | lpnid | VARCHAR(180) | Mã LPNID |
| PALLETID | swm.pickdetail | palletid | VARCHAR(180) | Mã palletID |
| PACKKEY | swm.pickdetail | pack_key | VARCHAR(180) | Mã quy cách sản phẩm |
| SKU | swm.pickdetail | sku | VARCHAR(180) | Mã sản phẩm |
| LOT | swm.pickdetail | lot | VARCHAR(180) | Số lot thực tế pick |
| QTY | swm.pickdetail | qty | DECIMAL(18,4) | Số lượng thực xuất (Master Unit) |
| UOMQTY | swm.pickdetail | uom_qty | DECIMAL(18,4) | Số lượng theo đơn vị lẻ |
| UOM | swm.pickdetail | uom | VARCHAR(108) | Đơn vị tính |
| STATUS | swm.pickdetail | status | VARCHAR(144) | Trạng thái xuất hàng (Allocate/Pick/Ship) |
| ADDDATE | swm.pickdetail | created_date | TIMESTAMP | Ngày tạo bản ghi |
| EDITDATE | swm.pickdetail | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.pickdetail | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế - Hash từ whseid, pick_detail_key |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

---

### 1.11. Bảng dim_lotattribute (Thuộc tính Lô hàng)

**Mô tả:** Danh mục thuộc tính của từng số lô (lot), bao gồm các thông tin như số lô nội bộ, số lô từ nhà cung cấp, ngày sản xuất, hạn sử dụng, và các trường thuộc tính tùy chỉnh.

**Nguồn dữ liệu:** `swm.lotattribute` (bảng thuộc tính lô từ hệ thống WMS)

**Quy trình xử lý:**
- Lọc: `STORERKEY = 'MDLZ'` và `WHSEID IN ('BKD1','BKD2','BKD3','NKD','VN821','VN831')`
- Surrogate Key: `cityHash64(lot, sku, whseid, storer_key)`
- Foreign Key sang dim_sku: `cityHash64(sku, whseid, storer_key)`
- last_modified_date: `greatest(ADDDATE, EDITDATE)` với kiểu toDateTime64(3)
- Nạp tăng trưởng (Incremental) dựa trên so sánh `last_modified_date`

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, storer_key, sku, lot)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.lotattribute | lot_attribute_id | VARCHAR(129) | ID định danh duy nhất của thuộc tính lô trong hệ thống nguồn |
| WHSEID | swm.lotattribute | whseid | VARCHAR(108) | Mã kho quản lý lô hàng (BKD1, BKD2, BKD3, NKD, VN821, VN831) |
| STORERKEY | swm.lotattribute | storer_key | VARCHAR(144) | Mã chủ hàng (MDLZ) - Luôn lọc theo giá trị này |
| SKU | swm.lotattribute | sku | VARCHAR(180) | Mã sản phẩm |
| LOT | swm.lotattribute | lot | VARCHAR(180) | Số lô quản lý nội bộ trong hệ thống kho |
| EXTERNALLOT | swm.lotattribute | external_lot | VARCHAR(180) | Số lô từ nhà cung cấp hoặc hệ thống ngoài |
| EXTERNRECEIPTKEY_LOT | swm.lotattribute | extern_receipt_key_lot | VARCHAR(180) | Mã chứng từ nhập kho liên kết với lô |
| LOTTABLE01 | swm.lotattribute | lottable01 | VARCHAR(180) | Thuộc tính lô tùy chỉnh 01 |
| LOTTABLE02 | swm.lotattribute | lottable02 | VARCHAR(180) | Thuộc tính lô tùy chỉnh 02 |
| LOTTABLE03 | swm.lotattribute | lottable03 | VARCHAR(180) | Thuộc tính lô tùy chỉnh 03 |
| LOTTABLE04 | swm.lotattribute | lottable04 | TIMESTAMP | Ngày sản xuất (NSX) - Ngày sản xuất hàng |
| LOTTABLE05 | swm.lotattribute | lottable05 | TIMESTAMP | Ngày hết hạn (HSD) - Hạn sử dụng sản phẩm |
| LOTTABLE06 | swm.lotattribute | lottable06 | VARCHAR(180) | Thuộc tính lô tùy chỉnh 06 |
| LOTTABLE07 | swm.lotattribute | lottable07 | VARCHAR(180) | Thuộc tính lô tùy chỉnh 07 |
| LOTTABLE08 | swm.lotattribute | lottable08 | VARCHAR(180) | Thuộc tính lô tùy chỉnh 08 |
| LOTTABLE09 | swm.lotattribute | lottable09 | VARCHAR(180) | Thuộc tính lô tùy chỉnh 09 |
| LOTTABLE10 | swm.lotattribute | lottable10 | VARCHAR(180) | Thuộc tính lô tùy chỉnh 10 |
| LOTTABLE11 | swm.lotattribute | lottable11 | TIMESTAMP | Thuộc tính lô tùy chỉnh 11 (kiểu timestamp) |
| LOTTABLE12 | swm.lotattribute | lottable12 | TIMESTAMP | Thuộc tính lô tùy chỉnh 12 (kiểu timestamp) |
| ADDDATE | swm.lotattribute | created_date | TIMESTAMP | Ngày giờ tạo thuộc tính lô |
| EDITDATE | swm.lotattribute | updated_date | TIMESTAMP | Ngày giờ cập nhật lần cuối |
| MAX(ADDDATE, EDITDATE) | swm.lotattribute | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Dùng để tracking delta incremental |
| -/- | -/- | sku_sk | VARCHAR(32) | Khóa ngoài liên kết đến dim_sku |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế (Surrogate Key) - Hash từ lot, sku, whseid, storer_key |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái: false (hoạt động), true (đã bị xóa) |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm được load vào DW (batch timestamp) |

---

### 1.12. Bảng dim_lotxlocxid (Tồn kho - Lot x Vị trí x ID)

**Mô tả:** Tồn kho chi tiết theo từng lô (lot) hàng hóa, tại từng vị trí (location) và kiện (LPNID), bao gồm các số lượng có sẵn, đã chỉ định (allocated), đã lấy (picked).

**Nguồn dữ liệu:** `swm.lotxlocxid` (bảng tồn kho chi tiết)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, storer_key, lpnid, lot, loc, sku, unitid, cartonid, palletid, status)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.lotxlocxid | lotxlocxid_id | VARCHAR(129) | ID gốc từ hệ thống |
| WHSEID | swm.lotxlocxid | whseid | VARCHAR(108) | Mã kho |
| STORERKEY | swm.lotxlocxid | storer_key | VARCHAR(144) | Mã chủ hàng (MDLZ) |
| LPNID | swm.lotxlocxid | lpnid | VARCHAR(180) | Mã kiện hàng (LPN) |
| LOT | swm.lotxlocxid | lot | VARCHAR(180) | Số lô hàng hóa |
| LOC | swm.lotxlocxid | loc | VARCHAR(180) | Vị trí bin lưu trữ |
| SKU | swm.lotxlocxid | sku | VARCHAR(180) | Mã sản phẩm |
| UNITID | swm.lotxlocxid | unitid | VARCHAR(180) | ID unit |
| CARTONID | swm.lotxlocxid | cartonid | VARCHAR(180) | ID carton |
| PALLETID | swm.lotxlocxid | palletid | VARCHAR(180) | Mã Pallet |
| STATUS | swm.lotxlocxid | status | VARCHAR(180) | Tình trạng sản phẩm lưu kho (Available, Locked,...) |
| QTY | swm.lotxlocxid | qty | DECIMAL(18,4) | Tổng số lượng hàng trong kho |
| QTYALLOCATED | swm.lotxlocxid | qty_allocated | DECIMAL(18,4) | Số lượng hàng đã chỉ định (allocated) |
| QTYPICKED | swm.lotxlocxid | qty_picked | DECIMAL(18,4) | Số lượng hàng đã picked (lấy hàng) |
| CALCULATION | swm.lotxlocxid | qty_available | DECIMAL(18,4) | Số lượng còn lại: qty - qty_allocated - qty_picked |
| ADDDATE | swm.lotxlocxid | created_date | TIMESTAMP | Ngày tạo bản ghi |
| EDITDATE | swm.lotxlocxid | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.lotxlocxid | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế - Hash từ tất cả các khóa định danh |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

---

### 1.13. Bảng dim_codelkup (Danh sách Mã Hệ thống)

**Mô tả:** Danh sách mã tham chiếu và giá trị cho các cài đặt hệ thống (ví dụ: trạng thái đơn hàng, phân loại SKU, tình trạng bin, v.v.).

**Nguồn dữ liệu:** `swm.codelkup` (bảng code lookup)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, code, list_name)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.codelkup | codelkup_id | VARCHAR(129) | ID gốc từ hệ thống |
| CODE | swm.codelkup | code | VARCHAR(144) | Mã thiết lập |
| WHSEID | swm.codelkup | whseid | VARCHAR(108) | Mã kho |
| LIST_NAME | swm.codelkup | list_name | VARCHAR(144) | Mã các thiết lập hệ thống (VD: ORDERSTATUS, SKU_CATEGORY, BIN_STATUS) |
| DESCRIPTION | swm.codelkup | description | VARCHAR(900) | Tên mô tả đầy đủ |
| SHORT_DESC | swm.codelkup | short_desc | VARCHAR(180) | Tên ngắn |
| LONG_VALUE | swm.codelkup | long_value | VARCHAR(900) | Tên dài/Giá trị mở rộng |
| SUSR1 | swm.codelkup | susr1 | VARCHAR(180) | Trường khách input 1 |
| SUSR2 | swm.codelkup | susr2 | VARCHAR(180) | Trường khách input 2 |
| SUSR3 | swm.codelkup | susr3 | VARCHAR(180) | Trường khách input 3 |
| SUSR4 | swm.codelkup | susr4 | VARCHAR(180) | Trường khách input 4 |
| SUSR5 | swm.codelkup | susr5 | VARCHAR(180) | Trường khách input 5 |
| ADDDATE | swm.codelkup | created_date | TIMESTAMP | Ngày tạo bản ghi |
| EDITDATE | swm.codelkup | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.codelkup | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế - Hash từ code, whseid, list_name |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

---

## 2. NHÓM BẢNG DANH MỤC PHỤ (SUBDIMENSION TABLES)

### 2.1. Bảng subdim_storer (Danh mục Khách hàng/Storer)

**Mô tả:** Danh mục khách hàng (Storer), bao gồm thông tin công ty, địa chỉ, và các property mở rộng. Liên kết với đơn hàng qua consignee_key.

**Nguồn dữ liệu:** `swm.storer` (bảng khách hàng)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, storer_key, type)
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.storer | storer_id | VARCHAR(129) | ID gốc từ hệ thống |
| STORERKEY | swm.storer | storer_key | VARCHAR(144) | Mã khách hàng |
| WHSEID | swm.storer | whseid | VARCHAR(108) | Mã kho |
| TYPE | swm.storer | type | VARCHAR(144) | Đánh dấu khách hàng (2 = soldto, 5 = shipto) |
| COMPANY | swm.storer | company | VARCHAR(900) | Tên khách hàng |
| ADDRESS1 | swm.storer | address | VARCHAR(900) | Địa chỉ khách hàng |
| SUSR1 | swm.storer | province | VARCHAR(180) | Tỉnh thành |
| SUSR2 | swm.storer | susr2 | VARCHAR(180) | Trường khách input 2 |
| SUSR3 | swm.storer | zip_code | VARCHAR(180) | Zip Code |
| SUSR4 | swm.storer | country | VARCHAR(180) | Quốc gia |
| SUSR5 | swm.storer | susr5 | VARCHAR(180) | Trường khách input 5 |
| SUSR6 | swm.storer | susr6 | VARCHAR(180) | Trường khách input 6 |
| SUSR7 | swm.storer | susr7 | VARCHAR(180) | Trường khách input 7 |
| SUSR8 | swm.storer | susr8 | VARCHAR(180) | Trường khách input 8 |
| SUSR9 | swm.storer | susr9 | VARCHAR(180) | Trường khách input 9 |
| SUSR10 | swm.storer | susr10 | VARCHAR(180) | Trường khách input 10 |
| ADDDATE | swm.storer | created_date | TIMESTAMP | Ngày tạo bản ghi |
| EDITDATE | swm.storer | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.storer | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế - Hash từ type, whseid, storer_key |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

---

### 2.2. Bảng subdim_customergroup (Nhóm Khách hàng)

**Mô tả:** Danh mục nhóm khách hàng, phân loại khách hàng theo nhóm và các thông tin liên lạc.

**Nguồn dữ liệu:** `swm.customergroup` (bảng nhóm khách hàng)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, group_code)
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.customergroup | customer_group_id | VARCHAR(129) | ID gốc từ hệ thống |
| WHSEID | swm.customergroup | whseid | VARCHAR(108) | Mã kho |
| GROUPCODE | swm.customergroup | group_code | VARCHAR(144) | Mã nhóm khách hàng |
| GROUPNAME | swm.customergroup | group_name | VARCHAR(900) | Tên nhóm khách hàng |
| PHONENUMBER | swm.customergroup | phonenumber | VARCHAR(180) | Số điện thoại nhóm |
| ADDRESS | swm.customergroup | address | VARCHAR(900) | Địa chỉ nhóm khách hàng |
| SHEFTLIFE | swm.customergroup | shelf_life | VARCHAR(180) | Thông tin shelf life |
| ADDDATE | swm.customergroup | created_date | TIMESTAMP | Ngày tạo bản ghi |
| EDITDATE | swm.customergroup | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.customergroup | last_modified_date | TIMESTAMP | MAX(created_date, updated_date) - Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thay thế - Hash từ whseid, group_code |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

---

## 3. NHÓM BẢNG GIAO DỊCH (FACT TABLES)

### 3.1. Bảng fact_inbound (Sự kiện Nhập kho)

**Mô tả:** Bảng sự kiện nhập kho, tổng hợp từ dim_receiptdetail với các khoá ngoại liên kết đến các bảng danh mục.

**Nguồn dữ liệu:** `dim_receiptdetail` + `dim_receipt` + `dim_codelkup`

**Engine:** ReplacingMergeTree(composite_last_modified_date)
**Order By:** (whseid, receipt_key, receipt_line_number)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| receiptdetail_sk | dim_receiptdetail | receiptdetail_sk | VARCHAR(32) | Khoá ngoại -> dim_receiptdetail |
| whseid | dim_receiptdetail | whseid | VARCHAR(108) | Mã kho |
| receipt_key | dim_receiptdetail | receipt_key | VARCHAR(180) | Mã đơn nhập (ASN) |
| receipt_line_number | dim_receiptdetail | receipt_line_number | VARCHAR(180) | Mã dòng trong chứng từ nhập |
| storer_key | dim_receiptdetail | storer_key | VARCHAR(144) | Mã chủ hàng |
| sku | dim_receiptdetail | sku | VARCHAR(180) | Mã sản phẩm |
| pack_key | dim_receiptdetail | pack_key | VARCHAR(180) | Mã quy cách đóng gói |
| po_key | dim_receiptdetail | po_key | VARCHAR(180) | Mã đơn PO liên kết |
| po_line_number | dim_receiptdetail | po_line_number | VARCHAR(180) | Mã dòng PO |
| qty_received | dim_receiptdetail | qty_received | DECIMAL(18,4) | Số lượng hàng thực nhập |
| palletid | dim_receiptdetail | palletid | VARCHAR(180) | Mã Pallet |
| receipt_sk | dim_receipt | receipt_sk | VARCHAR(32) | Khoá ngoại -> dim_receipt |
| type | dim_receipt | receipt_type | VARCHAR(180) | Loại đơn nhập |
| status_code | dim_codelkup | codelkup_sk | VARCHAR(32) | Khoá ngoại -> dim_codelkup (trạng thái) |
| created_date | dim_receiptdetail | created_date | TIMESTAMP | Ngày tạo bản ghi |
| updated_date | dim_receiptdetail | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| last_modified_date | dim_receiptdetail | last_modified_date | TIMESTAMP | Tracking delta |
| MAX(receiptdetail, receipt, codelkup last_modified_date) | -/- | composite_last_modified_date | TIMESTAMP | MAX(receiptdetail, receipt, codelkup last_modified_date) |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thông tin = receiptdetail_sk |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

**Ghí chú:** Bảng fact này được thiết kế để tối ưu hoá phân tích hiệu suất nhập kho, theo dõi độ trễ giao hàng, chất lượng nhập.

---

### 3.2. Bảng fact_inventory (Tồn kho - Snapshot)

**Mô tả:** Bảng tồn kho chi tiết, dựa trên dim_lotxlocxid với các khoá ngoại đến các bảng danh mục như SKU, Location, Pack, Receipt.

**Nguồn dữ liệu:** `dim_lotxlocxid` + `dim_sku` + `dim_receiptdetail`

**Engine:** ReplacingMergeTree(composite_last_modified_date)
**Order By:** (whseid, storer_key, lpnid, lot, loc, sku, unitid, cartonid, palletid, status)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| lotxlocxid_sk | dim_lotxlocxid | lotxlocxid_sk | VARCHAR(32) | Khoá ngoại -> dim_lotxlocxid |
| whseid | dim_lotxlocxid | whseid | VARCHAR(108) | Mã kho |
| storer_key | dim_lotxlocxid | storer_key | VARCHAR(144) | Mã chủ hàng |
| lpnid | dim_lotxlocxid | lpnid | VARCHAR(180) | Mã kiện hàng (LPN) |
| lot | dim_lotxlocxid | lot | VARCHAR(180) | Số lot hàng hóa |
| loc | dim_lotxlocxid | loc | VARCHAR(180) | Vị trí bin lưu trữ |
| sku | dim_lotxlocxid | sku | VARCHAR(180) | Mã sản phẩm |
| unitid | dim_lotxlocxid | unitid | VARCHAR(180) | ID unit |
| cartonid | dim_lotxlocxid | cartonid | VARCHAR(180) | ID carton |
| palletid | dim_lotxlocxid | palletid | VARCHAR(180) | Mã Pallet |
| status | dim_lotxlocxid | status | VARCHAR(180) | Tình trạng sản phẩm (Available, Locked,...) |
| qty | dim_lotxlocxid | qty | DECIMAL(18,4) | Tổng số lượng hàng trong kho |
| qty_picked | dim_lotxlocxid | qty_picked | DECIMAL(18,4) | Số lượng hàng đã picked |
| qty_allocated | dim_lotxlocxid | qty_allocated | DECIMAL(18,4) | Số lượng hàng đã allocated |
| CALCULATION | dim_lotxlocxid | qty_available | DECIMAL(18,4) | Số lượng còn lại: qty - qty_allocated - qty_picked |
| receiptdetail_sk | dim_receiptdetail | receiptdetail_sk | VARCHAR(32) | Khoá ngoại -> dim_receiptdetail (liên kết qua lpnid) |
| sku_sk | dim_sku | sku_sk | VARCHAR(32) | Khoá ngoại -> dim_sku |
| pack_sk | dim_pack | pack_sk | VARCHAR(32) | Khoá ngoại -> dim_pack |
| loc_sk | dim_loc | loc_sk | VARCHAR(32) | Khoá ngoại -> dim_loc |
| lotattribute_sk | dim_lotattribute | lotattribute | VARCHAR(32) | Khoá ngoại -> dim_lotattribute |
| created_date | dim_lotxlocxid | created_date | TIMESTAMP | Ngày tạo bản ghi |
| updated_date | dim_lotxlocxid | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| last_modified_date | dim_lotxlocxid | last_modified_date | TIMESTAMP | Tracking delta |
| MAX(lotxlocxid, receiptdetail, sku last_modified_date) | -/- | composite_last_modified_date | TIMESTAMP | MAX(lotxlocxid, receiptdetail, sku last_modified_date) |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thông tin = lotxlocxid_sk |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

**Ghí chú:** Bảng fact này dùng cho phân tích tồn kho hiện tại, tìm kiếm hàng, báo cáo khả năng cung cấp.

---

### 3.3. Bảng fact_outbound (Sự kiện Xuất kho)

**Mô tả:** Bảng sự kiện xuất kho, dựa trên dim_pickdetail với các khoá ngoại liên kết đến các bảng orderdetail, orders, SKU, location, pack.

**Nguồn dữ liệu:** `dim_pickdetail`

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, pick_detail_key)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.pickdetail | pickdetail_sk | VARCHAR(32) | Khoá ngoại -> dim_pickdetail |
| ORDERKEY | swm.pickdetail | orderdetail_sk | VARCHAR(32) | Khoá ngoại -> dim_orderdetail |
| ORDERKEY | swm.orders | orders_sk | VARCHAR(32) | Khoá ngoại -> dim_orders |
| SKU | swm.pickdetail | sku_sk | VARCHAR(32) | Khoá ngoại -> dim_sku |
| PACKKEY | swm.pickdetail | pack_sk | VARCHAR(32) | Khoá ngoại -> dim_pack |
| LOC | swm.pickdetail | loc_sk | VARCHAR(32) | Khoá ngoại -> dim_loc |
| LOC | swm.pickdetail | loc | VARCHAR(180) | Vị trí bin lấy hàng |
| WHSEID | swm.pickdetail | whseid | VARCHAR(108) | Mã kho |
| STORERKEY | swm.pickdetail | storer_key | VARCHAR(144) | Mã chủ hàng |
| PICKDETAILKEY | swm.pickdetail | pick_detail_key | VARCHAR(180) | Mã chi tiết pick hàng |
| PACKKEY | swm.pickdetail | pack_key | VARCHAR(180) | Mã quy cách sản phẩm |
| SKU | swm.pickdetail | sku | VARCHAR(180) | Mã sản phẩm |
| ORDERKEY | swm.pickdetail | order_key | VARCHAR(180) | Mã đơn xuất |
| ORDERLINENUMBER | swm.pickdetail | order_line_number | VARCHAR(180) | Mã dòng hàng hóa |
| QTY | swm.pickdetail | qty | DECIMAL(18,4) | Số lượng thực xuất (Master Unit) |
| UOMQTY | swm.pickdetail | uom_qty | DECIMAL(18,4) | Số lượng theo đơn vị lẻ |
| UOM | swm.pickdetail | uom | VARCHAR(108) | Đơn vị tính |
| ADDDATE | swm.pickdetail | created_date | TIMESTAMP | Ngày tạo bản ghi |
| EDITDATE | swm.pickdetail | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.pickdetail | last_modified_date | TIMESTAMP | Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thông tin = pickdetail_sk |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

**Ghí chú:** Bảng fact này dùng để phân tích hiệu suất picking, theo dõi thời gian xuất kho, tìm kiếm chi tiết picking.

---

### 3.4. Bảng fact_order_fulfillment (Phân tích Hoàn thành Đơn hàng)

**Mô tả:** Bảng phân tích mức độ hoàn thành đơn hàng, bao gồm các metric về số lượng kế hoạch, picked, shipped, và tỷ lệ fill rate.

**Nguồn dữ liệu:** `dim_orderdetail` + (sử dụng để tính toán thêm các metric)

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, order_key, order_line_number)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.orderdetail | orderdetail_sk | VARCHAR(32) | Khoá ngoại -> dim_orderdetail |
| ORDERKEY | swm.orders | orders_sk | VARCHAR(32) | Khoá ngoại -> dim_orders |
| SKU | swm.orderdetail | sku_sk | VARCHAR(32) | Khoá ngoại -> dim_sku |
| PACKKEY | swm.orderdetail | pack_sk | VARCHAR(32) | Khoá ngoại -> dim_pack |
| WHSEID | swm.orderdetail | whseid | VARCHAR(108) | Mã kho |
| ORDERKEY | swm.orderdetail | order_key | VARCHAR(180) | Mã đơn xuất |
| ORDERLINENUMBER | swm.orderdetail | order_line_number | VARCHAR(180) | Mã dòng hàng hóa |
| STORERKEY | swm.orderdetail | storer_key | VARCHAR(144) | Mã chủ hàng |
| PACKKEY | swm.orderdetail | pack_key | VARCHAR(180) | Mã quy cách sản phẩm |
| SKU | swm.orderdetail | sku | VARCHAR(180) | Mã sản phẩm |
| EXTERNORDERKEY | swm.orderdetail | extern_order_key | VARCHAR(180) | Mã đơn DO |
| ORIGINALQTY | swm.orderdetail | original_qty | DECIMAL(18,4) | Số lượng kế hoạch (Header) |
| SHIPPEDQTY | swm.orderdetail | shipped_qty | DECIMAL(18,4) | Số lượng thực xuất (Header) |
| QTYPICKED | swm.orderdetail | qty_picked | DECIMAL(18,4) | Số lượng đã pick hàng |
| CALCULATION | swm.orderdetail | qty_diff | DECIMAL(18,4) | Chênh lệch: original_qty - shipped_qty |
| CALCULATION | swm.orderdetail | qty_pending | DECIMAL(18,4) | Chờ xuất: qty_picked - shipped_qty |
| CALCULATION | swm.orderdetail | fill_rate_pct | DECIMAL(18,2) | Tỷ lệ hoàn thành (%): (shipped_qty / original_qty * 100) |
| ADDDATE | swm.orderdetail | created_date | TIMESTAMP | Ngày tạo bản ghi |
| EDITDATE | swm.orderdetail | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.orderdetail | last_modified_date | TIMESTAMP | Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thông tin = orderdetail_sk |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

**Ghí chú:** Bảng fact này dùng để:
- Kiểm tra mức độ hoàn thành đơn hàng của các khách hàng
- Xác định hàng còn thiếu (qty_diff > 0)
- Theo dõi hàng đã pick nhưng chưa xuất (qty_pending > 0)
- Tính toán KPI fill_rate để đánh giá hiệu suất kho

---

### 3.5. Bảng fact_purchase_fulfillment (Phân tích Hoàn thành Đơn mua)

**Mô tả:** Bảng phân tích mức độ hoàn thành đơn mua từ nhà cung cấp, bao gồm các metric về số lượng dự kiến, chốt, thực nhập, và tỷ lệ PO fill rate.

**Nguồn dữ liệu:** `dim_podetail`

**Engine:** ReplacingMergeTree(last_modified_date)
**Order By:** (whseid, po_key, po_line_number)
**Unique Key:** key_sk
**Tần suất cập nhật:** Hàng ngày (Daily)

| Cột Nguồn | Bảng Nguồn | Cột Đích | Kiểu DL | Ý nghĩa |
|:----|:----|:----|:----|:----|
| ID | swm.podetail | podetail_sk | VARCHAR(32) | Khoá ngoại -> dim_podetail |
| POKEY | swm.po | po_sk | VARCHAR(32) | Khoá ngoại -> dim_po |
| SKU | swm.podetail | sku_sk | VARCHAR(32) | Khoá ngoại -> dim_sku |
| WHSEID | swm.podetail | whseid | VARCHAR(108) | Mã kho |
| STORERKEY | swm.podetail | storer_key | VARCHAR(144) | Mã chủ hàng |
| POKEY | swm.podetail | po_key | VARCHAR(180) | Mã đơn mua |
| POLINENUMBER | swm.podetail | po_line_number | VARCHAR(180) | Mã dòng PO |
| SKU | swm.podetail | sku | VARCHAR(180) | Mã sản phẩm |
| QTYORIGINAL | swm.podetail | qty_original | DECIMAL(18,4) | Số lượng dự kiến ban đầu |
| QTYORDERED | swm.podetail | qty_ordered | DECIMAL(18,4) | Số lượng đã chốt đặt hàng |
| QTYRECEIVED | swm.podetail | qty_received | DECIMAL(18,4) | Số lượng thực tế đã nhập kho |
| CALCULATION | swm.podetail | qty_planning_gap | DECIMAL(18,4) | Chênh lệch dự kiến: qty_original - qty_ordered |
| CALCULATION | swm.podetail | qty_fulfillment_gap | DECIMAL(18,4) | Chênh lệch hoàn thành: qty_ordered - qty_received |
| UNITCOST | swm.podetail | unit_cost | DECIMAL(18,4) | Đơn giá mua |
| CALCULATION | swm.podetail | planned_amount | DECIMAL(18,4) | Giá trị dự kiến: qty_ordered * unit_cost |
| CALCULATION | swm.podetail | actual_received_amount | DECIMAL(18,4) | Giá trị thực nhập: qty_received * unit_cost |
| CALCULATION | swm.podetail | po_fill_rate_pct | DECIMAL(18,2) | Tỷ lệ nhà cung cấp giao hàng (%): (qty_received / qty_ordered * 100) |
| CALCULATION | swm.podetail | plan_accuracy_pct | DECIMAL(18,2) | Tỷ lệ chốt đơn so với dự kiến (%): (qty_ordered / qty_original * 100) |
| ADDDATE | swm.podetail | created_date | TIMESTAMP | Ngày tạo bản ghi |
| EDITDATE | swm.podetail | updated_date | TIMESTAMP | Ngày cập nhật gần nhất |
| MAX(ADDDATE, EDITDATE) | swm.podetail | last_modified_date | TIMESTAMP | Tracking delta |
| -/- | -/- | key_sk | VARCHAR(32) | Khóa thông tin = podetail_sk |
| -/- | -/- | is_deleted | BOOLEAN | Trạng thái xóa mềm |
| -/- | -/- | dbt_updated_at | TIMESTAMP | Thời điểm load vào DW |

**Ghí chú:** Bảng fact này dùng để:
- Đánh giá hiệu suất nhà cung cấp (po_fill_rate_pct)
- Phân tích độ chính xác kế hoạch mua (plan_accuracy_pct)
- Xác định hàng encore/thiếu (qty_fulfillment_gap)
- Tính giá trị mua thực tế so với dự kiến
- Từ đó điều chỉnh kế hoạch mua hàng, lựa chọn nhà cung cấp

---

## 4. CẢU TRÚC TỪ KHÓA (KEY RELATIONSHIPS)

### Relationship Diagram

```
dim_sku ← fact_inventory, fact_outbound, fact_order_fulfillment, fact_purchase_fulfillment
dim_loc ← fact_inventory, fact_outbound
dim_pack ← fact_inventory, fact_outbound, fact_order_fulfillment, fact_purchase_fulfillment
dim_po ← fact_purchase_fulfillment
dim_podetail ← fact_purchase_fulfillment
dim_receipt ← fact_inbound
dim_receiptdetail ← fact_inbound, fact_inventory
dim_orders ← fact_outbound, fact_order_fulfillment
dim_orderdetail ← fact_outbound, fact_order_fulfillment
dim_pickdetail ← fact_outbound
dim_lotxlocxid ← fact_inventory
dim_codelkup ← fact_inbound (status lookup)
subdim_storer ← dim_orders
subdim_customergroup ← (reference)
```

---

## 5. CHIẾN LƯỢC NẠPS DỮ LIỆU (INCREMENTAL LOADING STRATEGY)

**Engine:** ClickHouse ReplacingMergeTree
- Sử dụng `last_modified_date` để xác định bản ghi nào cần cập nhật
- Mỗi lần load, chỉ lấy dữ liệu có `last_modified_date >= max(last_modified_date)` trong bảng hiện tại
- ReplacingMergeTree tự động xử lý deduplication dựa trên `last_modified_date`
- Chạy `OPTIMIZE TABLE ... FINAL` sau mỗi load để merge và dọn dẹp

**Tần suất nạp:** Hàng ngày (Daily) - thường chạy vào buổi sáng sau 00:00 CST

**Vòng quay dữ liệu:**
- T+1: Dữ liệu hôm qua được load vào DW
- Có thể phân tích ngày hôm trước từ buổi sáng
- Dữ liệu hôm nay từ 00:00 CST có sẵn từ buổi sáng

---

## 6. METADATA VÀ GOVERNANCE

**Cột Metadata (tất cả bảng):**
- `created_date`: Khi bản ghi được tạo trong hệ thống nguồn
- `updated_date`: Khi bản ghi được cập nhật lần cuối trong hệ thống nguồn
- `last_modified_date`: toDateTime64(greatest(created_date, updated_date), 3) - KHÔNG NULL, dùng cho ReplacingMergeTree
- `is_deleted`: BOOLEAN - đánh dấu xóa mềm (soft delete) từ nguồn - luôn mặc định false khi insert mới
- `dbt_updated_at`: toDateTime64(now64(3)) - khi dbt load vào DW

**Giá trị mặc định:**
- `is_deleted = false` (không xóa mềm)
- Tất cả các cột khóa đều bắt buộc (NOT NULL)
- Các cột định lượng mặc định là số 0 nếu NULL
- Các cột mô tả mặc định là chuỗi rỗng nếu NULL

---

## PHỤ LỤC: DANH SÁCH BẢNG VÀ MỤC ĐÍCH

| Bảng | Loại | Mục đích chính |
|:----|:----|:----|
| dim_sku | Dimension | Danh mục sản phẩm, thông số vật lý, chiến lược WMS |
| dim_loc | Dimension | Danh mục vị trí bin, trạng thái kho |
| dim_pack | Dimension | Danh mục quy cách đóng gói |
| dim_po | Dimension | Đơn mua hàng header |
| dim_podetail | Dimension | Chi tiết dòng đơn mua |
| dim_receipt | Dimension | Chứng từ nhập kho header |
| dim_receiptdetail | Dimension | Chi tiết dòng nhập kho, lot, HSD |
| dim_orders | Dimension | Đơn hàng khách header |
| dim_orderdetail | Dimension | Chi tiết dòng đơn hàng khách |
| dim_pickdetail | Dimension | Chi tiết picking/lấy hàng |
| dim_lotxlocxid | Dimension | Tồn kho chi tiết theo lot, vị trí |
| dim_codelkup | Dimension | Danh sách mã hệ thống, trạng thái |
| subdim_storer | Subdimension | Danh mục khách hàng |
| subdim_customergroup | Subdimension | Nhóm khách hàng |
| fact_inbound | Fact | Sự kiện nhập kho, phân tích inbound |
| fact_inventory | Fact | Tồn kho hiện tại, khả năng cung cấp |
| fact_outbound | Fact | Sự kiện xuất kho, picking |
| fact_order_fulfillment | Fact | Phân tích hoàn thành đơn hàng khách |
| fact_purchase_fulfillment | Fact | Phân tích hoàn thành đơn mua từ supplier |

---

**Tài liệu cập nhật lần cuối:** 30/03/2026
**Phiên bản:** 2.0 (ClickHouse)
**Trạng thái:** Hoàn chỉnh với tất cả 19 bảng, đủ cột, comment chi tiết
