# modules/data-stores/mysql/variables.tf

variable "db_name" {
  description = "Name for the RDS instance and database"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect on port 3306"
  type        = list(string)
  default     = []
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the RDS instance"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage in GB"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Enable Multi-AZ for high availability"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy (set false in prod)"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Prevent accidental deletion (set true in prod)"
  type        = bool
  default     = false
}
