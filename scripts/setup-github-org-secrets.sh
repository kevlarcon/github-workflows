#!/bin/bash
set -euo pipefail

# Setup GitHub organization secrets
# Requires: gh CLI tool installed and authenticated

ORG="kevlarcon"

echo "🔐 Setting up GitHub organization secrets..."

# Check if gh is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "Install with: brew install gh"
    exit 1
fi

# Test authentication
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub"
    echo "Run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is authenticated"

# Function to set organization secret
set_org_secret() {
    local secret_name="$1"
    local secret_value="$2"

    echo "Setting organization secret: $secret_name"
    echo "$secret_value" | gh secret set "$secret_name" --org "$ORG"
    echo "✅ Set $secret_name"
}

# 1. Docker Registry Token
echo
echo "📦 Setting up Docker Registry Token..."
echo "Please create a Personal Access Token with package permissions:"
echo "https://github.com/settings/tokens/new"
echo "Required scopes: read:packages, write:packages"
echo
read -sp "Enter your GitHub PAT: " DOCKER_TOKEN
echo
set_org_secret "DOCKER_REGISTRY_TOKEN" "$DOCKER_TOKEN"

# 2. Kubernetes Config
echo
echo "☸️  Setting up Kubernetes Config..."
echo "Getting kubeconfig from current context..."

if ! kubectl config current-context &> /dev/null; then
    echo "❌ No current kubectl context"
    echo "Please configure kubectl to point to your cluster"
    exit 1
fi

KUBE_CONFIG_B64=$(kubectl config view --raw --minify | base64 -w 0)
set_org_secret "KUBE_CONFIG_DATA" "$KUBE_CONFIG_B64"

# 3. AWS Credentials (optional)
echo
echo "☁️  AWS Credentials (optional, press Enter to skip)..."
read -p "AWS Access Key ID: " AWS_KEY
if [ -n "$AWS_KEY" ]; then
    read -sp "AWS Secret Access Key: " AWS_SECRET
    echo
    set_org_secret "AWS_ACCESS_KEY_ID" "$AWS_KEY"
    set_org_secret "AWS_SECRET_ACCESS_KEY" "$AWS_SECRET"
else
    echo "Skipped AWS credentials"
fi

echo
echo "🎉 Organization secrets setup complete!"
echo
echo "Secrets configured:"
echo "  ✅ DOCKER_REGISTRY_TOKEN"
echo "  ✅ KUBE_CONFIG_DATA"
if [ -n "${AWS_KEY:-}" ]; then
    echo "  ✅ AWS_ACCESS_KEY_ID"
    echo "  ✅ AWS_SECRET_ACCESS_KEY"
fi
echo
echo "All repositories in the '$ORG' organization can now use these secrets."