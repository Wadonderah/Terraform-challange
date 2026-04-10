# modules/data-stores/mysql/main.tf
# RDS MySQL with encrypted storage, subnet group, and secrets via AWS Secrets Manager

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -------------------------
# DB Subnet Group
# -------------------------
resource "aws_db_subnet_group" "main" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name      = "${var.db_name}-subnet-group"
    ManagedBy = "terraform"
  }
}

# -------------------------
# Security Group for RDS
# -------------------------
resource "aws_security_group" "rds" {
  name        = "${var.db_name}-rds-sg"
  description = "Allow MySQL access from app layer"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.db_name}-rds-sg"
    ManagedBy = "terraform"
  }
}

# -------------------------
# RDS MySQL Instance
# -------------------------
resource "aws_db_instance" "main" {
  identifier              = var.db_name
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  allocated_storage       = var.allocated_storage
  storage_type            = "gp3"
  storage_encrypted       = true

  db_name  = replace(var.db_name, "-", "_")
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az               = var.multi_az
  publicly_accessible    = false
  skip_final_snapshot    = var.skip_final_snapshot
  deletion_protection    = var.deletion_protection

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  tags = {
    Name      = var.db_name
    ManagedBy = "terraform"
    Env       = var.environment
  }
}
