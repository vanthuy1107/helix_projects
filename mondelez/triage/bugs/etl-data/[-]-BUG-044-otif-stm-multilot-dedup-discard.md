# BUG-044: `mv_otif_swm_stm_data` dedup vứt lô + join khớp-lô làm hụt `Sản lượng giao CSE` khi SKU giao nhiều lô

- **Source**: Phát hiện qua `/debugger` + `/da-ch` ngày 2026-05-27 (trigger: SO `8482509466` báo giao 297/330 CSE — hụt 33)
- **Reporter**: PM/DA squad1 (`squad1@gosmartlog.com`)
- **Tenant**: MDLZ
- **Area**: OTIF (impact toàn dashboard `WidgetOtif` — KPI `% OTIF` / `% Infull`, Detail Table)
- **Severity**: **Sev1** — sai chỉ số kinh doanh trọng yếu, đổ oan NVC (giao đủ nhưng báo Failed Infull)
- **Priority**: **Critical/Blocker** — cùng mức BUG-042; chặn độ tin cậy `% OTIF` cho Mondelez Ops Manager
- **Triage confidence**: **High** — repro live, root cause truy tới STM raw, fix có proof
- **View**: OTIF section — toàn bộ widget bị impact
- **Tech layer**: `etl-data` — DDL MV `analytics_workspace.mv_otif_swm_stm_data` (+ `mv_otif_stm_data`)
- **Owner team**: `da` — Data Analyst / Data Engineer
- **Quan hệ**: **Regression của bản fix [BUG-042](./%5BD%5D-BUG-042-otif-stm-lineno-strip-mismatch.md)** — cùng triệu chứng (false Failed Infull), nguyên nhân mới do logic dedup/khớp-lô thêm vào ngày 2026-05-16.

## Repro steps

1. Trên dashboard OTIF (MDLZ), filter SO = `8482509466`.
2. Detail Table: line 00001 (SKU `4067111`) `Sản lượng giao CSE = 0` dù `SHIPPED CSE = 33`.
3. SO aggregate: `sum_san_luong_giao_cse = 297`, `chenh_lech = 33`, `Failed Infull` → `Failed OTIF` → `Transport Infull Failure`.
4. Đối chiếu STM raw: SKU `4067111` giao 2 lô — `03032026` (9 CSE) + `09032026` (24 CSE) = **33 CSE**. Đơn giao **đủ**.

## Expected

- `sum(Sản lượng giao CSE)` cho SO `8482509466` = **330** (= SHIPPED = ORIGINAL).
- `infull_status` = `Infull`, `otif_status` = `OTIF` (Ontime + Infull), `not_infull_reason` = NULL.

## Actual (current)

- `sum(Sản lượng giao CSE)` = **297** (mất 33 ở line 00001).
- `Failed Infull` / `Failed OTIF` / `Transport Infull Failure` — sai.

## Root cause

DDL live `mv_otif_swm_stm_data` (qua `SHOW CREATE`):

1. **CTE `stm_deduped`** giữ 1 dòng STM / `(Mã đơn hàng, LineNo, productCode)` theo `... QuantityBBGN DESC`. Khi 1 SKU giao nhiều lô → các lô khác bị **vứt** trước khi join. SKU 4067111: giữ lô 09032026 (BBGN 24), vứt lô 03032026 (BBGN 9).
2. **JOIN khớp lô + expiry**: `lottable01 = Note1` và `toDate(lottable05) = toDate(ExpiryDate)`. Lô STM sống sót (09032026) ≠ lô pick kho của SWM (03032026) → **no match** → giao CSE = 0 → mất trọn 33.

Bản fix BUG-042 đáng lẽ theo **Option B rollup** (`sum(QuantityBBGN)` theo `(SO, item_code)`) nhưng deploy thực tế giữ grain dòng + thêm khớp lô/expiry → vỡ ca SKU-nhiều-lô (và ca lô-pick ≠ lô-BBGN).

> `has_stm_line` KHÔNG phát hiện được orphan này (ClickHouse `join_use_nulls=0` → no-match điền `''` thay vì NULL → cờ = 1 nhầm).

## Scope (verified 30 ngày, ETA window)

| Chỉ số | Giá trị |
|---|---:|
| Tổng SO trong window | 22,613 |
| **SO có ≥1 ca dedup vứt lô** | **577 (2.55%)** |
| Dòng STM bị vứt | 691 |
| BBGN bị vứt (cận trên) | ~8,625 |

## Fix đề xuất

| Option | Mô tả | Effort |
|---|---|---|
| **A (recommend)** | Rollup BBGN: thay `stm_deduped` bằng `sum(QuantityBBGN)` theo `(Mã đơn hàng, productCode)`; JOIN chỉ `(SO, item_code)`, **bỏ Note1/ExpiryDate**. Proof: rollup = 330 ✓. Xử lý ca 1 SKU / N SWM line bằng chia tỉ lệ theo SHIPPED (tránh nhân đôi ở `GROUP BY (SO, Item Code, ORDERLINENUMBER)`). | Medium — rewrite MV + regression |
| B | Giữ khớp-lô nhưng **không dedup**, đồng thời SUM mọi lô match. Vẫn rớt ca lô-pick ≠ lô-BBGN → không đề xuất. | Medium |

**Pre-condition**: regression test 7 line single-lot không đổi; đo lại số mất thực tế (rollup-vs-current) trên window; cân nhắc backfill/re-baseline `% OTIF` lịch sử.

> MV production — đổi DDL qua data engineer Smartlog, KHÔNG tự `ALTER`/recreate trên `analytics_workspace`.

## Evidence

Full audit + repro + scope + fix proof:
[`projects/mondelez/02-data/audit-results/s2-so-8482509466-cse-undercount-20260527.md`](../../../02-data/audit-results/s2-so-8482509466-cse-undercount-20260527.md)

Liên quan: [`[D]-BUG-042`](./%5BD%5D-BUG-042-otif-stm-lineno-strip-mismatch.md), [`s2-bug-otif-stm-lineno-strip-optB-check-20260513.md`](../../../02-data/audit-results/s2-bug-otif-stm-lineno-strip-optB-check-20260513.md) (Option B rollup gốc).

## Note nội bộ

- BUG-042 đóng "Đã fixed" 2026-05-16 nhưng bản deploy ≠ Option B khuyến nghị → đẻ regression này. Cần thông báo: `% OTIF` vẫn chưa đáng tin cho rollout chính thức cho tới khi BUG-044 đóng.
- Snapshot DDL `clickhouse-ddl/analytics-workspace_mvs.sql` (2026-05-16 03:10 UTC) đã stale (còn điều kiện `ORDERLINENUMBER=LineNo`); live đã bỏ. Chạy lại `export_clickhouse_ddl.py`.

## History

| Date | Event | Actor | Ref |
|---|---|---|---|
| 2026-05-27 | Discovered via /debugger+/da-ch (SO 8482509466 hụt 33 CSE) | PM/DA squad1 | [s2-so-8482509466-cse-undercount-20260527.md](../../../02-data/audit-results/s2-so-8482509466-cse-undercount-20260527.md) |

## Status trong source

`New` — chưa pickup

## Next

1. Data engineer Smartlog: sửa MV theo Option A (rollup) + regression + backfill.
2. Sau fix: re-run query rollup-vs-current đo lại số SO/CSE được khôi phục; verify SO 8482509466 → Infull/OTIF.
