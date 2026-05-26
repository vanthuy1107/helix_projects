# UAT Plan — {section} ({tenant})

> Template Mode A output. File path: `projects/{tenant}/{section}/uat/{section}-uat-plan.md`
> Mọi placeholder `<...>` phải fill thật, KHÔNG để rớt vào file final.

---

## 0. Metadata

| Field | Value |
|---|---|
| Section / View | `<vd: OTIF | Flash Daily | VFR Late-alert>` |
| Tenant | `<vd: Mondelez | Panasonic>` |
| Version Smartlog CT | `<vd: v1.5.0>` |
| PRD ref | `<đường dẫn {section}-prd.md>` |
| Spec ref | `<đường dẫn {section}-spec.md>` |
| Plan author | `<PM/BA tên>` |
| Plan date | `<YYYY-MM-DD>` |
| UAT scheduled window | `<YYYY-MM-DD → YYYY-MM-DD>` |
| UAT session(s) planned | `<N>` session, mỗi session ~`<2-3>` giờ |

---

## 1. Mục tiêu UAT

`<1-2 câu>` — vd "Xác nhận view OTIF Mondelez hiển thị số liệu khớp golden file của khách, công thức OTIF/OnTime/InFull đúng định nghĩa nghiệp vụ MDLZ, và SC Manager đọc được story L1→L6 để ra quyết định can thiệp."

## 2. Phạm vi UAT

### 2.1. Trong scope

- View / module: `<liệt kê>`
- Storytelling layer: L1, L2, L3, L4, L5, L6 (theo `{section}-spec.md`)
- Filter combination: `<liệt kê filter chính + 2-3 combo edge>`
- Time window: `<window mặc định + 1-2 window khác>`

### 2.2. Out of scope

- `<Module khác không UAT lần này>`
- `<Filter combination phức tạp ít dùng>`
- `<Performance load test cường độ cao (chỉ smoke test)>`

## 3. Phân lớp test — 4 lớp

| Lớp | Mục đích | Số TC dự kiến |
|---|---|---|
| **A. Data Reconciliation** | Số dashboard có khớp golden file + SQL raw không | `<N>` |
| **B. Business Logic** | Định nghĩa metric, công thức, edge case có đúng nghiệp vụ tenant không | `<N>` |
| **C. UX & Storytelling** | Khách đọc được story, ra quyết định gì | `<N>` |
| **D. Performance / Filter** | Response time, filter combo, drill-down | `<N>` |
| **Tổng** | | `<N>` happy + `<N>` edge |

## 4. Test environment

| Item | Value |
|---|---|
| Environment | `<UAT | Staging | Production read-only>` |
| URL | `<https://...>` |
| Tenant DB | `<connection string ref / claim TenantDBConfiguration>` |
| Test user account | `<email khách + role>` |
| Data freshness | `<refresh lúc nào, MV refresh interval>` |
| Browser yêu cầu | `<Chrome/Edge phiên bản tối thiểu>` |

## 5. Stakeholder & roles

| Role | Name | Trách nhiệm |
|---|---|---|
| Customer SC Manager | `<tên>` | Final signoff Mode E |
| Customer key user | `<tên>` | Thao tác chính trong session Mode C |
| Customer IT representative | `<tên>` | Hỗ trợ technical clarification |
| Smartlog PM | `<tên>` | Drive session, quyết định defer/escalate |
| Smartlog BA | `<tên>` | Clarify business rule, write defect log |
| Smartlog dev (on-call) | `<tên>` | Standby cho Critical defect cần hotfix |

## 6. Schedule

| Phase | Date | Activity |
|---|---|---|
| Mode A — Design | `<date>` | Plan + cases + reconciliation template |
| Pre-UAT — Golden file ask | `<date>` | Gửi spec golden file cho khách |
| Pre-UAT — Golden file received | `<date>` | Khách gửi file |
| Mode B — Dry-run | `<date>` | Run reconciliation matrix, fix lệch trước session |
| Mode C — Session 1 | `<date>` | Execute với khách |
| Mode D — Retest round 1 | `<date>` | Sau dev fix |
| Mode D — Retest round 2 (nếu cần) | `<date>` | |
| Mode E — Signoff | `<date>` | Final signoff |

## 7. Tolerance threshold

(Chốt **trong** Mode A, KHÔNG đổi sau khi đã thấy số lệch)

| Loại metric | Tolerance | Áp dụng cho |
|---|---|---|
| Số đếm tuyệt đối (đơn, volume) | ≤ 1% | Tổng đơn vận chuyển, tổng volume, count by status |
| % metric | ≤ 0.5 pp | OTIF%, OnTime%, InFull%, % drop |
| Ranking top N | ≥ 4/5 tên match | Top kho late, top customer drop |
| Tổng amount/cost | ≤ 0.5% | Cost-related metric (nếu có) |

Override nếu khách yêu cầu khắt khe hơn: `<ghi rõ override>`.

## 8. Pass criteria

| Tiêu chí | Threshold | Notes |
|---|---|---|
| Pass rate happy path | ≥ 95% | |
| Pass rate edge case | ≥ 80% | |
| Defect Critical open | 0 | Block tuyệt đối |
| Defect Major open | ≤ 2 + mitigation plan | |
| Reconciliation matrix | 100% trong tolerance HOẶC root cause + khách accept | |
| Performance: filter response | < 3s | |
| Performance: page load | < 5s | |

## 9. Defect routing (đã chốt trước, để session không bàn route)

| Defect lớp | Tech_layer hypothesis | Route to |
|---|---|---|
| A — Số lệch nguồn data | etl-data / sql-query | `/da-ch` audit → dev squad CH owner |
| A — Số lệch do filter/widget logic | frontend-widget / frontend-config | `/da-triage` → `/qa-executor` → dev FE |
| B — Logic sai vs nghiệp vụ | cross-stack (PRD trước, code sau) | `/ba` revision → `/da-trace` xác nhận |
| C — UX khó dùng nhưng đúng spec | frontend-config (drift PRD) | `/da-trace` → `/ba` revision |
| C — UX bug rõ (chữ tràn, nút chồng) | frontend-widget | `/da-triage` → dev FE |
| D — Perf chậm | backend-api / sql-query | `/da-ch` + dev squad theo module |

## 10. Risks & mitigation

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Golden file khách trễ | Med | High (block UAT) | Đẩy lớp B lên trước, dùng SQL raw làm chuẩn tạm |
| Khách bận, session bị cắt ngắn | High | Med | Defer rule rõ; ưu tiên lớp A trước |
| Dev không kịp fix Critical trong 1 round | Med | High (lùi signoff) | On-call dev sẵn cho Critical; escalate `/da-pm` nếu trễ |
| Data refresh không kịp giờ session | Low | Med | Confirm MV refresh schedule trước session |
| Khách thay đổi định nghĩa nghiệp vụ giữa UAT | Low | High | `/ba` revision PRD trước khi continue |

## 11. Communication plan

- **Trong session**: PM drive, BA log defect realtime, dev on-call qua Slack
- **Sau session**: gửi `{section}-uat-execution-{date}.md` + defect list cho khách trong 4 giờ
- **Trước retest**: confirm với khách "defect X đã fix, schedule retest ngày Y"
- **Signoff**: gặp mặt + sign tay (hoặc DocuSign nếu khách yêu cầu)

## 12. Approval

| Role | Name | Signed | Date |
|---|---|---|---|
| Smartlog PM | | | |
| Smartlog BA | | | |
| Customer SC Manager (approval to start UAT) | | | |
