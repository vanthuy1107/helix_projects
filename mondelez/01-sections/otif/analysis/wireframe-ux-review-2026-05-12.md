# OTIF Section — Wireframe UX Review & Re-layout Proposal

> **Type**: Business UX analysis (skill `/da-biz-ba`) — phân tích layout hiện tại từ góc nhìn người dùng vận hành, đề xuất phương án cải thiện density & insight-first.
> **Tenant**: Mondelez
> **Date**: 2026-05-12
> **Source artifact**: [`../wireframe.md`](../wireframe.md) v1.1.0 + code thực tế [`frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx`](../../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx)
> **Audience**: PM/BA, Operation Manager (Mondelez SC), Dispatcher
> **Status**: Proposal — chưa duyệt

---

## 1. Phản hồi gốc & tóm tắt

> "Hiện tại wireframe đang chưa thân thiện với người dùng vì màn hình chỉ nhìn được 1-2 chart, rất khó để thấy được insight." — squad1@gosmartlog.com, 2026-05-12

→ Đây là **density problem** (mật độ thông tin trên 1 fold quá thấp) **và** **hierarchy problem** (không có Tier 1 vs Tier 2 → mọi chart đều to ngang nhau, user không biết nhìn cái gì trước).

---

## 2. Đo đạc hiện trạng (Observed — không suy luận)

### 2.1 Chiều cao thực tế của Tab Chart (đo từ source code)

| # | Block | Class | Component height | Effective height (gồm card + padding ~80px) |
|---|---|---|---|---|
| 1 | Filter bar sticky | — | ~80px | 80px |
| 2 | Tab bar [Chart][Chi tiết] | — | ~40px | 40px |
| 3 | KPI 4 cards | `grid-cols-2 xl:grid-cols-4` | ~80px (card) | 140px (gồm gap) |
| 4 | Fail Ontime + Fail Infull (2 cột) | `grid-cols-1 xl:grid-cols-2` + `h-64` | 256px | ~330px |
| 5 | Trend chart | `h-72` | 288px | ~370px |
| 6 | Chart by Transporter | `h-72` | 288px | ~370px |
| 7 | Chart by Category (NEW FEAT-128) | `h-72` | 288px | ~370px |
| 8 | Chart by Sales Channel | `h-72` | 288px | ~370px |
| 9 | Chart by Warehouse | `h-72` | 288px | ~370px |
| 10 | Chart by Area | `h-72` | 288px | ~370px |

**Tổng chiều cao Tab Chart ở viewport `xl`**: ≈ **2,810px**

**Viewport tham chiếu**:
- Laptop 14" (1366×768) — content area ≈ 600–650px sau khi trừ chrome browser + sidebar
- Desktop 24" (1920×1080) — content area ≈ 900–950px

→ User cần **scroll ~3.5 fold** trên laptop, **~3 fold** trên desktop để xem hết Tab Chart.
→ Ở fold đầu tiên (laptop 14"): chỉ thấy KPI 4 cards + ~½ Fail charts. **Không thấy được Trend hoặc bất kỳ dimension chart nào** trước khi scroll → khớp 100% phản hồi gốc.

### 2.2 Tỷ lệ "ink" hữu ích trên 1 fold

| Fold | Nội dung | Insight gain |
|---|---|---|
| 1 | KPI cards + ½ Fail charts | Biết %OTIF tổng, chưa biết tại sao fail |
| 2 | ½ Fail + Trend | Biết lý do fail + xu hướng |
| 3 | Transporter + Category | So sánh 2 chiều |
| 4 | Sales Channel + Warehouse + Area | So sánh 3 chiều còn lại |

→ Câu hỏi quan trọng nhất của Ops Manager — "**hôm nay vấn đề ở đâu, NVC nào, kho nào, mặt hàng nào?**" — chỉ được trả lời sau khi scroll xuống fold 3-4. Đây là anti-pattern cho ops dashboard.

### 2.3 Pattern lặp lại

5 dimension charts (Transporter / Category / Sales Channel / Warehouse / Area) đều cùng cấu trúc:

- Grouped bar chart, 3 metric (Ontime/Infull/OTIF)
- Y-axis 0-100%
- Height = 288px
- Width = full-row

→ User phải nhìn **5 chart giống nhau về cấu trúc** chỉ để so sánh 5 chiều khác nhau. Đây là cơ hội lớn để consolidate.

---

## 3. Pain points (root cause)

| # | Pain | Evidence | Stakeholder ảnh hưởng |
|---|---|---|---|
| P1 | Trên fold đầu KHÔNG có cảnh báo "vấn đề ở đâu" — chỉ có KPI tổng | Đo đạc 2.1, fold 1 chỉ tới ½ Fail charts | Operation Manager, Dispatcher |
| P2 | Phải scroll 3-4 fold mới so sánh được 5 chiều (NVC/Kho/SC/Cat/Area) | Đo đạc 2.1, total 2810px | Operation Manager, Account Manager |
| P3 | 5 dimension chart cùng pattern lặp lại — user mỏi mắt + xử lý thị giác chậm | Phân tích 2.3 | Tất cả |
| P4 | Trend chart full-width nhưng nội dung thưa (1 line + 1 bar) | Width full ≈ 1400px, dữ liệu chỉ cần ~600px | Mọi user trên desktop |
| P5 | Không có cross-filter giữa các chart — click NVC "HVP" trên chart Transporter KHÔNG filter các chart còn lại | Đọc code `widget-otif.tsx`: mỗi chart query độc lập, không share state | Operation Manager (khi drill-down) |
| P6 | "Lý do fail" 2 chart side-by-side ăn 1 fold quan trọng, nhưng đây là Tier 2 (drill-down), không phải Tier 1 (alert) | Layout hiện tại đặt fail reason ngay sau KPI | Stakeholder muốn KPI → Alert → Drill-down |
| P7 | Mobile (`<xl`): KPI 4 cards xếp 2x2 (4 hàng) + 5 dimension charts full-width = scroll dài gấp đôi | Class `grid-cols-2 xl:grid-cols-4` | Mobile users (rare nhưng tồn tại) |

---

## 4. Câu chuyện stakeholder (hỏi đúng câu)

Khi Operation Manager Mondelez mở dashboard OTIF lúc 9:00 sáng, họ KHÔNG đọc lần lượt từ trên xuống. Họ scan theo thứ tự ưu tiên:

```
1. %OTIF hôm nay có "đỏ" không?              ← KPI tổng (≤ 2 giây)
2. Nếu đỏ — vấn đề ở chiều nào?               ← Heatmap 5 dimensions (≤ 10 giây)
3. Lý do fail là gì?                          ← Fail reason (≤ 20 giây)
4. Xu hướng có xấu đi không?                  ← Trend (≤ 30 giây)
5. Cần action gì?                             ← Drill-down chi tiết
```

Layout hiện tại đang ép thứ tự là **1 → 3 → 4 → 2 → 5**, lệch với mental model.

---

## 5. Phương án đề xuất

Có 4 phương án từ ít rủi ro tới triệt để. Tôi recommend **Phương án C** (hybrid).

### Phương án A — "Compact heights" (rủi ro thấp, lợi ích nhỏ)

- Giảm height của 5 dimension charts từ `h-72` (288px) → `h-56` (224px)
- Đặt 5 charts vào grid `xl:grid-cols-2` → 3 hàng thay vì 5 hàng
- Trend chart giảm xuống `h-56`

**Kết quả**: Tab Chart từ 2810px → ~1900px (-32%). Vẫn 2 fold nhưng dễ thở hơn.

**Pros**: Đơn giản, chỉ đổi class, không cần redesign component, không phá AC khác.
**Cons**: KHÔNG giải quyết P5 (cross-filter), P6 (hierarchy). Vẫn chưa "insight-first".

---

### Phương án B — "Tab dimension switcher" (gọn nhưng mất so sánh chéo)

Gộp 5 dimension charts vào **1 chart duy nhất** với tab chọn dimension:

```
┌──────────────────────────────────────────────────────────┐
│ Phân tích theo chiều [NVC][Kho][SC][Loại hàng][Khu vực] │
│ [BarChart grouped, h=288px]                              │
└──────────────────────────────────────────────────────────┘
```

**Kết quả**: Tab Chart từ 2810px → ~1330px (-53%). Tất cả vừa 1.5-2 fold.

**Pros**: Tiết kiệm không gian tối đa.
**Cons**: Mất khả năng so sánh chéo (Ops Manager hay phải so NVC vs Kho để định danh root cause). User phải click switch tab nhiều lần → friction tăng.

---

### Phương án C — "Cockpit / Tier-based" (RECOMMENDED)

Tổ chức lại 3 tầng thông tin:

**Tier 1 — Above the fold (1 màn hình laptop ≈ 600-650px)**
- KPI 4 cards (compact, ~100px)
- Health snapshot: **Heatmap matrix** thay 5 charts (~280px) — rows = 5 dimensions, cells = %OTIF color-coded
- Mini trend sparkline 14 ngày (~80px)
- **→ User trả lời được 3 câu hỏi đầu chỉ trên 1 fold**

**Tier 2 — Scroll 1 lần (fold 2)**
- 2 Fail Reason charts (giữ nguyên `h-64`)
- Trend chart compact (`h-56`)
- Layout: `xl:grid-cols-3` (fail ontime | fail infull | trend) cùng hàng

**Tier 3 — Click-to-expand**
- Khi click 1 row trên heatmap → expand chart grouped-bar full detail (như hiện tại) cho dimension đó
- 5 charts dimension vẫn tồn tại nhưng **ẩn mặc định, expand on demand**

**Kết quả**: Tab Chart Tier 1+2 ≈ **1200px**. Fold 1 chứa đủ alert. Fold 2 chứa root cause + trend. Drill-down chuyển sang Tab Chi tiết (đã có sẵn).

**ASCII mockup**:

```
┌──────────────────────────────────────────────────────────────────────┐
│ [Sticky Filter Bar]                                  [⚙ SQL] [Apply] │
├──────────────────────────────────────────────────────────────────────┤
│ Tab: [Chart] [Chi tiết]                                              │
├──────────────────────────────────────────────────────────────────────┤
│ TIER 1 — Snapshot (above the fold)                                   │
│ ┌────────┐┌────────┐┌────────┐┌────────┐  ← KPI compact 4-col h~100│
│ │ Total  ││%Ontime ││%Infull ││ %OTIF  │                            │
│ │ 1,250  ││ 97.3%  ││ 94.1%  ││ 91.8%  │                            │
│ └────────┘└────────┘└────────┘└────────┘                            │
│                                                                       │
│ ┌─────────────────────────────────┬──────────────────────────────┐  │
│ │ Health Matrix — %OTIF theo chiều│  Mini Trend 14 ngày  [→Full] │  │
│ │ (click row để xem detail)        │  ●─●─●─●─●─●─●─●─●─●─●─●─●  │  │
│ │              %OTIF  %On   %In    │  91.2  90.5  91.8  91.4 ... │  │
│ │ NVC                              │                              │  │
│ │   HVP        🟢95%  97%  98%     │  Total 14d: 14,820 DO        │  │
│ │   TLL        🟡88%  92%  94%     │                              │  │
│ │   SVL        🔴72%  78%  85%  ← │                              │  │
│ │ Kho                              │                              │  │
│ │   BKD1       🟢94%  96%  97%     │                              │  │
│ │   NKD        🔴68%  75%  82%  ← │                              │  │
│ │ Loại hàng                        │                              │  │
│ │   FRESH      🟡85%  89%  91%     │                              │  │
│ │   DRY        🟢93%  96%  96%     │                              │  │
│ │ Khu vực, Sales Channel ...       │                              │  │
│ └─────────────────────────────────┴──────────────────────────────┘  │
│                                                                       │
│ ─────────────── Scroll line: fold 1 hết ở đây ───────────────────    │
│                                                                       │
│ TIER 2 — Root cause & Trend                                          │
│ ┌──────────────┬──────────────┬────────────────────────────────┐    │
│ │ Lý do fail   │ Lý do fail   │ %OTIF theo thời gian           │    │
│ │ ontime       │ infull       │ [Day][Week][Month]             │    │
│ │ [bar h=224]  │ [bar h=224]  │ [composed h=224]               │    │
│ └──────────────┴──────────────┴────────────────────────────────┘    │
│                                                                       │
│ TIER 3 — Drill-down (collapsed by default)                           │
│ ▶ Xem chi tiết theo NVC                                              │
│ ▶ Xem chi tiết theo Kho                                              │
│ ▶ Xem chi tiết theo Loại hàng                                        │
│ ▶ Xem chi tiết theo Sales Channel                                    │
│ ▶ Xem chi tiết theo Khu vực                                          │
│   (click → expand grouped-bar h=288 như hiện tại)                    │
└──────────────────────────────────────────────────────────────────────┘
```

**Pros**:
- Giải quyết P1, P2, P3, P4, P6 cùng lúc
- Insight-first đúng mental model Ops Manager
- Heatmap matrix tận dụng 1 màn hình so sánh được 15-25 row (5 chiều × 3-5 giá trị/chiều) — nhanh gấp 5 lần đọc 5 bar chart
- Drill-down giữ nguyên feature hiện có → không phá AC
- Backward compatible: detail charts vẫn tồn tại, chỉ collapsed

**Cons**:
- Cần component mới `OtifHealthMatrix` (effort ~3-5 ngày dev)
- Cần SQL bổ sung trả về dữ liệu 5 dimensions cùng lúc (hoặc reuse 5 SQL hiện có)
- Threshold màu (🟢🟡🔴) cần business confirm (vd: ≥95% green, 85-95% yellow, <85% red) — **EVIDENCE_GAP**

---

### Phương án D — "Multi-dashboard split" (triệt để nhất, effort cao)

Tách Tab Chart hiện tại thành 3 sub-tab:

- **Snapshot**: KPI + mini trend (1 fold)
- **Root Cause**: Fail reason + dimension breakdown (1 fold)
- **Trend**: Full trend với multiple metrics (1 fold)

**Pros**: Mỗi sub-tab đúng 1 fold, không scroll.
**Cons**: User phải click giữa các tab nhiều lần. Mất context "tổng quan 1 lần nhìn". Effort dev cao nhất.

---

## 6. So sánh phương án (decision matrix)

| Tiêu chí | A. Compact | B. Tab switch | **C. Cockpit** | D. Multi-tab |
|---|---|---|---|---|
| Giải quyết "1-2 chart per fold" | ⚠️ Một phần | ✅ | ✅ | ✅ |
| Insight-first hierarchy | ❌ | ⚠️ Trung bình | ✅ | ⚠️ Trung bình |
| Giữ khả năng so sánh chéo | ✅ | ❌ | ✅ | ⚠️ Một phần |
| Effort dev | 0.5 ngày | 2 ngày | **3-5 ngày** | 5-7 ngày |
| Rủi ro phá AC khác | Thấp | Trung bình | **Trung bình** | Cao |
| Cần SQL mới | Không | Không | Có (heatmap aggregate) | Không |
| Cần business confirm threshold | Không | Không | **Có (🟢🟡🔴)** | Không |
| Stakeholder feedback dự kiến | "Đỡ hơn chút" | "Mất so sánh" | **"Đúng cái tôi cần"** | "Phải click nhiều" |

**Recommendation: Phương án C — Cockpit/Tier-based.**

---

## 7. Roadmap thực thi (nếu chọn C)

### Phase 0 — Confirm (1-2 ngày)
- Workshop 30 phút với Ops Manager Mondelez xác nhận:
  - Thứ tự ưu tiên 5 dimensions (cái nào quan trọng nhất → đặt đầu heatmap)
  - Threshold màu (🟢/🟡/🔴) cụ thể
  - Tier 3 nên collapsed hay vẫn show ở dạng card thumbnail
- Output: **assessment.md** update với decisions

### Phase 1 — Quick win (Phương án A, 0.5 ngày)
- Đổi `h-72` → `h-56` cho 5 dimension charts
- Đặt 5 charts vào `xl:grid-cols-2` thay vì full-width
- Deploy ngay → user thấy đỡ ngay trong tuần

### Phase 2 — Cockpit core (3-5 ngày)
- Component mới `OtifHealthMatrix` với rows-by-dimension, color-coded cells
- Compact KPI cards (`h-20`)
- Mini sparkline reuse `Recharts` Line + ResponsiveContainer
- Tier 3 dùng `Collapsible` của Shadcn

### Phase 3 — Polish (1-2 ngày)
- Click row trên matrix → scroll smooth + auto-expand dimension chart tương ứng
- Mobile layout: matrix chuyển sang scrollable horizontal
- A11y: keyboard navigation cho matrix

**Total effort**: ~5-8 ngày dev (1 BE + 1 FE), 2 ngày BA/UX review.

---

## 8. Open questions (cần stakeholder confirm)

| # | Câu hỏi | Owner | Why it matters |
|---|---|---|---|
| Q1 | Threshold màu cho Health Matrix là gì? (vd: ≥95/85-95/<85) | Ops Manager Mondelez | Quyết định cell coloring — sai threshold = signal sai |
| Q2 | Thứ tự ưu tiên 5 dimensions trên matrix? | Ops Manager | NVC > Kho > Loại hàng > SC > Area, hay khác? |
| Q3 | Có cần "click row matrix → cross-filter các chart khác" không? | Ops Manager + PM | Nếu có, scope tăng thêm 2-3 ngày |
| Q4 | Mini sparkline 14 ngày dùng metric gì? %OTIF tổng hay 3 line (Ontime/Infull/OTIF)? | Ops Manager | 1 line đơn giản, 3 line giàu thông tin hơn |
| Q5 | Tier 3 (5 dimension charts) nên collapsed default hay hiển thị thumbnail? | UX preference | Collapsed = gọn hơn; thumbnail = đỡ ẩn feature |

---

## 9. Memory để lưu (nếu user duyệt phương án này)

> Anti-pattern phát hiện: Dashboard layout liệt kê N chart cùng cấu trúc full-width là information density thấp. Cần consolidate qua heatmap/matrix khi N ≥ 4.

> Mental model Ops Manager Mondelez: scan theo thứ tự "%OTIF tổng → vấn đề ở chiều nào → lý do → xu hướng → action". Layout phải khớp thứ tự này.

(Sẽ chỉ save sau khi user xác nhận pattern này áp dụng cho các section khác như Tender, Flash Daily, Transaction Move.)

---

## 10. Linked artifacts

- Wireframe hiện tại: [`../wireframe.md`](../wireframe.md) v1.1.0
- Assessment tháng 5: [`./assessment-2026-05-10.md`](./assessment-2026-05-10.md)
- FEAT-057 analysis: [`./feat-057-analysis.md`](./feat-057-analysis.md)
- Pulse W19: [`./pulse-W19-2026-05-04_2026-05-09.md`](./pulse-W19-2026-05-04_2026-05-09.md)
- PRD section: [`../prd.md`](../prd.md)
- Source code: [`frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx`](../../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx)

---

**ARTIFACT_PATH**: `projects/mondelez/01-sections/otif/analysis/wireframe-ux-review-2026-05-12.md`

**EVIDENCE_GAPS**:
- Q1-Q5 (mục 8) — tất cả cần Ops Manager Mondelez confirm trước khi đi tiếp Phase 0 → Phase 2
- Đo đạc viewport "1 fold" giả định laptop 14" / desktop 24"; nếu user Mondelez chủ yếu dùng resolution khác (vd: 4K, ultrawide) → cần re-measure
- "Mental model Ops Manager" mục 4 là `Assumed` (BA suy luận từ kinh nghiệm dashboard ops), chưa có biên bản phỏng vấn Mondelez Ops Manager để verify

**HANDOFF_TO**:
- Nếu user duyệt Phương án C: chuyển sang `/ba` để viết PRD cho `OtifHealthMatrix` component → `/planner` để technical plan → `/frontend` + `/backend` implement
- Nếu user duyệt quick win Phương án A trước: chuyển thẳng `/frontend` với scope hẹp (đổi class layout)
- Nếu cần workshop với Ops Manager: dùng `/da-biz-ba` lần nữa để chuẩn bị discussion guide
