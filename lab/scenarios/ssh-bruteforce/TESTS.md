# SSH Tests: Results and Regression Procedure

## Observed results

Results from the real tests are summarized in [observed-test-summaries.jsonl](../../evidence/ssh-bruteforce/observed-test-summaries.jsonl).

| Test | Observed sequence (Manager timestamp, UTC) | Observed result |
|---|---|---|
| Positive pair | 05/10 16:37:09.654 `120936` A1->V1; 16:37:42.265 login A1->V1 | `120937` |
| Different destination | 06/10 14:40:12.506 `120936` A1->V1; 14:40:44.742 login A1->V2 | `5715`; no `120937` in the queried excerpt |
| Different source | 06/10 15:33:10.707 `120936` A1->V1; 15:33:39.357 login A2->V1 | `5715`; no `120937` in the queried excerpt |
| Fan-out | 06/10 16:03:46.755 pair A1->V1; 16:05:58.757 A1->V2 | `120940` |
| Fan-in | 06/10 16:08:44.770 pair A1->V1; 16:10:44.777 A2->V1 | `120941` |
| Independence | 06/10 16:13:22.790 A1->V1; 16:15:18.797 A2->V2 | Two `120939`; no `120940/120941` in the excerpt |

No recall/precision measurements, statistically meaningful replication count, or simultaneous two-pair test are available. The matrix establishes the behavior of the shown cases, not all possible behavior.

## Test conditions

VMs: A1 `10.3.20.2`, A2 `10.3.20.4`, V1 `10.3.30.3`, V2 `10.3.30.4`. The two servers had distinct Wazuh agents, and `dstip` normalization was verified. Quarantine Active Response was disabled during detection-only testing. Verify the actual state before repeating a test and retain Proxmox console access.

For fan-out, fan-in, and independence: use two sequences separated by at least 70 seconds and complete them within 900 seconds. The Manager was restarted between tests to clear Wazuh correlation state. A restart is not harmless in production and **does not clear Zeek state**. Do not restart the Manager between the two pairs of the same test.

The address-scan threshold was changed from 2 to 20. The source included with this documentation contains 20; this is a laboratory value, not a universal baseline. The previous command that contacted two IP addresses no longer reproduces a scan with threshold 20. To repeat the scan->SSH chain, use an authorized test consistent with the configured threshold or a separate documented test profile. Do not fabricate a `100918` event or treat a missing prerequisite as a successful negative test.

## One controlled attempt

From the authorized client, without administrative privileges:

```bash
ssh -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    -o NumberOfPasswordPrompts=1 \
    -o ConnectTimeout=5 \
    wazuh_lab_test@10.3.30.3
```

Intentionally enter an incorrect password for a non-production test account. The first connection requires host-key verification; do not disable it. The expected client outcome is `Permission denied`, not `Connection timed out`. Repeat only as needed to reach the laboratory thresholds. Five connections do not necessarily equal eight `5710` events: verify the actual rule matches because one connection may emit both `Invalid user` and `Failed password` records.

## Criteria for negative tests

A negative test is valid only if there is first a fresh antecedent for A1->V1 and then a login for the different pair is observed with correctly decoded fields. Absence of the final alert alone is insufficient. The independence test requires both pair confirmations, not only the absence of fan-out/fan-in.

Synthetic tests should be kept in `wazuh-logtest` sessions separate from real results. Do not add fabricated records to `auth.log` or custom logs to simulate evidence.

## Limitations that should remain documented

The `ignore=60` behavior, the outer `ssh_pair_confirmed` group, and interaction with `120936` must be interpreted together with scanning detection and the confirmed SSH pair. Waiting 70 seconds and increasing a threshold isolates the tests, but it does not demonstrate interference-free correlation under simultaneous traffic.
