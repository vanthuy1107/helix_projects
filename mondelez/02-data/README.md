# 02-data — Data Layer

Business logic theo từng KPI: cách tính theo góc nhìn khách hàng (TMS/WMS views) và cách xử lý kỹ thuật trên Clickhouse.

> **Nguyên tắc**: Khách hàng chỉ thấy lớp TMS/WMS. Lớp Clickhouse là nội bộ kỹ thuật.

## Nội dung

```
02-data/
├── glossary.md              # Khái niệm, KPI definitions, đặc thù dự án
└── clickhouse/              # Schema Clickhouse hiện tại (nội bộ kỹ thuật)
    ├── overview.md          # Tổng quan: databases, tables, kết nối
    ├── _template.md         # Template cho MV
    └── mv-<tên>.md          # Mỗi Materialized View là 1 file riêng
```

> Spec nghiệp vụ theo widget nằm ở `01-sections/<widget>/spec.md`

## Danh sách KPI Specs

| File | KPI | Trạng thái |
|------|-----|------------|
| | | |
