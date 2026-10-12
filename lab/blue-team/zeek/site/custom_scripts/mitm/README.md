# MITM detection package

This package contains lab-specific Zeek detections for three adversary-in-the-middle indicators observed on VLAN 20:

| Detector | Signal | Output |
|---|---|---|
| `arp_spoof.zeek` | a protected IPv4 address is advertised by a MAC address different from its trusted baseline | `/var/log/zeek-custom/mitm_arp.log` |
| `dhcp_spoof.zeek` | a DHCP OFFER/ACK appears on a segment where the lab baseline expects static addressing and no legitimate DHCP server | `/var/log/zeek-custom/mitm_dhcp.log` |
| `dns_spoof.zeek` | a protected public domain returns a private IPv4 address to a protected client | `/var/log/zeek-custom/mitm_dns.log` |

`logging.zeek` defines the shared records and writes one JSON object per line. `__load__.zeek` loads the three detectors.

## Loading

The site policy loads the package with:

```zeek
@load custom_scripts/mitm
```

Validate before deployment:

```bash
sudo /opt/zeek/bin/zeekctl check
sudo /opt/zeek/bin/zeekctl deploy
```

Run these commands on **ZeekVM**. Administrative privileges are required.

## Lab baseline

The supplied configuration reflects the validated laboratory snapshot and is intentionally explicit:

- monitored VLAN 20 subnet: `10.3.20.0/24`;
- protected ARP bindings: gateway `10.3.20.1` and protected client `10.3.20.4`;
- contextual MAC ownership includes `10.3.20.2`, `10.3.20.4`, and `10.3.20.1`;
- protected DNS client: `10.3.20.4`;
- protected DNS names: `example.com` and `www.example.com`;
- duplicate-suppression window: 30 seconds.

These values are **not production defaults**. Update them when the lab topology changes.

## Detection semantics

### ARP

The ARP detector compares the sender protocol address (`SPA`) and sender hardware address (`SHA`) against `MITM::protected_bindings`. A mismatch generates `event_type=arp_spoof` and `reason=protected_ip_mac_mismatch`.

`known_mac_owners` is used only to add context. `suspected_attacker_ip` is therefore an attribution hint, not proof of attacker identity: a source MAC can itself be spoofed.

### DHCP

The DHCP detector observes server-side `DHCPOFFER` and `DHCPACK` messages. In this laboratory VLAN 20 is expected to be statically addressed; therefore a relevant server response is anomalous and generates `reason=unexpected_dhcp_server_on_static_segment`.

If DHCP is legitimately introduced on this segment, this policy must be changed before using the detector because the current assumption would create false positives.

### DNS

The DNS detector watches A-record replies for explicitly protected clients and domains. It raises an event when a protected public name resolves to an RFC1918/private IPv4 address.

This is a scenario-specific heuristic, not a general DNS-poisoning detector. The apparent DNS resolver address in a packet is not necessarily the source of manipulation. Split-horizon DNS, internal overrides, captive portals, VPN DNS, or intentionally private answers can create false positives. For production use, replace the simple private-address test with an allowlisted expected-answer policy or an authoritative baseline.

## Visibility requirements

- ARP detection requires link-layer ARP frames from the monitored segment to reach Zeek through the OVS mirror.
- DHCP detection requires the relevant broadcast/unicast DHCP traffic to be visible to the sensor.
- DNS detection requires Zeek to observe the victim's DNS exchange.
- The OVS mirror must preserve the traffic needed by these analyzers; routing-only visibility is insufficient for some layer-2 signals.

Current Zeek documentation exposes the `arp_request`, `arp_reply`, `dhcp_message`, and `dns_A_reply` events used by this package. Zeek's current ARP documentation also warns that the ARP analyzer is not activated by the default configuration in every deployment. Because this lab has produced ARP events successfully, the current lab path is functional, but a new Zeek version or deployment must be verified rather than assumed compatible.

## Wazuh mapping

| Zeek event | Wazuh rule | ATT&CK |
|---|---:|---|
| `arp_spoof` | `100930` | `T1557.002` ARP Cache Poisoning |
| `dhcp_spoof` | `100931` | `T1557.003` DHCP Spoofing |
| `dns_spoof` | `100932` | `T1557` Adversary-in-the-Middle |

The generic `T1557` mapping for this DNS scenario is intentional. ATT&CK `T1557.001` specifically covers name-resolution poisoning/SMB-relay mechanisms such as LLMNR/NBT-NS/mDNS and should not be assigned automatically to an arbitrary DNS response-manipulation scenario.

## Limitations and production hardening

This package is a cyber-range detector, not a production baseline. Before production use, consider:

1. externalizing protected IP/MAC/domain baselines rather than hard-coding them;
2. adding controlled baseline-change procedures to avoid false positives after NIC or gateway replacement;
3. retaining negative-control tests for every detector;
4. monitoring log-write failures and sensor packet loss;
5. correlating network evidence with switch/DHCP/DNS infrastructure telemetry;
6. replacing MAC-based attribution with corroborated evidence from endpoint, switch-port, DHCP, and authentication logs;
7. tuning alert severity and suppression intervals from measured traffic rather than copying lab values.

## References

- Zeek ARP events: https://docs.zeek.org/en/current/scripts/base/bif/plugins/Zeek_ARP.events.bif.zeek.html
- Zeek DHCP events: https://docs.zeek.org/en/current/scripts/base/bif/plugins/Zeek_DHCP.events.bif.zeek.html
- Zeek DNS events: https://docs.zeek.org/en/current/scripts/base/bif/plugins/Zeek_DNS.events.bif.zeek.html
- MITRE ATT&CK T1557: https://attack.mitre.org/techniques/T1557/
- MITRE ATT&CK T1557.002: https://attack.mitre.org/techniques/T1557/002/
- MITRE ATT&CK T1557.003: https://attack.mitre.org/techniques/T1557/003/
