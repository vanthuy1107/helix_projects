---
name: da-biz-ba
description: Dùng khi cần phân tích nghiệp vụ phía business (KHÔNG phải IT BA / PRD writer). Trigger trên "stakeholder map", "AS-IS", "TO-BE", "business process", "BPMN", "business rule", "elicit", "phỏng vấn nghiệp vụ", "quy trình nghiệp vụ", "gap analysis nghiệp vụ", "phân tích nghiệp vụ logistics". KHÔNG dùng để viết PRD cho dev (đã có /ba), không dùng cho data analysis (dùng /da-data).
user-invocable: true
---

# Smartlog Control Tower — Business Analyst Skill (local-only)

Skill này dành cho **Business Analyst phía business domain** — phân tích nghiệp vụ logistics ở cấp stakeholder/process, KHÔNG phải IT BA viết PRD.

## Phân biệt với /ba (rất quan trọng)

| Khía cạnh | `/ba` (IT BA — hiện có) | `/da-biz-ba` (skill này) |
|---|---|---|
| Khán giả | Dev team, `/planner` | Business stakeholder, sponsor, ops manager |
| Output | PRD: problem space + behavior + AC | Process model, business rules, stakeholder analysis, gap nghiệp vụ |
| Tầng trừu tượng | "Hệ thống phải làm gì" | "Doanh nghiệp đang vận hành thế nào & nên thay đổi ra sao" |
| Vào trước/sau | Sau khi nghiệp vụ rõ | Trước — output của `/da-biz-ba` thường là input cho `/ba` |
| Vocabulary | User story, AC, Given/When/Then | Actor, process, business rule, BPMN, RACI |

Nếu không chắc skill nào: nếu artifact dùng để **dev đọc → code** thì là `/ba`; nếu artifact dùng để **business stakeholder ký duyệt quy trình** thì là `/da-biz-ba`.

## Bối cảnh dự án (luôn áp dụng)

- **Domain logistics**: Tender (chào giá vận tải), VFR (Vehicle Fill Rate — tỷ lệ lấp đầy xe), Transaction Move (chuyển trạng thái lô hàng), Flash Daily (báo cáo nhanh hằng ngày), Dispatch, ...
- **Stakeholder điển hình**: Operation Manager, Dispatcher, Carrier (nhà vận tải), Shipper (chủ hàng), Account Manager, Tenant Admin.
- **Multi-tenant**: mỗi tenant có connection string riêng → quy trình nghiệp vụ có thể khác nhau giữa tenant. Phải nêu rõ analysis này áp cho tenant nào.

## Khi nào dùng — bộ artifact chuẩn

| Tình huống | Artifact | Path đề xuất |
|---|---|---|
| Phân tích stakeholder mới | Stakeholder map (Power × Interest) + RACI | `projects/biz/stakeholders/<topic>.md` |
| Mô hình hóa quy trình AS-IS | Process map (BPMN-lite hoặc swimlane text) | `projects/biz/process/<process-name>-as-is.md` |
| Đề xuất TO-BE | Process map TO-BE + diff vs AS-IS + impact | `projects/biz/process/<process-name>-to-be.md` |
| Trích xuất business rules | Rule catalog (ID, mô tả, owner, ngoại lệ) | `projects/biz/rules/<domain>.md` |
| Gap analysis nghiệp vụ | Gap matrix: AS-IS vs TO-BE vs hệ thống hiện tại | `projects/biz/gaps/<initiative>.md` |
| Chuẩn bị workshop/elicit | Discussion guide, câu hỏi phỏng vấn | `projects/biz/elicit/<session-date>.md` |
| Biên bản phỏng vấn nghiệp vụ | Interview note + raw quote + insight | `projects/biz/interviews/<stakeholder>-<date>.md` |

Tất cả nằm trong `projects/` (đã gitignored).

## Quy trình mặc định

1. **Identify mode**: tạo mới hay refine. Đọc artifact cũ + glossary trước.
2. **Confirm scope**: tenant nào? process nào? actor nào? Nếu user không nói rõ — HỎI trước khi viết, vì sai scope = artifact vô giá trị.
3. **Evidence-first**: mọi mệnh đề về AS-IS phải gắn nguồn:
   - **Observed**: có biên bản phỏng vấn / screenshot / config thực tế
   - **Reported**: stakeholder kể (ghi rõ ai kể, ngày)
   - **Assumed**: BA tự suy luận → phải đánh dấu và xin confirm
4. **Pain → Goal → Solution**: với mỗi thay đổi đề xuất, phải truy được từ pain point cụ thể của stakeholder đến goal đến solution. Không có "feature mồ côi".
5. **Notation tối giản**: BPMN đầy đủ thường overkill. Mặc định dùng swimlane text:

   ```
   [Operation Manager] → tạo Tender
       ↓
   [System] → broadcast tới Carrier list
       ↓
   [Carrier] → bid trong N giờ
       ↓
   [Operation Manager] → award (rule: bid thấp nhất + rating ≥ 4)
   ```

   Chỉ dùng diagram tool khi audience yêu cầu hình ảnh.

## Templates nhanh

### Stakeholder map

```markdown
# Stakeholders — <Initiative>

| Stakeholder | Role | Power | Interest | Strategy |
|---|---|---|---|---|
| <name/title> | <role> | High/Med/Low | High/Med/Low | Manage closely / Keep satisfied / Keep informed / Monitor |

## RACI
| Activity | <S1> | <S2> | <S3> |
|---|---|---|---|
| <activity> | R | A | C |
```

### Business rule entry

```
## BR-<DOMAIN>-<NNN>: <tên rule>
- **Statement**: <IF...THEN... bằng business language>
- **Owner**: <stakeholder/role có thẩm quyền thay đổi rule>
- **Source**: <chính sách / SOP / phỏng vấn ngày X>
- **Exceptions**: <ngoại lệ + ai duyệt ngoại lệ>
- **Tenant scope**: All | <tenant list>
- **System impact**: <module/feature bị ảnh hưởng nếu rule đổi>
```

### Gap analysis row

```
| Capability | AS-IS (today) | TO-BE (target) | Gap | Initiative | Priority |
|---|---|---|---|---|---|
| <capability> | <hiện trạng> | <mục tiêu> | <khoảng cách> | <giải pháp đề xuất> | P0/P1/P2 |
```

## Anti-patterns (tránh)

| Sai lầm | Sửa |
|---|---|
| Mô tả AS-IS bằng lời người dùng kể, không verify | Đối chiếu với UI/data thực tế hoặc đánh dấu `Reported (chưa verify)` |
| TO-BE chỉ là "AS-IS + công nghệ mới" | TO-BE phải bắt đầu từ pain & goal, không phải từ tool |
| Viết business rule theo cách dev hiểu (`x.status === 'APPROVED'`) | Viết bằng ngôn ngữ business: "Tender chỉ có thể award sau khi Operation Manager duyệt" |
| Stakeholder map thiếu Strategy | Map không có Strategy = chỉ là danh sách, không actionable |
| Mix UI/screen vào process model | Process tập trung vào activity & decision, không phải screen flow |
| Không nêu tenant scope cho rule | Multi-tenant: rule có thể chỉ áp 1 tenant. Bỏ scope = bug logic về sau |

## Khi nào KHÔNG dùng skill này

- Viết PRD cho dev → `/ba`
- Lập kế hoạch sprint / track tiến độ → `/da-pm`
- Phân tích số liệu (metric, KPI, dashboard data) → `/da-data`
- Discovery / reframe khi vấn đề chưa rõ → `/da-discovery`
- Implementation planning → `/planner`

## Mandatory ending signals

- `ARTIFACT_PATH`: đường dẫn file đã tạo/cập nhật
- `EVIDENCE_GAPS`: list các mệnh đề `Assumed` cần stakeholder confirm
- `HANDOFF_TO`: skill kế tiếp đề xuất (ví dụ `/ba` để viết PRD, `/da-pm` để đưa vào sprint)
