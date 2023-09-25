#!/bin/bash

# Define array of security scripts and their description
# Define indexed arrays of security scripts and their description for ordered processing
declare -a ORDERED_SCRIPTS=(
  "updating.sh"
  "security_tools.sh"
  "AIDE.sh"
  "clamAV.sh"
  "ssl.sh"
  "apache2_hardening.sh"
  "WAF.sh"
  "auditd.sh"
  "banners.sh"
  "permissions.sh"
  "shell_hardening.sh"
  "firewall.sh"
  "kernel.sh"
  "filesystem.sh"
  "unnecessary.sh"
  "grub.sh"
  "ssh.sh"
  "snort.sh"
  "pam.sh"
)

declare -a DESCRIPTIONS=(
  "System Update"
  "Security Tools installation"
  "File Integrity Checker (AIDE) installation"
  "ClamAV installation and configuration"
  "SSL Configuration"
  "Apache2 hardening"
  "Web Application Firewall Setup"
  "Audit Daemon Configuration"
  "Banners Setup"
  "Permission Hardening"
  "Shell Hardening"
  "Firewall Configuration"
  "Kernel Hardening"
  "Filesystem Security"
  "Remove Unnecessary Packages"
  "GRUB Configuration"
  "SSH hardening"
  "Snort installation"
  "PAM Configuration"
)

# Create associative array from indexed arrays
declare -A SCRIPTS
for i in "${!ORDERED_SCRIPTS[@]}"; do
  SCRIPTS[${ORDERED_SCRIPTS[$i]}]=${DESCRIPTIONS[$i]}
done

# Directory to store custom security profiles
PROFILE_DIR="./profiles"

# Check for an active internet connection
check_internet() {
  ping -c 1 8.8.8.8 &> /dev/null
  if [ $? -ne 0 ]; then
    echo "No internet connection. Exiting script."
    exit 1
  fi
}

# Execute selected security scripts
apply_measures() {
  for script in "$@"; do
    echo "Applying ${SCRIPTS[$script]}..."
    ./$script
    if [[ $? == 0 ]]; then
      echo -e "\033[32m${SCRIPTS[$script]} has been applied successfully\033[0m"
    else
      echo -e "\033[31mFailed to apply ${SCRIPTS[$script]}\033[0m"
    fi
    sleep 5
    echo "-------------------------------"
  done
}

snort_menu() {
    while true; do
        echo "SNORT Menu:"
        echo "1. Check SNORT status"
        echo "2. Restart SNORT"
        echo "3. Access SNORT detection logs"
        echo "4. Return to the main menu"

        read -p "Choose an option: " snort_choice

        case $snort_choice in
            1)
                sudo systemctl status snort
                ;;
            2)
                read -p "Are you sure you want to restart SNORT? (y/n): " confirm_restart
                if [[ "$confirm_restart" == "y" || "$confirm_restart" == "Y" ]]; then
                    echo "Restarting SNORT..."
                    sudo systemctl restart snort

                    # Check if SNORT restarted successfully
                    if sudo systemctl is-active --quiet snort; then
                        echo "SNORT restarted successfully!"
                    else
                        echo "SNORT failed to restart. Please check the logs for details."
                    fi
                else
                    echo "SNORT restart cancelled."
                fi
                ;;
            3)
                # Make sure you know the correct path for Snort logs.
                # The path below is a common example. Modify if necessary.
                cat /var/log/snort/snort.alert.fast
                ;;
            4)
                break
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
    done
}

clamav_menu() {
    while true; do
        echo "ClamAV Menu:"
        echo "1. Check ClamAV status (database and daemon)"
        echo "2. Update ClamAV database"
        echo "3. Launch a full system ClamAV scan (This can take a while)"
        echo "4. Return to the main menu"

        read -p "Choose an option: " clamav_choice

        case $clamav_choice in
            1)
                echo "Checking ClamAV Database Version:"
                clamscan --version
                echo "Checking ClamAV Daemon Status:"
                sudo systemctl status clamav-daemon
                ;;
            2)
                echo "Updating ClamAV Database..."
                sudo freshclam
                ;;
            3)
                echo "Warning: A full system scan can take a significant amount of time."
                read -p "Do you want to continue with a full system scan? (y/n): " confirm_scan
                if [[ "$confirm_scan" == "y" || "$confirm_scan" == "Y" ]]; then
                    clamscan -r /
                else
                    echo "Full system scan cancelled."
                fi
                ;;
            4)
                break
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
    done
}

# Display main menu to the user
main_menu() {
  echo -e "\nMain Menu:"
  echo "1. Uniform Approach (Apply all security measures)"
  echo "2. Customized Approach (Select measures to apply)"
  echo "3. Saved profiles"
  echo "4. SNORT Menu"
  echo "5. Vulnerability scanners Menu"
  echo "6. Logwatch logs"
  echo "7. ClamAV Menu"
  echo "8. Exit"
}

# Apply all the security measures
uniform_approach() {
  echo "You have chosen the Uniform Approach. This will apply all security measures. Continue? (y/n)"
  read confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    apply_measures "${ORDERED_SCRIPTS[@]}"
    echo "All measures applied successfully!"
    echo "Please note that applying all these security measures may affect the behavior of your web server."
    echo "It's recommended to reboot your computer for changes to take full effect."
  else
    echo "Cancelled Uniform Approach."
  fi
}

# Allow the user to select specific security measures and apply them
customized_approach() {
  local selections=()
  echo "Select security measures to apply (end selection with a blank):"
  select script in "${!SCRIPTS[@]}"; do
    [[ -z $script ]] && break
    selections+=("$script")
  done

  if [[ ${#selections[@]} -eq 0 ]]; then
    echo "No measures selected. Returning to main menu."
    return
  fi
  
  echo "Selected measures:"
  for script in "${selections[@]}"; do
    echo " - ${SCRIPTS[$script]}"
  done

  echo "Would you like to save this configuration as a profile? (y/n)"
  read save_conf
  if [[ "$save_conf" == "y" || "$save_conf" == "Y" ]]; then
    echo "Enter profile name:"
    read profile_name
    echo "${selections[@]}" > "$PROFILE_DIR/$profile_name"
    echo "Profile saved!"
  fi

  echo "Apply selected measures? (y/n)"
  read apply_conf
  if [[ "$apply_conf" == "y" || "$apply_conf" == "Y" ]]; then
    apply_measures "${selections[@]}"
    echo "Measures applied!"
  else
    echo "Cancelled application of selected measures."
  fi
}

consult_logwatch() {
  if ! command -v logwatch &> /dev/null; then
    echo "Logwatch is not installed. Installing..."
    sudo apt update && sudo apt install -y logwatch
    echo "Logwatch installed successfully!"
  fi

  echo "Generating Logwatch report..."
  logwatch --output stdout
  echo "Finished displaying Logwatch report!"
}


# Apply security measures from a saved profile
apply_profile() {
  local EXIT_OPTION="Return to main menu"

  echo "Available profiles:"
  select profile in $(ls $PROFILE_DIR) "$EXIT_OPTION"; do
    if [[ "$profile" == "$EXIT_OPTION" ]]; then
      echo "Returning to main menu."
      return
    elif [[ -f "$PROFILE_DIR/$profile" ]]; then
      mapfile -t measures < "$PROFILE_DIR/$profile"
      apply_measures "${measures[@]}"
      echo "Measures from profile $profile applied!"
      return
    else
      echo "Invalid profile selected. Please choose again."
    fi
  done
}

check_internet

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit
fi

mkdir -p $PROFILE_DIR

while true; do
  main_menu
  read -r choice

  case $choice in
    1) uniform_approach ;;
    2) customized_approach ;;
    3) apply_profile ;;
    4)
        if ! command -v snort &>/dev/null; then
            echo "SNORT is not installed. Installings..."
            ./snort.sh
        fi
        snort_menu
        ;;
    5) ./scanner.sh ;;
    6) consult_logwatch ;;
    7) 
      if ! command -v clamscan &>/dev/null; then
          echo "ClamAV is not installed. Installing..."
          ./CLAM.sh
      fi
      clamav_menu
      ;;
    8) echo "Exiting script." && exit 0 ;;
    *) echo "Invalid choice. Please try again." ;;
  esac
done
