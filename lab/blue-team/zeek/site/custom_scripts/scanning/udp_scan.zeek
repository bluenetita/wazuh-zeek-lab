@load ./logging

module udp_scan;

export {

    # UDP scanning è generalmente più lento,
    # quindi usiamo una soglia iniziale inferiore al TCP.
    const threshold: count = 50 &redef;

    const scan_window: interval = 60secs &redef;

    const suppress_for: interval = 5mins &redef;
}


# ============================================================
# STRUTTURE DATI
# ============================================================

# scanner_ip -> target_ip -> porta UDP
global seen_ports: table[addr, addr, port] of time
    &write_expire=scan_window;


# Coppie scanner -> target già segnalate.
global alerted_scans: set[addr, addr]
    &create_expire=suppress_for;


# ============================================================
# CONTA PORTE UDP UNICHE
# ============================================================

function count_ports(scanner: addr, target: addr): count
{
    local n: count = 0;

    for ( [src, dst, p] in seen_ports )
    {
        if ( src == scanner && dst == target )
            ++n;
    }

    return n;
}


# ============================================================
# UDP PORT SCAN
# ============================================================

event new_connection(c: connection)
{
    local scanner = c$id$orig_h;
    local target = c$id$resp_h;
    local target_port = c$id$resp_p;


    # Solo UDP.
    if ( get_port_transport_proto(target_port) != udp )
        return;


    if ( scanner == target )
        return;


    seen_ports[scanner, target, target_port] =
        network_time();


    local ports = count_ports(scanner, target);


    # ========================================================
    # UDP PORT SCAN RILEVATO
    # ========================================================

    if ( ports >= threshold &&
         [scanner, target] !in alerted_scans )
    {
        add alerted_scans[scanner, target];


        local log_rec: scanning_logging::Info = [
            $ts=network_time(),
            $event_type="udp_port_scan",
            $src_ip=scanner,
            $target_ip=target,
            $unique_ports=ports,
            $scan_window=scan_window,
            $protocol="UDP",
            $note="Possible UDP port scanning detected."
        ];


        scanning_logging::append_scanning_log(log_rec);
    }
}
