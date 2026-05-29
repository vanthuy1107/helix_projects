"""
da.reconcile
────────────
Framework đối chiếu chéo 2 nguồn (xem /da-py §6) — biến việc reconcile lặp đi lặp lại
(TMS report #25 ↔ mv_otif) thành API tái dùng, thay vì gõ lại mỗi lần.

Quy tắc tin cậy: CHỈ tin cột SỐ ĐƠN; % nếu hai nguồn khác mẫu số → chỉ tham khảo.
"""
from __future__ import annotations

import pandas as pd


def align_grain(df: pd.DataFrame, key: list[str], agg: dict) -> pd.DataFrame:
    """Rollup `df` về cùng grain TRƯỚC khi so sánh (bắt buộc — chống double-count).

    agg: {cột_output: (cột_nguồn, hàm_agg)}. Vd TMS một đơn vào nhiều chuyến:
        align_grain(tms, ['OrderCode'], {'kh': ('QuantityOrder', 'max')})
    dùng `max` để không cộng trùng khối lượng khi đơn lặp trên nhiều dòng chuyến.
    """
    return df.groupby(key, dropna=False).agg(**{
        out: pd.NamedAgg(column=src, aggfunc=fn) for out, (src, fn) in agg.items()
    }).reset_index()


def full_outer_by(a: pd.DataFrame, b: pd.DataFrame, on: list[str],
                  suffixes: tuple[str, str] = ("_a", "_b")) -> pd.DataFrame:
    """Full-outer-join + cột `_merge` (left_only/right_only/both).
    `_merge != both` = lệch TẬP ĐƠN (khác với lệch SỐ LIỆU — phân loại riêng)."""
    return a.merge(b, on=on, how="outer", suffixes=suffixes, indicator=True)


def delta_flags(m: pd.DataFrame, col_a: str, col_b: str, *,
                out: str = "delta", green: int = 0, amber: int = 2) -> pd.DataFrame:
    """Thêm cột `out` = a - b và cờ `{out}_flag`: 🟢(=green) 🟡(<=amber) 🔴(>amber).
    NULL coi như 0 để so số đơn (đơn vắng ở một nguồn = chênh thật)."""
    m = m.copy()
    a = pd.to_numeric(m[col_a], errors="coerce").fillna(0)
    b = pd.to_numeric(m[col_b], errors="coerce").fillna(0)
    m[out] = a - b

    def _flag(d: float) -> str:
        ad = abs(d)
        return "🟢" if ad == green else ("🟡" if ad <= amber else "🔴")

    m[f"{out}_flag"] = m[out].map(_flag)
    return m


def reconcile_by_day(a: pd.DataFrame, b: pd.DataFrame, *,
                     on: tuple[str, ...] | list[str] = ("ngay",),
                     count_a: str = "don_a", count_b: str = "don_b",
                     amber: int = 2) -> pd.DataFrame:
    """Đối chiếu SỐ ĐƠN theo ngày giữa 2 nguồn đã rollup. Trả bảng có Δ + cờ.

    Hai nguồn truyền vào phải đã cùng grain (mỗi `on` một dòng). CHỈ tin cột số đơn;
    nếu kèm cột % thì chỉ để tham khảo (hai nguồn thường khác mẫu số).
    """
    on = list(on)
    m = full_outer_by(a, b, on=on)
    m = delta_flags(m, count_a, count_b, out="d_don", amber=amber)
    return m.sort_values(on).reset_index(drop=True)
