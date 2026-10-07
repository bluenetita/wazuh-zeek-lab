# ServerDB

`ServerDB` is an internal server on VLAN 30. Originally documented mainly as a PostgreSQL database server, in the final laboratory state it also hosts the inventory service used by the AppArmor scenario and acts as victim V1 in SSH Endpoint Normalizer validation.

## Network

| Field | Value |
|---|---|
| Name | `ServerDB` |
| IP | `10.3.30.3/24` |
| VLAN | 30 - Server |
| Gateway | `10.3.30.1` |
| SSH role | V1 |

`ServerDB2` (`10.3.30.4`) is a clone used as V2 in multi-victim SSH tests. Its complete configuration does not need to be duplicated in the repository.

## Services

### PostgreSQL

The server retains its role as an internal database system. PostgreSQL configuration files and logs should be published only after sanitization.

### Inventory service

The [`inventario-service/`](inventario-service/README.md) directory contains:

```text
inventario.c
inventario-terminale.service
README.md
```

The unit runs the service as `inv-user` and is the target of the AppArmor scenario.

## AppArmor

Profile:

```text
blue-team/apparmor/profiles/opt.inventario_service.inventario_c
```

The final `servicefix` series compares 5 complain runs with 5 enforce runs. The observed execution of `/usr/bin/dash` is allowed in complain mode and denied in enforce mode; the expected Wazuh alerts are present in the enforce runs. The service remains `active`, and the Main PID stays unchanged in the final series.

See [`../../scenarios/apparmor-mitigation/README.md`](../../scenarios/apparmor-mitigation/README.md).

## SSH Endpoint Normalizer

The host's Wazuh configuration collects `sshd` from `/var/log/auth.log` and appends:

```text
wazuh_dst_ip=$(host_ip)
```

The Manager decoder produces both `dstip` and `dest_ip`, allowing events directed at V1 to be distinguished from those directed at V2. This prevents correlation based only on the attacker when the same source host contacts multiple servers.

See [`../../scenarios/ssh-bruteforce/README.md`](../../scenarios/ssh-bruteforce/README.md).

## Relationship with Zeek

Traffic to or from ServerDB can be observed by the sensor when it crosses the mirror point. Zeek provides network metadata, while Wazuh provides authentication events, system logs, service events, and host-based telemetry.

## Files that must not be published

Do not version database credentials, real service-user files, private keys, complete logs, or unnecessary runtime data.
