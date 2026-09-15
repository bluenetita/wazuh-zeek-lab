@load ./logging

module host_scan;

export {

    # Numero minimo di IP differenti interrogati
    # prima di considerare il comportamento un host scan.
    const threshold: count = 20 &redef;

    # Finestra temporale.
    const scan_window: interval = 60secs &redef;

    # Suppression dopo una detection.
    const suppress_for: interval = 5mins &redef;
}


# ============================================================
# STRUTTURE DATI
# ============================================================

# scanner_ip -> target_ip
#
# Ogni coppia rimane valida per scan_window.
global seen_targets: table[addr, addr] of time
    &write_expire=scan_window;


# Scanner che hanno già generato una detection.
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
# ARP HOST SCAN
# ============================================================

event arp_request(mac_src: string,
                  mac_dst: string,
                  SPA: addr,
                  SHA: string,
                  TPA: addr,
                  THA: string)
{
    # SPA = IP sorgente della richiesta ARP.
    # SHA = MAC sorgente.
    # TPA = IP che viene cercato.

    if ( SPA == TPA )
        return;


    # Registra scanner -> target.
    #
    # Lo stesso target ripetuto non incrementa il conteggio.
    seen_targets[SPA, TPA] = network_time();


    local targets = count_targets(SPA);


    if ( targets >= threshold &&
         SPA !in alerted_scanners )
    {
        add alerted_scanners[SPA];


        local log_rec: scanning_logging::Info = [
            $ts=network_time(),
            $event_type="host_scan",
            $src_ip=SPA,
            $scanner_mac=SHA,
            $target_count=targets,
            $scan_window=scan_window,
            $protocol="ARP",
            $note="Possible ARP host scanning detected."
        ];


        scanning_logging::append_scanning_log(log_rec);
    }
}
