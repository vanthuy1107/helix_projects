# 02 — KPIs (định nghĩa & công thức)

Mỗi KPI có: tên TV, tên EN, công thức, nguồn dữ liệu, ngưỡng màu sắc (nếu có).

> Khi BA viết PRD, copy y nguyên công thức từ đây. Khi DEV implement query, đối chiếu công thức từ đây để verify.

---

## OTIF Family — `WidgetOTIF` / `mv_otif`

Nguồn định nghĩa: [`01-sections/otif/prd.md`](../01-sections/otif/prd.md)

| KPI | Tên đầy đủ | Công thức | Đơn vị |
|-----|-----------|-----------|--------|
| `% Ontime` | On-time rate | `COUNT(Ontime DO) / COUNT(DO) × 100` | % |
| `% Infull` | In-full rate | `COUNT(Infull DO) / COUNT(DO) × 100` | % |
| `% OTIF` | OTIF rate | `COUNT(OTIF DO) / COUNT(DO) × 100` | % |
| `Tổng đơn` | Total DO | `COUNT(DISTINCT DO)` | đơn |

**Định nghĩa Ontime / Infull / OTIF:**
- **Ontime** ⇔ `ATA ≤ ETA`
- **Infull** ⇔ `planned_cse = shipped_cse = delivered_cse` (sau khi `round(toFloat64(x), 4)` để tránh false-positive precision)
- **OTIF** ⇔ `Ontime AND Infull`
- **No STM data** ⇔ `has_stm_order = 0` — ngoại lệ, không tính vào tử số nhưng có thể tính tổng

**Ngưỡng màu sắc % OTIF:**
- 🟢 Pass: `≥ 90%`
- 🟡 Warning: `80% – 89%`
- 🔴 Critical: `< 80%`

**Date Type filter (BA phải nói rõ default nào):**
- `'ETA gửi thầu'` (mặc định) — lọc theo ETA tender
- `'ATA chi tiết chuyến'` — lọc theo ATA actual
- Max date range: 2 năm

**Phân loại nguyên nhân fail Ontime** (5 categories): Lỗi transport giao trễ / Lỗi warehouse gọi trễ / Lỗi transport vào kho trễ / Lỗi rớt warehouse / Lỗi rớt transport.

**Phân loại nguyên nhân fail Infull** (3 categories): Warehouse / Transport / Cả hai.

---

## VFR (Vehicle Fill Rate) — `WidgetVFR`

Nguồn: [`05-reference/[done] vfr/vfr.prd.md`](../05-reference/[done]%20vfr/vfr.prd.md)

| KPI | Công thức | Đơn vị |
|-----|-----------|--------|
| `VFR Tấn` | `Tấn chở / Tấn đăng ký × 100%` | % |
| `VFR Khối` | `Khối chở / Khối đăng ký × 100%` | % |
| `VFR Max` | `MAX(VFR Tấn, VFR Khối)` | % |

**VFR Buckets (phân nhóm hiệu suất):**
- `< 50%` (under-utilized)
- `50% – 70%`
- `70% – 95%`
- `≥ 95%` (full)

**Hai lăng kính (lens):**
- **Tender lens:** group by `TenderMasterID` → MV `mv_vfr_gui_thau`
- **Operational lens:** group by `MasterCode` → MV `mv_vfr_van_hanh`

**Capacity source:** `Ton` lấy từ danh mục loại xe (registered tonnage), KHÔNG phải tải thực.

---

## Loose Picking — `WidgetLoosePicking` / `mv_loose_picking`

Nguồn: [`05-reference/[done] loose-picking/loose-picking.prd.md`](../05-reference/[done]%20loose-picking/loose-picking.prd.md)

| KPI | Công thức |
|-----|-----------|
| `% Loose` | `SUM(cse_loose) / SUM(cse_full + cse_loose) × 100` |
| `cse_per_pallet` | `masterunit_per_pallet / masterunit_per_cse` |

**Ngưỡng màu sắc % Loose** (đảo: thấp = tốt):
- 🟢 Good: `< 30%`
- 🟡 Warning: `30% – 40%`
- 🔴 Bad: `> 40%`

**Scope filter:** chỉ trip đã hoàn tất → `orders.status_code = '95'` (= ShipCompleted).

---

## Shipping Progress / Flash Daily — `WidgetFlashDaily`

Nguồn: [`05-reference/[done] flash_report/flash-daily-report.prd.md`](../05-reference/[done]%20flash_report/flash-daily-report.prd.md)

| KPI | Công thức |
|-----|-----------|
| `Total DO` | `COUNT(DISTINCT do)` |
| `Đơn xuất` | `COUNT(DISTINCT so)` với status ∈ {Đã xuất kho, Đang vận chuyển, Đã vận chuyển} |
| `Đơn pending` | `COUNT(DISTINCT so)` với status ∈ {Chưa xuất kho, Đang xuất kho} |
| `% Xuất` | `(Đơn xuất / Total DO) × 100` |

**5-card layout:** CBM / Tấn / Đơn / Chuyến / % Xuất.

---

## Late Order Alert — `WidgetLateOrderAlert` / `mv_alert_late_do`

Nguồn: [`05-reference/[done] canh_bao_don_tre/late-order-alert.prd.md`](../05-reference/[done]%20canh_bao_don_tre/late-order-alert.prd.md)

KPI = count theo 7 trạng thái + 1 tổng (xem `04-status-enums.md` cho định nghĩa từng trạng thái).

| KPI | Công thức |
|-----|-----------|
| `Tất cả` | `COUNT(DISTINCT so_chuyen)` toàn bộ trip |
| 7 status counts | xem `04-status-enums.md` |

**Real-time calculation:** dùng `now64()` so với `tg_bat_buoc_roi_kho`. **At-risk window:** mặc định **45 phút** trước deadline.

**ATD definition:** dùng `gio_ra_cong` (ra cổng từ dock register), KHÔNG phải `atd_chuyen`.

---

## Stock Type — `WidgetStockType` / `mv_stocktype`

Nguồn: [`05-reference/[done] stock-type/stock-type.prd.md`](../05-reference/[done]%20stock-type/stock-type.prd.md)

| KPI | Công thức |
|-----|-----------|
| `Total Inv CSE` | tổng tồn kho theo Case |
| `Total Inv PLT` | tổng tồn kho theo Pallet |
| `Available` | `qty − allocated − picked` |

**Scope filter:** `storer_key = 'MDLZ'` (chỉ Mondelez, không multi-tenant trong MV này).
**Snapshot pattern:** không có time dimension, refresh 1h.

---

## Transaction Move — `WidgetTxnMove` / `mv_movement_transaction`

| KPI | Mô tả |
|-----|------|
| `Total Volume Inbound` | tổng thể tích nhập |
| `Total Volume Outbound` | tổng thể tích xuất |
| `Print DO` | số đơn đã in |

---

## Tender Response Rate — `WidgetTenderResponse`

| KPI | Công thức (đề xuất, cần BA xác nhận) |
|-----|-------------------------------------|
| `% Tender Response` | `(Số chuyến NVC nhận thầu / Tổng chuyến gửi thầu) × 100` |
| `% Commit Response` | `(Số chuyến NVC commit / Tổng chuyến gửi thầu) × 100` |

⚠️ Folder `commit-response-rate` đã có ở `05-reference/`, chưa có version mới ở `01-sections/`. Nếu Mondelez yêu cầu cả 2 KPI → BA cần làm rõ.

---

## Quy ước về số liệu

- **Divide-by-zero:** SQL `if(total=0, 0, ...)` — UI fallback `NULL → 0%`.
- **CSE rounding:** dùng `round(toFloat64(x), 4)` để tránh false positive khi so sánh CSE (chứ không so trực tiếp).
- **Snake_case ↔ camelCase:** ClickHouse trả `snake_case`, UI nhận `camelCase` — mapping ở [`01-sections/otif/spec.md:150`](../01-sections/otif/spec.md).
