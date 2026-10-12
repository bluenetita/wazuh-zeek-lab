# MITM evidence

This directory contains reduced JSONL samples from the controlled MITM validation campaign. Full Zeek logs, packet captures, credential material, and operational attack commands are intentionally excluded.

| File | Records | What it demonstrates |
|---|---:|---|
| `zeek-arp-sample.jsonl` | 2 | bidirectional protected-IP/MAC mismatch involving the gateway and protected client |
| `zeek-dhcp-sample.jsonl` | 1 | unexpected `DHCPOFFER` on the static VLAN 20 segment |
| `zeek-dns-sample.jsonl` | 1 | protected public domain returning a private IPv4 answer to the protected client |
| `results.tsv` | 3 | compact index of the supplied positive-path evidence |

These are evidence excerpts, not complete runtime logs. Timestamps and private lab addresses are retained because they are useful for reproducibility and do not expose public credentials or secrets.

## Wazuh evidence status

The supplied archive included the Wazuh rule definitions but did not include reduced Manager alert excerpts for all three rules. Therefore this directory does **not** claim that `100930`, `100931`, and `100932` are each proven by an archived Wazuh alert here. Add selected alert samples after verification if they are needed for the thesis/repository evidence chain.
