# Packer Configuration

This directory contains Packer templates for building machine images (AMIs) that can be used with Terraform.

## Structure

```
packer/
├── variables.pkr.hcl    # Variable definitions
├── templates/           # Packer templates
│   └── aws-ami.pkr.hcl # AWS AMI build template
└── scripts/            # Provisioning scripts
    └── provision.sh    # Main provisioning script
```

## Prerequisites

1. Install Packer: https://www.packer.io/downloads
2. Configure AWS credentials:
   ```bash
   export AWS_ACCESS_KEY_ID="your_access_key"
   export AWS_SECRET_ACCESS_KEY="your_secret_key"
   ```
   Or use AWS CLI: `aws configure`

## Usage

### Initialize Packer

```bash
cd packer
packer init templates/aws-ami.pkr.hcl
```

### Validate Template

```bash
packer validate templates/aws-ami.pkr.hcl
```

### Build AMI

```bash
# Build with default variables
packer build templates/aws-ami.pkr.hcl

# Build with custom variables
packer build -var 'environment=prod' -var 'aws_region=us-west-2' templates/aws-ami.pkr.hcl

# Build with variable file
packer build -var-file="prod.pkrvars.hcl" templates/aws-ami.pkr.hcl
```

### Format Packer Files

```bash
packer fmt .
```

## Variables

You can override variables in several ways:

1. **Command line**:
   ```bash
   packer build -var 'instance_type=t3.small' templates/aws-ami.pkr.hcl
   ```

2. **Variable file** (`*.pkrvars.hcl`):
   ```hcl
   aws_region   = "us-west-2"
   environment  = "prod"
   instance_type = "t3.small"
   ```

3. **Environment variables**:
   ```bash
   export PKR_VAR_aws_region="us-west-2"
   ```

## Available Variables

- `aws_region`: AWS region to build the AMI (default: us-east-1)
- `instance_type`: EC2 instance type for building (default: t3.micro)
- `source_ami_filter`: Filter for base AMI (default: Amazon Linux 2)
- `ssh_username`: SSH username for provisioning (default: ec2-user)
- `ami_name_prefix`: Prefix for AMI name (default: packer-devops)
- `environment`: Environment tag (default: dev)
- `project_name`: Project name for tagging (default: devops-project)

## Provisioning

The `scripts/provision.sh` script handles:
- System updates
- Package installation
- Security hardening
- Application setup

Modify this script to customize your AMI.

## Integration with Terraform

After building an AMI:

1. Note the AMI ID from the Packer output or `manifest.json`
2. Use it in Terraform:
   ```bash
   cd ../terraform
   terraform apply -var 'packer_ami_id=ami-xxxxx'
   ```

Or configure Terraform to automatically fetch the latest Packer-built AMI using data sources.

## Best Practices

1. Use version control for all Packer configurations
2. Tag AMIs appropriately with environment, version, and build date
3. Test AMIs in a non-production environment first
4. Automate AMI builds in CI/CD pipeline
5. Regularly update base AMIs and rebuild
6. Clean up old AMIs to reduce costs
7. Use Packer's `manifest` post-processor to track built AMIs
