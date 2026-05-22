# S2 — Pipeline Audit: BUG `mv_otif_stm_data.LineNo` derivation (CRITICAL)

**Date:** 2026-05-13
**Auditor:** PM/DA (via `/da-ch`)
**Source MV:** `analytics_workspace.mv_otif_stm_data` (root cause), `mv_otif_swm_stm_data` (propagation), `mv_otif` (visible impact)
**SQL Registry section:** §OTIF (KPI cards + Detail Table)
**ClickHouse server:** ghrx9lirdl.ap-southeast-1.aws.clickhouse.cloud
**Trigger:** SO `8482485892` báo cáo Failed Infull (Transport hụt 20 CSE), nhưng TMS xác nhận BBGN = 20 cho SKU `4305257` line 8.

---

## 1. TL;DR — Bug

**Root cause**: DDL của `mv_otif_stm_data` derive `LineNo` từ `opg.code_sync` bằng cách **chỉ cắt 1 ký tự cuối** ([line 3862](../data-sources/clickhouse-ddl/analytics-workspace_mvs.sql#L3862)):

```sql
leftUTF8(ifNull(opg.code_sync, ''),
         greatest(lengthUTF8(ifNull(opg.code_sync, '')) - 1, 0)) AS LineNo
```

Logic này ngầm giả định `code_sync = SWM.orderlinenumber × 10` (sequential, không gap). **Sai khi STM có gap** trong dãy `code_sync` — phổ biến hơn dự kiến.

**Hậu quả**: Khi STM skip 1 line trong dãy (vd: `000010, 000020, ..., 000070, 000090` — mất 000080), tất cả line từ điểm skip trở đi bị **lệch nhãn 1 bậc** so với SWM. JOIN `swm.orderlinenumber = stm.LineNo` → no match → BBGN không propagate → counted as 0 → OTIF aggregation **wrongly marks Failed Infull**.

**Scope đo được (30 ngày gần nhất, ETA 2026-04-13 → 2026-05-13)**:

| Chỉ số | Giá trị |
|---|---:|
| Tổng SO trong window | 11,523 |
| SO bị impact | **693** |
| % impact | **6.01%** |
| Total orphaned lines | **1,420** |
| **CSE bị mất khỏi `sum_san_luong_giao_cse`** | **~29,357** |

Mỗi orphan line đẩy đơn vào nhánh `sum_shipped_cse > sum_giao_cse` → `Failed Infull` → `Failed OTIF` → `not_infull_reason = 'Transport Infull Failure'` (đổ tội oan NVC).

---

## 2. Bằng chứng repro cho SO `8482485892`

### 2.1 STM raw (`stm_dwh_mondelez.dim_ord_product_group` + `dim_ops_trip_detail`)

| # | `code_sync` | `sort_order` | `quantity_bbgn` |
|---:|---|---:|---:|
| 1 | `000010` | -1 | 30 |
| 2 | `000020` | -1 | 40 |
| 3 | `000030` | -1 | 60 |
| 4 | `000040` | -1 | 20 |
| 5 | `000050` | -1 | 40 |
| 6 | `000060` | -1 | 40 |
| 7 | `000070` | -1 | 40 |
| 8 | **`000090`** | -1 | **20** ← BBGN=20 nằm ở `000090`, **không phải `000080`** |

→ STM có 8 line giao đủ cho SO này; line thứ 8 ứng với `code_sync = '000090'` (gap tại `000080`).

### 2.2 Sau khi apply strip-last-char DDL transformation

| `code_sync` | → `LineNo` (strip cuối) |
|---|---|
| `000010` | `00001` |
| `000020` | `00002` |
| `000030` | `00003` |
| `000040` | `00004` |
| `000050` | `00005` |
| `000060` | `00006` |
| `000070` | `00007` |
| `000090` | **`00009`** ← lệch 1 bậc |

→ Verified bằng query trực tiếp:
```
SELECT `Mã đơn hàng`, LineNo, QuantityBBGN FROM analytics_workspace.mv_otif_stm_data
WHERE `Mã đơn hàng` = '8482485892' ORDER BY LineNo;
```
Kết quả: 8 row LineNo = `00001..00007, 00009` (no `00008`).

### 2.3 SWM (`mv_otif_swm_data`)

`ORDERLINENUMBER` chạy tuần tự `00001..00008` cho 8 SKU. Line 8 = SKU `4305257`, SHIPPED CSE = 20.

### 2.4 JOIN mismatch

Join condition trong DDL `mv_otif_swm_stm_data`:
```sql
ON swm_data.SO = stm_data.`Mã đơn hàng`
   AND toString(swm_data.ORDERLINENUMBER) = toString(stm_data.LineNo)
```

| SWM line | STM line | Match? |
|---|---|---|
| 00001 | 00001 | ✓ |
| 00002 | 00002 | ✓ |
| 00003 | 00003 | ✓ |
| 00004 | 00004 | ✓ |
| 00005 | 00005 | ✓ |
| 00006 | 00006 | ✓ |
| 00007 | 00007 | ✓ |
| **00008** | (none — STM có `00009`) | **❌ NO MATCH** |

→ Trong `mv_otif_swm_stm_data` row line 8: `QuantityBBGN = NULL` (truy ngược qua `SETTINGS join_use_nulls = 1`); `Sản lượng giao CSE = 0` (coalesce default trong upstream aggregate).
→ Trong `mv_otif`: `sum_san_luong_giao_cse = 30+40+60+20+40+40+40+0 = 270` thay vì 290.
→ Status: `Failed Infull` / `Failed OTIF` / `Transport Infull Failure` — **đổ oan NVC ANH SON** vì 20 case mà ANH SON thực tế đã giao đủ.

> **Caveat detect orphan**: cột `LineNo` trong cả 2 MV được declare là `String` (KHÔNG Nullable). Với default `join_use_nulls = 0`, LEFT JOIN no-match trả về `LineNo = ''` (empty string) chứ không phải NULL. Query audit phải dùng `stm.LineNo = ''` (hoặc `SETTINGS join_use_nulls = 1`) để detect orphan đúng.

---

## 3. Scope query (verify được)

```sql
WITH per_so AS (
    SELECT
        swm.SO                                          AS so,
        countIf(stm.LineNo = '')                       AS orphaned,
        sumIf(swm.`SHIPPED CSE`, stm.LineNo = '')      AS lost_cse
    FROM analytics_workspace.mv_otif_swm_data AS swm
    LEFT JOIN analytics_workspace.mv_otif_stm_data AS stm
        ON swm.SO = stm.`Mã đơn hàng`
       AND swm.ORDERLINENUMBER = stm.LineNo
    WHERE swm.SO IN (
        SELECT so FROM analytics_workspace.mv_otif
        WHERE toDate(eta_giao_hang_cho_npp) >= today() - 30
    )
    GROUP BY swm.SO
)
SELECT
    countIf(orphaned > 0)                                AS impacted_so,
    count()                                              AS total_so_30d,
    round(countIf(orphaned > 0) * 100.0 / count(), 2)    AS pct_impacted,
    sumIf(orphaned, orphaned > 0)                        AS orphan_lines_total,
    round(sumIf(lost_cse, orphaned > 0), 2)              AS lost_cse_total
FROM per_so;
-- Result (2026-05-13): impacted_so=693, total_so_30d=11523, pct=6.01%,
--                      orphan_lines=1420, lost_cse=29357.31
```

### Top 10 SO mất CSE nhiều nhất

| SO | SWM lines | STM matched | Orphan | Lost CSE |
|---|---|---|---:|---:|
| 8482475242 | 1..6 | [1] | 5 | 662 |
| 8482495068 | 1..6 | [1, 6] | 4 | 566 |
| 8482495075 | 1..6 | [1, 2, 4, 6] | 2 | 464 |
| 8482478784 | 1..4 | [3, 4] | 2 | 460 |
| 8482480603 | 1..19 | 18 matched (miss 16) | 1 | 458 |
| 8482499844 | 1..10 | [6] | 9 | 439 |
| 8482495188 | 1..6 | [3] | 5 | 428 |
| 8482490996 | 1..7 | [1, 2, 6, 7] | 3 | 400 |
| 8482486020 | 1..3 | [1] | 2 | 400 |
| 8482494228 | 1..5 | [5] | 4 | 398 |

→ Pattern không phải lúc nào cũng "gap tại 1 line cuối" như case 8482485892. Có những SO mất rất nhiều line (vd `8482499844` chỉ match 1/10 line) → STM line numbering có thể **khác hoàn toàn** SWM, không chỉ là gap-1-bậc.

---

## 4. Root cause analysis — vì sao DDL strip-last-char sai

### 4.1 Giả định ngầm trong DDL

[`mv_otif_stm_data` line 3862](../data-sources/clickhouse-ddl/analytics-workspace_mvs.sql#L3862):
```sql
leftUTF8(code_sync, length(code_sync) - 1) AS LineNo
```

Giả định: `STM.code_sync` = `SWM.ORDERLINENUMBER × 10` (dạng `XXXX0`), strip ký tự cuối (=`0`) → ra `SWM.ORDERLINENUMBER` (dạng `XXXX`).

### 4.2 Khi nào giả định đúng

Khi STM `code_sync` dense và đồng bộ với SWM line:
- SWM lines `00001, 00002, 00003` ↔ STM `code_sync = '000010', '000020', '000030'` → strip → `00001, 00002, 00003` ✓ match

### 4.3 Khi nào giả định sai (ít nhất 2 patterns)

**Pattern A — Gap trong STM** (case của SO `8482485892`):
- SWM tuần tự `00001..00008`
- STM `code_sync` = `000010..000070, 000090` (mất `000080`)
- Strip → STM LineNo = `00001..00007, 00009`
- SWM line 8 → no match

**Pattern B — STM line numbering hoàn toàn khác SWM** (case của SO `8482499844`):
- SWM có 10 lines `00001..00010`
- STM chỉ match được 1 line (`00006`)
- 9 line orphan → mất 439 CSE
- → STM có thể đang nhóm theo `product_group` chứ không theo SKU line, hoặc dùng cardinality khác hẳn

→ Logic strip-last-char chỉ là **band-aid heuristic** chứ không phải mapping logic đúng. Cần fix bằng business-key join.

### 4.4 Fragility cộng thêm

Comment trong [`mv_dropped_stm` schema line 80](../data-sources/clickhouse-ddl/analytics-workspace_mvs.sql) đã ghi rõ:
> `line_no  String  "LineNo từ code_sync (bỏ 1 ký tự cuối)"`

→ Dev biết logic strip nhưng không nhận thức được đây là **fragile assumption**. Nên có doc cảnh báo gap risk.

---

## 5. Recommended fix options

| Option | Mô tả | Pros | Cons | Effort |
|---|---|---|---|---|
| **A — Sequence-based align** | Trong `mv_otif_swm_stm_data`, gán `row_number() OVER (PARTITION BY SO ORDER BY code_sync)` ở STM và `row_number() OVER (PARTITION BY SO ORDER BY ORDERLINENUMBER)` ở SWM. JOIN `(SO, rn)`. | Robust với mọi gap pattern, không cần thêm field STM | Giả định 1:1 line count STM ↔ SWM. Cần verify trước khi roll-out. Nếu STM có ít/nhiều line hơn SWM → vẫn miss nhưng theo cách deterministic. | Trung bình — rewrite `mv_otif_stm_data` + test |
| **B — Join by item_code** | Thêm `item_code` vào `mv_otif_stm_data` (kéo từ `dim_ord_product`). JOIN `(SO, item_code)`. | Stable business key — không phụ thuộc line order | Cùng SO có thể có 2+ line cùng item_code → ambiguous match → cần agg | Cao — schema change + xử lý duplicate |
| **C — Source-side fix tại STM** | Yêu cầu STM expose `external_orderlinenumber` mapping ngược về SWM line. | Đúng nhất về mặt business | Lệ thuộc team STM Mondelez, timeline dài | Rất cao — cross-team |
| **D — Composite fallback** | Giữ strip-last-char, nếu không match → fallback match theo `item_code`. | Backward compatible với case dense | Phức tạp, vẫn ambiguous trong case có duplicate item | Cao |
| **E (workaround tạm)** — | Hardcode exclude SO có orphan ra khỏi `% OTIF`/`% Infull` (giảm denominator) cho tới khi A/B/C deploy | Stop bleeding metric ngay | Giảm volume báo cáo, có thể che các SO thực sự fail | Thấp — chỉnh widget SQL |

**Recommend: Option A (sequence-align)** làm fix chính, **Option E** làm workaround tạm để metric không tiếp tục đổ oan NVC trong khi A đang dev.

> ⚠️ Trước khi commit Option A: cần data team STM **xác nhận** rằng `code_sync` order tuyến tính theo SWM line order (vd: code_sync luôn tăng theo thứ tự line SWM tạo). Nếu STM resequence (vd: line bị canceled rồi tạo lại với code_sync mới lớn hơn) → sequence-align cũng có thể lệch. Cần check.

---

## 6. Action items đề xuất

| # | Owner | Task | Mức ưu tiên |
|---|---|---|---|
| 1 | Data Engineer Smartlog | Verify Pattern B (STM line numbering khác SWM) bằng cách sample 10 SO trong top 10 và pull raw STM/SWM line counts đối chiếu | **HIGH** — quyết định Option A hay B |
| 2 | Data Engineer Smartlog | Implement Option A (sequence-align), deploy lên staging, run side-by-side với production trong 1 tuần | **HIGH** |
| 3 | PM/DA | Báo Mondelez Ops Manager: chỉ số `% OTIF` hiện tại có **systematic ~6% sai số** do bug pipeline; NVC `ANH SON` và các NVC khác có thể bị đổ oan; sẽ có config sau khi fix | **HIGH** — credibility report |
| 4 | PM/DA | Update [`projects/mondelez/01-sections/otif/analysis/business-rules-trace-2026-05-13.md`](../../01-sections/otif/analysis/business-rules-trace-2026-05-13.md) §4 — thêm Flag mới (Flag-7): STM↔SWM line mismatch | MEDIUM |
| 5 | BA | Update `glossary/99-discrepancies.md` — pin bug này cho tới khi closed | LOW |
| 6 | Data team STM | (Optional) Cross-team — discuss khả năng expose `external_orderlinenumber` từ STM | LOW (long-term) |

---

## 7. Caveats

- **MV refresh trễ tối đa 5 phút** (`mv_otif_swm_stm_data REFRESH EVERY 5 MINUTE`) + 1 giờ (`mv_otif`, `mv_otif_stm_data REFRESH EVERY 1 HOUR`). Số đo scope (693 SO, 29,357 CSE) là **snapshot tại 2026-05-13 03:52 UTC**.
- Không có quyền truy cập `system.view_refreshes` để confirm last_refresh_time của các MV này.
- Pattern B (STM line numbering hoàn toàn khác SWM) chưa được phân tích sâu — cần raw query thêm để hiểu nguồn gốc.
- Bug này có thể đã tồn tại từ ngày MV `mv_otif_stm_data` được tạo — cần historical backfill ước tính nếu Mondelez cần re-baseline `% OTIF`.

---

## ARTIFACT_PATH: `projects/mondelez/02-data/audit-results/s2-bug-otif-stm-lineno-strip-20260513.md`
## DATA_CONFIDENCE: **High** — Bug verified bằng raw STM source (BBGN=20 ở `code_sync='000090'`) + scope query reproducible
## MV_FRESHNESS: snapshot 2026-05-13 03:52 UTC; `system.view_refreshes` không truy cập được
## NEXT_ACTION:
- **(immediate)** `/da-pm` để add fix vào sprint backlog (Option A + E workaround)
- **(parallel)** Báo Mondelez Ops Manager qua email/Slack về systematic 6% sai số trước khi rollout dashboard
- **(follow-up)** `/da-trace` audit xem widget OTIF có warning user về data quality không
