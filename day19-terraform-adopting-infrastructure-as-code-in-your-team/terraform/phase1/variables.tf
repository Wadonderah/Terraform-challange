variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "af-south-1"
}

variable "environment" {
  description = "Environment name — used in resource names and tags"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
