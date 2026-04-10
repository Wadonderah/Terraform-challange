# Module: networking/vpc

## What it does

Creates a production-ready VPC with:
- Public subnets (load balancers, NAT gateways)
- Private subnets (EC2 instances, RDS)
- Internet Gateway for public subnets
- NAT Gateway so private instances can reach the internet
- Separate route tables for public and private subnets

## Usage

```hcl
module "vpc" {
  source = "github.com/YOUR-ORG/modules//networking/vpc?ref=v1.0.0"

  name        = "my-app"
  environment = "prod"

  vpc_cidr             = "10.2.0.0/16"
  public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
  private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24"]
  availability_zones   = ["us-east-2a", "us-east-2b"]
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | string | — | Name prefix for all resources |
| `environment` | string | — | dev / stage / prod |
| `vpc_cidr` | string | `10.0.0.0/16` | VPC CIDR block |
| `public_subnet_cidrs` | list(string) | `["10.0.1.0/24","10.0.2.0/24"]` | Public subnet CIDRs |
| `private_subnet_cidrs` | list(string) | `["10.0.10.0/24","10.0.11.0/24"]` | Private subnet CIDRs |
| `availability_zones` | list(string) | `["us-east-2a","us-east-2b"]` | AZs — must match subnet list length |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | Public subnet IDs list |
| `private_subnet_ids` | Private subnet IDs list |
| `vpc_cidr` | VPC CIDR block |

## Design decisions

- One NAT gateway per VPC (not per AZ) — saves cost in non-prod environments. For production HA, extend the module to create one NAT gateway per AZ.
- Public subnets auto-assign public IPs (`map_public_ip_on_launch = true`) — only load balancers should live here.
- Private subnets route through NAT — instances have outbound internet access but no inbound.
