# Auditd Configuration

This directory contains the Linux Audit rules used on `ClientVM` to provide endpoint context for reverse-shell and privilege-escalation scenarios.

## Files

| File | Purpose |
|---|---|
| `rules.d/audit.rules` | Base Audit subsystem settings |
| `rules.d/privileged-command.rules` | Keys for SUID, root, `sudo`, `su`, and downloads-directory execution |
| `rules.d/reverse_shell.rules` | Successful outbound `connect()` syscall monitoring |

## Keys

| Key | Purpose |
|---|---|
| `rs_connect` | Successful outbound network connection |
| `suid_exec` | Non-root execution with effective root privileges |
| `root_exec` | Command executed from a root login session |
| `sudo_exec` | Execution of `/usr/bin/sudo` |
| `su_exec` | Execution of `/usr/bin/su` |
| `download_exec` | Execution below the monitored Downloads directory |

## Deployment

```bash
sudo cp rules.d/*.rules /etc/audit/rules.d/
sudo augenrules --load
sudo auditctl -l
```

## Validation

```bash
sudo ausearch -k rs_connect -i
sudo ausearch -k suid_exec -i
sudo ausearch -k sudo_exec -i
sudo ausearch -k su_exec -i
sudo ausearch -k download_exec -i
```

The rules generate telemetry, not final verdicts. Interpret them together with process, user, network, Zeek, and Wazuh correlation context.
