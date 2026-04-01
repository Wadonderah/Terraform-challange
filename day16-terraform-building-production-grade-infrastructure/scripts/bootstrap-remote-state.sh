#!/usr/bin/env bash
# =============================================================================
# scripts/bootstrap-remote-state.sh
# Run ONCE to bootstrap the S3 + DynamoDB backend before using remote state.
# After this runs successfully, uncomment the backend block in main.tf and
# run `terraform init` to migrate local state to S3.
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — edit these values before running
# ---------------------------------------------------------------------------
AWS_REGION="${AWS_REGION:-us-east-1}"
STATE_BUCKET="${STATE_BUCKET:-myapp-terraform-state-ACCOUNTID}"
DYNAMODB_TABLE="${DYNAMODB_TABLE:-terraform-state-lock}"
KMS_ALIAS="${KMS_ALIAS:-alias/terraform-state}"

echo "=========================================="
echo "Bootstrapping Terraform Remote State"
echo "Region:    $AWS_REGION"
echo "Bucket:    $STATE_BUCKET"
echo "DynamoDB:  $DYNAMODB_TABLE"
echo "=========================================="

# 1. Create KMS key

echo "[1/5] Creating KMS key..."
KMS_KEY_ID=$(aws kms create-key \
  --description "Terraform state encryption" \
  --region "$AWS_REGION" \
  --query 'KeyMetadata.KeyId' \
  --output text)

aws kms create-alias \
  --alias-name "$KMS_ALIAS" \
  --target-key-id "$KMS_KEY_ID" \
  --region "$AWS_REGION"

echo "      KMS Key ID: $KMS_KEY_ID"

# 2. Create S3 bucket

echo "[2/5] Creating S3 state bucket..."
if [ "$AWS_REGION" = "us-east-1" ]; then
  aws s3api create-bucket \
    --bucket "$STATE_BUCKET" \
    --region "$AWS_REGION"
else
  aws s3api create-bucket \
    --bucket "$STATE_BUCKET" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION"
fi

# Enable versioning

aws s3api put-bucket-versioning \
  --bucket "$STATE_BUCKET" \
  --versioning-configuration Status=Enabled

# Enable encryption

aws s3api put-bucket-encryption \
  --bucket "$STATE_BUCKET" \
  --server-side-encryption-configuration "{
    \"Rules\": [{
      \"ApplyServerSideEncryptionByDefault\": {
        \"SSEAlgorithm\": \"aws:kms\",
        \"KMSMasterKeyID\": \"$KMS_KEY_ID\"
      },
      \"BucketKeyEnabled\": true
    }]
  }"

# Block all public access

aws s3api put-public-access-block \
  --bucket "$STATE_BUCKET" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "      Bucket ready: s3://$STATE_BUCKET"

# 3. Create DynamoDB table for state locking

echo "[3/5] Creating DynamoDB lock table..."
aws dynamodb create-table \
  --table-name "$DYNAMODB_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$AWS_REGION" \
  --sse-specification Enabled=true,SSEType=KMS,KMSMasterKeyId="$KMS_KEY_ID" > /dev/null

echo "      Table ready: $DYNAMODB_TABLE"

# 4. Enable point-in-time recovery on DynamoDB

echo "[4/5] Enabling DynamoDB PITR..."
aws dynamodb update-continuous-backups \
  --table-name "$DYNAMODB_TABLE" \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
  --region "$AWS_REGION" > /dev/null

# 5. Print next steps

echo "[5/5] Bootstrap complete!"
echo ""
echo "=========================================="
echo "NEXT STEPS:"
echo "=========================================="
echo "1. Create backend.hcl for each environment:"
echo ""
echo "   environments/dev/backend.hcl:"
echo "     bucket         = \"$STATE_BUCKET\""
echo "     key            = \"dev/terraform.tfstate\""
echo "     region         = \"$AWS_REGION\""
echo "     dynamodb_table = \"$DYNAMODB_TABLE\""
echo "     encrypt        = true"
echo ""
echo "   environments/production/backend.hcl:"
echo "     bucket         = \"$STATE_BUCKET\""
echo "     key            = \"production/terraform.tfstate\""
echo "     region         = \"$AWS_REGION\""
echo "     dynamodb_table = \"$DYNAMODB_TABLE\""
echo "     encrypt        = true"
echo ""
echo "2. Init each environment with the backend config:"
echo "   terraform -chdir=environments/dev init -backend-config=backend.hcl"
echo "   terraform -chdir=environments/production init -backend-config=backend.hcl"
echo ""
echo "3. Create terraform.tfvars from the .example file and deploy:"
echo "   cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars"
echo "   # Edit terraform.tfvars with your values"
echo "   terraform -chdir=environments/dev plan -var-file=terraform.tfvars"
echo "   terraform -chdir=environments/dev apply -var-file=terraform.tfvars"
echo "=========================================="

# Optionally auto-generate backend.hcl files

if [ "${AUTO_WRITE_BACKEND:-false}" = "true" ]; then
  echo ""
  echo "Auto-writing backend.hcl files..."

  cat > environments/dev/backend.hcl <<EOF
bucket         = "$STATE_BUCKET"
key            = "dev/terraform.tfstate"
region         = "$AWS_REGION"
dynamodb_table = "$DYNAMODB_TABLE"
encrypt        = true
EOF

  cat > environments/production/backend.hcl <<EOF
bucket         = "$STATE_BUCKET"
key            = "production/terraform.tfstate"
region         = "$AWS_REGION"
dynamodb_table = "$DYNAMODB_TABLE"
encrypt        = true
EOF

  echo "backend.hcl files written. Do NOT commit these to git."
fi
