# Packer Image Building Templates

This directory contains Packer templates for building machine images for AWS and Azure.

## Directory Structure

```
packer/
├── aws/
│   └── aws-ami.pkr.hcl          # AWS AMI build configuration
├── azure/
│   └── azure-image.pkr.hcl      # Azure VM image build configuration
├── scripts/                      # Provisioning scripts
│   ├── update-system.sh
│   ├── install-docker.sh
│   ├── install-aws-tools.sh
│   ├── install-azure-tools.sh
│   ├── install-app-dependencies.sh
│   ├── security-hardening.sh
│   ├── install-monitoring.sh
│   └── cleanup.sh
└── README.md                     # This file
```

## Prerequisites

### General
- [Packer](https://www.packer.io/downloads) >= 1.9.0 installed
- Basic understanding of Packer templates

### AWS
- AWS CLI configured with appropriate credentials
- IAM permissions to create EC2 instances, AMIs, and related resources
- Default VPC or custom VPC with public subnet

### Azure
- Azure CLI installed and authenticated
- Resource group created for Packer images
- Service Principal with Contributor access (or use Azure CLI auth)

## Building Images

### AWS AMI

#### Using Environment Variables

```bash
cd packer/aws

# Set AWS credentials (if not using AWS CLI profile)
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"

# Build the AMI
packer init .
packer validate aws-ami.pkr.hcl
packer build aws-ami.pkr.hcl
```

#### With Variables

```bash
cd packer/aws

packer build \
  -var 'aws_region=us-west-2' \
  -var 'environment=production' \
  -var 'app_version=1.2.0' \
  aws-ami.pkr.hcl
```

#### Using var-file

Create a `variables.pkrvars.hcl` file:

```hcl
aws_region       = "us-east-1"
instance_type    = "t3.small"
environment      = "production"
app_version      = "1.0.0"
ami_name_prefix  = "myapp"
```

Then build:

```bash
packer build -var-file=variables.pkrvars.hcl aws-ami.pkr.hcl
```

### Azure VM Image

#### Using Azure CLI Authentication

```bash
cd packer/azure

# Login to Azure
az login

# Build the image
packer init .
packer validate azure-image.pkr.hcl
packer build azure-image.pkr.hcl
```

#### Using Service Principal

```bash
cd packer/azure

# Set Azure credentials
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"

# Build the image
packer build azure-image.pkr.hcl
```

#### With Variables

```bash
cd packer/azure

packer build \
  -var 'location=westus2' \
  -var 'environment=production' \
  -var 'app_version=1.2.0' \
  azure-image.pkr.hcl
```

## Provisioning Scripts

### update-system.sh
Updates system packages and installs essential utilities.

### install-docker.sh
Installs Docker CE, Docker Compose, and configures Docker service.

### install-aws-tools.sh
Installs AWS CLI, CloudWatch Agent, and SSM Agent (AWS only).

### install-azure-tools.sh
Installs Azure CLI and Azure Monitor Agent (Azure only).

### install-app-dependencies.sh
Installs application-specific dependencies (Node.js, Python, etc.).

### security-hardening.sh
Applies security hardening:
- Configures fail2ban
- Sets up UFW firewall
- Disables root login
- Configures automatic security updates
- Hardens kernel parameters

### install-monitoring.sh
Installs monitoring agents:
- Prometheus Node Exporter
- Logging configuration

### cleanup.sh
Cleans up temporary files, logs, and prepares image for deployment.

## Customization

### Adding Custom Provisioners

Add a new provisioner block in the build section:

```hcl
build {
  sources = ["source.amazon-ebs.app"]

  # Your custom provisioner
  provisioner "shell" {
    script = "../scripts/your-custom-script.sh"
  }
}
```

### Adding Custom Scripts

1. Create your script in `scripts/` directory
2. Make it executable: `chmod +x scripts/your-script.sh`
3. Reference it in the Packer template

### Modifying Base Images

#### AWS
Change the `source_ami_filter_name` variable:

```hcl
variable "source_ami_filter_name" {
  default = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
}
```

#### Azure
Change the image publisher, offer, and SKU:

```hcl
source "azure-arm" "app" {
  image_publisher = "RedHat"
  image_offer     = "RHEL"
  image_sku       = "8-lvm-gen2"
  image_version   = "latest"
}
```

## Variables Reference

### AWS Variables

| Variable | Default | Description |
|----------|---------|-------------|
| aws_region | us-east-1 | AWS region for AMI |
| instance_type | t3.micro | EC2 instance type |
| ami_name_prefix | myapp | Prefix for AMI name |
| environment | dev | Environment tag |
| app_version | 1.0.0 | Application version |
| source_ami_owner | 099720109477 | AMI owner (Canonical) |
| source_ami_filter_name | ubuntu/images/... | Base AMI filter |
| ssh_username | ubuntu | SSH username |

### Azure Variables

| Variable | Default | Description |
|----------|---------|-------------|
| subscription_id | - | Azure subscription ID |
| resource_group_name | packer-images-rg | Resource group name |
| location | eastus | Azure region |
| vm_size | Standard_B2s | VM size |
| image_name_prefix | myapp | Prefix for image name |
| environment | dev | Environment tag |
| app_version | 1.0.0 | Application version |

## CI/CD Integration

These Packer templates are designed to work with GitHub Actions. See `.github/workflows/packer-build.yml` for automated image building.

### GitHub Actions Secrets Required

#### AWS
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ROLE_TO_ASSUME` (if using OIDC)

#### Azure
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

## Troubleshooting

### Packer Build Fails to Connect

**Issue**: SSH/WinRM connection timeout

**Solutions**:
- Ensure security groups allow SSH (port 22) from your IP
- Verify the VPC has internet connectivity
- Check if the instance is in a public subnet with a public IP

### AMI/Image Already Exists

**Issue**: Image with the same name already exists

**Solutions**:
- Use timestamp in image names (already configured)
- Delete old images before building
- Use `-force` flag: `packer build -force ...`

### Permission Denied Errors

**Issue**: Scripts fail with permission errors

**Solutions**:
- Ensure all scripts are executable: `chmod +x scripts/*.sh`
- Check IAM/RBAC permissions for creating resources

### Slow Builds

**Solutions**:
- Use a larger instance type
- Optimize provisioning scripts
- Use Packer's `pause_before` to debug

## Best Practices

1. **Version Control**: Tag images with version numbers
2. **Immutable Infrastructure**: Don't modify running instances
3. **Security**: Use encrypted AMIs/images
4. **Testing**: Validate images before production use
5. **Documentation**: Document custom modifications
6. **Automation**: Use CI/CD for consistent builds
7. **Cleanup**: Regularly remove old images
8. **Validation**: Use `packer validate` before builds

## Advanced Usage

### Building Multiple Images

Create a `build.pkr.hcl` with multiple sources:

```hcl
build {
  sources = [
    "source.amazon-ebs.app",
    "source.amazon-ebs.app-gpu"
  ]

  # Shared provisioners
}
```

### Using Ansible for Provisioning

```hcl
provisioner "ansible" {
  playbook_file = "../ansible/playbook.yml"
}
```

### Creating Shared Image Galleries (Azure)

Uncomment the `shared_image_gallery_destination` block in `azure-image.pkr.hcl`.

## Support

For issues or questions:
- Check Packer documentation: https://www.packer.io/docs
- Review provisioning script logs
- Enable debug mode: `PACKER_LOG=1 packer build ...`

## License

These Packer templates are provided as-is for use in your projects.
