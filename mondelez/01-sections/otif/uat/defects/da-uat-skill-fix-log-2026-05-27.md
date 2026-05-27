# Nhật ký sửa lỗi skill da-uat — 2026-05-27

> 5 lỗi phát hiện trong quá trình review Excel pack UAT cho section OTIF (tenant Mondelez).
> Tất cả đã fix trong các file template skill. Không bao gồm thay đổi dashboard hoặc MV — đó là track riêng.

---

## Lỗi 1 — Biên ngày: inclusive vs exclusive

### Triệu chứng

Yêu cầu lấy data từ 18/05 → 22/05, nhưng script lấy từ 18/05 → **23/05**. Tất cả row thừa ngày 23/05 đều có timestamp `2026-05-23 00:00:00`.

### Nguyên nhân gốc

SKILL.md dòng 273 chỉ ghi `{{from_date}} / {{to_date}} → date literals` — không quy định convention biên ngày. AI sinh script Python dùng convention exclusive-end (`timedelta(days=5)` → 23/05), rồi truyền vào registry SQL `BETWEEN toDate(from) AND toDate(to)` — vốn **inclusive** cả hai đầu. Kết quả: lấy thừa row ngày 23/05 lúc 00:00:00.

### Cách fix

**SKILL.md dòng 273** — thêm quy tắc rõ ràng:

> `to_date` là ngày cuối cùng CÓ trong kết quả, KHÔNG phải ngày đầu tiên bị loại. Ví dụ: window 18→22/05 thì `from_date='2026-05-18'`, `to_date='2026-05-22'`. KHÔNG dùng convention exclusive-end của Python `range()` / `timedelta`.

**SKILL.md bảng Common Mistakes** — thêm mục mới.

### Query kiểm chứng

```sql
-- Phải trả cùng số với dashboard
SELECT uniqExact(so)
FROM analytics_workspace.mv_otif
WHERE ontime_status != 'Không có dữ liệu STM'
  AND toDate(eta_giao_hang_cho_npp)
      BETWEEN toDate('2026-05-18') AND toDate('2026-05-22');
```

---

## Lỗi 2 — %OTIF tính bằng giao (intersection) thay vì cột pre-computed

### Triệu chứng

%OTIF trong Excel lệch so với dashboard, trong khi %Ontime và %Infull đều đúng.

### Nguyên nhân gốc

SKILL.md dòng 148 định nghĩa OTIF là `OnTime ∩ InFull = OTIF count`. AI sinh formula `COUNTIFS(ontime='Ontime', infull='Infull')` trong Excel.

Nhưng cột `otif_status` trong MV dùng **logic rounding khác** so với `infull_status`:

- `infull_status` dùng `round(toFloat64(...), 4)` — làm tròn 4 chữ số thập phân
- `otif_status` dùng **so sánh decimal thô** — không làm tròn

Hệ quả: 1 đơn có thể đạt `infull_status = 'Infull'` (giá trị sau rounding bằng nhau) nhưng **fail** phần infull check bên trong `otif_status` (giá trị thô khác nhau) → `otif_status = 'Failed OTIF'`.

### Cách fix

**SKILL.md dòng 148** — sửa thành:

> OTIF count dùng `otif_status = 'OTIF'` (cột pre-computed trong MV), KHÔNG dùng intersection.

**SKILL.md bảng Common Mistakes** — thêm mục mới.

### Query kiểm chứng

```sql
-- Tìm đơn mà intersection khác otif_status
SELECT so, ontime_status, infull_status, otif_status,
       sum_original_cse, sum_shipped_cse, sum_san_luong_giao_cse
FROM analytics_workspace.mv_otif
WHERE ontime_status = 'Ontime'
  AND infull_status = 'Infull'
  AND otif_status != 'OTIF';
```

### Lưu ý

Đây cũng là **lỗi không nhất quán ở tầng MV** — phần infull check bên trong `otif_status` nên dùng cùng `round(..., 4)` như `infull_status`. Fix MV là track riêng (thay đổi DDL), không nằm trong scope fix skill lần này.

---

## Lỗi 3 — Health Matrix dùng Kho group thay vì Kho code

### Triệu chứng

Trong Sheet 02 (Health Matrix), chiều Kho hiển thị `BKD1 = 0 đơn`, `VN831 = 0 đơn`, trong khi `NKD = 738 đơn` có vẻ đúng.

### Nguyên nhân gốc

SKILL.md dòng 206 ghi `Kho group`. AI viết COUNTIF trỏ vào cột C (Kho group) trong Detail Orders, nhưng lại liệt kê giá trị Kho code (BKD1, NKD, VN831) làm nhãn dimension.

- BKD1 (Kho code) tìm trong cột C nơi giá trị là "BKD" (Kho group) → không match → 0
- NKD trùng tình cờ vì code và group cùng tên → match nhưng chỉ là may mắn

Bằng chứng từ formula bar: `=COUNTIF('05 — Detail Orders'!C:C,$B14)`

### Cách fix

**SKILL.md dòng 206** — sửa `Kho group` thành `Kho code (whseid)`:

> Dùng cột Kho code (B) trong Detail Orders, KHÔNG dùng Kho group (C) — COUNTIF phải match đúng cột chứa giá trị dimension label.

**SKILL.md bảng Common Mistakes** — thêm mục mới.

---

## Lỗi 4 — Fail Reason dùng COUNTIF (1 điều kiện) thay vì COUNTIFS (2 điều kiện)

### Triệu chứng

Trong Sheet 03 (Fail Reason), phần Fail Ontime breakdown:
- SQL frozen (cột B): **200**
- Công thức Excel (cột C): **306**
- Dashboard (cột D): **200**

### Nguyên nhân gốc

SKILL.md dòng 207 ghi `COUNTIF trên Detail`. AI sinh formula:

```
=COUNTIF('05 — Detail Orders'!R:R,"Thiếu dữ liệu đăng ký dock")
```

Formula này đếm **mọi row** có text reason đó — kể cả row mà `ontime_status` không phải `'Failed Ontime'` (vd row `'Không có dữ liệu STM'` nhưng vẫn có giá trị `not_ontime_reason`). 106 row thừa là những đơn không thuộc diện failed.

### Cách fix

**SKILL.md dòng 207** — sửa `COUNTIF` thành `COUNTIFS` với yêu cầu 2 điều kiện:

> Bắt buộc 2 điều kiện: (1) reason column match bucket label VÀ (2) status column match trạng thái failed tương ứng (`ontime_status = 'Failed Ontime'` cho Fail Ontime, `infull_status = 'Failed Infull'` cho Fail Infull).

**SKILL.md bảng Common Mistakes** — thêm mục mới.

---

## Lỗi 5 — Timezone: skill dùng UTC+7, dashboard dùng UTC

### Triệu chứng

Số đơn theo ngày trong Excel Trend (Sheet 04) lệch so với dashboard. Tổng toàn window có thể khớp, nhưng đơn bị dịch giữa các ngày liền kề.

### Nguyên nhân gốc

MV lưu datetime dạng `DateTime64(3, 'UTC')`. Dashboard group theo ngày bằng `CAST(selected_date, 'Date')` — mặc định theo **UTC**.

Nhưng SKILL.md dòng 237 hướng dẫn:

> `toDateTime(col, 'Asia/Ho_Chi_Minh')` → Python datetime → strip tzinfo → ghi vào Excel

Điều này convert sang **UTC+7** trước khi ghi. Mọi đơn có ETA từ 17:00–23:59 UTC (= 00:00–06:59 hôm sau giờ VN) sẽ rơi vào **ngày khác nhau** giữa Excel và dashboard.

### Quyết định

Giữ **UTC** (khớp dashboard). Skill đã được cập nhật bỏ toàn bộ chuyển đổi UTC+7.

### File đã sửa

| File | Vị trí sửa |
|---|---|
| **SKILL.md** | Dòng 153, 223, 237–240, 273, 312, 398, 545 (6 vị trí + 1 mục Common Mistake mới) |
| **uat-cases.md** | Dòng 174–177 (test case timezone cutoff) |
| **uat-reconciliation.md** | Dòng 19, 45, 52–53, 62, 128 (time window + ví dụ root cause) |
| **reconciliation-method.md** | Dòng 53–54, 66 (filter alignment + phân loại diff) |

### File KHÔNG sửa (không có data-timezone ref)

- **uat-plan.md** — không cần thay đổi
- **uat-signoff.md** — không cần thay đổi
- **uat-execution-log.md** — giờ session (`HH:MM UTC+7`) giữ nguyên (thời gian thực tế họp, không phải timezone data)

### Lưu ý

Nếu nghiệp vụ sau này quyết định UTC+7 mới là timezone chuẩn cho vận hành tại Việt Nam, fix nên áp dụng vào **query dashboard** (`CAST(selected_date, 'Date')` → `toDate(selected_date, 'Asia/Ho_Chi_Minh')`) thay vì revert skill.

---

## Lỗi 6 (bổ sung — phát hiện khi re-extract từ ClickHouse 2026-05-27, track data/MV) — STM exclusion không nhất quán khi `ontime_status = NULL`

> Phát hiện khi connect ClickHouse re-extract lại Excel pack (sau khi đã fix #3/#4/#5). KHÔNG nằm trong 5 lỗi review gốc và KHÔNG do fix gây ra — fix #4 (COUNTIF → COUNTIFS) chỉ làm nó lộ ra ở bước reconciliation.

### Triệu chứng

- Detail sheet = **2.986 dòng** nhưng KPI Hero "Tổng đơn" (frozen) = **2.984**.
- Fail Reason bucket **"Warehouse Infull Failure"**: công thức Excel live (đếm từ Detail) = **9**, số frozen từ registry = **7**.

### Nguyên nhân gốc

Đúng **2 đơn** `8482509670` và `8482509801` có **`ontime_status = NULL`** (nhưng `infull_status = 'Failed Infull'`, `otif_status = 'Failed OTIF'`, `not_infull_reason = 'Warehouse Infull Failure'`, ETA nằm trong window).

Cả pack loại STM bằng predicate `ontime_status != 'Không có dữ liệu STM'`, nhưng hai nhánh xử lý NULL khác nhau:

- **Query frozen** (KPI `uniqExact(so)`, Fail Infull breakdown): predicate chạy độc lập → trong ClickHouse `NULL != 'x'` = NULL → row bị WHERE loại → **2.984 / bucket 7**.
- **Query Detail** (`run_detail`, có thêm 4 mệnh đề `if(arraySort(...) = ..., 1=1, col IN (...))` bypass + CASE date): cùng predicate nhưng 2 đơn NULL **vẫn lọt** → **2.986 / bucket 9** (đã xác nhận bằng cách chạy thẳng `run_detail()`).

→ Mọi slice chứa 2 đơn này sẽ lệch **+2** giữa công thức live (từ Detail) và số frozen (từ registry).

### Ghi chú quan trọng

Ghi chú "KPI vs Detail row count" trong header script `uat_otif_export.py` trước đây giải thích diff 2.986/2.984 là do **"1 SO split sang nhiều whseid"** — **SAI**. Thực tế 2.986 dòng = 2.986 SO duy nhất (không split); nguyên nhân thật là 2 đơn NULL `ontime_status`. → Đã sửa lại ghi chú này trong script.

### Đề xuất (track data/MV — CHƯA fix lần này)

Chuẩn hóa cách loại STM nhất quán toàn pack + xử lý NULL tường minh:
- Dùng `coalesce(ontime_status, '') != 'Không có dữ liệu STM'` ở mọi query, HOẶC thống nhất loại STM bằng đúng 1 field (cả registry lẫn Detail).
- Xác định nghiệp vụ: đơn có `ontime_status = NULL` (chưa chấm ontime) có thuộc scope OTIF report không.

### Query kiểm chứng

```sql
-- 2 đơn NULL ontime_status trong window
SELECT so, ontime_status, infull_status, otif_status, not_infull_reason
FROM analytics_workspace.mv_otif
WHERE toDate(eta_giao_hang_cho_npp) BETWEEN toDate('2026-05-18') AND toDate('2026-05-22')
  AND ontime_status IS NULL;

-- Chênh lệch do field dùng để loại STM
SELECT
  countIf(ontime_status != 'Không có dữ liệu STM') AS excl_by_ontime,  -- 2984
  countIf(otif_status   != 'Không có dữ liệu STM') AS excl_by_otif,    -- 2986
  countIf(ontime_status IS NULL)                   AS null_ontime      -- 2
FROM analytics_workspace.mv_otif
WHERE toDate(eta_giao_hang_cho_npp) BETWEEN toDate('2026-05-18') AND toDate('2026-05-22');
```

---

## Tổng kết

| # | Lỗi | Ảnh hưởng | Mức độ | File đã fix |
|---|---|---|---|---|
| 1 | Biên ngày inclusive vs exclusive | Lấy thừa 1 ngày data | Major | SKILL.md |
| 2 | OTIF intersection vs cột pre-computed | %OTIF lệch dashboard | Major | SKILL.md |
| 3 | Kho group vs Kho code | Health Matrix hiển thị 0 cho một số kho | Major | SKILL.md |
| 4 | COUNTIF vs COUNTIFS | Số fail reason bị thổi phồng | Major | SKILL.md |
| 5 | Timezone UTC+7 vs UTC | Số đơn theo ngày bị dịch giữa các ngày | Major | SKILL.md, uat-cases.md, uat-reconciliation.md, reconciliation-method.md |
| 6 | STM exclusion không nhất quán khi `ontime_status` NULL | Detail 2.986 vs KPI 2.984; Fail Infull bucket live 9 vs frozen 7 | Finding (track data/MV) | uat_otif_export.py (sửa ghi chú README sai) — **chưa fix data** |

Lỗi #1–#5 đã được thêm vào bảng **Common Mistakes** trong SKILL.md để phòng ngừa tái phát. Lỗi #6 là finding tầng data/MV (chưa fix), chờ quyết định chuẩn hóa STM exclusion.
