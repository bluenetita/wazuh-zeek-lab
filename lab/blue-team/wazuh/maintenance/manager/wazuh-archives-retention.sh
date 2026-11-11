#!/usr/bin/env bash
# Retain a configurable number of UTC calendar days of rotated Wazuh archives.
# Default action is dry-run. Use --delete ONLY after review and backup.
set -euo pipefail
export LC_ALL=C
export TZ=UTC

MODE="${1:---dry-run}"
case "$MODE" in
  --dry-run|--delete) ;;
  *) echo "Usage: $0 [--dry-run|--delete]" >&2; exit 2 ;;
esac
if (( $# > 1 )); then
  echo "Unexpected arguments" >&2
  exit 2
fi

ROOT="/var/ossec/logs/archives"
KEEP_DAYS=7

# This isolated test override is not used by cron or the installer.
if [[ "${WAZUH_RETENTION_TEST_MODE:-0}" == "1" ]]; then
  ROOT="${WAZUH_RETENTION_TEST_ROOT:?missing test root}"
  KEEP_DAYS="${WAZUH_RETENTION_TEST_DAYS:-7}"
  TODAY="${WAZUH_RETENTION_TEST_TODAY:-$(date -u +%F)}"
else
  if (( EUID != 0 )); then
    echo "Error: must be run as root" >&2
    exit 1
  fi
  CONF="/etc/wazuh-archives-retention.conf"
  if [[ ! -f "$CONF" || -L "$CONF" ]]; then
    echo "Error: missing or unsafe config $CONF" >&2
    exit 1
  fi
  # This file must be root-owned and writable only by root.
  owner=$(stat -c '%u' -- "$CONF")
  perms=$(stat -c '%a' -- "$CONF")
  if [[ "$owner" != "0" || "$(( 8#$perms & 0022 ))" -ne 0 ]]; then
    echo "Error: unsafe ownership or permissions on $CONF" >&2
    exit 1
  fi
  # shellcheck source=/dev/null
  source "$CONF"
  TODAY="$(date -u +%F)"
fi

if [[ ! "$KEEP_DAYS" =~ ^[1-9][0-9]{0,3}$ ]] || (( 10#$KEEP_DAYS > 3650 )); then
  echo "Error: KEEP_DAYS must be an integer between 1 and 3650" >&2
  exit 1
fi
if [[ ! "$ROOT" = /* || ! -d "$ROOT" || -L "$ROOT" ]]; then
  echo "Error: unsafe or missing archive directory" >&2
  exit 1
fi
if [[ ! "$TODAY" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Error: invalid reference date" >&2
  exit 1
fi
TODAY_EPOCH=$(date -u -d "$TODAY" +%s) || exit 1
if [[ "$(date -u -d "@$TODAY_EPOCH" +%F)" != "$TODAY" ]]; then
  echo "Error: invalid reference date" >&2
  exit 1
fi
CUTOFF_EPOCH=$(( TODAY_EPOCH - (10#$KEEP_DAYS - 1) * 86400 ))
CUTOFF="$(date -u -d "@$CUTOFF_EPOCH" +%F)"

count=0
bytes=0
# Materialize the file list first so a failed find cannot be mistaken for success.
tmp_list="$(mktemp)"
trap 'rm -f -- "$tmp_list"' EXIT
# -P means symlinks are never traversed by find.
find -P "$ROOT" -mindepth 3 -maxdepth 3 -type f \
  \( -name 'ossec-archive-*.json.gz' -o -name 'ossec-archive-*.json.sum' \
     -o -name 'ossec-archive-*.log.gz' -o -name 'ossec-archive-*.log.sum' \) \
  -print0 > "$tmp_list"
while IFS= read -r -d '' file; do
  rel="${file#"$ROOT"/}"
  if [[ ! "$rel" =~ ^([0-9]{4})/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/ossec-archive-([0-9]{2})\.(json|log)\.(gz|sum)$ ]]; then
    continue
  fi
  year="${BASH_REMATCH[1]}"
  month="${BASH_REMATCH[2]}"
  day="${BASH_REMATCH[3]}"
  case "$month" in
    Jan) month_num=01;; Feb) month_num=02;; Mar) month_num=03;;
    Apr) month_num=04;; May) month_num=05;; Jun) month_num=06;;
    Jul) month_num=07;; Aug) month_num=08;; Sep) month_num=09;;
    Oct) month_num=10;; Nov) month_num=11;; Dec) month_num=12;;
  esac
  file_date="$year-$month_num-$day"
  # Validate calendar dates strictly: no invalid or normalized dates.
  date -u -d "$file_date" +%F >/dev/null 2>&1 || continue
  [[ "$(date -u -d "$file_date" +%F)" == "$file_date" ]] || continue
  [[ "$file_date" < "$CUTOFF" ]] || continue
  # Do not touch files replaced with symlinks between discovery and processing.
  [[ -f "$file" && ! -L "$file" ]] || continue
  size=$(stat -c '%s' -- "$file") || exit 1
  if [[ "$MODE" == "--delete" ]]; then
    rm -- "$file"
    action="DELETED"
  else
    action="WOULD_DELETE"
  fi
  printf '%s | %s | %s | %s bytes\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$action" "$file" "$size"
  count=$((count + 1))
  bytes=$((bytes + size))
done < "$tmp_list"

printf 'Mode: %s\nRetention: %s calendar days (UTC)\nKeep from: %s\nFiles: %d\nBytes: %d\n' \
  "$MODE" "$KEEP_DAYS" "$CUTOFF" "$count" "$bytes"
