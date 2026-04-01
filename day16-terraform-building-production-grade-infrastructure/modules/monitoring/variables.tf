variable "cluster_name" {
  type        = string
  description = "Cluster name, used as prefix for all monitoring resources."
}

variable "asg_name" {
  type        = string
  description = "Name of the Auto Scaling Group to monitor."
}

variable "alb_arn_suffix" {
  type        = string
  description = "ALB ARN suffix (the portion after 'loadbalancer/'). Used in CloudWatch dimensions."
}

variable "target_group_arn_suffix" {
  type        = string
  description = "Target group ARN suffix. Used in CloudWatch dimensions."
}

variable "scale_out_policy_arn" {
  type        = string
  description = "ARN of the ASG scale-out policy. Triggered by high CPU alarm."
}

variable "scale_in_policy_arn" {
  type        = string
  description = "ARN of the ASG scale-in policy. Triggered by low CPU alarm."
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ID for encrypting the SNS topic."
}

variable "alert_email_addresses" {
  type        = list(string)
  description = "List of email addresses to subscribe to the alerts SNS topic."
  default     = []
}

variable "log_retention_days" {
  type        = number
  description = "Number of days to retain CloudWatch log groups."
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch retention period."
  }
}

variable "cpu_high_threshold" {
  type        = number
  description = "CPU % that triggers scale-out alarm."
  default     = 80

  validation {
    condition     = var.cpu_high_threshold > 0 && var.cpu_high_threshold <= 100
    error_message = "cpu_high_threshold must be between 1 and 100."
  }
}

variable "cpu_low_threshold" {
  type        = number
  description = "CPU % below which scale-in alarm triggers."
  default     = 20

  validation {
    condition     = var.cpu_low_threshold > 0 && var.cpu_low_threshold < 100
    error_message = "cpu_low_threshold must be between 1 and 99."
  }
}

variable "error_rate_threshold" {
  type        = number
  description = "5xx error rate (%) that triggers an alarm."
  default     = 5
}

variable "latency_threshold_seconds" {
  type        = number
  description = "p95 response time (seconds) that triggers a latency alarm."
  default     = 2
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all resources."
  default     = {}
}
