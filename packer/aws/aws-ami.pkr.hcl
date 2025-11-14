# Packer configuration for building AWS AMI
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# Variables
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_name_prefix" {
  type    = string
  default = "myapp"
}

variable "ami_description" {
  type    = string
  default = "Custom AMI built with Packer"
}

variable "source_ami_owner" {
  type    = string
  default = "099720109477" # Canonical (Ubuntu)
}

variable "source_ami_filter_name" {
  type    = string
  default = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "app_version" {
  type    = string
  default = "1.0.0"
}

# Local variables
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  ami_name  = "${var.ami_name_prefix}-${var.environment}-${local.timestamp}"
}

# Data source to get the latest Ubuntu AMI
data "amazon-ami" "ubuntu" {
  filters = {
    name                = var.source_ami_filter_name
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = [var.source_ami_owner]
  region      = var.aws_region
}

# Source configuration
source "amazon-ebs" "app" {
  ami_name        = local.ami_name
  ami_description = var.ami_description
  instance_type   = var.instance_type
  region          = var.aws_region
  source_ami      = data.amazon-ami.ubuntu.id
  ssh_username    = var.ssh_username

  # Enable EBS encryption
  encrypt_boot = true

  # Launch configuration
  associate_public_ip_address = true
  subnet_filter {
    filters = {
      "tag:Tier" = "Public"
    }
    most_free = true
    random    = false
  }

  # Tags
  tags = {
    Name        = local.ami_name
    Environment = var.environment
    OS          = "Ubuntu"
    OS_Version  = "22.04"
    Release     = "Latest"
    AppVersion  = var.app_version
    CreatedBy   = "Packer"
    BuildTime   = local.timestamp
  }

  # Snapshot tags
  snapshot_tags = {
    Name        = "${local.ami_name}-snapshot"
    Environment = var.environment
    CreatedBy   = "Packer"
  }

  # AMI configuration
  ami_virtualization_type = "hvm"
  ena_support             = true
  sriov_support           = true

  # Launch block device mappings
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }
}

# Build configuration
build {
  name    = "aws-ami-build"
  sources = ["source.amazon-ebs.app"]

  # Wait for cloud-init to complete
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait"
    ]
  }

  # Update system packages
  provisioner "shell" {
    script = "../scripts/update-system.sh"
  }

  # Install Docker and Docker Compose
  provisioner "shell" {
    script = "../scripts/install-docker.sh"
  }

  # Install AWS CLI and CloudWatch agent
  provisioner "shell" {
    script = "../scripts/install-aws-tools.sh"
  }

  # Install application dependencies
  provisioner "shell" {
    script = "../scripts/install-app-dependencies.sh"
  }

  # Security hardening
  provisioner "shell" {
    script = "../scripts/security-hardening.sh"
  }

  # Install monitoring and logging agents
  provisioner "shell" {
    script = "../scripts/install-monitoring.sh"
  }

  # Copy application files (if needed)
  # provisioner "file" {
  #   source      = "../../app"
  #   destination = "/tmp/app"
  # }

  # Setup application
  # provisioner "shell" {
  #   script = "../scripts/setup-application.sh"
  # }

  # Cleanup
  provisioner "shell" {
    script = "../scripts/cleanup.sh"
  }

  # Validate the build
  provisioner "shell" {
    inline = [
      "echo 'Validating Docker installation...'",
      "docker --version",
      "docker-compose --version",
      "echo 'Validating AWS CLI installation...'",
      "aws --version",
      "echo 'Build validation complete!'"
    ]
  }

  # Create manifest file
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      ami_name     = local.ami_name
      source_ami   = data.amazon-ami.ubuntu.id
      environment  = var.environment
      app_version  = var.app_version
      built_at     = local.timestamp
    }
  }
}
