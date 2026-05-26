# OTIF UAT Ops Insight Pack — Window 2026-05-18 → 2026-05-22

**Tenant**: Mondelez
**Section**: OTIF
**Window**: 5 ngày (Mon → Fri tuần 21/2026)
**Pulled at**: 2026-05-26 16:30 UTC+7
**Stack**: B (ClickHouse `analytics_workspace.mv_otif`)
**Author**: PM/BA — thuy le
**Companion file**: [otif-uat-numbers-2026-05-18_to_2026-05-22.xlsx](otif-uat-numbers-2026-05-18_to_2026-05-22.xlsx) (số đối chiếu cho khách)

---

## Premise của file này

Giả định **UAT pass 100% reconciliation** (số dashboard khớp golden file 100%). Câu hỏi tiếp theo: **những con số đó đang nói lên điều gì về vận hành Mondelez?** Khách hàng cần insight gì ngoài việc xác nhận "số khớp"?

File này:
- KHÔNG audit định nghĩa Ontime/Infull/OTIF (đó là UAT lớp B).
- KHÔNG verify dashboard có đúng PRD không (đó là UAT lớp C / `/da-trace`).
- **CÓ** đọc data 5 ngày dưới góc Senior Ops Reviewer + Data Analyst để: (1) flag master data quality gap, (2) identify operational red flag mà khách nên action, (3) đề xuất KPI dài hạn để maintain.

---

## 1-line headline

**% OTIF window = 82.89% — dưới target 90% (Red band).** 3 root cause chính: **FRESH cargo chỉ 60.92% OTIF** (kéo tổng -6pp), **NVC HDA worst 72.79%** chiếm 20.06% volume, **Tuesday 19/05 outlier 66.79%** do NVC ANH SON crash 53.98% + NVC HOA PHAT silent. **Master data clean** trên 4/5 trục, có 11 đơn NVC rỗng + 1 vendor (HOA PHAT) chỉ chạy 2/5 ngày cần xác minh nghiệp vụ.

Số tham chiếu: 82.89% → [Excel Q-1](otif-uat-numbers-2026-05-18_to_2026-05-22.xlsx); 60.92% → Q-INS-14; 72.79% → [Excel Q-04 (Top NVC)](otif-uat-numbers-2026-05-18_to_2026-05-22.xlsx); 20.06% → Q-INS-2; 66.79% → Q-INS-10; 53.98% → Q-INS-3.

---

## 2. Key numbers (đối chiếu Excel)

| Metric | Value | Source |
|---|---|---|
| Tổng đơn (sau loại STM) | 2,986 | [Excel sheet 01](otif-uat-numbers-2026-05-18_to_2026-05-22.xlsx); Q-INS-1 |
| % OTIF window | **82.89%** | [Excel sheet 01](otif-uat-numbers-2026-05-18_to_2026-05-22.xlsx); Q-1 |
| % Ontime | 93.24% | Q-1 |
| % Infull | 92.36% | Q-1 |
| Đơn không có dữ liệu STM | 0 (0%) | Q-INS-1 |
| ETA + ATA timestamps đầy đủ | 100% | Q-INS-13 |
| NVC concentration top-3 | 82.32% volume | Q-INS-2 |
| Cargo type splits | DRY 73.07% / FRESH 22.54% / POSM 4.39% | Q-INS-14 |

---

## 3. Master data quality scorecard

| Trục master data | Status | Số liệu | Hành động đề xuất |
|---|---|---|---|
| `whseid` coverage (PRD §4 mapping) | ✅ Clean | 0 đơn nằm ngoài 6 mã (BKD1/2/3, NKD, VN821, VN831) | Maintain — verify lại sau mỗi master data sync |
| ETA timestamp (`eta_giao_hang_cho_npp`) | ✅ Clean | 100% (Q-INS-13) | OK |
| ATA timestamp (`ata_den`) | ✅ Clean | 100% (Q-INS-13) | OK |
| STM data coverage | ✅ Clean | 100% có STM (0 đơn `'Không có dữ liệu STM'`) | OK |
| Cargo type (`group_of_cago`) | ✅ Clean | 100% có value (3 type chuẩn DRY/FRESH/POSM) | OK |
| Channel (`group_name`) | ✅ Clean | Đầy đủ (GT/MT) | OK |
| **NVC name (`ten_ngan_nha_van_tai`)** | ⚠️ **99.63%** | **11 đơn rỗng** spread across BKD1/NKD/VN831, 11 customer khác nhau, toàn DRY (Q-INS-4) | BA email IT Mondelez check pipeline import NVC code → name; nếu sporadic do mã NVC mới chưa map → fix master data; nếu vẫn lặp → escalate Smartlog backend |
| **Customer name encoding** | ⚠️ Possible truncation | "CN BINH DUONG - CONG TY CP DICH VUTHUONG MAI" thiếu space giữa "DV" và "THUONG" (Q-INS-9) | BA review master data `customer_name` field length / encoding issue tại source |

---

## 4. Operational red flags — 6 phát hiện cần customer action

### Flag 1 — FRESH cargo OTIF 60.92% (kéo tổng OTIF -6pp)
- **Quan sát**: FRESH 673 đơn (22.54% volume) đạt **60.92% OTIF** (Q-INS-14). DRY 2,182 đơn (73.07% vol) đạt **89.83%** — gần target. POSM 131 đơn đạt 80.15%.
- **So sánh**: Gap DRY vs FRESH = **28.91pp**. Nếu FRESH-only mode → tổng OTIF ~60.92%. Nếu DRY-only mode → ~89.83% (gần target).
- **Giả thuyết**: FRESH cần cold chain + time window chặt hơn, vehicle setup khác, route ưu tiên khác. Target 90% áp dụng cùng cho cả 2 không realistic với mô hình FMCG có cargo mix.
- **Đề xuất**: **Per-cargo target** — FRESH 80%, DRY 95%, POSM 85%. PRD §13.2 hiện tại chỉ có 1 target = 90% cho mọi cargo. → **Route**: `/ba` revise PRD `§13.2` + Mondelez SC Manager confirm target tách theo cargo.

### Flag 2 — NVC concentration top-3 = 82.32% volume (single point of failure risk)
- **Quan sát**: ANH SON **41.93%**, HOA PHAT **20.33%**, HDA **20.06%** — top 3 NVC chiếm **82.32%** volume window (Q-INS-2). 4 NVC còn lại (TLL/NGUYEN PHAT/HVP/THANH AN) cộng lại chỉ **17.32%**. HDA OTIF **72.79%** — vendor worst trong top-3 ([Excel Q-04](otif-uat-numbers-2026-05-18_to_2026-05-22.xlsx)).
- **So sánh**: Ngày 19/05 ANH SON crash 53.98% OTIF (Q-INS-3) → toàn bộ ngày down 66.79%. Top NVC fail → daily fail.
- **Giả thuyết**: Tổng đơn dồn vào ít NVC — vendor risk concentration. Khi 1 NVC có sự cố, không có dự phòng từ tail vendor (mỗi tail vendor chỉ 3-6% volume).
- **Đề xuất**: Customer cần track **NVC concentration index** (HHI hoặc % top-3) và define ngưỡng cảnh báo. Sourcing team cân nhắc grow tail NVC để giảm risk. **Route**: `/da-pm` thêm "NVC concentration" vào roadmap KPI quý sau.

### Flag 3 — HOA PHAT chỉ chạy 2/5 ngày trong window (silent 3/5 ngày)
- **Quan sát**: HOA PHAT 607 đơn nhưng chỉ xuất hiện 2 ngày: **2026-05-20** + **2026-05-22** (Q-INS-12). Silent 3/5 ngày (18/05 + 19/05 + 21/05). 100% OTIF.
- **So sánh**: 6 NVC còn lại đều hoạt động 5/5 ngày. HOA PHAT là vendor duy nhất bị silence.
- **Giả thuyết**: 3 khả năng — (a) HOA PHAT là **peak-relief carrier** chỉ chạy ngày volume cao (20/05 peak 1326 đơn); (b) HOA PHAT chỉ phục vụ specific route/customer tập trung 2 ngày; (c) Operational issue chưa rõ. Q-INS-11 cho thấy HOA PHAT phục vụ WinMart/WinCommerce 376/607 đơn (62%) — có thể là **carrier dedicated cho MT Modern Trade chain**.
- **Đề xuất**: SC Manager confirm với vendor management team — đây có phải contractual peak-relief setup không? Nếu là chính thức → log vào contract metadata; nếu là gap → tìm thêm carrier để cover 3 ngày kia. **Route**: BA mention trong UAT session lớp C (storytelling) — "Health Matrix có surface được pattern này không?"

### Flag 4 — Tuesday 19/05 outlier 66.79% (gap -16pp so với Wednesday)
- **Quan sát**: Daily OTIF (Q-INS-10): Mon 75.13% (390 đơn), **Tue 66.79% (268 đơn — lowest)**, **Wed 88.54% (1326 đơn — peak)**, Thu 76.82% (358), Fri 86.02% (644). Variance Tue↔Wed = **16.25pp**, volume variance 4.95×.
- **So sánh**: Tue có volume thấp nhất NHƯNG OTIF thấp nhất → không phải "ít đơn dễ giao". Wed có volume cao nhất NHƯNG OTIF cao thứ nhì → ngược intuition.
- **Giả thuyết**: 19/05 ANH SON (top NVC) crash 53.98% (Q-INS-3) + HOA PHAT silent → daily fail. Có thể là day-of-week pattern (Tue thường chuẩn bị cho Wed peak?) hoặc external event (weather, traffic, hệ thống Mondelez maintenance, holiday).
- **Đề xuất**: Customer điều tra root cause 19/05 — đã có incident log chưa? Define **"daily OTIF variance alert"** — khi 1 ngày lệch > 10pp vs trung bình tuần thì tự động alert. **Route**: `/da-data` thêm Daily Variance metric vào dashboard.

### Flag 5 — Lateness magnitude: 34 đơn late >12 giờ (17% của Failed Ontime)
- **Quan sát**: 200 đơn Failed Ontime (Q-INS-7). Phân bố lateness: **≤1h: 38 đơn**, 1-3h: 102, 3-12h: 26, **>12h: 34 đơn**. Median = **2h late**, p95 = **~40h**, max = **~49h (gần 2 ngày)**.
- **So sánh**: Definition Failed Ontime trong DDL = late > 30 phút. Nhưng severity rất phân hoá: 38 đơn late ≤1h (recoverable) vs 34 đơn late >12h (catastrophic — likely SLA breach).
- **Giả thuyết**: 34 đơn >12h late có thể đã được Mondelez xử lý riêng (refund, rescheduling, customer complaint) nhưng dashboard chỉ đếm chung "Failed Ontime". 1 metric % OTIF không phân biệt được severity.
- **Đề xuất**: Thêm **Lateness severity histogram** vào dashboard (Tier 2/3) — 4 bucket ≤1h/1-3h/3-12h/>12h. Customer biết "fail ít nhưng đa số recoverable" khác với "fail nhiều cộng severe". **Route**: `/ba` thêm AC mới + `/da-data` define metric.

### Flag 6 — Infull failure 96% có transport component (chỉ 5.7% kho)
- **Quan sát**: 228 đơn Failed Infull (Q-INS-8). **13 đơn** shipped_lt_planned (warehouse rớt số khi xuất kho — 5.7%) vs **219 đơn** delivered_lt_shipped (transport rớt số trên đường — 96.05%). Median gap 11 CSE, p95 276.65 CSE (extreme), avg 58.46 CSE.
- **So sánh**: PRD §3 phân loại WH vs Transport Infull failure — data 5 ngày cho thấy transport là root cause dominant trong 219/228 đơn (96%). Một số đơn có cả WH + Transport fail nên 13+219 > 228 (overlap).
- **Giả thuyết**: WH có thể đã xuất đủ → nhưng transport bị mất/hỏng trên đường (theft, vehicle damage, customer reject 1 phần). Hoặc data tracking POD chưa khớp với customer signed quantity.
- **Đề xuất**: Customer cần điều tra **219 đơn delivered_lt_shipped** — gap CSE ở đâu mất giữa kho → giao? Vendor management team review carrier loss claim. Median 11 CSE × 219 đơn = ~2,409 CSE missing trong 5 ngày — đáng quan tâm về cost. **Route**: `/da-pm` mention trong stakeholder update.

---

## 5. Long-term tracking criteria — 9 KPI extension đề xuất

Ngoài 3 KPI hiện có (% Ontime / % Infull / % OTIF), Mondelez nên maintain monitor 9 metric mới để vận hành proactive thay vì reactive:

| # | KPI extension | Current value (window 18-22/05) | Why monitor | Source query |
|---|---|---|---|---|
| 1 | % OTIF by cargo type | DRY 89.83% / FRESH 60.92% / POSM 80.15% | Phát hiện cargo nào lệch — set per-cargo target | Q-INS-14 |
| 2 | Lateness severity histogram (4 bucket) | 38 / 102 / 26 / 34 (≤1h / 1-3h / 3-12h / >12h) | Phân biệt fail recoverable vs catastrophic | Q-INS-7 |
| 3 | Infull root cause split | WH 13 / Transport 219 (96% transport involved) | Action team theo root cause | Q-INS-8 |
| 4 | NVC concentration (top-3 share) | **82.32%** (ANH SON 41.93 + HOA PHAT 20.33 + HDA 20.06) | Vendor risk SPOF | Q-INS-2 |
| 5 | NVC active-day ratio | HOA PHAT 2/5 days (40%) | Phát hiện peak-relief vs regular carrier | Q-INS-12 |
| 6 | Daily OTIF variance | Max-Min daily = 21.75pp (88.54 − 66.79) | Detect outlier day — alert > 10pp variance | Q-INS-10 |
| 7 | Customer concentration top-N | Top 4 WinMart/WinCommerce = 8.4% vol, 0% fail | Lobby cho key customer (service-level guarantee) | Q-INS-9 |
| 8 | Master data NVC name fill rate | 99.63% (11/2986 rỗng) | Master data hygiene — chỉ ra pipeline data gap | Q-INS-4 |
| 9 | Cumulative CSE gap p95 (Infull) | 276.65 CSE | Track magnitude rớt số lượng (cost) | Q-INS-8 |

**Lưu ý**: 9 KPI trên KHÔNG block UAT v1.5 — đề xuất cho roadmap quý sau. Customer pick 3-5 metric muốn ưu tiên, `/da-pm` add vào sprint planning.

---

## 6. Open questions cho customer Mondelez (mang vào session)

1. **Target % OTIF 90% có nên áp dụng cùng cho DRY (89.83%) và FRESH (60.92%) không?** PRD hiện chỉ 1 target = 90%. Realistic options: (a) giữ 1 target + accept FRESH dưới target permanent, (b) tách per-cargo target (FRESH 80% / DRY 95% / POSM 85%), (c) exclude FRESH khỏi tính OTIF chung (báo riêng).
2. **HOA PHAT chỉ chạy 2/5 ngày trong window — đây là contract pattern peak-relief hay anomaly?** Nếu là chính thức, dashboard cần surface được "vendor activity pattern" để SC Manager không hiểu nhầm 100% là tốt.
3. **34 đơn late > 12h (median 2h, max 49h) — đã được Mondelez xử lý riêng (refund/incident) chưa, hay chỉ đếm chung với Failed Ontime 30 phút?** Severity bucket có cần?
4. **11 đơn NVC name rỗng — accept trong báo cáo hay phải exclude?** Spread across BKD1/NKD/VN831, không tập trung 1 NVC code → có vẻ master data NVC code-to-name mapping bị miss vài record.
5. **Tuesday 19/05 (66.79%) outlier — Mondelez đã có root cause analysis chưa?** ANH SON crash 53.98% + HOA PHAT silent. Có incident log để cross-check không?
6. **WinMart/WinCommerce 4 chain ALL 0% fail (250 đơn 8.4% vol) — đây là service-level guarantee đặc biệt, hay HOA PHAT carrier có dedicated route cho WinMart?** Customer relationship logic.
7. **219 đơn delivered_lt_shipped (median 11 CSE, p95 276 CSE) — đó là customer reject 1 phần, theft, hay vehicle damage?** Cần root cause để vendor management team action.

---

## 7. Verdict + handoff routing

**Verdict UAT lớp Ops (giả định reconciliation pass 100%)**: ✅ Số liệu mạch lạc; ⚠️ 6 operational red flag + 9 KPI extension đề xuất; ⚠️ 2 master data hygiene issue (NVC name rỗng + customer name encoding).

| Finding | Route | Output |
|---|---|---|
| FRESH per-cargo target | `/ba` revise PRD §13.2 | PRD v1.2.7 |
| NVC name rỗng | BA email Mondelez IT (master data pipeline) | Confirm pattern + ETL fix |
| Customer name encoding truncation | BA email Mondelez IT | Master data export QA |
| HOA PHAT 2/5 day pattern | SC Manager → vendor management | Contract metadata review |
| Lateness severity histogram | `/da-data` define metric + `/ba` thêm AC | New metric + AC-16 PRD |
| Daily OTIF variance alert | `/da-data` define alert rule | Alert config |
| NVC concentration KPI | `/da-pm` roadmap quý sau | Sprint planning |
| Storytelling Health Matrix có surface vendor silence không | UAT lớp C TC-OTIF-009 + `/da-trace` audit nếu fail | Drift report |
| 19/05 outlier root cause | SC Manager với Ops team Mondelez | Incident log cross-check |

---

## Appendix — Data sources

> Mọi số trong artifact truy về 1 trong các query bên dưới. 10 query Q-1..Q-9 (KPI/Trend/Dim base) đã có trong [Excel sheet 06](otif-uat-numbers-2026-05-18_to_2026-05-22.xlsx) "06 — SQL Appendix" (Q-01..Q-10). 14 query Q-INS-* dưới đây là ad-hoc cho insight pack này, KHÔNG nằm trong Excel.

### Q-INS-1 — STM coverage (% rows excluded)

- **Source**: `analytics_workspace.mv_otif` (ClickHouse Mondelez)
- **Run at**: 2026-05-26 16:25 UTC+7
- **Result**: total=2986, no_stm=0, valid=2986, pct_no_stm=0.0%

```sql
SELECT
  count() AS total_with_eta,
  countIf(otif_status = 'Không có dữ liệu STM') AS no_stm,
  countIf(otif_status != 'Không có dữ liệu STM') AS valid,
  round(100.0 * countIf(otif_status = 'Không có dữ liệu STM') / count(), 2) AS pct_no_stm
FROM analytics_workspace.mv_otif
WHERE eta_giao_hang_cho_npp BETWEEN '2026-05-18 00:00:00' AND '2026-05-22 23:59:59'
```

### Q-INS-2 — Top NVC volume share (concentration/Pareto)

- **Run at**: 2026-05-26 16:25 UTC+7
- **Result**: ANH SON 1252 (41.93%), HOA PHAT 607 (20.33%), HDA 599 (20.06%), TLL 171 (5.73%), NGUYEN PHAT 129 (4.32%), HVP 115 (3.85%), THANH AN 102 (3.42%), (rỗng) 11 (0.37%). **Top-3 share = 82.32%**.

```sql
WITH base AS (
  SELECT if(ten_ngan_nha_van_tai='', '(rỗng)', ten_ngan_nha_van_tai) AS nvc, count() AS n
  FROM analytics_workspace.mv_otif
  WHERE eta_giao_hang_cho_npp BETWEEN '2026-05-18 00:00:00' AND '2026-05-22 23:59:59'
    AND otif_status != 'Không có dữ liệu STM'
  GROUP BY nvc
)
SELECT nvc, n, round(100.0 * n / sum(n) OVER (), 2) AS pct_share
FROM base ORDER BY n DESC LIMIT 10
```

### Q-INS-3 — 2026-05-19 outlier drill by NVC

- **Result**: ANH SON 113 đơn 53.98% OTIF (crash); HDA 98 đơn 76.53%; HVP 22 đơn 100%; NGUYEN PHAT 15 đơn 66.67%; TLL 12 đơn 66.67%; THANH AN 6 đơn 50%; (rỗng) 2 đơn 0%. **HOA PHAT silent (0 row)**.

```sql
SELECT
  if(ten_ngan_nha_van_tai='', '(rỗng)', ten_ngan_nha_van_tai) AS nvc,
  count() AS n,
  countIf(otif_status='OTIF') AS otif_n,
  round(100.0 * countIf(otif_status='OTIF') / count(), 2) AS pct_otif
FROM analytics_workspace.mv_otif
WHERE toDate(eta_giao_hang_cho_npp) = '2026-05-19'
  AND otif_status != 'Không có dữ liệu STM'
GROUP BY nvc ORDER BY n DESC LIMIT 8
```

### Q-INS-4 — NVC name rỗng drill (kho × customer × cargo)

- **Result**: 11 đơn rỗng spread across 11 unique customer, dim mix NKD/BKD1/VN831 × DRY × GT/MT. KHÔNG tập trung 1 pattern → sporadic data gap.

```sql
SELECT whseid, group_of_cago, group_name, customer_name, count() AS n
FROM analytics_workspace.mv_otif
WHERE eta_giao_hang_cho_npp BETWEEN '2026-05-18 00:00:00' AND '2026-05-22 23:59:59'
  AND otif_status != 'Không có dữ liệu STM'
  AND (ten_ngan_nha_van_tai = '' OR ten_ngan_nha_van_tai IS NULL)
GROUP BY whseid, group_of_cago, group_name, customer_name
ORDER BY n DESC LIMIT 10
```

### Q-INS-5 — HOA PHAT 100% breakdown

- **Result**: HOA PHAT 607 đơn ALL từ BKD1, DRY only, MT only, 133 distinct customer. 100% OTIF — concentrated route pattern.

```sql
SELECT whseid, group_of_cago, group_name, count() AS n,
       countIf(otif_status='OTIF') AS otif_n,
       round(100.0 * countIf(otif_status='OTIF') / count(), 2) AS pct_otif,
       count(DISTINCT customer_code) AS n_customers
FROM analytics_workspace.mv_otif
WHERE eta_giao_hang_cho_npp BETWEEN '2026-05-18 00:00:00' AND '2026-05-22 23:59:59'
  AND ten_ngan_nha_van_tai = 'HOA PHAT'
GROUP BY whseid, group_of_cago, group_name ORDER BY n DESC
```

### Q-INS-6 — Whseid orphan check (ngoài 6 mã PRD mapping)

- **Result**: **0 rows** — toàn bộ whseid nằm trong {BKD1,BKD2,BKD3,NKD,VN821,VN831}.

```sql
SELECT whseid, count() AS n
FROM analytics_workspace.mv_otif
WHERE eta_giao_hang_cho_npp BETWEEN '2026-05-18 00:00:00' AND '2026-05-22 23:59:59'
  AND otif_status != 'Không có dữ liệu STM'
  AND whseid NOT IN ('BKD1','BKD2','BKD3','NKD','VN821','VN831')
GROUP BY whseid ORDER BY n DESC
```

### Q-INS-7 — Lateness magnitude (Failed Ontime)

- **Result**: total=200, ≤1h=38, 1-3h=102, 3-12h=26, **>12h=34**, median=120 min (2h), p95=2391 min (~40h), max=2931 min (~49h).

```sql
WITH late AS (
  SELECT dateDiff('minute', eta_giao_hang_cho_npp, ata_den) AS lateness_min
  FROM analytics_workspace.mv_otif
  WHERE eta_giao_hang_cho_npp BETWEEN '2026-05-18 00:00:00' AND '2026-05-22 23:59:59'
    AND otif_status != 'Không có dữ liệu STM'
    AND ontime_status = 'Failed Ontime'
    AND eta_giao_hang_cho_npp IS NOT NULL AND ata_den IS NOT NULL
)
SELECT count(), countIf(lateness_min <= 60), countIf(lateness_min > 60 AND lateness_min <= 180),
       countIf(lateness_min > 180 AND lateness_min <= 720), countIf(lateness_min > 720),
       round(quantile(0.5)(lateness_min)), round(quantile(0.95)(lateness_min)), max(lateness_min)
FROM late
```

### Q-INS-8 — Infull gap magnitude (root cause WH vs Transport)

- **Result**: fail_n=228, avg_gap=58.46 CSE, median=11, p95=276.65; **shipped_lt_planned=13** (WH involvement 5.7%); **delivered_lt_shipped=219** (Transport involvement 96.05%). Tổng > 100% vì overlap (đơn có cả 2 fail).

```sql
SELECT count(),
       round(avg(toFloat64(sum_original_cse) - toFloat64(sum_san_luong_giao_cse)), 2) AS avg_gap_cse,
       round(quantile(0.5)(toFloat64(sum_original_cse) - toFloat64(sum_san_luong_giao_cse)), 2) AS median_gap_cse,
       round(quantile(0.95)(toFloat64(sum_original_cse) - toFloat64(sum_san_luong_giao_cse)), 2) AS p95_gap_cse,
       countIf(toFloat64(sum_shipped_cse) < toFloat64(sum_original_cse)) AS shipped_lt_planned,
       countIf(toFloat64(sum_san_luong_giao_cse) < toFloat64(sum_shipped_cse)) AS delivered_lt_shipped
FROM analytics_workspace.mv_otif
WHERE eta_giao_hang_cho_npp BETWEEN '2026-05-18 00:00:00' AND '2026-05-22 23:59:59'
  AND otif_status != 'Không có dữ liệu STM'
  AND infull_status = 'Failed Infull'
```

### Q-INS-9 — Top 10 customer volume + fail rate

- **Result**: Top 4 WinMart/WinCommerce chain (94+84+48+17 đơn = 243 đơn ≈ 8.14% vol) ALL 0% fail. HPhat Vina 29 đơn 34.48% fail. An Thinh Trading 24 đơn 41.67% fail. Customer name có truncation "WINCOMMERCE" + "DV" missing space → "DVTHUONG MAI".

```sql
WITH base AS (
  SELECT customer_name, count() AS n, countIf(otif_status != 'OTIF') AS fail_n
  FROM analytics_workspace.mv_otif
  WHERE eta_giao_hang_cho_npp BETWEEN '2026-05-18 00:00:00' AND '2026-05-22 23:59:59'
    AND otif_status != 'Không có dữ liệu STM'
  GROUP BY customer_name
)
SELECT customer_name, n, fail_n, round(100.0 * fail_n / n, 2) AS fail_pct,
       round(100.0 * n / sum(n) OVER (), 2) AS vol_share_pct
FROM base ORDER BY n DESC LIMIT 10
```

### Q-INS-10 — Day-of-week pattern (5 days)

- **Result**: Mon 18/05 = 390/75.13%; **Tue 19/05 = 268/66.79%** (lowest); **Wed 20/05 = 1326/88.54%** (peak); Thu 21/05 = 358/76.82%; Fri 22/05 = 644/86.02%. Volume swing 4.95×, OTIF swing 21.75pp.

```sql
SELECT toDate(eta_giao_hang_cho_npp) AS d, toDayOfWeek(eta_giao_hang_cho_npp) AS dow_num,
       count() AS n, round(100.0 * countIf(otif_status='OTIF') / count(), 2) AS pct_otif
FROM analytics_workspace.mv_otif
WHERE eta_giao_hang_cho_npp BETWEEN '2026-05-18 00:00:00' AND '2026-05-22 23:59:59'
  AND otif_status != 'Không có dữ liệu STM'
GROUP BY d, dow_num ORDER BY d
```

### Q-INS-11 — NVC × WinMart customer-group cross

- **Result**: HOA PHAT serves 376 WinMart + 231 Other (607 total) all at 100% — pattern thực sự là service-level outlier, không phải "easy customer". ANH SON serves 37 WinMart at 86.49% vs 1215 Other at 80.41% — WinMart slight boost.

```sql
SELECT ten_ngan_nha_van_tai AS nvc,
       CASE WHEN customer_name LIKE '%WINCOMMERCE%' OR customer_name LIKE '%VinMart%' OR customer_name LIKE '%Vinmart%'
            THEN 'WinMart/WinCommerce' ELSE 'Other' END AS cust_group,
       count() AS n, countIf(otif_status='OTIF') AS otif_n,
       round(100.0 * countIf(otif_status='OTIF') / count(), 2) AS pct_otif
FROM analytics_workspace.mv_otif
WHERE eta_giao_hang_cho_npp BETWEEN '2026-05-18 00:00:00' AND '2026-05-22 23:59:59'
  AND otif_status != 'Không có dữ liệu STM'
  AND ten_ngan_nha_van_tai IN ('HOA PHAT', 'ANH SON', 'HDA', 'TLL', 'NGUYEN PHAT', 'HVP', 'THANH AN')
GROUP BY nvc, cust_group ORDER BY nvc, cust_group
```

### Q-INS-12 — NVC silence (active days in window)

- **Result**: chỉ HOA PHAT active 2/5 ngày (2026-05-20 + 2026-05-22). 6 NVC khác active 5/5 ngày.

```sql
WITH dim AS (
  SELECT toDate(eta_giao_hang_cho_npp) AS d,
         if(ten_ngan_nha_van_tai='', '(rỗng)', ten_ngan_nha_van_tai) AS nvc, count() AS n
  FROM analytics_workspace.mv_otif
  WHERE eta_giao_hang_cho_npp BETWEEN '2026-05-18 00:00:00' AND '2026-05-22 23:59:59'
    AND otif_status != 'Không có dữ liệu STM'
  GROUP BY d, nvc
)
SELECT nvc, count(DISTINCT d) AS days_active, sumIf(n, n>0) AS total_orders,
       arrayStringConcat(groupArrayDistinct(formatDateTime(d, '%Y-%m-%d')), ', ') AS days_with_orders
FROM dim GROUP BY nvc HAVING days_active < 5 ORDER BY days_active ASC, total_orders DESC
```

### Q-INS-13 — ETA/ATA completeness

- **Result**: total=2986, no_ata=0, no_eta=0 — 100% complete.

```sql
SELECT count() AS total, countIf(ata_den IS NULL) AS no_ata,
       countIf(eta_giao_hang_cho_npp IS NULL) AS no_eta,
       round(100.0 * countIf(ata_den IS NULL) / count(), 2) AS pct_no_ata,
       round(100.0 * countIf(ata_den IS NOT NULL AND eta_giao_hang_cho_npp IS NOT NULL) / count(), 2) AS pct_complete
FROM analytics_workspace.mv_otif
WHERE eta_giao_hang_cho_npp BETWEEN '2026-05-18 00:00:00' AND '2026-05-22 23:59:59'
  AND otif_status != 'Không có dữ liệu STM'
```

### Q-INS-14 — Cargo type vs OTIF

- **Result**: DRY 2182 (73.07%) at 89.83% OTIF; **FRESH 673 (22.54%) at 60.92%** OTIF; POSM/OFFBOM 131 (4.39%) at 80.15%. Gap DRY−FRESH = **28.91pp**.

```sql
SELECT if(group_of_cago='', '(rỗng)', group_of_cago) AS cargo,
       count() AS n, countIf(otif_status='OTIF') AS otif_n,
       round(100.0 * countIf(otif_status='OTIF') / count(), 2) AS pct_otif,
       round(100.0 * count() / sum(count()) OVER (), 2) AS vol_share
FROM analytics_workspace.mv_otif
WHERE eta_giao_hang_cho_npp BETWEEN '2026-05-18 00:00:00' AND '2026-05-22 23:59:59'
  AND otif_status != 'Không có dữ liệu STM'
GROUP BY cargo ORDER BY n DESC
```
