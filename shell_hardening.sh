#!/bin/bash

# Backup original configuration files before modifying them
cp /etc/bash.bashrc /etc/bash.bashrc.backup
cp /etc/profile /etc/profile.backup

# 1. Set Session Timeout
# Setting an auto logout feature for shell. After 600 seconds (10 minutes) of inactivity, the shell session will be terminated.
echo "TMOUT=600" | sudo tee -a /etc/profile
echo "readonly TMOUT" | sudo tee -a /etc/profile
echo "export TMOUT" | sudo tee -a /etc/profile

# 2. Ensure default umask value is set to a stricter and more secure value
# Ideally, you'd want to set the default umask to 027 (which means files are created with permissions 750).
# This ensures that by default files/directories are not globally readable.

# Set umask value in /etc/bash.bashrc
if grep -q "umask" /etc/bash.bashrc; then
    # If there's already a umask setting, modify it
    sudo sed -i 's/umask [0-9]*$/umask 027/' /etc/bash.bashrc
else
    # If no umask setting exists, append it
    echo "umask 027" | sudo tee -a /etc/bash.bashrc
fi

# Since the /etc/profile already has the umask setting (as per the recommendation), we won't modify it.
# But if needed, you can follow the same logic as with /etc/bash.bashrc to modify or append the umask setting.

# Notify user of changes and suggest a system restart for some changes to take effect
echo "Shell security enhancements applied. Please restart your shell sessions for changes to take full effect."

