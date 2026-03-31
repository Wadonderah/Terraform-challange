# live/docker/variables.tf

variable "nginx_version" {
  description = "nginx Docker image tag to pull."
  type        = string
  default     = "latest"
}

variable "host_port" {
  description = "Host (external) port to map to the container's port 80."
  type        = number
  default     = 8080

  validation {
    condition     = var.host_port >= 1024 && var.host_port <= 65535
    error_message = "host_port must be between 1024 and 65535 (unprivileged range)."
  }
}
