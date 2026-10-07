# Reverse Shell

Scenario for detection and correlation of connections compatible with reverse-shell behavior using Zeek and Wazuh telemetry, with endpoint-side Auditd integration and RouterOS containment validation.

## Objective

Correlate different signals without treating a single network heuristic as definitive proof. The pipeline uses Zeek connection events, movement events, host-based signals, and Wazuh correlation rules.

## Components

- Zeek custom logs: `possible_malware.log`, `reverse_shell_live.log`, `reverse_shell_movement.log`, `reverse_shell_final.log`;
- `reverse_shell_movement.zeek` v2;
- Auditd decoder `000_audit_saddr_decoder.xml`;
- correlations in `004_zeek_auditd_correlation.xml`;
- downstream scanning correlations in `005_zeek_scanning_correlation.xml`;
- optional evidence collector;
- RouterOS Active Response, validated separately in OFF/ON conditions.

## Movement detector v2

The main condition is:

```text
duration >= 30 s
orig_pkts > 10
resp_pkts > 10
```

The older average-packet-size thresholds are diagnostic only and no longer block event generation. The detector reevaluates state periodically and on new packets and limits output to one movement event per connection.

File:

```text
blue-team/zeek/site/custom_scripts/reverse_shell/reverse_shell_movement.zeek
```

## Host/network correlation

Client-Linux collects Auditd events related to connections and enriches them with the local host IP. The decoder extracts fields used for correlation with Zeek. IP semantics in the reverse-shell scenario differ from inbound SSH: the compromised host may be the outbound connection `src_ip`.

## Recovered tests

Ten runs from the campaign also used for the Active Response comparison are retained, including selected Zeek records, Wazuh alerts, and OFF/ON outcomes. A separate historical negative control is also included.

Evidence:

- [`../../evidence/routeros-ar/2026-10-01/README.md`](../../evidence/routeros-ar/2026-10-01/README.md)
- [`../../evidence/reverse-shell/2026-10-01-negative-control/README.md`](../../evidence/reverse-shell/2026-10-01-negative-control/README.md)

The repository does not claim that every run contains a complete sequence of every custom log or that the heuristic detects every reverse-shell variant.

## Containment

RouterOS quarantine is documented in [`../active-response/README.md`](../active-response/README.md). In the published `ossec.conf` export, the block that would automatically enable quarantine is commented out.

## Limitations

- heuristics depend on mirror visibility;
- duplicates/retransmissions can affect packet-based counters;
- allowed ports and excluded networks can create blind spots;
- Zeek does not directly observe the local process that opened a connection;
- final attribution requires correlation with host-based telemetry.
