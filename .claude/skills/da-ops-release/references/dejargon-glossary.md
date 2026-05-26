# De-jargon Glossary — Bóc thuật ngữ kỹ thuật cho Release PDF

> Source `/da-ops` viết cho analyst/PM/CS đọc — đầy tên schema, QueryConfig code, DbContext, framework keyword. Release PDF cho stakeholder tenant phải sạch hết những từ này.
> Quét từng dòng source, gặp từ bên trái → thay bằng từ bên phải (hoặc bỏ hẳn nếu cột "Bỏ" = ✓).

---

## 1. Tên schema, table, DbContext (database object)

| Source dùng | Release thay bằng | Bỏ luôn? |
|---|---|---|
| `logging.activity` | "hệ thống ghi nhận thao tác" / "dữ liệu hoạt động" | hoặc bỏ hẳn nếu trong câu narrative |
| `logging.entity` / `logging.related_entity` | "dữ liệu thao tác trên đối tượng" / bỏ | thường bỏ |
| `LogDbContext` / `AppDbContext` | bỏ — nội bộ tech | ✓ |
| `<schema>.<table>` (vd `tender.dbo.tenders`) | "phân hệ Tender" / "module Tender" | ✓ (giữ tên module business, bỏ schema/table) |
| `dbo.<entity>` / `[dbo]` | bỏ schema prefix | ✓ |
| `dim_*` / `dict_*` table | "danh mục [tham chiếu]" | thường bỏ |
| Connection string / `tenant_db = mondelez_prod` / `mondelez_prod_replica` | "DB Mondelez" (single-tenant audience) hoặc bỏ | ✓ |
| Claim `TenantDBConfiguration` | bỏ — nội bộ auth | ✓ |
| `ttc_control_tower` / `smartlog_control_tower` (DB name) | "hệ thống Smartlog Control Tower" | ✓ |
| `BFF query` / `query layer` / `endpoint /api/v1/...` | bỏ — không liên quan stakeholder | ✓ |
| `Refit` / `EF Core` / `SqlKata` / `MediatR` | bỏ — internal framework | ✓ |
| `DynamicQuery` / `QueryConfig` / `JSON config` | bỏ — internal config layer | ✓ |
| QueryConfig code (vd `SYSROLEG01`, `WMSOTIFG02`) | "báo cáo <tên business tương ứng>" hoặc bỏ | ✓ thường bỏ |

## 2. SQL & code-style identifiers

| Source dùng | Release thay bằng | Bỏ? |
|---|---|---|
| Code block ` ```sql ... ``` ` | bỏ toàn bộ section "Appendix — Data sources" | ✓ |
| `SELECT / FROM / WHERE / GROUP BY / JOIN / LIMIT` | bỏ | ✓ |
| `entity_code = 'TENDER_CREATE'` | "thao tác Tạo Tender" — chuyển sang tên business |
| `module = 'TXN_MOVE'` | "module Transaction Move" — giữ tên module business |
| `user_id = 87` / `user_email = ops_lead@mondelez.com` | nếu audience tenant: "ops_lead@mondelez.com"; nếu audience nội bộ Smartlog: "User Vận hành 1 (anonymized)" |
| `created_at = '2026-05-08 03:20:00'` UTC | "ngày 08/05/2026 lúc 10:20 (UTC+7)" — convert UTC+7 |
| `DeletedTime IS NULL` filter syntax | bỏ — internal soft-delete convention | ✓ |
| `CreatedBy` / `UpdatedBy` / `DeletedBy` columns | "người tạo" / "người cập nhật" / "người xoá" |
| `Run at: 2026-05-08T07:30; Rows: N` | bỏ | ✓ |
| Endpoint route (`POST /api/v1/tender/create`) | "thao tác Tạo Tender qua hệ thống" | ✓ thường bỏ |

## 3. Khái niệm DA/BA / framework keyword

| Source dùng | Release thay bằng | Bỏ? |
|---|---|---|
| **SCQA** (Situation/Complication/Question/Answer) | "Tóm tắt nhanh" / "Câu chuyện điều hành" |
| **Bottom Line / Bottom Line Up Front** | "Điểm cốt lõi" / "Tóm tắt nhanh" |
| **Headline 1 dòng** / **1-line headline** | "Câu mở" / bỏ heading, gộp vào Bối cảnh |
| **Insight 1 / Insight 2 / Insight N** (numbered) | bỏ numbering — mỗi insight thành 1 chương riêng với heading so-what | ✓ |
| **Q1 / Q2 / Q-baseline** ref tới Appendix | bỏ — không có Appendix trong release | ✓ |
| **Quan sát / So sánh / Giả thuyết / Đề xuất** (4-component label) | bỏ label — gộp thành câu chuyện chương: "Số liệu cho thấy..., so với..., có thể do..., cần làm..." | ✓ |
| **Open questions cho rollout team** | nếu audience tenant → BỎ (đó là internal handoff cho CS); nếu audience nội bộ Smartlog → "Câu hỏi cần xác minh" |
| **Pareto** / **80/20** | "Tập trung cao" / "Phần lớn từ một số ít" |
| **RAG** (Red/Amber/Green) | "Trạng thái" — trong PDF dùng badge xanh/vàng/đỏ trực quan, không gọi tên RAG |
| **CV** / **Coefficient of Variation** | "Mức dao động" / "Độ ổn định" |
| **Outlier** | "Trường hợp bất thường" / "Điểm lệch" (rồi giải thích) |
| **Distribution** | "Phân bố" |
| **Sparkline** | "biểu đồ xu hướng nhỏ" — hoặc bỏ |
| **Heatmap** | "ma trận màu" — render CSS table với background color cells |
| **Percentile / Quartile / P95** | "nhóm cao nhất 5%" / "nhóm trên cùng 25%" |
| **Funnel** (khởi tạo → thành công → fail) | "luồng hoàn thành" / "tỷ lệ qua từng bước" |
| **Adoption** / **Reach** / **Depth** / **Friction** | nếu audience SC Manager → giữ ("mức tiếp cận", "độ sâu sử dụng", "ma sát"); nếu audience BOD → "tỷ lệ user dùng feature" / "mức độ tích cực" / "khó khăn vận hành" |
| **Action title** | trong PDF không gọi "action title", chỉ là **heading** của chương — đảm bảo so-what |
| **Drilldown** / **Drill-in** | "Phân tích chi tiết" / "Đi sâu vào" |
| **Time pattern** / **Peak sáng / Peak chiều** | "Nhịp giờ trong ngày" / "Giờ cao điểm sáng/chiều" |
| **Silence** / **No-news cũng là news** | "Khoảng yên lặng đáng chú ý" / "Không thao tác cũng là tín hiệu" |

## 4. Internal status / project lingo

| Source dùng | Release thay bằng | Bỏ? |
|---|---|---|
| "Activity log chưa bật cho module X" | "Hiện tại hệ thống chưa ghi nhận chi tiết thao tác cho module X" — giữ insight, ẩn từ "activity log" |
| "[N/A — chưa query được]" / "[N/A — connection thiếu]" / "[N/A — log chưa bật]" | "Số liệu này chưa sẵn sàng trong kỳ báo cáo" — hoặc bỏ row khỏi bảng nếu rỗng quá nửa |
| "BUG-012" / "TICKET-XXX" / "Sprint X" reference | bỏ | ✓ |
| "BFF query layer" / "Fastify" / "Vite" / "TanStack Query" | bỏ — internal stack | ✓ |
| "QueryConfig `<code>`" / "FormConfig `<code>`" | bỏ — internal config layer | ✓ |
| "MVP_SPEC §X" / "BUILD_LOG.md" / "ROADMAP.md" | bỏ — internal docs | ✓ |
| "Generated by /da-ops (Claude)" | đổi thành "Soạn bởi đội Vận hành Smartlog Control Tower" hoặc bỏ |
| "Audience: Operations, Rollout, SC Planning" tag | bỏ — audience của release đã chốt ở R2 | ✓ |
| "Re-query" / "Re-run query" / "Cần re-query baseline" | bỏ — internal action | ✓ |
| "Pulled at: 2026-05-08 14:30 UTC+7" | "Số liệu chốt ngày 08/05/2026 lúc 14:30" — đặt ở footer 1 dòng |

## 5. Bảng & breakdown — bóc về dạng business

| Source dùng | Release xử lý |
|---|---|
| Bảng "Key numbers" với cột `Source` / `Q?` ref | Bỏ cột `Source`. Header đổi: "Module" / "Volume hôm nay" / "So với 4 tuần trước" / "Δ" |
| Bảng "User activity" với cột `email` / `role` / `actions` / `Source` | Bỏ cột `Source`. Header: "Người dùng" / "Vai trò" / "Số thao tác" / "Quan sát". Sanitize email cross-tenant |
| Bảng "Reach / Depth / Friction" (adoption) | Giữ structure; bỏ cột `Source`. Đổi header tiếng Việt: "Số user chạm feature", "Tỷ lệ user dùng lặp lại", "Số lỗi", "Tỷ lệ bỏ giữa chừng", "Thời gian hoàn thành (median)" |
| Bảng có cột `[N/A]` ≥ 50% rows | Bỏ bảng — không phải dữ liệu để release; đẩy vào Bối cảnh dưới dạng câu "Trong kỳ này, một số chỉ số chưa sẵn sàng do..." |
| Bảng "Hypotheses" (anomaly note) | Mỗi hypothesis thành 1 đoạn ngắn trong Câu chuyện chương — không giữ dạng bảng |

## 6. Tenant codes — phân biệt 2 nhóm

Source `/da-ops` đã expand đầy đủ tên tenant lần đầu mention. Release giữ nguyên cách dùng — chỉ kiểm tra:

- **Tenant code chính thức** (`mondelez`, `acme`, `customer-x`) → lần đầu dùng `<Tên đầy đủ>` (vd "Mondelez Việt Nam"), sau đó dùng tên ngắn ("Mondelez") OK. KHÔNG dùng alias DB internal (`mondelez_prod`, `mondelez_prod_replica`)
- **Cross-tenant data** trong báo cáo cho 1 tenant cụ thể → BỎ hết. Nếu cần giữ baseline so sánh → anonymize "Tenant tham chiếu A/B/C" và chỉ ghi % chứ không ghi số tuyệt đối
- **Tenant chưa active / sandbox / demo** → không nhắc trong release production; nếu source có lẫn vào → flag warning trong delivery

## 7. Tên user / module / entity

Source đã JOIN dim/dictionary (nếu có) hoặc query trực tiếp activity log → tên thường có sẵn dạng business. Release giữ nguyên. Chỉ chú ý:

- **Email user**: nếu audience là tenant của user đó → giữ thật (`ops_lead@mondelez.com`). Nếu audience là Smartlog nội bộ và muốn anonymize → "Operator Mondelez 1". KHÔNG bao giờ lộ email user của tenant khác (cross-tenant leak).
- **Module name** business (Tender, VFR, Transaction Move, Flash Daily widget, Quick Order, Demand Planning...): GIỮ — đây là từ tenant đã quen từ training. KHÔNG dịch sang tiếng Việt mới (vd không đổi "Tender" → "Đấu thầu" trừ khi tenant đã đặt tên Việt riêng).
- **Entity code** business (vd `TENDER_CREATE`, `VFR_SUBMIT`): chuyển sang tên thao tác đời thường ("Tạo Tender", "Gửi VFR").
- **Widget name** (vd `WidgetTxnMove`, `WidgetFlashDaily`): chuyển về tên hiển thị tiếng Việt nếu UI có sẵn ("Widget Transaction Move", "Widget Flash Daily" — chỉ bỏ prefix `Widget` nếu source đã bỏ).

---

## Checklist sau khi de-jargon (tự verify trước R5)

- [ ] Không còn `logging.*` / `<schema>.<table>` trong markdown trung gian
- [ ] Không còn `LogDbContext` / `AppDbContext` / `EF Core` / `Refit` / `BFF` / `QueryConfig` / `DynamicQuery`
- [ ] Không còn block ` ```sql `
- [ ] Không còn từ "SCQA" / "Pareto" / "RAG" / "CV" / "Sparkline" / "Heatmap" / "Drilldown" / "Outlier" (nếu có thì đã giải thích đời thường)
- [ ] Không còn section "Appendix — Data sources" (technical)
- [ ] Không còn section "Open questions cho rollout team" (nếu audience tenant)
- [ ] Không còn `entity_code = '...'` / `module = '...'` style filter syntax
- [ ] Không còn reference `Q1` / `Q2` / `Q?-baseline` trỏ về Appendix
- [ ] Không còn alias DB technical (`mondelez_prod`, `*_replica`) — chỉ tên tenant đầy đủ
- [ ] Không còn email user của tenant khác trong báo cáo cho 1 tenant cụ thể (cross-tenant sanitization)
- [ ] Không còn timestamp UTC chưa convert UTC+7
- [ ] Heading section không còn "Insight 1 / 2 / 3" — mỗi insight có heading so-what riêng
- [ ] Footer chỉ 1 dòng tổng quan: "Số liệu chốt từ hệ thống Smartlog Control Tower lúc <timestamp UTC+7> · soạn ngày <generated-at>"
- [ ] Không còn placeholder `<chưa query>` / `<...>` (nếu có thì đã chuyển thành "Số liệu chưa sẵn sàng trong kỳ" hoặc bỏ row)

Nếu còn ≥1 mục chưa pass → quay lại R3 quét tiếp.
