# Terraform CLI Commands — Exam Mastery Reference
## 20-Year Practitioner's Own-Words Descriptions + Exam Scenarios

---

## terraform init

**What it does:**
Downloads and installs the providers and modules declared in your configuration,
configures the backend for remote state storage, and creates the .terraform working
directory. It is always the first command you run in a new workspace.

**Exam scenario:**
You clone a repo and run terraform plan — it errors saying "missing required provider."
You need to run terraform init first to download the provider plugins.

**Key flags:**
```bash
terraform init -backend=false              # skip backend init (safe for CI validation)
terraform init -backend-config="key=value" # pass backend config without hardcoding it
terraform init -upgrade                    # upgrade providers to latest allowed version
terraform init -reconfigure               # force reconfigure backend (ignore existing state)
terraform init -migrate-state             # migrate state to new backend
terraform init -get=false                 # skip module downloads
```

**Exam trap:** `-reconfigure` does NOT migrate state — it ignores the existing state.
Use `-migrate-state` if you want to move state to a new backend.

---

## terraform validate

**What it does:**
Checks the syntax and internal consistency of your Terraform configuration files
without accessing any remote services or requiring AWS credentials. It catches things
like referencing a variable that does not exist, or a resource argument with the wrong
type — but it does NOT check whether your AWS credentials are valid or whether the
resources actually exist.

**Exam scenario:**
Your CI pipeline runs on every PR with no AWS credentials. You can safely run
terraform validate because it never contacts AWS — it only reads local .tf files.

**Key flags:**
```bash
terraform validate -json    # machine-readable output for CI integration
terraform validate -no-color
```

**Exam trap:** validate passes even if your AMI ID does not exist in AWS.
It only checks the configuration, not the real world.

---

## terraform fmt

**What it does:**
Rewrites Terraform configuration files to the canonical HCL style — consistent
indentation, aligned equals signs, sorted arguments. It is the Terraform equivalent
of gofmt. Run it before every commit.

**Exam scenario:**
Your CI pipeline fails with a "format check" error. You ran terraform fmt -check
and it exited with code 1, meaning files need reformatting. Run terraform fmt
(without -check) to fix them, then commit.

**Key flags:**
```bash
terraform fmt             # reformat files in current directory
terraform fmt -check      # exit 1 if any file needs reformatting (CI use)
terraform fmt -recursive  # include all subdirectories
terraform fmt -diff       # show the diff without writing files
terraform fmt -write=false # same as -diff — show but do not write
```

**Exam trap:** `-check` does NOT fix files — it only reports. Use it in CI to
enforce formatting. Without `-check`, fmt silently rewrites files.

---

## terraform plan

**What it does:**
Compares the desired state (your .tf files) against the current state (state file
+ real infrastructure via a refresh) and produces a diff showing what would be
created, changed, or destroyed. Nothing is changed in the real world. The plan
output uses +, -, ~, and -/+ symbols.

**Exam scenario:**
A team member manually deleted an S3 bucket that Terraform manages. When you run
terraform plan, Terraform detects the drift and shows the bucket as "to be created"
(+). The state file still references it, but the real bucket is gone.

**Key flags:**
```bash
terraform plan -out=ci.tfplan       # save plan to file (the immutable artifact)
terraform plan -target=aws_vpc.main # plan only one resource (use sparingly)
terraform plan -var="env=prod"      # pass a variable inline
terraform plan -var-file=prod.tfvars
terraform plan -destroy             # preview what destroy would do
terraform plan -refresh=false       # skip the real-world refresh (use carefully)
terraform plan -refresh-only        # only refresh state, do not plan changes
terraform plan -replace=aws_instance.web # force recreation of one resource
```

**Plan output symbols:**
- `+` = create
- `-` = destroy
- `~` = update in-place
- `-/+` = destroy then create (replacement)
- `<=` = data source read

---

## terraform apply

**What it does:**
Executes the changes shown in a plan, actually creating, modifying, or destroying
real infrastructure. When run without a saved plan file, it generates a new plan
and prompts for confirmation. When run with a saved plan file, it applies that exact
plan without prompting.

**Exam scenario:**
Your CI pipeline saved a plan with terraform plan -out=ci.tfplan. In the deploy job,
you run terraform apply ci.tfplan — no prompt appears because the plan is already
approved. The exact changes that were reviewed are what gets applied.

**Key flags:**
```bash
terraform apply                     # plan + prompt + apply
terraform apply -auto-approve       # skip the "yes" prompt (CI use)
terraform apply ci.tfplan           # apply a specific saved plan (no prompt)
terraform apply -target=aws_vpc.main
terraform apply -replace=aws_instance.web  # replaces taint (deprecated)
terraform apply -destroy            # equivalent to terraform destroy
terraform apply -var="env=prod"
terraform apply -refresh=false
```

**Exam trap:** `terraform apply -auto-approve` is dangerous in production.
Best practice: save a plan, get human approval, then `terraform apply <plan>`.

---

## terraform destroy

**What it does:**
Destroys all resources managed by the current Terraform configuration.
It is essentially `terraform apply -destroy`. It shows a plan of everything
that will be deleted and requires confirmation (unless -auto-approve is used).

**Exam scenario:**
You have finished a lab environment and want to tear everything down cleanly.
Run terraform destroy — it will remove all resources in the correct reverse-dependency
order (it destroys dependants before dependees).

**Key flags:**
```bash
terraform destroy                    # plan destruction + prompt
terraform destroy -auto-approve      # skip prompt
terraform destroy -target=aws_rds_instance.main  # destroy one resource
```

**Exam trap:** terraform destroy only removes resources that are IN the state file.
Resources created out-of-band (in the AWS console) are not touched.

---

## terraform output

**What it does:**
Reads and displays output values from the current state file. Does not contact AWS.
Useful for retrieving ALB DNS names, database endpoints, or VPC IDs after an apply,
or for scripting values into other tools.

**Exam scenario:**
After a terraform apply, a deployment script needs the ALB DNS name. Run
`terraform output -raw alb_dns_name` to get just the value without quotes,
suitable for passing to curl or a shell variable.

**Key flags:**
```bash
terraform output                     # show all outputs
terraform output alb_dns_name        # show one output
terraform output -raw alb_dns_name   # no quotes — for shell scripting
terraform output -json               # all outputs as JSON
terraform output -json | jq .alb_dns_name.value
```

**Exam trap:** `-raw` only works on string outputs — it errors on lists or maps.
Use `-json` and pipe to jq for complex types.

---

## terraform state list

**What it does:**
Lists the resource addresses of every resource currently tracked in the state file.
Does not contact AWS. Useful for understanding what Terraform is managing and for
finding the exact address to use in other state commands.

**Exam scenario:**
You want to move a resource to a different module. First, run terraform state list
to find the exact current address (e.g., `aws_instance.web`), then use that address
in terraform state mv.

**Key flags:**
```bash
terraform state list                        # list all resources
terraform state list aws_instance.*         # filter by resource type
terraform state list module.vpc.*           # list resources inside a module
terraform state list -id=i-0abc123         # find resource by real-world ID
```

---

## terraform state show

**What it does:**
Shows all the attributes of a single resource as stored in the state file.
This is the full snapshot Terraform has of that resource — every attribute,
including computed ones like ARNs, IPs, and IDs that were returned by AWS after creation.

**Exam scenario:**
An engineer needs the security group ID that was assigned to an RDS instance.
Run `terraform state show module.mysql.aws_security_group.rds` to see all attributes
including the computed ID, without logging into the AWS console.

**Key flags:**
```bash
terraform state show aws_instance.web
terraform state show module.vpc.aws_vpc.main
terraform state show -json aws_instance.web    # machine-readable
```

---

## terraform state mv

**What it does:**
Moves a resource from one address to another within the same state file,
or from one state file to another. It does NOT touch real infrastructure —
it only updates the state file. Used when you refactor code (rename a resource,
move it into a module) and need Terraform to recognise the existing infrastructure
under its new name.

**Exam scenario:**
You renamed `resource "aws_instance" "web"` to `resource "aws_instance" "app_server"`
in your code. Without state mv, Terraform would destroy the old instance and create a new
one. Run `terraform state mv aws_instance.web aws_instance.app_server` to tell Terraform
the existing instance is now known by the new name. No infrastructure is touched.

**Key flags:**
```bash
terraform state mv aws_instance.web aws_instance.app_server
terraform state mv aws_instance.web module.compute.aws_instance.app_server
terraform state mv -state=old.tfstate -state-out=new.tfstate aws_instance.web aws_instance.web
```

---

## terraform state rm

**What it does:**
Removes a resource from the state file WITHOUT destroying the real infrastructure.
Terraform forgets the resource exists. The resource continues to run in AWS — it is
just no longer managed by this Terraform configuration. Use it when you want to hand
off a resource to a different Terraform workspace or when you need to stop managing
something without deleting it.

**Exam scenario:**
You want to import an S3 bucket into a different Terraform repo. First, run
`terraform state rm aws_s3_bucket.logs` to remove it from the current workspace's state.
The real bucket is untouched. Then import it into the new workspace.

**Key flags:**
```bash
terraform state rm aws_s3_bucket.logs
terraform state rm module.vpc.aws_subnet.public[0]
terraform state rm -dry-run aws_s3_bucket.logs    # preview without executing
```

**CRITICAL EXAM FACT:** terraform state rm does NOTHING to real infrastructure.
The resource keeps running. Only the state entry is deleted.

---

## terraform import

**What it does:**
Brings an existing real-world resource (created manually in the AWS console or by
another tool) under Terraform management by adding it to the state file. You must
write the Terraform resource configuration first, then run import to associate the
real resource with that configuration.

**Exam scenario:**
Your team has been running an EC2 instance that was created manually two years ago.
You write the `resource "aws_instance" "legacy"` block in your .tf file, then run
`terraform import aws_instance.legacy i-0abc123def456` to link the existing instance
to that resource block. After import, terraform plan should show "no changes" if your
config matches reality.

**Key flags:**
```bash
terraform import aws_instance.legacy i-0abc123def456
terraform import module.vpc.aws_vpc.main vpc-0abc123
terraform import -var="region=us-east-2" aws_instance.legacy i-0abc123
```

**Exam trap:** Import only updates STATE — it does not generate .tf configuration.
You must write the resource block yourself. After import, always run plan to verify.

---

## terraform taint (DEPRECATED)

**What it does:**
Marked a resource for forced recreation on the next apply — as if it had been
deleted and needed to be rebuilt. DEPRECATED since Terraform 0.15.2.

**Replacement:** Use `terraform apply -replace=<address>` instead.

**Exam scenario:** If you see terraform taint on the exam, know that:
1. It is deprecated
2. The modern equivalent is `terraform apply -replace=aws_instance.web`
3. Both cause the resource to be destroyed and recreated on next apply

```bash
# Old way (deprecated)
terraform taint aws_instance.web

# New way
terraform apply -replace=aws_instance.web
```

---

## terraform workspace

**What it does:**
Manages Terraform workspaces — isolated state environments within the same
backend configuration. Each workspace has its own state file. The default workspace
is named "default".

**Exam scenario:**
A team uses workspaces to manage dev/stage/prod with the same code. They run
`terraform workspace new prod` to create the prod workspace, then
`terraform workspace select prod` before running apply. Each workspace has
a separate state file in S3 at `env:/prod/terraform.tfstate`.

**Key flags / subcommands:**
```bash
terraform workspace list          # list all workspaces (* = current)
terraform workspace new dev       # create and switch to new workspace
terraform workspace select prod   # switch to existing workspace
terraform workspace show          # print current workspace name
terraform workspace delete dev    # delete a workspace (must be empty)
```

**Exam trap:** Workspaces share the same backend configuration and the same code.
They are NOT a replacement for separate environments with separate state files.
File layout isolation (separate directories) is safer for prod/non-prod isolation.

**In configuration:** `terraform.workspace` is a built-in variable:
```hcl
locals {
  instance_type = terraform.workspace == "prod" ? "t3.medium" : "t3.micro"
}
```

---

## terraform providers

**What it does:**
Shows the providers required by the current configuration, their version constraints,
and where they will be installed from. Subcommands include lock (update the lock file)
and mirror (download providers for air-gapped use).

**Exam scenario:**
You need to deploy Terraform in an air-gapped environment with no internet access.
Run `terraform providers mirror /path/to/local/mirror` to download all required
provider binaries locally, then configure the filesystem mirror in CLI config.

**Key subcommands:**
```bash
terraform providers                          # show required providers
terraform providers lock                     # update .terraform.lock.hcl
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
terraform providers mirror /tmp/mirror       # download providers locally
terraform providers schema -json             # dump full provider schema as JSON
```

---

## terraform login

**What it does:**
Authenticates to Terraform Cloud (or Terraform Enterprise) by obtaining an API token
and storing it in the local credentials file (~/.terraform.d/credentials.tfrc.json).
Required before you can use a TFC backend or access the private module registry.

**Exam scenario:**
A developer joins the team and needs to run Terraform against the TFC backend.
They run `terraform login` — a browser window opens, they approve the token,
and credentials are saved locally. Subsequent terraform init commands can now
access the TFC workspace.

**Key flags:**
```bash
terraform login                    # login to app.terraform.io (default)
terraform login my.tfe.company.com # login to self-hosted TFE
terraform logout                   # remove stored credentials
```

---

## terraform graph

**What it does:**
Outputs the Terraform resource dependency graph in DOT format — a graph description
language that can be rendered by Graphviz. Shows the relationships between all
resources, data sources, and outputs. Useful for debugging complex dependency chains
but rarely used in day-to-day work.

**Exam scenario:**
You suspect a circular dependency in your configuration that is causing a plan error.
Run `terraform graph | dot -Tsvg > graph.svg` to render the dependency graph
visually and identify the cycle.

**Key flags:**
```bash
terraform graph                    # full dependency graph
terraform graph -type=plan         # graph for a specific operation
terraform graph | dot -Tpng > graph.png   # render with Graphviz
```

**Exam fact:** The output is DOT format. You need Graphviz installed to render it.

---

## Quick Reference — What Does Each Command Touch?

| Command | State file | Real infra | AWS creds needed |
|---------|-----------|-----------|-----------------|
| init | Yes (configures) | No | No |
| validate | No | No | No |
| fmt | No | No | No |
| plan | Yes (reads) | Yes (refresh) | Yes |
| apply | Yes (writes) | Yes | Yes |
| destroy | Yes (writes) | Yes | Yes |
| output | Yes (reads) | No | No |
| state list | Yes (reads) | No | No |
| state show | Yes (reads) | No | No |
| state mv | Yes (writes) | No | No |
| state rm | Yes (writes) | No | No |
| import | Yes (writes) | Yes (reads) | Yes |
| workspace | Yes (switches) | No | No |
| graph | No | No | No |
| login | No (credentials) | No | No |
