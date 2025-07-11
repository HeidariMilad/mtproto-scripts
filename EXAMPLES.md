# MTProto Proxy Usage Examples

This document provides practical examples of how to use the MTProto proxy deployment scripts.

## 🚀 Quick Start Examples

### Basic Deployment
```bash
# Deploy to VPS with IP address
./deploy-mtproto.sh -i 192.168.1.100 -k ~/.ssh/id_rsa

# Deploy to VPS with custom SSH user
./deploy-mtproto.sh -i 192.168.1.100 -u ubuntu -k ~/.ssh/id_rsa
```

### Domain-based Deployment
```bash
# Deploy with custom domain
./deploy-mtproto.sh -i 192.168.1.100 -k ~/.ssh/id_rsa -d proxy.example.com

# Deploy to Ubuntu server with domain
./deploy-mtproto.sh -i 192.168.1.100 -u ubuntu -k ~/.ssh/id_rsa -d telegram.mydomain.com
```

## 🛠️ Manual Installation Examples

### Basic Installation
```bash
# On your VPS
./mtproto-proxy-setup-v2.sh
```

### Installation with Domain
```bash
# On your VPS with domain
./mtproto-proxy-setup-v2.sh --domain proxy.example.com
```

## 📱 Management Examples

### Check Status
```bash
# Check if proxy is running
mtproto-manager status

# View detailed service information
sudo systemctl status mtg
```

### View Connection Information
```bash
# Display connection details
mtproto-manager info

# Show connection URL for sharing
mtproto-manager info | grep "Connection URL"
```

### Monitor Logs
```bash
# View real-time logs
mtproto-manager logs

# View last 50 log entries
sudo journalctl -u mtg -n 50
```

### Generate New Secret
```bash
# Generate and apply new secret
mtproto-manager secret

# Generate new secret manually
/usr/local/bin/mtg generate-secret google.com
```

### Update Domain Settings
```bash
# Change from IP to domain
mtproto-manager domain

# Manual domain update
echo "proxy.example.com" | mtproto-manager domain
```

## 🔧 Advanced Configuration Examples

### Custom Port Configuration
```bash
# Check current port
sudo lsof -i :9443

# Change port manually (edit config)
sudo nano /etc/mtg/config.toml
sudo systemctl restart mtg
```

### Firewall Configuration
```bash
# Check firewall status
sudo ufw status

# Manually add firewall rules
sudo ufw allow 9443/tcp
sudo ufw allow 3129/tcp
```

### Service Management
```bash
# Start/stop/restart service
sudo systemctl start mtg
sudo systemctl stop mtg
sudo systemctl restart mtg

# Enable/disable auto-start
sudo systemctl enable mtg
sudo systemctl disable mtg
```

## 📊 Monitoring Examples

### Check Proxy Statistics
```bash
# View proxy stats
mtproto-manager stats

# Direct stats access
curl http://your-server:3129
```

### Resource Monitoring
```bash
# Check memory usage
ps aux | grep mtg

# Monitor network connections
sudo netstat -tlnp | grep mtg

# Check disk usage
du -sh /etc/mtg /var/log/mtg
```

## 🗑️ Uninstallation Examples

### Complete Removal
```bash
# Using management script
mtproto-manager uninstall

# Direct uninstallation
./mtproto-proxy-uninstall.sh
```

### Selective Cleanup
```bash
# Stop service only
sudo systemctl stop mtg
sudo systemctl disable mtg

# Remove just the binary
sudo rm /usr/local/bin/mtg

# Remove configuration
sudo rm -rf /etc/mtg
```

## 🌐 Domain Setup Examples

### DNS Configuration
```bash
# Example DNS records
proxy.example.com.    300    IN    A    192.168.1.100
telegram.example.com. 300    IN    A    192.168.1.100
```

### SSL/TLS Setup (Optional)
```bash
# Install certbot
sudo apt install certbot

# Get SSL certificate
sudo certbot certonly --standalone -d proxy.example.com
```

## 🔒 Security Examples

### SSH Key Management
```bash
# Generate new SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_mtproto

# Copy public key to server
ssh-copy-id -i ~/.ssh/id_rsa_mtproto user@server
```

### Firewall Hardening
```bash
# Enable UFW
sudo ufw enable

# Allow only necessary ports
sudo ufw allow ssh
sudo ufw allow 9443/tcp
sudo ufw allow 3129/tcp

# Deny all other traffic
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

## 🚨 Troubleshooting Examples

### Common Issues
```bash
# Check if port is in use
sudo lsof -i :9443

# Test connectivity
telnet your-server 9443

# Check DNS resolution
nslookup proxy.example.com
```

### Log Analysis
```bash
# Search for errors
sudo journalctl -u mtg | grep -i error

# Filter by date
sudo journalctl -u mtg --since "2024-01-01"

# Export logs
sudo journalctl -u mtg > mtg_logs.txt
```

## 📝 Configuration File Examples

### Basic Configuration
```toml
# /etc/mtg/config.toml
bind-to = "0.0.0.0:9443"
secret = "your-secret-here"
debug = false
verbose = false
prefer-ip = "prefer-ipv4"

[stats]
ip = "0.0.0.0"
port = 3129
```

### Advanced Configuration
```toml
# /etc/mtg/config.toml with custom settings
bind-to = "0.0.0.0:9443"
secret = "your-secret-here"
debug = false
verbose = true
prefer-ip = "prefer-ipv4"
multiplex-per-connection = 500
max-connections = 100000

[stats]
ip = "127.0.0.1"
port = 3129
```

## 🔄 Backup and Restore Examples

### Backup Configuration
```bash
# Backup configuration
sudo cp /etc/mtg/config.toml ~/mtg-backup.toml
sudo cp /etc/mtg/connection-info.txt ~/connection-info-backup.txt

# Backup secret
sudo grep secret /etc/mtg/config.toml > ~/secret-backup.txt
```

### Restore Configuration
```bash
# Restore from backup
sudo cp ~/mtg-backup.toml /etc/mtg/config.toml
sudo systemctl restart mtg
```

---

For more detailed information, refer to the main [README.md](README.md) and [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) files.
