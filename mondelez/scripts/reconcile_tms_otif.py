"""
reconcile_tms_otif.py
─────────────────────
Đối chiếu SỐ ĐƠN theo ngày giữa TMS report #25 và mv_otif → xuất file .md
(tách code khỏi kết quả). Đây là MẪU cho "file phân tích = .py, kết quả = .md".

Chiến lược:
  - Rollup hai nguồn về cùng grain ngày theo "Ngày gửi thầu" (trục reconcile chung).
  - Bind mọi chuỗi tiếng Việt qua tham số {x:String}/Array(String) — KHÔNG inline.
  - CHỈ tin cột số đơn (Δ + cờ 🟢🟡🔴); OT%/IF% hai nguồn khác mẫu số → tham khảo.

Cách chạy (từ thư mục gốc helix-projects/):
    python mondelez/scripts/reconcile_tms_otif.py
    python mondelez/scripts/reconcile_tms_otif.py --from 2026-05-01 --to 2026-05-28

Env (mondelez/.env): CLICKHOUSE_*.  Config nghiệp vụ: mondelez/da.toml.
"""
from __future__ import annotations

from pathlib import Path

import da
from da.macros import DT, NUM, ontime
from da.cli import build_parser, resolve


def fetch_tms_daily(client, cfg, dfrom: str, dto: str):
    """TMS #25 daily: số đơn + OT%/IF% (replica L2.2 notebook tms).
    OT% tính trên dòng 'Hoàn tất' với dung sai grace; IF% trên QtyBBGN ≥ QtyOrder."""
    tms = cfg.table("tms_report_25")
    grace = cfg.scope["ontime_grace_min"]
    so_valid = cfg.scope["so_valid"]   # mảnh SQL (identifier-level) → inline f-string, không bind
    sql = f"""
        SELECT toDate({DT('TenderedDate')})                                      AS ngay,
               uniqExact(OrderCode)                                              AS don_tms,
               round(100*countIf({ontime('DateToCome','ETA',grace)} AND DeliveryStatus = {{done:String}})
                     / nullIf(countIf(DeliveryStatus = {{done:String}}
                              AND {DT('DateToCome')} IS NOT NULL AND {DT('ETA')} IS NOT NULL), 0), 2) AS ontime_tms,
               round(100*countIf({NUM('QuantityBBGN')} >= {NUM('QuantityOrder')}
                              AND DeliveryStatus = {{done:String}} AND {NUM('QuantityOrder')} > 0)
                     / nullIf(countIf(DeliveryStatus = {{done:String}} AND {NUM('QuantityOrder')} > 0), 0), 2) AS infull_tms
        FROM {tms}
        WHERE {so_valid}
          AND MasterStatus IN {{mstatus:Array(String)}} AND OrderStatus IN {{ostatus:Array(String)}}
          AND toDate({DT('TenderedDate')}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
        GROUP BY ngay ORDER BY ngay
    """
    return da.run_df(client, sql, {
        "done": "Hoàn tất",
        "mstatus": cfg.scope["analysis_master_statuses"],
        "ostatus": cfg.scope["analysis_order_statuses"],
        "f": dfrom, "t": dto,
    })


def fetch_mv_daily(client, cfg, dfrom: str, dto: str):
    """mv_otif daily: uniqExact(so) + OT%/IF% trên count(so) (replica L3c notebook otif)."""
    mv = cfg.table("mv_otif")
    dc = cfg.scope["default_date_col"]
    sql = f"""
        SELECT toDate({dc})                                                       AS ngay,
               uniqExact(so)                                                      AS don_mv,
               round(100.0*countIf(ontime_status='Ontime')/nullIf(count(so),0),2) AS ontime_mv,
               round(100.0*countIf(infull_status='Infull')/nullIf(count(so),0),2) AS infull_mv
        FROM {mv}
        WHERE toDate({dc}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
        GROUP BY ngay ORDER BY ngay
    """
    return da.run_df(client, sql, {"f": dfrom, "t": dto})


def main() -> None:
    args = build_parser("Đối chiếu TMS report #25 ↔ mv_otif theo ngày → .md").parse_args()
    if not args.tenant:
        args.tenant = Path(__file__).resolve().parent.parent   # script sống trong mondelez/ → tenant của nó
    cfg, (dfrom, dto) = resolve(args)
    client = da.ch_client(cfg)

    fresh = da.meta(client, cfg.table("mv_otif"), cfg.scope["default_date_col"])
    tms = fetch_tms_daily(client, cfg, dfrom, dto)
    mv = fetch_mv_daily(client, cfg, dfrom, dto)

    rec = da.reconcile_by_day(tms, mv, count_a="don_tms", count_b="don_mv", amber=2)
    n_lech = int((rec["d_don"] != 0).sum())
    only_one = int((rec["_merge"] != "both").sum())

    cols = ["ngay", "don_tms", "don_mv", "d_don", "d_don_flag",
            "ontime_tms", "ontime_mv", "infull_tms", "infull_mv"]
    out = cfg.root / "reports" / f"tms-vs-otif-{dto.replace('-', '')}.md"
    path = da.save_md([
        f"**Window** `{dfrom}` → `{dto}` · trục `Ngày gửi thầu` (`{cfg.scope['default_date_col']}`)",
        f"- mv_otif freshness: max_date `{fresh.get('max_date')}`, trễ ~{fresh.get('lag_min')}′",
        f"- Số ngày lệch số đơn: **{n_lech}** / {len(rec)} ngày  (trong đó {only_one} ngày thiếu hẳn 1 phía)",
        "- Cờ Δ số đơn: 🟢 = 0 · 🟡 ≤ 2 · 🔴 > 2",
        "> Chỉ tin cột **số đơn** (Δ). OT%/IF% hai nguồn khác mẫu số (TMS tính trên dòng 'Hoàn tất'; "
        "mv_otif trên count(so)) → chỉ tham khảo.",
        rec[[c for c in cols if c in rec.columns]],
    ], out, title=f"Đối chiếu TMS #25 ↔ mv_otif — {cfg.name}")

    print(f"[OK] {path}")
    print(f"[INFO] {len(rec)} ngày · {n_lech} ngày lệch số đơn · {only_one} ngày thiếu 1 phía")


if __name__ == "__main__":
    main()
