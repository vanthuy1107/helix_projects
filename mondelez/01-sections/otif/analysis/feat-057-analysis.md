# Analysis FEAT-057 — "Bổ sung lý do rớt là gồm cả 2 ()"

**Date**: 2026-05-12
**Requested by**: MDLZ team (Edit UX_UI_MDLZ.xlsx — Sheet7 row 66)
**Tenant scope**: MDLZ (Mondelez)
**Related stub**: [triage/discoveries/cross-stack/[-]-FEAT-057](../../../triage/discoveries/cross-stack/%5B-%5D-FEAT-057-other-bo-sung-ly-do-rot-la-gom-ca-2.md)
**Triage priority**: Major (cross-stack)
**Triage confidence**: High (item rõ rồi); **Data confidence cho analysis này**: **Medium** (raw quote thiếu context, có 3 cách diễn giải khả thi)
**Section docs (folder cha)**: [prd.md](../prd.md), [spec.md](../spec.md), [wireframe.md](../wireframe.md)
**Analysis cùng folder**: [assessment-2026-05-10.md](assessment-2026-05-10.md), [pulse-W19-2026-05-04_2026-05-09.md](pulse-W19-2026-05-04_2026-05-09.md)

---

## 1. Question (1 dòng business)

> Trong widget OTIF, khách muốn thêm một "lý do rớt" mới mang nghĩa "**gồm cả 2**" — nhưng "cả 2" cụ thể là cả 2 cái gì?

Raw quote (Excel) chỉ có 1 dòng và ngoặc `()` ở cuối bỏ trống → khả năng cao là khách đang chỉ vào 1 screenshot và viết tắt. Không có "Hiện tại / Note" đi kèm.

---

## 2. Bối cảnh data hiện tại (Observed)

Widget [`widget-otif.tsx`](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx) hiện tại có **3 nơi** đang phân loại "lý do rớt" — đây chính là 3 ứng viên cho từ "lý do rớt" trong yêu cầu.

### 2.1 Chart "Fail Ontime Reason" (`chartFailOntime`)

Đọc từ SQL trả về `reason, fail_so`. Phân nhóm hiện tại (theo PRD §3 và `REASON_COLORS` ở [widget-otif.tsx:576-582](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L576-L582)):

| # | Reason | Điều kiện business |
|---|--------|--------------------|
| 1 | Lỗi transport giao trễ | Ontime fail, `planned_cse = shipped_cse` |
| 2 | Lỗi warehouse gọi vào kho trễ | Ontime fail, `shipped_cse < planned_cse` |
| 3 | Lỗi transport vào kho trễ | Ontime fail, `shipped_cse > 0`, `delivered_cse < shipped_cse` |
| 4 | Lỗi rớt do warehouse | Infull fail, `shipped_cse < planned_cse` |
| 5 | Lỗi rớt do transport | Còn lại |

→ **5 reason mutually exclusive.** KHÔNG có bucket "cả warehouse + transport".

### 2.2 Chart "Fail Infull Reason" (`chartFailInfull`)

Đọc từ SQL cùng schema `reason, fail_so`. Theo PRD §3 (Phân loại Infull):

| # | Reason | Điều kiện |
|---|--------|-----------|
| 1 | Warehouse Infull failure | `shipped_cse < planned_cse` |
| 2 | Transport Infull failure | `delivered_cse < shipped_cse` |
| 3 | **WH + Transport Infull failure** | Cả hai đều lỗi |

→ **3 reason, ĐÃ CÓ bucket "cả 2".** Đây là đối xứng cho thấy việc "thiếu cả 2" ở Ontime là asymmetry.

### 2.3 Bảng "Fail Report" (`failSummary` query)

Columns bắt buộc trong SQL response ([widget-otif.tsx:317-357](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L317-L357)):

| Group | Column | Mục đích |
|-------|--------|---------|
| Tổng | `total_so`, `fail_ontime_so`, `fail_infull_so` | Tổng đơn rớt |
| Ontime breakdown (5 buckets) | `late_arrival_by_transport`, `late_wh_call_by_warehouse`, `late_pickup_by_warehouse`, `late_departure_by_transport`, `late_delivery_by_transport` | KHÔNG có "both" |
| Infull breakdown (3 buckets) | `warehouse_infull_failure`, `transport_infull_failure`, **`warehouse_transport_infull_failure`** | ĐÃ CÓ "both" |

→ **Cùng asymmetry như §2.1 vs §2.2**: Infull có cột "cả 2", Ontime không.

### 2.4 Cột text trong `OtifRow` (detail table)

OtifRow có 2 cột reason text-based ([widget-otif.tsx:432-433](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L432-L433)):

- `notInfullReason` — lý do rớt Infull của đơn đó
- `notOntimeReason` — lý do rớt Ontime của đơn đó

Mỗi đơn có thể có **cả 2** field non-null cùng lúc (đơn vừa rớt Ontime vừa rớt Infull). Nhưng UI chỉ render 2 cột riêng — không có cột tổng hợp "Lý do rớt" gộp cả 2.

### 2.5 KPI cards: % Ontime, % Infull, % OTIF

- `%OTIF = COUNT(Ontime AND Infull) / COUNT(DO) × 100`
- Tức ngầm hiểu "fail OTIF" = "NOT Ontime OR NOT Infull" (union)
- KHÔNG có metric "% Rớt cả 2 mặt" (intersection — đơn vừa fail Ontime vừa fail Infull) làm KPI riêng.

---

## 3. Hypotheses cho "gồm cả 2 ()"

Vì raw quote không nói rõ "()", có **3 cách diễn giải** mà data thực tế đang support:

| # | Hypothesis | Diễn giải | Evidence | Khả năng |
|---|-----------|-----------|----------|----------|
| **H-A** | "cả 2" = **warehouse + transport** | Khách muốn chart "Fail Ontime Reason" thêm bucket thứ 6 "Lỗi rớt do cả warehouse + transport" (đối xứng với Fail Infull đã có) | Asymmetry §2.1 vs §2.2; "WH + Transport Infull failure" đã tồn tại làm precedent | **High** |
| **H-B** | "cả 2" = **Ontime + Infull** | Khách muốn 1 bucket / KPI "đơn vừa rớt Ontime vừa rớt Infull" (intersection thay vì union) — phân loại đơn rớt theo nặng/nhẹ | OtifRow có cả `notOntimeReason` + `notInfullReason` cùng lúc nhưng không được aggregate | **Medium** |
| **H-C** | "cả 2" = **gộp 2 cột reason thành 1** | Trong detail table, gộp `notOntimeReason` + `notInfullReason` thành 1 cột "Lý do rớt" tổng | Detail table có 2 cột riêng; user xem table có thể muốn 1 cột tóm tắt | **Low–Medium** |

### 3.1 Vì sao H-A là Most Likely

- **Pattern matching**: Infull chart ĐÃ có "cả 2" → khách thấy Ontime chart THIẾU "cả 2" → ask "bổ sung". Đây là loại request UX/data parity rất phổ biến trong rollout.
- **"Lý do rớt" ngữ pháp**: cụm này thường được dùng cho chart Fail Ontime hoặc Fail Infull (mỗi bucket = 1 "lý do"), không dùng cho KPI tổng hợp.
- **Source ở Sheet7 row 66 — View=OTIF**: nếu là KPI tổng (H-B) chắc sẽ ở khu vực KPI cards trong Excel feedback.

### 3.2 Vì sao H-B vẫn cần để ngỏ

- Cụm "gồm cả 2" tiếng Việt thuần thường ám chỉ "đơn rớt cả Ontime VÀ Infull" — đây là intersection mà KPI hiện tại không phơi.
- Trong logistics MDLZ, đơn rớt "cả 2 mặt" có nghĩa business khác hẳn đơn rớt 1 mặt (cấp độ severity cao hơn) → có cơ sở business để bổ sung.

### 3.3 H-C không phủ nhận

- Có thể H-C đi kèm H-A hoặc H-B chứ không loại trừ.
- Detail table dài ~50 cột, khả năng khách quan tâm gộp cột là thấp hơn.

---

## 4. Findings

| # | Type | Statement | Evidence |
|---|------|-----------|----------|
| F-1 | **Fact** | Chart "Fail Ontime Reason" hiện có 5 bucket mutually exclusive, KHÔNG có bucket "cả warehouse + transport". | [widget-otif.tsx:576-582](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L576-L582), PRD §3 |
| F-2 | **Fact** | Chart "Fail Infull Reason" có 3 bucket, ĐÃ có "WH + Transport Infull failure". | PRD §3 (Phân loại Infull) |
| F-3 | **Fact** | Bảng `failSummary` có 5 cột Ontime + 3 cột Infull (cột thứ 3 Infull = `warehouse_transport_infull_failure`). Asymmetry tương tự §2.1 vs §2.2. | [widget-otif.tsx:317-357](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L317-L357) |
| F-4 | **Fact** | OtifRow detail có 2 trường reason độc lập (`notInfullReason`, `notOntimeReason`), không có trường tổng hợp. | [widget-otif.tsx:432-433](../../../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx#L432-L433) |
| F-5 | **Fact** | KPI `%OTIF` định nghĩa = Ontime AND Infull → fail OTIF là union (NOT Ontime OR NOT Infull). KHÔNG phơi intersection. | PRD §3 (định nghĩa OTIF) |
| I-1 | **Insight** | Có 1 asymmetry rõ giữa Ontime classification (5 bucket, không có "both") và Infull classification (3 bucket, có "both"). Hypothesis A khớp pattern này tự nhiên nhất. | F-1, F-2, F-3 |
| I-2 | **Insight** | Đơn "rớt cả Ontime + Infull" hiện được đếm 2 lần trong 2 chart riêng → user xem cộng 2 chart có thể bị over-count nếu hiểu nhầm. | F-1, F-2, F-5 |
| H-1 | **Hypothesis** | Nếu chỉ thêm bucket H-A (warehouse + transport cho Ontime), số đơn rớt Ontime "cả 2 NVC+kho" hiện tại đang bị phân loại vào bucket "Lỗi rớt do transport" (catch-all "còn lại") → khi tách ra sẽ làm giảm con số bucket #5 hiện tại. Cần audit query SQL backend để verify. | Classifier rule "Còn lại → Lỗi rớt do transport" |
| H-2 | **Hypothesis** | Hỏi MDLZ rõ "()" trong quote có thể là khách định gõ tên 2 lý do cụ thể nhưng quên paste — vd "(warehouse + transport)" hoặc "(ontime + infull)". | Patterns phổ biến trong Excel feedback (quote bỏ dở) |

---

## 5. Recommendation

### 5.1 Hành động ngay (trước khi commit dev)

1. **Clarification từ MDLZ** — gửi 3 câu hỏi tới rollout/PO:
   - Q1: "Lý do rớt" trong yêu cầu đang nói tới **chart nào** — Fail Ontime, Fail Infull, hay bảng Fail Report?
   - Q2: "Gồm cả 2" có phải nghĩa **"lỗi do cả warehouse + cả transport"** (giống bucket "WH + Transport Infull failure" hiện có ở chart Infull)?
   - Q3: Hay là khách muốn 1 KPI/bucket tổng hợp **"đơn vừa rớt Ontime vừa rớt Infull"**?
   - Đính kèm screenshot 2 chart Fail Ontime / Fail Infull để khách chỉ trỏ trực tiếp.

2. **Audit SQL backend** (nếu H-A đúng) — kiểm tra query `chartFailOntime` và cột `late_*_*` trong `failSummary`:
   - Đếm xem hiện tại có bao nhiêu đơn fall vào case "shipped < planned VÀ delivered < shipped" (cả 2 lỗi) — đang được gán reason gì?
   - Verify hypothesis H-1: bucket "Lỗi rớt do transport" (catch-all) có đang chứa đơn loại này không.

### 5.2 Đề xuất giải pháp (conditional)

**Nếu Q2 = Yes (H-A confirmed):**
- **Data**: bổ sung 1 bucket reason mới `Lỗi rớt do cả warehouse + transport` (hoặc tên ngắn gọn hơn — let BA decide) vào classifier query backend. Bucket này chỉ chiếu cho **Fail Ontime** (vì Infull đã có).
- **SQL `failSummary`**: bổ sung cột mới `warehouse_transport_ontime_failure` (đối xứng với `warehouse_transport_infull_failure`).
- **FE**: thêm color trong `REASON_COLORS`, không cần thay đổi chart structure.
- **Tác động data**: con số bucket "Lỗi rớt do transport" hiện tại sẽ giảm — cần thông báo cho user về retro-comparison khi go-live.

**Nếu Q3 = Yes (H-B confirmed):**
- **Data**: thêm KPI card thứ 5 hoặc 1 chart phụ "Đơn rớt cả 2 mặt" — metric mới = `COUNT(DO WHERE NOT Ontime AND NOT Infull)`.
- **SQL**: bổ sung 1 query mới (vd `bothFailure`) hoặc bổ sung cột `both_fail_so` vào query `cards`.
- **PRD impact**: Cần update §3 (định nghĩa nghiệp vụ) và §5.1 (KPI Cards), §6 (queries).
- **Tác động lớn hơn H-A** — phải mở 1 PRD revision riêng.

**Nếu cả H-A và H-B đều True (khách muốn 2 thứ):**
- Tách thành 2 PRD ask khác nhau, gán FEAT-057 cho H-A, mở FEAT-057b cho H-B.

### 5.3 Owner & success metric

- **Owner clarification**: BA/PO MDLZ rollout (TBD — chưa assign trong triage).
- **Success metric sau implement**:
  - H-A: số % đơn rớt được "explain" bằng 1 reason cụ thể tăng (giảm "catch-all transport").
  - H-B: user khảo sát confirm họ ưu tiên đơn "rớt cả 2 mặt" trong action plan hàng ngày.

---

## 6. Caveats

- **Quote source mơ hồ**: "()" bỏ trống là dấu hiệu khách paste/gõ chưa xong. **KHÔNG nên build trước khi clarify**.
- **Chưa có data thực tế từ MDLZ**: distribution thực của 5 bucket Ontime hiện tại ở môi trường MDLZ ClickHouse chưa được sample → khi audit query, dùng tenant data MDLZ chứ không phải sandbox.
- **Backend cross-stack**: vì query reason phân loại nằm ở SQL (config trong widget settings), thay đổi này có thể chỉ là **config-level** (chỉnh SQL trong settings dialog) chứ không cần code change → cần backend dev confirm.
- **Tenant scope**: yêu cầu này là MDLZ-specific (rollout feedback) — KHÔNG được biến nó thành platform feature trừ khi BA xác nhận có giá trị cross-tenant.

---

## 7. Handoff path

```
FEAT-057 (this analysis)
   ↓
[NEXT] /da-discovery — chạy 5 câu hỏi office-hours với MDLZ rollout, thu thập answers Q1/Q2/Q3 (mục §5.1)
   ↓
   ├─ Nếu H-A confirmed → /ba revise PRD OTIF §3 + §6.failSummary → /planner → /backend (update SQL) → /frontend (REASON_COLORS)
   ├─ Nếu H-B confirmed → /ba mở PRD revision lớn (KPI mới) → /planner → /backend (cards query) → /frontend (new card)
   └─ Nếu khách trả lời khác → quay lại analysis, update hypotheses
```

---

`ARTIFACT_PATH`: [projects/mondelez/01-sections/otif/analysis/feat-057-analysis.md](feat-057-analysis.md)
`DATA_CONFIDENCE`: **Medium** — code paths + PRD đều rõ, nhưng raw quote MDLZ thiếu context → 3 hypotheses song song, cần clarification trước khi commit dev.
`NEXT_ACTION`: **`/da-discovery`** với 3 câu hỏi clarification ở §5.1; song song có thể giao **`/backend`** audit query `chartFailOntime` SQL để verify H-1 (bucket catch-all đang chứa "cả 2"). KHÔNG handoff `/ba` hay `/planner` trước khi MDLZ trả lời.
