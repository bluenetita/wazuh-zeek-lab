# ServerDB Command-Injection Validation

This scenario uses the intentionally unsafe inventory service on ServerDB to validate defensive monitoring and AppArmor confinement.

The application builds a shell command using untrusted input and executes it through the operating system. The public repository documents the vulnerability class and defensive observations but intentionally omits the exact exploitation string.

## Defensive observations

- in AppArmor complain mode, relevant policy violations can be logged without enforcement;
- in enforce mode, an operation that requires an ungranted shell execution is denied;
- the AppArmor/Audit event is collected by the ServerDB Wazuh Agent;
- Wazuh decoder/rules classify the resulting denial.

## Scope

Use only on the isolated laboratory service. Do not expose the intentionally unsafe service to untrusted networks.
