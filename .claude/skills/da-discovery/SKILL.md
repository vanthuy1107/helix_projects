---
name: da-discovery
description: Dùng khi vấn đề chưa rõ, cần thử thách giả định, reframe trước khi viết spec/PRD. Cảm hứng từ "office-hours" của gstack — buộc trả lời các câu hỏi khó về user, value, alternative trước khi đầu tư vào solution. Trigger trên "discovery", "khám phá vấn đề", "reframe", "challenge giả định", "có nên làm X không", "vấn đề chưa rõ", "spike sản phẩm". KHÔNG dùng khi đã có PRD rõ ràng (chuyển sang /planner) hoặc khi cần technical research (dùng /research-ideation).
user-invocable: true
---

# Smartlog Control Tower — Discovery / Office Hours (local-only)

Cảm hứng từ `/office-hours` trong [gstack](https://github.com/garrytan/gstack) — *the point isn't who typed it, it's what shipped*. Skill này tồn tại để **chặn** việc nhảy vào spec/code khi vấn đề chưa rõ.

## Triết lý

- Một spec sai nhưng được thực thi hoàn hảo còn tệ hơn không làm gì.
- 90% giá trị của discovery nằm ở việc **đặt đúng câu hỏi**, không phải tìm câu trả lời.
- Discovery KHÔNG phải research công nghệ (`/research-ideation`), KHÔNG phải PRD (`/ba`), KHÔNG phải planning (`/planner`). Nó là filter trước những skill đó.

## Khi nào dùng

- Stakeholder đến với 1 yêu cầu kiểu "thêm widget X" / "làm dashboard Y" — và bạn không chắc nó giải quyết vấn đề gì.
- Có 2-3 hướng tiếp cận và phải chọn trước khi đầu tư.
- Bạn cảm thấy "có gì đó chưa đúng" nhưng chưa diễn đạt được.
- Initiative lớn, cần align stakeholder trước khi thành lập sprint.

## Output

| Artifact | Path |
|---|---|
| Discovery brief (1 trang) | `projects/discovery/<YYYY-MM-DD>-<slug>.md` |

Output nằm trong `projects/` (gitignored).

## Quy trình bắt buộc — 5 câu hỏi không né tránh

Mỗi discovery PHẢI trả lời cả 5 câu, không bỏ qua, không trả lời chung chung:

### 1. Vấn đề thực sự là gì?
- Phát biểu vấn đề bằng 1 câu, không nhắc tới solution.
- Ai đang chịu vấn đề này? Cụ thể (Operation Manager tại tenant X, không phải "users").
- Hiện tại họ workaround thế nào?
- Nếu không giải quyết, hậu quả gì? Đo được không?

### 2. Tại sao là BÂY GIỜ?
- Vấn đề này tồn tại bao lâu rồi? Tại sao trước đây không làm?
- Có deadline / sự kiện external nào ép timing không? (compliance, hợp đồng tenant, mùa cao điểm logistics...)
- Nếu trì hoãn 3 tháng, mất gì?

### 3. Ai THỰC SỰ muốn cái này?
- Stakeholder nào sẽ dùng? (không phải ai đề xuất — ai sẽ dùng hằng ngày)
- Họ đã được hỏi chưa? Đã thấy hành vi của họ chưa?
- Đề xuất đến từ user, sales, hay phỏng đoán nội bộ? Phân biệt rõ.

### 4. Alternative nào đã loại?
- Liệt kê tối thiểu 2 cách khác để giải quyết cùng vấn đề.
- Vì sao loại từng cái? Bằng chứng?
- Có giải pháp "do nothing" / process change (không cần code) không? Vì sao không đủ?

### 5. Cách đo thành công?
- Sau 30 / 60 / 90 ngày kể từ release, metric nào sẽ thay đổi?
- Đo bằng cách nào? (event log có không? cần track mới?)
- Ngưỡng nào coi là thành công? Ngưỡng nào coi là thất bại / rollback?

## Template Discovery Brief

```markdown
# Discovery: <Tên vấn đề, KHÔNG phải tên solution>

**Date**: <YYYY-MM-DD>  
**Requested by**: <ai mở discovery>  
**Status**: Open | Converged | Killed

## 1. Problem
<1 câu, không nhắc solution>

- **Who suffers**: <stakeholder cụ thể, tenant cụ thể>
- **Current workaround**: <hiện tại họ làm gì>
- **Cost of inaction**: <đo được nếu có>

## 2. Why now
<Lý do timing>

## 3. Real demand
- **Source**: User request | Sales push | Internal hypothesis
- **Evidence of demand**: <conversation, ticket, behavior>
- **End user persona**: <người dùng hằng ngày>

## 4. Alternatives considered
| # | Alternative | Why rejected |
|---|---|---|
| A | Do nothing / process change | <lý do hoặc "cần verify"> |
| B | <giải pháp khác> | <lý do> |
| C | <đề xuất hiện tại> | <Pending — đang là default> |

## 5. Success metric
- **Leading indicator (30 ngày)**: <metric>
- **Lagging indicator (90 ngày)**: <metric>
- **Tracking source**: <log, query, manual>
- **Rollback threshold**: <số liệu xấu tới mức nào thì rút>

## Verdict
- [ ] **Proceed** → handoff `/da-biz-ba` (nếu cần process model) hoặc `/ba` (nếu đã rõ behavior)
- [ ] **Park** — quay lại sau khi: <điều kiện>
- [ ] **Kill** — vì: <lý do>

## Open questions blocking verdict
- Q: <câu hỏi> — owner: <ai trả lời> — by: <date>
```

## Anti-patterns (tránh)

| Sai lầm | Sửa |
|---|---|
| Phát biểu vấn đề kèm solution ("vấn đề: chưa có dashboard tender") | Vấn đề thật là gì khiến cần dashboard? "Operation Manager mất 30 phút mỗi sáng để gom data tender từ 4 nguồn" |
| "End user là 'users'" | Cụ thể: vai trò + tenant + tần suất sử dụng |
| Liệt kê alternative cho có, không phân tích | Mỗi alternative phải có lý do reject thực chất, có evidence |
| Success metric kiểu "users hài lòng" | Phải đo được, có nguồn data, có ngưỡng |
| Skip discovery vì "đã rõ rồi" | Nếu thực sự đã rõ — viết 5 câu trả lời này trong 15 phút và confirm. Nếu không viết được = chưa rõ |
| Discovery kéo dài vô hạn | Time-box: 1-3 ngày. Nếu chưa converged → "Park" có ngày quay lại |

## Verdict-driven (gstack-style)

Discovery **PHẢI kết thúc bằng 1 trong 3 verdict**: Proceed | Park | Kill. Không có "tiếp tục thảo luận". Nếu không quyết được → ghi rõ blocker (câu hỏi cụ thể + ai trả lời + deadline).

## Khi nào KHÔNG dùng skill này

- Đã có PRD rõ → `/planner`
- Cần research công nghệ / so sánh tool → `/research-ideation`
- Cần phân tích nghiệp vụ chi tiết → `/da-biz-ba`
- Cần phân tích số liệu để hỗ trợ quyết định → `/da-data` chạy trước, kết quả feed vào discovery

## Mandatory ending signals

- `ARTIFACT_PATH`: discovery brief
- `VERDICT`: Proceed | Park | Kill
- `HANDOFF_TO`: skill kế tiếp (nếu Proceed) hoặc điều kiện quay lại (nếu Park)
