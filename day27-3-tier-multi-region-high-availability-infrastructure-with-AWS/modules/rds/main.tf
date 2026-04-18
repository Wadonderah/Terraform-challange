terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Get the AWS managed KMS key for RDS in the current region (for replicas)
data "aws_kms_key" "rds" {
  count  = var.is_replica ? 1 : 0
  key_id = "alias/aws/rds"
}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "multi-region-ha"
    Region      = var.region
  })
}

resource "aws_security_group" "rds" {
  name        = "rds-sg-${var.environment}-${var.region}"
  description = "Allow MySQL inbound from application tier only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_db_subnet_group" "main" {
  name       = "db-subnet-group-${var.environment}-${var.region}"
  subnet_ids = var.subnet_ids
  tags       = local.common_tags
}

resource "aws_db_instance" "main" {
  identifier     = var.identifier
  engine         = "mysql"
  instance_class = var.instance_class

  # Primary-only settings — nulled out for replicas
  engine_version    = var.is_replica ? null : var.engine_version
  allocated_storage = var.is_replica ? null : var.allocated_storage
  db_name           = var.is_replica ? null : (var.db_name != "" ? var.db_name : null)
  username          = var.is_replica ? null : (var.db_username != "" ? var.db_username : null)
  password          = var.is_replica ? null : (var.db_password != "" ? var.db_password : null)

  # Replica-only setting
  replicate_source_db = var.is_replica ? var.replicate_source_db : null

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Multi-AZ only on primary
  multi_az = var.is_replica ? false : var.multi_az

  # Backup retention — replicas don't need local backups
  backup_retention_period = var.is_replica ? 0 : 7

  skip_final_snapshot = true
  storage_encrypted   = true
  publicly_accessible = false
  
  # For cross-region replicas, use default AWS managed key for RDS
  # This is required when replicating from an encrypted source to another region
  kms_key_id = var.is_replica ? data.aws_kms_key.rds[0].arn : null

  # Performance Insights for observability (not supported on t3.micro)
  performance_insights_enabled = false

  tags = merge(local.common_tags, {
    Name = var.identifier
    Role = var.is_replica ? "read-replica" : "primary"
  })
}
