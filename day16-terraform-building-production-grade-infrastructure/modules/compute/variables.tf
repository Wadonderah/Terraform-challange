variable "cluster_name" {
  type        = string
  description = "Unique cluster name used as prefix for all compute resources."
}

variable "environment" {
  type        = string
  description = "Deployment environment name."

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the ALB."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for the ASG instances."
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID for the Application Load Balancer."
}

variable "web_security_group_id" {
  type        = string
  description = "Security group ID for the web server instances."
}

variable "instance_profile_name" {
  type        = string
  description = "Name of the IAM instance profile to attach to EC2 instances."
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key for EBS volume encryption."
}

variable "ami_id" {
  type        = string
  description = "AMI ID for the EC2 instances (should be Amazon Linux 2023)."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type. Must be t2 or t3 family for cost control."
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "instance_type must be a t2 or t3 family type (e.g. t3.micro, t3.small)."
  }
}

variable "server_port" {
  type        = number
  description = "Port the web servers listen on."
  default     = 80

  validation {
    condition     = var.server_port > 0 && var.server_port < 65536
    error_message = "server_port must be between 1 and 65535."
  }
}

variable "min_size" {
  type        = number
  description = "Minimum number of instances in the ASG."
  default     = 2

  validation {
    condition     = var.min_size >= 1
    error_message = "min_size must be at least 1."
  }
}

variable "max_size" {
  type        = number
  description = "Maximum number of instances in the ASG."
  default     = 6

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size must be greater than or equal to min_size."
  }
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of instances. Must be between min_size and max_size."
  default     = 2
}

variable "access_logs_bucket" {
  type        = string
  description = "S3 bucket name for ALB access logs."
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate for HTTPS. Required when environment is 'production'."
  default     = ""
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all resources."
  default     = {}
}
