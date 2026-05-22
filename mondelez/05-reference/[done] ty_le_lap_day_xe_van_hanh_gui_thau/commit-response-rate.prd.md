# PRD — Dashboard Tỷ lệ Tuân thủ Vận hành tại Điểm

## Fulfillment & Compliance Ratio

**Status:** Done
**Owner:** Thanh
**Last updated:** 06/05/2026 04:00 PM 

---

## 1. Overview

Dashboard **Tỷ lệ Tuân thủ Vận hành tại Điểm** được xây dựng nhằm giám sát và đo lường mức độ tuân thủ quy trình vận hành của các chuyến xe tại từng điểm vận hành, bao gồm **điểm kho** và **điểm giao hàng**.

Dashboard tập trung vào hai nhóm tiêu chí chính:

1. Tài xế có sử dụng **Mobile App tài xế** để thực hiện thao tác **vào điểm** và **ra điểm** hay không.
2. Thời gian load/unload thực tế tại điểm có nằm trong giới hạn hợp lệ so với thời gian load/unload quy định hay không.

Một điểm vận hành được xem là **Tuân thủ** khi đồng thời thỏa mãn tất cả điều kiện sau:

- Phương thức vào điểm là **Mobile App tài xế**.
- Phương thức ra điểm là **Mobile App tài xế**.
- Thời gian load/unload thực tế lớn hơn hoặc bằng thời gian load/unload quy định.
- Thời gian load/unload thực tế nhỏ hơn 8 giờ.

Dashboard giúp các nhóm Logistics, Transport Operation, Carrier Management, Điều phối vận hành và lãnh đạo chuỗi cung ứng đánh giá chất lượng tuân thủ quy trình vận hành theo nhà vận tải, tài xế, điểm vận hành và thời gian.

---

## 2. Problem Statement

Hiện tại, việc theo dõi mức độ tuân thủ quy trình vào/ra điểm bằng **Mobile App tài xế** chưa có công cụ trực quan và tự động. Người dùng khó xác định tài xế, nhà vận tải hoặc điểm vận hành nào thường xuyên không thực hiện đúng quy trình.

Ngoài ra, thời gian load/unload thực tế tại điểm có thể thấp hơn thời gian quy định hoặc vượt ngưỡng hợp lệ, ảnh hưởng đến chất lượng dữ liệu, hiệu quả vận hành, khả năng quay vòng xe và chất lượng dịch vụ.

Các vấn đề chính bao gồm:

- Chưa có dashboard tự động đo lường việc tài xế sử dụng Mobile App khi vào/ra điểm.
- Khó theo dõi thời gian load/unload thực tế so với thời gian load/unload quy định.
- Thiếu khả năng phân tích tỷ lệ tuân thủ theo nhà vận tải và thời gian.
- Khó xác định các trường hợp vi phạm để làm việc với nhà vận tải hoặc cải thiện quy trình vận hành.
- Chưa có bảng dữ liệu chi tiết phục vụ đối soát từng điểm vận hành trong từng chuyến.

Do đó, cần có dashboard giúp giám sát tỷ lệ tuân thủ, phát hiện vi phạm và hỗ trợ đánh giá hiệu suất vận hành theo nhà vận tải, tài xế, điểm và thời gian.

---

## 3. Target Users

### 3.1 Logistics & Transport Operation Manager

Nhóm này cần theo dõi mức độ tuân thủ vận hành tổng thể của các chuyến xe.

Nhu cầu chính:

- Theo dõi tỷ lệ tuân thủ toàn hệ thống.
- Phát hiện điểm vận hành có thời gian load/unload bất thường.
- Đánh giá chất lượng thực hiện quy trình vào/ra điểm.
- Theo dõi xu hướng cải thiện hoặc suy giảm theo thời gian.

### 3.2 Carrier Management

Nhóm này sử dụng dashboard để đánh giá hiệu suất tuân thủ của từng nhà vận tải.

Nhu cầu chính:

- So sánh tỷ lệ tuân thủ giữa các nhà vận tải.
- Xác định nhà vận tải có tỷ lệ vi phạm cao.
- Làm cơ sở trao đổi KPI, SLA và hợp đồng vận tải.
- Theo dõi chất lượng thực hiện của nhà vận tải theo từng giai đoạn.

### 3.3 Điều phối & Giám sát vận hành

Nhóm này cần dữ liệu chi tiết để theo dõi và xử lý các vấn đề phát sinh trong vận hành.

Nhu cầu chính:

- Kiểm tra từng chuyến và từng điểm vận hành.
- Xác định phương thức vào/ra điểm của tài xế.
- Theo dõi thời gian vào điểm, ra điểm và thời gian load/unload thực tế.
- Truy vết các trường hợp vi phạm theo tài xế, xe, nhà vận tải hoặc điểm vận hành.

### 3.4 Lãnh đạo Chuỗi cung ứng

Nhóm này cần cái nhìn tổng quan về chất lượng tuân thủ vận hành.

Nhu cầu chính:

- Theo dõi xu hướng tỷ lệ tuân thủ theo thời gian.
- Đánh giá mức độ cải thiện sau các hành động vận hành.
- Nhận diện nhà vận tải, điểm vận hành hoặc nhóm điểm cần ưu tiên cải thiện.
- Có dữ liệu tổng quan phục vụ đánh giá hiệu quả vận hành.

---

## 4. Goals & Success Metrics

### 4.1 Goals

Dashboard cần đạt các mục tiêu sau:

1. Giúp người dùng theo dõi tỷ lệ tuân thủ vận hành tại điểm một cách trực quan và gần thời gian thực.
2. Đo lường việc tài xế sử dụng **Mobile App tài xế** khi vào/ra điểm.
3. So sánh thời gian load/unload thực tế với thời gian load/unload quy định.
4. Phân tích tỷ lệ tuân thủ theo nhà vận tải và thời gian.
5. Hỗ trợ xác định tài xế, nhà vận tải hoặc điểm vận hành thường xuyên vi phạm.
6. Cung cấp dữ liệu chi tiết để đối soát, làm việc với nhà vận tải và cải tiến quy trình vận hành.
7. Cho phép xuất dữ liệu chi tiết theo bộ lọc đang áp dụng.

### 4.2 Success Metrics

Dashboard được xem là thành công nếu đáp ứng các tiêu chí sau:

| Nhóm tiêu chí | Chỉ số thành công |
| --- | --- |
| Khả năng theo dõi | Người dùng có thể xem tổng số chuyến, tổng số điểm và tỷ lệ tuân thủ tổng thể |
| Khả năng phân tích | Người dùng có thể phân tích tỷ lệ tuân thủ theo nhà vận tải và thời gian |
| Khả năng phát hiện vi phạm | Người dùng có thể xác định các điểm/chuyến vi phạm trong bảng chi tiết |
| Khả năng đối soát | Dữ liệu chi tiết hiển thị đầy đủ thông tin vào/ra điểm, thời gian load/unload và trạng thái tuân thủ |
| Tính kịp thời | Dữ liệu được cập nhật gần thời gian thực từ TMS |
| Phạm vi MVP | Hoàn thành dashboard với 3 scorecard chính, 2 biểu đồ phân tích và 1 bảng chi tiết |

---

## 5. KPI Definitions

### 5.1 Tổng số chuyến vận hành

**Tổng số chuyến vận hành** là tổng số chuyến hợp lệ thỏa mãn điều kiện dữ liệu đầu vào.

Điều kiện dữ liệu:

- `StatusOfDITOMaster = Đã hoàn thành`
- `ServiceOfOrderName = Xuất bán`

Chuyến vận hành được xác định theo `MasterCode`.

Công thức:

> Tổng số chuyến vận hành = Count distinct `MasterCode`

---

### 5.2 Tổng số điểm vận hành

**Tổng số điểm vận hành** là tổng số điểm hợp lệ trong các chuyến vận hành, được ghi nhận theo `LocationCode`.

Một chuyến vận hành có thể có nhiều điểm, bao gồm:

- Điểm kho
- Điểm giao hàng

Tổng số điểm vận hành là mẫu số chính để tính tỷ lệ tuân thủ.

Công thức:

> Tổng số điểm vận hành = Count số bản ghi điểm vận hành hợp lệ theo `LocationCode`

---

### 5.3 Số điểm tuân thủ

**Số điểm tuân thủ** là tổng số điểm vận hành thỏa mãn đầy đủ điều kiện tuân thủ.

Một điểm vận hành được xem là **Tuân thủ** khi đồng thời thỏa mãn tất cả điều kiện sau:

| Điều kiện | Logic |
| --- | --- |
| Phương thức vào điểm | `ActionComeByName = Mobile App tài xế` |
| Phương thức ra điểm | `ActionLeaveByName = Mobile App tài xế` |
| Thời gian load/unload | `Thời gian load/unload quy định <= Thời gian load/unload thực tế < 8 giờ` |

Kết quả hiển thị trong cột trạng thái:

> `Tuân thủ = Tuân thủ`

---

### 5.4 Số điểm vi phạm

**Số điểm vi phạm** là tổng số điểm vận hành không thỏa mãn một hoặc nhiều điều kiện tuân thủ.

Các trường hợp vi phạm bao gồm:

1. Vào điểm không bằng **Mobile App tài xế**.
2. Ra điểm không bằng **Mobile App tài xế**.
3. Thời gian load/unload thực tế nhỏ hơn thời gian load/unload quy định.
4. Thời gian load/unload thực tế từ 8 giờ trở lên.
5. Thiếu dữ liệu `DateCome` hoặc `DateLeave`.
6. `DateLeave < DateCome`.

Kết quả hiển thị trong cột trạng thái:

> `Tuân thủ = Vi phạm`

---

### 5.5 Thời gian load/unload quy định

**Thời gian load/unload quy định** là thời gian tiêu chuẩn cần thiết để hoàn tất việc load/unload hàng tại một điểm vận hành.

Thời gian này được tính dựa trên:

- Số lượng thùng thực tế giao tại điểm.
- Thời gian xử lý tiêu chuẩn cho mỗi thùng.

Công thức:

> Thời gian load/unload quy định = Số lượng thùng đã giao × Thời gian xử lý / 1 thùng

Trong đó:

| Thành phần | Mô tả |
| --- | --- |
| Số lượng thùng đã giao | Số lượng thùng thực tế giao tại điểm |
| Thời gian xử lý / 1 thùng | Tham số do user setup trong hệ thống |
| Đơn vị lưu trữ | Giây |

Vì tham số **Thời gian xử lý / 1 thùng** được lưu theo đơn vị giây, kết quả cần được quy đổi sang giờ để so sánh với thời gian load/unload thực tế.

Công thức quy đổi:

> Thời gian load/unload quy định giờ = Số lượng thùng đã giao × Thời gian xử lý / 1 thùng giây / 3.600

---

### 5.6 Thời gian load/unload thực tế

**Thời gian load/unload thực tế** là khoảng thời gian thực tế xe ở tại điểm, được tính từ thời điểm xe vào điểm đến thời điểm xe ra điểm.

Công thức:

> Thời gian load/unload thực tế = DateLeave - DateCome

Trong đó:

| Trường dữ liệu | Mô tả |
| --- | --- |
| `DateCome` | Thời gian vào điểm |
| `DateLeave` | Thời gian ra điểm |

Kết quả cần được tính theo đơn vị giờ.

Công thức quy đổi:

> Thời gian load/unload thực tế giờ = DateLeave - DateCome tính theo giây / 3.600

Hoặc tương đương:

> Thời gian load/unload thực tế giờ = DateLeave - DateCome tính theo phút / 60

---

### 5.7 Tỷ lệ tuân thủ

**Tỷ lệ tuân thủ** là tỷ lệ số điểm vận hành tuân thủ trên tổng số điểm vận hành.

Công thức:

> Tỷ lệ tuân thủ = Số điểm tuân thủ / Tổng số điểm vận hành × 100%

Ví dụ:

> Nếu có 1.000 điểm vận hành, trong đó 850 điểm tuân thủ, tỷ lệ tuân thủ là 85%.

---

### 5.8 Tỷ lệ vi phạm

**Tỷ lệ vi phạm** là tỷ lệ số điểm vận hành vi phạm trên tổng số điểm vận hành.

Công thức:

> Tỷ lệ vi phạm = Số điểm vi phạm / Tổng số điểm vận hành × 100%

Hoặc:

> Tỷ lệ vi phạm = 100% - Tỷ lệ tuân thủ

---

## 6. Functional Requirements

### 6.1 Scorecard tổng quan

Dashboard cần hiển thị 3 scorecard chính ở phần đầu trang.

Scorecard MVP bao gồm:

| Scorecard | Mô tả |
| --- | --- |
| Tổng số chuyến vận hành | Tổng số chuyến hợp lệ, tính theo `MasterCode` |
| Tổng số điểm vận hành | Tổng số điểm vận hành hợp lệ |
| Tỷ lệ tuân thủ | Số điểm tuân thủ / Tổng số điểm vận hành |

Các scorecard mở rộng có thể bổ sung sau MVP:

| Scorecard mở rộng | Mô tả |
| --- | --- |
| Số điểm tuân thủ | Tổng số điểm đạt đầy đủ điều kiện tuân thủ |
| Số điểm vi phạm | Tổng số điểm không đạt một hoặc nhiều điều kiện tuân thủ |
| Tỷ lệ vi phạm | Số điểm vi phạm / Tổng số điểm vận hành |

---

### 6.2 Biểu đồ 1 — Tỷ lệ tuân thủ theo Nhà vận tải

Dashboard cần có mixed chart hiển thị tỷ lệ tuân thủ theo từng nhà vận tải.

Yêu cầu:

- Trục X: Nhà vận tải.
- Cột: Số điểm tuân thủ và số điểm vi phạm.
- Đường: Tỷ lệ tuân thủ.
- Cho phép lọc theo mã điểm, loại điểm, nhà vận tải, loại ngày và khoảng thời gian.
- Cho phép sắp xếp theo tỷ lệ tuân thủ tăng dần hoặc giảm dần.

Mục đích:

- So sánh hiệu suất tuân thủ giữa các nhà vận tải.
- Xác định nhà vận tải có tỷ lệ vi phạm cao.
- Hỗ trợ đánh giá Carrier Performance và làm việc về KPI/SLA/hợp đồng.

---

### 6.3 Biểu đồ 2 — Tỷ lệ tuân thủ theo thời gian

Dashboard cần có mixed chart thể hiện xu hướng tỷ lệ tuân thủ theo thời gian.

Yêu cầu:

- Cho phép người dùng chọn chế độ xem theo **ngày**, **tuần** hoặc **tháng**.
- Trục X: Mốc thời gian tương ứng với chế độ xem được chọn.
  - Nếu chọn ngày: hiển thị theo từng ngày.
  - Nếu chọn tuần: hiển thị theo từng tuần.
  - Nếu chọn tháng: hiển thị theo từng tháng.
- Cột: Số điểm tuân thủ và số điểm vi phạm.
- Đường: Tỷ lệ tuân thủ.
- Mặc định sử dụng dữ liệu của tháng hiện tại.
- Loại ngày mặc định là **ATA chuyến vận hành**.
- Khi người dùng thay đổi chế độ xem ngày/tuần/tháng, biểu đồ cần tự động aggregate lại dữ liệu theo cấp thời gian tương ứng.

Mục đích:

- Theo dõi xu hướng tuân thủ tăng hoặc giảm theo thời gian.
- Phát hiện ngày, tuần hoặc tháng có nhiều vi phạm.
- Đánh giá tác động của các hành động cải thiện vận hành.

---

### 6.4 Bảng chi tiết dữ liệu

Dashboard cần có bảng chi tiết dữ liệu ở cấp điểm vận hành, group theo `LocationCode`.

Bảng cần hiển thị các trường sau:

| Trường dữ liệu | Mô tả |
| --- | --- |
| `LocationCode` | Mã điểm |
| Loại điểm | Kho / Giao hàng |
| `MasterCode` | Mã chuyến vận hành |
| `OrderCode` | Mã đơn hàng |
| `RegNo` | Biển số xe |
| `DriverName1` | Tên tài xế |
| `VendorShortName` | Nhà vận tải |
| `DateCome` | Thời gian vào điểm |
| `DateLeave` | Thời gian ra điểm |
| `ActionComeByName` | Phương thức vào điểm |
| `ActionLeaveByName` | Phương thức ra điểm |
| Số lượng thùng đã giao | Số lượng thùng thực tế giao tại điểm |
| Thời gian xử lý / 1 thùng | Tham số setup, đơn vị giây |
| Thời gian load/unload quy định | Số lượng thùng đã giao × thời gian xử lý / 1 thùng |
| Thời gian load/unload thực tế | `DateLeave - DateCome` |
| Tuân thủ | Tuân thủ / Vi phạm |
| Lý do vi phạm | Nhóm lý do vi phạm, nếu có |

Mục đích:

- Cho phép người dùng kiểm tra từng điểm trong từng chuyến vận hành.
- Hỗ trợ truy vết tài xế, xe, nhà vận tải và thời điểm vi phạm.
- Làm cơ sở xuất báo cáo và làm việc với nhà vận tải.

---

### 6.5 Xuất báo cáo

Người dùng Full Access cần có khả năng xuất dữ liệu từ dashboard.

Yêu cầu:

- Xuất dữ liệu bảng chi tiết.
- Định dạng đề xuất: Excel hoặc CSV.
- Dữ liệu xuất ra phải tuân theo bộ lọc đang được áp dụng trên dashboard.
- File xuất cần bao gồm cột trạng thái `Tuân thủ / Vi phạm`.
- File xuất nên bao gồm cột `Lý do vi phạm` để phục vụ đối soát.

---

## 7. Filters

Dashboard cần hỗ trợ các bộ lọc sau:

| Tên bộ lọc | Loại bộ lọc | Tiêu chí lọc | Ghi chú |
| --- | --- | --- | --- |
| Mã điểm | Multi-select | Danh sách điểm hệ thống | Lấy theo `LocationCode` |
| Loại điểm | Multi-select | Kho / Giao hàng | Cho phép chọn một hoặc nhiều loại điểm |
| Nhà vận tải | Multi-select | Danh sách nhà vận tải | Lấy theo `VendorShortName` hoặc mã vendor tương ứng |
| Loại ngày | Combo box | ETA / ATA chuyến vận hành | Mặc định: ATA |
| Khoảng thời gian | Date range | Từ ngày đến ngày | Tối đa 12 tháng, mặc định tháng hiện tại |

---

### 7.1 Quy tắc filter thời gian

- Người dùng chỉ được chọn khoảng thời gian tối đa 12 tháng.
- Mặc định dashboard hiển thị dữ liệu của tháng hiện tại.
- Loại ngày mặc định là **ATA chuyến vận hành**.
- Khi người dùng đổi loại ngày, toàn bộ dashboard cần tính toán lại theo loại ngày được chọn.
- Nếu người dùng chọn khoảng thời gian vượt quá 12 tháng, hệ thống cần hiển thị cảnh báo.

Thông báo đề xuất:

> Vui lòng chọn khoảng thời gian không vượt quá 12 tháng.

---

## 8. Data Requirements

### 8.1 Nguồn dữ liệu

Dữ liệu được lấy từ hệ thống **TMS - Smartlog**.

Các view/báo cáo chính:

1. View Giám sát - Phân phối
2. View Điều phối - Gửi thầu chi tiết
3. Báo cáo 36

---

### 8.2 Điều kiện dữ liệu đầu vào

Chỉ các bản ghi thỏa mãn đầy đủ các điều kiện sau mới được đưa vào dashboard:

| Trường dữ liệu | Điều kiện |
| --- | --- |
| `StatusOfDITOMaster` | Đã hoàn thành |
| `ServiceOfOrderName` | Xuất bán |

---

### 8.3 Các trường dữ liệu chính

Bảng dữ liệu chi tiết cần có các trường sau:

| Trường dữ liệu | Mô tả |
| --- | --- |
| `LocationCode` | Mã điểm |
| Loại điểm | Kho / Giao hàng |
| `MasterCode` | Mã chuyến vận hành |
| `OrderCode` | Mã đơn hàng |
| `RegNo` | Biển số xe |
| `DriverName1` | Tên tài xế |
| `VendorShortName` | Nhà vận tải |
| `DateCome` | Thời gian vào điểm |
| `DateLeave` | Thời gian ra điểm |
| `ActionComeByName` | Phương thức vào điểm |
| `ActionLeaveByName` | Phương thức ra điểm |
| Số lượng thùng đã giao | Dùng để tính thời gian load/unload quy định |
| Thời gian xử lý / 1 thùng | Tham số do user setup, đơn vị giây |
| Thời gian load/unload quy định | Kết quả tính từ số lượng thùng đã giao và thời gian xử lý / 1 thùng |
| Thời gian load/unload thực tế | `DateLeave - DateCome` |
| Tuân thủ | Tuân thủ / Vi phạm |
| Lý do vi phạm | Nhóm lý do vi phạm, nếu có |

---

### 8.4 Logic xác định tuân thủ

Hệ thống cần tính trạng thái tuân thủ ở cấp **điểm vận hành**.

Một điểm được xem là **Tuân thủ** nếu:

```text
ActionComeByName = "Mobile App tài xế"
AND ActionLeaveByName = "Mobile App tài xế"
AND Thời gian load/unload quy định <= Thời gian load/unload thực tế
AND Thời gian load/unload thực tế < 8 giờ
````

Nếu không thỏa mãn đầy đủ điều kiện trên, điểm được xem là **Vi phạm**.

---

### 8.5 Logic xác định lý do vi phạm

Dashboard nên ghi nhận lý do vi phạm để hỗ trợ phân tích và đối soát.

Các nhóm lý do vi phạm đề xuất:

| Lý do vi phạm                           | Điều kiện                                                      |
| --------------------------------------- | -------------------------------------------------------------- |
| Không vào điểm bằng Mobile App          | `ActionComeByName != Mobile App tài xế`                        |
| Không ra điểm bằng Mobile App           | `ActionLeaveByName != Mobile App tài xế`                       |
| Thiếu thời gian vào điểm                | `DateCome` null                                                |
| Thiếu thời gian ra điểm                 | `DateLeave` null                                               |
| Dữ liệu thời gian không hợp lệ          | `DateLeave < DateCome`                                         |
| Thời gian load/unload thấp hơn quy định | Thời gian load/unload thực tế < Thời gian load/unload quy định |
| Thời gian load/unload vượt ngưỡng       | Thời gian load/unload thực tế >= 8 giờ                         |

Một điểm có thể có nhiều lý do vi phạm.

---

### 8.6 Tần suất cập nhật

Dữ liệu cần được cập nhật **gần thời gian thực** từ hệ thống TMS.

Dashboard cần hiển thị thời điểm cập nhật dữ liệu gần nhất.

Ví dụ:

> Last updated: 10:30 AM, 15 Jan 2026

SLA cập nhật dữ liệu cụ thể cần được xác nhận thêm với đội kỹ thuật hoặc đội dữ liệu.

---

## 9. Dashboard Layout

Dashboard MVP gồm:

* 3 scorecard chính
* 2 biểu đồ phân tích
* 1 bảng chi tiết dữ liệu

---

### 9.1 Khu vực filter

Khu vực filter đặt ở đầu dashboard hoặc panel bên trái.

Bao gồm:

* Mã điểm
* Loại điểm
* Nhà vận tải
* Loại ngày
* Khoảng thời gian

---

### 9.2 Khu vực scorecard

Hiển thị 3 KPI tổng quan:

1. Tổng số chuyến vận hành
2. Tổng số điểm vận hành
3. Tỷ lệ tuân thủ

Có thể bổ sung thêm sau MVP:

4. Số điểm tuân thủ
5. Số điểm vi phạm
6. Tỷ lệ vi phạm

---

### 9.3 Khu vực biểu đồ phân tích

Các biểu đồ trong MVP:

| STT | Biểu đồ                         | Loại biểu đồ | Mục đích                                        |
| --- | ------------------------------- | ------------ | ----------------------------------------------- |
| 1   | Tỷ lệ tuân thủ theo nhà vận tải | Mixed chart  | So sánh Carrier Performance                     |
| 2   | Tỷ lệ tuân thủ theo thời gian   | Mixed chart  | Theo dõi xu hướng tuân thủ theo ngày/tuần/tháng |

---

### 9.4 Khu vực bảng dữ liệu

Bảng chi tiết đặt ở cuối dashboard.

Yêu cầu:

* Group theo `LocationCode`.
* Hiển thị dữ liệu theo từng điểm của từng chuyến vận hành.
* Có thể search theo `LocationCode`, `MasterCode`, `OrderCode`, `RegNo`, `DriverName1`, `VendorShortName`.
* Có thể sort theo ngày, nhà vận tải, thời gian load/unload thực tế, trạng thái tuân thủ.
* Có thể export dữ liệu theo bộ lọc đang áp dụng.

---

## 10. Access & Permissions

### 10.1 Full Access

Người dùng có quyền Full Access được phép:

* Xem tất cả dữ liệu.
* Sử dụng tất cả filter.
* Xem toàn bộ biểu đồ và bảng chi tiết.
* Xuất báo cáo.
* Truy cập dữ liệu của tất cả nhà vận tải, điểm vận hành và loại điểm.

Hiện tại PRD chỉ định nghĩa quyền **Full Access**. Các quyền giới hạn theo khu vực, nhà vận tải hoặc nhóm người dùng chưa nằm trong phạm vi MVP nếu chưa có yêu cầu bổ sung.

---

## 11. In Scope

Các hạng mục nằm trong phạm vi dashboard:

1. Theo dõi tỷ lệ tuân thủ quy trình vào/ra điểm bằng Mobile App tài xế.
2. Kiểm tra phương thức vào điểm và ra điểm của tài xế.
3. Tính thời gian load/unload quy định.
4. Tính thời gian load/unload thực tế.
5. Xác định trạng thái Tuân thủ / Vi phạm ở cấp điểm vận hành.
6. Ghi nhận lý do vi phạm ở cấp điểm vận hành.
7. Phân tích tỷ lệ tuân thủ theo nhà vận tải.
8. Phân tích tỷ lệ tuân thủ theo thời gian.
9. Hiển thị bảng chi tiết dữ liệu group theo `LocationCode`.
10. Hỗ trợ filter theo mã điểm, loại điểm, nhà vận tải, loại ngày và khoảng thời gian.
11. Hỗ trợ xuất báo cáo cho người dùng Full Access.
12. Cập nhật dữ liệu gần thời gian thực từ TMS.

---

## 12. Out of Scope

Các hạng mục không thuộc phạm vi dashboard này:

1. Tỷ lệ đáp ứng chuyến gửi thầu, vì đây là dashboard riêng.
2. Phân tích chi phí vận chuyển.
3. Theo dõi hiệu suất xe chi tiết như nhiên liệu, bảo dưỡng, tải trọng hoặc hiệu suất tài xế nâng cao.
4. Dự báo nhu cầu vận tải.
5. Tự động gửi cảnh báo hoặc reminder cho tài xế/nhà vận tải.
6. Tự động tính penalty hoặc thưởng/phạt nhà vận tải.
7. Phân tích nguyên nhân vận hành chuyên sâu ngoài logic Mobile App và thời gian load/unload.
8. Custom dashboard builder cho người dùng tự thiết kế dashboard.
9. Phân quyền nâng cao theo khu vực, nhà vận tải hoặc nhóm người dùng nếu chưa có yêu cầu bổ sung.
10. Biểu đồ ranking điểm vận hành có tỷ lệ vi phạm cao.
11. Biểu đồ phân tích riêng theo loại điểm.

---

## 13. Edge Cases & Business Rules

### 13.1 Thiếu DateCome hoặc DateLeave

Nếu thiếu `DateCome` hoặc `DateLeave`, hệ thống không thể tính thời gian load/unload thực tế.

Đề xuất xử lý:

* Gắn trạng thái **Vi phạm**.
* Ghi nhận lý do vi phạm tương ứng:

  * Thiếu thời gian vào điểm
  * Thiếu thời gian ra điểm

---

### 13.2 DateLeave nhỏ hơn DateCome

Nếu `DateLeave < DateCome`, dữ liệu được xem là bất thường.

Đề xuất xử lý:

* Gắn trạng thái **Vi phạm**.
* Ghi nhận lý do vi phạm: **Dữ liệu thời gian không hợp lệ**.

---

### 13.3 Thời gian load/unload thực tế từ 8 giờ trở lên

Nếu thời gian load/unload thực tế >= 8 giờ, điểm vận hành được xem là **Vi phạm**.

Lý do:

* Thời gian vượt ngưỡng hợp lệ.
* Có thể do thao tác vào/ra điểm không đúng thời điểm thực tế.
* Có thể do tài xế quên thao tác ra điểm trên Mobile App.

---

### 13.4 Thời gian load/unload thực tế nhỏ hơn thời gian load/unload quy định

Nếu thời gian load/unload thực tế nhỏ hơn thời gian load/unload quy định, điểm vận hành được xem là **Vi phạm**.

Lý do:

* Không đáp ứng yêu cầu tối thiểu theo thời gian xử lý đã setup.
* Có thể phản ánh thao tác vào/ra điểm không chính xác hoặc dữ liệu không đầy đủ.

---

### 13.5 Vào điểm hoặc ra điểm không bằng Mobile App tài xế

Nếu một trong hai thao tác vào điểm hoặc ra điểm không được thực hiện bằng **Mobile App tài xế**, điểm vận hành được xem là **Vi phạm**.

Ví dụ:

| ActionComeByName  | ActionLeaveByName | Kết quả                                   |
| ----------------- | ----------------- | ----------------------------------------- |
| Mobile App tài xế | Mobile App tài xế | Tuân thủ nếu thời gian load/unload hợp lệ |
| Manual            | Mobile App tài xế | Vi phạm                                   |
| Mobile App tài xế | Manual            | Vi phạm                                   |
| Manual            | Manual            | Vi phạm                                   |

---

### 13.6 Một chuyến có nhiều điểm vận hành

Tỷ lệ tuân thủ được tính ở cấp **điểm vận hành**, không phải chỉ ở cấp chuyến.

Ví dụ:

Một `MasterCode` có 5 điểm vận hành. Nếu 4 điểm tuân thủ và 1 điểm vi phạm:

* Số điểm tuân thủ = 4
* Tổng số điểm vận hành = 5
* Tỷ lệ tuân thủ của chuyến, nếu cần hiển thị ở cấp chuyến, là 80%

---

### 13.7 Khoảng thời gian lớn hơn 12 tháng

Dashboard không cho phép người dùng chọn khoảng thời gian lớn hơn 12 tháng.

Thông báo đề xuất:

> Vui lòng chọn khoảng thời gian không vượt quá 12 tháng.

---

## 14. MVP Recommendation

Với bản MVP, nên ưu tiên phạm vi:

* 3 scorecard chính
* 2 biểu đồ phân tích
* 1 bảng chi tiết dữ liệu
* Bộ lọc đầy đủ
* Khả năng export dữ liệu chi tiết

---

### 14.1 MVP Components

| STT | Thành phần                   | Mô tả                                                                                                                  |
| --- | ---------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| 1   | Scorecard tổng quan          | Tổng số chuyến vận hành, tổng số điểm vận hành, tỷ lệ tuân thủ                                                         |
| 2   | Mixed Chart theo nhà vận tải | Hiển thị số điểm tuân thủ, số điểm vi phạm và tỷ lệ tuân thủ theo nhà vận tải                                          |
| 3   | Mixed Chart theo thời gian   | Hiển thị xu hướng số điểm tuân thủ, số điểm vi phạm và tỷ lệ tuân thủ theo ngày/tuần/tháng                             |
| 4   | Bảng chi tiết dữ liệu        | Group theo `LocationCode`, hiển thị thông tin vào/ra điểm, thời gian load/unload, trạng thái tuân thủ và lý do vi phạm |

---

### 14.2 MVP Filters

MVP cần hỗ trợ đầy đủ các filter sau:

* Mã điểm
* Loại điểm
* Nhà vận tải
* Loại ngày
* Khoảng thời gian

---

### 14.3 MVP Output

Kết quả MVP cần cho phép người dùng:

* Xem tỷ lệ tuân thủ tổng thể.
* So sánh tỷ lệ tuân thủ theo nhà vận tải.
* Theo dõi xu hướng tỷ lệ tuân thủ theo ngày, tuần hoặc tháng.
* Kiểm tra từng dòng dữ liệu chi tiết.
* Xác định lý do vi phạm của từng điểm vận hành.
* Xuất dữ liệu chi tiết phục vụ đối soát và làm việc với nhà vận tải.