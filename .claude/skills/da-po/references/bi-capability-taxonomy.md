# BI Capability Taxonomy — 14 areas

Khung phân loại cố định dùng cho cả inventory (Mode A) và benchmark matrix (Mode B). Đừng tạo capability mới ngoài 14 area dưới đây — nếu thực sự thấy thiếu, đề xuất thêm vào skill này trước, KHÔNG hardcode trong từng catalog.

Mỗi area có 4 phần:
- **Định nghĩa** — capability này là gì
- **What good looks like** — tiêu chí "Deep" depth
- **Smartlog evidence paths** — path source code để bóc evidence
- **Anti-scope** — phần không thuộc area này (tránh double-count)

---

## 1. Data Connectors

**Định nghĩa**: Khả năng kéo data từ nguồn ngoài vào platform.

**What good looks like (Deep)**:
- 20+ connector built-in (RDBMS, warehouse, REST API, file, streaming)
- Schema introspection tự động
- Connector custom qua plugin/SDK
- OAuth / SSO cho data source

**Smartlog evidence paths**:
- `backend/src/Smartlog.Infrastructure/` (EF Core providers, Refit clients)
- `backend/src/Smartlog.Infrastructure/IDbContextResolver.cs` (multi-tenant connection)
- `backend/src/Smartlog.Application/**/Repositories/`
- `package.json` (FE: TanStack Query — nguồn data trên FE)

**Anti-scope**: Không tính cache, không tính query engine.

---

## 2. Data Modeling

**Định nghĩa**: Xây dataset semantic — joins, calculated fields, measures, metric registry.

**What good looks like (Deep)**:
- Star/snowflake schema designer visual
- Calculated columns + measures với DSL (DAX / LookML / SQL)
- Reusable metric definitions
- Lineage view giữa fields

**Smartlog evidence paths**:
- `backend/src/Smartlog.Domain/Entities/`
- `backend/src/Smartlog.Infrastructure/Migrations/`
- `backend/src/QueryConfigs/*.json` (relationship metadata)
- `projects/{tenant}/.../sql-registry.md` nếu có (metric documentation)

**Anti-scope**: Không tính raw SQL execution (thuộc area 3).

---

## 3. Query Engine / Semantic Layer

**Định nghĩa**: Engine biến intent người dùng → SQL/DAX/LookML và thực thi.

**What good looks like (Deep)**:
- Query optimizer push-down
- Multi-dialect (SQL, DAX, LookML, M)
- Semantic layer (1 metric defined once, dùng mọi nơi)
- Query cache transparent

**Smartlog evidence paths**:
- `backend/src/Smartlog.DynamicQuery/` (SqlKata + Fluid templates)
- `backend/src/QueryConfigs/*.json`
- ClickHouse `mv_*` materialized views (tenant-specific)

**Anti-scope**: Không tính storage / DB engine.

---

## 4. Visualization Library

**Định nghĩa**: Tập chart types + extensibility (custom viz).

**What good looks like (Deep)**:
- 30+ chart types out-of-box
- Custom viz qua marketplace / SDK
- Smart chart suggestion theo data shape
- Conditional formatting

**Smartlog evidence paths**:
- `frontend/src/components/widgets/*` (mỗi widget = 1 viz)
- `frontend/package.json` → recharts, monaco (chart libs)
- `frontend/src/components/widgets/index.ts` (registry)

**Anti-scope**: Không tính layout (area 5).

---

## 5. Dashboard / Canvas

**Định nghĩa**: Cách user assemble nhiều viz thành 1 dashboard.

**What good looks like (Deep)**:
- Drag-drop grid layout, responsive
- Drill-down / drill-through giữa viz
- Cross-filter giữa các viz
- Dashboard nested / linked
- Template gallery

**Smartlog evidence paths**:
- `frontend/src/features/dashboard/`
- `frontend/package.json` → react-grid-layout
- Sections như `flash-daily`, `vfr-late-alert`, `order-monitor`

**Anti-scope**: Không tính từng chart (area 4), không tính authoring no-code (area 7).

---

## 6. Filtering & Parameters

**Định nghĩa**: Cách user thu hẹp data view runtime.

**What good looks like (Deep)**:
- Global slicer + per-chart filter
- Cross-filter auto giữa charts
- Parameter điều khiển logic (e.g., date range slicer)
- URL-driven filter state (sharable)
- Filter dependency (cascading)

**Smartlog evidence paths**:
- `frontend/src/features/dashboard/filters/`
- `frontend/src/features/dashboard/hooks/WidgetFilterResolver*`
- `frontend/src/components/widgets/*/settings/` (per-widget overrides)

**Anti-scope**: Không tính query engine (area 3).

---

## 7. Self-service Authoring

**Định nghĩa**: User không code có tự tạo được dashboard / widget mới không.

**What good looks like (Deep)**:
- Drag-drop chart builder
- No-code dataset wizard
- Natural language → chart
- In-app SQL editor có autocomplete + lineage

**Smartlog evidence paths**:
- `backend/src/FormConfigs/*.json` (auto-generated form configs)
- `frontend/src/features/.../createEntityPage*`
- Admin Settings dialog flow (cho paste SQL vào widget)

**Anti-scope**: Không tính chart library (area 4).

---

## 8. Embedding & Sharing

**Định nghĩa**: Đưa dashboard ra ngoài platform — iframe, public URL, export.

**What good looks like (Deep)**:
- Embed iframe có row-level security pass-through
- Public URL với token expiry
- Export PDF / PNG / Excel pixel-perfect
- Scheduled email export

**Smartlog evidence paths**:
- `backend/src/Smartlog.Api/Controllers/Export*.cs`
- `backend/src/Smartlog.Infrastructure/Reporting/`
- FE: feature `share/` hoặc `export/` nếu có

**Anti-scope**: Không tính alerts (area 9).

---

## 9. Collaboration

**Định nghĩa**: Người dùng tương tác với nhau xung quanh data.

**What good looks like (Deep)**:
- Comments per chart / per cell
- @-mention + notification
- Subscriptions (gửi định kỳ)
- Alerts trên metric threshold
- Annotation trên chart

**Smartlog evidence paths**:
- `backend/src/Smartlog.Application/**/Notifications/`
- `backend/src/Smartlog.Infrastructure/EventBus/`
- `logging.activity` (audit, có thể bóc collaboration trace)
- FE: feature `notifications/`, `alerts/`

**Anti-scope**: Không tính embedding (area 8).

---

## 10. Governance & RBAC

**Định nghĩa**: Ai thấy gì, ai edit được gì.

**What good looks like (Deep)**:
- Role-based access control phân quyền theo workspace/folder/dataset
- Row-level security (RLS)
- Column-level masking
- Audit log
- Workspaces / multi-tenant isolation
- Data lineage + impact analysis

**Smartlog evidence paths**:
- `backend/src/Smartlog.Application/Authorization/`
- JWT claim `TenantDBConfiguration` (multi-tenant)
- `backend/src/Smartlog.Infrastructure/IDbContextResolver.cs`
- `logging.activity` (audit)
- `backend/src/QueryConfigs/*.json` (per-config permission)

**Anti-scope**: Không tính authentication (đó là IAM ngoài scope BI).

---

## 11. Performance & Scale

**Định nghĩa**: Tốc độ render với data lớn.

**What good looks like (Deep)**:
- In-memory column store (VertiPaq / Hyper)
- Materialized view auto
- Query result cache
- Incremental refresh
- Aggregation table fallback

**Smartlog evidence paths**:
- `backend/src/Smartlog.Infrastructure/Caching/`
- ClickHouse `mv_*` (MergeTree, materialized views)
- `backend/src/Smartlog.DynamicQuery/` (query plan)

**Anti-scope**: Không tính connectors (area 1).

---

## 12. AI / ML

**Định nghĩa**: Smart capability — NL query, anomaly, forecast, copilot.

**What good looks like (Deep)**:
- Natural language → chart / SQL
- Auto-insight ("Why did revenue drop?")
- Anomaly detection
- Forecasting built-in
- Copilot trong authoring

**Smartlog evidence paths**:
- `backend/src/Smartlog.Application/**/AI/` (nếu có)
- Tích hợp Claude API / OpenAI nếu có (check `package.json` BE + FE)
- Hiện trạng: phần lớn N/A trong Smartlog → ghi rõ

**Anti-scope**: Không tính ML model training pipeline thuần (đó là MLOps, ngoài BI).

---

## 13. Mobile / Responsive

**Định nghĩa**: Trải nghiệm trên màn nhỏ.

**What good looks like (Deep)**:
- Native iOS/Android app
- Mobile-optimized layout tự động
- Offline mode
- Touch gesture trên chart

**Smartlog evidence paths**:
- `frontend/src/components/ui/` (RTL-patched Shadcn → cũng có breakpoint Tailwind)
- `frontend/tailwind.config.*`
- Không có native mobile app → ghi rõ ✗

**Anti-scope**: Không tính responsive web design generic (mọi sản phẩm hiện đại đều có).

---

## 14. Pricing & Deployment Model

**Định nghĩa**: Cách vendor charge tiền + deploy.

**What good looks like (Deep)**:
- Pricing trong suốt (per-user, per-capacity)
- Self-hosted OSS option
- SaaS multi-region
- Free tier có nghĩa (>10 users / >X dashboard)
- Embedded license (per-tenant cho ISV như Smartlog)

**Smartlog evidence paths**:
- N/A — Smartlog là internal product, đang ở model "embedded multi-tenant per contract"
- Ghi rõ position: B2B SaaS, per-tenant, multi-tenant DB resolution qua JWT claim
- Đối thủ: ghi pricing page URL + tier

**Anti-scope**: Không tính governance (area 10).

---

## Scoring rubric per cell

Mỗi ô matrix `(area × vendor)` cần 2 trục:

| Trục | Giá trị | Định nghĩa |
|---|---|---|
| Presence | ✓ | Có, full-featured theo "what good looks like" |
| | ◐ | Có nhưng thiếu component chính |
| | ✗ | Không có hoặc chỉ là roadmap |
| Depth | Deep | Match ≥80% "what good looks like" |
| | Medium | Match 40–80% |
| | Shallow | Match <40% |
| | n/a | Không applicable (vd. Mobile cho OSS tự host) |

**Source bắt buộc**: mỗi cell phải có URL doc (đối thủ) hoặc code path (ta). Cell `Source: unverified` = blocker, không được handoff.
