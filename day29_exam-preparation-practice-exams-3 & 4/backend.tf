# =============================================================================
# backend.tf
# Day 29: Terraform Associate Exam Prep — Practice Exams 3 & 4
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: Workspaces in Terraform Cloud vs CLI workspaces
#
# PERSISTENT WRONG ANSWER (appeared in exams 3 AND 4):
#
# CLI workspaces (terraform workspace new/select):
#   - Multiple state files within the SAME backend
#   - Isolated state per workspace, same config
#   - terraform.workspace variable returns current workspace name
#   - The "default" workspace always exists and CANNOT be deleted
#   - Good for: testing changes before applying to prod (same infra, diff state)
#
# Terraform Cloud workspaces:
#   - Completely separate entities — each has its own:
#     * State file
#     * Variables
#     * Run history
#     * Permissions
#     * Execution mode (local/remote/agent)
#   - NOT the same as running terraform workspace new in the CLI
#   - Think of TF Cloud workspaces like separate projects, not branches
# =============================================================================

terraform {
  cloud {
    organization = "your-org-name"
    workspaces {
      name = "day29-exam-prep"
    }
  }

  # Uncomment for S3 backend with workspace support:
  # backend "s3" {
  #   bucket         = "my-tf-state"
  #   key            = "day29/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  #
  #   # With S3 backend, workspaces store state at:
  #   #   s3://my-tf-state/env:/dev/day29/terraform.tfstate
  #   #   s3://my-tf-state/env:/staging/day29/terraform.tfstate
  #   # The key prefix changes per workspace automatically.
  # }
}