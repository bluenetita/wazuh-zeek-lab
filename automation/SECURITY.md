# Security Policy and Secret Handling

## Private repository does not mean secrets may be committed

This project may be hosted in a private Git repository, but plaintext secrets must still be excluded from version control.

Reasons include:

- every repository collaborator can clone the full history;
- repository visibility can be changed accidentally;
- local clones and backups may outlive access revocation;
- deleted files remain in Git history unless history is rewritten;
- CI/CD logs or integrations may expose committed credentials.

## Files and values that must not be committed

### Terraform

Do not commit:

```text
terraform.tfvars
terraform.tfstate
terraform.tfstate.backup
*.tfstate.*
*.tfplan
.terraform/
```

Terraform state may contain sensitive values even if an input variable is declared `sensitive = true`.

### Proxmox

Do not commit:

- real API tokens;
- passwords;
- private certificates or private keys.

Use placeholders in `terraform.tfvars.example`.

### SSH

Never commit:

- private keys (`id_rsa`, `id_ecdsa`, `id_ed25519`, `.ppk`, `.pem`);
- local `known_hosts` files when they are not intentionally part of a managed SSH trust model.

Public SSH keys are not secret, but committing a personal public key is optional and usually unnecessary. Prefer a placeholder in the example configuration.

### Wazuh

Do not commit:

```text
authd.pass
client.keys
```

Do not place real enrollment passwords directly in normal YAML or templates.

### Ansible Vault

An encrypted Vault file may be committed.

Before committing, confirm:

```bash
head -n 1 ansible/inventory/group_vars/zeek_sensors/vault.yml
```

starts with:

```text
$ANSIBLE_VAULT;1.1;AES256
```

Never commit:

- the Vault password;
- a `.vault_pass` file;
- plaintext copies of the Vault content.

Share the Vault password with the authorized colleague through a separate secure channel.

## Zeek artifact

The precompiled Zeek tarball is intentionally excluded from normal Git history because it is large.

The repository should contain only the checksum and instructions for obtaining the artifact.

## Before every first push

Run:

```bash
git status
```

Verify the ignore rules:

```bash
git check-ignore terraform.tfvars
git check-ignore terraform.tfstate
git check-ignore terraform.tfstate.backup
git check-ignore ansible/artifacts/zeek-8.0.6/zeek-8.0.6-ubuntu24.04-amd64.tar.gz
```

Inspect staged files:

```bash
git add .
git status
```

If an unsafe file appears under `Changes to be committed`, unstage it before committing.

## If a sensitive file was already tracked

Adding it to `.gitignore` is not enough because tracked files remain tracked.

Remove it from the Git index while keeping the local copy:

```bash
git rm --cached terraform.tfvars
git rm --cached terraform.tfstate
git rm --cached terraform.tfstate.backup
```

For a directory:

```bash
git rm -r --cached .terraform
```

Then commit the removal.

## If a secret was committed

Assume the secret may be exposed even if the repository is private.

1. Rotate/revoke the exposed credential first.
2. Remove the sensitive file/value from the current tree.
3. Decide whether Git history must be rewritten.
4. Inform collaborators that old clones may still contain the old secret.

Secret rotation is more important than merely deleting a historical commit.

## Minimum repository access

Grant access only to collaborators who need it. Prefer named individual accounts rather than shared credentials.

For collaboration, use branches and pull requests for non-trivial changes so infrastructure modifications can be reviewed before merging.
