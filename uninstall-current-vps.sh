#!/bin/bash

# Quick uninstall script for current VPS
# This demonstrates how to clean uninstall from your Vultr VPS

echo "🗑️  Uninstalling MTProto proxy from Vultr VPS..."
echo "=================================================="

# Upload and run uninstaller
scp /Users/milad/mtproto-proxy-uninstall.sh vultr:~/
ssh vultr 'chmod +x ~/mtproto-proxy-uninstall.sh && ~/mtproto-proxy-uninstall.sh'

echo ""
echo "✅ Uninstallation complete!"
echo "Your VPS has been restored to its previous state."
