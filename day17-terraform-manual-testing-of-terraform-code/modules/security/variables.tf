##############################################################
# modules/security/variables.tf
##############################################################

variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to create security groups in"
  type        = string
}

variable "server_port" {
  description = "Port EC2 instances listen on"
  type        = number
}

variable "alb_port" {
  description = "Port the ALB listens on"
  type        = number
}
