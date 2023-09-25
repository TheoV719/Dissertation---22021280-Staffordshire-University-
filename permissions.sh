#!/bin/bash

echo "Applying strict permissions to sensitive files..."

chown root:root /boot/grub/grub.cfg
chmod og-rwx /boot/grub/grub.cfg

# Secure /etc/passwd - User account information
chmod 0644 /etc/passwd
chown root:root /etc/passwd

# Secure /etc/shadow - User password hashes
chmod 0400 /etc/shadow
chown root:root /etc/shadow

# Secure /etc/group - Group information
chmod 0644 /etc/group
chown root:root /etc/group

# Secure /etc/gshadow - Group password hashes
chmod 0400 /etc/gshadow
chown root:root /etc/gshadow

# Secure /etc/sudoers - Sudo privileges
chmod 0440 /etc/sudoers
chown root:root /etc/sudoers

# Secure /etc/ssh/sshd_config - SSH server configuration
chmod 0600 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config

# Secure the main crontab file to ensure only root can read/write it
chmod 0600 /etc/crontab
chown root:root /etc/crontab

# Secure sudoers files

chown root:root /etc/sudoers.d
chmod 0700 /etc/sudoers.d

# Secure the cron directories to ensure only root has access, preventing potential malicious cron job injections

chmod -R go-rwx /etc/cron.d
chown -R root:root /etc/cron.d

chmod -R go-rwx /etc/cron.daily
chown -R root:root /etc/cron.daily

chmod -R go-rwx /etc/cron.hourly
chown -R root:root /etc/cron.hourly

chmod -R go-rwx /etc/cron.monthly
chown -R root:root /etc/cron.monthly

chmod -R go-rwx /etc/cron.weekly
chown -R root:root /etc/cron.weekly

echo "Permissions applied."
