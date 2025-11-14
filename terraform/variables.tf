# Common variables
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "devops-project"
}

variable "cloud_provider" {
  description = "Cloud provider to deploy to (aws, azure, or multi)"
  type        = string
  default     = "aws"
  validation {
    condition     = contains(["aws", "azure", "multi"], var.cloud_provider)
    error_message = "Cloud provider must be aws, azure, or multi."
  }
}

variable "os_type" {
  description = "Operating system type (linux, windows, or both)"
  type        = string
  default     = "linux"
  validation {
    condition     = contains(["linux", "windows", "both"], var.os_type)
    error_message = "OS type must be linux, windows, or both."
  }
}

# AWS variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "packer_ami_id" {
  description = "Linux AMI ID created by Packer"
  type        = string
  default     = ""
}

variable "packer_windows_ami_id" {
  description = "Windows AMI ID created by Packer"
  type        = string
  default     = ""
}

# Azure variables
variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
}

variable "azure_location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "azure_resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = "devops-rg"
}

variable "packer_azure_image_id" {
  description = "Linux Azure Image ID created by Packer"
  type        = string
  default     = ""
}

variable "packer_azure_windows_image_id" {
  description = "Windows Azure Image ID created by Packer"
  type        = string
  default     = ""
}
