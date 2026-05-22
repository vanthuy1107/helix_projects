# S2 — Pipeline Audit: DA Assessment Dataset Extract

**Date:** 2026-05-16
**Auditor:** PM/DA (via /da-ch)
**Purpose:** Trích xuất dataset mẫu từ ClickHouse Mondelez để build bài test ứng viên Data Analyst (1-2 YOE). Toàn bộ MDLZ-identifiable info phải được anonymize.
**Source MVs:**
- `analytics_workspace.mv_otif` (REFRESH EVERY 5 MINUTE)
- `analytics_workspace.mv_vfr_van_hanh` (REFRESH EVERY 1 HOUR)
- `analytics_workspace.mv_filter_vendor` / `mv_filter_warehouse` / `mv_filter_region` / `mv_filter_cargo_brand` / `mv_filter_channel`

**SQL Registry section:** [`sql-registry.md` § OTIF](../data-sources/sql-registry.md) (lines 17911+), [§ vfr operation](../data-sources/sql-registry.md) (lines 4980+)
**ClickHouse server:** `ghrx9lirdl.ap-southeast-1.aws.clickhouse.cloud:8443` (Cloud, ap-southeast-1)
**Extract artifact:** [`projects/assessments/da/`](../../../assessments/da/)

---

## 1. Metadata MV

| MV | Total rows | In-window rows (eta 2026-02-01..2026-04-30) | Distinct keys | Notes |
|---|---|---|---|---|
| `mv_otif` | 1,288,293 | 31,207 | 31,207 distinct `so` | REFRESH 5 min; 6 distinct warehouses, 10 carriers, 12 areas, 7 cargo groups, 5 channels (toàn dataset) |
| `mv_vfr_van_hanh` | 72,025 | 6,631 | 6,631 distinct `ma_chuyen_van_hanh` | REFRESH 1 hour; 6 carriers, 11 vehicle types, 5 pickups, 11 areas |
| `mv_filter_vendor` | 11 | n/a | 11 vendor codes | Static dim |
| `mv_filter_warehouse` | 6 | n/a | 6 whseid | Static dim |
| `mv_filter_region` | 34,408 | n/a | — | **Quá nhiều** — extract phải filter theo used codes |

**Server time at extract:** 2026-05-16 11:27:50 UTC
**CH version:** 25.12.1.1497
**Refresh status:** Không query được `system.view_refreshes` (Access Denied for user `helix`) — fallback: tin `REFRESH EVERY` config trong DDL.

---

## 2. Kết quả truy vấn

### 2.1 OTIF / Ontime / Infull by month (Feb-Apr 2026)

| Month | total_so | OTIF % | Ontime % | Infull % |
|---|---|---|---|---|
| 2026-02 | 9,881 | 82.57% | 92.86% | 91.43% |
| 2026-03 | 10,524 | 81.85% | 91.57% | 92.63% |
| 2026-04 | 10,802 | **77.36%** | 92.55% | **90.48%** |

→ **Pattern xác nhận**: OTIF drop ~5 điểm tháng 4. Ontime gần như flat. Infull dip nhẹ. Apr Not-OTIF n=2,446 trong đó Short-only 36.5%, Late-only 27.5%, both 3.5%, other (status combo có Unknown) 32.5%.

### 2.2 Top carriers by volume + OTIF (anonymized)

| Carrier | Volume | OTIF % | Notes |
|---|---|---|---|
| CAR002 | 15,324 | 86.99% | Top performer của high-volume |
| CAR001 | 8,781 | 75.24% | High volume + OTIF tệ → priority fix |
| CAR003 | 2,151 | 57.60% | Outlier nghiêm trọng |
| CAR004 | 1,594 | 86.57% | |
| CAR006 | 1,409 | 81.55% | |
| CAR005 | 1,388 | 76.59% | |
| CAR007 | 361 | 100.00% | Small sample, đáng kiểm tra |
| (empty) | 199 | 0.00% | DQ issue — carrier_code rỗng |

### 2.3 VFR by vehicle type

| Vehicle | n | avg VFR % |
|---|---|---|
| 1.4T | 440 | 95.13% |
| 2T | 2,151 | 90.57% |
| 3.5T | 346 | 86.90% |
| 5T | 1,703 | 80.89% |
| 11T | 1,375 | **74.83%** ← xe lớn dùng kém |

VFR distribution: avg 84%, P50 96%, P90 100%, max 100% (server-cap).

---

## 3. Sanity checks

| Check | Kết quả | Pass/Fail |
|---|---|---|
| Sum of months total = overall total (31,207) | 9,881 + 10,524 + 10,802 = 31,207 | ✅ |
| Cardinality preserved post-anonymize (top 8 carriers row-count match) | Match 100% | ✅ |
| Zero MDLZ identifiers in anonymized CSVs | grep returns 0 hit cho regex `mondelez|mdlz|oreo|cosy|afc|ritz|solite|kinh do|trung thu|tết|toblerone|cadbury|BKD|NKD|VN821|VN831|HDA|HVP|GHN|NINJAVAN|...` | ✅ |
| Zero `\N` markers post-anonymize | 0 | ✅ |
| `shipment_id` unique trong shipments.csv | 31,207 distinct / 31,207 rows | ✅ |
| VFR ∈ [0, 100] (server-cap, không có outlier) | 0 trips > 100% | ✅ |
| Date range khớp filter window | min/max eta_planned ∈ [2026-02-02, 2026-04-30] | ✅ |

---

## 4. Bug / Discrepancy phát hiện

### BUG-1 (LOW): `mv_filter_region` cardinality cực cao (34,408 rows)
- **Vị trí:** `analytics_workspace.mv_filter_region` (joined to `stm_dwh_mondelez.subdim_cat_area`)
- **Triệu chứng:** SELECT từ MV trả 34,408 rows nhưng `mv_otif` trong 3 tháng chỉ dùng 12 distinct areas.
- **Root cause (giả thuyết):** MV chứa toàn bộ master data area (province/district/ward) thay vì chỉ những area được dùng trong vận hành.
- **Impact business:** Nếu widget filter dropdown đọc trực tiếp MV này → user sẽ thấy 34k options → UX tệ.
- **Recommendation:** Wrap MV với UI filter sao cho chỉ hiển thị area thực sự được dùng (vd join với `mv_otif`/`mv_vfr_van_hanh` để filter). Hoặc tạo `mv_filter_region_used` riêng.

### BUG-2 (MEDIUM): 199 shipments có `ten_ngan_nha_van_tai = ''`
- **Vị trí:** `analytics_workspace.mv_otif` upstream chain
- **Triệu chứng:** 199 rows trong 3 tháng có carrier name rỗng, **100% có `infull_status = 'Failed Infull'` và `otif_status = 'Failed OTIF'`**.
- **Root cause (giả thuyết):** Có thể là đơn chưa được assign carrier (cancelled tender, hoặc DO không qua STM). Pattern OTIF=0% cho thấy có thể đây là "phantom orders" hoặc orders đã cancelled trước khi vận hành.
- **Impact business:** OTIF % toàn tenant bị kéo xuống do đếm các đơn này vào mẫu số. Nếu loại ra, OTIF có thể tăng ~0.5-1 điểm.
- **Recommendation:** PM/BA review với business team xem có nên loại các đơn `carrier=''` ra khỏi tính OTIF không (đề xuất loại — không có nghĩa tính OTIF cho đơn chưa giao).

### BUG-3 (LOW): `khu_vuc_doi_xe = ''` cho 25.3% shipments
- **Vị trí:** `mv_otif`
- **Triệu chứng:** 7,888/31,207 (25.3%) shipments có empty delivery area.
- **Root cause (giả thuyết):** Có thể là direct ship hoặc area chưa được master-classify. Cần check thêm với business.
- **Impact business:** Phân tích "OTIF theo khu vực" sẽ bias mạnh nếu loại các đơn này.
- **Recommendation:** Cross-check với DA team — đây có phải pattern bình thường hay là gap trong data classification?

> Các BUG này được **cố ý** giữ trong dataset assessment để test khả năng phát hiện DQ issue của ứng viên — không cần fix.

---

## 5. Query đã verify (ClickHouse SQL chuẩn)

### Query 1 — shipments extract

```sql
-- DA Assessment fact: OTIF shipments Feb-Apr 2026
SELECT
    ifNull(so, '')                                              AS shipment_id_raw,
    whseid                                                      AS warehouse_code_raw,
    khu_vuc_doi_xe                                              AS delivery_area_raw,
    ifNull(group_of_cago, 'Unclassified')                       AS cargo_group_raw,
    ten_ngan_nha_van_tai                                        AS carrier_code_raw,
    group_name                                                  AS sales_channel_raw,
    ifNull(loai_xe_van_hanh, '')                                AS vehicle_type_raw,
    toString(toDate(ngay_gi))                                   AS gi_date,
    toString(etd_chuyen_gui_thau)                               AS etd_planned,
    toString(eta_giao_hang_cho_npp)                             AS eta_planned,
    toString(actual_ship_date)                                  AS atd_actual,
    toString(ata_den)                                           AS ata_actual,
    ifNull(ontime_status, '')                                   AS ontime_status_raw,
    ifNull(infull_status, '')                                   AS infull_status_raw,
    otif_status                                                 AS otif_status_raw,
    toFloat64(ifNull(sum_original_cse, 0))                      AS planned_qty_cse,
    toFloat64(ifNull(sum_original_kg, 0))                       AS planned_weight_kg,
    toFloat64(ifNull(sum_original_cbm, 0))                      AS planned_volume_cbm,
    toFloat64(ifNull(sum_original_pl, 0))                       AS planned_pallets,
    toFloat64(ifNull(sum_san_luong_giao_cse, 0))                AS delivered_qty_cse
FROM analytics_workspace.mv_otif
WHERE toDate(eta_giao_hang_cho_npp) BETWEEN toDate('2026-02-01') AND toDate('2026-04-30')
ORDER BY eta_giao_hang_cho_npp, so
FORMAT CSVWithNames;
```

### Query 2 — trips extract

```sql
-- DA Assessment fact: VFR trips Feb-Apr 2026
SELECT
    ma_chuyen_van_hanh                                          AS trip_id_raw,
    toString(toDate(tender_date))                               AS tender_date,
    toString(eta_vh)                                            AS eta_operation,
    toString(ata_vh)                                            AS ata_operation,
    ifNull(diem_nhan, '')                                       AS pickup_location_raw,
    ifNull(khu_vuc_doi_xe, '')                                  AS delivery_area_raw,
    ifNull(nha_van_tai, '')                                     AS carrier_code_raw,
    loai_xe_van_hanh                                            AS vehicle_type_raw,
    nhom_hang_hoa                                               AS cargo_group_raw,
    toFloat64(vfr_max)                                          AS vfr_pct,
    toFloat64(vfr_theo_tan)                                     AS vfr_by_ton,
    toFloat64(vfr_theo_khoi)                                    AS vfr_by_volume,
    toFloat64(ifNull(tan_ke_hoach, 0))                          AS planned_ton,
    toFloat64(ifNull(cbm_ke_hoach, 0))                          AS planned_cbm
FROM analytics_workspace.mv_vfr_van_hanh
WHERE toDate(eta_vh) BETWEEN toDate('2026-02-01') AND toDate('2026-04-30')
ORDER BY eta_vh, ma_chuyen_van_hanh
FORMAT CSVWithNames;
```

(Queries 3-5: carriers, locations, products — xem file đầy đủ tại [`projects/assessments/da/dataset/_internal/extract.sql`](../../../assessments/da/dataset/_internal/extract.sql))

---

## 6. Caveats

- **MV refresh trễ:** `mv_otif` refresh 5 phút, `mv_vfr_van_hanh` refresh 1 giờ. Dataset là snapshot lúc 2026-05-16 ~11:30 UTC. Nếu re-run sau, số liệu có thể đổi nhẹ ở rìa window (orders giao trễ + status update).
- **Anonymization mapping cố định:** seed = 20260516. Re-run anonymize.py sau khi extract mới sẽ giữ mapping ổn định miễn là `mapping.csv` còn lưu. Nếu xoá mapping.csv, candidate mapping sẽ regenerate (cùng raw → cùng fake do seed cố định).
- **Cross-tenant không khả dụng:** Dataset chỉ Mondelez. Không generalize cho tenant khác.
- **Empty delivery_area / carrier_code:** Real data có DQ issue — KHÔNG fix, để cho candidate gặp và xử lý.
- **Brand không link xuống shipment:** Real data gap, không phải bug. Brand chỉ ở dim level qua SKU join — không denormalize.
- **VFR cap 100%:** Server-side cap (DDL: `least(..., 100)`). Dataset không có outlier > 100 — note này trong dataset/README.md.

---

## 7. Anonymization audit

Mapping mẫu (xem [`mapping.csv`](../../../assessments/da/dataset/_internal/mapping.csv) đầy đủ):

| Namespace | # mappings | Spot check |
|---|---|---|
| `shipment` | 31,207 | `8482410648` → `SH-2026-000001` |
| `trip` | 6,631 | `DI0184932` → `TR-2026-000001` |
| `carrier_code` | 8 (active) | `HDA` → `CAR001`, `ANH SON` → `CAR002`, `GHN` → `CAR007` |
| `warehouse_code` | 4 | `NKD` → `WH001`, `VN831` → `WH002`, `BKD1` → `WH004` |
| `pickup_location` | 4 | `Kho ngoài - BKD` → `Hub-01`, `Kho trong - NKD` → `Hub-04` |
| `brand` | 9 | `Oreo` → `Velvetta`, `Cosy` → `Cocoluxe`, `KD` → `Crispero`, `Solite` → `Sunbite` |

Mapping file (`_internal/mapping.csv`) **KHÔNG được share candidate** — chỉ dùng nội bộ để debug khi cần.

Leak verification (regex case-insensitive trên 5 CSVs anonymized): **0 hits**.

### Encoding & display fix

- Tất cả 5 CSV anonymized ghi với **UTF-8 BOM** (`utf-8-sig`) → Excel trên Windows tự detect và đọc đúng, không mojibake.
- 1 row trong `mv_vfr_van_hanh.nhom_hang_hoa` chứa VN text `"DRY, HÀNG HÓA, FRESH"` → cleaned thành `"DRY, FRESH"` (drop VN token, keep ASCII siblings) — apply selectively chỉ cho trips.cargo_group (denormalized passthrough field).
- Brand keywords MDLZ (Oreo, Cosy, AFC, RITZ, Solite, KD, Slide, Tết, Trung Thu, Toblerone) đều được đưa qua mapping store → fake names trong pool. Mapping ổn định seeded.
- Raw CSVs trong `_internal/raw/` giữ nguyên (không BOM, chứa VN text) — chỉ dùng nội bộ.

**Lưu ý implement**: `_clean_audience_text` chỉ apply cho fields PASSTHROUGH (vd `trips.cargo_group`) — KHÔNG apply cho fields đang là mapping-key (vd `pickup_location_raw = "Kho ngoài - BKD"`). Apply nhầm trên mapping key sẽ collapse các raw distinct thành "Other" → mất uniqueness của fake mapping (đã xảy ra ở r1 anonymize.py, đã fix).

---

## ARTIFACT_PATH: projects/mondelez/02-data/audit-results/s2-da-assessment-extract-20260516.md
## DATA_CONFIDENCE: High — cardinality preserved, leak check zero hits, math verified server-side vs Python locally
## MV_FRESHNESS: mv_otif refresh 5 min (data fresh as of 2026-05-16 11:30 UTC); mv_vfr_van_hanh refresh 1 hour
## NEXT_ACTION: PM share `projects/assessments/da/dataset/` (KHÔNG `_internal/`) + `test/assessment.md` cho ứng viên vòng đầu. Reviewer dùng `test/rubric.md` + `test/reference-findings.md` để chấm.
