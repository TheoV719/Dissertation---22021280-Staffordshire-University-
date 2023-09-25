##!/bin/bash

# Define rollback function first
RollbackChanges() {
    echo "Rolling back changes..."
    rm -rf /etc/apache2/*
    cp -R "$BACKUP_DIR"/* /etc/apache2/
    service apache2 restart
    echo "Configuration has been rolled back."
}

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Check if apache2 is installed
if ! dpkg -l | grep apache2 &>/dev/null; then
    echo "The script requires Apache2. Please install it and try again."
    exit 1
fi

# Backup Apache2 configuration
BACKUP_DIR="/tmp/apache2_backup_$(date +%Y%m%d%H%M%S)"
echo "Backing up Apache2 configuration to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -R /etc/apache2/* "$BACKUP_DIR/"

# Install necessary modules
apt-get update
apt-get install -y libapache2-mod-evasive libapache2-mod-security2

# Enable the modules
a2enmod evasive
a2enmod security2

# Basic configuration for mod_evasive
cat > /etc/apache2/mods-available/evasive.conf <<EOL
<IfModule mod_evasive20.c>
    DOSHashTableSize    3097
    DOSPageCount        2
    DOSSiteCount        50
    DOSPageInterval     1
    DOSSiteInterval     1
    DOSBlockingPeriod   10
    DOSLogDir           "/var/log/mod_evasive"
</IfModule>
EOL

# Create log directory for mod_evasive
mkdir -p /var/log/mod_evasive

# Add custom WAF rules
cat <<EOL | sudo tee -a /etc/modsecurity/99-custom-rules.conf
# Block common Request Methods
SecRule REQUEST_METHOD "@pm TRACE TRACK" "id:2000,deny,status:405,msg:'TRACE and TRACK are not allowed'"
# Prevent shell command injection via common parameters
SecRule ARGS "@rx (\;|\||\`|<|>|$|\!)" "id:2001,deny,status:403,msg:'Command Injection attempt detected'"
# Block HTTP requests with no User-Agent or with empty User-Agent
SecRule &HTTP_User-Agent "@eq 0" "id:2002,deny,status:400,msg:'Missing User Agent Header'"
SecRule HTTP_User-Agent "^$" "id:2003,deny,status:400,msg:'Empty User Agent Header'"
# Deny request containing <script> or javascript: in ARGS
SecRule ARGS "@rx <script>|javascript:" "id:2004,deny,status:403,msg:'XSS attack attempt detected'"
# Detect and block base64 encoded payloads in ARGS
SecRule ARGS "@rx [A-Za-z0-9+/]{30,}=*" "id:2005,deny,status:403,msg:'Base64 encoded payload detected'"
# Block attempts to access protected files (like .htaccess, .htpasswd, etc.)
SecRule REQUEST_FILENAME "@rx /\.(ht|git)" "id:2006,deny,status:403,msg:'Protected file access attempt'"
# Block potential PHP code/file injections
SecRule REQUEST_FILENAME "@rx (\.php\?.*php://|\.php\?.*data:)" "id:2007,deny,status:403,msg:'Potential PHP code/file injection attempt'"
# Block potential Local File Inclusion (LFI) attempts
SecRule ARGS "@rx (?:\.\./|\.\.\|)" "id:2008,deny,status:403,msg:'Potential Local File Inclusion (LFI) detected'"
# Deny request if referer doesn't match the domain for sensitive pages (Basic CSRF protection)
SecRule REQUEST_URI "@streq /sensitive_page" "chain,id:2009,deny,status:403,msg:'Potential CSRF detected'"
SecRule &HTTP_REFERER "@eq 0" "chain"
SecRule HTTP_REFERER "!@rx ^https?://([^.]+\.)?example\.com/"
EOL

# Test Apache
service apache2 restart
if [[ $? -ne 0 ]]; then
    echo "Error detected with the configurations. Rolling back..."
    RollbackChanges
    exit 1
fi

echo "ModEvasive and ModSecurity with manual rules have been set up for Apache."
