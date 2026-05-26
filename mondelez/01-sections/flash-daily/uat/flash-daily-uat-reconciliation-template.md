# UAT Reconciliation Matrix — Flash Daily (Mondelez) — Template (Mode A)

> Mode A empty template. Mode B sẽ duplicate file này thành `flash-daily-uat-dryrun-2026-06-05.md` và fill 3 nguồn thật.
> Source: ClickHouse `analytics_workspace.mv_flash_and_drop_report` (L1-L3, L5, L6) + `mv_dropped_report` (L4, T7, T8) + `mv_flash_report` (T1-T6, T9). Golden file = Mondelez Logistics Analyst export 3 nguồn (SAP plan + WMS shipped + STM giao).
> Tolerance theo `flash-daily-uat-plan.md §7`. **HARD RULE**: KHÔNG mark PASS chỉ với 2 nguồn — thiếu Golden file = block Mode B.

---

## 0. Metadata

| Field | Value |
|---|---|
| Section | Flash Daily |
| Tenant | Mondelez |
| Dry-run date | `<2026-06-05 sẽ fill khi chạy>` |
| Golden file source | `<3 file MDLZ gửi 2026-06-02 — sheet/path sẽ fill: (1) SAP plan export, (2) WMS shipped export, (3) STM giao export>` |
| Golden file received | `<YYYY-MM-DD HH:MM UTC+7>` |
| SQL raw source | ClickHouse `analytics_workspace.mv_flash_and_drop_report` + `mv_dropped_report` + `mv_flash_report`, Mondelez cluster |
| Dashboard environment | `<UAT URL — fill trước Mode B>` |
| Time window mặc định | 2026-06-08 00:00 → 23:59 UTC+7 (D-1 session) |
| Tolerance ref | `flash-daily-uat-plan.md §7` |
| Bug 2026-05-18 regression check | L5 4 panels SUM(total_volume) PARITY L1 Plan denominator (R-013) |

---

## 1. Status tổng (fill sau khi run xong)

| Metric | Value |
|---|---|
| Total rows | 22 |
| Pass (in tolerance) | `<N>` |
| Fail (out-of-tolerance, no root cause) | `<N>` — block session |
| Accepted (out-of-tolerance, customer accept với root cause) | `<N>` |
| Deferred (chưa resolve, convert defect open trước session) | `<N>` |
| **Ready for Mode C session 2026-06-09?** | YES / NO |

---

## 2. Reconciliation rows

> 22 rows: 4 L1 Hero + 3 L2 Exception + 5 L3 funnel + 4 L4 Drop Trend + 4 L5 dim parity + 2 L6 detail.
> Filter context ghi rõ để re-run. SQL query ref Q-NNN trỏ về §3 SQL Appendix.

---

### L1 Hero (4 rows)

#### R-001 — % Hoàn thành hôm nay (L1 Hero giá trị chính)

| Field | Value |
|---|---|
| Metric | `pct_done` (L1 Hero %, target 95%) |
| Filter | Kho/Channel/Cargo/Brand/Region=ALL; Date Type=GI date; UOM=cse |
| Time window | 2026-06-08 00:00 → 23:59 UTC+7 |
| **Dashboard** | `<số đọc L1 Hero>` |
| **SQL raw** | `<số>` — query ref: Q-001 |
| **Golden file khách** | `<số>` — row ref: `<sheet/cell>` |
| Diff Dashboard − Golden | `<số>` (`<pp>`) |
| Tolerance | ≤ 0.5pp |
| **Status** | PASS / FAIL / ACCEPTED / DEFERRED |
| Root cause | |
| Action | |
| Owner | |

#### R-002 — Plan volume L1 (sub-number)

| Field | Value |
|---|---|
| Metric | `total_plan` (L1 sub-number "Plan") |
| Filter | Cùng R-001 |
| Time window | Cùng R-001 |
| **Dashboard** | `<số>` |
| **SQL raw** | `<số>` — Q-001 |
| **Golden file khách (SAP plan export)** | `<số>` |
| Diff | `<số>` (`<%>`) |
| Tolerance | ≤ 1% |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

#### R-003 — Đã giao volume L1 (sub-number)

| Field | Value |
|---|---|
| Metric | `done_volume` (L1 sub-number "Đã giao") |
| Filter | Cùng R-001 |
| Time window | Cùng R-001 |
| **Dashboard** | `<số>` |
| **SQL raw** | `<số>` — Q-001 |
| **Golden file khách (STM giao export)** | `<số>` |
| Diff | `<số>` (`<%>`) |
| Tolerance | ≤ 1% |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

#### R-004 — Còn lại volume L1 (computed = Plan − Đã giao)

| Field | Value |
|---|---|
| Metric | `remaining_volume` = R-002 − R-003 |
| Filter | Cùng R-001 |
| Time window | Cùng R-001 |
| **Dashboard** | `<số>` |
| **SQL raw computed** | R-002 SQL − R-003 SQL |
| **Golden file computed** | R-002 Golden − R-003 Golden |
| Diff Dashboard vs Computed | `<số>` (`<%>`) |
| Tolerance | ≤ 0.01% (computed arithmetic, expect exact match) |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

---

### L2 Exception Spotlight (3 rows)

#### R-005 — L2 ô (a) Top N kho off-target — top 5 ranking match

| Field | Value |
|---|---|
| Metric | Top 5 kho có `pct_done < 85%` sort ASC |
| Filter | Cùng R-001 |
| Time window | Cùng R-001 |
| **Dashboard** | `<list 5 tên kho + %>` |
| **SQL raw** | `<list 5>` — Q-005 (registry "L2 Điểm nóng — Kho") |
| **Golden file khách** | `<list 5>` |
| Diff (ranking match) | `<N/5 tên match>` |
| Tolerance | ≥ 4/5 tên match; % khớp ±0.5pp |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

#### R-006 — L2 ô (b) Đơn rớt chưa xử lý (count)

| Field | Value |
|---|---|
| Metric | Count distinct so có status=Cancel hoặc Close + chưa close lý do |
| Filter | Cùng R-001 |
| Time window | Cùng R-001 |
| **Dashboard** | `<số>` |
| **SQL raw** | `<số>` — Q-006 (registry "L2 Điểm nóng — Drop + Lý do") |
| **Golden file khách** | `<số>` |
| Diff | `<số>` (`<%>`) |
| Tolerance | ≤ 1% |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

#### R-007 — L2 ô (c) Khu vực dưới target — top 5 ranking match

| Field | Value |
|---|---|
| Metric | Top 5 khu vực có `pct_done < 95%` sort ASC |
| Filter | Cùng R-001 |
| Time window | Cùng R-001 |
| **Dashboard** | `<list 5 tên KV + %>` |
| **SQL raw** | `<list 5>` — Q-007 (registry "L2 Điểm nóng — Khu vực") |
| **Golden file khách** | `<list 5>` |
| Diff | `<N/5 match>` |
| Tolerance | ≥ 4/5 tên match; % khớp ±0.5pp |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

---

### L3 Funnel 5 status (5 rows)

#### R-008 — Volume status "Chưa xuất kho"

| Field | Value |
|---|---|
| Metric | `volume_uom` cho `e2e_label = 'Chưa xuất kho'`, UOM=cse |
| Filter | Cùng R-001 |
| Time window | Cùng R-001 |
| **Dashboard** | `<số>` |
| **SQL raw** | `<số>` — Q-008 (registry "Chưa xuất kho") |
| **Golden file khách (WMS open orders)** | `<số>` |
| Diff | `<số>` (`<%>`) |
| Tolerance | ≤ 1% |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

#### R-009 — Volume status "Đang xuất kho"

| Field | Value |
|---|---|
| Metric | `volume_uom` cho `e2e_label = 'Đang xuất kho'`, UOM=cse |
| Filter | Cùng R-001 |
| Time window | Cùng R-001 |
| **Dashboard** | `<số>` |
| **SQL raw** | `<số>` — Q-009 (registry "Đang xuất kho") |
| **Golden file khách (WMS allocate/pick)** | `<số>` |
| Diff | `<số>` (`<%>`) |
| Tolerance | ≤ 1% |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

#### R-010 — Volume status "Đã xuất kho" (STM lag check ở R-EDGE-022)

| Field | Value |
|---|---|
| Metric | `volume_uom` cho `e2e_label = 'Đã xuất kho'` (actual_ship_date NOT NULL + thoi_gian_di IS NULL), UOM=cse |
| Filter | Cùng R-001 |
| Time window | Cùng R-001 |
| **Dashboard** | `<số>` |
| **SQL raw** | `<số>` — Q-010 (registry "Đã xuất kho") |
| **Golden file khách (WMS shipped pending ATD STM)** | `<số>` |
| Diff | `<số>` (`<%>`) |
| Tolerance | ≤ 1% |
| **Status** | |
| Root cause | (note: nếu Golden không tách STM-pending → accept với điều kiện L3 = WMS shipped count) |
| Action | |
| Owner | |

#### R-011 — Volume status "Đang vận chuyển" (STM lag check ở R-EDGE-022)

| Field | Value |
|---|---|
| Metric | `volume_uom` cho `e2e_label = 'Đang vận chuyển'` (thoi_gian_di NOT NULL + ata_den IS NULL), UOM=cse |
| Filter | Cùng R-001 |
| Time window | Cùng R-001 |
| **Dashboard** | `<số>` |
| **SQL raw** | `<số>` — Q-011 (registry "Đang vận chuyển") |
| **Golden file khách (STM đang chạy)** | `<số>` |
| Diff | `<số>` (`<%>`) |
| Tolerance | ≤ 1% |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

#### R-012 — Volume status "Đã vận chuyển"

| Field | Value |
|---|---|
| Metric | `san_luong_giao_cse` cho `e2e_label = 'Đã vận chuyển'` (ata_den NOT NULL), UOM=cse |
| Filter | Cùng R-001 |
| Time window | Cùng R-001 |
| **Dashboard** | `<số>` |
| **SQL raw** | `<số>` — Q-012 (registry "Đã vận chuyển") |
| **Golden file khách (STM giao thành công)** | `<số>` |
| Diff | `<số>` (`<%>`) |
| Tolerance | ≤ 1% |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

> **R-013** (computed): Σ R-008..R-012 phải = R-002 Plan (L1) ± 1%. Nếu lệch → bug 2026-05-18 status canonical filter chưa fix (memory [[feedback_l5_sql_canonical_status_filter]]).

---

### L4 Drop Trend 14 ngày (4 rows)

#### R-014 — L4 drop_rate ngày D-1 (hôm qua)

| Field | Value |
|---|---|
| Metric | `drop_rate = count(status='Cancel') / total_plan × 100` ngày D-1 (per H1 FAIL=Cancel only) |
| Filter | Default filter HOẶC filter-independent (verify behavior Mode B per memory [[project_mondelez_flash_daily_l4_filter_independent]]) |
| Time window | 2026-06-07 (D-1 của session D=2026-06-09; D-1 = ngày trước session) |
| **Dashboard** | `<số %>` |
| **SQL raw** | `<số>` — Q-014 (registry "L4 Trend tỷ lệ rớt 14 ngày") |
| **Golden file khách (Customer drop reason export)** | `<số>` |
| Diff | `<số>` (`<pp>`) |
| Tolerance | ≤ 0.5pp |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

#### R-015 — L4 rolling 30d avg ngày D-1

| Field | Value |
|---|---|
| Metric | `drop_rate_30d_avg` window ROWS BETWEEN 29 PRECEDING AND CURRENT ROW, ngày D-1 |
| Filter | Cùng R-014 |
| Time window | Cùng R-014 (CTE backfill 44 ngày để có 30 priors) |
| **Dashboard** | `<số %>` |
| **SQL raw** | `<số>` — Q-014 |
| **Golden file** | `<computed từ 30 giá trị drop_rate priors>` (PM/BA tính trước Mode B) |
| Diff | `<số>` (`<pp>`) |
| Tolerance | ≤ 0.5pp |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

#### R-016 — L4 14 ngày sequence khớp golden

| Field | Value |
|---|---|
| Metric | 14 điểm drop_rate ASC theo date |
| Filter | Cùng R-014 |
| Time window | 2026-05-25 → 2026-06-07 (14 ngày priors) |
| **Dashboard** | `<list 14 % theo date>` |
| **SQL raw** | `<list 14>` — Q-014 |
| **Golden file** | `<list 14>` (Customer drop export per day) |
| Diff | `<N/14 ngày khớp ±0.5pp>` |
| Tolerance | ≥ 13/14 ngày match |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

#### R-017 — L4 reference line target = 5% solid red

| Field | Value |
|---|---|
| Metric | Visual reference line position + style |
| Filter | Cùng R-014 |
| Time window | Cùng R-014 |
| **Dashboard** | `<note position y=5 + style solid red>` |
| **Spec ref** | Spec §6.7 "Reference line 1: y=5 solid red, label 'Target ≤5%'" |
| **Golden file** | N/A (visual check, không số) |
| Diff | Visual match per Spec |
| Tolerance | Match exactly |
| **Status** | |
| Root cause | (nếu solid grey không phải red → defect Cosmetic; nếu vắng line → Major) |
| Action | |
| Owner | |

---

### L5 Dimension panels parity check (4 rows — regression bug 2026-05-18)

#### R-018 — L5 panel Kho SUM(total_volume) parity L1 Plan

| Field | Value |
|---|---|
| Metric | Σ `total_volume` của tất cả kho trong L5 panel Kho |
| Filter | Cùng R-001, UOM=cse |
| Time window | Cùng R-001 |
| **Dashboard L5 sum** | `<số>` |
| **L1 Plan (R-002)** | `<số>` |
| **SQL raw** | `<số>` — Q-018 (registry "Báo cáo tổng hợp theo kho hệ thống" — verify 5 canonical status filter trong CTE) |
| Diff L5 sum vs L1 Plan | `<số>` (`<%>`) |
| Tolerance | ≤ 1% (parity) |
| **Status** | |
| Root cause | (Critical nếu fail — bug 2026-05-18 chưa fix; check `trang_thai_don_do IN (5 canonical)` filter) |
| Action | |
| Owner | |

#### R-019 — L5 panel Khu vực SUM(total_volume) parity L1 Plan

| Field | Value |
|---|---|
| Metric | Σ `total_volume` của tất cả khu vực trong L5 panel Khu vực |
| Filter | Cùng R-018 |
| Time window | Cùng R-018 |
| **Dashboard L5 sum** | `<số>` |
| **L1 Plan** | `<từ R-002>` |
| **SQL raw** | `<số>` — Q-019 (registry "Báo cáo tổng hợp theo khu vực") |
| Diff | `<số>` (`<%>`) |
| Tolerance | ≤ 1% |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

#### R-020 — L5 panel Customer SUM(total_volume) parity (lưu ý top-10 cap)

| Field | Value |
|---|---|
| Metric | Σ `total_volume` top 10 customer trong L5 panel Customer (KHÔNG dropdown NPP/Customer) |
| Filter | Cùng R-018 |
| Time window | Cùng R-018 |
| **Dashboard L5 sum top 10** | `<số>` |
| **L1 Plan (full)** | `<từ R-002>` |
| **SQL raw all customers** | `<số>` — Q-020 (registry "Báo cáo tổng hợp theo NPP") |
| **SQL raw top 10 only** | `<số>` — derived from Q-020 |
| Diff L5 vs SQL top 10 | `<số>` (`<%>`) |
| Tolerance | ≤ 1% (L5 = SQL top 10, KHÔNG = L1 Plan vì cap) |
| **Status** | |
| Root cause | (note: top 10 cap → L5 < L1; verify cap working) |
| Action | |
| Owner | |

#### R-021 — L5 panel Kênh bán SUM(total_volume) parity L1 Plan

| Field | Value |
|---|---|
| Metric | Σ `total_volume` của tất cả kênh trong L5 panel Kênh |
| Filter | Cùng R-018 |
| Time window | Cùng R-018 |
| **Dashboard L5 sum** | `<số>` |
| **L1 Plan** | `<từ R-002>` |
| **SQL raw** | `<số>` — Q-021 (registry "Báo cáo tổng hợp theo kênh bán hàng") |
| Diff | `<số>` (`<%>`) |
| Tolerance | ≤ 1% |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

---

### L6 Detail tables spot check (1 row)

#### R-022 — T1 Completion row count + spot check 3 rows

| Field | Value |
|---|---|
| Metric | T1 `DSHFLADTG01` row count + spot 3 rows (whName + channel + area + pctHoanThanh) |
| Filter | Cùng R-001 |
| Time window | Cùng R-001 |
| **Dashboard row count** | `<N>` |
| **SQL raw row count** | `<N>` — Q-022 (Completion config-driven SQL) |
| **Synthetic check** | KHÔNG = 54 fixed (drift #7 fix verify) |
| **Golden file** | `<3 row reference>` |
| Diff | `<spot check 3 rows>` |
| Tolerance | Row count khớp SQL exact; 3 spot rows khớp golden ±1% |
| **Status** | |
| Root cause | (Critical nếu = 54 fixed → synthetic chưa removed) |
| Action | |
| Owner | |

---

## 3. SQL Appendix

> Mỗi Q-NNN dùng canonical từ `projects/mondelez/02-data/data-sources/sql-registry.md` section "Flash Report" (line 9437+). Substitute placeholders:
> - `{{whseid}}` / `{{group_name}}` / `{{group_of_cargo}}` / `{{region}}` → `''` (ALL) hoặc quoted CSV list
> - `{{from_date}}` / `{{to_date}}` → `'2026-06-08 00:00:00'` / `'2026-06-08 23:59:59'`
> - `{{date_type}}` → `'GI date'` (default)
> - `{{uom}}` → `'cse'` (default)
>
> Source provenance:
> - **Registry** (canonical): Q-001..Q-022 các metric có SQL trong registry
> - **Ad-hoc**: KHÔNG có (mọi metric trong matrix đều có canonical SQL)

| Q-NNN | Mục đích | Registry section | Pattern note |
|---|---|---|---|
| Q-001 | L1 Hero + Plan + Đã giao + % Hoàn thành | `### Tổng Volume` + `### Đã vận chuyển` | UOM CASE branching theo `{{uom}}` |
| Q-005 | L2 Top N kho off-target | `### L2 Điểm nóng — Kho` | `HAVING pct_done < 85` |
| Q-006 | L2 Đơn rớt count | `### L2 Điểm nóng — Drop + Lý do` | `mv_dropped_report` source |
| Q-007 | L2 Khu vực dưới target | `### L2 Điểm nóng — Khu vực` | `HAVING pct_done < 95` |
| Q-008 | L3 funnel — Chưa xuất kho | `### Chưa xuất kho` | `e2e_label = 'Chưa xuất kho'` |
| Q-009 | L3 funnel — Đang xuất kho | `### Đang xuất kho` | `e2e_label = 'Đang xuất kho'` |
| Q-010 | L3 funnel — Đã xuất kho | `### Đã xuất kho` | `e2e_label = 'Đã xuất kho'` |
| Q-011 | L3 funnel — Đang vận chuyển | `### Đang vận chuyển` | `e2e_label = 'Đang vận chuyển'` |
| Q-012 | L3 funnel — Đã vận chuyển | `### Đã vận chuyển` | `e2e_label = 'Đã vận chuyển'`, `san_luong_giao_cse` |
| Q-014 | L4 Drop Trend 14 ngày | `### L4 Trend tỷ lệ rớt 14 ngày` | CTE backfill 44d, `status='Cancel'` only, rolling 30d avg |
| Q-018 | L5 panel Kho | `### Báo cáo tổng hợp theo kho hệ thống` | ⚠ MUST `trang_thai_don_do IN (5 canonical)` (per memory [[feedback_l5_sql_canonical_status_filter]]) |
| Q-019 | L5 panel Khu vực | `### Báo cáo tổng hợp theo khu vực` | Cùng pattern Q-018 |
| Q-020 | L5 panel Customer (full + top 10) | `### Báo cáo tổng hợp theo NPP` | Cùng pattern + top 10 cap FE-side |
| Q-021 | L5 panel Kênh bán | `### Báo cáo tổng hợp theo kênh bán hàng` | Cùng pattern Q-018 |
| Q-022 | T1 Completion table | `### Bảng tổng hợp` (nếu có) hoặc config-driven SQL admin paste qua Settings dialog | T1 PHẢI non-empty, KHÔNG render synthetic 54 rows |

(SQL block đầy đủ paste tại Mode B run — script dynamic-load từ registry trong Python pipeline `scripts/uat_flash_daily_export.py` khi PM trigger build Excel pack)

---

## 4. Notes for Mode B

- **Bắt buộc trước Mode B**:
  - Golden file 3 nguồn (SAP plan / WMS shipped / STM giao) đã nhận từ MDLZ Logistics Analyst ≥ 3 ngày trước session.
  - `tblCompletion` SQL non-empty trên env UAT — verify trước, nếu không có thì block (drift #7 fix verify).
  - 15 SQL section keys non-empty (`hasSqlConfig = true`).
  - MV refresh < 2h trước dry-run run.
- **Bug 2026-05-18 regression check**: R-013 (computed) + R-018..R-021 phải PASS — đây là regression gate. Fail → block Mode C.
- **STM lag check**: R-010 + R-011 có thể accept với golden không tách STM-pending — note rõ accept trong row. R-EDGE-022 (UAT-FLASH-006 test case) verify mutually exclusive qua SQL raw.
- **L4 filter-independent**: confirm behavior trên UAT env trước Mode B — nếu L4 áp filter (Spec §6.7) → note rõ; nếu filter-independent (memory [[project_mondelez_flash_daily_l4_filter_independent]]) → R-014..R-017 dùng default filter cho L1-L3 nhưng L4 vẫn full window 14 ngày.
- **L4 reference lines**: R-017 visual check — verify color (solid red cho target, dashed grey cho rolling) + label text "Target ≤5%".

---

## 5. Defer rule

Nếu Mode B phát hiện row out-of-tolerance không có root cause:
- Critical regression (R-013, R-018..R-021 fail bug 2026-05-18) → **STOP**, dev fix trước Mode C
- Layer A row fail (R-001..R-012) → log defect Critical/Major + chuyển status DEFERRED, mở defect stub trước session
- L4 row fail (R-014..R-017) → log defect Major + accept Defer nếu Customer Ops Manager OK (L4 là chart mới, có thể accept với hotfix tracking)
- L6 row fail (R-022) → log defect Critical nếu T1 synthetic fallback render (drift #7)

Tất cả deferred row phải mở UAT-{NNN} defect stub trước Mode C session, ghi rõ status "deferred to fix before signoff".
