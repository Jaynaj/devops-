#!/bin/bash
set -e

echo "=== Installing monitoring and logging agents ==="

# Install Prometheus Node Exporter
NODE_EXPORTER_VERSION="1.7.0"
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvfz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

# Create node_exporter user
sudo useradd --no-create-home --shell /bin/false node_exporter || true

# Create systemd service for node_exporter
sudo cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Enable but don't start (will be started on first boot)
sudo systemctl daemon-reload
sudo systemctl enable node_exporter

# Configure rsyslog for centralized logging
sudo apt-get install -y rsyslog

# Enable and configure journald
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald

echo "=== Monitoring and logging installation complete ==="
