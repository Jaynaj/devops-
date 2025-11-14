# Packer template for building Azure Managed Image
packer {
  required_plugins {
    azure = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

# Build configuration for Azure
source "azure-arm" "main" {
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

# Build steps
build {
  name = "azure-image"
  sources = [
    "source.azure-arm.main"
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

  # Copy files if needed
  # provisioner "file" {
  #   source      = "files/"
  #   destination = "/tmp/"
  # }

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
