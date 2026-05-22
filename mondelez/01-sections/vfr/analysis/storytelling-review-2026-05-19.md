# Storytelling Review — VFR Widget (Mondelez)

**Skill:** `/da-storytelling-data` Mode C — Critique
**Date:** 2026-05-19
**Reviewer:** Persona SC/Logistics Data Storytelling advisor (15+ năm SC)
**Artifacts reviewed:**
- [`vfr-prd.md`](../vfr-prd.md) (342 lines)
- [`vfr-spec.md`](../vfr-spec.md) (345 lines)
- [`vfr-wireframe.md`](../vfr-wireframe.md) (247 lines)

> Output → drives [`docs/feature/vfr-storytelling-refresh/dev/plan.md`](../../../../docs/feature/vfr-storytelling-refresh/dev/plan.md)

---

## C2 — Critique theo 5 chiều

| Chiều | Score | Lý do |
|---|---|---|
| **Narrative clarity** | 🔴 Fail | 0 action titles. Tất cả chart titles là label thuần ("VFR theo Khu vực"). KPI cards chỉ snapshot, không vs target/trend. |
| **Hierarchy** | 🟡 Warning | L1 có 5 cards equal weight (Avg + 4 buckets) — không có hero number. Thiếu L2 exception panel. L3-L4 đầy đủ. |
| **Chart fit** | 🟡 Warning | Dual Y-axis trên chart Area/Vehicle (anti-pattern). 5-bucket color scheme không follow RAG (tím/đỏ/vàng/xanh dương/xanh lá — user không có muscle memory). Không có target reference line ở chart nào. |
| **Exception visibility** | 🔴 Fail | Card "Low <50%" hiện count `38` nhưng không drill-from-card. Không có hot list "N chuyến cần check hôm nay". Time × Area cells flat color — không RAG-highlight ô <70%. |
| **Audience fit** | 🟡 Warning | PRD §2 list 4 persona (BOD/Logistics/Carrier/Planning) nhưng tất cả xem cùng 1 screen. BOD không cần grid 29 cột; Carrier cần "VFR by Vendor" ở L3. |

---

## C3 — Issues (10 phát hiện)

### 🔴 Critical (decision-affecting)

1. **No action titles** ở bất kỳ chart/table nào. User phải tự tính delta. Chart 1-3 chỉ là label "VFR theo X".
2. **GT vs VH delta bị ẩn sau toggle.** Insight quan trọng nhất là "GT plan 85% nhưng VH thực tế 72%, tại sao?". Toggle pattern (PRD §17 D1) buộc serial scan, mất khả năng spot delta — đặc biệt tệ cho Planning persona.
3. **Không có target line / RAG threshold visible.** 72% là tốt hay xấu? Không có target band trên chart, không có vs-target trên KPI card. Mondelez chưa khai báo target VFR.
4. **Exception count không actionable.** Card "Low <50% — 38 chuyến" là dead-end. User phải mở Detail tab + filter VFR<50 + sort thủ công. Mất 4-5 click cho insight đáng lẽ 1.

### 🟡 Warning

5. **Dual Y-axis trên chart 1 (Area) + chart 2 (Vehicle).** Skill anti-pattern: scale confusion. Nên tách hoặc bỏ Bar Planned, dùng RAG color cho Line.
6. **5-bucket color scheme không follow RAG.** Avg = tím, Excellent = xanh lá — user phải learn lại. Nên gradient theo direction.
7. **Time × Area table flat color.** Period × Area matrix là nơi spot "khu vực Mekong 1 kẹt 3 tháng liên tiếp" — không có conditional RAG.
8. **One-size-fits-all screen cho 4 personas.** Không có preset "BOD view" / "Ops view" / "Carrier view".
9. **Loose+FP weighted formula quá phức tạp cho end-user.** 8 sub-metrics tooltip = smell. OQ-04 chưa đóng.
10. **Silent error state.** Không banner, không retry — user nhìn empty chart không biết là "no data" hay "fetch fail".

### 🟢 Good (giữ lại)

- Drift log PRD §17 — gold standard tracing PRD vs impl, đặc biệt D1 (toggle), D6 (late-alert scope).
- Mode toggle GT/VH **as a data-source switch** là đúng (2 MVs khác nhau).
- Wireframe tách rõ section `vfr-prd` / `vfr-spec` / `vfr-wireframe` theo memory.
- PRD §13 "Late alert" call-out raise scope sớm.

---

## C4 — Concrete fixes (8 fixes → plan.md)

### Fix 1 — Action titles (mọi chart)

```
❌ "VFR theo Khu vực"
✅ "Mekong 1 kéo VFR xuống 58% — thấp nhất 6 khu vực, hụt target 22 điểm"

❌ "VFR theo Loại xe"
✅ "Xe 24T chỉ đầy 56% — đề xuất ghép hàng / chuyển 8T cho lane này"

❌ "VFR theo Loại bốc xếp & Thời gian"
✅ "Box pallet cải thiện 65→72% trong 3 tháng; Loose ổn định 78%"

❌ "VFR theo thời gian và khu vực"
✅ "Mekong 1 kẹt <60% suốt 3 tháng — pattern hệ thống, không phải spike"
```

Title phải auto-generate từ data (top mover, biggest gap), KHÔNG hardcode.

### Fix 2 — L1 hero card + GT vs VH delta luôn visible

```
┌──────────────────────────────────────────────────────────┐
│  VFR Trung bình         vs Target 80%      Trend 13w     │
│                                                          │
│   72%   🟡    Gap −8 pts    ▁▂▃▃▅▄▅▆▆▇▅▄▅                │
│                                                          │
│  ─────────────────────────────────────────────────       │
│  GT (thầu)  85%   │   VH (vận hành) 72%   │  Δ −13       │
│   🟢                  🟡                       ⚠️         │
│  Plan tốt → thực thi rớt: kiểm tra ghép hàng + carrier    │
└──────────────────────────────────────────────────────────┘
```

### Fix 3 — L2 Exception panel (mới)

```
┌──────────────────────────────────────────────────────────┐
│  ⚠️  38 chuyến VFR <50% trong 7 ngày — cần action        │
│                                                          │
│  Top khu vực:  Mekong 1 (12) │ Ha Noi (8) │ HCM (7)     │
│  Top vendor:   NGUYEN PHAT (15) │ HDA (9) │ NINJAVAN (5)│
│  Top loại xe:  24T (18) │ 15T (11) │ Cont (6)           │
│                                                          │
│  [Xem 38 chuyến →]   [Export CSV]   [Assign owner]      │
└──────────────────────────────────────────────────────────┘
```

### Fix 4 — Chart 1+2 đổi sang Bar sorted + RAG color (bỏ dual axis)

```
By Area (sorted ascending, color = RAG vs 80% target):
   Mekong 1   🔴 ████████ 58%       │← exception
   Mekong 2   🔴 █████████ 62%      │
   HCM        🟡 ██████████ 69%     │
   Ha Noi     🟢 ████████████ 81%   │← target line
   South East 🟢 █████████████ 84%  │
   North East 🟢 █████████████ 85%  │
                                     │
            ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄ 80% target ┄┄
```

### Fix 5 — Time × Area cells RAG-color

```
Thời gian │ South E │ HCM    │ Mekong 1│ Ha Noi  │ Trung bình
2026-03   │ 🟢 72%  │ 🟡 68% │ 🔴 58%  │ 🟢 80%  │ 71.2%
2026-04   │ 🟢 75%  │ 🟢 70% │ 🔴 62%  │ 🟢 82%  │ 73.5%
2026-05   │ 🟢 71%  │ 🟡 69% │ 🔴 60%  │ 🟢 81%  │ 72.0%
```

### Fix 6 — Add chart 4 "VFR by Vendor"

Persona Carrier Management cần chart này ở primary view, không phải filter. Sorted bar VFR% per vendor + count chuyến.

### Fix 7 — Persona presets

| Preset | L1 | L2 exception | L3 charts | L5 grid |
|---|---|---|---|---|
| `preset-om-vfr-bod` | ✅ hero only | — | trend 13w | — |
| `preset-om-vfr-ops` | ✅ | ✅ | — | ✅ (filtered VFR<70) |
| `preset-om-vfr-carrier` | ✅ | — | by Vendor + by Lane | ✅ |
| `preset-om-vfr-planning` (default) | ✅ | ✅ | all 4 | ✅ |

### Fix 8 — Đóng Open Questions ưu tiên cao

- **OQ-04** (Loose+FP formula): nếu data team không xác nhận → revert headline về `MAX(VFR Tấn, VFR Khối)` simple. Formula 8-biến hiện tại chỉ làm tooltip phụ.
- **OQ-03** (target VFR Mondelez): chốt với SC Manager — propose **80% overall**, RAG bands 70/80 (10pt buffer vì variance theo lane/xe cao hơn OTIF).
- **OQ-05** (late-alert scope): cần PM trả lời TRƯỚC khi merge branch.

---

## Delivery Signal

```
STORYTELLING REVIEW COMPLETE
──────────────────────────────────
Mode          : C-Critique
Section       : Mondelez / 01-sections / vfr
Audience      : PRD list 4 personas, hiện chỉ phục vụ chung 1 view
──────────────────────────────────
Key decisions :
  - Action titles bắt buộc cho 5 charts/tables
  - L1 hero card phải show GT vs VH delta luôn (không ẩn sau toggle)
  - Thêm L2 exception panel — drill 1-click sang grid pre-filtered
  - Bỏ dual Y-axis; chuyển sang sorted bar + RAG vs target
  - Tạo 4 persona presets (BOD / Ops / Carrier / Planning)
  - Chốt target VFR với SC Manager — proposal 80% overall
Issues found  : 4 critical / 6 warning / 4 good
Next step     : Plan + tasks + context created at docs/feature/vfr-storytelling-refresh/dev/
                Awaiting PM approval Q0-Q6 trước khi /frontend kick off Phase 1
──────────────────────────────────
```
