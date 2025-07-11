#!/bin/bash

# MTProto Proxy Manager Script v2.0
# Manage your MTProto proxy with ease

CONFIG_FILE="/etc/mtg/config.toml"
SERVICE_NAME="mtg"

show_help() {
    echo "MTProto Proxy Manager v2.0"
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status      - Show proxy status"
    echo "  start       - Start the proxy"
    echo "  stop        - Stop the proxy"
    echo "  restart     - Restart the proxy"
    echo "  logs        - Show logs"
    echo "  info        - Show connection info"
    echo "  stats       - Show proxy statistics"
    echo "  secret      - Generate new secret"
    echo "  domain      - Update domain settings"
    echo "  uninstall   - Completely remove MTProto proxy"
    echo "  help        - Show this help message"
}

show_status() {
    echo "🔍 Checking MTProto proxy status..."
    sudo systemctl status $SERVICE_NAME --no-pager
}

start_proxy() {
    echo "🚀 Starting MTProto proxy..."
    sudo systemctl start $SERVICE_NAME
    echo "✅ Proxy started successfully"
}

stop_proxy() {
    echo "⏹️  Stopping MTProto proxy..."
    sudo systemctl stop $SERVICE_NAME
    echo "✅ Proxy stopped successfully"
}

restart_proxy() {
    echo "🔄 Restarting MTProto proxy..."
    sudo systemctl restart $SERVICE_NAME
    echo "✅ Proxy restarted successfully"
}

show_logs() {
    echo "📋 Showing MTProto proxy logs..."
    sudo journalctl -u $SERVICE_NAME -f
}

show_info() {
    echo "📊 MTProto Proxy Connection Info"
    echo "================================="
    
    # Check if saved connection info exists
    if [[ -f /etc/mtg/connection-info.txt ]]; then
        echo "📄 Reading saved connection info..."
        cat /etc/mtg/connection-info.txt
        return
    fi
    
    # Fallback to generating info
    SERVER_IP=$(curl -s https://ipinfo.io/ip 2>/dev/null || echo "Unable to fetch IP")
    
    # Extract secret from config
    if [[ -f $CONFIG_FILE ]]; then
        SECRET=$(grep '^secret' $CONFIG_FILE | awk -F'"' '{print $2}')
        PORT=$(grep '^bind-to' $CONFIG_FILE | awk -F':' '{print $2}' | tr -d '"')
    else
        SECRET="Config file not found"
        PORT="Unknown"
    fi
    
    echo "🌐 Server IP: $SERVER_IP"
    echo "🔌 Port: $PORT"
    echo "🔐 Secret: $SECRET"
    echo ""
    echo "📱 Telegram Connection URL:"
    echo "https://t.me/proxy?server=$SERVER_IP&port=$PORT&secret=$SECRET"
    echo ""
    echo "📊 Stats URL: http://$SERVER_IP:3129"
}

show_stats() {
    echo "📈 Fetching proxy statistics..."
    SERVER_IP=$(curl -s https://ipinfo.io/ip 2>/dev/null || echo "127.0.0.1")
    curl -s "http://$SERVER_IP:3129" 2>/dev/null || echo "❌ Unable to fetch stats. Make sure the proxy is running."
}

generate_secret() {
    echo "🔐 Generating new secret..."
    if command -v /usr/local/bin/mtg &> /dev/null; then
        NEW_SECRET=$(/usr/local/bin/mtg generate-secret google.com)
    else
        NEW_SECRET=$(head -c 16 /dev/urandom | xxd -p)
    fi
    echo "New secret: $NEW_SECRET"
    
    read -p "Do you want to update the configuration with this new secret? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo sed -i "s/^secret = .*/secret = \"$NEW_SECRET\"/" $CONFIG_FILE
        echo "✅ Configuration updated with new secret"
        echo "🔄 Restarting proxy to apply changes..."
        sudo systemctl restart $SERVICE_NAME
        echo "✅ Proxy restarted successfully"
        update_connection_info
        show_info
    else
        echo "Secret not applied. Use 'mtproto-manager info' to see current connection details."
    fi
}

update_domain() {
    echo "🌐 Domain Configuration"
    echo "======================"
    
    read -p "Enter your domain (leave empty to use IP): " DOMAIN
    
    if [[ -z "$DOMAIN" ]]; then
        SERVER_ADDRESS=$(curl -s https://ipinfo.io/ip 2>/dev/null || echo "Unable to fetch IP")
        echo "🌐 Using IP address: $SERVER_ADDRESS"
    else
        SERVER_ADDRESS="$DOMAIN"
        echo "🌐 Using domain: $DOMAIN"
    fi
    
    update_connection_info "$SERVER_ADDRESS"
    echo "✅ Connection info updated"
    show_info
}

update_connection_info() {
    local SERVER_ADDRESS=${1:-$(curl -s https://ipinfo.io/ip 2>/dev/null || echo "Unknown")}
    
    if [[ -f $CONFIG_FILE ]]; then
        SECRET=$(grep '^secret' $CONFIG_FILE | awk -F'"' '{print $2}')
        PORT=$(grep '^bind-to' $CONFIG_FILE | awk -F':' '{print $2}' | tr -d '"')
        
        sudo tee /etc/mtg/connection-info.txt > /dev/null <<EOF
MTProto Proxy Connection Details
===============================
Server: $SERVER_ADDRESS
Port: $PORT
Secret: $SECRET
Connection URL: https://t.me/proxy?server=$SERVER_ADDRESS&port=$PORT&secret=$SECRET
Stats URL: http://$SERVER_ADDRESS:3129
EOF
    fi
}

uninstall_proxy() {
    echo "⚠️  This will completely remove MTProto proxy from your system!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Starting uninstallation process..."
        
        # Stop and disable service
        if systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
            sudo systemctl stop $SERVICE_NAME
        fi
        if systemctl is-enabled --quiet $SERVICE_NAME 2>/dev/null; then
            sudo systemctl disable $SERVICE_NAME
        fi
        
        # Remove files
        sudo rm -f /etc/systemd/system/mtg.service
        sudo rm -f /usr/local/bin/mtg
        sudo rm -f /usr/local/bin/mtproto-manager
        sudo rm -rf /etc/mtg
        sudo rm -rf /var/log/mtg
        
        # Remove user
        sudo userdel mtg 2>/dev/null || true
        
        # Clean up firewall rules
        if command -v ufw &> /dev/null; then
            RULES=$(sudo ufw status numbered | grep -E "(443|9443|8443|7443|6443|5443|4443|3129)" | awk '{print $1}' | tr -d '[]' | sort -nr)
            if [[ -n "$RULES" ]]; then
                while IFS= read -r rule_num; do
                    if [[ -n "$rule_num" ]]; then
                        echo "y" | sudo ufw delete "$rule_num" 2>/dev/null || true
                    fi
                done <<< "$RULES"
            fi
        fi
        
        sudo systemctl daemon-reload
        sudo pkill -x mtg 2>/dev/null || true
        
        echo "✅ MTProto proxy has been completely removed!"
    else
        echo "❌ Uninstallation cancelled"
    fi
}

# Main script logic
case "$1" in
    status)
        show_status
        ;;
    start)
        start_proxy
        ;;
    stop)
        stop_proxy
        ;;
    restart)
        restart_proxy
        ;;
    logs)
        show_logs
        ;;
    info)
        show_info
        ;;
    stats)
        show_stats
        ;;
    secret)
        generate_secret
        ;;
    domain)
        update_domain
        ;;
    uninstall)
        uninstall_proxy
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
