# Advanced Secrets Management in Terraform: A Multi-Cloud Reference Guide

> A practical reference for infrastructure engineers who need to handle secrets correctly across AWS, Azure, GCP, and on-premises environments.

---

## The Three Leak Paths (and How to Close Each One)

Every secret incident in a Terraform-managed environment originates from one of three paths.

### Leak Path 1 — Hardcoded Values in Configuration Files

Secrets typed directly into `.tf` files are committed to version control the moment `git add` runs. Git history is permanent — even if you delete the value in a later commit, `git log -p` will reveal it forever.

**Vulnerable:**
```hcl
resource "aws_db_instance" "example" {
  password = "MyP@ssw0rd!"   # In Git forever
}
```

**Secure:** Use a data source to fetch the value at apply time:
```hcl
locals {
  creds = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)
}
resource "aws_db_instance" "example" {
  password = local.creds["password"]   # Never written to any file
}
```

### Leak Path 2 — Variable Default Values

`default` values live in `.tf` files. A variable with a default containing a secret is no different from a hardcoded value.

**Vulnerable:**
```hcl
variable "api_key" {
  default = "sk-abc123"   # Committed to source control
}
```

**Secure:** No default; supply via environment variable or secrets pipeline:
```hcl
variable "api_key" {
  type      = string
  sensitive = true
  # No default — supply via TF_VAR_api_key or upstream data source
}
```

The best approach: eliminate the variable entirely and use a data source.

### Leak Path 3 — Plaintext in State Files

Terraform stores the resolved value of every resource attribute in `terraform.tfstate`. For an RDS instance, that means the password is in the state file in plaintext JSON, regardless of how carefully you handled the first two paths.

**Mitigation strategy:**
1. Use remote state with encryption at rest (S3 SSE-KMS or equivalent)
2. Enable bucket versioning for recovery from accidental overwrites
3. Restrict access via IAM to only the principals that run Terraform
4. Enable access logging on the state bucket
5. Never commit `.tfstate` files to version control (enforce with `.gitignore`)

---

## AWS Secrets Manager Integration Pattern

### Creating the Secret (Bootstrap — Do This Once, Outside Terraform)

```bash
aws secretsmanager create-secret \
  --name "prod/db/credentials" \
  --description "Production RDS master credentials" \
  --secret-string '{"username":"dbadmin","password":"YourSecurePassword"}' \
  --region us-east-1
```

Never create secrets with Terraform — the `secret_string` argument is stored in state.

### Fetching at Apply Time

```hcl
data "aws_secretsmanager_secret" "db" {
  name = "prod/db/credentials"
}

data "aws_secretsmanager_secret_version" "db" {
  secret_id = data.aws_secretsmanager_secret.db.id
}

locals {
  db = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)
}

resource "aws_db_instance" "primary" {
  username = local.db["username"]
  password = local.db["password"]
  # All other required arguments omitted for brevity
}
```

### Automatic Rotation

Enable rotation so credentials change on a schedule without any Terraform involvement:

```bash
aws secretsmanager rotate-secret \
  --secret-id "prod/db/credentials" \
  --rotation-lambda-arn "arn:aws:lambda:us-east-1:123456789012:function:SecretsManagerRDSRotation" \
  --rotation-rules AutomaticallyAfterDays=30
```

After rotation, the next `terraform plan` will detect no drift because the data source always fetches `AWSCURRENT`. The RDS instance itself is updated by the rotation Lambda — Terraform does not need to intervene.

---

## HashiCorp Vault Integration Pattern

Use Vault when you need dynamic secrets, multi-cloud support, or fine-grained access policies beyond what Secrets Manager provides.

### Provider Configuration

```hcl
provider "vault" {
  address = "https://vault.your-company.com:8200"
  # Auth via environment: VAULT_TOKEN or VAULT_ROLE_ID + VAULT_SECRET_ID
}
```

### Fetching a Static Secret

```hcl
data "vault_generic_secret" "db_credentials" {
  path = "secret/prod/db/credentials"
}

resource "aws_db_instance" "primary" {
  username = data.vault_generic_secret.db_credentials.data["username"]
  password = data.vault_generic_secret.db_credentials.data["password"]
}
```

### Dynamic Secrets (the Vault Advantage)

Vault can generate short-lived database credentials on demand. The credential exists only for the duration of the lease:

```hcl
data "vault_database_secret_backend_creds" "db" {
  backend = "database"
  role    = "terraform-rds-role"
}

resource "aws_db_instance" "primary" {
  username = data.vault_database_secret_backend_creds.db.username
  password = data.vault_database_secret_backend_creds.db.password
}
```

### When to Choose Vault Over Secrets Manager

| Requirement | Secrets Manager | Vault |
|---|---|---|
| AWS-only infrastructure | ✅ Simpler | ⬜ Overkill |
| Multi-cloud or on-premises | ⬜ AWS-only | ✅ Native support |
| Dynamic secrets (short-lived) | ⬜ Not supported | ✅ Core feature |
| Automatic RDS rotation | ✅ Built-in | ⬜ Requires plugin |
| No self-hosting burden | ✅ Fully managed | ⬜ You operate it |
| LDAP / Kubernetes / GitHub auth | ⬜ Not supported | ✅ 15+ auth methods |

---

## Environment Variable Handling for Provider Credentials

### AWS

```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."          # If using temporary credentials
export AWS_DEFAULT_REGION="us-east-1"
```

The AWS provider reads these automatically. Never put these values in provider blocks.

**Preferred for workloads running in AWS:** Use an IAM instance profile or ECS task role. No static credentials required.

**Preferred for CI/CD:** Use OIDC federation (GitHub Actions → AWS OIDC provider) to generate short-lived session credentials. No static access keys stored anywhere.

### Azure

```bash
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."
```

### GCP

```bash
export GOOGLE_CREDENTIALS="$(cat service-account-key.json)"
# Or: use Application Default Credentials
gcloud auth application-default login
```

---

## State File Security Checklist

Run through every item before your first production apply.

```
[ ] Remote backend configured (S3, Azure Blob, GCS, or Terraform Cloud)
[ ] Encryption at rest enabled (encrypt = true + SSE-KMS recommended)
[ ] Block all public access enabled on the S3/GCS bucket
[ ] Bucket versioning enabled
[ ] Access logging enabled (logs to separate bucket)
[ ] IAM bucket policy: allow only named Terraform execution roles
[ ] DynamoDB lock table configured (prevents concurrent applies)
[ ] .gitignore includes *.tfstate and *.tfstate.backup
[ ] .terraform/ directory excluded from version control
[ ] *.tfvars files excluded (or audited and confirmed secret-free)
[ ] CI/CD pipeline injects credentials from a secrets store, not YAML
[ ] KMS key rotation enabled on the key encrypting the state bucket
[ ] CloudTrail logging enabled for S3 GetObject on the state bucket
```

---

## .gitignore Template for Terraform Projects

```gitignore
# Terraform working directory — provider binaries, cached modules
.terraform/

# Local state files — contain plaintext secrets
*.tfstate
*.tfstate.backup

# Variable value files — may contain secrets
*.tfvars
*.tfvars.json

# Local override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# CLI credentials
.terraformrc
terraform.rc

# Crash logs — can contain state fragments
crash.log
crash.*.log

# Environment files
.env
.env.*
.envrc
```

---

## IAM Policy for Least-Privilege State Bucket Access

Attach this policy to the IAM role your Terraform runs assume. Replace the ARNs with your actual values.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateReadWrite",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::your-state-bucket/production/*"
    },
    {
      "Sid": "TerraformStateLock",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:123456789012:table/terraform-state-locks"
    },
    {
      "Sid": "SecretsManagerRead",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/*"
    }
  ]
}
```

---

## Key Takeaways

1. **Secrets in `.tf` files are permanent** — Git history cannot be fully purged without a force-push that breaks every clone.
2. **Variable defaults are just as dangerous** — They live in the same committed files.
3. **State files always contain secrets** — Accept this and protect the state file instead of trying to work around it.
4. **`sensitive = true` is a display control, not a security control** — It prevents terminal leakage but does nothing for the state file.
5. **Remote state + encryption + IAM restriction** is the minimum viable state security posture for any production system.
6. **Bootstrap secrets outside Terraform** — Creating secrets with Terraform writes them to state. Use the CLI or a secrets pipeline for the initial seed.

---

*Written as part of Day 13 of the 30-Day Terraform Challenge.*
*AWS AI/ML UserGroup Kenya · Meru HashiCorp User Group · EveOps*
