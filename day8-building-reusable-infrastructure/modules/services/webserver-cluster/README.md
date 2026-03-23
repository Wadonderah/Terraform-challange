# 🌐 webserver-cluster Module

> A reusable, production-ready web server cluster on AWS — Auto Scaling, Load Balanced, and IMDSv2 hardened.

---

## 📐 Architecture

```
                        Internet
                           │
                    ┌──────▼──────┐
                    │     ALB     │  ← HTTP :80
                    │  (public)   │
                    └──────┬──────┘
                           │  forwards to
              ┌────────────▼────────────┐
              │    Target Group :8080   │
              └────────────┬────────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
   │   EC2 (AZ1) │  │   EC2 (AZ2) │  │   EC2 (AZn) │
   │  Apache:8080│  │  Apache:8080│  │  Apache:8080│
   └─────────────┘  └─────────────┘  └─────────────┘
          └────────────────┬────────────────┘
                           │
                  Auto Scaling Group
                  (min / max / desired)

  Security:
  ┌─────────────────────────────────────────┐
  │  ALB SG  → allows :80 from 0.0.0.0/0   │
  │  EC2 SG  → allows :8080 from ALB SG    │  ← instances NOT directly reachable
  └─────────────────────────────────────────┘
```

---

## 🗂️ Files

```
webserver-cluster/
├── main.tf          # ALB, ASG, Launch Template, Security Groups
├── variables.tf     # All input variables with descriptions & defaults
├── outputs.tf       # ALB DNS, ARNs, SG IDs exposed to callers
├── user-data.sh     # Apache install + IMDSv2-aware instance metadata page
└── README.md        # You are here
```

---

## 🚀 Usage

```hcl
module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name = "webservers-dev"
  min_size     = 2
  max_size     = 4
}
```

---

## 📥 Inputs

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `cluster_name` | `string` | ✅ | — | Name prefix for all resources |
| `min_size` | `number` | ✅ | — | Minimum ASG instance count |
| `max_size` | `number` | ✅ | — | Maximum ASG instance count |
| `instance_type` | `string` | | `t2.micro` | EC2 instance type |
| `server_port` | `number` | | `8080` | Port the app listens on |
| `ami_id` | `string` | | Amazon Linux 2 (us-east-1) | AMI ID for EC2 instances |
| `health_check_path` | `string` | | `/` | ALB health check HTTP path |
| `health_check_grace_period` | `number` | | `300` | Seconds before first health check |
| `enable_autoscaling` | `bool` | | `true` | Enable CPU-based scaling policy |
| `custom_tags` | `map(string)` | | `{}` | Extra tags applied to all resources |

---

## 📤 Outputs

| Name | Description |
|------|-------------|
| `alb_dns_name` | DNS name to reach the cluster — use for Route53 CNAME |
| `alb_arn` | ALB ARN for WAF or additional listener attachment |
| `asg_name` | ASG name for external scaling policies or instance queries |
| `instance_security_group_id` | For adding extra inbound rules (e.g. bastion host) |
| `alb_security_group_id` | For whitelisting the ALB in downstream security groups |

---

## 🔒 Security Notes

- Instances are **only reachable from the ALB** — no direct internet access
- **IMDSv2 enforced** on all instances (`http_tokens = "required"`)
- `create_before_destroy` on Launch Template and ASG for **zero-downtime updates**
- Set `enable_autoscaling = false` in dev to keep the environment stable for testing
