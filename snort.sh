#!/bin/bash

echo "Snort IDS Installation and Configuration Script"

is_snort_installed() {
    if command -v snort &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to check if Snort is configured with community rules
is_community_rules_configured() {
    if grep -q "community.rules" /etc/snort/snort.conf; then
        return 0
    else
        return 1
    fi
}

# Function to install and setup Snort
install_snort() {
    echo "[*] Updating the package repository..."
    sudo apt update

    echo "[*] Installing Snort..."
    sudo apt install -y snort

    # Verifying installation
    if ! command -v snort &> /dev/null; then
        echo "[-] Error: Snort installation failed!"
        exit 1
    fi

    echo "[*] Snort installation completed successfully."
}

# Function to setup community rules
setup_community_rules() {
    echo "[*] Downloading and installing community rules..."

    # Backup original configuration
    sudo cp /etc/snort/snort.conf /etc/snort/snort.conf.bak

    sudo wget https://www.snort.org/downloads/community/community-rules.tar.gz -O /tmp/community-rules.tar.gz
    sudo tar -xzvf /tmp/community-rules.tar.gz -C /tmp/
    sudo mkdir -p /etc/snort/rules
    sudo cp /tmp/community-rules/community.rules /etc/snort/rules/

    # Check if RULE_PATH is set, if not, set it
    if ! grep -q "RULE_PATH" /etc/snort/snort.conf; then
        echo "var RULE_PATH /etc/snort/rules" | sudo tee -a /etc/snort/snort.conf
    fi

    # Add the community rules to the snort.conf
    echo "include \$RULE_PATH/community.rules" | sudo tee -a /etc/snort/snort.conf

    # Cleanup temporary files
    sudo rm -rf /tmp/community-rules.tar.gz /tmp/community-rules

    echo "[*] Community rules setup completed."
}

# Function to verify Snort configuration

verify_snort_config() {
    echo "[*] Verifying Snort configuration..."

    snort -T -c /etc/snort/snort.conf
    if [ $? -eq 0 ]; then
        echo "[+] Snort configuration verification was successful!"
    else
        echo "[-] There was an issue verifying the Snort configuration. Please review the configuration and logs."
        exit 1
    fi
}

# Main execution

if is_snort_installed; then
    echo "[*] Snort is already installed."

    if is_community_rules_configured; then
        echo "[*] Community rules are already configured. Exiting..."
        exit 0
    else
        echo "[*] Configuring Snort with community rules..."
        setup_community_rules
        verify_snort_config
    fi
else
    echo "[*] Installing and configuring Snort..."
    install_snort
    setup_community_rules
    verify_snort_config
fi

echo "[*] Script execution completed. Snort IDS is set up and ready."
