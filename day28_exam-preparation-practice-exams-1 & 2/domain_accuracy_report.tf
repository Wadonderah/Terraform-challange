# =============================================================================
# domain_accuracy_report.tf
# Day 28: Terraform Associate Exam Prep - Exam Results as HCL
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# This file encodes the Day 28 exam results, domain accuracy table, and
# remediation plan as Terraform locals and outputs.
# Run: terraform console -> then query these locals interactively.
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # EXAM SCORES
  # ---------------------------------------------------------------------------
  exam_scores = {
    exam_1 = {
      score      = 42
      total      = 57
      percentage = 73.7
      result     = "PASS"
    }
    exam_2 = {
      score      = 45
      total      = 57
      percentage = 78.9
      result     = "PASS"
    }
  }

  improvement_pct = local.exam_scores.exam_2.percentage - local.exam_scores.exam_1.percentage
  # = 5.2

  # ---------------------------------------------------------------------------
  # DOMAIN ACCURACY TABLE
  # Combined results across both exams (114 total questions)
  # ---------------------------------------------------------------------------
  domain_accuracy = {
    iac_concepts = {
      attempted = 8
      correct   = 6
      accuracy  = 75.0
      status    = "on_track"
    }
    terraform_purpose = {
      attempted = 6
      correct   = 5
      accuracy  = 83.3
      status    = "on_track"
    }
    terraform_basics = {
      attempted = 10
      correct   = 8
      accuracy  = 80.0
      status    = "on_track"
    }
    terraform_cli = {
      attempted = 12
      correct   = 9
      accuracy  = 75.0
      status    = "on_track"
    }
    terraform_modules = {
      attempted = 8
      correct   = 5
      accuracy  = 62.5
      status    = "needs_work"  # BELOW 70% THRESHOLD
    }
    core_workflow = {
      attempted = 6
      correct   = 5
      accuracy  = 83.3
      status    = "on_track"
    }
    state_management = {
      attempted = 10
      correct   = 6
      accuracy  = 60.0
      status    = "needs_work"  # BELOW 70% THRESHOLD
    }
    configuration = {
      attempted = 8
      correct   = 6
      accuracy  = 75.0
      status    = "on_track"
    }
    terraform_cloud = {
      attempted = 5
      correct   = 3
      accuracy  = 60.0
      status    = "needs_work"  # BELOW 70% THRESHOLD
    }
  }

  # Domains requiring remediation (below 70%)
  weak_domains = {
    for domain, data in local.domain_accuracy :
    domain => data
    if data.accuracy < 70
  }

  # Overall accuracy
  total_attempted = sum([for d in values(local.domain_accuracy) : d.attempted])
  total_correct   = sum([for d in values(local.domain_accuracy) : d.correct])
  overall_accuracy = local.total_correct / local.total_attempted * 100

  # ---------------------------------------------------------------------------
  # WRONG ANSWER ANALYSIS
  # The 6 most impactful wrong answers from Day 28
  # ---------------------------------------------------------------------------
  wrong_answers = [
    {
      id            = 1
      topic         = "Q4 Topic 1 - Immutable Infrastructure Advantage"
      my_answer     = "C - Quicker infrastructure upgrades"
      correct       = "D - Less complex infrastructure upgrades"
      reasoning_error = "Confused speed with simplicity. Immutability eliminates drift and partial states. The advantage is LESS COMPLEX, not faster."
      doc_ref       = "https://developer.hashicorp.com/terraform/tutorials/aws-get-started/infrastructure-as-code"
      hands_on_fix  = "terraform destroy && terraform apply  # practice full replacement"
    },
    {
      id            = 2
      topic         = "terraform state rm - Effect on real infrastructure"
      my_answer     = "terraform state rm destroys the actual cloud resource"
      correct       = "terraform state rm removes from state only. Real infrastructure survives unmanaged."
      reasoning_error = "Conflated state management with resource lifecycle. destroy=deletes. state rm=orphans."
      doc_ref       = "https://developer.hashicorp.com/terraform/cli/commands/state/rm"
      hands_on_fix  = "terraform state rm <resource> && verify resource still exists in AWS console"
    },
    {
      id            = 3
      topic         = "Terraform Cloud - Remote state vs remote operations"
      my_answer     = "The cloud backend always executes plans remotely"
      correct       = "execution_mode workspace setting controls plan location. State is always remote."
      reasoning_error = "Did not distinguish backend type from execution mode. These are independent settings."
      doc_ref       = "https://developer.hashicorp.com/terraform/cloud-docs/run/remote-operations"
      hands_on_fix  = "Toggle execution_mode in TF Cloud workspace UI and observe plan behaviour change"
    },
    {
      id            = 4
      topic         = "Module sources - version argument support"
      my_answer     = "All module sources support the version argument"
      correct       = "Only registry sources (public and private) support version. Local and Git sources do not."
      reasoning_error = "Overgeneralised. version is a registry-only feature. Git uses ?ref= in URL."
      doc_ref       = "https://developer.hashicorp.com/terraform/language/modules/sources"
      hands_on_fix  = "Add version to a local module source and observe the error"
    },
    {
      id            = 5
      topic         = "terraform refresh - What it updates"
      my_answer     = "terraform refresh updates .tf configuration files"
      correct       = "terraform refresh updates state file only. Configuration files are never modified by Terraform."
      reasoning_error = "Confused direction of update. State moves to match reality. Config only changes by human edit."
      doc_ref       = "https://developer.hashicorp.com/terraform/cli/commands/refresh"
      hands_on_fix  = "terraform refresh && git diff *.tf  # confirms config files unchanged"
    },
    {
      id            = 6
      topic         = "sensitive = true - Security scope"
      my_answer     = "sensitive = true encrypts the value in terraform.tfstate"
      correct       = "sensitive = true suppresses CLI display only. Value is plaintext in tfstate."
      reasoning_error = "Over-attributed security to a display-only flag. Real encryption requires encrypted backend."
      doc_ref       = "https://developer.hashicorp.com/terraform/language/values/outputs#sensitive-suppressing-values-in-cli-output"
      hands_on_fix  = "terraform output -json  # reveals value; cat tfstate shows plaintext"
    },
  ]

  # ---------------------------------------------------------------------------
  # DAYS 29 & 30 PLAN
  # ---------------------------------------------------------------------------
  day29_plan = {
    focus     = "Targeted remediation of three sub-70% domains only"
    tasks = [
      "State Management: command comparison table, run all state commands against test resources",
      "Modules: write 3 modules from scratch covering validation, outputs, and for_each",
      "Terraform Cloud: map every workspace setting to its CLI behaviour",
      "IaC Concepts: write immutable/idempotent/declarative definitions from memory, verify against docs",
    ]
  }

  day30_plan = {
    focus = "Light review then exam"
    tasks = [
      "Morning: 20-min review of command comparison table and wrong-answer cards",
      "Pre-exam: weak domain summaries only - no new material",
      "Exam: 57 questions, 60 minutes, flag uncertain, complete first pass then revisit",
    ]
    target_score = "80%+ (46/57)"
  }
}

# ---------------------------------------------------------------------------
# OUTPUTS - query these in terraform console or terraform output
# ---------------------------------------------------------------------------

output "exam_summary" {
  description = "Day 28 exam scores summary."
  value = {
    exam_1_score       = "${local.exam_scores.exam_1.score}/${local.exam_scores.exam_1.total} = ${local.exam_scores.exam_1.percentage}%"
    exam_2_score       = "${local.exam_scores.exam_2.score}/${local.exam_scores.exam_2.total} = ${local.exam_scores.exam_2.percentage}%"
    improvement        = "+${local.improvement_pct}%"
    overall_accuracy   = "${local.overall_accuracy}%"
    weak_domain_count  = length(local.weak_domains)
  }
}

output "weak_domains_report" {
  description = "Domains requiring remediation before Day 30 exam."
  value       = local.weak_domains
}

output "wrong_answer_count" {
  description = "Number of wrong answers analysed today."
  value       = length(local.wrong_answers)
}