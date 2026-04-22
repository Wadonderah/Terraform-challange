# =============================================================================
# variables.tf
# Day 28: Terraform Associate Exam Prep
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: Variable types, validation, and sensitive variables
# =============================================================================

# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------
variable "environment" {
  description = "Deployment environment. Controls resource naming and sizing."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name used in resource tags and naming."
  type        = string
  default     = "day28-terraform-challenge"
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets. One per AZ."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets. One per AZ."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# -----------------------------------------------------------------------------
# Compute
# -----------------------------------------------------------------------------
variable "instance_type" {
  description = "EC2 instance type for the web server."
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of EC2 instances to create."
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "instance_count must be between 1 and 10."
  }
}

variable "ami_id" {
  description = "AMI ID for EC2 instances. Defaults to Amazon Linux 2 in us-east-1."
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}

# -----------------------------------------------------------------------------
# EXAM CONCEPT: sensitive = true
#
# WRONG ANSWER TRAP: sensitive = true encrypts the value in the state file.
# CORRECT:          sensitive = true suppresses display in CLI output ONLY.
#                   The value is stored in PLAINTEXT in terraform.tfstate.
#                   To protect secrets at rest, use an encrypted backend.
# -----------------------------------------------------------------------------
variable "db_password" {
  description = <<-EOT
    Database password.
    EXAM NOTE: Marking this sensitive suppresses it in CLI output.
    It does NOT encrypt it in the state file. The state file stores it in plaintext.
    Use an encrypted backend (S3+KMS, Terraform Cloud) for real protection.
  EOT
  type      = string
  sensitive = true
  default   = "change-me-before-production"
}

variable "db_username" {
  description = "Database username."
  type        = string
  default     = "admin"
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Map of additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
