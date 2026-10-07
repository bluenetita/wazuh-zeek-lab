# SSH Brute Force: Endpoint Normalization and Multi-Host Correlation

## Objective

Distinguish `A1 -> V1`, `A1 -> V2`, `A2 -> V1`, and `A2 -> V2`, preventing a login on one endpoint from completing the correlation chain of another endpoint. The normalizer is not an external program: it uses the Wazuh agent's native `out_format` and XML decoders on the Manager.

[Topology](../../docs/topology-ssh-validation-2026-10.md) - [Tests](TESTS.md) - [Evidence](../../evidence/ssh-bruteforce/README.md).

## Endpoint path

On the SSH server, the `/var/log/auth.log` collector selects `sshd` and appends:

```xml
<out_format>$(log) wazuh_dst_ip=$(host_ip)</out_format>
```

The decoder retains `srcip`, extracts `dstip`, and adds dynamic aliases `src_ip` and `dest_ip`. The ServerDB agent also collects non-SSH journald events so that the same SSH source is not intentionally duplicated. The effective configuration should also be checked when centralized `agent.conf` files are in use.

`$(host_ip)` is an address selected by the agent. It is not proof of the actual local address of every SSH socket, and it is not necessarily identical to the enrollment IP. During the tests, the values were V1 `10.3.30.3` and V2 `10.3.30.4`. On multihomed hosts, with NAT, IP aliases, or multiple listening addresses, the semantics must be reassessed.

## Network path and unknown authentication outcome

The script maintains separate state for `[src, dst, dport]`. `ssh_auth_result` handles authentication outcomes inferred by the SSH analyzer; `SSH::log_ssh` handles sessions where `auth_success` is not populated. The two paths are designed not to increment the same session when an authentication result is present.

In the fallback path: `failed_connections=0`, `unknown_connections=5`, `auth_attempts=0`, and `auth_success` is absent. This represents **candidate repeated SSH activity**, not proof of five incorrect passwords. Failure confirmation comes from `sshd` through Wazuh. Even a known auth result on the Zeek side remains a network inference rather than a server audit record.

The Zeek collector sends only the custom log with the `zeek_ssh_json: ` prefix. The dedicated decoder uses `JSON_Decoder` and adds static IPv4 aliases for correlation.

## Correlation rules

| ID | Function | Window | Key |
|---|---|---|---|
| 100922 | Dedicated SSH JSON decoder base | Single event | Location + Zeek source |
| 100920 | SSH candidate from the sensor | Thresholds in Zeek script | Network fields |
| 100921 | Inferred success after SSH pattern | Script follow-up | `[src,dst,dport]` |
| 5712 / 5763 | Stock endpoint aggregation | 8 events / 120 s; observed `ignore=60` | Source within agent context |
| 120935 | Previous Zeek + endpoint failures | 300 s | `srcip`, `dstip`, cross-agent |
| 120938 / 120939 | Previous endpoint failures + Zeek | 300 s | `srcip`, `dstip`, cross-agent |
| 120936 | Previous scan + confirmed SSH pair | 900 s | scanner `src_ip` |
| 120937 | Successful login after 120936 | 900 s | Same IP pair |
| 120940 | Fan-out | 900 s, frequency 2 | Same source, different destination |
| 120941 | Fan-in | 900 s, frequency 2 | Different source, same destination |

`120936` is intentionally source-oriented because a multi-target scan does not necessarily provide a single victim to compare. `120937` requires both IP addresses but **does not require the same username** as the brute-force attempts. The positive test used attempts against a nonexistent user followed by a successful login as the real `serverdb` user; this demonstrates a host-level chain, not recovery of that user's password.

`global_frequency` enables correlation between agents on the same Manager. It is not distributed correlation across cluster nodes.

## Thresholds and state

Zeek uses 5 relevant connections or 5 inferred attempts, a 60-second window anchored to the first event in the sequence, and state expiration after 10 minutes without writes. Success follow-up is 5 minutes from the latest sequence event. These values describe the laboratory configuration, not a certified exact sliding window under every workload.

Fan-out/fan-in experiments used a 70-second pause between pairs to avoid interference from the stock rule's `ignore=60`. This is a **test limitation**: the pause makes the test sequential and does not resolve possible missed alerts under simultaneous attacks. Do not claim concurrency support based only on these tests.

In the ruleset, `ssh_pair_confirmed` is also present in the outer group and is therefore assigned to other contained rules, not exclusively the first three pair-confirmation rules. This behavior is preserved and should be regression-tested before further extension of the ruleset. It is not silently altered for publication.

## Security and publication

The published configuration does not enable new quarantine actions for SSH alerts. The supplied RouterOS Python script selects `data.src_ip`: in the reverse-shell scenario that represents the suspicious client, while in the SSH scenario it represents the source of the attempts. Do not automatically connect the new SSH rules to the same Active Response without defining the intended policy.

The original descriptions of `100920`/`100921` are preserved. When the outcome is unknown, also inspect `detection_reason` and the counters: the legacy description `brute force detected` does not turn a network candidate into a confirmed authentication failure.
