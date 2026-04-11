# Day 24 — Flash Card Self-Test
## 10 Questions from the Task — Own Words Answers

> Write your answer first without looking, then compare to the answers below.

---

## Flash Card 1
**Q: What file does `terraform init` create to record provider versions?**

Your answer: _______________________________

**Correct answer:**
`.terraform.lock.hcl` — the provider dependency lock file.

It records the exact version and cryptographic hashes (for multiple platforms) of every provider used in the configuration. It lives in the root module directory alongside your .tf files. COMMIT it to version control — it ensures every team member and CI runner uses identical provider binaries.

Do not confuse with:
- `.terraform/` — the directory where provider binaries are actually downloaded (do NOT commit this)
- `terraform.tfstate` — the state file (records deployed resources, not providers)

---

## Flash Card 2
**Q: What is the difference between `terraform.workspace` and a Terraform Cloud workspace?**

Your answer: _______________________________

**Correct answer:**
These are two completely different things that share confusing naming.

`terraform.workspace` is a **built-in Terraform expression** that returns a string — the name of the currently selected local workspace (e.g., "default", "dev", "prod"). You use it in HCL: `local.env = terraform.workspace`.

A **Terraform Cloud workspace** is a complete unit of infrastructure management in TFC — it has its own state, variables, run history, team access controls, and optionally a VCS connection. It is more analogous to a separate Terraform configuration directory than to a local workspace.

The confusion: a local workspace is just a different state file. A TFC workspace is a full operating environment.

---

## Flash Card 3
**Q: If you run `terraform state rm aws_instance.web`, what happens to the EC2 instance in AWS?**

Your answer: _______________________________

**Correct answer:**
Absolutely nothing happens to the real EC2 instance. It continues running in AWS unchanged.

`terraform state rm` only modifies the state file — it removes the entry that maps the `aws_instance.web` resource block to the real EC2 instance. After running it:
- The EC2 instance is still running in AWS
- Terraform no longer manages it (it is "forgotten")
- The next `terraform plan` will NOT show the instance (it is not in state)
- If the resource block is still in your .tf file, the next plan will show "+ create" (Terraform thinks it needs to be created)

This is the single most-tested CLI command behaviour on the exam.

---

## Flash Card 4
**Q: What does the `depends_on` meta-argument do and when should you use it?**

Your answer: _______________________________

**Correct answer:**
`depends_on` creates an explicit ordering dependency between resources — it tells Terraform "do not create or update resource B until resource A is complete."

**When to use it:**
Only when the dependency is IMPLICIT — not captured by an attribute reference. Terraform automatically infers dependencies from references (e.g., `subnet_id = aws_subnet.main.id` creates an automatic dependency on `aws_subnet.main`). Use `depends_on` for dependencies that exist in reality but are not expressed through attribute references.

**Example:**
An IAM role is attached to a Lambda function, but the Lambda resource block does not reference the role attachment resource — only the role ARN. The attachment must complete before Lambda can be invoked. Use `depends_on = [aws_iam_role_policy_attachment.lambda_exec]`.

**When NOT to use it:**
Do not overuse it. `depends_on` forces Terraform to replace the dependent resource whenever the dependency changes, which can cause unnecessary recreation.

---

## Flash Card 5
**Q: What is the purpose of the `.terraform.lock.hcl` file?**

Your answer: _______________________________

**Correct answer:**
The lock file records the exact provider versions selected by `terraform init` and their cryptographic hashes for multiple platforms (linux_amd64, darwin_arm64, windows_amd64).

**Purpose:**
1. **Consistency** — everyone on the team uses the same provider version
2. **Security** — hashes verify the downloaded provider binary has not been tampered with
3. **Reproducibility** — CI runners always get the same provider, even if a new version is published

**Should it be committed?** YES — always commit `.terraform.lock.hcl` to version control.

**How to update it:** Run `terraform init -upgrade` when you want to adopt newer provider versions. The lock file is updated with the new version and hashes. Commit the updated lock file.

---

## Flash Card 6
**Q: How does `for_each` differ from `count` when items are removed from the middle of a collection?**

Your answer: _______________________________

**Correct answer:**
This is a critical exam distinction.

**With `count`:**
Resources are indexed numerically: [0], [1], [2], [3], [4]. If you remove the item at position 2 (making count = 4), Terraform renumbers — [3] becomes [2], [4] becomes [3]. Terraform sees this as modifying resources at those positions, potentially destroying and recreating the wrong resources.

**With `for_each`:**
Resources are indexed by string keys from the map or set. Each resource has a stable identity tied to its key. If you remove the key "db-server", only that specific resource is destroyed — the other resources are completely unaffected, regardless of their position in the collection.

**Rule:** Use `for_each` whenever the collection might have items removed from the middle. Use `count` only for simple "create N identical resources" scenarios where removal always happens from the end.

---

## Flash Card 7
**Q: What does `terraform apply -refresh-only` do?**

Your answer: _______________________________

**Correct answer:**
`terraform apply -refresh-only` reads the current state of all real-world resources managed by Terraform and updates the state file to match — without making any changes to infrastructure.

It is the safe replacement for the deprecated `terraform refresh` command.

**Use cases:**
- You know out-of-band changes were made and want to sync state before planning
- You want to see what has drifted from configuration without triggering infrastructure changes
- Before a major plan operation, to ensure state is current

**What it does NOT do:**
- It does not change any real infrastructure
- It does not plan or apply resource changes
- It only updates the Terraform state file

**Comparison:**
- `terraform plan` — refreshes state AND plans changes
- `terraform apply -refresh-only` — refreshes state ONLY, no changes
- `terraform plan -refresh=false` — plans WITHOUT refreshing state (fast but may be stale)

---

## Flash Card 8
**Q: What is the maximum number of items you can specify in a single `terraform import` command?**

Your answer: _______________________________

**Correct answer:**
**One.** A single `terraform import` command imports exactly one resource.

```bash
# This imports ONE resource
terraform import aws_instance.web i-0abc123def456

# To import more, you must run separate commands
terraform import aws_s3_bucket.logs my-logs-bucket
terraform import aws_security_group.app sg-0abc123
```

**The modern alternative (Terraform 1.5+):**
The `import` block in HCL allows multiple imports in a single `terraform apply`:
```hcl
import {
  to = aws_instance.web
  id = "i-0abc123def456"
}
import {
  to = aws_s3_bucket.logs
  id = "my-logs-bucket"
}
```
But the `terraform import` CLI command is still limited to one resource per invocation.

---

## Flash Card 9
**Q: What happens when you run `terraform plan` against a workspace that has never been applied?**

Your answer: _______________________________

**Correct answer:**
Terraform treats an empty state as "no resources exist." The plan output shows every resource in the configuration as `+ create` (to be created). No resources are in state because nothing has been applied yet, so Terraform plans to create everything from scratch.

This is the expected behaviour — it is exactly what you want when deploying a new environment. The plan gives you a preview of all resources that will be created on the first apply.

**What the plan does:**
1. Refreshes state — state is empty, so there is nothing to refresh
2. Evaluates the configuration
3. Plans creation of every resource block in the configuration

---

## Flash Card 10
**Q: What does the `prevent_destroy` lifecycle argument do and what does it NOT prevent?**

Your answer: _______________________________

**Correct answer:**
**What it DOES:**
`lifecycle { prevent_destroy = true }` causes `terraform plan` and `terraform apply` to return an error if the plan includes destroying that resource. It blocks `terraform destroy` for that specific resource and any plan that would destroy it as part of a change (e.g., a replacement due to an immutable attribute change).

**What it does NOT prevent:**
1. **Removing the resource block from configuration.** If you delete the resource block from your .tf file, Terraform destroys the resource on the next apply — the lifecycle block no longer exists to be read.

2. **Manual deletion in AWS console.** `prevent_destroy` only controls Terraform behaviour. It cannot stop someone from clicking "Delete" in the AWS console.

3. **`terraform state rm` followed by configuration removal.** Once the resource is removed from state, Terraform no longer manages it and the lifecycle block has no effect.

**Practical use:**
Put `prevent_destroy = true` on production databases, S3 buckets with critical data, and any resource where accidental deletion would be catastrophic. Combine with S3 bucket versioning and DynamoDB deletion protection for defence in depth.

---

## Self-Scoring

```
Flash card results:
Q1 (lock file):           Correct / Incorrect
Q2 (workspace types):     Correct / Incorrect
Q3 (state rm):            Correct / Incorrect
Q4 (depends_on):          Correct / Incorrect
Q5 (lock.hcl purpose):    Correct / Incorrect
Q6 (for_each vs count):   Correct / Incorrect
Q7 (refresh-only):        Correct / Incorrect
Q8 (import limit):        Correct / Incorrect
Q9 (empty workspace):     Correct / Incorrect
Q10 (prevent_destroy):    Correct / Incorrect

Score: _____ / 10
```
