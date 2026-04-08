#!/usr/bin/env bash
# ==============================================================================
# scripts/analyze-blast-radius.sh
#
# PURPOSE: Automatically analyze the blast radius of Terraform changes.
# Identifies affected resources, shared dependencies, and potential impact.
#
# USAGE:
#   terraform plan -out=plan.tfplan
#   ./scripts/analyze-blast-radius.sh plan.tfplan
# ==============================================================================

set -euo pipefail

PLAN_FILE="${1:-terraform.tfplan}"

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "❌ Plan file not found: $PLAN_FILE"
  echo "Usage: $0 <plan-file>"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 BLAST RADIUS ANALYSIS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Extract resource change summary
# ─────────────────────────────────────────────────────────────────────────────

echo "📊 Resource Change Summary"
echo "─────────────────────────────────────────────────────────"

PLAN_JSON=$(terraform show -json "$PLAN_FILE")

CREATED=$(echo "$PLAN_JSON" | jq '[.resource_changes[] | select(.change.actions == ["create"])] | length')
UPDATED=$(echo "$PLAN_JSON" | jq '[.resource_changes[] | select(.change.actions == ["update"])] | length')
REPLACED=$(echo "$PLAN_JSON" | jq '[.resource_changes[] | select(.change.actions == ["delete", "create"])] | length')
DESTROYED=$(echo "$PLAN_JSON" | jq '[.resource_changes[] | select(.change.actions == ["delete"])] | length')

echo "  Created:   $CREATED"
echo "  Updated:   $UPDATED"
echo "  Replaced:  $REPLACED"
echo "  Destroyed: $DESTROYED"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# List all affected resources
# ─────────────────────────────────────────────────────────────────────────────

echo "📋 Affected Resources"
echo "─────────────────────────────────────────────────────────"

echo "$PLAN_JSON" | jq -r '
  .resource_changes[] |
  select(.change.actions != ["no-op"]) |
  "  \(.change.actions | join(",") | ascii_upcase): \(.type).\(.name)"
' | sort

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Identify shared/critical resources
# ─────────────────────────────────────────────────────────────────────────────

echo "⚠️  Shared/Critical Resources"
echo "─────────────────────────────────────────────────────────"

SHARED_RESOURCES=$(echo "$PLAN_JSON" | jq -r '
  .resource_changes[] |
  select(.change.actions != ["no-op"]) |
  select(.type | test("aws_vpc|aws_security_group|aws_iam_role|aws_subnet|aws_route_table|aws_internet_gateway|aws_nat_gateway")) |
  "  ⚠️  \(.type).\(.name) - \(.change.actions | join(","))"
')

if [[ -n "$SHARED_RESOURCES" ]]; then
  echo "$SHARED_RESOURCES"
  echo ""
  echo "  ⚠️  These resources may affect multiple services/environments!"
  echo "  ⚠️  Verify downstream dependencies before applying."
else
  echo "  ✅ No shared infrastructure resources affected"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Identify stateful resources
# ─────────────────────────────────────────────────────────────────────────────

echo "💾 Stateful Resources"
echo "─────────────────────────────────────────────────────────"

STATEFUL_RESOURCES=$(echo "$PLAN_JSON" | jq -r '
  .resource_changes[] |
  select(.change.actions != ["no-op"]) |
  select(.type | test("aws_db_instance|aws_rds_cluster|aws_s3_bucket|aws_dynamodb_table|aws_elasticache_cluster|aws_efs_file_system")) |
  "  💾 \(.type).\(.name) - \(.change.actions | join(","))"
')

if [[ -n "$STATEFUL_RESOURCES" ]]; then
  echo "$STATEFUL_RESOURCES"
  echo ""
  echo "  ⚠️  DANGER: These resources contain data!"
  echo "  ⚠️  Ensure backups exist before applying destructive changes."
else
  echo "  ✅ No stateful resources affected"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Check for destructions
# ─────────────────────────────────────────────────────────────────────────────

if [[ "$DESTROYED" -gt 0 ]] || [[ "$REPLACED" -gt 0 ]]; then
  echo "🚨 DESTRUCTIVE CHANGES DETECTED"
  echo "─────────────────────────────────────────────────────────"
  
  echo "$PLAN_JSON" | jq -r '
    .resource_changes[] |
    select(.change.actions | contains(["delete"])) |
    "  🚨 \(.type).\(.name) will be DESTROYED"
  '
  
  echo ""
  echo "  ⚠️  REQUIRED ACTIONS:"
  echo "  1. Obtain secondary approval from infrastructure-leads"
  echo "  2. Verify backups/snapshots exist for stateful resources"
  echo "  3. Document rollback plan in PR"
  echo "  4. Type 'DESTROY' when prompted by safe-apply.sh"
  echo ""
fi

# ─────────────────────────────────────────────────────────────────────────────
# Generate dependency graph
# ─────────────────────────────────────────────────────────────────────────────

echo "📊 Dependency Graph"
echo "─────────────────────────────────────────────────────────"

if command -v dot &> /dev/null; then
  terraform graph | dot -Tpng > blast-radius-graph.png 2>/dev/null || true
  if [[ -f blast-radius-graph.png ]]; then
    echo "  ✅ Dependency graph saved to: blast-radius-graph.png"
  else
    echo "  ⚠️  Could not generate graph (this is normal if no resources)"
  fi
else
  echo "  ⚠️  Graphviz not installed. Install with: brew install graphviz"
  echo "     Graph generation skipped."
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Estimate downtime/impact
# ─────────────────────────────────────────────────────────────────────────────

echo "⏱️  Impact Assessment"
echo "─────────────────────────────────────────────────────────"

# Check for resources that cause downtime
DOWNTIME_RESOURCES=$(echo "$PLAN_JSON" | jq -r '
  .resource_changes[] |
  select(.change.actions | contains(["delete", "create"])) |
  select(.type | test("aws_instance|aws_autoscaling_group|aws_lb|aws_db_instance|aws_elasticache_cluster")) |
  .type
' | wc -l)

if [[ "$DOWNTIME_RESOURCES" -gt 0 ]]; then
  echo "  ⚠️  Potential downtime: $DOWNTIME_RESOURCES compute/database resources will be replaced"
  echo "  ⚠️  Plan maintenance window and notify stakeholders"
else
  echo "  ✅ No expected downtime (changes are additive or in-place updates)"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Rollback complexity
# ─────────────────────────────────────────────────────────────────────────────

echo "🔄 Rollback Complexity"
echo "─────────────────────────────────────────────────────────"

if [[ "$DESTROYED" -gt 0 ]]; then
  echo "  🔴 HIGH - Destructive changes cannot be automatically rolled back"
  echo "     Rollback requires: State restore + manual resource recreation"
elif [[ "$REPLACED" -gt 0 ]]; then
  echo "  🟡 MEDIUM - Resource replacements require careful rollback"
  echo "     Rollback method: git revert + terraform apply previous plan"
elif [[ "$UPDATED" -gt 0 ]]; then
  echo "  🟢 LOW - In-place updates can be rolled back easily"
  echo "     Rollback method: git revert + terraform apply"
else
  echo "  🟢 MINIMAL - Only additions, rollback is straightforward"
  echo "     Rollback method: terraform destroy new resources"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Recommendations
# ─────────────────────────────────────────────────────────────────────────────

echo "💡 Recommendations"
echo "─────────────────────────────────────────────────────────"

if [[ "$DESTROYED" -gt 0 ]] || [[ "$REPLACED" -gt 0 ]]; then
  echo "  1. ⚠️  Obtain secondary approval (infrastructure-leads)"
  echo "  2. 📸 Create snapshots/backups of stateful resources"
  echo "  3. 📝 Document detailed rollback plan in PR"
  echo "  4. 🔔 Notify stakeholders of maintenance window"
  echo "  5. 🧪 Test rollback procedure in dev environment first"
elif [[ "$CREATED" -gt 5 ]] || [[ "$UPDATED" -gt 10 ]]; then
  echo "  1. 📊 Large change detected - consider breaking into smaller PRs"
  echo "  2. 🧪 Test in dev environment before production"
  echo "  3. 📝 Document all new resources in PR description"
else
  echo "  ✅ Change appears safe - standard review process applies"
  echo "  1. 👀 Have infrastructure team member review plan output"
  echo "  2. ✅ Ensure all CI checks pass"
  echo "  3. 🚀 Apply during normal business hours"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Analysis complete. Include this output in your PR description."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Made with Bob
