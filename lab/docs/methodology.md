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

The scanning package deliberately uses low thresholds for `address_scan` and `icmp_host_scan` in the current laboratory validation configuration. These values are useful for tests but can be noisy in a continuously monitored network.

### Preserve schema consistency

The current scanning schema uses `src_ip` as the scanner-source field. Older test logs that used `scanner_ip` must not be mixed into current correlation tests without normalization.

### Distinguish prevention from detection

AppArmor complain mode provides visibility without enforcing the policy. Enforce mode blocks operations not granted by the loaded profile. Wazuh reports the AppArmor decision; it does not itself enforce the application policy.

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
