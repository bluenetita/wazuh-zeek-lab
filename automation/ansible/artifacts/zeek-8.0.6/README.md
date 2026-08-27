# Zeek 8.0.6 Precompiled Artifact

The Ansible Zeek role expects a precompiled Ubuntu 24.04 amd64 Zeek archive named:

```text
zeek-8.0.6-ubuntu24.04-amd64.tar.gz
```

Place it in this directory before running the Zeek playbook.

## Why the archive is not in Git

The archive is approximately 400+ MB and is intentionally excluded by `.gitignore`.

Do not use normal Git history to distribute this binary. Transfer it separately through an approved shared storage location or artifact-release mechanism.

## Expected checksum

The versioned checksum file is:

```text
zeek-8.0.6-ubuntu24.04-amd64.sha256
```

Expected SHA256:

```text
23d1728be068f2d149352909c4707c4028416d6dfea969e8d30f09f2d638fc51
```

Verify after copying the artifact:

```bash
cd ansible/artifacts/zeek-8.0.6
sha256sum -c zeek-8.0.6-ubuntu24.04-amd64.sha256
```

Expected result:

```text
zeek-8.0.6-ubuntu24.04-amd64.tar.gz: OK
```

Do not run the playbook with an artifact whose checksum does not match the expected value.
