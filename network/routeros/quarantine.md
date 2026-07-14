# RouterOS Automated Quarantine

RouterOS is the network-containment component of the reverse-shell response workflow.

## Components

- Wazuh Manager Active Response;
- `routeros_quarantine.py`;
- dedicated RouterOS user `wazuh-quarantine`;
- SSH public-key authentication;
- `Quarantine` firewall address list;
- firewall filter rules;
- connection tracking.

## Workflow

```text
High-confidence Wazuh movement alert
        |
        v
routeros_quarantine.py on Wazuh Manager
        |
        v
SSH to RouterOS 10.3.0.1
        |
        +--> Add victim IP to `Quarantine`
        +--> Remove source connection entries
        +--> Remove destination connection entries
        |
        v
Network isolation and reverse-shell interruption
```

## Account

The current laboratory account is:

```routeros
/user add comment="Wazuh quarantine automation" group=write name=wazuh-quarantine
```

It uses the built-in `write` group and currently has no source-address restriction. This accurately reflects the lab but is broader than a hardened least-privilege design.

## Runtime configuration

```ini
ROUTEROS_USER="wazuh-quarantine"
ROUTEROS_HOST="10.3.0.1"
ROUTEROS_SSH_KEY="/var/ossec/.ssh/routeros_quarantine"
QUARANTINE_LIST="Quarantine"
```

The real configuration and SSH material remain outside Git.

## Recovery

Quarantine removal is manual:

```routeros
/ip firewall address-list remove [find where list="Quarantine" address="VICTIM_IP"]
```

Restore connectivity only after investigation and remediation.

## Limitations

- no automatic expiry or rollback;
- no approval step;
- account permissions are broader than ideal;
- correctness depends on victim-IP extraction and firewall ordering;
- the workflow isolates the network but does not kill the endpoint process.
