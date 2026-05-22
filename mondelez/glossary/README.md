# Glossary — Mondelez Control Tower

**Mục đích:** Đồng bộ ngôn ngữ giữa BA / PM / DA và DEV. Khi trao đổi về 1 widget, KPI, status, view... cả hai bên dùng **cùng 1 tên gốc** (canonical name) để tránh hiểu nhầm.

**Phạm vi:** Dự án Mondelez triển khai trên Smartlog Control Tower (TMS = STM, WMS = SWM, Analytics = ClickHouse).

---

## Cách dùng

- **BA viết PRD/spec** → tra `01-widgets.md` để lấy đúng tên widget, `02-kpis.md` để lấy đúng công thức KPI, `03-business-terms.md` để dùng đúng từ nghiệp vụ.
- **DEV nhận task** → đọc cùng glossary để biết term này map sang component/MV/entity nào trong code.
- **Khi gặp term mới** → thêm vào file phù hợp trong cùng PR; KHÔNG tự đặt tên mới ngoài glossary.
- **Khi phát hiện mismatch** giữa docs và code → log vào `99-discrepancies.md` để cùng team xử lý.

---

## Cấu trúc

| File | Nội dung | Audience chính |
|------|---------|----------------|
| [`01-widgets.md`](01-widgets.md) | 16 widgets — tên nghiệp vụ ↔ slug folder ↔ React component ↔ ClickHouse MV ↔ FormConfig | BA + DEV (FE & BE) |
| [`02-kpis.md`](02-kpis.md) | Định nghĩa KPI: OTIF, Ontime, Infull, VFR, % Loose, % Xuất, ngưỡng màu sắc, công thức SQL | BA + DEV |
| [`03-business-terms.md`](03-business-terms.md) | Nghiệp vụ: DO/SO/CSE/PCE/PL, ETA/ATA/ETD, NVC/Tender/Trip, NPP/KA/MT/GT, Loose vs Full Pallet... | BA + DEV |
| [`04-status-enums.md`](04-status-enums.md) | OTIF status, Late Order Alert (7 trạng thái), Flash Daily status, SWM/STM status, color codes | BA + DEV (UI) |
| [`05-master-data.md`](05-master-data.md) | Kho (BKD/NKD/VN821/VN831), Brand (Oreo/Cosy/Solite...), Khu vực, Kênh bán, Nhóm hàng | BA + DA |
| [`06-data-layer.md`](06-data-layer.md) | ClickHouse MVs, source tables STM/SWM, refresh interval, master data MVs | DA + DEV (BE) |
| [`99-discrepancies.md`](99-discrepancies.md) | Mismatch giữa docs và code (e.g. PRD nói `mv_flash_report`, code dùng `mv_flrp_stm_data`) — cần đối soát | All |

---

## Quy tắc đặt tên (canonical naming convention)

Để tránh nhầm lẫn, mỗi khái niệm trong dự án đều có **đúng 1 canonical name** ở mỗi tầng. Ví dụ widget "Cảnh báo đơn trễ":

| Tầng | Canonical | Lưu ý |
|------|-----------|-------|
| Tên nghiệp vụ TV | Cảnh báo đơn trễ | Dùng trong PRD, training, customer comm |
| Tên nghiệp vụ EN | Late Order Alert | Dùng trong UI tiếng Anh, technical doc |
| Folder PRD | `late-order-alert/` | Trong `projects/mondelez/01-sections/` |
| React component | `WidgetLateOrderAlert` | Class/function name trong frontend |
| File component | `widget-late-order-alert.tsx` | kebab-case |
| i18n namespace | `orderMonitor.lateOrderAlert.*` | Frontend i18n |
| ClickHouse MV | `mv_alert_late_do` | snake_case + prefix `mv_` |
| FormConfig code | `DSHLOAMNG01` | 11 ký tự, format `DSH{WIDGET}{TYPE}{SEQ}` |

**Tránh:** dùng tên không nhất quán trong cùng 1 PR (ví dụ vừa gọi "Late Order", vừa gọi "Đơn trễ", vừa gọi "Late DO").

---

## Maintenance

- Mỗi khi thêm widget/KPI/status mới → cập nhật glossary trong cùng PR với code/PRD.
- Mỗi khi đổi tên (rename component, rename MV) → cập nhật glossary + flag trong `99-discrepancies.md` nếu cũ vẫn còn dùng.
- Review glossary mỗi sprint review (10 phút) — đảm bảo BA và DEV vẫn cùng ngôn ngữ.

**Owner:** PM/BA (squad1@gosmartlog.com)
**Last sync với codebase:** 2026-05-10
