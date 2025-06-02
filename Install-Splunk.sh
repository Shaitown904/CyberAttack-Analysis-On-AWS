#!/bin/bash
set -e

# Update system
apt update && apt upgrade -y

# Download and install Splunk
wget -O splunk-9.4.2-e9664af3d956-linux-amd64.deb "https://download.splunk.com/products/splunk/releases/9.4.2/linux/splunk-9.4.2-e9664af3d956-linux-amd64.deb"
dpkg -i splunk-9.4.2-e9664af3d956-linux-amd64.deb

# Set admin credentials
mkdir -p /opt/splunk/etc/system/local
echo "[user_info]" > /opt/splunk/etc/system/local/user-seed.conf
echo "USERNAME = admin" >> /opt/splunk/etc/system/local/user-seed.conf
echo "PASSWORD = " >> /opt/splunk/etc/system/local/user-seed.conf #Create Your own Password

# Listen on port 9997
echo "[tcp://9997]" > /opt/splunk/etc/system/local/inputs.conf
echo "disabled = false" >> /opt/splunk/etc/system/local/inputs.conf
echo "index = main" >> /opt/splunk/etc/system/local/inputs.conf

# Start and enable Splunk
/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt
/opt/splunk/bin/splunk enable boot-start
/opt/splunk/bin/splunk restart
