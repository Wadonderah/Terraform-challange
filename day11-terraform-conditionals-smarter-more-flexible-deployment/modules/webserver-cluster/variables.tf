###############################################################################
# modules/webserver-cluster/variables.tf
# Day 11 — Terraform Conditionals Deep Dive
# Author  : Senior AWS Cloud Engineer
###############################################################################

# ─────────────────────────────────────────────────────────────────────────────
# Core
# ─────────────────────────────────────────────────────────────────────────────
variable "cluster_name" {
  description = "Name prefix for all resources in this cluster"
  type        = string
}

variable "environment" {
  description = "Deployment environment. Must be one of: dev, staging, production"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging, or production. Got: \"${var.environment}\"."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Networking (brownfield / greenfield toggle)
# ─────────────────────────────────────────────────────────────────────────────
variable "use_existing_vpc" {
  description = "Set to true to attach to an existing VPC instead of creating one"
  type        = bool
  default     = false
}

variable "existing_vpc_name_tag" {
  description = "Value of the 'Name' tag on the existing VPC (only used when use_existing_vpc = true)"
  type        = string
  default     = "existing-vpc"
}

# ─────────────────────────────────────────────────────────────────────────────
# Feature flags
# ─────────────────────────────────────────────────────────────────────────────
variable "enable_detailed_monitoring" {
  description = "Create CloudWatch CPU alarm. Incurs additional cost."
  type        = bool
  default     = false
}

variable "create_dns_record" {
  description = "Create a Route53 alias record for the ALB"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "FQDN for the Route53 record (required when create_dns_record = true)"
  type        = string
  default     = ""
}
