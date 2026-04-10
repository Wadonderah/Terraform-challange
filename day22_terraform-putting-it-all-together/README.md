# Day 22 — Terraform: Up & Running Complete
## Putting It All Together

> Brikman, Ch. 10 — *"The main branch of the live repository should be a 1:1
> representation of what's actually deployed in production."*

---

## Quick Start

### 1. Prerequisites

```bash
terraform >= 1.7.0
terragrunt >= 0.55.0
go >= 1.21          # for Terratest
aws cli v2
```

### 2. Bootstrap remote state (do this once)

```bash
aws s3api create-bucket \
  --bucket YOUR-TFSTATE-BUCKET \
  --region us-east-2 \
  --create-bucket-configuration LocationConstraint=us-east-2

aws s3api put-bucket-versioning \
  --bucket YOUR-TFSTATE-BUCKET \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket YOUR-TFSTATE-BUCKET \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws dynamodb create-table \
  --table-name YOUR-LOCK-TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-2
```

### 3. Replace placeholders

Search the repo for `YOUR-TFSTATE-BUCKET`, `YOUR-LOCK-TABLE`, and `<OWNER>` and replace
them with your real values.

### 4. Deploy dev environment

```bash
export TF_VAR_db_username=myuser
export TF_VAR_db_password=SuperSecret123!

cd live/dev/services/hello-wadondera-app
terraform init
terraform plan -out=ci.tfplan
terraform apply ci.tfplan
```

### 5. Verify

```bash
terraform output alb_dns_name
curl http://<alb_dns_name>
# Hello, World from dev!

curl http://<alb_dns_name>/health
# OK
```

### 6. Run unit tests

```bash
cd modules/compute/asg-rolling-deploy
terraform test
```

### 7. Run integration tests (requires real AWS account)

```bash
cd tests/integration
go test -v -timeout 60m ./...
```

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── terraform-ci.yml          # Full CI/CD pipeline (validate→plan→apply×3)
│
├── modules/                           # Reusable, versioned modules
│   ├── networking/
│   │   └── vpc/                       # VPC, subnets, NAT, route tables
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── load-balancing/
│   │   └── alb/                       # ALB, target group, security group, listener
│   ├── compute/
│   │   └── asg-rolling-deploy/        # ASG, launch template, CloudWatch, user-data.sh
│   ├── data-stores/
│   │   └── mysql/                     # RDS MySQL, subnet group, security group
│   └── services/
│       └── hello-wadondera-app/           # Composition module — wires all of the above
│
├── live/                              # Live infrastructure — 1 folder per env per module
│   ├── dev/
│   │   └── services/hello-wadondera-app/  # main.tf + variables.tf + outputs.tf
│   ├── stage/
│   │   └── services/hello-wadondera-app/
│   └── prod/
│       └── services/hello-wadondera-app/  # Multi-AZ, deletion protection, larger instances
│
├── sentinel/                          # Terraform Cloud Sentinel policies
│   ├── allowed-instance-types.sentinel  # hard-mandatory: instance type allow-list
│   ├── require-terraform-tag.sentinel   # soft-mandatory: ManagedBy = "terraform"
│   └── cost-check.sentinel             # advisory→soft-mandatory: <$50/mo delta
│
├── tests/
│   ├── unit/
│   │   ├── asg_module_test.tftest.hcl   # native terraform test — no AWS needed
│   │   └── vpc_module_test.tftest.hcl
│   └── integration/
│       ├── hello_wadondera_app_test.go      # Terratest — deploys real infra, verifies ALB
│       └── go.mod
│
├── blog-post.md                        # Full Day 22 blog post
└── README.md                           # This file
```

---

## The Golden Rule of Terraform

```
terraform plan   # run this in any live/ folder
                 # output must always be: "No changes. Your infrastructure matches the configuration."
                 # if it is not — that is the highest priority issue this sprint
```

---

## Environment Comparison

| Setting | dev | stage | prod |
|---------|-----|-------|------|
| instance_type | t3.micro | t3.small | t3.medium |
| min_size | 1 | 2 | 3 |
| max_size | 2 | 4 | 9 |
| enable_autoscaling | false | true | true |
| db_instance_class | db.t3.micro | db.t3.small | db.t3.medium |
| multi_az | false | false | true |
| deletion_protection | false | false | true |
| skip_final_snapshot | true | true | false |

---

## Sentinel Policy Summary

| Policy | File | Level | What it blocks |
|--------|------|-------|----------------|
| Instance types | `allowed-instance-types.sentinel` | hard-mandatory | Any EC2 instance not in the allow-list |
| ManagedBy tag | `require-terraform-tag.sentinel` | soft-mandatory | Any resource without `ManagedBy = "terraform"` |
| Cost gate | `cost-check.sentinel` | advisory / soft-mandatory | Monthly cost delta > $50 |

---

## CI/CD Flow

```
PR opened
    │
    ▼
[validate]  terraform fmt + init + validate + test   (no AWS creds)
    │
    ▼
[plan]      terraform init + plan -out=ci.tfplan      (OIDC temp creds)
            upload ci.tfplan as immutable artifact
    │
    ▼  (merge to main)
[apply-dev]   download ci.tfplan → terraform apply ci.tfplan
    │
    ▼  (manual approval)
[apply-stage] terraform plan + apply
    │
    ▼  (2nd manual approval)
[apply-prod]  terraform plan + apply
```

The `.tfplan` artifact is never regenerated between environments.
The same plan reviewed in staging is the plan applied in production.
