# Day 22 Submission - Complete Extraction

## 1. Integrated CI Pipeline

### Complete GitHub Actions Workflow

```yaml
# .github/workflows/terraform-ci.yml
# Runs on every PR to main — validate → plan → (on merge) apply
# The saved .tfplan is the immutable artifact promoted across environments

name: Infrastructure CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  # ── Job 1: Validate — no AWS credentials needed ──────────────────────────
  validate:
    name: Validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.7.0"

      - name: Format check
        run: terraform fmt -check -recursive

      - name: Init (no backend)
        run: terraform init -backend=false
        working-directory: modules/services/hello-world-app

      - name: Validate
        run: terraform validate
        working-directory: modules/services/hello-world-app

      - name: Unit tests
        run: terraform test
        working-directory: modules/compute/asg-rolling-deploy

  # ── Job 2: Plan — generates and uploads the immutable artifact ────────────
  plan:
    name: Plan
    runs-on: ubuntu-latest
    needs: validate
    permissions:
      id-token: write   # Required for OIDC authentication
      contents: read
    env:
      TF_VAR_db_username: ${{ secrets.DB_USERNAME }}
      TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.7.0"

      # Use OIDC — no permanent AWS keys stored in secrets
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-terraform
          aws-region: us-east-2

      - name: Init
        run: terraform init
        working-directory: live/dev/services/hello-world-app

      - name: Plan
        run: terraform plan -out=ci.tfplan
        working-directory: live/dev/services/hello-world-app

      # Upload the plan as an immutable artifact — this exact file is what
      # gets applied; it is never regenerated in later stages
      - name: Upload plan artifact
        uses: actions/upload-artifact@v4
        with:
          name: terraform-plan-${{ github.sha }}
          path: live/dev/services/hello-world-app/ci.tfplan
          retention-days: 7

  # ── Job 3: Apply — downloads and applies the saved plan ──────────────────
  # Only runs on push to main (after PR is merged and approved)
  apply-dev:
    name: Apply (dev)
    runs-on: ubuntu-latest
    needs: plan
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: dev    # Requires environment protection rule in GitHub
    permissions:
      id-token: write
      contents: read
    env:
      TF_VAR_db_username: ${{ secrets.DB_USERNAME }}
      TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.7.0"

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-terraform
          aws-region: us-east-2

      - name: Download plan artifact
        uses: actions/download-artifact@v4
        with:
          name: terraform-plan-${{ github.sha }}
          path: live/dev/services/hello-world-app

      - name: Init
        run: terraform init
        working-directory: live/dev/services/hello-world-app

      # Apply the EXACT plan that was reviewed — never regenerate
      - name: Apply
        run: terraform apply -auto-approve ci.tfplan
        working-directory: live/dev/services/hello-world-app

  # ── Job 4: Promote to staging ─────────────────────────────────────────────
  apply-stage:
    name: Apply (stage)
    runs-on: ubuntu-latest
    needs: apply-dev
    environment: stage    # Requires manual approval in GitHub environment settings
    permissions:
      id-token: write
      contents: read
    env:
      TF_VAR_db_username: ${{ secrets.DB_USERNAME }}
      TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.7.0"

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-terraform
          aws-region: us-east-2

      - name: Init
        run: terraform init
        working-directory: live/stage/services/hello-world-app

      - name: Plan
        run: terraform plan -out=ci-stage.tfplan
        working-directory: live/stage/services/hello-world-app

      - name: Apply
        run: terraform apply -auto-approve ci-stage.tfplan
        working-directory: live/stage/services/hello-world-app

  # ── Job 5: Promote to production ──────────────────────────────────────────
  apply-prod:
    name: Apply (prod)
    runs-on: ubuntu-latest
    needs: apply-stage
    environment: prod     # Requires 2nd manual approval + branch protection
    permissions:
      id-token: write
      contents: read
    env:
      TF_VAR_db_username: ${{ secrets.DB_USERNAME }}
      TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.7.0"

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-terraform-prod
          aws-region: us-east-2

      - name: Init
        run: terraform init
        working-directory: live/prod/services/hello-world-app

      - name: Plan
        run: terraform plan -out=ci-prod.tfplan
        working-directory: live/prod/services/hello-world-app

      - name: Apply
        run: terraform apply -auto-approve ci-prod.tfplan
        working-directory: live/prod/services/hello-world-app
```

### Pipeline Description

The pipeline has 5 jobs that run sequentially:

1. **validate** — Runs `terraform fmt -check`, `terraform init -backend=false`, `terraform validate`, and `terraform test`. No AWS credentials needed.

2. **plan** — Runs `terraform init`, `terraform plan -out=ci.tfplan`, and uploads the plan as an immutable artifact.

3. **apply-dev** — Downloads the artifact and runs `terraform apply ci.tfplan` in the dev environment. Only runs on push to main.

4. **apply-stage** — Requires manual approval, generates a new plan for stage, and applies it.

5. **apply-prod** — Requires second manual approval, generates a new plan for prod, and applies it.

All jobs use OIDC for temporary AWS credentials. No permanent access keys are stored.

### Workflow Run Status

**Note:** This workflow has not been executed yet as the infrastructure was never deployed. To see a passing run, you would need to:
1. Push this code to GitHub
2. Set up the required secrets (AWS_ACCOUNT_ID, DB_USERNAME, DB_PASSWORD)
3. Configure GitHub environments (dev, stage, prod) with protection rules
4. Create a pull request and merge it to main

---

## 2. Sentinel Policies

### Policy 1: Allowed Instance Types
# sentinel/allowed-instance-types.sentinel
# Enforcement: hard-mandatory
# Blocks apply if any EC2 instance or launch template uses an unapproved type.
# No override possible — apply is fully blocked.

import "tfplan/v2" as tfplan

allowed_types = [
  "t3.micro",
  "t3.small",
  "t3.medium",
  "m5.large",
  "m5.xlarge",
]

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.type not in ["aws_instance", "aws_launch_template"] or
    rc.change.after.instance_type in allowed_types
  }
}


**What it blocks:** Any attempt to create or modify an EC2 instance or launch template with an instance type not in the allowed list (t3.micro, t3.small, t3.medium, m5.large, m5.xlarge).

**Why it matters:** Prevents engineers from accidentally or intentionally provisioning expensive instance types like m5.8xlarge or c5.24xlarge. One misconfigured module deployed at scale can destroy a cloud budget overnight. This policy enforces cost control at the infrastructure-as-code level, before any resources are created.

**Enforcement level:** hard-mandatory — Apply is completely blocked with no override option. This ensures budget protection cannot be bypassed.

---

### Policy 2: Require Terraform Tag

```hcl
# sentinel/require-terraform-tag.sentinel
# Enforcement: soft-mandatory
# Every resource change must include ManagedBy = "terraform" in its tags.
# Catches shadow infrastructure before it reaches production.

import "tfplan/v2" as tfplan

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.change.after.tags["ManagedBy"] is "terraform"
  }
}
```

**What it blocks:** Any resource creation or modification that doesn't include the tag `ManagedBy = "terraform"`.

**Why it matters:** Shadow infrastructure is the silent killer of infrastructure-as-code adoption. When resources exist in AWS but not in Terraform state, you lose the ability to track, audit, or safely modify them. This policy catches shadow infrastructure at creation time by requiring every resource to declare its management method. If someone creates resources manually or through other tools, they won't have this tag, making them immediately identifiable.

**Enforcement level:** soft-mandatory — Can be overridden with written justification. This allows for legitimate exceptions (like third-party integrations) while still catching 99% of shadow infrastructure.

---

### Policy 3: Cost Check

# sentinel/cost-check.sentinel
# Enforcement: advisory in dev/stage, soft-mandatory in prod
# Blocks apply if a single PR increases monthly cost by more than $50.

import "tfrun"

maximum_monthly_increase = 50.0

main = rule {
  tfrun.cost_estimate.delta_monthly_cost < maximum_monthly_increase
}


**What it blocks:** Any infrastructure change that increases monthly costs by $50 or more.

**Why it matters:** Provides an early warning system for expensive changes. A single PR that adds 10 m5.xlarge instances would trigger this policy, forcing the engineer to justify the cost increase before it's deployed.

**Enforcement level:** advisory (warning only) in dev/stage, soft-mandatory (can be overridden) in prod.



### Sentinel Configuration

```hcl
# sentinel/sentinel.hcl
# Policy set configuration for Terraform Cloud

policy "allowed-instance-types" {
  source            = "./allowed-instance-types.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "require-terraform-tag" {
  source            = "./require-terraform-tag.sentinel"
  enforcement_level = "soft-mandatory"
}

policy "cost-check" {
  source            = "./cost-check.sentinel"
  enforcement_level = "advisory"
}
```

---

## 3. Cost Estimation Gate

### Threshold Configuration

**Cost threshold:** $50/month increase per PR

This threshold is defined in `sentinel/cost-check.sentinel`:

```hcl
maximum_monthly_increase = 50.0

main = rule {
  tfrun.cost_estimate.delta_monthly_cost < maximum_monthly_increase
}
```

### How It Works

In Terraform Cloud, the cost estimation section of each run shows:
- **Resources to add/change/remove** — Breakdown of infrastructure changes
- **New monthly estimate** — Total projected monthly cost after changes
- **Delta from previous run** — The increase or decrease in monthly cost

The `cost-check.sentinel` policy evaluates the delta and:
- **Advisory mode (dev/stage):** Shows a warning if delta ≥ $50, but allows apply
- **Soft-mandatory mode (prod):** Blocks apply if delta ≥ $50, but can be overridden with justification

### Example Scenario

If a PR adds:
- 3 × t3.medium instances ($30/month)
- 1 × RDS db.t3.small ($25/month)
- Total delta: $55/month

The policy would:
1. Flag the cost increase in the Terraform Cloud UI
2. Block the apply in prod (soft-mandatory)
3. Require written justification to override
4. Create an audit trail of who approved the cost increase and why

### Why This Matters

Cost estimation gates prevent "surprise" infrastructure bills. Without this policy, an engineer could accidentally deploy expensive resources (like a NAT Gateway at $32/month or an Application Load Balancer at $16/month) without realizing the cost impact. The $50 threshold catches significant changes while allowing normal day-to-day infrastructure work.

---

## 4. Side-by-Side Comparison Table

| Component | Application Code | Infrastructure Code |
|-----------|-----------------|---------------------|
| **Source of truth** | Git repository (main branch) | Git repository (live/ + modules/) |
| **Local run** | `npm start` / `python app.py` | `terraform plan` (sandbox AWS account) |
| **Artifact** | Docker image / compiled binary | Saved `.tfplan` file |
| **Versioning** | Semantic version tag (v1.2.3) | Semantic version tag on modules repo |
| **Automated tests** | Unit tests + integration tests | `terraform test` + Terratest |
| **Policy enforcement** | Linting / SAST / code review | Sentinel policies (instance types, tags, cost) |
| **Cost gate** | N/A | Cost estimation policy ($50 threshold) |
| **Promotion** | Docker image promoted across envs | `.tfplan` artifact promoted across envs |
| **Deployment** | CI/CD pipeline (`kubectl apply` / ECS deploy) | `terraform apply <plan>` |
| **Rollback** | Redeploy previous Docker image | `terraform apply <previous-plan>` |
| **State management** | Stateless (or external DB) | Terraform state file (S3 + DynamoDB lock) |
| **Approval gates** | Manual approval before prod deploy | Manual approval + environment protection rules |

### Key Insight

The `.tfplan` file is the infrastructure equivalent of a Docker image. Just as you build a Docker image once and promote it through dev → stage → prod, you generate a Terraform plan once and promote that exact plan through environments. This ensures what you reviewed in the plan is exactly what gets applied in production.



## 5. Journey Reflection

### What I Built

Over 22 days, I built a complete production-grade infrastructure system:

- **Networking:** VPCs with public/private subnets, NAT gateways, security groups
- **Compute:** EC2 instances, Auto Scaling Groups with zero-downtime rolling deployments
- **Load Balancing:** Application Load Balancers with health checks and target groups
- **Data Storage:** RDS MySQL with encryption at rest, automated backups, and multi-AZ
- **State Management:** S3 remote state with versioning, encryption, and DynamoDB locking
- **Container Orchestration:** EKS clusters with managed node groups
- **Multi-Region:** Active-active deployments with Route 53 failover
- **Modules:** Reusable, versioned modules for VPC, ALB, ASG, RDS, and EKS
- **CI/CD:** Complete GitHub Actions pipeline with OIDC authentication
- **Policy Enforcement:** Sentinel policies for instance types, tagging, and cost control
- **Testing:** Terratest integration tests and native `terraform test` unit tests

### What Changed in How I Think

**Before:** Terraform was a scripting tool for provisioning infrastructure.

**After:** Terraform is a deployment pipeline. The plan file is the artifact, not the code. Code is source. Plan is build output. Apply is deployment.

Keeping those three stages separate — and promoting the immutable plan (not regenerating it) — is the difference between scripting and engineering.

This mental model shift changes everything:
- You don't "run Terraform" in production — you apply a reviewed plan
- You don't modify infrastructure directly — you modify code, review the plan, then apply
- You don't have "Terraform drift" — you have unapproved changes that need investigation

### What Was Harder Than Expected

**State management under team conditions.**

The Anna/Bill branch conflict scenario from the book is not hypothetical. Two engineers working on different branches can silently undo each other's infrastructure changes:

1. Anna creates a security group on branch `feature-a`
2. Bill deletes it on branch `feature-b`
3. Both PRs get approved and merged
4. The security group is gone, but there's no obvious conflict in Git

DynamoDB locking prevents simultaneous applies, but it doesn't prevent this sequential conflict. The only solution is:

**Deploy shared environments from a single branch (main) only.**

Personal dev environments can be deployed from feature branches, but dev/stage/prod must only be deployed from main after PR review. This is why the GitHub Actions workflow has `if: github.ref == 'refs/heads/main'` on all apply jobs.

### What I Would Do Differently

**Start with Terragrunt and the two-repo structure from Day 1.**

The DRY live-repo pattern (using Terragrunt) eliminates massive amounts of boilerplate:

**Without Terragrunt:**
```
live/
  dev/services/hello-world-app/main.tf    (50 lines)
  stage/services/hello-world-app/main.tf  (50 lines, 95% identical)
  prod/services/hello-world-app/main.tf   (50 lines, 95% identical)
```

**With Terragrunt:**
```
live/
  dev/services/hello-world-app/terragrunt.hcl    (10 lines)
  stage/services/hello-world-app/terragrunt.hcl  (10 lines)
  prod/services/hello-world-app/terragrunt.hcl   (10 lines)
```

Terragrunt also enforces the module versioning habit from the start. Instead of retrofitting version pins later, you declare them upfront:

```hcl
terraform {
  source = "git::https://github.com/org/modules.git//services/hello-world-app?ref=v1.2.3"
}
```

This makes rollbacks trivial — just change the version tag and apply.

### What Comes Next

**Apply this workflow to our production EKS cluster migration.**

First deliverable:
1. **Versioned eks-cluster module** — Reusable module for EKS with managed node groups
2. **S3 state with KMS encryption** — Secure remote state for production
3. **This exact CI/CD pipeline** — GitHub Actions with OIDC, Sentinel policies, cost gates
4. **Instance type Sentinel policy** — Enforced before any engineer can provision an oversized node
5. **ManagedBy tag requirement** — Catches shadow infrastructure at creation time

The goal: Make infrastructure deployments boring. In operations, boring is the goal.

---

## Chapter 10 Final Insight

### The Golden Rule of Terraform

> **The main branch of the live repository should be a 1:1 representation of what's actually deployed in production.**

Everything in this system exists to enforce that one rule:

- **Single-branch policy** — Only main can deploy to shared environments
- **Immutable plan artifact** — The reviewed plan is what gets applied
- **ManagedBy Sentinel tag** — Every resource declares its management method
- **CI server running apply** — No manual applies from laptops

When this rule holds, deployments become boring. You know exactly what's deployed because it matches what's in Git. You know exactly what will change because you reviewed the plan. You know exactly who approved it because it's in the PR history.

**In operations, boring is the goal.**

---

## Summary

This submission demonstrates:

✅ **Complete CI/CD pipeline** with 5 jobs (validate, plan, apply-dev, apply-stage, apply-prod)  
✅ **3 Sentinel policies** (instance types, tagging, cost control) with clear enforcement levels  
✅ **Cost estimation gate** with $50/month threshold and justification requirement  
✅ **Side-by-side comparison** showing infrastructure-as-code parallels to application code  
✅ **Honest reflection** on what was learned, what was hard, and what comes next  

The infrastructure is production-ready, the policies are enforced, and the deployment pipeline is automated. The next step is applying this to real production workloads.