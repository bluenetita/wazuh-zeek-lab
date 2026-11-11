#!/usr/bin/env bash
# Install local archive retention. Cron remains disabled unless --enable-cron is passed.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: sudo bash install-archives-retention.sh --days N [--enable-cron]
  --days N      Retention in UTC calendar days (1..3650, required)
  --enable-cron Install the daily 04:15 cron schedule (DELETES expired archives)

Always run a dry-run and review it before enabling cron.
Previous local configs are backed up under /var/backups/wazuh-archives-retention/.
USAGE
}

DAYS=""
ENABLE_CRON=0
while (( $# )); do
  case "$1" in
    --days)
      (( $# >= 2 )) || { usage >&2; exit 2; }
      DAYS="$2"; shift 2;;
    --enable-cron)
      ENABLE_CRON=1; shift;;
    -h|--help)
      usage; exit 0;;
    *) usage >&2; exit 2;;
  esac
done
if (( EUID != 0 )); then
  echo "Run as root (sudo)." >&2
  exit 1
fi
if [[ ! "$DAYS" =~ ^[1-9][0-9]{0,3}$ ]] || (( 10#$DAYS > 3650 )); then
  echo "--days must be an integer between 1 and 3650" >&2
  exit 2
fi

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$DIR/manager/wazuh-archives-retention.sh"
CONF_EXAMPLE="$DIR/manager/wazuh-archives-retention.conf.example"
CRON="$DIR/manager/wazuh-archives-retention.cron"
LOGROTATE="$DIR/manager/wazuh-archives-retention.logrotate"

[[ -d /var/ossec/logs/archives ]] || { echo "Not a Wazuh manager archive host" >&2; exit 1; }
[[ -f "$CONF_EXAMPLE" && -f "$CRON" && -f "$LOGROTATE" ]] || { echo "Incomplete repository package" >&2; exit 1; }
bash -n "$SCRIPT"
command -v flock >/dev/null || { echo "flock not installed" >&2; exit 1; }

BACKUP="/var/backups/wazuh-archives-retention/$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p -m 0700 -- "$BACKUP"
backup_if_exists() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    [[ ! -L "$target" ]] || { echo "Refusing symlink: $target" >&2; exit 1; }
    cp -a -- "$target" "$BACKUP/$(basename -- "$target")"
  fi
}

backup_if_exists /usr/local/sbin/wazuh-archives-retention.sh
backup_if_exists /etc/wazuh-archives-retention.conf
backup_if_exists /etc/logrotate.d/wazuh-archives-retention
if (( ENABLE_CRON )); then
  backup_if_exists /etc/cron.d/wazuh-archives-retention
fi

install -o root -g root -m 0750 "$SCRIPT" /usr/local/sbin/wazuh-archives-retention.sh
printf 'KEEP_DAYS=%s\n' "$DAYS" > /etc/wazuh-archives-retention.conf
chown root:root /etc/wazuh-archives-retention.conf
chmod 0600 /etc/wazuh-archives-retention.conf
install -o root -g root -m 0644 "$LOGROTATE" /etc/logrotate.d/wazuh-archives-retention
LOG_FILE="/var/log/wazuh-archives-retention.log"
if [[ -L "$LOG_FILE" ]]; then
  echo "Refusing symlink: $LOG_FILE" >&2
  exit 1
fi
if [[ ! -e "$LOG_FILE" ]]; then
  install -o root -g root -m 0640 /dev/null "$LOG_FILE"
fi
chown root:root "$LOG_FILE"
chmod 0640 "$LOG_FILE"

printf 'Installed retention script (days=%s) and logrotate.\nBackups: %s\n' "$DAYS" "$BACKUP"
if (( ENABLE_CRON )); then
  install -o root -g root -m 0644 "$CRON" /etc/cron.d/wazuh-archives-retention
  echo "ENABLED: daily 04:15 CRON deletion of archives older than retention."
else
  echo "Cron not enabled by this run."
  if [[ -f /etc/cron.d/wazuh-archives-retention ]]; then
    echo "WARNING: A previously installed cron job already exists and may be active."
  fi
fi
echo "Verify: sudo /usr/local/sbin/wazuh-archives-retention.sh --dry-run"
