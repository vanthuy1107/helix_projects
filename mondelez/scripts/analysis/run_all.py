"""
run_all.py
──────────
Chạy TẤT CẢ report audit/reconcile của tenant trong một lệnh, xuất `.md` + `.html`
cho từng cái, rồi sinh trang chủ `reports/index.html` liên kết toàn bộ (kèm
freshness + headline + cờ trạng thái) — một cú click mở từng report.

Tái dùng hàm `build()` của mỗi script (Single-Purpose: build dựng blocks, run_all
lo điều phối + ghi file) → KHÔNG lặp lại logic fetch. Mỗi report lỗi → ghi 🔴 vào
index, KHÔNG làm hỏng cả lượt chạy.

Cách chạy (từ thư mục gốc helix-projects/):
    python mondelez/scripts/analysis/run_all.py
    python mondelez/scripts/analysis/run_all.py --from 2026-05-01 --to 2026-05-28

Env (mondelez/.env): CLICKHOUSE_*.  Config nghiệp vụ: mondelez/da.toml.
"""
from __future__ import annotations

from pathlib import Path

import da
from da.cli import build_parser, resolve

import otif_mtd_audit
import flash_daily_audit
import tms_report_25_audit
import reconcile_tms_otif

# Đăng ký report — thêm 1 dòng là có thêm report trong index (không hardcode rải rác).
REPORTS = [
    ("OTIF MTD",               otif_mtd_audit),
    ("Flash Daily MTD",        flash_daily_audit),
    ("TMS Report #25",         tms_report_25_audit),
    ("TMS ↔ OTIF (reconcile)", reconcile_tms_otif),
]


def _fresh_str(fresh: dict) -> str:
    """Freshness gọn cho index: max_date + lag (phút) vs now."""
    if not fresh:
        return "—"
    return f"`{fresh.get('max_date')}` · trễ ~{fresh.get('lag_min')}′"


def main() -> None:
    args = build_parser(
        "Chạy mọi report audit/reconcile → .md + .html + reports/index.html"
    ).parse_args()
    if not args.tenant:
        args.tenant = next(p for p in Path(__file__).resolve().parents
                           if (p / "da.toml").exists())  # tenant root = nơi có da.toml (relocation-proof)
    cfg, (dfrom, dto) = resolve(args)
    client = da.ch_client(cfg)
    reports_dir = cfg.root / "reports"

    rows = []   # mỗi dòng index: (label, status, window, freshness, headline, html_name)
    for label, mod in REPORTS:
        try:
            r = mod.build(client, cfg, dfrom, dto)
            out = reports_dir / f"{r['stem']}.md"
            da.save_md(r["blocks"], out, title=r["title"])
            da.save_html(r["blocks"], out.with_suffix(".html"), title=r["title"])
            rows.append((label, r["status"], f"`{dfrom}`→`{dto}`",
                         _fresh_str(r.get("fresh", {})), r["headline"],
                         f"{r['stem']}.html"))
            print(f"[OK] {label}: {out.name} + .html — {r['headline']}")
        except Exception as exc:  # noqa: BLE001 — 1 report lỗi không làm hỏng cả lượt
            msg = str(exc).splitlines()[0][:120]
            rows.append((label, "🔴", f"`{dfrom}`→`{dto}`", "—", f"(lỗi: {msg})", ""))
            print(f"[ERROR] {label}: {msg}")

    # ── index.html: bảng liên kết toàn bộ report ────────────────────────────
    header = "| Report | TT | Window | Freshness MV | Headline | Mở |\n|---|:--:|---|---|---|---|\n"
    body = "".join(
        f"| **{lbl}** | {st} | {win} | {fr} | {hl} | "
        f"{f'[xem]({href})' if href else '—'} |\n"
        for (lbl, st, win, fr, hl, href) in rows
    )
    blocks = [
        f"Cập nhật theo lệnh `run_all.py` · window `{dfrom}` → `{dto}` · tenant `{cfg.name}`.",
        "Cờ trạng thái: 🟢 đạt / không vi phạm · 🟡 lệch nhẹ · 🔴 lệch nặng hoặc lỗi.",
        header + body,
        "> File `.md` đi kèm mỗi report (cùng tên, đuôi `.md`) để diff git / xem trong VSCode.",
    ]
    index = da.save_html(blocks, reports_dir / "index.html",
                         title=f"DA Reports — {cfg.name} — {dto}")
    print(f"[OK] index → {index}")


if __name__ == "__main__":
    main()
