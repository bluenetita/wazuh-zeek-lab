module MITM;

@load ./logging


export {

    #
    # VLAN 20 is statically addressed in the current laboratory.
    # No legitimate DHCP server is expected on this subnet.
    #
    const monitored_dhcp_subnet: subnet =
        10.3.20.0/24 &redef;


    #
    # DHCP message types.
    #
    const DHCP_OFFER: count = 2;
    const DHCP_ACK: count = 5;


    #
    # Suppress duplicate packets belonging to the same
    # DHCP transaction.
    #
    const dhcp_alert_suppression: interval =
        30secs &redef;
}


global recent_dhcp_alerts: table[string] of time
    &write_expire=dhcp_alert_suppression;


function dhcp_message_name(message_type: count): string
    {
    if ( message_type == DHCP_OFFER )
        return "DHCPOFFER";

    if ( message_type == DHCP_ACK )
        return "DHCPACK";

    return fmt("DHCP_%d", message_type);
    }


event dhcp_message(
    c: connection,
    is_orig: bool,
    msg: DHCP::Msg,
    options: DHCP::Options
)
    {
    #
    # A rogue DHCP attack is relevant when a server sends
    # an OFFER or ACK.
    #
    if ( msg$m_type != DHCP_OFFER &&
         msg$m_type != DHCP_ACK )
        return;


    local server_ip = 0.0.0.0;
    local router_ip = 0.0.0.0;

    local dns_server_1 = 0.0.0.0;
    local dns_server_2 = 0.0.0.0;


    #
    # DHCP Server Identifier - Option 54.
    #
    if ( options?$serv_addr )
        server_ip = options$serv_addr;

    #
    # Fallback to BOOTP siaddr when Option 54 is absent.
    #
    else if ( msg$siaddr != 0.0.0.0 )
        server_ip = msg$siaddr;


    #
    # Router - Option 3.
    #
    if ( options?$routers &&
         |options$routers| > 0 )
        {
        router_ip = options$routers[0];
        }


    #
    # DNS servers - Option 6.
    #
    if ( options?$dns_servers )
        {
        if ( |options$dns_servers| > 0 )
            dns_server_1 =
                options$dns_servers[0];

        if ( |options$dns_servers| > 1 )
            dns_server_2 =
                options$dns_servers[1];
        }


    #
    # Determine whether this DHCP response belongs to
    # the monitored VLAN 20 addressing space.
    #
    local relevant = F;

    if ( msg$yiaddr in monitored_dhcp_subnet )
        relevant = T;

    if ( server_ip in monitored_dhcp_subnet )
        relevant = T;

    if ( router_ip in monitored_dhcp_subnet )
        relevant = T;


    if ( ! relevant )
        return;


    #
    # One alert per message type / transaction / server.
    #
    local alert_key =
        fmt(
            "%d|%d|%s|%s",
            msg$m_type,
            msg$xid,
            server_ip,
            msg$chaddr
        );


    if ( alert_key in recent_dhcp_alerts )
        return;


    recent_dhcp_alerts[alert_key] =
        network_time();


    local message_name =
        dhcp_message_name(msg$m_type);


    local reason =
        "unexpected_dhcp_server_on_static_segment";


    local note =
        fmt(
            "Rogue DHCP suspected: unexpected %s from server %s offered IP %s to client MAC %s. Advertised router: %s.",
            message_name,
            server_ip,
            msg$yiaddr,
            msg$chaddr,
            router_ip
        );


    local rec: MITM::DHCPInfo = [

        $event_source="zeek",

        $ts=network_time(),

        $event_type="dhcp_spoof",

        $dhcp_message=message_name,

        $dhcp_message_type=msg$m_type,

        $transaction_id=msg$xid,

        $offered_ip=msg$yiaddr,

        $client_mac=msg$chaddr,

        $flow_orig_ip=c$id$orig_h,

        $flow_resp_ip=c$id$resp_h,

        $reason=reason,

        $note=note

    ];


    if ( server_ip != 0.0.0.0 )
        rec$server_ip = server_ip;


    if ( options?$subnet_mask )
        rec$subnet_mask =
            options$subnet_mask;


    if ( router_ip != 0.0.0.0 )
        rec$router_ip =
            router_ip;


    if ( dns_server_1 != 0.0.0.0 )
        rec$dns_server_1 =
            dns_server_1;


    if ( dns_server_2 != 0.0.0.0 )
        rec$dns_server_2 =
            dns_server_2;


    MITM::append_dhcp_log(rec);
    }
