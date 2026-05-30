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
    python mondelez/scripts/analysis/reconcile_tms_otif.py
    python mondelez/scripts/analysis/reconcile_tms_otif.py --from 2026-05-01 --to 2026-05-28

Env (mondelez/.env): CLICKHOUSE_*.  Config nghiệp vụ: mondelez/da.toml.
"""
from __future__ import annotations

from pathlib import Path

import pandas as pd

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


def fetch_tms_orders(client, cfg, dfrom: str, dto: str):
    """Tập ĐƠN TMS #25 theo (ngày gửi thầu, OrderCode) + trường CHẨN ĐOÁN lệch.

    Filter PHẢI khớp y hệt fetch_tms_daily (so_valid + master/order status + cùng
    trục ngày) → đơn trong set-diff chính là đơn tạo nên Δ số đơn của bảng daily.
    `any()` lấy 1 giá trị đại diện khi đơn vào nhiều chuyến (grain = đơn, không nở);
    `min(TenderedDate)` = giờ gửi thầu sớm nhất (giờ VN) để soi lệch biên ngày TZ."""
    tms = cfg.table("tms_report_25")
    so_valid = cfg.scope["so_valid"]
    sql = f"""
        SELECT toDate({DT('TenderedDate')})  AS ngay,
               OrderCode                      AS code,
               min({DT('TenderedDate')})      AS ts_tms,
               any(ServiceOfOrderName)        AS dichvu_tms,
               any(DeliveryStatus)            AS tt_tms,
               any(MasterCode)                AS chuyen_tms
        FROM {tms}
        WHERE {so_valid}
          AND MasterStatus IN {{mstatus:Array(String)}} AND OrderStatus IN {{ostatus:Array(String)}}
          AND toDate({DT('TenderedDate')}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
        GROUP BY ngay, code
    """
    return da.run_df(client, sql, {
        "mstatus": cfg.scope["analysis_master_statuses"],
        "ostatus": cfg.scope["analysis_order_statuses"],
        "f": dfrom, "t": dto,
    })


def fetch_mv_orders(client, cfg, dfrom: str, dto: str):
    """Tập ĐƠN mv_otif theo (ngày gửi thầu, so) + trường CHẨN ĐOÁN lệch.

    Filter khớp fetch_mv_daily (chỉ lọc theo ngày) → set-diff khớp Δ số đơn daily.
    `min(thoi_gian_gui_thau)` = giờ gửi thầu (giờ UTC) để soi lệch biên ngày TZ;
    `otif_status` = trạng thái OTIF tổng để biết đơn này được tính thế nào ở mv."""
    mv = cfg.table("mv_otif")
    dc = cfg.scope["default_date_col"]
    sql = f"""
        SELECT toDate({dc})      AS ngay,
               so                AS code,
               min({dc})         AS ts_mv,
               any(otif_status)  AS otif_mv
        FROM {mv}
        WHERE toDate({dc}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
        GROUP BY ngay, code
    """
    return da.run_df(client, sql, {"f": dfrom, "t": dto})


_DETAIL_CAP = 300       # trần an toàn cho bảng chi tiết đơn cần truy (tránh .md/.html phình)
_COVERAGE_MIN = 0.5     # nguồn yếu < 50% nguồn mạnh ⇒ coverage chưa đủ (không phải lệch từng đơn)


def _classify_diff(tms_ord, mv_ord) -> dict:
    """Set-diff theo (ngay, code) → PHÂN LOẠI đơn lệch tập (không để 'lệch' trần).

    Tách hai loại (xem /da-py §6.1 bước 4):
      📭 coverage gap — ngày thiếu hẳn MỘT nguồn, hoặc một nguồn hiện diện nhưng
         < _COVERAGE_MIN nguồn kia (ingest dở dang, thường là ngày biên cửa sổ).
         Lệch cả ngày, KHÔNG truy từng đơn — đã thấy ở Δ daily.
      🔎 lệch trong ngày CÓ ĐỦ hai nguồn — đơn thật sự cần truy nguyên nhân.

    Trả dict: counts + by_day (tổng hợp theo ngày) + detail (chỉ phần 🔎) + gap_note.
    """
    od = da.full_outer_by(tms_ord, mv_ord, on=["ngay", "code"])
    diff = od[od["_merge"] != "both"].copy()
    n_tms_only = int((diff["_merge"] == "left_only").sum())
    n_mv_only = int((diff["_merge"] == "right_only").sum())
    if diff.empty:
        return {"n_diff": 0, "n_tms_only": 0, "n_mv_only": 0, "n_real": 0,
                "by_day": None, "detail": None, "gap_note": None}

    # Tổng số đơn MỖI nguồn có theo ngày → đo coverage (phân biệt ingest dở vs lệch thật).
    tms_cnt = tms_ord.groupby("ngay")["code"].nunique()
    mv_cnt = mv_ord.groupby("ngay")["code"].nunique()

    def _day_kind(d) -> str:
        t, m = int(tms_cnt.get(d, 0)), int(mv_cnt.get(d, 0))
        if t == 0:                            # cả ngày không có đơn TMS
            return "📭 thiếu TMS cả ngày"
        if m == 0:                            # cả ngày không có đơn mv_otif
            return "📭 thiếu mv_otif cả ngày"
        lo, hi = min(t, m), max(t, m)
        if lo / hi < _COVERAGE_MIN:           # một nguồn hiện diện nhưng quá thiếu
            weak = "TMS" if t < m else "mv_otif"
            return f"📭 {weak} thiếu nhiều ({lo}/{hi})"
        return "🔎 lệch trong ngày"

    by_rows = [{
        "ngày": str(d)[:10],
        "chỉ TMS": int((diff[diff["ngay"] == d]["_merge"] == "left_only").sum()),
        "chỉ mv_otif": int((diff[diff["ngay"] == d]["_merge"] == "right_only").sum()),
        "loại": _day_kind(d),
    } for d in sorted(diff["ngay"].unique())]
    by_day = pd.DataFrame(by_rows)

    gap = by_day[by_day["loại"].str.startswith("📭")]
    gap_note = " · ".join(
        f"`{r['ngày']}` {r['loại'].replace('📭 ', '')}: {r['chỉ TMS'] + r['chỉ mv_otif']} đơn"
        for _, r in gap.iterrows()
    ) if not gap.empty else None

    real = diff[diff["ngay"].map(_day_kind) == "🔎 lệch trong ngày"].copy()
    detail = None
    if not real.empty:
        # code -> các ngày đơn xuất hiện ở MỖI nguồn (toàn cửa sổ) → chẩn đoán lệch:
        # đơn chỉ-TMS mà CÓ ở mv_otif ngày khác ⇒ lệch biên ngày (TZ), không phải mất đơn.
        tms_map = tms_ord.groupby("code")["ngay"].apply(
            lambda s: sorted({str(x)[:10] for x in s})).to_dict()
        mv_map = mv_ord.groupby("code")["ngay"].apply(
            lambda s: sorted({str(x)[:10] for x in s})).to_dict()

        def _crosscheck(r) -> str:
            if r["_merge"] == "left_only":            # chỉ TMS → có ở mv_otif ngày nào?
                days = mv_map.get(r["code"])
                return f"⏱ ở mv_otif {','.join(days)}" if days else "∅ không có ở mv_otif"
            days = tms_map.get(r["code"])              # chỉ mv_otif → có ở TMS ngày nào?
            return f"⏱ ở TMS {','.join(days)}" if days else "∅ không có ở TMS"

        real["nguồn"] = real["_merge"].map({"left_only": "🔵 chỉ TMS",
                                            "right_only": "🟠 chỉ mv_otif"})
        real["gửi thầu"] = (pd.to_datetime(real["ts_tms"].fillna(real["ts_mv"]))
                            .dt.strftime("%Y-%m-%d %H:%M")).fillna("—")
        real["dịch vụ (TMS)"] = real["dichvu_tms"].fillna("—")
        real["trạng thái"] = real["tt_tms"].fillna(real["otif_mv"]).fillna("—")
        real["đối chiếu chéo"] = real.apply(_crosscheck, axis=1)
        real["chuyến (TMS)"] = real["chuyen_tms"].fillna("—")
        detail = (real.rename(columns={"ngay": "ngày", "code": "mã đơn"})
                      .sort_values(["ngày", "nguồn", "mã đơn"])
                      [["ngày", "mã đơn", "nguồn", "gửi thầu", "dịch vụ (TMS)",
                        "trạng thái", "đối chiếu chéo", "chuyến (TMS)"]]
                      .reset_index(drop=True))

    return {"n_diff": len(diff), "n_tms_only": n_tms_only, "n_mv_only": n_mv_only,
            "n_real": 0 if detail is None else len(detail),
            "by_day": by_day, "detail": detail, "gap_note": gap_note}


def build(client, cfg, dfrom: str, dto: str) -> dict:
    """Dựng blocks + metadata reconcile (KHÔNG ghi file) — main() và run_all.py
    cùng tái dùng. Trả dict: blocks/title/stem/headline/fresh/status."""
    fresh = da.meta(client, cfg.table("mv_otif"), cfg.scope["default_date_col"])
    tms = fetch_tms_daily(client, cfg, dfrom, dto)
    mv = fetch_mv_daily(client, cfg, dfrom, dto)

    rec = da.reconcile_by_day(tms, mv, count_a="don_tms", count_b="don_mv", amber=2)
    n_lech = int((rec["d_don"] != 0).sum())
    only_one = int((rec["_merge"] != "both").sum())

    # ── Tầng CHI TIẾT: đơn lệch tập để tracking (set-diff theo (ngay, code)) ──
    d = _classify_diff(fetch_tms_orders(client, cfg, dfrom, dto),
                       fetch_mv_orders(client, cfg, dfrom, dto))

    cols = ["ngay", "don_tms", "don_mv", "d_don", "d_don_flag",
            "ontime_tms", "ontime_mv", "infull_tms", "infull_mv"]
    blocks = [
        f"**Window** `{dfrom}` → `{dto}` · trục `Ngày gửi thầu` (`{cfg.scope['default_date_col']}`)",
        f"- mv_otif freshness: max_date `{fresh.get('max_date')}`, trễ ~{fresh.get('lag_min')}′",
        f"- Số ngày lệch số đơn: **{n_lech}** / {len(rec)} ngày  (trong đó {only_one} ngày thiếu hẳn 1 phía)",
        f"- Đơn lệch tập (chỉ 1 nguồn): **{d['n_diff']}** "
        f"(🔵 {d['n_tms_only']} chỉ TMS · 🟠 {d['n_mv_only']} chỉ mv_otif) — "
        f"trong đó **{d['n_real']}** đơn cần truy (ngày đủ 2 nguồn), còn lại do coverage-gap ngày biên",
        "- Cờ Δ số đơn: 🟢 = 0 · 🟡 ≤ 2 · 🔴 > 2",
        "> Chỉ tin cột **số đơn** (Δ). OT%/IF% hai nguồn khác mẫu số (TMS tính trên dòng 'Hoàn tất'; "
        "mv_otif trên count(so)) → chỉ tham khảo.",
        "## Đối chiếu số đơn theo ngày",
        rec[[c for c in cols if c in rec.columns]],
        "## Đơn lệch tập — tổng hợp theo ngày",
        "> 📭 = ngày thiếu hẳn một nguồn (coverage gap, KHÔNG truy từng đơn — đã thấy ở Δ daily) · "
        "🔎 = lệch trong ngày có đủ 2 nguồn (đơn thật sự cần truy bên dưới).",
    ]
    if d["by_day"] is None:
        blocks.append("✅ Không có đơn lệch tập — hai nguồn khớp hoàn toàn theo (ngày, mã đơn).")
    else:
        blocks.append(d["by_day"])
        if d["gap_note"]:
            blocks.append(f"- Ngày coverage-gap: {d['gap_note']}")

    blocks += [
        "## Chi tiết đơn cần truy (🔎 ngày đủ 2 nguồn)",
        "> Cột chẩn đoán nguyên nhân lệch: **`đối chiếu chéo`** = mã đơn có ở nguồn kia ngày nào không "
        "— `⏱ ở … {ngày}` ⇒ nghi **lệch biên ngày timezone** (mv_otif giờ **UTC**, TMS giờ **VN**, "
        "chênh 7h); `∅ không có` ⇒ đơn thật sự chỉ một nguồn (khác service / chưa đẩy). "
        "**`dịch vụ (TMS)`** ≠ `Xuất bán` ⇒ lý do mv_otif (chỉ scope `Xuất bán`) không có đơn. "
        "`gửi thầu`: TMS giờ VN, mv_otif giờ UTC. `mã đơn` = `OrderCode` (TMS) / `so` (mv_otif).",
    ]
    if d["detail"] is None:
        blocks.append("✅ Không có đơn lệch trong ngày đủ 2 nguồn — mọi lệch tập đều do coverage-gap ngày biên.")
    else:
        if d["n_real"] > _DETAIL_CAP:
            blocks.append(f"> ⚠️ Bảng giới hạn {_DETAIL_CAP}/{d['n_real']} đơn (sort theo ngày). "
                          "Chạy script/notebook để lấy đủ nếu cần truy hết.")
        blocks.append(d["detail"].head(_DETAIL_CAP))

    # Status: 🟢 khớp hoàn toàn · 🟡 lệch nhẹ · 🔴 lệch nặng (đơn CẦN TRUY là tín hiệu chính)
    if n_lech == 0 and d["n_diff"] == 0:
        status = "🟢"
    elif n_lech <= 2 and d["n_real"] <= 5:
        status = "🟡"
    else:
        status = "🔴"
    return {
        "blocks": blocks,
        "title": f"Đối chiếu TMS #25 ↔ mv_otif — {cfg.name}",
        "stem": f"tms-vs-otif-{dto.replace('-', '')}",
        "headline": f"{len(rec)} ngày · {n_lech} ngày lệch số đơn · "
                    f"{d['n_diff']} đơn lệch tập ({d['n_real']} cần truy)",
        "fresh": fresh,
        "status": status,
    }


def main() -> None:
    args = build_parser("Đối chiếu TMS report #25 ↔ mv_otif theo ngày → .md + .html").parse_args()
    if not args.tenant:
        args.tenant = next(p for p in Path(__file__).resolve().parents
                           if (p / "da.toml").exists())  # tenant root = nơi có da.toml (relocation-proof)
    cfg, (dfrom, dto) = resolve(args)
    client = da.ch_client(cfg)

    r = build(client, cfg, dfrom, dto)
    out = cfg.root / "reports" / f"{r['stem']}.md"
    da.save_md(r["blocks"], out, title=r["title"])
    da.save_html(r["blocks"], out.with_suffix(".html"), title=r["title"])

    print(f"[OK] {out}  +  {out.with_suffix('.html').name}")
    print(f"[INFO] {r['headline']}")


if __name__ == "__main__":
    main()
