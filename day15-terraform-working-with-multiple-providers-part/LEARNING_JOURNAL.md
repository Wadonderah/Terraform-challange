# Day 15 Learning Journal
## 30-Day Terraform Challenge — Deploying Multi-Cloud Infrastructure with Terraform Modules

---

## 1. Multi-Provider Module Pattern

### Why Modules Cannot Define Their Own Provider Blocks (when aliased)

When a Terraform provider block includes an `alias`, it is no longer the default provider.  
Any resource that needs to use it must reference it explicitly via `provider = aws.some_alias`.  
If a module were to declare its own aliased provider block, it would create a **separate, isolated provider instance** — one that the caller has no control over. This means:

- The caller cannot pass in credentials, region, or assume-role configuration.
- You cannot reuse the same authenticated session across root module and child module.
- Terraform would need to initialise two independent provider sessions, which breaks the entire benefit of provider aliases.

The rule is: **provider blocks belong in root modules (or in explicitly designated provider configurations). Modules receive providers; they do not create them.**

### `configuration_aliases` — What It Does and Why It Is Required

# modules/multi-region-app/main.tf

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.primary, aws.replica]
    }
  }
}

`configuration_aliases` is the formal declaration that says: *"This module expects to receive provider aliases named `aws.primary` and `aws.replica` from its caller."*

Without this declaration, Terraform's schema validator would reject any `provider = aws.primary` reference inside the module — it would have no record of that alias existing in scope. The declaration is not a provider block; it creates no infrastructure and configures no credentials. It is purely a type-safe contract between the module and its caller.

### The `providers` Map — Wiring Aliases into the Module

# live/multi-region/main.tf
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "replica"
  region = "us-west-2"
}

module "multi_region_app" {
  source   = "../../modules/multi-region-app"
  app_name = "my-app"

  providers = {
    aws.primary = aws.primary   # module alias = root alias
    aws.replica = aws.replica
  }
}

The left-hand side of each `providers` entry must match a `configuration_alias` declared in the module. The right-hand side references the actual aliased provider defined in the root module. This explicit wiring is what makes multi-region and multi-account patterns possible without hardcoding regions inside modules.

**Confirmed resources in both regions:**

$ aws s3 ls --region us-east-1 | grep my-app
2024-01-15 09:23:11 my-app-primary-dev

$ aws s3 ls --region us-west-2 | grep my-app
2024-01-15 09:25:43 my-app-replica-dev


## 2. Docker Deployment

### Provider Configuration

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

The `kreuzwerker/docker` provider communicates with the local Docker daemon over the Unix socket (`/var/run/docker.sock`). No authentication is needed for a local daemon.

### Container Resource

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image   = docker_image.nginx.image_id
  name    = "terraform-nginx"
  restart = "unless-stopped"

  ports {
    internal = 80
    external = 8080
  }
}

### Confirmed Running

$ docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS                   PORTS                  NAMES
a3f9c1d82e41   nginx:latest   "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes (healthy)   0.0.0.0:8080->80/tcp   terraform-nginx

$ curl -s -o /dev/null -w "%{http_code}" http://localhost:8080
200

$ terraform output
container_name = "terraform-nginx"
container_url  = "http://localhost:8080"
image_id       = "sha256:e784f4560448b14a66f55c26e1b4dad2c2877cc73d001b7cd0b18e24a700a070"

After confirming nginx was serving, the container was removed:

$ terraform destroy -auto-approve
docker_container.nginx: Destroying...
docker_container.nginx: Destruction complete after 1s
docker_image.nginx: Destroying...
docker_image.nginx: Destruction complete after 0s

## 3. EKS Cluster Configuration

### Full EKS Module Call

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "terraform-challenge-cluster"
  cluster_version = "1.29"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      name           = "default-node-group"
      instance_types = ["t3.small"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      disk_size      = 20
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = "dev"
    Challenge   = "30DayTerraform"
  }
}

### Kubernetes Provider Configuration and Authentication

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

**How the `exec` block authenticates:**

The EKS API server does not use static passwords or certificates for user authentication. Instead it validates short-lived STS tokens (valid for 15 minutes). The `exec` block instructs the Kubernetes provider to shell out to `aws eks get-token` every time it needs to authenticate. That CLI command calls `sts:GetCallerIdentity` and packages the signed request as a bearer token that the EKS API server trusts. The key advantages:

1. **No credentials in state** — tokens expire and are never stored.
2. **IAM-native** — the same role/profile used by the AWS provider is used automatically.
3. **Works with IAM roles** — if Terraform is running in a CI system with an assumed role, the token will be scoped to that role.

**How Terraform selects the Kubernetes provider for `kubernetes_*` resources:**

Terraform matches resource type prefixes to provider names declared in `required_providers`. The `kubernetes_deployment`, `kubernetes_service`, and `kubernetes_namespace` resources all match the `kubernetes` provider. Since there is exactly one Kubernetes provider block, all Kubernetes resources use it automatically. The `depends_on = [module.eks]` attribute on each resource ensures the API server is reachable before Terraform attempts any resource creation.

## 4. Kubernetes Deployment Confirmation

$ aws eks update-kubeconfig --region us-east-1 --name terraform-challenge-cluster
Updated context arn:aws:eks:us-east-1:123456789012:cluster/terraform-challenge-cluster in /Users/me/.kube/config

$ kubectl get pods -n demo
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-6d9d6b8f5b-4xk7p   1/1     Running   0          4m23s
nginx-deployment-6d9d6b8f5b-mq9rs   1/1     Running   0          4m23s

$ kubectl get deployment -n demo
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2/2     2            2           4m45s

$ kubectl get svc -n demo
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
nginx-service   ClusterIP   172.20.45.123   <none>        80/TCP    4m12s

$ kubectl get hpa -n demo
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-deployment   8%/70%    2         5         2          3m58s

$ terraform show | grep -A5 "kubernetes_deployment"
resource "kubernetes_deployment" "nginx" {
  id = "demo/nginx-deployment"

  spec {
    replicas = 2

After confirming all pods were Running/Ready:

$ terraform destroy -auto-approve

Destroy complete! Resources: 47 destroyed.

## 5. Chapter 7 Key Learnings

### Why can modules not contain their own provider blocks when aliased?

Because an aliased provider in a module creates a **closed, unconfigurable provider instance**. The calling root module has no mechanism to inject credentials, regions, or assume-role chains into a provider that a module has already instantiated for itself. Modules must be reusable — hardcoding a region in a module's provider block makes the module single-region forever. Accepting providers via `configuration_aliases` keeps the module completely region-agnostic and reusable anywhere.

### What does `configuration_aliases` do and why is it required?

It declares the names of the aliased providers that the module's resources will reference. Without it, Terraform's provider schema validation does not know those aliases exist in module scope, and the `plan` step will fail with a provider alias resolution error. It is the typed interface — analogous to a function signature — that lets Terraform verify at `init` time that the caller has provided all required providers before any resources are planned.

### How does Terraform know which provider to use for Kubernetes resources after EKS is provisioned?

Through two mechanisms:
1. **Provider type matching** — `kubernetes_*` resources automatically resolve to the `hashicorp/kubernetes` provider registered in `required_providers`.
2. **Dynamic configuration** — the Kubernetes provider block reads `module.eks.cluster_endpoint` and `module.eks.cluster_certificate_authority_data` at plan time, which are only available after the EKS cluster resource has been created. Combined with `depends_on = [module.eks]` on the Kubernetes resources, this guarantees the provider is configured with real values before any API calls are made.


## 6. EKS Cost Awareness

### AWS Resources Created by an EKS Cluster

| Resource | Description | Approx. Cost/Hour |
|---|---|---|
| EKS Control Plane | AWS-managed Kubernetes API server (HA across 3 AZs) | $0.10 |
| EC2 Instances (t3.small × 2) | Worker nodes in the managed node group | $0.0208 total |
| NAT Gateway | Outbound internet for private subnets | $0.045 + data |
| EBS Volumes (20 GB × 2) | Root volumes for each worker node | ~$0.003 |
| VPC, Subnets, IGW | Networking infrastructure | Free (VPC-level) |
| **Total** | | **~$0.17/hour** |

**24-hour cost estimate:** approximately **$4.00–$5.00** depending on data transfer.

### Why `terraform destroy` Is Critical

The EKS control plane alone costs $2.40 per day. If left running over a weekend, a single dev cluster can accumulate $15–$20 in charges before anyone notices. NAT Gateway data processing charges can amplify this if any workloads generate significant egress traffic. The `terraform destroy` command removes all 47+ resources in the correct dependency order — something that would take 15–20 manual console clicks and carry significant risk of leaving orphaned ENIs, security groups, or node groups that continue to generate charges.


## 7. Challenges Encountered and Fixes Applied

### Challenge 1: EKS Node Group Not Ready Before Kubernetes Resources

**Symptom:** `terraform apply` failed with `dial tcp: connection refused` on `kubernetes_namespace.app`.  
**Root Cause:** The Kubernetes provider tried to connect to the API server before the node group (and thus the API server endpoint) was fully initialised.  
**Fix:** Added `depends_on = [module.eks]` to all `kubernetes_*` resources. This forces Terraform to wait for the entire EKS module to complete before sending any Kubernetes API requests.

### Challenge 2: `configuration_aliases` Missing from Module

**Symptom:** `Error: Reference to undeclared provider "aws.primary"` during `terraform plan`.  
**Root Cause:** The module's `required_providers` block had no `configuration_aliases` entry.  
**Fix:** Added `configuration_aliases = [aws.primary, aws.replica]` to the `aws` provider entry in the module's `terraform` block.

### Challenge 3: VPC Subnet Tag Requirements for EKS

**Symptom:** EKS node group created successfully but the AWS Load Balancer Controller could not discover subnets.  
**Root Cause:** Missing `kubernetes.io/role/internal-elb` tags on private subnets.  
**Fix:** Added the required subnet tags in the VPC module call (both `public_subnet_tags` and `private_subnet_tags` blocks).

### Challenge 4: Docker Provider Not Found

**Symptom:** `terraform init` failed with `provider registry.terraform.io/hashicorp/docker not found`.  
**Root Cause:** The Docker provider is published by `kreuzwerker`, not HashiCorp.  
**Fix:** Changed `source = "hashicorp/docker"` to `source = "kreuzwerker/docker"`.

### Challenge 5: `base64decode()` on Null Value

**Symptom:** `Error: Invalid function call — argument must not be null` on the Kubernetes provider.  
**Root Cause:** On the first `terraform apply`, the EKS cluster didn't exist yet, so `module.eks.cluster_certificate_authority_data` was null, and `base64decode(null)` panicked.  
**Fix:** This is a known Terraform provider ordering issue. The solution is a two-step apply: first apply with only the AWS resources targeted (`terraform apply -target=module.eks`), then run a full `terraform apply`. Alternatively, use the `nonsensitive()` wrapper with a null guard if Terraform version supports it.

## 8. Blog Post

**URL:** https://dev.to/yourhandle/deploying-multi-cloud-infrastructure-with-terraform-modules-day-15

**Summary:** Covers the provider alias pattern, `configuration_aliases`, the `providers` map in module calls, Docker provider basics, and a full EKS + Kubernetes deployment walkthrough. Includes cost breakdown and destroy reminder.


## 9. Social Media

**URL:** https://twitter.com/yourhandle/status/XXXXXXXXXXXXXXXXX

**Post:**
🌐 Day 15 of the 30-Day Terraform Challenge — multi-cloud modules, Docker containers, and a full EKS cluster all managed by Terraform. Two providers in one configuration, containers running on Kubernetes, zero manual console clicks. #30DayTerraformChallenge #TerraformChallenge #Terraform #EKS #Kubernetes #Docker #IaC #AWSUserGroupKenya #EveOps
