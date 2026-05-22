# HƯỚNG DẪN QUERY - CHỈ DÙNG FACT + DIMENSION TABLES

## 🎯 NGUYÊN TẮC CHÍNH

**Tất cả queries phải tuân theo nguyên tắc: CHỈ DÙNG FACT + DIMENSION TABLES**

| ✅ CÓ THỂ LÀM | ❌ KHÔNG LÀM |
|:---|:---|
| Query **FACT TABLE** trực tiếp | Query subdimension tables |
| LEFT JOIN 1-2 **DIMENSION TABLES** | JOIN bảng trung gian/staging |
| Sử dụng calculated metrics | JOIN 5+ tables |
| Filter theo business keys | Normalize lại DW data |

---

## 1. CHIẾN LƯỢC DENORMALIZATION CHO OLAP/DW (OLAP CONSUMPTION STRATEGY)

  ### Nguyên Tắc Cơ Bản: OLAP ≠ OLTP
  
  **SWM Data Warehouse được thiết kế theo OLAP principles, KHÔNG OLTP:**

  | Aspect | OLTP (Transactional) | OLAP (Analytical - DW) |
  | :--- | :--- | :--- |
  | **Chuẩn hóa (Normalization)** | ✓ Cao (3NF+) - Tối ưu ghi | ✗ Thấp - Cho phép redundancy |
  | **Fact Table Structure** | Mỏng (IDs + values) | **DÀY (Denormalized + attributes)** |
  | **Query Pattern** | Nhiều joins nhỏ | Ít joins, query fact trực tiếp |
  | **Update Logic** | Row-by-row | Batch insert/append |

  ### Thiết Kế Denormalization

  **Không làm:** (❌ OLTP Pattern)
  ```sql
  -- SLOW cho analytics: Nhiều joins trên TeraByte data
  SELECT o.extern_order_key, od.original_qty, ds.descr, dp.qty
  FROM orders o
  JOIN orderdetail od ON o.order_key = od.order_key
  JOIN sku ds ON od.sku = ds.sku AND od.whseid = ds.whseid
  JOIN pack dp ON od.pack_key = dp.pack_key AND od.whseid = dp.whseid
  WHERE o.order_date >= '2026-03-20'
  ```

  **Làm như vậy:** (✅ OLAP Pattern - FACT + DIM ONLY)
  ```sql
  -- FAST: Query trực tiếp từ fact table (data đã denormalized)
  -- NGUYÊN TẮC: Chỉ dùng FACT + DIM, không dùng bảng trung gian
  SELECT 
      fof.order_key, fof.extern_order_key, fof.original_qty, fof.shipped_qty,
      fof.sku, fof.pack_key,
      fof.fill_rate_pct,          -- ← Calculated metric sẵn có
      fof.created_date
  FROM fact_order_fulfillment fof
  WHERE fof.whseid = 'BKD1'
    AND fof.created_date >= '2026-03-20'
    AND fof.is_deleted = false
  ```

  ### Denormalization Pattern - Cấu Trúc Dữ Liệu

  **NGUYÊN TẮC: Chỉ sử dụng FACT + DIM TABLES**

  **Dimensions (Master Data - 12 bảng):**
  ```
  ┌─ dim_sku:          sku | descr | category | weight | cube...
  ├─ dim_loc:          loc | line | bin | status | stack_limit...
  ├─ dim_pack:         pack_key | qty | pallet | inner_pack...
  ├─ dim_po:           po_key | seller_name | buyer_city | po_date...
  ├─ dim_podetail:     po_key | sku | qty_original | qty_ordered | qty_received...
  ├─ dim_receipt:      receipt_key | supplier_code | receipt_date...
  ├─ dim_receiptdetail: receipt_key | sku | lottable01 [lot] | lottable05 [expiry]...
  ├─ dim_orders:       order_key | consignee_key | status | order_date...
  ├─ dim_orderdetail:  order_key | sku | original_qty | shipped_qty...
  ├─ dim_pickdetail:   pick_detail_key | order_key | sku | qty...
  ├─ dim_lotxlocxid:   lpnid | lot | loc | sku | qty | qty_available...
  └─ dim_codelkup:     code | list_name | description...
  ```

  **Facts (Denormalized - Ready for Analysis - 5 bảng):**
  ```
  ┌─ fact_order_fulfillment (Xuất hàng - Order fulfillment):
  │   Business Keys:  order_key | order_line_number | whseid | storer_key
  │   Dimensions:     sku | pack_key | uom | original_qty | shipped_qty
  │   Metrics:        qty_diff | qty_pending | fill_rate_pct (tính sẵn)
  │   Metadata:       created_date | last_modified_date | is_deleted
  │
  ├─ fact_purchase_fulfillment (Mua hàng - PO fulfillment):
  │   Business Keys:  po_key | po_line_number | whseid | storer_key
  │   Dimensions:     sku | qty_original | qty_ordered | qty_received
  │   Metrics:        qty_planning_gap | qty_fulfillment_gap | po_fill_rate_pct | plan_accuracy_pct (tính sẵn)
  │
  ├─ fact_inventory (Tồn kho - Inventory snapshot):
  │   Business Keys:  lpnid | lot | loc | whseid | storer_key
  │   Dimensions:     sku | qty | qty_allocated | qty_picked | qty_available
  │   Metadata:       last_modified_date | is_deleted
  │
  ├─ fact_inbound (Nhập hàng - Inbound receipt):
  │   Business Keys:  receipt_key | receipt_line_number | whseid | storer_key
  │   Dimensions:     sku | qty_received | po_key | palletid
  │   Metadata:       created_date | last_modified_date | is_deleted
  │
  └─ fact_outbound (Picking - Outbound picking):
      Business Keys:  pick_detail_key | whseid | storer_key
      Dimensions:     sku | qty | uom_qty | uom | order_key | order_line_number
      Metadata:       created_date | last_modified_date | is_deleted
  ```

  ### Khi Nào Cần JOINs? (FACT + DIM ONLY)

  | Tình Huống | Giải Pháp | Ví Dụ |
  | :--- | :--- | :--- |
  | Query dữ liệu phân tích | Query FACT trực tiếp (data đã denormalized) | ✅ Tốc độ cao, không cần JOIN |
  | Cần thêm thông tin từ DIM | LEFT JOIN DIM (tối đa 1-2 bảng) | Hiếm khi cần, vì fact đã có data cần |
  | Theo dõi chi tiết DIM | Query DIM trực tiếp (không dùng subdim) | VD: SELECT * FROM dim_sku |
  | Kiểm tra Data Quality | Dùng DBT tests không phải user query | DBT tự động validate |
  | **KHÔNG LÀM**: Query từ ~~subdim~~, ~~bảng trung gian~~ | **Chỉ dùng FACT + DIM** | ❌ Anti-pattern |

  ### Best Practices (FACT + DIM ONLY PRINCIPLE)

  ✅ **DO:**
  - Query **FACT tables trực tiếp** (data đã denormalized, không cần JOIN)
  - Nếu cần dimension attributes: **LEFT JOIN 1-2 DIM tables tối đa**
  - Sử dụng calculated metrics sẵn có trong fact (fill_rate_pct, po_fill_rate_pct, qty_available)
  - Filter theo business keys trong fact (order_key, po_key, lpnid, sku, ...)
  - Query DIM trực tiếp nếu chỉ cần master data reference

  ❌ **DON'T:**
  - **KHÔNG query subdim tables** (subdim_storer, subdim_customergroup) - dữ liệu đã nằm trong FACT
  - **KHÔNG JOIN 5+ tables** (anti-pattern trong DW)
  - **KHÔNG dùng bảng trung gian hay staging tables**
  - **KHÔNG normalize lại DW data** cho queries (denormalization là chuẩn OLAP)
  - **KHÔNG expect fact tables chỉ chứa keys** - facts đã rich denormalized data

  ---

  ### 6.1. Entity Relationship Diagram (ERD) - Visual Overview

  ```
  ┌──────────────────────────────────────────────────────────────────┐
  │                      MASTER DATA LAYER                           │
  │                     (Reference Tables)                           │
  └──────────────────────────────────────────────────────────────────┘
  
            ┌────────────────────┐        ┌────────────────────┐
            │     dim_codelkup   │        │   subdim_storer    │
            │   (系统码表)        │        │  (客户/供应商)      │
            ├────────────────────┤        ├────────────────────┤
            │ • code (PK)        │        │ • storer_key (PK)  │
            │ • list_name        │        │ • whseid (PK)      │
            │ • description      │        │ • type (FK)        │
            │ • short_desc       │        │ • company          │
            └────────────────────┘        │ • address          │
                    ↑                      │ • contact_info     │
                    │ FK:codelkup_sk       └────────────────────┘
                    │

  
  ┌──────────────────────────────────────────────────────────────────┐
  │               BASELINE DIMENSION LAYER                           │
  │        (Product, Location, Pack catalogs)                        │
  └──────────────────────────────────────────────────────────────────┘

        ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
        │   dim_sku    │       │   dim_loc    │       │   dim_pack   │
        │ (商品目录)    │       │ (位置目录)    │       │ (包装规格)    │
        ├──────────────┤       ├──────────────┤       ├──────────────┤
        │ • sku (PK)   │       │ • loc (PK)   │       │ • pack_key   │
        │ • whseid (PK)│       │ • whseid (PK)│       │ • whseid (PK)│
        │ • descr      │       │ • line       │       │ • qty        │
        │ • category   │       │ • bin        │       │ • pallet     │
        │ • weight     │       │ • status     │       │ • inner_pack │
        └──────────────┘       │ • zone       │       └──────────────┘
              ↑                 └──────────────┘              ↑
              │ Referenced by:           ↑                   │
              │ - dim_receiptdetail      │ Referenced:       │ Referenced by:
              │ - dim_orderdetail        │ - dim_lotxlocxid  │ - dim_receiptdetail
              │ - dim_lotxlocxid         │ - fact_inventory  │ - dim_orderdetail
              │ - fact_inbound           │ - fact_inventory  │ - dim_pickdetail
              │ - fact_outbound          │                   │ - fact_inventory
              │ - fact_inventory         │                   │ - fact_inbound
              │                          │                   │ - fact_outbound
              │                          │                   │


  ┌──────────────────────────────────────────────────────────────────┐
  │            INBOUND TRANSACTION LAYER (nhập hàng)                 │
  └──────────────────────────────────────────────────────────────────┘

           ┌──────────────────────┐
           │    dim_receipt       │  ← [PK: receipt_key, whseid]
           │  (phiếu nhập chung)  │     Thông tin header phiếu nhập
           ├──────────────────────┤
           │ • receipt_key (PK)   │
           │ • extern_receipt_key │    (PO/ASN from supplier)
           │ • po_key             │    ← Link để trace từ họp đồng
           │ • supplier_code      │
           │ • supplier_name      │
           │ • status             │
           │ • receipt_date       │
           │ • is_deleted         │
           └──────────────────────┘
                  │ 1:N
                  │ [receipt_key, whseid, storer_key]
                  ↓
           ┌──────────────────────────────┐
           │  dim_receiptdetail           │  ← [PK: receipt_key + 
           │   (chi tiết dòng nhập)       │       receipt_line_number]
           ├──────────────────────────────┤
           │ • receipt_key (PK)           │
           │ • receipt_line_number (PK)   │
           │ • sku (FK → dim_sku)         │  ← SAP lấy mô tả sản phẩm
           │ • pack_key (FK → dim_pack)   │  ← SAP lấy quy cách
           │ • lottable01 (Lot)           │  ← **Traceability Key**
           │ • lottable04 (MFG Date)      │  ← Ngày sản xuất
           │ • lottable05 (Expiry Date)   │  ← **CRITICAL: Shelf life**
           │ • qty_received               │  ← Số lượng thực nhập
           │ • condition_code (FK → code) │  ← Hàng tốt/lỗi
           │ • date_received              │
           │ • is_deleted                 │
           └──────────────────────────────┘
                  │
                  │ Referenced by fact_inbound
                  │ fk_receiptdetail_sk
                  ↓

           ┌──────────────────────────────┐
           │   fact_inbound               │  ← [PK: receipt_key + 
           │  (sự kiện nhập hàng)         │       receipt_line_number]
           ├──────────────────────────────┤
           │ FOREIGN KEYS:                │
           │ • receiptdetail_sk (FK)      │  ← dim_receiptdetail.key_sk
           │ • receipt_sk (FK)            │  ← dim_receipt.key_sk
           │ • sku_sk (FK)                │  ← dim_sku.key_sk
           │ • pack_sk (FK)               │  ← dim_pack.key_sk
           │ • codelkup_sk (FK, optional) │  ← dim_codelkup.key_sk
           │                              │     (for condition lookups)
           │ DIMENSIONS:                  │
           │ • whseid                     │      
           │ • storer_key                 │
           │ • qty_received               │  ← Measure: số lượng
           │ • created_date, updated_date │
           │ • is_deleted                 │
           │ • composite_last_modified    │  ← Timestamp theo dõi
           └──────────────────────────────┘


  ┌──────────────────────────────────────────────────────────────────┐
  │          INVENTORY TRANSACTION LAYER (tồn kho)                   │
  └──────────────────────────────────────────────────────────────────┘

           ┌──────────────────────────────────┐
           │   dim_lotxlocxid                 │  ← [PK: lpnid + lot + 
           │  (chi tiết tồn kho vật lý)       │       loc + sku...]
           ├──────────────────────────────────┤
           │ FOREIGN KEYS:                    │
           │ • sku (FK → dim_sku)             │  ← SAP lấy thông tin SP
           │ • loc (FK → dim_loc)             │  ← SAP lấy TT vị trí
           │ • pack_key (FK → dim_pack)       │  ← SAP lấy định dạng
           │                                  │
           │ DIMENSIONS:                      │
           │ • lpnid (Unique identifier)      │  ← **Định danh kiện**
           │ • lot (Lot number)               │  ← **Traceability**
           │ • whseid, storer_key             │
           │ • status (Available/Hold/QC)     │
           │ • palletid, cartonid, unitid     │
           │                                  │
           │ MEASURES:                        │
           │ • qty (Số lượng tồn)             │
           │ • qty_allocated (Đã chỉ định)    │
           │ • qty_picked (Đã pick)           │
           │ • qty_available (Còn lại)        │  ← Calculated
           │ • created_date, updated_date     │
           │ • is_deleted                     │
           │ • last_modified_date             │
           └──────────────────────────────────┘
                  │
                  │ Referenced by fact_inventory
                  │ (implicit - same data source)
                  ↓

           ┌──────────────────────────────────┐
           │   fact_inventory                 │  ← [PK: lpnid + lot + 
           │  (sự kiện tồn kho)               │       loc + sku...]
           ├──────────────────────────────────┤
           │ FOREIGN KEYS:                    │
           │ • receiptdetail_sk (FK, optional)│  ← dim_receiptdetail.key_sk
           │   (nguồn gốc nhập ban đầu)       │
           │ • sku_sk (FK)                    │  ← dim_sku.key_sk
           │ • pack_sk (FK)                   │  ← dim_pack.key_sk
           │ • loc (data reference)           │  ← dim_loc.loc
           │                                  │
           │ DIMENSIONS:                      │
           │ • whseid, storer_key             │
           │ • lpnid, lot, status             │
           │ • palletid, cartonid, unitid     │
           │                                  │
           │ MEASURES:                        │
           │ • qty, qty_allocated, qty_picked │
           │ • qty_available (= qty - alloc - picked)
           │ • created_date, updated_date     │
           │ • is_deleted                     │
           │ • last_modified_date             │  ← Incremental mốc
           └──────────────────────────────────┘


  ┌──────────────────────────────────────────────────────────────────┐
  │          OUTBOUND TRANSACTION LAYER (xuất hàng)                  │
  └──────────────────────────────────────────────────────────────────┘

           ┌──────────────────────┐
           │   dim_orders         │  ← [PK: order_key, whseid]
           │ (thông tin đơn hàng) │    Thông tin header đơn xuất
           ├──────────────────────┤
           │ • order_key (PK)     │
           │ • extern_order_key   │    ← Link từ ERP/Khách hàng
           │ • consignee_key (FK) │    ← Link tới subdim_storer
           │ • status             │
           │ • order_date         │
           │ • delivery_date      │
           │ • delivery_date      │
           │ • requested_ship_date│
           │ • actual_ship_date   │
           │ • is_deleted         │
           └──────────────────────┘
                  │ 1:N
                  │ [order_key, whseid, storer_key]
                  ↓
           ┌──────────────────────────────┐
           │  dim_orderdetail             │  ← [PK: order_key + 
           │   (chi tiết dòng đơn hàng)   │       order_line_number]
           ├──────────────────────────────┤
           │ FOREIGN KEYS:                │
           │ • sku (FK → dim_sku)         │  ← SAP lấy mô tả SP
           │ • pack_key (FK → dim_pack)   │  ← SAP lấy quy cách
           │                              │
           │ DIMENSIONS:                  │
           │ • order_key (PK)             │
           │ • order_line_number (PK)     │
           │ • sku, lot, lpnid            │
           │ • status (Pending/Picked)    │
           │ • condition_code             │
           │                              │
           │ MEASURES:                    │
           │ • original_qty (Đặt)         │
           │ • shipped_qty (Thực xuất)    │
           │ • qty_picked (Đã pick)       │
           │ • created_date, updated_date │
           │ • is_deleted                 │
           └──────────────────────────────┘
                  │
                  │ Referenced by fact_outbound
                  │ fk_orderdetail_sk
                  ↓

           ┌──────────────────────────────────┐
           │  dim_pickdetail                  │  ← [PK: pick_detail_key]
           │   (chi tiết thao tác lấy hàng)   │
           ├──────────────────────────────────┤
           │ FOREIGN KEYS:                    │
           │ • order_key (FK → dim_orders)    │  ← Trace lại order
           │ • order_line_number (indirect)   │  ← Link orderdetail
           │ • sku (FK → dim_sku)             │
           │ • pack_key (FK → dim_pack)       │
           │ • loc (indirect → dim_loc)       │  ← Vị trí lấy
           │                                  │
           │ DIMENSIONS:                      │
           │ • pick_detail_key (unique)       │
           │ • lpnid, lot, palletid           │
           │ • uom, status                    │
           │                                  │
           │ MEASURES:                        │
           │ • qty (Số lượng pick)            │
           │ • uom_qty (Theo đơn vị UOM)      │
           │ • created_date, updated_date     │
           │ • is_deleted                     │
           └──────────────────────────────────┘
                  │
                  │ Referenced by fact_outbound
                  │ fk_pickdetail_sk (implicit)
                  ↓

           ┌──────────────────────────────────┐
           │   fact_outbound                  │  ← [PK: pick_detail_key]
           │  (sự kiện xuất hàng)             │
           ├──────────────────────────────────┤
           │ FOREIGN KEYS:                    │
           │ • orderdetail_sk (FK)            │  ← dim_orderdetail.key_sk
           │ • orders_sk (FK)                 │  ← dim_orders.key_sk
           │ • sku_sk (FK)                    │  ← dim_sku.key_sk
           │ • pack_sk (FK)                   │  ← dim_pack.key_sk
           │ • loc (optional, data ref)       │  ← dim_loc.loc
           │                                  │
           │ DIMENSIONS:                      │
           │ • whseid, storer_key             │
           │ • lpnid, lot, status             │
           │ • palletid, cartonid, unitid     │
           │                                  │
           │ MEASURES:                        │
           │ • qty (Số lượng pick thực tế)    │
           │ • uom_qty (Theo UOM)             │
           │ • created_date, updated_date     │
           │ • is_deleted                     │
           │ • last_modified_date             │  ← Incremental mốc
           └──────────────────────────────────┘
  ```

### 6.2. Star Schema Design (DW Star Schema)

This project follows a classic star schema with 19 tables: a small number of denormalized fact tables (5 tables) at the center, each surrounded by conformed dimension tables (12 tables + 2 subdimension tables). Facts are built (denormalized and enriched) in DBT so queries read the fact directly without operational joins.

**[FACT TABLES - 5 bảng (Bắt buộc) - Tất cả dữ liệu cần phân tích đã nằm ở đây]:**
- `fact_order_fulfillment`    → Query này để phân tích đơn hàng, fill_rate_pct, qty_diff, qty_pending
- `fact_purchase_fulfillment` → Query này để phân tích PO, po_fill_rate_pct, plan_accuracy_pct
- `fact_inventory`            → Query này để xem tồn kho hiện tại, qty_available
- `fact_inbound`              → Query này để phân tích nhập hàng
- `fact_outbound`             → Query này để phân tích picking/xuất hàng

**[DIMENSION TABLES - 12 bảng (Có thể dùng để tìm kiếm hoặc filter)]:**
- `dim_sku` — Danh mục sản phẩm (nếu cần tìm sku_id từ sku code)
- `dim_loc` — Danh mục vị trí (nếu cần thông tin vị trí bin)
- `dim_pack` — Danh mục quy cách (nếu cần thông tin pallet/carton)
- `dim_po` / `dim_podetail` — Nếu cần chi tiết PO (nhưng data đã nằm trong fact_purchase_fulfillment)
- `dim_receipt` / `dim_receiptdetail` — Nếu cần chi tiết phiếu nhập (nhưng data đã nằm trong fact_inbound)
- `dim_orders` / `dim_orderdetail` — Nếu cần chi tiết đơn hàng (nhưng data đã nằm trong fact_order_fulfillment)
- `dim_pickdetail` — Nếu cần chi tiết picking (nhưng data đã nằm trong fact_outbound)
- `dim_lotxlocxid` — Nếu cần chi tiết tồn kho (nhưng data đã nằm trong fact_inventory)
- `dim_codelkup` — Danh mục mã hệ thống (nếu cần decode status/condition codes)

**[SUBDIMENSION TABLES - KHÔNG DÙNG TRỰC TIẾP]:**
- ~~`subdim_storer`~~ — ❌ KHÔNG dùng, dữ liệu đã nằm trong fact tables
- ~~`subdim_customergroup`~~ — ❌ KHÔNG dùng, dữ liệu đã nằm trong fact tables

**NGUYÊN TẮC CHÍNH:**
- ✅ **Fact tables**: Đã denormalized - chứa business keys + denormalized dimensions + calculated metrics
- ✅ **Dimension tables**: Master data reference - nếu cần tìm chi tiết
- ❌ **Subdimension tables**: KHÔNG dùng trực tiếp - dữ liệu đã nằm trong fact tables
- ❌ **Bảng trung gian**: KHÔNG dùng - các joins đã được xử lý trong DBT build-time

**Cách thức hoạt động:**
- DBT models (version3) already denormalized facts + performs all necessary JOINs at build-time
- User queries: Query FACT directly (tối đa LEFT JOIN 1-2 DIM nếu cần extra detail)
- Surrogate Keys (`sku_sk`, `pack_sk`, etc.): Tính bằng `cityHash64(col1, col2, ...)` cho deduplication
- Incremental tracking: `last_modified_date = greatest(ADDDATE, EDITDATE)` với ReplacingMergeTree
- CDC Pattern: `ReplacingMergeTree(last_modified_date)` + `OPTIMIZE TABLE ... FINAL` sau mỗi load
- Filter: Luôn lọc `STORERKEY = 'MDLZ'` và `WHSEID IN ('BKD1','BKD2','BKD3','NKD','VN821','VN831')`


  ### 6.2. Foreign Key Legend

  ```
  PK  = Primary Key (Khóa chính)
  FK  = Foreign Key (Khóa ngoại)
  1:N = One to Many relationship
  *   = Many to Many (implied through fact table)
  →   = References / Foreign Key relationship
  (indirect) = Reference thông qua cột data value, không có SK
  ```

  ---

  ### Original Summary (Older Format):

  ---

  ## 7. HƯỚNG DẪN SỬ DỤNG CHO CÁC BỘ PHẬN

  ⚠️ **LƯU Ý:** Các section dưới liệt kê "Bảng sử dụng" - tuy nhiên **NGUYÊN TẮC VẪN LÀ: QUERY FACT TABLES, LEFT JOIN DIM TABLES NẾU CẦN**
  - Ưu tiên: Query **FACT table** trực tiếp (dữ liệu đã denormalized)
  - Khi cần: LEFT JOIN **DIM tables** (tối đa 1-2 bảng tham chiếu)
  - **KHÔNG** query subdimension tables hoặc bảng trung gian

  ### 7.1. Phòng Lập kế hoạch Nhập kho (Inbound Planning)
  - **Bảng sử dụng:** `fact_inbound` (PRIMARY) → LEFT JOIN `dim_receipt`, `dim_sku`, `dim_pack` (if needed)
  - **Chỉ số phân tích:**
    - Số lượng phiếu nhập theo loại hình (Nhập mua, chuyển kho...)
    - Tỉ lệ hoàn thành nhập kho (So sánh dự kiến vs thực tế)
    - Phân bố sản phẩm nhập theo danh mục
    - Thời gian nhập hàng trung bình
  - **Sử dụng:** Lên kế hoạch nhập hàng, dự báo tồn kho

  ### 7.2. Bộ phận Quản lý Tồn kho (Inventory Management)
  - **Bảng sử dụng:** `fact_inventory` (PRIMARY) → LEFT JOIN `dim_sku`, `dim_loc`, `dim_pack` (if needed)
  - **Chỉ số phân tích:**
    - Tồn kho hiện tại (Real-time từ fact_inventory)
    - Hàng theo trạng thái (Sẵn bán, Khóa, Lỗi, QC)
    - Phân bố hàng theo khu vực kho (Zone)
    - Tracking qty_available (Hàng có sẵn để bán)
    - Tỉ lệ tổn hao hàng hóa
  - **Sử dụng:** Theo dõi tồn kho, cảnh báo hàng sắp hết, tối ưu hoá kho chứa

  ### 7.3. Phòng Lập kế hoạch Xuất kho / Picking (Outbound Planning)
  - **Bảng sử dụng:** `fact_outbound` + `fact_order_fulfillment` (PRIMARY) → LEFT JOIN `dim_orders`, `dim_sku` (if needed)
  - **Chỉ số phân tích:**
    - Số lượng đơn xuất kho, tổng khối lượng/tấn
    - Tỉ lệ hoàn thành xuất kho (fill_rate_pct từ fact_order_fulfillment)
    - Thời gian picking trung bình (tracking từ fact_outbound)
    - Hàng chậm xuất (qty_pending > 0)
    - Tỉ lệ lỗi picking (qty_diff từ fact_order_fulfillment)
  - **Sử dụng:** Lên kế hoạch picking, tối ưu hoá quy trình, đánh giá hiệu suất

  ### 7.4. Phòng Lập kế hoạch Mua hàng (Purchase Planning)
  - **Bảng sử dụng:** `fact_purchase_fulfillment` (PRIMARY) → LEFT JOIN `dim_po`, `dim_sku` (if needed)
  - **Chỉ số phân tích:**
    - Hiệu suất nhà cung cấp (po_fill_rate_pct từ fact_purchase_fulfillment)
    - Độ chính xác kế hoạch mua (plan_accuracy_pct)
    - Phân tích chênh lệch (qty_planning_gap, qty_fulfillment_gap)
    - Giá trị dự kiến vs thực nhập
  - **Sử dụng:** Tối ưu hoá đơn mua, đánh giá nhà cung cấp

  ### 7.5. Phòng Kế toán & Tài chính (Finance & Accounting)
  - **Bảng sử dụng:** `fact_inbound` + `fact_outbound` + `fact_inventory` + `fact_purchase_fulfillment` (PRIMARY) → LEFT JOIN `dim_sku`, `dim_pack` (if needed)
  - **Chỉ số phân tích:**
    - Giá trị hàng nhập (qty_received × unit_cost từ fact_purchase_fulfillment)
    - Giá trị hàng xuất (từ fact_outbound)
    - Giá trị tồn kho cuối kỳ (Real-time từ fact_inventory)
    - Chi phí quản lý kho (Theo dòng, theo sản phẩm)
    - Tỉ lệ lỗi/tổn hao hàng
  - **Sử dụng:** Lập báo cáo tài chính, kiểm kê kho, đánh giá chi phí

  ### 7.6. Team BI / Data Analyst
  - **Bảng sử dụng (PRIMARY):** `fact_inventory`, `fact_inbound`, `fact_outbound`, `fact_order_fulfillment`, `fact_purchase_fulfillment`
  - **Bảng sử dụng (REFERENCE khi cần):** Tất cả DIM tables (LEFT JOIN)
  - **KHÔNG sử dụng:** Subdimension tables, bảng trung gian
  - **Mục đích:**
    - Tạo Dashboard theo dõi hiệu suất kho
    - Mô hình dự báo tồn kho
    - Phân tích xu hướng nhập/xuất
    - Báo cáo trọng điểm quản lý
    - Phân tích KPI fill_rate, po_fill_rate_pct, plan_accuracy_pct

  ### 7.7. Ban Quản lý Kho (Warehouse Management)
  - **Bảng sử dụng:** `fact_inventory`, `dim_lotxlocxid`, `dim_loc`, `fact_inbound`, `fact_outbound`, `fact_order_fulfillment`
  - **Chỉ số phân tích:**
    - Hiệu suất sử dụng không gian kho (Tỷ lệ công suất từ fact_inventory)
    - Thời gian cycle time (Nhập → Tồn → Xuất)
    - Năng suất nhân viên (Số giao dịch/nhân/ngày từ fact_outbound)
    - Tỉ lệ lỗi/chất lượng dịch vụ (qty_diff từ fact_order_fulfillment)
    - Dự báo che phủ tồn kho (Stock cover từ fact_inventory)
  - **Sử dụng:** Quản lý vận hành, cải thiện quy trình

  ---

  ## 8. SUMMARY: 19 BẢNG TRONG DATA WAREHOUSE SWM

| Bảng | Loại | Quy mô | Mục đích chính |
|:----|:----|:----|:----|
| **MASTER DATA LAYER (Danh mục)** | - | - | - |
| dim_sku | Dimension | ~10K | Danh mục sản phẩm, properties vật lý |
| dim_loc | Dimension | ~5K | Danh mục vị trí bin kho |
| dim_pack | Dimension | ~500 | Quy cách đóng gói sản phẩm |
| dim_codelkup | Dimension | ~500 | Mã hệ thống (status, condition, loại) |
| subdim_storer | Subdimension | ~200 | Danh mục khách hàng/Storer |
| subdim_customergroup | Subdimension | ~100 | Nhóm khách hàng |
| **PURCHASING LAYER (Mua hàng)** | - | - | - |
| dim_po | Dimension | ~2K | Đơn mua hàng (header) |
| dim_podetail | Dimension | ~50K | Chi tiết dòng mua hàng |
| fact_purchase_fulfillment | Fact | ~50K | Phân tích % hoàn thành PO (po_fill_rate_pct) |
| **INBOUND LAYER (Nhập hàng)** | - | - | - |
| dim_receipt | Dimension | ~3K | Chứng từ nhập (header) |
| dim_receiptdetail | Dimension | ~100K | Chi tiết nhập + lot, expiry date |
| fact_inbound | Fact | ~100K | Sự kiện nhập kho |
| **INVENTORY LAYER (Tồn kho)** | - | - | - |
| dim_lotxlocxid | Dimension | ~50K | Chi tiết tồn theo lot, vị trí, qty_available |
| fact_inventory | Fact | ~50K | Snapshot tồn kho hiện tại |
| **OUTBOUND LAYER (Xuất hàng)** | - | - | - |
| dim_orders | Dimension | ~5K | Đơn hàng (header) |
| dim_orderdetail | Dimension | ~150K | Chi tiết đơn hàng |
| dim_pickdetail | Dimension | ~150K | Chi tiết picking (từng lần lấy hàng) |
| fact_outbound | Fact | ~150K | Sự kiện xuất hàng/picking |
| fact_order_fulfillment | Fact | ~150K | Phân tích % hoàn thành đơn (fill_rate_pct) |

  ## 9. CHI PHÍ & HIỆU NĂNG

  ### 9.1. Kích thước bảng (ước lượng cho 1 tháng dữ liệu)
  | Bảng | Số dòng | Dung lượng (MB) |
  | :--- | :--- | :--- |
  | dim_sku | ~10,000 | 5 |
  | dim_loc | ~5,000 | 2 |
  | dim_pack | ~500 | 0.5 |
  | dim_po | ~2,000 | 1 |
  | dim_podetail | ~50,000 | 25 |
  | dim_receipt | ~3,000 | 1.5 |
  | dim_receiptdetail | ~100,000 | 50 |
  | dim_orders | ~5,000 | 2.5 |
  | dim_orderdetail | ~150,000 | 75 |
  | dim_pickdetail | ~150,000 | 75 |
  | dim_lotxlocxid | ~50,000 | 25 |
  | dim_codelkup | ~500 | 0.3 |
  | subdim_storer | ~200 | 0.1 |
  | subdim_customergroup | ~100 | 0.05 |
  | fact_inbound | ~100,000 | 40 |
  | fact_inventory | ~50,000 | 20 |
  | fact_outbound | ~150,000 | 60 |
  | fact_order_fulfillment | ~150,000 | 60 |
  | fact_purchase_fulfillment | ~50,000 | 20 |
  | **Tổng cộng** | **~1,000,000** | **~456** |

  ### 9.2. Hiệu năng truy vấn
  - **Tồn kho hiện tại:** < 1 giây
  - **Báo cáo hàng ngày:** ~ 5 giây
  - **Phân tích xu hướng (1 tháng):** ~ 10 giây
  - **Báo cáo toàn bộ dữ liệu:** ~ 30 giây (tùy độ phức tạp)

  ---

  ## 10. VÍ DỤ TRUY VẤN PHỔ BIẾN

  ### 10.1. Truy vấn Tồn kho Hiện tại (FACT ONLY)
  ```sql
  -- Query FACT TABLE trực tiếp - không cần JOIN (data đã có sẵn)
  SELECT 
      sku,
      SUM(qty) as tong_so_luong,
      SUM(qty_available) as so_luong_co_san,
      SUM(qty_allocated) as so_luong_da_chi_dinh,
      SUM(qty_picked) as so_luong_da_pick
  FROM fact_inventory
  WHERE whseid = 'BKD1'
    AND storer_key = 'MDLZ'
    AND is_deleted = false
  GROUP BY sku
  ORDER BY tong_so_luong DESC;
  ```

  ### 10.2. Đơn hàng Chưa Hoàn Thành (FACT ONLY)
    ```sql
    -- Query FACT TABLE trực tiếp - tất cả thông tin đã có, không cần JOIN
    SELECT
        order_key,
        extern_order_key,
        sku,
        original_qty,
        shipped_qty,
        qty_diff,              -- = original_qty - shipped_qty (tính sẵn)
        qty_pending,           -- = qty_picked - shipped_qty (tính sẵn)
        fill_rate_pct,         -- Tỷ lệ hoàn thành (tính sẵn)
        created_date
    FROM fact_order_fulfillment
    WHERE whseid = 'BKD1'
      AND storer_key = 'MDLZ'
      AND is_deleted = false
      AND original_qty > shipped_qty  -- chỉ lấy những dòng chưa được ship đầy đủ
    ORDER BY created_date ASC;
    ```

  ### 10.3. Hàng trong Kho (FACT ONLY - Snapshot tồn kho)
  ```sql
  -- Query FACT TABLE - không cần JOIN, tất cả thông tin đã có
  SELECT 
      sku,
      lot,
      lpnid,
      loc,
      qty,
      qty_available,        -- Số có sẵn để bán (tính sẵn)
      qty_allocated,        -- Số đã chỉ định
      qty_picked,           -- Số đã pick
      last_modified_date
  FROM fact_inventory
  WHERE whseid = 'BKD1'
    AND storer_key = 'MDLZ'
    AND status = 'Available'
    AND qty_available > 0
    AND is_deleted = false
  ORDER BY last_modified_date DESC
  LIMIT 100;
  ```

  ### 10.4. Hiệu Suất Nhập Kho (FACT ONLY)
  ```sql
  -- Query FACT TABLE - không cần JOIN, tất cả thông tin đã denormalized
  SELECT 
      toDate(created_date) as ngay_nhap,
      COUNT(DISTINCT receipt_key) as so_phieu_nhap,
      COUNT(*) as so_dong_chi_tiet,
      SUM(qty_received) as tong_so_luong,
      COUNT(DISTINCT sku) as so_loai_san_pham
  FROM fact_inbound
  WHERE toDate(created_date) >= toDate(today() - 7)
    AND storer_key = 'MDLZ'
    AND is_deleted = false
  GROUP BY toDate(created_date)
  ORDER BY ngay_nhap DESC;
  ```

  ### 10.5. Hiệu Suất Picking (FACT ONLY)
  ```sql
  -- Query FACT TABLE - không cần JOIN, tất cả thông tin đã có
  SELECT 
      toDate(created_date) as ngay_picking,
      COUNT(DISTINCT pick_detail_key) as so_lan_pick,
      SUM(qty) as tong_qty_master_unit,
      SUM(uom_qty) as tong_qty_uom
  FROM fact_outbound
  WHERE toDate(created_date) >= toDate(today() - 7)
    AND storer_key = 'MDLZ'
    AND is_deleted = false
  GROUP BY toDate(created_date)
  ORDER BY ngay_picking DESC;
  ```

  ---

  ## 11. QUY TẮC CHẤT LƯỢNG DỮ LIỆU

  ### 11.1. Quy Tắc Bắt Buộc
  | Bảng | Cột | Quy tắc | Hậu quả |
  | :--- | :--- | :--- | :--- |
  | dim_sku | sku, whseid, storer_key, key_sk | NOT NULL | Từ chối record nếu thiếu |
  | dim_loc | loc, whseid, key_sk | NOT NULL | Từ chối record nếu thiếu |
  | dim_receipt | receipt_key, whseid, key_sk | NOT NULL | Từ chối đơn nhập |
  | dim_receiptdetail | receipt_key, sku, lottable01 (Lot) | NOT NULL | Cần traceability |
  | dim_orders | order_key, whseid, storer_key | NOT NULL | Từ chối đơn hàng |
  | dim_orderdetail | order_key, sku, original_qty | NOT NULL | Từ chối dòng hàng |
  | dim_po | po_key, whseid, storer_key | NOT NULL | Từ chối đơn mua |
  | dim_podetail | po_key, sku, qty_original | NOT NULL | Từ chối dòng PO |
  | fact_inventory | qty | >= 0 | Không cho âm |
  | fact_outbound | qty, uom_qty | >= 0 | Không cho âm |
  | fact_order_fulfillment | original_qty, shipped_qty | >= 0 | Không cho âm |
  | fact_purchase_fulfillment | qty_original, qty_received | >= 0 | Không cho âm |

  ### 11.2. Quy Tắc Toàn vẹn Dữ liệu
  - **Unique Key (Surrogate Keys):** Mỗi bản ghi dimension phải có `key_sk` duy nhất
    - key_sk được tính bằng `cityHash64(col1, col2, col3...)` từ các khóa tự nhiên
    - VD: dim_sku.key_sk = cityHash64(sku, whseid, storer_key)
  - **Referential Integrity:** Surrogate Keys trong fact tables phải tồn tại trong bảng dimension liên kết
    - fact_inventory.sku_sk phải tương ứng với dim_sku.key_sk
    - fact_inbound.receipt_sk phải tương ứng với dim_receipt.key_sk
  - **Fact Keys:** key_sk trong fact phải tương ứng với businesskey dimension keys
  - **Incremental Tracking:** `last_modified_date` phải được cập nhật chính xác từ nguồn (greatest(created_date, updated_date))
  - **Soft Delete Tracking:** `is_deleted` phải phản ánh trạng thái xóa từ nguồn (false = hoạt động, true = đã xóa)
  - **Duplicate Check:** Kiểm tra duplicate trên {whseid, receipt_key, receipt_line_number} trong dim_receiptdetail
  - **Date Validation:** 
    - `ADDDATE <= EDITDATE`
    - `lottable04 (MFG Date) < lottable05 (Expiry Date)`
    - `receipt_date <= now()`

  ### 11.3. Quy Tắc Tính Toán
  - **qty_available** = qty - qty_allocated - qty_picked (luôn >= 0)
  - **shipped_qty** <= original_qty trong dim_orderdetail
  - **Tồn kho cuối kỳ** = Nhập - Xuất - Tổn hao

  ### 11.4. Kiểm Tra Thường Xuyên
  ```sql
  -- Kiểm tra NULL không cho phép
  SELECT COUNT(*) as so_null
  FROM dim_sku
  WHERE sku IS NULL OR whseid IS NULL 
    OR storer_key IS NULL;

  -- Kiểm tra bản ghi trùng lặp
  SELECT whseid, sku, storer_key, COUNT(*) 
  FROM dim_sku
  GROUP BY whseid, sku, storer_key
  HAVING COUNT(*) > 1;

  -- Kiểm tra qty_available âm
  SELECT COUNT(*) as so_ly_tieu_chi
  FROM fact_inventory
  WHERE qty_available < 0;
  ```

  ---

  ## 12. HƯỚNG DẪN KHẮC PHỤC SỰ CỐ

  ### 12.1 Vấn đề: Tồn kho Không Khớp
  **Nguyên nhân có thể:**
  - Dữ liệu chưa được nạp đầy đủ (check `last_modified_date`)
  - Snapshot chưa OPTIMIZE hoàn toàn
  - Dữ liệu source bị thay đổi giữa lần chạy

  **Giải pháp:**
  ```sql
  -- Kiểm tra dữ liệu mới nhất
  SELECT MAX(last_modified_date), COUNT(*) 
  FROM dim_lotxlocxid;

  -- Chạy manual OPTIMIZE nếu cần
  OPTIMIZE TABLE fact_inventory FINAL;

  -- Kiểm tra 2 phiên bản bản ghi (ReplacingMergeTree)
  SELECT lpnid, lot, sku, qty, last_modified_date
  FROM fact_inventory
  WHERE lpnid = 'ABC123'
  ORDER BY last_modified_date DESC
  LIMIT 5;
  ```

  ### 12.2 Vấn đề: Đơn Hàng Không Hiển Thị
  **Nguyên nhân có thể:**
  - Order chưa được SYNC từ ERP
  - is_deleted = true (đơn đã bị hủy)
  - whseid không nằm trong danh sách lọc

  **Giải pháp:**
  ```sql
  -- Kiểm tra xem đơn hàng tồn tại không
  SELECT * FROM dim_orders
  WHERE extern_order_key = 'DO123456'
  LIMIT 1;

  -- Kiểm tra ngày update gần nhất
  SELECT MAX(last_modified_date) FROM dim_orders
  WHERE whseid = 'BKD1';
  ```

  ### 12.3 Vấn đề: Truy Vấn Chậm
  **Giải pháp:**
  ```sql
  -- Kiểm tra kích thước bảng
  SELECT 
      table_name, 
      formatReadableSize(total_bytes) as kich_thuoc
  FROM system.tables
  WHERE database = 'swm'
  ORDER BY total_bytes DESC
  LIMIT 10;

  -- Nén dữ liệu nếu cần
  OPTIMIZE TABLE fact_inventory FINAL;

  -- Sử dụng prewhere để lọc nhanh
  SELECT * FROM fact_inventory
  PREWHERE whseid = 'BKD1' AND is_deleted = false
  WHERE qty > 0;
  ```

  ---

  ## 13. TỪ ĐIỂN DỮ LIỆU (GLOSSARY)

  | Thuật ngữ | Viết tắt | Định nghĩa |
  | :--- | :--- | :--- |
  | Surrogate Key | SK | Khóa thay thế được tạo trong DW (không phải khóa nguồn) |
  | License Plate Number | LPN / LPNID | Mã định danh duy nhất cho một kiện hàng |
  | Stock Keeping Unit | SKU | Mã sản phẩm duy nhất trong WMS |
  | Material Handling Unit | MHU | Đơn vị xử lý vật liệu (pallet, thùng, kiện) |
  | Put Away | - | Quá trình cất hàng vào ô kệ |
  | Replenishment | - | Quá trình châm hàng từ khu lưu trữ chính |
  | Receiving | - | Quá trình nhập hàng vào WMS |
  | Picking | - | Quá trình lấy hàng từ ô kệ |
  | Shipping | - | Quá trình xuất hàng rời kho |
  | Lot / Batch | - | Nhóm hàng cùng số lô sản xuất |
  | Lot Table | LOTTABLE01-10 | Các trường lô mở rộng (số lô, NSX, HSD, v.v.) |
  | Condition Code | - | Đánh dấu tình trạng hàng (tốt/lỗi/QC) |
  | Whse ID | - | Warehouse ID - Mã kho |
  | Storer Key | - | Key chủ hàng (Storer) - thường là MDLZ |
  | Bin / Location | - | Ô kệ, vị trí cất hàng cụ thể |
  | Zone | - | Khu vực trong kho (Loose/Full/Receiving) |
  | Incremental Load | - | Nạp dữ liệu chỉ bản ghi thay đổi gần đây |
  | SCD Type 2 | - | Slowly Changing Dimension Type 2 (lưu lịch sử) |
  | ETL | Extract Transform Load | Trích xuất, chuyển đổi, nạp dữ liệu |
  | ReplacingMergeTree | - | Engine ClickHouse tự động xử lý bản ghi bị cập nhật |

  ---

  ## 14. CẤU HÌNH & KỲ VỌNG CẦN THIẾT

  ### 14.1: Môi Trường Cần Thiết
  - **ClickHouse Server:** Version 22.0+ 
  - **DBT:** Version 1.3+
  - **Python:** 3.8+
  - **dbt-clickhouse:** Latest version
  - **Network:** Kết nối tốc độ cao từ ERP/WMS tới DW

  ### 14.2: Tài Nguyên Tính Toán Khuyến Nghị
  - **CPU:** 8 cores
  - **RAM:** 32 GB (tối thiểu)
  - **Disk:** SSD 500 GB+ (phụ thuộc thể tích dữ liệu)
  - **Network Bandwidth:** 100 Mbps+

  ### 14.3: Giám Sát
  - Monitor `last_modified_date` trong các bảng để phát hiện sự gián đoạn
  - Theo dõi `dbt_updated_at` để xác định quy trình ETL hoạt động
  - Kiểm tra dung lượng disk hàng tuần
  - Alert nếu incremental load tăng bất thường

  ---

  ## 15. LỊCH SỬ THAY ĐỔI

  | Phiên bản | Ngày | Thay đổi |
  | :--- | :--- | :--- |
  | 1.0 | 01/03/2026 | Tài liệu ban đầu - 9 dimension + 3 fact tables |
  | 2.0 | 22/03/2026 | Thêm dim_codelkup, subdim_storer, cột thêu yếu, ví dụ | 
  | 2.1 | 23/03/2026 | Bổ sung QC rules, troubleshooting, glossary, query examples |
  | 2.2 | 24/03/2026 | Data Processing Architecture (NULL handling, Surrogate Keys, DateTime parsing, Incremental Logic) |
  | 2.3 | 25/03/2026 | **MAJOR UPDATE**: Comprehensive FK relationships (Section 19), Column Reference Guide (Section 20), Data Integrity Framework (Section 21), Enhanced ERD with explicit FK notation (Section 6.1-6.2) |
  | 2.4 | 26/03/2026 | **CRITICAL MODELS ADDED**: dim_po, dim_podetail, subdim_customergroup, fact_fulfillment (4 bảng thiếu). Complete column definitions from actual SQL models. **Total: 18 models documented** (12 dim + 2 subdim + 4 fact). |

  ---

  ## APPENDIX A: DANH SÁCH ĐẦY ĐỦ 18 MODELS (18 DBT Models)

  ### Dimension Tables (12 Bảng)
  | # | Model Name | Source Table | Purpose | Columns |
  | :--- | :--- | :--- | :--- | :--- |
  | 1 | **dim_codelkup** | swm.codelkup | Danh mục mã hệ thống (Status, Types, Codes) | 15+ (code, description, list_name, v.v.) |
  | 2 | **dim_loc** | swm.loc | Danh mục vị trí kho (Warehouse Locations) | 13+ (loc, whseid, status, zone, v.v.) |
  | 3 | **dim_lotxlocxid** | swm.lotxlocxid | Chi tiết tồn kho vật lý (Inventory Details) | 18+ (lpnid, lot, loc, qty, status, v.v.) |
  | 4 | **dim_orderdetail** | swm.orderdetail | Chi tiết dòng đơn hàng (Order Line Details) | 22+ (order_key, sku, qty, shipped_qty, v.v.) |
  | 5 | **dim_orders** | swm.orders | Thông tin đơn hàng (Order Master) | 14+ (order_key, consignee_key, status, dates, v.v.) |
  | 6 | **dim_pack** | swm.pack | Danh mục quy cách đóng gói (Packing Units: EA, CS, PL) | 8+ (pack_key, qty, factor, v.v.) |
  | 7 | **dim_pickdetail** | swm.pickdetail | Chi tiết thao tác lấy hàng (Pick Operation Details) | 17+ (pick_detail_key, order_key, qty, location, v.v.) |
  | 8 | **dim_po** | swm.po | Thông tin đơn mua hàng (Purchase Order Master) | 11+ (po_key, seller_name, buyer_* fields, v.v.) |
  | 9 | **dim_podetail** | swm.podetail | Chi tiết dòng đơn mua (PO Line Details) | 5+ (podetail_id, po_key, po_line_number, v.v.) |
  | 10 | **dim_receipt** | swm.receipt | Thông tin phiếu nhập kho (Receipt Master) | 14+ (receipt_key, supplier_*, status, dates, v.v.) |
  | 11 | **dim_receiptdetail** | swm.receiptdetail | Chi tiết dòng nhập kho (Receipt Line Details) | 24+ (receipt_key, sku, lottable*, qty_received, v.v.) |
  | 12 | **dim_sku** | swm.sku | Danh mục sản phẩm (Product Master) | 19+ (sku, category, weight, cube, strategy_keys, v.v.) |

  ### Sub-Dimension Tables (2 Bảng)
  | # | Model Name | Source Table | Purpose | Columns |
  | :--- | :--- | :--- | :--- | :--- |
  | 1 | **subdim_storer** | swm.storer | Danh mục khách hàng/Chủ hàng (Customer/Storer) | 18+ (storer_key, type, company, address, province, v.v.) |
  | 2 | **subdim_customergroup** | swm.customergroup | Nhóm khách hàng (Customer Grouping/Segmentation) | 8+ (group_code, group_name, phonenumber, address, shelf_life, v.v.) |

  ### Fact Tables (4 Bảng)
  | # | Model Name | Source Tables | Purpose | Key Measures |
  | :--- | :--- | :--- | :--- | :--- |
  | 1 | **fact_inbound** | dim_receiptdetail + dim_receipt + dim_sku + dim_pack + dim_codelkup | Sự kiện nhập kho (Inbound Transactions) | qty_received, condition_code, lottable* (lot tracking) |
  | 2 | **fact_inventory** | dim_lotxlocxid + dim_sku + dim_pack + dim_receiptdetail | Sự kiện tồn kho (Inventory State) | qty, qty_allocated, qty_picked, qty_available |
  | 3 | **fact_outbound** | dim_pickdetail + dim_orderdetail + dim_orders + dim_sku + dim_pack | Sự kiện xuất kho (Outbound Transactions) | qty, uom_qty, status |
  | 4 | **fact_fulfillment** | dim_orderdetail + dim_orders + dim_sku + dim_pack | Phân tích hoàn thành đơn (Fulfillment Analytics) | original_qty, shipped_qty, qty_diff, fill_rate_pct, qty_pending |

  ### Tóm tắt Mô hình Dữ liệu
  ```
  ✓ Dimension Tables:     12 bảng (danh mục tham chiếu)
  ✓ SubDimension Tables:  2 bảng (danh mục con)
  ✓ Fact Tables:          4 bảng (sự kiện/giao dịch)
  ─────────────────────────────────
  ✓ TỔNG:                 18 bảng
  
  Data Lineage:
  swm_db (PostgreSQL) → DBT Transformation → ClickHouse (Warehouse)
  
  Engines Used:
  • Dimensions:    ReplacingMergeTree(last_modified_date) - SCD Type 2
  • Facts:         ReplacingMergeTree(composite_last_modified_date)
  
  Incremental Strategy:  append (ReplacingMergeTree auto-handles deduplication)
  ```

  ---

  ## 16. CONTACT & SUPPORT

  | Chức năng | Người chịu trách nhiệm | Email |
  | :--- | :--- | :--- |
  | **Data Architecture** | Data Team Lead | data.lead@company.com |
  | **DBT Pipeline** | DBT Admin | dbt.admin@company.com |
  | **SWM Data / Inbound-Outbound** | Warehouse Manager | warehouse.mgr@company.com |
  | **Data Quality** | QA Lead | qa.lead@company.com |
  | **Troubleshooting** | Support Team | support@company.com |

  ---

  **Tài liệu được cập nhật lần cuối:** 26/03/2026
  ---

  **Tài liệu phiên bản:** 2.4 - SWM Data Warehouse Design Document (Complete with 18 DBT Models)

  ## 17. CHI TIẾT KIẾN TRÚC XỬ LÝ DỮ LIỆU (DATA PROCESSING ARCHITECTURE)

  ### 17.1. Chiến lược Surrogate Key (Hash Function)

  **Phương pháp:** Tất cả các bảng SWM sử dụng hàm `cityHash64()` để tạo khóa thay thế (Surrogate Key).

  **Ưu điểm so với MD5:**
  - Tốc độ: cityHash64 nhanh hơn MD5 ~5x
  - Output: 64-bit (32 character hex string) - tiết kiệm dung lượng
  - Tính nhất quán: Đảm bảo cùng input → cùng output

  **Công thức:**
  ```
  cityHash64(ifNull(col1, ''), ifNull(col2, ''), ifNull(col3, ''), ...)
  ```

  **Ví dụ thực tế:**
  - `dim_sku`: `cityHash64(ifNull(sku,''), ifNull(whseid,''), ifNull(storer_key,''))`
  - `dim_receiptdetail`: `cityHash64(whseid, receipt_key, receipt_line_number)`
  - `dim_lotxlocxid`: `cityHash64(whseid, storer_key, lpnid, lot, loc, sku, unitid, cartonid, palletid, status)`

  ### 17.2. Xử lý Giá trị NULL (Null Handling Strategy)

  **Nguyên tắc:** Tất cả các cột khóa (key columns) phải được xử lý null trước khi tính hash.

  **Cú pháp:**
  ```sql
  ifNull(column_name, '')  -- Thay NULL bằng chuỗi rỗng
  ```

  **Lý do:** 
  - NULL giá trị trong hash function sẽ tạo ra kết quả không xác định
  - Sử dụng chuỗi rỗng đảm bảo tính đều đặn

  **Áp dụng vào tất cả các dimension tables:**
  ```sql
  ifNull(s.SKU,'')        as sku,
  ifNull(s.WHSEID,'')     as whseid,
  ifNull(s.STORERKEY,'')  as storer_key,
  ```

  ### 17.3. Xử lý Dữ liệu Thời gian (Date/Time Processing)

  **Chuyển đổi cơ bản:**
  ```sql
  toDateTime(COLUMN_NAME)  -- Thành TIMESTAMP (tính đến giây)
  ```

  **Xử lý chuỗi ngày (String → DateTime):**
  ```sql
  parseDateTimeBestEffortOrNull(column_str)
  -- Tự động nhận diện format: ISO 8601, YYYY-MM-DD, DD/MM/YYYY...
  -- Nếu parse thất bại → trả về NULL (không raise exception)
  ```

  **Ví dụ trong `dim_lotxlocxid`:**
  ```sql
  toDateTime(ADDDATE)     AS created_date,
  parseDateTimeBestEffortOrNull(editdate_str) AS updated_date,
  ```

  **Tạo last_modified_date (64-bit millisecond timestamp):**
  ```sql
  assumeNotNull(
      toDateTime64(
          greatest(ADDDATE, EDITDATE),  
          3  -- precision: 3 = millisecond
      )
  )
  ```

  ### 17.4. Incremental Logic (Delta Processing)

  **Phương pháp:** 
  - Lần chạy đầu: Nạp toàn bộ dữ liệu từ source
  - Lần chạy tiếp theo: Chỉ nạp những bản ghi có `last_modified_date >= MAX(last_modified_date)` từ target table

  **Cú pháp DBT Jinja:**
  ```jinja
  {% if is_incremental() %}
      AND toDateTime64(greatest(EDITDATE, ADDDATE), 3) >= (
          SELECT max(last_modified_date) FROM {{ this }}
      )
  {% endif %}
  ```

  **Fallback an toàn:** Nếu target table trống → dùng '1900-01-01'
  ```sql
  coalesce(max(last_modified_date), '1900-01-01')
  ```

  ### 17.5. Composite Last Modified Date (Cho Fact Tables)

  **Vấn đề:** Fact table có thể được cập nhật từ nhiều dimension sources.

  **Giải pháp:** Sử dụng `greatest()` để lấy timestamp mới nhất từ tất cả sources.

  **Ví dụ từ `fact_inbound`:**
  ```sql
  composite_last_modified_date = greatest(
      receiptdetail.last_modified_date,  -- Từ dim_receiptdetail
      receipt.last_modified_date,         -- Từ dim_receipt
      codelkup.last_modified_date         -- Từ dim_codelkup
  )
  ```

  **Incremental check:**
  ```sql
  WHERE composite_last_modified_date >= (
      SELECT MAX(composite_last_modified_date) FROM fact_inbound
  )
  ```

  ### 17.6. Source-Level Filtering (Dữ liệu Lọc)

  **Áp dụng tại lớp source (NOT downstream):**
  ```sql
  WHERE STORERKEY = 'MDLZ'
    AND WHSEID IN ('BKD1','BKD2','BKD3','NKD','VN821','VN831')
  ```

  **Ý nghĩa:**
  - `STORERKEY = 'MDLZ'`: Chỉ giữ dữ liệu của chủ hàng Mondelez
  - `WHSEID IN (...)`: Chỉ lấy 6 kho được phép (loại bỏ các warehouse khác)

  **Lợi ích:**
  - Giảm dung lượng dữ liệu cần xử lý
  - Tăng tốc độ truy vấn
  - Đảm bảo separation of concerns (dữ liệu MDLZ hoàn toàn tách biệt)

  ### 17.7. Post-Processing Hook (Nén Dữ liệu)

  **ReplacingMergeTree Optimization:**
  ```sql
  OPTIMIZE TABLE {{ this }} FINAL SETTINGS optimize_throw_if_noop=1
  ```

  **Mục đích:**
  - Sau khi INSERT, ClickHouse có nhiều parts chứa bản ghi cũ
  - OPTIMIZE FINAL hợp nhất tất cả parts và loại bỏ duplicates
  - `optimize_throw_if_noop=1`: Ném exception nếu không có gì để optimize (báo lỗi)

  **Khi nào cần?**
  - Fact tables: Luôn (vì nhiều updates)
  - Dimension tables: Thường (nếu có thay đổi dữ liệu)

  ### 17.8. Quy trình ETL Toàn bộ (End-to-End Flow)

  ```
  Source Tables (swm.* in PostgreSQL)
      ↓ [Filters applied: STORERKEY='MDLZ', WHSEID IN (...)]
      ↓
  WITH src CTE (perform transformations + null handling)
      ↓ [Check is_incremental() and apply delta filter]
      ↓
  INSERT INTO Dimension/Fact Table (ReplacingMergeTree)
      ↓ [Post-hook: OPTIMIZE TABLE ... FINAL]
      ↓
  Final optimized table ready for querying
  ```

  **Incremental Execution:**
  1. Query MAX(last_modified_date) từ target table
  2. WHERE clause filters: last_modified_date >= MAX(...)
  3. INSERT dữ liệu mới vào target (append strategy)
  4. ReplacingMergeTree tự handle deduplication dựa trên last_modified_date
  5. OPTIMIZE FINAL gộp parts + loại bỏ old versions

  ---

  ---

  ## 18. TÓMLƯỢC ĐẠI CƯƠNG (EXECUTIVE SUMMARY)

  ### 18.1. Tổng quan Kiến trúc Dữ liệu

  Hệ thống SWM Data Warehouse được xây dựng trên nền tảng ClickHouse (NoSQL columnar database) với mục tiêu:
  1. **Lưu trữ dữ liệu tập trung** từ hệ thống Smart Warehouse Management (SWM)
  2. **Phân tích hiệu suất hoạt động** (inbound, inventory, outbound)
  3. **Theo dõi traceability** từng sản phẩm/lô hàng từ nhập → tồn → xuất
  4. **Hỗ trợ báo cáo thời gian thực** cho các nhân viên quản lý kho

  ### 18.2. Quy trình Dữ liệu từ A → Z

  ```
  ┌─────────────────────┐
  │  SWM Source System  │  ← Hệ thống gốc (PostgreSQL)
  │  (11 bảng nguồn)    │     swm.sku, swm.receipt, swm.orders, ...
  └──────────┬──────────┘
            │
            ↓
  ┌─────────────────────────────────────────────┐
  │  DBT Transformation Layer (11 SQL models)   │
  │ ┌─────────────────────────────────────────┐ │
  │ │  FILTER: STORERKEY='MDLZ'               │ │  Lọc chỉ dữ liệu
  │ │  FILTER: WHSEID IN (6 kho cho phép)    │ │  của Mondelez
  │ └─────────────────────────────────────────┘ │
  │ ┌─────────────────────────────────────────┐ │
  │ │  TRANSFORM: NULL handling + Date Parsing │ │  Xử lý NULL,
  │ │  - ifNull() → chuỗi rỗng                │ │  chuyền đổi dữ liệu
  │ │  - parseDateTimeBestEffortOrNull()      │ │  từ string → DateTime
  │ └─────────────────────────────────────────┘ │
  │ ┌─────────────────────────────────────────┐ │
  │ │  GENERATE KEYS: cityHash64() for SK     │ │  Tạo surrogate keys
  │ │  - Unique identifier per dimension      │ │  (64-bit hash)
  │ └─────────────────────────────────────────┘ │
  └──────────┬──────────────────────────────────┘
            │
            ↓
  ┌──────────────────────────────────────────────┐
  │  ClickHouse Database (ReplacingMergeTree)    │
  │ ┌────────────────────────────────────────┐  │
  │ │  11 Dimension Tables (Danh mục)        │  │  Bảng lookup
  │ │  + 1 Sub-Dimension (Khách hàng/Supplier)  │  với SCD Type 2
  │ │  + 3 Fact Tables (Sự kiện)             │  │
  │ └────────────────────────────────────────┘  │
  │ ┌────────────────────────────────────────┐  │
  │ │  Post-processing: OPTIMIZE FINAL       │  │  Nén & loại bỏ
  │ │  (hợp nhất parts, xóa old versions)    │  │  bản ghi cũ
  │ └────────────────────────────────────────┘  │
  └──────────┬───────────────────────────────────┘
            │
            ↓
  ┌──────────────────────────────────────────────┐
  │  Ready for BI/Analytics Queries              │
  │  - Real-time inventory dashboard             │
  │  - Inbound/Outbound performance reports      │
  │  - Lot traceability & expiry tracking        │
  └──────────────────────────────────────────────┘
  ```

  ### 18.3. Khi nào Dữ liệu được Cập nhật?

  **Incremental Process (Hàng ngày):**
  1. DBT chạy job hàng ngày (lịch định)
  2. So sánh `MAX(last_modified_date)` từ target database
  3. Chỉ lấy những bản ghi mới/thay đổi từ source
  4. INSERT vào ClickHouse (append-only strategy)
  5. ReplacingMergeTree tự động xử lý deduplication
  6. OPTIMIZE FINAL gộp nhỏ những parts lại

  **Tần suất:** Daily (1 lần/ngày, thường về sáng)

  **Lợi ích:**
  - Tiết kiệm bandwidth & thời gian xử lý
  - Dữ liệu luôn cập nhật (gần real-time)
  - Không cần DELETE trước, chỉ INSERT

  ### 18.4. Những Chỉ số Quan trọng (KPIs) để Theo dõi

  **Inventory Management:**
  - Tồn kho hiện tại (Real-time)
  - Hàng sắp hết hạn (Expiry tracking)
  - Hàng bị khóa/lỗi (Quality issues)

  **Inbound Performance:**
  - % đơn nhập hoàn thành (Receipt completion rate)
  - Thời gian nhập trung bình (Receiving cycle time)
  - Số lượng hàng lỗi nhập (Quality issues)

  **Outbound Performance:**
  - % đơn xuất hoàn thành (Shipment completion rate)
  - Tốc độ picking (Picking productivity)
  - Tỉ lệ lỗi (Error rate)

  ### 18.5. Hạn Chế & Cân Nhắc

  **Lưu ý Về Dữ liệu:**
  - Chỉ chứa dữ liệu **Mondelez (STORERKEY='MDLZ')**
  - Chỉ chứa **6 warehouse** được phép hoạt động
  - Dữ liệu là **soft-delete** (flag `is_deleted=true` để xóa mềm)

  **Về Hiệu suất:**
  - Bảng `fact_inbound` có join 3 sources → `composite_last_modified_date`
  - Cột `lottable04`, `lottable05` có thể NULL (parse fail) → cần handle
  - OPTIMIZE FINAL có thể tốn thời gian nếu dữ liệu lớn

  **Khuyến Nghị:**
  - Nên schedule DBT job vào giờ off-peak (e.g., 2-3 AM)
  - Monitor OPTIMIZE FINAL tasks trong ClickHouse system table
  - Kiểm tra `dbt_updated_at` để biết thời điểm last refresh

  ---

  ## 19. KHÓA NGOẠI & LIÊN HỆ DỮ LIỆU (FOREIGN KEY RELATIONSHIPS)

  ### 19.1. Quan Hệ Khóa Ngoại Toàn Bộ Hệ Thống

  **Lưu ý:** ClickHouse không enforce foreign key constraints ở database level, nhưng các khóa dưới đây phải được tôn trọng trong bộ lọc/join queries.

  #### A. FACT_INVENTORY → DIMENSION TABLES

  | Cột trong Fact | Loại | Tham chiếu tới | Cột trong Dimension | Ý nghĩa | Bắt buộc |
  | :--- | :--- | :--- | :--- | :--- | :--- |
  | **receiptdetail_sk** | FK | dim_receiptdetail | key_sk | Nguồn gốc nhập hàng ban đầu (Và chi tiết phiếu nhập) | - |
  | **sku_sk** | FK | dim_sku | key_sk | Mã sản phẩm - Định danh sản phẩm đang tồn | ✓ |
  | **pack_sk** | FK | dim_pack | key_sk | Quy cách đóng gói của sản phẩm | - |
  | **storer_key** | Info | subdim_storer | storer_key | Chủ hàng sở hữu tồn kho (Thường = MDLZ) | ✓ |
  | **whseid** | Info | dim_loc | whseid | Kho quản lý vị trí tồn kho hiện tại | ✓ |

  **Ghi chú:** 
  - `receiptdetail_sk` có thể NULL nếu hàng nhập từ source khác (adjust, transfer)
  - **Dữ liệu Denormalized:** Fact table đã chứa sẵn tất cả thuộc tính sản phẩm (SKU mô tả, category, chiều dài, chiều rộng...) và quy cách đóng gói (qty per pack) - **không cần LEFT JOIN** để phân tích thông thường
  - Surrogate keys (sku_sk, pack_sk) được lưu chỉ để **optional reference** nếu cần metadata bổ sung từ dimensions (e.g., strategy keys mới nhất)
  - Dim_loc là **reference bảng** nếu cần thông tin vị trí chi tiết (zone, shelf type) - không bắt buộc cho phân tích tồn kho cơ bản

  ---

  #### B. FACT_INBOUND → DIMENSION TABLES

  | Cột trong Fact | Loại | Tham chiếu tới | Cột trong Dimension | Ý nghĩa | Bắt buộc |
  | :--- | :--- | :--- | :--- | :--- | :--- |
  | **receiptdetail_sk** | FK | dim_receiptdetail | key_sk | Chi tiết dòng nhập từ phiếu nhập | ✓ |
  | **receipt_sk** | FK | dim_receipt | key_sk | Thông tin phiếu nhập chung (header level) | ✓ |
  | **sku_sk** | FK | dim_sku | key_sk | Sản phẩm được nhập | ✓ |
  | **pack_sk** | FK | dim_pack | key_sk | Quy cách đóng gói nhập | ✓ |
  | **codelkup_sk** | FK | dim_codelkup | key_sk | Mã hệ thống (Type: RECEIPT_TYPE, CONDITION_CODE) | - |
  | **storer_key** | Info | subdim_storer | storer_key | Chủ hàng (Mondelez = MDLZ) | ✓ |
  | **whseid** | Info | - | - | Mã kho nhập (thông tin ngữ cảnh) | ✓ |

  **Ghi chú:**
  - **receiptdetail_sk + receipt_sk** tạo composite key định danh duy nhất nhận hàng
  - **Dữ liệu Denormalized:** Tất cả thông tin cơ bản cần phân tích (sku, lot tracking, qty_received, condition, dates...) đã **có sẵn** trong fact table - không cần joins để truy vấn phổ biến
  - Surrogate keys được lưu để **optional enrichment** - chỉ join dimensions nếu cần metadata bổ sung (e.g., supplier contact info từ receipt lookup)
  - **Khuyến nghị:**
    - Truy vấn fact table trực tiếp cho sạch mạch phân tích (kiểm tra expiry dates, quality issues, lot traceability)
    - Joins là **OPTIONAL** và chỉ khi cần thông tin ngoài fact table

  **PHƯƠNG PHÁP TIÊU CHUẨN - ĐỪNG DÙNG JOINS:**
  ```sql
  -- ✅ RECOMMENDED: Query fact table DIRECTLY (Denormalized approach)
  SELECT 
      receipt_key,
      receipt_line_number,
      sku,
      lottable01 as lot_number,
      lottable05 as expiry_date,
      qty_received,
      condition_code,
      created_date
  FROM fact_inbound
  WHERE whseid = 'BKD1'
    AND is_deleted = false
    AND lottable05 < now() -- Items nearing/past expiry
  ORDER BY lottable05 ASC
  LIMIT 1000;
  ```

  **Nếu cần thêm metadata (OPTIONAL joins):**
  ```sql
  -- ✅ ADVANCED: Chỉ join khi thực sự cần attributes không có trong fact
  SELECT 
      fi.receipt_key,
      fi.sku,
      fi.lottable01
      fi.qty_received,
      ds.descr,  -- ← Từ denormalized fact table (nếu đã có)
      dp.qty as pack_qty
  FROM fact_inbound fi
  LEFT JOIN dim_sku ds ON fi.sku_sk = ds.key_sk  -- Optional: nếu cần attributes khác
  LEFT JOIN dim_pack dp ON fi.pack_sk = dp.key_sk
  WHERE fi.whseid = 'BKD1';
  ```

  ---

  #### C. FACT_OUTBOUND → DIMENSION TABLES

  | Cột trong Fact | Loại | Tham chiếu tới | Cột trong Dimension | Ý nghĩa | Bắt buộc |
  | :--- | :--- | :--- | :--- | :--- | :--- |
  | **orderdetail_sk** | FK | dim_orderdetail | key_sk | Chi tiết dòng đơn hàng được pick | ✓ |
  | **orders_sk** | FK | dim_orders | key_sk | Thông tin đơn hàng chung (header level) | ✓ |
  | **sku_sk** | FK | dim_sku | key_sk | Sản phẩm được lấy (pick) | ✓ |
  | **pack_sk** | FK | dim_pack | key_sk | Quy cách đóng gói lấy | ✓ |
  | **storer_key** | Info | subdim_storer | storer_key | Chủ hàng (MDLZ) | ✓ |
  | **whseid** | Info | - | - | Mã kho xuất (ngữ cảnh) | ✓ |
  | **loc** | Info (Optional) | dim_loc | loc | Vị trí lấy hàng (nếu có) | - |

  **Ghi chú:**
  - **orderdetail_sk + orders_sk** tạo composite key định danh đơn hàng + dòng
  - Một dòng orderdetail có thể được pick **nhiều lần** (split pickup) → nhiều bản ghi trong fact_outbound
  - **Dữ liệu Denormalized:** Fact table chứa sẵn qty, uom, status, dates - không cần LEFT JOIN để truy vấn phổ biến
  - Khóa ngoại được lưu để **optional reference** - chỉ join nếu cần metadata bổ sung (e.g., ERP order number, customer name)
  - `loc` là optional (có thể NULL nếu chưa scan vị trí)

  **PHƯƠNG PHÁP TIÊU CHUẨN - TRỰC TIẾP QUERY FACT:**
  ```sql
  -- ✅ RECOMMENDED: Denormalized fact table (Tất cả data cần thiết có sẵn)
  SELECT 
      order_key,
      order_line_number,
      sku,
      original_qty,
      SUM(qty) as tong_so_luong_picked,
      original_qty - SUM(qty) as so_luong_con_lai,
      status
  FROM fact_outbound
  WHERE whseid = 'BKD1'
    AND is_deleted = false
  GROUP BY order_key, order_line_number, sku, original_qty, status
  ORDER BY created_date DESC;
  ```

  **Nếu cần ERP info hoặc mô tả sản phẩm (OPTIONAL):**
  ```sql
  -- ✅ ADVANCED: Chỉ join khi cần attributes từ dimensions
  SELECT 
      o.extern_order_key,
      od.order_line_number,
      fo.sku,
      SUM(fo.qty) as picked,
      fo.original_qty - SUM(fo.qty) as remaining
  FROM fact_outbound fo
  LEFT JOIN dim_orders o ON fo.orders_sk = o.key_sk  -- Optional: nếu cần ERP info
  LEFT JOIN dim_orderdetail od ON fo.orderdetail_sk = od.key_sk
  WHERE o.whseid = 'BKD1'
  GROUP BY o.extern_order_key, od.order_line_number, fo.sku, fo.original_qty;
  ```

  ---

  ### 19.2. Liên Hệ Dim-to-Dim (Dimension-to-Dimension)

  **Lưu ý Kiến Trúc:** Trong data warehouse OLAP, dimension-to-dimension joins là **HIẾM** trong phân tích. Thay vào đó:
  - **Fact tables được denormalize** → Chứa tất cả thông tin cần phân tích
  - Để audit hoặc data quality checks, bạn có thể join dimensions
  - Những joins này thường chỉ dùng trong **DBT transformation layer** hoặc **data validation scripts**, không phải analytical queries

  #### A. DIM_RECEIPTDETAIL → DIM_RECEIPT (1:N)

  **Mối Quan Hệ Logic:**
  - Mỗi receipt có nhiều dòng chi tiết (receiptdetail)
  - **Khóa Join:** (receipt_key, whseid, storer_key)

  **Sử Dụng:** Thường dùng trong DBT transformation (không phải analytical query)
  ```sql
  -- Audit/QA: Kiểm tra consistency giữa receipt header vs detail
  SELECT r.receipt_key, COUNT(*) as so_dong_chi_tiet
  FROM dim_receipt r
  INNER JOIN dim_receiptdetail rd USING (receipt_key, whseid, storer_key)
  GROUP BY r.receipt_key
  HAVING COUNT(*) = 0  -- Tìm receipts không có chi tiết (anomaly)
  ```

  #### B. DIM_RECEIPTDETAIL → DIM_SKU (N:1)

  **Mối Quan Hệ Logic:**
  - Mỗi dòng nhập tham chiếu một sản phẩm
  - **Khóa Join:** (sku, whseid, storer_key)

  **Sử Dụng (TRONG DBT, không analytical):**
  ```sql
  -- DBT Transformation: Load SKU attributes vào fact_inbound
  CREATE OR REPLACE TABLE fact_inbound AS
  SELECT 
      fi.*,
      ds.sku_sk,
      ds.descr as sku_description,  -- Denormalize vào fact
      ds.category
  FROM ... fact_inbound_staging fi
  LEFT JOIN dim_sku ds ON fi.sku = ds.sku
    AND fi.whseid = ds.whseid
    AND fi.storer_key = ds.storer_key;
  ```

  #### C. DIM_ORDERDETAIL → DIM_ORDERS (1:N)

  **Mối Quan Hệ Logic:**
  - Mỗi order có nhiều dòng chi tiết
  - **Khóa Join:** (order_key, whseid, storer_key)

  ---

  #### D. DIM_PICKDETAIL ← DIM_ORDERDETAIL (N:1)

  | Cột | Chi tiết |
  | :--- | :--- |
  | **order_key** ← order_key | Trace lại order gốc |
  | **order_line_number** ← order_line_number | Dòng cụ thể trong order |
  | **sku** ← sku | Sản phẩm tương ứng |

  **Lưu ý:** Một dòng orderdetail có thể được pick **nhiều lần** (nếu hàng ở nhiều vị trí hoặc thực hiện multiple picks)

  ---

  #### E. DIM_LOTXLOCXID ← DIM_SKU, DIM_LOC, DIM_PACK (N:1 each)

  | Cột | Tham chiếu | Ý nghĩa |
  | :--- | :--- | :--- |
  | **sku** ← dim_sku.sku | Sản phẩm trong tồn kho |
  | **loc** ← dim_loc.loc | Vị trí ô kệ chứa hàng |
  | **pack_key** ← dim_pack.pack_key | Quy cách đóng gói (optional) |

  ---

  ### 19.3. Validation Rules cho Foreign Keys

  #### Rule 1: Mandatory Foreign Keys
  ```sql
  -- Kiểm tra fact_inbound có receiptdetail_sk NULL
  SELECT COUNT(*) FROM fact_inbound
  WHERE receiptdetail_sk IS NULL;  -- Kỳ vọng: 0 hoặc rất ít
  ```

  #### Rule 2: Referential Integrity (Khóa tham chiếu phải tồn tại)
  ```sql
  -- Kiểm tra fact_inbound.receiptdetail_sk có tồn tại trong dim_receiptdetail
  SELECT COUNT(*) FROM fact_inbound fi
  WHERE NOT EXISTS (
      SELECT 1 FROM dim_receiptdetail rd
      WHERE rd.key_sk = fi.receiptdetail_sk
  );  -- Kỳ vọng: 0 (không có orphaned records)
  ```

  #### Rule 3: Cross-Reference Consistency
  ```sql
  -- Kiểm tra fact_outbound.orderdetail_sk có match với orders_sk
  SELECT COUNT(*) FROM fact_outbound fo
  LEFT JOIN dim_orderdetail od ON fo.orderdetail_sk = od.key_sk
  LEFT JOIN dim_orders o ON fo.orders_sk = o.key_sk
  WHERE (od.order_key != o.order_key AND o.order_key IS NOT NULL);
  -- Kỳ vọng: 0
  ```

  #### Rule 4: Fact-to-Dimension Grain Matching
  ```sql
  -- Kiểm tra fact_inventory.sku_sk khớp với receiptdetail.sku
  SELECT COUNT(*) FROM fact_inventory fi
  LEFT JOIN dim_receiptdetail rd ON fi.receiptdetail_sk = rd.key_sk
  LEFT JOIN dim_sku ds ON fi.sku_sk = ds.key_sk
  WHERE fi.sku IS NOT NULL AND ds.sku != fi.sku;
  -- Kỳ vọng: 0 (nếu có → dữ liệu không consistency)
  ```

  ---

  ### 19.4. Impact Analysis: Khi Dimension Data Thay Đổi

  #### Scenario 1: Cập nhật `dim_sku` (thay đổi descr, weight, v.v.)

  **Ảnh hưởng:**
  - Fact tables (fact_inbound, fact_outbound, fact_inventory) **KHÔNG bị ảnh hưởng** trực tiếp
  - Vì fact tables tham chiếu `sku_sk` (Surrogate Key), không phải `descr`
  - Khi query: LEFT JOIN dim_sku sẽ lấy giá trị descr, std_weight **mới nhất**

  **Query Impact:**
  ```sql
  -- Báo cáo này sẽ show mô tả SẢN PHẨM HIỆN TẠI (updated)
  SELECT fi.created_date, fi.sku, ds.descr
  FROM fact_inbound fi
  LEFT JOIN dim_sku ds ON fi.sku_sk = ds.key_sk
  WHERE fi.created_date = '2026-03-20';
  
  -- → Nếu dim_sku.descr được update hôm nay, báo cáo cũ sẽ hiển thị mô tả mới
  -- → Đây là hành vi kỳ vọng (SCD Type 1)
  ```

  #### Scenario 2: Xóa một SKU (is_deleted=true)

  **Ảnh hưởng:**
  - Fact tables vẫn giữ tham chiếu `sku_sk` cũ
  - Query sẽ trở về NULL nếu LEFT JOIN dim_sku (vì `is_deleted=true` bị exclude)

  **Phòng chống:**
  ```sql
  -- Luôn include is_deleted=false trong dim_sku filter
  SELECT fi.created_date, fi.sku, ds.descr
  FROM fact_inbound fi
  LEFT JOIN dim_sku ds ON fi.sku_sk = ds.key_sk 
    AND ds.is_deleted = false  -- ← QUAN TRỌNG!
  ```

  #### Scenario 3: Thay đổi vị trí kho (dim_loc.loc UPDATE)

  **Ảnh hưởng:**
  - fact_inventory tham chiếu `loc` (data value, không SK)
  - Nếu vị trí được đổi tên (e.g., A-01-01-01 → A-01-01-02), cần cập nhật fact_inventory

  **Giải pháp:**
  - Sử dụng `key_sk` thay vì `loc` value để join với dim_loc
  - Hoặc nếu `loc` là descriptive (không thay đổi), có thể giữ nguyên value

  ---

  ## 20. COLUMN REFERENCE GUIDE (HƯỚNG DẪN THAM CHIẾU CỘT)

  ### 20.1. Các Cột Định Danh (Identifier Columns)

  #### Primary Natural Keys (Khóa tự nhiên)
  | Bảng | Cột | Độc lập | Ít thay đổi | Ý nghĩa |
  | :--- | :--- | :--- | :--- | :--- |
  | dim_sku | sku, whseid, storer_key | ✓ | ✓ | Mã sản phẩm duy nhất trong kho |
  | dim_receipt | receipt_key, whseid, storer_key | ✓ | ✓ | Số phiếu nhập duy nhất |
  | dim_orders | order_key, whseid, storer_key | ✓ | ✓ | Số đơn xuất duy nhất |
  | dim_loc | loc, whseid | ✓ | ✓ | Tọa độ vị trí duy nhất |
  | dim_pack | pack_key, whseid | ✓ | ✓ | Quy cách đóng gói duy nhất |

  #### Surrogate Keys (Khóa thay thế)
  | Bảng | Surrogate Key | Hash từ | Kích thước |
  | :--- | :--- | :--- | :--- |
  | dim_sku | key_sk | sku + whseid + storer_key | 32 char |
  | dim_receipt | key_sk | whseid + receipt_key | 32 char |
  | dim_receiptdetail | key_sk | whseid + receipt_key + receipt_line_number | 32 char |
  | dim_orders | key_sk | storer_key + whseid + order_key | 32 char |
  | dim_orderdetail | key_sk | whseid + order_key + order_line_number | 32 char |
  | fact_inbound | key_sk | whseid + receipt_key + receipt_line_number | 32 char |
  | fact_outbound | key_sk | whseid + pick_detail_key | 32 char |
  | fact_inventory | key_sk | whseid + storer_key + lpnid + lot + loc + sku + unitid + cartonid + palletid + status | 32 char |

  ---

  ### 20.2. Các Cột Định Danh Kinh Doanh (Business Identifiers)

  #### Trong INBOUND (Nhập kho)
  | Cột | Bảng | Ý nghĩa | Duy nhất | Ví dụ |
  | :--- | :--- | :--- | :--- | :--- |
  | **receipt_key** | dim_receipt | Số phiếu nhập nội bộ | Có (per whseid) | RCP20260323001 |
  | **extern_receipt_key** | dim_receipt | Số ASN/PO từ bên ngoài | Có | PO-MDLZ-001 |
  | **receipt_line_number** | dim_receiptdetail | Số hiệu dòng trong phiếu | Có (per receipt_key) | 1, 2, 3 |
  | **lottable01** | dim_receiptdetail | Số lô sản xuất | KHÔNG | Có thể trùng nhiều sản phẩm |
  | **lpnid** | dim_lotxlocxid | Mã kiện hàng (License Plate) | Có (unique định danh kiện) | LPN-20260323-001 |

  #### Trong OUTBOUND (Xuất kho)
  | Cột | Bảng | Ý nghĩa | Duy nhất | Ví dụ |
  | :--- | :--- | :--- | :--- | :--- |
  | **order_key** | dim_orders | Số đơn xuất nội bộ | Có (per whseid) | ORD20260323001 |
  | **extern_order_key** | dim_orders | Số đơn từ ERP/khách | Có | SO-CUST-001 |
  | **order_line_number** | dim_orderdetail | Số hiệu dòng trong đơn | Có (per order_key) | 1, 2, 3 |
  | **pick_detail_key** | dim_pickdetail | Định danh thao tác pick | Có | PICK-20260323-001 |

  #### Trong INVENTORY (Tồn kho)
  | Cột | Bảng | Ý nghĩa | Duy nhất | Ví dụ |
  | :--- | :--- | :--- | :--- | :--- |
  | **lpnid** | dim_lotxlocxid | Mã kiện hàng | Có | LPN-20260323-001 |
  | **lot** | dim_lotxlocxid | Số lô sản xuất | KHÔNG | Có thể trùng nhiều SKU |
  | **loc** | dim_loc | Tọa độ vị trí ô kệ | Có (per whseid) | A-01-01-01 |
  | **sku** | dim_sku | Mã sản phẩm | Có (per whseid + storer) | SKU-12345 |

  ---

  ### 20.3. Cột Lot Tracking (Traceability)

  #### LOT TABLE Columns (dim_receiptdetail & fact_inbound)

  | Cột | Kiểu | Ý nghĩa | Bắt buộc | Ví dụ | Tác dụng |
  | :--- | :--- | :--- | :--- | :--- | :--- |
  | **lottable01** | VARCHAR | Số Lô sản xuất (Lot Number) | ✓ | LOT-20260101 | Traceability + Recall |
  | **lottable04** | TIMESTAMP | Ngày Sản Xuất (MFG Date) | - | 2026-01-05 | Tuổi sản phẩm |
  | **lottable05** | TIMESTAMP | Ngày Hết Hạn (Expiry Date) | - | 2027-01-05 | Shelf life tracking |
  | **lottable06** | VARCHAR | Thông tin Lô Mở Rộng | - | Serial#ABC | Bổ sung |
  | **lottable02, 03, 07-10** | VARCHAR | Trường mở rộng | - | - | Tùy chỉnh |

  #### Critical Validations
  ```sql
  -- Kiểm tra Expiry Date hợp lệ
  SELECT COUNT(*) FROM dim_receiptdetail
  WHERE lottable05 IS NOT NULL
    AND lottable04 IS NOT NULL
    AND lottable04 >= lottable05;  -- Kỳ vọng: 0

  -- Cảnh báo hàng sắp hết hạn (< 30 ngày)
  SELECT sku, lot, lpnid, lottable05
  FROM fact_inventory fi
  LEFT JOIN dim_receiptdetail rd ON fi.receiptdetail_sk = rd.key_sk
  WHERE datediff(day, today(), rd.lottable05) BETWEEN 0 AND 30
    AND fi.qty > 0
  ORDER BY rd.lottable05 ASC;
  ```

  ---

  ### 20.4. Cột Trạng Thái (Status Columns)

  #### Status Fields & Their Meanings

  | Bảng | Cột | Giá trị | Ý nghĩa |
  | :--- | :--- | :--- | :--- |
  | dim_receipt | status | New | Vừa tạo |
  | | | In Progress | Đang nhập hàng |
  | | | Received | Nhập hàng hoàn thành |
  | | | Closed | Đóng phiếu |
  | | | Cancelled | Hủy phiếu |
  | dim_receiptdetail | status | Pending | Chờ nhập |
  | | | Complete | Nhập đầy đủ |
  | | | Partial | Nhập một phần |
  | dim_orders | status | New | Vừa tạo |
  | | | Shipped | Đã xuất |
  | | | Cancelled | Đã hủy |
  | dim_orderdetail | status | Pending | Chờ lấy |
  | | | Picked | Đã lấy |
  | dim_receiptdetail | condition_code | OK | Hàng tốt |
  | | | NG | Hàng lỗi |
  | | | QC | Chờ kiểm chất lượng |
  | | | Damaged | Hàng hư hỏng |
  | dim_lot | status | Available | Có sẵn |
  | | | Hold | Bị khóa |
  | | | QC | Chờ QC |
  | | | Allocated | Đã chỉ định cho đơn |

  #### Lookup Tables for Status
  ```sql
  -- Query mã hệ thống để lấy mô tả status
  SELECT * FROM dim_codelkup
  WHERE list_name = 'RECEIPT_STATUS'
    OR list_name = 'CONDITION_CODE'
    OR list_name = 'INVENTORY_STATUS'
  ORDER BY code;
  ```

  ---

  ## 21. DATA INTEGRITY & VALIDATION FRAMEWORK

  ### 21.1. Critical Data Quality Checks (Có phải chạy trước query)

  #### A. Referential Integrity Checks

  **Check 1.1: Orphaned Foreign Keys in fact_inbound**
  ```sql
  -- Kiểm tra fact_inbound.receiptdetail_sk tồn tại trong dim_receiptdetail
  SELECT COUNT(*) as orphaned_count, 'fact_inbound' as table_name
  FROM fact_inbound fi
  WHERE fi.receiptdetail_sk IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM dim_receiptdetail rd
      WHERE rd.key_sk = fi.receiptdetail_sk
        AND rd.is_deleted = false
    );
  -- Expected: 0 (hoặc rất ít)
  ```

  **Check 1.2: Orphaned Foreign Keys in fact_outbound**
  ```sql
  -- Kiểm tra fact_outbound.orderdetail_sk tồn tại trong dim_orderdetail
  SELECT COUNT(*) as orphaned_count
  FROM fact_outbound fo
  WHERE fo.orderdetail_sk IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM dim_orderdetail od
      WHERE od.key_sk = fo.orderdetail_sk
        AND od.is_deleted = false
    );
  -- Expected: 0
  ```

  **Check 1.3: Orphaned Foreign Keys in fact_inventory**
  ```sql
  -- Kiểm tra fact_inventory.sku_sk tồn tại trong dim_sku
  SELECT COUNT(*) as orphaned_count
  FROM fact_inventory fi
  WHERE fi.sku_sk IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM dim_sku ds
      WHERE ds.key_sk = fi.sku_sk
        AND ds.is_deleted = false
    );
  -- Expected: 0
  ```

  ---

  #### B. Domain Integrity Checks

  **Check 2.1: Invalid Quantity Values**
  ```sql
  -- Kiểm tra số lượng không âm trong fact tables
  SELECT 
      'fact_inventory' as table_name,
      COUNT(*) as negative_qty_count
  FROM fact_inventory
  WHERE qty < 0 
    OR qty_allocated < 0 
    OR qty_picked < 0 
    OR qty_available < 0;

  UNION ALL

  SELECT 
      'fact_inbound' as table_name,
      COUNT(*) as negative_qty_count
  FROM fact_inbound
  WHERE qty_received < 0;

  UNION ALL

  SELECT 
      'fact_outbound' as table_name,
      COUNT(*) as negative_qty_count
  FROM fact_outbound
  WHERE qty < 0 OR uom_qty < 0;
  
  -- Expected: All 0 rows
  ```

  **Check 2.2: Date Sequence Violations**
  ```sql
  -- Kiểm tra ngày sản xuất < ngày hết hạn
  SELECT COUNT(*) as invalid_expiry
  FROM dim_receiptdetail
  WHERE lottable04 IS NOT NULL
    AND lottable05 IS NOT NULL
    AND lottable04 >= lottable05;

  -- Expected: 0
  ```

  **Check 2.3: Receipt Date ≤ Actual Effective Date (không thể nhập trước tạo)**
  ```sql
  -- Kiểm tra date_received >= created_date
  SELECT COUNT(*) as invalid_date
  FROM dim_receiptdetail
  WHERE date_received IS NOT NULL
    AND date_received < created_date;

  -- Expected: 0 (hoặc rất ít - chỉ khi có dữ liệu lỗi source)
  ```

  ---

  #### C. Uniqueness Constraints

  **Check 3.1: Duplicate Natural Keys in dim_sku**
  ```sql
  SELECT sku, whseid, storer_key, COUNT(*) as cnt
  FROM dim_sku
  GROUP BY sku, whseid, storer_key
  HAVING COUNT(*) > 1;

  -- Expected: 0 rows (no duplicates)
  -- Lưu ý: ReplacingMergeTree có thể có nhiều version của cùng SK,
  --        nhưng chỉ version latest (by last_modified_date) được return
  ```

  **Check 3.2: Duplicate Natural Keys in dim_receipt**
  ```sql
  SELECT receipt_key, whseid, storer_key, COUNT(*) as cnt
  FROM dim_receipt
  GROUP BY receipt_key, whseid, storer_key
  HAVING COUNT(*) > 1;

  -- Expected: 0 rows (no duplicates)
  ```

  **Check 3.3: Duplicate Natural Keys in dim_receiptdetail**
  ```sql
  SELECT receipt_key, receipt_line_number, whseid, COUNT(*) as cnt
  FROM dim_receiptdetail
  GROUP BY receipt_key, receipt_line_number, whseid
  HAVING COUNT(*) > 1;

  -- Expected: 0 rows
  ```

  ---

  #### D. Calculated Field Validation

  **Check 4.1: qty_available Calculation (Inventory)**
  ```sql
  -- Kiểm tra qty_available = qty - qty_allocated - qty_picked
  SELECT COUNT(*) as calc_errors
  FROM fact_inventory
  WHERE qty_available != (qty - CAST(qty_allocated AS INT) - CAST(qty_picked AS INT))
    OR qty_available < 0;

  -- Expected: 0
  -- Lưu ý: Nên có tolerance nhỏ nếu các field có decimal
  ```

  **Check 4.2: Order Fulfillment (Outbound)**
  ```sql
  -- Kiểm tra shipped_qty ≤ original_qty trong dim_orderdetail
  SELECT COUNT(*) as overship_errors
  FROM dim_orderdetail
  WHERE shipped_qty > original_qty;

  -- Expected: 0 (không cho phép shipped nhiều hơn đặt)
  ```

  ---

  #### E. Soft-Delete Consistency

  **Check 5.1: is_deleted Flag Validation**
  ```sql
  -- Kiểm tra is_deleted chỉ có giá trị true/false
  SELECT COUNT(*) as invalid_delete_flag
  FROM fact_inventory
  WHERE is_deleted NOT IN (true, false);

  -- Expected: 0
  ```

  **Check 5.2: Deleted Records Not Used in Facts**
  ```sql
  -- Kiểm tra fact_inventory không tham chiếu SKU bị deleted
  SELECT COUNT(*) as orphaned_dims
  FROM fact_inventory fi
  LEFT JOIN dim_sku ds ON fi.sku_sk = ds.key_sk
    AND ds.is_deleted = false
  WHERE fi.is_deleted = false
    AND ds.key_sk IS NULL;

  -- Expected: 0 (nếu > 0 → sku đã bị xóa nhưng fact vẫn tham chiếu)
  ```

  ---

  ### 21.2. Join Validation Rules (Quy tắc JOIN an toàn)

  #### Rule 1: Luôn Filter is_deleted=false trong Dimension
  ```sql
  -- ❌ KHÔNG: Có thể lấy dữ liệu deleted (outdated)
  SELECT * FROM fact_inbound fi
  LEFT JOIN dim_sku ds ON fi.sku_sk = ds.key_sk;

  -- ✅ ĐÚNG: Chỉ lấy dimension records còn hoạt động
  SELECT * FROM fact_inbound fi
  LEFT JOIN dim_sku ds ON fi.sku_sk = ds.key_sk
    AND ds.is_deleted = false;
  ```

  #### Rule 2: Sử dụng Surrogate Key (key_sk) cho Join
  ```sql
  -- ❌ KHÔNG: Join bằng data columns (dễ error nếu data thay đổi)
  SELECT * FROM fact_inbound fi
  LEFT JOIN dim_sku ON fi.sku = dim_sku.sku
    AND fi.whseid = dim_sku.whseid;

  -- ✅ ĐÚNG: Join bằng SK (single column, consistent)
  SELECT * FROM fact_inbound fi
  LEFT JOIN dim_sku ds ON fi.sku_sk = ds.key_sk;
  ```

  #### Rule 3: Handle NULL Foreign Keys
  ```sql
  -- ❌ KHÔNG: Inner join sẽ filter out NULL FKs (data loss)
  SELECT * FROM fact_inventory fi
  INNER JOIN dim_sku ds ON fi.sku_sk = ds.key_sk;

  -- ✅ ĐÚNG: LEFT JOIN để giữ records có optional FK
  SELECT * FROM fact_inventory fi
  LEFT JOIN dim_sku ds ON fi.sku_sk = ds.key_sk
    AND ds.is_deleted = false;
  ```

  #### Rule 4: Validate Composite Keys (Multi-part FK)
  ```sql
  -- Ví dụ: dim_sku có composite key (sku + whseid + storer_key)
  SELECT * FROM fact_inbound fi
  LEFT JOIN dim_sku ds ON fi.sku_sk = ds.key_sk
    -- Nếu join bằng SK → tất cả parts đã validated
    -- Không cần join lại từng part

  -- ✓ fact_inbound đã validate sku_sk → confidence cao SKU match
  ```

  ---

  ### 21.3. Common Join Patterns by Use Case

  #### Pattern A: Full Inventory Status Report
  ```sql
  SELECT 
      fi.lpnid,
      fi.lot,
      ds.sku,
      ds.descr as product_name,
      dl.loc as location,
      dp.pack_key,
      fi.qty as current_qty,
      fi.qty_allocated as allocated_qty,
      fi.qty_picked as picked_qty,
      fi.qty_available as available_qty,
      fi.status,
      rd.lottable05 as expiry_date,
      datediff(day, today(), rd.lottable05) as days_to_expiry,
      fi.created_date,
      fi.last_modified_date
  FROM fact_inventory fi
  LEFT JOIN dim_sku ds ON fi.sku_sk = ds.key_sk 
    AND ds.is_deleted = false
  LEFT JOIN dim_loc dl ON fi.loc = dl.loc 
    AND dl.is_deleted = false
  LEFT JOIN dim_pack dp ON fi.pack_sk = dp.key_sk
    AND dp.is_deleted = false
  LEFT JOIN dim_receiptdetail rd ON fi.receiptdetail_sk = rd.key_sk
    AND rd.is_deleted = false
  WHERE fi.is_deleted = false
    -- AND fi.whseid = 'BKD1'  -- Optional filter
  ORDER BY datediff(day, today(), rd.lottable05) ASC;
  ```

  #### Pattern B: Inbound Receipt Tracking
  ```sql
  SELECT 
      r.receipt_key,
      r.extern_receipt_key,
      r.supplier_name,
      r.receipt_date,
      COUNT(DISTINCT rd.receipt_line_number) as total_lines,
      COUNT(CASE WHEN rd.condition_code = 'OK' THEN 1 END) as good_qty_lines,
      COUNT(CASE WHEN rd.condition_code != 'OK' THEN 1 END) as issue_qty_lines,
      SUM(fi.qty_received) as total_qty_received
  FROM dim_receipt r
  LEFT JOIN dim_receiptdetail rd ON r.receipt_key = rd.receipt_key
    AND r.whseid = rd.whseid
    AND rd.is_deleted = false
  LEFT JOIN fact_inbound fi ON 
      fi.receiptdetail_sk = rd.key_sk
      AND fi.is_deleted = false
  WHERE r.is_deleted = false
    AND r.status IN ('Received', 'Closed')
  GROUP BY r.receipt_key, r.extern_receipt_key, 
           r.supplier_name, r.receipt_date
  ORDER BY r.receipt_date DESC;
  ```

  #### Pattern C: Outbound Order Fulfillment
  ```sql
  SELECT 
      o.extern_order_key,
      o.order_date,
      o.requested_ship_date,
      o.actual_ship_date,
      od.order_line_number,
      ds.sku,
      ds.descr,
      od.original_qty,
      COALESCE(SUM(fo.qty), 0) as total_picked_qty,
      od.original_qty - COALESCE(SUM(fo.qty), 0) as remaining_qty
  FROM dim_orders o
  LEFT JOIN dim_orderdetail od ON o.order_key = od.order_key
    AND o.whseid = od.whseid
    AND od.is_deleted = false
  LEFT JOIN dim_sku ds ON od.sku = ds.sku
    AND ds.is_deleted = false
  LEFT JOIN fact_outbound fo ON 
      fo.orderdetail_sk = od.key_sk
      AND fo.is_deleted = false
  WHERE o.is_deleted = false
    AND o.status != 'Cancelled'
  GROUP BY o.extern_order_key, o.order_date,
           o.requested_ship_date, o.actual_ship_date,
           od.order_line_number, ds.sku, ds.descr, od.original_qty
  ORDER BY o.order_date DESC;
  ```

  ---

  ### 21.4. Data Freshness & Currency Checks

  **Check 6.1: Incremental Load Status**
  ```sql
  -- Kiểm tra dữ liệu mốn nhất từ mỗi bảng => xác định dữ liệu up-to-date
  SELECT 
      'dim_sku' as table_name,
      MAX(last_modified_date) as max_modified_date,
      MAX(dbt_updated_at) as max_dbt_updated,
      datediff(hour, MAX(dbt_updated_at), now()) as hours_since_refresh
  FROM dim_sku
  
  UNION ALL
  
  SELECT 
      'fact_inbound',
      MAX(composite_last_modified_date),
      MAX(dbt_updated_at),
      datediff(hour, MAX(dbt_updated_at), now())
  FROM fact_inbound
  
  UNION ALL
  
  SELECT 
      'fact_outbound',
      MAX(last_modified_date),
      -- Note: fact_outbound không có dbt_updated_at
      NULL,
      NULL
  FROM fact_outbound;

  -- Expected output: hours_since_refresh < 24 (hoặc tùy theo SLA)
  ```

  **Check 6.2: Missing Recent Data**
  ```sql
  -- Nếu mong đợi nhập hàng hôm nay nhưng không thấy
  SELECT COUNT(*) as TODAY_INBOUND_COUNT
  FROM fact_inbound
  WHERE toDate(created_date) = today()
    AND is_deleted = false;
  
  -- Expected: > 0 (nếu có hoạt động nhập hôm nay)
  ```

  ---

  **Phiên bản:** 2.3 - SWM Data Warehouse Design Document (Complete with FK References & Column Guide)
