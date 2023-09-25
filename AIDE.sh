#!/bin/bash

# Install AIDE and initialize its database
sudo apt update
sudo apt install -y aide
sudo aideinit

# Move the new database to be the active database
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Create a daily cron job for AIDE check
echo '#!/bin/bash' | sudo tee /etc/cron.daily/aide_check
echo '/usr/bin/aide.wrapper --check > /var/log/aide/aide.log' | sudo tee -a /etc/cron.daily/aide_check
sudo chmod +x /etc/cron.daily/aide_check

echo "AIDE setup complete."

