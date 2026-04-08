#!/usr/bin/env bash
# ==============================================================================
# scripts/list-state-versions.sh
#
# PURPOSE: List available S3 state versions so you can identify the version
# to restore from if an apply corrupts the state.
#
# USAGE:
#   ./scripts/list-state-versions.sh <s3-bucket> [workspace] [limit]
#
# EXAMPLE:
#   ./scripts/list-state-versions.sh my-terraform-state-bucket production 10
# ==============================================================================

set -euo pipefail

BUCKET="${1:-}"
WORKSPACE="${2:-dev}"
LIMIT="${3:-10}"

if [[ -z "$BUCKET" ]]; then
  echo "Usage: $0 <s3-bucket> [workspace] [limit]"
  exit 1
fi

STATE_KEY="${WORKSPACE}/terraform.tfstate"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  State versions for: s3://$BUCKET/$STATE_KEY"
echo "  Showing last $LIMIT versions (newest first)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

aws s3api list-object-versions \
  --bucket "$BUCKET" \
  --prefix "$STATE_KEY" \
  --query "reverse(sort_by(Versions, &LastModified))[0:${LIMIT}].{VersionId:VersionId,LastModified:LastModified,Size:Size,IsLatest:IsLatest}" \
  --output table

echo ""
echo "To restore a specific version:"
echo "  aws s3api get-object \\"
echo "    --bucket $BUCKET \\"
echo "    --key $STATE_KEY \\"
echo "    --version-id <VERSION_ID> \\"
echo "    terraform.tfstate.restored"
echo ""
echo "  terraform state push terraform.tfstate.restored"
