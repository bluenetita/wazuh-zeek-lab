# Data Exfiltration — Zeek active package

Six-file, completed-TCP-flow implementation validated in the lab after migration on **28 October 2026**. `@load custom_scripts/data_exfiltration` loads `__load__.zeek`; the individual modules are:

| File | Responsibility |
|---|---|
| `connection.zeek` | Internal-to-external TCP originator payload estimate from finalized flows |
| `window.zeek` | 60-s destination and host windows, source/destination attribution, quality gates and JSON output |
| `adaptive.zeek` | Cold-start vs trained profile threshold, delayed learning, eligibility checks |
| `slow.zeek` | Ten-window low-and-slow detection, continued-candidate and expiry tracking |
| `config.zeek` | Site policy and lab network configuration |
| `__load__.zeek` | Module load order |

The single output path is `/var/log/zeek-custom/data_exfiltration.log` (JSON). Wazuh Agent filters events and Wazuh Manager correlates them natively with rules `111940–111948`.

**Do not load** the former `data_exfiltration.zeek` legacy packet-based implementation alongside this package: remove this obsolete file from the repository during publication (copying files alone cannot delete it). Do not reintroduce experimental `*shadow*.zeek` modules or `exfil_shadow_*` event schemas.

Key settings: internal lab subnets `10.3.10.0/24`, `10.3.20.0/24`, `10.3.30.0/24`; `window_interval=1mins`; `minimum_training_windows=30`; 15-minute delayed learning; 4-MiB cold start; 1-MiB ready-state minimum; Slow 10 rolling windows / 8 active / 4-MiB aggregate / less than 1 MiB per window. Thresholds are for this test topology and are not production defaults.

The first window of a previously unseen source can be partial/ineligible. Restarting Zeek resets all in-memory baselines and rolling states. Source-specific training can be suspended by suspicious Adaptive/Slow detections. An estimated byte count must never be reported as confirmed received bytes.

For architecture, rules, results, limits, and smoke checks, see [`scenarios/data-exfiltration/README.md`](../../../../../scenarios/data-exfiltration/README.md) and [`docs/data-exfiltration-validation-2026-10.md`](../../../../../docs/data-exfiltration-validation-2026-10.md).
