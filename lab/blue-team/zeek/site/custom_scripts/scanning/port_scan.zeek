@load ./logging

module port_scan;

export {

    # Numero di porte TCP differenti necessarie
    # per generare la detection.
    const threshold: count = 100 &redef;

    # Finestra temporale.
    const scan_window: interval = 60secs &redef;

    # Evita alert continui per la stessa coppia
    # scanner -> target.
    const suppress_for: interval = 5mins &redef;
}


# ============================================================
# STRUTTURE DATI
# ============================================================

# scanner_ip -> target_ip -> target_port
#
# Serve per contare quante porte differenti vengono
# contattate sullo stesso host.
global seen_ports: table[addr, addr, port] of time
    &write_expire=scan_window;


# Coppie scanner -> target che hanno già generato
# una detection.
global alerted_scans: set[addr, addr]
    &create_expire=suppress_for;


# ============================================================
# CONTA PORTE UNICHE
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
# TCP PORT SCAN
# ============================================================

event new_connection(c: connection)
{
    local scanner = c$id$orig_h;
    local target = c$id$resp_h;
    local target_port = c$id$resp_p;


    # Ci interessano solamente connessioni TCP.
    if ( get_port_transport_proto(target_port) != tcp )
        return;


    if ( scanner == target )
        return;


    # Memorizza scanner -> target -> porta.
    #
    # Se la stessa porta viene contattata più volte
    # rimane comunque una sola entry.
    seen_ports[scanner, target, target_port] =
        network_time();


    local ports = count_ports(scanner, target);


    # ========================================================
    # PORT SCAN RILEVATO
    # ========================================================

    if ( ports >= threshold &&
         [scanner, target] !in alerted_scans )
    {
        add alerted_scans[scanner, target];


        local log_rec: scanning_logging::Info = [
            $ts=network_time(),
            $event_type="port_scan",
            $src_ip=scanner,
            $target_ip=target,
            $unique_ports=ports,
            $scan_window=scan_window,
            $protocol="TCP",
            $note="Possible TCP port scanning detected."
        ];


        scanning_logging::append_scanning_log(log_rec);
    }
}
