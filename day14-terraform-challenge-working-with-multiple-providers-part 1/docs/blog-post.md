# Getting Started with Multiple Providers in Terraform

*Day 14 of the 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya × EveOps*

---

## Introduction

One of the most powerful — and most misunderstood — features in Terraform is its provider system. Once you understand how providers are installed, versioned, and aliased, multi-region and multi-account deployments become surprisingly clean patterns rather than scary special cases.

Today I deployed a fully working S3 cross-region replication setup using two AWS regions and a single Terraform configuration. Here is everything I learned.

---

## What Is a Provider?

A **provider** is a plugin that translates Terraform's declarative resource blocks into actual API calls for a specific platform. When you write:

```hcl
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-bucket-name"
}
```

Terraform does not know how to talk to AWS on its own. The `hashicorp/aws` provider translates that resource declaration into the correct S3 `CreateBucket` API call, handles authentication, deals with retries, and maps the response back into Terraform state.

Providers exist for every major platform: AWS, Azure, GCP, Kubernetes, Datadog, GitHub, and hundreds more — all available on the [Terraform Registry](https://registry.terraform.io/).

---

## Provider Installation: What Happens at `terraform init`

When you run `terraform init`, Terraform reads your `required_providers` block and executes a multi-step process:

1. **Resolves the source address** — `hashicorp/aws` expands to `registry.terraform.io/hashicorp/aws`
2. **Evaluates the version constraint** — Fetches the list of published releases and selects the newest that satisfies your constraint
3. **Downloads the binary** — Fetches the correct binary for your OS and CPU architecture
4. **Verifies integrity** — Compares the binary hash against the checksums in your `.terraform.lock.hcl` file (or generates the lock file on first run)
5. **Installs to `.terraform/providers/`** — Places the binary where Terraform can execute it

```
.terraform/
└── providers/
    └── registry.terraform.io/
        └── hashicorp/
            └── aws/
                └── 5.82.0/
                    └── linux_amd64/
                        └── terraform-provider-aws_v5.82.0_x5
```

---

## Version Constraints: Pinning Done Right

Version constraints are how you balance stability with staying current.

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### Constraint Operators Explained

| Operator | Example | Meaning |
|----------|---------|---------|
| `=` | `= 5.0.0` | Exact version only. Too rigid for teams. |
| `!=` | `!= 5.1.0` | Exclude a specific broken release. |
| `>`, `>=` | `>= 5.0` | Minimum version. No upper bound — risky. |
| `<`, `<=` | `< 6.0` | Maximum version. |
| `~>` | `~> 5.0` | **Pessimistic constraint.** Allows patch/minor but blocks major. `~> 5.0` = `>= 5.0, < 6.0`. **This is the recommended operator.** |

The `~>` operator is the right default for most teams. It lets you absorb bug fixes and new resource types automatically, while ensuring a major version (which typically contains breaking changes) never sneaks in unexpectedly.

---

## The `.terraform.lock.hcl` File

The lock file is the most underrated file in your Terraform project. It records the **exact** version selected after resolving your constraint, plus cryptographic hashes for every platform binary.

```hcl
provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.82.0"
  constraints = "~> 5.0"
  hashes = [
    "h1:3k4iFVVlHHaNoFKxz4TKPdRJYSS3F4gOR9BWBV9FQIY=",
    "zh:0b4a9cb48b55aa1c7059b57e24e79aa78a3c7c0d67b5f8e21b2d0e7b46a3d10a",
    ...
  ]
}
```

### What Each Field Means

- **`version`** — The resolved, pinned version. Future `terraform init` runs use this exact version even if a newer patch is published.
- **`constraints`** — Recorded for drift detection. If you tighten the constraint later, Terraform can warn you.
- **`hashes`** — SHA-256 checksums of every OS/architecture binary. Before trusting a downloaded binary, Terraform verifies its hash. A tampered binary cannot pass this check.

### Always Commit This File

The lock file should **always be committed to version control**. Here is why:

1. **Reproducibility** — Every developer, every CI run, uses the identical provider binary
2. **Security** — Hash verification prevents supply-chain attacks (swapped binaries)
3. **Audit trail** — `git log .terraform.lock.hcl` shows exactly when and why you upgraded

To upgrade a provider within your constraint: `terraform init -upgrade`

---

## Provider Aliases: The Key to Multi-Region Deployments

By default, every resource in your configuration uses the single default provider. To deploy resources in a second region (or account), you define an **aliased provider**.

```hcl
# Default provider — primary region (us-east-1)
# Used by any resource that does NOT specify a provider argument
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}

# Aliased provider — replica region (us-west-2)
# Used only by resources that explicitly reference aws.replica
provider "aws" {
  alias  = "replica"
  region = "us-west-2"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Role      = "Replica"
    }
  }
}
```

### How Terraform Determines Which API Endpoint to Call

When Terraform plans a resource, it follows this lookup:

1. Does the resource have an explicit `provider = aws.<alias>` argument? Use that provider.
2. Is there a default (no-alias) provider of the matching type? Use that.
3. No match — Terraform throws a configuration error.

Each provider configuration resolves to a specific API endpoint, authentication credential, and region. The provider binary handles the actual HTTP call; Terraform just routes the resource to the right provider instance.

---

## Practical Demo: S3 Cross-Region Replication

Here is the full pattern using provider aliases to deploy a primary bucket in `us-east-1` and a replica in `us-west-2`.

### Resources in the Primary Region (default provider)

```hcl
resource "aws_s3_bucket" "primary" {
  # No provider argument → uses default provider (us-east-1)
  bucket = "my-app-primary-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

### Resources in the Replica Region (aliased provider)

```hcl
resource "aws_s3_bucket" "replica" {
  provider = aws.replica  # Explicit reference → calls us-west-2 S3 endpoint
  bucket   = "my-app-replica-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

### Replication Configuration

```hcl
resource "aws_s3_bucket_replication_configuration" "primary_to_replica" {
  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.replica,
  ]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "replicate-all-objects"
    status = "Enabled"

    filter {
      prefix = ""
    }

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD_IA"
    }
  }
}
```

> **Key insight:** The `aws_s3_bucket_replication_configuration` resource lives in the *primary* region (default provider) because the replication rule is a property of the source bucket. The destination bucket ARN is just a reference — no provider alias needed on the replication configuration resource itself.

---

## Multi-Account Deployments with `assume_role`

For multi-account architectures, extend the alias pattern with `assume_role`:

```hcl
provider "aws" {
  alias  = "production"
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::111111111111:role/TerraformDeployRole"
    session_name = "terraform-deploy-prod"
  }
}

provider "aws" {
  alias  = "staging"
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::222222222222:role/TerraformDeployRole"
    session_name = "terraform-deploy-staging"
  }
}
```

Terraform authenticates with your local credentials (or the CI runner's IAM role), calls `sts:AssumeRole` to get short-lived credentials for each target account, then makes API calls as that assumed role. The executing identity needs `sts:AssumeRole` on the target role ARNs.

The `TerraformDeployRole` in each account needs a trust policy allowing your management account to assume it, and a permission policy scoped to exactly what Terraform needs to manage in that account.

---

## Key Takeaways

- Every resource needs exactly one provider. Terraform determines it via the explicit `provider` argument, then falls back to the default (no-alias) provider of the matching resource type.
- Version constraints with `~>` are the sweet spot: auto-update within a major version, block breaking changes.
- The lock file is your safety net — commit it, upgrade it intentionally, and never ignore hash mismatch errors.
- Provider aliases are the clean, Terraform-native solution to multi-region and multi-account deployments. No hacks, no wrapper scripts.

---

## Resources

- [Terraform AWS Provider Registry](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Dependency Lock File Docs](https://developer.hashicorp.com/terraform/language/files/dependency-lock)
- [Provider Version Constraints](https://developer.hashicorp.com/terraform/language/expressions/version-constraints)
- [AWS S3 Cross-Region Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)

---

*#30DayTerraformChallenge #Terraform #AWS #MultiRegion #IaC #AWSUserGroupKenya #EveOps*
