#!/bin/bash

# Backup fstab
cp /etc/fstab /etc/fstab.backup

# Check if hidepid is already set
if grep -q "hidepid=" /etc/fstab; then
    echo "The hidepid option is already set in /etc/fstab. Exiting..."
    exit 1
fi

# Function to revert changes
revert_changes() {
    echo "An error occurred. Reverting changes..."
    cp /etc/fstab.backup /etc/fstab
    mount -o remount /proc
    exit 1
}

# Set hidepid=2 in /etc/fstab
sed -i '/proc/s/defaults/&,hidepid=2/' /etc/fstab

# Remount /proc to apply the changes
if ! mount -o remount,hidepid=2 /proc; then
    revert_changes
fi

echo "hidepid has been set to 2 for /proc."

# Harden /dev/shm
if ! grep -qE '\s/dev/shm\s' /etc/fstab; then
    echo "Warning: /dev/shm not found in /etc/fstab. Adding entry..."
    echo "tmpfs   /dev/shm    tmpfs   defaults,nosuid,noexec,nodev   0 0" >> /etc/fstab || { revert_changes "Failed to add /dev/shm"; exit 1; }
else
    sed -i '/\s\/dev\/shm\s/s/defaults/&,nosuid,noexec,nodev/' /etc/fstab || { revert_changes "Failed to update /dev/shm"; exit 1; }
fi

echo "Changes applied successfully."


# Backup relevant files before making changes
backup_dir="/tmp/coredump_backup_$(date +%Y%m%d%H%M%S)"
mkdir "$backup_dir"
cp /etc/security/limits.conf "$backup_dir/"
cp /etc/sysctl.conf "$backup_dir/"

# Function to rollback changes if error occurs
rollback() {
    echo "Error detected. Rolling back to the original configuration..."
    cp "$backup_dir/limits.conf" /etc/security/limits.conf
    cp "$backup_dir/sysctl.conf" /etc/sysctl.conf
    sysctl -p
    exit 1
}

# Disable core dumps
echo "* hard core 0" >> /etc/security/limits.conf || rollback

echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf || rollback

sysctl -w fs.suid_dumpable=0 || rollback

# If systemd-coredump is installed
if systemctl list-unit-files | grep -q 'systemd-coredump'; then
    cp /etc/systemd/coredump.conf "$backup_dir/"
    sed -i 's/^Storage=.*/Storage=none/' /etc/systemd/coredump.conf
    echo "ProcessSizeMax=0" >> /etc/systemd/coredump.conf
    systemctl daemon-reload || rollback
fi

echo "Core dump has been disabled."
