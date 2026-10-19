# Methodology

## Evidence-driven workflow

The laboratory follows a repeatable detection-engineering process:

1. define an authorized scenario and expected behavior;
2. identify the required network and endpoint observations;
3. collect raw telemetry privately;
4. implement parsers/decoders and low-level rules;
5. correlate independent or temporally related evidence;
6. tune thresholds and exclusions;
7. validate defensive controls and response behavior;
8. preserve only reduced/sanitized evidence for publication;
9. document limitations, false positives, and reproducibility requirements.

## Detection design principles

### Separate observation from conclusion

A single connection, scan-like pattern, download, privileged execution, AppArmor denial, or traffic-volume spike is not automatically malicious. Lower-level rules describe observations; correlation and context produce stronger conclusions.

### Prefer independent evidence when available

Reverse-shell confidence increases when Zeek network behavior agrees with Auditd connection/process context. Post-compromise scanning confidence increases when scanning follows an earlier compromise signal from the same host.

### Treat thresholds as environment-specific

In the checked-in Zeek scanning scripts, `address_scan` uses 20 unique targets / 60 s and `icmp_host_scan` uses 2 unique targets / 60 s. The latter is intentionally aggressive for laboratory validation. The separate ICMP **Flood** detector is **not** a host-scanning classifier: v1.5 counted 500 raw mirror observations/5 s, while final v1.7-rc2 `enforce` counts 500 **heuristically distinct** Echo Request observations/5 s in configured protected subnets. These threshold settings are laboratory-specific, not production baselines.

### Preserve schema consistency

The current scanning schema uses `src_ip` as the scanner-source field. Older test logs that used `scanner_ip` must not be mixed into current correlation tests without normalization.

### Distinguish prevention from detection

AppArmor complain mode provides visibility without enforcing the policy. Enforce mode blocks operations not granted by the loaded profile. Wazuh reports the AppArmor decision; it does not itself enforce the application policy.

### Compare fixed vs sliding windows fairly

For ICMP Flood v1.5, the boundary regression used the **same** PCAP for the old fixed-window and new sliding-window detectors, with threshold 500 / five seconds. The old detector produced no alert when its adjacent windows contained 366 + 436 observations; the new detector produced one alert when its rolling window contained at least 500. This is a confirmed *scenario-specific* false negative of v1.4, **not** an empirical false-negative rate across attacks.

Report **raw mirror observations** for historical v1.5 and **estimated distinct** counts for v1.7 separately. Neither proves physical packet uniqueness; the TTL pairing is specific to the tested path. Source IP remains unverified if spoofing is possible. Early pre-NTP cross-VM timing samples are invalid; after NTP verification, report single-run Zeek-to-Wazuh timestamp differences with uncertainty and without calling them pure network latency.

## Scenario validation record

Each scenario should record:

- date/environment state;
- participating systems;
- defensive objective;
- expected Zeek/Auditd/AppArmor/Wazuh events;
- decoder and rule IDs;
- actual alert levels;
- false positives and tuning decisions;
- response result, when applicable;
- sanitized evidence references;
- known observability gaps.

## Evidence handling

Raw evidence may be retained privately for engineering and troubleshooting, but the public repository should contain only the minimum fields required to demonstrate a result. Do not publish complete Auditd logs, rotated scanning archives, full PCAPs, credentials, signed webhooks, or volatile response archives.

## Change control

Changes to event schemas, decoder fields, Auditd keys, AppArmor profiles, custom-log paths, rule IDs, network interfaces, IP addresses, thresholds, or RouterOS list names must be reflected across configuration, documentation, scenarios, and evidence notes.
