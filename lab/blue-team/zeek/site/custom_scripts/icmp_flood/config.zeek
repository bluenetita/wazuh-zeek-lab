# ICMP Flood site policy -- keep network-specific settings out of local.zeek
# Loaded after icmp_flood.zeek via __load__.zeek.
# Restrict auto-monitoring to the three approved laboratory VLANs.
redef ICMPFlood::auto_monitor_subnets = T;
redef ICMPFlood::monitored_networks = {
    10.3.10.0/24,
    10.3.20.0/24,
    10.3.30.0/24
};

# Optional target exclusions (uncomment and adapt if needed).
# redef ICMPFlood::excluded_targets = { 10.3.10.2 };

# Optional parameter overrides: leave unchanged to retain v1.5 behavior.
# redef ICMPFlood::threshold_packets = 500;
# redef ICMPFlood::window_length = 5sec;
# redef ICMPFlood::alert_cooldown = 30sec;
# redef ICMPFlood::target_idle_timeout = 10min;

# v1.7-rc2: STRICT TTL decrement + one-to-one match, under a 2ms window.
# The lab previously validated enforce mode; observe/off remain available.
# Keep enforce ONLY in the isolated laboratory until field-validated.
redef ICMPFlood::dedup_mode = "enforce";
redef ICMPFlood::dedup_window = 2msec;
redef ICMPFlood::dedup_max_signatures = 1024;
redef ICMPFlood::dedup_max_payload_bytes = 1024;
# Optional: publish per-destination 5-second diagnostic metrics. May be noisy.
# redef ICMPFlood::metrics_enabled = T;
