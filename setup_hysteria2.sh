#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Update packages
echo "Updating packages..."
sudo apt update && sudo apt upgrade -y

# Install necessary packages
echo "Installing necessary packages..."
sudo apt install -y wget curl openssl dialog

# Install Hysteria2
echo "Installing Hysteria2..."
sudo bash <(curl -fsSL https://get.hy2.sh/)

# Configure Hysteria2 user
echo "Configuring Hysteria2 user..."
sudo HYSTERIA_USER=root bash <(curl -fsSL https://get.hy2.sh/)

# Generate SSL certificates
echo "Generating SSL certificates..."
sudo openssl ecparam -name prime256v1 -out /etc/hysteria/params.pem
sudo openssl req -x509 -nodes -days 3650 -newkey ec:/etc/hysteria/params.pem -keyout /etc/hysteria/key.pem -out /etc/hysteria/cert.pem -subj "/CN=Hysteria2"

# Function to get a random available port
get_random_port() {
    while true; do
        port=$(shuf -i 1000-65535 -n 1)
        if ! sudo lsof -Pi :$port -sTCP:LISTEN -sUDP:LISTEN -t >/dev/null ; then
            break
        fi
    done
    echo $port
}

# Get random ports
listen_port=$(get_random_port)
quic_port=$(get_random_port)

# Generate random passwords
password1=$(openssl rand -base64 12)
password2=$(openssl rand -base64 12)

# Get server's public IP
public_ip=$(curl -s ifconfig.me)

# Configure Hysteria2
echo "Configuring Hysteria2..."
cat <<EOF | sudo tee /etc/hysteria/config.yaml
listen: :$listen_port

tls:
  cert: /etc/hysteria/cert.pem
  key: /etc/hysteria/key.pem

obfs:
  type: salamander
  salamander:
    password: $password1

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
  password: $password2

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

# Restart Hysteria2 service
echo "Restarting Hysteria2 service..."
sudo systemctl restart hysteria-server.service
sudo systemctl enable hysteria-server.service

# Output client configuration
echo "Hysteria2 setup complete. Use the following configuration to connect:"
echo "--------------------------------------------------------------------"
echo "hysteria2://$password2@$public_ip:$listen_port?obfs=salamander&obfs-password=$password1&insecure=1#Hysteria2_VPN"
echo "--------------------------------------------------------------------"
