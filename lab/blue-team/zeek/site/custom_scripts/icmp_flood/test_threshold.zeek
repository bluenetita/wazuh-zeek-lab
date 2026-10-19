# Offline regression: no writes to operational Zeek logs.
@load ./icmp_flood.zeek
# Historical v1.5 PCAP regression: disable mirror dedup to reproduce raw counts.
redef ICMPFlood::dedup_mode = "off";
redef ICMPFlood::log_path = "icmp_flood";
redef ICMPFlood::metrics_path = "icmp_flood_metrics";
redef ICMPFlood::metrics_enabled = T;
redef ICMPFlood::window_length = 5sec;
redef ICMPFlood::threshold_packets = 500;
redef ICMPFlood::alert_cooldown = 30sec;
redef LogAscii::use_json = T;
