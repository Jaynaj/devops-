#!/bin/bash
set -e

echo "=== Installing application dependencies ==="

# Install Node.js (if needed)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js installation
node --version
npm --version

# Install Python 3 and pip (if needed)
sudo apt-get install -y python3 python3-pip python3-venv

# Verify Python installation
python3 --version
pip3 --version

# Install common utilities
sudo apt-get install -y \
    htop \
    vim \
    tmux \
    net-tools \
    dnsutils \
    iputils-ping \
    telnet

# Install monitoring tools
sudo apt-get install -y \
    sysstat \
    iotop \
    nethogs

echo "=== Application dependencies installation complete ==="
