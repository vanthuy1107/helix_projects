#!/usr/bin/env bash
# Chạy SQL script .sql trên ClickHouse Cloud cho dự án Panasonic.
#
# Đọc credential từ projects/panasonic/.env (ưu tiên) hoặc projects/mondelez/.env (fallback).
#
# Usage:
#   ./run.sh core/C00_profile-psv.ch.sql
#   ./run.sh core/C01_psv-summary.ch.sql --format CSVWithNames --out out/summary.csv
#   echo "SELECT count() FROM psv_target FINAL" | ./run.sh --format JSONEachRow
#
# Flags:
#   --format <fmt>    Output format (default: PrettyCompactMonoBlock)
#   --db <database>   Default database (default: analytics_workspace)
#   --out <file>      Write to file thay vì stdout
#   --timeout <sec>   max_execution_time (default: 120)
#   --max-rows <n>    max_result_rows (default: 100000)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ─── Load .env ─────────────────────────────────────────────────────
# Chỉ load các key CLICKHOUSE_* — bỏ qua các key khác (vd: GOOGLE_*) để
# tránh lỗi shell parse khi path chứa ký tự đặc biệt.
load_clickhouse_env() {
    local f="$1"
    [[ -f "$f" ]] || return 1
    while IFS= read -r line; do
        # skip comments/blanks
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        # match CLICKHOUSE_XXX=YYY
        if [[ "$line" =~ ^[[:space:]]*(CLICKHOUSE_[A-Z_]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local val="${BASH_REMATCH[2]}"
            # strip trailing CR (Windows CRLF .env files)
            val="${val%$'\r'}"
            # strip optional surrounding quotes
            val="${val%\"}"; val="${val#\"}"
            val="${val%\'}"; val="${val#\'}"
            export "$key=$val"
        fi
    done < "$f"
    return 0
}

ENV_PANASONIC="$PROJECT_DIR/.env"
ENV_MONDELEZ="$PROJECT_DIR/../mondelez/.env"

if load_clickhouse_env "$ENV_PANASONIC" && [[ -n "${CLICKHOUSE_PASSWORD:-}" ]]; then
    :  # loaded from panasonic
elif load_clickhouse_env "$ENV_MONDELEZ"; then
    :  # loaded from mondelez
else
    echo "ERROR: không tìm thấy .env có CLICKHOUSE_* keys (đã thử $ENV_PANASONIC và $ENV_MONDELEZ)" >&2
    exit 1
fi

: "${CLICKHOUSE_HOST:?CLICKHOUSE_HOST chưa được set}"
: "${CLICKHOUSE_USER:?CLICKHOUSE_USER chưa được set}"
: "${CLICKHOUSE_PASSWORD:?CLICKHOUSE_PASSWORD chưa được set}"

# ─── Parse args ────────────────────────────────────────────────────
FORMAT="PrettyCompactMonoBlock"
DATABASE="analytics_workspace"
OUT=""
TIMEOUT=120
MAX_ROWS=100000
FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --format)   FORMAT="$2"; shift 2 ;;
        --db)       DATABASE="$2"; shift 2 ;;
        --out)      OUT="$2"; shift 2 ;;
        --timeout)  TIMEOUT="$2"; shift 2 ;;
        --max-rows) MAX_ROWS="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,18p' "$0" | sed 's/^# //'
            exit 0 ;;
        -*) echo "Unknown flag: $1" >&2; exit 1 ;;
        *)  FILE="$1"; shift ;;
    esac
done

# ─── Read SQL ──────────────────────────────────────────────────────
if [[ -n "$FILE" ]]; then
    [[ -f "$FILE" ]] || { echo "File not found: $FILE" >&2; exit 1; }
    SQL_BODY="@$FILE"
elif [[ ! -t 0 ]]; then
    # stdin pipe
    SQL_BODY="@-"
else
    echo "Cần truyền <file.sql> hoặc pipe SQL string. (-h để xem help)" >&2
    exit 1
fi

# ─── Build URL ─────────────────────────────────────────────────────
PORT="${CLICKHOUSE_PORT:-8443}"
SCHEME="https"
if [[ "${CLICKHOUSE_SECURE:-true}" == "false" ]]; then SCHEME="http"; fi

URL="$SCHEME://$CLICKHOUSE_HOST:$PORT/?database=$DATABASE&default_format=$FORMAT&max_execution_time=$TIMEOUT&max_result_rows=$MAX_ROWS"

# ─── Run ───────────────────────────────────────────────────────────
START=$(date +%s%N)
if [[ -n "$OUT" ]]; then
    mkdir -p "$(dirname "$OUT")"
    curl --silent --show-error --fail-with-body \
         --user "$CLICKHOUSE_USER:$CLICKHOUSE_PASSWORD" \
         "$URL" --data-binary "$SQL_BODY" > "$OUT"
    END=$(date +%s%N)
    ELAPSED_MS=$(( (END - START) / 1000000 ))
    echo "  ✓ Saved → $OUT  (${ELAPSED_MS}ms)" >&2
else
    curl --silent --show-error --fail-with-body \
         --user "$CLICKHOUSE_USER:$CLICKHOUSE_PASSWORD" \
         "$URL" --data-binary "$SQL_BODY"
    END=$(date +%s%N)
    ELAPSED_MS=$(( (END - START) / 1000000 ))
    echo "" >&2
    echo "  ⏱  ${ELAPSED_MS}ms" >&2
fi
