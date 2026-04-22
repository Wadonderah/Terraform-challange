# Day 28 - Terraform Associate Exam Prep
## 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps

This project is a full Terraform implementation of every concept tested in Day 28
practice exams. It is structured so you can run real commands against real resources
and learn by doing, not by reading.

## Exam Scores
- Practice Exam 1: 42/57 = 73.7% (PASS)
- Practice Exam 2: 45/57 = 78.9% (PASS)
- Improvement: +5.2%

## Weak Domains (below 70%)
- Terraform Modules: 63%
- State Management: 60%
- Terraform Cloud: 60%

## Project Structure


day28_tf/
├── main.tf                  # Root module - calls all child modules
├── variables.tf             # Root input variables
├── outputs.tf               # Root outputs (includes sensitive demo)
├── versions.tf              # Required providers and Terraform version
├── backend.tf               # Remote backend configuration (Terraform Cloud)
├── locals.tf                # Local values
├── data.tf                  # Data sources
├── modules/
│   ├── compute/             # EC2 module - demonstrates module versioning concepts
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── vpc/                 # VPC module - demonstrates module composition
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── state_demo/          # Demonstrates state concepts
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/                 # Dev workspace configuration
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   └── prod/                # Prod workspace configuration
│       ├── main.tf
│       └── terraform.tfvars
└── .github/
    └── workflows/
        └── terraform.yml    # CI/CD pipeline demonstrating Terraform Cloud run triggers


## How to Use This Project

### 1. Initialise

terraform init


### 2. Plan

terraform plan -var-file="environments/dev/terraform.tfvars"


### 3. Apply

terraform apply -var-file="environments/dev/terraform.tfvars"


### 4. Practice State Commands (after apply)

terraform state list
terraform state show module.compute.aws_instance.this
terraform state mv module.compute.aws_instance.this module.compute.aws_instance.web
terraform state pull | jq '.resources | length'

### 5. Destroy

terraform destroy -var-file="environments/dev/terraform.tfvars"


## Key Concepts Demonstrated
- Immutable infrastructure: resources are replaced, not patched (use -replace flag)
- Module versioning: registry modules use version, local modules do not
- State management: state rm vs destroy, state mv, state import
- Sensitive outputs: suppressed in CLI but visible in state file
- Remote backend: Terraform Cloud with configurable execution mode
- Workspaces: dev and prod environments via terraform.tfvars
