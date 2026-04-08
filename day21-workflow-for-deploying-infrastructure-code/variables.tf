# ==============================================================================
# Root Module Variables - Day 21 Example Configuration
# ==============================================================================

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cpu_high_threshold" {
  description = "CPU % above which the high-CPU alarm fires"
  type        = number
  default     = 80
}

variable "cpu_low_threshold" {
  description = "CPU % below which the low-CPU alarm fires"
  type        = number
  default     = 10
}

variable "alb_5xx_threshold" {
  description = "Number of ALB 5xx responses per minute that triggers alarm"
  type        = number
  default     = 10
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
  default     = ""

  validation {
    condition     = var.alert_email == "" || can(regex("^[^@]+@[^@]+\\.[^@]+$", var.alert_email))
    error_message = "alert_email must be a valid email address or empty string."
  }
}