#!/usr/bin/env bash
# =============================================================================
# bootstrap-secrets.sh — One-Time Secret Initialisation
# =============================================================================
# PURPOSE:
#   Creates the AWS Secrets Manager secret that Terraform will reference at
#   apply time. Run this ONCE before your first terraform apply.
#
# WHY NOT USE TERRAFORM FOR THIS?
#   If you create a secret with Terraform, the secret value is written to
#   terraform.tfstate in plaintext. Bootstrapping outside Terraform keeps the
#   secret value out of state entirely.
#
# USAGE:
#   export AWS_DEFAULT_REGION="us-east-1"
#   export DB_USERNAME="dbadmin"
#   # You will be prompted for the password — it will not echo to the terminal
#   bash scripts/bootstrap-secrets.sh
#
# PREREQUISITES:
#   - AWS CLI v2 installed and configured
#   - IAM permissions: secretsmanager:CreateSecret, secretsmanager:PutSecretValue
# =============================================================================

set -euo pipefail

SECRET_NAME="${SECRET_NAME:-prod/db/credentials}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
DB_USERNAME="${DB_USERNAME:-dbadmin}"

echo "============================================================"
echo "  Terraform Day 13 — Secrets Bootstrap"
echo "============================================================"
echo ""
echo "This script will create: ${SECRET_NAME}"
echo "Region: ${REGION}"
echo ""

# ── Safety check: abort if secret already exists ─────────────────────────────
if aws secretsmanager describe-secret \
     --secret-id "${SECRET_NAME}" \
     --region "${REGION}" \
     --query "Name" \
     --output text 2>/dev/null; then
  echo "ERROR: Secret '${SECRET_NAME}' already exists."
  echo "       To rotate the password, use:"
  echo "       aws secretsmanager put-secret-value --secret-id '${SECRET_NAME}' --secret-string '{...}'"
  exit 1
fi

# ── Prompt for password (no echo) ────────────────────────────────────────────
echo -n "Enter database master password (input hidden): "
read -rs DB_PASSWORD
echo ""

if [[ -z "${DB_PASSWORD}" ]]; then
  echo "ERROR: Password cannot be empty."
  exit 1
fi

# Validate minimum length
if [[ ${#DB_PASSWORD} -lt 16 ]]; then
  echo "ERROR: Password must be at least 16 characters for production use."
  exit 1
fi

# ── Build the secret JSON payload ─────────────────────────────────────────────
SECRET_JSON=$(printf '{"username":"%s","password":"%s"}' \
  "${DB_USERNAME}" \
  "${DB_PASSWORD}")

# ── Create the secret ─────────────────────────────────────────────────────────
echo "Creating secret '${SECRET_NAME}'..."

SECRET_ARN=$(aws secretsmanager create-secret \
  --name "${SECRET_NAME}" \
  --description "Database master credentials for production RDS instance" \
  --secret-string "${SECRET_JSON}" \
  --region "${REGION}" \
  --query "ARN" \
  --output text)

echo ""
echo "✅  Secret created successfully."
echo "    ARN: ${SECRET_ARN}"
echo ""
echo "Next steps:"
echo "  1. Export your AWS credentials as environment variables"
echo "  2. cd terraform/environments/production"
echo "  3. terraform init"
echo "  4. terraform plan"
echo "  5. terraform apply"
echo ""
echo "The secret will be fetched automatically at apply time via the"
echo "aws_secretsmanager_secret_version data source."

# Clear sensitive variable from shell memory
unset DB_PASSWORD
unset SECRET_JSON
