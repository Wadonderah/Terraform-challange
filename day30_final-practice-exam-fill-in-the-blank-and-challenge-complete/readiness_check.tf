# =============================================================================
# readiness_check.tf
# Day 30: Final Practice Exam, Fill-in-the-Blank, and Challenge Complete
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# All 10 final readiness check answers encoded as queryable Terraform outputs.
# Run: terraform output readiness_check_answers
# =============================================================================

locals {
  readiness_check_answers = {

    q1_terraform_init = {
      question = "What does terraform init do to your .terraform directory?"
      answer   = ".terraform directory is created and populated. Provider plugins downloaded into .terraform/providers/. Module sources downloaded into .terraform/modules/. Backend configured. .terraform.lock.hcl created or updated with exact versions and checksums. Init is idempotent. Must run before validate, plan, or apply. .terraform/ should NOT be committed to VCS."
    }

    q2_state_backup = {
      question = "Difference between terraform.tfstate and terraform.tfstate.backup?"
      answer   = "terraform.tfstate is the current live state — Terraform's belief about existing infrastructure. terraform.tfstate.backup is the previous state, auto-created before each state-modifying operation. With remote backends (S3, TF Cloud) local files replaced by remote state; backup handled by S3 versioning or TF Cloud history."
    }

    q3_never_commit_state = {
      question = "Why should you never commit terraform.tfstate to version control?"
      answer   = "Three reasons: 1) State contains sensitive values in plaintext (passwords, keys, tokens) — even with sensitive=true — and VCS history makes them permanent. 2) Multiple team members pushing conflicting state files causes corruption and potential infrastructure destruction. 3) State files are large, change every apply, and pollute git history. Solution: remote backend with locking."
    }

    q4_depends_on = {
      question = "What does depends_on do and when should you use it?"
      answer   = "depends_on creates explicit dependency ordering between resources or modules when implicit reference-based dependency detection is insufficient. Example: IAM policy propagation delay before Lambda creation — nothing in Lambda references the policy directly. Use sparingly — overuse slows plans and makes configurations harder to reason about."
    }

    q5_variable_vs_locals = {
      question = "What is the difference between a variable block and a locals block?"
      answer   = "variable = public interface, can be set from outside (tfvars, -var, env vars, module args). locals = internal computed values, derived from other values, cannot be overridden by caller. If a value needs to come from outside: variable. If derived internally and used multiple places: local."
    }

    q6_concurrent_apply = {
      question = "What happens if you run terraform apply and state was modified by another team member?"
      answer   = "If backend supports locking: apply acquires lock; if another apply in progress, second apply waits or errors with lock info. If state was modified but no lock held: apply proceeds with the old plan — may make unexpected changes or error if referenced resources no longer exist in state. Best practice: plan immediately before apply, use saved plan files in CI/CD."
    }

    q7_terraform_graph = {
      question = "What does terraform graph output and what is it used for?"
      answer   = "terraform graph outputs a DOT-format directed graph of resource dependency relationships. Visualise with Graphviz (dot -Tpng). Used for: understanding resource creation/destruction order, debugging unexpected dependencies, identifying circular dependencies that would fail plans. Helpful in large configurations to reason about sequencing."
    }

    q8_registry_three_types = {
      question = "What is the Terraform Registry and the three types of things published there?"
      answer   = "registry.terraform.io is the public index of reusable Terraform components. Three types: 1) Providers — plugins for managing platform APIs (AWS, Azure, GCP), downloaded by terraform init. 2) Modules — reusable resource collections (e.g. terraform-aws-modules/vpc/aws), referenced with source and version. 3) Policies — Sentinel and OPA policy sets for Terraform Cloud/Enterprise governance."
    }

    q9_cloud_vs_enterprise = {
      question = "What is the difference between Terraform Cloud and Terraform Enterprise?"
      answer   = "Terraform Cloud = HashiCorp-managed SaaS. Remote state, remote execution, team access, Sentinel policies, VCS integration, private module registry. Free and paid tiers. Terraform Enterprise = self-hosted version deployed in customer's own infrastructure. Same features plus additional enterprise controls. For: data residency, airgapped environments, compliance, very large scale. Key distinction: Cloud = HashiCorp manages infra. Enterprise = you manage infra."
    }

    q10_configuration_aliases = {
      question = "When a module uses configuration_aliases, what problem does it solve?"
      answer   = "configuration_aliases allows a module to receive and use multiple configurations of the same provider — e.g. managing resources in two AWS regions or two accounts simultaneously within one module call. Without it, a module only uses one provider configuration. The module declares aliases in required_providers; the root module passes them via the providers argument when calling the module."
      hcl_example = "terraform { required_providers { aws = { source = hashicorp/aws, configuration_aliases = [aws.primary, aws.secondary] } } }"
    }

    score = "10/10 — All answered confidently without notes or documentation"
  }
}

output "readiness_check_answers" {
  description = "All 10 final readiness check answers. Run: terraform output readiness_check_answers"
  value       = local.readiness_check_answers
}