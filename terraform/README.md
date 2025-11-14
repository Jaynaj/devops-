# Terraform Configuration

This directory contains Terraform configurations for managing infrastructure that uses Packer-built AMIs.

## Structure

```
terraform/
├── versions.tf          # Terraform and provider version constraints
├── variables.tf         # Input variables
├── main.tf             # Main configuration
├── outputs.tf          # Output values
├── modules/            # Reusable Terraform modules
└── environments/       # Environment-specific configurations
    ├── dev/
    ├── staging/
    └── prod/
```

## Usage

### Initialize Terraform

```bash
cd terraform
terraform init
```

### Plan Infrastructure Changes

```bash
terraform plan
```

### Apply Infrastructure Changes

```bash
terraform apply
```

### Using Packer AMIs

The configuration is set up to work with AMIs created by Packer. You can:

1. Use a specific AMI ID by setting the `packer_ami_id` variable
2. Automatically fetch the latest Packer-built AMI using data sources

### Environment-Specific Deployments

Create environment-specific variable files:

```bash
# Dev environment
terraform apply -var-file="environments/dev/terraform.tfvars"

# Production environment
terraform apply -var-file="environments/prod/terraform.tfvars"
```

## Variables

- `aws_region`: AWS region for deployment (default: us-east-1)
- `environment`: Environment name (dev/staging/prod)
- `project_name`: Project name for resource tagging
- `packer_ami_id`: Specific AMI ID to use (optional)

## Best Practices

1. Always run `terraform plan` before `apply`
2. Use remote state storage (S3 + DynamoDB) for team collaboration
3. Tag all resources appropriately
4. Use workspaces or separate state files for different environments
