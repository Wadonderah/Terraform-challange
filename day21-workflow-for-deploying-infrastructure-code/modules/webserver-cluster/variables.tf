# ==============================================================================
# variables.tf — Day 21 additions for CloudWatch alarm configuration
# These are ADDITIVE to the variables already defined in your Day 19/20 module.
# Add these blocks to your existing variables.tf.
# ==============================================================================

variable "cluster_name" {
  description = "The name of the webserver cluster. Used as a prefix for all resource names."
  type        = string

  validation {
    condition     = length(var.cluster_name) <= 32 && can(regex("^[a-z0-9-]+$", var.cluster_name))
    error_message = "cluster_name must be lowercase alphanumeric + hyphens, max 32 chars."
  }
}

variable "cpu_high_threshold" {
  description = "CPU % above which the high-CPU alarm fires (triggers scale-out notification)."
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_high_threshold > 0 && var.cpu_high_threshold <= 100
    error_message = "cpu_high_threshold must be between 1 and 100."
  }
}

variable "cpu_low_threshold" {
  description = "CPU % below which the low-CPU alarm fires (triggers scale-in notification)."
  type        = number
  default     = 10

  validation {
    condition     = var.cpu_low_threshold >= 0 && var.cpu_low_threshold < 100
    error_message = "cpu_low_threshold must be between 0 and 99."
  }
}

variable "alb_5xx_threshold" {
  description = "Number of ALB 5xx responses per minute that triggers the error alarm."
  type        = number
  default     = 10
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications. Leave empty to skip subscription."
  type        = string
  default     = ""

  validation {
    condition     = var.alert_email == "" || can(regex("^[^@]+@[^@]+\\.[^@]+$", var.alert_email))
    error_message = "alert_email must be a valid email address or an empty string."
  }
}
