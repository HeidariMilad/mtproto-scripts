# MTProto Proxy Deployment Package

A complete solution for deploying MTProto proxy servers on VPS instances with domain support, management tools, and easy uninstallation.

## 🚀 Features

- **Easy Deployment**: One-command deployment to any VPS
- **Domain Support**: Use custom domains instead of IP addresses
- **Safe Installation**: Won't affect existing services
- **Management Tools**: Built-in management script with multiple commands
- **Clean Uninstallation**: Complete removal with system restoration
- **Firewall Configuration**: Automatic firewall rules setup
- **Service Management**: Systemd service with auto-restart
- **Connection Info**: Generates ready-to-use Telegram URLs

## 📦 Package Contents

```
mtproto-proxy-deployment/
├── deploy-mtproto.sh              # Main deployment script
├── mtproto-proxy-setup-v2.sh      # VPS installation script
├── mtproto-manager-v2.sh           # Management script
├── mtproto-proxy-uninstall.sh     # Uninstallation script
├── README.md                       # This file
└── DEPLOYMENT_GUIDE.md            # Detailed deployment guide
```

## 🔧 Quick Start

### 1. Deploy to VPS

```bash
# Basic deployment with IP
./deploy-mtproto.sh -i YOUR_VPS_IP -k ~/.ssh/your_key

# Deployment with domain
./deploy-mtproto.sh -i YOUR_VPS_IP -k ~/.ssh/your_key -d proxy.yourdomain.com

# Deployment with custom user
./deploy-mtproto.sh -i YOUR_VPS_IP -u ubuntu -k ~/.ssh/your_key
```

### 2. Management Commands

Once deployed, use these commands on your VPS:

```bash
# Check status
mtproto-manager status

# View connection info
mtproto-manager info

# View logs
mtproto-manager logs

# Generate new secret
mtproto-manager secret

# Update domain settings
mtproto-manager domain

# Restart service
mtproto-manager restart

# Completely uninstall
mtproto-manager uninstall
```

## 🌐 Domain Configuration

### Using IP Address (Default)
If you don't specify a domain, the proxy will use your VPS IP address for connections.

### Using Custom Domain
To use a custom domain:

1. **During deployment:**
   ```bash
   ./deploy-mtproto.sh -i YOUR_VPS_IP -d proxy.yourdomain.com -k ~/.ssh/your_key
   ```

2. **After deployment:**
   ```bash
   ssh your_vps
   mtproto-manager domain
   ```

3. **DNS Configuration:**
   - Add an A record pointing your domain to your VPS IP
   - Example: `proxy.yourdomain.com -> YOUR_VPS_IP`

## 🛠️ Installation Options

### Automatic Deployment (Recommended)
```bash
./deploy-mtproto.sh -i YOUR_VPS_IP -k ~/.ssh/your_key
```

### Manual Installation
1. Upload scripts to your VPS
2. Run the setup script:
   ```bash
   # Basic installation
   ./mtproto-proxy-setup-v2.sh
   
   # With domain
   ./mtproto-proxy-setup-v2.sh --domain yourdomain.com
   ```

## 🔍 Connection Information

After installation, you'll receive:

```
MTProto Proxy Connection Details
===============================
Server: proxy.yourdomain.com (or IP)
Port: 9443
Secret: [generated secret]
Connection URL: https://t.me/proxy?server=...
Stats URL: http://proxy.yourdomain.com:3129
```

## 📱 Connecting to Telegram

### Method 1: Direct URL
Click the generated connection URL or paste it in your browser.

### Method 2: Manual Configuration
1. Open Telegram
2. Go to Settings → Data and Storage → Proxy Settings
3. Add MTProto proxy:
   - Server: Your domain or IP
   - Port: The assigned port (usually 9443)
   - Secret: The generated secret

## 🔧 Advanced Configuration

### Port Selection
The installer automatically finds available ports in this order:
- 443 (preferred - HTTPS port for better bypass capability)
- 9443, 8443, 7443, 6443, 5443, 4443

### Firewall Configuration
The installer automatically configures UFW if available:
- Opens the proxy port (443 or alternative if occupied)
- Opens the stats port (3129)
- Sets proper capabilities for binding to privileged ports

### Service Management
```bash
# System service commands
sudo systemctl start mtg
sudo systemctl stop mtg
sudo systemctl restart mtg
sudo systemctl status mtg

# View logs
sudo journalctl -u mtg -f
```

## 🗑️ Uninstallation

### Complete Removal
```bash
# Using management script
mtproto-manager uninstall

# Or directly
./mtproto-proxy-uninstall.sh
```

### What Gets Removed
- ✅ MTG service stopped and disabled
- ✅ MTG binary removed
- ✅ Configuration files removed
- ✅ Log files removed
- ✅ System user removed
- ✅ Firewall rules cleaned
- ✅ Temporary files cleaned

## 🔒 Security Considerations

1. **Secret Management**: Keep your secret key private
2. **Firewall**: The installer configures basic firewall rules
3. **Updates**: Keep your system updated
4. **SSH Security**: Use SSH keys instead of passwords
5. **Domain Security**: Use HTTPS and secure DNS

## 🐛 Troubleshooting

### Common Issues

**Cannot connect to VPS:**
- Check IP address and SSH key
- Verify VPS is running
- Check firewall rules

**Proxy not working:**
- Check service status: `mtproto-manager status`
- View logs: `mtproto-manager logs`
- Verify firewall: `sudo ufw status`

**Port conflicts:**
- The installer automatically finds available ports
- Manually check: `sudo lsof -i :9443`

### Log Analysis
```bash
# View recent logs
sudo journalctl -u mtg -n 50

# Follow logs in real-time
sudo journalctl -u mtg -f

# Check service status
sudo systemctl status mtg
```

## 📊 Monitoring

### Statistics
Access proxy statistics at: `http://your-domain:3129`

### Resource Usage
```bash
# Check process
ps aux | grep mtg

# Check network connections
sudo netstat -tlnp | grep mtg

# Check resource usage
top -p $(pgrep mtg)
```

## 🔄 Updates

### Updating MTG
```bash
# Stop service
sudo systemctl stop mtg

# Download latest version
wget -O mtg.tar.gz https://github.com/9seconds/mtg/releases/download/v2.1.7/mtg-2.1.7-linux-amd64.tar.gz
tar -xzf mtg.tar.gz
sudo cp mtg-2.1.7-linux-amd64/mtg /usr/local/bin/
sudo chmod +x /usr/local/bin/mtg

# Start service
sudo systemctl start mtg
```

## 🤝 Support

For issues and questions:
1. Check the troubleshooting section
2. View logs for error messages
3. Verify configuration files
4. Check the official MTG documentation

## 📄 License

This deployment package is provided as-is for educational and legitimate use only.

## 🔗 Useful Links

- [MTG Official Repository](https://github.com/9seconds/mtg)
- [Telegram Proxy Documentation](https://core.telegram.org/mtproto)
- [UFW Firewall Guide](https://help.ubuntu.com/community/UFW)

---

**Note**: Always use MTProto proxies responsibly and in compliance with local laws and regulations.
