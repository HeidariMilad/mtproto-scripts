#!/bin/bash

# === Basic Config ===
INSTALL_DIR=~/MTProxy
BIN_PATH="$INSTALL_DIR/objs/bin/mtproto-proxy"
SERVICE_PATH="/etc/systemd/system/mtproxy.service"

echo "🔧 MTProto Proxy Installer for Telegram"
echo "--------------------------------------"

# Prompt for optional domain
read -p "🌐 Do you want to set a domain for the proxy? (y/n): " use_domain
domain=""
if [[ "$use_domain" == "y" || "$use_domain" == "Y" ]]; then
    read -p "➡️  Enter domain name (e.g. proxy.example.com): " domain
fi

# Default port
PORT=443

# Generate a random 16-byte hex secret
SECRET=$(head -c 16 /dev/urandom | xxd -ps)
echo "🔐 Generated secret: $SECRET"

# Install dependencies
echo "📦 Installing dependencies..."
sudo apt update && sudo apt install -y git curl build-essential libssl-dev zlib1g-dev

# Clone repo
echo "📁 Cloning MTProxy repo..."
git clone https://github.com/TelegramMessenger/MTProxy.git $INSTALL_DIR

# Build
echo "⚙️  Building MTProxy..."
cd $INSTALL_DIR && make

# Start proxy temporarily
echo "🚀 Starting MTProto proxy on port $PORT..."
sudo $BIN_PATH -u nobody -p 8888 -H $PORT -S $SECRET --aes-pwd proxy-secret proxy-multi.conf -M 1 &

# Get external IP
IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)

# Create Telegram link
if [[ -n "$domain" ]]; then
    TLINK="https://t.me/proxy?server=$domain&port=$PORT&secret=ee$SECRET"
else
    TLINK="https://t.me/proxy?server=$IP&port=$PORT&secret=ee$SECRET"
fi

echo ""
echo "✅ Proxy is now running."
echo "🔗 Your Telegram link:"
echo "$TLINK"
echo ""

# Ask to install as service
read -p "💡 Do you want to install MTProto as a systemd service? (y/n): " install_service

if [[ "$install_service" == "y" || "$install_service" == "Y" ]]; then
    echo "🛠️  Creating systemd service..."
    sudo bash -c "cat > $SERVICE_PATH" <<EOF
[Unit]
Description=MTProto Proxy for Telegram
After=network.target

[Service]
ExecStart=$BIN_PATH -u nobody -p 8888 -H $PORT -S $SECRET --aes-pwd proxy-secret proxy-multi.conf -M 1
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable mtproxy
    sudo systemctl restart mtproxy
    echo "✅ MTProto proxy installed as a systemd service and will auto-start on reboot."
else
    echo "ℹ️  Proxy is currently running but will stop after reboot unless added as a service."
fi

echo ""
echo "🎉 Done!"
