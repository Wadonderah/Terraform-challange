# Preparing for the Terraform Associate Exam — Key Resources and Tips
## Day 23 of the 30-Day Terraform Challenge

*After 22 days of building real infrastructure — VPCs, ASGs, RDS, EKS, CI/CD pipelines,
and Sentinel policies — today I shifted from building to studying. Here is what I found,
what surprised me, and how I structured the remaining days.*

---

## Start With the Official Study Guide — Not a YouTube Video

The authoritative source is the HashiCorp Terraform Associate Certification Study Guide:
https://developer.hashicorp.com/terraform/tutorials/certification-003/associate-study-003

Print it. Open it in a second tab. Everything on the exam is on that page.
Everything NOT on that page is not on the exam. Do not let a third-party course
define your scope for you.

---

## The Self-Audit Approach — Honest Green/Yellow/Red

Before building a study plan, I audited every domain honestly against three ratings:

- **Green** — I can explain it, have done it hands-on, and could answer exam questions cold
- **Yellow** — I understand it conceptually but need to verify exact CLI flags or edge cases
- **Red** — I have a gap

Here are my results after 22 days of hands-on work:

| Domain | Weight | Rating |
|--------|--------|--------|
| Understand IaC concepts | 16% | Green — built it daily |
| Understand Terraform's purpose | 20% | Green — clear after the book |
| Understand Terraform basics | 24% | Mixed — Green on core, Yellow on built-in functions |
| Use the Terraform CLI | 26% | Most Yellows — highest priority |
| Interact with Terraform modules | 12% | Green — built 5 modules |
| Navigate the core workflow | 8% | Green |
| Implement and maintain state | 8% | Mostly Green — Yellow on state mv/rm |
| Read, generate, modify configuration | 8% | Mixed — Yellow on advanced HCL |
| Understand Terraform Cloud capabilities | 4% | Mostly Green — lowest priority |

The honest finding: **22 days of hands-on work covered about 80% of exam material deeply.
The remaining 20% is in CLI flag edge cases and built-in functions** — things you rarely
need in production but that are heavily tested.

---

## The CLI Commands Section Is More Detailed Than You Expect

Domain 4 — Use the Terraform CLI — carries 26% of the exam weight. That makes it
the highest-weighted domain. Yet most study resources cover it superficially.

Here is what the exam actually tests:

**Not just "what does terraform plan do" — but:**
- What does `-refresh=false` vs `-refresh-only` do?
- What is the difference between `terraform init -reconfigure` and `terraform init -migrate-state`?
- What exit code does `terraform fmt -check` return when files need reformatting?
- What does `terraform state rm` do to real infrastructure? (Answer: nothing)

**The three state commands that trip people up:**

`terraform state mv` — moves a resource between addresses in state. Does NOT touch real infra.
Use it when you refactor code (rename a resource, move it into a module) to prevent Terraform
from destroying the real resource and creating a new one.

`terraform state rm` — removes a resource from state. The real resource keeps running.
Use it to hand off management of a resource to a different Terraform workspace.

`terraform import` — the opposite of state rm. Brings a real resource INTO state.
Critical: you must write the resource block BEFORE running import.

---

## Built-in Functions — The Quiet Killer

The exam tests built-in functions that you rarely use in production but which
appear in questions regularly:

```hcl
# cidrsubnet — calculate a subnet CIDR from a larger block
cidrsubnet("10.0.0.0/16", 8, 1)  # returns "10.0.1.0/24"

# flatten — merge nested lists into a flat list
flatten([["a", "b"], ["c"]])  # returns ["a", "b", "c"]

# toset — convert list to set (removes duplicates, loses order)
toset(["a", "b", "a"])  # returns {"a", "b"}

# formatlist — apply format to each element of a list
formatlist("Hello, %s!", ["Alice", "Bob"])  # ["Hello, Alice!", "Hello, Bob!"]
```

Spend 30 minutes in `terraform console` running these. Seeing the output locks them in.

---

## Non-Cloud Providers — They Test Your Understanding of the Model

The `random` and `local` providers appear in exam questions because they test whether
you understand that Terraform's provider model is universal — not specific to AWS.

Key facts the exam tests:

**random_id, random_password:** Values are generated once and stored in state.
They are NOT regenerated on every apply. Use the `keepers` argument to force regeneration.

**local_file:** Creates files on the machine running Terraform (the CI runner),
NOT on your EC2 instances. If you want files on EC2, use `user_data` or provisioners.

**random_password** result is marked sensitive — it will not appear in plan output or logs.

---

## The Most Useful Study Technique: Write Your Own Questions

Reading is passive. Writing exam questions is active. When you write a question,
you have to understand the material well enough to construct three plausible wrong answers.
That forces deeper understanding than passive review.

I wrote 25 original questions for this challenge. Here are three examples:

**Question:** You run `terraform state rm aws_s3_bucket.logs`. What happens to the real S3 bucket?
**Answer:** Nothing — the bucket continues to exist. Only the state entry is removed.

**Question:** A developer runs `terraform validate` against a config with a non-existent AMI ID. What happens?
**Answer:** Validate passes — it never contacts AWS. It only checks local configuration syntax.

**Question:** Which exit code does `terraform fmt -check` return if files need reformatting?
**Answer:** Exit code 1. (This matters for CI pipelines that check the exit code.)

---

## My Study Plan for the Remaining Days

I am spending time in priority order of exam domain weight:

- Day 24: CLI commands hands-on — run `state mv`, `state rm`, `import` against real resources
- Day 25: Built-in functions — 30 minutes in terraform console
- Day 26: Dynamic blocks and advanced HCL patterns
- Day 27: State management — cross-stack references, workspace trade-offs
- Day 28: Terraform Cloud deep dive — variable sets, run triggers, private registry
- Day 29: Full mock exam — official sample questions, review every wrong answer
- Day 30: Light flashcard review — stop by noon, rest before exam

**The rule I am following:** every study session has a specific hands-on deliverable,
not just reading. "Run terraform state mv against a test resource and document what
changed" is a study plan. "Review state management" is not.

---

## Resources I Am Using

- Official Study Guide: https://developer.hashicorp.com/terraform/tutorials/certification-003/associate-study-003
- Official Sample Questions: https://developer.hashicorp.com/terraform/tutorials/certification-003/associate-questions
- Terraform CLI Reference: https://developer.hashicorp.com/terraform/cli
- Terraform Random Provider: https://registry.terraform.io/providers/hashicorp/random/latest/docs

---

## The Single Tip That Changes Your Score

**Know what each CLI command does to three things: the state file, the real infrastructure,
and whether AWS credentials are required.**

Most exam questions about CLI commands are really testing whether you know that
`state rm` does nothing to real infra, that `validate` needs no credentials,
and that `output` reads from state without contacting AWS.

Build that three-column mental model for every command and the CLI section becomes easy.

---

*Day 23 complete. The book is finished. The builds are running. Now it is exam time.*

*#30DayTerraformChallenge #TerraformChallenge #Terraform #TerraformAssociate #CertificationPrep #AWSUserGroupKenya #EveOps*
