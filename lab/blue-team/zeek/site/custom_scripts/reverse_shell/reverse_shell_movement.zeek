module ReverseShellLive;

export {

    type LiveInfo: record {
        event_source: string &log;
        ts: time &log;
        event_type: string &log;
        uid: string &log;
        src_ip: addr &log;
        dest_ip: addr &log;
        dest_port: string &log;
        dest_proto: string &log;
        orig_bytes: count &log;
        resp_bytes: count &log;
        orig_pkts: count &log;
        resp_pkts: count &log;
        duration: interval &log;
        note: string &log;
    };

}


# -------------------------------------------------------------------
# Reverse shell movement detector - v2
#
# Obiettivo:
#   rilevare una connessione esterna persistente e bidirezionale
#   senza usare la dimensione media dei pacchetti come hard gate.
#
# avg_orig / avg_resp restano disponibili nel log diagnostico.
# -------------------------------------------------------------------


# =========================
# PARAMETRI DEL RILEVATORE
# =========================

const movement_min_duration: interval = 30secs &redef;

# Manteniamo la semantica originale:
# devono esserci PIU' di 10 pacchetti in entrambe le direzioni.
const movement_packet_threshold: count = 10 &redef;

# Dopo i primi 30 secondi, se non è ancora stato generato
# movement, rivaluta periodicamente la connessione.
const movement_recheck_interval: interval = 5secs &redef;

# Frequenza massima dei record diagnostici.
const movement_diag_interval: interval = 5secs &redef;


# Le vecchie soglie vengono mantenute ESCLUSIVAMENTE
# come informazione diagnostica.
#
# NON bloccano più reverse_shell_movement.
const legacy_avg_orig_limit: double = 100.0 &redef;
const legacy_avg_resp_limit: double = 8000.0 &redef;


# =========================
# FILE DI LOG
# =========================

global reverse_shell_movement_log_path: string =
    "/var/log/zeek-custom/reverse_shell_movement.log";

# Usiamo un file v2 separato per evitare di mescolare
# la semantica diagnostica precedente con quella nuova.
global reverse_shell_movement_diag_log_path: string =
    "/var/log/zeek-custom/reverse_shell_movement_diag_v2.log";


# =========================
# RECORD DIAGNOSTICO
# =========================

type MovementDiagInfo: record {
    event_source: string &log;
    ts: time &log;
    event_type: string &log;
    logic_version: string &log;
    phase: string &log;

    uid: string &log;
    src_ip: addr &log;
    dest_ip: addr &log;
    dest_port: string &log;
    dest_proto: string &log;

    duration: interval &log;

    orig_bytes: count &log;
    resp_bytes: count &log;
    orig_pkts: count &log;
    resp_pkts: count &log;

    avg_orig: double &log;
    avg_resp: double &log;

    duration_ok: bool &log;
    orig_pkts_ok: bool &log;
    resp_pkts_ok: bool &log;
    bidirectional_ok: bool &log;

    # Condizione realmente usata dalla v2.
    core_match: bool &log;

    # Valutazione delle vecchie soglie,
    # SOLO diagnostica.
    legacy_avg_orig_ok: bool &log;
    legacy_avg_resp_ok: bool &log;
    legacy_avg_match: bool &log;

    movement_logged: bool &log;
};


# =========================
# STATO PER CONNESSIONE
# =========================

type ConnStats: record {
    uid: string;
    start_time: time;

    orig_bytes: count;
    resp_bytes: count;

    orig_pkts: count;
    resp_pkts: count;

    movement_logged: bool;
    last_diag_time: time;
};


global conn_stats: table[conn_id] of ConnStats;
# Prototipo dell'evento usato dai timer.
global movement_timer: event(id: conn_id);

# =========================
# BASELINE
# =========================

global allowed_ports: set[port] = {
    80/tcp,
    443/tcp,
    22/tcp,
    53/udp,
    53/tcp,
    1514/tcp,
    1515/tcp
};


global white_list: set[subnet] = {
    10.3.10.0/24,
    10.3.20.0/24,
    10.3.30.0/24
};


# ============================================================
# FUNZIONI DI SUPPORTO
# ============================================================


function append_reverse_shell_movement_log(
    rec: ReverseShellLive::LiveInfo)
{
    local f = open_for_append(reverse_shell_movement_log_path);

    if ( ! active_file(f) )
    {
        Reporter::warning(
            fmt(
                "Impossibile aprire il file reverse_shell_movement log: %s",
                reverse_shell_movement_log_path
            )
        );

        return;
    }

    local line = to_json(rec, T);

    if ( ! write_file(f, fmt("%s\n", line)) )
        Reporter::warning(
            fmt(
                "Errore scrittura su file reverse_shell_movement log: %s",
                reverse_shell_movement_log_path
            )
        );

    close(f);
}


function average_bytes(bytes: count, packets: count): double
{
    if ( packets == 0 )
        return 0.0;

    return count_to_double(bytes) /
           count_to_double(packets);
}


function movement_core_match(id: conn_id): bool
{
    if ( id !in conn_stats )
        return F;

    local s = conn_stats[id];

    local duration =
        network_time() - s$start_time;

    if ( duration < movement_min_duration )
        return F;

    if ( s$orig_pkts <= movement_packet_threshold )
        return F;

    if ( s$resp_pkts <= movement_packet_threshold )
        return F;

    return T;
}


function append_movement_diag(
    id: conn_id,
    phase: string)
{
    if ( id !in conn_stats )
        return;

    local s = conn_stats[id];

    local duration =
        network_time() - s$start_time;

    local avg_orig =
        average_bytes(
            s$orig_bytes,
            s$orig_pkts
        );

    local avg_resp =
        average_bytes(
            s$resp_bytes,
            s$resp_pkts
        );

    local duration_ok =
        duration >= movement_min_duration;

    local orig_pkts_ok =
        s$orig_pkts > movement_packet_threshold;

    local resp_pkts_ok =
        s$resp_pkts > movement_packet_threshold;

    local bidirectional_ok =
        orig_pkts_ok && resp_pkts_ok;

    local core_match =
        duration_ok &&
        bidirectional_ok;

    # Vecchie condizioni:
    # vengono CALCOLATE ma NON decidono più il movement.
    local legacy_avg_orig_ok =
        s$orig_pkts > 0 &&
        avg_orig < legacy_avg_orig_limit;

    local legacy_avg_resp_ok =
        s$resp_pkts > 0 &&
        avg_resp < legacy_avg_resp_limit;

    local legacy_avg_match =
        core_match &&
        legacy_avg_orig_ok &&
        legacy_avg_resp_ok;


    local rec: MovementDiagInfo = [
        $event_source="zeek",
        $ts=network_time(),
        $event_type="reverse_shell_movement_diag",
        $logic_version="v2",
        $phase=phase,

        $uid=s$uid,
        $src_ip=id$orig_h,
        $dest_ip=id$resp_h,
        $dest_port=fmt(
            "%d",
            port_to_count(id$resp_p)
        ),
        $dest_proto=fmt(
            "%s",
            get_port_transport_proto(id$resp_p)
        ),

        $duration=duration,

        $orig_bytes=s$orig_bytes,
        $resp_bytes=s$resp_bytes,
        $orig_pkts=s$orig_pkts,
        $resp_pkts=s$resp_pkts,

        $avg_orig=avg_orig,
        $avg_resp=avg_resp,

        $duration_ok=duration_ok,
        $orig_pkts_ok=orig_pkts_ok,
        $resp_pkts_ok=resp_pkts_ok,
        $bidirectional_ok=bidirectional_ok,

        $core_match=core_match,

        $legacy_avg_orig_ok=legacy_avg_orig_ok,
        $legacy_avg_resp_ok=legacy_avg_resp_ok,
        $legacy_avg_match=legacy_avg_match,

        $movement_logged=s$movement_logged
    ];


    local f =
        open_for_append(
            reverse_shell_movement_diag_log_path
        );

    if ( ! active_file(f) )
    {
        Reporter::warning(
            fmt(
                "Impossibile aprire movement diagnostic log: %s",
                reverse_shell_movement_diag_log_path
            )
        );

        return;
    }

    local line = to_json(rec, T);

    if ( ! write_file(f, fmt("%s\n", line)) )
        Reporter::warning(
            fmt(
                "Errore scrittura movement diagnostic log: %s",
                reverse_shell_movement_diag_log_path
            )
        );

    close(f);
}


function maybe_write_diag(
    id: conn_id,
    phase: string)
{
    if ( id !in conn_stats )
        return;

    local now = network_time();

    if ( now - conn_stats[id]$last_diag_time
         < movement_diag_interval )
        return;

    append_movement_diag(
        id,
        phase
    );

    conn_stats[id]$last_diag_time = now;
}


function emit_movement(
    id: conn_id)
{
    if ( id !in conn_stats )
        return;

    if ( conn_stats[id]$movement_logged )
        return;

    local s = conn_stats[id];

    local duration =
        network_time() - s$start_time;


    local log_rec: ReverseShellLive::LiveInfo = [

        $event_source="zeek",

        $ts=network_time(),

        $event_type="reverse_shell_movement",

        $uid=s$uid,

        $src_ip=id$orig_h,

        $dest_ip=id$resp_h,

        $dest_port=fmt(
            "%d",
            port_to_count(id$resp_p)
        ),

        $dest_proto=fmt(
            "%s",
            get_port_transport_proto(id$resp_p)
        ),

        $orig_bytes=s$orig_bytes,

        $resp_bytes=s$resp_bytes,

        $orig_pkts=s$orig_pkts,

        $resp_pkts=s$resp_pkts,

        $duration=duration,

        $note=fmt(
            "Possibile reverse shell ATTIVA %s -> %s:%s (dur=%s, bidirectional=yes, detector=v2)",
            id$orig_h,
            id$resp_h,
            id$resp_p,
            duration
        )
    ];


    append_reverse_shell_movement_log(
        log_rec
    );


    # IMPORTANTISSIMO:
    # una sola emissione movement per connessione.
    conn_stats[id]$movement_logged = T;


    # Conserviamo lo stato che ha causato
    # l'emissione del movement.
    append_movement_diag(
        id,
        "movement_emitted"
    );

    conn_stats[id]$last_diag_time =
        network_time();
}


function evaluate_movement(
    id: conn_id,
    phase: string)
{
    if ( id !in conn_stats )
        return;

    if ( conn_stats[id]$movement_logged )
        return;


    if ( movement_core_match(id) )
    {
        emit_movement(id);
        return;
    }


    # Se non è ancora soddisfatta la condizione,
    # conserva periodicamente lo stato diagnostico.
    maybe_write_diag(
        id,
        phase
    );
}


function track_connection(
    c: connection)
{
    # reverse_shell_movement v2 analizza esclusivamente TCP.
    #
    # new_connection() viene generato anche per flow UDP/ICMP:
    # senza questo filtro creeremmo conn_stats e timer periodici
    # inutili per traffico broadcast/multicast.
    if ( get_conn_transport_proto(c$id) != tcp )
        return;

    if ( c$id in conn_stats )
        return;

    # Destinazioni interne / whitelist:
    # non fanno parte di questo detector.
    if ( c$id$resp_h in white_list )
        return;


    # Porte considerate baseline:
    # non fanno parte di questo detector.
    if ( c$id$resp_p in allowed_ports )
        return;


    conn_stats[c$id] = [

        $uid=c$uid,

        $start_time=network_time(),

        $orig_bytes=0,

        $resp_bytes=0,

        $orig_pkts=0,

        $resp_pkts=0,

        $movement_logged=F,

        $last_diag_time=network_time()
    ];


    # Prima valutazione temporizzata.
    #
    # Questo evita di dipendere esclusivamente
    # dall'arrivo di un pacchetto esattamente
    # dopo il superamento dei 30 secondi.
    schedule movement_min_duration
    {
        ReverseShellLive::movement_timer(c$id)
    };
}


# ============================================================
# TIMER
# ============================================================


event movement_timer(id: conn_id)
{
    # La connessione potrebbe essere già stata rimossa.
    if ( id !in conn_stats )
        return;


    if ( conn_stats[id]$movement_logged )
        return;


    evaluate_movement(
        id,
        "timer_check"
    );


    # Se non è ancora stata rilevata come movement,
    # continua a rivalutarla ogni 5 secondi.
    if ( id in conn_stats &&
         ! conn_stats[id]$movement_logged )
    {
        schedule movement_recheck_interval
        {
            ReverseShellLive::movement_timer(id)
        };
    }
}


# ============================================================
# EVENTI ZEEK
# ============================================================


event new_connection(c: connection)
{
    track_connection(c);
}


event tcp_packet(
    c: connection,
    is_orig: bool,
    flags: string,
    seq: count,
    ack: count,
    len: count,
    payload: string)
{
    # Fallback:
    # se new_connection non ha inizializzato lo stato,
    # proviamo qui.
    if ( c$id !in conn_stats )
        track_connection(c);


    if ( c$id !in conn_stats )
        return;


    # Aggiornamento dei contatori.
    if ( is_orig )
    {
        conn_stats[c$id]$orig_bytes += len;
        conn_stats[c$id]$orig_pkts += 1;
    }
    else
    {
        conn_stats[c$id]$resp_bytes += len;
        conn_stats[c$id]$resp_pkts += 1;
    }


    local duration =
        network_time() -
        conn_stats[c$id]$start_time;


    # Manteniamo anche la valutazione packet-driven.
    #
    # In questo modo il detector può scattare
    # immediatamente quando arrivano i requisiti,
    # senza dover attendere il timer successivo.
    if ( duration >= movement_min_duration &&
         ! conn_stats[c$id]$movement_logged )
    {
        evaluate_movement(
            c$id,
            "packet_check"
        );
    }
}


event connection_state_remove(c: connection)
{
    if ( c$id !in conn_stats )
        return;


    # Salva sempre lo stato finale per poter capire
    # perché una connessione sia stata o meno rilevata.
    append_movement_diag(
        c$id,
        "connection_state_remove"
    );


    delete conn_stats[c$id];
}
