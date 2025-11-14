#!/bin/bash
set -e

echo "=== Installing Azure CLI and tools ==="

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify Azure CLI installation
az --version

# Install Azure Monitor Agent (optional)
wget https://aka.ms/azuremonitorlinuxagent -O azure-monitor-agent.deb
sudo dpkg -i azure-monitor-agent.deb || sudo apt-get install -f -y
rm azure-monitor-agent.deb

echo "=== Azure tools installation complete ==="
