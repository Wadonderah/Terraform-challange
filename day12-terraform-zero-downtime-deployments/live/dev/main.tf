###############################################################################
# live/dev/main.tf
# Day 12 — Zero-Downtime Deployments
#
# WORKFLOW:
#   Step 1: Apply with blue_app_version = "v1", active_environment = "blue"
#           → Blue ASG serves v1. Green ASG serves v2 (standby).
#
#   Step 2: Start traffic loop in a second terminal:
#           while true; do curl -s http://<alb-dns> | grep version; sleep 2; done
#
#   Step 3: Switch active_environment = "green"
#           → Single terraform apply. Listener rule flips. Traffic shifts instantly.
#
#   Step 4: To roll back, flip back to "blue" and apply again.
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


# ── Blue/Green config ──────────────────────────────────────────────────────
# Blue = currently deployed version
blue_app_version = "v1"

# Green = new version ready to receive traffic
green_app_version = "v2"

# Change this to "green" and re-apply to switch live traffic
active_environment = "blue"


module "webserver_cluster" {
  source = "../../modules/webserver-cluster"

  cluster_name  = "webserver-dev"
  environment   = "dev"
  instance_type = "t3.micro"
  min_size      = 1
  max_size      = 2

}

# ── Outputs ──────────────────────────────────────────────────────────────────

output "alb_dns_name" { value = module.webserver_cluster.alb_dns_name }
output "active_environment" { value = module.webserver_cluster.active_environment }
output "traffic_loop_command" { value = module.webserver_cluster.traffic_loop_command }
output "blue_asg" { value = module.webserver_cluster.blue_asg_name }
output "green_asg" { value = module.webserver_cluster.green_asg_name }
