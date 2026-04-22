# =============================================================================
# backend.tf
# Day 28: Terraform Associate Exam Prep
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: Remote backend vs remote operations
#
# WRONG ANSWER TRAP: "The cloud backend always runs plans remotely."
# CORRECT:          The cloud backend stores state remotely. Whether plans run
#                   remotely or locally is controlled by the workspace
#                   execution_mode setting in Terraform Cloud UI:
#                     - execution_mode = "remote" -> plan runs in TF Cloud
#                     - execution_mode = "local"  -> plan runs on your machine
#                                                    state still stored in TF Cloud
#
# To use this backend:
#   1. terraform login
#   2. terraform init
#   Set TF_CLOUD_ORGANIZATION env var or replace "your-org-name" below.
#
# To use local backend instead (for testing without TF Cloud), comment out
# the cloud block and uncomment the local block below.
# =============================================================================

terraform {
  # -----------------------------------------------------------------------------
  # OPTION A: Terraform Cloud backend (remote state + optional remote operations)
  # -----------------------------------------------------------------------------
  cloud {
    organization = "your-org-name" # Replace with your TF Cloud org

    workspaces {
      # Use a single workspace name OR a tag to match multiple workspaces.
      # Tag-based selection allows terraform workspace select to switch contexts.
      name = "day28-exam-prep"

      # Alternatively, select workspaces by tag:
      # tags = ["day28", "exam-prep"]
    }
  }

  # -----------------------------------------------------------------------------
  # OPTION B: S3 backend (remote state, local operations, encrypted at rest)
  # Uncomment to use instead of Terraform Cloud.
  # This demonstrates that remote state != remote operations.
  # Plans still run locally; state is stored encrypted in S3.
  # -----------------------------------------------------------------------------
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "day28/exam-prep/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true          # State encrypted at rest with SSE-S3
  #   kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"
  #   dynamodb_table = "terraform-locks" # State locking
  # }

  # -----------------------------------------------------------------------------
  # OPTION C: Local backend (default - no config needed)
  # State stored in terraform.tfstate in working directory.
  # EXAM NOTE: sensitive = true does NOT encrypt local state.
  # The value is plaintext in terraform.tfstate regardless of the flag.
  # -----------------------------------------------------------------------------
  # backend "local" {
  #   path = "terraform.tfstate"
  # }
}
