# Day 7 — Terraform State Isolation: Workspaces vs File Layouts

## Repository Structure

```
terraform-day7/
├── workspaces/              # Workspace isolation — single config, multiple state files
│   ├── main.tf              # Uses terraform.workspace for conditional behaviour
│   ├── variables.tf
│   └── outputs.tf
│
├── environments/            # File layout isolation — separate dir per environment
│   ├── dev/
│   │   ├── backend.tf       # key: environments/dev/terraform.tfstate
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── staging/
│   │   ├── backend.tf       # key: environments/staging/terraform.tfstate
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── remote_state.tf  # terraform_remote_state example
│   └── production/
│       ├── backend.tf       # key: environments/production/terraform.tfstate
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── app-layer/               # Remote state consumer example
    └── main.tf              # Reads subnet_id from networking layer state

```

## Usage

### Workspaces approach
```bash
cd workspaces/
terraform init
terraform workspace new dev
terraform workspace new staging
terraform workspace new production
terraform workspace select dev
terraform apply
```

### File layout approach
```bash
cd environments/dev
terraform init
terraform apply

cd ../production
terraform init
terraform apply
```

### Remote state
The `app-layer/` reads outputs from `environments/dev/` state file.
Deploy dev first, then deploy app-layer.

## Prerequisites
- AWS credentials configured
- S3 bucket: `wadondera-terraform-state-556684850027`
- DynamoDB table: `terraform-state-locks` (partition key: `LockID`)
