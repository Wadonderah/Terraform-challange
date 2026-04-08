#!/usr/bin/env bash
# ==============================================================================
# scripts/verify-compliance.sh
#
# PURPOSE: Verify infrastructure code workflow compliance.
# Checks all required components are in place and properly configured.
#
# USAGE:
#   ./scripts/verify-compliance.sh
# ==============================================================================

set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() {
  echo -e "  ${GREEN}✅${NC} $1"
  ((PASS_COUNT++))
}

fail() {
  echo -e "  ${RED}❌${NC} $1"
  ((FAIL_COUNT++))
}

warn() {
  echo -e "  ${YELLOW}⚠️${NC}  $1"
  ((WARN_COUNT++))
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Infrastructure Code Workflow Compliance Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Check 1: Branch Protection
# ─────────────────────────────────────────────────────────────────────────────

echo "1️⃣  Branch Protection"
echo "─────────────────────────────────────────────────────────"

if command -v gh &> /dev/null; then
  if gh api repos/:owner/:repo/branches/main/protection &> /dev/null; then
    pass "Branch protection enabled on main"
  else
    fail "Branch protection NOT enabled on main"
    echo "     Action: See .github/branch-protection-config.md"
  fi
else
  warn "GitHub CLI not installed - cannot verify branch protection"
  echo "     Install: https://cli.github.com/"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Check 2: Version Tags
# ─────────────────────────────────────────────────────────────────────────────

echo "2️⃣  Release Management"
echo "─────────────────────────────────────────────────────────"

TAG_COUNT=$(git tag -l | grep -c "^v[0-9]" || echo "0")

if [[ "$TAG_COUNT" -gt 0 ]]; then
  LATEST_TAG=$(git tag -l "v*" | sort -V | tail -1)
  pass "Version tags exist (latest: $LATEST_TAG)"
else
  fail "No semantic version tags found"
  echo "     Action: git tag -a 'v1.0.0' -m 'Initial release'"
fi

if [[ -f CHANGELOG.md ]]; then
  pass "CHANGELOG.md exists"
else
  fail "CHANGELOG.md missing"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Check 3: Pre-commit Hooks
# ─────────────────────────────────────────────────────────────────────────────

echo "3️⃣  Pre-commit Hooks"
echo "─────────────────────────────────────────────────────────"

if [[ -f .pre-commit-config.yaml ]]; then
  pass "Pre-commit config exists"
else
  fail "Pre-commit config missing"
fi

if command -v pre-commit &> /dev/null; then
  pass "Pre-commit installed ($(pre-commit --version))"
  
  if [[ -f .git/hooks/pre-commit ]]; then
    pass "Pre-commit hooks installed in repository"
  else
    warn "Pre-commit hooks not installed"
    echo "     Action: pre-commit install"
  fi
else
  fail "Pre-commit not installed"
  echo "     Action: pip install pre-commit"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Check 4: Code Owners
# ─────────────────────────────────────────────────────────────────────────────

echo "4️⃣  Code Ownership"
echo "─────────────────────────────────────────────────────────"

if [[ -f .github/CODEOWNERS ]]; then
  pass "CODEOWNERS file exists"
  
  # Check if it has content
  if [[ $(wc -l < .github/CODEOWNERS) -gt 10 ]]; then
    pass "CODEOWNERS has ownership rules defined"
  else
    warn "CODEOWNERS file is sparse"
  fi
else
  fail "CODEOWNERS file missing"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Check 5: Commit Template
# ─────────────────────────────────────────────────────────────────────────────

echo "5️⃣  Commit Message Standards"
echo "─────────────────────────────────────────────────────────"

if [[ -f .gitmessage ]]; then
  pass "Commit message template exists"
else
  fail "Commit message template missing"
fi

COMMIT_TEMPLATE=$(git config --get commit.template || echo "")
if [[ "$COMMIT_TEMPLATE" == ".gitmessage" ]]; then
  pass "Git configured to use commit template"
else
  warn "Git not configured to use commit template"
  echo "     Action: git config commit.template .gitmessage"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Check 6: CI Pipeline
# ─────────────────────────────────────────────────────────────────────────────

echo "6️⃣  Automated Testing"
echo "─────────────────────────────────────────────────────────"

if [[ -f .github/workflows/terraform-ci.yml ]]; then
  pass "GitHub Actions CI pipeline configured"
  
  # Check for required jobs
  if grep -q "terraform fmt" .github/workflows/terraform-ci.yml; then
    pass "Format check configured"
  fi
  
  if grep -q "terraform validate" .github/workflows/terraform-ci.yml; then
    pass "Validation check configured"
  fi
  
  if grep -q "terraform test" .github/workflows/terraform-ci.yml; then
    pass "Unit tests configured"
  fi
else
  fail "CI pipeline missing"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Check 7: Sentinel Policies
# ─────────────────────────────────────────────────────────────────────────────

echo "7️⃣  Sentinel Policies"
echo "─────────────────────────────────────────────────────────"

if [[ -f sentinel.hcl ]]; then
  pass "Sentinel configuration exists"
  
  POLICY_COUNT=$(grep -c "^policy" sentinel.hcl || echo "0")
  pass "Sentinel policies defined: $POLICY_COUNT"
  
  # Check for specific policies
  if [[ -f sentinel/require-instance-type.sentinel ]]; then
    pass "Instance type policy exists"
  fi
  
  if [[ -f sentinel/cost-estimation.sentinel ]]; then
    pass "Cost estimation policy exists"
  fi
  
  if [[ -f sentinel/require-tags.sentinel ]]; then
    pass "Required tags policy exists"
  fi
  
  if [[ -f sentinel/prevent-public-s3.sentinel ]]; then
    pass "S3 public access policy exists"
  fi
else
  fail "Sentinel configuration missing"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Check 8: Deployment Scripts
# ─────────────────────────────────────────────────────────────────────────────

echo "8️⃣  Deployment Safeguards"
echo "─────────────────────────────────────────────────────────"

if [[ -f scripts/safe-apply.sh ]]; then
  pass "Safe-apply script exists"
  
  if [[ -x scripts/safe-apply.sh ]]; then
    pass "Safe-apply script is executable"
  else
    warn "Safe-apply script not executable"
    echo "     Action: chmod +x scripts/safe-apply.sh"
  fi
else
  fail "Safe-apply script missing"
fi

if [[ -f scripts/list-state-versions.sh ]]; then
  pass "State version listing script exists"
else
  warn "State version listing script missing"
fi

if [[ -f scripts/analyze-blast-radius.sh ]]; then
  pass "Blast radius analysis script exists"
else
  warn "Blast radius analysis script missing"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Check 9: Documentation
# ─────────────────────────────────────────────────────────────────────────────

echo "9️⃣  Documentation"
echo "─────────────────────────────────────────────────────────"

if [[ -f README.md ]]; then
  pass "README.md exists"
  
  if grep -q "terraform plan" README.md; then
    pass "README documents workflow"
  fi
else
  fail "README.md missing"
fi

if [[ -f COMPLIANCE_AUDIT_REPORT.md ]]; then
  pass "Compliance audit report exists"
else
  warn "Compliance audit report missing"
fi

if [[ -f IMPLEMENTATION_GUIDE.md ]]; then
  pass "Implementation guide exists"
else
  warn "Implementation guide missing"
fi

if [[ -f .github/PULL_REQUEST_TEMPLATE/infrastructure_change.md ]]; then
  pass "PR template exists"
else
  fail "PR template missing"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Check 10: Tool Installations
# ─────────────────────────────────────────────────────────────────────────────

echo "🔧 Required Tools"
echo "─────────────────────────────────────────────────────────"

if command -v terraform &> /dev/null; then
  TF_VERSION=$(terraform version -json | jq -r '.terraform_version')
  pass "Terraform installed: v$TF_VERSION"
else
  fail "Terraform not installed"
fi

if command -v tflint &> /dev/null; then
  pass "TFLint installed"
else
  warn "TFLint not installed"
fi

if command -v tfsec &> /dev/null; then
  pass "TFSec installed"
else
  warn "TFSec not installed"
fi

if command -v aws &> /dev/null; then
  pass "AWS CLI installed"
else
  warn "AWS CLI not installed"
fi

if command -v jq &> /dev/null; then
  pass "jq installed"
else
  warn "jq not installed (required for blast radius analysis)"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Compliance Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "  ${GREEN}✅ Passed:${NC}  $PASS_COUNT"
echo -e "  ${YELLOW}⚠️  Warnings:${NC} $WARN_COUNT"
echo -e "  ${RED}❌ Failed:${NC}  $FAIL_COUNT"
echo ""

TOTAL=$((PASS_COUNT + FAIL_COUNT))
if [[ $TOTAL -gt 0 ]]; then
  COMPLIANCE_PERCENT=$((PASS_COUNT * 100 / TOTAL))
  echo "  Compliance Score: $COMPLIANCE_PERCENT%"
  echo ""
fi

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo -e "${GREEN}✅ All critical checks passed!${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Review warnings and address if applicable"
  echo "  2. Ensure branch protection is enabled on GitHub"
  echo "  3. Configure Terraform Cloud workspace settings"
  echo "  4. Train team on new workflow"
  exit 0
else
  echo -e "${RED}❌ Compliance check failed!${NC}"
  echo ""
  echo "Action required:"
  echo "  1. Address all failed checks above"
  echo "  2. Review IMPLEMENTATION_GUIDE.md for remediation steps"
  echo "  3. Re-run this script after fixes"
  exit 1
fi

# Made with Bob
