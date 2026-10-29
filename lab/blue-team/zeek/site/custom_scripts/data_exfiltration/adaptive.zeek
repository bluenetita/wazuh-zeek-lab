# Adaptive volume candidate detection from completed-flow windows.
# Delayed baseline confirmation prevents learning suspected exfiltration.
# Baseline history is memory-only and resets after Zeek restart/deploy.
# Quality-degraded windows never become confirmed candidates.
@load ./window

module DataExfilAdaptive;

export {
    const enabled: bool = T &redef;
    const administrative_networks: set[subnet] = { 10.8.0.0/24 } &redef;

    const minimum_training_windows: count = 30 &redef;
    const history_size: count = 60 &redef;
    const minimum_candidate_bytes: count = 1048576 &redef;
    const cold_start_candidate_bytes: count = 4194304 &redef;
    const max_training_sample_bytes: count = 2097152 &redef;
    const median_multiplier: count = 4 &redef;
    const p90_multiplier: count = 2 &redef;
    const max_host_profiles: count = 512 &redef;
    const max_destination_profiles: count = 4096 &redef;
    # 15-minute lookahead safely covers a 10-window slow sequence with up to
    # 90 seconds between accepted windows (9 * 90 seconds = 13.5 minutes).
    const delayed_learning_enabled: bool = T &redef;
    const learning_confirmation_delay: interval = 15mins &redef;
    const learning_suspension_after_candidate: interval = 10mins &redef;
    const max_pending_samples_per_profile: count = 24 &redef;
    const output_path: string = "/var/log/zeek-custom/data_exfiltration.log" &redef;

    type DecisionInfo: record {
        ts: time &log;
        event_type: string &log;
        scope: string &log;
        src_ip: addr &log;
        dest_ip: addr &log;
        destination_class: string &log;
        window_seconds: interval &log;
        flow_count: count &log;
        sample_bytes: count &log;
        sample_eligible: bool &log;
        profile_samples_before: count &log;
        profile_state: string &log;
        baseline_median_bytes: count &log;
        baseline_p90_bytes: count &log;
        threshold_bytes: count &log;
        adaptive_candidate: bool &log;
        # Not an alert: suspicious estimated volume in an untrusted window.
        quality_degraded_volume_candidate: bool &log;
        principal_dest_ip: addr &log;
        principal_dest_bytes: count &log;
        principal_dest_share_percent: count &log;
        attribution_complete: bool &log;
        quality_gap_flows: count &log;
        quality_non_sf_flows: count &log;
        quality_missing_estimates: count &log;
        reason: string &log;
        baseline_sample_added: bool &log;
        baseline_sample_queued: bool &log;
        baseline_pending_count: count &log;
        learning_suspended: bool &log;
        byte_basis: string &log;
        note: string &log;
    };

    type BaselineAudit: record {
        ts: time &log;
        event_type: string &log;
        scope: string &log;
        src_ip: addr &log;
        dest_ip: addr &log;
        original_sample_ts: time &log;
        sample_bytes: count &log;
        sample_count: count &log;
        reason: string &log;
    };

    # Called synchronously by the slow rolling engine after a candidate is
    # detected. Host-wide suspension prevents cross-scope baseline poisoning.
    global suspend_learning: function(source: addr, stamp: time, trigger: string);
}

# Fixed memory footprint per profile: at most history_size samples.
type CountHistory: vector of count;
type BufferedSample: record {
    ts: time;
    payload_bytes: count;
};
type BufferedHistory: vector of BufferedSample;
type Profile: record {
    values: CountHistory;
    next_slot: count;
    pending: BufferedHistory;
};

global profiles_host: table[addr] of Profile;
global profiles_dest: table[addr, addr] of Profile;
# One conservatively shared hold per protected source. These values are
# network-time timestamps, not wall-clock deadlines.
global learning_suspended_until: table[addr] of time;

function fresh_profile(): Profile
    {
    return [$values=CountHistory(), $next_slot=0, $pending=BufferedHistory()];
    }

function add_sample(p: Profile, sample: count): Profile
    {
    if ( |p$values| < history_size )
        p$values += sample;
    else
        {
        p$values[p$next_slot] = sample;
        p$next_slot = (p$next_slot + 1) % history_size;
        }
    return p;
    }

# Percentiles are computed from a COPY: sorting must not change ring slots.
# This function is invoked only for nonempty profiles.
function percentile(p: Profile, percentile_level: count): count
    {
    local ordered_values: CountHistory = CountHistory();
    for ( idx in p$values )
        ordered_values += p$values[idx];
    if ( |ordered_values| == 0 )
        return 0;
    sort(ordered_values);
    local n = |ordered_values|;
    local selected_index = ((n - 1) * percentile_level) / 100;
    return ordered_values[selected_index];
    }

function write_decision(rec: DataExfilAdaptive::DecisionInfo)
    {
    local f = open_for_append(output_path);
    if ( ! active_file(f) )
        {
        Reporter::warning(fmt("DataExfilAdaptive: cannot open %s", output_path));
        return;
        }
    if ( ! write_file(f, fmt("%s\n", to_json(rec, T))) )
        Reporter::warning(fmt("DataExfilAdaptive: cannot write %s", output_path));
    close(f);
    }


# Writes structured confirmation/discard evidence independently of the
# per-window classification log, which must not claim early learning.
function write_baseline_audit(rec: DataExfilAdaptive::BaselineAudit)
    {
    local f = open_for_append(output_path);
    if ( ! active_file(f) )
        {
        Reporter::warning(fmt("DataExfilAdaptive: cannot open %s", output_path));
        return;
        }
    if ( ! write_file(f, fmt("%s\n", to_json(rec, T))) )
        Reporter::warning(fmt("DataExfilAdaptive: cannot write %s", output_path));
    close(f);
    }

function learning_is_suspended(source: addr, stamp: time): bool
    {
    return source in learning_suspended_until &&
           learning_suspended_until[source] >= stamp;
    }

function discard_pending(p: Profile, stamp: time, source: addr,
                         destination: addr, scope_name: string,
                         discard_reason: string): Profile
    {
    if ( |p$pending| > 0 )
        {
        local removed_bytes: count = 0;
        local removed_count = |p$pending|;
        for ( i in p$pending )
            removed_bytes += p$pending[i]$payload_bytes;
        local audit: DataExfilAdaptive::BaselineAudit = [
            $ts=stamp, $event_type="exfil_baseline_discard",
            $scope=scope_name, $src_ip=source, $dest_ip=destination,
            $original_sample_ts=stamp, $sample_bytes=removed_bytes,
            $sample_count=removed_count, $reason=discard_reason
        ];
        write_baseline_audit(audit);
        p$pending = BufferedHistory();
        }
    return p;
    }

# A conservative HOST-level quarantine, shared by the two scopes.
# It removes provisional samples across the protected source, including
# destination profiles whose handlers ran before the host-level detector.
# Keys are copied first: never modify Zeek table membership while iterating.
function suspend_learning(source: addr, stamp: time, trigger: string)
    {
    if ( ! delayed_learning_enabled )
        return;

    local hold_until = stamp + learning_suspension_after_candidate;
    if ( source !in learning_suspended_until ||
         learning_suspended_until[source] < hold_until )
        learning_suspended_until[source] = hold_until;

    if ( source in profiles_host )
        {
        local hp = profiles_host[source];
        hp = discard_pending(hp, stamp, source, 0.0.0.0,
                             "host", trigger);
        profiles_host[source] = hp;
        }

    local destination_keys: set[addr, addr] = set();
    for ( [s, d] in profiles_dest )
        {
        if ( s == source )
            add destination_keys[s, d];
        }
    for ( [s, d] in destination_keys )
        {
        if ( [s, d] in profiles_dest )
            {
            local dp = profiles_dest[s, d];
            dp = discard_pending(dp, stamp, s, d, "destination", trigger);
            profiles_dest[s, d] = dp;
            }
        }
    }

# Promote only samples whose conservative rolling hazard period has elapsed.
# This is called only at the explicit tick barrier, AFTER all slow decisions
# (including synthetic destination idle windows) have been processed.
function confirm_pending(p: Profile, stamp: time, source: addr,
                         destination: addr, scope_name: string): Profile
    {
    local waiting: BufferedHistory = BufferedHistory();
    for ( i in p$pending )
        {
        local sample = p$pending[i];
        if ( stamp - sample$ts >= learning_confirmation_delay )
            {
            p = add_sample(p, sample$payload_bytes);
            local audit: DataExfilAdaptive::BaselineAudit = [
                $ts=stamp, $event_type="exfil_baseline_commit",
                $scope=scope_name,
                $src_ip=source, $dest_ip=destination,
                $original_sample_ts=sample$ts,
                $sample_bytes=sample$payload_bytes,
                $sample_count=1,
                $reason="confirmed_after_rolling_horizon"
            ];
            write_baseline_audit(audit);
            }
        else
            waiting += sample;
        }
    p$pending = waiting;
    return p;
    }

# Exactly one call per completed window record. Nothing is automatically
# whitelisted: administrative networks get a classification label ONLY.
function evaluate_window(
    snapshot_ts: time,
    source: addr,
    destination: addr,
    scope_name: string,
    window_span: interval,
    flows: count,
    bytes_sent: count,
    eligible: bool,
    principal_dest: addr,
    principal_bytes: count,
    principal_share_percent: count,
    attribution_complete: bool,
    gap_flows: count,
    non_sf_flows: count,
    missing_estimates: count)
    {
    if ( ! enabled )
        return;

    local p: Profile = fresh_profile();
    local capacity_ok = T;
    local destination_class = "external_to_protected_scope";

    if ( scope_name == "host" )
        {
        destination_class = "all_destinations";
        if ( source in profiles_host )
            p = profiles_host[source];
        else if ( |profiles_host| >= max_host_profiles )
            capacity_ok = F;
        }
    else
        {
        if ( destination in administrative_networks )
            destination_class = "administrative_ssh_vpn_network";
        if ( [source, destination] in profiles_dest )
            p = profiles_dest[source, destination];
        else if ( |profiles_dest| >= max_destination_profiles )
            capacity_ok = F;
        }

    local samples_before = |p$values|;
    local ready = samples_before >= minimum_training_windows;
    local median_bytes: count = 0;
    local p90_bytes: count = 0;
    local threshold_bytes: count = cold_start_candidate_bytes;
    local is_candidate = F;
    local degraded_volume = F;
    local added = F;
    local queued = F;
    local changed = F;
    local suspended = delayed_learning_enabled &&
                      learning_is_suspended(source, snapshot_ts);
    local status = "training";
    local reason = "collecting_baseline";

    if ( ready )
        {
        status = "ready";
        median_bytes = percentile(p, 50);
        p90_bytes = percentile(p, 90);
        threshold_bytes = minimum_candidate_bytes;
        if ( median_bytes * median_multiplier > threshold_bytes )
            threshold_bytes = median_bytes * median_multiplier;
        if ( p90_bytes * p90_multiplier > threshold_bytes )
            threshold_bytes = p90_bytes * p90_multiplier;
        }

    if ( ! capacity_ok )
        {
        status = "capacity_exceeded";
        reason = "profile_limit_reached";
        }
    else if ( ! eligible )
        {
        status = "quality_excluded";
        reason = "window_not_eligible";
        # Invalid quality resets provisional evidence; never silently release
        # samples spanning a capture gap into a supposedly clean baseline.
        if ( delayed_learning_enabled && |p$pending| > 0 )
            {
            p = discard_pending(p, snapshot_ts, source, destination,
                                scope_name, "quality_reset");
            changed = T;
            }
        # Distinct from adaptive_candidate: cannot claim reliable measurement.
        if ( flows > 0 && bytes_sent >= threshold_bytes )
            degraded_volume = T;
        }
    else if ( flows == 0 || bytes_sent == 0 )
        {
        reason = "idle_or_zero_payload_no_training";
        }
    else
        {
        if ( bytes_sent >= threshold_bytes )
            {
            is_candidate = T;
            if ( ready )
                reason = "adaptive_volume_above_baseline";
            else
                reason = "cold_start_large_transfer";
            }
        else if ( bytes_sent > max_training_sample_bytes )
            reason = "large_untrusted_sample_excluded_from_training";
        else if ( suspended )
            reason = "learning_suspended_by_rolling_or_volume_candidate";
        else if ( delayed_learning_enabled )
            {
            if ( |p$pending| >= max_pending_samples_per_profile )
                {
                p = discard_pending(p, snapshot_ts, source, destination,
                                    scope_name, "pending_capacity_exceeded");
                changed = T;
                reason = "pending_capacity_exceeded_no_training";
                }
            else
                {
                p$pending += [$ts=snapshot_ts, $payload_bytes=bytes_sent];
                queued = T;
                changed = T;
                if ( ready )
                    reason = "within_adaptive_baseline_pending";
                else
                    reason = "baseline_learning_pending";
                }
            }
        else
            {
            p = add_sample(p, bytes_sent);
            added = T;
            changed = T;
            if ( ready )
                reason = "within_adaptive_baseline";
            else
                reason = "baseline_learning";
            }
        }

    # Even a single-window adaptive candidate is a conservative reason to
    # withdraw provisional samples for this protected source.
    if ( is_candidate && delayed_learning_enabled )
        {
        suspend_learning(source, snapshot_ts, "adaptive_volume_candidate");
        # Keep the current decision log consistent with a possible discard
        # of pending samples performed by suspend_learning().
        if ( scope_name == "host" && source in profiles_host )
            p = profiles_host[source];
        else if ( scope_name != "host" &&
                  [source, destination] in profiles_dest )
            p = profiles_dest[source, destination];
        }

    if ( changed && capacity_ok )
        {
        if ( scope_name == "host" )
            profiles_host[source] = p;
        else
            profiles_dest[source, destination] = p;
        }

    local decision: DataExfilAdaptive::DecisionInfo = [
        $ts=snapshot_ts,
        $event_type="exfil_adaptive_decision",
        $scope=scope_name,
        $src_ip=source,
        $dest_ip=destination,
        $destination_class=destination_class,
        $window_seconds=window_span,
        $flow_count=flows,
        $sample_bytes=bytes_sent,
        $sample_eligible=eligible,
        $profile_samples_before=samples_before,
        $profile_state=status,
        $baseline_median_bytes=median_bytes,
        $baseline_p90_bytes=p90_bytes,
        $threshold_bytes=threshold_bytes,
        $adaptive_candidate=is_candidate,
        $quality_degraded_volume_candidate=degraded_volume,
        $principal_dest_ip=principal_dest,
        $principal_dest_bytes=principal_bytes,
        $principal_dest_share_percent=principal_share_percent,
        $attribution_complete=attribution_complete,
        $quality_gap_flows=gap_flows,
        $quality_non_sf_flows=non_sf_flows,
        $quality_missing_estimates=missing_estimates,
        $reason=reason,
        $baseline_sample_added=added,
        $baseline_sample_queued=queued,
        $baseline_pending_count=|p$pending|,
        $learning_suspended=(suspended || is_candidate),
        $byte_basis="zeek_tcp_sequence_estimate",
        $note="Detection-only estimate; when delayed learning is enabled, baseline_sample_added means immediate commit (normally false). Delayed commits/discards have separate audit records. No proof of exfiltration or data receipt; baseline memory resets on restart."
    ];
    write_decision(decision);
    }

# Zeek dispatches queued events after the source window tick. Snapshot
# records contain all fields necessary for evaluation before state reset.
event DataExfilWindow::host_window_ready(summary: DataExfilWindow::WindowInfo) &priority=0
    {
    evaluate_window(summary$ts, summary$src_ip, 0.0.0.0, "host",
                    summary$window_seconds, summary$flow_count,
                    summary$outbound_payload_bytes, summary$baseline_sample_eligible,
                    summary$top_dest_ip, summary$top_dest_bytes,
                    summary$top_dest_share_percent, summary$attribution_complete,
                    summary$capture_gap_flows, summary$non_sf_flows,
                    summary$missing_outbound_byte_estimates);
    }

event DataExfilWindow::destination_window_ready(summary: DataExfilWindow::DestinationWindowInfo) &priority=0
    {
    evaluate_window(summary$ts, summary$src_ip, summary$dest_ip, "destination",
                    summary$window_seconds, summary$destination_flow_count,
                    summary$destination_payload_bytes, summary$baseline_sample_eligible,
                    summary$dest_ip, summary$destination_payload_bytes,
                    (summary$destination_payload_bytes > 0 ? 100 : 0),
                    (summary$window_invariant_ok && summary$baseline_sample_eligible),
                    summary$capture_gap_flows_destination,
                    summary$non_sf_flows_destination,
                    summary$missing_outbound_byte_estimates_destination);
    }

# Final reconciliation barrier: queued window callbacks have all run, and
# slow.zeek processes its zero-filled destinations at higher priority.
# No new sample is committed while a source is quarantined after a candidate.
event DataExfilWindow::window_tick_complete(stamp: time, span: interval) &priority=-10
    {
    if ( ! enabled || ! delayed_learning_enabled )
        return;

    local source_keys: set[addr] = set();
    local pair_keys: set[addr, addr] = set();
    local expired_holds: set[addr] = set();
    for ( s in profiles_host )
        add source_keys[s];
    for ( [s, d] in profiles_dest )
        add pair_keys[s, d];

    for ( s in source_keys )
        {
        if ( s in profiles_host )
            {
            local hp = profiles_host[s];
            if ( learning_is_suspended(s, stamp) )
                hp = discard_pending(hp, stamp, s, 0.0.0.0,
                                     "host", "candidate_hold_at_tick_barrier");
            else
                hp = confirm_pending(hp, stamp, s, 0.0.0.0, "host");
            profiles_host[s] = hp;
            }
        }

    for ( [s, d] in pair_keys )
        {
        if ( [s, d] in profiles_dest )
            {
            local dp = profiles_dest[s, d];
            if ( learning_is_suspended(s, stamp) )
                dp = discard_pending(dp, stamp, s, d, "destination",
                                     "candidate_hold_at_tick_barrier");
            else
                dp = confirm_pending(dp, stamp, s, d, "destination");
            profiles_dest[s, d] = dp;
            }
        }

    for ( s in learning_suspended_until )
        {
        if ( learning_suspended_until[s] < stamp )
            add expired_holds[s];
        }
    for ( s in expired_holds )
        delete learning_suspended_until[s];
    }
