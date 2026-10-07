# Inventory service - servicefix source and unit

The [inventario.c source](inventario.c) is a byte-for-byte copy of the `inventario_service_fixed.c` file supplied with the AppArmor servicefix campaign. SHA-256:

```text
30a03bf127db6c7c02fd84c3bbdf4cf1886daff362c8b48e00975656696c4ded
```

This matches `service_hashes.txt` from the campaign. The published filename reflects `/opt/inventario_service/inventario.c` on the VM; the program itself has not been rewritten.

This variant handles clients in child processes, uses `MSG_NOSIGNAL`, and handles `SIGPIPE` to reduce the impact of client disconnects on the parent process. **Servicefix does not mean that the command-injection vulnerability was fixed**: the `system()` call on user-controlled input remains intentionally vulnerable. The `verifica_login()` function exists but is not called from the `main`/`handle_client` path in this version. Do not deploy this service on production or Internet-exposed hosts.

The supplied [systemd unit](inventario-terminale.service) is unchanged: `User=inv-user`, `WorkingDirectory=/opt/inventario_service`, `Restart=always`, and `AmbientCapabilities=CAP_NET_BIND_SERVICE`. A comment mentioning `www-data` does not change the effective service user. The VM binary and `utenti.txt` with real credentials are not included.

To compile locally from the source directory without starting the service:

```bash
cc -Wall -Wextra -O2 inventario.c -o inventario_c
```

This command creates a local binary and does not install the service. The hash of a newly compiled binary depends on the toolchain and is not expected to match the historical binary. No installation or network execution is performed by the repository update package. Initial `products/` data is not included; a minimal reconstruction procedure would need to be documented before claiming identical service reproducibility.

[AppArmor profile](../../../blue-team/apparmor/profiles/opt.inventario_service.inventario_c) - [Ten final servicefix runs](../../../evidence/apparmor/2026-10-servicefix/README.md).
