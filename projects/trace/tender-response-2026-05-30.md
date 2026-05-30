# Trace Report — Tender Response (Tỷ lệ đáp ứng chuyến gửi thầu)

**Date**: 2026-05-30
**Auditor**: PM/DA via `/da-trace`
**Scope**: `mondelez/01-sections/tender-response` — widget `WidgetTenderResponse`
**Branch / commit**: `main` @ `a27857c` (workspace `helix-projects`)
**Audited against**: glossary (current canonical) + reference cũ `[done] ty_le_dap_ung_va_tuan_thu` + MV DDL `mv_dap_ung_gui_thau` + sql-registry §Fulfillment Ratio

---

## Sources used

| Source | Path | Status |
|---|---|---|
| Section PRD | `01-sections/tender-response/prd.md` | 🚫 **Empty (2 bytes)** trước audit → đã thay bằng `tender-response-prd.md` v1.0.0 |
| Section spec | `01-sections/tender-response/spec.md` | 🚫 Empty → đã thay bằng `tender-response-spec.md` |
| Section wireframe | `01-sections/tender-response/wireframe.md` | 🚫 Empty → đã thay bằng `tender-response-wireframe.md` |
| Reference PRD (cũ) | `05-reference/[done] ty_le_dap_ung_va_tuan_thu/tender-response-rate.prd.md` | Present — hệ Smartlog cũ |
| Glossary | `glossary/01-widgets.md`, `02-kpis.md`, `03-business-terms.md`, `06-data-layer.md`, `99-discrepancies.md` | Present (canonical) |
| MV DDL | `02-data/.../analytics-workspace_mvs.sql:1239-1375` | Present — verified |
| SQL registry | `02-data/data-sources/sql-registry.md` §Fulfillment Ratio | Present — scorecard verified |
| Frontend widget | `frontend/.../widget-tender-response.tsx` | 🚫 **Missing source** (repo không có local) — không trace được code |

---

## Drift summary

- ✅ Conformant: **5** (5 input conditions của MV khớp reference §8.2; core logic 1:1 khớp)
- ⚠️ Minor drift (terminology / cosmetic): **3**
- ❌ Functional drift: **0** (không phát hiện sai logic — chỉ chưa trace được FE)
- 🚫 Missing source: **2** (frontend widget; `% Commit Response` chưa có MV/folder rõ)

---

## Claim matrix

| # | Claim | Source ref | Evidence | Status | Severity |
|---|---|---|---|---|---|
| 1 | Tender đáp ứng = 1:1 (không gom/tách) | reference PRD §5.3 | `mv_dap_ung_gui_thau` line 1307: `if((cnt_van_hanh≥2) OR (cnt_gui_thau≥2), false, true)` | ✅ | — |
| 2 | Input: TenderMasterID ≠ null | ref §8.2 | DDL `trip_tender_id != -1` | ✅ | — |
| 3 | Input: ServiceOfOrderName = Xuất bán | ref §8.2 | DDL `o.service_code = 'XB'` | ✅ | — |
| 4 | Input: 2 GroupOfVehicleName ≠ null | ref §8.2 | DDL `header_group_vehicle_sk != -1` & `tender_group_vehicle_sk != -1` | ✅ | — |
| 5 | Input: StatusOfDITOMaster = Đã hoàn thành | ref §8.2 | DDL `t.status_id > 98` | ✅ | Low — xác nhận ngưỡng 98 |
| 6 | % đáp ứng = đáp ứng / tổng × 100, divide-by-zero an toàn | glossary 02-kpis, ref §5.7 | sql-registry: `round(... / nullIf(countDistinct(id_chuyen_gui_thau),0), 2)` | ✅ | — |
| 7 | Section docs (prd/spec/wireframe) tồn tại & có nội dung | README convention | File rỗng 2 bytes | 🚫→✅ | High (đã fix) |
| 8 | `% Commit Response` được implement | glossary 02-kpis L146 | Không có folder/MV gắn rõ; tồn tại `mv_dap_ung_van_hanh` chưa confirm | 🚫 | Med |
| 9 | Behavior FE đúng PRD (filter, sort, export) | — | Frontend không có local | 🚫 Not verifiable | Med |

---

## Cross-doc consistency findings

| # | Drift type | Detail | Sources in conflict | Severity |
|---|---|---|---|---|
| 1 | Scope | Reference cũ có Acceptance Rate / Avg Response Time / Compliance Score / status Excellent-Critical — không tồn tại trong MV/scope hiện tại | reference vs glossary/MV | Med |
| 2 | Terminology | glossary: "% Tender Response = số NVC **nhận thầu**" — gây hiểu nhầm; logic thật là mapping 1:1 (gom/tách), không phải carrier accept | glossary 02-kpis vs MV logic | Med |
| 3 | Field naming | `MasterCode`/`TenderMasterID`/`StatusOfDITOMaster` (ref) vs `id_chuyen_van_hanh`/`id_chuyen_gui_thau`/`status_id` (MV) | reference vs DDL | Low |
| 4 | Default value | `date_type` default = ATA (ref) vs `Ngày gửi thầu` (widget khác) | reference vs convention | Low |
| 5 | Missing folder | `commit-response-rate` có ở `05-reference/`, không có ở `01-sections/` | glossary 99-discrepancies | Med |

---

## Recommended actions

| # | Action | Owner | Type | Effort |
|---|---|---|---|---|
| 1 | Chốt scope `% Commit Response` (tạo folder mới `commit-response-rate/` dựa MV `mv_dap_ung_van_hanh`, hay thêm KPI thứ 2) | BA | Decision | M |
| 2 | Chốt default `date_type` (ATA vs Ngày gửi thầu) | BA/PM | Decision | S |
| 3 | Định nghĩa ngưỡng RAG cho `% Tỷ lệ đáp ứng` | BA | Doc | S |
| 4 | Khi có repo frontend → trace `WidgetTenderResponse` nâng docs lên Observed; verify cách truyền biến ALL | DA | Code trace | M |
| 5 | Verify `byVendor` / `byTime` SQL trên `analytics_workspace` | DA via `/da-ch` | Verification | S |
| 6 | Sửa wording glossary "nhận thầu" → "đáp ứng (mapping 1:1)" | BA | Doc fix | S |

---

## Open questions (block sign-off)

- Q1: `% Commit Response` có trong scope tenant Mondelez? — owner: BA — by: trước UAT
- Q2: Default `date_type`? — owner: BA/PM — by: trước build
- Q3: Ngưỡng % đáp ứng mục tiêu (RAG)? — owner: BA — by: trước build chart
- Q4: `status_id > 98` đúng = "Đã hoàn thành"? — owner: DA/Dev — by: khi audit SQL

---

**ARTIFACT_PATH**: `projects/trace/tender-response-2026-05-30.md` + 3 file section `01-sections/tender-response/tender-response-{prd,spec,wireframe}.md`
**DRIFT_COUNT**: 0 High (functional) / 4 Med / 3 Low — cộng 2 Missing source
**BLOCKING_QUESTIONS**: 4
**RECOMMENDED_NEXT**: BA quyết Q1–Q3; DA trace frontend + verify chart SQL khi có repo
