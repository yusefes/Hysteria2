#!/bin/bash

# Hysteria 2 Auto Installer
# This script automatically installs and configures Hysteria 2 server

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    print_error "This script must be run as root"
    exit 1
fi

# Function to get server's public IP
get_public_ip() {
    IP=$(curl -s https://api.ipify.org)
    if [[ -z "$IP" ]]; then
        IP=$(curl -s http://ifconfig.me)
    fi
    echo "$IP"
}

# Install required packages
install_required_packages() {
    print_info "Installing required packages..."
    apt update
    apt install -y curl openssl
}

# Install Hysteria 2
install_hysteria() {
    print_info "Installing Hysteria 2..."
    bash <(curl -fsSL https://get.hy2.sh/)
}

# Generate certificates
generate_certificates() {
    print_info "Generating certificates..."
    cd /etc/hysteria
    openssl ecparam -name prime256v1 -genkey -noout -out key.pem
    openssl req -new -x509 -days 365 -key key.pem -out cert.pem -subj "/CN=hysteria.local"
}

# Configure Hysteria 2
configure_hysteria() {
    local PUBLIC_IP="$1"
    local PASSWORD=$(openssl rand -base64 16)
    
    print_info "Configuring Hysteria 2..."
    cat > /etc/hysteria/config.yaml << EOF
listen: :443

tls:
  cert: /etc/hysteria/cert.pem
  key: /etc/hysteria/key.pem

obfs:
  type: salamander
  salamander:
    password: ${PASSWORD}

auth:
  type: password
  password: ${PASSWORD}

bandwidth:
  up: 1 gbps
  down: 1 gbps

resolver:
  type: udp
  udp:
    addr: "8.8.8.8:53"
    timeout: 4s

masquerade:
  type: proxy
  proxy:
    url: https://news.ycombinator.com/
    rewriteHost: true
EOF

    # Save password for later use
    echo "${PASSWORD}" > /etc/hysteria/password.txt
}

# Generate client configuration
generate_client_config() {
    local PUBLIC_IP="$1"
    local PASSWORD=$(cat /etc/hysteria/password.txt)
    
    print_info "Generating client configuration..."
    echo
    echo "------------------------CLIENT CONFIGURATION------------------------"
    echo "hysteria2://${PASSWORD}@${PUBLIC_IP}:443?insecure=1&obfs=salamander&obfs-password=${PASSWORD}"
    echo "-----------------------------------------------------------------"
    echo
}

# Create required directories
prepare_environment() {
    print_info "Preparing environment..."
    mkdir -p /etc/hysteria
}

# Main installation process
main() {
    print_info "Starting Hysteria 2 installation..."
    
    # Get public IP
    PUBLIC_IP=$(get_public_ip)
    if [[ -z "$PUBLIC_IP" ]]; then
        print_error "Could not determine public IP address"
        exit 1
    fi
    
    prepare_environment
    install_required_packages
    install_hysteria
    generate_certificates
    configure_hysteria "$PUBLIC_IP"
    
    # Start Hysteria 2 service
    systemctl daemon-reload
    systemctl restart hysteria-server.service
    systemctl enable --now hysteria-server.service
    
    # Check if service is running
    if systemctl is-active --quiet hysteria-server.service; then
        print_info "Hysteria 2 service is running successfully"
        generate_client_config "$PUBLIC_IP"
    else
        print_error "Hysteria 2 service failed to start. Checking logs..."
        journalctl -u hysteria-server.service --no-pager -n 50
        exit 1
    fi
}

# Run main installation
main
