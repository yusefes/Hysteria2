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
    mkdir -p /etc/hysteria
    openssl ecparam -name prime256v1 -out /etc/hysteria/params.pem
    openssl req -x509 -nodes -days 365 -newkey ec:params.pem \
        -keyout /etc/hysteria/key.pem -out /etc/hysteria/cert.pem \
        -subj "/CN=hysteria.local"
}

# Configure Hysteria 2
configure_hysteria() {
    local PUBLIC_IP="$1"
    local PASSWORD=$(openssl rand -base64 16)
    
    print_info "Configuring Hysteria 2..."
    cat > /etc/hysteria/config.yaml << EOF
listen: :443

tls:
  cert: cert.pem
  key: key.pem

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
}

# Generate client configuration
generate_client_config() {
    local PUBLIC_IP="$1"
    local PASSWORD="$2"
    
    print_info "Generating client configuration..."
    echo
    echo "------------------------CLIENT CONFIGURATION------------------------"
    echo "hysteria2://${PASSWORD}@${PUBLIC_IP}:443?insecure=1&obfs=salamander&obfs-password=${PASSWORD}"
    echo "-----------------------------------------------------------------"
    echo
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
    
    install_required_packages
    install_hysteria
    generate_certificates
    
    # Generate random password and configure
    PASSWORD=$(openssl rand -base64 16)
    configure_hysteria "$PUBLIC_IP"
    
    # Start Hysteria 2 service
    systemctl restart hysteria-server.service
    systemctl enable --now hysteria-server.service
    
    # Check if service is running
    if systemctl is-active --quiet hysteria-server.service; then
        print_info "Hysteria 2 service is running successfully"
        generate_client_config "$PUBLIC_IP" "$PASSWORD"
    else
        print_error "Hysteria 2 service failed to start"
        exit 1
    fi
}

# Run main installation
main
