"""
fetch_sql_registry.py
─────────────────────
Kéo dữ liệu SQL Registry từ Google Sheet "Summary_Report" và xuất ra
projects/mondelez/02-data/data-sources/sql-registry.md để dùng cho:
  - clickhouse-migration.prompt.md
  - clickhouse-skill-guide.prompt.md
  - Debug / reference SQL

Cách chạy:
    python projects/mondelez/scripts/meta/fetch_sql_registry.py

Env vars cần có trong projects/mondelez/.env:
    GOOGLE_APPLICATION_CREDENTIALS  — đường dẫn tới service account JSON
    GOOGLE_SHEET_ID                 — ID của Google Spreadsheet

Mỗi lần chạy sẽ fetch dữ liệu MỚI NHẤT từ Google Sheet.
"""

import os
import sys
import json
import re
from datetime import datetime
from pathlib import Path

from dotenv import load_dotenv

# ── Load .env ────────────────────────────────────────────────────────────────
_PROJECT_DIR = next(p for p in Path(__file__).resolve().parents
                    if (p / "da.toml").exists())  # tenant root = nơi có da.toml (relocation-proof)
_env_file = _PROJECT_DIR / ".env"
if _env_file.exists():
    load_dotenv(_env_file)
else:
    load_dotenv()

CREDENTIALS_PATH = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
SHEET_ID = os.getenv("GOOGLE_SHEET_ID")
SHEET_NAME = "Summary_Report"

# Output paths
OUTPUT_MD = _PROJECT_DIR / "02-data" / "data-sources" / "sql-registry.md"


# ── Validate env ─────────────────────────────────────────────────────────────
def validate_env() -> None:
    errors = []
    if not CREDENTIALS_PATH:
        errors.append("GOOGLE_APPLICATION_CREDENTIALS chưa được set trong .env")
    elif not Path(CREDENTIALS_PATH).exists():
        errors.append(f"File credentials không tồn tại: {CREDENTIALS_PATH}")
    if not SHEET_ID:
        errors.append("GOOGLE_SHEET_ID chưa được set trong .env")
    if errors:
        for e in errors:
            print(f"[ERROR] {e}")
        sys.exit(1)


# ── Kết nối Google Sheet ──────────────────────────────────────────────────────
def get_sheet_data() -> list[dict]:
    """
    Kết nối Google Sheet bằng service account, đọc toàn bộ "Summary_Report".
    Trả về list[dict] với keys chuẩn hóa.
    """
    try:
        import gspread
        from google.oauth2.service_account import Credentials
    except ImportError:
        print("[ERROR] Thiếu thư viện. Chạy: pip install gspread google-auth")
        sys.exit(1)

    scopes = [
        "https://www.googleapis.com/auth/spreadsheets.readonly",
        "https://www.googleapis.com/auth/drive.readonly",
    ]
    creds = Credentials.from_service_account_file(CREDENTIALS_PATH, scopes=scopes)
    client = gspread.authorize(creds)

    spreadsheet = client.open_by_key(SHEET_ID)
    worksheet = spreadsheet.worksheet(SHEET_NAME)

    # Lấy tất cả dữ liệu dưới dạng list of lists
    raw = worksheet.get_all_values()
    if not raw or len(raw) < 2:
        print("[WARN] Sheet trống hoặc chỉ có header.")
        return []

    # Header row → chuẩn hóa tên cột
    headers = [h.strip() for h in raw[0]]
    print(f"[INFO] Đọc được {len(raw) - 1} dòng từ sheet '{SHEET_NAME}'")
    print(f"[INFO] Columns: {headers}")

    rows = []
    for row in raw[1:]:
        # Pad row nếu ngắn hơn header
        padded = row + [""] * (len(headers) - len(row))
        record = {headers[i]: padded[i].strip() for i in range(len(headers))}
        rows.append(record)

    return rows


# ── Detect column mapping ─────────────────────────────────────────────────────
def detect_columns(rows: list[dict]) -> dict:
    """
    Tự động detect tên cột thực tế trong sheet (tiêu đề có thể thay đổi).
    Trả về mapping: {field_key: actual_column_name}
    Mỗi cột chỉ được map vào 1 field (không tái sử dụng).
    """
    if not rows:
        return {}

    sample_keys = list(rows[0].keys())
    mapping = {}
    used_cols: set[str] = set()

    # Thứ tự quan trọng: đặc thù nhất trước, chung nhất sau
    patterns = {
        "sql_redshift": r"(redshift|sql.*redshift|redshift.*sql)",
        "sql_clickhouse": r"(clickhouse|sql.*click|click.*sql)",
        "status": r"(trạng|status|p đánh|note|ghi chú)",
        "source": r"(tên sheet|sheet name|source|nguồn)",
        "chart": r"(^chart$|biểu đồ|^chart\b)",
    }

    for field, pattern in patterns.items():
        for col in sample_keys:
            if col in used_cols:
                continue
            if re.search(pattern, col, re.IGNORECASE):
                mapping[field] = col
                used_cols.add(col)
                break

    # Fallback: dùng thứ tự cột cho field chưa được map
    fallback_order = ["source", "chart", "sql_redshift", "sql_clickhouse", "status"]
    for i, field in enumerate(fallback_order):
        if field not in mapping and i < len(sample_keys):
            col = sample_keys[i]
            if col not in used_cols:
                mapping[field] = col
                used_cols.add(col)

    print(f"[INFO] Column mapping: {json.dumps(mapping, ensure_ascii=False)}")
    return mapping


# ── Làm sạch dữ liệu (xử lý merged cells) ───────────────────────────────────
def clean_rows(rows: list[dict], col_map: dict) -> list[dict]:
    """
    Google Sheets khi export bị mất giá trị ô merge.
    Dùng "forward-fill" cho cột source và chart.
    Loại bỏ dòng không có cả Redshift lẫn ClickHouse SQL.
    """
    last_source = ""
    last_chart = ""
    cleaned = []

    src_col = col_map.get("source", "")
    chart_col = col_map.get("chart", "")
    rs_col = col_map.get("sql_redshift", "")
    ch_col = col_map.get("sql_clickhouse", "")
    st_col = col_map.get("status", "")

    for row in rows:
        source = row.get(src_col, "").strip()
        chart = row.get(chart_col, "").strip()
        rs_sql = row.get(rs_col, "").strip()
        ch_sql = row.get(ch_col, "").strip()
        status = row.get(st_col, "").strip()

        # Forward-fill merged cells
        if source:
            last_source = source
        else:
            source = last_source

        if chart:
            last_chart = chart
        else:
            chart = last_chart

        # Bỏ dòng nếu không có SQL nào
        if not rs_sql and not ch_sql:
            continue

        cleaned.append({
            "source": source,
            "chart": chart,
            "sql_redshift": rs_sql,
            "sql_clickhouse": ch_sql,
            "status": status,
        })

    print(f"[INFO] Sau khi làm sạch: {len(cleaned)} dòng có SQL")
    return cleaned


# ── Group theo source ─────────────────────────────────────────────────────────
def group_by_source(cleaned: list[dict]) -> dict:
    """Group records: {source_name: [records]}"""
    groups: dict[str, list] = {}
    for rec in cleaned:
        src = rec["source"] or "Uncategorized"
        groups.setdefault(src, []).append(rec)
    return groups


# ── Render markdown ───────────────────────────────────────────────────────────
def render_markdown(groups: dict, total_rows: int) -> str:
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    sheet_url = f"https://docs.google.com/spreadsheets/d/{SHEET_ID}"

    lines = [
        "# SQL Registry — MDLZ Control Tower",
        "",
        "> **Auto-generated** — Không chỉnh sửa tay. Chạy lại script để cập nhật.",
        f">",
        f"> Source: [{SHEET_ID}]({sheet_url}) / sheet `{SHEET_NAME}`  ",
        f"> Last updated: **{now}**  ",
        f"> Total charts với SQL: **{total_rows}**",
        "",
        "---",
        "",
        "## Mục lục",
        "",
    ]

    # TOC
    for i, source in enumerate(groups.keys(), 1):
        anchor = re.sub(r"[^a-z0-9]+", "-", source.lower()).strip("-")
        lines.append(f"{i}. [{source}](#{anchor})")

    lines += ["", "---", ""]

    # Content
    for source, records in groups.items():
        anchor = re.sub(r"[^a-z0-9]+", "-", source.lower()).strip("-")
        lines.append(f"## {source}")
        lines.append("")

        # Deduplicate chart names (có thể có nhiều dòng cùng chart do split SQL)
        seen_charts: dict[str, dict] = {}
        for rec in records:
            chart = rec["chart"]
            if chart not in seen_charts:
                seen_charts[chart] = rec
            else:
                # Merge: nếu dòng sau có SQL mà dòng trước không có
                existing = seen_charts[chart]
                if not existing["sql_redshift"] and rec["sql_redshift"]:
                    existing["sql_redshift"] = rec["sql_redshift"]
                if not existing["sql_clickhouse"] and rec["sql_clickhouse"]:
                    existing["sql_clickhouse"] = rec["sql_clickhouse"]
                if not existing["status"] and rec["status"]:
                    existing["status"] = rec["status"]

        for chart, rec in seen_charts.items():
            status_badge = f" `{rec['status']}`" if rec["status"] else ""
            lines.append(f"### {chart}{status_badge}")
            lines.append("")

            if rec["sql_redshift"]:
                lines.append("**Redshift SQL:**")
                lines.append("")
                lines.append("```sql")
                lines.append(rec["sql_redshift"])
                lines.append("```")
                lines.append("")

            if rec["sql_clickhouse"]:
                lines.append("**ClickHouse SQL:**")
                lines.append("")
                lines.append("```sql")
                lines.append(rec["sql_clickhouse"])
                lines.append("```")
                lines.append("")

            if not rec["sql_redshift"] and not rec["sql_clickhouse"]:
                lines.append("_Chưa có SQL_")
                lines.append("")

        lines.append("---")
        lines.append("")

    return "\n".join(lines)


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    print("=" * 60)
    print("fetch_sql_registry.py — MDLZ Control Tower")
    print("=" * 60)

    validate_env()

    # 1. Kéo dữ liệu từ Google Sheet
    raw_rows = get_sheet_data()
    if not raw_rows:
        print("[WARN] Không có dữ liệu. Dừng.")
        return

    # 2. Detect columns & clean data
    col_map = detect_columns(raw_rows)
    cleaned = clean_rows(raw_rows, col_map)

    # 3. Group & render
    groups = group_by_source(cleaned)
    md_content = render_markdown(groups, len(cleaned))

    # 4. Ghi ra docs
    OUTPUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_MD.write_text(md_content, encoding="utf-8")
    print(f"\n[OK] Đã ghi: {OUTPUT_MD.relative_to(_PROJECT_DIR)}")
    print(f"[OK] {len(groups)} nhóm | {len(cleaned)} charts có SQL")
    print("\nTham chiếu trong prompts:")
    print("  02-data/data-sources/sql-registry.md")


if __name__ == "__main__":
    main()
