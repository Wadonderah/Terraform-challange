# Day 23 — Terraform Associate Exam Domain Audit
## Honest Self-Assessment from a 20-Year Cloud Engineering Practitioner

> Rating key:
> GREEN  = I can explain it, have done it hands-on, and could answer exam questions cold
> YELLOW = I understand it conceptually but need to verify exact CLI flags / edge cases
> RED    = Gap — needs dedicated study time before exam

---

## Domain 1 — Understand Infrastructure as Code Concepts (16%)

| Topic | Rating | Notes |
|-------|--------|-------|
| IaC definition and benefits | GREEN | Day-to-day reality for 20 years |
| Idempotency | GREEN | Core principle — same config, same result |
| Declarative vs procedural | GREEN | Terraform declarative; Ansible procedural |
| IaC advantages over manual | GREEN | Auditability, repeatability, speed |
| Configuration drift | GREEN | Terraform plan detects it; Golden Rule prevents it |
| Infrastructure provisioning vs config management | GREEN | Terraform provisions; Chef/Ansible configures |

**Domain 1 verdict: GREEN across the board. Exam weight: 16%. No study time needed.**

---

## Domain 2 — Understand Terraform's Purpose (20%)

| Topic | Rating | Notes |
|-------|--------|-------|
| Multi-cloud provisioning | GREEN | Built multi-region with provider aliases on Day 18 |
| Provider ecosystem | GREEN | AWS, Azure, GCP, Kubernetes, Datadog — all providers |
| Terraform vs other IaC tools | GREEN | CloudFormation (AWS only), Pulumi (code), Ansible (config) |
| State purpose and function | GREEN | Remote S3 + DynamoDB lock — built it Day 3 |
| Resource graph and dependency resolution | YELLOW | Understand it; need to review implicit vs explicit depends_on |
| Terraform workflow (init/plan/apply) | GREEN | Ran this thousands of times |
| When NOT to use Terraform | GREEN | Throwaway prototypes, single-person teams |

**Domain 2 verdict: Mostly GREEN. One YELLOW on dependency graph internals.**

---

## Domain 3 — Understand Terraform Basics (24%)

| Topic | Rating | Notes |
|-------|--------|-------|
| Providers — installing, versioning, locking | GREEN | .terraform.lock.hcl understood |
| Provider version constraints (~>, >=, =) | GREEN | Use all three regularly |
| Resources — syntax, meta-arguments | GREEN | lifecycle, count, for_each, depends_on |
| Data sources | GREEN | Used extensively for AMI lookups, remote state |
| Variables — types, validation, sensitive | GREEN | Built validation blocks on Day 10 |
| Output values | GREEN | Outputs between modules, cross-stack |
| Local values | GREEN | locals {} for repeated expressions |
| Modules — calling, versioning | GREEN | Built 5 modules in this challenge |
| terraform.tfvars and .auto.tfvars loading order | YELLOW | Know the concept, need to confirm exact precedence |
| Built-in functions | YELLOW | Use common ones; exam tests obscure ones (cidrsubnet, formatlist) |
| Type constraints (string, number, bool, list, map, object, tuple) | YELLOW | Need to review complex type definitions |
| Dynamic blocks | YELLOW | Used them; need to review syntax cold |

**Domain 3 verdict: GREEN on core, YELLOW on edge cases. Highest exam weight (24%) — review built-in functions and type constraints.**

---

## Domain 4 — Use the Terraform CLI (26%)

| Topic | Rating | Notes |
|-------|--------|-------|
| terraform init flags (-backend-config, -upgrade, -reconfigure) | YELLOW | Know the flags, need exact behavior confirmed |
| terraform plan (-out, -target, -var, -var-file, -refresh-only) | GREEN | Run daily |
| terraform apply (-auto-approve, -target, -replace) | GREEN | Understand -replace vs taint |
| terraform destroy | GREEN | Also: terraform apply -destroy |
| terraform fmt (-check, -recursive, -diff) | GREEN | In every CI pipeline |
| terraform validate | GREEN | Runs without AWS creds |
| terraform output (-json, -raw) | YELLOW | Know it, need to verify -raw vs -json difference |
| terraform state list/show/mv/rm/pull/push | YELLOW | Used list and show; mv and rm less frequently |
| terraform import | YELLOW | Know concept; exam tests the exact workflow |
| terraform workspace commands | YELLOW | Know workspaces; prefer file layout — need exam perspective |
| terraform taint (deprecated) | YELLOW | Know it's deprecated; -replace flag is the replacement |
| terraform graph | YELLOW | Know it outputs DOT format; never use in practice |
| terraform providers (lock, mirror) | YELLOW | Need to review providers lock flags |
| terraform login / logout | GREEN | Used with TFC |
| terraform console | YELLOW | Interactive expression evaluator — underused |

**Domain 4 verdict: MOST YELLOWS HERE. Highest exam weight (26%). This is where to spend the most study time.**

---

## Domain 5 — Interact with Terraform Modules (12%)

| Topic | Rating | Notes |
|-------|--------|-------|
| Module sources (local, Git, registry, S3) | GREEN | Used all four |
| Module versioning with ref= | GREEN | Built versioned modules in this challenge |
| Public registry vs private registry | GREEN | Terraform Cloud private registry |
| Module inputs and outputs | GREEN | Extensively used |
| Root module vs child module vs published module | GREEN | Clear distinction |
| Module composition | GREEN | Ch. 8 of the book — composable APIs |

**Domain 5 verdict: GREEN. Weight 12%. No dedicated study needed — occasional review only.**

---

## Domain 6 — Navigate the Core Terraform Workflow (8%)

| Topic | Rating | Notes |
|-------|--------|-------|
| Write → Plan → Apply cycle | GREEN | Core of everything built |
| Refresh behavior | YELLOW | -refresh=false flag and when to use it |
| Plan output interpretation (+, -, ~, -/+) | GREEN | Read plan output daily |
| Targeted applies (-target) | YELLOW | Understand use; know it's discouraged for regular use |

**Domain 6 verdict: Mostly GREEN. Weight 8%.**

---

## Domain 7 — Implement and Maintain State (8%)

| Topic | Rating | Notes |
|-------|--------|-------|
| Purpose of state | GREEN | Maps code to real world |
| Remote backends | GREEN | S3 + DynamoDB — built Day 3 |
| State locking | GREEN | DynamoDB lock table |
| Sensitive data in state | GREEN | State is always sensitive — encrypt at rest |
| terraform_remote_state data source | GREEN | Cross-stack references |
| State drift scenarios | GREEN | Plan detects; import fixes |
| terraform state commands | YELLOW | Need hands-on practice with mv and rm |
| Workspaces vs file layout | YELLOW | Exam perspective on trade-offs |
| Backend configuration | GREEN | S3, GCS, Azure Blob, TFC |

**Domain 7 verdict: Mostly GREEN. Weight 8%. Practice state mv and rm.**

---

## Domain 8 — Read, Generate, and Modify Configuration (8%)

| Topic | Rating | Notes |
|-------|--------|-------|
| HCL syntax | GREEN | Write it daily |
| String interpolation and heredoc | GREEN | "${var.name}" and <<EOT |
| count vs for_each | GREEN | Know the trade-offs cold |
| Loops: for expressions, for_each, dynamic blocks | YELLOW | Need to review for expression syntax |
| Conditionals: ternary, count tricks | GREEN | Used extensively |
| Built-in functions (file, templatefile, jsondecode, etc.) | YELLOW | Review the full function list |
| Path references (path.module, path.root, path.cwd) | YELLOW | Know them; confirm exam scenarios |

**Domain 8 verdict: GREEN on core HCL, YELLOW on advanced functions and loops.**

---

## Domain 9 — Understand Terraform Cloud Capabilities (4%)

| Topic | Rating | Notes |
|-------|--------|-------|
| Workspaces in TFC | GREEN | Used in this challenge |
| Remote runs (plan + apply in TFC) | GREEN | CI/CD pipeline uses this |
| Sentinel policies | GREEN | Built 3 policies in Day 22 |
| Cost estimation | GREEN | Lab 1 in Day 22 |
| Private module registry | GREEN | Understand concept |
| Variable sets | YELLOW | Know concept; need to review scope rules |
| Team-based access control | YELLOW | Know it exists; exam tests RBAC concepts |

**Domain 9 verdict: Mostly GREEN. Weight 4% — lowest priority.**

---

## Priority Summary for Remaining Study Days

| Priority | Domain / Topic | Current | Action |
|----------|---------------|---------|--------|
| 1 (highest) | CLI commands — flags and edge cases | YELLOW | Hands-on + flashcards |
| 2 | Built-in functions (cidrsubnet, formatlist, toset, flatten) | YELLOW | Read docs + write examples |
| 3 | terraform state mv / rm / import | YELLOW | Run against test resources |
| 4 | Type constraints and dynamic blocks | YELLOW | Write examples from scratch |
| 5 | Workspace vs file layout trade-offs | YELLOW | Write comparison notes |
| 6 | for expressions and dynamic blocks | YELLOW | Code examples |
| 7 | Dependency graph (implicit vs explicit) | YELLOW | Read one article |

**All GREEN domains: No dedicated study needed — a quick review question is enough.**
