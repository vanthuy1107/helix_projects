# WIREFRAME — Tender Response

| Trường | Giá trị |
|--------|---------|
| **Version** | 1.0.0 |
| **Ngày** | 2026-05-30 |
| **Trạng thái** | Canonical layout — dựng từ reference + PRD/spec hiện hành (chưa render từ frontend) |
| **PRD reference** | [tender-response-prd.md](tender-response-prd.md) |
| **Spec reference** | [tender-response-spec.md](tender-response-spec.md) |

---

## 1. Filter bar (sticky)

```
┌────────────────────────────────────────────────────────────────────────────┐
│ Bộ lọc Tỷ lệ đáp ứng chuyến gửi thầu                                       │
│ ┌──────────┬──────────────┬──────────────┬──────────┬──────────────────┐   │
│ │ Kho      │ Khu vực giao │ Nhà vận tải  │ Loại ngày│ Khoảng thời gian │   │
│ │ [▼ ALL ] │ [▼ ALL ]     │ [▼ ALL ]     │ [▼ ATA ] │ [📅 from → to]   │   │
│ │ multi    │ multi        │ multi        │ single   │ ≤ 12 tháng       │   │
│ └──────────┴──────────────┴──────────────┴──────────┴──────────────────┘   │
└────────────────────────────────────────────────────────────────────────────┘
```
- 3 multi-select: `whseid`, `area`, `transporter` — default ALL.
- 1 single-select `date_type`: `ETA` · `ATA` · `Ngày gửi thầu` — default **ATA** (⚠ xem PRD Open Q2).
- 1 date range: default tháng hiện tại, hard-limit 12 tháng.

---

## 2. Scorecard row (5 KPI)

```
┌─────────────────┬──────────────┬──────────────┬──────────────┬──────────────┐
│ 🎯 TỶ LỆ ĐÁP ỨNG│ Tổng chuyến  │ Tổng chuyến  │ Đáp ứng      │ Không đáp ứng│
│                 │ gửi thầu     │ vận hành     │              │              │
│     85.0 %      │   1,240      │   1,180      │   1,054      │     186      │
│   (lớn, navy)   │              │              │  green       │  red         │
└─────────────────┴──────────────┴──────────────┴──────────────┴──────────────┘
   ty_le_dap_ung    so_..gui_thau   so_..van_hanh   ..dap_ung      ..khong_dap_ung
```
- Thẻ % để lớn nhất (primary). 4 thẻ count nhỏ hơn.
- Nguồn: query `scorecard` (1 row, 5 cột) — [spec §3.1](tender-response-spec.md).

---

## 3. Mixed chart — Tỷ lệ đáp ứng theo Nhà vận tải

```
┌────────────────────────────────────────────────────────────────────────────┐
│ Tỷ lệ đáp ứng theo Nhà vận tải              [sort: % ▲/▼]                   │
│  số chuyến ┤                                                  ── % đáp ứng  │
│   300 ┤  ██                                                                 │
│   200 ┤  ██▓▓   ██                ●───────●                                 │
│   100 ┤  ██▓▓   ██▓▓   ██▓▓   ●───        ●──── ██▓▓                        │
│     0 ┼──██▓▓───██▓▓───██▓▓───────────────────██▓▓──────────────────────── │
│        NVT A   NVT B   NVT C   NVT D   NVT E   NVT F                        │
│        ██ đáp ứng   ▓▓ không đáp ứng   ●─ % đáp ứng (trục phải)             │
└────────────────────────────────────────────────────────────────────────────┘
```
- Cột stacked: `so_dap_ung` (green) + `so_khong_dap_ung` (red); đường: `ty_le_dap_ung_pct` (trục phải %).
- Sort theo % để đẩy NVT yếu lên đầu (exception-first).
- Nguồn: query `byVendor` — [spec §3.2] (⚠ chưa verify).

---

## 4. Mixed chart — Tỷ lệ đáp ứng theo thời gian

```
┌────────────────────────────────────────────────────────────────────────────┐
│ Xu hướng tỷ lệ đáp ứng              [ Ngày | Tuần | Tháng ]                 │
│  số chuyến ┤                                            ── % đáp ứng        │
│       ┤        ●─────●─────●                                                 │
│       ┤  ●────              ●─────●────●     (đường % – trục phải)           │
│       ┤ ██▓  ██▓  ██▓  ██▓  ██▓  ██▓  ██▓   (cột đáp ứng/không – trục trái) │
│       ┼──┬────┬────┬────┬────┬────┬────┬──────────────────────────────────  │
│        T1   T2   T3   T4   T5   T6   T7                                      │
└────────────────────────────────────────────────────────────────────────────┘
```
- Bucket theo `date_type` đã chọn; mặc định tháng hiện tại.
- Nguồn: query `byTime` — [spec §3.3] (⚠ chưa verify). Grafana: dùng `$__timeFilter`.

---

## 5. Bảng chi tiết (group theo chuyến vận hành)

```
┌────────────┬────────────┬──────────┬────────┬─────────┬──────────┬─────────────┬──────────────────────┐
│ Mã chuyến  │ ID gửi thầu│ NVT      │ Kho    │ Khu vực │ Ngày thầu│ Loại đáp ứng│ Lý do không đáp ứng  │
│ vận hành   │            │          │ lấy    │ giao    │ /ETA/ATA │             │                      │
├────────────┼────────────┼──────────┼────────┼─────────┼──────────┼─────────────┼──────────────────────┤
│ M001       │ T001       │ NVT A    │ BKD1   │ Mekong  │ 12/05    │ 🟢 Đáp ứng  │ —                    │
│ M002       │ T002,T003  │ NVT B    │ NKD    │ Đông NB │ 12/05    │ 🔴 Không    │ Gom 2 tender → 1 xe  │
│ M003,M004  │ T004       │ NVT C    │ VN821  │ Tây NB  │ 13/05    │ 🔴 Không    │ Tách 1 tender → 2 xe │
└────────────┴────────────┴──────────┴────────┴─────────┴──────────┴─────────────┴──────────────────────┘
   [ ⬇ Export CSV/Excel (theo filter hiện tại) ]   — Full Access only
```
- Cột `Loại đáp ứng`: 🟢 `dap_ung_gui_thau=true` / 🔴 `false`.
- Cột `Lý do`: derive từ `cnt_id_chuyen_gui_thau ≥ 2` (Gom) / `cnt_id_chuyen_van_hanh ≥ 2` (Tách).
- Cột ẩn mặc định: khối lượng (`tan_*`, `cbm_*`), loại xe, số xe/tài xế.

---

## 6. Empty / error / loading

| State | Hiển thị |
|---|---|
| Loading | skeleton scorecard + chart spinner |
| Empty (0 row) | scorecard = 0 / 0% (fallback `NULL→0`); chart + bảng hiển thị "Không có dữ liệu trong khoảng lọc" |
| Error | banner đỏ + nút thử lại; chart/bảng giữ empty state |
| Filter > 12 tháng | toast cảnh báo "Vui lòng chọn khoảng thời gian không vượt quá 12 tháng." |
