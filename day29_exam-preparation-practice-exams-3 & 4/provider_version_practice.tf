# =============================================================================
# provider_version_practice.tf
# Day 29: Terraform Associate Exam Prep — Practice Exams 3 & 4
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# TASK from Day 29: Write three required_providers blocks using different
# constraint operators and describe in plain English what each one allows.
#
# This file is the HCL answer to that task.
# =============================================================================

# -----------------------------------------------------------------------------
# EXAMPLE 1: Pessimistic constraint operator — patch level (~> X.Y.Z)
#
# Plain English: "Give me version 3.5.0 or any patch release of 3.5,
# but stop before 3.6.0. I want the bug fixes but not potentially
# breaking minor version changes."
#
# Allows:  3.5.0, 3.5.1, 3.5.99
# Blocks:  3.4.x (too old), 3.6.0 (minor bump), 4.0.0 (major bump)
# -----------------------------------------------------------------------------
# terraform {
#   required_providers {
#     example_patch = {
#       source  = "hashicorp/random"
#       version = "~> 3.5.0"
#     }
#   }
# }

# -----------------------------------------------------------------------------
# EXAMPLE 2: Pessimistic constraint operator — minor level (~> X.Y)
#
# Plain English: "Give me version 3.5 or any minor/patch release of 3.x,
# but stop before version 4.0.0. I trust the provider team's minor
# version releases to stay backward-compatible within the major version."
#
# Allows:  3.5.0, 3.5.1, 3.6.0, 3.99.99
# Blocks:  3.4.x (below floor), 4.0.0 (major bump breaks compatibility)
#
# EXAM TRAP: ~> 3.5 is NOT the same as ~> 3.5.0
#   ~> 3.5   -> minor increments allowed (3.5, 3.6, 3.7 ... 3.99)
#   ~> 3.5.0 -> patch only (3.5.0, 3.5.1 ... 3.5.99, but NOT 3.6.0)
# -----------------------------------------------------------------------------
# terraform {
#   required_providers {
#     example_minor = {
#       source  = "hashicorp/aws"
#       version = "~> 3.5"
#     }
#   }
# }

# -----------------------------------------------------------------------------
# EXAMPLE 3: Range constraint (>= lower, < upper)
#
# Plain English: "Give me any version from 4.0.0 up to but NOT including
# 5.0.0. I want to allow any release in the 4.x range — all minor and
# patch versions — but I do not want to accidentally pull in a major
# version bump that could break my configuration."
#
# Allows:  4.0.0, 4.1.0, 4.99.99
# Blocks:  3.99.0 (below floor), 5.0.0 (hits ceiling)
#
# EQUIVALENCE: ">= 4.0, < 5.0.0" is equivalent to "~> 4.0"
# Explicit range is sometimes preferred for clarity in team environments.
# -----------------------------------------------------------------------------
# terraform {
#   required_providers {
#     example_range = {
#       source  = "hashicorp/null"
#       version = ">= 4.0, < 5.0.0"
#     }
#   }
# }

# -----------------------------------------------------------------------------
# WORKING EXAMPLE: All three operators in one providers block
# These three providers demonstrate each constraint type in practice.
# -----------------------------------------------------------------------------
# NOTE: This block is here for study. The actual working required_providers
# block is in versions.tf. Terraform only reads one terraform{} block.

locals {
  # Version constraint reference table — query in terraform console
  version_constraint_reference = {
    "~> 1.0.0" = {
      operator     = "pessimistic patch"
      plain_english = "1.0.0 or any patch of 1.0, but not 1.1.0"
      allows       = ["1.0.0", "1.0.1", "1.0.99"]
      blocks       = ["1.1.0", "2.0.0", "0.99.0"]
    }
    "~> 1.0" = {
      operator     = "pessimistic minor"
      plain_english = "1.0 or any minor/patch of 1.x, but not 2.0.0"
      allows       = ["1.0.0", "1.1.0", "1.99.99"]
      blocks       = ["0.99.0", "2.0.0"]
    }
    ">= 1.0, < 2.0.0" = {
      operator     = "explicit range"
      plain_english = "anything from 1.0.0 up to but not including 2.0.0"
      allows       = ["1.0.0", "1.5.0", "1.99.99"]
      blocks       = ["0.99.0", "2.0.0"]
      equivalent_to = "~> 1.0"
    }
  }

  # EXAM TRAP: Module source with no version always pulls LATEST
  # Never do this in production:
  #   module "vpc" { source = "terraform-aws-modules/vpc/aws" }
  # Always pin:
  #   module "vpc" { source = "terraform-aws-modules/vpc/aws" ; version = "~> 5.1" }
  module_version_note = "Always pin module versions in production. No version = latest = unpredictable."
}

output "version_constraint_reference" {
  description = "Version constraint operator reference. Query with: terraform output version_constraint_reference"
  value       = local.version_constraint_reference
}