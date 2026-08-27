# Zeek Custom Log Rotation

This directory contains the `logrotate` policy for logs written below `/var/log/zeek-custom/`.

The policy should:

- rotate logs frequently enough to protect disk space;
- compress historical files;
- retain only the period required by the laboratory;
- preserve ownership and permissions expected by Zeek and the Wazuh Agent;
- avoid rotating a file in a way that prevents further writes.

Validate a policy with:

```bash
sudo logrotate -d /etc/logrotate.d/zeek-custom
```

Force a controlled test with:

```bash
sudo logrotate -f /etc/logrotate.d/zeek-custom
```

Do not commit rotated production logs.
