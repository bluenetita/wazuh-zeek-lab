# Contributing

This repository contains Infrastructure-as-Code that can create, modify or destroy lab virtual machines. Changes should therefore be reviewed before they are applied.

## Recommended workflow

Create a branch:

```bash
git checkout -b feature/short-description
```

Make the required changes, then run the relevant checks.

### Terraform changes

```bash
terraform fmt -recursive
terraform validate
terraform plan
```

Review the plan before applying it.

### Ansible changes

```bash
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"

ansible-playbook \
  -i ansible/inventory/lab.yml \
  ansible/playbooks/site.yml \
  --syntax-check \
  --ask-vault-pass
```

When a test VM is available, also verify:

```bash
ansible all -i ansible/inventory/lab.yml -m ping --ask-vault-pass
```

and run the relevant playbook.

## Commit style

Use concise commit messages describing the result of the change, for example:

```text
Add reusable Wazuh Agent role
Add Zeek capture interface configuration
Add final sudo hardening
Document Terraform deployment workflow
```

## Pull requests

For meaningful infrastructure changes, prefer a pull request even in a private two-person repository.

A pull request should explain:

- what changes;
- why it changes;
- affected VM groups;
- whether Terraform creates/destroys/replaces resources;
- whether new secrets or local files are required;
- validation performed.

## Secrets

Before committing, read [SECURITY.md](SECURITY.md).

Never include real API tokens, passwords, SSH private keys, Terraform state or unencrypted Vault content in commits, issues or pull-request descriptions.

## Documentation

Update documentation in the same change whenever a configuration workflow or required variable changes.

At minimum, review:

- `DEPLOYMENT_GUIDE.md` for user-facing deployment changes;
- `docs/TERRAFORM.md` for Terraform interface changes;
- `docs/ANSIBLE.md` for Ansible structure changes;
- `docs/ADDING_NEW_VM.md` when extensibility patterns change;
- `CHANGELOG.md` for notable changes.
