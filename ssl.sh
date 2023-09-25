#!/bin/bash

# Check if the script is running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." 
   exit 1
fi

# Backup current Apache2 configuration
BACKUP_DIR="/etc/apache2/backup_$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r /etc/apache2/sites-available/ "$BACKUP_DIR/"

# Define the location for the SSL files
SSL_DIR="/etc/apache2/ssl"
mkdir -p "$SSL_DIR"

# Generate a self-signed certificate (valid for 365 days)
openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout "$SSL_DIR/apache-selfsigned.key" -out "$SSL_DIR/apache-selfsigned.crt"

# Configure Apache2 for SSL
cat > /etc/apache2/sites-available/default-ssl.conf <<EOL
<IfModule mod_ssl.c>
    <VirtualHost _default_:443>
        ServerAdmin webmaster@localhost

        DocumentRoot /var/www/html

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        SSLEngine on
        SSLCertificateFile      $SSL_DIR/apache-selfsigned.crt
        SSLCertificateKeyFile   $SSL_DIR/apache-selfsigned.key

        # Disable weak protocols and use strong ciphers
        SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1
        SSLCipherSuite          ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256
        SSLHonorCipherOrder     on
        SSLSessionTickets       off

        <FilesMatch "\.(cgi|shtml|phtml|php)$">
                SSLOptions +StdEnvVars
        </FilesMatch>
        <Directory /usr/lib/cgi-bin>
                SSLOptions +StdEnvVars
        </Directory>
    </VirtualHost>
</IfModule>
EOL

# Enable SSL and the default SSL site
a2enmod ssl
a2ensite default-ssl

# Test Apache2 configuration
apachectl configtest
if [ $? -eq 0 ]; then
    # Restart Apache2 to apply changes
    systemctl restart apache2
    if [ $? -eq 0 ]; then
        echo "Enhanced SSL/TLS setup complete for Apache2 with self-signed certificate."
    else
        echo "Error detected while restarting Apache2. Rolling back changes..."
        rm -r /etc/apache2/sites-available/
        cp -r "$BACKUP_DIR/sites-available/" /etc/apache2/
        systemctl restart apache2
        echo "Configuration has been rolled back."
    fi
else
    echo "Error detected in Apache2 configuration. Rolling back changes..."
    rm -r /etc/apache2/sites-available/
    cp -r "$BACKUP_DIR/sites-available/" /etc/apache2/
    systemctl restart apache2
    echo "Configuration has been rolled back."
fi
