# Putting It All Together: Application and Infrastructure Workflows with Terraform

*Day 22 of the 30-Day Terraform Challenge — finishing the book and reflecting on the journey.*

---

## The Moment It Clicked

Somewhere around Chapter 8 of *Terraform: Up & Running*, I stopped thinking of Terraform as
a tool for provisioning resources and started thinking of it as a software delivery system for
infrastructure. Chapter 10 is where Yevgeniy Brikman makes that explicit, and it is the most
important chapter in the book — not because it introduces new Terraform syntax, but because it
shows you how to run the whole thing like a real engineering team.

This post covers what I built on Day 22: an integrated CI/CD pipeline, three Sentinel policies,
a cost estimation gate, and the immutable artifact promotion pattern. Then I will tell you what
surprised me, what broke, and what I would do differently if I started over.

---

## The Integrated Pipeline

The central idea of Chapter 10 is that deploying infrastructure code follows the same seven
steps as deploying application code — version control, local run, code changes, review, automated
tests, merge and release, deploy. The difference is not in the steps. It is in what happens at
each step.

Here is the GitHub Actions pipeline I built:

```yaml
name: Infrastructure CI

on:
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - name: Format check
        run: terraform fmt -check -recursive
      - name: Init (no backend)
        run: terraform init -backend=false
      - name: Validate
        run: terraform validate
      - name: Unit tests
        run: terraform test

  plan:
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - name: Init
        run: terraform init
      - name: Plan
        run: terraform plan -out=ci.tfplan
      - name: Upload plan artifact
        uses: actions/upload-artifact@v4
        with:
          name: terraform-plan
          path: ci.tfplan
```

The validate job runs without AWS credentials — it uses `terraform init -backend=false` so
it never touches remote state. This means untrusted pull requests from forks can run format
checks and validation safely.

The plan job runs after validate passes, using OIDC to get temporary AWS credentials
(never permanent access keys stored in secrets). It saves the plan to a file and uploads it
as a GitHub Actions artifact.

### The Key Insight: The Plan Is the Artifact

When deploying application code, you build a Docker image once and promote that exact image
from dev to staging to production. You never rebuild it. The image that passed testing in
staging is the image that runs in production.

The same principle applies to Terraform. The saved `.tfplan` file is the artifact. It is
built once, uploaded, and promoted. When the apply job runs — whether in dev, staging, or
production — it downloads that exact file and applies it. It never regenerates the plan.

This matters because regenerating the plan in each environment is a source of drift. If
something in AWS changed between your staging plan and your production plan, you would get
a different result. With an immutable plan, what you reviewed is exactly what gets applied.

---

## Sentinel Policies

I implemented three Sentinel policies in Terraform Cloud.

### Policy 1 — Allowed Instance Types (hard-mandatory)

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

This is hard-mandatory, meaning apply is blocked with no override. An engineer cannot
accidentally (or deliberately) provision an `m5.8xlarge`. The policy runs before any
resource is created, at plan evaluation time in Terraform Cloud.

Why this matters: a single misconfigured module instantiated at scale can generate an
AWS bill that ends careers. This policy eliminates that category of error entirely.

### Policy 2 — ManagedBy Tag Required (soft-mandatory)

```hcl
import "tfplan/v2" as tfplan

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.change.after.tags["ManagedBy"] is "terraform"
  }
}
```

Every resource must carry a `ManagedBy = "terraform"` tag. This is soft-mandatory —
it can be overridden with a written justification recorded in the Terraform Cloud audit log.

Why this matters: when you run `terraform plan` in a random folder and see "no changes",
that is the Golden Rule being honoured. Resources without the tag are the ones that exist
in AWS but not in your state — shadow infrastructure. This policy catches them at creation
time before they become a maintenance problem.

### Policy 3 — Cost Estimation Gate (advisory escalating to soft-mandatory)

```hcl
import "tfrun"

maximum_monthly_increase = 50.0

main = rule {
  tfrun.cost_estimate.delta_monthly_cost < maximum_monthly_increase
}
```

Any PR that would increase monthly costs by more than $50 triggers this policy. In dev
and staging it is advisory — you are warned. In production it is soft-mandatory — you need
to justify it in writing before it applies.

---

## The Side-by-Side Comparison

| Component | Application Code | Infrastructure Code |
|-----------|-----------------|---------------------|
| Source of truth | Git repository | Git repository (live + modules repos) |
| Local run | `npm start` / `python app.py` | `terraform plan` in sandbox account |
| Artifact | Docker image / binary | Saved `.tfplan` file |
| Versioning | Semantic version tag | Semantic version tag on modules repo |
| Automated tests | Unit + integration tests | `terraform test` + Terratest |
| Policy enforcement | Linting / SAST | Sentinel policies |
| Cost gate | N/A | Cost estimation policy |
| Promotion | Image promoted across envs | Plan promoted across envs |
| Deployment | CI/CD pipeline | `terraform apply <plan>` |
| Rollback | Redeploy previous image | `terraform apply <previous plan>` |

---

## Reflection: 22 Days In

### What I Built

VPCs with public/private subnets and NAT gateways. EC2 instances behind Application Load
Balancers. Auto Scaling Groups with zero-downtime rolling deployments using
`create_before_destroy`. RDS MySQL with encrypted storage. S3 remote state with DynamoDB
locking. EKS clusters with Kubernetes Deployments and Services. Multi-region deployments
with provider aliases. Reusable versioned modules with full test coverage. This CI/CD
pipeline with Sentinel enforcement and cost gates.

### What Changed in How I Think

The mental model shift that matters most: **the plan file is the artifact, not the code**.

I started this challenge thinking of Terraform code as the thing you promote. You update
a variable, apply in dev, apply in stage, apply in prod. Brikman reframes this. The code
is the source. The plan is the build output. The apply is the deployment. Keeping those
three stages distinct — and never regenerating the plan between environments — is the
difference between a scripting discipline and an engineering discipline.

### What Was Harder Than Expected

State management under team conditions. Specifically, the branch problem.

Chapter 10 describes what I now call the Anna and Bill problem. Two engineers working on
different branches, both deploying to the same staging environment. Anna upgrades an
instance type on her branch. Bill, whose branch predates her change, runs plan — and his
plan proposes to silently undo Anna's upgrade as part of adding a tag.

DynamoDB locking does not prevent this. The conflict has nothing to do with concurrent
writes to the same state file. It has everything to do with the fact that Terraform is a
mapping from code to the real world, and there is only one real world. Two branches means
two conflicting maps.

The fix is simple — only deploy to shared environments from a single branch — but understanding
*why* this is a firm rule, not a preference, required seeing the failure mode described
precisely.

### What I Would Do Differently

Set up Terragrunt and the two-repo structure from Day 1. I wrote a significant amount of
copied provider blocks and backend configuration that Terragrunt eliminates entirely. Starting
with the DRY live-repo structure from the beginning would have built the versioning habit
earlier and made the multi-environment promotion exercises half the effort.

### What Comes Next

Apply this full workflow to our production EKS cluster migration. First deliverable: replace
manually created node groups with a versioned `eks-cluster` module, lock state in S3 with KMS
encryption, stand up this pipeline, and enforce the instance type Sentinel policy before any
engineer can provision an oversized node by accident.

North star: the Golden Rule. Run `terraform plan` across three random live repo folders at the
start of every sprint. If output is not "no changes", that is the highest priority issue in
the room.

---

## The Single Most Important Insight from Chapter 10

Brikman's Golden Rule:

> The main branch of the live repository should be a 1:1 representation of what's actually
> deployed in production.

Not approximately. Not mostly. A 1:1 representation. Every resource in AWS has a corresponding
line of code in the live repo on the main branch. Every line of code in the live repo on the
main branch has a corresponding resource in AWS.

Everything in this system — the single-branch rule, the immutable plan artifact, the Sentinel
tag requirement, the CI server running apply instead of developers — is in service of that one
rule.

If you operate Terraform such that the Golden Rule holds, boring deployments become possible.
And in operations, boring is the goal.

---

*Day 22 complete. Eight days left.*

*#30DayTerraformChallenge #TerraformChallenge #Terraform #DevOps #IaC #AWSUserGroupKenya #EveOps*
