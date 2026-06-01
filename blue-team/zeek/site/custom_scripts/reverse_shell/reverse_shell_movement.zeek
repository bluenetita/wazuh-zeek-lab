module ReverseShellLive;

export {

    type LiveInfo: record {
    ts: time        &log;
    event_type: string  &log;
    uid: string     &log;
    src_ip: addr    &log;
    dest_ip: addr    &log;
    dest_port: port    &log;
    orig_bytes: count  &log;
    resp_bytes: count   &log;
    orig_pkts: count    &log;
    resp_pkts: count    &log;
    duration: interval  &log;
    note: string    &log;
    };

}

global reverse_shell_movement_log_path: string = "/var/log/zeek-custom/reverse_shell_movement.log";

function append_reverse_shell_movement_log(rec: ReverseShellLive::LiveInfo)
{
    local f = open_for_append(reverse_shell_movement_log_path);

    if ( ! active_file(f) )
    {
        Reporter::warning(fmt("Impossibile aprire il file reverse_shell_movement log: %s", reverse_shell_movement_log_path));
        return;
    }

    # Converte il record Zeek in JSON.
    # Il secondo parametro T dice: includi solo i campi con &log.
    local line = to_json(rec, T);

    if ( ! write_file(f, fmt("%s\n", line)) )
        Reporter::warning(fmt("Errore scrittura su file reverse_shell_movement log: %s", reverse_shell_movement_log_path));

    close(f);
}

global conn_log: table[conn_id] of record {
    uid: string;
    time_log: time;
    };

global conn_stats: table[conn_id] of record {
    start_time: time;
    orig_bytes: count;
    resp_bytes: count;
    orig_pkts: count;
    resp_pkts: count;
    };

global allowed_ports: set[port] = {
    80/tcp, 443/tcp, 22/tcp, 53/udp, 53/tcp, 1514/tcp, 1515/tcp
};

global white_list: set[subnet] = {
    10.3.10.0/24,
    10.3.20.0/24,
    10.3.30.0/24
};

event new_connection(c: connection)
{
    if (c$id$resp_h !in white_list){
        if(c$id$resp_p !in allowed_ports){
            conn_stats[c$id] = [$start_time=network_time(),
                                $orig_bytes=0,
                                $resp_bytes=0,
                                $orig_pkts=0,
                                $resp_pkts=0];
        }
    }
}

event tcp_packet(c: connection, is_orig: bool, flags: string,
                 seq: count, ack: count, len: count, payload: string)
{

    if ( c$id !in conn_stats ) {
        if (c$id$resp_h !in white_list){
            if (c$id$resp_p !in allowed_ports){
                conn_stats[c$id] = [$start_time=network_time(),
                                    $orig_bytes=0,
                                    $resp_bytes=0,
                                    $orig_pkts=0,
                                    $resp_pkts=0];
            } else return;
        } else return;
    }

    if ( is_orig ) {
        conn_stats[c$id]$orig_bytes += len;
        conn_stats[c$id]$orig_pkts += 1;
    } else {
        conn_stats[c$id]$resp_bytes += len;
        conn_stats[c$id]$resp_pkts += 1;
    }

    local s = conn_stats[c$id];
    local duration = network_time() - s$start_time;

    # euristica live
    if ( duration > 30secs &&
         s$orig_pkts > 10 &&
         s$resp_pkts > 10 )
    {
        local avg_orig = s$orig_bytes / s$orig_pkts;
        local avg_resp = s$resp_bytes / s$resp_pkts;
        if ( avg_orig < 100 && avg_resp < 8000)
        {
            local log_rec: ReverseShellLive::LiveInfo = [
                $ts=network_time(),
                $event_type="reverse_shell_movement",
                $uid=c$uid,
                $src_ip=c$id$orig_h,
                $dest_ip=c$id$resp_h,
                $dest_port=c$id$resp_p,
                $orig_bytes=conn_stats[c$id]$orig_bytes,
                $resp_bytes=conn_stats[c$id]$resp_bytes,
                $orig_pkts=conn_stats[c$id]$orig_pkts,
                $resp_pkts=conn_stats[c$id]$resp_pkts,
                $duration=duration,
                $note=fmt("Possibile reverse shell ATTIVA %s -> %s:%s (dur=%s)",
                            c$id$orig_h, c$id$resp_h, c$id$resp_p, duration)
            ];
            if (c$id !in conn_log) {
                conn_log[c$id]=[$uid= c$uid, $time_log=network_time()];
                append_reverse_shell_movement_log(log_rec);
            } else {
                local time_diff: interval = network_time() - conn_log[c$id]$time_log;
                if (time_diff >= 1 mins) {
                    conn_log[c$id]$time_log = network_time();
                    append_reverse_shell_movement_log(log_rec);
                }
            }
        }
    }
}

event connection_state_remove(c: connection)
{
    delete conn_log[c$id];
    delete conn_stats[c$id];
}