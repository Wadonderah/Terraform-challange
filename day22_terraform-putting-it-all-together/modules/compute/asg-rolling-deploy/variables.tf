# modules/compute/asg-rolling-deploy/variables.tf

variable "cluster_name" {
  description = "Name of the ASG cluster"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, stage, prod)"
  type        = string
}

variable "ami" {
  description = "AMI ID — leave empty to use latest Ubuntu 22.04"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "m5.large"], var.instance_type)
    error_message = "instance_type must be one of: t3.micro, t3.small, t3.medium, m5.large"
  }
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number

  validation {
    condition     = var.min_size >= 1
    error_message = "min_size must be at least 1"
  }
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs to launch instances into"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB (allows ingress from it)"
  type        = string
}

variable "server_port" {
  description = "Port the web server listens on"
  type        = number
  default     = 8080
}

variable "enable_autoscaling" {
  description = "Enable scheduled scale-out/in actions"
  type        = bool
  default     = false
}
