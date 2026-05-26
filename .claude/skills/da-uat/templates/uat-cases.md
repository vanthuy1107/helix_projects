# UAT Test Cases — {section} ({tenant})

> Template Mode A output. File path: `projects/{tenant}/{section}/uat/{section}-uat-cases.md`
> Bám storytelling layout L1→L6 của section. Mỗi level/layer = 2-4 case (1 happy + 1-2 edge).
> Khách hoặc PM/BA điền cột `Actual` và `P/F` trong Mode C.

---

## 0. Quy ước

- **TC-ID**: `UAT-{section-short}-{NNN}` (vd `UAT-OTIF-001`)
- **Layer**: L1 / L2 / L3 / L4 / L5 / L6 (theo `{section}-spec.md`)
- **Lớp**: A (Data) / B (Logic) / C (UX) / D (Perf) — có thể là kết hợp `A+B`
- **Tiền điều kiện**: filter combination + time window + tenant + user role
- **Severity expected** (nếu Fail): Critical / Major / Minor / Cosmetic
- **P/F**: Pass / Fail / Blocked / Defer / N/A

---

## 1. Layer L1 — Hero

### UAT-{slug}-001 (lớp A+B, happy)

| Field | Value |
|---|---|
| Mục đích | Verify % hero hôm nay khớp golden file khách + RAG band đúng target |
| Tiền điều kiện | Filter: NPP=ALL, kho=ALL, date=hôm nay; user=SC Manager |
| Steps | 1. Mở view {section}<br>2. Đọc % ở hero L1<br>3. Note RAG color |
| Expected | % = `<từ golden file>` ± `<tolerance>`; RAG color = `<green/yellow/red theo band>` |
| Actual | `<điền trong Mode C>` |
| P/F | |
| Severity nếu Fail | Major |
| Note | |

### UAT-{slug}-002 (lớp B, edge)

| Field | Value |
|---|---|
| Mục đích | Verify RAG color đúng khi % chạm chính xác ngưỡng band |
| Tiền điều kiện | Filter chọn time window có % = `<ngưỡng vd 85.0%>` |
| Steps | 1. Filter time window<br>2. Note RAG color |
| Expected | RAG = `<color đúng band theo memory tenant>` |
| Actual | |
| P/F | |
| Severity nếu Fail | Minor |
| Note | Edge case ranh giới band |

## 2. Layer L2 — Exception banner

### UAT-{slug}-003 (lớp B+C, happy)

| Field | Value |
|---|---|
| Mục đích | Verify exception banner hiển thị khi % vượt ngưỡng cảnh báo |
| Tiền điều kiện | Filter time window có % < `<ngưỡng vd 80%>` |
| Steps | 1. Filter<br>2. Quan sát banner xuất hiện<br>3. Đọc text banner |
| Expected | Banner Red, text rõ "Cảnh báo: ..." |
| Actual | |
| P/F | |
| Severity | Major |

### UAT-{slug}-004 (lớp C, edge)

| Field | Value |
|---|---|
| Mục đích | Banner KHÔNG hiển thị khi % vừa khít trên ngưỡng |
| Tiền điều kiện | Filter có % = ngưỡng + epsilon |
| Steps | ... |
| Expected | Không có banner |
| Actual | |
| P/F | |
| Severity | Minor |

## 3. Layer L3 — Funnel (nếu có)

### UAT-{slug}-005 (lớp A+B)

| Field | Value |
|---|---|
| Mục đích | Verify tổng từng bucket funnel khớp golden file + tổng các bucket = tổng đơn |
| Tiền điều kiện | Filter chuẩn |
| Steps | 1. Đọc số mỗi bucket L3<br>2. Cộng tay tổng các bucket<br>3. So với tổng đơn ở L1 hero |
| Expected | Mỗi bucket khớp golden ± tolerance; tổng bucket = tổng đơn |
| Actual | |
| P/F | |
| Severity | Major |

## 4. Layer L4 — Trend (filter behavior tuỳ section)

### UAT-{slug}-006 (lớp B)

| Field | Value |
|---|---|
| Mục đích | Verify trend window đúng spec (vd 14d cho Flash Daily, độc lập với filter date theo memory) |
| Tiền điều kiện | Đổi filter date → quan sát trend |
| Steps | 1. Filter date=hôm nay → screenshot trend<br>2. Filter date=tuần trước → screenshot trend |
| Expected | 2 screenshot trend IDENTICAL (filter-independent với date) |
| Actual | |
| P/F | |
| Severity | Major |
| Note | Verify per memory [[project_mondelez_flash_daily_l4_filter_independent]] nếu section là Flash Daily |

### UAT-{slug}-007 (lớp A)

| Field | Value |
|---|---|
| Mục đích | Verify từng điểm trên trend khớp golden file |
| Tiền điều kiện | Filter chuẩn |
| Steps | Click vào từng điểm → đọc value tooltip |
| Expected | Mỗi điểm ngày khớp golden ± tolerance |
| Actual | |
| P/F | |
| Severity | Major |

## 5. Layer L5 — Dimension panels

### UAT-{slug}-008 (lớp A+C)

| Field | Value |
|---|---|
| Mục đích | Verify dimension panel khớp golden cho từng chiều (kho/khu vực/customer/channel) |
| Tiền điều kiện | Filter chuẩn |
| Steps | 1. Đọc top 5 mỗi dimension panel<br>2. Match với golden top 5 |
| Expected | ≥ 4/5 tên match, thứ tự có thể lệch |
| Actual | |
| P/F | |
| Severity | Major |

### UAT-{slug}-009 (lớp C)

| Field | Value |
|---|---|
| Mục đích | Khách đọc panel có spot được "chiều nào kéo % xuống" không? |
| Tiền điều kiện | Filter có % thấp ở 1 chiều cụ thể |
| Steps | Hỏi khách: "Theo anh/chị, kho/khu vực nào đang kéo OTIF xuống?" |
| Expected | Khách chỉ đúng panel chứa cause |
| Actual | (ghi câu trả lời khách) |
| P/F | (đạt yêu cầu storytelling không) |
| Severity | Minor |
| Note | UX validation — không có "đúng/sai" tuyệt đối |

## 6. Layer L6 — Detail tables

### UAT-{slug}-010 (lớp A)

| Field | Value |
|---|---|
| Mục đích | Verify table top N late khớp golden file order-by-order |
| Tiền điều kiện | Filter chuẩn |
| Steps | 1. Export table top N<br>2. Match từng row với golden |
| Expected | Top N match ≥ 90% rows; column values match exact |
| Actual | |
| P/F | |
| Severity | Major |

### UAT-{slug}-011 (lớp D)

| Field | Value |
|---|---|
| Mục đích | Click vào 1 row → drill qua Order Monitor < 2s |
| Tiền điều kiện | |
| Steps | Click 1 row → đo thời gian load Order Monitor |
| Expected | Load < 2s, params đúng order code |
| Actual | |
| P/F | |
| Severity | Minor |

## 7. Edge cases (cross-layer)

### UAT-{slug}-012 (lớp B, edge)

| Field | Value |
|---|---|
| Mục đích | Verify timezone cutoff UTC+7 — đơn 23:30 UTC+7 hôm nay có nằm trong "hôm nay" không? |
| Tiền điều kiện | Có đơn test gần cutoff |
| Steps | Filter date=hôm nay → check đơn 23:30 có trong list |
| Expected | Có; nếu là 00:30 hôm sau thì KHÔNG có |
| Actual | |
| P/F | |
| Severity | Major |

### UAT-{slug}-013 (lớp B, edge)

| Field | Value |
|---|---|
| Mục đích | Đơn không có POD/InFull data — exclude khỏi tử số không? Đếm vào mẫu số không? |
| Tiền điều kiện | |
| Steps | Tạo đơn test không POD, check số dashboard có đổi không |
| Expected | Theo định nghĩa khách (đã ghi PRD) |
| Actual | |
| P/F | |
| Severity | Critical (nếu sai định nghĩa) |

### UAT-{slug}-014 (lớp D, edge)

| Field | Value |
|---|---|
| Mục đích | Filter combo phức tạp (NPP × kho × channel × time window) response < 3s |
| Tiền điều kiện | |
| Steps | Combo 5 filter cùng lúc, đo time |
| Expected | < 3s |
| Actual | |
| P/F | |
| Severity | Minor |

---

## Tóm tắt

| Metric | Value |
|---|---|
| Tổng TC | `<N>` |
| Happy path | `<N>` |
| Edge case | `<N>` |
| Lớp A | `<N>` |
| Lớp B | `<N>` |
| Lớp C | `<N>` |
| Lớp D | `<N>` |
