"""
da.report
─────────
Xuất kết quả TÁCH KHỎI CODE (yêu cầu cố định của user): bảng/finding → file `.md`
sạch, không bắt người đọc cuộn qua code. Kèm display options & bảng màu dùng chung.
"""
from __future__ import annotations

from pathlib import Path

import pandas as pd

# Bảng màu Smartlog Control Tower (gom từ các notebook, hết rải rác hằng số màu).
PALETTE = {
    "navy": "#1E3A5F", "accent": "#2563EB", "green": "#287819",
    "amber": "#E18719", "red": "#C0392B", "blue": "#2D6EAA", "grey": "#9AA5B1",
}


def setup_display() -> None:
    """pd.set_option dùng chung cho notebook/script (thay 3 bản copy)."""
    pd.set_option("display.max_rows", 300)
    pd.set_option("display.max_colwidth", 80)
    pd.set_option("display.float_format", lambda v: f"{v:,.2f}")


def save_md(blocks, path, *, title: str | None = None) -> Path:
    """Ghi danh sách block ra MỘT file `.md` sạch (tách code khỏi kết quả).

    blocks: một phần tử hoặc list trộn:
      - str          → chèn nguyên (markdown/heading/ghi chú)
      - pd.DataFrame  → render thành bảng markdown (cần `tabulate`)
    Mở file bằng VSCode Preview (Ctrl+Shift+V) để xem gọn, version-được trong git.
    """
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if not isinstance(blocks, (list, tuple)):
        blocks = [blocks]

    parts: list[str] = []
    if title:
        parts.append(f"# {title}")
    for b in blocks:
        parts.append(b.to_markdown(index=False) if isinstance(b, pd.DataFrame) else str(b))

    path.write_text("\n\n".join(parts) + "\n", encoding="utf-8")
    return path
