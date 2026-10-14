#!/usr/bin/env bash
# Zeek v1.5 offline regression. Reads PCAPs, writes only into a fresh directory.
set -euo pipefail

ZEEK_BIN="${ZEEK_BIN:-/opt/zeek/bin/zeek}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PCAP_DIR="${PCAP_DIR:-$HOME/icmp-debug}"
TEST_ROOT="${TEST_ROOT:-$HOME/icmp-debug/v1.5-$(date -u +%Y%m%d-%H%M%S)}"

for tool in jq awk; do
    command -v "$tool" >/dev/null || { echo "ERROR: missing $tool" >&2; exit 1; }
done
[[ -x "$ZEEK_BIN" ]] || { echo "ERROR: Zeek missing: $ZEEK_BIN" >&2; exit 1; }
[[ ! -e "$TEST_ROOT" ]] || { echo "ERROR: directory already exists: $TEST_ROOT" >&2; exit 1; }

# Uses the four captures already present on the ZeekVM.
declare -A PCAPS=(
    [low]="$PCAP_DIR/icmp-calibration-long.pcap"
    [high]="$PCAP_DIR/icmp-calibration-298.pcap"
    [multi]="$PCAP_DIR/icmp-multiwindow.pcap"
    [boundary]="$PCAP_DIR/icmp-boundary-v1_4.pcap"
)
for name in low high multi boundary; do
    [[ -r "${PCAPS[$name]}" ]] || {
        echo "ERROR: cannot read ${PCAPS[$name]}" >&2; exit 1;
    }
done

mkdir -p "$TEST_ROOT"

run_case() {
    local name="$1"
    local pcap="${PCAPS[$name]}"
    local out="$TEST_ROOT/$name"
    mkdir -p "$out"
    echo "=== $name ==="
    ( cd "$out" && "$ZEEK_BIN" -r "$pcap" "$SCRIPT_DIR/test_threshold.zeek" )
    [[ -s "$out/icmp_flood_metrics.log" ]] || { echo "ERROR: missing metrics: $name" >&2; exit 1; }
    local alerts=0
    [[ ! -s "$out/icmp_flood.log" ]] || alerts="$(jq -s 'length' "$out/icmp_flood.log")"
    jq -s --arg scenario "$name" --argjson alerts "$alerts" \
        '{scenario:$scenario,observed_total:(map(.observed_packets)|add),fixed_windows:length,alerts:$alerts}' \
        "$out/icmp_flood_metrics.log"
}

for scenario in low high multi boundary; do
    run_case "$scenario"
done

fail() { echo "FAIL: $*" >&2; echo "Evidence preserved: $TEST_ROOT" >&2; exit 1; }

[[ ! -s "$TEST_ROOT/low/icmp_flood.log" ]] || fail "false positive for low"
jq -e -s 'length==4 and (map(.observed_packets)|add)==320' \
    "$TEST_ROOT/low/icmp_flood_metrics.log" >/dev/null || fail "low metrics"

jq -e -s 'length==1 and .[0].event_type=="icmp_flood_suspected" and .[0].observed_packets==500 and .[0].alert_phase=="sliding_threshold_crossed" and .[0].threshold_trigger_pps>0' \
    "$TEST_ROOT/high/icmp_flood.log" >/dev/null || fail "high early alert"
jq -e -s 'length==1 and (map(.observed_packets)|add)==596' \
    "$TEST_ROOT/high/icmp_flood_metrics.log" >/dev/null || fail "high metrics"

jq -e -s 'length==1 and .[0].observed_packets==500' \
    "$TEST_ROOT/multi/icmp_flood.log" >/dev/null || fail "multi cooldown alert"
jq -e -s 'length==2 and (map(.observed_packets)|add)==1600 and (any(.[]; .cooldown_suppressed == true))' \
    "$TEST_ROOT/multi/icmp_flood_metrics.log" >/dev/null || fail "multi cooldown metrics"

jq -e -s 'length==1 and .[0].observed_packets==500 and .[0].alert_phase=="sliding_threshold_crossed" and .[0].dest_ip=="10.3.30.3"' \
    "$TEST_ROOT/boundary/icmp_flood.log" >/dev/null || fail "boundary false negative persists"
jq -e -s 'length==2 and (map(.observed_packets)|add)==802 and (map(.fixed_window_threshold_reached)|all(.==false)) and (any(.[]; .alert_emitted==true))' \
    "$TEST_ROOT/boundary/icmp_flood_metrics.log" >/dev/null || fail "boundary fixed/sliding metrics"

BOUNDARY_TS="$(jq -r '.ts' "$TEST_ROOT/boundary/icmp_flood.log")"
awk -v actual="$BOUNDARY_TS" -v expected=1791974668.501825 'BEGIN {
    d=actual-expected; if(d<0)d=-d;
    printf "Boundary alert timestamp: %.6f (delta from PCAP analysis %.6f s)\n",actual,d;
    if(d>0.001)exit 1;
}' || fail "boundary threshold timestamp"

echo "PASS: all 4 offline v1.5 regression scenarios."
echo "Test outputs: $TEST_ROOT"
