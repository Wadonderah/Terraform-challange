# ==============================================================================
# Example Root Configuration - Day 21 Webserver Cluster
# This is an example of how to use the webserver-cluster module
# ==============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Day21-Infrastructure-Workflow"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# ==============================================================================
# Call the webserver-cluster module
# ==============================================================================

module "webserver_cluster" {
  source = "./modules/webserver-cluster"

  cluster_name = "${var.environment}-webserver-cluster"

  # CloudWatch alarm thresholds
  cpu_high_threshold = var.cpu_high_threshold
  cpu_low_threshold  = var.cpu_low_threshold
  alb_5xx_threshold  = var.alb_5xx_threshold

  # Alert notifications
  alert_email = var.alert_email
}

# ==============================================================================
# Outputs
# ==============================================================================

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.webserver_cluster.asg_name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.webserver_cluster.alb_dns_name
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = module.webserver_cluster.cloudwatch_dashboard_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = module.webserver_cluster.sns_topic_arn
}

output "alarm_arns" {
  description = "Map of alarm names to ARNs"
  value       = module.webserver_cluster.alarm_arns
}