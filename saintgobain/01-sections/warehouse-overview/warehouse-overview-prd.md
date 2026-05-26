# PRD — Section Warehouse Overview: TV dashboard giám sát vận hành kho real-time

| Trường | Giá trị |
|--------|---------|
| **Version** | 0.1.0 |
| **Ngày** | 2026-05-22 |
| **Trạng thái** | Draft — derived from HTML mockup, business validation cần thiết trước khi sang `/planner` |
| **Tác giả** | PM/BA Smartlog via `/ba` (input: `projects/saintgobain/dashboard.html`) |
| **Phạm vi** | `01-sections/warehouse-overview` — màn hình duy nhất "Digital View Logistics" cho khách hàng Saint-Gobain |
| **Source idea** | [`../../dashboard.html`](../../dashboard.html) — HTML mockup do user cung cấp |
| **Branch** | (TBA — chưa cut) |

> **⚠ Lưu ý classify**: Saint-Gobain là dự án **mới**, không có code/UI/config Smartlog hiện hành. Mọi mô tả "current behavior" thực chất là **Decision** (chốt từ mockup HTML) hoặc **Assumption** (PM/BA suy luận). KHÔNG có Observed (chưa có hệ thống production). Open Questions ở §11 cần được Saint-Gobain xác nhận trước khi spec.

---

## 1. Mục đích

Section **Warehouse Overview** cung cấp một **TV dashboard duy nhất** treo tại sàn vận hành kho Saint-Gobain, hiển thị real-time tình trạng toàn bộ chuỗi giao nhận trong kho:

- Số lượng đơn đang **chờ soạn (pre-picking)**, **đang soạn (in progress)**, **đã soạn xong sẵn sàng xuất (completed)**
- Danh sách xe đang **chuẩn bị nhận** (về kho lấy/nhập nguyên vật liệu) và xe đang **chuẩn bị xuất** (rời kho giao hàng)
- Tình trạng **các cửa dock** (line nào trống, line nào đang nhận, line nào đang xuất, biển số xe + mã đơn + thời gian vào dock)
- Danh sách **đơn mới thêm vào hệ thống** (chưa hoặc đã được pre-picking) và **đơn đang/đã soạn**

Mục tiêu nghiệp vụ:

| # | Mục tiêu | Tại sao quan trọng |
|---|---------|---------------------|
| G1 | Quản lý kho thấy "nhịp" vận hành trong 1 cái nhìn | Tránh phải mở 3-4 hệ thống WMS/TMS khác nhau để biết ai đang ở đâu |
| G2 | Tổ điều phối dock biết line nào sẵn sàng đón xe tiếp theo | Tối ưu thời gian quay đầu xe, giảm xe chờ ở cổng |
| G3 | Tổ soạn hàng (picker) biết hôm nay còn bao nhiêu đơn phải soạn | Self-pacing — giảm hỏi qua bộ đàm |
| G4 | Tài xế / nhà xe vào kho nhìn TV biết xe mình lên dock nào | Giảm gọi điện hỏi điều phối |

> **Khác Mondelez Flash Daily** — Mondelez đo *tiến độ E2E theo kế hoạch SAP đẩy về theo ngày/kỳ ngắn*. Saint-Gobain V1 đo *trạng thái real-time tại sàn kho ngay tại thời điểm xem* — không có khái niệm "% hoàn thành kế hoạch" trong section này.

---

## 2. Người dùng mục tiêu

| Vai trò | Vị trí xem | Nhu cầu chính | Mức độ tương tác |
|---------|-----------|---------------|------------------|
| **Quản lý kho (WH Manager)** | TV treo phòng điều hành / desktop cá nhân | Nhìn tổng — phát hiện bottleneck (xe chờ, đơn ứ, dock idle) | Cao — có thể click vào card/row để xem chi tiết (Open Question OQ-01) |
| **Điều phối dock (Dock Coordinator)** | TV sàn dock | Biết line nào trống để gọi xe lên | Trung bình — chủ yếu xem, ít click |
| **Tổ trưởng pick (Pick Lead)** | TV khu vực picking | Biết còn bao nhiêu đơn pre / đang soạn | Thấp — chỉ xem |
| **Tài xế / nhà xe** | TV phòng chờ tài xế / cổng kho | Biết biển số xe mình đã được gán dock chưa, lên line nào | Thấp — chỉ xem, không login |
| **Lãnh đạo / khách thăm kho** | TV sảnh / phòng họp | Cảm nhận "kho đang chạy ổn" — không tương tác | Không tương tác |

> **[Assumption]** — Danh sách user role suy ra từ mockup HTML (có nút Login + Warehouse selector → có cả mode anonymous TV view và mode login để chọn kho). Saint-Gobain cần xác nhận.

---

## 3. Định nghĩa nghiệp vụ

### 3.1 Vòng đời đơn hàng trong kho (Order Lifecycle)

> **[Decision from mockup + Assumption]** — Mockup HTML cho thấy 5 trạng thái đơn được nhóm thành 3 KPI cards. Định nghĩa nghiệp vụ chi tiết cần Saint-Gobain xác nhận (OQ-02).

| # | Trạng thái nghiệp vụ | Mô tả | Đếm vào KPI |
|---|----------------------|-------|-------------|
| 1 | **Chưa Pre (đơn mới chưa pre-picking)** | Đơn vừa được tạo / push xuống kho từ hệ thống cấp trên, chưa có thao tác chuẩn bị | "Pre-picking (New)" |
| 2 | **Đã Pre (đã pre-picking, chờ vào dock)** | Đơn đã được chuẩn bị thông tin / kế hoạch (allocate hàng, gán xe), chờ điều phối kéo lên dock | "Pre-picking (New)" |
| 3 | **Đang soạn (in progress picking)** | Đơn đang được soạn trên dock — picker đang lấy hàng / loader đang chất lên xe | "In Progress" |
| 4 | **Đã soạn (picking completed, ready to leave)** | Đơn đã soạn xong, xe đã chất hàng, chờ thủ tục xuất | "Completed (Ready)" |
| 5 | **Đã xuất (departed)** | Xe đã rời kho — KHÔNG còn hiển thị trên dashboard |

> **Trạng thái rendered trên dashboard** (từ mockup):
> - Badge `Đã Pre` (✓ green) vs `Chưa Pre` (red text)
> - Badge `Đã soạn` (green) vs `Đang soạn` (amber)
>
> **[Open Question OQ-02]**: Saint-Gobain hiện đang track 5 trạng thái này ở đâu (WMS hiện hành nào)? Có thêm trạng thái nào không (vd. Cancel, Hold, Partial)?

### 3.2 Loại nhận / Loại xuất

> **[Open Question OQ-03]** — Mockup HTML có 4 viết tắt: NVL, TBo, D2D, Cont. Cần Saint-Gobain define đầy đủ.

| Mã (mockup) | Suy đoán nghĩa | Vị trí xuất hiện |
|------------|----------------|------------------|
| `NVL` | Nguyên vật liệu (raw material — xe nhập NVL về kho) | Loại nhận |
| `TBo` | TBA (cần Saint-Gobain confirm — "Thành Bào"? "Thành Bao"? "Trả Bo")? | Cả nhận lẫn xuất |
| `D2D` | Door-to-door (giao thẳng từ kho tới điểm khách) | Loại xuất |
| `Cont` | Container (xuất nguyên cont) | Loại xuất |

PRD chỉ ghi tạm. Spec sẽ chuẩn hoá sau khi Saint-Gobain confirm.

### 3.3 Dock line (cửa dock)

> **[Decision from mockup]** — Mockup hiển thị 7 line: Line 3, 4, 5, 6, 7, 17, 21. Có vẻ Saint-Gobain có hệ thống đánh số line không liên tục (skip 1-2, 8-16, 18-20, 22+ hoặc không có).

Mỗi dock line có 1 trong 3 trạng thái:

| Trạng thái | Visual mockup | Thông tin hiển thị |
|-----------|----------------|---------------------|
| **Trống** (Empty) | Card xám, biểu tượng xe tải mờ | Chỉ tên line |
| **Đang nhận** (Inbound active) | Card xanh dương, viền sáng | Tên line + biển số xe + mã đơn IN-xxx + thời gian xe vào dock |
| **Đang xuất** (Outbound active) | Card cam, viền sáng | Tên line + biển số xe + mã đơn OUT-xxx + thời gian xe vào dock |

> **[Open Question OQ-04]**: Saint-Gobain có bao nhiêu dock line tổng cộng? Có cần render đủ tất cả line vật lý hay chỉ render line được "kích hoạt" trong tenant config?

### 3.4 Vehicle status (trạng thái xe so với lịch hẹn)

| Status | Định nghĩa |
|--------|-----------|
| **Đã đến** | Xe đã đến cổng/sân kho (có ATA — actual time of arrival) |
| **Chưa đến** | Xe đã được lên kế hoạch (có Time DK = thời gian dự kiến) nhưng chưa có ATA |

Chỉ có 2 trạng thái này trên bảng xe nhận / xe xuất.

> **[Open Question OQ-05]**: Sau khi xe **Đã đến** → khi nào xe biến mất khỏi bảng "chuẩn bị nhận/xuất"? Khi xe được gán vào dock line (xuất hiện ở Dock Operation)? Hay khi xe rời kho?

### 3.5 KPI deltas (góc trên 3 card)

| Card | Sub-text mockup | Ý nghĩa |
|------|----------------|---------|
| Pre-picking (New) | "+12 orders vs 1h ago" | Số đơn mới được push vào trong 60 phút qua |
| In Progress | "Avg. pick time: 24m" | Thời gian soạn hàng trung bình của các đơn đang soạn |
| Completed (Ready) | "98% On-time" | Tỷ lệ đơn hoàn tất soạn đúng giờ vs SLA nội bộ trong khoảng thời gian (TBA) |

> **[Open Question OQ-06]**: Định nghĩa "On-time" = soạn xong trước Time DK xuất bao nhiêu phút? Phạm vi tính (hôm nay? 24h gần nhất?)

---

## 4. Bộ lọc / Cấu hình màn hình

> **[Decision from mockup]** — Mockup chỉ có **Warehouse selector** ở header. KHÔNG có date range, KHÔNG có channel/region/brand filter. Đây là dashboard **always live**, scope = 1 kho tại thời điểm hiện tại.

| Filter | Behavior | Default | Persist? |
|--------|---------|---------|----------|
| **Warehouse** (dropdown) | Single-select — chọn 1 kho trong số kho user có quyền truy cập | Kho được gán default cho user (hoặc kho đầu danh sách) | Có — localStorage / user profile |

**Auto-refresh**: Dashboard tự refresh dữ liệu định kỳ (Open Question OQ-07 về tần suất). Đồng hồ realtime ở header tick mỗi giây — chỉ là UI display, không trigger data refresh.

**Không có**: date range, time window selector, ngôn ngữ toggle (mockup tiếng Việt hardcoded — xem OQ-08).

---

## 5. Cấu trúc màn hình

Section gồm **5 vùng chính**, layout dọc:

```
┌──────────────────────────────────────────────────────────────────────┐
│ HEADER — Logo Saint-Gobain + tên dashboard + Warehouse selector +    │
│          đồng hồ realtime + nút Login                                 │
├──────────────────────────────────────────────────────────────────────┤
│ KPI STRIP — 3 thẻ ngang:                                              │
│   [Pre-picking (New)] [In Progress] [Completed (Ready)]               │
│   Mỗi thẻ: label + giá trị lớn + sub-text (delta / avg / %)           │
├──────────────────────────────────────────────────────────────────────┤
│ HÀNG 2 CỘT — Xe nhận / Xe xuất                                        │
│   [Bảng: Thông tin xe chuẩn bị NHẬN]  [Bảng: Thông tin xe chuẩn bị XUẤT] │
│   Cột: Mã đơn │ Biển số xe │ Time DK │ Loại │ Trạng thái               │
│   Footer: Total + đếm Đến / Chưa đến                                  │
├──────────────────────────────────────────────────────────────────────┤
│ DOCK OPERATION (dark theme banner) — grid các dock line                │
│   Mỗi line: tên + tag (Trống/Nhận/Xuất) + thông tin xe nếu active      │
│   Line active có viền màu (xanh = Nhận, cam = Xuất) + shadow glow      │
├──────────────────────────────────────────────────────────────────────┤
│ HÀNG 2 CỘT — Đơn thêm mới / Đơn đang/đã soạn                          │
│   [Bảng: Đơn thêm mới]              [Bảng: Đơn đang/đã soạn]          │
│   Cột: Mã đơn │ Trạng thái Pre/Soạn │ Time xuất │ Loại xuất            │
│   Footer: Total + đếm theo trạng thái                                  │
└──────────────────────────────────────────────────────────────────────┘
```

> **[Decision from mockup]** — Layout chi tiết, màu sắc, typography (Plus Jakarta Sans + JetBrains Mono) reference từ `dashboard.html`. Wireframe đầy đủ sẽ được port sang `warehouse-overview-wireframe.md` ở phase tiếp theo.

### 5.1 Responsive

Mockup HTML có 1 breakpoint `@max-width: 1100px`:
- KPI strip 3 cột → 1 cột
- Hàng 2 cột → 1 cột (xe nhận xếp trên xe xuất)
- Dock lines 7 cột → 3 cột

> **[Decision]** — Optimize cho TV ngang 16:9 (≥1920px). Mobile/tablet KHÔNG phải target chính.

---

## 6. Functional Requirements

| ID | Requirement | Priority |
|----|------------|----------|
| FR-01 | Hiển thị header có logo Saint-Gobain, tên "Digital View Logistics — Warehouse Management System", dropdown chọn kho, đồng hồ realtime (HH:MM:SS update mỗi giây), nút Login | Must Have |
| FR-02 | Hiển thị 3 KPI card: số đơn Pre-picking (New), số đơn In Progress, số đơn Completed (Ready) — mỗi card có sub-text giải thích delta / chỉ số phụ | Must Have |
| FR-03 | Hiển thị bảng "Thông tin xe chuẩn bị nhận" với các cột: Mã đơn, Biển số xe, Time dự kiến, Loại nhận, Trạng thái (Đã đến / Chưa đến) | Must Have |
| FR-04 | Hiển thị bảng "Thông tin xe chuẩn bị xuất" với cùng schema FR-03, Loại xuất khác biệt (D2D / Cont / TBo / …) | Must Have |
| FR-05 | Hiển thị footer mỗi bảng xe: tổng số xe + đếm phân nhóm theo trạng thái (Đến / Chưa đến) | Must Have |
| FR-06 | Hiển thị grid Dock Operation — mỗi dock line là 1 ô; ô **Trống** chỉ có tên line; ô **Nhận** / **Xuất** có biển số xe, mã đơn, thời gian vào dock | Must Have |
| FR-07 | Phân biệt dock line nhận vs xuất bằng màu sắc rõ rệt (xanh dương vs cam) + viền sáng + glow | Must Have |
| FR-08 | Hiển thị bảng "Đơn thêm mới" với các cột: Mã đơn, Trạng thái Pre (Đã Pre / Chưa Pre), Time xuất, Loại xuất | Must Have |
| FR-09 | Hiển thị bảng "Đơn đang/đã soạn" với các cột: Mã đơn, Trạng thái (Đang soạn / Đã soạn), Time xuất, Loại xuất | Must Have |
| FR-10 | Hiển thị footer mỗi bảng đơn: tổng + đếm theo trạng thái nghiệp vụ (Chưa Pre; Đang soạn / Đã soạn) | Must Have |
| FR-11 | Dropdown Warehouse selector cho phép user chuyển sang kho khác — tất cả KPI, bảng, dock grid refetch theo kho đã chọn | Must Have |
| FR-12 | Dashboard tự động làm mới dữ liệu định kỳ KHÔNG cần user nhấn refresh (tần suất TBA — OQ-07) | Must Have |
| FR-13 | Đồng hồ realtime tick mỗi giây — KHÔNG trigger fetch dữ liệu | Must Have |
| FR-14 | Khi không có dữ liệu cho bảng nào (vd. không xe chuẩn bị nhận hôm nay) → bảng vẫn render header + footer "Total: 0", body hiển thị empty state (TBA — OQ-09) | Should Have |
| FR-15 | Hiển thị KPI delta "+N orders vs 1h ago" so sánh số đơn Pre-picking với cùng thời điểm 1 giờ trước | Should Have |
| FR-16 | Hiển thị KPI "Avg. pick time: Nm" = thời gian soạn trung bình của đơn In Progress hiện tại (TBA định nghĩa cụ thể) | Should Have |
| FR-17 | Hiển thị KPI "N% On-time" = tỷ lệ đơn Completed đúng SLA trong khoảng thời gian (TBA — OQ-06) | Should Have |
| FR-18 | User KHÔNG login vẫn xem được dashboard mode read-only (TV view) — kho mặc định theo URL hoặc default tenant config | Could Have (TBA — OQ-10) |
| FR-19 | User login → cá nhân hoá: kho default = kho user phụ trách, có thể save filter | Could Have |
| FR-20 | Click vào 1 row (đơn / xe / dock line) → mở drill-down detail (đơn lịch sử, sản phẩm, ETA…) | Could Have (TBA — OQ-01) |

---

## 7. Business Rules

| ID | Rule | Ghi chú |
|----|------|---------|
| BR-01 | Một dock line tại 1 thời điểm chỉ thuộc đúng 1 trạng thái: Trống / Nhận / Xuất — không có "vừa nhận vừa xuất" | Cần Saint-Gobain confirm có ngoại lệ không |
| BR-02 | Mã đơn IN-xxx là đơn nhập (xe chở hàng VÀO kho); OUT-xxx là đơn xuất (xe chở hàng RA kho) | Suy ra từ mockup — cần confirm naming convention chính thức |
| BR-03 | Xe đã có Time DK nhưng chưa có ATA → trạng thái "Chưa đến"; có ATA → "Đã đến" | |
| BR-04 | Xe biến mất khỏi bảng "chuẩn bị nhận/xuất" khi đã được gán dock line (xuất hiện ở Dock Operation) | **[Assumption]** — OQ-05 cần confirm |
| BR-05 | Dashboard chỉ hiển thị các đơn đang ACTIVE trong kho — đơn đã rời kho (departed) KHÔNG xuất hiện ở bất kỳ section nào | |
| BR-06 | Warehouse selector chỉ liệt kê các kho mà user hiện tại có quyền truy cập | Multi-tenant + ACL — chuẩn Smartlog Control Tower |
| BR-07 | Khi chuyển kho → toàn bộ dashboard reset, không giữ state từ kho cũ | |
| BR-08 | KPI delta "+N orders vs 1h ago" cho phép số âm (vd. "-5") nếu trong 1h qua có nhiều đơn được pre hơn là đơn mới push vào | **[Assumption]** — confirm với Saint-Gobain |
| BR-09 | KPI "% On-time" tính trên các đơn có status = Completed (Ready) trong khoảng thời gian rolling N (N = TBA OQ-06) | |
| BR-10 | Đơn ở trạng thái "Đã soạn" sẽ chuyển sang "Đã xuất" (biến mất khỏi dashboard) khi xe gán đơn đó rời kho | **[Assumption]** — confirm |

---

## 8. User Stories & Acceptance Criteria

### US-01: Quản lý kho xem nhịp vận hành trong 1 cái nhìn

**As a** quản lý kho Saint-Gobain, **I want** thấy tổng quan số đơn / xe / dock trong kho hôm nay, **so that** tôi biết kho đang "khoẻ" hay đang ứ đọng mà không cần mở nhiều hệ thống.

**Acceptance Criteria:**

#### AC-01: 3 KPI cards luôn hiển thị giá trị hiện thời

- **Given** user mở dashboard với kho đã chọn
- **When** dữ liệu load xong
- **Then** 3 KPI cards hiển thị:
  - "Pre-picking (New)" = số đơn ở trạng thái "Chưa Pre" + "Đã Pre" (tổng đơn chờ vào dock)
  - "In Progress" = số đơn ở trạng thái "Đang soạn"
  - "Completed (Ready)" = số đơn ở trạng thái "Đã soạn"
- Mỗi card có sub-text: KPI #1 = delta 1h, KPI #2 = avg pick time, KPI #3 = % on-time

#### AC-02: Chuyển kho cập nhật toàn dashboard

- **Given** user đang xem kho A
- **When** user chọn kho B trong dropdown Warehouse
- **Then** trong vòng tối đa 3 giây:
  - 3 KPI cards refetch số liệu kho B
  - 2 bảng xe (nhận/xuất) refetch
  - Dock Operation grid refetch
  - 2 bảng đơn (mới / đang soạn) refetch
- Lựa chọn kho B được persist (lần mở sau vào kho B)

### US-02: Điều phối dock biết line nào trống để gọi xe lên

**As a** điều phối dock, **I want** thấy nhanh các line dock đang trống, **so that** tôi gọi xe tiếp theo lên line phù hợp mà không cần đi quanh kho kiểm tra.

**Acceptance Criteria:**

#### AC-03: Dock grid phân biệt 3 trạng thái rõ ràng

- **Given** dashboard đang hiển thị Dock Operation grid
- **When** user nhìn vào grid
- **Then**:
  - Line **Trống**: nền nhạt, biểu tượng xe tải mờ, tag "Trống" màu xám
  - Line **Đang nhận**: nền xanh dương đậm, viền sáng + glow, tag "Nhận" + biển số xe + mã đơn IN-xxx + giờ vào dock
  - Line **Đang xuất**: nền cam đậm, viền sáng + glow, tag "Xuất" + biển số xe + mã đơn OUT-xxx + giờ vào dock
- Từ khoảng cách 3-5m (TV view) phân biệt được rõ 3 trạng thái

### US-03: Tổ trưởng pick biết còn bao nhiêu đơn cần soạn

**As a** tổ trưởng pick, **I want** thấy số đơn "Chưa Pre" và "Đang soạn", **so that** tôi điều động nhân lực phù hợp mà không cần hỏi qua bộ đàm.

**Acceptance Criteria:**

#### AC-04: Bảng "Đơn thêm mới" + "Đơn đang/đã soạn" hiển thị đúng status

- **Given** dashboard đang hiển thị
- **When** user nhìn vào 2 bảng đơn
- **Then**:
  - Bảng "Đơn thêm mới" liệt kê đơn ở trạng thái Chưa Pre / Đã Pre với badge tương ứng (badge xanh nếu Đã Pre, badge đỏ nếu Chưa Pre)
  - Bảng "Đơn đang/đã soạn" liệt kê đơn ở trạng thái Đang soạn (badge amber) / Đã soạn (badge xanh)
  - Mỗi row có Mã đơn, Time xuất dự kiến, Loại xuất
  - Footer hiển thị Total + đếm Chưa Pre (cho bảng 1) / Đang soạn + Đã soạn (cho bảng 2)

### US-04: Tài xế / nhà xe biết xe mình lên dock nào

**As a** tài xế đến nhập/xuất hàng kho Saint-Gobain, **I want** thấy biển số xe của mình trên TV phòng chờ, **so that** tôi biết lên line nào mà không cần hỏi điều phối.

**Acceptance Criteria:**

#### AC-05: Biển số xe hiển thị nổi bật trên dock line active

- **Given** xe của tài xế đã được gán lên dock line
- **When** tài xế nhìn TV
- **Then**:
  - Card dock line tương ứng có biển số xe hiển thị bằng font monospace cỡ lớn
  - Có mã đơn + giờ vào dock kèm theo
  - Từ khoảng cách 3-5m đọc được biển số

### US-05: Dashboard auto-refresh không cần thao tác

**As a** mọi user xem TV, **I want** dashboard tự cập nhật, **so that** thông tin trên TV luôn mới mà không ai phải bấm F5.

**Acceptance Criteria:**

#### AC-06: Dashboard tự refetch dữ liệu định kỳ

- **Given** dashboard đang hiển thị, không có thao tác user
- **When** trải qua khoảng thời gian X giây (X = TBA, OQ-07)
- **Then**:
  - Tất cả 3 KPI cards + 2 bảng xe + dock grid + 2 bảng đơn refetch
  - UI cập nhật mượt, không flicker / không "trắng màn"
  - Đồng hồ header vẫn tick từng giây độc lập với data refetch

#### AC-07: Đồng hồ realtime không phụ thuộc data fetch

- **Given** dashboard đang hiển thị
- **When** thời gian thay đổi
- **Then** đồng hồ HH:MM:SS ở header update mỗi giây ngay cả khi data fetch fail

### US-06: Empty state khi không có hoạt động

**As a** quản lý kho ngoài giờ vận hành, **I want** dashboard vẫn hiển thị đẹp khi kho không có hoạt động, **so that** TV không bị "rỗng" gây nhầm với lỗi hệ thống.

**Acceptance Criteria:**

#### AC-08: Bảng / KPI vẫn render khi data rỗng

- **Given** không có đơn / xe / dock active trong kho đã chọn
- **When** data return rỗng
- **Then**:
  - 3 KPI cards hiển thị "0" cho value, sub-text neutral (vd. "Chưa có đơn mới trong 1h qua")
  - 2 bảng xe có header + footer "Total: 0", body có message empty state
  - Dock grid hiển thị tất cả line ở trạng thái "Trống"
  - 2 bảng đơn có header + footer "Total: 0", body có message empty state
- KHÔNG có error message / spinner kéo dài

---

## 9. User Flows

### Flow 1: User mở dashboard lần đầu (TV mode, không login)

```
1. User mở URL dashboard trên TV
2. Hệ thống detect không có session login
   → áp dụng default warehouse (tenant config) HOẶC hiển thị nút Login (TBA OQ-10)
3. Tải dữ liệu: 3 KPI + 2 bảng xe + dock grid + 2 bảng đơn
4. Hiển thị toàn bộ dashboard
5. Background: auto-refresh mỗi X giây
```

### Flow 2: Quản lý kho xem dashboard và chuyển kho

```
1. User login → dashboard mở với kho default của user
2. User click Warehouse dropdown → chọn kho khác
3. Toàn bộ dashboard reset + refetch theo kho mới
4. Lựa chọn kho mới được persist
5. Lần mở dashboard tiếp theo → kho đã chọn
```

### Flow 3: Điều phối dock theo dõi xe vào ra

```
1. Xe có lịch hẹn → xuất hiện trong bảng "Xe chuẩn bị nhận/xuất" với badge "Chưa đến"
2. Xe đến kho (cảm biến cổng / nhân viên scan) → badge đổi "Đã đến"
3. Điều phối gán xe vào dock line → row xe biến mất khỏi bảng "chuẩn bị" → card dock line đổi sang trạng thái Nhận/Xuất với biển số + mã đơn
4. Xe rời dock → card dock line đổi về "Trống"; đơn hàng (nếu là OUT) chuyển sang "Đã xuất" (biến mất khỏi mọi bảng)
```

---

## 10. Dependencies

| # | Phụ thuộc | Loại | Ghi chú |
|---|----------|------|---------|
| D1 | Hệ thống WMS Saint-Gobain hiện hành | Data source | Cung cấp danh sách đơn + trạng thái Pre/Soạn — chưa biết hệ thống tên gì, có API hay chỉ DB |
| D2 | Hệ thống TMS / quản lý xe Saint-Gobain | Data source | Cung cấp danh sách xe + biển số + Time DK + ATA — TBA |
| D3 | Hệ thống quản lý dock (DMS / module trong WMS) | Data source | Cung cấp mapping xe → dock line, trạng thái dock — TBA |
| D4 | Hệ thống quản lý nhân sự (SSO) | Auth | Optional — chỉ cần cho login mode; TV mode anonymous không cần |
| D5 | Smartlog Control Tower platform | Hạ tầng | Dashboard host, widget framework, multi-tenant, ACL kho |
| D6 | Master data: danh mục kho, danh mục dock line vật lý, danh mục loại nhận/xuất | Master data | TBA — Saint-Gobain cung cấp |

> **[Open Question OQ-11]**: Saint-Gobain hiện đang dùng WMS / TMS gì? Có API gọi được hay phải DB-direct? Tần suất push data ra sao?

---

## 11. Non-functional Requirements

| ID | Yêu cầu | Mục tiêu |
|----|---------|---------|
| NFR-01 | Thời gian load dashboard lần đầu | < 3 giây (kết nối nội bộ kho) |
| NFR-02 | Tần suất auto-refresh | 10-30 giây (TBA OQ-07) |
| NFR-03 | Concurrent viewers per warehouse | ≥ 20 TV / desktop session đồng thời |
| NFR-04 | Khả năng hiển thị trên TV ≥ 1920×1080 | Layout không vỡ, font đọc được từ 3-5m |
| NFR-05 | Browser support | Chrome / Edge phiên bản mới nhất (Smart TV browser nếu cần — TBA) |
| NFR-06 | Resilient với data lag | Khi data source lag, dashboard vẫn hiển thị data cũ + indicator "Cập nhật lần cuối: HH:mm" (TBA OQ-12 — confirm cần hay không) |
| NFR-07 | Đa ngôn ngữ | V1 chỉ tiếng Việt (mockup hardcoded VN) — Anh ngữ và song ngữ defer (TBA OQ-08) |
| NFR-08 | Accessibility | KHÔNG bắt buộc V1 — TV mode anonymous read-only, không có ARIA / keyboard nav requirement |
| NFR-09 | Audit / log | KHÔNG cần log view event V1 (TV mode anonymous); chỉ log action khi user login (TBA) |

---

## 12. Out of Scope (V1)

| # | Hạng mục | Lý do defer |
|---|---------|------------|
| OOS-01 | Drill-down chi tiết đơn (click row → modal hoặc page mới) | Defer V2 — cần workshop UX trước; V1 chỉ là TV view read-only |
| OOS-02 | Cảnh báo / alert khi KPI vượt ngưỡng (vd. > 50 đơn chờ Pre) | Defer V2 — không có rules trigger rõ ràng |
| OOS-03 | Lịch sử trend (số đơn hôm qua / tuần trước) | KHÔNG nằm trong scope TV real-time — sẽ là section khác |
| OOS-04 | Export CSV / PDF dữ liệu trên màn | KHÔNG cần V1 (TV mode) |
| OOS-05 | Đa kho hiển thị đồng thời (multi-warehouse single view) | V1 = 1 kho / 1 dashboard. Multi-warehouse là roadmap V2+ |
| OOS-06 | Cấu hình dashboard layout (drag-drop, custom widget) | Saint-Gobain V1 = layout cố định cho TV. Edit mode cho power user defer |
| OOS-07 | Tích hợp camera / video stream dock | KHÔNG nằm trong PRD này |
| OOS-08 | Báo cáo SLA / KPI tổng kết ngày-tuần-tháng | Defer — sẽ là section riêng (potential "Daily Report") |
| OOS-09 | Cấu hình ngưỡng cảnh báo theo loại đơn / kho | Defer V2 |
| OOS-10 | Mobile responsive đầy đủ (smartphone view) | V1 ưu tiên TV. Mobile có thể "xem được" nhưng không phải target |

---

## 13. Open Questions

> Tất cả OQ dưới đây cần Saint-Gobain xác nhận trước khi sang `/planner` (Tech Spec phase).

| # | Câu hỏi | Tại sao quan trọng | Cần answer từ |
|---|---------|---------------------|----------------|
| **OQ-01** | Click vào row (đơn / xe / dock card) có mở drill-down detail KHÔNG ở V1? Nếu có → drill-down hiển thị gì? | Quyết định scope V1 vs V2 | Saint-Gobain Business Owner |
| **OQ-02** | 5 trạng thái đơn nghiệp vụ (Chưa Pre / Đã Pre / Đang soạn / Đã soạn / Đã xuất) có chính xác KHÔNG? Có thêm trạng thái nào (Cancel, Hold, Partial)? Định nghĩa chuyển trạng thái ra sao? | Toàn bộ logic dashboard phụ thuộc | Saint-Gobain WH Ops + IT |
| **OQ-03** | NVL / TBo / D2D / Cont nghĩa đầy đủ là gì? Còn loại nhận/xuất nào khác không? | Để chuẩn hoá master data + badge color | Saint-Gobain WH Ops |
| **OQ-04** | Saint-Gobain có bao nhiêu dock line tổng cộng (vật lý)? Có cố định 7 line hay theo từng kho? Đánh số ra sao? | Layout dock grid + master data | Saint-Gobain WH Ops |
| **OQ-05** | Sau khi xe "Đã đến" → khi nào xe biến mất khỏi bảng "chuẩn bị nhận/xuất"? Khi gán dock? Khi rời kho? | Logic state transition của 2 bảng xe | Saint-Gobain WH Ops |
| **OQ-06** | KPI "% On-time" — định nghĩa "on-time" = trước Time DK xuất bao nhiêu phút? Tính trên khoảng thời gian nào (hôm nay / 24h / 8h ca làm việc)? | Công thức KPI #3 | Saint-Gobain WH Ops |
| **OQ-07** | Tần suất auto-refresh là bao nhiêu? 10s / 30s / 1 phút? | NFR-02, performance design | Saint-Gobain WH Ops + Smartlog DevOps |
| **OQ-08** | V1 có cần đa ngôn ngữ (Việt-Anh)? Saint-Gobain VN có nhân viên expat không? | Quyết định i18n architecture | Saint-Gobain BOD |
| **OQ-09** | Empty state message cho bảng / KPI khi data rỗng? Nội dung cụ thể? | UX copy | Saint-Gobain + UX writer |
| **OQ-10** | TV mode anonymous (không login) có support không? Hay bắt buộc login? Nếu anonymous → kho default lấy từ đâu (tenant config / URL param)? | Auth architecture | Saint-Gobain IT |
| **OQ-11** | Hệ thống WMS / TMS / DMS Saint-Gobain hiện đang dùng là gì? Cách lấy data (API / DB direct / file)? Tần suất data freshness ra sao? | Toàn bộ integration design | Saint-Gobain IT |
| **OQ-12** | Có cần hiển thị "Cập nhật lần cuối: HH:mm" trên dashboard không? | Trust & transparency UX | Saint-Gobain WH Ops |
| **OQ-13** | Saint-Gobain có nhiều kho không? Nếu nhiều → có cần đa kho cùng lúc hay 1 lần 1 kho là đủ V1? | Scope V1 vs roadmap | Saint-Gobain WH Ops |
| **OQ-14** | KPI delta "+12 orders vs 1h ago" so sánh với cùng lúc 1h trước hay với "tổng đơn được tạo trong 1h qua"? | Định nghĩa KPI delta | Saint-Gobain WH Ops |
| **OQ-15** | "Avg. pick time: 24m" tính trên đơn nào — đơn In Progress hiện tại (mean của duration "vào trạng thái Đang soạn → bây giờ"), hay đơn đã hoàn thành gần đây? | Định nghĩa KPI #2 | Saint-Gobain WH Ops |
| **OQ-16** | Mockup ghi "Pre-picking (New)" — KPI #1 đếm cả đơn "Đã Pre" (chờ vào dock) hay chỉ đơn "Chưa Pre" (mới chưa pre)? | Định nghĩa KPI #1 | Saint-Gobain WH Ops |
| **OQ-17** | Mockup không có date range filter — dashboard chỉ live realtime, hay có cần xem snapshot của một ngày quá khứ? | Scope feature filter | Saint-Gobain WH Ops |
| **OQ-18** | Permission model: user nào được thấy kho nào? Saint-Gobain dùng SSO của họ hay tài khoản local Smartlog? | Auth + ACL architecture | Saint-Gobain IT |

---

## 14. Lịch sử thay đổi

| Version | Ngày | Tác giả | Thay đổi |
|---------|------|---------|---------|
| 0.1.0 | 2026-05-22 | PM/BA Smartlog via `/ba` | Bản đầu tiên — derive từ HTML mockup `dashboard.html`. Chứa 18 Open Questions cần Saint-Gobain xác nhận trước khi sang Tech Spec. Phạm vi V1 = TV dashboard real-time 1 kho, 5 vùng (header / 3 KPI / 2 bảng xe / dock grid / 2 bảng đơn). |
