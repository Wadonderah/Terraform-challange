# Sensitive values — pass via TF_VAR_ env vars or a .tfvars file (never commit to git)

variable "db_username" {
  description = "Master username for the dev RDS instance"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the dev RDS instance"
  type        = string
  sensitive   = true
}
