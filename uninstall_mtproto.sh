#!/bin/bash

echo "🧹 MTProto Proxy Uninstaller"
echo "----------------------------"

SERVICE_PATH="/etc/systemd/system/mtproxy.service"
INSTALL_DIR=~/MTProxy

# Stop and disable systemd service
if systemctl list-units --full -all | grep -Fq "mtproxy.service"; then
    echo "🛑 Stopping and disabling mtproxy systemd service..."
    sudo systemctl stop mtproxy
    sudo systemctl disable mtproxy
    sudo rm -f $SERVICE_PATH
    sudo systemctl daemon-reload
else
    echo "⚠️  No mtproxy systemd service found."
fi

# Remove installed files
if [ -d "$INSTALL_DIR" ]; then
    echo "🗑️  Removing MTProxy directory..."
    rm -rf "$INSTALL_DIR"
else
    echo "⚠️  MTProxy directory not found at $INSTALL_DIR"
fi

# Clean up firewall rules (optional)
echo "🔥 Checking for open ports (443, 8888)..."
read -p "➡️  Do you want to remove UFW/iptables rules for ports 443 and 8888? (y/n): " clean_fw
if [[ "$clean_fw" == "y" || "$clean_fw" == "Y" ]]; then
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw delete allow 443 2>/dev/null
        sudo ufw delete allow 8888 2>/dev/null
        echo "✅ UFW rules cleaned."
    fi
    sudo iptables -D INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null
    sudo iptables -D INPUT -p tcp --dport 8888 -j ACCEPT 2>/dev/null
    echo "✅ iptables rules cleaned."
fi

echo "✅ Uninstallation complete."
