# Glossary — Mondelez (data-layer slice)

> ⚠️ **File này đã được di chuyển.**
>
> Glossary đầy đủ (cross-team BA ↔ DEV) hiện ở: [`projects/mondelez/glossary/`](../glossary/README.md)
>
> Cụ thể cho data layer (ClickHouse MVs, source tables): [`glossary/06-data-layer.md`](../glossary/06-data-layer.md).

---

Lý do di chuyển: glossary cần phục vụ cả BA, DEV, DA — không chỉ data layer. Đã tách thành folder `glossary/` ở project root để cấu trúc rõ ràng hơn.

Folder mới gồm:
- `README.md` — index + cách dùng
- `01-widgets.md` — widget ↔ component ↔ MV mapping
- `02-kpis.md` — KPI definitions + công thức
- `03-business-terms.md` — DO/SO/CSE/ETA/NVC/...
- `04-status-enums.md` — status values + color codes
- `05-master-data.md` — Mondelez warehouses, brands, areas
- `06-data-layer.md` — ClickHouse MVs + source tables (nội dung cũ của file này thuộc đây)
- `99-discrepancies.md` — mismatch giữa docs và code đang chờ xử lý
