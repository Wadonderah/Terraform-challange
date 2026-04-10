# Day 23 — Terraform Associate Exam Preparation
## 30-Day Terraform Challenge

---

## What is in this package

```
day23/
├── domain-audit/
│   └── domain-audit.md              # Green/Yellow/Red rating for every exam domain
│
├── study-plan/
│   └── days-24-30-study-plan.md     # Specific study plan per day through exam
│
├── cli-commands/
│   ├── cli-commands-reference.md    # All 15 CLI commands — own words + exam scenarios + flags
│   └── advanced-hcl-and-providers.tf # Provider aliases, for expressions, dynamic blocks
│
├── non-cloud-providers/
│   └── non-cloud-providers.tf       # random, local, tls, null, time — working examples
│
├── practice-questions/
│   └── 25-practice-questions.md     # 25 original questions with answers and explanations
│
├── flashcards/
│   └── 50-flashcards.md             # 50 Q&A flashcards for rapid review
│
├── blog-post/
│   └── blog-post-day23.md           # Full blog post — resources, tips, self-audit approach
│
└── SUBMISSION.md                    # Copy-paste ready workspace documentation
```

---

## How to use this

### For exam prep
1. Start with `domain-audit/domain-audit.md` — find your Yellows and Reds
2. Use `study-plan/days-24-30-study-plan.md` to schedule your remaining time
3. `cli-commands/cli-commands-reference.md` is the most important document — read it twice
4. Test yourself with `practice-questions/25-practice-questions.md`
5. Do rapid-fire review with `flashcards/50-flashcards.md`

### For the workspace submission
- Copy the contents of `SUBMISSION.md` into the documentation editor

---

## Key exam facts to memorise right now

| Command | State | Real infra | AWS creds |
|---------|-------|-----------|-----------|
| init | Configures | No | No |
| validate | No | No | No |
| fmt | No | No | No |
| plan | Reads | Reads | Yes |
| apply | Writes | Creates/modifies | Yes |
| state rm | Writes | NOTHING | No |
| state mv | Writes | NOTHING | No |
| import | Writes | Reads | Yes |
| output | Reads | No | No |

**The single most-tested fact:** `terraform state rm` does nothing to real infrastructure.

---

## Domain weights — where your time goes

1. Domain 4 — CLI commands: **26%** (highest)
2. Domain 3 — Terraform basics: **24%**
3. Domain 2 — Terraform purpose: **20%**
4. Domain 1 — IaC concepts: **16%**
5. Domain 5 — Modules: **12%**
6. Domains 6, 7, 8: 8% each
7. Domain 9 — Terraform Cloud: **4%** (lowest)

Study time allocation should roughly mirror these percentages.
