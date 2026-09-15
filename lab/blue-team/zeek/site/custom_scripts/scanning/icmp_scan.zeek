@load ./logging

module icmp_scan;

export {

    # Numero minimo di host differenti a cui vengono
    # inviati ICMP Echo Request.
    const threshold: count = 2 &redef;

    const scan_window: interval = 60secs &redef;

    const suppress_for: interval = 5mins &redef;
}


# ============================================================
# STRUTTURE DATI
# ============================================================

# scanner -> target
global seen_targets: table[addr, addr] of time
    &write_expire=scan_window;


# Scanner già segnalati.
global alerted_scanners: set[addr]
    &create_expire=suppress_for;


# ============================================================
# CONTA TARGET UNICI
# ============================================================

function count_targets(scanner: addr): count
{
    local n: count = 0;

    for ( [src, dst] in seen_targets )
    {
        if ( src == scanner )
            ++n;
    }

    return n;
}


# ============================================================
# ICMP HOST SCAN
# ============================================================

event icmp_echo_request(c: connection,
                        info: icmp_info,
                        id: count,
                        seq: count,
                        payload: string)
{
    local scanner = c$id$orig_h;
    local target = c$id$resp_h;


    if ( scanner == target )
        return;


    # Registra scanner -> target.
    seen_targets[scanner, target] =
        network_time();


    local targets = count_targets(scanner);


    # ========================================================
    # ICMP HOST SCAN RILEVATO
    # ========================================================

    if ( targets >= threshold &&
         scanner !in alerted_scanners )
    {
        add alerted_scanners[scanner];


        local log_rec: scanning_logging::Info = [
            $ts=network_time(),
            $event_type="icmp_host_scan",
            $src_ip=scanner,
            $target_count=targets,
            $scan_window=scan_window,
            $protocol="ICMP",
            $note="Possible ICMP host scanning detected."
        ];


        scanning_logging::append_scanning_log(log_rec);
    }
}
