# modules/multi-region-app/variables.tf

variable "app_name" {
  description = "Application name — used as the base for all resource names and bucket prefixes."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,32}$", var.app_name))
    error_message = "app_name must be 3–32 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment (dev | staging | prod). Appended to bucket names."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "common_tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
