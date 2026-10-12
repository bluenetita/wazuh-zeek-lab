# MITM validation matrix

This matrix separates observed positive-path evidence from controls that should be retained before claiming production-grade coverage.

| Test ID | Vector | Input condition | Expected Zeek result | Wazuh rule | Evidence in this update | Status |
|---|---|---|---|---:|---|---|
| `MITM-ARP-P01` | ARP | protected gateway/client IP advertised by an unexpected MAC | `arp_spoof` / `protected_ip_mac_mismatch` | `100930` | `zeek-arp-sample.jsonl` | observed at Zeek |
| `MITM-DHCP-P01` | DHCP | unexpected server OFFER on static VLAN 20 | `dhcp_spoof` / `unexpected_dhcp_server_on_static_segment` | `100931` | `zeek-dhcp-sample.jsonl` | observed at Zeek |
| `MITM-DNS-P01` | DNS | protected public name returns private A record | `dns_spoof` / `protected_public_domain_resolved_to_private_address` | `100932` | `zeek-dns-sample.jsonl` | observed at Zeek |
| `MITM-ARP-N01` | ARP negative control | protected IP advertised by expected MAC | no MITM event | none | not supplied | to archive |
| `MITM-DHCP-N01` | DHCP negative control | normal static-address baseline | no MITM event | none | not supplied | to archive |
| `MITM-DNS-N01` | DNS negative control | protected name returns expected public A record | no MITM event | none | not supplied | to archive |

## End-to-end completion criterion

For each positive test, mark the Wazuh path as validated only after retaining a minimal selected Manager alert showing the expected rule ID and matching event fields. Do not use the presence of the rule file alone as proof that the end-to-end alert path fired.

## DHCP evidence qualification

The supplied DHCP positive sample advertises the same IPv4 address that is already assigned to the test source. It demonstrates that Zeek observed an unexpected OFFER; it does not establish that the protected client accepted a valid lease or that a MITM channel became functional. Record these as separate outcomes if the scenario is repeated.
