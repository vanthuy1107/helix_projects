"""
otif_mtd_audit.py
─────────────────
Audit OTIF MTD trên `mv_otif` → xuất 1 file .md (tách code khỏi kết quả).
Port các SECTION lặp-lại-được từ notebook `mondelez/notebooks/otif_mtd_audit.ipynb`
(bỏ qua các cell tra-cứu-1-đơn tương tác — để lại cho notebook explore).

Chiến lược:
  - Mỗi section = 1 hàm fetch_* thuần trả DataFrame; gom vào list blocks rồi save_md.
  - Bind mọi chuỗi tiếng Việt là VALUE so sánh qua param {x:String} — KHÔNG inline
    (clickhouse-connect corrupt UTF-8 nếu inline). 'OTIF'/'Ontime'/'Infull' là ASCII → inline OK.
    'Không có dữ liệu STM' BẮT BUỘC bind {nostm:String}.
  - ĐỊNH DANH (tên bảng/cột) + mảnh SQL (window filter, where_so) → nội suy f-string.
  - Window mặc định MTD (resolve lo sẵn). Filter chỉ window ngày + (optional) SO.

KPI canonical (đúng công thức notebook): loại 'Không có dữ liệu STM' ở mẫu số % metric.

Cách chạy (từ thư mục gốc helix-projects/):
    python mondelez/scripts/otif_mtd_audit.py
    python mondelez/scripts/otif_mtd_audit.py --from 2026-05-01 --to 2026-05-28
    python mondelez/scripts/otif_mtd_audit.py --so 8482509466 --so 8482509467

Env (mondelez/.env): CLICKHOUSE_*.  Config nghiệp vụ: mondelez/da.toml.
"""
from __future__ import annotations

from pathlib import Path

import da
from da.cli import build_parser, resolve


# ── helper: mảnh WHERE chung (window theo date_col + optional SO) ─────────────
def _where(date_col: str, so_filter: list[str]) -> str:
    """Mảnh WHERE: window ngày (bind {f}/{t}) + optional so IN(...).

    so_filter là identifier-level value list cho cột `so`; ta inline ở đây sau khi
    escape '' để không phải tăng số lượng param động. (Giá trị SO là mã số ASCII.)"""
    w = f"toDate({date_col}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})"
    if so_filter:
        vals = ",".join("'" + s.replace("'", "''") + "'" for s in so_filter)
        w += f" AND so IN ({vals})"
    return w


# ── SECTION 1 · Summary sức khỏe (scale + distinct theo dim trong window) ─────
def fetch_scale(client, cfg, dfrom, dto, so_filter, date_col):
    """SO-WHAT: nhịp dữ liệu trong window — row, distinct SO, fan-out theo dim.
    rows_minus_so > 0 = có SO split sang nhiều kho; rows_khong_co_stm = loại khỏi % KPI."""
    T = cfg.table("mv_otif")
    sql = f"""
        SELECT count()                                       AS rows_window,
               uniqExact(so)                                 AS distinct_so,
               count() - uniqExact(so)                       AS rows_minus_so,
               uniqExact(so, whseid)                         AS distinct_so_whseid,
               uniqExact(whseid)                             AS distinct_whseid,
               uniqExact(coalesce(customer_code,''))         AS distinct_customer,
               uniqExact(coalesce(group_of_cago,''))         AS distinct_cargo,
               uniqExact(coalesce(group_name,''))            AS distinct_kenh,
               uniqExact(coalesce(khu_vuc_doi_xe,''))        AS distinct_khu_vuc,
               uniqExact(coalesce(ten_ngan_nha_van_tai,''))  AS distinct_nvt,
               countIf(otif_status = {{nostm:String}})       AS rows_khong_co_stm,
               countIf(otif_status != {{nostm:String}})      AS rows_co_stm
        FROM {T}
        WHERE {_where(date_col, so_filter)}
    """
    df = da.run_df(client, sql, {"nostm": "Không có dữ liệu STM", "f": dfrom, "t": dto})
    return df.T.reset_index().rename(columns={"index": "metric", 0: "value"})


# ── SECTION 2 · KPI canonical OTIF / Ontime / Infull ─────────────────────────
def fetch_kpi(client, cfg, dfrom, dto, so_filter, date_col):
    """SO-WHAT: KPI canonical — đã loại 'Không có dữ liệu STM' ở mẫu số % metric
    (đúng định nghĩa dashboard). Target PRD §13.2: OTIF 90 / Ontime 95 / Infull 97."""
    T = cfg.table("mv_otif")
    sql = f"""
        WITH filtered AS (
          SELECT * FROM {T}
          WHERE {_where(date_col, so_filter)}
            AND otif_status != {{nostm:String}}        -- exclusion canonical cho % metric
        )
        SELECT
          uniqExact(so)                                                       AS total_so,
          countIf(ontime_status = 'Ontime')                                   AS ontime_so,
          round(100.0*countIf(ontime_status='Ontime')/nullIf(count(so),0),2)  AS pct_ontime,
          countIf(infull_status = 'Infull')                                   AS infull_so,
          round(100.0*countIf(infull_status='Infull')/nullIf(count(so),0),2)  AS pct_infull,
          countIf(otif_status = 'OTIF')                                       AS otif_so,
          round(100.0*countIf(otif_status='OTIF')/nullIf(count(so),0),2)      AS pct_otif
        FROM filtered
    """
    return da.run_df(client, sql, {"nostm": "Không có dữ liệu STM", "f": dfrom, "t": dto})


def kpi_table_md(k) -> str:
    """Render KPI 1 dòng thành bảng markdown có cờ RAG (band PRD §13.2)."""
    def rag(v, green, yellow_lo):
        if v is None:
            return "—"
        v = float(v)
        return "🟢" if v >= green else ("🟡" if v >= yellow_lo else "🔴")

    return (
        "| KPI | Số đơn | % | Target | RAG |\n|---|---:|---:|---:|:--:|\n"
        f"| **% OTIF**   | {int(k['otif_so']):,}   | **{k['pct_otif']:.2f}%**   | 90% | {rag(k['pct_otif'],90,85)} |\n"
        f"| **% Ontime** | {int(k['ontime_so']):,} | **{k['pct_ontime']:.2f}%** | 95% | {rag(k['pct_ontime'],95,90)} |\n"
        f"| **% Infull** | {int(k['infull_so']):,} | **{k['pct_infull']:.2f}%** | 97% | {rag(k['pct_infull'],97,92)} |\n\n"
        f"Tổng đơn (uniqExact SO, đã loại STM-missing): **{int(k['total_so']):,}**"
    )


# ── SECTION 3 · Phân bố theo dim nghiệp vụ ───────────────────────────────────
def fetch_dim(client, cfg, dfrom, dto, so_filter, date_col, col):
    """SO-WHAT: phân bố theo 1 dim nghiệp vụ + %OTIF nhóm (đã loại STM ở mẫu số).
    bucket (NULL)/(rỗng) cao = red flag master data."""
    T = cfg.table("mv_otif")
    sql = f"""
        SELECT
          multiIf({col} IS NULL, '(NULL)', {col}='', '(rỗng)', {col}) AS bucket,
          count()                                       AS rows,
          round(100.0*count()/sum(count()) OVER (),2)   AS pct,
          countIf(otif_status='OTIF')                   AS otif_so,
          round(100.0*countIf(otif_status='OTIF')
                /nullIf(countIf(otif_status != {{nostm:String}}),0),2) AS pct_otif
        FROM {T}
        WHERE {_where(date_col, so_filter)}
        GROUP BY bucket ORDER BY rows DESC
    """
    return da.run_df(client, sql, {"nostm": "Không có dữ liệu STM", "f": dfrom, "t": dto})


# ── SECTION 4 · Volume tổng (plan / shipped / delivered × CSE/KG/CBM) ─────────
def fetch_volume(client, cfg, dfrom, dto, so_filter, date_col):
    """SO-WHAT: tổng volume — kỳ vọng monotonic Plan ≥ Shipped ≥ Delivered mỗi UOM.
    Loại STM-missing (khớp KPI denom)."""
    T = cfg.table("mv_otif")
    sql = f"""
        SELECT
          round(sum(toFloat64(coalesce(sum_original_cse,0))),2)        AS plan_cse,
          round(sum(toFloat64(coalesce(sum_shipped_cse,0))),2)         AS shipped_cse,
          round(sum(toFloat64(coalesce(sum_san_luong_giao_cse,0))),2)  AS delivered_cse,
          round(sum(toFloat64(coalesce(sum_original_kg,0))),2)         AS plan_kg,
          round(sum(toFloat64(coalesce(sum_shipped_kg,0))),2)          AS shipped_kg,
          round(sum(toFloat64(coalesce(sum_san_luong_giao_kg,0))),2)   AS delivered_kg,
          round(sum(toFloat64(coalesce(sum_original_cbm,0))),3)        AS plan_cbm,
          round(sum(toFloat64(coalesce(sum_shipped_cbm,0))),3)         AS shipped_cbm,
          round(sum(toFloat64(coalesce(sum_san_luong_giao_cbm,0))),3)  AS delivered_cbm
        FROM {T}
        WHERE {_where(date_col, so_filter)}
          AND otif_status != {{nostm:String}}
    """
    df = da.run_df(client, sql, {"nostm": "Không có dữ liệu STM", "f": dfrom, "t": dto})
    return df.T.reset_index().rename(columns={"index": "metric", 0: "value"})


# ── SECTION 5 · Trend theo ngày (default_date_col) ───────────────────────────
def fetch_trend(client, cfg, dfrom, dto, so_filter, date_col):
    """SO-WHAT: trend daily — total_so=count(so) cắt ngày UTC (khớp widget trend).
    dup>0 = SO lặp trong ngày; rows_nostm = đơn chưa có STM trong ngày."""
    T = cfg.table("mv_otif")
    sql = f"""
        SELECT
          toDate({date_col})                                                 AS ngay,
          count(so)                                                          AS total_so,
          uniqExact(so)                                                      AS so_unique,
          count(so) - uniqExact(so)                                          AS dup,
          countIf(otif_status = {{nostm:String}})                            AS rows_nostm,
          countIf(otif_status='OTIF')                                        AS otif_so,
          round(100.0*countIf(otif_status='OTIF')/nullIf(count(so),0),2)     AS pct_otif,
          round(100.0*countIf(ontime_status='Ontime')/nullIf(count(so),0),2) AS pct_ontime,
          round(100.0*countIf(infull_status='Infull')/nullIf(count(so),0),2) AS pct_infull,
          round(sum(toFloat64(coalesce(sum_original_cse,0))),2)              AS plan_cse
        FROM {T}
        WHERE {_where(date_col, so_filter)}
        GROUP BY ngay ORDER BY ngay
    """
    return da.run_df(client, sql, {"nostm": "Không có dữ liệu STM", "f": dfrom, "t": dto})


# ── SECTION 6 · 5 nhóm anomaly ───────────────────────────────────────────────
def fetch_anomaly_nulls(client, cfg, dfrom, dto, so_filter, date_col):
    """A · NULL / empty các cột then chốt. so_null/whseid_empty kỳ vọng = 0."""
    T = cfg.table("mv_otif")
    sql = f"""
        SELECT
          count()                                              AS rows_window,
          countIf(so IS NULL OR so='')                         AS so_null,
          countIf(whseid='')                                   AS whseid_empty,
          countIf(otif_status='')                              AS otif_status_empty,
          countIf(ontime_status IS NULL)                       AS ontime_status_null,
          countIf(infull_status IS NULL)                       AS infull_status_null,
          countIf(thoi_gian_gui_thau IS NULL)                  AS thoi_gian_gui_thau_null,
          countIf(eta_giao_hang_cho_npp IS NULL)               AS eta_null,
          countIf(ata_den IS NULL)                             AS ata_den_null,
          countIf(customer_code IS NULL OR customer_code='')   AS customer_code_null,
          countIf(group_of_cago IS NULL OR group_of_cago='')   AS cargo_null,
          countIf(toFloat64(coalesce(sum_original_cse,0))=0)   AS original_cse_zero
        FROM {T}
        WHERE {_where(date_col, so_filter)}
    """
    df = da.run_df(client, sql, {"f": dfrom, "t": dto})
    return df.T.reset_index().rename(columns={"index": "check", 0: "count"})


def fetch_anomaly_volume(client, cfg, dfrom, dto, so_filter, date_col):
    """B · Volume integrity — neg / over-ship / over-deliver. neg & overdeliver kỳ vọng = 0."""
    T = cfg.table("mv_otif")
    sql = f"""
        SELECT
          count()                                              AS rows_window,
          countIf(toFloat64(coalesce(sum_original_cse,0)) < 0) AS neg_plan_cse,
          countIf(toFloat64(coalesce(sum_shipped_cse,0)) < 0)  AS neg_shipped_cse,
          countIf(toFloat64(coalesce(sum_san_luong_giao_cse,0)) < 0) AS neg_delivered_cse,
          countIf(round(toFloat64(sum_shipped_cse),4) > round(toFloat64(sum_original_cse),4)
                  AND toFloat64(sum_original_cse) > 0)         AS overship_cse,
          countIf(round(toFloat64(sum_san_luong_giao_cse),4) > round(toFloat64(sum_shipped_cse),4)
                  AND toFloat64(sum_shipped_cse) > 0)          AS overdeliver_cse,
          countIf(toFloat64(coalesce(sum_original_cse,0))>0
                  AND toFloat64(coalesce(sum_original,0))=0)   AS cse_pos_qty_zero
        FROM {T}
        WHERE {_where(date_col, so_filter)}
    """
    df = da.run_df(client, sql, {"f": dfrom, "t": dto})
    return df.T.reset_index().rename(columns={"index": "check", 0: "count"})


def fetch_anomaly_business(client, cfg, dfrom, dto, so_filter, date_col):
    """C · Business-rule cross-field. otif_but_not_ontime/infull kỳ vọng = 0."""
    T = cfg.table("mv_otif")
    sql = f"""
        SELECT
          count()                                              AS rows_window,
          countIf(ontime_status='Failed Ontime' AND (not_ontime_reason IS NULL OR not_ontime_reason=''))
                                                               AS failontime_no_reason,
          countIf(infull_status='Failed Infull' AND (not_infull_reason IS NULL OR not_infull_reason=''))
                                                               AS failinfull_no_reason,
          countIf(ontime_status='Ontime' AND ata_den IS NULL)  AS ontime_but_ata_null,
          countIf(otif_status='OTIF' AND ontime_status!='Ontime') AS otif_but_not_ontime,
          countIf(otif_status='OTIF' AND infull_status!='Infull') AS otif_but_not_infull,
          countIf(otif_status={{nostm:String}} AND ata_den IS NOT NULL) AS nostm_but_has_ata,
          countIf(ontime_status='Ontime' AND infull_status='Infull' AND otif_status='Failed OTIF')
                                                               AS grace_gap,
          countIf(toDate(thoi_gian_gui_thau) > today())        AS tender_future,
          countIf(thoi_gian_gui_thau < toDateTime64('2020-01-01 00:00:00',3,'UTC')) AS tender_too_old
        FROM {T}
        WHERE {_where(date_col, so_filter)}
    """
    df = da.run_df(client, sql, {"nostm": "Không có dữ liệu STM", "f": dfrom, "t": dto})
    return df.T.reset_index().rename(columns={"index": "check", 0: "count"})


def fetch_anomaly_dup(client, cfg, dfrom, dto, so_filter, date_col):
    """D · Duplicate (so, whseid). dup kỳ vọng = 0; multi = SO trải > 1 kho (info)."""
    T = cfg.table("mv_otif")
    dup = int(da.run_df(client, f"""
        SELECT count() AS c FROM (
          SELECT so, whseid, count() AS c FROM {T}
          WHERE {_where(date_col, so_filter)}
          GROUP BY so, whseid HAVING count() > 1)
    """, {"f": dfrom, "t": dto})["c"].iloc[0])
    multi = int(da.run_df(client, f"""
        SELECT count() AS c FROM (
          SELECT so, uniqExact(whseid) AS w FROM {T}
          WHERE {_where(date_col, so_filter)}
          GROUP BY so HAVING w > 1)
    """, {"f": dfrom, "t": dto})["c"].iloc[0])
    import pandas as pd
    return pd.DataFrame(
        [("Duplicate (so, whseid)", dup, "= 0"), ("SO trải > 1 whseid", multi, "info")],
        columns=["check", "count", "rule"],
    )


def fetch_anomaly_timestamp(client, cfg, dfrom, dto, so_filter, date_col):
    """E · Timestamp ordering — các cặp mốc nghịch thứ tự. Mọi đếm kỳ vọng = 0."""
    T = cfg.table("mv_otif")
    sql = f"""
        SELECT
          count() AS rows_window,
          countIf(thoi_gian_gui_thau IS NOT NULL AND etd_chuyen_gui_thau IS NOT NULL
                  AND thoi_gian_gui_thau > etd_chuyen_gui_thau)        AS tender_after_etd,
          countIf(etd_chuyen_gui_thau IS NOT NULL AND eta_giao_hang_cho_npp IS NOT NULL
                  AND etd_chuyen_gui_thau > eta_giao_hang_cho_npp)     AS etd_after_eta,
          countIf(gio_vao_cong IS NOT NULL AND gio_ra_cong IS NOT NULL
                  AND gio_vao_cong > gio_ra_cong)                      AS incong_after_outcong,
          countIf(gio_vao_dock IS NOT NULL AND gio_ra_dock IS NOT NULL
                  AND gio_vao_dock > gio_ra_dock)                      AS indock_after_outdock,
          countIf(ata_den IS NOT NULL AND ata_roi IS NOT NULL
                  AND ata_den > ata_roi)                               AS atadel_after_ataleave,
          countIf(actual_ship_date IS NOT NULL AND ata_den IS NOT NULL
                  AND actual_ship_date > ata_den)                      AS ship_after_arrival,
          countIf(gio_ra_cong IS NOT NULL AND ata_den IS NOT NULL
                  AND gio_ra_cong > ata_den)                           AS leavegate_after_arrival,
          countIf(ngay_tao_don IS NOT NULL AND ngay_gi IS NOT NULL
                  AND ngay_tao_don > ngay_gi)                          AS create_after_gi
        FROM {T}
        WHERE {_where(date_col, so_filter)}
    """
    df = da.run_df(client, sql, {"f": dfrom, "t": dto})
    return df.T.reset_index().rename(columns={"index": "check", 0: "count"})


def main() -> None:
    p = build_parser("Audit OTIF MTD trên mv_otif → .md (port từ notebook otif_mtd_audit)")
    p.add_argument("--so", dest="so", action="append", default=[],
                   help="Lọc theo mã SO (lặp lại để truyền nhiều). Mặc định: tất cả đơn.")
    args = p.parse_args()
    if not args.tenant:
        args.tenant = Path(__file__).resolve().parent.parent   # script sống trong mondelez/
    cfg, (dfrom, dto) = resolve(args)
    client = da.ch_client(cfg)

    date_col = cfg.scope["default_date_col"]
    so_filter = args.so
    T = cfg.table("mv_otif")

    fresh = da.meta(client, T, date_col)
    kpi = fetch_kpi(client, cfg, dfrom, dto, so_filter, date_col)
    k = kpi.iloc[0]

    dim_specs = [
        ("whseid",               "Kho (whseid)"),
        ("khu_vuc_doi_xe",       "Khu vực đội xe"),
        ("group_name",           "Kênh bán hàng"),
        ("ten_ngan_nha_van_tai", "Nhà vận tải"),
        ("group_of_cago",        "Loại hàng (Group of Cargo)"),
        ("loai_xe_gui_thau",     "Loại xe gửi thầu"),
    ]

    blocks = [
        f"**Window** `{dfrom}` → `{dto}` (inclusive) · trục `{date_col}` (Ngày gửi thầu)"
        f" · SO filter: `{so_filter if so_filter else 'ALL'}`",
        f"- Freshness `{date_col}`: max_date `{fresh.get('max_date')}`, min_date "
        f"`{fresh.get('min_date')}`, lag ~{fresh.get('lag_min')}′ vs now (MV refresh 5′ → lag lớn = chưa cập nhật).",

        "## 1 · Summary sức khỏe — scale + distinct theo dim (trong window)",
        "_rows_minus_so > 0 = SO split sang nhiều kho · rows_khong_co_stm = loại khỏi mẫu số % KPI._",
        fetch_scale(client, cfg, dfrom, dto, so_filter, date_col),

        "## 2 · KPI canonical OTIF / Ontime / Infull (đã loại 'Không có dữ liệu STM' ở mẫu số)",
        kpi_table_md(k),
    ]

    blocks.append("## 3 · Phân bố theo dim nghiệp vụ (pct_otif = %OTIF nhóm, loại STM ở mẫu số)")
    for col, label in dim_specs:
        blocks.append(f"**{label}** (`{col}`)")
        blocks.append(fetch_dim(client, cfg, dfrom, dto, so_filter, date_col, col))

    blocks += [
        "## 4 · Volume tổng (kỳ vọng monotonic Plan ≥ Shipped ≥ Delivered mỗi UOM)",
        fetch_volume(client, cfg, dfrom, dto, so_filter, date_col),

        f"## 5 · Trend theo ngày (`{date_col}`)",
        "_total_so = count(so) cắt ngày UTC (khớp widget trend) · dup > 0 = SO lặp trong ngày._",
        fetch_trend(client, cfg, dfrom, dto, so_filter, date_col),

        "## 6 · Anomaly — 5 nhóm (đếm kỳ vọng = 0 trừ các mục info)",
        "**6A · NULL / empty cột then chốt** (so_null, whseid_empty kỳ vọng = 0)",
        fetch_anomaly_nulls(client, cfg, dfrom, dto, so_filter, date_col),
        "**6B · Volume integrity** (neg_*, overdeliver kỳ vọng = 0 · overship → Failed Infull, info)",
        fetch_anomaly_volume(client, cfg, dfrom, dto, so_filter, date_col),
        "**6C · Business-rule cross-field** (otif_but_not_ontime/infull kỳ vọng = 0)",
        fetch_anomaly_business(client, cfg, dfrom, dto, so_filter, date_col),
        "**6D · Duplicate (so, whseid)** (dup kỳ vọng = 0 · multi = SO trải > 1 kho, info)",
        fetch_anomaly_dup(client, cfg, dfrom, dto, so_filter, date_col),
        "**6E · Timestamp ordering** (mọi cặp mốc nghịch thứ tự kỳ vọng = 0)",
        fetch_anomaly_timestamp(client, cfg, dfrom, dto, so_filter, date_col),
    ]

    out = cfg.root / "reports" / f"otif-mtd-audit-{dto.replace('-', '')}.md"
    path = da.save_md(blocks, out, title=f"Audit OTIF MTD — mv_otif — {cfg.name}")

    print(f"[OK] {path}")
    print(f"[INFO] %OTIF={k['pct_otif']:.2f} · %Ontime={k['pct_ontime']:.2f} · "
          f"%Infull={k['pct_infull']:.2f} · total_so={int(k['total_so']):,}")


if __name__ == "__main__":
    main()
