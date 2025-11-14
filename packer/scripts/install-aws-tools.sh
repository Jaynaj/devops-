#!/bin/bash
set -e

echo "=== Installing AWS CLI and CloudWatch Agent ==="

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Verify AWS CLI installation
aws --version

# Install AWS CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Install AWS Systems Manager Agent
sudo snap install amazon-ssm-agent --classic
sudo systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

# Install ECS Agent (optional - uncomment if needed for ECS)
# sudo mkdir -p /etc/ecs
# sudo cat > /etc/ecs/ecs.config << 'EOF'
# ECS_CLUSTER=default
# ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
# EOF
#
# sudo docker pull amazon/amazon-ecs-agent:latest

echo "=== AWS tools installation complete ==="
