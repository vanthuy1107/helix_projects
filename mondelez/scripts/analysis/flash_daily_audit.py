"""
flash_daily_audit.py
────────────────────
Audit chất lượng dữ liệu MTD cho báo cáo Flash Daily (`mv_flash_and_drop_report`)
→ xuất 1 file .md (tách code khỏi kết quả). Port từ notebook
`mondelez/notebooks/flash_daily_mtd_audit.ipynb`, bỏ các slot drill ad-hoc tương tác.

Chiến lược (theo MẪU reconcile_tms_otif.py):
  - Mọi chuỗi tiếng Việt là VALUE → bind qua param {x:String} (chống corrupt UTF-8).
  - ĐỊNH DANH (tên bảng/cột) + mảnh SQL → nội suy f-string ở call site.
  - Window mặc định MTD (resolve lo sẵn); filter CHỈ theo window ngày trên date_col.
  - MV không tồn tại / thiếu cột → ghi rõ vào .md thay vì để script chết.

Section (đọc được lặp lại):
  1. Summary  — row/distinct/freshness trong window (+ da.meta)
  2. Phân bố  — e2e_label + các dim (status/type/whseid/brand/group_name/khu_vuc_doi_xe)
  3. Volume   — tổng Plan/Shipped/Delivered × CSE/KG/CBM/PL + daily
  4. Anomaly  — 5 nhóm: NULL · volume integrity · business rule ·
                key/cross-MV parity (flash+drop vs flash_and_drop) · timestamp ordering

Cách chạy (từ thư mục gốc helix-projects/):
    python mondelez/scripts/analysis/flash_daily_audit.py
    python mondelez/scripts/analysis/flash_daily_audit.py --from 2026-05-01 --to 2026-05-28

Env (mondelez/.env): CLICKHOUSE_*.  Config nghiệp vụ: mondelez/da.toml.
"""
from __future__ import annotations

from pathlib import Path

import pandas as pd

import da
from da.cli import build_parser, resolve

# Cột ngày + cột volume mặc định (cell L0 notebook). delivery_date_1 = "Ngày GI".
DATE_COL = "delivery_date_1"
DATE_LABEL = "Ngày GI"
UOM_COL = "original_cse"
TZ = "Asia/Ho_Chi_Minh"


# ─── 1 · Summary ──────────────────────────────────────────────────────────────
def fetch_rowcount(client, cfg):
    """A · Tổng row mỗi MV gốc (không lọc window). MV lỗi → ghi (lỗi) thay vì chết."""
    rows = []
    for logical, name in [("mv_flash", "mv_flash_and_drop_report"),
                          ("mv_flash_only", "mv_flash_report"),
                          ("mv_drop", "mv_dropped_report")]:
        tbl = cfg.table(logical)
        try:
            n = int(da.run_df(client, f"SELECT count() AS rows FROM {tbl}")["rows"].iloc[0])
            rows.append({"source_mv": name, "rows": n})
        except Exception as exc:  # noqa: BLE001 — MV thiếu → ghi nhận, không dừng
            rows.append({"source_mv": name, "rows": f"(lỗi: {str(exc).splitlines()[0][:80]})"})
    return pd.DataFrame(rows)


def fetch_distinct(client, cfg, dfrom, dto):
    """B · Distinct count các dim trong window MTD trên MV chính."""
    t = cfg.table("mv_flash")
    sql = f"""
        SELECT count()                            AS rows_mtd,
               uniq(so)                           AS distinct_so,
               uniq(coalesce(whseid, ''))         AS distinct_whseid,
               uniq(coalesce(customer_code, ''))  AS distinct_customer,
               uniq(coalesce(brand, ''))          AS distinct_brand,
               uniq(coalesce(group_of_cago, ''))  AS distinct_cargo_group,
               uniq(coalesce(group_name, ''))     AS distinct_kenh,
               uniq(coalesce(khu_vuc_doi_xe, '')) AS distinct_khu_vuc,
               uniq(coalesce(e2e_label, ''))      AS distinct_e2e_label,
               uniq(coalesce(status, ''))         AS distinct_status,
               uniq(coalesce(type, ''))           AS distinct_order_type
        FROM {t}
        WHERE toDate({DATE_COL}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
    """
    df = da.run_df(client, sql, {"f": dfrom, "t": dto})
    return df.T.reset_index().rename(columns={"index": "metric", 0: "value"})


def fetch_freshness(client, cfg):
    """C · Freshness — max timestamp các cột thời gian + lag vs now() (UTC+7)."""
    t = cfg.table("mv_flash")
    sql = f"""
        SELECT toDateTime(max({DATE_COL}),       '{TZ}') AS max_date_col,
               toDateTime(min({DATE_COL}),       '{TZ}') AS min_date_col,
               toDateTime(max(ngay_tao_don),     '{TZ}') AS max_ngay_tao_don,
               toDateTime(max(actual_ship_date), '{TZ}') AS max_actual_ship,
               toDateTime(max(ata_den),          '{TZ}') AS max_ata_den,
               now('{TZ}')                                AS server_now,
               dateDiff('minute', max(ngay_tao_don), now())     AS lag_min_ngay_tao_don,
               dateDiff('minute', max(actual_ship_date), now()) AS lag_min_actual_ship
        FROM {t}
    """
    df = da.run_df(client, sql)
    return df.T.reset_index().rename(columns={"index": "metric", 0: "value"})


# ─── 2 · Phân bố ──────────────────────────────────────────────────────────────
def fetch_e2e_dist(client, cfg, dfrom, dto):
    """A · Phân bố theo e2e_label (volume theo UOM_COL)."""
    t = cfg.table("mv_flash")
    sql = f"""
        SELECT coalesce(nullIf(e2e_label, ''), '(NULL)')        AS e2e_label,
               count()                                          AS rows,
               round(count() * 100.0 / sum(count()) OVER (), 2) AS pct_rows,
               round(sum({UOM_COL}), 2)                         AS volume_uom
        FROM {t}
        WHERE toDate({DATE_COL}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
        GROUP BY e2e_label
        ORDER BY rows DESC
    """
    return da.run_df(client, sql, {"f": dfrom, "t": dto})


def fetch_dim_dist(client, cfg, dfrom, dto, dim):
    """B · Phân bố theo 1 dim (top 30). dim là ĐỊNH DANH → f-string."""
    t = cfg.table("mv_flash")
    sql = f"""
        SELECT coalesce(nullIf({dim}, ''), '(NULL)') AS value,
               count()                               AS rows,
               round(sum({UOM_COL}), 2)              AS volume_uom
        FROM {t}
        WHERE toDate({DATE_COL}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
        GROUP BY value
        ORDER BY rows DESC
        LIMIT 30
    """
    return da.run_df(client, sql, {"f": dfrom, "t": dto})


# ─── 3 · Volume ───────────────────────────────────────────────────────────────
def fetch_volume_total(client, cfg, dfrom, dto):
    """Tổng volume MTD theo Plan/Shipped/Delivered × CSE/KG/CBM/PL."""
    t = cfg.table("mv_flash")
    sql = f"""
        SELECT round(sum(original_cse), 2)       AS plan_cse,
               round(sum(shipped_cse), 2)        AS shipped_cse,
               round(sum(san_luong_giao_cse), 2) AS delivered_cse,
               round(sum(original_kg), 2)        AS plan_kg,
               round(sum(shipped_kg), 2)         AS shipped_kg,
               round(sum(san_luong_giao_kg), 2)  AS delivered_kg,
               round(sum(original_cbm), 2)       AS plan_cbm,
               round(sum(shipped_cbm), 2)        AS shipped_cbm,
               round(sum(san_luong_giao_cbm), 2) AS delivered_cbm,
               round(sum(original_pl), 2)        AS plan_pl,
               round(sum(shipped_pl), 2)         AS shipped_pl,
               round(sum(san_luong_giao_pl), 2)  AS delivered_pl
        FROM {t}
        WHERE toDate({DATE_COL}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
    """
    df = da.run_df(client, sql, {"f": dfrom, "t": dto})
    return df.T.reset_index().rename(columns={"index": "metric", 0: "value"})


def fetch_volume_daily(client, cfg, dfrom, dto):
    """Daily volume trong window — quan sát ngày sụt/tăng đột biến."""
    t = cfg.table("mv_flash")
    sql = f"""
        SELECT toDate({DATE_COL})                AS day,
               count()                           AS rows,
               round(sum(original_cse), 2)       AS plan_cse,
               round(sum(shipped_cse), 2)        AS shipped_cse,
               round(sum(san_luong_giao_cse), 2) AS delivered_cse,
               round(if(sum(original_cse) > 0,
                     sum(san_luong_giao_cse) / sum(original_cse) * 100, 0), 2) AS pct_done
        FROM {t}
        WHERE toDate({DATE_COL}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
        GROUP BY day
        ORDER BY day
    """
    return da.run_df(client, sql, {"f": dfrom, "t": dto})


# ─── 4 · Anomaly ──────────────────────────────────────────────────────────────
def fetch_nulls(client, cfg, dfrom, dto):
    """Nhóm 1 — NULL/empty trên cột critical (kỳ vọng nhỏ; pct so với window)."""
    t = cfg.table("mv_flash")
    sql = f"""
        SELECT countIf(so IS NULL OR so = '')                       AS so_null_or_empty,
               countIf(whseid IS NULL OR whseid = '')               AS whseid_null_or_empty,
               countIf(customer_code IS NULL OR customer_code = '')  AS customer_code_null_or_empty,
               countIf(customer_name IS NULL OR customer_name = '')  AS customer_name_null_or_empty,
               countIf(brand IS NULL OR brand = '')                 AS brand_null_or_empty,
               countIf(group_of_cago IS NULL OR group_of_cago = '') AS cargo_group_null_or_empty,
               countIf(group_name IS NULL OR group_name = '')       AS kenh_null_or_empty,
               countIf(khu_vuc_doi_xe IS NULL OR khu_vuc_doi_xe = '') AS khu_vuc_null_or_empty,
               countIf(delivery_date_1 IS NULL)                     AS delivery_date_null,
               countIf(ngay_tao_don IS NULL)                        AS ngay_tao_don_null,
               countIf(original_cse IS NULL OR original_cse = 0)    AS original_cse_zero_or_null,
               countIf(e2e_label IS NULL OR e2e_label = '')         AS e2e_label_null_or_empty,
               countIf(status IS NULL OR status = '')               AS status_null_or_empty,
               countIf(type IS NULL OR type = '')                   AS order_type_null_or_empty,
               count()                                              AS total_rows_in_window
        FROM {t}
        WHERE toDate({DATE_COL}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
    """
    df = da.run_df(client, sql, {"f": dfrom, "t": dto})
    total = int(df["total_rows_in_window"].iloc[0])
    out = df.drop(columns=["total_rows_in_window"]).T.reset_index()
    out.columns = ["metric", "count"]
    out["pct"] = (out["count"] / total * 100).round(3) if total else 0
    return out, total


def fetch_volume_integrity(client, cfg, dfrom, dto):
    """Nhóm 2 — vi phạm tính toàn vẹn volume (kỳ vọng = 0 mọi dòng)."""
    t = cfg.table("mv_flash")
    sql = f"""
        SELECT countIf(original_cse < 0)                                     AS neg_original_cse,
               countIf(shipped_cse < 0)                                      AS neg_shipped_cse,
               countIf(san_luong_giao_cse < 0)                              AS neg_delivered_cse,
               countIf(original_qty < 0)                                     AS neg_original_qty,
               countIf(shipped_cse > original_cse AND original_cse > 0)      AS shipped_gt_plan,
               countIf(san_luong_giao_cse > shipped_cse AND shipped_cse > 0) AS delivered_gt_shipped,
               countIf(original_qty <= 0 AND original_cse > 0)               AS qty0_but_cse_positive,
               countIf(original_cse > 0 AND original_pl IS NULL)             AS cse_positive_but_pl_null,
               countIf(san_luong_giao_cse > 0 AND ata_den IS NULL)          AS delivered_volume_but_no_ata
        FROM {t}
        WHERE toDate({DATE_COL}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
    """
    df = da.run_df(client, sql, {"f": dfrom, "t": dto})
    return df.T.reset_index().rename(columns={"index": "metric", 0: "violations"})


def fetch_business_rules(client, cfg, dfrom, dto):
    """Nhóm 3 — vi phạm business rule. Chuỗi tiếng Việt bind qua param."""
    t = cfg.table("mv_flash")
    sql = f"""
        SELECT countIf(status = {{cancel:String}} AND san_luong_giao_cse > 0)        AS cancel_but_delivered,
               countIf(e2e_label = {{delivered:String}} AND ata_den IS NULL)          AS delivered_label_but_no_ata,
               countIf(e2e_label = {{shipping:String}} AND atd_den IS NULL)           AS shipping_label_but_no_atd,
               countIf(e2e_label = {{shipped:String}}
                       AND atd_den IS NOT NULL AND thoi_gian_di IS NOT NULL)          AS shipped_label_but_has_full_stm,
               countIf(ata_den IS NOT NULL AND e2e_label = {{shipping:String}})       AS ata_set_but_still_shipping,
               countIf(toDate(delivery_date_1) > today())                            AS delivery_date_in_future,
               countIf(delivery_date_1 < toDateTime('2020-01-01')
                       OR delivery_date_1 > now() + INTERVAL 90 DAY)                  AS outlier_delivery_date,
               countIf(e2e_label = {{dropped:String}} AND (remark_2 IS NULL OR remark_2 = '')) AS drop_no_reason,
               count()                                                               AS total_rows_in_window
        FROM {t}
        WHERE toDate({DATE_COL}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
    """
    df = da.run_df(client, sql, {
        "f": dfrom, "t": dto,
        "cancel": "Cancel",
        "delivered": "Đã vận chuyển",
        "shipping": "Đang vận chuyển",
        "shipped": "Đã xuất kho",
        "dropped": "Kế hoạch hủy",
    })
    total = int(df["total_rows_in_window"].iloc[0])
    out = df.drop(columns=["total_rows_in_window"]).T.reset_index().rename(
        columns={"index": "metric", 0: "violations"})
    out["pct_window"] = (out["violations"] / total * 100).round(3) if total else 0
    return out, total


def fetch_dup_and_parity(client, cfg, dfrom, dto):
    """Nhóm 4 — duplicate key + cross-MV parity (flash + dropped == combined).

    Parity quét 3 MV; nếu 1 MV thiếu/lỗi cột → ghi nhận vào note, không dừng.
    """
    t = cfg.table("mv_flash")
    dup = da.run_df(client, f"""
        SELECT count() AS dup_key_pairs, coalesce(sum(c), 0) AS dup_row_total
        FROM (
          SELECT so, orderlinenumber, count() AS c
          FROM {t}
          WHERE toDate({DATE_COL}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
          GROUP BY so, orderlinenumber
          HAVING count() > 1
        )
    """, {"f": dfrom, "t": dto})

    parity_rows, notes = [], []
    counts = {}
    for key, logical, name in [("combined", "mv_flash", "mv_flash_and_drop_report"),
                               ("flash", "mv_flash_only", "mv_flash_report"),
                               ("dropped", "mv_drop", "mv_dropped_report")]:
        tbl = cfg.table(logical)
        try:
            n = int(da.run_df(client, f"""
                SELECT count() AS c FROM {tbl}
                WHERE toDate({DATE_COL}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
            """, {"f": dfrom, "t": dto})["c"].iloc[0])
            counts[key] = n
            parity_rows.append({"metric": f"rows_{key} ({name})", "rows": n})
        except Exception as exc:  # noqa: BLE001
            counts[key] = None
            parity_rows.append({"metric": f"rows_{key} ({name})", "rows": "(lỗi)"})
            notes.append(f"`{name}`: {str(exc).splitlines()[0][:120]}")

    if None not in (counts.get("flash"), counts.get("dropped"), counts.get("combined")):
        fp = counts["flash"] + counts["dropped"]
        parity_rows.append({"metric": "flash_plus_dropped", "rows": fp})
        parity_rows.append({"metric": "parity_diff (flash+dropped − combined)",
                            "rows": fp - counts["combined"]})
    return dup, pd.DataFrame(parity_rows), notes


def fetch_timestamp_ordering(client, cfg, dfrom, dto):
    """Nhóm 5 — timestamp ordering (kỳ vọng = 0 mọi dòng)."""
    t = cfg.table("mv_flash")
    sql = f"""
        SELECT countIf(ngay_tao_don IS NOT NULL AND delivery_date_1 IS NOT NULL
                       AND ngay_tao_don > delivery_date_1)                    AS create_after_delivery,
               countIf(thoi_gian_gui_thau IS NOT NULL AND etd_chuyen_gui_thau IS NOT NULL
                       AND thoi_gian_gui_thau > etd_chuyen_gui_thau)         AS bid_after_etd,
               countIf(etd_chuyen_gui_thau IS NOT NULL AND eta_giao_hang_cho_npp IS NOT NULL
                       AND etd_chuyen_gui_thau > eta_giao_hang_cho_npp)      AS etd_after_eta,
               countIf(atd_den IS NOT NULL AND ata_den IS NOT NULL
                       AND atd_den > ata_den)                                AS atd_after_ata,
               countIf(ata_den IS NOT NULL AND etd_chuyen_gui_thau IS NOT NULL
                       AND ata_den < etd_chuyen_gui_thau)                    AS ata_before_etd,
               countIf(actual_ship_date IS NOT NULL AND atd_den IS NOT NULL
                       AND actual_ship_date > atd_den + INTERVAL 1 DAY)      AS asd_far_after_atd,
               countIf(gio_ra_dock IS NOT NULL AND thoi_gian_di IS NOT NULL
                       AND gio_ra_dock > thoi_gian_di)                       AS ra_dock_after_di,
               count()                                                       AS total_rows_in_window
        FROM {t}
        WHERE toDate({DATE_COL}) BETWEEN toDate({{f:String}}) AND toDate({{t:String}})
    """
    df = da.run_df(client, sql, {"f": dfrom, "t": dto})
    total = int(df["total_rows_in_window"].iloc[0])
    out = df.drop(columns=["total_rows_in_window"]).T.reset_index().rename(
        columns={"index": "metric", 0: "violations"})
    out["pct_window"] = (out["violations"] / total * 100).round(3) if total else 0
    return out, total


def build(client, cfg, dfrom: str, dto: str) -> dict:
    """Dựng blocks + metadata audit Flash Daily (KHÔNG ghi file) — main() và
    run_all.py cùng tái dùng. Trả dict: blocks/title/stem/headline/fresh/status."""
    # 1 · Summary
    fresh_meta = da.meta(client, cfg.table("mv_flash"), DATE_COL)
    df_rowcount = fetch_rowcount(client, cfg)
    df_distinct = fetch_distinct(client, cfg, dfrom, dto)
    df_freshness = fetch_freshness(client, cfg)

    # 2 · Phân bố
    df_e2e = fetch_e2e_dist(client, cfg, dfrom, dto)
    dim_dists = []
    for dim, label in [
        ("status", "status (enum TMS raw)"),
        ("type", "type (order type)"),
        ("whseid", "whseid (kho)"),
        ("brand", "brand"),
        ("group_name", "group_name (kênh)"),
        ("khu_vuc_doi_xe", "khu_vuc_doi_xe (khu vực)"),
    ]:
        dim_dists.append((label, fetch_dim_dist(client, cfg, dfrom, dto, dim)))

    # 3 · Volume
    df_vol_total = fetch_volume_total(client, cfg, dfrom, dto)
    df_vol_daily = fetch_volume_daily(client, cfg, dfrom, dto)

    # 4 · Anomaly
    df_nulls, n_window = fetch_nulls(client, cfg, dfrom, dto)
    df_int = fetch_volume_integrity(client, cfg, dfrom, dto)
    df_biz, _ = fetch_business_rules(client, cfg, dfrom, dto)
    df_dup, df_parity, parity_notes = fetch_dup_and_parity(client, cfg, dfrom, dto)
    df_ts, _ = fetch_timestamp_ordering(client, cfg, dfrom, dto)

    # ── so-what: gom số vi phạm để đặt heading ───────────────────────────────
    n_int = int(pd.to_numeric(df_int["violations"], errors="coerce").fillna(0).sum())
    n_biz = int(pd.to_numeric(df_biz["violations"], errors="coerce").fillna(0).sum())
    n_ts = int(pd.to_numeric(df_ts["violations"], errors="coerce").fillna(0).sum())
    n_dup = int(df_dup["dup_key_pairs"].iloc[0])
    parity_diff_row = df_parity[df_parity["metric"].str.startswith("parity_diff")]
    parity_diff = int(parity_diff_row["rows"].iloc[0]) if len(parity_diff_row) else None
    hard_violations = n_int + n_biz + n_ts + n_dup + (abs(parity_diff) if parity_diff else 0)

    verdict = (
        f"⚠ **{hard_violations} vi phạm cứng** (integrity {n_int} · business {n_biz} · "
        f"timestamp {n_ts} · duplicate {n_dup}"
        + (f" · parity_diff {parity_diff}" if parity_diff is not None else "")
        + ") — cần drill bằng notebook gốc (L9/L10)."
        if hard_violations else
        "✓ **Data healthy** — không vi phạm integrity/business/timestamp/duplicate/parity."
    )

    blocks = [
        f"**Window** `{dfrom}` → `{dto}` · trục `{DATE_LABEL}` (`{DATE_COL}`) · "
        f"volume theo `{UOM_COL}`",
        f"- MV chính `mv_flash_and_drop_report` freshness: max_date `{fresh_meta.get('max_date')}`, "
        f"trễ ~{fresh_meta.get('lag_min')}′ · {n_window:,} row trong window",
        f"- {verdict}",

        "## 1 · Summary",
        "**A · Tổng row mỗi MV gốc (không lọc window)**", df_rowcount,
        "**B · Distinct count trong window MTD**", df_distinct,
        "**C · Freshness — max timestamp + lag vs now() (UTC+7)**", df_freshness,

        "## 2 · Phân bố",
        f"**A · Phân bố theo `e2e_label` (volume theo `{UOM_COL}`)**", df_e2e,
    ]
    for label, df in dim_dists:
        blocks += [f"**B · Phân bố theo `{label}` — top 30**", df]

    blocks += [
        "## 3 · Volume",
        "**Tổng volume MTD theo Plan/Shipped/Delivered × CSE/KG/CBM/PL**", df_vol_total,
        "**Daily volume trong window — quan sát ngày sụt/tăng đột biến**", df_vol_daily,

        "## 4 · Anomaly",
        f"**Nhóm 1 · NULL / empty trên cột critical (window có {n_window:,} row)**", df_nulls,
        "**Nhóm 2 · Volume integrity violations (kỳ vọng = 0 mọi dòng)**", df_int,
        "**Nhóm 3 · Business rule violations (kỳ vọng = 0; info ở dòng STM lag/tương lai)**", df_biz,
        "**Nhóm 4 · Duplicate `(so, orderlinenumber)` (kỳ vọng = 0)**", df_dup,
        "**Nhóm 4 · Cross-MV parity — `combined = flash + dropped` (UNION ALL)**", df_parity,
    ]
    if parity_notes:
        blocks.append("> Cảnh báo MV parity:\n" + "\n".join(f"> - {n}" for n in parity_notes))
    blocks += [
        "**Nhóm 5 · Timestamp ordering violations (kỳ vọng = 0 mọi dòng)**", df_ts,
    ]

    return {
        "blocks": blocks,
        "title": f"Flash Daily — Audit chất lượng MTD — {cfg.name}",
        "stem": f"flash-daily-audit-{dto.replace('-', '')}",
        "headline": (f"{n_window:,} row · {hard_violations} vi phạm cứng "
                     f"(int {n_int} · biz {n_biz} · ts {n_ts} · dup {n_dup} · parity {parity_diff})"),
        "fresh": fresh_meta,
        "status": "🟢" if hard_violations == 0 else "🔴",
    }


def main() -> None:
    args = build_parser(
        "Audit chất lượng dữ liệu MTD cho Flash Daily (mv_flash_and_drop_report) → .md + .html"
    ).parse_args()
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
