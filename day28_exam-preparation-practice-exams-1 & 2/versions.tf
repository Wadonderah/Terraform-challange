# =============================================================================
# versions.tf
# Day 28: Terraform Associate Exam Prep
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: Terraform version constraints
# The required_version block uses constraint syntax identical to module
# version arguments. Key operators:
#   = 1.5.0   -> exactly 1.5.0
#   >= 1.5.0  -> 1.5.0 or higher
#   ~> 1.5.0  -> 1.5.x (patch-level only, pessimistic constraint)
#   ~> 1.5    -> 1.x (minor-level, pessimistic constraint)
# =============================================================================

terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
