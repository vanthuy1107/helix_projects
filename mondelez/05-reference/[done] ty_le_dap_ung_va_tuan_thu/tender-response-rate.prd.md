# PRD — Dashboard Tỷ Lệ Đáp Ứng & Tuân Thủ

## Tỷ Lệ Đáp Ứng Chuyến Gửi Thầu

**Status:** Done
**Owner:** Thanh
**Last updated:** 06/05/2026 04:00 PM

---

## 1. Overview

Dashboard **Tỷ Lệ Đáp Ứng Chuyến Gửi Thầu** được xây dựng nhằm giám sát và đo lường mức độ đáp ứng của các chuyến gửi thầu so với thực tế vận hành trong hệ thống TMS.

Dashboard tập trung vào việc xác định một chuyến gửi thầu có được thực hiện đúng theo kế hoạch vận hành ban đầu hay không, dựa trên mối quan hệ giữa **ID chuyến gửi thầu — TenderMasterID** và **Mã chuyến vận hành — MasterCode**.

Một chuyến gửi thầu được xem là **được đáp ứng** khi đồng thời thỏa mãn các điều kiện sau:

* Một `TenderMasterID` chỉ được thực hiện bởi đúng một `MasterCode`.
* Một `MasterCode` chỉ gắn với đúng một `TenderMasterID`.

Dashboard giúp người dùng phát hiện các trường hợp không tuân thủ trong quá trình vận hành như:

* Nhiều chuyến gửi thầu bị gom vào cùng một xe vận hành.
* Một chuyến gửi thầu bị tách ra nhiều xe vận hành.
* Sự khác biệt giữa kế hoạch gửi thầu và thực tế vận hành.

Dashboard này hỗ trợ đội Điều phối vận tải, Carrier Management, Ban Lập kế hoạch vận hành và lãnh đạo chuỗi cung ứng đánh giá hiệu suất nhà vận tải, chất lượng lập kế hoạch vận chuyển và mức độ tuân thủ vận hành.

---

## 2. Problem Statement

Hiện tại, việc theo dõi mức độ đáp ứng giữa kế hoạch gửi thầu và thực tế vận hành còn khó khăn. Người dùng chưa có một dashboard trực quan để nhanh chóng đánh giá liệu các chuyến gửi thầu có được thực hiện đúng theo kế hoạch ban đầu hay không.

Trong thực tế vận hành, có thể phát sinh các tình huống như:

* Nhiều `TenderMasterID` được gom chung vào cùng một `MasterCode`.
* Một `TenderMasterID` bị tách ra thành nhiều `MasterCode`.
* Tổng số chuyến vận hành thực tế khác với tổng số chuyến gửi thầu ban đầu.
* Khó xác định nhà vận tải, kho hoặc khu vực nào thường xuyên xảy ra tình trạng gom/tách chuyến.

Các tình huống này làm giảm độ tin cậy của dữ liệu vận hành, ảnh hưởng đến khả năng đánh giá hiệu suất nhà vận tải và gây khó khăn trong việc kiểm soát chất lượng lập kế hoạch vận chuyển.

Các vấn đề chính bao gồm:

* Chưa có dashboard đo lường tự động tỷ lệ đáp ứng của chuyến gửi thầu.
* Khó phát hiện các chuyến gửi thầu bị gom hoặc tách trong thực tế vận hành.
* Thiếu khả năng phân tích tỷ lệ đáp ứng theo nhà vận tải, thời gian, kho lấy hàng và khu vực giao hàng.
* Khó có dữ liệu chi tiết để đối soát và làm việc với nhà vận tải.
* Chưa có cái nhìn tổng quan để hỗ trợ cải tiến quy trình lập kế hoạch và gửi thầu.

Do đó, cần có dashboard giúp giám sát tỷ lệ đáp ứng, xác định các trường hợp không đáp ứng và hỗ trợ đánh giá hiệu suất vận hành theo nhà vận tải, thời gian, kho và khu vực.

---

## 3. Target Users

### 3.1 Quản lý Điều phối vận tải / Logistics

Nhóm người dùng này cần theo dõi tình trạng thực hiện của các chuyến gửi thầu so với thực tế vận hành.

Nhu cầu chính:

* Theo dõi tỷ lệ chuyến gửi thầu được đáp ứng.
* Phát hiện các chuyến bị gom hoặc tách bất thường.
* Theo dõi tình hình vận hành theo kho, khu vực, nhà vận tải và thời gian.
* Kiểm tra dữ liệu chi tiết để xử lý các vấn đề vận hành phát sinh.

### 3.2 Quản lý Nhà vận tải — Carrier Management

Nhóm này sử dụng dashboard để đánh giá hiệu suất của từng nhà vận tải.

Nhu cầu chính:

* So sánh tỷ lệ đáp ứng giữa các nhà vận tải.
* Xác định nhà vận tải có tỷ lệ đáp ứng thấp.
* Làm cơ sở đánh giá Carrier Performance.
* Hỗ trợ quyết định duy trì, thay thế hoặc điều chỉnh hợp đồng nhà vận tải.

### 3.3 Ban Lập kế hoạch vận hành

Nhóm này cần đánh giá chất lượng lập kế hoạch vận chuyển và quy trình gửi thầu.

Nhu cầu chính:

* Xác định mức độ chênh lệch giữa kế hoạch gửi thầu và thực tế vận hành.
* Phân tích các trường hợp gom chuyến hoặc tách chuyến.
* Nhận diện các điểm chưa phù hợp trong kế hoạch vận tải.
* Cải thiện quy trình lập kế hoạch và gửi thầu.

### 3.4 Lãnh đạo Chuỗi cung ứng — Mondelēz International

Nhóm này cần cái nhìn tổng quan về hiệu suất vận hành ở cấp quản trị.

Nhu cầu chính:

* Theo dõi KPI tổng thể về tỷ lệ đáp ứng chuyến gửi thầu.
* Đánh giá xu hướng đáp ứng theo thời gian.
* Nhận diện nhà vận tải, kho hoặc khu vực cần ưu tiên cải thiện.
* Hỗ trợ ra quyết định về hiệu quả vận hành và chất lượng dịch vụ logistics.

---

## 4. Goals & Success Metrics

## 4.1 Goals

Dashboard cần đạt các mục tiêu sau:

1. Giúp người dùng theo dõi tỷ lệ đáp ứng của các chuyến gửi thầu một cách trực quan và gần real-time.
2. Phân biệt rõ các chuyến gửi thầu được đáp ứng và không được đáp ứng.
3. Phát hiện các trường hợp gom nhiều chuyến thầu vào cùng một xe vận hành.
4. Phát hiện các trường hợp tách một chuyến thầu ra nhiều xe vận hành.
5. Hỗ trợ phân tích tỷ lệ đáp ứng theo nhà vận tải, thời gian, kho lấy hàng và khu vực giao hàng.
6. Cung cấp dữ liệu chi tiết để người dùng kiểm tra nguyên nhân không đáp ứng.
7. Hỗ trợ quyết định liên quan đến Carrier Performance, hợp đồng nhà vận tải và cải tiến quy trình lập kế hoạch.

## 4.2 Success Metrics

Dashboard được xem là thành công nếu đáp ứng các tiêu chí sau:

| Nhóm tiêu chí             | Chỉ số thành công                                                                                                    |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Khả năng theo dõi         | Người dùng có thể xem tỷ lệ đáp ứng tổng thể trên dashboard                                                          |
| Khả năng phân tích        | Người dùng có thể phân tích tỷ lệ đáp ứng theo nhà vận tải, thời gian, kho và khu vực                                |
| Khả năng phát hiện vấn đề | Người dùng có thể xác định các chuyến không được đáp ứng trong bảng chi tiết                                         |
| Khả năng đối soát         | Dữ liệu chi tiết hiển thị đầy đủ thông tin `TenderMasterID`, `MasterCode`, nhà vận tải, kho, khu vực và loại đáp ứng |
| Tính kịp thời             | Dữ liệu được cập nhật real-time hoặc near real-time từ TMS                                                           |
| Phạm vi MVP               | Hoàn thành dashboard với scorecard, 2 mixed chart chính và 1 bảng chi tiết                                           |
| Khả năng sử dụng          | Dashboard dễ đọc, không quá tải thông tin và hỗ trợ xuất dữ liệu phục vụ đối soát                                    |

---

## 5. KPI Definitions

## 5.1 Tổng số chuyến gửi thầu

**Tổng số chuyến gửi thầu** là tổng số `TenderMasterID` hợp lệ thỏa mãn điều kiện dữ liệu đầu vào.

Điều kiện dữ liệu:

* `StatusOfDITOMaster = Đã hoàn thành`
* `TenderMasterID <> Null`
* `LogiXeGuiThau GroupOfVehicleName <> Null`
* `LogiXeVanHanh GroupOfVehicleName <> Null`
* `ServiceOfOrderName = Xuất bán`

Tổng số chuyến gửi thầu là mẫu số chính để tính tỷ lệ đáp ứng.

---

## 5.2 Tổng số chuyến vận hành

**Tổng số chuyến vận hành** là tổng số `MasterCode` hợp lệ phát sinh từ các chuyến gửi thầu thỏa mãn điều kiện dữ liệu đầu vào.

Chuyến vận hành được xác định theo `MasterCode`.

Ghi chú:

* Một `MasterCode` có thể gắn với một hoặc nhiều `TenderMasterID`.
* Một `TenderMasterID` có thể gắn với một hoặc nhiều `MasterCode`.
* Logic mapping giữa `TenderMasterID` và `MasterCode` là cơ sở để xác định chuyến gửi thầu được đáp ứng hay không được đáp ứng.

---

## 5.3 Chuyến gửi thầu được đáp ứng

Một chuyến gửi thầu được xem là **được đáp ứng** khi chuyến gửi thầu đó được vận hành đúng theo kế hoạch ban đầu.

Điều kiện xác định:

| Điều kiện                                    | Mô tả                                                  |
| -------------------------------------------- | ------------------------------------------------------ |
| Một `TenderMasterID` chỉ có một `MasterCode` | Chuyến gửi thầu không bị tách ra nhiều chuyến vận hành |
| Một `MasterCode` chỉ có một `TenderMasterID` | Chuyến vận hành không gom nhiều chuyến gửi thầu        |

Logic kiểm tra:

```text
COUNT(DISTINCT MasterCode) theo TenderMasterID = 1
AND COUNT(DISTINCT TenderMasterID) theo MasterCode = 1
```

Kết quả hiển thị trong cột:

> **Loại đáp ứng = Được đáp ứng**

---

## 5.4 Chuyến gửi thầu không được đáp ứng

Một chuyến gửi thầu được xem là **không được đáp ứng** nếu không thỏa mãn logic đáp ứng ở trên.

Các trường hợp không được đáp ứng bao gồm:

1. Nhiều `TenderMasterID` bị gom chung vào cùng một `MasterCode`.
2. Một `TenderMasterID` bị tách ra vận hành trên nhiều `MasterCode`.
3. Dữ liệu mapping giữa `TenderMasterID` và `MasterCode` không hợp lệ hoặc thiếu thông tin, nếu business xác nhận cần tính là không đáp ứng.

Kết quả hiển thị trong cột:

> **Loại đáp ứng = Không được đáp ứng**

---

## 5.5 Trường hợp gom nhiều chuyến thầu vào cùng một xe

Một chuyến vận hành được xem là có tình trạng **gom chuyến** khi nhiều `TenderMasterID` khác nhau được vận hành chung trong cùng một `MasterCode`.

Điều kiện xác định:

```text
COUNT(DISTINCT TenderMasterID) theo MasterCode > 1
```

Ví dụ:

| TenderMasterID | MasterCode |
| -------------- | ---------- |
| T001           | M001       |
| T002           | M001       |
| T003           | M001       |

Trong ví dụ trên, các chuyến thầu `T001`, `T002`, `T003` đều được vận hành chung trong cùng `MasterCode = M001`.

Kết quả:

* Các `TenderMasterID` liên quan được xem là **Không được đáp ứng**.
* Lý do không đáp ứng: **Gom nhiều TenderMasterID vào cùng một MasterCode**.

---

## 5.6 Trường hợp tách một chuyến thầu ra nhiều xe

Một chuyến gửi thầu được xem là có tình trạng **tách chuyến** khi một `TenderMasterID` được vận hành bởi nhiều `MasterCode`.

Điều kiện xác định:

```text
COUNT(DISTINCT MasterCode) theo TenderMasterID > 1
```

Ví dụ:

| TenderMasterID | MasterCode |
| -------------- | ---------- |
| T004           | M002       |
| T004           | M003       |

Trong ví dụ trên, `TenderMasterID = T004` được vận hành bởi hai chuyến khác nhau là `M002` và `M003`.

Kết quả:

* `TenderMasterID = T004` được xem là **Không được đáp ứng**.
* Lý do không đáp ứng: **Một TenderMasterID bị tách ra nhiều MasterCode**.

---

## 5.7 Tỷ lệ đáp ứng

**Tỷ lệ đáp ứng** là tỷ lệ phần trăm số chuyến gửi thầu được đáp ứng trên tổng số chuyến gửi thầu hợp lệ.

Công thức:

> Tỷ lệ đáp ứng = Số chuyến gửi thầu được đáp ứng / Tổng số chuyến gửi thầu × 100%

Trong đó:

| Thành phần                      | Mô tả                                                                     |
| ------------------------------- | ------------------------------------------------------------------------- |
| Số chuyến gửi thầu được đáp ứng | Tổng số `TenderMasterID` đạt điều kiện đáp ứng                            |
| Tổng số chuyến gửi thầu         | Tổng số `TenderMasterID` hợp lệ sau khi áp dụng điều kiện dữ liệu đầu vào |

Hiển thị dưới dạng phần trăm.

Ví dụ:

> Nếu có 100 chuyến gửi thầu, trong đó 85 chuyến được đáp ứng, tỷ lệ đáp ứng là 85%.

---

## 6. Functional Requirements

## 6.1 Scorecard tổng quan

Dashboard cần hiển thị các scorecard chính ở phần đầu trang.

Các scorecard bao gồm:

| Scorecard                             | Mô tả                                                     |
| ------------------------------------- | --------------------------------------------------------- |
| Tỷ lệ đáp ứng                         | Số chuyến gửi thầu được đáp ứng / Tổng số chuyến gửi thầu |
| Tổng số chuyến gửi thầu               | Tổng số `TenderMasterID` hợp lệ                           |
| Tổng số chuyến vận hành               | Tổng số `MasterCode` hợp lệ                               |
| Số chuyến gửi thầu được đáp ứng       | Tổng số `TenderMasterID` đạt điều kiện đáp ứng            |
| Số chuyến gửi thầu không được đáp ứng | Tổng số `TenderMasterID` không đạt điều kiện đáp ứng      |

Ghi chú: MVP có thể ưu tiên 5 scorecard chính:

1. Tỷ lệ đáp ứng
2. Tổng số chuyến gửi thầu
3. Tổng số chuyến vận hành
4. Số chuyến gửi thầu được đáp ứng
5. Số chuyến gửi thầu không được đáp ứng

---

## 6.2 Mixed Chart — Tỷ lệ đáp ứng theo Nhà vận tải

Dashboard cần có mixed chart hiển thị tỷ lệ đáp ứng theo từng nhà vận tải.

Yêu cầu:

* Trục X: Nhà vận tải.
* Cột: Số chuyến gửi thầu được đáp ứng và số chuyến gửi thầu không được đáp ứng.
* Đường: Tỷ lệ đáp ứng.
* Cho phép lọc theo kho lấy hàng, khu vực giao hàng, nhà vận tải, loại ngày và khoảng thời gian.
* Có thể sắp xếp theo tỷ lệ đáp ứng tăng dần hoặc giảm dần.

Mục đích:

* So sánh hiệu suất đáp ứng giữa các nhà vận tải.
* Xác định nhà vận tải có tỷ lệ đáp ứng thấp.
* Hỗ trợ đánh giá Carrier Performance.
* Làm cơ sở cho quyết định duy trì, thay thế hoặc điều chỉnh hợp đồng nhà vận tải.

---

## 6.3 Mixed Chart — Tỷ lệ đáp ứng theo thời gian

Dashboard cần có mixed chart thể hiện xu hướng tỷ lệ đáp ứng theo thời gian.

Yêu cầu:

* Cho phép xem theo ngày, tuần hoặc tháng.
* Trục X: Mốc thời gian.
* Cột: Số chuyến gửi thầu được đáp ứng và số chuyến gửi thầu không được đáp ứng.
* Đường: Tỷ lệ đáp ứng.
* Mặc định sử dụng tháng hiện tại.
* Loại ngày mặc định là ATA.

Mục đích:

* Theo dõi xu hướng tỷ lệ đáp ứng tăng hoặc giảm.
* Phát hiện các giai đoạn có tỷ lệ đáp ứng thấp.
* Đánh giá tác động của các thay đổi vận hành hoặc thay đổi nhà vận tải.
* Hỗ trợ theo dõi hiệu quả cải tiến quy trình lập kế hoạch và gửi thầu.

---

## 6.4 Phân tích theo Kho lấy hàng

Dashboard cần hỗ trợ phân tích tỷ lệ đáp ứng theo **Kho lấy hàng**.

Yêu cầu:

* Bộ lọc kho lấy hàng dạng multi-select.
* Danh sách kho lấy hàng được lấy từ hệ thống.
* Có thể hiển thị ranking các kho có tỷ lệ đáp ứng thấp hoặc cao.
* Dữ liệu kho cần đồng bộ với các view nguồn trong TMS.

Mục đích:

* Xác định kho nào thường xuyên có tình trạng gom/tách chuyến.
* Phát hiện điểm xuất phát có mức độ đáp ứng thấp.
* Hỗ trợ điều tra vấn đề vận hành theo điểm xuất phát.

---

## 6.5 Phân tích theo Khu vực giao hàng

Dashboard cần hỗ trợ phân tích tỷ lệ đáp ứng theo **Khu vực giao hàng**.

Yêu cầu:

* Bộ lọc khu vực giao hàng dạng multi-select.
* Danh sách khu vực lấy từ hệ thống.
* Có thể hiển thị tỷ lệ đáp ứng theo từng khu vực.
* Cho phép kết hợp filter khu vực với nhà vận tải, kho và khoảng thời gian.

Mục đích:

* Xác định khu vực có nhiều trường hợp gom/tách chuyến.
* Hỗ trợ tối ưu kế hoạch vận chuyển theo vùng.
* Nhận diện khu vực có rủi ro vận hành hoặc chất lượng lập kế hoạch thấp.

---

## 6.6 Bảng chi tiết dữ liệu

Dashboard cần có bảng chi tiết dữ liệu, group theo **Mã chuyến vận hành — MasterCode**.

Bảng cần hiển thị các thông tin chính:

| Trường dữ liệu                     | Mô tả                                            |
| ---------------------------------- | ------------------------------------------------ |
| MasterCode                         | Mã chuyến vận hành                               |
| TenderMasterID                     | ID chuyến gửi thầu                               |
| Nhà vận tải                        | Nhà xe thực hiện                                 |
| Kho lấy hàng                       | Kho xuất phát                                    |
| Khu vực giao hàng                  | Khu vực nhận hàng                                |
| Ngày gửi thầu                      | Ngày tạo/gửi thầu                                |
| ETA                                | Thời gian dự kiến đến                            |
| ATA                                | Thời gian thực tế đến                            |
| Trạng thái vận hành                | Trạng thái của chuyến                            |
| Loại đáp ứng                       | Được đáp ứng / Không được đáp ứng                |
| Lý do không đáp ứng                | Gom nhiều TenderMasterID / Tách nhiều MasterCode |
| Số TenderMasterID trong MasterCode | Dùng để phát hiện gom chuyến                     |
| Số MasterCode của TenderMasterID   | Dùng để phát hiện tách chuyến                    |

Mục đích:

* Cho phép người dùng kiểm tra dữ liệu chi tiết theo từng chuyến vận hành.
* Hỗ trợ truy vết các trường hợp không đáp ứng.
* Giúp đối soát dữ liệu giữa kế hoạch gửi thầu và thực tế vận hành.
* Làm cơ sở xuất báo cáo và làm việc với nhà vận tải.

---

## 6.7 Xuất báo cáo

Người dùng Full Access cần có khả năng xuất dữ liệu từ dashboard.

Yêu cầu:

* Xuất dữ liệu bảng chi tiết.
* Định dạng đề xuất: Excel hoặc CSV.
* Dữ liệu xuất ra phải tuân theo filter đang được áp dụng trên dashboard.
* File xuất cần bao gồm cột **Loại đáp ứng** và **Lý do không đáp ứng**.
* File xuất cần bao gồm các cột hỗ trợ kiểm tra mapping giữa `TenderMasterID` và `MasterCode`.

---

## 7. Filters

Dashboard cần hỗ trợ các bộ lọc sau:

| Tên bộ lọc        | Loại bộ lọc  | Tiêu chí lọc              | Ghi chú                                  |
| ----------------- | ------------ | ------------------------- | ---------------------------------------- |
| Kho lấy hàng      | Multi-select | Danh sách kho từ hệ thống | Cho phép chọn một hoặc nhiều kho         |
| Khu vực giao hàng | Multi-select | Danh sách khu vực         | Cho phép chọn một hoặc nhiều khu vực     |
| Nhà vận tải       | Multi-select | Danh sách nhà xe          | Cho phép chọn một hoặc nhiều nhà vận tải |
| Loại ngày         | Combo box    | Ngày gửi thầu, ETA, ATA   | Mặc định: ATA                            |
| Khoảng thời gian  | Date range   | Từ ngày đến ngày          | Tối đa 12 tháng, mặc định tháng hiện tại |

---

## 7.1 Quy tắc filter thời gian

* Người dùng chỉ được chọn khoảng thời gian tối đa 12 tháng.
* Mặc định dashboard hiển thị dữ liệu của tháng hiện tại.
* Loại ngày mặc định là **ATA**.
* Khi người dùng đổi loại ngày, toàn bộ dashboard cần tính toán lại theo loại ngày được chọn.
* Nếu người dùng chọn khoảng thời gian vượt quá 12 tháng, hệ thống cần hiển thị cảnh báo.

Thông báo đề xuất:

> Vui lòng chọn khoảng thời gian không vượt quá 12 tháng.

---

## 8. Data Requirements

## 8.1 Nguồn dữ liệu

Dữ liệu được lấy từ các view trong hệ thống TMS:

1. **View Giám sát - Phân phối**
2. **View Điều phối - Gửi thầu chi tiết**

---

## 8.2 Điều kiện dữ liệu đầu vào

Chỉ các bản ghi thỏa mãn đầy đủ các điều kiện sau mới được đưa vào dashboard:

| Trường dữ liệu                   | Điều kiện     |
| -------------------------------- | ------------- |
| StatusOfDITOMaster               | Đã hoàn thành |
| TenderMasterID                   | Không null    |
| LogiXeGuiThau GroupOfVehicleName | Không null    |
| LogiXeVanHanh GroupOfVehicleName | Không null    |
| ServiceOfOrderName               | Xuất bán      |

---

## 8.3 Các trường dữ liệu chính

Bảng dữ liệu chi tiết cần có các trường sau:

| Trường dữ liệu                     | Mô tả                                           |
| ---------------------------------- | ----------------------------------------------- |
| MasterCode                         | Mã chuyến vận hành                              |
| TenderMasterID                     | ID chuyến gửi thầu                              |
| VendorShortName / Nhà vận tải      | Nhà xe thực hiện                                |
| Kho lấy hàng                       | Kho xuất phát                                   |
| Khu vực giao hàng                  | Khu vực nhận hàng                               |
| Ngày gửi thầu                      | Ngày tạo hoặc gửi thầu                          |
| ETA                                | Thời gian dự kiến                               |
| ATA                                | Thời gian thực tế                               |
| StatusOfDITOMaster                 | Trạng thái chuyến vận hành                      |
| ServiceOfOrderName                 | Loại dịch vụ                                    |
| LogiXeGuiThau GroupOfVehicleName   | Nhóm xe gửi thầu                                |
| LogiXeVanHanh GroupOfVehicleName   | Nhóm xe vận hành                                |
| Loại đáp ứng                       | Được đáp ứng / Không được đáp ứng               |
| Lý do không đáp ứng                | Gom chuyến / Tách chuyến / Dữ liệu không hợp lệ |
| Số TenderMasterID trong MasterCode | Chỉ số dùng để phát hiện gom chuyến             |
| Số MasterCode của TenderMasterID   | Chỉ số dùng để phát hiện tách chuyến            |

---

## 8.4 Logic xác định đáp ứng

Hệ thống cần tính trạng thái đáp ứng ở cấp **chuyến gửi thầu — TenderMasterID**.

Một chuyến gửi thầu được xem là **được đáp ứng** nếu:

```text
COUNT(DISTINCT MasterCode) theo TenderMasterID = 1
AND COUNT(DISTINCT TenderMasterID) theo MasterCode = 1
```

Một chuyến gửi thầu được xem là **không được đáp ứng** nếu:

```text
COUNT(DISTINCT MasterCode) theo TenderMasterID > 1
OR COUNT(DISTINCT TenderMasterID) theo MasterCode > 1
```

Phân loại lý do không đáp ứng:

| Điều kiện                                            | Lý do không đáp ứng                                    |
| ---------------------------------------------------- | ------------------------------------------------------ |
| `COUNT(DISTINCT TenderMasterID) theo MasterCode > 1` | Gom nhiều TenderMasterID vào cùng một MasterCode       |
| `COUNT(DISTINCT MasterCode) theo TenderMasterID > 1` | Một TenderMasterID bị tách ra nhiều MasterCode         |
| Thiếu `MasterCode` hoặc dữ liệu mapping không hợp lệ | Dữ liệu thiếu hoặc không hợp lệ, cần business xác nhận |

---

## 8.5 Tần suất cập nhật

Dữ liệu cần được cập nhật **real-time hoặc near real-time** từ hệ thống TMS.

Trong trường hợp không thể real-time hoàn toàn, dashboard cần hiển thị thời điểm cập nhật dữ liệu gần nhất.

Ví dụ:

> Last updated: 10:30 AM, 15 Jan 2026

---

## 9. Dashboard Layout

Dashboard MVP gồm các thành phần chính sau:

* Khu vực filter
* Khu vực scorecard
* Mixed Chart tỷ lệ đáp ứng theo nhà vận tải
* Mixed Chart tỷ lệ đáp ứng theo thời gian
* Bảng chi tiết dữ liệu

---

## 9.1 Khu vực filter

Đặt ở đầu dashboard hoặc panel bên trái.

Bao gồm:

* Kho lấy hàng
* Khu vực giao hàng
* Nhà vận tải
* Loại ngày
* Khoảng thời gian

---

## 9.2 Khu vực scorecard

Hiển thị các KPI tổng quan:

1. Tỷ lệ đáp ứng
2. Tổng số chuyến gửi thầu
3. Tổng số chuyến vận hành
4. Số chuyến gửi thầu được đáp ứng
5. Số chuyến gửi thầu không được đáp ứng

Ghi chú: Nếu cần giữ đúng phạm vi MVP tối giản, có thể ưu tiên 3 scorecard chính:

1. Tỷ lệ đáp ứng
2. Tổng số chuyến gửi thầu
3. Tổng số chuyến vận hành

---

## 9.3 Khu vực biểu đồ phân tích

Các chart đề xuất:

| STT | Chart                          | Loại biểu đồ | Mục đích                               |
| --- | ------------------------------ | ------------ | -------------------------------------- |
| 1   | Scorecard tổng quan            | Scorecard    | Hiển thị KPI chính                     |
| 2   | Tỷ lệ đáp ứng theo nhà vận tải | Mixed Chart  | So sánh Carrier Performance            |
| 3   | Tỷ lệ đáp ứng theo thời gian   | Mixed Chart  | Theo dõi xu hướng theo ngày/tuần/tháng |

---

## 9.4 Khu vực bảng dữ liệu

Bảng chi tiết đặt ở cuối dashboard.

Yêu cầu:

* Group theo `MasterCode`.
* Hiển thị dữ liệu mapping giữa `MasterCode` và `TenderMasterID`.
* Có thể search theo `MasterCode`, `TenderMasterID`, nhà vận tải, kho và khu vực.
* Có thể sort theo ngày, nhà vận tải, loại đáp ứng và lý do không đáp ứng.
* Có thể export dữ liệu.
* Có thể hiển thị rõ các trường hợp gom chuyến và tách chuyến.

---

## 10. Access & Permissions

## 10.1 Full Access

Người dùng có quyền Full Access được phép:

* Xem tất cả dữ liệu.
* Sử dụng tất cả filter.
* Xem toàn bộ biểu đồ và bảng chi tiết.
* Xuất báo cáo.
* Truy cập dữ liệu của tất cả nhà vận tải, kho và khu vực.

Hiện tại PRD chỉ định nghĩa quyền **Full Access**. Các quyền giới hạn theo role, khu vực, kho hoặc nhà vận tải chưa nằm trong phạm vi bản MVP nếu chưa có yêu cầu bổ sung.

---

## 11. In Scope

Các hạng mục nằm trong phạm vi dashboard:

1. Theo dõi tỷ lệ đáp ứng của chuyến gửi thầu.
2. Tính toán số chuyến gửi thầu được đáp ứng và không được đáp ứng.
3. Xác định trạng thái Được đáp ứng / Không được đáp ứng ở cấp `TenderMasterID`.
4. Phát hiện trường hợp nhiều `TenderMasterID` bị gom vào cùng một `MasterCode`.
5. Phát hiện trường hợp một `TenderMasterID` bị tách ra nhiều `MasterCode`.
6. Phân tích tỷ lệ đáp ứng theo nhà vận tải.
7. Phân tích tỷ lệ đáp ứng theo thời gian.
8. Phân tích theo kho lấy hàng và khu vực giao hàng.
9. Hiển thị bảng chi tiết dữ liệu group theo `MasterCode`.
10. Hỗ trợ filter theo kho lấy hàng, khu vực giao hàng, nhà vận tải, loại ngày và khoảng thời gian.
11. Hỗ trợ xuất báo cáo cho người dùng Full Access.
12. Cập nhật dữ liệu real-time hoặc near real-time từ TMS.

---

## 12. Out of Scope

Các hạng mục không thuộc phạm vi dashboard này:

1. Tỷ lệ tuân thủ chuyến vận hành tại điểm, vì đây là dashboard riêng.
2. Phân tích chi phí vận chuyển.
3. Theo dõi hiệu suất xe chi tiết như nhiên liệu, bảo trì, tải trọng hoặc năng suất tài xế.
4. Dự báo nhu cầu thầu hoặc forecasting.
5. Tự động khuyến nghị thay thế nhà vận tải.
6. Tự động gửi cảnh báo hoặc reminder.
7. Tự động tính penalty hoặc thưởng/phạt nhà vận tải.
8. Phân tích nguyên nhân vận hành chuyên sâu ngoài logic gom/tách chuyến.
9. Custom dashboard builder cho người dùng tự thiết kế dashboard.

---

## 13. Edge Cases & Business Rules

## 13.1 TenderMasterID null

Các bản ghi có `TenderMasterID = Null` không được đưa vào dashboard.

Lý do:

* Không xác định được chuyến gửi thầu.
* Không thể tính mapping giữa chuyến gửi thầu và chuyến vận hành.

---

## 13.2 MasterCode null

Các bản ghi không có `MasterCode` hoặc không có thông tin xe vận hành hợp lệ không được đưa vào phần tính tỷ lệ đáp ứng, trừ khi business xác nhận cần tính là không đáp ứng.

Cần xác nhận business rule:

* Loại khỏi toàn bộ dashboard, hoặc
* Đưa vào nhóm **Dữ liệu thiếu / không hợp lệ**, hoặc
* Tính là **Không được đáp ứng**.

Đề xuất cho dashboard vận hành: nếu chuyến đã hoàn thành nhưng thiếu `MasterCode`, nên gắn trạng thái **Không được đáp ứng** và flag lý do **Thiếu MasterCode**.

---

## 13.3 Một TenderMasterID có nhiều dòng chi tiết

Nếu một `TenderMasterID` có nhiều dòng chi tiết nhưng tất cả các dòng đều thuộc cùng một `MasterCode`, chuyến gửi thầu vẫn được xem là **Được đáp ứng**, với điều kiện `MasterCode` đó không gom thêm `TenderMasterID` khác.

Ví dụ:

| TenderMasterID | MasterCode | Kết quả      |
| -------------- | ---------- | ------------ |
| T001           | M001       | Được đáp ứng |
| T001           | M001       | Được đáp ứng |
| T001           | M001       | Được đáp ứng |

Điều kiện bổ sung:

```text
COUNT(DISTINCT MasterCode) theo TenderMasterID = 1
AND COUNT(DISTINCT TenderMasterID) theo MasterCode = 1
```

---

## 13.4 Một MasterCode có nhiều TenderMasterID

Nếu một `MasterCode` chứa nhiều `TenderMasterID`, các chuyến thầu liên quan được xem là **Không được đáp ứng** do bị gom chuyến.

Ví dụ:

| TenderMasterID | MasterCode | Kết quả            |
| -------------- | ---------- | ------------------ |
| T001           | M001       | Không được đáp ứng |
| T002           | M001       | Không được đáp ứng |

Lý do không đáp ứng:

> Gom nhiều TenderMasterID vào cùng một MasterCode

---

## 13.5 Một TenderMasterID có nhiều MasterCode

Nếu một `TenderMasterID` xuất hiện trên nhiều `MasterCode`, chuyến thầu đó được xem là **Không được đáp ứng** do bị tách chuyến.

Ví dụ:

| TenderMasterID | MasterCode | Kết quả            |
| -------------- | ---------- | ------------------ |
| T003           | M002       | Không được đáp ứng |
| T003           | M003       | Không được đáp ứng |

Lý do không đáp ứng:

> Một TenderMasterID bị tách ra nhiều MasterCode

---

## 13.6 Vừa gom chuyến vừa tách chuyến

Trong một số trường hợp dữ liệu phức tạp, một `TenderMasterID` hoặc `MasterCode` có thể vừa liên quan đến logic gom chuyến vừa liên quan đến logic tách chuyến.

Ví dụ:

| TenderMasterID | MasterCode |
| -------------- | ---------- |
| T001           | M001       |
| T001           | M002       |
| T002           | M002       |

Trong ví dụ trên:

* `T001` bị tách ra nhiều `MasterCode`.
* `M002` gom nhiều `TenderMasterID`.

Đề xuất xử lý:

* Gắn trạng thái **Không được đáp ứng**.
* Lý do không đáp ứng: **Gom chuyến và tách chuyến**.
* Bảng chi tiết cần hiển thị đủ chỉ số:

  * Số `TenderMasterID` trong `MasterCode`
  * Số `MasterCode` của `TenderMasterID`

---

## 13.7 Khoảng thời gian lớn hơn 12 tháng

Dashboard không cho phép người dùng chọn khoảng thời gian lớn hơn 12 tháng.

Thông báo đề xuất:

> Vui lòng chọn khoảng thời gian không vượt quá 12 tháng.

---

## 14. MVP Recommendation

Với bản MVP, nên ưu tiên phạm vi tập trung vào scorecard, 2 mixed chart chính và 1 bảng chi tiết.

---

## 14.1 MVP Components

| STT | Thành phần                   | Mô tả                                                                                                                 |
| --- | ---------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| 1   | Scorecard tổng quan          | Tỷ lệ đáp ứng, tổng số chuyến gửi thầu, tổng số chuyến vận hành, số chuyến được đáp ứng, số chuyến không được đáp ứng |
| 2   | Mixed Chart theo nhà vận tải | Hiển thị tỷ lệ đáp ứng, số chuyến được đáp ứng và số chuyến không được đáp ứng theo nhà vận tải                       |
| 3   | Mixed Chart theo thời gian   | Hiển thị xu hướng tỷ lệ đáp ứng theo ngày/tuần/tháng                                                                  |
| 4   | Bảng chi tiết dữ liệu        | Group theo `MasterCode`, hiển thị mapping `TenderMasterID` - `MasterCode`, loại đáp ứng và lý do không đáp ứng        |
| 5   | Export dữ liệu               | Xuất dữ liệu bảng chi tiết theo filter đang áp dụng                                                                   |

---

## 14.2 MVP Filters

MVP cần hỗ trợ đầy đủ các filter sau:

* Kho lấy hàng
* Khu vực giao hàng
* Nhà vận tải
* Loại ngày
* Khoảng thời gian

---

## 14.3 MVP Output

Kết quả MVP cần cho phép người dùng:

* Xem tỷ lệ đáp ứng tổng thể.
* Xem tổng số chuyến gửi thầu và tổng số chuyến vận hành.
* Xem số chuyến gửi thầu được đáp ứng và không được đáp ứng.
* So sánh tỷ lệ đáp ứng theo nhà vận tải.
* Theo dõi xu hướng tỷ lệ đáp ứng theo thời gian.
* Xác định các trường hợp gom nhiều chuyến thầu vào cùng một xe.
* Xác định các trường hợp tách một chuyến thầu ra nhiều xe.
* Kiểm tra từng dòng dữ liệu chi tiết.
* Xuất dữ liệu chi tiết phục vụ đối soát và làm việc với nhà vận tải.