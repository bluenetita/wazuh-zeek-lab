# Slow exfiltration candidate detection: 10-window rolling TCP volume.
# Consumes finalized-flow windows, not packet timestamps.
# Synthetic idle windows advance state without representing sent bytes.
@load ./adaptive

module DataExfilSlow;

export {
    const enabled: bool = T &redef;
    const rolling_windows: count = 10 &redef;
    const minimum_active_windows: count = 8 &redef;
    const cumulative_threshold_bytes: count = 4194304 &redef;  # 4 MiB / 10 completed windows
    const per_window_ceiling_bytes: count = 1048576 &redef;     # each window < 1 MiB
    const maximum_interwindow_gap: interval = 90secs &redef;
    const minimum_window_span: interval = 50secs &redef;
    const maximum_window_span: interval = 70secs &redef;
    const maximum_host_profiles: count = 512 &redef;
    const maximum_destination_profiles: count = 4096 &redef;
    const profile_idle_expiry: interval = 35mins &redef;
    # Bound synthetic zero-window output and retire genuinely idle pairs.
    # Must exceed rolling_windows*window_interval in the standard configuration.
    const idle_tail_retirement: interval = 12mins &redef;
    const housekeeping_interval: interval = 10mins &redef;
    const output_path: string = "/var/log/zeek-custom/data_exfiltration.log" &redef;

    type SlowDecision: record {
        ts: time &log;
        event_type: string &log;
        scope: string &log;
        src_ip: addr &log;
        dest_ip: addr &log;
        destination_class: string &log;
        window_seconds: interval &log;
        sample_bytes: count &log;
        sample_eligible: bool &log;
        synthetic_idle_window: bool &log;
        profile_state: string &log;
        rolling_window_count: count &log;
        rolling_active_windows: count &log;
        rolling_payload_bytes: count &log;
        rolling_threshold_bytes: count &log;
        largest_window_bytes: count &log;
        slow_candidate: bool &log;
        candidate_active: bool &log;
        reason: string &log;
        current_window_top_dest_ip: addr &log;
        current_window_top_dest_share_percent: count &log;
        byte_basis: string &log;
        aggregation_scope: string &log;
        note: string &log;
    };
}

type WindowSample: record {
    ts: time;
    payload_bytes: count;
};

type SampleRing: vector of WindowSample;

type Profile: record {
    samples: SampleRing;
    next_slot: count;
    last_ts: time;
    last_observed_ts: time;  # updated only by real destination/host callbacks
    candidate_active: bool;
};

global host_profiles: table[addr] of Profile;
global destination_profiles: table[addr, addr] of Profile;
global prune_profiles: event();

function fresh_profile(ts: time): Profile
    {
    return [$samples=SampleRing(), $next_slot=0,
            $last_ts=ts, $last_observed_ts=ts, $candidate_active=F];
    }

function add_window(p: Profile, stamp: time, bytes: count): Profile
    {
    local sample: WindowSample = [$ts=stamp, $payload_bytes=bytes];
    if ( |p$samples| < rolling_windows )
        p$samples += sample;
    else
        {
        p$samples[p$next_slot] = sample;
        p$next_slot = (p$next_slot + 1) % rolling_windows;
        }
    p$last_ts = stamp;
    return p;
    }

function append_decision(rec: DataExfilSlow::SlowDecision)
    {
    local f = open_for_append(output_path);
    if ( ! active_file(f) )
        {
        Reporter::warning(fmt("DataExfilSlow: cannot open %s", output_path));
        return;
        }
    if ( ! write_file(f, fmt("%s\n", to_json(rec, T))) )
        Reporter::warning(fmt("DataExfilSlow: cannot write %s", output_path));
    close(f);
    }

function evaluate_window(
    stamp: time,
    src: addr,
    dst: addr,
    scope_name: string,
    window_span: interval,
    flows: count,
    bytes: count,
    eligible: bool,
    current_top_dest: addr,
    current_top_share: count,
    synthetic_idle: bool)
    {
    if ( ! enabled )
        return;

    # Invalid tuning must not trigger modulo-zero or false detections.
    if ( rolling_windows < 2 || minimum_active_windows > rolling_windows ||
         per_window_ceiling_bytes == 0 )
        {
        Reporter::warning("DataExfilSlow: invalid rolling-window configuration");
        return;
        }

    local capacity_ok = T;
    local existing = F;
    local p = fresh_profile(stamp);
    if ( scope_name == "host" )
        {
        if ( src in host_profiles )
            {
            p = host_profiles[src];
            existing = T;
            }
        else if ( |host_profiles| >= maximum_host_profiles )
            capacity_ok = F;
        }
    else
        {
        if ( [src, dst] in destination_profiles )
            {
            p = destination_profiles[src, dst];
            existing = T;
            }
        else if ( |destination_profiles| >= maximum_destination_profiles )
            capacity_ok = F;
        }

    # Duplicate callbacks in the same window cannot double count bytes.
    if ( existing && stamp <= p$last_ts )
        return;

    local span_ok = window_span >= minimum_window_span &&
                    window_span <= maximum_window_span;
    local valid = eligible && span_ok;
    local reset_due_to_gap = existing &&
                            stamp - p$last_ts > maximum_interwindow_gap;
    local was_active = p$candidate_active;
    local destination_class = "external_to_protected_scope";
    if ( scope_name == "host" )
        destination_class = "all_destinations";
    else if ( dst in DataExfilAdaptive::administrative_networks )
        destination_class = "administrative_ssh_vpn_network";
    local state = "warming";
    local reason = "collecting_consecutive_windows";
    local candidate = F;
    local active_windows: count = 0;
    local total: count = 0;
    local largest: count = 0;

    if ( ! capacity_ok )
        {
        state = "capacity_exceeded";
        reason = "profile_limit_reached";
        }
    else if ( ! valid )
        {
        # Fail closed for QUALITY: never learn from an invalid window, and
        # never bridge it into an otherwise apparently consecutive series.
        p = fresh_profile(stamp);
        state = "quality_excluded";
        reason = "window_not_eligible_or_incomplete";
        if ( was_active )
            reason = "candidate_state_reset_due_to_quality";
        }
    else if ( bytes >= per_window_ceiling_bytes )
        {
        # Individual high-volume windows belong to the Adaptive volume engine.
        p = fresh_profile(stamp);
        state = "non_slow_window";
        reason = "individual_window_at_or_above_ceiling";
        if ( was_active )
            reason = "candidate_state_reset_due_to_large_window";
        }
    else
        {
        if ( reset_due_to_gap )
            p = fresh_profile(stamp);
        p = add_window(p, stamp, bytes);

        for ( i in p$samples )
            {
            total += p$samples[i]$payload_bytes;
            if ( p$samples[i]$payload_bytes > 0 )
                active_windows += 1;
            if ( p$samples[i]$payload_bytes > largest )
                largest = p$samples[i]$payload_bytes;
            }

        if ( |p$samples| < rolling_windows )
            {
            if ( reset_due_to_gap )
                reason = "gap_reset_collecting_windows";
            }
        else
            {
            state = "ready";
            if ( active_windows < minimum_active_windows )
                reason = "insufficient_active_windows";
            else if ( total < cumulative_threshold_bytes )
                reason = "below_rolling_threshold";
            else if ( was_active && ! reset_due_to_gap )
                {
                p$candidate_active = T;
                reason = "candidate_continues_suppressed";
                }
            else
                {
                candidate = T;
                p$candidate_active = T;
                reason = "rolling_volume_above_threshold";
                }

            if ( reason == "insufficient_active_windows" ||
                 reason == "below_rolling_threshold" )
                {
                p$candidate_active = F;
                if ( was_active && synthetic_idle )
                    reason = "candidate_cleared_after_inactivity";
                }
            }
        }

    # Coordinated fail-closed baseline protection. A slow candidate from
    # EITHER scope conservatively suspends learning for its source host.
    if ( capacity_ok && p$candidate_active )
        DataExfilAdaptive::suspend_learning(src, stamp, "slow_rolling_candidate");

    # Zero-fill advances rolling time but never masquerades as REAL traffic.
    if ( ! synthetic_idle )
        p$last_observed_ts = stamp;

    # Save only tracked profiles. Invalid windows reset history to prevent
    # false positives later; the profile remains bounded to rolling_windows.
    if ( capacity_ok )
        {
        if ( scope_name == "host" )
            host_profiles[src] = p;
        else
            destination_profiles[src, dst] = p;
        }

    local result: DataExfilSlow::SlowDecision = [
        $ts=stamp,
        $event_type="exfil_slow_window_decision",
        $scope=scope_name,
        $src_ip=src,
        $dest_ip=dst,
        $destination_class=destination_class,
        $window_seconds=window_span,
        $sample_bytes=bytes,
        $sample_eligible=valid,
        $synthetic_idle_window=synthetic_idle,
        $profile_state=state,
        $rolling_window_count=|p$samples|,
        $rolling_active_windows=active_windows,
        $rolling_payload_bytes=total,
        $rolling_threshold_bytes=cumulative_threshold_bytes,
        $largest_window_bytes=largest,
        $slow_candidate=candidate,
        $candidate_active=p$candidate_active,
        $reason=reason,
        $current_window_top_dest_ip=current_top_dest,
        $current_window_top_dest_share_percent=current_top_share,
        $byte_basis="zeek_tcp_sequence_estimate",
        $aggregation_scope="flows_finalized_in_consecutive_windows_not_wire_time",
        $note="Slow-volume decision for Wazuh rule classification. Threshold fixed at 4 MiB / 10 valid 1-min windows; not an adaptive/behavioral proof. Host and destination can each generate a candidate."
    ];
    append_decision(result);
    }

event DataExfilWindow::host_window_ready(summary: DataExfilWindow::WindowInfo) &priority=10
    {
    evaluate_window(summary$ts, summary$src_ip, 0.0.0.0, "host",
                    summary$window_seconds, summary$flow_count,
                    summary$outbound_payload_bytes, summary$baseline_sample_eligible,
                    summary$top_dest_ip, summary$top_dest_share_percent, F);
    }

event DataExfilWindow::destination_window_ready(summary: DataExfilWindow::DestinationWindowInfo) &priority=10
    {
    evaluate_window(summary$ts, summary$src_ip, summary$dest_ip, "destination",
                    summary$window_seconds, summary$destination_flow_count,
                    summary$destination_payload_bytes, summary$baseline_sample_eligible,
                    summary$dest_ip,
                    (summary$destination_payload_bytes > 0 ? 100 : 0), F);
    }

# Zero-complete all previously observed destination profiles once the real
# destination callbacks for this tick have been evaluated. Missing destination
# rows are NOT evidence of new outbound payload: explicitly mark these samples
# as synthetic idle so readers can distinguish observed from zero-filled data.
# Collect keys before updating tables to avoid Zeek iterator invalidation.
event DataExfilWindow::window_tick_complete(stamp: time, span: interval) &priority=10
    {
    if ( ! enabled )
        return;

    local idle_pairs: set[addr, addr] = set();
    local retire_pairs: set[addr, addr] = set();

    for ( [s, d] in destination_profiles )
        {
        if ( destination_profiles[s, d]$last_ts < stamp )
            add idle_pairs[s, d];
        }

    for ( [s, d] in idle_pairs )
        {
        if ( [s, d] in destination_profiles )
            {
            local inactive_span = stamp - destination_profiles[s, d]$last_observed_ts;
            # Do not keep producing empty records forever. Once 12 minutes
            # have elapsed without a real flow, the 10-slot ring contains
            # only zeros and any candidate should already have cleared.
            if ( inactive_span > idle_tail_retirement &&
                 ! destination_profiles[s, d]$candidate_active )
                add retire_pairs[s, d];
            else
                {
                evaluate_window(stamp, s, d, "destination", span,
                                0, 0, T, d, 0, T);
                if ( [s, d] in destination_profiles &&
                     stamp - destination_profiles[s, d]$last_observed_ts > idle_tail_retirement &&
                     ! destination_profiles[s, d]$candidate_active )
                    add retire_pairs[s, d];
                }
            }
        }

    for ( [s, d] in retire_pairs )
        delete destination_profiles[s, d];
    }

# Periodic cleanup releases memory for destination pairs that stop appearing.
# Collect expired keys first; never delete during table iteration.
event prune_profiles()
    {
    local now = network_time();
    local expired_hosts: set[addr] = set();
    local expired_destinations: set[addr, addr] = set();

    for ( s in host_profiles )
        {
        if ( now - host_profiles[s]$last_ts > profile_idle_expiry )
            add expired_hosts[s];
        }
    for ( [s, d] in destination_profiles )
        {
        if ( now - destination_profiles[s, d]$last_ts > profile_idle_expiry )
            add expired_destinations[s, d];
        }
    for ( s in expired_hosts )
        delete host_profiles[s];
    for ( [s, d] in expired_destinations )
        delete destination_profiles[s, d];

    schedule housekeeping_interval { prune_profiles() };
    }

event zeek_init()
    {
    if ( enabled )
        schedule housekeeping_interval { prune_profiles() };
    }
