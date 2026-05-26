# UAT Execution Log — {section} ({tenant})

> Template Mode C (session với khách) + Mode D (retest round N).
> File path Mode C: `{section}-uat-execution-{YYYY-MM-DD}.md`.
> File path Mode D: `{section}-uat-retest-{N}-{YYYY-MM-DD}.md`.

---

## 0. Session metadata

| Field | Value |
|---|---|
| Mode | C (session 1) / D (retest N) |
| Date | `<YYYY-MM-DD>` |
| Time start | `<HH:MM UTC+7>` |
| Time end | `<HH:MM UTC+7>` |
| Duration | `<H giờ M phút>` |
| Location / channel | `<onsite | MS Teams | Zoom + meeting link>` |
| Plan ref | `{section}-uat-plan.md` |
| Cases ref | `{section}-uat-cases.md` |
| Dry-run ref | `{section}-uat-dryrun-<date>.md` |

## 1. Attendees

| Side | Name | Role |
|---|---|---|
| Customer | | SC Manager |
| Customer | | Key user |
| Customer | | IT representative |
| Smartlog | | PM (drive) |
| Smartlog | | BA (defect log) |
| Smartlog | | Dev on-call (Slack/standby) |

## 2. Pre-session checklist

- [ ] Dry-run report status = ready
- [ ] All filters reset về default
- [ ] Browser dev tools tắt
- [ ] Screenshot tool sẵn sàng
- [ ] Execution log file đã mở
- [ ] Defect stub template sẵn
- [ ] Reconciliation matrix mở sẵn để re-run nếu khách hỏi

## 3. Execution table

> Chạy theo thứ tự lớp **A → B → C → D**. Stop nếu lớp A fail nặng — không nên tiếp lớp B/C trên data sai.

| TC-ID | Layer | Lớp | Tiền điều kiện | Run time | P/F | Actual (tóm tắt) | Defect ID (nếu Fail) | Owner observe |
|---|---|---|---|---|---|---|---|---|
| UAT-{slug}-001 | L1 | A+B | NPP=ALL, hôm nay | 14:05 | P | % = 88.2, golden 87.0, trong tolerance | — | PM+SC Mgr |
| UAT-{slug}-002 | L1 | B | edge ngưỡng band | 14:08 | P | | — | |
| UAT-{slug}-003 | L2 | B+C | | 14:12 | F | Banner ko hiển thị khi < 80% | UAT-001 | |
| ... | | | | | | | | |

Status legend:
- **P** = Pass — actual khớp expected, khách + Smartlog cùng kết luận
- **F** = Fail — actual lệch expected, defect log đã tạo
- **B** = Blocked — không chạy được vì TC trước fail / data thiếu
- **D** = Deferred — hết giờ session, defer round retest (KHÔNG phải Skipped)
- **N/A** = Not applicable — TC không còn liên quan vì spec đã đổi

## 4. Reconciliation matrix re-run (in-session)

> Nếu khách yêu cầu xác nhận số live trong session — re-run 1-2 row chính, ghi vào đây.

| Row | Filter | Dashboard | Golden file | Diff | Status | Note |
|---|---|---|---|---|---|---|
| R-001 (tổng đơn) | hôm nay | | | | | |
| R-002 (% OTIF) | hôm nay | | | | | |

## 5. Defect summary (cuối session)

| Defect ID | Severity | tech_layer | Title | Status |
|---|---|---|---|---|
| UAT-001 | Major | frontend-widget | Banner ko hiển thị khi <80% | Open |
| UAT-002 | Minor | frontend-config | Drill-down từ L6 ko mang đúng date filter | Open |
| UAT-{NNN} | | | | |

Tổng:
- Critical: `<N>`
- Major: `<N>`
- Minor: `<N>`
- Cosmetic: `<N>`

## 6. Session closing notes

### Tổng TC chạy

- Pass: `<N>`
- Fail: `<N>`
- Blocked: `<N>`
- Deferred: `<N>` (lý do: `<hết giờ / blocker>`)
- N/A: `<N>`

### Pass rate

- Happy path: `<%>` (target ≥ 95%)
- Edge case: `<%>` (target ≥ 80%)

### Quote khách (verbatim, nếu có insight đáng ghi)

> "..." — `<tên SC Manager>`

### Decision next step

- [ ] Dev fix defect Open trong `<N>` ngày
- [ ] Retest round 1 scheduled: `<YYYY-MM-DD>`
- [ ] (Nếu nhiều defect) Triage qua `/da-triage` trước khi route dev
- [ ] (Nếu phát hiện business rule mới chưa có PRD) `/ba` revision trước retest

### Không signoff trong session này

→ Signoff chỉ ở Mode E sau khi pass criteria đạt.

## 7. (Mode D only) Retest delta vs round trước

| Metric | Round N-1 | Round N | Δ |
|---|---|---|---|
| Total TC retested | | | |
| Pass rate happy | | | |
| Defect Critical | | | |
| Defect Major | | | |
| New defect (regression) | | | |

### Defect changelog

| Defect ID | Round N-1 status | Round N status | Note |
|---|---|---|---|
| UAT-001 | Open | Verified-fixed | Dev fix commit `<sha>` |
| UAT-002 | Open | Reopened | Fix chưa giải quyết root cause, vẫn lệch |
| UAT-005 (new) | — | Open | Regression từ fix UAT-001 |

### Loop control

- [ ] Pass criteria đạt → Mode E signoff
- [ ] Còn Critical/Major → schedule retest round `<N+1>`
- [ ] Quá 3 round mà còn Critical → escalate `/da-pm`
