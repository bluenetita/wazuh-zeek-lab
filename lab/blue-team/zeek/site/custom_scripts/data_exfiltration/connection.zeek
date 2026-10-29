# Completed-flow outbound TCP summary for the final Data Exfiltration detector.
# Uses sequence-derived byte estimates; not proof of delivery.
# Logs both connection initiation orientations for diagnostics.
@load base/protocols/conn

module DataExfilFlow;

export {
    const enabled: bool = T &redef;
    const internal_networks: set[subnet] = {
        10.3.10.0/24,
        10.3.20.0/24,
        10.3.30.0/24
    } &redef;
    const min_outbound_payload_bytes: count = 1024 &redef;
    const output_path: string = "/var/log/zeek-custom/data_exfiltration.log" &redef;

    type Info: record {
        ts: time &log;                   # Time of the summary event at this sensor
        event_type: string &log;
        conn_ts: time &log;              # Start time of this TCP flow
        uid: string &log;                # Zeek connection UID
        src_ip: addr &log;               # Internal endpoint sending outbound data
        src_port: count &log;
        dest_ip: addr &log;              # Outside peer (not necessarily initiator)
        dest_port: count &log;
        dest_proto: string &log;
        flow_orientation: string &log;
        outbound_payload_bytes: count &log;
        inbound_payload_bytes: count &log;
        outbound_ip_observed_bytes: count &log;
        outbound_ip_bytes_available: bool &log;
        missed_bytes: count &log;
        conn_state: string &log;
        duration: interval &log;
        data_quality: string &log;
        byte_basis: string &log;
        note: string &log;
    };
}

function emit_record(rec: DataExfilFlow::Info)
    {
    local f = open_for_append(output_path);
    if ( ! active_file(f) )
        {
        Reporter::warning(fmt("DataExfilFlow: cannot open %s", output_path));
        return;
        }

    if ( ! write_file(f, fmt("%s\n", to_json(rec, T))) )
        Reporter::warning(fmt("DataExfilFlow: cannot write %s", output_path));
    close(f);
    }

# Uses Zeek's connection summaries rather than summing every TCP packet.
# It deliberately covers BOTH possible TCP initiation directions:
#   internal initiator -> external responder: outbound == orig_bytes
#   external initiator -> internal responder: outbound == resp_bytes
# TCP retransmissions and OVS mirroring can skew packet-level totals.
# Sequence-number estimates have their own accuracy limitations.
event Conn::log_conn(rec: Conn::Info)
    {
    if ( ! enabled || rec$proto != tcp )
        return;

    local orig_internal = rec$id$orig_h in internal_networks;
    local resp_internal = rec$id$resp_h in internal_networks;

    # Skip internal-to-internal and external-to-external connections.
    if ( orig_internal == resp_internal )
        return;

    local internal_ip: addr;
    local internal_port: port;
    local external_ip: addr;
    local external_port: port;
    local outbound: count = 0;
    local inbound: count = 0;
    local observed_ip: count = 0;
    local has_ip_bytes = F;
    local orientation: string;

    if ( orig_internal )
        {
        # If Zeek has no outbound byte estimate, avoid inventing a zero.
        if ( ! rec?$orig_bytes )
            return;
        outbound = rec$orig_bytes;
        if ( rec?$resp_bytes )
            inbound = rec$resp_bytes;
        if ( rec?$orig_ip_bytes )
            {
            observed_ip = rec$orig_ip_bytes;
            has_ip_bytes = T;
            }
        internal_ip = rec$id$orig_h;
        internal_port = rec$id$orig_p;
        external_ip = rec$id$resp_h;
        external_port = rec$id$resp_p;
        orientation = "internal_initiated";
        }
    else
        {
        if ( ! rec?$resp_bytes )
            return;
        outbound = rec$resp_bytes;
        if ( rec?$orig_bytes )
            inbound = rec$orig_bytes;
        if ( rec?$resp_ip_bytes )
            {
            observed_ip = rec$resp_ip_bytes;
            has_ip_bytes = T;
            }
        internal_ip = rec$id$resp_h;
        internal_port = rec$id$resp_p;
        external_ip = rec$id$orig_h;
        external_port = rec$id$orig_p;
        orientation = "external_initiated";
        }

    if ( outbound < min_outbound_payload_bytes )
        return;

    local missed: count = 0;
    if ( rec?$missed_bytes )
        missed = rec$missed_bytes;

    local elapsed: interval = 0sec;
    if ( rec?$duration )
        elapsed = rec$duration;

    local quality = "sequence_estimate_unverified";
    if ( missed > 0 )
        quality = "capture_gaps";
    else if ( rec$conn_state == "OTH" || rec$conn_state == "S1" )
        quality = "partial_connection";
    else if ( has_ip_bytes && outbound > observed_ip )
        quality = "sequence_estimate_exceeds_observed_ip_bytes";

    local out: DataExfilFlow::Info = [
        $ts=network_time(),
        $event_type="exfil_flow_summary",
        $conn_ts=rec$ts,
        $uid=rec$uid,
        $src_ip=internal_ip,
        $src_port=port_to_count(internal_port),
        $dest_ip=external_ip,
        $dest_port=port_to_count(external_port),
        $dest_proto="tcp",
        $flow_orientation=orientation,
        $outbound_payload_bytes=outbound,
        $inbound_payload_bytes=inbound,
        $outbound_ip_observed_bytes=observed_ip,
        $outbound_ip_bytes_available=has_ip_bytes,
        $missed_bytes=missed,
        $conn_state=rec$conn_state,
        $duration=elapsed,
        $data_quality=quality,
        $byte_basis="zeek_tcp_sequence_estimate",
        $note="Diagnostic-only. A flow summary is not proof of exfiltration or bytes received."
    ];

    emit_record(out);
    }
