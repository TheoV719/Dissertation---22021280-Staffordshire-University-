#!/bin/bash

PACKAGES="apt-listchanges needrestart fail2ban rkhunter acct apt-show-versions debsums arpwatch auditd sysstat usbguard logwatch nmap nikto lynis software-properties-common"
TO_INSTALL=""

# Checking which packages are not installed
for tool in $PACKAGES; do
    if dpkg -l | grep -qw "$tool"; then
        echo "$tool is already installed."
    else
        echo "$tool is not installed."
        TO_INSTALL="$TO_INSTALL $tool"
    fi
done


# Install missing packages if any
if [ -n "$TO_INSTALL" ]; then
    sudo apt update
    for tool in $TO_INSTALL; do
        echo "Installing $tool..."
        sudo apt install -y "$tool"
        echo "$tool installed successfully!"
        sudo apt upgrade "$tool"
        echo "$tool upgraded successfully!"
    done
else
    echo "All packages are already installed. No action needed."
fi


# Copy /etc/fail2ban/jail.conf to /etc/fail2ban/jail.local, ensuring that jail.local will not be overwritten during package updates
if [[ -e "/etc/fail2ban/jail.conf" && ! -e "/etc/fail2ban/jail.local" ]]; then
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
fi

# Activating accton
sudo /usr/sbin/accton on

# Enable sysstat data collection (change ENABLED from "false" to "true")
sudo sed -i 's/^ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
# Restart the sysstat service to apply changes
sudo systemctl restart sysstat

echo "sysstat installed and enabled!"

# Install and configure Ansible if not already done
if ! dpkg -l | grep -qw "ansible"; then
    # Add the Ansible PPA and install Ansible
    sudo apt-add-repository --yes --update ppa:ansible/ansible
    sudo apt install -y ansible
    echo "Ansible installed!"
fi
