variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

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

variable "packer_ami_id" {
  description = "AMI ID created by Packer"
  type        = string
  default     = ""
}
