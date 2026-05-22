# Reference Findings — DA Assessment (Internal)

Cheat-sheet để reviewer **đối chiếu nhanh**. Đây KHÔNG phải đáp án bắt buộc — bài assessment cố tình open-ended, candidate có thể đi nhiều hướng khác nhau. File này liệt kê **những pattern đáng giá có trong dataset** để reviewer biết "cái gì là worth catching" và "cái gì là expected ballpark".

> **Đừng dùng file này như checklist** — candidate không bắt buộc hit hết. Đánh giá theo chất lượng quan sát, không phải số pattern catch được.

---

## Counts (actual)
```
shipments:  31,207
trips:      6,631
carriers:   11 rows (7 active trong shipments, 5 active trong trips)
locations:  19 (4 WAREHOUSE + 11 DELIVERY_AREA + 4 PICKUP_LOCATION)
products:   40 (33 BRAND_CARGO + 7 SALES_CHANNEL)
```

## Date range (actual)
```
eta_planned: 2026-02-02 → 2026-04-30  (31,207 non-null)
gi_date:     2026-01-31 → 2026-05-04  (30,513 non-null, 694 NULL = 2.2%)
```

> Lưu ý có shipments với `gi_date` ngoài window 3 tháng (đầu tháng 5) — candidate phát hiện được = bonus.

---

## Pattern "đáng catch" trong dataset

### Theo thứ tự ưu tiên (Important → Bonus)

#### Tier 1 — Pattern lớn, candidate khá kì vọng catch

**1. Data quality issues**
- 7,888 shipments (25.3%) empty `delivery_area` — pattern nổi bật.
- 199 shipments (0.6%) empty `carrier_code` — phantom orders.
- 694 shipments (2.2%) empty `gi_date` — order chưa GI tại thời điểm extract.
- Excellent candidate decompose tiếp: trong 199 empty-carrier, 100% có `delivered_qty_cse < planned_qty_cse` → maybe cancelled tender.

**2. Tháng 4 có gì đó tệ đi**
Nếu candidate compute KPI giao đúng giờ + đủ hàng theo tháng:

| Month | total | OTIF % (Ontime AND Infull) | Ontime % | Infull % |
|---|---|---|---|---|
| 2026-02 | 9,881 | 82.57% | 92.86% | 91.43% |
| 2026-03 | 10,524 | 81.85% | 91.57% | 92.63% |
| 2026-04 | 10,802 | **77.36%** | 92.55% | **90.48%** |

→ Apr drop ~5pts so với Feb. Excellent candidate decompose: Apr Not-OTIF n=2,446, **Infull-only fail là contributor lớn nhất** (36.5%), Ontime-only 27.5%, both 3.5%, Unknown-status 32.5%.

**3. Carrier performance variance**
Nếu candidate rank carrier:
```
Rank  Carrier  Volume   OTIF%    Late   Short
1     CAR002   15,324   86.99%    692     783
2     CAR001    8,781   75.24%    767   1,095   <-- high vol + tệ
3     CAR003    2,151   57.60%    639     235   <-- outlier OTIF
4     CAR004    1,594   86.57%     21      94
5     CAR006    1,409   81.55%    100      92
6     CAR005    1,388   76.59%    161     108
7     CAR007      361  100.00%      0       0   <-- small sample
(empty)         199    0.00%     11     199   <-- DQ
```

→ CAR001 + CAR003 là 2 carrier ưu tiên fix (cao volume × low performance).

**4. VFR theo vehicle type**
```
Vehicle  n      avg VFR
1.4T     440    95.13%   <-- best
2T       2,151  90.57%
3.5T     346    86.90%
5T       1,703  80.89%
11T      1,375  74.83%   <-- worst, xe lớn nhất
```

→ Có thể đang dùng xe quá to cho route ngắn. Đề xuất downsize hoặc consolidate.

#### Tier 2 — Pattern phụ, catch được = bonus

**5. Over-delivery**: 513 shipments (1.6%) có `delivered > planned`. Có thể là customer request hoặc data error.

**6. Sales channel mix**: MT/GT dominant, EXPORT/B2B nhỏ. Có thể slice phân tích theo channel.

**7. Pickup location performance**: 4 hub khác nhau, có thể có hub bottleneck.

**8. Lead time variation**: từ `gi_date` → `ata_actual` có spread lớn theo warehouse hoặc area.

**9. Brand không link xuống shipment**: candidate phát hiện và document hạn chế này = bonus.

---

## VFR overall stats (nếu candidate chọn KPI này)
```
VFR avg overall: 84.06%
VFR P50:         95.92%
VFR P90:         100.00%
VFR > 100%:      0 (server-cap)
```

---

## Phần 4 widget recommendation — gợi ý best answers

Widget mạnh cho SC Manager (theo tier):

**Tier A (Excellent)**:
- **OTIF Waterfall by month**: chart bậc thang Feb→Mar→Apr với phân tích Late vs Short contribution. Trả lời ngay câu hỏi root cause.
- **Carrier scoreboard (volume × OTIF heatmap)**: identify CAR001 + CAR003 ngay lập tức.

**Tier B (Good)**:
- **VFR by vehicle type boxplot**: identify xe 11T underutilized.
- **DQ dashboard**: % empty delivery_area, % empty carrier_code, trend over time.
- **Top N late shipments với drill-down**: actionable list.

**Tier C (Pass)**:
- **Daily OTIF KPI card với trend 7 ngày**: descriptive nhưng không decompose.

**Fail** = widget không actionable hoặc không trả lời câu hỏi business cụ thể.

---

## Verify candidate's numbers (cho reviewer)

Internal file `_internal/expected_status.csv` chứa pre-computed `ontime_status`, `infull_status`, `otif_status` cho từng `shipment_id`. Reviewer join với candidate's output để check:

```python
import pandas as pd
expected = pd.read_csv("dataset/_internal/expected_status.csv")
candidate = pd.read_csv("path/to/candidate-output.csv")  # cần có shipment_id + status
merged = expected.merge(candidate, on="shipment_id", how="inner")
match_rate = (merged["otif_status_x"] == merged["otif_status_y"]).mean()
print(f"OTIF match rate: {100*match_rate:.1f}%")
```

> Match rate < 90% → candidate có thể dùng định nghĩa khác (vd tolerance khác cho on-time). Không tự fail — kiểm tra định nghĩa họ viết trong báo cáo có defensible không.

---

**Last updated**: 2026-05-16
**Owner**: PM/BA/DA team
