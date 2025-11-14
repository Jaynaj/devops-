#!/bin/bash
set -e

echo "=== Updating system packages ==="

# Update package lists
sudo apt-get update -y

# Upgrade existing packages
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install essential packages
sudo apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    jq \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    build-essential

echo "=== System update complete ==="
