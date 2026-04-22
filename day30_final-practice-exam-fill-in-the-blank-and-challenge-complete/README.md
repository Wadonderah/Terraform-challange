# Day 30 — Final Practice Exam, Fill-in-the-Blank, and Challenge Complete
## 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | Meru HashiCorp User Group | EveOps

---

## What Was Accomplished Today

This is Day 30. Thirty days ago this challenge started with basic Terraform syntax. It ends today with
five practice exams completed, a full certification study programme finished, and real infrastructure
deployed across every major Terraform domain. This README documents every task completed today in full —
not a summary, a complete written record of the final day.



## Task 1: Practice Exam 5 — Final Simulated Exam

**Conditions:** 60-minute timer. 57 questions. No reference material. Same discipline as Exams 1–4.

**Score: 50/57 = 87.7% — PASS**

### How This Compares to Exam 1

Exam 1 (Day 28) scored 42/57 = 73.7%. Exam 5 scored 50/57 = 87.7%.

That is a 14-point improvement across five exams. The improvement is not a fluke. It maps directly to the work done:

- Exam 1 → 2 improvement (+5.2%): warm-up effect and question source variety
- Exam 2 → 3 improvement (+1.8%): state management study between Day 28 and Day 29
- Exam 3 → 4 improvement (+3.5%): lifecycle rules and workspace concepts hands-on
- Exam 4 → 5 improvement (+3.5%): fill-in-the-blank precision work and final consolidation

The trajectory tells a clear story: structured wrong-answer analysis followed by hands-on terminal
exercises is more effective than re-reading documentation. Every gap that appeared in a wrong-answer
analysis card was closed before the next exam. The score improvement reflects that.

**Post-exam review approach:** Reviewed wrong answers briefly. Did not go deep into new documentation.
At this stage the knowledge is there. The job is to consolidate, not learn. Seven wrong answers were
noted, all in areas already studied — imprecise command syntax recall under time pressure, not
conceptual gaps.



## Task 2: Fill-in-the-Blank Questions

**Method:** Wrote all ten answers from memory BEFORE checking documentation. Then verified.
The act of retrieval from memory is higher-quality practice than recognition.



### Question 1
**Question:** The command to check the formatting of Terraform code without making changes is `terraform ___`.

**My answer (before checking):** `fmt -check`

**Correct answer:** `fmt`

**Result:** CORRECT — `terraform fmt` checks AND reformats. `terraform fmt -check` checks without changing.
Both are valid answers depending on interpretation. The base command is `fmt`. To check only without
writing changes, add the `-check` flag. `-recursive` applies to all subdirectories.

**Explanation:** `terraform fmt` is always safe to run. It does not contact providers, does not change
infrastructure, and does not modify state. It only reformats `.tf` files to canonical HCL style. It can
be run at any point in the workflow — before or after `init`, before or after `plan`. This is distinct
from `validate` which requires `init` to have run first.



### Question 2
**Question:** The meta-argument that prevents a resource from being destroyed is `___ = true` inside a lifecycle block.

**My answer (before checking):** `prevent_destroy`

**Correct answer:** `prevent_destroy`

**Result:** CORRECT

**Explanation:** `prevent_destroy = true` inside a `lifecycle` block causes Terraform to reject any plan
that would destroy the resource. The error appears at the plan stage — Terraform will not proceed.
CRITICAL EXAM TRAP: `prevent_destroy` only blocks `terraform destroy` and plans that include resource
destruction. It does NOT prevent manual deletion through the AWS console, CLI, or API. If someone
deletes the resource manually, Terraform has no visibility and cannot stop it.


resource "aws_s3_bucket" "critical_data" {
  bucket = "my-critical-bucket"
  lifecycle {
    prevent_destroy = true
  }
}




### Question 3
**Question:** To reference the current workspace name inside a configuration, you use `terraform.___`.

**My answer (before checking):** `workspace`

**Correct answer:** `workspace`

**Result:** CORRECT

**Explanation:** `terraform.workspace` is a built-in expression that returns the name of the currently
selected workspace as a string. When you run `terraform workspace select dev`, any reference to
`terraform.workspace` in your configuration evaluates to `"dev"`. The default workspace evaluates to
`"default"`. This is commonly used in `locals` blocks to drive workspace-aware naming:


locals {
  env_prefix = "${var.project}-${terraform.workspace}"
}

EXAM NOTE: `terraform.workspace` cannot be set in `terraform.tfvars`. It is controlled exclusively by
`terraform workspace select <name>`.


### Question 4
**Question:** The backend block for storing state in S3 requires a `___` argument to enable server-side encryption.

**My answer (before checking):** `encrypt`

**Correct answer:** `encrypt`

**Result:** CORRECT

**Explanation:** Setting `encrypt = true` in the S3 backend configuration enables server-side encryption
(SSE) for the state file at rest. This addresses the EXAM TRAP from Day 28 and 29: `sensitive = true`
on output values does NOT encrypt state. `encrypt = true` in the backend DOES. For stronger encryption,
pair with `kms_key_id` to use a customer-managed KMS key instead of the default SSE-S3.

```hcl
backend "s3" {
  bucket         = "my-tf-state"
  key            = "prod/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"
  dynamodb_table = "terraform-state-locks"
}


### Question 5
**Question:** The `for_each` meta-argument requires the value to be a map or a `___`.

**My answer (before checking):** `set`

**Correct answer:** `set`

**Result:** CORRECT

**Explanation:** `for_each` accepts either a `map` (where each key becomes the instance key in state,
e.g. `aws_instance.web["server-1"]`) or a `set of strings` (where each value becomes the instance key).
It does NOT accept a plain list. If you have a list, convert it using `toset()`:


variable "bucket_names" {
  type    = list(string)
  default = ["logs", "backups", "artifacts"]
}

resource "aws_s3_bucket" "this" {
  for_each = toset(var.bucket_names)
  bucket   = each.key
}
# Creates: aws_s3_bucket.this["logs"], aws_s3_bucket.this["backups"], aws_s3_bucket.this["artifacts"]


CONTRAST with `count`: `count` uses integer index (`aws_s3_bucket.this[0]`). `for_each` uses string key.
`for_each` is preferred when resources have meaningful identifiers because removing one element from the
middle of a `count` list causes all subsequent resources to be re-indexed and potentially replaced.


### Question 6
**Question:** The command that removes a resource from Terraform state without destroying the real infrastructure is `terraform state ___`.

**My answer (before checking):** `rm`

**Correct answer:** `rm`

**Result:** CORRECT

**Explanation:** `terraform state rm <address>` removes the resource from Terraform's state file. The
real cloud infrastructure is not touched — it continues running as an unmanaged orphan. This is the
command that appeared wrong in three of five exams before the hands-on practice sessions.

Full state command matrix (burned in through terminal practice):
- `terraform state rm`     → orphans resource (state gone, infra lives)
- `terraform destroy`      → kills resource (state gone, infra deleted)
- `terraform state mv`     → renames address (infra unchanged)
- `terraform import`       → adopts resource (state added, no .tf generated)
- `terraform state pull`   → reads raw state JSON (read-only)
- `terraform refresh`      → syncs state to real infra (config files never touched)


### Question 7
**Question:** Provider version constraint `~> 2.0` allows versions `>= 2.0` and `< ___`.

**My answer (before checking):** `3.0`

**Correct answer:** `3.0`

**Result:** CORRECT

**Explanation:** The pessimistic constraint operator `~>` increments the rightmost non-zero segment.
`~> 2.0` has two segments: major=2, minor=0. The rightmost segment (minor) can increment freely.
So `~> 2.0` = `>= 2.0.0` and `< 3.0.0`. Minor releases 2.1, 2.2 ... 2.99 are all allowed.
Major version 3.0 is blocked.

CRITICAL DISTINCTION (persistent wrong answer):
- `~> 2.0`   = >= 2.0.0, < 3.0.0  (minor increments allowed)
- `~> 2.0.0` = >= 2.0.0, < 2.1.0  (patch only — three segments means tighter)

The number of version segments in the constraint determines tightness. More segments = tighter lock.



### Question 8
**Question:** A data block reads `___` infrastructure; a resource block manages `___` infrastructure.

**My answer (before checking):** `existing / managed (new or existing)`

**Correct answer:** `existing / managed`

**Result:** CORRECT

**Explanation:** `data` sources are read-only. They query existing infrastructure and expose its
attributes. They do not create, modify, or destroy anything. `resource` blocks declare infrastructure
that Terraform owns and manages — creating it on first apply, updating or replacing it when config
changes, and destroying it on `terraform destroy`.


# data: reads an existing VPC — Terraform does not own this
data "aws_vpc" "existing" {
  tags = { Name = "production-vpc" }
}

# resource: Terraform owns and manages this subnet
resource "aws_subnet" "new" {
  vpc_id     = data.aws_vpc.existing.id   # reference data source output
  cidr_block = "10.0.100.0/24"
}


### Question 9
**Question:** The `terraform init -upgrade` flag forces Terraform to update provider versions even when they are pinned in the `___` file.

**My answer (before checking):** `.terraform.lock.hcl`

**Correct answer:** `.terraform.lock.hcl`

**Result:** CORRECT

**Explanation:** `.terraform.lock.hcl` is the dependency lock file. It records the exact provider
versions and their checksums after the first `terraform init`. On subsequent `init` runs, Terraform uses
the lock file to ensure the same provider versions are installed — this makes infrastructure deployments
reproducible. `terraform init -upgrade` ignores the lock file and pulls the newest version that
satisfies the version constraints in `required_providers`. The lock file is then updated. This file
SHOULD be committed to version control — it is not a secret and it ensures all team members use
identical provider versions.


### Question 10
**Question:** To apply a previously saved plan file named `myplan.tfplan`, the command is `terraform apply ___`.

**My answer (before checking):** `myplan.tfplan`

**Correct answer:** `myplan.tfplan`

**Result:** CORRECT

**Explanation:** `terraform plan -out=myplan.tfplan` saves a plan to a binary file. `terraform apply
myplan.tfplan` executes exactly that saved plan — no new plan is generated, no confirmation prompt
appears (the plan IS the approval). This is the standard CI/CD pattern: plan in one stage, apply in a
separate stage after human approval, with the guarantee that what was approved is exactly what runs.

# Save plan
terraform plan -out=myplan.tfplan

# Review plan (optional — for CI display)
terraform show myplan.tfplan

# Apply exactly the saved plan (no prompt, no re-plan)
terraform apply myplan.tfplan
```

**Fill-in-the-Blank Score: 10/10 — All correct on first retrieval attempt.**


## Task 3: Final Readiness Check

All ten questions answered cold — no notes, no documentation.


### Q1: What does `terraform init` do to your `.terraform` directory?

`terraform init` creates and populates the `.terraform` directory. It downloads provider plugins defined
in `required_providers` into `.terraform/providers/`. It downloads module sources (registry, git, local)
into `.terraform/modules/`. It configures the backend defined in `backend` or `cloud` blocks. It creates
or updates `.terraform.lock.hcl` with exact provider versions and checksums. Running `init` is
idempotent — running it multiple times produces the same result. It must be run before `validate`,
`plan`, or `apply`. The `.terraform` directory itself should NOT be committed to version control — it
is machine-specific and potentially large.


### Q2: What is the difference between `terraform.tfstate` and `terraform.tfstate.backup`?

`terraform.tfstate` is the current state file — the live record of what Terraform believes exists in
the real world. `terraform.tfstate.backup` is the previous state file, automatically created before
each operation that modifies state. If an apply partially fails or produces unexpected results, the
backup provides a rollback point. With a remote backend (S3, Terraform Cloud), these local files are
replaced by the remote state and the backup mechanism is handled by the backend (S3 versioning, TF
Cloud history). The backup file is specific to the local backend.


### Q3: Why should you never commit `terraform.tfstate` to version control?

Three reasons: First, state files frequently contain sensitive values in plaintext — database passwords,
private keys, API tokens — even when `sensitive = true` is set on outputs. Version control history
makes these values permanent and accessible to anyone with repository access. Second, state represents
a point-in-time snapshot of infrastructure. Multiple team members pushing different state files causes
state conflicts, corrupt state, and potential infrastructure destruction. Third, state files can be very
large and change on every apply, polluting git history. The correct solution is a remote backend with
state locking (S3 + DynamoDB, Terraform Cloud) where state is stored centrally, encrypted, versioned,
and locked during operations.

---

### Q4: What does `depends_on` do and when should you use it?

`depends_on` creates an explicit dependency between resources or modules, forcing Terraform to create,
update, or destroy them in a specific order regardless of whether a data reference exists. Terraform
normally infers dependencies automatically from references (`resource_a.id` in `resource_b` means
`resource_b` depends on `resource_a`). `depends_on` is for situations where a dependency exists but is
not expressible through resource references — for example, an IAM policy must be fully propagated
before a Lambda function is created, but nothing in the Lambda resource block references the IAM policy
directly. Overusing `depends_on` makes plans slower and harder to reason about. Use it only when
implicit dependency detection is insufficient.


### Q5: What is the difference between a `variable` block and a `locals` block?

A `variable` block declares an input value that can be set by the caller — via `terraform.tfvars`,
`-var` flags, environment variables, or module arguments. Variables are the module's public interface.
A `locals` block declares computed values that are internal to the module — they cannot be set from
outside and cannot be overridden. Locals reduce repetition and centralise logic (e.g., constructing a
name prefix from multiple variables, computing a derived value once and using it everywhere). If a value
needs to come from outside the module, it is a variable. If a value is derived from other values and
used internally, it is a local.


### Q6: What happens if you run `terraform apply` and the state file has been modified by another team member since your last `terraform plan`?

If the backend supports state locking (S3 + DynamoDB, Terraform Cloud), Terraform acquires the lock
at the start of the apply. If another apply is in progress, the second apply waits or errors with lock
information. If the state has been modified but no lock is currently held, Terraform proceeds with
the apply using the plan that was generated against the old state. This means the apply may make
different changes than the plan showed — or it may produce errors if resources referenced in the plan
no longer exist in state. The safe practice is always to `terraform plan` immediately before `terraform
apply` in CI/CD pipelines, and to use `-out` with saved plan files to ensure what was approved is
exactly what runs.


### Q7: What does the `terraform graph` command output and what is it used for?

`terraform graph` outputs a DOT-format directed graph representing the dependency relationships between
resources in the configuration. The graph can be visualised using tools like Graphviz (`dot -Tpng`).
It is used for understanding why Terraform is creating resources in a particular order, debugging
unexpected dependencies, and identifying circular dependencies that would cause plan failures. In
large configurations, the graph helps teams reason about which resources block other resources during
creates and destroys.


### Q8: What is the Terraform Registry and what are the three types of things published there?

The Terraform Registry (registry.terraform.io) is the public index of reusable Terraform components.
Three types of items are published there:

1. **Providers** — plugins that enable Terraform to manage a specific platform's APIs (AWS, Azure, GCP,
   Kubernetes, GitHub, etc.). Providers are downloaded by `terraform init`.

2. **Modules** — reusable, opinionated collections of Terraform resources that implement a common
   pattern (e.g., `terraform-aws-modules/vpc/aws`). Modules are referenced with a `source` argument
   and optionally a `version` argument.

3. **Policies** — Sentinel and OPA policy sets for use with Terraform Cloud and Enterprise to enforce
   governance rules on infrastructure changes.


### Q9: What is the difference between Terraform Cloud and Terraform Enterprise?

Terraform Cloud is HashiCorp's managed SaaS offering. It provides remote state storage, remote plan/
apply execution, team access management, Sentinel policy enforcement, VCS integration, and the private
module registry. It has a free tier and paid tiers based on team size and feature requirements.

Terraform Enterprise is the self-hosted version of Terraform Cloud. It is deployed in a customer's own
infrastructure — on-premises or in their cloud account. It is designed for organisations with data
residency requirements, airgapped environments, compliance requirements that prevent SaaS usage, or
very large scale. Terraform Enterprise includes all Terraform Cloud features plus additional enterprise
controls. The key distinction: Cloud = HashiCorp manages the infrastructure. Enterprise = you manage
the infrastructure.


### Q10: When a module uses `configuration_aliases`, what problem does it solve?

`configuration_aliases` solves the problem of a module that needs to manage resources in multiple
provider configurations simultaneously — for example, deploying resources into two different AWS
regions, or into two different AWS accounts, within a single module call. Without `configuration_aliases`,
a module can only use a single provider configuration. With `configuration_aliases`, the module declares
that it expects multiple configurations for the same provider, and the caller passes them explicitly:


# In the module's required_providers:
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.primary, aws.secondary]
    }
  }
}

# In the root module, passing two provider configs to the module:
module "multi_region" {
  source = "./modules/multi_region"
  providers = {
    aws.primary   = aws.us_east_1
    aws.secondary = aws.eu_west_1
  }
}


**Final Readiness Check: 10/10 — All questions answered confidently without notes.**


## Task 4: Exam Day Logistics

- **Exam registered:** Yes — booked via hashicorp.com/certification
- **Exam format:** Online proctored (PSI platform)
- **Room prepared:** Quiet room, cleared desk, working webcam, government ID ready
- **Exam policies reviewed:** No notes, no second monitors, no mobile devices, browser locked to exam
- **Score delivery:** Credly badge appears within 24 hours of exam completion
- **Exam duration:** 60 minutes, 57 questions, passing score 70% (40/57)
- **Readiness confirmation:** Five practice exams averaging 79.1%, final exam at 87.7%. Ready.


## Task 5: 30-Day Reflection

### What Changed?

The honest answer is that the challenge changed how I think about change itself in infrastructure.
Before this programme, infrastructure felt like something you built once and then managed — patching,
updating, tweaking in place. After thirty days of writing declarative configurations and watching
Terraform calculate diffs, I think about infrastructure as something that should converge toward a
desired state, not something that accumulates changes over time.

The shift is subtle but it affects every decision. When something breaks, my first question is no longer
"what changed" — it is "what does the configuration say it should be, and where did reality diverge?"
That framing makes problems smaller and more tractable. Configuration drift is not a mystery when you
have state. Unexpected changes are not unexplained when everything that Terraform manages is
documented in code, versioned in git, and visible in a plan.

I also changed my understanding of what "managing infrastructure" means professionally. It is not
operating a console. It is designing systems that manage themselves toward a specification, with humans
reviewing the diff before anything changes. The certification is not the point. This way of thinking is.



### What Are You Most Proud Of?

The state management understanding. Not the commands — those are easy to look up. The conceptual model:
understanding that `terraform.tfstate` is not a backup or a log, it is the source of truth about what
Terraform believes exists. That `terraform state rm` is not a soft delete — it is Terraform admitting
it no longer knows about something that may still be running. That `terraform import` is an adoption,
not a creation.

This took the longest to get solid. It appeared wrong in three of five practice exams before the
hands-on terminal sessions on Day 28 and Day 29. The moment it clicked was running `terraform state rm`
against a resource and then opening the AWS console to confirm the instance was still running.
That thirty-second experiment was worth more than any amount of documentation reading.


### What Comes Next?

The immediate application is the team's existing infrastructure — roughly 40 manually created resources
across two AWS accounts with no state management and no automation. The first project is importing
those resources into Terraform, writing the configurations that match what exists, and establishing
a proper S3 + DynamoDB remote backend with CI/CD in GitHub Actions.

After that: the AZ-900 to round out the multi-cloud picture, and then Terraform Cloud Foundation
certification to go deeper on the enterprise features. But the first thing is the real work —
taking everything from this challenge and using it on something that matters to the team.



## Task 6: Five-Exam Score Summary

| Exam   | Score | %     | Trend        |
|--------|-------|-------|--------------|
| Exam 1 | 42/57 | 73.7% | Baseline     |
| Exam 2 | 45/57 | 78.9% | +5.2%        |
| Exam 3 | 46/57 | 80.7% | +1.8%        |
| Exam 4 | 48/57 | 84.2% | +3.5%        |
| Exam 5 | 50/57 | 87.7% | +3.5%        |

**Total improvement: +14.0 percentage points from Exam 1 to Exam 5.**
**All five exams above the 70% passing threshold.**
**Average across all five exams: 81.0%**


## Task 7: Closing Message to the Community

To everyone starting the 30-Day Terraform Challenge:

The first thing I wish someone had told me is this: **wrong answers are the work**. Every time you get
a practice question wrong, that is not a failure — that is the most valuable data point in the session.
Do not just note the correct answer. Write down why your reasoning was wrong. Run the actual command in
your terminal. Feel the difference between `terraform state rm` and `terraform destroy` by doing both
against a real resource. Read-only learning produces read-only knowledge. The exam tests recall under
pressure, and the only way to build that is through active retrieval and hands-on practice.

The second thing: do not skip the reflection tasks. The builds and the certifications are the visible
output, but the invisible output — the shift in how you think about systems — is the durable one.
That is what you will carry into every infrastructure conversation for the rest of your career.

Thank you to **AWS AI/ML UserGroup Kenya**, **Meru HashiCorp User Group**, and **EveOps** for building
this programme and making it available. It is genuinely excellent. Now go pass the exam.


## Blog Post

**Title:** Ready for Terraform Certification: My Final Exam Prep and 30-Day Reflection

**Summary:** Final practice exam scored 87.7% (50/57). Fill-in-the-blank: 10/10 on first retrieval.
Final readiness check: 10/10. Five-exam trajectory from 73.7% to 87.7% documented. 30-day reflection
on what changed — not what was learned, but how thinking about infrastructure changed. Closing message
to future participants. Full blog post at link below.

**URL:** [To be published before final submission]


## Social Media Post

⚡️ Day 30 of the 30-Day Terraform Challenge — complete. Five practice exams, 30 days of builds,
modules, state management, testing, CI/CD, and a full certification prep programme. Thank you to
AWS AI/ML UserGroup Kenya, Meru HashiCorp User Group, and EveOps for making this happen. Now let's go
pass that exam. #30DayTerraformChallenge #TerraformChallenge #Terraform #TerraformAssociate #IaC
#DevOps #AWSUserGroupKenya #MeruHashiCorp #EveOps

**URL:** [To be added after publishing]


*This challenge was brought to you by AWS AI/ML UserGroup Kenya, Meru HashiCorp User Group, and EveOps.*
*Congratulations on completing 30 days. Go pass that exam.*