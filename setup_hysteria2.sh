#!/bin/bash

# Automatic Installation Script for Hysteria2 VPN

# Exit on error
set -e

# Prompt for port
read -p "Enter the port for Hysteria2 (default 443): " PORT
PORT=${PORT:-443}

# Determine the server's public IP
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com)

if [[ -z "$SERVER_IP" ]]; then
    echo "Unable to determine server IP. Please ensure curl is installed and try again."
    exit 1
fi

# Update the system
apt update && apt upgrade -y

# Install necessary dependencies
apt install -y openssl nano curl

# Install Hysteria2
bash <(curl -fsSL https://get.hy2.sh/)

# Create TLS certificates
openssl ecparam -name prime256v1 -out /etc/hysteria/params.pem
openssl req -x509 -nodes -days 3650 -newkey ec:/etc/hysteria/params.pem \
    -keyout /etc/hysteria/key.pem \
    -out /etc/hysteria/cert.pem \
    -subj "/CN=Hysteria2"

# Generate configuration file
cat > /etc/hysteria/config.yaml <<EOF
listen: :$PORT

tls:
  cert: /etc/hysteria/cert.pem
  key: /etc/hysteria/key.pem

obfs:
  type: salamander
  salamander:
    password: StrongObfsPass

quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 30s
  maxIncomingStreams: 1024
  disablePathMTUDiscovery: false

bandwidth:
  up: 1 gbps
  down: 1 gbps

ignoreClientBandwidth: false

speedTest: false

disableUDP: false

udpIdleTimeout: 60s

auth:
  type: password
  password: StrongAuthPass

resolver:
  type: udp
  tcp:
    addr: 8.8.8.8:53
    timeout: 4s
  udp:
    addr: 8.8.4.4:53
    timeout: 4s
  tls:
    addr: 1.1.1.1:853
    timeout: 10s
    sni: cloudflare-dns.com
    insecure: false
  https:
    addr: 1.1.1.1:443
    timeout: 10s
    sni: cloudflare-dns.com
    insecure: false

sniff:
  enable: true
  timeout: 2s
  rewriteDomain: false
  tcpPorts: 80,443,8000-9000
  udpPorts: all

masquerade:
  type: proxy
  proxy:
    url: https://news.ycombinator.com/
    rewriteHost: true
EOF

# Restart Hysteria2 with the new configuration
systemctl restart hysteria-server.service
systemctl enable --now hysteria-server.service

# Display the final configuration
echo "\nHysteria2 VPN setup is complete. Use the following configuration to connect:"
CONFIG_URL="hysteria2://StrongAuthPass@$SERVER_IP:$PORT?&insecure=1&obfs=salamander&obfs-password=StrongObfsPass#Hysteria2VPN"
echo "$CONFIG_URL"

# Done
exit 0
