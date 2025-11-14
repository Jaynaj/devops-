#!/bin/bash
set -e

echo "=== Cleaning up ==="

# Clean apt cache
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove -y

# Remove temporary files
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Clear bash history
cat /dev/null > ~/.bash_history
history -c

# Remove SSH host keys (will be regenerated on first boot)
sudo rm -f /etc/ssh/ssh_host_*

# Clear cloud-init artifacts
sudo cloud-init clean --logs --seed

# Clear log files
sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
sudo find /var/log -type f -name "*.gz" -delete
sudo find /var/log -type f -name "*.1" -delete

# Remove machine-id (will be regenerated)
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

# Clear user history
sudo rm -f /home/*/.bash_history
sudo rm -f /root/.bash_history

# Sync to ensure all writes are committed
sync

echo "=== Cleanup complete ==="
