#!/bin/bash

#!/bin/bash

# Define the legal banner

BANNER="\
*******************************************************************************
* WARNING: Unauthorized access to this system is forbidden and will be        *
* prosecuted by law. By accessing this system, you agree that your actions    *
* may be monitored if unauthorized usage is suspected.                        *
*******************************************************************************
"

# Add the banner to /etc/issue
echo "$BANNER" > /etc/issue

# Add the banner to /etc/issue.net
echo "$BANNER" > /etc/issue.net

echo "Legal banners added to /etc/issue and /etc/issue.net"

