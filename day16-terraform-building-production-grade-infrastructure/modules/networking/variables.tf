variable "cluster_name" {
  type        = string
  description = "Unique name for this cluster/environment. Used as a prefix for all resources."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,28}[a-z0-9]$", var.cluster_name))
    error_message = "cluster_name must be 4-30 characters, lowercase alphanumeric and hyphens, must start with a letter."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC (e.g. 10.0.0.0/16)."
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "List of AWS availability zones to deploy into. Must have at least 2 for HA."

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all resources in this module."
  default     = {}
}
