# Day 23 Submission — Workspace Documentation
## Terraform Associate Exam Preparation

---

## Domain Audit Summary

| Domain | Weight | Rating | Action |
|--------|--------|--------|--------|
| IaC concepts | 16% | GREEN | No study needed |
| Terraform's purpose | 20% | GREEN | Quick review only |
| Terraform basics | 24% | MIXED | Study built-in functions + type constraints |
| Use the Terraform CLI | 26% | YELLOW | Priority 1 — most exam weight |
| Interact with modules | 12% | GREEN | No study needed |
| Core workflow | 8% | GREEN | No study needed |
| Implement and maintain state | 8% | MOSTLY GREEN | Practice state mv/rm |
| Read/generate/modify config | 8% | MIXED | Study dynamic blocks + for expressions |
| Terraform Cloud capabilities | 4% | MOSTLY GREEN | Quick review |

---

## CLI Commands Self-Test (Own Words)

**terraform init**
Downloads provider plugins and configures the backend. Run it first in any new workspace. Re-run it after adding new providers or modules.
Scenario: You add a new provider to your config and plan errors saying plugin not installed — run terraform init.

**terraform validate**
Checks that your .tf files are syntactically correct and internally consistent, without contacting AWS.
Scenario: CI pipeline needs to check configuration correctness without AWS credentials — validate is the answer.

**terraform fmt**
Rewrites .tf files to canonical HCL formatting style.
Scenario: A new team member's PR fails the CI format check — they run terraform fmt and commit the result.

**terraform plan**
Compares desired state (code) against current state (state file + real infra) and shows what would change.
Scenario: Someone deleted an RDS instance manually — plan shows it as "to be created."

**terraform apply**
Executes the changes from a plan, creating/modifying/destroying real infrastructure.
Scenario: After reviewing a saved plan file, run terraform apply ci.tfplan to apply it without re-planning.

**terraform destroy**
Destroys all resources in the current configuration.
Scenario: End of a lab session — run terraform destroy to avoid ongoing AWS charges.

**terraform output**
Reads and displays output values from the state file, without contacting AWS.
Scenario: A deployment script needs the ALB DNS name — run terraform output -raw alb_dns_name.

**terraform state list**
Lists all resource addresses currently tracked in the state file.
Scenario: Before running state mv, run state list to find the exact resource address.

**terraform state show**
Shows all stored attributes of a single resource in state, without contacting AWS.
Scenario: Need to find the ARN of a security group — run terraform state show aws_security_group.app.

**terraform state mv**
Moves a resource from one address to another in state. Does NOT touch real infrastructure.
Scenario: You renamed a resource in your code — run state mv to prevent Terraform from destroying and recreating it.

**terraform state rm**
Removes a resource from the state file. The real resource is completely unaffected.
Scenario: You want to hand off an S3 bucket to a different Terraform workspace — state rm it here, import it there.

**terraform import**
Associates a real existing resource with a Terraform resource block in state.
Scenario: An EC2 instance was created manually — write the resource block then run terraform import to manage it.

**terraform taint (deprecated)**
Marked a resource for forced recreation. Now replaced by terraform apply -replace=<address>.
Scenario: On the exam — know it is deprecated and that -replace is the modern equivalent.

**terraform workspace**
Creates, lists, selects, and deletes workspaces — each with its own isolated state file.
Scenario: Team uses workspaces for dev/stage — run terraform workspace select prod before applying to prod.

**terraform providers**
Shows providers required by the configuration and subcommands for locking and mirroring them.
Scenario: Air-gapped deployment — run terraform providers mirror /tmp/mirror to download providers locally first.

**terraform login**
Authenticates to Terraform Cloud and stores the API token locally.
Scenario: New developer joins and needs TFC backend access — they run terraform login first.

**terraform graph**
Outputs the resource dependency graph in DOT format for rendering with Graphviz.
Scenario: Debugging a circular dependency — run terraform graph | dot -Tsvg > graph.svg to visualise it.

---

## Non-Cloud Provider Working Example


# Generate a stable unique suffix for S3 bucket names (must be globally unique)
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "app_assets" {
  bucket = "myapp-assets-${random_id.bucket_suffix.hex}"
}

# Generate a strong random password for RDS — stable after first apply
resource "random_password" "db_master" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Write the ALB DNS name to a local file after apply (on the runner)
resource "local_file" "alb_endpoint" {
  content  = module.hello_world_app.alb_dns_name
  filename = "${path.module}/generated/alb-endpoint.txt"
}
```

**Where these are useful:**
- `random_id` / `random_string`: S3 bucket names require global uniqueness. Appending a random suffix avoids naming conflicts without hardcoding.
- `random_password`: Generates initial database passwords without them appearing in .tf files. The result is stored in state (sensitive) and can be pushed to Secrets Manager.
- `local_file`: After deploying infrastructure, write connection strings or endpoints to files that downstream scripts or CI steps can read.

---

## Official Practice Question Results

HashiCorp sample questions: 18/20 correct on first attempt (90%)

Questions missed:
1. The exact behaviour of `terraform init -reconfigure` vs `-migrate-state`
   Learning: `-reconfigure` does NOT migrate state — it ignores the existing state entirely.

2. The correct enforcement level terminology for Sentinel policies
   Learning: advisory / soft-mandatory / hard-mandatory — not advisory / warning / block.

Both added to study plan for Day 28.


## Social Media Post

Day 23 of the 30-Day Terraform Challenge — full exam prep mode.

Audited every objective domain. Honest finding: 22 days of hands-on work covers 80%
of exam material deeply. The remaining 20% is CLI flag edge cases and built-in functions.

The tip nobody tells you: Domain 4 (CLI commands) carries 26% of the exam weight.
The question is not "what does terraform plan do" — it is "what does terraform state rm
do to real infrastructure?" (Answer: nothing.)

Know what each command does to three things: state file, real infra, AWS credentials needed.
That mental model makes the CLI section straightforward.

#30DayTerraformChallenge #TerraformChallenge #Terraform #TerraformAssociate #CertificationPrep #AWSUserGroupKenya #EveOps
