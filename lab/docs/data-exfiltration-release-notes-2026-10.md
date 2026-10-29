# Data Exfiltration — final module release notes (29 October 2026)

This documentation-only repository update publishes the **already validated** Zeek/Wazuh implementation for the controlled Data Exfiltration detection scenario. It does not deploy code to any VM.

## Final active components

- Zeek loads `@load custom_scripts/data_exfiltration` from `blue-team/zeek/site/local.zeek`. Six module files provide completed-TCP-flow volume estimation, one-minute windows, Adaptive training, rolling Slow detection and lab-specific policy.
- Zeek writes one JSON stream to `/var/log/zeek-custom/data_exfiltration.log`.
- ZeekVM Wazuh Agent collects that stream with one JSON `<localfile>` and PCRE2 selectors for eligible candidates and selected Slow continuation events.
- Wazuh Manager performs detection and temporal correlation using **only native XML rules** `111940–111948`. No Python correlator or scenario-specific Active Response is enabled.

## Publication-only cleanup

The former packet-based `data_exfiltration.zeek`, its `baseline_completed` / `possible_data_exfiltration` events and Manager rules `100913/100914` are retired. Remove the obsolete `.zeek` source after copying the updated folder: a file-copy overlay does not delete pre-existing files. Other, unrelated scenarios and Wazuh rules must remain unchanged.

## Test results

All ten targeted post-migration functional regression cases T01–T10 returned PASS on 28 October 2026, including two-source isolation, delayed baseline confirmation, Slow persistence and repeat correlation, multi-destination aggregation, log rotation and service restart recovery. The [validation report](data-exfiltration-validation-2026-10.md) and [reduced evidence table](../evidence/data-exfiltration/post-migration-validation-2026-10.tsv) record observed outcomes and caveats. Full logs and sensitive assets are not published.

## Scope

Detection of anomalies in *estimated* completed TCP flow payload volume does not prove data theft, identify the initiating endpoint process, or guarantee accurate counts on all capture paths. The rules were validated only in this Proxmox lab topology. Other endpoint Auditd/AppArmor scenarios remain separate.
