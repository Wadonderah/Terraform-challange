variable "cluster_name" {
  type        = string
  description = "Unique cluster name used as prefix for resource names."
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique name for the Terraform remote state S3 bucket."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9\\-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "state_bucket_name must be a valid S3 bucket name (3-63 chars, lowercase alphanumeric and hyphens)."
  }
}

variable "config_bucket_name" {
  type        = string
  description = "Globally unique name for the application configuration S3 bucket."
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name for the DynamoDB state lock table."
  default     = "terraform-state-lock"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key to use for server-side encryption."
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all resources."
  default     = {}
}
