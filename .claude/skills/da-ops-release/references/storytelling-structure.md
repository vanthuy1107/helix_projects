# Storytelling Structure — Khung 5 phần cho Release PDF

> Source `/da-ops` viết theo template pulse/adoption/anomaly (analytical, có Appendix SQL). Release PDF kể chuyện (narrative). Cùng 1 data, hai cách dẫn dắt.
> Khung 5 phần dưới đây là minimum viable narrative — không phải maximum.

---

## Khung 5 phần (giữ thứ tự)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. BỐI CẢNH        — Set the scene (3-4 dòng văn xuôi)     │
│    Mục đích: Người đọc hiểu "tại sao báo cáo này tồn tại"  │
├─────────────────────────────────────────────────────────────┤
│ 2. ĐIỂM NHẤN       — 3-5 bullet số to (callout box pale)   │
│    Mục đích: Nếu chỉ đọc 30 giây, đọc đoạn này             │
├─────────────────────────────────────────────────────────────┤
│ 3. CÂU CHUYỆN      — 3-5 chương; mỗi chương = 1 chủ đề     │
│    Mỗi chương: heading so-what + 1 đoạn + chart/bảng       │
│    Mục đích: Hiểu sâu, có evidence, có nhân vật            │
├─────────────────────────────────────────────────────────────┤
│ 4. ĐỀ XUẤT HÀNH ĐỘNG — Bảng/bullet (Việc | Ai | Khi)       │
│    Mục đích: Người đọc đóng PDF biết phải làm gì tiếp      │
├─────────────────────────────────────────────────────────────┤
│ 5. LỜI KẾT         — 1 đoạn (3-5 dòng)                     │
│    Mục đích: 1 thông điệp duy nhất stakeholder nhớ lại     │
└─────────────────────────────────────────────────────────────┘
Footer (1 dòng nhỏ): "Số liệu chốt từ hệ thống Smartlog Control Tower lúc X · soạn ngày Y"
```

---

## 1. Bối cảnh — Set the scene

**Mục đích:** Người đọc bước vào báo cáo không bị shock số. Hiểu phạm vi, hiểu thời điểm, hiểu vai trò của hệ thống/feature được báo cáo.

**Source map:**
- Daily pulse: `Window` + `Tenant DB` (ẩn alias technical) → mở rộng thành 1 đoạn
- Adoption: `Released` + `Today (D+N)` + `Tenants in scope` → mở rộng
- Anomaly: `Detected when` + `Tenant scope` + `Severity.Impact` → mở rộng

**Tiêu chí:**
- Không số lớn (số to để dành cho phần 2)
- Không jargon (không "activity log", "QueryConfig", "DbContext", "BFF")
- Trả lời ngầm 3 câu: *"Hệ thống/feature nào? Trong kỳ nào? Đối tượng quan tâm là gì?"*

**Ví dụ (daily pulse cho SC Manager Mondelez):**
```
❌ Source pulse Window + headline (analytical, terse):
"Window: 2026-05-08 00:00 → 14:30 UTC+7. Tenant DB: mondelez_prod.
1-line headline: Volume Tender create giảm 38% so với baseline 4 tuần."

✅ Release Bối cảnh (narrative, scene-setting cho SC Manager):
"Trong ngày làm việc 08/05/2026, hệ thống điều phối SC của Mondelez ghi nhận một
phiên giao dịch tương đối lặng so với mặt bằng 4 tuần gần đây. Báo cáo dưới đây
tổng hợp nhịp tạo Tender, hoạt động của các Operator chính, và một số điểm cần
đội Vận hành Mondelez kiểm tra trước khi vào ca chiều."
```

**Ví dụ (adoption cho Engineering Smartlog):**
```
❌ Source: "Released: 2026-04-30. Today: D+5. Tenants: Mondelez, Acme."

✅ Release Bối cảnh:
"Sau 5 ngày kể từ khi widget Flash Daily được phát hành tới Mondelez và Acme,
báo cáo này tổng hợp mức tiếp cận, độ sâu sử dụng, và các tín hiệu khó khăn
quan sát được trên hai tenant. Đối tượng đọc: Engineering và Product team
Smartlog để quyết định iterate trong sprint tới."
```

---

## 2. Điểm nhấn — Bullet số to

**Mục đích:** Người đọc 30 giây đầu rút được kết luận. Đây là phần stakeholder copy-paste sang slide nội bộ.

**Source map:**
- Daily pulse: `1-line headline` + top rows của `Key numbers` (Volume + Δ baseline)
- Adoption: top-line `Reach` + `Depth` (% adoption, distinct users, total uses)
- Anomaly: `What's odd` (số bất thường) + `Severity.Impact`

**Format:** 3-5 bullet, mỗi bullet:
```
<Số to in đậm> — <vế ngữ cảnh + tác động/ý nghĩa>
```

**Tiêu chí:**
- Mỗi bullet đứng độc lập (đọc riêng vẫn hiểu)
- Số được làm tròn theo audience: BOD = integer hoặc 1 thập phân; SC Manager = 2 thập phân OK; Engineering = giữ chi tiết
- Có ít nhất 1 bullet là risk/cảnh báo nếu source có exception (exception-first)
- Không quá 5 bullet — nếu hơn, gộp hoặc đẩy xuống phần Câu chuyện

**Render trong PDF:** callout box `#EFF4FB` background, `#1E3A5F` text, padding 16px, border-left `4px solid #2563EB`.

**Ví dụ (daily pulse SC Manager Mondelez):**
```
✅ ĐIỂM NHẤN
• Volume tạo Tender 145 — giảm 38% so với mức trung bình 4 tuần (235), đáng theo dõi
• 2/8 Operator đã login trong sáng nay — thấp hơn nhịp thường (6/8 trước 10:00)
• 0 sự cố lỗi ghi nhận — hệ thống ổn định, không có ma sát kỹ thuật
• Khoảng 11:00–13:00 không có thao tác Tạo Tender mới — trùng giờ nghỉ, không bất thường
• Cần xác minh — kế hoạch điều phối ca chiều với đội điều vận trước 14:00
```

---

## 3. Câu chuyện — 3-5 chương

**Mục đích:** Cung cấp evidence cho điểm nhấn. Mỗi chương = 1 chủ đề (1 module / 1 user pattern / 1 vấn đề), có nhân vật (user/module/widget đặt tên thật), có xung đột (số lệch khỏi mong đợi), có hồi đáp (giải thích nguyên nhân hoặc khuyến nghị).

**Source map:**
- Daily pulse `Insights` mỗi insight → 1 chương (đã có cấu trúc Quan sát+So sánh+Giả thuyết+Đề xuất — gộp 4 thành 1 đoạn narrative)
- Daily pulse `User activity` + `Time pattern` → có thể gộp thành 1 chương "Nhịp vận hành trong ngày"
- Adoption `Reach` / `Depth` / `Friction signals` mỗi cái → 1 chương
- Anomaly `Hypotheses` → mỗi hypothesis 1 đoạn ngắn trong chung 1 chương "Các giả thuyết đang xem xét"

**Cấu trúc 1 chương:**
```
## <Heading nói so-what — copy hoặc trang trọng hoá insight title của source>

<1 đoạn dẫn (2-4 dòng) — what + so what; gộp Quan sát + So sánh + Giả thuyết>

<Chart hoặc bảng — render từ data trong source nếu có ≥3 dòng numeric>

<1-2 dòng chú thích/insight, nếu cần — giải thích pattern hoặc callout exception>
```

**Tiêu chí:**
- Heading PHẢI là câu so-what, không label. Ví dụ:
  - ❌ "Phân tích Volume Tender"
  - ✅ "Volume tạo Tender hôm nay giảm 38% — phần lớn Operator chưa login"
- Đoạn dẫn không lặp lại 100% nội dung chart — phải thêm context/diễn giải
- Chart: render bằng CSS bar div lấy từ bảng numeric của source (≥3 dòng); KHÔNG copy ASCII; KHÔNG dùng PNG/matplotlib
- Bảng: header `#EFF4FB` text `#1E3A5F`, alternating row white/`#F7FAFD`
- Mỗi chương vừa 1 page (BOD audience). Nếu dài hơn → tách chương

**Số chương theo audience:**
| Audience | Số chương | Depth |
|---|---|---|
| BOD/C-Level (tenant) | 2-3 | Tóm tắt cao, mỗi chương 1 chart + 1 bảng tối đa |
| **SC Manager (tenant)** (default) | 3-5 | Chi tiết operational, có exception list, breakdown lane/SKU/user |
| Rollout/CS Smartlog | 3-5 | Trung bình; có chương "Danh sách user cần CS gọi" |
| Engineering / Tech lead | 4-5 | Detail; có chương "Friction signals" với metric error rate, abandon rate, time-to-complete |

---

## 4. Đề xuất hành động

**Mục đích:** Người đọc đóng PDF biết phải làm gì tiếp. Đây là "so-what" cuối cùng cho stakeholder.

**Source map:**
- Daily pulse: `Insights.Đề xuất` của mỗi insight → mỗi action 1 row
- Adoption: `Verdict` checklist (Healthy / Slow start / Friction / Rejection) → chuyển thành actions cụ thể
- Anomaly: `Verification needed` → mỗi item 1 row
- Open questions cho rollout team (nếu audience tenant) → BỎ; (nếu audience nội bộ) → gộp vào bảng action với owner = CS team

**Format:** Bảng 3 cột:

| Việc cần làm | Người chịu trách nhiệm | Khi nào |
|---|---|---|
| Gọi `ops_lead@mondelez.com` xác nhận kế hoạch điều phối ca chiều | CS Smartlog (audience nội bộ) hoặc SC Lead Mondelez (audience tenant) | Trước 14:00 hôm nay |
| Rà soát danh sách Operator login trong tuần để phát hiện shift change | Trưởng ca Mondelez | Trong 2 ngày |
| Kiểm tra widget Flash Daily có hiển thị đúng cho Operator chưa | Engineering Smartlog | Sprint tới |

**Tiêu chí:**
- Tối đa 5 dòng (BOD), 7-8 dòng (SC Manager), 10 dòng (Rollout/Engineering chi tiết). Hơn → cần priority hóa
- Mỗi action phải có owner cụ thể (vai trò, không phải tên cá nhân — trừ khi audience là internal team và analyst đã chỉ tên)
- Mỗi action phải có deadline rõ (trong giờ / hôm nay / N ngày / sprint tới) — không "khi nào có thời gian"
- Không action loại "tiếp tục theo dõi" — đó không phải action, đó là không-quyết-định
- Owner audience-aware: tenant audience → vai trò phía tenant; internal audience → vai trò Smartlog (CS, Rollout, Engineering)

---

## 5. Lời kết

**Mục đích:** Stakeholder đóng PDF, mang về 1 thông điệp duy nhất. Lặp lại điểm cốt lõi nhưng dưới dạng narrative, không bullet.

**Source map:**
- Daily pulse: `1-line headline` + tổng quát từ `Insights`
- Adoption: `Verdict` (winner)
- Anomaly: `Severity.Urgency` + recap

**Tiêu chí:**
- 3-5 dòng văn xuôi
- Tone: trang trọng nhưng không khô. Có thể có 1 câu khẳng định hoặc đặt câu hỏi mở (kích thích quyết định)
- Không có số mới — chỉ recap số to nhất từ phần 2
- Không có jargon
- Câu cuối → liên kết với hành động nhưng không lặp bullet

**Ví dụ (daily pulse cho SC Manager Mondelez):**
```
✅ LỜI KẾT
"Phiên sáng nay nhịp giao dịch chậm hơn mặt bằng tuần — phần lớn vì Operator chưa
vào ca đầy đủ. Bản thân hệ thống không ghi nhận sự cố nào, và nhịp này nhiều khả
năng phục hồi trong ca chiều nếu kế hoạch điều phối được xác nhận trước 14:00.
Báo cáo ngày mai sẽ tiếp tục theo dõi tỷ lệ Operator đúng giờ và volume Tender
trong khung 06:00–10:00 — đây là chỉ báo sớm cho tuần sau."
```

---

## Tone Matrix theo audience

| Yếu tố | BOD/C-Level (tenant) | **SC Manager (tenant)** (default) | Rollout/CS Smartlog (nội bộ) | Engineering / Tech lead (nội bộ) |
|---|---|---|---|---|
| **Câu mở** | "Báo cáo vận hành định kỳ tổng kết..." | "Trong ngày 08/05, các phân hệ vận hành chính..." | "Tuần này nhịp dùng của Mondelez có 2 điểm cần CS theo dõi..." | "Sau release feature X 5 ngày, adoption + friction observed..." |
| **Đại từ** | Khách quan, không "chúng tôi" | "Đội ngũ / chúng ta / đội Vận hành" | "Team CS / chúng ta" | "Team Engineering / chúng ta" |
| **Câu hỏi mở** | Hạn chế — BOD muốn câu trả lời | OK — kích thích thảo luận trong team SC | OK — định hướng action cho CS | OK — định hướng iterate sprint sau |
| **Số nhỏ** | Bỏ hoặc gom — chỉ giữ số to | Giữ chi tiết operational | Giữ chi tiết, đặc biệt user-level (email, role) | Giữ tất cả metric numeric (error rate, abandon, time) |
| **Risk language** | "rủi ro tài chính / vận hành" | "rủi ro vận hành" — direct | "rủi ro adoption / training gap" | "regression / friction signal / error spike" |
| **Câu kết** | Khẳng định + impact | Call to action team SC | Call to action CS / training | Call to iterate / fix / measure tiếp |
| **Độ dài tổng** | 2-3 trang PDF | 3-4 trang | 3-4 trang | 4-5 trang |

---

## Quy tắc viết câu (chung mọi audience)

1. **Câu ngắn.** Tối đa 25 từ/câu trong narrative; bullet thì 15-20 từ.
2. **Chủ động.** "Đội Vận hành Mondelez cần kiểm tra..." > "Việc kiểm tra cần được thực hiện..."
3. **Cụ thể trước, trừu tượng sau.** "Volume Tender 145 đơn" trước khi nói "Nhịp giảm so với baseline".
4. **Không hashtag, không emoji** ngoài badge trạng thái 🟢🟡🔴 (và chỉ trong bảng KPI status).
5. **Không từ tiếng Anh nếu có từ tiếng Việt tương đương** — exception: tên module/widget đã đặt sẵn (Tender, VFR, Flash Daily, Transaction Move, Quick Order, Demand Planning), từ chuyên ngành đã thông dụng (KPI, SKU, BU).
6. **Số liệu có đơn vị.** "145 đơn Tender" không phải "145"; "38%" không phải "38".
7. **Phép so sánh phải có vế đúng.** "Volume hôm nay 145 — giảm 38% so với trung bình 4 tuần (235)" — luôn nói đối chiếu với cái gì.
8. **Time luôn UTC+7.** "Lúc 10:20" không phải "lúc 03:20 UTC". Luôn convert trước khi viết.

---

## Anti-patterns trong storytelling

| ❌ | ✅ |
|---|---|
| Dán nguyên template pulse `/da-ops` (Window/Pulled at/Author) vào | Tách thành 5 phần — Window/Pulled at/Author đẩy xuống footer 1 dòng nhỏ |
| Heading chương = label ("Phân tích Volume Tender") | Heading = action title ("Volume Tender hôm nay giảm 38% — Operator chưa login đầy đủ") |
| Bullet điểm nhấn dài 3 dòng | 1 dòng / bullet — gộp vế phụ vào phần Câu chuyện |
| Đề xuất hành động không có owner / deadline | Mọi action có cả 2 — không thì bỏ |
| Lời kết = lặp Headline nguyên văn | Lời kết = narrative version, recap implicit |
| Dùng "chúng tôi khuyến nghị quý vị nên..." (formal cliché) | "Khuyến nghị: ..." hoặc câu chủ động |
| Giữ ref `Q1` / `Q2` / `(ref: Q?)` từ source | BỎ tất cả Q reference — release không có Appendix |
| Giữ "Insight 1 / Insight 2 / Insight 3" numbering | Đặt heading so-what cho mỗi insight, không numbering |
| Giữ "Quan sát / So sánh / Giả thuyết / Đề xuất" 4-label trong PDF | Gộp 4 thành 1 đoạn narrative; "Đề xuất" tách ra section 4 (Đề xuất hành động) |
| Jargon mới mẻ ("luồng tiêu chuẩn này thể hiện sự đa dạng kênh...") | Đời thường ("Operator đang dùng module này theo nhiều cách khác nhau, một số chưa quen với UI mới") |
| Bullet chỉ có "what" không có "so what" ("145 đơn") | Mỗi bullet kèm hệ quả ("145 đơn — giảm 38% so với baseline 4 tuần, đáng theo dõi nhịp ca chiều") |
| Ghi giờ UTC nguyên trong PDF "khách câm lúc 03:00" | Convert UTC+7: "khách câm lúc 10:00" — kèm "(UTC+7)" lần đầu mention |
| Lộ email user của tenant khác trong báo cáo cho 1 tenant | Sanitize cross-tenant trước khi viết câu chuyện chương |
