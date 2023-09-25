#!/bin/bash

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_SSHD_CONFIG="$SSHD_CONFIG.backup"

# Backup original configuration
cp "$SSHD_CONFIG" "$BACKUP_SSHD_CONFIG"
echo "Backed up current sshd_config to $BACKUP_SSHD_CONFIG"

# Configuration changes
declare -A CONFIG_CHANGES=(
    ["#PasswordAuthentication yes"]="PasswordAuthentication yes"
    ["#PermitRootLogin prohibit-password"]="PermitRootLogin no"
    ["#X11Forwarding yes"]="X11Forwarding no"
    ["#ClientAliveCountMax 3"]="ClientAliveCountMax 2"
    ["#LogLevel INFO"]="LogLevel VERBOSE"
    ["#MaxAuthTries 6"]="MaxAuthTries 2"
    ["#MaxSessions 10"]="MaxSessions 2"
    ["#TCPKeepAlive yes"]="TCPKeepAlive no"
    ["#AllowAgentForwarding yes"]="AllowAgentForwarding no"
    ["#AllowTcpForwarding yes"]="AllowTcpForwarding no"
    ["#Port 22"]="Port 2222"
)

# Apply the changes
for original in "${!CONFIG_CHANGES[@]}"; do
    sed -i "s/$original/${CONFIG_CHANGES[$original]}/" "$SSHD_CONFIG"
done

# Restart and revert on failure
if ! service ssh restart; then
    echo "Error restarting SSH. Reverting changes..."
    mv "$BACKUP_SSHD_CONFIG" "$SSHD_CONFIG"
    service ssh restart
    echo "Reverted to the original configuration and restarted SSH."
else
    echo "SSH configuration updated and service restarted successfully!"
fi
