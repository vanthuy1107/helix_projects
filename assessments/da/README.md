# DA Assessment — Smartlog Control Tower

Bộ artifact dùng để **đánh giá ứng viên Data Analyst (1-2 năm kinh nghiệm)** hỗ trợ dự án Smartlog Control Tower.

**Status**: Active
**Created**: 2026-05-16
**Owner**: PM/BA/DA team
**Internal use only** — KHÔNG share toàn bộ folder cho candidate; chỉ share `dataset/` (trừ `_internal/`) và `test/assessment.md`.

---

## Mục tiêu

Tuyển 1 DA 1-2 YOE có thể:
- Đọc/clean dataset thô từ logistics ops, tự profile và phát hiện anomaly.
- Viết SQL aggregation + window function cơ bản, hoặc pandas/Excel tương đương.
- Định nghĩa và tính được các KPI logistics: OTIF, On-time, In-full, VFR (loading rate), carrier performance.
- Trình bày finding cho stakeholder business (SC Manager, không phải dev).
- Có "óc đặt câu hỏi" — không chỉ trả số mà còn quan sát pattern, nêu giả thuyết.

---

## Cấu trúc folder

```
projects/assessments/da/
├── README.md                          # File này — KHÔNG share candidate
├── dataset/
│   ├── README.md                      # Schema mô tả AcmeFoods — share candidate
│   ├── shipments.csv                  # Fact: OTIF (anonymized)
│   ├── trips.csv                      # Fact: VFR operation (anonymized)
│   ├── carriers.csv                   # Dim: nhà vận tải (anonymized)
│   ├── locations.csv                  # Dim: kho + khu vực giao
│   ├── products.csv                   # Dim: brand + cargo group
│   └── _internal/                     # KHÔNG share candidate
│       ├── extract.sql                # Query trên ClickHouse analytics_workspace
│       ├── anonymize.py               # Script đổi MDLZ → AcmeFoods
│       └── mapping.csv                # MDLZ ↔ fake (sinh khi chạy anonymize.py)
└── test/                              # Chỉ share assessment.md cho candidate
    ├── assessment.md                  # File bài test giao candidate
    ├── rubric.md                      # Thang chấm nội bộ
    └── reference-findings.md          # Insight kỳ vọng để chấm nhanh
```

---

## Workflow chạy bài test

### Phase 1 — Chuẩn bị dataset (1 lần)

1. Chạy `dataset/_internal/extract.sql` trên ClickHouse Mondelez (stack `analytics_workspace`).
   Output: 5 file CSV thô trong `dataset/_internal/raw/`.
2. Chạy `python dataset/_internal/anonymize.py`.
   Output: 5 file CSV anonymized trong `dataset/` + `mapping.csv` nội bộ.
3. **Sanity check bắt buộc** trước khi share:
   ```bash
   grep -ril -E 'mondelez|mdlz|oreo|cadbury|tang' dataset/*.csv
   # → expected: 0 hit
   ```
4. Verify row count + sample data còn meaningful (xem `dataset/README.md` § Sanity).

### Phase 2 — Mỗi vòng phỏng vấn

1. Share zip `dataset/*.csv` (KHÔNG `_internal/`) + `test/assessment.md` cho candidate.
2. Candidate có 2-3 giờ làm bài (take-home).
3. Candidate submit: file phân tích (notebook / Excel / PDF / BI dashboard export) + ít nhất 1 chart + narrative.
4. Reviewer chấm theo `test/rubric.md`, đối chiếu nhanh với `test/reference-findings.md`.

### Phase 3 — Sau test

- Discuss live 30 phút (candidate present findings).
- Nếu pass: chuyển qua interview kỹ thuật sâu hơn.

---

## Tiêu chí pass/fail (preview, chi tiết xem `test/rubric.md`)

| Mức | Tổng điểm | Hành động |
|---|---|---|
| Excellent | ≥ 85/100 | Strong yes — fast-track |
| Good | 70-84 | Yes — proceed to live discussion |
| Borderline | 55-69 | Conditional — depends on live discussion |
| Fail | < 55 | No |

**Red flags auto-fail** bất kể điểm:
- Đưa hypothesis như fact, không phân biệt được "số nói gì" vs "tôi đoán".
- Bỏ qua data quality issue hiển nhiên (vd row trùng, ngày NULL, status không hợp lệ).
- Không filter được `DeletedTime` / record trạng thái invalid.
- Recommendation chung chung kiểu "cần cải thiện performance" mà không có WHO/WHAT/đo bằng gì.

---

## Notes

- Dataset là **snapshot anonymized** — KHÔNG dùng cho phân tích thực sự, chỉ dùng phỏng vấn.
- Refresh mapping mỗi 6 tháng hoặc khi có thay đổi schema lớn.
- Nếu candidate hỏi về business context, share file `dataset/README.md` (đã viết theo persona AcmeFoods).
