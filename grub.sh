#!/bin/bash

GRUB_FILE="/etc/grub.d/40_custom"

# Check if grub2 is installed
if ! dpkg-query -W -f='${Status}' grub-pc | grep "ok installed"; then
  echo "GRUB2 is not installed. Installing..."
  apt-get update
  apt-get install -y grub-pc
fi

# Generate GRUB2 password hash
echo "Please enter a password for GRUB2:"
HASH=$(grub-mkpasswd-pbkdf2 | grep 'PBKDF2 hash of your password is' | cut -d ' ' -f7)

if [[ -z "$HASH" ]]; then
  echo "Failed to generate GRUB2 password hash. Exiting."
  exit 1
fi

# Backup original GRUB configuration
cp "$GRUB_FILE" "$GRUB_FILE.backup"

# Append password to GRUB configuration
echo "set superusers=\"root\"" >> "$GRUB_FILE"
echo "password_pbkdf2 root $HASH" >> "$GRUB_FILE"

echo "GRUB2 password has been set and configuration updated!"
