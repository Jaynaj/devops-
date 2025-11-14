# DevOps Setup Guide

This guide will help you set up the complete CI/CD pipeline with GitHub Actions, AWS, Azure, and Terraform Cloud.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Configuration](#aws-configuration)
3. [Azure Configuration](#azure-configuration)
4. [Terraform Cloud Configuration](#terraform-cloud-configuration)
5. [GitHub Repository Configuration](#github-repository-configuration)
6. [Testing the Setup](#testing-the-setup)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

- GitHub repository with admin access
- AWS account with IAM permissions
- Azure subscription with contributor access
- Terraform Cloud account
- AWS CLI installed
- Azure CLI installed
- Terraform CLI installed

## AWS Configuration

### 1. Create OIDC Provider

```bash
# Get the GitHub OIDC thumbprint
THUMBPRINT=$(openssl s_client -servername token.actions.githubusercontent.com \
  -showcerts -connect token.actions.githubusercontent.com:443 2>/dev/null \
  | openssl x509 -fingerprint -noout | sed 's/://g' | awk -F= '{print tolower($2)}')

# Create OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list $THUMBPRINT
```

### 2. Create IAM Role for GitHub Actions

Create a file `github-actions-trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
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

Create the role:

```bash
# Replace YOUR_ACCOUNT_ID, YOUR_ORG, and YOUR_REPO
aws iam create-role \
  --role-name github-actions-role \
  --assume-role-policy-document file://github-actions-trust-policy.json

# Attach policies for ECR and ECS
aws iam attach-role-policy \
  --role-name github-actions-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

aws iam attach-role-policy \
  --role-name github-actions-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

aws iam attach-role-policy \
  --role-name github-actions-role \
  --policy-arn arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS
```

### 3. Create ECR Repository

```bash
aws ecr create-repository \
  --repository-name myapp \
  --region us-east-1 \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256
```

### 4. Create ECS Cluster and Service

```bash
# Create ECS cluster
aws ecs create-cluster \
  --cluster-name myapp-cluster \
  --region us-east-1

# Create task definition (example)
# You'll need to create a task definition JSON file
aws ecs register-task-definition \
  --cli-input-json file://task-definition.json

# Create service with CodeDeploy
# This requires setting up Application Load Balancer, target groups, etc.
```

### 5. Setup CodeDeploy for Blue-Green Deployment

```bash
# Create CodeDeploy application
aws deploy create-application \
  --application-name myapp-service-codedeploy-app \
  --compute-platform ECS

# Create deployment group
aws deploy create-deployment-group \
  --application-name myapp-service-codedeploy-app \
  --deployment-group-name myapp-service-deployment-group \
  --deployment-config-name CodeDeployDefault.ECSAllAtOnce \
  --service-role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/CodeDeployServiceRole \
  --ecs-services clusterName=myapp-cluster,serviceName=myapp-service \
  --load-balancer-info targetGroupPairInfoList=[{...}] \
  --blue-green-deployment-configuration '{...}'
```

## Azure Configuration

### 1. Create Azure AD Application

```bash
# Login to Azure
az login

# Create application
APP_ID=$(az ad app create \
  --display-name github-actions-oidc \
  --query appId -o tsv)

echo "Application ID: $APP_ID"

# Create service principal
az ad sp create --id $APP_ID

# Get tenant and subscription IDs
TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "Tenant ID: $TENANT_ID"
echo "Subscription ID: $SUBSCRIPTION_ID"
```

### 2. Configure Federated Credentials

```bash
# For main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main",
    "description": "GitHub Actions for main branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For develop branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-develop",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/develop",
    "description": "GitHub Actions for develop branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### 3. Assign Permissions

```bash
# Assign Contributor role to the service principal
az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID

# For ACR specific permissions
az role assignment create \
  --assignee $APP_ID \
  --role AcrPush \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/YOUR_RG/providers/Microsoft.ContainerRegistry/registries/YOUR_ACR
```

### 4. Create Azure Container Registry

```bash
# Create resource group
az group create \
  --name myapp-rg \
  --location eastus

# Create ACR
az acr create \
  --resource-group myapp-rg \
  --name myacrregistry \
  --sku Standard \
  --admin-enabled false
```

## Terraform Cloud Configuration

### 1. Create Organization and Workspaces

1. Go to https://app.terraform.io
2. Create organization (if not exists)
3. Create workspaces:
   - `myapp-dev`
   - `myapp-staging`
   - `myapp-production`

### 2. Configure Workspace Settings

For each workspace:

1. Go to Settings → General
2. Set Execution Mode to "Remote"
3. Set Terraform Version to "1.6.0"
4. Enable "Auto apply" (optional)

### 3. Configure Variables

Add environment variables in each workspace:

```
AWS_ACCESS_KEY_ID (sensitive)
AWS_SECRET_ACCESS_KEY (sensitive)
AWS_DEFAULT_REGION

AZURE_CLIENT_ID
AZURE_CLIENT_SECRET (sensitive)
AZURE_SUBSCRIPTION_ID
AZURE_TENANT_ID
```

### 4. Generate API Token

1. Go to User Settings → Tokens
2. Create API token with description "GitHub Actions"
3. Copy the token (you won't see it again)

## GitHub Repository Configuration

### 1. Create Environments

1. Go to repository Settings → Environments
2. Create environments:
   - **dev**: No protection rules
   - **staging**: Optional reviewers
   - **production**: Required reviewers (1-2 people)
   - **terraform-approval**: Required reviewers (1-2 people)
   - **terraform-destroy-approval**: Required reviewers (2+ people)

### 2. Add Repository Secrets

Go to Settings → Secrets and variables → Actions → New repository secret:

```
AWS_ROLE_TO_ASSUME=arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-role
AZURE_CLIENT_ID=<app-id-from-azure>
AZURE_TENANT_ID=<tenant-id>
AZURE_SUBSCRIPTION_ID=<subscription-id>
TF_API_TOKEN=<terraform-cloud-token>
```

Optional secrets for enhanced security scanning:

```
GITGUARDIAN_API_KEY=<your-key>
SNYK_TOKEN=<your-token>
GITLEAKS_LICENSE=<your-license>
```

### 3. Enable Required Workflows

1. Go to Actions tab
2. Enable workflows if needed
3. Verify permissions in Settings → Actions → General

### 4. Configure Branch Protection

For `main` branch:

1. Go to Settings → Branches
2. Add branch protection rule for `main`:
   - Require pull request reviews (1-2 approvals)
   - Require status checks to pass
   - Require branches to be up to date
   - Include administrators
   - Required status checks:
     - `Security Scanning`
     - `Build and Security Scan`
     - `Terraform Plan`

### 5. Update Workflow Variables

Edit workflow files and update:

**`.github/workflows/build-scan-push-registries.yml`**:
```yaml
env:
  AWS_REGION: us-east-1  # Your region
  AZURE_REGISTRY_NAME: myacrregistry  # Your ACR name
  IMAGE_NAME: myapp  # Your app name
```

**`.github/workflows/ecs-bluegreen-deployment.yml`**:
```yaml
env:
  AWS_REGION: us-east-1
  ECS_CLUSTER: myapp-cluster
  ECS_SERVICE: myapp-service
  CONTAINER_NAME: myapp-container
  TASK_DEFINITION_FAMILY: myapp-task
```

**`.github/workflows/terraform-cloud.yml`**:
```yaml
env:
  TF_CLOUD_ORGANIZATION: "my-org"  # Your org
  TF_WORKSPACE_PREFIX: "myapp"
```

## Testing the Setup

### 1. Test Secret Scanning

```bash
# Create a test branch
git checkout -b test/security-scan

# Push changes
git push origin test/security-scan
```

Verify that the security scanning workflow runs.

### 2. Test Docker Build

```bash
# Make a change to Dockerfile
git checkout -b test/docker-build
git add Dockerfile
git commit -m "test: docker build"
git push origin test/docker-build
```

Create a PR and verify the build workflow runs.

### 3. Test GHCR Publishing

```bash
# Merge to develop
git checkout develop
git merge test/docker-build
git push origin develop
```

Verify images are pushed to GHCR.

### 4. Test Terraform Workflow

```bash
# Add terraform files
mkdir -p terraform
cd terraform
# Add your terraform files
git add terraform/
git commit -m "feat: add terraform configuration"
git push origin develop
```

Create PR and verify plan appears in comments.

### 5. Test Full Deployment

```bash
# Merge to main
git checkout main
git merge develop
git push origin main
```

This should trigger:
1. Build and scan
2. Push to registries
3. ECS deployment (with approval)
4. Terraform apply (with approval)

## Troubleshooting

### OIDC Authentication Fails

**Symptom**: `Error: Not authorized to perform sts:AssumeRoleWithWebIdentity`

**Solution**:
1. Verify the repository name in trust policy matches exactly
2. Check OIDC provider exists in AWS
3. Ensure the role has correct trust policy
4. Verify the subject claim format

### ECR Push Fails

**Symptom**: `Error: denied: Your authorization token has expired`

**Solution**:
1. Verify IAM role has ECR permissions
2. Check ECR repository exists
3. Ensure region matches

### Azure Login Fails

**Symptom**: `Error: AADSTS700016: Application not found`

**Solution**:
1. Verify application ID is correct
2. Check federated credentials are configured
3. Ensure service principal exists

### Terraform Apply Fails

**Symptom**: `Error: workspace not found`

**Solution**:
1. Verify workspace names match the pattern
2. Check Terraform Cloud organization name
3. Ensure API token has correct permissions

### Helm Push Fails

**Symptom**: `Error: failed to authorize: failed to fetch anonymous token`

**Solution**:
1. Verify GITHUB_TOKEN has packages:write permission
2. Check chart version is unique
3. Ensure Chart.yaml is valid

## Best Practices

1. **Rotate secrets regularly**: Set reminders to rotate tokens
2. **Use separate environments**: Keep dev/staging/prod isolated
3. **Review security alerts**: Check Security tab weekly
4. **Monitor costs**: Track AWS/Azure spending
5. **Test in dev first**: Always test changes in dev environment
6. **Document changes**: Update this guide when making changes
7. **Backup state**: Ensure Terraform state is backed up
8. **Use tags**: Tag all resources for cost tracking
9. **Enable logging**: Configure CloudWatch/Azure Monitor
10. **Review deployments**: Check deployment history regularly

## Additional Resources

- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS ECS Blue-Green Deployments](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-bluegreen.html)
- [Terraform Cloud Documentation](https://www.terraform.io/cloud-docs)
- [Helm OCI Support](https://helm.sh/docs/topics/registries/)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)

## Support

If you encounter issues:

1. Check workflow logs in Actions tab
2. Review this setup guide
3. Consult the troubleshooting section
4. Check cloud provider status pages
5. Review GitHub Actions status
