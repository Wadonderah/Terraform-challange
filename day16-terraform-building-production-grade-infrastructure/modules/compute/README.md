# Module: compute

Creates the application layer: Application Load Balancer, Target Group, Launch Template,
Auto Scaling Group with rolling instance refresh, and scaling policies.

## Usage

```hcl
module "compute" {
  source = "../../modules/compute"

  cluster_name          = "myapp-prod"
  environment           = "production"
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  web_security_group_id = module.security.web_security_group_id
  instance_profile_name = module.security.ec2_instance_profile_name
  kms_key_arn           = module.security.kms_key_arn
  ami_id                = data.aws_ami.amazon_linux_2023.id
  instance_type         = "t3.small"
  server_port           = 80
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  access_logs_bucket    = module.storage.config_bucket_id
}
```

## Key Design Decisions

### ELB Health Checks on the ASG
`health_check_type = "ELB"` ensures the ASG replaces instances that are running but
not serving healthy HTTP responses — not just instances the hypervisor can't reach.

### IMDSv2 Required
`http_tokens = "required"` prevents SSRF attacks from stealing instance credentials
via the metadata service.

### create_before_destroy on Target Group
Prevents downtime during target group replacement. New TG is registered and healthy
before the old one is removed from ALB listener rules.

### Instance Refresh
Zero-downtime rolling deployments when the launch template changes. Maintains 50%
minimum healthy capacity throughout the refresh.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cluster_name` | string | — | Resource name prefix |
| `environment` | string | — | One of: dev, staging, production |
| `instance_type` | string | `t3.micro` | Must be t2 or t3 family |
| `min_size` | number | `2` | ASG minimum |
| `max_size` | number | `6` | ASG maximum |
| `server_port` | number | `80` | App listen port |

## Outputs

| Name | Description |
|------|-------------|
| `alb_dns_name` | ALB DNS — point Route53 CNAME here |
| `asg_name` | ASG name — used by monitoring module |
| `scale_out_policy_arn` | Passed to monitoring for alarm actions |
| `scale_in_policy_arn` | Passed to monitoring for alarm actions |
