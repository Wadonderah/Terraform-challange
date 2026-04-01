# Module: networking

Creates the full network foundation: VPC, public & private subnets across multiple AZs,
Internet Gateway, NAT Gateways (one per AZ for HA), route tables, and VPC Flow Logs.

## Usage

```hcl
module "networking" {
  source = "../../modules/networking"

  cluster_name       = "myapp-prod"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  common_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "MyApp"
    Owner       = "platform-engineering"
  }
}
```

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `cluster_name` | string | — | yes | Prefix for all resource names |
| `vpc_cidr` | string | `10.0.0.0/16` | no | VPC CIDR block |
| `availability_zones` | list(string) | — | yes | Min 2 AZs required |
| `common_tags` | map(string) | `{}` | no | Tags applied to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | Public subnet IDs (ALB placement) |
| `private_subnet_ids` | Private subnet IDs (EC2 placement) |
| `nat_gateway_ids` | NAT Gateway IDs |
| `flow_log_group_name` | CloudWatch log group for flow logs |

## Design Decisions

- **One NAT Gateway per AZ** — more expensive than a single NAT GW, but eliminates cross-AZ data transfer charges and AZ dependency. Use a single NAT GW in dev to save cost.
- **VPC Flow Logs** — `ALL` traffic logged to CloudWatch with 30-day retention. Essential for security audits and incident investigation.
- **Private subnets for EC2** — instances never have public IPs. All outbound traffic routes through NAT GW.
