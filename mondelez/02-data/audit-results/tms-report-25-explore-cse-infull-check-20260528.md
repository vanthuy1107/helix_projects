# Analysis: CSE & In-full logic trong `tms_report_25_explore.ipynb`

**Date**: 2026-05-28
**Requested by**: PM/DA squad (kiểm tra trước khi đẩy notebook lên review)
**Tenant scope**: Mondelez
**Notebook**: [`mondelez/notebooks/tms_report_25_explore.ipynb`](../../notebooks/tms_report_25_explore.ipynb)
**Source table**: `analytics_workspace.mdlz_tms_report_25_trip_order` (bảng phẳng, không phải MV OTIF)

## Question
1. Trong notebook, "CSE" đang được tính theo logic nào? Nếu chỉ là rename → không cần xử lý riêng, chỉ dùng cột số lượng.
2. Logic In-full có đang so **kế hoạch vs thực giao** (đúng) hay **thực nhận vs thực giao** (sai)?

## Method
Grep toàn notebook tìm mọi tham chiếu `CSE`, `QuantityOrder`, `QuantityTransfer`, `QuantityBBGN`, `INFULL_EXPR`, `pct_infull`, `fill_rate`. So với từ điển cột ở cell L1 (line 1621-1627) để xác định ngữ nghĩa nghiệp vụ.

## Findings

### Bảng cột số lượng (cả 3 cùng đơn vị CSE)

| Cột | Nhãn nghiệp vụ | Non-null | Vai trò |
|---|---|---:|---|
| `QuantityOrder` | Số lượng kế hoạch | 100.0% | Plan |
| `QuantityTransfer` | Số lượng lấy (pickup ở kho) | 83.5% | Thực nhận từ kho — **không dùng trong Infull** |
| `QuantityBBGN` | Số lượng giao (BBGN tại điểm giao) | 83.5% | Thực giao |

### Findings table

| # | Type | Statement | Evidence |
|---|---|---|---|
| 1 | Fact | "CSE" trong notebook là **unit label** dán vào cột số lượng (`QuantityOrder` hiển thị thành "KH (CSE)", `QuantityBBGN` thành "Giao nhận (CSE)") — KHÔNG có cell nào tính CSE từ thành phần khác | [line 25](../../notebooks/tms_report_25_explore.ipynb#L25), [line 2775-2776](../../notebooks/tms_report_25_explore.ipynb#L2775-L2776), [line 14902-14903](../../notebooks/tms_report_25_explore.ipynb#L14902-L14903) |
| 2 | Fact | Notebook KHÔNG đọc `mv_otif_swm_stm_data` (chỗ có logic CSE join lô/expiry phức tạp đang bị regression — xem [s2-so-8482509466-cse-undercount-20260527.md](s2-so-8482509466-cse-undercount-20260527.md)). Notebook chỉ đọc bảng phẳng `mdlz_tms_report_25_trip_order` → `QuantityBBGN` đã là "giao CSE" trực tiếp | [line 16591](../../notebooks/tms_report_25_explore.ipynb#L16591), README `mondelez/notebooks/README.md` |
| 3 | Fact | Công thức Infull thống nhất 4 chỗ trong notebook: `QuantityBBGN >= QuantityOrder` (kèm guard `QuantityOrder > 0`) — tức **thực giao ≥ kế hoạch**, KHÔNG dùng `QuantityTransfer` | [line 5057](../../notebooks/tms_report_25_explore.ipynb#L5057), [line 2933-2934](../../notebooks/tms_report_25_explore.ipynb#L2933-L2934), [line 12935-12936](../../notebooks/tms_report_25_explore.ipynb#L12935-L12936), [line 14908-14910](../../notebooks/tms_report_25_explore.ipynb#L14908-L14910) |
| 4 | Fact | `QuantityTransfer` chỉ xuất hiện trong cell L1 (column inventory) và `QTY_COLS` setup; không xuất hiện trong bất kỳ công thức metric nào | grep `QuantityTransfer` → chỉ [line 105](../../notebooks/tms_report_25_explore.ipynb#L105), [line 1448](../../notebooks/tms_report_25_explore.ipynb#L1448), [line 1637](../../notebooks/tms_report_25_explore.ipynb#L1637) |
| 5 | Insight | Nhãn header `(CSE)` dễ gây hiểu lầm rằng CSE là metric tính được — thực tế chỉ là đơn vị của cột số lượng (giống Tấn/CBM là đơn vị khác cùng cột) | Bảng output `KH (CSE) / Giao nhận (CSE) / Chênh lệch / Trạng thái` |

## Recommendation

**Code change**: KHÔNG cần sửa logic (đã đúng cả 2 điểm).

**Cleanup nhãn hiển thị (ĐÃ APPLY 2026-05-28, 2 vòng):**

**Vòng 1** — bỏ "(CSE)" khỏi nhãn compound (display labels):
1. ✅ KPI: `'Sản lượng kế hoạch (CSE)'` → `'Sản lượng kế hoạch'`; `'Fill rate CSE'` → `'Fill rate'`
2. ✅ Rename dicts: `'KH (CSE)'` → `'Số lượng KH'`; `'Giao nhận (CSE)'` → `'Số lượng giao'`; `'SL giao (CSE)'` → `'Số lượng giao'`
3. ✅ Chart titles/legends: bỏ ` (CSE)` ở 4 chart + 2 legend
4. ✅ Print statements: `"Giao nhận theo CSE — ..."` → `"Giao nhận (số lượng) — ..."`
5. ✅ Thêm note "KHÔNG dùng `QuantityTransfer`" vào intro (line 25), L3.4 Infull (line 5057), L4 drilldown (line 13023), SQL comment (line 13046)

**Vòng 2** — purge toàn bộ CSE (user feedback: CSE là đơn vị thùng nhưng table không có column CSE → vẫn dễ misslead):
6. ✅ Bỏ luôn `"đơn vị CSE"` note ở 3 chỗ source còn sót (intro, column reliability, KPI print)
7. ✅ Rename internal SQL/DataFrame aliases: `kh_cse` → `kh_qty`, `giaonhan_cse` → `gn_qty`, `sl_tra_ve_cse` → `sl_tra_ve` (16 references across 4 cells, paired SQL↔Python)
8. ✅ Clear outputs trên 23 code cells để hết stale "(CSE)" trong rendered tables/charts. Notebook giảm từ 16,618 → 1,253 dòng

**Verify**: `grep -i cse` trên file → **0 match**. JSON valid (53 cells).

**Pending (chưa làm — optional cho lần sau):**
- Đồng bộ glossary `mondelez/02-data/glossary.md` & knowledge-base ([`bdcc207`](../../docs/knowledge-base/)): note rằng `QuantityOrder/Transfer/BBGN` là số lượng (Case-level), không cần label CSE.
- User rerun all cells để outputs mới được render với label clean.
- Cân nhắc tương tự cho `flash_daily_mtd_audit.ipynb` — chỗ đó CSE vẫn dùng đúng nghĩa là UOM (alongside KG/CBM/PL), chưa cần purge.

## Caveats

- Phân tích này chỉ đọc code, KHÔNG re-run notebook để verify số liệu. Số 99.1% fill rate hiển thị ở output L2 không kiểm chứng lại trong audit này.
- Phạm vi: chỉ notebook explore. Logic CSE trong production pipeline (`mv_otif_*`) là chuyện riêng và đang có bug đang điều tra ở [s2-so-8482509466-cse-undercount-20260527.md](s2-so-8482509466-cse-undercount-20260527.md) — không đồng nhất với notebook này.

---

ARTIFACT_PATH: `mondelez/02-data/audit-results/tms-report-25-explore-cse-infull-check-20260528.md` + `mondelez/notebooks/tms_report_25_explore.ipynb` (cleanup applied)
DATA_CONFIDENCE: High — đọc trực tiếp source code notebook, từ điển cột rõ ràng, 4 chỗ Infull đồng nhất.
NEXT_ACTION: User rerun notebook để outputs khớp source. Sau đó commit (hoặc gọi `/da-ship` nếu muốn gate-check trước commit).
