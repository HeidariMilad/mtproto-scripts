# MTProto Proxy Deployment Guide

This guide will help you set up an MTProto proxy on your VPS to connect to Telegram.

## Prerequisites

- A VPS with Ubuntu/Debian (16.04+ recommended)
- Root or sudo access
- Internet connectivity
- Open port 443 (HTTPS) - most VPS providers allow this by default

## Quick Setup

### 1. Upload Files to Your VPS

Upload the following files to your VPS:
- `mtproto-proxy-setup.sh` - Main setup script
- `mtproto-manager.sh` - Management script

```bash
# Copy files to your VPS (replace YOUR_VPS_IP with actual IP)
scp mtproto-proxy-setup.sh root@YOUR_VPS_IP:~/
scp mtproto-manager.sh root@YOUR_VPS_IP:~/
```

### 2. Run the Setup Script

```bash
# SSH into your VPS
ssh root@YOUR_VPS_IP

# Make the script executable
chmod +x mtproto-proxy-setup.sh

# Run the setup script
./mtproto-proxy-setup.sh
```

The script will:
- Install required dependencies
- Download and install MTG (MTProto Go)
- Generate a random secret key
- Configure the proxy service
- Start the proxy automatically
- Configure firewall rules
- Display connection information

### 3. Install Management Script (Optional)

```bash
# Make the management script executable
chmod +x mtproto-manager.sh

# Move it to a global location for easy access
sudo mv mtproto-manager.sh /usr/local/bin/mtproto-manager

# Now you can use it from anywhere
mtproto-manager info
```

## Configuration Details

### Default Settings
- **Port**: 443 (HTTPS port to bypass restrictions)
- **Protocol**: MTProto
- **Stats Port**: 3129 (for monitoring)
- **User**: mtg (dedicated service user)

### Service Management

```bash
# Using systemctl
sudo systemctl start mtg      # Start the proxy
sudo systemctl stop mtg       # Stop the proxy
sudo systemctl restart mtg    # Restart the proxy
sudo systemctl status mtg     # Check status

# Using the management script
mtproto-manager start
mtproto-manager stop
mtproto-manager restart
mtproto-manager status
mtproto-manager logs
```

## Connecting to Telegram

After setup, you'll get a connection URL like:
```
https://t.me/proxy?server=YOUR_VPS_IP&port=443&secret=YOUR_SECRET_KEY
```

### Connection Methods

1. **Direct URL**: Click the generated link
2. **Manual Setup**: 
   - Open Telegram
   - Go to Settings → Data and Storage → Proxy Settings
   - Add MTProto proxy with your server details

## Security Considerations

1. **Secret Key**: Keep your secret key private. If compromised, generate a new one:
   ```bash
   mtproto-manager secret
   ```

2. **Firewall**: The script configures basic firewall rules. Consider additional security:
   ```bash
   # Restrict SSH access to specific IPs
   sudo ufw allow from YOUR_IP to any port 22
   sudo ufw delete allow 22
   ```

3. **Updates**: Keep your system updated:
   ```bash
   sudo apt update && sudo apt upgrade
   ```

## Monitoring

### Check Proxy Status
```bash
mtproto-manager status
```

### View Logs
```bash
mtproto-manager logs
```

### View Statistics
```bash
mtproto-manager stats
# Or visit: http://YOUR_VPS_IP:3129
```

## Troubleshooting

### Common Issues

1. **Port 443 blocked**: Some VPS providers block port 443. Try changing to port 8080:
   ```bash
   sudo nano /etc/mtg/config.toml
   # Change bind-to = "0.0.0.0:8080"
   sudo systemctl restart mtg
   ```

2. **Connection refused**: Check if the service is running:
   ```bash
   sudo systemctl status mtg
   ```

3. **Firewall issues**: Ensure ports are open:
   ```bash
   sudo ufw status
   sudo ufw allow 443
   ```

### Log Analysis
```bash
# View recent logs
sudo journalctl -u mtg -n 50

# Follow logs in real-time
sudo journalctl -u mtg -f
```

## Performance Optimization

### For High Traffic
```bash
# Edit config for better performance
sudo nano /etc/mtg/config.toml
```

Add these settings:
```toml
[performance]
buffer-size = 65536
workers = 4
```

### Resource Monitoring
```bash
# Check resource usage
htop
# Monitor network
sudo netstat -tlnp | grep :443
```

## Backup Configuration

```bash
# Backup your configuration
sudo cp /etc/mtg/config.toml ~/mtg-config-backup.toml
```

## Updating MTG

```bash
# Download latest version
MTG_VERSION="v1.1.4"  # Check GitHub for latest
wget -O mtg https://github.com/9seconds/mtg/releases/download/${MTG_VERSION}/mtg-linux-amd64
chmod +x mtg
sudo systemctl stop mtg
sudo mv mtg /usr/local/bin/
sudo systemctl start mtg
```

## Support

If you encounter issues:
1. Check logs: `mtproto-manager logs`
2. Verify configuration: `mtproto-manager info`
3. Test connection: Try connecting from different networks
4. Check official MTG documentation: https://github.com/9seconds/mtg

## Security Best Practices

1. **Regular Updates**: Keep your VPS and MTG updated
2. **Strong Passwords**: Use strong passwords for your VPS
3. **SSH Keys**: Use SSH keys instead of passwords
4. **Monitor Usage**: Regularly check proxy statistics
5. **Rotate Secrets**: Change proxy secrets periodically

Remember to save your connection details securely!
