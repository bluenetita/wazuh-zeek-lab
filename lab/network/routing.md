# Laboratory Routing

Routing is split between pfSense, RouterOS, Proxmox bridges, and endpoint routes.

RouterOS provides internal routing and the quarantine enforcement point. ClientVM normally reaches its VLAN gateway at `10.3.20.1`; RouterOS is reachable at `10.3.0.1` for management and containment workflows.

Document every static route with source, destination, next hop, purpose, and owning device. After changes, validate both forward and return paths to avoid asymmetric routing.

Useful checks:

```text
Linux:   ip route
RouterOS: /ip route print detail
pfSense: Diagnostics -> Routes
```
