"""
da.macros
─────────
Mảnh SQL GENERIC dùng lại mọi tenant. Gom `DT`/`NUM`/`ONTIME` đang bị copy
& divergence âm thầm giữa các notebook (tms định nghĩa, otif tái suy ra).

Chỉ chứa thứ GIỐNG nhau mọi tenant. Scope đặc thù (service, so_valid, grace)
lấy từ `cfg.scope` — KHÔNG nhúng cứng ở đây.
"""
from __future__ import annotations


def DT(col: str) -> str:
    """Parse cột chuỗi ngày → DateTime an toàn (rỗng → NULL)."""
    return f"parseDateTimeBestEffortOrNull(nullIf({col}, ''))"


def NUM(col: str) -> str:
    """Cột chuỗi số → Float64 (rỗng/sai định dạng → 0)."""
    return f"toFloat64OrZero({col})"


def ontime(come: str, eta: str, grace_min: int) -> str:
    """Điều kiện on-time có dung sai: đến đúng hạn nếu come <= eta + grace_min.

    Tham số hoá `grace_min` (KHÔNG dùng global GRACE) để hai notebook không thể
    divergence ngầm khi một bên đổi dung sai mà bên kia quên.
    """
    return f"{DT(come)} <= addMinutes({DT(eta)}, {grace_min})"
