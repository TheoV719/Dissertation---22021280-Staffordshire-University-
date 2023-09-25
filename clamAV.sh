#!/bin/bash

# Function to check if a command was successful
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error encountered. Exiting..."
        exit 1
    fi
}

# Update package list
sudo apt update
check_status

# Install ClamAV and ClamAV daemon
sudo apt install -y clamav clamav-daemon
check_status

# Stop the ClamAV daemon for configuration
sudo systemctl stop clamav-freshclam
check_status

# Update ClamAV database
sudo freshclam
check_status

# Start the ClamAV updater daemon
sudo systemctl start clamav-freshclam
check_status

# Enable and start the ClamAV daemon
sudo systemctl enable clamav-daemon
sudo systemctl start clamav-daemon
check_status

# Check the ClamAV daemon status
status=$(sudo systemctl is-active clamav-daemon)
if [[ $status == "active" ]]; then
    echo "ClamAV is running actively!"
else
    echo "Failed to start ClamAV. Please check logs and configuration."
    exit 1
fi

# If desired, run a full scan on the system (this may take a while)
# sudo clamscan -r --bell -i /

echo "ClamAV setup and activation completed!"
