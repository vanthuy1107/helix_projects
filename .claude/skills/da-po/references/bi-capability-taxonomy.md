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

Mỗi ô matrix `(area × vendor)` cần **3 trục**. Presence/Depth trả lời *"platform CÓ gì"* (supply view); Ease trả lời *"user TRẢI NGHIỆM ra sao"* (demand view). Thiếu trục Ease = đánh giá nền tảng theo những gì nó SỞ HỮU mà bỏ qua những gì user thực sự CẢM NHẬN — và đó chính là lỗ hổng khiến các tool "nhiều tính năng nhưng khó dùng" bị chấm điểm cao hơn thực tế, còn các champion về usability (vd Metabase) bị chấm thấp hơn giá trị thị trường của họ.

| Trục | Giá trị | Định nghĩa |
|---|---|---|
| **Presence** | ✓ | Có, full-featured theo "what good looks like" |
| | ◐ | Có nhưng thiếu component chính |
| | ✗ | Không có hoặc chỉ là roadmap |
| **Depth** | Deep | Match ≥80% "what good looks like" |
| | Medium | Match 40–80% |
| | Shallow | Match <40% |
| | n/a | Không applicable (vd. Mobile cho OSS tự host) |
| **Ease** (cho persona X) | Easy | Persona mục tiêu hoàn thành tác vụ cốt lõi **ngay lần đầu, không cần training/docs**; click tối thiểu; default tốt; empty/error state dẫn dắt rõ |
| | Moderate | Hoàn thành được nhưng cần học, vài bước không hiển nhiên, đôi khi phải tra docs, hoặc cần mental-model của power user |
| | Hard | Cần người kỹ thuật/expert, code, tool ngoài, hoặc nhiều bước — persona mục tiêu bị kẹt |
| | n/a | Không có bề mặt user cho persona này (vd #14 pricing, infra backend-only) |

**Ease luôn chấm KÈM persona** (xem mục "Convenience personas & journeys" bên dưới). Cùng 1 capability có thể Easy cho persona này nhưng Hard cho persona khác — vd authoring widget mới: Easy cho frontend dev, Hard cho citizen analyst. Ghi rõ persona đang chấm, vd `Ease: Hard (P2)`.

**Phân biệt Ease với "UI polish"**: Ease KHÔNG phải "đẹp/xấu" (subjective — vẫn loại trừ). Ease là **đo được**: time-to-task, số click, learning curve, tỉ lệ self-serve thành công không cần hỗ trợ, chất lượng empty/error/recovery. Chỉ chấm Ease bằng evidence (luồng thao tác thực tế / code path / doc), KHÔNG bằng cảm tính thẩm mỹ.

**Source bắt buộc**: mỗi cell phải có URL doc (đối thủ) hoặc code path (ta). Cell `Source: unverified` = blocker, không được handoff.

---

## Convenience personas & journeys (trục thứ 3, cross-cutting)

> **Vì sao tách riêng mục này thay vì thêm "area #15 — Usability"?**
> Vì usability/convenience là **chất lượng cross-cutting của MỌI capability**, không phải 1 bucket tính năng riêng. Thêm nó thành area #15 sẽ lặp lại đúng lỗi category error mà nó đang sửa. Thay vào đó:
> 1. **Per-capability**: chấm trục **Ease** trên từng ô của ma trận 14×8 (đã định nghĩa ở rubric trên).
> 2. **Cross-cutting**: chấm **persona journeys** dưới đây — vì một phần lớn "sự thuận tiện" sống ở **khoảng-giữa các capability** (onboarding, learning curve, time-to-insight, hồi phục lỗi), không nằm gọn trong bất kỳ 1 capability nào.

### Personas (whose convenience?)

Cùng 1 nền tảng cho trải nghiệm rất khác nhau theo persona — phải chấm Ease/journey theo persona, không gộp.

| Persona | Là ai (Smartlog context) | Convenience nghĩa là gì với họ |
|---|---|---|
| **P1 — Business Consumer** | SC Manager, BOD, trưởng vận hành tenant | Time-to-insight, dễ hiểu (storytelling, plain language), exception nổi rõ, **không cần training** |
| **P2 — Citizen Author / Analyst** | DA / BA / PM (chính user của skill này) | Tự dựng view / hỏi ad-hoc / định nghĩa KPI mà không cần frontend dev; SQL editor + config-paste ergonomics; NL→SQL |
| **P3 — Tenant Admin / Embedder** | Tenant IT, rollout team | Onboard tenant mới, cấu hình embed + permission, dán SQL canonical vào widget settings, clone từ tenant có sẵn |

(P4 — field/mobile ops user: hiện được phục vụ qua screenshot Slack; out-of-primary-scope, khớp verdict IGNORE hiện hữu ở area #13 cho tới khi có customer signal.)

### Journeys (the "between-capabilities" convenience)

Mỗi journey là 1 tác vụ end-to-end thực tế. Chấm `Ease` (Easy/Moderate/Hard) cho **Smartlog** và cho **champion đối thủ liên quan**, kèm evidence + persona.

| Journey | Persona | Tác vụ | Capability liên quan (ghép từ 14 area) |
|---|---|---|---|
| **J1 — Time-to-first-insight** | P1 | Mở control tower → hiểu "hôm nay ổn không?" trong <30s, không cần ai giải thích | #5 Dashboard + #4 Viz + storytelling layout |
| **J2 — Self-serve a follow-up question** | P1→P2 | "Tại sao VFR rớt ở miền Bắc?" mà không cần gọi DA | #12 chat NL→SQL + #6 filter + #5 drill-through |
| **J3 — Author a new widget / metric** | P2 | Dựng 1 view phân tích mới từ đầu | #7 authoring + #4 viz + #3 query |
| **J4 — Onboard a new tenant** | P3 | Đưa tenant mới (vd Panasonic) lên, clone pattern từ Mondelez | #10 governance + #2 modeling + #11 MV setup |
| **J5 — Recover from empty / error / stale state** | tất cả | Filter trả rỗng / query lỗi / data cũ → user hiểu chuyện gì xảy ra & làm gì tiếp | #6 filter + #4 viz + freshness/as-of indicator |
| **J6 — Embed into tenant portal** | P3 | Nhúng dashboard vào portal của khách (integration time) | #8 embedding |

### Convenience gaps — namespace `CONV-NNN`

Gap về thuận tiện dùng namespace **riêng** `CONV-NNN` (KHÔNG trộn dải số với `GAP-NNN` capability gaps — tránh đúng kiểu namespace collision đã ghi nhận trong memory). Mỗi `CONV-NNN` vẫn theo đúng verdict framework (KEEP/CATCH-UP/LEAPFROG/IGNORE) + handoff `/da-discovery`, nhưng thêm 2 trường:

| Field | Nội dung |
|---|---|
| `conv_id` | `CONV-{NNN}` |
| `persona` | P1 / P2 / P3 (ai chịu thiệt) |
| `journey` | J1..J6 (tác vụ nào kẹt) |
| `gap_summary` | 1 câu: user khó/chậm ở đâu (KHÔNG phải "thiếu tính năng X" — mà "tốn N bước / cần DA / không tự làm được") |
| `evidence` | luồng thao tác thực tế / code path (ta) hoặc doc (đối thủ) |
| `relevance_to_logistics` | High / Medium / Low |
| `verdict` + `verdict_rationale` + `handoff_to` | như GAP-NNN |

**Lưu ý chấm điểm quan trọng**: một capability có thể `Presence ✓ / Depth Deep` nhưng `Ease Hard` — khi đó *moat về capability hẹp hơn nhiều so với những gì ma trận presence×depth gợi ý* cho persona đó. Luôn surface mâu thuẫn này (vd #7 Self-service: chat+notebook tồn tại đầy đủ → Deep, nhưng dựng widget mới vẫn cần code → Hard cho P2).

### Handoff downstream cho convenience

- `CONV-NNN` verdict CATCH-UP / LEAPFROG → `/da-discovery` (giống GAP-NNN).
- Khi đã frame xong và là vấn đề thiết kế UI/luồng → có thể handoff tiếp tới `/frontend-ux` (SaaS quality) hoặc `/da-storytelling-data` (narrative/layout) — đây là 2 skill *thực thi* convenience, còn `/da-po` chỉ *phát hiện & định verdict*.
