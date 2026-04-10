# Module: compute/asg-rolling-deploy

## What it does

Deploys an Auto Scaling Group with **zero-downtime rolling deployments**.

Key behaviours:
- `create_before_destroy = true` — new instances are launched and pass health checks before old ones are terminated
- ASG name includes the launch template version — any change to the template forces a new ASG, triggering a rolling replacement
- Instances live in **private subnets** — only the ALB has a public-facing address
- Optional scheduled scale-out (9am) and scale-in (5pm) for cost saving
- CloudWatch alarm fires when CPU > 90%

## Usage

```hcl
module "asg" {
  source = "github.com/YOUR-ORG/modules//compute/asg-rolling-deploy?ref=v1.0.0"

  cluster_name          = "prod-hello-world"
  environment           = "prod"
  instance_type         = "t3.medium"
  min_size              = 3
  max_size              = 9
  enable_autoscaling    = true
  server_port           = 8080

  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  target_group_arn      = module.alb.target_group_arn
  alb_security_group_id = module.alb.alb_security_group_id
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cluster_name` | string | — | Unique name for this ASG cluster |
| `environment` | string | — | dev / stage / prod |
| `instance_type` | string | `t3.micro` | Must be in allowed list (validated) |
| `min_size` | number | — | Minimum instances (≥ 1, validated) |
| `max_size` | number | — | Maximum instances |
| `enable_autoscaling` | bool | `false` | Enables 9am/5pm scheduled scaling |
| `server_port` | number | `8080` | Port the web server listens on |
| `vpc_id` | string | — | VPC to deploy into |
| `subnet_ids` | list(string) | — | Private subnet IDs |
| `target_group_arn` | string | — | ALB target group ARN |
| `alb_security_group_id` | string | — | ALB security group (allows ingress from it) |

## Outputs

| Name | Description |
|------|-------------|
| `asg_name` | ASG name |
| `instance_security_group_id` | Security group attached to instances |
| `launch_template_id` | Launch template ID |

## How zero-downtime works

1. You change `instance_type` (or any variable that affects the launch template)
2. Terraform creates a **new** launch template version
3. The ASG name includes the version number — so a new ASG resource is planned
4. `create_before_destroy` means the new ASG starts launching instances first
5. New instances register with the ALB target group and pass health checks
6. Only then does Terraform destroy the old ASG and its instances
7. Zero traffic is dropped during the rotation
