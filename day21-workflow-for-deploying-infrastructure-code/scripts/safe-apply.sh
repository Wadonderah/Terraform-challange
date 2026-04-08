#!/usr/bin/env bash
# ==============================================================================
# scripts/safe-apply.sh
#
# PURPOSE: Wraps `terraform apply` with the infrastructure safeguards from
# Day 21: state backup verification, plan file pinning, post-apply validation.
#
# USAGE:
#   ./scripts/safe-apply.sh <plan-file> <s3-state-bucket> [workspace]
#
# EXAMPLE:
#   ./scripts/safe-apply.sh day21.tfplan my-terraform-state-bucket dev
#
# This script enforces the principle from the Day 21 notes:
#   "Always apply from a saved plan file — never from a fresh plan."
# ==============================================================================

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Arguments
# ─────────────────────────────────────────────────────────────────────────────

PLAN_FILE="${1:-}"
STATE_BUCKET="${2:-}"
WORKSPACE="${3:-dev}"

if [[ -z "$PLAN_FILE" || -z "$STATE_BUCKET" ]]; then
  echo "❌ Usage: $0 <plan-file> <s3-state-bucket> [workspace]"
  exit 1
fi

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "❌ Plan file '$PLAN_FILE' not found."
  echo "   Run: terraform plan -out=$PLAN_FILE first."
  exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Helper functions
# ─────────────────────────────────────────────────────────────────────────────

log()  { echo "[$(date '+%H:%M:%S')] $*"; }
fail() { echo "❌ $*" >&2; exit 1; }
ok()   { echo "✅ $*"; }

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Verify S3 state bucket has versioning enabled
# A corrupted state file is unrecoverable without versioning.
# ─────────────────────────────────────────────────────────────────────────────

log "Checking S3 state bucket versioning..."

VERSIONING=$(aws s3api get-bucket-versioning \
  --bucket "$STATE_BUCKET" \
  --query 'Status' \
  --output text 2>/dev/null || echo "UNKNOWN")

if [[ "$VERSIONING" != "Enabled" ]]; then
  fail "S3 bucket '$STATE_BUCKET' does NOT have versioning enabled.
       Enable it before applying: aws s3api put-bucket-versioning \\
         --bucket $STATE_BUCKET \\
         --versioning-configuration Status=Enabled"
fi
ok "State bucket versioning: $VERSIONING"

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Record the current state version before apply
# This is your rollback reference — save it.
# ─────────────────────────────────────────────────────────────────────────────

STATE_KEY="${WORKSPACE}/terraform.tfstate"
log "Recording pre-apply state version..."

CURRENT_VERSION=$(aws s3api list-object-versions \
  --bucket "$STATE_BUCKET" \
  --prefix "$STATE_KEY" \
  --query 'Versions[?IsLatest==`true`].VersionId' \
  --output text 2>/dev/null || echo "NONE")

if [[ "$CURRENT_VERSION" == "NONE" || -z "$CURRENT_VERSION" ]]; then
  log "⚠️  No existing state version found (first apply?)."
else
  log "Pre-apply state version: $CURRENT_VERSION"
  echo "$CURRENT_VERSION" > .pre-apply-state-version
  ok "Saved pre-apply state version to .pre-apply-state-version"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Show plan summary and require explicit confirmation
# ─────────────────────────────────────────────────────────────────────────────

log "Showing plan summary..."
terraform show -no-color "$PLAN_FILE" | grep -E "^Plan:|will be (created|destroyed|updated)" | head -20

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Workspace : $WORKSPACE"
echo "  Plan file : $PLAN_FILE"
echo "  State     : s3://$STATE_BUCKET/$STATE_KEY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for destructions — require extra confirmation

DESTROY_COUNT=$(terraform show -json "$PLAN_FILE" 2>/dev/null \
  | jq '[.resource_changes[]?.change.actions[] | select(. == "delete")] | length' \
  2>/dev/null || echo "0")

if [[ "$DESTROY_COUNT" -gt 0 ]]; then
  echo ""
  echo "⚠️  ⚠️  ⚠️  WARNING: This plan DESTROYS $DESTROY_COUNT resource(s)! ⚠️  ⚠️  ⚠️"
  echo ""
  echo "Destroying resources is irreversible (databases, S3 buckets, etc.)."
  echo "Confirm you have a second approver sign-off before proceeding."
  echo ""
  read -r -p "Type 'DESTROY' to confirm you accept the destruction: " DESTROY_CONFIRM
  if [[ "$DESTROY_CONFIRM" != "DESTROY" ]]; then
    fail "Destruction not confirmed. Exiting."
  fi
fi

read -r -p "Apply this plan to workspace '$WORKSPACE'? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  log "Apply cancelled."
  exit 0
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Apply the pinned plan file
# Using the saved plan file ensures exactly what was reviewed is what runs.
# ─────────────────────────────────────────────────────────────────────────────

log "Applying plan: $PLAN_FILE"
START_TIME=$(date +%s)

terraform apply "$PLAN_FILE"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
ok "Apply completed in ${DURATION}s"

# ─────────────────────────────────────────────────────────────────────────────
# Step 5: Post-apply validation — run plan again, expect zero changes
# A non-clean post-apply plan indicates state drift or a bug in your code.
# ─────────────────────────────────────────────────────────────────────────────

log "Running post-apply plan to verify clean state..."
POST_PLAN_OUTPUT=$(terraform plan -detailed-exitcode -no-color 2>&1 || true)
POST_EXIT_CODE=$?

case $POST_EXIT_CODE in
  0)
    ok "Post-apply plan is clean — no unexpected changes. Infrastructure matches code."
    ;;
  2)
    echo ""
    echo "⚠️  WARNING: Post-apply plan shows additional changes!"
    echo "    This means the apply did not fully converge, or there is state drift."
    echo "    Review the following and open an incident if unexpected:"
    echo ""
    echo "$POST_PLAN_OUTPUT" | grep -E "^  [+~-]" | head -20
    ;;
  *)
    fail "Post-apply plan failed with exit code $POST_EXIT_CODE. Check Terraform state."
    ;;
esac

# ─────────────────────────────────────────────────────────────────────────────
# Step 6: Print rollback instructions
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ROLLBACK REFERENCE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ -f ".pre-apply-state-version" ]]; then
  PRE_VERSION=$(cat .pre-apply-state-version)
  echo "  Pre-apply state version: $PRE_VERSION"
  echo ""
  echo "  To restore state to pre-apply version:"
  echo "    aws s3api get-object \\"
  echo "      --bucket $STATE_BUCKET \\"
  echo "      --key $STATE_KEY \\"
  echo "      --version-id $PRE_VERSION \\"
  echo "      terraform.tfstate.backup"
  echo ""
  echo "    # Then: terraform state push terraform.tfstate.backup"
fi
echo ""
log "Done. ✅"
