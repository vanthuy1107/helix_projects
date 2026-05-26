# 3-Source Reconciliation Method (depth)

> Skill reference. Đọc khi cần hiểu sâu hơn về phương pháp đối chiếu số liệu 3 nguồn trong Mode A (thiết kế template) và Mode B (chạy dry-run).

---

## 1. Tại sao phải 3 nguồn, không phải 2

Phổ biến tâm lý "Dashboard khớp SQL là đủ" — sai lầm phổ biến nhất trong UAT BI.

| Cặp đối chiếu | Chứng minh được gì | KHÔNG chứng minh được |
|---|---|---|
| Dashboard ↔ SQL raw | Widget hiển thị đúng kết quả SQL ta viết | SQL có đúng nghiệp vụ khách không |
| SQL raw ↔ Golden file | SQL ra cùng số khách tính được | Widget hiển thị đúng SQL kia không |
| Dashboard ↔ Golden file | Số trên màn hình khớp số khách | Có thể đúng vì sai bù sai (SQL sai + widget hiển thị nhầm sai trùng) |

Chỉ khi **cả 3 cặp** khớp mới chứng minh được full chain: nghiệp vụ → SQL → widget = đúng.

Anti-pattern thực tế đã gặp:
- Dashboard hiển thị 88.2%, SQL trả 88.2% → "khớp, OK"
- Sau khi golden file khách đến: 87.0% → lệch 1.2pp
- Truy ngược: SQL có bug trong join condition, golden file đếm khác cách → cả 2 đều sai theo cùng 1 hướng

## 2. Cấu trúc golden file lý tưởng

Yêu cầu khách chuẩn bị 1 trong 3 dạng (ưu tiên theo thứ tự):

### 2.1. Dạng raw export + công thức (tốt nhất)

- Khách export raw orders/transactions theo cùng filter
- Khách document công thức tính từng metric trên data đó (vd "OTIF = đơn (delivery_time ≤ promised_time) AND (delivered_qty ≥ ordered_qty)")
- DA tự tính lại để verify, không phụ thuộc trust khách tính đúng

### 2.2. Dạng metric pre-computed (chấp nhận được)

- Khách cung cấp Excel với metric đã tính sẵn
- DA verify cross-check bằng cách yêu cầu khách cung cấp **kèm** breakdown — vd "Tổng = 12,450; in-full = 11,800; on-time = 11,500; OTIF = 11,000"
- Nếu khách KHÔNG cung cấp được breakdown khớp với formula khách → red flag, khách chưa nắm rõ định nghĩa của chính họ

### 2.3. Dạng báo cáo PDF cũ (chấp nhận với cảnh báo)

- Khách chỉ có báo cáo PDF từ hệ thống cũ
- DA OCR + manually parse → error-prone
- Phải xác nhận với khách: "đây là số chính thức của các anh chị đã dùng để báo cáo lên BOD chưa?"

## 3. Filter alignment — điểm dễ lệch nhất

Số lệch 80% là do filter chưa align, không phải logic sai. Trước khi đối chiếu phải lock cứng:

| Khía cạnh | Spec |
|---|---|
| Tenant scope | 1 tenant ID cụ thể, không "all tenant" |
| Time window | Format đầy đủ: `from=2026-05-25 00:00:00 UTC+7` `to=2026-05-25 23:59:59 UTC+7` |
| Timezone | Luôn UTC+7. Nếu DB lưu UTC → convert trong SQL |
| Include/exclude rules | Có đơn cancelled trong tổng không? Đơn return có đếm không? |
| Filter NULL handling | Đơn không có `delivery_time` được coi là late, hay loại khỏi mẫu số? |

Mỗi điểm trên phải document trong reconciliation matrix — không assume.

## 4. Diff classification

Khi diff vượt tolerance, root cause thường thuộc 1 trong 6 nhóm:

| Nhóm root cause | Triệu chứng | Action |
|---|---|---|
| **Timezone** | Diff đúng bằng số đơn 1 khoảng giờ giáp ranh | Sửa SQL convert timezone |
| **Filter alignment** | Diff lớn (>5%), không pattern | Re-check filter cả 2 nguồn |
| **Include/exclude rule** | Diff = số đơn 1 status đặc biệt (cancelled / return / draft) | Sửa SQL WHERE clause |
| **NULL handling** | Diff ≈ số đơn có field NULL | Quyết định nghiệp vụ: COALESCE hay loại |
| **Formula mismatch** | Diff ở % metric, không ở count | Re-check formula vs PRD |
| **Data freshness** | Diff thay đổi khi re-run khác giờ | MV chưa refresh, đợi hoặc force refresh |

## 5. Tolerance — tại sao default 1% / 0.5pp

Theo kinh nghiệm Smartlog Control Tower + benchmarks BI:

| Metric type | Default tolerance | Lý do |
|---|---|---|
| Count tuyệt đối | ≤ 1% | Late events, status update delay tự nhiên trong 1 ngày — không ETL nào tránh được |
| % metric | ≤ 0.5pp | 0.5pp là threshold nhân loại nhận diện được change visually trên dashboard. Trên đó = khách sẽ tranh luận; dưới đó = noise |
| Ranking top N | ≥ 4/5 | Top 5 có 1 vị trí "biên" hay đổi do tie-breaking; 4/5 stable là dấu hiệu logic đúng |
| Amount tổng | ≤ 0.5% | Tiền nhạy cảm hơn count — khách thấy lệch 1% tiền sẽ phản ứng |

Override khi nào:
- **Khách siết** (đặc biệt số liệu tài chính): có thể về 0.1% / 0.1pp
- **Domain phức tạp** (vd shipment tracking với late events 7 ngày): có thể nới lên 2% / 1pp, nhưng phải document lý do trong plan

## 6. Khi golden file không khả thi

Một số tenant chưa có baseline nội bộ → không golden file. Phương án:

| Tình huống | Phương án thay thế |
|---|---|
| Tenant chưa từng track metric này | Đẩy lớp B (Business Logic) lên trước. Lấy SQL raw làm chuẩn. Khách verify công thức trên 5-10 đơn cụ thể (manual trace) thay vì tổng. |
| Tenant có data trong 1 hệ thống cũ nhưng không export được | Yêu cầu khách screenshot 5-10 màn hình hệ thống cũ + xin license đọc. Reconcile từng row được capture. |
| Tenant từ chối share data với Smartlog | UAT chỉ chạy lớp B + C + D, lớp A skip. Document rõ trong plan + signoff "không reconcile lớp A do khách không cung cấp baseline". |

**KHÔNG bao giờ**: Pass lớp A reconciliation mà không có nguồn baseline độc lập. Nếu không có golden → đánh dấu "A skipped" không phải "A pass".

## 7. Re-running reconciliation

Mỗi lần re-run (dry-run lại / retest) — số có thể đổi nhẹ:

| Nguyên nhân đổi số | Có chấp nhận được? |
|---|---|
| MV refresh giữa 2 lần run | Yes, document timestamp run |
| Late event update (đơn đến muộn data flow) | Yes, document |
| Dev fix logic giữa 2 lần | Yes, expected |
| Filter khác (vô tình) | NO, re-align filter |
| Time window không lock cứng (vd "hôm nay" rolling) | NO, đổi sang absolute date |

Best practice: lock time window thành **absolute date** sau ngày đầu UAT để mọi run lặp lại ra số cùng nguồn truth. Tránh dùng "hôm nay" / "7 ngày gần nhất" rolling.

## 8. Output rò rỉ

Khi present reconciliation matrix cho khách (trong session hoặc signoff), che hoặc bóc:
- Tên column/MV/table internal (`mv_psv_main`, `logging.activity`...)
- Connection string, tenant DB name
- SQL query body — chỉ show kết quả

Audience khách = nghiệp vụ, không phải DBA. Technical artifact dành cho phụ lục nội bộ.
