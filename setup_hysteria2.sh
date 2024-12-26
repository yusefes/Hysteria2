#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Ensure necessary directories exist
sudo mkdir -p /etc/hysteria

# Install required packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget curl openssl dialog lsof

# Install Hysteria2
sudo bash <(curl -fsSL https://get.hy2.sh/)

# Generate SSL certificates
sudo openssl ecparam -name prime256v1 -out /etc/hysteria/params.pem
sudo openssl req -x509 -nodes -days 3650 -newkey ec:/etc/hysteria/params.pem -keyout /etc/hysteria/key.pem -out /etc/hysteria/cert.pem -subj "/CN=Hysteria2"

# Configure Hysteria2
cat <<EOF | sudo tee /etc/hysteria/config.yaml
# Your configuration settings here
EOF

# Create systemd service file
sudo tee /etc/systemd/system/hysteria.service <<EOF
[Unit]
Description=Hysteria2 Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/hysteria run -c /etc/hysteria/config.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon and enable service
sudo systemctl daemon-reload
sudo systemctl enable hysteria.service
sudo systemctl start hysteria.service

# Output client configuration
echo "Hysteria2 setup complete. Use the following configuration to connect:"
echo "--------------------------------------------------------------------"
echo "Your client configuration link here"
echo "--------------------------------------------------------------------"
