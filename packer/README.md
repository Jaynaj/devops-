# Packer Configuration - Multi-Cloud with Windows & Linux Support

This directory contains Packer templates for building machine images on both AWS and Azure for **Linux and Windows** operating systems.

## Structure

```
packer/
├── variables.pkr.hcl                # Variable definitions (AWS & Azure, Linux & Windows)
├── templates/                       # Packer templates
│   ├── aws-ami.pkr.hcl             # AWS Linux AMI template
│   ├── aws-windows-ami.pkr.hcl     # AWS Windows AMI template
│   ├── azure-image.pkr.hcl         # Azure Linux Managed Image template
│   ├── azure-windows-image.pkr.hcl # Azure Windows Managed Image template
│   ├── multi-cloud.pkr.hcl         # Linux-only multi-cloud template
│   └── multi-cloud-all.pkr.hcl     # All OS + All Cloud template
└── scripts/                         # Provisioning scripts
    ├── provision.sh                # AWS Linux provisioning (Amazon Linux)
    ├── provision-azure.sh          # Azure Linux provisioning (Ubuntu)
    ├── provision-windows.ps1       # AWS Windows provisioning
    ├── provision-windows-azure.ps1 # Azure Windows provisioning
    └── enable-winrm.ps1            # WinRM enablement for Windows builds
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

## Supported OS Combinations

| Cloud | OS      | Base Image           | Template File                |
|-------|---------|----------------------|------------------------------|
| AWS   | Linux   | Amazon Linux 2       | aws-ami.pkr.hcl             |
| AWS   | Windows | Windows Server 2022  | aws-windows-ami.pkr.hcl     |
| Azure | Linux   | Ubuntu 22.04 LTS     | azure-image.pkr.hcl         |
| Azure | Windows | Windows Server 2022  | azure-windows-image.pkr.hcl |

## Usage

### Initialize Packer

```bash
cd packer

# For specific template
packer init templates/aws-ami.pkr.hcl

# For comprehensive multi-cloud template
packer init templates/multi-cloud-all.pkr.hcl
```

### Validate Templates

```bash
packer validate templates/aws-ami.pkr.hcl
packer validate templates/aws-windows-ami.pkr.hcl
packer validate templates/multi-cloud-all.pkr.hcl
```

### Build Images

#### Individual Cloud/OS Combinations

```bash
# AWS Linux only
packer build templates/aws-ami.pkr.hcl

# AWS Windows only
packer build templates/aws-windows-ami.pkr.hcl

# Azure Linux only
packer build templates/azure-image.pkr.hcl

# Azure Windows only
packer build templates/azure-windows-image.pkr.hcl
```

#### Using Comprehensive Multi-Cloud Template

```bash
# Build all images (AWS Linux, AWS Windows, Azure Linux, Azure Windows)
packer build templates/multi-cloud-all.pkr.hcl

# Build only AWS images (both Linux and Windows)
packer build -only='aws-*' templates/multi-cloud-all.pkr.hcl

# Build only Azure images (both Linux and Windows)
packer build -only='azure-*' templates/multi-cloud-all.pkr.hcl

# Build only Linux images (both AWS and Azure)
packer build -only='*-linux' templates/multi-cloud-all.pkr.hcl

# Build only Windows images (both AWS and Azure)
packer build -only='*-windows' templates/multi-cloud-all.pkr.hcl

# Build specific combination
packer build -only='aws-linux' templates/multi-cloud-all.pkr.hcl
packer build -only='azure-windows' templates/multi-cloud-all.pkr.hcl
```

#### Custom Variables

```bash
packer build \
  -var 'environment=prod' \
  -var 'aws_region=us-west-2' \
  -var 'azure_location=West US' \
  templates/multi-cloud-all.pkr.hcl
```

## Variables

### Common Variables
- `environment`: Environment tag (default: dev)
- `project_name`: Project name for tagging (default: devops-project)
- `image_name_prefix`: Prefix for image name (default: packer-devops)

### AWS Linux Variables
- `aws_region`: AWS region (default: us-east-1)
- `aws_instance_type`: EC2 instance type (default: t3.micro)
- `source_ami_owner`: AMI owner (default: amazon)
- `source_ami_filter`: Filter for base AMI (default: Amazon Linux 2)
- `aws_ssh_username`: SSH username (default: ec2-user)

### AWS Windows Variables
- `aws_windows_instance_type`: EC2 instance type (default: t3.medium)
- `source_windows_ami_owner`: AMI owner (default: amazon)
- `source_windows_ami_filter`: Filter for base AMI (default: Windows Server 2022)
- `aws_winrm_username`: WinRM username (default: Administrator)

### Azure Linux Variables
- `azure_location`: Azure region (default: East US)
- `azure_vm_size`: VM size (default: Standard_B2s)
- `azure_resource_group`: Resource group (default: packer-rg)
- `azure_image_publisher`: Base image publisher (default: Canonical)
- `azure_image_offer`: Base image offer (default: Ubuntu 22.04)
- `azure_image_sku`: Base image SKU (default: 22_04-lts-gen2)
- `azure_ssh_username`: SSH username (default: packer)

### Azure Windows Variables
- `azure_windows_vm_size`: VM size (default: Standard_D2s_v3)
- `azure_windows_image_publisher`: Base image publisher (default: MicrosoftWindowsServer)
- `azure_windows_image_offer`: Base image offer (default: WindowsServer)
- `azure_windows_image_sku`: Base image SKU (default: 2022-Datacenter)
- `azure_winrm_username`: WinRM username (default: packer)

### Azure Authentication (from environment variables)
- `azure_subscription_id`: From ARM_SUBSCRIPTION_ID
- `azure_client_id`: From ARM_CLIENT_ID
- `azure_client_secret`: From ARM_CLIENT_SECRET
- `azure_tenant_id`: From ARM_TENANT_ID

## Provisioning

### Linux Provisioning

**AWS (Amazon Linux 2):**
- System updates via `yum`
- Package installation (wget, curl, git)
- Custom provisioning script: `scripts/provision.sh`

**Azure (Ubuntu 22.04):**
- System updates via `apt`
- Package installation (wget, curl, git)
- Azure-specific configuration
- Automatic security updates
- Custom provisioning script: `scripts/provision-azure.sh`

### Windows Provisioning

**Both AWS and Azure Windows Server 2022:**
- Windows Updates via PSWindowsUpdate module
- Chocolatey package manager installation
- Common packages (git, 7zip, curl)
- PowerShell module installation (Az, AWSPowerShell)
- Security hardening
- Timezone configuration (UTC)
- IE Enhanced Security Configuration disabled
- Custom provisioning scripts:
  - AWS: `scripts/provision-windows.ps1`
  - Azure: `scripts/provision-windows-azure.ps1`

**Windows-Specific Notes:**
- WinRM is used for communication (enabled via `enable-winrm.ps1`)
- Sysprep is automatically run for image generalization
- Build times are longer for Windows (typically 30-60 minutes)

## Output Manifests

After each build, Packer creates manifest files with image details:

- `manifest-aws-linux.json` - AWS Linux AMI details
- `manifest-aws-windows.json` - AWS Windows AMI details
- `manifest-azure-linux.json` - Azure Linux Image details
- `manifest-azure-windows.json` - Azure Windows Image details

## Integration with Terraform

### Using Specific Image IDs

```bash
cd ../terraform

# Linux images
terraform apply \
  -var 'cloud_provider=aws' \
  -var 'os_type=linux' \
  -var 'packer_ami_id=ami-xxxxx'

# Windows images
terraform apply \
  -var 'cloud_provider=aws' \
  -var 'os_type=windows' \
  -var 'packer_windows_ami_id=ami-xxxxx'

# Both OS types
terraform apply \
  -var 'cloud_provider=multi' \
  -var 'os_type=both'
```

## Best Practices

### General
1. Use version control for all Packer configurations
2. Tag images with environment, OS, version, and build date
3. Test images in non-production environments first
4. Automate builds in CI/CD pipelines
5. Regularly update base images for security patches
6. Clean up old images to reduce costs

### Windows-Specific
1. Allocate sufficient build time (30-60 minutes)
2. Use larger instance types (t3.medium or Standard_D2s_v3)
3. Ensure WinRM is properly configured
4. Test Sysprep process before production builds
5. Monitor Windows Update installation carefully
6. Consider disabling Windows Defender during build for speed

### Linux-Specific
1. Keep builds lightweight and fast
2. Use cloud-init for runtime configuration
3. Minimize installed packages
4. Use security-hardened base images

## Troubleshooting

### AWS Windows Issues
- **WinRM timeout**: Increase `winrm_timeout` or check security groups
- **Sysprep fails**: Review EC2Launch configuration
- **Build hangs**: Check Windows Update installation progress

### Azure Windows Issues
- **Authentication fails**: Verify ARM credentials are correct
- **Sysprep timeout**: Increase build timeout settings
- **VM Agent issues**: Ensure Azure VM Agent is running

### Linux Issues
- **cloud-init timeout**: Some images take longer to initialize
- **Package installation fails**: Check repository availability
- **SSH connection fails**: Verify security group/NSG rules

### General Debug Commands

```bash
# Enable Packer debug logging
PACKER_LOG=1 packer build templates/multi-cloud-all.pkr.hcl

# Validate with variables
packer validate -var 'environment=prod' templates/aws-windows-ami.pkr.hcl

# Format all templates
packer fmt .
```

## Example Workflows

### Build production images for all platforms

```bash
# Set production variables
export PKR_VAR_environment="prod"
export PKR_VAR_aws_region="us-west-2"
export PKR_VAR_azure_location="West US"

# Build all images
packer build templates/multi-cloud-all.pkr.hcl
```

### Build only Windows images for disaster recovery

```bash
packer build -only='*-windows' \
  -var 'environment=dr' \
  -var 'aws_region=us-east-2' \
  -var 'azure_location=East US 2' \
  templates/multi-cloud-all.pkr.hcl
```

### Automated CI/CD pipeline example

```bash
#!/bin/bash
# Build script for CI/CD

# Initialize
packer init templates/multi-cloud-all.pkr.hcl

# Validate
packer validate templates/multi-cloud-all.pkr.hcl

# Build
packer build \
  -var "environment=${ENV}" \
  -var "project_name=${PROJECT}" \
  templates/multi-cloud-all.pkr.hcl

# Extract image IDs from manifests
AWS_LINUX_AMI=$(jq -r '.builds[0].artifact_id' manifest-aws-linux.json | cut -d: -f2)
AWS_WINDOWS_AMI=$(jq -r '.builds[0].artifact_id' manifest-aws-windows.json | cut -d: -f2)

echo "Linux AMI: $AWS_LINUX_AMI"
echo "Windows AMI: $AWS_WINDOWS_AMI"
```

## Resources

- [Packer Documentation](https://www.packer.io/docs)
- [Packer AWS Builder](https://www.packer.io/docs/builders/amazon)
- [Packer Azure Builder](https://www.packer.io/docs/builders/azure)
- [WinRM Communicator](https://www.packer.io/docs/communicators/winrm)
