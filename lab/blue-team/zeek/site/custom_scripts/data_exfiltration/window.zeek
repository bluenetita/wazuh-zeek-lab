# Outbound TCP completed-flow windows, separated by source and destination.
# Timestamp describes flow finalization, not transmission time.
# Quality checks exclude partial/capture-gap windows from candidate decisions.
@load base/protocols/conn

module DataExfilWindow;

export {
    const enabled: bool = T &redef;
    const window_interval: interval = 1mins &redef;
    const idle_timeout: interval = 30mins &redef;
    const max_destination_keys: count = 4096 &redef;
    const output_path: string = "/var/log/zeek-custom/data_exfiltration.log" &redef;

    type WindowInfo: record {
        ts: time &log;
        event_type: string &log;
        src_ip: addr &log;
        window_start: time &log;
        window_seconds: interval &log;
        first_window_partial: bool &log;
        flow_count: count &log;
        outbound_payload_bytes: count &log;
        max_single_flow_bytes: count &log;
        top_dest_ip: addr &log;
        top_dest_bytes: count &log;
        top_dest_share_percent: count &log;
        tracked_destination_payload_bytes: count &log;
        unattributed_payload_bytes: count &log;
        attribution_complete: bool &log;
        capture_gap_flows: count &log;
        non_sf_flows: count &log;
        missing_outbound_byte_estimates: count &log;
        destination_tracking_overflow_flows: count &log;
        baseline_sample_eligible: bool &log;
        window_invariant_ok: bool &log;
        byte_basis: string &log;
        aggregation_scope: string &log;
        note: string &log;
    };

    # Diagnostic per-destination rows; emitted only for destination keys with
    # positive outbound TCP payload finalized during this window. They do not
    # imply that the source IP/port is malicious or bytes reached the receiver.
    type DestinationWindowInfo: record {
        ts: time &log;
        event_type: string &log;
        src_ip: addr &log;
        dest_ip: addr &log;
        window_start: time &log;
        window_seconds: interval &log;
        destination_payload_bytes: count &log;
        destination_flow_count: count &log;
        host_outbound_payload_bytes: count &log;
        host_flow_count: count &log;
        first_window_partial: bool &log;
        # Quality of THIS destination, never inherited from others.
        capture_gap_flows_destination: count &log;
        non_sf_flows_destination: count &log;
        missing_outbound_byte_estimates_destination: count &log;
        # Host counters are retained solely for diagnostics.
        capture_gap_flows_host: count &log;
        non_sf_flows_host: count &log;
        missing_outbound_byte_estimates_host: count &log;
        destination_tracking_overflow_flows_host: count &log;
        window_invariant_ok: bool &log;
        baseline_sample_eligible: bool &log;
        byte_basis: string &log;
        aggregation_scope: string &log;
        note: string &log;
    };

    # Callbacks emitted once per completed diagnostic window. These events
    # are queued after snapshots are written; they do not modify counters.
    global host_window_ready: event(summary: WindowInfo);
    global destination_window_ready: event(summary: DestinationWindowInfo);
    # Dispatched AFTER all destination/host snapshots of the same tick.
    # Rolling detectors can synthesize idle destination windows safely.
    global window_tick_complete: event(stamp: time, span: interval);
}

type HostState: record {
    last_flow: time;
    first_window_partial: bool;
    flow_count: count;
    outbound_payload_bytes: count;
    max_single_flow_bytes: count;
    top_dest_ip: addr;
    top_dest_bytes: count;
    capture_gap_flows: count;
    non_sf_flows: count;
    missing_outbound_byte_estimates: count;
    destination_tracking_overflow_flows: count;
};

global hosts: table[addr] of HostState;
# Tracking is bounded: overflow affects only top-destination attribution;
# the total per-host byte and flow counters still include all flows.
global destination_bytes: table[addr,addr] of count;
global destination_flows: table[addr,addr] of count;
# Separate quality counters prevent an unrelated TCP flow from invalidating
# an otherwise trustworthy source/destination window.
global destination_gap_flows: table[addr,addr] of count;
global destination_non_sf_flows: table[addr,addr] of count;
global destination_missing_estimates: table[addr,addr] of count;
global destination_keys: count = 0;
global window_start_time: time;
global process_window_tick: event();

function ensure_host(ip: addr)
    {
    if ( ip in hosts )
        return;

    hosts[ip] = [
        $last_flow=network_time(),
        $first_window_partial=T,
        $flow_count=0,
        $outbound_payload_bytes=0,
        $max_single_flow_bytes=0,
        $top_dest_ip=0.0.0.0,
        $top_dest_bytes=0,
        $capture_gap_flows=0,
        $non_sf_flows=0,
        $missing_outbound_byte_estimates=0,
        $destination_tracking_overflow_flows=0
    ];
    }

function append_window(rec: DataExfilWindow::WindowInfo)
    {
    local f = open_for_append(output_path);
    if ( ! active_file(f) )
        {
        Reporter::warning(fmt("DataExfilWindow: cannot open %s", output_path));
        return;
        }

    if ( ! write_file(f, fmt("%s\n", to_json(rec, T))) )
        Reporter::warning(fmt("DataExfilWindow: cannot write %s", output_path));
    close(f);
    }

function append_destination_window(rec: DataExfilWindow::DestinationWindowInfo)
    {
    local f = open_for_append(output_path);
    if ( ! active_file(f) )
        {
        Reporter::warning(fmt("DataExfilWindow: cannot open %s", output_path));
        return;
        }

    if ( ! write_file(f, fmt("%s\n", to_json(rec, T))) )
        Reporter::warning(fmt("DataExfilWindow: cannot write %s", output_path));
    close(f);
    }

# Runs alongside the independent per-flow diagnostics module.
event Conn::log_conn(rec: Conn::Info)
    {
    if ( ! enabled || rec$proto != tcp )
        return;

    local orig_internal = rec$id$orig_h in DataExfilFlow::internal_networks;
    local resp_internal = rec$id$resp_h in DataExfilFlow::internal_networks;

    # The OUTBOUND-INITIATED baseline only covers Zeek originators in the
    # protected networks and their non-protected responders. Incoming session
    # replies (e.g., VPN 10.8.0.4:ephemeral -> Client Linux:22) MUST NOT
    # contaminate this baseline. Do NOT silently whitelist the VPN: a protected
    # host that INITIATES a VPN connection is still evaluated normally.
    # The connection.zeek module logs both flow orientations,
    # including server replies, with flow_orientation="external_initiated".
    # With OTH/missing SYN, Zeek's originator direction can be uncertain.
    if ( ! orig_internal || resp_internal )
        return;

    local src_ip = rec$id$orig_h;
    local dest_ip = rec$id$resp_h;
    local outbound: count = 0;
    local byte_estimate_available = F;
    if ( rec?$orig_bytes )
        {
        outbound = rec$orig_bytes;
        byte_estimate_available = T;
        }

    ensure_host(src_ip);
    hosts[src_ip]$last_flow = network_time();
    hosts[src_ip]$flow_count += 1;
    hosts[src_ip]$outbound_payload_bytes += outbound;

    if ( outbound > hosts[src_ip]$max_single_flow_bytes )
        hosts[src_ip]$max_single_flow_bytes = outbound;

    local missing_estimate = ! byte_estimate_available;
    local has_capture_gap = rec?$missed_bytes && rec$missed_bytes > 0;
    local non_sf_state = ! rec?$conn_state || rec$conn_state != "SF";

    if ( missing_estimate )
        hosts[src_ip]$missing_outbound_byte_estimates += 1;
    if ( has_capture_gap )
        hosts[src_ip]$capture_gap_flows += 1;
    if ( non_sf_state )
        hosts[src_ip]$non_sf_flows += 1;

    # Track positive-payload flows AND problematic zero/unknown-payload flows.
    # A bad flow with unknown byte count must not silently disappear from
    # the destination's quality assessment. All entries are bounded by
    # max_destination_keys and reset after each completed window.
    if ( outbound > 0 || missing_estimate || has_capture_gap ||
         non_sf_state || [src_ip, dest_ip] in destination_bytes )
        {
        if ( [src_ip, dest_ip] !in destination_bytes )
            {
            if ( destination_keys < max_destination_keys )
                {
                destination_bytes[src_ip, dest_ip] = 0;
                destination_flows[src_ip, dest_ip] = 0;
                destination_gap_flows[src_ip, dest_ip] = 0;
                destination_non_sf_flows[src_ip, dest_ip] = 0;
                destination_missing_estimates[src_ip, dest_ip] = 0;
                destination_keys += 1;
                }
            else
                hosts[src_ip]$destination_tracking_overflow_flows += 1;
            }

        if ( [src_ip, dest_ip] in destination_bytes )
            {
            destination_bytes[src_ip, dest_ip] += outbound;
            destination_flows[src_ip, dest_ip] += 1;
            if ( has_capture_gap )
                destination_gap_flows[src_ip, dest_ip] += 1;
            if ( non_sf_state )
                destination_non_sf_flows[src_ip, dest_ip] += 1;
            if ( missing_estimate )
                destination_missing_estimates[src_ip, dest_ip] += 1;

            if ( destination_bytes[src_ip, dest_ip] > hosts[src_ip]$top_dest_bytes )
                {
                hosts[src_ip]$top_dest_bytes = destination_bytes[src_ip, dest_ip];
                hosts[src_ip]$top_dest_ip = dest_ip;
                }
            }
        }

    }

event zeek_init()
    {
    window_start_time = network_time();
    if ( enabled )
        schedule window_interval { process_window_tick() };
    }

event process_window_tick()
    {
    local now = network_time();
    local window_length = now - window_start_time;
    local expired_hosts: set[addr] = set();

    # Calculate tracked totals separately. This also detects a regression in
    # cross-destination accounting without mutating the table being traversed.
    local tracked_by_host: table[addr] of count = table();
    for ( [tracked_source, tracked_dest] in destination_bytes )
        {
        if ( tracked_source !in tracked_by_host )
            tracked_by_host[tracked_source] = 0;
        tracked_by_host[tracked_source] += destination_bytes[tracked_source, tracked_dest];
        }

    # Snapshot all destination keys BEFORE host counters are reset below.
    # Per-destination quality does NOT inherit unrelated host-wide TCP gaps.

    for ( [s, d] in destination_bytes )
        {
        local dest_state = hosts[s];
        local invariant_ok = dest_state$top_dest_bytes <= dest_state$outbound_payload_bytes &&
                             destination_bytes[s, d] <= dest_state$outbound_payload_bytes &&
                             tracked_by_host[s] <= dest_state$outbound_payload_bytes;
        if ( ! invariant_ok )
            Reporter::warning(fmt("DataExfilWindow: destination %s -> %s exceeded host total", s, d));

        local dest_eligible = invariant_ok &&
                         ! dest_state$first_window_partial &&
                         destination_gap_flows[s, d] == 0 &&
                         destination_non_sf_flows[s, d] == 0 &&
                         destination_missing_estimates[s, d] == 0;
        # Overflow on another destination makes HOST attribution incomplete,
        # but this tracked destination's quality remains independently known.

        local dest_out: DataExfilWindow::DestinationWindowInfo = [
            $ts=now,
            $event_type="exfil_destination_window",
            $src_ip=s,
            $dest_ip=d,
            $window_start=window_start_time,
            $window_seconds=window_length,
            $destination_payload_bytes=destination_bytes[s, d],
            $destination_flow_count=destination_flows[s, d],
            $host_outbound_payload_bytes=dest_state$outbound_payload_bytes,
            $host_flow_count=dest_state$flow_count,
            $first_window_partial=dest_state$first_window_partial,
            $capture_gap_flows_destination=destination_gap_flows[s, d],
            $non_sf_flows_destination=destination_non_sf_flows[s, d],
            $missing_outbound_byte_estimates_destination=destination_missing_estimates[s, d],
            $capture_gap_flows_host=dest_state$capture_gap_flows,
            $non_sf_flows_host=dest_state$non_sf_flows,
            $missing_outbound_byte_estimates_host=dest_state$missing_outbound_byte_estimates,
            $destination_tracking_overflow_flows_host=dest_state$destination_tracking_overflow_flows,
            $window_invariant_ok=invariant_ok,
            $baseline_sample_eligible=dest_eligible,
            $byte_basis="zeek_tcp_sequence_estimate",
            $aggregation_scope="tcp_flows_finalized_within_window",
            $note="Protected-initiated TCP only. No alert; finalized-flow time, not wire-time. Incoming replies stay visible in connection.zeek."
        ];
        append_destination_window(dest_out);
        event DataExfilWindow::destination_window_ready(dest_out);
        }

    for ( src_ip in hosts )
        {
        local state = hosts[src_ip];
        local tracked_total: count = 0;
        if ( src_ip in tracked_by_host )
            tracked_total = tracked_by_host[src_ip];
        local destination_invariant_ok = state$top_dest_bytes <= state$outbound_payload_bytes &&
                                         tracked_total <= state$outbound_payload_bytes;
        local unattributed_total: count = 0;
        if ( tracked_total <= state$outbound_payload_bytes )
            unattributed_total = state$outbound_payload_bytes - tracked_total;
        local top_share: count = 0;
        if ( state$outbound_payload_bytes > 0 )
            top_share = (state$top_dest_bytes * 100) / state$outbound_payload_bytes;
        local attribution_complete = destination_invariant_ok &&
                                     state$destination_tracking_overflow_flows == 0 &&
                                     unattributed_total == 0 &&
                                     state$missing_outbound_byte_estimates == 0 &&
                                     state$capture_gap_flows == 0 &&
                                     state$non_sf_flows == 0;
        if ( ! destination_invariant_ok )
            Reporter::warning(fmt("DataExfilWindow: inconsistent destination sum for %s (%d > %d)",
                                  src_ip, state$top_dest_bytes, state$outbound_payload_bytes));

        local eligible = destination_invariant_ok &&
                         ! state$first_window_partial &&
                         state$capture_gap_flows == 0 &&
                         state$non_sf_flows == 0 &&
                         state$missing_outbound_byte_estimates == 0 &&
                         state$destination_tracking_overflow_flows == 0;

        local out: DataExfilWindow::WindowInfo = [
            $ts=now,
            $event_type="exfil_window_summary",
            $src_ip=src_ip,
            $window_start=window_start_time,
            $window_seconds=window_length,
            $first_window_partial=state$first_window_partial,
            $flow_count=state$flow_count,
            $outbound_payload_bytes=state$outbound_payload_bytes,
            $max_single_flow_bytes=state$max_single_flow_bytes,
            $top_dest_ip=state$top_dest_ip,
            $top_dest_bytes=state$top_dest_bytes,
            $top_dest_share_percent=top_share,
            $tracked_destination_payload_bytes=tracked_total,
            $unattributed_payload_bytes=unattributed_total,
            $attribution_complete=attribution_complete,
            $capture_gap_flows=state$capture_gap_flows,
            $non_sf_flows=state$non_sf_flows,
            $missing_outbound_byte_estimates=state$missing_outbound_byte_estimates,
            $destination_tracking_overflow_flows=state$destination_tracking_overflow_flows,
            $baseline_sample_eligible=eligible,
            $window_invariant_ok=destination_invariant_ok,
            $byte_basis="zeek_tcp_sequence_estimate",
            $aggregation_scope="tcp_flows_finalized_within_window",
            $note="Protected-initiated TCP only. Finalization time is not wire-time; no proof of exfiltration or receipt."
        ];
        append_window(out);
        event DataExfilWindow::host_window_ready(out);

        if ( now - state$last_flow > idle_timeout )
            {
            add expired_hosts[src_ip];
            }
        else
            {
            hosts[src_ip]$first_window_partial = F;
            hosts[src_ip]$flow_count = 0;
            hosts[src_ip]$outbound_payload_bytes = 0;
            hosts[src_ip]$max_single_flow_bytes = 0;
            hosts[src_ip]$top_dest_ip = 0.0.0.0;
            hosts[src_ip]$top_dest_bytes = 0;
            hosts[src_ip]$capture_gap_flows = 0;
            hosts[src_ip]$non_sf_flows = 0;
            hosts[src_ip]$missing_outbound_byte_estimates = 0;
            hosts[src_ip]$destination_tracking_overflow_flows = 0;
            }
        }

    # Never modify a table while iterating over its keys: Zeek warns that
    # membership changes during iteration may leave keys behind.
    for ( ip in expired_hosts )
        delete hosts[ip];

    # Replacing the table also bounds per-window destination state correctly.
    destination_bytes = table();
    destination_flows = table();
    destination_gap_flows = table();
    destination_non_sf_flows = table();
    destination_missing_estimates = table();
    destination_keys = 0;

    # Barrier after destination_window_ready and host_window_ready callbacks.
    # Zeek queues the events in invocation order for subsequent processing;
    # the rolling listener sees all real rows before this completion marker.
    event DataExfilWindow::window_tick_complete(now, window_length);
    window_start_time = now;
    schedule window_interval { process_window_tick() };
    }
