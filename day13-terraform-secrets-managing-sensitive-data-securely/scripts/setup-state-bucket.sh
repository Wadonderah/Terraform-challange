#!/usr/bin/env bash
# =============================================================================
# setup-state-bucket.sh — One-time S3 state bucket provisioning
# =============================================================================
# Run this ONCE before terraform init.
# Replace BUCKET_NAME below with your chosen unique bucket name.
#
# USAGE:
#   export BUCKET_NAME="yourname-terraform-state-day13"
#   export AWS_DEFAULT_REGION="ap-northeast-2"
#   bash scripts/setup-state-bucket.sh
# =============================================================================

set -euo pipefail

BUCKET_NAME="${BUCKET_NAME:?Set BUCKET_NAME environment variable}"
REGION="${AWS_DEFAULT_REGION:-ap-northeast-2}"

echo "==> Creating state bucket: ${BUCKET_NAME} in ${REGION}"

# 1. Create the bucket
if [ "${REGION}" = "us-east-1" ]; then
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}"
else
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}" \
    --create-bucket-configuration LocationConstraint="${REGION}"
fi

# 2. Enable versioning (required for use_lockfile)
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

# 3. Enable server-side encryption
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# 4. Block all public access
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo ""
echo "✅  Bucket ready: ${BUCKET_NAME}"
echo ""
echo "Now update backend.tf:"
echo "  bucket = \"${BUCKET_NAME}\""
echo "  region = \"${REGION}\""
