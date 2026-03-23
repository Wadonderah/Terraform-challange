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
    key            = "dev/data-stores/mysql/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "terraform"
      Team        = "platform"
    }
  }
}

module "mysql" {
  source = "../../../../modules/data-stores/mysql"

  db_name             = "devdb"
  db_username         = var.db_username
  db_password         = var.db_password
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  skip_final_snapshot = true                        # Fine for dev — no need to keep a snapshot on destroy
  backup_retention_period = 0                       # Disable backups in dev to save cost

  custom_tags = {
    CostCenter = "engineering-dev"
  }
}

output "db_endpoint" {
  description = "Dev RDS connection endpoint"
  value       = module.mysql.db_instance_endpoint
}

output "db_port" {
  value = module.mysql.db_instance_port
}
