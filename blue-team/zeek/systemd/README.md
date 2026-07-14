# Zeek systemd Service

This directory documents the systemd unit or override used to run Zeek on the sensor VM.

Useful commands:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now zeek
sudo systemctl status zeek --no-pager
sudo journalctl -u zeek -n 100 --no-pager
```

Before restarting the service, validate the Zeek configuration with:

```bash
sudo /opt/zeek/bin/zeekctl check
```

Keep service paths consistent with the installed Zeek prefix and local script locations.
