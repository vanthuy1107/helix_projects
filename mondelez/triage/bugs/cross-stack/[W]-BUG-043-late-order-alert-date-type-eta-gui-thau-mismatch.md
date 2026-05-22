# BUG-043: Late Order Alert — filter "ETA gửi thầu" trả về 0 chuyến (silently empty)

## ⏸ LOCKED 2026-05-21 — PM decision

> **Status**: LOCKED / Waiting (PM "Vẫn giữ ETA gửi thầu (đơn)" + "NO" cho cross-widget extend + "fix sau"). LOA scope RESOLVED tại commit `feat-vfr-late-alert` 2026-05-21; cross-widget cleanup defer.
>
> **PM decision recap**:
> 1. Canonical value = `'ETA gửi thầu (đơn)'` với `(đơn)` suffix (MDLZ legacy)
> 2. KHÔNG fix MV / runtime / registry — đều đã canonical sẵn (Step 1 doc claim không match reality, không action)
> 3. LOA FE đã update 1 dòng 2026-05-21 → 4-way coherent
> 4. **NO extend cho OTIF + Flash Daily + order-monitor-api** — PM sẽ tự fix sau (separate effort/tenant decision)
>
> **Next review trigger**: khi PM cleanup cross-widget hoặc khi tenant khác RS deploy LOA/OTIF/Flash Daily (RS không có suffix → cần datatype decoupling Option C của BUG-043).

---

- **Source**: Phát hiện qua `/ba-review` audit ngày 2026-05-19 trên [late-order-alert-spec.md §7 anomaly A1](../../../01-sections/late-order-alert/late-order-alert-spec.md#7-known-anomalies--issues-locked-for-fix)
- **Reporter**: PM/DA (squad1@gosmartlog.com)
- **Tenant**: MDLZ (ClickHouse stack)
- **Area**: Late Order Alert widget (`WidgetLateOrderAlert`)
- **Severity**: Sev1 — sai số liệu, mất chức năng filter
- **Priority**: **Critical** — option mặc định thứ 2 của filter `Loại ngày` silently trả 0 chuyến (resolved LOA, locked rest)
- **Triage confidence**: High — verified bằng đối chiếu code + sql-registry + live MV query 2026-05-21
- **View**: Dashboard → Late Order Alert (cả tab Chart và Chi tiết bảng) — LOA resolved 2026-05-21
- **Tech layer**: `cross-stack` — drift giữa FE constant và registry CH SQL
- **Owner team**: `dev-fe` cho cross-widget extend (PM decides when)
- **Status**: ⏸ **LOCKED — Waiting PM** cho cross-widget extend

## Repro steps

1. Đăng nhập tenant Mondelez (CH stack).
2. Mở dashboard có widget **Late Order Alert**.
3. Trên filter bar, mở dropdown **Loại ngày** → chọn `ETA gửi thầu`.
4. Chọn date range bất kỳ có dữ liệu (vd 7 ngày gần nhất).
5. Observe: KPI cards về 0, donut chart trống, transporter chart trống, bảng chi tiết empty.
6. Đổi lại **Loại ngày** = `Ngày gửi thầu` → data trở lại bình thường.

## Expected

Khi chọn `ETA gửi thầu`, widget filter theo `eta_giao_hang_cho_npp` (ETA giao hàng cho NPP) — trả ra đúng các chuyến có ETA trong date range.

## Actual

Widget trả về 0 rows mọi nơi. Không có error message — user không biết là bug, có thể nhầm với "thực tế 0 chuyến trong khoảng" (làm trầm trọng thêm bởi anomaly A5 silent ZERO_SCORECARD).

## Root cause

FE [widget-late-order-alert.tsx:76-79](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L76-L79):

```ts
const DATE_TYPE_OPTIONS = [
  { value: 'Ngày gửi thầu', i18nKey: 'dateTypeNgayGuiThau' },
  { value: 'ETA gửi thầu', i18nKey: 'dateTypeEtaGuiThau' },
]
```

→ FE gửi `filterOverrides.date_type = 'ETA gửi thầu'` xuống backend.

Registry ClickHouse SQL ([sql-registry.md `## Cảnh báo đơn trễ → Scorecard Tất cả` CH branch](../../02-data/data-sources/sql-registry.md), ~line 20567):

```sql
CASE
  WHEN {{date_type}} = 'ETA gửi thầu (đơn)' THEN t.eta_giao_hang_cho_npp
  WHEN {{date_type}} = 'Ngày gửi thầu'      THEN t.thoi_gian_gui_thau
  -- ... 6 nhánh khác (ETD chuyến, ETA chuyến, ATD chuyến, ATA chuyến, request_date, approved_date)
END
```

→ Value `'ETA gửi thầu'` (không có suffix `(đơn)`) **không match nhánh nào** → CASE trả NULL → `toDate(NULL)` → row bị BETWEEN clause loại → zero rows.

Note: Registry Redshift SQL match `'ETA gửi thầu'` (không suffix) — RS tenant chạy đúng. Bug chỉ trigger trên CH stack (Mondelez + bất kỳ tenant nào dùng CH).

## Fix options

| Option | Thay đổi | Pros | Cons |
|--------|----------|------|------|
| **(A) Sửa FE value** | `'ETA gửi thầu'` → `'ETA gửi thầu (đơn)'` trong `DATE_TYPE_OPTIONS[1]` | 1-file change, FE-only | Phá RS tenant (RS branch không có suffix `(đơn)`); UI label cần tách value/label nếu muốn user thấy `ETA gửi thầu` |
| **(B) Sửa registry + runtime SQL** | Drop suffix `(đơn)` ở registry CH + cập nhật `widget.config.queries.{scorecard,detail}` đang lưu trên DB của tenant Mondelez | Match được cả CH+RS+FE, giữ label đơn giản | Cần DB write trên widget.config (qua Settings dialog admin hoặc SQL migration), nhiều surface area hơn |
| **(C) Decouple label/value** | FE đổi value sang code (`'eta_gui_thau_don'`), label giữ `'ETA gửi thầu'`; registry CH+RS đổi nhánh CASE sang match code | Cleanest, không phụ thuộc Vietnamese string match | Lớn nhất scope, phải đụng cả registry + runtime SQL + FE i18n |

## Recommended fix

**Option (B)** — sửa registry CH drop suffix `(đơn)`, đồng thời update runtime `widget.config` của Mondelez tenant:

1. Edit [sql-registry.md](../../02-data/data-sources/sql-registry.md) — section `## Cảnh báo đơn trễ`: tất cả CH SQL CASE branch `'ETA gửi thầu (đơn)'` → `'ETA gửi thầu'` (Scorecard × 7, Donut, Report raw, Chart Cảnh báo theo NVT — verify tất cả).
2. Update widget.config của Mondelez tenant — paste lại 2 SQL (scorecard + detail) qua Settings dialog admin, hoặc gọi API `useUpdateV2Widget` với SQL đã sửa.
3. Verify: chọn `ETA gửi thầu` trên dashboard → data trả về đúng.

## Affected scope (CONFIRMED system-wide via grep audit 2026-05-19)

Pattern lặp lại trên **TẤT CẢ widget order-monitor + flash-report** chạy CH stack:

| FE widget | File | FE value gửi | Registry CH cũ | Status |
|-----------|------|---------------|----------------|--------|
| Late Order Alert | [widget-late-order-alert.tsx:78](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx#L78) | `'ETA gửi thầu'` | `'ETA gửi thầu (đơn)'` | FIXED in registry |
| OTIF | [widget-otif.tsx:531](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L531), :778, :1409 | `'ETA gửi thầu'` | `'ETA gửi thầu (đơn)'` | FIXED in registry |
| Flash Daily | [widget-flash-daily.tsx:114](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L114) | `'ETA gửi thầu'` | `'ETA gửi thầu (đơn)'` | FIXED in registry |
| VFR (suspected) | — | likely `'ETA gửi thầu'` | — | Pending audit |
| order-monitor-api default | [order-monitor-api.ts:353](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/order-monitor-api.ts#L353) | `'ETA gửi thầu'` | — | Fallback default, aligned |

**Total registry occurrences fixed**: 38 nhánh `'ETA gửi thầu (đơn)'` → `'ETA gửi thầu'` trên toàn `sql-registry.md`.

## Fix history & PM decision (2026-05-21)

### 2026-05-19 fix attempt (Option B — DROP suffix) — DOC CLAIM NOT ACTUALLY APPLIED

⚠ **Status correction 2026-05-21**: Step 1 claim ("replace_all 38 spots done") trong doc này **KHÔNG match file state thật**:
- Current grep `'ETA gửi thầu (đơn)'` trong sql-registry.md → **55 matches** (toàn bộ CH WHEN branches còn nguyên suffix)
- Current grep `'ETA gửi thầu'` (no suffix) trong CH WHEN branches → **0 matches**

→ Step 1 hoặc chưa từng apply lên disk, hoặc đã bị revert ở session sau. Registry CH variants **đã luôn luôn** giữ `(đơn)` suffix — consistent với MV + runtime state.

### 2026-05-21 PM decision: "Vẫn giữ ETA gửi thầu (đơn)"

PM canonical = `'ETA gửi thầu (đơn)'` (MDLZ legacy). Hợp thức hóa state thực tế hiện tại của 3 layer + chỉ cần 1 FE update.

| Layer | Value hiện tại | Match canonical? | Action |
|-------|----------------|------------------|--------|
| MV `mv_filter_date_type_alert` | `'ETA gửi thầu (đơn)'` | ✅ | NO-OP |
| Runtime `widget.config.queries` Mondelez tenant | `WHEN ... = 'ETA gửi thầu (đơn)'` | ✅ | NO-OP |
| Registry SQL `sql-registry.md` CH variants (55 spots) | `WHEN ... = 'ETA gửi thầu (đơn)'` | ✅ | NO-OP (Step 1 doc claim was inaccurate) |
| Registry SQL `sql-registry.md` RS variants | `WHEN ... = 'ETA gửi thầu'` (no suffix) | ✅ | NO-OP (RS originally không có suffix) |
| FE widget `DATE_TYPE_FALLBACK[1]` | `'ETA gửi thầu'` → `'ETA gửi thầu (đơn)'` | ✅ Updated 2026-05-21 | DONE |

### Cross-widget impact (need PM extend decision)

FE callsites khác vẫn dùng `'ETA gửi thầu'` (no suffix) — cần align cùng PM decision nếu apply globally:

| Widget | File | Status sau PM decision |
|--------|------|------------------------|
| Late Order Alert | [widget-late-order-alert.tsx](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx) | ✅ Updated 2026-05-21 (T3.4 scope) |
| OTIF | [widget-otif.tsx:531,778,1409](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L531) | ⏳ Pending PM decision extend |
| Flash Daily | [widget-flash-daily.tsx:114](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L114) | ⏳ Pending PM decision extend |
| order-monitor-api default | [order-monitor-api.ts:353](../../../../frontend/src/features/dashboard/components/widgets/order-monitor/order-monitor-api.ts#L353) | ⏳ Pending PM decision extend |

### Rollout sequence

1. ✅ Registry SQL CH variants — đã có `(đơn)` suffix (55 spots, verified).
2. ✅ MV keep as-is — no work.
3. ✅ Runtime widget.config keep as-is — no work.
4. ✅ FE LOA `DATE_TYPE_FALLBACK[1]` updated 2026-05-21 — no further work.
5. ⏳ PM confirm extend decision cho OTIF + Flash Daily + order-monitor-api.ts → update 4 FE callsites tương tự nếu YES.
6. ⏳ Re-handoff `/qa-executor` formal verification (LOA filter dateType end-to-end với value `'ETA gửi thầu (đơn)'`).

**LOA filter dateType status**: ✅ COHERENT 2026-05-21 — 4-way (MV + runtime + registry + FE) đều canonical `(đơn)`. Bug effectively RESOLVED cho widget LOA.

**Admin step thủ công cần làm trên Mondelez tenant**:

1. Login dashboard với account có quyền `editMode`.
2. Mỗi widget bị ảnh hưởng (Late Order Alert, OTIF, Flash Daily) → click nút "Setting Chart" (hoặc Settings dialog tương đương).
3. Mỗi section (scorecard, detail, donut, transporter chart, …):
   - Mở Monaco SQL editor
   - Copy canonical SQL mới từ [sql-registry.md](../../02-data/data-sources/sql-registry.md) section tương ứng
   - Paste vào editor
   - Click "Save"
4. Reload dashboard.
5. Test: chọn `Loại ngày = ETA gửi thầu` + date range có dữ liệu → verify scorecard cards hiển thị số > 0.

**Hoặc** (nhanh hơn): nhờ DA/DBA chạy 1 SQL UPDATE trên app DB (table `widgets` hoặc tương đương) — replace string `'ETA gửi thầu (đơn)'` → `'ETA gửi thầu'` trong column lưu config JSON. Cần verify schema trước khi chạy.

## Mitigation tạm thời (trước khi admin paste)

Tell users: tránh chọn `Loại ngày = ETA gửi thầu` trên Mondelez dashboard. Dùng `Ngày gửi thầu` thay thế cho tới khi step 2 hoàn tất.

## DEV note

Fix doc-side trong registry KHÔNG đủ — registry là source-of-truth doc, nhưng runtime SQL nằm trong `widget.config.queries` lưu DB. Bug chỉ resolve sau khi admin paste lại. Đây là pattern đã từng xảy ra với các widget khác — cần migration tool tự động sync registry → runtime widget.config.

## Status trong source

`RESOLVED for LOA 2026-05-21 — PM canonical = (đơn) suffix; all 4 layers coherent (MV + runtime + registry CH + FE). Cross-widget alignment for OTIF + Flash Daily + order-monitor-api pending PM extend decision.`

## Next

1. ✅ Registry SQL CH variants — already canonical (no work, Step 1 doc claim was inaccurate).
2. ✅ MV DDL — no work (Step 0 cancelled per PM).
3. ✅ Runtime widget.config Mondelez — no work (Step 2 cancelled per PM, đã canonical).
4. ✅ FE LOA widget — updated `DATE_TYPE_FALLBACK[1]` 2026-05-21.
5. ⏳ PM decision extend cho 3 FE callsite khác (OTIF + Flash Daily + order-monitor-api): nếu YES → 3 edits tương tự.
6. ⏳ Audit các MV `mv_filter_date_type_*` khác (`_dap_ung` / `_flashreport` / `_movement_transaction` / `_otif` / `_tien_do_xuat_hang` / `_vfr`) — check value convention có nhất quán không.
7. ⏳ Handoff `/qa-executor` formal verification LOA end-to-end với value `'ETA gửi thầu (đơn)'`.
8. ⏳ Lesson learnt: doc claim "fix done" cần verify state ngay sau khi apply — BUG-043 Step 1 doc-claim không match reality, hôm nay mới phát hiện 2 ngày sau. Log thành FEAT-{N} discovery: governance cho fix-doc-vs-reality sync.
