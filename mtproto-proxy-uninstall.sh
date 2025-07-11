#!/bin/bash

# MTProto Proxy Uninstaller Script
# This script completely removes MTProto proxy and all its configurations

set -e

echo "🗑️  MTProto Proxy Uninstaller"
echo "==============================="
echo ""

# Check if we're running as root or with sudo
if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
    echo "❌ This script needs to be run as root or with sudo privileges"
    exit 1
fi

# Confirm uninstallation
read -p "⚠️  Are you sure you want to completely remove MTProto proxy? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Uninstallation cancelled"
    exit 1
fi

echo "🔍 Checking for MTProto proxy installation..."

# Stop and disable service if it exists
if systemctl is-active --quiet mtg 2>/dev/null; then
    echo "⏹️  Stopping MTProto proxy service..."
    sudo systemctl stop mtg
fi

if systemctl is-enabled --quiet mtg 2>/dev/null; then
    echo "🔧 Disabling MTProto proxy service..."
    sudo systemctl disable mtg
fi

# Remove systemd service file
if [[ -f /etc/systemd/system/mtg.service ]]; then
    echo "🗑️  Removing systemd service file..."
    sudo rm -f /etc/systemd/system/mtg.service
    sudo systemctl daemon-reload
fi

# Remove binary
if [[ -f /usr/local/bin/mtg ]]; then
    echo "🗑️  Removing MTG binary..."
    sudo rm -f /usr/local/bin/mtg
fi

# Remove management script
if [[ -f /usr/local/bin/mtproto-manager ]]; then
    echo "🗑️  Removing management script..."
    sudo rm -f /usr/local/bin/mtproto-manager
fi

# Remove configuration and data directories
if [[ -d /etc/mtg ]]; then
    echo "🗑️  Removing configuration directory..."
    sudo rm -rf /etc/mtg
fi

if [[ -d /var/log/mtg ]]; then
    echo "🗑️  Removing log directory..."
    sudo rm -rf /var/log/mtg
fi

# Remove user
if id "mtg" &>/dev/null; then
    echo "👤 Removing mtg user..."
    sudo userdel mtg 2>/dev/null || true
fi

# Remove firewall rules
if command -v ufw &> /dev/null; then
    echo "🔥 Checking firewall rules..."
    
    # Get list of MTProto related rules
    RULES=$(sudo ufw status numbered | grep -E "(9443|8443|7443|6443|5443|4443|3129)" | awk '{print $1}' | tr -d '[]' | sort -nr)
    
    if [[ -n "$RULES" ]]; then
        echo "🔥 Removing firewall rules..."
        while IFS= read -r rule_num; do
            if [[ -n "$rule_num" ]]; then
                echo "   Removing rule $rule_num..."
                echo "y" | sudo ufw delete "$rule_num" 2>/dev/null || true
            fi
        done <<< "$RULES"
    else
        echo "   No MTProto firewall rules found"
    fi
fi

# Clean up any remaining processes
if pgrep -x "mtg" > /dev/null; then
    echo "🔧 Killing remaining MTG processes..."
    sudo pkill -x mtg || true
fi

# Remove any temporary files
echo "🧹 Cleaning up temporary files..."
sudo rm -f /tmp/mtg* 2>/dev/null || true
sudo rm -f /root/mtg* 2>/dev/null || true

echo ""
echo "✅ MTProto proxy has been completely uninstalled!"
echo ""
echo "🔍 Summary of removed items:"
echo "  ✓ MTG service stopped and disabled"
echo "  ✓ MTG binary removed from /usr/local/bin/"
echo "  ✓ Management script removed"
echo "  ✓ Configuration directory removed (/etc/mtg)"
echo "  ✓ Log directory removed (/var/log/mtg)"
echo "  ✓ MTG user removed"
echo "  ✓ Firewall rules cleaned up"
echo "  ✓ Temporary files cleaned up"
echo ""
echo "🎉 Your system has been restored to its previous state!"
echo ""
echo "💡 Note: Dependencies (wget, curl, xxd, tar, openssl) were not removed"
echo "   as they might be used by other applications."
