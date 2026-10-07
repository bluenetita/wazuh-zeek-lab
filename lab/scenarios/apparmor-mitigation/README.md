# AppArmor Mitigation - Inventory Service

Hardening scenario for the vulnerable service running on ServerDB using a dedicated AppArmor profile and a controlled comparison between complain and enforce modes.

## Components

- source: [`../../infrastructure/server-db/inventario-service/inventario.c`](../../infrastructure/server-db/inventario-service/inventario.c)
- systemd unit: [`../../infrastructure/server-db/inventario-service/inventario-terminale.service`](../../infrastructure/server-db/inventario-service/inventario-terminale.service)
- profile: [`../../blue-team/apparmor/profiles/opt.inventario_service.inventario_c`](../../blue-team/apparmor/profiles/opt.inventario_service.inventario_c)

The unit runs the service as `inv-user`, with working directory `/opt/inventario_service` and the capability required to bind the configured port.

## Method

The tests compare the same operation in two states:

```text
complain -> record the policy violation without blocking it
enforce  -> apply the policy and deny unauthorized behavior
```

Each run observes the profile state, AppArmor decision, Audit/SYSCALL record, service state, and availability check.

## Final `servicefix` series

Evidence: [`../../evidence/apparmor/2026-10-servicefix/README.md`](../../evidence/apparmor/2026-10-servicefix/README.md).

Results across 5 complain/enforce pairs:

| Mode | `/usr/bin/dash` | SYSCALL | Wazuh alert |
|---|---|---|---|
| complain | ALLOWED 5/5 | `success=yes`, `exit=0` | not used as evidence of blocking |
| enforce | DENIED 5/5 | `success=no`, `exit=-13` | `130920` in all 5 runs |

In the final series, the service remains `active`, the Main PID remains unchanged, and the local TCP check returns `rc=0` before and after in every run.

The availability check verifies systemd state and TCP reachability; it does not execute a complete application-menu transaction.

## Previous series

[`../../evidence/apparmor/2026-10-01-baseline/README.md`](../../evidence/apparmor/2026-10-01-baseline/README.md) retains an earlier series with consistent complain/enforce decisions but PID changes between checks. It is therefore not used to claim process continuity.

## Interpretation

The result demonstrates that the AppArmor policy can block the observed unauthorized execution while keeping the service available in the final test. It does not demonstrate coverage of every possible vector or establish the profile as a complete production policy.
