provider "aws" {  
    region = "us-east-2"
}

resource "aws_instance" "Splunk_Server" {
  ami                         = "ami-04f167a56786e4b09" # Ubuntu 22.04 AMI
  instance_type               = "t2.medium"
  key_name                    = "Honeypot_Access"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["Your Own Security Group"] # Ensure TCP 9997 is open inbound
  root_block_device {
    volume_size = 20 
    volume_type = "gp3"
  }
  user_data = <<-EOF
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
              EOF

  tags = {
    Name = "Splunk_Server"
  }
}

resource "aws_instance" "Honeypot" {
  ami                         = "ami-04f167a56786e4b09" # Ubuntu 22.04 AMI
  instance_type               = "t2.micro"
  key_name                    = "Honeypot_Access"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["Your Own Security Group"] # Make sure this allows outbound and SSH/Telnet in

  depends_on = [aws_instance.Splunk_Server]

  user_data = <<-EOF
              #!/bin/bash
              set -e

              SPLUNK_FWD_URL="https://download.splunk.com/products/universalforwarder/releases/9.4.2/linux/splunkforwarder-9.4.2-e9664af3d956-linux-amd64.deb"
              SPLUNK_FORWARD_SERVER="${aws_instance.Splunk_Server.private_ip}:9997"
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
              EOF

  tags = {
    Name = "Honeypot"
  }
