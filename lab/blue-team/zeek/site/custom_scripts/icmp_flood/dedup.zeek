# ICMP Flood v1.7-rc2: one-to-one TTL-decrement pairing of mirror copies.
#
# A candidate is suppressed ONLY if ALL conditions hold:
#   1. Same observed source/destination, ICMP echo ID/sequence, payload.
#   2. The earlier observation's IPv4 TTL is exactly one higher.
#   3. The observations are less than dedup_window apart.
#   4. The earlier observation has NOT already been paired/consumed.
#
# This is intentionally asymmetric: only pre-router -> post-router ordering
# is deduplicated, as independently confirmed by tcpdump in this lab.
# Same-TTL repeats and reversed observations remain countable (fail-open).
# Different actual packets crafted with matching signatures and sequential
# TTLs can still collide; this is a heuristic, NOT physical identity proof.
#
# 'observe': count candidates but do not affect the detector sliding window.
# 'enforce': exclude confirmed TTL-transition candidates from the ring.
# 'off': keep all raw observations; no fingerprint processing.
#
# Memory per active destination remains bounded by dedup_max_signatures.

module ICMPFlood;

export {
    const dedup_mode: string = "observe" &redef;
    const dedup_window: interval = 2msec &redef;
    const dedup_max_signatures: count = 1024 &redef;
    const dedup_max_payload_bytes: count = 1024 &redef;
    const dedup_idle_timeout: interval = 10min &redef;

    global echo_duplicate_candidate: function(c: connection, dst: addr,
                                              observed_ttl: count,
                                              echo_id: count, echo_seq: count,
                                              payload: string, now: time): bool;
}

type SignatureSlot: record {
    fingerprint: string;
    seen: time;
    ttl: count;
};

global signature_slots: table[addr, count] of SignatureSlot;
global signature_latest: table[addr, string] of count;

# Clear the per-target bounded ring/index after an inactivity timeout.
function expire_signature_target(t: table[addr] of count, dst: addr): interval
    {
    local slot: count = 0;
    while ( slot < dedup_max_signatures )
        {
        if ( [dst, slot] in signature_slots )
            {
            local previous_key = signature_slots[dst, slot]$fingerprint;
            if ( [dst, previous_key] in signature_latest &&
                 signature_latest[dst, previous_key] == slot )
                delete signature_latest[dst, previous_key];
            delete signature_slots[dst, slot];
            }
        ++slot;
        }
    return 0sec;
    }

global signature_next: table[addr] of count
    &write_expire=dedup_idle_timeout
    &expire_func=expire_signature_target;

function echo_duplicate_candidate(c: connection, dst: addr,
                                  observed_ttl: count,
                                  echo_id: count, echo_seq: count,
                                  payload: string, now: time): bool
    {
    # Fail open if the feature is disabled, out of bounds, or misconfigured.
    if ( dedup_mode == "off" || dedup_max_signatures == 0 ||
         dedup_window <= 0sec || observed_ttl > 255 )
        return F;

    # Skip hashing large attacker-controlled payloads; count them normally.
    if ( |payload| > dedup_max_payload_bytes )
        return F;

    # TTL must NOT be included in this fingerprint: the router changes it.
    # SHA-256 is just a content identity heuristic, not source authentication.
    local key = sha256_hash(
        fmt("%s|%s|%d|%d|", c$id$orig_h, dst, echo_id, echo_seq),
        payload);

    if ( dst !in signature_next )
        signature_next[dst] = 0;

    if ( [dst, key] in signature_latest )
        {
        local prior_slot = signature_latest[dst, key];
        if ( [dst, prior_slot] in signature_slots )
            {
            local prior = signature_slots[dst, prior_slot];
            local elapsed = now - prior$seen;

            # Exactly ONE routed TTL decrement; earlier observation must be
            # the pre-router copy. Require a strict one-to-one match.
            if ( elapsed >= 0sec && elapsed < dedup_window &&
                 observed_ttl < 255 && prior$ttl == observed_ttl + 1 )
                {
                # Consume the reference so a third identical observation
                # cannot be suppressed by matching the same first packet.
                delete signature_latest[dst, key];

                # Refresh per-destination idle expiration on matched traffic.
                signature_next[dst] = signature_next[dst];
                return T;
                }
            }
        }

    # Every non-matching observation counts as unique. Record it as a new
    # potential pre-router sample and use a bounded FIFO ring for storage.
    local slot = signature_next[dst];
    if ( [dst, slot] in signature_slots )
        {
        local evicted = signature_slots[dst, slot]$fingerprint;
        if ( [dst, evicted] in signature_latest &&
             signature_latest[dst, evicted] == slot )
            delete signature_latest[dst, evicted];
        }

    signature_slots[dst, slot] =
        [$fingerprint=key, $seen=now, $ttl=observed_ttl];
    signature_latest[dst, key] = slot;

    ++slot;
    if ( slot >= dedup_max_signatures )
        slot = 0;
    signature_next[dst] = slot;
    return F;
    }
