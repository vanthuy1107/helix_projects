# Flash Daily — Đề xuất trả lời 10 Open Questions

| Trường | Giá trị |
|--------|---------|
| **Version** | 0.2.0 (User-confirmed 2026-05-16) |
| **Ngày** | 2026-05-16 |
| **Tác giả** | DA-Biz-BA |
| **Tenant scope** | Mondelez Vietnam (single tenant) |
| **Phạm vi** | 10 OQ trong [`flash-daily-prd.md` §11](../flash-daily-prd.md) v1.0.0 |
| **Trạng thái** | **PM/DA-confirmed** — PM Smartlog (sid.product@gosmartlog.com) đã duyệt 18/18 câu hỏi vòng 1. Còn 2 follow-up cần Ops Manager Mondelez confirm trong workshop. |
| **Linked artifacts** | [PRD v1.0.0](../flash-daily-prd.md), [Spec v1.0.0](../flash-daily-spec.md), [Wireframe v1.0.0](../flash-daily-wireframe.md) |

---

## 0-LOCKED. Layout v2 — Final spec cho v1.1.0

> Locked 2026-05-16 sau 3 rounds duyệt với PM Smartlog (A1-E5 + F1-F2 + G1-G7 = 25 quyết định).
> Đây là **scope reference cho `/ba` PRD v1.1.0 addendum**.

```
┌─────────────────────────────────────────────────────────────────────┐
│ FILTER BAR (sticky, autoApply) — như cũ                             │
├─────────────────────────────────────────────────────────────────────┤
│ L1 HERO — % HOÀN THÀNH HÔM NAY (full-width)                         │
│   • Snapshot value + target 95% reference + RAG color               │
│   • Sub-numbers: Plan / Đã giao / Còn lại                           │
│   • KHÔNG có delta, KHÔNG có as-of timestamp                        │
├─────────────────────────────────────────────────────────────────────┤
│ L2 EXCEPTION SPOTLIGHT — 3 ô (hôm nay)                              │
│   • Top N kho off-target (< 85%)                                    │
│   • Đơn rớt chưa xử lý                                              │
│   • Khu vực dưới target                                             │
├─────────────────────────────────────────────────────────────────────┤
│ L3 FUNNEL 5 TRẠNG THÁI — strip compact 1 dòng                       │
│   • Chưa xuất → Đang xuất → Đã xuất → Đang vận → Đã vận             │
│   • Mỗi entry: volume + % share                                     │
│   • THAY THẾ 6 KPI cards hiện hành                                  │
├─────────────────────────────────────────────────────────────────────┤
│ L4 TREND TỶ LỆ RỚT 14 NGÀY — chart MỚI (line)                       │
│   • Definition: drop_rate = # đơn FAIL / Tổng kế hoạch (per day)    │
│   • X: 14 ngày qua | Y: % rớt                                       │
│   • Reference: target ≤5% (solid red) + rolling 30d avg (dashed)    │
│   • Áp cùng filter bar với L1-L3                                    │
├─────────────────────────────────────────────────────────────────────┤
│ L5 DIMENSION DRILLDOWN — tabbed chart (hôm nay)                     │
│   • Tabs: Kho / Khu vực / Khách / Kênh                              │
│   • Horizontal bar % completion, sort worst-first, target line 95%  │
├─────────────────────────────────────────────────────────────────────┤
│ L6 DETAIL TABLES (tab riêng) — GIỮ NGUYÊN 9 bảng (D2 defer)         │
│   • T1 Completion — BỎ synthetic fallback (drift #7 fix)            │
│   • T2 E2E Detail, T3-T6 Summary (giữ nguyên — cleanup ở phase sau) │
│   • T7 Dropped Delivery, T8 Dropped Reason, T9 Flash Detail (giữ)   │
└─────────────────────────────────────────────────────────────────────┘
```

**Storytelling principles áp dụng** (theo `/da-storytelling-data`):
- Action title trên mỗi section (vd "Hôm nay 73% kế hoạch đã hoàn thành — DƯỚI target 95%")
- RAG color: Green ≥95, Yellow 85-95, Red <85
- Alert banner full-width khi overall <80%
- BỎ dropdown NPP/Customer (D3)
- BỎ subtitle CBM forced display
- Sửa `STATUS_ORDER` đúng thứ tự luồng E2E (drift #11)

**v1.1.0 Action items được audit confirm**:
- **L4 Drop trend chart**: BUILDABLE NOW với SQL draft đã có (xem §0c A3 finding 2). Add section key `chartDropTrend` vào `FlashDailySqlQueries` + `FLASH_DAILY_SECTIONS`. FAIL = `status='Cancel'` only (H1). Date type chỉ allow GI/Actual Ship/ATA (H2).
- **STM lag caveat**: Add tooltip "Chưa nhận tín hiệu ATD từ STM" ở 2 KPI status "Đã xuất kho" + "Đang vận chuyển" (A3 finding 1). KHÔNG block release.
- **T1 synthetic fallback removal**: Replace [widget-flash-daily.tsx:1813-1910](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1813-L1910) bằng `return []` + EmptyState ở consumer line 2878 + xoá constants 166-175 (A2 finding).
- **PRD §3.1 + Spec §18 wording fixes** (xem §0c A2-A3 cross-finding).
- **STATUS_ORDER drift #11 fix**: Sửa thứ tự constant theo flow E2E ([widget-flash-daily.tsx:91-97](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L91-L97)).

**Out-of-scope cho v1.1.0** (chuyển sang sau):
- Delta vs hôm qua / vs same time yesterday (F2 reframe)
- Snapshot infrastructure per timepoint (F2 reframe)
- As-of timestamp UI (G7)
- Target override per channel/cargo/warehouse (F1 + B2 + B3)
- Per-channel RAG bands (F1)
- Customer search box + N selector (OQ-06 — chuyển v1.2.0)
- Consolidate 17 → 5 query (OQ-09 — chuyển v1.3.0)
- Master data `customer_type` field (OQ-07 — KHÔNG cần cho Mondelez theo D3)
- File refactor 2,893 dòng (drift #2 — chuyển v1.2.0)
- **Cut T2-T6 tables (D2)** — defer hoàn toàn, user xử lý cleanup riêng phase sau

---

## 0c. Audit findings — 2026-05-16

> Section này ghi findings từ 3 audit agent đã spawn parallel. Cập nhật khi mỗi agent xong.

### A2 — FormConfig seed audit (✅ done)

**Reversal quan trọng**: FormConfig system là **file-based** (`FileBasedFormConfigProvider.cs` + `IMemoryCache` TTL 2h), **KHÔNG** có DB table `form_config`. Spec §18 wording cần sửa.

| Item | Trạng thái |
|------|------------|
| 9 JSON files presence | ✅ All 9 present at `backend/src/FormConfigs/DSHFLADTG01..09.json` |
| JSON structure valid | ✅ All parse, category="GRID", code matches filename |
| Column counts | 01=7, 02=3, 03=5, 04=5, 05=5, 06=5, 07=5, 08=3, 09=33 |
| Seed mechanism | File-based, deployed via `Smartlog.Api.csproj <Content Include="..\FormConfigs\**\*.json">` lines 29-32 |
| Per-tenant scope | **GLOBAL** — 1 file phục vụ mọi tenant |
| Audit còn lại | Runtime smoke `GET /api/forms/{code}` × 9 với Mondelez tenant — verify Api image deploy đủ |

**Spec §18 cần update**: thay "Backend FormConfig seed Mondelez tenant phải chứa 9 codes" → "Build/Deploy: 9 JSON files phải có trong Api image, verify bằng runtime smoke. KHÔNG có DB query để audit."

**Synthetic fallback safe-removal pattern** (đã verify khả thi):
- File: [widget-flash-daily.tsx:1809-1919](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1809-L1919)
- Step 1: Replace lines 1813-1910 (everything after the early-return on line 1812) with `return [] as CompletionRateRow[]`
- Step 2: Consumer line 2878 — render EmptyState ("Chưa cấu hình tblCompletion SQL") khi `completionRows.length === 0`
- Step 3: Delete constants `COMPLETION_WH_NAMES` / `COMPLETION_CHANNELS` / `COMPLETION_AREAS` ([lines 166-175](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L166-L175)) — unused sau khi xoá

**Block v1.1.0 rollout if**: (a) runtime smoke fails for any of 9 codes → CI/CD packaging bug; (b) synthetic fallback chưa được removed AND Mondelez `tblCompletion` SQL chưa registered → user thấy 54 dòng giả.

**Safe to proceed if**: (a) file audit pass; (b) Mondelez `tblCompletion` SQL registered (depend trên A3 /da-ch result); (c) fallback removed per pattern above.

### A1 — Usage 9 bảng audit (✅ done)

**Reversal**: Telemetry void cho Mondelez.

| Item | Trạng thái |
|------|------------|
| `logging.activity` schema | Real columns: `user_email, time, label, parameters, caller_name, request_id, ip_address`. KHÔNG có `entity_code` / `table_grid_key` như SQL audit cũ viết. |
| Grid open events | KHÔNG track. Chỉ `SaveUserFormSetting` (PUT, user nhấn "Save Settings") mới ghi activity, KHÔNG phải mount load. |
| Mondelez có PG activity log không? | Likely NO — Mondelez = ClickHouse-only stack. `analytics_workspace` có 16 KPI MV nhưng KHÔNG có user-activity MV. |
| Cut decision T2-T6 | **NEED DATA mà DATA KHÔNG TỒN TẠI** → fallback về stakeholder hypothesis (đã align cắt T2-T6 từ critique vòng 2). |

**Recommendation**:
- v1.1.0: accept stakeholder hypothesis cut, KHÔNG block release
- (Optional) v1.1.0 PR thêm tiny instrumentation: track grid-open events vào activity log với gridKey → v1.2.0 có data thật
- (Alternative) Ship T2-T6 dưới dạng collapsed `<details>` block 1 sprint → click-to-expand signal

**SQL audit cũ ở OQ-05 section (line ~415) cần update**: dùng schema sai → reformulate hoặc remove.

### A3 — ClickHouse STM lag + drop rate SQL audit (✅ done)

**Reversal**: PRD §3.1 SAI về double-count + L4 chart buildable now.

#### Finding 1 — STM lag: KHÔNG có double-count risk

PRD §3.1 hiện viết "'Đã xuất kho' và 'Đang vận chuyển' cùng dùng `SUM(QTY SHIPPEDDETAIL)`, chỉ khác signal STM". **SAI** — CH MV pre-computes `e2e_label` qua check `thoi_gian_di IS NULL` → 2 status mutually exclusive at SQL level.

| Status | Pre-compute logic |
|--------|-------------------|
| Đã xuất kho | `actual_ship_date NOT NULL AND thoi_gian_di IS NULL` |
| Đang vận chuyển | `thoi_gian_di NOT NULL AND ata_den IS NULL` |
| Đã vận chuyển | `ata_den NOT NULL` |

Lag chỉ là **operational** (signal arrival latency từ STM), không inflate data bucket.

**Storytelling action**:
- Add caveat tooltip ở 2 KPI status: "Chưa nhận tín hiệu ATD từ STM"
- (Optional) L2 Exception card khi >5% volume stuck >12h không có ATD signal:
  ```sql
  SELECT countIf(thoi_gian_di IS NULL AND now() - actual_ship_date > INTERVAL 12 HOUR) AS stuck_no_atd
  FROM analytics_workspace.mv_flash_and_drop_report
  WHERE e2e_label = 'Đã xuất kho' AND actual_ship_date >= today() - 1
  ```

#### Finding 2 — L4 drop trend chart BUILDABLE NOW

Data sources (confirmed):
- `analytics_workspace.mv_flash_report` — active orders + `e2e_label`
- `analytics_workspace.mv_dropped_report` — cancelled/failed orders
- `analytics_workspace.mv_flash_and_drop_report` — UNION (cards/status)

FAIL classification (canonical per `projects/mondelez/02-data/data-sources/sql-registry.md` "Flash Report" section, lines L12047-12291): `status = 'Cancel'` on `mv_dropped_report`. NOT substring match.

**SQL draft cho L4 chart** (cho `/da-ch` finalize, đã filter parity với existing T7 — KHÔNG có brand filter):

```sql
WITH flash_base AS (
  SELECT toDate(CASE WHEN {{date_type}} = 'Ngày GI' THEN delivery_date_1
                     WHEN {{date_type}} = 'Actual Ship Date' THEN actual_ship_date
                     WHEN {{date_type}} = 'ATA đơn' THEN ata_den
                     ELSE delivery_date_1 END) AS d,
         toFloat64(coalesce(original_cse,0)) + toFloat64(coalesce(original_qty,0)) AS plan_v
  FROM analytics_workspace.mv_flash_report
  WHERE <date BETWEEN {{from_date}} AND {{to_date}}>
    AND <multi-select: group_name / whseid / group_of_cargo / region>
),
drop_base AS (
  SELECT toDate(<same CASE>) AS d,
         toFloat64(coalesce(original_cse,0)) + toFloat64(coalesce(original_qty,0)) AS plan_v,
         if(status='Cancel', toFloat64(coalesce(original_cse,0)) + toFloat64(coalesce(original_qty,0)), 0) AS fail_v
  FROM analytics_workspace.mv_dropped_report
  WHERE <same date+filter block>
),
per_day AS (
  SELECT d, SUM(plan_v) AS total_plan, 0 AS total_failed FROM flash_base GROUP BY d
  UNION ALL
  SELECT d, SUM(plan_v) AS total_plan, SUM(fail_v) AS total_failed FROM drop_base GROUP BY d
)
SELECT d AS date, SUM(total_plan) AS total_plan, SUM(total_failed) AS total_failed,
       if(SUM(total_plan)=0, 0, round(100.0 * SUM(total_failed) / SUM(total_plan), 2)) AS drop_rate
FROM per_day GROUP BY d ORDER BY d;
```

**Rolling 30d average** (cho dashed reference line):
```sql
SELECT date, drop_rate, total_plan, total_failed,
       avg(drop_rate) OVER (ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS drop_rate_30d_avg
FROM (<above>)
ORDER BY date DESC LIMIT 14;
```
(Backfill 44 ngày trong CTE để 14 visible rows có đủ 30 priors).

**Section key**: thêm `chartDropTrend` vào `FlashDailySqlQueries` interface + `FLASH_DAILY_SECTIONS` của Settings dialog.

#### Finding 3 — 2 ambiguity cần Ops confirm

| ID | Vấn đề | Gợi ý |
|----|--------|------|
| **H1** | FAIL = chỉ `Cancel`, hay cả `Close`? Tooltip T7 "Xử lý ko thành công" có thể bao gồm `Close` | **(a) Cancel only** (canonical SQL registry) — confirm với Ops |
| **H2** | `mv_dropped_report` chỉ expose 3/5 date_type options (thiếu ETD gửi thầu + ETA gửi thầu) → nếu user chọn ETD/ETA → drop-side rows NULL out | **(a) Disable ETD/ETA option trên L4 chart UX** — đơn giản, không lossy |

### A2-A3 cross-finding — Spec §18 cần sửa wording

Bộ tài liệu PRD/spec hiện viết sai 2 chỗ về backend data layer:
1. **Spec §18**: "Backend FormConfig seed Mondelez tenant phải chứa 9 codes" → đổi thành "Build/Deploy: 9 JSON files phải có trong Api image, verify bằng runtime smoke. KHÔNG có DB query để audit."
2. **PRD §3.1**: "'Đã xuất kho' và 'Đang vận chuyển' cùng dùng `SUM(QTY SHIPPEDDETAIL)`, chỉ khác signal STM" → đổi thành "2 status pre-computed mutually exclusive ở CH MV `e2e_label` field. Phân biệt qua check `thoi_gian_di NULL`. Lag chỉ ảnh hưởng operational, không inflate count."

Cả 2 fix sẽ được áp khi bump v1.0.0 → v1.1.0.

---

## 0a. Decisions Log — User confirmation 2026-05-16

> PM Smartlog đã duyệt qua 18 câu hỏi vòng 1. Bảng dưới là **chốt nguồn duy nhất** — các section OQ chi tiết bên dưới được giữ để trace lý do, nhưng nếu xung đột → bảng này là source of truth.

| Câu | Quyết định | Status |
|-----|-----------|--------|
| **A1** Mục đích refresh | 3 phase: Storytelling v1.1.0 → UI reorg v1.2.0 → Performance v1.3.0 | ✅ Confirmed |
| **A2** Workshop attendees | Ops Manager Mondelez + PM Smartlog + 3 WH Manager + 1 Planner + 1 CS | ✅ Confirmed |
| **A3** Deadline v1.1.0 | 3-4 tuần sau workshop | ✅ Confirmed |
| **B1** Target overall E2E | **95%** | ✅ Confirmed |
| **B2** Override theo Cargo Group | **KHÔNG override** — dùng 95% chung | ✅ Confirmed |
| **B3** Override theo Kho | **KHÔNG override** — dùng 95% chung | ✅ Confirmed |
| **B4** Ngưỡng alert đỏ | **<85%** Red trên KPI card; **<80%** thêm alert banner | ✅ Confirmed |
| **C1** KPI card 3-layer (value + delta + target) | **REFRAME** — bỏ delta, giữ value + target. Xem F2 mới. | 🔄 Reframed (F2 round 2) |
| **C2** Reference cho delta | **BỎ** — không tính delta theo giờ nữa | 🔄 Reframed |
| **C3** L2 Exception Spotlight | **YES** | ✅ Confirmed |
| **C4** Cắt 6 KPI cards → L1 hero + L3 funnel strip | **YES** | ✅ Confirmed |
| **D1** UOM default | **cse** (giữ nguyên) | ✅ Confirmed |
| **D2** Audit usage 9 bảng | **🔄 Round 3 — DEFER**. Audit telemetry void → user chọn GIỮ NGUYÊN 9 bảng cho v1.1.0, xử lý cleanup ở phase sau. | ✅ Confirmed (deferred) |
| **D3** NPP/Customer split | **🔥 NPP = Customer (không phân biệt)** → BỎ dropdown `customerDimensionFilter` luôn | ✅ Confirmed |
| **D4** STM lag verification | **🔄 Audit done — PRD §3.1 SAI**. CH MV pre-computes `e2e_label` (mutually exclusive). Zero double-count, chỉ là operational lag. → Add caveat tooltip, KHÔNG block. | ✅ Audit done (A3 agent) |
| **D5** Synthetic 54-row T1 fallback | **BỎ** — replace bằng empty state | ✅ Confirmed |
| **D6** Audit FormConfig DSHFLADTG01..09 | **🔄 Audit done 2026-05-16** — FormConfig là **file-based, KHÔNG DB-seeded**. 9 JSON files đều có + valid. Audit thực sự = runtime smoke `GET /api/forms/{code}` cho 9 codes với Mondelez tenant. | ✅ Audit done (A2 agent) |
| **E1** Refresh frequency Ops | **11h sáng / 17h / 23h** — 3 check-in mỗi ngày (KHÔNG phải sáng sớm) | ✅ Confirmed (PM relay) |
| **E2** Single most important number | **% Hoàn thành E2E so với target** | ✅ Confirmed (PM relay) |
| **E3** Target SLA per channel | **F1 chốt: dùng 95% chung cho dashboard**. SLA per-channel là contractual, KHÔNG vào dashboard v1.1.0. | ✅ Confirmed (F1 round 2) |
| **E4** STM lag occurrence | Có, nhưng RẤT HIẾM | ✅ Confirmed (PM relay) |
| **E5** Số liệu không khớp thực tế | Có — khi thực tế đã thực hiện nhưng chưa update lên hệ thống (data delay, không phải data wrong) | ✅ Confirmed (PM relay) |
| **G1** L4 trend window | **14 ngày qua** (fixed, KHÔNG dropdown) | ✅ Confirmed |
| **G2** Định nghĩa "Tỷ lệ rớt" | **Hẹp**: `# đơn FAIL / Tổng kế hoạch` (chỉ cancel/close) | ✅ Confirmed |
| **G3** L4 chart type | **Line chart** (1 line, 14 điểm) | ✅ Confirmed |
| **G4** L4 reference lines | **Cả 2**: target ≤5% (cố định) + rolling 30-day avg (dynamic dashed) | ✅ Confirmed |
| **G5** L4 áp filter | **Cùng filter** với L1-L3 (consistent) | ✅ Confirmed |
| **G6** KPI cards 6 ô | **CẮT** — gộp thành L1 hero + L3 funnel strip | ✅ Confirmed |
| **H1** FAIL classification | **`status='Cancel'` only** (canonical SQL registry) | ✅ Confirmed |
| **H2** Date type ETD/ETA trên L4 | **Disable ETD/ETA option** trên L4 chart UX (chỉ allow GI/Actual Ship/ATA) | ✅ Confirmed |
| **D2-followup** Cut T2-T6 tables | **DEFER** — giữ nguyên 9 bảng cho v1.1.0, cleanup ở phase sau | ✅ Confirmed (user 2026-05-16) |
| **G7** As-of timestamp | **KHÔNG cần** — giữ dashboard sạch (chấp nhận data delay risk theo E5) | ✅ Confirmed |

### 🔥 Key insights mới phát hiện từ câu trả lời

1. **NPP = Customer (D3)** — Mondelez KHÔNG dùng business distinction NPP vs Customer endpoint. Toàn bộ code logic `inferCustomerDimensionType()` + dropdown `customerDimensionFilter` (Tất cả / NPP / Customer) là **noise** — phải bỏ hẳn trong v1.1.0, KHÔNG cần OQ-07 fix master data.
2. **Refresh pattern 3 lần/ngày (E1)** — 11h sáng, 17h, 23h. Điều này ảnh hưởng **C2 "delta vs same time yesterday"**: phải lưu snapshot per timepoint, KHÔNG phải so với midnight hay end-of-day.
3. **STM lag rare (E4)** — D4 audit vẫn cần làm, nhưng hypothesis là pattern OK. Caveat tooltip có thể bỏ qua, KHÔNG cần STM health badge nổi bật.
4. **Data delay = root cause E5** — Vấn đề số liệu không khớp KHÔNG phải do bug, mà do user thao tác trên thực tế nhưng chưa update lên WMS/STM. Đây là **process gap**, không phải **system bug** — storytelling layer cần handle bằng "as-of timestamp" rõ ràng ("Dữ liệu cập nhật lần cuối: HH:mm").

---

## 0b. Follow-up cần Ops Manager Mondelez confirm trong workshop

> 2 mâu thuẫn / chưa rõ phát sinh từ câu trả lời vòng 1:

### ✅ F1 RESOLVED 2026-05-16 — Dùng 95% chung cho dashboard

PM chốt **(a)** — Dashboard hiển thị 1 target overall 95% cho mọi widget. SLA per-channel (KA=95%, MT=90-93%) là contractual cho BOD/Finance, KHÔNG phản ánh trong dashboard v1.1.0. Nếu Ops Mondelez feedback "MT bị đỏ oan" trong UAT → cân nhắc override ở v1.2.0.

---

### F1 (original) — Mâu thuẫn target overall vs target per channel

**Vấn đề**: B1+B2 chốt **95% overall, KHÔNG override theo cargo/kho**. Nhưng E3 nói **KA = 95%, MT = 90-93%** → đây có phải override theo **kênh bán hàng** không?

**3 cách diễn giải**:

| Diễn giải | Implication storytelling |
|----------|--------------------------|
| **(a)** Dashboard hiển thị 1 target overall 95% cho mọi widget. E3 là SLA contractual (BOD/Finance dùng), KHÔNG phản ánh trong dashboard. | RAG bands đơn giản — 1 ngưỡng 95% áp dụng cả KPI card + 4 dimension chart |
| **(b)** Overall = 95% cho L1 hero, nhưng L4 chart "Theo Kênh bán hàng" có RAG bands **per channel**: KA G≥95/R<85, MT G≥90/R<80. | RAG bands phức tạp hơn — cần config per channel |
| **(c)** Mọi nơi đều dùng channel-specific target — overall 95% chỉ là số trung bình weighted. | Phải refactor cả L1 hero để hiển thị weighted target |

**Gợi ý của tôi**: chọn **(a)** cho v1.1.0 — đơn giản, nhanh ship. Khi Ops Mondelez feedback "MT bị đỏ oan" mới chuyển sang (b) ở v1.2.0.

**Cần Ops Manager confirm**: *"Trên dashboard này, bạn muốn 1 target chung 95% hay target khác nhau theo kênh KA/MT/GT?"*

### 🔄 F2 RESOLVED 2026-05-16 — REFRAME: Bỏ delta, thêm trend tỷ lệ rớt N ngày

**PM chốt (round 2)**: Bỏ delta theo giờ — quá nặng và không phản ánh đúng mental model. Thay vào đó:
1. **Hôm nay**: chỉ cần snapshot "% đã hoàn thành" + RAG (no delta)
2. **N ngày qua**: thêm trend "tỷ lệ rớt qua các ngày"

**Implication storytelling lớn**:
- KPI cards SIMPLIFIED — chỉ value + % vs target, KHÔNG cần delta arrow
- Thêm SECTION MỚI ở Level cao: "Trend tỷ lệ rớt N ngày qua" (line/bar chart)
- BỎ luôn snapshot infrastructure (lưu data per timepoint) — vì không dùng delta

Xem `## L1-L6 Layout Proposal v2` bên dưới.

---

### F2 (original) — "Delta vs same time yesterday" với 3 check-in points

**Vấn đề**: E1 nói Ops check 11h / 17h / 23h. C2 chốt "delta vs same time yesterday" — vậy:
- Khi user mở dashboard 11h thứ Hai → so với 11h Chủ Nhật? Hay 11h thứ Sáu (skip cuối tuần)?
- Khi user mở 14h (giữa các check-in points) → so với 14h hôm qua? Hay 11h gần nhất?

**3 cách**:

| Cách | Implication |
|------|-------------|
| **(a)** Real-time: lúc nào mở thì so với cùng giờ hôm qua | Snapshot mỗi giờ — storage cost cao hơn |
| **(b)** Snapshot at 11h/17h/23h only — giữa các điểm thì delta giữ nguyên | Đơn giản, đủ cho Ops use case |
| **(c)** So với end-of-day hôm qua (tổng cuối ngày) | Đơn giản nhất nhưng KHÔNG match Ops mental model (E2 muốn "hôm nay tốt hơn hôm qua chưa") |

**Gợi ý của tôi**: chọn **(b)** — snapshot 3 lần/ngày + đếm delta theo điểm gần nhất trong quá khứ. Skip cuối tuần (nếu hôm nay là thứ Hai → so với thứ Sáu).

**Cần Ops Manager confirm**: *"Khi bạn mở dashboard lúc 14h, bạn muốn so với 14h hôm qua, hay với check-in gần nhất (11h)?"*

---

## 0. Methodology — Evidence tagging

Mỗi đề xuất gắn 1 trong 3 nhãn:

| Nhãn | Nghĩa | Hành động yêu cầu |
|------|------|--------------------|
| **[Observed]** | Đối chiếu được với source code / config / data thực | Có thể chốt luôn, KHÔNG cần stakeholder confirm |
| **[Reported]** | Dựa trên industry standard / best practice / external doc | Cần Ops Manager Mondelez xác nhận có áp dụng với họ không |
| **[Assumed]** | BA suy luận, chưa verify | **PHẢI** confirm trong workshop trước khi đưa vào PRD v1.1.0 |

Mỗi OQ trả lời theo template:
- **Câu hỏi gốc** (copy từ PRD §11)
- **Evidence collected** — đã quan sát/đọc được gì
- **Stakeholder lens** — góc nhìn từng bên
- **Đề xuất** — recommended answer
- **Rủi ro nếu chọn sai** — what's at stake
- **Verification path** — cách verify trước khi chốt

---

## OQ-01 — Mục đích chính của nhánh `feat-flash-daily-refresh`

> **Câu hỏi gốc**: Storytelling refresh giống OTIF (action title + target band + RAG)? Hay tổ chức lại UI (gộp tab/giảm số chart)? Hay performance (17 queries song song → quá nhiều)?

### Evidence collected
- **[Observed]** Branch `feat-flash-daily-refresh` cut từ `main` 2026-05-16, hiện chưa có commit flash-daily-specific ([PRD §metadata](../flash-daily-prd.md))
- **[Observed]** Pattern OTIF gần đây đã refresh: storytelling + action title + RAG (commit `d306e31 feat: enhance VFR widget`, `3adce87 Merged in feat-otif-storytelling-refresh`)
- **[Observed]** Memory note `feedback_pm_driven_feature_attribution.md`: PM/DA tự drive refresh (không qua dev squad full pipeline)

### Stakeholder lens
| Stakeholder | Họ ưu tiên cái gì? |
|------------|---------------------|
| Ops Manager Mondelez | Hiểu nhanh "hôm nay đang đỏ chỗ nào" — **Storytelling** |
| WH Manager | Đối chiếu kho của mình vs target — **Storytelling + RAG** |
| Planner | Theo dõi % theo NPP/Khu vực — **Storytelling + drill** |
| PM Smartlog | Consistency với OTIF refresh — **Storytelling + UI reorg** |
| Dev-FE | File 2,893 dòng khó maintain — **UI reorg + cleanup** |
| Dev-BE / DA-CH | 17 queries × 5000 rows = ~130MB/refresh — **Performance** |

### Đề xuất — **Tất cả 3, theo thứ tự ưu tiên**:

| Phase | Scope | Lý do |
|-------|-------|------|
| **v1.1.0 — Storytelling** (P0) | Action title + RAG + L1 hero + L2 exception | Tác động UX cao nhất; user-facing pain → giải quyết "đọc dashboard không ra quyết định" |
| **v1.2.0 — UI reorg** (P1) | Gộp/cắt 5 chart + 4 bảng summary; tách `widget-flash-daily.tsx` 2,893 dòng | Dọn dẹp sau khi v1.1.0 chốt KPI nào thực sự dùng |
| **v1.3.0 — Performance** (P2) | Consolidate 17 → 5-7 queries; MV trên ClickHouse | Sau khi UI reorg cắt query không cần thiết |

**Status**: [Assumed] — Workshop bắt buộc xác nhận với PM.

### Rủi ro nếu chọn sai
- Nếu chọn **Performance trước**: tối ưu cho cấu trúc cũ → khi v1.1.0 đổi layout, lại phải làm lại
- Nếu chọn **UI reorg trước**: cắt nhầm widget mà user đang dùng (chưa audit usage — xem OQ-05)

### Verification path
- Workshop 30 phút với PM Smartlog + Ops Manager Mondelez
- Câu hỏi chốt: *"Nếu chỉ làm được 1 trong 3 trong tháng này, bạn chọn cái nào?"*

---

## OQ-02 — Target % Hoàn thành Mondelez

> **Câu hỏi gốc**: Target % Hoàn thành chính thức của Mondelez cho Flash Daily là bao nhiêu? Có khác nhau theo kho/khu vực/cargo group không?

### Evidence collected
- **[Observed]** Code KHÔNG có target hardcoded — chỉ có constants color (RAG chưa tồn tại)
- **[Observed]** Memory `project_mondelez_otif_target.md`: OTIF target Mondelez = **90%**, Ontime/Infull riêng vẫn open (OQ-07 trong OTIF doc)
- **[Reported]** SC industry benchmark cho FMCG: OTD (On-Time Delivery) = 95-97%; OTIF = 92-95%; Fill Rate ≥ 98%
- **[Reported]** Distinction: Flash Daily đo **quá trình** (% kế hoạch đã chạy đến đâu), OTIF đo **kết quả** (giao đúng giờ + đủ hàng)

### Stakeholder lens
| Cargo group | Lý do target có thể khác |
|-------------|--------------------------|
| FRESH (sữa, kem) | Shelf-life ngắn → late = lỗ lớn → target cao nhất |
| DRY (bánh kẹo) | Linh hoạt hơn → target trung bình |
| MOONCAKE / Tết | Mùa vụ → target peak cao, off-peak thấp |
| POSM / OFFBOM | Không phải SKU bán → target thấp hơn |

### Đề xuất — chốt trong workshop:

| Metric | Target đề xuất | RAG bands | Cargo override? |
|--------|----------------|-----------|-----------------|
| **% Hoàn thành E2E (overall)** | **95%** | G≥95, Y 85–95, R<85 | Tạm thời KHÔNG override |
| **% Hoàn thành theo Kho** | **95%** | (same) | KHÔNG override |
| **% Hoàn thành theo Khu vực** | **95%** | (same) | KHÔNG override |
| **% Hoàn thành FRESH** | **97%** | G≥97, Y 90–97, R<90 | Override nếu Ops xác nhận shelf-life sensitive |
| **% Hoàn thành DRY** | **95%** | (overall) | KHÔNG override |
| **% Hoàn thành POSM** | **90%** | G≥90, Y 80–90, R<80 | Override nếu Ops xác nhận POSM ít critical |

**Status**: [Reported industry standard] + [Assumed Mondelez sẽ accept] — Workshop confirm.

### Rủi ro nếu chọn sai
- Target quá cao → 100% màu đỏ → dashboard luôn báo động → user mất niềm tin
- Target quá thấp → 100% màu xanh → mất ý nghĩa cảnh báo
- KHÔNG override theo cargo → FRESH bị che hiệu suất xấu trong overall green

### Verification path
- **Ops Manager Mondelez**: hỏi *"Có SLA / KPI nào ràng buộc bạn với Mondelez global không? Số bao nhiêu?"*
- **CS team**: lấy 3 tháng OTIF/OTD report làm baseline để đề xuất target realistic
- **Cross-check**: so với target của OTIF widget (90%) — Flash Daily target nên CAO HƠN vì đo quá trình (chưa tính fail-to-deliver)

---

## OQ-03 — UOM mặc định = `cse`?

> **Câu hỏi gốc**: UOM mặc định `cse` có đúng workflow Ops Manager không, hay nên đổi sang `ton`/`pallet` để dễ hình dung quy mô?

### Evidence collected
- **[Observed]** Default UOM trong code = `cse` ([widget-flash-daily.tsx:1026-1039](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1026-L1039))
- **[Observed]** 5 UOM hỗ trợ: cse, ton, cbm, pallet, do
- **[Reported]** FMCG industry: **cse (case/thùng)** là đơn vị xuất kho phổ biến nhất — tương đương "đơn vị giao dịch giữa SAP và WMS"
- **[Reported]** CBM được dùng cho **capacity planning** (chở được bao nhiêu trong 1 xe); ton cho **finance reporting**; pallet cho **warehouse layout**

### Stakeholder lens
| Audience | UOM phù hợp |
|----------|-------------|
| Ops Manager (daily decision) | **cse** — đơn vị tự nhiên của lệnh xuất |
| WH Manager (sorting/picking) | **cse** hoặc **pallet** |
| Transport / Carrier | **CBM** — capacity xe |
| Finance / BOD | **ton** hoặc tiền |

### Đề xuất — **GIỮ `cse` làm default**:

- KHÔNG đổi default — break habit của user hiện hành (đã có 1 năm dùng cse)
- THÊM **persistent UOM preference per user** (lưu localStorage hoặc user profile) — nếu user đổi sang `ton`, lần sau load vẫn là `ton`
- Trên subtitle chart, **fix CBM forced display**: hiện luôn show "Plan CBM: N" bất kể user chọn UOM nào → CONFUSING. Đề xuất:
  - Nếu user chọn `cbm` → KHÔNG show subtitle (đã ở Y-axis rồi)
  - Nếu user chọn UOM khác → show subtitle `"Plan {value} {uom} | Capacity ref: {cbm} CBM"`

**Status**: [Reported] industry consensus + [Observed] default đã tồn tại — chỉ cần Ops xác nhận không phá vỡ workflow.

### Rủi ro nếu chọn sai
- Đổi default → user phải re-train, mất confidence
- Bỏ CBM subtitle → mất context khi user xem ton/pallet

### Verification path
- Hỏi 3 Ops Manager (BKD1, NKD, ICD): *"Bạn report cho sếp dùng đơn vị gì?"*
- Audit localStorage usage qua `/da-ops`: Có bao nhiêu % user đã từng đổi UOM khỏi default `cse`?

---

## OQ-04 — KPI cards cần `% target` + `delta vs hôm qua`?

> **Câu hỏi gốc**: 6 KPI cards có cần thêm "% so với kế hoạch" và "delta vs hôm qua" như OTIF v1.2.0 không?

### Evidence collected
- **[Observed]** OTIF v1.2.0 đã có pattern này (commit `3adce87 feat-otif-storytelling-refresh`) — đã được PM approve
- **[Observed]** Hiện 6 KPI cards chỉ show **giá trị tuyệt đối** + description text
- **[Observed]** Skill `/da-storytelling-data` anti-pattern: *"KPI card không có % vs total, không có vs hôm qua"*
- **[Reported]** Storytelling best practice: KPI card phải có 3 layer — value + trend + target

### Stakeholder lens
| Stakeholder | Cần gì |
|------------|--------|
| Ops Manager | "Hôm nay so với hôm qua tốt hơn hay xấu hơn?" — delta arrow |
| WH Manager | "Tôi đang xuất bao nhiêu % so với kế hoạch SAP đẩy về?" — % vs plan |
| BOD | "Trong 5 ngày qua có cải thiện không?" — trend mini sparkline |

### Đề xuất — **YES, mandatory cho v1.1.0**:

Mỗi card có **3 layer** (giảm description, thêm metric):

```
┌─────────────────────────────────────┐
│ ▄▄▄▄▄▄ (color accent) ▄▄▄▄▄▄▄▄▄▄▄  │
│ [icon]  ĐÃ VẬN CHUYỂN          [?] │
│  39,000 CSE                         │  ← Layer 1: Absolute value (như cũ)
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│  31% kế hoạch  ↓3pp vs hôm qua     │  ← Layer 2: % share + delta
│  Target 35%  ⚠️ DƯỚI mục tiêu      │  ← Layer 3: vs target + RAG
└─────────────────────────────────────┘
```

**Reference cho comparison**:
- **Delta vs hôm qua** (recommended) — same time yesterday, không phải tổng hôm qua
- **% kế hoạch** = card value / Tổng Volume Kế hoạch
- **Target** chỉ áp cho 2 card cuối: "Đang vận chuyển" + "Đã vận chuyển" (vì 3 card đầu giảm là good, không có target)

**Status**: [Reported best practice] + [Observed OTIF đã làm] — Workshop confirm reference (yesterday vs MTD avg).

### Rủi ro nếu chọn sai
- Quá nhiều info trên 1 card → trở thành "BOD report" thay vì "flash status"
- Reference sai (vd vs cùng ngày tuần trước thay vì hôm qua) → user diễn giải sai

### Verification path
- Cho Ops 3 mock card (compact / medium / full) → chọn cái nào dễ đọc nhất trong 3 giây

---

## OQ-05 — 9 bảng ở tab Chi tiết, dùng hết không?

> **Câu hỏi gốc**: Bảng nào users thực sự xem >1x/tuần? (cần audit usage log để cắt bảng không dùng)

### Evidence collected
- **[Observed]** Activity log table `logging.activity` (`LogDbContext`) — có ghi action user click vào dashboard
- **[Observed]** Memory `project_mondelez_da_ops_stack`: Mondelez = Stack B (ClickHouse `analytics_workspace`) — query qua /da-ch
- **[Reported]** Pareto thường gặp: 80% user dùng 20% feature

### Stakeholder lens (hypothesis trước audit)
| Role | Bảng có khả năng dùng |
|------|------------------------|
| Ops Manager (daily) | T1 Completion (decide hành động) |
| WH Manager | T3 Summary by WH (own WH) |
| Planner | T4 Summary by Customer, T5 Summary by Area |
| CS | T9 Flash Detail (query đơn cụ thể) |
| Sales / KAM | T7 Dropped, T8 Dropped Reason (follow customer) |

### Đề xuất — **Audit qua `/da-ops` trước**, hypothesis:

| Bảng | Hypothesis usage | Quyết định nếu hypothesis đúng |
|------|------------------|--------------------------------|
| T1 Completion | High (Ops primary) | **GIỮ** |
| T2 E2E Detail | Low (trùng KPI cards) | **CẮT** — đã có L3 Funnel ở storytelling layer |
| T3 Summary WH | Med (WH Manager) | **MERGE** vào L4 tabbed chart (xem critique vòng 2) |
| T4 Summary Customer | Med (Planner, Sales) | **MERGE** vào L4 |
| T5 Summary Area | Med (Planner) | **MERGE** vào L4 |
| T6 Summary Channel | Low (overlap T4) | **CẮT** hoặc merge |
| T7 Dropped Delivery | High (Ops follow-up) | **GIỮ** + nâng cấp lên L2 exception |
| T8 Dropped Reason | High (root cause) | **GIỮ** + nâng cấp lên L2 |
| T9 Flash Detail (32 cột) | Med (CS, audit) | **GIỮ** — bảng raw cho deep query |

**Tổng**: 9 → 4 bảng (T1, T7, T8, T9). Tiết kiệm 5 query.

**Status**: [Assumed] — workshop với Ops + audit usage trước khi cắt.

### Rủi ro nếu chọn sai
- Cắt nhầm bảng đang được dùng → user fail to complete task
- KHÔNG cắt → dashboard tiếp tục bloat, 17 query overload

### Verification path
- `/da-ops` audit: `SELECT user, table_grid_key, count(*) FROM logging.activity WHERE entity_code LIKE 'DSHFLA%' GROUP BY 1,2 ORDER BY 3 DESC` (LIMIT 30 ngày)
- Threshold: bảng có < 5 lần xem / tuần / toàn tenant → cắt

---

## OQ-06 — Customer chart top 10 cứng?

> **Câu hỏi gốc**: Chart "Theo NPP/Customer" giới hạn top 10 — có cần tùy chỉnh N hoặc cho phép search customer cụ thể không?

### Evidence collected
- **[Observed]** Code hardcode `topNByTotal(filteredRows, 10)` ([widget-flash-daily.tsx:1737](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1737))
- **[Observed]** Có filter NPP/Customer/All client-side
- **[Reported]** Mondelez Vietnam có ~50-80 NPP active + hàng nghìn Customer endpoint

### Stakeholder lens
| Use case | Cần gì |
|---------|--------|
| "Khách nào lớn nhất hôm nay?" | Top 10/20 by volume |
| "Khách nhỏ nào bị bỏ rơi?" | Bottom 10 by % complete |
| "Khách X cụ thể đang sao?" | Search by name |
| "Tổng quan toàn cảnh" | Heatmap N x M không cần top |

### Đề xuất:

Replace hardcode 10 bằng **3 control**:
1. **N selector**: dropdown `[5 / 10 / 20 / 50 / All]` — default 10
2. **Sort selector**: `[By volume desc / By % complete asc (worst first) / By name]` — default "By volume desc"
3. **Search box**: filter by customer name (case-insensitive)

Combined giải quyết cả 4 use case trên.

**Status**: [Reported best practice] — implementation decision, không cần stakeholder confirm.

### Rủi ro nếu chọn sai
- Thêm 3 control → UI clutter nếu không design tốt
- N=All → render 1000+ rows làm chậm browser

### Verification path
- Implement và test với Ops thử 1 tuần
- Monitor: usage của từng control để decide có giữ cả 3 không

---

## OQ-07 — NPP/Customer phân loại bằng substring match?

> **Câu hỏi gốc**: Heuristic `inferCustomerDimensionType` substring match — có đáng tin cậy không, hay cần field `customer_type` từ SQL?

### Evidence collected
- **[Observed]** Code hiện match substring `'npp' | 'nha phan phoi' | 'nhà phân phối' | 'distributor'` ([widget-flash-daily.tsx:319-330](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L319-L330))
- **[Observed]** Spec drift #3: "fragile khi customer name tiếng Anh"
- **[Reported]** SAP master data thường có field `partner_function` hoặc `customer_classification` phân loại NPP/Sub-dealer/End-customer

### Stakeholder lens
| Stakeholder | Care về NPP vs Customer? |
|------------|--------------------------|
| Ops Manager | Phân biệt để biết "giao tới NPP" vs "giao trực tiếp" — KHÁC SLA |
| Planner | Phân tích kênh phân phối — quan trọng |
| Finance | Tính giá theo loại khách — quan trọng |

### Business rule khám phá

```
## BR-MDL-FD-001: Phân loại khách hàng theo loại giao
- **Statement**: Đơn hàng giao tới NPP (Nhà Phân Phối) có SLA và quy trình khác đơn hàng
  giao trực tiếp tới customer endpoint. Dashboard phải phân biệt rõ 2 nhóm này.
- **Owner**: Ops Manager Mondelez
- **Source**: Assumed từ SC convention — cần Mondelez confirm
- **Exceptions**: None — phải nhất quán toàn tenant
- **Tenant scope**: Mondelez (có thể áp tenant khác)
- **System impact**: Filter dropdown chart Customer, KPI breakdown theo loại
```

### Đề xuất — **🔴 Fix root cause, KHÔNG patch substring**:

| Layer | Hành động |
|-------|----------|
| **Master data** | Add field `customer_type` (`'NPP' \| 'CUSTOMER' \| 'INTERNAL' \| 'OTHER'`) trong dim customer table |
| **Backend / SQL** | `chartCustomer` SQL SELECT thêm `customer_type` column |
| **Frontend** | Đọc field trực tiếp, BỎ `inferCustomerDimensionType()` |

**Status**: [Observed bug] — escalate lên dev-be + IT Mondelez.

### Rủi ro nếu KHÔNG fix
- Customer Eng name (vd "Phong Vu Distribution") không match "npp" → bị phân loại sai
- Onboard tenant khác → substring rule không áp dụng

### Verification path
- `/da-ch` query: `SELECT customer_name, customer_type FROM <dim_customer> LIMIT 100` — verify field tồn tại
- Nếu KHÔNG có: yêu cầu dev-be + IT Mondelez expose field

---

## OQ-08 — Đã xuất + Đang vận chuyển double-count khi STM lag?

> **Câu hỏi gốc**: Status "Đã xuất kho" và "Đang vận chuyển" cùng dùng `SUM(QTY SHIPPEDDETAIL)` — chỉ khác signal STM. Khi STM down/lag → 2 status đếm trùng hay không?

### Evidence collected
- **[Observed]** PRD §3.1: cả 2 status đều `SUM(QTY SHIPPEDDETAIL)`
- **[Observed]** Phân biệt = signal STM (ATD signal nhận từ STM hay chưa)
- **[Observed]** Spec drift #10 đã flag severity **High** — chưa có test case
- **[Reported]** STM (Shipment Tracking Module) là external system → latency có thể 5 phút đến vài giờ tuỳ kết nối

### Phân tích logic

| Trạng thái thực tế của đơn | Status field trả về | Có thể đếm trùng? |
|----------------------------|---------------------|---------------------|
| Kho vừa xuất xong, xe chưa rời | "Đã xuất kho" | KHÔNG (chỉ 1 status) |
| Xe rời kho 30 phút trước, STM signal đã về | "Đang vận chuyển" | KHÔNG (status đã chuyển) |
| Xe rời kho 2h trước, STM signal LAG chưa về | **"Đã xuất kho" (sai — đáng ra phải là "Đang vận chuyển")** | KHÔNG đếm trùng, nhưng **báo sai** |

### Business rule khám phá

```
## BR-MDL-FD-002: Source of truth cho trạng thái xe rời kho
- **Statement**: Trạng thái "Đang vận chuyển" CHỈ được set khi nhận tín hiệu ATD (Actual
  Time of Departure) từ STM. Trước khi nhận tín hiệu → vẫn ở "Đã xuất kho" dù xe đã rời.
- **Owner**: Ops Manager + IT Mondelez (sở hữu STM integration)
- **Source**: Suy luận từ FLASH_DAILY_HINTS code — cần Mondelez confirm
- **Exceptions**: Khi STM down > 4h → manual override?
- **Tenant scope**: Mondelez
- **System impact**: Status reporting, OTIF calculation
```

### Đề xuất:

1. **Test case verification (qa-executor)**:
   - Pick 1 SO đã có cả "shipped detail" và "STM ATD signal"
   - Verify status_field qua SQL: chỉ trả 1 status (không trùng 2 status)
2. **Storytelling adjustment**:
   - Thêm subtitle hoặc tooltip ở 2 card "Đã xuất kho" + "Đang vận chuyển": *"Phụ thuộc tín hiệu STM. Lag tín hiệu có thể làm volume hiển thị ở 'Đã xuất kho' lâu hơn thực tế."*
3. **Health indicator**:
   - Thêm 1 health badge nhỏ ở filter bar: "STM signal: ✅ Latest sync 2 min ago" / "⚠️ Last sync 1h ago — data may lag"

**Status**: [Reported risk] — cần `/da-ch` + qa-executor verify.

### Rủi ro nếu KHÔNG verify
- Ops Manager thấy "Đã xuất kho" cao → nghĩ kho chưa làm gì → call WH oan
- Total `actualExport = Đã xuất + Đang vận + Đã vận` có thể chính xác (vì 3 status mutually exclusive) — nhưng **distribution** giữa 3 status thì sai

### Verification path
- `/da-ch` query trên dim shipment: `SELECT so, status, atd_signal_received_at FROM shipment WHERE shipped_at IS NOT NULL ORDER BY shipped_at DESC LIMIT 100`
- Test: bao nhiêu đơn có `shipped_at` > 2h và status vẫn "Đã xuất kho" (STM lag)?

---

## OQ-09 — 17 queries song song có overload?

> **Câu hỏi gốc**: 17 useQuery song song có overload backend/ClickHouse không? Có cần consolidate xuống 5-7 query không?

### Evidence collected
- **[Observed]** Spec §19: 17 query × 5000 rows = ~85,000 rows max, ~130MB raw per refresh
- **[Observed]** UOM change → trigger refetch toàn bộ 17 queries (do `applied` thay đổi)
- **[Reported]** ClickHouse có thể xử lý 17 query song song dễ dàng, nhưng nghẽn thường ở:
  - Frontend network: 17 HTTP request HTTP/1.1 = browser concurrency limit (~6 connections)
  - Backend: 17 query đồng thời chiếm 17 connection pool slot
  - Browser memory: parse 85k rows = vài trăm MB heap

### Stakeholder lens
| Stakeholder | Quan tâm |
|------------|---------|
| Ops Manager | "Tại sao dashboard load 8 giây?" |
| Dev-FE | Maintain 17 useQuery code khó |
| DA-CH | Tối ưu ClickHouse query → MV nếu cần |
| Dev-BE | Connection pool quản lý |

### Đề xuất — **Phase 3 (v1.3.0): Consolidate sau khi UI reorg**:

#### Phase 1 — Quick wins (v1.1.0)
- Bỏ `sql-cards-cbm` query phụ trợ (drift: subtitle CBM forced) → 17 → 16
- Bỏ legacy fallback queries `sql-charts`, `sql-table` (nếu không tenant nào dùng) → 16 → 14

#### Phase 2 — Sau UI reorg (v1.2.0)
- Cắt 4 bảng Summary (T3-T6) → cắt 4 query → 14 → 10

#### Phase 3 — Consolidate (v1.3.0)
- 1 unified status query (returns: status + whseid + region + customer + channel + sum_volume) — replace 6 queries (`cardKpiStatus` + 5 chart)
- 1 detail query (T9 Flash Detail)
- 1 completion query (T1)
- 1 dropped query (T7+T8 merged)
- 1 filter dropdown (whseid, brand etc — gốc) — already exists
- **Total: 5 queries** (vs 17 hiện tại)

#### Phase 4 — Performance optimization (v1.4.0+)
- ClickHouse MV pre-aggregate theo `(date, status, dimension)` → giảm scan
- Backend cache layer cho cùng filterOverrides
- HTTP/2 multiplexing thay vì 17 request riêng

**Status**: [Reported best practice] — cần `/da-ch` benchmark cụ thể.

### Rủi ro nếu KHÔNG consolidate
- Browser memory leak khi UOM/filter đổi liên tục
- Network latency tích lũy → user trải nghiệm lag
- ClickHouse load spike khi nhiều user mở dashboard cùng lúc

### Verification path
- `/da-ch` benchmark: chạy 17 query đồng thời, đo p95 latency vs p95 latency của 5 unified query
- Browser: dùng Chrome DevTools Performance Profile đo memory + time-to-interactive

---

## OQ-10 — FormConfig DSHFLADTG01..09 đã seed cho Mondelez?

> **Câu hỏi gốc**: 9 FormConfig codes đã được seed chưa? Backend tenant Mondelez có config cho 9 grid này không?

### Evidence collected
- **[Observed]** 9 codes `DSHFLADTG01..DSHFLADTG09` được hardcode trong `widget-flash-daily-detail.tsx`
- **[Observed]** Spec §18: yêu cầu backend seed cho Mondelez tenant
- **[Observed]** Spec drift #7 **High**: T1 Completion có synthetic fallback 54 dòng "sinh số liệu giả" nếu `tblCompletion` rỗng — nguy hiểm cho production decision

### Business rule khám phá

```
## BR-MDL-FD-003: Cấm dùng synthetic data trên dashboard production
- **Statement**: Bất kỳ widget nào trên dashboard production CỦA TENANT Mondelez phải có
  SQL config thật, KHÔNG được render synthetic/mock data ngay cả khi config rỗng.
- **Owner**: PM Smartlog + Mondelez tenant admin
- **Source**: Assumed từ Smartlog product policy — cần PM confirm
- **Exceptions**: Trên môi trường demo/training → có thể dùng mock với badge "DEMO DATA"
- **Tenant scope**: All production tenants
- **System impact**: Widget render logic phải có guard `!hasSqlConfig => "No data, please configure"`,
  KHÔNG được hiển thị synthetic
```

### Stakeholder lens
| Stakeholder | Risk |
|------------|------|
| Ops Manager Mondelez | Quyết định dựa số liệu giả → mất tiền |
| Tenant Admin | Audit fail nếu khách phát hiện |
| PM Smartlog | Reputational risk |
| Dev-BE | Phải seed config trước rollout |

### Đề xuất — **Audit + Block rollout nếu thiếu**:

#### Step 1 — Audit ngay
```sql
-- Backend SQL Server / PostgreSQL
SELECT code, table_name, tenant_id, is_active
FROM form_config
WHERE code LIKE 'DSHFLADTG%' AND tenant_id = '<mondelez_tenant_id>'
ORDER BY code
```

Expected: 9 rows (DSHFLADTG01 đến DSHFLADTG09). Nếu < 9 → BLOCK rollout v1.x cho đến khi seed đủ.

#### Step 2 — Bỏ synthetic fallback cho T1
Code [widget-flash-daily.tsx:1809-1919](../../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx#L1809-L1919) — thay vì synthetic 54 dòng, render empty state:

```
┌────────────────────────────────────────┐
│ Report tỷ lệ hoàn thành                │
│                                         │
│  ⚠️ Chưa có dữ liệu cấu hình            │
│  Liên hệ admin để config tblCompletion │
└────────────────────────────────────────┘
```

#### Step 3 — Seed script
Tạo migration backend seed 9 FormConfig cho Mondelez tenant với SQL queries thật.

**Status**: [Observed gap] — verification + fix bắt buộc.

### Rủi ro nếu rollout mà chưa seed
- T1 Completion render 54 dòng synthetic → Ops Manager đọc và quyết định sai
- KPI cards = 0 nếu cardKpiStatus chưa có → user nghĩ "dashboard chết"

### Verification path
- `/backend` audit DB: chạy SQL trên
- `/qa-executor`: test case "Mở Flash Daily widget với tenant mới chưa seed → expect empty state với message rõ ràng, KHÔNG synthetic"

---

## Summary matrix

| OQ | Mức độ | Evidence | Đề xuất ngắn | Block v1.1.0? | Verification |
|----|--------|----------|--------------|---------------|--------------|
| 01 | High | Assumed | 3 phase: Storytelling P0 / UI reorg P1 / Performance P2 | KHÔNG (đã quyết Phase 1) | Workshop PM |
| 02 | High | Reported + Assumed | Target overall 95%, FRESH 97%, POSM 90% — RAG bands | **CÓ** — cần Ops confirm | Workshop Ops Mondelez |
| 03 | Med | Reported + Observed | GIỮ cse default + persistent user pref + fix CBM subtitle | KHÔNG | Hỏi 3 Ops Manager |
| 04 | Med | Reported + Observed | YES — 3-layer KPI card (value + delta + target) | KHÔNG (recommend mạnh) | UX test 3 mock cards |
| 05 | Med | Assumed | Audit usage rồi cắt T2/T3/T5/T6 (giữ T1/T7/T8/T9) | KHÔNG (do v1.2) | /da-ops audit |
| 06 | Low | Reported | N selector + sort selector + search box | KHÔNG | Implement + monitor |
| 07 | Med | Observed bug | Fix root cause — thêm `customer_type` field từ master | KHÔNG (long-term) | /da-ch + dev-be |
| 08 | **High** | Reported risk | Test case verify + tooltip caveat + STM health badge | **CÓ** — verify trước rollout | /da-ch + qa-executor |
| 09 | Med | Reported + Observed | Phased consolidate 17 → 5 queries qua 3 release | KHÔNG (v1.3) | /da-ch benchmark |
| 10 | **High** | Observed gap | Audit seed + bỏ synthetic fallback + empty state | **CÓ** — block production | /backend + /qa-executor |

**Block v1.1.0 rollout nếu chưa giải quyết**: OQ-02 (target), OQ-08 (STM lag verify), OQ-10 (FormConfig seed).

---

## Business Rules Discovered (để add vào `business-rules.md`)

| ID | Tên | Tenant | Severity |
|----|-----|--------|----------|
| BR-MDL-FD-001 | Phân loại khách hàng NPP vs Customer | Mondelez | Med |
| BR-MDL-FD-002 | Source of truth = STM ATD signal | Mondelez | High |
| BR-MDL-FD-003 | Cấm synthetic data trên production dashboard | All tenants | High |

---

## Stakeholder map cho Workshop

| Stakeholder | Role | Power | Interest | Strategy |
|------------|------|-------|----------|----------|
| Ops Manager Mondelez | Decide target % + UOM workflow | **High** | **High** | **Manage closely** — owner workshop |
| PM Smartlog | Decide scope v1.1.0 | High | High | Manage closely |
| WH Manager (3 kho lớn) | Validate target per warehouse | Med | High | Keep informed |
| Planner Mondelez | Validate dimension drilldown | Med | Med | Keep informed |
| CS team | Validate T9 detail use case | Low | Med | Keep informed |
| IT Mondelez | Verify STM signal + master data customer_type | Med | Med | Consult |
| Dev-FE Smartlog | Implement v1.1.0 | Low | High | Inform after workshop |
| DA-CH Smartlog | Audit query + benchmark | Low | High | Consult |

---

## Next Steps (handoff)

| # | Hành động | Owner | Deadline đề xuất | Skill kế tiếp |
|---|-----------|-------|------------------|---------------|
| 1 | Workshop 60 min với Ops Manager Mondelez + PM Smartlog | DA-Biz-BA | Tuần này | `/da-biz-ba` (workshop notes) |
| 2 | Audit usage 9 bảng qua activity log | DA-Ops | 3 ngày | `/da-ops` |
| 3 | Audit FormConfig seed cho Mondelez tenant | Backend dev | 1 ngày | `/backend` |
| 4 | Audit STM signal lag pattern qua ClickHouse | DA-CH | 2 ngày | `/da-ch` |
| 5 | Sau workshop + audit → viết PRD v1.1.0 addendum | IT-BA (Smartlog PM) | Sau khi 1-4 xong | `/ba` |
| 6 | PRD v1.1.0 review | BA-Review | Sau (5) | `/ba-review` |
| 7 | Technical plan cho v1.1.0 | Planner | Sau (6) | `/planner` |

---

## Open issues còn lại (cần thêm 1 vòng analysis)

- **OQ-04**: Reference cho "delta vs hôm qua" là **same time yesterday** hay **MTD daily avg** hay **cùng kỳ tuần trước**? — workshop hỏi
- **OQ-08**: Có override manual khi STM down > 4h không? — IT Mondelez confirm
- **OQ-10**: Synthetic fallback có dùng cho môi trường demo không? — PM Smartlog confirm policy

---

## Phụ lục — Câu hỏi gợi ý cho Workshop

### Phần 1 — Mục đích refresh (OQ-01, OQ-04)
1. *"Nếu chỉ làm được 1 trong 3 việc trong tháng này — storytelling, UI gọn, performance — bạn chọn cái nào? Tại sao?"*
2. *"Mỗi sáng bạn mở dashboard này lúc mấy giờ? Mục đích chính là gì?"*
3. *"Nếu chỉ thấy 1 con số duy nhất, bạn muốn thấy con số nào?"*

### Phần 2 — Target (OQ-02)
4. *"Mondelez có commit % OTD/OTIF với khách hàng KA/MT không? Số là bao nhiêu?"*
5. *"FRESH (sữa kem) có quy định riêng so với DRY không?"*
6. *"Khi % hoàn thành < bao nhiêu thì bạn báo cáo lên cấp trên?"*

### Phần 3 — UOM & workflow (OQ-03)
7. *"Bạn báo cáo cho sếp dùng đơn vị gì? cse / tấn / pallet?"*
8. *"Có bao giờ bạn cần đổi UOM trên dashboard không? Khi nào?"*

### Phần 4 — Use case của 9 bảng (OQ-05, OQ-06)
9. *"Trong tab Chi tiết bảng, bảng nào bạn xem nhiều nhất hằng ngày?"*
10. *"Bạn có bao giờ search 1 khách hàng cụ thể trên chart không?"*

### Phần 5 — Data trust (OQ-07, OQ-08, OQ-10)
11. *"Có bao giờ bạn nghi ngờ số liệu trên dashboard không khớp thực tế không? Tình huống nào?"*
12. *"Khi STM down, bạn dùng nguồn nào để biết xe đang ở đâu?"*
13. *"Bạn có biết khi nào dashboard này dùng số liệu giả không?"* (kiểm tra awareness về synthetic fallback)

---

```
ARTIFACT_PATH: projects/mondelez/01-sections/flash-daily/analysis/flash-daily-oq-resolution.md

EVIDENCE_GAPS:
  - [OQ-01] Mục đích refresh — cần PM Smartlog confirm scope v1.1.0
  - [OQ-02] Target 95%/97%/90% — cần Ops Manager Mondelez confirm SLA contractual
  - [OQ-02] Cargo-specific override — cần Ops xác nhận FRESH/POSM khác
  - [OQ-04] Reference cho delta — yesterday vs MTD avg vs same-day-last-week
  - [OQ-05] Usage 9 bảng — cần /da-ops audit log
  - [OQ-07] Field customer_type — cần /da-ch verify master data có field này không
  - [OQ-08] STM lag pattern — cần /da-ch query thực tế lag distribution
  - [OQ-10] FormConfig DSHFLADTG01..09 seeded — cần /backend audit DB

HANDOFF_TO:
  - /da-biz-ba (workshop notes sau buổi họp với Ops + PM)
  - /da-ops (audit usage 9 bảng — 3 ngày)
  - /backend (audit FormConfig seed — 1 ngày)
  - /da-ch (audit STM signal + customer_type — 2 ngày)
  - /ba (sau khi 4 audit + workshop xong → viết PRD v1.1.0 addendum)
```
