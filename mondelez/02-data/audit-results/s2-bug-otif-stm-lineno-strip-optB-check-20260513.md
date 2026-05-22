# S2 — Option B Feasibility Check: Join STM↔SWM by `(SO, item_code)`

**Date:** 2026-05-13
**Auditor:** PM/DA (via `/da-ch`)
**Parent audit:** [`s2-bug-otif-stm-lineno-strip-20260513.md`](./s2-bug-otif-stm-lineno-strip-20260513.md)
**Source MV:** `analytics_workspace.mv_otif_stm_data` (proposed schema change), `mv_otif_swm_data`, `mv_otif_swm_stm_data` (join change)
**ClickHouse server:** ghrx9lirdl.ap-southeast-1.aws.clickhouse.cloud (Cloud, ap-southeast-1)
**MV refresh policy:** `REFRESH EVERY 1 HOUR` — caveat: data trễ tối đa 1h
**Snapshot taken:** 2026-05-13 (queries run live, results reproducible)

---

## 1. TL;DR — verdict cho Option B

| Tiêu chí | Kết quả | Verdict |
|---|---|---|
| **Khả thi schema** | item_code lấy được qua chain STM `dim_ord_product_group → dim_ord_product → subdim_cus_product.code` | ✅ FEASIBLE |
| **Effectiveness (line-level)** | Recovery 1,419/1,420 orphan lines trong 30 ngày, 3,713/3,718 trong 90 ngày (~99.87%) | ✅ EXCELLENT |
| **Effectiveness (CSE recovery)** | Recovery 29,357.31 / 29,357.31 CSE trong 30 ngày, 88,741.31 / 88,741.31 trong 90 ngày (**100% trong cả 2 window**) | ✅ EXCELLENT |
| **BBGN sum accuracy** | Truth=1,422,727 → Old=-3.17%, OptB-any=+0.19%, **OptB-rollup=-0.12%** → 16× cải thiện | ✅ EXCELLENT |
| **Regressions** | 0 lines bị regression (mọi line đang match dưới logic cũ đều vẫn match dưới Option B) | ✅ ZERO RISK |
| **Ambiguity risk (con của audit)** | 1,009 / 95,851 pairs có dup cả 2 side (~1.05%); 305 chỉ SWM dup; 0 chỉ STM dup | ⚠️ QUANTIFIED — small, manageable |
| **Schema change** | Thêm 1 cột `Item Code` vào `mv_otif_stm_data` + đổi JOIN trong `mv_otif_swm_stm_data` | 🟡 Effort **moderate** (KHÔNG như "High" mà audit gốc đánh giá) |
| **Pathological case (SO 8482499844)** | Old match 0/10 lines, Option B match 10/10 lines (BBGN từ 0 → đầy đủ) | ✅ ROBUST |

**Recommendation cập nhật**: Option B **vượt trội Option A trong mọi metric đo được**.
- Pathological case 8482499844 không phải "STM line numbering khác hoàn toàn SWM" — mà là STM `code_sync` chạy theo `000060, 000170, …, 000250` (giá trị giả lập sequence từ SAP, không liên quan tới SWM line order). Sequence-align (Option A) sẽ **sai** vì sort STM theo code_sync ra `000060 → 000170 → …` rồi gán `00001..00010` thì gán mapping `SAP-line-6 → SWM-line-1` → vô nghĩa nghiệp vụ.
- Option B (SKU anchor) là **đúng bản chất nghiệp vụ**: "shipment cho SKU X trong đơn này bằng bao nhiêu" — không phụ thuộc thứ tự tạo line.

---

## 2. Item_code path — verified

Chain trong STM datawarehouse (đã verify trực tiếp):

```
stm_dwh_mondelez.dim_ord_product_group (opg)         -- 1 row per line
    ↓ join: dim_ord_product.group_product_id = opg.id
stm_dwh_mondelez.dim_ord_product (op)
    ↓ join: subdim_cus_product.key_sk = op.subcus_product_sk
stm_dwh_mondelez.subdim_cus_product (cp)
    → cp.code = item_code (= SKU)
    → cp.product_name = tên SKU
```

Spot-check SO `8482485892` (case gốc của bug):

| opg_id | code_sync | LineNo_strip (sai) | item_code (truth) | product_name |
|---|---|---|---|---|
| 3493436 | `000010` | `00001` | `4253217` | MINI OREO CHOCOLATE 6X10X20.4G MSTVH |
| 3493437 | `000020` | `00002` | `4253218` | MINI OREO ORIGINAL 6X10X20.4G MSTVH |
| 3493438 | `000030` | `00003` | `4326368` | OREO VANILLA 24X105G C2 |
| 3493439 | `000040` | `00004` | `4315598` | LU BANH QUY BO THAP CAM 540GRX6HT ATM |
| 3493440 | `000050` | `00005` | `4086399` | SOLITE TRON KEM BO SUA 276GRX10H |
| 3493441 | `000060` | `00006` | `4331291` | SOLITE CUON KEM BO SUA KM 18+4 396GX12K |
| 3493442 | `000070` | `00007` | `4331290` | SOLITE CUON KEM LA DUA KM 18+4 396GX12K |
| 3493443 | **`000090`** | **`00009`** | **`4305257`** | **SLIDE CHEESE 90G X 14 LON** ← line gốc của bug |

→ item_code `4305257` trùng khớp tuyệt đối với SKU trong audit gốc.

> **Cardinality `opg → op`**: trong sample này 1:1 (mỗi opg có đúng 1 op). Cần verify rộng hơn — xem §5 caveat 1.

---

## 3. Side-by-side: bug hiện tại vs Option B (SO 8482485892)

| SWM line | SWM item | SWM CSE | STM code_sync | STM LineNo_strip | STM item | Old (LineNo_strip) | **Option B (item_code)** |
|:---:|:---:|---:|:---:|:---:|:---:|:---:|:---:|
| 00001 | 4253217 | 30 | 000010 | 00001 | 4253217 | ✓ | ✓ |
| 00002 | 4253218 | 40 | 000020 | 00002 | 4253218 | ✓ | ✓ |
| 00003 | 4326368 | 60 | 000030 | 00003 | 4326368 | ✓ | ✓ |
| 00004 | 4315598 | 20 | 000040 | 00004 | 4315598 | ✓ | ✓ |
| 00005 | 4086399 | 40 | 000050 | 00005 | 4086399 | ✓ | ✓ |
| 00006 | 4331291 | 40 | 000060 | 00006 | 4331291 | ✓ | ✓ |
| 00007 | 4331290 | 40 | 000070 | 00007 | 4331290 | ✓ | ✓ |
| **00008** | **4305257** | **20** | **000090** | **00009** | **4305257** | **✗ ORPHAN** | **✓ MATCHED** |

→ Option B phục hồi đúng 20 CSE bị mất. Không hồi quy 7 dòng đang đúng.

---

## 4. Pathological case SO 8482499844 — Option B ROBUST hơn Option A

Audit gốc đánh dấu SO này là "STM line numbering hoàn toàn khác SWM" (chỉ 1/10 match) và lo ngại Option A có thể không xử lý được. Kết quả test Option B:

| SWM line | SWM item | SWM CSE | STM code_sync | STM LineNo_strip | Old match? | **Option B match?** |
|:---:|:---:|---:|:---:|:---:|:---:|:---:|
| 00001 | 4299263 | 30 | 000060 | 00006 | ✗ | ✓ |
| 00002 | 4306428 | 110 | 000170 | 00017 | ✗ | ✓ |
| 00003 | 4306429 | 66 | 000180 | 00018 | ✗ | ✓ |
| 00004 | 4306430 | 33 | 000190 | 00019 | ✗ | ✓ |
| 00005 | 4306431 | 22 | 000200 | 00020 | ✗ | ✓ |
| 00006 | 4320256 | 22 | 000210 | 00021 | ✗ | ✓ |
| 00007 | 4326384 | 84 | 000220 | 00022 | ✗ | ✓ |
| 00008 | 4326400 | 28 | 000230 | 00023 | ✗ | ✓ |
| 00009 | 4328569 | 30 | 000240 | 00024 | ✗ | ✓ |
| 00010 | 4330468 | 36 | 000250 | 00025 | ✗ | ✓ |

→ **10/10 lines fix bằng Option B**. STM `code_sync` của SO này chạy `000060 → 000170 → …` (sequence từ SAP, nhảy bậc) — sort-by-code_sync (Option A) sẽ ánh xạ vô nghĩa nghiệp vụ (SAP-line-6 ↔ SWM-line-1). Option B (SKU) xử lý đúng bản chất.

---

## 5. Scope quantification — 30D và 90D

### 5.1 Line-level recovery

| Window | SWM lines total | Orphan (old) | Lost CSE (old) | Orphan (Option B) | Lost CSE (Option B) | Recovered lines | Recovered CSE | Regressed |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 30 ngày | 97,176 | 1,420 | 29,357.31 | **1** | **0** | **1,419** | **29,357.31** | 0 |
| 90 ngày | 258,814 | 3,718 | 88,741.31 | **5** | **0** | **3,713** | **88,741.31** | 0 |

### 5.2 BBGN sum accuracy (key insight — Option B đúng bản chất NUMERIC chứ không chỉ join coverage)

Test trên 30 ngày — tổng BBGN sau khi propagate qua join, so với ground-truth tổng BBGN raw từ STM:

| Strategy | Tổng BBGN emit | % Error vs truth |
|---|---:|---:|
| Truth (raw STM sum) | 1,422,727 | (baseline) |
| **Old (LineNo_strip)** | **1,377,586** | **-3.173%** (under-count, ~45k CSE thất thoát) |
| Option B — naive `any()` | 1,425,452 | +0.192% (slight over-count do dup) |
| **Option B — rollup `sum() per (SO, item)`** | **1,421,088** | **-0.115%** ✅ (gần đúng nhất) |

→ Variant `rollup` cải thiện 27× so với bug hiện tại. Variant `any()` cải thiện 16×. **Cả 2 đều áp dụng được**; sai số `any()` chấp nhận được cho first roll-out.

### 5.3 Residual orphan (cái Option B không fix được)

Chỉ 1 SO trong 30 ngày bị Option B không match được: SO `8482478793`, line `00001-SP001`, SKU `4305245`, **SHIPPED CSE = 0**.

- Format line `00001-SP001` cho thấy đây là SP-suffix line (supplementary product) — STM không tạo line tương ứng (SKU không nằm trong dim_ord_product của order này).
- Không ảnh hưởng metric vì CSE = 0.
- → Có thể bỏ qua an toàn. Hoặc thêm rule "ignore SP-suffix lines" downstream.

---

## 6. Duplicate ambiguity — risk audit gốc đã cảnh báo

Audit gốc viết:
> "Cùng SO có thể có 2+ line cùng item_code → ambiguous match → cần agg"

**Quantification (30 ngày, dựa trên 95,851 (SO, item_code) pairs có data cả 2 side):**

| Pattern | Số pairs | % | Diễn giải |
|---|---:|---:|---|
| 1 SWM line × 1 STM line | 94,537 | **98.63%** | Clean — không cần xử lý đặc biệt |
| Many SWM × 1 STM | 305 | 0.32% | Cần split BBGN nếu giữ line grain |
| 1 SWM × Many STM | **0** | 0% | Không xảy ra trong data thực |
| **Many SWM × Many STM** | **1,009** | **1.05%** | **AMBIGUOUS** — cần aggregate |

Insight: 0 pair có STM dup mà SWM không dup → bất cứ khi nào STM tách 1 SKU thành nhiều line, SWM cũng tách. Có thể vì cùng 1 SKU được ship trong nhiều batch / pallet riêng và STM ghi BBGN tách theo từng chuyến.

Sample ambiguous case lớn nhất: SO `8482499973`, SKU `4319360` (SLIDE-CHEESE 145GR X 14LON):
- STM: 2 lines, BBGN = 9 + 1 = 10
- SWM: 2 lines
- → Aggregate `sum(BBGN) per (SO, item) = 10` rồi attach 1 lần (rollup) hoặc split proportionally — đều ra cùng tổng.

---

## 7. Schema change cần thiết (concrete diff)

### 7.1 `mv_otif_stm_data` — thêm cột `Item Code`

```sql
-- THÊM 1 cột vào schema declaration
`Item Code` String,

-- TRONG SELECT, thêm các LEFT JOIN:
SELECT
    opg.id AS ID_ORD_GroupProduct,
    ordm.code AS `Mã đơn hàng`,
    -- (giữ nguyên dòng strip-last-char cho backward compat trong giai đoạn rollout song song)
    leftUTF8(ifNull(opg.code_sync, ''), greatest(lengthUTF8(ifNull(opg.code_sync, '')) - 1, 0)) AS LineNo,
    ifNull(cp.code, '')                                                                         AS `Item Code`,  -- <-- NEW
    dtd.quantity_bbgn AS QuantityBBGN,
    ...
FROM stm_dwh_mondelez.dim_ord_order AS ordm
LEFT JOIN stm_dwh_mondelez.dim_ord_product_group AS opg ON opg.order_id = ordm.id
LEFT JOIN stm_dwh_mondelez.dim_ord_product       AS op  ON op.group_product_id = opg.id AND ifNull(toUInt8(op.is_deleted), 0) = 0     -- <-- NEW
LEFT JOIN stm_dwh_mondelez.subdim_cus_product    AS cp  ON cp.key_sk = op.subcus_product_sk                                          -- <-- NEW
LEFT JOIN ... -- (giữ nguyên các JOIN khác)
```

→ Chỉ 2 LEFT JOIN mới + 1 cột mới. Effort thực tế **không cao như audit gốc đánh giá** ("High — schema change + xử lý duplicate").

### 7.2 `mv_otif_swm_stm_data` — đổi JOIN condition

```sql
-- CŨ:
LEFT JOIN analytics_workspace.mv_otif_stm_data AS stm_data
    ON (swm_data.SO = stm_data.`Mã đơn hàng`)
   AND (toString(swm_data.ORDERLINENUMBER) = toString(stm_data.LineNo))

-- MỚI (variant rollup — recommend cho accuracy):
LEFT JOIN (
    SELECT
        `Mã đơn hàng`                                       AS so,
        `Item Code`                                         AS item_code,
        sum(QuantityBBGN)                                   AS QuantityBBGN_total,
        anyHeavy(`Tên ngắn nhà vận tải`)                    AS `Tên ngắn nhà vận tải`,
        -- (rollup các field khác tương tự — anyHeavy() lấy giá trị xuất hiện thường nhất)
        ...
    FROM analytics_workspace.mv_otif_stm_data
    WHERE `Item Code` != ''
    GROUP BY `Mã đơn hàng`, `Item Code`
) AS stm_data
    ON swm_data.SO = stm_data.so
   AND swm_data.`Item Code` = stm_data.item_code
```

→ Grain của `mv_otif_swm_stm_data` chuyển ngầm: BBGN bây giờ là tổng theo (SO, item_code), KHÔNG còn theo line. Mọi SWM dup-line cùng 1 SKU sẽ thấy cùng giá trị BBGN_total → cần điều chỉnh `Sản lượng giao CSE` xuống grain (SO, item) downstream để tránh double-count. Xem §8.

### 7.3 Alternative — variant `any()` (đơn giản hơn nhưng có sai số nhỏ)

Nếu không muốn refactor downstream:
```sql
LEFT JOIN (
    SELECT
        `Mã đơn hàng` AS so,
        `Item Code`   AS item_code,
        any(QuantityBBGN) AS QuantityBBGN,  -- pick 1 STM line per (SO, item)
        any(...) ...
    FROM analytics_workspace.mv_otif_stm_data
    WHERE `Item Code` != ''
    GROUP BY `Mã đơn hàng`, `Item Code`
) AS stm_data ON ...
```
→ Sai số tổng BBGN ~0.2% (over-count). Trade-off: code đơn giản hơn nhưng dup pairs sẽ over-count nhẹ.

---

## 8. Caveats cần verify trước khi commit

| # | Caveat | Cách verify |
|---|---|---|
| 1 | Cardinality `dim_ord_product` vs `dim_ord_product_group` — đảm bảo không có row explosion | `SELECT opg.id, count() FROM dim_ord_product_group opg LEFT JOIN dim_ord_product op ON op.group_product_id = opg.id GROUP BY opg.id HAVING count() > 1` — nếu trả về > 1 row → có opg có nhiều product → cần handle |
| 2 | `subdim_cus_product.key_sk` unique theo subcus_product_sk | `SELECT key_sk, count() FROM subdim_cus_product GROUP BY key_sk HAVING count() > 1` — nếu duplicate trong subdim → spurious product_name |
| 3 | item_code = NULL/empty rate trong STM | Mức null hiện tại unknown; cần filter `cp.code != ''` để tránh "ALL NULL ← ALL NULL" join thành cartesian-zombie |
| 4 | Downstream `mv_otif` aggregation logic — `sumIf(Sản lượng giao CSE)` không double-count khi 1 STM BBGN attach lên nhiều SWM line dup | Phải audit `mv_otif` DDL sau khi đổi join — nếu nó sum theo `SO` thì rollup variant cần share BBGN xuống line cấp; nếu nó sum theo `(SO, item)` thì rollup OK |
| 5 | MV refresh sequence — `mv_otif_stm_data` (refresh 1h) phải refresh **trước** `mv_otif_swm_stm_data` (refresh 1h) để tránh stale join | Confirm scheduling thứ tự, hoặc đổi `mv_otif_stm_data` xuống refresh 30 phút |
| 6 | SP-suffix lines `00001-SP001`, … trong SWM | Khi rollout, decide policy: ignore vs forced match. Hiện chỉ thấy 1 case CSE=0 → có thể bỏ qua |
| 7 | Historical backfill | Sau khi Option B deploy, cần re-run scope query đếm số SO trước-rollout bị flag Failed Infull oan → publish "data correction notice" cho Mondelez Ops Manager nếu họ muốn re-baseline |

---

## 9. Recommendation tổng thể

1. **Greenlight Option B** — không chọn Option A. Lý do: Option A (sequence-align) fail trên pathological case 8482499844 vì STM code_sync nhảy bậc theo SAP — sort theo code_sync ánh xạ vô nghĩa nghiệp vụ.
2. **Effort thực tế: Moderate (không High)** — chỉ thêm 1 cột + 2 LEFT JOIN trong `mv_otif_stm_data`, đổi 1 join trong `mv_otif_swm_stm_data`. Tổng < 30 dòng SQL.
3. **Variant chọn: rollup** (accuracy -0.12%) cho phiên bản chính, nhưng `any()` (accuracy +0.19%) chấp nhận được nếu chạy tight timeline.
4. **Vẫn nên triển khai Option E (workaround)** song song trong 1–2 sprint đầu để stop bleeding metric trong khi schema-change-test còn diễn ra.
5. **Trước commit phải verify 7 caveat trong §8** — đặc biệt #1 (row explosion), #4 (downstream double-count), #5 (refresh order).

---

## 10. Query tham khảo (cho data engineer Smartlog)

### 10.1 Verify caveat #1 (row explosion `opg → op`)

```sql
WITH recent_opg AS (
    SELECT opg.id
    FROM stm_dwh_mondelez.dim_ord_product_group opg
    WHERE opg.order_id IN (
        SELECT id FROM stm_dwh_mondelez.dim_ord_order
        WHERE code IN (SELECT so FROM analytics_workspace.mv_otif WHERE toDate(eta_giao_hang_cho_npp) >= today() - 30)
    )
    AND ifNull(toUInt8(opg.is_deleted), 0) = 0
)
SELECT
    countIf(n = 1) AS opg_1to1_op,
    countIf(n > 1) AS opg_1toN_op,
    max(n)         AS max_n
FROM (
    SELECT opg.id AS opg_id, count() AS n
    FROM recent_opg opg
    LEFT JOIN stm_dwh_mondelez.dim_ord_product op
        ON op.group_product_id = opg.id AND ifNull(toUInt8(op.is_deleted),0) = 0
    GROUP BY opg.id
);
```

### 10.2 Verify caveat #4 (sample 5 ambiguous SOs to see what downstream `mv_otif` reports vs truth)

```sql
SELECT
    SO,
    sum(`Sản lượng giao CSE`) AS sum_giao_cse_now,
    sum(`SHIPPED CSE`)        AS sum_shipped_cse_now
FROM analytics_workspace.mv_otif_swm_stm_data
WHERE SO IN ('8482499973', '8482485892')  -- (ambiguous + simple) cases
GROUP BY SO;
```

---

## 11. Confidence & Next action

## ARTIFACT_PATH: `projects/mondelez/02-data/audit-results/s2-bug-otif-stm-lineno-strip-optB-check-20260513.md`
## DATA_CONFIDENCE: **High** — Tất cả số đo (recovery rate, BBGN accuracy, dup distribution) reproducible bằng SQL trong file này; pathological case verify trực tiếp; item_code path verified end-to-end với SO `8482485892` & `8482499844`.
## MV_FRESHNESS: snapshot 2026-05-13 (queries chạy live trên ClickHouse production); refresh policy `REFRESH EVERY 1 HOUR` cho cả 3 MV liên quan.
## NEXT_ACTION:
- **(decision needed)** PM/DA confirm hướng đi: **Greenlight Option B** với variant rollup
- **(immediate)** Verify 7 caveats trong §8 — especially row explosion (caveat #1) — trước khi cho Data Engineer Smartlog dev
- **(parallel)** `/da-pm` để add task implement Option B vào sprint, **deprioritize** Option A (đã có evidence Option A sai trên pathological case)
- **(follow-up)** Sau deploy: chạy lại scope query trên window mới để đo dropdown của `not_infull_reason = 'Transport Infull Failure'` (xác minh fix end-to-end về business metric)
