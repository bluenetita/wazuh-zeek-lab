# Static Zeek files to copy from wazuh-zeek-lab

Copy the real files from your existing `wazuh-zeek-lab/blue-team/zeek/` tree into this role before running it:

- `etc/zeekctl.cfg` -> `roles/zeek/files/etc/zeekctl.cfg`
- `etc/networks.cfg` -> `roles/zeek/files/etc/networks.cfg`
- `site/custom_scripts/local.zeek` -> `roles/zeek/files/site/local.zeek`
- `site/custom_scripts/start.zeek` -> `roles/zeek/files/site/custom_scripts/start.zeek`
- `site/custom_scripts/wazuh-zeek.sh` -> `roles/zeek/files/site/custom_scripts/wazuh-zeek.sh`
- `site/custom_scripts/reverse_shell/*` -> `roles/zeek/files/site/custom_scripts/reverse_shell/`
- `site/custom_scripts/data_exfiltration/*` -> `roles/zeek/files/site/custom_scripts/data_exfiltration/`
- `logrotate/zeek-custom` -> `roles/zeek/files/logrotate/zeek-custom`

Systemd and Netplan are templates in the role because interface names and VLAN IDs are variables.
