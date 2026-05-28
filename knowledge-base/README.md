# Knowledge Base — WMS & TMS (theo view)

Tài liệu tham chiếu mô tả các **view / báo cáo** của hai hệ thống nguồn Smartlog:

- **TMS** — Transport Management (host `api-stm-*`, client `STM`)
- **WMS** — Warehouse Management

KB này **product-level, cross-tenant** — mô tả *định nghĩa* report của hệ thống, không phải số liệu của một tenant cụ thể.

## Cách tổ chức

```
knowledge-base/
├── tms/ | wms/
│   ├── README.md      # tổng quan hệ thống + catalog index các report
│   ├── _shared/       # kiến thức dùng chung mọi report
│   │   ├── filters.md
│   │   ├── date-params.md
│   │   └── endpoints.md
│   └── reports/
│       └── {số}-{slug}/
│           ├── {số}-{product}-{slug}.md       # spec nghiệp vụ
│           ├── {số}-{product}-{slug}.api.md   # API contract
│           └── samples/                       # payload mẫu (ĐÃ xóa token)
```

## Convention

- **Mỗi view = 1 folder** trong `reports/`, tên `{số}-{slug}` (số = `TypeExport`, để sort theo số).
- **Tên file** self-describing: `{số}-{product}-{slug}.md` (vd `25-tms-trip-and-order.md`).
- **KHÔNG commit secret**: payload mẫu phải xóa `Authorization: Bearer ...` và mọi token trước khi lưu.
- Kiến thức lặp lại giữa các report (bộ filter, enum ngày, endpoint) → tách vào `_shared/`, report chỉ tham chiếu.

## Thêm 1 report mới

1. Tạo folder `reports/{số}-{slug}/`.
2. Copy skeleton từ một report đã có.
3. Thêm 1 dòng vào bảng catalog trong `{product}/README.md`.
