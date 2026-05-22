# PRD — OTIF View

> **Status:** 🟡 Draft v1 (cần stakeholder confirm các điểm `[TBD]`)
> **Owner:** [TBD] — Q1 trả lời "logistics manager + warehouse supervisor" là target users, chưa có owner đề xuất
> **Last updated:** 2026-05-07
> **Reference docs:**
> - Spec: `docs/02-features/otif/otif.spec.md`
> - Wireframe: `docs/02-features/otif/otif.wireframe.md`
> - GLOSSARY: `docs/GLOSSARY.md` § "On-Time In-Full"
> - Audit results: `docs/audit-results/s1-otif-20260507.md`, `docs/audit-results/s2-otif-20260507.md`
> - Figma: snapshot 2026-05-07 (6 ảnh — Tab Biểu đồ + Tab Chi tiết bảng)

---

## 1. Overview

OTIF View là màn hình giám sát realtime hiệu suất giao hàng của Mondelez Vietnam — đo bằng 2 tiêu chí cốt lõi:

- **On-Time**: đơn hàng (DO) đến điểm giao đúng hạn so với ETA gửi thầu
- **In-Full**: số lượng giao đủ (CSE kế hoạch = CSE xuất kho = CSE giao khách)
- **OTIF**: đạt cả 2 tiêu chí trên

Feature thuộc module **Control Tower → Order Monitor** trong hệ thống W-PRED, sử dụng dữ liệu pre-computed từ ClickHouse MV `analytics_workspace.mv_otif` (refresh 5 phút). UI trình bày 4 KPI cards, 5 biểu đồ phân tích (theo khu vực / kênh bán hàng / nhà vận tải / kho / thời gian), 2 chart phân loại lý do fail, và 3 bảng chi tiết.

---

## 2. Problem Statement

### 2.1 Pain points hiện tại

1. **Thiếu visibility realtime** về tỷ lệ giao đúng/đủ trong vận hành kho thành phẩm Dry & Fresh.
2. Khi có đơn fail, **không xác định được nhanh nguyên nhân** thuộc về kho (gọi xe trễ, xuất kho trễ) hay vận tải (xe đến trễ, không đủ tải).
3. **Không có công cụ pivot** để so sánh hiệu suất giữa các nhà vận tải, khu vực, kho, kênh bán hàng cho mục đích benchmark và đàm phán SLA.
4. Quy trình tổng hợp KPI tuần/tháng đang làm thủ công trên Excel — tốn 2–4h/tuần cho ops team.

### 2.2 Why now

- Mondelez đang siết SLA giao hàng cho NPP (Nhà Phân Phối) sau Q1/2026 — yêu cầu báo cáo OTIF hàng ngày/tuần.
- DA team đã chuẩn hoá pipeline `mv_otif` (1.28M rows, 2024–2026) trên ClickHouse → đủ điều kiện build view tại chỗ thay vì xuất Excel.

---

## 3. Target Users

| Persona | Vai trò | Tần suất | Use case chính |
|---|---|---|---|
| **Logistics Manager** | Quản lý vận tải, làm việc với carrier | Daily / Weekly | Giám sát % OTIF tổng, identify carrier yếu, theo dõi trend |
| **Warehouse Supervisor** | Giám sát kho (BKD1, NKD, …) | Daily | Theo dõi % theo kho, debug khi fail thuộc warehouse cause |

> **Personas khác (chưa confirm scope):** Sales Ops / Customer Service có thể cần xem theo Khu vực giao hàng — `[TBD]` cần Q1 stakeholder bổ sung.

---

## 4. Goals & Success Metrics

> ⚠️ **[TBD]** — Q2 user trả lời "không biết". Đề xuất default dưới đây cần stakeholder confirm.

### 4.1 Business goals (đề xuất)

| Goal | Metric đo lường | Target đề xuất |
|---|---|---|
| Tăng visibility OTIF realtime | Tần suất view sử dụng | ≥ 5 lần/tuần/user (logistics + warehouse) |
| Rút ngắn time-to-detect fail | Số ngày từ khi fail xảy ra → ops nhận biết | < 1 ngày (thay vì 7 ngày như báo cáo Excel) |
| Tăng accuracy phân loại nguyên nhân | % fail có root cause rõ (warehouse vs transport) | ≥ 95% (hiện tại MV đã phân loại 6 categories) |
| Giảm thời gian làm báo cáo tuần | Giờ/tuần | < 30 phút (thay vì 2–4h Excel) |

### 4.2 Product KPIs cần track sau launch

- Daily/Weekly Active Users của OTIF View
- Số lần Apply filter / Export / drill-down per session
- Latency p95 của 5+ API endpoints (target < 2s)
- MV refresh delay (target ≤ 5 phút như hiện tại)

### 4.3 OTIF threshold (chốt theo PRD discussion D2 = Y)

- 🟢 OTIF ≥ 90% / 🟡 80–89% / 🔴 < 80%
- 🟢 Ontime, Infull ≥ 95% / 🟡 85–94% / 🔴 < 85%

---

## 5. Functional Requirements

### 5.1 Filter bar (Must-have, áp dụng cho cả 2 tab)

| FR | Mô tả |
|---|---|
| FR-F1 | 6 filter: KHO, KHU VỰC GIAO HÀNG, NHÓM HÀNG, NHÀ VẬN TẢI, LOẠI NGÀY, DATE RANGE |
| FR-F2 | Mỗi filter là single-select dropdown, default `'ALL'` (trừ DATE RANGE = current date range) |
| FR-F3 | LOẠI NGÀY enum: `'ETA gửi thầu (đơn)'` (default) / `'ATA chi tiết chuyến'` |
| FR-F4 | Pattern Draft → Apply: thay đổi filter chỉ update draft state; click "Apply filter" mới fetch API |
| FR-F5 | Click "Reset filter" reset draft về default |
| FR-F6 | NULL `group_of_cago` / `transporter` / `khu_vuc_doi_xe` mapped thành `'Unclassified'` (SQL fallback) |
| FR-F7 | Empty `khu_vuc_doi_xe` (string rỗng) hiển thị `'Chưa phân loại'` (D6 = Y) |

### 5.2 Tab "Biểu đồ" (Must-have)

| FR | Mô tả |
|---|---|
| FR-B1 | 4 KPI cards (Tổng đơn, % Ontime, % Infull, % OTIF) với big number + sub count + description tiếng Việt theo Figma |
| FR-B2 | Color coding theo threshold §4.3 |
| FR-B3 | Chart "OTIF/Ontime/Infull theo khu vực" — grouped bar (Cyan/Green/Purple) |
| FR-B4 | Chart "OTIF/Ontime/Infull theo kênh bán hàng" — grouped bar |
| FR-B5 | Chart "OTIF/Ontime/Infull theo nhà vận tải" — grouped bar |
| FR-B6 | Chart "OTIF/Ontime/Infull theo kho" — grouped bar |
| FR-B7 | Chart "%OTIF và số lượng đơn theo thời gian" — combo bar (số đơn/grain) + line (%OTIF) với toggle Day/Week/Month |
| FR-B8 | Chart "Lý do fail ontime" — horizontal bar đơn sắc Orange; footer hiển thị tổng DO fail |
| FR-B9 | Chart "Lý do fail infull" — horizontal bar đơn sắc Red; footer hiển thị tổng DO fail |
| FR-B10 | Mỗi chart có info icon (?) hiển thị tooltip công thức KPI |
| FR-B11 | Mỗi chart có menu (⋮) với option Export |

### 5.3 Tab "Chi tiết bảng" (Must-have)

| FR | Mô tả |
|---|---|
| FR-T1 | Multi-select checkboxes "Nhóm theo": Nhà vận tải / Kênh bán hàng / Nhóm hàng / Khu vực đội xe |
| FR-T2 | Section "%OTIF chiều vận hành" — table với cột dim + Tổng số đơn + %OTIF/Ontime/Infull (mỗi cột hiển thị `XX.X% (Nđơn)`) |
| FR-T3 | Section breakdown fail Ontime — table cùng dim + Tổng + Số đơn fail Ontime [orange] + 5 cột pivot lý do |
| FR-T4 | Section "Bảng chi tiết đơn hàng" — raw orders với 15+ cột (xem spec §9.1) |
| FR-T5 | Pagination 10 rows/page cho Section 3 |
| FR-T6 | Per-column search input (header row) |
| FR-T7 | Sort 3-state per column (asc/desc/none) |
| FR-T8 | Button "Xuất" export CSV/XLSX |
| FR-T9 | Button "Cấu hình bảng" mở dialog ẩn/hiện cột |

### 5.4 Data layer (Must-have)

| FR | Mô tả |
|---|---|
| FR-D1 | Source duy nhất: `analytics_workspace.mv_otif` (ClickHouse, refresh 5 phút) — D7 = Y |
| FR-D2 | Tổng cộng 8+ endpoints (xem spec §2.1, §2.2) |
| FR-D3 | KPI tính trong SQL/MV, **không tính ở UI** (single source of truth) |
| FR-D4 | Divide-by-zero protection ở cả SQL (`if(total=0, 0, …)`) và UI (`r.totalSo > 0 ? … : 0`) |
| FR-D5 | Date filter mặc định loại NULL ETA/ATA → trạng thái `'Không có dữ liệu STM'` không vào KPI (D1 quyết định: dùng date filter làm implicit exclusion) |

### 5.5 Nice-to-have (chưa scope MVP)

- Drill-down KPI card → detail table (D8 = N → **không làm** trong MVP)
- Forecast OTIF (Q3 = Out-of-scope)
- Alert system khi % OTIF dưới threshold (Q3 = Out-of-scope)
- Workflow gán action item cho owner khi có fail (Q3 = Out-of-scope)
- Slack/Email notification (Out-of-scope)
- Owner mapping per fail reason (Q4 `[TBD]`) — placeholder cho phase 2

---

## 5.6 Business Logic Specification

> **Source of truth**: `analytics_workspace.mv_otif` (ClickHouse, refresh 5 phút). DDL tại `clickhouse-ddl/analytics-workspace_mvs.md` lines 5442–5660. Logic dưới đây đã verified với 1,280,855 rows (range 2024-01-08 → 2026-05-07) tại 2026-05-07.

### 5.6.1 Đầu vào & Ranh giới

| Item | Định nghĩa |
|---|---|
| **Đơn vị đo (granularity)** | 1 row = 1 SO (Sales Order). MV đã collapse từ line-level (`SO + ORDERLINENUMBER`) thành SO-level bằng aggregation + `row_number() OVER (PARTITION BY SO ORDER BY group_priority, ORDERLINENUMBER)` để pick header. |
| **Cargo group priority** (cho header pick) | FRESH (1) > DRY (2) > MOONCAKE (3) > POSM/OFFBOM (4) > TEST (5) > EQUIPMENT (6) > PM (7) > others (99) |
| **Volume metrics** | `sum_original_cse`, `sum_shipped_cse`, `sum_san_luong_giao_cse` (CSE = Case, đơn vị gốc OTIF). CBM/KG/PL chỉ phục vụ display. |
| **Time metrics** | `eta_giao_hang_cho_npp`, `ata_den` (chính); `etd_chuyen_gui_thau`, `gio_dang_tai`, `gio_goi_xe`, `gio_vao_cong`, `actual_ship_date`, `tg_bat_buoc_roi_kho`, `gio_ra_cong` (phụ — phục vụ phân loại fail reason). |
| **STM marker** | `has_stm_order = 1` nếu SO có ít nhất 1 line trong STM data, else 0. Quyết định status có phân loại được không. |

### 5.6.2 Công thức Status Classification

Mỗi SO được gán đồng thời 3 status. Logic dưới đây chính xác như implementation tại `mv_otif` lines 5639–5641.

#### A. `ontime_status`

```
IF (ETA NOT NULL) AND (ATA NOT NULL) AND (ETA < ATA)        → 'Failed Ontime'
ELSE IF (ETA NOT NULL) AND (ATA NOT NULL) AND (ETA >= ATA)  → 'Ontime'
ELSE IF has_stm_order = 0                                   → 'Không có dữ liệu STM'
ELSE                                                        → NULL
```

> **Note:** "On-Time" sử dụng `ETA >= ATA` ⇔ `ATA <= ETA` (tương đương). NULL ETA hoặc NULL ATA mà có STM data → status NULL (không phân loại được).

#### B. `infull_status`

Dùng `round(toFloat64(x), 4)` cho cả 3 cột để tránh false positive do precision.

```
IF has_stm_order = 0                                                → 'Không có dữ liệu STM'
ELSE IF (round(original_cse,4) > round(shipped_cse,4))
     OR (round(shipped_cse,4) > round(giao_cse,4))                  → 'Failed Infull'
ELSE IF (round(original_cse,4) = round(shipped_cse,4))
    AND (round(shipped_cse,4) = round(giao_cse,4))                  → 'Infull'
ELSE                                                                → NULL
```

> **Business meaning:** "In-Full" yêu cầu kế hoạch = xuất kho = giao khách (exact match). Bất cứ lệch nào (kho hụt, hoặc giao thiếu) đều là Failed Infull.

#### C. `otif_status`

```
IF (ontime = 'Ontime') AND (infull = 'Infull')   → 'OTIF'
ELSE IF has_stm_order = 0                        → 'Không có dữ liệu STM'
ELSE                                             → 'Failed OTIF'
```

> **Verified data distribution (2024-01 → 2026-05, toàn MV):**
> - `OTIF`: 367,466 rows (28.7%) | `Failed OTIF`: 135,365 rows (10.6%) | `Không có dữ liệu STM`: 778,024 rows (60.7%)
> - **Quan trọng:** 100% rows `'Không có dữ liệu STM'` có `eta_giao_hang_cho_npp = NULL` → date filter mặc định của UI **tự động loại** chúng. KPI hiển thị production luôn dùng denominator clean.

### 5.6.3 Công thức KPI Aggregation

Áp dụng sau khi filter scope (warehouse, area, group, transporter, dateType, dateRange).

```sql
totalSo  = countDistinct(so)
ontimeSo = countDistinct(if(ontime_status = 'Ontime', so, NULL))
infullSo = countDistinct(if(infull_status = 'Infull', so, NULL))
otifSo   = countDistinct(if(otif_status   = 'OTIF',   so, NULL))

pctOntime = if(totalSo = 0, 0, ontimeSo * 100.0 / totalSo)
pctInfull = if(totalSo = 0, 0, infullSo * 100.0 / totalSo)
pctOtif   = if(totalSo = 0, 0, otifSo   * 100.0 / totalSo)
```

> **Divide-by-zero protection:** SQL dùng `if(totalSo = 0, 0, …)`; UI dùng `r.totalSo > 0 ? … : 0`. Cả 2 layer đều safe.

### 5.6.4 Fail Reason Classification

#### A. `not_ontime_reason` (timestamp-based — 6 categories)

Triggered chỉ khi `ETA < ATA`. Logic concat các pattern matched (theo thứ tự):

| Reason | Trigger condition |
|---|---|
| `Late arrival by Transport` | `Giờ gọi xe < ETD < Giờ vào cổng` (xe đến cổng trễ so với ETD) |
| `Late warehouse call by Warehouse` | `ETD < Giờ đăng tài AND Giờ gọi xe > ETD` (kho gọi xe trễ) |
| `Late pickup by Warehouse` | `ETD > Giờ vào cổng AND Actual Ship > (TG bắt buộc rời kho - 10 phút)` (kho xuất hàng trễ) |
| `Late departure by Transport` | `ETD > Giờ vào cổng AND Actual Ship < (TG bắt buộc - 10p) AND TG bắt buộc < Giờ ra cổng` (xe ra cổng trễ) |
| `Late delivery by Transport` | `ETD > Giờ vào cổng AND Actual Ship < (TG bắt buộc - 10p) AND TG bắt buộc > Giờ ra cổng AND ETA < ATA` (xe trên đường lâu) |
| `Thiếu dữ liệu đăng ký dock` | Catch-all khi không match pattern nào (thiếu timestamp dock) |

> **Verified (Apr 2026):** Late delivery 14,508 / Late arrival 34,930 / Late wh call 10,063 / Thiếu dock 2,446 / Late pickup 21 / Late departure 2.
> **Empirical fact:** 0/61,970 rows có compound `not_ontime_reason` (multi-reason concat) — luôn single-valued trong production.

#### B. `not_infull_reason` (CSE-based — 3 categories)

Triggered chỉ khi `infull_status = 'Failed Infull'`.

| Reason | Trigger condition |
|---|---|
| `Warehouse + Transport Infull Failure` | `original > shipped > giao` (cả 2 cùng rớt) |
| `Warehouse Infull Failure` | `(original > shipped AND shipped = giao)` HOẶC `original > shipped` mà không thuộc combined |
| `Transport Infull Failure` | `original = shipped AND shipped > giao` (chỉ vận tải rớt) |

> **Verified (Apr 2026):** Transport 74,744 / Warehouse 4,678 / Combined 1,080.

### 5.6.5 Filter Behavior (Business Rules)

| Filter | Áp dụng SQL | Fallback rule |
|---|---|---|
| `whseid` | `whseid = p_whseid` | `'ALL'` → no filter |
| `groupOfCargo` | `coalesce(group_of_cago, 'Unclassified') = p_group_of_cago` | NULL → `'Unclassified'` |
| `transporter` | `coalesce(ten_ngan_nha_van_tai, 'Unclassified') = p_ten_ngan_nha_van_tai` | NULL → `'Unclassified'` |
| `khu_vuc_doi_xe` | `coalesce(khu_vuc_doi_xe, 'Unclassified') = p_khu_vuc_doi_xe` | NULL → `'Unclassified'`; UI display `'Chưa phân loại'` (D6) |
| `dateType` + `fromDate, toDate` | `CASE p_loai_ngay WHEN 'ETA gửi thầu' THEN toDate(eta_giao_hang_cho_npp) WHEN 'ATA chi tiết chuyến' THEN toDate(ata_den) END BETWEEN p_tu_ngay AND p_den_ngay` | `'ALL'` chỉ áp dụng cho Report raw query |

### 5.6.6 Derived Metrics (per-SO)

MV cung cấp các cột derived hữu ích cho drill-down:

| Cột | Đơn vị | Công thức | Use case |
|---|---|---|---|
| `cse_otif` | CSE | `IF (ETA<ATA) THEN 0 ELSE sum_giao_cse` (NULL nếu thiếu time) | OTIF volume per SO |
| `pct_otif` | % | `cse_otif / sum_original_cse` | Tỷ lệ giao OTIF của SO |
| `chenh_lech_sl_giao_cho_cse` | CSE | `sum_shipped_cse - sum_giao_cse` | Hụt giao do vận tải |
| `tong_tg_trong_kho_min` | phút | `dateDiff('minute', Giờ vào cổng, Giờ ra cổng)` | Time-in-warehouse |
| `tg_load_hang_min` | phút | `dateDiff('minute', ATA đến, ATA rời)` | Load time tại điểm giao |
| `chenh_lech_tg_thuc_te_du_kien_hour` | giờ | `dateDiff('hour', ETA, ATA)` | Lateness gap (>0 = trễ) |
| `delay_xe_dang_tai`, `delay_goi_xe`, `delay_vao_cong`, `delay_xuat_kho_tre`, `delay_roi_kho_tre`, `delay_tren_duong` | phút | Min-diff giữa các milestone vs ETD/TG bắt buộc | Phân rã thời gian fail ontime |

> Các cột này hiện chưa được expose qua API — Phase 2 có thể cân nhắc.

### 5.6.7 Edge Cases (Business Rules)

| # | Tình huống | Xử lý |
|---|---|---|
| BL-1 | `ETA NULL` hoặc `ATA NULL` (đơn chưa hoàn thành) | `ontime_status = NULL` hoặc `'Không có dữ liệu STM'`; KPI bỏ qua qua `countIf(... = 'Ontime', ...)`; UI date filter loại |
| BL-2 | `has_stm_order = 0` (đơn chưa lên STM) | All status = `'Không có dữ liệu STM'`; chiếm 60.7% MV nhưng 0% sau date filter; **không tính vào KPI** |
| BL-3 | `sum_original_cse = 0` (đơn 0 CSE) | `pct_otif = NULL`; status vẫn classify được nếu times đầy đủ |
| BL-4 | Tổng SO = 0 sau filter (filter quá hẹp) | KPI = 0% (divide-by-zero protected ở cả SQL + UI) |
| BL-5 | Empty `khu_vuc_doi_xe` (`''`) | UI render `'Chưa phân loại'` (D6); ~4,500 SO/tháng; SQL filter `'ALL'` vẫn include |
| BL-6 | NULL `group_of_cago`/`transporter` | SQL coalesce → `'Unclassified'`; SO vẫn được tính KPI |
| BL-7 | Duplicate SO trên 2 `whseid` khác nhau | MV ORDER BY (so, whseid) → có 2 rows; KPI dùng `countDistinct(so)` không double-count tổng, nhưng filter theo whseid sẽ chia |
| BL-8 | Multi-reason `not_ontime_reason` (compound string) | Theory: SQL group ra row riêng cho mỗi combination; reality: 0 occurrences (verified 2026-05-07) |
| BL-9 | Round precision (sum_original = 12.66666666 vs giao = 12.6666) | `round(toFloat64(x), 4)` — sai số bậc 5+ ignored, có thể vẫn trigger Failed Infull khi lệch ở bậc 4 |
| BL-10 | Timezone mix (DateTime64 UTC vs DateTime no-tz) | **Risk lệch ±7h** — DA cần verify (Phase 1 blocker) |

### 5.6.8 Threshold (chốt theo D2)

| KPI | 🟢 Green | 🟡 Amber | 🔴 Red |
|---|---|---|---|
| % On-Time | ≥ 95% | 85–94% | < 85% |
| % In-Full | ≥ 95% | 85–94% | < 85% |
| % OTIF | ≥ 90% | 80–89% | < 80% |

Áp dụng cho: KPI cards, Area/Channel/Carrier/Warehouse charts, Trend chart threshold line.

### 5.6.9 CLAUDE.md Data Exclusion Rules — Audit

| # | Rule | Trạng thái mv_otif |
|---|---|---|
| 1 | `is_deleted = 0` (ClickHouse) | ⚠️ Chỉ áp dụng `is_deleted=0` trên `dim_ord_order` JOIN cuối; upstream `mv_otif_swm_data`, `mv_otif_stm_data` chưa verify — DA cần check (Q1 PRD §9) |
| 2 | Cancelled orders excluded | ⚠️ Chưa verify — Q2 |
| 3 | Virtual/Test orders excluded | ⚠️ Chưa verify (lưu ý: cargo group có 'TEST' priority 5 — có thể test orders đang lọt vào MV) |
| 4 | Internal transfers excluded | ⚠️ Chưa verify — Q3 |
| 5 | NULL warehouse/shift/ETD excluded | ❌ MV không filter NULL ETA/ATA (cố ý — để giữ status `'Không có dữ liệu STM'` cho audit); **date filter UI là implicit exclusion** |
| 6 | Divide by zero → return 0 | ✅ SQL + UI đều có protection |

> **Action:** DA team cần verify Q1, Q2, Q3 trước Phase 1 launch. Q5 timezone là medium risk độc lập.

---

## 5.7 Data Pipeline Reference (Engineering)

> Section bổ sung cho §5.6: chi tiết **pipeline lineage**, **column reference**, **query patterns**, và **bugs** dành cho dev/DA. Stakeholder/BA có thể bỏ qua.

### 5.7.1 Pipeline lineage (4 stages)

```
┌─────────────────────┐    ┌─────────────────────┐
│ STM CDC sources     │    │ SWM CDC sources     │
│ stm_dwh_mondelez.*  │    │ swm-test.* (default)│
└──────────┬──────────┘    └──────────┬──────────┘
           ▼                          ▼
   mv_otif_stm_data           mv_otif_swm_data
   (line-level STM)           (line-level SWM)
   ~2.97M rows                ~6.38M rows
           │                          │
           └────────────┬─────────────┘
                        ▼
        mv_otif_swm_stm_data
        - JOIN stm × swm by SO + LineNo
        - Enrich masterdata location/SKU
        - Compute Sản lượng giao CSE/CBM/KG/PL via UOM conversion
        ~6.45M rows
                        ▼
        mv_otif (1 row per SO)
        - Aggregate line → SO sum CSE/CBM/KG/PL
        - Pick header line theo group_priority
        - Compute ontime/infull/otif status + reasons + 6 delays
        1,280,855 rows (≈ 1,279,536 distinct SO)
                        ▼
              8 SQL queries (registry)
                        ▼
       API endpoints (CTowerController) → UI
```

**Engine:** Tất cả MV dùng `SharedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')` trên ClickHouse Cloud. `REFRESH EVERY 5 MINUTE`.

### 5.7.2 `mv_otif` — 55 cột (column reference tóm tắt)

| Nhóm | Số cột | Cột chính |
|---|---:|---|
| **Identifier** | 2 | `so`, `whseid` |
| **Cargo / Customer** | 5 | `group_of_cago`, `group_name`, `customer_code`, `customer_name`, `khu_vuc_doi_xe` |
| **Carrier / Vehicle** | 5 | `ten_ngan_nha_van_tai`, `loai_xe_van_hanh`, `loai_xe_gui_thau`, `ma_doi_tac_nhan`, `ten_doi_tac_nhan` |
| **Trip identifier** | 5 | `id_chuyen_gui_thau`, `so_chuyen`, `so_xe`, `tai_xe`, `ma_nha_xe` |
| **Timeline** | 13 | `thoi_gian_gui_thau`, `ngay_tao_chuyen`, `etd_chuyen_gui_thau`, `gio_dang_tai`, `gio_goi_xe`, `gio_vao_cong`, `gio_vao_dock`, `actual_ship_date`, `gio_ra_dock`, `gio_ra_cong`, `tg_bat_buoc_roi_kho`, **`eta_giao_hang_cho_npp`** (ETA), **`ata_den`** (ATA), `ata_roi` |
| **Volume planned (`sum_original_*`)** | 5 | base, cbm, kg, cse, pl |
| **Volume shipped (`sum_shipped_*`)** | 5 | base, cbm, kg, cse, pl |
| **Volume giao (`sum_san_luong_giao_*`)** | 5 | base, cbm, kg, cse, pl |
| **Chênh lệch (`chenh_lech_sl_giao_cho_*`)** | 5 | base, cbm, kg, cse, pl = shipped − giao |
| **Time KPIs** | 3 | `tong_tg_trong_kho_min`, `tg_load_hang_min`, `chenh_lech_tg_thuc_te_du_kien_hour` |
| **Status** | 3 | `ontime_status`, `infull_status`, `otif_status` |
| **Per-SO OTIF** | 2 | `cse_otif`, `pct_otif` |
| **Reasons** | 2 | `not_ontime_reason`, `not_infull_reason` |
| **6 Delay metrics (phút)** | 6 | `delay_xe_dang_tai`, `delay_goi_xe`, `delay_vao_cong`, `delay_xuat_kho_tre`, `delay_roi_kho_tre`, `delay_tren_duong` |
| **Audit dates** | 3 | `ngay_duyet_chuyen`, `ngay_gi`, `ngay_tao_don` |

### 5.7.3 Group priority (header pick rule)

Khi 1 SO có nhiều lines với cargo group khác nhau, MV chọn header theo:

```sql
row_number() OVER (PARTITION BY SO
                   ORDER BY group_priority ASC, ORDERLINENUMBER ASC NULLS LAST) = 1
```

| Priority | Cargo group |
|---:|---|
| 1 | FRESH |
| 2 | DRY |
| 3 | MOONCAKE |
| 4 | POSM / OFFBOM / POSM/OFFBOM |
| 5 | TEST |
| 6 | EQUIPMENT |
| 7 | PM |
| 99 | other |

> **Implication**: 1 SO có cả Fresh và Dry sẽ được gán `group_of_cago = 'FRESH'`. Filter NHÓM HÀNG = `'DRY'` sẽ **không match** SO đó dù có line DRY. Volume aggregation (`sum_*`) vẫn đầy đủ tất cả lines.

### 5.7.4 8 query patterns (cùng template `WITH params + filtered_data`)

```sql
WITH params AS (
    SELECT
        'ALL'                AS p_whseid,
        'ALL'                AS p_group_of_cago,
        'ALL'                AS p_khu_vuc_doi_xe,
        'ALL'                AS p_ten_ngan_nha_van_tai,
        'ETA gửi thầu'       AS p_loai_ngay,        -- hoặc 'ATA chi tiết chuyến'
        toDate('1900-01-01') AS p_tu_ngay,
        toDate('2999-12-31') AS p_den_ngay
),
filtered_data AS (
    SELECT t.*
    FROM analytics_workspace.mv_otif AS t
    CROSS JOIN params AS p
    WHERE
          (p.p_whseid               = 'ALL' OR t.whseid = p.p_whseid)
      AND (p.p_group_of_cago        = 'ALL' OR coalesce(t.group_of_cago, 'Unclassified') = p.p_group_of_cago)
      AND (p.p_ten_ngan_nha_van_tai = 'ALL' OR t.ten_ngan_nha_van_tai = p.p_ten_ngan_nha_van_tai)
      AND (p.p_khu_vuc_doi_xe       = 'ALL' OR t.khu_vuc_doi_xe = p.p_khu_vuc_doi_xe)
      AND (
          CASE
              WHEN p.p_loai_ngay = 'ETA gửi thầu'        THEN toDate(t.eta_giao_hang_cho_npp)
              WHEN p.p_loai_ngay = 'ATA chi tiết chuyến' THEN toDate(t.ata_den)
              ELSE NULL
          END
          BETWEEN coalesce(p.p_tu_ngay, toDate('1900-01-01'))
              AND coalesce(p.p_den_ngay, toDate('2999-12-31'))
      )
)
-- query-specific aggregation here
```

| # | Query | SQL Reg § | Aggregation chính | Output shape |
|---:|---|---|---|---|
| 1 | KPI Summary (Tổng đơn / % Ontime / % Infull / % OTIF) | 16427, 16591, 16755, 16919 | `count(so)` + `countIf(status='X')` + round 2 | 1 row × 7 metrics |
| 2 | Theo khu vực | 17083 | GROUP BY `khu_vuc_doi_xe`, same agg | N rows × 7 metrics |
| 3 | Phân rã fail ontime | 17227 | `countDistinct(so)` GROUP BY `not_ontime_reason` (filter `Failed Ontime`) | N rows × 2 col |
| 4 | Phân rã fail infull | 17389 | `countDistinct(so)` GROUP BY `not_infull_reason` (filter `Failed Infull`) | N rows × 2 col |
| 5 | Trend theo thời gian | 17699 | GROUP BY `day, toStartOfWeek(d, 1), toStartOfMonth(d)`; `countDistinct(so)` | N rows × 5 col (3 grain + counts + %) |
| 6 | %OTIF chiều vận hành | 17910 | GROUP BY 4 dim (`NVT × Kênh × Nhóm × Khu vực`); `countDistinct(so)` | N rows × 11 col |
| 7 | Report fail ontime/infull | 18164 | Long-form detail + reasons | All MV cols × N rows |
| 8 | Report raw data | 17551 | `SELECT t.*` from filtered_data; ORDER BY so, ngay_tao_chuyen, eta | All 55 cols × N rows |

### 5.7.5 Conversion logic (`mv_otif_swm_stm_data`)

`Sản lượng giao CSE/CBM/KG/PL` được tính từ `QuantityBBGN` (số lượng biên bản giao nhận) tuỳ UOM:

```
UOM = 'CSE'             → giao_cse1 = QuantityBBGN
UOM ∈ ('PCE','PC','EA') → giao1     = QuantityBBGN
UOM = 'PALLET'          → giao_pl1  = QuantityBBGN
```

Sau đó convert qua masterdata SKU (`masterunit_per_cse`, `masterunit_per_pallet`, `cbm_per_masterunit`, `kg_per_masterunit`):

| Output | Trigger UOM | Formula |
|---|---|---|
| `Sản lượng giao` (master units) | CSE | `giao_cse1 × masterunit_per_cse` |
| | PCE/PC/EA | `giao1` (giữ nguyên) |
| | PALLET | `giao_pl1 × masterunit_per_pallet` |
| `Sản lượng giao CSE` | CSE | `giao_cse1` |
| | PCE/PC/EA | `giao1 / masterunit_per_cse` |
| | PALLET | `giao_pl1 × masterunit_per_pallet / masterunit_per_cse` |
| `Sản lượng giao CBM` | All | `(master units) × cbm_per_masterunit` |
| `Sản lượng giao KG` | All | `(master units) × kg_per_masterunit` |
| `Sản lượng giao PL` | CSE | `giao_cse1 × masterunit_per_cse / masterunit_per_pallet` |
| | PCE/PC/EA | `giao1 / masterunit_per_pallet` |
| | PALLET | `giao_pl1` (giữ nguyên) |

> **Risk:** Formulas dùng `assumeNotNull(masterdata_sku.X)` — nếu masterdata thiếu (SKU mới chưa setup), query throw runtime error. Cần DA verify masterdata coverage.

### 5.7.6 Inconsistencies & Bugs phát hiện

| # | Bug / Inconsistency | Severity | Vị trí |
|---|---|---|---|
| BUG-1 | Typo `'ATA chi tiết chuyên'` (thiếu dấu) trong Redshift Report raw query | 🟢 Low | `sql-registry.md` §17604; ClickHouse version đã đúng |
| BUG-2 | Filter coalesce inconsistency: `p_ten_ngan_nha_van_tai` & `p_khu_vuc_doi_xe` có fallback `'Unclassified'` ở query "%OTIF chiều vận hành" (§17947, §17951) nhưng KHÔNG có ở 4 KPI summary query (§17188, §17190) | 🟡 Medium | Có thể gây kết quả khác nhau khi filter rows có NULL transporter/area |
| BUG-3 | KPI Summary dùng `count(so)`, queries Trend/Chiều vận hành dùng `countDistinct(so)` | 🟡 Medium | sql-registry §16566 vs §17871, §18101 — cần align convention |
| BUG-4 | `assumeNotNull(masterdata_sku.X)` có thể throw runtime exception nếu masterdata gap | 🟡 Medium | `mv_otif_swm_stm_data` lines 5936–5940 |
| BUG-5 | Timezone mix: `tg_bat_buoc_roi_kho` là `DateTime` (no tz), trong khi `Giờ vào cổng/ra cổng/đăng tài/gọi xe` là `DateTime('UTC')` → risk lệch ±7h khi compare | 🟡 Medium | `mv_otif_swm_stm_data` DDL — đây cũng là nguồn của Q5 §9 |

### 5.7.7 Data quality assertions (cho QA test)

| # | Assertion | Expected | Verified 2026-05-07 |
|---|---|---|---|
| A1 | 1 row per SO trong `mv_otif` | True | ✅ 1,279,536 distinct SO ≈ 1,280,855 rows (≈ 0.1% có duplicate khác whseid) |
| A2 | Tất cả `'Không có dữ liệu STM'` rows có ETA NULL | True | ✅ 100% confirmed |
| A3 | Empty `khu_vuc_doi_xe` chỉ vài % | < 5% | ✅ ~4% Apr-May 2026 |
| A4 | `not_ontime_reason` luôn single-valued (không compound) | True trong production | ✅ 0/61,970 |
| A5 | `pct_ontime + pct_failed_ontime ≈ 100%` (sau date filter) | True | 🔲 Cần verify |
| A6 | `% OTIF ≤ min(% Ontime, % Infull)` | True (vì OTIF = AND) | 🔲 Cần verify |
| A7 | `chenh_lech_sl_giao_cho_cse = sum_shipped_cse − sum_san_luong_giao_cse` | True | 🔲 Cần verify |
| A8 | `cse_otif = 0` khi `Failed Ontime`; `= sum_giao_cse` khi `Ontime`; NULL khi NULL ETA/ATA | True | 🔲 Cần verify |

### 5.7.8 Live KPI snapshot (Apr 1 – May 7, 2026)

| Khu vực | Tổng SO | OTIF SO | % OTIF |
|---|---:|---:|---:|
| (Empty) | 4,530 | 3,937 | 86.9% |
| North East - North West | 1,627 | 1,083 | 66.6% |
| Ha Noi | 1,455 | 999 | 68.7% |
| Ho Chi Minh | 1,430 | 976 | 68.3% |
| South East | 1,356 | 883 | 65.1% |
| North Central Coast | 1,050 | 653 | 62.2% |
| Central | 606 | 424 | 70.0% |
| Mekong 1 | 574 | 377 | 65.7% |
| Mekong 2 | 566 | 395 | 69.8% |
| South Central Coast | 446 | 318 | 71.3% |
| Central highland | 266 | 169 | 63.5% |
| South East - Lam Dong | 200 | 137 | 68.5% |

**Observations:**
- Tất cả areas (trừ Empty) đều dưới ngưỡng 90% → có nhiều scope cải thiện cho Phase 2 Alert workflow.
- Empty area paradox 86.9% (cao nhất) — cần điều tra: liệu các SO không có area phải chăng là internal transfer (không qua carrier nên ít fail)?
- Distribution áp đảo của Transport Infull Failure (93%) trong fail infull → vấn đề chủ yếu ở khâu giao (xe chở thiếu so với bốc xếp), không phải kho.

---

## 6. Out of Scope

| # | Hạng mục | Lý do |
|---|---|---|
| OOS-1 | Forecast / Prediction OTIF tương lai | Q3 user xác nhận chưa làm |
| OOS-2 | Alert/Notification khi fail | Q3 — Phase 2 |
| OOS-3 | Workflow assign action item cho owner | Q3 — Phase 2; cần Q4 D5 quyết định owner mapping |
| OOS-4 | Late Order Alert scorecard (7 query trong sql-registry §18407–19103) | Thuộc feature **Late Order Alert** (`mv_alert_late_do`), không phải OTIF |
| OOS-5 | OTC Monthly forecast vs Sales Plan | Thuộc OTC View module |
| OOS-6 | Mobile responsive UI | MVP chỉ desktop |
| OOS-7 | Owner mapping (warehouse vs transport) cho từng fail reason | Q4 `[TBD]` — Phase 2 cần stakeholder confirm |
| OOS-8 | Translation map English ↔ Vietnamese cho fail reasons | Hiện tại UI hiển thị English label trực tiếp; nếu cần VN labels → Phase 2 |

---

## 7. Decisions Log

| ID | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | % KPI denominator có loại `'Không có dữ liệu STM'` không? | ✅ **Loại implicitly qua date filter** | Verified 2026-05-07: 100% rows 'Không có dữ liệu STM' có ETA NULL → date filter tự động loại. Không cần thêm WHERE clause |
| D2 | OTIF threshold | ✅ Giữ 90/80 cho OTIF, 95/85 cho Ontime+Infull | User confirm Y |
| D3 | In-Full formula | ✅ Exact match `original = shipped = giao` (round 4 decimals) | User confirm Y; production code + UI tooltip + MV align |
| D4 | Default date type | ✅ `'ETA gửi thầu (đơn)'` | User confirm Y; matches code default |
| D6 | Empty area policy | ✅ UI render `'Chưa phân loại'` (giữ nguyên code hiện tại, không đổi sang `'Không xác định'`) | User confirm Y; matches Figma + code |
| D7 | Refresh cadence 5 phút | ✅ Đủ realtime cho ops daily | User confirm Y |
| D8 | Drill-down KPI → table | ❌ **Không làm** | User confirm N |

### Decisions còn `[TBD]`

| ID | Decision | Khi nào cần |
|---|---|---|
| Q2 | Goals & Success Metrics cụ thể | Trước Phase 2 launch — cần stakeholder confirm target % và cadence review |
| Q4 | Owner mapping per fail reason (warehouse vs transport) | Phase 2 nếu làm Alert/Action workflow |

---

## 8. Edge Cases & Error Handling

Xem spec §11 (Edge Cases E1–E14) và §10 (Loading & Error States) cho chi tiết. Tóm tắt:

- NULL ETA/ATA: status NULL hoặc `'Không có dữ liệu STM'`, date filter loại
- Tổng DO = 0 (filter quá hẹp): KPI hiển thị 0%
- API 5xx: hiển thị error banner, charts/table empty, user click Apply để retry
- MV refresh delay: chấp nhận trễ ≤ 5 phút (D7)
- Timezone DateTime64 UTC vs DateTime no-tz: **risk lệch ±7h** — cần DA verify (spec §13 Q5)

---

## 9. Data Quality Risks (cần DA align)

| # | Risk | Severity | Owner |
|---|---|---|---|
| Q1 | Upstream `mv_otif_swm_data`, `mv_otif_stm_data` chưa verify áp `is_deleted=0` | 🟡 Medium | DA team |
| Q2 | Cancelled / Virtual / Test orders có nằm trong scope OTIF không | 🟡 Medium | DA + BA |
| Q3 | Internal transfer orders có tính OTIF không | 🟡 Medium | BA + Logistics manager |
| Q4 | Typo `'ATA chi tiết chuyên'` ở Redshift Report raw query | 🟢 Low | DA (sẽ deprecate Redshift) |
| Q5 | Timezone mismatch giữa các DateTime cột | 🟡 Medium | DA |

---

## 10. Release Plan

### Phase 1 — MVP (current scope)

- ✅ 5 endpoints + 1 KPI summary đã có
- 🔲 Bổ sung 6 endpoints mới (3 chart progress + 2 table + 1 raw report) — xem spec §2.2
- 🔲 Replace `buildMock()` 40 rows bằng `fetchOtifReportRaw`
- 🔲 Verify E14 (multi-area) — đã verify code: single-select OK
- 🔲 Standardize chart colors theo Figma (orange fail ontime, red fail infull)
- 🔲 DA verify Q1, Q2, Q5 (data quality)

### Phase 2 — Post-MVP (`[TBD]` priority)

- Translation map English ↔ Vietnamese cho fail reasons
- Owner mapping + assignment workflow
- Alert/Notification
- Forecast OTIF

---

## 11. Open Questions

1. **Q2 Success metrics:** Stakeholder cần confirm target % OTIF mục tiêu (90%? 95%?) và cadence review (daily/weekly).
2. **Q4 Owner mapping:** Khi `Late warehouse call by Warehouse` xảy ra, ai chịu trách nhiệm xử lý? Cần định nghĩa cho Phase 2.
3. **Internal transfer orders** có nằm trong scope OTIF không? (CLAUDE.md Data Exclusion Rule #4 yêu cầu loại — nhưng cần BA confirm áp dụng cho OTIF)
4. **Multi-channel breakdown:** Figma có chart "theo kênh bán hàng" — danh sách channels chính (KA/MT/GT/E-com/…) cần BA list rõ trong spec.

---

## 12. Cross-references

- Spec: `docs/02-features/otif/otif.spec.md`
- Wireframe: `docs/02-features/otif/otif.wireframe.md`
- GLOSSARY: `docs/GLOSSARY.md` § "On-Time In-Full"
- Audit results:
  - S2 Pipeline: `docs/audit-results/s2-otif-20260507.md`
  - S1 BA Logic: `docs/audit-results/s1-otif-20260507.md`
- SQL Registry: `docs/03-engineering/sql-registry.md` § "OTIF - verified" (16425–18406)
- DDL: `docs/03-engineering/data-sources/clickhouse-ddl/analytics-workspace_mvs.md` § `mv_otif` (5442–5660)
- Code:
  - UI: `control-tower/ui/src/views/control-tower/order-monitor/OTIFView.tsx`
  - API: `control-tower/api/src/WPred.Api/Controllers/CTowerController.cs:1465–1660`
  - Client: `control-tower/ui/src/api/otifApi.ts`
