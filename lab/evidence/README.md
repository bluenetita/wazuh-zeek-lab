# Evidence

This directory contains **reduced and sanitized** evidence from results observed in the cyber range. Scenario documentation explains each test; `evidence/` retains the data required to support the result without publishing complete raw archives.

## Available evidence

| Directory | Contents |
|---|---|
| `reverse-shell/` | negative control and links to the reverse-shell campaign |
| `privilege-escalation/` | existing host-based evidence |
| `apparmor/2026-10-01-baseline/` | first complain/enforce series |
| `apparmor/2026-10-servicefix/` | final AppArmor series: 5 complain + 5 enforce |
| `routeros-ar/2026-10-01/` | 5 OFF + 5 ON runs, probes, selected alerts, and metrics |
| `ssh-bruteforce/` | Zeek/Wazuh samples and multi-host test matrix |

## Publication criteria

The repository may include:

- strictly necessary log excerpts;
- selected Wazuh alerts;
- reduced JSONL/TSV data;
- policy snapshots without secrets;
- aggregate metrics;
- validation notes.

The repository does not include:

- complete system logs;
- full PCAP captures;
- passwords, tokens, or keys;
- complete process dumps or journal exports;
- private router configurations;
- personal data or unnecessary runtime files.

## Relationship with `scenarios/`

```text
scenarios/ -> what was tested and how to interpret it
evidence/  -> what was observed during the tests
```

An alert absence is documented as a negative result only when the test also verified that the required prerequisites, IP pairs, and other necessary events were actually present.
