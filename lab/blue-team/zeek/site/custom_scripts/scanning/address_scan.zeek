@load ./logging

module address_scan;

export {

    # Numero minimo di host differenti contattati
    # sulla stessa porta TCP.
    const threshold: count = 2 &redef;

    # Finestra temporale.
    const scan_window: interval = 60secs &redef;

    # Evita alert continui per la stessa combinazione
    # scanner -> porta.
    const suppress_for: interval = 5mins &redef;
}


# ============================================================
# STRUTTURE DATI
# ============================================================

# scanner_ip -> target_port -> target_ip
#
# Serve per contare quanti host differenti vengono
# contattati sulla stessa porta.
global seen_targets: table[addr, port, addr] of time
    &write_expire=scan_window;


# Coppie scanner -> porta che hanno già generato
# una detection.
global alerted_scans: set[addr, port]
    &create_expire=suppress_for;


# ============================================================
# CONTA TARGET UNICI
# ============================================================

function count_targets(scanner: addr, target_port: port): count
{
    local n: count = 0;

    for ( [src, p, dst] in seen_targets )
    {
        if ( src == scanner && p == target_port )
            ++n;
    }

    return n;
}


# ============================================================
# TCP ADDRESS SCAN
# ============================================================

event new_connection(c: connection)
{
    local scanner = c$id$orig_h;
    local target = c$id$resp_h;
    local target_port = c$id$resp_p;


    # Solo TCP.
    if ( get_port_transport_proto(target_port) != tcp )
        return;


    if ( scanner == target )
        return;


    # Memorizza scanner -> porta -> target.
    #
    # Se lo stesso target viene contattato più volte,
    # non aumenta il conteggio.
    seen_targets[scanner, target_port, target] =
        network_time();


    local targets = count_targets(scanner, target_port);


    # ========================================================
    # ADDRESS SCAN RILEVATO
    # ========================================================

    if ( targets >= threshold &&
         [scanner, target_port] !in alerted_scans )
    {
        add alerted_scans[scanner, target_port];


        local log_rec: scanning_logging::Info = [
            $ts=network_time(),
            $event_type="address_scan",
            $src_ip=scanner,
            $target_port=target_port,
            $target_count=targets,
            $scan_window=scan_window,
            $protocol="TCP",
            $note="Possible TCP address scanning detected."
        ];


        scanning_logging::append_scanning_log(log_rec);
    }
}
