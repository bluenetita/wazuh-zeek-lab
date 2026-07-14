# pfSense Sanitization Notes

Before publishing pfSense material, remove or replace:

- passwords and password hashes;
- API tokens and session identifiers;
- private keys and certificates;
- VPN pre-shared keys;
- public addresses and dynamic DNS credentials;
- serial numbers, unique IDs, and personal data.

Prefer focused documentation over a complete configuration export.
