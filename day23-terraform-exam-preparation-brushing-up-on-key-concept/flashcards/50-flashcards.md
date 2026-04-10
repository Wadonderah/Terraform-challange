# Terraform Associate — 50 Exam Flashcards
## Print, cut, or use as rapid-fire self-test

---

**Q1:** What does `terraform state rm` do to real infrastructure?
**A:** Nothing. It only removes the resource from the state file.

---

**Q2:** What exit code does `terraform fmt -check` return if files need reformatting?
**A:** Exit code 1.

---

**Q3:** What does the `-/+` symbol mean in plan output?
**A:** Destroy and recreate (replacement). An immutable attribute was changed.

---

**Q4:** What does `~` mean in plan output?
**A:** Update in-place. The resource is modified without being replaced.

---

**Q5:** Which command downloads provider plugins?
**A:** `terraform init`

---

**Q6:** Does `terraform validate` require AWS credentials?
**A:** No. It only checks local configuration files.

---

**Q7:** What is the name of the provider lock file?
**A:** `.terraform.lock.hcl`

---

**Q8:** Should `.terraform.lock.hcl` be committed to version control?
**A:** Yes. It ensures all team members use the same provider versions.

---

**Q9:** What built-in variable returns the current workspace name?
**A:** `terraform.workspace`

---

**Q10:** What is the default workspace name?
**A:** `default`

---

**Q11:** What does `terraform apply -replace=aws_instance.web` do?
**A:** Forces the resource to be destroyed and recreated on the next apply.

---

**Q12:** What deprecated command did `-replace` replace?
**A:** `terraform taint`

---

**Q13:** What format does `terraform graph` output?
**A:** DOT format (used by Graphviz).

---

**Q14:** What does `terraform providers mirror` do?
**A:** Downloads provider binaries to a local directory for air-gapped use.

---

**Q15:** What happens to the resource if you set `count = 0`?
**A:** The existing resource is destroyed.

---

**Q16:** When count is reduced from 5 to 3, which instances are destroyed?
**A:** The highest-indexed ones: [3] and [4].

---

**Q17:** What is the correct syntax for a provider alias reference in a resource?
**A:** `provider = aws.west` (dot notation, not a string).

---

**Q18:** What does `terraform init -reconfigure` do differently from `-migrate-state`?
**A:** `-reconfigure` ignores existing state; `-migrate-state` moves it to the new backend.

---

**Q19:** What does `terraform output -raw` do differently from `terraform output`?
**A:** `-raw` outputs the string value without quotes — suitable for shell scripting.

---

**Q20:** What does `terraform state mv` do to real infrastructure?
**A:** Nothing. It only updates the state file.

---

**Q21:** Which S3 backend feature requires DynamoDB?
**A:** State locking.

---

**Q22:** What does a Sentinel `hard-mandatory` policy do when violated?
**A:** Blocks the apply with no way to override.

---

**Q23:** What does a Sentinel `soft-mandatory` policy do when violated?
**A:** Blocks the apply but can be overridden by an authorised user.

---

**Q24:** What does a Sentinel `advisory` policy do when violated?
**A:** Logs the violation but does not block the apply.

---

**Q25:** After `terraform import`, what should you always run next?
**A:** `terraform plan` — to verify the configuration matches the imported resource.

---

**Q26:** What must you do BEFORE running `terraform import`?
**A:** Write the resource block in your .tf files.

---

**Q27:** What does `terraform_remote_state` allow you to do?
**A:** Read output values from another Terraform configuration's state file.

---

**Q28:** What is the `random_password` resource used for?
**A:** Generating stable, cryptographically random passwords stored in state.

---

**Q29:** Does `random_id` generate a new value on every apply?
**A:** No. The value is generated once and stored in state. It is stable unless you use `-replace`.

---

**Q30:** What is the `keepers` argument in random resources used for?
**A:** Forces the random value to regenerate when a keeper value changes.

---

**Q31:** What does `local_file` create?
**A:** A file on the local filesystem (on the Terraform runner, not on EC2 instances).

---

**Q32:** What is `path.module`?
**A:** The filesystem path of the directory containing the current module's .tf files.

---

**Q33:** What is `path.root`?
**A:** The filesystem path of the root module (where terraform apply was run).

---

**Q34:** What does `lifecycle { create_before_destroy = true }` do?
**A:** For replacements, creates the new resource before destroying the old one (zero-downtime).

---

**Q35:** What does `lifecycle { ignore_changes = [tags] }` do?
**A:** Tells Terraform to ignore changes to the `tags` attribute when planning.

---

**Q36:** What does `lifecycle { prevent_destroy = true }` do?
**A:** Causes terraform destroy (and any plan that would destroy the resource) to error.

---

**Q37:** What variable prefix lets you set Terraform variables via environment variables?
**A:** `TF_VAR_` — e.g., `TF_VAR_db_password=secret`

---

**Q38:** What does `terraform console` do?
**A:** Opens an interactive REPL for evaluating Terraform expressions and functions.

---

**Q39:** What does `terraform plan -refresh-only` do?
**A:** Updates the state file to match real infrastructure without planning any resource changes.

---

**Q40:** What does `terraform plan -refresh=false` do?
**A:** Skips the real-world refresh and plans based on the existing state file only.

---

**Q41:** What is the difference between `count` and `for_each`?
**A:** `count` uses numeric indexes; `for_each` uses string keys. `for_each` is safer for deletions because it does not shift indexes.

---

**Q42:** What is a dynamic block used for?
**A:** Generating repeated nested blocks (like `ingress` rules in a security group) from a collection.

---

**Q43:** What does a `for` expression `[for s in var.list : upper(s)]` produce?
**A:** A new list with each element of `var.list` converted to uppercase.

---

**Q44:** What does `toset()` do to a list?
**A:** Converts a list to a set, removing duplicates and losing order.

---

**Q45:** What does `cidrsubnet("10.0.0.0/16", 8, 1)` return?
**A:** `"10.0.1.0/24"` — creates a /24 subnet (8 extra bits) at index 1.

---

**Q46:** When does Terraform automatically create an implicit `depends_on`?
**A:** When one resource references an attribute of another (e.g., `vpc_id = aws_vpc.main.id`).

---

**Q47:** What is the Terraform state file named by default?
**A:** `terraform.tfstate`

---

**Q48:** What does `-auto-approve` do in `terraform apply`?
**A:** Skips the interactive "yes" confirmation prompt.

---

**Q49:** What happens to the state file when you run `terraform destroy`?
**A:** Resources are removed from the state file as they are destroyed. The file may be empty but still exists.

---

**Q50:** What is the Golden Rule of Terraform?
**A:** The main branch of the live repository should be a 1:1 representation of what is actually deployed in production.
