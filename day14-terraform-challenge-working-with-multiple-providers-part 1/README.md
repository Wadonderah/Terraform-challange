# Day 14 — Working with Multiple Providers in Terraform

**30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya × Meru HashiCorp User Group × EveOps**


## Repository Structure

day14-terraform-challenge/
├── README.md                          ← You are here
├── docs/
│   ├── blog-post.md                   ← Full blog post for publication
│   └── learning-journal.md            ← Submission documentation (all 8 sections)
└── terraform/
    ├── multi-region/                  ← S3 cross-region replication demo
    │   ├── main.tf                    ← Providers, IAM, buckets, replication config
    │   ├── variables.tf               ← Input variables with validation
    │   ├── outputs.tf                 ← Deployment summary and resource ARNs
    │   ├── terraform.tfvars.example   ← Copy to terraform.tfvars and customise
    │   └── .terraform.lock.hcl.example ← Annotated lock file with field explanations
    └── multi-account/
        └── main.tf                    ← assume_role multi-account pattern + IAM docs



## Quick Start — Multi-Region Deployment

### Prerequisites

- Terraform >= 1.6.0 installed
- AWS credentials configured (`aws configure` or environment variables)
- IAM permissions: `s3:*`, `iam:CreateRole`, `iam:PutRolePolicy`

### Steps

```bash
cd terraform/multi-region

# Copy and customise variables
cp terraform.tfvars.example terraform.tfvars

# Initialise — downloads AWS provider and creates lock file
terraform init

# Preview what will be created
terraform plan

# Deploy
terraform apply

# View deployment summary
terraform output deployment_summary

# Clean up
terraform destroy
```

### What Gets Created

| Resource | Region | Purpose |
|----------|--------|---------|
| `aws_s3_bucket.primary` | us-east-1 | Source bucket (default provider) |
| `aws_s3_bucket.replica` | us-west-2 | Destination bucket (aliased provider) |
| `aws_iam_role.replication` | us-east-1 | Role S3 uses to replicate objects |
| `aws_s3_bucket_replication_configuration` | us-east-1 | Replication rule |
| Versioning on both buckets | Both regions | Required for replication |
| Encryption on both buckets | Both regions | AES-256 server-side encryption |
| Public access block on both | Both regions | Blocks all public access |

---

## Key Concepts Demonstrated

### Provider Aliases

```hcl
# Default provider — no alias — used by resources without provider argument
provider "aws" {
  region = "us-east-1"
}

# Aliased provider — must be explicitly referenced
provider "aws" {
  alias  = "replica"
  region = "us-west-2"
}

# Resource using default provider (us-east-1)
resource "aws_s3_bucket" "primary" {
  bucket = "my-primary-bucket"
}

# Resource using aliased provider (us-west-2)
resource "aws_s3_bucket" "replica" {
  provider = aws.replica
  bucket   = "my-replica-bucket"
}
```

### Version Constraint Operators

| Operator | Example | Meaning |
|----------|---------|---------|
| `=` | `= 5.0.0` | Exact version only |
| `~>` | `~> 5.0` | `>= 5.0.0, < 6.0.0` (**recommended**) |
| `>=` | `>= 5.0` | Minimum, no upper bound |
| `!=` | `!= 5.1.0` | Exclude a specific version |

### Multi-Account Pattern

```hcl
provider "aws" {
  alias  = "production"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::111111111111:role/TerraformDeployRole"
  }
}
```

---

## Challenge Info

This work is part of the **30-Day Terraform Challenge** organised by:
- [AWS AI/ML UserGroup Kenya](https://www.meetup.com/aws-ai-ml-usergroup-kenya/)
- Meru HashiCorp User Group
- EveOps
