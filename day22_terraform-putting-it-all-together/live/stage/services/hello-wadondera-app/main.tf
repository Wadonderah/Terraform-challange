# live/stage/services/hello-wadondera-app/main.tf

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # S3 bucket for remote state storage
    # Created by bootstrap module in bootstrap/terraform.tfvars
    # Naming: <org>-terraform-state-<region>-<account-id>
    bucket = "wadoh-terraform-state-us-east-2-123456789012"
    
    # State file path follows pattern: <env>/services/<app-name>/terraform.tfstate
    # This ensures clear separation between environments and services
    key = "stage/services/hello-wadondera-app/terraform.tfstate"
    
    # Region must match the bucket region
    region = "us-east-2"
    
    # Enable encryption at rest (AES-256)
    # Additional encryption configured on bucket itself
    encrypt = true
    
    # DynamoDB table for state locking
    # Prevents concurrent modifications and state corruption
    # Created by bootstrap module
    dynamodb_table = "wadoh-terraform-locks-us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
}

module "hello_wadondera_app" {
  source = "../../../../modules/services/hello-wadondera-app"

  environment        = "stage"
  instance_type      = "t3.small"
  min_size           = 2
  max_size           = 4
  enable_autoscaling = true

  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = "db.t3.small"
}
