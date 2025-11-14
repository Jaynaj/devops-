#!/bin/bash
set -e

echo "Starting custom provisioning..."

# Install common utilities
echo "Installing common utilities..."
sudo yum install -y \
    vim \
    htop \
    net-tools \
    telnet \
    nc

# Install Docker (example)
# echo "Installing Docker..."
# sudo yum install -y docker
# sudo systemctl enable docker

# Install CloudWatch Agent (example)
# echo "Installing CloudWatch Agent..."
# sudo yum install -y amazon-cloudwatch-agent

# Configure system settings
echo "Configuring system settings..."
sudo timedatectl set-timezone UTC

# Security hardening (examples)
echo "Applying security hardening..."
# Disable root login
# sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Set up application user (example)
# sudo useradd -m -s /bin/bash appuser

echo "Provisioning completed successfully!"
