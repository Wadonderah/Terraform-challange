# Non-Cloud Providers — Terraform Beyond AWS
## Exam Reference + Working Examples

---

## Why Non-Cloud Providers Exist

Terraform is not just an AWS tool. The provider ecosystem covers anything with an API:
DNS zones, TLS certificates, random values, local files, time delays, and HTTP calls.
These appear frequently in exam questions because they demonstrate that students
understand Terraform's provider model — not just AWS resource syntax.

---

## The random Provider

### What it does
Generates random values that are stable across plan/apply cycles — once generated
and stored in state, the same value is returned on every subsequent plan. Useful
for generating unique names, passwords, and IDs without hardcoding them.

### Working examples

```hcl
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# ── random_id — generates a random hex/base64 string ──────────────────────
# Use case: unique suffix for S3 bucket names (must be globally unique)
resource "random_id" "bucket_suffix" {
  byte_length = 4   # 4 bytes = 8 hex characters
}

resource "aws_s3_bucket" "app_assets" {
  bucket = "myapp-assets-${random_id.bucket_suffix.hex}"
  # Result: "myapp-assets-a1b2c3d4"
  # Stable across plans — same suffix every time after first apply
}

# ── random_string — generates a random string with character control ───────
# Use case: unique suffix with readable characters only
resource "random_string" "app_suffix" {
  length  = 8
  special = false   # no special characters
  upper   = false   # lowercase only
  numeric = true
}

# ── random_password — generates a cryptographically random password ────────
# Use case: initial RDS master password, stored in state (sensitive)
resource "random_password" "db_master" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  # Excludes / @ " which can cause issues in connection strings
}

# Store in Secrets Manager — never output or log this value
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db_master.result
}

# ── random_integer — generates a random integer in a range ────────────────
resource "random_integer" "priority" {
  min = 100
  max = 999
}

resource "aws_lb_listener_rule" "app" {
  priority = random_integer.priority.result
  # ...
}

# ── random_uuid — generates a UUID ────────────────────────────────────────
resource "random_uuid" "deployment_id" {}

output "deployment_id" {
  value = random_uuid.deployment_id.result
  # "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
}

# ── random_shuffle — shuffles a list and optionally picks N items ──────────
# Use case: distribute instances across AZs randomly
resource "random_shuffle" "az" {
  input        = ["us-east-2a", "us-east-2b", "us-east-2c"]
  result_count = 2   # pick 2 AZs at random
}

resource "aws_subnet" "app" {
  count             = 2
  availability_zone = random_shuffle.az.result[count.index]
  # ...
}
```

### Key exam facts about random resources

1. **Stable after first apply** — random values are generated once and stored in state.
   Subsequent plans/applies return the same value unless you run `terraform apply -replace=random_id.bucket_suffix`
2. **`keepers` argument** — forces regeneration when a keeper value changes:
   ```hcl
   resource "random_password" "db" {
     length = 24
     keepers = {
       rotation_date = "2025-01-01"  # change this to rotate the password
     }
   }
   ```
3. **Sensitive outputs** — `random_password.result` is marked sensitive and does not
   appear in plan output or logs

---

## The local Provider

### What it does
Manages local filesystem resources — files and directories on the machine running Terraform.
Useful for writing rendered templates, generating scripts, or creating configuration files
as part of a provisioning workflow.

### Working examples

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# ── local_file — writes a file to the local filesystem ────────────────────
# Use case: generate a kubeconfig after an EKS cluster is created
resource "local_file" "kubeconfig" {
  content  = templatefile("${path.module}/kubeconfig.tpl", {
    cluster_endpoint = module.eks.cluster_endpoint
    cluster_ca       = module.eks.cluster_ca_certificate
    cluster_name     = module.eks.cluster_name
  })
  filename = "${path.module}/generated/kubeconfig.yaml"
  file_permission = "0600"   # restrict to owner only
}

# ── local_file with heredoc ────────────────────────────────────────────────
resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [webservers]
    %{ for ip in aws_instance.web[*].public_ip ~}
    ${ip}
    %{ endfor ~}
  EOT
  filename = "${path.module}/inventory/hosts.ini"
}

# ── local_sensitive_file — same as local_file but content is sensitive ─────
resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.app.private_key_pem
  filename        = "${path.module}/generated/app.pem"
  file_permission = "0400"
}

# ── path references — critical for local file paths ───────────────────────
# path.module = directory of the current module
# path.root   = directory of the root module  
# path.cwd    = current working directory when terraform was invoked
```

### Key exam facts about local provider

1. **`local_file` creates files on the Terraform runner** — not on EC2 instances.
   Use `user_data` or `provisioner "file"` to create files on remote machines.
2. **File permissions** — use `file_permission` and `directory_permission` (octal strings: "0644")
3. **`local_sensitive_file`** — prevents content from appearing in plan output

---

## The tls Provider

```hcl
terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Generate an SSH key pair — store private key in Secrets Manager, public key in AWS
resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "bastion-key"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "aws_secretsmanager_secret_version" "bastion_key" {
  secret_id     = aws_secretsmanager_secret.bastion_key.id
  secret_string = tls_private_key.bastion.private_key_pem  # sensitive
}
```

---

## The null Provider

```hcl
terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# null_resource — a resource with no real infrastructure, used for triggers
# and for running local-exec / remote-exec provisioners
resource "null_resource" "ansible_run" {
  triggers = {
    # Re-run ansible when the instance ID changes (i.e., instance was replaced)
    instance_id = aws_instance.app.id
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${aws_instance.app.public_ip},' site.yml"
  }
}
```

---

## The time Provider

```hcl
terraform {
  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

# time_sleep — adds a delay between resource creation
# Use case: wait for an RDS instance to be ready before running DB migrations
resource "time_sleep" "wait_for_rds" {
  depends_on      = [aws_db_instance.main]
  create_duration = "60s"
}

resource "null_resource" "db_migration" {
  depends_on = [time_sleep.wait_for_rds]
  provisioner "local-exec" {
    command = "python manage.py migrate"
  }
}
```

---

## Exam Summary — Non-Cloud Provider Facts

| Provider | Key resource | Common use case | Exam trap |
|----------|-------------|-----------------|-----------|
| random | random_id, random_password | Unique names, initial passwords | Values stable after first apply |
| local | local_file | Write rendered templates to disk | Creates files on runner, not EC2 |
| tls | tls_private_key | SSH key pair generation | Private key stored in state (sensitive) |
| null | null_resource | Triggers, local-exec provisioners | Provisioners are last resort |
| time | time_sleep | Delays between resource creation | Fragile — prefer depends_on chains |

**Most important exam fact:** All of these providers follow exactly the same
provider model as AWS — they have a source, a version constraint, and resources
with arguments. There is nothing special about them architecturally. The exam
tests whether you understand this generality.
