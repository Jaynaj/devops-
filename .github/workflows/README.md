# GitHub Actions Workflows Documentation

This directory contains GitHub Actions workflows for CI/CD, security scanning, and infrastructure deployment.

## 📋 Workflows Overview

### 1. Build, Scan, and Push to Registries (`build-scan-push-registries.yml`)

**Purpose**: Build Docker images, perform security scans, and push to AWS ECR and Azure ACR using OIDC authentication.

**Triggers**:
- Push to `main` or `develop` branches
- Pull requests
- Manual dispatch

**Features**:
- Multi-stage Docker builds with BuildKit
- Trivy vulnerability scanning
- Secret scanning in images
- OIDC authentication for AWS and Azure
- Push to both ECR and ACR
- SBOM and provenance generation

**Required Secrets**:
- `AWS_ROLE_TO_ASSUME`: ARN of the AWS IAM role to assume via OIDC
- `AZURE_CLIENT_ID`: Azure application (client) ID
- `AZURE_TENANT_ID`: Azure tenant ID
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID

### 2. ECS Blue-Green Deployment (`ecs-bluegreen-deployment.yml`)

**Purpose**: Deploy containers to AWS ECS using Blue-Green deployment strategy with AWS CodeDeploy.

**Triggers**:
- Successful completion of build workflow
- Manual dispatch

**Features**:
- Automated Blue-Green deployments
- Zero-downtime deployments
- Automatic rollback on failure
- Environment-based deployments (dev/staging/production)
- GitHub deployment tracking

**Required Secrets**:
- `AWS_ROLE_TO_ASSUME`: ARN of the AWS IAM role to assume via OIDC

**Required Configuration**:
- ECS cluster and service must exist
- CodeDeploy application and deployment group must be configured
- `appspec.yaml` file must be present in the repository

### 3. Terraform Cloud Deployment (`terraform-cloud.yml`)

**Purpose**: Manage infrastructure using Terraform Cloud with approval gates.

**Triggers**:
- Push to `main` or `develop` branches (terraform files only)
- Pull requests
- Manual dispatch

**Features**:
- Terraform plan on PRs
- Manual approval before apply
- Security scanning with tfsec and Checkov
- Multiple workspace support
- Terraform Cloud integration
- Plan artifacts and outputs

**Required Secrets**:
- `TF_API_TOKEN`: Terraform Cloud API token

**Approval Process**:
- Plan runs automatically
- Apply requires manual approval via GitHub Environments
- Destroy requires separate approval

### 4. GHCR and Helm Publishing (`ghcr-helm-publish.yml`)

**Purpose**: Build and push Docker images to GitHub Container Registry and package Helm charts.

**Triggers**:
- Push to `main` or `develop` branches
- Tag creation (v*.*.*)
- Pull requests
- Release publication

**Features**:
- Multi-architecture builds (amd64/arm64)
- Automatic versioning
- Helm chart packaging and publishing to GHCR OCI registry
- Helm chart validation
- Local Kubernetes testing with kind
- Artifact attestation

**Required Secrets**:
- `GITHUB_TOKEN`: Automatically provided by GitHub

### 5. Security Scanning (`security-scanning.yml`)

**Purpose**: Comprehensive security scanning for secrets, vulnerabilities, and misconfigurations.

**Triggers**:
- Push to any branch
- Pull requests
- Daily schedule (2 AM UTC)
- Manual dispatch

**Features**:
- Secret detection (TruffleHog, Gitleaks, GitGuardian)
- Dependency vulnerability scanning (Trivy, Snyk)
- SAST with CodeQL and Semgrep
- Credential file detection
- Docker image security scanning
- Infrastructure security scanning
- Kubernetes manifest validation

**Required Secrets**:
- `GITLEAKS_LICENSE`: Gitleaks license (optional)
- `GITGUARDIAN_API_KEY`: GitGuardian API key (optional)
- `SNYK_TOKEN`: Snyk API token (optional)

## 🔧 Setup Instructions

### 1. AWS OIDC Configuration

To use OIDC with AWS:

```bash
# Create an OIDC provider in AWS
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list <thumbprint>

# Create an IAM role with trust policy
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
        }
      }
    }
  ]
}
```

### 2. Azure OIDC Configuration

To use OIDC with Azure:

```bash
# Create an Azure AD application
az ad app create --display-name github-actions-oidc

# Create a service principal
az ad sp create --id <app-id>

# Create federated credentials
az ad app federated-credential create \
  --id <app-id> \
  --parameters '{
    "name": "github-actions",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Assign permissions to the service principal
az role assignment create \
  --assignee <app-id> \
  --role Contributor \
  --scope /subscriptions/<subscription-id>
```

### 3. GitHub Environments

Create the following environments in your repository settings:

- `dev`
- `staging`
- `production`
- `terraform-approval` (with required reviewers)
- `terraform-destroy-approval` (with required reviewers)

### 4. Required Repository Secrets

Add these secrets in your repository settings:

```
AWS_ROLE_TO_ASSUME=arn:aws:iam::123456789012:role/github-actions-role
AZURE_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
TF_API_TOKEN=your-terraform-cloud-token
GITGUARDIAN_API_KEY=your-gitguardian-key (optional)
SNYK_TOKEN=your-snyk-token (optional)
```

### 5. Update Environment Variables

Update the following environment variables in each workflow file:

**build-scan-push-registries.yml**:
- `AWS_REGION`: Your AWS region
- `AZURE_REGISTRY_NAME`: Your ACR name
- `IMAGE_NAME`: Your application name

**ecs-bluegreen-deployment.yml**:
- `AWS_REGION`: Your AWS region
- `ECS_CLUSTER`: Your ECS cluster name
- `ECS_SERVICE`: Your ECS service name
- `CONTAINER_NAME`: Your container name
- `TASK_DEFINITION_FAMILY`: Your task definition family

**terraform-cloud.yml**:
- `TF_CLOUD_ORGANIZATION`: Your Terraform Cloud organization
- `TF_WORKSPACE_PREFIX`: Your workspace prefix

**ghcr-helm-publish.yml**:
- `HELM_CHART_NAME`: Your Helm chart name

## 📁 Required Files

Ensure the following files exist in your repository:

- `Dockerfile`: Docker build configuration
- `appspec.yaml`: ECS Blue-Green deployment configuration
- `terraform/`: Terraform configuration directory
- `helm/`: Helm chart directory
- `.gitignore`: Prevent secrets from being committed

## 🔒 Security Best Practices

1. **Never commit secrets**: Use GitHub Secrets or environment variables
2. **Use .gitignore**: Add credential files to .gitignore
3. **Enable secret scanning**: GitHub Advanced Security recommended
4. **Review security alerts**: Check Security tab regularly
5. **Use OIDC**: Avoid long-lived credentials
6. **Enable branch protection**: Require status checks and reviews
7. **Use environments**: Add manual approval for production deployments
8. **Rotate secrets**: Regularly rotate API tokens and credentials
9. **Least privilege**: Grant minimum required permissions
10. **Audit logs**: Review GitHub Actions logs regularly

## 🚀 Usage Examples

### Deploy to Production

```bash
# Method 1: Push to main branch
git push origin main

# Method 2: Manual dispatch
# Go to Actions → Select workflow → Run workflow
```

### Deploy Specific Image Tag

```bash
# Use workflow dispatch with custom image tag
# Actions → ECS Blue-Green Deployment → Run workflow
# Set image-tag: v1.2.3
```

### Run Security Scan

```bash
# Method 1: Automatic on push/PR
git push

# Method 2: Manual trigger
# Actions → Security Scanning → Run workflow
```

### Apply Terraform Changes

```bash
# 1. Create PR with terraform changes
# 2. Review plan in PR comments
# 3. Merge to main
# 4. Approve in terraform-approval environment
# 5. Changes applied automatically
```

## 🐛 Troubleshooting

### OIDC Authentication Fails

- Verify OIDC provider is configured correctly
- Check trust policy conditions match repository
- Ensure role has required permissions

### Docker Build Fails

- Check Dockerfile syntax
- Verify build context
- Review build logs for errors

### Helm Chart Push Fails

- Ensure chart version is unique
- Verify GHCR authentication
- Check Chart.yaml syntax

### Terraform Plan/Apply Fails

- Verify Terraform Cloud token
- Check workspace configuration
- Review state lock status

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS OIDC Guide](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Azure OIDC Guide](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Terraform Cloud Documentation](https://www.terraform.io/cloud-docs)
- [Helm Documentation](https://helm.sh/docs/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

## 📝 License

These workflows are provided as-is for use in your projects.
