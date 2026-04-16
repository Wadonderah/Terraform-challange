variable "app_name" {
  description = "Application name — used as a name prefix for ALB and related resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev | staging | production)"
  type        = string
  default     = "dev"
}

variable "ami_id" {
  description = "Amazon Linux 2023 AMI ID for the target region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for web tier instances"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name — leave null to skip SSH access in dev"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID where all resources will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (at least two AZs) — ALB is placed here"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs (at least two AZs) — ASG instances are placed here"
  type        = list(string)
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of EC2 instances the ASG can scale to"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired EC2 instance count at launch"
  type        = number
  default     = 2
}

variable "cpu_scale_out_threshold" {
  description = "Average CPU % that triggers a scale-out event"
  type        = number
  default     = 70
}

variable "cpu_scale_in_threshold" {
  description = "Average CPU % that triggers a scale-in event"
  type        = number
  default     = 30
}
