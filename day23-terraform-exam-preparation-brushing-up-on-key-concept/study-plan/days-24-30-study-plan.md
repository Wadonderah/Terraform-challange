# Days 24–30 Structured Study Plan
## Terraform Associate Certification — Exam Countdown

> Rule: Every session has a specific method, a deliverable, and a time box.
> "Review X" is not a plan. "Run terraform state mv against a test resource and write 3 questions about it" is a plan.

---

## Day 24 — CLI Commands Deep Dive (Priority 1)

| Topic | Method | Deliverable | Time |
|-------|--------|-------------|------|
| terraform init flags | Run each flag variant against test dir | Notes on -reconfigure vs -migrate-state | 30 min |
| terraform state mv | Move a resource between names in test infra | Screenshot of before/after state list | 30 min |
| terraform state rm + re-import | Remove a resource from state, then import it back | Working import workflow documented | 45 min |
| terraform console | Open console, test 10 built-in functions interactively | Function cheat sheet | 30 min |
| terraform graph | Run against challenge infra, render with dot | PNG of dependency graph | 15 min |
| Practice questions | Write 5 questions about CLI flags you found tricky | 5 questions with answers | 30 min |

**Day 24 total: ~3 hours. Deliverable: CLI mastery notes + state workflow hands-on.**

---

## Day 25 — Built-in Functions + Type Constraints (Priority 2)

| Topic | Method | Deliverable | Time |
|-------|--------|-------------|------|
| String functions | `terraform console` — test format, substr, replace, trimspace, split, join | Function reference card | 20 min |
| Collection functions | Test toset, tolist, tomap, flatten, concat, merge, keys, values, lookup | Function reference card | 30 min |
| Numeric functions | Test min, max, ceil, floor, abs | 5 min |
| IP/CIDR functions | Test cidrsubnet, cidrhost, cidrnetmask | Write 3 exam questions | 20 min |
| Type constraints | Write examples of object, tuple, list(string), map(number) | Working .tf file with each type | 30 min |
| Encoding functions | Test base64encode, jsondecode, jsonencode, yamldecode | 15 min |
| Practice questions | 5 questions on functions | 5 questions with answers | 20 min |

**Day 25 total: ~2.5 hours. Deliverable: Function reference card + type constraint examples.**

---

## Day 26 — Dynamic Blocks + Advanced HCL (Priority 3)

| Topic | Method | Deliverable | Time |
|-------|--------|-------------|------|
| for expressions (list) | Write `[for s in var.list : upper(s)]` variants | 10 examples | 20 min |
| for expressions (map) | Write `{for k, v in var.map : k => v * 2}` variants | 10 examples | 20 min |
| for_each with maps vs sets | Write resource using for_each on a map of objects | Working module | 30 min |
| dynamic blocks | Write security group with dynamic ingress rules | Working .tf file | 30 min |
| splat expressions | Write `aws_instance.web[*].id` vs `aws_instance.web.*.id` | Notes on old vs new syntax | 15 min |
| templatefile function | Write a user_data script using templatefile | Working example | 20 min |
| Practice questions | 5 questions on HCL features | 30 min |

**Day 26 total: ~2.5 hours. Deliverable: HCL patterns library file.**

---

## Day 27 — State Management + Workspace Deep Dive (Priority 4)

| Topic | Method | Deliverable | Time |
|-------|--------|-------------|------|
| terraform_remote_state | Set up cross-stack reference between two test configs | Working example | 45 min |
| Workspace vs file layout | Write a one-page comparison with trade-offs | Comparison document | 20 min |
| Backend types | Read docs on S3, GCS, Azure Blob, TFC, local | Cheat sheet | 20 min |
| State locking scenarios | Write 3 exam questions about locking failures | 3 questions | 20 min |
| Sensitive data in state | Find a sensitive value in actual state file | Documented finding | 15 min |
| terraform state pull/push | Test both against test backend | Notes | 20 min |
| Practice questions | 5 state-focused questions | 30 min |

**Day 27 total: ~2.5 hours. Deliverable: State management cheat sheet.**

---

## Day 28 — Terraform Cloud + Sentinel (Priority 5)

| Topic | Method | Deliverable | Time |
|-------|--------|-------------|------|
| TFC workspace types | Read: CLI-driven vs VCS-driven vs API-driven | Comparison notes | 20 min |
| Variable sets | Read TFC docs on variable sets scope | Notes | 15 min |
| Sentinel policy tiers | Write one policy at each tier (advisory/soft/hard) | 3 policy files | 30 min |
| Private module registry | Walk through publishing a module to TFC | Notes | 20 min |
| Cost estimation limits | Document what cost estimation does and does not cover | Notes | 15 min |
| Run triggers | Read TFC docs on run triggers between workspaces | Notes | 15 min |
| Practice questions | 5 TFC-focused questions | 25 min |

**Day 28 total: ~2 hours. Deliverable: TFC + Sentinel reference document.**

---

## Day 29 — Full Mock Exam Day

| Activity | Method | Time |
|----------|--------|------|
| Official HashiCorp sample questions | First attempt — no notes | 30 min |
| Review every wrong answer | Read official explanation + docs page | 45 min |
| Weak area rapid review | Return to cheat sheets for any missed topics | 45 min |
| Write 5 more original questions | Focus on topics you got wrong today | 30 min |
| Rest | No more studying after 2pm | — |

**Day 29 total: ~2.5 hours. Deliverable: Final weak-area list.**

---

## Day 30 — Light Review + Exam Day Prep

| Activity | Method | Time |
|----------|--------|------|
| Flashcard review | Go through all flashcards — green/amber/red sort | 45 min |
| CLI commands rapid fire | Read each command header — can you recall flags? | 20 min |
| Domain weights review | Know which domains are worth the most (Domain 4: 26%) | 5 min |
| Exam logistics | Confirm exam time, ID requirements, quiet room | 10 min |
| No new material | Stop studying by noon | — |

---

## Quick Reference — What to Study If You Have 1 Hour

If you only have 60 minutes before the exam, spend it here in order:

1. (20 min) CLI commands — `state mv`, `state rm`, `import` workflow
2. (15 min) Plan output symbols: +, -, ~, -/+, <=
3. (10 min) Workspace vs file layout trade-offs
4. (10 min) Sentinel policy tiers: advisory / soft-mandatory / hard-mandatory
5. (5 min) `terraform.workspace` built-in variable

---

## Cheat Sheet — Numbers That Appear on the Exam

| Fact | Value |
|------|-------|
| Domain 4 weight (CLI) | 26% — highest |
| Default workspace name | "default" |
| State file name | terraform.tfstate |
| Lock file name | .terraform.lock.hcl |
| Provider cache directory | .terraform/providers/ |
| TF_VAR_ prefix | Used to set variables via environment |
| count starts at | 0 (first index is [0]) |
| Sentinel hard-mandatory | Cannot be overridden |
| Sentinel soft-mandatory | Can be overridden with approval |
| Sentinel advisory | Logged only, never blocks |
