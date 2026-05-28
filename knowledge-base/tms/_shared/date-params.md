# TMS — Tham số ngày

Các tham số điều khiển khoảng thời gian khi export report.

## `TypeDateRange`

| Giá trị | Ý nghĩa |
|---|---|
| `3` | Khoảng ngày **tùy chọn** — dùng `dtfrom` / `dtto` ở envelope (giá trị quan sát ở #25) |

> Các giá trị khác (hôm nay, tuần này, tháng này…) chưa đối chiếu — bổ sung khi gặp.

## `TypeOfDate` (loại ngày lọc)

Chọn mốc ngày để áp khoảng `from–to`. Nhãn nghiệp vụ (theo hồ sơ #25):

| Nhãn | Field áp dụng |
|---|---|
| ETD đơn hàng | `[ETD]` |
| ETA đơn hàng | `[ETA]` |
| ATD chuyến | `[MasterATD]` |
| ATA chuyến | `[MasterATA]` |

> `TypeOfDate` là enum **số**; payload mẫu #25 dùng `9`. Bản đồ số↔nhãn **chưa xác nhận** — cần đối chiếu thêm với UI/spec TMS trước khi tự suy.

## `dtfrom` / `dtto` (envelope)

- Kiểu ISO UTC (`...Z`). **`17:00Z` = `00:00 +07`** (giờ VN).
- Quy ước cửa sổ local `[S, E]` (bao gồm 2 đầu):
  - `dtfrom` = `(S − 1 ngày)` lúc `17:00:00.000Z`
  - `dtto`   = `E` lúc `17:00:00.000Z`
- Ví dụ #25: `dtfrom=2026-05-22T17:00Z`, `dtto=2026-05-26T17:00Z` → local **23→26/05/2026**.

## Định dạng hiển thị ngày

`dd/MM/yyyy HH:mm`.
