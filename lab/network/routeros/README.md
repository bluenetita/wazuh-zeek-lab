# RouterOS

RouterOS is the inter-VLAN router in the cyber range and, in the automated-response scenario, also acts as the enforcement point for Wazuh quarantine.

## Network role

| Interface | Role | Network |
|---|---|---|
| `ether1` | uplink toward pfSense | `10.4.0.0/24` |
| `ether2` | trunk/LAN toward internal VLANs | `10.3.0.0/16` |
| `ether3` | test network | `10.5.0.0/24` |
| `vlan10` | Monitoring | `10.3.10.0/24` |
| `vlan20` | Client | `10.3.20.0/24` |
| `vlan30` | Server | `10.3.30.0/24` |

Gateways documented in the lab:

```text
vlan10  10.3.10.1/24
vlan20  10.3.20.1/24
vlan30  10.3.30.1/24
```

RouterOS forwards external traffic toward pfSense and also retains the VPN-network route documented in the lab configuration. Masquerading toward the uplink can change the source IP observed by pfSense.

Historical interface, VLAN, routing, and firewall files already present in this directory remain part of the documentation and are not replaced by this README.

## Wazuh quarantine

Active Response uses an address list named `Quarantine`. The public script is:

```text
blue-team/wazuh/active-response/routeros_quarantine.py
```

The configuration template is:

```text
blue-team/wazuh/active-response/routeros.conf.example
```

The template contains placeholders only; the private SSH key, passwords, and real router configuration are not versioned.

## Script behavior

When it receives a valid `add` action, the script extracts `data.src_ip`, validates the address syntax, opens a non-interactive SSH session to RouterOS, adds the IP to the list if necessary, and removes matching connections from connection tracking.

The address list by itself does not block traffic; the result depends on the actual firewall rules.

## Policy observed during testing

The campaign snapshot contains:

- exceptions for Wazuh communication;
- drops to/from hosts in `Quarantine`;
- inter-VLAN rules;
- VPN access rules;
- FastTrack/established rules before the quarantine drops in the historical snapshot.

The last point means that rule order and connection tracking must be reviewed before reusing the policy in another environment.

## OFF/ON validation

The October 1, 2026 campaign contains 10 runs:

| Mode | Runs | AR observed | Quarantine | Probe blocked |
|---|---:|---:|---:|---:|
| OFF | 5 | 0/5 | 0/5 | 0/5 |
| ON | 5 | 5/5 | 5/5 | 5/5 |

The probe verified the flow `10.3.20.2 -> 10.2.0.2:22`. It is not proof that every protocol is universally blocked.

Details, metrics, and limitations: [`../../scenarios/active-response/README.md`](../../scenarios/active-response/README.md).

## Cleanup and published state

Quarantine removal during the campaign was performed by the coordinator; the published script does not implement an equivalent automatic rollback.

In the repository's `blue-team/wazuh/manager/ossec.conf`, the quarantine command is defined, but the corresponding `<active-response>` block is commented out. The repository therefore documents the feature without enabling it implicitly.

## Security

Do not publish RouterOS exports containing credentials, private host keys, management secrets, or unnecessary data. The policy snapshot included with the evidence is reduced and intended to explain the test, not for direct import.
