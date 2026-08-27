# RouterOS Routing

RouterOS routes traffic between internal laboratory segments and provides the path used by the Wazuh Manager for containment commands.

Document static and connected routes with destination, gateway, distance, and purpose. Verify the return route toward Wazuh Manager and ClientVM before enabling automatic quarantine.

Useful command:

```routeros
/ip route print detail
```
