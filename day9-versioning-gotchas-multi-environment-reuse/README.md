# Day 9 — Advanced Terraform Modules: Versioning, Gotchas, and Multi-Environment Reuse

## Repository Structure

```
terraform-day9/
├── modules/
│   └── terraform-aws-webserver-cluster/   # The reusable module (published to GitHub & tagged)
│       ├── main.tf          # ASG, ALB, Launch Template, Security Groups, CloudWatch
│       ├── variables.tf     # All input variables with types, defaults, and validation
│       ├── outputs.tf       # Granular outputs (avoids depends_on gotcha)
│       ├── versions.tf      # Provider version constraints
│       ├── user-data.sh     # EC2 bootstrap script (referenced via path.module)
│       └── README.md        # Module documentation — complete enough to use without asking
│
├── live/
│   ├── dev/
│   │   └── services/webserver-cluster/
│   │       ├── main.tf      # Calls module at ?ref=v0.0.2 (testing latest)
│   │       └── outputs.tf
│   └── production/
│       └── services/webserver-cluster/
│           ├── main.tf      # Calls module at ?ref=v0.0.1 (pinned to stable)
│           └── outputs.tf
│
└── LEARNING_JOURNAL.md      # Full Day 9 submission with gotchas, examples, and analysis
```

## Key Concepts Demonstrated

- **path.module** for safe file references inside modules
- **Separate security group rule resources** (no inline blocks) for caller extensibility
- **Granular module outputs** to avoid over-coupling with `depends_on`
- **Git tag-based versioning** with `?ref=v0.0.x` source URLs
- **Multi-environment version pinning**: dev on v0.0.2, production on v0.0.1

## Module Versions

| Tag    | Changes |
|--------|---------|
| v0.0.1 | Initial: ASG, ALB, Launch Template, security groups |
| v0.0.2 | Added: health_check_grace_period, CloudWatch alarms, desired_capacity, input validation |

## Usage

```bash
# Deploy dev (uses v0.0.2)
cd live/dev/services/webserver-cluster
terraform init
terraform plan
terraform apply

# Deploy production (uses v0.0.1 — pinned, stable)
cd live/production/services/webserver-cluster
terraform init
terraform plan
terraform apply
```
