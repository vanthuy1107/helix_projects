# Wireframe — Section OTIF

> ASCII wireframe trích xuất từ source code layout thực tế (`widget-otif.tsx`).
> Tất cả kích thước, màu sắc, component đều là **Observed** — không phải mockup.
>
> **Refresh 2026-05-12 (v1.1.0)** — cập nhật thứ tự insight-first sau FEAT-128 (commit `80194e9`) + bổ sung Chart by Warehouse (pre-existing) + Chart by Category (NEW). Trace report: [`projects/trace/widget-otif-chart-reorder-and-category-2026-05-12.md`](../../../trace/widget-otif-chart-reorder-and-category-2026-05-12.md).

---

## Tổng quan layout

Thứ tự "insight-first" sau FEAT-128: KPI tổng → **Lý do fail (root cause)** → Trend → drill-down theo các chiều (Transporter → Category → Sales Channel → Warehouse → Area).

```
┌─────────────────────────────────────────────────────────────────────┐
│  WIDGET: OTIF — Giám sát đơn hàng                                   │
│  [sticky header: Filter Bar]                                        │
├─────────────────────────────────────────────────────────────────────┤
│  Tab: [  Chart  ] [  Chi tiết  ]                                    │
├─────────────────────────────────────────────────────────────────────┤
│  (Tab Chart)                                                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐  │
│  │  KPI Card   │ │  KPI Card   │ │  KPI Card   │ │  KPI Card   │  │
│  │  Tổng đơn   │ │  % Ontime   │ │  % Infull   │ │  % OTIF     │  │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘  │
│                                                                     │
│  ┌────────────────────────────┐ ┌────────────────────────────┐     │
│  │  Lý do fail ontime  [?][↗] │ │  Lý do fail infull  [?][↗] │     │ ← #3 root cause (xl:grid-cols-2)
│  │  [BarChart horiz, h=256px] │ │  [BarChart horiz, h=256px] │     │
│  │  Total: N DO               │ │  Total: N DO               │     │
│  └────────────────────────────┘ └────────────────────────────┘     │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  %OTIF và số lượng đơn theo thời gian               [?][↗]  │   │ ← #4 trend
│  │                        [Day] [Week] [Month]                  │   │
│  │  [ComposedChart: Bar(totalSo) + Line(%OTIF), h=288px]        │   │
│  │  N đơn/day · X periods              total: N DO              │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Chart: OTIF / Ontime / Infull theo nhà vận tải      [?][↗] │   │ ← #5 transporter
│  │  [BarChart grouped, h=288px]                                 │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Chart: OTIF / Ontime / Infull theo loại hàng ★      [?][↗] │   │ ← #6 category (FEAT-128 NEW)
│  │  [BarChart grouped, h=288px]                                 │   │   accent: lime
│  │  FRESH → DRY → MOONCAKE → POSM/OFFBOM → TEST → ...           │   │   empty state: "Chưa cấu hình SQL"
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Chart: OTIF / Ontime / Infull theo kênh bán hàng    [?][↗] │   │ ← #7 sales channel
│  │  [BarChart grouped, h=288px]                                 │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Chart: OTIF / Ontime / Infull theo kho ★            [?][↗] │   │ ← #8 warehouse (pre-existing)
│  │  [BarChart grouped, h=288px]                                 │   │   X: whseid (BKD1/BKD2/NKD/VN821/...)
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Chart: OTIF / Ontime / Infull theo khu vực          [?][↗] │   │ ← #9 area
│  │  [BarChart grouped, h=288px]                                 │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘

★ = chart không có trong wireframe v1.0.0.
```

```
┌─────────────────────────────────────────────────────────────────────┐
│  (Tab Chi tiết)                                                     │
│  Tab: [%OTIF Chiều vận hành] [Fail Report] [Chi tiết đơn hàng]      │
├─────────────────────────────────────────────────────────────────────┤
│  (Inner tab: %OTIF Chiều vận hành)                                  │
│  Nhóm theo: [☑ NVC] [☑ Kênh] [☑ Nhóm hàng] [☑ Khu vực]           │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  NVC | Kênh | Nhóm hàng | Khu vực | Tổng đơn |%OTIF |%On|%In│  │
│  │  HVP  GT     PM          South...    120      95%   97%  98% │  │
│  │  TLL  MT     DRY         Mekong 1    80       88%   92%  94% │  │
│  │  ...                                                         │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Filter Bar

### Chế độ SqlFilterPanel (khi widget có filterStorageKey)

```
┌─────────────────────────────────────────────────────────────────────┐
│ OTIF Filters                                          [⚙] [Apply]  │
│ [Kho ▼]  [Khu vực ▼]  [Nhóm hàng ▼]  [NVC ▼]  [Loại ngày ▼]       │
│ [Từ ngày: 2026-01-01]  [Đến ngày: 2026-01-31]                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Chế độ fallback filter bar (7 controls)

```
┌──────────────────────────────────────────────────────────────────────┐
│ KHO          KHU VỰC       NHÓM HÀNG     NVC          LOẠI NGÀY     │
│ [ALL     ▼]  [ALL     ▼]   [ALL     ▼]   [ALL    ▼]   [ETA gửi ▼]  │
│                                                                       │
│ TỪ NGÀY                    ĐẾN NGÀY                                  │
│ [2026-05-07    ]            [2026-05-07   ]                           │
│                                          [Apply]      [Reset filter] │
└──────────────────────────────────────────────────────────────────────┘
```

Ghi chú: filter bar `sticky top-0 z-20` với `backdrop-blur`.

---

## KPI Cards

```
┌─────────────────────────┐
│▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄│  ← top gradient border (0.5px)
│ [🎯] TỔNG ĐƠN      [?] │  ← icon 20×20, label 10px, hint icon
│                         │
│  1,250                  │  ← value 20px bold tabular-nums
│                         │
│  Số đơn theo filter     │  ← desc 10px muted
└─────────────────────────┘

┌─────────────────────────┐
│▄▄▄▄▄▄▄(cyan)▄▄▄▄▄▄▄▄▄▄▄│
│ [⏰] % ONTIME      [?] │
│                         │
│  97.3%                  │  ← value
│  1,216 đơn              │  ← subValue (số đơn)
│  Tỷ lệ đơn giao đúng hạn│
└─────────────────────────┘

┌─────────────────────────┐
│▄▄▄▄▄(emerald)▄▄▄▄▄▄▄▄▄▄│
│ [✓] % INFULL       [?] │
│  94.1%                  │
│  1,176 đơn              │
│  Tỷ lệ đơn giao đủ SL  │
└─────────────────────────┘

┌─────────────────────────┐
│▄▄▄▄▄(violet)▄▄▄▄▄▄▄▄▄▄▄│
│ [⚠] % OTIF         [?] │
│  91.8%                  │
│  1,148 đơn              │
│  Tỷ lệ đơn đạt đủ & đúng│
└─────────────────────────┘

Layout: grid grid-cols-2 xl:grid-cols-4
```

---

## Charts

### Bar Chart By Area / By Sales Channel / By Transporter / By Warehouse / By Category

5 chart cùng pattern grouped-bar (3 bars: Ontime/Infull/OTIF). X-axis đổi theo dimension; Y-axis luôn 0–100%.

```
┌──────────────────────────────────────────────────────────┐
│ OTIF / Ontime / Infull theo khu vực              [?] [↗] │
│                                                           │
│  %  100┤                                         ■ Ontime│
│       ┤  97.3  94.1  91.8    ←label trên bar     ■ Infull│
│    80 ┤  █ █ █   █ █ █   ...                     ■ OTIF  │
│    60 ┤  │ │ │                                           │
│    40 ┤                                                   │
│    20 ┤                                                   │
│     0 └──────────────────────────────────────────────    │
│        S.East  HCM   Mekong1  Mekong2                    │
└──────────────────────────────────────────────────────────┘
Color: Ontime=#22D3EE Infull=#10B981 OTIF=#8E59FF
Height: 288px
```

**Chart by Category — empty state** (khi `sqlQueries.chartByCategory` blank):

```
┌──────────────────────────────────────────────────────────┐
│ OTIF / Ontime / Infull theo loại hàng           [?] [↗]  │
│                                                           │
│                                                           │
│         Chưa cấu hình SQL cho chart theo loại hàng.       │  ← i18n: categoryNoConfig
│                                                           │
│                                                           │
└──────────────────────────────────────────────────────────┘
Height: 288px (h-72)
Accent: from-lime-500/80 to-lime-400/30 (gradient riêng để phân biệt)
```

### Trend Chart

```
┌──────────────────────────────────────────────────────────┐
│ %OTIF và số lượng đơn theo thời gian          [?] [↗]    │
│                               [ Day ] [ Week ] [ Month ] │
│  %  100┤ 91.8  90.5  ...  ←line label          │ Count   │
│     80 ┤  ●────●────●────                      │  1250   │
│     60 ┤                                       │   900   │
│     40 ┤  █    █    █    ←bar (totalSo)         │   600   │
│     20 ┤                                       │   300   │
│      0 └─────────────────────────────────────────────   │
│        05-01  05-02  05-03  05-04  05-05               │
│  Số đơn/day · 5 ngày              total: 1,250 DO       │
└──────────────────────────────────────────────────────────┘
Bar: #60A5FA (Y right)  Line: #F59E0B (Y left, 0-100%)
```

### Fail Reason Charts (2 cột)

```
┌─────────────────────────────────┐ ┌─────────────────────────────────┐
│ Lý do fail ontime       [?][↗]  │ │ Lý do fail infull       [?][↗]  │
│                                 │ │                                  │
│ Lỗi transport giao trễ    █ 85  │ │ Warehouse Infull failure    █ 62 │
│ Lỗi rớt do warehouse      █ 34  │ │ Transport Infull failure    █ 28 │
│ Lỗi transport vào kho     █ 12  │ │ WH+Transport Infull fail   █  8  │
│ Lỗi warehouse gọi trễ     █  8  │ │                                  │
│ Lỗi rớt do transport      █  5  │ │                                  │
│                                 │ │                                  │
│                     139 DO      │ │                      98 DO       │
└─────────────────────────────────┘ └─────────────────────────────────┘
Fail Ontime bar: #F59E0B    Fail Infull bar: #EF4444
Height: 256px each
```

---

## Tab Chi tiết

### Inner tabs

```
┌──────────────────────────────────────────────────────────────────┐
│ [%OTIF Chiều vận hành] [Fail Report] [Chi tiết đơn hàng]         │
└──────────────────────────────────────────────────────────────────┘
```

### Tab: %OTIF Chiều vận hành

```
┌──────────────────────────────────────────────────────────────────┐
│ Nhóm theo:  [☑ Nhà vận tải] [☑ Kênh bán hàng]                   │
│             [☑ Nhóm hàng  ] [☑ Khu vực đội xe]                  │
│                                                                   │
│ ┌──────────┬────────────┬─────────────┬──────────┬──────┬───────┐│
│ │ NVC      │ Kênh       │ Nhóm hàng   │ Khu vực  │Tổng  │%OTIF  ││
│ │ ▼filter  │ ▼filter    │ text filter  │▼filter   │sort↕ │sort↕  ││
│ ├──────────┼────────────┼─────────────┼──────────┼──────┼───────┤│
│ │ HVP      │ GT         │ PM          │ South E  │ 120  │95.0%  ││
│ │          │            │             │          │      │(114)  ││
│ │ TLL      │ MT         │ DRY         │ HCM      │  80  │88.0%  ││
│ │          │            │             │          │      │(70)   ││
│ └──────────┴────────────┴─────────────┴──────────┴──────┴───────┘│
│ Format %OTIF: "X.X% (N đơn)" via formatPctAndCount()             │
└──────────────────────────────────────────────────────────────────┘
```

### Tab: Fail Report

```
┌──────────────────────────────────────────────────────────────────────┐
│ ┌─────┬──────┬──────┬──────┬──────┬──────────┬─────────────────────┐│
│ │ NVC │Kênh  │Nhóm  │Khu   │Tổng  │Fail Ontime (amber)             ││
│ │     │      │hàng  │vực   │đơn   ├──────────┬─────────────────────┤│
│ │     │      │      │      │      │ Fail On  │Late arrival │Late WH ││
│ ├─────┼──────┼──────┼──────┼──────┼──────────┼─────────────┼───────┤│
│ │ HVP │ GT   │ PM   │ S.E  │ 120  │    25    │     15      │   5   ││
│ └─────┴──────┴──────┴──────┴──────┴──────────┴─────────────┴───────┘│
│ (+ columns: Fail Infull (rose), Warehouse/Transport/WH+Trans fail)   │
└──────────────────────────────────────────────────────────────────────┘
```

### Tab: Chi tiết đơn hàng

```
┌───────────────────────────────────────────────────────────────────────┐
│ ┌────────┬────────┬──────┬──────────┬────────┬───────┬───────┬───────┐│
│ │ SO     │ DO     │ Kho  │ Khu vực  │Nhóm hàng│Kênh  │ ETA   │ ATA   ││
│ │ text▼  │ text▼  │ ▼    │ ▼        │ text▼   │text▼ │ text▼ │ text▼ ││
│ ├────────┼────────┼──────┼──────────┼─────────┼──────┼───────┼───────┤│
│ │84830000│84831000│BKD1  │South East│PM       │GT    │05-01  │05-01  ││
│ ├────────┼────────┼──────┼──────────┼─────────┼──────┼───────┼───────┤│
│ │ ...    │        │      │          │         │      │       │       ││
│ └────────┴────────┴──────┴──────────┴─────────┴──────┴───────┴───────┘│
│ + KH | Xuất kho | Giao | Ontime | Infull | OTIF | % OTIF | ...       │
│ (Cột ẩn mặc định toggle được qua column settings)                     │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Loading State

```
┌─────────────────────────────────────────────────────────┐
│  [████████████████████████████] ← Skeleton h-28         │
│                                                         │
│  [████████] [████████] [████████] [████████]   ← 4 card │
│   skeleton   skeleton   skeleton   skeleton    │  h-80px │
│                                                         │
│  [████████████████████████████████████████████]         │
│   ████████████████████████████████████████████          │
│   flex-1 skeleton                                       │
└─────────────────────────────────────────────────────────┘
```

## Error State

```
┌─────────────────────────────────────────────────────────┐
│  ⚠ Order Monitor API 500: Connection refused            │
│    [red border, red background/10]                      │
└─────────────────────────────────────────────────────────┘
```

---

## Edit Mode — Toolbar

```
┌───────────────────────────────────────────────────────┐
│  Dashboard Toolbar              [⚙ SQL Settings] [≡]  │
│                                  violet        amber   │
└───────────────────────────────────────────────────────┘

[⚙ SQL Settings] = WidgetOtifSettingsDialog
  → Mở dialog với 12 tab: Cards | By Area | By SalesChannel |
    By Transporter | By Warehouse ★ | By Category ★ |
    Fail Ontime | Fail Infull | Trend |
    OTIF Ops | Fail Report | Detail
  → Mỗi tab có Monaco editor + nút Test Query
  ★ = tab thêm sau v1.0.0 (Warehouse: commit 53dd564; Category: FEAT-128)

[≡] amber = Filter Settings (SqlFilterPanel config)
```

---

## Responsive Behavior

| Breakpoint | KPI Cards | Fail Charts | Filter Bar |
|-----------|-----------|-------------|------------|
| Mobile (`<xl`) | 2 cột | 1 cột | 2 cột × 4 hàng |
| Desktop (`xl+`) | 4 cột | 2 cột | 7 cột × 1 hàng |

```
Mobile:              Desktop (xl):
┌────┐ ┌────┐       ┌────┐ ┌────┐ ┌────┐ ┌────┐
│KPI │ │KPI │       │KPI │ │KPI │ │KPI │ │KPI │
└────┘ └────┘       └────┘ └────┘ └────┘ └────┘
┌────┐ ┌────┐       ┌──────────────────────────┐
│KPI │ │KPI │       │    Fail Ontime Chart      │
└────┘ └────┘       └──────────────────────────┘
┌──────────────┐    ┌──────────────────────────┐
│ Fail Ontime  │    │    Fail Infull Chart      │
└──────────────┘    └──────────────────────────┘
┌──────────────┐
│ Fail Infull  │
└──────────────┘
```

