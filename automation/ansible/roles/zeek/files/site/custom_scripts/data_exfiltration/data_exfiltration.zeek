module DataExfiltration;

export {

    type Info: record {
        ts: time &log;
        event_type: string &log;

        src_ip: addr &log;

        # Destinazione principale nella finestra corrente.
        # Non è necessariamente l'unica destinazione, ma quella che ha ricevuto più byte.
        dest_ip: addr &log;
        dest_port: count &log;
        dest_proto: string &log;
        top_dest_bytes: count &log;

        total_orig_bytes: count &log;
        packet_count: count &log;
        avg_payload_bytes: count &log;
        max_payload_bytes: count &log;

        baseline_avg_bytes: double &log;
        baseline_stddev_bytes: double &log;
        baseline_max_bytes: count &log;

        dynamic_threshold: double &log;
        window_interval: interval &log;

        note: string &log;
    };
}


# ---------------- COSTANTI / VARIABILI ----------------

const min_baseline_windows: count = 5 &redef;

global data_exfiltration_log_path: string = "/var/log/zeek-custom/data_exfiltration.log";

global white_list: set[subnet] = {
    10.3.10.0/24,
    10.3.20.0/24,
    10.3.30.0/24
};


global internal_hosts: table[addr] of record {
    # Finestra corrente
    start_time: time;
    src_ip: addr;

    total_orig_bytes: count;
    packet_count: count;
    avg_payload_bytes: count;
    max_payload_bytes: count;

    # Destinazione principale nella finestra corrente
    dest_ip: addr;
    top_dest_port: port;
    top_dest_bytes: count;

    # Baseline
    baseline_start_time: time;
    baseline_windows: count;
    baseline_total_bytes: double;
    baseline_total_squared_bytes: double;
    baseline_avg_bytes: double;
    baseline_stddev_bytes: double;
    baseline_max_bytes: count;

    # Threshold dinamica
    dynamic_threshold: double;
    baseline_done: bool;
};


# Tabella temporanea per contare i byte verso ogni destinazione nella finestra corrente.
# Chiave: src_ip, dest_ip, dest_port
global dest_bytes_window: table[addr, addr, port] of count;


# Finestra di calcolo.
# Per testing: 1 minuto.
const window_interval: interval = 1mins &redef;

# Durata baseline.
# Per testing: 5 minuti.
const baseline_duration: interval = 5mins &redef;

# Formula: threshold = mean + 3 * stddev
const stddev_factor: double = 3.0 &redef;

# Formula alternativa di sicurezza: threshold >= baseline_max * 1.2
const max_safety_factor: double = 1.2 &redef;


# Evento schedulato
global check_exfil_windows: event();


# ---------------- FUNZIONI ----------------

function append_data_exfiltration_log(rec: DataExfiltration::Info)
{
    local f = open_for_append(data_exfiltration_log_path);

    if ( ! active_file(f) )
    {
        Reporter::warning(fmt("Impossibile aprire il file data_exfiltration log: %s", data_exfiltration_log_path));
        return;
    }

    # Converte il record Zeek in JSON.
    # Il secondo parametro T dice: includi solo i campi con &log.
    local line = to_json(rec, T);

    if ( ! write_file(f, fmt("%s\n", line)) )
        Reporter::warning(fmt("Errore scrittura su file data_exfiltration log: %s", data_exfiltration_log_path));

    close(f);
}


# Estrae il numero della porta da un valore Zeek di tipo port.
function get_port_num(p: port): count
{
    return port_to_count(p);
}


# Estrae il protocollo da un valore Zeek di tipo port.
# Esempio: 9001/tcp -> "tcp"
function get_port_proto(p: port): string
{
    local ps: string = fmt("%s", p);

    if ( /tcp/ in ps )
        return "tcp";

    if ( /udp/ in ps )
        return "udp";

    if ( /icmp/ in ps )
        return "icmp";

    return "unknown";
}


# Inizializza l'host e lo inserisce nella tabella.
function init_host(src_ip: addr)
{
    if ( src_ip in internal_hosts )
        return;

    internal_hosts[src_ip] = [
        $start_time=network_time(),
        $src_ip=src_ip,

        $total_orig_bytes=0,
        $packet_count=0,
        $avg_payload_bytes=0,
        $max_payload_bytes=0,

        $dest_ip=0.0.0.0,
        $top_dest_port=0/tcp,
        $top_dest_bytes=0,

        $baseline_start_time=network_time(),
        $baseline_windows=0,
        $baseline_total_bytes=0.0,
        $baseline_total_squared_bytes=0.0,
        $baseline_avg_bytes=0.0,
        $baseline_stddev_bytes=0.0,
        $baseline_max_bytes=0,

        $dynamic_threshold=0.0,
        $baseline_done=F
    ];

    # Reporter::info(fmt("Host interno monitorato: %s", src_ip));
}


# Aggiorna la destinazione principale della finestra corrente.
function update_dest_window(src_ip: addr, dest_ip: addr, dest_port: port, len: count)
{
    if ( [src_ip, dest_ip, dest_port] !in dest_bytes_window )
        dest_bytes_window[src_ip, dest_ip, dest_port] = 0;

    dest_bytes_window[src_ip, dest_ip, dest_port] += len;

    if ( dest_bytes_window[src_ip, dest_ip, dest_port] > internal_hosts[src_ip]$top_dest_bytes )
    {
        internal_hosts[src_ip]$dest_ip = dest_ip;
        internal_hosts[src_ip]$top_dest_port = dest_port;
        internal_hosts[src_ip]$top_dest_bytes = dest_bytes_window[src_ip, dest_ip, dest_port];
    }
}


# Resetta la finestra corrente.
function reset_host_window(src_ip: addr)
{
    if ( src_ip !in internal_hosts )
        return;

    internal_hosts[src_ip]$start_time = network_time();

    internal_hosts[src_ip]$total_orig_bytes = 0;
    internal_hosts[src_ip]$packet_count = 0;
    internal_hosts[src_ip]$avg_payload_bytes = 0;
    internal_hosts[src_ip]$max_payload_bytes = 0;

    internal_hosts[src_ip]$dest_ip = 0.0.0.0;
    internal_hosts[src_ip]$top_dest_port = 0/tcp;
    internal_hosts[src_ip]$top_dest_bytes = 0;

    # Rimuove dalla tabella temporanea solo le destinazioni relative a questo src_ip.
    for ( [s, d, p] in dest_bytes_window )
    {
        if ( s == src_ip )
            delete dest_bytes_window[s, d, p];
    }
}


# Funzione per generare il log JSON custom.
function write_exfil_log(src_ip: addr, event_type: string, note: string)
{
    local log_dest_ip: addr = internal_hosts[src_ip]$dest_ip;
    local log_dest_port: count = get_port_num(internal_hosts[src_ip]$top_dest_port);
    local log_dest_proto: string = get_port_proto(internal_hosts[src_ip]$top_dest_port);
    local log_top_dest_bytes: count = internal_hosts[src_ip]$top_dest_bytes;

    # baseline_completed non rappresenta una connessione sospetta verso una destinazione specifica.
    # Quindi azzero i campi top_dest_* per evitare ambiguità nel log.
    if ( event_type == "baseline_completed" )
    {
        log_dest_ip = 0.0.0.0;
        log_dest_port = 0;
        log_dest_proto = "";
        log_top_dest_bytes = 0;
    }

    local log_rec: DataExfiltration::Info = [
        $ts=network_time(),
        $event_type=event_type,

        $src_ip=src_ip,

        $dest_ip=log_dest_ip,
        $dest_port=log_dest_port,
        $dest_proto=log_dest_proto,
        $top_dest_bytes=log_top_dest_bytes,

        $total_orig_bytes=internal_hosts[src_ip]$total_orig_bytes,
        $packet_count=internal_hosts[src_ip]$packet_count,
        $avg_payload_bytes=internal_hosts[src_ip]$avg_payload_bytes,
        $max_payload_bytes=internal_hosts[src_ip]$max_payload_bytes,

        $baseline_avg_bytes=internal_hosts[src_ip]$baseline_avg_bytes,
        $baseline_stddev_bytes=internal_hosts[src_ip]$baseline_stddev_bytes,
        $baseline_max_bytes=internal_hosts[src_ip]$baseline_max_bytes,

        $dynamic_threshold=internal_hosts[src_ip]$dynamic_threshold,
        $window_interval=window_interval,

        $note=note
    ];

    append_data_exfiltration_log(log_rec);
}


# Calcolo finale della baseline e della soglia dinamica.
function finalize_baseline(src_ip: addr)
{
    if ( src_ip !in internal_hosts )
        return;

    if ( internal_hosts[src_ip]$baseline_windows == 0 )
        return;

    local n: double = count_to_double(internal_hosts[src_ip]$baseline_windows);

    local mean: double =
        internal_hosts[src_ip]$baseline_total_bytes / n;

    local mean_square: double =
        internal_hosts[src_ip]$baseline_total_squared_bytes / n;

    local variance: double = mean_square - mean * mean;

    if ( variance < 0.0 )
        variance = 0.0;

    local stddev: double = sqrt(variance);

    internal_hosts[src_ip]$baseline_avg_bytes = mean;
    internal_hosts[src_ip]$baseline_stddev_bytes = stddev;

    local threshold_from_stddev: double =
        mean + stddev_factor * stddev;

    local threshold_from_max: double =
        count_to_double(internal_hosts[src_ip]$baseline_max_bytes) * max_safety_factor;

    if ( threshold_from_stddev > threshold_from_max )
        internal_hosts[src_ip]$dynamic_threshold = threshold_from_stddev;
    else
        internal_hosts[src_ip]$dynamic_threshold = threshold_from_max;

    internal_hosts[src_ip]$baseline_done = T;

    # Reporter::info(fmt(
    #     "Baseline completata src_ip=%s mean=%.2f stddev=%.2f baseline_max=%s dynamic_threshold=%.2f",
    #     src_ip,
    #     internal_hosts[src_ip]$baseline_avg_bytes,
    #     internal_hosts[src_ip]$baseline_stddev_bytes,
    #     internal_hosts[src_ip]$baseline_max_bytes,
    #     internal_hosts[src_ip]$dynamic_threshold
    # ));

    write_exfil_log(
        src_ip,
        "baseline_completed",
        "Baseline completata e soglia dinamica calcolata"
    );
}


function process_baseline_window(src_ip: addr)
{
    local total_bytes: count = internal_hosts[src_ip]$total_orig_bytes;
    local packets: count = internal_hosts[src_ip]$packet_count;

    local baseline_diff: interval =
        network_time() - internal_hosts[src_ip]$baseline_start_time;

    if ( packets == 0 )
    {
        if ( baseline_diff >= baseline_duration &&
             internal_hosts[src_ip]$baseline_windows >= min_baseline_windows )
        {
            finalize_baseline(src_ip);
        }

        reset_host_window(src_ip);
        return;
    }

    local x: double = count_to_double(total_bytes);

    internal_hosts[src_ip]$baseline_windows += 1;
    internal_hosts[src_ip]$baseline_total_bytes += x;
    internal_hosts[src_ip]$baseline_total_squared_bytes += x * x;

    if ( total_bytes > internal_hosts[src_ip]$baseline_max_bytes )
        internal_hosts[src_ip]$baseline_max_bytes = total_bytes;

    internal_hosts[src_ip]$avg_payload_bytes = total_bytes / packets;

    # Se vuoi loggare ogni finestra di baseline, decommenta questo blocco.
    # write_exfil_log(
    #     src_ip,
    #     "baseline_window",
    #     "Finestra aggiunta alla baseline"
    # );

    if ( baseline_diff >= baseline_duration &&
         internal_hosts[src_ip]$baseline_windows >= min_baseline_windows )
    {
        finalize_baseline(src_ip);
    }

    reset_host_window(src_ip);
}


function process_detection_window(src_ip: addr)
{
    local total_bytes: count = internal_hosts[src_ip]$total_orig_bytes;
    local packets: count = internal_hosts[src_ip]$packet_count;

    if ( packets == 0 )
    {
        reset_host_window(src_ip);
        return;
    }

    internal_hosts[src_ip]$avg_payload_bytes = total_bytes / packets;

    if ( count_to_double(total_bytes) >= internal_hosts[src_ip]$dynamic_threshold )
    {
        write_exfil_log(
            src_ip,
            "possible_data_exfiltration",
            "Byte totali in uscita superiori alla soglia dinamica; dest_ip, dest_port e dest_proto indicano la destinazione principale della finestra"
        );
    }
    else
    {
        # Se vuoi loggare anche il traffico normale, decommenta questo blocco.
        # write_exfil_log(
        #     src_ip,
        #     "normal_traffic_window",
        #     "Traffico sotto soglia dinamica"
        # );
    }

    reset_host_window(src_ip);
}


function calculate_window_for_host(src_ip: addr)
{
    if ( src_ip !in internal_hosts )
        return;

    if ( ! internal_hosts[src_ip]$baseline_done )
        process_baseline_window(src_ip);
    else
        process_detection_window(src_ip);
}


# ---------------- EVENTI ----------------

event zeek_init()
{
    # Reporter::info(fmt(
    #     "DataExfiltration avviato window=%s baseline_duration=%s min_baseline_windows=%s stddev_factor=%.2f max_safety_factor=%.2f",
    #     window_interval,
    #     baseline_duration,
    #     min_baseline_windows,
    #     stddev_factor,
    #     max_safety_factor
    # ));

    schedule window_interval { check_exfil_windows() };
}


event tcp_packet(c: connection, is_orig: bool, flags: string,
                 seq: count, ack: count, len: count, payload: string)
{
    # Conta solo traffico originato dall'host interno verso l'esterno.
    if ( ! is_orig )
        return;

    # Ignora ACK o pacchetti senza payload.
    if ( len == 0 )
        return;

    # Solo traffico interno -> esterno.
    if ( c$id$orig_h !in white_list )
        return;

    if ( c$id$resp_h in white_list )
        return;

    local src_ip: addr = c$id$orig_h;
    local dest_ip: addr = c$id$resp_h;
    local dest_port: port = c$id$resp_p;

    init_host(src_ip);

    internal_hosts[src_ip]$total_orig_bytes += len;
    internal_hosts[src_ip]$packet_count += 1;

    if ( len > internal_hosts[src_ip]$max_payload_bytes )
        internal_hosts[src_ip]$max_payload_bytes = len;

    update_dest_window(src_ip, dest_ip, dest_port, len);
}


event check_exfil_windows()
{
    for ( src_ip in internal_hosts )
    {
        local timediff: interval =
            network_time() - internal_hosts[src_ip]$start_time;

        if ( timediff >= window_interval )
            calculate_window_for_host(src_ip);
    }

    schedule window_interval { check_exfil_windows() };
}