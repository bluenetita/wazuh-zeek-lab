# Changelog

All notable changes to this project should be documented in this file.

The format is inspired by [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Terraform-based Proxmox VM provisioning using the `bpg/proxmox` provider.
- Reusable `modules/proxmox-vm` Terraform module.
- Cloud-Init management IP, gateway, user and SSH-key configuration.
- Dynamic support for multiple VM definitions through the `vms` map.
- Ansible inventory grouped by VM responsibility.
- Zeek sensor role for Ubuntu 24.04.
- Deployment of the precompiled Zeek 8.0.6 artifact.
- Zeek custom scripts and configuration deployment.
- Netplan configuration for the Zeek capture VLAN interface.
- Persistent promiscuous-mode systemd units.
- Wazuh Agent reusable role.
- Group-selectable Wazuh Agent configuration template.
- Centralized Wazuh Manager address for Wazuh Agent groups.
- Ansible Vault support for sudo credentials.
- Final administrative-user hardening with password-protected sudo.
- Deployment and repository documentation.

### Security

- Terraform variables/state, SSH private keys and Wazuh credential files are excluded by `.gitignore`.
- Large Zeek binary artifacts are excluded from normal Git history while the SHA256 checksum remains versioned.
