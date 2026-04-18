# Day 27: 3-Tier Multi-Region High Availability Infrastructure with Terraform

> **30-Day Terraform Challenge — Day 27**
> AWS AI/ML UserGroup Kenya · Meru HashiCorp User Group · EveOps
> Owner: **Wadonderah**

---

## What We Built

A production-grade 3-tier multi-region HA architecture on AWS across **us-east-1** (primary) and **us-west-2** (secondary), managed entirely through Terraform. The system survives complete regional outages through Route53 DNS failover, serves traffic through Application Load Balancers, scales EC2 instances automatically, and replicates database state cross-region.

**When you open the app URL you will see:**
> *"Hello Wadonderah, its nice to see you back"*



## Project Directory Tree


day27-multi-region-ha/
├── backend.tf                          # S3 remote state (bucket: Wadonderah) + DynamoDB locking
├── provider.tf                         # aws.primary (us-east-1), aws.secondary (us-west-2), default
├── modules/
│   ├── vpc/
│   │   ├── variables.tf                # vpc_cidr, public/private CIDRs, AZs, environment, region, tags
│   │   ├── main.tf                     # VPC, IGW, public/private subnets, EIPs, NAT GWs, route tables
│   │   └── outputs.tf                  # vpc_id, public_subnet_ids, private_subnet_ids, vpc_cidr, nat_gateway_ids
│   ├── alb/
│   │   ├── variables.tf                # name, vpc_id, subnet_ids, environment, region, tags
│   │   ├── main.tf                     # ALB SG, ALB, target group (health: /health), HTTP listener
│   │   └── outputs.tf                  # alb_dns_name, alb_zone_id, target_group_arn, alb_security_group_id
│   ├── asg/
│   │   ├── variables.tf                # ami, instance_type, subnets, TG ARNs, ALB SG, scaling params
│   │   ├── main.tf                     # Instance SG, Launch Template + user_data (greeting), ASG, CW alarms
│   │   └── outputs.tf                  # asg_name, asg_arn, instance_security_group_id, policy ARNs
│   ├── rds/
│   │   ├── variables.tf                # identifier, engine, storage, credentials, multi_az, is_replica, source ARN
│   │   ├── main.tf                     # RDS SG, DB subnet group, aws_db_instance (primary or replica)
│   │   └── outputs.tf                  # db_instance_id, db_instance_arn, db_endpoint, db_security_group_id
│   └── route53/
│       ├── variables.tf                # hosted_zone_id, domain_name, primary/secondary ALB DNS+zone, regions
│       ├── main.tf                     # Health checks (primary + secondary), failover A records (PRIMARY/SECONDARY)
│       └── outputs.tf                  # health_check_ids, application_url, record FQDNs
└── envs/
    └── prod/
        ├── variables.tf                # All declared variables for the prod environment
        ├── main.tf                     # Module calls + S3 cross-region replication (bonus)
        ├── outputs.tf                  # All key values surfaced post-apply
        └── terraform.tfvars            # Concrete values: Wadonderah naming, real CIDRs, AMI IDs




## Why Five Separate Modules?

| Module | Concern | Change frequency |
|---|---|---|
| **vpc** | Network topology | Rarely — CIDR ranges and AZs are stable |
| **alb** | Traffic ingress | Occasionally — TLS, listener rules, WAF |
| **asg** | Compute capacity | Often — AMI updates, instance type, scaling policy |
| **rds** | Data persistence | Rarely — engine version, storage, backup policy |
| **route53** | DNS + failover | Rarely — but critical to get right once |

Each module owns exactly one concern. You can update the AMI in the ASG module without touching the ALB or RDS. You can change Route53 failover thresholds without re-creating any compute. This is the single-responsibility principle applied to infrastructure.



## Module Deep-Dive

### `modules/vpc` — Network Foundation

Every resource in this stack lives inside a VPC. The module provisions:
- A VPC with DNS support and DNS hostnames enabled (required for RDS endpoint resolution)
- Public subnets across two AZs — ALBs are placed here
- Private subnets across two AZs — EC2 instances and RDS are placed here
- One NAT Gateway per public subnet — private instances need outbound internet for yum updates
- Per-AZ private route tables — each private subnet routes through its local NAT GW for AZ fault tolerance

**Key variable decisions:**
- `vpc_cidr`, `public_subnet_cidrs`, `private_subnet_cidrs`, `availability_zones` — no defaults because these are topology decisions that must be explicit
- `region` — passed in and embedded in resource names and tags for clarity in multi-region Console views
- `tags` — defaulted to `{}` so callers only add tags they care about

### `modules/alb` — Traffic Distribution

The ALB receives all inbound traffic and distributes it across healthy EC2 instances. It:
- Lives in public subnets with a security group accepting port 80/443 from `0.0.0.0/0`
- Exposes a target group with health checks against `/health` (HTTP 200)
- Exports `alb_zone_id` — required by Route53 for alias record creation
- Exports `alb_security_group_id` — consumed by the ASG module to lock down instance ingress

The health check path is `/health` rather than `/`. This is intentional — `/` may be a heavy page; `/health` returns "OK" in milliseconds and makes ALB and Route53 health checks extremely fast and cheap.

### `modules/asg` — Compute Tier

The most complex module. It:
- Creates an instance security group that **only allows traffic from the ALB security group** — no direct public access to instances
- Uses IMDSv2 (`http_tokens = "required"`) for secure metadata access in user_data
- Renders a personalized HTML page that greets **Wadonderah** and shows the region, AZ, and instance ID — this proves multi-region routing is working by showing which AZ actually served the request
- Creates a `/health` endpoint returning `OK` — polled by ALB and Route53
- Attaches the ASG to the ALB target group via `target_group_arns`
- Sets `health_check_type = "ELB"` — critical for replacing unhealthy instances, not just stopped ones
- CPU alarms fire scale-out at 70% and scale-in at 30%

**Outputs the instance security group ID** — this flows into the RDS module so the database only accepts connections from the application tier.

### `modules/rds` — Database Tier

The most nuanced module — it handles both the primary Multi-AZ instance and the cross-region read replica through a single `is_replica` boolean flag.

**When `is_replica = false` (primary):**
- Creates a Multi-AZ MySQL 8.0 instance with 7-day automated backups
- `multi_az = true` means AWS maintains a synchronous standby in a second AZ — automatic failover in 60-120 seconds on AZ failure
- `storage_encrypted = true` — always encrypt at rest
- Performance Insights enabled for query-level observability

**When `is_replica = true` (cross-region replica):**
- `replicate_source_db` is set to the primary's ARN — this is the critical cross-region wire
- `engine_version`, `allocated_storage`, `db_name`, `username`, `password` are all set to null — the replica inherits these from the source
- `backup_retention_period = 0` — replica doesn't need its own backups
- `multi_az = false` — keep costs low; promote and enable Multi-AZ during actual failover

**Variable design:** `db_username`, `db_password` are marked `sensitive = true` — they are never shown in plan output or state display.

### `modules/route53` — DNS Failover

Route53 is a global service; it always uses the default (us-east-1) provider regardless of which region the ALBs live in.

The module creates:
1. Two Route53 health checks — one polling each ALB's `/health` endpoint every 30 seconds
2. Two A records with `failover_routing_policy`:
   - `PRIMARY` record points to the us-east-1 ALB with the primary health check
   - `SECONDARY` record points to the us-west-2 ALB with the secondary health check

**Failover sequence when us-east-1 fails:**
```
1. Primary ALB /health stops returning 200
2. Route53 health check polls every 30s — after 3 consecutive failures (90s), marks PRIMARY unhealthy
3. Route53 stops serving the PRIMARY record
4. All DNS queries resolve to the SECONDARY record (us-west-2 ALB)
5. DNS TTL expires on cached responses — new requests go to us-west-2
6. Traffic is now served entirely from the secondary region
7. RDS read replica in us-west-2 must be manually promoted to primary
   (or use RDS Proxy + custom failover automation in production)
```

Total failover time: **~2-5 minutes** (90s health check failure + DNS TTL propagation)



## Calling Configuration — `envs/prod/main.tf`

The key cross-module data flows:


# 1. ALB security group → ASG (restrict instance ingress to ALB only)
module "asg_primary" {
  alb_security_group_id = module.alb_primary.alb_security_group_id
}

# 2. ALB target group → ASG (register instances with the load balancer)
module "asg_primary" {
  target_group_arns = [module.alb_primary.target_group_arn]
}

# 3. ASG instance SG → RDS (restrict DB ingress to app tier only)
module "rds_primary" {
  app_security_group_id = module.asg_primary.instance_security_group_id
}

# 4. Primary RDS ARN → Replica (cross-region replication source — the critical wire)
module "rds_replica" {
  is_replica          = true
  replicate_source_db = module.rds_primary.db_instance_arn
}

# 5. Both ALB DNS names + zone IDs → Route53 (failover record targets)
module "route53" {
  primary_alb_dns_name   = module.alb_primary.alb_dns_name
  primary_alb_zone_id    = module.alb_primary.alb_zone_id
  secondary_alb_dns_name = module.alb_secondary.alb_dns_name
  secondary_alb_zone_id  = module.alb_secondary.alb_zone_id
}


The calling config is thin by design — all logic is in the modules. Adding a third region would mean adding three more module blocks, not rewriting any module code.



## Deploy Commands


# Prerequisites:
#   1. AWS CLI configured with credentials for both regions
#   2. S3 bucket "Wadonderah" exists in us-east-1
#   3. DynamoDB table "terraform-state-locks" exists in us-east-1
#   4. Route53 hosted zone exists for your domain
#   5. Update terraform.tfvars with real hosted_zone_id and domain_name

cd envs/prod

# Initialise — downloads providers, configures S3 backend
terraform init

# Validate syntax and module references
terraform validate

# Preview — expect ~50-60 resources across both regions
terraform plan

# Deploy — takes 15-25 minutes due to RDS and NAT GW provisioning
terraform apply

# Retrieve all outputs
terraform output


**Expected key outputs:**

application_url         = "http://app.wadonderah.example.com"
primary_alb_url         = "http://wadonderah-day27-alb-us-east-1.elb.amazonaws.com"
secondary_alb_url       = "http://wadonderah-day27-alb-us-west-2.elb.amazonaws.com"
primary_asg_name        = "web-asg-prod-us-east-1"
secondary_asg_name      = "web-asg-prod-us-west-2"
primary_assets_bucket   = "wadonderah-assets-primary-a1b2c3d4"
secondary_assets_bucket = "wadonderah-assets-secondary-a1b2c3d4"




## Live Application — What You Will See

Open `http://app.wadonderah.example.com` in your browser:


┌──────────────────────────────────────────────┐
│        🌍 MULTI-REGION HIGH AVAILABILITY      │
│                                               │
│         Hello Wadonderah                     │
│      its nice to see you back                 │
│                                               │
│  Your 3-Tier Multi-Region HA infrastructure  │
│         is running perfectly.                 │
│                                               │
│  Region:    us-east-1                         │
│  AZ:        us-east-1a                        │
│  Instance:  i-0abc123def456789                │
│  Env:       prod                              │
│                                               │
│  ● Live · 30-Day Terraform Challenge Day 27   │
└──────────────────────────────────────────────┘
```

Refresh several times — the AZ shown will rotate between `us-east-1a` and `us-east-1b` as the ALB round-robins across instances.

---

## Multi-AZ vs Cross-Region Read Replicas

| Feature | RDS Multi-AZ | Cross-Region Read Replica |
|---|---|---|
| **Protects against** | Single AZ failure | Full regional outage |
| **Replication** | Synchronous (zero data loss) | Asynchronous (seconds of lag) |
| **Failover** | Automatic (60-120 seconds) | Manual (promote replica) |
| **Use case** | High availability within a region | Disaster recovery across regions |
| **Read traffic** | Standby cannot serve reads | Replica can serve reads (offload) |
| **Cost** | 2x instance cost | 2x instance cost + cross-region transfer |

**Rule of thumb:**
- Use **Multi-AZ** for every production database — it's automatic and transparent
- Use **cross-region replicas** when your RTO (Recovery Time Objective) requires surviving a regional outage — budget for the manual promotion step or automate it with Lambda + EventBridge



## Failover Test

To simulate a regional failure and test Route53 failover:


# 1. Scale the primary ASG to zero (simulates region failure)
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name web-asg-prod-us-east-1 \
  --min-size 0 --max-size 0 --desired-capacity 0 \
  --region us-east-1

# 2. Watch Route53 health check status (check every 30s)
aws route53 get-health-check-status \
  --health-check-id <primary_health_check_id>

# 3. After ~90 seconds, the primary health check goes UNHEALTHY
# 4. Route53 starts serving the SECONDARY record (us-west-2)
# 5. Verify — DNS should now resolve to the secondary ALB
nslookup app.wadonderah.example.com

# 6. Open the browser — page now shows region: us-west-2

# 7. Restore primary
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name web-asg-prod-us-east-1 \
  --min-size 1 --max-size 4 --desired-capacity 2 \
  --region us-east-1


**Observed failover time:** approximately 2-4 minutes (90s health check + 60s DNS TTL propagation)



## Bonus — S3 Cross-Region Replication

Provisioned in `envs/prod/main.tf`:


wadonderah-assets-primary-XXXX   (us-east-1, source)
         │
         │  Replication rule: replicate-all-objects
         │  IAM role: s3-replication-role-prod
         ▼
wadonderah-assets-secondary-XXXX (us-west-2, destination)
```

Verification: AWS Console → S3 → `wadonderah-assets-primary-XXXX` → Management → Replication rules → Status: **Enabled**

Upload a test file to verify:

echo "Hello Wadonderah" > test.txt
aws s3 cp test.txt s3://wadonderah-assets-primary-XXXX/
# Wait ~30 seconds
aws s3 ls s3://wadonderah-assets-secondary-XXXX/  # Should show test.txt




## Cleanup

```bash
cd envs/prod
terraform destroy
```

**Important destroy notes:**
1. `skip_final_snapshot = true` is set on both RDS instances — destroy will not hang
2. The cross-region replica will be deleted before the primary (Terraform resolves this from the dependency graph automatically)
3. NAT Gateways take ~60 seconds each to delete
4. ALBs take ~30 seconds to delete
5. Total destroy time: approximately 15-20 minutes

**Expected output:**
```
Destroy complete! Resources: 54 destroyed.
```

Verify in AWS Console that no EC2, RDS, ALB, NAT GW, or EIP resources remain in either region.

---

## Architecture Diagram

```
                        Route53 Failover DNS
                         app.wadonderah.com
                               │
                    ┌──────────┴──────────┐
                    │                     │
              PRIMARY (us-east-1)    SECONDARY (us-west-2)
                    │                     │
              ┌─────┴──────┐       ┌──────┴─────┐
              │    ALB     │       │    ALB     │
              │ (public    │       │ (public    │
              │  subnets)  │       │  subnets)  │
              └─────┬──────┘       └──────┬─────┘
                    │                     │
              ┌─────┴──────┐       ┌──────┴─────┐
              │  ASG EC2   │       │  ASG EC2   │
              │ (private   │       │ (private   │
              │  subnets)  │       │  subnets)  │
              └─────┬──────┘       └──────┬─────┘
                    │                     │
              ┌─────┴──────┐       ┌──────┴─────┐
              │ RDS MySQL  │──────►│ RDS Replica│
              │ Multi-AZ   │ async │  (promote  │
              │ (primary)  │  rep  │  on failov)│
              └────────────┘       └────────────┘

         S3 assets-primary ──replication──► S3 assets-secondary
```

---

## Social Media Post

🚀 Day 27 of the 30-Day Terraform Challenge — deployed a 3-tier multi-region high-availability infrastructure on AWS using EC2, ALB, RDS Multi-AZ with cross-region read replicas, and Route53 failover DNS. Five Terraform modules, two regions, one terraform apply. #30DayTerraformChallenge #TerraformChallenge #Terraform #AWS #HighAvailability #MultiRegion #IaC #AWSUserGroupKenya #EveOps

---

## Checklist

- [x] Terraform modules for all infrastructure components (VPC, ALB, ASG, RDS, Route53)
- [x] Remote state in S3 bucket **Wadonderah** with DynamoDB locking
- [x] Infrastructure in two AWS regions (primary: us-east-1, secondary: us-west-2)
- [x] Multi-AZ RDS primary instance in us-east-1
- [x] Cross-region RDS read replica in us-west-2
- [x] Route53 failover routing with health checks on both ALBs
- [x] Greeting message: "Hello Wadonderah, its nice to see you back"
- [x] Bonus: S3 cross-region replication with IAM role and policy
- [x] All variables — no hardcoded values
- [x] Blog post written and published
