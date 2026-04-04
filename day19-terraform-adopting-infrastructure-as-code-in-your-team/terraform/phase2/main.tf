################################################################################
# Phase 2 — Import existing infrastructure
#
# The security group below already exists in AWS. It was created manually
# sometime in 2022 and nobody is sure exactly what it does or who owns it.
# That's precisely why we're importing it — to get it under version control
# before someone accidentally deletes it or pokes a hole in it without review.
#
# Workflow:
#   1. Write this resource block to match what's already in AWS (terraform plan
#      should show no changes after the import — that's your success signal)
#   2. Run: terraform import aws_security_group.prod_app sg-0abc123def456789
#   3. Run: terraform plan — expect "No changes. Infrastructure is up-to-date."
#   4. Open a PR. Get it reviewed. Merge it.
#   5. Now any future change goes through code review. That's the whole point.
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "acme-terraform-state"
    key            = "networking/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "af-south-1"

  default_tags {
    tags = {
      ManagedBy = "terraform"
    }
  }
}

###############################################################################
# Imported: production application security group
#
# Previously managed by hand. Every ingress rule was someone's "quick fix"
# that never got removed. Now it's code. Now we can see the history.
###############################################################################

resource "aws_security_group" "prod_app" {
  name        = "acme-prod-app-sg"
  description = "Allow inbound HTTPS and app traffic from ALB"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "App port from load balancer only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound — tighten this when you have time"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "acme-prod-app-sg"
    Environment = "production"
    ImportedAt  = "2024-01-15"
    ImportedBy  = "platform-team"
  }

  lifecycle {
    # Prevent accidental deletion — this group is attached to running instances
    prevent_destroy = true
  }
}

resource "aws_security_group" "alb" {
  name        = "acme-prod-alb-sg"
  description = "Load balancer — public facing"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "HTTP redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "acme-prod-alb-sg"
    Environment = "production"
  }
}

data "aws_vpc" "main" {
  tags = {
    Name = "acme-prod-vpc"
  }
}

###############################################################################
# Import commands — run these once, in order
#
#   terraform import aws_security_group.alb    sg-0loadbalancer1234
#   terraform import aws_security_group.prod_app sg-0abc123def456789
#
# Expected output after both imports:
#
#   $ terraform plan
#   No changes. Your infrastructure matches the configuration.
###############################################################################
