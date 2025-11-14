# Packer Configuration - Multi-Cloud (AWS & Azure)

This directory contains Packer templates for building machine images on both AWS and Azure that can be used with Terraform.

## Structure

```
packer/
├── variables.pkr.hcl           # Variable definitions (AWS & Azure)
├── templates/                  # Packer templates
│   ├── aws-ami.pkr.hcl        # AWS AMI build template
│   ├── azure-image.pkr.hcl    # Azure Managed Image template
│   └── multi-cloud.pkr.hcl    # Build for both AWS and Azure
└── scripts/                    # Provisioning scripts
    ├── provision.sh           # AWS provisioning script
    └── provision-azure.sh     # Azure provisioning script
```

## Prerequisites

### For AWS
1. Install Packer: https://www.packer.io/downloads
2. Configure AWS credentials:
   ```bash
   export AWS_ACCESS_KEY_ID="your_access_key"
   export AWS_SECRET_ACCESS_KEY="your_secret_key"
   ```
   Or use AWS CLI: `aws configure`

### For Azure
1. Install Packer: https://www.packer.io/downloads
2. Configure Azure credentials:
   ```bash
   export ARM_SUBSCRIPTION_ID="your_subscription_id"
   export ARM_CLIENT_ID="your_client_id"
   export ARM_CLIENT_SECRET="your_client_secret"
   export ARM_TENANT_ID="your_tenant_id"
   ```
3. Create a resource group for Packer images:
   ```bash
   az group create --name packer-rg --location "East US"
   ```

## Usage

### Initialize Packer

```bash
cd packer

# For AWS only
packer init templates/aws-ami.pkr.hcl

# For Azure only
packer init templates/azure-image.pkr.hcl

# For multi-cloud
packer init templates/multi-cloud.pkr.hcl
```

### Validate Templates

```bash
# Validate AWS template
packer validate templates/aws-ami.pkr.hcl

# Validate Azure template
packer validate templates/azure-image.pkr.hcl

# Validate multi-cloud template
packer validate templates/multi-cloud.pkr.hcl
```

### Build Images

#### AWS AMI Only
```bash
# Build with default variables
packer build templates/aws-ami.pkr.hcl

# Build with custom variables
packer build -var 'environment=prod' -var 'aws_region=us-west-2' templates/aws-ami.pkr.hcl
```

#### Azure Image Only
```bash
# Build with default variables
packer build templates/azure-image.pkr.hcl

# Build with custom variables
packer build -var 'environment=prod' -var 'azure_location=West US' templates/azure-image.pkr.hcl
```

#### Multi-Cloud (Build Both)
```bash
# Build images for both AWS and Azure
packer build templates/multi-cloud.pkr.hcl

# Build only AWS from multi-cloud template
packer build -only='aws.*' templates/multi-cloud.pkr.hcl

# Build only Azure from multi-cloud template
packer build -only='azure.*' templates/multi-cloud.pkr.hcl

# Build with custom variables for both clouds
packer build \
  -var 'environment=prod' \
  -var 'aws_region=us-west-2' \
  -var 'azure_location=West US' \
  templates/multi-cloud.pkr.hcl
```

### Format Packer Files

```bash
packer fmt .
```

## Variables

### Common Variables
- `environment`: Environment tag (default: dev)
- `project_name`: Project name for tagging (default: devops-project)
- `image_name_prefix`: Prefix for image name (default: packer-devops)

### AWS-Specific Variables
- `aws_region`: AWS region to build the AMI (default: us-east-1)
- `aws_instance_type`: EC2 instance type for building (default: t3.micro)
- `source_ami_owner`: AMI owner (default: amazon)
- `source_ami_filter`: Filter for base AMI (default: Amazon Linux 2)
- `aws_ssh_username`: SSH username for provisioning (default: ec2-user)

### Azure-Specific Variables
- `azure_location`: Azure region to build the image (default: East US)
- `azure_vm_size`: VM size for building (default: Standard_B2s)
- `azure_resource_group`: Resource group for images (default: packer-rg)
- `azure_subscription_id`: Azure subscription ID (from ARM_SUBSCRIPTION_ID env var)
- `azure_client_id`: Azure client ID (from ARM_CLIENT_ID env var)
- `azure_client_secret`: Azure client secret (from ARM_CLIENT_SECRET env var)
- `azure_tenant_id`: Azure tenant ID (from ARM_TENANT_ID env var)
- `azure_image_publisher`: Base image publisher (default: Canonical)
- `azure_image_offer`: Base image offer (default: Ubuntu 22.04)
- `azure_image_sku`: Base image SKU (default: 22_04-lts-gen2)
- `azure_ssh_username`: SSH username for provisioning (default: packer)

### Variable Override Methods

1. **Command line**:
   ```bash
   packer build -var 'aws_instance_type=t3.small' templates/aws-ami.pkr.hcl
   ```

2. **Variable file** (`*.pkrvars.hcl`):
   ```hcl
   environment     = "prod"
   aws_region      = "us-west-2"
   azure_location  = "West US"
   ```

3. **Environment variables**:
   ```bash
   export PKR_VAR_aws_region="us-west-2"
   export PKR_VAR_environment="prod"
   ```

## Provisioning

### AWS Provisioning
The `scripts/provision.sh` script handles:
- System updates (yum-based for Amazon Linux)
- Package installation
- Security hardening
- Application setup

### Azure Provisioning
The `scripts/provision-azure.sh` script handles:
- System updates (apt-based for Ubuntu)
- Package installation
- Security hardening
- Azure-specific configuration
- Automatic security updates

Modify these scripts to customize your images.

## Integration with Terraform

### After Building Images

The build process creates manifest files:
- `manifest-aws.json` - Contains AWS AMI details
- `manifest-azure.json` - Contains Azure Image details

### Using with Terraform

1. **Using specific image IDs**:
   ```bash
   cd ../terraform

   # For AWS
   terraform apply -var 'packer_ami_id=ami-xxxxx' -var 'cloud_provider=aws'

   # For Azure
   terraform apply -var 'packer_azure_image_id=/subscriptions/.../...' -var 'cloud_provider=azure'

   # For both
   terraform apply -var 'cloud_provider=multi'
   ```

2. **Auto-fetch latest images**: Configure Terraform to automatically fetch the latest Packer-built images using data sources (see terraform/main.tf for examples).

## Output Manifests

After each build, Packer creates a manifest file with image details:

- **AWS**: `manifest-aws.json` contains AMI ID and metadata
- **Azure**: `manifest-azure.json` contains Image ID and metadata

Example manifest structure:
```json
{
  "builds": [
    {
      "artifact_id": "ami-xxxxx or /subscriptions/...",
      "packer_run_uuid": "...",
      "custom_data": {...}
    }
  ]
}
```

## Best Practices

1. Use version control for all Packer configurations
2. Tag images appropriately with environment, version, and build date
3. Test images in non-production environments first
4. Automate image builds in CI/CD pipeline
5. Regularly update base images and rebuild
6. Clean up old images to reduce costs
7. Use Packer's `manifest` post-processor to track built images
8. Use separate templates for development vs. production
9. Store sensitive credentials in environment variables, not in code
10. Consider using cloud-native image galleries (AWS AMI Catalog, Azure Shared Image Gallery)

## Troubleshooting

### AWS Issues
- Ensure AWS credentials are valid and have necessary permissions
- Check that the region is correct and available
- Verify the source AMI exists in the specified region

### Azure Issues
- Ensure Azure credentials are valid with required permissions
- Verify the resource group exists before building
- Check that the Azure subscription is active
- Ensure the VM size is available in the chosen region

### General Issues
- Run `packer validate` before building
- Check Packer logs for detailed error messages
- Ensure network connectivity to cloud provider APIs
