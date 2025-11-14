#!/bin/bash
set -e

echo "Starting Azure custom provisioning..."

# Install common utilities
echo "Installing common utilities..."
sudo apt-get install -y \
    vim \
    htop \
    net-tools \
    telnet \
    netcat

# Install Docker (example)
# echo "Installing Docker..."
# sudo apt-get install -y docker.io
# sudo systemctl enable docker
# sudo systemctl start docker

# Install Azure CLI (optional)
# echo "Installing Azure CLI..."
# curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Configure system settings
echo "Configuring system settings..."
sudo timedatectl set-timezone UTC

# Security hardening (examples)
echo "Applying security hardening..."
# Disable root login
# sudo sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# Set up application user (example)
# sudo useradd -m -s /bin/bash appuser

# Configure automatic security updates
echo "Configuring automatic security updates..."
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

echo "Azure provisioning completed successfully!"
