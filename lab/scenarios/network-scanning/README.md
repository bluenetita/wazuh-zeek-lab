# Network Scanning

Scenario for detecting scanning activity through custom Zeek scripts and Wazuh rules.

## Detectors and thresholds in the final snapshot

| Detector | Threshold | Window |
|---|---:|---:|
| TCP address scan | 20 destinations per source/port | 60 s |
| TCP port scan | 100 ports | 60 s |
| UDP port scan | 50 ports | 60 s |
| ARP host scan | 20 targets | 60 s |
| ICMP host scan | 2 targets | 60 s |

These are laboratory values, not a universal baseline.

## Address scan

Updated file:

```text
blue-team/zeek/site/custom_scripts/scanning/address_scan.zeek
```

For TCP traffic, the script tracks destinations contacted by a source on the same port and emits `address_scan` when the number of targets reaches the threshold.

During SSH testing, the experimental value `threshold=2` caused a false positive: A1 contacting V1 and V2 on port 22 was also classified as an address scan. The final snapshot keeps `threshold=20`; after that change, the two-victim test no longer produced rule `100918`.

## Correlation with SSH

Rule `120936` links previous scanning activity with confirmed SSH brute force from the same source. It is intentionally source-oriented because a scan can involve multiple destinations and does not always provide one victim that should be matched.

Tuning the threshold to 20 cleanly isolates the two-server fan-out test, but it is not a complete validation of simultaneous interaction between a real scan and SSH fan-out.

## Reproducibility

With threshold 20, contacting only two hosts is no longer sufficient to reproduce `100918`. Scanning tests must match the configured threshold and must be performed only inside the authorized cyber range.
