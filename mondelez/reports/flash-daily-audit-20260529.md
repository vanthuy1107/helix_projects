# Flash Daily — Audit chất lượng MTD — mondelez

**Window** `2026-05-01` → `2026-05-29` · trục `Ngày GI` (`delivery_date_1`) · volume theo `original_cse`

- MV chính `mv_flash_and_drop_report` freshness: max_date `2026-08-01 00:00:00`, trễ ~-91771′ · 105,072 row trong window

- ⚠ **13242 vi phạm cứng** (integrity 8747 · business 565 · timestamp 3930 · duplicate 0 · parity_diff 0) — cần drill bằng notebook gốc (L9/L10).

## 1 · Summary

**A · Tổng row mỗi MV gốc (không lọc window)**

| source_mv                |    rows |
|:-------------------------|--------:|
| mv_flash_and_drop_report | 6340952 |
| mv_flash_report          | 6298052 |
| mv_dropped_report        |   42900 |

**B · Distinct count trong window MTD**

| metric               |   value |
|:---------------------|--------:|
| rows_mtd             |  105072 |
| distinct_so          |   16255 |
| distinct_whseid      |       2 |
| distinct_customer    |    1012 |
| distinct_brand       |      10 |
| distinct_cargo_group |       3 |
| distinct_kenh        |       3 |
| distinct_khu_vuc     |      12 |
| distinct_e2e_label   |       5 |
| distinct_status      |       3 |
| distinct_order_type  |       1 |

**C · Freshness — max timestamp + lag vs now() (UTC+7)**

| metric               | value                     |
|:---------------------|:--------------------------|
| max_date_col         | 2026-08-01 14:00:00+07:00 |
| min_date_col         | 2021-08-03 07:00:00+07:00 |
| max_ngay_tao_don     | 2026-05-30 00:31:08+07:00 |
| max_actual_ship      | 2026-05-29 19:59:13+07:00 |
| max_ata_den          | 2026-05-29 22:58:42+07:00 |
| server_now           | 2026-05-29 20:29:38+07:00 |
| lag_min_ngay_tao_don | -242                      |
| lag_min_actual_ship  | 30                        |

## 2 · Phân bố

**A · Phân bố theo `e2e_label` (volume theo `original_cse`)**

| e2e_label       |   rows |   pct_rows |      volume_uom |
|:----------------|-------:|-----------:|----------------:|
| Đã vận chuyển   | 100297 |      95.46 |     1.01703e+06 |
| Đã xuất kho     |   3701 |       3.52 |  8545.67        |
| Đang vận chuyển |    638 |       0.61 | 11588           |
| Kế hoạch hủy    |    420 |       0.4  |  3343.17        |
| Chưa xuất kho   |     16 |       0.02 |    99           |

**B · Phân bố theo `status (enum TMS raw)` — top 30**

| value         |   rows |     volume_uom |
|:--------------|-------:|---------------:|
| ShipCompleted | 104636 |    1.03717e+06 |
| Cancel        |    420 | 3343.17        |
| New           |     16 |   99           |

**B · Phân bố theo `type (order type)` — top 30**

|   value |   rows |   volume_uom |
|--------:|-------:|-------------:|
|     240 | 105072 |  1.04061e+06 |

**B · Phân bố theo `whseid (kho)` — top 30**

| value   |   rows |   volume_uom |
|:--------|-------:|-------------:|
| BKD1    |  68709 |       664156 |
| NKD     |  36363 |       376451 |

**B · Phân bố theo `brand` — top 30**

| value   |   rows |   volume_uom |
|:--------|-------:|-------------:|
| KD      |  43519 |    289036    |
| Oreo    |  19085 |    298693    |
| Slide   |  14122 |    105201    |
| Cosy    |  12081 |    176744    |
| Solite  |   7089 |    111564    |
| AFC     |   6334 |     42295    |
| Lu      |   1175 |      3794    |
| RITZ    |   1021 |      8152    |
| Other   |    643 |      5113.49 |
| (NULL)  |      3 |        15    |

**B · Phân bố theo `group_name (kênh)` — top 30**

| value   |   rows |   volume_uom |
|:--------|-------:|-------------:|
| GT      |  59766 |     671433   |
| MT      |  43249 |     304641   |
| KA      |   2057 |      64534.1 |

**B · Phân bố theo `khu_vuc_doi_xe (khu vực)` — top 30**

| value                   |   rows |   volume_uom |
|:------------------------|-------:|-------------:|
| (NULL)                  |  20060 |      88065.7 |
| North East - North West |  15537 |     154448   |
| South East              |  12665 |     145551   |
| Ho Chi Minh             |  11247 |     162967   |
| Ha Noi                  |   9723 |     109620   |
| North Central Coast     |   9093 |      94126.7 |
| Mekong 2                |   6344 |      56073.6 |
| Central                 |   5870 |      67597.1 |
| Mekong 1                |   5331 |      61957.4 |
| South Central Coast     |   4173 |      38525.7 |
| Central highland        |   2938 |      38939.7 |
| South East - Lam Dong   |   2091 |      22735.3 |

## 3 · Volume

**Tổng volume MTD theo Plan/Shipped/Delivered × CSE/KG/CBM/PL**

| metric        |           value |
|:--------------|----------------:|
| plan_cse      |     1.04061e+06 |
| shipped_cse   |     1.04153e+06 |
| delivered_cse |     1.09579e+06 |
| plan_kg       |     3.87893e+06 |
| shipped_kg    |     3.87931e+06 |
| delivered_kg  |     4.06898e+06 |
| plan_cbm      | 38196.9         |
| shipped_cbm   | 38118.7         |
| delivered_cbm | 39731.8         |
| plan_pl       | 25314.2         |
| shipped_pl    | 25264.7         |
| delivered_pl  | 26414.4         |

**Daily volume trong window — quan sát ngày sụt/tăng đột biến**

| day                 |   rows |   plan_cse |   shipped_cse |   delivered_cse |   pct_done |
|:--------------------|-------:|-----------:|--------------:|----------------:|-----------:|
| 2026-05-01 00:00:00 |     24 |      89    |         89    |           89    |     100    |
| 2026-05-02 00:00:00 |   2218 |    8706.08 |       8802.08 |         8451.08 |      97.07 |
| 2026-05-04 00:00:00 |   4600 |   50322.8  |      50376.8  |        54688.5  |     108.68 |
| 2026-05-05 00:00:00 |   4526 |   47816.4  |      46960.4  |        54325.2  |     113.61 |
| 2026-05-06 00:00:00 |   8475 |   67791.1  |      69336.5  |        89340.6  |     131.79 |
| 2026-05-07 00:00:00 |   3184 |   45343.7  |      45301.4  |        44916.4  |      99.06 |
| 2026-05-08 00:00:00 |   4703 |   56602.8  |      56239.5  |        55155.5  |      97.44 |
| 2026-05-09 00:00:00 |   1787 |   26593.3  |      26576.3  |        26030.3  |      97.88 |
| 2026-05-11 00:00:00 |   5177 |   45558.3  |      45641.3  |        54683.3  |     120.03 |
| 2026-05-12 00:00:00 |   2920 |   29400.7  |      29400.7  |        29808.7  |     101.39 |
| 2026-05-13 00:00:00 |   5393 |   66409.2  |      67076.2  |        68677.2  |     103.42 |
| 2026-05-14 00:00:00 |   3978 |   43207.5  |      43402.5  |        43569.5  |     100.84 |
| 2026-05-15 00:00:00 |   7281 |   57260.3  |      57335.3  |        57650.3  |     100.68 |
| 2026-05-16 00:00:00 |   4051 |   25482.9  |      25423.9  |        25624.5  |     100.56 |
| 2026-05-17 00:00:00 |      4 |      18    |         18    |           18    |     100    |
| 2026-05-18 00:00:00 |   4665 |   41233.3  |      41291.3  |        41423.3  |     100.46 |
| 2026-05-19 00:00:00 |   2642 |   29708.1  |      29677.1  |        29677.1  |      99.9  |
| 2026-05-20 00:00:00 |   6936 |   54399.5  |      54363.5  |        55024.5  |     101.15 |
| 2026-05-21 00:00:00 |   3554 |   36678.9  |      36617.9  |        37472.9  |     102.16 |
| 2026-05-22 00:00:00 |   4435 |   44651.9  |      44645.9  |        46528.9  |     104.2  |
| 2026-05-23 00:00:00 |   2329 |   29983.6  |      29810.6  |        29901.6  |      99.73 |
| 2026-05-24 00:00:00 |      2 |      53    |         53    |           53    |     100    |
| 2026-05-25 00:00:00 |   5481 |   47192.5  |      47025.5  |        47585.5  |     100.83 |
| 2026-05-26 00:00:00 |   2956 |   34741.2  |      34754.2  |        41739.2  |     120.14 |
| 2026-05-27 00:00:00 |   6314 |   57912.2  |      57974.2  |        58310.2  |     100.69 |
| 2026-05-28 00:00:00 |   3130 |   38879    |      38871    |        39159    |     100.72 |
| 2026-05-29 00:00:00 |   4307 |   54572.5  |      54466.5  |        55887.5  |     102.41 |

## 4 · Anomaly

**Nhóm 1 · NULL / empty trên cột critical (window có 105,072 row)**

| metric                      |   count |    pct |
|:----------------------------|--------:|-------:|
| so_null_or_empty            |       0 |  0     |
| whseid_null_or_empty        |       0 |  0     |
| customer_code_null_or_empty |       0 |  0     |
| customer_name_null_or_empty |       0 |  0     |
| brand_null_or_empty         |       3 |  0.003 |
| cargo_group_null_or_empty   |       0 |  0     |
| kenh_null_or_empty          |       0 |  0     |
| khu_vuc_null_or_empty       |   20060 | 19.092 |
| delivery_date_null          |       0 |  0     |
| ngay_tao_don_null           |       0 |  0     |
| original_cse_zero_or_null   |       0 |  0     |
| e2e_label_null_or_empty     |       0 |  0     |
| status_null_or_empty        |       0 |  0     |
| order_type_null_or_empty    |       0 |  0     |

**Nhóm 2 · Volume integrity violations (kỳ vọng = 0 mọi dòng)**

| metric                      |   violations |
|:----------------------------|-------------:|
| neg_original_cse            |            0 |
| neg_shipped_cse             |            0 |
| neg_delivered_cse           |            0 |
| neg_original_qty            |            0 |
| shipped_gt_plan             |          688 |
| delivered_gt_shipped        |         4040 |
| qty0_but_cse_positive       |            0 |
| cse_positive_but_pl_null    |            0 |
| delivered_volume_but_no_ata |         4019 |

**Nhóm 3 · Business rule violations (kỳ vọng = 0; info ở dòng STM lag/tương lai)**

| metric                         |   violations |   pct_window |
|:-------------------------------|-------------:|-------------:|
| cancel_but_delivered           |            0 |        0     |
| delivered_label_but_no_ata     |            0 |        0     |
| shipping_label_but_no_atd      |            0 |        0     |
| shipped_label_but_has_full_stm |            0 |        0     |
| ata_set_but_still_shipping     |          332 |        0.316 |
| delivery_date_in_future        |            0 |        0     |
| outlier_delivery_date          |            0 |        0     |
| drop_no_reason                 |          233 |        0.222 |

**Nhóm 4 · Duplicate `(so, orderlinenumber)` (kỳ vọng = 0)**

|   dup_key_pairs |   dup_row_total |
|----------------:|----------------:|
|               0 |               0 |

**Nhóm 4 · Cross-MV parity — `combined = flash + dropped` (UNION ALL)**

| metric                                   |   rows |
|:-----------------------------------------|-------:|
| rows_combined (mv_flash_and_drop_report) | 105072 |
| rows_flash (mv_flash_report)             | 104652 |
| rows_dropped (mv_dropped_report)         |    420 |
| flash_plus_dropped                       | 105072 |
| parity_diff (flash+dropped − combined)   |      0 |

**Nhóm 5 · Timestamp ordering violations (kỳ vọng = 0 mọi dòng)**

| metric                |   violations |   pct_window |
|:----------------------|-------------:|-------------:|
| create_after_delivery |          770 |        0.733 |
| bid_after_etd         |          386 |        0.367 |
| etd_after_eta         |            0 |        0     |
| atd_after_ata         |            1 |        0.001 |
| ata_before_etd        |          408 |        0.388 |
| asd_far_after_atd     |         1784 |        1.698 |
| ra_dock_after_di      |          581 |        0.553 |
