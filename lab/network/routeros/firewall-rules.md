# RouterOS Firewall Rules

RouterOS enforces the automated containment policy through the `Quarantine` address list.

## Quarantine behavior

- Wazuh dynamically adds the victim IP to `Quarantine`.
- Firewall rules match traffic involving quarantined addresses.
- Existing connection-tracking entries are removed by `routeros_quarantine.py`.
- The reverse-shell session is therefore interrupted rather than waiting for timeout.

Quarantine rules must be evaluated before broad accept or FastTrack rules that could bypass the intended policy.

The exact sanitized commands belong in `config/quarantine-firewall.rsc`.

## Validation

```routeros
/ip firewall filter print detail where src-address-list="Quarantine"
/ip firewall filter print detail where dst-address-list="Quarantine"
/ip firewall filter print stats
/ip firewall address-list print detail where list="Quarantine"
```

Do not publish the current address-list members or live connection-tracking table.
