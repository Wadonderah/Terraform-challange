# =============================================================
# environments/prod/main.tf
# =============================================================
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # backend "s3" { ... }
}

provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "../../modules/webserver-cluster"

  cluster_name       = "prod-webserver"
  environment        = "production"
  enable_autoscaling = true # ← autoscaling ON in prod

  iam_users = {
    prod-alice = { department = "engineering", admin = true }
    prod-carol = { department = "devops", admin = true }
    prod-dave  = { department = "marketing", admin = false }
  }

  security_group_rules = {
    http = {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    }
    https = {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    }
  }
}

output "cluster_summary" {
  value = module.webserver_cluster.cluster_summary
}

output "admin_user_arns" {
  value     = module.webserver_cluster.admin_user_arns
  sensitive = false
}
