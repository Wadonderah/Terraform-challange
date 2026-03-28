###############################################################################
# modules/webserver-cluster/variables.tf
# Day 12 — Zero-Downtime Deployments with Terraform
###############################################################################

variable "cluster_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment: dev, staging, or production"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Must be dev, staging, or production."
  }
}

variable "ami" {
  description = "AMI ID for EC2 instances (leave empty to use latest Ubuntu 22.04)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
  default     = 3
}

variable "server_port" {
  description = "Port the web server listens on"
  type        = number
  default     = 80
}

variable "app_version" {
  description = "Application version string shown in the HTML response (e.g. v1, v2)"
  type        = string
  default     = "v1"
}

# ─────────────────────────────────────────────────────────────────────────────
# Blue/Green
# ─────────────────────────────────────────────────────────────────────────────
variable "active_environment" {
  description = "Which target group receives live traffic: blue or green"
  type        = string
  default     = "blue"
  validation {
    condition     = contains(["blue", "green"], var.active_environment)
    error_message = "active_environment must be blue or green."
  }
}

variable "blue_app_version" {
  description = "App version running in the blue target group"
  type        = string
  default     = "v1"
}

variable "green_app_version" {
  description = "App version running in the green target group"
  type        = string
  default     = "v2"
}
