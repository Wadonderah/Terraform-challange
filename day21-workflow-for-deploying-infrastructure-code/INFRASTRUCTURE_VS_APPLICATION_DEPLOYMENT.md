# Infrastructure vs Application Deployment: Critical Differences

## Executive Summary

This document maps the seven-step application deployment workflow to infrastructure code deployment, identifying the **critical differences** that make infrastructure deployments fundamentally more dangerous and require additional safeguards.

**Core Insight:** A bad application deploy returns 500 errors and can be rolled back in seconds. A bad infrastructure deploy destroys databases, corrupts state files, and may be **unrecoverable**.

---

## The Seven-Step Workflow Comparison

### Step 1: Version Control

| Aspect | Application Code | Infrastructure Code |
|--------|------------------|---------------------|
| **What's versioned** | Source code, configs | HCL files + state file references |
| **Branch protection** | Require 1 approval | Require 1 approval + **mandatory status checks** |
| **Merge strategy** | Squash/rebase acceptable | **Preserve commit history** for audit trail |
| **Direct commits** | Blocked | **ABSOLUTELY BLOCKED** - no exceptions |
| **Rollback method** | Redeploy previous image | **State restoration + reverse apply** (may be impossible) |

**Infrastructure-Specific Safeguards:**
- ✅ Branch protection must include **passing terraform plan** as required status check
- ✅ Commit messages must include **resource counts** (created/modified/destroyed)
- ✅ All commits must document **blast radius**
- ✅ Destructive changes require **second explicit approval** separate from PR review

**Why Different:** Git history is your audit trail for compliance. Infrastructure changes are **stateful** - you can't just revert a commit if it destroyed a database.

---

### Step 2: Run Locally (terraform plan)

| Aspect | Application Code | Infrastructure Code |
|--------|------------------|---------------------|
| **Local execution** | Run binary/server | `terraform plan` against **remote state** |
| **What you're reviewing** | Code behavior | **Plan output** showing exact resource changes |
| **State dependency** | Stateless (usually) | **Stateful** - plan depends on current state |
| **Drift detection** | N/A | Plan shows **unexpected changes** from manual modifications |
| **Plan file** | N/A | **MUST save with -out flag** for exact execution guarantee |

**Infrastructure-Specific Safeguards:**
```bash
# ✅ CORRECT - Save plan for exact execution
terraform workspace select dev
terraform plan -out=day21.tfplan

# ❌ WRONG - Ephemeral plan, may differ at apply time
terraform plan
```

**Critical Difference:** The gap between `plan` and `apply` can be minutes or hours. Another engineer's merge, AWS-side changes, or drift can cause the apply to execute a **different plan** than what was reviewed.

**Plan File Pinning Rule:** Never run `terraform apply` without an explicitly saved and reviewed plan file. The saved plan is cryptographically signed - it guarantees exact execution.

---

### Step 3: Make Code Changes

| Aspect | Application Code | Infrastructure Code |
|--------|------------------|---------------------|
| **Change scope** | Feature/bugfix | **Resource lifecycle changes** |
| **Testing locally** | Unit tests, local server | **terraform validate + plan** |
| **Blast radius** | Service errors | **Data loss, cascading failures** |
| **Rollback complexity** | Redeploy (seconds) | **State restoration** (minutes to hours, may fail) |

**Infrastructure-Specific Safeguards:**
- ✅ Run `terraform plan` on **final committed state**, not mid-edit
- ✅ Analyze plan output for **unexpected changes** (drift)
- ✅ Document **what breaks** if apply fails at each step
- ✅ Verify **no shared resource modifications** without team approval

**Commit Message Template Requirements:**
```
infra: Add CloudWatch alarms to webserver cluster

## What Changed
- Added 4 CloudWatch alarms for CPU and ALB metrics
- Created SNS topic for alert notifications

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


### Step 4: Submit for Review (Pull Request)

| Aspect | Application Code | Infrastructure Code |
|--------|------------------|---------------------|
| **Review artifact** | Code diff | **Terraform plan output** (the diff) |
| **What reviewer sees** | Code changes | **Exact resource changes** with before/after values |
| **Approval criteria** | Code quality | **Blast radius acceptability** |
| **Required documentation** | Feature description | **Plan output + blast radius + rollback plan** |

**Infrastructure-Specific PR Requirements:**

```markdown
## Terraform Plan Output
[REQUIRED - Full plan output here]

Plan: 7 to add, 0 to change, 0 to destroy.

## Resource Impact Summary
- **Created:** 7 (4 alarms, 1 SNS topic, 1 subscription, 1 dashboard)
- **Modified:** 0
- **Destroyed:** 0

## Blast Radius Analysis
**Affected Environments:** dev only
**Downstream Dependencies:** None - all new resources
**Failure Scenarios:**
- If apply fails after SNS topic creation: Orphaned topic (cleanup: terraform destroy)
- If apply fails after alarm creation: Partial monitoring (safe - no traffic impact)
**Production Impact:** NONE - dev environment only

## Rollback Procedure
1. `git revert <merge-commit-sha>`
2. Create new PR with revert
3. Merge and apply
4. Verify with `terraform plan` (should show destruction of created resources)
5. Alternative: Restore state from pre-apply version (see .pre-apply-state-version)

## Shared Resource Changes
- [ ] VPC modifications: NO
- [ ] Security group changes: NO
- [ ] IAM role changes: NO
- [ ] Shared module updates: NO
```

**Critical Difference:** The reviewer MUST see the plan output. Code diff alone is insufficient - Terraform's computed values, data sources, and conditionals mean the code diff doesn't show what will actually happen.

---

### Step 5: Automated Tests

| Check | Application Code | Infrastructure Code | Why Different |
|-------|------------------|---------------------|---------------|
| **Format** | Linter (eslint, etc.) | `terraform fmt --check` | HCL-specific formatting |
| **Syntax** | Compiler | `terraform validate` | Catches HCL errors, missing vars |
| **Linting** | Language-specific | `tflint` | **Provider-aware** rules (AWS-specific) |
| **Security** | SAST tools | `tfsec` | **Infrastructure-specific** (open ports, encryption) |
| **Plan** | N/A | `terraform plan` | **THE CRITICAL CHECK** - shows exact changes |
| **Unit tests** | Jest, pytest, etc. | `terraform test` | Tests resource configuration |
| **Integration tests** | API tests | **Actual AWS resources** | Real infrastructure, real cost |

**Infrastructure-Specific CI Pipeline:**

```yaml
jobs:
  fmt:
    - terraform fmt -check -recursive
  
  validate:
    - terraform init -backend=false
    - terraform validate
  
  tflint:
    - tflint --init
    - tflint --format=compact
  
  tfsec:
    - tfsec . --soft-fail=false  # FAIL on HIGH/CRITICAL
  
  plan:
    - terraform plan -out=ci.tfplan
    - Post plan output as PR comment  # CRITICAL - reviewer must see this
  
  test:
    - terraform test  # Unit tests for resource config
```

**Critical Difference:** `terraform plan` in CI is **not optional** - it's the primary review artifact. The plan output must be posted to the PR so reviewers can see exact changes without running anything locally.

### Step 6: Merge and Release

| Aspect | Application Code | Infrastructure Code |
|--------|------------------|---------------------|
| **Versioning** | Artifact/image tag | **Module source `?ref=v1.4.0`** |
| **Release artifact** | Docker image, binary | **Git tag + CHANGELOG** |
| **Rollback target** | Previous image | **Previous module version** |
| **Deployment timing** | Immediate after merge | **Delayed** - requires explicit apply |

**Infrastructure-Specific Release Process:**

```bash
# 1. Merge PR to main
git checkout main
git pull

# 2. Tag the module version (semantic versioning)
git tag -a "v1.4.0" -m "Add CloudWatch alarms and dashboard

Features:
- CPU high/low alarms
- ALB 5xx error alarm
- Unhealthy host alarm
- SNS topic for alerts
- CloudWatch dashboard

Breaking Changes: None
Migration: None required"

git push origin v1.4.0

# 3. Update CHANGELOG.md
cat >> CHANGELOG.md << EOF
## [1.4.0] - 2026-04-08

### Added
- CloudWatch alarms for CPU utilization (high/low thresholds)
- ALB 5xx error rate alarm
- Unhealthy host count alarm
- SNS topic with email subscription for alerts
- CloudWatch dashboard with CPU and ALB metrics

### Changed
- None

### Deprecated
- None

### Removed
- None

### Fixed
- None

### Security
- SNS topic encrypted with AWS-managed KMS key
EOF

# 4. Update consuming modules to reference new version
# In other repositories:
module "webserver_cluster" {
  source = "git::https://github.com/org/repo.git//modules/webserver-cluster?ref=v1.4.0"
  # ... configuration
}
```

**Critical Difference:** Infrastructure modules are versioned separately from deployments. You tag the module code, then consuming environments explicitly upgrade by changing their `source` reference.

---

### Step 7: Deploy (terraform apply)

| Aspect | Application Code | Infrastructure Code |
|--------|------------------|---------------------|
| **Deployment method** | Push image, restart service | **terraform apply <plan-file>** |
| **Execution guarantee** | Image is immutable | **Plan file pins exact execution** |
| **State management** | Stateless | **State file is source of truth** |
| **Failure impact** | 500 errors, retry | **Partial infrastructure, corrupted state** |
| **Rollback** | Redeploy previous image (seconds) | **State restoration + reverse apply** (complex) |
| **Verification** | Health checks | **Post-apply plan must show "No changes"** |

**Infrastructure-Specific Apply Process:**

```bash
# NEVER do this - fresh plan may differ from reviewed plan
# ❌ terraform apply

# ALWAYS use saved plan file
# ✅ Use safe-apply script with all safeguards
./scripts/safe-apply.sh day21.tfplan my-terraform-state-bucket dev
```

**What safe-apply.sh Does:**

1. **Verify S3 state bucket versioning enabled** (rollback requirement)
2. **Record pre-apply state version** (rollback reference)
3. **Show plan summary** with resource counts
4. **Detect destructions** - require typing "DESTROY" for confirmation
5. **Apply the pinned plan file** (exact execution of reviewed plan)
6. **Post-apply validation** - run `terraform plan` again, expect "No changes"
7. **Print rollback instructions** with exact state version

**Critical Safeguards:**

```bash
# 1. State Backup Verification
aws s3api get-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --query 'Status'
# Expected: "Enabled"

# 2. Record Pre-Apply State Version
aws s3api list-object-versions \
  --bucket my-terraform-state-bucket \
  --prefix dev/terraform.tfstate \
  --query 'Versions[?IsLatest==`true`].VersionId' \
  --output text
# Save this - it's your rollback point

# 3. Apply with Saved Plan
terraform apply day21.tfplan

# 4. Post-Apply Validation (CRITICAL)
terraform plan
# MUST show: Plan: 0 to add, 0 to change, 0 to destroy.
# If it shows changes, you have state drift or a bug

# 5. Verify in AWS Console
# Check resources actually exist and are configured correctly
```

**State Restoration Procedure:**

```bash
# If apply corrupts state or you need to rollback:

# 1. Get pre-apply state version (from .pre-apply-state-version file)
PRE_VERSION=$(cat .pre-apply-state-version)

# 2. Download that version
aws s3api get-object \
  --bucket my-terraform-state-bucket \
  --key dev/terraform.tfstate \
  --version-id $PRE_VERSION \
  terraform.tfstate.restored

# 3. Push restored state
terraform state push terraform.tfstate.restored

# 4. Verify restoration
terraform plan
# Should show the changes you're rolling back
```

---

## Infrastructure-Specific Safeguards Summary

### 1. Mandatory Apply Approval Gates

**Terraform Cloud Configuration:**
- Any plan showing `actions: ["delete"]` triggers **mandatory apply approval**
- Separate from PR review - requires explicit "Confirm & Apply" in Terraform Cloud UI
- Cannot be bypassed (hard-mandatory enforcement)

**Local Enforcement:**
```bash
# safe-apply.sh detects destructions and requires explicit confirmation
DESTROY_COUNT=$(terraform show -json plan.tfplan | jq '[.resource_changes[]?.change.actions[] | select(. == "delete")] | length')

if [[ "$DESTROY_COUNT" -gt 0 ]]; then
  echo "⚠️  WARNING: This plan DESTROYS $DESTROY_COUNT resource(s)!"
  read -p "Type 'DESTROY' to confirm: " CONFIRM
  [[ "$CONFIRM" != "DESTROY" ]] && exit 1
fi
```

### 2. Second Approval for Destructive Changes

**Process:**
1. PR approval (standard review)
2. **Second approval from infrastructure-leads** for any plan with destructions
3. Document in PR: "Destruction approved by @senior-engineer on 2026-04-08"
4. Terraform Cloud apply approval (separate from PR)

**Why:** Destructive changes are irreversible. Databases, S3 buckets with data, stateful resources cannot be recovered without backups.

### 3. S3 State Bucket Versioning

**Verification:**
```bash
# Must be enabled before any applies
aws s3api get-bucket-versioning \
  --bucket my-terraform-state-bucket
# Status: "Enabled"

# If not enabled:
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled
```

**Why:** State file corruption is unrecoverable without versioning. A corrupted state file means Terraform doesn't know what infrastructure exists - you're flying blind.

### 4. Blast Radius Documentation

**Required for Every PR:**

```markdown
## Blast Radius Analysis

**Affected Environments:** [dev/staging/production]

**Downstream Dependencies:**
- Module X reads outputs from this module
- Service Y depends on security group rules
- Database Z uses IAM role created here

**Failure Scenarios:**
1. If apply fails after resource A creation:
   - Impact: [describe]
   - Mitigation: [describe]
2. If apply fails after resource B modification:
   - Impact: [describe]
   - Mitigation: [describe]

**Shared Resource Changes:**
- VPC: [YES/NO] - [details if yes]
- Security Groups: [YES/NO] - [details if yes]
- IAM Roles: [YES/NO] - [details if yes]
```

**Mandatory for Shared Resources:**
- VPC modifications: Affects all services in that VPC
- Security group changes: Can break connectivity for multiple services
- IAM role changes: Can break permissions for multiple services
- Subnet changes: Can cause IP exhaustion or routing issues

---

## Sentinel Policies: Infrastructure-Specific Enforcement

### How Sentinel Differs from terraform validate

| | terraform validate | Sentinel Policies |
|---|---|---|
| **When it runs** | Before plan, on local HCL | **After plan, in Terraform Cloud** |
| **What it sees** | HCL structure and types | **Final resolved plan values** |
| **What it catches** | Syntax errors, type mismatches | **Business rule violations** |
| **Enforcement** | Always - blocks local operations | **Policy-as-code** - configurable per workspace |
| **Override** | Not possible | **Possible for soft-mandatory** |
| **Audit trail** | None | **Full log in Terraform Cloud** |

**Example:**

```hcl
# terraform validate CANNOT catch this:
resource "aws_instance" "web" {
  instance_type = "m5.24xlarge"  # Valid string, but too expensive!
}

# Sentinel CAN catch this:
import "tfplan/v2" as tfplan

allowed_instance_types = ["t2.micro", "t2.small", "t2.medium", "t3.micro", "t3.small"]

instances = filter tfplan.resource_changes as _, rc {
  rc.type is "aws_instance" and
  (rc.change.actions contains "create" or rc.change.actions contains "update")
}

instance_type_allowed = rule {
  all instances as _, instance {
    instance.change.after.instance_type in allowed_instance_types
  }
}

main = rule {
  instance_type_allowed
}
```

### Production-Specific Sentinel Policies

**1. Prevent Destructive Changes in Production:**

```hcl
# sentinel/prevent-production-destruction.sentinel
import "tfplan/v2" as tfplan
import "tfrun" as tfrun

# Only enforce in production workspaces
is_production = tfrun.workspace.name matches "^prod-.*"

# Find all resource destructions
destructions = filter tfplan.resource_changes as _, rc {
  rc.change.actions contains "delete" and
  rc.mode is "managed"
}

no_destructions_in_prod = rule when is_production {
  length(destructions) == 0
}

main = rule {
  no_destructions_in_prod
}
```

**Enforcement Level:** `hard-mandatory` - NO override possible

**2. Require Approved Instance Types:**

```hcl
# sentinel/require-instance-type.sentinel
import "tfplan/v2" as tfplan

allowed_types = ["t2.micro", "t2.small", "t2.medium", "t3.micro", "t3.small"]

instances = filter tfplan.resource_changes as _, rc {
  rc.type is "aws_instance" and
  (rc.change.actions contains "create" or rc.change.actions contains "update")
}

instance_type_allowed = rule {
  all instances as _, instance {
    instance.change.after.instance_type in allowed_types
  }
}

main = rule {
  instance_type_allowed
}
```

**Enforcement Level:** `hard-mandatory`

**3. Cost Estimation Threshold:**

```hcl
# sentinel/cost-estimation.sentinel
import "tfrun" as tfrun

# Environment-specific monthly cost limits
cost_limits = {
  "dev":     100,   # $100/month
  "staging": 500,   # $500/month
  "prod":    5000,  # $5000/month
}

workspace_name = tfrun.workspace.name
environment = strings.split(workspace_name, "-")[0]
cost_limit = cost_limits[environment]

estimated_cost = decimal.new(tfrun.cost_estimate.delta_monthly_cost)

within_budget = rule {
  estimated_cost.less_than(cost_limit)
}

main = rule {
  within_budget
}
```

**Enforcement Level:** `soft-mandatory` - Can override with justification

---

## Complete End-to-End Workflow Example

### Scenario: Add CloudWatch Alarms to Webserver Cluster

**Step 1: Create Feature Branch**

```bash
git checkout main
git pull
git checkout -b add-cloudwatch-alarms-day21
```

**Step 2: Make Infrastructure Changes**

```bash
# Create modules/webserver-cluster/cloudwatch.tf
# Add variables to modules/webserver-cluster/variables.tf
# Add outputs to modules/webserver-cluster/outputs.tf

terraform fmt -recursive
terraform validate
```

**Step 3: Generate Plan**

```bash
terraform workspace select dev
terraform plan -out=day21.tfplan

# Review output:
# Plan: 7 to add, 0 to change, 0 to destroy.
#
# Resources to be created:
#   + aws_cloudwatch_metric_alarm.cpu_high
#   + aws_cloudwatch_metric_alarm.cpu_low
#   + aws_cloudwatch_metric_alarm.alb_5xx_errors
#   + aws_cloudwatch_metric_alarm.unhealthy_hosts
#   + aws_sns_topic.alerts
#   + aws_sns_topic_subscription.email_alerts
#   + aws_cloudwatch_dashboard.webserver_cluster
```

**Step 4: Analyze Blast Radius**

```bash
./scripts/analyze-blast-radius.sh day21.tfplan

# Output:
# 🔍 Analyzing blast radius...
# aws_cloudwatch_metric_alarm.cpu_high: create
# aws_cloudwatch_metric_alarm.cpu_low: create
# aws_cloudwatch_metric_alarm.alb_5xx_errors: create
# aws_cloudwatch_metric_alarm.unhealthy_hosts: create
# aws_sns_topic.alerts: create
# aws_sns_topic_subscription.email_alerts: create
# aws_cloudwatch_dashboard.webserver_cluster: create
#
# ⚠️  Shared resources affected: NONE
```

**Step 5: Commit with Template**

```bash
git add .
git commit  # Opens editor with .gitmessage template

# Fill in:
infra: Add CloudWatch alarms and dashboard for webserver cluster

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
- No shared resources modified

## Testing
- [x] terraform fmt passed
- [x] terraform validate passed
- [x] terraform plan reviewed
- [x] Blast radius analyzed

Closes #123
```

**Step 6: Push and Create PR**

```bash
git push origin add-cloudwatch-alarms-day21

# Create PR on GitHub with infrastructure_change.md template
# Include full terraform plan output in PR description
```

**Step 7: Wait for CI and Review**

```
GitHub Actions runs:
✅ fmt check
✅ validate
✅ tflint
✅ tfsec
✅ plan (output posted to PR)
✅ terraform test

Reviewer checks:
✅ Plan output matches description
✅ Resource counts correct
✅ No unexpected changes
✅ Blast radius acceptable
✅ Rollback plan clear
✅ Tests pass

Approval granted ✅
```

**Step 8: Merge and Tag**

```bash
# PR merged to main
git checkout main
git pull

# Tag release
git tag -a "v1.4.0" -m "Add CloudWatch alarms and dashboard"
git push origin v1.4.0

# Update CHANGELOG.md
```

**Step 9: Apply to Dev**

```bash
terraform workspace select dev
terraform plan -out=deploy.tfplan

# Review plan one more time
terraform show deploy.tfplan

# Apply with safeguards
./scripts/safe-apply.sh deploy.tfplan my-terraform-state-bucket dev

# Output:
# [20:15:00] Checking S3 state bucket versioning...
# ✅ State bucket versioning: Enabled
# [20:15:01] Recording pre-apply state version...
# Pre-apply state version: abc123def456
# ✅ Saved pre-apply state version to .pre-apply-state-version
# [20:15:02] Showing plan summary...
# Plan: 7 to add, 0 to change, 0 to destroy.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   Workspace : dev
#   Plan file : deploy.tfplan
#   State     : s3://my-terraform-state-bucket/dev/terraform.tfstate
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Apply this plan to workspace 'dev'? (yes/no): yes
# [20:15:10] Applying plan: deploy.tfplan
# ... terraform apply output ...
# ✅ Apply completed in 45s
# [20:15:55] Running post-apply plan to verify clean state...
# ✅ Post-apply plan is clean — no unexpected changes.
```

**Step 10: Verify Deployment**

```bash
# 1. Run plan again - must show no changes
terraform plan
# Expected: Plan: 0 to add, 0 to change, 0 to destroy.

# 2. Verify in AWS Console
# - CloudWatch → Alarms → confirm all 4 alarms exist and are in OK state
# - SNS → Topics → confirm "dev-webserver-cluster-alerts" exists
# - CloudWatch → Dashboards → open "dev-webserver-cluster-overview"

# 3. Test alarm functionality
# - Trigger CPU spike on instance
# - Verify alarm transitions to ALARM state
# - Verify SNS email received
```

---

## Key Takeaways

### Infrastructure Deployment is Fundamentally Different

1. **Statefulness:** Infrastructure has persistent state that must be managed
2. **Irreversibility:** Destroyed resources may be unrecoverable
3. **Blast Radius:** One bad change can cascade across multiple services
4. **Rollback Complexity:** Can't just redeploy - must restore state and reverse changes
5. **Verification:** Must verify both Terraform state AND actual AWS resources

### Non-Negotiable Safeguards

1. ✅ **Plan file pinning** - Never apply without saved plan
2. ✅ **State versioning** - Must be enabled before any applies
3. ✅ **Post-apply validation** - Plan must show "No changes"
4. ✅ **Blast radius documentation** - Required for every PR
5. ✅ **Second approval for destructions** - Separate from PR review
6. ✅ **Sentinel policies** - Enforce business rules at apply time

### The Workflow Discipline

Infrastructure code deployment requires **discipline** that application deployment doesn't:
- Every change goes through PR review (no exceptions)
- Every PR includes plan output (not optional)
- Every apply uses saved plan file (never fresh apply)
- Every destructive change gets second approval (always)
- Every deployment is verified in AWS console (not just Terraform)

**The teams that succeed treat this as a practice, not a project.**

---

**Last Updated:** 2026-04-08  
**Version:** 1.0.0  
**Author:** Infrastructure Team