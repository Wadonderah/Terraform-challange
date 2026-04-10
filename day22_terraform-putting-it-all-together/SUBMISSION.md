# Day 22 Submission Notes

## Social Media Post

🎉 Day 22 of the 30-Day Terraform Challenge — finished the book.

Combined application and infrastructure deployment workflows into one integrated
pipeline with CI, Sentinel policies, cost gates, and immutable plan promotion
across environments.

Built this week:
✅ GitHub Actions pipeline: validate → plan → apply (dev → stage → prod)
✅ Sentinel hard-mandatory instance type policy — no m5.8xlarge surprises
✅ Sentinel ManagedBy tag requirement — zero shadow infrastructure
✅ Cost estimation gate — blocks apply if monthly delta > $50
✅ Immutable .tfplan artifact promoted across all 3 environments
✅ Terratest integration test + native terraform test unit tests

22 days in and it is just getting interesting.

#30DayTerraformChallenge #TerraformChallenge #Terraform #DevOps #IaC #AWSUserGroupKenya #EveOps

---

## Submission Checklist

### Repository Link field
Paste your GitHub Actions workflow run URL:
https://github.com/<YOUR-ORG>/<YOUR-REPO>/actions

### Live App Link field
Paste your social media post URL (LinkedIn / X / Hashnode)

### Documentation to paste into the editor

---

## Integrated CI Pipeline

The pipeline has 5 jobs:

1. **validate** — `terraform fmt -check`, `terraform init -backend=false`,
   `terraform validate`, `terraform test` — no AWS credentials needed
2. **plan** — `terraform init`, `terraform plan -out=ci.tfplan`, upload artifact
3. **apply-dev** — download artifact, `terraform apply ci.tfplan`
4. **apply-stage** — manual approval gate, plan + apply
5. **apply-prod** — second manual approval, plan + apply

All jobs use OIDC for temporary AWS credentials. No permanent access keys.

---

## Sentinel Policies

### Policy 1 — Allowed Instance Types
```hcl
import "tfplan/v2" as tfplan
allowed_types = ["t3.micro", "t3.small", "t3.medium", "m5.large", "m5.xlarge"]
main = rule {
  all tfplan.resource_changes as _, rc {
    rc.type not in ["aws_instance", "aws_launch_template"] or
    rc.change.after.instance_type in allowed_types
  }
}
```
**Enforcement**: hard-mandatory — apply is fully blocked, no override.
**Why it matters**: Prevents any engineer from provisioning unapproved instance types.
One misconfigured module at scale can destroy a cloud budget.

### Policy 2 — ManagedBy Tag Required
```hcl
import "tfplan/v2" as tfplan
main = rule {
  all tfplan.resource_changes as _, rc {
    rc.change.after.tags["ManagedBy"] is "terraform"
  }
}
```
**Enforcement**: soft-mandatory — can be overridden with written justification.
**Why it matters**: Every resource without this tag is shadow infrastructure — it
exists in AWS but not in Terraform state. This catches it at creation time.

---

## Cost Estimation Gate

Threshold: **$50/month increase per PR**.

In Terraform Cloud, the cost estimation section of each run shows:
- Resources to add / change / remove
- New monthly estimate
- Delta from previous run

The `cost-check.sentinel` policy blocks apply if `delta_monthly_cost >= 50.0`.
Advisory in dev/stage, soft-mandatory in prod.

---

## Side-by-Side Comparison Table

| Component | Application Code | Infrastructure Code |
|-----------|-----------------|---------------------|
| Source of truth | Git repository | Git repository (live + modules) |
| Local run | npm start / python app.py | terraform plan (sandbox AWS account) |
| Artifact | Docker image / binary | Saved .tfplan file |
| Versioning | Semantic version tag | Semantic version tag on modules repo |
| Automated tests | Unit + integration tests | terraform test + Terratest |
| Policy enforcement | Linting / SAST | Sentinel policies |
| Cost gate | N/A | Cost estimation policy |
| Promotion | Image promoted across envs | Plan promoted across envs |
| Deployment | CI/CD pipeline | terraform apply <plan> |
| Rollback | Redeploy previous image | terraform apply <previous plan> |

---

## Journey Reflection

**What I built**: VPCs, EC2 instances, ALBs, ASGs with zero-downtime rolling
deployments, RDS MySQL with encryption, S3 remote state, EKS clusters,
multi-region deployments, reusable versioned modules, full CI/CD pipeline
with Sentinel and cost gates.

**What changed in how I think**: The plan file is the artifact, not the code.
Code is source. Plan is build output. Apply is deployment. Keeping those three
stages separate and promoting the immutable plan — not the code — is the
difference between scripting and engineering.

**What was harder than expected**: State management under team conditions.
The Anna/Bill branch conflict is not hypothetical. Two engineers on different
branches can silently undo each other's infrastructure changes. DynamoDB locking
does not prevent this. Only deploying shared environments from a single branch does.

**What I would do differently**: Terragrunt and the two-repo structure from Day 1.
The DRY live-repo pattern eliminates a large amount of boilerplate and builds the
module versioning habit from the start rather than retrofitting it.

**What comes next**: Apply this workflow to our production EKS cluster migration.
First deliverable: versioned eks-cluster module, S3 state with KMS, this pipeline,
instance type Sentinel policy enforced before any engineer can provision an
oversized node.

---

## Chapter 10 Final Insight

The Golden Rule of Terraform:

> The main branch of the live repository should be a 1:1 representation
> of what's actually deployed in production.

Everything in this system — the single-branch policy, the immutable plan artifact,
the ManagedBy Sentinel tag, the CI server running apply — exists to enforce that
one rule. When it holds, deployments become boring. In operations, boring is the goal.
