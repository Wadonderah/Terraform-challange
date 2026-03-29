# Day 13: Managing Sensitive Data Securely in Terraform

> **30-Day Terraform Challenge** | AWS AI/ML UserGroup Kenya · Meru HashiCorp User Group · EveOps



## Overview

This repository is the complete submission for Day 13 of the 30-Day Terraform Challenge. It covers every secret leak path in Terraform, demonstrates AWS Secrets Manager integration, and provides a production-grade state-file security setup.


## Repository Structure


day13-terraform-secrets/
├── README.md                          ← Full learning journal (this file)
├── .gitignore                         ← Terraform-safe ignore rules
├── terraform/
│   ├── environments/
│   │   └── production/
│   │       ├── main.tf                ← Root module – wires everything together
│   │       ├── variables.tf           ← All input variables (sensitive flagged)
│   │       ├── outputs.tf             ← Outputs (sensitive flagged)
│   │       ├── backend.tf             ← S3 encrypted remote state
│   │       └── providers.tf           ← AWS provider (no credentials in code)
│   └── modules/
│       └── rds/
│           ├── main.tf                ← RDS instance using secrets from Secrets Manager
│           ├── variables.tf
│           └── outputs.tf
├── scripts/
│   ├── bootstrap-secrets.sh           ← One-time secret creation (never via Terraform)
│   └── iam-state-bucket-policy.json   ← Least-privilege IAM policy for state bucket
└── docs/
    ├── advanced-secrets-guide.md      ← Comprehensive multi-cloud secrets reference
    └── blog-post.md                   ← Full blog post: "How to Handle Sensitive Data Securely in Terraform"




## Learning Journal

### The Three Secret Leak Paths

Every security incident involving Terraform secrets can be traced to one of three leak paths. Understanding each one — and its secure alternative — is the foundation of secrets management.


#### Leak Path 1 — Hardcoded Values in `.tf` Files

**What happens:** A developer types a password directly into a resource argument. The moment `git add` runs, that secret is in version control history. Deleting it from the file does not remove it from Git history. Anyone who clones the repo — ever — can run `git log -p` and see it.

**Vulnerable pattern:**


# ❌ NEVER do this
resource "aws_db_instance" "example" {
  engine         = "mysql"
  instance_class = "db.t3.micro"
  username       = "admin"
  password       = "MyS3cur3P@ssw0rd!"   # Committed to Git forever
}


**Secure alternative — fetch from Secrets Manager at apply time:**

# ✅ Secret fetched at runtime, never written to any .tf file
data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = "prod/db/credentials"
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)
}

resource "aws_db_instance" "example" {
  engine         = "mysql"
  instance_class = "db.t3.micro"
  username       = local.db_creds["username"]
  password       = local.db_creds["password"]
}



#### Leak Path 2 — Variable Defaults Containing Secrets

**What happens:** A developer creates a variable with a `default` value containing a secret. Defaults live in `.tf` files and are therefore committed to source control alongside the rest of the configuration. Even with `sensitive = true`, the value itself is in Git.

**Vulnerable pattern:**

# ❌ Default value is committed to source control
variable "db_password" {
  description = "Database password"
  default     = "MyS3cur3P@ssw0rd!"   # Stored in .tf file → Git
}

**Secure alternative — no default, no hardcoded value:**

# ✅ No default forces the value to come from outside the codebase
variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
  # No default — Terraform will prompt at apply time,
  # or read from TF_VAR_db_password environment variable,
  # or receive the value from an upstream secrets pipeline.
}


The safest approach is to avoid input variables for secrets altogether and use a data source (Secrets Manager, Vault) instead, so the secret never passes through variable assignment at all.



#### Leak Path 3 — Plaintext Secrets in State Files

**What happens:** Even when you handle the first two leak paths perfectly, Terraform writes the _resolved_ values of resource attributes into `terraform.tfstate` in plaintext JSON. For an RDS instance, that means `username` and `password` appear verbatim in the state file. Anyone with read access to the state file has access to every secret it contains.

**Vulnerable pattern (local state — never use in production):**


# ❌ Local state file sits on disk, unencrypted, often accidentally committed
terraform {
  # No backend configured → defaults to local state
}


**Secure alternative — encrypted remote state with restricted access:**


# ✅ Remote state: encrypted at rest, versioned, access-controlled
terraform {
  backend "s3" {
    bucket         = "acme-terraform-state-prod"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true   # AES-256 server-side encryption
  }
}


State file security requires three controls together:
1. **Encryption at rest** (`encrypt = true` + S3 SSE-KMS or SSE-S3)
2. **Versioning** so accidental overwrites can be recovered
3. **Restricted IAM access** — only the roles that run Terraform should be able to read the bucket



### AWS Secrets Manager Integration

The complete data source configuration used in this project:


# Step 1: Reference the secret by name (created manually via CLI, never via Terraform)
data "aws_secretsmanager_secret" "db_credentials" {
  name = "prod/db/credentials"
}

# Step 2: Fetch the current version of the secret
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

# Step 3: Decode the JSON payload into a local map
locals {
  db_credentials = jsondecode(
    data.aws_secretsmanager_secret_version.db_credentials.secret_string
  )
}

# Step 4: Reference the local map values in the resource
resource "aws_db_instance" "primary" {
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  db_name           = "appdb"
  allocated_storage = 20
  skip_final_snapshot = true

  username = local.db_credentials["username"]
  password = local.db_credentials["password"]

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Encryption at rest
  storage_encrypted = true
}


**The secret value does not appear anywhere in any `.tf` file.** It is fetched at apply time from Secrets Manager, decoded in memory, and referenced through the local. The only place the resolved value persists is the encrypted state file.

---

### Sensitive Variable and Output Declarations


# variables.tf
variable "db_password" {
  description = "Database administrator password — passed via TF_VAR_db_password or secrets pipeline"
  type        = string
  sensitive   = true
  # No default
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}
```

```hcl
# outputs.tf
output "db_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = aws_db_instance.primary.endpoint
  sensitive   = false   # Endpoint is not a secret
}

output "db_connection_string" {
  description = "Full JDBC connection string — contains credentials, handle carefully"
  value       = "mysql://${aws_db_instance.primary.username}@${aws_db_instance.primary.endpoint}/${aws_db_instance.primary.db_name}"
  sensitive   = true
}


**What Terraform shows in plan/apply output with `sensitive = true`:**


Changes to Outputs:
  + db_connection_string = (sensitive value)
  + db_endpoint          = "mydb.abc123.us-east-1.rds.amazonaws.com:3306"


The sensitive output is never printed. The non-sensitive endpoint is shown normally.



### State File Security Audit

**Backend configuration:**


terraform {
  backend "s3" {
    bucket         = "acme-terraform-state-prod"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}


**S3 bucket controls verified:**

| Control | Status | Notes |
|---|---|---|
| Block all public access | ✅ Enabled | All four block settings on |
| Bucket versioning | ✅ Enabled | 90-day lifecycle to Glacier for old versions |
| Server-side encryption | ✅ AES-256 | `encrypt = true` in backend config |
| Access logging | ✅ Enabled | Logs to separate `acme-tf-state-access-logs` bucket |
| Bucket policy | ✅ Restricted | Allow only `TerraformExecutionRole` and CI/CD role |
| DynamoDB lock table | ✅ Present | `terraform-state-locks` with PAY_PER_REQUEST billing |

**IAM policy restricting bucket access** — see `scripts/iam-state-bucket-policy.json`. Only the named IAM roles can `GetObject`, `PutObject`, or `DeleteObject` on the state bucket. All other principals are explicitly denied.



### .gitignore Contents and Rationale

```gitignore
# Terraform working directory — contains provider binaries (100MB+) and cached state
.terraform/

# Lock file — provider version pins; commit this if you want reproducible builds,
# but exclude if you prefer to re-lock on each clone
# .terraform.lock.hcl

# Local state files — NEVER commit; contain plaintext secrets
*.tfstate
*.tfstate.backup

# Variable files — often contain environment-specific values or secrets
# Add terraform.tfvars to version control only if it contains no secrets
*.tfvars
*.tfvars.json

# Override files — local developer overrides, never shared
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# CLI config — machine-specific credentials file
.terraformrc
terraform.rc

# Crash logs
crash.log
crash.*.log

# Environment variable files
.env
.env.*
```

**Key entries explained:**

- **`.terraform/`** — Provider plugins and cached modules. These are hundreds of megabytes of binary files that belong in a registry, not Git.
- **`*.tfstate` / `*.tfstate.backup`** — Contain plaintext secrets. Use remote state exclusively.
- **`*.tfvars`** — Variable value files. If you put secrets in them, they must never be committed. Exclude all `.tfvars` by default and explicitly add back only the ones confirmed to contain no secrets.
- **`crash.log`** — Terraform crash logs can contain state data and sensitive values.



### Chapter 6 Learnings

**Does `sensitive = true` prevent secrets from being stored in state?**

No. `sensitive = true` is a display control, not a storage control. It tells Terraform to replace the value with `(sensitive value)` in plan and apply terminal output, and to redact it from JSON plan files. The actual value is still written to `terraform.tfstate` in plaintext. The only way to protect state-file secrets is to encrypt and restrict access to the state file itself.

**HashiCorp Vault vs AWS Secrets Manager — when to use each:**

| | AWS Secrets Manager | HashiCorp Vault |
|---|---|---|
| **Best for** | AWS-native workloads; RDS credential rotation built in | Multi-cloud or on-premises; fine-grained access policies |
| **Rotation** | Automatic Lambda-based rotation for supported services | Dynamic secrets — Vault generates short-lived credentials on demand |
| **Auth methods** | IAM roles and policies | LDAP, Kubernetes, GitHub, AWS, Azure, GCP, and more |
| **Cost** | $0.40/secret/month + API call fees | OSS free; Enterprise paid; self-hosting adds ops burden |
| **Terraform integration** | `aws_secretsmanager_secret_version` data source | `vault_generic_secret` data source or Vault Agent |
| **Choose when** | You are all-in on AWS and want managed rotation | You have heterogeneous infrastructure or need dynamic secrets |

**Why can you not fully prevent secrets from appearing in state for some resource types?**

Terraform must store the complete desired state of every resource so it can calculate diffs on subsequent plans. For resources like `aws_db_instance`, the provider marks `password` as computed-and-sensitive, but Terraform has no mechanism to store a reference to a secret rather than the secret value itself. The state file must contain the actual password so Terraform knows what value is currently deployed. Until Terraform adds first-class secret references (storing a Secrets Manager ARN instead of the resolved value), secrets will appear in state for any resource that accepts them as plain string attributes.



### Challenges and Fixes

**IAM permissions for Secrets Manager**

The data source call requires `secretsmanager:GetSecretValue` on the specific secret ARN. A common mistake is granting this permission at the `*` resource level during testing and forgetting to tighten it. The policy in `scripts/iam-state-bucket-policy.json` uses the exact ARN. If the execution role is missing `secretsmanager:DescribeSecret`, Terraform throws a cryptic `AccessDeniedException` on the `aws_secretsmanager_secret` data source rather than the version data source — trace the error to the right call.

**jsondecode parsing**

`jsondecode` returns a Terraform object. Accessing a key that does not exist in the JSON payload produces a runtime error, not a null. Always validate the secret payload format manually with `aws secretsmanager get-secret-value --secret-id prod/db/credentials | jq .SecretString | jq -r .` before running `terraform apply`.

**Sensitive output handling**

Terraform 0.15+ will error if a non-sensitive output references a sensitive value without explicitly setting `sensitive = true`. The error message is clear, but engineers sometimes work around it by casting with `nonsensitive()` — this defeats the purpose and should never be done for actual secrets.



## Quick Start

```bash
# 1. Create the secret (one time, before any Terraform run)
bash scripts/bootstrap-secrets.sh

# 2. Export AWS credentials via environment variables — never hardcode
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# 3. Initialise Terraform (downloads providers, configures remote backend)
cd terraform/environments/production
terraform init

# 4. Review the plan — sensitive values show as (sensitive value)
terraform plan

# 5. Apply
terraform apply
```



## References

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Terraform Sensitive Values](https://developer.hashicorp.com/terraform/language/values/outputs#sensitive-suppressing-values-in-cli-output)
- [HashiCorp Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Terraform AWS Secrets Manager Data Source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret)
- [Protecting Sensitive Data in Terraform State](https://developer.hashicorp.com/terraform/language/state/sensitive-data)
