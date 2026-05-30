# SPEC — Tender Response: SQL contract & data model

| Trường | Giá trị |
|--------|---------|
| **Version** | 1.0.0 |
| **Ngày** | 2026-05-30 |
| **Trạng thái** | Canonical — scorecard SQL đã verify trên `analytics_workspace`; chart SQL = đề xuất (chưa có trong sql-registry) |
| **PRD reference** | [tender-response-prd.md](tender-response-prd.md) |
| **MV** | `analytics_workspace.mv_dap_ung_gui_thau` ([DDL](../../02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql)) |
| **SQL registry** | [`02-data/data-sources/sql-registry.md`](../../02-data/data-sources/sql-registry.md) → `## Fulfillment Ratio (tỷ lệ đáp ứng)` |
| **Datasource Grafana** | ClickHouse UID `ffnl3fnifrcowc` (helixmonitoring.grafana.net) |

---

## 1. Data model — `mv_dap_ung_gui_thau`

Grain: **1 row = 1 cặp (chuyến vận hành × chuyến gửi thầu)** — `ORDER BY (ma_chuyen_van_hanh, id_chuyen_gui_thau)`. Refresh `EVERY 1 HOUR`.

| Nhóm cột | Cột chính | Ghi chú |
|---|---|---|
| Khoá | `id_chuyen_gui_thau` (Nullable Int32), `id_chuyen_van_hanh` (Nullable Int32), `ma_chuyen_van_hanh` (String) | tender ↔ operational |
| Kết quả | `dap_ung_gui_thau` (Bool) | precompute 1:1 — xem §2 |
| Đếm split/merge | `cnt_id_chuyen_van_hanh`, `cnt_id_chuyen_gui_thau` (UInt64) | window count per partition |
| Thời gian | `tender_date`, `etd_gt`, `eta_gt`, `etd_vh`, `atd_vh`, `eta_vh`, `ata_vh` (Nullable DateTime UTC) | filter `date_type` dùng `eta_vh`/`ata_vh`/`tender_date` |
| NVT | `ma_nha_van_tai`, `nha_van_tai`, `so_xe`, `tai_xe` | |
| Địa điểm | `ma_diem_nhan`, `diem_nhan`, `ma_diem_giao`, `diem_giao`, `ma_khu_vuc_doi_xe`, `khu_vuc_doi_xe` | khu vực null → `'UNKNOWN'` |
| Loại xe | `ma_loai_xe_gui_thau`, `loai_xe_gui_thau`, `ma_loai_xe_van_hanh`, `loai_xe_van_hanh` | |
| Khối lượng | `tan_ke_hoach/nhan/giao`, `cbm_ke_hoach/nhan/giao` (Nullable Float64) | bảng chi tiết |
| Khác | `trang_thai_chuyen`, `ma_don_hang`, `dich_vu_van_chuyen`, `nhom_hang_hoa`, `loai_boc_xep`, `loai_dia_diem` | |

### 1.1 Input conditions (đã build sẵn trong MV)
`trip_tender_id != -1` · `trip_header_id != -1` · `t.header_group_vehicle_sk != -1` · `tt.tender_group_vehicle_sk != -1` · `o.service_code = 'XB'` (Xuất bán) · `t.status_id > 98` (Đã hoàn thành). Nguồn: `stm_dwh_mondelez.dim_ops_trip_detail` + `dim_ops_trip` (×2: vận hành & tender) + `dim_ord_order`. → KHÔNG cần lặp lại các điều kiện này trong widget SQL.

---

## 2. Logic `dap_ung_gui_thau` (precomputed)

```sql
-- window count theo từng phía rồi suy ra cờ đáp ứng
count() OVER (PARTITION BY id_chuyen_van_hanh) AS cnt_id_chuyen_van_hanh,
count() OVER (PARTITION BY id_chuyen_gui_thau)  AS cnt_id_chuyen_gui_thau,
...
if((cnt_id_chuyen_van_hanh >= 2) OR (cnt_id_chuyen_gui_thau >= 2), false, true) AS dap_ung_gui_thau
```

`true` = 1:1 (đáp ứng) · `false` = gom (`cnt_id_chuyen_gui_thau ≥ 2`) hoặc tách (`cnt_id_chuyen_van_hanh ≥ 2`).

---

## 3. Section keys & SQL contract

Widget cần (tối thiểu) 2 query — tương ứng FormConfig `DSHTNDDTG01` (scorecard) và `DSHTNDDTG02` (detail/breakdown).

### 3.1 `scorecard` — ✅ canonical (verified)

**Mục đích**: cấp data cho 5 KPI card. **Shape**: 1 row, 5 cột.

```sql
SELECT
    countDistinct(id_chuyen_gui_thau) AS so_id_chuyen_gui_thau,
    countDistinct(if(dap_ung_gui_thau = true,  id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_dap_ung,
    countDistinct(if(dap_ung_gui_thau = false, id_chuyen_gui_thau, NULL)) AS so_id_chuyen_gui_thau_khong_dap_ung,
    countDistinct(id_chuyen_van_hanh) AS so_id_chuyen_van_hanh,
    round(
        countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL)) * 100.0
        / nullIf(countDistinct(id_chuyen_gui_thau), 0),
    2) AS ty_le_dap_ung_pct
FROM analytics_workspace.mv_dap_ung_gui_thau
WHERE 1 = 1
  -- Warehouse
  AND if(arraySort([{{whseid}}]) = (SELECT arraySort(groupUniqArray(ma_su_dung)) FROM analytics_workspace.mv_masterdata_kho_stm),
         1 = 1, ma_diem_nhan IN ({{whseid}}))
  -- Area
  AND if(arraySort([{{area}}]) = (SELECT arraySort(groupArray(DISTINCT group_area_code)) FROM analytics_workspace.mv_filter_region),
         1 = 1, khu_vuc_doi_xe IN ({{area}}))
  -- Transporter
  AND if(arraySort([{{transporter}}]) = (SELECT arraySort(groupArray(DISTINCT vendor_code)) FROM analytics_workspace.mv_filter_vendor),
         1 = 1, nha_van_tai IN ({{transporter}}))
  -- Date
  AND (toDate(CASE
        WHEN {{date_type}} = 'ETA'           THEN eta_vh
        WHEN {{date_type}} = 'ATA'           THEN ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu' THEN tender_date
      END)
      BETWEEN toDate(coalesce({{from_date}}, '1900-01-01'))
          AND toDate(coalesce({{to_date}},   '2999-12-31')));
```

> Nguồn: [sql-registry.md §Fulfillment Ratio → "Tỷ lệ đáp ứng"](../../02-data/data-sources/sql-registry.md) (đã verify trên `analytics_workspace`).
> Filter dùng pattern `if(arraySort([...]) = MV_list, 1=1, col IN (...))`: chỉ work khi FE gửi CSV của toàn bộ code lúc "ALL". Nếu FE gửi `''` khi ALL → cần đổi sang `[[...]]` optional block (xem note tương tự trong [late-order-alert-spec.md §1.1](../late-order-alert/late-order-alert-spec.md)). **Cần verify cách FE/Grafana truyền biến ALL.**

### 3.2 `byVendor` — ⚠️ đề xuất (chưa có trong registry)

```sql
SELECT
    nha_van_tai,
    countDistinct(if(dap_ung_gui_thau = true,  id_chuyen_gui_thau, NULL)) AS so_dap_ung,
    countDistinct(if(dap_ung_gui_thau = false, id_chuyen_gui_thau, NULL)) AS so_khong_dap_ung,
    round(countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL)) * 100.0
          / nullIf(countDistinct(id_chuyen_gui_thau), 0), 2) AS ty_le_dap_ung_pct
FROM analytics_workspace.mv_dap_ung_gui_thau
WHERE 1 = 1 /* + cùng bộ filter §3.1 */
GROUP BY nha_van_tai
ORDER BY ty_le_dap_ung_pct ASC;
```

### 3.3 `byTime` — ⚠️ đề xuất (time series cho Grafana)

```sql
SELECT
    toStartOfDay(CASE
        WHEN {{date_type}} = 'ETA'           THEN eta_vh
        WHEN {{date_type}} = 'ATA'           THEN ata_vh
        WHEN {{date_type}} = 'Ngày gửi thầu' THEN tender_date
    END) AS period,
    countDistinct(if(dap_ung_gui_thau = true,  id_chuyen_gui_thau, NULL)) AS so_dap_ung,
    countDistinct(if(dap_ung_gui_thau = false, id_chuyen_gui_thau, NULL)) AS so_khong_dap_ung,
    round(countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL)) * 100.0
          / nullIf(countDistinct(id_chuyen_gui_thau), 0), 2) AS ty_le_dap_ung_pct
FROM analytics_workspace.mv_dap_ung_gui_thau
WHERE 1 = 1 /* + cùng bộ filter §3.1 */
GROUP BY period
ORDER BY period;
```

> Grafana time series: dùng macro `$__timeFilter(...)` thay block date thủ công nếu panel chạy native Grafana (xem skill `/da-grafana`). Bucket ngày/tuần/tháng = `toStartOfDay/Week/Month`.

---

## 4. Bảng chi tiết (`detail`) — cột hiển thị

| Cột UI | Cột MV | Ghi chú |
|---|---|---|
| Mã chuyến vận hành | `ma_chuyen_van_hanh` | group key |
| ID chuyến gửi thầu | `id_chuyen_gui_thau` | |
| Nhà vận tải | `nha_van_tai` | |
| Kho lấy hàng | `diem_nhan` / `ma_diem_nhan` | |
| Khu vực giao hàng | `khu_vuc_doi_xe` | null → `UNKNOWN` |
| Ngày gửi thầu / ETA / ATA | `tender_date` / `eta_vh` / `ata_vh` | |
| Trạng thái chuyến | `trang_thai_chuyen` | |
| Loại đáp ứng | `dap_ung_gui_thau` | `true`→Được đáp ứng / `false`→Không |
| Lý do không đáp ứng | derived | `cnt_id_chuyen_gui_thau ≥ 2`→Gom · `cnt_id_chuyen_van_hanh ≥ 2`→Tách |
| Số tender / chuyến vận hành | `cnt_id_chuyen_gui_thau` | phát hiện gom |
| Số chuyến vận hành / tender | `cnt_id_chuyen_van_hanh` | phát hiện tách |

---

## 5. Quy ước số liệu

- **Divide-by-zero**: `nullIf(countDistinct(id_chuyen_gui_thau), 0)` → UI map `NULL → 0%`.
- **Distinct count**: luôn `countDistinct(id_chuyen_gui_thau)` / `countDistinct(id_chuyen_van_hanh)` — KHÔNG dùng `count()` thô (grain MV là cặp, có thể trùng).
- **Snake_case → camelCase**: ClickHouse trả `snake_case`; UI nhận `camelCase` (xem mapping ở [otif/spec.md](../otif/spec.md)).
- **Timezone**: cột DateTime ở UTC; quy ước hiển thị UTC+7 theo convention tenant.

---

## 6. Chưa verify / cần làm tiếp

- [ ] Trace widget frontend `WidgetTenderResponse` (repo chưa có local) → nâng trạng thái lên Observed.
- [ ] Verify cách Grafana/FE truyền biến "ALL" → chọn pattern `if(arraySort)` vs `[[...]]`.
- [ ] Verify `byVendor` / `byTime` SQL trên `analytics_workspace` (hiện chỉ verify scorecard).
- [ ] Chốt `% Commit Response` (MV `mv_dap_ung_van_hanh`) — xem PRD §8 Q1.
- [ ] Xác nhận ngưỡng `status_id > 98` = "Đã hoàn thành".
