# 04 — Status & Enums

Tất cả giá trị trạng thái xuất hiện trong widgets, kèm điều kiện xác định và màu hex thống nhất giữa BA wireframe và FE component.

> Khi BA mô tả "đơn ở trạng thái X" trong PRD, dùng đúng tên ở đây. Khi DEV implement filter/legend, dùng đúng hex color ở đây.

---

## OTIF Status (`WidgetOTIF`)

| Status | Tiếng Việt | Điều kiện SQL | Notes |
|--------|-----------|--------------|------|
| `Ontime` | Đúng hạn | `ATA ≤ ETA` | |
| `Failed Ontime` | Trễ hạn | `ATA > ETA` | |
| `Infull` | Đủ số lượng | `planned_cse = shipped_cse = delivered_cse` (sau round) | |
| `Failed Infull` | Không đủ | chênh trên 3 cột CSE | |
| `OTIF` | Đạt OTIF | `Ontime AND Infull` | |
| `Failed OTIF` | Fail OTIF | `Failed Ontime OR Failed Infull` | |
| `Không có dữ liệu STM` | No STM data | `has_stm_order = 0` | exclude khỏi % calc |

---

## Late Order Alert (`WidgetLateOrderAlert`) — 7 trạng thái

Phân thành 2 nhóm: **Real-time** (chuyến chưa hoàn tất) + **Historical** (chuyến đã có actual data).

### Nhóm Real-time

| Status | Tiếng Việt | Hex | Điều kiện |
|--------|-----------|-----|----------|
| `Normal` | Bình thường | 🟢 `#10B981` | Chưa rời kho, còn `> 45 phút` đến deadline |
| `At risk` | Sắp trễ | 🟡 `#F59E0B` | Chưa rời kho, còn `0–45 phút` đến deadline |
| `Late departure open` | Đã trễ deadline (chưa rời) | 🔴 `#EF4444` | Chưa rời kho, đã quá deadline (`now > tg_bat_buoc_roi_kho`) |

### Nhóm Historical

| Status | Tiếng Việt | Hex | Điều kiện |
|--------|-----------|-----|----------|
| `Late departure` | Trễ giờ rời kho | 🔴 `#DC2626` | `gio_ra_cong NOT NULL` AND `gio_ra_cong ≥ tg_bat_buoc_roi_kho` |
| `Ontime departure` | Đúng giờ rời kho | 🟢 `#22C55E` | `gio_ra_cong NOT NULL` AND `gio_ra_cong < tg_bat_buoc_roi_kho` |
| `Late delivery` | Trễ giao hàng | 🔴 `#F87171` | `ata_roi NOT NULL` AND có line trễ vs ETA |
| `Ontime delivery` | Đúng giờ giao hàng | 🟢 `#14B8A6` | `ata_roi NOT NULL` AND tất cả line đúng hạn |

### Card layout

8-card UI: 1 card "Tất cả" (tổng) + 7 card status.

---

## Flash Daily Report (`WidgetFlashDaily`) — 5 status

Mapping từ SWM/STM status → display status. Dùng làm legend stacked bar chart.

| Status hiển thị | Tiếng Anh | Hex | Điều kiện |
|----------------|-----------|-----|----------|
| `Đã vận chuyển` | Delivered | 🟢 `#287819` | `swm_status = 'ShipCompleted'` AND (STM giao xong hoặc `stm_ata_den IS NOT NULL`) |
| `Đang vận chuyển` | In Transit | 🔵 `#2D6EAA` | `swm_status = 'ShipCompleted'` AND `stm_thoi_gian_di IS NOT NULL` |
| `Đã xuất kho` | Shipped | 🟣 `#4F2170` | `swm_status = 'ShipCompleted'` (default — chưa có STM signal) |
| `Đang xuất kho` | Shipping | 🟠 `#E18719` | `swm_status ∈ {PartAllocate, Allocated, PartPick, Picked, PartShipped}` |
| `Chưa xuất kho` | Not Shipped | ⚪ `#858585` | `swm_status = 'New'` |

---

## SWM (WMS) Order Status — raw enum

Source enum từ hệ thống SWM. DEV phải biết raw value vì query lọc/group dùng các giá trị này.

| Raw value | Display | Stage |
|-----------|---------|-------|
| `New` | Đơn mới | Trước picking |
| `PartAllocate` | Phân bổ một phần | Allocation |
| `Allocated` | Đã phân bổ | Allocation done |
| `PartPick` | Pick một phần | Picking |
| `Picked` | Đã pick | Picking done |
| `PartShipped` | Ship một phần | Shipping |
| `ShipCompleted` | Đã xuất kho | Shipping done — `status_code = '95'` |

⚠️ Loose Picking widget filter: `status_code = '95'` ⇔ `ShipCompleted`.

---

## STM (TMS) Order Status — raw enum

Source enum từ STM (lưu ý là **tiếng Việt** trong DB).

| Raw value (DB) | Tiếng Anh | Stage |
|----------------|-----------|-------|
| `Đã giao hàng` | Delivered | Done |
| `Nhận 1 phần chứng từ` | Partial receipt | POD partial |
| `Đã nhận chứng từ` | Receipt complete | POD complete |

---

## Convention chung

- **Tên status TV** → dùng trong UI nội bộ tiếng Việt (legend, filter).
- **Tên status EN** → dùng trong code (TS enum, MV column comment, log).
- **Hex color** → cố định, không tự đổi. Nếu cần đổi, BA + UX + DEV thống nhất rồi update vào file này.
- **Mapping ngưỡng KPI** (🟢🟡🔴) — xem `02-kpis.md`, không phải status enum mà là threshold-based.
