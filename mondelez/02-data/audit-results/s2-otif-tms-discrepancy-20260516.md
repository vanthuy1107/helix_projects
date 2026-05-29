# Audit: Chênh lệch TMS report vs mv_otif ngày 16/05/2026

**Ngày audit**: 2026-05-28  
**Người thực hiện**: da-ch audit workflow  
**DATA_CONFIDENCE**: HIGH — root cause xác nhận bằng set diff chính xác + truy ngược STM source  
**MV_FRESHNESS**: CRITICAL — `mv_otif` và `mv_otif_swm_stm_data` đang EMPTY (pipeline broken)  
**NEXT_ACTION**: (1) Escalate pipeline OTIF broken tới backend dev; (2) Xem xét bổ sung `status = 60` vào dashboard nếu stakeholder muốn track đơn Chờ  

---

## 1. Câu hỏi

> TMS report (filter `ServiceOfOrderName='Xuất bán'`, `TenderedDate='2026-05-16'`) = **245 đơn**,  
> nhưng mv.otif ("ngày gửi thầu" = 16/05) = **237 đơn**. Vì sao chênh 8?

---

## 2. Nguồn dữ liệu kiểm tra

| Bảng | Engine | Rows hiện tại | Ghi chú |
|---|---|---|---|
| `analytics_workspace.mdlz_tms_report_25_trip_order` | MergeTree | ~50k+ | TMS report raw |
| `analytics_workspace.mv_otif` | MaterializedView (REFRESH 5min) | **0** | ⚠️ EMPTY — pipeline bị vỡ |
| `analytics_workspace.mv_otif_swm_stm_data` | MaterializedView | **0** | ⚠️ EMPTY — là nguồn trực tiếp của mv_otif |
| `analytics_workspace.mv_otif_stm_data` | MaterializedView | 3,067,609 | OK — STM data có sẵn |
| `analytics_workspace.mv_otif_swm_data` | MaterializedView | 6,641,674 | OK — SWM data có sẵn |

**Phát hiện**: `mv_otif_swm_stm_data` = 0 rows dù cả 2 nguồn (`mv_otif_swm_data` và `mv_otif_stm_data`) đều có dữ liệu. Join/refresh bị lỗi ở tầng này.

---

## 3. Kết quả so sánh

| Câu truy vấn | Kết quả |
|---|---|
| TMS: `uniqExact(OrderCode)` WHERE `ServiceOfOrderName='Xuất bán'` AND `toDate(TenderedDate)='2026-05-16'` | **245** |
| mv_otif_stm_data: `uniqExact(Mã đơn hàng)` WHERE `toDate(Thời gian gửi thầu)='2026-05-16'` (UTC) | **237** |
| mv_otif (hiện tại) | **0** (EMPTY) |

---

## 4. Set diff – xác định 8 đơn

Giao nhau giữa 2 tập: **237 đơn** (mv_otif_stm_data ⊆ TMS).  
Không có đơn nào trong STM mà thiếu trong TMS.

**8 OrderCode chỉ tồn tại trong TMS (bị loại khỏi OTIF):**

| OrderCode | TenderedDate | DeliveryStatus (TMS) | status_of_order_id (STM) |
|---|---|---|---|
| 8482509879 | 2026-05-16 13:41:01 | Chờ | **60** |
| 8482509880 | 2026-05-16 13:41:02 | Chờ | **60** |
| 8482509889 | 2026-05-16 23:37:52 | Chờ | **60** |
| 8482509890 | 2026-05-16 23:37:52 | Chờ | **60** |
| 8482509892 | 2026-05-16 23:37:54 | Chờ | **60** |
| 8482509894 | 2026-05-16 23:38:03 | Chờ | **60** |
| 8482509895 | 2026-05-16 23:38:03 | Chờ | **60** |
| 8482509897 | 2026-05-16 23:38:03 | Chờ | **60** |

---

## 5. Root Cause

**Nguyên nhân chính**: `mv_otif_stm_data` chỉ lấy đơn có `status_of_order_id IN (62, 63, 64)`, loại bỏ status 60.

```sql
-- Filter trong mv_otif_stm_data (từ stm_dwh_mondelez.dim_ord_order):
WHERE ordm.service_name = 'Xuất bán'
  AND ordm.status_of_order_id IN (62, 63, 64)  ← status 60 bị loại
  AND ordm.customer_id = 9
  AND ifNull(toUInt8(dtd.is_deleted), 0) = 0
  AND ((toString(dtd.sort_order) = '1') OR (dtd.sort_order = '-1'))
  AND ifNull(toUInt8(trip.is_deleted), 0) = 0
  AND ifNull(toUInt8(tender.is_deleted), 0) = 0
```

**Ý nghĩa business**: Status 60 = "Chờ" (Chờ xếp chuyến / Pending dispatch). Đơn đã được gửi thầu nhưng **chưa được gán vào chuyến vận chuyển**. OTIF chỉ theo dõi đơn đã có chuyến (status 62–64), vì chưa có chuyến thì không có dữ liệu On-Time/In-Full để tính.

**Nguyên nhân phụ** (không phải timezone): 
- TMS `TenderedDate` lưu giờ Việt Nam (UTC+7) dưới dạng string
- STM `Thời gian gửi thầu` lưu UTC DateTime64
- Khi dùng `toDate()` trên UTC, 8 đơn này gửi lúc 13:41 và 23:37–23:38 VN → UTC là 06:41 và 16:37–16:38 → vẫn trong ngày 2026-05-16 UTC → không bị timezone lệch
- → Timezone KHÔNG phải nguyên nhân ở đây

---

## 6. Kết luận

| Điểm | Chi tiết |
|---|---|
| **Chênh lệch có lý không?** | Có — intentional design, không phải lỗi dữ liệu |
| **245 - 237 = 8** | 8 đơn `Chờ` (status 60) đang chờ xếp chuyến, chưa thuộc scope OTIF |
| **Dashboard OTIF** | Đang DOWN vì `mv_otif_swm_stm_data` = 0 rows |
| **Hành động cần thiết** | Backend dev kiểm tra pipeline join SWM × STM (mv_otif_swm_stm_data refresh error) |

---

## 7. SQL Appendix

```sql
-- TMS count ngày 16/05
SELECT uniqExact(OrderCode) AS tong_don
FROM (SELECT * FROM analytics_workspace.mdlz_tms_report_25_trip_order
      WHERE ServiceOfOrderName = 'Xuất bán') AS _t
WHERE toDate(parseDateTimeBestEffortOrNull(nullIf(TenderedDate, ''))) = '2026-05-16';
-- Result: 245

-- mv_otif_stm_data count ngày 16/05 (UTC)
SELECT uniqExact(`Mã đơn hàng`) AS tong_don
FROM analytics_workspace.mv_otif_stm_data
WHERE toDate(`Thời gian gửi thầu`) = '2026-05-16';
-- Result: 237

-- 8 đơn chỉ trong TMS (set diff)
SELECT DISTINCT OrderCode
FROM analytics_workspace.mdlz_tms_report_25_trip_order
WHERE ServiceOfOrderName = 'Xuất bán'
  AND toDate(parseDateTimeBestEffortOrNull(nullIf(TenderedDate, ''))) = '2026-05-16'
  AND OrderCode NOT IN (
      SELECT DISTINCT `Mã đơn hàng`
      FROM analytics_workspace.mv_otif_stm_data
      WHERE toDate(`Thời gian gửi thầu`) = '2026-05-16'
  );
-- Result: 8482509879, 8482509880, 8482509889, 8482509890,
--         8482509892, 8482509894, 8482509895, 8482509897

-- Kiểm tra status của 8 đơn trong STM
SELECT code, status_of_order_id, service_name, customer_id
FROM stm_dwh_mondelez.dim_ord_order
WHERE code IN ('8482509879','8482509880','8482509889','8482509890',
               '8482509892','8482509894','8482509895','8482509897')
  AND ifNull(toUInt8(is_deleted), 0) = 0;
-- Result: tất cả status_of_order_id = 60 ('Chờ')
```
