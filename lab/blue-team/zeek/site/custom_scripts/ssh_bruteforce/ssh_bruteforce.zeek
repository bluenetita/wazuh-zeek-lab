@load base/protocols/ssh

module ssh_bruteforce;


export {

    #
    # ============================================================
    # RECORD LOG CUSTOM
    # ============================================================
    #

    type Info: record {

        event_source: string        &log;
        ts: time                    &log;
        event_type: string          &log;

        uid: string                 &log;

        src_ip: addr                &log;
        src_port: string            &log;

        dest_ip: addr               &log;
        dest_port: string           &log;
        dest_proto: string          &log;

        #
        # Il risultato dell'autenticazione viene scritto solamente
        # quando Zeek riesce realmente a determinarlo.
        #
        # T       = autenticazione riuscita
        # F       = autenticazione fallita
        # assente = risultato sconosciuto
        #
        auth_success: bool          &log &optional;

        #
        # Fallimenti confermati tramite ssh_auth_result().
        #
        failed_connections: count   &log;

        #
        # Connessioni SSH per cui Zeek non è riuscito
        # a determinare con sicurezza l'esito auth.
        #
        unknown_connections: count  &log;

        #
        # Numero cumulativo di authentication attempts
        # quando disponibile.
        #
        auth_attempts: count        &log;

        first_seen: time            &log;
        last_seen: time             &log;

        connection_threshold: count &log;
        attempt_threshold: count    &log;

        detection_window: string    &log;

        detection_reason: string    &log;
        note: string                &log;
    };


    #
    # ============================================================
    # CONFIGURAZIONE
    # ============================================================
    #

    #
    # Numero di connessioni SSH ripetute verso la stessa coppia
    #
    # source IP -> destination IP -> destination port
    #
    # necessario per generare la detection.
    #
    # Il conteggio comprende:
    #
    # - fallimenti confermati;
    # - connessioni con risultato auth sconosciuto.
    #
    const failed_connection_threshold: count = 5 &redef;


    #
    # Numero cumulativo di authentication attempts osservati.
    #
    const auth_attempt_threshold: count = 5 &redef;


    #
    # Finestra temporale della detection.
    #
    const brute_force_window: interval = 60sec &redef;


    #
    # Tempo massimo entro cui considerare interessante
    # un login riuscito dopo un brute force rilevato.
    #
    const success_followup_window: interval = 5min &redef;
}


#
# ================================================================
# STATO
# ================================================================
#

#
# Stato mantenuto separatamente per ogni:
#
# source IP -> destination IP -> destination port
#
# Questo impedisce che attività SSH rivolte a vittime differenti
# vengano fuse nella stessa sequenza.
#
type BruteState: record {

    first_seen: time;
    last_seen: time;

    #
    # Fallimenti confermati da ssh_auth_result().
    #
    failed_connections: count;

    #
    # Connessioni SSH per cui Zeek non ha determinato
    # il risultato dell'autenticazione.
    #
    unknown_connections: count;

    #
    # Authentication attempts osservati quando disponibili.
    #
    auth_attempts: count;

    #
    # Impedisce alert duplicati per la stessa sequenza.
    #
    alerted: bool;
};


#
# Lo stato viene eliminato automaticamente se non viene
# aggiornato per 10 minuti.
#
global brute_state: table[addr, addr, port] of BruteState
    &write_expire=10min;


#
# ================================================================
# FILE LOG CUSTOM
# ================================================================
#

global ssh_bruteforce_log_path: string =
    "/var/log/zeek-custom/ssh_bruteforce.log";


#
# ================================================================
# SCRITTURA LOG JSON
# ================================================================
#

function append_ssh_bruteforce_log(rec: ssh_bruteforce::Info)
    {
    local f = open_for_append(ssh_bruteforce_log_path);

    if ( ! active_file(f) )
        {
        Reporter::warning(
            fmt(
                "Impossibile aprire il file SSH brute force log: %s",
                ssh_bruteforce_log_path
            )
        );

        return;
        }


    #
    # Converte il record Zeek in JSON.
    #
    # T = include solamente i campi marcati con &log.
    #
    local line = to_json(rec, T);


    if ( ! write_file(f, fmt("%s\n", line)) )
        {
        Reporter::warning(
            fmt(
                "Errore scrittura SSH brute force log: %s",
                ssh_bruteforce_log_path
            )
        );
        }


    close(f);
    }


#
# ================================================================
# GENERAZIONE EVENTO CUSTOM
# ================================================================
#

function generate_detection(
    uid: string,
    id: conn_id,
    state: BruteState,
    event_type: string,
    auth_known: bool,
    auth_success: bool,
    reason: string,
    note: string
)
    {
    local log_rec: ssh_bruteforce::Info = [

        $event_source="zeek",

        $ts=network_time(),

        $event_type=event_type,

        $uid=uid,

        $src_ip=id$orig_h,

        $src_port=fmt(
            "%d",
            port_to_count(id$orig_p)
        ),

        $dest_ip=id$resp_h,

        $dest_port=fmt(
            "%d",
            port_to_count(id$resp_p)
        ),

        $dest_proto=fmt(
            "%s",
            get_port_transport_proto(id$resp_p)
        ),

        $failed_connections=state$failed_connections,

        $unknown_connections=state$unknown_connections,

        $auth_attempts=state$auth_attempts,

        $first_seen=state$first_seen,

        $last_seen=state$last_seen,

        $connection_threshold=failed_connection_threshold,

        $attempt_threshold=auth_attempt_threshold,

        $detection_window=fmt(
            "%s",
            brute_force_window
        ),

        $detection_reason=reason,

        $note=note
    ];


    #
    # Non inventiamo un risultato di autenticazione.
    #
    # Il campo auth_success viene scritto solamente quando
    # Zeek conosce realmente l'esito.
    #
    if ( auth_known )
        {
        log_rec$auth_success = auth_success;
        }


    append_ssh_bruteforce_log(log_rec);
    }


#
# ================================================================
# VALUTAZIONE CENTRALIZZATA DELLA DETECTION
# ================================================================
#

function evaluate_bruteforce_detection(
    uid: string,
    id: conn_id,
    state: BruteState,
    auth_known: bool,
    auth_success: bool
): BruteState
    {

    #
    # Se la sequenza è già stata segnalata,
    # non generiamo duplicati.
    #
    if ( state$alerted )
        {
        return state;
        }


    #
    # Numero totale di connessioni SSH rilevanti.
    #
    # Manteniamo distinti:
    #
    # - fallimenti certi;
    # - esiti sconosciuti.
    #
    # Ma entrambi possono contribuire al pattern
    # comportamentale di connessioni SSH ripetute.
    #
    local observed_connections =
        state$failed_connections +
        state$unknown_connections;


    #
    # Nessuna soglia raggiunta.
    #
    if (
        observed_connections < failed_connection_threshold &&
        state$auth_attempts < auth_attempt_threshold
    )
        {
        return state;
        }


    #
    # Valori di default per la detection comportamentale.
    #
    local reason =
        "ssh_connection_pattern_threshold";

    local note =
        "Repeated SSH connection activity detected from the same source to the same destination.";


    #
    # ============================================================
    # SEGNALE FORTE:
    #
    # fallimenti confermati + authentication attempts
    # ============================================================
    #
    if (
        state$failed_connections >= failed_connection_threshold &&
        state$auth_attempts >= auth_attempt_threshold
    )
        {
        reason =
            "failed_connections_and_auth_attempts_threshold";

        note =
            "Multiple failed SSH authentications detected from the same source to the same destination.";
        }


    #
    # ============================================================
    # FALLIMENTI CONFERMATI
    # ============================================================
    #
    else if (
        state$failed_connections >= failed_connection_threshold
    )
        {
        reason =
            "failed_connections_threshold";

        note =
            "Multiple failed SSH authentications detected from the same source to the same destination.";
        }


    #
    # ============================================================
    # AUTHENTICATION ATTEMPTS
    # ============================================================
    #
    else if (
        state$auth_attempts >= auth_attempt_threshold
    )
        {
        reason =
            "auth_attempts_threshold";

        note =
            "Multiple SSH authentication attempts detected from the same source to the same destination.";
        }


    #
    # ============================================================
    # FALLBACK:
    #
    # connessioni SSH ripetute con risultato auth sconosciuto
    # ============================================================
    #
    else if (
        state$unknown_connections > 0
    )
        {
        reason =
            "repeated_ssh_connections_unknown_auth";

        note =
            "Repeated SSH connections detected from the same source to the same destination; authentication outcome was not available from network analysis.";
        }


    #
    # Generazione evento custom.
    #
    generate_detection(
        uid,
        id,
        state,
        "ssh_bruteforce",
        auth_known,
        auth_success,
        reason,
        note
    );


    #
    # Segna la sequenza come già rilevata.
    #
    state$alerted = T;


    return state;
    }


#
# ================================================================
# SSH AUTHENTICATION RESULT
# ================================================================
#

#
# Viene chiamato quando Zeek riesce a determinare
# con sufficiente confidenza il risultato finale
# dell'autenticazione SSH.
#
event ssh_auth_result(
    c: connection,
    result: bool,
    auth_attempts: count
)
    {
    local src = c$id$orig_h;

    local dst = c$id$resp_h;

    local dport = c$id$resp_p;

    local now = network_time();


    #
    # ============================================================
    # AUTENTICAZIONE RIUSCITA
    # ============================================================
    #
    if ( result )
        {

        #
        # Nessuna precedente attività rilevante:
        # normale autenticazione SSH.
        #
        if ( [src, dst, dport] !in brute_state )
            {
            return;
            }


        local previous_state =
            brute_state[src, dst, dport];


        #
        # Generiamo ssh_bruteforce_success solamente se:
        #
        # 1. il brute force/pattern SSH era stato rilevato;
        # 2. il login riuscito avviene entro la follow-up window.
        #
        if (
            previous_state$alerted &&
            now - previous_state$last_seen <= success_followup_window
        )
            {
            previous_state$last_seen = now;


            generate_detection(
                c$uid,
                c$id,
                previous_state,
                "ssh_bruteforce_success",
                T,
                T,
                "success_after_bruteforce",
                "Successful SSH authentication observed after detected brute-force activity."
            );
            }


        #
        # Un'autenticazione riuscita conclude la sequenza
        # precedente per questa coppia source/destination/port.
        #
        delete brute_state[src, dst, dport];


        return;
        }


    #
    # ============================================================
    # AUTENTICAZIONE FALLITA
    # ============================================================
    #

    #
    # Primo fallimento osservato per:
    #
    # source -> destination -> SSH destination port
    #
    if ( [src, dst, dport] !in brute_state )
        {
        brute_state[src, dst, dport] = [

            $first_seen=now,

            $last_seen=now,

            $failed_connections=0,

            $unknown_connections=0,

            $auth_attempts=0,

            $alerted=F
        ];
        }


    local state =
        brute_state[src, dst, dport];


    #
    # Se siamo usciti dalla finestra temporale,
    # iniziamo una nuova sequenza.
    #
    if (
        now - state$first_seen > brute_force_window
    )
        {
        state = [

            $first_seen=now,

            $last_seen=now,

            $failed_connections=0,

            $unknown_connections=0,

            $auth_attempts=0,

            $alerted=F
        ];
        }


    #
    # Fallimento confermato.
    #
    state$failed_connections += 1;


    #
    # Authentication attempts osservati da Zeek.
    #
    state$auth_attempts += auth_attempts;


    state$last_seen = now;


    #
    # Valutazione delle soglie.
    #
    state = evaluate_bruteforce_detection(
        c$uid,
        c$id,
        state,
        T,
        F
    );


    #
    # Salvataggio stato aggiornato.
    #
    brute_state[src, dst, dport] = state;
    }


#
# ================================================================
# SSH RESULT UNKNOWN FALLBACK
# ================================================================
#

#
# SSH::log_ssh viene generato quando il record SSH
# viene inviato al logging framework.
#
# Se auth_success è presente, ssh_auth_result() rappresenta
# il segnale più affidabile e questa connessione non deve
# essere conteggiata nuovamente.
#
# Se auth_success è assente, invece, Zeek ha osservato una
# sessione SSH valida ma non è riuscito a determinare con
# sufficiente confidenza l'esito dell'autenticazione.
#
event SSH::log_ssh(rec: SSH::Info)
    {

    #
    # Risultato conosciuto.
    #
    # La connessione viene gestita dal ramo ssh_auth_result().
    #
    if ( rec?$auth_success )
        {
        return;
        }


    local src = rec$id$orig_h;

    local dst = rec$id$resp_h;

    local dport = rec$id$resp_p;

    local now = network_time();


    #
    # Primo evento con esito sconosciuto per questa coppia.
    #
    if ( [src, dst, dport] !in brute_state )
        {
        brute_state[src, dst, dport] = [

            $first_seen=now,

            $last_seen=now,

            $failed_connections=0,

            $unknown_connections=0,

            $auth_attempts=0,

            $alerted=F
        ];
        }


    local state =
        brute_state[src, dst, dport];


    #
    # Nuova finestra temporale.
    #
    if (
        now - state$first_seen > brute_force_window
    )
        {
        state = [

            $first_seen=now,

            $last_seen=now,

            $failed_connections=0,

            $unknown_connections=0,

            $auth_attempts=0,

            $alerted=F
        ];
        }


    #
    # IMPORTANTE:
    #
    # Questo NON significa authentication failure.
    #
    # Significa esclusivamente che Zeek ha osservato
    # una sessione SSH per cui non dispone di un esito
    # affidabile dell'autenticazione.
    #
    state$unknown_connections += 1;


    state$last_seen = now;


    #
    # Valutazione del pattern comportamentale.
    #
    state = evaluate_bruteforce_detection(
        rec$uid,
        rec$id,
        state,
        F,
        F
    );


    #
    # Salvataggio dello stato.
    #
    brute_state[src, dst, dport] = state;
    }
