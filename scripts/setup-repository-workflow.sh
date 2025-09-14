#!/bin/bash
set -euo pipefail

# Setup GitHub workflow for a specific app repository
# Usage: ./setup-repository-workflow.sh <app-name> <domain> [repo-path]

APP_NAME="$1"
DOMAIN="$2"
REPO_PATH="${3:-.}"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <app-name> <domain> [repo-path]"
    echo "Example: $0 grantcentral grantcentral.io /path/to/grantcentral-repo"
    exit 1
fi

echo "🚀 Setting up GitHub workflow for $APP_NAME"
echo "   Domain: $DOMAIN"
echo "   Repository: $REPO_PATH"

# Create .github/workflows directory
mkdir -p "$REPO_PATH/.github/workflows"

# Create deployment workflow
cat > "$REPO_PATH/.github/workflows/deploy.yml" << EOF
name: Deploy $APP_NAME

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  deploy:
    if: github.ref == 'refs/heads/main'
    uses: kevlarcon/github-workflows/.github/workflows/deploy-django-app.yml@main
    with:
      app_name: $APP_NAME
      environment: prod
      domain: $DOMAIN
    secrets: inherit
EOF

echo "✅ Created deployment workflow"

# Create Dockerfile if it doesn't exist
if [ ! -f "$REPO_PATH/Dockerfile" ]; then
    cat > "$REPO_PATH/Dockerfile" << EOF
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    build-essential \\
    libpq-dev \\
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput

# Create a health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \\
    CMD python -c "import requests; requests.get('http://localhost:8000/health/')"

# Expose port
EXPOSE 8000

# Run application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "config.wsgi:application"]
EOF
    echo "✅ Created sample Dockerfile"
else
    echo "ℹ️  Dockerfile already exists, skipping"
fi

# Create .dockerignore if it doesn't exist
if [ ! -f "$REPO_PATH/.dockerignore" ]; then
    cat > "$REPO_PATH/.dockerignore" << EOF
.git
.github
.gitignore
README.md
Dockerfile
.dockerignore
node_modules
.venv
venv/
__pycache__
*.pyc
.pytest_cache
.coverage
htmlcov/
.DS_Store
.env
.env.local
db.sqlite3
EOF
    echo "✅ Created .dockerignore"
else
    echo "ℹ️  .dockerignore already exists, skipping"
fi

# Create sample requirements.txt if it doesn't exist
if [ ! -f "$REPO_PATH/requirements.txt" ]; then
    cat > "$REPO_PATH/requirements.txt" << EOF
Django>=4.2,<5.0
gunicorn>=21.0
psycopg2-binary>=2.9
django-environ>=0.11
requests>=2.31
EOF
    echo "✅ Created sample requirements.txt"
else
    echo "ℹ️  requirements.txt already exists, skipping"
fi

echo
echo "🎉 Repository setup complete!"
echo
echo "Files created/updated:"
echo "  ✅ .github/workflows/deploy.yml"
if [ ! -f "$REPO_PATH/Dockerfile" ]; then
    echo "  ✅ Dockerfile (sample)"
fi
if [ ! -f "$REPO_PATH/.dockerignore" ]; then
    echo "  ✅ .dockerignore"
fi
if [ ! -f "$REPO_PATH/requirements.txt" ]; then
    echo "  ✅ requirements.txt (sample)"
fi
echo
echo "Next steps:"
echo "1. Ensure your Django app has a /health/ endpoint"
echo "2. Commit and push these files to your repository"
echo "3. Push to main branch to trigger deployment"
echo "4. Monitor the Actions tab in GitHub for deployment status"