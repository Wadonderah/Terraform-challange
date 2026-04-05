# =============================================================================
# modules/rds/main.tf — Reusable RDS Module
# =============================================================================
# This module accepts pre-resolved credentials from the calling environment.
# The environment is responsible for fetching secrets from Secrets Manager
# and passing the resolved values here. The module itself has no knowledge
# of where secrets come from.
# =============================================================================

resource "aws_db_instance" "this" {
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username # Sensitive — sourced from Secrets Manager by caller
  password = var.db_password # Sensitive — sourced from Secrets Manager by caller

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = false

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot

  tags = var.tags
}
