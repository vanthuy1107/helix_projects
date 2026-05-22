# Frontend Report Structure

> Bản đồ thư mục code phía frontend cho các báo cáo (widget/dashboard) trên Smartlog Control Tower.
> Dùng để tra cứu nhanh: "section X của Mondelez ứng với code nào?"
> Last synced: 2026-05-10 từ `frontend/src/features/dashboard/`

---

## 1. Cây thư mục tổng quát

Tất cả báo cáo đều nằm trong **một feature duy nhất**: [frontend/src/features/dashboard/](../../../frontend/src/features/dashboard/).

```
frontend/src/features/dashboard/
├── dashboard-view-page.tsx              # Trang xem dashboard (canvas chứa widget)
├── dashboard-list-page.test.tsx
├── dashboard-view-page.test.tsx
├── index.tsx                            # Entry / list page
│
├── api/                                 # API layer
│   ├── dashboard.api.ts                 # Axios calls
│   ├── query-keys.ts                    # TanStack Query Key Factory
│   └── schema.ts                        # Zod schemas (DTO + form)
│
├── contexts/
│   ├── cross-filter-context.tsx         # Cross-widget filtering
│   └── widget-toolbar-actions-context.tsx
│
├── data/                                # Mock & preset data
│   ├── dashboard-product-category.ts
│   ├── preset-pgi-report.ts
│   ├── preset-templates.ts
│   └── used-templates-store.ts
│
├── filters/                             # Filter logic (shared)
│   ├── date-ranges.ts
│   ├── filter-templates.ts
│   └── index.ts
│
├── hooks/
│   ├── use-column-aliases.ts
│   ├── use-create-from-preset.ts
│   ├── use-cross-filter-safe.ts
│   ├── use-dashboard-ai.ts
│   ├── use-dashboard-crud.ts
│   ├── use-dashboard-permissions.ts
│   ├── use-dashboard-shares.ts
│   ├── use-dashboard-widgets.ts
│   ├── use-widget-execution.ts
│   └── use-widget-query.ts
│
├── types/
│   └── index.ts
│
├── utils/
│   └── format-money-vn.ts
│
└── components/
    ├── ai/                              # AI Insights sidebar
    │   ├── ai-insight-card.tsx
    │   └── ai-sidebar.tsx
    │
    ├── detail/                          # Trang chi tiết widget (drill-down)
    │   ├── chart-detail-layout.tsx
    │   ├── chart-section.tsx
    │   ├── chart-time-comparison.tsx
    │   ├── chart-annotations-config.tsx
    │   ├── conditional-formatting-config.tsx
    │   ├── export-menu.tsx
    │   ├── metadata-panel.tsx
    │   ├── sql-panel.tsx
    │   └── summary-stats.tsx
    │
    ├── filters/                         # Filter UI dùng chung
    │   ├── chart-filter-panel.tsx
    │   ├── chart-filter-types.ts
    │   ├── filter-override-dialog.tsx
    │   └── filter-controls/
    │       ├── date-range-filter.tsx
    │       ├── multi-select-filter.tsx
    │       ├── numeric-range-filter.tsx
    │       └── text-search-filter.tsx
    │
    ├── layout/                          # Khung dashboard
    │   ├── dashboard-grid.tsx           # react-grid-layout canvas
    │   ├── dashboard-sidebar.tsx
    │   ├── dashboard-tabs.tsx
    │   ├── dashboard-toolbar.tsx
    │   └── empty-dashboard.tsx
    │
    ├── management/                      # CRUD dashboard / widget
    │   ├── add-widget-sheet.tsx
    │   ├── clone-dashboard-dialog.tsx
    │   ├── create-dashboard-dialog.tsx
    │   ├── edit-dashboard-dialog.tsx
    │   ├── kpi-widget-config-panel.tsx
    │   └── template-gallery-sheet.tsx
    │
    ├── sharing/
    │   ├── permission-badge.tsx
    │   └── share-dialog.tsx
    │
    └── widgets/                         # ★ NƠI CHỨA CÁC BÁO CÁO
        ├── widget-renderer.tsx          # Dispatcher: chọn widget theo type
        ├── widget-frame.tsx             # Khung chung (header, toolbar, resize)
        ├── widget-detail-page.tsx       # Trang chi tiết
        ├── widget-context-menu.tsx
        ├── widget-parameter-bar.tsx
        ├── widget-unconfigured.tsx
        ├── chart-export-menu.tsx
        ├── sql-filter-panel.tsx
        │
        ├── widget-chart.tsx             # Generic chart widget
        ├── widget-kpi.tsx
        ├── widget-kpi-gauge.tsx
        ├── widget-matrix-table.tsx
        ├── widget-metric.tsx
        ├── widget-narrative.tsx
        ├── widget-stat-list.tsx
        ├── widget-alert-summary.tsx
        ├── widget-shared.tsx
        │
        ├── shared/                      # Hạ tầng dùng chung cho widget
        │   ├── WidgetGrid.tsx
        │   ├── rounded-chart-tooltip.tsx
        │   ├── sql-settings-dialog.tsx
        │   ├── sql-widget-config.ts
        │   ├── sql-widget-helpers.ts
        │   ├── use-filter-config-save.ts
        │   └── widget-grid.types.ts
        │
        ├── matrix-table/                # Pivot/matrix engine (shared)
        │   ├── formula-engine.ts
        │   ├── inline-bar.tsx
        │   ├── matrix-cell.tsx
        │   ├── matrix-filter-bar.tsx
        │   ├── types.ts
        │   ├── use-matrix-filter.ts
        │   └── use-pivot-data.ts
        │
        ├── alert-summary/               # ▸ Section: Alert Summary
        │   ├── active-alert-list.tsx
        │   ├── severity-counts.tsx
        │   ├── types.ts
        │   └── use-alert-summary.ts
        │
        ├── daily-ops/                   # ▸ Section: Daily Operations
        │   ├── widget-daily-ops.tsx
        │   ├── daily-ops-settings-dialog.tsx
        │   ├── mock-data.ts
        │   ├── types.ts
        │   └── use-daily-ops-data.ts
        │
        ├── flash-report/                # ▸ Section: Flash Daily Report
        │   ├── widget-flash-daily.tsx
        │   ├── widget-flash-daily.columns.tsx
        │   ├── widget-flash-daily-detail.tsx
        │   ├── widget-flash-daily-settings-dialog.tsx
        │   └── flash-report-api.ts
        │
        ├── pgi-report/                  # ▸ Section: PGI Report
        │   ├── widget-pgi-report.tsx
        │   ├── widget-pgi-report-settings-dialog.tsx
        │   ├── pgi-report-api.ts
        │   ├── pgi-report-constants.ts
        │   └── pgi-shared.ts
        │
        ├── order-monitor/                               # ▸ Section group: Order monitoring (5 widgets)
        │   │                                            #   ⓘ Code thực tế FLAT — group dưới đây là logic view
        │   ├── order-monitor-api.ts                     # 🔗 API client dùng chung cho cả 5 widget
        │   │
        │   ├── ▸ late-order-alert/                      # Cảnh báo đơn trễ
        │   │   ├── widget-late-order-alert.tsx
        │   │   ├── widget-late-order-alert.columns.tsx
        │   │   └── widget-late-order-alert-settings-dialog.tsx
        │   │
        │   ├── ▸ otif/                                  # OTIF (On-Time In-Full)
        │   │   ├── widget-otif.tsx
        │   │   ├── widget-otif.columns.ts
        │   │   ├── widget-otif-detail.tsx
        │   │   └── widget-otif-settings-dialog.tsx
        │   │
        │   ├── ▸ shipping-progress/                     # Tiến độ xuất hàng
        │   │   ├── widget-shipping-progress.tsx
        │   │   ├── widget-shipping-progress.columns.ts
        │   │   ├── widget-shipping-progress-detail.tsx
        │   │   └── widget-shipping-progress-settings-dialog.tsx
        │   │
        │   ├── ▸ tender-response/                       # Tỷ lệ đáp ứng tuyến
        │   │   ├── widget-tender-response.tsx
        │   │   ├── widget-tender-response.columns.tsx
        │   │   ├── widget-tender-response-detail.tsx
        │   │   └── widget-tender-response-settings-dialog.tsx
        │   │
        │   └── ▸ vfr/                                   # VFR (Vehicle Fill Rate)
        │       ├── widget-vfr.tsx
        │       ├── widget-vfr.columns.ts
        │       ├── widget-vfr-detail.tsx
        │       └── widget-vfr-settings-dialog.tsx
        │
        └── wh-predict/                                  # ▸ Section group: Warehouse predictive (7 widgets)
            │                                            #   ⓘ Code thực tế FLAT — group dưới đây là logic view
            ├── wh-predict-api.ts                        # 🔗 API client dùng chung
            ├── widget-sql-settings-dialog.tsx           # 🔗 Dialog SQL chung cho nhóm
            │
            ├── ▸ copack/                                # Copack
            │   ├── widget-copack.tsx
            │   └── widget-copack-settings-dialog.tsx
            │
            ├── ▸ factory-inbound/                       # Nhập kho từ NM
            │   ├── widget-factory-inbound.tsx
            │   └── widget-factory-inbound-settings-dialog.tsx
            │
            ├── ▸ loose-picking/                         # Loose Picking
            │   ├── widget-loose-picking.tsx
            │   ├── widget-loose-picking.columns.ts
            │   ├── widget-loose-picking-detail.tsx
            │   └── widget-loose-picking-settings-dialog.tsx
            │
            ├── ▸ stock-type/                            # Cơ cấu loại tồn
            │   ├── widget-stock-type.tsx
            │   └── widget-stock-type-settings-dialog.tsx
            │
            ├── ▸ transfer/                              # Điều chuyển kho
            │   ├── widget-transfer.tsx
            │   └── widget-transfer-settings-dialog.tsx
            │
            ├── ▸ txn-move/                              # Transaction Move
            │   ├── widget-txn-move.tsx
            │   ├── widget-txn-move.columns.ts
            │   └── widget-txn-move-settings-dialog.tsx
            │
            └── ▸ wh-util/                               # WH Utilization
                ├── widget-wh-util.tsx
                ├── widget-wh-util.columns.tsx
                ├── widget-wh-util-detail.tsx
                └── widget-wh-util-settings-dialog.tsx
```

> **Chú ý về `▸` (logic view):** trong code thực tế, hai folder `order-monitor/` và `wh-predict/` đang để **flat** — tất cả file `widget-*.tsx` cùng nằm 1 cấp với `*-api.ts`. Nhóm `▸ <widget>/` ở trên **chỉ là logic view** để dễ hình dung từng báo cáo gồm những file nào (chính / columns / detail / settings dialog). Nếu sau này muốn refactor thành sub-folder thật, bảng mapping ở mục **2** sẽ phải cập nhật path.

---

## 2. Mapping: Section PRD ↔ Widget code

Bảng dưới đối chiếu mỗi section trong [`01-sections/`](../01-sections/) với entry-point file ở frontend.

| Section (PRD)                                                       | Widget folder           | Entry component                                                                                                                                                                              |
| ------------------------------------------------------------------- | ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [alert-summary](../01-sections/alert-summary/prd.md)                | `widgets/alert-summary` | [widget-alert-summary.tsx](../../../frontend/src/features/dashboard/components/widgets/widget-alert-summary.tsx)                                                                             |
| [daily-ops](../01-sections/daily-ops/prd.md)                        | `widgets/daily-ops`     | [widget-daily-ops.tsx](../../../frontend/src/features/dashboard/components/widgets/daily-ops/widget-daily-ops.tsx)                                                                           |
| [flash-daily](../01-sections/flash-daily/flash-daily-prd.md)        | `widgets/flash-report`  | [widget-flash-daily.tsx](../../../frontend/src/features/dashboard/components/widgets/flash-report/widget-flash-daily.tsx)                                                                    |
| [late-order-alert](../01-sections/late-order-alert/prd.md)          | `widgets/order-monitor` | [widget-late-order-alert.tsx](../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-late-order-alert.tsx)                                                         |
| [otif](../01-sections/otif/prd.md)                                  | `widgets/order-monitor` | [widget-otif.tsx](../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-otif.tsx)                                                                                 |
| [shipping-progress](../01-sections/shipping-progress/prd.md)        | `widgets/order-monitor` | [widget-shipping-progress.tsx](../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-shipping-progress.tsx)                                                       |
| [tender-response](../01-sections/tender-response/prd.md)            | `widgets/order-monitor` | [widget-tender-response.tsx](../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-tender-response.tsx)                                                           |
| [vfr](../01-sections/vfr/prd.md)                                    | `widgets/order-monitor` | [widget-vfr.tsx](../../../frontend/src/features/dashboard/components/widgets/order-monitor/widget-vfr.tsx)                                                                                   |
| [copack](../01-sections/copack/prd.md)                              | `widgets/wh-predict`    | [widget-copack.tsx](../../../frontend/src/features/dashboard/components/widgets/wh-predict/widget-copack.tsx)                                                                                |
| [factory-inbound](../01-sections/factory-inbound/prd.md)            | `widgets/wh-predict`    | [widget-factory-inbound.tsx](../../../frontend/src/features/dashboard/components/widgets/wh-predict/widget-factory-inbound.tsx)                                                              |
| [loose-picking](../01-sections/loose-picking/prd.md)                | `widgets/wh-predict`    | [widget-loose-picking.tsx](../../../frontend/src/features/dashboard/components/widgets/wh-predict/widget-loose-picking.tsx)                                                                  |
| [stock-type](../01-sections/stock-type/prd.md)                      | `widgets/wh-predict`    | [widget-stock-type.tsx](../../../frontend/src/features/dashboard/components/widgets/wh-predict/widget-stock-type.tsx)                                                                        |
| [transfer](../01-sections/transfer/prd.md)                          | `widgets/wh-predict`    | [widget-transfer.tsx](../../../frontend/src/features/dashboard/components/widgets/wh-predict/widget-transfer.tsx)                                                                            |
| [txn-move](../01-sections/txn-move/prd.md)                          | `widgets/wh-predict`    | [widget-txn-move.tsx](../../../frontend/src/features/dashboard/components/widgets/wh-predict/widget-txn-move.tsx)                                                                            |
| [wh-utilization](../01-sections/wh-utilization/prd.md)              | `widgets/wh-predict`    | [widget-wh-util.tsx](../../../frontend/src/features/dashboard/components/widgets/wh-predict/widget-wh-util.tsx)                                                                              |

---

## 3. Quy ước đặt tên (đúng theo code hiện tại)

| Pattern                                  | Vai trò                                          |
| ---------------------------------------- | ------------------------------------------------ |
| `widget-{name}.tsx`                      | Component chính render trên dashboard canvas     |
| `widget-{name}.columns.ts(x)`            | Cấu hình cột table/grid                          |
| `widget-{name}-detail.tsx`               | Trang chi tiết khi click vào widget              |
| `widget-{name}-settings-dialog.tsx`      | Dialog cấu hình widget (filter, tham số…)        |
| `{group}-api.ts`                         | API client cho cả nhóm (vd `order-monitor-api`)  |
| `use-{name}.ts`                          | Hook chuyên biệt cho widget                      |

---

## 4. Ghi chú điều hướng nhanh

- **Thêm widget mới**: bắt đầu từ [widget-renderer.tsx](../../../frontend/src/features/dashboard/components/widgets/widget-renderer.tsx) (dispatcher) và [add-widget-sheet.tsx](../../../frontend/src/features/dashboard/components/management/add-widget-sheet.tsx).
- **Filter dùng chung**: [components/filters/](../../../frontend/src/features/dashboard/components/filters/) — cả filter override dialog và filter controls (date/multi-select/numeric/text).
- **Layout / canvas**: [dashboard-grid.tsx](../../../frontend/src/features/dashboard/components/layout/dashboard-grid.tsx) — chứa `react-grid-layout`.
- **AI sidebar**: [components/ai/](../../../frontend/src/features/dashboard/components/ai/) — gọi backend AI insights.
- **SQL widget config / dialog**: [shared/sql-settings-dialog.tsx](../../../frontend/src/features/dashboard/components/widgets/shared/sql-settings-dialog.tsx) — base cho mọi widget driven bởi SQL.
- **Matrix table engine**: [matrix-table/](../../../frontend/src/features/dashboard/components/widgets/matrix-table/) — `use-pivot-data.ts` + `formula-engine.ts` là core; widget chính ở [widget-matrix-table.tsx](../../../frontend/src/features/dashboard/components/widgets/widget-matrix-table.tsx).

---

## 5. Cập nhật

File này được tạo thủ công từ snapshot thư mục. Nếu thêm/sửa widget, cập nhật:
1. Cây thư mục ở mục **1**.
2. Bảng mapping ở mục **2** (nếu là section mới của Mondelez).
