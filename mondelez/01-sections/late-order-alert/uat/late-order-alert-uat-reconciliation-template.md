# Reconciliation Matrix Template — Late Order Alert (Mondelez)

| Trường | Giá trị |
|---|---|
| **Plan reference** | [late-order-alert-uat-plan.md](late-order-alert-uat-plan.md) |
| **Tolerance** | Theo plan §4 |
| **3 nguồn** | Dashboard CT (production widget) · SQL raw (CH `analytics_workspace.mv_alert_late_do` via Excel sheet 08 appendix) · Golden file MDLZ (Excel daily tracker khách) |
| **Ngày tạo template** | 2026-05-27 |
| **Tác giả** | PM/DA via `/da-uat` |
| **Trạng thái** | Empty — fill trong Mode B dry-run (T-2 → T-1) |

---

## Cách dùng matrix

1. Mode B (dry-run T-2 → T-1): PM/DA fill 3 cột (Dashboard / SQL raw / Golden) cho từng row, tính Diff + Tolerance OK + Root cause.
2. Mọi row out-of-tolerance phải có 1 trong 3 trạng thái trước session UAT:
   - **Resolved** — Đã fix, re-run matrix khớp
   - **Accepted** — Khách đã accept diff (vd timezone) — ghi rõ accept trong note
   - **Deferred** — Convert thành defect stub, mở trước session, báo khách "row này check riêng"
3. Mode C (session): re-run với data session thực tế, đối chiếu live với khách.
4. Mode D (retest): re-run TOÀN BỘ matrix sau dev fix — số có thể dịch.

**KHÔNG bắt đầu session UAT khi matrix có row chưa Resolved / Accepted / Deferred.**

---

## Block 1 — Scorecard 8 KPI (lớp A — TC-A01, A02)

**Filter session UAT**: `all=ALL, dateType='ETA gửi thầu (đơn)', dateRange={session_date} 00:00:00 → {session_date} 23:59:59 UTC+7`

| # | Metric | Filter | Dashboard | SQL raw | Golden file | Diff Dash–Golden | Diff Dash–SQL | Tolerance OK? | Status | Root cause / Note |
|---|---|---|---|---|---|---|---|---|---|---|
| 1.1 | Tổng chuyến (`tat_ca`) | ALL | _____ | _____ | _____ | _____ | _____ | ≤1% | _____ | _____ |
| 1.2 | Normal (`normal_cnt`) | ALL | _____ | _____ | _____ | _____ | _____ | ≤1% | _____ | _____ |
| 1.3 | At risk (`at_risk_cnt`) | ALL | _____ | _____ | _____ | _____ | _____ | ≤1% | _____ | _____ |
| 1.4 | Late departure open (`late_departure_open_cnt`) | ALL | _____ | _____ | _____ | _____ | _____ | ≤1% | _____ | _____ |
| 1.5 | Late departure (`late_departure_cnt`) | ALL | _____ | _____ | _____ | _____ | _____ | ≤1% | _____ | _____ |
| 1.6 | Ontime departure (`ontime_departure_cnt`) | ALL | _____ | _____ | _____ | _____ | _____ | ≤1% | _____ | _____ |
| 1.7 | Ontime delivery (`ontime_delivery_cnt`) | ALL | _____ | _____ | _____ | _____ | _____ | ≤1% | _____ | _____ |
| 1.8 | Late delivery (`late_delivery_cnt`) | ALL | _____ | _____ | _____ | _____ | _____ | ≤1% | _____ | _____ |
| 1.9 | **Sum check**: 1.2 + 1.3 + 1.4 + 1.5 + 1.6 + 1.7 + 1.8 = 1.1 | ALL | _____ | _____ | _____ | _____ | _____ | exact match | _____ | _____ |

---

## Block 2 — Donut chart 7 segment (lớp A — TC-A04, A05)

**Cùng filter Block 1**. Verify donut segment count + share %.

| # | Segment | Dashboard count | Dashboard share % | SQL raw count | SQL raw share % | Tolerance OK? (count ≤1%; share ≤0.5pp) | Status | Note |
|---|---|---|---|---|---|---|---|---|
| 2.1 | Normal | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 2.2 | At risk | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 2.3 | Late departure open | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 2.4 | Late departure | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 2.5 | Ontime departure | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 2.6 | Ontime delivery | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 2.7 | Late delivery | _____ | _____ | _____ | _____ | _____ | _____ | _____ |

---

## Block 3 — Transporter bar chart top 5 (lớp A — TC-A06)

**Cùng filter Block 1**. Sort by total trip desc.

| # | Rank | NVT (Dashboard) | Total (Dashboard) | NVT (Golden file) | Total (Golden) | Match? | Tolerance OK? (tên ≥4/5, count ≤1%) | Status | Note |
|---|---|---|---|---|---|---|---|---|---|
| 3.1 | #1 | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 3.2 | #2 | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 3.3 | #3 | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 3.4 | #4 | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 3.5 | #5 | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 3.6 | NVT empty (`Không xác định`) | _____ | _____ | (N/A) | _____ | _____ | _____ | _____ | _____ |

---

## Block 4 — Detail table trip count vs scorecard (lớp A — TC-A07)

**Cùng filter Block 1**. Verify aggregation lossless.

| # | Metric | Value | Source | Expected match | Status | Note |
|---|---|---|---|---|---|---|
| 4.1 | Detail table T rows (sau trip aggregate) | _____ | Dashboard footer count grid | = Block 1.1 (`tat_ca`) | _____ | _____ |
| 4.2 | DO-level row count (trước aggregate) | _____ | SQL raw `COUNT(*)` từ `mv_alert_late_do` | ≥ 4.1 | _____ | _____ |
| 4.3 | DO/Trip ratio | _____ | 4.2 / 4.1 | Document — không phải pass/fail | _____ | _____ |
| 4.4 | Trip-less DO count (`so_chuyen IS NULL OR ''`) | _____ | SQL raw | Document | _____ | _____ |

---

## Block 5 — Detail table top 5 critical (lớp A — TC-A08)

**Cùng filter Block 1**. Sort by alert priority asc — top 5 = Late departure open (priority 0).

| # | Trip code (Dashboard) | Kho | NVT | Alert (Dashboard) | ETA (Dashboard) | Match golden file? | Khách phân loại (Golden) | Status | Note |
|---|---|---|---|---|---|---|---|---|---|
| 5.1 | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 5.2 | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 5.3 | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 5.4 | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 5.5 | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ |

---

## Block 6 — Filter combo verify (lớp D — TC-D02)

Run với filter chặt hơn — verify số dịch đúng + golden file ALSO filtered.

| # | Filter combo | Metric | Dashboard | SQL raw | Golden file (cùng filter) | Tolerance OK? | Status | Note |
|---|---|---|---|---|---|---|---|---|
| 6.1 | `whseid='BKD1'` (single) | Tổng chuyến | _____ | _____ | _____ | ≤1% | _____ | _____ |
| 6.2 | `whseid='BKD1', transporter='ANH SON'` | Tổng chuyến | _____ | _____ | _____ | ≤1% | _____ | _____ |
| 6.3 | `whseid='BKD1,NKD,VN821' (3 kho CSV)` | Tổng chuyến | _____ | _____ | _____ | ≤1% | _____ | _____ |
| 6.4 | `dateType='Ngày gửi thầu'` (đổi branch) | Tổng chuyến | _____ | _____ | _____ | ≤1% | _____ | A1 regression check |
| 6.5 | `region='<1 khu vực phổ biến>'` | Tổng chuyến | _____ | _____ | _____ | ≤1% | _____ | _____ |
| 6.6 | `group_name='<1 kênh>'` (alias sales_channel) | Tổng chuyến | _____ | _____ | _____ | ≤1% | _____ | _____ |

---

## Block 7 — Trip aggregation deep check (lớp B — TC-B06)

Pick 3 trip có ≥2 DO khác alert. Cross-check trip row aggregate đúng §5.3 PRD.

| # | Trip code | DO count | Alert (Dashboard) | Expected alert (max priority DO) | `mandatoryDepartAt` (Dashboard) | Expected (alertPriorityRow) | `eta` (Dashboard) | Expected (earliestEtaRow) | `salesChannel` (Dashboard) | Expected (nppPriorityRow) | Match? | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 7.1 | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 7.2 | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ |
| 7.3 | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ | _____ |

---

## Block 8 — Warehouse standardize (lớp B — TC-B07)

Verify mọi variant của 6 codes (BKD1/2/3, NKD, VN821, VN831) được map đúng. Test với raw `whseid` variants nếu CH có.

| # | Raw `whseid` MV | Standardized (Dashboard) | Expected | Match? | Status | Note |
|---|---|---|---|---|---|---|
| 8.1 | `BKD1` (canonical) | _____ | BKD1 | _____ | _____ | _____ |
| 8.2 | `BKD-1` (nếu có) | _____ | BKD1 | _____ | _____ | _____ |
| 8.3 | `BINHDUONG1` (nếu có) | _____ | BKD1 | _____ | _____ | _____ |
| 8.4 | `bkd 1` (nếu có) | _____ | BKD1 | _____ | _____ | _____ |
| 8.5 | `NKD` | _____ | NKD | _____ | _____ | _____ |
| 8.6 | `VN821` | _____ | VN821 | _____ | _____ | _____ |
| 8.7 | `VN831` | _____ | VN831 | _____ | _____ | _____ |
| 8.8 | `<unknown new wh>` | _____ | raw value (trim only) | _____ | _____ | A4 anomaly — note nếu MDLZ có WH mới |

---

## Summary dashboard cho dry-run report (Mode B)

Fill cuối Mode B:

| Block | Tổng row | Pass | Fail (out-of-tolerance) | Resolved | Accepted | Deferred |
|---|---|---|---|---|---|---|
| 1 Scorecard 8 KPI | 9 | _____ | _____ | _____ | _____ | _____ |
| 2 Donut 7 segment | 7 | _____ | _____ | _____ | _____ | _____ |
| 3 Transporter top 5 | 6 | _____ | _____ | _____ | _____ | _____ |
| 4 Detail trip count | 4 | _____ | _____ | _____ | _____ | _____ |
| 5 Detail top 5 critical | 5 | _____ | _____ | _____ | _____ | _____ |
| 6 Filter combo | 6 | _____ | _____ | _____ | _____ | _____ |
| 7 Trip aggregation | 3 | _____ | _____ | _____ | _____ | _____ |
| 8 Warehouse standardize | 8 | _____ | _____ | _____ | _____ | _____ |
| **Total** | **48** | _____ | _____ | _____ | _____ | _____ |

**Ready for session?** ☐ Yes (all rows Resolved/Accepted/Deferred) — ☐ No (lùi lịch)

---

## Lịch sử thay đổi

| Version | Ngày | Tác giả | Thay đổi |
|---|---|---|---|
| 1.0.0 | 2026-05-27 | PM/DA via `/da-uat` | Bản đầu tiên — 8 block × 48 rows reconciliation. Cover scorecard 8 KPI + donut 7 segment + transporter top 5 + detail trip count + detail top 5 critical + filter combo 6 + trip aggregation 3 + warehouse standardize 8 |
