module MITM;

@load ./logging


export {

    #
    # Trusted IP -> MAC bindings for VLAN 20.
    #
    # These values come from the laboratory baseline.
    #
    const protected_bindings: table[addr] of string = {

        [10.3.20.1] = "bc:24:11:54:83:fe",
        [10.3.20.4] = "bc:24:11:50:08:a8"

    } &redef;


    #
    # Known MAC ownership.
    #
    # This is used only for attribution/context.
    # Detection DOES NOT depend on the attacker being known.
    #
    const known_mac_owners: table[string] of addr = {

        ["bc:24:11:da:1c:99"] = 10.3.20.2,
        ["bc:24:11:50:08:a8"] = 10.3.20.4,
        ["bc:24:11:54:83:fe"] = 10.3.20.1

    } &redef;


    #
    # Prevent repeated poisoned ARP packets from generating
    # an excessive number of identical events.
    #
    const alert_suppression: interval = 30secs &redef;
}


#
# Detection key:
#
# operation | claimed IP | observed MAC | target IP
#
global recent_alerts: table[string] of time
    &write_expire=alert_suppression;


function check_arp_binding(
    operation: string,
    mac_src: string,
    mac_dst: string,
    SPA: addr,
    SHA: string,
    TPA: addr,
    THA: string
)
    {
    #
    # We only enforce bindings for infrastructure/endpoints
    # explicitly protected by this detector.
    #
    if ( SPA !in protected_bindings )
        return;


    local expected_mac = protected_bindings[SPA];


    #
    # Legitimate binding.
    #
    if ( SHA == expected_mac )
        return;


    #
    # Deduplicate repeated poisoning frames.
    #
    local alert_key =
        fmt(
            "%s|%s|%s|%s",
            operation,
            SPA,
            SHA,
            TPA
        );


    if ( alert_key in recent_alerts )
        return;


    recent_alerts[alert_key] = network_time();


    local reason = "protected_ip_mac_mismatch";


    local note =
        fmt(
            "ARP spoofing suspected: IP %s is expected at MAC %s but was advertised by MAC %s. Target IP: %s.",
            SPA,
            expected_mac,
            SHA,
            TPA
        );


    local rec: MITM::ARPInfo = [

        $event_source="zeek",

        $ts=network_time(),

        $event_type="arp_spoof",

        $arp_operation=operation,

        $claimed_ip=SPA,

        $expected_mac=expected_mac,

        $observed_mac=SHA,

        $target_ip=TPA,

        $target_mac=THA,

        $ethernet_src=mac_src,

        $ethernet_dst=mac_dst,

        $reason=reason,

        $note=note

    ];


    #
    # Attribution is contextual only.
    #
    # A malicious host can spoof its own source MAC,
    # therefore this field must not be treated as proof
    # of attacker identity.
    #
    if ( SHA in known_mac_owners )
        {
        rec$suspected_attacker_ip =
            known_mac_owners[SHA];

        rec$suspected_attacker_mac =
            SHA;
        }


    MITM::append_arp_log(rec);
    }


event arp_request(
    mac_src: string,
    mac_dst: string,
    SPA: addr,
    SHA: string,
    TPA: addr,
    THA: string
)
    {
    check_arp_binding(
        "request",
        mac_src,
        mac_dst,
        SPA,
        SHA,
        TPA,
        THA
    );
    }


event arp_reply(
    mac_src: string,
    mac_dst: string,
    SPA: addr,
    SHA: string,
    TPA: addr,
    THA: string
)
    {
    check_arp_binding(
        "reply",
        mac_src,
        mac_dst,
        SPA,
        SHA,
        TPA,
        THA
    );
    }
