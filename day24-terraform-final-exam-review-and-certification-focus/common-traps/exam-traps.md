# Terraform Associate — Common Exam Traps
## Official Traps + 6 More From 20 Years of Practitioner Experience

---

## Official Traps (From the Task)

### Trap 1: "No changes" questions — stale state
If a question says "terraform plan shows no changes" and asks what that means, the exam often tests whether you know the answer depends on whether the state was refreshed. A freshly refreshed plan showing "no changes" = infrastructure matches configuration. A plan run with `-refresh=false` showing "no changes" = infrastructure MIGHT have drifted but Terraform did not check.

### Trap 2: terraform destroy vs terraform state rm
`terraform destroy` = removes real infrastructure AND updates state
`terraform state rm` = removes from state ONLY, real infrastructure untouched

The exam loves scenario questions: "A team member ran terraform state rm on a production database. What happened to the database?" Answer: nothing — it is still running.

### Trap 3: Required variables prompt interactively in terminal — hang in CI
A variable with no default (`variable "env" { type = string }`) will prompt interactively when run in a terminal. In a non-interactive CI environment, it causes the process to hang. Always provide required variables in CI via `-var`, `-var-file`, or `TF_VAR_` environment variables.

### Trap 4: `?ref=main` is mutable; `?ref=v1.0.0` is immutable
Module source `?ref=main` points to a branch — anyone can push to it. Your next `terraform init` might get completely different code. `?ref=v1.0.0` points to a Git tag — immutable. Production modules MUST be pinned to tags.

### Trap 5: `sensitive = true` does NOT protect state file
Marks output as sensitive (hides in terminal). Value is still in plaintext in terraform.tfstate. Encryption must be done at the backend level (S3 SSE, TFC encrypted state).

---

## Additional Traps From Practitioner Experience

### Trap 6: `terraform workspace new` CREATES AND SWITCHES — `workspace select` only switches
**Why it's a trap:** The exam gives you a scenario where someone creates a workspace and expects to still be on the previous workspace. But `terraform workspace new prod` BOTH creates AND switches. After running it, you are now on "prod." If you then run `terraform apply`, you apply to prod — not where you were before.

**The correct commands:**
```bash
terraform workspace new prod    # creates AND switches to prod
terraform workspace select dev  # switches to existing dev (does not create)
terraform workspace show        # confirms which workspace you are on
```

**Exam question format:** "A developer runs `terraform workspace new staging` then immediately runs `terraform apply`. Which workspace is affected?"
Answer: staging — the new workspace they just created and switched to.

---

### Trap 7: `terraform import` requires the resource block BEFORE running — and does NOT generate config
**Why it's a trap:** Many people assume `terraform import` is like `terraform generate` — that it reads the real resource and writes the .tf configuration for you. It does NOT. You must:
1. Write the resource block in your .tf files FIRST
2. Run `terraform import <address> <real_id>` to link the real resource to your block
3. Run `terraform plan` to verify the config matches (it rarely does perfectly on first try)

**The exam scenario:** "A team wants to bring an existing EC2 instance under Terraform management. What is the correct first step?"
Answer: Write the `resource "aws_instance"` block in the configuration — not run terraform import.

---

### Trap 8: `count.index` starts at 0 — and the last item is `count - 1`
**Why it's a trap:** Exam questions about count often involve off-by-one scenarios. If `count = 5`, instances are `[0]`, `[1]`, `[2]`, `[3]`, `[4]`. There is NO `[5]`. When count is reduced from 5 to 3, items `[3]` and `[4]` are destroyed — NOT `[2]` and `[3]`.

**The exam question:** "A configuration uses `count = 5`. It is changed to `count = 3`. Which resources are destroyed?"
Answer: The resources at index [3] and [4] — the highest-indexed ones.

---

### Trap 9: `lifecycle { prevent_destroy = true }` is defeated by removing the resource block
**Why it's a trap:** Sounds like it permanently protects the resource. It does not. `prevent_destroy` lives inside the resource block. If you delete the resource block from your .tf files, the lifecycle setting is gone — Terraform reads no configuration for that resource and destroys it on next apply.

**The only things it actually prevents:**
- `terraform destroy` for that resource (errors with "prevent_destroy is true")
- Any plan that includes destroying the resource as part of a change

**The exam scenario:** "A developer adds `prevent_destroy = true` to a production database, then later removes the entire resource block from the .tf file and runs apply. What happens?"
Answer: The database is destroyed — the lifecycle block no longer exists.

---

### Trap 10: `terraform plan -out=ci.tfplan` and then `terraform apply ci.tfplan` — no refresh happens at apply time
**Why it's a trap:** People assume apply always refreshes. When you pass a saved plan file, Terraform applies the EXACT plan that was saved — it does NOT re-check real infrastructure or generate a new plan. This is intentional (it is what makes the immutable artifact pattern work) but it means:
- If someone made infrastructure changes between your plan and apply, apply may succeed with unexpected results
- The state after apply reflects the plan, not a fresh refresh

**When this matters:** The longer the gap between plan and apply, the more risk that the plan is stale. This is why the best practice is to approve and apply plan files quickly.

---

### Trap 11: The `~>` operator applies to the RIGHTMOST specified version component
**Why it's a trap:** This is the most commonly misread version constraint.

```
~> 5       means >= 5.0.0, < 6.0.0
~> 5.0     means >= 5.0.0, < 6.0.0   (SAME as above)
~> 5.1     means >= 5.1.0, < 6.0.0
~> 5.1.0   means >= 5.1.0, < 5.2.0   (DIFFERENT — now locked to 5.1.x)
~> 5.1.2   means >= 5.1.2, < 5.2.0
```

The key insight: `~> 5.0` does NOT mean "only 5.0.x patches." It means anything under 6. `~> 5.0.0` is what you need to restrict to 5.0.x patches only.

**The exam scenario:** "Which version constraint allows 5.1.3 but not 6.0.0?"
Answer: `~> 5.0` or `~> 5.1` — both allow 5.1.3 and restrict to < 6.0.0.
