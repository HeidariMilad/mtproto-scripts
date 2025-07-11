#!/bin/bash

# MTProto Proxy Deployment Script
# This script helps you deploy MTProto proxy to your VPS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
VPS_IP=""
VPS_USER="root"
SSH_KEY=""
DOMAIN=""
USE_DOMAIN=false

show_help() {
    echo "MTProto Proxy Deployment Script"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --ip IP          VPS IP address"
    echo "  -u, --user USER      SSH username (default: root)"
    echo "  -k, --key KEY        SSH key file path"
    echo "  -d, --domain DOMAIN  Use domain instead of IP"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -i 192.168.1.100 -k ~/.ssh/id_rsa"
    echo "  $0 -i 192.168.1.100 -u ubuntu -d proxy.example.com"
}

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--ip)
            VPS_IP="$2"
            shift 2
            ;;
        -u|--user)
            VPS_USER="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        -d|--domain)
            DOMAIN="$2"
            USE_DOMAIN=true
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$VPS_IP" ]]; then
    error "VPS IP address is required"
    show_help
    exit 1
fi

# Interactive mode if parameters are missing
if [[ -z "$SSH_KEY" ]]; then
    echo -e "${BLUE}Available SSH keys:${NC}"
    if ls ~/.ssh/id_* 2>/dev/null | grep -v ".pub" | head -5; then
        echo ""
        read -p "Enter SSH key path (or press Enter for default): " SSH_KEY
        if [[ -z "$SSH_KEY" ]]; then
            SSH_KEY="$HOME/.ssh/id_rsa"
        fi
    else
        warn "No SSH keys found in ~/.ssh/"
        read -p "Enter SSH key path: " SSH_KEY
    fi
fi

# Validate SSH key
if [[ ! -f "$SSH_KEY" ]]; then
    error "SSH key file not found: $SSH_KEY"
    exit 1
fi

# Ask for domain if not provided
if [[ -z "$DOMAIN" ]]; then
    read -p "Enter domain name (leave empty to use IP): " DOMAIN
    if [[ -n "$DOMAIN" ]]; then
        USE_DOMAIN=true
    fi
fi

echo ""
echo -e "${BLUE}=== Deployment Configuration ===${NC}"
echo "VPS IP: $VPS_IP"
echo "SSH User: $VPS_USER"
echo "SSH Key: $SSH_KEY"
if [[ "$USE_DOMAIN" == true ]]; then
    echo "Domain: $DOMAIN"
else
    echo "Using IP address for connections"
fi
echo ""

read -p "Continue with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Test SSH connection
log "Testing SSH connection..."
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes "$VPS_USER@$VPS_IP" "echo 'SSH connection successful'" 2>/dev/null; then
    error "Cannot connect to VPS via SSH"
    echo "Please check:"
    echo "- VPS IP address is correct"
    echo "- SSH key is correct and has proper permissions"
    echo "- VPS is running and accessible"
    exit 1
fi

log "SSH connection successful"

# Upload scripts
log "Uploading installation scripts..."
scp -i "$SSH_KEY" "$(dirname "$0")/mtproto-proxy-setup-v2.sh" "$VPS_USER@$VPS_IP:~/"
scp -i "$SSH_KEY" "$(dirname "$0")/mtproto-manager-v2.sh" "$VPS_USER@$VPS_IP:~/"
scp -i "$SSH_KEY" "$(dirname "$0")/mtproto-proxy-uninstall.sh" "$VPS_USER@$VPS_IP:~/"

# Make scripts executable
log "Making scripts executable..."
ssh -i "$SSH_KEY" "$VPS_USER@$VPS_IP" "chmod +x ~/mtproto-proxy-setup-v2.sh ~/mtproto-manager-v2.sh ~/mtproto-proxy-uninstall.sh"

# Run installation
log "Running MTProto proxy installation..."
if [[ "$USE_DOMAIN" == true ]]; then
    ssh -i "$SSH_KEY" "$VPS_USER@$VPS_IP" "~/mtproto-proxy-setup-v2.sh --domain $DOMAIN"
else
    ssh -i "$SSH_KEY" "$VPS_USER@$VPS_IP" "~/mtproto-proxy-setup-v2.sh"
fi

# Install management script
log "Installing management script..."
ssh -i "$SSH_KEY" "$VPS_USER@$VPS_IP" "sudo mv ~/mtproto-manager-v2.sh /usr/local/bin/mtproto-manager && sudo chmod +x /usr/local/bin/mtproto-manager"

# Get connection info
log "Retrieving connection information..."
CONNECTION_INFO=$(ssh -i "$SSH_KEY" "$VPS_USER@$VPS_IP" "cat /etc/mtg/connection-info.txt")

# Clean up uploaded files
log "Cleaning up temporary files..."
ssh -i "$SSH_KEY" "$VPS_USER@$VPS_IP" "rm -f ~/mtproto-proxy-setup-v2.sh ~/mtproto-proxy-uninstall.sh"

echo ""
echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo "$CONNECTION_INFO"
echo ""
echo -e "${BLUE}Management Commands:${NC}"
echo "ssh -i $SSH_KEY $VPS_USER@$VPS_IP 'mtproto-manager status'"
echo "ssh -i $SSH_KEY $VPS_USER@$VPS_IP 'mtproto-manager logs'"
echo "ssh -i $SSH_KEY $VPS_USER@$VPS_IP 'mtproto-manager info'"
echo ""
echo -e "${GREEN}🎉 Your MTProto proxy is ready to use!${NC}"
