# Observability Gaps

## Network visibility

- Encrypted payloads are not inspected without decryption.
- Zeek observes mirrored traffic only; traffic outside the mirror scope is invisible.
- Packet loss or incorrect OVS/VLAN configuration can produce incomplete sessions.
- Heuristic reverse-shell detection can identify suspicious behavior but cannot prove attacker intent by itself.

## Endpoint visibility

- Auditd captures configured syscalls and watches only.
- The current `connect()` rule focuses on authenticated users and may miss kernel, service, container, or excluded-user activity.
- A fixed syscall number can be architecture-specific.
- Processes may terminate before evidence collection runs.
- AppArmor events describe policy decisions, not necessarily compromise.

## Correlation limitations

- Field normalization must be identical across sources.
- Cross-agent timing and ordering can affect correlation.
- Filename equality is not equivalent to file identity; hashes provide stronger linkage.
- Long timeframes increase the chance of unrelated events being combined.

## Data-exfiltration limitations

- A volume anomaly can represent legitimate backups, updates, or transfers.
- Baselines are sensitive to the learning period and workload changes.
- Low-and-slow exfiltration may remain below the threshold.

## Response limitations

- The evidence collector records a point-in-time snapshot and may miss terminated processes.
- RouterOS quarantine depends on SSH, firewall ordering, connection tracking, and correct victim-IP extraction.
- The current repository does not implement automatic endpoint process termination or automatic quarantine rollback.
- The RouterOS account currently uses the built-in `write` group, which is broader than an ideal least-privilege policy.

## Future improvements

- Add architecture-aware syscall handling.
- Add allowlists for management systems and permitted victim subnets.
- Hash evidence archives and transfer them to protected central storage.
- Create a dedicated RouterOS permission group.
- Add response approval and recovery workflows.
- Add automated tests for decoder and correlation regressions.
