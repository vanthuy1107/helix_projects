"""
Export DDL của tất cả Materialized Views trong analytics_workspace (ClickHouse).

Mục đích:
  - Cung cấp nguồn DDL chuẩn cho clickhouse-migration.prompt và clickhouse-skill-guide.prompt
  - Dùng để debug data pipeline, trace data lineage
  - Cập nhật định kỳ khi MV thay đổi trên server

Credentials đọc từ .env (CLICKHOUSE_HOST, CLICKHOUSE_PORT, CLICKHOUSE_USER, CLICKHOUSE_PASSWORD, CLICKHOUSE_SECURE)
fallback: biến môi trường hệ thống

Output:
  02-data/data-sources/clickhouse-ddl/analytics_workspace_mvs.md   ← Markdown + metadata
  02-data/data-sources/clickhouse-ddl/analytics_workspace_mvs.sql  ← Raw SQL DDL (copy-paste ready)

Usage:
  python scripts/meta/export_clickhouse_ddl.py
  python scripts/meta/export_clickhouse_ddl.py --database analytics_workspace
  python scripts/meta/export_clickhouse_ddl.py --engine MaterializedView,View
  python scripts/meta/export_clickhouse_ddl.py --table mv_alert_late_do    # single table
"""
from __future__ import annotations

import argparse
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

_SCRIPT_DIR = Path(__file__).resolve().parent
_PROJECT_DIR = next(p for p in Path(__file__).resolve().parents
                    if (p / "da.toml").exists())  # tenant root = nơi có da.toml (relocation-proof)
_OUTPUT_DIR = _PROJECT_DIR / "02-data" / "data-sources" / "clickhouse-ddl"

# Load .env từ repo root
try:
    from dotenv import load_dotenv
    _env_file = _PROJECT_DIR / ".env"
    if _env_file.exists():
        load_dotenv(_env_file)
    else:
        load_dotenv()
except ImportError:
    pass  # dotenv optional — dùng env vars hệ thống

try:
    import clickhouse_connect
except ImportError:
    print("ERROR: clickhouse-connect chưa được cài. Chạy: pip install clickhouse-connect", file=sys.stderr)
    sys.exit(1)


# ──────────────────────────────────────────────
# Config
# ──────────────────────────────────────────────
DEFAULT_DATABASE = "analytics_workspace"
DEFAULT_ENGINES = ("MaterializedView", "View", "SharedMergeTree")


def _get_client() -> clickhouse_connect.driver.Client:
    host = os.getenv("CLICKHOUSE_HOST", "")
    port = int(os.getenv("CLICKHOUSE_PORT", "8443"))
    user = os.getenv("CLICKHOUSE_USER", "")
    password = os.getenv("CLICKHOUSE_PASSWORD", "")
    secure_raw = os.getenv("CLICKHOUSE_SECURE", "true").lower()
    secure = secure_raw not in ("false", "0", "no")

    if not host or not user:
        print("ERROR: CLICKHOUSE_HOST và CLICKHOUSE_USER phải được set trong .env", file=sys.stderr)
        sys.exit(1)

    return clickhouse_connect.get_client(
        host=host,
        port=port,
        username=user,
        password=password,
        secure=secure,
        connect_timeout=30,
    )


def _list_objects(client, database: str, engines: tuple[str, ...], table_filter: str | None,
                   include_inner: bool = False) -> list[dict]:
    """Lấy danh sách tables/views trong database, filter theo engine.
    Mặc định bỏ qua backing tables .inner_id.* (internal ClickHouse MV storage).
    """
    engine_list = ", ".join(f"'{e}'" for e in engines)
    sql = f"""
        SELECT
            name,
            engine,
            total_rows,
            formatReadableSize(total_bytes) AS size,
            comment
        FROM system.tables
        WHERE database = '{database}'
          AND engine IN ({engine_list})
        ORDER BY name
    """
    result = client.query(sql)
    rows = []
    for row in result.named_results():
        if not include_inner and row["name"].startswith(".inner_id."):
            continue
        if table_filter and row["name"] != table_filter:
            continue
        rows.append(row)
    return rows


def _get_ddl(client, database: str, name: str) -> str:
    result = client.query(f"SHOW CREATE TABLE `{database}`.`{name}`")
    return result.first_row[0]


def _build_markdown(database: str, objects: list[dict], ddls: dict[str, str], generated_at: str) -> str:
    lines: list[str] = []

    lines.append(f"# ClickHouse DDL Snapshot — `{database}`")
    lines.append("")
    lines.append(f"> **Generated:** {generated_at}  ")
    lines.append(f"> **Database:** `{database}`  ")
    lines.append(f"> **Total objects:** {len(objects)}")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## Danh sách Objects")
    lines.append("")
    lines.append("| # | Name | Engine | Rows | Size | Comment |")
    lines.append("|---|------|--------|------|------|---------|")
    for i, obj in enumerate(objects, 1):
        rows = obj.get("total_rows") or "—"
        size = obj.get("size") or "—"
        comment = (obj.get("comment") or "").replace("|", "\\|")
        lines.append(f"| {i} | `{obj['name']}` | {obj['engine']} | {rows} | {size} | {comment} |")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## DDL Chi tiết")
    lines.append("")

    for obj in objects:
        name = obj["name"]
        ddl = ddls.get(name, "-- DDL not available")
        lines.append(f"### `{name}`")
        lines.append("")
        if obj.get("comment"):
            lines.append(f"> {obj['comment']}")
            lines.append("")
        lines.append(f"**Engine:** `{obj['engine']}`")
        lines.append("")
        lines.append("```sql")
        lines.append(ddl)
        lines.append("```")
        lines.append("")
        lines.append("---")
        lines.append("")

    return "\n".join(lines)


def _build_sql(database: str, objects: list[dict], ddls: dict[str, str], generated_at: str) -> str:
    lines: list[str] = []
    lines.append(f"-- ClickHouse DDL Snapshot: {database}")
    lines.append(f"-- Generated: {generated_at}")
    lines.append(f"-- Total: {len(objects)} objects")
    lines.append("-- " + "─" * 60)
    lines.append("")
    for obj in objects:
        name = obj["name"]
        ddl = ddls.get(name, "-- DDL not available")
        lines.append(f"-- ════════════════════════════════════════════════════")
        lines.append(f"-- Object: {name}  (engine: {obj['engine']})")
        lines.append(f"-- ════════════════════════════════════════════════════")
        lines.append("")
        lines.append(ddl)
        lines.append("")
        lines.append("")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Export ClickHouse DDL snapshot")
    parser.add_argument("--database", default=DEFAULT_DATABASE, help=f"ClickHouse database (default: {DEFAULT_DATABASE})")
    parser.add_argument("--engine", default=",".join(DEFAULT_ENGINES),
                        help="Comma-separated engine types (default: MaterializedView,View,SharedMergeTree)")
    parser.add_argument("--table", default=None, help="Export single table/view only")
    parser.add_argument("--include-inner", action="store_true",
                        help="Bao gồm cả backing tables .inner_id.* (mặc định: bỏ qua)")
    parser.add_argument("--output-dir", default=str(_OUTPUT_DIR),
                        help="Output directory (default: docs/03-engineering/data-sources/clickhouse-ddl/)")
    args = parser.parse_args()

    engines = tuple(e.strip() for e in args.engine.split(","))
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"[1/4] Kết nối ClickHouse ({os.getenv('CLICKHOUSE_HOST', '?')})...")
    client = _get_client()
    print("      ✓ Connected")

    print(f"[2/4] Liệt kê objects trong `{args.database}` (engines: {engines})...")
    objects = _list_objects(client, args.database, engines, args.table, include_inner=args.include_inner)
    if not objects:
        print(f"      ⚠ Không tìm thấy object nào trong {args.database} với engine={engines}")
        return
    print(f"      ✓ Tìm thấy {len(objects)} objects: {', '.join(o['name'] for o in objects)}")

    print("[3/4] Export DDL từng object...")
    ddls: dict[str, str] = {}
    errors: list[str] = []
    for i, obj in enumerate(objects, 1):
        name = obj["name"]
        try:
            ddl = _get_ddl(client, args.database, name)
            ddls[name] = ddl
            print(f"      [{i:02d}/{len(objects):02d}] ✓ {name}")
        except Exception as exc:
            ddls[name] = f"-- ERROR fetching DDL: {exc}"
            errors.append(name)
            print(f"      [{i:02d}/{len(objects):02d}] ✗ {name}: {exc}")

    generated_at = datetime.now(tz=timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    db_slug = args.database.replace("_", "-")

    # Ghi Markdown
    md_path = output_dir / f"{db_slug}_mvs.md"
    md_content = _build_markdown(args.database, objects, ddls, generated_at)
    md_path.write_text(md_content, encoding="utf-8")

    # Ghi SQL
    sql_path = output_dir / f"{db_slug}_mvs.sql"
    sql_content = _build_sql(args.database, objects, ddls, generated_at)
    sql_path.write_text(sql_content, encoding="utf-8")

    print(f"\n[4/4] Đã lưu:")
    print(f"      📄 {md_path.relative_to(_PROJECT_DIR)}")
    print(f"      📄 {sql_path.relative_to(_PROJECT_DIR)}")
    if errors:
        print(f"\n  ⚠  {len(errors)} object(s) lỗi khi lấy DDL: {', '.join(errors)}")
    else:
        print(f"\n  ✓  Export hoàn tất. {len(objects)} objects, 0 errors.")


if __name__ == "__main__":
    main()
