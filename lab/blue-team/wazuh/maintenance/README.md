# Wazuh storage maintenance and retention

Reusable, sanitized maintenance assets for **Wazuh Manager + Wazuh Indexer 4.14.4**.
The procedure was exercised in the lab on 2026-11-11 (single-node indexer, Ubuntu).
It is **not a production-approved default**: retention must be adapted to the
organisation's audit, incident-response, and contractual requirements.

## Components

| Asset | Function | Applied where |
| --- | --- | --- |
| `manager/wazuh-archives-retention.sh` | Dry-run / delete old compressed archive files and checksums by UTC archive date | Wazuh Manager |
| `manager/*.conf.example` | Lab retention example: 7 calendar days | Wazuh Manager |
| `manager/*.cron` | Daily cleanup at 04:15 VM local time (UTC in lab) | `/etc/cron.d/` |
| `manager/*.logrotate` | Rotate the cleanup job's own audit log | `/etc/logrotate.d/` |
| `indexer/wazuh-alerts-7d-ism-policy.json` | ISM 7-day retention for `wazuh-alerts-4.x-*` | Wazuh Indexer API |
| `indexer/wazuh-alerts-single-shard-template.json` | Legacy template override: one primary, no replicas | Wazuh Indexer API, single-node only |
| `indexer/gc-jvm-example.txt` | GC rotation example: 8 x 32 MiB | `/etc/wazuh-indexer/jvm.options` |
| `scripts/install-archives-retention.sh` | Installs local files; enables cron **only with explicit flag** | Wazuh Manager |
| `tests/test-archives-retention.sh` | Isolated regression test, no Wazuh installation required | Development host |

## Quick start: Wazuh Manager

From the repository root on a test/lab Wazuh Manager host:

```bash
bash blue-team/wazuh/maintenance/tests/test-archives-retention.sh
sudo bash blue-team/wazuh/maintenance/scripts/install-archives-retention.sh --days 7
sudo /usr/local/sbin/wazuh-archives-retention.sh --dry-run
```

Review the exact file list and the summary. The script defaults to dry-run and
never touches the active `archives.json` / `archives.log` files, the indexer,
manager queues, or Wazuh rules. A 7-day retention means keeping the seven most
recent UTC calendar days **including today**.

**Irreversible action:** after approval, install the cron schedule:

```bash
sudo bash blue-team/wazuh/maintenance/scripts/install-archives-retention.sh --days 7 --enable-cron
sudo cat /etc/cron.d/wazuh-archives-retention
sudo systemctl is-active cron
```

The cron entry then invokes `--delete` every day at 04:15 in the VM's timezone.
`flock` prevents concurrent executions. Inspect `/var/log/wazuh-archives-retention.log`
and `df -h /` after the first scheduled run. The installer creates backups of
replaced config files in `/var/backups/wazuh-archives-retention/`.

To change retention later, rerun the installer with a revised `--days N` value,
review a dry-run, and confirm the schedule is present. To stop automatic
purging immediately, remove or disable `/etc/cron.d/wazuh-archives-retention`.
This **cannot restore data already deleted**. See [DEPLOYMENT.md](DEPLOYMENT.md).

## Quick start: Wazuh Indexer

From Wazuh Dashboard **Indexer management -> Dev Tools**:

1. Check existing policies: `GET _plugins/_ism/policies`.
2. Review and adapt `indexer/wazuh-alerts-7d-ism-policy.json`.
3. Create policy with `PUT _plugins/_ism/policies/wazuh-alerts-7d` and the JSON file as request body.
4. Check the policy: `GET _plugins/_ism/policies/wazuh-alerts-7d`.
5. **Separately** decide whether historical indices should be managed; applying
   ISM to old indices is destructive after the retention condition is met.
6. For a single-node lab, check composable templates then create the
   `wazuh-alerts-single-shard` legacy template with its JSON file as body.
7. Verify policy and shard behavior on newly created indices.

**Do not** use these example settings unchanged on a multi-node production
cluster: `number_of_replicas: 0` means no shard redundancy. Seven days may be
insufficient for incident investigation or legal retention. Index creation age,
not the calendar date encoded in the index name, drives this ISM policy.

## Verified lab result (2026-11-11)

- Filesystem before maintenance: ~83% used, ~8.3 GiB free.
- Filesystem after archive cleanup, ISM cleanup and GC rotation: ~68% used, ~16 GiB free.
- Rotated archives: ~4.9 GiB to ~1.6 GiB in the initial cleanup.
- Alert index store: ~1.9 GiB to ~150.9 MiB after ISM deletion.
- Indexer GC logs: ~1.7 GiB to ~30 MiB after removing old rotated files while service was stopped.
- `wazuh-manager`, `filebeat`, `wazuh-indexer` all reported `active`.
- Wazuh alert search returned an event; the single-node cluster stayed `yellow`
  due to unassigned replicas, with all primaries allocated.
- Archive cron script passed a manual `--delete` test; scheduled execution remained
  pending at the time of the record.
- One-primary-shard override was installed and verified as a template;
  **creation of a future index with one shard was not yet observed**.

The storage figures are rounded operational observations, not performance
benchmarks. No raw alert records, credentials, or VM databases are included.

## Safety scope

The assets cover only `wazuh-alerts-4.x-*` indices and compressed/rotated files
under `/var/ossec/logs/archives/YYYY/Mon/`. They **do not** manage all Wazuh
indices, `alerts/` local files, `/var/ossec/queue/vd` (vulnerability database),
`/var/ossec/queue/indexer`, or `/var/lib/wazuh-indexer` by direct filesystem deletion.
Index deletion must happen through the OpenSearch API/ISM, never via `rm`.

See [DEPLOYMENT.md](DEPLOYMENT.md) for API operations, validation, backup, and rollback.

## References

- Wazuh index lifecycle: https://documentation.wazuh.com/current/user-manual/wazuh-indexer-cluster/index-lifecycle-management.html
- Wazuh event logging: https://documentation.wazuh.com/current/user-manual/manager/event-logging.html
- Wazuh index families and templates: https://documentation.wazuh.com/current/user-manual/wazuh-indexer/wazuh-indexer-indices.html
