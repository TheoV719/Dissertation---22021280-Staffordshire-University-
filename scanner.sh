#!/bin/bash

# Function to detect and install software if not present
install_if_not_present() {
    local software=$1
    command -v $software > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        read -p "$software is not installed. Do you want to install it? (Y/n) " choice
        if [[ $choice == "Y" || $choice == "y" || $choice == "" ]]; then
            sudo apt update
            sudo apt install -y $software
        fi
    fi
}

# Scanning functions for each tool
perform_nmap_scan() {
    local IP="localhost"
    echo "Performing nmap scan on $IP..."
    nmap -sC -sS -sV $IP | tee nmap_$IP.log
    echo "Nmap scan completed."
}

perform_nikto_scan() {
    local IP="localhost"
    echo "Performing nikto scan on $IP..."
    nikto -h $IP | tee nikto_$IP.log
    echo "Nikto scan completed."
}

perform_lynis_scan() {
    echo "Performing lynis system audit..."
    sudo lynis audit system | tee lynis.log
    echo "Lynis system audit completed."
}

# Main menu to select scans
show_menu() {
    echo "Please select a scan type:"
    echo "1. Nmap"
    echo "2. Nikto"
    echo "3. Lynis"
    echo "4. All"
    echo "5. Exit"
}

# Driver function for the menu
main() {
    while true; do
        show_menu

        read -p "Enter your choice: " choice

        case $choice in
            1)
                install_if_not_present "nmap"
                perform_nmap_scan
                ;;
            2)
                install_if_not_present "nikto"
                perform_nikto_scan
                ;;
            3)
                install_if_not_present "lynis"
                perform_lynis_scan
                ;;
            4)
                install_if_not_present "nmap"
                install_if_not_present "nikto"
                install_if_not_present "lynis"
                perform_nmap_scan
                perform_nikto_scan
                perform_lynis_scan
                ;;
            5)
                echo "Exiting."
                exit 0
                ;;
            *)
                echo "Invalid option, please try again."
                ;;
        esac
    done
}

main