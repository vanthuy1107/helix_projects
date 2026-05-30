# PRD — Section Tender Response: Tỷ lệ đáp ứng chuyến gửi thầu

| Trường | Giá trị |
|--------|---------|
| **Version** | 1.0.0 |
| **Ngày** | 2026-05-30 |
| **Trạng thái** | Canonical baseline — dựng từ glossary + reference + MV DDL (frontend chưa trace được local) |
| **Tác giả** | PM/DA via `/da-trace` |
| **Phạm vi** | `01-sections/tender-response` — widget `WidgetTenderResponse` trên dashboard / Grafana tenant Mondelez |
| **Widget code** | `WidgetTenderResponse` · i18n namespace `orderMonitor.tenderResponse` |
| **FormConfig** | `DSHTNDDTG01`, `DSHTNDDTG02` (xem [glossary/01-widgets.md](../../glossary/01-widgets.md)) |
| **Materialized View** | `analytics_workspace.mv_dap_ung_gui_thau` (REFRESH EVERY 1 HOUR) |
| **Reference cũ** | [`05-reference/[done] ty_le_dap_ung_va_tuan_thu/tender-response-rate.prd.md`](../../05-reference/%5Bdone%5D%20ty_le_dap_ung_va_tuan_thu/tender-response-rate.prd.md) (hệ Smartlog Control Tower cũ — xem mục Drift) |

> **Lưu ý nguồn**: Repo frontend không có mặt trong workspace local nên section này **không trace được code widget hiện hành** (khác cách `late-order-alert` được dựng). Nội dung dưới đây là **canonical từ glossary + reference + DDL ClickHouse + sql-registry đã verify**. Khi có frontend, cần soát lại bằng `/da-trace` để nâng trạng thái lên "Observed baseline".

---

## 1. Mục đích

Section **Tender Response** đo **tỷ lệ đáp ứng chuyến gửi thầu** — mức độ mà một chuyến gửi thầu (tender) được vận hành **đúng 1:1** theo kế hoạch ban đầu, không bị **gom** (nhiều tender vào 1 chuyến vận hành) hay **tách** (1 tender ra nhiều chuyến vận hành).

Đây là dashboard **đánh giá chất lượng lập kế hoạch & tuân thủ vận hành của nhà vận tải (NVT)** — trả lời câu hỏi: *"Bao nhiêu % chuyến gửi thầu được thực hiện đúng như đã thầu?"*. Khác `VFR` (đo độ lấp đầy xe) và khác `OTIF` (đo đúng giờ/đủ đơn) — Tender Response đo **độ khớp giữa kế hoạch thầu và thực tế vận hành**.

---

## 2. Người dùng mục tiêu

| Vai trò | Nhu cầu chính |
|---------|--------------|
| Điều phối vận tải / Logistics | Theo dõi tỷ lệ chuyến gửi thầu được đáp ứng; phát hiện gom/tách bất thường theo kho, khu vực, NVT, thời gian |
| Quản lý Nhà vận tải (Carrier Management) | So sánh tỷ lệ đáp ứng giữa các NVT; nhận diện NVT yếu để làm cơ sở đánh giá Carrier Performance / điều chỉnh hợp đồng |
| Ban Lập kế hoạch vận hành | Đánh giá chênh lệch giữa kế hoạch gửi thầu và thực tế vận hành; cải thiện quy trình thầu |
| Lãnh đạo Chuỗi cung ứng (Mondelēz) | Theo dõi KPI tổng thể + xu hướng theo thời gian; ưu tiên NVT/kho/khu vực cần cải thiện |

---

## 3. Định nghĩa nghiệp vụ

### 3.1 Khái niệm cốt lõi

| Thuật ngữ | Định nghĩa | Trường MV |
|-----------|-----------|-----------|
| **Chuyến gửi thầu** (TenderMasterID) | ID kế hoạch gửi thầu — cấp tender | `id_chuyen_gui_thau` |
| **Chuyến vận hành** (MasterCode) | Mã chuyến vận hành thực tế — cấp operational | `id_chuyen_van_hanh` / `ma_chuyen_van_hanh` |
| **Đáp ứng** | Tender được vận hành đúng 1:1 (không gom, không tách) | `dap_ung_gui_thau` (Bool) |

### 3.2 Quy tắc xác định "được đáp ứng" — canonical

Một chuyến gửi thầu **được đáp ứng** khi đồng thời:

```text
COUNT(DISTINCT chuyến vận hành) theo 1 chuyến gửi thầu = 1   (không bị TÁCH)
AND COUNT(DISTINCT chuyến gửi thầu) theo 1 chuyến vận hành = 1  (không bị GOM)
```

Tương đương công thức đã precompute trong MV ([analytics-workspace_mvs.sql:1307](../../02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql)):

```sql
dap_ung_gui_thau = if(
  (cnt_id_chuyen_van_hanh >= 2) OR (cnt_id_chuyen_gui_thau >= 2),
  false,   -- bị gom hoặc tách → KHÔNG đáp ứng
  true     -- 1:1 → đáp ứng
)
```

| Trường hợp không đáp ứng | Điều kiện | Lý do |
|---|---|---|
| **Gom chuyến** | `cnt_id_chuyen_gui_thau >= 2` (nhiều tender chung 1 chuyến vận hành) | Gom nhiều TenderMasterID vào cùng MasterCode |
| **Tách chuyến** | `cnt_id_chuyen_van_hanh >= 2` (1 tender ra nhiều chuyến vận hành) | Một TenderMasterID bị tách ra nhiều MasterCode |

### 3.3 Điều kiện dữ liệu đầu vào (input filter của MV)

> Đã verify khớp 1:1 với reference §8.2 — implementation trong MV (`base_dt` + các INNER JOIN, [analytics-workspace_mvs.sql:1286-1370](../../02-data/data-sources/clickhouse-ddl/analytics-workspace_mvs.sql)).

| Điều kiện nghiệp vụ (reference) | Implementation MV | Khớp |
|---|---|---|
| `TenderMasterID <> Null` | `trip_tender_id != -1` | ✅ |
| `StatusOfDITOMaster = Đã hoàn thành` | `t.status_id > 98` | ✅ (cần xác nhận ngưỡng 98) |
| `LogiXeVanHanh GroupOfVehicleName <> Null` | `t.header_group_vehicle_sk != -1` | ✅ |
| `LogiXeGuiThau GroupOfVehicleName <> Null` | `tt.tender_group_vehicle_sk != -1` | ✅ |
| `ServiceOfOrderName = Xuất bán` | `o.service_code = 'XB'` | ✅ |

### 3.4 Đơn vị đo

Widget đếm **số chuyến gửi thầu** (distinct `id_chuyen_gui_thau`) và **số chuyến vận hành** (distinct `id_chuyen_van_hanh`). KHÔNG đo volume/CSE/tấn/CBM ở scorecard (các cột `tan_*`, `cbm_*` có sẵn trong MV nhưng phục vụ bảng chi tiết / phân tích phụ).

---

## 4. KPI Definitions

| # | KPI | Công thức | Nguồn |
|---|-----|-----------|-------|
| 1 | **% Tỷ lệ đáp ứng** (`% Tender Response`) | `Số chuyến gửi thầu đáp ứng / Tổng chuyến gửi thầu × 100` | MV `mv_dap_ung_gui_thau` — verified ([sql-registry §Fulfillment Ratio](../../02-data/data-sources/sql-registry.md)) |
| 2 | **Tổng chuyến gửi thầu** | `countDistinct(id_chuyen_gui_thau)` | MV |
| 3 | **Tổng chuyến vận hành** | `countDistinct(id_chuyen_van_hanh)` | MV |
| 4 | **Số chuyến gửi thầu đáp ứng** | `countDistinct(if(dap_ung_gui_thau = true, id_chuyen_gui_thau, NULL))` | MV |
| 5 | **Số chuyến gửi thầu không đáp ứng** | `countDistinct(if(dap_ung_gui_thau = false, id_chuyen_gui_thau, NULL))` | MV |

**Divide-by-zero**: `round(... / nullIf(countDistinct(id_chuyen_gui_thau), 0), 2)` → NULL; UI fallback `NULL → 0%`.

> **🚫 Open scope — `% Commit Response`**: glossary [02-kpis.md](../../glossary/02-kpis.md) liệt kê KPI thứ 2 `% Commit Response = (Số chuyến NVC commit / Tổng chuyến gửi thầu) × 100`. KPI này **chưa có** trong scope hiện tại của section này và **chưa có folder `commit-response-rate/`** ở `01-sections/`. Tồn tại MV anh em `analytics_workspace.mv_dap_ung_van_hanh` (lăng kính vận hành) có thể là nền cho metric này — **cần BA xác nhận** trước khi đưa vào (xem [99-discrepancies.md](../../glossary/99-discrepancies.md) và Open Questions §8).

---

## 5. Functional Requirements

### 5.1 Scorecard tổng quan (MVP)
5 thẻ chính: **% Tỷ lệ đáp ứng** · Tổng chuyến gửi thầu · Tổng chuyến vận hành · Số đáp ứng · Số không đáp ứng. → FormConfig `DSHTNDDTG01`.

### 5.2 Tỷ lệ đáp ứng theo Nhà vận tải (mixed chart)
Trục X = NVT (`nha_van_tai`); cột = số đáp ứng / không đáp ứng; đường = % đáp ứng. Sắp xếp được theo % tăng/giảm. → so sánh Carrier Performance.

### 5.3 Tỷ lệ đáp ứng theo thời gian (mixed chart / time series)
Trục X = mốc thời gian (ngày/tuần/tháng theo `date_type`); cột = số đáp ứng / không đáp ứng; đường = % đáp ứng. → theo dõi xu hướng.

### 5.4 Phân tích theo Kho lấy hàng & Khu vực giao hàng
Ranking kho (`diem_nhan`/`ma_diem_nhan`) và khu vực (`khu_vuc_doi_xe`) theo % đáp ứng. Kết hợp được với filter NVT + thời gian.

### 5.5 Bảng chi tiết
Group theo chuyến vận hành; hiển thị mapping tender↔operational + loại đáp ứng + lý do không đáp ứng. Cột chi tiết: xem [tender-response-spec.md §4](tender-response-spec.md).

### 5.6 Xuất báo cáo
Full Access export bảng chi tiết (Excel/CSV) theo filter đang áp dụng, kèm cột **Loại đáp ứng** và **Lý do không đáp ứng**.

---

## 6. Filters

| Tên bộ lọc | Key / template var | Loại | Mặc định | Cột MV |
|---|---|---|---|---|
| Kho lấy hàng | `{{whseid}}` | Multi-select | ALL | `ma_diem_nhan` |
| Khu vực giao hàng | `{{area}}` | Multi-select | ALL | `khu_vuc_doi_xe` |
| Nhà vận tải | `{{transporter}}` | Multi-select | ALL | `nha_van_tai` |
| Loại ngày | `{{date_type}}` | Single-select | **ATA** (reference) | `ETA`→`eta_vh`, `ATA`→`ata_vh`, `Ngày gửi thầu`→`tender_date` |
| Khoảng thời gian | `{{from_date}}`, `{{to_date}}` | Date range | Tháng hiện tại | (theo `date_type`) |

**Quy tắc thời gian**: tối đa 12 tháng; vượt → cảnh báo *"Vui lòng chọn khoảng thời gian không vượt quá 12 tháng."*

> ⚠️ **Drift tiềm ẩn — default `date_type`**: reference ghi mặc định **ATA**, nhưng các widget order-monitor khác (vd late-order-alert) mặc định **`Ngày gửi thầu`**. Cần BA/PM chốt giá trị default cho tenant Mondelez (xem Open Questions).

---

## 7. Color / Status Coding

| Trạng thái | Màu | Điều kiện |
|---|---|---|
| Được đáp ứng | Green `#22c55e` | `dap_ung_gui_thau = true` |
| Không đáp ứng | Red `#ef4444` | `dap_ung_gui_thau = false` |
| % đáp ứng tốt | Green | ≥ ngưỡng mục tiêu (BA chốt — reference cũ không định nghĩa ngưỡng RAG cho metric này) |

> Reference Smartlog cũ có bộ status Excellent/Good/Needs Improvement/Critical dựa trên Response Rate + Response Time — **KHÔNG áp dụng** cho scope hiện tại (xem Drift §9).

---

## 8. Open Questions (block sign-off)

| # | Câu hỏi | Owner | Hạn |
|---|---|---|---|
| 1 | `% Commit Response` có thuộc scope tenant Mondelez không? Nếu có → tạo `01-sections/commit-response-rate/` (MV `mv_dap_ung_van_hanh`) hay thêm làm KPI thứ 2 ở section này? | BA | trước UAT |
| 2 | Default `date_type` = `ATA` (reference) hay `Ngày gửi thầu` (đồng bộ widget khác)? | BA/PM | trước build |
| 3 | Ngưỡng RAG cho `% Tỷ lệ đáp ứng` (target %)? | BA | trước build chart |
| 4 | Ngưỡng `status_id > 98` có đúng nghĩa "Đã hoàn thành" trên DWH Mondelez? | DA/Dev | khi audit SQL |

---

## 9. Drift so với reference cũ

| # | Drift | Chi tiết | Severity |
|---|---|---|---|
| 1 | Scope metric thu hẹp | Reference cũ có Acceptance Rate, Avg Response Time, Compliance Score, status Excellent/Good/Critical → **không** thuộc scope ClickHouse/Grafana hiện tại. Scope hiện tại chỉ là tỷ lệ đáp ứng dựa trên mapping 1:1 | Med |
| 2 | Terminology | "% Tender Response = số NVC **nhận thầu**" (glossary) gây hiểu nhầm — logic thực tế là **mapping 1:1 không gom/tách**, không phải "carrier accept tender" | Med |
| 3 | Field naming | Reference dùng `MasterCode`/`TenderMasterID`/`StatusOfDITOMaster`; MV dùng `id_chuyen_van_hanh`/`id_chuyen_gui_thau`/`status_id` — cần bảng mapping (đã đưa vào §3.3) | Low |

Chi tiết đầy đủ + claim matrix: xem trace report `projects/trace/tender-response-2026-05-30.md`.
