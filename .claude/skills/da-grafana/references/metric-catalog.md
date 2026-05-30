# Metric Catalog — Section → Grafana panel (tài liệu SỐNG)

Catalog map mỗi **section** (`mondelez/01-sections/<section>/`) → panel Grafana. Đây KHÔNG phải danh sách đóng: hiện mới có 4 section đã port SQL verify; **mỗi lần dựng dashboard cho section mới → thêm 1 mục vào đây**.

**Nguồn công thức (thứ tự ưu tiên)** — xem SKILL §0:
1. `01-sections/<section>/prd.md` → KPI + target + audience.
2. `01-sections/<section>/spec.md` → bảng/MV nguồn + cột + công thức TMS/WMS→ClickHouse.
3. `01-sections/<section>/analysis/*.md` + [`scripts/analysis/*.py`](../../../../mondelez/scripts/analysis/) → SQL canonical đã chạy thật.

**Công thức bên dưới là canonical** (cho section đã port) — copy nguyên semantics, chỉ đổi `WHERE window` → `$__timeFilter(<time_col>)`. Bảng vật lý lấy từ [`da.toml`](../../../../mondelez/da.toml); ở Grafana dùng tên đầy đủ `analytics_workspace.<table>`.

> **Section CHƯA có ở đây** (vfr, tender-response, wh-utilization, stock-type, copack, factory-inbound, loose-picking, shipping-progress, transfer, txn-move, daily-ops, alert-summary, late-order-alert): đọc prd/spec section đó → dựng công thức → smoke-test `/da-ch` → thêm mục mới theo khuôn dưới.

### Khuôn 1 mục section (dùng khi bổ sung)
```
## Dashboard N — <Tên section> (`<mv/table>`)
Nguồn: 01-sections/<section>/{prd,spec}.md (+ analysis nếu có). Time col: `<col>`.
- L0 Health  : <KPI stat + threshold/target từ prd>
- L1 Except. : <anomaly/đơn off-track>
- L2 Trend   : <time series KPI theo ngày>
- L3 Breakdown: <bar/bargauge theo dim>
+ SQL canonical mỗi panel (đổi window → $__timeFilter).
```

Quy ước cột (giống script): chuỗi tiếng Việt là VALUE so sánh (`'OTIF'`, `'Ontime'`, `'Infull'` là ASCII OK inline; `'Không có dữ liệu STM'` là literal UTF-8 — trong panel JSON tĩnh đặt literal được vì JSON là UTF-8, vẫn kiểm encoding sau import).

---

## Dashboard 1 — OTIF Performance (`mv_otif`)

Nguồn: [`otif_mtd_audit.py`](../../../../mondelez/scripts/analysis/otif_mtd_audit.py). Time col: `thoi_gian_gui_thau` (UTC — xem timezone gotcha). **Mẫu số canonical loại `'Không có dữ liệu STM'`.**

### L0 — Health: KPI canonical (Stat ×3)

Một query trả 3 metric; tách 3 stat panel hoặc 1 stat group. `format` = table.

```sql
SELECT
  round(100.0 * countIf(otif_status   = 'OTIF')   / nullIf(count(so), 0), 2) AS pct_otif,
  round(100.0 * countIf(ontime_status = 'Ontime') / nullIf(count(so), 0), 2) AS pct_ontime,
  round(100.0 * countIf(infull_status = 'Infull') / nullIf(count(so), 0), 2) AS pct_infull,
  uniqExact(so) AS total_so
FROM analytics_workspace.mv_otif
WHERE $__timeFilter(thoi_gian_gui_thau)
  AND otif_status != 'Không có dữ liệu STM'          -- exclusion canonical cho % metric
  AND $__conditionalAll(whseid IN (${whseid:singlequote}), $whseid)
```

Thresholds (field config, **không** trong SQL):

| Stat | base(🔴) | 85→🟡(otif) | green | target line |
|---|---|---|---|---|
| pct_otif | 0 | 85 | 90 | 90 |
| pct_ontime | 0 | 90 | 95 | 95 |
| pct_infull | 0 | 92 | 97 | 97 |

Action titles: `"% OTIF (mục tiêu 90%)"`, `"% Ontime (95%)"`, `"% Infull (97%)"`, `"Tổng đơn (loại STM-missing)"`.

### L0 — Freshness (Stat, lower=better, invert)

```sql
SELECT dateDiff('minute', max(thoi_gian_gui_thau), now()) AS lag_min,
       toString(toDate(max(thoi_gian_gui_thau)))          AS max_date
FROM analytics_workspace.mv_otif
```
Thresholds lag: 🟢 < 10 · 🟡 10–30 · 🔴 > 30. Title: `"Freshness — data tới max_date, trễ ~lag′"`.

### L2 — Trend %OTIF/Ontime/Infull theo ngày (Time series)

```sql
SELECT toStartOfDay(thoi_gian_gui_thau)                                     AS time,
       round(100.0*countIf(otif_status='OTIF')   /nullIf(count(so),0),2)    AS "% OTIF",
       round(100.0*countIf(ontime_status='Ontime')/nullIf(count(so),0),2)   AS "% Ontime",
       round(100.0*countIf(infull_status='Infull')/nullIf(count(so),0),2)   AS "% Infull"
FROM analytics_workspace.mv_otif
WHERE $__timeFilter(thoi_gian_gui_thau)
  AND otif_status != 'Không có dữ liệu STM'
  AND $__conditionalAll(whseid IN (${whseid:singlequote}), $whseid)
GROUP BY time ORDER BY time
```
Thêm 3 threshold line (90/95/97) hoặc dùng "target band". Title: `"Xu hướng %OTIF/Ontime/Infull — đường = target"`.

### L3 — %OTIF theo dim (Bar gauge, RAG)

Dim đề xuất (giống `dim_specs` script): `whseid` (Kho), `khu_vuc_doi_xe`, `group_name` (Kênh), `ten_ngan_nha_van_tai` (Nhà vận tải), `group_of_cago` (Loại hàng), `loai_xe_gui_thau`.

```sql
SELECT multiIf(whseid IS NULL,'(NULL)', whseid='','(rỗng)', whseid)         AS dim,
       round(100.0*countIf(otif_status='OTIF')
             /nullIf(countIf(otif_status != 'Không có dữ liệu STM'),0),2)    AS pct_otif,
       count() AS rows
FROM analytics_workspace.mv_otif
WHERE $__timeFilter(thoi_gian_gui_thau)
GROUP BY dim ORDER BY rows DESC LIMIT 30
```
Đổi `whseid` sang dim khác cho từng panel. Threshold giống pct_otif. Title: `"%OTIF theo kho — đỏ < 85%"`.

### L1 — Exception: anomaly (Table, cell threshold)

Gộp 5 nhóm anomaly của script (NULL/empty, volume integrity, business-rule, duplicate, timestamp). Mỗi check 1 dòng `check | count | rule (=0)`. Ví dụ nhóm NULL:

```sql
SELECT 'so NULL/empty'        AS check, countIf(so IS NULL OR so='')        AS cnt UNION ALL
SELECT 'whseid empty',                  countIf(whseid='')                          UNION ALL
SELECT 'otif_but_not_ontime',           countIf(otif_status='OTIF' AND ontime_status!='Ontime') UNION ALL
SELECT 'otif_but_not_infull',           countIf(otif_status='OTIF' AND infull_status!='Infull')
FROM analytics_workspace.mv_otif
WHERE $__timeFilter(thoi_gian_gui_thau)
```
(Xem `fetch_anomaly_*` trong script để lấy đủ ~40 check; cell color: > 0 = 🔴.) Title: `"Anomaly — đếm kỳ vọng = 0"`.

### L3 — Volume (Stat group / Bar)

Plan/Shipped/Delivered × CSE/KG/CBM — kỳ vọng monotonic Plan ≥ Shipped ≥ Delivered.

```sql
SELECT round(sum(toFloat64(coalesce(sum_original_cse,0))),2)       AS plan_cse,
       round(sum(toFloat64(coalesce(sum_shipped_cse,0))),2)        AS shipped_cse,
       round(sum(toFloat64(coalesce(sum_san_luong_giao_cse,0))),2) AS delivered_cse
FROM analytics_workspace.mv_otif
WHERE $__timeFilter(thoi_gian_gui_thau) AND otif_status != 'Không có dữ liệu STM'
```

---

## Dashboard 2 — Flash Daily Quality (`mv_flash_and_drop_report`)

Nguồn: [`flash_daily_audit.py`](../../../../mondelez/scripts/analysis/flash_daily_audit.py). Time col: `delivery_date_1` ("Ngày GI"). UOM mặc định `original_cse`.

### L0 — Health (Stat)
- `count()` row trong window · `uniq(so)` distinct SO.
- **Vi phạm cứng** = integrity + business + timestamp + duplicate + |parity_diff|. Threshold: 0 = 🟢, > 0 = 🔴.

### L2 — Daily volume + %done (Time series)
```sql
SELECT toStartOfDay(delivery_date_1)              AS time,
       round(sum(original_cse),2)                 AS plan_cse,
       round(sum(shipped_cse),2)                  AS shipped_cse,
       round(sum(san_luong_giao_cse),2)           AS delivered_cse,
       round(if(sum(original_cse)>0, sum(san_luong_giao_cse)/sum(original_cse)*100,0),2) AS pct_done
FROM analytics_workspace.mv_flash_and_drop_report
WHERE $__timeFilter(delivery_date_1)
GROUP BY time ORDER BY time
```

### L3 — Phân bố `e2e_label` / status / type / brand / kênh / khu vực (Bar sorted)
```sql
SELECT coalesce(nullIf(e2e_label,''),'(NULL)') AS e2e_label,
       count() AS rows, round(sum(original_cse),2) AS volume_cse
FROM analytics_workspace.mv_flash_and_drop_report
WHERE $__timeFilter(delivery_date_1)
GROUP BY e2e_label ORDER BY rows DESC
```

### L1 — Exception: vi phạm (Table)
- Volume integrity: `neg_*`, `shipped_gt_plan`, `delivered_gt_shipped` (=0).
- Business rule: `cancel_but_delivered`, `delivered_label_but_no_ata`, `drop_no_reason`... (chuỗi VN literal trong JSON).
- Timestamp ordering: `create_after_delivery`, `bid_after_etd`, `atd_after_ata`... (=0).
- Parity: `rows_combined = rows_flash + rows_dropped` → `parity_diff` (=0).
- Duplicate `(so, orderlinenumber)`.

(Lấy nguyên các `countIf` từ `fetch_volume_integrity` / `fetch_business_rules` / `fetch_timestamp_ordering` / `fetch_dup_and_parity`.)

---

## Dashboard 3 — TMS #25 Ops (`mdlz_tms_report_25_trip_order`)

Nguồn: [`tms_report_25_audit.py`](../../../../mondelez/scripts/analysis/tms_report_25_audit.py). Time col: `TenderedDate` (chuỗi → parse). Macro DT/NUM:
- `DT(col)` = `parseDateTimeBestEffortOrNull(nullIf(col,''))`
- `NUM(col)` = `toFloat64OrZero(col)`
- on-time grace = 30′ (`da.toml scope.ontime_grace_min`); `so_valid` = `position(OrderCode,'-') = 0`.
- scope: `MasterStatus IN ('Đã hoàn thành','Đang vận chuyển')`, `OrderStatus IN ('Đã giao hàng')`, `DeliveryStatus = 'Hoàn tất'`.

### L2 — KPI theo ngày (Time series / Table)
```sql
SELECT toDate(parseDateTimeBestEffortOrNull(nullIf(TenderedDate,'')))          AS time,
       uniqExact(OrderCode)                                                     AS so_don,
       uniqExactIf(MasterCode, MasterCode != '')                                AS so_chuyen,
       round(100*countIf(
            parseDateTimeBestEffortOrNull(nullIf(DateToCome,'')) <= addMinutes(parseDateTimeBestEffortOrNull(nullIf(ETA,'')),30)
            AND DeliveryStatus='Hoàn tất')
         / nullIf(countIf(DeliveryStatus='Hoàn tất'
            AND parseDateTimeBestEffortOrNull(nullIf(DateToCome,'')) IS NOT NULL
            AND parseDateTimeBestEffortOrNull(nullIf(ETA,'')) IS NOT NULL),0),1) AS pct_ontime,
       round(100*countIf(toFloat64OrZero(QuantityBBGN) >= toFloat64OrZero(QuantityOrder)
            AND DeliveryStatus='Hoàn tất' AND toFloat64OrZero(QuantityOrder)>0)
         / nullIf(countIf(DeliveryStatus='Hoàn tất' AND toFloat64OrZero(QuantityOrder)>0),0),1) AS pct_infull,
       round(100*sum(toFloat64OrZero(QuantityBBGN))/nullIf(sum(toFloat64OrZero(QuantityOrder)),0),1) AS fill_rate
FROM analytics_workspace.mdlz_tms_report_25_trip_order
WHERE position(OrderCode,'-') = 0
  AND MasterStatus IN ('Đã hoàn thành','Đang vận chuyển') AND OrderStatus IN ('Đã giao hàng')
  AND $__timeFilter(parseDateTimeBestEffortOrNull(nullIf(TenderedDate,'')))
GROUP BY time ORDER BY time
```
> `$__timeFilter` trên biểu thức parse: nếu plugin từ chối → thêm cột tính `toDateTime` trong subquery rồi filter cột đó. Smoke-test trước.

### L3 — Phân bố MasterStatus / OrderStatus / DeliveryStatus (Bar). L1 — đơn 'Hoàn tất' thiếu DateToCome/ETA + đơn multi-trip (Stat/Table).

---

## Dashboard 4 — TMS ↔ OTIF Reconcile

Nguồn: [`reconcile_tms_otif.py`](../../../../mondelez/scripts/analysis/reconcile_tms_otif.py). Trục chung "Ngày gửi thầu". **Chỉ tin cột số đơn (Δ)**; OT%/IF% hai nguồn khác mẫu số → tham khảo.

### L2 — Δ số đơn theo ngày (Time series, bar mode)
Hai nguồn khác bảng/grain → tính riêng rồi join theo ngày trong panel, hoặc dùng `FULL OUTER JOIN` trên subquery ngày:
```sql
SELECT t.ngay AS time,
       t.don_tms AS don_tms, m.don_mv AS don_mv,
       (toInt64(t.don_tms) - toInt64(m.don_mv)) AS d_don
FROM (
  SELECT toDate(parseDateTimeBestEffortOrNull(nullIf(TenderedDate,''))) AS ngay, uniqExact(OrderCode) AS don_tms
  FROM analytics_workspace.mdlz_tms_report_25_trip_order
  WHERE position(OrderCode,'-')=0
    AND MasterStatus IN ('Đã hoàn thành','Đang vận chuyển') AND OrderStatus IN ('Đã giao hàng')
    AND $__timeFilter(parseDateTimeBestEffortOrNull(nullIf(TenderedDate,'')))
  GROUP BY ngay
) t
FULL OUTER JOIN (
  SELECT toDate(thoi_gian_gui_thau) AS ngay, uniqExact(so) AS don_mv
  FROM analytics_workspace.mv_otif
  WHERE $__timeFilter(thoi_gian_gui_thau)
  GROUP BY ngay
) m ON t.ngay = m.ngay
ORDER BY time
```
Threshold `d_don` (abs): 🟢 0 · 🟡 ≤ 2 · 🔴 > 2. Title: `"Δ số đơn TMS − mv_otif theo ngày (🟢0 🟡≤2 🔴>2)"`.

> Timezone: mv_otif UTC, TMS VN → Δ ngày biên có thể do lệch 7h, không phải mất đơn. Ghi chú panel description đúng như script (`_classify_diff`: coverage-gap vs lệch thật).

### L1 — Đơn lệch tập cần truy (Table) — set-diff theo `(ngày, mã đơn)`; cột chẩn đoán "đối chiếu chéo" (đơn có ở nguồn kia ngày khác ⇒ lệch biên TZ). Phần này phức tạp (Python `_classify_diff`) → có thể giữ ở report `.md`, panel Grafana chỉ show Δ tổng hợp; nếu cần đầy đủ, tạo MV/bảng trung gian.
