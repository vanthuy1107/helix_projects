# UAT Reconciliation Matrix — {section} ({tenant})

> Template Mode A (empty) + Mode B (filled). File path Mode A: `{section}-uat-reconciliation-template.md`. File path Mode B: `{section}-uat-dryrun-{YYYY-MM-DD}.md`.
> Mode B fill 3 nguồn thật — Dashboard / SQL raw / Golden file khách. KHÔNG mark row PASS chỉ với 2 nguồn.

---

## 0. Metadata

| Field | Value |
|---|---|
| Section | `<vd: OTIF>` |
| Tenant | `<vd: Mondelez>` |
| Dry-run date | `<YYYY-MM-DD>` |
| Golden file source | `<path / file name khách gửi>` |
| Golden file received | `<YYYY-MM-DD HH:MM UTC+7>` |
| SQL raw source | `<ClickHouse analytics_workspace | Postgres LogDbContext | ...>` |
| Dashboard environment | `<UAT / staging URL>` |
| Time window | `<từ → đến, UTC+7>` |
| Tolerance ref | Section 7 của `{section}-uat-plan.md` |

## 1. Status tổng

(Fill sau khi run xong toàn bộ matrix)

| Metric | Value |
|---|---|
| Total rows | `<N>` |
| Pass (in tolerance) | `<N>` |
| Fail (out-of-tolerance, no root cause) | `<N>` — block session |
| Accepted (out-of-tolerance, khách accept với root cause) | `<N>` |
| Deferred (chưa resolve, convert thành defect open trước session) | `<N>` |
| **Ready for Mode C session?** | YES / NO |

## 2. Reconciliation rows

> Mỗi row đại diện 1 metric + 1 filter combination. Filter cần ghi rõ để re-run lần sau ra cùng số.

### Row R-001

| Field | Value |
|---|---|
| Metric | `<vd: Tổng đơn vận chuyển>` |
| Filter | NPP=ALL, kho=ALL, channel=ALL, date=2026-05-25 |
| Time window | 2026-05-25 00:00 → 23:59 UTC+7 |
| **Dashboard** | `<số đọc từ widget>` |
| **SQL raw** | `<số chạy SQL>` — query ref: Q-001 |
| **Golden file khách** | `<số từ file>` — row ref: `<sheet/row>` |
| Diff Dashboard − Golden | `<số>` (`<%>`) |
| Tolerance | ≤ 1% |
| **Status** | PASS / FAIL / ACCEPTED / DEFERRED |
| Root cause (nếu FAIL/ACCEPTED) | `<vd: khác cutoff timezone, golden tính 00:00 UTC+7 hôm trước; dashboard 23:00 UTC>` |
| Action | `<vd: dev FE fix timezone trong widget → retest>` |
| Owner | `<tên>` |

### Row R-002

| Field | Value |
|---|---|
| Metric | `<vd: % OTIF>` |
| Filter | NPP=ALL, kho=ALL, date=2026-05-25 |
| Time window | 2026-05-25 00:00 → 23:59 UTC+7 |
| **Dashboard** | `<%>` |
| **SQL raw** | `<%>` — Q-002 |
| **Golden file** | `<%>` |
| Diff (pp) | `<số pp>` |
| Tolerance | ≤ 0.5 pp |
| **Status** | |
| Root cause | |
| Action | |
| Owner | |

### Row R-003 — Ranking row

| Field | Value |
|---|---|
| Metric | Top 5 kho late |
| Filter | NPP=ALL, date=2026-05-25 |
| **Dashboard** (top 5 theo thứ tự) | 1.`<A>` 2.`<B>` 3.`<C>` 4.`<D>` 5.`<E>` |
| **SQL raw** (top 5) | 1.`<A>` 2.`<B>` 3.`<C>` 4.`<D>` 5.`<E>` |
| **Golden file** (top 5) | 1.`<A>` 2.`<B>` 3.`<D>` 4.`<C>` 5.`<F>` |
| Match count (Dashboard vs Golden) | `<X/5>` tên trong top 5 |
| Tolerance | ≥ 4/5 match |
| **Status** | |
| Root cause | |
| Action | |

### Row R-004 — Tổng bucket funnel

(Tương tự cho mỗi bucket L3)

### Row R-{NNN} — ...

(Thêm row cho mỗi metric cần reconcile — tối thiểu: tổng đơn, % chính, top N theo từng dimension L5, từng bucket L3, từng điểm L4 trend nếu cần)

## 3. Tổng số rows expected

Tối thiểu phải có cho 1 section:
- 1 row tổng đơn
- 1 row mỗi % metric chính (vd OTIF, OnTime, InFull = 3 rows)
- 1 row mỗi bucket funnel L3 (vd 5 bucket = 5 rows)
- 1 row top N cho mỗi dimension L5 (vd kho/khu vực/customer/channel = 4 rows)
- 1 row mỗi point đặc biệt L4 (vd ngày peak, ngày low — 2-3 rows)
- 1 row mỗi edge case quan trọng (vd timezone cutoff = 1-2 rows)

→ Total ~15-25 rows cho 1 view phức tạp như OTIF / Flash Daily.

## 4. Diff resolution status

(Roll-up của tất cả row có diff vượt tolerance)

| Status | Định nghĩa | Action trước session |
|---|---|---|
| **PASS** | Diff trong tolerance | Không action |
| **FAIL** | Diff vượt tolerance, chưa có root cause | Block session, phải resolve hoặc accept/defer |
| **ACCEPTED** | Diff vượt tolerance, có root cause, khách đã accept (ghi rõ ai accept, khi nào) | Note trong report |
| **DEFERRED** | Diff vượt tolerance, sẽ convert defect open trước session, khách biết trước | Tạo defect stub `defects/UAT-{NNN}-{slug}.md` |

**Rule cứng**: Không được có row FAIL khi bước vào Mode C session. Toàn bộ phải PASS/ACCEPTED/DEFERRED.

## 5. Appendix — SQL queries

### Q-001 — Tổng đơn vận chuyển

```sql
-- Source: <ClickHouse analytics_workspace>
-- Tenant: <tenant>
-- Time window: 2026-05-25 00:00 → 23:59 UTC+7
-- Run at: 2026-05-26 09:00 UTC+7

SELECT count(*) AS total_orders
FROM <table or MV>
WHERE <filter clause>
  AND <time window clause>;

-- Result: <số>
```

### Q-002 — % OTIF

```sql
-- ...
```

(Append mỗi SQL của mỗi row R-NNN)

## 6. Appendix — Golden file mapping

| Row | Golden file sheet | Golden file row/cell | Notes |
|---|---|---|---|
| R-001 | `<sheet name>` | `<row N, col M>` | |
| R-002 | | | |

Lưu ý: nếu golden file của khách không có sẵn metric — phải tính tay từ raw data khách. Ghi rõ công thức tính ở đây để re-produce.

## 7. Decision before Mode C

Ký xác nhận trước khi vào session:

| Role | Decision | Signed | Date |
|---|---|---|---|
| Smartlog PM | Ready / Not ready | | |
| Smartlog BA | Ready / Not ready | | |
| (Optional) Customer IT | Ack reconciliation | | |
