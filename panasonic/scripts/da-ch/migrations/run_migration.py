"""
Run a .ch.sql migration file statement-by-statement (CH HTTP API doesn't accept multi-statement bodies).

Usage:
  # dry run — print each statement, don't execute
  python run_migration.py M01_add_descriptions.ch.sql --dry-run

  # actually execute
  python run_migration.py M01_add_descriptions.ch.sql

  # execute first N statements (smoke test)
  python run_migration.py M01_add_descriptions.ch.sql --limit 5

Credentials: đọc projects/panasonic/.env trước, fallback projects/mondelez/.env
"""
from __future__ import annotations

import argparse
import base64
import os
import re
import sys
import time
from pathlib import Path
from urllib import request, parse, error

_SCRIPT_DIR = Path(__file__).resolve().parent
_PROJECT_DIR = _SCRIPT_DIR.parent.parent.parent  # projects/panasonic/

def load_env() -> None:
    candidates = [
        _PROJECT_DIR / ".env",
        _PROJECT_DIR.parent / "mondelez" / ".env",
    ]
    for env_file in candidates:
        if not env_file.exists():
            continue
        with open(env_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.rstrip("\r\n").strip()
                if not line or line.startswith("#"):
                    continue
                m = re.match(r"^(CLICKHOUSE_[A-Z_]+)\s*=\s*(.*)$", line)
                if m:
                    key, val = m.group(1), m.group(2).strip().strip('"').strip("'")
                    os.environ.setdefault(key, val)
        if os.environ.get("CLICKHOUSE_PASSWORD"):
            print(f"[env] Loaded from {env_file}")
            return
    sys.exit("ERROR: CLICKHOUSE_* env vars chưa được set")


def split_statements(sql_text: str) -> list[str]:
    """Strip comments + split on ';' boundaries."""
    # Remove single-line comments
    cleaned_lines = []
    for line in sql_text.splitlines():
        # naive: strip everything after '--' on a line
        idx = line.find("--")
        if idx >= 0:
            line = line[:idx]
        cleaned_lines.append(line)
    cleaned = "\n".join(cleaned_lines)
    # Split on ';' boundary
    raw = [s.strip() for s in cleaned.split(";")]
    return [s for s in raw if s]


def execute(sql: str, timeout: int = 30) -> tuple[bool, str]:
    host = os.environ["CLICKHOUSE_HOST"]
    port = os.environ.get("CLICKHOUSE_PORT", "8443")
    user = os.environ["CLICKHOUSE_USER"]
    password = os.environ["CLICKHOUSE_PASSWORD"]
    secure = os.environ.get("CLICKHOUSE_SECURE", "true").lower() != "false"

    scheme = "https" if secure else "http"
    qs = parse.urlencode({"max_execution_time": str(timeout)})
    url = f"{scheme}://{host}:{port}/?{qs}"

    auth = base64.b64encode(f"{user}:{password}".encode()).decode()
    req = request.Request(
        url,
        data=sql.encode("utf-8"),
        headers={
            "Authorization": f"Basic {auth}",
            "Content-Type": "text/plain; charset=utf-8",
        },
        method="POST",
    )
    try:
        with request.urlopen(req, timeout=timeout + 10) as resp:
            return True, resp.read().decode("utf-8")
    except error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        return False, f"HTTP {e.code}: {body.strip()}"
    except Exception as e:
        return False, f"Error: {e}"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("migration_file", type=Path)
    parser.add_argument("--dry-run", action="store_true", help="Print each statement, don't execute")
    parser.add_argument("--limit", type=int, default=0, help="Execute only first N statements (smoke test)")
    parser.add_argument("--continue-on-error", action="store_true", help="Don't stop if a statement fails")
    args = parser.parse_args()

    if not args.migration_file.exists():
        # Try resolving relative to script dir
        alt = _SCRIPT_DIR / args.migration_file
        if alt.exists():
            args.migration_file = alt
        else:
            sys.exit(f"ERROR: file not found: {args.migration_file}")

    load_env()
    sql_text = args.migration_file.read_text(encoding="utf-8")
    statements = split_statements(sql_text)
    total = len(statements)
    print(f"[plan] {total} statements in {args.migration_file.name}")

    if args.limit > 0:
        statements = statements[: args.limit]
        print(f"[plan] limited to first {args.limit}")

    if args.dry_run:
        for i, stmt in enumerate(statements, 1):
            preview = " ".join(stmt.split())[:120]
            print(f"  [{i:3d}/{total}] {preview}")
        print("\n[dry-run] no statements executed.")
        return

    ok_count = 0
    fail_count = 0
    failures: list[tuple[int, str, str]] = []
    t_start = time.time()
    for i, stmt in enumerate(statements, 1):
        preview = " ".join(stmt.split())[:100]
        success, body = execute(stmt)
        if success:
            ok_count += 1
            print(f"  ✓ [{i:3d}/{total}] {preview}")
        else:
            fail_count += 1
            failures.append((i, preview, body))
            print(f"  ✗ [{i:3d}/{total}] {preview}")
            print(f"      → {body[:300]}")
            if not args.continue_on_error:
                print("\n[STOP] Halting on first error. Pass --continue-on-error to ignore.")
                break

    elapsed = time.time() - t_start
    print(f"\n[done] {ok_count} OK, {fail_count} FAILED in {elapsed:.1f}s")
    if failures:
        print("\n[failures]")
        for i, preview, body in failures:
            print(f"  #{i}: {preview}")
            print(f"      {body[:200]}")


if __name__ == "__main__":
    main()
