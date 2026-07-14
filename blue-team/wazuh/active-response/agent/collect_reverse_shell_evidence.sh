#!/bin/bash

BASE_DIR="/var/ossec/active-response/evidence"
LOG_FILE="/var/ossec/logs/active-responses.log"

HOST="$(hostname)"
TS="$(TZ=Europe/Rome date +%Y-%m-%d_%H-%M-%S_%Z)_$$"
OUT_DIR="$BASE_DIR/reverse_shell_${HOST}_${TS}"

log() {
  echo "$(TZ=Europe/Rome date -Is) collect_reverse_shell_evidence: $1" >> "$LOG_FILE"
}

safe_run() {
  CMD_DESC="$1"
  OUT_FILE="$2"
  shift 2

  log "collecting $CMD_DESC"

  timeout 15 "$@" > "$OUT_FILE" 2>&1
  RET=$?

  if [ "$RET" -eq 124 ]; then
    log "WARNING: $CMD_DESC timed out"
    echo "Command timed out while collecting: $CMD_DESC" >> "$OUT_FILE"
  elif [ "$RET" -ne 0 ]; then
    log "WARNING: $CMD_DESC exited with code $RET"
    echo "Command exited with code $RET while collecting: $CMD_DESC" >> "$OUT_FILE"
  fi
}

read INPUT_JSON

log "received active response input"

if [ -z "$INPUT_JSON" ]; then
  log "empty input received, exiting"
  exit 0
fi

AR_COMMAND="$(echo "$INPUT_JSON" | grep -oP '"command"\s*:\s*"\K[^"]+' | head -n 1)"

if [ -n "$AR_COMMAND" ] && [ "$AR_COMMAND" != "add" ]; then
  log "command=$AR_COMMAND, not add, exiting"
  exit 0
fi

VICTIM_IP="$(echo "$INPUT_JSON" | grep -oP '"victim_ip"\s*:\s*"\K[^"]+' | head -n 1)"

if [ -z "$VICTIM_IP" ]; then
  VICTIM_IP="$(echo "$INPUT_JSON" | grep -oP '"src_ip"\s*:\s*"\K[^"]+' | head -n 1)"
fi

DEST_IP="$(echo "$INPUT_JSON" | grep -oP '"dest_ip"\s*:\s*"\K[^"]+' | head -n 1)"
DEST_PORT="$(echo "$INPUT_JSON" | grep -oP '"dest_port"\s*:\s*"\K[0-9]+' | head -n 1)"
RULE_ID="$(echo "$INPUT_JSON" | grep -oP '"id"\s*:\s*"\K[0-9]+' | head -n 1)"

if [ -z "$VICTIM_IP" ]; then
  log "no victim_ip/src_ip found, exiting"
  exit 0
fi

LOCAL_MATCH="$(ip -o -4 addr show | awk '{print $4}' | cut -d/ -f1 | grep -Fx "$VICTIM_IP")"

if [ -z "$LOCAL_MATCH" ]; then
  log "victim_ip=$VICTIM_IP does not match this host, exiting"
  exit 0
fi

mkdir -p "$OUT_DIR"

if [ ! -d "$OUT_DIR" ]; then
  log "ERROR: failed to create evidence directory $OUT_DIR"
  exit 1
fi

log "MATCH victim_ip=$VICTIM_IP dest_ip=$DEST_IP dest_port=$DEST_PORT rule_id=$RULE_ID collecting evidence"
log "evidence directory created: $OUT_DIR"

{
  echo "Evidence collection report"
  echo "=========================="
  echo ""
  echo "Timestamp Europe/Rome: $(TZ=Europe/Rome date -Is)"
  echo "Timestamp UTC: $(date -u -Is)"
  echo "Hostname: $(hostname)"
  echo "Kernel: $(uname -a)"
  echo "Current user: $(whoami)"
  echo ""
  echo "Matched alert fields"
  echo "--------------------"
  echo "Rule ID: $RULE_ID"
  echo "Victim IP: $VICTIM_IP"
  echo "Destination IP: $DEST_IP"
  echo "Destination port: $DEST_PORT"
  echo ""
  echo "Evidence directory:"
  echo "$OUT_DIR"
} > "$OUT_DIR/system_info.txt" 2>&1

echo "$INPUT_JSON" > "$OUT_DIR/wazuh_alert.json"

safe_run "ip addresses" "$OUT_DIR/ip_addr.txt" ip addr show
safe_run "ip routes" "$OUT_DIR/ip_route.txt" ip route show
safe_run "process tree" "$OUT_DIR/process_tree.txt" ps auxf
safe_run "network connections with ss" "$OUT_DIR/network_connections_ss.txt" ss -tunap
safe_run "network connections with lsof" "$OUT_DIR/network_connections_lsof.txt" lsof -i -P -n
safe_run "logged users" "$OUT_DIR/logged_users.txt" who

log "collecting recent logins"

timeout 10 bash -c 'last -a | head -n 50' > "$OUT_DIR/recent_logins.txt" 2>&1
RET=$?

if [ "$RET" -eq 124 ]; then
  log "WARNING: recent logins collection timed out"
elif [ "$RET" -ne 0 ]; then
  log "WARNING: recent logins collection exited with code $RET"
fi

log "collecting audit tail"

if [ -f /var/log/audit/audit.log ]; then
  timeout 10 tail -n 1000 /var/log/audit/audit.log > "$OUT_DIR/audit_tail.log" 2>&1
  RET=$?

  if [ "$RET" -eq 124 ]; then
    log "WARNING: audit tail collection timed out"
  elif [ "$RET" -ne 0 ]; then
    log "WARNING: audit tail collection exited with code $RET"
  fi
else
  echo "Audit log not found: /var/log/audit/audit.log" > "$OUT_DIR/audit_tail.log"
  log "audit log not found"
fi

log "collecting recent rs_connect audit events"

if command -v ausearch >/dev/null 2>&1; then
  timeout 15 ausearch -k rs_connect --start recent -i > "$OUT_DIR/audit_rs_connect_recent.log" 2>&1
  RET=$?

  if [ "$RET" -eq 124 ]; then
    log "WARNING: ausearch rs_connect timed out"
  elif [ "$RET" -ne 0 ]; then
    log "WARNING: ausearch rs_connect exited with code $RET"
  fi
else
  echo "ausearch command not found" > "$OUT_DIR/audit_rs_connect_recent.log"
  log "ausearch command not found"
fi

log "collecting journal"

timeout 10 journalctl -n 300 --no-pager > "$OUT_DIR/journal_tail.log" 2>&1
RET=$?

if [ "$RET" -eq 124 ]; then
  log "WARNING: journal collection timed out"
elif [ "$RET" -ne 0 ]; then
  log "WARNING: journal collection exited with code $RET"
fi

{
  echo "Collection completed"
  echo "Completed at Europe/Rome: $(TZ=Europe/Rome date -Is)"
  echo "Completed at UTC: $(date -u -Is)"
  echo "Evidence directory: $OUT_DIR"
} > "$OUT_DIR/collection_status.txt" 2>&1

log "evidence saved in directory $OUT_DIR"
log "collection completed successfully"

exit 0