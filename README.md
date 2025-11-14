# DevOps Infrastructure - Multi-Cloud with Terraform & Packer

A comprehensive Infrastructure as Code (IaC) solution for building and deploying **Linux and Windows** machine images across **AWS** and **Azure** using HashiCorp Packer and Terraform.

## Overview

This repository provides a complete multi-cloud infrastructure setup that enables you to:

1. **Build machine images** with Packer for both AWS (AMIs) and Azure (Managed Images)
2. **Support both Linux and Windows** operating systems
3. **Deploy infrastructure** with Terraform using those custom-built images
4. **Manage multi-cloud environments** with a unified workflow

## Repository Structure

```
.
├── packer/                      # Packer configurations for image building
│   ├── variables.pkr.hcl       # Variable definitions (AWS & Azure, Linux & Windows)
│   ├── templates/              # Packer templates
│   │   ├── aws-ami.pkr.hcl            # AWS Linux AMI template
│   │   ├── aws-windows-ami.pkr.hcl    # AWS Windows AMI template
│   │   ├── azure-image.pkr.hcl        # Azure Linux image template
│   │   ├── azure-windows-image.pkr.hcl# Azure Windows image template
│   │   ├── multi-cloud.pkr.hcl        # Linux multi-cloud template
│   │   └── multi-cloud-all.pkr.hcl    # All OS + All Cloud template
│   ├── scripts/                # Provisioning scripts
│   │   ├── provision.sh                # AWS Linux (Amazon Linux 2)
│   │   ├── provision-azure.sh          # Azure Linux (Ubuntu 22.04)
│   │   ├── provision-windows.ps1       # AWS Windows Server 2022
│   │   ├── provision-windows-azure.ps1 # Azure Windows Server 2022
│   │   └── enable-winrm.ps1            # WinRM enablement for Windows
│   └── README.md               # Detailed Packer documentation
│
├── terraform/                   # Terraform configurations
│   ├── versions.tf             # Provider version constraints
│   ├── variables.tf            # Input variables (AWS & Azure)
│   ├── main.tf                 # Main infrastructure configuration
│   ├── outputs.tf              # Output definitions
│   ├── modules/                # Reusable Terraform modules
│   ├── environments/           # Environment-specific configs
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── README.md               # Detailed Terraform documentation
│
└── README.md                    # This file
```

## Quick Start

### Prerequisites

1. **Install required tools:**
   - [Packer](https://www.packer.io/downloads) (>= 1.8.0)
   - [Terraform](https://www.terraform.io/downloads) (>= 1.0)

2. **Configure cloud credentials:**

   **For AWS:**
   ```bash
   export AWS_ACCESS_KEY_ID="your_access_key"
   export AWS_SECRET_ACCESS_KEY="your_secret_key"
   # Or use: aws configure
   ```

   **For Azure:**
   ```bash
   export ARM_SUBSCRIPTION_ID="your_subscription_id"
   export ARM_CLIENT_ID="your_client_id"
   export ARM_CLIENT_SECRET="your_client_secret"
   export ARM_TENANT_ID="your_tenant_id"
   # Or use: az login
   ```

### Step 1: Build Images with Packer

```bash
cd packer

# Initialize Packer plugins
packer init templates/multi-cloud.pkr.hcl

# Build all images (AWS+Azure, Linux+Windows)
packer build templates/multi-cloud-all.pkr.hcl

# Or build for specific combinations:
packer build templates/aws-ami.pkr.hcl              # AWS Linux only
packer build templates/aws-windows-ami.pkr.hcl      # AWS Windows only
packer build templates/azure-image.pkr.hcl          # Azure Linux only
packer build templates/azure-windows-image.pkr.hcl  # Azure Windows only

# Or use filters with multi-cloud-all template:
packer build -only='*-linux' templates/multi-cloud-all.pkr.hcl    # All Linux
packer build -only='*-windows' templates/multi-cloud-all.pkr.hcl  # All Windows
packer build -only='aws-*' templates/multi-cloud-all.pkr.hcl      # All AWS
```

### Step 2: Deploy Infrastructure with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Deploy to AWS (Linux)
terraform apply -var 'cloud_provider=aws' -var 'os_type=linux'

# Deploy to Azure (Windows)
terraform apply -var 'cloud_provider=azure' -var 'os_type=windows'

# Deploy to both clouds with both OS types
terraform apply -var 'cloud_provider=multi' -var 'os_type=both'
```

## Detailed Documentation

- **[Packer Documentation](packer/README.md)** - Image building, variables, and provisioning
- **[Terraform Documentation](terraform/README.md)** - Infrastructure deployment and configuration

## Features

### Multi-Cloud Support
- **AWS**: Amazon Linux 2 and Windows Server 2022 AMIs
- **Azure**: Ubuntu 22.04 and Windows Server 2022 Managed Images
- **Flexible deployment**: Choose AWS, Azure, or both
- **OS flexibility**: Build Linux, Windows, or both

| Cloud | Linux OS        | Windows OS           |
|-------|-----------------|----------------------|
| AWS   | Amazon Linux 2  | Windows Server 2022  |
| Azure | Ubuntu 22.04    | Windows Server 2022  |

### Image Building (Packer)
- Separate templates for each cloud platform
- Multi-cloud template for simultaneous builds
- Cloud-specific provisioning scripts
- Automated tagging and versioning
- Manifest files for tracking builds

### Infrastructure Deployment (Terraform)
- Conditional resource creation based on cloud provider
- Environment-specific configurations (dev/staging/prod)
- Auto-discovery of latest Packer-built images
- Comprehensive outputs for both platforms
- Support for remote state backends

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    1. Build Images (Packer)                  │
│  ┌──────────────────────┐      ┌──────────────────────┐    │
│  │   AWS AMI            │      │   Azure Image         │    │
│  │   (Amazon Linux 2)   │      │   (Ubuntu 22.04)      │    │
│  └──────────────────────┘      └──────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              2. Deploy Infrastructure (Terraform)            │
│  ┌──────────────────────┐      ┌──────────────────────┐    │
│  │   AWS Resources      │      │   Azure Resources     │    │
│  │   - EC2 Instances    │      │   - Virtual Machines  │    │
│  │   - VPC/Subnets      │      │   - VNet/Subnets      │    │
│  │   - Security Groups  │      │   - NSGs              │    │
│  └──────────────────────┘      └──────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Use Cases

1. **Multi-Cloud Strategy**: Deploy applications across AWS and Azure for redundancy
2. **Cloud Migration**: Build consistent images for migrating between clouds
3. **Disaster Recovery**: Maintain infrastructure in multiple clouds
4. **Development Environments**: Test applications across different cloud platforms
5. **CI/CD Integration**: Automate image builds and deployments

## Configuration Examples

### Build Production Images

```bash
cd packer
packer build \
  -var 'environment=prod' \
  -var 'aws_region=us-west-2' \
  -var 'azure_location=West US' \
  templates/multi-cloud.pkr.hcl
```

### Deploy Multi-Cloud Production Infrastructure

```bash
cd terraform
terraform apply \
  -var 'cloud_provider=multi' \
  -var 'environment=prod' \
  -var 'aws_region=us-west-2' \
  -var 'azure_location=West US'
```

### Environment-Specific Deployment

```bash
# Create terraform/environments/prod/terraform.tfvars
cat > terraform/environments/prod/terraform.tfvars <<EOF
environment    = "prod"
cloud_provider = "multi"
aws_region     = "us-west-2"
azure_location = "West US"
project_name   = "myapp"
EOF

# Deploy
cd terraform
terraform apply -var-file="environments/prod/terraform.tfvars"
```

## Best Practices

1. **Version Control**: All configuration files are version-controlled
2. **Secrets Management**: Use environment variables for credentials
3. **Tagging**: Resources are tagged with Environment, Project, and ManagedBy
4. **State Management**: Use remote backends (S3/Azure Storage) for Terraform state
5. **Image Versioning**: Packer images include timestamps and environment tags
6. **Testing**: Test images in dev/staging before production deployment
7. **Automation**: Integrate with CI/CD pipelines for automated builds

## Security Considerations

- Never commit credentials or secrets to version control
- Use IAM roles/service principals with least privilege
- Enable encryption for state files and storage
- Regularly update base images for security patches
- Use private networks and security groups/NSGs
- Implement proper access controls and audit logging

## Troubleshooting

### Packer Issues
```bash
# Validate template
packer validate templates/multi-cloud.pkr.hcl

# Enable debug logging
PACKER_LOG=1 packer build templates/aws-ami.pkr.hcl
```

### Terraform Issues
```bash
# Validate configuration
terraform validate

# Enable debug logging
TF_LOG=DEBUG terraform apply

# Check state
terraform show
terraform state list
```

## Contributing

1. Create feature branches for changes
2. Test in development environment first
3. Update documentation for new features
4. Follow existing code style and conventions

## Resources

- [Packer Documentation](https://www.packer.io/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## License

This project is available for use under your organization's policies.

## Support

For detailed usage instructions, refer to:
- [Packer README](packer/README.md)
- [Terraform README](terraform/README.md)
