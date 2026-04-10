# bootstrap/variables.tf

variable "aws_region" {
  description = "AWS region for the state bucket and lock table"
  type        = string
  default     = "us-east-2"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform remote state"
  type        = string
  # Example: "mycompany-terraform-state-us-east-2"
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-locks"
}

variable "github_org" {
  description = "Your GitHub organisation or username"
  type        = string
}

variable "github_repo" {
  description = "Your GitHub repository name"
  type        = string
}
