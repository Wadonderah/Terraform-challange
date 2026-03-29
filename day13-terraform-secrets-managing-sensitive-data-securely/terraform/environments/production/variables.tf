# =============================================================================
# variables.tf — Input Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "aws_account_id" {
  description = "AWS account ID — find it with: aws sts get-caller-identity --query Account --output text"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "environment must be one of: production, staging, development."
  }
}

# ---------------------------------------------------------------------------
# Networking — set these in terraform.tfvars
# ---------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID — find with: aws ec2 describe-vpcs --region ap-northeast-2 --query 'Vpcs[*].VpcId'"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "List of subnet IDs — find with: aws ec2 describe-subnets --region ap-northeast-2 --query 'Subnets[*].SubnetId'"
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Secrets Manager
# ---------------------------------------------------------------------------

variable "db_secret_name" {
  description = "Name of the AWS Secrets Manager secret containing DB credentials"
  type        = string
  default     = "prod/db/credentials"
}

variable "db_master_password_override" {
  description = "Emergency override — only use during bootstrap. Supply via TF_VAR_db_master_password_override"
  type        = string
  sensitive   = true
  default     = null
}
