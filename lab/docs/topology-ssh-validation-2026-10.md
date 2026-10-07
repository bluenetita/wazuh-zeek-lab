# SSH validation topology

Topology used in the real tests performed on October 5-6, 2026. The IDs belong to this installation and must not be reused as credentials or manually assigned in another deployment.

| Label | Host / agent name | IPv4 | Wazuh agent | Test role |
|---|---|---|---|---|
| A1 | Client-Linux | `10.3.20.2` | `007` | SSH source 1 |
| A2 | Client-Linux2 | `10.3.20.4` | `013` | SSH source 2 |
| V1 | ServerDB | `10.3.30.3` | `005` | SSH server 1 |
| V2 | ServerDB2 | `10.3.30.4` | `012` | SSH server 2 |
| Sensor | Zeek | `10.3.10.2` | `006` | Network observation |
| Manager | wazuhvm | `10.3.10.3` | `000` | Correlation |

Zeek listens on the `ens19.999` mirror interface. SSH tests cross the client network `10.3.20.0/24` and server network `10.3.30.0/24`; this document describes only the topology required for SSH validation and does not replace the complete Proxmox/OVS/RouterOS documentation.

```text
A1 10.3.20.2 ----+---- V1 10.3.30.3 --> agent 005 --+
                |                                |
A2 10.3.20.4 ----+---- V2 10.3.30.4 --> agent 012 --+--> Wazuh
                |                                |
                +---- mirror --> Zeek agent 006 --+
```

## Clone identity separation

ServerDB2 and Client-Linux2 were created as clones but registered with distinct Wazuh agent IDs. The clones reuse the base configurations of their respective hosts while keeping distinct Wazuh identities and IP addresses.

When creating a new clone, isolate the NIC first, assign a distinct IP/MAC/hostname, do not start the agent with a copied `client.keys`, and register a new identity. Also review `machine-id`, SSH host keys, and service identities; whether they must be regenerated depends on the target environment. Changing only the display name in Proxmox is not sufficient.

Reusing the same username in the tests does not confuse the IP pair. Reusing the same password was a laboratory choice, not a recommendation for other environments.

One V2 log still displayed `serverdbvm`; agent `012` and `dstip=10.3.30.4` were correct. Alignment of the hostname emitted by logging remains a separate cleanup item.
