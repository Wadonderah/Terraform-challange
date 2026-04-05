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
    key            = "production/services/webserver-cluster/terraform.tfstate"
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

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name              = "webservers-production"
  instance_type             = "t2.medium" # More headroom for real traffic
  min_size                  = 4           # 4 minimum = baseline capacity + HA
  max_size                  = 10          # Scale headroom for traffic spikes
  health_check_grace_period = 300         # Allow app warm-up time
  enable_autoscaling        = true        # Scale on CPU in production

  custom_tags = {
    CostCenter  = "engineering-prod"
    Criticality = "high"
  }
}

output "alb_dns_name" {
  description = "Production load balancer DNS — use this for your Route53 CNAME"
  value       = module.webserver_cluster.alb_dns_name
}

output "asg_name" {
  value = module.webserver_cluster.asg_name
}
