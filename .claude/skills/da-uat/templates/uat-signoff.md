# Biên bản nghiệm thu UAT — {section} — {tenant}

> Template Mode E. File path: `projects/{tenant}/{section}/uat/{section}-uat-signoff-{YYYY-MM-DD}.md`.
> **Audience: Supply Chain Manager / Trưởng phòng vận hành phía khách.** Ngôn ngữ tiếng Việt nghiệp vụ — KHÔNG dùng thuật ngữ kỹ thuật.

---

## 0. Thông tin chung

| Hạng mục | Nội dung |
|---|---|
| Tên hệ thống | Smartlog Control Tower — `<phiên bản>` |
| Phân hệ / Chức năng nghiệm thu | `<vd: Dashboard OTIF — theo dõi giao hàng đúng giờ & đầy đủ>` |
| Doanh nghiệp | `<tên đầy đủ tenant>` |
| Thời gian UAT | `<YYYY-MM-DD>` → `<YYYY-MM-DD>` |
| Số phiên kiểm thử | `<N>` phiên |
| Người đại diện khách | `<Họ tên — Chức vụ>` |
| Người đại diện Smartlog | `<Họ tên — Chức vụ>` |

## 1. Phạm vi nghiệm thu

### 1.1. Các chức năng đã kiểm thử

| # | Tên chức năng | Mô tả ngắn |
|---|---|---|
| 1 | `<Hero — tỷ lệ OTIF hôm nay>` | Hiển thị tỷ lệ giao hàng đúng giờ & đầy đủ trong ngày, kèm đèn cảnh báo theo mục tiêu |
| 2 | `<Phễu trạng thái>` | Phân tách đơn theo 5 trạng thái: đã giao, đang giao, hoãn, huỷ, chưa lên kế hoạch |
| 3 | `<Xu hướng 14 ngày>` | Đồ thị diễn biến OTIF qua 14 ngày gần nhất, so với mục tiêu |
| 4 | `<Phân tích theo chiều>` | Bóc OTIF theo kho, khu vực, khách hàng, kênh phân phối |
| 5 | `<Bảng chi tiết đơn>` | Top đơn giao trễ / thiếu, có thể bấm vào để xem chi tiết |

### 1.2. Các bộ lọc đã kiểm thử

- Theo nhà phân phối (NPP)
- Theo kho xuất / kho nhận
- Theo khu vực địa lý
- Theo kênh phân phối
- Theo khoảng thời gian

### 1.3. Số liệu đã đối chiếu

Tổng cộng `<N>` chỉ tiêu đã được đối chiếu giữa hệ thống Smartlog Control Tower và dữ liệu chuẩn do `<tên doanh nghiệp>` cung cấp.

## 2. Kết quả kiểm thử tổng quan

| Tiêu chí | Yêu cầu | Kết quả thực tế | Đạt? |
|---|---|---|---|
| Tỷ lệ kịch bản chính đạt | ≥ 95% | `<X%>` | ✓ / ✗ |
| Tỷ lệ kịch bản phụ đạt | ≥ 80% | `<X%>` | ✓ / ✗ |
| Vấn đề nghiêm trọng tồn đọng | 0 | `<N>` | ✓ / ✗ |
| Vấn đề mức nghiêm trọng trung bình tồn đọng | ≤ 2 + có kế hoạch khắc phục | `<N>` | ✓ / ✗ |
| Đối chiếu số liệu | 100% trong dung sai cho phép | `<X/Y>` chỉ tiêu | ✓ / ✗ |
| Thời gian phản hồi khi lọc | < 3 giây | `<X giây>` | ✓ / ✗ |
| Thời gian tải trang | < 5 giây | `<X giây>` | ✓ / ✗ |

## 3. Số liệu nghiệm thu chính

(Bảng tóm tắt 5-10 chỉ tiêu chính — số trên Smartlog vs số khách hàng, đã được khách xác nhận trong dung sai cho phép)

| Chỉ tiêu | Bộ lọc | Số trên Smartlog | Số chuẩn của `<DN>` | Chênh lệch | Dung sai cho phép | Kết luận |
|---|---|---|---|---|---|---|
| Tổng đơn vận chuyển | Toàn bộ NPP, ngày `<DD/MM/YYYY>` | `<số>` | `<số>` | `<số>` (`<%>`) | ≤ 1% | Trong dung sai |
| Tỷ lệ OTIF | Toàn bộ NPP, ngày `<DD/MM/YYYY>` | `<%>` | `<%>` | `<pp>` | ≤ 0.5 điểm % | Trong dung sai |
| Tỷ lệ giao đúng giờ | | `<%>` | `<%>` | | ≤ 0.5 điểm % | |
| Tỷ lệ giao đầy đủ | | `<%>` | `<%>` | | ≤ 0.5 điểm % | |
| Top 5 kho giao trễ | Tuần `<W/YYYY>` | `<A,B,C,D,E>` | `<A,B,D,C,F>` | 4/5 tên trùng | ≥ 4/5 | Trong dung sai |

## 4. Vấn đề tồn đọng (nếu có)

> Các vấn đề ghi nhận nhưng đã có kế hoạch khắc phục cụ thể, hai bên thống nhất không cản trở việc đưa vào sử dụng chính thức.

| # | Mô tả vấn đề | Mức độ | Giải pháp | Thời hạn cam kết |
|---|---|---|---|---|
| 1 | `<vd: Bộ lọc theo kênh phân phối khi chọn nhiều mục đôi khi mất chú thích — không ảnh hưởng số liệu>` | Trung bình | Hotfix trong bản kế tiếp | `<DD/MM/YYYY>` |
| 2 | | | | |

## 5. Kết luận nghiệm thu

Sau quá trình kiểm thử với sự tham gia của đại diện hai bên, các chức năng trong phạm vi nghiệm thu được đánh giá:

☐ **Chấp thuận nghiệm thu, đưa vào sử dụng chính thức**
☐ **Chấp thuận nghiệm thu có điều kiện** (theo các cam kết tại Mục 4)
☐ **Chưa chấp thuận nghiệm thu** (lý do nêu tại Mục 4)

## 6. Cam kết hai bên

### Phía Smartlog
- Hỗ trợ kỹ thuật khi vận hành chính thức trong vòng `<N>` tháng đầu
- Khắc phục các vấn đề tồn đọng theo thời hạn tại Mục 4
- Đào tạo người dùng cuối theo lịch đã thống nhất

### Phía `<tên doanh nghiệp>`
- Cung cấp phản hồi vận hành trong vòng `<N>` ngày sau khi đưa vào sử dụng
- Báo cáo các vấn đề phát sinh qua kênh hỗ trợ: `<email/số điện thoại CS>`

## 7. Chữ ký

| Vai trò | Họ tên | Chức vụ | Ký tên | Ngày ký |
|---|---|---|---|---|
| Đại diện doanh nghiệp | | Trưởng phòng Vận hành / Chuỗi cung ứng | | |
| Đại diện doanh nghiệp | | Đại diện CNTT | | |
| Đại diện Smartlog | | Project Manager | | |
| Đại diện Smartlog | | Business Analyst | | |

---

## Phụ lục (đính kèm riêng, không phát hành chung)

- A. Báo cáo kiểm thử chi tiết — file nội bộ `{section}-uat-execution-*.md`
- B. Bảng đối chiếu chi tiết 3 nguồn — file nội bộ `{section}-uat-dryrun-*.md`
- C. Danh sách vấn đề và quá trình khắc phục — file nội bộ `defects/UAT-*.md`
- D. Phụ lục kỹ thuật về nguồn dữ liệu (nếu khách yêu cầu) — chuẩn bị riêng

> Lưu ý cho người viết: Bóc thuật ngữ kỹ thuật trước khi giao biên bản:
> - "ClickHouse / MV / materialized view" → "kho dữ liệu phân tích"
> - "QueryConfig / FormConfig / ViewConfig" → "cấu hình màn hình"
> - "logging.activity / LogDbContext / AppDbContext" → "nhật ký hệ thống"
> - "mv_psv_main / mv_filter_*" → "nguồn dữ liệu"
> - "Sev1-4 / tech_layer" → "mức độ nghiêm trọng cao/trung bình/thấp"
> - "Filter / drill-down / hero card" → "bộ lọc / xem chi tiết / thẻ tổng quan"
