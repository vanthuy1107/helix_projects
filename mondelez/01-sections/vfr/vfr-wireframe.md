# ASCII Wireframe — VFR widget

**Tenant:** Mondelez
**Source:** [widget-vfr.tsx](frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx)
**Last updated:** 2026-05-19

> Đây là ASCII của UI thật trên branch `feat-vfr-late-alert` — KHÔNG phải wireframe đề xuất. Mục đích: stakeholder nhìn nhanh layout final khi review PRD.

---

## 0. Container

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│                                  Widget VFR                                        │
│  (toolbar actions chỉ hiện khi editMode=true: [Setting Chart] [Setting Filter])   │
└────────────────────────────────────────────────────────────────────────────────────┘
```

Edit-mode toolbar (right-side, attached to widget header):

```
                                                          ┌────────────────┐ ┌──────────────────┐
                                                          │ ⚙ Setting Chart│ │ ☰ Setting Filter │
                                                          └────────────────┘ └──────────────────┘
```

---

## 1. Filter panel (SqlFilterPanel)

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│  VFR Filters                                              [Apply]  [Reset] [✎ Cfg] │
├────────────────────────────────────────────────────────────────────────────────────┤
│  Pickup Warehouse:  [Kho trong - NKD ▾]   [Kho ngoài - BKD ▾]   ...   (multi)     │
│  Khu vực giao hàng: [South East ▾]        [Ho Chi Minh ▾]       ...   (multi)     │
│  Vendor / Carrier:  [NGUYEN PHAT ▾]       [NINJAVAN ▾]          ...   (multi)     │
│  Date Type:         (•) ETA   ( ) ATA                                              │
│  Date range:        From [2026-05-01]  To [2026-05-19]                            │
│  Loại xe gửi thầu:  [4T ▾] [8T ▾] ... (multi)         ← disabled when mode = VH    │
│  Loại xe vận hành:  [4T ▾] [8T ▾] ... (multi)         ← disabled when mode = GT    │
└────────────────────────────────────────────────────────────────────────────────────┘
```

> autoApply=true → mọi thay đổi field tự fire `handleFilterApply`. Reset đưa state về `[ALL]`/`ETA`/`startOfMonth..today`.

---

## 2. Mode toggle (between filter panel and chart tabs)

```
   Mode  [ VFR theo Chuyến thầu ]  [ VFR theo Chuyến vận hành ]
          ▲ active = mode === 'tender'   ▲ active = mode === 'operation'
```

---

## 3. Tab bar

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│  [ Chart ]                                  [ Detail ]                             │
└────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Tab "Chart" — KPI cards row (5 cards)

```
┌─────────────────┬─────────────────┬─────────────────┬─────────────────┬─────────────────┐
│ ▲ Avg VFR       │ 🚚 Thấp <50%   │ 🚚 TB 50–70%   │ 🚚 Cao 70–95%  │ 🚚 Xuất sắc ≥95│
│                 │                 │                 │                 │                 │
│   72.40%        │   38            │   125           │   612           │   84            │
│                 │                 │                 │                 │                 │
│ Giá trị trung   │ Nhóm cần cải    │ Nhóm trung bình │ Nhóm hiệu suất  │ Nhóm tối ưu     │
│ bình trên trips │ thiện           │                 │ tốt             │                 │
│ [tím]           │ [đỏ]            │ [vàng]          │ [xanh dương]    │ [xanh lá]       │
└─────────────────┴─────────────────┴─────────────────┴─────────────────┴─────────────────┘
         ▲ mỗi card có icon `?` (tooltip công thức) ở góc phải khi hover
```

Responsive: `grid-cols-2 xl:grid-cols-5` — mobile/laptop nhỏ xếp 2 cột, desktop ≥1280px xếp 5 cột.

---

## 5. Tab "Chart" — 3 chart cards (grid 2 cột trên xl)

### 5.1 Chart 1 — VFR theo Khu vực (ComposedChart Bar + Line)

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│  VFR {gửi thầu | vận hành} theo Khu vực                                      [?] [⬇]│
├────────────────────────────────────────────────────────────────────────────────────┤
│  10k │██                                                              100%  │
│      │██   ██                                                          80%  │
│      │██   ██   ██                                          ●─────●   60%  │
│   5k │██   ██   ██   ██   ██               ●──────●─────●           40%   │
│      │██   ██   ██   ██   ██   ██   ●─────●                          20%  │
│      └────────────────────────────────────────────────────────────  0%    │
│       South East  HCM   Mekong 1  Ha Noi   North East   Mekong 2          │
│                                                                            │
│  ██ Registered CBM (left axis)    ● VFR % (right axis, tím #8E59FF)       │
└────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Chart 2 — VFR theo Loại xe (ComposedChart Bar + Line)

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│  VFR {gửi thầu | vận hành} theo loại xe                                      [?] [⬇]│
├────────────────────────────────────────────────────────────────────────────────────┤
│   8k │█▒                                                              100%  │
│      │█▒    █▒                                                         80%  │
│      │█▒    █▒    █▒                                       ●──────●    60%  │
│   4k │█▒    █▒    █▒    █▒    █▒              ●──────●                40%  │
│      │█▒    █▒    █▒    █▒    █▒    █▒    ●                          20%  │
│      └────────────────────────────────────────────────────────────  0%    │
│        2T    4T    8T   15T   24T   Cont                                   │
│                                                                            │
│  █▒ Registered CBM (left axis, #0EA5E9)   ● VFR % (right axis, tím)       │
└────────────────────────────────────────────────────────────────────────────┘
       ▲ X-axis = vehicle_type_tender (mode GT) hoặc vehicle_type_ops (mode VH)
```

### 5.3 Chart 3 — VFR theo Loại bốc xếp & Thời gian (multi-series ComposedChart)

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│  VFR {gửi thầu | vận hành} theo loại bốc xếp        [Ngày|Tuần|Tháng] [?] [⬇]   │
├────────────────────────────────────────────────────────────────────────────────────┤
│   5k │█▒                                                              100%  │
│      │█▒  ░░                                                ●         80%  │
│      │█▒  ░░  █▒                                  ●──────●          60%  │
│   2k │█▒  ░░  █▒  ░░  █▒                ●──────●                    40%  │
│      │█▒  ░░  █▒  ░░  █▒  ░░                                         20%  │
│      └────────────────────────────────────────────────────────────  0%    │
│       2026-03  2026-04  2026-05                                            │
│                                                                            │
│  █▒ Loose - planned   ░░ Box pallet - planned   ● Loose VFR%   ◇ Box pallet VFR% │
│  Ghi chú: Bar `Other`/`Full Pallet` bị ẩn — chỉ render line                       │
└────────────────────────────────────────────────────────────────────────────┘
```

Group-by toggle (top-right của chart):
```
   ┌─────────┬─────────┬─────────┐
   │  Ngày   │  Tuần   │ ► Tháng │   ← default = Tháng (highlighted teal)
   └─────────┴─────────┴─────────┘
```

---

## 6. Tab "Detail" — 2 thành phần

### 6.1 Detail grid (WidgetGrid, gridKey DSHVFRDTG01)

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│  Layers Chi tiết bảng                                  🚚📈 Góc nhìn {thầu|vận hành}│
├────────────────────────────────────────────────────────────────────────────────────┤
│  [Filter row — text + multiselect per col]            [Export ▾] [10 | 20 | 50]    │
├────┬───────────┬─────────────┬───────┬───────────┬─────────────┬───────┬──────────┤
│Trip│ Mã chuyến │ Mã đơn hàng │ Dịch  │ Trạng thái│ Tg gửi thầu │ ETA   │ ATA  ... │
├────┼───────────┼─────────────┼───────┼───────────┼─────────────┼───────┼──────────┤
│DI..│ M1730000  │ ORD-001..   │ Xuất  │ Hoàn thành│ 2026-05-01  │ 2026..│ 2026.. ..│
│DI..│ M1730001  │ ORD-002..   │ Xuất  │ Hoàn thành│ 2026-05-01  │ 2026..│ 2026.. ..│
│DI..│ M1730002  │ ORD-003..   │ Xuất  │ Hoàn thành│ 2026-05-02  │ 2026..│ 2026.. ..│
├────┴───────────┴─────────────┴───────┴───────────┴─────────────┴───────┴──────────┤
│   < Prev   [1] 2 3 4 5 ... 47   Next >                              total: 938   │
└────────────────────────────────────────────────────────────────────────────────────┘
```

Right-scroll continues — 29 columns total. See [`vfr-spec.md` §6](vfr-spec.md) for full column list.

### 6.2 Time × Area summary table (TimeAreaTable)

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│  VFR {gửi thầu | vận hành} theo thời gian và khu vực                       [?] [⬇]│
├──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬─────────────────┤
│Thời gian │ South E. │ HCM      │ Mekong 1 │ Ha Noi   │ ...      │  Trung bình     │
├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┼─────────────────┤
│2026-03   │ 72.40%   │ 68.10%   │ 58.00%   │ 80.00%   │ ...      │ 71.20%          │
│2026-04   │ 75.10%   │ 70.50%   │ 62.50%   │ 82.00%   │ ...      │ 73.50%          │
│2026-05   │ 71.80%   │ 69.20%   │ 60.00%   │ 81.00%   │ ...      │ 72.00%          │
├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┼─────────────────┤
│Trung bình│ 73.10%   │ 69.27%   │ 60.17%   │ 81.00%   │ ...      │ 72.23%          │
└──────────┴──────────┴──────────┴──────────┴──────────┴──────────┴─────────────────┘
        ▲ row trung bình (sticky bottom) tính column-wise; ô góc phải-dưới = grandAverage
        Color: text-sky-400 cho hàng trung bình + cột trung bình
```

---

## 7. Loading state

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│  ████████████████████████████████  (filter skeleton 12px)                          │
├──────┬──────┬──────┬──────┬──────┬─────────────────────────────────────────────────┤
│ ████ │ ████ │ ████ │ ████ │ ████ │                                                 │
│ skel │ skel │ skel │ skel │ skel │                                                 │
├──────┴──────┴──────┴──────┴──────┴─────────────────────────────────────────────────┤
│                                                                                    │
│                            ████████████████████████████                            │
│                            ████████ chart skeleton ████                            │
│                            ████████████████████████████                            │
│                                                                                    │
└────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Empty state (data error or no rows)

KHÔNG có banner/toast — silent degrade. Charts render với:
- KPI cards: `0` cho count fields, `0.00%` cho avgVfr
- Charts: empty Recharts canvas với axes nhưng không có Bar/Line
- Detail grid: header rows + footer "total: 0"

(Drift: PRD gốc spec error message + retry button — chưa implement)

---

## 9. Responsive behavior

| Breakpoint | KPI cards | Charts | Time×Area table |
|---|---|---|---|
| < 1280px (mobile/laptop) | 2 cols | 1 col | full width, h-scroll |
| ≥ 1280px (`xl`) | 5 cols | 2 cols | full width |

Charts dùng `ResponsiveContainer width=100% height=100%` với fixed parent `h-80` (320px).

---

## 10. Diff with PRD original wireframe

PRD gốc đề xuất layout 10 KPIs (5×GT + 5×VH) song song + 8 charts. Hiện code chốt layout:
- 5 KPIs × 1 mode (toggle GT/VH)
- 3 charts × 1 mode (toggle)
- 1 Time×Area table × 1 mode
- 1 Detail grid × 1 mode

Trade-off: clutter giảm ~40%, mất khả năng cross-eye compare GT vs VH (phải toggle). Memory `feedback_l5_dimension_panels_over_tabs` từng note rằng "với Mondelez cardinality nhỏ, grid 2×2 tốt hơn Tabs" — VFR đây dùng toggle vì mode là 2 nguồn dữ liệu khác nhau, không phải 2 dimension cuts cùng nguồn.
