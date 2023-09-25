#!/bin/bash

# Define the script's own path
SCRIPT_PATH="$(readlink -f "$0")"

echo "Updating package lists..."
apt-get update

# Upgrade all upgradable packages
echo "Upgrading packages..."
apt-get upgrade -y

# Clean up unnecessary packages and dependencies
echo "Cleaning up..."
apt-get autoremove -y
apt-get autoclean -y

# Schedule the script to run every three days if it's not already scheduled
if ! crontab -l | grep -q "$SCRIPT_PATH"; then
    echo "Setting up the script to run every three days..."
    (crontab -l ; echo "0 0 */3 * * $SCRIPT_PATH") | crontab -
fi

