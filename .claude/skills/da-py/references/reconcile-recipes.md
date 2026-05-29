# Reconcile recipes (pandas) — depth

> Reference của `da-py`. Recipe pandas để đối chiếu chéo 2+ nguồn. Kỹ thuật cross-check ở tầng SQL (4 kỹ thuật L6, 5 nhóm anomaly) → đọc [`.claude/skills/da-uat/references/data-audit-and-crosscheck.md`](../../da-uat/references/data-audit-and-crosscheck.md). File này lo phần biến kết quả SQL → DataFrame → bảng đối chiếu truy vết được.

---

## 0. Luật vàng trước khi merge

1. **Align grain trước** — rollup cả 2 nguồn về cùng cấp (đơn / chuyến / ngày). Không align = double-count.
2. **Align timezone** — quy cả 2 về cùng quy ước (UTC hoặc VN), ghi rõ vào output.
3. **Align scope** — cùng filter service (`mv_otif` chỉ `'Xuất bán'`), cùng window.
4. **Chỉ tin cột số đơn** khi 2 nguồn khác mẫu số của %. % chỉ tham khảo.

---

## 1. Rollup về cùng grain (chống double-count)

Đơn TMS có thể vào nhiều chuyến → mỗi dòng lặp `QuantityOrder`. Dùng `max` cho cột kế hoạch (không nhân bản), `sum` cho cột thực giao:

```python
tms_order = (tms.groupby(["OrderCode", "ngay"], as_index=False)
                .agg(kh=("QuantityOrder", "max"),       # max: chống double-count khi đơn nhiều chuyến
                     gn=("QuantityBBGN", "sum")))         # sum: sản lượng giao cộng dồn các chuyến
mv_order  = (mv.groupby(["so", "ngay"], as_index=False)
               .agg(don=("so", "count")))
```
Đơn `Failed` nếu **bất kỳ** dòng con Failed → `agg(failed=("is_failed", "max"))`.

---

## 2. Full-outer-join + cột Δ + cờ trạng thái

```python
m = (tms_order.rename(columns={"OrderCode": "code"})
     .merge(mv_order.rename(columns={"so": "code"}),
            on=["code", "ngay"], how="outer",
            suffixes=("_tms", "_mv"), indicator=True))

# Δ và cờ — CHỈ tin cột số đơn
m["don_tms"] = m["kh"].notna().astype(int)          # hoặc count thật theo bài toán
m["delta"]   = m["don_tms"].fillna(0) - m["don_mv"].fillna(0)

def flag(d):
    d = abs(d)
    return "🟢" if d == 0 else ("🟡" if d <= 2 else "🔴")
m["flag"] = m["delta"].map(flag)

# Lệch TẬP đơn (khác lệch số liệu) — phân loại riêng
m["chi_tms"] = m["_merge"].eq("left_only")
m["chi_mv"]  = m["_merge"].eq("right_only")
```

**Sanity sau merge**: kiểm row count không nở bất ngờ.
```python
assert len(m) <= len(tms_order) + len(mv_order), "merge nở row — kiểm key trùng"
```

---

## 3. Bảng đối chiếu theo ngày (output chính)

```python
by_day = (m.groupby("ngay")
          .agg(don_tms=("don_tms", "sum"),
               don_mv=("don_mv", "sum"),
               chi_tms=("chi_tms", "sum"),
               chi_mv=("chi_mv", "sum"))
          .reset_index())
by_day["delta"] = by_day["don_tms"] - by_day["don_mv"]
by_day["flag"]  = by_day["delta"].map(flag)
```
Xuất Markdown (tách khỏi code → file `.md`):
```python
print(by_day.to_markdown(index=False))   # cần `tabulate`
# hoặc: by_day.to_markdown("mondelez/02-data/audit-results/tms-vs-mv-otif-20260529.md", index=False)
```

---

## 4. Confusion matrix trạng thái (đơn giao nhau)

Chỉ trên đơn có ở **cả hai** nguồn (`_merge == "both"`), pivot label TMS × label MV:
```python
both = m[m["_merge"] == "both"]
cm = pd.crosstab(both["label_tms"], both["label_mv"], margins=True)
print(cm.to_markdown())
```
Đường chéo = đồng thuận; off-diagonal = lệch kết luận → drill top đơn lệch:
```python
mismatch = both[both["label_tms"] != both["label_mv"]]
top = mismatch.reindex(mismatch["tre_phut"].abs().sort_values(ascending=False).index).head(30)
```

---

## 5. Phân loại nguyên nhân lệch (biến "lệch" → "lệch vì X")

Đừng để con số lệch trần. Bucket lý do:
```python
def reason(row):
    if row["chi_mv"] and row.get("status_mv") == "Chờ":      return "chưa lên chuyến"
    if row["chi_tms"] and row.get("service_tms") != "Xuất bán": return "service khác scope MV"
    if row["delta"] != 0 and row.get("near_midnight"):       return "timezone giáp ranh ngày"
    return "cần điều tra"
m["reason"] = m.apply(reason, axis=1)
print(m.groupby("reason").size().to_markdown())
```
Mỗi bucket → quyết "Accepted (đã hiểu)" hay "Defect → handoff `/da-ch`".

---

## 6. Checklist trước khi báo reconcile xong

- [ ] Đã align grain (rollup về cùng cấp)
- [ ] Đã align timezone, ghi rõ quy ước vào output
- [ ] Đã align service scope + window
- [ ] Cột số đơn là trục kết luận; % chỉ tham khảo (ghi chú rõ)
- [ ] Row count sau merge không nở/co bất thường
- [ ] Đơn chỉ-A / chỉ-B đã phân loại nguyên nhân, không rớt im lặng
- [ ] Bảng đối chiếu export ra `.md` (tách khỏi code)
- [ ] Mandatory ending signals đầy đủ (`GRAIN`, `TIMEZONE`, `DATA_CONFIDENCE`...)
