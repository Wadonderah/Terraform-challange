terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "wadondera-terraform-state-556684850027"
    key            = "production/data-stores/mysql/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
      Team        = "platform"
    }
  }
}

module "mysql" {
  source = "../../../../modules/data-stores/mysql"

  db_name             = "proddb"
  db_username         = var.db_username
  db_password         = var.db_password
  instance_class      = "db.t3.small"                                  # More headroom for real traffic
  allocated_storage   = 100
  skip_final_snapshot = false                                          # Always keep a final snapshot in production
  backup_retention_period = 7                                          # 7-day rolling backups

  custom_tags = {
    CostCenter  = "engineering-prod"
    Criticality = "high"
  }
}

output "db_endpoint" {
  description = "Production RDS connection endpoint"
  value       = module.mysql.db_instance_endpoint
}

output "db_port" {
  value = module.mysql.db_instance_port
}
