#!/bin/bash

# MTProto Proxy Setup Script v2.0
# This script sets up an MTProto proxy using mtg (MTProto Go implementation)
# Safe for existing VPS installations with domain support

set -e

echo "🚀 Setting up MTProto Proxy on VPS..."
echo "⚠️  This script will install MTProto proxy without affecting existing services"

# Parse command line arguments
DOMAIN=""
USE_DOMAIN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--domain)
      DOMAIN="$2"
      USE_DOMAIN=true
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -d, --domain DOMAIN    Use domain instead of IP for connection"
      echo "  -h, --help            Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check if we're running as root or with sudo
if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
    echo "❌ This script needs to be run as root or with sudo privileges"
    exit 1
fi

# Update package list (but don't upgrade existing packages to avoid disruption)
echo "📦 Updating package list..."
sudo apt update

# Install only required dependencies that aren't already installed
echo "🔧 Installing required dependencies..."
for package in wget curl xxd tar openssl; do
    if ! dpkg -l | grep -q "^ii  $package "; then
        echo "Installing $package..."
        sudo apt install -y $package
    else
        echo "$package is already installed"
    fi
done

# Download and install mtg (MTProto Go)
echo "⬇️ Downloading MTG (MTProto Go)..."
MTG_VERSION="v2.1.7"
wget -O mtg.tar.gz https://github.com/9seconds/mtg/releases/download/${MTG_VERSION}/mtg-${MTG_VERSION#v}-linux-amd64.tar.gz
tar -xzf mtg.tar.gz
sudo cp mtg-${MTG_VERSION#v}-linux-amd64/mtg /usr/local/bin/mtg
sudo chmod +x /usr/local/bin/mtg
rm -rf mtg.tar.gz mtg-${MTG_VERSION#v}-linux-amd64/

# Generate MTProto secret with domain fronting
echo "🔐 Generating proxy secret..."
SECRET=$(/usr/local/bin/mtg generate-secret google.com)
echo "Generated secret: $SECRET"

# Create mtg user
echo "👤 Creating mtg user..."
sudo useradd -r -s /bin/false mtg 2>/dev/null || true

# Create directories
echo "📁 Creating directories..."
sudo mkdir -p /etc/mtg
sudo mkdir -p /var/log/mtg

# Find available port (prioritize 443)
echo "🔍 Finding available port..."
PORTS=(443 9443 8443 7443 6443 5443 4443)
PORT=""
for p in "${PORTS[@]}"; do
    if ! sudo lsof -i :$p > /dev/null 2>&1; then
        PORT=$p
        break
    fi
done

if [[ -z "$PORT" ]]; then
    echo "❌ No available ports found. Please manually specify a port."
    exit 1
fi

echo "✅ Using port $PORT for MTProto proxy"

# Create configuration file
echo "📝 Creating configuration file..."
sudo tee /etc/mtg/config.toml > /dev/null <<EOF
bind-to = "0.0.0.0:$PORT"
secret = "$SECRET"
debug = false
verbose = false
prefer-ip = "prefer-ipv4"

[stats]
ip = "0.0.0.0"
port = 3129
EOF

# Set capabilities for binding to privileged ports
echo "🔒 Setting capabilities for privileged ports..."
sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/mtg

# Create systemd service
echo "🔧 Creating systemd service..."
sudo tee /etc/systemd/system/mtg.service > /dev/null <<EOF
[Unit]
Description=MTProto Proxy
After=network.target

[Service]
Type=simple
User=mtg
Group=mtg
ExecStart=/usr/local/bin/mtg run /etc/mtg/config.toml
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
# Allow binding to privileged ports
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
echo "🔒 Setting permissions..."
sudo chown -R mtg:mtg /etc/mtg /var/log/mtg

# Enable and start service
echo "🚀 Starting MTProto proxy service..."
sudo systemctl daemon-reload
sudo systemctl enable mtg
sudo systemctl start mtg

# Configure firewall (if ufw is installed)
if command -v ufw &> /dev/null; then
    echo "🔥 Configuring firewall..."
    sudo ufw allow $PORT/tcp
    sudo ufw allow 3129/tcp  # Stats port
    
    # Check if ufw is active before enabling
    if ! sudo ufw status | grep -q "Status: active"; then
        echo "⚠️  UFW is not active. Firewall rules added but not enabled."
        echo "   Run 'sudo ufw enable' to activate firewall if needed."
    fi
fi

# Get server IP or use domain
if [[ "$USE_DOMAIN" == true ]]; then
    SERVER_ADDRESS="$DOMAIN"
    echo "🌐 Using domain: $DOMAIN"
else
    SERVER_ADDRESS=$(curl -s https://ipinfo.io/ip)
    echo "🌐 Using IP: $SERVER_ADDRESS"
fi

# Create connection info file
sudo tee /etc/mtg/connection-info.txt > /dev/null <<EOF
MTProto Proxy Connection Details
===============================
Server: $SERVER_ADDRESS
Port: $PORT
Secret: $SECRET
Connection URL: https://t.me/proxy?server=$SERVER_ADDRESS&port=$PORT&secret=$SECRET
Stats URL: http://$SERVER_ADDRESS:3129
EOF

echo "✅ MTProto Proxy setup complete!"
echo ""
echo "🔗 Connection Details:"
echo "Server: $SERVER_ADDRESS"
echo "Port: $PORT"
echo "Secret: $SECRET"
echo ""
echo "📱 Telegram Connection URL:"
echo "https://t.me/proxy?server=$SERVER_ADDRESS&port=$PORT&secret=$SECRET"
echo ""
echo "📊 Stats available at: http://$SERVER_ADDRESS:3129"
echo ""
echo "🔧 Service commands:"
echo "  Start:   sudo systemctl start mtg"
echo "  Stop:    sudo systemctl stop mtg"
echo "  Status:  sudo systemctl status mtg"
echo "  Logs:    sudo journalctl -u mtg -f"
echo ""
echo "📄 Connection info saved to: /etc/mtg/connection-info.txt"
echo "💡 Save the secret key securely - you'll need it to connect!"
