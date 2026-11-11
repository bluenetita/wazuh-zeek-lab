# Deployment, verification and rollback runbook

## Scope and preflight

Target validated in lab: Wazuh 4.14.4, single-node Wazuh Indexer, Ubuntu,
manager archiving with `<logall>no</logall>` and `<logall_json>yes</logall_json>`.
This runbook documents a feature, not blanket authorisation for production.

Before any destructive operation, agree on a retention period, identify legal
or contractual requirements, export/snapshot required evidence, and take a
recoverable backup. Seven days is a **lab choice**, not a recommended SOC
retention. Confirm roles and user access for `Indexer management -> Dev Tools`.

Read-only baseline (on the VM):

```bash
df -h /
sudo du -sh /var/ossec/logs/archives /var/ossec/logs/alerts
sudo du -sh /var/lib/wazuh-indexer /var/log/wazuh-indexer
sudo systemctl is-active wazuh-manager filebeat wazuh-indexer
```

Read-only baseline (in Dashboard Dev Tools):

```http
GET _cluster/health
GET _cat/allocation?v
GET _cat/indices/wazuh-alerts-4.x-*?v&h=index,pri,rep,store.size,creation.date.string
GET _plugins/_ism/policies
GET _template/wazuh
GET _index_template?filter_path=index_templates.name,index_templates.index_template.index_patterns
```

All commands below are examples scoped to `wazuh-alerts-4.x-*`. Check the
actual index naming pattern in the target deployment before adapting.

## A. Local archive retention (Manager)

Files are already rotated/compressed by Wazuh. The script only purges fully
rotated files named `ossec-archive-DD.json.gz`, `...json.sum`, `...log.gz`,
`...log.sum` from `YYYY/Mon/`. It does not touch active files or directories.
The period is based on the filename's UTC calendar date; `mtime` is not used.
It rejects invalid day numbers. Dry-run is the default.

1. Test: `bash blue-team/wazuh/maintenance/tests/test-archives-retention.sh`.
2. Install without enabling deletion:
   `sudo bash blue-team/wazuh/maintenance/scripts/install-archives-retention.sh --days 7`.
3. Review: `sudo /usr/local/sbin/wazuh-archives-retention.sh --dry-run`.
4. If approved, opt in to automatic irreversible deletion:
   `sudo bash blue-team/wazuh/maintenance/scripts/install-archives-retention.sh --days 7 --enable-cron`.
5. Verify: `sudo systemctl is-active cron`,
   `sudo cat /etc/cron.d/wazuh-archives-retention`,
   `sudo logrotate -d /etc/logrotate.d/wazuh-archives-retention`.
6. After the first scheduled run: `sudo tail -n 30 /var/log/wazuh-archives-retention.log`
   and `df -h /`. The timer is 04:15 in the host's timezone; the lab host was UTC.

**Rollback:** remove `/etc/cron.d/wazuh-archives-retention` to disable future
deletions. The installer saves overwritten files under
`/var/backups/wazuh-archives-retention/`; restore the needed configuration
from a dated backup. Deleted archives are recoverable only from external backup.
The cron job log is rotated weekly with eight compressed rotations.

## B. ISM policy (Indexer)

The file `indexer/wazuh-alerts-7d-ism-policy.json` contains the request body
for the following operation. From Dashboard Dev Tools, run:

```http
PUT _plugins/_ism/policies/wazuh-alerts-7d
{ "policy": { "...": "paste complete body from JSON file" } }
```

The inline body shown above is **only a placeholder**: paste the complete file,
not the placeholder. Do not overwrite a pre-existing policy without reviewing
it. Inspect with:

```http
GET _plugins/_ism/policies/wazuh-alerts-7d
GET _plugins/_ism/explain/wazuh-alerts-4.x-*
```

The `ism_template` auto-attaches to matching future indices. Associating the
policy with **existing indices** is a separate and potentially destructive
operation. Only after backup and retention approval:

```http
POST _plugins/_ism/add/wazuh-alerts-4.x-*
{ "policy_id": "wazuh-alerts-7d" }
```

Existing indices older than `min_index_age` can be deleted by the next ISM
cycles. Age is calculated from **actual index creation time**, not from the
index name's date. Verify shrinking index counts via:

```http
GET _cat/indices/wazuh-alerts-4.x-*?v&h=index,store.size,creation.date.string
GET _cat/allocation?v
GET _cluster/health
```

**Rollback (before the policy deletes data):** first detach policies from
managed matching indices using the version-supported ISM remove action, for
example:

```http
POST _plugins/_ism/remove/wazuh-alerts-4.x-*
```

Then, after confirming no managed indices still depend on it, remove the policy:

```http
DELETE _plugins/_ism/policies/wazuh-alerts-7d
```

Confirm API support on the installed Wazuh version before using rollback
commands. Deleting the policy alone must not be treated as a safe rollback;
indices already deleted by ISM **cannot** be recovered without a snapshot.

## C. Single-primary shard override (Indexer)

Only for the validated **single-node** scenario. Check for other templates
that cover the index prefix. The lab's legacy `wazuh` template used order 0,
three primary shards and no replicas. The custom legacy override uses order 10
and applies only to `wazuh-alerts-4.x-*`.

In Dev Tools, create using the *complete body* in
`indexer/wazuh-alerts-single-shard-template.json`:

```http
PUT _template/wazuh-alerts-single-shard?create=true
{ "order": 10, "index_patterns": ["wazuh-alerts-4.x-*"],
  "settings": {"index":{"number_of_shards":1,"number_of_replicas":0}} }
```

Verify:

```http
GET _template/wazuh-alerts-single-shard
GET _cat/indices/wazuh-alerts-4.x-*?v&h=index,pri,rep,store.size
```

The **next newly created** matching index should have `pri=1`, `rep=0`.
Existing indices keep their previous shard count. This does not validate the
mapping automatically; confirm alert parsing and discovery as well.

**Rollback for future indices:**

```http
DELETE _template/wazuh-alerts-single-shard
```

Do not apply `number_of_replicas=0` blindly to multi-node installations;
production redundancy depends on topology and recovery objectives.

## D. Java GC log rotation (Indexer)

The lab file `/etc/wazuh-indexer/jvm.options` previously had `filecount=32,
filesize=64m` for its GC logs. The feature reduced this to `filecount=8,
filesize=32m`. The file `indexer/gc-jvm-example.txt` contains the one-line
reference. Do **not** replace the entire JVM configuration with that file.

1. Schedule maintenance and take a backup:
   `sudo cp -a /etc/wazuh-indexer/jvm.options /etc/wazuh-indexer/jvm.options.bak.TIMESTAMP`.
   Replace `TIMESTAMP` with a unique label before executing.
2. Change only the existing `-Xlog:gc` option; verify:
   `sudo grep -n 'Xlog:gc' /etc/wazuh-indexer/jvm.options`.
3. Stop Indexer: `sudo systemctl stop wazuh-indexer`; verify `inactive`.
4. Only if loss of historic JVM diagnostics is approved, remove **rotated**
   `gc.log.NN` files while stopped, without touching `gc.log` or the cluster log.
5. Start Indexer: `sudo systemctl start wazuh-indexer`; verify `active`.
6. Verify `sudo du -sh /var/log/wazuh-indexer`, `df -h /`, and Indexer health.

**Rollback:** restore the backed-up `jvm.options` and restart the Indexer in a
maintenance window. Deleted historical GC logs cannot be restored without backup.

## E. Storage incident checks (no blind repair)

The lab previously had `cluster.blocks.create_index=true` set persistently.
This may prevent daily indices from being created even after disk usage drops.
Check free disk, watermarks, relevant index blocks, and operator intent before
clearing a cluster block. In the lab this was investigated and reset by setting
its persistent value to `null`; it is **not** an automatic deployment action.
Do not weaken watermarks to conceal space exhaustion.

Check healthy indexing end-to-end after any Indexer restart:

```http
GET _cluster/health
GET _cat/allocation?v
GET wazuh-alerts-4.x-*/_search
{ "size": 1, "sort": [{"timestamp":{"order":"desc"}}],
  "_source": ["timestamp","agent.name","rule.id"] }
```

Generate a controlled recent alert to confirm new ingestion if necessary.
For a single-node cluster, `yellow` may result from replica shards of internal
indices; ensure **all primary shards** are assigned and diagnose any others.

## F. Evidence and change control

Keep timestamps, sanitized before/after disk metrics, policy IDs, index counts,
shard counts, and command results in an internal change record. Do not commit
raw logs, credentials, snapshots, private IPs, or full endpoint telemetry.
Review changes in a branch and submit a PR before merging.
