# Day 24 Submission — Workspace Documentation
## Final Exam Review and Certification Focus

---

## Exam Simulation Score

**Score: 51 / 57 (89%)**
**Passing threshold: 40 / 57 (70%)**
**Status: PASS (simulation)**

### Questions answered incorrectly (6 total):

| Q# | Topic | Lesson learned |
|----|-------|----------------|
| 29 | `~> 5.1` vs `~> 5.1.0` version constraint | Rightmost component determines freedom range |
| 35 | `terraform init -reconfigure` vs `-migrate-state` | -reconfigure ignores state; -migrate-state moves it |
| 38 | Max resources per terraform import command | One. CLI command = one resource per run |
| 45 | `<=` symbol in plan output | Data source read — not a resource change |
| 41 | `terraform output -json` vs `-raw` | -json returns full object with type/sensitive; -raw returns just the string value |
| 34 | Correct sequence for terraform import | Write config FIRST, then import |

**Weakest domain:** Domain 4 (CLI) — 4 of 6 wrong answers were CLI-related. Confirmed as highest-priority study area.


## Flash Card Answers (Own Words, Verified)

**Q1 — What file does terraform init create to record provider versions?**
`.terraform.lock.hcl` — the provider dependency lock file. Records exact versions and hashes for all providers. MUST be committed to version control.

**Q2 — Difference between terraform.workspace and a TFC workspace?**
`terraform.workspace` is a built-in expression returning the current local workspace name (e.g., "default", "prod"). A TFC workspace is a complete managed environment — its own state, variables, run history, team access. Not the same thing at all.

**Q3 — terraform state rm on an EC2 instance — what happens in AWS?**
Nothing. The instance keeps running. state rm only removes the state file entry — it has zero effect on real infrastructure.

**Q4 — What does depends_on do and when to use it?**
Creates an explicit ordering dependency. Use ONLY when the dependency is not captured by an attribute reference (i.e., resource B depends on resource A but does not reference any attribute of A in its configuration).

**Q5 — Purpose of .terraform.lock.hcl?**
Records exact provider versions and cryptographic hashes. Ensures everyone (developers, CI) uses identical provider binaries. Update with terraform init -upgrade, commit to version control.

**Q6 — How does for_each differ from count when middle items are removed?**
count uses numeric indexes that shift when items are removed — potentially destroying/recreating wrong resources. for_each uses stable string keys — only the removed key's resource is destroyed, others are unaffected.

**Q7 — What does terraform apply -refresh-only do?**
Reads current real-world infrastructure and updates the state file to match — without making any infrastructure changes. Safe replacement for deprecated terraform refresh.

**Q8 — Maximum resources in single terraform import command?**
One. The CLI terraform import command is one resource per invocation. Terraform 1.5+ HCL import blocks allow multiple in a single apply.

**Q9 — What happens when plan runs against workspace never applied?**
Every resource shows as `+ create`. State is empty so Terraform plans to create everything from scratch.

**Q10 — What does prevent_destroy do and NOT do?**
DOES: blocks terraform destroy and any plan that includes destroying the resource.
DOES NOT: protect against removing the resource block (lifecycle no longer exists), manual deletion in AWS console, terraform state rm.



## High-Weight Domain — 3 Precision Facts Each

### Domain 1 — IaC Concepts (16%)
1. Terraform is declarative in what you write; the execution plan is ordered/procedural based on dependency graph
2. Configuration drift is what terraform plan explicitly detects — the refresh phase is drift detection
3. `create_before_destroy` is the HCL expression of immutable infrastructure philosophy

### Domain 2 — Terraform's Purpose (20%)
1. State file is the source of truth — both .tf files (desired state) AND state file (current deployed state) are needed together
2. `sensitive = true` only masks terminal output — state file still stores the value in plaintext
3. Local terraform.workspace (expression) vs TFC workspace (full managed environment) — completely different concepts with confusing shared naming

### Domain 3 — Terraform Basics (24%)
1. `~> 5.1` allows >= 5.1, < 6.0; `~> 5.1.0` allows >= 5.1.0, < 5.2.0 — rightmost component determines range
2. for_each with sets loses ordering; prefer maps for stability and access to both key and value via each.key/each.value
3. terraform.tfstate.backup only written with LOCAL backend — remote backends use their own versioning (S3 versioning IS the backup)

### Domain 4 — CLI (26%)
1. `-reconfigure` ignores existing state; `-migrate-state` moves it to new backend
2. `terraform apply ci.tfplan` with a saved plan: NO prompt, NO refresh — applies the exact saved plan
3. `terraform destroy` = `terraform apply -destroy` (alias) — NOT the same as running state rm on every resource

---

## Common Traps — 3 Additional From My Experience

**Additional Trap 1: `terraform workspace new` creates AND switches — many people expect it to just create**
Scenario: developer runs `terraform workspace new staging` expecting to still be on default, then runs apply. They just applied to the new staging workspace.
Why it's a trap: intuitively you expect "new" to be a creation operation separate from "select."

**Additional Trap 2: `~> 5.0` and `~> 5.1` both allow 5.1.3 — but `~> 5.1.0` does not allow 5.2.0**
This trips people because they assume `~> 5.0` means "only 5.0.x patches." It means anything < 6.0.
Why it's a trap: the zero reads like a zero patch version, but it is actually specifying the minor version component.

**Additional Trap 3: `terraform apply ci.tfplan` does NOT re-run the refresh phase**
People assume apply always refreshes. With a saved plan file, the refresh was done at plan time and is baked into the plan. Apply time uses the saved plan exactly. This is the feature (immutable artifact); it can also be the trap (stale plan if infra changed between plan and apply).



## Exam-Day Strategy (7 Bullet Points)

- Read the last sentence of each question FIRST — know what you are being asked before reading the scenario
- 90 seconds maximum per question — flag it and move on; you can miss 17 and still pass
- Eliminate before selecting — get to 2 choices through elimination, then decide
- Use the three-column CLI model for every CLI question: state file / real infra / AWS creds needed
- Watch for absolute language ("always," "never," "only") — usually wrong; "by default," "typically" usually right
- On "Select TWO" questions, find the two clearly right — not the two least wrong
- Reset after a hard question: flag it, one breath, read the next question fresh



## Remaining Red Topics

**One remaining gap: HCL import block (Terraform 1.5+)**

The `import {}` block syntax that allows multiple imports in a single apply.
Plan: 20 minutes reading https://developer.hashicorp.com/terraform/language/import before exam.
Everything else from Day 23's audit has been addressed through today's simulation and drills.



## Social Media Post

Day 24 of the 30-Day Terraform Challenge — final exam prep.

Full 57-question simulation under timed conditions: 51/57 (89%). The 6 I missed were all CLI flag edge cases — confirmed that 24 days of hands-on work nails the concepts; the gaps are in precise command flag behaviour.

Drilled the four traps that catch the most people:
1. terraform state rm = nothing happens to real infra
2. sensitive = true does not protect the state file
3. prevent_destroy is defeated by removing the resource block
4. terraform import: write config FIRST, generates nothing

The three-column model for every CLI command: what does it do to the state file / real infrastructure / does it need AWS creds? That mental model answers the majority of CLI questions.

Whatever the score is, I know this material better than I did 24 days ago. Let's go.

#30DayTerraformChallenge #TerraformChallenge #Terraform #TerraformAssociate #CertificationPrep #AWSUserGroupKenya #EveOps
