# Terraform Associate Exam — 25 Original Practice Questions
## Written by a 20-Year Practitioner Based on the Challenge Infrastructure

> Format: Question → Answer choices → Correct answer → Why each wrong answer is wrong

---

### Question 1
You run `terraform state rm aws_s3_bucket.logs`. What happens to the real S3 bucket in AWS?

A) The bucket is deleted from AWS
B) The bucket is emptied but not deleted
C) Nothing — the bucket continues to exist in AWS unchanged
D) The bucket is moved to a different Terraform workspace

**Correct answer: C**

- A is wrong: `state rm` only modifies the state file. It has zero effect on real infrastructure.
- B is wrong: `state rm` does not interact with AWS at all.
- D is wrong: Workspaces are separate state files; `state rm` does not move resources between them.
- C is correct: `state rm` removes the resource from Terraform's state file, causing Terraform to "forget" it. The S3 bucket keeps running unchanged in AWS.

---

### Question 2
A developer runs `terraform validate` on a configuration that references an AMI ID
that does not exist in AWS. What is the result?

A) Terraform errors with "AMI not found"
B) Terraform warns but continues
C) Terraform validate passes successfully
D) Terraform contacts AWS to check the AMI and blocks if it does not exist

**Correct answer: C**

- A is wrong: `validate` does not contact AWS. It only checks syntax and internal consistency.
- B is wrong: There are no warnings — validate passes cleanly.
- D is wrong: `validate` requires no AWS credentials and makes no API calls.
- C is correct: `validate` checks that the configuration is syntactically valid and internally consistent. It does not verify that referenced resources (AMIs, VPCs, etc.) actually exist.

---

### Question 3
You have the following provider configuration. Which resource block correctly uses the west coast provider?

```hcl
provider "aws" {
  region = "us-east-1"
}
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}
```

A) `resource "aws_s3_bucket" "west" { provider = "west" }`
B) `resource "aws_s3_bucket" "west" { provider = aws.west }`
C) `resource "aws_s3_bucket" "west" { region = "us-west-2" }`
D) `resource "aws_s3_bucket" "west" { alias = "west" }`

**Correct answer: B**

- A is wrong: Provider references use dot notation — `aws.west` not a string `"west"`.
- C is wrong: The `region` argument belongs in the provider block, not the resource block.
- D is wrong: `alias` is a provider argument, not a resource argument.
- B is correct: The `provider` meta-argument in a resource block uses `<provider_type>.<alias>` notation.

---

### Question 4
What does the `-/+` symbol mean in a `terraform plan` output?

A) The resource will be updated in place
B) The resource will be destroyed then recreated
C) The resource has an unknown value that will be determined at apply time
D) The resource is being imported from existing infrastructure

**Correct answer: B**

- A is wrong: In-place updates are shown with `~` (tilde).
- C is wrong: Unknown values are shown with `(known after apply)` in the attribute values.
- D is wrong: Import is a separate command, not a plan symbol.
- B is correct: `-/+` means the resource must be destroyed and a new one created. This happens when you change an immutable attribute (like an EC2 instance's AMI ID or an RDS engine version).

---

### Question 5
Your team's CI pipeline runs `terraform fmt -check -recursive` and exits with code 1.
What does this mean and what should you do?

A) The configuration has syntax errors — run terraform validate to see them
B) One or more files are not formatted to canonical style — run terraform fmt to fix them
C) The backend configuration is missing — run terraform init
D) Provider versions are out of date — run terraform init -upgrade

**Correct answer: B**

- A is wrong: `fmt -check` checks formatting, not syntax. Syntax errors would fail validate, not fmt.
- C is wrong: Backend configuration has nothing to do with fmt.
- D is wrong: fmt has no relationship to provider versions.
- B is correct: `terraform fmt -check` exits with code 1 if any file needs reformatting. Run `terraform fmt -recursive` (without -check) to fix the files, then commit.

---

### Question 6
A team member manually added an EC2 instance in the AWS console that should now be
managed by Terraform. What is the correct sequence of steps?

A) Run `terraform plan` — Terraform will automatically detect and import it
B) Write the resource block in .tf files, then run `terraform import`
C) Run `terraform import` first, then write the resource block
D) Delete the EC2 instance and let Terraform recreate it with terraform apply

**Correct answer: B**

- A is wrong: `terraform plan` cannot automatically import resources. It would show no change because the resource is not in state.
- C is wrong: You must write the resource configuration BEFORE importing. Import adds the resource to state and associates it with an existing resource block.
- D is wrong: Deleting and recreating is disruptive and unnecessary.
- B is correct: The correct workflow is (1) write the Terraform resource block, (2) run `terraform import <address> <real_id>`, (3) run `terraform plan` to verify "no changes".

---

### Question 7
Which of the following is TRUE about Terraform workspaces?

A) Each workspace has its own provider configuration
B) Each workspace has its own state file
C) Each workspace must be in a separate Git repository
D) Workspaces are the recommended way to manage prod vs dev isolation

**Correct answer: B**

- A is wrong: All workspaces share the same provider configuration and the same .tf files.
- C is wrong: Workspaces exist within a single Terraform configuration directory.
- D is wrong: File layout isolation (separate directories per environment) is recommended for prod/non-prod. Workspaces share code, making it harder to have different configurations per environment.
- B is correct: Each workspace has its own separate state file in the backend.

---

### Question 8
You need to update a resource's configuration but Terraform says no changes are needed,
even though the real resource was changed outside of Terraform. What is most likely happening?

A) The state file is corrupted
B) The resource is not in the state file
C) Terraform needs `-refresh=false` to detect the change
D) The attribute you changed is not tracked by the AWS provider

**Correct answer: D**

- A is wrong: A corrupted state file would usually cause an error, not a clean "no changes."
- B is wrong: If not in state, plan would show it as a new resource to create.
- C is wrong: `-refresh=false` skips the refresh — the opposite of what you want. The default behavior IS to refresh.
- D is correct: Some attributes are not tracked by the provider (or are ignored via `lifecycle { ignore_changes }`). If you changed an attribute that Terraform does not manage, plan would show no changes.

---

### Question 9
What is the difference between `terraform apply -replace=aws_instance.web` and `terraform taint aws_instance.web`?

A) There is no difference — they do the same thing
B) `-replace` destroys and recreates immediately; `taint` waits for the next plan
C) `taint` marks the resource for recreation on next apply; `-replace` is the modern equivalent and does the same thing but is not deprecated
D) `taint` only works with EC2 instances; `-replace` works with any resource

**Correct answer: C**

- A is partially right but misses the deprecation context.
- B is wrong: Neither destroys immediately. Both plan destruction + recreation on next apply.
- D is wrong: Both work with any resource type.
- C is correct: `terraform taint` was deprecated in Terraform 0.15.2. `terraform apply -replace=<address>` is the modern replacement. Both mark a resource for forced recreation — destroy the existing resource and create a new one on the next apply.

---

### Question 10
A `terraform plan` output shows a resource with `~ update in-place`. Later, you run
`terraform apply` and the resource shows `-/+ (destroy and recreate)`. What happened?

A) A bug in Terraform
B) The resource's state changed between plan and apply (concurrent modification)
C) The -auto-approve flag was used incorrectly
D) The provider was upgraded between plan and apply

**Correct answer: B**

- A is wrong: This is expected behaviour, not a bug.
- C is wrong: -auto-approve does not change plan results.
- D is wrong: Provider upgrades would require re-running init.
- B is correct: Between plan and apply, the real resource or its attributes may have changed (another team member applied, an AWS auto-action occurred, etc.). Terraform refreshes state at apply time, which can reveal a different action is needed than what the plan showed. This is why saved plan files (`terraform plan -out=ci.tfplan`) are important — the apply uses the exact plan without re-evaluating.

---

### Question 11
Which built-in Terraform variable returns the name of the current workspace?

A) `var.workspace`
B) `local.workspace`
C) `terraform.workspace`
D) `env.workspace`

**Correct answer: C**

- A is wrong: This would be a user-defined variable.
- B is wrong: This would be a user-defined local value.
- D is wrong: This does not exist in Terraform.
- C is correct: `terraform.workspace` is a built-in expression that returns the current workspace name as a string. Use it in locals: `local.is_prod = terraform.workspace == "prod"`.

---

### Question 12
What does `.terraform.lock.hcl` contain and why should it be committed to version control?

A) Terraform state data — should NOT be committed (contains secrets)
B) Provider version hashes — SHOULD be committed to ensure consistent provider versions across the team
C) Backend configuration — should NOT be committed (environment-specific)
D) Module source URLs — SHOULD be committed for reproducibility

**Correct answer: B**

- A is wrong: `.terraform.lock.hcl` contains no state data or secrets. The state file is `terraform.tfstate`.
- C is wrong: Backend config is in your .tf files, not the lock file.
- D is wrong: Module sources are in .tf files.
- B is correct: `.terraform.lock.hcl` records the exact version and cryptographic hash of each provider. Committing it ensures every team member and CI runner uses identical provider binaries. Without it, `terraform init` might install different provider versions.

---

### Question 13
In a Terraform module, what is the difference between `path.module` and `path.root`?

A) They are always the same value
B) `path.module` is the directory of the current module; `path.root` is the directory of the root module
C) `path.root` is the directory of the current module; `path.module` is the directory of the root module
D) `path.module` is the absolute path; `path.root` is the relative path

**Correct answer: B**

- A is wrong: They are the same only in the root module. In child modules they differ.
- C is wrong: This is reversed.
- D is wrong: Both are absolute filesystem paths.
- B is correct: When a module at `./modules/vpc` uses `path.module`, it gets `./modules/vpc`. When it uses `path.root`, it gets the root module directory (where `terraform apply` was run). Use `path.module` for files within the module; use `path.root` to reference files in the calling workspace.

---

### Question 14
A `count` meta-argument is set to 0. What happens to an existing resource?

A) An error is thrown — count cannot be 0
B) The resource is destroyed
C) The resource still exists but is removed from state
D) The resource is ignored on the next apply

**Correct answer: B**

- A is wrong: count = 0 is valid Terraform syntax.
- C is wrong: Removing from state without destroying would require `terraform state rm`.
- D is wrong: Terraform acts on the count value immediately in the next apply.
- B is correct: Setting `count = 0` tells Terraform you want zero instances of that resource. If one exists, Terraform destroys it on the next apply. This is the common "conditional resource" pattern: `count = var.create_resource ? 1 : 0`.

---

### Question 15
What is the correct way to pass sensitive variable values to Terraform in a CI pipeline
without storing them in .tfvars files?

A) Hardcode them in the .tf files with `sensitive = true`
B) Set them as `TF_VAR_<variable_name>` environment variables in the CI runner
C) Pass them as `-var` flags in the terraform apply command in the CI script
D) Store them in the .terraform directory

**Correct answer: B**

- A is wrong: Hardcoding secrets in .tf files is a serious security risk regardless of the sensitive flag.
- C is wrong: Passing secrets as command-line flags exposes them in process lists and logs.
- D is wrong: The .terraform directory contains provider binaries and modules, not variable values.
- B is correct: Terraform reads environment variables prefixed with `TF_VAR_` as variable values. For example, `TF_VAR_db_password=mysecret` sets the `db_password` variable. CI systems (GitHub Actions, CircleCI) have secure secrets storage that can inject environment variables without exposing them in logs.

---

### Question 16
You have a Terraform configuration that creates 5 AWS EC2 instances using `count = 5`.
You change it to `count = 3`. What does terraform plan show?

A) Create 3 new instances (total will be 8)
B) Destroy all 5 and create 3 new ones
C) Destroy 2 instances (the last two: index [3] and [4])
D) Terraform errors because you cannot reduce count

**Correct answer: C**

- A is wrong: Terraform knows 5 already exist and would not create more.
- B is wrong: Terraform does not rebuild all instances — it only destroys the excess ones.
- D is wrong: Reducing count is valid.
- C is correct: Terraform destroys the highest-indexed instances. With `count = 5`, instances are indexed [0] through [4]. Reducing to `count = 3` destroys [3] and [4], keeping [0], [1], and [2]. This is a key difference between `count` and `for_each` — `for_each` is tied to keys, not positions, making it safer for deletions.

---

### Question 17
Which Terraform command would you use to see all the attributes (including computed ones
like ARN and ID) of a resource currently in state, WITHOUT contacting AWS?

A) `terraform plan`
B) `terraform state show <address>`
C) `terraform output`
D) `terraform state list`

**Correct answer: B**

- A is wrong: `plan` contacts AWS to refresh state and shows planned changes, not current attributes.
- C is wrong: `output` only shows values defined in `output` blocks, not all resource attributes.
- D is wrong: `list` shows resource addresses only, not attributes.
- B is correct: `terraform state show <address>` reads from the local state file and displays all stored attributes of that resource. No AWS credentials needed.

---

### Question 18
A Sentinel policy is configured as `enforcement_level = "soft-mandatory"`. 
A plan violates this policy. What happens?

A) The apply is blocked with no way to proceed
B) The apply proceeds with a warning logged
C) The apply is blocked but can be overridden by a user with appropriate permissions
D) The policy is automatically disabled for this run

**Correct answer: C**

- A is wrong: That is `hard-mandatory` behaviour.
- B is wrong: That is `advisory` behaviour.
- D is wrong: Policies cannot be auto-disabled.
- C is correct: `soft-mandatory` means the policy must pass OR be overridden by an authorised team member (typically an admin). The override is logged in the Terraform Cloud audit trail. Use `soft-mandatory` for policies that are important but may have legitimate exceptions.

---

### Question 19
What is the purpose of the `depends_on` meta-argument and when should it be used?

A) Always — to make the dependency graph explicit and readable
B) Only when Terraform cannot automatically determine the dependency order
C) Only in root modules, never in child modules
D) Only with data sources, never with resources

**Correct answer: B**

- A is wrong: Overusing `depends_on` obscures the dependency graph and can cause unnecessary re-creation.
- C is wrong: `depends_on` can be used in both root and child modules.
- D is wrong: `depends_on` works with both resources and data sources.
- B is correct: Terraform automatically determines dependencies from references (e.g., `aws_subnet.main.id` in a resource creates an implicit dependency on `aws_subnet.main`). Use `depends_on` only for implicit dependencies that are NOT captured by references — for example, if resource A must run before resource B but B does not reference any attribute of A.

---

### Question 20
Which of the following backend types supports state locking natively?

A) local
B) S3 (without DynamoDB)
C) S3 with DynamoDB
D) HTTP

**Correct answer: C**

- A is wrong: The local backend uses a local file lock — works on a single machine but not for teams.
- B is wrong: S3 alone does NOT support state locking. You must add DynamoDB for locking.
- D is wrong: The HTTP backend supports locking only if the server implements the lock API.
- C is correct: The S3 backend + DynamoDB table combination provides distributed state locking. The DynamoDB table stores a lock entry (key: LockID) that prevents concurrent applies.

---

### Question 21
You want to reference the output of one Terraform configuration (workspace A) from another
configuration (workspace B). What is the correct approach?

A) Copy the state file from workspace A to workspace B
B) Use `terraform_remote_state` data source in workspace B, pointing to workspace A's backend
C) Use module outputs — modules share state automatically
D) Export the value to an environment variable and read it with `var`

**Correct answer: B**

- A is wrong: Manually copying state files is dangerous and not a supported pattern.
- C is wrong: Modules within the same root module share state, but separate workspaces/configurations do not.
- D is wrong: Environment variables would require manual maintenance and break automation.
- B is correct: The `terraform_remote_state` data source reads the output values from another configuration's state file:
  ```hcl
  data "terraform_remote_state" "vpc" {
    backend = "s3"
    config = { bucket = "my-state-bucket", key = "vpc/terraform.tfstate", region = "us-east-2" }
  }
  local.vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  ```

---

### Question 22
A resource block has `lifecycle { create_before_destroy = true }`. 
Which scenario correctly describes when this matters?

A) When you add a new resource to the configuration
B) When you destroy the entire infrastructure
C) When you change an immutable attribute that forces resource replacement
D) When you use count or for_each

**Correct answer: C**

- A is wrong: Creating a new resource does not involve any destroy action.
- B is wrong: Destroying everything runs destroy in dependency order, not create-before.
- D is wrong: count/for_each do not trigger create_before_destroy by themselves.
- C is correct: When an immutable attribute changes (like an AMI ID or RDS engine version), Terraform must replace the resource (-/+ in plan). Normally, it destroys the old one first then creates the new one — causing downtime. With `create_before_destroy = true`, Terraform creates the new resource first, then destroys the old one. Essential for zero-downtime deployments in ASGs.

---

### Question 23
What happens when you run `terraform init` in a directory that already has a
`.terraform` directory and a configured backend?

A) It errors — you must delete .terraform first
B) It re-initialises, downloading providers and reconfiguring the backend
C) It does nothing — init only runs once
D) It destroys the existing state and starts fresh

**Correct answer: B**

- A is wrong: Running init on an existing directory is safe and common.
- C is wrong: init can and should be re-run (e.g., after adding a new provider or module).
- D is wrong: init never touches state data.
- B is correct: `terraform init` is idempotent. Re-running it downloads any new providers or modules, validates the backend configuration, and updates the lock file if needed. Nothing is destroyed. Use `terraform init -upgrade` to also upgrade provider versions.

---

### Question 24
You have this variable declaration:
```hcl
variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, stage, or prod."
  }
}
```
A user runs `terraform apply -var="environment=staging"`. What happens?

A) The apply proceeds with environment = "staging"
B) Terraform warns but continues with environment = "staging"
C) Terraform errors with the validation error message before any infrastructure changes
D) Terraform falls back to the default value "dev"

**Correct answer: C**

- A is wrong: The validation block rejects "staging" because it is not in the allowed list.
- B is wrong: Validation blocks are hard errors, not warnings.
- D is wrong: Terraform does not silently fall back to defaults on validation failure.
- C is correct: Variable validation runs during terraform plan, before any changes are made. If the condition evaluates to false, Terraform displays the error_message and stops. No infrastructure is touched.

---

### Question 25
In the context of Terraform Cloud, what is the difference between a Terraform variable
and an environment variable?

A) There is no difference — they are both passed to Terraform the same way
B) Terraform variables are passed as `-var` flags; environment variables are set as `TF_VAR_` prefixed
C) Terraform variables are available as `var.<name>` in HCL; environment variables are available to provider configuration and provisioners but not as `var.<name>` unless prefixed with TF_VAR_
D) Terraform variables are stored encrypted; environment variables are stored in plaintext

**Correct answer: C**

- A is wrong: They behave differently and are used for different purposes.
- B is wrong: In Terraform Cloud, both are configured through the workspace UI, not CLI flags.
- D is wrong: Both variable types can be marked sensitive (encrypted) in Terraform Cloud.
- C is correct: In TFC, "Terraform variables" are passed as HCL variable values and appear as `var.<name>`. "Environment variables" are set in the runner's environment and are used by provider SDKs (e.g., `AWS_ACCESS_KEY_ID`) or accessed via `TF_VAR_<name>` to set Terraform variables. Sensitive versions of both are stored encrypted in TFC.
