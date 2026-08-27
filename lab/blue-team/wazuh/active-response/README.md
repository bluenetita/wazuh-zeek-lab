# Wazuh Active Response

This directory contains two response components used by the reverse-shell scenario.

## Structure

```text
active-response/
├── agent/
│   └── collect_reverse_shell_evidence.sh
└── manager/
    ├── routeros_quarantine.py
    └── routeros.conf.example
```

## Evidence collection

`collect_reverse_shell_evidence.sh` runs on a monitored Linux endpoint and creates a compressed snapshot containing system information, interfaces, routes, process tree, sockets, logged-in users, recent logins, Auditd records, and journal records.

Runtime output is stored below:

```text
/var/ossec/active-response/evidence/
```

Raw archives must not be committed.

## RouterOS quarantine

`routeros_quarantine.py` runs on the Wazuh Manager. It:

1. reads the Wazuh Active Response JSON message from standard input;
2. accepts the `add` command;
3. extracts `parameters.alert.data.src_ip`;
4. validates the address;
5. loads `/etc/wazuh-routeros/routeros.conf`;
6. connects to RouterOS with SSH public-key authentication;
7. adds the address to the `Quarantine` address list if absent;
8. removes active connections where the address is source or destination;
9. writes the result to `/var/ossec/logs/active-responses.log`.

## Manager configuration note

The repository `ossec.conf` currently defines evidence collection with `timeout_allowed=yes`, `location=all`, and a timeout. The shell collector does not implement a rollback/delete operation, so this should be reviewed. A safer stateless design normally uses `timeout_allowed=no` and targets only the intended endpoint.

The RouterOS response is correctly designed as a non-timeout command executed at `server` location.

## Security

Keep these files outside Git:

```text
/etc/wazuh-routeros/routeros.conf
/var/ossec/.ssh/routeros_quarantine
/var/ossec/.ssh/known_hosts
/var/ossec/active-response/evidence/*.tar.gz
```

The current implementation provides evidence collection and network containment. It does not terminate the endpoint process directly.
