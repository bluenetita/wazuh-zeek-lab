# AppArmor Mitigation Scenario

## Objective

Compare the same unsafe application behavior while the ServerDB inventory-service profile is in complain mode and enforce mode.

## Expected behavior

### Complain mode

Policy violations are recorded for analysis, but the profile does not enforce denial solely because it is in complain mode.

### Enforce mode

Operations not granted by the profile are denied. The supplied laboratory evidence includes a denied shell-execution attempt for the inventory-service profile. Wazuh rule `130920` classifies blocked shell execution when the required decoded fields match.

## Defensive validation

1. confirm AppArmor is loaded for the inventory service;
2. confirm ServerDB sends `/var/log/audit/audit.log` to Wazuh;
3. verify decoder `apparmor_audit`;
4. verify base rule `130900`;
5. verify the relevant specialized AppArmor rule;
6. compare complain/enforce results;
7. return the service/profile to the intended final lab state.

## Evidence

See `evidence/apparmor/apparmor-shell-denied-sanitized.log`.
