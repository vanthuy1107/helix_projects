# Wireframe — Section Flash Daily

> ASCII wireframe trích xuất từ source code layout thực tế (`widget-flash-daily.tsx`) cho v1.0.0 baseline + mockup mới cho v1.1.0 storytelling refresh.
>
> **Version**: 1.1.0 — Storytelling refresh 2026-05-16. Đi cùng [`flash-daily-prd.md`](flash-daily-prd.md) và [`flash-daily-spec.md`](flash-daily-spec.md) v1.1.0. Source of truth decisions: [`analysis/flash-daily-oq-resolution.md`](analysis/flash-daily-oq-resolution.md) §0-LOCKED.

---

## Layout v2 Overview (v1.1.0 — storytelling 6 levels)

> Locked 2026-05-16 sau 3 rounds duyệt PM + 3 audit. v1.0.0 baseline được giữ ở sections "v1.0.0 Baseline" bên dưới để compare.

```
┌─────────────────────────────────────────────────────────────────────┐
│ FILTER BAR (sticky, autoApply) — giữ nguyên v1.0.0                  │
├─────────────────────────────────────────────────────────────────────┤
│ L1 HERO — % HOÀN THÀNH HÔM NAY (full-width)                         │
│   • Snapshot value + target 95% reference + RAG color               │
│   • Sub-numbers: Plan / Đã giao / Còn lại                           │
│   • KHÔNG có delta, KHÔNG có as-of timestamp                        │
├─────────────────────────────────────────────────────────────────────┤
│ L2 EXCEPTION SPOTLIGHT — 3 ô (hôm nay)                              │
│   • Top N kho off-target (< 85%)                                    │
│   • Đơn rớt chưa xử lý                                              │
│   • Khu vực dưới target                                             │
├─────────────────────────────────────────────────────────────────────┤
│ L3 FUNNEL 5 TRẠNG THÁI — strip compact 1 dòng                       │
│   • Chưa xuất → Đang xuất → Đã xuất → Đang vận → Đã vận             │
│   • Mỗi entry: volume + % share                                     │
│   • THAY THẾ 6 KPI cards baseline                                   │
├─────────────────────────────────────────────────────────────────────┤
│ L4 TREND TỶ LỆ RỚT 14 NGÀY — chart MỚI (line)                       │
│   • Definition: drop_rate = # đơn FAIL / Tổng kế hoạch (per day)    │
│   • X: 14 ngày qua | Y: % rớt                                       │
│   • Reference: target ≤5% (solid red) + rolling 30d avg (dashed)    │
│   • Áp cùng filter bar với L1-L3                                    │
├─────────────────────────────────────────────────────────────────────┤
│ L5 DIMENSION DRILLDOWN — tabbed chart (hôm nay)                     │
│   • Tabs: Kho / Khu vực / Khách / Kênh                              │
│   • Horizontal bar % completion, sort worst-first, target line 95%  │
├─────────────────────────────────────────────────────────────────────┤
│ L6 DETAIL TABLES (tab riêng) — GIỮ NGUYÊN 9 bảng (D2 defer)         │
│   • T1 Completion — BỎ synthetic fallback (drift #7 fix)            │
│   • T2-T6 Summary, T7-T9 (giữ — cleanup ở phase sau)                │
└─────────────────────────────────────────────────────────────────────┘
```

---

## L1 Hero — % Hoàn thành E2E hôm nay (full-width)

```
┌─────────────────────────────────────────────────────────────────────┐
│ HÔM NAY 73% KẾ HOẠCH ĐÃ HOÀN THÀNH — DƯỚI TARGET 95%   [⚠ banner]  │ ← action title
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                                                             │    │
│  │         ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                              │    │ ← progress bar
│  │         (red bg — RAG <85)                                  │    │   filled to 73%
│  │                                                             │    │
│  │              73%                  Target 95% ─ ─ ─ ─ ─ ─ ─ │    │ ← target ref line
│  │           text-6xl bold                                     │    │
│  │           color: red-500 (RAG <85)                          │    │
│  │                                                             │    │
│  │  Plan  125,400 CSE   │  Đã giao  91,542 CSE   │  Còn lại  33,858 CSE
│  │  text-xs muted        │  text-sm emerald       │  text-sm amber │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                     │
│ Alert banner (chỉ khi overall < 80%):                              │
│ ⚠ Hôm nay đang off-track nghiêm trọng (<80%) — cần can thiệp ngay  │
│ [red bg-red-500/10, border red-500/30, icon AlertTriangle]         │
└─────────────────────────────────────────────────────────────────────┘

RAG color logic (target = 95%):
  ≥ 95%       → bg-emerald-500/10, text-emerald-600 (Green)
  85% – <95%  → bg-amber-500/10,   text-amber-600   (Yellow)
  < 85%       → bg-red-500/10,     text-red-600     (Red)
  < 80%       → + full-width alert banner trên đầu dashboard

Layout: w-full, p-6, rounded-xl, border, mb-4
KHÔNG có delta vs hôm qua (F2 reframe)
KHÔNG có as-of timestamp (G7)
Sub-numbers format theo UOM hiện hành
```

---

## L2 Exception Spotlight — 3 ô (chỉ show khi có vấn đề)

```
┌─────────────────────────────────────────────────────────────────────┐
│ ⚠ ĐIỂM NÓNG CẦN XỬ LÝ HÔM NAY                                       │ ← action title
│                                                                     │
│ ┌────────────────────┐ ┌────────────────────┐ ┌────────────────────┐│
│ │ KHO OFF-TARGET     │ │ ĐƠN RỚT CHƯA XỬ LÝ │ │ KHU VỰC DƯỚI TARGET││
│ │ ─────────────      │ │ ─────────────      │ │ ─────────────      ││
│ │ ● BKD1   72% ▼     │ │ Tổng: 248 đơn      │ │ ● Mekong 2  78%▼   ││
│ │ ● NKD    81% ▼     │ │                    │ │ ● Central H 82%▼   ││
│ │ ● VN821  84% ▼     │ │ Top reason:        │ │ ● North Cen 84%▼   ││
│ │                    │ │  Hết hàng      102 │ │                    ││
│ │ Target: 95%        │ │  Sai đơn        67 │ │ Target: 95%        ││
│ │ Threshold: <85%    │ │  Khách hủy      45 │ │ Threshold: <85%    ││
│ │                    │ │  Khác           34 │ │                    ││
│ │ [↗ View T7 Drop]   │ │ [↗ View T7]        │ │ [↗ View L5 Area]   ││
│ └────────────────────┘ └────────────────────┘ └────────────────────┘│
│   red border-l-4         amber border-l-4        red border-l-4     │
│   bg-red-500/5           bg-amber-500/5          bg-red-500/5       │
└─────────────────────────────────────────────────────────────────────┘

Conditional render:
  - Card 1 (Kho): show khi >= 1 kho có pctDone < 85%, sort worst-first, top 3
  - Card 2 (Drop): show khi tổng đơn FAIL ('Cancel') > 0 hôm nay
  - Card 3 (Region): show khi >= 1 region có pctDone < 85%, sort worst-first, top 3

Layout: grid grid-cols-1 md:grid-cols-3 gap-3 mb-4
Mỗi card: rounded-lg, p-4, border, border-l-4 (red/amber theo severity)
KHÔNG show section khi không có exception → giữ dashboard sạch
Click ↗ link nhảy xuống section L5 hoặc L6 detail
```

---

## L3 Funnel 5 Trạng thái — strip compact 1 dòng (thay 6 KPI cards)

```
┌─────────────────────────────────────────────────────────────────────┐
│ LUỒNG E2E HÔM NAY — 73% (91.5k / 125.4k CSE)                        │ ← action title
│                                                                     │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐          │
│  │ Chưa     │ Đang     │ Đã       │ Đang     │ Đã       │          │
│  │ xuất kho │ xuất kho │ xuất kho │ vận chyn │ vận chyn │          │
│  │ ────     │ ────     │ ────     │ ────     │ ────     │          │
│  │ 12.3k    │ 18.0k    │ 20.5k 📍 │ 35.6k 📍 │ 39.0k    │          │
│  │  9.8%    │ 14.4%    │ 16.3%    │ 28.4%    │ 31.1%    │          │
│  │ grey     │ amber    │ violet   │ blue     │ green    │          │
│  │ #858585  │ #E18719  │ #4F2170  │ #2D6EAA  │ #287819  │          │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘          │
│       →            →           →            →                       │
│  [arrow chevrons giữa các entry, color muted-foreground/30]        │
│                                                                     │
│  📍 caveat icon (ở cards 3 + 4): tooltip "Chưa nhận tín hiệu ATD   │
│      từ STM — volume có thể giữ ở trạng thái này lâu hơn thực tế" │
│      (audit A3 finding 1)                                          │
└─────────────────────────────────────────────────────────────────────┘

STATUS_ORDER PHẢI sửa đúng luồng E2E (drift #11):
  ['Chưa xuất kho', 'Đang xuất kho', 'Đã xuất kho', 'Đang vận chuyển', 'Đã vận chuyển']

Layout: flex strip 1 dòng (responsive: stack 2x3 trên mobile)
Mỗi entry: flex-1, p-3, border-t-2 (color accent), text-center
Total 5 entries (KHÔNG có "Tổng Volume Kế hoạch" — đã ở L1)
THAY THẾ 6 KPI cards baseline v1.0.0
Hint icon (Info) per entry — i18n từ FLASH_DAILY_HINTS
```

---

## L4 Drop Trend 14 ngày — Line chart (section MỚI v1.1.0)

```
┌─────────────────────────────────────────────────────────────────────┐
│ TỶ LỆ RỚT 14 NGÀY QUA — TRUNG BÌNH 4.2%, ĐỈNH 8.1% NGÀY 12/05      │ ← action title
│                                                                     │
│  Drop rate (%)                                                      │
│   10 ┤                                                              │
│      │            ●                                                 │
│    8 ┤           /│\                                                │
│      │          / │ \                                               │
│    6 ┤    ●    /  │  \      ●                                       │
│      │   /│\  /   │   \    /│\                                      │
│   ━━5━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│ ← Target ≤5% (solid red)
│      │  / │ \/    │    \  / │ \                                     │
│    4 ┤ ●  ●  ●    │     ●●  │  ●                                    │
│      │            │         │   \   ●                               │
│   ─ ─3.8─ ─ ─ ─ ─ │ ─ ─ ─ ─ ─ ─ ─ \─/─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│ ← rolling 30d avg (dashed grey)
│      │            │         │     ●                                 │
│    2 ┤                                                              │
│      │                                                              │
│    0 ┴────────────────────────────────────────────────────          │
│      04/05 05 06 07 08 09 10 11 12 13 14 15 16 17                   │
│                            (14 ngày qua, ASC L→R)                   │
│                                                                     │
│  Legend:                                                            │
│  ● Drop rate (line solid blue)                                      │
│  ━ Target ≤5% (solid red, y=5)                                      │
│  ─ Rolling 30d avg (dashed grey, dynamic per-day)                   │
│                                                                     │
│  Tooltip per dot:                                                   │
│  ┌─────────────────────────────┐                                    │
│  │ 12/05/2026                  │                                    │
│  │ Drop rate:     8.1%  ⚠      │                                    │
│  │ Failed:        320 đơn      │                                    │
│  │ Total plan:    3,950 đơn    │                                    │
│  │ 30d avg:       4.2%         │                                    │
│  └─────────────────────────────┘                                    │
└─────────────────────────────────────────────────────────────────────┘

Layout: full-width, h=320px fixed
Section key: chartDropTrend (mới — interface FlashDailySqlQueries)
i18n title: chartDropTrend14d
Export filename: flash-daily-drop-trend-14d
14 ngày FIXED — KHÔNG có dropdown chọn N (G1 chốt)
FAIL = status='Cancel' only — KHÔNG bao gồm Close (H1 chốt)
Date type guard: disable ETD/ETA gửi thầu options khi xem L4 (H2 chốt)
  → chỉ allow GI date / Actual Ship Date / ATA đơn
Áp cùng filter bar với L1-L3 (G5 chốt)
SQL CTE backfill 44 ngày để rolling 30d đủ priors
```

---

## L5 Dimension Drilldown — Tabbed chart (worst-first)

```
┌─────────────────────────────────────────────────────────────────────┐
│ CHIỀU NÀO ĐANG KÉO % HOÀN THÀNH XUỐNG?                              │ ← action title
│                                                                     │
│  Tabs: [ Kho ▼ ] [ Khu vực ] [ Khách hàng ] [ Kênh bán ]            │
│         ─────                                                       │
│  (active tab có border-b-2 primary)                                 │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ BKD1     ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰         72% ⚠ Red             │   │ ← worst-first
│  │ NKD      ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰       81% ⚠ Red             │   │
│  │ VN821    ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰      84% ⚠ Red             │   │
│  │ BKD2     ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰     88% ▲ Yellow          │   │
│  │ BKD3     ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰    91% ▲ Yellow          │   │
│  │ NKD-out  ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰   95% ✓ Green           │   │
│  │ VN831    ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰  97% ✓ Green           │   │
│  │                                                              │   │
│  │                          target 95% ─ ─ ─ ─ ─ ─ ─ ─ ─ ─     │   │ ← target ref line
│  │ 0%       20%      40%      60%      80%     100%             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  Tab options:                                                       │
│  - Kho (whseid): horizontal bar, ~5-10 rows                         │
│  - Khu vực (region): 10 rows                                        │
│  - Khách hàng (customer): top 10 by total (KHÔNG có dropdown        │
│      NPP/Customer — D3 bỏ; search box + N selector → v1.2.0)        │
│  - Kênh bán (group_name): 5-6 rows                                  │
└─────────────────────────────────────────────────────────────────────┘

Layout: full-width, h = clamp(320, rows*40, 600)
Sort: worst-first (pctDone ASC) — Red rows ở trên
Bar color: theo RAG (red <85, amber <95, emerald ≥95)
Target reference line: y=95% (solid grey)
Filter parity: cùng filter bar L1-L4
KHÔNG có dropdown customerDimensionFilter (D3 bỏ NPP/Customer)
Export filename: flash-daily-dimension-{kho|region|customer|channel}
```

---

## L6 Detail Tables — GIỮ NGUYÊN 9 bảng v1.0.0 (D2 defer)

Layout, ASCII wireframe của 9 grid `DSHFLADTG01..09` xem section **"v1.0.0 Baseline → Tab Chi tiết bảng"** bên dưới. v1.1.0 KHÔNG cắt T2-T6 — user chọn defer hoàn toàn ngày 2026-05-16.

**Thay đổi duy nhất**: T1 Completion phải BỎ synthetic fallback 54 dòng (drift #7 fix). Khi `tblCompletion` SQL rỗng → render EmptyState:

```
┌─────────────────────────────────────────────────────────────────────┐
│ DSHFLADTG01 — Report tỷ lệ hoàn thành                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│              ┌──────────────────────────────────────┐               │
│              │  ⚠                                    │               │
│              │  Chưa cấu hình SQL `tblCompletion`   │               │
│              │  Liên hệ admin để bổ sung query.     │               │
│              └──────────────────────────────────────┘               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## v1.0.0 Baseline — Tổng quan layout

> Sections từ đây xuống là ASCII wireframe v1.0.0 baseline. Giữ để team compare khi build v1.1.0. **6 KPI cards baseline sẽ bị replace bởi L1 hero + L3 funnel strip ở v1.1.0** — nhưng wireframe baseline vẫn cần để dev biết được cái gì đang được thay.

Thứ tự render: KPI cards (6 thẻ) → Chart Theo khu vực giao → Grid 2 cột (Phân bổ E2E + Theo kho) → Chart Theo NPP/Customer → Chart Theo kênh bán → Tab "Chi tiết bảng" (9 grid).

```
┌─────────────────────────────────────────────────────────────────────┐
│  WIDGET: FLASH DAILY — Tiến độ E2E hằng ngày                       │
│  [sticky filter bar — 8 fields, autoApply]                          │
├─────────────────────────────────────────────────────────────────────┤
│  Tab: [  Biểu đồ  ] [  Chi tiết bảng  ]                            │
├─────────────────────────────────────────────────────────────────────┤
│  (Tab Biểu đồ)                                                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                            │
│  │  Card    │ │  Card    │ │  Card    │   ← 3 cols (xl)            │
│  │  Tổng    │ │  Chưa    │ │  Đang    │     grid grid-cols-1       │
│  │  Volume  │ │  xuất    │ │  xuất    │       sm:grid-cols-2       │
│  │  emerald │ │  kho     │ │  kho     │       xl:grid-cols-3       │
│  │          │ │  grey    │ │  amber   │                            │
│  └──────────┘ └──────────┘ └──────────┘                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                            │
│  │  Card    │ │  Card    │ │  Card    │                            │
│  │  Đã xuất │ │  Đang    │ │  Đã      │                            │
│  │  kho     │ │  vận     │ │  vận     │                            │
│  │  violet  │ │  chuyển  │ │  chuyển  │                            │
│  │          │ │  blue    │ │  green   │                            │
│  └──────────┘ └──────────┘ └──────────┘                            │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Theo khu vực giao hàng                              [?][↗] │   │ ← #1 by Region
│  │  Subtitle: Stacked theo Region · Plan CBM: N                 │   │
│  │  [Horizontal stacked BarChart, h = dynamic 480..1400px]      │   │
│  │  Y: Region names (width 180px)                               │   │
│  │  X: Volume                                                   │   │
│  │  7 bars per group: Plan + Actual + 5 status                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌──────────────────────────────┐ ┌──────────────────────────────┐ │
│  │  Phân bổ E2E         [?][↗]  │ │  Tiến độ theo kho    [?][↗]  │ │ ← #2 + #3 (grid 2 cols xl)
│  │  Subtitle: Plan CBM: N        │ │  Subtitle: Plan CBM: N        │ │
│  │  [Vertical BarChart, h=288px] │ │  [Vertical Stacked, h=384px]  │ │
│  │  X: 7 status entries          │ │  X: WHSEID                    │ │
│  │  Each X has individual color  │ │  7 bars stacked per WH        │ │
│  │  (no stacking)                │ │  Plan + Actual + 5 status     │ │
│  └──────────────────────────────┘ └──────────────────────────────┘ │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Theo NPP/Customer                                   [?][↗] │   │ ← #4 by Customer
│  │  Subtitle: Plan CBM: N                                       │   │
│  │  Loại hiển thị: [ Tất cả ▼ ]   ← customerDimensionFilter    │   │
│  │  [Horizontal stacked, h = dynamic, TOP 10 by total]          │   │
│  │  Y: Customer/NPP names                                       │   │
│  │  Dropdown filter: All / NPP only / Customer only             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Theo kênh bán hàng                                  [?][↗] │   │ ← #5 by Sales Channel
│  │  Subtitle: Plan CBM: N                                       │   │
│  │  [Horizontal stacked, h = dynamic]                           │   │
│  │  Y: Group/Channel (GT, MT, KA, B2B, EXPORT, OTHER)           │   │
│  │  7 bars per channel                                          │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

```
┌─────────────────────────────────────────────────────────────────────┐
│  (Tab Chi tiết bảng — 9 WidgetGrid stack vertical)                  │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  DSHFLADTG01 — Report tỷ lệ hoàn thành (page 20)              │  │
│  │  Tên kho | Kênh | Khu vực | Mục tiêu | Hoàn thành |Còn lại|% │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  DSHFLADTG02 — Báo cáo chi tiết E2E (page 10)                 │  │
│  │  Trạng thái | Volume | UOM                                    │  │
│  │  (7 rows: Kế hoạch + Thực xuất + 5 status)                    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  DSHFLADTG03 — Tổng hợp theo kho (page 10)                    │  │
│  │  Tên | Tổng | Hoàn thành | Đang chờ | % Hoàn thành            │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  DSHFLADTG04 — Tổng hợp theo NPP/Customer (page 10)           │  │
│  │  (cùng schema #3)                                             │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  DSHFLADTG05 — Tổng hợp theo khu vực (page 10)                │  │
│  │  (cùng schema #3)                                             │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  DSHFLADTG06 — Tổng hợp theo kênh bán hàng (page 10)          │  │
│  │  (cùng schema #3)                                             │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  DSHFLADTG07 — Report hàng rớt (page 20)                      │  │
│  │  Delivery to Customer | DRY&FRESH(CSE) | POSM(PC) | % DF | %P │  │
│  │  (4 fixed rows: Tổng KH / Thành công / Đang xử lý / Failed)   │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  DSHFLADTG08 — Report lý do rớt đơn (page 10)                 │  │
│  │  Remark | FRESH/DRY (CSE) | POSM (PC)                         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  DSHFLADTG09 — Chi tiết Flash (page 20)                       │  │
│  │  32 cột: SO | Order type | STATUS | TT đơn hàng | TT đơn DO  │  │
│  │           | Item Code | Tên hàng | Group of Cago | Group |...│  │
│  │  Cột UOM-aware: ORIGINAL / SHIPPED / Sản lượng giao          │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Filter Bar

### Chế độ SqlFilterPanel — autoApply (8 fields)

```
┌─────────────────────────────────────────────────────────────────────┐
│ Flash Daily Filters                                  [⚙] (autoApply)│
│ [Kho ▼ ALL]  [Sales Channel ▼ ALL]  [Cargo Group ▼ ALL]            │
│ [Brand ▼ ALL]  [Khu vực ▼ ALL]                                     │
│ [UOM ▼ cse]  [Date Type ▼ GI date]  [Date range: 01..16/05/2026]   │
└─────────────────────────────────────────────────────────────────────┘
```

- Brand depends on Cargo Group (parentKey: `group_of_cargo`)
- UOM = single-select, 5 options: cse, ton, cbm, pallet, do
- Date Type = single-select, 5 options: GI date, Actual Ship date, ETD gửi thầu, ATA đơn, ETA gửi thầu
- Multi-select fields default = ALL (truyền empty string khi resolve)
- autoApply: thay đổi → áp dụng ngay, KHÔNG cần nhấn Apply
- Sticky `top-0 z-20` với `backdrop-blur`

### Edit mode toolbar — 2 nút

```
┌─────────────────────────────────────────────────────────┐
│  Dashboard Toolbar  ... [⚙ Setting Chart]  [≡ Setting   │
│                          violet outline       Filter ]  │
│                                              amber chip │
└─────────────────────────────────────────────────────────┘
```

- [⚙ Setting Chart] → mở `WidgetFlashDailySettingsDialog` (15-tab SqlSettingsDialog)
- [≡ Setting Filter] → mở `SqlFilterPanel` settings dialog (amber chip styling)

---

## KPI Cards (StatusCard)

```
┌─────────────────────────┐
│▄▄▄▄▄(emerald)▄▄▄▄▄▄▄▄▄▄│  ← top gradient border (0.5px)
│ [📦] TỔNG VOLUME    [?] │  ← icon 32×32, label 10px, hint icon
│      KẾ HOẠCH           │
│  125,400                │  ← value text-lg bold tabular-nums
│  Tổng volume kế hoạch...│  ← desc 10px muted
└─────────────────────────┘
Background: linear-gradient(135deg, #10B98126 → #10B9810D)

┌─────────────────────────┐
│▄▄▄▄▄▄▄▄(grey)▄▄▄▄▄▄▄▄▄▄│
│ [🗂️] CHƯA XUẤT KHO  [?] │
│  12,300                  │
│  Volume kho chưa bắt    │
│  đầu xử lý               │
└─────────────────────────┘
Background: linear-gradient(135deg, #85858526 → #8585850D)

┌─────────────────────────┐
│▄▄▄▄▄▄▄(amber)▄▄▄▄▄▄▄▄▄▄│
│ [📈] ĐANG XUẤT KHO  [?] │
│  18,000                  │
│  Volume đang được kho   │
│  xử lý: allocate,...    │
└─────────────────────────┘
Background: linear-gradient(135deg, #E1871926 → #E187190D)

┌─────────────────────────┐
│▄▄▄▄▄(violet)▄▄▄▄▄▄▄▄▄▄▄│
│ [🚚] ĐÃ XUẤT KHO    [?] │
│  20,500                  │
│  Volume đã load lên xe  │
│  và xe còn trong kho    │
└─────────────────────────┘
Background: linear-gradient(135deg, #4F217026 → #4F21700D)

┌─────────────────────────┐
│▄▄▄▄▄▄▄▄(blue)▄▄▄▄▄▄▄▄▄▄│
│ [🚚] ĐANG VẬN       [?] │
│       CHUYỂN            │
│  35,600                  │
│  Volume đã rời kho và   │
│  đang trên đường giao   │
└─────────────────────────┘
Background: linear-gradient(135deg, #2D6EAA26 → #2D6EAA0D)

┌─────────────────────────┐
│▄▄▄▄▄▄▄(green)▄▄▄▄▄▄▄▄▄▄│
│ [🚚] ĐÃ VẬN CHUYỂN  [?] │
│  39,000                  │
│  Volume đã giao tới NPP │
└─────────────────────────┘
Background: linear-gradient(135deg, #28781926 → #2878190D)

Layout: grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3
```

---

## Chart 1 — Theo khu vực giao hàng (Horizontal Stacked)

```
┌────────────────────────────────────────────────────────────────────┐
│ Theo khu vực giao hàng                                    [?] [↗]  │
│ Stacked DO count theo Khu vực giao và trạng thái · Số KH (CBM): N  │
│                                                                     │
│  South East        ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰  35,200                  │
│  South East-Lam D. ▰▰▰▰▰▰▰▰▰▰▰▰▰         18,500                   │
│  Ha Noi            ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰       21,800                   │
│  Central highland  ▰▰▰▰▰▰▰▰              9,200                    │
│  Mekong 1          ▰▰▰▰▰▰▰▰▰▰▰▰          14,300                   │
│  Ho Chi Minh       ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰    25,400                   │
│                                                                     │
│  Legend (7 entries, custom-rendered):                              │
│  ■ #0EA5E9 Kế hoạch xuất     ■ #16A34A Tổng thực xuất             │
│  ■ #858585 Chưa xuất kho     ■ #E18719 Đang xuất kho              │
│  ■ #4F2170 Đã xuất kho       ■ #2D6EAA Đang vận chuyển            │
│  ■ #287819 Đã vận chuyển                                          │
└────────────────────────────────────────────────────────────────────┘
Layout: vertical, YAxis category, width=180px
Height: clamp(480, rows*200, 1400) — dynamic
Margin: {top: 4, right: 60, left: 0, bottom: 0}
maxBarSize: 32px, barCategoryGap: 10%, barGap: 2px
Bar radius: [0, 4, 4, 0] (right-rounded)
Label: position='right', 1 decimal place, font 9px, color #9CA3AF
```

---

## Chart 2 — Phân bổ E2E (Vertical Bar, 7 cột)

```
┌────────────────────────────────────────────────────────────────────┐
│ Phân bổ E2E                                              [?] [↗]   │
│ Giá trị theo UOM đã chọn và trạng thái e2e · Số KH (CBM): N        │
│                                                                     │
│  Volume                                                             │
│   40k ┤                                          ▮ 39.0k           │
│   30k ┤                                  ▮ 35.6k                   │
│   20k ┤              ▮ 20.5k                                       │
│       │      ▮ 18.0k                                               │
│   10k ┤  ▮ 12.3k                                                   │
│      ▮125k                                                         │
│    0 ┴──────────────────────────────────────────────              │
│      Kế   Tổng  Chưa  Đang  Đã    Đang  Đã                        │
│      hoạch thực xuất  xuất  xuất  vận   vận                       │
│      xuất xuất kho   kho   kho   chuyển chuyển                    │
│      🔵   🟢   ⚪    🟠    🟣    🔵    🟢                          │
│      ↑0EA5E9 ↑16A34A ↑858585 ↑E18719 ↑4F2170 ↑2D6EAA ↑287819     │
│                                                                     │
│  Legend (7 entries, font 15px — khác chart khác):                  │
└────────────────────────────────────────────────────────────────────┘
Layout: vertical (default — each X = 1 single bar, NOT stacked)
Each X entry has its own Cell color from e2eDoRows
Height: 288px (h-72)
Bar radius: [6, 6, 0, 0]
Label: position='top', 1 decimal, 9px
```

---

## Chart 3 — Tiến độ theo kho hệ thống (Vertical Stacked)

```
┌────────────────────────────────────────────────────────────────────┐
│ Tiến độ theo kho hệ thống                                [?] [↗]   │
│ Stacked theo kho và trạng thái · Số KH (CBM): N                    │
│                                                                     │
│   25k ┤      ▮ 22.4k                                               │
│       │      ▮▮▮                                                   │
│   20k ┤      ▮▮▮      ▮ 19.8k                                      │
│       │      ▮▮▮      ▮▮▮                                          │
│   15k ┤  ▮ 14.5k  ▮▮▮      ▮ 16.2k                                │
│       │  ▮▮▮      ▮▮▮      ▮▮▮                                    │
│   10k ┤  ▮▮▮      ▮▮▮      ▮▮▮      ▮ 11.0k                       │
│       │  ▮▮▮      ▮▮▮      ▮▮▮      ▮▮▮                           │
│    5k ┤  ▮▮▮      ▮▮▮      ▮▮▮      ▮▮▮      ▮ 5.8k               │
│       │  ▮▮▮      ▮▮▮      ▮▮▮      ▮▮▮      ▮▮▮                  │
│    0 ┴──────────────────────────────────────────────              │
│         BKD1     BKD2    BKD3    NKD     VN821                     │
│                                                                     │
│  Legend: 7 entries (cùng pattern Chart 1)                          │
└────────────────────────────────────────────────────────────────────┘
Layout: vertical bars, X = whseid sorted alpha
Height: 384px (h-96 — fixed)
Margin: {top: 24, right: 12, left: 0, bottom: 0}
maxBarSize: 28px, barCategoryGap: 25%, barGap: 2px
Bar radius: [4, 4, 0, 0] (top-rounded)
Label: position='top', 1 decimal, 9px
```

---

## Chart 4 — Theo NPP/Customer (Horizontal, top 10)

```
┌────────────────────────────────────────────────────────────────────┐
│ Theo NPP/Customer                                        [?] [↗]   │
│ Stacked theo Customer và trạng thái · Số KH (CBM): N               │
│                                                                     │
│  Loại hiển thị: [ Tất cả ▼ ]    ← customerDimensionFilter dropdown │
│                  Tất cả                                            │
│                  NPP only                                          │
│                  Customer only                                     │
│                                                                     │
│  NPP A         ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰  45,200                  │
│  Customer X    ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰      38,500                  │
│  Distributor Y ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰         32,800                  │
│  Customer Z    ▰▰▰▰▰▰▰▰▰▰▰▰▰▰            28,100                  │
│  NPP B         ▰▰▰▰▰▰▰▰▰▰▰▰              22,400                  │
│  Customer M    ▰▰▰▰▰▰▰▰▰▰                17,200                  │
│  NPP C         ▰▰▰▰▰▰▰▰▰                 14,800                  │
│  Customer N    ▰▰▰▰▰▰▰▰                  12,300                  │
│  NPP D         ▰▰▰▰▰▰▰                   10,200                  │
│  Customer P    ▰▰▰▰▰▰                    8,500                   │
│                                                                     │
│  (chỉ top 10 by total — topNByTotal(rows, 10))                     │
│  Legend: 7 entries                                                 │
└────────────────────────────────────────────────────────────────────┘
Layout: vertical (horizontal bars)
Height: clamp(480, rows*200, 1400) — usually 480-2000 nếu < 10 rows
NPP/Customer classification: inferCustomerDimensionType()
  - substring 'npp' / 'nha phan phoi' / 'nhà phân phối' / 'distributor' → npp
  - else → customer
```

---

## Chart 5 — Theo kênh bán hàng (Horizontal Stacked)

```
┌────────────────────────────────────────────────────────────────────┐
│ Theo kênh bán hàng                                       [?] [↗]   │
│ Stacked theo Sales Channel và trạng thái · Số KH (CBM): N          │
│                                                                     │
│  GT     ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰  72,300                       │
│  MT     ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰              48,200                     │
│  KA     ▰▰▰▰▰▰▰▰▰▰▰▰                  32,500                     │
│  B2B    ▰▰▰▰▰▰                        16,000                     │
│  EXPORT ▰▰▰▰                          11,200                     │
│  OTHER  ▰▰                            4,800                      │
│                                                                     │
│  Legend: 7 entries                                                 │
└────────────────────────────────────────────────────────────────────┘
Layout: vertical (horizontal bars), YAxis category
Height: clamp(480, rows*200, 1400)
Same pattern as Chart 1 (Region)
```

---

## Tab Chi tiết bảng — 9 WidgetGrid

### DSHFLADTG01 — Report tỷ lệ hoàn thành (page 20)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Tên kho       │ Kênh │ Khu vực  │ Mục tiêu │ Hoàn thành │ Còn lại │ %  │
│ ▼filter       │▼filter│ ▼filter  │  sort↕   │   sort↕   │  sort↕  │sort│
├───────────────┼──────┼──────────┼──────────┼────────────┼─────────┼────┤
│ Kho trong-BKD │ GT   │ South E  │  18,500  │  16,200 ✓ │ 2,300 ⚠ │88% │
│ Kho ngoài-NKD │ MT   │ Mekong 1 │  12,800  │  11,400 ✓ │ 1,400 ⚠ │89% │
│ Kho BEE_BKD   │ KA   │ Mekong 2 │  10,200  │   8,800 ✓ │ 1,400 ⚠ │86% │
│ ...           │      │          │          │            │         │    │
└───────────────┴──────┴──────────┴──────────┴────────────┴─────────┴────┘
Synthetic fallback: 54 rows (6 WH × 3 Channel × 3 Area) khi tblCompletion rỗng
Style: green = Hoàn thành, amber = Còn lại, indigo = % Hoàn thành
```

### DSHFLADTG02 — Báo cáo chi tiết E2E (page 10)

```
┌────────────────────────────────────────┐
│ Trạng thái       │ Volume    │ UOM     │
│ sort↕           │  sort↕    │ readonly│
├──────────────────┼───────────┼─────────┤
│ Kế hoạch xuất    │  125,400  │  CSE    │  ← color: #0EA5E9
│ Tổng thực xuất   │   95,100  │  CSE    │  ← color: #16A34A
│ Chưa xuất kho    │   12,300  │  CSE    │  ← color: #858585
│ Đang xuất kho    │   18,000  │  CSE    │  ← color: #E18719
│ Đã xuất kho      │   20,500  │  CSE    │  ← color: #4F2170
│ Đang vận chuyển  │   35,600  │  CSE    │  ← color: #2D6EAA
│ Đã vận chuyển    │   39,000  │  CSE    │  ← color: #287819
└──────────────────┴───────────┴─────────┘
(7 rows fixed)
UOM column: format theo applied.uom (CSE / TON / CBM / PALLET / DO-line)
```

### DSHFLADTG03-06 — Summary tables (page 10 each, cùng schema)

```
┌─────────────────────────────────────────────────────────────┐
│ Chiều             │ Tổng     │ Hoàn thành │ Đang chờ │ %   │
│ text▼            │  sort↕   │   sort↕    │  sort↕   │sort↕│
├───────────────────┼──────────┼────────────┼──────────┼─────┤
│ {dim values}      │ N,NNN    │  N,NNN ✓  │ N,NNN ⚠  │ N%  │
│ ...               │          │            │          │     │
└───────────────────┴──────────┴────────────┴──────────┴─────┘
T3: Tổng hợp theo kho       — Chiều = whseid
T4: Tổng hợp theo NPP/Customer — Chiều = customer name
T5: Tổng hợp theo khu vực   — Chiều = region
T6: Tổng hợp theo kênh bán  — Chiều = group_name
Style: green = Hoàn thành, amber = Đang chờ, indigo = % Done
```

### DSHFLADTG07 — Report hàng rớt (page 20)

```
┌────────────────────────────────────────────────────────────────────┐
│ Delivery to        │ DRY&FRESH│ POSM(PC) │ % DRY& │ % POSM         │
│ Customer (bucket)  │ (CSE)    │          │ FRESH  │                │
│ ▼filter            │ sort↕    │ sort↕    │ sort↕  │ sort↕          │
├────────────────────┼──────────┼──────────┼────────┼────────────────┤
│ Tổng kế hoạch CS   │  85,200  │  12,400  │  100%  │   100%         │
│ Xử lý thành công   │  72,500  │  10,800  │   85%  │    87%         │
│ Đang xử lý         │   8,200  │   1,000  │   10%  │     8%         │
│ Xử lý ko thành     │   4,500  │     600  │    5%  │     5%         │
│ công               │          │          │        │                │
└────────────────────┴──────────┴──────────┴────────┴────────────────┘
(4 rows fixed; bucket classification dùng substring match trên delivery_to_customer)
```

### DSHFLADTG08 — Report lý do rớt đơn (page 10)

```
┌────────────────────────────────────────────────────┐
│ Remark           │ FRESH/DRY (CSE) │ POSM (PC)    │
│ ▼filter         │   sort↕         │   sort↕      │
├──────────────────┼─────────────────┼──────────────┤
│ Hết hàng        │     2,800       │     320      │
│ Sai đơn         │     1,200       │     150      │
│ Khách hủy       │       500       │      80      │
│ ...             │                 │              │
└──────────────────┴─────────────────┴──────────────┘
Group by remark_2 / remark2 / reason field
```

### DSHFLADTG09 — Chi tiết Flash (page 20, 32 cột)

```
┌─────────────────────────────────────────────────────────────────────┐
│ SO       │ Order  │ STATUS│ TT đơn   │ TT đơn   │ Item    │ Tên   │
│          │ type   │       │ hàng     │ DO       │ Code    │ hàng  │
│ text▼   │ text▼ │text▼ │ text▼   │ text▼   │ text▼  │ text▼│
├──────────┼────────┼───────┼──────────┼──────────┼─────────┼───────┤
│84830000  │ DO     │ Active│ Đã xuất  │ Đã vận   │ITEM001  │ ...   │
│84830001  │ DO     │ Active│ Đang     │ Đang vận │ITEM002  │ ...   │
│ ...      │        │       │          │          │         │       │
└──────────┴────────┴───────┴──────────┴──────────┴─────────┴───────┘

+ Group of Cago | Group | Customer Code | Customer Name | Khu vực đội xe |
+ Tên ngắn NVT | Loại xe vận hành | Mã điểm nhận | Tên điểm nhận       |
+ ORIGINAL (UOM-aware) | SHIPPED (UOM-aware) | Sản lượng giao (UOM)   |
+ Thời gian gửi thầu | Delievery Date 1 [SIC] | ETD chuyến gửi thầu    |
+ ATD đến | ATD rời | Actual Ship Date | TG bắt buộc rời kho           |
+ Thời gian đi | ETA (Giao hàng cho NPP) | ATA đến | ATA rời           |
+ Số chuyến | Số xe | Mã nhà xe                                        |

Cell UOM-aware (cột 17/18/19):
  uom=cse  → {prefix}_cse raw value
  uom=ton  → "{kg/1000} Tấn ({kg} Kg)" via formatTonWithKg
  uom=cbm  → {prefix}_cbm raw
  uom=pallet → {prefix}_pl raw
  uom=do   → '-' (DO không có volume)
```

---

## Loading State

```
┌─────────────────────────────────────────────────────────┐
│  [████████████████████████████]   ← Skeleton h-20       │
│                                       (filter bar)      │
│                                                         │
│  [████] [████] [████] [████] [████] [████]   ← 6 cards │
│  h-20  h-20  h-20  h-20  h-20  h-20         (grid)      │
│                                                         │
│  [████████████████████████████████████████]             │
│   ████████████████████████████████████████              │
│   h-64 skeleton (chart placeholder)                     │
└─────────────────────────────────────────────────────────┘
isInitialLoading = isLoading && statusRows.length === 0
Refetch (placeholderData: prev) — KHÔNG hiển thị skeleton
```

## Error State

```
┌─────────────────────────────────────────────────────────┐
│  ⚠ {sqlError.message}                                   │
│    [red border, red bg/10]                              │
└─────────────────────────────────────────────────────────┘
Single banner — KHÔNG phân biệt query nào lỗi (xem spec §3.2)
```

---

## Empty Data State (KHÔNG có mock)

```
┌─────────────────────────────────────────────────────────┐
│  (Filter bar render bình thường)                        │
├─────────────────────────────────────────────────────────┤
│  Tab: [ Biểu đồ ] [ Chi tiết bảng ]                    │
├─────────────────────────────────────────────────────────┤
│  [KPI cards render với value 0]                         │
│  [Charts render container nhưng KHÔNG có bars]          │
│  [Tab Chi tiết: 9 WidgetGrid render header + empty]     │
└─────────────────────────────────────────────────────────┘

KHÁC OTIF: Flash Daily KHÔNG fallback mock 120 dòng.
Khi !hasSqlConfig → widgetReady=false → KHÔNG fetch → cards = 0.
```

---

## Responsive Behavior

| Breakpoint | KPI Cards | Chart E2E + Wh | Other charts | Filter Bar |
|-----------|-----------|----------------|--------------|------------|
| Mobile (`<sm`) | 1 cột | 1 cột stack | Full-width | Wraps |
| Tablet (`sm` to `<xl`) | 2 cột | 1 cột stack | Full-width | Wraps |
| Desktop (`xl+`) | 3 cột | 2 cột grid | Full-width | 1 row |

```
Mobile:                    Desktop (xl):
┌─────┐                    ┌─────┐ ┌─────┐ ┌─────┐
│ Card│                    │Card │ │Card │ │Card │
└─────┘                    └─────┘ └─────┘ └─────┘
┌─────┐                    ┌─────┐ ┌─────┐ ┌─────┐
│ Card│                    │Card │ │Card │ │Card │
└─────┘                    └─────┘ └─────┘ └─────┘
... (×4 more)              ┌─────────────────────┐
                           │ Chart Area          │
┌─────────────────────┐    └─────────────────────┘
│ Chart Area          │    ┌──────────┬──────────┐
└─────────────────────┘    │ Chart E2E│ Chart Wh │
┌─────────────────────┐    └──────────┴──────────┘
│ Chart E2E           │    ┌─────────────────────┐
└─────────────────────┘    │ Chart Customer      │
┌─────────────────────┐    └─────────────────────┘
│ Chart Wh            │    ┌─────────────────────┐
└─────────────────────┘    │ Chart Sales Channel │
...                        └─────────────────────┘
```

---

## Color Palette Summary

| Element | Hex | Usage |
|---------|-----|-------|
| Tổng Volume Kế hoạch | `#10B981` | Card 1 + accent |
| Chưa xuất kho | `#858585` | Card 2 + Status bar 1 |
| Đang xuất kho | `#E18719` | Card 3 + Status bar 2 |
| Đã xuất kho | `#4F2170` | Card 4 + Status bar 3 |
| Đang vận chuyển | `#2D6EAA` | Card 5 + Status bar 4 |
| Đã vận chuyển | `#287819` | Card 6 + Status bar 5 |
| Kế hoạch xuất (bar) | `#0EA5E9` (sky) | Bar 1 trong all charts |
| Tổng thực xuất (bar) | `#16A34A` (green) | Bar 2 trong all charts |
| Edit Settings button | Outline default | Setting Chart button |
| Edit Filter button | Amber `bg-amber-500/10` | Setting Filter chip |
| Done value (table) | `text-emerald-500` | Hoàn thành / Done columns |
| Pending value (table) | `text-amber-500` | Đang chờ / Còn lại columns |
| % value (table) | `text-indigo-400` | % Hoàn thành / % Done columns |
| Label number (chart) | `#9CA3AF` | LabelList text on bars |
| Error banner | `border-destructive/30 bg-destructive/10` | sqlError state |

### v1.1.0 storytelling palette additions

| Element | Hex / Token | Usage |
|---------|-------------|-------|
| RAG Green (≥95%) | `bg-emerald-500/10` + `text-emerald-600` | L1 hero, L5 bar, L3 funnel entry % |
| RAG Yellow (85-<95%) | `bg-amber-500/10` + `text-amber-600` | L1 hero, L5 bar |
| RAG Red (<85%) | `bg-red-500/10` + `text-red-600` | L1 hero, L5 bar, L2 exception card 1+3 left border |
| Alert banner (<80%) | `bg-red-500/10 border-red-500/30` | L1 hero overall alert |
| L2 exception amber card | `bg-amber-500/5 border-l-4 border-amber-500` | L2 "đơn rớt chưa xử lý" |
| L4 target line | solid `red-500`, y=5 | L4 reference line |
| L4 rolling 30d avg | dashed grey-400, dynamic | L4 secondary reference |
| L5 target line | solid grey-400, x=95% | L5 vertical reference |
| L3 STM caveat icon (📍) | `text-amber-500` | Tooltip ở 2 KPI status "Đã xuất kho" + "Đang vận chuyển" |

---

## Change history

| Version | Ngày | Tác giả | Thay đổi |
|---------|------|---------|---------|
| 1.0.0 | 2026-05-16 | PM/DA via `/da-trace` | Observed baseline ASCII wireframe — 6 KPI cards + 5 chart + tab 9 grid + filter bar. |
| 1.1.0 | 2026-05-16 | PM/DA via `/da-biz-ba` | Storytelling refresh. (1) Thêm Layout v2 Overview 6 levels L1-L6 ở đầu file. (2) Thêm 5 ASCII wireframe section: L1 Hero (full-width % completion + RAG + target 95% + sub-numbers Plan/Đã giao/Còn lại), L2 Exception 3-column (kho off-target / đơn rớt / khu vực dưới target), L3 Funnel strip 5 entries, L4 Drop Trend line chart 14 ngày + target ≤5% solid + rolling 30d dashed, L5 Tabbed dimension drilldown (Kho/Khu vực/Khách/Kênh, worst-first, target 95% line). (3) Giữ nguyên L6 Detail Tables (9 bảng — D2 defer) + section v1.0.0 baseline để compare. (4) Update Color Palette với RAG bands + L4/L5 reference line colors. |
