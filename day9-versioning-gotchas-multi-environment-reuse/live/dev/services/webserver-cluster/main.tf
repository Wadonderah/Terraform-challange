# -----------------------------------------------------------------------------
# live/dev/services/webserver-cluster/main.tf
#
# Dev environment — pinned to v0.0.2 (latest) to test new module features.
# Dev intentionally runs the newest module version so issues are caught
# here before v0.0.2 is promoted to production.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0.0"

  # RECOMMENDED: remote state for real teams
  # NOTE: uncomment the backend block below to enable remote state storage
  # NOTE: the backend configuration below is for demo purposes only

  # backend "s3" {
  #   bucket         = "my-terraform-state-dev"
  #   key            = "dev/services/webserver-cluster/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "terraform"
      Project     = "webserver-cluster"
    }
  }
}

# Dev uses v0.0.2 — the latest version being validated before production promotion
# v0.0.2 feature — testing the health check grace period
# v0.0.2 feature — enable alarms in dev to validate alarm config before prod

module "webserver_cluster" {
  source = "github.com/Wadonderah/Terraform-challange//day9-versioning-gotchas-multi-environment-reuse/modules/terraform-aws-webserver-cluster?ref=main"

  cluster_name  = "webservers-dev"
  instance_type = "t2.micro"   # small/cheap for dev
  min_size      = 2
  max_size      = 4
  desired_capacity = 2
  health_check_grace_period = 300
  enable_cloudwatch_alarms = true
  cpu_alarm_threshold      = 85           # looser threshold for dev noise reduction

  extra_tags = {
    Environment = "dev"
    CostCenter  = "engineering-dev"
  }
}
