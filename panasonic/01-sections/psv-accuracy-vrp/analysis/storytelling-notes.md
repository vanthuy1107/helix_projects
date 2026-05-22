# Storytelling Notes — Section `psv-accuracy-vrp`

> **Source artifact:** [projects/panasonic/05-reference/PSV-auto-demo.pdf](../../../../05-reference/PSV-auto-demo.pdf)
> **Mode:** Critique + Visualize (Design skipped per request)
> **Author:** /da-storytelling-data
> **Date:** 2026-05-19
> **Target binding:** `analytics_workspace.mv_psv_main` (Panasonic PSV pipeline — see [`analytics-workspace_psv.md`](../../../../02-data/data-sources/clickhouse-ddl/analytics-workspace_psv.md))
> **Status:** DRAFT — input cho bước `/ba` kế tiếp

---

## 0. Tiền đề (đọc trước khi xem từng chart)

### 0.1 Câu chuyện tổng thể của bộ chart

Demo PDF kể câu chuyện **đo độ tin cậy của Auto Planning (VRP)** từ 5 góc nhìn:

| § | Section trong PDF | Câu hỏi nghiệp vụ chính | Audience |
|---|---|---|---|
| 1 | Overall Performance | "Bao nhiêu % phương án Auto được giữ nguyên hoặc chỉ chỉnh do thiếu xe?" | BOD + Planning Lead |
| 2 | Post-Adjustment Violation | "Sau khi planner chỉnh tay, còn bao nhiêu chuyến vi phạm ràng buộc?" | Planning Lead + Operations |
| 3 | Vendor & Operation Impact | "Planner đang swap vendor nào, ảnh hưởng chi phí gì?" | Procurement + Planning Lead |
| 4 | Adjusted vs Auto by Zone | "Adjust làm tăng/giảm chi phí ở zone nào?" | Planning Lead + Finance |
| 5 | Autolog | "Ai đang dùng Autoplan, tần suất ra sao, tỷ lệ run success bao nhiêu?" | Operations Manager + IT Adoption |

Insight tối thượng cần ship: **"VRP có đáng tin để giữ nguyên không? Nếu phải chỉnh thì chỉnh ở đâu, vì sao, tốn thêm bao nhiêu?"**

### 0.2 ⚠️ Constraint kỹ thuật then chốt — đọc kỹ trước khi map chart sang data

`mv_psv_main` là **snapshot 1-row-per-route-final-state**:

- Engine = refreshable MV đọc từ `psv_target FINAL` mỗi 1 giờ.
- 1 hàng = 1 (`tracking_id`, `order_code`) — đại diện **trạng thái cuối cùng** của route sau mọi chỉnh sửa của planner.
- **KHÔNG lưu baseline "Auto Planning gốc" song song với "Adjusted final"** trong cùng 1 dòng.
- Chỉ có 1 cờ duy nhất để phân biệt: `is_trip_edit_manual` (Bool) + derived `status_name_detail` (`Chuyến tạo mới` vs `Chuyến điều chỉnh route`).
- Có `reason_change` (text user nhập khi adjust) và `report_modified_date / report_modified_by` (ai/khi chỉnh).
- **Không có**: `total_cost_auto`, `vendor_name_auto`, `cost_per_cbm_auto`, `trip_count_auto`, hoặc các trường "_original" để pivot Auto vs Adjusted.

Hệ quả: **mọi chart so sánh Auto vs Adjusted (Sections 1.3, 3, 4 trong PDF) đều GAP với `mv_psv_main`**. Có 3 hướng xử lý — đề xuất rõ ở §99 cuối note.

### 0.3 Zone — concept derived, không có trong mv_psv_main

PDF dùng các "zone" như `HN inside`, `HN outside`, `Red River Delta`, `Mekong`, `HN-DN`, `HCM-DN`, ... `mv_psv_main` chỉ có `location_from_code` và `location_to_code` (LowCardinality String). Để derive zone:

- **Cần master_data**: 1 bảng `location → zone` (Panasonic logistics zone), join theo `location_to_code` (zone đích) hoặc cặp (`location_from_code`, `location_to_code`) cho route inter-zone như "HN-DN".
- Heuristic từ tên (`location_to_name`) là fragile, không dùng.
- → **GAP cross-cutting cho mọi chart "by Zone"** — flagged trong từng chart bên dưới.

### 0.4 Grain mặc định của mọi chart

- **mv_psv_main**: 1 row = 1 (tracking_id, order_code). 1 chuyến (`tracking_id`) có thể có nhiều order → khi count "trip" phải `uniqExact(tracking_id)`.
- **Filter ngữ cảnh chuẩn** áp dụng mọi chart trừ khi nói khác: `is_deleted = 0 AND data_report = true AND is_save = true` (đã built-in trong refresh query của mv_psv_main, KHÔNG cần lặp).
- **Time filter**: dùng `created_date` (đã UTC+7) cho window day/month của OPS_Optimizer run. Tránh `master_etd`/`master_eta` vì đó là datetime kế hoạch giao, không phải lúc run thuật toán.

### 0.5 Source-of-truth model — per legacy Apps Script (fake-data generator)

PM/DA cung cấp Google Apps Script `generateTablesForCharts()` đã dùng để generate fake data cho demo PDF. Đọc script này tiết lộ **mental model dữ liệu PM giả định** cho real pipeline:

**Field shape `Fake_Data_Dashboard`:**

| Field | Loại | Ý nghĩa | Có ở `mv_psv_main`? |
|---|---|---|---|
| `Tender ID` | dimension | ≈ `tracking_id` hoặc `ops_optimize_id` | ✅ (`tracking_id`) |
| `User ID` | dimension | planner email | ✅ (`created_by`) |
| `Action Type` | event-type enum | `Run Auto` / `Final Save` / `Send Tender` | 🔴 KHÔNG — đây là EVENT, không snapshot |
| `Action Timestamp` | event time | mỗi action có timestamp riêng | 🔴 KHÔNG — chỉ có `created_date` + `report_modified_date` (2 timestamp) |
| `Run Status` | per-run status | likely `Success/Failure` | 🔴 KHÔNG — chỉ có `data_report` Bool |
| `total_fee` | measure | Actual (post-adjustment) fee | ✅ (`total_cost`) |
| `Original Total Fee` | measure | Auto baseline fee | 🔴 KHÔNG — chỉ có Adjusted |
| `carrier` | dimension | vendor name | ✅ (`vendor_name`) — Adjusted only |
| `Zone` | dimension | pre-classified zone label | 🔴 KHÔNG — cần master |

**3 trụ cột mental model PM giả định:**

1. **Event log table** với 3 distinct event types (`Run Auto`, `Final Save`, `Send Tender`) — KHÔNG phải single snapshot row per trip. Đây là source-of-truth riêng cho Chart 1.4 (Process Efficiency) và toàn bộ Section 5 (Autolog).

2. **2-column baseline** — `total_fee` (Actual/Adjusted) và `Original Total Fee` (Auto baseline) cùng tồn tại trên 1 row per tender. Đây là **Option B** của §99, KHÔNG phải Option A (version pivot). PM mental model là "lưu cả 2 giá trị side-by-side", không phải "diff giữa 2 versions".

3. **Zone master ready** — fake data đã có sẵn cột Zone populated. PM có file mapping ở đâu đó (chưa share), chứ KHÔNG đoán/derive runtime.

**Công thức Chart 1.4 (Process Efficiency) — confirmed từ code:**

```js
// From generateTablesForCharts():
adjDur   = (tenderMap[id].finalSave - tenderMap[id].start) / 60000   // min
leadTime = (tenderMap[id].sent      - tenderMap[id].finalSave) / 60000  // min
// start = MIN(Action Timestamp), thường là Run Auto event đầu tiên
// finalSave = timestamp của Final Save event
// sent = timestamp của Send Tender event
```

- `AVG Adj Duration = AVG(Final Save - Run Auto first)` per tender.
- `AVG Final Leadtime = AVG(Send Tender - Final Save)` per tender.
- ⚠️ Code **KHÔNG tính `AVG Preparation`** — PM đã drop metric này khi generate fake data. Confirm recommendation §99: ship 2/3 metric v1, đẩy `AVG Preparation` sang v2 hoặc bỏ.

**Implication tổng thể:** real pipeline cần bổ sung **2 nguồn dữ liệu mới** ngoài hiện tại:
- (i) Event log table (Run Auto, Final Save, Send Tender, Run Status) — từ Panasonic TMS audit/activity log hoặc tạo mới.
- (ii) Baseline columns (`total_cost_auto`, `total_cbm_auto`, `vendor_name_auto`) — extend `psv_target` từ JSON nếu OPS_Optimizer lưu, hoặc capture tại event Run Auto.

---

## SECTION 1 — Overall Performance

### Chart 1.1 — `% Accuracy (No Change)` (KPI card, big number)

**1. Audience + narrative intent**
- Audience: BOD + Planning Lead.
- Câu hỏi: "Tỷ lệ phương án Auto được giữ nguyên (hoặc chỉ đổi do thiếu xe) là bao nhiêu? → Có nên đầu tư tiếp vào VRP không?"
- **Định nghĩa Accuracy do Panasonic chốt (PDF page 1):** `Accuracy = (No Change + Change with violation) / Total results` — tức là *route không bị động* HOẶC *bị động nhưng vẫn vi phạm sau đó* (planner thay đổi không "cứu" được). Cases chỉnh và đẹp (no violation) bị **trừ điểm** khỏi Accuracy. ⚠️ Đây là định nghĩa **counter-intuitive** — phải highlight trong tooltip và spec.

**2. Chart type rationale**
- KPI card big-number 68% — fit tốt cho headline single-value.
- 🟡 **Khuyến nghị critique**: thêm sparkline 7-14 ngày bên dưới + RAG band (Green ≥ 80%, Yellow 60–80%, Red < 60%) + delta vs tuần trước. Số 68% raw không cho biết trend.

**3. Layout hierarchy**
- L1 — Hero KPI. Vị trí top-left section. Filter ngữ cảnh = section filter chung (date range + planner + zone).
- Drill-down: click → hiện Chart 1.2 (Accuracy by Zone) đã filtered + table chi tiết.

**4. Data shape — `mv_psv_main`**

| Vai trò | Column / công thức | Có sẵn? |
|---|---|---|
| Dimension grouping | `is_trip_edit_manual`, `status_name_detail`, `constraint_name` | ✅ |
| Filter | `created_date` (range), `created_by` (planner) | ✅ |
| Grain | per `tracking_id` (uniqExact) — không phải per row | ✅ |

**Công thức SQL (per `tracking_id` — vì 1 chuyến có thể có nhiều order rows):**

```sql
WITH trip_level AS (
    SELECT
        tracking_id,
        any(is_trip_edit_manual)                       AS edited,
        max(constraint_name != '' ? 1 : 0)             AS has_violation
    FROM analytics_workspace.mv_psv_main
    WHERE created_date BETWEEN {{date_from}} AND {{date_to}}
    GROUP BY tracking_id
)
SELECT
    countIf(edited = 0)                                AS no_change_trips,
    countIf(edited = 1 AND has_violation = 1)          AS change_with_violation_trips,
    count()                                            AS total_trips,
    (no_change_trips + change_with_violation_trips) * 100.0 / total_trips
                                                       AS pct_accuracy
FROM trip_level;
```

**Numerator:** `tracking_id` thoả 1 trong 2:
- `is_trip_edit_manual = 0` (No Change)
- `is_trip_edit_manual = 1 AND constraint_name != ''` (Change with violation)

**Denominator:** `uniqExact(tracking_id)` trong window.

**GAP — quy tắc "NVT change due to vehicle shortage"** (PDF mô tả: "the plan remains unchanged or only the NVT is changed due to vehicle shortage"). `NVT` (Nhà Vận Tải) = `vendor_name`. Định nghĩa hiện tại trong `status_name_detail` derive logic **không phân biệt** trường hợp này với change khác. → **CẦN BA clarify với Panasonic**: chỉ đổi `vendor_name` có nên count là "No Change" không? Nếu có, cần thêm điều kiện so sánh vendor Auto vs Adjusted → đụng GAP §0.2 (không có vendor baseline).

**5. Edge case + empty state**
- Không có run nào trong window → KPI = `—` + caption "No Autoplan run in selected period" (KHÔNG fallback về 100% hay 0%).
- Total = 0 → divide-by-zero → return `NULL`, hiển thị `—`.
- `tracking_id` mà cả `edited=0` lẫn `constraint_name=''` → vẫn count là No Change (rule đúng).
- VRP không chạy (no data_report) → row đã bị filter ở MV refresh (`data_report = true`), nên không xuất hiện.

---

### Chart 1.2 — `Accuracy Rate by Zone` (horizontal bar)

**1. Audience + narrative intent**
- Audience: Planning Lead.
- Câu hỏi: "Zone nào VRP làm tốt (giữ nguyên cao), zone nào hay bị chỉnh? → Tinh chỉnh thuật toán theo zone."

**2. Chart type rationale**
- Horizontal bar sorted desc — đúng pattern cho ranking 16 zones có label dài tiếng Việt.
- 🟢 Keep: sort theo % giảm dần.
- 🟡 Critique: KHÔNG có target line / threshold. Đề xuất thêm vertical line at 80% (target Panasonic).
- 🟡 RAG color: thay vì 1 màu xanh đậm cho tất cả, dùng Red < 50%, Yellow 50–80%, Green ≥ 80%.

**3. Layout hierarchy**
- L2 — Diagnostic chart, bên phải Chart 1.1.
- Mối quan hệ: click 1 zone → filter cascade xuống Section 2 (violation by zone), Section 4 (cost by zone).

**4. Data shape — `mv_psv_main`**

| Vai trò | Column | Status |
|---|---|---|
| Dimension X | `zone` (derived) | 🔴 GAP — cần master_data location → zone |
| Measure | `% accuracy` (cùng công thức Chart 1.1, group by zone) | ✅ |
| Filter | `created_date`, `created_by` | ✅ |

**Grain:** per `tracking_id` per zone.

**GAP rõ ràng — Zone master_data**:
- `mv_psv_main.location_to_code` có nhưng KHÔNG đủ — Panasonic zone không trùng province code.
- "HN-DN" là inter-zone (Hà Nội → Đà Nẵng), suy ra cần CẶP (`location_from_code`, `location_to_code`) → zone label.
- **Đề xuất**: tạo bảng `panasonic_zone_master` (location_code, zone, route_type) bind cùng cluster ClickHouse, hoặc đẩy zone vào `psv_target` trigger MV từ JSON nếu Panasonic TMS có sẵn (cần check schema dbo_OPS_Optimizer.DataRun JSON).

**5. Edge case + empty state**
- Zone không có run → KHÔNG hiển thị bar (KHÔNG hiển thị 0%, dễ nhầm là VRP fail toàn bộ zone).
- Zone với < 10 trips trong window → hiển thị nhưng grey-out + tooltip "low sample (n=N)".
- Zone null (location_to_code không match master) → bucket "Unknown" cuối list, flag warning để IT fix master.

---

### Chart 1.3 — `Cost per CBM Trend` (vertical bar, daily)

**1. Audience + narrative intent**
- Audience: Planning Lead + Finance.
- Câu hỏi: "Sau khi planner chỉnh, chi phí/CBM lệch Auto bao nhiêu % mỗi ngày? → Tổng quan tác động tài chính."

**2. Chart type rationale**
- 🔴 **Critical critique**: PDF hiển thị bar chart cho time series — sai lựa chọn. Time series → dùng **line chart**. Bar chart cho daily với 20+ ngày làm mất pattern.
- 🔴 Sort theo % giá trị giảm dần (không theo thời gian) → KHÔNG đọc được trend, chỉ ra ranking ngày — vô nghĩa với metric trend.
- 🔴 KHÔNG có zero baseline đậm + KHÔNG có threshold band (e.g., ±5% acceptable drift).
- ✅ Fix đề xuất:
  - Đổi sang **line chart** sort by date asc.
  - Reference line at 0% (đậm) + band ±5% (mờ).
  - Color line theo điểm: green ≤ 5%, yellow 5–15%, red > 15%.
  - Action title: "Adjust làm tăng chi phí/CBM trung bình X% trong tháng (peak N% ngày dd/mm)".

**3. Layout hierarchy**
- L3 — Trend, full width dưới Chart 1.1 và 1.2.
- Filter ngữ cảnh: nhận date range chung của section.

**4. Data shape — `mv_psv_main`**

| Vai trò | Column | Status |
|---|---|---|
| Dimension X (date) | `toDate(created_date)` | ✅ |
| Measure | `%diff_cost_per_cbm = (cpc_adjusted - cpc_auto) / cpc_auto` per day | 🔴 GAP |
| | `cpc = SUM(total_cost) / SUM(total_cbm)` (per data_source) | partly ✅ |

**Công thức:**
```
cpc_auto      = SUM(total_cost where source=Auto)      / SUM(total_cbm where source=Auto)
cpc_adjusted  = SUM(total_cost where source=Adjusted)  / SUM(total_cbm where source=Adjusted)
%diff_per_day = (cpc_adjusted - cpc_auto) / cpc_auto
```

**🔴 GAP MAJOR — Auto baseline không tồn tại trong `mv_psv_main`**:
- 1 row trong mv_psv_main = trạng thái cuối. `total_cost` và `total_cbm` đều là post-adjustment.
- Không có cờ `data_source ∈ {Auto, Adjusted}`.
- 3 lựa chọn fix (xem §99):
  - **A. Bind `psv_target` (không FINAL)** + version-based pivot (MIN version = Auto baseline, MAX = Adjusted). Cần Panasonic TMS write Auto-save event trước Adjust-save event.
  - **B. Extend pipeline upstream**: thêm 2 cột `total_cost_auto`, `total_cbm_auto` vào `psv_target` từ JSON nếu OPS_Optimizer lưu cả 2 snapshot.
  - **C. Redesign**: bỏ Auto-vs-Adjusted, chỉ kể "Cost/CBM trend on Adjusted" (single source). Mất 60% giá trị insight của chart.

**5. Edge case + empty state**
- Ngày không có run → gap trong line (KHÔNG nội suy 0%).
- `cpc_auto = 0` (không có CBM auto) → return NULL, không divide-by-zero.
- Ngày có run nhưng tất cả là "No Change" → diff = 0% (display green band, không treat như missing data).

---

### Chart 1.4 — Process Efficiency Analysis (3 KPI cards + 1 stacked bar + 1 user table)

**1. Audience + narrative intent**
- Audience: Operations Manager + IT Adoption.
- Câu hỏi: "Mất bao lâu cho 1 phương án từ chuẩn bị data → adjust → gửi vendor? Ai chậm, ai nhanh?"

**2. Chart type rationale**
- 3 KPI cards (AVG Preparation/Adj Duration/Final Leadtime, đơn vị Min): ✅ fit cho top-line.
- Stacked bar "Time Spent by User" — ✅ fit để so sánh phân bổ 3 giai đoạn theo user.
- Table "User Name / Total Trip / Total Time" — ✅ secondary table.
- 🟡 Critique: 3 KPI không có target/threshold (target Adj Duration = bao nhiêu phút?). Hỏi PM xác lập.

**3. Layout hierarchy**
- L4 — Process detail, panel cuối Section 1.
- Independent: KHÔNG drill-down từ 1.1/1.2/1.3; có filter ngữ cảnh chung.

**4. Data shape — `mv_psv_main`**

| Metric | Công thức (confirmed từ §0.5 Apps Script) | Source columns | Status |
|---|---|---|---|
| AVG Preparation (Min) | (not computed by PM in fake data) | — | 🟢 DROP — PM đã skip metric này |
| AVG Adj Duration (Min) | `AVG(Final Save − Run Auto first)` per tender | event log (`Action Type`, `Action Timestamp`) | 🔴 GAP — cần event log; fallback từ `mv_psv_main`: `report_modified_date - created_date` |
| AVG Final Leadtime (Min) | `AVG(Send Tender − Final Save)` per tender | event log | 🔴 GAP — cần event log |
| Total Trip per User | `uniqExact(tracking_id) GROUP BY created_by` | `tracking_id`, `created_by` | ✅ |
| Total Time per User | sum của Adj Duration + Final Leadtime | event log | 🔴 GAP |

**Grain:** per `created_by`, per (tracking_id) trong window.

**🔴 GAP — chốt theo Apps Script mental model:**
- Cả 2 metric Adj Duration + Final Leadtime đều cần **event log table** với 3 event types (`Run Auto`, `Final Save`, `Send Tender`) — KHÔNG phải single-snapshot mv_psv_main.
- Fallback chấp nhận được cho v1: dùng `created_date` (≈ Run Auto event) và `report_modified_date` (≈ Final Save event) trong mv_psv_main → derive AVG Adj Duration. Vẫn miss AVG Final Leadtime hoàn toàn.
- Source khả dĩ event log: (a) audit/activity log của Panasonic TMS SQL Server (cần BA hỏi), (b) Smartlog activity log nếu planner thao tác qua Control Tower UI.
- **Đề xuất scope v1**: ship AVG Adj Duration (từ mv_psv_main fallback formula) + drop AVG Preparation + đánh dấu AVG Final Leadtime "Coming v2 pending event log integration".

**5. Edge case + empty state**
- User không có trip → loại khỏi stacked bar và table.
- Trip không edited (`is_trip_edit_manual=0`) → `report_modified_date IS NULL` → loại khỏi tính AVG Adj Duration.
- `report_modified_date < created_date` (datetime corrupt) → loại + flag data quality warning.

---

## SECTION 2 — Post-Adjustment Violation

### Chart 2.1 — `Constraint Violation Rate` (KPI card)

**1. Audience + narrative intent**
- Audience: Planning Lead + Operations.
- Câu hỏi: "Sau khi planner đã adjust, còn bao nhiêu % chuyến vi phạm ràng buộc? → Đánh giá chất lượng adjustment."

**2. Chart type rationale**
- KPI card 27.3% — ✅ fit. 🟡 Thiếu RAG threshold (mặc định: Green < 10%, Yellow 10–25%, Red ≥ 25%) → 27.3% nên đỏ.
- 🟡 Thiếu trend mini.

**3. Layout hierarchy**
- L1 — Hero của Section 2, top-left.
- Filter ngữ cảnh: section date range + planner.

**4. Data shape — `mv_psv_main`**

| Vai trò | Column | Status |
|---|---|---|
| Numerator | `countIf(constraint_name != '')` (per `tracking_id`) | ✅ |
| Denominator | `uniqExact(tracking_id)` total | ✅ |

**Công thức:**
```sql
SELECT
    countIf(any(constraint_name != ''))      AS trips_with_violation,
    uniqExact(tracking_id)                   AS total_trips,
    trips_with_violation * 100.0 / total_trips AS pct
FROM analytics_workspace.mv_psv_main
WHERE created_date BETWEEN {{date_from}} AND {{date_to}}
GROUP BY tracking_id;
-- (kết hợp 2 step: trip_level CTE + outer aggregate)
```

**Caveat:** `constraint_name` chứa multiple violations CSV (`'Fishbone, M…'`, `'Fishbone, 3D…'`). 1 trip có thể có nhiều violation → count vẫn là 1 trip với violation, KHÔNG splitByChar trừ khi muốn count distinct violation types.

**5. Edge case + empty state**
- Total = 0 → return `—`.
- Tất cả trips violation → 100% → display đỏ rực + alert.

---

### Chart 2.2 — `Violation Rate by Zone` (vertical bar)

**1. Audience + narrative intent**
- Audience: Planning Lead.
- Câu hỏi: "Zone nào hay vi phạm sau adjust? → Train planner theo zone hoặc tinh chỉnh constraint."

**2. Chart type rationale**
- Vertical bar sorted desc — ✅ fit. 🟡 Đề xuất horizontal bar nếu zone label dài (16 zones).
- ✅ RAG color đã dùng (orange) — keep nhưng nên gradient theo % (deep red ở top).
- Thiếu reference line for "section average" (= 27.3% từ Chart 2.1) → planner so sánh ngay zone vs trung bình.

**3. Layout hierarchy**
- L2 — Diagnostic, bên phải Chart 2.1.
- Drill: click zone → cascade xuống Chart 2.3 (filter category by zone).

**4. Data shape — `mv_psv_main`**

| Vai trò | Column | Status |
|---|---|---|
| Dimension X | `zone` (derived) | 🔴 GAP — xem §0.3 |
| Measure | `violation_rate per zone` | ✅ derive từ constraint_name |

**Grain:** per (tracking_id, zone).

**GAP:** Same as Chart 1.2 — Zone master_data.

**5. Edge case + empty state**
- Same as 1.2: hide zone không có trips; grey out zone với n < 10.

---

### Chart 2.3 — `Violation Count by Category` (vertical bar, sorted desc)

**1. Audience + narrative intent**
- Audience: Planning Lead + VRP Algorithm Owner.
- Câu hỏi: "Loại ràng buộc nào hay vi phạm nhất? Fishbone, 3D_loading, Break_time, PO_expired... → Đầu tư fix constraint nào trước?"

**2. Chart type rationale**
- ✅ Pareto-style bar (sorted desc) đúng pattern.
- 🔴 **Critical**: PDF show 20 categories với label dài bị truncate (`Fishbone, M…`, `Fishbone, Br…`). Khó đọc combinatorial categories.
- ✅ Fix: **split constraint_name CSV thành single-violation buckets** trước khi count. 1 trip với "Fishbone, 3D_loading" → +1 cho "Fishbone" và +1 cho "3D_loading".
- 🟡 Đề xuất: top-10 categories + bucket "Others" gộp phần đuôi.

**3. Layout hierarchy**
- L3 — Detail breakdown, bên trái Chart 2.4 (trend).

**4. Data shape — `mv_psv_main`**

| Vai trò | Column | Status |
|---|---|---|
| Dimension X | `arrayJoin(splitByChar(',', trim(constraint_name)))` | ✅ |
| Measure | `count()` per violation type | ✅ |

**Công thức (split + dedupe):**
```sql
SELECT
    trim(violation)                                AS constraint_violation,
    count()                                        AS record_count
FROM analytics_workspace.mv_psv_main
ARRAY JOIN splitByChar(',', constraint_name) AS violation
WHERE created_date BETWEEN {{date_from}} AND {{date_to}}
  AND constraint_name != ''
GROUP BY constraint_violation
ORDER BY record_count DESC
LIMIT 20;
```

**Note**: Đơn vị "Record Count" trong PDF nên đổi tên thành "Trip-Violation Count" — 1 trip có 2 violation count thành 2.

**5. Edge case + empty state**
- Không có violation nào → empty state "No constraints violated in selected period 🎉".
- Constraint_name chứa space hoặc i18n inconsistent (`Vượt quá tr…`, `Vi phạm trọ…`) → cần master_data về constraint code/label để chuẩn hoá. **GAP**: constraint catalog không có; hiện đang dùng raw string.

---

### Chart 2.4 — `Daily Violation Trend` (line chart)

**1. Audience + narrative intent**
- Audience: Planning Lead + Operations.
- Câu hỏi: "Vi phạm có spike vào ngày nào? Có pattern theo tuần/đầu tháng không?"

**2. Chart type rationale**
- ✅ Line chart cho time series — đúng (khác bar trong Chart 1.3).
- 🟡 Thiếu reference line cho average daily violations.
- 🟡 Đề xuất overlay với 1 dimension thứ 2: line phân tầng theo zone hoặc theo top-3 categories.

**3. Layout hierarchy**
- L4 — Trend, full width dưới Chart 2.3.

**4. Data shape — `mv_psv_main`**

| Vai trò | Column | Status |
|---|---|---|
| X | `toDate(created_date)` | ✅ |
| Y | `countIf(constraint_name != '')` | ✅ |

**Grain:** per day.

**5. Edge case + empty state**
- Day với 0 violation → vẫn show point at y=0 (KHÔNG gap, vì 0 violation = good story).
- Window > 90 days → switch sang weekly aggregation tự động.

---

## SECTION 3 — Vendor & Operation Impact

⚠️ **Section 3 toàn bộ phụ thuộc Auto vs Adjusted comparison** — đây là zone GAP nặng nhất. Critique tổng cho section: nên redesign nếu không có baseline data.

### Chart 3.1 — `Trip Change Matrix` (pivot table: Carrier Old → Carrier New)

**1. Audience + narrative intent**
- Audience: Procurement Lead + Planning Lead.
- Câu hỏi: "Planner đang swap vendor nào sang vendor nào? Carrier X bị thay nhiều nhất bằng carrier Y → vì sao?"

**2. Chart type rationale**
- ✅ Heatmap matrix cell-value pattern — đúng cho 2-dim comparison.
- 🟡 Critique: 9x11 cells, nhiều cell empty → đề xuất conditional formatting (heat color) thay vì plain number.
- 🟡 Đề xuất: thay matrix bằng Sankey diagram → trực quan hơn cho "flow" vendor swap.

**3. Layout hierarchy**
- L1 — Hero của Section 3, top-left full width.
- Drill: click cell → filter Section 3.3 (cost impact) + Section 4 (zone-level)

**4. Data shape — `mv_psv_main`**

| Vai trò | Column | Status |
|---|---|---|
| Dim row | `carrier_old = vendor_name_auto` | 🔴 GAP |
| Dim col | `carrier_new = vendor_name_adjusted` | 🔴 GAP |
| Measure | count of trips swapped | derive được nếu có 2 baseline |

**🔴 GAP MAJOR — vendor_name baseline:**
- `mv_psv_main.vendor_name` = vendor cuối cùng (Adjusted).
- Không có `vendor_name_auto`.
- → **Chart KHÔNG bind được mv_psv_main** trong thiết kế hiện tại.

**Hướng fix (xem §99):**
- A. Bind `psv_target` với version pivot: MIN(version) per (ops_optimize_id, tracking_id) = Auto save, MAX(version) = Adjusted save. Compare `vendor_name` giữa 2 version.
- B. Extend mv_psv_main thêm `vendor_name_original` (cần upstream lưu trong DataReport JSON).
- C. Redesign: thay matrix bằng "Vendor share trend over time" — single-source, vẫn show vendor mix shift nhưng KHÔNG link cụ thể old→new.

**5. Edge case + empty state**
- Trip không change vendor → KHÔNG include trong matrix (diagonal cells ẩn).
- Trip change nhưng cả 2 vendor đều null → loại.
- Vendor mới xuất hiện chỉ ở Adjusted (carrier_old = null) → đề xuất row "(New)" để show "vendor mới được thêm bao nhiêu chuyến".

---

### Chart 3.2 — `Vendor Allocation Ratio` (grouped bar: Auto vs Adjusted)

**1. Audience + narrative intent**
- Audience: Procurement + Planning Lead.
- Câu hỏi: "Vendor nào được Auto đề xuất nhiều nhưng bị planner cắt giảm? Vendor nào ngược lại?"

**2. Chart type rationale**
- ✅ Grouped bar (2 bars per vendor) — đúng pattern cho A vs B comparison.
- 🟡 Critique: thay vì 2 grouped bars riêng biệt, dùng **dumbbell chart** (2 chấm nối bằng line) → focus vào delta thay vì absolute %.

**3. Layout hierarchy**
- L2 — bên trái Chart 3.3 (Vendor Allocation by Zone).

**4. Data shape — `mv_psv_main`**

| Vai trò | Column | Status |
|---|---|---|
| Dim X | `vendor_name` | ✅ (final) |
| Measure auto | `total_trip_auto = uniqExact(tracking_id where source=Auto) / total` | 🔴 GAP — không có Auto baseline |
| Measure adj | `total_trip_adjusted = uniqExact(tracking_id where source=Adjusted) / total` | ✅ chỉ phần Adjusted |

**🔴 GAP same as Chart 3.1**: cần version-aware data. Hiện chỉ ship được Adjusted side.

**5. Edge case + empty state**
- Vendor xuất hiện 0% Auto, X% Adjusted → label "(Added)".
- Vendor xuất hiện X% Auto, 0% Adjusted → label "(Removed)".

---

### Chart 3.3 — `Vendor Allocation by Zone` (grouped bar by zone)

**1. Audience + narrative intent**
- Audience: Planning Lead + Procurement (zone-level).
- Câu hỏi: "Phân bổ trip theo zone trước vs sau adjust có lệch không?"

**2. Chart type rationale**
- 🟡 Critique: PDF dùng grouped bar % theo zone — khó so sánh khi có 17 zones x 2 bars = 34 bars chen chúc.
- 🔴 **Redesign đề xuất**: small multiples (1 mini chart per vendor, dim X = zone, 2 bars Auto vs Adjusted). Hoặc Sankey.

**3. Layout hierarchy**
- L3 — bên phải Chart 3.2.

**4. Data shape**
- Same GAP as Chart 3.2 + zone GAP (§0.3).
- 🔴 **Double GAP** — chart này phụ thuộc CẢ baseline lẫn zone master_data.

**5. Edge case + empty state**
- Zone không có vendor X → bỏ qua cell, không show 0%.

---

### Chart 3.4 — `Cost Impact by Vendor` (dual-axis: bar + line)

**1. Audience + narrative intent**
- Audience: Finance + Procurement.
- Câu hỏi: "Vendor nào sau adjust tốn thêm hoặc tiết kiệm chi phí? Drift %/CBM mỗi vendor là bao nhiêu?"

**2. Chart type rationale**
- 🔴 **Critical critique**: Dual-axis (bar VND for cost + line % for drift) — anti-pattern theo /da-storytelling-data principles. Khó so sánh 2 scale.
- ✅ Fix: **tách thành 2 chart**:
  - Chart A: horizontal bar `% Drift Cost per CBM` per vendor, sort by abs(drift) desc, color theo dấu.
  - Chart B: bar `Cost Variation (VND)` per vendor, sort by absolute variation desc.
- Hoặc giữ 1 chart: scatter (X = volume CBM, Y = drift %, bubble size = total fee).

**3. Layout hierarchy**
- L3 — full width dưới Chart 3.2/3.3.

**4. Data shape — `mv_psv_main`**

| Vai trò | Column | Status |
|---|---|---|
| Dim X | `vendor_name` | ✅ |
| Measure original fee | `total_cost_auto per vendor` | 🔴 GAP |
| Measure actual fee | `total_cost_adjusted per vendor` | ✅ (current `total_cost`) |
| Cost variation | `actual - original` | 🔴 GAP |
| % Drift Cost/CBM | `(cpc_adj - cpc_auto) / cpc_auto per vendor` | 🔴 GAP |

**🔴 GAP same source**: vendor-level Auto baseline. Same fix options §99.

**Tham số bổ sung:** vendor có thể thay đổi sau adjust → cần quyết định *group by vendor_name của Auto* hay *của Adjusted*. Đề xuất: vendor_name **Adjusted** (vendor cuối cùng giữ chuyến) — đó là vendor đang "chịu" chi phí thực tế.

**5. Edge case + empty state**
- Vendor không có CBM Auto → drift % undefined → display "—" + tooltip "no auto baseline".

---

### Chart 3.5 — `% Change Vendor by Zone` (pivot table heatmap)

**1. Audience + narrative intent**
- Audience: Planning Lead + Procurement.
- Câu hỏi: "Vendor X trong zone Y bị tăng/giảm bao nhiêu % so với Auto đề xuất?"

**2. Chart type rationale**
- ✅ Pivot heatmap — đúng pattern cho 2-dim % matrix.
- 🟡 Critique: nhiều cell "-" (no data) không phân biệt rõ với 0% → dùng grey cho NULL, divergent color (red-white-green) cho cell có giá trị.
- 🔴 Giá trị cực đoan như `-633.33%`, `1,100%` — outlier do mẫu nhỏ (1-2 chuyến). Đề xuất min threshold n ≥ 5 trips Auto trong cell mới hiển thị %.

**3. Layout hierarchy**
- L4 — Detail panel bên dưới 3.4.

**4. Data shape**
- Dim row: `vendor_name`. Dim col: `zone`. Cell: `(trip_adjusted - trip_auto) / trip_auto`.
- 🔴 **GAP triple**: baseline + zone + cell-level pivot.

**5. Edge case + empty state**
- `trip_auto = 0, trip_adjusted > 0` → not divide; display "(New)".
- Cell n < 5 → grey-out.

---

## SECTION 4 — Adjusted vs Auto by Zone

⚠️ **Toàn bộ section phụ thuộc Auto vs Adjusted baseline** — same GAP family as Section 3.

### Chart 4.1 — `Table: Summary Comparison` (2-row table, Auto vs Adjusted)

**1. Audience + narrative intent**
- Audience: BOD + Planning Lead.
- Câu hỏi: "Tổng CBM, tổng trip, tổng fee, cost/CBM — Auto vs Adjusted lệch bao nhiêu?"

**2. Chart type rationale**
- ✅ 2-row compact table — fit cho summary.
- 🟡 Critique: thiếu cột "Δ" (delta) và "% diff" — bắt user tính nhẩm. Đề xuất thêm 2 cột.

**3. Layout hierarchy**
- L1 — Hero của Section 4, top-left.

**4. Data shape**
- 4 cột: `total_cbm`, `trip_id (count)`, `total_fee`, `costPerCbm` × 2 source (Auto, Adjusted).
- Map vào mv_psv_main:
  - `total_cbm` = SUM(total_cbm) [Adjusted ✅, Auto 🔴 GAP]
  - `trip_id` = uniqExact(tracking_id) [Adjusted ✅, Auto 🔴 GAP]
  - `total_fee` = SUM(total_cost) [Adjusted ✅, Auto 🔴 GAP]
  - `costPerCbm` = total_fee / total_cbm [computed]

**🔴 GAP: Auto baseline cho 3 measures.** Same fix §99.

**5. Edge case + empty state**
- Cả 2 cột zero → display "No runs".

---

### Chart 4.2 — `Trip Variation by Zone` (vertical bar with signed %)

**1. Audience + narrative intent**
- Audience: Planning Lead.
- Câu hỏi: "Zone nào trip tăng/giảm nhiều nhất sau adjust?"

**2. Chart type rationale**
- ✅ Diverging bar chart with signed % — đúng pattern cho +/- comparison.
- 🟡 Critique: outlier `-100%` (HCM-DN) do mẫu nhỏ làm méo trục → thêm note hoặc cap visual.

**3. Layout hierarchy**
- L2 — bên dưới 4.1.

**4. Data shape — same as 3.5 trip-by-zone variation, GROUP BY zone only.**
- 🔴 **GAP**: baseline trip count per zone + zone master.

**5. Edge case + empty state**
- Same Chart 3.5 outlier handling.

---

### Chart 4.3 — `Total Saving/Loss` (vertical bar VND)

**1. Audience + narrative intent**
- Audience: Finance + BOD.
- Câu hỏi: "Tổng tiền adjust làm tiết kiệm/tốn thêm theo zone, đơn vị VND?"

**2. Chart type rationale**
- ✅ Bar chart sorted by value — đúng.
- 🟡 Critique: trục Y "Total Saving/Loss" thiếu đơn vị (VND? Triệu VND?). PDF show `4,428` đến `-46,856` — nếu là VND thì quá nhỏ (chỉ 46k VND), có thể là nghìn VND hoặc đơn vị khác — cần BA clarify.
- 🟡 Color theo dấu: green positive (saving), red negative (loss).

**3. Layout hierarchy**
- L3 — bên dưới 4.2.

**4. Data shape**
- `saving_loss_per_zone = SUM(total_cost_auto) - SUM(total_cost_adjusted)` per zone.
- 🔴 **GAP**: baseline + zone.

**5. Edge case + empty state**
- Zone net zero → hidden hoặc small bar at 0.

---

### Chart 4.4 — `Cost % Diff by Zone` (vertical bar with signed %)

**1. Audience + narrative intent**
- Audience: Planning Lead + Finance.
- Câu hỏi: "Cost/CBM zone nào đắt hơn / rẻ hơn sau adjust?"

**2. Chart type rationale**
- ✅ Diverging bar — đúng pattern.

**3. Layout hierarchy**
- L4 — dưới 4.3.

**4. Data shape**
- `(cpc_adj - cpc_auto) / cpc_auto per zone`.
- 🔴 **GAP**: same triple.

**5. Edge case + empty state**
- HCM-DN missing (n quá nhỏ) → bỏ qua, KHÔNG show 0%.

---

### Chart 4.5 — `Cost Efficiency Analysis` × 2 bubble charts (by Zone & by Vendor)

**1. Audience + narrative intent**
- Audience: Procurement + Planning Strategy.
- Câu hỏi: "Cụm zone/vendor nào volume cao + cost/CBM hợp lý (sweet spot)? Cụm nào volume thấp + cost cao (cần renegotiate)?"

**2. Chart type rationale**
- ✅ Bubble chart 3 dim (X = volume CBM, Y = cost/CBM, size = trip count) — đúng pattern strategic 2x2 matrix.
- 🟢 PDF description tốt: "target top-left quadrant for negotiation". Keep.
- 🟡 Critique: thiếu quadrant lines (median lines chia 4 góc) — user phải mental compute.
- 🟡 Bubble color hiện random (nhiều màu) → đề xuất 1 hue family, transparency 60%.

**3. Layout hierarchy**
- L5 — pair charts (zone + vendor) cạnh nhau.

**4. Data shape — `mv_psv_main`**

| Vai trò | Column | Status |
|---|---|---|
| X | `SUM(total_cbm)` per zone/vendor (Adjusted) | ✅ (one-sided) |
| Y | `SUM(total_cost) / SUM(total_cbm)` per zone/vendor | ✅ (one-sided) |
| Bubble size | `uniqExact(tracking_id)` Auto (size = "Total Trip Auto" trong PDF) | 🔴 GAP — bubble size hiện ref Auto count |

**Note**: Bubble chart KHÔNG cần baseline cho X/Y (chỉ là current Adjusted state), nhưng PDF design dùng `total_trip_auto` cho size. Đề xuất:
- v1: dùng `uniqExact(tracking_id)` Adjusted cho size → KHÔNG GAP, vẫn ship được.
- v2: switch sang Auto khi có baseline data.

**Zone GAP:** same as §0.3.

**5. Edge case + empty state**
- Zone/vendor với CBM = 0 → loại khỏi chart (không thể plot Y).
- 1-2 outlier vendor với cost/CBM siêu cao → cân nhắc log scale trục Y.

---

### Chart 4.6 — `Table: Summary Metrics by Prov` (heatmap table)

**1. Audience + narrative intent**
- Audience: Planning Lead (deep-dive).
- Câu hỏi: "Số liệu chi tiết Auto vs Adjusted theo zone — để tham chiếu / export."

**2. Chart type rationale**
- ✅ Conditional formatting table — fit cho drill-down detail.
- 🟢 Keep heatmap intensity by value within column.
- 🟡 Critique: thiếu sort interactivity (user click cột để sort).

**3. Layout hierarchy**
- L6 — full width bottom of Section 4. Drill-down support cho 4.1–4.5.

**4. Data shape**
- Cùng 4 cột × 2 source × zone dimension. **🔴 GAP**: baseline + zone.

**5. Edge case + empty state**
- Zone không có data Auto + có Adjusted → display Adjusted columns + dash Auto columns.

---

## SECTION 5 — Autolog

⚠️ Section này về **adoption + run reliability**, không phải VRP accuracy. Cân nhắc tách thành section riêng `psv-adoption-vrp` thay vì gộp vào `psv-accuracy-vrp` — narrative scope khác audience.

### Chart 5.1 — `Daily Auto Runs & Conversion Rate` (bar + overlay line, per user)

**1. Audience + narrative intent**
- Audience: Operations Manager + IT Adoption.
- Câu hỏi: "User nào chạy Autoplan nhiều nhất? Có chuyển được phương án Auto thành dispatch không (Conversion = % SendVendor)?"

**2. Chart type rationale**
- 🔴 PDF: bar + overlay line per user — dual-axis on same chart, anti-pattern. Conversion rate gần như flat 100% trong PDF → không có thông tin.
- ✅ Fix: 2 chart riêng (1 bar count + 1 KPI conversion rate aggregate).

**3. Layout hierarchy**
- L1 — Hero Section 5.

**4. Data shape — `mv_psv_main`**

| Vai trò | Column | Status |
|---|---|---|
| User | `created_by` | ✅ |
| Total runs | `uniqExact(ops_optimize_id)` ⚠️ | 🟡 `ops_optimize_id` không có trong mv_psv_main (chỉ ở psv_target) |
| Conversion (`SendVendor`) | dispatch event after save | 🔴 GAP — KHÔNG có timestamp dispatch |

**🔴 GAP 2 cái:**
- `ops_optimize_id` — không expose qua mv_psv_main. Hiện chỉ có `tracking_id`. **Đề xuất**: thêm `ops_optimize_id` vào mv_psv_main (rẻ, chỉ là pass-through). Hoặc bind chart 5 vào `psv_target FINAL` thay vì mv_psv_main.
- `SendVendor` event — không có trong PSV pipeline. Confirmed từ §0.5 Apps Script: PM mental model là event log với action `Send Tender`. Source thực sự ở Panasonic TMS audit log (cần BA xác minh table cụ thể) — KHÔNG derive được từ snapshot.

**5. Edge case + empty state**
- User không có run → loại khỏi chart.
- User là test account (`@gosmartlog.com`) → flag exclude theo default filter; checkbox include test.

---

### Chart 5.2 — `Hourly Run Distribution`

**1. Audience + narrative intent**
- Audience: Operations Manager.
- Câu hỏi: "Peak hour của Autoplan là khi nào? Để planning ca trực hỗ trợ."

**2. Chart type rationale**
- 🔴 PDF show "System Error" — chart chưa render được. Không có gì để critique.
- ✅ Design đề xuất: stacked area chart hoặc heatmap (X = hour 0-23, Y = day-of-week, Z = run count).

**3. Layout hierarchy**
- L2 — bên dưới 5.1.

**4. Data shape — `mv_psv_main`**
- `toHour(created_date)` ✅
- `count()` hoặc `uniqExact(ops_optimize_id)` — 🟡 cùng GAP Chart 5.1 nếu dùng ops_optimize_id.

**5. Edge case + empty state**
- Out-of-hours runs (e.g., 2 AM) → keep, có thể flag warning "off-hours activity".

---

### Chart 5.3 — `Daily Active Users (DAU)`

**1. Audience + narrative intent**
- Audience: IT Adoption + Operations.
- Câu hỏi: "Adoption metric — bao nhiêu user/ngày dùng Autoplan?"

**2. Chart type rationale**
- ✅ Line chart cho time series — đúng.
- 🟡 Critique: thiếu MA-7 (7-day moving average) để smooth noise daily.
- 🟡 Reference: tổng số planner active trong Panasonic (e.g., 8 users) → vẽ horizontal line for "100% adoption".

**3. Layout hierarchy**
- L3 — full width.

**4. Data shape — `mv_psv_main`**

| Vai trò | Column | Status |
|---|---|---|
| X | `toDate(created_date)` | ✅ |
| Y | `uniqExact(created_by)` | ✅ |

**5. Edge case + empty state**
- Weekend với 0 user → hiển thị 0 (data point), KHÔNG gap.
- Holiday → 0 user là expected, không alert.

---

### Chart 5.4 — `Run Success Rate` (bar + line per user)

**1. Audience + narrative intent**
- Audience: IT Adoption + Operations.
- Câu hỏi: "User nào có tỷ lệ run thành công thấp → cần training hoặc fix data input."

**2. Chart type rationale**
- 🟡 Same dual-axis critique như 5.1.
- 🔴 Định nghĩa "Success" không rõ trong PDF — "Total Run" vs "% Success" → success = run nào? Có data_report? Có save? Có dispatch?

**3. Layout hierarchy**
- L4 — bottom Section 5.

**4. Data shape — `mv_psv_main`**

| Vai trò | Column | Status |
|---|---|---|
| User | `created_by` | ✅ |
| Total runs | `uniqExact(ops_optimize_id)` | 🟡 GAP — same Chart 5.1 |
| Success runs | định nghĩa = ? | 🔴 GAP — cần BA define |

**🔴 GAP business definition**: §0.5 Apps Script cho thấy PM mental model = field `Run Status` per Run Auto event (likely values `Success / Failure / Timeout`). Hiện `mv_psv_trigger` KHÔNG extract field này từ `dbo.OPS_Optimizer.DataRun` JSON — cần check JSON có field `Status` không, hoặc nằm ở sister table.

3 candidate definition cho real pipeline:
1. Run có `data_report = true` → algorithm trả ra kết quả (fallback nếu không có Status field).
2. Run được save (`is_save = true`) — derivable.
3. Run có `Status = 'Success'` từ source JSON/sister table — match PM mental model nhất.

**Đề xuất v1**: bind theo Status field nếu có; nếu không thì fallback #1. BA cần xác minh source field cho Status.

**5. Edge case + empty state**
- User 100% success với chỉ 2 runs (`psvsp15`, `psvsp6` trong PDF) → flag low-sample warning.

---

## §99. Khoảng cách dữ liệu — Tổng hợp & Hướng xử lý

### Bảng tổng GAP

| # | Chart | GAP chính | Severity |
|---|---|---|---|
| 1.2, 2.2, 3.3, 3.5, 4.2, 4.3, 4.4, 4.5, 4.6 | by-Zone | Zone master_data (location → zone, route_type) | 🔴 Critical — block 9 charts |
| 1.3, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.6 | Auto vs Adjusted | Không có Auto baseline trong mv_psv_main (PM mental model: 2-column side-by-side per §0.5) | 🔴 Critical — block 11 charts |
| 1.4, 5.1, 5.2, 5.4 | Process Efficiency + Autolog | Cần event log table 3 event types (Run Auto, Final Save, Send Tender) + Run Status — confirmed từ §0.5 | 🔴 Critical — block 4 charts |
| 5.4 | Success definition | Likely = field `Run Status` per §0.5; cần BA xác minh source | 🟡 Major |
| 2.3 | Constraint catalog | Không có master constraint code/label | 🟢 Minor — dùng raw string OK v1 |

### Hướng xử lý — 3 phương án cho Auto-vs-Adjusted GAP

**Option A — Bind `psv_target` (without FINAL) + version-based pivot.** Recommended.
- Logic: per (`ops_optimize_id`, `tracking_id`), MIN(`version`) = Auto save, MAX(`version`) = Adjusted final. So sánh `vendor_name`, `total_cost`, `total_cbm` giữa 2 version.
- ✅ Pro: KHÔNG cần thay đổi upstream. Mọi cột đã có.
- 🔴 Con: phụ thuộc Panasonic TMS workflow PHẢI có 2 save events riêng biệt (1 cho Auto, 1 cho Adjusted). Nếu user adjust trước khi save lần đầu → chỉ có 1 version → KHÔNG có baseline.
- 🔴 Con: cần verify với BA — hỏi: "Khi planner click Save trên Auto result KHÔNG chỉnh sửa, có insert row vào dbo.OPS_Optimizer không?"

**Option B — Extend pipeline upstream để materialize baseline columns.** Heavy.
- Logic: thêm `vendor_name_auto`, `total_cost_auto`, `total_cbm_auto`, etc. vào `psv_target` và `mv_psv_main`, lấy từ JSON `DataReport` field auto (nếu có) hoặc snapshot tại moment save lần đầu.
- ✅ Pro: 1 row 1 record clean, mọi chart join nội bộ.
- 🔴 Con: cần thay đổi `mv_psv_trigger`, regenerate `psv_target`, refresh `mv_psv_main` — risk pipeline downtime.
- 🔴 Con: phụ thuộc nguồn — Panasonic TMS có lưu Auto snapshot trong JSON `DataRun.DataReport` không?

**Option C — Redesign section, drop Auto-vs-Adjusted pillar.** Fallback.
- Logic: thay vì so sánh Auto vs Adjusted, kể câu chuyện "VRP output Adjusted" + "% adjusted vs no-change" only.
- ✅ Pro: ship được ngay với mv_psv_main hiện tại.
- 🔴 Con: mất 60–70% giá trị insight (no cost saving/loss story, no vendor swap analysis).
- 📌 Phù hợp: nếu deadline gấp, ship v1 truncated rồi mở v2 sau khi data pipeline ready.

**Đề xuất /ba kế tiếp:** chốt Option A vs B vs C với stakeholder Panasonic.

⚠️ **REVISED RECOMMENDATION** sau khi đọc §0.5 Apps Script:

PM mental model là **Option B + event log integration** — KHÔNG phải Option A. PM đã thiết kế fake data với:
- `total_fee` và `Original Total Fee` cùng tồn tại trên 1 row (= 2-column baseline).
- Event log table với 3 action types riêng biệt.

Nếu muốn match demo 1:1, hướng **B+event_log** match đúng business expectation:
1. Extend `psv_target` thêm `total_cost_auto`, `total_cbm_auto`, `vendor_name_auto` (source từ JSON nếu OPS_Optimizer lưu, hoặc capture tại Run Auto event).
2. Bổ sung event log table: từ Panasonic TMS audit/activity log hoặc Smartlog activity log.

Option A (version pivot) vẫn là **fallback** nếu Option B không khả thi (PM không có Auto baseline trong source JSON) — nhưng sẽ KHÔNG match mental model 1:1.

### Hướng xử lý — Zone GAP

- **Đề xuất cho /ba**: yêu cầu Panasonic cung cấp file CSV/Excel mapping `(location_code, zone, zone_type, route_type)`.
- Materialize thành bảng `analytics_workspace.panasonic_zone_master` (sharded copy hoặc dictionary).
- Hoặc: thêm `zone_to`, `zone_from`, `zone_pair` vào `psv_target` trigger MV nếu Panasonic TMS có sẵn trong JSON.

---

## §100. Next steps — Handoff cho /ba

1. **Resolve GAP §99 với stakeholder Panasonic** (questions refined sau khi đọc §0.5 Apps Script):
   - [ ] **Q1 — Auto baseline**: JSON `DataRun.DataReport` của `dbo.OPS_Optimizer` có lưu Auto-baseline values (fee/CBM/vendor) trước khi planner adjust, hay chỉ overwrite với Adjusted final? Nếu có → extend `mv_psv_trigger` để materialize `*_auto` columns (Option B).
   - [ ] **Q2 — Zone master**: Xin file CSV/Excel mapping `location → zone / zone_pair` mà PM đã dùng để populate cột Zone trong fake data. Materialize thành `analytics_workspace.panasonic_zone_master`.
   - [ ] **Q3 — Event log source**: Table nào trong Panasonic TMS SQL Server log các event `Run Auto`, `Final Save`, `Send Tender`? Có audit log / activity table tương ứng với `dbo.OPS_Optimizer` không? Nếu không → cân nhắc capture từ Smartlog Control Tower activity log nếu planner thao tác qua UI Smartlog.
   - [ ] **Q4 — Run Status**: Field `Run Status` per Run Auto event đến từ đâu? `dbo.OPS_Optimizer.DataRun` JSON có field Status không, hay nằm ở sister table? Values khả dĩ (`Success / Failure / Timeout`)?

2. **Scope v1 vs v2** (dựa trên answer các câu hỏi):
   - **Best case** (Q1=yes, Q2 có file, Q3 có table, Q4 có field): ship full 17 charts theo demo PDF.
   - **Likely case** (Q1=partial, Q2 có file, Q3 chỉ có Final Save = `report_modified_date`, Q4 derive từ `data_report`):
     - Section 1: ship Chart 1.1, 1.2; Chart 1.3 fallback Option A; Chart 1.4 chỉ ship AVG Adj Duration.
     - Section 2: ship full (không phụ thuộc baseline).
     - Section 3 & 4: cần baseline → ship sau khi extend pipeline.
     - Section 5: ship 5.3 (DAU) full; 5.1/5.2/5.4 cần event log + ops_optimize_id expose.
   - **Worst case** (no baseline, no event log): ship Section 1 partial + Section 2 full + Chart 5.3 only. Skip Sections 3, 4, và Charts 1.3, 1.4, 5.1, 5.2, 5.4.

3. **PRD content cần viết**:
   - Action title chuẩn cho từng chart (xem critique từng chart).
   - Filter chuẩn của section: date range, planner, zone (sau khi có zone master từ Q2).
   - RAG thresholds chuẩn cho Panasonic (Accuracy ≥ X%, Violation < Y%) — cần BA hỏi target chính thức.
   - Define "Success" cho Chart 5.4 từ Q4 answer.
   - Decision matrix Option B vs Option A vs Option C theo answer Q1.

4. **Memory rule**: bộ critique trên đã tuân thủ memory [feedback_no_v2_v3_filenames] — không đặt `mv_psv_main_v2`; mọi thay đổi đề xuất là on-pipeline upgrade.

---

## §101. ARTIFACT_PATH

`projects/panasonic/01-sections/psv-accuracy-vrp/analysis/storytelling-notes.md`

---

## Delivery Signal

```
STORYTELLING REVIEW COMPLETE
──────────────────────────────────
Mode          : C-Critique + A-Visualize
Section       : psv-accuracy-vrp (Panasonic PSV)
Audience      : BOD + Planning Lead + Operations + Procurement + IT Adoption (multi-tier)
──────────────────────────────────
Key decisions :
  - 17 charts critiqued across 5 sections
  - 3 cross-cutting GAPs: zone master, Auto baseline, event log
  - 11/17 charts blocked by Auto-vs-Adjusted GAP (Sections 3, 4 + Chart 1.3)
  - 9/17 charts blocked by zone GAP
  - 4/17 charts blocked by event log GAP (Charts 1.4, 5.1, 5.2, 5.4)
  - Revised recommended path: Option B (extend pipeline w/ baseline columns)
    + event log integration — matches PM mental model per §0.5 Apps Script
Issues found  : 3 critical, ~10 warning
Next step     : /ba clarify 4 refined questions in §100, then chốt scope v1
──────────────────────────────────
```
