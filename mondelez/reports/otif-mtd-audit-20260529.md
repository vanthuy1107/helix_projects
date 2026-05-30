# Audit OTIF MTD — mv_otif — mondelez

**Window** `2026-05-01` → `2026-05-29` (inclusive) · trục `thoi_gian_gui_thau` (Ngày gửi thầu) · SO filter: `ALL`

- Freshness `thoi_gian_gui_thau`: max_date `2026-05-29 00:00:00`, min_date `2024-05-25 00:00:00`, lag ~340′ vs now (MV refresh 5′ → lag lớn = chưa cập nhật).

## 1 · Summary sức khỏe — scale + distinct theo dim (trong window)

_rows_minus_so > 0 = SO split sang nhiều kho · rows_khong_co_stm = loại khỏi mẫu số % KPI._

| metric             |   value |
|:-------------------|--------:|
| rows_window        |   22188 |
| distinct_so        |   22188 |
| rows_minus_so      |       0 |
| distinct_so_whseid |   22188 |
| distinct_whseid    |       3 |
| distinct_customer  |    1927 |
| distinct_cargo     |       4 |
| distinct_kenh      |       4 |
| distinct_khu_vuc   |      12 |
| distinct_nvt       |       9 |
| rows_khong_co_stm  |       0 |
| rows_co_stm        |   22188 |

## 2 · KPI canonical OTIF / Ontime / Infull (đã loại 'Không có dữ liệu STM' ở mẫu số)

| KPI | Số đơn | % | Target | RAG |
|---|---:|---:|---:|:--:|
| **% OTIF**   | 20,357   | **91.75%**   | 90% | 🟢 |
| **% Ontime** | 20,564 | **92.68%** | 95% | 🟡 |
| **% Infull** | 21,954 | **98.95%** | 97% | 🟢 |

Tổng đơn (uniqExact SO, đã loại STM-missing): **22,188**

## 3 · Phân bố theo dim nghiệp vụ (pct_otif = %OTIF nhóm, loại STM ở mẫu số)

**Kho (whseid)** (`whseid`)

| bucket   |   rows |   pct |   otif_so |   pct_otif |
|:---------|-------:|------:|----------:|-----------:|
| NKD      |  11946 | 53.84 |     11523 |      96.46 |
| BKD1     |   9990 | 45.02 |      8605 |      86.14 |
| VN831    |    252 |  1.14 |       229 |      90.87 |

**Khu vực đội xe** (`khu_vuc_doi_xe`)

| bucket                  |   rows |   pct |   otif_so |   pct_otif |
|:------------------------|-------:|------:|----------:|-----------:|
| (rỗng)                  |  13651 | 61.52 |     12770 |      93.55 |
| Ho Chi Minh             |   1317 |  5.94 |      1143 |      86.79 |
| Ha Noi                  |   1306 |  5.89 |      1204 |      92.19 |
| North East - North West |   1303 |  5.87 |      1153 |      88.49 |
| South East              |   1224 |  5.52 |      1101 |      89.95 |
| North Central Coast     |    985 |  4.44 |       814 |      82.64 |
| Mekong 2                |    596 |  2.69 |       569 |      95.47 |
| Central                 |    523 |  2.36 |       485 |      92.73 |
| Mekong 1                |    493 |  2.22 |       436 |      88.44 |
| South Central Coast     |    365 |  1.65 |       326 |      89.32 |
| Central highland        |    250 |  1.13 |       196 |      78.4  |
| South East - Lam Dong   |    175 |  0.79 |       160 |      91.43 |

**Kênh bán hàng** (`group_name`)

| bucket   |   rows |   pct |   otif_so |   pct_otif |
|:---------|-------:|------:|----------:|-----------:|
| MT       |  16411 | 73.96 |     15291 |      93.18 |
| GT       |   5467 | 24.64 |      4809 |      87.96 |
| KA       |    309 |  1.39 |       256 |      82.85 |
| B2B      |      1 |  0    |         1 |     100    |

**Nhà vận tải** (`ten_ngan_nha_van_tai`)

| bucket      |   rows |   pct |   otif_so |   pct_otif |
|:------------|-------:|------:|----------:|-----------:|
| HDA         |  10352 | 46.66 |     10066 |      97.24 |
| ANH SON     |   6018 | 27.12 |      5257 |      87.35 |
| HOA PHAT    |   2359 | 10.63 |      1857 |      78.72 |
| GHN         |   1072 |  4.83 |      1072 |     100    |
| TLL         |    770 |  3.47 |       611 |      79.35 |
| NGUYEN PHAT |    597 |  2.69 |       570 |      95.48 |
| HVP         |    523 |  2.36 |       485 |      92.73 |
| THANH AN    |    493 |  2.22 |       436 |      88.44 |
| (rỗng)      |      4 |  0.02 |         3 |      75    |

**Loại hàng (Group of Cargo)** (`group_of_cago`)

| bucket      |   rows |   pct |   otif_so |   pct_otif |
|:------------|-------:|------:|----------:|-----------:|
| DRY         |  18245 | 82.23 |     17126 |      93.87 |
| FRESH       |   3324 | 14.98 |      2644 |      79.54 |
| POSM/OFFBOM |    613 |  2.76 |       581 |      94.78 |
| (NULL)      |      6 |  0.03 |         6 |     100    |

**Loại xe gửi thầu** (`loai_xe_gui_thau`)

| bucket   |   rows |   pct |   otif_so |   pct_otif |
|:---------|-------:|------:|----------:|-----------:|
| 2T       |   5266 | 23.73 |      4566 |      86.71 |
| 3.5T     |   3674 | 16.56 |      3536 |      96.24 |
| (rỗng)   |   3672 | 16.55 |      3208 |      87.36 |
| 5T       |   2673 | 12.05 |      2526 |      94.5  |
| 2.5T     |   2398 | 10.81 |      2266 |      94.5  |
| 8T       |   2266 | 10.21 |      2159 |      95.28 |
| 1.4T     |   1742 |  7.85 |      1675 |      96.15 |
| 11T      |    497 |  2.24 |       421 |      84.71 |

## 4 · Volume tổng (kỳ vọng monotonic Plan ≥ Shipped ≥ Delivered mỗi UOM)

| metric        |           value |
|:--------------|----------------:|
| plan_cse      |     1.17416e+06 |
| shipped_cse   |     1.17762e+06 |
| delivered_cse |     1.17057e+06 |
| plan_kg       |     4.34482e+06 |
| shipped_kg    |     4.35612e+06 |
| delivered_kg  |     4.33131e+06 |
| plan_cbm      | 41430.4         |
| shipped_cbm   | 41496.1         |
| delivered_cbm | 39581.8         |

## 5 · Trend theo ngày (`thoi_gian_gui_thau`)

_total_so = count(so) cắt ngày UTC (khớp widget trend) · dup > 0 = SO lặp trong ngày._

| ngay                |   total_so |   so_unique |   dup |   rows_nostm |   otif_so |   pct_otif |   pct_ontime |   pct_infull |   plan_cse |
|:--------------------|-----------:|------------:|------:|-------------:|----------:|-----------:|-------------:|-------------:|-----------:|
| 2026-05-01 00:00:00 |       1416 |        1416 |     0 |            0 |      1413 |      99.79 |        99.93 |        99.86 |    6961.96 |
| 2026-05-02 00:00:00 |        288 |         288 |     0 |            0 |       253 |      87.85 |        92.71 |        94.44 |   35540.1  |
| 2026-05-03 00:00:00 |       1020 |        1020 |     0 |            0 |       973 |      95.39 |        96.27 |        98.92 |   21971.5  |
| 2026-05-04 00:00:00 |        745 |         745 |     0 |            0 |       475 |      63.76 |        66.58 |        97.05 |   61421.8  |
| 2026-05-05 00:00:00 |       2367 |        2367 |     0 |            0 |      2253 |      95.18 |        97.25 |        97.63 |   71656.4  |
| 2026-05-06 00:00:00 |        852 |         852 |     0 |            0 |       796 |      93.43 |        95.66 |        97.77 |   62227.6  |
| 2026-05-07 00:00:00 |        645 |         645 |     0 |            0 |       563 |      87.29 |        91.32 |        95.35 |   60112.1  |
| 2026-05-08 00:00:00 |        221 |         221 |     0 |            0 |       207 |      93.67 |        96.83 |        96.83 |   29954.3  |
| 2026-05-09 00:00:00 |        353 |         353 |     0 |            0 |       284 |      80.45 |        89.24 |        89.8  |   31710    |
| 2026-05-10 00:00:00 |        697 |         697 |     0 |            0 |       674 |      96.7  |        96.7  |        99.86 |   19496.7  |
| 2026-05-11 00:00:00 |       1009 |        1009 |     0 |            0 |       903 |      89.49 |        89.59 |        99.9  |   31584.7  |
| 2026-05-12 00:00:00 |        566 |         566 |     0 |            0 |       512 |      90.46 |        90.46 |       100    |   73422.2  |
| 2026-05-13 00:00:00 |        355 |         355 |     0 |            0 |       312 |      87.89 |        88.73 |        98.87 |   50621.6  |
| 2026-05-14 00:00:00 |       1343 |        1343 |     0 |            0 |      1271 |      94.64 |        94.86 |        99.78 |   60520.8  |
| 2026-05-15 00:00:00 |       1095 |        1095 |     0 |            0 |      1081 |      98.72 |        98.81 |        99.91 |   32399.2  |
| 2026-05-16 00:00:00 |        237 |         237 |     0 |            0 |       222 |      93.67 |        94.09 |        99.16 |   27093.8  |
| 2026-05-17 00:00:00 |       1105 |        1105 |     0 |            0 |      1090 |      98.64 |        98.64 |       100    |   20206.5  |
| 2026-05-18 00:00:00 |        268 |         268 |     0 |            0 |       243 |      90.67 |        91.42 |        99.25 |   35041.1  |
| 2026-05-19 00:00:00 |       1920 |        1920 |     0 |            0 |      1835 |      95.57 |        95.68 |        99.9  |   60475.3  |
| 2026-05-20 00:00:00 |       1370 |        1370 |     0 |            0 |      1332 |      97.23 |        97.37 |        99.85 |   44274.1  |
| 2026-05-21 00:00:00 |       1235 |        1235 |     0 |            0 |      1199 |      97.09 |        97.09 |       100    |   53944.9  |
| 2026-05-22 00:00:00 |        238 |         238 |     0 |            0 |       213 |      89.5  |        90.34 |        99.16 |   31680.6  |
| 2026-05-23 00:00:00 |        475 |         475 |     0 |            0 |       451 |      94.95 |        95.16 |        99.79 |   29524.5  |
| 2026-05-24 00:00:00 |        209 |         209 |     0 |            0 |       184 |      88.04 |        88.52 |        99.52 |   19666    |
| 2026-05-25 00:00:00 |        338 |         338 |     0 |            0 |       312 |      92.31 |        92.6  |        99.7  |   41551.2  |
| 2026-05-26 00:00:00 |       1159 |        1159 |     0 |            0 |       688 |      59.36 |        59.45 |        99.91 |   63328.5  |
| 2026-05-27 00:00:00 |        265 |         265 |     0 |            0 |       248 |      93.58 |        93.96 |        99.62 |   44478    |
| 2026-05-28 00:00:00 |        396 |         396 |     0 |            0 |       369 |      93.18 |        94.95 |        97.47 |   52918.5  |
| 2026-05-29 00:00:00 |          1 |           1 |     0 |            0 |         1 |     100    |       100    |       100    |     380    |

## 6 · Anomaly — 5 nhóm (đếm kỳ vọng = 0 trừ các mục info)

**6A · NULL / empty cột then chốt** (so_null, whseid_empty kỳ vọng = 0)

| check                   |   count |
|:------------------------|--------:|
| rows_window             |   22188 |
| so_null                 |       0 |
| whseid_empty            |       0 |
| otif_status_empty       |       0 |
| ontime_status_null      |       0 |
| infull_status_null      |       0 |
| thoi_gian_gui_thau_null |       0 |
| eta_null                |       0 |
| ata_den_null            |       0 |
| customer_code_null      |       0 |
| cargo_null              |       6 |
| original_cse_zero       |       0 |

**6B · Volume integrity** (neg_*, overdeliver kỳ vọng = 0 · overship → Failed Infull, info)

| check             |   count |
|:------------------|--------:|
| rows_window       |   22188 |
| neg_plan_cse      |       0 |
| neg_shipped_cse   |       0 |
| neg_delivered_cse |       0 |
| overship_cse      |     243 |
| overdeliver_cse   |     385 |
| cse_pos_qty_zero  |       0 |

**6C · Business-rule cross-field** (otif_but_not_ontime/infull kỳ vọng = 0)

| check                |   count |
|:---------------------|--------:|
| rows_window          |   22188 |
| failontime_no_reason |       0 |
| failinfull_no_reason |       2 |
| ontime_but_ata_null  |       0 |
| otif_but_not_ontime  |       0 |
| otif_but_not_infull  |       0 |
| nostm_but_has_ata    |       0 |
| grace_gap            |       0 |
| tender_future        |       0 |
| tender_too_old       |       0 |

**6D · Duplicate (so, whseid)** (dup kỳ vọng = 0 · multi = SO trải > 1 kho, info)

| check                  |   count | rule   |
|:-----------------------|--------:|:-------|
| Duplicate (so, whseid) |       0 | = 0    |
| SO trải > 1 whseid     |       0 | info   |

**6E · Timestamp ordering** (mọi cặp mốc nghịch thứ tự kỳ vọng = 0)

| check                   |   count |
|:------------------------|--------:|
| rows_window             |   22188 |
| tender_after_etd        |     201 |
| etd_after_eta           |       0 |
| incong_after_outcong    |       0 |
| indock_after_outdock    |       0 |
| atadel_after_ataleave   |      47 |
| ship_after_arrival      |     100 |
| leavegate_after_arrival |      26 |
| create_after_gi         |     138 |
