# UAT Reconciliation Matrix — OTIF (Mondelez) — Template (Mode A)

> Mode A empty template. Mode B sẽ duplicate file này thành `otif-uat-dryrun-2026-06-01.md` và fill 3 nguồn thật.
> Source: ClickHouse `analytics_workspace.mv_otif` (Mondelez tenant). Golden file = Logistics Analyst MDLZ export pipeline báo cáo nội bộ.
> Tolerance theo `otif-uat-plan.md §7`. KHÔNG mark PASS chỉ với 2 nguồn.

---

## 0. Metadata

| Field | Value |
|---|---|
| Section | OTIF |
| Tenant | Mondelez |
| Dry-run date | `<2026-06-01 sẽ fill khi chạy>` |
| Golden file source | `<file MDLZ gửi 2026-05-29 — sheet/path sẽ fill>` |
| Golden file received | `<YYYY-MM-DD HH:MM UTC+7>` |
| SQL raw source | ClickHouse `analytics_workspace.mv_otif`, Mondelez cluster |
| Dashboard environment | `<UAT URL — fill trước Mode B>` |
| Time window mặc định | 2026-06-02 00:00 → 23:59 UTC+7 (D-1 session) |
| Tolerance ref | `otif-uat-plan.md §7` |

---

## 1. Status tổng (fill sau khi run xong)

| Metric | Value |
|---|---|
| Total rows | 18 |
| Pass (in tolerance) | `<N>` |
| Fail (out-of-tolerance, no root cause) | `<N>` — block session |
| Accepted (out-of-tolerance, customer accept với root cause) | `<N>` |
| Deferred (chưa resolve, convert defect open trước session) | `<N>` |
| **Ready for Mode C session 2026-06-03?** | YES / NO |

---

## 2. Reconciliation rows

> 18 rows: 1 tổng đơn + 3 % KPI + 5 fail bucket + 5 top-N dim + 2 trend point + 2 edge. Filter context ghi rõ để re-run.

### R-001 — Tổng đơn (KPI Tổng đơn)

| Field | Value |
|---|---|
| Metric | `totalSo` (KPI card #1) |
| Filter | NPP/Kho/Khu vực/Loại hàng/NVC=ALL; Loại ngày=ETA gửi thầu |
| Time window | 2026-06-02 00:00 → 23:59 UTC+7 |
| **Dashboard** | `<số đọc KPI card>` |
| **SQL raw** | `<số>` — query ref: Q-001 |
| **Golden file khách** | `<số>` — row ref: `<sheet>` |
| Diff Dashboard − Golden | `<số>` (`<%>`) |
| Tolerance | ≤ 1% |
| **Status** | PASS / FAIL / ACCEPTED / DEFERRED |
| Root cause | |
| Action | |
| Owner | |

### R-002 — % OTIF (KPI #4)

| Field | Value |
|---|---|
| Metric | `pctOtif` |
| Filter | Default |
| Time window | Default |
| **Dashboard** | `<%>` |
| **SQL raw** | `<%>` — Q-002 |
| **Golden file** | `<%>` |
| Diff (pp) | `<pp>` |
| Tolerance | ≤ 0.5 pp |
| **Status** | |
| Root cause | |
| Action | |

### R-003 — % Ontime (KPI #2)

| Field | Value |
|---|---|
| Metric | `pctOntime` |
| Filter | Default |
| **Dashboard** | `<%>` |
| **SQL raw** | `<%>` — Q-003 |
| **Golden file** | `<%>` (note: nếu golden không có Ontime riêng → ghi `<N/A — golden không có>`, accept với SQL raw làm chuẩn) |
| Diff | |
| Tolerance | ≤ 0.5 pp |
| **Status** | |

### R-004 — % Infull (KPI #3)

| Field | Value |
|---|---|
| Metric | `pctInfull` |
| Filter | Default |
| **Dashboard** | `<%>` |
| **SQL raw** | `<%>` — Q-004 |
| **Golden file** | `<%>` (note: nếu golden không có Infull riêng → N/A) |
| Diff | |
| Tolerance | ≤ 0.5 pp |
| **Status** | |

### R-005 — Fail Ontime bucket: Lỗi transport giao trễ

| Field | Value |
|---|---|
| Metric | `late_delivery_by_transport` (= `chartFailOntime` bar "Lỗi transport giao trễ") |
| Filter | Default |
| **Dashboard** | `<fail_so>` |
| **SQL raw** | `<số>` — Q-005 (apply `classifyReason()` PRD §3) |
| **Golden file** | `<số>` (nếu có breakdown lý do) |
| Diff | |
| Tolerance | ≤ 1% |
| **Status** | |

### R-006 — Fail Ontime bucket: Lỗi warehouse gọi vào kho trễ

| Field | Value |
|---|---|
| Metric | `late_wh_call_by_warehouse` |
| Filter | Default |
| **Dashboard** | `<fail_so>` |
| **SQL raw** | `<số>` — Q-006 |
| **Golden file** | `<số>` |
| Tolerance | ≤ 1% |
| **Status** | |

### R-007 — Fail Ontime bucket: Lỗi transport vào kho trễ

| Field | Value |
|---|---|
| Metric | `late_arrival_by_transport` |
| Filter | Default |
| **Dashboard** | `<fail_so>` |
| **SQL raw** | `<số>` — Q-007 |
| **Golden file** | `<số>` |
| Tolerance | ≤ 1% |
| **Status** | |

### R-008 — Fail Infull bucket: Warehouse failure

| Field | Value |
|---|---|
| Metric | `warehouse_infull_failure` |
| Filter | Default |
| **Dashboard** | `<fail_so>` |
| **SQL raw** | `<số>` — Q-008 |
| **Golden file** | `<số>` |
| Tolerance | ≤ 1% |
| **Status** | |

### R-009 — Fail Infull bucket: Transport failure

| Field | Value |
|---|---|
| Metric | `transport_infull_failure` |
| Filter | Default |
| **Dashboard** | `<fail_so>` |
| **SQL raw** | `<số>` — Q-009 |
| **Golden file** | `<số>` |
| Tolerance | ≤ 1% |
| **Status** | |

### R-010 — Top 5 NVC theo % OTIF (worst-first)

| Field | Value |
|---|---|
| Metric | Ranking dim NVC trong Health Matrix |
| Filter | Default |
| **Dashboard** (top 5 worst) | 1.`<>` 2.`<>` 3.`<>` 4.`<>` 5.`<>` |
| **SQL raw** | 1.`<>` 2.`<>` 3.`<>` 4.`<>` 5.`<>` — Q-010 |
| **Golden file** | 1.`<>` 2.`<>` 3.`<>` 4.`<>` 5.`<>` |
| Match count (Dashboard vs Golden) | `<X/5>` |
| Tolerance | ≥ 4/5 tên match |
| **Status** | |

### R-011 — Top Kho theo % OTIF (4 group)

| Field | Value |
|---|---|
| Metric | Ranking dim Kho (BKD / NKD / Kho ngoài BKD / Kho ngoài NKD) |
| Filter | Default |
| **Dashboard** | 1.`<>` 2.`<>` 3.`<>` 4.`<>` |
| **SQL raw** | 1.`<>` 2.`<>` 3.`<>` 4.`<>` — Q-011 (whseid mapping) |
| **Golden file** | 1.`<>` 2.`<>` 3.`<>` 4.`<>` |
| Match count | `<X/4>` |
| Tolerance | ≥ 3/4 match (dim cardinality nhỏ) |
| **Status** | |
| Note | Verify whseid mapping: BKD=BKD1+BKD2+BKD3, NKD=NKD, Kho ngoài BKD=VN821, Kho ngoài NKD=VN831 |

### R-012 — Top Loại hàng theo % OTIF (sort priority)

| Field | Value |
|---|---|
| Metric | Ranking dim Loại hàng |
| Filter | Default |
| **Dashboard** (theo `OTIF_CATEGORY_ORDER`) | FRESH=`<%>` DRY=`<%>` MOONCAKE=`<%>` POSM=`<%>` TEST=`<%>` EQUIPMENT=`<%>` PM=`<%>` |
| **SQL raw** | FRESH=`<%>` ... — Q-012 |
| **Golden file** | FRESH=`<%>` ... |
| Diff worst category | `<pp>` |
| Tolerance | ≤ 0.5 pp per category; sort order khớp priority 1-7 |
| **Status** | |

### R-013 — Top Kênh theo % OTIF

| Field | Value |
|---|---|
| Metric | Ranking dim Kênh |
| Filter | Default |
| **Dashboard** | 1.`<>` 2.`<>` 3.`<>` |
| **SQL raw** | — Q-013 |
| **Golden file** | |
| Match count | `<X/3>` |
| Tolerance | ≥ 2/3 match |
| **Status** | |

### R-014 — Top Khu vực theo % OTIF

| Field | Value |
|---|---|
| Metric | Ranking dim Khu vực (South East / Ho Chi Minh / Mekong 1 / Mekong 2 / ...) |
| Filter | Default |
| **Dashboard** | 1.`<>` 2.`<>` 3.`<>` 4.`<>` |
| **SQL raw** | — Q-014 |
| **Golden file** | |
| Match count | `<X/4>` |
| Tolerance | ≥ 3/4 match |
| **Status** | |

### R-015 — Trend point D-1 (% OTIF ngày 2026-06-02)

| Field | Value |
|---|---|
| Metric | Trend chart bucket=Day point D-1 |
| Filter | Khoảng ngày = 7 ngày gần nhất |
| **Dashboard** | `<%>` |
| **SQL raw** | `<%>` — Q-015 (chartTrend bucket=Day) |
| **Golden file** | `<%>` daily |
| Diff | |
| Tolerance | ≤ 0.5 pp |
| **Status** | |

### R-016 — Trend point worst trong 7 ngày

| Field | Value |
|---|---|
| Metric | Trend point có % OTIF thấp nhất trong window 7d (test target band visual) |
| Filter | Khoảng ngày = 7 ngày gần nhất |
| **Dashboard** | Ngày=`<>` %=`<>` |
| **SQL raw** | Ngày=`<>` %=`<>` — Q-016 |
| **Golden file** | Ngày=`<>` %=`<>` |
| Diff | |
| Tolerance | Ngày khớp + % ≤ 0.5pp |
| **Status** | |
| Note | Verify point này nằm dưới target band xanh 90% |

### R-017 — Edge timezone: đơn 23:30 UTC+7 D-1 + 00:30 UTC+7 D

| Field | Value |
|---|---|
| Metric | DO test code `<TEST-001>` (23:30 D-1) + `<TEST-002>` (00:30 D) — yêu cầu dev CH chuẩn bị |
| Filter | Khoảng ngày = D-1 (single day) |
| **Dashboard** Detail Table | TEST-001 có trong list? `<Y/N>`; TEST-002 có? `<Y/N>` |
| **SQL raw** | TEST-001 có? `<Y/N>`; TEST-002 có? `<Y/N>` — Q-017 |
| **Golden file** | Khách export filter D-1 → có TEST-001 không? `<Y/N>` |
| Expected | TEST-001=Y, TEST-002=N (đúng UTC+7 cutoff) |
| Tolerance | Exact match (Y/N) |
| **Status** | |

### R-018 — Edge filter Kho mapping (BKD = BKD1+BKD2+BKD3)

| Field | Value |
|---|---|
| Metric | Tổng đơn khi filter Kho=BKD |
| Filter | Kho=BKD, ngày=D-1 |
| **Dashboard** | `<số>` |
| **SQL raw** với `whseid IN ('BKD1','BKD2','BKD3')` | `<số>` — Q-018 |
| **Golden file** | `<số>` (filter MDLZ định nghĩa kho BKD) |
| Diff | |
| Tolerance | ≤ 1% |
| **Status** | |

---

## 3. Diff resolution status

| Status | Định nghĩa | Action trước session 2026-06-03 |
|---|---|---|
| **PASS** | Diff trong tolerance | Không action |
| **FAIL** | Diff vượt tolerance, chưa có root cause | Block session 2026-06-03, phải resolve hoặc accept/defer |
| **ACCEPTED** | Diff vượt tolerance, có root cause, khách đã accept (ghi rõ ai accept, khi nào) | Note trong dry-run report; ack với khách qua email trước session |
| **DEFERRED** | Diff vượt tolerance, sẽ convert defect open trước session, khách biết trước | Tạo defect stub `defects/UAT-{NNN}-{slug}.md`, gửi customer Ops Manager |

**Rule cứng**: 0 row FAIL khi bước vào Mode C. Toàn bộ phải PASS/ACCEPTED/DEFERRED.

---

## 4. Appendix — SQL queries

> Mỗi Q-NNN sẽ fill chi tiết trong Mode B dry-run. Pattern tham khảo từ `mv_otif` MV và 12 SQL widget config (PRD §6).

### Q-001 — Tổng đơn

```sql
-- Source: analytics_workspace.mv_otif (Mondelez)
-- Filter: default ALL
-- Time window: 2026-06-02 00:00 → 23:59 UTC+7
-- Run at: <2026-06-01 HH:MM UTC+7 sẽ fill>

SELECT count(DISTINCT do_code) AS total_so
FROM analytics_workspace.mv_otif
WHERE eta_ngay_gui_thau BETWEEN '2026-06-02 00:00:00' AND '2026-06-02 23:59:59'
  AND otif_status != 'Không có dữ liệu STM';   -- exclude theo PRD §6 note canonical

-- Result: <số>
```

### Q-002 — % OTIF

```sql
-- Pattern: chartByCategory r6 production-verified (PRD §6 note)
-- Apply: COUNT OTIF / COUNT total × 100

SELECT
  100.0 * countIf(is_otif = 1) / count() AS pct_otif
FROM analytics_workspace.mv_otif
WHERE eta_ngay_gui_thau BETWEEN '2026-06-02 00:00:00' AND '2026-06-02 23:59:59'
  AND otif_status != 'Không có dữ liệu STM';

-- Result: <%>
```

### Q-003 — % Ontime

```sql
-- Apply Ontime definition PRD §3: ATA ≤ ETA
SELECT
  100.0 * countIf(is_ontime = 1) / count() AS pct_ontime
FROM analytics_workspace.mv_otif
WHERE ...;
```

### Q-004 — % Infull

```sql
-- Apply Infull definition: planned_cse = shipped_cse = delivered_cse
SELECT
  100.0 * countIf(is_infull = 1) / count() AS pct_infull
FROM analytics_workspace.mv_otif
WHERE ...;
```

### Q-005..Q-009 — Fail buckets

```sql
-- classifyReason() / classifyInfullBucket() PRD §3 — apply CASE WHEN
-- Q-005: late_delivery_by_transport
-- Q-006: late_wh_call_by_warehouse
-- Q-007: late_arrival_by_transport
-- Q-008: warehouse_infull_failure
-- Q-009: transport_infull_failure
```

### Q-010..Q-014 — Top N per dimension

```sql
-- chartByTransporter / chartByWarehouse / chartByCategory / chartBySalesChannel / chartByArea
-- Pattern: ORDER BY pct_otif ASC LIMIT 5 (worst-first)
```

### Q-015..Q-016 — Trend point

```sql
-- chartTrend bucket=Day
SELECT
  toDate(eta_ngay_gui_thau) AS day,
  100.0 * countIf(is_otif = 1) / count() AS pct_otif
FROM analytics_workspace.mv_otif
WHERE eta_ngay_gui_thau BETWEEN '<7d ago>' AND '<D>'
  AND otif_status != 'Không có dữ liệu STM'
GROUP BY day
ORDER BY day;
```

### Q-017 — Edge timezone DO test

```sql
SELECT do_code, eta_ngay_gui_thau, toDateTime(eta_ngay_gui_thau, 'Asia/Ho_Chi_Minh') AS eta_utc7
FROM analytics_workspace.mv_otif
WHERE do_code IN ('<TEST-001>', '<TEST-002>');
```

### Q-018 — Edge filter Kho mapping

```sql
SELECT count(DISTINCT do_code) AS total_so
FROM analytics_workspace.mv_otif
WHERE whseid IN ('BKD1','BKD2','BKD3')
  AND eta_ngay_gui_thau BETWEEN '<D-1 00:00>' AND '<D-1 23:59>';
```

---

## 5. Appendix — Golden file mapping

| Row | Golden file sheet | Golden file row/col | Notes |
|---|---|---|---|
| R-001 | `<sheet "KPI">` | `<row N>` Total Orders | |
| R-002 | `<sheet "KPI">` | OTIF % | |
| R-003 | `<sheet "KPI">` | OnTime % | `<có riêng không?>` |
| R-004 | `<sheet "KPI">` | Infull % | `<có riêng không?>` |
| R-005..R-009 | `<sheet "Fail breakdown">` | per bucket | Nếu golden không có breakdown → accept SQL raw chuẩn |
| R-010 | `<sheet "By NVC">` | Top 5 | |
| R-011 | `<sheet "By Kho">` | 4 group | Verify cùng định nghĩa BKD/NKD/... |
| R-012 | `<sheet "By Loại hàng">` | 7 category | |
| R-013 | `<sheet "By Kênh">` | | |
| R-014 | `<sheet "By Khu vực">` | | |
| R-015..R-016 | `<sheet "Daily trend">` | per day | |
| R-017 | Khách export filter D-1 | DO codes list | Yêu cầu khách export raw DO list để verify |
| R-018 | `<sheet "By Kho">` | BKD only | |

Lưu ý: Nếu golden không có sẵn metric/breakdown → ghi rõ `<N/A — golden không có>` và accept với SQL raw làm chuẩn (note trong row Action).

---

## 6. Decision before Mode C session 2026-06-03

| Role | Decision | Signed | Date |
|---|---|---|---|
| Smartlog PM (thuy le) | Ready / Not ready | | |
| Smartlog BA (thuy le) | Ready / Not ready | | |
| (Optional) Customer IT MDLZ | Ack reconciliation | | |
