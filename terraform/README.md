# Terraform Configuration - Multi-Cloud (AWS & Azure)

This directory contains Terraform configurations for managing infrastructure using Packer-built images on AWS and/or Azure.

## Structure

```
terraform/
├── versions.tf          # Terraform and provider version constraints
├── variables.tf         # Input variables (AWS & Azure)
├── main.tf             # Main configuration with multi-cloud support
├── outputs.tf          # Output values
├── modules/            # Reusable Terraform modules
└── environments/       # Environment-specific configurations
    ├── dev/
    ├── staging/
    └── prod/
```

## Prerequisites

### For AWS
1. Install Terraform: https://www.terraform.io/downloads
2. Configure AWS credentials:
   ```bash
   export AWS_ACCESS_KEY_ID="your_access_key"
   export AWS_SECRET_ACCESS_KEY="your_secret_key"
   ```
   Or use AWS CLI: `aws configure`

### For Azure
1. Install Terraform: https://www.terraform.io/downloads
2. Configure Azure credentials:
   ```bash
   export ARM_SUBSCRIPTION_ID="your_subscription_id"
   export ARM_CLIENT_ID="your_client_id"
   export ARM_CLIENT_SECRET="your_client_secret"
   export ARM_TENANT_ID="your_tenant_id"
   ```
   Or use Azure CLI: `az login`

## Usage

### Initialize Terraform

```bash
cd terraform
terraform init
```

### Plan Infrastructure Changes

```bash
# Plan for AWS only
terraform plan -var 'cloud_provider=aws'

# Plan for Azure only
terraform plan -var 'cloud_provider=azure'

# Plan for both clouds
terraform plan -var 'cloud_provider=multi'
```

### Apply Infrastructure Changes

```bash
# Deploy to AWS only
terraform apply -var 'cloud_provider=aws'

# Deploy to Azure only
terraform apply -var 'cloud_provider=azure'

# Deploy to both clouds
terraform apply -var 'cloud_provider=multi'
```

### Destroy Infrastructure

```bash
terraform destroy
```

## Using Packer Images

The configuration is set up to work with images created by Packer on both AWS and Azure.

### Option 1: Specify Image IDs

```bash
# For AWS
terraform apply \
  -var 'cloud_provider=aws' \
  -var 'packer_ami_id=ami-xxxxx'

# For Azure
terraform apply \
  -var 'cloud_provider=azure' \
  -var 'packer_azure_image_id=/subscriptions/.../images/...'

# For both
terraform apply \
  -var 'cloud_provider=multi' \
  -var 'packer_ami_id=ami-xxxxx' \
  -var 'packer_azure_image_id=/subscriptions/.../images/...'
```

### Option 2: Auto-fetch Latest Images

Uncomment the data source blocks in `main.tf` to automatically fetch the latest Packer-built images:

```hcl
# For AWS
data "aws_ami" "packer_image" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["packer-devops-aws-*"]
  }
}

# For Azure
data "azurerm_image" "packer_image" {
  name_regex          = "packer-devops-azure-.*"
  resource_group_name = var.azure_resource_group_name
  sort_descending     = true
}
```

## Environment-Specific Deployments

Create environment-specific variable files:

### Example: `environments/dev/terraform.tfvars`

```hcl
environment     = "dev"
cloud_provider  = "aws"
aws_region      = "us-east-1"
project_name    = "myapp"
```

### Example: `environments/prod/terraform.tfvars`

```hcl
environment     = "prod"
cloud_provider  = "multi"
aws_region      = "us-west-2"
azure_location  = "West US"
project_name    = "myapp"
```

Then deploy:

```bash
# Dev environment
terraform apply -var-file="environments/dev/terraform.tfvars"

# Production environment
terraform apply -var-file="environments/prod/terraform.tfvars"
```

## Variables

### Common Variables
- `environment`: Environment name (dev/staging/prod) - default: "dev"
- `project_name`: Project name for resource tagging - default: "devops-project"
- `cloud_provider`: Target cloud provider (aws/azure/multi) - default: "aws"

### AWS Variables
- `aws_region`: AWS region for deployment - default: "us-east-1"
- `packer_ami_id`: Specific AMI ID to use (optional) - default: ""

### Azure Variables
- `azure_subscription_id`: Azure subscription ID - default: ""
- `azure_location`: Azure region for deployment - default: "East US"
- `azure_resource_group_name`: Azure resource group name - default: "devops-rg"
- `packer_azure_image_id`: Specific Azure Image ID to use (optional) - default: ""

## Outputs

The configuration provides outputs for both AWS and Azure resources:

### AWS Outputs
- `aws_instance_id`: EC2 instance ID
- `aws_instance_public_ip`: Public IP address
- `aws_ami_id`: AMI ID used

### Azure Outputs
- `azure_vm_id`: Virtual machine ID
- `azure_vm_private_ip`: Private IP address
- `azure_image_id`: Image ID used
- `azure_resource_group_name`: Resource group name

View outputs:
```bash
terraform output
```

## Multi-Cloud Architecture

The configuration uses conditional resource creation based on the `cloud_provider` variable:

- **aws**: Creates only AWS resources
- **azure**: Creates only Azure resources
- **multi**: Creates resources in both clouds

Example resource with conditional creation:
```hcl
resource "aws_instance" "app_server" {
  count = var.cloud_provider == "aws" || var.cloud_provider == "multi" ? 1 : 0
  # ... resource configuration
}
```

## Best Practices

1. **Planning**: Always run `terraform plan` before `apply`
2. **State Management**: Use remote state storage for team collaboration
   - AWS: S3 + DynamoDB
   - Azure: Azure Storage Account
3. **Tagging**: Tag all resources with Environment, Project, and ManagedBy
4. **Environments**: Use workspaces or separate state files for different environments
5. **Secrets**: Never commit sensitive values; use environment variables or secret managers
6. **Modules**: Create reusable modules for common infrastructure patterns
7. **Version Control**: Use version constraints for providers and modules
8. **Documentation**: Keep README files updated with configuration changes

## Remote State Configuration

### AWS S3 Backend Example

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "devops/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

### Azure Storage Backend Example

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstate"
    container_name       = "tfstate"
    key                  = "devops.terraform.tfstate"
  }
}
```

## Common Commands

```bash
# Initialize and upgrade providers
terraform init -upgrade

# Format configuration files
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show

# List all resources
terraform state list

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0

# Refresh state
terraform refresh

# Create execution plan
terraform plan -out=tfplan

# Apply saved plan
terraform apply tfplan

# Target specific resource
terraform apply -target=aws_instance.app_server
```

## Troubleshooting

### Common Issues

1. **Provider Authentication Errors**
   - Verify credentials are set correctly
   - Check permissions for the service principal/user
   - Ensure subscription is active

2. **State Lock Errors**
   - Check if another operation is running
   - Manually unlock if needed: `terraform force-unlock <LOCK_ID>`

3. **Resource Already Exists**
   - Import the existing resource: `terraform import`
   - Or remove from state: `terraform state rm`

4. **Version Conflicts**
   - Update provider versions: `terraform init -upgrade`
   - Check compatibility matrix

### Getting Help

```bash
# Get help for a command
terraform plan -help

# View provider documentation
terraform providers

# Debug mode
TF_LOG=DEBUG terraform apply
```

## Integration with Packer

This Terraform configuration is designed to work seamlessly with the Packer templates in the `../packer` directory:

1. Build images with Packer:
   ```bash
   cd ../packer
   packer build templates/multi-cloud.pkr.hcl
   ```

2. Note the image IDs from the output or manifest files

3. Deploy infrastructure with Terraform:
   ```bash
   cd ../terraform
   terraform apply -var 'packer_ami_id=ami-xxxxx'
   ```

## Next Steps

1. Customize `main.tf` with your specific infrastructure requirements
2. Create environment-specific variable files
3. Set up remote state backend
4. Create reusable modules for common patterns
5. Integrate with CI/CD pipeline
6. Set up monitoring and alerting
