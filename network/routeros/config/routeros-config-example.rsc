# RouterOS example configuration - sanitized
# This file is a generic template and does not contain real secrets.

# =========================
# Ethernet interfaces
# =========================

/interface ethernet
set [ find default-name=ether1 ] comment="WAN / uplink to pfSense" disable-running-check=no
set [ find default-name=ether2 ] comment="LAN / VLAN trunk to vmbr2" disable-running-check=no
set [ find default-name=ether3 ] comment="TEST network" disable-running-check=no

# =========================
# VLAN interfaces
# =========================

/interface vlan
add interface=TRUNK_INTERFACE name=vlan10 vlan-id=10 comment="Monitoring VLAN"
add interface=TRUNK_INTERFACE name=vlan20 vlan-id=20 comment="Client VLAN"
add interface=TRUNK_INTERFACE name=vlan30 vlan-id=30 comment="Server VLAN"

# =========================
# IP addresses
# =========================

/ip address
add address=ROUTEROS_WAN_IP/CIDR comment="WAN toward pfSense" interface=PFSENSE_UPLINK_INTERFACE network=WAN_TRANSIT_NET
add address=ROUTEROS_LAN_IP/CIDR comment="LAN gateway for internal networks" interface=TRUNK_INTERFACE network=INTERNAL_SUPERNET

add address=VLAN10_GATEWAY/CIDR comment="Monitoring VLAN gateway" interface=vlan10 network=MONITORING_NET
add address=VLAN20_GATEWAY/CIDR comment="Client VLAN gateway" interface=vlan20 network=CLIENT_NET
add address=VLAN30_GATEWAY/CIDR comment="Server VLAN gateway" interface=vlan30 network=SERVER_NET

add address=TEST_NET_GATEWAY/CIDR comment="Optional test network" interface=TEST_INTERFACE network=TEST_NET

# =========================
# DNS
# =========================

/ip dns
set servers=DNS_SERVER_1,DNS_SERVER_2

# =========================
# Routing
# =========================

/ip route
add comment="Default route to pfSense" dst-address=0.0.0.0/0 gateway=PFSENSE_INTERNAL_IP

# Optional route for VPN network
add comment="VPN via Proxmox" dst-address=VPN_NET gateway=PROXMOX_VPN_GATEWAY

# =========================
# Firewall filter
# =========================

/ip firewall filter
add action=fasttrack-connection chain=forward comment="FastTrack established/related" connection-state=established,related
add action=accept chain=forward comment="Accept established/related" connection-state=established,related

# Inter-VLAN traffic
add action=accept chain=forward comment="VLAN10 -> VLAN20" in-interface=vlan10 out-interface=vlan20
add action=accept chain=forward comment="VLAN20 -> VLAN10" in-interface=vlan20 out-interface=vlan10

add action=accept chain=forward comment="VLAN10 -> VLAN30" in-interface=vlan10 out-interface=vlan30
add action=accept chain=forward comment="VLAN30 -> VLAN10" in-interface=vlan30 out-interface=vlan10

add action=accept chain=forward comment="VLAN20 -> VLAN30" in-interface=vlan20 out-interface=vlan30
add action=accept chain=forward comment="VLAN30 -> VLAN20" in-interface=vlan30 out-interface=vlan20

# VLANs to WAN / pfSense
add action=accept chain=forward comment="VLAN10 -> WAN" in-interface=vlan10 out-interface=PFSENSE_UPLINK_INTERFACE
add action=accept chain=forward comment="VLAN20 -> WAN" in-interface=vlan20 out-interface=PFSENSE_UPLINK_INTERFACE
add action=accept chain=forward comment="VLAN30 -> WAN" in-interface=vlan30 out-interface=PFSENSE_UPLINK_INTERFACE

# VPN access to internal VLANs
add action=accept chain=forward comment="VPN SSH to VLANs" src-address=VPN_NET dst-address=INTERNAL_SUPERNET protocol=tcp dst-port=22
add action=accept chain=forward comment="VPN HTTPS to VLANs" src-address=VPN_NET dst-address=INTERNAL_SUPERNET protocol=tcp dst-port=443
add action=accept chain=forward comment="VPN HTTP to VLANs" src-address=VPN_NET dst-address=INTERNAL_SUPERNET protocol=tcp dst-port=80
add action=accept chain=forward comment="VPN RDP to VLANs" src-address=VPN_NET dst-address=INTERNAL_SUPERNET protocol=tcp dst-port=3389

# Default deny
add action=drop chain=forward comment="Drop everything else"

# =========================
# NAT
# =========================

/ip firewall nat
add action=masquerade chain=srcnat comment="NAT LAN to WAN" out-interface=PFSENSE_UPLINK_INTERFACE