# My Final Preparation for the Terraform Associate Exam
## Day 24 of the 30-Day Terraform Challenge

*24 days of building real infrastructure — VPCs, ASGs, RDS databases, EKS clusters,
CI/CD pipelines, Sentinel policies, multi-region deployments. The book is finished.
The code is running. Today was simulation day.*

---

## The Simulation

I sat down with a timer for 60 minutes and worked through 57 practice questions
without looking anything up. The rules: no pausing, no searching, no skipping.
Flag uncertain questions and return to them.

**Simulation score: 51/57 (89%)**

The six I got wrong:

1. The exact behaviour of `~> 5.1` vs `~> 5.1.0` (pessimistic constraint operator)
2. What `terraform init -reconfigure` does vs `-migrate-state`
3. The maximum number of resources in a single `terraform import` command
4. The `<=` symbol in plan output (data source reads)
5. What `terraform output -json` returns vs `terraform output -raw`
6. The correct sequence: write config BEFORE running `terraform import`

Pattern: all six wrong answers were CLI flag details or less-obvious behaviours.
Zero wrong answers on IaC concepts, provider architecture, or module design.

This confirmed what I found in Day 23's audit: 22 days of hands-on work covers
the concepts deeply. The gaps are in the precise details of CLI command behaviour.

---

## What I Drilled After the Simulation

### The three-column CLI mental model

For every CLI command, I now think in three columns:

| Command | State file | Real infra | AWS creds needed |
|---------|-----------|-----------|-----------------|
| validate | No | No | No |
| fmt | No | No | No |
| state rm | Writes (removes) | NOTHING | No |
| state mv | Writes (moves) | NOTHING | No |
| import | Writes (adds) | Reads | Yes |
| plan | Reads + refreshes | Reads | Yes |
| apply | Writes | Creates/modifies | Yes |
| destroy | Writes | Destroys | Yes |
| output | Reads | No | No |

This model answers the majority of CLI exam questions because most of them
are testing exactly one of these three properties.

### The version constraint precision problem

I had to sit down and work through `~>` systematically:

```
~> 5       = >= 5.0.0, < 6.0.0
~> 5.0     = >= 5.0.0, < 6.0.0   ← same as above
~> 5.1     = >= 5.1.0, < 6.0.0
~> 5.1.0   = >= 5.1.0, < 5.2.0   ← DIFFERENT — now locked to 5.1.x patches
~> 5.1.2   = >= 5.1.2, < 5.2.0
```

The rule: `~>` allows the RIGHTMOST specified component to change freely,
and everything to its right. Everything to the LEFT is locked.

`~> 5.1.0` — rightmost component is patch (0). Only patches can change.
`~> 5.0` — rightmost component is minor (0). Minor and patch can change.

Write it out. Do not try to remember it by feel.

---

## The Four Exam Traps That Catch the Most People

**Trap 1: `terraform state rm` does nothing to real infrastructure**

The exam will ask this in various forms:
- "A developer ran terraform state rm on a production database. What happened to the database?"
- "What is the difference between terraform destroy and terraform state rm?"

The answer is always the same: `state rm` only modifies the state file. The real resource keeps running unchanged. `destroy` removes the real resource.

**Trap 2: `sensitive = true` does not protect the state file**

`sensitive = true` in an output block prevents the value from appearing in terminal output. That is its only effect. The value is still stored in plaintext in `terraform.tfstate`. Security requires encrypting the backend (S3 server-side encryption, TFC encrypted state) and restricting access to the state file.

**Trap 3: `prevent_destroy = true` is defeated by removing the resource block**

`prevent_destroy = true` lives inside the resource block. If you delete the resource block from your .tf files, the lifecycle setting no longer exists — Terraform destroys the resource on next apply. It is not a permanent protection — it is a guard against accidental in-configuration destruction.

**Trap 4: `terraform import` requires config written FIRST — and generates nothing**

Common misconception: `terraform import` reads the real resource and writes Terraform configuration for you. It does not. You write the resource block first, then run import to link the real resource to your configuration block. After import, run `terraform plan` — it almost always shows differences because your manually-written config rarely matches all attributes exactly.

---

## The Resources That Were Most Useful

**Best for concepts:** *Terraform: Up & Running* by Yevgeniy Brikman — Chapters 1-5 and 10.
Reading this book is more valuable than watching videos because it builds deep understanding
of the "why" behind every decision.

**Best for CLI details:** The official Terraform CLI reference at developer.hashicorp.com.
Search for the specific command you are fuzzy on — the flag descriptions are precise and
that precision is what the exam tests.

**Best for practice questions:** Write your own. Seriously.
Writing a question requires understanding the material well enough to construct a plausible
wrong answer. I wrote 30 questions across Days 23 and 24 and they covered topics that I
had read three times but not retained until I had to construct a wrong answer for them.

**Best for the night before:** The 50 flashcards from Day 23.
Do not read new material the night before. Rapid Q&A with flashcards keeps the material
active without introducing new concepts that might cause confusion.

---

## My Exam-Day Strategy

1. **Read the last sentence of each question first.** Long scenario questions bury the actual
   question at the end. Know what you are being asked before reading the setup.

2. **Eliminate before you select.** On any uncertain question, get it to 2 choices through
   elimination, then decide. Do not try to select the right answer out of 4 — eliminate
   the 3 wrong ones.

3. **90 seconds maximum per question.** A hard question counts the same as an easy one.
   Flag it and move on. Your brain keeps working on flagged questions in the background.

4. **Use the three columns for CLI questions:** state file / real infra / AWS creds.
   Most CLI questions are testing one of these three properties.

5. **Watch for absolute language.** "Always," "never," "must," and "only" are usually
   wrong. Terraform has exceptions to most rules.

6. **On multi-select: find the two that are clearly right.** "Select TWO" means exactly two.
   Getting one right and picking a third wrong answer scores zero.

7. **70% to pass. You can miss 17 questions.** When confidence drops around question 30,
   remember this. Flag the hard one, reset, and move to the next.

---

## Remaining Red Topics

After today's simulation, I am honest that one topic is still not fully solid:

**The `import` block (Terraform 1.5+ HCL import):**
```hcl
import {
  to = aws_instance.web
  id = "i-0abc123def456"
}
```
This is the newer way to import multiple resources in a single apply. The CLI `terraform import` command is still one-at-a-time. The exam may test awareness of both methods. I will spend 20 minutes reading the official import block documentation before the exam.

---

## The Honest Assessment

89% on the simulation. The official passing threshold is 70%.

I would rather go into the exam with a 19-point buffer earned through hands-on work
over 24 days than with a narrow pass earned through watching videos the week before.

The infrastructure I built in this challenge is the reason the concepts are solid.
Sentinel policies do not feel abstract when you have written three of them. Remote state
does not feel theoretical when you have debugged a DynamoDB lock table at 2am.

That is the real value of the 30-day challenge — not the certification, but what
knowing the material at this depth means for the next infrastructure project.

---

*Day 24 complete. Exam day is coming.*

*#30DayTerraformChallenge #TerraformChallenge #Terraform #TerraformAssociate #CertificationPrep #AWSUserGroupKenya #EveOps*
