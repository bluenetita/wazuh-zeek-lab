# Scanning Log Samples

`scanning-sanitized-samples.log` contains one reduced example per current scanning event type.

The examples use the current field name `src_ip`. Some older raw test logs used `scanner_ip`; those old records were intentionally not copied unchanged because the current Wazuh correlation rules match on `src_ip`.

These samples are for documentation and `wazuh-logtest`-style validation only. They are not a replacement for the original private telemetry archive.
