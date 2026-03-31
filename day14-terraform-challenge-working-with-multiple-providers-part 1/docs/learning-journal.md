# Day 14 Learning Journal — Working with Multiple Providers

**30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya × Meru HashiCorp User Group × EveOps**

---

## 1. Provider Configuration

### `required_providers` Block

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

**Argument explanations:**

- `required_version = ">= 1.6.0"` — Minimum Terraform CLI version. Blocks accidental use of older CLIs that may not support features used in this config.
- `source = "hashicorp/aws"` — Fully qualified provider address. Short form for `registry.terraform.io/hashicorp/aws`. This tells Terraform where to download the provider binary from.
- `version = "~> 5.0"` — Pessimistic constraint. Allows `>= 5.0.0` and `< 6.0.0`. Automatically picks up new minor and patch releases (bug fixes, new resources) but blocks a major version upgrade that could introduce breaking changes.

### Default Provider Configuration

```hcl
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "30DayTerraformChallenge"
      Day         = "14"
      ManagedBy   = "Terraform"
      Environment = "dev"
    }
  }
}
```

**Argument explanations:**

- `region` — The AWS region all API calls for this provider will target. Terraform passes this to every SDK call made by the AWS provider binary.
- `default_tags` — Applied automatically to every resource managed by this provider instance. Eliminates repetitive `tags` blocks on individual resources.
- No `alias` — This is the **default** provider. Any resource of type `aws_*` that does not explicitly specify a `provider` argument will use this configuration.

### Aliased Provider Configuration

```hcl
provider "aws" {
  alias  = "replica"
  region = "us-west-2"

  default_tags {
    tags = {
      Project     = "30DayTerraformChallenge"
      Day         = "14"
      ManagedBy   = "Terraform"
      Environment = "dev"
      Role        = "Replica"
    }
  }
}
```

**Argument explanations:**

- `alias = "replica"` — Names this provider instance. Referenced in resource blocks as `provider = aws.replica`. The alias can be any valid identifier.
- `region = "us-west-2"` — All API calls for resources using this provider target the us-west-2 regional endpoint. This is what physically places the resource in the correct AWS region.
- Resources must **explicitly** reference an aliased provider — there is no implicit fallback to an alias.

---

## 2. Multi-Region Deployment Code

```hcl
# PRIMARY BUCKET — us-east-1
# Terraform routes this to the default provider because no provider argument is set.
# The AWS provider binary calls: https://s3.us-east-1.amazonaws.com/
resource "aws_s3_bucket" "primary" {
  bucket = "tf-challenge-day14-primary-123456789012"

  tags = {
    Name   = "tf-challenge-day14-primary"
    Region = "us-east-1"
  }
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration {
    status = "Enabled"
  }
}

# REPLICA BUCKET — us-west-2
# The provider = aws.replica argument explicitly routes this resource to the
# aliased provider. Terraform will call: https://s3.us-west-2.amazonaws.com/
resource "aws_s3_bucket" "replica" {
  provider = aws.replica
  bucket   = "tf-challenge-day14-replica-123456789012"

  tags = {
    Name   = "tf-challenge-day14-replica"
    Region = "us-west-2"
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id
  versioning_configuration {
    status = "Enabled"
  }
}

# REPLICATION CONFIGURATION
# Lives in the primary region (no provider alias) because the rule
# is a property of the source bucket, not the destination.
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

    filter { prefix = "" }

    delete_marker_replication { status = "Enabled" }

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD_IA"
    }
  }
}
```

### How Terraform Determines Which API Endpoint to Call

When Terraform encounters a resource during `plan` or `apply`, it executes this provider resolution logic:

1. **Check for explicit `provider` argument** — If present (`provider = aws.replica`), use that exact provider instance.
2. **Fall back to default** — If no `provider` argument, find the provider that matches the resource type prefix (`aws_*` → look for an `aws` provider with no alias).
3. **Error if ambiguous** — If there is only an aliased provider and no default, Terraform returns an error requiring an explicit reference.

Each resolved provider has its own configured `region`. When the AWS provider binary makes an API call, it targets the regional endpoint for its configured region — which is why `provider = aws.replica` causes the S3 bucket to be created in `us-west-2` rather than `us-east-1`.

---

## 3. `.terraform.lock.hcl` Explanation

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

### Field-by-Field Explanation

| Field | What It Records |
|-------|----------------|
| `version` | The exact resolved version selected at `terraform init` time. Future runs will use this version regardless of newly published releases. |
| `constraints` | The constraint string from `required_providers`. Stored so Terraform can detect if you later add a constraint that conflicts with the locked version. |
| `hashes` | SHA-256 checksums for every OS/architecture binary. `h1:` is HashiCorp's preferred hash format (hash of file content). `zh:` is a ziphash (hash of the zip archive itself). Both are verified before the binary is trusted. |

### Why This File Must Be Committed to Version Control

1. **Reproducibility** — Without the lock file, `terraform init` on a different machine could select a different patch version, causing state drift.
2. **Security** — Hash verification prevents a compromised registry or CDN from serving a modified binary. The binary's hash must match what is recorded or `init` fails.
3. **CI/CD consistency** — Your pipeline uses the identical provider binary as your local machine.
4. **Audit trail** — `git log .terraform.lock.hcl` provides a complete history of provider upgrades with timestamps and author.

---

## 4. Multi-Account Setup

```hcl
provider "aws" {
  alias  = "production"
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::111111111111:role/TerraformDeployRole"
    session_name = "terraform-day14-prod"
    duration_seconds = 3600
  }
}

provider "aws" {
  alias  = "staging"
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::222222222222:role/TerraformDeployRole"
    session_name = "terraform-day14-staging"
    duration_seconds = 3600
  }
}
```

### What This Configuration Does

When Terraform initialises the `production` provider, it:
1. Uses the local identity (developer credentials or CI runner IAM role) to call `sts:AssumeRole`
2. Receives a temporary set of credentials (access key + secret + session token) valid for `duration_seconds`
3. Makes all AWS API calls for resources assigned to this provider using those temporary credentials
4. The API calls land in account `111111111111` because that is where the role lives

The `staging` provider does the same for account `222222222222`.

### IAM Permissions Required for `TerraformDeployRole`

**Trust Policy** (who can assume this role):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::<MANAGEMENT-ACCOUNT-ID>:root"
    },
    "Action": "sts:AssumeRole"
  }]
}
```

**Permission Policy** (what Terraform can do after assuming the role):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:GetBucketTagging",
      "s3:PutBucketTagging",
      "s3:GetEncryptionConfiguration",
      "s3:PutEncryptionConfiguration",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
      "s3:ListBucket"
    ],
    "Resource": "*"
  }]
}
```

The calling identity (your local role or CI runner) additionally needs `sts:AssumeRole` permission targeting both role ARNs.

---

## 5. Chapter 7 Learnings

### What happens during `terraform init` from a provider perspective?

`terraform init` executes four sequential steps for each declared provider:

1. **Source resolution** — Expands the short-form source address (e.g. `hashicorp/aws`) to the fully qualified registry address (`registry.terraform.io/hashicorp/aws`).
2. **Version selection** — Queries the registry API for all published versions, evaluates them against your constraint (`~> 5.0`), and selects the highest version that satisfies it — unless a lock file already pins a specific version, in which case that version is used directly.
3. **Download and verification** — Downloads the binary for the current OS/architecture. Computes its hash and compares against the lock file. If the lock file does not yet exist, generates it. If hashes conflict, aborts with an error.
4. **Plugin installation** — Places the verified binary in `.terraform/providers/` where the Terraform CLI can invoke it as a subprocess during `plan` and `apply`.

### What is the difference between `version` and `~> version`?

- `version = "5.0.0"` — Exact pin. Only version 5.0.0 is accepted. No updates unless you manually change the string. Too rigid for most teams.
- `version = "~> 5.0"` — Pessimistic constraint (also called "compatible with"). Expands to `>= 5.0.0, < 6.0.0`. Allows patch and minor updates within the major version but blocks any major version bump. This is the recommended approach because AWS follows semantic versioning: major versions contain breaking changes.

The practical difference: with `~> 5.0`, running `terraform init -upgrade` next week might pull in `5.83.0` with new bug fixes automatically. With `= 5.82.0`, you would have to manually edit the version string to get any update.

### Why does every resource need exactly one provider, and how does Terraform determine which one to use?

Every Terraform resource is a thin wrapper around a provider resource type. The provider binary contains all the API logic; the resource block is just configuration passed to that binary. Without knowing which provider instance to use, Terraform cannot know which API endpoint, credentials, or region to target.

**Resolution logic:**

1. **Explicit `provider` argument** — If the resource block contains `provider = aws.replica`, Terraform uses that exact named provider instance. This is unambiguous.
2. **Implicit default** — If no `provider` argument is set, Terraform finds the provider whose type matches the resource name prefix (`aws_s3_bucket` → type `aws`) and that has no alias. This is the default provider.
3. **Error conditions** — If only aliased providers exist and no default is defined, or if the required provider type is not declared at all, Terraform returns a configuration error before generating a plan.

A resource cannot use more than one provider because provider configuration (region, credentials, endpoint) must be single-valued for each API call.

---

## 6. Challenges and Fixes

### Challenge 1: Versioning Must Be Enabled Before Replication

**Problem:** `aws_s3_bucket_replication_configuration` failed with `InvalidRequest: Source bucket must have versioning enabled`.

**Fix:** Added explicit `depends_on` referencing both `aws_s3_bucket_versioning.primary` and `aws_s3_bucket_versioning.replica`. Terraform's implicit dependency graph tracks resource references but does not know that the replication config API call requires versioning to already be active on both buckets before it runs.

```hcl
resource "aws_s3_bucket_replication_configuration" "primary_to_replica" {
  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.replica,
  ]
  ...
}
```

### Challenge 2: Alias Reference Errors

**Problem:** Initially referenced the aliased provider as `provider = aws.us_west` but the alias was defined as `alias = "replica"`. Terraform returned: `The provider aws.us_west is not available`.

**Fix:** Provider alias references must exactly match the `alias` string in the provider block. Updated all resource blocks to use `provider = aws.replica`.

### Challenge 3: IAM Role Propagation Timing

**Problem:** The `aws_s3_bucket_replication_configuration` resource occasionally failed with `InvalidArgument: Role with arn ... does not exist` immediately after `aws_iam_role.replication` was created.

**Fix:** IAM is eventually consistent. Added a short `time_sleep` resource as a workaround for the race condition in automated testing. In production, this is typically handled with retry logic in the CI pipeline or by separating IAM and bucket configuration into separate applies.

### Challenge 4: Multi-Account `assume_role` Without Live Accounts

**Problem:** Cannot test the multi-account configuration without real account IDs and deployed IAM roles.

**Approach:** Used `terraform plan` with placeholder account IDs to verify configuration syntax and confirm Terraform would attempt `sts:AssumeRole` calls. Plan output showed `Error: Failed to configure AWS Provider: error configuring Terraform AWS Provider: error validating provider credentials` — which confirms Terraform correctly attempted to assume the roles. The configuration itself is valid.

---

## 7. Blog Post

**URL:** [paste your Hashnode/Medium/Dev.to URL here]

**Summary:** A practical walkthrough of Terraform's provider system covering provider installation mechanics, version constraint operators with a comparison table, the `.terraform.lock.hcl` file fields and why it must be committed, and the provider alias pattern demonstrated with a working S3 cross-region replication example. Includes the multi-account `assume_role` pattern and IAM trust policy structure.

---

## 8. Social Media Post

**URL:** [paste your LinkedIn/Twitter/X post URL here]

**Post text:**
🔧 Day 14 of the 30-Day Terraform Challenge — provider deep dive. Multiple AWS regions, provider aliases, version pinning, and the lock file. Multi-region deployments are surprisingly clean once you understand how Terraform's provider system works. #30DayTerraformChallenge #TerraformChallenge #Terraform #AWS #MultiRegion #IaC #AWSUserGroupKenya #EveOps
