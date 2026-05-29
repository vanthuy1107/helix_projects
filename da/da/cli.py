"""
da.cli
──────
Scaffold argparse chuẩn cho script CLI — một cách parse tham số nhất quán
(--tenant / --from / --to), thay vì mỗi script tự dựng argparse khác nhau.
"""
from __future__ import annotations

import argparse
from datetime import date

from .config import load_tenant, TenantConfig


def build_parser(description: str) -> argparse.ArgumentParser:
    """Parser chuẩn cho script DA: chọn tenant + cửa sổ thời gian."""
    p = argparse.ArgumentParser(description=description)
    p.add_argument("--tenant", default=None,
                   help="Tên tenant (mặc định: tự dò .env gần nhất từ CWD)")
    p.add_argument("--from", dest="dfrom", default=None, help="Ngày bắt đầu YYYY-MM-DD (mặc định: đầu tháng)")
    p.add_argument("--to", dest="dto", default=None, help="Ngày kết thúc YYYY-MM-DD (mặc định: hôm nay)")
    return p


def resolve(args) -> tuple[TenantConfig, tuple[str, str]]:
    """args → (TenantConfig, (from, to)). Mặc định window = MTD (đầu tháng → hôm nay)."""
    cfg = load_tenant(args.tenant)
    today = date.today()
    dfrom = args.dfrom or today.replace(day=1).isoformat()
    dto = args.dto or today.isoformat()
    return cfg, (dfrom, dto)
