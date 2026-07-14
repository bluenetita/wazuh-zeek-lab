# MikroTik RouterOS

RouterOS provides internal routing and the network-enforcement layer for Wazuh automated quarantine.

## Documentation

- [`interfaces.md`](interfaces.md)
- [`routing.md`](routing.md)
- [`vlans.md`](vlans.md)
- [`firewall-rules.md`](firewall-rules.md)
- [`quarantine.md`](quarantine.md)
- [`sanitized-config-notes.md`](sanitized-config-notes.md)

## Wazuh integration

The Wazuh Manager connects to RouterOS at `10.3.0.1` with the dedicated `wazuh-quarantine` account and SSH public-key authentication. The Active Response adds the victim address to the `Quarantine` address list and removes existing tracked connections involving that address.

The Python implementation is stored under [`../../blue-team/wazuh/active-response/manager/`](../../blue-team/wazuh/active-response/manager/).
