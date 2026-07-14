# Proxmox OVS Scripts

This directory contains scripts used to create or validate the Open vSwitch mirror for Zeek.

A script should:

- use stable bridge and mirror names;
- select only intended VLANs;
- send copies to the dedicated mirror destination;
- avoid duplicate mirrors when run repeatedly;
- provide verification commands;
- fail clearly when interfaces or bridges are missing.

Validate with `ovs-vsctl list mirror` and packet capture on ZeekVM.
