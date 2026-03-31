# Day 15 — Working with Multiple Providers (Part 2)
## 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya × EveOps


## Project Structure

day15-terraform/
├── modules/
│   └── multi-region-app/       # Reusable module: S3 cross-region replication
│       ├── main.tf             # Resources + configuration_aliases declaration
│       ├── variables.tf
│       └── outputs.tf
└── live/
    ├── multi-region/           # Lab: deploy the module across us-east-1 / us-west-2
    │   ├── main.tf             # Provider aliases + module call with providers map
    │   ├── variables.tf
    │   └── outputs.tf
    ├── docker/                 # Lab: manage nginx container via Docker provider
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── eks/                    # Lab: EKS cluster + Kubernetes workload
        ├── main.tf             # AWS + Kubernetes provider, VPC + EKS modules
        ├── kubernetes.tf       # Namespace, Deployment, Service, HPA
        ├── variables.tf
        └── outputs.tf


## Quick-Start Guide

### Prerequisites

| Tool | Minimum Version | Install |
|------|----------------|---------|
| Terraform | 1.5.0 | https://developer.hashicorp.com/terraform/install |
| AWS CLI | 2.x | https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html |
| kubectl | 1.29 | https://kubernetes.io/docs/tasks/tools/ |
| Docker | 24.x | https://docs.docker.com/get-docker/ |

### AWS Authentication

```bash
aws configure            # or use AWS_PROFILE / AWS_ACCESS_KEY_ID env vars
aws sts get-caller-identity   # confirm credentials are working
```

## Lab 1: Multi-Region S3 Module

```bash
cd live/multi-region

terraform init
terraform plan -var="app_name=my-app"
terraform apply -var="app_name=my-app"

# Confirm buckets in both regions
aws s3 ls --region us-east-1 | grep my-app
aws s3 ls --region us-west-2 | grep my-app

terraform destroy -var="app_name=my-app"
```

**Key concept:** The `providers` map in the `module` block wires the root module's aliased providers to the `configuration_aliases` declared in the module's `required_providers` block.


## Lab 2: Docker Container

```bash
# Docker must be running before this step
cd live/docker

terraform init
terraform apply

# Confirm nginx is serving
curl http://localhost:8080        # expect 200 OK
docker ps | grep terraform-nginx  # expect running container

# Always clean up
terraform destroy

## Lab 3: EKS Cluster + Kubernetes Workload

> ⚠️ **Cost warning:** An EKS cluster costs ~$0.17/hour (~$4/day). Destroy immediately after confirming it works.

```bash
cd live/eks

terraform init

# Step 1: Provision AWS infrastructure first (avoids provider chicken-and-egg issue)
terraform apply -target=module.vpc -target=module.eks

# Step 2: Deploy Kubernetes workloads
terraform apply

# Configure kubectl
$(terraform output -raw configure_kubectl)

# Confirm pods are running
kubectl get pods -n demo
kubectl get deployment -n demo
kubectl get svc -n demo
kubectl get hpa -n demo

# ⚠️ CRITICAL: Destroy immediately to avoid charges
terraform destroy
```

## Core Concepts Covered

### Provider Alias Pattern

# Root module — providers are ALWAYS declared here
provider "aws" { alias = "primary"; region = "us-east-1" }
provider "aws" { alias = "replica";  region = "us-west-2" }

module "example" {
  source = "../../modules/example"
  providers = {
    aws.primary = aws.primary
    aws.replica = aws.replica
  }
}

# Module — declares what it expects, never creates providers
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.primary, aws.replica]
    }
  }
}

resource "aws_s3_bucket" "primary" {
  provider = aws.primary   # uses the provider passed in by the caller
  bucket   = "..."
}

### Kubernetes Provider Authentication via exec

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

The `exec` block generates a short-lived STS token (15 min TTL) via the AWS CLI — no static credentials are stored anywhere.


## Estimated AWS Costs

| Resource | Cost/Hour | Cost/Day |
|---|---|---|
| EKS Control Plane | $0.100 | $2.40 |
| 2× t3.small nodes | $0.021 | $0.50 |
| NAT Gateway | $0.045 | $1.08 |
| EBS volumes (40 GB) | $0.003 | $0.07 |
| **Total** | **~$0.17** | **~$4.05** |

Run `terraform destroy` as soon as validation is complete.

*Part of the 30-Day Terraform Challenge by AWS AI/ML UserGroup Kenya, Meru HashiCorp User Group, and EveOps.*
