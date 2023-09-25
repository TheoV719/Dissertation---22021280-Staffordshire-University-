#!/bin/bash

# Ensure auditd is installed
if ! command -v auditctl &> /dev/null; then
    echo "auditd is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y auditd audispd-plugins
fi

# Define the rules

# Monitor the modification of the /etc/passwd, /etc/shadow, and /etc/group
sudo auditctl -w /etc/passwd -p wa -k passwd_changes
sudo auditctl -w /etc/shadow -p wa -k shadow_changes
sudo auditctl -w /etc/group -p wa -k group_changes

# Monitor the Apache/Nginx configuration and log directories
sudo auditctl -w /etc/apache2/ -p wa -k apache_config_change
sudo auditctl -w /etc/nginx/ -p wa -k nginx_config_change
sudo auditctl -w /var/log/apache2/ -p wa -k apache_logs
sudo auditctl -w /var/log/nginx/ -p wa -k nginx_logs

# Monitor all executions in the system
sudo auditctl -a always,exit -F arch=b64 -S execve -k exec_tracking

# Log unauthorized access attempts to the web server
sudo auditctl -a always,exit -F arch=b64 -S connect -k web_access

# Monitor usage of the sudo command
sudo auditctl -w /usr/bin/sudo -p x -k sudo_usage

# Monitor file deletion events
sudo auditctl -a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k file_deletion

# Monitor system time changes
sudo auditctl -a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time_change

# Monitor kernel module loading and unloading
sudo auditctl -w /sbin/insmod -p x -k module_insert
sudo auditctl -w /sbin/rmmod -p x -k module_remove
sudo auditctl -w /sbin/modprobe -p x -k module_manage

# Make the configuration persistent across reboots
echo "-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group -p wa -k group_changes
-w /etc/apache2/ -p wa -k apache_config_change
-w /var/log/apache2/ -p wa -k apache_logs
-a always,exit -F arch=b64 -S execve -k exec_tracking
-a always,exit -F arch=b64 -S connect -k web_access
-w /usr/bin/sudo -p x -k sudo_usage
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k file_deletion
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time_change
-w /sbin/insmod -p x -k module_insert
-w /sbin/rmmod -p x -k module_remove
-w /sbin/modprobe -p x -k module_manage" | sudo tee -a /etc/audit/rules.d/audit.rules

# Restart auditd
sudo systemctl restart auditd

echo "Audit rules added successfully!"
