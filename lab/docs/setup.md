# Setup Guide

## Recommended order

1. Deploy Proxmox bridges and VLANs.
2. Configure pfSense/RouterOS routing and firewall policy.
3. Configure the OVS mirror and VLAN 999 capture path.
4. Install/configure ZeekVM and verify mirrored traffic.
5. Deploy the custom reverse-shell, data-exfiltration, and scanning scripts.
6. Install Wazuh agents on ZeekVM, ClientVM, and ServerDB.
7. Install Auditd rules on ClientVM.
8. Install the ServerDB AppArmor profile in complain mode for initial observation.
9. Install custom Wazuh decoders and rules on the manager.
10. Validate individual events before testing correlations.
11. Validate AppArmor enforce mode only after required service behavior is understood.
12. Run controlled scenarios and retain only sanitized evidence in Git.

## Zeek scanning package

Copy the scanning package to the Zeek site directory so the structure is equivalent to:

```text
/opt/zeek/share/zeek/site/custom_scripts/scanning/
  __load__.zeek
  logging.zeek
  host_scan.zeek
  port_scan.zeek
  address_scan.zeek
  udp_scan.zeek
  icmp_scan.zeek
```

Ensure `local.zeek` loads the package:

```zeek
@load custom_scripts/scanning
```

Validate and deploy:

```bash
sudo /opt/zeek/bin/zeekctl check
sudo /opt/zeek/bin/zeekctl deploy
```

Confirm that `/var/log/zeek-custom/scanning.log` can be created/written by the Zeek process and read by the Wazuh Agent.

## Wazuh agent collection

The ZeekVM agent must collect `/var/log/zeek-custom/scanning.log` as JSON. The ServerDB agent must collect `/var/log/audit/audit.log` using the Audit log format.

After updating an agent configuration, restart the corresponding Wazuh Agent and verify `/var/ossec/logs/ossec.log`.

## AppArmor on ServerDB

Install the profile at:

```text
/etc/apparmor.d/opt.inventario_service.inventario_c
```

Reload it after edits:

```bash
sudo apparmor_parser -r /etc/apparmor.d/opt.inventario_service.inventario_c
```

Verify status with:

```bash
sudo aa-status
```

Use complain mode while observing required service behavior, then test enforce mode in the isolated lab. Do not assume that commented `deny` examples are active policy.

## Wazuh Manager

Copy the custom decoder/rule files into the manager's configured custom directories, normally:

```text
/var/ossec/etc/decoders/
/var/ossec/etc/rules/
```

Validate before restart:

```bash
sudo /var/ossec/bin/wazuh-analysisd -t
sudo /var/ossec/bin/wazuh-logtest
```

The existing manager configuration already loads `etc/decoders` and `etc/rules`, so the scanning/AppArmor additions do not require a new manager `<rule_dir>` or `<decoder_dir>` entry.

## Validation order

Validate the new functionality in this order:

1. each Zeek scanning event type appears in `scanning.log`;
2. Wazuh rules `100915-100919` match the corresponding event types;
3. a prior reverse-shell correlation followed by scanning triggers one of `120927-120934` with the same `src_ip`;
4. an AppArmor denial is decoded as `apparmor_audit`;
5. base AppArmor rule `130900` triggers;
6. specialized rules such as execution/file/network/capability rules trigger only when their required fields are present;
7. repeated-denial rules are tested separately from one-shot events.

## Publication checks

Before committing:

- do not add the compiled `inventario_c` binary;
- do not add `audit.log`, `scanning.log`, or rotated `.gz` archives;
- do not add signed webhook URLs, credentials, keys, `client.keys`, or `authd.pass`;
- keep only reduced/sanitized evidence samples;
- review `git diff` for accidental secrets.
