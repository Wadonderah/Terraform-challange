# =============================================================================
# versions.tf
# Day 29: Terraform Associate Exam Prep — Practice Exams 3 & 4
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: Version constraint operators
#
# Operator quick reference (persistent wrong answer across exams 3 & 4):
#
#   = 1.5.0       Exactly 1.5.0 only
#   != 1.5.0      Any version except 1.5.0
#   > 1.5.0       Greater than 1.5.0
#   >= 1.5.0      1.5.0 or higher (no upper bound)
#   < 2.0.0       Less than 2.0.0
#   <= 2.0.0      2.0.0 or lower
#   ~> 1.5        >= 1.5.0 AND < 2.0.0  (rightmost digit increments freely)
#   ~> 1.5.0      >= 1.5.0 AND < 1.6.0  (patch only — last digit increments)
#   ~> 1.5.2      >= 1.5.2 AND < 1.6.0  (patch from 1.5.2)
#
# EXAM TRAP: ~> 1.0 vs ~> 1.0.0
#   ~> 1.0   allows 1.0, 1.1, 1.9 but NOT 2.0  (minor increments)
#   ~> 1.0.0 allows 1.0.0, 1.0.1, 1.0.9 but NOT 1.1.0  (patch only)
#   The number of version segments matters. More segments = tighter constraint.
# =============================================================================

terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # Allows: 5.0.x, 5.1.x, 5.99.x
      # Blocks:  4.x.x, 6.0.0
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
      # Allows: 3.5.0, 3.5.1, 3.99.x
      # Blocks:  3.4.x, 4.0.0
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0, < 4.0"
      # Equivalent to: ~> 3.0
      # Allows: 3.0.0, 3.1.0, 3.99.0
      # Blocks:  2.x.x, 4.0.0
    }
  }
}