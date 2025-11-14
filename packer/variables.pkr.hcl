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
