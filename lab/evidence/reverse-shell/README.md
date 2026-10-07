# Evidence - Reverse Shell

This directory contains reduced evidence related to the reverse-shell scenario.

The OFF/ON runs also used to validate RouterOS containment are stored under:

```text
../routeros-ar/2026-10-01/
```

The historical negative control is stored under:

```text
2026-10-01-negative-control/
```

The OFF/ON campaign contains distinct UIDs, selected Zeek events, Wazuh alerts, and movement-v2 diagnostics. It is not presented as a complete capture of every custom log for every UID.

For detector interpretation, see [`../../scenarios/reverse-shell/README.md`](../../scenarios/reverse-shell/README.md). For containment, see [`../../scenarios/active-response/README.md`](../../scenarios/active-response/README.md).
