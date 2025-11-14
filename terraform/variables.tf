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

# AWS variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "packer_ami_id" {
  description = "AMI ID created by Packer"
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
  description = "Azure Image ID created by Packer"
  type        = string
  default     = ""
}
