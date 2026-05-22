# WIREFRAME — Late Order Alert

| Trường | Giá trị |
|--------|---------|
| **Version** | 1.0.0 |
| **Ngày** | 2026-05-19 |
| **Trạng thái** | Observed baseline — ASCII rendering theo implementation hiện hành |
| **PRD reference** | [late-order-alert-prd.md](late-order-alert-prd.md) |
| **Spec reference** | [late-order-alert-spec.md](late-order-alert-spec.md) |
| **Source code** | [`frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx`](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx) |

---

## 1. Toolbar (edit mode only)

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [⚙ Setting Chart]   [🎚 Setting Filter]                                    │
└────────────────────────────────────────────────────────────────────────────┘
```
- `Setting Chart` (outline) → mở SqlSettingsDialog 2 tab: Scorecard, Detail.
- `Setting Filter` (ghost amber chip) → mở SqlFilterPanel settings.

---

## 2. Filter bar (sticky, autoApply)

```
┌────────────────────────────────────────────────────────────────────────────┐
│ Bộ lọc Late Order Alert                                                    │
│ ┌──────────┬──────────────┬──────────────┬──────────┬──────────┬─────────┐ │
│ │ Kho      │ Khu vực giao │ Sales Channel│ NVT      │ Loại ngày│ Ngày    │ │
│ │ [▼ ALL ] │ [▼ ALL ]     │ [▼ ALL ]     │ [▼ ALL ] │ [▼ Ngày  │ [📅 from│ │
│ │ multi    │ multi        │ multi        │ multi    │  gửi thầu│ → to]   │ │
│ └──────────┴──────────────┴──────────────┴──────────┴──────────┴─────────┘ │
│ Auto-apply (KHÔNG có nút Apply) · Reset                                    │
└────────────────────────────────────────────────────────────────────────────┘
```

- 4 multi-select chips: `whseid`, `region`, `group_name`, `transporter` — default ALL.
- 1 single-select: `dateType` — default `Ngày gửi thầu`, 2 options.
- 1 date range: default `today → today`, hard-limit 2 năm.

---

## 3. Tabs

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [ Chart ]   [ Chi tiết bảng ]                                              │
└────────────────────────────────────────────────────────────────────────────┘
```

Tabs full-width, mỗi tab flex-1. Default active = `chart`.

---

## 4. Tab: Chart

### 4.1 KPI Cards row (1 lớn + 7 nhỏ chia 3 group)

```
┌────────────────────────────────────────────────────────────────────────────┐
│ ┌────────────┐  ┌───────────────────────────────────────────────────────┐  │
│ │  🎯 Tổng   │  │ ━ CHUYẾN TRONG KHO, CHƯA RỜI KHO ━━━━━━━━━━━━━━━━━━━ │  │
│ │  chuyến    │  │ ┌──────────┬──────────────┬──────────────────────┐    │  │
│ │            │  │ │🕐 Normal │ ⚠ At risk   │ ⚠ Late dep open      │    │  │
│ │  12,345    │  │ │   8,200  │     350     │       120            │    │  │
│ │            │  │ │  emerald │   amber     │     red              │    │  │
│ │  Tổng số   │  │ └──────────┴──────────────┴──────────────────────┘    │  │
│ │  chuyến    │  ├───────────────────────────────────────────────────────┤  │
│ │            │  │ ━ CHUYẾN TRÊN ĐƯỜNG GIAO ━━━━━━━━━━━━━━━━━━━━━━━━━━ │  │
│ │ (w-44)     │  │ ┌────────────────────┬────────────────────────────┐  │  │
│ │ large      │  │ │🚚 Late departure   │ 🚚 Ontime departure        │  │  │
│ │ variant    │  │ │     450            │      2,100                 │  │  │
│ │            │  │ │     pink           │       sky                  │  │  │
│ │            │  │ └────────────────────┴────────────────────────────┘  │  │
│ │            │  ├───────────────────────────────────────────────────────┤  │
│ │            │  │ ━ CHUYẾN ĐÃ GIAO THÀNH CÔNG ÍT NHẤT 1 ĐƠN ━━━━━━━━ │  │
│ │            │  │ ┌────────────────────┬────────────────────────────┐  │  │
│ │            │  │ │🚚 Ontime delivery  │ ⚠ Late delivery            │  │  │
│ │            │  │ │     1,000          │      125                   │  │  │
│ │            │  │ │     emerald-dark   │     rose                   │  │  │
│ │            │  │ └────────────────────┴────────────────────────────┘  │  │
│ └────────────┘  └───────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
```

**Layout properties**:
- Mỗi card: `linear-gradient(135deg, color26, color0D)` background, border 0.5px top accent.
- Số values formatted `toLocaleString()` (vd `12,345`).
- Mỗi card có icon trái + label trên + value lớn + desc nhỏ + (?) hint tooltip phải.
- 3 groups bao quanh bằng `bg-muted/20 border border-dashed`.

### 4.2 Chart 1: Breakdown trạng thái cảnh báo (Donut)

```
┌──── Breakdown trạng thái cảnh báo ────────────────────── (?) [⤓ Export] ───┐
│                                                                            │
│        ┌──────────────────┐         ┌──────────────────────────┐           │
│        │                  │         │ ▮ Bình thường    8,200   │           │
│        │      ╱─╲         │         │ ▮ Sắp trễ          350   │           │
│        │     │   │        │         │ ▮ Trễ rời kho      120   │           │
│        │     │ ◯ │        │         │   (chưa rời)             │           │
│        │     │   │        │         │ ▮ Trễ rời kho      450   │           │
│        │      ╲─╱         │         │ ▮ Đúng hạn rời   2,100   │           │
│        │   (innerR 62,    │         │ ▮ Giao đúng hạn  1,000   │           │
│        │    outerR 105)   │         │ ▮ Trễ giao         125   │           │
│        │                  │         │                          │           │
│        └──────────────────┘         └──────────────────────────┘           │
│   col xl: 1fr (donut)    │      col xl: 220px (legend strip)               │
└────────────────────────────────────────────────────────────────────────────┘
```

- 7 segments với màu theo `STATUS_COLORS`, thứ tự `BREAKDOWN_STATUS_ORDER`.
- Legend strip bên phải LUÔN hiển thị đủ 7 entries (kể cả value = 0).
- Tooltip: `{count} - {statusLabel}` với label đã i18n.

### 4.3 Chart 2: Cảnh báo theo nhà vận tải (Stacked Bar)

```
┌── Cảnh báo tình trạng đơn hàng theo nhà vận tải ─────── (?) [⤓ Export] ───┐
│                                                                            │
│  ▮Bình thường ▮Sắp trễ ▮Trễ rời (chưa rời) ▮Trễ rời ▮Đúng hạn rời  ...    │
│                                                                            │
│  count                                                                     │
│   ▲                                                                        │
│ 2000┤                                                                      │
│     │       ┌──┐                                                           │
│ 1500┤       │  │  ┌──┐                                                     │
│     │   ┌──┐│  │  │  │                                                     │
│ 1000┤   │  ││  │  │  │  ┌──┐                                               │
│     │   │  ││  │  │  │  │  │  ┌──┐                                         │
│  500┤   │  ││  │  │  │  │  │  │  │                                         │
│     │   │▮▮││▮▮│  │▮▮│  │▮▮│  │▮▮│                                         │
│   0 ┼───┴──┴┴──┴──┴──┴──┴──┴──┴──┴────────────────────────────────────► X │
│        NVT1  NVT2 NVT3 NVT4 NVT5 ...                                       │
│                  (sort by total desc)                                      │
└────────────────────────────────────────────────────────────────────────────┘
```

- 7 stacked bar series cho 7 alert status (color theo `STATUS_COLORS`).
- X axis: transporter name (empty → fallback `Không xác định`).
- Sort: total chuyến desc.
- LabelList trên mỗi segment hiển thị count number.
- Custom Tooltip (`TransporterBreakdownTooltip`): khi hover hiện full breakdown 7 statuses cho transporter đó.
- Height: 320px.

---

## 5. Tab: Chi tiết bảng

```
┌────────────────────────────────────────────────────────────────────────────┐
│ Chi tiết cảnh báo đơn trễ                                  [⤓ Export CSV] │
├────────────────────────────────────────────────────────────────────────────┤
│ Filter cột: trip [____] doCode [____] tripStatus [▼ multi] alert [▼ multi]│
│             warehouse [▼ multi] deliveryArea [▼ multi] ...                 │
├────────────────────────────────────────────────────────────────────────────┤
│ Trip       │ Mã DO   │Tr.Thái│ TG bắt buộc │ Cảnh báo │ Kho │ Khu vực│NVT │
│            │         │chuyến │ rời kho     │          │     │ giao   │    │
├────────────┼─────────┼───────┼─────────────┼──────────┼─────┼────────┼────┤
│ T001 [Mới] │ DO-12345│ HD    │ 14:30 19/05 │[Late dep │BKD1 │ HCM    │NVT │
│      trễ ▮ │         │       │             │ open ▮]  │     │        │ 1  │
├────────────┼─────────┼───────┼─────────────┼──────────┼─────┼────────┼────┤
│ T002 [Mới  │ DO-67890│ HD    │ 15:00 19/05 │[At risk ▮│BKD2 │ DNG    │NVT │
│  nguy cơ ⚠]│         │       │             │ amber]   │     │        │ 2  │
├────────────┼─────────┼───────┼─────────────┼──────────┼─────┼────────┼────┤
│ T003       │ DO-...  │ HD    │ 12:00 19/05 │[Normal ▮]│NKD  │ HN     │NVT │
│            │         │       │             │  emerald │     │        │ 3  │
├────────────┼─────────┼───────┼─────────────┼──────────┼─────┼────────┼────┤
│  ...                                                                       │
├────────────────────────────────────────────────────────────────────────────┤
│ < Prev   Page 1 / 5   Next >        Show 20 per page                       │
└────────────────────────────────────────────────────────────────────────────┘
```

**Visible-by-default columns** (11): Trip | DO | Tr.Thái chuyến | TG bắt buộc rời kho | Cảnh báo | Kho | Khu vực giao | NVT | ATD thực tế | ETA | Kênh bán hàng.

**Default-hidden columns** (~50): identity (customer/đối tác), time fields (đăng tài / gọi xe / vào cổng / dock / Actual Ship / ata den / ata roi / ...), vehicle (số xe / tài xế / mã nhà xe), quantities × 5 UOM × 4 groups (original/shipped/delivered/diff), durations (TG trong kho / TG load / chênh lệch / phút trễ), distance (số KM / vận tốc).

**Trip badges**:
- `Mới nguy cơ trễ` (badge amber bg, 9px) — khi `alert = At risk`
- `Mới trễ` (badge rose bg, 9px) — khi `alert = Late departure open`

**Alert chip rendering** (cột `alert`):
- `Late departure open` → bg-rose-500/20, text-rose-700
- `At risk` → bg-amber-400/20, text-amber-700
- Còn lại → bg-emerald-500/15, text-emerald-700

**Page size**: 20 rows (`WidgetGrid` prop `pageSize=20`).

**Sort default**: Theo alert priority asc (Late dep open → Late dep → Late delivery → At risk → Normal → Ontime dep → Ontime delivery), tie-breaker = trip alphabetical.

---

## 6. Loading state (initial)

```
┌────────────────────────────────────────────────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← Skeleton h-12 (filter strip)
├────────────────────────────────────────────────────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐    │
│ │ ▓▓▓▓ │ │ ▓▓▓▓ │ │ ▓▓▓▓ │ │ ▓▓▓▓ │ │ ▓▓▓▓ │ │ ▓▓▓▓ │ │ ▓▓▓▓ │ │ ▓▓▓▓ │   │  ← 8 skeleton h-[72px]
│ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘    │
├────────────────────────────────────────────────────────────────────────────┤
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← Skeleton (chart area)
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
└────────────────────────────────────────────────────────────────────────────┘
```

Chỉ render khi `isLoading && !hasLoadedData`. Sau lần load đầu, `placeholderData=prev` giữ data cũ khi refetch.

---

## 7. Error state (initial)

```
┌────────────────────────────────────────────────────────────────────────────┐
│ ⚠  Error: <message từ scorecardError>                                      │
└────────────────────────────────────────────────────────────────────────────┘
```

Inline box màu destructive, border-destructive/30, bg-destructive/10. Chỉ hiện khi `error && !hasLoadedData`.

---

## 8. Responsive behavior

- **xl+ (≥1280px)**: Donut chart + legend strip layout 2 cột (`grid-cols-[1fr_220px]`).
- **< xl**: Donut chart + legend strip stack vertical (`grid-cols-1`).
- KPI cards row: Card lớn `w-44 shrink-0` + container nhỏ `flex-1 min-w-0` — luôn responsive vì group 1/2/3 dùng `grid-cols-3 / 2 / 2`.

---

## 9. Empty state behavior

Không có message rõ "Không có dữ liệu":
- KPI cards: hiển thị `0` (hoặc `ZERO_SCORECARD`)
- Donut chart: vẫn render 7 segment với value 0 → invisible (no visible arc)
- Bar chart: render empty (no bars)
- Bảng: hiển thị header + dòng "no data" (do `WidgetGrid`)

> ⚠ Có thể coi đây là gap cho v1.1 — cần Empty State component thống nhất với "No trips match current filter".

---

## 10. Lịch sử thay đổi

| Version | Ngày | Tác giả | Thay đổi |
|---------|------|---------|---------|
| 1.0.0 | 2026-05-19 | PM/DA via `/da-trace` | Bản đầu tiên — ASCII wireframe theo implementation hiện hành. Cover: toolbar (2 buttons), filter bar (6 fields), 2 tabs (chart + table), KPI cards (1 lớn + 7 nhỏ × 3 group), 2 charts (donut + transporter stacked bar), detail table (11 visible + ~50 hidden cols, page 20, sort alert priority), loading/error/empty states. |
