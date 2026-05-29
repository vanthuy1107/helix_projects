"""da — thư viện Data Analysis dùng chung (đa tenant) cho Smartlog Control Tower.

Diệt copy-paste: kết nối ClickHouse, macro SQL, reconcile, export — một nguồn chân lý.
Xem README.md và mondelez/03-build/da-python-platform-plan.md.
"""
from .config import load_tenant, TenantConfig, ChCreds, validate_env
from .ch import ch_client, run_df, meta
from .macros import DT, NUM, ontime
from .reconcile import align_grain, full_outer_by, delta_flags, reconcile_by_day
from .report import save_md, setup_display, PALETTE

__version__ = "0.1.0"
__all__ = [
    "load_tenant", "TenantConfig", "ChCreds", "validate_env",
    "ch_client", "run_df", "meta",
    "DT", "NUM", "ontime",
    "align_grain", "full_outer_by", "delta_flags", "reconcile_by_day",
    "save_md", "setup_display", "PALETTE",
]
