
#
/ip firewall filter add action=accept chain=forward comment="Allow Wazuh from pfSense" dst-address=10.3.10.3 dst-port=1514,1515 log=yes protocol=tcp src-address=10.2.0.3
/ip firewall filter add action=fasttrack-connection chain=forward comment="FastTrack established/related" connection-state=established,related
/ip firewall filter add action=accept chain=forward comment="Accept established/related" connection-state=established,related
/ip firewall filter add action=accept chain=forward comment="Quarantena - Wazuh -> Quarantena" dst-address-list=Quarantine dst-port=22,1514 protocol=tcp src-address-list="Trusted IP"
/ip firewall filter add action=accept chain=forward comment="Quarantena - Quarantena -> Wazuh" dst-address-list="Trusted IP" protocol=tcp src-address-list=Quarantine src-port=22,1514
/ip firewall filter add action=drop chain=forward comment="Drop verso quarantena" dst-address-list=Quarantine
/ip firewall filter add action=drop chain=forward comment="Drop da quarantena" src-address-list=Quarantine
/ip firewall filter add action=accept chain=forward comment="VLAN10 -> VLAN20" in-interface=vlan10 out-interface=vlan20
/ip firewall filter add action=accept chain=forward comment="VLAN20 -> VLAN10" in-interface=vlan20 out-interface=vlan10
/ip firewall filter add action=accept chain=forward comment="VLAN10 -> VLAN30" in-interface=vlan10 out-interface=vlan30
/ip firewall filter add action=accept chain=forward comment="VLAN30 -> VLAN10" in-interface=vlan30 out-interface=vlan10
/ip firewall filter add action=accept chain=forward comment="VLAN20 -> VLAN30" in-interface=vlan20 out-interface=vlan30
/ip firewall filter add action=accept chain=forward comment="VLAN30 -> VLAN20" in-interface=vlan30 out-interface=vlan20
/ip firewall filter add action=accept chain=forward comment="VLAN10 -> WAN" in-interface=vlan10 out-interface=ether1
/ip firewall filter add action=accept chain=forward comment="VLAN20 -> WAN" in-interface=vlan20 out-interface=ether1
/ip firewall filter add action=accept chain=forward comment="VLAN30 -> WAN" in-interface=vlan30 out-interface=ether1
/ip firewall filter add action=accept chain=forward comment="VPN SSH to VLANS" dst-address=10.3.0.0/16 dst-port=22 protocol=tcp src-address=10.8.0.0/24
/ip firewall filter add action=accept chain=forward comment="VPN RDP to VLANS" dst-address=10.3.0.0/16 protocol=rdp src-address=10.8.0.0/24
/ip firewall filter add action=accept chain=forward comment="VPN HTTPS to VLANS" dst-address=10.3.0.0/16 dst-address-list="" dst-port=443 protocol=tcp src-address=10.8.0.0/24
/ip firewall filter add action=accept chain=forward comment="VPN HTTP to VLANS" dst-address=10.3.0.0/16 dst-address-list="" dst-port=80 protocol=tcp src-address=10.8.0.0/24
/ip firewall filter add action=drop chain=forward comment="Drop everything else"