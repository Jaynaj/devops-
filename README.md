# DevOps Pipeline - Complete CI/CD Solution

A comprehensive DevOps pipeline implementation using GitHub Actions, AWS, Azure, and Terraform Cloud with security best practices.

## Features

### 🚀 Automated CI/CD Pipelines

- **Packer Image Building**: Automated AMI and VM image creation for AWS and Azure
- **Multi-Registry Docker Builds**: Build once, push to AWS ECR, Azure ACR, and GitHub Container Registry
- **Security Scanning**: Integrated vulnerability scanning with Trivy, Snyk, and secret detection
- **Blue-Green Deployments**: Zero-downtime deployments to AWS ECS using CodeDeploy
- **Modular Infrastructure as Code**: Terraform modules for networking, compute, and more
- **Infrastructure as Code**: Terraform Cloud integration with approval workflows
- **Helm Chart Publishing**: Package and publish Helm charts to GHCR OCI registry

### 🔒 Security Features

- **OIDC Authentication**: Secure, keyless authentication with AWS and Azure
- **Secret Scanning**: Multiple layers of secret detection (TruffleHog, Gitleaks, GitGuardian)
- **SAST**: Static application security testing with CodeQL and Semgrep
- **Container Scanning**: Image vulnerability scanning before deployment
- **IaC Security**: Terraform security scanning with tfsec and Checkov
- **Compliance**: Automated security checks on every commit

### 📦 What's Included

```
.
├── .github/
│   ├── workflows/                    # GitHub Actions workflows
│   │   ├── build-scan-push-registries.yml   # Docker build and multi-registry push
│   │   ├── ecs-bluegreen-deployment.yml     # ECS Blue-Green deployments
│   │   ├── terraform-cloud.yml              # Terraform Cloud integration
│   │   ├── ghcr-helm-publish.yml            # GHCR and Helm chart publishing
│   │   ├── security-scanning.yml            # Comprehensive security scans
│   │   ├── packer-build.yml                 # Packer image building
│   │   └── README.md                        # Workflows documentation
│   └── SETUP_GUIDE.md                # Step-by-step setup instructions
├── packer/                           # Packer templates for image building
│   ├── aws/
│   │   └── aws-ami.pkr.hcl          # AWS AMI configuration
│   ├── azure/
│   │   └── azure-image.pkr.hcl      # Azure VM image configuration
│   ├── scripts/                      # Provisioning scripts
│   │   ├── update-system.sh
│   │   ├── install-docker.sh
│   │   ├── install-aws-tools.sh
│   │   ├── install-azure-tools.sh
│   │   ├── security-hardening.sh
│   │   └── cleanup.sh
│   └── README.md                     # Packer documentation
├── terraform/                        # Modular Terraform configurations
│   ├── modules/                     # Reusable modules
│   │   ├── networking/              # VPC, subnets, routing
│   │   └── compute/
│   │       └── ecs/                 # ECS cluster and services
│   ├── environments/                # Environment-specific configs
│   │   ├── dev/                     # Development environment
│   │   ├── staging/                 # Staging environment
│   │   └── production/              # Production environment
│   └── README.md                    # Terraform documentation
├── helm/                            # Helm charts
│   └── myapp/                      # Application Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── Dockerfile                       # Multi-stage Docker build
├── appspec.yaml                    # ECS deployment specification
└── .gitignore                      # Prevent secrets in git

```

## Quick Start

### Prerequisites

- GitHub repository with admin access
- AWS account with permissions to create IAM roles, ECS, ECR, and CodeDeploy resources
- Azure subscription with Contributor access
- Terraform Cloud account

### Setup Steps

1. **Follow the Setup Guide**: See [.github/SETUP_GUIDE.md](.github/SETUP_GUIDE.md) for detailed instructions

2. **Configure OIDC**:
   - AWS: Create OIDC provider and IAM role
   - Azure: Create App Registration with federated credentials

3. **Add Repository Secrets**:
   ```
   AWS_ROLE_TO_ASSUME
   AZURE_CLIENT_ID
   AZURE_TENANT_ID
   AZURE_SUBSCRIPTION_ID
   TF_API_TOKEN
   ```

4. **Create GitHub Environments**:
   - `dev`, `staging`, `production`
   - `terraform-approval` (with required reviewers)

5. **Update Workflow Variables**: Edit workflow files with your specific values

6. **Test the Pipeline**:
   ```bash
   git add .
   git commit -m "feat: initial DevOps setup"
   git push origin main
   ```

## Workflows

### Build, Scan, and Push to Registries

**File**: `.github/workflows/build-scan-push-registries.yml`

- Builds Docker images with BuildKit
- Runs Trivy vulnerability scans
- Scans for secrets in images
- Pushes to AWS ECR and Azure ACR using OIDC
- Generates SBOM and provenance attestations

**Triggers**: Push to `main`/`develop`, Pull requests, Manual

### ECS Blue-Green Deployment

**File**: `.github/workflows/ecs-bluegreen-deployment.yml`

- Deploys to AWS ECS using CodeDeploy
- Blue-Green deployment strategy
- Zero-downtime deployments
- Automatic rollback on failure
- Environment-based deployments

**Triggers**: After successful build, Manual

### Terraform Cloud Deployment

**File**: `.github/workflows/terraform-cloud.yml`

- Runs Terraform plan on PRs
- Security scanning (tfsec, Checkov)
- Requires manual approval before apply
- Multi-workspace support
- Terraform state management

**Triggers**: Push to terraform files, Pull requests, Manual

### Packer Image Building

**File**: `.github/workflows/packer-build.yml`

- Validates Packer templates
- Builds AWS AMIs with security hardening
- Builds Azure VM images
- Installs Docker, monitoring agents, and dependencies
- Applies security hardening to base images
- Generates image manifests

**Triggers**: Push to packer files, Pull requests, Manual

### GHCR and Helm Publishing

**File**: `.github/workflows/ghcr-helm-publish.yml`

- Builds multi-architecture images (amd64/arm64)
- Pushes to GitHub Container Registry
- Packages and publishes Helm charts
- Tests chart installation with kind
- Generates artifact attestations

**Triggers**: Push to `main`/`develop`, Tags, Releases

### Security Scanning

**File**: `.github/workflows/security-scanning.yml`

- Secret detection (multiple tools)
- Dependency vulnerability scanning
- SAST with CodeQL and Semgrep
- Docker image security scanning
- Infrastructure security scanning
- Daily scheduled scans

**Triggers**: All pushes/PRs, Daily at 2 AM UTC, Manual

## Security Best Practices

✅ **OIDC Authentication** - No long-lived credentials
✅ **Secret Scanning** - Multiple layers of detection
✅ **Branch Protection** - Required reviews and status checks
✅ **Environment Approvals** - Manual gates for production
✅ **Least Privilege** - Minimal required permissions
✅ **Audit Logging** - Full deployment history
✅ **Vulnerability Scanning** - Pre-deployment security checks
✅ **Infrastructure Security** - IaC scanning before apply

## Documentation

- **Workflows**: [.github/workflows/README.md](.github/workflows/README.md)
- **Setup Guide**: [.github/SETUP_GUIDE.md](.github/SETUP_GUIDE.md)
- **Packer Templates**: [packer/README.md](packer/README.md)
- **Terraform Modules**: [terraform/README.md](terraform/README.md)
- **Helm Charts**: [helm/](helm/)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Actions                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Build & Scan │→ │ Push Images  │→ │ Deploy ECS   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         │                  │                  │                  │
└─────────┼──────────────────┼──────────────────┼──────────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
   ┌──────────────┐   ┌──────────┐     ┌─────────────┐
   │   Security   │   │   AWS    │     │    Azure    │
   │   Scanning   │   │   ECR    │     │     ACR     │
   │  (Trivy/     │   │          │     │             │
   │   CodeQL)    │   │   ECS    │     │             │
   └──────────────┘   │          │     └─────────────┘
                      │ CodeDeploy│
                      │  (B/G)    │
                      └───────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │ Terraform Cloud │
                   │  (IaC Mgmt)     │
                   └─────────────────┘
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Run security scans locally
4. Submit a pull request
5. Wait for CI/CD checks to pass
6. Get approval from reviewers

## Support

For issues or questions:
- Check the [Setup Guide](.github/SETUP_GUIDE.md)
- Review [Workflows Documentation](.github/workflows/README.md)
- Check GitHub Actions logs
- Review cloud provider documentation

## License

This DevOps pipeline template is provided as-is for use in your projects.