# Troubleshooting

This file collects common problems already encountered while developing and testing the Terraform/Ansible workflow.

## Ansible ignores `ansible.cfg` under `/mnt/c`

### Symptom

```text
[WARNING]: Ansible is being run in a world writable directory (...), ignoring it as an ansible.cfg source.
```

### Cause

The repository is stored on the Windows filesystem mounted by WSL. Ansible considers the directory world-writable and refuses to load `ansible.cfg` from it.

### Workaround

From the repository root:

```bash
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"
```

Always specify the inventory explicitly:

```bash
-i ansible/inventory/lab.yml
```

Alternative: clone/move the repository to the WSL Linux filesystem.

---

## Ansible role not found

### Symptom

A syntax check or playbook execution reports that role `zeek`, `wazuh_agent` or `hardening` cannot be found.

### Fix

```bash
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"
```

Then retry.

---

## SSH host identification changed after VM recreation

### Symptom

```text
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
```

### Cause

A VM was destroyed and recreated with the same management IP but a new SSH host key.

### Fix in WSL

```bash
ssh-keygen -f ~/.ssh/known_hosts -R 10.3.10.X
```

Reconnect and verify the new fingerprint before accepting it.

---

## First SSH connection asks for host authenticity confirmation

This is normal for a previously unknown VM:

```text
The authenticity of host ... can't be established.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Verify the target IP/fingerprint and answer `yes` only when it is the intended host.

---

## `zeek_artifact` is undefined

### Symptom

```text
'zeek_artifact' is undefined
```

### Common cause

The Zeek variables are no longer being loaded after changing the `group_vars` layout to add a Vault.

### Recommended layout

Do not keep both a legacy standalone group file and an inconsistent directory layout. Use:

```text
ansible/inventory/group_vars/zeek_sensors/
+-- main.yml
+-- vault.yml
```

`main.yml` contains:

```yaml
zeek_artifact: "{{ inventory_dir }}/../artifacts/zeek-8.0.6/zeek-8.0.6-ubuntu24.04-amd64.tar.gz"
```

Check variable resolution with:

```bash
ansible-inventory -i ansible/inventory/lab.yml --host zeek01 --ask-vault-pass
```

Do not share the full output because decrypted secret variables may be displayed.

---

## Zeek artifact missing

### Symptom

Ansible cannot find the local tarball used by `unarchive`.

### Expected path

```text
ansible/artifacts/zeek-8.0.6/zeek-8.0.6-ubuntu24.04-amd64.tar.gz
```

The artifact is not stored in Git. It must be copied separately after cloning.

Verify its checksum:

```bash
cd ansible/artifacts/zeek-8.0.6
sha256sum -c zeek-8.0.6-ubuntu24.04-amd64.sha256
```

---

## Wazuh Agent service is running but the host does not appear in the dashboard

### Possible cause

The VM was rebuilt with the same Wazuh agent name/IP while the Wazuh Manager still has the old agent registration and key.

A Wazuh agent identity is not defined only by IP/name; enrollment keys also matter.

### Diagnostic approach

- verify `wazuh-agent` is running;
- inspect the agent log;
- verify connectivity to the manager/enrollment ports;
- verify whether an old registration with the same identity still exists on the manager;
- test with a new temporary agent name/IP to isolate duplicate-registration issues.

Do not blindly copy an old `client.keys` file into the repository or into unrelated hosts.

---

## `sudo su` does not request a password

### Cause

Cloud-Init may create a sudoers entry like:

```text
user ALL=(ALL) NOPASSWD:ALL
```

Check with:

```bash
sudo grep -R "NOPASSWD" /etc/sudoers /etc/sudoers.d/
```

The final hardening role should replace the rule for the configured administrative account so sudo requires the password.

Test after provisioning:

```bash
sudo -k
sudo whoami
```

It should prompt for the user's password and then return:

```text
root
```

---

## Ansible works on first deployment but fails after hardening

### Cause

After `NOPASSWD` is removed, Ansible needs a valid become password.

### Fix

Ensure the encrypted group Vault contains:

```yaml
ansible_become_password: "..."
```

Run with:

```bash
ansible-playbook -i ansible/inventory/lab.yml ansible/playbooks/site.yml --ask-vault-pass
```

---

## Wazuh `netstat` command is missing

If the deployed `ossec.conf` contains commands that execute `netstat`, ensure `net-tools` is installed by the Wazuh Agent role.

Check:

```bash
command -v netstat
```

---

## Zeek service does not start

Check configuration first:

```bash
sudo /opt/zeek/bin/zeekctl check
```

Then inspect:

```bash
sudo systemctl status zeek.service
sudo journalctl -u zeek.service -n 100 --no-pager
```

Verify the capture interface exists:

```bash
ip link show ens19
ip link show ens19.999
```

Check the promiscuous-mode services:

```bash
systemctl status bridge-promisc.service
systemctl status vlan-promisc.service
```

---

## Zeek is installed but not found in the shell

Check directly:

```bash
/opt/zeek/bin/zeek --version
```

The role installs `/etc/profile.d/zeek.sh`. Start a new shell or run:

```bash
source /etc/profile.d/zeek.sh
```

---

## Terraform reports that remote changes exist or the VM already exists

Do not force changes before understanding whether:

- the VM is already managed by this Terraform state;
- another Terraform state manages the same VMID;
- the VM was created manually;
- the local state was lost/not shared.

Terraform state is the ownership record for managed resources. A private Git repository does not replace a shared Terraform backend.
