# live/multi-region/variables.tf

variable "app_name" {
  description = "Application name used as a prefix for all resource names."
  type        = string
  default     = "my-app"
}

variable "environment" {
  description = "Deployment environment (dev | staging | prod)."
  type        = string
  default     = "dev"
}

variable "primary_region" {
  description = "AWS region for the primary S3 bucket."
  type        = string
  default     = "us-east-1"
}

variable "replica_region" {
  description = "AWS region for the replica S3 bucket."
  type        = string
  default     = "us-west-2"
}
