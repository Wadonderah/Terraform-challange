# Day 10 — Terraform Loops and Conditionals
**30-Day Terraform Challenge**             | AWS AI/ML UserGroup Kenya · Meru HashiCorp User Group · EveOps
## Repository Structure

day10-terraform/
├── count-example/
│   └── main.tf          # count basics + the index footgun
├── for-each-example/
│   └── main.tf          # for_each with set and map
├── for-expressions/
│   └── main.tf          # for expressions in outputs and locals
├── conditionals/
│   └── main.tf          # enable_autoscaling + env-based sizing
├── modules/
│   └── webserver-cluster/
│       ├── main.tf      # fully refactored module
│       └── user-data.sh # EC2 bootstrap script
└── environments/
    ├── dev/main.tf      # enable_autoscaling=false, t3.micro
    └── prod/main.tf     # enable_autoscaling=true, t3.medium


## Key Concepts Covered

| Tool | Use Case | Safe for changing lists? |
|------|----------|--------------------------|
| `count` | Fixed N copies; boolean toggle (0 or 1) | ⚠ No — renumbers on removal |
| `for_each` | Any collection keyed by name | ✅ Yes — key-stable |
| `for` expression | Transform data inline | N/A — not a resource loop |
| Ternary `? :` | Conditional values; combine with count | N/A |

## Quick Start

```bash
# Dev (autoscaling disabled, t3.micro)
cd environments/dev
terraform init && terraform plan

# Prod (autoscaling enabled, t3.medium)
cd environments/prod
terraform init && terraform plan
```

## The count Footgun in One Line

Removing an item from the middle of a `count`-driven list causes Terraform to **destroy and recreate all subsequent resources**. Use `for_each` with a `set` or `map` to avoid this entirely.

## Social Media

> 💡 Day 10 of the 30-Day Terraform Challenge — loops and conditionals unlocked. `count`, `for_each`, `for` expressions, and ternary conditionals turn static configs into dynamic infrastructure. No more copy-pasting resource blocks.
> `#30DayTerraformChallenge #TerraformChallenge #Terraform #IaC #DevOps #AWSUserGroupKenya #EveOps`
