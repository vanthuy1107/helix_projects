# RULE-OTIF-001: Ontime tolerance — ETA + 30 phút vs ATA

- **Source**: Decision-record nội bộ (KHÔNG có trong Excel MDLZ gốc) — confirmed by PM 2026-05-16
- **Reporter**: PM Mondelez / Customer feedback synthesis
- **Tenant**: MDLZ
- **Area**: OrderMonitoring (OTIF widget — ảnh hưởng `% Ontime`, `% OTIF` rollup, mọi chart cắt Ontime)
- **Severity**: N/A — business-rule clarification, KHÔNG phải bug
- **Priority**: **Major** — Ảnh hưởng định nghĩa metric công bố ra Ops Manager Mondelez
- **Triage confidence**: High
- **View**: OTIF
- **Tech layer**: `etl-data` — DDL ClickHouse MV `analytics_workspace.mv_otif` (logic `ontime_status`)
- **Owner team**: `da` — Data Analyst (cập nhật MV DDL + spec, propagate xuống PRD/spec/business-rules-trace)

## Rule mới (PM-approved 2026-05-16)

> **Một đơn được xem là Ontime khi `ETA + 30 phút ≥ ATA`** (tolerance 30 phút áp dụng vào vế ETA, KHÔNG vào ATA).
>
> Tương đương: `ATA ≤ ETA + INTERVAL 30 MINUTE` → `Ontime`. Ngược lại → `Failed Ontime`.

Rule cũ trong DDL hiện tại (xem [business-rules-trace-2026-05-13.md §2.1](../../../01-sections/otif/analysis/business-rules-trace-2026-05-13.md)):

```sql
-- Trước:
p.`ETA (Giao hàng cho NPP)` <  p.`ATA đến`, 'Failed Ontime',
p.`ETA (Giao hàng cho NPP)` >= p.`ATA đến`, 'Ontime',
```

Rule mới (PM-approved):

```sql
-- Sau:
p.`ETA (Giao hàng cho NPP)` + INTERVAL 30 MINUTE <  p.`ATA đến`, 'Failed Ontime',
p.`ETA (Giao hàng cho NPP)` + INTERVAL 30 MINUTE >= p.`ATA đến`, 'Ontime',
```

## Why

Customer Mondelez confirm rằng dispatch operations cần grace window 30 phút (xếp dỡ, chờ xe, traffic) — đơn delivered trễ trong vòng 30 phút so với ETA vẫn coi là on-time về business intent. Không có tolerance → `% Ontime` bị deflated giả tạo, false-flag NVC.

## Impact

| Phần | Tác động |
|---|---|
| **% Ontime** | Tăng nhẹ (giải toả false-negative grace-window) — magnitude phụ thuộc data Mondelez |
| **% OTIF** | Tăng nhẹ (do Ontime là 1 trong 2 thành phần của OTIF rollup) |
| **% Infull** | KHÔNG đổi (chỉ rule Ontime thay đổi) |
| **Charts cắt Ontime** | Toàn bộ chart fail-ontime-reason, by-transporter, by-area v.v. cập nhật |
| **Detail table** | Cột `Trạng thái Ontime` đổi value cho ~border-case đơn (ATA trong khoảng [ETA, ETA+30m]) |

## Status

✅ **DONE 2026-05-16** — DDL MV ClickHouse updated. Verify backfill historical: TBD nếu Mondelez yêu cầu re-baseline trend cũ.

## History

| Date | Event | Actor | Ref |
|---|---|---|---|
| 2026-05-13 | business-rules-trace v1 documented rule **không có tolerance** (`ETA >= ATA`) | /da-data | [business-rules-trace-2026-05-13.md §2.1](../../../01-sections/otif/analysis/business-rules-trace-2026-05-13.md) |
| 2026-05-16 | PM Mondelez approve rule mới — DDL MV `mv_otif` ontime_logic updated, deploy parallel với BUG-042 fix | PM | conversation 2026-05-16 |

## Follow-up (KHÔNG block Go-Live)

1. Update [`01-sections/otif/spec.md`](../../../01-sections/otif/spec.md) — bổ sung note về tolerance 30 phút trong định nghĩa Ontime
2. Update [`business-rules-trace-2026-05-13.md`](../../../01-sections/otif/analysis/business-rules-trace-2026-05-13.md) §2.1 + §3 — paraphrase business: "đơn ontime khi ATA ≤ ETA + 30 phút"
3. Update [`01-sections/otif/prd.md`](../../../01-sections/otif/prd.md) §3 + §13 — cập nhật định nghĩa Ontime; nếu chưa có changelog v1.2.7 → ghi vào
4. Re-baseline pulse note OTIF tiếp theo phải dùng rule mới + caveat so vs pulse cũ
5. Glossary [`docs/shared/business-rules.md`](../../../../../docs/shared/business-rules.md) — bổ sung tolerance convention

## Liên quan

- [BUG-042 (Done)](../etl-data/%5BD%5D-BUG-042-otif-stm-lineno-strip-mismatch.md) — fix Infull sync; combined với rule này = double impact lên % Ontime + % Infull → metric chính thức phải dùng cả 2 fixes.
- [`go-live-tracker.md`](../../../go-live-tracker.md) — Go-Live tracker overall

## Next

KHÔNG cần action coding. Follow-up doc updates đã liệt kê — non-blocker cho Go-Live nhưng nên xong trước formal stakeholder communication next pulse.
