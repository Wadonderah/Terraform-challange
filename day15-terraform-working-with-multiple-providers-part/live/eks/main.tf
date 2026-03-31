# live/eks/main.tf
# -----------------------------------------------------------------------------
# EKS Cluster + Kubernetes Workload — Production-Ready Pattern
#
# Resource hierarchy:
#   VPC (module.vpc)
#     └── EKS Cluster (module.eks)
#           └── Kubernetes Deployment / Service (kubernetes_*)
#
# Provider dependency chain:
#   1. AWS provider provisions the VPC and EKS control plane.
#   2. Once EKS outputs are available, the Kubernetes provider is configured
#      dynamically using those outputs (endpoint + CA cert).
#   3. The exec block tells the Kubernetes provider to call `aws eks get-token`
#      for short-lived authentication tokens — no static credentials needed.
#
# COST WARNING:
#   An EKS control plane costs ~$0.10/hour (~$2.40/day).
#   Two t3.small worker nodes cost ~$0.04/hour combined.
#   Always run `terraform destroy` immediately after validating the cluster.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }

  # Uncomment to store state remotely (strongly recommended for EKS)
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "day15/eks/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

# ---------------------------------------------------------------------------
# AWS Provider — default region from the environment or tfvars
# ---------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# ---------------------------------------------------------------------------
# Kubernetes Provider — dynamically configured from EKS module outputs.
#
# WHY exec AND NOT static credentials?
# The EKS API server uses short-lived bearer tokens (15 minutes) generated
# by the AWS STS service. The exec block delegates token generation to the
# AWS CLI, which respects the same IAM role/credentials as the AWS provider.
# This means no tokens are ever stored in state or environment variables.
#
# HOW does Terraform know which provider to use for kubernetes_* resources?
# Terraform matches kubernetes_* resources to the "kubernetes" provider entry
# in required_providers. Because there is only one kubernetes provider block,
# all kubernetes_* resources automatically use it. The `depends_on` on the
# deployment resource (below) ensures the EKS cluster exists before any
# Kubernetes API calls are attempted.
# ---------------------------------------------------------------------------

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name", module.eks.cluster_name,
      "--region", var.aws_region,
    ]
  }
}

# ---------------------------------------------------------------------------
# Locals
# ---------------------------------------------------------------------------

locals {
  cluster_name = "terraform-challenge-cluster"

  common_tags = {
    Project     = "30DayTerraformChallenge"
    Day         = "15"
    ManagedBy   = "Terraform"
    Environment = var.environment
    Owner       = "AWSUserGroupKenya"
  }
}

# ---------------------------------------------------------------------------
# Data Sources
# ---------------------------------------------------------------------------

# Fetch available AZs in the chosen region (used by the VPC module)

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# ---------------------------------------------------------------------------
# VPC — three public and three private subnets across three AZs.
# EKS worker nodes live in private subnets; the control plane is AWS-managed.
# The public subnets host NAT Gateway and any public-facing load balancers.
# ---------------------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [for k, v in slice(data.aws_availability_zones.available.names, 0, 3) : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in slice(data.aws_availability_zones.available.names, 0, 3) : cidrsubnet(var.vpc_cidr, 4, k + 4)]

  enable_nat_gateway   = true
  single_nat_gateway   = true   # Cost optimisation for dev; use false in prod
  enable_dns_hostnames = true
  enable_dns_support   = true

  # These subnet tags are REQUIRED by the EKS module and AWS load balancer
  # controller to discover which subnets to place load balancers in.

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# EKS Cluster — uses the official AWS EKS Terraform module
# ---------------------------------------------------------------------------

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true   # Allows `kubectl` from your laptop

  # EKS Managed Node Groups — AWS manages the underlying EC2 autoscaling group

  eks_managed_node_groups = {
    default = {
      name           = "default-node-group"
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Use AL2 for broad compatibility; switch to AL2023 for newer clusters
      
      ami_type = "AL2_x86_64"

      disk_size = 20   # GB per node

      labels = {
        role = "worker"
      }

      tags = local.common_tags
    }
  }

  # Allow the caller's IAM identity to administer the cluster via kubectl
  
  enable_cluster_creator_admin_permissions = true

  tags = merge(local.common_tags, {
    Challenge = "30DayTerraform"
  })
}
