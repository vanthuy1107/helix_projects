# Ops Insight Pack — Flash Daily UAT (Mondelez) — 2026-06-08

> Mode A optional artifact. **File riêng, KHÔNG nhồi vào Excel UAT pack** (Excel pack tập trung reconciliation thuần; insight md cho audience PM/BA, share Slack/email).
> Window: 2026-06-08 (D-1 session 2026-06-09).
> Source: ClickHouse `analytics_workspace.mv_flash_and_drop_report` + `mv_dropped_report` (Mondelez cluster). Ad-hoc Q-INS-* SQL (KHÔNG phải registry).
> Author: PM/BA — thuy le. Date: 2026-05-26.

---

## 1. Headline

> **Giả định reconciliation pass 100% trong session UAT 2026-06-09**, câu chuyện vận hành Flash Daily đứng sau số sẽ nói gì với MDLZ?

Verdict đề xuất cho session: **GO**, với 3 caveat phải address trong session:
1. **STM lag operational confusion** — 2 status "Đã xuất kho" / "Đang vận chuyển" có operational drift do STM signal lag >12h. Mặc dù MV pre-computes mutually exclusive (Audit A3) → KHÔNG inflate count, nhưng UX có thể confuse "đã rời kho mà sao vẫn Đã xuất kho?".
2. **Drop bucket pattern match fragile** — T7 dùng substring match trên `delivery_to_customer` field ("tổng kế hoạch" / "xử lý thành công" / "xử lý ko thành công") — nếu MDLZ đổi naming convention export → bucket logic vỡ silently.
3. **L4 chart MỚI, chưa run production lâu** — Drop Trend 14 ngày là chart đầu tiên trong CT Mondelez sử dụng rolling window 30d CTE backfill 44d. Perf risk khi mở rộng tenant volume lớn.

---

## 2. Master Data Quality Scorecard (8 trục)

| Trục | Coverage % (estimate) | Risk nếu thấp | Action recommend |
|---|---|---|---|
| `whseid` coverage | ~99% | High — kho rỗng → L5 panel Kho lệch | Q-INS-01 verify Mode B; nếu < 95% → block UAT |
| `delivery_date_1` (GI date) completeness | ~98% | High — default date_type → ảnh hưởng cả 5 status filter | Q-INS-02 verify |
| `actual_ship_date` completeness | ~85-90% | Med — đơn rớt thường thiếu ASD → ảnh hưởng "Đã xuất kho" bucket | Q-INS-03 verify trước session |
| `thoi_gian_di` (ATD STM signal) coverage | ~75-80% | High — quyết định "Đã xuất kho" vs "Đang vận chuyển" mutually exclusive | Q-INS-04 — đo lag % và max delay |
| `ata_den` (ATA STM signal) coverage | ~70-75% | High — quyết định "Đang vận chuyển" vs "Đã vận chuyển" | Q-INS-05 |
| `group_of_cago` (Cargo Group) fill rate | ~95% | Low — fallback 'Unclassified' | Q-INS-06; verify Unclassified % < 5% |
| `customer_name` (NPP=Customer) Vietnamese diacritics | Unknown | Med — UX visual confusion nếu encoding lỗi | Q-INS-07 spot 50 row |
| `khu_vuc_doi_xe` (Region) standardized values | Unknown | Med — 10 region options FE expect, nếu raw có thêm/khác → fallback Unclassified | Q-INS-08 verify enum match |

---

## 3. 6 Operational Red Flags

### RF-01 — STM signal lag inflate "Đã xuất kho" bucket

| Field | Value |
|---|---|
| Title | Đơn đã rời kho >12h nhưng `thoi_gian_di IS NULL` vẫn nằm trong bucket "Đã xuất kho" |
| Severity | Major (UX confusion, KHÔNG data wrong) |
| Layer | L3 funnel + caveat tooltip |
| Quan sát | Q-INS-04: count đơn có `actual_ship_date < now()-12h AND thoi_gian_di IS NULL` |
| So sánh | Expect 0 đơn (ideal); thực tế Mondelez có thể ~5-15% đơn |
| Giả thuyết | STM signal lag — đơn vật lý đã rời kho, signal chưa nhận. Pre-computed `e2e_label` đúng theo signal availability tại thời điểm refresh MV. |
| Đề xuất | (a) Caveat tooltip "Chưa nhận tín hiệu ATD từ STM" trên 2 KPI status (PRD §3.1 v1.1.0 đã add); (b) Audit STM integration lag metric riêng, expose qua module Monitors phase 2 |
| Route handoff | `/da-ch` audit `mv_flash_and_drop_report` refresh frequency; `/ba` add STM lag KPI |
| Source query | Q-INS-04 |

### RF-02 — Drop bucket pattern match fragile (substring)

| Field | Value |
|---|---|
| Title | T7 bucket detection dùng substring `"tổng kế hoạch"`/`"xử lý thành công"`/`"xử lý ko thành công"` trên field `delivery_to_customer` — fragile khi MDLZ đổi naming |
| Severity | Major (silent bug nếu fragile) |
| Layer | T7 / Dropped report |
| Quan sát | `droppedDeliveryMetricRows` ở widget-flash-daily.tsx:1921-2049 dùng pattern match cứng |
| So sánh | OQ-07 best practice: pre-computed bucket trong MV qua trường `bucket_type` enum, không string match FE |
| Giả thuyết | Khi MDLZ đổi naming convention (vd "Hủy đơn" thay vì "xử lý ko thành công"), bucket Failed → 0, "Đang xử lý" inflate sai |
| Đề xuất | (a) Q-INS-09 enum tất cả unique `delivery_to_customer` value 30d gần đây; (b) Phase 2: chuyển bucket pre-compute vào MV `mv_dropped_report.bucket_type` enum |
| Route handoff | `/da-ch` add bucket_type column; `/ba` update PRD §3.4 |
| Source query | Q-INS-09 |

### RF-03 — `group_of_cago` typo trong source schema

| Field | Value |
|---|---|
| Title | Field name `group_of_cago` (thiếu "r") trong MV — nhưng FE filter dùng key `group_of_cargo` (đúng spelling) → SQL config phải tay alias |
| Severity | Minor (technical debt) |
| Layer | SQL config + ETL |
| Quan sát | Registry "Báo cáo tổng hợp theo X" Flash Report section: `coalesce(group_of_cago, 'Unclassified')` |
| So sánh | FE filter `applied.groupOfCargo` (đúng "cargo") |
| Giả thuyết | Typo ETL ban đầu, kéo dài đến giờ chưa fix |
| Đề xuất | Phase 2 cleanup: rename `group_of_cago` → `group_of_cargo` trong MV + update SQL registry; risk migrate FormConfig cho T9 detail |
| Route handoff | `/da-ch` schema migration |
| Source query | Q-INS-06 |

### RF-04 — `customer_name` encoding diacritics

| Field | Value |
|---|---|
| Title | Vietnamese diacritics trong `customer_name` có thể bị mangle qua ETL pipeline → UX display "Cong ty TNHH" thay vì "Công ty TNHH" |
| Severity | Minor (UX) |
| Layer | L5 panel Customer + T4 + T9 |
| Quan sát | Q-INS-07 spot 50 row customer_name có diacritics gốc; verify UTF-8 |
| So sánh | Expect 100% diacritics preserved |
| Giả thuyết | ETL stage có thể strip diacritics nếu encoding chưa explicit UTF-8 |
| Đề xuất | Q-INS-07 verify trước session; nếu fail → escalate dev CH check ETL encoding |
| Route handoff | `/da-ch` audit encoding pipeline |
| Source query | Q-INS-07 |

### RF-05 — L4 chart filter behavior conflict (Spec §6.7 vs memory)

| Field | Value |
|---|---|
| Title | Spec §6.7 nói L4 áp filter parity với L1-L3 (G5 chốt) — NHƯNG memory [[project_mondelez_flash_daily_l4_filter_independent]] nói L4 filter-independent (override G5). Cần verify behavior thực tế trên UAT env. |
| Severity | Major (PRD/spec drift) |
| Layer | L4 design intent |
| Quan sát | Spec §6.7 "Filter parity: áp cùng filter bar với L1-L3 (G5 chốt)" vs memory ngược lại |
| So sánh | Tracing: G5 nguyên thủy chốt filter parity; memory override sau (date 2026-05-XX) |
| Giả thuyết | Quyết định đảo chiều sau session PM ngày 2026-05-XX, memory đúng — spec chưa update |
| Đề xuất | (a) Mode B verify behavior thực tế; (b) Update Spec §6.7 reflect memory decision; (c) PM align với customer trong session |
| Route handoff | `/da-trace` confirm drift; `/ba` update PRD §6.6 + spec §6.7 |
| Source query | N/A (drift check, không số) |

### RF-06 — 17 useQuery song song page load risk

| Field | Value |
|---|---|
| Title | Page load Flash Daily fire 17 API call song song — nặng hơn 2× OTIF (9 query). Browser HTTP/2 concurrent stream limit 100; CH backend connection pool limit. |
| Severity | Major (perf) |
| Layer | Spec §3.1 + PRD §7 + OQ-09 |
| Quan sát | Spec §3.1: tối đa 17 request song song khi widget load |
| So sánh | OQ-09 chốt consolidate 17 → 5 query v1.3.0 performance phase |
| Giả thuyết | Tenant Mondelez data volume lớn (~50-100k đơn/ngày) → 17 query có thể queue/timeout |
| Đề xuất | (a) UAT-FLASH-025 test perf < 5s page load (regression gate); (b) Profile từng query thời gian execution; (c) Track v1.3.0 consolidation |
| Route handoff | `/da-ch` profile query perf; `/da-pm` track v1.3.0 milestone |
| Source query | Q-INS-10 (CH query log) |

---

## 4. 9 KPI Extension đề xuất (Roadmap)

> Insight bổ sung — KPI hiện hành đo "trạng thái snapshot", nhưng vận hành Ops Manager còn cần "xu hướng + variance".

| # | KPI đề xuất | Tại sao | Layer phù hợp | Phase |
|---|---|---|---|---|
| 1 | STM lag % (đơn có `actual_ship_date NOT NULL` nhưng `thoi_gian_di IS NULL > 12h`) | Quantify operational drift RF-01 | L2 (4th exception ô) | v1.2.0 |
| 2 | Per-cargo target override (DRY 95% / FRESH 90% / POSM 80%) | Per memory: hiện overall 95% — F1 reframe v1.2.0 nếu UAT feedback "MT/POSM bị đỏ oan" | L1 RAG band per filter | v1.2.0 (UAT-conditional) |
| 3 | Lateness histogram (đơn rớt theo bucket độ trễ: <1h / 1-4h / 4-8h / >8h) | Currently chỉ có count drop, không có severity drop | T8 Drop Reason extend | v1.2.0 |
| 4 | NVC concentration index (top 3 NVC % share đơn rớt) | Vận tải phụ thuộc 1-2 NVC = high risk | L2 (5th exception ô) | v1.3.0 |
| 5 | Daily variance % (variance Plan SAP vs Actual WMS shipped per day) | "Kế hoạch SAP có sát không?" — input planner | L4 sister chart | v1.3.0 |
| 6 | First-time-right rate per kho (đơn không có "Đang xử lý" bucket) | Đo độ trơn tru process | L5 Kho panel sub-metric | v1.3.0 |
| 7 | Cross-dim cohort (đơn theo Cargo × Channel × Region) heat map | Find combinations have outliers | New section L7 | v1.4.0 |
| 8 | NPP early-warning (NPP có ≥ 30% volume rớt 2 tuần liên tục) | Proactive — không cần đợi đơn rớt | Module Monitors integration | v2.0 |
| 9 | Forecasting drop_rate next 7 days (regression từ rolling 30d) | Predictive thay vì retrospective | L4 extension | v2.0 |

---

## 5. 7 Open Questions mang vào session UAT

| # | Question | Gửi cho | Tại sao quan trọng |
|---|---|---|---|
| OQ-A | "Target 95% % Hoàn thành áp dụng cho mọi cargo group hay nên có per-cargo (DRY 95 / POSM 80)?" | Ops Manager + Logistics Analyst | F1 reframe — nếu fail UAT → defer v1.2.0 |
| OQ-B | "Khi STM signal lag >12h, đơn đã rời kho hiện vẫn nằm 'Đã xuất kho' — UX có chấp nhận không?" | Ops Manager + WH Manager | RF-01 — quyết định Phase 2 STM lag KPI |
| OQ-C | "Drop bucket 4 loại (Tổng KH / Success / Failed / In-progress) có đủ không, hay cần thêm bucket vd 'Pending customer accept'?" | Logistics Analyst | RF-02 — bucket extension |
| OQ-D | "L4 Drop Trend 14 ngày fixed window có hữu ích không, hay nên có dropdown 7/14/30 ngày?" | Ops Manager | G1 reframe — verify decision |
| OQ-E | "L5 4 dim panels (Kho/Khu vực/Khách/Kênh) có đủ không, hay cần thêm Cargo Group?" | Ops Manager | L5 extension v1.2.0 |
| OQ-F | "Alert banner <80% xuất hiện full-width — có nên có sound/notification không?" | Ops Manager + IT rep | Module Monitors phase 2 |
| OQ-G | "Khi NPP=Customer (Mondelez đặc thù), report có cần distinguish NPP-direct vs sub-customer của NPP không?" | Logistics Analyst | OQ-07 dropped sau, nếu UAT trả ngược → revisit |

---

## 6. Appendix — Q-INS-* SQL Evidence (ad-hoc, KHÔNG registry)

```sql
-- Q-INS-01: whseid coverage (% đơn có whseid not null vs total)
-- Window: last 30 days
SELECT
  count() AS total_orders,
  countIf(whseid IS NOT NULL AND whseid != '') AS with_whseid,
  round(100.0 * countIf(whseid IS NOT NULL AND whseid != '') / count(), 2) AS coverage_pct
FROM analytics_workspace.mv_flash_and_drop_report
WHERE toDate(delivery_date_1) BETWEEN today() - 30 AND today();

-- Q-INS-02: delivery_date_1 (GI date) completeness
SELECT
  count() AS total_rows,
  countIf(delivery_date_1 IS NOT NULL) AS with_gi_date,
  round(100.0 * countIf(delivery_date_1 IS NOT NULL) / count(), 2) AS pct
FROM analytics_workspace.mv_flash_and_drop_report
WHERE toDate(delivery_date_1) BETWEEN today() - 30 AND today();

-- Q-INS-03: actual_ship_date completeness theo bucket
SELECT
  e2e_label,
  count() AS bucket_count,
  countIf(actual_ship_date IS NOT NULL) AS with_asd,
  round(100.0 * countIf(actual_ship_date IS NOT NULL) / count(), 2) AS pct
FROM analytics_workspace.mv_flash_and_drop_report
WHERE toDate(delivery_date_1) BETWEEN today() - 30 AND today()
GROUP BY e2e_label;

-- Q-INS-04: STM lag % — đơn đã rời kho >12h chưa có ATD signal (RF-01)
SELECT
  count() AS total_shipped,
  countIf(actual_ship_date IS NOT NULL
    AND thoi_gian_di IS NULL
    AND now() - actual_ship_date > 12*3600) AS stm_lagged,
  round(100.0 * countIf(actual_ship_date IS NOT NULL
    AND thoi_gian_di IS NULL
    AND now() - actual_ship_date > 12*3600) / count(), 2) AS lag_pct,
  max(now() - actual_ship_date) AS max_lag_hours
FROM analytics_workspace.mv_flash_and_drop_report
WHERE toDate(delivery_date_1) BETWEEN today() - 7 AND today()
  AND actual_ship_date IS NOT NULL;

-- Q-INS-05: ATA STM signal coverage
SELECT
  e2e_label,
  count() AS total,
  countIf(thoi_gian_di IS NOT NULL) AS with_atd,
  countIf(ata_den IS NOT NULL) AS with_ata,
  round(100.0 * countIf(ata_den IS NOT NULL) / count(), 2) AS ata_coverage_pct
FROM analytics_workspace.mv_flash_and_drop_report
WHERE toDate(delivery_date_1) BETWEEN today() - 7 AND today()
  AND e2e_label IN ('Đang vận chuyển', 'Đã vận chuyển')
GROUP BY e2e_label;

-- Q-INS-06: group_of_cago fill rate + unique values
SELECT
  count() AS total,
  countIf(group_of_cago IS NOT NULL AND group_of_cago != '') AS with_cargo,
  uniqExact(group_of_cago) AS unique_count,
  round(100.0 * countIf(group_of_cago IS NOT NULL AND group_of_cago != '') / count(), 2) AS fill_rate
FROM analytics_workspace.mv_flash_and_drop_report
WHERE toDate(delivery_date_1) BETWEEN today() - 30 AND today();

-- Q-INS-07: customer_name encoding diacritics spot check
-- Tìm 50 customer có ký tự đặc biệt
SELECT
  customer_name,
  count() AS order_count
FROM analytics_workspace.mv_flash_and_drop_report
WHERE toDate(delivery_date_1) BETWEEN today() - 7 AND today()
  AND customer_name LIKE '%ô%'
  OR customer_name LIKE '%ê%'
  OR customer_name LIKE '%ư%'
GROUP BY customer_name
ORDER BY order_count DESC
LIMIT 50;

-- Q-INS-08: khu_vuc_doi_xe enum match
-- FE expect 10 region; verify thực tế
SELECT
  khu_vuc_doi_xe,
  count() AS order_count
FROM analytics_workspace.mv_flash_and_drop_report
WHERE toDate(delivery_date_1) BETWEEN today() - 30 AND today()
  AND khu_vuc_doi_xe IS NOT NULL
GROUP BY khu_vuc_doi_xe
ORDER BY order_count DESC;
-- Expect 10 values: South East, South East - Lam Dong, Ha Noi, Central highland,
-- Mekong 1, Ho Chi Minh, North East - North West, North Central Coast, South Central Coast, Mekong 2

-- Q-INS-09: delivery_to_customer enum (RF-02 bucket fragility check)
SELECT
  delivery_to_customer,
  count() AS row_count
FROM analytics_workspace.mv_dropped_report
WHERE toDate(delivery_date_1) BETWEEN today() - 30 AND today()
GROUP BY delivery_to_customer
ORDER BY row_count DESC;
-- Expect bucket pattern match:
--   "tổng kế hoạch" / "tong ke hoach" / "total plan"
--   "xử lý thành công" / "xu ly thanh cong" / "success"
--   "xử lý ko thành công" / "khong thanh cong" / "failed"

-- Q-INS-10: Query perf profile (CH system.query_log)
-- Phải chạy với user có quyền system.query_log
SELECT
  substring(query, 1, 100) AS query_snippet,
  count() AS run_count,
  avg(query_duration_ms) AS avg_ms,
  max(query_duration_ms) AS max_ms,
  round(quantile(0.95)(query_duration_ms), 0) AS p95_ms
FROM system.query_log
WHERE event_time BETWEEN now() - 7*86400 AND now()
  AND query LIKE '%mv_flash_and_drop_report%'
  AND type = 'QueryFinish'
GROUP BY query_snippet
ORDER BY p95_ms DESC
LIMIT 20;
```

---

## 7. Closing notes

- File này KHÔNG embed vào Excel UAT pack — keep riêng. PM/BA share Slack/email cho team trước session để team prep.
- Insight chỉ là "câu chuyện đằng sau số" — KHÔNG block session UAT nếu reconciliation pass.
- Sau UAT session, nếu Ops Manager confirm OQ-A → OQ-G → cập nhật PRD v1.2.0 backlog qua `/ba` revision.
- Q-INS-* SQL là ad-hoc — KHÔNG nên paste vào widget settings (registry-only convention per memory [[feedback_check_registry_before_handrolling_sql]]).
