###############################################################################
# live/dev/main.tf
# Calling configuration for the DEV environment
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket = "my-terraform-state"
  #   key    = "dev/webserver-cluster/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "day11-terraform-challenge"
      Environment = "dev"
    }
  }
}

module "webserver_cluster" {
  source = "../../modules/webserver-cluster"

  cluster_name = "webserver-dev"
  environment  = "dev"            # ← drives ALL conditional sizing decisions

  # Feature flags — off in dev to keep costs minimal
  enable_detailed_monitoring = false
  create_dns_record          = false

  # Greenfield: create a fresh VPC in dev
  use_existing_vpc = false
}

# ─── Outputs ─────────────────────────────────────────────────────────────────
output "alb_dns_name"      { value = module.webserver_cluster.alb_dns_name }
output "alarm_arn"         { value = module.webserver_cluster.alarm_arn }        # null in dev
output "instance_type"     { value = module.webserver_cluster.instance_type }    # t3.micro
output "cluster_min_size"  { value = module.webserver_cluster.cluster_min_size } # 1
output "cluster_max_size"  { value = module.webserver_cluster.cluster_max_size } # 3
