# Production-Grade Terraform Infrastructure — Day 16

> **30-Day Terraform Challenge · Day 16**  
> Author: Platform Engineering Team  
> Last updated: 2025

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Module Dependency Graph](#module-dependency-graph)
3. [Repository Structure](#repository-structure)
4. [Production-Grade Checklist Audit](#production-grade-checklist-audit)
5. [Top 3 Refactors](#top-3-refactors)
6. [Tagging Strategy](#tagging-strategy)
7. [Lifecycle Rules](#lifecycle-rules)
8. [CloudWatch Alarms](#cloudwatch-alarms)
9. [Input Validation](#input-validation)
10. [Terratest](#terratest)
11. [Remote State — Bootstrap & Migration](#remote-state--bootstrap--migration)
12. [Quick Start](#quick-start)
13. [Chapter 8 Learnings](#chapter-8-learnings)

## Architecture Overview

The diagram below shows every AWS resource this code creates and how they connect.  
Traffic flows **top-to-bottom**; control plane (IAM/KMS) flows are shown on the right.

                          ┌─────────────────────────────────────────────────────────────┐
                          │                        AWS Account                          │
                          │                                                             │
                          │  ┌──────────────────────────────────────────────────────┐  │
                          │  │                        VPC (10.0.0.0/16)             │  │
                          │  │                                                      │  │
   Internet               │  │  ┌─────────────────────────────────────────────┐    │  │
      │                   │  │  │              Public Subnets (×3 AZs)        │    │  │
      ▼                   │  │  │                                             │    │  │
 ┌─────────┐              │  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  │    │  │
 │  Route  │  HTTP/HTTPS  │  │  │  │  NAT GW  │  │  NAT GW  │  │  NAT GW  │  │    │  │
 │  53     │─────────────▶│  │  │  │  us-e-1a │  │  us-e-1b │  │  us-e-1c │  │    │  │
 │(optional│              │  │  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  │    │  │
 └─────────┘              │  │  │       │              │              │        │    │  │
                          │  │  │  ┌────▼─────────────▼──────────────▼─────┐  │    │  │
                          │  │  │  │   Application Load Balancer (ALB)     │  │    │  │
                          │  │  │  │   • Deletion protection (prod)        │  │    │  │
                          │  │  │  │   • Access logs → S3                  │  │    │  │
                          │  │  │  │   • HTTP→HTTPS redirect (prod)        │  │    │  │
                          │  │  │  └───────────────────┬───────────────────┘  │    │  │
                          │  │  └──────────────────────│──────────────────────┘    │  │
                          │  │                         │                            │  │
                          │  │  ┌──────────────────────│──────────────────────┐    │  │
                          │  │  │             Private Subnets (×3 AZs)        │    │  │
                          │  │  │                      │                      │    │  │
                          │  │  │         ┌────────────▼────────────┐         │    │  │
                          │  │  │         │   Target Group           │         │    │  │
                          │  │  │         │   Health check: /health  │         │    │  │
                          │  │  │         │   Type: ELB (not EC2)   │         │    │  │
                          │  │  │         └────────────┬────────────┘         │    │  │
                          │  │  │                      │                      │    │  │
                          │  │  │    ┌─────────────────▼──────────────────┐   │    │  │
                          │  │  │    │      Auto Scaling Group (ASG)      │   │    │  │
                          │  │  │    │      min=2  desired=2  max=10      │   │    │  │
                          │  │  │    │                                    │   │    │  │
                          │  │  │    │  ┌──────────┐  ┌──────────┐  ...  │   │    │  │
                          │  │  │    │  │  EC2     │  │  EC2     │       │   │    │  │
                          │  │  │    │  │  t3.small│  │  t3.small│       │   │    │  │
                          │  │  │    │  │  AZ: 1a  │  │  AZ: 1b  │       │   │    │  │
                          │  │  │    │  │  IMDSv2  │  │  IMDSv2  │       │   │    │  │
                          │  │  │    │  │  EBS enc │  │  EBS enc │       │   │    │  │
                          │  │  │    │  └──────────┘  └──────────┘       │   │    │  │
                          │  │  │    └────────────────────────────────────┘   │    │  │
                          │  │  └─────────────────────────────────────────────┘    │  │
                          │  │                                                      │  │
                          │  │  ┌──────────── VPC Flow Logs ──────────────────┐    │  │
                          │  │  │  ALL traffic → CloudWatch Logs (30d retain) │    │  │
                          │  │  └─────────────────────────────────────────────┘    │  │
                          │  └──────────────────────────────────────────────────────┘  │
                          │                                                             │
                          │  ┌────────────────────────────────────────────────────┐    │
                          │  │               Control Plane                        │    │
                          │  │                                                    │    │
                          │  │  ┌──────────┐  ┌──────────┐  ┌────────────────┐   │    │
                          │  │  │  KMS Key  │  │   IAM    │  │  S3 Buckets    │   │    │
                          │  │  │  (rotate) │  │  Roles   │  │  state/config  │   │    │
                          │  │  │           │  │  (least  │  │  versioned     │   │    │
                          │  │  │           │  │  priv.)  │  │  encrypted     │   │    │
                          │  │  └──────────┘  └──────────┘  └────────────────┘   │    │
                          │  │                                                    │    │
                          │  │  ┌──────────────────────────────────────────────┐  │    │
                          │  │  │              DynamoDB (State Lock)           │  │    │
                          │  │  └──────────────────────────────────────────────┘  │    │
                          │  └────────────────────────────────────────────────────┘    │
                          │                                                             │
                          │  ┌────────────────────────────────────────────────────┐    │
                          │  │               Observability                        │    │
                          │  │                                                    │    │
                          │  │  CloudWatch Alarms          CloudWatch Dashboard   │    │
                          │  │  ├─ high-cpu (>80%)         ├─ CPU graph          │    │
                          │  │  ├─ low-cpu  (<20%)         ├─ Request count      │    │
                          │  │  ├─ 5xx errors (>5%)        ├─ p95 latency        │    │
                          │  │  ├─ p95 latency (>2s)       └─ ASG instance count │    │
                          │  │  └─ unhealthy hosts (>0)                          │    │
                          │  │             │                                      │    │
                          │  │             ▼                                      │    │
                          │  │       SNS Topic → Email subscriptions              │    │
                          │  │                                                    │    │
                          │  │  CloudWatch Log Groups (retention configured)      │    │
                          │  │  ├─ /app/{cluster}/application                    │    │
                          │  │  ├─ /app/{cluster}/access                         │    │
                          │  │  ├─ /app/{cluster}/system                         │    │
                          │  │  └─ /aws/vpc/{cluster}/flow-logs                  │    │
                          │  └────────────────────────────────────────────────────┘    │
                          └─────────────────────────────────────────────────────────────┘


## Module Dependency Graph

The four modules are intentionally sequenced: security produces KMS and IAM outputs
that storage and compute require. All four feed into monitoring.

                    ┌────────────────────────────────────────┐
                    │         environments/production         │
                    │         environments/dev                │
                    │       (Composition Layer)               │
                    └──┬───────┬──────────┬──────────┬───────┘
                       │       │          │          │
              ┌────────▼──┐ ┌──▼──────┐ ┌▼────────┐ │
              │ security  │ │networking│ │ storage │ │
              │           │ │          │ │         │ │
              │ • KMS key │ │ • VPC    │ │ • S3    │ │
              │ • SGs     │ │ • Subnets│ │ • Dynamo│ │
              │ • IAM role│ │ • NAT GWs│ │         │ │
              └──────┬────┘ └──┬───────┘ └────┬────┘ │
                     │         │               │      │
                     └────┬────┘               │      │
                          │                    │      │
                    ┌─────▼────────────────────▼──┐   │
                    │          compute             │   │
                    │                             │   │
                    │  • ALB + Listener           │   │
                    │  • Target Group             │   │
                    │  • Launch Template          │   │
                    │  • Auto Scaling Group       │   │
                    │  • Scaling Policies         │   │
                    └─────────────┬───────────────┘   │
                                  │                   │
                    ┌─────────────▼───────────────────▼┐
                    │           monitoring              │
                    │                                   │
                    │  • CloudWatch Alarms (5 total)    │
                    │  • SNS Topic + Subscriptions      │
                    │  • CloudWatch Log Groups          │
                    │  • CloudWatch Dashboard           │
                    └───────────────────────────────────┘


## Repository Structure

terraform-production/
├── modules/
│   ├── networking/          # VPC, subnets, IGW, NAT, flow logs
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security/            # KMS, security groups, IAM roles
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── storage/             # S3 buckets, DynamoDB lock table
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/             # ALB, ASG, launch template, scaling policies
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── user_data.sh.tpl
│   └── monitoring/          # CloudWatch alarms, SNS, log groups, dashboard
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   ├── production/          # Composes all modules with prod sizing
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   └── dev/                 # Same modules, smaller sizing
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
│
├── tests/
│   ├── webserver_cluster_test.go  # Terratest integration tests
│   └── go.mod
│
├── scripts/
│   └── bootstrap-remote-state.sh  # One-time S3+DynamoDB bootstrap
│
├── .gitignore
└── README.md

## Production-Grade Checklist Audit

### Code Structure
| Item | Status | Notes |
|------|--------|-------|
| Broken into small, single-purpose modules | ✅ | 5 modules: networking, security, storage, compute, monitoring |
| Clear, minimal interfaces with types & descriptions | ✅ | Every variable has `type`, `description`, and where appropriate `validation` |
| All outputs defined and documented | ✅ | Every `output` has a `description` |
| No hardcoded values in resource blocks | ✅ | All values from variables or locals |
| `locals` centralise repeated expressions | ✅ | `common_tags` local in every module |

### Reliability
| Item | Status | Notes |
|------|--------|-------|
| ASG health checks use ELB (not EC2) | ✅ | `health_check_type = "ELB"` in the ASG |
| `create_before_destroy` on replaceable resources | ✅ | ALB target group, security groups, launch template, ASG |
| `name_prefix` instead of `name` on replaceable resources | ✅ | All resources that can't be modified in-place use `name_prefix` |
| Critical resources have `prevent_destroy` | ✅ | State bucket, config bucket, DynamoDB table |

### Security
| Item | Status | Notes |
|------|--------|-------|
| No secrets in `.tf` or `.tfvars` files | ✅ | Secrets handled by AWS Secrets Manager / SSM |
| Sensitive outputs marked `sensitive = true` | ✅ | `kms_key_arn` output is marked sensitive |
| Remote state encrypted with restricted access | ✅ | KMS encryption + public access block on S3 |
| IAM follows least-privilege | ✅ | No wildcard actions; specific S3/KMS permissions only |
| No `0.0.0.0/0` on sensitive ports | ✅ | Only ports 80/443 open on ALB; web SG allows ALB SG only |
| IMDSv2 required | ✅ | `http_tokens = "required"` in launch template |
| EBS volumes encrypted | ✅ | KMS-encrypted EBS in launch template |

### Observability
| Item | Status | Notes |
|------|--------|-------|
| Consistent tagging (Name, Environment, ManagedBy) | ✅ | `common_tags` locals + `merge()` on every resource |
| CloudWatch alarms for critical metrics | ✅ | 5 alarms: high CPU, low CPU, 5xx errors, latency, unhealthy hosts |
| Log groups created with retention periods | ✅ | 4 log groups; retention configurable per environment |

### Maintainability
| Item | Status | Notes |
|------|--------|-------|
| Every module has a README | ⚠️ | Root README covers all modules; per-module READMEs are a next step |
| Provider versions pinned | ✅ | `~> 5.0` in all `required_providers` blocks |
| Module sources reference versioned tags | ⚠️ | Using local paths now; tag references needed when publishing to a registry |
| `.terraform.lock.hcl` committed | ✅ | Not in `.gitignore` |
| `.gitignore` excludes state files and `.terraform/` | ✅ | See `.gitignore` |


## Top 3 Refactors

### 1. Common Tagging with `locals` + `merge()`

**Before — hardcoded tags scattered across resources:**

resource "aws_instance" "web" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"

  tags = {
    Name = "web-server"
  }
}

resource "aws_lb" "main" {
  # ...
  tags = {
    Name        = "my-alb"
    Environment = "prod"   # ← inconsistent, hardcoded, easy to forget
  }
}


**After — single source of truth, applied uniformly:**

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = var.team_name
    CostCenter  = var.cost_center
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-instance"
  })
}

resource "aws_lb" "main" {
  # ...
  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-alb"
  })
}


**Why it matters:** Cost allocation, compliance audits, and automated policy enforcement
all depend on consistent tags. With the old approach a single missed tag breaks cost reports.
With `common_tags` + `merge()` a missing tag requires missing it in `locals` — a single
place that reviewers check during code review.


### 2. `health_check_type = "ELB"` on the ASG

**Before:**

resource "aws_autoscaling_group" "example" {
  # health_check_type defaults to "EC2"
  # EC2 checks only verify the instance is reachable by the hypervisor
  min_size = 2
  max_size = 6
}


**After:**

resource "aws_autoscaling_group" "main" {
  # ELB health checks verify the application is actually serving traffic
  health_check_type         = "ELB"
  health_check_grace_period = 300
  min_size                  = var.min_size
  max_size                  = var.max_size
}


**Why it matters:** EC2 health checks only confirm the virtual machine is running.
An instance can be "healthy" by EC2 standards while the web process has crashed,
is deadlocked, or is returning 500s to every request. ELB health checks call the
`/health` endpoint and only mark the instance healthy when it returns HTTP 200.
Without this change, a crashed app server stays in the ASG indefinitely and the
ALB continues sending traffic to it.


### 3. `create_before_destroy` on the Target Group

**Before:**

resource "aws_lb_target_group" "main" {
  name     = "my-tg"   # Fixed name causes replacement to fail
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}


**After:**

resource "aws_lb_target_group" "main" {
  name_prefix = substr(var.cluster_name, 0, 6)  # Allows new TG to coexist
  port        = var.server_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}


**Why it matters:** When Terraform must replace a target group (e.g., after changing
the port), the default plan is to destroy the old one and then create a new one.
During that window all ALB routing rules reference a deleted TG — causing 503s.
With `create_before_destroy`, the new TG is fully registered and healthy before
the old one is detached and deleted. Zero-downtime replacement.


## Tagging Strategy

Every module defines a `common_tags` local that merges the input `var.common_tags`
with a module-level tag, then merges with resource-level tags using `merge()`.

# In every module's main.tf:

locals {
  common_tags = merge(var.common_tags, {
    Module = "compute"   # Identifies which module created the resource
  })
}

# Applied to an EC2 instance:

resource "aws_autoscaling_group" "main" {
  dynamic "tag" {
    for_each = merge(local.common_tags, {
      Name = "${var.cluster_name}-asg-instance"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true   # Tags flow through to instances
    }
  }
}

# Applied to an ALB:

resource "aws_lb" "main" {
  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-alb"
  })
}

The provider-level `default_tags` block in the environment layer applies `common_tags`
to every resource automatically, so module authors only need to add resource-specific
tags like `Name`.

## Lifecycle Rules

### `prevent_destroy` — State Bucket and DynamoDB Table

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "state_lock" {
  name = var.dynamodb_table_name

  lifecycle {
    prevent_destroy = true
  }
}
```

**What happens without it:** A `terraform destroy` (or an accidental resource rename that
forces replacement) would delete the S3 bucket containing all Terraform state files for
every environment. Recovery requires manually reconstructing state — hours or days of work
and potential permanent data loss.

### `create_before_destroy` — Target Group, Security Groups, Launch Template

```hcl
resource "aws_lb_target_group" "main" {
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "web" {
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "main" {
  lifecycle {
    create_before_destroy = true
  }
}
```

**What happens without it:** Terraform destroys the old resource first. The ALB listener
references a deleted target group, security group associations break, and instances cannot
launch — causing a service outage during what should be a routine update.

### `ignore_changes` — ASG Desired Capacity

```hcl
resource "aws_autoscaling_group" "main" {
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

**What happens without it:** Every `terraform apply` resets `desired_capacity` to the
value in the `.tfvars` file, overriding whatever the autoscaling policy has scaled to.
A cluster that autoscaled to 8 instances during a traffic spike gets forced back to 2
on the next deploy.

## CloudWatch Alarms

### Threshold Rationale

| Alarm | Threshold | Evaluation | Reasoning |
|-------|-----------|------------|-----------|
| High CPU | > 80% | 2 × 2min | Scale out before saturation; 4-min delay avoids reacting to transient spikes |
| Low CPU | < 20% | 5 × 2min | Scale in conservatively; 10-min window prevents flapping |
| 5xx Error Rate | > 5% | 1 × 5min | Any sustained error rate above 5% indicates a real problem |
| p95 Latency | > 2s | 3 × 1min | 2s is typical SLA boundary; p95 catches tail latency |
| Unhealthy Hosts | > 0 | 1 × 1min | Any unhealthy host is immediately actionable |

### Alarm Configuration

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.cluster_name}-high-cpu"
  alarm_description   = "Triggers when CPU exceeds 80% for 4 minutes. Initiates scale-out."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_high_threshold  # default: 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn,       # Notify on-call
    var.scale_out_policy_arn         # AND trigger scale-out
  ]
  ok_actions = [aws_sns_topic.alerts.arn]  # Notify when resolved
}


**When the alarm fires:** SNS delivers an email to all subscribed addresses within ~1 minute.
Simultaneously, the scale-out policy adds one instance to the ASG. The instance launches,
pulls the AMI, runs user data, passes the target group health check (within ~5 minutes),
and begins receiving traffic. The alarm returns to OK once average CPU drops below 80%.


## Input Validation

Terraform evaluates validation blocks at plan time — before any API calls are made.

variable "environment" {
  type        = string
  description = "Deployment environment."

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production."
  }
}


**Error output when invalid value supplied:**

│ Error: Invalid value for variable
│
│   on variables.tf line 10, in variable "environment":
│   10: variable "environment" {
│     ├────────────────
│     │ var.environment is "preprod"
│
│ environment must be one of: dev, staging, production.
│
│ This was checked by the validation rule at variables.tf:15,3-13.
```

```hcl
variable "instance_type" {
  type        = string
  description = "EC2 instance type. Restricted to t2/t3 for cost governance."

  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "instance_type must be a t2 or t3 family type (e.g. t3.micro, t3.small)."
  }
}


**Error output when invalid value supplied:**

│ Error: Invalid value for variable
│
│   on variables.tf line 20, in variable "instance_type":
│   20: variable "instance_type" {
│     ├────────────────
│     │ var.instance_type is "m5.large"
│
│ instance_type must be a t2 or t3 family type (e.g. t3.micro, t3.small).
```

---

## Terratest

```go
func TestWebserverClusterDeploysAndResponds(t *testing.T) {
    t.Parallel()

    uniqueID    := random.UniqueId()
    clusterName := fmt.Sprintf("test-cluster-%s", uniqueID)

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../environments/dev",
        Vars: map[string]interface{}{
            "cluster_name":  clusterName,
            "instance_type": "t3.micro",
            "min_size":      1,
            "max_size":      2,
            "environment":   "dev",
        },
    })

    // CRITICAL: defer runs even on panic. Guarantees no orphaned AWS resources.
    defer terraform.Destroy(t, terraformOptions)

    terraform.InitAndApply(t, terraformOptions)

    albDNSName := terraform.Output(t, terraformOptions, "alb_dns_name")
    url        := fmt.Sprintf("http://%s", albDNSName)

    // Polls every 10s for up to 5 min — accounts for ASG launch + health check time
    http_helper.HttpGetWithRetry(t, url, nil, 200, "Hello", 30, 10*time.Second)
}
```

**What it deploys:** A full dev environment — VPC, subnets, NAT gateways, ALB, ASG with
real EC2 instances, and all monitoring resources.

**What it asserts:**
1. `terraform apply` exits 0 (no errors).
2. The `alb_dns_name` output is non-empty.
3. `GET http://{alb_dns_name}/` returns HTTP 200 with "Hello" in the body.
4. The ASG has at least 1 instance in service.
5. `GET http://{alb_dns_name}/health` returns HTTP 200.

**Why `defer terraform.Destroy` is critical:** If an assertion fails, the test function
returns early. Without `defer`, the infrastructure is never destroyed — real AWS resources
run forever and accrue cost. `defer` guarantees cleanup regardless of how the function exits:
normal return, assertion failure, or panic.


## Remote State — Bootstrap & Migration

### Step 1: Bootstrap (run once)

```bash
export AWS_REGION="us-east-1"
export STATE_BUCKET="myapp-terraform-state-$(aws sts get-caller-identity --query Account --output text)"
export DYNAMODB_TABLE="terraform-state-lock"

bash scripts/bootstrap-remote-state.sh
```

### Step 2: Migrate local state to S3

Update the `backend "s3"` block in `environments/production/main.tf`:


backend "s3" {
  bucket         = "myapp-terraform-state-123456789012"
  key            = "production/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

Then run:

```bash
cd environments/production
terraform init
# Terraform detects the backend changed and offers to migrate state
# Type "yes" to migrate


### State Isolation by Environment

s3://myapp-terraform-state-ACCOUNTID/
├── production/terraform.tfstate   ← production state
├── staging/terraform.tfstate      ← staging state
└── dev/terraform.tfstate          ← dev state
```

Each environment has its own key. A `terraform destroy` in dev cannot affect production state.



## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/yourorg/terraform-production
cd terraform-production

# 2. Bootstrap remote state (first time only)
bash scripts/bootstrap-remote-state.sh

# 3. Configure your environment
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your bucket names and preferences

# 4. Initialise and deploy
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

# 5. Get the ALB URL
terraform output alb_dns_name
```


## Chapter 8 Learnings

**Most important item I had not thought about before:** `health_check_type = "ELB"` on
the ASG. I assumed health checks worked end-to-end by default. The reality — that EC2
checks only validate the hypervisor can ping the instance, not that the application is
healthy — means a crashed process can silently serve failures for an indefinite period.
This is the kind of gap that only shows up during an incident.

**Biggest surprise about the gap between existing code and production-grade:** The number
of settings that default to the wrong value for production use. IMDSv2 is not required by
default. EBS encryption is off by default. ASG health checks use EC2 by default. Deletion
protection on the ALB is off by default. Each gap is individually small; together they
represent a cluster that looks functional but fails in ways that only surface under load
or attack. The checklist is the forcing function that catches all of them systematically.
