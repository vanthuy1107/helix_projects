# BUG-042: `mv_otif_stm_data.LineNo` strip-last-char làm lệch JOIN với SWM khi STM `code_sync` có gap

- **Source**: Phát hiện nội bộ qua `/da-ch` audit ngày 2026-05-13 (trigger: SO `8482485892` báo Failed Infull oan)
- **Reporter**: PM/DA squad1 (`squad1@gosmartlog.com`)
- **Tenant**: MDLZ
- **Area**: OTIF (impact toàn dashboard `WidgetOtif` — KPI cards, charts, Detail Table)
- **Severity**: **Sev1** — Lỗi nghiêm trọng — sai chỉ số kinh doanh trọng yếu (% OTIF, % Infull), đổ tội oan NVC
- **Priority**: **Critical** — Cản trở chính của metric tin cậy được; cần fix trước khi formal rollout dashboard OTIF cho Mondelez Ops Manager
- **Triage confidence**: **High** — Bug đã verify bằng raw STM + scope query reproducible
- **View**: OTIF section — toàn bộ widget bị impact
- **Tech layer**: `etl-data` — DDL của MV ClickHouse `analytics_workspace.mv_otif_stm_data`
- **Owner team**: `da` — Data Analyst / Data Engineer (sửa DDL MV + verify backfill)

## Repro steps

1. Trên dashboard OTIF (Mondelez tenant), filter SO = `8482485892`.
2. Quan sát Detail Table: row line 8 (SKU 4305257) hiển thị `Sản lượng giao CSE = 0`, `Chênh lệch SL giao & chở CSE = 20`.
3. KPI card `% OTIF` cho SO này = 0%, status `Failed OTIF`, `Transport Infull Failure`, đổ vào NVC `ANH SON`.
4. Đối chiếu trên TMS / BBGN giấy → SKU `4305257` thực tế đã giao đủ **20 case**.
5. Kết luận: dashboard sai → NVC `ANH SON` bị đổ oan; SO này phải là Infull thay vì Failed Infull.

## Expected

- `mv_otif.sum_san_luong_giao_cse` cho SO `8482485892` = **290** (đúng raw STM)
- `infull_status` = `'Infull'`
- `otif_status` = `'OTIF'` (vì Ontime + Infull)
- `not_infull_reason` = `NULL`

## Actual (current)

- `mv_otif.sum_san_luong_giao_cse` = **270** (mất 20 vì line 8 không match được STM)
- `infull_status` = `'Failed Infull'`
- `otif_status` = `'Failed OTIF'`
- `not_infull_reason` = `'Transport Infull Failure'`

## Root cause

DDL của `mv_otif_stm_data` derive `LineNo` từ `opg.code_sync` bằng **strip 1 ký tự cuối**:

> File: [`projects/mondelez/02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql`](../../../02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql) — line 3862

```sql
leftUTF8(ifNull(opg.code_sync, ''),
         greatest(lengthUTF8(ifNull(opg.code_sync, '')) - 1, 0)) AS LineNo
```

Logic này giả định ngầm `STM.code_sync = SWM.ORDERLINENUMBER × 10` (dense, không gap). **Sai khi STM có gap** trong dãy `code_sync` — thực tế khá phổ biến.

Ví dụ SO `8482485892`: STM raw có `code_sync` chạy `000010, 000020, ..., 000070, 000090` (skip `000080`). Strip last char → STM `LineNo` = `00001..00007, 00009`. SWM tuần tự `00001..00008` → line 8 không match → BBGN=20 (thực tế nằm ở `code_sync='000090'`) bị orphan → coalesce 0 trong aggregation.

## Scope (verified 30 ngày gần nhất, ETA 2026-04-13 → 2026-05-13)

| Chỉ số | Giá trị |
|---|---:|
| Tổng SO trong window | 11,523 |
| **SO bị impact** | **693 (6.01%)** |
| Total orphaned lines | 1,420 |
| **CSE bị mất khỏi `sum_san_luong_giao_cse`** | **~29,357** |

→ Ảnh hưởng systematic, không phải edge case 1 đơn lẻ. Top SO mất đến 9/10 line (vd `8482499844`) — suggest pattern STM line numbering có thể KHÔNG chỉ là gap-1-bậc.

## Caveat detect

Cột `LineNo` declare là `String` (KHÔNG Nullable). Default `join_use_nulls=0` của ClickHouse → LEFT JOIN no-match trả `LineNo=''` (empty string), KHÔNG phải NULL. Query audit phải dùng `stm.LineNo = ''` (hoặc `SETTINGS join_use_nulls = 1`) để detect orphan đúng. Dev quen Postgres/MSSQL dễ bỏ sót.

## Fix options đề xuất (chọn 1 — recommend A)

| Option | Mô tả | Effort |
|---|---|---|
| **A (recommend)** | Sequence-align: `row_number() OVER (PARTITION BY SO ORDER BY code_sync)` ở STM + `OVER (PARTITION BY SO ORDER BY ORDERLINENUMBER)` ở SWM. JOIN `(SO, rn)`. Robust với mọi gap pattern, không cần schema change. | Medium — rewrite `mv_otif_stm_data` + test |
| B | Join by `item_code` thay vì `LineNo`. Thêm `item_code` vào `mv_otif_stm_data`. | High — schema change + xử lý duplicate item |
| C | Source-side fix: yêu cầu STM expose `external_orderlinenumber` mapping ngược. | Very high — cross-team timeline |
| **E (workaround tạm)** | Exclude orphan SO khỏi `% OTIF` denominator trong widget SQL cho tới khi A deploy — stop bleeding metric. | Low — chỉnh widget SQL |

**Pre-condition cho Option A**: Data team STM cần xác nhận `code_sync` order tuyến tính theo SWM line creation order (không bị resequence khi line bị cancel/recreate).

## Evidence — link audit đầy đủ

Full audit + bằng chứng repro + scope query + top-10 impacted SO:
[`projects/mondelez/02-data/audit-results/s2-bug-otif-stm-lineno-strip-20260513.md`](../../../02-data/audit-results/s2-bug-otif-stm-lineno-strip-20260513.md)

Liên quan:
- Rule trace OTIF: [`01-sections/otif/analysis/business-rules-trace-2026-05-13.md`](../../../01-sections/otif/analysis/business-rules-trace-2026-05-13.md) — bug này = Flag-7 mới (sẽ update sau)
- SO sample audit: [`02-data/audit-results/s2-so-8482485892-cse-check-20260513.md`](../../../02-data/audit-results/s2-so-8482485892-cse-check-20260513.md)

## Note nội bộ

- Bug có thể đã tồn tại từ ngày `mv_otif_stm_data` được tạo → cần historical backfill ước tính nếu Mondelez cần re-baseline `% OTIF`.
- Trước khi báo cáo `% OTIF` chính thức ra Ops Manager Mondelez → **bắt buộc deploy workaround E** để stop wrong-blame NVC.
- `mv_dropped_stm` schema comment ghi rõ "LineNo từ code_sync (bỏ 1 ký tự cuối)" → dev biết logic nhưng không nhận thức được fragile assumption. Update comment để cảnh báo gap risk.

## DEV note

✅ **Đã fix — đóng status DONE ngày 2026-05-16 bởi PM/DA squad1.**

Lỗi sync `LineNo` giữa STM (WMS upstream) ↔ SWM (TMS upstream) đã được giải quyết ở tầng MV ClickHouse `analytics_workspace.mv_otif_stm_data`. `% Infull` không còn bị inflated False bởi STM gap pattern. Các SO impact (vd `8482485892`) đã verify khớp giữa dashboard vs BBGN giấy.

Chi tiết verify lại trong [`_releases/`](../../../01-sections/otif/_releases/) của OTIF section khi PM publish next pulse note.

## History

| Date | Event | Actor | Ref |
|---|---|---|---|
| 2026-05-13 | Discovered via /da-ch audit (SO 8482485892 wrong-blamed) | PM/DA squad1 | [s2-bug-otif-stm-lineno-strip-20260513.md](../../../02-data/audit-results/s2-bug-otif-stm-lineno-strip-20260513.md) |
| 2026-05-13 | Option B alternative validated | PM/DA squad1 | [s2-bug-otif-stm-lineno-strip-optB-check-20260513.md](../../../02-data/audit-results/s2-bug-otif-stm-lineno-strip-optB-check-20260513.md) |
| 2026-05-16 | MV `mv_otif_stm_data` DDL updated → infull sync restored | PM/DA squad1 | confirmed by user 2026-05-16 |

## Status trong source

`Đã fixed`

## Next

KHÔNG cần action. Follow-up không-blocker:
1. Verify backfill historical % OTIF — nếu Mondelez cần re-baseline metric từ trước fix, schedule 1 pulse note đối chiếu.
2. Update [`business-rules-trace-2026-05-13.md`](../../../01-sections/otif/analysis/business-rules-trace-2026-05-13.md) §4 Flag-7 với fix evidence.
