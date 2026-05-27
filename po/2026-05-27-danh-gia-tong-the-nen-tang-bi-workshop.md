# Smartlog Control Tower — Đánh giá tổng thể nền tảng BI

**Tài liệu workshop nội bộ** · 2026-05-27 · Tác giả: `/da-po` (squad1@gosmartlog.com)
**Branch tham chiếu**: `feat-vfr-late-alert` · **Scan baseline**: `41b3863` (2026-05-22)
**Đối tượng đọc**: các team nội bộ Smartlog (DEV / DA / BA / PM / Rollout / BOD)
**Mục đích**: nhìn nhận trạng thái hiện tại của sản phẩm một cách khách quan, làm input cho thảo luận định hướng phát triển.

---

## 0. Cách đọc tài liệu này (đọc trước)

Tài liệu này **tổng hợp** 6 artifact đã có sẵn trong `projects/po/` (không phải đánh giá mới từ đầu):

| Nguồn | Nội dung |
|---|---|
| [`inventory/2026-05-26-feature-catalog.md`](inventory/2026-05-26-feature-catalog.md) | 47–48 feature bóc từ source code, gom theo 14 BI capability area |
| [`benchmark/2026-05-26-bi-capability-matrix.md`](benchmark/2026-05-26-bi-capability-matrix.md) | Ma trận 14 area × 8 vendor (ta + 7 đối thủ) |
| [`benchmark/2026-05-26-gap-analysis.md`](benchmark/2026-05-26-gap-analysis.md) | 26 gap năng lực (`GAP-001..026`) + verdict |
| [`benchmark/2026-05-27-usability-convenience-lens.md`](benchmark/2026-05-27-usability-convenience-lens.md) | Góc nhìn "dễ dùng" theo persona (7 gap `CONV-001..007`) |
| [`roadmap-input/2026-05-26-recommendations.md`](roadmap-input/2026-05-26-recommendations.md) | 16 đề xuất gom thành 4 cluster |
| [`_competitors/*.md`](_competitors/) | Hồ sơ 7 đối thủ |

**Tài liệu này KHÔNG phải:**
- **Không phải roadmap đã chốt** — các định hướng ở §7 là *đề xuất để thảo luận*, chưa có owner/timeline (đó là việc của `/da-pm`), chưa qua bước `/da-discovery` để frame vấn đề.
- **Không phải tài liệu bán hàng** — viết cho người trong nhà đã biết sản phẩm; ưu tiên thẳng thắn hơn là tô hồng.
- **Không phải đánh giá thẩm mỹ UI** — loại trừ "đẹp/xấu" (chủ quan), nhưng *có* đo "dễ dùng/thuận tiện" (đo được: time-to-task, số bước, tự phục vụ được không).

**Độ tin cậy của số liệu** (khách quan với cả phương pháp):
- Phần tính năng của Smartlog: **bóc trực tiếp từ code**, có path truy ngược → độ tin cậy cao.
- Phần đối thủ: **2/7 vendor verify qua tài liệu chính thức** (Power BI Copilot, Tableau Pulse); **5/7 dựa training-cutoff + URL doc gốc** (Looker/Superset/Metabase/Sisense/Qlik). → coi là **định hướng, không phải số liệu cứng**; phải refresh trước khi dùng đối ngoại.
- 3 điểm đã được kiểm chứng lại khi soạn tài liệu này (xem [§8 đính chính](#8-đính-chính-khi-soát-lại-source-code--giữ-khách-quan)).

---

## 1. TL;DR — kết luận trong một trang

> **Smartlog Control Tower không còn là "dashboard widget cơ bản trên react-grid-layout".** Nó đã là một nền tảng analytics khá đầy đủ: ~48 tính năng trải 13/14 capability area, 42 controller, ~80 entity, có cả lớp AI-native (chat NL→SQL, RAG, eval harness, multi-LLM, error-graph) và notebook self-service — những thứ đa số BI vendor cùng tầm giá không có.

Nhưng đánh giá khách quan phải nói thẳng **hai mâu thuẫn cốt lõi** mà cả team cần nhìn nhận trong workshop:

**Mâu thuẫn 1 — "Trưởng thành ở chỗ ít khác biệt, non ở chỗ khác biệt nhất."**
Phần GA (chín, dùng được) hầu hết là *plumbing thông dụng* mà vendor nào cũng có (governance, dashboard CRUD, query engine, connectors, monitor/alert, widget viz). Còn phần *tạo khác biệt* — AI/ML, semantic layer, self-service authoring — thì **~19/48 feature vẫn Beta** và tập trung đúng vào các vùng đó. Ta đang quảng bá moat ở chỗ sản phẩm còn non nhất.

**Mâu thuẫn 2 — "Có năng lực, nhưng đường đi tới giá trị còn khó."**
Chấm theo *cung* (có/sâu): #7 Self-service = `✓/Deep` (dẫn đầu). Chấm theo *cầu* (người dùng làm có dễ không): tạo một widget phân tích mới = **Hard** với chính persona DA/BA. Moat "self-service" hẹp hơn nhiều so với điểm số. Đồng thời khoản đầu tư demand-side lớn nhất gần đây (storytelling layout, plain-language, empty-state) lại **vô hình** với thước đo năng lực thuần.

**3 điểm mạnh đáng bảo vệ** (evidence trong code, nhưng chưa validate ngoài thị trường):
1. **Kiến trúc AI đa nhà cung cấp** (multi-LLM + budget + eval + error-graph + golden SQL) — vendor copilot đều khoá 1 LLM.
2. **Chiều sâu nghiệp vụ logistics** (8 widget domain + KPI templates có industry benchmark) — moat dọc ngành.
3. **Comprehension-first storytelling** (Flash Daily 6 tầng, VFR "Có rủi ro/Ổn định") — "ra quyết định trong 30 giây, không cần training".

**3 điểm yếu/rủi ro thật sự:**
1. **Nhãn Beta chặn enterprise procurement** — 9/11 feature AI còn Beta.
2. **Định vị "embedded ISV" nhưng embedding mới chỉ iframe** — thiếu component SDK / signed-URL / RLS policy (đối thủ Sisense/Looker/Metabase đã có).
3. **Onboard tenant mới còn thủ công** (dựng MV off-repo + paste SQL registry) — bóp nghẹt chính mô hình kinh doanh multi-tenant.

**Câu hỏi lớn nhất cho workshop:** *Smartlog chọn định vị nào làm trục chính 12 tháng tới?* (vertical logistics analytics / embedded ISV BI / AI-native BI) — vì ba điểm yếu trên không thể fix song song hết, và lựa chọn định vị quyết định fix cái nào trước.

---

## 2. Chân dung sản phẩm hôm nay

### 2.1 Bốn trụ cột

Codebase hiện đứng trên 4 trục lớn (không còn là "widget canvas" đơn thuần):

1. **Dashboard + Widget cố định** — 8 widget logistics-specific (alert-summary, daily-ops, flash-report, matrix-table, order-monitor, pgi-report, wh-predict, shared) trên `react-grid-layout`, **cộng** một lớp widget generic (`widget-kpi`, `widget-metric`, `widget-stat-list`, `widget-narrative`, `widget-chart`, `widget-kpi-gauge`). Đây là core delivery hiện tại.
2. **Chat-driven analytics** — pipeline NL→SQL→chart đầy đủ: ChatPipeline, GoldenSql, Knowledge/RAG, EmbeddingCache, SemanticRegistry, ToolExecutionTrace, AnalysisRun, EvaluationRun.
3. **Notebook** — Jupyter-style (cell + revision + run + artifact) cho DA self-service.
4. **Monitor/Alert + ScheduledReport + Slack** — lớp observability trên metric tenant, có cả LLM analysis gắn vào alert.

### 2.2 Độ phủ năng lực (13/14 area)

| # | Capability area | Số feature | Maturity cao nhất | Ghi chú |
|---|---|---:|---|---|
| 1 | Data Connectors | 3 | GA | Multi-tenant, multi-provider (PG/MSSQL/CH); không có marketplace |
| 2 | Data Modeling | 4 | GA | semantic-registry (Beta) có versioning + test case |
| 3 | Query Engine / Semantic | 4 | GA | SqlKata + Fluid; Golden SQL lib (Beta) |
| 4 | Visualization | 10 | GA | 8 widget domain + lớp generic + chart-auto-detect (Beta) |
| 5 | Dashboard / Canvas | 5 | GA | react-grid-layout; AI assist (Beta) |
| 6 | Filtering & Params | 3 | GA | Cross-filter + WidgetFilterResolver |
| 7 | Self-service Authoring | 6 | Beta | **Chat + Notebook + KPI templates = vùng chiến lược** |
| 8 | Embedding & Sharing | 4 | GA | Slack + scheduled report; chưa có SDK/iframe RLS chuẩn |
| 9 | Collaboration | 5 | GA | Monitor + Alert (LLM-attached) + Notification |
| 10 | Governance & RBAC | 7 | GA | Tenant + Role + SecurityGroup + RateLimit + activity log |
| 11 | Performance & Scale | 4 | GA | ClickHouse MV per-tenant; embedding cache |
| 12 | AI / ML | 11 | Beta–GA | **Đậm đặc nhất sau Dashboard**: RAG + eval + memory + error-graph |
| 13 | Mobile / Responsive | 1 | GA | Web responsive + RTL; **không có app native** |
| 14 | Pricing / Deployment | n/a | — | Internal product, multi-tenant SaaS per-contract |

*(+1 feature `support-center` — in-app user guide + walkthrough — nằm trong `_latest.json`; xem [§8](#8-đính-chính-khi-soát-lại-source-code--giữ-khách-quan).)*

### 2.3 Bức tranh maturity — điểm cần nhìn thẳng

Đây là biểu đồ quan trọng nhất của workshop. Khi tách GA vs Beta:

- **Phần GA (chín)** = chủ yếu *plumbing thông dụng*: governance/RBAC (7 GA), dashboard CRUD, query engine core, connectors, monitor/alert, widget viz, scheduled report, export. → Đây là **table-stakes**: vendor nào cũng có ở mức GA.
- **Phần Beta (~19/48 feature)** = tập trung đúng vào *vùng khác biệt*: gần như toàn bộ AI/ML (chat-pipeline, knowledge-rag, embedding-management, analysis-runs, evaluation-harness, user-memory, error-graph, chat-suggestions), semantic-registry, column-value-index, golden-sql-library, notebooks, kpi-templates, tool-trace-replay, chart-auto-detect, dashboard-ai-assist, wh-predict.

> **Kết luận khách quan:** Smartlog **trưởng thành nhất ở nơi ít tạo khác biệt, và non nhất ở nơi tạo khác biệt nhất.** Đây không phải là "thiếu tính năng" — kiến trúc và entity đã có. Đây là **khoảng cách chất lượng/độ tin cậy** (Beta → GA): SLA, eval chạy trên traffic thật, error budget, changelog cho khách. Đó mới là phần lift thật sự.

---

## 3. Ta đang ở đâu trên bản đồ BI (benchmark vs 7 vendor)

Tóm tắt ma trận 14×8 (chi tiết: [bi-capability-matrix.md](benchmark/2026-05-26-bi-capability-matrix.md)):

| Vị thế | Area | Diễn giải khách quan |
|---|---|---|
| **Dẫn đầu / khác biệt** | #12 AI/ML, #7 Self-service, #2 Data Modeling (grounding) | Bề rộng kiến trúc AI bất thường so với tầm giá; multi-LLM là khác biệt thật vs Copilot (Azure OpenAI), Looker (Gemini), Pulse (Einstein) |
| **Ngang bằng** | #5 Dashboard, #6 Filtering, #9 Collaboration, #10 Governance, #11 Performance | ClickHouse MV là tương đương chức năng của in-memory engine cho use case phân tích |
| **Tụt lại** | #1 Connectors (3 vs 60–200), #4 viz breadth (vs 25–40 chart type), #8 embedding polish, #13 mobile (web-only) | Một số khoảng cách *hợp* với định vị "vertical logistics ISV" và **không nên đuổi**; riêng #8 embedding là khoảng cách *đáng lo* vì mâu thuẫn với định vị embedded |
| **N/A** | #14 Pricing | Sản phẩm nội bộ, không có bảng giá công khai |

**Đối thủ "gần ta nhất": Sisense** — cùng mô hình embedded ISV multi-tenant; Compose SDK của họ là benchmark cho embedding. **Metabase** là đối thủ trực diện ở phân khúc embedded giá $85–$500/mo và thắng deal nhờ *no-code dễ dùng* (điểm này ma trận năng lực thuần đánh giá thấp họ một cách hệ thống — xem §4).

**Lưu ý đọc ma trận cho đúng:** ma trận presence×depth **thưởng quá tay cho tool nhiều tính năng nhưng khó dùng, và phạt oan tool dễ dùng**. Vì vậy phải đọc kèm góc nhìn cầu ở §4 — nếu không, ta sẽ tự định vị sai.

---

## 4. Hai góc nhìn phải đặt cạnh nhau: Cung (năng lực) vs Cầu (dễ dùng)

Đây là phần "có gì mới" so với một báo cáo benchmark thông thường, và là phần đáng tranh luận nhất trong workshop.

**Cung (supply)** = "nền tảng CÓ gì" (presence × depth). **Cầu (demand)** = "người dùng thật CẢM NHẬN gì" (dễ/nhanh/tự phục vụ được). Chấm theo 3 persona:

| Persona | Là ai ở Smartlog | "Thuận tiện" nghĩa là |
|---|---|---|
| **P1 — Business Consumer** | SC Manager, BOD | time-to-insight, hiểu ngay, không cần training |
| **P2 — Citizen Author** | DA / BA / PM | tự dựng view / hỏi ad-hoc / tạo KPI mà không cần FE dev |
| **P3 — Tenant Admin / Embedder** | IT tenant, Rollout | onboard tenant, cấu hình embed + permission, clone từ tenant có sẵn |

### 4.1 Mâu thuẫn `✓/Deep/Hard` — moat self-service hẹp hơn điểm số

| Hành trình người dùng | Persona | Cung chấm | Cầu chấm | Thực tế hôm nay |
|---|---|---|---|---|
| **J1 — Hiểu "hôm nay có ổn không"** | P1 | (không đo) | **Easy ✅** | Storytelling layout: Flash Daily hero %, VFR exception-first, ngôn ngữ thường → trả lời trong vài giây, **đây là điểm ta thật sự dẫn** |
| **J3 — Tự tạo widget/metric mới** | P2 | `✓/Deep` (dẫn đầu) | **Hard ❌** | Cần FE code + paste SQL thủ công qua Settings dialog; registry không tự sync xuống `widget.config`; sai label `{{date_type}}` là silent bug. **Metabase no-code = Easy** — đúng chỗ họ thắng deal |
| **J4 — Onboard tenant mới** | P3 | (không đo) | **Hard ❌** | Dựng MV off-repo (`sql-registry.md`) + paste registry; chưa có wizard "clone Mondelez → Panasonic". **Đây chính là mô hình kinh doanh** |
| **J6 — Embed vào portal tenant** | P3 | ◐ Medium | **Hard** | Chỉ iframe; thời gian tích hợp cao (= GAP-001/002/003) |
| **J5 — Xử lý khi rỗng/lỗi/cũ** | tất cả | (không đo) | Moderate | TỐT: VFR empty-state 3 ca. YẾU: cố tình bỏ as-of/freshness; SQL silent-fail khiến số sai trông như số đúng |

> **Điểm chốt:** #7 là `Deep` cho việc *tiêu thụ* và *config CRUD*, nhưng **không** cho việc *tạo mới bởi người không phải developer*. Đóng được CONV-001 (đường no-code GA cho P2) chính là cách **hiện thực hoá** cái moat mà ma trận năng lực đã cộng điểm cho ta.

### 4.2 Khoản đầu tư lớn nhất gần đây lại vô hình với thước đo

Công việc trên nhánh này — VFR storytelling v2, Flash Daily 6 tầng, empty-state 3 ca, đổi tên "Có rủi ro/Ổn định" — **toàn bộ là convenience/comprehension cho business user**. Ma trận năng lực **không nhìn thấy** vì nó chỉ đếm feature presence. Team đang làm demand-side mà chính scoreboard của mình mù với nó.

Hệ quả thú vị: gap `GAP-024` (Tableau Story Points) bị chấm **IGNORE** trên trục cung ("ta không cần feature đó"). Trên trục cầu thì **ngược lại** — pattern storytelling của ta là **LEAPFROG** đáng nhân đôi (CONV-004). Vấn đề không phải copy feature của Tableau, mà là **biến pattern hand-built per-widget thành framework layout tái dùng được + trait của KPI template**.

### 4.3 Tổng hợp 7 convenience gap (`CONV-NNN`)

| conv_id | Persona | Friction | Verdict |
|---|---|---|---|
| CONV-001 | P2 | Chưa có đường no-code GA để tạo widget phân tích mới (chat/auto-detect đều Beta) | CATCH-UP High |
| CONV-002 | P3 | Onboard tenant thủ công, chưa có clone/template wizard | CATCH-UP High |
| CONV-003 | P1 | Đòn bẩy self-serve mạnh nhất (NL chat) còn Beta → consumer không tin → quay về nhờ DA | CATCH-UP High |
| CONV-004 | P1 | Storytelling là edge thật nhưng per-widget, chưa codify thành tài sản tái dùng | **LEAPFROG** |
| CONV-005 | P1/P2 | (cần đính chính — xem §8) onboarding trong sản phẩm | CATCH-UP Med |
| CONV-006 | P1/P2 | Thiếu tín hiệu tin cậy: không có freshness/as-of + SQL silent-fail | CATCH-UP Med |
| CONV-007 | P1 | Accessibility (WCAG, keyboard, screen reader) chưa từng được đánh giá | CATCH-UP Low |

---

## 5. Điểm mạnh thật sự (đáng bảo vệ)

Trình bày như **giả thuyết có bằng chứng trong code, cần validate ngoài thị trường** — không phải khẳng định marketing.

1. **Kiến trúc AI đa nhà cung cấp + kiểm soát chi phí** (`llm-providers`, `LlmBudgetConfig`, `RateLimit`) — vendor copilot khoá 1 LLM (PowerBI=AzureOpenAI, Looker=Gemini, Pulse=Einstein). Tenant như Mondelez/Panasonic có yêu cầu data-residency + cost-cap mà single-LLM khó đáp ứng. *(GAP-013 LEAPFROG)*
2. **Eval harness + Golden SQL + Error-graph** — bộ ba "AI có thể kiểm chứng": chấm điểm model, thư viện NL↔SQL của tenant, graph root-cause. Hầu như không vendor benchmark nào lộ ra ở cấp này. *(GAP-012/014/015 LEAPFROG)*
3. **Notebook + tool-trace-replay** — Hex/Deepnote/Mode là *tool riêng*; ở đây tích hợp sẵn trong BI + replay agent. *(GAP-011 LEAPFROG)*
4. **Chiều sâu nghiệp vụ logistics** — 8 widget domain + KPI templates có `KpiIndustryBenchmark` + required-column gating + drilldown + goal config. Vendor có "metric definition", ít ai có "industry benchmark + gating". *(GAP-016 LEAPFROG)*
5. **Comprehension-first storytelling** (J1) — edge demand-side thật, vô hình với scoreboard cung. *(CONV-004 LEAPFROG)*
6. **Multi-tenant isolation theo DB** (JWT `TenantDBConfiguration`) — mạnh hơn về cấu trúc so với column-masking trong shared DB.

> Cả 6 điểm đều có chung pattern: **entity/kiến trúc đã ship, nhưng chưa thành "surface khách hàng thấy được"**. Lift chính là productization + GA, không phải build mới.

---

## 6. Điểm yếu & rủi ro thật sự

1. **Nhãn Beta là rào procurement** (GAP-004) — 9/11 feature AI Beta. Không phải gap tính năng mà là gap chất lượng/SLA. Đối thủ marketing AI ở mức GA.
2. **Định vị embedded nhưng embedding mới iframe** (GAP-001/002/003) — thiếu component SDK (Sisense Compose), signed-URL pass-through (Looker), RLS policy khai báo (Metabase). Đây là **gap nhận diện**: nếu định vị "embedded" mà hợp đồng embedding chỉ là iframe, ta thua RFP trước vendor mà cả sản phẩm là embedding.
3. **Authoring khó cho citizen analyst** (CONV-001/J3) — moat self-service hẹp hơn điểm số; đúng chỗ Metabase thắng.
4. **Onboard tenant thủ công** (CONV-002/J4) — friction scale tuyến tính theo pipeline bán hàng; giới hạn tốc độ nhận tenant.
5. **Thiếu tín hiệu tin cậy** (CONV-006) — bỏ freshness/as-of + SQL silent-fail → user không phân biệt được số cũ/sai với số đúng. Rủi ro niềm tin với chính business user.
6. **Hẹp ở connectors / viz breadth / mobile native** — phần lớn *hợp* định vị dọc ngành (nên IGNORE, review 6 tháng), nhưng cần nói rõ với team để không bị bất ngờ khi so bảng tính năng với đối thủ.
7. **Phụ thuộc artifact off-repo** — MV tenant sống trong `sql-registry.md` (repo `helix_projects`), registry không tự sync xuống runtime `widget.config` → rủi ro lệch số khi admin quên paste lại.

---

## 7. Định hướng đề xuất (để workshop thảo luận — chưa chốt)

Tổng hợp 16 gap năng lực (`GAP`) + 7 convenience gap (`CONV`) thành **5 cluster**. Mọi item **bắt buộc đi qua `/da-discovery`** để frame vấn đề trước, **không nhảy thẳng `/ba`**.

| Cluster | Items | Ý đồ chiến lược | Đòn bẩy |
|---|---|---|---|
| **A. Embedded ISV hardening** | GAP-001/002/003/005, CONV-002 | Đạt chuẩn embedded BI (component SDK + signed-URL + RLS policy + server-side PDF) + clone-tenant wizard | Định vị, định danh |
| **B. AI: từ bề rộng → trưởng thành + tin cậy** | GAP-004/011/012/013/015, CONV-003 | Đưa Beta→GA; productize eval/multi-LLM/error-graph thành surface khách hàng; "BI bạn kiểm chứng được" | Cao nhất (positioning) |
| **C. Vertical IP marketplace** | GAP-014/016 | Golden SQL + KPI templates có industry benchmark → marketplace tenant subscribe | Trung bình, chi phí thấp (entity có sẵn) |
| **D. Tactical UX catch-up** | GAP-006/007/008/009/010 | Drill-through, comment, anomaly/forecast, lineage, mobile layout | Cơ hội, rủi ro thấp |
| **E. Convenience & comprehension** | CONV-001/004/005/006/007 | No-code authoring GA, codify storytelling thành framework, trust signals, accessibility | Hiện thực hoá moat đã được cộng điểm |

**Thứ tự ưu tiên đề xuất (informal — `/planner` sẽ tinh chỉnh):** Cluster A + B cao nhất (định vị); C dùng entity sẵn (productization rẻ); D + E cơ hội. CONV-003 (GA hoá chat) là **ROI demand-side cao nhất** vì mở khoá J2 self-serve cho P1 *và* đường no-code cho P2 cùng lúc.

**Phần KHÔNG đề xuất (IGNORE, review 2026-11-26):** connector breadth, custom viz SDK, generic chart breadth, story points/device layout, aggregation fallback, native mobile app — minh bạch để workshop biết ta *chủ động bỏ qua*, không phải quên.

---

## 8. Đính chính khi soát lại source code (giữ khách quan)

Khi soạn tài liệu này tôi kiểm chứng lại 3 điểm trong các artifact nguồn — đây là phần "khách quan với chính mình":

1. **`support-center` CÓ tồn tại** — `frontend/src/features/support-center/` (api/components/hooks) + `SupportCenterController.cs` + `SupportCenterAdminController.cs` + entity `UserGuideArticle`/`UserGuideCategory`/`WalkthroughProgress`. → **CONV-005 ("No in-product onboarding / guided tour") nói quá.** Hạ tầng onboarding *đã có*; câu hỏi đúng cho workshop là *"đã populate nội dung và có ai dùng chưa?"*, không phải "có chưa".
2. **Viz layer rộng hơn "8 widget"** — ngoài 8 widget folder domain, còn lớp generic: `widget-kpi`, `widget-metric`, `widget-stat-list`, `widget-narrative`, `widget-kpi-gauge`, `widget-chart`. → Framing "8 widget vs 25–40 chart type" hơi undersell; ta có lớp render generic, chỉ là chưa nhiều như chart-library của đối thủ.
3. **Controller: 42 thực tế** (artifact ghi 41) — sai số nhỏ, không ảnh hưởng kết luận.

→ Hàm ý: các artifact nguồn rất chắc về *cung* (bóc từ code), nhưng phần *cầu* (`CONV`) được viết suy luận và **cần kiểm chứng adoption thật** trước khi đưa vào roadmap. Đây là một agenda item của workshop.

---

## 9. Câu hỏi quyết định cho workshop

Phần này là "trái tim" của buổi workshop — không phải để báo cáo, mà để cả team quyết:

1. **Định vị trục chính 12 tháng tới?** — *Vertical logistics analytics* (đào sâu domain widget + KPI marketplace) / *Embedded ISV BI* (đóng gap embedding) / *AI-native BI* (GA hoá AI + productize eval). Ba điểm yếu lớn không fix song song được; chọn định vị → chọn fix gì trước.
2. **Tiêu chí "GA" cho AI là gì?** — latency p95? hallucination rate? eval pass rate? Feature nào lên GA trước (chat / notebook / eval)? Feature nào giữ Beta hoặc khai tử?
3. **Build hay defend?** — với 6 LEAPFROG (multi-LLM, eval, error-graph, golden SQL, notebook, storytelling): productize thành surface khách hàng (defend moat) hay tiếp tục build bề rộng mới?
4. **Convenience nợ ai trả?** — CONV-001 (no-code authoring) và CONV-002 (onboard tenant) là đòn bẩy business-model; ai own? DEV squad hay DA tooling?
5. **Storytelling — codify hay để bespoke?** — biến J1 thành framework layout tái dùng (CONV-004 LEAPFROG) hay tiếp tục làm tay từng widget?
6. **Số liệu đối thủ** — chấp nhận mức "định hướng" (5/7 từ training-cutoff) cho thảo luận nội bộ, hay cần refresh verify trước khi ra quyết định lớn?

---

## 10. Giới hạn của đánh giá & bước tiếp

**Giới hạn cần biết khi dùng tài liệu:**
- Snapshot tại commit `41b3863` (2026-05-22); nhánh `feat-vfr-late-alert` đang active → vùng widget/order-monitor sẽ tiếp tục đổi.
- MV tenant off-repo (`projects/{tenant}/`) **chưa được scan** (repo `helix_projects` riêng) — area #11 chỉ ghi nhận sự tồn tại.
- Convenience gap (`CONV`) là suy luận demand-side, **chưa verify bằng số liệu adoption thật** (cần `/da-ops` pulse).
- 5/7 hồ sơ đối thủ từ training-cutoff — TTL 30 ngày, refresh hạn **2026-06-25**.

**Bước tiếp theo (theo handoff matrix của `/da-po`):**
- `/da-po delta` ngày **2026-06-02** (re-quét phần code đã đổi + refresh competitor có release note mới) — không re-scan toàn bộ.
- Các item CATCH-UP/LEAPFROG → `/da-discovery` (frame 5 câu hỏi) **trước** khi sang `/ba`.
- Convenience item về luồng/UI → sau `/da-discovery` chuyển `/frontend-ux`; về narrative/layout → `/da-storytelling-data`.
- Verify tenant signal cho cluster D qua `/da-ops` pulse trước khi cam kết PRD.

**Lưu ý repo:** file này nằm trong `projects/po/` — thuộc repo `helix_projects` (gitignored khỏi repo chính). Muốn commit/push phải đi qua `/da-projects`. Tài liệu này **chưa commit**.

---

## Phụ lục — chỉ số tóm tắt

- **Tính năng**: ~48 feature / 13 capability area (area 14 Pricing N/A) · ~19 Beta, còn lại GA
- **Stack**: .NET 10 (Clean Arch + CQRS) · React 19 + TS · PostgreSQL + ClickHouse (MV per-tenant) · SqlKata+Fluid · Recharts · Monaco · OIDC · i18next (vi/en)
- **Quy mô code**: 42 controller · ~80 entity · 38 form config · 8 widget domain + lớp generic
- **Benchmark**: dẫn #7 + #12 · ngang ~6 area · tụt #1/#4/#8/#13 · đối thủ gần nhất: Sisense (mô hình) + Metabase (giá + dễ dùng)
- **Gap**: 26 `GAP` (10 CATCH-UP + 6 LEAPFROG + 4 KEEP + 6 IGNORE) + 7 `CONV` (6 CATCH-UP + 1 LEAPFROG)
- **Handoff queue → `/da-discovery`**: 16 `GAP` + 7 `CONV` = 23 item, gom 5 cluster
