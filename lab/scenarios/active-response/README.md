# RouterOS Active Response

Automated containment scenario in which Wazuh can add the source IP from an alert to the RouterOS `Quarantine` address list over SSH using a dedicated key.

## Implementation

Script:

```text
blue-team/wazuh/active-response/routeros_quarantine.py
```

Publishable configuration template:

```text
blue-team/wazuh/active-response/routeros.conf.example
```

The script:

1. reads the Active Response message from `stdin`;
2. accepts `command=add`;
3. extracts `parameters.alert.data.src_ip`;
4. validates the address;
5. uses non-interactive SSH to RouterOS;
6. adds the IP to `Quarantine` if it is not already present;
7. removes matching connections from connection tracking;
8. records the result in `active-responses.log`.

The private key and the real router configuration are not versioned.

## State of the published configuration

In the included `manager/ossec.conf`, the `quarantine-routeros` command is defined, but the corresponding `<active-response>` block is commented out. Copying the repository files **does not enable** quarantine in the laboratory.

## Observed RouterOS policy

The campaign snapshot contains rules dedicated to the `Quarantine` list together with exceptions for Wazuh traffic. FastTrack appears before the quarantine drops in the historical snapshot, so rule order must be reassessed before using this configuration as a production policy.

The address list alone does not block traffic; containment depends on the actual firewall rules.

## OFF/ON validation

Campaign: [`../../evidence/routeros-ar/2026-10-01/README.md`](../../evidence/routeros-ar/2026-10-01/README.md).

| Mode | Runs | AR invocation | Quarantine | Probe blocked |
|---|---:|---:|---:|---:|
| OFF | 5 | 0/5 | 0/5 | 0/5 |
| ON | 5 | 5/5 | 5/5 | 5/5 |

From the campaign timestamps:

- mean `T_AR`: approximately **0.358 s** from the Wazuh alert to the logged completion of the response;
- mean `T_C`: approximately **36.744 s** from the coordinator GO signal to containment observed by the probe.

The two metrics use different time origins and must not be compared as though they measured the same segment of the pipeline. `T_C` includes human trigger latency, polling, and probe timeout.

The probe verified the flow `10.3.20.2 -> 10.2.0.2:22`; it does not demonstrate blocking of every protocol or all pre-existing connections.

## Cleanup

Quarantine removal during the campaign was explicitly performed by the coordinator. The published script does not implement an equivalent automatic rollback on `command=delete`.

## Security

The published version is a laboratory baseline. Before operational use, review at least the management allowlist, quarantine duration, IPv6 behavior, FastTrack/firewall ordering, exact connection-removal selection, and rollback strategy.
