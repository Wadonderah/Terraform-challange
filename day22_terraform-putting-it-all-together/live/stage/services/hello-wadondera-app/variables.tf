# live/stage/services/hello-wadondera-app/variables.tf
variable "db_username" {
  description = "RDS master username — set via TF_VAR_db_username"
  type        = string
  sensitive   = true
}
variable "db_password" {
  description = "RDS master password — set via TF_VAR_db_password"
  type        = string
  sensitive   = true
}
