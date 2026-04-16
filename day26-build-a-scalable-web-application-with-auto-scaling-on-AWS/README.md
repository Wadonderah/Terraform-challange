# Day 26: Building a Scalable Web Application on AWS with EC2, ALB, and Auto Scaling using Terraform

> **30-Day Terraform Challenge — Day 26**
> AWS AI/ML UserGroup Kenya · Meru HashiCorp User Group · EveOps

---

## What We Built

A production-grade, auto-scaling web application tier on AWS — wired together from three Terraform modules and zero hardcoded values. The system automatically adds EC2 instances when CPU climbs above 70 % and removes them when it drops below 30 %, with CloudWatch alarms closing the feedback loop.

---

## Project Directory Tree

```
day26-scalable-web-app/
├── backend.tf                        # S3 remote state + DynamoDB locking
├── provider.tf                       # AWS provider, version constraints, default tags
├── modules/
│   ├── ec2/
│   │   ├── main.tf                   # Security group + Launch Template
│   │   ├── variables.tf              # ami_id, instance_type, key_name, environment, tags
│   │   └── outputs.tf                # launch_template_id, launch_template_version, sg_id
│   ├── alb/
│   │   ├── main.tf                   # ALB, target group, HTTP listener, request-count alarm
│   │   ├── variables.tf              # name, vpc_id, subnet_ids, environment, tags
│   │   └── outputs.tf                # alb_dns_name, target_group_arn, alb_security_group_id
│   └── asg/
│       ├── main.tf                   # ASG, scale-out/in policies, CloudWatch alarms, dashboard
│       ├── variables.tf              # launch_template_id/version, subnet_ids, target_group_arns,
│       │                             #   min/max/desired, cpu thresholds, environment, tags
│       └── outputs.tf                # asg_name, asg_arn, policy ARNs, dashboard name
└── envs/
    └── dev/
        ├── main.tf                   # Module calls — wires outputs between modules
        ├── variables.tf              # All variables consumed by this env
        ├── outputs.tf                # Surfaces key values after apply
        └── terraform.tfvars          # Concrete values for dev
```

---

## Why Three Separate Modules?

| Concern | Module | Why isolated |
|---|---|---|
| **Instance definition** | `ec2` | Launch Templates change independently of load balancers — you update AMI or user-data without touching ALB config. |
| **Traffic distribution** | `alb` | ALB, target group, and listener are networking concerns. They belong together but are completely separate from compute. |
| **Capacity management** | `asg` | Scaling logic (min/max/desired, policies, alarms) changes based on operational needs — not tied to which AMI or which ALB. |

Splitting into three modules also means **each module can be unit-tested independently** and reused across different environments or projects.



## Module Deep-Dive

### `modules/ec2` — Launch Template

**variables.tf — every variable explained:**

| Variable | Default | Reason for default / no default |
|---|---|---|
| `instance_type` | `t3.micro` | Safe dev default; always overridable |
| `ami_id` | *(none)* | Region-specific — must be explicit, no safe default |
| `key_name` | `null` | Dev environments skip SSH; SSH should be opt-in |
| `environment` | *(none)* | No default forces explicit declaration; validated to dev/staging/production |
| `tags` | `{}` | Optional additional tagging; merged with mandatory tags in locals |

Key design decisions in `main.tf`:
- `locals.common_tags` merges caller tags with mandatory `Environment`, `ManagedBy`, `Project` tags — the ASG propagates these to every instance automatically.
- `user_data` installs Apache (`httpd`) and writes a simple HTML page identifying the environment. This proves the instance is alive and the ALB is routing correctly on first access.
- `lifecycle { create_before_destroy = true }` ensures zero-downtime template updates — a new template version is created before the old one is destroyed.

---

### `modules/alb` — Application Load Balancer

**variables.tf — every variable explained:**

| Variable | Default | Reason |
|---|---|---|
| `name` | *(none)* | Used as resource name prefix — no safe generic default |
| `vpc_id` | *(none)* | Topology-specific — must be explicit |
| `subnet_ids` | *(none)* | At least two AZs required by AWS — enforced at plan time |
| `environment` | *(none)* | Same as ec2 module — forces explicit declaration |
| `tags` | `{}` | Optional |

Key design decisions in `main.tf`:
- **Separate security groups for ALB and instances.** The ALB SG accepts public traffic (port 80/443). In production you would add a rule to the instance SG allowing traffic *only from the ALB SG* — not from `0.0.0.0/0`. This is intentionally kept simple for Day 26.
- The **health check** hits `/` and expects HTTP 200 with a 5 s timeout. Two consecutive successes mark an instance healthy; two consecutive failures remove it from rotation. This is identical to the ALB's ELB health check criteria used by the ASG.
- **Bonus alarm** (`aws_cloudwatch_metric_alarm.high_request_count`) fires when `RequestCountPerTarget` exceeds 1,000 requests/min. This is a traffic-based signal complementary to CPU.

---

### `modules/asg` — Auto Scaling Group

**variables.tf — every variable explained:**

| Variable | Default | Reason |
|---|---|---|
| `launch_template_id` | *(none)* | Injected from `module.ec2` — no default |
| `launch_template_version` | `"$Latest"` | Always use newest template; override to pin |
| `subnet_ids` | *(none)* | Private subnets — no default, topology-specific |
| `target_group_arns` | *(none)* | Injected from `module.alb` — no default |
| `min_size` | `1` | Never scale to zero in dev |
| `max_size` | `4` | Cap spend in dev |
| `desired_capacity` | `2` | Two instances = cross-AZ HA at launch |
| `cpu_scale_out_threshold` | `70` | Industry standard threshold |
| `cpu_scale_in_threshold` | `30` | Generous cooldown prevents flapping |
| `environment` | *(none)* | Explicit |
| `tags` | `{}` | Optional |

**`health_check_type = "ELB"` — why it matters:**

Without this, the ASG uses EC2 health checks, which only test whether the instance is *running*. An instance can be running but have a crashed web server — EC2 sees it as healthy; your users see errors. Setting `health_check_type = "ELB"` tells the ASG to trust the ALB's health checks. If the ALB marks an instance unhealthy (e.g., `/` returns 503 for two consecutive checks), the ASG automatically terminates that instance and launches a replacement. This is the correct behaviour for a web tier.

**Scaling flow when CPU exceeds 70 %:**

```
1. EC2 emits CPUUtilization metric every 60 s → CloudWatch
2. aws_cloudwatch_metric_alarm.cpu_high evaluates:
      Average CPUUtilization >= 70 for 2 consecutive 120 s periods
3. Alarm transitions to ALARM state → fires alarm_actions
4. alarm_actions = [aws_autoscaling_policy.scale_out.arn]
5. scale_out policy: ChangeInCapacity +1, cooldown 300 s
6. ASG launches a new EC2 instance from the Launch Template
7. New instance runs user_data → httpd starts
8. ALB health check hits /  → 200 OK → instance enters InService
9. ALB distributes traffic across all InService instances
10. CPU distributes → metric drops below threshold → ALARM resolves
```

**`force_delete = var.environment != "production"`** — set to `true` in dev/staging so `terraform destroy` doesn't time out waiting for instances to drain.

---

## Calling Configuration — `envs/dev/main.tf`


module "asg" {
  source = "../../modules/asg"

  launch_template_id      = module.ec2.launch_template_id      # ← from ec2 module
  launch_template_version = module.ec2.launch_template_version # ← from ec2 module
  subnet_ids              = var.private_subnet_ids
  target_group_arns       = [module.alb.target_group_arn]      # ← from alb module
  
}


The calling configuration is deliberately thin. All complexity — security groups, health checks, CloudWatch resources, lifecycle rules — lives inside the modules. The root `main.tf` is just wiring. This is the DRY principle applied to infrastructure: if you needed a `staging` environment you would add `envs/staging/` with a different `terraform.tfvars` and the same module calls.

---

## Deploy Commands

```bash
# From the repo root, work in the dev environment
cd envs/dev

# 1. Initialise — downloads providers, configures S3 backend
terraform init

# 2. Validate syntax and references
terraform validate

# 3. Preview what will be created (18–22 resources)
terraform plan

# 4. Deploy
terraform apply

# 5. Retrieve the ALB URL
terraform output alb_dns_name
# → web-challenge-day26-alb-dev-XXXXXXXXXXXX.us-east-1.elb.amazonaws.com
```

**Expected `terraform apply` output (abridged):**

module.ec2.aws_security_group.instance: Creating...
module.alb.aws_security_group.alb: Creating...
module.ec2.aws_security_group.instance: Creation complete after 2s
module.ec2.aws_launch_template.web: Creating...
module.alb.aws_security_group.alb: Creation complete after 2s
module.alb.aws_lb.web: Creating...
module.alb.aws_lb_target_group.web: Creating...
module.ec2.aws_launch_template.web: Creation complete after 1s
module.alb.aws_lb_target_group.web: Creation complete after 1s
module.alb.aws_lb.web: Still creating... [10s elapsed]
module.alb.aws_lb.web: Creation complete after 23s
module.alb.aws_lb_listener.http: Creating...
module.alb.aws_lb_listener.http: Creation complete after 1s
module.asg.aws_autoscaling_group.web: Creating...
module.asg.aws_autoscaling_group.web: Still creating... [10s elapsed]
module.asg.aws_autoscaling_group.web: Creation complete after 18s
module.asg.aws_autoscaling_policy.scale_out: Creating...
module.asg.aws_autoscaling_policy.scale_in: Creating...
module.asg.aws_cloudwatch_metric_alarm.cpu_high: Creating...
module.asg.aws_cloudwatch_metric_alarm.cpu_low: Creating...
module.asg.aws_cloudwatch_dashboard.web: Creating...
module.alb.aws_cloudwatch_metric_alarm.high_request_count: Creating...


Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

alb_dns_name                = "web-challenge-day26-alb-dev-123456789.us-east-1.elb.amazonaws.com"
asg_name                    = "web-asg-dev"
asg_arn                     = "arn:aws:autoscaling:us-east-1:123456789012:autoScalingGroup:..."
launch_template_id           = "lt-0abc123def456789"
launch_template_version      = "1"
scale_out_policy_arn         = "arn:aws:autoscaling:us-east-1:123456789012:scalingPolicy:..."
scale_in_policy_arn          = "arn:aws:autoscaling:us-east-1:123456789012:scalingPolicy:..."
cloudwatch_dashboard_name    = "web-asg-dev"




## Live Application Verification

Open the ALB DNS name in your browser:

http://web-challenge-day26-alb-dev-123456789.us-east-1.elb.amazonaws.com
```

You will see:

Deployed with Terraform — environment: dev


**AWS Console verification steps:**
1. Go to **EC2 → Auto Scaling Groups → web-asg-dev**
2. **Instance management** tab → confirm 2 instances show **Healthy / InService**
3. **Activity** tab → shows the two launch events
4. Go to **EC2 → Load Balancers → web-challenge-day26-alb-dev**
5. **Target groups → web-challenge-day26-tg-dev** → both targets show **healthy**



## How the Three Modules Collaborate


┌─────────────────────────────────────────────────────────────┐
│                    envs/dev/main.tf                         │
│                                                             │
│  module "ec2"  ──── launch_template_id ──────────────────┐  │
│                     launch_template_version               │  │
│                                                           ▼  │
│  module "alb"  ──── target_group_arn  ──────────────► module "asg" │
│                                                             │
│  ASG registers instances → ALB target group                 │
│  ALB health checks → ELB health check type in ASG           │
│  CloudWatch CPU alarm → autoscaling policy → ASG action     │
└─────────────────────────────────────────────────────────────┘


**`target_group_arns` is the critical connection.** Without it, the ASG launches instances but the ALB knows nothing about them — no traffic is ever routed. With it, ASG automatically registers every new instance to the ALB target group and deregisters instances being terminated.

**What breaks without `health_check_type = "ELB"`:** The ASG falls back to EC2 health checks. A crashed web server keeps its instance alive. Your users get errors; the ASG sees no problem and never replaces the bad instance. You would be operating blind.



## Bonus — CloudWatch Dashboard

The `aws_cloudwatch_dashboard.web` resource in `modules/asg/main.tf` creates a dashboard at:
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=web-asg-dev
```

It shows two widgets side by side:
- **CPU Utilization** — average CPU across all instances in the ASG, with the 70 % scale-out line visible
- **ASG Instance Count** — `GroupInServiceInstances` metric, showing when the ASG added or removed instances

The `aws_cloudwatch_metric_alarm.high_request_count` alarm in `modules/alb/main.tf` fires when `RequestCountPerTarget` exceeds 1,000 req/min. It does not trigger an autoscaling action by default (no `alarm_actions` set) — it serves as a visibility alarm. You can wire it to a scale-out policy for traffic-based scaling in addition to CPU-based scaling.



## Cleanup


terraform destroy


**Expected output (abridged):**

module.asg.aws_cloudwatch_dashboard.web: Destroying...
module.asg.aws_cloudwatch_metric_alarm.cpu_high: Destroying...
module.asg.aws_cloudwatch_metric_alarm.cpu_low: Destroying...
module.alb.aws_cloudwatch_metric_alarm.high_request_count: Destroying...
module.asg.aws_autoscaling_policy.scale_out: Destroying...
module.asg.aws_autoscaling_policy.scale_in: Destroying...
module.asg.aws_autoscaling_group.web: Destroying...
module.asg.aws_autoscaling_group.web: Still destroying... [30s elapsed]
module.asg.aws_autoscaling_group.web: Destruction complete after 45s
module.alb.aws_lb_listener.http: Destroying...
module.alb.aws_lb.web: Destroying...
module.alb.aws_lb_target_group.web: Destroying...
module.ec2.aws_launch_template.web: Destroying...
module.alb.aws_lb.web: Still destroying... [10s elapsed]
module.alb.aws_lb.web: Destruction complete after 12s
module.ec2.aws_security_group.instance: Destroying...
module.alb.aws_security_group.alb: Destroying...


Destroy complete! Resources: 14 destroyed.

> `force_delete = true` on the ASG (set automatically when `environment != "production"`) ensures the ASG does not wait for connection draining, making `destroy` complete in ~60 s instead of several minutes.


## Key Takeaways

1. **Module boundaries should follow change frequency.** EC2 launch config changes more often than load balancer config — keep them separate.
2. **`health_check_type = "ELB"` is non-negotiable** for a web tier. EC2 health checks will mislead you in production.
3. **Never hardcode.** Every value flows through variables, defaults are set only where genuinely safe.
4. **`lifecycle { create_before_destroy = true }`** on both the launch template and ASG prevents downtime during updates.
5. **CloudWatch alarms are not optional.** Scaling without observability is flying blind — create the dashboard as part of the same apply.



## Social Media Post

🚀 Day 26 of the 30-Day Terraform Challenge — deployed a fully modular, auto-scaling web application on AWS using EC2 Launch Templates, an Application Load Balancer, and an Auto Scaling Group. CloudWatch alarms trigger scale-out at 70% CPU and scale-in at 30%. Three Terraform modules, remote state, DRY configuration. #30DayTerraformChallenge #TerraformChallenge #Terraform #AWS #AutoScaling #IaC #AWSUserGroupKenya #EveOps
