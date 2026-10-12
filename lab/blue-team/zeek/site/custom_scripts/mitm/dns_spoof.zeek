module MITM;

@load ./logging


export {

    #
    # Client protected in the current MITM scenario.
    #
    const protected_dns_clients: set[addr] = {
        10.3.20.4
    } &redef;


    #
    # Domains explicitly protected by this detector.
    #
    # example.com is the domain used by the current controlled
    # DNS-spoofing validation scenario.
    #
    const protected_domains: set[string] = {
        "example.com",
        "www.example.com"
    } &redef;


    #
    # Addresses belonging to private/internal networks.
    #
    const private_networks: set[subnet] = {
        10.0.0.0/8,
        172.16.0.0/12,
        192.168.0.0/16
    } &redef;


    const dns_alert_suppression: interval =
        30secs &redef;
}


global recent_dns_alerts: table[string] of time
    &write_expire=dns_alert_suppression;


function is_private_address(a: addr): bool
    {
    for (net in private_networks)
        {
        if ( a in net )
            return T;
        }

    return F;
    }


event dns_A_reply(
    c: connection,
    msg: dns_msg,
    ans: dns_answer,
    a: addr
)
    {
    #
    # Only monitor the protected victim(s).
    #
    if ( c$id$orig_h !in protected_dns_clients )
        return;


    #
    # Only evaluate domains for which an internal A answer
    # would be anomalous in this laboratory.
    #
    if ( ans$query !in protected_domains )
        return;


    #
    # Public answers are legitimate.
    #
    if ( ! is_private_address(a) )
        return;


    local alert_key =
        fmt(
            "%s|%s|%s|%s",
            c$id$orig_h,
            c$id$resp_h,
            ans$query,
            a
        );


    if ( alert_key in recent_dns_alerts )
        return;


    recent_dns_alerts[alert_key] =
        network_time();


    local reason =
        "protected_public_domain_resolved_to_private_address";


    local note =
        fmt(
            "DNS spoofing suspected: protected public domain %s resolved to private address %s for client %s via resolver %s.",
            ans$query,
            a,
            c$id$orig_h,
            c$id$resp_h
        );


    local rec: MITM::DNSInfo = [

        $event_source="zeek",

        $ts=network_time(),

        $event_type="dns_spoof",

        $query=ans$query,

        $answer_ip=a,

        $client_ip=c$id$orig_h,

        $resolver_ip=c$id$resp_h,

        $suspicious_destination_ip=a,

        $reason=reason,

        $note=note

    ];


    MITM::append_dns_log(rec);
    }
