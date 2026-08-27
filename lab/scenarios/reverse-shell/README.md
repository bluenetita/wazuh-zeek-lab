# Reverse-Shell Detection and Containment

## Objective

Validate multi-source detection of a controlled reverse-shell session and test automated evidence collection and RouterOS quarantine.

## Expected telemetry

### Zeek

- `possible_malware` when a suspicious download is observed;
- `reverse_shell_live` for the suspected connection start;
- `reverse_shell_movement` for continued traffic;
- `reverse_shell_final` when the connection closes.

### Auditd

A successful outbound `connect()` event with process, PID/PPID, user, destination address, and destination port.

### Wazuh

- low-level Zeek rules `100909–100912`;
- endpoint rule `110900`;
- correlation chains `120900–120926`;
- severity progression from initial evidence to complete lifecycle.

## Response

Movement-stage correlation rules can launch `routeros_quarantine.py` on the manager. The script adds the victim IP to `Quarantine` and removes active source/destination connections.

The evidence collector can snapshot processes, sockets, routes, users, Auditd records, and journal entries. Review its current `ossec.conf` targeting and timeout configuration before reuse.

## Result interpretation

A high-confidence alert means multiple observations agreed; it does not replace forensic investigation. Preserve timestamps, UIDs, destination fields, process information, and response logs.

## Cleanup

- remove the victim from `Quarantine` after remediation;
- confirm the suspicious process is no longer running;
- remove controlled test files;
- archive only sanitized evidence;
- restore the endpoint snapshot if required.

## Current limitation

Network quarantine is implemented. Direct endpoint process termination is not included in the versioned Active Response code.
