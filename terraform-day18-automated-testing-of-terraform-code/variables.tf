##############################################################
# variables.tf — Root module (Day 18)
##############################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment: dev or prod"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "webserver-cluster"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum ASG instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum ASG instances"
  type        = number
  default     = 2
}

variable "server_port" {
  description = "Web server port"
  type        = number
  default     = 8080
}

variable "alb_port" {
  description = "ALB listener port"
  type        = number
  default     = 80
}

variable "hello_world_text" {
  description = "Text returned by web server"
  type        = string
  default     = "Hi Wadondera welcome back!"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances — must match the deployment region"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2023 us-east-1
}
