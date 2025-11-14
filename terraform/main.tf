# Main Terraform configuration
# This file can be used to deploy infrastructure using Packer-built AMIs

# Example: Data source to fetch the latest Packer-built AMI
# Uncomment and modify as needed
# data "aws_ami" "packer_image" {
#   most_recent = true
#   owners      = ["self"]
#
#   filter {
#     name   = "name"
#     values = ["packer-${var.project_name}-*"]
#   }
#
#   filter {
#     name   = "tag:Environment"
#     values = [var.environment]
#   }
# }

# Example: EC2 instance using Packer AMI
# resource "aws_instance" "app_server" {
#   ami           = var.packer_ami_id != "" ? var.packer_ami_id : data.aws_ami.packer_image.id
#   instance_type = "t3.micro"
#
#   tags = {
#     Name        = "${var.project_name}-${var.environment}"
#     Environment = var.environment
#     ManagedBy   = "Terraform"
#   }
# }
