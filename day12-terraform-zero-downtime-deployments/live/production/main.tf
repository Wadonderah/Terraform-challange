###############################################################################
# live/production/main.tf
# Day 12 — Zero-Downtime Deployments — Production
###############################################################################

terraform {
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project = "day12-zero-downtime"
      Day     = "12"
    }
  }
}

module "webserver_cluster" {
  source = "../../modules/webserver-cluster"

  cluster_name  = "webserver-prod"
  environment   = "production"
  instance_type = "t3.micro"   # t3.medium in a paid account
  min_size      = 2
  max_size      = 4

  blue_app_version  = "v1"
  green_app_version = "v2"
  active_environment = "blue"
}

output "alb_dns_name"         { value = module.webserver_cluster.alb_dns_name }
output "active_environment"   { value = module.webserver_cluster.active_environment }
output "traffic_loop_command" { value = module.webserver_cluster.traffic_loop_command }
