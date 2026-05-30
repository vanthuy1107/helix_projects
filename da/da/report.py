"""
da.report
─────────
Xuất kết quả TÁCH KHỎI CODE (yêu cầu cố định của user): bảng/finding → file `.md`
sạch (diff git được) HOẶC `.html` (bộ nhận diện Smartlog lightmode — gửi stakeholder).

`save_md` và `save_html` ăn CÙNG một `blocks` list (str | DataFrame) → script chỉ
thêm ĐÚNG 1 dòng để có thêm bản HTML, không phải dựng lại gì.
"""
from __future__ import annotations

import html as _html
import re
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


# ─────────────────────────────────────────────────────────────────────────────
# HTML — bộ nhận diện Smartlog Control Tower lightmode (đồng bộ /da-ops-release):
# navy #1E3A5F · dark #14283F · accent #2563EB · pale #EFF4FB.
# KHÔNG dark mode · KHÔNG gradient · KHÔNG drop-shadow · font-weight ≤ 500.
# ─────────────────────────────────────────────────────────────────────────────
_HTML_CSS = """
:root { --navy:#1E3A5F; --dark:#14283F; --accent:#2563EB; --pale:#EFF4FB;
        --grey:#9AA5B1; --line:#E2E8F0; --green:#287819; --amber:#E18719; --red:#C0392B; }
* { box-sizing: border-box; }
body { margin:0; background:#FFFFFF; color:var(--dark);
       font-family:"Segoe UI",system-ui,-apple-system,"Helvetica Neue",Arial,sans-serif;
       font-size:14px; line-height:1.55; font-weight:400; }
.wrap { max-width:980px; margin:0 auto; padding:32px 36px 64px; }
h1 { color:var(--navy); font-weight:500; font-size:23px; margin:0 0 4px;
     padding-bottom:10px; border-bottom:2px solid var(--accent); }
h2 { color:var(--navy); font-weight:500; font-size:18px; margin:30px 0 10px;
     padding-left:10px; border-left:3px solid var(--accent); }
h3 { color:var(--navy); font-weight:500; font-size:15px; margin:20px 0 8px; }
p { margin:8px 0; }
p.subtitle { color:var(--grey); margin:0 0 18px; }
a { color:var(--accent); text-decoration:none; }
a:hover { text-decoration:underline; }
code { background:var(--pale); color:var(--navy); padding:1px 5px; border-radius:3px;
       font-family:"Cascadia Code",Consolas,"SF Mono",monospace; font-size:12.5px; }
ul { margin:8px 0; padding-left:22px; }
li { margin:3px 0; }
blockquote { margin:12px 0; padding:8px 14px; background:var(--pale);
             border-left:3px solid var(--grey); color:var(--dark); }
blockquote p { margin:4px 0; }
table { border-collapse:collapse; margin:10px 0 18px; width:100%; font-size:13px; }
table th { background:var(--pale); color:var(--navy); font-weight:500; text-align:left;
           padding:7px 10px; border-bottom:2px solid var(--navy); white-space:nowrap; }
table td { padding:6px 10px; border-bottom:1px solid var(--line); vertical-align:top; }
table tr:nth-child(even) td { background:#FAFBFD; }
table.dataframe td:not(:first-child) { text-align:right; font-variant-numeric:tabular-nums; }
"""

_HTML_DOC = """<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>{css}</style>
</head>
<body><div class="wrap">
{body}
</div></body>
</html>
"""


def _esc(s: str) -> str:
    """Escape ký tự HTML đặc biệt (& < >) — gọi TRƯỚC khi chèn vào markup."""
    return _html.escape(str(s), quote=False)


def _inline(s: str) -> str:
    """Inline markdown → HTML cho TẬP CON đang dùng: `code`, **bold**, _italic_.

    Bảo vệ `code` span trước (placeholder) để dấu `_`/`*` trong tên cột
    (vd `khu_vuc_doi_xe`) KHÔNG bị hiểu nhầm là italic/bold.
    """
    codes: list[str] = []

    def _stash(m: re.Match) -> str:
        codes.append(m.group(1))
        return f"\x00{len(codes) - 1}\x00"

    s = re.sub(r"`([^`]+)`", _stash, s)
    s = _esc(s)
    s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', s)   # [text](href)
    s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
    # italic: dấu `_` mở đầu từ/sau khoảng trắng, đóng trước ranh giới từ — chừa
    # các `_` nằm GIỮA từ (định danh) khỏi bị nuốt.
    s = re.sub(r"(?<![\w])_(?=\S)(.+?)(?<=\S)_(?![\w])", r"<em>\1</em>", s)
    s = re.sub(r"\x00(\d+)\x00",
               lambda m: f"<code>{_esc(codes[int(m.group(1))])}</code>", s)
    return s


def _is_table_sep(line: str) -> bool:
    """Dòng phân cách header bảng pipe: chỉ gồm | : - và khoảng trắng, có ít nhất 1 '-'."""
    t = line.strip()
    return bool(t) and "-" in t and re.fullmatch(r"[\s:|\-]+", t) is not None


def _split_row(line: str) -> list[str]:
    """Tách 1 dòng bảng pipe thành các ô (bỏ | bao ngoài)."""
    return [c.strip() for c in line.strip().strip("|").split("|")]


def _md_to_html(md: str) -> str:
    """Block-level markdown → HTML cho tập con report dùng: heading, list, blockquote,
    bảng pipe, paragraph. Cú pháp NGOÀI tập con → render an toàn dạng paragraph
    (converter có chủ đích giới hạn, không phải markdown engine tổng quát)."""
    lines = md.split("\n")
    out: list[str] = []
    i, n = 0, len(lines)

    while i < n:
        raw = lines[i]
        s = raw.strip()
        if not s:
            i += 1
            continue

        m = re.match(r"(#{1,6})\s+(.*)", s)                       # heading
        if m:
            lvl = len(m.group(1))
            out.append(f"<h{lvl}>{_inline(m.group(2))}</h{lvl}>")
            i += 1
            continue

        if "|" in s and i + 1 < n and _is_table_sep(lines[i + 1]):  # bảng pipe
            header = _split_row(s)
            i += 2
            rows: list[list[str]] = []
            while i < n and "|" in lines[i] and lines[i].strip():
                rows.append(_split_row(lines[i]))
                i += 1
            th = "".join(f"<th>{_inline(c)}</th>" for c in header)
            trs = "".join(
                "<tr>" + "".join(f"<td>{_inline(c)}</td>" for c in r) + "</tr>"
                for r in rows
            )
            out.append(f"<table><thead><tr>{th}</tr></thead><tbody>{trs}</tbody></table>")
            continue

        if s.startswith(">"):                                     # blockquote
            buf = []
            while i < n and lines[i].strip().startswith(">"):
                buf.append(re.sub(r"^\s*>\s?", "", lines[i]))
                i += 1
            out.append(f"<blockquote>{_md_to_html(chr(10).join(buf))}</blockquote>")
            continue

        if re.match(r"[-*]\s+", s):                               # bullet list
            items = []
            while i < n and re.match(r"[-*]\s+", lines[i].strip()):
                items.append(_inline(re.sub(r"^[-*]\s+", "", lines[i].strip())))
                i += 1
            out.append("<ul>" + "".join(f"<li>{it}</li>" for it in items) + "</ul>")
            continue

        buf = [s]                                                 # paragraph
        i += 1
        while i < n:
            nxt = lines[i].strip()
            if (not nxt or re.match(r"(#{1,6}\s|[-*]\s|>)", nxt)
                    or ("|" in nxt and i + 1 < n and _is_table_sep(lines[i + 1]))):
                break
            buf.append(nxt)
            i += 1
        out.append(f"<p>{_inline(' '.join(buf))}</p>")

    return "\n".join(out)


def save_html(blocks, path, *, title: str | None = None,
              subtitle: str | None = None) -> Path:
    """Ghi `blocks` (CÙNG định dạng save_md) ra 1 file `.html` self-contained.

    str       → _md_to_html (heading/bold/code/list/blockquote/bảng pipe).
    DataFrame → df.to_html (class 'dataframe' → CSS canh phải cột số).
    CSS inline theo bộ nhận diện Smartlog lightmode → mở browser / gửi đi ngay.
    """
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if not isinstance(blocks, (list, tuple)):
        blocks = [blocks]

    parts: list[str] = []
    if title:
        parts.append(f"<h1>{_esc(title)}</h1>")
    if subtitle:
        parts.append(f"<p class='subtitle'>{_inline(subtitle)}</p>")
    for b in blocks:
        if isinstance(b, pd.DataFrame):
            parts.append(b.to_html(index=False, classes="dataframe", border=0,
                                   escape=True, na_rep=""))
        else:
            parts.append(_md_to_html(str(b)))

    doc = _HTML_DOC.format(title=_esc(title or "DA Report"),
                           css=_HTML_CSS, body="\n".join(parts))
    path.write_text(doc, encoding="utf-8")
    return path
