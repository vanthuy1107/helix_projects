# 05 — Master Data (Mondelez-specific)

Các giá trị danh mục riêng của khách hàng Mondelez. Khi DEV viết seed data, fixture test, hoặc filter mặc định → tra danh sách này để dùng đúng giá trị.

---

## Kho / Warehouses

| Whseid | Tên | Khu vực | Mô tả |
|--------|-----|--------|------|
| `BKD1` | BKD1 | TP HCM | Kho TP HCM chi nhánh 1 |
| `BKD2` | BKD2 | TP HCM | Kho TP HCM chi nhánh 2 |
| `BKD3` | BKD3 | TP HCM | Kho TP HCM chi nhánh 3 |
| `NKD` | NKD | Hà Nội | Kho Hà Nội |
| `VN821` | Kho ngoài BKD | TP HCM | Kho ngoài (3PL) phục vụ HCM |
| `VN831` | Kho ngoài NKD | Hà Nội | Kho ngoài (3PL) phục vụ HN |

**Default warehouse filter trên dashboard:** `BKD1, BKD2, BKD3, NKD` (4 kho chính).

⚠️ `VN821` / `VN831` hiện trả 0 rows trong MV `mv_loose_picking` — xem [`99-discrepancies.md`](99-discrepancies.md) (BUG-2 trong PRD loose-picking gốc).

---

## Brands (`brand` column trong `mv_stocktype`)

10 brands chính + `NULL`:

1. `Oreo`
2. `Cosy`
3. `Solite`
4. `AFC`
5. `Slide`
6. `KD`
7. `RITZ`
8. `Lu`
9. `Tết` (seasonal — bánh Tết)
10. `Other`
11. (NULL — chưa map)

---

## Khu vực / Areas (`area` / `khu_vuc_doi_xe`)

| Area | Mô tả |
|------|------|
| `Ho Chi Minh` | TP HCM nội thành |
| `South East` | Đông Nam Bộ |
| `Mekong 1` | Tây Nam Bộ — vùng 1 |
| `Mekong 2` | Tây Nam Bộ — vùng 2 |
| (... — bổ sung khi BA xác nhận đầy đủ list) | |

---

## Nhóm hàng / Cargo group (`group_of_cargo`)

| Mã | Tên đầy đủ | Mô tả |
|----|-----------|------|
| `FRESH` | Fresh | Hàng tươi |
| `DRY` | Dry | Hàng khô |
| `MOONCAKE` | Mooncake | Bánh trung thu (seasonal) |
| `POSM` | POSM | Tài liệu/vật phẩm trưng bày |
| `OFFBOM` | Off-BOM | Sản phẩm ngoài BOM |
| `PM` | PM | Sản phẩm khác (other) |
| `TEST` | Test | Hàng test |
| `EQUIPMENT` | Equipment | Thiết bị (không phải hàng bán) |

---

## Kênh bán hàng / Sales channels (`kenh_ban_hang` / `group_name`)

(Chi tiết list cần BA xác nhận với khách hàng — placeholder)

| Channel code | Mô tả |
|-------------|------|
| `NPP` | Nhà phân phối |
| `KA` | Key Account (chuỗi siêu thị lớn) |
| `MT` | Modern Trade (siêu thị, CVS) |
| `GT` | General Trade (chợ, tạp hóa) |
| ... | |

---

## Storer key

Trong `mv_stocktype` và một số MV khác có cột `storer_key`:

- `MDLZ` = Mondelez (single value đối với dự án này)

⚠️ Nếu sau này onboard khách thứ 2 lên cùng tenant → cần re-design filter.

---

## Tenant info

| Field | Value |
|-------|------|
| Tenant ID | (chưa fill — xem `README.md`) |
| Connection string source | JWT claim `TenantDBConfiguration` |
| ClickHouse database | `analytics_workspace` |
| TMS schema | `stm` |
| WMS schema | `swm` |

---

## Quy ước fill master data

- Khi BA viết seed/sample data trong PRD → dùng đúng giá trị ở trên.
- Khi DEV viết test fixture → dùng `BKD1`, `Oreo`, `Ho Chi Minh`, `DRY` làm default.
- Khi onboard kho/brand/area mới → cập nhật file này và flag trong PR.
