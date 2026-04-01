# Module: monitoring

Creates the full observability stack: 5 CloudWatch alarms wired to SNS, 4 log groups
with configurable retention, and a CloudWatch dashboard with 5 widgets.

## Usage

```hcl
module "monitoring" {
  source = "../../modules/monitoring"

  cluster_name            = "myapp-prod"
  asg_name                = module.compute.asg_name
  alb_arn_suffix          = split("loadbalancer/", module.compute.alb_arn)[1]
  target_group_arn_suffix = split(":targetgroup/", module.compute.target_group_arn)[1]
  scale_out_policy_arn    = module.compute.scale_out_policy_arn
  scale_in_policy_arn     = module.compute.scale_in_policy_arn
  kms_key_id              = module.security.kms_key_id
  alert_email_addresses   = ["oncall@example.com"]
  log_retention_days      = 90
  cpu_high_threshold      = 80
  cpu_low_threshold       = 20
}
```

## Alarms

| Alarm | Triggers When | Action |
|-------|--------------|--------|
| `high-cpu` | Avg CPU > 80% for 4 min | SNS email + scale-out |
| `low-cpu` | Avg CPU < 20% for 10 min | Scale-in (silent) |
| `alb-5xx-errors` | 5xx rate > 5% over 5 min | SNS email |
| `alb-latency` | p95 latency > 2s for 3 min | SNS email |
| `unhealthy-hosts` | Any unhealthy host | SNS email (immediate) |

## Dashboard Widgets

1. CPU Utilization (line chart with threshold annotations)
2. Request Count & 5xx Errors (dual-line)
3. Target Response Time — p50 / p95 / p99
4. ASG In-Service vs Desired Capacity
5. Alarm status panel (all 5 alarms)

## Outputs

| Name | Description |
|------|-------------|
| `sns_topic_arn` | ARN of the alerts SNS topic |
| `dashboard_url` | Direct link to the CloudWatch dashboard |
| `application_log_group_name` | Log group for app logs |
