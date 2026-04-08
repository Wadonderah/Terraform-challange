# Day 21 — Workflow for Deploying Infrastructure Code

## What I Built

This submission implements the complete seven-step infrastructure code deployment workflow for the webserver cluster from Day 19/20. The feature branch change is a CloudWatch monitoring stack (alarms, SNS topic, dashboard) added to the existing cluster module.

## The Seven-Step Workflow — Applied

### Step 1 — Version Control

Branch protection rules verified on `main`:

✅ Require at least 1 reviewer approval before merge
✅ Status checks (fmt, validate, plan, tests) must pass before merge
✅ No direct pushes to main — all changes go through PRs
✅ Require branches to be up to date before merging
✅ Dismiss stale reviews when new commits are pushed


### Step 2 — Run Locally (terraform plan)

# Always select your workspace explicitly before planning
terraform workspace select dev

# Generate a saved plan — the -out flag is non-negotiable
terraform plan -out=day21.tfplan

# Review the output:
#   + = resource will be created
#   ~ = resource will be modified in-place
#   -/+ = resource will be destroyed and recreated (DANGER)
#   - = resource will be destroyed (DANGER)
#
# Count: Created: 7 | Modified: 0 | Destroyed: 0


**Why `-out=day21.tfplan` is mandatory:** Without it, the plan is ephemeral. If anything changes in AWS between your `plan` and your `apply` (another engineer's deploy, a drift event, a Lambda that modifies tags), the apply will execute a *different* plan than the one you reviewed. The saved plan file cryptographically pins what will be applied.

### Step 3 — Make Code Changes

git checkout -b add-cloudwatch-alarms-day21

# Changes made:
#   modules/webserver-cluster/cloudwatch.tf   ← new file
#   modules/webserver-cluster/variables.tf    ← added 5 new variables
#   modules/webserver-cluster/outputs.tf      ← added asg_name and alarm outputs

terraform plan -out=day21.tfplan
# Re-review the plan — always run plan on the final committed state, not mid-edit

git add .
git commit -m "Add CloudWatch alarms and dashboard for webserver cluster

- CPU high alarm (>80% for 2 periods) → SNS
- CPU low alarm (<10% for 3 periods) → SNS  
- ALB 5xx error count alarm (>10/min) → SNS
- ALB unhealthy host count alarm (>0) → SNS
- CloudWatch dashboard with CPU + ALB widgets + alarm status panel
- SNS topic with optional email subscription
- All alarms: treat_missing_data=notBreaching (no false positives during deploy)"

git push origin add-cloudwatch-alarms-day21

### Step 4 — Submit for Review (Pull Request)

PR template: see `.github/PULL_REQUEST_TEMPLATE/infrastructure_change.md`

**Key fields:**
- **What this changes:** Adds observability — four CloudWatch alarms + SNS fan-out + dashboard
- **Blast radius:** All changes are additive (no modifications to existing resources). If the apply fails midway, worst case is an orphaned SNS topic. No production traffic is affected.
- **Rollback plan:** `git revert` the merge commit and re-run the pipeline. SNS topic and alarms are independently deletable without touching ASG/ALB.
- **Resources affected:** Created: 7 | Modified: 0 | Destroyed: 0

### Step 5 — Automated Tests

GitHub Actions pipeline (`.github/workflows/terraform-ci.yml`) runs:

| Check | Tool | Purpose |
|-------|------|---------|
| Format | `terraform fmt --check` | No cosmetic noise in PR diffs |
| Syntax | `terraform validate` | Catch HCL errors before plan |
| Linting | `tflint` | Provider-specific rule violations |
| Security | `tfsec` | Static security analysis (open ports, unencrypted storage) |
| Plan | `terraform plan` | Posts plan output as PR comment |
| Unit tests | `terraform test` | Tests alarm config in `tests/cloudwatch_alarms.tftest.hcl` |

### Step 6 — Merge and Release

# After PR is approved and CI is green:
git checkout main
git pull

# Tag the module version
git tag -a "v1.4.0" -m "Add CloudWatch alarms and dashboard for webserver cluster"
git push origin v1.4.0

# Update any root module configs that pin the module version:
# module "webserver_cluster" {
#   source  = "git::https://github.com/your-org/Terraform-challange.git//modules/webserver-cluster?ref=v1.4.0"
# }

### Step 7 — Deploy (terraform apply)

# Use the safe-apply script — it verifies state versioning, requires explicit
# confirmation on destructions, and validates post-apply state is clean
./scripts/safe-apply.sh day21.tfplan my-terraform-state-bucket dev

# Always run plan AFTER apply — it must return "No changes"
terraform plan
# Expected: Plan: 0 to add, 0 to change, 0 to destroy.

# Verify in AWS:
# 1. CloudWatch → Alarms → confirm all 4 alarms are in OK state
# 2. SNS → Topics → confirm "webserver-cluster-alerts" exists with KMS
# 3. CloudWatch → Dashboards → open "webserver-cluster-overview"

## Infrastructure-Specific Safeguards

### 1. Approval Gates for Destructive Changes

Configured in Terraform Cloud: any plan containing `actions: ["delete"]` on a stateful resource type triggers a mandatory apply approval step (separate from PR review). The `scripts/safe-apply.sh` enforces this locally — it detects destruction count from the plan JSON and requires typing `DESTROY` explicitly.

### 2. Plan File Pinning

# ✅ Correct — apply exactly what was reviewed
terraform plan -out=day21.tfplan
terraform apply day21.tfplan

# ❌ Risky — fresh plan at apply time may differ from reviewed plan
terraform apply

The gap between plan and apply in a busy team can be minutes or hours. Another engineer's merge, a Lambda modifying tags, or an AWS-side change can all cause the fresh plan to differ from the reviewed plan.

### 3. State Backup Before Apply

# Verify versioning is enabled
aws s3api get-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --query 'Status'
# Expected: "Enabled"

# List available state versions (rollback reference)
./scripts/list-state-versions.sh my-terraform-state-bucket dev 10

# Restore a previous state version if apply corrupts state:
aws s3api get-object \
  --bucket my-terraform-state-bucket \
  --key dev/terraform.tfstate \
  --version-id <PREVIOUS_VERSION_ID> \
  terraform.tfstate.restored

terraform state push terraform.tfstate.restored

### 4. Blast Radius Documentation

Every PR touching shared resources (VPCs, security groups, IAM roles) must answer:
- Which environments consume this resource?
- What downstream modules read outputs from this module?
- What breaks (and at what severity) if the apply fails at step N?

This day's change has a **blast radius of zero** on production traffic — all resources are new, no existing resources are modified.

## Sentinel Policies

### `require-instance-type.sentinel` — Hard Mandatory

**What it enforces:**
1. All `aws_instance` and `aws_launch_template` resources must use approved instance types only
2. All EBS root volumes must have encryption enabled
3. No stateful resource destructions in workspaces matching `^prod-.*`

**How it differs from `terraform validate`:**

| | `terraform validate` | Sentinel |
|---|---|---|
| **When it runs** | Before plan, on local HCL | After plan, in Terraform Cloud |
| **What it sees** | HCL structure and types | Final resolved plan values |
| **What it catches** | Syntax errors, type mismatches, missing required vars | Business rule violations (`instance_type = "m5.24xlarge"`) |
| **Enforcement** | Always — blocks local operations | Policy-as-code — configurable per workspace |
| **Override** | Not possible | Possible for soft-mandatory |
| **Audit trail** | None | Full log in Terraform Cloud |

`terraform validate` cannot tell you that `instance_type = "m5.24xlarge"` is too expensive — it only knows that a string is a valid value for that argument. Sentinel knows the business rule.

### `cost-estimation.sentinel` — Soft Mandatory

Blocks deploys that exceed the per-environment monthly cost threshold. Soft-mandatory means engineers can override with a justification — this creates an audit trail in Terraform Cloud without creating a hard blocker for legitimate large changes.

## Where the Infrastructure Workflow Diverges from Application Code

From the Brikman reading, the key differences are:

| Concern | Application Code | Infrastructure Code |
|---------|-----------------|---------------------|
| **"Running locally"** | Run the binary/server | `terraform plan` against state |
| **The diff** | Code diff in PR | Plan output in PR description |
| **Bad deploy consequence** | 500 errors, rollback in seconds | Destroyed databases, corrupted state — may be unrecoverable |
| **Review artifact** | Code changes | Plan output (the reviewer must see this) |
| **State** | Stateless (usually) | Stateful — the `.tfstate` file IS the source of truth |
| **Blast radius** | Service errors | Data loss, cascading dependency failures |
| **Rollback** | Redeploy previous image | State restore + reverse apply (may be impossible) |
| **Approval gates** | PR review | PR review + mandatory apply approval for destructions |
| **Automated tests** | Unit + integration tests | `validate`, `fmt`, `tfsec`, `terraform test`, plan |
| **Versioning** | Artifact/image version | Module source `?ref=v1.4.0` |

The core insight: **a bad application deploy returns 500s; a bad infrastructure deploy destroys the database that the application reads from.** That asymmetry in blast radius is why infrastructure deployments require additional safeguards that have no equivalent in application CI/CD.
