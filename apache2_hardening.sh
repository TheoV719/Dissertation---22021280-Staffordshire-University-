#!/bin/bash

# Check if Apache2 is installed
if ! dpkg -l | grep -qw apache2; then
    echo "Apache2 is not installed. Exiting."
    exit 1
fi

# Backup Apache2 configuration
CONFIG_DIR="/etc/apache2"
BACKUP_DIR="/etc/apache2-backup-$(date +"%Y%m%d%H%M%S")"

if [ -d "$CONFIG_DIR" ]; then
    echo "Backing up Apache2 configuration..."
    sudo cp -r "$CONFIG_DIR" "$BACKUP_DIR"
else
    echo "Apache2 configuration directory not found. Exiting."
    exit 1
fi

# 1. Set permissions and ownership
echo "Setting permissions on Apache2 configuration files..."
sudo chown root:root /etc/apache2/apache2.conf
sudo chmod 644 /etc/apache2/apache2.conf

# 2. Disable directory listings
echo "Disabling directory listings..."
sudo sed -i 's/Options Includes Indexes FollowSymLinks/Options Includes FollowSymLinks/' /etc/apache2/apache2.conf

# 3. Hide Apache version and other sensitive information
echo "Disabling server tokens and server signatures..."
sudo sed -i 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
sudo sed -i 's/ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf

# 4. Restrict HTTP methods
echo "Limiting HTTP methods..."
echo "<Directory />
    <LimitExcept GET POST HEAD>
        deny from all
    </LimitExcept>
</Directory>" | sudo tee -a /etc/apache2/apache2.conf > /dev/null

# 5. Disable unnecessary modules
echo "Disabling unnecessary Apache2 modules..."
sudo a2dismod autoindex status cgi

# 6. Set appropriate timeouts and limits
echo "Setting timeouts and limits..."
sudo sed -i 's/Timeout 300/Timeout 60/' /etc/apache2/apache2.conf
echo "LimitRequestBody 512000" | sudo tee -a /etc/apache2/apache2.conf > /dev/null

# 7. Log All Events 
echo "Ensuring all events are logged..."
sudo sed -i 's/LogLevel warn/LogLevel info/' /etc/apache2/apache2.conf

# Restart Apache2 to apply changes
echo "Restarting Apache2 to apply changes..."
sudo systemctl restart apache2

# Check for any errors
if [[ $? -ne 0 ]]; then
    echo "Error while restarting Apache2."
    read -p "Would you like to rollback to the backup configuration? (y/n) " choice
    if [[ $choice == "y" || $choice == "Y" ]]; then
        echo "Rolling back..."
        sudo rm -r "$CONFIG_DIR"
        sudo cp -r "$BACKUP_DIR" "$CONFIG_DIR"
        sudo systemctl restart apache2
        echo "Rollback complete."
    else
        echo "No rollback performed. Please check the configurations."
    fi
    exit 1
else
    echo "Apache2 hardened successfully."
fi
