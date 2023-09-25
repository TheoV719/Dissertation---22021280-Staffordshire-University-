#!/bin/bash

# Define paths and backup paths
PAM_FILE="/etc/pam.d/common-password"
LOGINDEFS="/etc/login.defs"
PAM_BACKUP="$PAM_FILE.backup"
LOGINDEFS_BACKUP="$LOGINDEFS.backup"

# --- Function Definitions ---

# Backup the specified file
backup_file() {
    local file="$1"
    local backup="$2"
    cp "$file" "$backup"
    echo "[INFO] Backup for $file created at $backup."
}

# Restore the specified backup file
restore_backup() {
    local original="$1"
    local backup="$2"
    mv "$backup" "$original"
    echo "[INFO] Restored the backup from $backup to $original."
}

# Install the specified package if not already installed
check_and_install() {
    local package="$1"
    if ! dpkg -l | grep -q "$package"; then
        apt-get update && apt-get install -y "$package"
    else
        echo "[INFO] $package is already installed."
    fi
}

# --- Main Execution Starts Here ---

# Install necessary packages
check_and_install "libpam-modules"
check_and_install "libpam-pwquality"
check_and_install "libpam-tmpdir"

# Backup current configurations
backup_file $PAM_FILE $PAM_BACKUP
backup_file $LOGINDEFS $LOGINDEFS_BACKUP

# Update PAM configurations
if grep -q "pam_pwquality.so" $PAM_FILE; then
    sed -i 's/^password\s*requisite\s*pam_pwquality.so.*/password requisite pam_pwquality.so retry=3 minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1 rounds=5000/' $PAM_FILE
fi

if grep -q "pam_unix.so" $PAM_FILE; then
    sed -i '/pam_unix.so/ s/$/ rounds=5000/' $PAM_FILE
else
    echo "password required pam_unix.so rounds=5000" >> $PAM_FILE
fi

# Update password aging and hashing configurations in /etc/login.defs
sed -i '/^PASS_MIN_DAYS/ c\PASS_MIN_DAYS   7' $LOGINDEFS
sed -i '/^PASS_MAX_DAYS/ c\PASS_MAX_DAYS   90' $LOGINDEFS
sed -i '/^PASS_WARN_AGE/ c\PASS_WARN_AGE   7' $LOGINDEFS

if grep -q "^ENCRYPT_METHOD" $LOGINDEFS; then
    sed -i 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD SHA512/' $LOGINDEFS
else
    echo "ENCRYPT_METHOD SHA512" >> $LOGINDEFS
fi

# Verification of changes
VERIFIED=true
grep -q "rounds=5000" $PAM_FILE || VERIFIED=false
grep -q "ENCRYPT_METHOD SHA512" $LOGINDEFS || VERIFIED=false
grep -q "SHA_CRYPT_MIN_ROUNDS 5000" $LOGINDEFS || VERIFIED=false
grep -q "^PASS_MIN_DAYS   7" $LOGINDEFS || VERIFIED=false
grep -q "^PASS_MAX_DAYS   90" $LOGINDEFS || VERIFIED=false

if $VERIFIED; then
    echo "[SUCCESS] All changes applied successfully!"
else
    echo "[ERROR] Applying changes failed! Restoring backups..."
    restore_backup $PAM_FILE $PAM_BACKUP
    restore_backup $LOGINDEFS $LOGINDEFS_BACKUP
fi

# Paths
PROFILE="/etc/profile"
LOGINDEFS="/etc/login.defs"

# Set a desired umask value; 027 is a common choice for added security
DESIRED_UMASK="027"

# Check and set umask in /etc/profile
if ! grep -q "umask" $PROFILE; then
    echo "umask $DESIRED_UMASK" >> $PROFILE
    echo "[INFO] Added umask $DESIRED_UMASK to $PROFILE."
else
    echo "[INFO] umask already set in $PROFILE."
fi

# Check and set umask in /etc/login.defs
if grep -q "^UMASK" $LOGINDEFS; then
    # If UMASK is already defined, modify its value
    sed -i "s/^UMASK.*/UMASK       $DESIRED_UMASK/" $LOGINDEFS
    echo "[INFO] Updated umask to $DESIRED_UMASK in $LOGINDEFS."
else
    # If UMASK is not defined, add it
    echo "UMASK       $DESIRED_UMASK" >> $LOGINDEFS
    echo "[INFO] Added umask $DESIRED_UMASK to $LOGINDEFS."
fi

# Define the number of days until the password must be changed.
DAYS_TILL_EXPIRY=90

# Fetch users with valid shells.
USERS_WITH_SHELL=$(awk -F: '$7 !~ /nologin|false/ {print $1}' /etc/passwd)

for user in $USERS_WITH_SHELL; do
    # Check if the user has a password set (i.e., 'x' in the password field).
    if grep -q "^$user:x:" /etc/passwd; then
        # Set the maximum days till password change for the user.
        chage -M $DAYS_TILL_EXPIRY $user
        echo "Set password expiry for $user to $DAYS_TILL_EXPIRY days."
    fi
done

echo "Password expiration dates set for all users."


for user in $(awk -F: '$3 >= 1000 && $3 != 65534 && $7 !~ /nologin/ {print $1}' /etc/passwd); do
    chage -d 0 $user
    echo "Password expired for user $user. They must reset it on next login."
done

echo "Script finished."