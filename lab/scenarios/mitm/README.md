# MITM / Adversary-in-the-Middle scenario

## Objective

Validate whether the Zeek + Wazuh monitoring path can identify network indicators associated with three controlled adversary-in-the-middle conditions on VLAN 20:

- ARP cache poisoning indicators;
- rogue DHCP activity on a statically addressed segment;
- manipulated DNS A-record responses for a protected public domain.

The public repository documents the **defensive experiment, telemetry, and results**. Reusable attack command sequences and credential-capture examples remain in private lab notes.

## Scenario-specific roles

| Role in this scenario | Address | Notes |
|---|---|---|
| VLAN 20 gateway | `10.3.20.1` | protected ARP binding |
| Controlled MITM test source | `10.3.20.2` | used only as an authorized test source for this scenario |
| Protected client / victim | `10.3.20.4` | protected ARP and DNS client |
| ZeekVM | `10.3.10.2` | passive sensor receiving mirrored traffic |
| Wazuh Manager | `10.3.10.3` | rule evaluation and alerting |

The `10.3.20.2` and `10.3.20.4` hosts also have roles in other validation scenarios. The table above describes their role **only during the MITM campaign**.

## Detection coverage

| Vector | Zeek condition | Zeek log | Wazuh rule | ATT&CK |
|---|---|---|---:|---|
| ARP | protected IP advertised by a MAC different from the baseline | `mitm_arp.log` | `100930` | `T1557.002` |
| DHCP | unexpected OFFER/ACK on the static VLAN 20 segment | `mitm_dhcp.log` | `100931` | `T1557.003` |
| DNS | protected public name resolves to a private IPv4 address for the protected client | `mitm_dns.log` | `100932` | `T1557` |

## Prerequisites

1. VLAN 20 traffic is mirrored to the Zeek capture path, including the layer-2 frames required by ARP detection.
2. `local.zeek` loads `custom_scripts/mitm`.
3. `/var/log/zeek-custom/mitm_arp.log`, `mitm_dhcp.log`, and `mitm_dns.log` exist with `zeek:wazuh` ownership and mode `0640`.
4. The ZeekVM Wazuh Agent collects the three files as JSON.
5. `007_mitm_rules.xml` is installed under the Manager custom rules directory.
6. Zeek and Wazuh configurations pass their respective validation commands before any service restart.

## Safe validation method

Use an isolated, authorized laboratory only. Keep operational test commands outside the public repository.

For each vector:

1. record the initial network state and a UTC timestamp;
2. verify that the normal baseline is present before inducing the condition;
3. exercise **one vector at a time**;
4. verify the corresponding Zeek event and key fields;
5. verify the Wazuh rule match for the same event;
6. stop the test condition;
7. restore normal routing/addressing/name-resolution state;
8. verify client connectivity, gateway resolution, and DNS behavior after cleanup;
9. retain only a minimal sanitized evidence sample.

## Observed positive-path evidence

### ARP

The supplied evidence contains two complementary ARP mismatch records:

- the gateway address `10.3.20.1` was advertised by the unexpected test-source MAC toward `10.3.20.4`;
- the protected client address `10.3.20.4` was advertised by the same unexpected MAC toward the gateway.

The detector records the expected MAC, observed MAC, target endpoint, and optional contextual attribution.

### DHCP

The supplied sample contains a `DHCPOFFER` from `10.3.20.2` on VLAN 20. The offer advertises the same test node as router and DNS server. Because the monitored segment baseline expects no legitimate DHCP server, the event is classified as `unexpected_dhcp_server_on_static_segment`.

**Validity caveat:** the observed `offered_ip` is also `10.3.20.2`, which is already assigned to the controlled source. This supports detection of an anomalous OFFER, but it does **not** demonstrate a correct, conflict-free lease or a successful interception. Repeated experiments should use an unallocated address pool and independently verify the client's accepted address and connectivity.

### DNS

The supplied sample shows the protected client `10.3.20.4` receiving a response for `example.com` that points to the private address `10.3.20.2`. The detector records the client, apparent resolver, protected query, and suspicious answer.

## Wazuh alerts

The custom rules are:

| ID | Level | Condition |
|---:|---:|---|
| `100930` | 12 | `event_type=arp_spoof` + `reason=protected_ip_mac_mismatch` + ARP log location |
| `100931` | 12 | `event_type=dhcp_spoof` + `reason=unexpected_dhcp_server_on_static_segment` + DHCP log location |
| `100932` | 12 | `event_type=dns_spoof` + `reason=protected_public_domain_resolved_to_private_address` + DNS log location |

The repository evidence supplied with this update contains reduced **Zeek** JSONL samples. Add selected Wazuh alert excerpts only after confirming them from the Manager; do not fabricate or publish complete `alerts.json` archives.

## Negative controls still worth retaining

Positive-path evidence does not by itself characterize false-positive behavior. A stronger final campaign should archive these controls:

- ARP: correct IP-to-MAC advertisements produce no `100930` event;
- DHCP: no offer/ack is observed during a normal static-address baseline window;
- DNS: the protected public domain resolving to an expected public address produces no `100932` event;
- attribution: an unknown unexpected MAC still triggers the ARP mismatch but does not receive a trusted attacker-IP attribution.

## Cleanup checks

After every run, verify at minimum:

- the protected client has the expected IP configuration;
- the default gateway is the intended gateway;
- ARP/neighbor state no longer contains the test-source MAC for protected IPs;
- DNS configuration is restored and the protected name returns its normal answer;
- temporary forwarding/NAT/test services are no longer active;
- Zeek and Wazuh remain healthy and continue processing normal traffic.

## Interpretation

These detections indicate conditions **consistent with** MITM activity, not cryptographic proof that an attacker successfully intercepted data. Configuration changes, legitimate DHCP introduction, split-horizon DNS, stale baselines, or network-device replacement can generate similar signals. Treat the Wazuh alert as a high-priority investigation trigger and correlate it with switch, endpoint, DNS/DHCP, and application telemetry.

## Evidence

Reduced evidence is stored under [`../../evidence/mitm/`](../../evidence/mitm/README.md).
