# Methodology

## Approach

The laboratory follows an evidence-driven workflow:

1. define a controlled security scenario;
2. identify expected network and endpoint observations;
3. collect raw telemetry;
4. implement decoders and low-level rules;
5. correlate independent evidence sources;
6. validate false-positive controls;
7. test response actions;
8. preserve reduced, sanitized evidence;
9. document limitations and reproducibility requirements.

## Detection design principles

### Separate observation from conclusion

A single connection, download, SUID execution, or traffic spike is not automatically malicious. Lower-level rules describe observations; higher-level correlation rules represent stronger conclusions.

### Prefer independent evidence

Reverse-shell confidence increases when Zeek network behavior agrees with an Auditd process connection from the target endpoint.

### Preserve event order alternatives

Network and endpoint events may reach Wazuh in different orders. Correlation chains therefore support alternative sequences when required.

### Use controlled exclusions

Known local services, loopback addresses, expected DNS traffic, and approved destinations are excluded only when the exclusion is justified and documented.

## Validation

Each scenario should record:

- test date and environment state;
- source and target hosts;
- commands or actions at a safe descriptive level;
- expected Zeek, Auditd, and Wazuh events;
- actual rule IDs and alert levels;
- response result;
- false positives and visibility gaps;
- sanitized evidence references.

## Evidence handling

Do not publish complete logs or archives. Extract only the fields required to demonstrate the result and replace real values with placeholders where appropriate.

## Change control

Changes to schemas, decoder fields, Auditd keys, paths, rule IDs, network interfaces, or RouterOS list names must be reflected across configuration, scenario documentation, and evidence notes.
