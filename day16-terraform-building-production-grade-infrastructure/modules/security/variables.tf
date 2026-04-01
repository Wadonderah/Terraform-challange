variable "cluster_name" {
  type        = string
  description = "Unique name for this cluster/environment."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where security groups will be created."
}

variable "server_port" {
  type        = number
  description = "Port the web servers listen on."
  default     = 8080

  validation {
    condition     = var.server_port > 0 && var.server_port < 65536
    error_message = "server_port must be between 1 and 65535."
  }
}

variable "config_bucket_name" {
  type        = string
  description = "Name of the S3 bucket that stores application configuration. Used in IAM policy."
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all resources."
  default     = {}
}
