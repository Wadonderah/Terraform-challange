# =============================================================================
# main.tf — Production Environment Root Module
# =============================================================================
# Secrets are fetched from AWS Secrets Manager at apply time.
# They never appear in any .tf file or in plan/apply terminal output.
#
# BEFORE running terraform plan/apply you must:
#   1. Create the Secrets Manager secret (see scripts/bootstrap-secrets.sh)
#   2. Fill in terraform.tfvars (copy from terraform.tfvars.example)
# =============================================================================

# ---------------------------------------------------------------------------
# Data: fetch DB credentials from Secrets Manager
# ---------------------------------------------------------------------------

data "aws_secretsmanager_secret" "db_credentials" {
  name = var.db_secret_name
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

locals {
  db_credentials = jsondecode(
    data.aws_secretsmanager_secret_version.db_credentials.secret_string
  )
}

# ---------------------------------------------------------------------------
# Data: look up the VPC (only when vpc_id is provided)
# ---------------------------------------------------------------------------

data "aws_vpc" "selected" {
  id = var.vpc_id != "" ? var.vpc_id : null
}

# ---------------------------------------------------------------------------
# Security Group for RDS
# ---------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  count       = var.vpc_id != "" ? 1 : 0
  name        = "${var.environment}-rds-sg"
  description = "Controls inbound access to the RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "MySQL from VPC CIDR"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.environment}-rds-sg"
  }
}

# ---------------------------------------------------------------------------
# RDS Subnet Group
# ---------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  count       = length(var.private_subnet_ids) > 0 ? 1 : 0
  name        = "${var.environment}-rds-subnet-group"
  description = "Subnet group for ${var.environment} RDS instances"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "${var.environment}-rds-subnet-group"
  }
}

# ---------------------------------------------------------------------------
# RDS Instance — credentials from Secrets Manager
# ---------------------------------------------------------------------------

resource "aws_db_instance" "primary" {
  count = (
    var.vpc_id != "" &&
    length(var.private_subnet_ids) > 0
  ) ? 1 : 0

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "appdb"
  username = local.db_credentials["username"]
  password = local.db_credentials["password"]

  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]
  publicly_accessible    = false

  multi_az                  = false   # Set true for production HA
  backup_retention_period   = 0
  backup_window             = "03:00-04:00"
  maintenance_window        = "Mon:04:00-Mon:05:00"
  auto_minor_version_upgrade = true

  deletion_protection       = false   # Set true for real production
  skip_final_snapshot       = true    # Set false for real production
  final_snapshot_identifier = "${var.environment}-rds-final-snapshot"

  tags = {
    Name = "${var.environment}-primary-db"
  }
}
