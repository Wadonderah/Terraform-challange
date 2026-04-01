# =============================================================================
# ENVIRONMENT: production — variables.tf
# =============================================================================

variable "aws_region" {
  type        = string
  description = "AWS region to deploy into."
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region name (e.g. us-east-1)."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment. Affects deletion protection, redirect rules."
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production."
  }
}

variable "cluster_name" {
  type        = string
  description = "Unique name identifying this cluster. Used as a prefix for all resources."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,28}[a-z0-9]$", var.cluster_name))
    error_message = "cluster_name must be 4-30 chars, lowercase alphanumeric and hyphens, start with a letter."
  }
}

variable "project_name" {
  type        = string
  description = "Project name. Appears in the 'Project' tag on every resource."
}

variable "team_name" {
  type        = string
  description = "Owning team name. Appears in the 'Owner' tag on every resource."
}

variable "cost_center" {
  type        = string
  description = "Cost center code for billing attribution."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type. Restricted to t2/t3 families for cost governance."
  default     = "t3.small"

  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "instance_type must be a t2 or t3 family type (e.g. t3.micro, t3.small)."
  }
}

variable "server_port" {
  type        = number
  description = "Port the web server process listens on inside the instance."
  default     = 80

  validation {
    condition     = var.server_port > 0 && var.server_port < 65536
    error_message = "server_port must be between 1 and 65535."
  }
}

variable "min_size" {
  type        = number
  description = "Minimum number of EC2 instances in the Auto Scaling Group."
  default     = 2

  validation {
    condition     = var.min_size >= 1
    error_message = "min_size must be at least 1."
  }
}

variable "max_size" {
  type        = number
  description = "Maximum number of EC2 instances in the Auto Scaling Group."
  default     = 10

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size must be greater than or equal to min_size."
  }
}

variable "desired_capacity" {
  type        = number
  description = "Initial desired instance count. Autoscaling manages this at runtime."
  default     = 2
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for Terraform remote state."
}

variable "config_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for application configuration."
}

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB table name for Terraform state locking."
  default     = "terraform-state-lock"
}

variable "alert_email_addresses" {
  type        = list(string)
  description = "Email addresses subscribed to the CloudWatch alerts SNS topic."
  default     = []
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log group retention period in days."
  default     = 90
}

variable "cpu_high_threshold" {
  type        = number
  description = "CPU utilization % that triggers the scale-out alarm."
  default     = 80
}

variable "cpu_low_threshold" {
  type        = number
  description = "CPU utilization % below which the scale-in alarm triggers."
  default     = 20
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate for HTTPS listener. Required for production."
  default     = ""
}
