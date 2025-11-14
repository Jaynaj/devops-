# Main Terraform configuration
# This file can be used to deploy infrastructure using Packer-built images on AWS and/or Azure

# ============================================
# AWS Resources
# ============================================

# Data source to fetch the latest Packer-built AMI
# Uncomment and modify as needed
# data "aws_ami" "packer_image" {
#   count       = var.cloud_provider == "aws" || var.cloud_provider == "multi" ? 1 : 0
#   most_recent = true
#   owners      = ["self"]
#
#   filter {
#     name   = "name"
#     values = ["packer-${var.project_name}-aws-*"]
#   }
#
#   filter {
#     name   = "tag:Environment"
#     values = [var.environment]
#   }
#
#   filter {
#     name   = "tag:Cloud"
#     values = ["AWS"]
#   }
# }

# Example: EC2 instance using Packer AMI
# resource "aws_instance" "app_server" {
#   count         = var.cloud_provider == "aws" || var.cloud_provider == "multi" ? 1 : 0
#   ami           = var.packer_ami_id != "" ? var.packer_ami_id : data.aws_ami.packer_image[0].id
#   instance_type = "t3.micro"
#
#   tags = {
#     Name        = "${var.project_name}-${var.environment}-aws"
#     Environment = var.environment
#     ManagedBy   = "Terraform"
#     Cloud       = "AWS"
#   }
# }

# ============================================
# Azure Resources
# ============================================

# Data source to fetch the latest Packer-built Azure Image
# Uncomment and modify as needed
# data "azurerm_image" "packer_image" {
#   count               = var.cloud_provider == "azure" || var.cloud_provider == "multi" ? 1 : 0
#   name_regex          = "packer-${var.project_name}-azure-${var.environment}-.*"
#   resource_group_name = var.azure_resource_group_name
#   sort_descending     = true
# }

# Example: Azure resource group
# resource "azurerm_resource_group" "main" {
#   count    = var.cloud_provider == "azure" || var.cloud_provider == "multi" ? 1 : 0
#   name     = "${var.project_name}-${var.environment}-rg"
#   location = var.azure_location
#
#   tags = {
#     Environment = var.environment
#     ManagedBy   = "Terraform"
#     Cloud       = "Azure"
#   }
# }

# Example: Azure virtual network
# resource "azurerm_virtual_network" "main" {
#   count               = var.cloud_provider == "azure" || var.cloud_provider == "multi" ? 1 : 0
#   name                = "${var.project_name}-${var.environment}-vnet"
#   address_space       = ["10.0.0.0/16"]
#   location            = azurerm_resource_group.main[0].location
#   resource_group_name = azurerm_resource_group.main[0].name
#
#   tags = {
#     Environment = var.environment
#     ManagedBy   = "Terraform"
#     Cloud       = "Azure"
#   }
# }

# Example: Azure subnet
# resource "azurerm_subnet" "main" {
#   count                = var.cloud_provider == "azure" || var.cloud_provider == "multi" ? 1 : 0
#   name                 = "${var.project_name}-${var.environment}-subnet"
#   resource_group_name  = azurerm_resource_group.main[0].name
#   virtual_network_name = azurerm_virtual_network.main[0].name
#   address_prefixes     = ["10.0.1.0/24"]
# }

# Example: Azure network interface
# resource "azurerm_network_interface" "main" {
#   count               = var.cloud_provider == "azure" || var.cloud_provider == "multi" ? 1 : 0
#   name                = "${var.project_name}-${var.environment}-nic"
#   location            = azurerm_resource_group.main[0].location
#   resource_group_name = azurerm_resource_group.main[0].name
#
#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.main[0].id
#     private_ip_address_allocation = "Dynamic"
#   }
#
#   tags = {
#     Environment = var.environment
#     ManagedBy   = "Terraform"
#     Cloud       = "Azure"
#   }
# }

# Example: Azure VM using Packer Image
# resource "azurerm_linux_virtual_machine" "main" {
#   count               = var.cloud_provider == "azure" || var.cloud_provider == "multi" ? 1 : 0
#   name                = "${var.project_name}-${var.environment}-vm"
#   resource_group_name = azurerm_resource_group.main[0].name
#   location            = azurerm_resource_group.main[0].location
#   size                = "Standard_B2s"
#   admin_username      = "adminuser"
#
#   network_interface_ids = [
#     azurerm_network_interface.main[0].id,
#   ]
#
#   admin_ssh_key {
#     username   = "adminuser"
#     public_key = file("~/.ssh/id_rsa.pub")
#   }
#
#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
#
#   source_image_id = var.packer_azure_image_id != "" ? var.packer_azure_image_id : data.azurerm_image.packer_image[0].id
#
#   tags = {
#     Name        = "${var.project_name}-${var.environment}-azure"
#     Environment = var.environment
#     ManagedBy   = "Terraform"
#     Cloud       = "Azure"
#   }
# }
