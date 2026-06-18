#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Export a MySQL/MariaDB SELECT from a Namecheap hosting account over SSH to CSV.

Required environment variables:
  SSH_USER      cPanel / Namecheap SSH username
  SSH_HOST      SSH hostname, usually server hostname or your domain
  DB_USER       MySQL database user
  DB_NAME       MySQL database name

Optional environment variables:
  SSH_PORT      SSH port, default: 21098 for many Namecheap shared hosting accounts
  DB_HOST       MySQL host, default: localhost
  DB_PORT       MySQL port, default: 3306
  DB_PASS       MySQL password; if omitted, script prompts securely
  SSH_KEY       Path to SSH private key; if omitted, default SSH auth is used

Usage:
  ./export_namecheap_db.sh query.sql output.csv

Example:
  export SSH_USER='cpanel_user'
  export SSH_HOST='server123.web-hosting.com'
  export DB_USER='cpanel_dbuser'
  export DB_NAME='cpanel_database'
  ./export_namecheap_db.sh queries/customer_export.sql exports/customer_export.csv

Notes:
  - The query file should contain a SELECT statement only.
  - The script runs mysql on the hosting server through SSH, captures tab-separated output,
    then converts it locally to RFC4180-style CSV using Python's csv module.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 2 ]]; then
  usage >&2
  exit 2
fi

QUERY_FILE="$1"
OUTPUT_CSV="$2"

: "${SSH_USER:?Set SSH_USER}"
: "${SSH_HOST:?Set SSH_HOST}"
: "${DB_USER:?Set DB_USER}"
: "${DB_NAME:?Set DB_NAME}"

SSH_PORT="${SSH_PORT:-21098}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"

if [[ ! -f "$QUERY_FILE" ]]; then
  echo "Query file not found: $QUERY_FILE" >&2
  exit 2
fi

# Basic guardrail: this export process is intended for SELECT statements.
first_word=$(tr -d '\r' < "$QUERY_FILE" | sed -e 's/^--.*$//' -e 's:/\*.*\*/::g' | awk 'NF {print toupper($1); exit}')
if [[ "$first_word" != "SELECT" && "$first_word" != "WITH" ]]; then
  echo "Refusing to run non-SELECT query. First SQL keyword was: ${first_word:-<empty>}" >&2
  echo "Put only a SELECT or WITH ... SELECT statement in $QUERY_FILE." >&2
  exit 2
fi

if [[ -z "${DB_PASS:-}" ]]; then
  read -r -s -p "MySQL password for $DB_USER: " DB_PASS
  echo
fi

mkdir -p "$(dirname "$OUTPUT_CSV")"
TMP_TSV="$(mktemp)"
cleanup() { rm -f "$TMP_TSV"; }
trap cleanup EXIT

quote() { printf '%q' "$1"; }

REMOTE_CMD="MYSQL_PWD=$(quote "$DB_PASS") mysql --host=$(quote "$DB_HOST") --port=$(quote "$DB_PORT") --user=$(quote "$DB_USER") --database=$(quote "$DB_NAME") --default-character-set=utf8mb4 --batch --raw --column-names"

SSH_ARGS=(-p "$SSH_PORT" -o ServerAliveInterval=30 -o ServerAliveCountMax=3)
if [[ -n "${SSH_KEY:-}" ]]; then
  SSH_ARGS+=(-i "$SSH_KEY")
fi

echo "Running query on $SSH_USER@$SSH_HOST:$SSH_PORT / database $DB_NAME ..." >&2
ssh "${SSH_ARGS[@]}" "$SSH_USER@$SSH_HOST" "$REMOTE_CMD" < "$QUERY_FILE" > "$TMP_TSV"

python - "$TMP_TSV" "$OUTPUT_CSV" <<'PY'
import csv
import pathlib
import sys

tsv_path = pathlib.Path(sys.argv[1])
csv_path = pathlib.Path(sys.argv[2])

with tsv_path.open('r', encoding='utf-8', newline='') as src, csv_path.open('w', encoding='utf-8', newline='') as dst:
    reader = csv.reader(src, delimiter='\t')
    writer = csv.writer(dst)
    rows = 0
    for row in reader:
        writer.writerow(row)
        rows += 1

print(f"Wrote {rows} CSV rows, including header, to {csv_path}", file=sys.stderr)
PY

echo "Done: $OUTPUT_CSV" >&2
