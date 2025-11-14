# Packer configuration for building Azure VM Image
packer {
  required_plugins {
    azure = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

# Variables
variable "client_id" {
  type    = string
  default = env("ARM_CLIENT_ID")
}

variable "client_secret" {
  type      = string
  default   = env("ARM_CLIENT_SECRET")
  sensitive = true
}

variable "subscription_id" {
  type    = string
  default = env("ARM_SUBSCRIPTION_ID")
}

variable "tenant_id" {
  type    = string
  default = env("ARM_TENANT_ID")
}

variable "resource_group_name" {
  type    = string
  default = "packer-images-rg"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "image_name_prefix" {
  type    = string
  default = "myapp"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "app_version" {
  type    = string
  default = "1.0.0"
}

variable "managed_image_name" {
  type    = string
  default = ""
}

variable "shared_image_gallery_name" {
  type    = string
  default = ""
}

# Local variables
locals {
  timestamp          = regex_replace(timestamp(), "[- TZ:]", "")
  image_name         = var.managed_image_name != "" ? var.managed_image_name : "${var.image_name_prefix}-${var.environment}-${local.timestamp}"
  use_azure_cli_auth = var.client_id == "" ? true : false
}

# Source configuration
source "azure-arm" "app" {
  # Authentication
  use_azure_cli_auth = local.use_azure_cli_auth
  client_id          = var.client_id
  client_secret      = var.client_secret
  subscription_id    = var.subscription_id
  tenant_id          = var.tenant_id

  # Resource Group
  managed_image_resource_group_name = var.resource_group_name
  managed_image_name                = local.image_name

  # Base image
  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts-gen2"
  image_version   = "latest"

  # VM Configuration
  location = var.location
  vm_size  = var.vm_size

  # Disk configuration
  os_disk_size_gb = 30
  disk_caching_type = "ReadWrite"

  # Network configuration
  private_virtual_network_with_public_ip = false
  virtual_network_name                    = "packer-vnet"
  virtual_network_subnet_name             = "packer-subnet"
  virtual_network_resource_group_name     = var.resource_group_name

  # Tags
  azure_tags = {
    Name        = local.image_name
    Environment = var.environment
    OS          = "Ubuntu"
    OS_Version  = "22.04"
    AppVersion  = var.app_version
    CreatedBy   = "Packer"
    BuildTime   = local.timestamp
  }

  # Shared Image Gallery (optional)
  # shared_image_gallery_destination {
  #   subscription         = var.subscription_id
  #   resource_group       = var.resource_group_name
  #   gallery_name         = var.shared_image_gallery_name
  #   image_name           = var.image_name_prefix
  #   image_version        = var.app_version
  #   replication_regions  = [var.location]
  #   storage_account_type = "Standard_LRS"
  # }
}

# Build configuration
build {
  name    = "azure-image-build"
  sources = ["source.azure-arm.app"]

  # Wait for cloud-init to complete
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait || true",
      "sleep 10"
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

  # Install Azure CLI
  provisioner "shell" {
    script = "../scripts/install-azure-tools.sh"
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

  # Azure-specific configurations
  provisioner "shell" {
    inline = [
      "echo 'Configuring Azure VM...'",
      "sudo waagent -force -deprovision+user",
      "sudo rm -f /etc/resolv.conf",
      "sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf"
    ]
  }

  # Cleanup
  provisioner "shell" {
    script = "../scripts/cleanup.sh"
  }

  # Generalize the VM (Azure-specific)
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E bash '{{ .Path }}'"
    inline = [
      "sudo /usr/sbin/waagent -force -deprovision+user",
      "export HISTSIZE=0",
      "sync"
    ]
    inline_shebang = "/bin/bash -x"
  }

  # Create manifest file
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      image_name   = local.image_name
      environment  = var.environment
      app_version  = var.app_version
      built_at     = local.timestamp
    }
  }
}
