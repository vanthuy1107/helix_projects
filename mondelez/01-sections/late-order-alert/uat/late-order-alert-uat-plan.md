# UAT Plan — Late Order Alert (Mondelez)

| Trường | Giá trị |
|---|---|
| **Tenant** | Mondelez |
| **Section** | `01-sections/late-order-alert` |
| **Widget** | `WidgetLateOrderAlert` (gridKey `DSHLOAMNG01`) |
| **PRD reference** | [late-order-alert-prd.md](../late-order-alert-prd.md) (v1.0.1) |
| **Spec reference** | [late-order-alert-spec.md](../late-order-alert-spec.md) (v1.0.6) |
| **Source MV (CH)** | `analytics_workspace.mv_alert_late_do` + `mv_filter_*` family |
| **Stack** | B — ClickHouse `analytics_workspace` |
| **Tác giả UAT plan** | PM/DA via `/da-uat` |
| **Ngày tạo** | 2026-05-27 |
| **Trạng thái** | Mode A — Design (chờ golden file MDLZ) |

---

## 1. Phạm vi UAT

### 1.1 Trong phạm vi

Section Late Order Alert toàn bộ — 1 widget, 2 tab (Chart / Chi tiết bảng):

- **Tab Chart** — 8 KPI cards (1 Tổng + 7 status chia 3 nhóm) + 1 Donut chart + 1 Stacked Bar chart theo nhà vận tải.
- **Tab Chi tiết bảng** — Grid 11 cột visible-by-default, trip-level aggregation từ DO-level rows, sort theo alert priority asc.
- **Filter** — 6 filter (`whseid`, `region`, `group_name`, `transporter`, `dateType`, `dateRange`), persist localStorage, autoApply.
- **Settings dialog** (chỉ admin) — 2 SQL section (scorecard + detail), tùy chọn `groupedTable` (per spec §22.3).

### 1.2 Ngoài phạm vi

- Notification/email/SMS khi có chuyến trễ (thuộc module Monitors / Alerts khác).
- Cấu hình ngưỡng `45 phút` window At-risk (hardcode trong MV — tracked anomaly A3, ngoài widget).
- Drilldown 1 chuyến → trang chi tiết riêng (hiện chỉ có inline detail row).
- Phân tích root-cause `Late delivery` theo trip leg (multi-stop) — schema MV không có cột `is_last_leg`.
- Anomaly **A2, A4–A9** tracked trong spec §7 — UAT KHÔNG fail/pass dựa trên các anomaly này, chỉ note nếu Ops Mondelez quan tâm.
- Anomaly **A1** (date_type `(đơn)` suffix) — đã RESOLVED for LOA 2026-05-21. UAT TC-A03 verify lại để confirm 4-way coherent.

---

## 2. Mục tiêu nghiệm thu

Khách hàng (SC Manager Mondelez + Ops Manager) confirm:

1. **Đúng nghiệp vụ** — 7 trạng thái cảnh báo phân loại theo đúng cách Ops Mondelez hiểu "đơn trễ" (TG bắt buộc rời kho vs Giờ ra cổng vs ATA rời vs ETA NPP).
2. **Đúng số liệu** — Số chuyến đếm trên dashboard khớp với golden file MDLZ export từ hệ thống cũ (Excel daily tracker) trong tolerance.
3. **Đúng hành động** — Dashboard giúp Ops Manager phát hiện chuyến "cần can thiệp" trong < 30s khi mở app vào sáng (giờ peak quyết định xuất xe).
4. **Filter hoạt động** — 6 filter behavior đúng, đặc biệt `dateType` không gây silent 0 (regression check anomaly A1 sau fix 2026-05-21).
5. **Performance** — Filter combo + đổi dateRange < 3s response, load page < 5s.

---

## 3. Phân lớp test (4 layers)

| Lớp | Mục đích | Số TC dự kiến | Layer của storytelling |
|---|---|---|---|
| **A. Data Reconciliation** | Số dashboard có khớp golden file MDLZ + SQL raw không (3-source matrix) | 7-8 | L1 KPI + L2 Donut + L3 Bar + L4 Detail |
| **B. Business Logic** | Phân loại 7 status có đúng nghiệp vụ Ops MDLZ không (formula 3 mốc thời gian) | 6-7 | L1 KPI cards + L4 trip aggregation rules |
| **C. UX & Storytelling** | Khách đọc story Tổng → 3 nhóm → 7 status có ra quyết định "cần can thiệp ngay" không | 5-6 | L1 → L2 → L3 → L4 narrative |
| **D. Performance / Filter** | 6 filter combo + dateRange 2-year guard + localStorage persist + autoApply | 4-5 | Filter bar + autoApply lifecycle |

**Tổng**: 22-26 happy path + 4-6 edge case = **~28-30 TC**. Chi tiết case ở [late-order-alert-uat-cases.md](late-order-alert-uat-cases.md).

---

## 4. Tolerance threshold (CHỐT TRONG MODE A — KHÔNG đổi sau khi thấy số lệch)

LOA là **count-based**, KHÔNG có % metric như OTIF (delta thì có % share trên Donut nhưng derived).

| Loại metric | Tolerance | Rationale |
|---|---|---|
| **Số đếm tuyệt đối** (Tổng chuyến, 7 count status) | ≤ 1% (rounding up — min ±1 chuyến) | Count of trips qua `COUNT(DISTINCT so_chuyen)`, không có % rounding error |
| **Top N transporter** (5 NVT đầu trên Bar chart) | ≥ 4/5 tên match (thứ tự có thể lệch 1 bậc) | Sort theo total desc — tie-breaker khác giữa CH `ORDER BY` vs Excel sort là OK |
| **Donut chart 7 segment share %** | ≤ 0.5 percentage point per segment | Share = count_segment / total — derived, tolerance theo %share không phải count |
| **Trip aggregation** (1 trip có nhiều DO → 1 row) | 100% match priority rule (At risk + Late departure open + Late departure + Late delivery + Ontime departure + Normal + Ontime delivery) | Aggregation rule deterministic — không có tolerance, fail là fail |
| **Filter empty (ALL)** | Tổng trên dashboard = tổng SQL raw bypass filter | ALL phải thực sự ALL — không skew vì `[[...]]` block strip sai |
| **45-min At-risk window** | ±2 phút (do clock skew CH vs frontend) | Computed inside MV — tolerance nhỏ để chấp nhận server time drift |

Vượt tolerance VÀ chưa có root cause → defect **Severity tối thiểu Major**.

---

## 5. Pass criteria

Đối chiếu trong Mode E signoff:

| Tiêu chí | Threshold |
|---|---|
| Pass rate happy path (lớp A+B+C) | ≥ 95% |
| Pass rate edge case (lớp A timezone + lớp B aggregation tie-break) | ≥ 80% |
| Defect Critical open | **0** — block signoff |
| Defect Major open | ≤ 2 với mitigation plan đã được khách accept |
| Reconciliation matrix row pass | 100% trong tolerance (xem §4) |
| Performance: filter response | < 3s p95 |
| Performance: page load | < 5s p95 |
| Performance: detail tab open (5000 rows aggregate) | < 8s |

---

## 6. Pre-conditions (Mode B — pre-UAT prep)

Block UAT session nếu thiếu 1 trong các điều kiện sau:

| Pre-condition | Owner | Trạng thái |
|---|---|---|
| Golden file MDLZ export — Excel daily tracker chuyến + 7 status mapping (hoặc tương đương) | SC Manager / Ops Mondelez | ⏳ Pending — request gửi T-7 |
| Khách confirm canonical `dateType` value = `'ETA gửi thầu (đơn)'` với suffix | SC Manager | ⏳ Pending — verify trong dry-run |
| Khách confirm 45-min At-risk window cho Mondelez (OQ-01 trong PRD §11) | Ops Manager | ⏳ Pending — collect trong session |
| Widget config production đã có 2 SQL (scorecard + detail) khớp spec §22 | DA + admin tenant | ⏳ Verify trong dry-run B.2 |
| Test environment có data ổn định ≥ 7 ngày liền | DA | ⏳ Verify trên CH `analytics_workspace` 2026-05-27 |
| `mv_alert_late_do` không bị refresh giữa session (snapshot consistent) | DA + DevOps | ⏳ Lock refresh schedule trong session window |

Mode B dry-run output: `late-order-alert-uat-dryrun-{YYYY-MM-DD}.md` — fill 3-source reconciliation matrix, chạy trước T-1 → T-2.

---

## 7. Golden file spec cho khách

Gửi SC Manager Mondelez yêu cầu export:

### 7.1 Format

- **File**: Excel `.xlsx` hoặc CSV UTF-8
- **Tên file**: `MDLZ-late-trip-tracking-{YYYY-MM-DD}.xlsx`
- **1 row** = 1 chuyến (so_chuyen) — KHÔNG phải DO-level

### 7.2 Cột bắt buộc

| Cột | Header | Format | Note |
|---|---|---|---|
| 1 | `Số chuyến` | string | Khóa chính, dùng để cross-check với `so_chuyen` MV |
| 2 | `Kho xuất` | string | Match `whseid` sau standardize (BKD1/2/3, NKD, VN821, VN831) |
| 3 | `Khu vực giao` | string | Match `khu_vuc_doi_xe` |
| 4 | `Nhà vận tải` | string | Match `ten_ngan_nvt` |
| 5 | `Kênh bán hàng` | string | Match `group` |
| 6 | `TG bắt buộc rời kho` | datetime UTC+7 | yyyy-MM-dd HH:mm:ss |
| 7 | `Giờ ra cổng (ATD)` | datetime UTC+7 hoặc empty | empty = chưa ra cổng |
| 8 | `ATA rời (giao xong)` | datetime UTC+7 hoặc empty | empty = chưa giao xong |
| 9 | `ETA giao NPP` | datetime UTC+7 | Của DO ETA sớm nhất trong trip |
| 10 | `Trạng thái khách phân loại` | enum 7 status hoặc raw VN | Để cross-check với cột `alert_status` MV |

### 7.3 Filter + time window

Khớp chính xác filter sẽ dùng trong session UAT:

- `dateType = 'ETA gửi thầu (đơn)'` (suffix `(đơn)` per spec §2.1 PM decision 2026-05-21)
- `dateRange` = window snapshot ngày UAT (vd `2026-05-27 00:00:00` → `2026-05-27 23:59:59` UTC+7)
- `whseid = ALL`, `region = ALL`, `group_name = ALL`, `transporter = ALL` (single golden file ALL)
- Bổ sung 1 golden file với `whseid = 'BKD1'` để TC-D02 verify filter

### 7.4 Định nghĩa metric khách dùng

Yêu cầu SC Manager document:
- Khách định nghĩa "chuyến trễ" thế nào? (`ATA rời > ETA`? hay theo `phut_tre_giao_npp > 0`?)
- Cửa sổ At-risk khách quan tâm bao nhiêu phút? (45 phút có đúng không — OQ-01)
- 1 trip nhiều DO với alert khác nhau → khách chọn theo priority nào? (verify §5.3 PRD priority order)

**Block UAT** nếu khách chưa có Excel daily tracker đầy đủ — chuyển lớp B (Business Logic) lên trước với SQL raw làm chuẩn tạm.

---

## 8. Test environment

| Item | Giá trị |
|---|---|
| **Frontend URL** | `<staging-mondelez-dashboard-url>` (PM cấp T-2) |
| **Backend** | API staging có connection sang CH `analytics_workspace` |
| **Auth** | Login MDLZ SSO + role có `editMode` để TC-D05 verify Settings dialog |
| **Browser** | Chrome 130+ (primary), Edge 130+ (Mondelez team chuẩn) |
| **Resolution** | 1920×1080 (laptop SC Manager) + 1366×768 (laptop Ops floor) |
| **Data snapshot** | Live `mv_alert_late_do` — lock refresh trong session window |
| **Timezone client** | UTC+7 (Asia/Ho_Chi_Minh) |
| **Connection check** | `projects/mondelez/scripts/uat_late_order_alert_export.py --check-connection` (dry-run T-2) |

---

## 9. Roles & responsibilities

| Vai trò | Người (placeholder) | Trách nhiệm trong session |
|---|---|---|
| **Facilitator** (PM) | `<PM name>` | Drive session theo lớp A→B→C→D, log defect tại chỗ |
| **Data approver** (DA) | `<DA name>` | Chạy SQL raw cross-check khi khách phát hiện diff |
| **Business approver** (SC Manager MDLZ) | `<SC Manager name>` | Confirm Pass/Fail từng TC theo nghiệp vụ |
| **Ops Manager** (MDLZ) | `<Ops Manager name>` | Verify lớp B (logic 7 status) + lớp C (story L1→L4) |
| **WH Manager** (optional) | `<WH Manager name>` | Verify warehouse standardize + cửa sổ 45 phút At-risk |
| **Tech support standby** (DEV FE/BE) | `<DEV lead name>` | On standby cho defect Critical cần fix gấp |

---

## 10. Schedule (đề xuất)

| Phase | Ngày dự kiến | Action |
|---|---|---|
| T-7 | 2026-XX-XX | Send golden file spec đến SC Manager + lock UAT slot |
| T-3 | 2026-XX-XX | Receive golden file MDLZ — verify format đúng §7 |
| T-2 | 2026-XX-XX | Run script `uat_late_order_alert_export.py` → sinh Excel pack (8 sheet) |
| T-2 | 2026-XX-XX | PM + DA review Excel pack vs Golden file → identify diff |
| T-1 | 2026-XX-XX | Mode B dry-run report — chỉ vào session khi resolved/accepted/deferred |
| T-0 | 2026-XX-XX | Session UAT với khách (2-3h) — chạy 28 TC + 3-source reconcile |
| T+3 | 2026-XX-XX | Mode D retest round 1 (sau khi dev fix defect Major) |
| T+7 | 2026-XX-XX | Mode E signoff pack — bóc thuật ngữ kỹ thuật + ký |

---

## 11. Route handoff (defect → owner)

Khi defect phát sinh trong Mode C/D, route theo bảng dưới — PM/BA dùng skill không cần nhớ:

| Defect lớp | Triệu chứng | Handoff |
|---|---|---|
| **Lớp A** (số lệch + root cause là SQL/MV) | Scorecard count != golden file > 1% chuyến | `/da-ch` audit MV `mv_alert_late_do.alert_status` logic → dev squad CH owner fix DDL |
| **Lớp A** (số lệch + root cause là filter resolver) | `[[...]]` block strip sai khi ALL filter, hoặc `dateType` silent 0 | `/da-triage` → `/qa-executor` → dev FE (`WidgetFilterResolver` + `filterOverrides` memo) |
| **Lớp B** (logic priority sai) | Trip multi-DO nhưng alert hiển thị ≠ DO có priority cao nhất | `/da-trace` confirm drift PRD §5.3 ↔ widget → dev FE fix `detailTripRows` memo |
| **Lớp B** (definition sai vs nghiệp vụ) | Khách chỉ ra "Late departure" định nghĩa của họ khác — vd phải tính cả "Giờ vào dock" | `/ba` revision PRD §3.2 trước, sau đó dev squad fix |
| **Lớp C** (UX khó dùng nhưng đúng spec) | Khách không scan được story L1→L4 trong 30s | `/da-trace` confirm drift PRD §5.1 ↔ wireframe — có thể là spec drift, không phải bug |
| **Lớp D** (perf chậm) | Filter response > 3s p95 | Dev FE + DA — check page size 5000 vs DO/trip ratio + client-side derive cost |
| **Critical immediate** | Số silent về 0 / page crash / data leak cross-tenant | `/debugger` ngay tại session, dev squad standby fix |

---

## 12. Anomaly tracking trong UAT

Spec đã track 9 anomaly (A1 RESOLVED, A2–A9 LOCKED). Cách handle trong session:

| Anomaly | Action UAT |
|---|---|
| **A1** (dateType `(đơn)` suffix) | TC-A03 verify lại regression — nếu fail = re-open A1 |
| **A2** (requiredColumns validator gap) | OUT-OF-SCOPE UAT — note khi user vào Settings dialog, không count Fail |
| **A3** (45-min At-risk threshold hardcode) | OQ-01 — collect Ops Mondelez confirm; nếu khác 45 phút → file defect Lớp B Severity Major |
| **A4** (warehouse standardize hardcode) | OUT-OF-SCOPE UAT — chỉ note nếu user thêm warehouse mới |
| **A5** (ZERO_SCORECARD vs lỗi config) | TC-D03 verify hành vi khi SQL config trống — note nhưng không Fail UAT |
| **A6** (FE expose 2/8 dateType branches) | OQ-08 — Ops Mondelez có cần thêm 6 option khác không (ETD/ETA chuyến, ATD/ATA chuyến, request_date, approved_date) |
| **A7** (dateType default hardcode) | OUT-OF-SCOPE — single-tenant Mondelez nên không vấn đề |
| **A8** (i18n key namespace) | OUT-OF-SCOPE technical |
| **A9** (Setting Chart/Filter button i18n) | OUT-OF-SCOPE pattern-wide |

---

## 13. Lịch sử thay đổi

| Version | Ngày | Tác giả | Thay đổi |
|---|---|---|---|
| 1.0.0 | 2026-05-27 | PM/DA via `/da-uat` | Bản đầu tiên — scope toàn section, 4-layer 28 TC, tolerance count ≤1% + share ≤0.5pp + trip-agg 100%, golden file spec 10 cột, route handoff 6 nhóm defect, anomaly A1-A9 mapping |
