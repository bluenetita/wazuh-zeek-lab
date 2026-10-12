# Setup Guide
## Recommended order
1. Deploy Proxmox bridges and VLANs.
2. Configure pfSense/RouterOS routing and firewall policy.
3. Configure the OVS mirror and VLAN 999 capture path.
4. Install/configure ZeekVM and verify mirrored traffic.
5. Deploy the custom reverse-shell, data-exfiltration, scanning, and MITM scripts.
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

## Zeek MITM package

Deploy the MITM package under:

```text
/opt/zeek/share/zeek/site/custom_scripts/mitm/
  __load__.zeek
  logging.zeek
  arp_spoof.zeek
  dhcp_spoof.zeek
  dns_spoof.zeek
```

Ensure `local.zeek` contains:

```zeek
@load custom_scripts/mitm
```

Prepare the three custom log files with `blue-team/zeek/scripts/wazuh-zeek.sh`, then validate and deploy Zeek:

```bash
sudo /opt/zeek/bin/zeekctl check
sudo /opt/zeek/bin/zeekctl deploy
```

The ARP detector depends on link-layer visibility and a valid IP/MAC baseline. A topology or NIC change requires updating the protected bindings before interpreting mismatches as security events.

## Wazuh agent collection

The ZeekVM agent must collect `/var/log/zeek-custom/scanning.log` plus `mitm_arp.log`, `mitm_dhcp.log`, and `mitm_dns.log` as JSON. The ServerDB agent must collect `/var/log/audit/audit.log` using the Audit log format.

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

The existing manager configuration already loads `etc/decoders` and `etc/rules`, so the scanning/AppArmor/MITM additions do not require a new manager `<rule_dir>` or `<decoder_dir>` entry.
## Validation order

Validate the new functionality in this order:
1. each Zeek scanning event type appears in `scanning.log`;
2. Wazuh rules `100915-100919` match the corresponding event types;
3. a prior reverse-shell correlation followed by scanning triggers one of `120927-120934` with the same `src_ip`;
4. an AppArmor denial is decoded as `apparmor_audit`;
5. base AppArmor rule `130900` triggers;
6. specialized rules such as execution/file/network/capability rules trigger only when their required fields are present;
7. repeated-denial rules are tested separately from one-shot events.

## MITM validation order

1. confirm `zeekctl check` succeeds with `custom_scripts/mitm` loaded;
2. confirm new MITM events are appended to the correct custom JSON log;
3. on ZeekVM, run `sudo /var/ossec/bin/wazuh-logcollector -t` and `sudo /var/ossec/bin/wazuh-agentd -t`;
4. on the Manager, run `sudo /var/ossec/bin/wazuh-analysisd -t`;
5. verify rules `100930`, `100931`, and `100932` independently before adding any correlation or automatic response;
6. retain a normal/negative control for each detector and restore the network baseline after every run.

## Publication checks

Before committing:

- do not add the compiled `inventario_c` binary;
- do not add `audit.log`, `scanning.log`, full `mitm_*.log` files, or rotated `.gz` archives;
- do not add signed webhook URLs, credentials, keys, `client.keys`, or `authd.pass`;
- keep only reduced/sanitized evidence samples;
- review `git diff` for accidental secrets.
