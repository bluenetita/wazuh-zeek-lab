# ServerDB

ServerDB is the controlled server target used by the current AppArmor scenario.

## Role

- hosts the isolated inventory-service test application;
- sends system and Linux Audit/AppArmor events to the Wazuh Manager;
- provides a target for network-reconnaissance validation observed by Zeek;
- demonstrates the difference between visibility in AppArmor complain mode and prevention in enforce mode.

## Relevant repository paths

```text
infrastructure/server-db/vulnerable-service/
blue-team/apparmor/
blue-team/wazuh/agent-configs/server-db-agent-ossec.conf
blue-team/wazuh/decoders/001_apparmor_decoder.xml
blue-team/wazuh/rules/006_app_armor.xml
```

## Publication notes

Do not commit the compiled application binary, credentials, raw Auditd logs, or any production-like data. The service exists only for the isolated laboratory.
