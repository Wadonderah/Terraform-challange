# =============================================================================
# versions.tf
# Day 30: Final Practice Exam, Fill-in-the-Blank, and Challenge Complete
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# FILL-IN-THE-BLANK ANSWER 9:
# The terraform init -upgrade flag updates providers even when pinned in the
# .terraform.lock.hcl file. This file records exact provider versions and
# checksums to ensure reproducible deployments across all team members.
# It SHOULD be committed to version control.
# =============================================================================

terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # FILL-IN-THE-BLANK ANSWER 7:
      # ~> 5.0 allows >= 5.0.0 AND < 6.0.0 (minor increments)
      # ~> 5.0.0 would allow >= 5.0.0 AND < 5.1.0 (patch only)
      # More segments = tighter constraint
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0, < 4.0"
      # Equivalent to ~> 3.0 — explicit range for clarity
    }
  }
}