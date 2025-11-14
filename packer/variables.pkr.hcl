# Packer variables file

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
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

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

variable "ami_name_prefix" {
  type    = string
  default = "packer-devops"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "devops-project"
}
