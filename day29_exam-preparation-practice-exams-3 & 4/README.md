# Day 29 - Terraform Associate Exam Prep: Practice Exams 3 & 4
## 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps

This project is a full Terraform implementation of every concept tested in Day 29
practice exams 3 and 4. Run real commands against real resources and learn by
doing, not by reading.

## Four-Exam Score Trend

| Exam         | Score | %     | Notes                          |
|--------------|-------|-------|--------------------------------|
| Exam 1 Day28 | 42/57 | 73.7% | Baseline — warm-up exam        |
| Exam 2 Day28 | 45/57 | 78.9% | Improved — warm-up effect      |
| Exam 3 Day29 | 46/57 | 80.7% | Sustained improvement          |
| Exam 4 Day29 | 48/57 | 84.2% | Highest score — target reached |

**Trend:** Consistent upward trajectory. Ready to sit the exam on Day 30.

## Weak Domains After Four Exams

- State Management: persistent gap on `state rm` vs `destroy`
- Terraform Cloud Workspaces: different from CLI workspaces
- Provider Version Constraints: `~>` operator edge cases
- Lifecycle Rules: `prevent_destroy` vs manual console deletion

## Project Structure


day29_tf/
├── main.tf                        # Root module
├── variables.tf                   # Input variables with validation
├── outputs.tf                     # Outputs including sensitive demo
├── versions.tf                    # Version constraints (all 3 operator types)
├── backend.tf                     # Backend options
├── locals.tf                      # Computed locals
├── data.tf                        # Data sources
├── provider_version_practice.tf   # Version constraint exam practice
├── workspace_demo.tf              # Workspace behaviour concepts
├── lifecycle_rules.tf             # All lifecycle meta-argument patterns
├── persistent_wrong_answers.tf    # Four-exam gap analysis in HCL
├── four_exam_trend.tf             # Score trend as locals and outputs
├── state_commands.sh              # Executable state practice script
├── workspace_commands.sh          # Executable workspace practice script
├── modules/
│   ├── random_demo/               # Simple resource for state practice
│   ├── workspace_demo/            # Workspace-aware resource naming
│   └── lifecycle_demo/            # lifecycle block patterns
├── environments/
│   ├── dev/terraform.tfvars
│   ├── staging/terraform.tfvars
│   └── prod/terraform.tfvars
└── .github/workflows/
    └── terraform.yml


## Quick Start


# Initialise
terraform init

# Validate
terraform validate

# Plan for dev
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply
terraform apply -var-file="environments/dev/terraform.tfvars"

# Run state practice (after apply)
bash state_commands.sh

# Run workspace practice
bash workspace_commands.sh

# Destroy
terraform destroy -var-file="environments/dev/terraform.tfvars"


## Key Concepts Covered

1. State management: `state rm` vs `destroy` vs `import` vs `refresh`
2. Workspaces: CLI workspaces vs Terraform Cloud workspaces
3. Provider version constraints: `~>`, `>=`, `<`, `=`
4. Lifecycle rules: `create_before_destroy`, `prevent_destroy`, `ignore_changes`
5. Terraform workflow order: `init` → `validate` → `plan` → `apply` → `destroy`