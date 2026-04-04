# Day 19 — IaC Adoption Strategy
## 30-Day Terraform Challenge

## What's in this folder

day19/
├── docs/
│   ├── learning-journal.md    ← Full documentation submission
│   └── blog-post.md           ← Blog post: "How to Convince Your Team..."
│
└── terraform/
    ├── phase1/                ← New CloudTrail S3 bucket (start here)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── phase2/                ← Import existing security groups
    │   └── main.tf            ← Includes import commands in comments
    │
    ├── phase3/
    │   └── modules/
    │       └── vpc/
    │           └── main.tf    ← Shared VPC module with flow logs
    │
    └── phase4/
        └── terraform.yml      ← GitHub Actions CI/CD workflow

## Where to start

1. Read `docs/learning-journal.md` — this is the full submission including the current state assessment, all four phases, business case table, import practice, and Chapter 10 reflection.

2. Read `docs/blog-post.md` — the standalone blog post for publishing.

3. Look at the Terraform code in order: `phase1` → `phase2` → `phase3` → `phase4`. Each phase builds on the previous one and includes comments explaining the reasoning behind the decisions.

## Key files to note

**`terraform/phase1/main.tf`** — The starting point. A new S3 bucket for CloudTrail logs. Remote state configured. Nothing migrated, nothing at risk.

**`terraform/phase2/main.tf`** — The import workflow. Shows how to write resource blocks that match existing AWS resources, run `terraform import`, and verify with `terraform plan`.

**`terraform/phase3/modules/vpc/main.tf`** — The first shared internal module. Opinionated by design. 3 AZs, NAT gateway per AZ, flow logs on by default.

**`terraform/phase4/terraform.yml`** — The full CI/CD workflow. OIDC authentication (no stored credentials), plan on PRs, apply on merge to main, plan output posted as PR comment.


*30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | Meru HashiCorp User Group | EveOps*
