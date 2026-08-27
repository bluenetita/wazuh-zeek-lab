module ReverseShell;

export {
    # Definisco la struttura per i dati all'inizio della connessione.
    type LiveInfo: record {
        ts: time        &log;
        event_type: string  &log;
        uid: string     &log;
        src_ip: addr    &log;
        dest_ip: addr   &log;
        dest_port: port &log;
        weird_name: string &log;
        note: string    &log;
    };

    # Definisco la struttura per i dati finali della connessione.
    type FinalInfo: record {
        ts: time           &log;
        event_type: string  &log;
        uid: string        &log;
        src_ip: addr       &log;
        dest_ip: addr      &log;
        dest_port: port    &log;
        duration: interval &log;
        orig_bytes: count  &log;
        resp_bytes: count  &log;
        service: string    &log;
        note: string       &log;
    };
}

# Lista degli UID dei possibili sospettati.
global alerted_live: set[string] = {};

# Lista degli UID dei sospettati.
global alerted_final: set[string] = {};

# Lista delle porte permesse
global allowed_ports: set[port] = {
    80/tcp, 443/tcp, 22/tcp, 53/udp, 53/tcp, 1514/tcp, 1515/tcp
};

global reverse_shell_live_log_path: string = "/var/log/zeek-custom/reverse_shell_live.log";

function append_reverse_shell_live_log(rec: ReverseShell::LiveInfo)
{
    local f = open_for_append(reverse_shell_live_log_path);

    if ( ! active_file(f) )
    {
        Reporter::warning(fmt("Impossibile aprire il file reverse_shell_live log: %s", reverse_shell_live_log_path));
        return;
    }

    # Converte il record Zeek in JSON.
    # Il secondo parametro T dice: includi solo i campi con &log.
    local line = to_json(rec, T);

    if ( ! write_file(f, fmt("%s\n", line)) )
        Reporter::warning(fmt("Errore scrittura su file reverse_shell_live log: %s", reverse_shell_live_log_path));

    close(f);
}

global reverse_shell_final_log_path: string = "/var/log/zeek-custom/reverse_shell_final.log";

function append_reverse_shell_final_log(rec: ReverseShell::FinalInfo)
{
    local f = open_for_append(reverse_shell_final_log_path);

    if ( ! active_file(f) )
    {
        Reporter::warning(fmt("Impossibile aprire il file reverse_shell_final log: %s", reverse_shell_final_log_path));
        return;
    }

    # Converte il record Zeek in JSON.
    # Il secondo parametro T dice: includi solo i campi con &log.
    local line = to_json(rec, T);

    if ( ! write_file(f, fmt("%s\n", line)) )
        Reporter::warning(fmt("Errore scrittura su file reverse_shell_final log: %s", reverse_shell_final_log_path));

    close(f);
}

# ALERT LIVE:
# se compare un weird su una connessione verso una porta sospetta,
# genero subito il log mentre la connessione e' ancora attiva.
event conn_weird(name: string, c: connection, addl: string) {
    if ( name == "truncated_tcp_payload" ||
         name == "data_before_established" ||
         name == "bad_TCP_checksum" ) {
        if ( c$id$resp_p !in allowed_ports ) {
            if ( c$uid !in alerted_live ) {
                add alerted_live[c$uid];
                local log_rec: ReverseShell::LiveInfo = [
                    $ts=network_time(),
                    $event_type="reverse_shell_live",
                    $uid=c$uid,
                    $src_ip=c$id$orig_h,
                    $dest_ip=c$id$resp_h,
                    $dest_port=c$id$resp_p,
                    $weird_name=name,
                    $note="Possibile reverse shell / C2 TCP (live)"
            ];
            append_reverse_shell_live_log(log_rec);
            }
        }
    }
}

# CONFERMA FINALE:
# quando la connessione termina, se ha abbastanza volume e/o era gia' alertata live,
# scrivo il log finale.
event connection_state_remove(c: connection) {
    if ( ! c?$conn ) {
        return;
    }

    if ( ! c$conn?$duration || ! c$conn?$orig_bytes || ! c$conn?$resp_bytes ) {
        return;
    }

    local service = "";
    if ( c$conn?$service )
        service = c$conn$service;

    local suspicious = F;

    # Caso 1: gia' alertato live
    if ( c$uid in alerted_live )
        suspicious = T;

    # Caso 2: anche senza live alert, porta sospetta + traffico bidirezionale
    if ( c$id$resp_p !in allowed_ports &&
         c$conn$orig_bytes > 500 &&
         c$conn$resp_bytes > 500 )
        suspicious = T;

    if ( suspicious ) {
        if (c$uid !in alerted_final)
            add alerted_final[c$uid];
        local log_rec: ReverseShell::FinalInfo = [
            $ts=network_time(),
            $event_type="reverse_shell_final",
            $uid=c$uid,
            $src_ip=c$id$orig_h,
            $dest_ip=c$id$resp_h,
            $dest_port=c$id$resp_p,
            $duration=c$conn$duration,
            $orig_bytes=c$conn$orig_bytes,
            $resp_bytes=c$conn$resp_bytes,
            $service=service,
            $note="Possibile reverse shell / C2 TCP (final)"
        ];
        append_reverse_shell_final_log(log_rec);
    }
}