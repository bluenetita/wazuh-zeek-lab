module MITM;

export {

    #
    # ============================================================
    # ARP
    # ============================================================
    #

    type ARPInfo: record {
        event_source: string &log;
        ts: time &log;

        event_type: string &log;
        arp_operation: string &log;

        claimed_ip: addr &log;
        expected_mac: string &log;
        observed_mac: string &log;

        target_ip: addr &log;
        target_mac: string &log;

        ethernet_src: string &log;
        ethernet_dst: string &log;

        suspected_attacker_ip: addr &log &optional;
        suspected_attacker_mac: string &log &optional;

        reason: string &log;
        note: string &log;
    };


    global arp_spoof_log_path: string =
        "/var/log/zeek-custom/mitm_arp.log"
        &redef;


    global append_arp_log:
        function(rec: ARPInfo);


    #
    # ============================================================
    # DHCP
    # ============================================================
    #

    type DHCPInfo: record {
        event_source: string &log;
        ts: time &log;

        event_type: string &log;
        dhcp_message: string &log;
        dhcp_message_type: count &log;

        transaction_id: count &log;

        server_ip: addr &log &optional;

        offered_ip: addr &log;
        client_mac: string &log;

        subnet_mask: addr &log &optional;
        router_ip: addr &log &optional;

        dns_server_1: addr &log &optional;
        dns_server_2: addr &log &optional;

        flow_orig_ip: addr &log;
        flow_resp_ip: addr &log;

        reason: string &log;
        note: string &log;
    };


    global dhcp_spoof_log_path: string =
        "/var/log/zeek-custom/mitm_dhcp.log"
        &redef;


    global append_dhcp_log:
        function(rec: DHCPInfo);

    #
    # ============================================================
    # DNS
    # ============================================================
    #

    type DNSInfo: record {
        event_source: string &log;
        ts: time &log;

        event_type: string &log;

        query: string &log;
        answer_ip: addr &log;

        client_ip: addr &log;
        resolver_ip: addr &log;

        suspicious_destination_ip: addr &log;

        reason: string &log;
        note: string &log;
    };


    global dns_spoof_log_path: string =
        "/var/log/zeek-custom/mitm_dns.log"
        &redef;


    global append_dns_log:
        function(rec: DNSInfo);
}


#
# ============================================================
# ARP LOG WRITER
# ============================================================
#

function append_arp_log(rec: ARPInfo)
    {
    local f = open_for_append(arp_spoof_log_path);

    if ( ! active_file(f) )
        {
        Reporter::warning(
            fmt(
                "Unable to open MITM ARP log: %s",
                arp_spoof_log_path
            )
        );

        return;
        }

    local line = to_json(rec, T);

    if ( ! write_file(f, fmt("%s\n", line)) )
        {
        Reporter::warning(
            fmt(
                "Unable to write MITM ARP log: %s",
                arp_spoof_log_path
            )
        );
        }

    close(f);
    }


#
# ============================================================
# DHCP LOG WRITER
# ============================================================
#

function append_dhcp_log(rec: DHCPInfo)
    {
    local f = open_for_append(dhcp_spoof_log_path);

    if ( ! active_file(f) )
        {
        Reporter::warning(
            fmt(
                "Unable to open MITM DHCP log: %s",
                dhcp_spoof_log_path
            )
        );

        return;
        }

    local line = to_json(rec, T);

    if ( ! write_file(f, fmt("%s\n", line)) )
        {
        Reporter::warning(
            fmt(
                "Unable to write MITM DHCP log: %s",
                dhcp_spoof_log_path
            )
        );
        }

    close(f);
    }

#
# ============================================================
# DNS LOG WRITER
# ============================================================
#

function append_dns_log(rec: DNSInfo)
    {
    local f = open_for_append(dns_spoof_log_path);

    if ( ! active_file(f) )
        {
        Reporter::warning(
            fmt(
                "Unable to open MITM DNS log: %s",
                dns_spoof_log_path
            )
        );

        return;
        }

    local line = to_json(rec, T);

    if ( ! write_file(f, fmt("%s\n", line)) )
        {
        Reporter::warning(
            fmt(
                "Unable to write MITM DNS log: %s",
                dns_spoof_log_path
            )
        );
        }

    close(f);
    }
