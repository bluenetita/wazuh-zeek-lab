# RouterOS sanitized configuration
# RouterOS 7.22.1

/interface ethernet
set [ find default-name=ether1 ] comment=WAN disable-running-check=no
set [ find default-name=ether2 ] comment=LAN disable-running-check=no
set [ find default-name=ether3 ] comment="TEST (vmbr4-test)" disable-running-check=no

/interface vlan
add interface=ether2 name=vlan10 vlan-id=10
add interface=ether2 name=vlan20 vlan-id=20
add interface=ether2 name=vlan30 vlan-id=30

/queue interface
set ether1 queue=multi-queue-ethernet-default
set ether2 queue=multi-queue-ethernet-default

/ip address
add address=10.4.0.252/24 comment="WAN verso vmbr1/internet" interface=ether1 network=10.4.0.0
add address=10.3.0.1/16 comment="LAN gateway per VM (vmbr2)" interface=ether2 network=10.3.0.0
add address=10.3.10.1/24 interface=vlan10 network=10.3.10.0
add address=10.3.20.1/24 interface=vlan20 network=10.3.20.0
add address=10.3.30.1/24 interface=vlan30 network=10.3.30.0
add address=10.5.0.1/24 interface=ether3 network=10.5.0.0

/ip dhcp-client
add interface=ether1 name=client1

/ip dns
set servers=1.1.1.1,8.8.8.8

/ip firewall filter
add action=fasttrack-connection chain=forward comment="FastTrack established/related" connection-state=established,related
add action=accept chain=forward comment="Accept established/related" connection-state=established,related
add action=accept chain=forward comment="VLAN10 -> VLAN20" in-interface=vlan10 out-interface=vlan20
add action=accept chain=forward comment="VLAN20 -> VLAN10" in-interface=vlan20 out-interface=vlan10
add action=accept chain=forward comment="VLAN10 -> VLAN30" in-interface=vlan10 out-interface=vlan30
add action=accept chain=forward comment="VLAN30 -> VLAN10" in-interface=vlan30 out-interface=vlan10
add action=accept chain=forward comment="VLAN20 -> VLAN30" in-interface=vlan20 out-interface=vlan30
add action=accept chain=forward comment="VLAN30 -> VLAN20" in-interface=vlan30 out-interface=vlan20
add action=accept chain=forward comment="VLAN10 -> WAN" in-interface=vlan10 out-interface=ether1
add action=accept chain=forward comment="VLAN20 -> WAN" in-interface=vlan20 out-interface=ether1
add action=accept chain=forward comment="VLAN30 -> WAN" in-interface=vlan30 out-interface=ether1
add action=accept chain=forward comment="VPN SSH to VLANS" dst-address=10.3.0.0/16 dst-port=22 protocol=tcp src-address=10.8.0.0/24
add action=accept chain=forward comment="VPN RDP to VLANS" dst-address=10.3.0.0/16 protocol=rdp src-address=10.8.0.0/24
add action=accept chain=forward comment="VPN HTTPS to VLANS" dst-address=10.3.0.0/16 dst-port=443 protocol=tcp src-address=10.8.0.0/24
add action=accept chain=forward comment="VPN HTTP to VLANS" dst-address=10.3.0.0/16 dst-port=80 protocol=tcp src-address=10.8.0.0/24
add action=drop chain=forward comment="Drop everything else"

/ip firewall nat
add action=masquerade chain=srcnat comment="NAT LAN > WAN" out-interface=ether1

/ip route
add comment="Route via WAN pfsense" gateway=10.4.0.253
add comment="VPN via Proxmox" dst-address=10.8.0.0/24 gateway=10.3.0.254