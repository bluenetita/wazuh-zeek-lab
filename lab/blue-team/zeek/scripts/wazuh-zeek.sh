#!/bin/bash

CUSTOM_LOGS="
possible_malware
reverse_shell_live
reverse_shell_final
reverse_shell_movement
data_exfiltration
scanning
ssh_bruteforce
mitm_arp
mitm_dhcp
mitm_dns
"
for f in $CUSTOM_LOGS; do
    if [ ! -f "/var/log/zeek-custom/${f}.log" ]; then
        install -m 0640 -o zeek -g wazuh /dev/null "/var/log/zeek-custom/${f}.log"
    fi
done
systemctl restart wazuh-agent.service
