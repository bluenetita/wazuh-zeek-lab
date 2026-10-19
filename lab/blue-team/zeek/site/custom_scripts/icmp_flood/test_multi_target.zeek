# For a SECOND Zeek instance, or for offline captures with two destinations.
# Do not @load this file into the currently deployed ZeekControl instance.
@load ./icmp_flood.zeek
# Historical v1.5 PCAP regression: disable mirror dedup to reproduce raw counts.
redef ICMPFlood::dedup_mode = "off";
redef ICMPFlood::monitored_targets = { 10.3.30.3, 10.3.20.2 };
redef ICMPFlood::log_path = "icmp_flood_multi";
redef ICMPFlood::metrics_path = "icmp_flood_multi_metrics";
redef ICMPFlood::metrics_enabled = T;
redef ICMPFlood::window_length = 5sec;
redef ICMPFlood::threshold_packets = 500;
redef ICMPFlood::alert_cooldown = 30sec;
redef LogAscii::use_json = T;
