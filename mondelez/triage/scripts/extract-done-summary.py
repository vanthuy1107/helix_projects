"""
Extract done-summary.md → per-item stubs with history tracking.

Reads `done-summary.md` (170 Done + 29 WIP + 13 Unmapped rows) and produces
one stub `[D|W|?]-DONE-NNN-<module>-r<row>-<slug>.md` per item under
{bugs|discoveries|prd-asks}/{tech_layer}/ following the existing triage layout.

Usage:
    python scripts/extract-done-summary.py [--dry-run]

The Excel source itself is not re-parsed here — we faithfully replay rows
that done-summary.md has already canonicalized.
"""
from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
SOURCE = BASE / "done-summary.md"
TRIAGE_DATE = "2026-05-09"
EXCEL_SOURCE = "projects/mondelez/Edit UX_UI_MDLZ.xlsx"

MODULE_MAP = {
    "%Stock Type (214)": "stock-type",
    "%Utilization (224)": "utilization",
    "Cảnh báo đơn trễ (204)": "late-order-alert",
    "Flash report (214)": "flash-report",
    "Movement transaction (214)": "movement-transaction",
    "OTIF (204)": "otif",
    "Sheet7": "sheet7-misc",
    "Tiến độ xuất hàng (204)": "shipping-progress",
    "Tỷ lệ đáp ứng và tuân thủ": "fulfillment-compliance",
    "VFR": "vfr",
    "VFR (224)": "vfr-224",
}


@dataclass
class Item:
    status_prefix: str  # 'D' | 'W' | 'U' (unmapped; was '?' in done-summary.md but '?' is invalid in Windows filenames)
    sheet: str
    row: str
    status_raw: str
    item_text: str
    seq: int = 0  # filled later

    @property
    def module_slug(self) -> str:
        return MODULE_MAP.get(self.sheet, slugify(self.sheet, 3))


def slugify(text: str, max_words: int = 5) -> str:
    text = unicodedata.normalize("NFD", text)
    text = "".join(c for c in text if unicodedata.category(c) != "Mn")
    text = text.replace("đ", "d").replace("Đ", "D")
    text = re.sub(r"[^\w\s-]", " ", text).strip().lower()
    words = [w for w in re.split(r"\s+", text) if w]
    return "-".join(words[:max_words])[:50] or "item"


def classify_type(item_text: str) -> str:
    t = item_text.lower()
    if "[bug]" in t or "[ui]" in t and "bug" in t:
        return "BUG"
    if any(k in t for k in ["bổ sung", "bổ xung", "thêm ", "combine", "switch filter", "bổ sung chart", "bổ sung report"]):
        return "FEAT"
    return "UX"


def classify_tech_layer(item_text: str) -> str:
    t = item_text.lower()
    if "phân quyền" in t:
        return "cross-stack"
    if any(k in t for k in ["combine data", "realtime", "pipeline", "số sai", "số lệch", "tổng thực xuất", "kế hoạch xuất"]):
        return "etl-data"
    if any(k in t for k in ["đổi tên view", "đổi tên scorecard", "đổi tên chart", "để tên view", "đổi tên"]):
        return "backend-config"
    if "param" in t or "bộ lọc type" in t:
        return "backend-config"
    if "bộ lọc" in t:
        return "frontend-config"
    if any(k in t for k in ["scorecard", "card", "thẻ kpi"]):
        return "frontend-widget"
    if any(k in t for k in ["chart", "biểu đồ", "time series", "bar chart", "line chart", "pie chart", "icon ?", "icon"]):
        return "frontend-widget"
    if any(k in t for k in ["report", "sort", "search", "cột", "pivot", "bảng", "ẩn cột", "hide cột"]):
        return "frontend-config"
    if any(k in t for k in ["download", "apply filter", "reset filter", "vị trí", "relayout", "layout", "kích thước", "loading", "highlight", "show số liệu", "dark", "mode", "size chữ", "thu gọn", "kéo dài", "fixed filter scroll"]):
        return "frontend-widget"
    return "unknown"


def folder_for_type(t: str) -> str:
    return {"BUG": "bugs", "FEAT": "discoveries", "UX": "prd-asks"}[t]


# ─── Parser ───────────────────────────────────────────────────────────────

def parse_done_summary(source_md: str) -> list[Item]:
    items: list[Item] = []
    lines = source_md.splitlines()
    i = 0
    section = None  # 'D' | 'W' | '?'
    current_sheet = None

    while i < len(lines):
        line = lines[i]

        if line.startswith("## `[D]` Done items"):
            section = "D"
        elif line.startswith("## `[W]`"):
            section = "W"
            current_sheet = None
        elif line.startswith("## `?`"):
            section = "U"
            current_sheet = None
        elif line.startswith("## "):
            section = None

        if section == "D" and line.startswith("### "):
            m = re.match(r"### `([^`]+)` — \d+ done items", line)
            if m:
                current_sheet = m.group(1)

        if section in ("D", "W", "U") and line.startswith("| ") and not line.startswith("| ---"):
            cols = [c.strip() for c in line.strip().strip("|").split("|")]
            if section == "D" and current_sheet and len(cols) >= 3:
                row, status, text = cols[0], cols[1], cols[2]
                if row.isdigit():
                    items.append(Item("D", current_sheet, row, status.strip("`"), text))
            elif section == "W" and len(cols) >= 4:
                sheet, row, status, text = cols[0], cols[1], cols[2], cols[3]
                if row.isdigit():
                    items.append(Item("W", sheet, row, status.strip("`"), text))
            elif section == "U" and len(cols) >= 4:
                sheet, row, status, text = cols[0], cols[1], cols[2], cols[3]
                if row.isdigit():
                    items.append(Item("U", sheet, row, status.strip("`"), text))
        i += 1

    for n, it in enumerate(items, start=1):
        it.seq = n
    return items


# ─── Renderer ─────────────────────────────────────────────────────────────

def stub_filename(it: Item) -> str:
    type_label = classify_type(it.item_text)
    item_slug = slugify(it.item_text, 5)
    return f"[{it.status_prefix}]-DONE-{it.seq:03d}-{it.module_slug}-r{it.row}-{item_slug}.md"


def stub_relpath(it: Item) -> str:
    type_label = classify_type(it.item_text)
    folder = folder_for_type(type_label)
    layer = classify_tech_layer(it.item_text)
    return f"{folder}/{layer}/{stub_filename(it)}"


STATUS_LABEL = {
    "D": "Done",
    "W": "Work In Progress",
    "U": "Unmapped — needs BA review (was `?` in done-summary.md; `?` is invalid in Windows paths)",
}


def render_stub(it: Item) -> str:
    type_label = classify_type(it.item_text)
    layer = classify_tech_layer(it.item_text)
    status_label = STATUS_LABEL[it.status_prefix]

    if it.status_prefix == "D":
        history_first = f"| (unknown, before {TRIAGE_DATE}) | Marked done by MDLZ in Excel | Khách MDLZ | row {it.row} of `{it.sheet}` sheet — status `{it.status_raw}` |"
        next_action = "Re-verify trên môi trường hiện tại — confirm còn work, không regression."
    elif it.status_prefix == "W":
        history_first = f"| {TRIAGE_DATE} | Captured during triage as WIP | SLG triage | row {it.row} of `{it.sheet}` sheet — status `{it.status_raw}` |"
        next_action = "Kiểm tra với DEV team xem ai đang làm + ETA. Khi xong → đổi prefix `[W]` → `[D]` + add history row."
    else:  # U
        history_first = f"| {TRIAGE_DATE} | Flagged unmapped during triage | SLG triage | row {it.row} of `{it.sheet}` sheet — status `{it.status_raw}` (không khớp convention) |"
        next_action = "BA review: status `sao lại dùng bộ lọc riêng ??` là **câu hỏi của khách** (không phải status). Cần clarify với reporter rồi map về `[D]/[W]/[-]`. Khi resolved → đổi prefix file `[U]` → đúng status mới."

    return f"""# [{it.status_prefix}]-DONE-{it.seq:03d}: {it.item_text[:80]}

- **Status**: {status_label}
- **Type guess**: {type_label} (heuristic)
- **Tech layer guess**: `{layer}` (heuristic — verify khi review)
- **Module / Sheet**: `{it.sheet}` → slug `{it.module_slug}`
- **Source**: row {it.row} of `{EXCEL_SOURCE}`
- **Raw status in Excel**: `{it.status_raw}`
- **Tenant**: MDLZ (Mondelez)

## History / Audit trail

| Date | Event | Actor | Ref |
|---|---|---|---|
{history_first}
| TBD | PR / commit link | TBD | TBD |
| TBD | QA re-verify | TBD | TBD |
| TBD | UAT confirm by MDLZ | TBD | TBD |

## Logic — what was fixed / what needs fixing

<!-- Điền khi có thông tin: file thay đổi, FormConfig code, QueryConfig code, behavior change. -->
<!-- Nếu Done & chưa biết logic → đánh dấu "Logic unknown — captured retroactively from done-summary". -->

- Files changed: TBD
- Config code (FormConfig/QueryConfig/etc.): TBD
- Behavior before: TBD
- Behavior after: TBD

## Raw quote

> {it.item_text}

(Source: sheet `{it.sheet}`, row {it.row}, status text `{it.status_raw}`)

## Re-verify checklist

- [ ] Vẫn work trên môi trường hiện tại (smoke test)
- [ ] Không có regression liên quan
- [ ] FormConfig / QueryConfig code đã verify (nếu liên quan config-driven)
- [ ] UAT confirm bởi reporter MDLZ

## Next

{next_action}

---

_Generated by `scripts/extract-done-summary.py` on {TRIAGE_DATE} from `done-summary.md`._
"""


# ─── Main ─────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Don't write files, just report stats")
    args = parser.parse_args()

    if not SOURCE.exists():
        print(f"FATAL: source not found at {SOURCE}", file=sys.stderr)
        return 1

    md = SOURCE.read_text(encoding="utf-8")
    items = parse_done_summary(md)

    by_status: dict[str, int] = {"D": 0, "W": 0, "U": 0}
    by_folder: dict[str, int] = {}
    by_layer: dict[str, int] = {}

    written = 0
    for it in items:
        by_status[it.status_prefix] += 1
        rel = stub_relpath(it)
        target = BASE / rel
        folder_key = "/".join(rel.split("/")[:2])
        by_folder[folder_key] = by_folder.get(folder_key, 0) + 1
        by_layer[classify_tech_layer(it.item_text)] = by_layer.get(classify_tech_layer(it.item_text), 0) + 1

        if not args.dry_run:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(render_stub(it), encoding="utf-8")
            written += 1

    print(f"Parsed {len(items)} items: D={by_status['D']} W={by_status['W']} U={by_status['U']}")
    print(f"\nBy folder:")
    for k, v in sorted(by_folder.items()):
        print(f"  {k:35s} {v:4d}")
    print(f"\nBy tech_layer:")
    for k, v in sorted(by_layer.items()):
        print(f"  {k:20s} {v:4d}")
    print(f"\nFiles written: {written} {'(dry-run, nothing actually written)' if args.dry_run else ''}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
