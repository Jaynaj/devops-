# Multi-cloud Packer template for building both AWS AMI and Azure Image
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
    azure = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

# AWS: Data source to get the latest Amazon Linux 2 AMI
data "amazon-ami" "aws_base" {
  filters = {
    name                = var.source_ami_filter
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = [var.source_ami_owner]
  region      = var.aws_region
}

# AWS Source Configuration
source "amazon-ebs" "aws" {
  ami_name      = "${var.image_name_prefix}-aws-${var.environment}-{{timestamp}}"
  instance_type = var.aws_instance_type
  region        = var.aws_region
  source_ami    = data.amazon-ami.aws_base.id
  ssh_username  = var.aws_ssh_username

  tags = {
    Name        = "${var.image_name_prefix}-aws-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    BuildDate   = "{{timestamp}}"
    ManagedBy   = "Packer"
    Cloud       = "AWS"
  }

  run_tags = {
    Name      = "Packer Builder - ${var.project_name}"
    ManagedBy = "Packer"
  }
}

# Azure Source Configuration
source "azure-arm" "azure" {
  # Authentication
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id

  # Resource group and location
  managed_image_resource_group_name = var.azure_resource_group
  location                          = var.azure_location

  # Image details
  managed_image_name = "${var.image_name_prefix}-azure-${var.environment}-{{timestamp}}"

  # Source image
  image_publisher = var.azure_image_publisher
  image_offer     = var.azure_image_offer
  image_sku       = var.azure_image_sku

  # VM configuration
  vm_size = var.azure_vm_size

  # OS disk
  os_type         = "Linux"
  os_disk_size_gb = 30

  # Tags
  azure_tags = {
    Name        = "${var.image_name_prefix}-azure-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    BuildDate   = "{{timestamp}}"
    ManagedBy   = "Packer"
    Cloud       = "Azure"
  }
}

# Build for AWS
build {
  name = "aws"
  sources = [
    "source.amazon-ebs.aws"
  ]

  # Update system packages (Amazon Linux)
  provisioner "shell" {
    inline = [
      "echo 'Updating system packages...'",
      "sudo yum update -y",
      "sudo yum install -y wget curl git"
    ]
  }

  # Run custom provisioning script
  provisioner "shell" {
    script = "../scripts/provision.sh"
  }

  # Final cleanup
  provisioner "shell" {
    inline = [
      "echo 'Cleaning up...'",
      "sudo yum clean all",
      "sudo rm -rf /tmp/*"
    ]
  }

  # Post-processor to manifest the AMI ID
  post-processor "manifest" {
    output     = "manifest-aws.json"
    strip_path = true
  }
}

# Build for Azure
build {
  name = "azure"
  sources = [
    "source.azure-arm.azure"
  ]

  # Update system packages (Ubuntu/Debian)
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait",
      "echo 'Updating system packages...'",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y wget curl git"
    ]
  }

  # Run custom provisioning script
  provisioner "shell" {
    script = "../scripts/provision-azure.sh"
  }

  # Final cleanup and deprovision
  provisioner "shell" {
    inline = [
      "echo 'Cleaning up...'",
      "sudo apt-get clean",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*"
    ]
  }

  # Azure deprovision
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline = [
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
    inline_shebang = "/bin/sh -x"
  }

  # Post-processor to manifest the Image ID
  post-processor "manifest" {
    output     = "manifest-azure.json"
    strip_path = true
  }
}
