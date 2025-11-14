# Terraform outputs

# ============================================
# AWS Outputs
# ============================================

# output "aws_instance_id" {
#   description = "ID of the AWS EC2 instance"
#   value       = var.cloud_provider == "aws" || var.cloud_provider == "multi" ? aws_instance.app_server[0].id : null
# }
#
# output "aws_instance_public_ip" {
#   description = "Public IP of the AWS EC2 instance"
#   value       = var.cloud_provider == "aws" || var.cloud_provider == "multi" ? aws_instance.app_server[0].public_ip : null
# }
#
# output "aws_ami_id" {
#   description = "AMI ID used for the AWS instance"
#   value       = var.cloud_provider == "aws" || var.cloud_provider == "multi" ? (var.packer_ami_id != "" ? var.packer_ami_id : data.aws_ami.packer_image[0].id) : null
# }

# ============================================
# Azure Outputs
# ============================================

# output "azure_vm_id" {
#   description = "ID of the Azure VM"
#   value       = var.cloud_provider == "azure" || var.cloud_provider == "multi" ? azurerm_linux_virtual_machine.main[0].id : null
# }
#
# output "azure_vm_private_ip" {
#   description = "Private IP of the Azure VM"
#   value       = var.cloud_provider == "azure" || var.cloud_provider == "multi" ? azurerm_network_interface.main[0].private_ip_address : null
# }
#
# output "azure_image_id" {
#   description = "Azure Image ID used for the VM"
#   value       = var.cloud_provider == "azure" || var.cloud_provider == "multi" ? (var.packer_azure_image_id != "" ? var.packer_azure_image_id : data.azurerm_image.packer_image[0].id) : null
# }
#
# output "azure_resource_group_name" {
#   description = "Name of the Azure resource group"
#   value       = var.cloud_provider == "azure" || var.cloud_provider == "multi" ? azurerm_resource_group.main[0].name : null
# }
