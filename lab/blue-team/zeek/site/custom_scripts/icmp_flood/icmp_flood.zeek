@load base/frameworks/logging
@load ./dedup

# ICMP Flood detector v1.7-rc2 (experimental) -- EXACT sliding window.
# Added optional automatic tracking of destination IPv4 addresses in explicitly
# configured protected CIDRs, with inactive per-target state expiration.
# By default the detector still counts mirrored observations; duplicate
# candidates are tracked separately in observe mode. Optional enforce mode
# counts heuristic unique estimates, NOT proven physical packets.
# Per target it stores no more than threshold_packets timestamps (ring).

module ICMPFlood;

export {
    redef enum Log::ID += { LOG, METRICS_LOG };

    # Backward-compatible static target set (used by existing v1.5 captures).
    const monitored_targets: set[addr] = { 10.3.30.3 } &redef;

    # Disabled by default to preserve the behavior of existing test overrides.
    # The dedicated config.zeek policy enables this for the protected lab VLANs.
    const auto_monitor_subnets: bool = F &redef;
    const monitored_networks: set[subnet] = {
        10.3.10.0/24,
        10.3.20.0/24,
        10.3.30.0/24
    } &redef;
    # Applies to static and subnet selection; no exclusions by default.
    const excluded_targets: set[addr] = {} &redef;

    # Release per-destination ring state after a prolonged period of silence.
    # Should be substantially larger than window_length and alert_cooldown.
    const target_idle_timeout: interval = 10min &redef;
    const log_path: string = "/var/log/zeek-custom/icmp_flood" &redef;
    const metrics_path: string = "/var/log/zeek-custom/icmp_flood_metrics" &redef;
    const metrics_enabled: bool = F &redef;

    const window_length: interval = 5sec &redef;
    # threshold_packets MUST be >= 1. Memory O(threshold_packets * targets).
    const threshold_packets: count = 500 &redef;
    const alert_cooldown: interval = 30sec &redef;

    # Existing Wazuh 100940 fields are retained; new fields are additive.
    # TTL decrement pairing is a topology-aware HEURISTIC, not proof of uniqueness.
    # observed_pps is a NOMINAL rate: threshold_packets / window_length.
    type Info: record {
        ts: time &log;
        event_type: string &log;
        dest_ip: addr &log;
        observed_packets: count &log;
        window_seconds: double &log;
        observed_pps: double &log;
        threshold_packets: count &log;
        detection_reason: string &log;
        source_attribution: string &log;
        observation_scope: string &log;
        alert_phase: string &log;
        threshold_elapsed_seconds: double &log;
        threshold_trigger_pps: double &log;
        dedup_mode: string &log;
        counting_basis: string &log;
        dedup_match_policy: string &log;
        raw_observations_in_diagnostic_window: count &log;
        estimated_unique_in_diagnostic_window: count &log;
        duplicate_candidates_in_diagnostic_window: count &log;
    };

    # Fixed windows remain ONLY for recording comparable diagnostic metrics.
    # Detection is independent of those boundaries.
    type MetricsInfo: record {
        ts: time &log;
        window_start: time &log;
        dest_ip: addr &log;
        observed_packets: count &log;
        window_seconds: double &log;
        actual_observation_seconds: double &log;
        echo_span_seconds: double &log;
        window_complete: bool &log;
        observed_pps: double &log;
        threshold_packets: count &log;
        observation_scope: string &log;
        threshold_reached: bool &log;
        threshold_elapsed_seconds: double &log;
        threshold_trigger_pps: double &log;
        alert_emitted: bool &log;
        cooldown_suppressed: bool &log;
        fixed_window_threshold_reached: bool &log;
        detection_window_type: string &log;
        dedup_mode: string &log;
        counting_basis: string &log;
        dedup_match_policy: string &log;
        estimated_unique_observations: count &log;
        duplicate_candidates: count &log;
    };
}

# Sliding-window ring. The next slot points to the oldest retained timestamp
# once ring_fill[dst] == threshold_packets.
global ring_times: table[addr, count] of time;
global ring_fill: table[addr] of count;

# Expiration is keyed by the destination, not by each timestamp independently.
# This prevents partially expired rings while a low-rate stream is active.
# The expiring ring_next_slot entry itself is removed by Zeek.
function expire_inactive_target(t: table[addr] of count, dst: addr): interval
    {
    local slot: count = 0;
    while ( slot < threshold_packets )
        {
        if ( [dst, slot] in ring_times )
            delete ring_times[dst, slot];
        ++slot;
        }

    if ( dst in ring_fill )
        delete ring_fill[dst];

    return 0sec;
    }

global ring_next_slot: table[addr] of count
    &write_expire=target_idle_timeout
    &expire_func=expire_inactive_target;

# Each destination maintains its own ring and separate cooldown.
# An explicit set of protected CIDRs limits the state cardinality.
function should_monitor_target(dst: addr): bool
    {
    if ( dst in excluded_targets )
        return F;

    if ( dst in monitored_targets )
        return T;

    if ( auto_monitor_subnets && dst in monitored_networks )
        return T;

    return F;
    }

# Fixed-window diagnostics only: a separate timer for each monitored target.
global packet_counts: table[addr] of count;
global window_starts: table[addr] of time;
global last_echo_times: table[addr] of time;
global sliding_hit_windows: set[addr];
global emitted_windows: set[addr];
global suppressed_windows: set[addr];
global window_trigger_elapsed: table[addr] of double;
# Diagnostics are fixed-window COUNTS and are never represented as exact
# rolling-window totals. In observe mode these do not affect detection.
global estimated_unique_counts: table[addr] of count;
global duplicate_candidate_counts: table[addr] of count;

# Shared per-target cooldown: independent from any fixed-window timer.
global last_alert: table[addr] of time &write_expire = 1hr;

event zeek_init() &priority=5
    {
    Log::create_stream(ICMPFlood::LOG,
                       [$columns=Info, $path=log_path]);
    Log::create_stream(ICMPFlood::METRICS_LOG,
                       [$columns=MetricsInfo, $path=metrics_path]);
    }

function process_sliding_hit(dst: addr, now: time, span: interval)
    {
    add sliding_hit_windows[dst];

    local elapsed = interval_to_double(span);
    if ( dst !in window_trigger_elapsed )
        window_trigger_elapsed[dst] = elapsed;

    # No repeated alert before cooldown expires, but sustained traffic can
    # generate another alert after it expires without resetting the ring.
    if ( dst in last_alert && now - last_alert[dst] < alert_cooldown )
        {
        add suppressed_windows[dst];
        return;
        }

    local trigger_pps = 0.0;
    if ( elapsed > 0.0 )
        trigger_pps = count_to_double(threshold_packets) / elapsed;

    local basis = "raw_mirror_observations";
    local scope = "mirrored_traffic_not_deduplicated";
    if ( dedup_mode == "enforce" )
        {
        basis = "estimated_unique_echo_requests";
        scope = "mirrored_traffic_heuristic_deduplication";
        }

    Log::write(ICMPFlood::LOG,
        [
            $ts=now,
            $event_type="icmp_flood_suspected",
            $dest_ip=dst,
            $observed_packets=threshold_packets,
            $window_seconds=interval_to_double(window_length),
            $observed_pps=count_to_double(threshold_packets) / interval_to_double(window_length),
            $threshold_packets=threshold_packets,
            $detection_reason="destination_echo_sliding_window_threshold",
            $source_attribution="unverified",
            $observation_scope=scope,
            $alert_phase="sliding_threshold_crossed",
            $threshold_elapsed_seconds=elapsed,
            $threshold_trigger_pps=trigger_pps,
            $dedup_mode=dedup_mode,
            $counting_basis=basis,
            $dedup_match_policy="ttl_decrement_one_to_one",
            $raw_observations_in_diagnostic_window=packet_counts[dst],
            $estimated_unique_in_diagnostic_window=estimated_unique_counts[dst],
            $duplicate_candidates_in_diagnostic_window=duplicate_candidate_counts[dst]
        ]);

    last_alert[dst] = now;
    add emitted_windows[dst];
    }

event icmp_flood_window_end(dst: addr)
    {
    if ( dst !in packet_counts )
        return;

    local n = packet_counts[dst];
    local first_ts = window_starts[dst];
    local last_echo_ts = last_echo_times[dst];
    local now = network_time();
    local win_sec = interval_to_double(window_length);

    if ( metrics_enabled )
        {
        local span = 0.0;
        if ( dst in window_trigger_elapsed )
            span = window_trigger_elapsed[dst];

        local trigger_pps = 0.0;
        if ( span > 0.0 )
            trigger_pps = count_to_double(threshold_packets) / span;

        local basis = "raw_mirror_observations";
        local scope = "mirrored_traffic_not_deduplicated";
        if ( dedup_mode == "enforce" )
            {
            basis = "estimated_unique_echo_requests";
            scope = "mirrored_traffic_heuristic_deduplication";
            }

        Log::write(ICMPFlood::METRICS_LOG,
            [
                $ts=now,
                $window_start=first_ts,
                $dest_ip=dst,
                $observed_packets=n,
                $window_seconds=win_sec,
                $actual_observation_seconds=interval_to_double(now-first_ts),
                $echo_span_seconds=interval_to_double(last_echo_ts-first_ts),
                $window_complete=(now-first_ts >= window_length),
                $observed_pps=count_to_double(n)/win_sec,
                $threshold_packets=threshold_packets,
                $observation_scope=scope,
                $threshold_reached=(dst in sliding_hit_windows),
                $threshold_elapsed_seconds=span,
                $threshold_trigger_pps=trigger_pps,
                $alert_emitted=(dst in emitted_windows),
                $cooldown_suppressed=(dst in suppressed_windows),
                $fixed_window_threshold_reached=(n >= threshold_packets),
                $detection_window_type="sliding_exact",
                $dedup_mode=dedup_mode,
                $counting_basis=basis,
            $dedup_match_policy="ttl_decrement_one_to_one",
                $estimated_unique_observations=estimated_unique_counts[dst],
                $duplicate_candidates=duplicate_candidate_counts[dst]
            ]);
        }

    delete packet_counts[dst];
    if ( dst in estimated_unique_counts )
        delete estimated_unique_counts[dst];
    if ( dst in duplicate_candidate_counts )
        delete duplicate_candidate_counts[dst];
    delete window_starts[dst];
    delete last_echo_times[dst];
    if ( dst in sliding_hit_windows )
        delete sliding_hit_windows[dst];
    if ( dst in emitted_windows )
        delete emitted_windows[dst];
    if ( dst in suppressed_windows )
        delete suppressed_windows[dst];
    if ( dst in window_trigger_elapsed )
        delete window_trigger_elapsed[dst];
    }

event icmp_echo_request(c: connection, info: icmp_info,
                        id: count, seq: count, payload: string)
    {
    if ( info$v6 )
        return;

    local dst = c$id$resp_h;
    if ( ! should_monitor_target(dst) )
        return;

    local now = network_time();

    # Fixed diagnostic windows never influence the sliding decision.
    if ( dst !in packet_counts )
        {
        packet_counts[dst] = 0;
        estimated_unique_counts[dst] = 0;
        duplicate_candidate_counts[dst] = 0;
        window_starts[dst] = now;
        schedule window_length { icmp_flood_window_end(dst) };
        }
    ++packet_counts[dst];
    last_echo_times[dst] = now;

    local duplicate_candidate = F;
    if ( dedup_mode != "off" )
        duplicate_candidate = echo_duplicate_candidate(c, dst, info$ttl, id,
                                                       seq, payload, now);

    if ( duplicate_candidate )
        ++duplicate_candidate_counts[dst];
    else
        ++estimated_unique_counts[dst];

    # Observe is non-invasive. Only enforce removes a likely mirror copy from
    # the exact sliding detection ring. Wazuh rule 100940 stays unchanged.
    if ( dedup_mode == "enforce" && duplicate_candidate )
        return;

    # Store just the most recent threshold_packets observation timestamps.
    if ( dst !in ring_next_slot )
        {
        ring_next_slot[dst] = 0;
        ring_fill[dst] = 0;
        }

    local slot = ring_next_slot[dst];
    ring_times[dst, slot] = now;
    if ( ring_fill[dst] < threshold_packets )
        ++ring_fill[dst];

    ++slot;
    if ( slot >= threshold_packets )
        slot = 0;
    ring_next_slot[dst] = slot;  # Refresh per-destination idle expiration.

    if ( ring_fill[dst] < threshold_packets )
        return;

    # After insertion, 'slot' points to the oldest of the last K packets.
    local oldest = ring_times[dst, slot];
    local span = now - oldest;

    # A precise half-open 5-second sliding window: [now-5sec, now].
    # Equal-to-5sec is excluded, matching the tcpdump/awk validation.
    if ( span < 0sec || span >= window_length )
        return;

    process_sliding_hit(dst, now, span);
    }
