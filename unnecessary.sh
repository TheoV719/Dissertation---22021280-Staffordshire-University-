#!/bin/bash

# Disable USB storage driver
echo "Disabling USB storage..."
echo "blacklist usb-storage" > /etc/modprobe.d/disable-usb-storage.conf

for host in /sys/bus/usb/devices/usb*
    do
        echo 0 > ${host}/authorized
        echo 0 > ${host}/authorized_default
    done

# Disable unwanted network protocols
echo "Disabling dccp, sctp, rds, and tipc protocols based on Lynis recommendation..."
protocols=("dccp" "sctp" "rds" "tipc")

for protocol in "${protocols[@]}"; do
    # Add the protocol to the blacklist if not already present
    if ! grep -q "install $protocol /bin/true" /etc/modprobe.d/disable-protocols.conf; then
        echo "install $protocol /bin/true" >> /etc/modprobe.d/disable-protocols.conf
        echo "Added rule to prevent $protocol from being loaded."
    else
        echo "Rule for $protocol is already in place."
    fi
    # Attempt to unload the module if currently loaded
    if lsmod | grep -q "^$protocol "; then
        modprobe -r $protocol && echo "Unloaded $protocol module."
    fi
done

# Feedback to user
echo "All tasks completed. Consider rebooting for changes to take full effect."
