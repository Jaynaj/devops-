terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Terraform Cloud backend configuration
  # This will be configured via CLI parameters in GitHub Actions
  cloud {
    organization = "my-org"  # Will be overridden by workflow

    workspaces {
      name = "myapp-dev"  # Will be overridden by workflow
    }
  }
}

# AWS Provider configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
      Repository  = "github.com/${var.github_org}/${var.github_repo}"
    }
  }
}

# Azure Provider configuration
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
