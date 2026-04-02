##############################################################
# modules/compute/variables.tf
##############################################################

variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "server_port" {
  description = "Port the web server listens on"
  type        = number
}

variable "alb_port" {
  description = "Port the ALB listens on"
  type        = number
}

variable "health_check_path" {
  description = "HTTP path for ALB health checks"
  type        = string
}

variable "hello_world_version" {
  description = "Version string embedded in the HTTP response"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum ASG instance count"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum ASG instance count"
  type        = number
}

variable "asg_desired_capacity" {
  description = "Desired ASG instance count"
  type        = number
}

variable "vpc_id" {
  description = "VPC ID for target group"
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnet IDs for the ALB (public)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Subnet IDs for EC2 instances (private)"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "instance_sg_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}
