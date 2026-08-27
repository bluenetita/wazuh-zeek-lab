#!/bin/bash
# Script to persist OVS mirror across reboots and network restarts

LOG_FILE="/var/log/ovs-mirror.log"
BRIDGE="vmbr2"          # Replace with your OVS bridge name
OUTPUT_VLAN="999"    # Replace with your VM tap interface
MIRROR_NAME="zeek_mirror"  # Choose a name for your mirror

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> ${LOG_FILE}
}

# Check if the mirror already exists
if ! ovs-vsctl list Mirror | grep -q "name=${MIRROR_NAME}"; then
    log_message "Mirror ${MIRROR_NAME} not found. Creating..."


    ovs-vsctl -- --id=@m create mirror name=${MIRROR_NAME} select-all=true select-vlan=10,20,30 output-vlan=${OUTPUT_VLAN} -- set bridge ${BRIDGE} mirrors=@m


    if [ $? -eq 0 ]; then
        log_message "Mirror created successfully."
    else
        log_message "ERROR: Failed to create mirror."
    fi
else
    log_message "Mirror ${MIRROR_NAME} already exists. Recreating..."
    ovs-vsctl clear Bridge vmbr2 mirrors
    ovs-vsctl -- --id=@m create mirror name=${MIRROR_NAME} select-all=true select-vlan=10,20,30 output-vlan=${OUTPUT_VLAN} -- set bridge ${BRIDGE} mirrors=@m
    log_message "Mirror created successfully."
fi