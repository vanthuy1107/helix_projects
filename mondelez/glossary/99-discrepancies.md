# 99 — Discrepancies (mismatch giữa Docs và Code)

Danh sách các điểm **PRD/spec/wireframe nói khác với code thực tế**. Cần BA + DEV cùng đối soát: docs sai? code đã refactor chưa update doc? hay đúng là 2 thứ khác nhau?

> Quy ước: mỗi mục có `Status` ∈ `OPEN` (chưa xử lý) / `RESOLVED` (đã đồng bộ) / `WONTFIX` (cố ý khác nhau, cần ghi rõ lý do).

---

## DISC-001 — `mv_flash_report` không tồn tại trong code

| Trường | Giá trị |
|--------|--------|
| Status | `OPEN` |
| Source doc | [`05-reference/[done] flash_report/flash-daily-report.prd.md:6`](../05-reference/[done]%20flash_report/flash-daily-report.prd.md) |
| Doc nói | MV name = `analytics_workspace.mv_flash_report` (refresh 5–30 phút) + `mv_flash_and_drop_report` (refresh 15 phút) |
| Code thực tế | Không có 2 MV trên. Hiện chỉ có: `mv_flrp_stm_data`, `mv_flrp_swm_data`, `mv_dropped_report`, `mv_dropped_stm`, `mv_dropped_swm` |
| Phán đoán | Code đã refactor split STM/SWM cho dễ maintain. PRD cần update tên MV. |
| Action | BA xác nhận với DA → update PRD `flash-daily/flash-daily-spec.md` để dùng tên mới. |

---

## DISC-002 — `mv_loose_picking_clickhouse` vs `mv_loose_picking`

| Trường | Giá trị |
|--------|--------|
| Status | `OPEN` |
| Source doc | [`05-reference/[done] loose-picking/loose-picking.prd.md:6`](../05-reference/[done]%20loose-picking/loose-picking.prd.md) |
| Doc nói | `mv_loose_picking_clickhouse` |
| Code thực tế | `mv_loose_picking` |
| Phán đoán | Doc cũ kèm hậu tố `_clickhouse` (legacy naming). Code đã đơn giản hóa. |
| Action | Update PRD/spec → `mv_loose_picking`. |

---

## DISC-003 — `mv_vfr` đã tách thành 2 lăng kính

| Trường | Giá trị |
|--------|--------|
| Status | `RESOLVED` (về mặt code, doc cần update) |
| Source doc | [`05-reference/[done] vfr/vfr.prd.md`](../05-reference/[done]%20vfr/vfr.prd.md) |
| Doc nói | (cũ) Có thể nói `mv_vfr` chung |
| Code thực tế | `mv_vfr_gui_thau` (tender lens) + `mv_vfr_van_hanh` (operational lens) |
| Phán đoán | Code chia rõ 2 lăng kính tender vs vận hành — đúng yêu cầu nghiệp vụ. PRD chỉ cần ghi rõ 2 MV. |
| Action | Verify trong PRD `vfr/spec.md` mới (ở `01-sections/vfr/`) đã reflect chưa. |

---

## DISC-004 — Component name có thể bị typo: `WidgetLateLateOrderAlert`

| Trường | Giá trị |
|--------|--------|
| Status | `OPEN` |
| Source code | `frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx` |
| Code nói (theo agent extract) | Class/function name `WidgetLateLateOrderAlert` (lặp `Late`) — cần verify trực tiếp file |
| Expected | `WidgetLateOrderAlert` (1 `Late`) |
| Phán đoán | Có thể là typo của extraction. Hoặc thật sự có typo trong code. |
| Action | DEV mở file confirm. Nếu typo thật → rename qua `gitnexus_rename`. |

---

## DISC-005 — `WidgetPgiReport` có code, không có PRD

| Trường | Giá trị |
|--------|--------|
| Status | `OPEN` |
| Source code | `frontend/src/features/dashboard/components/widgets/pgi-report/widget-pgi-report.tsx` |
| i18n key | `pgiReport.header.title` = "ORDER STATISTICS", `pgiReport.salesChannel.title` = "ORDER STATISTICS BY SALES CHANNEL" |
| Doc | KHÔNG có folder `01-sections/pgi-report/` |
| Phán đoán | Widget mới được dev hoặc inherit từ tenant khác (chưa map vào dashboard Mondelez). |
| Action | BA xác nhận với khách: PGI Report có nằm trong scope Mondelez không? → Nếu có, viết PRD. Nếu không, đánh dấu deprecated/không hiển thị cho tenant Mondelez. |

---

## DISC-006 — `commit-response-rate` chỉ có ở `05-reference/`, chưa có folder mới

| Trường | Giá trị |
|--------|--------|
| Status | `OPEN` |
| Source doc | [`05-reference/[done] ty_le_lap_day_xe_van_hanh_gui_thau/commit-response-rate.prd.md`](../05-reference/[done]%20ty_le_lap_day_xe_van_hanh_gui_thau/commit-response-rate.prd.md) |
| Tình trạng | KPI "Commit Response Rate" đã được mô tả trong reference cũ; không có folder ở `01-sections/`; không rõ widget code |
| Phán đoán | Có thể đã merge vào `tender-response/` hoặc bị drop khỏi scope. |
| Action | BA confirm với khách: KPI này còn cần không → tạo `01-sections/commit-response-rate/` HOẶC bổ sung vào `tender-response/prd.md` như 1 metric thứ 2. |

---

## DISC-007 — Mondelez warehouse VN821/VN831 trả 0 rows trong loose-picking

| Trường | Giá trị |
|--------|--------|
| Status | `OPEN` (BUG-2 trong PRD gốc) |
| Source doc | [`05-reference/[done] loose-picking/loose-picking.prd.md:123`](../05-reference/[done]%20loose-picking/loose-picking.prd.md) |
| Tình trạng | `mv_loose_picking` không trả data cho 2 kho 3PL `VN821`, `VN831` |
| Phán đoán | Hoặc data 3PL chưa sync vào ClickHouse, hoặc filter trong MV loại bỏ nhầm. |
| Action | DEV check filter logic trong DDL `mv_loose_picking`. DA verify nguồn data 3PL. |

---

## DISC-008 — Glossary stub cũ tại `02-data/glossary.md` rỗng

| Trường | Giá trị |
|--------|--------|
| Status | `RESOLVED` (file này thay thế) |
| Source doc | `02-data/glossary.md` (chỉ có header + bảng rỗng) |
| Action | File `02-data/glossary.md` được update thành 1 redirect note trỏ về `glossary/`. |

---

## Quy trình xử lý 1 discrepancy

1. **BA review** mỗi sprint planning: đọc file này, gọi DEV/DA xác nhận.
2. **Update PRD/spec** nếu code đúng, doc sai → BA sửa doc.
3. **Update code/MV** nếu doc đúng, code lệch → DEV fix code.
4. **Đánh dấu `RESOLVED`** + ngày + người resolve.
5. **Sau 1 sprint** entry `RESOLVED` có thể delete khỏi file này.
