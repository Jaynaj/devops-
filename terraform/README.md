# Terraform Configurations

This directory contains modular Terraform configurations for infrastructure provisioning.

## Directory Structure

```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── networking/            # VPC, subnets, routing
│   ├── compute/              # Compute resources
│   │   └── ecs/              # ECS clusters and services
│   ├── database/             # RDS, DynamoDB modules (future)
│   ├── security/             # Security groups, WAF (future)
│   └── monitoring/           # CloudWatch, alarms (future)
├── environments/             # Environment-specific configurations
│   ├── dev/                 # Development environment
│   ├── staging/             # Staging environment
│   └── production/          # Production environment
└── README.md                # This file
```

## Modules

### Networking Module

**Path**: `modules/networking/`

Creates a complete VPC with public and private subnets, NAT gateways, and optional VPC flow logs.

**Features**:
- VPC with customizable CIDR
- Multi-AZ public and private subnets
- Internet Gateway and NAT Gateways
- VPC Flow Logs (optional)
- Proper routing and associations

**Usage**:
```hcl
module "networking" {
  source = "../../modules/networking"

  name_prefix        = "myapp-dev"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  enable_nat_gateway = true
  enable_flow_logs   = true

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
```

### ECS Compute Module

**Path**: `modules/compute/ecs/`

Creates ECS Fargate clusters, services, task definitions, and auto-scaling.

**Features**:
- ECS Fargate cluster with Container Insights
- Task definitions with configurable resources
- IAM roles and policies
- CloudWatch logging
- Auto-scaling policies (CPU and memory)
- Blue-Green deployment support (CodeDeploy)
- ECS Exec support for debugging

**Usage**:
```hcl
module "ecs" {
  source = "../../modules/compute/ecs"

  cluster_name     = "myapp-cluster"
  service_name     = "myapp-service"
  container_name   = "myapp"
  container_image  = "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest"
  container_port   = 8080

  cpu    = 256
  memory = 512

  desired_count = 2

  aws_region          = "us-east-1"
  subnet_ids          = module.networking.private_subnet_ids
  security_group_ids  = [aws_security_group.ecs_tasks.id]
  target_group_arn    = aws_lb_target_group.app.arn

  enable_auto_scaling = true
  min_capacity        = 1
  max_capacity        = 10

  environment_variables = [
    {
      name  = "ENVIRONMENT"
      value = "dev"
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
```

## Environment Configurations

Each environment directory (`dev`, `staging`, `production`) contains a complete infrastructure configuration using the modules.

### Structure

```
environments/<env>/
├── main.tf           # Main configuration with module calls
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── backend.tf        # Backend configuration (Terraform Cloud)
└── terraform.tfvars  # Variable values (gitignored for sensitive data)
```

### Using Environment Configurations

```bash
# Navigate to environment directory
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy
```

## Best Practices

### 1. Module Versioning

When using modules in production, pin to specific versions:

```hcl
module "networking" {
  source  = "git::https://github.com/org/terraform-modules.git//networking?ref=v1.0.0"
  # ...
}
```

### 2. State Management

Use Terraform Cloud or S3 backend for state management:

```hcl
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      name = "myapp-dev"
    }
  }
}
```

### 3. Variable Management

- Use `.tfvars` files for environment-specific values
- Never commit sensitive values to git
- Use Terraform Cloud variables or AWS Secrets Manager

### 4. Tagging Strategy

Apply consistent tags to all resources:

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Repository  = "github.com/org/repo"
  }
}
```

### 5. Module Design

- Keep modules focused on a single responsibility
- Use variables for all configurable values
- Provide sensible defaults
- Document all inputs and outputs
- Include examples in module READMEs

## Creating New Modules

1. Create module directory: `mkdir -p modules/<module-name>`
2. Add required files:
   ```
   modules/<module-name>/
   ├── main.tf       # Resource definitions
   ├── variables.tf  # Input variables
   ├── outputs.tf    # Output values
   └── README.md     # Documentation
   ```
3. Document inputs, outputs, and usage examples
4. Test the module in a dev environment
5. Version the module if in a separate repository

## Testing

### Validation

```bash
terraform validate
```

### Formatting

```bash
terraform fmt -recursive
```

### Security Scanning

```bash
# Using tfsec
tfsec .

# Using Checkov
checkov -d .
```

### Plan Testing

```bash
terraform plan -out=tfplan
terraform show -json tfplan | jq .
```

## CI/CD Integration

See `.github/workflows/terraform-cloud.yml` for automated Terraform workflows:

- Validate on all PRs
- Plan on PRs with file comments
- Apply on main branch (with approval)
- Security scanning with tfsec and Checkov

## Common Patterns

### Multi-Environment Deployment

```hcl
# Use workspaces or separate directories
terraform workspace new dev
terraform workspace new staging
terraform workspace new production
```

### Resource Naming

```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_instance" "app" {
  # ...
  tags = {
    Name = "${local.name_prefix}-app-server"
  }
}
```

### Conditional Resources

```hcl
resource "aws_instance" "bastion" {
  count = var.create_bastion ? 1 : 0
  # ...
}
```

## Troubleshooting

### State Lock Issues

```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Import Existing Resources

```bash
terraform import aws_instance.example i-1234567890abcdef0
```

### Refresh State

```bash
terraform refresh
```

### Debug Mode

```bash
TF_LOG=DEBUG terraform apply
```

## Module Registry

Consider publishing modules to:
- Terraform Registry (public)
- Private module registry
- Git repositories with version tags

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Module Development](https://www.terraform.io/docs/modules/index.html)

## Contributing

When contributing modules:

1. Follow the established directory structure
2. Include comprehensive documentation
3. Add examples of module usage
4. Test thoroughly in dev environment
5. Run security scans before committing
6. Use descriptive commit messages

## License

These Terraform configurations are provided as-is for use in your projects.
