# Analysis: Đối chiếu cấp đơn TMS (#25) vs `mv_otif` (Mondelez)

**Date**: 2026-05-28
**Requested by**: User (qua skill `/da-data`)
**Tenant scope**: Mondelez
**Window**: TenderedDate `2026-05-01 → 2026-05-31` (ngày VN)
**Notebook**: [`mondelez/notebooks/tms_report_25_explore.ipynb`](../../notebooks/tms_report_25_explore.ipynb) — section mới **L6**

## Question

So sánh **cấp đơn** (`OrderCode`) giữa 2 nguồn:
- TMS: `analytics_workspace.mdlz_tms_report_25_trip_order` (grain `Order × Trip`)
- MV : `analytics_workspace.mv_otif` (MaterializedView, REFRESH 5 phút; grain `so × whseid`)

Cụ thể: (1) số lượng đơn ở mỗi nguồn + giao nhau + lệch hai chiều, (2) đối chiếu trạng thái **Ontime** cấp đơn, (3) đối chiếu trạng thái **Infull** cấp đơn, (4) liệt kê đơn lệch.

## Method

Section **L6** mới được append vào notebook gồm 5 sub-section (mỗi sub-section 1 cell markdown + 1 cell code):

| Cell | Nội dung |
|---|---|
| L6.0 Setup | Tham số `CMP_FROM/CMP_TO`, `CMP_SERVICE='Xuất bán'`; helpers `_TMS_AGG`/`_MV_AGG`/`qcmp()` |
| L6.1 | Tổng đếm + bảng theo ngày — `trung` / `chi_tms` / `chi_mv` |
| L6.2 | Confusion matrix Ontime + top 30 đơn lệch (sort theo `\|trễ phút\|`) |
| L6.3 | Confusion matrix Infull + top 30 đơn lệch (sort theo `\|chênh KH–Giao\|`) |
| L6.4 | Set diff hai chiều — đơn chỉ ở TMS, đơn chỉ ở MV, bucket nguyên nhân |

**Quy về cấp đơn**:
- TMS group theo `OrderCode`: `kh = max(QuantityOrder)` (chống double-count khi đơn vào nhiều chuyến), `gn = sum(QuantityBBGN)`; Ontime = `Failed` nếu **bất kỳ** chuyến đã giao trễ ETA + grace 30′; Infull = `gn >= kh`.
- MV group theo `so`: nếu có **bất kỳ** dòng `Failed Ontime`/`Failed Infull` → đơn `Failed`; còn lại cho `Ontime`/`Infull` hoặc `any()` (vd `Không có dữ liệu STM`).

**Timezone**: TMS `TenderedDate` là string giờ VN; `mv_otif.thoi_gian_gui_thau` là `DateTime64('UTC')`. Cả 2 phía quy về **ngày VN** trước khi so.

**Parameter binding**: tất cả chuỗi tiếng Việt (`'Xuất bán'`, `'Hoàn tất'`) bind qua `{svc:String}`/`{ht:String}` chứ KHÔNG inline literal — `clickhouse-connect` corrupt UTF-8 trong scalar subquery khi inline (debug đã xác nhận trả 0 row khi inline, đúng số khi bind).

## Findings

### L6.1 · Tổng đếm (verified 2026-05-28)

| Chỉ số | Số đơn |
|---|---:|
| TMS (Xuất bán, May 2026) | **24,191** |
| `mv_otif` | **21,526** |
| Trùng cả 2 | **19,965** |
| Chỉ TMS (thiếu trong mv) | **4,226** |
| Chỉ mv_otif (thiếu trong TMS) | **1,561** |

Tổng cân bằng: `19,965 + 4,226 = 24,191` ✓ và `19,965 + 1,561 = 21,526` ✓.

### L6.2 · Confusion matrix Ontime (cấp đơn, match cả 2 → 19,960 đơn)

| TMS \ MV | Ontime | Failed Ontime | TỔNG |
|---|---:|---:|---:|
| Ontime         | 17,087 | 39    | 17,126 |
| Failed Ontime  |  1,161 | 1,100 |  2,261 |
| Chưa giao      |    137 |   441 |    578 |
| TỔNG           | 18,385 | 1,580 | 19,965 |

- **Khớp**: 17,087 + 1,100 = **18,187 đơn (91%)** cùng kết luận
- **Lệch một chiều TMS nghiêm hơn**: 1,161 đơn TMS nói `Failed Ontime` nhưng mv_otif nói `Ontime` — đáng audit
- **Lệch chiều ngược lại**: 39 đơn TMS nói `Ontime` nhưng mv_otif nói `Failed Ontime` — ít, có thể do mv_otif đo theo ATA chuyến (`ata_den`) còn TMS đo theo `DateToCome` của đơn
- **TMS Chưa giao nhưng MV đã chấm**: 578 đơn — `DeliveryStatus != 'Hoàn tất'` ở TMS nhưng MV đã có status (mv_otif dùng definition khác cho "đơn đã giao")

### L6.3 · Confusion matrix Infull (cấp đơn, match cả 2 → 19,965 đơn)

| TMS \ MV | Infull | Failed Infull | None | TỔNG |
|---|---:|---:|---:|---:|
| Infull         | 17,582 | 1,223 | 423 | 19,228 |
| Failed Infull  |     12 |   134 |  13 |    159 |
| Chưa giao      |      0 |   578 |   0 |    578 |
| TỔNG           | 17,594 | 1,935 | 436 | 19,965 |

- **Khớp**: 17,582 + 134 = **17,716 đơn (89%)** cùng kết luận
- **Lệch lớn 1 chiều**: 1,223 đơn TMS nói `Infull` nhưng mv_otif nói `Failed Infull` — số lượng lớn, hệ thống MV có thể đang trừ thêm lô hết hạn/lỗi giao (CSE-level) mà bảng `mdlz_tms_report_25_trip_order` không thấy. Xem thêm [s2-so-8482509466-cse-undercount-20260527.md](s2-so-8482509466-cse-undercount-20260527.md) — vấn đề CSE join lô đang regression ở `mv_otif_swm_stm_data`
- **Lệch chiều ngược**: 12 đơn TMS Failed nhưng MV Infull — rất ít
- **436 đơn MV `None`**: `infull_status` null/None — MV chưa tính ra được, cần backend dev check

### L6.4 · Set diff

**Chỉ TMS** (4,226 đơn) — bucket nguyên nhân:

| `OrderStatus` (TMS) | Số đơn | Chưa lên chuyến | Đã lên chuyến |
|---|---:|---:|---:|
| Đang lập kế hoạch | 4,019 | 3,984 | 35 |
| Đang vận chuyển   |   203 |     0 | 203 |
| Đã giao hàng      |     4 |     0 |   4 |

→ **95% đơn `Chỉ TMS` là `Đang lập kế hoạch`** (status 60 'Chờ' ở STM), khớp với root cause đã xác định trong [s2-otif-tms-discrepancy-20260516.md](s2-otif-tms-discrepancy-20260516.md) — mv_otif chỉ track `status_of_order_id IN (62, 63, 64)`.

Đáng chú ý: 203 đơn `Đang vận chuyển` đã có `MasterCode` nhưng vẫn vắng trong mv_otif — có thể do pipeline lag hoặc dispatch chưa đủ điều kiện. **Cần verify với backend dev.**

**Chỉ mv_otif** (1,561 đơn): sample đầu show các đơn `8482485451`/`8482487808`/... với `customer_name` rõ ràng (`AEON BINH DUONG NEW CITY`, `Sieu thi Bac Giang`...). Hypothesis: TenderedDate của TMS rơi vào cuối tháng 4 (timezone shift) hoặc đơn được tender đi tháng 5 ở MV nhưng `TenderedDate` ở TMS ghi tháng 4. Cần xác nhận bằng query trên TMS bỏ filter date.

## Recommendation

| Đối tượng | Action | Ưu tiên |
|---|---|---|
| **DA/PM** | Rerun L6 trong notebook → screenshot/share confusion matrix cho team OTIF | P1 |
| **Backend dev** | Investigate 1,161 đơn TMS `Failed Ontime` nhưng MV `Ontime` — có thể MV dùng `ata_den` (ATA chuyến) thay vì `DateToCome` (giao thực) → định nghĩa Ontime business KHÔNG đồng nhất giữa 2 nguồn | P1 |
| **Backend dev** | Investigate 1,223 đơn TMS `Infull` nhưng MV `Failed Infull` + 436 đơn MV `None` — liên quan đến CSE join lô đang regression | P1 |
| **Backend dev** | Verify 203 đơn `Đang vận chuyển` chỉ có ở TMS — có pipeline lag không? | P2 |
| **DA/PM** | Reframe câu hỏi business: muốn dùng MV làm source-of-truth (cần fix gap) hay TMS (cần xây pipeline tương đương)? | P2 |

## Caveats

1. **MV refresh 5 phút** → 2 lần đếm cách nhau vài phút có thể lệch 5–10 đơn (đã chứng kiến: 21,519 → 21,526 trong 1 lần đo). Số chỉ ổn định khi gating bằng `TenderedDate` < `now() - 1h`.
2. **Sub-day timezone edge** — đơn tender lúc nửa đêm VN (17:00 UTC) có thể bị shift ngày khi convert. Đã quy `toDate(toTimeZone(thoi_gian_gui_thau, 'Asia/Ho_Chi_Minh'))` ở MV → mismatch với TMS chỉ còn ở những đơn có MV `thoi_gian_gui_thau` lệch giờ thực tế so với TMS `TenderedDate` (rất hiếm).
3. **Ontime definition gap**: notebook dùng `DateToCome ≤ ETA + 30′` (ETA của đơn). MV dùng `ontime_status` được tính ở tầng `mv_otif_swm_stm_data` — chưa kiểm chứng business rule cụ thể. 1,161 đơn TMS-Failed/MV-Ontime cần verify rule này.
4. **CSE-level vs case-level Infull**: TMS chỉ có `QuantityBBGN` ở grain đơn; MV có `sum_san_luong_giao_cse`, `_kg`, `_cbm`, `_pl` + `cse_otif`. Notebook hiện so case-level (`QuantityBBGN >= QuantityOrder`), MV có thể đang so CSE → khác bản chất metric. Đây có thể là nguyên nhân chính của 1,223 đơn lệch Infull.
5. **Service scope**: notebook L6 mặc định lọc `ServiceOfOrderName='Xuất bán'` vì mv_otif chỉ track Xuất bán. Đổi `CMP_SERVICE` để so scope khác (Thu hồi / Chuyển kho), nhưng kỳ vọng MV trả 0 đơn cho service này.

## SQL Appendix

Toàn bộ SQL nằm trong notebook **L6**, dùng f-string template + parameter binding qua `qcmp(sql, params)`. Helper chính:

```python
_TMS_AGG = f"""
  SELECT OrderCode AS code, ...
         countIf(DeliveryStatus = {{ht:String}}) AS dong_da_giao,
         countIf(... AND NOT ({ONTIME()})) AS dong_tre,
         max({NUM('QuantityOrder')}) AS kh,
         sum({NUM('QuantityBBGN')}) AS gn,
         ...
  FROM ({_TMS_BASE})
  GROUP BY OrderCode
"""

_MV_AGG = f"""
  SELECT so AS code,
         if(countIf(ontime_status = 'Failed Ontime') > 0, 'Failed Ontime', ...) AS mv_ontime,
         if(countIf(infull_status = 'Failed Infull') > 0, 'Failed Infull', ...) AS mv_infull,
         ...
  FROM ({_MV_BASE})
  GROUP BY so
"""
```

Confusion matrix dùng `INNER JOIN tms_lab USING code` rồi pivot trong pandas.

---

ARTIFACT_PATH:
- `mondelez/notebooks/tms_report_25_explore.ipynb` (append 10 cells: L6.0 → L6.4)
- `mondelez/02-data/audit-results/tms-mv-otif-order-reconciliation-20260528.md` (file này)

DATA_CONFIDENCE: **High** — số đếm đã verify trực tiếp qua ClickHouse, confusion matrix balance đúng (tổng row = trung), bucket nguyên nhân 'Chỉ TMS' khớp với root cause audit trước. Phần "tại sao 1,161 đơn lệch Ontime" và "1,223 đơn lệch Infull" là **Hypothesis** đợi backend dev verify rule.

NEXT_ACTION:
- User rerun L6 trong notebook để confirm số live (MV refresh 5 phút).
- Handoff list 1,161 đơn lệch Ontime + 1,223 đơn lệch Infull (export từ L6.2/L6.3) cho backend dev → tìm root cause definition gap.
- Nếu muốn drill down 1 đơn lệch cụ thể: dùng L4.1 (`ORDER_CODE = '...'`) để xem chi tiết chuyến vs ETA, paired với `SELECT * FROM mv_otif WHERE so = '...'`.
