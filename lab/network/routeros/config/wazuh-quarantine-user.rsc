# Dedicated RouterOS account used by the Wazuh Active Response
# quarantine workflow.
#
# The account uses the built-in RouterOS "write" group.
# Passwords and SSH key material are deliberately excluded.

/user
add comment="Wazuh quarantine automation" group=write name=wazuh-quarantine