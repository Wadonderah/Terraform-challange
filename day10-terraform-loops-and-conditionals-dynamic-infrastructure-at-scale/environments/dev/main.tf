# =============================================================
# environments/dev/main.tf
# =============================================================
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # backend "s3" { ... }  # uncomment and configure for real use
}

provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "../../modules/webserver-cluster"

  cluster_name       = "dev-webserver"
  environment        = "dev"
  enable_autoscaling = false # ← no autoscaling in dev: saves cost

  iam_users = {
    dev-alice = { department = "engineering", admin = true }
    dev-bob   = { department = "qa", admin = false }
  }

  security_group_rules = {
    http = {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    }
    ssh = {
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"] # internal only in dev
      description = "SSH from VPN"
    }
  }
}

output "cluster_summary" {
  value = module.webserver_cluster.cluster_summary
}

output "user_arns" {
  value = module.webserver_cluster.user_arns
}
