# Rubric — DA Assessment (Internal)

Thang chấm chi tiết cho bài `test/assessment.md`. **Dùng nội bộ — không share candidate.**

> **Triết lý**: Bài này KHÔNG có "đáp án đúng" duy nhất vì dataset README cố tình KHÔNG đưa danh sách KPI. Candidate phải tự discover. Chấm focus vào **cách nghĩ**, không phải checklist số liệu.

---

## Tổng quan trọng số

| Trục | Trọng số | Phần bài liên quan |
|---|---|---|
| 1. Curiosity & Framing | 30% | Tất cả (đặc biệt P1, P3) |
| 2. Execution | 25% | P1, P2, P3 |
| 3. Insight quality | 25% | P3, P4 |
| 4. Communication | 20% | Báo cáo + `notes.md` + chart |
| **Tổng** | **100%** | |

Mỗi trục chấm theo 4 mức: **Excellent (90-100) / Good (75-89) / Pass (60-74) / Fail (<60)**.

---

## Trục 1 — Curiosity & Framing (30%)

> "Candidate có đặt được câu hỏi đúng trước khi tính không?"

| Mức | Tiêu chí |
|---|---|
| **Excellent (90-100)** | Profile (P1) phát hiện ≥4 DQ issues + ≥3 pattern không hiển nhiên. Đề xuất 2-3 câu hỏi business sâu sắc, không chỉ liệt kê KPI cliché. Trong P3, tự reframe câu hỏi của SC Manager thành câu cụ thể hơn trước khi trả lời. Phân biệt **fact vs hypothesis** consistent xuyên suốt. KPI chọn trong P2 có lý do business rõ ràng, không phải "vì OTIF là KPI tiêu chuẩn". |
| **Good (75-89)** | Phát hiện 2-3 DQ + 2 pattern. Đề xuất 2 câu hỏi business OK. Phân biệt fact/hypothesis nhưng không đều. KPI chọn defensible. |
| **Pass (60-74)** | Phát hiện 1-2 DQ. Câu hỏi business generic. Đôi chỗ lẫn fact và hypothesis. |
| **Fail (<60)** | Bỏ qua bước profile, nhảy thẳng vào tính KPI. Hoặc chọn KPI mà không giải thích tại sao. Đưa kết luận khi data không support. Trả lời sai câu hỏi P3. |

**Red flags auto-fail trục này**:
- Bỏ qua P1 hoặc P1 chỉ vài dòng generic ("data có N rows, K columns").
- Bịa data point không có trong file (vd nói "kẹt xe Tết" cho Apr trong khi Tết = Feb).
- Đưa hypothesis như fact (vd "carrier X tệ vì họ là carrier mới" — không có cách biết từ data).

---

## Trục 2 — Execution (25%)

> "Cách candidate viết query / pandas / Excel — đúng, hiệu quả, repro được?"

| Mức | Tiêu chí |
|---|---|
| **Excellent (90-100)** | Code/query clean, có comment. Định nghĩa metric **chính xác** và **defensible** (vd "Late = ATA > ETA + 30min, NULL → exclude" — có lý do). Join đúng các bảng dim. Xử lý NULL / empty có ý đồ tường minh. Có ≥1 window function HOẶC pivot cross-tab. Số chấm verify được khi reviewer re-run. |
| **Good (75-89)** | Code chạy được, metric tính đúng theo định nghĩa candidate đưa ra. Join đúng nhưng có 1-2 chỗ inefficient. NULL handling OK. |
| **Pass (60-74)** | Metric tính được nhưng định nghĩa không rõ ràng / không document. Code dài dòng, khó re-run. |
| **Fail (<60)** | Số sai vì lỗi join / lỗi filter. Code không reproduce được. Định nghĩa metric không match với cách compute. Đưa "tính tay" thay vì query. |

**Cách verify (reviewer)**:
1. Re-run code candidate cung cấp với cùng dataset.
2. Đối chiếu metric candidate tính vs `_internal/expected_status.csv` (reviewer-only file có pre-computed OTIF/Ontime/Infull để benchmark) NẾU candidate chọn các KPI này.
3. Kiểm tra NULL handling — đặc biệt `delivery_area` (25% empty), `carrier_code` (0.6% empty).

**Red flags trục này**:
- Tính % mà mẫu số chứa NULL → bias.
- Không filter duplicate khi `COUNT(DISTINCT shipment_id)` cần thiết.
- Define metric theo 1 cách rồi compute theo cách khác.

---

## Trục 3 — Insight quality (25%)

> "Candidate có 'óc đặt câu hỏi' không, hay chỉ trả số?"

| Mức | Tiêu chí |
|---|---|
| **Excellent (90-100)** | Phát hiện ≥3 pattern không hiển nhiên. Hypothesis hợp lý có gốc data. Trong P3 root-cause được decompose (vd "tháng X tệ do dimension Y trong cụm Z"). Đề xuất hành động P3 có **WHO + WHAT + đo bằng gì + timeline**. Recommendation widget P4 trả lời 1 câu hỏi cụ thể, không chung chung. |
| **Good (75-89)** | Phát hiện 2 pattern. Hypothesis hợp lý. Recommendation có WHO + WHAT nhưng thiếu cách đo. |
| **Pass (60-74)** | Có 1 pattern. Recommendation chung chung kiểu "cần cải thiện performance". |
| **Fail (<60)** | Chỉ liệt kê số. Không quan sát, không hypothesis. Recommendation generic. |

**Pattern dataset thực sự có** (xem [`reference-findings.md`](reference-findings.md) cho số liệu chi tiết):
- OTIF / On-time / Infull % theo tháng có pattern (Apr tệ hơn Feb-Mar nếu candidate chọn compute KPI này).
- 25.3% shipments empty `delivery_area` — DQ issue lớn.
- 1 carrier có volume 2k+ nhưng performance kém hơn rõ.
- 199 shipments empty `carrier_code` (phantom orders).
- VFR theo vehicle type — xe to (11T) tận dụng kém hơn xe nhỏ (1.4T-2T).
- Over-delivery: 1.6% shipments có `delivered > planned`.
- Lead time spread giữa các kho khác nhau.
- Sales channel distribution skewed (MT/GT dominant).

Candidate có thể bắt được 1 hoặc nhiều pattern khác — không bắt buộc phải hit hết. Đánh giá theo **chất lượng quan sát** không phải **số lượng**.

---

## Trục 4 — Communication (20%)

> "Stakeholder business (KHÔNG biết code) đọc có hiểu không?"

| Mức | Tiêu chí |
|---|---|
| **Excellent (90-100)** | Báo cáo có cấu trúc rõ (heading, bullet, không wall-of-text). Chart có title + axis label + đơn vị. Số có context (vd "82% vs target 90%" tốt hơn "82%"). `notes.md` honest và có suy ngẫm. Tiếng Việt/Anh natural. |
| **Good (75-89)** | Báo cáo đủ structure. Chart có title nhưng thiếu axis label hoặc đơn vị. `notes.md` viết nhưng sơ sài. |
| **Pass (60-74)** | Báo cáo đọc được nhưng phải đọc 2 lần. Chart không có title hoặc axis. `notes.md` 1-2 câu. |
| **Fail (<60)** | Wall-of-text không heading. Chart không có label. Không có `notes.md`. |

**Red flags trục này**:
- Chart dùng default Excel/matplotlib không edit (title rỗng, axis "value", legend "series1").
- Paste SQL trực tiếp vào body báo cáo cho SC Manager — sai audience.
- Số đưa ra không có đơn vị / không có baseline so sánh.

---

## Auto-fail (bất kể tổng điểm)

| # | Hành vi | Lý do |
|---|---|---|
| 1 | Đưa hypothesis như fact | DA junior phải biết phân biệt |
| 2 | Bỏ qua data quality issue hiển nhiên (vd 25% empty delivery_area) | Miss skill core |
| 3 | Recommendation chung chung không actionable | DA phải tạo value, không chỉ describe |
| 4 | Không trả lời được câu hỏi mở của P3 — viết được mỗi "không biết phải xem gì" | Trục 1 fail nặng |
| 5 | Code không repro được (sai folder, sai filename, syntax error) | Không production-ready |
| 6 | Bịa data point không có trong file | Trustworthiness fail — biggest red flag |
| 7 | AI-wash (không giải thích được code của chính họ trong buổi discuss) | Phát hiện ở live discussion |

---

## Cách chấm cuối cùng

1. Đọc lướt báo cáo + `notes.md` (5 phút).
2. Re-run code candidate trên dataset (10 phút) — verify Phần 1, Phần 2.
3. Đối chiếu finding P3 với `reference-findings.md` (10 phút) — KHÔNG yêu cầu match, chỉ check chất lượng quan sát.
4. Cho điểm 4 trục → tổng điểm.
5. Quyết định pass/fail:

| Tổng | Decision |
|---|---|
| ≥ 85 | **Strong yes** — fast track tới final round |
| 70-84 | **Yes** — proceed to live discussion (30 phút) |
| 55-69 | **Borderline** — depend on live discussion |
| < 55 | **No** — gửi reject + feedback ngắn |

Bất kì auto-fail nào → **No** bất kể điểm trục.

---

## Câu hỏi đề xuất cho buổi live discussion

Sau khi đọc bài, chuẩn bị 3-5 câu hỏi đào sâu. Pattern:
1. **Defend metric**: "Bạn chọn metric X — nếu mình challenge bạn chọn metric Y thay thế, bạn sẽ defend thế nào?"
2. **Defend assumption**: "Bạn assume Z khi compute metric. Nếu assume sai, kết luận có đổi không?"
3. **Code understanding**: "Đoạn SQL/pandas này — vì sao bạn viết kiểu này thay vì cách khác?"
4. **Edge case probe**: "Nếu data có 1 row outlier kiểu X, bạn sẽ xử lý thế nào?"
5. **Business sense**: "SC Manager push back đề xuất của bạn vì lý do Y — bạn sẽ thuyết phục thế nào?"

---

## Template feedback ngắn cho candidate (reject)

> Cảm ơn bạn đã dành thời gian. Bài bạn thể hiện [điểm tốt cụ thể]. Tuy nhiên bọn mình nhận thấy [điểm thiếu cụ thể, 1-2 câu]. Bọn mình sẽ lưu CV cho các vị trí phù hợp hơn trong tương lai. Chúc bạn may mắn.

---

**Last updated**: 2026-05-16
**Owner**: PM/BA/DA team
