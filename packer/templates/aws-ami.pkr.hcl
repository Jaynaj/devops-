# Packer template for building AWS AMI
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# Data source to get the latest Amazon Linux 2 AMI
data "amazon-ami" "base" {
  filters = {
    name                = var.source_ami_filter
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = [var.source_ami_owner]
  region      = var.aws_region
}

# Build configuration
source "amazon-ebs" "main" {
  ami_name      = "${var.image_name_prefix}-aws-${var.environment}-{{timestamp}}"
  instance_type = var.aws_instance_type
  region        = var.aws_region
  source_ami    = data.amazon-ami.base.id
  ssh_username  = var.aws_ssh_username

  tags = {
    Name        = "${var.image_name_prefix}-aws-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    BuildDate   = "{{timestamp}}"
    ManagedBy   = "Packer"
    Cloud       = "AWS"
  }

  run_tags = {
    Name      = "Packer Builder - ${var.project_name}"
    ManagedBy = "Packer"
  }
}

# Build steps
build {
  name = "aws-ami"
  sources = [
    "source.amazon-ebs.main"
  ]

  # Update system packages
  provisioner "shell" {
    inline = [
      "echo 'Updating system packages...'",
      "sudo yum update -y",
      "sudo yum install -y wget curl git"
    ]
  }

  # Run custom provisioning script
  provisioner "shell" {
    script = "../scripts/provision.sh"
  }

  # Copy files if needed
  # provisioner "file" {
  #   source      = "files/"
  #   destination = "/tmp/"
  # }

  # Final cleanup
  provisioner "shell" {
    inline = [
      "echo 'Cleaning up...'",
      "sudo yum clean all",
      "sudo rm -rf /tmp/*"
    ]
  }

  # Post-processor to manifest the AMI ID
  post-processor "manifest" {
    output     = "manifest-aws.json"
    strip_path = true
  }
}
