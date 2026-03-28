###############################################################################
# live/production/main.tf
# Calling configuration for the PRODUCTION environment
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket = "my-terraform-state"
  #   key    = "production/webserver-cluster/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "day11-terraform-challenge"
      Environment = "production"
    }
  }
}

module "webserver_cluster" {
  source = "../../modules/webserver-cluster"

  cluster_name = "webserver-prod"
  environment  = "production"     # ← single variable drives ALL environment differences

  # Feature flags — monitoring on, DNS record created in production
  enable_detailed_monitoring = true
  create_dns_record          = false
  domain_name                = "app.example.com"

  # Brownfield: reuse an existing VPC that was provisioned by the networking team
  use_existing_vpc      = false
  existing_vpc_name_tag = "prod-vpc"
}

# ─── Outputs ─────────────────────────────────────────────────────────────────

output "alb_dns_name"      { value = module.webserver_cluster.alb_dns_name }
output "alarm_arn"         { value = module.webserver_cluster.alarm_arn }        # real ARN in prod
output "dns_record_fqdn"   { value = module.webserver_cluster.dns_record_fqdn }  # real FQDN in prod
output "instance_type"     { value = module.webserver_cluster.instance_type }    # t3.medium
output "cluster_min_size"  { value = module.webserver_cluster.cluster_min_size } # 3
output "cluster_max_size"  { value = module.webserver_cluster.cluster_max_size } # 10
