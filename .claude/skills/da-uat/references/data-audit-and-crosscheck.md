# Data Audit & Cross-System Cross-Check (depth)

> Skill reference. Đọc khi cần (1) **summary** sức khỏe dữ liệu, (2) **quét dữ liệu bất thường** (5 nhóm anomaly), (3) **đối chiếu chéo với nguồn khác** (WMS/SWM, TMS report) — TRƯỚC khi vào reconciliation 3 nguồn của Mode B.
>
> Nguồn gốc: bóc từ 2 notebook canonical của Mondelez. KHÔNG viết lại logic — load/clone từ đó rồi đổi tham số.

---

## 0. Canonical tooling — KHÔNG tự sinh lại

| Notebook / script | Dùng cho | Path |
|---|---|---|
| `flash_daily_mtd_audit.ipynb` | Summary health + 5 nhóm anomaly trên view `mv_flash_and_drop_report` (parity với `mv_flash_report` + `mv_dropped_report`) | `projects/{tenant}/notebooks/` |
| `tms_report_25_explore.ipynb` | Explore TMS report #25 (`mdlz_tms_report_25_trip_order`) đa cấp (đơn / chuyến / ngày) + **section L6 cross-check TMS ↔ `mv_otif`** | `projects/{tenant}/notebooks/` |
| `uat_*_export.py`, `uat_quick_check_export.py` | Export Excel pack reconciliation (Mode A.7) | `projects/{tenant}/scripts/` |

Khi audit 1 section UAT: **clone cell tương ứng, đổi `PARAMS` (window, filter, date_col), re-run**. Mọi SQL canonical đã xử lý timezone, parameter-binding UTF-8, grain rollup — tự viết lại = tái phát bug đã fix.

**Gotcha parameter binding** (đã debug, BẮT BUỘC nhớ): chuỗi tiếng Việt (`'Xuất bán'`, `'Hoàn tất'`, `'Đã vận chuyển'`) phải bind qua `{svc:String}` / `{ht:String}` — KHÔNG inline literal. `clickhouse-connect` corrupt UTF-8 trong scalar subquery khi inline → trả 0 row sai. Bind = đúng số.

---

## 1. Ba lớp audit này đứng ở đâu trong lifecycle

Chạy trong **Mode B (Pre-UAT)** TRƯỚC reconciliation 3 nguồn — và (thiết kế scope) trong **Mode A**.

```
A. Design  → chốt: anomaly group nào áp dụng cho section, cross-source pair nào (xem §4)
B. Pre-UAT → [B.0 summary] → [B.0b anomaly sweep] → [B.5 cross-system] → reconciliation 3 nguồn
```

Lý do đặt TRƯỚC: nếu data nền có integrity violation (volume âm, status mâu thuẫn, key trùng) hoặc lệch lớn với WMS/TMS, thì đối chiếu Dashboard vs Golden vô nghĩa — phải surface anomaly thành defect/finding trước, không vào session với data bẩn.

**Quy tắc xuất**: mọi anomaly count > ngưỡng OR mọi diff cross-system vượt tolerance → **defect stub** (Mode C format) HOẶC dòng note "Accepted" có root cause. KHÔNG để rớt im lặng.

---

## 2. Part A — Summary sức khỏe dữ liệu (the "summary")

Mục tiêu: 1 ảnh chụp nhanh "data có đủ + tươi + phân bố hợp lý + tổng volume đúng độ lớn?" trước khi tin bất kỳ số nào.

| Block | Tính gì | SQL pattern (ClickHouse) |
|---|---|---|
| **Scale** | row count, distinct order/key, dòng chưa gắn chuyến | `count()`, `uniqExact(so)`, `uniqExactIf(MasterCode, MasterCode!='')`, `countIf(MasterCode='')` |
| **Window** | ngày nhỏ nhất / lớn nhất có data | `min(toDate(...))`, `max(toDate(...))` |
| **Freshness** | độ trễ data so với now | `dateDiff('minute', max(ngay_tao_don), now())` → lag phút |
| **Distribution** | phân bố theo `e2e_label` / status / type / whseid / brand / kênh / khu vực | `GROUP BY {dim}` + `count()` + `round(100*count()/sum(count()) OVER (),2)` pct + `sum({uom})` volume |
| **Volume totals** | tổng Plan / Shipped / Delivered × CSE/KG/CBM | `sum(original_cse)`, `sum(shipped_cse)`, `sum(san_luong_giao_cse)` (+ Ton/CBM tương đương) |
| **Column coverage** | % non-null mỗi cột thời gian/số (data nào dùng được) | `round(100*countIf({col}!='')/count(),1)` pct_non_null; `countIf(NUM(col)!=0)` cho numeric |

**Đọc summary thế nào**:
- `dong_chua_len_chuyen` lớn / `MasterCode=''` nhiều → nhiều đơn chưa gắn chuyến, ảnh hưởng mẫu số on-time.
- Freshness lag > kỳ vọng refresh (vd `mv_otif` REFRESH 5′) → MV chưa cập nhật, **dừng** reconcile, đợi/force refresh.
- Distribution có bucket `(NULL)` / `(rỗng)` cao bất thường ở dim quan trọng → master data quality issue → red flag cho session.
- Volume total lệch một bậc độ lớn so với kỳ vọng khách → sai filter/window, không phải logic.

Helper macro (TMS report — cột staging đều String): `DT(col)=parseDateTimeBestEffortOrNull(nullIf(col,''))`, `NUM(col)=toFloat64OrZero(col)`.

---

## 3. Part B — Quét dữ liệu bất thường (5 nhóm anomaly)

Mỗi nhóm = nhiều `countIf(<điều kiện vi phạm>)` trong 1 query + `count() AS total_rows`. Vi phạm > 0 → drill listout (LIMIT 100, sort theo độ nặng) → defect/finding.

### Nhóm 1 — NULL / Empty trên field critical
`countIf(col IS NULL OR col='')` cho mọi key + dim + date + status critical; coi `original_cse IS NULL OR =0` là bất thường. Báo count + % tổng window.
→ Field nghiệp vụ bắt buộc mà NULL = data ingestion thiếu / master data chưa map.

### Nhóm 2 — Volume integrity
| Check | Điều kiện vi phạm |
|---|---|
| Volume âm | `original_cse < 0` / `shipped_cse < 0` / `san_luong_giao_cse < 0` / `original_qty < 0` |
| Over-shipment | `shipped_cse > original_cse AND original_cse > 0` |
| Over-delivery | `san_luong_giao_cse > shipped_cse AND shipped_cse > 0` |
| QTY=0 nhưng CSE>0 | `original_qty <= 0 AND original_cse > 0` |
| Có volume nhưng thiếu ref/timestamp | `original_cse>0 AND original_pl IS NULL`; `san_luong_giao_cse>0 AND ata_den IS NULL` |
→ Vi phạm monotonicity Plan ≥ Shipped ≥ Delivered = lỗi nguồn hoặc đổi đơn vị.

### Nhóm 3 — Business rule cross-field (status ↔ label ↔ fact mâu thuẫn)
| Check | Điều kiện vi phạm |
|---|---|
| Cancel nhưng đã giao | `status='Cancel' AND san_luong_giao_cse > 0` |
| Label vs timestamp | `e2e_label='Đã vận chuyển' AND ata_den IS NULL`; `'Đang vận chuyển' AND atd_den IS NULL`; `ata_den IS NOT NULL AND e2e_label='Đang vận chuyển'` |
| Date phi lý | `toDate(delivery_date_1) > today()`; `delivery_date_1 < '2020-01-01' OR > now()+90 DAY` |
| Drop không lý do | `e2e_label='Kế hoạch hủy' AND (remark_2 IS NULL OR ='')` |
→ Status enum nói A nhưng fact nói B → STM lag hoặc logic gán label sai.

### Nhóm 4 — Key uniqueness & cross-MV parity
- **Dup key**: `GROUP BY so, orderlinenumber HAVING count()>1` → kỳ vọng 0 trong window.
- **Parity** giữa view tổng và 2 view thành phần: `rows_combined == rows_flash + rows_dropped` (quan hệ UNION ALL). `parity_diff != 0` → MV compose sai → escalate `/da-ch`.

### Nhóm 5 — Timestamp ordering (7 ràng buộc thời gian)
`countIf(a IS NOT NULL AND b IS NOT NULL AND a > b)` cho mỗi cặp phải tăng dần:
`ngay_tao_don ≤ delivery_date_1` · `thoi_gian_gui_thau(bid) ≤ etd` · `etd ≤ eta` · `atd_den ≤ ata_den` · `ata_den ≥ etd` · `actual_ship_date ≤ atd+1d` · `gio_ra_dock ≤ thoi_gian_di`.
→ Đảo ngược thời gian = STM logging lỗi / clock skew / sai mapping cột.

**Drill listout** mỗi vi phạm: select key cols + 2 timestamp + `dateDiff('hour', later, earlier) AS hours_reversed` ORDER BY DESC LIMIT 100. Có thể `GROUP BY whseid/khu_vuc` để tìm hotspot (segment nào vi phạm tập trung).

**Rollup**: 1 cell summary cuối gom count đại diện mỗi nhóm + dup + parity → 1 dòng verdict "X nhóm sạch / Y nhóm có vi phạm" mang vào plan.

---

## 4. Part C — Đối chiếu chéo với nguồn khác (WMS / TMS)

Bổ sung "nguồn thứ 4" ngoài 3 nguồn chuẩn (Dashboard / SQL / Golden): **hệ thống nguồn upstream**.

| Nguồn cross-check | Là gì | Bảng/MV |
|---|---|---|
| **TMS report #25** | Báo cáo TMS cấp `Order × Trip` (REPDIOPSPlan #25) | `analytics_workspace.mdlz_tms_report_25_trip_order` (staging, cột String, filter `position(OrderCode,'-')=0`) |
| **OTIF MV** | MV dashboard OTIF, REFRESH 5′, grain `so × whseid` | `analytics_workspace.mv_otif` |
| **WMS / SWM** | Smart Warehouse Management — outbound/order fulfillment, 6 kho (BKD1/2/3, NKD, VN821, VN831), ReplacingMergeTree CDC | `dim_orders`, `dim_orderdetail`, `fact_order_fulfillment`, `fact_outbound` (xem `02-data/data-sources/swm-datawarehouse.md`) |

Mục đích: chứng minh dashboard MV **không drift khỏi hệ thống nghiệp vụ gốc** (TMS quyết on-time qua thực tế giao; WMS quyết in-full qua picking/outbound thực tế). Dashboard MV là dẫn xuất — phải khớp upstream.

### 4 kỹ thuật cross-check (từ section L6 của tms notebook)

**(1) Count + set membership theo ngày** — FULL OUTER JOIN 2 nguồn trên `(code, ngay)`:
```sql
WITH a AS (SELECT DISTINCT code, ngay FROM src1),
     b AS (SELECT DISTINCT code, ngay FROM src2)
SELECT ngay,
       countIf(in_a AND in_b)        AS trung,
       countIf(in_a AND NOT in_b)    AS chi_a,
       countIf(NOT in_a AND in_b)    AS chi_b
FROM (SELECT coalesce(a.code,b.code) code, coalesce(a.ngay,b.ngay) ngay,
             a.code!='' in_a, b.code!='' in_b
      FROM a FULL OUTER JOIN b USING (code, ngay))
GROUP BY ngay ORDER BY ngay
```
→ `chi_a` / `chi_b` lớn = lệch tập đơn, KHÔNG phải lệch số liệu — xử lý trước khi so trạng thái.

**(2) Confusion matrix trạng thái** — INNER JOIN trên `code` (giao nhau), pivot `src1_label × src2_label`:
```sql
SELECT a.label AS tms_kl, b.label AS mv_kl, count() AS so_don
FROM a_labeled a INNER JOIN b_labeled b USING code
GROUP BY tms_kl, mv_kl ORDER BY so_don DESC
```
Đường chéo = đồng thuận; off-diagonal = lệch kết luận → list top 30 đơn lệch (sort theo độ nặng: `abs(tre_phut)` cho on-time, `abs(kh-giao)` cho in-full).

**(3) Set diff hai chiều + bucket nguyên nhân** — đơn chỉ-A / chỉ-B, rồi `GROUP BY status` để phân loại lý do (chưa lên chuyến / status='Chờ' / lệch timezone-window / service khác). Biến "lệch" thành "lệch vì lý do X đã hiểu".

**(4) Grain alignment** — BẮT BUỘC trước mọi so sánh:
- **Rollup về cùng cấp**: TMS `GROUP BY OrderCode` (`kh=max(QuantityOrder)` chống double-count khi đơn vào nhiều chuyến; `gn=sum(QuantityBBGN)`); MV `GROUP BY so`. Đơn `Failed` nếu **bất kỳ** dòng con Failed.
- **Timezone**: TMS `TenderedDate` = string giờ VN; `mv_otif.thoi_gian_gui_thau` = `DateTime64(3,'UTC')`. Quy **cả 2 về ngày VN** (`toTimeZone(...,'Asia/Ho_Chi_Minh')`) trước khi so. (Lưu ý: khác convention reconciliation dashboard trong `reconciliation-method.md` §3 — dashboard cắt theo UTC; cross-check upstream theo nghiệp vụ VN. Chốt rõ trong plan dùng quy ước nào cho từng đối chiếu.)
- **Service scope**: `mv_otif` chỉ track `ServiceOfOrderName='Xuất bán'` → filter TMS cùng service, nếu không "chỉ-TMS" sẽ phồng giả.
- **On-time grace**: 30 phút (`ONTIME_GRACE_MIN`, theo `[D]-RULE-OTIF-001`) — `DateToCome <= addMinutes(ETA, 30)`.

### Khi cross-check lệch → phân loại
| Triệu chứng | Khả năng | Action |
|---|---|---|
| `chi_tms`/`chi_mv` lớn, status='Chờ' | Đơn chưa đẩy sang MV (chưa lên chuyến) | Note "expected", loại khỏi mẫu so trạng thái |
| Lệch đúng đơn 1 khoảng giờ giáp ranh ngày | Timezone window (UTC vs VN) | Align tz, re-run |
| Off-diagonal on-time tập trung 1 NVC/kho | Logic gán on-time khác giữa 2 hệ | Drill, → `/da-ch` audit MV vs TMS rule |
| In-full lệch do đơn vị (CSE vs Ton vs thùng) | Sai cột volume | Re-map cột, không phải logic |

---

## 5. Output của 3 lớp audit này

| Sản phẩm | Path | Khi nào |
|---|---|---|
| Audit summary + anomaly report | `projects/{tenant}/{section}/uat/{section}-uat-dataaudit-{date}.md` | Mode B, trước reconciliation |
| Cross-system reconciliation report | `projects/{tenant}/02-data/audit-results/{a}-vs-{b}-{date}.md` (vd `tms-mv-otif-order-reconciliation-{date}.md`) | Mode B |
| Anomaly/lệch vượt ngưỡng → defect stub | `projects/{tenant}/{section}/uat/defects/UAT-{NNN}-{slug}.md` | Mode B/C |

Mỗi finding ghi: nhóm anomaly / cặp cross-check + count + % + drill sample + hypothesis root cause + route handoff (`/da-ch` nếu MV/SQL, `/ba` nếu định nghĩa nghiệp vụ lệch).
