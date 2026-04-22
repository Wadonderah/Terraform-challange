# =============================================================================
# variables.tf
# Day 30: Final Practice Exam, Fill-in-the-Blank, and Challenge Complete
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# READINESS CHECK ANSWER 5:
# variable block = public interface, can be set from outside the module
# locals block   = internal computed values, cannot be overridden by caller
# =============================================================================

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Must be dev or prod."
  }
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name."
  type        = string
  default     = "day30-challenge-complete"
}

variable "bucket_names" {
  description = "List of S3 bucket name suffixes to create via for_each."
  type        = list(string)
  default     = ["logs", "backups", "artifacts"]
  # FILL-IN-THE-BLANK ANSWER 5:
  # for_each requires a map or SET (not a plain list).
  # In main.tf this list is converted with toset() before passing to for_each.
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}