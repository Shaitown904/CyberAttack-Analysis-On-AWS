 #!/bin/bash
set -e

SPLUNK_FWD_URL="https://download.splunk.com/products/universalforwarder/releases/9.4.2/linux/splunkforwarder-9.4.2-e9664af3d956-linux-amd64.deb"
SPLUNK_FORWARD_SERVER="<your_server's_public_IP>:9997"
SPLUNK_ADMIN_PASSWORD="" #Create your own password

# Update system and install dependencies
apt update && apt upgrade -y
apt install -y git python3 python3-pip python3-venv libffi-dev libssl-dev libpython3-dev authbind build-essential wget

# Add cowrie user if not exists
if ! id "cowrie" &>/dev/null; then
  useradd -m -s /bin/bash cowrie
fi

# Install and configure Cowrie
sudo -i -u cowrie bash <<'EOS'
cd ~
if [ ! -d "cowrie" ]; then
  git clone https://github.com/cowrie/cowrie.git
fi
cd cowrie
python3 -m venv cowrie-env
source cowrie-env/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
cp etc/cowrie.cfg.dist etc/cowrie.cfg
deactivate
EOS

# Setup Cowrie systemd service
cat <<EOS > /etc/systemd/system/cowrie.service
[Unit]
Description=Cowrie SSH/Telnet Honeypot
After=network.target

[Service]
User=cowrie
WorkingDirectory=/home/cowrie/cowrie
ExecStart=/home/cowrie/cowrie/cowrie-env/bin/python /home/cowrie/cowrie/src/cowrie/entry.py start
ExecStop=/home/cowrie/cowrie/cowrie-env/bin/python /home/cowrie/cowrie/src/cowrie/entry.py stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOS

systemctl daemon-reload
systemctl enable cowrie
systemctl start cowrie

# Download and install Splunk Universal Forwarder
wget -O splunkforwarder.deb "$SPLUNK_FWD_URL"
dpkg -i splunkforwarder.deb

# Configure admin credentials
mkdir -p /opt/splunkforwarder/etc/system/local
echo "[user_info]" > /opt/splunkforwarder/etc/system/local/user-seed.conf
echo "USERNAME = admin" >> /opt/splunkforwarder/etc/system/local/user-seed.conf
echo "PASSWORD = $SPLUNK_ADMIN_PASSWORD" >> /opt/splunkforwarder/etc/system/local/user-seed.conf

# Start and enable Splunk Forwarder
/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt
/opt/splunkforwarder/bin/splunk enable boot-start

# Forward to Splunk Server
/opt/splunkforwarder/bin/splunk add forward-server "$SPLUNK_FORWARD_SERVER" -auth admin:$SPLUNK_ADMIN_PASSWORD

# Monitor Cowrie logs
/opt/splunkforwarder/bin/splunk add monitor /home/cowrie/cowrie/var/log/cowrie.log -auth admin:$SPLUNK_ADMIN_PASSWORD
