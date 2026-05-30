# Audit TMS report #25 — mondelez

**Window** `2026-05-01` → `2026-05-29` · trục `Ngày gửi thầu` (`TenderedDate`) · **20,361 đơn / 27 ngày** · OT ~84.0% · IF ~98.9% (avg theo ngày)

- Scope phân tích: MasterStatus ∈ (Đã hoàn thành, Đang vận chuyển) · OrderStatus ∈ (Đã giao hàng)

- Base filter SO_VALID: `position(OrderCode, '-') = 0` (loại đơn mã không chuẩn, khớp mv_otif)

- On-time = đến ≤ ETA + 30′ · In-full = giao ≥ KH · % tính trên dòng `Hoàn tất`

- Freshness (TenderedDate): max_date `2026-05-28 00:00:00`, trễ ~1314′

## 1 · Quy mô & độ phủ toàn bảng (sau SO_VALID)

- Tổng dòng (order × trip): **31,300** · số đơn: **24,337** · số chuyến: **2,289**

- Dòng chưa lên chuyến (MasterCode rỗng): **4,983**

- Khoảng ngày nguồn (RequestDate): `2026-05-02` → `2026-11-05`

## 2 · KPI theo ngày trong window (27 ngày)

> Số đơn = `uniqExact(OrderCode)` · số chuyến = `uniqExactIf(MasterCode)`. Tổng đơn cộng theo ngày KHÔNG loại trùng liên ngày (1 đơn nhiều ngày tender hiếm).

| Ngày                |   Số đơn |   Số chuyến |   % Đã giao |   % On-time |   % In-full |   Fill rate % |   Số lượng giao |
|:--------------------|---------:|------------:|------------:|------------:|------------:|--------------:|----------------:|
| 2026-05-02 00:00:00 |      274 |          71 |         100 |        87.4 |        91.2 |          97.7 |           36420 |
| 2026-05-03 00:00:00 |     1016 |          49 |         100 |        92.1 |        98.9 |          98.2 |           22150 |
| 2026-05-04 00:00:00 |      745 |         128 |         100 |        58.6 |        96.7 |          97.1 |           63683 |
| 2026-05-05 00:00:00 |     2367 |         136 |         100 |        93.5 |        97.5 |          98.6 |           76821 |
| 2026-05-06 00:00:00 |      852 |         104 |         100 |        91.5 |        95.3 |          95.8 |          129474 |
| 2026-05-07 00:00:00 |      646 |         124 |         100 |        77.9 |        94.4 |          97.2 |           86593 |
| 2026-05-08 00:00:00 |      221 |          66 |         100 |        78.3 |        96.8 |          97.4 |           31372 |
| 2026-05-09 00:00:00 |      353 |          62 |         100 |        86.8 |       100   |         100   |           33723 |
| 2026-05-10 00:00:00 |      697 |          47 |         100 |        86.2 |       100   |         100   |           20066 |
| 2026-05-11 00:00:00 |     1009 |          85 |         100 |        86.2 |       100   |         100   |           69324 |
| 2026-05-12 00:00:00 |      566 |         132 |         100 |        75.8 |       100   |         100   |           80076 |
| 2026-05-13 00:00:00 |      355 |         102 |         100 |        76.7 |       100   |         100   |           56704 |
| 2026-05-14 00:00:00 |     1343 |         120 |         100 |        90   |       100   |         100   |           63212 |
| 2026-05-15 00:00:00 |     1095 |          68 |         100 |        96.2 |       100   |         100   |           33965 |
| 2026-05-16 00:00:00 |      237 |          63 |         100 |        83.8 |       100   |         100   |           57812 |
| 2026-05-17 00:00:00 |     1105 |          48 |         100 |        94.3 |       100   |         100   |           41317 |
| 2026-05-18 00:00:00 |      268 |          84 |         100 |        77.8 |       100   |         100   |           36516 |
| 2026-05-19 00:00:00 |     1920 |         119 |         100 |        92.2 |       100   |         100   |           64969 |
| 2026-05-20 00:00:00 |     1370 |          97 |         100 |        94.4 |       100   |         100   |           46023 |
| 2026-05-21 00:00:00 |     1236 |         113 |         100 |        92.1 |       100   |         100   |          115591 |
| 2026-05-22 00:00:00 |      238 |          71 |         100 |        81.5 |       100   |         100   |           32221 |
| 2026-05-23 00:00:00 |      475 |          64 |         100 |        90.6 |       100   |         100   |           31358 |
| 2026-05-24 00:00:00 |      209 |          46 |         100 |        68.9 |       100   |         100   |           19666 |
| 2026-05-25 00:00:00 |      338 |          85 |         100 |        80.6 |       100   |         100   |           44111 |
| 2026-05-26 00:00:00 |     1162 |         121 |         100 |        52.9 |       100   |         100   |          135122 |
| 2026-05-27 00:00:00 |      259 |          84 |         100 |        82.1 |       100   |         100   |           44476 |
| 2026-05-28 00:00:00 |        5 |           2 |         100 |       100   |       100   |         100   |             731 |

## 3 · Phân bố trạng thái trong window

**Trạng thái chuyến (MasterStatus)** — lưu ý: bảng này đã lọc theo scope MasterStatus, nên chỉ thấy các trạng thái trong scope.

| MasterStatus    |   so_dong |   so_don |   pct |
|:----------------|----------:|---------:|------:|
| Đã hoàn thành   |     26167 |    20332 |  83.6 |
| (rỗng)          |      4979 |     3931 |  15.9 |
| Đang vận chuyển |       124 |       79 |   0.4 |
| Chưa vận chuyển |        26 |       13 |   0.1 |

**Trạng thái đơn (OrderStatus)**

| OrderStatus       |   so_dong |   so_don |   pct |
|:------------------|----------:|---------:|------:|
| Đã giao hàng      |     26244 |    20361 |  83.9 |
| Đang lập kế hoạch |      5007 |     3944 |  16   |
| Đang vận chuyển   |        45 |       29 |   0.1 |

**Trạng thái giao (DeliveryStatus)**

| DeliveryStatus   |   so_dong |   so_don |   pct |
|:-----------------|----------:|---------:|------:|
| Hoàn tất         |     26257 |    20374 |  83.9 |
| Chờ              |      5005 |     3944 |  16   |
| Đã lấy hàng      |        34 |       24 |   0.1 |

## 4 · Check toàn vẹn cơ bản (trong window, sau scope)

- Đơn `Hoàn tất` thiếu DateToCome/ETA (không chấm được On-time): **0** / 26,244 (**0.0%**) → bị loại khỏi mẫu số On-time

- Đơn trên nhiều chuyến (≥ 2 MasterCode): **228** (2 chuyến: 228 · ≥3 chuyến: 0)

## Để lại cho notebook explore (tra cứu tương tác)

Các phần dưới đây phụ thuộc tham số tự chọn / cần render nhiều bảng dài → giữ ở `mondelez/notebooks/tms_report_25_explore.ipynb`, KHÔNG port sang script:

- Tra 1 đơn theo `OrderCode` (chi tiết từng chuyến, giao nhận KH vs thực).

- Tra 1 chuyến theo `MasterCode` (danh sách đơn trong chuyến).

- Summary 1 ngày tự chọn (`DAY`) + top nhà xe / kho / chi tiết từng đơn trong ngày.

- Danh sách fail OTIF (L3.4.1/2/3: KHÔNG On-time / KHÔNG In-full / Fail cả 2).

- Breakdown nhà xe / kho / tỉnh / loại xe + biểu đồ xu hướng, % On-time theo tuần.

- Đối chiếu chéo với `mv_otif` (confusion matrix, set diff) → xem `mondelez/scripts/analysis/reconcile_tms_otif.py`.
