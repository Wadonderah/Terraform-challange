# modules/load-balancing/alb/variables.tf

variable "alb_name" {
  description = "Name for the ALB and related resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the ALB into"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "target_port" {
  description = "Port the target instances listen on"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "HTTP path for ALB health checks"
  type        = string
  default     = "/"
}
