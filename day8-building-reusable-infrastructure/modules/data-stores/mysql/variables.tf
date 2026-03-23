variable "db_name" {
  description = "Name of the database to create inside the RDS instance"
  type        = string
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

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy. Set true for dev, false for production."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days to retain automated backups. 0 disables backups."
  type        = number
  default     = 7
}

variable "custom_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
