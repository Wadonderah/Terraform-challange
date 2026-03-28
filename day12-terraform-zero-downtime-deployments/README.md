# Day 12 — Zero-Downtime Deployments with Terraform

## Project Structure

```
day12-terraform/
├── modules/
│   └── webserver-cluster/
│       ├── variables.tf     # All input variables incl. blue/green config
│       ├── locals.tf        # (inline in main.tf for this module)
│       ├── main.tf          # create_before_destroy + blue/green ASGs
│       ├── outputs.tf       # ALB DNS, ASG names, traffic loop command
│       └── user-data.sh     # Nginx install + versioned HTML page
├── live/
│   ├── dev/main.tf          # Dev calling config
│   └── production/main.tf   # Production calling config
└── README.md
```

---

## Key Patterns

### 1. `create_before_destroy` on Launch Template + ASG

```hcl
lifecycle {
  create_before_destroy = true
}
```

Reverses the default destroy-then-create order. New ASG is fully healthy before old ASG is terminated. No downtime window.

### 2. `name_prefix` instead of `name` on ASG

```hcl
resource "aws_autoscaling_group" "blue" {
  name_prefix = "${var.cluster_name}-blue-"   # AWS generates unique name
  ...
  lifecycle { create_before_destroy = true }
}
```

AWS does not allow two ASGs with the same name to coexist. `name_prefix` lets AWS generate a unique name each time, which is required for `create_before_destroy` to work.

### 3. `random_id` keyed on app version

```hcl
resource "random_id" "blue" {
  keepers     = { app_version = var.blue_app_version }
  byte_length = 4
}

resource "aws_launch_template" "blue" {
  name = "${var.cluster_name}-blue-${random_id.blue.hex}"
  ...
}
```

New `random_id` → new Launch Template name → new Launch Template created → ASG replacement triggered.

### 4. Blue/Green listener switch

```hcl
resource "aws_lb_listener" "http" {
  default_action {
    type             = "forward"
    target_group_arn = var.active_environment == "blue"
      ? aws_lb_target_group.blue.arn
      : aws_lb_target_group.green.arn
  }
}
```

Changing `active_environment` from `"blue"` to `"green"` updates the listener in a single API call. Traffic shifts atomically — no downtime window.

---

## Step-by-Step Workflow

### Initial Deployment (v1 on blue)

```bash
cd live/dev
terraform init
terraform apply
# Note the ALB DNS name from outputs
```

### Start Traffic Monitor (second terminal)

```bash
while true; do
  curl -s http://<your-alb-dns>
  sleep 2
done
```

### Deploy v2 to Green (blue still live)

Green ASG already runs v2 from the initial deploy. Both ASGs are running.

### Switch Traffic to Green

Edit `live/dev/main.tf`:
```hcl
active_environment = "green"   # was "blue"
```

```bash
terraform apply
# Only the listener rule changes — apply takes ~10 seconds
# Watch the traffic loop switch from v1 to v2 with no errors
```

### Roll Back to Blue

```hcl
active_environment = "blue"
```

```bash
terraform apply
# Instant rollback — same single listener rule update
```

### Update Blue to v3 (zero-downtime update within blue)

```hcl
blue_app_version   = "v3"     # triggers new random_id → new LT → new ASG
active_environment = "green"  # keep green live while blue updates
```

```bash
terraform apply
# Blue ASG cycles with create_before_destroy — green stays live throughout
# When blue is healthy, switch: active_environment = "blue"
```

---

## Why Default Terraform Causes Downtime

Default order for a resource that cannot be updated in-place:

```
1. Destroy old ASG  →  instances terminated  →  app goes DOWN
2. Create new ASG   →  instances spin up     →  app comes BACK
```

The gap between step 1 and step 2 is your downtime window — typically 2–5 minutes for an ASG.

`create_before_destroy` reverses this:

```
1. Create new ASG   →  instances spin up, pass health checks
2. Destroy old ASG  →  traffic already on new instances
```

Zero downtime window.
