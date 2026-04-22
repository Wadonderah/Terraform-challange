# =============================================================================
# fill_in_the_blank.tf
# Day 30: Final Practice Exam, Fill-in-the-Blank, and Challenge Complete
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# All 10 fill-in-the-blank questions answered in HCL with explanations.
# Run: terraform output fill_in_the_blank_answers
# =============================================================================

locals {
  fill_in_the_blank_answers = {

    q1 = {
      question       = "The command to check formatting without making changes is terraform ___"
      my_answer      = "fmt -check"
      correct_answer = "fmt"
      result         = "CORRECT"
      explanation    = "terraform fmt checks AND reformats. Add -check flag to check without writing changes. -recursive applies to all subdirectories. Always safe to run — does not affect providers, state, or infrastructure."
      command        = "terraform fmt -check -recursive"
    }

    q2 = {
      question       = "The meta-argument that prevents destruction is ___ = true inside lifecycle"
      my_answer      = "prevent_destroy"
      correct_answer = "prevent_destroy"
      result         = "CORRECT"
      explanation    = "prevent_destroy = true blocks terraform destroy and any plan that would destroy the resource. EXAM TRAP: does NOT block manual deletion via AWS console, CLI, or API. Terraform only controls what it controls."
      hcl_example    = "lifecycle { prevent_destroy = true }"
    }

    q3 = {
      question       = "To reference current workspace name use terraform.___"
      my_answer      = "workspace"
      correct_answer = "workspace"
      result         = "CORRECT"
      explanation    = "terraform.workspace is a built-in expression returning the current workspace name as a string. Cannot be set in tfvars. Controlled by terraform workspace select. Default workspace = 'default' string."
      hcl_example    = "name = dollar{var.project}-dollar{terraform.workspace}"
    }

    q4 = {
      question       = "S3 backend requires ___ argument for server-side encryption"
      my_answer      = "encrypt"
      correct_answer = "encrypt"
      result         = "CORRECT"
      explanation    = "encrypt = true in the S3 backend block encrypts the state file at rest. This IS encryption. Contrast: sensitive = true on outputs only suppresses CLI display — state is still plaintext. Use kms_key_id for customer-managed key encryption."
      hcl_example    = "backend s3 { encrypt = true }"
    }

    q5 = {
      question       = "for_each requires the value to be a map or a ___"
      my_answer      = "set"
      correct_answer = "set"
      result         = "CORRECT"
      explanation    = "for_each accepts a map (keys become resource addresses) or a set of strings. NOT a plain list. Convert lists with toset(). Advantage over count: removing one element does not re-index all others. Resources addressed by key not integer index."
      hcl_example    = "for_each = toset(var.bucket_names)"
    }

    q6 = {
      question       = "Command to remove from state without destroying is terraform state ___"
      my_answer      = "rm"
      correct_answer = "rm"
      result         = "CORRECT"
      explanation    = "terraform state rm removes the resource from state only. Real infrastructure keeps running as an unmanaged orphan. CONTRAST: terraform destroy removes from state AND deletes the real resource. This distinction appeared wrong in 3 of 5 exams before terminal practice."
      command        = "terraform state rm aws_instance.web"
    }

    q7 = {
      question       = "~> 2.0 allows versions >= 2.0 and < ___"
      my_answer      = "3.0"
      correct_answer = "3.0"
      result         = "CORRECT"
      explanation    = "Pessimistic constraint ~> increments the rightmost segment. ~> 2.0 has two segments so minor can increment: >= 2.0.0, < 3.0.0. ~> 2.0.0 has three segments: >= 2.0.0, < 2.1.0 (patch only). More segments = tighter constraint."
      exam_trap      = "~> 2.0 vs ~> 2.0.0 are NOT the same. Segment count matters."
    }

    q8 = {
      question       = "A data block reads ___ infrastructure; a resource block manages ___ infrastructure"
      my_answer      = "existing / managed"
      correct_answer = "existing / managed"
      result         = "CORRECT"
      explanation    = "Data sources are read-only — they query and expose attributes of existing resources Terraform does not own. Resource blocks declare infrastructure Terraform manages: creates on first apply, updates/replaces on config change, destroys on terraform destroy."
      hcl_example    = "data reads: data aws_vpc existing {} -- resource manages: resource aws_subnet new {}"
    }

    q9 = {
      question       = "terraform init -upgrade updates providers pinned in the ___ file"
      my_answer      = ".terraform.lock.hcl"
      correct_answer = ".terraform.lock.hcl"
      result         = "CORRECT"
      explanation    = ".terraform.lock.hcl records exact provider versions and checksums after init. Ensures reproducibility across team members. -upgrade flag overrides it and pulls newest versions satisfying constraints. This file SHOULD be committed to version control. The .terraform directory should NOT."
      commit_to_vcs  = "YES — commit .terraform.lock.hcl to version control"
    }

    q10 = {
      question       = "To apply a saved plan file myplan.tfplan the command is terraform apply ___"
      my_answer      = "myplan.tfplan"
      correct_answer = "myplan.tfplan"
      result         = "CORRECT"
      explanation    = "terraform plan -out=myplan.tfplan saves a binary plan. terraform apply myplan.tfplan executes it exactly — no re-plan, no confirmation prompt. Standard CI/CD pattern: plan in PR stage, human approves, apply in deploy stage with guarantee that approved plan = executed plan."
      commands       = "terraform plan -out=myplan.tfplan && terraform show myplan.tfplan && terraform apply myplan.tfplan"
    }

    score = "10/10 — All correct on first retrieval attempt (answers written before checking docs)"
  }
}

output "fill_in_the_blank_answers" {
  description = "All 10 fill-in-the-blank answers with explanations. Run: terraform output fill_in_the_blank_answers"
  value       = local.fill_in_the_blank_answers
}