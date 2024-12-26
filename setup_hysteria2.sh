#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Function to generate random port between 10000-65535
generate_random_port() {
    echo $(shuf -i 10000-65535 -n 1)
}

# Function to generate random string
generate_random_string() {
    echo $(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
}

# Get server IP
SERVER_IP=$(curl -s https://api.ipify.org)
if [[ -z "$SERVER_IP" ]]; then
    echo -e "${RED}Failed to get server IP${NC}"
    exit 1
fi

# Generate random port and passwords
PORT=$(generate_random_port)
PASSWORD1=$(generate_random_string)
PASSWORD2=$(generate_random_string)

echo -e "${GREEN}Installing Hysteria2...${NC}"

# Update system
apt update && apt upgrade -y

# Install Hysteria2
HYSTERIA_USER=root bash <(curl -fsSL https://get.hy2.sh/)

# Install openssl if not present
apt install openssl -y

# Generate certificates
openssl ecparam -name prime256v1 -out /etc/hysteria/params.pem
openssl req -x509 -nodes -days 3650 -newkey ec:/etc/hysteria/params.pem -keyout /etc/hysteria/key.pem -out /etc/hysteria/cert.pem -subj "/CN=Hysteria2"

# Create config file
cat > /etc/hysteria/config.yaml << EOF
listen: :${PORT}

tls:
  cert: cert.pem
  key: key.pem

obfs:
  type: salamander
  salamander:
    password: ${PASSWORD1}

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
  password: ${PASSWORD2}

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

# Restart and enable Hysteria2 service
systemctl restart hysteria-server.service
systemctl enable --now hysteria-server.service

# Check service status
if ! systemctl is-active --quiet hysteria-server.service; then
    echo -e "${RED}Hysteria2 service failed to start${NC}"
    exit 1
fi

# Generate client configuration
CLIENT_CONFIG="hysteria2://${PASSWORD2}@${SERVER_IP}:${PORT}?insecure=1&obfs=salamander&obfs-password=${PASSWORD1}#Hysteria2-VPN"

echo -e "\n${GREEN}Installation completed successfully!${NC}"
echo -e "\n${YELLOW}Your Hysteria2 Configuration:${NC}"
echo -e "${GREEN}$CLIENT_CONFIG${NC}"
echo -e "\n${YELLOW}You can use this configuration in Hiddify, v2rayN, or other supported clients.${NC}"
