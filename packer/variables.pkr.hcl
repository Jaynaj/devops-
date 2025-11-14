# Packer variables file - Multi-cloud (AWS & Azure)

# Common variables
variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "devops-project"
}

variable "image_name_prefix" {
  type    = string
  default = "packer-devops"
}

# AWS-specific variables
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "source_ami_owner" {
  type    = string
  default = "amazon"
}

variable "source_ami_filter" {
  type    = string
  default = "amzn2-ami-hvm-*-x86_64-gp2"
}

variable "aws_ssh_username" {
  type    = string
  default = "ec2-user"
}

# AWS Windows-specific variables
variable "aws_windows_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "source_windows_ami_owner" {
  type    = string
  default = "amazon"
}

variable "source_windows_ami_filter" {
  type    = string
  default = "Windows_Server-2022-English-Full-Base-*"
}

variable "aws_winrm_username" {
  type    = string
  default = "Administrator"
}

# Azure-specific variables
variable "azure_location" {
  type    = string
  default = "East US"
}

variable "azure_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "azure_resource_group" {
  type    = string
  default = "packer-rg"
}

variable "azure_subscription_id" {
  type    = string
  default = env("ARM_SUBSCRIPTION_ID")
}

variable "azure_client_id" {
  type    = string
  default = env("ARM_CLIENT_ID")
}

variable "azure_client_secret" {
  type    = string
  default = env("ARM_CLIENT_SECRET")
  sensitive = true
}

variable "azure_tenant_id" {
  type    = string
  default = env("ARM_TENANT_ID")
}

variable "azure_image_publisher" {
  type    = string
  default = "Canonical"
}

variable "azure_image_offer" {
  type    = string
  default = "0001-com-ubuntu-server-jammy"
}

variable "azure_image_sku" {
  type    = string
  default = "22_04-lts-gen2"
}

variable "azure_ssh_username" {
  type    = string
  default = "packer"
}

# Azure Windows-specific variables
variable "azure_windows_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "azure_windows_image_publisher" {
  type    = string
  default = "MicrosoftWindowsServer"
}

variable "azure_windows_image_offer" {
  type    = string
  default = "WindowsServer"
}

variable "azure_windows_image_sku" {
  type    = string
  default = "2022-Datacenter"
}

variable "azure_winrm_username" {
  type    = string
  default = "packer"
}
