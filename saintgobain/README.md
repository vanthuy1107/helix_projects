# Saint-Gobain Project

Tài liệu triển khai dự án Saint-Gobain trên nền tảng Smartlog Control Tower.

## Cấu trúc

```
saintgobain/
├── README.md                # File này — thông tin dự án & liên hệ
├── 00-platform/             # Hạ tầng kỹ thuật: môi trường, deployment, runbook
├── 01-sections/             # Wireframe + PRD theo từng section/màn hình dashboard
│   └── warehouse-overview/  # TV dashboard giám sát vận hành kho real-time
│       ├── warehouse-overview-prd.md
│       ├── warehouse-overview-wireframe.md  (TBA)
│       ├── warehouse-overview-spec.md       (TBA — sau khi PRD approve)
│       └── analysis/                        (open-question resolution, audit notes)
├── 02-data/                 # Data layer: spec KPI, schema/MVs, glossary (TBA)
├── 03-build/                # Artifact triển khai: widgets, FormConfig, QueryConfig (TBA)
├── 04-requirements/         # Yêu cầu: backlog, decisions, TOBE, rollout plan, UAT (TBA)
└── scripts/                 # Python scripts tiện ích (TBA)
```

## Thông tin dự án

- **Khách hàng**: Saint-Gobain (Vietnam)
- **Loại hình**: Vật liệu xây dựng — kho hàng vận hành theo dây chuyền pre-picking → picking → dock loading
- **Môi trường Dev**: (TBA)
- **Môi trường Staging**: (TBA)
- **Môi trường Production**: (TBA)
- **Tenant ID**: (TBA)
- **Bắt đầu**: 2026-05

## Trạng thái

| Phase | Trạng thái | Ghi chú |
|-------|-----------|---------|
| **Idea / Mockup** | ✅ Done | `dashboard.html` ở project root — HTML demo cho TV dashboard duy nhất ("Digital View Logistics") |
| **PRD draft** | 🟡 In progress | `01-sections/warehouse-overview/warehouse-overview-prd.md` v0.1.0 — chứa nhiều OQ cần business confirm |
| **Wireframe** | ⏳ Pending | HTML mockup cần convert sang wireframe markdown chuẩn (sau khi PRD approve) |
| **Tech Spec** | ⏳ Pending | Sau khi PRD approve |
| **Build** | ⏳ Pending | |
| **UAT** | ⏳ Pending | |
| **Production** | ⏳ Pending | |

## Liên hệ

| Vai trò | Tên | Email / Phone |
|---------|-----|---------------|
| PO (Smartlog) | | |
| IT (Saint-Gobain) | | |
| Business Owner | | |
| WH Operations | | |

## Artifact tham chiếu

| Artifact | Path | Mục đích |
|----------|------|---------|
| Idea mockup (HTML) | [`dashboard.html`](dashboard.html) | Bản demo TV dashboard ban đầu — input cho PRD v0.1.0 |
| PRD section "Warehouse Overview" | [`01-sections/warehouse-overview/warehouse-overview-prd.md`](01-sections/warehouse-overview/warehouse-overview-prd.md) | Đặc tả nghiệp vụ section đầu tiên |
