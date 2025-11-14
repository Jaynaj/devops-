#!/bin/bash
set -e

echo "=== Applying security hardening ==="

# Update system packages one more time
sudo apt-get update -y
sudo apt-get upgrade -y

# Install security packages
sudo apt-get install -y \
    fail2ban \
    ufw \
    unattended-upgrades \
    aide

# Configure automatic security updates
sudo dpkg-reconfigure -plow unattended-upgrades

# Configure fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Configure UFW firewall (disabled by default, enable in user-data)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
# Don't enable UFW here - let it be enabled in user-data if needed

# Disable root login via SSH
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable password authentication (use SSH keys only)
sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Set proper file permissions
sudo chmod 600 /etc/ssh/sshd_config

# Configure kernel parameters for security
sudo cat >> /etc/sysctl.conf << 'EOF'

# Security hardening
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
EOF

# Apply sysctl changes
sudo sysctl -p

# Set up log rotation
sudo cat > /etc/logrotate.d/custom << 'EOF'
/var/log/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
}
EOF

echo "=== Security hardening complete ==="
