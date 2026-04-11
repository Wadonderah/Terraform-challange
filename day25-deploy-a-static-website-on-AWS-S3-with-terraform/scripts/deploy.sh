#!/usr/bin/env bash
# scripts/deploy.sh
# Complete deployment script for the static website.
# Usage: ./scripts/deploy.sh [dev|staging|prod] [plan|apply|destroy]

set -euo pipefail

ENV=${1:-dev}
ACTION=${2:-plan}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

header() { echo -e "\n${CYAN}═══════════════════════════════════════${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}═══════════════════════════════════════${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✗ $1${NC}"; exit 1; }

# Validate inputs
if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
  error "Environment must be: dev, staging, or prod"
fi

if [[ ! "$ACTION" =~ ^(plan|apply|destroy|output)$ ]]; then
  error "Action must be: plan, apply, destroy, or output"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_DIR="$PROJECT_ROOT/envs/$ENV"

if [[ ! -d "$ENV_DIR" ]]; then
  error "Environment directory not found: $ENV_DIR"
fi

header "Static Website — $ENV / $ACTION"

cd "$ENV_DIR"

# Safety check for production
if [[ "$ENV" == "prod" && "$ACTION" == "destroy" ]]; then
  warn "You are about to destroy the PRODUCTION environment!"
  read -r -p "Type 'destroy production' to confirm: " confirm
  if [[ "$confirm" != "destroy production" ]]; then
    error "Aborted."
  fi
fi

echo "Working directory: $ENV_DIR"
echo "Terraform version: $(terraform version -json | python3 -c 'import sys,json; print(json.load(sys.stdin)["terraform_version"])' 2>/dev/null || terraform version | head -1)"

case "$ACTION" in
  plan)
    header "Running terraform init + plan"
    terraform init -input=false
    terraform validate
    terraform plan -out="${ENV}.tfplan" -input=false
    success "Plan complete. Review the output above."
    echo ""
    echo "To apply: ./scripts/deploy.sh $ENV apply"
    ;;

  apply)
    if [[ -f "${ENV}.tfplan" ]]; then
      header "Applying saved plan: ${ENV}.tfplan"
      terraform apply "${ENV}.tfplan"
    else
      warn "No saved plan found. Running plan + apply."
      terraform init -input=false
      terraform plan -out="${ENV}.tfplan" -input=false
      echo ""
      read -r -p "Apply this plan? [yes/no]: " confirm
      if [[ "$confirm" == "yes" ]]; then
        terraform apply "${ENV}.tfplan"
      else
        error "Apply cancelled."
      fi
    fi

    success "Apply complete!"
    header "Deployment Outputs"
    terraform output

    header "Access your website"
    WEBSITE_URL=$(terraform output -raw website_url 2>/dev/null || echo "")
    if [[ -n "$WEBSITE_URL" ]]; then
      echo ""
      echo -e "${GREEN}  Website URL: $WEBSITE_URL${NC}"
      echo ""
      echo -e "${YELLOW}  Note: CloudFront distributions take 5–15 minutes to propagate globally.${NC}"
      echo -e "${YELLOW}  The website will be accessible at the URL above once propagation completes.${NC}"
    fi

    header "Cache Invalidation"
    INVALIDATE_CMD=$(terraform output -raw cache_invalidation_command 2>/dev/null || echo "")
    if [[ -n "$INVALIDATE_CMD" ]]; then
      echo "Run this after uploading new content:"
      echo "  $INVALIDATE_CMD"
    fi
    ;;

  destroy)
    header "Running terraform destroy for $ENV"
    terraform init -input=false
    terraform destroy
    success "Destroy complete."
    ;;

  output)
    terraform output
    ;;
esac
