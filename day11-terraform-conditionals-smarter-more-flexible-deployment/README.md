# Day 11 — Terraform Conditionals Deep Dive

## Project Structure

```
day11-terraform/
├── modules/
│   └── webserver-cluster/
│       ├── variables.tf     # Input variables with validation blocks
│       ├── locals.tf        # ALL conditional logic centralised here
│       ├── main.tf          # Resources (clean, no logic)
│       └── outputs.tf       # Safe references for conditional resources
├── live/
│   ├── dev/
│   │   └── main.tf          # Dev environment caller (t3.micro, min=1)
│   └── production/
│       └── main.tf          # Prod environment caller (t3.medium, min=3)
└── LEARNING_JOURNAL.md      # Full blog post + learning journal
```

## Key Patterns Demonstrated

| # | Pattern | File |
|---|---------|------|
| 1 | Ternary in `locals` — centralised decisions | `modules/.../locals.tf` |
| 2 | `count = condition ? 1 : 0` — optional resources | `modules/.../main.tf` |
| 3 | Safe output references with ternary guard | `modules/.../outputs.tf` |
| 4 | Input `validation` block — fail fast | `modules/.../variables.tf` |
| 5 | Environment-aware module | `modules/.../locals.tf` + `live/*/main.tf` |
| 6 | Conditional data source — brownfield/greenfield | `modules/.../main.tf` |

## Quick Start

```bash
# Deploy dev environment
cd live/dev
terraform init
terraform plan   # Shows t3.micro, min_size=1, no CloudWatch alarm

# Deploy production environment
cd live/production
terraform init
terraform plan   # Shows t3.medium, min_size=3, CloudWatch alarm created

# Test validation
# Edit live/dev/main.tf and set environment = "prod"
terraform plan   # Immediately fails with clear error message
```

## Environment Differences at a Glance

| Attribute | dev | production |
|-----------|-----|------------|
| `instance_type` | t3.micro | t3.medium |
| ASG `min_size` | 1 | 3 |
| ASG `max_size` | 3 | 10 |
| CloudWatch alarm | ✗ not created | ✓ created |
| Route53 record | ✗ not created | ✓ created |
| VPC mode | greenfield (creates new) | brownfield (uses existing) |
| Deletion policy | Delete | Retain |
