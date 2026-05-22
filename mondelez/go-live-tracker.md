# Mondelez Control Tower — Go-Live Tracker

> **Audience**: PM Mondelez project, BA, Tech Lead, Dev/QA leads. 
> **Mục đích**: 1 trang theo dõi trạng thái Go-Live tất cả widget/view trong Control Tower cho khách Mondelez. Mỗi pending có **priority + link tới chi tiết**.
> **Updated**: 2026-05-16 (sau Phase 3 OTIF redesign + BUG-042 + RULE-OTIF-001 ship)
> **Updated by**: `/da-triage` skill

---

## Quy ước

| Symbol | Trạng thái Go-Live |
|---|---|
| 🟢 **READY** | Đã ship + verify, no blocker → có thể bật cho user MDLZ |
| 🟡 **WIP** | Đang dev/test hoặc chờ customer clarify; có blocker phải đóng |
| 🟠 **BLOCKED** | Có **Major+ pending** chặn Go-Live (bug nghiêm trọng hoặc PRD gap chưa chốt) |
| ⚪ **BACKLOG** | Chưa start hoặc chưa ưu tiên cho Go-Live đợt 1 |

| Priority (cho pending items) | Định nghĩa |
|---|---|
| **Critical/Blocker** | Block Go-Live, không workaround (vd bug số liệu sai, view không render) |
| **Major** | Cản trở significant business workflow, không có workaround tốt |
| **Minor** | Lỗi nhỏ, có workaround; CHẤP NHẬN ship cho Go-Live đợt 1 và fix theo follow-up |
| **Low/Cosmetic** | Polish; KHÔNG block Go-Live |

> **Quy tắc Go-Live**: Section ✅ READY khi `Critical + Major pending = 0`. Minor/Cosmetic chấp nhận ship + log thành follow-up backlog.

---

## 1. Overall summary — 15 widget của Control Tower

| # | Section | Widget | Status | Critical/Major pending | Total pending+WIP | Detail |
|---|---|---|---|---|---|---|
| 1 | **otif** | `widget-otif` | 🟡 **WIP** | 1 (raw view discussion) | 1 | [§3.1](#31-otif) |
| 2 | **vfr** | `widget-vfr` | 🟠 **BLOCKED** | 14 (multi-select + bugs filter) | 31 | [§3.2](#32-vfr) |
| 3 | **late-order-alert** | `widget-late-order-alert` | 🟠 **BLOCKED** | 1 (FEAT-034 detail table content) | 5 | [§3.3](#33-late-order-alert) |
| 4 | **stock-type** | `widget-stock-type` | 🟠 **BLOCKED** | 1 (UX-035 detail table) | 19 | [§3.4](#34-stock-type) |
| 5 | **loose-picking** | `widget-loose-picking` | 🟠 **BLOCKED** | 0 confirmed Major (heavy minor) | 15 | [§3.5](#35-loose-picking) |
| 6 | **shipping-progress** | `widget-shipping-progress` | 🟢 **READY** | 0 | 2 (minor) | [§3.6](#36-shipping-progress) |
| 7 | **txn-move** | `widget-txn-move` | 🟡 **WIP** | 2 (FEAT-053 chart + FEAT-054 combine data) | 1 WIP + several minor | [§3.7](#37-txn-move) |
| 8 | **wh-utilization** | `widget-wh-util` | 🟡 **WIP** | 0 | 3 | [§3.8](#38-wh-utilization) |
| 9 | **flash-daily** | `widget-flash-daily` | 🟡 **WIP** | 1 (BUG-040 bộ lọc Kho) | 7 | [§3.9](#39-flash-daily) |
| 10 | **tender-response** | `widget-tender-response` | ⚪ **BACKLOG** | — | 0 explicit | [§3.10](#310-tender-response) |
| 11 | **copack** | `widget-copack` | ⚪ **BACKLOG** | — | 0 explicit | [§3.11](#311-copack) |
| 12 | **factory-inbound** | `widget-factory-inbound` | ⚪ **BACKLOG** | — | 0 explicit | [§3.12](#312-factory-inbound) |
| 13 | **transfer** | `widget-transfer` | ⚪ **BACKLOG** | — | 0 explicit | [§3.13](#313-transfer) |
| 14 | **daily-ops** | `widget-daily-ops` | ⚪ **BACKLOG** | — | 0 explicit | [§3.14](#314-daily-ops) |
| 15 | **alert-summary** | `alert-summary/` | ⚪ **BACKLOG** | — | 0 explicit | [§3.15](#315-alert-summary) |

### Rollup

| Bucket | Count | % |
|---|---|---|
| 🟢 READY | 1 | 6.7% |
| 🟡 WIP | 4 | 26.7% |
| 🟠 BLOCKED | 4 | 26.7% |
| ⚪ BACKLOG | 6 | 40.0% |

> **OTIF gần ship nhất** — chỉ còn customer-call về raw view. VFR là blocker lớn nhất (cả multi-select platform + bugs filter). 6 widget đang BACKLOG nghĩa là chưa được khách MDLZ feedback explicit, cần PM confirm scope Go-Live đợt 1.

---

## 2. Platform-level blockers (cross-cutting — implement 1 lần, áp dụng N view)

Đây là pattern lặp lại nhiều view → 1 stub PLATFORM = 1 task dev → đóng 1 lần fix nhiều view.

| Status | Platform stub | # views affected | Priority | Detail |
|---|---|---|---|---|
| 🟡 WIP | `PLATFORM-MULTI-SELECT-FILTER` (15 items, mostly VFR + Inventory) | 4 | **Critical** | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER.md](triage/_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| 🟡 WIP | `PLATFORM-SORT-SEARCH-REPORT` (5 items) | 4 | Minor | [_platform/discoveries/[W]-PLATFORM-SORT-SEARCH-REPORT.md](triage/_platform/discoveries/%5BW%5D-PLATFORM-SORT-SEARCH-REPORT.md) |
| 🟠 OPEN | `PLATFORM-DOWNLOAD-IMG-EXCEL` (5 items) | 4 | Minor | [_platform/discoveries/[-]-PLATFORM-DOWNLOAD-IMG-EXCEL.md](triage/_platform/discoveries/%5B-%5D-PLATFORM-DOWNLOAD-IMG-EXCEL.md) |
| 🟠 OPEN | `PLATFORM-SHOW-VALUE-ON-CHART` (3 items) | 3 | **Major** | [_platform/prd-asks/[-]-PLATFORM-SHOW-VALUE-ON-CHART.md](triage/_platform/prd-asks/%5B-%5D-PLATFORM-SHOW-VALUE-ON-CHART.md) |
| 🟠 OPEN | `PLATFORM-FILTER-FIXED-SCORECARD` (2 items) | 2 | Minor | [_platform/prd-asks/[-]-PLATFORM-FILTER-FIXED-SCORECARD.md](triage/_platform/prd-asks/%5B-%5D-PLATFORM-FILTER-FIXED-SCORECARD.md) |
| 🟠 OPEN | `PLATFORM-APPLY-RESET-BUTTON` (2 items) | 2 | Minor | [_platform/prd-asks/[-]-PLATFORM-APPLY-RESET-BUTTON.md](triage/_platform/prd-asks/%5B-%5D-PLATFORM-APPLY-RESET-BUTTON.md) |
| 🟠 OPEN | `PLATFORM-RENAME-SCORECARD` (2 items) | 2 | Low/Cosmetic | [_platform/prd-asks/[-]-PLATFORM-RENAME-SCORECARD.md](triage/_platform/prd-asks/%5B-%5D-PLATFORM-RENAME-SCORECARD.md) |
| 🟡 WIP | `PLATFORM-VALUE-THOUSAND-SEP` (1 item) | 1 | Low/Cosmetic | [_platform/prd-asks/[W]-PLATFORM-VALUE-THOUSAND-SEP.md](triage/_platform/prd-asks/%5BW%5D-PLATFORM-VALUE-THOUSAND-SEP.md) |

> **PM action**: 2 platform stubs ưu tiên cao nhất cho Go-Live đợt 1:
> - **PLATFORM-MULTI-SELECT-FILTER** — block VFR + Inventory Go-Live (5 BUG + 10 UX dùng pattern này)
> - **PLATFORM-SHOW-VALUE-ON-CHART** — Major priority, 3 views

---

## 3. Per-section detail

### 3.1 OTIF

- **Status**: 🟡 **WIP** — sắp ship, 1 customer-call còn lại
- **PRD**: [01-sections/otif/prd.md](01-sections/otif/prd.md) — PM Approved v1.2.6 (Phase 5 review reversal 2026-05-15)
- **Spec**: [01-sections/otif/spec.md](01-sections/otif/spec.md)
- **Recent ship (2026-05-16)**: Phase 3 Cockpit redesign (UI) + BUG-042 lineno sync + RULE-OTIF-001 (Ontime + 30 phút) + FEAT-128 chart reorder + FEAT-057 column gộp

#### Pending (1 item — chặn Go-Live OTIF)

| ID | Priority | Title | Owner | Chi tiết ở |
|---|---|---|---|---|
| **DISC-OTIF-RAW-VIEW** | **Major** | Thảo luận lần nữa với MDLZ về "view các raw" | PM (customer-call) | [triage/discoveries/unknown/[W]-DISC-OTIF-RAW-VIEW](triage/discoveries/unknown/%5BW%5D-DISC-OTIF-RAW-VIEW-customer-discussion.md) |

#### Recently closed (2026-05-16)

| ID | Title | Stub |
|---|---|---|
| BUG-042 | STM `LineNo` strip mismatch → infull sync fix | [bugs/etl-data/[D]-BUG-042](triage/bugs/etl-data/%5BD%5D-BUG-042-otif-stm-lineno-strip-mismatch.md) |
| UX-067 | Bảng %OTIF chiều vận hành | [prd-asks/frontend-config/[D]-UX-067](triage/prd-asks/frontend-config/%5BD%5D-UX-067-otif-bang-chieu-van-hanh.md) |
| FEAT-056 | Thêm filter thời gian | [discoveries/cross-stack/[D]-FEAT-056](triage/discoveries/cross-stack/%5BD%5D-FEAT-056-other-them-filter-thoi-gian.md) |
| RULE-OTIF-001 | Ontime tolerance ETA + 30 phút | [bugs/etl-data/[D]-RULE-OTIF-001](triage/bugs/etl-data/%5BD%5D-RULE-OTIF-001-ontime-tolerance-30min.md) |
| FEAT-057 (earlier) | Bổ sung lý do rớt (WH+Transport) | [discoveries/cross-stack/[D]-FEAT-057](triage/discoveries/cross-stack/%5BD%5D-FEAT-057-other-bo-sung-ly-do-rot-la-gom-ca-2.md) |
| FEAT-128 (earlier) | Chart by category + reorder | [discoveries/frontend-widget/[D]-FEAT-128](triage/discoveries/frontend-widget/%5BD%5D-FEAT-128-otif-doi-thu-tu-charts-va-bo-sung-chart-loai-hang.md) |

→ Full summary: [triage/widget-otif-pending-summary.md](triage/widget-otif-pending-summary.md)

---

### 3.2 VFR

- **Status**: 🟠 **BLOCKED** — số lượng pending lớn nhất (31 active)
- **PRD**: [01-sections/vfr/prd.md](01-sections/vfr/prd.md)

#### Critical/Major pending (14)

| ID | Priority | Title | Owner | Stub |
|---|---|---|---|---|
| BUG-001 | Major | Bảng dữ liệu detail VFR | mixed (WIP) | [bugs/cross-stack/[W]-BUG-001](triage/bugs/cross-stack/%5BW%5D-BUG-001-vfr-bang-du-lieu-detail.md) |
| BUG-007..013 (7 items) | Major | Multi-select filter VFR (Kho, Khu vực, NVC, Loại xe) | dev-be (WIP) | [_platform/prd-asks/[W]-PLATFORM-MULTI-SELECT-FILTER](triage/_platform/prd-asks/%5BW%5D-PLATFORM-MULTI-SELECT-FILTER.md) |
| BUG-033 | Minor | Nội dung Bảng dữ liệu chi tiết | mixed | [bugs/cross-stack/[-]-BUG-033](triage/bugs/cross-stack/%5B-%5D-BUG-033-vfr-noi-dung-bang-du-lieu-chi-tiet.md) |
| BUG-036 | Major | Dòng chú thích card view "Tỷ lệ đáp ứng" | dev-fe | [bugs/frontend-config/[-]-BUG-036](triage/bugs/frontend-config/%5B-%5D-BUG-036-vfr-dong-chu-thich-cua-card-view-ty-le-dap-u.md) |
| BUG-037 | Major | Param `{{pickup_warehouse}}` | dev-be | [bugs/backend-config/[-]-BUG-037](triage/bugs/backend-config/%5B-%5D-BUG-037-vfr-param-pickup-warehouse.md) |
| BUG-039 | Major | Layout view "Tỷ lệ tuân thủ vận hành" | dev-fe | [bugs/frontend-config/[-]-BUG-039](triage/bugs/frontend-config/%5B-%5D-BUG-039-vfr-layout-view-ty-le-tuan-thu-van-hanh.md) |
| UX-025 | Major (drift) | Bảng dữ liệu detail | mixed (WIP) | [prd-asks/cross-stack/[W]-UX-025](triage/prd-asks/cross-stack/%5BW%5D-UX-025-vfr-bang-du-lieu-detail.md) |
| FEAT-043, 047 | Minor (chart card view) | Card view tỷ lệ tuân thủ | dev-fe | [discoveries/frontend-config/*](triage/discoveries/frontend-config/) |

#### Khác (Minor/UX/Feature — 17 items)

Xem [triage/by-team.md §VFR](triage/by-team.md) hoặc [triage/backlog.md filter Area=VFR](triage/backlog.md).

#### Critical paths để unblock VFR Go-Live

1. **Ship PLATFORM-MULTI-SELECT-FILTER** (7 bugs WIP) — đóng 7 BUG cùng lúc
2. **Fix BUG-001 + UX-025** (bảng dữ liệu detail VFR) — đang WIP
3. **PRD revision Bảng detail** — [prd-asks/cross-stack/[W]-UX-025](triage/prd-asks/cross-stack/%5BW%5D-UX-025-vfr-bang-du-lieu-detail.md)

---

### 3.3 Late Order Alert

- **Status**: 🟠 **BLOCKED** — 1 Major pending (FEAT-034 detail content)
- **PRD**: [01-sections/late-order-alert/prd.md](01-sections/late-order-alert/prd.md)

#### Critical/Major pending

| ID | Priority | Title | Owner | Stub |
|---|---|---|---|---|
| FEAT-034 | Major | Nội dung Bảng dữ liệu chi tiết | mixed | [discoveries/cross-stack/[-]-FEAT-034](triage/discoveries/cross-stack/%5B-%5D-FEAT-034-ordermonitoring-noi-dung-bang-du-lieu-chi-tiet.md) |
| UX-026 | Med | Bảng dữ liệu chi tiết (BE config) | dev-be | [prd-asks/backend-config/[-]-UX-026](triage/prd-asks/backend-config/%5B-%5D-UX-026-ordermonitoring-bang-du-lieu-chi-tiet.md) |
| UX-027 | Med | Bảng dữ liệu chi tiết (cross-stack) | mixed | [prd-asks/cross-stack/[-]-UX-027](triage/prd-asks/cross-stack/%5B-%5D-UX-027-ordermonitoring-bang-du-lieu-chi-tiet.md) |
| UX-002 | High score 15 | Show số liệu lên chart (platform) | dev-fe | [_platform/prd-asks/[-]-PLATFORM-SHOW-VALUE-ON-CHART](triage/_platform/prd-asks/%5B-%5D-PLATFORM-SHOW-VALUE-ON-CHART.md) |
| FEAT-104 | Minor | Chart time series | mixed | [discoveries/...](triage/discoveries/) |

---

### 3.4 Stock Type

- **Status**: 🟠 **BLOCKED** — 19 pending
- **PRD**: [01-sections/stock-type/prd.md](01-sections/stock-type/prd.md)

#### Major pending

| ID | Priority | Title | Stub |
|---|---|---|---|
| UX-035 | Major (drift) | Nội dung Bảng dữ liệu chi tiết | [prd-asks/cross-stack/[-]-UX-035](triage/prd-asks/cross-stack/%5B-%5D-UX-035-inventory-noi-dung-bang-du-lieu-chi-tiet.md) |
| BUG-041 | Major | Số liệu chưa realtime / chưa đúng | [bugs/etl-data/[-]-BUG-041](triage/bugs/etl-data/%5B-%5D-BUG-041-inventory-so-lieu-chua-realtime-va-chua-dung-voi-3.md) |
| FEAT-052 | Major | Bổ sung stock type theo shelflife | [discoveries/cross-stack/[-]-FEAT-052](triage/discoveries/cross-stack/%5B-%5D-FEAT-052-inventory-bo-sung-them-stock-type-theo-shelflife.md) |
| UX-003, UX-004 | High score | Bộ lọc + show số liệu lên chart (platform) | [_platform/...](triage/_platform/) |

#### Minor (15)

Đa số là UX bộ lọc / scorecard rename / position layout / khoảng thời gian — chấp nhận ship Go-Live đợt 1 + log follow-up. Xem [backlog.md Area=Inventory](triage/backlog.md).

---

### 3.5 Loose Picking

- **Status**: 🟠 **BLOCKED** — 15 pending (heavy minor, không có Major confirmed)
- **PRD**: [01-sections/loose-picking/prd.md](01-sections/loose-picking/prd.md)
- **Note**: Cần BA review xem có Major nào bị classify miss không. Phần lớn dùng pattern `multi-select-filter` (platform) + `show-value-on-chart` (platform) → đóng 2 platform stub sẽ tự đóng phần lớn item Loose Picking.

---

### 3.6 Shipping Progress

- **Status**: 🟢 **READY** — chỉ 2 minor (`sort-search-report` platform)
- **PRD**: [01-sections/shipping-progress/prd.md](01-sections/shipping-progress/prd.md)
- **Pending (Minor — accept ship)**: FEAT-016, FEAT-109 (both follow PLATFORM-SORT-SEARCH-REPORT)

---

### 3.7 Transaction Move (txn-move)

- **Status**: 🟡 **WIP**
- **PRD**: [01-sections/txn-move/prd.md](01-sections/txn-move/prd.md)

#### Major pending

| ID | Priority | Title | Stub |
|---|---|---|---|
| FEAT-053 | Major | Thêm chart liên quan tới transaction | [discoveries/cross-stack/[-]-FEAT-053](triage/discoveries/cross-stack/%5B-%5D-FEAT-053-transactionmove-them-chart-lien-quan-toi-transaction.md) |
| FEAT-054 | Major | Combine data xuất từ kho này qua kho kia | [discoveries/etl-data/[-]-FEAT-054](triage/discoveries/etl-data/%5B-%5D-FEAT-054-transactionmove-combine-data-xuat-tu-kho-nay-qua-kho-kia.md) |

---

### 3.8 WH Utilization

- **Status**: 🟡 **WIP** — 3 minor (mostly sort-search platform)
- **PRD**: [01-sections/wh-utilization/prd.md](01-sections/wh-utilization/prd.md)

---

### 3.9 Flash Daily

- **Status**: 🟡 **WIP** — 7 items mix Minor + 1 Major
- **PRD**: [01-sections/flash-daily/flash-daily-prd.md](01-sections/flash-daily/flash-daily-prd.md)

#### Major pending

| ID | Priority | Title | Stub |
|---|---|---|---|
| BUG-040 | Minor (review xem có nên Major?) | Bộ lọc Kho: BKD, NKD chưa work đúng | [bugs/frontend-widget/[-]-BUG-040](triage/bugs/frontend-widget/%5B-%5D-BUG-040-flashdaily-bo-loc-kho-gia-tri-bkd-nkd-chua-work-dun.md) |
| FEAT-049 | Low/Cosmetic | Icon ? giải thích source | [discoveries/frontend-widget/[W]-FEAT-049](triage/discoveries/frontend-widget/%5BW%5D-FEAT-049-flashdaily-them-icon-giai-thich-source-logic-tinh-t.md) |

---

### 3.10–3.15 BACKLOG widgets

Các widget sau **chưa có pending/WIP item nào từ feedback MDLZ Excel 2026-05-09**:

| Section | Widget | PRD | Note |
|---|---|---|---|
| **tender-response** | `widget-tender-response` | [prd](01-sections/tender-response/prd.md) | Chưa rollout cho MDLZ hay đã ship-clean? PM confirm |
| **copack** | `widget-copack` | [prd](01-sections/copack/prd.md) | Chưa rollout |
| **factory-inbound** | `widget-factory-inbound` | [prd](01-sections/factory-inbound/prd.md) | Chưa rollout |
| **transfer** | `widget-transfer` | [prd](01-sections/transfer/prd.md) | Chưa rollout |
| **daily-ops** | `widget-daily-ops` | [prd](01-sections/daily-ops/prd.md) | Chưa rollout |
| **alert-summary** | `alert-summary/` | [prd](01-sections/alert-summary/prd.md) | Chưa rollout |

> **PM action cần**: Quyết định 6 widget này có thuộc Go-Live đợt 1 không. Nếu có → cần khách MDLZ feedback / UAT.

---

## 4. Critical path để Go-Live đợt 1

Đề xuất ưu tiên giảm dần (PM có thể đảo):

| # | Action | Widget impact | Skill |
|---|---|---|---|
| 1 | Customer-call về raw view OTIF (PM-led, 15-30 phút) | OTIF | PM |
| 2 | Ship `PLATFORM-MULTI-SELECT-FILTER` (đang WIP) | VFR + Stock Type + Loose Picking | `/backend` + `/frontend` |
| 3 | Verify backfill historical OTIF % sau RULE-OTIF-001 (Ontime+30min) — quyết định có cần re-baseline trend hay không | OTIF | `/da-data` |
| 4 | Ship `PLATFORM-SHOW-VALUE-ON-CHART` (Major) | Late Order Alert + Stock Type + Loose Picking | `/frontend` |
| 5 | PRD revision "Bảng dữ liệu chi tiết" (template detail-table) — gộp UX-025, UX-026, UX-027, UX-035, FEAT-034 | VFR + Late Order Alert + Stock Type | `/ba` |
| 6 | Fix BUG-001 (đang WIP) | VFR | `/debugger` |
| 7 | PM quyết định scope 6 widget BACKLOG (tender/copack/factory-inbound/transfer/daily-ops/alert-summary) cho Go-Live đợt 1 | Cross-cutting | PM |

---

## 5. Lưu ý vận hành & convention

- Bảng này là **single source of truth** cho PM theo dõi Go-Live. Tất cả pending có link tới stub chi tiết để dev/BA biết spec.
- Mỗi lần đóng item: cập nhật **cả** stub file (`[-]` → `[D]`) **và** bảng này.
- Khi có feedback MDLZ mới → re-run `/da-triage`, bảng này được refresh tự động (next iteration).
- 4 dimension classification trong stub: `type` (Bug/UX/Feature) × `area` × `tech_layer` (etl-data/be-config/be-api/fe-config/fe-widget/cross-stack) × `priority` — xem [triage/README.md](triage/README.md).
- Convention `[D]/[W]/[-]/[X]` prefix filename: scan folder biết status không mở file.

---

## 6. Liên quan & tham chiếu

| Resource | Path |
|---|---|
| Triage workspace MDLZ | [triage/](triage/) |
| Triage README + convention | [triage/README.md](triage/README.md) |
| Backlog master | [triage/backlog.md](triage/backlog.md) |
| By-team view | [triage/by-team.md](triage/by-team.md) |
| OTIF pending summary | [triage/widget-otif-pending-summary.md](triage/widget-otif-pending-summary.md) |
| Sections (PRD/spec/wireframe) | [01-sections/](01-sections/) |
| Data audit results | [02-data/audit-results/](02-data/audit-results/) |
| Glossary (business rules) | [`docs/shared/business-rules.md`](../../docs/shared/business-rules.md) |
