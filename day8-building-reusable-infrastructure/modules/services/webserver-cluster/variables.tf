variable "cluster_name" {
  description = "The name to use for all cluster resources"
  type        = string
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type for the cluster nodes. t3.micro is free-tier eligible."
  type        = string
  default     = "t3.micro"
}

variable "server_port" {
  description = "Port the web server listens on for HTTP traffic"
  type        = number
  default     = 8080
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances. Defaults to Amazon Linux 2 in us-east-1."
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "health_check_path" {
  description = "HTTP path the ALB uses to health-check instances"
  type        = string
  default     = "/"
}

variable "health_check_grace_period" {
  description = "Seconds to wait before running the first ASG health check after an instance launches"
  type        = number
  default     = 300
}

variable "enable_autoscaling" {
  description = "Whether to attach CPU-based scaling policies to the ASG"
  type        = bool
  default     = true
}

variable "custom_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
