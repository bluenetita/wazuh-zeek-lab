module scanning_logging;

export {

    # Record comune utilizzato da tutte le detection di scanning.
    #
    # I campi comuni sono sempre presenti.
    # I campi specifici delle singole detection sono optional.
    type Info: record {
        ts: time                &log;
        event_type: string      &log;
        src_ip: addr            &log;

        scanner_mac: string     &log &optional;

        target_ip: addr         &log &optional;
        target_port: port       &log &optional;

        target_count: count     &log &optional;
        unique_ports: count     &log &optional;

        scan_window: interval   &log &optional;

        protocol: string        &log &optional;

        note: string            &log;
    };


    # Funzione utilizzata dagli altri script per scrivere
    # un evento in scanning.log.
    global append_scanning_log: function(rec: Info);
}


# ============================================================
# CONFIGURAZIONE LOG
# ============================================================

global scanning_log_path: string =
    "/var/log/zeek-custom/scanning.log";


# ============================================================
# SCRITTURA LOG
# ============================================================

function append_scanning_log(rec: Info)
{
    local f = open_for_append(scanning_log_path);

    if ( ! active_file(f) )
    {
        Reporter::warning(
            fmt("Impossibile aprire il file scanning log: %s",
                scanning_log_path)
        );

        return;
    }


    # Converte il record in JSON.
    # T = include solamente i campi marcati con &log.
    local line = to_json(rec, T);


    if ( ! write_file(f, fmt("%s\n", line)) )
        Reporter::warning(
            fmt("Errore scrittura su scanning log: %s",
                scanning_log_path)
        );


    close(f);
}
