# PRD — Dashboard Tỷ Lệ Sử Dụng Xe

## Tỷ Lệ Sử Dụng Xe — VFR

### Vehicle Fill Rate / Tỷ lệ sử dụng xe theo trọng tải & thể tích

**Status:** Done
**Owner:** Thanh
**Last updated:** 06/05/2026 04:00 PM

---

## 1. Overview

Dashboard **Tỷ Lệ Sử Dụng Xe — Vehicle Fill Rate (VFR)** được xây dựng nhằm giám sát và đo lường hiệu quả sử dụng xe của các chuyến gửi thầu và chuyến vận hành trong hệ thống **TMS — Smartlog**.

Dashboard tập trung vào việc đánh giá mức độ tận dụng xe dựa trên hai tiêu chí chính:

1. Mức độ sử dụng theo **trọng tải — Tấn**.
2. Mức độ sử dụng theo **thể tích — Khối/CBM**.

VFR được tính bằng cách so sánh lượng hàng được chở với khả năng chở tối đa của loại xe, sau đó lấy giá trị cao hơn giữa VFR theo tấn và VFR theo khối để phản ánh yếu tố giới hạn chính của chuyến.

Dashboard cần tính và hiển thị VFR riêng cho hai nhóm:

* **Chuyến gửi thầu — GT**, group theo `TenderMasterID`.
* **Chuyến vận hành — VH**, group theo `MasterCode`.

Dashboard giúp đội Logistics, Carrier Management, Team Lập kế hoạch vận tải và lãnh đạo chuỗi cung ứng theo dõi tình trạng xe chạy non tải, đánh giá hiệu quả sử dụng xe theo khu vực, loại xe, loại bốc xếp và thời gian, từ đó tối ưu kế hoạch vận chuyển và giảm lãng phí tài nguyên vận tải.

---

## 2. Problem Statement

Hiện tại, việc theo dõi tỷ lệ sử dụng xe chưa đủ trực quan và chi tiết để người dùng nhanh chóng đánh giá hiệu quả sử dụng xe trong cả giai đoạn gửi thầu và vận hành thực tế.

Trong thực tế vận hành, có thể phát sinh các tình huống như:

* Xe chạy non tải, tỷ lệ sử dụng thấp.
* VFR của chuyến gửi thầu khác với VFR của chuyến vận hành thực tế.
* Một số khu vực hoặc loại xe có tỷ lệ sử dụng thấp lặp lại nhiều lần.
* Một số loại bốc xếp ảnh hưởng đến khả năng tối ưu tải trọng/thể tích.
* Khó phân tích VFR theo nhà vận tải, khu vực, loại xe, loại bốc xếp và thời gian.
* Thiếu dữ liệu chi tiết để đánh giá chất lượng lập kế hoạch và làm việc với nhà vận tải.

Các vấn đề chính bao gồm:

* Chưa có dashboard đo lường tự động VFR theo cả trọng tải và thể tích.
* Khó xác định nhóm chuyến có VFR thấp, đặc biệt là các nhóm `<50%` và `50%–70%`.
* Chưa phân biệt rõ VFR theo **chuyến gửi thầu** và VFR theo **chuyến vận hành**.
* Thiếu công cụ trực quan để so sánh VFR theo khu vực, loại xe và loại bốc xếp.
* Khó sử dụng dữ liệu VFR làm cơ sở cải thiện kế hoạch ghép hàng, điều phối xe và đánh giá hiệu suất nhà vận tải.

Do đó, cần có dashboard giúp giám sát tỷ lệ sử dụng xe, phát hiện tình trạng xe chạy non tải và cung cấp dữ liệu chi tiết phục vụ tối ưu vận hành.

---

## 3. Target Users

### 3.1 Quản lý Logistics & Transport Operation

Nhóm này cần theo dõi hiệu quả sử dụng xe trong hoạt động vận tải tổng thể.

Nhu cầu chính:

* Theo dõi VFR tổng thể.
* Phát hiện tình trạng xe chạy non tải.
* So sánh VFR giữa chuyến gửi thầu và chuyến vận hành.
* Phân tích VFR theo khu vực, loại xe, loại bốc xếp và thời gian.
* Xác định các điểm cần cải thiện trong vận hành vận tải.

### 3.2 Quản lý Nhà vận tải — Carrier Management

Nhóm này sử dụng dashboard để đánh giá hiệu suất sử dụng xe của từng nhà vận tải.

Nhu cầu chính:

* So sánh VFR giữa các nhà vận tải.
* Xác định nhà vận tải có tỷ lệ sử dụng xe thấp.
* Làm cơ sở đánh giá Carrier Performance.
* Hỗ trợ đàm phán KPI, SLA hoặc điều chỉnh hợp đồng với nhà vận tải.

### 3.3 Team Lập kế hoạch vận tải

Nhóm này cần dữ liệu VFR để tối ưu kế hoạch gửi thầu, ghép hàng và lựa chọn loại xe.

Nhu cầu chính:

* Đánh giá mức độ tối ưu của kế hoạch vận tải.
* Xác định chuyến gửi thầu có khả năng chạy non tải.
* Điều chỉnh kế hoạch ghép hàng để tăng tỷ lệ sử dụng xe.
* Lựa chọn loại xe phù hợp theo khu vực, đơn hàng hoặc loại bốc xếp.
* So sánh VFR gửi thầu và VFR vận hành để phát hiện chênh lệch giữa kế hoạch và thực tế.

### 3.4 Lãnh đạo Chuỗi cung ứng

Nhóm này cần cái nhìn tổng quan về hiệu quả sử dụng tài nguyên vận tải.

Nhu cầu chính:

* Theo dõi KPI VFR tổng thể.
* Đánh giá xu hướng sử dụng xe theo thời gian.
* Nhận diện khu vực, nhà vận tải hoặc loại xe cần tối ưu.
* Hỗ trợ quyết định chiến lược về vận tải, hiệu quả vận hành và chi phí logistics.

---

## 4. Goals & Success Metrics

## 4.1 Goals

Dashboard cần đạt các mục tiêu sau:

1. Giúp người dùng theo dõi tỷ lệ sử dụng xe một cách trực quan và gần real-time.
2. Tính toán VFR dựa trên cả trọng tải và thể tích.
3. Phân biệt rõ VFR của chuyến gửi thầu và chuyến vận hành.
4. Phân nhóm VFR theo các ngưỡng: `<50%`, `50%–70%`, `70%–95%`, `≥95%`.
5. Hỗ trợ phân tích VFR theo khu vực, loại xe, loại bốc xếp, nhà vận tải và thời gian.
6. Cung cấp dữ liệu chi tiết ở cấp `TenderMasterID` và `MasterCode`.
7. Hỗ trợ quyết định tối ưu ghép hàng, điều chỉnh kế hoạch gửi thầu và đánh giá hiệu suất nhà vận tải.

## 4.2 Success Metrics

Dashboard được xem là thành công nếu đáp ứng các tiêu chí sau:

| Nhóm tiêu chí             | Chỉ số thành công                                                                             |
| ------------------------- | --------------------------------------------------------------------------------------------- |
| Khả năng theo dõi         | Người dùng có thể xem VFR tổng thể và phân bố VFR theo từng nhóm ngưỡng                       |
| Khả năng phân tích        | Người dùng có thể phân tích VFR theo khu vực, loại xe, loại bốc xếp, nhà vận tải và thời gian |
| Khả năng so sánh          | Người dùng có thể so sánh VFR giữa chuyến gửi thầu và chuyến vận hành                         |
| Khả năng phát hiện vấn đề | Người dùng có thể xác định nhóm chuyến có VFR thấp, đặc biệt là `<50%` và `50%–70%`           |
| Khả năng đối soát         | Dữ liệu chi tiết hiển thị đầy đủ thông tin chuyến, xe, nhà vận tải, tấn/khối và VFR           |
| Tính kịp thời             | Dữ liệu được cập nhật near real-time từ TMS                                                   |
| Phạm vi MVP               | Hoàn thành dashboard với 10 scorecard, 8 biểu đồ và 2 bảng dữ liệu chi tiết                   |

---

## 5. KPI Definitions

## 5.1 Tỷ lệ sử dụng xe — VFR

**VFR — Vehicle Fill Rate** là tỷ lệ sử dụng xe dựa trên mức độ tận dụng trọng tải và thể tích của xe so với khả năng chở tối đa.

VFR được tính theo hai thành phần:

* VFR theo tấn.
* VFR theo khối.

Sau đó lấy giá trị lớn hơn giữa hai tỷ lệ này làm **VFR Max**.

Công thức tổng quát:

> VFR Max = MAX(VFR Tấn, VFR Khối)

VFR cần được tính riêng cho:

* Chuyến gửi thầu — GT.
* Chuyến vận hành — VH.

---

## 5.2 VFR Tấn

**VFR Tấn** đo lường mức độ sử dụng xe theo trọng tải.

Công thức:

> VFR Tấn = Tấn chở / Tấn đăng ký × 100%

Trong đó:

| Thành phần  | Mô tả                                               |
| ----------- | --------------------------------------------------- |
| Tấn chở     | Tổng trọng lượng hàng hóa được chở trên chuyến      |
| Tấn đăng ký | Trọng tải đăng ký hoặc tải trọng tối đa của loại xe |

Nguồn dữ liệu tham chiếu:

| Nhóm dữ liệu      | Field gợi ý                        |
| ----------------- | ---------------------------------- |
| Trọng tải đăng ký | `Ton` từ danh mục loại xe          |
| Tấn kế hoạch      | `Ton` từ View Giám sát - Phân phối |
| Tấn nhận          | `TonTransfer`                      |
| Tấn giao          | `TonBBGN`                          |

Cần xác nhận với business/data team field nào được dùng làm **Tấn chở** chính thức cho GT và VH.

---

## 5.3 VFR Khối

**VFR Khối** đo lường mức độ sử dụng xe theo thể tích.

Công thức:

> VFR Khối = Khối chở / Khối đăng ký × 100%

Trong đó:

| Thành phần   | Mô tả                                              |
| ------------ | -------------------------------------------------- |
| Khối chở     | Tổng thể tích hàng hóa được chở trên chuyến        |
| Khối đăng ký | Thể tích tối đa hoặc dung tích đăng ký của loại xe |

Nguồn dữ liệu tham chiếu:

| Nhóm dữ liệu     | Field gợi ý               |
| ---------------- | ------------------------- |
| Khối đăng ký     | `CBM` từ danh mục loại xe |
| Số khối kế hoạch | `OPSCBM`                  |
| Số khối nhận     | `OPSCBMTransfer`          |
| Số khối giao     | `OPSCBMBBGN`              |

Cần xác nhận với business/data team field nào được dùng làm **Khối chở** chính thức cho GT và VH.

---

## 5.4 VFR Max

**VFR Max** là giá trị lớn hơn giữa VFR Tấn và VFR Khối.

Công thức:

> VFR Max = MAX(VFR Tấn, VFR Khối)

Mục đích:

* Nếu hàng nặng nhưng chiếm ít thể tích, VFR Tấn có thể cao hơn.
* Nếu hàng nhẹ nhưng chiếm nhiều thể tích, VFR Khối có thể cao hơn.
* VFR Max phản ánh yếu tố giới hạn chính của chuyến.

Ví dụ:

| VFR Tấn | VFR Khối | VFR Max |
| ------- | -------- | ------- |
| 72.73%  | 66.67%   | 72.73%  |
| 60.00%  | 80.00%   | 80.00%  |

---

## 5.5 Phân loại VFR của chuyến

Sau khi tính VFR Max, hệ thống cần xác định chuyến được phân loại theo tấn hay theo khối.

Điều kiện xác định:

| Điều kiện            | Phân loại VFR |
| -------------------- | ------------- |
| `VFR Max = VFR Tấn`  | Tấn           |
| `VFR Max = VFR Khối` | Khối          |

Nếu VFR Tấn bằng VFR Khối, hệ thống ưu tiên phân loại là **Khối**, trừ khi business xác nhận rule khác.

---

## 5.6 Phân nhóm VFR theo ngưỡng

Dashboard cần phân loại VFR theo các ngưỡng để người dùng dễ nhận diện mức độ sử dụng xe.

| Nhóm VFR  | Điều kiện       | Ý nghĩa             |
| --------- | --------------- | ------------------- |
| `<50%`    | VFR < 50%       | Sử dụng xe rất thấp |
| `50%–70%` | 50% ≤ VFR < 70% | Sử dụng xe thấp     |
| `70%–95%` | 70% ≤ VFR < 95% | Sử dụng xe tốt      |
| `≥95%`    | VFR ≥ 95%       | Sử dụng xe rất cao  |

Trong phạm vi MVP, dashboard cần hiển thị đầy đủ 4 nhóm scorecard chính:

* `<50%`
* `50%–70%`
* `70%–95%`
* `≥95%`

---

## 5.7 VFR theo loại bốc xếp

VFR cần được tính theo từng **loại bốc xếp** để phản ánh đặc thù vận hành và phương thức xử lý hàng hóa.

Dữ liệu loại bốc xếp được xác định theo field:

> `UnloadingTypeID`

Yêu cầu:

* Mỗi chuyến cần xác định loại bốc xếp tương ứng.
* VFR được tính theo từng loại bốc xếp.
* VFR theo loại bốc xếp được tính dựa trên nhóm chuyến đã phân loại theo VFR Tấn hoặc VFR Khối.
* VFR Tổng được tổng hợp từ VFR của từng loại bốc xếp.

---

## 5.8 VFR Tấn/Khối theo từng loại bốc xếp

Ví dụ với **Loại bốc xếp 1**, hệ thống cần lấy ra các dòng dữ liệu có `Loại bốc xếp = 1`, sau đó thực hiện tính toán.

Công thức:

> VFR Tấn của loại bốc xếp = SUM Tấn chở của các chuyến có phân loại VFR = Tấn / SUM Tấn đăng ký của các chuyến có phân loại VFR = Tấn

> VFR Khối của loại bốc xếp = SUM Khối chở của các chuyến có phân loại VFR = Khối / SUM Khối đăng ký của các chuyến có phân loại VFR = Khối

Trong đó:

| Thành phần                         | Mô tả                                              |
| ---------------------------------- | -------------------------------------------------- |
| Các chuyến có phân loại VFR = Tấn  | Các chuyến mà VFR Max được quyết định bởi VFR Tấn  |
| Các chuyến có phân loại VFR = Khối | Các chuyến mà VFR Max được quyết định bởi VFR Khối |
| Loại bốc xếp                       | Nhóm bốc xếp được xác định theo `UnloadingTypeID`  |

---

## 5.9 VFR của từng loại bốc xếp

Sau khi có VFR Tấn và VFR Khối của từng loại bốc xếp, hệ thống cần tính VFR tổng hợp cho từng loại bốc xếp.

Công thức khái niệm:

> VFR loại bốc xếp = VFR Tấn của loại bốc xếp × tỷ trọng khối chở của nhóm phân loại Tấn + VFR Khối của loại bốc xếp × tỷ trọng khối chở của nhóm phân loại Khối

Trong đó:

| Thành phần                | Mô tả                                                                                  |
| ------------------------- | -------------------------------------------------------------------------------------- |
| VFR Tấn của loại bốc xếp  | VFR tính từ nhóm chuyến có phân loại VFR = Tấn                                         |
| VFR Khối của loại bốc xếp | VFR tính từ nhóm chuyến có phân loại VFR = Khối                                        |
| Tỷ trọng khối chở         | Tỷ trọng `SUM Khối chở / SUM Khối đăng ký` hoặc logic weighting theo business xác nhận |

Ghi chú: Logic này là logic đặc thù của dashboard VFR, không phải phép tính trung bình đơn giản của VFR từng chuyến.

---

## 5.10 VFR Tổng

**VFR Tổng** là tỷ lệ sử dụng xe tổng hợp sau khi tính VFR theo từng loại bốc xếp.

Công thức khái niệm:

> VFR Tổng = VFR loại bốc xếp 1 × tỷ trọng khối chở của loại bốc xếp 1 + VFR loại bốc xếp 2 × tỷ trọng khối chở của loại bốc xếp 2 + ... + VFR loại bốc xếp n × tỷ trọng khối chở của loại bốc xếp n

Trong đó:

| Thành phần                           | Mô tả                                                     |
| ------------------------------------ | --------------------------------------------------------- |
| VFR loại bốc xếp n                   | VFR được tính cho từng nhóm loại bốc xếp                  |
| Tỷ trọng khối chở của loại bốc xếp n | Tỷ trọng của loại bốc xếp đó trong tổng dữ liệu được chọn |

Kết quả cần được tính riêng cho:

* Chuyến gửi thầu — GT.
* Chuyến vận hành — VH.

---

## 6. Functional Requirements

## 6.1 Scorecard tổng quan

Dashboard cần hiển thị các scorecard chính ở phần đầu trang.

Các scorecard bao gồm:

| Scorecard                   | Mô tả                                                |
| --------------------------- | ---------------------------------------------------- |
| Tỷ lệ sử dụng xe trung bình | VFR trung bình của chuyến gửi thầu/vận hành          |
| Tỷ lệ sử dụng xe `<50%`     | Số lượng chuyến gửi thầu/vận hành có VFR < 50%       |
| Tỷ lệ sử dụng xe `50%–70%`  | Số lượng chuyến gửi thầu/vận hành có 50% ≤ VFR < 70% |
| Tỷ lệ sử dụng xe `70%–95%`  | Số lượng chuyến gửi thầu/vận hành có 70% ≤ VFR < 95% |
| Tỷ lệ sử dụng xe `≥95%`     | Số lượng chuyến gửi thầu/vận hành có VFR ≥ 95%       |

Yêu cầu:

* Scorecard cần hiển thị riêng cho **chuyến gửi thầu — GT** và **chuyến vận hành — VH**.
* Dashboard có tổng cộng 10 scorecard: 5 scorecard cho GT và 5 scorecard cho VH.
* Có thể thiết kế dạng tab hoặc chia cột GT/VH để tránh quá tải giao diện.
* Giá trị scorecard có thể hiển thị dạng số lượng chuyến, tỷ lệ phần trăm hoặc cả hai tùy thiết kế dashboard.

---

## 6.2 Mixed Chart — VFR theo Khu vực

Dashboard cần có mixed chart hiển thị tỷ lệ sử dụng xe theo khu vực giao hàng.

Yêu cầu:

* Trục X: Khu vực giao hàng của điểm giao cuối.
* Cột: Số khối kế hoạch.
* Đường: Tỷ lệ sử dụng xe.
* Cần hiển thị riêng cho GT và VH.
* Cho phép lọc theo kho lấy hàng, khu vực giao hàng, nhà vận tải, loại xe, dịch vụ đơn hàng, loại ngày và khoảng thời gian.

Mục đích:

* Xác định khu vực có VFR thấp.
* Phát hiện khu vực thường xuyên có xe chạy non tải.
* Hỗ trợ tối ưu kế hoạch ghép hàng theo vùng.

---

## 6.3 Mixed Chart — VFR theo Loại xe

Dashboard cần có mixed chart hiển thị VFR theo loại xe.

Yêu cầu:

* Trục X: Loại xe.
* Cột: Số khối kế hoạch.
* Đường: Tỷ lệ sử dụng xe.
* Chart GT sử dụng **Loại xe gửi thầu**.
* Chart VH sử dụng **Loại xe vận hành**.
* Có thể lọc riêng theo `TenderGroupOfVehicleName` và `GroupOfVehicleName`.

Mục đích:

* Xác định loại xe có tỷ lệ sử dụng thấp.
* Hỗ trợ lựa chọn loại xe phù hợp hơn khi gửi thầu.
* Phát hiện chênh lệch giữa loại xe gửi thầu và loại xe vận hành.

---

## 6.4 Mixed Chart — VFR theo Loại bốc xếp

Dashboard cần có mixed chart hiển thị VFR theo loại bốc xếp.

Yêu cầu:

* Trục X: Loại bốc xếp của điểm giao cuối.
* Cột: Số khối kế hoạch.
* Đường: Tỷ lệ sử dụng xe.
* Cần hiển thị riêng cho GT và VH.
* Loại bốc xếp được xác định theo `UnloadingTypeID`.

Mục đích:

* Phân tích ảnh hưởng của loại bốc xếp đến tỷ lệ sử dụng xe.
* Xác định nhóm bốc xếp thường có VFR thấp.
* Hỗ trợ cải thiện quy trình lập kế hoạch và ghép hàng.

---

## 6.5 Table — VFR theo thời gian và khu vực

Dashboard cần có table hoặc matrix thể hiện VFR theo thời gian và khu vực.

Yêu cầu:

* Hiển thị theo tháng, năm và khu vực.
* Giá trị hiển thị: tỷ lệ sử dụng xe.
* Cần hiển thị riêng cho GT và VH.
* Cho phép phân tích xu hướng VFR theo thời gian và khu vực.

Mục đích:

* Theo dõi xu hướng VFR theo tháng/năm.
* So sánh hiệu quả sử dụng xe giữa các khu vực.
* Xác định khu vực có VFR thấp kéo dài qua nhiều kỳ.

---

## 6.6 Bảng chi tiết dữ liệu — Chuyến gửi thầu

Dashboard cần có bảng chi tiết dữ liệu theo **ID chuyến gửi thầu — TenderMasterID**.

Mỗi dòng được group theo `TenderMasterID` nếu VFR tính theo chuyến gửi thầu.

Bảng cần hiển thị các thông tin chính:

| Trường dữ liệu      | Mã cột                     | Mô tả                                     |
| ------------------- | -------------------------- | ----------------------------------------- |
| ID chuyến gửi thầu  | `TenderMasterID`           | ID chuyến gửi thầu                        |
| Mã chuyến vận hành  | `MasterCode`               | Mã chuyến vận hành liên quan              |
| Mã đơn hàng         | `OrderCode`                | Danh sách đơn hàng trong chuyến           |
| Dịch vụ vận chuyển  | `ServiceOfOrderName`       | Loại dịch vụ                              |
| Trạng thái chuyến   | `StatusOfDITOMasterName`   | Trạng thái chuyến                         |
| Thời gian gửi thầu  | `TenderedDate`             | Ngày giờ gửi thầu                         |
| ETA chuyến vận hành | `MasterETA`                | Thời gian dự kiến đến của chuyến vận hành |
| ATA chuyến vận hành | `MasterATA`                | Thời gian thực tế đến của chuyến vận hành |
| Nhà vận tải         | `VendorShortName`          | Tên ngắn nhà thầu/nhà xe                  |
| Mã điểm nhận        | `LocationFromCode`         | Mã điểm nhận                              |
| Tên điểm nhận       | `LocationFromName`         | Tên điểm nhận                             |
| Mã điểm giao        | `LocationToCode`           | Mã điểm giao                              |
| Tên điểm giao       | `LocationToName`           | Tên điểm giao                             |
| Khu vực đội xe      | `Note2`                    | Khu vực                                   |
| Loại bốc xếp        | `UnloadingTypeID`          | Loại bốc xếp                              |
| Mã hàng hóa         | `ProductCode`              | Mã sản phẩm                               |
| Tên hàng hóa        | `ProductName`              | Tên sản phẩm                              |
| Tên nhóm hàng       | `GroupOfProductName`       | Nhóm sản phẩm                             |
| Loại xe gửi thầu    | `TenderGroupOfVehicleName` | Loại xe gửi thầu                          |
| Trọng tải đăng ký   | `Ton`                      | Tấn đăng ký của loại xe                   |
| CBM đăng ký         | `CBM`                      | Khối đăng ký của loại xe                  |
| Tấn chở             | `TonTransfer`              | Tấn dùng để tính VFR GT                   |
| Khối chở            | `OPSCBMTransfer`           | Khối dùng để tính VFR GT                  |
| VFR Tấn             | Calculated                 | Tấn chở / Tấn đăng ký                     |
| VFR Khối            | Calculated                 | Khối chở / Khối đăng ký                   |
| VFR Max             | Calculated                 | Max giữa VFR Tấn và VFR Khối              |
| Phân loại VFR       | Calculated                 | Tấn / Khối                                |
| Nhóm VFR            | Calculated                 | `<50%`, `50%–70%`, `70%–95%`, `≥95%`      |

Mục đích:

* Cho phép người dùng kiểm tra VFR của chuyến gửi thầu.
* Hỗ trợ đánh giá chất lượng kế hoạch gửi thầu.
* Làm cơ sở phân tích xe chạy non tải trước khi vận hành thực tế.

---

## 6.7 Bảng chi tiết dữ liệu — Chuyến vận hành

Dashboard cần có bảng chi tiết dữ liệu theo **Mã chuyến vận hành — MasterCode**.

Mỗi dòng được group theo `MasterCode` nếu VFR tính theo chuyến vận hành.

Bảng cần hiển thị các thông tin chính:

| Trường dữ liệu      | Mã cột                   | Mô tả                                |
| ------------------- | ------------------------ | ------------------------------------ |
| Mã chuyến vận hành  | `MasterCode`             | Mã chuyến vận hành                   |
| ID chuyến gửi thầu  | `TenderMasterID`         | ID chuyến gửi thầu liên quan         |
| Mã đơn hàng         | `OrderCode`              | Danh sách đơn hàng trong chuyến      |
| Dịch vụ vận chuyển  | `ServiceOfOrderName`     | Loại dịch vụ                         |
| Trạng thái chuyến   | `StatusOfDITOMasterName` | Trạng thái chuyến                    |
| Thời gian gửi thầu  | `TenderedDate`           | Ngày giờ gửi thầu                    |
| ETA chuyến vận hành | `MasterETA`              | Thời gian dự kiến đến                |
| ATA chuyến vận hành | `MasterATA`              | Thời gian thực tế đến                |
| Số xe               | `RegNo`                  | Biển số xe                           |
| Tên tài xế          | `DriverName1`            | Tên tài xế                           |
| Nhà vận tải         | `VendorShortName`        | Tên ngắn nhà thầu                    |
| Mã điểm nhận        | `LocationFromCode`       | Mã điểm nhận                         |
| Tên điểm nhận       | `LocationFromName`       | Tên điểm nhận                        |
| Mã điểm giao        | `LocationToCode`         | Mã điểm giao                         |
| Tên điểm giao       | `LocationToName`         | Tên điểm giao                        |
| Khu vực đội xe      | `Note2`                  | Khu vực                              |
| Loại bốc xếp        | `UnloadingTypeID`        | Loại bốc xếp                         |
| Tên nhóm hàng       | `GroupOfProductName`     | Nhóm sản phẩm                        |
| Loại xe vận hành    | `GroupOfVehicleName`     | Loại xe vận hành                     |
| Trọng tải đăng ký   | `Ton`                    | Tấn đăng ký của loại xe              |
| CBM đăng ký         | `CBM`                    | Khối đăng ký của loại xe             |
| Tấn chở             | `TonTransfer`            | Tấn dùng để tính VFR VH              |
| Khối chở            | `OPSCBMTransfer`         | Khối dùng để tính VFR VH             |
| VFR Tấn             | Calculated               | Tấn chở / Tấn đăng ký                |
| VFR Khối            | Calculated               | Khối chở / Khối đăng ký              |
| VFR Max             | Calculated               | Max giữa VFR Tấn và VFR Khối         |
| Phân loại VFR       | Calculated               | Tấn / Khối                           |
| Nhóm VFR            | Calculated               | `<50%`, `50%–70%`, `70%–95%`, `≥95%` |

Mục đích:

* Cho phép người dùng kiểm tra VFR của chuyến vận hành.
* So sánh VFR thực tế với kế hoạch gửi thầu.
* Hỗ trợ đánh giá nhà vận tải và hiệu quả sử dụng xe thực tế.

---

## 6.8 Xuất báo cáo

Người dùng Full Access cần có khả năng xuất dữ liệu từ dashboard.

Yêu cầu:

* Xuất dữ liệu bảng chi tiết GT.
* Xuất dữ liệu bảng chi tiết VH.
* Định dạng đề xuất: Excel hoặc CSV.
* Dữ liệu xuất ra phải tuân theo filter đang được áp dụng trên dashboard.
* File xuất cần bao gồm các cột tính toán VFR Tấn, VFR Khối, VFR Max, phân loại VFR và nhóm VFR.

---

## 7. Filters

Dashboard cần hỗ trợ các bộ lọc sau:

| Tên bộ lọc        | Loại bộ lọc  | Tiêu chí lọc                                    | Ghi chú                                   |
| ----------------- | ------------ | ----------------------------------------------- | ----------------------------------------- |
| Kho lấy hàng      | Multi-select | Danh sách tên hệ thống từ danh mục địa điểm kho | Mặc định chọn tất cả giá trị              |
| Khu vực giao hàng | Multi-select | Danh sách tên khu vực từ thiết lập khu vực      | Mặc định chọn tất cả giá trị              |
| Nhà vận tải       | Multi-select | Danh sách tên ngắn từ danh sách nhà xe          | Mặc định chọn tất cả giá trị              |
| Loại xe gửi thầu  | Multi-select | Danh sách mã/tên loại xe gửi thầu               | Áp dụng riêng cho nhóm chart VFR gửi thầu |
| Loại xe vận hành  | Multi-select | Danh sách mã/tên loại xe vận hành               | Áp dụng riêng cho nhóm chart VFR vận hành |
| Dịch vụ đơn hàng  | Multi-select | Danh sách từ danh mục loại dịch vụ              | Mặc định chọn tất cả giá trị              |
| Loại ngày         | Combo box    | ETA chuyến vận hành / ATA chuyến vận hành       | Mặc định: ATA chuyến vận hành             |
| Khoảng thời gian  | Date range   | Từ ngày đến ngày                                | Tối đa 12 tháng, mặc định tháng hiện tại  |

---

## 7.1 Quy tắc filter thời gian

* Người dùng chỉ được chọn khoảng thời gian tối đa 12 tháng.
* Mặc định dashboard hiển thị dữ liệu của tháng hiện tại.
* Loại ngày mặc định là **ATA chuyến vận hành**.
* Người dùng có thể chọn **ETA chuyến vận hành** hoặc **ATA chuyến vận hành**.
* Khi người dùng đổi loại ngày, toàn bộ dashboard cần tính toán lại theo loại ngày được chọn.
* Nếu người dùng chọn khoảng thời gian vượt quá 12 tháng, hệ thống cần hiển thị cảnh báo.

Thông báo đề xuất:

> Vui lòng chọn khoảng thời gian không vượt quá 12 tháng.

---

## 7.2 Quy tắc filter loại xe

Dashboard có hai bộ lọc loại xe riêng:

| Bộ lọc           | Phạm vi áp dụng                                     |
| ---------------- | --------------------------------------------------- |
| Loại xe gửi thầu | Áp dụng cho nhóm chart và bảng dữ liệu VFR gửi thầu |
| Loại xe vận hành | Áp dụng cho nhóm chart và bảng dữ liệu VFR vận hành |

Nếu dashboard hiển thị chart so sánh GT và VH cùng lúc, cần xác định rõ filter nào tác động đến nhóm dữ liệu nào để tránh hiểu nhầm.

---

## 8. Data Requirements

## 8.1 Nguồn dữ liệu

Dữ liệu được lấy từ hệ thống **TMS — Smartlog**.

Các view chính:

1. **View Giám sát - Phân phối**
2. **View Điều phối - Gửi thầu chi tiết**
3. **View Quản trị - Danh mục loại xe**
4. **View Quản trị - Danh mục điểm**
5. Các database/source bổ sung liên quan đến tấn giao, nếu có

---

## 8.2 Điều kiện dữ liệu đầu vào

Chỉ các bản ghi thỏa mãn đầy đủ các điều kiện sau mới được đưa vào dashboard:

| Trường dữ liệu           | Điều kiện           | Ghi chú                             |
| ------------------------ | ------------------- | ----------------------------------- |
| StatusOfDITOMaster       | Đã hoàn thành       | Trạng thái chi tiết chuyến vận hành |
| TenderMasterID           | Không null          | ID chuyến gửi thầu                  |
| TenderGroupOfVehicleName | Không null          | Loại xe gửi thầu                    |
| GroupOfVehicleName       | Không null          | Loại xe vận hành                    |
| ServiceOfOrderName       | Xuất bán            | Dịch vụ vận chuyển                  |
| LocationFromCode         | Bằng `TextFromCode` | Chỉ áp dụng cho VFR gửi thầu        |

Ghi chú: Điều kiện `LocationFromCode = TextFromCode` chỉ áp dụng đối với VFR gửi thầu.

---

## 8.3 Các trường dữ liệu chính

Bảng dữ liệu chi tiết cần có các trường sau:

| Trường dữ liệu      | Mã cột                     | Nguồn                                |
| ------------------- | -------------------------- | ------------------------------------ |
| ID chuyến gửi thầu  | `TenderMasterID`           | View Điều phối - Gửi thầu chi tiết   |
| Mã chuyến vận hành  | `MasterCode`               | View Điều phối - Gửi thầu chi tiết   |
| Mã đơn hàng         | `OrderCode`                | View Điều phối - Gửi thầu chi tiết   |
| Dịch vụ vận chuyển  | `ServiceOfOrderName`       | View Điều phối - Gửi thầu chi tiết   |
| Trạng thái chuyến   | `StatusOfDITOMasterName`   | View Giám sát - Phân phối            |
| Thời gian gửi thầu  | `TenderedDate`             | View Điều phối - Gửi thầu chi tiết   |
| ETA chuyến vận hành | `MasterETA`                | View Điều phối - Gửi thầu chi tiết   |
| ATA chuyến vận hành | `MasterATA`                | View Điều phối - Gửi thầu chi tiết   |
| Số xe               | `RegNo`                    | View Điều phối - Gửi thầu chi tiết   |
| Tên tài xế          | `DriverName1`              | View Điều phối - Gửi thầu chi tiết   |
| Tên ngắn nhà thầu   | `VendorShortName`          | View Điều phối - Gửi thầu chi tiết   |
| Mã điểm nhận        | `LocationFromCode`         | View Giám sát - Phân phối            |
| Tên điểm nhận       | `LocationFromName`         | View Giám sát - Phân phối            |
| Mã điểm giao        | `LocationToCode`           | View Giám sát - Phân phối            |
| Tên điểm giao       | `LocationToName`           | View Giám sát - Phân phối            |
| Khu vực đội xe      | `Note2`                    | View Quản trị - Danh mục điểm        |
| Loại bốc xếp        | `UnloadingTypeID`          | View Quản trị - Danh mục điểm        |
| Mã hàng hóa         | `ProductCode`              | View Điều phối - Gửi thầu chi tiết   |
| Tên hàng hóa        | `ProductName`              | View Điều phối - Gửi thầu chi tiết   |
| Tên nhóm hàng       | `GroupOfProductName`       | View Điều phối - Gửi thầu chi tiết   |
| Loại xe gửi thầu    | `TenderGroupOfVehicleName` | View Gửi thầu chi tiết               |
| Loại xe vận hành    | `GroupOfVehicleName`       | View Gửi thầu chi tiết               |
| Trọng tải đăng ký   | `Ton`                      | View Quản trị - Loại xe              |
| CBM đăng ký         | `CBM`                      | View Quản trị - Loại xe              |
| Tấn kế hoạch        | `Ton`                      | View Giám sát - Phân phối            |
| Tấn nhận            | `TonTransfer`              | View Giám sát - Phân phối            |
| Tấn giao            | `TonBBGN`                  | Database / nguồn bổ sung             |
| Số khối kế hoạch    | `OPSCBM`                   | View Giám sát - Phân phối            |
| Số khối nhận        | `OPSCBMTransfer`           | View Giám sát - Phân phối            |
| Số khối giao        | `OPSCBMBBGN`               | View Giám sát - Phân phối            |
| VFR Tấn             | Calculated                 | Tính toán                            |
| VFR Khối            | Calculated                 | Tính toán                            |
| VFR Max             | Calculated                 | Tính toán                            |
| Phân loại VFR       | Calculated                 | Tấn / Khối                           |
| Nhóm VFR            | Calculated                 | `<50%`, `50%–70%`, `70%–95%`, `≥95%` |

---

## 8.4 Logic tính VFR

Hệ thống cần tính VFR riêng cho **chuyến gửi thầu — GT** và **chuyến vận hành — VH**.

Quy trình tính VFR cho GT và VH là giống nhau về cách tính, nhưng khác cấp group dữ liệu:

| Nhóm tính                | Cấp group                   |
| ------------------------ | --------------------------- |
| VFR chuyến gửi thầu — GT | Group theo `TenderMasterID` |
| VFR chuyến vận hành — VH | Group theo `MasterCode`     |

---

### 8.4.1 Bước 1 — Tính VFR Tấn/Khối của từng chuyến

Công thức:

```text
VFR Tấn (a) = Tấn chở / Tấn đăng ký
VFR Khối (b) = Khối chở / Khối đăng ký
```

Sau đó lấy giá trị lớn hơn:

```text
VFR Max = MAX(VFR Tấn, VFR Khối)
```

---

### 8.4.2 Bước 2 — Phân loại VFR của chuyến theo VFR Max

Điều kiện:

```text
Nếu VFR Max = VFR Tấn
=> Phân loại VFR = Tấn

Nếu VFR Max = VFR Khối
=> Phân loại VFR = Khối
```

Nếu VFR Tấn bằng VFR Khối, hệ thống ưu tiên phân loại là **Khối**.

---

### 8.4.3 Bước 3 — Tính VFR Tấn/Khối theo từng loại bốc xếp

Ví dụ với **Loại bốc xếp 1**, lấy các dòng dữ liệu có `Loại bốc xếp = 1`.

Công thức:

```text
VFR Tấn (c)
= SUM Tấn chở của các chuyến có phân loại VFR = Tấn
/ SUM Tấn đăng ký của các chuyến có phân loại VFR = Tấn
```

```text
VFR Khối (d)
= SUM Khối chở của các chuyến có phân loại VFR = Khối
/ SUM Khối đăng ký của các chuyến có phân loại VFR = Khối
```

---

### 8.4.4 Bước 4 — Tính VFR của từng loại bốc xếp

Ví dụ với **Loại bốc xếp 1**:

```text
VFR loại bốc xếp 1
= VFR Tấn (c)
  × (SUM Khối chở của các chuyến có phân loại VFR = Tấn
     / SUM Khối đăng ký của các chuyến có phân loại VFR = Tấn)
+ VFR Khối (d)
  × (SUM Khối chở của các chuyến có phân loại VFR = Khối
     / SUM Khối đăng ký của các chuyến có phân loại VFR = Khối)
```

Ghi chú: Công thức này cần được data team xác nhận lại chính xác theo file mẫu tính VFR, vì đây là logic đặc thù của business.

---

### 8.4.5 Bước 5 — Tính VFR Tổng

Sau khi tính được VFR của từng loại bốc xếp, hệ thống tính VFR Tổng.

Công thức khái niệm:

```text
VFR Tổng
= VFR loại bốc xếp 1 × tỷ trọng khối chở của loại bốc xếp 1
+ VFR loại bốc xếp 2 × tỷ trọng khối chở của loại bốc xếp 2
+ ...
+ VFR loại bốc xếp n × tỷ trọng khối chở của loại bốc xếp n
```

VFR Tổng cần được tính riêng cho:

* VFR GT.
* VFR VH.

---

## 8.5 Tần suất cập nhật

Dữ liệu cần được cập nhật **near real-time** từ hệ thống TMS.

Dashboard cần hiển thị thời điểm cập nhật dữ liệu gần nhất.

Ví dụ:

> Last updated: 10:30 AM, 15 Jan 2026

---

## 9. Dashboard Layout

Dashboard MVP gồm **10 scorecard, 8 biểu đồ và 2 bảng dữ liệu chi tiết**.

Các khu vực chính:

* Khu vực filter.
* Khu vực scorecard.
* Nhóm biểu đồ VFR chuyến gửi thầu — GT.
* Nhóm biểu đồ VFR chuyến vận hành — VH.
* Table VFR chuyến gửi thầu — GT theo thời gian và khu vực.
* Table VFR chuyến vận hành — VH theo thời gian và khu vực.
* Bảng dữ liệu chi tiết GT.
* Bảng dữ liệu chi tiết VH.

---

## 9.1 Khu vực filter

Đặt ở đầu dashboard hoặc panel bên trái.

Bao gồm:

* Kho lấy hàng.
* Khu vực giao hàng.
* Nhà vận tải.
* Loại xe gửi thầu.
* Loại xe vận hành.
* Dịch vụ đơn hàng.
* Loại ngày.
* Khoảng thời gian.

---

## 9.2 Khu vực scorecard

Hiển thị các KPI tổng quan theo cả GT và VH.

Các scorecard chính:

1. Tỷ lệ sử dụng xe trung bình — GT.
2. Tỷ lệ sử dụng xe `<50%` — GT.
3. Tỷ lệ sử dụng xe `50%–70%` — GT.
4. Tỷ lệ sử dụng xe `70%–95%` — GT.
5. Tỷ lệ sử dụng xe `≥95%` — GT.
6. Tỷ lệ sử dụng xe trung bình — VH.
7. Tỷ lệ sử dụng xe `<50%` — VH.
8. Tỷ lệ sử dụng xe `50%–70%` — VH.
9. Tỷ lệ sử dụng xe `70%–95%` — VH.
10. Tỷ lệ sử dụng xe `≥95%` — VH.

Ghi chú: Có thể thiết kế dạng tab hoặc toggle **GT / VH** để dashboard dễ đọc hơn.

---

## 9.3 Khu vực biểu đồ phân tích

Các chart/báo cáo đề xuất:

| STT | Chart                              | Loại biểu đồ   | Mục đích                                    |
| --- | ---------------------------------- | -------------- | ------------------------------------------- |
| 1   | VFR theo khu vực — GT              | Mixed Chart    | Phân tích VFR gửi thầu theo khu vực         |
| 2   | VFR theo khu vực — VH              | Mixed Chart    | Phân tích VFR vận hành theo khu vực         |
| 3   | VFR theo loại xe — GT              | Mixed Chart    | Phân tích theo loại xe gửi thầu             |
| 4   | VFR theo loại xe — VH              | Mixed Chart    | Phân tích theo loại xe vận hành             |
| 5   | VFR theo loại bốc xếp — GT         | Mixed Chart    | Phân tích VFR gửi thầu theo loại bốc xếp    |
| 6   | VFR theo loại bốc xếp — VH         | Mixed Chart    | Phân tích VFR vận hành theo loại bốc xếp    |
| 7   | VFR theo thời gian và khu vực — GT | Table / Matrix | So sánh VFR gửi thầu theo tháng/năm/khu vực |
| 8   | VFR theo thời gian và khu vực — VH | Table / Matrix | So sánh VFR vận hành theo tháng/năm/khu vực |

Ghi chú: Nếu cần tối ưu layout, có thể gom các chart của GT/VH thành tab riêng.

---

## 9.4 Khu vực bảng dữ liệu chi tiết

Dashboard cần có 2 bảng dữ liệu chi tiết.

### Bảng 1: Chi tiết VFR chuyến gửi thầu — GT

Yêu cầu:

* Group theo `TenderMasterID`.
* Hiển thị dữ liệu VFR theo chuyến gửi thầu.
* Có thể search theo `TenderMasterID`, `OrderCode`, nhà vận tải, kho, khu vực, loại xe gửi thầu.
* Có thể sort theo VFR Max, nhóm VFR, ngày, nhà vận tải, loại xe gửi thầu.
* Có thể export dữ liệu.

### Bảng 2: Chi tiết VFR chuyến vận hành — VH

Yêu cầu:

* Group theo `MasterCode`.
* Hiển thị dữ liệu VFR theo chuyến vận hành.
* Có thể search theo `MasterCode`, `TenderMasterID`, `OrderCode`, nhà vận tải, kho, khu vực, loại xe vận hành.
* Có thể sort theo VFR Max, nhóm VFR, ngày, nhà vận tải, loại xe vận hành.
* Có thể export dữ liệu.

---

## 10. Access & Permissions

## 10.1 Full Access

Người dùng có quyền Full Access được phép:

* Xem tất cả dữ liệu.
* Sử dụng tất cả filter.
* Xem toàn bộ biểu đồ và bảng chi tiết.
* Xuất báo cáo.
* Truy cập dữ liệu của tất cả nhà vận tải, kho, khu vực, loại xe và dịch vụ đơn hàng.

Hiện tại PRD chỉ định nghĩa quyền **Full Access**. Các quyền giới hạn theo role, khu vực, kho hoặc nhà vận tải chưa nằm trong phạm vi bản MVP nếu chưa có yêu cầu bổ sung.

---

## 11. In Scope

Các hạng mục nằm trong phạm vi dashboard:

1. Tính toán và phân tích VFR theo chuyến gửi thầu.
2. Tính toán và phân tích VFR theo chuyến vận hành.
3. Tính VFR theo trọng tải.
4. Tính VFR theo thể tích.
5. Xác định VFR Max.
6. Phân loại VFR theo Tấn hoặc Khối.
7. Phân nhóm VFR theo các ngưỡng `<50%`, `50%–70%`, `70%–95%`, `≥95%`.
8. Tính VFR theo loại bốc xếp.
9. Tính VFR Tổng theo logic loại bốc xếp.
10. Phân tích VFR theo khu vực giao hàng.
11. Phân tích VFR theo loại xe gửi thầu và loại xe vận hành.
12. Phân tích VFR theo loại bốc xếp.
13. Phân tích VFR theo thời gian và khu vực.
14. Hiển thị bảng chi tiết dữ liệu theo `TenderMasterID`.
15. Hiển thị bảng chi tiết dữ liệu theo `MasterCode`.
16. Hỗ trợ filter theo kho, khu vực, nhà vận tải, loại xe, dịch vụ đơn hàng, loại ngày và khoảng thời gian.
17. Hỗ trợ xuất báo cáo cho người dùng Full Access.
18. Cập nhật dữ liệu near real-time từ TMS.

---

## 12. Out of Scope

Các hạng mục không thuộc phạm vi dashboard này:

1. Tỷ lệ tuân thủ quy trình vận hành tại điểm, vì đây là dashboard riêng.
2. Tỷ lệ đáp ứng chuyến gửi thầu, vì đây là dashboard riêng.
3. Phân tích chi phí vận chuyển chi tiết theo xe.
4. Theo dõi nhiên liệu, bảo trì hoặc hiệu suất kỹ thuật của xe.
5. Tự động khuyến nghị ghép hàng hoặc thay đổi loại xe.
6. Tự động tính penalty hoặc thưởng/phạt nhà vận tải.
7. Dự báo nhu cầu vận tải hoặc forecasting.
8. Custom dashboard builder cho người dùng tự thiết kế dashboard.

---

## 13. Edge Cases & Business Rules

## 13.1 Tấn đăng ký hoặc Khối đăng ký bằng 0/null

Nếu `Tấn đăng ký` hoặc `Khối đăng ký` bằng 0 hoặc null, hệ thống không thể tính VFR tương ứng.

Đề xuất xử lý:

* Không tính VFR của thành phần bị thiếu.
* Flag lý do: **Thiếu dữ liệu tải trọng/thể tích đăng ký**.
* Nếu cả tấn đăng ký và khối đăng ký đều thiếu, loại bản ghi khỏi phần tính VFR.

---

## 13.2 Tấn chở hoặc Khối chở bằng 0/null

Nếu `Tấn chở` hoặc `Khối chở` bằng 0 hoặc null, cần xác nhận business rule.

Đề xuất xử lý:

* Nếu chuyến đã hoàn thành nhưng tấn/khối chở bằng 0, flag là dữ liệu bất thường.
* Nếu một thành phần thiếu nhưng thành phần còn lại hợp lệ, vẫn có thể tính VFR Max dựa trên thành phần hợp lệ.
* Nếu cả tấn chở và khối chở đều thiếu, VFR Max được tính bằng 0.

---

## 13.3 VFR lớn hơn 100%

Nếu VFR lớn hơn 100%, có thể do xe vượt tải, sai dữ liệu đăng ký hoặc sai dữ liệu hàng hóa.

Đề xuất xử lý:

* Hiển thị giá trị VFR là 100%.
* Phân loại vào nhóm `≥95%`.

---

## 13.4 VFR Tấn bằng VFR Khối

Nếu VFR Tấn bằng VFR Khối, hệ thống ưu tiên phân loại là **Khối**.

---

## 13.5 Chuyến gửi thầu không có loại xe gửi thầu

Nếu chuyến gửi thầu không có `TenderGroupOfVehicleName`, bản ghi không đủ điều kiện tính VFR GT.

Đề xuất xử lý:

* Loại khỏi phần tính VFR GT.

---

## 13.6 Chuyến vận hành không có loại xe vận hành

Nếu chuyến vận hành không có `GroupOfVehicleName`, bản ghi không đủ điều kiện tính VFR VH.

Đề xuất xử lý:

* Loại khỏi phần tính VFR VH.

---

## 13.7 LocationFromCode khác TextFromCode đối với VFR gửi thầu

Đối với VFR gửi thầu, điều kiện dữ liệu yêu cầu:

```text
LocationFromCode = TextFromCode
```

Nếu không thỏa mãn điều kiện này:

* Không đưa vào phần tính VFR gửi thầu.

---

## 13.8 ServiceOfOrderName ngoài phạm vi

Dashboard chỉ áp dụng cho:

* `Xuất bán`

Nếu `ServiceOfOrderName` nằm ngoài phạm vi này, bản ghi không được đưa vào dashboard.

---

## 13.9 Loại bốc xếp null

Nếu `UnloadingTypeID` null, hệ thống không thể phân tích VFR theo loại bốc xếp.

Đề xuất xử lý:

* Vẫn cho phép tính VFR chuyến nếu đủ dữ liệu tấn/khối.
* Đưa vào nhóm **Không xác định loại bốc xếp** trong chart loại bốc xếp.
* Flag dữ liệu để cải thiện master data.

---

## 13.10 Khoảng thời gian lớn hơn 12 tháng

Dashboard không cho phép người dùng chọn khoảng thời gian lớn hơn 12 tháng.

Thông báo đề xuất:

> Vui lòng chọn khoảng thời gian không vượt quá 12 tháng.

---

## 14. MVP Recommendation

Với bản MVP, nên ưu tiên phạm vi theo tài liệu visualization gồm: **10 scorecard, 8 biểu đồ và 2 bảng dữ liệu chi tiết**.

---

## 14.1 MVP Components

| STT | Thành phần                             | Mô tả                                                  |
| --- | -------------------------------------- | ------------------------------------------------------ |
| 1   | Scorecard VFR trung bình — GT          | VFR gửi thầu trung bình                                |
| 2   | Scorecard VFR `<50%` — GT              | Số lượng chuyến gửi thầu có VFR < 50%                  |
| 3   | Scorecard VFR `50%–70%` — GT           | Số lượng chuyến gửi thầu có 50% ≤ VFR < 70%            |
| 4   | Scorecard VFR `70%–95%` — GT           | Số lượng chuyến gửi thầu có 70% ≤ VFR < 95%            |
| 5   | Scorecard VFR `≥95%` — GT              | Số lượng chuyến gửi thầu có VFR ≥ 95%                  |
| 6   | Scorecard VFR trung bình — VH          | VFR vận hành trung bình                                |
| 7   | Scorecard VFR `<50%` — VH              | Số lượng chuyến vận hành có VFR < 50%                  |
| 8   | Scorecard VFR `50%–70%` — VH           | Số lượng chuyến vận hành có 50% ≤ VFR < 70%            |
| 9   | Scorecard VFR `70%–95%` — VH           | Số lượng chuyến vận hành có 70% ≤ VFR < 95%            |
| 10  | Scorecard VFR `≥95%` — VH              | Số lượng chuyến vận hành có VFR ≥ 95%                  |
| 11  | Mixed Chart VFR GT theo khu vực        | Phân tích VFR gửi thầu theo khu vực                    |
| 12  | Mixed Chart VFR VH theo khu vực        | Phân tích VFR vận hành theo khu vực                    |
| 13  | Mixed Chart VFR GT theo loại xe        | Phân tích theo loại xe gửi thầu                        |
| 14  | Mixed Chart VFR VH theo loại xe        | Phân tích theo loại xe vận hành                        |
| 15  | Mixed Chart VFR GT theo loại bốc xếp   | Phân tích VFR gửi thầu theo loại bốc xếp               |
| 16  | Mixed Chart VFR VH theo loại bốc xếp   | Phân tích VFR vận hành theo loại bốc xếp               |
| 17  | Table VFR GT theo thời gian và khu vực | So sánh VFR gửi thầu theo tháng/năm/khu vực            |
| 18  | Table VFR VH theo thời gian và khu vực | So sánh VFR vận hành theo tháng/năm/khu vực            |
| 19  | Bảng chi tiết GT                       | Group theo `TenderMasterID`, hiển thị dữ liệu tính VFR |
| 20  | Bảng chi tiết VH                       | Group theo `MasterCode`, hiển thị dữ liệu tính VFR     |

---

## 14.2 MVP Filters

MVP cần hỗ trợ đầy đủ các filter sau:

* Kho lấy hàng.
* Khu vực giao hàng.
* Nhà vận tải.
* Loại xe gửi thầu.
* Loại xe vận hành.
* Dịch vụ đơn hàng.
* Loại ngày.
* Khoảng thời gian.

---

## 14.3 MVP Output

Kết quả MVP cần cho phép người dùng:

* Xem tỷ lệ sử dụng xe tổng thể.
* Xem phân bố VFR theo các ngưỡng `<50%`, `50%–70%`, `70%–95%`, `≥95%`.
* So sánh VFR giữa chuyến gửi thầu và chuyến vận hành.
* Phân tích VFR theo khu vực.
* Phân tích VFR theo loại xe.
* Phân tích VFR theo loại bốc xếp.
* Theo dõi VFR theo thời gian và khu vực.
* Xác định các khu vực, loại xe hoặc loại bốc xếp có VFR thấp.
* Kiểm tra dữ liệu chi tiết theo `TenderMasterID`.
* Kiểm tra dữ liệu chi tiết theo `MasterCode`.
* Xuất dữ liệu chi tiết phục vụ đối soát và làm việc với nhà vận tải.
