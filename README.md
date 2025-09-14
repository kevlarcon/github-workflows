# GitHub Workflows Repository

Centralized, reusable GitHub Actions workflows for Kevlar's Django applications.

## Purpose

This repository provides:
- **Reusable workflows** for building and deploying Django applications
- **Zero copy-pasta** CI/CD setup for new applications
- **Centralized updates** - modify once, affects all applications
- **Automated credential management** for GitHub Actions

## Repository Structure

```
github-workflows/
├── .github/workflows/
│   └── deploy-django-app.yml      # Reusable deployment workflow
├── scripts/
│   ├── setup-github-org-secrets.sh    # Configure organization secrets
│   └── setup-repository-workflow.sh   # Set up individual app repos
└── README.md
```

## Quick Start

### 1. One-time Organization Setup

Set up organization-level secrets that all repositories will inherit:

```bash
cd /Users/paul/dev/github-workflows
chmod +x scripts/setup-github-org-secrets.sh
./scripts/setup-github-org-secrets.sh
```

This configures:
- `DOCKER_REGISTRY_TOKEN` - GitHub Personal Access Token for container registry
- `KUBE_CONFIG_DATA` - Base64-encoded kubeconfig for Kubernetes access
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` - Optional AWS credentials

### 2. Per-Application Setup

For each Django application repository:

```bash
# Set up workflow files for a specific app
./scripts/setup-repository-workflow.sh grantcentral grantcentral.io /path/to/grantcentral-repo
```

This creates:
- `.github/workflows/deploy.yml` - Simple workflow that calls the reusable workflow
- `Dockerfile` - Sample Django container configuration
- `.dockerignore` - Optimized Docker ignore rules
- `requirements.txt` - Sample Python dependencies

### 3. Deploy Applications

Once set up, applications deploy automatically:
- **Push to main branch** → Triggers deployment
- **Pull requests** → Builds but doesn't deploy

## Workflow Features

### Multi-tenant Django Applications
- **Container building** with GitHub Container Registry (ghcr.io)
- **Kubernetes deployment** using Helm with standardized chart
- **Multi-tenant routing** via nginx sidecar
- **Database integration** with Terraform-managed secrets
- **SSL termination** with automatic certificate management

### Development Experience
- **Fast builds** with Docker layer caching
- **Deployment verification** with rollout status checks
- **URL reporting** shows application endpoints after deployment
- **Error handling** with detailed logs

## Usage in Application Repositories

Each Django application repository only needs this simple workflow file:

`.github/workflows/deploy.yml`:
```yaml
name: Deploy MyApp

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    uses: kevlarcon/github-workflows/.github/workflows/deploy-django-app.yml@main
    with:
      app_name: myapp
      environment: prod
      domain: myapp.io
    secrets: inherit
```

That's it! Only 12 lines of YAML per application.

## Security

### Organization Secrets
All sensitive data is stored as organization-level secrets:
- Automatically inherited by all repositories
- Managed centrally for rotation and updates
- Follows least-privilege access patterns

### Container Security
- Base images use official Python images
- Dependencies are pinned to specific versions
- Container scanning via GitHub security features
- Non-root user execution in containers

## Troubleshooting

### Common Issues

1. **Container registry authentication failed**
   ```
   Error: failed to login to ghcr.io
   ```
   **Solution**: Verify `DOCKER_REGISTRY_TOKEN` has `write:packages` scope

2. **Kubernetes connection failed**
   ```
   Error: failed to connect to cluster
   ```
   **Solution**: Verify `KUBE_CONFIG_DATA` is valid and base64-encoded

3. **Helm deployment timeout**
   ```
   Error: timed out waiting for the condition
   ```
   **Solution**: Check application logs and resource limits

### Debug Commands

```bash
# Test Docker registry access
echo $DOCKER_REGISTRY_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Test kubectl access
echo $KUBE_CONFIG_DATA | base64 -d > kubeconfig
export KUBECONFIG=kubeconfig
kubectl get nodes

# Check Helm chart
helm template myapp /tmp/infrastructure-catalog/charts/django-app \
  --set app.name=myapp \
  --set app.baseDomain=myapp.io \
  --set image.repository=ghcr.io/kevlarcon/myapp
```

## Integration with Infrastructure

This workflow integrates with:
- **infrastructure-catalog**: Uses the standardized Django Helm chart
- **infrastructure-live**: Deploys to Kubernetes clusters provisioned by Terragrunt
- **Application repositories**: Provides the deployment automation

## Updates and Versioning

### Updating Workflows
1. Modify workflows in this repository
2. Push changes to `main` branch
3. All applications automatically use updated workflows

### Version Pinning (Optional)
Applications can pin to specific workflow versions:
```yaml
uses: kevlarcon/github-workflows/.github/workflows/deploy-django-app.yml@v1.2.0
```

### Breaking Changes
When making breaking changes:
1. Create a new major version tag
2. Update documentation
3. Coordinate with application teams for migration