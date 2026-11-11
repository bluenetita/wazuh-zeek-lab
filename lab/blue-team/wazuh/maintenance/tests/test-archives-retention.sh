#!/usr/bin/env bash
# Non-destructive regression test; all test data stays under a temporary directory.
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT_DIR/manager/wazuh-archives-retention.sh"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
ROOT="$TMP/archives"
mkdir -p "$ROOT/2026/Nov" "$ROOT/2026/Oct"

# 7 days counted from 2026-11-11: preserve 2026-11-05 through 2026-11-11.
printf 'old compressed content\n' > "$ROOT/2026/Nov/ossec-archive-04.json.gz"
printf 'old json sum\n' > "$ROOT/2026/Nov/ossec-archive-04.json.sum"
printf 'old log sum\n' > "$ROOT/2026/Nov/ossec-archive-04.log.sum"
printf 'cutoff preserved\n' > "$ROOT/2026/Nov/ossec-archive-05.json.gz"
printf 'recent preserved\n' > "$ROOT/2026/Nov/ossec-archive-11.json.gz"
printf 'invalid day preserved\n' > "$ROOT/2026/Nov/ossec-archive-32.json.gz"
printf 'other name preserved\n' > "$ROOT/2026/Nov/random-04.json.gz"
printf 'external\n' > "$TMP/external.txt"
ln -s "$TMP/external.txt" "$ROOT/2026/Oct/ossec-archive-01.json.gz"

run() {
  WAZUH_RETENTION_TEST_MODE=1 \
  WAZUH_RETENTION_TEST_ROOT="$ROOT" \
  WAZUH_RETENTION_TEST_DAYS=7 \
  WAZUH_RETENTION_TEST_TODAY=2026-11-11 \
  bash "$SCRIPT" "$1"
}

DRY="$(run --dry-run)"
grep -q 'Files: 3' <<< "$DRY"
[[ -f "$ROOT/2026/Nov/ossec-archive-04.json.gz" ]]
[[ ! "$DRY" =~ DELETED[[:space:]] ]]
DEL="$(run --delete)"
grep -q 'Files: 3' <<< "$DEL"
[[ ! -e "$ROOT/2026/Nov/ossec-archive-04.json.gz" ]]
[[ ! -e "$ROOT/2026/Nov/ossec-archive-04.json.sum" ]]
[[ ! -e "$ROOT/2026/Nov/ossec-archive-04.log.sum" ]]
[[ -f "$ROOT/2026/Nov/ossec-archive-05.json.gz" ]]
[[ -f "$ROOT/2026/Nov/ossec-archive-11.json.gz" ]]
[[ -f "$ROOT/2026/Nov/ossec-archive-32.json.gz" ]]
[[ -f "$ROOT/2026/Nov/random-04.json.gz" ]]
[[ -f "$TMP/external.txt" ]]
[[ -L "$ROOT/2026/Oct/ossec-archive-01.json.gz" ]]
grep -q 'Files: 0' <<< "$(run --dry-run)"
echo 'PASS: dry-run, cutoff, exact filenames, invalid dates, symlink safety, delete, repeat run'
