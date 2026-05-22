# QA Execution Report — FEAT-128 (OTIF reorder + chart by category)

**Date:** 2026-05-12
**Executor:** /qa-executor
**Source:** [stub `[D]-FEAT-128-...`](../[D]-FEAT-128-otif-doi-thu-tu-charts-va-bo-sung-chart-loai-hang.md) §3 ACs + §4 edge cases
**Mode:** Mixed — static code verification + manual smoke checklist (executor không có browser access; manual gate cần user chạy `pnpm --prefix frontend dev` rồi observe)
**Build:** branch `fix-frontend-otif`, latest commit `d08e5b0`

---

## 1. Test cases

### Acceptance Criteria (từ stub §3)

| TC ID | AC | Verification mode | Result | Evidence |
|---|---|---|---|---|
| TC-01 | Thứ tự 9 sections render đúng §2.1 (Cards → Fail-reasons → Trend → Transporter → Category → SalesChannel → Warehouse → Area) | Code (static) + Manual (visual) | ⏸️ **Code-Pass / UI-Blocked** | JSX render order: line 1240 (FailOntime) → 1309 (FailInfull) → 1379 (ByTime) → 1497 (ByTransporter) → 1580 (ByCategory) → 1671 (BySalesChannel) → 1754 (ByWarehouse) → 1837 (ByArea). Match §2.1. Cần user observe trên dashboard. |
| TC-02 | "Lý do fail" hiển thị 2 chart Ontime/Infull side-by-side ở vị trí #3 | Code + Manual | ⏸️ **Code-Pass / UI-Blocked** | `<div className='grid grid-cols-1 gap-4 xl:grid-cols-2'>` [line 1238](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1238) bao 2 ChartCard (FailOntime + FailInfull). Stack vertical < xl, side-by-side ≥ xl. Verified by code; cần user observe trên ≥ xl viewport. |
| TC-03a | Chart by Category vị trí #6 — sort FRESH trước DRY theo OTIF_CATEGORY_ORDER | Code + Manual | ⏸️ **Code-Pass / UI-Blocked** | `OTIF_CATEGORY_ORDER` 7 priority [widget-otif.tsx:522-530](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L522-L530). Sort logic `byCategory.sort()` [line 949-954](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L949-L954) dùng `priority.get(name.toUpperCase())` ?? 99 → alpha fallback. Code đúng. |
| TC-03b | Chart by Category có ChartExportMenu (CSV/PNG) | Code + Manual | ⏸️ **Code-Pass / UI-Blocked** | `exportData={byCategory as ChartExportData[]}` + `exportFilename='otif-by-category'` [line 1583-1584](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1583-L1584). Same prop pattern với 7 chart khác → menu sẽ render. |
| TC-03c | Empty state khi sqlQueries.chartByCategory chưa config | Code + Manual | ⏸️ **Code-Pass / UI-Blocked** | Conditional branch [line 1586-1591](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1586-L1591): SQL configured + 0 rows → `t('orderMonitor.otif.noData')`; SQL chưa config → `t('orderMonitor.otif.categoryNoConfig')`. Cả 2 i18n key cần verify exists. |
| TC-03d | SQL invalid → error state bắt được, không crash widget | Manual only | ⏸️ **Blocked** | Cần user paste SQL syntax invalid → observe widget không crash, hiển thị error/empty. Code path `execSection` [line 833-842](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L833-L842) trả `[]` nếu `res.error` → byCategory.length === 0 → empty state. Suy luận: chart hiển thị "Không có dữ liệu" thay vì crash. |
| TC-04 | i18n key `orderMonitor.otif.chartByCategory` EN+VI | Code | ✅ **Pass** | EN: [`dashboard-order-monitor.json:171`](../../../../../frontend/src/i18n/locales/en/dashboard-order-monitor.json#L171) = `"OTIF by product type"`. VI: [`dashboard-order-monitor.json:154`](../../../../../frontend/src/i18n/locales/vi/dashboard-order-monitor.json#L154) = `"OTIF theo loại hàng"`. |
| TC-05 | Settings dialog có field SQL `chartByCategory` ở đúng nhóm "Charts SQL" | Code + Manual | ⏸️ **Code-Pass / UI-Blocked** | Section definition [widget-otif-settings-dialog.tsx:121-140](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif-settings-dialog.tsx#L121-L140) — key `chartByCategory`, label `By Category`, icon `BarChart3`, requiredColumns đúng. Order trong `OTIF_SECTIONS` array → render position trong dialog. Cần user mở dialog observe. |
| TC-06 | Existing 7 charts không regression (export filename, filter binding, drill-down handler) | Code + Manual | ⏸️ **Code-Pass / UI-Blocked** | Tất cả 7 chart cũ giữ nguyên `exportData` + `exportFilename` prop + `filterOverrides` binding (line 791-806 useMemo + line 856-863 execSection). Không đổi props. Cần user click qua các chart cũ verify export, filter behavior. |
| TC-07 | Filter `categoryFilter` ở filter bar vẫn lọc đúng cho chart mới | Code + Manual | ⏸️ **Code-Pass / UI-Blocked** | `filterOverrides.group_of_cargo` + `group_of_cago` (typo alias) cả 2 đều set theo `cargo` state [line 797-798](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L797-L798). r6 SQL có `{{group_of_cargo}}` placeholder + `arraySort([])` block → wire đúng. Cần user select cargo filter → confirm chart by category cập nhật. |

### Edge cases (từ stub §4)

| TC ID | Edge case | Verification mode | Result | Evidence |
|---|---|---|---|---|
| TC-E1 | User chưa config SQL chartByCategory → Empty state | Code + Manual | ⏸️ **Code-Pass / UI-Blocked** | Same path như TC-03c. Branch `sqlQueries?.chartByCategory?.trim()` falsy → render `t('categoryNoConfig')`. Các chart khác vẫn fetch độc lập (Promise.all không await reject). |
| TC-E2 | Source data chỉ có 1 category (vd DRY) → render 1 cột không vỡ layout | Manual only | ⏸️ **Blocked** | Recharts BarChart với 1 data point vẫn render 1 cột. Tooltip + Legend behave bình thường. Cần user filter category → verify. |
| TC-E3 | Category null/blank → bucket "(Không xác định)" hoặc filter out | Code | ✅ **Pass** | SQL r6 `coalesce(group_of_cago, 'Unclassified') AS category` [stub §5.2](../[D]-FEAT-128-otif-doi-thu-tu-charts-va-bo-sung-chart-loai-hang.md). FE byCategory map fallback `r.khuVucDoiXe \|\| '(Không xác định)'` [line 944](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L944). Coverage cả 2 tầng. |
| TC-E4 | Mobile responsive — 2 chart "Lý do fail" stack vertical < xl | Code + Manual | ⏸️ **Code-Pass / UI-Blocked** | `grid grid-cols-1 ... xl:grid-cols-2` [line 1238](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L1238). Tailwind breakpoint `xl` = 1280px. < 1280px → 1 cột (stack), ≥ 1280px → 2 cột. Cần user resize browser window verify. |

---

## 2. Manual smoke checklist cho user

Khi chạy `pnpm --prefix frontend dev` rồi mở widget OTIF dashboard, kiểm tra theo thứ tự:

### Pre-condition
- [ ] r6 SQL đã paste vào widget settings dialog field `chartByCategory` và Save (xem stub §5.2 cho SQL final)
- [ ] Mondelez tenant data có rows trong window date filter hiện tại

### Visual smoke (TC-01, TC-02, TC-03a, TC-03c, TC-04, TC-E2, TC-E4)
- [ ] Mở dashboard OTIF → quan sát thứ tự sections từ trên xuống: Filter → 4 KPI cards → 2 chart Lý do fail (Ontime + Infull side-by-side trên màn ≥1280px) → Chart Trend → Chart By Transporter → **Chart By Category (mới)** → Chart By Sales Channel → Chart By Warehouse → Chart By Area
- [ ] Chart By Category render với cột FRESH trước DRY, theo sau MOONCAKE/POSM-OFFBOM (nếu có data)
- [ ] Chuyển ngôn ngữ EN ↔ VI: title chart đổi giữa "OTIF by product type" / "OTIF theo loại hàng"
- [ ] Resize browser xuống < 1280px → 2 chart "Lý do fail" stack vertical (1 cột)
- [ ] Filter chỉ 1 category (vd DRY) → chart by category render 1 cột, không vỡ layout

### Behavioral smoke (TC-03b, TC-03d, TC-05, TC-06, TC-07, TC-E1)
- [ ] Click ChartExportMenu của Chart By Category → có option CSV + PNG; export thử CSV → file tên `otif-by-category.csv` (hoặc tương đương)
- [ ] Mở Settings → section "Charts SQL" → có field `By Category` (icon BarChart3, lime accent). Empty field → Save → reopen → chart hiển thị empty state với text `"orderMonitor.otif.categoryNoConfig"` (i18n key — text Việt/Anh tùy locale)
- [ ] Paste SQL invalid (vd `SELECT FROM`) vào field → Test SQL → expect error message, widget KHÔNG crash (các chart khác vẫn render)
- [ ] Filter bar → chọn 1 category (vd FRESH) → tất cả 8 chart trên dashboard cập nhật (Chart By Category trở thành 1 cột FRESH duy nhất)
- [ ] Click qua 7 chart cũ (KPI cards, Trend, Transporter, Sales Channel, Warehouse, Area, Fail-reasons) → export filename không đổi, filter binding hoạt động, không có console error

### Network/runtime smoke
- [ ] DevTools Network → load dashboard → có 8 request `executeWidget` (gồm cards + 7 chart sections + 1 chartByCategory mới)
- [ ] Mỗi request payload `filterOverrides` chứa: `whseid` (CSV nếu ALL hoặc 1 value), `area/group_of_cargo/transporter` (empty nếu ALL), `from_date/to_date/date_type`
- [ ] Response của chartByCategory request: rows chứa columns `category, total_so, ontime_so, infull_so, otif_so, pct_ontime, pct_infull, pct_otif`

---

## 3. Bugs phát hiện qua static analysis

**0 bugs found.** Code-side implementation đầy đủ cho mọi AC + edge case. r6 SQL user-verified working trên prod widget runtime (xem [audit r6](../../../../02-data/audit-results/s2-feat128-otif-chart-by-category-20260512.md) §LIVE VERIFICATION 3).

**i18n keys verified (post-execution check)**:
- `orderMonitor.otif.chartByCategory` ✅ EN line 171 / VI line 154
- `orderMonitor.otif.tooltipByCategory` ✅ EN line 307 / VI line 290
- `orderMonitor.otif.categoryNoConfig` ✅ EN line 172 ("SQL not configured for product type chart.") / VI line 155 ("Chưa cấu hình SQL cho chart theo loại hàng.")
- `orderMonitor.otif.noData` ✅ exists multiple instances trong dashboard-order-monitor namespace

→ TC-04 upgraded to **full Pass**. TC-03c empty-state branches có đủ string cho cả 2 nhánh.

**Caveat — chưa verify trên running browser:**
- ⚠️ Item TC-05 (settings dialog field): vị trí section trong dialog phụ thuộc thứ tự `OTIF_SECTIONS` array — `chartByCategory` ở index 5 (`cards/chartByArea/chartBySalesChannel/chartByTransporter/chartByWarehouse/chartByCategory/...`). Nếu PM/UX muốn position khác (vd. cuối list các chart) → adjust array order.

Nếu user manual smoke phát hiện bug → tạo bug report dưới folder `bugs/BUG-{NNN}.md` cùng đường dẫn này.

---

## 4. Pre-condition issues outstanding

| Item | Mức | Action |
|---|---|---|
| r6 SQL có save vào widget config production chưa? | Block release | User confirm — đã paste vào widget settings dialog → "Test SQL" pass → Save? |
| `date_type` literal mismatch: FE option `'ETA gửi thầu'` vs SQL CASE `'ETA gửi thầu (đơn)'` | Latent risk | r6 vẫn work theo user-verified (có thể `[[ ]]` drop block hoặc data đủ trải qua nhánh khác). Recommend QA verify với filter dateType active xem rows count consistent vs chart anh em. |
| PM admin: append vào [`backlog.md`](../../backlog.md) + [`by-team.md`](../../by-team.md) | Soft | Sau khi `[x]` → cần rerun `/da-triage` refresh index. |

---

## ARTIFACT_PATH
projects/mondelez/triage/discoveries/frontend-widget/qa-feat128/execution-report.md

## EXECUTION_STATUS
**Blocked** — static code verification pass cho 100% AC; UI runtime observation pending (executor không có browser access). Status sẽ chuyển sang **Pass** sau khi user complete manual smoke checklist §2.

## BUGS_FOUND
**0** (static analysis 0 critical/high/medium/low; manual smoke chưa run)

## REGRESSION_SAFE
**true** — code review không phát hiện regression: existing 7 chart giữ nguyên props (`exportData/exportFilename/filterOverrides binding`), không có file shared mutation đáng ngại. Cần user click qua 7 chart cũ để confirm khi smoke (TC-06).

## HEALTH_SCORE
**100** — formula: 100 − 0×25 − 0×15 − 0×8 − 0×3 = 100. **Caveat**: score này tính trên static analysis; manual smoke có thể giảm score nếu phát hiện bug.
