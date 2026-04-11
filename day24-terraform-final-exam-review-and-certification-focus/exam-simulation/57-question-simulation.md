# Day 24 — Full Exam Simulation
## 57 Questions | 60 Minutes | Passing Score: 70% (40/57)

> Instructions: Set a timer for 60 minutes. Answer every question.
> Flag uncertain ones with [FLAG]. Return to flagged questions after completing all 57.
> Do NOT look anything up during the simulation.

---

## DOMAIN 1 — IaC Concepts (Questions 1–9)

**Q1.** Which of the following BEST describes idempotency in the context of Infrastructure as Code?
A) Running the same configuration twice deletes resources on the second run
B) Applying the same configuration multiple times always produces the same result
C) The configuration file is immutable and cannot be changed after first apply
D) Infrastructure is automatically recreated when it is modified

**ANSWER: B**
Idempotency means that regardless of how many times you apply the same configuration, the end state is identical. Terraform achieves this by comparing desired state (code) against current state (state file + real infra) and only making necessary changes.

---

**Q2.** What is configuration drift?
A) A gradual increase in Terraform state file size
B) The difference between the infrastructure declared in code and what actually exists in the cloud
C) Provider version changes between terraform init runs
D) A workspace that has not been applied in more than 30 days

**ANSWER: B**
Configuration drift occurs when real infrastructure diverges from the declared configuration — usually from manual changes made outside Terraform (clicking in the AWS console). Terraform plan detects it.

---

**Q3.** Which IaC approach does Terraform use?
A) Imperative — you describe the steps to reach the desired state
B) Declarative — you describe the desired end state and Terraform figures out the steps
C) Procedural — you write functions that Terraform executes in sequence
D) Event-driven — Terraform reacts to infrastructure events

**ANSWER: B**
Terraform is declarative. You declare what you want (e.g., "an EC2 instance with t3.micro") and Terraform determines what API calls to make to achieve that state. Ansible is an example of an imperative/procedural approach.

---

**Q4.** Which of the following is a benefit of immutable infrastructure?
A) Resources can be updated in place, reducing downtime
B) Existing resources are modified when configuration changes
C) When changes are needed, new resources replace old ones rather than modifying them
D) State files are never needed because resources are replaced

**ANSWER: C**
Immutable infrastructure means you never modify existing resources — you replace them. This eliminates configuration drift on running instances, enables easy rollback (deploy the old image), and is the principle behind ASG rolling deployments with create_before_destroy.

---

**Q5.** A team uses manual CLI commands to provision servers. Which of the following is a risk that Infrastructure as Code eliminates?
A) Provider API rate limits
B) Network latency between regions
C) Manual errors and undocumented changes that cannot be reproduced
D) Cloud provider pricing changes

**ANSWER: C**
IaC eliminates the risk of undocumented, irreproducible manual changes. Every change is code-reviewed, version-controlled, auditable, and reproducible. It does not affect API rate limits, latency, or pricing.

---

**Q6.** Which of the following tools is a configuration MANAGEMENT tool rather than a provisioning tool?
A) Terraform
B) CloudFormation
C) Ansible
D) Pulumi

**ANSWER: C**
Ansible is a configuration management tool — it configures software on existing servers. Terraform, CloudFormation, and Pulumi are provisioning tools — they create the infrastructure itself.

---

**Q7.** What does "version controlling infrastructure" mean?
A) Pinning providers to specific versions in required_providers
B) Storing infrastructure configuration in a Git repository so changes are tracked, reviewed, and reversible
C) Using Terraform workspaces to manage versions of deployed infrastructure
D) Storing the terraform.tfstate file in version control

**ANSWER: B**
Version controlling infrastructure means treating .tf files like application code — stored in Git, reviewed via pull requests, and tracked with commit history. Note: terraform.tfstate should NOT be committed to version control (it may contain secrets).

---

**Q8.** Which of the following statements about Terraform is TRUE?
A) Terraform can only manage AWS resources
B) Terraform uses an agent installed on managed servers
C) Terraform is agentless — it communicates directly with provider APIs
D) Terraform requires a master server to coordinate deployments

**ANSWER: C**
Terraform is agentless — it runs on your local machine or CI server and communicates directly with provider APIs (AWS API, GCP API, etc.). No agents are installed on managed resources. Ansible can be either agent or agentless; Chef/Puppet require agents.

---

**Q9.** What is the primary difference between Terraform and AWS CloudFormation?
A) Terraform uses YAML; CloudFormation uses HCL
B) CloudFormation manages state; Terraform does not
C) Terraform supports multiple cloud providers; CloudFormation is AWS-only
D) CloudFormation is open source; Terraform is proprietary

**ANSWER: C**
CloudFormation is AWS-specific — it cannot manage Azure, GCP, or other provider resources. Terraform supports hundreds of providers through its provider plugin ecosystem. Both manage state; Terraform uses its own state file, CloudFormation uses CloudFormation stacks.

---

## DOMAIN 2 — Terraform's Purpose (Questions 10–20)

**Q10.** What is the Terraform state file's primary purpose?
A) To store provider credentials securely
B) To map Terraform configuration to real-world infrastructure resources
C) To track which team members have run terraform apply
D) To store the history of all previous plan outputs

**ANSWER: B**
The state file maps each resource block in your .tf files to the corresponding real-world resource (its ID, ARN, all attributes). Without state, Terraform cannot know what already exists and what needs to be created, updated, or destroyed.

---

**Q11.** You run `terraform plan` and the output shows: "No changes. Your infrastructure matches the configuration." What does this mean?
A) Terraform did not connect to AWS during the plan
B) The state file is empty
C) The real infrastructure matches the Terraform configuration exactly
D) The configuration has not been modified since the last apply

**ANSWER: C**
"No changes" means Terraform compared desired state (code) against current state (state file refreshed against real infra) and found no differences. This is the desired outcome — it means your infrastructure is exactly what your code says it should be.

---

**Q12.** What is the correct order of the core Terraform workflow?
A) Plan → Write → Apply
B) Write → Apply → Plan
C) Write → Plan → Apply
D) Init → Plan → Write → Apply

**ANSWER: C**
Write (author .tf files) → Plan (preview changes with terraform plan) → Apply (execute changes with terraform apply). Init is a prerequisite step, not part of the workflow loop.

---

**Q13.** Which of the following is TRUE about Terraform Cloud vs Terraform Enterprise?
A) Terraform Cloud is self-hosted; Terraform Enterprise is SaaS
B) Terraform Cloud is a SaaS product; Terraform Enterprise is self-hosted for organisations with compliance requirements
C) They are identical products with different pricing
D) Terraform Enterprise does not support Sentinel policies

**ANSWER: B**
Terraform Cloud (TFC) is HashiCorp's SaaS offering at app.terraform.io. Terraform Enterprise (TFE) is the same product but installed on your own infrastructure — for organisations that cannot send data to external SaaS (government, banking, compliance-regulated industries).



**Q14.** A developer makes changes directly in the AWS console to an EC2 instance managed by Terraform. What happens on the next `terraform plan`?
A) Terraform ignores the manual change
B) Terraform detects the drift and shows what changes it would make to match the configuration
C) Terraform automatically reverts the manual change
D) Terraform errors because the state file is corrupted

**ANSWER: B**
Terraform plan refreshes state against real infrastructure before planning. It detects the out-of-band change and shows it in the plan output. The plan would propose restoring the resource to match the configuration. Terraform does NOT automatically revert — it waits for terraform apply.

---

**Q15.** Which of the following statements about Terraform providers is TRUE?
A) Providers are installed by running terraform apply
B) Each provider is developed and maintained exclusively by HashiCorp
C) Providers are plugins that allow Terraform to interact with specific platforms and services via their APIs
D) A Terraform configuration can only use one provider

**ANSWER: C**
Providers are plugins that translate Terraform resource blocks into API calls for a specific platform. They are installed by terraform init. Many providers are maintained by third parties (AWS, Google, Microsoft, Datadog, etc.) — not exclusively HashiCorp.

---

**Q16.** What is the difference between a resource and a data source in Terraform?
A) Resources are read-only; data sources create infrastructure
B) Resources create and manage infrastructure; data sources read existing information without creating anything
C) Data sources can only be used with the random provider
D) Resources require AWS credentials; data sources do not

**ANSWER: B**
A resource block (`resource "aws_instance" "web" {}`) creates, updates, and destroys infrastructure. A data source block (`data "aws_ami" "ubuntu" {}`) reads existing information — it fetches data from the provider but creates nothing.

---

**Q17.** Which backend type should a team use to enable state locking and prevent concurrent applies?
A) local backend with a .terraform.lock.hcl file
B) S3 backend alone
C) S3 backend with a DynamoDB table for locking
D) Any backend — all backends support state locking

**ANSWER: C**
S3 alone does not support state locking. Adding a DynamoDB table gives Terraform a distributed lock — when one team member is running apply, others get a "state is locked" error. The local backend has file-based locking but only works on a single machine.

---

**Q18.** A Terraform configuration uses `terraform_remote_state` to read outputs from another configuration. What must be true for this to work?
A) Both configurations must be in the same Git repository
B) The remote configuration must have declared output values
C) Both configurations must use the same provider
D) The remote configuration must be applied in the same workspace

**ANSWER: B**
`terraform_remote_state` reads the outputs block values from another configuration's state file. If no outputs are declared in the remote configuration, there is nothing to read. The configurations can be in different repos, use different providers, and be in different workspaces.

---

**Q19.** What does `sensitive = true` in an output block do?
A) Encrypts the value in the state file
B) Prevents the value from appearing in terraform plan and apply terminal output, but the value is still stored in state
C) Prevents the value from being stored in the state file entirely
D) Requires a password to access the output value

**ANSWER: B**
`sensitive = true` masks the value in terminal output (shows `<sensitive>`). It does NOT encrypt or remove it from the state file — the value is still stored in plaintext in terraform.tfstate. Always encrypt your state backend (S3 server-side encryption) and restrict access to the state file.

---

**Q20.** What is the purpose of `terraform login`?
A) Authenticates to AWS using your IAM credentials
B) Obtains and stores an API token for Terraform Cloud or Terraform Enterprise
C) Validates your Terraform configuration against the registry
D) Enables MFA for terraform apply operations

**ANSWER: B**
`terraform login` opens a browser window to app.terraform.io (or your TFE instance), allows you to generate an API token, and stores it in `~/.terraform.d/credentials.tfrc.json`. Required before using a TFC backend or accessing the private module registry.

---

## DOMAIN 3 — Terraform Basics (Questions 21–34)

**Q21.** What is the difference between `terraform.tfstate` and `terraform.tfstate.backup`?
A) terraform.tfstate.backup is encrypted; terraform.tfstate is not
B) terraform.tfstate is the current state; terraform.tfstate.backup is the state from before the most recent apply
C) terraform.tfstate.backup is stored remotely; terraform.tfstate is local
D) They are identical files — the backup is just a redundant copy

**ANSWER: B**
Before every apply, Terraform saves the current state to `terraform.tfstate.backup` and writes the new state to `terraform.tfstate`. If an apply partially fails, the backup contains the last known good state. With remote backends (S3), versioning replaces the need for the .backup file.

---

**Q22.** What does `terraform refresh` do and why is it deprecated?
A) It downloads the latest provider versions — deprecated because init -upgrade does this
B) It synchronises the state file with real infrastructure without planning changes — deprecated in favour of terraform apply -refresh-only
C) It clears the state file and starts fresh — deprecated because it was too destructive
D) It refreshes provider authentication tokens — deprecated because providers handle this automatically

**ANSWER: B**
`terraform refresh` updated the state file to match real infrastructure (running a refresh without planning). It was deprecated because it could cause issues without a plan step. The replacement is `terraform apply -refresh-only`, which shows you what the refresh would change before committing it.

---

**Q23.** Which resource meta-argument would you use to ensure resource B is not created before resource A, even though B does not reference any attribute of A?
A) count
B) for_each
C) depends_on
D) lifecycle

**ANSWER: C**
`depends_on` creates an explicit dependency. Normally Terraform infers dependencies from attribute references. When there is a dependency that is NOT captured by a reference (e.g., a Lambda function depends on an IAM role being attached, but doesn't reference the role directly), use `depends_on` to declare it explicitly.

---

**Q24.** What does `lifecycle { prevent_destroy = true }` prevent?
A) Any modification to the resource
B) The resource being destroyed by terraform destroy or any plan that would destroy it — but it does NOT prevent destruction if the resource block is removed from configuration
C) Terraform from replacing the resource when immutable attributes change
D) Manual deletion of the resource in the AWS console

**ANSWER: B**
`prevent_destroy = true` causes Terraform to error if a plan includes destroying the resource. However, if you completely REMOVE the resource block from your .tf files, Terraform will destroy the resource regardless of prevent_destroy — the lifecycle block no longer exists to be read.

---

**Q25.** A variable is declared with no `default` value:
```hcl
variable "environment" {
  type = string
}
```
What happens when you run `terraform plan` without providing a value?

A) Terraform uses an empty string as the default
B) Terraform errors immediately with "variable not defined"
C) Terraform prompts you interactively to enter a value
D) Terraform skips resources that use the variable

**ANSWER: C**
Variables with no default are REQUIRED. When running in interactive mode (a developer's terminal), Terraform prompts for the value. In CI (non-interactive), this causes the plan to hang or fail. Always provide required variables via -var flags, .tfvars files, or TF_VAR_ environment variables in CI.

---

**Q26.** What is the difference between `locals` and `variables` in Terraform?
A) Locals can be changed at runtime; variables cannot
B) Variables are inputs that can be set externally; locals are internal computed values that cannot be set from outside the configuration
C) Locals require type constraints; variables do not
D) Variables are available in child modules; locals are not

**ANSWER: B**
`variable` blocks are inputs — they can be set by the user via CLI flags, .tfvars files, or environment variables. `locals` are internal computed values — expressions evaluated within the configuration that cannot be overridden externally.

---

**Q27.** Which built-in function would you use to merge two maps in Terraform?
A) concat()
B) flatten()
C) merge()
D) join()

**ANSWER: C**
`merge({a=1}, {b=2})` returns `{a=1, b=2}`. If both maps have the same key, the rightmost value wins. `concat()` works on lists, not maps. `flatten()` flattens nested lists. `join()` converts a list to a string.

---

**Q28.** What does `toset()` do to a list?
A) Converts a list to a map with numeric keys
B) Removes duplicate values and loses ordering
C) Sorts the list alphabetically
D) Validates that all values in the list are unique

**ANSWER: B**
`toset(["a", "b", "a", "c"])` returns `{"a", "b", "c"}` — duplicates removed, order not guaranteed. Sets are used with `for_each` when you want unique keys without caring about order.

---

**Q29.** A module is called with:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
}
```
What versions are allowed by `~> 5.0`?

A) Only exactly version 5.0
B) Any version from 5.0 up to but not including 6.0
C) Any version from 5.0 up to but not including 5.1
D) Any version greater than 5.0 with no upper limit

**ANSWER: B**
`~> 5.0` is the "pessimistic constraint operator" applied to the minor version. It allows `>= 5.0` and `< 6.0`. If written as `~> 5.1.0`, it would allow `>= 5.1.0` and `< 5.2.0`. This is one of the most commonly misunderstood exam topics.

---

**Q30.** What is the `file()` function used for?
A) Creates a local file on the filesystem
B) Reads the contents of a file as a string
C) Lists files in a directory
D) Validates that a file exists before applying

**ANSWER: B**
`file("${path.module}/scripts/setup.sh")` reads the contents of setup.sh and returns them as a string. Commonly used for user_data scripts. Compare with `templatefile()` which also interpolates variables into the file content.

---

**Q31.** What is the key difference between `count` and `for_each`?
A) count creates named resources; for_each creates indexed resources
B) count uses a numeric index that shifts when items are removed; for_each uses string keys that are stable regardless of other items
C) for_each can only be used with maps; count can be used with any value
D) count supports conditional creation; for_each does not

**ANSWER: B**
This is a critical exam topic. With `count = 3`, resources are indexed [0], [1], [2]. If you remove the middle item (making count = 2), Terraform destroys [2] and updates [1] — potentially disrupting the wrong resource. With `for_each`, each resource is keyed by a stable string — removing one key only destroys that specific resource without affecting others.

---

**Q32.** Which of the following is a valid way to reference an output from a child module?
A) `output.vpc.vpc_id`
B) `module.vpc.outputs.vpc_id`
C) `module.vpc.vpc_id`
D) `var.vpc.vpc_id`

**ANSWER: C**
Child module outputs are referenced as `module.<module_name>.<output_name>`. The module label matches the name in the `module` block: `module "vpc" { source = "..." }` → referenced as `module.vpc.vpc_id`.

---

**Q33.** A module source is:
```
source = "github.com/myorg/modules//networking/vpc?ref=main"
```
Why is `?ref=main` a concern for production use?
A) The `//` double-slash syntax is only valid for local paths
B) `ref=main` points to a branch that can change — it is not pinned to an immutable version
C) GitHub sources require authentication that Terraform cannot handle
D) The `//` separator is used incorrectly here

**ANSWER: B**
`?ref=main` points to the main branch — a moving target. If someone pushes a breaking change to main, your next `terraform init` picks it up automatically. For production, always pin to a tag: `?ref=v1.2.3`. Tags are immutable; branches are not.

---

**Q34.** What does the `lookup()` function do?
A) Searches a list for a value and returns its index
B) Retrieves a value from a map by key, with an optional default if the key does not exist
C) Finds a resource in the state file by ID
D) Looks up DNS records for a hostname

**ANSWER: B**
`lookup(map, key, default)` — e.g., `lookup({a=1, b=2}, "c", 0)` returns `0` because "c" is not in the map. Without the default argument, a missing key causes an error. Use it to safely access map values when the key might not exist.

---

## DOMAIN 4 — Terraform CLI (Questions 35–50)

**Q35.** What does `terraform init -upgrade` do that `terraform init` does not?
A) Recreates the .terraform directory from scratch
B) Forces provider version upgrades even when the lock file pins them to older versions
C) Upgrades the Terraform binary itself
D) Migrates state to a newer format

**ANSWER: B**
`terraform init` respects the `.terraform.lock.hcl` file and downloads the pinned version. `-upgrade` tells Terraform to find newer versions that satisfy the version constraints and update the lock file. Use it when you want to adopt a newer provider version.

---

**Q36.** What does `terraform apply -target=aws_instance.web` do?
A) Creates only the aws_instance.web resource and all its dependencies
B) Skips the aws_instance.web resource during apply
C) Destroys only aws_instance.web
D) Applies to all resources with "web" in their name

**ANSWER: A**
`-target` limits the apply to the specified resource and its dependencies. It is useful for troubleshooting but not recommended for routine use because it can leave the state partially out of sync with configuration. HashiCorp explicitly discourages using -target as a workflow practice.

---

**Q37.** You need to mark a resource for forced recreation on the next apply. The Terraform version is 1.7. What is the correct command?
A) `terraform taint aws_instance.web`
B) `terraform apply -replace=aws_instance.web`
C) `terraform state rm aws_instance.web && terraform apply`
D) `terraform destroy -target=aws_instance.web && terraform apply`

**ANSWER: B**
`terraform taint` was deprecated in Terraform 0.15.2. The modern replacement is `terraform apply -replace=<address>`, which both marks the resource for recreation AND runs the apply in one step. Option C would remove from state and recreate, but is more disruptive than necessary.

---

**Q38.** What is the maximum number of resources you can import in a single `terraform import` command?
A) Unlimited — you pass a list of addresses
B) 10 — the default limit
C) 1 — one resource per import command
D) The number of resource blocks in the configuration

**ANSWER: C**
Classic `terraform import` imports exactly ONE resource per invocation. Terraform 1.5+ introduced an `import` block in HCL that allows multiple imports in a single apply, but the `terraform import` CLI command is still one at a time.

---

**Q39.** What does `terraform workspace new production` do?
A) Creates a new workspace named "production" but does not switch to it
B) Creates a new workspace named "production" AND switches to it
C) Switches to the existing "production" workspace
D) Creates a new workspace and applies the current configuration to it

**ANSWER: B**
`terraform workspace new <name>` creates AND switches to the new workspace. To switch to an existing workspace without creating one, use `terraform workspace select <name>`.

---

**Q40.** A developer runs `terraform plan -refresh=false`. What is the implication?
A) Terraform skips downloading providers
B) Terraform plans based on the state file without checking real infrastructure for drift
C) Terraform skips the planning phase and goes directly to apply
D) Terraform refreshes state but does not show a plan

**ANSWER: B**
`-refresh=false` skips the real-world refresh. Terraform plans based entirely on the state file, which may be out of sync with actual infrastructure. Useful for speed in scenarios where you are confident no out-of-band changes occurred. Risky if someone has made manual changes.

---

**Q41.** What does `terraform output -json` return?
A) Only the output values in JSON format
B) All outputs with their values, types, and sensitivity flags in JSON format
C) The entire state file in JSON format
D) A JSON schema for validating the configuration

**ANSWER: B**
`terraform output -json` returns a JSON object where each key is an output name and the value is an object with `value`, `type`, and `sensitive` fields. Example: `{"alb_dns_name": {"value": "abc.elb.amazonaws.com", "type": "string", "sensitive": false}}`.

---

**Q42.** Which command would you use to see which providers a configuration requires without running init?
A) `terraform validate`
B) `terraform providers`
C) `terraform init -list`
D) `terraform state list`

**ANSWER: B**
`terraform providers` reads the configuration files and shows the required providers, their version constraints, and the module they come from. It does not download anything or contact the registry.

---

**Q43.** A team member accidentally ran `terraform destroy` on the production environment. Fortunately, you have the S3 backend with versioning enabled. What is the correct recovery approach?
A) Run terraform apply to recreate all resources from scratch
B) Restore the pre-destroy state file version from S3, then run terraform apply
C) Run terraform import for each resource that was destroyed
D) There is no recovery — the state is gone

**ANSWER: B**
With S3 versioning enabled, every state file version is preserved. Restore the version from before the destroy operation using the S3 console or CLI, then run `terraform apply` — Terraform will detect the difference between the restored state (resources exist) and reality (resources were destroyed) and recreate them.

---

**Q44.** What does `terraform fmt -check` return when all files are correctly formatted?
A) A list of correctly formatted files
B) Exit code 0 with no output
C) Exit code 1 with a success message
D) A diff showing that no changes are needed

**ANSWER: B**
When all files are correctly formatted, `terraform fmt -check` exits with code 0 and produces no output. When files need reformatting, it exits with code 1 and lists the files. CI pipelines check the exit code: `terraform fmt -check -recursive && echo "Format OK"`.

---

**Q45.** A `terraform plan` output shows a resource with the symbol `<=`. What does this mean?
A) The resource will be updated in place with a partial change
B) The resource will be read (it is a data source that will be fetched)
C) The resource already exists and no changes are needed
D) The resource has a lower priority than other resources

**ANSWER: B**
`<=` in plan output indicates a data source read — not a resource change. Data sources are refreshed during planning to get current values. The symbol represents that Terraform is reading (not writing) the resource.

---

**Q46.** You want to view all resources currently tracked in the state file without contacting AWS. Which command do you use?
A) `terraform plan`
B) `terraform state show`
C) `terraform state list`
D) `terraform providers`

**ANSWER: C**
`terraform state list` reads from the state file and prints all resource addresses. No AWS credentials needed. `terraform state show <address>` shows the attributes of a specific resource. `terraform plan` contacts AWS to refresh state.

---

**Q47.** What happens to the `.terraform.lock.hcl` file when you run `terraform init -upgrade`?
A) The file is deleted and recreated
B) The file is unchanged — upgrade does not modify the lock file
C) The lock file is updated with the new provider version hashes
D) The lock file is backed up as .terraform.lock.hcl.backup

**ANSWER: C**
When `-upgrade` finds a newer provider version, it updates `.terraform.lock.hcl` with the new version constraints and cryptographic hashes. You should commit this updated lock file to version control so all team members get the same provider version on their next `terraform init`.

---

**Q48.** Which of the following is TRUE about `terraform apply -auto-approve`?
A) It is equivalent to running terraform plan then terraform apply separately
B) It skips the interactive plan review and confirmation prompt
C) It automatically approves Sentinel policy overrides
D) It is required when running in CI environments

**ANSWER: B**
`-auto-approve` skips the "Do you want to perform these actions? Enter a value: yes" prompt. It does not affect Sentinel policies. In CI, you can also pass a saved plan file (`terraform apply ci.tfplan`) to avoid the prompt — this is actually safer because the plan was reviewed by a human before the CI job runs.

---

**Q49.** A resource is in the Terraform state but no longer exists in real infrastructure (it was manually deleted). What does the next `terraform plan` show?
A) No changes — Terraform does not detect missing resources
B) An error — state corruption detected
C) The resource as "to be created" (+ create)
D) The resource as "to be deleted" (- destroy)

**ANSWER: C**
When a resource exists in state but not in real infrastructure, Terraform detects the drift during the plan refresh. Since the desired state (code) says the resource should exist and reality says it does not, Terraform plans to create it: `+ aws_s3_bucket.logs will be created`.

---

**Q50.** What does `terraform apply -refresh-only` do?
A) Applies only resources that have drifted from configuration
B) Updates the state file to reflect current real-world infrastructure without making any infrastructure changes
C) Refreshes provider authentication without applying changes
D) Applies changes and immediately refreshes the state afterward

**ANSWER: B**
`-refresh-only` is the safe replacement for the deprecated `terraform refresh`. It reads current real-world infrastructure and updates the state file to match — but makes NO changes to infrastructure. Use it when you know out-of-band changes have occurred and want to update state before planning.

---

## DOMAIN 5 — Modules (Questions 51–54)

**Q51.** What is the difference between a root module and a child module?
A) Root modules can have outputs; child modules cannot
B) The root module is the directory where you run terraform apply; child modules are called by the root or other modules
C) Child modules are stored in the Terraform registry; root modules are local only
D) Root modules require a backend configuration; child modules do not

**ANSWER: B**
The root module is where you run Terraform commands — it is the top-level configuration directory. Child modules are called using `module` blocks and can be local (relative path), remote (registry, Git), or nested.

---

**Q52.** A module uses `source = "terraform-aws-modules/vpc/aws"` with no version constraint. What is the risk?
A) Terraform will use version 0.0.1 by default
B) The module will not download — a version is required
C) Any new major version pushed to the registry could introduce breaking changes on the next init
D) The module is read-only and cannot be modified

**ANSWER: C**
Without a version constraint, Terraform downloads the latest version of the module each time `terraform init` runs. If the module maintainer releases a breaking major version change (e.g., removes an input variable), your next init would break. Always pin module versions in production.

---

**Q53.** Which of the following is a valid module source?
A) `source = "s3://my-bucket/modules/vpc"`
B) `source = "git::https://github.com/org/repo.git//modules/vpc?ref=v1.0.0"`
C) `source = "aws:///modules/vpc"`
D) `source = "local:///modules/vpc"`

**ANSWER: B**
Valid module sources: local paths (./modules/vpc), Terraform Registry (hashicorp/consul/aws), GitHub (github.com/org/repo), generic Git (git::https://...), S3 (s3::https://...), HTTP URLs. Option A uses the wrong URL scheme for S3 (should be `s3::https://`). Option B with `git::https://` is correct.

---

**Q54.** When would you use a `module` block with a `providers` argument?
A) When the module needs to use a different provider version than the parent
B) When you want to pass an aliased provider to a module that will deploy resources in a different region or account
C) When the module has more than 10 resources
D) When the module is sourced from a private registry

**ANSWER: B**
The `providers` argument in a module block passes specific provider instances (including aliased ones) to the child module. Use it when a module should deploy resources using a non-default provider — for example, deploying VPC resources in us-west-2 using `provider = aws.west`.

---

## DOMAIN 6-9 — Mixed (Questions 55–57)

**Q55.** Which Sentinel enforcement level allows an apply to proceed after an authorised user provides written justification?
A) advisory
B) hard-mandatory
C) soft-mandatory
D) override-enabled

**ANSWER: C**
soft-mandatory blocks the apply but allows an authorised user to override with justification (logged in audit trail). advisory never blocks. hard-mandatory never allows override. There is no "override-enabled" tier.

---

**Q56.** What happens to existing infrastructure if you remove a resource block from your .tf configuration files and run `terraform apply`?
A) Nothing — Terraform ignores removed resource blocks
B) Terraform destroys the resource that was removed from configuration
C) Terraform moves the resource to the "orphaned" state
D) Terraform errors — you must use terraform state rm first

**ANSWER: B**
When a resource block is removed from configuration, Terraform sees that the desired state no longer includes that resource. On the next apply, Terraform destroys the real resource and removes it from state. This is why removing a resource block from production code is a dangerous operation.

---

**Q57.** A team is evaluating whether to use Terraform workspaces or separate directories for environment isolation. Which statement correctly identifies the primary advantage of separate directories?
A) Separate directories allow different provider versions per environment
B) Separate directories enable different variable values per environment
C) Separate directories provide stronger isolation — a plan in one environment cannot affect another — and make it clear from the file structure what is deployed where
D) Workspaces are deprecated in Terraform 1.5+

**ANSWER: C**
Separate directories (file layout isolation) provide full isolation — a mistake in one environment's directory cannot affect another. They also give a clear visual representation of what is deployed (the Golden Rule: main branch = what is deployed). Workspaces share code and can lead to the Anna/Bill problem from Chapter 10. Workspaces are not deprecated.

---

## SCORING

Count your correct answers and record below:

```
Total correct: _____ / 57
Percentage:    _____ %
Passing score: 40/57 (70%)
Status:        PASS / FAIL

Questions I got wrong (list question numbers):
_________________________________________________

Domains I was weakest in:
_________________________________________________

Topics to review before exam:
_________________________________________________
```

---

## ANSWER KEY (quick reference)

| Q | A | Q | A | Q | A | Q | A |
|---|---|---|---|---|---|---|---|
| 1 | B | 16 | B | 31 | B | 46 | C |
| 2 | B | 17 | C | 32 | C | 47 | C |
| 3 | B | 18 | B | 33 | B | 48 | B |
| 4 | C | 19 | B | 34 | B | 49 | C |
| 5 | C | 20 | B | 35 | B | 50 | B |
| 6 | C | 21 | B | 36 | A | 51 | B |
| 7 | B | 22 | B | 37 | B | 52 | C |
| 8 | C | 23 | C | 38 | C | 53 | B |
| 9 | C | 24 | B | 39 | B | 54 | B |
| 10 | B | 25 | C | 40 | B | 55 | C |
| 11 | C | 26 | B | 41 | B | 56 | B |
| 12 | C | 27 | C | 42 | B | 57 | C |
| 13 | B | 28 | B | 43 | B | | |
| 14 | B | 29 | B | 44 | B | | |
| 15 | C | 30 | B | 45 | B | | |
