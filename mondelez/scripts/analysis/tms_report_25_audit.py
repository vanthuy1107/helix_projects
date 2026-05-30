"""
tms_report_25_audit.py
──────────────────────
Audit "lặp-lại-được" của TMS report #25 (bảng `mdlz_tms_report_25_trip_order`)
→ xuất file .md (tách code khỏi kết quả). Port từ notebook
`mondelez/notebooks/tms_report_25_explore.ipynb`.

Notebook gốc THIÊN VỀ TRA CỨU TƯƠNG TÁC (1 đơn theo OrderCode, 1 chuyến theo
MasterCode, summary 1 ngày tự chọn, danh sách fail OTIF, đối chiếu mv_otif). Những
phần đó CỐ TÌNH ĐỂ LẠI cho notebook explore — xem mục "Để lại cho notebook" trong
.md. Script này chỉ port các phần CHẠY-ĐỊNH-KỲ-ĐƯỢC trên một window:

  1. Quy mô & freshness toàn bảng (sau filter SO_VALID).
  2. KPI theo ngày trong window (theo TenderedDate / "Ngày gửi thầu"):
     số đơn (uniqExact OrderCode), số chuyến, % On-time, % In-full — áp scope
     ANALYSIS_FILTER (MasterStatus/OrderStatus bind qua Array(String)).
  3. Phân bố trạng thái (MasterStatus / OrderStatus / DeliveryStatus) trong window.
  4. Check toàn vẹn cơ bản: đơn 'Hoàn tất' thiếu thời gian (không chấm được On-time),
     đơn trên nhiều chuyến.

Quy ước binding (xem da.ch): VALUE tiếng Việt ('Hoàn tất', mảng MasterStatus/
OrderStatus) → bind qua params {x:String}/{x:Array(String)}. so_valid là MẢNH SQL
(identifier-level) → nội suy f-string.

Cách chạy (từ thư mục gốc helix-projects/):
    python mondelez/scripts/analysis/tms_report_25_audit.py
    python mondelez/scripts/analysis/tms_report_25_audit.py --from 2026-05-01 --to 2026-05-28

Env (mondelez/.env): CLICKHOUSE_*.  Config nghiệp vụ: mondelez/da.toml.
"""
from __future__ import annotations

from pathlib import Path

import da
from da.macros import DT, NUM, ontime
from da.cli import build_parser, resolve

DONE = "Hoàn tất"   # DeliveryStatus = đã giao xong (chấm OTIF trên dòng này)


def fetch_scale(client, cfg):
    """Quy mô & độ phủ toàn bảng (sau SO_VALID) — 1 dòng tổng quan."""
    tms = cfg.table("tms_report_25")
    so_valid = cfg.scope["so_valid"]   # mảnh SQL → inline f-string
    sql = f"""
        SELECT count()                                       AS so_dong,
               uniqExact(OrderCode)                          AS so_don,
               uniqExactIf(MasterCode, MasterCode != '')     AS so_chuyen,
               countIf(MasterCode = '')                      AS dong_chua_len_chuyen,
               toString(min(toDate({DT('RequestDate')})))    AS tu_ngay,
               toString(max(toDate({DT('RequestDate')})))    AS den_ngay
        FROM {tms}
        WHERE {so_valid}
    """
    return da.run_df(client, sql, {}).iloc[0]


def fetch_daily(client, cfg, dfrom: str, dto: str):
    """KPI theo ngày (TenderedDate) trong window, áp scope ANALYSIS_FILTER.
    số đơn = uniqExact(OrderCode); số chuyến = uniqExactIf(MasterCode);
    OT% / IF% tính trên dòng 'Hoàn tất' với grace dung sai."""
    tms = cfg.table("tms_report_25")
    grace = cfg.scope["ontime_grace_min"]
    so_valid = cfg.scope["so_valid"]
    sql = f"""
        SELECT toDate({DT('TenderedDate')})                                       AS ngay,
               uniqExact(OrderCode)                                               AS so_don,
               uniqExactIf(MasterCode, MasterCode != '')                          AS so_chuyen,
               round(100 * countIf(DeliveryStatus = {{done:String}}) / count(), 1) AS pct_da_giao,
               round(100 * countIf({ontime('DateToCome', 'ETA', grace)} AND DeliveryStatus = {{done:String}})
                     / nullIf(countIf(DeliveryStatus = {{done:String}}
                              AND {DT('DateToCome')} IS NOT NULL AND {DT('ETA')} IS NOT NULL), 0), 1) AS pct_ontime,
               round(100 * countIf({NUM('QuantityBBGN')} >= {NUM('QuantityOrder')}
                              AND DeliveryStatus = {{done:String}} AND {NUM('QuantityOrder')} > 0)
                     / nullIf(countIf(DeliveryStatus = {{done:String}} AND {NUM('QuantityOrder')} > 0), 0), 1) AS pct_infull,
               round(100 * sum({NUM('QuantityBBGN')}) / nullIf(sum({NUM('QuantityOrder')}), 0), 1) AS fill_rate,
               round(sum({NUM('QuantityBBGN')}), 0)                               AS sl_giao
        FROM {tms}
        WHERE {so_valid}
          AND MasterStatus IN {{mstatus:Array(String)}} AND OrderStatus IN {{ostatus:Array(String)}}
          AND toDate({DT('TenderedDate')}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
        GROUP BY ngay ORDER BY ngay
    """
    return da.run_df(client, sql, {
        "done": DONE,
        "mstatus": cfg.scope["analysis_master_statuses"],
        "ostatus": cfg.scope["analysis_order_statuses"],
        "f": dfrom, "t": dto,
    })


def fetch_status_dist(client, cfg, col: str, dfrom: str, dto: str):
    """Phân bố một cột trạng thái trong window (theo TenderedDate, sau SO_VALID).
    col là ĐỊNH DANH → inline f-string (không bind value tiếng Việt vào identifier)."""
    tms = cfg.table("tms_report_25")
    so_valid = cfg.scope["so_valid"]
    sql = f"""
        SELECT if({col} = '', '(rỗng)', {col}) AS gia_tri,
               count()                          AS so_dong,
               uniqExact(OrderCode)             AS so_don
        FROM {tms}
        WHERE {so_valid}
          AND toDate({DT('TenderedDate')}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
        GROUP BY {col} ORDER BY so_dong DESC
    """
    df = da.run_df(client, sql, {"f": dfrom, "t": dto})
    if not df.empty:
        tong = df["so_dong"].sum()
        df["pct"] = (100 * df["so_dong"] / tong).round(1) if tong else 0
    return df.rename(columns={"gia_tri": col})


def fetch_integrity(client, cfg, dfrom: str, dto: str):
    """Check toàn vẹn cơ bản trong window (sau SO_VALID + ANALYSIS_FILTER):
    - đơn 'Hoàn tất' thiếu DateToCome/ETA → không chấm được On-time
    - đơn xuất hiện trên ≥ 2 chuyến (multi-trip)"""
    tms = cfg.table("tms_report_25")
    so_valid = cfg.scope["so_valid"]
    base = f"""
        FROM {tms}
        WHERE {so_valid}
          AND MasterStatus IN {{mstatus:Array(String)}} AND OrderStatus IN {{ostatus:Array(String)}}
          AND toDate({DT('TenderedDate')}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
    """
    params = {
        "done": DONE,
        "mstatus": cfg.scope["analysis_master_statuses"],
        "ostatus": cfg.scope["analysis_order_statuses"],
        "f": dfrom, "t": dto,
    }
    miss = da.run_df(client, f"""
        SELECT countIf(DeliveryStatus = {{done:String}})                            AS tong_hoan_tat,
               countIf(DeliveryStatus = {{done:String}}
                       AND ({DT('DateToCome')} IS NULL OR {DT('ETA')} IS NULL))      AS thieu_thoi_gian,
               round(100 * countIf(DeliveryStatus = {{done:String}}
                       AND ({DT('DateToCome')} IS NULL OR {DT('ETA')} IS NULL))
                     / nullIf(countIf(DeliveryStatus = {{done:String}}), 0), 1)      AS pct_thieu
        {base}
    """, params).iloc[0]
    multi = da.run_df(client, f"""
        SELECT uniqExact(OrderCode)            AS don_nhieu_chuyen,
               countIf(so_chuyen = 2)          AS don_2_chuyen,
               countIf(so_chuyen >= 3)         AS don_3_chuyen_tro_len
        FROM (
            SELECT OrderCode, uniqExact(MasterCode) AS so_chuyen
            {base} AND MasterCode != ''
            GROUP BY OrderCode HAVING so_chuyen >= 2
        )
    """, params).iloc[0]
    return miss, multi


def build(client, cfg, dfrom: str, dto: str) -> dict:
    """Dựng blocks + metadata audit TMS #25 (KHÔNG ghi file) — main() và run_all.py
    cùng tái dùng. Trả dict: blocks/title/stem/headline/fresh/status."""
    fresh = da.meta(client, cfg.table("tms_report_25"), DT("TenderedDate"))
    scale = fetch_scale(client, cfg)
    daily = fetch_daily(client, cfg, dfrom, dto)
    miss, multi = fetch_integrity(client, cfg, dfrom, dto)

    # KPI tổng window (đã giao trong window) — so-what cho heading
    don_window = int(daily["so_don"].sum()) if not daily.empty else 0
    n_ngay = len(daily)
    ot_avg = round(daily["pct_ontime"].mean(), 1) if not daily.empty else None
    if_avg = round(daily["pct_infull"].mean(), 1) if not daily.empty else None

    grace = cfg.scope["ontime_grace_min"]
    mstatus = ", ".join(cfg.scope["analysis_master_statuses"])
    ostatus = ", ".join(cfg.scope["analysis_order_statuses"])

    # Bảng KPI theo ngày — đổi tên cột sang tiếng Việt cho .md
    daily_show = daily.rename(columns={
        "ngay": "Ngày", "so_don": "Số đơn", "so_chuyen": "Số chuyến",
        "pct_da_giao": "% Đã giao", "pct_ontime": "% On-time",
        "pct_infull": "% In-full", "fill_rate": "Fill rate %", "sl_giao": "Số lượng giao",
    })

    blocks = [
        f"**Window** `{dfrom}` → `{dto}` · trục `Ngày gửi thầu` (`TenderedDate`) · "
        f"**{don_window:,} đơn / {n_ngay} ngày** · OT ~{ot_avg}% · IF ~{if_avg}% (avg theo ngày)",
        f"- Scope phân tích: MasterStatus ∈ ({mstatus}) · OrderStatus ∈ ({ostatus})",
        f"- Base filter SO_VALID: `{cfg.scope['so_valid']}` (loại đơn mã không chuẩn, khớp mv_otif)",
        f"- On-time = đến ≤ ETA + {grace}′ · In-full = giao ≥ KH · % tính trên dòng `{DONE}`",
        f"- Freshness (TenderedDate): max_date `{fresh.get('max_date')}`, trễ ~{fresh.get('lag_min')}′",

        "## 1 · Quy mô & độ phủ toàn bảng (sau SO_VALID)",
        f"- Tổng dòng (order × trip): **{int(scale['so_dong']):,}** · "
        f"số đơn: **{int(scale['so_don']):,}** · số chuyến: **{int(scale['so_chuyen']):,}**",
        f"- Dòng chưa lên chuyến (MasterCode rỗng): **{int(scale['dong_chua_len_chuyen']):,}**",
        f"- Khoảng ngày nguồn (RequestDate): `{scale['tu_ngay']}` → `{scale['den_ngay']}`",

        f"## 2 · KPI theo ngày trong window ({n_ngay} ngày)",
        "> Số đơn = `uniqExact(OrderCode)` · số chuyến = `uniqExactIf(MasterCode)`. "
        "Tổng đơn cộng theo ngày KHÔNG loại trùng liên ngày (1 đơn nhiều ngày tender hiếm).",
        daily_show,

        "## 3 · Phân bố trạng thái trong window",
        "**Trạng thái chuyến (MasterStatus)** — lưu ý: bảng này đã lọc theo scope MasterStatus, "
        "nên chỉ thấy các trạng thái trong scope.",
        fetch_status_dist(client, cfg, "MasterStatus", dfrom, dto),
        "**Trạng thái đơn (OrderStatus)**",
        fetch_status_dist(client, cfg, "OrderStatus", dfrom, dto),
        "**Trạng thái giao (DeliveryStatus)**",
        fetch_status_dist(client, cfg, "DeliveryStatus", dfrom, dto),

        "## 4 · Check toàn vẹn cơ bản (trong window, sau scope)",
        f"- Đơn `{DONE}` thiếu DateToCome/ETA (không chấm được On-time): "
        f"**{int(miss['thieu_thoi_gian']):,}** / {int(miss['tong_hoan_tat']):,} "
        f"(**{miss['pct_thieu']}%**) → bị loại khỏi mẫu số On-time",
        f"- Đơn trên nhiều chuyến (≥ 2 MasterCode): **{int(multi['don_nhieu_chuyen']):,}** "
        f"(2 chuyến: {int(multi['don_2_chuyen']):,} · ≥3 chuyến: {int(multi['don_3_chuyen_tro_len']):,})",

        "## Để lại cho notebook explore (tra cứu tương tác)",
        "Các phần dưới đây phụ thuộc tham số tự chọn / cần render nhiều bảng dài → giữ ở "
        "`mondelez/notebooks/tms_report_25_explore.ipynb`, KHÔNG port sang script:",
        "- Tra 1 đơn theo `OrderCode` (chi tiết từng chuyến, giao nhận KH vs thực).",
        "- Tra 1 chuyến theo `MasterCode` (danh sách đơn trong chuyến).",
        "- Summary 1 ngày tự chọn (`DAY`) + top nhà xe / kho / chi tiết từng đơn trong ngày.",
        "- Danh sách fail OTIF (L3.4.1/2/3: KHÔNG On-time / KHÔNG In-full / Fail cả 2).",
        "- Breakdown nhà xe / kho / tỉnh / loại xe + biểu đồ xu hướng, % On-time theo tuần.",
        "- Đối chiếu chéo với `mv_otif` (confusion matrix, set diff) → xem "
        "`mondelez/scripts/analysis/reconcile_tms_otif.py`.",
    ]

    return {
        "blocks": blocks,
        "title": f"Audit TMS report #25 — {cfg.name}",
        "stem": f"tms-report-25-audit-{dto.replace('-', '')}",
        "headline": (f"{n_ngay} ngày · {don_window:,} đơn (window) · "
                     f"OT avg {ot_avg}% · IF avg {if_avg}% · "
                     f"toàn bảng {int(scale['so_don']):,} đơn / {int(scale['so_chuyen']):,} chuyến"),
        "fresh": fresh,
        "status": "🟢",  # audit TMS raw: không có ngưỡng pass/fail cứng → thông tin
    }


def main() -> None:
    args = build_parser("Audit lặp-lại-được TMS report #25 theo window → .md + .html").parse_args()
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
