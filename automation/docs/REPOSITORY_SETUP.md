# Private Repository Setup

This guide describes how to publish the project to a private GitHub repository without accidentally committing local secrets or generated files.

## 1. Copy the documentation pack into the project

Copy the generated files while preserving their paths.

For example, the repository root should contain:

```text
.gitignore
README.md
DEPLOYMENT_GUIDE.md
CHANGELOG.md
CONTRIBUTING.md
SECURITY.md
docs/
```

The pack also contains replacement documentation under `ansible/`, `ansible/artifacts/...` and `modules/proxmox-vm/`.

## 2. Check `.gitignore` before staging anything

This step must happen before the first `git add .`.

Confirm that sensitive/generated files are ignored:

```bash
git check-ignore terraform.tfvars
git check-ignore terraform.tfstate
git check-ignore terraform.tfstate.backup
git check-ignore ansible/artifacts/zeek-8.0.6/zeek-8.0.6-ubuntu24.04-amd64.tar.gz
```

Each command should print the matching path.

Check that the provider lock file is not ignored:

```bash
git check-ignore .terraform.lock.hcl
```

This should produce no output.

## 3. Verify the Vault

If the encrypted Vault will be committed:

```bash
head -n 1 ansible/inventory/group_vars/zeek_sensors/vault.yml
```

It must start with:

```text
$ANSIBLE_VAULT;1.1;AES256
```

If it shows YAML variables/passwords in plaintext, do not stage it.

## 4. Initialize Git if needed

If the project is not already a Git repository:

```bash
git init
```

Set the primary branch:

```bash
git branch -M main
```

## 5. Stage files

```bash
git add .
```

Immediately inspect:

```bash
git status
```

The staged list must not contain:

```text
.terraform/
terraform.tfvars
terraform.tfstate
terraform.tfstate.backup
*.tfplan
Zeek *.tar.gz artifact
SSH private keys
authd.pass
client.keys
Vault password files
```

It is expected to contain:

```text
.terraform.lock.hcl
terraform.tfvars.example
Terraform .tf source files
Ansible YAML/templates/scripts
Encrypted vault.yml (optional)
Zeek *.sha256
Documentation
.gitignore
```

## 6. If an ignored file is already tracked

`.gitignore` only affects untracked files.

If, for example, `terraform.tfstate` was already added previously:

```bash
git rm --cached terraform.tfstate
```

For `.terraform/`:

```bash
git rm -r --cached .terraform
```

For the Zeek artifact:

```bash
git rm --cached ansible/artifacts/zeek-8.0.6/zeek-8.0.6-ubuntu24.04-amd64.tar.gz
```

Then check:

```bash
git status
```

## 7. Perform an optional secret review

Before the first commit, search staged content for obvious secret indicators:

```bash
git diff --cached --check
```

Also manually inspect `terraform.tfvars.example`, normal YAML files and templates to ensure they contain placeholders rather than real tokens/passwords.

## 8. Commit

```bash
git commit -m "Initial Terraform and Ansible lab automation"
```

## 9. Create a private GitHub repository

In GitHub:

1. Create a new repository.
2. Select **Private** visibility.
3. Do not initialize it with another README if the local project already contains one.
4. Copy the repository URL.

## 10. Add the remote

HTTPS example:

```bash
git remote add origin https://github.com/OWNER/REPOSITORY.git
```

Or use the SSH URL if GitHub SSH authentication is already configured.

Verify:

```bash
git remote -v
```

## 11. Push

```bash
git push -u origin main
```

## 12. Add the colleague

In the GitHub repository settings, grant access only to the intended collaborator.

Do not put the Ansible Vault password in the repository README, issues, commits or files. Share it separately through an approved secure channel.

The colleague will also need the Zeek binary artifact because it is intentionally not committed.

## 13. Colleague clone workflow

After cloning:

```bash
git clone <repository>
cd wazuh-zeek-terraform-lab
cp terraform.tfvars.example terraform.tfvars
```

The colleague then supplies their/local environment values and separately obtains:

- Proxmox API access/token;
- SSH private key or their own authorized key workflow;
- Ansible Vault password when authorized;
- Zeek precompiled artifact.

Then they can follow `DEPLOYMENT_GUIDE.md`.
