# BẢN ĐẶC TẢ GIẢI PHÁP TOBE — DASHBOARD ĐÁNH GIÁ ĐỘ TIN CẬY THUẬT TOÁN VRP

> **Dự án:** Hệ thống Quản trị & Phân tích Dữ liệu Vận tải (TMS Analytics)
> **Khách hàng (Tenant):** Panasonic Việt Nam
> **Đơn vị triển khai:** Công ty Cổ phần Giải pháp Chuỗi Cung ứng Smartlog (Smartlog)
> **Mã phân hệ:** `psv-accuracy-vrp`
> **Nguồn dữ liệu tích hợp:** ClickHouse cluster `analytics_workspace.mv_psv_main` (Đồng bộ từ `psv_target FINAL`)
> **Trạng thái tài liệu:** KHUNG TOBE ĐỀ XUẤT (Dùng để tổng hợp dữ liệu từ PRD, Spec và Wireframe)

---

## MỤC LỤC TỔNG THỂ (TABLE OF CONTENTS)

- **I. PHẠM VI & MỤC TIÊU GIẢI PHÁP TOBE**
  - 1. Bối cảnh vận hành hệ thống Panasonic TMS và module PSV
  - 2. Đối tượng sử dụng & Mục tiêu cốt lõi (Strategic / Tactical / Operational)
  - 3. Mô hình luồng dữ liệu tổng thể TOBE (VRP Auto-planning -> Manual Adjustment)
- **II. NGUYÊN TẮC THIẾT LẬP BỘ CHỈ SỐ ĐO LƯỜNG (KPI BUSINESS RULES)**
  - 1. Chỉ số % Accuracy (Độ chính xác thuật toán VRP)
  - 2. Chỉ số % Violation Rate (Tỷ lệ vi phạm ràng buộc sau can thiệp)
  - 3. Chỉ số Cost/CBM Drift Trend (Biến động chi phí trên mỗi khối hàng)
  - 4. Ngưỡng phân cấp cảnh báo hệ thống (RAG Thresholds Configuration)
- **III. ĐẶC TẢ TÍNH NĂNG & GIAO DIỆN HỆ THỐNG DASHBOARD (5-TAB LAYOUT)**
  - 1. Phân hệ Tổng quan (Tab 1: Overview)
  - 2. Phân hệ Độ tin cậy vận hành (Tab 2: Reliability)
  - 3. Phân hệ Giám sát Nhà thầu (Tab 3: Vendor & Carrier)
  - 4. Phân hệ Biến động Chi phí (Tab 4: Cost Variance)
  - 5. Phân hệ Khai thác & Xuất dữ liệu (Tab 5: Data Explorer)
- **IV. ĐẶC TẢ CẤU TRÚC DỮ LIỆU THÔ (GRID DỮ LIỆU & QUY TẮC TỪNG CỘT)**
  - 1. Bảng T-CONSTRAINT: Nhật ký Trip vi phạm ràng buộc (Tab 2)
  - 2. Bảng T-VENDOR: Chi tiết hoán đổi Nhà thầu và Chi phí chênh lệch (Tab 3)
  - 3. Bảng T-ZONE-COST: Tổng hợp chênh lệch chi phí theo Vùng (Tab 4)
  - 4. Bảng T-MASTER: Toàn bộ dữ liệu lịch sử các chuyến xe (Tab 5)
  - 5. Bảng T-PLANNER: Đánh giá hiệu suất xử lý dữ liệu của Planner (Tab 5)
- **V. QUY TẮC TƯƠNG TÁC, RÀNG BUỘC KỸ THUẬT & EMPTY STATES**
  - 1. Nguyên tắc xếp chồng bộ lọc hệ thống (Filter Cascade Rules)
  - 2. Kịch bản hiển thị khi dữ liệu trống (Empty States & Error Handling Map)
  - 3. Tiêu chuẩn Xuất dữ liệu & Định dạng tệp tin (Bulk Export Mechanics)
- **VI. PHƯƠNG ÁN KHẮC PHỤC THIẾU HỤT DỮ LIỆU HỆ THỐNG (DATA GAPs & FALLBACKS)**
  - 1. Đồng bộ cấu trúc dữ liệu Gốc của thuật toán (GAP Q1 - Auto Baseline)
  - 2. Đồng bộ danh mục Phân vùng Logistics của Panasonic (GAP Q2 - Zone Master Mapping)
  - 3. Thiết lập kết nối dòng thời gian thao tác Planner (GAP Q3/Q4 - Event Log Tracking)
- **VII. TIÊU CHÍ KIỂM TOÁN SỐ LIỆU & NGHIỆM THU DỰ ÁN (AUDIT GATE)**

---

## CHƯƠNG CHI TIẾT (DETAILED CONTENT TEMPLATE)

### I. PHẠM VI & MỤC TIÊU GIẢI PHÁP TOBE

#### 1. Bối cảnh vận hành hệ thống Panasonic TMS và module PSV
* **Mô tả hiện trạng (AS-IS):** Quy trình điều phối tự động qua thuật toán OPS_Optimizer (VRP). Tuy nhiên, sau khi thuật toán đề xuất, Planner tiến hành can thiệp thủ công (Manual Adjust) để thay đổi xe, nhà thầu, hoặc lộ trình nhưng không có công cụ giám sát tập trung.
* **Mục tiêu tương lai (TOBE):** Dashboard đóng vai trò định lượng hóa toàn bộ hành vi can thiệp của Planner, làm rõ lý do tại sao thuật toán bị ghi đè, đo lường độ lệch chi phí tài chính và kiểm soát chất lượng vận hành cuối cùng.

#### 2. Đối tượng sử dụng & Mục tiêu cốt lõi (Strategic / Tactical / Operational)
Tài liệu Word cuối cùng cần bóc tách chi tiết phân quyền và góc nhìn cho 4 nhóm đối tượng chính của Panasonic:
* **Strategic (BOD + Operations Director):** Đánh giá chỉ số ROI tổng thể để quyết định mở rộng module sang các site/nhà máy khác.
* **Tactical (Planning Lead):** Chẩn đoán các vùng (Zone) thuật toán hoạt động kém, xác định các ràng buộc vận hành (Constraints) hay bị vi phạm để cấu hình lại core thuật toán.
* **Operational (Procurement Lead):** Theo dõi xu hướng hoán đổi nhà thầu (Vendor Swap), kiểm soát lãng phí ngân sách vận tải (Overspend).
* **Operational (Planner):** Tự giám sát xem phương án sau khi điều chỉnh có còn vi phạm lỗi xếp hàng hay giao nhận không.

#### 3. Mô hình luồng dữ liệu tổng thể TOBE (VRP Auto-planning -> Manual Adjustment)
* [Claude hướng dẫn: Hãy vẽ hoặc mô tả luồng di chuyển của dữ liệu từ khi sinh phương án tự động trong bảng `OPS_Optimizer`, lưu vết sửa đổi của Planner, đẩy vào Materialized View `mv_psv_main` với tần suất refresh 1 giờ một lần].

---

### II. NGUYÊN TẮC THIẾT LẬP BỘ CHỈ SỐ ĐO LƯỜNG (KPI BUSINESS RULES)

#### 1. Chỉ số % Accuracy (Độ chính xác thuật toán VRP)
* **Khái niệm & Ý nghĩa:** Tỷ lệ phần trăm các chuyến xe được giữ nguyên bản hoặc có chỉnh sửa nhưng không tạo ra vi phạm mới.
* **Công thức toán học (Nghiệp vụ):** $$\% 	ext{Accuracy} = rac{	ext{Số chuyến không thay đổi (No Change)} + 	ext{Số chuyến sửa đổi nhưng vẫn vi phạm (Change with Violation)}}{	ext{Tổng số chuyến xe được tối ưu hóa tự động}} 	imes 100$$
* **Quy tắc hệ thống (System Logic):** Áp dụng logic đếm số lượng `tracking_id` duy nhất (`uniqExact`). Chi tiết câu lệnh SQL canonical được trích xuất từ tài liệu Spec mục 4.1 để áp dụng vào cấu hình hệ thống.
* **Lưu ý vận hành (Caveat Q7/Q8):** Giải thích rõ cho Panasonic vì sao chuyến sửa đổi nhưng vẫn vi phạm lại được tính là "chính xác" (Do thuật toán ban đầu đã phát hiện ra vi phạm đó nhưng Planner không thể tối ưu hơn).

#### 2. Chỉ số % Violation Rate (Tỷ lệ vi phạm ràng buộc sau can thiệp)
* **Khái niệm & Ý nghĩa:** Tỷ lệ các chuyến xe cuối cùng gửi đi cho nhà thầu vẫn còn tồn tại ít nhất một lỗi vi phạm ràng buộc vận hành.
* **Công thức toán học:**
  $$\% 	ext{Violation Rate} = rac{	ext{Số chuyến có trường constraint\_name } 
eq 	ext{ trống}}{	ext{Tổng số chuyến xe thực tế phát sinh}} 	imes 100$$

#### 3. Chỉ số Cost/CBM Drift Trend (Biến động chi phí trên mỗi khối hàng)
* **Khái niệm & Ý nghĩa:** Đo lường phần trăm chênh lệch chi phí trên mỗi đơn vị khối (CBM) giữa phương án tối ưu của máy (Auto CPC) và phương án thực tế sau khi Planner điều chỉnh (Adjusted CPC).
* **Công thức tính toán từng ngày:**
  $$\% 	ext{Drift Cost/CBM} = rac{	ext{CPC Adjusted} - 	ext{CPC Auto}}{	ext{CPC Auto}} 	imes 100$$
  *Trong đó:* $	ext{CPC} = rac{	ext{Tổng chi phí (Total Cost)}}{	ext{Tổng thể tích hàng hóa (Total CBM)}}$

#### 4. Ngưỡng phân cấp cảnh báo hệ thống (RAG Thresholds Configuration)
Thống nhất áp dụng quy tắc mã hóa màu sắc đèn giao thông (Red-Amber-Green) theo tiêu chuẩn đề xuất của Panasonic tại mục PRD 8.Q5:
* **Đối với chỉ số % Accuracy:** Đạt trạng thái Xanh (Green) nếu $\ge 80\%$; Vàng (Yellow) nếu từ $60\% - 80\%$; Đỏ (Red) nếu dưới $60\%$.
* **Đối với chỉ số % Violation Rate:** Đạt trạng thái Xanh (Green) nếu $< 10\%$; Vàng (Yellow) nếu từ $10\% - 25\%$; Đỏ (Red) nếu $\ge 25\%$.

---

### III. ĐẶC TẢ TÍNH NĂNG & GIAO DIỆN HỆ THỐNG DASHBOARD (5-TAB LAYOUT)

#### 1. Phân hệ Tổng quan (Tab 1: Overview)
* **Mục đích:** Cung cấp góc nhìn Snapshot nhanh gọn trong đúng 1 khung hình (Viewport, ước tính chiều cao ~1,100px) dành cho Ban giám đốc (BOD).
* **Bố cục các thành phần hiển thị (Layout Structure):**
  * *Tầng L1 (Hero KPIs):* Hiển thị thẻ chỉ số lớn cho % Accuracy (A1) và % Violation Rate (B1), tích hợp biểu đồ Sparkline xu hướng 14 ngày gần nhất.
  * *Tầng L2 (Chẩn đoán nhanh):* Biểu đồ thanh ngang so sánh tỷ lệ Accuracy theo từng Vùng (A2) và Tỷ lệ vi phạm theo Vùng (B2). Giới hạn hiển thị Top 5 vùng nghiêm trọng nhất.
  * *Tầng L3 (Xu hướng dòng thời gian):* Đường đồ thị Daily xu hướng biến động chi phí Cost/CBM Drift (A3) và Xu hướng vi phạm hàng ngày (B4).
  * *Tầng L4 (Footer hiệu suất):* Thẻ đo lường thời gian xử lý trung bình của Planner (A4).
* **Bảng điều khiển bất thường (Exception Highlight Panel):** Tự động kích hoạt cảnh báo lên góc trên cùng của Tab 1 nếu phát hiện bất kỳ vùng nào có độ chính xác rơi xuống dưới $60\%$, hoặc nhà thầu có chi phí tăng đột biến $> 15\%$. Tối đa hiển thị 9 dòng cảnh báo.

#### 2. Phân hệ Độ tin cậy vận hành (Tab 2: Reliability)
* **Mục đích:** Phục vụ riêng cho Planning Lead điều tra lý do tại sao hệ thống tối ưu hóa thất bại. Chiều cao thiết kế cuộn dài ~1,800px.
* **Chi tiết biểu đồ:**
  * *A2 & B2 (Mở rộng):* Hiển thị danh sách toàn bộ các Zone vận hành (Không giới hạn ở Top 5), sắp xếp giảm dần theo hiệu suất.
  * *B3 (Constraint Pareto Chart):* Biểu đồ Pareto cột đứng phân tích số lượng vi phạm theo từng danh mục ràng buộc (Ví dụ: Fishbone, 3D_loading, Break_time, PO_expired). Hiển thị chi tiết Top 20 và gom phần còn lại vào nhóm "Others".
* **Tương tác Drill-down:** Khi click vào một cột ràng buộc trên biểu đồ Pareto, hệ thống sẽ mở một ngăn kéo giao diện bên phải (Right Drawer) hiển thị danh sách toàn bộ các mã chuyến xe liên quan.

#### 3. Phân hệ Giám sát Nhà thầu (Tab 3: Vendor & Carrier)
* **Mục đích:** Giúp bộ phận Thu mua (Procurement Lead) nắm bắt hành vi đổi nhà thầu của nhân viên và tác động tài chính.
* **Chi tiết biểu đồ:**
  * *C1 (Trip Change Matrix):* Ma trận luồng thay đổi nhà thầu dạng Sankey Diagram. Làm rõ luồng dịch chuyển từ Nhà thầu gốc (Auto) sang Nhà thầu thực tế (Adjusted). Tích hợp nút chuyển đổi nhanh sang dạng Bản đồ nhiệt (Heatmap).
  * *C2 (Vendor Allocation Ratio):* Biểu đồ dạng Tạ xích (Dumbbell Chart) so sánh trực quan tỷ trọng phần bổ sản lượng giữa đề xuất máy và thực tế sửa đổi. Sắp xếp theo giá trị tuyệt đối của biên độ lệch.
  * *C4 (Cost Impact by Vendor):* Biểu đồ thanh đôi phân rã đồng thời giá trị lệch tiền mặt ($\Delta 	ext{VND}$) và phần trăm biến động ($\% 	ext{Drift}$) trên cùng một dòng Vendor thực tế chịu chi phí.
  * *C3 & C5 (Phân tích sâu theo Zone):* Lưới biểu đồ nhỏ (Small Multiples 4x3) và bảng Heatmap chéo giữa Vùng và Nhà thầu.

#### 4. Phân hệ Biến động Chi phí (Tab 4: Cost Variance)
* **Mục đích:** Giúp bộ phận Kế toán (Finance) và Planning Lead phát hiện các điểm thất thoát tiền mặt.
* **Chi tiết biểu đồ:**
  * *D2 & D3 (Diverging Bars):* Biểu đồ thanh ngang phân kỳ (Cột có cả giá trị âm và dương đại diện cho Tiết kiệm / Thua lỗ). D2 biểu diễn theo $\%$, D3 biểu diễn theo giá trị tiền mặt VND (Đơn vị cấu hình linh hoạt).
  * *D5 (Strategic 2x2 Bubble Charts):* Gồm 2 biểu đồ bong bóng độc lập cho Vùng và Nhà thầu. Trục X hiển thị Tổng khối lượng (CBM), Trục Y hiển thị Đơn giá chi phí (Cost/CBM), kích thước bong bóng đại diện cho tổng số chuyến xe. Phân chia giao diện thành 4 góc phần tư: Phía trên bên trái gắn nhãn "Thương thảo lại giá" (Negotiate), Phía dưới bên phải gắn nhãn "Mở rộng quy mô" (Scale).

#### 5. Phân hệ Khai thác & Xuất dữ liệu (Tab 5: Data Explorer)
* **Mục đích:** Trung tâm xuất dữ liệu thô phục vụ đối soát định kỳ, gửi dữ liệu offline cho đối tác hoặc làm sạch số liệu.
* **Các cấu phần:**
  * *D1 (Summary Comparison):* Bảng tổng hợp tóm tắt 2 dòng $	imes$ 6 cột so sánh tổng quan Trips, CBM, Fee, CPC và phần trăm chênh lệch giữa hai trạng thái Auto vs Adjusted.
  * *D6 (Province Metrics Heatmap):* Bảng cường độ nhiệt thể hiện các chỉ số hiệu suất gom nhóm theo tỉnh thành điểm đến của đơn hàng.

---

### IV. ĐẶC TẢ CẤU TRÚC DỮ LIỆU THÔ (GRID DỮ LIỆU & QUY TẮC TỪNG CỘT)

[Claude hướng dẫn: Hãy sử dụng toàn bộ nội dung trong mục 3 (Per-Chart Data Contract) và mục 4 (SQL Canonical Patterns) của file Spec để viết chi tiết quy tắc dữ liệu cho 5 bảng thô này dưới dạng bảng đặc tả Word tiêu chuẩn].

#### 1. Bảng T-CONSTRAINT: Nhật ký Trip vi phạm ràng buộc (Tab 2)
* **Hạt dữ liệu (Grain):** 1 dòng tương ứng với 1 chuyến xe (`tracking_id`) có tồn tại vi phạm ràng buộc sau khi Planner xử lý.
* **Nguyên tắc lấy dữ liệu và phân tách mảng (ArrayJoin Rule):** Trích xuất danh sách lỗi ngăn cách bằng dấu phẩy trong trường `constraint_name`. Khi người dùng tra cứu, áp dụng hàm `splitByChar` để bóc tách đếm số lỗi độc lập.
* **Đặc tả các cột thông tin:** [Claude điền danh sách cột từ Spec 4.10]

#### 2. Bảng T-VENDOR: Chi tiết hoán đổi Nhà thầu và Chi phí chênh lệch (Tab 3)
* **Hạt dữ liệu:** 1 dòng tương ứng với 1 chuyến xe lịch sử có đầy đủ thông tin so sánh cặp Vendor/Carrier giữa Auto và Adjusted.
* **Đặc tả các cột thông tin:** [Claude điền danh sách cột từ Spec 4.11]

#### 3. Bảng T-ZONE-COST: Tổng hợp chênh lệch chi phí theo Vùng (Tab 4)
* **Hạt dữ liệu:** 1 dòng tương ứng với 1 Phân vùng Logistics sau khi đã gom nhóm dữ liệu (Aggregated Zone Row).
* **Quy tắc chặn bộ lọc mẫu thấp (Low-sample rule):** Hệ thống áp dụng mệnh đề `HAVING trip_count_adj >= 10`. Tất cả các vùng có tổng sản lượng dưới 10 chuyến xe trong kỳ lọc sẽ tự động bị ẩn khỏi bảng tổng hợp để tránh nhiễu dữ liệu.

#### 4. Bảng T-MASTER: Toàn bộ dữ liệu lịch sử các chuyến xe (Tab 5)
* **Hạt dữ liệu:** 1 dòng tương ứng với 1 bản ghi giao dịch chuyến xe duy nhất (`tracking_id`). Đây là bảng thô lớn nhất hệ thống với cấu trúc 24 cột thông tin đầu ra.
* **Quy tắc hiển thị mặc định:** Để tối ưu hóa trải nghiệm màn hình của người dùng, hệ thống chỉ hiển thị mặc định 18 cột cốt lõi. 6 cột thông tin phụ (Gồm: mã nhà máy gốc, tên chi tiết nhà vận chuyển, danh sách chuỗi văn bản ràng buộc kỹ thuật...) sẽ được ẩn đi và cho phép người dùng bật tắt thủ công qua thanh dropdown "Columns".

#### 5. Bảng T-PLANNER: Đánh giá hiệu suất xử lý dữ liệu của Planner (Tab 5)
* **Hạt dữ liệu:** 1 dòng ứng với 1 tài khoản nhân viên lập kế hoạch (Planner ID).
* **Công thức tính thời gian can thiệp:** Áp dụng thuật toán fallback đo khoảng cách số phút (`dateDiff('minute')`) giữa thời điểm hệ thống chạy VRP tự động (`created_date`) và thời điểm phương án được chốt lưu lần cuối (`report_modified_date`).

---

### V. QUY TẮC TƯƠNG TÁC, RÀNG BUỘC KỸ THUẬT & EMPTY STATES

#### 1. Nguyên tắc xếp chồng bộ lọc hệ thống (Filter Cascade Rules)
* **Phạm vi dùng chung (Global Filter State):** Bộ lọc thời gian (Date Range Picker mặc định tháng hiện tại), tài khoản Planner, và Phân vùng vận chuyển (Zone Multi-select) nằm trên thanh công cụ Sticky Top. Trạng thái lựa chọn của bộ lọc sẽ được lưu giữ nguyên vẹn qua LocalStorage khi người dùng di chuyển đổi tab, không thực hiện reset lại từ đầu.
* **Cơ chế cô lập bộ lọc cục bộ (Cross-tab Isolation Rule):** Khi người dùng click chọn một đối tượng cụ thể bên trong đồ thị của một phân hệ sâu (Ví dụ click chọn Vùng Z03 trong Tab 2), bộ lọc cục bộ sẽ chỉ áp dụng ép xuống các thành phần biểu đồ và bảng dữ liệu nội bộ trong Tab 2 đó. Hệ thống không tự động đồng bộ lựa chọn này sang các Tab khác để tránh làm gián đoạn mạch phân tích của người dùng.

#### 2. Kịch bản hiển thị khi dữ liệu trống (Empty States & Error Handling Map)
Hệ thống TOBE yêu cầu xử lý triệt để các trạng thái trống của dữ liệu theo bảng ma trận hành vi trích xuất từ tài liệu Wireframe mục 9:
* *Trường hợp tổng chuyến xe bằng 0:* Không hiển thị chỉ số giá trị $0\%$ (Dễ gây hiểu nhầm thuật toán bị lỗi hoàn toàn). Thay thế bằng biểu tượng gạch ngang lớn (`—`) kèm dòng thông tin phụ trợ "Không phát sinh lượt chạy VRP tự động nào trong khoảng thời gian được chọn".
* *Trường hợp xử lý lỗi quá hạn truy vấn (Query Timeout > 30s):* Đóng luồng hiển thị widget, kích hoạt băng rôn cảnh báo màu đỏ: "Truy vấn dữ liệu vượt quá thời gian phản hồi cho phép. Vui lòng thu hẹp bộ lọc thời gian hoặc liên hệ bộ phận kỹ thuật".

#### 3. Tiêu chuẩn Xuất dữ liệu & Định dạng tệp tin (Bulk Export Mechanics)
* **Quy tắc đặt tên file tự động (Filename ISO Pattern):** File tải về phải tuân thủ nghiêm ngặt cấu trúc self-describing tương thích với hệ thống quản lý tệp tin của Windows và macOS:
  `psv-accuracy-vrp__{tên_tab}__{ngày_bắt_đầu}_{ngày_kết_thúc}__{mã_vùng}.xlsx`
  *Ví dụ thực tế:* `psv-accuracy-vrp__reliability__2026-05-01_2026-05-21__ALL.xlsx`
* **Hàng rào chặn tải lượng dữ liệu lớn (Export Guardrails):** Hệ thống kích hoạt cơ chế kiểm tra tổng số dòng trước khi kết xuất dữ liệu. Nếu dung lượng dòng vượt quá 50,000 dòng đối với định dạng Excel (.xlsx) hoặc vượt quá 200,000 dòng đối với định dạng văn bản phẳng (.csv), nút bấm sẽ tự động khóa và hiển thị dòng text phụ: "Dữ liệu kết xuất vượt quá giới hạn tài nguyên hệ thống. Vui lòng cấu hình lại bộ lọc thời gian".

---

### VI. PHƯƠNG ÁN KHẮC PHỤC THIẾU HỤT DỮ LIỆU HỆ THỐNG (DATA GAPs & FALLBACKS)

Để bảo đảm tính sống còn và cam kết tiến độ Go-live của dự án không bị hoãn do hạ tầng dữ liệu của bên thứ ba, tài liệu thống nhất phân kỳ rõ hai kịch bản triển khai TOBE:

#### 1. Đồng bộ cấu trúc dữ liệu Gốc của thuật toán (GAP Q1 - Auto Baseline)
* **Tác động trực tiếp:** Ảnh hưởng toàn bộ đến 11 biểu đồ so sánh chênh lệch tài chính tại Nhóm C và Nhóm D cùng 3 bảng dữ liệu thô xuất khẩu.
* **Giải pháp ưu tiên (TOBE Mong muốn):** Phối hợp cùng đội kỹ thuật hệ thống core TMS của Panasonic thiết lập mở rộng câu lệnh Trigger tuần tự, tiến hành phân tách trường chuỗi văn bản JSON từ bảng dữ liệu gốc `dbo.OPS_Optimizer` để hiện thực hóa (Materialize) các cột giá trị Auto gốc (`total_cost_auto`, `total_cbm_auto`, `vendor_name_auto`) chạy trực tiếp vào View dữ liệu của phân hệ Analytics.
* **Giải pháp dự phòng (Fallback):** Trong trường hợp trường cấu trúc dữ liệu gốc bị ghi đè, Smartlog sẽ triển khai phương án thuật toán hàm cửa sổ (Window Function) bóc tách bản ghi có số thứ tự phiên bản (`version`) nhỏ nhất của chuyến xe trong bảng lưu trữ lịch sử `psv_target` để làm mốc đối chứng Auto gốc (Chi tiết mã SQL phương án fallback quy định tại tài liệu Spec mục 4.A.alt).

#### 2. Đồng bộ danh mục Phân vùng Logistics của Panasonic (GAP Q2 - Zone Master Mapping)
* **Tác động trực tiếp:** Ảnh hưởng đến 9 biểu đồ phân tích theo địa bàn kinh doanh.
* **Giải pháp ưu tiên:** Panasonic bàn giao tệp tin Master cấu hình ánh xạ tường minh giữa các mã địa điểm giao hàng (`location_to_code`) tương ứng với các Phân vùng địa lý (`zone`) và khu vực vùng miền (`region`). Dữ liệu này được Smartlog cấu hình thành bảng từ điển tĩnh `analytics_workspace.panasonic_zone_master`.
* **Giải pháp dự phòng:** Tất cả các mã địa điểm phát sinh trong đơn hàng vận tải thực tế nếu không tìm thấy giá trị đối chiếu trong bảng từ điển sẽ được hệ thống tự động gán vào một nhóm dữ liệu chung mang tên **"Unknown"** nằm ở cuối danh mục hiển thị, bảo đảm tổng số liệu chuyến xe và chi phí dòng tiền mặt không bị sai lệch hay mất mát.

#### 3. Thiết lập kết nối dòng thời gian thao tác Planner (GAP Q3/Q4 - Event Log Tracking)
* **Giải pháp xử lý:** [Claude bóc tách từ mục Spec 7 để đưa ra phương án fallback sử dụng hiệu số thời gian giữa ngày tạo và ngày cập nhật cuối cùng để cứu vãn tiến độ Tab 5 hiệu suất Planner].

---

### VII. TIÊU CHÍ KIỂM TOÁN SỐ LIỆU & NGHIỆM THU DỰ ÁN (AUDIT GATE)

Hệ thống Dashboard TOBE sau khi xây dựng xong chỉ được phê duyệt nghiệm thu đưa vào vận hành thực tế (Go-live) nếu vượt qua vòng kiểm toán dữ liệu nghiêm ngặt dựa trên 3 tiêu chí kỹ thuật:
1. **Mức độ dịch sai số chấp nhận được (Tolerance Rate):** Biên độ chênh lệch số liệu tổng hợp (Tổng số chuyến xe, Tổng thể tích hàng hóa CBM, Tổng giá trị dòng tiền cước phí) hiển thị trên các Widget đồ thị của giao diện Dashboard so với kết quả câu lệnh truy vấn kiểm toán độc lập chạy trực tiếp trên cơ sở dữ liệu gốc `analytics_workspace.psv_target FINAL` phải luôn luôn **$\le 1\%$** (Biên độ lệch này được chấp nhận dựa trên độ trễ đồng bộ tuần hoàn 1 giờ của cơ chế Materialized View).
2. **Câu lệnh kiểm toán chuẩn hóa (Canonical Audit SQL):** Toàn bộ quy trình đối soát chênh lệch số liệu giữa Dashboard và Kho dữ liệu tổng phải sử dụng duy nhất cấu trúc câu lệnh SQL chuẩn hóa đã được hai bên phê duyệt tại tài liệu Spec mục 6.1 và 6.2.
3. **Cơ chế quản lý lưu trữ mã nguồn SQL (SQL Source-of-truth Registry):** Để ngăn ngừa hoàn toàn tình trạng sai lệch số liệu do lập trình viên viết lại câu lệnh SQL trực tiếp trên giao diện Front-end, toàn bộ các cấu trúc câu lệnh SQL tính toán chỉ số cho các Widget bắt buộc phải được đăng ký tập trung vào hệ thống tệp lưu trữ mã nguồn tĩnh tại đường dẫn thư mục dự án `docs/shared/sql-registry.md` thuộc phân mục quản lý `panasonic/psv-accuracy-vrp`. Quản trị viên hệ thống sẽ thực hiện sao chép thủ công các đoạn mã nguồn chuẩn hóa này vào hộp thoại cấu hình hệ thống (Settings Dialog) của Dashboard tại thời điểm triển khai runtime.
