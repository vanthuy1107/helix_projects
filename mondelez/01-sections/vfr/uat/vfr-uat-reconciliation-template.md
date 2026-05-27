# UAT Reconciliation Matrix — VFR — Mondelez

**Section:** `vfr` · **Window:** 2026-05-18 → 2026-05-22 · **Filter:** ALL / ETA / 5 dim
**Source:** `mv_vfr_gui_thau` (GT) · `mv_vfr_van_hanh` (VH)
**Target:** 85% · **RAG:** 🟢≥85 / 🟡75–<85 / 🔴<75

> Sheet Excel song hành: `vfr-uat-numbers-2026-05-18_to_2026-05-22.xlsx` (sheet 01 KPI, 02 Dim, 03 Trend, 04 Detail, 07 SQL Appendix).

Mode B sẽ fill cột **Dashboard** + **Golden** từ screenshot + golden file MDLZ. Mode A để trống (placeholder `<chưa fill>`).

---

## Block 1 — Hero KPI (Avg VFR + Δ + buckets)

### 1.1 Mode GT (Tender) — `mv_vfr_gui_thau`

| Metric | Tolerance | SQL value (Mode A) | Dashboard | Golden file MDLZ | Diff Dash − Golden | Tolerance OK? | Root cause nếu lệch |
|---|---|---|---|---|---|---|---|
| Avg VFR | ≤ 0.5pp | **94.49%** 🟢 | `<chưa fill>` | `<golden pending>` | — | — | — |
| Tổng chuyến | ≤ 1% | 546 | `<chưa fill>` | `<golden pending>` | — | — | — |
| Low <50% | ≤ 1% | 4 | `<chưa fill>` | `<golden pending>` | — | — | — |
| Medium 50-70% | ≤ 1% | 6 | `<chưa fill>` | `<golden pending>` | — | — | — |
| High 70-95% | ≤ 1% | 178 | `<chưa fill>` | `<golden pending>` | — | — | — |
| Excellent ≥95% | ≤ 1% | 358 | `<chưa fill>` | `<golden pending>` | — | — | ⚠ Verify ≥95 vs >95 trước (BUG-VFR-08 rollout) |

### 1.2 Mode VH (Operation) — `mv_vfr_van_hanh`

| Metric | Tolerance | SQL value (Mode A) | Dashboard | Golden file MDLZ | Diff Dash − Golden | Tolerance OK? | Root cause nếu lệch |
|---|---|---|---|---|---|---|---|
| Avg VFR | ≤ 0.5pp | **78.10%** 🟡 | `<chưa fill>` | `<golden pending>` | — | — | — |
| Tổng chuyến | ≤ 1% | 492 | `<chưa fill>` | `<golden pending>` | — | — | — |
| Low <50% | ≤ 1% | **78** ⚠ | `<chưa fill>` | `<golden pending>` | — | — | Điểm nóng cần khách giải thích — 16% chuyến |
| Medium 50-70% | ≤ 1% | 87 | `<chưa fill>` | `<golden pending>` | — | — | — |
| High 70-95% | ≤ 1% | 137 | `<chưa fill>` | `<golden pending>` | — | — | — |
| Excellent ≥95% | ≤ 1% | 190 | `<chưa fill>` | `<golden pending>` | — | — | ⚠ Verify ≥95 vs >95 |

### 1.3 Δ GT − VH (hero, luôn visible)

| Metric | Tolerance | SQL value | Dashboard | Golden | Diff | OK? | Root cause |
|---|---|---|---|---|---|---|---|
| Δ Avg VFR GT − VH | ≤ 0.5pp | **+16.39pp** ⚠ | `<chưa fill>` | `<golden pending>` | — | — | Gap planning vs execution lớn — chính là giá trị storytelling v2 mang lại |

---

## Block 2 — Dimension VFR (weighted)

> **Lưu ý weighted:** số SQL dưới đây là `vfr_ratio` weighted (Loose/FP × Khối/Tấn fill×mix) — số dashboard. Excel sheet 02 có cột simple-avg crosscheck, KHÔNG khớp với weighted SQL.

### 2.1 By Area (Khu vực)

| Khu vực | Mode | SQL weighted (sheet 02) | Dashboard | Golden | Diff | OK? (≤0.5pp) | Note |
|---|---|---|---|---|---|---|---|
| `<area1>` | GT | `<refresh từ Excel sheet 02>` | `<chưa fill>` | `<golden pending>` | — | — | Worst-first sort |
| ... (≈12 area × 2 modes ≈ 24 rows) | | | | | | | |

> Trong Mode B: fill từ sheet 02 (open Excel → copy 12 rows × 2 modes).

### 2.2 By Vehicle (Loại xe)

| Loại xe | Mode | SQL weighted | Dashboard | Golden | Diff | OK? | Note |
|---|---|---|---|---|---|---|---|
| ... (≈34 vehicle type × 2 modes ≈ 68 rows; lưu ý mode GT dùng `loai_xe_gui_thau`, VH dùng `loai_xe_van_hanh`) | | | | | | | |

### 2.3 By Vendor (NVC) — AD-HOC (no registry; spec §22)

| NVC | Mode | SQL weighted | Dashboard | Golden | Diff | OK? | Note |
|---|---|---|---|---|---|---|---|
| ... (≈11 NVC × 2 modes ≈ 22 rows) | | | | | | | ⚠ Dashboard By Vendor có thể empty nếu admin chưa cấu hình SQL (AC-S5) |

### 2.4 By Loading Type (Loose / Full Pallet) — AD-HOC rollup window-level

| Loại bốc xếp | Mode | SQL weighted | Dashboard | Golden | Diff | OK? | Note |
|---|---|---|---|---|---|---|---|
| Loose | GT | `<sheet 02>` | `<chưa fill>` | `<golden pending>` | — | — | Includes 'Losse' (typo) |
| Full Pallet | GT | `<sheet 02>` | `<chưa fill>` | `<golden pending>` | — | — | — |
| (rỗng) / Không xác định | GT | `<sheet 02>` | `<chưa fill>` | `<golden pending>` | — | — | BUG-VFR-04 fixed |
| Loose | VH | `<sheet 02>` | `<chưa fill>` | `<golden pending>` | — | — | — |
| Full Pallet | VH | `<sheet 02>` | `<chưa fill>` | `<golden pending>` | — | — | — |
| (rỗng) / Không xác định | VH | `<sheet 02>` | `<chưa fill>` | `<golden pending>` | — | — | — |

---

## Block 3 — Trend daily (Avg VFR per ngày)

| Ngày | Mode | SQL Avg VFR (sheet 03) | Dashboard | Golden | Diff | OK? (≤0.5pp/ngày) | Note |
|---|---|---|---|---|---|---|---|
| 2026-05-18 | GT | `<sheet 03>` | `<chưa fill>` | `<golden pending>` | — | — | — |
| 2026-05-19 | GT | `<sheet 03>` | `<chưa fill>` | `<golden pending>` | — | — | — |
| 2026-05-20 | GT | `<sheet 03>` | `<chưa fill>` | `<golden pending>` | — | — | — |
| 2026-05-21 | GT | `<sheet 03>` | `<chưa fill>` | `<golden pending>` | — | — | — |
| 2026-05-22 | GT | `<sheet 03>` | `<chưa fill>` | `<golden pending>` | — | — | — |
| (lặp 5 dòng cho VH) | | | | | | | |

> Hero sparkline = 14 ngày — window UAT 5 ngày chỉ verify subset. Sparkline 14d cần re-run script với window khác.

---

## Block 4 — Exception <50% summary

| Metric | Window | SQL value (refresh Mode B) | Dashboard | Golden | OK? |
|---|---|---|---|---|---|
| Count chuyến vfr_max<50 | 7 ngày cuối tính tới today | `<chưa run>` (UAT window 5d ≠ exception 7d) | `<chưa fill>` | — | — |
| Top 3 khu vực kéo Low | 7d | `<chưa run>` | `<chưa fill>` | — | — |
| Top 3 NVC kéo Low | 7d | `<chưa run>` | `<chưa fill>` | — | — |
| Top 3 loại xe kéo Low | 7d | `<chưa run>` | `<chưa fill>` | — | — |

---

## Block 5 — Top-N ranking sanity (chỉ cần 4/5 tên match, thứ tự có thể lệch)

| Ranking | Mode | SQL top 5 (sheet 02) | Dashboard top 5 | Golden top 5 | Match ≥ 4/5? | Note |
|---|---|---|---|---|---|---|
| Top 5 khu vực kéo VFR | GT | `<sheet 02 worst-first>` | `<chưa fill>` | `<golden>` | — | — |
| Top 5 khu vực kéo VFR | VH | `<sheet 02>` | `<chưa fill>` | `<golden>` | — | — |
| Top 5 NVC kéo VFR | GT | `<sheet 02>` | `<chưa fill>` | `<golden>` | — | — |
| Top 5 NVC kéo VFR | VH | `<sheet 02>` | `<chưa fill>` | `<golden>` | — | — |
| Top 5 loại xe kéo VFR | GT | `<sheet 02>` | `<chưa fill>` | `<golden>` | — | — |

---

## Block 6 — Filter combo sanity (random spot-check)

| Filter combo | Mode | Avg VFR SQL | Dashboard | Match? | Note |
|---|---|---|---|---|---|
| Khu vực = `<pick 1 worst>` | GT | `<re-run script với filter này>` | `<chưa fill>` | — | Multi-select IN logic |
| NVC = top 2 worst | GT | `<re-run>` | `<chưa fill>` | — | — |
| Combo 3 dim | GT | `<re-run>` | `<chưa fill>` | — | Verify perf < 3s |

---

## Diff resolution (chốt trước session, không bỏ qua)

Mỗi row out-of-tolerance phải có 1 trạng thái trước session:

| Trạng thái | Action |
|---|---|
| **Resolved** | Đã fix, re-run script khớp |
| **Accepted** | Khách accept diff (vd boundary >95, MDLZ dùng đếm thủ công Excel → ±2 chuyến) — ghi rõ accept trong note |
| **Deferred** | Convert thành defect stub `defects/UAT-{NNN}-{slug}.md`, mở trước session |

KHÔNG vào session với row chưa resolved/accepted/deferred.

---

## Header summary (fill ở Mode B)

```
Total rows: ~150
Resolved (in tolerance): _____
Accepted (with note): _____
Deferred (defect open): _____
Ready for session: yes / no
```

---

## SQL provenance reminder

- Q-KPI-{GT|VH} = registry `## vfr {tender|operation}` → `### Avg VFR (VFR by {Tender|Operation} Trip)` (sql-registry.md line ref ở Excel sheet 07)
- Q-AREA / Q-VEHICLE-{GT|VH} = registry dim sections
- Q-VENDOR / Q-LOADTYPE / Q-TREND / Q-DETAIL-{GT|VH} = ad-hoc (xem Excel sheet 07 với highlight vàng)

Khi registry update sau Mode A → re-run `python scripts/uat_vfr_export.py` để pick up + dry-run lại.
