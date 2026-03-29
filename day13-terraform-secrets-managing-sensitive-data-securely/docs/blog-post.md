# How to Handle Sensitive Data Securely in Terraform

*Day 13 of the 30-Day Terraform Challenge — AWS AI/ML UserGroup Kenya*

---

The number one security mistake Terraform engineers make is not using a misconfigured security group or an overly permissive IAM role. It is letting secrets — database passwords, API keys, TLS private keys — end up somewhere they should never be. In a `.tf` file. In a Git repository. In a plaintext state file on a public S3 bucket.

This guide walks through every way secrets leak in Terraform, shows you the concrete fix for each one, and gives you a state-file security checklist you can run through before every production deployment.

---

## The Three Ways Secrets Leak in Terraform

### Leak Path 1: Hardcoded Values in Configuration Files

This is the most obvious mistake, yet it still happens. A developer is working fast, they need the database to come up, so they type the password directly into the resource block.

```hcl
# ❌ This password is now in Git — permanently
resource "aws_db_instance" "primary" {
  engine         = "mysql"
  instance_class = "db.t3.micro"
  username       = "admin"
  password       = "SuperSecret123!"
}
```

The moment `git add .` runs, that password is committed. The moment `git push` runs, it is on GitHub, GitLab, or Bitbucket — potentially forever. Deleting the value in a later commit does not help. It is in the history. Any service scanning Git history (and there are many) will find it.

**The fix:** Never write secrets in configuration files. Fetch them at apply time from a secrets store:

```hcl
# ✅ Secret is fetched from Secrets Manager — never touches the .tf file
data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = "prod/db/credentials"
}

locals {
  creds = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)
}

resource "aws_db_instance" "primary" {
  username = local.creds["username"]
  password = local.creds["password"]
}
```

The secret is fetched at apply time, decoded in memory, and used. It never exists in any file that could be committed.

---

### Leak Path 2: Variable Default Values

This is the leak path that catches experienced engineers. They know not to hardcode values, so they use a variable. But they give the variable a default:

```hcl
# ❌ The default value is stored in variables.tf — which is committed to Git
variable "db_password" {
  description = "Database password"
  default     = "SuperSecret123!"
}
```

A `default` value lives in the `.tf` file. That file is committed to source control. The secret is in Git. This is functionally identical to hardcoding it in the resource block.

**The fix:** Never give a secret variable a default value. Mark it `sensitive = true` so it cannot accidentally surface in output:

```hcl
# ✅ No default — Terraform will require the value from outside the codebase
variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  # No default value — ever
}
```

Supply the value at apply time via:
- `export TF_VAR_db_password="..."` (from your CI/CD secrets store)
- `-var="db_password=..."` (from a pipeline step that fetches it at runtime)
- Or better: eliminate the variable entirely and use a data source

---

### Leak Path 3: Plaintext in the State File

This is the leak path that most engineers do not think about, and it is the one that matters most in production. Even when you handle the first two paths perfectly — no hardcoding, no defaults — Terraform writes the resolved values of resource attributes to `terraform.tfstate` in plaintext JSON.

Open any state file for a configuration that creates an RDS instance and you will find something like this:

```json
{
  "type": "aws_db_instance",
  "values": {
    "username": "admin",
    "password": "SuperSecret123!",
    ...
  }
}
```

Every secret that passes through a Terraform resource ends up here. `sensitive = true` does not prevent this — it is a display control, not a storage control. The only way to protect state-file secrets is to protect the state file itself.

**The fix:**

```hcl
# ✅ Remote state with encryption, versioning, and restricted access
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true   # AES-256 server-side encryption
  }
}
```

And the S3 bucket must have:
- **Block all public access** — all four settings
- **Versioning** — recover from accidental overwrites
- **IAM bucket policy** — only the roles that run Terraform can read the bucket
- **Access logging** — audit who accessed the state file and when

---

## The Complete AWS Secrets Manager Integration

Here is the full, production-grade pattern for integrating Secrets Manager with a Terraform-managed RDS instance.

### Step 1: Create the Secret (Outside Terraform)

```bash
# Create once, before the first terraform apply
# Never create this with Terraform — it writes the value to state
aws secretsmanager create-secret \
  --name "prod/db/credentials" \
  --description "Production RDS master credentials" \
  --secret-string '{"username":"dbadmin","password":"your-secure-password"}' \
  --region us-east-1
```

### Step 2: Fetch It in Terraform

```hcl
# Fetch the secret metadata
data "aws_secretsmanager_secret" "db_credentials" {
  name = "prod/db/credentials"
}

# Fetch the current secret version
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

# Decode the JSON payload into a usable map
locals {
  db_credentials = jsondecode(
    data.aws_secretsmanager_secret_version.db_credentials.secret_string
  )
}

# Use the credentials in the resource
resource "aws_db_instance" "primary" {
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  db_name           = "appdb"
  allocated_storage = 20
  storage_encrypted = true

  username = local.db_credentials["username"]
  password = local.db_credentials["password"]

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  skip_final_snapshot = false
  deletion_protection = true
}
```

The secret value never appears in any `.tf` file. It is fetched at apply time and held in memory for the duration of the apply. The state file will still contain the resolved value — which is why state security (Step 3) is non-negotiable.

---

## Marking Outputs and Variables as Sensitive

```hcl
# variables.tf
variable "db_password" {
  description = "Database password — supply via TF_VAR_db_password"
  type        = string
  sensitive   = true   # Prevents display in plan/apply output
  # No default
}

# outputs.tf
output "db_connection_string" {
  value     = "mysql://${aws_db_instance.primary.username}@${aws_db_instance.primary.endpoint}"
  sensitive = true
}
```

When `sensitive = true`, Terraform shows this in plan output:

```
Changes to Outputs:
  + db_connection_string = (sensitive value)
```

The actual value never appears in the terminal. This matters for shared screens, CI/CD logs, and any other context where plan output might be captured.

**Important caveat:** `sensitive = true` is a display control only. The value is still stored in state in plaintext.

---

## State File Security Checklist

Run through this before every production deployment:

```
[ ] Remote backend configured — no local state files
[ ] encrypt = true in backend configuration
[ ] S3 bucket: Block all public access — all four settings on
[ ] S3 bucket: Versioning enabled
[ ] S3 bucket: Access logging enabled
[ ] IAM bucket policy: only Terraform execution roles can access the bucket
[ ] DynamoDB lock table: prevents concurrent applies
[ ] .gitignore includes *.tfstate and *.tfstate.backup
[ ] .terraform/ directory excluded from version control
[ ] *.tfvars files excluded from version control (or audited for secrets)
[ ] CI/CD credentials come from a secrets store, not hardcoded in YAML
```

---

## AWS Credentials for the Provider — Environment Variables Only

```bash
# Export credentials — never put these in any .tf file
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"

terraform init
terraform plan
terraform apply
```

The AWS provider reads these automatically. For workloads running inside AWS (EC2, ECS, Lambda), use an IAM instance profile or task role — no static credentials required at all.

For CI/CD pipelines, store credentials in your CI system's secrets store (GitHub Actions secrets, GitLab CI variables, etc.) and inject them as environment variables in the pipeline. Never hardcode them in pipeline YAML files.

---

## Summary

| Threat | Prevention |
|---|---|
| Secret in `.tf` file | Use Secrets Manager data source |
| Secret in variable default | No default; mark `sensitive = true` |
| Secret in state file | Remote state + encryption + IAM restriction |
| Secret in terminal output | `sensitive = true` on variables and outputs |
| Secret in CI/CD logs | `sensitive = true` + CI secrets store for provider credentials |
| Secret in Git history | `.gitignore` covering `*.tfstate`, `*.tfvars`, `.terraform/` |

Security in Terraform is not an afterthought. It requires deliberate choices at every layer: how secrets enter the configuration, how they are stored, who can access the state, and what appears in logs. None of these controls works in isolation — all of them together form a coherent posture.

---

*#30DayTerraformChallenge #Terraform #Security #DevOps #IaC #AWSUserGroupKenya #EveOps*
