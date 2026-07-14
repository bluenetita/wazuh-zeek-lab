# Security Scenarios

This directory contains controlled validation scenarios for the monitoring and response architecture.

| Scenario | Main telemetry | Main validation goal |
|---|---|---|
| [`reverse-shell/`](reverse-shell/) | Zeek custom logs, Auditd connection events, Wazuh correlation, Active Response | Correlate network and endpoint evidence and test containment |
| [`privilege-escalation/`](privilege-escalation/) | Auditd keys, Wazuh privilege rules, FIM and system context | Detect privileged and post-exploitation command execution |
| [`data-exfiltration/`](data-exfiltration/) | Zeek outbound-volume baseline, custom JSON log, Wazuh rules `100913` and `100914` | Detect an authorized high-volume transfer that exceeds the learned threshold |

Each scenario should define:

- objective and scope;
- involved systems;
- prerequisites;
- safe controlled actions;
- expected telemetry;
- relevant decoder and rule IDs;
- result interpretation;
- response behavior, when implemented;
- cleanup;
- limitations;
- sanitized evidence references.

## Safety

The scenarios are intended for the isolated laboratory and authorized testing only.

Do not commit or publish:

- weaponized payloads;
- malware;
- credentials or private keys;
- real confidential data;
- complete packet captures;
- complete unredacted logs;
- reusable offensive instructions intended for unauthorized systems.

Use benign test files, authorized endpoints, and reduced evidence that demonstrates defensive visibility without exposing sensitive content.
