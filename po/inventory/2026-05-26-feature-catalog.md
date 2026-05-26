# Smartlog Control Tower — Feature Catalog (PO Inventory, 2026-05-26)

**Mode**: A (Inventory) · **Scan baseline**: `41b3863` (2026-05-22)
**Author**: `/da-po inventory` (squad1@gosmartlog.com)
**Branch**: `feat-vfr-late-alert`
**Output sibling**: `_latest.json`

## TL;DR — what we have

Smartlog Control Tower **đã không còn là "dashboard widgets cơ bản trên react-grid-layout"** như mô tả trong root `CLAUDE.md`. Snapshot này (lấy từ source code, không phải slide) cho thấy 1 platform analytics đầy đủ với 4 trục lớn:

1. **Dashboards + Widgets cố định** (8 widget types: alert-summary, daily-ops, flash-report, matrix-table, order-monitor, pgi-report, shared, wh-predict) trên `react-grid-layout` — vẫn là core delivery hiện tại.
2. **Chat-driven analytics** (NL → chart/SQL) với toàn bộ pipeline AI: ChatPipeline, GoldenSql, KnowledgeDocument/Chunk, EmbeddingCache, SemanticRegistry, ToolExecutionTrace, AnalysisRun, EvaluationRun.
3. **Notebook** (Jupyter-style với cell + revision + run + artifact) cho data analyst self-service.
4. **Monitor/Alert + ScheduledReport + Slack integration** — observability layer trên metric tenant.

Hệ thống cũng có: KPI Templates (industry benchmark + drilldown + goal config), Semantic layer (Dimensions/Metrics/Relationships/TestCase), LLM ops (Providers/Pricing/Usage/Budget/RateLimit), Error Graph (ErrorNode/Relation/Fix Pattern), Skills + UserMemory.

**Quan trọng cho roadmap:**

- Codebase **đã vượt khá xa** scope "BI dashboard cho logistics" thông thường — AI/LLM, semantic layer, eval harness, embeddings, golden SQL đã hiện diện ở mức entity + controller. Cần benchmark vs **PowerBI Copilot, Tableau Pulse, Looker AI** thay vì so với base BI.
- 2 trục chính vẫn còn ở **Beta**: chat-driven authoring + monitor evaluations — đây là vùng deserves CATCH-UP focus.
- Widget library hiện **không phải thư viện chart chung** mà là **8 widget logistics-specific** (daily-ops, flash-report, pgi-report, wh-predict, order-monitor). Đây là moat domain — phải defend trong benchmark.

---

## Catalog format

Mỗi feature có:
- `feature_id` — kebab-case slug, stable
- `name` — tên human-readable
- `bi_capability` — 1 trong 14 area (taxonomy)
- `maturity` — POC | Beta | GA
- `source_paths` — code path truy ngược (BE và/hoặc FE)
- `last_modified` — SHA + date (baseline `41b3863` cho lần scan đầu tiên; Mode D sẽ cập nhật per-feature)
- `owner_team` — đoán dựa controller + entity area
- `demo_route` — URL FE nếu xác định được
- `notes` — 1–2 dòng đặc biệt

**Total features cataloged: 47** (trải 13/14 capability bucket — area 14 Pricing là N/A vì product nội bộ).

---

## 1. Data Connectors

**What we have**: 1 feature.

| feature_id | name | maturity | source_paths | owner | notes |
|---|---|---|---|---|---|
| `data-sources` | Data Sources registry | GA | `backend/src/Smartlog.Api/Controllers/DataSourcesController.cs`, `backend/src/Smartlog.Domain/Entities/.../DataSource.cs`, `backend/src/Smartlog.Domain/Entities/.../DatabaseProviderType.cs`, `backend/src/Smartlog.Domain/Entities/.../CachedSchema.cs`, `frontend/src/features/data-sources/` | DEV | Multi-provider (PostgreSQL/MSSQL/ClickHouse — `DatabaseProviderType` enum); schema introspection vào `CachedSchema`. **Demo route**: `/data-sources` (inferred). |
| `multi-tenant-resolver` | Multi-tenant connection resolver (JWT claim) | GA | `backend/src/Smartlog.Infrastructure/IDbContextResolver.cs`, JWT claim `TenantDBConfiguration`, `ICurrentUser` | DEV | Falls back to `DefaultConnection` khi cờ `false &&` active (memory: feedback_pull_dev_skip_backend). Local dev workflow ghi nhận tránh xoá cờ này. |
| `external-services-refit` | Refit clients cho Tenant Admin + Auth Admin | GA | `backend/src/Smartlog.Infrastructure/ApiClients/TenantAdmin/`, `backend/src/Smartlog.Infrastructure/ApiClients/AuthAdmin/` | DEV | External SaaS dependency (Smartlog NuGet ecosystem). |

**Anti-scope check**: không gộp caching (area 11) hay query engine (area 3).

---

## 2. Data Modeling

**What we have**: 4 features.

| feature_id | name | maturity | source_paths | owner | notes |
|---|---|---|---|---|---|
| `semantic-registry` | Semantic Model registry (Dimensions / Metrics / Relationships) | Beta | `backend/src/Smartlog.Api/Controllers/SemanticRegistryController.cs`, entities `SemanticModel.cs`, `SemanticModelVersion.cs`, `SemanticDimension.cs`, `SemanticMetric.cs`, `SemanticRelationship.cs`, `SemanticTestCase.cs`, `frontend/src/features/semantic-registry/` | DEV+DA | Có versioning (`SemanticModelVersion`) + test case (`SemanticTestCase`) — tương đương LookML's `view+explore` ở dạng simplified. **Demo route**: `/semantic-registry`. |
| `glossary` | Business glossary (term → definition) | GA | `backend/src/Smartlog.Api/Controllers/GlossaryController.cs`, `GlossaryEntry.cs`, `BusinessRule.cs` | DA | Cross-source: dùng cho cả semantic layer và chat pipeline. |
| `column-value-index` | Column value index (cho NL grounding) | Beta | entities `ColumnValueEntry.cs`, `ColumnValueIndex.cs` | DEV | Index giá trị actual của column để chat pipeline mapping "Mondelez" → tenant_id. Anti-hallucination support cho area 12. |
| `dynamic-query-configs` | Query Config registry (JSON metadata) | GA | `backend/src/QueryConfigs/*.json` (Users, Roles, SecurityGroups, ErrorNodes, EvaluationRuns, Skills), schema in `backend/src/QueryConfigs/_schema/` | DEV | Modeling = TABLE_INFO + COLUMN_INFO + JOIN_INFO + WHERE_INFO; tenant-specific `mv_*` ClickHouse views (memory: feedback_check_registry_before_handrolling_sql). |

---

## 3. Query Engine / Semantic Layer

**What we have**: 4 features. Đây là **moat technical** — SqlKata + Fluid + tenant ClickHouse MV.

| feature_id | name | maturity | source_paths | owner | notes |
|---|---|---|---|---|---|
| `dynamic-query-engine` | Dynamic Query engine (SqlKata + Fluid) | GA | `backend/src/Smartlog.DynamicQuery/` (Abstractions, Handlers, QueryBuilders, Services, Utilities, Validators), `FileBasedQueryConfigService`, `FluidTemplateRenderService`, `DapperQueryExecuter` | DEV | JSON config → SQL pushdown to PG/MSSQL/CH. Vertical slice handler pipeline (Logging → Performance → Validation). |
| `golden-sql-library` | Golden SQL library (NL→SQL training pairs) | Beta | `backend/src/Smartlog.Api/Controllers/GoldenSqlsController.cs`, `GoldenSql.cs`, `GoldenSqlDifficulty.cs` (enum) | DEV+DA | Difficulty-rated NL↔SQL pairs; feed retrieval cho chat pipeline. **Khác biệt rõ với Superset/Metabase** — đa số competitor không có lib này. |
| `query-history` | Per-user query history | GA | entity `QueryHistory.cs` | DEV | Query log cho replay + audit. |
| `materialized-views-tenant` | Tenant ClickHouse MV (`mv_filter_*`, `mv_psv_*`, etc.) | GA | Documented trong `projects/{tenant}/.../sql-registry.md` (off-repo); runtime SQL stored trong widget.config DB | DEV+DA | Off-repo nhưng load-bearing. Memory: feedback_registry_runtime_sync_gap — registry edit không auto-sync xuống widget.config. |

---

## 4. Visualization Library

**What we have**: 9 features (8 widgets + chart auto-detect engine).

| feature_id | name | maturity | source_paths | owner | notes |
|---|---|---|---|---|---|
| `widget-alert-summary` | Alert Summary widget | GA | `frontend/src/features/dashboard/components/widgets/alert-summary/` | DEV | Hooks `use-alert-summary.ts`; tied to monitor area. |
| `widget-daily-ops` | Daily Ops widget | GA | `frontend/src/features/dashboard/components/widgets/daily-ops/` | DEV+DA | Daily operations pulse. |
| `widget-flash-report` | Flash Report widget (Mondelez Flash Daily) | GA | `frontend/src/features/dashboard/components/widgets/flash-report/`, `flash-report-api.ts` | DEV+DA | v1.1.0 storytelling 6 levels (memory: project_mondelez_flash_daily_storytelling); 95% target (project_mondelez_flash_daily_target). |
| `widget-matrix-table` | Matrix Table widget | GA | `frontend/src/features/dashboard/components/widgets/matrix-table/` | DEV+DA | 2-axis pivot. |
| `widget-order-monitor` | Order Monitor widget (VFR late-alert) | GA | `frontend/src/features/dashboard/components/widgets/order-monitor/` | DEV+DA | VFR storytelling v2 + grouped late-alert table v1.2 (recent commits 2dbefec, b642848); taxonomy "Có rủi ro/Ổn định" (memory: project_vfr_late_alert_taxonomy). |
| `widget-pgi-report` | PGI Report widget | GA | `frontend/src/features/dashboard/components/widgets/pgi-report/` | DEV+DA | PGI = post-goods-issue logistics report. |
| `widget-wh-predict` | Warehouse Predict widget | Beta | `frontend/src/features/dashboard/components/widgets/wh-predict/` | DEV+DA | Predictive (likely ML-flavored — promote to area 12 nếu chứa model). |
| `widget-shared-base` | Shared widget primitives (grid/types) | GA | `frontend/src/features/dashboard/components/widgets/shared/`, `widget-grid.types.ts` | DEV | Foundational utilities for all widgets. |
| `chart-auto-detect` | Chart auto-detection + smart encoding | Beta | `frontend/src/features/charts/lib/chart-auto-detect.ts`, `smart-encoding-suggester.ts`, `column-summary-analyzer.ts`, `column-format-inferrer.ts`, `chart-data-transform-pipeline.ts`, `format-column-label.ts` | DEV | Recharts + d3-array; data shape → chart type heuristic. **Closer to Tableau Show Me than Metabase**. |
| `saved-charts` | Saved Charts (persistent chart artifacts) | GA | `backend/src/Smartlog.Api/Controllers/SavedChartsController.cs`, `SavedChart.cs`, `frontend/src/features/chat/api/saved-charts.api.ts`, `use-saved-charts.ts` | DEV+DA | Chart đính kèm chat conversation, có thể pin lên dashboard. |

---

## 5. Dashboard / Canvas

**What we have**: 5 features.

| feature_id | name | maturity | source_paths | owner | notes |
|---|---|---|---|---|---|
| `dashboard-core` | Dashboard core (CRUD + folders) | GA | `backend/src/Smartlog.Api/Controllers/DashboardsController.cs`, `backend/src/Smartlog.Api/Controllers/DashboardFoldersController.cs`, entities `Dashboard.cs`, `DashboardFolder.cs`, `DashboardWidget.cs`, `WidgetParameter.cs`, `frontend/src/features/dashboard/api/`, `hooks/use-dashboard-crud.ts`, `hooks/use-dashboard-widgets.ts` | DEV | Drag-drop via `react-grid-layout` ^2.2.2. |
| `dashboard-permissions` | Dashboard permissions (per-user/group) | GA | `frontend/src/features/dashboard/hooks/use-dashboard-permissions.ts`, `DashboardPermission.cs` (enum) | DEV | Bonus: shared with area 10. |
| `dashboard-shares` | Dashboard share (link + visibility) | GA | `backend/src/Smartlog.Api/Controllers/SharesController.cs`, `DashboardShare.cs`, `WidgetVisibility.cs`, `SharedResource.cs`, `frontend/src/features/dashboard/hooks/use-dashboard-shares.ts` | DEV | Cũng phục vụ area 8 Embedding. |
| `dashboard-ai-assist` | Dashboard AI assistant (chat layer trên dashboard) | Beta | `frontend/src/features/dashboard/hooks/use-dashboard-ai.ts` | DEV | "Ask the dashboard a question" — overlap area 12. |
| `landing-canvas` | Landing canvas (homepage default dashboard) | GA | `frontend/src/features/landing/` | DEV | Entry-point canvas. |

---

## 6. Filtering & Parameters

**What we have**: 3 features.

| feature_id | name | maturity | source_paths | owner | notes |
|---|---|---|---|---|---|
| `widget-filter-resolver` | Widget filter resolver (multi-select + CSV expansion) | GA | `frontend/src/features/dashboard/components/filters/`, `chart-filter-types.ts`, FE `WidgetFilterResolver*` (memory: feedback_sql_review_widget_runtime) | DEV+DA | Anti-pattern audit ghi nhận trong memory — không dùng `coalesce({{multi_select}}, 'ALL')` trong CTE. |
| `cross-filter-safe` | Cross-filter giữa widgets | GA | `frontend/src/features/dashboard/hooks/use-cross-filter-safe.ts` | DEV | Click 1 widget → filter widgets khác trong cùng dashboard. |
| `widget-parameters` | Widget runtime parameters | GA | `WidgetParameter.cs` entity, FE settings dialog | DEV | Per-widget overrides — admin paste SQL qua Settings dialog (memory: feedback_no_default_sql_in_widget_code). |

---

## 7. Self-service Authoring

**What we have**: 6 features. Vùng này là **chiến lược** — chat + notebook = self-service moat.

| feature_id | name | maturity | source_paths | owner | notes |
|---|---|---|---|---|---|
| `chat-conversations` | Chat conversations + suggestions | Beta | `backend/src/Smartlog.Api/Controllers/ChatPipelineController.cs`, `ChatSuggestionsController.cs`, `ConversationsController.cs`, `MessagesController.cs`, entities `Conversation.cs`, `ConversationTag.cs`, `Message.cs`, `MessageFeedback.cs`, `MessageRole.cs`, `frontend/src/features/chat/` (api + hooks `use-chat`, `use-conversations`, `use-suggested-questions`) | DEV (AI) | NL → SQL → chart pipeline. Tagged conversations, suggestion auto-generation. |
| `notebooks` | Notebooks (cells + revisions + runs + artifacts) | Beta | `backend/src/Smartlog.Api/Controllers/NotebooksController.cs`, entities `Notebook.cs`, `NotebookCell.cs`, `NotebookCellRevision.cs`, `NotebookCellRun.cs`, `NotebookCellArtifact.cs`, `frontend/src/features/notebook/` | DEV (AI)+DA | Jupyter-style cho data analyst. Per-cell revision history = unusual depth. |
| `form-configs` | Form Config metadata (auto CRUD UI) | GA | `backend/src/Smartlog.Api/Controllers/FormsController.cs`, `backend/src/FormConfigs/*.json` (38 form configs incl. `DSHFLADTG01..G09`, OTIF, VFR, SHP), `frontend/src/core/api/form-config-queries.ts`, `core/store/formConfigStore.ts` | DEV | FormConfig codes drive grid + search; createEntityPage factory. |
| `monaco-sql-editor` | In-app SQL editor (Monaco + sql-formatter) | GA | FE deps `@monaco-editor/react ^4.7.0`, `monaco-editor ^0.55.1`, `sql-formatter ^15.7.2`, `react-syntax-highlighter` | DEV | Admin SQL paste workflow + chat tool-trace SQL preview. |
| `kpi-templates` | KPI Templates (industry benchmark + goal config + drilldown) | Beta | `backend/src/Smartlog.Api/Controllers/KpiTemplatesController.cs`, entities `KpiTemplate.cs`, `KpiChartConfig.cs`, `KpiDrilldownDimension.cs`, `KpiGoalConfig.cs`, `KpiIndustryBenchmark.cs`, `KpiMetricType.cs`, `KpiRequiredColumn.cs`, `KpiRequiredTable.cs`, `KpiRuntimeParameter.cs`, `KpiTemplateConsts.cs`, `KpiTemplateMapping.cs`, `frontend/src/features/kpi-templates/` | DEV+DA | **Distinctive**: industry benchmark embed + required column/table check + goal config per tenant. No direct equivalent ở Superset/Metabase. |
| `tool-trace-replay` | Tool execution trace (chat replay) | Beta | entity `ToolExecutionTrace.cs`, `frontend/src/features/chat/api/tool-trace.api.ts`, `use-tool-trace.ts`, `use-execution-plan.ts` | DEV (AI) | Replay step-by-step chat agent execution. |

---

## 8. Embedding & Sharing

**What we have**: 4 features.

| feature_id | name | maturity | source_paths | owner | notes |
|---|---|---|---|---|---|
| `share-resource` | Share resource (dashboard/notebook/chart) | GA | `backend/src/Smartlog.Api/Controllers/SharesController.cs`, `SharedResource.cs`, `DashboardShare.cs` | DEV | Token + visibility scope. |
| `scheduled-reports` | Scheduled reports (recurring delivery) | GA | `backend/src/Smartlog.Api/Controllers/ScheduledReportsController.cs`, `ScheduledReport.cs`, `ScheduledReportRun.cs` | DEV | Run history per schedule. |
| `slack-integration` | Slack integration (delivery + alert routing) | GA | `backend/src/Smartlog.Api/Controllers/SlackIntegrationController.cs`, `backend/src/Smartlog.Infrastructure/Slack/`, `SlackIntegration.cs` | DEV | Slack as delivery channel + alert routing target. |
| `export-pdf-excel` | Export PDF / PNG / Excel | GA | FE deps `jspdf ^4.2.1`, `html-to-image ^1.11.13`, `html2canvas ^1.4.1`, `xlsx-js-style ^1.2.0`, `frontend/src/core/utils/excel-export.ts` | DEV | Client-side render → file. Không pixel-perfect server-side. |

---

## 9. Collaboration

**What we have**: 5 features.

| feature_id | name | maturity | source_paths | owner | notes |
|---|---|---|---|---|---|
| `monitors` | Monitors (metric watchers) | GA | `backend/src/Smartlog.Api/Controllers/MonitorsController.cs`, entities `Monitor.cs`, `MonitorQuery.cs`, `MonitorQueryResult.cs`, `MonitorRun.cs`, `MonitorRunStatus.cs`, `MetricSnapshot.cs`, `MetricValues.cs`, `frontend/src/features/monitors/` | DEV | Multi-query monitor; per-run snapshot. |
| `alerts` | Alerts (threshold + routing + silence) | GA | entities `Alert.cs`, `AlertRoutingPolicy.cs`, `AlertSilence.cs`, `AlertState.cs`, `LlmAnalysisResult.cs`, `frontend/src/features/alert-manager/` | DEV | LLM analysis attached to alert (`LlmAnalysisResult`) — overlap area 12. |
| `notifications` | Notification channels + log | GA | `backend/src/Smartlog.Api/Controllers/NotificationsController.cs`, `NotificationChannelConfig.cs`, `NotificationChannelType.cs`, `NotificationLog.cs`, `NotificationStatus.cs`, `NotificationEventTypes.cs` | DEV | Channel types: Slack + Email (implied). |
| `message-feedback` | Per-message thumbs up/down (chat RLHF) | Beta | `MessageFeedback.cs` entity | DEV (AI) | Thumbs-up/down feedback per chat message. |
| `actions` | Actions framework (post-chart action handlers) | GA | `frontend/src/features/actions/api/actions.ts`, `frontend/src/core/builder/action-handlers.ts` | DEV | Action triggers (e.g., bulk row action) inside grid. |

---

## 10. Governance & RBAC

**What we have**: 7 features.

| feature_id | name | maturity | source_paths | owner | notes |
|---|---|---|---|---|---|
| `users` | Users CRUD + groups | GA | `backend/src/Smartlog.Api/Controllers/UsersController.cs`, `User.cs`, `UserGroup.cs`, `UserFormSetting.cs`, `frontend/src/features/users/` | DEV | Per-user form settings (grid layouts persist per user). |
| `roles` | Roles | GA | `backend/src/Smartlog.Api/Controllers/RolesController.cs`, `Role.cs`, `backend/src/QueryConfigs/Roles.json`, `frontend/src/features/roles/` | DEV | Role-based. |
| `security-groups` | Security Groups | GA | `backend/src/Smartlog.Api/Controllers/SecurityGroupsController.cs`, `SecurityGroup.cs`, `backend/src/QueryConfigs/SecurityGroups.json`, `frontend/src/features/security-groups/` | DEV | Workspace-level grouping. |
| `tenant-branding` | Tenant branding (per-tenant theme) | GA | `backend/src/Smartlog.Api/Controllers/TenantBrandingController.cs` | DEV | Multi-tenant isolation. |
| `rate-limits` | Rate limits (ceiling + per-user override) | GA | `backend/src/Smartlog.Api/Controllers/RateLimitsController.cs`, `RateLimitCeiling.cs`, `RateLimitGlobalConfig.cs`, `RateLimitUserOverride.cs` | DEV | LLM call rate limit. |
| `activity-log` | Activity log (audit trail) | GA | `backend/src/Smartlog.Infrastructure/ActivityLogs/`, `logging.activity` schema, `LogDbContext` separate from `AppDbContext` | DEV | Separate DB context (memory: `project_mondelez_da_ops_stack` ghi nhận. |
| `admin-features` | Admin features registry | GA | `backend/src/Smartlog.Api/Controllers/AdminController.cs`, `backend/src/Smartlog.Api/Controllers/FeaturesController.cs`, `backend/src/Smartlog.Api/Controllers/UserSettingsController.cs`, `backend/src/Smartlog.Api/Controllers/AnalyticsController.cs` | DEV | Feature flag + per-user settings. |

---

## 11. Performance & Scale

**What we have**: 4 features (smaller surface area — bóc từ Infrastructure subdirs).

| feature_id | name | maturity | source_paths | owner | notes |
|---|---|---|---|---|---|
| `embedding-cache` | Embedding cache | GA | `EmbeddingCache.cs` entity, `EmbeddingManagementController.cs` | DEV (AI) | Vector cache per content hash. |
| `background-jobs` | Background jobs runner | GA | `backend/src/Smartlog.Infrastructure/BackgroundJobs/` | DEV | Async work (embed jobs, scheduled report runs, monitor runs). |
| `file-storage` | File storage abstraction | GA | `backend/src/Smartlog.Infrastructure/FileStorage/` | DEV | Likely S3/local switchable. |
| `clickhouse-mv-tenant` | ClickHouse materialized views (tenant-specific) | GA | Off-repo `projects/{tenant}/.../sql-registry.md` (Mondelez Stack B, Panasonic PSV — memory `project_mondelez_da_ops_stack`, `project_panasonic_psv_pipeline`) | DEV+DA | MergeTree + `mv_filter_*` per tenant. |

---

## 12. AI / ML

**What we have**: 11 features. **Đây là vùng đậm đặc nhất sau Dashboard.**

| feature_id | name | maturity | source_paths | owner | notes |
|---|---|---|---|---|---|
| `chat-pipeline` | Chat pipeline (NL→SQL→answer) | Beta | `ChatPipelineController.cs`, chat hooks `use-chat`, `use-execution-plan` | DEV (AI) | Multi-step agent với tool-trace replay. |
| `knowledge-rag` | Knowledge documents + chunks + vector search | Beta | `KnowledgeDocumentsController.cs`, `KnowledgeSearchController.cs`, entities `KnowledgeDocument.cs`, `KnowledgeChunk.cs`, `KnowledgeType.cs`, `KnowledgeFileType.cs`, `KnowledgeDocumentStatus.cs`, `frontend/src/features/knowledge-memory/` | DEV (AI) | RAG with chunk-level retrieval. |
| `embedding-management` | Embedding management (provider + job + progress) | Beta | `EmbeddingManagementController.cs`, `EmbeddingCache.cs`, `EmbeddingJobProgress.cs`, `EmbeddingJobStatus.cs`, `EmbeddingJobType.cs`, `EmbeddingProvider.cs` | DEV (AI) | Async embedding pipeline (OpenAI/Voyage/etc.). |
| `llm-providers` | LLM providers + pricing + usage + budget | GA | `LlmProvidersController.cs`, `LlmModelPricingController.cs`, `LlmUsageController.cs`, entities `LlmProviderConfig.cs`, `LlmBudgetConfig.cs`, `LlmModelPricing.cs`, `LlmUsageLog.cs`, `LlmProviderType.cs`, `frontend/src/features/llm-stats/` | DEV (AI) | Multi-provider abstraction + per-tenant budget. **Differentiator vs PowerBI Copilot** (single-vendor lock-in). |
| `organization-ai-settings` | Per-org AI settings | GA | `OrganizationAiSettingsController.cs`, `OrganizationAiSettings.cs` | DEV (AI) | Tenant-level AI config. |
| `analysis-runs` | Analysis runs (LLM analytical runs) | Beta | `AnalysisRunsController.cs`, entities `AnalysisRun.cs`, `AnalysisArtifact.cs`, `AnalysisRunStatus.cs` | DEV (AI) | Long-running analytical task (e.g., anomaly summary). |
| `evaluation-harness` | Evaluation runs + results | Beta | `EvaluationRunsController.cs`, entities `EvaluationRun.cs`, `EvaluationResult.cs`, `backend/src/QueryConfigs/EvaluationRuns.json` | DEV (AI) | **Eval harness built-in** = uncommon ở BI vendors. Foundation for model selection. |
| `skills-registry` | Agent skills registry | GA | `SkillsController.cs`, `Skill.cs`, `SkillCategory.cs`, `backend/src/QueryConfigs/Skills.json`, `frontend/src/features/skills/` (skills-provider, use-skills) | DEV (AI) | Agent skill catalog with category. |
| `user-memory` | Persistent user memory (scoped) | Beta | `UserMemoriesController.cs`, `UserMemory.cs`, `UserMemoryScope.cs`, `UserMemoryType.cs` | DEV (AI) | Long-term memory across conversations. |
| `error-graph` | Error graph (errors + relations + fix patterns + column/table links) | Beta | `ErrorNodesController.cs`, entities `ErrorNode.cs`, `ErrorRelation.cs`, `ErrorFixPattern.cs`, `ErrorColumnLink.cs`, `ErrorTableLink.cs`, `backend/src/QueryConfigs/ErrorNodes.json`, `frontend/src/features/error-graph/` (use-error-graph hook) | DEV (AI) | Graph-based root cause analysis. **No equivalent** ở Superset/Metabase. |
| `chat-suggestions` | Chat suggestion engine | Beta | `ChatSuggestionsController.cs`, hook `use-suggested-questions.ts` | DEV (AI) | Auto-generated follow-up questions. |
| `widget-wh-predict-ml` | Warehouse predict (probable ML inference) | Beta | `frontend/src/features/dashboard/components/widgets/wh-predict/` | DEV+DA | Listed cũng ở area 4 — đây là tag ML inference của cùng widget. |

---

## 13. Mobile / Responsive

**What we have**: 1 feature (responsive only, no native app).

| feature_id | name | maturity | source_paths | owner | notes |
|---|---|---|---|---|---|
| `responsive-web` | Responsive web (Tailwind v4 + RTL components) | GA | `frontend/tailwind.config.*`, `frontend/src/components/ui/` (RTL-patched Shadcn: alert-dialog, calendar, command, dialog, dropdown-menu, select, table, sheet, sidebar, switch, scroll-area, sonner, separator), `frontend/src/hooks/use-mobile.tsx`, `frontend/src/context/direction-provider.tsx` | DEV | RTL ready (rare cho BI vendor); responsive breakpoints. **No native iOS/Android app**. |

---

## 14. Pricing & Deployment Model

**Smartlog position**: Internal product, B2B SaaS embedded multi-tenant (per-contract). Connection resolved qua JWT claim `TenantDBConfiguration`. Self-hosted .NET 10 + React 19, PostgreSQL primary + ClickHouse analytics. Docker compose available (`backend/docker-compose.dcproj`).

**N/A** — pricing public không applicable (internal). Sẽ benchmark vendor pricing trong Mode B.

---

## Cross-cutting tech stack flags (cho benchmark Mode B)

- **Auth**: OIDC (`oidc-client-ts ^3.4.1`, `react-oidc-context ^3.3.0`) — SSO ready.
- **i18n**: i18next v25 + browser language detector — multi-language out-of-box (`vi` default, `en` fallback per backend CLAUDE.md). Memory `feedback_i18n_no_internal_refs`: i18n string không reference internal docs.
- **Charts**: Recharts 3.5 + d3-array — single-vendor chart lib (no D3 raw).
- **Editor**: Monaco 0.55 (full IDE-grade SQL editor).
- **Data table**: TanStack Table 8.21 (Excel-like grid).
- **Routing**: TanStack Router 1.161 (file-based, auto-gen).
- **State**: Zustand 5.0 + TanStack Query 5.90.
- **Tests**: Vitest 4.0 + Testing Library 16.3 (FE); xUnit (`Smartlog.Application.Tests` BE).
- **Build**: Vite 7 + SWC.
- **Markdown**: react-markdown + remark-gfm (chat renderer).
- **Domain entities**: ~80 entity classes — wide modeling surface area.
- **Controllers**: 41 controllers (vs ~5–10 typical BI base).

---

## Capability bucket coverage summary

| # | Capability area | Features | Highest maturity | Notes |
|---|---|---:|---|---|
| 1 | Data Connectors | 3 | GA | Multi-tenant, multi-provider; no marketplace |
| 2 | Data Modeling | 4 | GA | Semantic registry Beta (versioning + test cases) |
| 3 | Query Engine | 4 | GA | SqlKata+Fluid; Golden SQL lib Beta |
| 4 | Visualization | 10 | GA | 8 domain widgets + chart-auto-detect Beta |
| 5 | Dashboard/Canvas | 5 | GA | react-grid-layout; AI assist Beta |
| 6 | Filtering & Params | 3 | GA | Cross-filter + WidgetFilterResolver |
| 7 | Self-service Authoring | 6 | Beta | Chat + Notebook + KPI templates **= strategic moat** |
| 8 | Embedding & Sharing | 4 | GA | Slack + scheduled reports; no iframe pixel-perfect |
| 9 | Collaboration | 5 | GA | Monitors+Alerts+Notifications; LLM-attached alerts |
| 10 | Governance & RBAC | 7 | GA | Tenant + Role + SecurityGroup + RateLimit + activity log |
| 11 | Performance & Scale | 4 | GA | ClickHouse MV per-tenant; embedding cache |
| 12 | AI / ML | 11 | Beta–GA | **Đậm đặc nhất sau Dashboard**: RAG + eval + memory + error graph |
| 13 | Mobile/Responsive | 1 | GA | Web only, no native app |
| 14 | Pricing/Deployment | (n/a) | n/a | Internal product, multi-tenant SaaS |

**Total catalogued: 47 features across 13 buckets.**

---

## Reading suggestions (for the next mode)

- Trước khi chạy `/da-po benchmark` hoặc `/da-po sweep`, đề xuất:
  - Refresh competitor cache với window 60 ngày — PowerBI Copilot và Looker Studio AI có release lớn năm 2026.
  - Đặc biệt benchmark **area 7 (authoring) + area 12 (AI/ML)** vì đó là vùng moat của ta.
- Khu vực có thể là **LEAPFROG candidates** (ta có, đa số competitor không):
  - `golden-sql-library` (training pairs)
  - `error-graph` (root-cause graph)
  - `evaluation-harness` (built-in eval)
  - `kpi-templates` với industry benchmark embed
  - `notebooks` với cell-level revision history
  - `user-memory` persistent

---

## Closing notes

- File này được sinh bởi `/da-po inventory` (Mode A). KHÔNG commit tự động — `projects/` là repo riêng (`helix_projects`), commit phải đi qua `/da-projects` (memory: `project_projects_repo_isolated`).
- Mode D (delta) sẽ dùng `_latest.json` để diff vs commit kế tiếp; KHÔNG re-scan toàn bộ.
- Khuyến nghị refresh: 7 ngày sau (2026-06-02) — branch `feat-vfr-late-alert` đang active, code area widget/order-monitor sẽ tiếp tục đổi.
