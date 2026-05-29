# S2 — Pipeline Build: MV `mv_mdlz_tms_report_25_order`

**Date:** 2026-05-28
**Auditor:** /da-ch (squad1@gosmartlog.com)
**Source MV:** `analytics_workspace.mv_mdlz_tms_report_25_order` (NEW)
**Source raw:** `analytics_workspace.mdlz_tms_report_25_trip_order` (32,262 dòng / 25,007 đơn / 2,473 chuyến)
**Notebook chân lý:** [mondelez/notebooks/tms_report_25_explore.ipynb](../../notebooks/tms_report_25_explore.ipynb) — Setup, L1, L6
**ClickHouse:** `ghrx9lirdl.ap-southeast-1.aws.clickhouse.cloud` (Cloud)
**MV refresh policy:** `REFRESH EVERY 1 HOUR` — caveat: dữ liệu trễ tối đa 1 giờ so với raw (raw lại reload TRUNCATE+reload theo cửa sổ ≤ 5 ngày, cadence riêng)

---

## 1. Vì sao có MV này

Notebook `tms_report_25_explore.ipynb` rewrites cùng 1 expression Ontime/Infull ở 15+ cell:
- `parseDateTimeBestEffortOrNull(nullIf(DateToCome, '')) <= addMinutes(parseDateTimeBestEffortOrNull(nullIf(ETA,'')), 30)`
- `toFloat64OrZero(QuantityBBGN) >= toFloat64OrZero(QuantityOrder)`
- Rollup cấp đơn: KH = `max(QuantityOrder)`, GN = `sum(QuantityBBGN)`, Ontime = `any chuyến trễ → Failed`

MV này **codify 1 lần** logic đó, output cấp đơn với cờ `ontime_status` / `infull_status` / `otif_status` để mọi dashboard / notebook chỉ cần `SELECT ... WHERE ontime_status = 'Failed Ontime'` thay vì viết lại CTE.

---

## 2. Grain & quy ước

| Thuộc tính | Giá trị |
|---|---|
| Grain | **1 row = 1 OrderCode** (rollup từ Order × Trip về cấp đơn) |
| Scope filter | `position(OrderCode, '-') = 0 AND OrderCode != ''` (= `SO_VALID` notebook) |
| MasterStatus filter | **KHÔNG pre-filter** — giữ cả đơn 'Chờ'/'Chưa giao'. Caller filter `master_status_has_active = 1` nếu cần scope L1-L4 |
| Ontime grace | 30 phút (hardcoded — khớp `ONTIME_GRACE_MIN` notebook) |
| Infull logic | `sum(QuantityBBGN) >= max(QuantityOrder)` |
| Engine | `SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')` |
| Partition | `toYYYYMM(tendered_date_vn)` |
| ORDER BY | `(tendered_date_vn, order_code)` |

**Lý do grain cấp đơn**:
- Notebook L1, L2, L3, L6 đều rollup về cấp đơn cuối cùng.
- OTIF canonically = "đơn Ontime / đơn Infull", không phải "dòng".
- Line-level vẫn JOIN ngược về raw nếu cần (qua `master_codes` Array).

---

## 3. Reconciliation — MV vs Notebook formula (raw recompute)

Chạy cùng công thức notebook trên raw rồi so với distribution MV — **khớp 100%**:

| Status | MV count | Raw recompute | Diff |
|---|---|---|---|
| Ontime | 17,130 | 17,130 | ✓ |
| Failed Ontime | 2,263 | 2,263 | ✓ |
| Chưa giao (OT) | 4,801 | 4,801 | ✓ |
| Thiếu thời gian | 0 | 0 | ✓ |
| Infull | 19,234 | 19,234 | ✓ |
| Failed Infull | 159 | 159 | ✓ |
| Chưa giao (IF) | 4,801 | 4,801 | ✓ |
| KH = 0 | 0 | 0 | ✓ |
| **TOTAL** | **24,194** | **24,194** | ✓ |

OTIF rollup:

| otif_status | Số đơn | % toàn cửa sổ |
|---|---|---|
| OTIF Pass | 17,014 | 70.3% |
| Failed Ontime | 2,220 | 9.2% |
| Failed Infull | 116 | 0.5% |
| Failed Both | 43 | 0.2% |
| Not Evaluable | 4,801 | 19.8% |
| **Tổng** | **24,194** | 100% |

L1 KPI tái dựng từ MV (filter `master_status_has_active = 1`):
- 19,665 đơn · 19,874 chuyến (cộng dồn, có thể trùng cross-order)
- % OTIF (đơn evaluable): **87.7%**
- % Ontime: **88.3%** · % In-full: **99.2%** · Fill rate: **125.8%**

---

## 4. Cách dùng — query patterns

### 4.1 KPI tổng (scope notebook L1)

```sql
SELECT
    count() AS so_don,
    countIf(otif_status = 'OTIF Pass')                                       AS so_otif_pass,
    round(100.0 * countIf(otif_status = 'OTIF Pass')
          / nullIf(countIf(otif_status != 'Not Evaluable'), 0), 1)           AS pct_otif,
    round(100.0 * countIf(ontime_status = 'Ontime')
          / nullIf(countIf(ontime_status IN ('Ontime','Failed Ontime')), 0), 1) AS pct_ontime,
    round(100.0 * countIf(infull_status = 'Infull')
          / nullIf(countIf(infull_status IN ('Infull','Failed Infull')), 0), 1) AS pct_infull,
    round(sum(gn_qty), 0)                                                    AS sl_giao,
    round(100.0 * sum(gn_qty) / nullIf(sum(kh_qty), 0), 1)                   AS fill_rate
FROM analytics_workspace.mv_mdlz_tms_report_25_order
WHERE master_status_has_active = 1
  AND tendered_date_vn BETWEEN '2026-05-01' AND '2026-05-31'
```

### 4.2 Danh sách đơn Failed OTIF (drill-down)

```sql
SELECT order_code, ontime_status, infull_status,
       kh_qty, gn_qty, chenh_qty, late_phut_max,
       vendor_name, stock_name, ops_location_to_province,
       master_codes
FROM analytics_workspace.mv_mdlz_tms_report_25_order
WHERE tendered_date_vn BETWEEN '2026-05-01' AND '2026-05-31'
  AND otif_status IN ('Failed Ontime', 'Failed Infull', 'Failed Both')
ORDER BY late_phut_max DESC NULLS LAST
LIMIT 200
```

### 4.3 Top vendor by % Ontime

```sql
SELECT vendor_name,
       count()                                                             AS so_don,
       round(100.0 * countIf(ontime_status = 'Ontime')
             / nullIf(countIf(ontime_status IN ('Ontime','Failed Ontime')), 0), 1) AS pct_ontime
FROM analytics_workspace.mv_mdlz_tms_report_25_order
WHERE vendor_name != ''
  AND master_status_has_active = 1
  AND tendered_date_vn BETWEEN '2026-05-01' AND '2026-05-31'
GROUP BY vendor_name
HAVING so_don >= 50
ORDER BY pct_ontime ASC
LIMIT 20
```

### 4.4 Join ngược về raw (line detail của 1 đơn)

```sql
WITH bad AS (
  SELECT order_code FROM analytics_workspace.mv_mdlz_tms_report_25_order
  WHERE otif_status = 'Failed Both' LIMIT 50
)
SELECT t.OrderCode, t.MasterCode, t.DeliveryStatus, t.ETA, t.DateToCome,
       t.QuantityOrder, t.QuantityBBGN
FROM analytics_workspace.mdlz_tms_report_25_trip_order t
WHERE t.OrderCode GLOBAL IN (SELECT order_code FROM bad)
ORDER BY t.OrderCode, t.MasterCode
```

---

## 5. Caveats

1. **Line-level vs Order-level Ontime%**: notebook một số chỗ (L1 KPI `pct_ontime`) tính theo **LINE**: `countIf(Hoàn tất AND ontime) / countIf(Hoàn tất AND eval_ot)`. MV này tính theo **ORDER**: 1 đơn có ≥ 1 chuyến trễ → cả đơn Failed. Order-level **strict hơn**, là định nghĩa OTIF chuẩn. Nếu cần line-level cũ, query thẳng raw.
2. **Trùng chuyến cross-order**: `sum(so_chuyen)` qua nhiều đơn KHÔNG = số chuyến unique toàn cửa sổ (vì 1 chuyến có nhiều đơn). Để đếm chuyến unique → `uniqExact(arrayJoin(master_codes))` hoặc query raw.
3. **Refresh trễ ≤ 1h**: dữ liệu thay đổi trong vòng 1 giờ trước check sẽ chưa phản ánh. So sánh `_refreshed_at` với `src_loaded_at` để biết MV có "đuổi kịp" raw không.
4. **`tendered_date_vn = 1970-01-01`**: đơn thiếu/không parse được `TenderedDate`. Filter `tendered_date_vn != '1970-01-01'` để loại nếu cần.
5. **`SO_VALID` filter**: bỏ ~813 dòng `OrderCode` chứa `-` (format "XXXXXXXX-N", tách dòng theo line). Khớp scope notebook — KHÔNG analyze đơn split này.
6. **`master_status_has_active` ≠ cờ delivery**: chỉ thị có ít nhất 1 chuyến `MasterStatus` ∈ {Đã hoàn thành, Đang vận chuyển}. Đơn `master_status_has_active = 1` vẫn có thể `ontime_status = 'Chưa giao'` (chuyến Đang vận chuyển chưa Hoàn tất).
7. **Hardcoded ONTIME_GRACE = 30 phút**: nếu nghiệp vụ đổi grace, phải DROP + recreate MV. Không có cách parameterize.

---

## 6. DDL canonical

File: [mondelez/02-data/sql/mv_mdlz_tms_report_25_order.sql](../sql/mv_mdlz_tms_report_25_order.sql)

Deploy command:

```bash
set -a; source mondelez/.env; set +a
curl -s --user "$CLICKHOUSE_USER:$CLICKHOUSE_PASSWORD" \
  "https://$CLICKHOUSE_HOST:$CLICKHOUSE_PORT/?max_execution_time=120" \
  --data-binary @mondelez/02-data/sql/mv_mdlz_tms_report_25_order.sql
```

Re-create (nếu DDL thay đổi):

```sql
DROP TABLE IF EXISTS analytics_workspace.mv_mdlz_tms_report_25_order;
-- rồi run lại CREATE từ file SQL
```

---

## 7. TODO / next actions

- [ ] Báo team data pipeline (Quân/Khang) MV mới deploy — nếu cần thêm cột để dashboard binding, raise PR sửa DDL.
- [ ] Refactor notebook `tms_report_25_explore.ipynb` cells L1–L4 dùng MV thay vì recompute từ raw (giảm 60-80% LOC, query nhanh hơn).
- [ ] Cân nhắc grant `SYSTEM VIEWS` cho user `helix` để có thể trigger refresh thủ công + đọc `system.view_refreshes` (hiện đang ACCESS_DENIED).
- [ ] Khi notebook tách `flash_daily_mtd_audit.ipynb` cần Ontime/Infull cấp đơn → reuse MV này, KHÔNG copy logic.

---

## ARTIFACT_PATH: mondelez/02-data/audit-results/tms-report-25-order-mv-20260528.md
## MV_PATH: analytics_workspace.mv_mdlz_tms_report_25_order (24,194 rows · 46 cols)
## DDL_PATH: mondelez/02-data/sql/mv_mdlz_tms_report_25_order.sql
## DATA_CONFIDENCE: High — 100% reconciliation vs raw recompute trên cả 8 status × 24,194 đơn
## MV_FRESHNESS: 2026-05-28 08:57:26 (first refresh, ~1 phút sau CREATE)
## NEXT_ACTION: handoff cho team notebook để refactor cells L1–L4 dùng MV; báo data pipeline team về MV mới
