# High-Weight Domain Drills
## 3 Precision Facts Per Domain — Things That Were Fuzzy Before Today

---

## Domain 1 — IaC Concepts (16%)

### Precision Fact 1: Terraform's approach is declarative, not imperative — but the plan is procedural
Most people know Terraform is "declarative." What catches people on the exam is the nuance: the final desired state is declarative, but the execution plan Terraform generates IS ordered and procedural (resource A before resource B, based on the dependency graph). The declarative part is what you write; the imperative part is what Terraform executes behind the scenes.

### Precision Fact 2: Configuration drift detection is what makes Terraform's plan powerful
Configuration drift is not just a conceptual term — it is what `terraform plan` explicitly detects. The plan refresh phase contacts real infrastructure and compares against the state file. Any divergence (manual changes, auto-scaling events, tag updates) shows up in the plan. This is why "run plan regularly" is good practice even when you have not made code changes.

### Precision Fact 3: Immutable infrastructure is WHY create_before_destroy exists
Immutable infrastructure = replace, never modify. `lifecycle { create_before_destroy = true }` is the HCL expression of this principle. It says: "When I must change this resource, create the new version first, then destroy the old one." Zero-downtime rolling deployments in ASGs work because of this principle applied at the compute layer.

---

## Domain 2 — Terraform's Purpose (20%)

### Precision Fact 1: The state file IS the source of truth — not the .tf files alone
This is a subtle but exam-tested point. The .tf files describe desired state. The state file records actual deployed state. Terraform needs BOTH to plan accurately. If the state file is lost, Terraform cannot determine what already exists. This is why remote backends with locking are essential — not just for teams, but for individual practitioners.

### Precision Fact 2: `sensitive = true` masks output but does NOT protect state
Before today, I knew sensitive masked terminal output. What I was fuzzy on: the value is STILL stored in plaintext in `terraform.tfstate`. The encryption responsibility is on the backend (S3 server-side encryption, TFC encrypted state). `sensitive = true` is about preventing accidental logging — it is not a security boundary.

### Precision Fact 3: terraform.workspace vs Terraform Cloud workspace are completely different things
Local workspace (`terraform workspace`) = different state file, same code, same backend config, accessed via `terraform.workspace` expression in HCL.
TFC workspace = a complete managed environment with its own state, variables, run history, team access, VCS connection. A TFC workspace is closer to a separate Terraform directory than to a local workspace.

---

## Domain 3 — Terraform Basics (24%)

### Precision Fact 1: `~> 5.0` allows >= 5.0, < 6.0 — but `~> 5.1.0` allows >= 5.1.0, < 5.2.0
The pessimistic constraint operator (`~>`) allows changes to the rightmost version component. `~> 5.0` — the rightmost component is 0 (minor), so it allows any patch and minor version below 6. `~> 5.1.0` — the rightmost component is 0 (patch), so it only allows different patch versions of 5.1.

### Precision Fact 2: `for_each` with sets loses ordering; prefer maps for stability
`for_each = toset(var.names)` is valid but the iteration order is not guaranteed (sets are unordered). `for_each` with maps is preferred for production because both the key AND value are available (`each.key` and `each.value`). With sets, `each.key` and `each.value` are the same (the set element). Use maps when you need associated data; use sets when you only need unique identifiers.

### Precision Fact 3: `terraform.tfstate.backup` is only written with local backends
Before today I assumed .backup was always created. In reality: with a local backend, Terraform writes `terraform.tfstate.backup` before every apply. With a REMOTE backend (S3, TFC), versioning is handled by the backend itself. No .backup file is written because the backend preserves all previous versions. This is why S3 versioning must be enabled — it IS the backup mechanism for remote state.

---

## Domain 4 — Terraform CLI (26%)

### Precision Fact 1: `terraform init -reconfigure` does NOT migrate state — it ignores it
I knew both flags existed but was fuzzy on the difference:
- `-reconfigure`: tells Terraform to reconfigure the backend and IGNORE any existing state. The old state is not touched, not migrated — just ignored. Use when you want to completely change backends and handle state separately.
- `-migrate-state`: configures the new backend AND moves the existing state to it. Use when you change backends and want to keep your history.

Getting these backwards on the exam = wrong answer on a question that distinguishes them.

### Precision Fact 2: `terraform apply ci.tfplan` skips the prompt AND skips the refresh
When you run `terraform apply` with a saved plan file, two things happen differently than without a plan file:
1. No interactive prompt (no "Do you want to perform these actions?")
2. No refresh — the apply uses the exact plan that was generated, without re-reading real infrastructure

This is CRITICAL for the immutable artifact pattern: the plan reviewed in staging IS the plan applied in production. No drift between review and apply.

### Precision Fact 3: `terraform destroy` is equivalent to `terraform apply -destroy` — not `terraform state rm` on everything
Before today, I could explain what destroy does but was fuzzy on its exact equivalence. `terraform destroy` is literally an alias for `terraform apply -destroy`. Both generate a plan that destroys all resources in reverse dependency order, then apply it. Neither is equivalent to running `terraform state rm` on each resource (which would leave resources running). Destroy actually removes real infrastructure.

---

## Code Examples — Precision Drills

```hcl
# locals — computed internally, cannot be set externally
locals {
  merged = merge(var.common_tags, { Name = "example" })
  # If common_tags = {Env = "prod"}, merged = {Env = "prod", Name = "example"}
  
  upper_names = [for name in var.names : upper(name)]
  # If names = ["alice", "bob"], upper_names = ["ALICE", "BOB"]
  
  name_map = { for name in var.names : name => length(name) }
  # If names = ["alice", "bob"], name_map = {alice = 5, bob = 3}
}

# Ternary conditional — common exam pattern
resource "aws_instance" "web" {
  instance_type = var.environment == "prod" ? "t3.medium" : "t3.micro"
}

# count conditional — create or don't create
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = var.enable_monitoring ? 1 : 0
  # ... alarm config
}

# for_each with map of objects — production pattern
variable "buckets" {
  type = map(object({
    versioning = bool
    region     = string
  }))
  default = {
    logs    = { versioning = true,  region = "us-east-2" }
    backups = { versioning = true,  region = "us-west-2" }
    assets  = { versioning = false, region = "us-east-2" }
  }
}

resource "aws_s3_bucket" "all" {
  for_each = var.buckets
  bucket   = "myapp-${each.key}"
  # each.key = "logs", "backups", "assets"
  # each.value = { versioning = true, region = "us-east-2" }
}
```
