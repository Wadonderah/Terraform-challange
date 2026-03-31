##############################################################################
# Variables — Day 14 Multi-Region Deployment
##############################################################################

variable "primary_region" {
  description = "AWS region for the primary (source) bucket"
  type        = string
  default     = "us-east-1"
}

variable "replica_region" {
  description = "AWS region for the replica (destination) bucket"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Deployment environment label"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_prefix" {
  description = "Short prefix for all resource names — keeps names unique and identifiable"
  type        = string
  default     = "tf-challenge-day14"

  validation {
    condition     = length(var.project_prefix) <= 30 && can(regex("^[a-z0-9-]+$", var.project_prefix))
    error_message = "project_prefix must be lowercase alphanumeric and hyphens only, max 30 chars."
  }
}
