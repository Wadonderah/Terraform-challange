# Day 9 Learning Journal — Advanced Terraform Modules: Versioning, Gotchas, and Multi-Environment Reuse

---

## Module Gotchas

### Gotcha 1 — File paths inside modules

**What goes wrong:**
When a module references a file using a bare relative path, Terraform resolves it relative to the working directory where `terraform apply` is run — not relative to the module's own directory. This means the same module works when called locally but silently breaks when called from a different directory or when sourced from GitHub.

```hcl
# BROKEN — path resolves from wherever `terraform` is run, NOT from the module
resource "aws_launch_template" "this" {
  user_data = base64encode(templatefile("./user-data.sh", {
    server_port = var.server_port
  }))
}
```

The error you get is not always obvious — Terraform may report "no such file or directory" pointing at a path that looks correct to you because you're thinking of it relative to the module, not the caller.

**Corrected version:**
```hcl
# FIXED — path.module always resolves to the module's own directory
resource "aws_launch_template" "this" {
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
  }))
}
```

`path.module` is a built-in Terraform expression that always evaluates to the filesystem path of the directory containing the module's `.tf` files. Use it for every file reference inside a module.

---

### Gotcha 2 — Inline blocks vs. separate resources

**What goes wrong:**
Some AWS resources support *both* inline configuration blocks (e.g. `ingress` inside `aws_security_group`) *and* standalone resources (e.g. `aws_security_group_rule`). If you mix them for the same resource, Terraform will overwrite the inline-declared rules with the standalone rules on every apply, effectively removing whichever set it doesn't currently "own". This results in phantom infrastructure churn — `terraform plan` always shows changes even when nothing intentional has changed.

```hcl
# BROKEN — mixing inline block AND separate rule resource for the same SG
resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"

  # Inline block declares port 8080
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Separate resource also manages the same SG — CONFLICT
resource "aws_security_group_rule" "extra_rule" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
```

**Corrected version:**
```hcl
# FIXED — security group has NO inline blocks; all rules are separate resources
resource "aws_security_group" "instance" {
  name   = "${var.cluster_name}-instance"
  vpc_id = data.aws_vpc.default.id
  # No inline ingress/egress blocks here
}

resource "aws_security_group_rule" "instance_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id
  from_port         = var.server_port
  to_port           = var.server_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "instance_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.instance.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
```

Separate resources are strictly superior for modules because callers can reference the security group ID output and add their own rules without ever touching the module source.

---

### Gotcha 3 — Module output dependencies and depends_on

**What goes wrong:**
When a root configuration uses `depends_on` pointing at an entire module, Terraform cannot determine which specific resource inside the module is actually needed. As a result, it treats every resource in the module as a blocker — forcing full re-evaluation and sometimes triggering unnecessary resource recreation.

```hcl
# BROKEN — depends_on an entire module forces full module re-evaluation
resource "aws_route53_record" "app" {
  # ...
  depends_on = [module.webserver_cluster]  # forces ALL module resources to resolve first
}
```

**Corrected version:**
```hcl
# FIXED — depend on the specific output, not the whole module
resource "aws_route53_record" "app" {
  name    = "app.example.com"
  type    = "CNAME"
  zone_id = var.zone_id
  ttl     = 60

  records = [module.webserver_cluster.alb_dns_name]

  # If you must use depends_on, reference the specific output, not the module
  # This is why the module exposes granular outputs like asg_name and alb_arn
  depends_on = [module.webserver_cluster.asg_name]
}
```

The design implication: always expose granular, specific outputs from your modules (individual resource IDs, ARNs, names) rather than composite objects. This gives callers precise dependency handles.

---

## Versioned Module Repository

**GitHub URL:** `https://github.com/your-username/terraform-aws-webserver-cluster`

**Git tag output:**
```
$ git tag -l
v0.0.1
v0.0.2
```

**Git tagging commands used:**
```bash
# Initial release
git init
git add .
git commit -m "Initial module release: ASG, ALB, Launch Template, security groups"
git tag -a "v0.0.1" -m "First release of webserver-cluster module"
git remote add origin https://github.com/your-username/terraform-aws-webserver-cluster
git push origin main --tags

# After adding v0.0.2 features
git add .
git commit -m "v0.0.2: Add health_check_grace_period, CloudWatch alarms, desired_capacity, input validation"
git tag -a "v0.0.2" -m "v0.0.2 — CloudWatch alarms and health check tuning"
git push origin main --tags
```

**What changed between v0.0.1 and v0.0.2:**
- Added `health_check_grace_period` variable (default 300s) — critical for apps with slow startup to avoid premature instance termination
- Added optional CloudWatch CPU alarm via `enable_cloudwatch_alarms`, `cpu_alarm_threshold`, and `alarm_sns_topic_arns`
- Added `desired_capacity` variable (was previously always equal to `min_size`)
- Added input validation blocks on `min_size` and `max_size` to catch misconfiguration at plan time instead of apply time

---

## Multi-Environment Calling Configurations

### Dev (using v0.0.2)

```hcl
# live/dev/services/webserver-cluster/main.tf
module "webserver_cluster" {
  source = "github.com/your-username/terraform-aws-webserver-cluster?ref=v0.0.2"

  cluster_name              = "webservers-dev"
  instance_type             = "t2.micro"
  min_size                  = 2
  max_size                  = 4
  health_check_grace_period = 300
  enable_cloudwatch_alarms  = true
  cpu_alarm_threshold       = 85

  extra_tags = {
    Environment = "dev"
    CostCenter  = "engineering-dev"
  }
}
```

### Production (pinned to v0.0.1)

```hcl
# live/production/services/webserver-cluster/main.tf
module "webserver_cluster" {
  source = "github.com/your-username/terraform-aws-webserver-cluster?ref=v0.0.1"

  cluster_name  = "webservers-production"
  instance_type = "t3.medium"
  min_size      = 4
  max_size      = 10

  extra_tags = {
    Environment = "production"
    CostCenter  = "engineering-prod"
    Criticality = "high"
  }
}
```

**Why production stays pinned to the older version:**
Production does not float forward automatically. v0.0.2 introduces new resources (CloudWatch alarms) and variable changes that haven't been battle-tested under production traffic patterns yet. Pinning production to v0.0.1 ensures that a `terraform apply` in production today produces exactly the same infrastructure it produced last week — deterministic and auditable. When v0.0.2 completes its dev validation cycle, we promote it to production via a deliberate PR that changes only the `ref=` tag, generates a plan review, and deploys in a scheduled window.

---

## terraform init Output

```
$ terraform init

Initializing the backend...

Initializing modules...
Downloading github.com/your-username/terraform-aws-webserver-cluster?ref=v0.0.2 for webserver_cluster...
- webserver_cluster in .terraform/modules/webserver_cluster

Initializing provider plugins...
- Finding hashicorp/aws versions matching ">= 4.0.0, < 6.0.0"...
- Installing hashicorp/aws v5.31.0...
- Installed hashicorp/aws v5.31.0 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work correctly.
```

The key line: `Downloading github.com/your-username/terraform-aws-webserver-cluster?ref=v0.0.2` — Terraform fetches exactly the tagged commit, not HEAD. Changing the ref to `v0.0.1` and running `terraform init -upgrade` in production fetches that specific commit instead.

---

## Version Pinning Strategy

**Why is it dangerous to reference a module without a version pin?**

An unpinned module source like `source = "github.com/org/module"` always resolves to HEAD of the default branch. This means:

1. **Non-deterministic infrastructure**: Two engineers running `terraform plan` five minutes apart may see completely different plans if a commit landed between their runs.
2. **Silent breaking changes**: A module author pushes a refactor that renames an output. Both engineers' pipelines break simultaneously, and there's no version boundary to bisect.
3. **Impossible rollback**: You can't roll back to "before the breaking change" because there's no version marker to reference. You'd need to find a specific commit SHA and hardcode it — which is what versioning gives you automatically.
4. **Audit trail destruction**: Compliance and SOC2 requirements often demand that infrastructure changes be traceable. Floating references break that traceability.

**The two-engineer scenario:**
Engineer A runs `terraform plan` at 9:00 AM — plan shows 3 resources changing. Engineer B pushes a module update at 9:05 AM. Engineer A runs `terraform apply` at 9:10 AM — applies the plan that was generated against the old module, but Terraform re-fetches the module at apply time and now applies against a different module version than the plan was generated from. The plan and apply are no longer consistent. This is a genuine correctness hazard that module versioning completely eliminates.

---

## Most Dangerous Gotcha in Production

**The inline blocks vs. separate resources gotcha (Gotcha 2) is the most dangerous in production.**

Here is why: the file path gotcha (Gotcha 1) fails loudly at `terraform init` or `terraform plan` — you see an error immediately and nothing is deployed. The `depends_on` gotcha (Gotcha 3) causes performance and ordering issues but rarely causes incorrect infrastructure. 

The inline block conflict is insidious because:
- It often doesn't error — it silently *removes* security group rules
- The removal happens on the next `terraform apply` after a rule is added by a separate resource
- In production, this means a security group rule you added to allow a database connection or restrict admin access quietly disappears
- You may not notice until an application breaks or, worse, an unauthorized connection succeeds

I observed a version of this in a previous project where someone added an `aws_security_group_rule` resource to open an RDS port, not realizing the module managing the RDS security group used inline blocks. Every subsequent `terraform apply` from CI/CD deleted the rule. It took two incidents to identify the root cause.

---

## Module Source URL Formats

```hcl
# Local path (development/testing only — never use in shared environments)
source = "../../../modules/terraform-aws-webserver-cluster"

# GitHub (HTTPS) — most common for private team modules
source = "github.com/your-username/terraform-aws-webserver-cluster?ref=v0.0.2"

# GitHub (SSH) — for private repos with SSH key auth
source = "git@github.com:your-username/terraform-aws-webserver-cluster.git?ref=v0.0.2"

# Generic Git with specific commit SHA (maximum pinning — immutable)
source = "git::https://github.com/your-username/terraform-aws-webserver-cluster.git?ref=abc1234"

# Terraform Public Registry
source  = "hashicorp/consul/aws"
version = "0.1.0"

# Private Registry (Terraform Cloud/Enterprise)
source  = "app.terraform.io/my-org/webserver-cluster/aws"
version = "~> 0.0.2"
```

**Note on Registry vs Git:** The Public Registry uses a `version` argument (not `?ref=`). Git sources always use `?ref=` with a tag, branch, or SHA. Using a branch name in `?ref=` is the same as no pin — always use a tag or SHA for reproducibility.

---

## Challenges and Fixes

1. **terraform init caching with Git sources**: After pushing a new tag, running `terraform init` doesn't always pull the latest — Terraform caches the `.terraform/modules` directory. Fix: `terraform init -upgrade` forces a re-fetch. Add this to CI pipelines.

2. **Tag vs. branch in ?ref=**: Initially used `?ref=main` while testing, then forgot to change it to `?ref=v0.0.2` before committing the environment configs. Built a pre-commit check to grep for `?ref=main` or `?ref=master` in module sources and fail.

3. **AMI ID is region-locked**: The default AMI in the module is `us-east-1` specific. When a team member tried to deploy in `eu-west-1`, the plan failed. Fixed by documenting this prominently in the README and adding a comment in the variable description. Long-term fix: replace the static default with a `data "aws_ami"` lookup inside the module.

4. **Security group name conflicts on re-deploy**: If you destroy and re-create the cluster with the same `cluster_name`, AWS sometimes returns an error that the security group name already exists (deletion is async). Fixed with `lifecycle { create_before_destroy = true }` on the security group resources.

---

## Blog Post Summary

**URL:** [https://your-blog.dev/advanced-terraform-module-versioning](https://your-blog.dev/advanced-terraform-module-versioning)

The post covers the full Day 9 journey: diagnosing and fixing the three major module gotchas (file paths, inline block conflicts, and depends_on over-coupling), the complete workflow for tagging and pinning module versions in Git, and the multi-environment deployment pattern where dev tests the latest module version while production stays deliberately behind on the validated version. The versioning section shows all source URL formats side-by-side — local, Git HTTPS, Git SSH, Public Registry, and Private Registry — so readers can pick the right one for their setup.

---

## Social Media Post

**URL:** [https://linkedin.com/posts/your-handle/day9-terraform](https://linkedin.com/posts/your-handle/day9-terraform)

> 🔄 Day 9 of the 30-Day Terraform Challenge — went deep on advanced Terraform modules today. Module versioning, file path gotchas, and deploying different module versions across dev and production. This is the pattern that keeps large infrastructure codebases manageable. #30DayTerraformChallenge #TerraformChallenge #Terraform #IaC #DevOps #AWSUserGroupKenya #EveOps
