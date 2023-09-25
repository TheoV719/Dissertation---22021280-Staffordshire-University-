#!/bin/bash

# Check if iptables-persistent is installed
if ! dpkg-query -W -f='${Status}' iptables-persistent | grep "install ok installed"; then
    echo "iptables-persistent is not installed. Installing..."
    sudo apt update
    sudo apt install -y iptables-persistent
else
    echo "iptables-persistent is already installed. Skipping installation."
fi

# Flush current rules
sudo iptables -F

# Default policies
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Loopback interface (localhost)
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

# Allow established sessions to receive traffic
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow incoming SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow incoming HTTP & HTTPS
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Block invalid packets
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Block SYN flood attacks
sudo iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
sudo iptables -A INPUT -p tcp --syn -j DROP

# Block excessive ICMP requests (Ping of Death)
sudo iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# Block port scanning (rate-limit incoming connections)
sudo iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

# Block common DDoS attack patterns (adjust as needed)
sudo iptables -A INPUT -p udp -m multiport --sports 53,123 -j ACCEPT
sudo iptables -A INPUT -p udp -j DROP

# Limit the rate of incoming SSH connections
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m limit --limit 3/min --limit-burst 3 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j DROP

# Test connectivity
ping -c 3 8.8.8.8    

# Check if the ping was successful. If not, flush the rules.
if [ $? -ne 0 ]; then
    echo "Failed to reach the internet. Flushing iptables rules..."
    sudo iptables -F
    sudo iptables -P INPUT ACCEPT
    sudo iptables -P FORWARD ACCEPT
    sudo iptables -P OUTPUT ACCEPT
else
    echo "Internet connectivity confirmed."
fi

# Save rules
sudo sh -c 'iptables-save > /etc/iptables/rules.v4'
