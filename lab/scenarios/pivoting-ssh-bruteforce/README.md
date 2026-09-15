# Pivoting and SSH Authentication Scenario

This stage documents a later part of the laboratory chain in which access through a previously compromised path is used to reach an internal SSH service and generate repeated authentication attempts.

The public repository intentionally omits the exact port-forwarding and password-guessing commands.

## Current detection status

- attack-stage validation: part of the private lab workflow;
- dedicated custom pivot/port-forward detector: not included in this update;
- dedicated custom SSH brute-force correlation: not included in this update.

Document this stage as an observability/detection gap rather than claiming that the current custom rules detect it.

## Defensive research direction

A future implementation can evaluate Zeek SSH telemetry, host authentication logs, Wazuh authentication rules, source/session context, rate thresholds, and correlation with the earlier compromise chain.
