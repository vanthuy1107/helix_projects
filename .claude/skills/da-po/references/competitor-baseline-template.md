# Competitor baseline template

Template cho file `projects/po/_competitors/{vendor}.md`. 7 vendor cần baseline:

1. `powerbi.md` — Microsoft Power BI (primary competitor)
2. `tableau.md` — Tableau (Salesforce)
3. `looker.md` — Google Looker
4. `superset.md` — Apache Superset (OSS)
5. `metabase.md` — Metabase (freemium + OSS)
6. `sisense.md` — Sisense (embedded BI, gần case Smartlog nhất)
7. `qlik.md` — Qlik Sense (associative engine)

## TTL & refresh

- TTL mặc định: **30 ngày** kể từ `last_refresh_date`.
- Mode D bắt đầu bằng việc check TTL toàn bộ 7 file → file nào quá hạn HOẶC vendor có release notes mới trong window → re-fetch official docs để refresh.
- Refresh tối thiểu: capability matrix scores + pricing + release notes section. Profile + history giữ nguyên.

## Cấu trúc file (template)

```markdown
---
vendor: <Vendor Name>
slug: <lowercase-slug>
category: <Enterprise BI | Cloud BI | OSS BI | Embedded BI>
last_refresh_date: <YYYY-MM-DD>
last_refresh_commit_smartlog: <git short SHA of Smartlog HEAD at refresh time>
sources_consulted:
  - <official docs URL>
  - <pricing page URL>
  - <release notes URL>
  - <reviewer / G2 page URL (only for context, not facts)>
---

# <Vendor Name> — Capability baseline

## Profile

- **Vendor / Parent company**: <Microsoft | Salesforce | Google | ASF | Metabase Inc | Sisense Inc | Qlik Inc>
- **Founded / acquired**: <year>
- **License**: <Proprietary | OSS (Apache 2.0) | Dual>
- **Deployment**: <SaaS only | Self-host only | Both>
- **Primary user persona**: <Enterprise analyst | Citizen developer | Embedded ISV | OSS power user>
- **Logistics-vertical presence**: <Yes — examples | Generic — no vertical focus>

## Capability scores (14 areas)

Format mỗi area:
```
### {N}. {Capability name}
- **Presence**: ✓ | ◐ | ✗
- **Depth**: Deep | Medium | Shallow | n/a
- **Ease**: Easy | Moderate | Hard | n/a  (cho persona nào — P1 consumer / P2 author / P3 admin)
- **Evidence**: <URL doc cụ thể>
- **Notable**: <1 câu — gì đặc biệt, vd "DAX engine in-memory VertiPaq">
- **Ease note**: <1 câu — vd "DAX learning curve cao → Moderate cho P2; consume pre-built thì Easy cho P1">
- **Smartlog comparable**: <link tới capability tương ứng của ta, hoặc "n/a — ta chưa có">
```

> **Ease là trục thứ 3 bắt buộc** (xem `bi-capability-taxonomy.md` → "Convenience personas & journeys"). Đo bằng learning curve / số bước / khả năng self-serve — KHÔNG bằng "đẹp/xấu". Champion usability (vd Metabase) thường Easy ở #7/#5 dù Depth chỉ Medium — chính chỗ đó là điểm Smartlog dễ bị under-rate nếu chỉ nhìn presence×depth.

### 1. Data Connectors
- **Presence**: 
- **Depth**: 
- **Ease**: 
- **Evidence**: 
- **Notable**: 
- **Ease note**: 
- **Smartlog comparable**: 

### 2. Data Modeling
...

### 3. Query Engine / Semantic Layer
...

### 4. Visualization Library
...

### 5. Dashboard / Canvas
...

### 6. Filtering & Parameters
...

### 7. Self-service Authoring
...

### 8. Embedding & Sharing
...

### 9. Collaboration
...

### 10. Governance & RBAC
...

### 11. Performance & Scale
...

### 12. AI / ML
...

### 13. Mobile / Responsive
...

### 14. Pricing & Deployment
- **Model**: <per-user / per-capacity / per-tenant / free OSS>
- **Entry tier**: <USD/month, hoặc free>
- **Embedded license**: <Yes/No, conditions>
- **Evidence**: <pricing page URL>

## Strengths (top 3)
1. <1 câu, có evidence>
2. ...
3. ...

## Weaknesses (top 3)
1. <1 câu, có evidence>
2. ...
3. ...

## Usability posture (per persona)

Tóm tắt vendor này dễ/khó với từng persona (demand view, bổ trợ capability scores):

| Persona | Ease tổng thể | 1 câu vì sao |
|---|---|---|
| P1 — Business Consumer | Easy/Moderate/Hard | <vd "consume pre-built dashboard rất mượt"> |
| P2 — Citizen Author | Easy/Moderate/Hard | <vd "DAX/LookML learning curve"> |
| P3 — Admin/Embedder | Easy/Moderate/Hard | <vd "embed setup time"> |

## Recent releases (window: last 90 days)
| Version | Date | Notable changes affecting capability matrix |
|---|---|---|
| <v.X.Y> | <YYYY-MM-DD> | <area N: presence ✗→◐, ...> |

## Relevance lens — logistics SaaS

Khi compare với Smartlog (B2B logistics control tower), 3 area sau là filter chính:

| Area | Vì sao quan trọng cho Smartlog |
|---|---|
| 8. Embedding | Smartlog model = embedded per-tenant, không phải standalone analyst tool |
| 10. Governance / multi-tenant | JWT-claim tenant routing — đối thủ thường charge enterprise tier mới có RLS |
| 14. Pricing per-tenant | Smartlog cần biết đối thủ có cho embedded license không, giá bao nhiêu |

Note vào weaknesses nếu đối thủ thiếu một trong 3 above — đó là chỗ Smartlog có thể defend market.

## Open questions / unverified
- Q: <câu hỏi chưa fetch được trong refresh window>
- Q: <thêm>

## Refresh log
| Date | Refreshed by | What changed |
|---|---|---|
| <YYYY-MM-DD> | da-po Mode D | Initial baseline |
```

## Quick-fill defaults per vendor (chỉ Profile section, để tăng tốc lần đầu)

### powerbi.md
- Vendor: Microsoft
- License: Proprietary (Power BI Free + Pro $10/user/mo + Premium $20/user/mo + Premium Capacity)
- Deployment: SaaS (Power BI Service) + Desktop (free) + Embedded license
- Persona: Enterprise analyst, IT-led BI
- Logistics presence: Generic, no vertical
- Source URL roots: `https://learn.microsoft.com/en-us/power-bi/`, `https://powerbi.microsoft.com/pricing/`

### tableau.md
- Vendor: Salesforce (acquired 2019)
- License: Proprietary (Creator $75/user/mo, Explorer $42, Viewer $15)
- Deployment: Tableau Cloud (SaaS) + Server (self-host) + Public (free, public-only)
- Persona: Power analyst, visualization-first
- Logistics presence: Generic
- Source URL roots: `https://help.tableau.com/`, `https://www.tableau.com/pricing`

### looker.md
- Vendor: Google Cloud
- License: Proprietary (quote-based, ~$3K+/month entry)
- Deployment: SaaS only (Looker Studio Pro embedded)
- Persona: Data engineer + analyst, LookML modeling-first
- Logistics presence: Generic
- Source URL roots: `https://cloud.google.com/looker/docs`, `https://cloud.google.com/looker/pricing`

### superset.md
- Vendor: Apache Software Foundation (created at Airbnb)
- License: Apache 2.0 (OSS)
- Deployment: Self-host only (managed: Preset)
- Persona: OSS power user, data engineer
- Logistics presence: None
- Source URL roots: `https://superset.apache.org/docs/`

### metabase.md
- Vendor: Metabase Inc
- License: Dual — OSS (AGPL) + Cloud + Pro/Enterprise
- Deployment: Self-host (free OSS) + Cloud Starter $85/mo + Pro + Enterprise
- Persona: Citizen analyst, lightweight BI
- Logistics presence: None
- Source URL roots: `https://www.metabase.com/docs/`, `https://www.metabase.com/pricing`

### sisense.md
- Vendor: Sisense Inc (most similar to Smartlog model — embedded BI)
- License: Proprietary, quote-based
- Deployment: Cloud + On-prem + Embedded SDK
- Persona: ISV embedding analytics into product (logistics-relevant)
- Logistics presence: Vertical templates exist
- Source URL roots: `https://docs.sisense.com/`, `https://www.sisense.com/pricing/`

### qlik.md
- Vendor: Qlik Inc (Thoma Bravo owned)
- License: Proprietary (Qlik Sense Business $30/user/mo, Enterprise quote-based)
- Deployment: SaaS (Cloud) + Client-Managed (on-prem) + Embedded
- Persona: Enterprise analyst, associative-engine workflows
- Logistics presence: Vertical accelerators exist (supply chain)
- Source URL roots: `https://help.qlik.com/`, `https://www.qlik.com/us/pricing`

## Fact-check rules (rút từ memory feedback)

- KHÔNG dùng marketing slide, blog third-party, Reddit, hoặc G2 review làm primary source.
- KHÔNG dùng phrasing kiểu "PowerBI is the best" — không có verdict tuyệt đối, chỉ có capability score.
- Mỗi claim phải có URL doc, KHÔNG được paraphrase từ trí nhớ.
- Nếu vendor có nhiều tier khác nhau (Power BI Pro vs Premium) → mặc định score theo tier *mid-range business* (Pro level), ghi rõ tier vào Notable.
- Pricing thay đổi nhanh — luôn ghi `access date` cùng URL pricing page.

## Source priority order

1. **Official product docs** (`help.<vendor>.com`, `docs.<vendor>.com`)
2. **Official release notes / changelog**
3. **Official pricing page**
4. **Vendor SEC filings / earnings call** (chỉ cho context, không cho capability)
5. **Independent benchmarks** (TPC, Gartner MQ paywalled — chỉ note position, không paraphrase)
6. ❌ KHÔNG dùng: blog third-party, Reddit, Hacker News comments, Twitter

## Khi không fetch được

Nếu một capability không tìm thấy doc trong 5 phút:
- Ghi `Presence: unverified, Depth: unverified`
- Thêm vào "Open questions / unverified" với câu hỏi cụ thể
- KHÔNG đoán

Cell `unverified` không được handoff sang gap analysis cho đến khi resolved.
