# Infrastructure Code Workflow - Implementation Guide

This guide provides step-by-step instructions for implementing the missing compliance components identified in the audit report.

## Quick Start

```bash
# 1. Configure git to use commit message template
git config commit.template .gitmessage

# 2. Install pre-commit hooks
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg

# 3. Create initial version tag
git tag -a "v1.0.0" -m "Initial release: webserver-cluster with CloudWatch monitoring"
git push origin v1.0.0

# 4. Configure branch protection (see .github/branch-protection-config.md)
```

---

## Phase 1: Critical Fixes (Week 1)

### Day 1-2: Enable Branch Protection

**Objective:** Prevent direct commits to main branch

**Steps:**

1. **Via GitHub Web UI:**
   - Navigate to repository Settings → Branches
   - Click "Add branch protection rule"
   - Follow configuration in `.github/branch-protection-config.md`

2. **Verify Configuration:**
   ```bash
   # Test that direct push is blocked
   git checkout main
   echo "test" >> test.txt
   git add test.txt
   git commit -m "Test direct push"
   git push origin main
   # Expected: ERROR - protected branch hook declined
   ```

3. **Team Communication:**
   - Announce branch protection is now active
   - Share feature branch workflow documentation
   - Schedule training session for team

**Success Criteria:**
- ✅ Direct pushes to main are blocked
- ✅ All team members aware of new workflow
- ✅ Test PR successfully merged with approvals

---

### Day 3-4: Implement Semantic Versioning

**Objective:** Enable rollback to known-good module versions

**Steps:**

1. **Tag Current State:**
   ```bash
   # Review current state
   git log --oneline -5
   
   # Create v1.0.0 tag
   git tag -a "v1.0.0" -m "Release v1.0.0: webserver-cluster with CloudWatch monitoring
   
   Features:
   - CloudWatch alarms (CPU, ALB 5xx, unhealthy hosts)
   - SNS topic for alerts
   - CloudWatch dashboard
   - Comprehensive unit tests
   - Sentinel policies
   - Safe-apply deployment script"
   
   # Push tag
   git push origin v1.0.0
   ```

2. **Update Module References:**
   ```hcl
   # In consuming repositories, update module source
   module "webserver_cluster" {
     source = "git::https://github.com/your-org/repo.git//modules/webserver-cluster?ref=v1.0.0"
     
     # ... other configuration
   }
   ```

3. **Document Release Process:**
   - Review CHANGELOG.md format
   - Add release process to team runbook
   - Create release checklist template

**Success Criteria:**
- ✅ v1.0.0 tag exists and is pushed
- ✅ CHANGELOG.md is up to date
- ✅ Module consumers reference specific version
- ✅ Release process documented

---

### Day 5: Enforce PR Workflow

**Objective:** All infrastructure changes go through pull request review

**Steps:**

1. **Create Feature Branch Workflow Documentation:**
   ```markdown
   # Feature Branch Workflow
   
   1. Create feature branch: git checkout -b feat-add-monitoring
   2. Make changes and commit with descriptive messages
   3. Run terraform plan and review output
   4. Push branch: git push origin feat-add-monitoring
   5. Create PR using infrastructure_change.md template
   6. Wait for CI checks to pass
   7. Request review from infrastructure team
   8. Address review comments
   9. Merge after approval
   ```

2. **Audit Recent Commits:**
   ```bash
   # List commits that bypassed PR process
   git log --oneline --first-parent main -20
   
   # Document each commit's changes retroactively
   # Create tracking issue for each undocumented change
   ```

3. **Team Training:**
   - Walk through PR template sections
   - Demonstrate terraform plan output in PR
   - Show blast radius documentation examples
   - Practice rollback procedures

**Success Criteria:**
- ✅ All team members trained on PR workflow
- ✅ Recent commits documented retroactively
- ✅ First compliant PR merged successfully
- ✅ Zero direct commits to main after training

---

## Phase 2: High Priority (Week 2-3)

### Week 2: Deploy Pre-commit Hooks

**Objective:** Catch issues before commit, not in CI

**Steps:**

1. **Install Pre-commit Framework:**
   ```bash
   # Install pre-commit
   pip install pre-commit
   
   # Install hooks in repository
   pre-commit install
   pre-commit install --hook-type commit-msg
   
   # Test hooks
   pre-commit run --all-files
   ```

2. **Configure TFLint:**
   ```bash
   # Install tflint
   curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
   
   # Initialize tflint plugins
   tflint --init
   
   # Test tflint
   tflint --config=.tflint.hcl
   ```

3. **Team Rollout:**
   ```bash
   # Create setup script for team
   cat > scripts/setup-dev-environment.sh << 'EOF'
   #!/bin/bash
   echo "Setting up development environment..."
   
   # Install pre-commit
   pip install pre-commit
   pre-commit install
   pre-commit install --hook-type commit-msg
   
   # Configure git commit template
   git config commit.template .gitmessage
   
   # Install tflint
   curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
   tflint --init
   
   echo "✅ Development environment ready!"
   EOF
   
   chmod +x scripts/setup-dev-environment.sh
   ```

**Success Criteria:**
- ✅ Pre-commit hooks installed on all developer machines
- ✅ Hooks catch formatting/validation issues before commit
- ✅ Team comfortable with hook workflow
- ✅ Setup script available for new team members

---

### Week 2: Configure Terraform Cloud Apply Approvals

**Objective:** Require manual approval for all applies

**Steps:**

1. **Configure Workspace Settings:**
   - Log into Terraform Cloud
   - Navigate to workspace settings
   - Enable "Manual Apply" under "Apply Method"
   - Configure notification settings

2. **Set Up Approval Policies:**
   ```hcl
   # In Terraform Cloud workspace settings
   # Execution Mode: Remote
   # Apply Method: Manual
   # Auto Apply: Disabled
   
   # For production workspaces:
   # Require 2 approvals for plans with destructions
   ```

3. **Test Approval Workflow:**
   ```bash
   # Create test change
   git checkout -b test-approval-workflow
   # Make minor change
   git commit -m "test: verify approval workflow"
   git push origin test-approval-workflow
   
   # Create PR, wait for plan
   # Verify manual approval required in Terraform Cloud
   # Test approval process
   ```

**Success Criteria:**
- ✅ All workspaces require manual apply approval
- ✅ Approval workflow tested and documented
- ✅ Team trained on approval process
- ✅ Notification webhooks configured

---

### Week 3: Create CODEOWNERS and Enforce Reviews

**Objective:** Route PRs to appropriate reviewers automatically

**Steps:**

1. **CODEOWNERS Already Created:** `.github/CODEOWNERS`

2. **Update Branch Protection:**
   - Enable "Require review from Code Owners"
   - Test with sample PR

3. **Define Team Structure:**
   ```bash
   # In GitHub organization settings, create teams:
   # - infrastructure-team (all infrastructure engineers)
   # - infrastructure-leads (senior engineers)
   # - devops-team (CI/CD specialists)
   # - module-maintainers (module owners)
   ```

4. **Document Review Expectations:**
   ```markdown
   # Code Review Guidelines for Infrastructure
   
   ## What to Review:
   - [ ] Terraform plan output shows expected changes
   - [ ] Resource counts match description
   - [ ] No unexpected destructions
   - [ ] Blast radius documented and acceptable
   - [ ] Rollback plan is clear and feasible
   - [ ] Tests pass and cover new functionality
   - [ ] Documentation updated
   - [ ] Commit messages follow template
   
   ## Approval Criteria:
   - Standard changes: 1 approval from infrastructure-team
   - Destructive changes: 2 approvals (1 from infrastructure-leads)
   - Sentinel policy changes: 1 approval from infrastructure-leads
   - CI/CD changes: 1 approval from devops-team
   ```

**Success Criteria:**
- ✅ CODEOWNERS file active and routing correctly
- ✅ GitHub teams configured
- ✅ Review guidelines documented
- ✅ Team trained on review expectations

---

## Phase 3: Enhancements (Week 4-6)

### Week 4: Implement Commit Message Template

**Objective:** Standardize commit message format

**Steps:**

1. **Template Already Created:** `.gitmessage`

2. **Configure Git Globally:**
   ```bash
   # For all team members
   git config commit.template .gitmessage
   
   # Verify configuration
   git config --get commit.template
   ```

3. **Enforce via Pre-commit Hook:**
   - Conventional commits hook already in `.pre-commit-config.yaml`
   - Validates commit message format

4. **Create Examples:**
   ```bash
   # Good commit message example
   git commit
   # Opens editor with template, fill in:
   
   infra: Add CloudWatch alarms to webserver cluster
   
   ## What Changed
   - Added 4 CloudWatch alarms for CPU and ALB metrics
   - Created SNS topic for alert notifications
   - Deployed CloudWatch dashboard for cluster visibility
   
   ## Terraform Plan Summary
   Created: 7 | Modified: 0 | Destroyed: 0
   
   ## Blast Radius
   - All changes are additive (no modifications to existing resources)
   - If apply fails after SNS topic creation, orphaned topic can be cleaned up
   - No production traffic affected
   
   ## Testing
   - [x] terraform fmt passed
   - [x] terraform validate passed
   - [x] terraform plan reviewed
   - [x] Unit tests passed
   
   Closes #123
   ```

**Success Criteria:**
- ✅ All developers using commit template
- ✅ Commit messages include plan summary
- ✅ Blast radius documented in commits
- ✅ Pre-commit hook validates format

---

### Week 5: Automate Blast Radius Detection

**Objective:** Automatically identify affected resources

**Steps:**

1. **Install Terraform Graph Tools:**
   ```bash
   # Option 1: terraform-graph
   go install github.com/pcasteran/terraform-graph@latest
   
   # Option 2: Rover (recommended)
   brew install rover
   ```

2. **Create Blast Radius Script:**
   ```bash
   cat > scripts/analyze-blast-radius.sh << 'EOF'
   #!/bin/bash
   # Analyze blast radius of terraform changes
   
   set -euo pipefail
   
   PLAN_FILE="${1:-terraform.tfplan}"
   
   if [[ ! -f "$PLAN_FILE" ]]; then
     echo "❌ Plan file not found: $PLAN_FILE"
     exit 1
   fi
   
   echo "🔍 Analyzing blast radius..."
   
   # Extract resource changes
   terraform show -json "$PLAN_FILE" | jq -r '
     .resource_changes[] |
     select(.change.actions != ["no-op"]) |
     "\(.type).\(.name): \(.change.actions | join(","))"
   '
   
   # Generate dependency graph
   terraform graph | dot -Tpng > blast-radius.png
   echo "✅ Dependency graph saved to blast-radius.png"
   
   # Identify shared resources
   echo ""
   echo "⚠️  Shared resources affected:"
   terraform show -json "$PLAN_FILE" | jq -r '
     .resource_changes[] |
     select(.type | test("aws_vpc|aws_security_group|aws_iam_role|aws_subnet")) |
     select(.change.actions != ["no-op"]) |
     "  - \(.type).\(.name)"
   '
   EOF
   
   chmod +x scripts/analyze-blast-radius.sh
   ```

3. **Integrate into CI:**
   ```yaml
   # Add to .github/workflows/terraform-ci.yml
   - name: Analyze blast radius
     run: |
       ./scripts/analyze-blast-radius.sh ci.tfplan
       # Upload graph as artifact
     if: always()
   ```

**Success Criteria:**
- ✅ Blast radius script working
- ✅ Dependency graphs generated automatically
- ✅ Shared resources flagged in CI
- ✅ Graphs attached to PRs

---

### Week 6: Enhanced Sentinel Policies

**Objective:** Add additional compliance policies

**Steps:**

1. **Create Required Tags Policy:**
   ```hcl
   # sentinel/require-tags.sentinel
   import "tfplan/v2" as tfplan
   
   required_tags = ["Environment", "Owner", "CostCenter", "Project"]
   
   all_resources = filter tfplan.resource_changes as _, rc {
     rc.mode is "managed" and
     (rc.change.actions contains "create" or rc.change.actions contains "update")
   }
   
   tags_present = rule {
     all all_resources as _, resource {
       all required_tags as _, tag {
         resource.change.after.tags[tag] exists
       }
     }
   }
   
   main = rule {
     tags_present
   }
   ```

2. **Create S3 Public Access Policy:**
   ```hcl
   # sentinel/prevent-public-s3.sentinel
   import "tfplan/v2" as tfplan
   
   s3_buckets = filter tfplan.resource_changes as _, rc {
     rc.type is "aws_s3_bucket" and
     (rc.change.actions contains "create" or rc.change.actions contains "update")
   }
   
   no_public_buckets = rule {
     all s3_buckets as _, bucket {
       bucket.change.after.acl is not "public-read" and
       bucket.change.after.acl is not "public-read-write"
     }
   }
   
   main = rule {
     no_public_buckets
   }
   ```

3. **Update sentinel.hcl:**
   ```hcl
   policy "require-tags" {
     source            = "./sentinel/require-tags.sentinel"
     enforcement_level = "soft-mandatory"
   }
   
   policy "prevent-public-s3" {
     source            = "./sentinel/prevent-public-s3.sentinel"
     enforcement_level = "hard-mandatory"
   }
   ```

**Success Criteria:**
- ✅ New policies deployed to Terraform Cloud
- ✅ Policies tested with sample plans
- ✅ Team trained on new requirements
- ✅ Documentation updated

---

## Verification Checklist

After completing all phases, verify compliance:

```bash
# Run comprehensive compliance check
cat > scripts/verify-compliance.sh << 'EOF'
#!/bin/bash

echo "🔍 Infrastructure Code Workflow Compliance Check"
echo "================================================"

# Check 1: Branch protection
echo "✓ Checking branch protection..."
gh api repos/:owner/:repo/branches/main/protection > /dev/null 2>&1 && \
  echo "  ✅ Branch protection enabled" || \
  echo "  ❌ Branch protection NOT enabled"

# Check 2: Version tags
echo "✓ Checking version tags..."
git tag -l | grep -q "v[0-9]" && \
  echo "  ✅ Version tags exist" || \
  echo "  ❌ No version tags found"

# Check 3: Pre-commit hooks
echo "✓ Checking pre-commit hooks..."
[ -f .pre-commit-config.yaml ] && \
  echo "  ✅ Pre-commit config exists" || \
  echo "  ❌ Pre-commit config missing"

# Check 4: CODEOWNERS
echo "✓ Checking CODEOWNERS..."
[ -f .github/CODEOWNERS ] && \
  echo "  ✅ CODEOWNERS file exists" || \
  echo "  ❌ CODEOWNERS file missing"

# Check 5: Commit template
echo "✓ Checking commit template..."
[ -f .gitmessage ] && \
  echo "  ✅ Commit template exists" || \
  echo "  ❌ Commit template missing"

# Check 6: CHANGELOG
echo "✓ Checking CHANGELOG..."
[ -f CHANGELOG.md ] && \
  echo "  ✅ CHANGELOG.md exists" || \
  echo "  ❌ CHANGELOG.md missing"

# Check 7: CI pipeline
echo "✓ Checking CI pipeline..."
[ -f .github/workflows/terraform-ci.yml ] && \
  echo "  ✅ CI pipeline configured" || \
  echo "  ❌ CI pipeline missing"

# Check 8: Sentinel policies
echo "✓ Checking Sentinel policies..."
[ -f sentinel.hcl ] && \
  echo "  ✅ Sentinel policies configured" || \
  echo "  ❌ Sentinel policies missing"

echo ""
echo "================================================"
echo "Compliance check complete!"
EOF

chmod +x scripts/verify-compliance.sh
./scripts/verify-compliance.sh
```

---

## Troubleshooting

### Pre-commit Hooks Failing

```bash
# Skip hooks temporarily (emergency only)
git commit --no-verify

# Update hooks
pre-commit autoupdate

# Clear cache
pre-commit clean
```

### Branch Protection Blocking Emergency Fix

```bash
# Temporarily disable (document in incident report)
gh api repos/:owner/:repo/branches/main/protection --method DELETE

# Make emergency change

# Re-enable immediately
# Follow .github/branch-protection-config.md
```

### Terraform Cloud Apply Stuck

```bash
# Check workspace status
terraform workspace show

# View pending runs
# Log into Terraform Cloud UI

# Cancel stuck run (if safe)
# Requires workspace admin permissions
```

---

## Maintenance

### Monthly Tasks
- [ ] Review compliance metrics
- [ ] Audit recent PRs for template usage
- [ ] Check pre-commit hook adoption rate
- [ ] Review Sentinel policy violations

### Quarterly Tasks
- [ ] Update allowed instance types in Sentinel
- [ ] Review and adjust cost thresholds
- [ ] Audit CODEOWNERS accuracy
- [ ] Update training materials

### Annual Tasks
- [ ] Comprehensive workflow audit
- [ ] Update compliance requirements
- [ ] Review and update policies
- [ ] Team training refresh

---

## Support

- **Documentation:** See README.md and COMPLIANCE_AUDIT_REPORT.md
- **Questions:** #infrastructure-team Slack channel
- **Issues:** Create GitHub issue with `compliance` label
- **Training:** Schedule with infrastructure-leads team

---

**Last Updated:** 2026-04-08  
**Version:** 1.0.0  
**Owner:** Infrastructure Team